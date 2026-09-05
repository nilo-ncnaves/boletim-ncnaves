-- Relatórios automáticos — FASE 2: robô-redator (API da Claude dentro do Supabase)
-- Rodar no SQL Editor do Supabase (projeto syvehtgrbqteyuqhoban) DEPOIS do
-- sql/020-relatorios-motor.sql. Pode ser rodado de novo sem estragar nada.
--
-- ORDEM DE COLAGEM:
--   sql/020-relatorios-motor.sql   (fase 1 — já rodado)
--   sql/030-redator.sql            ← ESTE ARQUIVO (tabelas, funções, agenda)
--   sql/031-redator-cofre.sql      (grava a chave da API em segredos — trocar COLE_AQUI)
--   sql/032-redator-teste.sql      (disparo manual de uma devolutiva + conferência)
--
-- O que faz: pega o resultado pronto da fase 1 (relatorios_gerados.dados), monta
-- uma mensagem com o texto-modelo de relatorios_modelos e pede à API da Claude
-- (https://api.anthropic.com/v1/messages) o texto narrativo. Padrão assíncrono
-- igual ao robô iCrop (pg_net): uma função DISPARA (guarda o req_id em
-- relatorios_reqs) e outra COLHE a resposta em net._http_response minutos depois,
-- gravando em relatorios_gerados.texto. O app só lê o texto e marca "gerado
-- automaticamente — revisar antes de enviar".
--
-- SEGURANÇA: a chave da API vive SÓ na tabela segredos (chave = 'anthropic_key',
-- gravada pelo sql/031) e é lida dentro de função security definer; nunca sai do
-- Supabase, nunca vai para o app, nunca entra no repositório. As funções ficam
-- revogadas para anon/authenticated: só o SQL Editor e o pg_cron chamam.
--
-- Modelos (relatorios_modelos): um texto-modelo por relatório narrativo.
--   devolutiva_semanal  — por unidade, sexta; fontes: farol_7 + dito × medido da semana
--   painel_executivo    — grupo, dia 8; fontes: mês fechado (custo, rebanho, plano,
--                         farol_30, semanas de irrigação e dito × medido) + mês anterior
--   alerta_divergencia  — manual (fase 2: sem agenda); uma divergência por chamada
-- O relatório narrativo vira uma LINHA em relatorios_gerados (relatorio =
-- nome do modelo, dados = fontes compactadas, texto = redação), e o app mostra
-- o texto acima dos números. Modelo novo = insert em relatorios_modelos.

create extension if not exists pg_net;

-- ====================================================================
-- 1. Textos-modelo (fonte: docs/redator-modelos.md — os dois nunca divergem)
-- ====================================================================
create table if not exists public.relatorios_modelos (
  relatorio     text primary key,          -- chave do relatório narrativo (= relatorios_gerados.relatorio)
  instrucoes    text not null,             -- texto-modelo (system prompt) do redator
  cadencia      text not null default 'manual' check (cadencia in ('semana', 'mes', 'manual')),
  por_unidade   boolean not null default true,   -- true = uma redação por unidade; false = linha do grupo
  fontes        text[] not null default '{}',    -- relatórios da fase 1 que alimentam a redação
  max_tokens    integer not null default 1500,
  ativo         boolean not null default true,
  atualizado_em timestamptz not null default now()
);
comment on table public.relatorios_modelos is
  'Textos-modelo do robô-redator (v57). Fonte dos textos: docs/redator-modelos.md. O redator lê instrucoes como system prompt e manda os dados das fontes em JSON.';
alter table public.relatorios_modelos add column if not exists cadencia text not null default 'manual';
alter table public.relatorios_modelos add column if not exists por_unidade boolean not null default true;
alter table public.relatorios_modelos add column if not exists fontes text[] not null default '{}';
alter table public.relatorios_modelos add column if not exists max_tokens integer not null default 1500;
alter table public.relatorios_modelos add column if not exists ativo boolean not null default true;
alter table public.relatorios_modelos add column if not exists atualizado_em timestamptz not null default now();
alter table public.relatorios_modelos enable row level security;
drop policy if exists "relatorios_modelos leitura" on public.relatorios_modelos;
create policy "relatorios_modelos leitura" on public.relatorios_modelos for select using (true);

-- Semente (texto idêntico ao de docs/redator-modelos.md). Regravar = rodar de novo.
insert into public.relatorios_modelos (relatorio, instrucoes, cadencia, por_unidade, fontes, max_tokens) values
('devolutiva_semanal',
$m$Você é o redator da Controladoria do Grupo LGS (agronegócio: café,
grãos e pecuária, Monte Carmelo-MG). Escreva a devolutiva semanal
de UMA unidade para o gerente dela, em português do Brasil, para
ser enviada por WhatsApp. Máximo 12 linhas. Estrutura: (1) uma
frase de reconhecimento específica (cite um dado real da semana
que foi bem feito — nunca elogio genérico); (2) o placar da semana
(boletins enviados/dias úteis); (3) o que a medição mostrou
(lâminas, chuva da estação, máquinas) e, se houver divergência
entre o informado e o medido, apresente como pergunta, não como
acusação ("a estação mediu 26 mm no dia 26 — confere com o que
você viu?"); (4) uma única pendência prioritária para a próxima
semana; (5) fecho curto e respeitoso. Regras: nunca invente número
— use só os dados fornecidos; se um dado faltar, não mencione; não
compare este gerente com outros; não use jargão técnico sem
explicar; não use listas com marcadores; tom de quem trabalha
junto, não de quem fiscaliza. Se a unidade não enviou nenhum
boletim na semana, a devolutiva vira um convite gentil, com a
pergunta "o que dificultou?".$m$,
 'semana', true, '{farol_7,dito_medido_icrop_semana,dito_medido_solinftec_semana}', 1500),
('painel_executivo',
$m$Você é o redator da Controladoria do Grupo LGS. Escreva o painel
executivo mensal para os sócios, em português, 1 página (máximo 25
linhas), a partir dos relatórios do mês fornecidos em JSON.
Estrutura fixa: (1) três números que resumem o mês (produção,
custo físico ou irrigação, rebanho) em uma linha cada; (2) o que
melhorou e o que piorou versus o mês anterior, com o número; (3)
divergências relevantes entre informado e medido (só as que
importam para dinheiro ou risco); (4) adesão ao boletim em uma
linha; (5) TRÊS decisões recomendadas, cada uma com a evidência
que a sustenta e o que acontece se não for tomada. Regras: nunca
invente; marque PENDENTE o que não constar; sem adjetivos vazios;
números com unidade e período; um sócio sem formação técnica deve
entender tudo; termine com a lista do que ainda depende de
integração (ERP) para o custo por saca ficar completo.$m$,
 'mes', false, '{farol_30,custo_fisico_talhao_mes,rebanho_mes,plano_executado_mes,irrigacao_rec_exec_semana,dito_medido_icrop_semana,dito_medido_solinftec_semana}', 1500),
('alerta_divergencia',
$m$Escreva, em até 3 linhas, um alerta interno para o controller
sobre uma divergência dito × medido: unidade, dia, o que foi
informado, o que foi medido, e uma hipótese neutra (erro de
lançamento? falha de sensor? evento não registrado?). Sem tom
acusatório. Sem inventar.$m$,
 'manual', true, '{dito_medido_icrop_dia,dito_medido_solinftec_dia}', 300)
on conflict (relatorio) do update set instrucoes = excluded.instrucoes, cadencia = excluded.cadencia,
  por_unidade = excluded.por_unidade, fontes = excluded.fontes, max_tokens = excluded.max_tokens, atualizado_em = now();

-- ====================================================================
-- 2. Pedidos em andamento + colunas do texto
-- ====================================================================
create table if not exists public.relatorios_reqs (
  req_id      bigint primary key,          -- id devolvido por net.http_post
  relatorio   text not null,
  periodo_ini date not null,
  periodo_fim date not null,
  unidade_id  text,
  modelo_ia   text,
  status      text not null default 'enviado' check (status in ('enviado', 'ok', 'erro', 'perdido')),
  erro        text,
  tokens_in   integer,
  tokens_out  integer,
  criado_em   timestamptz not null default now(),
  colhido_em  timestamptz
);
comment on table public.relatorios_reqs is 'Pedidos do robô-redator à API da Claude (dispara → colhe). Não guarda a chave nem a mensagem; só ids, status e tokens.';
alter table public.relatorios_reqs enable row level security;
drop policy if exists "relatorios_reqs leitura" on public.relatorios_reqs;
create policy "relatorios_reqs leitura" on public.relatorios_reqs for select using (true);

alter table public.relatorios_gerados add column if not exists texto_em timestamptz;
alter table public.relatorios_gerados add column if not exists texto_modelo text;   -- modelo de IA que redigiu

-- A fase 1 regrava os números todo dia; o texto já redigido NÃO pode sumir nessa
-- regravação (só troca quando o redator colhe um texto novo).
create or replace function public.rel_gravar(p_rel text, p_ini date, p_fim date, p_unidade text, p_dados jsonb, p_texto text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.relatorios_gerados (relatorio, periodo_ini, periodo_fim, unidade_id, gerado_em, dados, texto)
  values (p_rel, p_ini, p_fim, p_unidade, now(), p_dados, p_texto)
  on conflict (relatorio, periodo_ini, periodo_fim, (coalesce(unidade_id, '')))
  do update set dados = excluded.dados, gerado_em = now(),
    texto = coalesce(excluded.texto, public.relatorios_gerados.texto);
end $$;

-- ====================================================================
-- 3. Auxiliares
-- ====================================================================
-- Chave da API: só aqui, só dentro de função security definer. A tabela segredos
-- (da iCrop) pode ter as colunas chave/valor ou nome/valor — os dois casos servem.
create or replace function public.redator_chave()
returns text language plpgsql security definer set search_path = public as $$
declare c_chave text; c_valor text; v text;
begin
  select column_name into c_chave from information_schema.columns
    where table_schema = 'public' and table_name = 'segredos' and column_name in ('chave', 'nome', 'id')
    order by array_position(array['chave', 'nome', 'id'], column_name::text) limit 1;
  select column_name into c_valor from information_schema.columns
    where table_schema = 'public' and table_name = 'segredos' and column_name in ('valor', 'token', 'value')
    order by array_position(array['valor', 'token', 'value'], column_name::text) limit 1;
  if c_chave is null or c_valor is null then
    raise exception 'tabela segredos sem colunas chave/valor reconhecíveis — ver sql/031-redator-cofre.sql';
  end if;
  execute format('select %I from public.segredos where %I = %L limit 1', c_valor, c_chave, 'anthropic_key') into v;
  if v is null or v like 'COLE_AQUI%' then
    raise exception 'chave da API ainda não gravada em segredos (anthropic_key) — rodar sql/031-redator-cofre.sql';
  end if;
  return v;
end $$;

-- Grava (ou troca) a chave da API no cofre — usada pelo sql/031 (uma linha só,
-- para não ter que editar bloco no celular). Descobre sozinha se a tabela
-- segredos usa chave/valor ou nome/valor. Nunca devolve a chave.
create or replace function public.redator_gravar_chave(p_chave text)
returns text language plpgsql security definer set search_path = public as $$
declare c_chave text; c_valor text;
begin
  if p_chave is null or p_chave like 'COLE_AQUI%' or length(p_chave) < 20 then
    return 'nada gravado: troque COLE_AQUI pela chave da API (começa com sk-ant-)';
  end if;
  select column_name into c_chave from information_schema.columns
    where table_schema = 'public' and table_name = 'segredos' and column_name in ('chave', 'nome', 'id')
    order by array_position(array['chave', 'nome', 'id'], column_name::text) limit 1;
  select column_name into c_valor from information_schema.columns
    where table_schema = 'public' and table_name = 'segredos' and column_name in ('valor', 'token', 'value')
    order by array_position(array['valor', 'token', 'value'], column_name::text) limit 1;
  if c_chave is null or c_valor is null then
    return 'tabela segredos sem colunas chave/valor reconhecíveis — conferir: select column_name from information_schema.columns where table_name = ''segredos''';
  end if;
  execute format('insert into public.segredos (%I, %I) values (%L, %L) on conflict (%I) do update set %I = excluded.%I',
    c_chave, c_valor, 'anthropic_key', p_chave, c_chave, c_valor, c_valor);
  execute 'alter table public.segredos enable row level security';
  return 'chave gravada (' || length(p_chave) || ' caracteres, termina em …' || right(p_chave, 4) || ')';
end $$;

-- Compacta o JSON da fase 1 antes de mandar para a IA (menos tokens, mesma informação
-- essencial). nivel 1 = devolutiva (tira só o dia a dia redundante); nivel 2 = painel
-- (fica só resumo/totais por unidade).
create or replace function public.redator_compactar(p jsonb, p_nivel int)
returns jsonb language plpgsql immutable as $$
declare out jsonb := p;
begin
  if p is null or jsonb_typeof(p) <> 'object' then return p; end if;
  out := out - array['apontamentos', 'sem_talhao'];
  if out ? 'pivos' then
    out := jsonb_set(out, '{pivos}', (select coalesce(jsonb_agg(e - 'dias'), '[]'::jsonb) from jsonb_array_elements(out -> 'pivos') e));
  end if;
  if out ? 'chuva' and jsonb_typeof(out -> 'chuva') = 'object' then out := jsonb_set(out, '{chuva}', (out -> 'chuva') - 'dias'); end if;
  if out ? 'movimentacao' then out := jsonb_set(out, '{movimentacao}', (out -> 'movimentacao') - 'movimentos'); end if;
  if p_nivel >= 2 then
    out := out - array['dias', 'pivos', 'equipamentos', 'talhoes', 'divergencias', 'inventario', 'cocho', 'sanidade', 'massa',
      'eventos', 'embarques', 'gmd', 'unidades', 'gantt', 'fito_mes', 'fito_excecoes', 'sem_alias', 'produtos', 'funcoes',
      'solinftec', 'sem_boletim', 'sem_medicao', 'parametros', 'fito_alvos'];
  end if;
  return out;
end $$;

-- Monta (ou remonta) a linha do relatório narrativo em relatorios_gerados a partir das
-- fontes da fase 1 e devolve os dados compactados que vão para a IA.
create or replace function public.redator_montar(p_rel text, p_ini date, p_fim date, p_unidade text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare m record; v_fontes jsonb; v_ant jsonb := null; v_nivel int; v_dados jsonb; v_nome text;
  v_ini_ant date; v_fim_ant date;
begin
  select * into m from public.relatorios_modelos where relatorio = p_rel;
  if m is null then raise exception 'modelo % não cadastrado em relatorios_modelos', p_rel; end if;
  v_nivel := case when m.cadencia = 'mes' then 2 else 1 end;
  select nome into v_nome from public.rel_unidades where id = p_unidade;

  -- fontes do período: por unidade = mesma unidade; grupo = todas as unidades + linha do grupo
  select coalesce(jsonb_agg(jsonb_build_object('relatorio', g.relatorio, 'periodo_ini', g.periodo_ini, 'periodo_fim', g.periodo_fim,
           'unidade', g.unidade_id, 'dados', public.redator_compactar(g.dados, v_nivel)) order by g.relatorio, g.unidade_id nulls first, g.periodo_fim), '[]'::jsonb)
    into v_fontes
  from public.relatorios_gerados g
  where g.relatorio = any(m.fontes)
    and ((m.por_unidade and g.unidade_id = p_unidade) or (not m.por_unidade))
    and (g.periodo_fim = p_fim or (m.cadencia = 'mes' and g.periodo_ini >= p_ini and g.periodo_fim <= p_fim))
    and g.relatorio <> p_rel;

  -- painel: mês anterior (resumos) para o "melhorou × piorou"
  if m.cadencia = 'mes' then
    v_ini_ant := (p_ini - interval '1 month')::date; v_fim_ant := p_ini - 1;
    select coalesce(jsonb_agg(jsonb_build_object('relatorio', g.relatorio, 'unidade', g.unidade_id,
             'dados', public.redator_compactar(g.dados, 2)) order by g.relatorio, g.unidade_id nulls first), '[]'::jsonb)
      into v_ant
    from public.relatorios_gerados g
    where g.relatorio = any(m.fontes) and g.relatorio like '%_mes' and g.periodo_ini = v_ini_ant and g.periodo_fim = v_fim_ant;
  end if;

  v_dados := jsonb_build_object('composto', true, 'modelo', p_rel, 'unidade', p_unidade, 'nome', coalesce(v_nome, 'Grupo LGS'),
    'periodo_ini', p_ini, 'periodo_fim', p_fim, 'fontes', v_fontes, 'mes_anterior', v_ant,
    'resumo', jsonb_build_object('fontes', jsonb_array_length(v_fontes)));
  perform public.rel_gravar(p_rel, p_ini, p_fim, p_unidade, v_dados);
  return v_dados;
end $$;

-- ====================================================================
-- 4. DISPARA: redigir_relatorio(relatorio, ini, fim, unidade) → req_id
-- ====================================================================
create or replace function public.redigir_relatorio(p_rel text, p_ini date, p_fim date, p_unidade text default null)
returns bigint language plpgsql security definer set search_path = public, net as $$
declare m record; v_dados jsonb; v_msg text; v_body jsonb; v_req bigint; v_modelo_ia text := 'claude-sonnet-4-6';
begin
  select * into m from public.relatorios_modelos where relatorio = p_rel and ativo;
  if m is null then raise exception 'modelo % não cadastrado/ativo em relatorios_modelos', p_rel; end if;
  -- relatório da fase 1 com modelo próprio (ex.: alerta): usa a linha que já existe;
  -- relatório narrativo (devolutiva, painel): monta a linha composta pelas fontes
  select dados into v_dados from public.relatorios_gerados
    where relatorio = p_rel and periodo_ini = p_ini and periodo_fim = p_fim and coalesce(unidade_id, '') = coalesce(p_unidade, '')
      and not coalesce((dados ->> 'composto')::boolean, false);
  if v_dados is null then v_dados := public.redator_montar(p_rel, p_ini, p_fim, p_unidade); end if;

  v_msg := 'Hoje é ' || to_char(public.rel_hoje_brt(), 'DD/MM/YYYY') || '. '
    || case when p_unidade is null then 'Grupo LGS (todas as unidades).'
       else 'Unidade: ' || coalesce((select nome from public.rel_unidades where id = p_unidade), p_unidade) || ' (' || p_unidade || ').' end
    || ' Período: ' || to_char(p_ini, 'DD/MM/YYYY') || ' a ' || to_char(p_fim, 'DD/MM/YYYY') || '.'
    || E'\nDados (JSON gerado pelo motor de relatórios do Boletim NCNaves; "sem registro" significa que o gerente não enviou boletim, '
    || 'divergência é "para conferir", nunca erro):\n' || v_dados::text;

  v_body := jsonb_build_object(
    'model', v_modelo_ia,
    'max_tokens', m.max_tokens,
    'system', m.instrucoes,
    'messages', jsonb_build_array(jsonb_build_object('role', 'user', 'content', v_msg)));

  select net.http_post(
    url := 'https://api.anthropic.com/v1/messages',
    body := v_body,
    headers := jsonb_build_object(
      'x-api-key', public.redator_chave(),
      'anthropic-version', '2023-06-01',
      'content-type', 'application/json'),
    timeout_milliseconds := 120000)
  into v_req;

  insert into public.relatorios_reqs (req_id, relatorio, periodo_ini, periodo_fim, unidade_id, modelo_ia)
  values (v_req, p_rel, p_ini, p_fim, p_unidade, v_modelo_ia);
  return v_req;
end $$;

-- ====================================================================
-- 5. COLHE: redator_colher() — lê net._http_response e grava o texto
-- ====================================================================
create or replace function public.redator_colher()
returns integer language plpgsql security definer set search_path = public, net as $$
declare r record; resp record; j jsonb; v_texto text; n int := 0;
begin
  for r in select * from public.relatorios_reqs where status = 'enviado' order by criado_em loop
    select * into resp from net._http_response where id = r.req_id;
    if resp is null then
      if r.criado_em < now() - interval '6 hours' then
        update public.relatorios_reqs set status = 'perdido', erro = 'resposta não encontrada em net._http_response (expirou?)', colhido_em = now() where req_id = r.req_id;
      end if;
      continue;
    end if;
    if resp.status_code = 200 and resp.content is not null then
      begin
        j := resp.content::jsonb;
        select string_agg(c ->> 'text', E'\n') into v_texto from jsonb_array_elements(j -> 'content') c where c ->> 'type' = 'text';
      exception when others then v_texto := null; end;
      if v_texto is null or v_texto = '' then
        update public.relatorios_reqs set status = 'erro', erro = 'resposta 200 sem texto: ' || left(resp.content, 300), colhido_em = now() where req_id = r.req_id;
        continue;
      end if;
      if j ->> 'stop_reason' = 'max_tokens' then v_texto := v_texto || E'\n[texto cortado no limite de tokens — revisar]'; end if;
      update public.relatorios_gerados set texto = v_texto, texto_em = now(), texto_modelo = coalesce(j ->> 'model', r.modelo_ia)
        where relatorio = r.relatorio and periodo_ini = r.periodo_ini and periodo_fim = r.periodo_fim and coalesce(unidade_id, '') = coalesce(r.unidade_id, '');
      update public.relatorios_reqs set status = 'ok', colhido_em = now(),
        tokens_in = (j -> 'usage' ->> 'input_tokens')::int, tokens_out = (j -> 'usage' ->> 'output_tokens')::int
        where req_id = r.req_id;
      n := n + 1;
    else
      update public.relatorios_reqs set status = 'erro', colhido_em = now(),
        erro = coalesce('HTTP ' || resp.status_code || ': ', '') || coalesce(left(resp.content, 400), resp.error_msg, case when resp.timed_out then 'tempo esgotado' end, 'sem conteúdo')
        where req_id = r.req_id;
    end if;
  end loop;
  delete from public.relatorios_reqs where criado_em < now() - interval '120 days';
  return n;
end $$;

-- ====================================================================
-- 6. Rodadas agendadas (reaproveitam o mesmo par para qualquer modelo cadastrado)
-- ====================================================================
-- Dispara todos os modelos ativos da cadência: 'semana' = últimos 7 dias até ontem,
-- uma redação por unidade ativa (ou do grupo); 'mes' = mês anterior fechado.
create or replace function public.redator_disparar(p_cadencia text)
returns integer language plpgsql security definer set search_path = public as $$
declare m record; u record; v_ini date; v_fim date; n int := 0;
begin
  if p_cadencia = 'semana' then v_fim := public.rel_hoje_brt() - 1; v_ini := public.rel_hoje_brt() - 7;
  elsif p_cadencia = 'mes' then v_ini := (date_trunc('month', public.rel_hoje_brt()) - interval '1 month')::date;
                                v_fim := (date_trunc('month', public.rel_hoje_brt()) - interval '1 day')::date;
  else raise exception 'cadência % desconhecida', p_cadencia; end if;
  for m in select * from public.relatorios_modelos where ativo and cadencia = p_cadencia loop
    if m.por_unidade then
      for u in select id from public.rel_unidades where ativo order by id loop
        begin
          perform public.redigir_relatorio(m.relatorio, v_ini, v_fim, u.id); n := n + 1;
        exception when others then
          insert into public.relatorios_execucoes (relatorio, periodo_ini, periodo_fim, ok, erro) values (m.relatorio || ' (' || u.id || ')', v_ini, v_fim, false, left(sqlerrm, 500));
        end;
      end loop;
    else
      begin
        perform public.redigir_relatorio(m.relatorio, v_ini, v_fim, null); n := n + 1;
      exception when others then
        insert into public.relatorios_execucoes (relatorio, periodo_ini, periodo_fim, ok, erro) values (m.relatorio, v_ini, v_fim, false, left(sqlerrm, 500));
      end;
    end if;
  end loop;
  insert into public.relatorios_execucoes (relatorio, periodo_ini, periodo_fim, ok, erro) values ('redator_disparar ' || p_cadencia, v_ini, v_fim, true, n || ' pedido(s)');
  return n;
end $$;

create or replace function public.redator_rodar_colheita()
returns void language plpgsql security definer set search_path = public as $$
declare n int;
begin
  n := public.redator_colher();
  insert into public.relatorios_execucoes (relatorio, ok, erro) values ('redator_colher', true, n || ' texto(s) gravado(s)');
exception when others then
  insert into public.relatorios_execucoes (relatorio, ok, erro) values ('redator_colher', false, left(sqlerrm, 500));
end $$;

-- Trancar: nunca pela chave publishable do app
revoke all on function public.redator_chave() from public, anon, authenticated;
revoke all on function public.redator_gravar_chave(text) from public, anon, authenticated;
revoke all on function public.redator_compactar(jsonb, int) from public, anon, authenticated;
revoke all on function public.redator_montar(text, date, date, text) from public, anon, authenticated;
revoke all on function public.redigir_relatorio(text, date, date, text) from public, anon, authenticated;
revoke all on function public.redator_colher() from public, anon, authenticated;
revoke all on function public.redator_disparar(text) from public, anon, authenticated;
revoke all on function public.redator_rodar_colheita() from public, anon, authenticated;

-- ====================================================================
-- 7. Agenda pg_cron (UTC; Brasília = UTC-3). A fase 1 já gerou os números
--    às 05:00/05:10 (sexta) e 05:20 (dia 1); o redator vem depois.
-- ====================================================================
do $$
declare j record;
begin
  for j in select jobid from cron.job where jobname in ('redator-semana-dispara', 'redator-semana-colhe', 'redator-mes-dispara', 'redator-mes-colhe') loop
    perform cron.unschedule(j.jobid);
  end loop;
end $$;
select cron.schedule('redator-semana-dispara', '20 8 * * 5', $$select public.redator_disparar('semana')$$);   -- sexta 05:20 BRT
select cron.schedule('redator-semana-colhe',   '35 8 * * 5', $$select public.redator_rodar_colheita()$$);     -- sexta 05:35 BRT
select cron.schedule('redator-mes-dispara',    '20 8 8 * *', $$select public.redator_disparar('mes')$$);      -- dia 8 05:20 BRT
select cron.schedule('redator-mes-colhe',      '35 8 8 * *', $$select public.redator_rodar_colheita()$$);     -- dia 8 05:35 BRT
