-- Plano de safra — camada de referência e comparação (v52)
-- Rodar no SQL Editor do Supabase (projeto syvehtgrbqteyuqhoban),
-- ANTES do sql/006-plano-safra-seed-2627.sql (que carrega os dados).
-- Pode ser rodado de novo sem estragar nada (create if not exists /
-- drop policy if exists).
--
-- O que este arquivo cria:
--   1. unidade_manejo      — cadastro mestre das unidades do plano (setor,
--                            pivô, talhão do agrônomo). A CHAVE É O id; os
--                            nomes são só apelidos (unidade_alias).
--   2. unidade_alias       — apelidos por sistema (plano, app, solinftec,
--                            icrop, agrogestao), com vigência.
--   3. unidade_manejo_log  — trilha de alterações feitas na tela de
--                            Escritório (campo, antes, depois, quem, quando).
--   4. plano_safra         — versões do plano por fazenda e safra
--                            (rascunho → vigente → superado). Uma vigente
--                            por fazenda-safra.
--   5. plano_unidade, plano_adubo_mes, plano_calagem — conteúdo de cada
--                            versão. Nunca se edita a vigente: muda-se por
--                            nova versão.
--   6. plano_fito_mes, plano_fito_excecao — calendário fitossanitário do
--                            grupo (plano_id nulo = vale para todas).
--   7. plano_gantt         — janelas por atividade (modelos NC e NR) e qual
--                            registro do app / sistema externo comprova.
--   8. plano_parametros    — limites dos faróis, editáveis pelo ADMIN.
--
-- Segurança: mesmo modelo de confiança das demais tabelas do app — a
-- chave publishable lê e grava; o controle fino é do próprio app (só a
-- tela de ADMIN escreve). Não há policy de DELETE em nenhuma tabela:
-- unidade se inativa, plano se supera, nada se apaga.
-- Nenhum texto do plano é receituário: o app mostra como "previsto pelo
-- agrônomo — registre o que foi feito".

-- 1. unidade_manejo ---------------------------------------------------
create table if not exists public.unidade_manejo (
  id             uuid primary key default gen_random_uuid(),
  codigo         text not null unique,          -- ex.: VEC-S08 — imutável (gatilho abaixo)
  fazenda_app    text not null,                 -- nome EXATO da unidade no cadastro do app
  empresa        text not null check (empresa in ('NC Naves','NR Agropecuária')),
  nome_plano     text not null,                 -- nome como está no deck do agrônomo
  nome_curto     text,                          -- rótulo do chip (fase B)
  pai_id         uuid references public.unidade_manejo(id),
  area_ha        numeric,
  fonte_area     text check (fonte_area is null or fonte_area in
                   ('estimativa','calcario','calcario_rateado','icrop','solinftec','agrogestao')),
  irrigacao      text check (irrigacao is null or irrigacao in ('gotejo','pivo')),
  status         text not null default 'producao' check (status in
                   ('producao','poda','renovacao','recepa','plantio','a_confirmar')),
  status_desde   date,
  area_zerada_ha numeric,
  obs            text,
  ativo          boolean not null default true,
  inativado_em   timestamptz,
  criado_em      timestamptz not null default now(),
  atualizado_em  timestamptz not null default now()
);
comment on table public.unidade_manejo is
  'Cadastro mestre das unidades de manejo do plano de safra (Boletim NCNaves v52). A identidade é o id/codigo; nomes são aliases em unidade_alias. Nunca apagar: inativar (ativo=false).';
create index if not exists unidade_manejo_fazenda on public.unidade_manejo (fazenda_app) where ativo;

-- codigo imutável + atualizado_em sempre em dia
create or replace function public.unidade_manejo_toque()
returns trigger language plpgsql as $$
begin
  if new.codigo <> old.codigo then
    raise exception 'codigo da unidade_manejo é imutável (% → %)', old.codigo, new.codigo;
  end if;
  if new.ativo = false and old.ativo = true and new.inativado_em is null then
    new.inativado_em := now();
  end if;
  new.atualizado_em := now();
  return new;
end $$;
drop trigger if exists unidade_manejo_toque on public.unidade_manejo;
create trigger unidade_manejo_toque
  before update on public.unidade_manejo
  for each row execute function public.unidade_manejo_toque();

-- 2. unidade_alias ----------------------------------------------------
-- Um apelido só pode apontar para UMA unidade dentro da mesma fazenda e do
-- mesmo sistema enquanto estiver vigente (vigente_ate nulo). A fazenda
-- entra na chave porque os nomes do plano se repetem entre fazendas
-- ("Setor 01" existe em Vereda, Rio Preto, Lagamar e Mata Preta).
-- Para sistema = 'app' o alias é o ID do talhão no cadastro do app (t086…).
create table if not exists public.unidade_alias (
  id          uuid primary key default gen_random_uuid(),
  unidade_id  uuid not null references public.unidade_manejo(id),
  fazenda_app text not null default '',      -- preenchido pelo gatilho a partir da unidade
  sistema     text not null check (sistema in ('plano','app','solinftec','icrop','agrogestao')),
  alias       text not null,
  vigente_de  date not null default current_date,
  vigente_ate date,
  criado_em   timestamptz not null default now()
);
comment on table public.unidade_alias is
  'Apelidos das unidades de manejo por sistema. sistema=plano: nomes dos decks; app: id do talhão no index.html; solinftec/icrop/agrogestao: nomes nesses sistemas. Encerrar um alias = preencher vigente_ate.';
create unique index if not exists unidade_alias_vigente_unq
  on public.unidade_alias (sistema, fazenda_app, alias) where vigente_ate is null;
create index if not exists unidade_alias_unidade on public.unidade_alias (unidade_id);

create or replace function public.unidade_alias_preencher()
returns trigger language plpgsql as $$
begin
  if new.fazenda_app is null or new.fazenda_app = '' then
    select u.fazenda_app into new.fazenda_app from public.unidade_manejo u where u.id = new.unidade_id;
  end if;
  new.alias := btrim(new.alias);
  return new;
end $$;
drop trigger if exists unidade_alias_preencher on public.unidade_alias;
create trigger unidade_alias_preencher
  before insert or update on public.unidade_alias
  for each row execute function public.unidade_alias_preencher();

-- 3. unidade_manejo_log -----------------------------------------------
create table if not exists public.unidade_manejo_log (
  id          bigint generated always as identity primary key,
  unidade_id  uuid not null references public.unidade_manejo(id),
  campo       text not null,
  antes       text,
  depois      text,
  quem        text,
  quando      timestamptz not null default now()
);
comment on table public.unidade_manejo_log is
  'Trilha das alterações feitas nas unidades pela tela Escritório › Unidades e Plano (uma linha por campo alterado).';

-- 4. plano_safra ------------------------------------------------------
create table if not exists public.plano_safra (
  id             uuid primary key default gen_random_uuid(),
  fazenda_app    text not null,
  safra          text not null default '2026/27',
  versao         integer not null,
  status         text not null default 'rascunho' check (status in ('rascunho','vigente','superado')),
  vigente_de     date,
  motivo         text,
  arquivo_origem text,
  criado_por     text,
  aprovado_por   text,
  aprovado_em    timestamptz,
  auditoria_ok   boolean not null default false,
  auditoria_json jsonb,                    -- resultado da última auditoria (tela de Escritório)
  resumo_deck    jsonb,                    -- kg/ano por insumo no slide-resumo do deck (só para a auditoria comparar)
  criado_em      timestamptz not null default now(),
  unique (fazenda_app, safra, versao)
);
comment on table public.plano_safra is
  'Versões do plano de safra por fazenda. Só uma linha vigente por (fazenda_app, safra). Mudança de plano = nova versão; a anterior vira superado.';
create unique index if not exists plano_safra_um_vigente
  on public.plano_safra (fazenda_app, safra) where status = 'vigente';

-- 5. conteúdo de cada versão -----------------------------------------
create table if not exists public.plano_unidade (
  plano_id         uuid not null references public.plano_safra(id),
  unidade_id       uuid not null references public.unidade_manejo(id),
  area_ha_plano    numeric,
  safra_zerada_tipo text,                  -- como veio do deck: poda, plantio, a_confirmar, em_branco ou nulo
  area_zerada_ha   numeric,
  estimativa_sc_ha numeric,                -- nulo nesta fase (estimativa fica fora do app)
  primary key (plano_id, unidade_id)
);
comment on table public.plano_unidade is 'Unidades cobertas por cada versão do plano, com área e situação de safra zerada como estão no deck.';

create table if not exists public.plano_adubo_mes (
  id         bigint generated always as identity primary key,
  plano_id   uuid not null references public.plano_safra(id),
  unidade_id uuid not null references public.unidade_manejo(id),
  mes        integer not null check (mes between 1 and 12),
  insumo     text not null check (insumo in
               ('ureia','nitrato','sulfato_amonio','kcl','phusion','sulfato_mn','acido_borico','sulfato_zn')),
  kg         numeric not null,
  via        text check (via is null or via in ('fertirrigacao','lanco')),  -- nulo na v1: não deduzido
  obs        text,
  unique (plano_id, unidade_id, mes, insumo)
);
comment on table public.plano_adubo_mes is
  'Calendário de adubação previsto pelo agrônomo (kg por unidade, mês e insumo). Referência para comparação — NUNCA receituário: o app não mostra kg ao gerente por padrão.';
create index if not exists plano_adubo_mes_plano_mes on public.plano_adubo_mes (plano_id, mes);

create table if not exists public.plano_calagem (
  id         bigint generated always as identity primary key,
  plano_id   uuid not null references public.plano_safra(id),
  unidade_id uuid not null references public.unidade_manejo(id),
  subarea    text not null,                -- ex.: "Vereda 08 alto"
  t_ha       numeric,
  t_total    numeric,
  rateado    boolean not null default false,   -- bloco único do deck rateado entre unidades
  janela_ini date not null default '2026-09-01',
  janela_fim date not null default '2026-10-31',
  unique (plano_id, unidade_id, subarea)
);
comment on table public.plano_calagem is 'Calagem prevista por unidade/subárea (t/ha e t total) e janela de execução.';

-- 6. fito (grupo) ------------------------------------------------------
create table if not exists public.plano_fito_mes (
  id       bigint generated always as identity primary key,
  plano_id uuid references public.plano_safra(id),   -- nulo = registro do grupo (vale para todas as fazendas)
  mes      integer not null check (mes between 1 and 12),
  fase     text,
  alvos    text[] not null default '{}',
  produtos text[] not null default '{}',
  via_solo text[] not null default '{}'
);
comment on table public.plano_fito_mes is
  'Calendário fitossanitário mês a mês (fase, alvos, produtos citados pelo agrônomo, via solo). Produtos só aparecem no app como "usei:" para registrar o que foi feito — nunca como recomendação.';
create unique index if not exists plano_fito_mes_grupo_unq on public.plano_fito_mes (mes) where plano_id is null;
create unique index if not exists plano_fito_mes_plano_unq on public.plano_fito_mes (plano_id, mes) where plano_id is not null;

create table if not exists public.plano_fito_excecao (
  id          bigint generated always as identity primary key,
  mes         integer not null check (mes between 1 and 12),
  produto     text not null,
  fazenda_app text not null,
  unique (mes, produto, fazenda_app)
);
comment on table public.plano_fito_excecao is 'Produto via solo previsto só em algumas fazendas num mês (ex.: Vaniva em outubro).';

-- 7. gantt -------------------------------------------------------------
create table if not exists public.plano_gantt (
  modelo            text not null check (modelo in ('NC','NR')),
  atividade         text not null,          -- slug: calagem_gessagem, poda, mip…
  meses             integer[] not null,
  tipo              text not null default 'janela' check (tipo in ('janela','evento_unico')),
  evidencia_app     text,                   -- qual registro do app comprova a atividade
  evidencia_externa text,                   -- Solinftec / iCrop / ERP
  primary key (modelo, atividade)
);
comment on table public.plano_gantt is 'Janelas do ano agrícola por atividade, nos modelos NC Naves (NC) e NR Agropecuária (NR), e a evidência que comprova cada uma.';

-- 8. parâmetros --------------------------------------------------------
create table if not exists public.plano_parametros (
  chave         text primary key,
  valor         text not null,              -- número, data ou lista ("10,11,12") em texto; o app interpreta
  descricao     text,
  atualizado_em timestamptz not null default now()
);
comment on table public.plano_parametros is 'Limites e datas usados pelos faróis do plano (fase B). Editáveis pelo perfil ADMIN.';
-- Valores iniciais (o seed 006 repete os mesmos; "do nothing" preserva o que o ADMIN já tiver mudado)
insert into public.plano_parametros (chave, valor, descricao) values
  ('fito_dias_sem_monitoramento', '10', 'Dias sem monitoramento de um alvo previsto no mês para o farol Fito ficar amarelo'),
  ('gantt_pct_janela_amarelo', '60', '% da janela decorrida sem registro para o farol Gantt ficar amarelo'),
  ('adubo_dia_limite_cadencia', '20', 'Dia do mês até o qual se espera o 1º registro de fertirrigação/adubação (e a 1ª pulverização nos meses de fungicida + inseticida)'),
  ('poda_data_limite', '2026-09-30', 'Data-limite para o chip de poda ✔ nas unidades com status poda'),
  ('desbrota_data_limite', '2026-12-31', 'Data-limite para o chip de desbrota ✔ nas unidades com status poda'),
  ('chumbinho_meses', '10,11,12', 'Meses em que o chip "chumbinho visível" aparece no bloco Clima (fase B)')
on conflict (chave) do nothing;

-- RLS (mesmo padrão das demais tabelas do app) -------------------------
alter table public.unidade_manejo     enable row level security;
alter table public.unidade_alias      enable row level security;
alter table public.unidade_manejo_log enable row level security;
alter table public.plano_safra        enable row level security;
alter table public.plano_unidade      enable row level security;
alter table public.plano_adubo_mes    enable row level security;
alter table public.plano_calagem      enable row level security;
alter table public.plano_fito_mes     enable row level security;
alter table public.plano_fito_excecao enable row level security;
alter table public.plano_gantt        enable row level security;
alter table public.plano_parametros   enable row level security;

do $$
declare t text;
begin
  foreach t in array array['unidade_manejo','unidade_alias','unidade_manejo_log','plano_safra',
                           'plano_unidade','plano_adubo_mes','plano_calagem','plano_fito_mes',
                           'plano_fito_excecao','plano_gantt','plano_parametros'] loop
    execute format('drop policy if exists %I on public.%I', t||' leitura', t);
    execute format('create policy %I on public.%I for select using (true)', t||' leitura', t);
    execute format('drop policy if exists %I on public.%I', t||' insercao', t);
    execute format('create policy %I on public.%I for insert with check (true)', t||' insercao', t);
    execute format('drop policy if exists %I on public.%I', t||' atualizacao', t);
    execute format('create policy %I on public.%I for update using (true) with check (true)', t||' atualizacao', t);
    -- sem policy de delete: nada se apaga
  end loop;
end $$;
