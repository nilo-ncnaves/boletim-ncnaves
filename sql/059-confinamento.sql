-- ====================================================================
-- 059 — Módulo de confinamento: lotes, diário, eventos, pesagens,
--       sanidade e saídas  ·  v102
-- ====================================================================
-- Objetos: cf_lotes, cf_diario, cf_eventos, cf_pesagens, cf_sanidade,
-- cf_saidas e as visões vw_cf_diario_lote e vw_cf_lote_resumo (leitura).
-- Rodar no SQL Editor do Supabase (projeto syvehtgrbqteyuqhoban).
--
-- PASSO A PASSO (pelo iPhone):
--   1. Abra o Supabase e entre no projeto do Boletim.
--   2. Toque em "SQL Editor" e em "New query".
--   3. Selecione TODO o texto deste arquivo, copie e cole na caixa.
--   4. Toque em "Run".
--   5. No fim aparece uma tabelinha de conferência. Pode rodar de novo
--      quantas vezes quiser: nada duplica e nada se apaga.
--
-- O QUE É. O confinamento virou unidade de negócio própria na
-- controladoria (ao lado de grãos, café e pecuária de pasto). A unidade
-- mínima de custo é o LOTE — código CF-<sigla da fazenda>-<ano>-<nº>,
-- gerado pelo app na entrada; lote misto de Nelore e cruzado Angus vira
-- dois lotes, mesmo no mesmo curral. O FarmTell Beef cuida do trato; o
-- app registra o que ele não captura: eventos do lote, pesagens,
-- sanidade, condições do dia e a leitura do gerente.
--
--   • cf_lotes     = um lote por entrada (curral atual, grupo genético,
--                    cabeças e peso de balança na entrada, origem, preço de
--                    referência, GTA, status, projeção vigente em payload).
--   • cf_diario    = um registro por unidade e dia (clima do dia e, em
--                    payload.lotes[], uma linha por lote: CMS, sobra de
--                    cocho 0–4, animais na enfermaria, condição do curral).
--   • cf_eventos   = transferência de curral, morte (único lugar que aceita
--                    peso estimado) e leitura semanal do gerente.
--   • cf_pesagens  = pesagem intermediária, só com balança.
--   • cf_sanidade  = tratamento com carência (carencia_ate calculada no
--                    banco); carência trava a saída do lote no app.
--   • cf_saidas    = embarque para o frigorífico pelo gerente e, NA MESMA
--                    LINHA, o romaneio lançado depois pelo escritório.
--   • vw_cf_diario_lote  = uma linha por lote-dia (cruzamento com o FarmTell).
--   • vw_cf_lote_resumo  = dias de cocho, cabeças vivas, mortes, última
--                          pesagem e GMD por lote (leitura; o app calcula o
--                          mesmo no aparelho).
--
-- Na v102 o app grava cf_lotes, cf_diario e cf_eventos (tipo MORTE). As
-- outras três tabelas já nascem aqui para o SQL rodar uma vez só; o app
-- passa a escrevê-las nas próximas versões (pesagem, sanidade, saída).
--
-- COMO O DADO CHEGA: o app grava tudo no aparelho (offline first) e a fila
-- de sincronização sobe cada registro por id, como já faz com boletins,
-- pós-colheita, planejamento e insumos. O app também LÊ estas tabelas a
-- cada sincronização (só quem tem unidade de confinamento no escopo, ou
-- painel).
--
-- ENQUANTO NÃO RODAR: o módulo funciona INTEIRO no aparelho do gerente —
-- só não sincroniza. O diário fica na fila ("Aguardando internet (1 diário
-- na fila)") até o SQL rodar, e aí sobe sozinho; nada se perde.
--
-- VOCABULÁRIO: as telas relatam REGISTRO ("sem pesagem desde a entrada",
-- "sem CMS") — nunca "não fez", "pendente", "atrasado". Nada se apaga:
-- cancelar é status (lote) ou flag (evento/pesagem/saída).
--
-- SEGURANÇA: leitura e escrita anon por policy, como as demais tabelas que
-- o app alimenta (a autorização real é o escopo do código de acesso; ver
-- CLAUDE.md, "Segurança"). Nenhum segredo aqui. Sem policy de delete.
-- ====================================================================

create table if not exists public.cf_lotes (
  id                text primary key,            -- o próprio código do lote: CF-VER-2026-01
  unidade_id        text not null,               -- id da unidade no app (f22f = Vereda — Confinamento)
  ano               integer,
  seq               integer,
  curral_id         text,                        -- talhão tipo CURRAL (curral atual; muda com transferência)
  grupo_genetico    text,                        -- NELORE | CRUZADO_ANGUS
  entrada_data      date not null,
  cabecas_entrada   integer not null,
  peso_entrada_kg   numeric not null,            -- peso médio de balança (kg/cab)
  origem            text,                        -- RECRIA | COMPRA
  status            text not null default 'ATIVO',   -- ATIVO | EM_SAIDA | AGUARDANDO_ROMANEIO | FECHADO | CANCELADO
  payload           jsonb not null,              -- o lote inteiro (fornecedor, preço ref., GTA, projeção vigente, histórico)
  atualizado        timestamptz not null default now()
);
comment on table public.cf_lotes is
  'v102 — um lote de confinamento por entrada. payload.projecao = versão vigente da ficha de entrada (gmdAlvo, diasPrevistos, pesoSaidaKg, cmsPrevisto, rendimentoPct, custoArroba, precoTeto, gmdEquilibrio); payload.projecoes[] = versões anteriores, nunca editadas.';
create unique index if not exists cf_lotes_unidade_ano_seq on public.cf_lotes (unidade_id, ano, seq);
create index if not exists cf_lotes_unidade_status on public.cf_lotes (unidade_id, status);

create table if not exists public.cf_diario (
  id                text primary key,            -- unidade_id || '_' || data
  unidade_id        text not null,
  data              date not null,
  responsavel       text,
  chuva_mm          numeric,
  estresse_termico  boolean,
  payload           jsonb not null,              -- payload.lotes[] = {loteId, cms, sobra (0–4), enfermaria, curral (SECO|UMIDO|LAMA), obs}; payload.obs
  atualizado        timestamptz not null default now(),
  unique (unidade_id, data)
);
comment on table public.cf_diario is
  'v102 — diário do confinamento: um registro por unidade e dia, uma linha por lote ativo dentro do payload. O número de mortes do dia vem de cf_eventos (nunca é digitado duas vezes).';

create table if not exists public.cf_eventos (
  id                text primary key,
  unidade_id        text not null,
  lote_id           text not null,
  data              date not null,
  tipo              text not null,               -- TRANSFERENCIA | MORTE | LEITURA_SEMANAL
  cabecas           integer,                     -- morte
  causa             text,                        -- morte (lista curta do app)
  peso_estimado_kg  numeric,                     -- morte — o único peso estimado do app
  cancelado         boolean not null default false,   -- "desfazer" no app: nada se apaga
  payload           jsonb not null,              -- transferência: curralDe/curralPara; leitura semanal: rumo/motivo/pedido
  atualizado        timestamptz not null default now()
);
comment on table public.cf_eventos is
  'v102 — eventos do lote que não são pesagem, sanidade nem saída. cancelado = desfeito pelo gerente (fica para a trilha).';
create index if not exists cf_eventos_lote on public.cf_eventos (lote_id, data);

create table if not exists public.cf_pesagens (
  id                text primary key,
  unidade_id        text not null,
  lote_id           text not null,
  data              date not null,
  cabecas_pesadas   integer not null,
  peso_medio_kg     numeric not null,            -- só com balança: o app não aceita peso estimado aqui
  cancelado         boolean not null default false,
  payload           jsonb not null,
  atualizado        timestamptz not null default now()
);
comment on table public.cf_pesagens is 'v102 — pesagem intermediária do lote (prevista a cada 30 dias, registrada quando ocorre). A de entrada mora em cf_lotes; a de saída, em cf_saidas.';
create index if not exists cf_pesagens_lote on public.cf_pesagens (lote_id, data);

create table if not exists public.cf_sanidade (
  id                text primary key,
  unidade_id        text not null,
  lote_id           text not null,
  data              date not null,
  brinco            text,                        -- vazio = lote inteiro
  cabecas           integer,
  produto           text,
  dose              text,
  motivo            text,                        -- ENFERMARIA | PREVENTIVO | OUTRO
  carencia_dias     integer not null default 0,
  carencia_ate      date generated always as (data + carencia_dias) stored,
  cancelado         boolean not null default false,
  payload           jsonb not null,
  atualizado        timestamptz not null default now()
);
comment on table public.cf_sanidade is 'v102 — tratamento com carência. Enquanto houver carencia_ate >= data da saída em qualquer animal do lote, o app não registra a saída.';
create index if not exists cf_sanidade_lote on public.cf_sanidade (lote_id, carencia_ate);

create table if not exists public.cf_saidas (
  id                text primary key,
  unidade_id        text not null,
  lote_id           text not null,
  data              date not null,
  frigorifico       text,
  cabecas           integer not null,
  peso_vivo_kg      numeric not null,            -- total de balança no embarque
  nota              text,
  -- romaneio (escritório, depois):
  peso_carcaca_kg   numeric,
  rendimento_pct    numeric,                     -- carcaça ÷ vivo, calculado pelo app
  acabamento        text,                        -- escala do frigorífico (1 a 5)
  bonus_valor       numeric,                     -- R$/@
  romaneio_em       timestamptz,
  romaneio_por      text,
  status            text not null default 'ENVIADA',   -- ENVIADA | ROMANEIO_LANCADO
  cancelado         boolean not null default false,
  payload           jsonb not null,
  atualizado        timestamptz not null default now()
);
comment on table public.cf_saidas is 'v102 — embarque pelo gerente e romaneio pelo escritório na mesma linha. O lote fecha com zero cabeças vivas e todos os romaneios lançados.';
create index if not exists cf_saidas_lote on public.cf_saidas (lote_id, data);

-- ---------- gatilho de atualizado ----------
create or replace function public.cf_touch() returns trigger language plpgsql as $$
begin new.atualizado := now(); return new; end $$;
do $$
declare t text;
begin
  foreach t in array array['cf_lotes','cf_diario','cf_eventos','cf_pesagens','cf_sanidade','cf_saidas'] loop
    execute format('drop trigger if exists %I_touch on public.%I', t, t);
    execute format('create trigger %I_touch before insert or update on public.%I for each row execute function public.cf_touch()', t, t);
  end loop;
end $$;

-- ---------- políticas (mesma regra das outras tabelas do app; sem delete) ----------
do $$
declare t text;
begin
  foreach t in array array['cf_lotes','cf_diario','cf_eventos','cf_pesagens','cf_sanidade','cf_saidas'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I_ler on public.%I', t, t);
    execute format('create policy %I_ler on public.%I for select using (true)', t, t);
    execute format('drop policy if exists %I_gravar on public.%I', t, t);
    execute format('create policy %I_gravar on public.%I for insert with check (true)', t, t);
    execute format('drop policy if exists %I_atualizar on public.%I', t, t);
    execute format('create policy %I_atualizar on public.%I for update using (true) with check (true)', t, t);
  end loop;
end $$;

-- ---------- visão: uma linha por lote-dia (para cruzar com o FarmTell) ----------
drop view if exists public.vw_cf_diario_lote;
create view public.vw_cf_diario_lote with (security_invoker = true) as
select d.unidade_id,
       d.data,
       l->>'loteId'                                   as lote_id,
       nullif(replace(l->>'cms', ',', '.'), '')::numeric        as cms_kg_ms,
       nullif(l->>'sobra', '')::integer               as sobra_escore,
       coalesce(nullif(l->>'enfermaria', ''), '0')::integer     as enfermaria,
       l->>'curral'                                   as curral_cond,
       d.chuva_mm,
       d.estresse_termico,
       d.responsavel,
       l->>'obs'                                      as obs,
       (select coalesce(sum(coalesce(e.cabecas, 1)), 0) from public.cf_eventos e
         where e.lote_id = l->>'loteId' and e.tipo = 'MORTE' and e.data = d.data and not e.cancelado) as mortes_dia
  from public.cf_diario d
  cross join lateral jsonb_array_elements(coalesce(d.payload->'lotes', '[]'::jsonb)) l;
comment on view public.vw_cf_diario_lote is 'v102 — o diário aberto em uma linha por lote e dia; mortes_dia vem de cf_eventos.';

-- ---------- visão: resumo do lote (dias, vivas, mortes, última pesagem, GMD) ----------
drop view if exists public.vw_cf_lote_resumo;
create view public.vw_cf_lote_resumo with (security_invoker = true) as
with mortes as (
  select lote_id, sum(coalesce(cabecas, 1)) as mortes from public.cf_eventos where tipo = 'MORTE' and not cancelado group by lote_id),
saidas as (
  select lote_id, sum(cabecas) as saidas from public.cf_saidas where not cancelado group by lote_id),
ult as (
  select distinct on (lote_id) lote_id, data, peso_medio_kg from public.cf_pesagens where not cancelado order by lote_id, data desc)
select l.id as lote_id, l.unidade_id, l.status, l.grupo_genetico, l.curral_id, l.entrada_data, l.cabecas_entrada, l.peso_entrada_kg,
       case when l.status = 'FECHADO' then null else current_date - l.entrada_data end as dias_de_cocho,
       coalesce(m.mortes, 0) as mortes,
       coalesce(s.saidas, 0) as saidas,
       l.cabecas_entrada - coalesce(m.mortes, 0) - coalesce(s.saidas, 0) as cabecas_vivas,
       round(coalesce(m.mortes, 0)::numeric * 100 / nullif(l.cabecas_entrada, 0), 2) as mortalidade_pct,
       u.data as ultima_pesagem,
       u.peso_medio_kg as ultimo_peso_kg,
       case when u.data is not null and u.data > l.entrada_data
            then round((u.peso_medio_kg - l.peso_entrada_kg) / (u.data - l.entrada_data), 3) end as gmd_kg_dia,
       (l.payload->'projecao'->>'gmdAlvo')::numeric as gmd_alvo,
       (l.payload->'projecao'->>'diasPrevistos')::numeric as dias_previstos
  from public.cf_lotes l
  left join mortes m on m.lote_id = l.id
  left join saidas s on s.lote_id = l.id
  left join ult u on u.lote_id = l.id;
comment on view public.vw_cf_lote_resumo is 'v102 — números do lote calculados no banco (o app calcula os mesmos no aparelho). GMD = (último peso − peso de entrada) ÷ dias; sem pesagem, nulo.';

-- ---------- conferência ----------
select 'cf_lotes' as tabela, count(*) as linhas from public.cf_lotes
union all select 'cf_diario', count(*) from public.cf_diario
union all select 'cf_eventos', count(*) from public.cf_eventos
union all select 'cf_pesagens', count(*) from public.cf_pesagens
union all select 'cf_sanidade', count(*) from public.cf_sanidade
union all select 'cf_saidas', count(*) from public.cf_saidas;
