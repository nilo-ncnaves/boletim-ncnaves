-- Módulo de planejamento: reunião mensal + planejamento semanal (v77)
-- Objetos: planejamento_rodada, planejamento_semana, planejamento_tarefa
-- e a visão vw_planejamento_mes (leitura). Rodar no SQL Editor do Supabase
-- (projeto syvehtgrbqteyuqhoban).
--
-- PASSO A PASSO (pelo iPhone):
--   1. Abra o Supabase e entre no projeto do Boletim.
--   2. Toque em "SQL Editor" e em "New query".
--   3. Selecione TODO o texto deste arquivo, copie e cole na caixa.
--   4. Toque em "Run".
--   5. No fim aparece uma tabelinha de conferência (quantas rodadas,
--      semanas e tarefas existem). Pode rodar de novo quantas vezes
--      quiser: nada duplica e nada se apaga.
--
-- ANTES: sql/020 (motor de relatórios) precisa ter rodado — a visão usa
-- rel_unidades e rel_fz_atual. Se faltar, o bloco para com aviso claro.
--
-- O QUE É: toda reunião administrativa (por volta do dia 10) gera uma ATA
-- por fazenda; toda sexta há planejamento semanal, sem reunião. As duas
-- coisas apontam para a MESMA tarefa, vista em dois horizontes: concluir
-- no semanal atualiza o mensal e vice-versa.
--   • planejamento_rodada  = uma reunião ("Reunião 10/09/26").
--   • planejamento_semana  = uma semana (segunda a domingo).
--   • planejamento_tarefa  = a tarefa, com o histórico dentro do payload.
--
-- COMO O DADO CHEGA: o app grava tudo no aparelho (offline first) e a fila
-- de sincronização sobe cada registro por id, do mesmo jeito que já faz com
-- boletins, pós-colheita e remessas. O app também LÊ estas tabelas a cada
-- sincronização, então uma tarefa criada no escritório aparece no celular
-- do gerente e a resposta do gerente aparece no escritório.
--
-- HISTÓRICO: cada mudança de status ou de prazo vira uma linha em
-- payload.historico (quem, quando, de → para, motivo). Nada é apagado:
-- cancelar é um STATUS com motivo, nunca um delete.
--
-- VOCABULÁRIO (regra permanente do projeto): as telas dizem "sem registro"
-- e nomeiam o prazo; nunca "não fez", "não realizou", "faltou", "esqueceu".
-- Tarefa parada por terceiro ou por chuva tem STATUS PRÓPRIO (aguardando
-- terceiro / aguardando clima) e nunca aparece em vermelho para o campo —
-- vira cobrança do escritório.
--
-- SEGURANÇA: leitura e escrita anon por policy, como as demais tabelas que
-- o app alimenta (a autorização real é o escopo do código de acesso; ver
-- CLAUDE.md, "Segurança"). Visão com security_invoker. Nenhum segredo aqui.
--
-- IDENTIDADE: unidade_id é sempre o id da unidade do app (f22c, f03c…),
-- normalizado por rel_fz_atual — nunca pedaço de nome de fazenda.

-- 0. Pré-requisito: o motor (sql/020) precisa existir
do $$
begin
  if to_regclass('public.rel_unidades') is null
     or to_regproc('public.rel_fz_atual') is null then
    raise exception 'Rode antes o sql/020-relatorios-motor.sql (faltam rel_unidades / rel_fz_atual).';
  end if;
end $$;

-- 1. Rodadas da reunião administrativa (uma por mês, normalmente)
create table if not exists public.planejamento_rodada (
  id            text primary key,          -- id gerado pelo app
  ref           text not null,             -- mês de referência AAAA-MM
  payload       jsonb not null,            -- {nome, data, importadoEm, por, …}
  atualizado_em timestamptz not null default now()
);
create index if not exists planejamento_rodada_ref on public.planejamento_rodada (ref desc);
comment on table public.planejamento_rodada is
  'Uma reunião administrativa (ata do mês). O app cria ao importar a ata colada.';

-- 2. Semanas do planejamento (segunda a domingo; nascem sozinhas na sexta)
create table if not exists public.planejamento_semana (
  id            text primary key,
  ini           date not null,             -- segunda-feira
  payload       jsonb not null,            -- {fim, fechada, fechadoEm, …}
  atualizado_em timestamptz not null default now()
);
create index if not exists planejamento_semana_ini on public.planejamento_semana (ini desc);
comment on table public.planejamento_semana is
  'Uma semana de planejamento (sexta, sem reunião). A tarefa comprometida guarda o id da semana.';

-- 3. Tarefas — a mesma tarefa vista no mês e na semana
create table if not exists public.planejamento_tarefa (
  id            text primary key,
  unidade_id    text,                      -- id da unidade do app; nulo em assunto geral / investimento
  prazo         date,                      -- nulo = tarefa sem prazo (farol cinza, nunca vermelho)
  status        text not null,             -- a_iniciar | em_execucao | finalizado | aguardando_terceiro | aguardando_clima | cancelado
  payload       jsonb not null,            -- a tarefa inteira + payload.historico (quem, quando, de → para, motivo)
  atualizado_em timestamptz not null default now(),
  constraint planejamento_tarefa_status_ok check (status in
    ('a_iniciar','em_execucao','finalizado','aguardando_terceiro','aguardando_clima','cancelado'))
);
create index if not exists planejamento_tarefa_unidade on public.planejamento_tarefa (unidade_id);
create index if not exists planejamento_tarefa_prazo   on public.planejamento_tarefa (prazo);
create index if not exists planejamento_tarefa_status  on public.planejamento_tarefa (status);
comment on table public.planejamento_tarefa is
  'Tarefa da reunião ou da semana. Cancelar é STATUS com motivo — nunca delete. Histórico em payload.historico.';

-- 4. Normalização da unidade (id antigo → unidade de hoje) e carimbo de hora
create or replace function public.plan_normalizar()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  new.atualizado_em := now();
  if to_regproc('public.rel_fz_atual') is not null and new.unidade_id is not null then
    new.unidade_id := public.rel_fz_atual(new.unidade_id);
  end if;
  return new;
end $$;
drop trigger if exists plan_tarefa_normalizar on public.planejamento_tarefa;
create trigger plan_tarefa_normalizar before insert or update on public.planejamento_tarefa
  for each row execute function public.plan_normalizar();

create or replace function public.plan_carimbo()
returns trigger language plpgsql security definer set search_path = public as $$
begin new.atualizado_em := now(); return new; end $$;
drop trigger if exists plan_rodada_carimbo on public.planejamento_rodada;
create trigger plan_rodada_carimbo before insert or update on public.planejamento_rodada
  for each row execute function public.plan_carimbo();
drop trigger if exists plan_semana_carimbo on public.planejamento_semana;
create trigger plan_semana_carimbo before insert or update on public.planejamento_semana
  for each row execute function public.plan_carimbo();

-- 5. Leitura pronta: o mês por unidade (o app calcula o mesmo no aparelho;
--    esta visão é para relatório e conferência pelo SQL Editor).
--    Farol: só A INICIAR e EM EXECUÇÃO recebem cor de prazo; os dois
--    "aguardando" e a tarefa sem prazo ficam em cinza — NUNCA vermelho.
create or replace view public.vw_planejamento_mes
with (security_invoker = true) as
with t as (
  select p.id, p.unidade_id, p.prazo, p.status,
         coalesce((p.payload ->> 'area')::numeric, 0)                as area_ha,
         coalesce(array_length(
           array(select jsonb_array_elements_text(coalesce(p.payload -> 'arrastadaDe', '[]'::jsonb))), 1), 0) as arrastada_reunioes,
         (p.payload ->> 'desc')                                      as descricao,
         -- v78: foto do planejado × executado gravada pelo app (payload -> 'exec')
         coalesce((p.payload -> 'exec' ->> 'meta')::numeric, (p.payload ->> 'area')::numeric, 0) as meta_ha,
         coalesce((p.payload -> 'exec' ->> 'ha')::numeric, 0)        as exec_ha,
         coalesce((p.payload -> 'exec' ->> 'n')::int, 0)             as exec_lancamentos,
         (p.payload ->> 'tipoItem')                                  as tipo_item,
         (p.payload #>> '{bloqueio,quem}')                           as terceiro,
         (p.payload #>> '{bloqueio,desde}')::date                    as bloqueada_desde,
         to_char(coalesce(p.prazo, (p.payload ->> 'criadoEm')::date), 'YYYY-MM') as ref
    from public.planejamento_tarefa p
   where coalesce(p.payload ->> 'tipoItem', 'tarefa') = 'tarefa'
)
select t.ref,
       t.unidade_id,
       u.nome                                                        as unidade,
       count(*)                                                      as tarefas,
       count(*) filter (where t.status = 'finalizado')               as finalizadas,
       count(*) filter (where t.status = 'cancelado')                as canceladas,
       count(*) filter (where t.status in ('aguardando_terceiro','aguardando_clima')) as travadas,
       count(*) filter (where t.status in ('a_iniciar','em_execucao')
                          and t.prazo is not null and t.prazo < public.rel_hoje_brt()) as atrasadas,
       count(*) filter (where t.arrastada_reunioes > 0)              as arrastadas,
       -- v78: planejado × executado em área. "Sem lançamento" = nenhum registro do boletim
       -- casou com a tarefa; é ausência de REGISTRO, nunca afirmação de que não foi feito.
       sum(t.meta_ha) filter (where t.status <> 'cancelado')         as area_planejada,
       sum(least(t.exec_ha, t.meta_ha)) filter (where t.status <> 'cancelado' and t.meta_ha > 0) as area_executada,
       case when sum(t.meta_ha) filter (where t.status <> 'cancelado') > 0
            then round(sum(least(t.exec_ha, t.meta_ha)) filter (where t.status <> 'cancelado' and t.meta_ha > 0) * 100.0
                       / sum(t.meta_ha) filter (where t.status <> 'cancelado'))
       end                                                           as pct_area,
       count(*) filter (where t.status <> 'cancelado' and t.exec_lancamentos = 0) as tarefas_sem_lancamento,
       case when count(*) filter (where t.status <> 'cancelado') > 0
            then round(count(*) filter (where t.status = 'finalizado') * 100.0
                       / count(*) filter (where t.status <> 'cancelado'))
       end                                                           as cumprimento_pct,
       sum(t.area_ha)                                                as area_ha
  from t
  left join public.rel_unidades u on u.id = t.unidade_id
 group by t.ref, t.unidade_id, u.nome;
comment on view public.vw_planejamento_mes is
  'Mês por unidade: cumprimento, atrasadas, travadas, arrastadas e o planejado × executado em área (v78). Travada não conta como atrasada.';

-- 6. Segurança: leitura e escrita anon, como as demais tabelas do app
alter table public.planejamento_rodada enable row level security;
drop policy if exists "planejamento_rodada leitura"  on public.planejamento_rodada;
drop policy if exists "planejamento_rodada escrita"  on public.planejamento_rodada;
create policy "planejamento_rodada leitura" on public.planejamento_rodada for select using (true);
create policy "planejamento_rodada escrita" on public.planejamento_rodada for all using (true) with check (true);

alter table public.planejamento_semana enable row level security;
drop policy if exists "planejamento_semana leitura" on public.planejamento_semana;
drop policy if exists "planejamento_semana escrita" on public.planejamento_semana;
create policy "planejamento_semana leitura" on public.planejamento_semana for select using (true);
create policy "planejamento_semana escrita" on public.planejamento_semana for all using (true) with check (true);

alter table public.planejamento_tarefa enable row level security;
drop policy if exists "planejamento_tarefa leitura" on public.planejamento_tarefa;
drop policy if exists "planejamento_tarefa escrita" on public.planejamento_tarefa;
create policy "planejamento_tarefa leitura" on public.planejamento_tarefa for select using (true);
create policy "planejamento_tarefa escrita" on public.planejamento_tarefa for all using (true) with check (true);

-- 7. Conferência final (é isto que aparece na tela depois do Run)
select 'rodadas' as o_que, count(*)::text as quantas from public.planejamento_rodada
union all
select 'semanas', count(*)::text from public.planejamento_semana
union all
select 'tarefas', count(*)::text from public.planejamento_tarefa
union all
select 'tarefas travadas', count(*)::text from public.planejamento_tarefa
 where status in ('aguardando_terceiro','aguardando_clima')
union all
select 'tarefas com foto do executado (v78)', count(*)::text from public.planejamento_tarefa
 where payload -> 'exec' is not null
union all
select 'linhas na visão do mês', count(*)::text from public.vw_planejamento_mes;
