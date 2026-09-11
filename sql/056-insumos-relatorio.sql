-- ====================================================================
-- 056 — Insumos: programado × recebido × aplicado (mensal)  ·  v86
-- ====================================================================
-- O QUE É. Este arquivo só ACRESCENTA leitura ao motor de relatórios da
-- fase 1 (sql/020): o relatório mensal `insumos_programado_recebido_aplicado`
-- em `relatorios_gerados`, que o app lê como os outros e que a Controladoria
-- usa na reunião. Uma linha por unidade e uma linha do grupo (unidade_id
-- nulo), com, por produto:
--   programado · recebido · a_receber · aplicado · saldo · dias_de_espera.
--
-- DE ONDE VEM CADA NÚMERO:
--   • programado e recebido → vw_insumo_saldo (sql/054), calculados no banco;
--   • aplicado e saldo → da FOTO que o app grava dentro da própria remessa
--     (payload.alocacoes[].apl e .sal), porque quem sabe transformar o
--     lançamento do boletim em quilos é o app: o de-para de produtos e as
--     doses moram no index.html. O app regrava essa foto a cada
--     sincronização; aqui só se lê. Sem foto, o relatório traz programado e
--     recebido e deixa aplicado nulo — nunca estima.
--   A foto é do par unidade × produto (acumulada), e por isso o SQL usa o
--   MAIOR valor do par, nunca a soma das remessas.
--
-- REGRA QUE NÃO SE DISCUTE. "A receber" e "sem recebimento registrado" são
-- ausência de REGISTRO — nunca afirmação de que a carga não saiu ou de que o
-- serviço não foi feito. O relatório relata chegada e registro.
--
-- PRÉ-REQUISITOS: sql/020-relatorios-motor.sql e sql/054-insumos.sql já
-- rodados. Se faltar algum, o bloco para com aviso claro e não faz nada.
--
-- COMO RODAR (Nilo): SQL Editor do Supabase → colar este arquivo inteiro →
-- Run. Depois, para gerar o mês corrente na hora:
--     select public.rel_rodar_insumos();
-- e conferir:
--     select unidade_id, dados from public.relatorios_gerados
--      where relatorio = 'insumos_programado_recebido_aplicado'
--      order by periodo_fim desc, unidade_id;
--
-- SEGURANÇA. As funções são security definer e ficam trancadas para
-- anon/authenticated — só o SQL Editor e o pg_cron chamam. Nada é apagado;
-- regravar o mesmo período sobrescreve a linha.
-- ====================================================================

-- 0. Pré-requisitos
do $$
begin
  if to_regproc('public.rel_gravar') is null or to_regproc('public.rel_executar') is null then
    raise exception 'Rode antes o sql/020-relatorios-motor.sql (faltam rel_gravar / rel_executar).';
  end if;
  if to_regclass('public.insumo_remessa') is null or to_regclass('public.vw_insumo_saldo') is null then
    raise exception 'Rode antes o sql/054-insumos.sql (faltam insumo_remessa / vw_insumo_saldo).';
  end if;
end $$;

-- 1. Foto do aplicado, por unidade × produto (o maior valor, nunca a soma)
drop view if exists public.vw_insumo_aplicado;
create view public.vw_insumo_aplicado with (security_invoker = true) as
select a->>'unidade'                                  as unidade_id,
       r.produto,
       max(coalesce((a->>'apl')::numeric, 0))         as kg_aplicado,
       max(coalesce((a->>'sal')::numeric, 0))         as kg_saldo,
       max(a->>'em')                                  as fotografado_em
  from public.insumo_remessa r
  cross join lateral jsonb_array_elements(coalesce(r.payload->'alocacoes','[]'::jsonb)) a
 where a ? 'apl'
 group by 1, 2;

comment on view public.vw_insumo_aplicado is
  'v86 — foto do aplicado e do saldo por unidade × produto, gravada pelo app dentro da remessa. Sem foto, nada é estimado.';

-- 2. Gravação do relatório mensal, uma linha por unidade + a linha do grupo
create or replace function public.rel_insumos(p_ini date, p_fim date)
returns void language plpgsql security definer set search_path = public as $$
declare v_dados jsonb; v_grupo jsonb;
begin
  for v_dados in
    select jsonb_build_object(
             'unidade', t.unidade_id, 'unidade_nome', coalesce(u.nome, t.unidade_id),
             'periodo_ini', p_ini, 'periodo_fim', p_fim,
             'produtos', t.produtos,
             'programado', round(t.programado, 0),
             'recebido',   round(t.recebido, 0),
             'a_receber',  round(t.a_receber, 0),
             'aplicado',   case when t.tem_foto then round(t.aplicado, 0) end,
             'saldo',      case when t.tem_foto then round(t.saldo, 0) end,
             'maior_espera_dias', t.maior_espera,
             'detalhe', t.detalhe)
      from (
        select s.unidade_id,
               count(distinct s.produto)                 as produtos,
               sum(s.kg_programado)                      as programado,
               sum(s.kg_recebido)                        as recebido,
               sum(s.kg_a_receber)                       as a_receber,
               coalesce(sum(ap.kg_aplicado), 0)          as aplicado,
               coalesce(sum(ap.kg_saldo), 0)             as saldo,
               bool_or(ap.kg_aplicado is not null)       as tem_foto,
               max(case when s.kg_a_receber > 0 then s.dias_desde_o_anuncio end) as maior_espera,
               jsonb_agg(jsonb_build_object('produto', s.produto, 'fornecedor', s.fornecedor,
                 'programado', round(s.kg_programado,0), 'recebido', round(s.kg_recebido,0),
                 'a_receber', round(s.kg_a_receber,0),
                 'aplicado', round(coalesce(ap.kg_aplicado,0),0)) order by s.produto) as detalhe
          from (select unidade_id, produto, max(fornecedor) as fornecedor,
                       sum(kg_programado) as kg_programado, sum(kg_recebido) as kg_recebido,
                       sum(kg_a_receber) as kg_a_receber, max(dias_desde_o_anuncio) as dias_desde_o_anuncio
                  from public.vw_insumo_saldo
                 where anunciado_em is null or anunciado_em <= p_fim
                 group by 1,2) s
          left join public.vw_insumo_aplicado ap
            on ap.unidade_id = s.unidade_id and ap.produto = s.produto
         where s.unidade_id is not null
         group by s.unidade_id
      ) t
      left join public.rel_unidades u on u.id = t.unidade_id
  loop
    perform public.rel_gravar('insumos_programado_recebido_aplicado', p_ini, p_fim, v_dados ->> 'unidade', v_dados);
  end loop;

  -- linha do grupo (unidade_id nulo): só a Diretoria lê
  select jsonb_build_object('periodo_ini', p_ini, 'periodo_fim', p_fim,
           'unidades', count(distinct s.unidade_id),
           'produtos', count(distinct s.produto),
           'programado', round(coalesce(sum(s.kg_programado),0), 0),
           'recebido',   round(coalesce(sum(s.kg_recebido),0), 0),
           'a_receber',  round(coalesce(sum(s.kg_a_receber),0), 0),
           'maior_espera_dias', max(case when s.kg_a_receber > 0 then s.dias_desde_o_anuncio end))
    into v_grupo
    from public.vw_insumo_saldo s
   where s.unidade_id is not null and (s.anunciado_em is null or s.anunciado_em <= p_fim);
  if coalesce((v_grupo ->> 'programado')::numeric, 0) > 0 then
    perform public.rel_gravar('insumos_programado_recebido_aplicado', p_ini, p_fim, null, v_grupo);
  end if;
end $$;

-- 3. Rodada: mês corrente (dia 1 até ontem)
create or replace function public.rel_rodar_insumos()
returns void language plpgsql security definer set search_path = public as $$
declare v_fim date := public.rel_hoje_brt() - 1;
        v_ini date := date_trunc('month', public.rel_hoje_brt() - 1)::date;
begin
  perform public.rel_executar('insumos_programado_recebido_aplicado', v_ini, v_fim,
    format('select public.rel_insumos(%L, %L)', v_ini, v_fim));
end $$;

-- 4. Trancar as funções (o app nunca as chama; só SQL Editor e pg_cron)
revoke all on function public.rel_insumos(date, date) from public, anon, authenticated;
revoke all on function public.rel_rodar_insumos() from public, anon, authenticated;

notify pgrst, 'reload schema';

-- 5. Agendamento (opcional). Descomentar só depois de conferir na mão:
--    todo dia 9 às 05:10 BRT (08:10 UTC), véspera da reunião do dia 10.
-- select cron.schedule('rel_insumos_dia9', '10 8 9 * *', $$select public.rel_rodar_insumos()$$);

-- conferência
select 'relatório de insumos instalado' as passo,
       (select count(*) from public.vw_insumo_aplicado) as linhas_com_foto_do_aplicado;
