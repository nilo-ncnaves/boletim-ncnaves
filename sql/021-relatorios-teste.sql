-- Relatórios automáticos — chamadas manuais para conferir (v55)
-- Rodar no SQL Editor do Supabase DEPOIS do sql/020-relatorios-motor.sql.
-- Cada bloco é independente: selecione e rode um de cada vez, ou tudo de uma
-- vez (leva alguns segundos). Rodar de novo o mesmo período só regrava a
-- linha (não duplica). Datas de exemplo: troque à vontade.
--
-- Períodos que o agendador usa (Brasília):
--   diário   = ontem                        (farol 7/30, dito × medido dia, balanço hídrico)
--   semanal  = últimos 7 dias até ontem     (recomendado × executado, dito × medido semana)
--   mensal   = mês anterior fechado         (custo físico, rebanho, plano × executado fechado)
--   segunda  = mês corrente até ontem       (plano × executado parcial)

-- 1. Farol de completude (7 e 30 dias terminando ontem) ------------------
select public.rel_farol(7);
select public.rel_farol(30);
-- ou um período fixo (fim = 03/09/2026):
-- select public.rel_farol(7, date '2026-09-03');

-- 2. Dito × medido iCrop: um dia e uma semana -----------------------------
select public.rel_dito_medido_icrop(public.rel_hoje_brt() - 1, public.rel_hoje_brt() - 1);
select public.rel_dito_medido_icrop(public.rel_hoje_brt() - 7, public.rel_hoje_brt() - 1);
-- exemplo fixo: select public.rel_dito_medido_icrop(date '2026-08-28', date '2026-09-03');

-- 3. Dito × medido Solinftec: um dia e uma semana -------------------------
select public.rel_dito_medido_solinftec(public.rel_hoje_brt() - 1, public.rel_hoje_brt() - 1);
select public.rel_dito_medido_solinftec(public.rel_hoje_brt() - 7, public.rel_hoje_brt() - 1);

-- 4. Irrigação recomendado × executado (semana) ---------------------------
select public.rel_irrigacao_recomendado_executado(public.rel_hoje_brt() - 7, public.rel_hoje_brt() - 1);

-- 5. Balanço hídrico (ontem) ----------------------------------------------
select public.rel_balanco_hidrico();
-- exemplo fixo: select public.rel_balanco_hidrico(date '2026-09-02');

-- 6. Custo físico por talhão (mês anterior fechado e mês corrente parcial) -
select public.rel_custo_fisico_talhao(
  (date_trunc('month', public.rel_hoje_brt()) - interval '1 month')::date,
  (date_trunc('month', public.rel_hoje_brt()) - interval '1 day')::date);
select public.rel_custo_fisico_talhao(date_trunc('month', public.rel_hoje_brt())::date, public.rel_hoje_brt() - 1);
-- exemplo fixo: select public.rel_custo_fisico_talhao(date '2026-08-01', date '2026-08-31');

-- 7. Rebanho (mês anterior fechado) ---------------------------------------
select public.rel_rebanho(
  (date_trunc('month', public.rel_hoje_brt()) - interval '1 month')::date,
  (date_trunc('month', public.rel_hoje_brt()) - interval '1 day')::date);
-- exemplo fixo: select public.rel_rebanho(date '2026-08-01', date '2026-08-31');

-- 8. Plano × executado (mês corrente parcial) -----------------------------
-- Precisa de sql/005, 006 e 007 rodados (plano vigente); senão grava só um aviso.
select public.rel_plano_executado(date_trunc('month', public.rel_hoje_brt())::date, public.rel_hoje_brt() - 1);
-- exemplo fixo: select public.rel_plano_executado(date '2026-09-01', date '2026-09-03');

-- 9. As quatro rodadas exatamente como o pg_cron chama --------------------
select public.rel_rodar_diario();
select public.rel_rodar_semanal();
select public.rel_rodar_mensal();
select public.rel_rodar_plano();

-- ====================================================================
-- CONFERÊNCIA
-- ====================================================================
-- O que foi gerado (uma linha por relatório × período; unidade_id nulo = grupo)
select relatorio, periodo_ini, periodo_fim, count(*) as linhas,
  count(*) filter (where unidade_id is null) as linhas_grupo,
  max(gerado_em) as gerado_em, pg_size_pretty(sum(length(dados::text))::bigint) as tamanho
from public.relatorios_gerados
group by 1, 2, 3 order by 1, 2 desc;

-- Diário de bordo das rodadas (erro = motivo em texto)
select relatorio, periodo_ini, periodo_fim, ok, erro, quando
from public.relatorios_execucoes order by quando desc limit 40;

-- Farol do grupo (placar) e quem não está em dia
select dados ->> 'placar' as placar, dados -> 'unidades' as unidades
from public.relatorios_gerados
where relatorio = 'farol_7' and unidade_id is null order by periodo_fim desc limit 1;
select u ->> 'nome' as unidade, u ->> 'marcas' as marcas, u ->> 'enviados' as enviados, u ->> 'uteis' as uteis, u ->> 'ultimo_envio' as ultimo_envio
from public.relatorios_gerados r cross join lateral jsonb_array_elements(r.dados -> 'unidades') u
where r.relatorio = 'farol_7' and r.unidade_id is null and r.periodo_fim = (select max(periodo_fim) from public.relatorios_gerados where relatorio = 'farol_7')
  and not (u ->> 'em_dia')::boolean order by 1;

-- Divergências dito × medido (iCrop e Solinftec) do último período gerado
select r.relatorio, r.periodo_ini, r.periodo_fim, r.unidade_id, d ->> 'data' as data, d ->> 'nome' as pivo_ou_maquina, d ->> 'tipo' as tipo, d ->> 'texto' as texto
from public.relatorios_gerados r cross join lateral jsonb_array_elements(r.dados -> 'divergencias') d
where r.relatorio like 'dito_medido_%' and r.periodo_fim = (select max(periodo_fim) from public.relatorios_gerados where relatorio like 'dito_medido_%')
order by 1, 4, 5;

-- Irrigação: pivôs em alerta (atraso ≥ 3 dias ou dia recomendado sem irrigação)
select r.unidade_id, p ->> 'equipamento' as pivo, p ->> 'dias_rec' as dias_rec, p ->> 'dias_irr' as dias_irr, p ->> 'mm_min_rec' as mm_min_rec,
  p ->> 'mm_real' as mm_real, p ->> 'reais_nec' as reais_nec, p ->> 'reais_real' as reais_real, p ->> 'atraso' as atraso
from public.relatorios_gerados r cross join lateral jsonb_array_elements(r.dados -> 'pivos') p
where r.relatorio = 'irrigacao_rec_exec_semana' and (p ->> 'alerta')::boolean order by 1, 2;

-- Plano × executado: faróis amarelos/vermelhos por unidade do plano
select r.unidade_id, r.periodo_fim, u ->> 'codigo' as codigo, u -> 'adubo' ->> 'situacao' as adubo, u -> 'calagem' ->> 'situacao' as calagem, u -> 'fito' ->> 'situacao' as fito
from public.relatorios_gerados r cross join lateral jsonb_array_elements(r.dados -> 'unidades') u
where r.relatorio = 'plano_executado_mes'
  and (u -> 'adubo' ->> 'farol' in ('amarelo', 'vermelho') or u -> 'calagem' ->> 'farol' in ('amarelo', 'vermelho') or u -> 'fito' ->> 'farol' in ('amarelo', 'vermelho'))
order by 1, 2 desc, 3;

-- Ver o JSON inteiro de uma linha (troque relatório e unidade)
-- select jsonb_pretty(dados) from public.relatorios_gerados where relatorio = 'rebanho_mes' and unidade_id = 'f26' order by periodo_fim desc limit 1;

-- Limpeza (só se quiser recomeçar do zero — o agendador regrava tudo na próxima rodada)
-- truncate public.relatorios_gerados, public.relatorios_execucoes;
