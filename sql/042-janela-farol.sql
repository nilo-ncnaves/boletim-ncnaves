-- Janela e farol de registro (v60) — tabela operacao_janela + visão vw_farol_registro
-- Rodar no SQL Editor do Supabase (projeto syvehtgrbqteyuqhoban).
--
-- PASSO A PASSO (pelo iPhone):
--   1. Abra o Supabase e entre no projeto do Boletim.
--   2. Toque em "SQL Editor" e em "New query".
--   3. Selecione TODO o texto deste arquivo, copie e cole na caixa.
--   4. Toque em "Run".
--   5. No fim aparece uma tabelinha de conferência (uma linha por atividade
--      e farol). Pode rodar de novo quantas vezes quiser: nada duplica.
--
-- ANTES: sql/020 (motor) e sql/040 (dias sem registro) precisam ter rodado
-- (os dois rodaram em 05/09 e 07/09/2026). Se faltar, o bloco para com um
-- aviso claro e não faz nada.
--
-- O QUE É: a "janela" de uma operação é a cadência com que se ESPERA um
-- registro dela no boletim (ex.: suplementação a cada 7 dias) mais uma
-- tolerância (a janela fica aberta por mais N dias). O farol compara os
-- dias sem registro (vw_dias_sem_registro, sql/040) com a janela:
--   verde    — registrado dentro da cadência;
--   amarelo  — sem registro, mas a janela ainda está aberta;
--   vermelho — SÓ depois de a janela fechar (cadência + tolerância);
--   cinza    — unidade sem nenhum boletim (não há como medir).
-- Operação SEM janela não ganha farol (farol nulo): o app só mostra
-- "há N dias" / "sem registro". Nunca registrado desde o 1º boletim da
-- unidade conta os dias a partir desse 1º boletim, e o texto diz isso.
--
-- VOCABULÁRIO (regra do projeto): "sem registro", nunca "não fez";
-- "janela aberta" / "janela fechada", nunca "atrasado" ou "pendente".
-- Janela NÃO é prescrição: é a cadência de registro que a Diretoria
-- espera ver no boletim, para saber onde olhar. Nada aqui diz o que
-- fazer no campo, com que produto ou dose.
--
-- JANELAS PROPOSTAS (origem = 'proposta'): seed abaixo só para grãos e
-- pecuária, para o Nilo, o agrônomo e o veterinário ajustarem. Café fica
-- SEM janela nesta versão (o café já tem os faróis do plano de safra,
-- relatório plano_executado_mes). Ajustar é só SQL:
--   update public.operacao_janela set cadencia_dias = 10, tolerancia_dias = 5,
--     origem = 'veterinario' where operacao_id = 'PEC-SUPLEMENTACAO';
--   -- desligar a janela de uma unidade específica (ex.: pivô sem lavoura):
--   insert into public.operacao_janela (operacao_id, unidade_id, cadencia_dias, ativo, obs)
--     values ('GRAOS-MONITORAMENTO_DE_PRAGAS_E_DOENCAS', 'f35', 7, false, 'sem lavoura no campo');
-- A linha da unidade (unidade_id preenchido) vence a linha geral (nula).
--
-- SEGURANÇA: mesmo padrão do sql/040 — leitura anon por policy select, sem
-- policy de escrita (só o SQL Editor grava); visões com security_invoker.

-- 0. Pré-requisitos
do $$
begin
  if to_regclass('public.vw_dias_sem_registro') is null or to_regclass('public.operacao_catalogo') is null then
    raise exception 'Rode antes o sql/040-dias-sem-registro.sql (falta vw_dias_sem_registro / operacao_catalogo).';
  end if;
  if to_regproc('public.rel_hoje_brt') is null or to_regproc('public.rel_fz_atual') is null then
    raise exception 'Rode antes o sql/020-relatorios-motor.sql (faltam rel_hoje_brt / rel_fz_atual).';
  end if;
end $$;

-- 1. Janela por operação (e, se quiser, por unidade)
create table if not exists public.operacao_janela (
  id              bigint generated always as identity primary key,
  operacao_id     text not null references public.operacao_catalogo (id),
  unidade_id      text,                                  -- nulo = vale para todas as unidades da atividade
  cadencia_dias   integer not null check (cadencia_dias > 0),      -- registro esperado a cada N dias
  tolerancia_dias integer not null default 0 check (tolerancia_dias >= 0), -- janela fica aberta por mais N dias
  origem          text not null default 'proposta',      -- proposta | agronomo | veterinario | nilo
  obs             text,
  ativo           boolean not null default true,         -- false = sem farol (a linha da unidade pode desligar a geral)
  criado_em       timestamptz not null default now()
);
comment on table public.operacao_janela is
  'Cadência esperada de registro por operação (Boletim NCNaves v60). Não é prescrição: diz com que frequência a Diretoria espera ver a operação no boletim. unidade_id nulo = geral da atividade; linha por unidade vence a geral. Só o SQL Editor escreve.';
create unique index if not exists operacao_janela_chave
  on public.operacao_janela (operacao_id, (coalesce(unidade_id, '')));
alter table public.operacao_janela enable row level security;
drop policy if exists "operacao_janela leitura" on public.operacao_janela;
create policy "operacao_janela leitura" on public.operacao_janela for select using (true);

-- 2. Seed das janelas propostas (grãos e pecuária). Repetir não duplica.
insert into public.operacao_janela (operacao_id, cadencia_dias, tolerancia_dias, origem, obs) values
  ('PEC-SUPLEMENTACAO',                        7,   3, 'proposta', 'cocho: sal / proteinado / ração'),
  ('PEC-CONFERENCIA_DE_AGUA_AGUADAS',          7,   3, 'proposta', null),
  ('PEC-CONTAGEM',                             30, 10, 'proposta', 'contagem por lote / pasto'),
  ('PEC-CONTROLE_DE_CARRAPATO_MOSCA_DO_CHIFRE',30, 15, 'proposta', null),
  ('PEC-MANUTENCAO_DE_CERCA_COCHO_BEBEDOURO',  30, 15, 'proposta', null),
  ('PEC-CONTROLE_DE_FORMIGA',                  60, 30, 'proposta', null),
  ('PEC-PESAGEM',                              90, 30, 'proposta', null),
  ('PEC-VERMIFUGACAO',                         90, 30, 'proposta', null),
  ('PEC-VACINACAO',                           180, 30, 'proposta', 'campanhas semestrais'),
  ('GRAOS-MONITORAMENTO_DE_PRAGAS_E_DOENCAS',  7,   3, 'proposta', 'só faz sentido com lavoura no campo: desligar por unidade no vazio (linha com ativo = false)')
on conflict (operacao_id, (coalesce(unidade_id, ''))) do nothing;

-- 3. Primeiro e último boletim de cada unidade (para "nunca registrado" ter referência)
create or replace view public.vw_dsr_boletim_unidade
with (security_invoker = true) as
select public.rel_fz_atual(b.fazenda_id) as unidade_id,
       min(b.data::date) as primeiro_boletim,
       max(b.data::date) as ultimo_boletim,
       count(*)::integer as boletins
from public.boletins b
where coalesce((b.payload ->> 'exemplo')::boolean, false) = false
group by 1;

-- 4. A visão do farol: uma linha por unidade × operação (todas), farol só onde há janela
create or replace view public.vw_farol_registro
with (security_invoker = true) as
with base as (
  select d.unidade_id, d.operacao_id, d.atividade, d.operacao_nome, d.fase,
         d.data_ultimo_registro, d.dias_sem_registro, d.nunca_registrado,
         u.primeiro_boletim, u.ultimo_boletim, u.boletins,
         j.id as janela_id, j.ativo as janela_ativa, j.cadencia_dias, j.tolerancia_dias, j.origem as janela_origem,
         (j.unidade_id is not null) as janela_da_unidade,
         case when d.dias_sem_registro is not null then d.dias_sem_registro
              when u.primeiro_boletim is not null then (public.rel_hoje_brt() - u.primeiro_boletim)::integer
              else null end as dias_ref
  from public.vw_dias_sem_registro d
  left join public.vw_dsr_boletim_unidade u on u.unidade_id = d.unidade_id
  left join lateral (
    select * from public.operacao_janela j
    where j.operacao_id = d.operacao_id and (j.unidade_id = d.unidade_id or j.unidade_id is null)
    order by j.unidade_id nulls last
    limit 1) j on true
),
calc as (
  select b.*,
    case when janela_id is null or not janela_ativa then null
         when dias_ref is null then 'cinza'
         when not nunca_registrado and dias_ref <= cadencia_dias then 'verde'
         when dias_ref <= cadencia_dias + tolerancia_dias then 'amarelo'
         else 'vermelho' end as farol,
    case when janela_id is null or not janela_ativa then null
         else (cadencia_dias + tolerancia_dias - dias_ref) end as fecha_em_dias
  from base b
)
select unidade_id, operacao_id, atividade, operacao_nome, fase,
  data_ultimo_registro, dias_sem_registro, nunca_registrado,
  primeiro_boletim, ultimo_boletim, boletins,
  cadencia_dias, tolerancia_dias, janela_origem, janela_da_unidade,
  farol, fecha_em_dias,
  case farol
    when 'cinza'    then 'unidade sem boletim · sem histórico'
    when 'verde'    then case when dias_ref = 0 then 'registrado hoje' else 'registrado há ' || dias_ref || ' dia' || case when dias_ref = 1 then '' else 's' end end
    when 'amarelo'  then case when nunca_registrado
                           then 'sem registro desde o 1º boletim (há ' || dias_ref || ' dias) · janela aberta, fecha em ' || fecha_em_dias || ' dia' || case when fecha_em_dias = 1 then '' else 's' end
                           else 'sem registro há ' || dias_ref || ' dia' || case when dias_ref = 1 then '' else 's' end || ' · janela aberta, fecha em ' || fecha_em_dias || ' dia' || case when fecha_em_dias = 1 then '' else 's' end end
    when 'vermelho' then case when nunca_registrado
                           then 'sem registro desde o 1º boletim (há ' || dias_ref || ' dias) · janela fechada há ' || (-fecha_em_dias) || ' dia' || case when -fecha_em_dias = 1 then '' else 's' end
                           else 'sem registro há ' || dias_ref || ' dia' || case when dias_ref = 1 then '' else 's' end || ' · janela fechada há ' || (-fecha_em_dias) || ' dia' || case when -fecha_em_dias = 1 then '' else 's' end end
    else null end as situacao
from calc;
comment on view public.vw_farol_registro is
  'Farol de registro por unidade × operação (Boletim NCNaves v60): compara vw_dias_sem_registro com operacao_janela. verde = registrado na cadência; amarelo = sem registro, janela aberta; vermelho = só com a janela fechada; cinza = unidade sem boletim; nulo = operação sem janela. Texto em situacao: "sem registro", nunca "não fez".';

-- 5. Conferência (aparece na tela ao terminar)
select atividade, coalesce(farol, '(sem janela)') as farol, count(*) as combinacoes,
       min(dias_sem_registro) as menor_dias, max(dias_sem_registro) as maior_dias
from public.vw_farol_registro
group by atividade, farol
order by atividade, farol;
