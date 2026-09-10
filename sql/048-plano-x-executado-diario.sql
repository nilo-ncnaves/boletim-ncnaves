-- ====================================================================
-- 048 — Planejado × executado (plano do dia)  ·  Boletim NCNaves v75
-- ====================================================================
-- O QUE É. O gerente planeja o DIA SEGUINTE ao fechar o boletim (até 3
-- linhas: onde, o que, quantas pessoas). No boletim do dia seguinte o
-- app confere sozinho o que foi registrado e grava o resultado DENTRO
-- do próprio boletim, em boletins.payload -> 'plano':
--
--   {"data":"2026-09-10","criadoEm":"2026-09-09","por":"João",
--    "replanejado":false,"obs":"",
--    "itens":[{"op":"Colheita","ondes":["t101"],"pessoas":"8",
--              "status":"feito|parcial|nao_feito"}, ...],
--    "clima":{"cond":"Chuva forte","chuvaMm":"40","impedido":true},
--    "motivo":{"id":"clima|chuva|maquina|gente|insumo|prioridade|outro",
--              "texto":"","auto":true},
--    "pessoasPrev":15,"pessoasReal":10}
--
-- Nenhuma tabela nova: o plano viaja no payload de `boletins`, que já
-- sincroniza. Este arquivo só ACRESCENTA leitura no motor de relatórios
-- da fase 1 (sql/020): uma visão de conferência e o relatório mensal
-- `plano_x_executado_diario` em `relatorios_gerados`, que o app lê como
-- os outros (REL_CATALOGO do index.html).
--
-- PRÉ-REQUISITO: sql/020-relatorios-motor.sql já rodado (tabelas
-- relatorios_gerados / rel_unidades e funções rel_gravar / rel_executar).
--
-- COMO RODAR (Nilo): SQL Editor do Supabase → colar este arquivo
-- inteiro → Run. Depois, para gerar o mês corrente na hora:
--     select public.rel_rodar_plano_dia();
-- e conferir:
--     select unidade_id, dados from public.relatorios_gerados
--      where relatorio = 'plano_x_executado_diario'
--      order by periodo_fim desc, unidade_id;
--
-- SEGURANÇA. Mesma regra dos outros: a visão é só leitura (a chave
-- publishable lê), as funções são security definer e ficam trancadas
-- para anon/authenticated — só o SQL Editor e o pg_cron chamam.
-- Nada é apagado; regravar o mesmo período sobrescreve a linha.
-- ====================================================================

-- 1. Uma linha por item de plano (conferência e base do relatório)
create or replace view public.vw_plano_x_executado as
  select b.fazenda_id                              as unidade_id,
         (b.data)::date                            as data,
         coalesce(b.payload -> 'plano' ->> 'criadoEm', '')            as plano_criado_em,
         coalesce((b.payload -> 'plano' ->> 'replanejado')::boolean, false) as replanejado,
         coalesce(b.payload -> 'plano' -> 'clima' ->> 'cond', '')     as clima_cond,
         coalesce((b.payload -> 'plano' -> 'clima' ->> 'impedido')::boolean, false) as dia_impedido,
         coalesce(b.payload -> 'plano' -> 'motivo' ->> 'id', '')      as motivo_id,
         coalesce(b.payload -> 'plano' -> 'motivo' ->> 'texto', '')   as motivo_texto,
         coalesce((b.payload -> 'plano' ->> 'pessoasPrev')::numeric, 0) as pessoas_previstas,
         coalesce((b.payload -> 'plano' ->> 'pessoasReal')::numeric, 0) as pessoas_lancadas,
         i ->> 'op'                                as operacao,
         coalesce(i ->> 'status', 'nao_feito')     as status,
         coalesce((i ->> 'pessoas')::numeric, 0)   as pessoas_item,
         coalesce(jsonb_array_length(case when jsonb_typeof(i -> 'ondes') = 'array'
                                          then i -> 'ondes' else '[]'::jsonb end), 0) as n_onde
    from public.boletins b
   cross join lateral jsonb_array_elements(
          case when jsonb_typeof(b.payload -> 'plano' -> 'itens') = 'array'
               then b.payload -> 'plano' -> 'itens' else '[]'::jsonb end) as i
   where coalesce((b.payload ->> 'exemplo')::boolean, false) = false;

comment on view public.vw_plano_x_executado is
  'Boletim NCNaves v75: um item de plano do dia por linha, com o status que o app calculou dos registros daquele boletim. Só leitura. "nao_feito" = não houve REGISTRO daquela operação naquele dia — nunca "não fez".';

-- 2. Relatório mensal consolidado, no formato da fase 1
create or replace function public.rel_plano_x_executado_diario(p_ini date, p_fim date)
returns void language plpgsql security definer set search_path = public as $$
declare v_dados jsonb; v_grupo jsonb;
begin
  -- uma linha por unidade que tenha plano no período
  for v_dados in
    select jsonb_build_object(
             'unidade', t.unidade_id,
             'nome', coalesce(u.nome, t.unidade_id),
             'periodo_ini', p_ini, 'periodo_fim', p_fim,
             'dias_com_plano', t.dias,
             'itens', t.n, 'feito', t.feito, 'parcial', t.parcial, 'nao_feito', t.nao_feito,
             'aderencia_pct', case when t.n > 0 then round(t.feito * 100.0 / t.n) else null end,
             'replanejados', t.replan,
             'dias_impedidos', t.impedidos,
             'desvios_clima', t.desv_clima,
             'desvios_evitaveis', t.desv_evit,
             'pessoas_previstas', t.prev, 'pessoas_lancadas', t.lancadas,
             'precisao_esforco_pct', case when t.prev > 0 then round(t.lancadas * 100.0 / t.prev) else null end,
             'motivos', coalesce(t.motivos, '{}'::jsonb))
      from (
        with dias as (   -- um dia por linha: clima, motivo, replanejado e pessoas do dia (não por item)
          select v.unidade_id, v.data, bool_or(v.dia_impedido) as dia_impedido,
                 max(v.motivo_id) as motivo_id, bool_or(v.replanejado) as replanejado,
                 max(v.pessoas_lancadas) as lancadas, sum(v.pessoas_item) as previstas,
                 bool_or(v.status <> 'feito') as desvio
            from public.vw_plano_x_executado v
           where v.data between p_ini and p_fim
           group by v.unidade_id, v.data
        ), itens as (
          select v.unidade_id, count(*) as n,
                 count(*) filter (where v.status = 'feito')     as feito,
                 count(*) filter (where v.status = 'parcial')   as parcial,
                 count(*) filter (where v.status = 'nao_feito') as nao_feito
            from public.vw_plano_x_executado v
           where v.data between p_ini and p_fim
           group by v.unidade_id
        )
        select d.unidade_id,
               count(*)                                       as dias,
               i.n, i.feito, i.parcial, i.nao_feito,
               count(*) filter (where d.replanejado)           as replan,
               count(*) filter (where d.dia_impedido)          as impedidos,
               count(*) filter (where d.desvio and (d.dia_impedido or d.motivo_id in ('clima','chuva')))          as desv_clima,
               count(*) filter (where d.desvio and not d.dia_impedido and coalesce(d.motivo_id,'') not in ('clima','chuva')) as desv_evit,
               sum(d.previstas)                               as prev,
               sum(d.lancadas)                                as lancadas,
               (select jsonb_object_agg(m.k, m.q) from (
                  select case when x.dia_impedido then 'clima'
                              else coalesce(nullif(x.motivo_id, ''), 'nao_informado') end as k,
                         count(*) as q
                    from dias x
                   where x.unidade_id = d.unidade_id and x.desvio
                   group by 1) m)                             as motivos
          from dias d
          join itens i on i.unidade_id = d.unidade_id
         group by d.unidade_id, i.n, i.feito, i.parcial, i.nao_feito
      ) t
      left join public.rel_unidades u on u.id = t.unidade_id
  loop
    perform public.rel_gravar('plano_x_executado_diario', p_ini, p_fim, v_dados ->> 'unidade', v_dados);
  end loop;

  -- linha do grupo (unidade_id nulo): só a Diretoria lê
  select jsonb_build_object('periodo_ini', p_ini, 'periodo_fim', p_fim,
           'unidades_com_plano', count(distinct v.unidade_id),
           'itens', count(*), 'feito', count(*) filter (where v.status = 'feito'),
           'aderencia_pct', case when count(*) > 0
             then round(count(*) filter (where v.status = 'feito') * 100.0 / count(*)) else null end)
    into v_grupo
    from public.vw_plano_x_executado v
   where v.data between p_ini and p_fim;
  if (v_grupo ->> 'itens')::int > 0 then
    perform public.rel_gravar('plano_x_executado_diario', p_ini, p_fim, null, v_grupo);
  end if;
end $$;

-- 3. Rodada: mês corrente (dia 1 até ontem). Chamar junto da rel_rodar_plano
--    de segunda, ou na mão pelo SQL Editor.
create or replace function public.rel_rodar_plano_dia()
returns void language plpgsql security definer set search_path = public as $$
declare v_fim date := public.rel_hoje_brt() - 1;
        v_ini date := date_trunc('month', public.rel_hoje_brt() - 1)::date;
begin
  perform public.rel_executar('plano_x_executado_diario', v_ini, v_fim,
    format('select public.rel_plano_x_executado_diario(%L, %L)', v_ini, v_fim));
end $$;

-- 4. Trancar as funções (o app nunca as chama; só SQL Editor e pg_cron)
revoke all on function public.rel_plano_x_executado_diario(date, date) from public, anon, authenticated;
revoke all on function public.rel_rodar_plano_dia() from public, anon, authenticated;

-- 5. Agendamento (opcional, junto do que já roda de segunda às 05:00 BRT).
--    Descomentar só depois de conferir na mão:
-- select cron.schedule('rel_plano_dia_segunda', '0 8 * * 1', $$select public.rel_rodar_plano_dia()$$);
