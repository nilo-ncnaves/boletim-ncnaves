-- Relatórios automáticos — FASE 1: motor no Supabase (v55)
-- Rodar no SQL Editor do Supabase (projeto syvehtgrbqteyuqhoban).
--
-- ORDEM DE COLAGEM (cada um só uma vez; pode repetir sem estragar):
--   sql/003-solinftec.sql      (se ainda não rodou — cria solinftec_diario)
--   sql/004-boletim-pecuaria.sql (opcional; o motor lê a pecuária direto de boletins)
--   sql/005 → 006 → 007        (plano de safra; sem eles o relatório
--                               "plano × executado" grava só um aviso)
--   sql/020-relatorios-motor.sql  ← ESTE ARQUIVO
--   sql/021-relatorios-teste.sql  (chamadas manuais para conferir)
--
-- PRINCÍPIO: o Supabase calcula em horário agendado (pg_cron) e grava o
-- resultado pronto em relatorios_gerados; o app só lê e mostra. Nada é
-- calculado no celular além de formatação (nomes de talhão, datas, números).
--
-- O que este arquivo cria:
--   1. rel_unidades      — espelho das 24 unidades do app (id, nome, fazenda
--                          física, perfil, nome no plano). Lista de referência
--                          para o farol dizer quem FALTOU; unidade nova no app
--                          precisa entrar aqui (insert) para aparecer no farol.
--   2. rel_icrop_depara  — pedaço do nome da fazenda na iCrop → fazenda física
--                          (mesmo de-para do DEPARA_ICROP do index.html).
--   3. relatorios_gerados — resultado pronto de cada relatório (uma linha por
--                          unidade e período; unidade_id nulo = linha do grupo).
--                          Leitura anon; escrita só pelas funções (security
--                          definer). relatorios_execucoes = diário de bordo.
--   4. funções geradoras rel_* (uma por relatório) + auxiliares.
--   5. rel_rodar_* — rodadas agendadas, cada relatório protegido por
--                    exception (um erro não derruba os outros).
--   6. agendamento pg_cron (UTC; Brasília = UTC-3): 05:00 BRT = 08:00 UTC.
--
-- Vocabulário dos faróis (regra do projeto): "sem registro", nunca "não fez";
-- diferença entre dito e medido é "para conferir", nunca "erro do gerente".

create extension if not exists pg_cron;

-- ====================================================================
-- 1. Cadastro espelho das unidades do app (constante FAZENDAS do index.html)
-- ====================================================================
create table if not exists public.rel_unidades (
  id          text primary key,          -- id da unidade no app (f01, f03c, ...)
  nome        text not null,
  mae_id      text not null,             -- fazenda física (fazendaMae.id ou o próprio id)
  mae_nome    text not null,
  perfil      text[] not null,           -- CAFE / GRAOS / PECUARIA
  fazenda_app text,                      -- nome EXATO em plano_safra.fazenda_app (PLANO_FAZENDA_APP)
  ativo       boolean not null default true
);
comment on table public.rel_unidades is
  'Espelho das unidades do Boletim NCNaves (index.html → FAZENDAS + PLANO_FAZENDA_APP). Usado pelos relatórios automáticos para saber quem existe. Unidade nova no app: inserir aqui também.';

insert into public.rel_unidades (id, nome, mae_id, mae_nome, perfil, fazenda_app) values
  ('f01',  'Água Limpa',               'f01', 'Água Limpa',               '{CAFE}',     'Água Limpa'),
  ('f03c', 'Rio Preto-Lagamar — Café',  'f03', 'Rio Preto-Lagamar',        '{CAFE}',     'Rio Preto-Lagamar — Café'),
  ('f03g', 'Rio Preto-Lagamar — Grãos', 'f03', 'Rio Preto-Lagamar',        '{GRAOS}',    null),
  ('f13c', 'Mata Preta — Café',         'f13', 'Mata Preta',               '{CAFE}',     'Mata Preta — Café'),
  ('f13p', 'Mata Preta — Pecuária',     'f13', 'Mata Preta',               '{PECUARIA}', null),
  ('f14c', 'Monte Carmelo — Café',      'f14', 'Monte Carmelo',            '{CAFE}',     'Monte Carmelo — Café'),
  ('f14p', 'Monte Carmelo — Pecuária',  'f14', 'Monte Carmelo',            '{PECUARIA}', null),
  ('f21',  'São Félix — Arrendamento',  'f21', 'São Félix — Arrendamento', '{CAFE}',     null),
  ('f22c', 'Vereda — Café',             'f22', 'Vereda',                   '{CAFE}',     'Vereda — Café'),
  ('f22g', 'Vereda — Grãos',            'f22', 'Vereda',                   '{GRAOS}',    null),
  ('f23',  'Vereda Romaria',            'f23', 'Vereda Romaria',           '{CAFE}',     'Vereda Romaria'),
  ('f24',  'Vereda Café 5º e 6º',       'f24', 'Vereda Café 5º e 6º',      '{CAFE}',     'Vereda Café 5º e 6º'),
  ('f20',  'Lagamar Café (Rodrigo)',    'f20', 'Lagamar Café (Rodrigo)',   '{CAFE}',     'Lagamar Café (Rodrigo)'),
  ('f25',  'NC Naves — Armazém Geral',  'f25', 'NC Naves — Armazém Geral', '{CAFE}',     null),
  ('f26',  'Água Santa',                'f26', 'Água Santa',               '{PECUARIA}', null),
  ('f27',  'Capoeira Grande',           'f27', 'Capoeira Grande',          '{GRAOS}',    null),
  ('f28',  'Chapada',                   'f28', 'Chapada',                  '{PECUARIA}', null),
  ('f29',  'Chapadão',                  'f29', 'Chapadão',                 '{PECUARIA}', null),
  ('f30',  'Confins',                   'f30', 'Confins',                  '{PECUARIA}', null),
  ('f31',  'Cra Cra',                   'f31', 'Cra Cra',                  '{PECUARIA}', null),
  ('f32',  'Ferragem',                  'f32', 'Ferragem',                 '{PECUARIA}', null),
  ('f33',  'Floramill',                 'f33', 'Floramill',                '{GRAOS}',    null),
  ('f34',  'Gameleira',                 'f34', 'Gameleira',                '{PECUARIA}', null),
  ('f35',  'Porto Buriti',              'f35', 'Porto Buriti',             '{GRAOS}',    null)
on conflict (id) do update set nome = excluded.nome, mae_id = excluded.mae_id,
  mae_nome = excluded.mae_nome, perfil = excluded.perfil, fazenda_app = excluded.fazenda_app;

-- iCrop: pedaço do nome da fazenda (minúsculas) → fazenda física (DEPARA_ICROP)
create table if not exists public.rel_icrop_depara (
  padrao text primary key,
  mae_id text not null
);
insert into public.rel_icrop_depara (padrao, mae_id) values
  ('rio preto', 'f03'), ('vereda', 'f22'), ('floramil', 'f33'), ('capoeira grande', 'f27')
on conflict (padrao) do nothing;

-- ====================================================================
-- 2. Resultado pronto + diário de bordo
-- ====================================================================
create table if not exists public.relatorios_gerados (
  id          bigint generated always as identity primary key,
  relatorio   text not null,             -- farol_7, farol_30, dito_medido_icrop_dia, ... (lista em docs/relatorios.md)
  periodo_ini date not null,
  periodo_fim date not null,
  unidade_id  text,                      -- id da unidade no app; nulo = linha do grupo (só a Diretoria lê)
  gerado_em   timestamptz not null default now(),
  dados       jsonb not null,            -- resultado pronto (formato em docs/relatorios.md)
  texto       text                       -- reservado: texto pronto p/ WhatsApp (hoje o app formata a partir de dados)
);
comment on table public.relatorios_gerados is
  'Relatórios automáticos do Boletim NCNaves (v55): o pg_cron calcula e grava; o app só lê (últimos 60 dias, unidades do escopo). Uma linha por relatório × período × unidade; unidade_id nulo = grupo.';
create unique index if not exists relatorios_gerados_chave
  on public.relatorios_gerados (relatorio, periodo_ini, periodo_fim, (coalesce(unidade_id, '')));
create index if not exists relatorios_gerados_periodo
  on public.relatorios_gerados (periodo_fim desc, unidade_id);

alter table public.relatorios_gerados enable row level security;
drop policy if exists "relatorios_gerados leitura" on public.relatorios_gerados;
create policy "relatorios_gerados leitura" on public.relatorios_gerados
  for select using (true);
-- sem policy de insert/update/delete: só as funções (security definer, dono da tabela) gravam

create table if not exists public.relatorios_execucoes (
  id        bigint generated always as identity primary key,
  relatorio text not null,
  periodo_ini date,
  periodo_fim date,
  ok        boolean not null,
  erro      text,
  quando    timestamptz not null default now()
);
comment on table public.relatorios_execucoes is 'Diário de bordo das rodadas agendadas (vistoria de segunda lê aqui).';
alter table public.relatorios_execucoes enable row level security;
drop policy if exists "relatorios_execucoes leitura" on public.relatorios_execucoes;
create policy "relatorios_execucoes leitura" on public.relatorios_execucoes
  for select using (true);
alter table public.rel_unidades enable row level security;
drop policy if exists "rel_unidades leitura" on public.rel_unidades;
create policy "rel_unidades leitura" on public.rel_unidades for select using (true);
alter table public.rel_icrop_depara enable row level security;
drop policy if exists "rel_icrop_depara leitura" on public.rel_icrop_depara;
create policy "rel_icrop_depara leitura" on public.rel_icrop_depara for select using (true);

-- ====================================================================
-- 3. Auxiliares
-- ====================================================================
-- hoje em Brasília (as rodadas são às 5h; "ontem" é o dia fechado)
create or replace function public.rel_hoje_brt() returns date
language sql stable as $$ select (now() at time zone 'America/Sao_Paulo')::date $$;

-- ids antigos de fazenda gravados por versões velhas do app (FZ_LEGADO do index.html)
create or replace function public.rel_fz_atual(p text) returns text
language sql immutable as $$
  select case p when 'f19' then 'f03c' when 'f18' then 'f03c' when 'f05' then 'f14c'
    when 'f15' then 'f14c' when 'f16' then 'f14c' when 'f03' then 'f03c' when 'f22' then 'f22c'
    when 'f13' then 'f13c' when 'f14' then 'f14c' else p end $$;

-- número seguro: aceita "6", "6,5", "6.5", texto vazio/nulo/lixo vira nulo (n0 do app vira 0)
create or replace function public.rel_num(p text) returns numeric
language sql immutable as $$
  select case when p ~ '^\s*-?\d+([.,]\d+)?\s*$' then replace(trim(p), ',', '.')::numeric else null end $$;
create or replace function public.rel_n0(p text) returns numeric
language sql immutable as $$ select coalesce(public.rel_num(p), 0) $$;

-- problemas de irrigação da iCrop: vem como texto JSON ('[{"descricao":"..."}]') ou texto puro → lista legível
create or replace function public.rel_probs(p text) returns text
language plpgsql immutable as $$
declare j jsonb; out text;
begin
  if p is null or p in ('', 'null', '[]') then return null; end if;
  begin
    j := p::jsonb;
  exception when others then
    return p;
  end;
  if jsonb_typeof(j) = 'array' then
    select string_agg(coalesce(e ->> 'descricao', e ->> 'nome', case when jsonb_typeof(e) = 'string' then e #>> '{}' end), ', ')
      into out from jsonb_array_elements(j) e;
    return nullif(out, '');
  elsif jsonb_typeof(j) = 'object' then
    return coalesce(j ->> 'descricao', j ->> 'nome');
  else
    return p;
  end if;
end $$;

-- número do pivô: "Pivô 01", "01", "Pivo 1 - Vereda" → 1 (chavePivo do app)
create or replace function public.rel_pivo_num(p text) returns integer
language sql immutable as $$ select (regexp_match(coalesce(p, ''), '\d+'))[1]::integer $$;

-- grava (ou regrava) uma linha de resultado
create or replace function public.rel_gravar(p_rel text, p_ini date, p_fim date, p_unidade text, p_dados jsonb, p_texto text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.relatorios_gerados (relatorio, periodo_ini, periodo_fim, unidade_id, gerado_em, dados, texto)
  values (p_rel, p_ini, p_fim, p_unidade, now(), p_dados, p_texto)
  on conflict (relatorio, periodo_ini, periodo_fim, (coalesce(unidade_id, '')))
  do update set dados = excluded.dados, texto = excluded.texto, gerado_em = now();
end $$;

-- linhas da iCrop do período já com a UNIDADE do app resolvida (mesma regra do
-- icropDo do index.html: fazenda física pelo de-para; equipamento/parcela com
-- "caf" no nome → unidade Café, senão → Grãos; fazenda com uma unidade só recebe tudo)
create or replace function public.rel_icrop_periodo(p_ini date, p_fim date)
returns table (unidade_id text, mae_id text, data date, equipamento text, parcela text, pivo int,
  irr numeric, chuva numeric, chuva_pluv numeric, probs text, bruto jsonb)
language sql stable security definer set search_path = public as $$
  with m as (
    select m.fazenda, m.equipamento, m.parcela, m.data::date as data,
      public.rel_num(m.irrigacao_mm::text) as irr, public.rel_num(m.precipitacao_mm::text) as chuva,
      m.bruto,
      lower(coalesce(m.equipamento, '') || ' ' || coalesce(m.parcela, '')) like '%caf%' as eh_cafe
    from public.icrop_manejo m
    where m.data::date between p_ini and p_fim
  ), dp as (
    select m.*, d.mae_id
    from m
    left join lateral (select d.mae_id from public.rel_icrop_depara d
      where lower(m.fazenda) like '%' || d.padrao || '%' order by length(d.padrao) desc limit 1) d on true
  )
  select un.id, dp.mae_id, dp.data, dp.equipamento, dp.parcela, public.rel_pivo_num(dp.equipamento),
    dp.irr, dp.chuva, public.rel_num(dp.bruto ->> 'chuva_pluviometro'),
    public.rel_probs(dp.bruto ->> 'problemas_irrigacao'), dp.bruto
  from dp
  left join lateral (
    select u.id from public.rel_unidades u
    where u.mae_id = dp.mae_id and u.ativo
    order by case
      when (select count(*) from public.rel_unidades u2 where u2.mae_id = dp.mae_id and u2.ativo) = 1 then 0
      when dp.eh_cafe and 'CAFE' = any(u.perfil) then 0
      when not dp.eh_cafe and 'GRAOS' = any(u.perfil) then 0
      else 1 end, u.id
    limit 1) un on true
  where dp.mae_id is not null
$$;

-- boletins do período de uma unidade (ids antigos já convertidos), sem exemplos
create or replace function public.rel_boletins(p_unidade text, p_ini date, p_fim date)
returns table (data date, payload jsonb)
language sql stable security definer set search_path = public as $$
  select distinct on (b.data::date) b.data::date, b.payload
  from public.boletins b
  where public.rel_fz_atual(b.fazenda_id) = p_unidade
    and b.data::date between p_ini and p_fim
    and coalesce((b.payload ->> 'exemplo')::boolean, false) = false
  order by b.data::date, b.id desc
$$;


-- prepara, para UMA unidade, as tabelas temporárias analisadas que as funções
-- usam (_rel_bol: boletins do período; _rel_dias: calendário). Sem isso o
-- planejador estima 1.000 linhas por função e o plano explode em custo.
create or replace function public.rel_prep_bol(p_unidade text, p_ini date, p_fim date)
returns void language plpgsql security definer set search_path = public as $$
begin
  drop table if exists _rel_bol; drop table if exists _rel_dias;
  create temp table _rel_bol on commit drop as select data, payload from public.rel_boletins(p_unidade, p_ini, p_fim);
  create temp table _rel_dias on commit drop as select d::date as data, extract(dow from d) = 0 as domingo from generate_series(p_ini, p_fim, interval '1 day') d;
  analyze _rel_bol; analyze _rel_dias;
end $$;

-- ====================================================================
-- 4. Funções geradoras
-- ====================================================================

-- 4.1 FAROL (7 e 30 dias): por unidade, dias enviados/faltantes, "em dia";
--     linha do grupo com o placar. Domingo não conta (mesma regra do painel).
-- Lê: boletins (fazenda_id, data, payload->>'exemplo').
create or replace function public.rel_farol(p_dias int, p_fim date default null)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_fim date := coalesce(p_fim, public.rel_hoje_brt() - 1);
  v_ini date := coalesce(p_fim, public.rel_hoje_brt() - 1) - (p_dias - 1);
  v_rel text := 'farol_' || p_dias;
  u record; v_dados jsonb; v_grupo jsonb := '[]'::jsonb; v_marcas text;
begin
  for u in select * from public.rel_unidades where ativo order by mae_nome, nome loop
    perform public.rel_prep_bol(u.id, v_ini, v_fim);
    with x as (select d.data, d.domingo, (e.data is not null) as enviado from _rel_dias d left join _rel_bol e using (data))
    select jsonb_build_object(
      'unidade', u.id, 'nome', u.nome, 'mae', u.mae_id, 'mae_nome', u.mae_nome, 'perfil', to_jsonb(u.perfil),
      'periodo_ini', v_ini, 'periodo_fim', v_fim,
      'dias', jsonb_agg(jsonb_build_object('data', x.data, 'enviado', x.enviado, 'domingo', x.domingo) order by x.data),
      'uteis', count(*) filter (where not x.domingo),
      'enviados', count(*) filter (where x.enviado and not x.domingo),
      'faltantes', count(*) filter (where not x.enviado and not x.domingo),
      'enviados_total', count(*) filter (where x.enviado),
      'em_dia', coalesce(bool_or(x.enviado and x.data >= v_fim - 1), false),
      'ultimo_envio', max(x.data) filter (where x.enviado),
      'marcas', string_agg(case when x.enviado then '●' when x.domingo then '–' else '○' end, ' ' order by x.data))
    into v_dados from x;
    perform public.rel_gravar(v_rel, v_ini, v_fim, u.id, v_dados);
    v_grupo := v_grupo || jsonb_build_object('unidade', u.id, 'nome', u.nome, 'mae', u.mae_id, 'mae_nome', u.mae_nome,
      'enviados', v_dados -> 'enviados', 'uteis', v_dados -> 'uteis', 'faltantes', v_dados -> 'faltantes',
      'em_dia', v_dados -> 'em_dia', 'ultimo_envio', v_dados -> 'ultimo_envio', 'marcas', v_dados -> 'marcas');
  end loop;
  select jsonb_build_object('periodo_ini', v_ini, 'periodo_fim', v_fim, 'dias', p_dias,
      'unidades', v_grupo,
      'total', jsonb_array_length(v_grupo),
      'em_dia', (select count(*) from jsonb_array_elements(v_grupo) e where (e ->> 'em_dia')::boolean),
      'enviados', (select coalesce(sum((e ->> 'enviados')::int), 0) from jsonb_array_elements(v_grupo) e),
      'uteis', (select coalesce(sum((e ->> 'uteis')::int), 0) from jsonb_array_elements(v_grupo) e),
      'placar', (select count(*) from jsonb_array_elements(v_grupo) e where (e ->> 'em_dia')::boolean)
                || ' de ' || jsonb_array_length(v_grupo) || ' unidades em dia')
  into v_dados;
  perform public.rel_gravar(v_rel, v_ini, v_fim, null, v_dados);
end $$;

-- 4.2 DITO × MEDIDO iCROP (dia ou semana): por unidade e pivô, status informado
--     × lâmina medida, chuva digitada × pluviômetro, divergências.
-- Lê: boletins.payload (irg[] nome/status/lamina/percent — grãos; irr.status — café;
--     clima.chuvaMm) e icrop_manejo (fazenda, equipamento, parcela, data,
--     irrigacao_mm, precipitacao_mm, bruto->>chuva_pluviometro, bruto->>problemas_irrigacao).
create or replace function public.rel_dito_medido_icrop(p_ini date, p_fim date)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_rel text := case when p_ini = p_fim then 'dito_medido_icrop_dia' else 'dito_medido_icrop_semana' end;
  u record; v_dados jsonb;
begin
  drop table if exists _rel_ic; create temp table _rel_ic on commit drop as
    select * from public.rel_icrop_periodo(p_ini, p_fim) where unidade_id is not null;
  analyze _rel_ic;

  for u in select * from public.rel_unidades where ativo and mae_id in (select mae_id from public.rel_icrop_depara)
           order by mae_nome, nome loop
    perform public.rel_prep_bol(u.id, p_ini, p_fim);
    drop table if exists _rel_med; drop table if exists _rel_dito; drop table if exists _rel_dd;
    create temp table _rel_med on commit drop as  -- medição por pivô e dia (soma das parcelas, como o cartão do app)
      select equipamento, pivo, data, sum(coalesce(irr, 0)) as mm, bool_or(coalesce(irr, 0) > 0) as regou,
        max(chuva) as chuva, max(chuva_pluv) as chuva_pluv,
        string_agg(distinct probs, ' · ') filter (where probs is not null) as probs
      from _rel_ic where unidade_id = u.id group by 1, 2, 3;
    create temp table _rel_dito on commit drop as  -- grãos: uma linha por pivô lançado; café: status da irrigação (gotejo) vale para a unidade
      select b.data, coalesce(e ->> 'nome', e ->> 'k') as nome, public.rel_pivo_num(e ->> 'nome') as pivo,
        e ->> 'status' as status, public.rel_num(e ->> 'lamina') as lamina, public.rel_num(e ->> 'percent') as percent, false as cafe
      from _rel_bol b cross join lateral jsonb_array_elements(coalesce(b.payload -> 'irg', '[]'::jsonb)) e
      where coalesce(e ->> 'status', '') <> ''
      union all
      select b.data, 'irrigação (gotejo)', null, b.payload -> 'irr' ->> 'status', null, null, true
      from _rel_bol b where coalesce(b.payload -> 'irr' ->> 'status', '') <> '' and 'CAFE' = any(u.perfil);
    analyze _rel_med; analyze _rel_dito;
    create temp table _rel_dd on commit drop as
    with
    med as (select * from _rel_med), bol as (select * from _rel_bol), dito as (select * from _rel_dito),
    chave as (  -- pivôs conhecidos: os da iCrop e os do boletim, casados pelo número
      select pivo, max(equipamento) as equipamento, max(nome) as nome from (
        select pivo, equipamento, null::text as nome from med
        union all
        select pivo, null, nome from dito where not cafe) k
      group by pivo),
    dia_pivo as (
      select k.pivo, k.equipamento, k.nome, g.data,
        m.mm, m.regou, m.probs, (m.data is not null) as mediu,
        d.status, d.lamina, d.percent, (b.data is not null) as tem_boletim,
        c.status as status_cafe
      from chave k
      cross join _rel_dias g
      left join med m on m.pivo is not distinct from k.pivo and m.data = g.data
      left join dito d on d.pivo is not distinct from k.pivo and not d.cafe and d.data = g.data
      left join (select distinct data from bol) b on b.data = g.data
      left join dito c on c.cafe and c.data = g.data),
    dia_av as (
      select *,
        coalesce(status, status_cafe) as st,
        case
          when coalesce(status, status_cafe) in ('Rodou', 'Parcial', 'Rodou normal', 'Rodou com problema') then 'rodou'
          when coalesce(status, status_cafe) in ('Não rodou', 'Manutenção', 'Dia sem irrigação') then 'nao_rodou'
          else null end as dito_cls
      from dia_pivo),
    dia_div as (
      select *,
        array_remove(array[
          case when dito_cls = 'rodou' and mediu and not regou then 'disse_rodou_sem_lamina' end,
          case when dito_cls = 'nao_rodou' and mediu and regou then 'disse_nao_rodou_com_lamina' end,
          case when lamina > 0 and regou and abs(lamina - mm) > greatest(1, 0.2 * mm) then 'lamina_diferente' end,
          case when dito_cls = 'rodou' and not mediu then 'sem_medicao' end,
          case when mediu and regou and not tem_boletim then 'sem_registro' end
        ], null) as div
      from dia_av)
    select * from dia_div;
    analyze _rel_dd;
    with med as (select * from _rel_med), bol as (select * from _rel_bol), dia_div as (select * from _rel_dd),
    pivos as (
      select jsonb_agg(jsonb_build_object(
          'pivo', pivo, 'equipamento', equipamento, 'nome_boletim', nome,
          'dias', dias, 'lamina_inf_total', lamina_inf, 'lamina_med_total', lamina_med,
          'dias_rodou_inf', dias_rodou_inf, 'dias_regou_med', dias_regou_med, 'n_div', n_div)
        order by pivo nulls last) as j
      from (
        select pivo, max(equipamento) equipamento, max(nome) nome,
          jsonb_agg(jsonb_build_object('data', data, 'status', st, 'lamina_inf', lamina, 'percent', percent,
            'lamina_med', case when mediu then mm end, 'regou', regou, 'probs', probs, 'boletim', tem_boletim, 'div', to_jsonb(div)) order by data) as dias,
          sum(coalesce(lamina, 0)) as lamina_inf, sum(coalesce(mm, 0)) as lamina_med,
          count(*) filter (where dito_cls = 'rodou') as dias_rodou_inf,
          count(*) filter (where regou) as dias_regou_med,
          sum(cardinality(div)) as n_div
        from dia_div group by pivo) p),
    divs as (
      select coalesce(jsonb_agg(jsonb_build_object('data', data, 'pivo', pivo, 'nome', coalesce(nome, equipamento), 'tipo', t,
          'texto', case t
            when 'disse_rodou_sem_lamina' then 'boletim disse "' || st || '" e a iCrop não mediu lâmina'
            when 'disse_nao_rodou_com_lamina' then 'boletim disse "' || st || '" e a iCrop mediu ' || round(mm, 1) || ' mm'
            when 'lamina_diferente' then 'lâmina informada ' || round(lamina, 1) || ' mm × medida ' || round(mm, 1) || ' mm'
            when 'sem_medicao' then 'boletim disse "' || st || '" e não há medição iCrop no dia'
            when 'sem_registro' then 'iCrop mediu ' || round(mm, 1) || ' mm e não há boletim no dia (sem registro)'
            end) order by data, pivo), '[]'::jsonb) as j
      from dia_div, unnest(div) t),
    chuva_dia as (
      select g.data, public.rel_num(b.payload -> 'clima' ->> 'chuvaMm') as digitada,
        (select max(chuva) from med m where m.data = g.data) as estacao,
        (select max(chuva_pluv) from med m where m.data = g.data) as pluv,
        (b.data is not null) as boletim
      from _rel_dias g
      left join bol b on b.data = g.data),
    chuva as (
      select jsonb_build_object(
        'digitada', sum(coalesce(digitada, 0)), 'estacao', sum(coalesce(estacao, 0)), 'pluviometro', sum(coalesce(pluv, 0)),
        'dias_div', count(*) filter (where boletim and estacao is not null and abs(coalesce(digitada, 0) - estacao) > 5),
        'dias', jsonb_agg(jsonb_build_object('data', data, 'digitada', digitada, 'estacao', estacao, 'pluviometro', pluv,
          'div', (boletim and estacao is not null and abs(coalesce(digitada, 0) - estacao) > 5)) order by data)) as j
      from chuva_dia),
    sem as (
      select
        (select coalesce(jsonb_agg(data order by data), '[]'::jsonb) from
          (select distinct data from med where data not in (select data from bol)) s) as sem_boletim,
        (select coalesce(jsonb_agg(data order by data), '[]'::jsonb) from
          (select distinct data from bol where data not in (select data from med)) s) as sem_medicao)
    select jsonb_build_object(
      'unidade', u.id, 'nome', u.nome, 'mae', u.mae_id, 'mae_nome', u.mae_nome,
      'periodo_ini', p_ini, 'periodo_fim', p_fim,
      'pivos', coalesce((select j from pivos), '[]'::jsonb),
      'chuva', (select j from chuva),
      'divergencias', (select j from divs),
      'sem_boletim', (select sem_boletim from sem), 'sem_medicao', (select sem_medicao from sem),
      'resumo', jsonb_build_object(
        'n_div', jsonb_array_length((select j from divs)),
        'dias_sem_boletim', jsonb_array_length((select sem_boletim from sem)),
        'dias_sem_medicao', jsonb_array_length((select sem_medicao from sem)),
        'tem_dados', ((select count(*) from med) > 0 or (select count(*) from bol) > 0)))
    into v_dados;
    perform public.rel_gravar(v_rel, p_ini, p_fim, u.id, v_dados);
  end loop;
end $$;

-- 4.3 DITO × MEDIDO SOLINFTEC (dia ou semana): por fazenda física (as máquinas
--     são da fazenda; unidades irmãs recebem a mesma linha), equipamento e
--     talhão: horas/área medidas × máquinas apontadas no boletim, divergências.
-- Lê: solinftec_diario (fazenda_id, data, equipamento, operacao, cd_operacao,
--     talhao, horas, motor_h, ocioso_h, area_ha, consumo_l) e
--     boletins.payload.atividades[] (tipo, talhaoId, maquinas[] nome/horas/comb).
create or replace function public.rel_dito_medido_solinftec(p_ini date, p_fim date)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_rel text := case when p_ini = p_fim then 'dito_medido_solinftec_dia' else 'dito_medido_solinftec_semana' end;
  m record; u record; v_dados jsonb;
begin
  if to_regclass('public.solinftec_diario') is null then
    perform public.rel_gravar(v_rel, p_ini, p_fim, null,
      jsonb_build_object('aviso', 'tabela solinftec_diario ainda não existe — rodar sql/003-solinftec.sql'));
    return;
  end if;
  drop table if exists _rel_sol; create temp table _rel_sol on commit drop as
    select ru.mae_id, s.data::date as data, s.equipamento, s.operacao, s.cd_operacao, s.talhao,
      coalesce(s.horas, 0) as horas, coalesce(s.motor_h, 0) as motor_h, coalesce(s.ocioso_h, 0) as ocioso_h,
      coalesce(s.area_ha, 0) as area_ha, coalesce(s.consumo_l, 0) as litros
    from public.solinftec_diario s
    join public.rel_unidades ru on ru.id = public.rel_fz_atual(s.fazenda_id)
    where s.data::date between p_ini and p_fim;

  for m in select distinct mae_id, mae_nome from public.rel_unidades where ativo order by 1 loop
    drop table if exists _rel_bolm; drop table if exists _rel_maq; drop table if exists _rel_medm; drop table if exists _rel_dias;
    create temp table _rel_bolm on commit drop as
      select ru.id as unidade_id, b.data, b.payload
      from public.rel_unidades ru cross join lateral public.rel_boletins(ru.id, p_ini, p_fim) b
      where ru.mae_id = m.mae_id and ru.ativo;
    create temp table _rel_maq on commit drop as  -- máquinas apontadas no boletim (todas as unidades da fazenda física)
      select b.unidade_id, b.data, a ->> 'tipo' as operacao, a ->> 'talhaoId' as talhao_id,
        q ->> 'nome' as maquina, public.rel_pivo_num(coalesce(substring(q ->> 'nome' from 'COD\s*(\d+)'), q ->> 'nome')) as num,
        public.rel_n0(q ->> 'horas') as horas, public.rel_n0(q ->> 'comb') as comb
      from _rel_bolm b
      cross join lateral jsonb_array_elements(coalesce(b.payload -> 'atividades', '[]'::jsonb)) a
      cross join lateral jsonb_array_elements(coalesce(a -> 'maquinas', '[]'::jsonb)) q
      where coalesce(q ->> 'nome', '') <> '';
    create temp table _rel_medm on commit drop as select * from _rel_sol where mae_id = m.mae_id;
    create temp table _rel_dias on commit drop as select d::date as data from generate_series(p_ini, p_fim, interval '1 day') d;
    analyze _rel_bolm; analyze _rel_maq; analyze _rel_medm; analyze _rel_dias;
    with
    bol as (select * from _rel_bolm), maq as (select * from _rel_maq), med as (select * from _rel_medm),
    dias as (
      select g.data,
        coalesce((select sum(horas) from maq where maq.data = g.data), 0) as h_boletim,
        coalesce((select sum(comb) from maq where maq.data = g.data), 0) as diesel_boletim,
        coalesce((select sum(horas) from med where med.data = g.data), 0) as h_medido,
        coalesce((select sum(area_ha) from med where med.data = g.data), 0) as area_medida,
        coalesce((select sum(litros) from med where med.data = g.data), 0) as litros_medidos,
        exists (select 1 from bol where bol.data = g.data) as tem_boletim,
        exists (select 1 from med where med.data = g.data) as tem_medicao
      from _rel_dias g),
    dias_av as (
      select *,
        case
          when tem_medicao and not tem_boletim then 'sem_registro'
          when h_medido > 0 and h_boletim = 0 then 'medido_sem_apontamento'
          when h_boletim > 0 and h_medido = 0 and tem_medicao then 'apontado_sem_medicao'
          when h_boletim > 0 and h_medido > 0 and abs(h_boletim - h_medido) > 0.3 * greatest(h_boletim, h_medido) then 'horas_diferentes'
          end as div
      from dias),
    equip as (
      select e.equipamento, public.rel_pivo_num(e.equipamento) as num,
        sum(e.horas) as horas, sum(e.motor_h) as motor_h, sum(e.ocioso_h) as ocioso_h,
        sum(e.area_ha) as area_ha, sum(e.litros) as litros,
        string_agg(distinct nullif(e.operacao, ''), ' · ') as operacoes,
        string_agg(distinct nullif(e.talhao, ''), ' · ') as talhoes
      from med e group by 1, 2),
    equip_j as (
      select coalesce(jsonb_agg(jsonb_build_object('equipamento', equipamento, 'horas', round(horas, 2), 'motor_h', round(motor_h, 2),
        'ocioso_h', round(ocioso_h, 2), 'ocioso_pct', case when motor_h > 0 then round(100 * ocioso_h / motor_h) end,
        'area_ha', round(area_ha, 2), 'litros', round(litros, 1), 'l_h', case when horas > 0 then round(litros / horas, 1) end,
        'operacoes', operacoes, 'talhoes', talhoes,
        'h_boletim', (select sum(horas) from maq where maq.num = equip.num and equip.num is not null),
        'maquina_boletim', (select string_agg(distinct maquina, ' · ') from maq where maq.num = equip.num and equip.num is not null))
        order by horas desc), '[]'::jsonb) as j from equip),
    talh_j as (
      select coalesce(jsonb_agg(jsonb_build_object('talhao', talhao, 'operacao', operacao, 'horas', round(horas, 2),
        'area_ha', round(area_ha, 2), 'litros', round(litros, 1), 'equipamentos', eqs) order by talhao, operacao), '[]'::jsonb) as j
      from (select coalesce(nullif(talhao, ''), '(sem talhão)') as talhao, coalesce(nullif(operacao, ''), '(sem operação)') as operacao,
              sum(horas) horas, sum(area_ha) area_ha, sum(litros) litros, string_agg(distinct equipamento, ' · ') eqs
            from med group by 1, 2) t),
    apont_j as (
      select coalesce(jsonb_agg(jsonb_build_object('unidade', unidade_id, 'data', data, 'operacao', operacao, 'talhao_id', talhao_id,
        'maquina', maquina, 'horas', horas, 'comb', comb) order by data, unidade_id), '[]'::jsonb) as j from maq),
    divs as (
      select coalesce(jsonb_agg(jsonb_build_object('data', data, 'tipo', div, 'texto', case div
          when 'sem_registro' then 'Solinftec mediu ' || round(h_medido, 1) || ' h e não há boletim no dia (sem registro)'
          when 'medido_sem_apontamento' then 'Solinftec mediu ' || round(h_medido, 1) || ' h; boletim sem máquina apontada'
          when 'apontado_sem_medicao' then 'boletim apontou ' || round(h_boletim, 1) || ' h; Solinftec sem horas no dia'
          when 'horas_diferentes' then 'boletim ' || round(h_boletim, 1) || ' h × Solinftec ' || round(h_medido, 1) || ' h'
          end) order by data), '[]'::jsonb) as j
      from dias_av where div is not null)
    select jsonb_build_object(
      'mae', m.mae_id, 'mae_nome', m.mae_nome, 'periodo_ini', p_ini, 'periodo_fim', p_fim,
      'dias', (select jsonb_agg(jsonb_build_object('data', data, 'h_boletim', round(h_boletim, 2), 'diesel_boletim', round(diesel_boletim, 1),
         'h_medido', round(h_medido, 2), 'area_medida', round(area_medida, 2), 'litros_medidos', round(litros_medidos, 1),
         'boletim', tem_boletim, 'medicao', tem_medicao, 'div', div) order by data) from dias_av),
      'equipamentos', (select j from equip_j), 'talhoes', (select j from talh_j), 'apontamentos', (select j from apont_j),
      'divergencias', (select j from divs),
      'resumo', jsonb_build_object(
        'h_boletim', (select round(sum(h_boletim), 1) from dias), 'h_medido', (select round(sum(h_medido), 1) from dias),
        'area_medida', (select round(sum(area_medida), 1) from dias), 'litros_medidos', (select round(sum(litros_medidos), 1) from dias),
        'n_div', (select jsonb_array_length(j) from divs),
        'tem_dados', ((select count(*) from med) > 0 or (select count(*) from maq) > 0)))
    into v_dados;
    -- grava para cada unidade da fazenda física (irmãs veem o mesmo), só se houve máquina ou medição
    if (v_dados -> 'resumo' ->> 'tem_dados')::boolean then
      for u in select id from public.rel_unidades where mae_id = m.mae_id and ativo loop
        perform public.rel_gravar(v_rel, p_ini, p_fim, u.id, v_dados || jsonb_build_object('unidade', u.id, 'compartilhado', true));
      end loop;
    end if;
  end loop;
end $$;

-- 4.4 IRRIGAÇÃO RECOMENDADO × EXECUTADO (semana): por unidade e pivô/parcela,
--     percentímetro/tempo recomendados × lâmina executada, dias em atraso,
--     R$ necessário × realizado (tudo do bruto da iCrop).
-- Lê: icrop_manejo (irrigacao_mm, etc, eto, bruto->> percentimetro_recomendado,
--     tempo_de_irrigacao, lamina_minima, deficit_previsto, deficit_consolidado,
--     dias_em_atraso, eficiencia_irrigacao, reais_por_irrigacao_necessaria,
--     reais_por_irrigacao_realizada, area_da_parcela, reais_mm_ha).
--     Percentímetro/tempo EXECUTADOS só existem se a iCrop mandar no bruto
--     (chaves tentadas: percentimetro_realizado/executado, tempo_realizado/executado).
create or replace function public.rel_irrigacao_recomendado_executado(p_ini date, p_fim date)
returns void language plpgsql security definer set search_path = public as $$
declare u record; v_dados jsonb;
begin
  drop table if exists _rel_ic2; create temp table _rel_ic2 on commit drop as
    select i.*,
      public.rel_num(i.bruto ->> 'percentimetro_recomendado') as pct_rec,
      public.rel_num(i.bruto ->> 'tempo_de_irrigacao') as tempo_rec,
      public.rel_num(coalesce(i.bruto ->> 'percentimetro_realizado', i.bruto ->> 'percentimetro_executado', i.bruto ->> 'percentimetro')) as pct_exec,
      public.rel_num(coalesce(i.bruto ->> 'tempo_realizado', i.bruto ->> 'tempo_executado', i.bruto ->> 'tempo_de_irrigacao_realizado')) as tempo_exec,
      public.rel_num(i.bruto ->> 'lamina_minima') as lamina_min,
      public.rel_num(i.bruto ->> 'deficit_previsto') as deficit_prev,
      public.rel_num(i.bruto ->> 'deficit_consolidado') as deficit,
      public.rel_num(i.bruto ->> 'dias_em_atraso') as atraso,
      public.rel_num(i.bruto ->> 'eficiencia_irrigacao') as eficiencia,
      public.rel_num(i.bruto ->> 'reais_por_irrigacao_necessaria') as reais_nec,
      public.rel_num(i.bruto ->> 'reais_por_irrigacao_realizada') as reais_real,
      public.rel_num(i.bruto ->> 'area_da_parcela') as area,
      public.rel_num(i.bruto ->> 'reais_mm_ha') as reais_mm
    from public.rel_icrop_periodo(p_ini, p_fim) i where i.unidade_id is not null;
  analyze _rel_ic2;

  for u in select distinct ru.* from public.rel_unidades ru join _rel_ic2 i on i.unidade_id = ru.id order by ru.mae_nome, ru.nome loop
    with
    d as (  -- por pivô (equipamento) e dia: recomendação = máximo entre as parcelas; execução = soma das lâminas
      select equipamento, pivo, data,
        max(pct_rec) pct_rec, max(tempo_rec) tempo_rec, max(pct_exec) pct_exec, max(tempo_exec) tempo_exec,
        max(lamina_min) lamina_min, sum(coalesce(irr, 0)) mm, max(deficit_prev) deficit_prev, max(deficit) deficit,
        max(atraso) atraso, avg(eficiencia) eficiencia, sum(reais_nec) reais_nec, sum(reais_real) reais_real,
        max(area) area, avg(reais_mm) reais_mm, count(*) parcelas
      from _rel_ic2 where unidade_id = u.id group by 1, 2, 3),
    piv as (
      select equipamento, pivo,
        jsonb_agg(jsonb_build_object('data', data, 'pct_rec', pct_rec, 'tempo_rec', tempo_rec, 'pct_exec', pct_exec, 'tempo_exec', tempo_exec,
          'lamina_min', lamina_min, 'mm', round(mm, 1), 'deficit_prev', deficit_prev, 'deficit', deficit, 'atraso', atraso,
          'reais_nec', reais_nec, 'reais_real', reais_real) order by data) as dias,
        count(*) filter (where coalesce(pct_rec, 0) > 0 or coalesce(tempo_rec, 0) > 0) as dias_rec,
        count(*) filter (where mm > 0) as dias_irr,
        count(*) filter (where (coalesce(pct_rec, 0) > 0 or coalesce(tempo_rec, 0) > 0) and mm = 0) as dias_rec_sem_irr,
        count(*) filter (where not (coalesce(pct_rec, 0) > 0 or coalesce(tempo_rec, 0) > 0) and mm > 0) as dias_irr_sem_rec,
        sum(coalesce(lamina_min, 0)) as mm_min_rec, sum(mm) as mm_real,
        sum(coalesce(reais_nec, 0)) as reais_nec, sum(coalesce(reais_real, 0)) as reais_real,
        (array_agg(atraso order by data desc))[1] as atraso_fim, (array_agg(deficit order by data desc))[1] as deficit_fim,
        avg(eficiencia) as eficiencia, max(area) as area, avg(reais_mm) as reais_mm
      from d group by 1, 2)
    select jsonb_build_object(
      'unidade', u.id, 'nome', u.nome, 'mae', u.mae_id, 'mae_nome', u.mae_nome, 'periodo_ini', p_ini, 'periodo_fim', p_fim,
      'pivos', coalesce((select jsonb_agg(jsonb_build_object('pivo', pivo, 'equipamento', equipamento, 'dias', dias,
          'dias_rec', dias_rec, 'dias_irr', dias_irr, 'dias_rec_sem_irr', dias_rec_sem_irr, 'dias_irr_sem_rec', dias_irr_sem_rec,
          'mm_min_rec', round(mm_min_rec, 1), 'mm_real', round(mm_real, 1), 'reais_nec', round(reais_nec, 0), 'reais_real', round(reais_real, 0),
          'dif_reais', round(reais_real - reais_nec, 0), 'atraso', atraso_fim, 'deficit', deficit_fim,
          'eficiencia', round(eficiencia, 0), 'area_ha', area, 'reais_mm', reais_mm,
          'alerta', (coalesce(atraso_fim, 0) >= 3 or dias_rec_sem_irr > 0)) order by pivo nulls last) from piv), '[]'::jsonb),
      'resumo', jsonb_build_object(
        'reais_nec', (select round(sum(reais_nec), 0) from piv), 'reais_real', (select round(sum(reais_real), 0) from piv),
        'mm_min_rec', (select round(sum(mm_min_rec), 1) from piv), 'mm_real', (select round(sum(mm_real), 1) from piv),
        'pivos_atraso', (select count(*) from piv where coalesce(atraso_fim, 0) >= 3),
        'dias_rec_sem_irr', (select sum(dias_rec_sem_irr) from piv),
        'n_alertas', (select count(*) from piv where coalesce(atraso_fim, 0) >= 3 or dias_rec_sem_irr > 0)))
    into v_dados;
    perform public.rel_gravar('irrigacao_rec_exec_semana', p_ini, p_fim, u.id, v_dados);
  end loop;
end $$;

-- 4.5 BALANÇO HÍDRICO (dia): por unidade e pivô — ETo/ETc, déficit, umidade ×
--     segurança, atraso, fase, graus-dia, acumulados (relatório 15 da carteira).
-- Lê: icrop_manejo (eto, etc, irrigacao_mm, precipitacao_mm, bruto->> deficit_consolidado,
--     deficit_previsto, umidade, capacidade_de_campo, umidade_de_seguranca,
--     dias_em_atraso, fase_atual, gd_dia_acumulado, acumulado_irrigacao,
--     acumulado_precipitacao, problemas_irrigacao).
create or replace function public.rel_balanco_hidrico(p_dia date default null)
returns void language plpgsql security definer set search_path = public as $$
declare v_dia date := coalesce(p_dia, public.rel_hoje_brt() - 1); u record; v_dados jsonb;
begin
  drop table if exists _rel_bh; create temp table _rel_bh on commit drop as
    select i.*, public.rel_num(m.eto::text) as eto, public.rel_num(m.etc::text) as etc,
      public.rel_num(i.bruto ->> 'deficit_consolidado') deficit, public.rel_num(i.bruto ->> 'deficit_previsto') deficit_prev,
      public.rel_num(i.bruto ->> 'umidade') umidade, public.rel_num(i.bruto ->> 'capacidade_de_campo') cap_campo,
      public.rel_num(i.bruto ->> 'umidade_de_seguranca') umid_seg, public.rel_num(i.bruto ->> 'dias_em_atraso') atraso,
      nullif(nullif(i.bruto ->> 'fase_atual', 'null'), '') fase, public.rel_num(i.bruto ->> 'gd_dia_acumulado') gd,
      public.rel_num(i.bruto ->> 'acumulado_irrigacao') acum_irr, public.rel_num(i.bruto ->> 'acumulado_precipitacao') acum_chuva
    from public.rel_icrop_periodo(v_dia, v_dia) i
    join public.icrop_manejo m on m.data::date = i.data and m.equipamento = i.equipamento and coalesce(m.parcela, '') = coalesce(i.parcela, '')
    where i.unidade_id is not null;
  analyze _rel_bh;
  for u in select distinct ru.* from public.rel_unidades ru join _rel_bh i on i.unidade_id = ru.id order by ru.mae_nome, ru.nome loop
    select jsonb_build_object('unidade', u.id, 'nome', u.nome, 'mae', u.mae_id, 'mae_nome', u.mae_nome, 'periodo_ini', v_dia, 'periodo_fim', v_dia,
      'chuva', (select max(chuva) from _rel_bh where unidade_id = u.id),
      'pivos', (select jsonb_agg(jsonb_build_object('pivo', pivo, 'equipamento', equipamento, 'parcelas', parcelas,
          'eto', eto, 'etc', etc, 'mm', mm, 'deficit', deficit, 'deficit_prev', deficit_prev, 'umidade', umidade, 'cap_campo', cap_campo,
          'umid_seg', umid_seg, 'umid_baixa', (umidade is not null and umid_seg is not null and umidade < umid_seg),
          'atraso', atraso, 'fase', fase, 'gd', gd, 'acum_irr', acum_irr, 'acum_chuva', acum_chuva, 'probs', probs,
          'alerta', (coalesce(atraso, 0) >= 3 or (umidade is not null and umid_seg is not null and umidade < umid_seg))) order by pivo nulls last)
        from (select equipamento, pivo, count(*) parcelas, max(eto) eto, max(etc) etc, sum(coalesce(irr, 0)) mm, max(deficit) deficit,
                max(deficit_prev) deficit_prev, min(umidade) umidade, max(cap_campo) cap_campo, max(umid_seg) umid_seg, max(atraso) atraso,
                max(fase) fase, max(gd) gd, avg(acum_irr) acum_irr, avg(acum_chuva) acum_chuva,
                string_agg(distinct probs, ' · ') filter (where probs is not null) probs
              from _rel_bh where unidade_id = u.id group by 1, 2) p),
      'resumo', jsonb_build_object('n_alertas', (select count(*) from (select equipamento from _rel_bh where unidade_id = u.id
          group by equipamento having max(coalesce(atraso, 0)) >= 3 or bool_or(umidade is not null and umid_seg is not null and umidade < umid_seg)) a)))
    into v_dados;
    perform public.rel_gravar('balanco_hidrico_dia', v_dia, v_dia, u.id, v_dados);
  end loop;
end $$;

-- 4.6 CUSTO FÍSICO POR TALHÃO (mês): por unidade e talhão, mm irrigados e R$/mm,
--     horas-máquina por operação e diesel, pessoas-dia por função, produtos e
--     doses aplicados (R$ de insumo fica vazio — coluna custo_rs: null, para o ERP).
-- Lê: boletins.payload (atividades[] talhaoId/tipo/pessoas/maquinas[]/insumos[]/
--     produtos[]/receita/areaHa/doses; irg[] k/nome/quimiProdutos[]; irr.fert/
--     fertSetores/fertReceita; mo.funcoes[] nome/prop/pessoas/diar/hx; mo.proprios/diaristas),
--     icrop_manejo (irrigacao_mm, bruto->>reais_mm_ha, reais_por_irrigacao_realizada/necessaria)
--     e solinftec_diario (talhao, operacao, horas, area_ha, consumo_l).
--     Nome do talhão: o app resolve pelo talhao_id (cadastro do index.html);
--     o motor guarda o nome do pivô que o gerente lançou (irg.nome).
create or replace function public.rel_custo_fisico_talhao(p_ini date, p_fim date)
returns void language plpgsql security definer set search_path = public as $$
declare u record; v_dados jsonb; v_tem_sol boolean := to_regclass('public.solinftec_diario') is not null;
begin
  drop table if exists _rel_ic3; create temp table _rel_ic3 on commit drop as
    select i.*, public.rel_num(i.bruto ->> 'reais_mm_ha') reais_mm, public.rel_num(i.bruto ->> 'reais_por_irrigacao_realizada') reais_real,
      public.rel_num(i.bruto ->> 'reais_por_irrigacao_necessaria') reais_nec, public.rel_num(i.bruto ->> 'area_da_parcela') area
    from public.rel_icrop_periodo(p_ini, p_fim) i where i.unidade_id is not null;
  drop table if exists _rel_sol3; create temp table _rel_sol3 (mae_id text, talhao text, operacao text, horas numeric, area_ha numeric, litros numeric) on commit drop;
  if v_tem_sol then
    insert into _rel_sol3
      select ru.mae_id, coalesce(nullif(s.talhao, ''), '(sem talhão)'), coalesce(nullif(s.operacao, ''), '(sem operação)'),
        sum(coalesce(s.horas, 0)), sum(coalesce(s.area_ha, 0)), sum(coalesce(s.consumo_l, 0))
      from public.solinftec_diario s join public.rel_unidades ru on ru.id = public.rel_fz_atual(s.fazenda_id)
      where s.data::date between p_ini and p_fim group by 1, 2, 3;
  end if;

  for u in select * from public.rel_unidades where ativo order by mae_nome, nome loop
    perform public.rel_prep_bol(u.id, p_ini, p_fim);
    drop table if exists _rel_ativ; drop table if exists _rel_piv; drop table if exists _rel_icp;
    drop table if exists _rel_maq; drop table if exists _rel_pess; drop table if exists _rel_prod;
    create temp table _rel_ativ on commit drop as
      select b.data, a, nullif(a ->> 'talhaoId', '') as talhao_id, coalesce(a ->> 'tipo', 'Atividade') as operacao
      from _rel_bol b cross join lateral jsonb_array_elements(coalesce(b.payload -> 'atividades', '[]'::jsonb)) a;
    -- pivôs lançados no boletim: talhão (k) ↔ número do pivô ↔ equipamento iCrop
    create temp table _rel_piv on commit drop as
      select distinct nullif(e ->> 'k', '') as talhao_id, e ->> 'nome' as nome, public.rel_pivo_num(e ->> 'nome') as pivo
      from _rel_bol b cross join lateral jsonb_array_elements(coalesce(b.payload -> 'irg', '[]'::jsonb)) e
      where coalesce(e ->> 'nome', '') <> '';
    create temp table _rel_icp on commit drop as
      select pivo, equipamento, sum(coalesce(irr, 0)) mm, avg(reais_mm) reais_mm, sum(reais_real) reais_real, sum(reais_nec) reais_nec,
        count(distinct data) filter (where coalesce(irr, 0) > 0) dias_irr, max(area) area
      from _rel_ic3 where unidade_id = u.id group by 1, 2;
    analyze _rel_ativ; analyze _rel_piv; analyze _rel_icp;
    create temp table _rel_maq on commit drop as
      select talhao_id, operacao, sum(public.rel_n0(q ->> 'horas')) horas, sum(public.rel_n0(q ->> 'comb')) diesel,
        string_agg(distinct q ->> 'nome', ' · ') maquinas
      from _rel_ativ cross join lateral jsonb_array_elements(coalesce(a -> 'maquinas', '[]'::jsonb)) q
      where coalesce(q ->> 'nome', '') <> '' group by 1, 2;
    create temp table _rel_pess on commit drop as
      select talhao_id, operacao, sum(public.rel_n0(a ->> 'pessoas')) pessoas_dia, count(*) registros from _rel_ativ group by 1, 2;
    create temp table _rel_prod on commit drop as  -- produtos e doses: café (insumos[], receita), grãos (produtos[], adubos, inoculante), quimigação (irg) e fertirrigação (irr)
      with bol as (select * from _rel_bol), ativ as (select * from _rel_ativ)
      select data, talhao_id, operacao, produto, dose, un, qtd, area_ha from (
        select v.data, v.talhao_id, v.operacao, p ->> 'nome' produto, p ->> 'dose' dose, p ->> 'un' un, p ->> 'qtd' qtd,
          public.rel_num(v.a ->> 'areaHa') area_ha
        from ativ v cross join lateral jsonb_array_elements(coalesce(v.a -> 'insumos', '[]'::jsonb) || coalesce(v.a -> 'produtos', '[]'::jsonb)) p
        where coalesce(p ->> 'nome', '') <> ''
        union all
        select v.data, v.talhao_id, v.operacao, 'receita: ' || regexp_replace(v.a ->> 'receita', '\s*\n+\s*', ' · ', 'g'), null, null, null, public.rel_num(v.a ->> 'areaHa')
        from ativ v where coalesce(v.a ->> 'receita', '') <> ''
        union all
        select v.data, v.talhao_id, v.operacao,
          coalesce(nullif(v.a ->> 'produtoAdb', ''), nullif(v.a ->> 'formulacao', ''), nullif(v.a ->> 'produtoInoc', ''),
                   case when v.a ->> 'produtoTipo' <> 'Outro' then v.a ->> 'produtoTipo' end),
          coalesce(nullif(v.a ->> 'doseKgHa', ''), nullif(v.a ->> 'doseTHa', ''), nullif(v.a ->> 'doseInoc', '')),
          case when coalesce(v.a ->> 'doseKgHa', '') <> '' then 'kg/ha' when coalesce(v.a ->> 'doseTHa', '') <> '' then 't/ha' end, null,
          public.rel_num(v.a ->> 'areaHa')
        from ativ v
        where coalesce(nullif(v.a ->> 'produtoAdb', ''), nullif(v.a ->> 'formulacao', ''), nullif(v.a ->> 'produtoInoc', ''),
                       case when v.a ->> 'produtoTipo' <> 'Outro' then v.a ->> 'produtoTipo' end) is not null
        union all
        select b.data, nullif(e ->> 'k', ''), 'Quimigação (' || coalesce(e ->> 'nome', 'pivô') || ')', p ->> 'nome', p ->> 'dose', coalesce(p ->> 'un', 'kg') || '/ha', null, null
        from bol b cross join lateral jsonb_array_elements(coalesce(b.payload -> 'irg', '[]'::jsonb)) e
        cross join lateral jsonb_array_elements(coalesce(e -> 'quimiProdutos', '[]'::jsonb)) p
        where coalesce(p ->> 'nome', '') <> ''
        union all
        select b.data, nullif(s.value #>> '{}', ''), 'Fertirrigação', 'receita: ' || regexp_replace(b.payload -> 'irr' ->> 'fertReceita', '\s*\n+\s*', ' · ', 'g'), null, null, null, null
        from bol b cross join lateral jsonb_array_elements(coalesce(b.payload -> 'irr' -> 'fertSetores', '[]'::jsonb)) s
        where b.payload -> 'irr' ->> 'fert' = 'Sim' and coalesce(b.payload -> 'irr' ->> 'fertReceita', '') <> ''
        union all
        select b.data, null, 'Fertirrigação', 'receita: ' || regexp_replace(b.payload -> 'irr' ->> 'fertReceita', '\s*\n+\s*', ' · ', 'g'), null, null, null, null
        from bol b
        where b.payload -> 'irr' ->> 'fert' = 'Sim' and coalesce(b.payload -> 'irr' ->> 'fertReceita', '') <> ''
          and jsonb_array_length(coalesce(b.payload -> 'irr' -> 'fertSetores', '[]'::jsonb)) = 0
      ) p;
    analyze _rel_maq; analyze _rel_pess; analyze _rel_prod;
    with bol as (select * from _rel_bol), ativ as (select * from _rel_ativ), piv as (select * from _rel_piv), ic_piv as (select * from _rel_icp),
    maq as (select * from _rel_maq), pess as (select * from _rel_pess), prod as (select * from _rel_prod),
    talhoes as (
      select talhao_id from ativ where talhao_id is not null
      union select talhao_id from piv where talhao_id is not null
      union select talhao_id from prod where talhao_id is not null),
    talh_j as (
      select coalesce(jsonb_agg(jsonb_build_object(
          'talhao_id', t.talhao_id, 'nome', (select max(nome) from piv where piv.talhao_id = t.talhao_id),
          'irrigacao', (select jsonb_build_object('equipamento', ic.equipamento, 'mm', round(ic.mm, 1), 'reais_mm', round(ic.reais_mm, 2),
              'reais_real', round(ic.reais_real, 0), 'reais_nec', round(ic.reais_nec, 0), 'dias_irr', ic.dias_irr, 'area_ha', ic.area,
              'reais_estimado', case when ic.reais_real is null and ic.reais_mm is not null and ic.area is not null then round(ic.mm * ic.area * ic.reais_mm, 0) end)
            from piv join ic_piv ic on ic.pivo = piv.pivo where piv.talhao_id = t.talhao_id limit 1),
          'maquinas', (select coalesce(jsonb_agg(jsonb_build_object('operacao', operacao, 'horas', round(horas, 1), 'diesel_l', round(diesel, 1), 'maquinas', maquinas) order by horas desc), '[]'::jsonb)
            from maq where maq.talhao_id = t.talhao_id),
          'horas', (select round(coalesce(sum(horas), 0), 1) from maq where maq.talhao_id = t.talhao_id),
          'diesel_l', (select round(coalesce(sum(diesel), 0), 1) from maq where maq.talhao_id = t.talhao_id),
          'pessoas_dia', (select coalesce(sum(pessoas_dia), 0) from pess where pess.talhao_id = t.talhao_id),
          'operacoes', (select coalesce(jsonb_agg(jsonb_build_object('operacao', operacao, 'pessoas_dia', pessoas_dia, 'registros', registros) order by registros desc), '[]'::jsonb)
            from pess where pess.talhao_id = t.talhao_id),
          'produtos', (select coalesce(jsonb_agg(jsonb_build_object('data', data, 'operacao', operacao, 'produto', produto, 'dose', dose, 'un', un, 'qtd', qtd, 'area_ha', area_ha, 'custo_rs', null) order by data), '[]'::jsonb)
            from prod where prod.talhao_id = t.talhao_id)
        ) order by t.talhao_id), '[]'::jsonb) as j
      from talhoes t),
    func as (
      select coalesce(nullif(f ->> 'nome', ''), '(sem função)') funcao,
        sum(case when public.rel_num(f ->> 'prop') is not null or public.rel_num(f ->> 'diar') is not null then public.rel_n0(f ->> 'prop') else public.rel_n0(f ->> 'pessoas') end) proprios,
        sum(public.rel_n0(f ->> 'diar')) diaristas, sum(public.rel_n0(f ->> 'hx')) horas_extra, count(distinct b.data) dias
      from bol b cross join lateral jsonb_array_elements(coalesce(b.payload -> 'mo' -> 'funcoes', '[]'::jsonb)) f
      where coalesce(f ->> 'nome', '') <> '' group by 1)
    select jsonb_build_object(
      'unidade', u.id, 'nome', u.nome, 'mae', u.mae_id, 'mae_nome', u.mae_nome, 'periodo_ini', p_ini, 'periodo_fim', p_fim,
      'boletins', (select count(*) from bol),
      'talhoes', (select j from talh_j),
      'irrigacao_unidade', (select jsonb_build_object('mm', round(sum(mm), 1), 'reais_real', round(sum(reais_real), 0), 'reais_nec', round(sum(reais_nec), 0),
          'reais_mm', round(avg(reais_mm), 2), 'pivos', count(*)) from ic_piv),
      'sem_talhao', jsonb_build_object(
        'maquinas', (select coalesce(jsonb_agg(jsonb_build_object('operacao', operacao, 'horas', round(horas, 1), 'diesel_l', round(diesel, 1), 'maquinas', maquinas)), '[]'::jsonb) from maq where talhao_id is null),
        'produtos', (select coalesce(jsonb_agg(jsonb_build_object('data', data, 'operacao', operacao, 'produto', produto, 'dose', dose, 'un', un, 'qtd', qtd, 'custo_rs', null) order by data), '[]'::jsonb) from prod where talhao_id is null),
        'pessoas_dia', (select coalesce(sum(pessoas_dia), 0) from pess where talhao_id is null)),
      'funcoes', (select coalesce(jsonb_agg(jsonb_build_object('funcao', funcao, 'proprios', proprios, 'diaristas', diaristas,
          'pessoas_dia', proprios + diaristas, 'horas_extra', horas_extra, 'dias', dias) order by proprios + diaristas desc), '[]'::jsonb) from func),
      'mao_de_obra', (select jsonb_build_object('proprios_dia', sum(public.rel_n0(payload -> 'mo' ->> 'proprios')),
          'diaristas_dia', sum(public.rel_n0(payload -> 'mo' ->> 'diaristas')), 'faltas', sum(public.rel_n0(payload -> 'mo' ->> 'faltas')),
          'horas_extra', sum(public.rel_n0(payload -> 'mo' ->> 'horasExtras'))) from bol),
      'solinftec', (select coalesce(jsonb_agg(jsonb_build_object('talhao', talhao, 'operacao', operacao, 'horas', round(horas, 1), 'area_ha', round(area_ha, 1), 'litros', round(litros, 1)) order by talhao, operacao), '[]'::jsonb)
          from _rel_sol3 where mae_id = u.mae_id),
      'totais', jsonb_build_object(
        'horas', (select round(coalesce(sum(horas), 0), 1) from maq), 'diesel_l', (select round(coalesce(sum(diesel), 0), 1) from maq),
        'pessoas_dia', (select coalesce(sum(pessoas_dia), 0) from pess), 'mm', (select round(coalesce(sum(mm), 0), 1) from ic_piv),
        'reais_irrigacao', (select round(coalesce(sum(reais_real), 0), 0) from ic_piv), 'produtos', (select count(*) from prod),
        'custo_insumos_rs', null),
      'aviso', 'R$ de insumo fica em branco (custo_rs) até a integração com o ERP AgroGestão.')
    into v_dados;
    if (v_dados ->> 'boletins')::int > 0 or (v_dados -> 'irrigacao_unidade' ->> 'pivos')::int > 0 or jsonb_array_length(v_dados -> 'solinftec') > 0 then
      perform public.rel_gravar('custo_fisico_talhao_mes', p_ini, p_fim, u.id, v_dados);
    end if;
  end loop;
end $$;

-- 4.7 REBANHO (mês): por unidade e lote/pasto — inventário (última contagem),
--     nascimentos M/F, mortes e causas, desmama, entradas/saídas, prenhez, GMD
--     (só com duas pesagens do mesmo lote), lotação (pendente: área do pasto não
--     está no Supabase), embarques.
-- Lê: boletins.payload.pecuaria (mov[], lotes[], rep, san[], massa[], nut[], eventos[],
--     cocho/sal/agua) das unidades com perfil PECUARIA.
create or replace function public.rel_rebanho(p_ini date, p_fim date)
returns void language plpgsql security definer set search_path = public as $$
declare u record; v_dados jsonb;
begin
  for u in select * from public.rel_unidades where ativo and 'PECUARIA' = any(perfil) order by mae_nome, nome loop
    perform public.rel_prep_bol(u.id, p_ini, p_fim);
    with
    bol as (select data, payload -> 'pecuaria' as p from _rel_bol where payload ? 'pecuaria'),
    mov as (
      select b.data, m ->> 'tipo' tipo, m ->> 'categoria' categoria, coalesce(public.rel_num(m ->> 'qtd'), 1) qtd, m ->> 'modo' modo,
        m ->> 'sexo' sexo, m ->> 'causa' causa, m ->> 'parto' parto, m ->> 'pastoDe' pasto_de, m ->> 'pastoPara' pasto_para,
        m ->> 'contraparte' contraparte, m ->> 'brinco' brinco
      from bol b cross join lateral jsonb_array_elements(coalesce(b.p -> 'mov', '[]'::jsonb)) m where coalesce(m ->> 'tipo', '') <> ''),
    lotes as (
      select distinct on (coalesce(l ->> 'talhaoId', ''), coalesce(l ->> 'lote', ''))
        coalesce(nullif(l ->> 'talhaoId', ''), '') pasto, coalesce(nullif(l ->> 'lote', ''), '') lote, public.rel_n0(l ->> 'cabecas') cabecas, b.data
      from bol b cross join lateral jsonb_array_elements(coalesce(b.p -> 'lotes', '[]'::jsonb)) l
      where coalesce(l ->> 'talhaoId', '') <> '' or coalesce(l ->> 'lote', '') <> '' or public.rel_n0(l ->> 'cabecas') > 0
      order by coalesce(l ->> 'talhaoId', ''), coalesce(l ->> 'lote', ''), b.data desc),
    ev as (
      select b.data, e ->> 'tipo' tipo, e ->> 'talhaoId' pasto, e ->> 'lote' lote, public.rel_n0(e ->> 'qtd') qtd,
        public.rel_num(e ->> 'pesoMedio') peso, public.rel_num(e ->> 'valor') valor, e ->> 'contraparte' contraparte, e ->> 'produto' produto, e ->> 'obs' obs
      from bol b cross join lateral jsonb_array_elements(coalesce(b.p -> 'eventos', '[]'::jsonb)) e where coalesce(e ->> 'tipo', '') <> ''),
    pes as (select lote, pasto, data, peso from ev where tipo ilike 'Pesagem%' and peso is not null),
    gmd as (
      select coalesce(lote, pasto, '') chave, min(data) de, max(data) ate,
        (array_agg(peso order by data))[1] peso_ini, (array_agg(peso order by data desc))[1] peso_fim, count(*) pesagens
      from pes group by 1 having count(*) >= 2 and max(data) > min(data)),
    rep as (
      select sum(public.rel_n0(b.p -> 'rep' ->> 'dgPrenhes')) prenhes, sum(public.rel_n0(b.p -> 'rep' ->> 'dgVazias')) vazias,
        sum(public.rel_n0(b.p -> 'rep' ->> 'coberturas')) coberturas,
        string_agg(distinct nullif(b.p -> 'rep' ->> 'iatfEtapa', ''), ' · ') iatf_etapas, sum(public.rel_n0(b.p -> 'rep' ->> 'iatfQtd')) iatf_vacas,
        count(*) filter (where coalesce(b.p -> 'rep' ->> 'ocorTouro', '') not in ('', 'OK')) ocorr_touro
      from bol b),
    san as (
      select coalesce(nullif(s ->> 'problema', ''), '(sem problema informado)') problema, count(*) casos, sum(coalesce(public.rel_num(s ->> 'qtd'), 1)) cabecas,
        string_agg(distinct nullif(s ->> 'acao', ''), ' · ') acoes
      from bol b cross join lateral jsonb_array_elements(coalesce(b.p -> 'san', '[]'::jsonb)) s
      where coalesce(s ->> 'problema', '') <> '' or coalesce(s ->> 'acao', '') <> '' group by 1),
    massa as (
      select coalesce(nullif(m ->> 'tipo', ''), 'Manejo em massa') tipo, sum(public.rel_n0(m ->> 'qtd')) cabecas, string_agg(distinct nullif(m ->> 'produto', ''), ' · ') produtos, count(*) vezes
      from bol b cross join lateral jsonb_array_elements(coalesce(b.p -> 'massa', '[]'::jsonb)) m
      where coalesce(m ->> 'tipo', '') <> '' or coalesce(m ->> 'produto', '') <> '' or public.rel_n0(m ->> 'qtd') > 0 group by 1),
    nut as (
      select coalesce(nullif(n ->> 'talhaoId', ''), '(pasto não informado)') pasto,
        count(*) filter (where n ->> 'cocho' = 'Vazio') cocho_vazio, count(*) filter (where n ->> 'cocho' = 'Lambido') cocho_lambido,
        count(*) filter (where n ->> 'cocho' = 'Com sobra') cocho_sobra,
        count(*) filter (where coalesce(n ->> 'agua', '') not in ('', 'OK')) agua_problema,
        sum(public.rel_n0(n ->> 'qtd')) filter (where coalesce(n ->> 'un', 'sacos') = 'sacos') sacos,
        sum(public.rel_n0(n ->> 'qtd')) filter (where n ->> 'un' = 'kg') kg,
        string_agg(distinct nullif(n ->> 'insumo', ''), ' · ') insumos
      from bol b cross join lateral jsonb_array_elements(coalesce(b.p -> 'nut', '[]'::jsonb)) n
      where coalesce(n ->> 'talhaoId', '') <> '' or coalesce(n ->> 'insumo', '') <> '' or coalesce(n ->> 'cocho', '') <> '' group by 1),
    estrut as (
      select count(*) filter (where b.p ->> 'cocho' = 'Problema') cocho_problema, count(*) filter (where b.p ->> 'sal' = 'Problema') sal_problema,
        count(*) filter (where b.p ->> 'agua' = 'Problema') agua_problema,
        count(*) filter (where b.p -> 'pasto' ->> 'condicao' in ('Apertando', 'Crítico')) pasto_apertando
      from bol b)
    select jsonb_build_object(
      'unidade', u.id, 'nome', u.nome, 'mae', u.mae_id, 'mae_nome', u.mae_nome, 'periodo_ini', p_ini, 'periodo_fim', p_fim,
      'boletins', (select count(*) from bol),
      'movimentacao', jsonb_build_object(
        'nascimentos', (select coalesce(sum(qtd), 0) from mov where tipo = 'Nascimento'),
        'nascimentos_m', (select coalesce(sum(qtd), 0) from mov where tipo = 'Nascimento' and sexo = 'Macho'),
        'nascimentos_f', (select coalesce(sum(qtd), 0) from mov where tipo = 'Nascimento' and sexo = 'Fêmea'),
        'partos_assistidos', (select coalesce(sum(qtd), 0) from mov where tipo = 'Nascimento' and parto = 'Assistido'),
        'mortes', (select coalesce(sum(qtd), 0) from mov where tipo = 'Morte'),
        'mortes_causas', (select coalesce(jsonb_agg(jsonb_build_object('causa', causa, 'qtd', q) order by q desc), '[]'::jsonb)
          from (select coalesce(nullif(causa, ''), 'não informada') causa, sum(qtd) q from mov where tipo = 'Morte' group by 1) c),
        'desmamas', (select coalesce(sum(qtd), 0) from mov where tipo = 'Desmama'),
        'mudancas', (select coalesce(sum(qtd), 0) from mov where tipo = 'Mudança de pasto'),
        'entradas', (select coalesce(sum(qtd), 0) from mov where tipo = 'Entrada'),
        'entradas_modo', (select coalesce(jsonb_agg(jsonb_build_object('modo', modo, 'qtd', q)), '[]'::jsonb) from (select coalesce(nullif(modo, ''), '—') modo, sum(qtd) q from mov where tipo = 'Entrada' group by 1) c),
        'saidas', (select coalesce(sum(qtd), 0) from mov where tipo = 'Saída'),
        'saidas_modo', (select coalesce(jsonb_agg(jsonb_build_object('modo', modo, 'qtd', q)), '[]'::jsonb) from (select coalesce(nullif(modo, ''), '—') modo, sum(qtd) q from mov where tipo = 'Saída' group by 1) c),
        'saldo', (select coalesce(sum(case when tipo in ('Nascimento', 'Entrada') then qtd when tipo in ('Morte', 'Saída') then -qtd else 0 end), 0) from mov),
        'por_categoria', (select coalesce(jsonb_agg(jsonb_build_object('categoria', categoria, 'nascimentos', n, 'mortes', m, 'entradas', e, 'saidas', s, 'saldo', n + e - m - s) order by categoria), '[]'::jsonb)
          from (select coalesce(nullif(categoria, ''), '(sem categoria)') categoria,
                  coalesce(sum(qtd) filter (where tipo = 'Nascimento'), 0) n, coalesce(sum(qtd) filter (where tipo = 'Morte'), 0) m,
                  coalesce(sum(qtd) filter (where tipo = 'Entrada'), 0) e, coalesce(sum(qtd) filter (where tipo = 'Saída'), 0) s
                from mov group by 1) c),
        'movimentos', (select coalesce(jsonb_agg(jsonb_build_object('data', data, 'tipo', tipo, 'categoria', categoria, 'qtd', qtd, 'modo', modo, 'sexo', sexo,
            'causa', causa, 'pasto_de', pasto_de, 'pasto_para', pasto_para, 'contraparte', contraparte, 'brinco', brinco) order by data), '[]'::jsonb) from mov)),
      'inventario', (select coalesce(jsonb_agg(jsonb_build_object('pasto', pasto, 'lote', lote, 'cabecas', cabecas, 'data', data, 'lotacao', null) order by pasto, lote), '[]'::jsonb) from lotes),
      'cabecas_contadas', (select coalesce(sum(cabecas), 0) from lotes),
      'reproducao', (select jsonb_build_object('prenhes', prenhes, 'vazias', vazias,
          'taxa_prenhez', case when prenhes + vazias > 0 then round(100 * prenhes / (prenhes + vazias)) end,
          'coberturas', coberturas, 'iatf_etapas', iatf_etapas, 'iatf_vacas', iatf_vacas, 'ocorrencias_touro', ocorr_touro) from rep),
      'sanidade', (select coalesce(jsonb_agg(jsonb_build_object('problema', problema, 'casos', casos, 'cabecas', cabecas, 'acoes', acoes) order by casos desc), '[]'::jsonb) from san),
      'massa', (select coalesce(jsonb_agg(jsonb_build_object('tipo', tipo, 'cabecas', cabecas, 'produtos', produtos, 'vezes', vezes)), '[]'::jsonb) from massa),
      'cocho', (select coalesce(jsonb_agg(jsonb_build_object('pasto', pasto, 'cocho_vazio', cocho_vazio, 'cocho_lambido', cocho_lambido, 'cocho_sobra', cocho_sobra,
          'agua_problema', agua_problema, 'sacos', sacos, 'kg', kg, 'insumos', insumos) order by cocho_vazio desc), '[]'::jsonb) from nut),
      'estrutura', (select jsonb_build_object('cocho_problema', cocho_problema, 'sal_problema', sal_problema, 'agua_problema', agua_problema, 'pasto_apertando', pasto_apertando) from estrut),
      'gmd', (select coalesce(jsonb_agg(jsonb_build_object('lote', chave, 'de', de, 'ate', ate, 'peso_ini', peso_ini, 'peso_fim', peso_fim, 'pesagens', pesagens,
          'gmd_kg_dia', round((peso_fim - peso_ini) / (ate - de), 3))), '[]'::jsonb) from gmd),
      'embarques', (select coalesce(jsonb_agg(jsonb_build_object('data', data, 'tipo', tipo, 'lote', coalesce(lote, pasto), 'cabecas', qtd, 'peso_medio', peso, 'valor', valor, 'contraparte', contraparte, 'obs', obs) order by data), '[]'::jsonb)
          from ev where tipo ilike 'Embarque%' or tipo ilike 'Compra%'),
      'eventos', (select coalesce(jsonb_agg(jsonb_build_object('tipo', tipo, 'vezes', v, 'cabecas', c) order by v desc), '[]'::jsonb) from (select tipo, count(*) v, sum(qtd) c from ev group by 1) e),
      'lotacao', jsonb_build_object('valor', null, 'nota', 'área do pasto não está no Supabase (cadastro de pastos vive no app) — pendente'),
      'resumo', jsonb_build_object(
        'nascimentos', (select coalesce(sum(qtd), 0) from mov where tipo = 'Nascimento'), 'mortes', (select coalesce(sum(qtd), 0) from mov where tipo = 'Morte'),
        'saidas', (select coalesce(sum(qtd), 0) from mov where tipo = 'Saída'), 'entradas', (select coalesce(sum(qtd), 0) from mov where tipo = 'Entrada'),
        'cabecas_contadas', (select coalesce(sum(cabecas), 0) from lotes),
        'alertas', (select (cocho_problema + sal_problema + agua_problema + pasto_apertando) from estrut) + (select coalesce(sum(cocho_vazio + agua_problema), 0) from nut)))
    into v_dados;
    if (v_dados ->> 'boletins')::int > 0 then
      perform public.rel_gravar('rebanho_mes', p_ini, p_fim, u.id, v_dados);
    end if;
  end loop;
end $$;

-- 4.8 PLANO × EXECUTADO (mês): por fazenda de café com plano VIGENTE e unidade do
--     plano ligada a talhão do app (unidade_alias sistema app): adubação, calagem
--     e fito previstos × registrados nos boletins; Gantt do mês; atrasos.
--     Regras permanentes: "sem registro", nunca "não fez"; farol vermelho só
--     depois de a janela fechar; produto do plano só como "previsto pelo agrônomo".
-- Lê: plano_safra (vigente), unidade_manejo, unidade_alias (app), plano_adubo_mes,
--     plano_calagem, plano_fito_mes, plano_fito_excecao, plano_gantt, plano_parametros
--     e boletins.payload (atividades[] tipo/talhaoId/status, irr.fert/fertSetores,
--     fito[] nome/tipo/nivel/talhaoId, colheita[]).
create or replace function public.rel_plano_executado(p_ini date, p_fim date)
returns void language plpgsql security definer set search_path = public as $$
declare
  u record; v_dados jsonb; v_mes int := extract(month from p_ini);
  v_fim_mes date := (date_trunc('month', p_ini) + interval '1 month - 1 day')::date;
  v_fechado boolean := p_fim >= (date_trunc('month', p_ini) + interval '1 month - 1 day')::date;
  v_dia_lim int; v_pct_amarelo numeric; v_fito_dias int;
begin
  if to_regclass('public.plano_safra') is null then
    perform public.rel_gravar('plano_executado_mes', p_ini, p_fim, null,
      jsonb_build_object('aviso', 'tabelas do plano de safra ainda não existem — rodar sql/005, 006 e 007'));
    return;
  end if;
  select coalesce(public.rel_num((select valor from public.plano_parametros where chave = 'adubo_dia_limite_cadencia')), 20)::int into v_dia_lim;
  select coalesce(public.rel_num((select valor from public.plano_parametros where chave = 'gantt_pct_janela_amarelo')), 60) into v_pct_amarelo;
  select coalesce(public.rel_num((select valor from public.plano_parametros where chave = 'fito_dias_sem_monitoramento')), 10)::int into v_fito_dias;

  for u in select ru.*, ps.id as plano_id, ps.versao, ps.vigente_de, ps.aprovado_por, ps.safra
           from public.rel_unidades ru
           left join lateral (select * from public.plano_safra p where p.fazenda_app = ru.fazenda_app and p.status = 'vigente'
                              order by p.vigente_de desc nulls last, p.versao desc limit 1) ps on true
           where ru.ativo and ru.fazenda_app is not null order by ru.mae_nome, ru.nome loop
    if u.plano_id is null then
      perform public.rel_gravar('plano_executado_mes', p_ini, p_fim, u.id, jsonb_build_object('unidade', u.id, 'nome', u.nome, 'fazenda_app', u.fazenda_app,
        'periodo_ini', p_ini, 'periodo_fim', p_fim, 'mes', v_mes, 'plano', null, 'aviso', 'sem plano vigente para esta fazenda', 'unidades', '[]'::jsonb, 'gantt', '[]'::jsonb,
        'resumo', jsonb_build_object('unidades', 0, 'amarelos', 0, 'vermelhos', 0)));
      continue;
    end if;
    perform public.rel_prep_bol(u.id, p_ini, p_fim);
    drop table if exists _rel_reg;
    create temp table _rel_reg on commit drop as
    with bol as (select * from _rel_bol),
    reg as (  -- registros do boletim por talhão e família (adubo / calagem / fito / gantt slug)
      select b.data, nullif(a ->> 'talhaoId', '') talhao_id, a ->> 'tipo' tipo, a ->> 'status' status,
        case a ->> 'tipo'
          when 'Adubação via lanço' then 'adubo' when 'Adubação orgânica' then 'adubo'
          when 'Calagem / gessagem' then 'calagem'
          when 'Pulverização' then 'fito' when 'Aplicação via drench / via solo' then 'fito' when 'Monitoramento de pragas (MIP)' then 'fito'
          end familia,
        case a ->> 'tipo'
          when 'Calagem / gessagem' then 'calagem_gessagem' when 'Adubação orgânica' then 'adubacao_organica'
          when 'Limpeza do sistema de irrigação' then 'limpeza_sistema_irrigacao' when 'Adubação via lanço' then 'adubacao_lanco'
          when 'Monitoramento de pragas (MIP)' then 'mip' when 'Pulverização' then 'pulverizacao'
          when 'Aplicação via drench / via solo' then 'drench' when 'Desbrota' then 'desbrota' when 'Capina manual' then 'capina_manual'
          when 'Capina roçadeira / trincha' then 'capina_rocadeira_trincha' when 'Aplicação de herbicida' then 'herbicida'
          when 'Colheita' then 'colheita' when 'Poda / esqueletamento' then 'poda' end slug,
        null::text alvo, null::text nivel
      from bol b cross join lateral jsonb_array_elements(coalesce(b.payload -> 'atividades', '[]'::jsonb)) a
      union all  -- fertirrigação (gotejo): vale como adubação nos setores marcados (ou na fazenda toda, sem setor)
      select b.data, nullif(s.value #>> '{}', ''), 'Fertirrigação', null, 'adubo', 'adubacao_fertirrigacao', null, null
      from bol b cross join lateral jsonb_array_elements(coalesce(b.payload -> 'irr' -> 'fertSetores', '[]'::jsonb)) s
      where b.payload -> 'irr' ->> 'fert' = 'Sim'
      union all
      select b.data, null, 'Fertirrigação', null, 'adubo', 'adubacao_fertirrigacao', null, null
      from bol b where b.payload -> 'irr' ->> 'fert' = 'Sim' and jsonb_array_length(coalesce(b.payload -> 'irr' -> 'fertSetores', '[]'::jsonb)) = 0
      union all  -- seção Pragas, doenças e daninhas
      select b.data, nullif(f ->> 'talhaoId', ''), 'Fito: ' || coalesce(nullif(f ->> 'nome', ''), f ->> 'tipo', 'registro'), null, 'fito', 'mip', coalesce(nullif(f ->> 'nome', ''), f ->> 'tipo'), f ->> 'nivel'
      from bol b cross join lateral jsonb_array_elements(coalesce(b.payload -> 'fito', '[]'::jsonb)) f
      union all  -- módulo Colheita
      select b.data, nullif(c ->> 'talhaoId', ''), 'Colheita (registro)', null, null, 'colheita', null, null
      from bol b cross join lateral jsonb_array_elements(coalesce(b.payload -> 'colheita', '[]'::jsonb)) c)
    select * from reg;
    analyze _rel_reg;
    with bol as (select * from _rel_bol), reg as (select * from _rel_reg),
    un as (
      select um.id, um.codigo, um.nome_plano, um.nome_curto, um.area_ha, um.status, um.irrigacao, um.empresa,
        (select al.alias from public.unidade_alias al where al.unidade_id = um.id and al.sistema = 'app' and al.vigente_ate is null order by al.vigente_de desc limit 1) talhao_id
      from public.unidade_manejo um
      join public.plano_unidade pu on pu.plano_id = u.plano_id and pu.unidade_id = um.id
      where um.ativo),
    adubo as (
      select a.unidade_id, jsonb_agg(jsonb_build_object('insumo', a.insumo, 'kg', a.kg, 'via', a.via) order by a.insumo) previstos, sum(a.kg) kg
      from public.plano_adubo_mes a where a.plano_id = u.plano_id and a.mes = v_mes group by 1),
    calagem as (
      select c.unidade_id, jsonb_agg(jsonb_build_object('subarea', c.subarea, 't_ha', c.t_ha, 't_total', c.t_total, 'rateado', c.rateado,
        'janela_ini', c.janela_ini, 'janela_fim', c.janela_fim) order by c.subarea) previstos, sum(c.t_total) t_total, min(c.janela_ini) janela_ini, max(c.janela_fim) janela_fim
      from public.plano_calagem c where c.plano_id = u.plano_id and c.janela_ini <= p_fim and c.janela_fim >= p_ini group by 1),
    fito_mes as (
      select coalesce((select jsonb_agg(jsonb_build_object('fase', f.fase, 'alvos', to_jsonb(f.alvos), 'produtos_previstos', to_jsonb(f.produtos), 'via_solo', to_jsonb(f.via_solo)))
                       from public.plano_fito_mes f where f.mes = v_mes and (f.plano_id is null or f.plano_id = u.plano_id)), '[]'::jsonb) j,
        coalesce((select array_agg(distinct x) from public.plano_fito_mes f cross join lateral unnest(f.alvos) x
                  where f.mes = v_mes and (f.plano_id is null or f.plano_id = u.plano_id)), '{}') alvos),
    fito_exc as (select coalesce(jsonb_agg(e.produto), '[]'::jsonb) j from public.plano_fito_excecao e where e.mes = v_mes and e.fazenda_app = u.fazenda_app),
    fito_reg as (select data, talhao_id, tipo, alvo, nivel from reg where familia = 'fito'),
    un_j as (
      select coalesce(jsonb_agg(jsonb_build_object(
        'codigo', un.codigo, 'nome_plano', un.nome_plano, 'nome_curto', un.nome_curto, 'talhao_id', un.talhao_id, 'area_ha', un.area_ha, 'status', un.status, 'irrigacao', un.irrigacao,
        'adubo', case when ad.unidade_id is null then null else jsonb_build_object(
          'previstos', ad.previstos, 'kg_previsto', ad.kg, 'rotulo', 'previsto pelo agrônomo (plano v' || u.versao || ')',
          'registros', (select coalesce(jsonb_agg(jsonb_build_object('data', r.data, 'tipo', r.tipo) order by r.data), '[]'::jsonb) from reg r where r.familia = 'adubo' and (r.talhao_id = un.talhao_id or r.talhao_id is null)),
          'primeiro', (select min(r.data) from reg r where r.familia = 'adubo' and (r.talhao_id = un.talhao_id or r.talhao_id is null)),
          'kg_realizado', null,
          'situacao', case
            when un.talhao_id is null then 'sem ligação com talhão do app'
            when exists (select 1 from reg r where r.familia = 'adubo' and (r.talhao_id = un.talhao_id or r.talhao_id is null)) then 'registrado'
            when v_fechado then 'mês fechado sem registro'
            when extract(day from p_fim) > v_dia_lim then 'sem registro após o dia ' || v_dia_lim
            else 'em andamento' end,
          'farol', case
            when un.talhao_id is null then 'cinza'
            when exists (select 1 from reg r where r.familia = 'adubo' and (r.talhao_id = un.talhao_id or r.talhao_id is null)) then 'verde'
            when v_fechado then 'vermelho'
            when extract(day from p_fim) > v_dia_lim then 'amarelo'
            else 'branco' end) end,
        'calagem', case when ca.unidade_id is null then null else jsonb_build_object(
          'previstos', ca.previstos, 't_total', ca.t_total, 'janela_ini', ca.janela_ini, 'janela_fim', ca.janela_fim, 'rotulo', 'previsto pelo agrônomo (plano v' || u.versao || ')',
          'registros', (select coalesce(jsonb_agg(jsonb_build_object('data', r.data, 'tipo', r.tipo, 'status', r.status) order by r.data), '[]'::jsonb)
             from (select distinct b2.data::date data, r2.tipo, r2.status from public.rel_boletins(u.id, ca.janela_ini, least(p_fim, ca.janela_fim)) b2
                   cross join lateral jsonb_array_elements(coalesce(b2.payload -> 'atividades', '[]'::jsonb)) a2
                   cross join lateral (select a2 ->> 'tipo' tipo, a2 ->> 'status' status, nullif(a2 ->> 'talhaoId', '') talhao_id) r2
                   where r2.tipo = 'Calagem / gessagem' and (r2.talhao_id = un.talhao_id or r2.talhao_id is null)) r),
          'situacao', case
            when un.talhao_id is null then 'sem ligação com talhão do app'
            when exists (select 1 from public.rel_boletins(u.id, ca.janela_ini, least(p_fim, ca.janela_fim)) b2
                   cross join lateral jsonb_array_elements(coalesce(b2.payload -> 'atividades', '[]'::jsonb)) a2
                   where a2 ->> 'tipo' = 'Calagem / gessagem' and (nullif(a2 ->> 'talhaoId', '') = un.talhao_id or nullif(a2 ->> 'talhaoId', '') is null)) then 'registrado'
            when p_fim > ca.janela_fim then 'janela fechada sem registro'
            when (p_fim - ca.janela_ini)::numeric / greatest(1, ca.janela_fim - ca.janela_ini) * 100 >= v_pct_amarelo then 'sem registro (' || round((p_fim - ca.janela_ini)::numeric / greatest(1, ca.janela_fim - ca.janela_ini) * 100) || '% da janela)'
            else 'em andamento' end,
          'farol', case
            when un.talhao_id is null then 'cinza'
            when exists (select 1 from public.rel_boletins(u.id, ca.janela_ini, least(p_fim, ca.janela_fim)) b2
                   cross join lateral jsonb_array_elements(coalesce(b2.payload -> 'atividades', '[]'::jsonb)) a2
                   where a2 ->> 'tipo' = 'Calagem / gessagem' and (nullif(a2 ->> 'talhaoId', '') = un.talhao_id or nullif(a2 ->> 'talhaoId', '') is null)) then 'verde'
            when p_fim > ca.janela_fim then 'vermelho'
            when (p_fim - ca.janela_ini)::numeric / greatest(1, ca.janela_fim - ca.janela_ini) * 100 >= v_pct_amarelo then 'amarelo'
            else 'branco' end) end,
        'fito', jsonb_build_object(
          'registros', (select coalesce(jsonb_agg(jsonb_build_object('data', r.data, 'tipo', r.tipo, 'alvo', r.alvo, 'nivel', r.nivel) order by r.data), '[]'::jsonb) from fito_reg r where r.talhao_id = un.talhao_id or r.talhao_id is null),
          'ultimo', (select max(r.data) from fito_reg r where r.talhao_id = un.talhao_id or r.talhao_id is null),
          'situacao', case
            when un.talhao_id is null then 'sem ligação com talhão do app'
            when (select max(r.data) from fito_reg r where r.talhao_id = un.talhao_id or r.talhao_id is null) is null then case when v_fechado then 'mês fechado sem registro' else 'sem registro no mês' end
            when p_fim - (select max(r.data) from fito_reg r where r.talhao_id = un.talhao_id or r.talhao_id is null) > v_fito_dias then 'último registro há mais de ' || v_fito_dias || ' dias'
            else 'registrado' end,
          'farol', case
            when un.talhao_id is null then 'cinza'
            when (select max(r.data) from fito_reg r where r.talhao_id = un.talhao_id or r.talhao_id is null) is null then case when v_fechado then 'vermelho' when extract(day from p_fim) > v_fito_dias then 'amarelo' else 'branco' end
            when p_fim - (select max(r.data) from fito_reg r where r.talhao_id = un.talhao_id or r.talhao_id is null) > v_fito_dias then 'amarelo'
            else 'verde' end)
      ) order by un.codigo), '[]'::jsonb) j
      from un left join adubo ad on ad.unidade_id = un.id left join calagem ca on ca.unidade_id = un.id),
    gantt as (
      select g.atividade, g.meses, g.tipo, g.evidencia_app,
        (select count(*) from reg r where r.slug = g.atividade) registros,
        (select min(r.data) from reg r where r.slug = g.atividade) primeiro
      from public.plano_gantt g
      where g.modelo = coalesce((select case max(empresa) when 'NR Agropecuária' then 'NR' else 'NC' end from un), 'NC') and v_mes = any(g.meses)),
    gantt_j as (
      select coalesce(jsonb_agg(jsonb_build_object('atividade', atividade, 'meses', to_jsonb(meses), 'tipo', tipo, 'evidencia_app', evidencia_app,
        'registros', registros, 'primeiro', primeiro,
        'situacao', case when evidencia_app like 'sem chip%' then 'sem chip no app' when registros > 0 then 'registrado'
          when v_fechado and not (v_mes + 1 = any(meses) or (v_mes = 12 and 1 = any(meses))) then 'janela fechada sem registro'
          when extract(day from p_fim) > v_dia_lim then 'sem registro' else 'em andamento' end,
        'farol', case when evidencia_app like 'sem chip%' then 'cinza' when registros > 0 then 'verde'
          when v_fechado and not (v_mes + 1 = any(meses) or (v_mes = 12 and 1 = any(meses))) then 'vermelho'
          when extract(day from p_fim) > v_dia_lim then 'amarelo' else 'branco' end) order by atividade), '[]'::jsonb) j
      from gantt)
    select jsonb_build_object(
      'unidade', u.id, 'nome', u.nome, 'fazenda_app', u.fazenda_app, 'periodo_ini', p_ini, 'periodo_fim', p_fim, 'mes', v_mes, 'mes_fechado', v_fechado,
      'plano', jsonb_build_object('id', u.plano_id, 'versao', u.versao, 'safra', u.safra, 'vigente_de', u.vigente_de, 'aprovado_por', u.aprovado_por),
      'parametros', jsonb_build_object('adubo_dia_limite_cadencia', v_dia_lim, 'gantt_pct_janela_amarelo', v_pct_amarelo, 'fito_dias_sem_monitoramento', v_fito_dias),
      'boletins', (select count(*) from bol),
      'fito_mes', (select j from fito_mes), 'fito_alvos', (select to_jsonb(alvos) from fito_mes), 'fito_excecoes', (select j from fito_exc),
      'unidades', (select j from un_j),
      'sem_alias', (select coalesce(jsonb_agg(codigo order by codigo), '[]'::jsonb) from un where talhao_id is null),
      'gantt', (select j from gantt_j),
      'resumo', (select jsonb_build_object('unidades', count(*),
          'amarelos', count(*) filter (where e -> 'adubo' ->> 'farol' = 'amarelo' or e -> 'calagem' ->> 'farol' = 'amarelo' or e -> 'fito' ->> 'farol' = 'amarelo'),
          'vermelhos', count(*) filter (where e -> 'adubo' ->> 'farol' = 'vermelho' or e -> 'calagem' ->> 'farol' = 'vermelho' or e -> 'fito' ->> 'farol' = 'vermelho'),
          'sem_alias', count(*) filter (where e ->> 'talhao_id' is null),
          'gantt_amarelo', (select count(*) from jsonb_array_elements((select j from gantt_j)) g where g ->> 'farol' in ('amarelo', 'vermelho')))
        from jsonb_array_elements((select j from un_j)) e))
    into v_dados;
    perform public.rel_gravar('plano_executado_mes', p_ini, p_fim, u.id, v_dados);
  end loop;
end $$;

-- ====================================================================
-- 5. Rodadas agendadas (cada relatório protegido por exception)
-- ====================================================================
create or replace function public.rel_executar(p_rel text, p_ini date, p_fim date, p_sql text)
returns void language plpgsql security definer set search_path = public as $$
begin
  execute p_sql;
  insert into public.relatorios_execucoes (relatorio, periodo_ini, periodo_fim, ok) values (p_rel, p_ini, p_fim, true);
exception when others then
  insert into public.relatorios_execucoes (relatorio, periodo_ini, periodo_fim, ok, erro) values (p_rel, p_ini, p_fim, false, left(sqlerrm, 500));
end $$;

-- todo dia 05:00 BRT: farol 7 e 30, dito × medido de ontem (iCrop e Solinftec), balanço hídrico de ontem
create or replace function public.rel_rodar_diario()
returns void language plpgsql security definer set search_path = public as $$
declare v_ontem date := public.rel_hoje_brt() - 1;
begin
  perform public.rel_executar('farol_7',  v_ontem - 6,  v_ontem, 'select public.rel_farol(7)');
  perform public.rel_executar('farol_30', v_ontem - 29, v_ontem, 'select public.rel_farol(30)');
  perform public.rel_executar('dito_medido_icrop_dia',     v_ontem, v_ontem, format('select public.rel_dito_medido_icrop(%L, %L)', v_ontem, v_ontem));
  perform public.rel_executar('dito_medido_solinftec_dia', v_ontem, v_ontem, format('select public.rel_dito_medido_solinftec(%L, %L)', v_ontem, v_ontem));
  perform public.rel_executar('balanco_hidrico_dia',       v_ontem, v_ontem, format('select public.rel_balanco_hidrico(%L)', v_ontem));
  delete from public.relatorios_execucoes where quando < now() - interval '120 days';
end $$;

-- sexta 05:00 BRT: semana fechada = últimos 7 dias até ontem (sexta anterior → quinta)
create or replace function public.rel_rodar_semanal()
returns void language plpgsql security definer set search_path = public as $$
declare v_fim date := public.rel_hoje_brt() - 1; v_ini date := public.rel_hoje_brt() - 7;
begin
  perform public.rel_executar('irrigacao_rec_exec_semana',   v_ini, v_fim, format('select public.rel_irrigacao_recomendado_executado(%L, %L)', v_ini, v_fim));
  perform public.rel_executar('dito_medido_icrop_semana',    v_ini, v_fim, format('select public.rel_dito_medido_icrop(%L, %L)', v_ini, v_fim));
  perform public.rel_executar('dito_medido_solinftec_semana', v_ini, v_fim, format('select public.rel_dito_medido_solinftec(%L, %L)', v_ini, v_fim));
end $$;

-- dia 1 05:00 BRT: mês fechado (o anterior): custo físico, rebanho e plano × executado fechado
create or replace function public.rel_rodar_mensal()
returns void language plpgsql security definer set search_path = public as $$
declare v_ini date := (date_trunc('month', public.rel_hoje_brt()) - interval '1 month')::date;
        v_fim date := (date_trunc('month', public.rel_hoje_brt()) - interval '1 day')::date;
begin
  perform public.rel_executar('custo_fisico_talhao_mes', v_ini, v_fim, format('select public.rel_custo_fisico_talhao(%L, %L)', v_ini, v_fim));
  perform public.rel_executar('rebanho_mes',             v_ini, v_fim, format('select public.rel_rebanho(%L, %L)', v_ini, v_fim));
  perform public.rel_executar('plano_executado_mes',     v_ini, v_fim, format('select public.rel_plano_executado(%L, %L)', v_ini, v_fim));
end $$;

-- segunda 05:00 BRT: plano × executado do mês corrente (parcial, dia 1 até ontem)
create or replace function public.rel_rodar_plano()
returns void language plpgsql security definer set search_path = public as $$
declare v_fim date := public.rel_hoje_brt() - 1; v_ini date := date_trunc('month', public.rel_hoje_brt() - 1)::date;
begin
  perform public.rel_executar('plano_executado_mes', v_ini, v_fim, format('select public.rel_plano_executado(%L, %L)', v_ini, v_fim));
end $$;

-- Trancar: só o SQL Editor / pg_cron chamam as funções; a chave publishable do app não.
revoke all on function public.rel_gravar(text, date, date, text, jsonb, text) from public, anon, authenticated;
revoke all on function public.rel_icrop_periodo(date, date) from public, anon, authenticated;
revoke all on function public.rel_boletins(text, date, date) from public, anon, authenticated;
revoke all on function public.rel_prep_bol(text, date, date) from public, anon, authenticated;
revoke all on function public.rel_farol(int, date) from public, anon, authenticated;
revoke all on function public.rel_dito_medido_icrop(date, date) from public, anon, authenticated;
revoke all on function public.rel_dito_medido_solinftec(date, date) from public, anon, authenticated;
revoke all on function public.rel_irrigacao_recomendado_executado(date, date) from public, anon, authenticated;
revoke all on function public.rel_balanco_hidrico(date) from public, anon, authenticated;
revoke all on function public.rel_custo_fisico_talhao(date, date) from public, anon, authenticated;
revoke all on function public.rel_rebanho(date, date) from public, anon, authenticated;
revoke all on function public.rel_plano_executado(date, date) from public, anon, authenticated;
revoke all on function public.rel_executar(text, date, date, text) from public, anon, authenticated;
revoke all on function public.rel_rodar_diario() from public, anon, authenticated;
revoke all on function public.rel_rodar_semanal() from public, anon, authenticated;
revoke all on function public.rel_rodar_mensal() from public, anon, authenticated;
revoke all on function public.rel_rodar_plano() from public, anon, authenticated;

-- ====================================================================
-- 6. Agendamento pg_cron (UTC; Brasília = UTC-3 → 05:00 BRT = 08:00 UTC)
--    Não colide com os robôs: iCrop 03:50/04:05/04:20 e 09:45/10:00/10:15 BRT;
--    Solinftec 03:05 BRT e de hora em hora aos :35 (09:35–20:35 BRT).
-- ====================================================================
do $$
declare j record;
begin
  for j in select jobid from cron.job where jobname in ('relatorios-diario', 'relatorios-semanal', 'relatorios-mensal', 'relatorios-plano') loop
    perform cron.unschedule(j.jobid);
  end loop;
end $$;
select cron.schedule('relatorios-diario',  '0 8 * * *',  $$select public.rel_rodar_diario()$$);   -- todo dia 05:00 BRT
select cron.schedule('relatorios-semanal', '10 8 * * 5', $$select public.rel_rodar_semanal()$$);  -- sexta 05:10 BRT
select cron.schedule('relatorios-mensal',  '20 8 1 * *', $$select public.rel_rodar_mensal()$$);   -- dia 1 05:20 BRT
select cron.schedule('relatorios-plano',   '30 8 * * 1', $$select public.rel_rodar_plano()$$);    -- segunda 05:30 BRT

-- Primeira carga (opcional, roda na hora): descomente para não esperar a madrugada.
-- select public.rel_rodar_diario(); select public.rel_rodar_semanal();
-- select public.rel_rodar_mensal(); select public.rel_rodar_plano();
