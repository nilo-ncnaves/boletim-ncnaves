-- ====================================================================
-- 051 — Ata × executado (planejamento mensal)  ·  Boletim NCNaves v77
-- ====================================================================
-- O QUE É. Todo mês a reunião administrativa gera uma ata por fazenda, que
-- o app importa como uma RODADA de tarefas (sql/050). Este arquivo só
-- ACRESCENTA leitura ao motor de relatórios da fase 1 (sql/020): o
-- relatório mensal `ata_x_executado` em `relatorios_gerados`, que o app lê
-- como os outros (REL_CATALOGO do index.html) e que a Controladoria usa na
-- reunião seguinte.
--
-- Uma linha por unidade e uma linha do grupo (unidade_id nulo), com:
--   tarefas · finalizadas · cumprimento_pct · atrasadas · travadas ·
--   arrastadas · area_ha · e a distribuição dos motivos de trava.
--
-- REGRA QUE NÃO SE DISCUTE. Tarefa parada por TERCEIRO ou por CHUVA nunca
-- conta como atraso: ela tem status próprio e vira cobrança do escritório.
-- Por isso `atrasadas` só olha A INICIAR e EM EXECUÇÃO com prazo vencido.
-- O relatório relata REGISTRO e PRAZO — nunca "não fez".
--
-- PRÉ-REQUISITOS: sql/020-relatorios-motor.sql e sql/050-planejamento.sql
-- já rodados. Se faltar algum, o bloco para com aviso claro e não faz nada.
--
-- COMO RODAR (Nilo): SQL Editor do Supabase → colar este arquivo inteiro →
-- Run. Depois, para gerar o mês corrente na hora:
--     select public.rel_rodar_ata();
-- e conferir:
--     select unidade_id, dados from public.relatorios_gerados
--      where relatorio = 'ata_x_executado'
--      order by periodo_fim desc, unidade_id;
--
-- SEGURANÇA. A visão é só leitura (a chave publishable lê); as funções são
-- security definer e ficam trancadas para anon/authenticated — só o SQL
-- Editor e o pg_cron chamam. Nada é apagado; regravar o mesmo período
-- sobrescreve a linha.
-- ====================================================================

-- 0. Pré-requisitos
do $$
begin
  if to_regproc('public.rel_gravar') is null or to_regproc('public.rel_executar') is null then
    raise exception 'Rode antes o sql/020-relatorios-motor.sql (faltam rel_gravar / rel_executar).';
  end if;
  if to_regclass('public.planejamento_tarefa') is null then
    raise exception 'Rode antes o sql/050-planejamento.sql (falta planejamento_tarefa).';
  end if;
end $$;

-- 1. Gravação do relatório mensal, uma linha por unidade + a linha do grupo
create or replace function public.rel_ata_x_executado(p_ini date, p_fim date)
returns void language plpgsql security definer set search_path = public as $$
declare v_dados jsonb; v_grupo jsonb;
begin
  for v_dados in
    select jsonb_build_object(
             'unidade', t.unidade_id, 'unidade_nome', coalesce(u.nome, t.unidade_id),
             'periodo_ini', p_ini, 'periodo_fim', p_fim,
             'tarefas', t.tarefas, 'finalizadas', t.finalizadas, 'canceladas', t.canceladas,
             'cumprimento_pct', t.cumprimento_pct,
             'atrasadas', t.atrasadas, 'travadas', t.travadas, 'arrastadas', t.arrastadas,
             'area_ha', round(coalesce(t.area_ha, 0), 2),
             'motivos', coalesce(t.motivos, '{}'::jsonb),
             'farol', case when t.atrasadas > 0 then 'vermelho'
                           when t.travadas  > 0 then 'amarelo' else 'verde' end)
      from (
        select m.unidade_id, m.tarefas, m.finalizadas, m.canceladas, m.cumprimento_pct,
               m.atrasadas, m.travadas, m.arrastadas, m.area_ha,
               (select jsonb_object_agg(x.motivo, x.n) from (
                  select coalesce(nullif(p.payload #>> '{bloqueio,motivo}', ''), 'nao_informado') as motivo,
                         count(*) as n
                    from public.planejamento_tarefa p
                   where p.unidade_id = m.unidade_id
                     and p.status in ('aguardando_terceiro','aguardando_clima')
                   group by 1) x) as motivos
          from public.vw_planejamento_mes m
         where m.ref = to_char(p_fim, 'YYYY-MM')
           and m.unidade_id is not null
      ) t
      left join public.rel_unidades u on u.id = t.unidade_id
  loop
    perform public.rel_gravar('ata_x_executado', p_ini, p_fim, v_dados ->> 'unidade', v_dados);
  end loop;

  -- linha do grupo (unidade_id nulo): só a Diretoria lê
  select jsonb_build_object('periodo_ini', p_ini, 'periodo_fim', p_fim,
           'unidades', count(*),
           'tarefas', coalesce(sum(m.tarefas), 0),
           'finalizadas', coalesce(sum(m.finalizadas), 0),
           'atrasadas', coalesce(sum(m.atrasadas), 0),
           'travadas', coalesce(sum(m.travadas), 0),
           'arrastadas', coalesce(sum(m.arrastadas), 0),
           'cumprimento_pct', case when coalesce(sum(m.tarefas - m.canceladas), 0) > 0
             then round(sum(m.finalizadas) * 100.0 / sum(m.tarefas - m.canceladas)) end)
    into v_grupo
    from public.vw_planejamento_mes m
   where m.ref = to_char(p_fim, 'YYYY-MM') and m.unidade_id is not null;
  if coalesce((v_grupo ->> 'tarefas')::int, 0) > 0 then
    perform public.rel_gravar('ata_x_executado', p_ini, p_fim, null, v_grupo);
  end if;
end $$;

-- 2. Rodada: mês corrente (dia 1 até ontem). Chamar na mão pelo SQL Editor
--    ou junto do que já roda de segunda.
create or replace function public.rel_rodar_ata()
returns void language plpgsql security definer set search_path = public as $$
declare v_fim date := public.rel_hoje_brt() - 1;
        v_ini date := date_trunc('month', public.rel_hoje_brt() - 1)::date;
begin
  perform public.rel_executar('ata_x_executado', v_ini, v_fim,
    format('select public.rel_ata_x_executado(%L, %L)', v_ini, v_fim));
end $$;

-- 3. Trancar as funções (o app nunca as chama; só SQL Editor e pg_cron)
revoke all on function public.rel_ata_x_executado(date, date) from public, anon, authenticated;
revoke all on function public.rel_rodar_ata() from public, anon, authenticated;

-- 4. Agendamento (opcional). Descomentar só depois de conferir na mão:
--    todo dia 9 às 05:00 BRT (08:00 UTC), véspera da reunião do dia 10.
-- select cron.schedule('rel_ata_dia9', '0 8 9 * *', $$select public.rel_rodar_ata()$$);
