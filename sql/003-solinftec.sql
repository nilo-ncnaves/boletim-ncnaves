-- Robô Solinftec — API "Detalhes da Operação V3" (v48)
-- Rodar no SQL Editor do Supabase (projeto syvehtgrbqteyuqhoban).
--
-- ANTES DE RODAR (1 minuto):
--   Procure abaixo o texto COLE_AQUI_A_SENHA e troque pela senha que
--   está na página 1 do PDF "Configuração API Integração" da Solinftec
--   (campo "password"). A senha fica SÓ no Supabase (tabela
--   solinftec_segredos, trancada), nunca no código do app nem neste
--   arquivo do repositório.
--
-- O que este arquivo faz:
--   1. Liga as extensões http (chamada à API) e pg_cron (agendador).
--   2. Guarda usuário e senha da Solinftec na tabela
--      solinftec_segredos (própria, para não depender da estrutura da
--      tabela segredos antiga da iCrop).
--   3. Cria a tabela solinftec_diario (o app só LÊ ela, como faz com
--      icrop_manejo) + tabelas de-para de fazenda e de operação.
--   4. Cria as funções do robô: gerar token e buscar/gravar o dia.
--   5. Agenda: toda madrugada busca o dia anterior (fechado) e, de
--      hora em hora durante o dia, o dia corrente (parcial).

-- 1. Extensões -------------------------------------------------------
create extension if not exists http with schema extensions;
create extension if not exists pg_cron;

-- 2. Usuário e senha na tabela solinftec_segredos --------------------
-- Tabela própria (a tabela segredos da iCrop tem outra estrutura).
-- Trancada: RLS ligado e sem policies — só o SQL Editor alcança.
create table if not exists public.solinftec_segredos (
  nome text primary key,
  valor text not null
);
alter table public.solinftec_segredos enable row level security;

insert into public.solinftec_segredos (nome, valor) values
  ('solinftec_cliente', 'ncnaves'),
  ('solinftec_senha',   'COLE_AQUI_A_SENHA')  -- <<< trocar pela senha do PDF
on conflict (nome) do update set valor = excluded.valor;

-- 3. Tabelas ---------------------------------------------------------
-- Resumo diário por fazenda/equipamento/operação/talhão.
-- O app (v48) lê: fazenda_id, data, equipamento, operacao, talhao,
-- horas, area_ha, consumo_l.
create table if not exists public.solinftec_diario (
  data         date not null,
  fazenda_sol  text not null default '',  -- nome da fazenda como vem da Solinftec (dsFazenda)
  fazenda_id   text,                      -- id da unidade no app (f03g, f22g, ...), via de-para
  equipamento  text not null default '',
  cd_operacao  text not null default '',  -- código Solinftec da operação
  operacao     text not null default '',  -- nome amigável (de-para) ou "Operação NNN"
  talhao       text not null default '',
  horas        numeric,  -- soma de vlTempoSegundos / 3600
  motor_h      numeric,  -- soma de vlTempoMotorLigado / 3600
  ocioso_h     numeric,  -- soma de vlTempoMotorOcioso / 3600
  area_ha      numeric,  -- soma de vlAreaOperacional
  consumo_l    numeric,  -- soma de vlConsumoMedio (litros por hora somados = litros do dia)
  atualizado_em timestamptz not null default now(),
  primary key (data, fazenda_sol, equipamento, cd_operacao, talhao)
);
comment on table public.solinftec_diario is
  'Resumo diário das máquinas (API Solinftec Detalhes da Operação V3). Gravado pelo robô; o app só lê.';

-- Migração: se a tabela já existia de uma etapa antiga (a "garagem"
-- criada antes da API), garante as colunas novas sem perder dados.
alter table public.solinftec_diario add column if not exists fazenda_sol  text not null default '';
alter table public.solinftec_diario add column if not exists fazenda_id   text;
alter table public.solinftec_diario add column if not exists equipamento  text not null default '';
alter table public.solinftec_diario add column if not exists cd_operacao  text not null default '';
alter table public.solinftec_diario add column if not exists operacao     text not null default '';
alter table public.solinftec_diario add column if not exists talhao       text not null default '';
alter table public.solinftec_diario add column if not exists horas        numeric;
alter table public.solinftec_diario add column if not exists motor_h      numeric;
alter table public.solinftec_diario add column if not exists ocioso_h     numeric;
alter table public.solinftec_diario add column if not exists area_ha      numeric;
alter table public.solinftec_diario add column if not exists consumo_l    numeric;
alter table public.solinftec_diario add column if not exists atualizado_em timestamptz not null default now();

alter table public.solinftec_diario enable row level security;
drop policy if exists "solinftec_diario leitura" on public.solinftec_diario;
create policy "solinftec_diario leitura" on public.solinftec_diario
  for select using (true);
-- sem policy de escrita: só o robô (dono da tabela) grava

-- De-para: pedaço do nome da fazenda na Solinftec -> id da unidade no
-- app. Ajustar depois da primeira carga se algum nome não casar
-- (consulta de conferência no fim deste arquivo).
create table if not exists public.solinftec_depara (
  padrao     text primary key,  -- pedaço do nome, em minúsculas
  fazenda_id text not null
);
insert into public.solinftec_depara (padrao, fazenda_id) values
  ('rio preto', 'f03g'), ('lagamar', 'f03g'),
  ('vereda',    'f22g'),
  ('capoeira',  'f27'),
  ('floramil',  'f33'),
  ('buriti',    'f35'), ('porto', 'f35')
on conflict (padrao) do nothing;

-- De-para: código da operação -> nome amigável. A API só devolve o
-- código (cdOperacao); pedir a lista à Solinftec e preencher aqui.
-- Enquanto vazio, o app mostra "Operação NNN".
create table if not exists public.solinftec_operacoes (
  cd        text primary key,
  descricao text not null
);

alter table public.solinftec_depara    enable row level security;
alter table public.solinftec_operacoes enable row level security;
drop policy if exists "solinftec_depara leitura" on public.solinftec_depara;
create policy "solinftec_depara leitura" on public.solinftec_depara
  for select using (true);
drop policy if exists "solinftec_operacoes leitura" on public.solinftec_operacoes;
create policy "solinftec_operacoes leitura" on public.solinftec_operacoes
  for select using (true);

-- 4. Funções do robô -------------------------------------------------
create or replace function public.solinftec_token()
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_cli text;
  v_sen text;
  resp  extensions.http_response;
begin
  select valor into v_cli from public.solinftec_segredos where nome = 'solinftec_cliente';
  select valor into v_sen from public.solinftec_segredos where nome = 'solinftec_senha';
  if v_sen is null or v_sen like 'COLE_AQUI%' then
    raise exception 'Senha da Solinftec ainda não gravada na tabela solinftec_segredos (nome = solinftec_senha).';
  end if;
  select * into resp from extensions.http((
    'POST',
    'https://scdi.saas-solinftec.com/auth/token',
    array[extensions.http_header('Content-Type', 'application/json')],
    'application/json',
    jsonb_build_object('cliente', v_cli, 'password', v_sen)::text
  )::extensions.http_request);
  if resp.status <> 200 then
    raise exception 'Solinftec /auth/token devolveu status %: %', resp.status, left(resp.content, 300);
  end if;
  return resp.content::jsonb ->> 'token';
end $$;

-- Busca um dia inteiro na API (paginado) e regrava o resumo do dia.
-- Rodar de novo para o mesmo dia é seguro: apaga e grava por cima.
create or replace function public.solinftec_pull(dia date)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  tok   text;
  resp  extensions.http_response;
  corpo jsonb;
  pag   int := 1;
  tot   int := 1;
begin
  perform extensions.http_set_curlopt('CURLOPT_TIMEOUT', '180');
  tok := public.solinftec_token();

  drop table if exists _solinftec_tmp;
  create temp table _solinftec_tmp (l jsonb) on commit drop;

  loop
    select * into resp from extensions.http((
      'POST',
      'https://scdi.saas-solinftec.com/pull',
      array[extensions.http_header('X-Auth-Token', tok),
            extensions.http_header('Content-Type', 'application/json')],
      'application/json',
      jsonb_build_object(
        'identifier', '23',  -- código NC Naves (PDF de configuração da Solinftec)
        'filters', jsonb_build_object(
          'page', pag, 'size', 10000, 'data', to_char(dia, 'DD/MM/YYYY'))
      )::text
    )::extensions.http_request);
    if resp.status <> 200 then
      raise exception 'Solinftec /pull (página %) devolveu status %: %', pag, resp.status, left(resp.content, 300);
    end if;
    corpo := resp.content::jsonb;
    insert into _solinftec_tmp (l)
      select jsonb_array_elements(coalesce(corpo -> 'data', '[]'::jsonb));
    tot := coalesce((corpo ->> 'total_pages')::int, 1);
    exit when pag >= tot;
    pag := pag + 1;
    -- cada resposta traz um token novo (o anterior vence em ~1 min)
    tok := coalesce(corpo ->> 'token', public.solinftec_token());
  end loop;

  delete from public.solinftec_diario where data = dia;

  with linhas as (
    select
      coalesce(l ->> 'dsFazenda', '')                                        as fazenda_sol,
      coalesce(nullif(l ->> 'dsEquipamento', ''), l ->> 'cdEquipamento', '') as equipamento,
      coalesce(l ->> 'cdOperacao', '')                                       as cd_operacao,
      coalesce(l ->> 'dsTalhao', '')                                         as talhao,
      coalesce((l ->> 'vlTempoSegundos')::numeric, 0)                        as seg,
      coalesce((l ->> 'vlTempoMotorLigado')::numeric, 0)                     as motor,
      coalesce((l ->> 'vlTempoMotorOcioso')::numeric, 0)                     as ocioso,
      coalesce((l ->> 'vlAreaOperacional')::numeric, 0)                      as area,
      coalesce((l ->> 'vlConsumoMedio')::numeric, 0)                         as litros
    from _solinftec_tmp
  ),
  ag as (
    select fazenda_sol, equipamento, cd_operacao, talhao,
      sum(seg) seg, sum(motor) motor, sum(ocioso) ocioso,
      sum(area) area, sum(litros) litros
    from linhas
    group by 1, 2, 3, 4
  )
  insert into public.solinftec_diario
    (data, fazenda_sol, fazenda_id, equipamento, cd_operacao, operacao,
     talhao, horas, motor_h, ocioso_h, area_ha, consumo_l)
  select dia, ag.fazenda_sol, dp.fazenda_id, ag.equipamento, ag.cd_operacao,
    coalesce(op.descricao,
      case when ag.cd_operacao = '' then '' else 'Operação ' || ag.cd_operacao end),
    ag.talhao,
    round(ag.seg    / 3600.0, 2),
    round(ag.motor  / 3600.0, 2),
    round(ag.ocioso / 3600.0, 2),
    round(ag.area, 2),
    round(ag.litros, 1)
  from ag
  left join lateral (
    select d.fazenda_id from public.solinftec_depara d
    where lower(ag.fazenda_sol) like '%' || d.padrao || '%'
    limit 1
  ) dp on true
  left join public.solinftec_operacoes op on op.cd = ag.cd_operacao;
end $$;

-- Trancar as funções: só o robô (SQL Editor / pg_cron) pode chamar,
-- nunca a chave publishable do app.
revoke all on function public.solinftec_token() from public, anon, authenticated;
revoke all on function public.solinftec_pull(date) from public, anon, authenticated;

-- 5. Agendamento (horários em UTC; Brasília = UTC-3) -----------------
-- 03:05 da manhã: dia anterior fechado.
select cron.schedule('solinftec-madrugada', '5 6 * * *',
  $$select public.solinftec_pull((now() at time zone 'America/Sao_Paulo')::date - 1)$$);
-- De hora em hora, das 09:35 às 20:35 (Brasília): parcial do dia corrente,
-- para o cartão "medição automática do dia" do gerente.
select cron.schedule('solinftec-dia', '35 12-23 * * *',
  $$select public.solinftec_pull((now() at time zone 'America/Sao_Paulo')::date)$$);

-- ====================================================================
-- CONFERÊNCIAS (rodar depois, uma linha por vez, se quiser testar)
-- ====================================================================
-- Buscar ontem agora mesmo, sem esperar a madrugada:
--   select public.solinftec_pull((now() at time zone 'America/Sao_Paulo')::date - 1);
--
-- Ver o que chegou:
--   select * from public.solinftec_diario order by atualizado_em desc limit 30;
--
-- Fazendas da Solinftec que ficaram SEM unidade do app (ajustar o
-- de-para e depois rodar o update abaixo):
--   select distinct fazenda_sol from public.solinftec_diario where fazenda_id is null;
--   insert into public.solinftec_depara (padrao, fazenda_id) values ('pedaço do nome', 'fXX');
--   update public.solinftec_diario s set fazenda_id = d.fazenda_id
--     from public.solinftec_depara d
--     where s.fazenda_id is null and lower(s.fazenda_sol) like '%' || d.padrao || '%';
--
-- Quando a Solinftec mandar a lista de operações (código -> nome):
--   insert into public.solinftec_operacoes (cd, descricao) values ('205', 'Plantio'), ...;
--   update public.solinftec_diario s set operacao = op.descricao
--     from public.solinftec_operacoes op where op.cd = s.cd_operacao;
