-- ====================================================================
-- 03-visoes.sql — Projeto "Solinftec na gestão" (Grupo LGS)
-- ====================================================================
-- COMO USAR: Supabase › SQL Editor › New query › colar o arquivo
-- INTEIRO › Run. Leva poucos segundos. Rodar de novo é seguro.
-- PRÉ-REQUISITO: 01 e 02 já rodados.
--
-- O QUE ESTE ARQUIVO FAZ: cria as "visões" — consultas prontas que as
-- tarefas agendadas do Claude leem. Elas só SOMAM e COMPARAM; não
-- gravam nada. O dado bruto (solinftec_hora) continua trancado; a
-- chave pública lê só estas visões, que já vêm agregadas.
--
--   vw_status_robo ................ última data gravada e dias sem dado
--   vw_maquinas_semana ............ máquina × semana: motor, efetivo,
--                                   ocioso, área, ha/h, L/h, jornada,
--                                   dias úteis sem motor, paradas
--   vw_operacao_semana ............ ha/h da operação × média das 4
--                                   semanas anteriores
--   vw_fora_horario_semana ........ motor ligado de noite, no domingo
--                                   ou fora do núcleo habitual
--   vw_aplicacao_fora_faixa_semana  horas e ha fora da faixa de
--                                   velocidade/RPM (vazia até o
--                                   agrônomo preencher faixas_operacao)
--   vw_horimetro_atual ............ maior horímetro e horas na semana
--   vw_frota_mes .................. utilização por máquina e por modelo
--   vw_operador_mes ............... por operador (código) e operação
--   vw_talhao_mes ................. talhão × máquina: motor, diesel,
--                                   área e manutenção estimada (R$)
--
-- DEFINIÇÕES (as mesmas em todas as visões):
--   dia ........... o dia da Solinftec (dia produtivo, como no site;
--                   06 a 09/10 somou 483,0 h, igual ao site).
--   semana ........ começa na segunda (coluna "semana" = a segunda).
--   dia útil ...... segunda a sábado, só dias já fechados (até ontem).
--   motor ......... motor ligado (h).
--   efetivo ....... motor ligado menos ocioso, só em operação produtiva.
--   ha/h .......... área ÷ efetivo.
--   L/h ........... diesel ÷ motor.
--   jornada ....... parametros.jornada_h (9 h) × dias úteis.
--   paradas ....... tempo em código de parada DENTRO da jornada
--                   (7h–17h, seg–sáb); a noite com a máquina
--                   desligada não conta como parada.
--   Fazendas marcadas "fora" em solinftec_nucleo (Estreito, "-1") não
--   entram (só no vw_status_robo, que conta tudo).
-- ====================================================================

-- Apoio: dias úteis (seg–sáb) entre duas datas, sem passar de ontem.
create or replace function public.sol_dias_uteis(ini date, fim date)
returns int
language sql
stable
as $$
  select count(*)::int
  from generate_series(ini, least(fim, (now() at time zone 'America/Sao_Paulo')::date - 1), interval '1 day') d
  where extract(isodow from d) <= 6
$$;

create or replace function public.sol_param(p text)
returns numeric
language sql
stable
security definer
set search_path = public
as $$ select valor from public.parametros where chave = p $$;

-- Base: uma linha por registro da API, já com máquina, núcleo e tipo
-- da operação. PRIVADA (tem todo o detalhe) — a chave pública não lê.
create or replace view public.vw_sol_base as
select
  h.data,
  (h.data - (extract(isodow from h.data)::int - 1))       as semana,
  date_trunc('month', h.data)::date                        as mes,
  h.inicio,
  h.hora,
  coalesce(h.inicio::date, h.data)                         as dia_relogio,
  coalesce(m.codigo, cod.cod, h.cd_equipamento, h.ds_equipamento) as maquina,
  coalesce(m.nome, h.ds_equipamento)                       as maquina_nome,
  m.modelo,
  m.grupo,
  m.nucleo_habitual,
  h.ds_fazenda,
  coalesce(n.nucleo, h.ds_fazenda)                         as nucleo,
  coalesce(n.fora, false)                                  as fora,
  h.cd_operador                                            as operador,
  h.ds_talhao                                              as talhao,
  h.cd_operacao,
  coalesce(op.descricao, 'Operação ' || h.cd_operacao)     as operacao,
  op.tipo,
  h.cd_operacao_cb,
  coalesce(h.vl_tempo_motor_ligado, 0) / 3600.0            as motor_h,
  coalesce(h.vl_tempo_motor_ocioso, 0) / 3600.0            as ocioso_h,
  coalesce(h.vl_tempo_segundos, 0) / 3600.0                as tempo_h,
  case when op.tipo = 'produtiva'
       then greatest(coalesce(h.vl_tempo_motor_ligado, 0) - coalesce(h.vl_tempo_motor_ocioso, 0), 0) / 3600.0
       else 0 end                                          as efetivo_h,
  coalesce(h.vl_area_operacional, 0)                       as area_ha,
  coalesce(h.vl_consumo_medio, 0)                          as litros,
  h.vl_velocidade_media                                    as vel,
  h.vl_rpm_medio                                           as rpm,
  h.vl_horim_max_hora                                      as horimetro,
  -- dentro da jornada (7h–17h, segunda a sábado): paradas só contam aqui;
  -- fora dela a máquina desligada à noite viraria "parada"
  (h.hora between 7 and 16
   and extract(isodow from coalesce(h.inicio::date, h.data)) <= 6)  as na_jornada
from public.solinftec_hora h
left join lateral (
  select substring(h.ds_equipamento from '(?i)COD\.?\s*(\d+)') as cod
) cod on true
left join public.maquinas m
  on m.codigo = cod.cod
  or (cod.cod is null and m.nome_solinftec = h.ds_equipamento)
left join public.solinftec_nucleo n on n.fazenda_sol = h.ds_fazenda
left join public.solinftec_operacoes op on op.cd = h.cd_operacao;

revoke all on public.vw_sol_base from anon, authenticated;

-- 1. Status do robô -------------------------------------------------------
create or replace view public.vw_status_robo as
with u as (
  select max(data) as ultima_data, max(atualizado_em) as gravado_em
  from public.solinftec_hora
)
select
  u.ultima_data,
  u.gravado_em,
  -- 0 = ontem já está gravado (o normal); o dia de hoje ainda não fechou
  greatest(((now() at time zone 'America/Sao_Paulo')::date - 1) - u.ultima_data, 0) as dias_sem_dado,
  greatest(((now() at time zone 'America/Sao_Paulo')::date - 1) - u.ultima_data, 0)
    > public.sol_param('robo_dias_sem_dado')                                        as alerta
from u;

-- 2. Máquinas por semana --------------------------------------------------
create or replace view public.vw_maquinas_semana as
with b as (
  select * from public.vw_sol_base where not fora
),
dia as (  -- motor por máquina e dia
  select semana, maquina, data, sum(motor_h) as motor_h
  from b group by 1, 2, 3
),
sem as (
  select b.semana, b.maquina,
    max(b.maquina_nome) as maquina_nome, max(b.modelo) as modelo, max(b.grupo) as grupo,
    max(b.nucleo_habitual) as nucleo_habitual,
    sum(b.motor_h) as motor_h, sum(b.efetivo_h) as efetivo_h, sum(b.ocioso_h) as ocioso_h,
    sum(b.area_ha) as area_ha, sum(b.litros) as litros,
    sum(b.motor_h) filter (where b.nucleo_habitual is not null and b.nucleo <> b.nucleo_habitual) as motor_fora_nucleo_h
  from b group by 1, 2
),
-- o núcleo da linha: o habitual; sem habitual, onde rodou mais na semana
nuc as (
  select distinct on (semana, maquina) semana, maquina, nucleo
  from b group by semana, maquina, nucleo
  order by semana, maquina, sum(motor_h) desc
),
par as (
  select semana, maquina, jsonb_object_agg(operacao, round(h::numeric, 2) order by h desc) as paradas_h
  from (select semana, maquina, operacao, sum(tempo_h) as h
        from b where tipo = 'parada' and na_jornada group by 1, 2, 3) x
  where h > 0
  group by 1, 2
),
uteis as (
  select s.semana, s.maquina,
    public.sol_dias_uteis(s.semana, s.semana + 5) as dias_uteis,
    (select count(*) from dia d where d.semana = s.semana and d.maquina = s.maquina
        and extract(isodow from d.data) <= 6 and d.motor_h > 0.01)::int as dias_uteis_com_motor,
    (select count(*) from dia d where d.semana = s.semana and d.maquina = s.maquina
        and extract(isodow from d.data) <= 6 and d.motor_h > 0.01
        and d.motor_h < public.sol_param('motor_min_dia_util_h'))::int as dias_uteis_motor_baixo
  from sem s
),
lh as (
  select s.*, case when s.motor_h > 0 then s.litros / s.motor_h end as l_h from sem s
),
med as (
  select semana, modelo, percentile_cont(0.5) within group (order by l_h) as mediana_l_h_modelo
  from lh where l_h > 0 and modelo is not null group by 1, 2
)
select
  lh.semana,
  coalesce(lh.nucleo_habitual, nuc.nucleo)                         as nucleo,
  lh.maquina, lh.maquina_nome, lh.modelo, lh.grupo,
  round(lh.motor_h::numeric, 2)                                    as motor_h,
  round(lh.efetivo_h::numeric, 2)                                  as efetivo_h,
  round(lh.ocioso_h::numeric, 2)                                   as ocioso_h,
  round(lh.area_ha::numeric, 2)                                    as area_ha,
  round((lh.area_ha / nullif(lh.efetivo_h, 0))::numeric, 3)        as ha_h,
  round(lh.litros::numeric, 1)                                     as litros,
  round(lh.l_h::numeric, 2)                                        as l_h,
  round(med.mediana_l_h_modelo::numeric, 2)                        as mediana_l_h_modelo,
  round((100 * lh.ocioso_h / nullif(lh.motor_h, 0))::numeric, 1)   as ociosidade_pct,
  u.dias_uteis,
  round((100 * lh.motor_h / nullif(u.dias_uteis * public.sol_param('jornada_h'), 0))::numeric, 1) as aproveitamento_jornada_pct,
  u.dias_uteis_com_motor,
  greatest(u.dias_uteis - u.dias_uteis_com_motor, 0)               as dias_uteis_sem_motor,
  u.dias_uteis_motor_baixo,
  round(coalesce(lh.motor_fora_nucleo_h, 0)::numeric, 2)           as motor_fora_nucleo_h,
  coalesce(par.paradas_h, '{}'::jsonb)                             as paradas_h,
  -- alertas (limites em parametros)
  (100 * lh.ocioso_h / nullif(lh.motor_h, 0)) > public.sol_param('ociosidade_max_pct')          as alerta_ociosidade,
  (lh.l_h > med.mediana_l_h_modelo * (1 + public.sol_param('l_h_acima_mediana_pct') / 100))     as alerta_l_h
from lh
join uteis u on u.semana = lh.semana and u.maquina = lh.maquina
left join nuc on nuc.semana = lh.semana and nuc.maquina = lh.maquina
left join par on par.semana = lh.semana and par.maquina = lh.maquina
left join med on med.semana = lh.semana and med.modelo = lh.modelo;

-- 3. Operação por semana × 4 semanas anteriores --------------------------
create or replace view public.vw_operacao_semana as
with s as (
  select semana, cd_operacao, max(operacao) as operacao,
    sum(area_ha) as area_ha, sum(efetivo_h) as efetivo_h,
    count(distinct maquina) as maquinas
  from public.vw_sol_base
  where not fora and tipo = 'produtiva'
  group by 1, 2
)
select
  a.semana, a.cd_operacao, a.operacao, a.maquinas,
  round(a.area_ha::numeric, 2)                                   as area_ha,
  round(a.efetivo_h::numeric, 2)                                 as efetivo_h,
  round((a.area_ha / nullif(a.efetivo_h, 0))::numeric, 3)        as ha_h,
  round((p.area / nullif(p.ef, 0))::numeric, 3)                  as media_4sem_ha_h,
  round((100 * ((a.area_ha / nullif(a.efetivo_h, 0)) / nullif(p.area / nullif(p.ef, 0), 0) - 1))::numeric, 1) as variacao_pct,
  ((a.area_ha / nullif(a.efetivo_h, 0))
     < (p.area / nullif(p.ef, 0)) * (1 - public.sol_param('ha_h_queda_pct') / 100))       as alerta_ha_h
from s a
left join lateral (
  select sum(x.area_ha) as area, sum(x.efetivo_h) as ef
  from s x
  where x.cd_operacao = a.cd_operacao
    and x.semana between a.semana - 28 and a.semana - 7
) p on true;

-- 4. Fora de horário ou fora do núcleo -------------------------------------
create or replace view public.vw_fora_horario_semana as
select
  semana,
  dia_relogio                                  as dia,
  hora,
  maquina, max(maquina_nome) as maquina_nome,
  operador,
  talhao,
  nucleo,
  max(nucleo_habitual)                         as nucleo_habitual,
  concat_ws(' + ',
    case when hora >= public.sol_param('noite_inicio_h') or hora < public.sol_param('noite_fim_h') then 'noite' end,
    case when extract(isodow from dia_relogio) = 7 then 'domingo' end,
    case when max(nucleo_habitual) is not null and nucleo <> max(nucleo_habitual) then 'fora do núcleo' end
  )                                            as motivo,
  round(sum(motor_h)::numeric, 2)              as motor_h,
  round(sum(area_ha)::numeric, 2)              as area_ha
from public.vw_sol_base
where not fora and motor_h > 0
group by semana, dia_relogio, hora, maquina, operador, talhao, nucleo
having
     hora >= public.sol_param('noite_inicio_h') or hora < public.sol_param('noite_fim_h')
  or extract(isodow from dia_relogio) = 7
  or (max(nucleo_habitual) is not null and nucleo <> max(nucleo_habitual));

-- 5. Aplicação fora da faixa de velocidade/RPM ---------------------------
create or replace view public.vw_aplicacao_fora_faixa_semana as
select
  b.semana, b.nucleo, b.talhao, b.maquina, max(b.maquina_nome) as maquina_nome,
  b.operador, b.cd_operacao, max(b.operacao) as operacao,
  round(sum(b.tempo_h)::numeric, 2)  as horas_fora_faixa,
  round(sum(b.area_ha)::numeric, 2)  as area_fora_faixa_ha,
  round(avg(b.vel)::numeric, 2)      as vel_media,
  round(avg(b.rpm)::numeric, 0)      as rpm_medio,
  max(f.vel_min) as vel_min, max(f.vel_max) as vel_max,
  max(f.rpm_min) as rpm_min, max(f.rpm_max) as rpm_max
from public.vw_sol_base b
join public.faixas_operacao f on f.cd_operacao = b.cd_operacao
where not b.fora and b.tempo_h > 0
  and (   b.vel < f.vel_min or b.vel > f.vel_max
       or b.rpm < f.rpm_min or b.rpm > f.rpm_max)
group by b.semana, b.nucleo, b.talhao, b.maquina, b.operador, b.cd_operacao;

-- 6. Horímetro --------------------------------------------------------------
create or replace view public.vw_horimetro_atual as
with sem as (
  select (d - (extract(isodow from d)::int - 1)) as atual
  from (select (now() at time zone 'America/Sao_Paulo')::date as d) x
)
select
  b.maquina, max(b.maquina_nome) as maquina_nome, max(b.modelo) as modelo,
  max(b.nucleo_habitual) as nucleo_habitual,
  max(b.horimetro) as horimetro,
  max(b.data) filter (where b.horimetro is not null) as data_leitura,
  round(coalesce(sum(b.motor_h) filter (where b.semana = sem.atual), 0)::numeric, 2)     as motor_semana_atual_h,
  round(coalesce(sum(b.motor_h) filter (where b.semana = sem.atual - 7), 0)::numeric, 2) as motor_semana_anterior_h
from public.vw_sol_base b cross join sem
group by b.maquina, sem.atual;

-- 7. Frota por mês: máquina e modelo --------------------------------------
create or replace view public.vw_frota_mes as
with dia as (
  select mes, data, maquina, max(modelo) as modelo, max(grupo) as grupo,
    max(maquina_nome) as maquina_nome, sum(motor_h) as motor_h
  from public.vw_sol_base where not fora
  group by 1, 2, 3
),
maq as (
  select mes, maquina, max(maquina_nome) as maquina_nome, max(modelo) as modelo, max(grupo) as grupo,
    sum(motor_h) as motor_h, count(*) filter (where motor_h > 0.01) as dias_com_motor
  from dia group by 1, 2
),
uteis as (
  select mes, public.sol_dias_uteis(mes, (mes + interval '1 month - 1 day')::date) as dias_uteis
  from (select distinct mes from maq) m
),
pico as (
  select mes, modelo, max(n) as pico_mesmo_dia
  from (select mes, data, modelo, count(distinct maquina) filter (where motor_h > 0.01) as n
        from dia where modelo is not null group by 1, 2, 3) x
  group by 1, 2
),
frota as (
  select modelo, count(*) as maquinas_cadastradas
  from public.maquinas where tem_solinftec and modelo is not null group by 1
)
select 'maquina'::text as nivel, maq.mes, maq.maquina, maq.maquina_nome, maq.modelo, maq.grupo,
  round(maq.motor_h::numeric, 2) as motor_h, maq.dias_com_motor::int, u.dias_uteis,
  round((100 * maq.motor_h / nullif(u.dias_uteis * public.sol_param('jornada_h'), 0))::numeric, 1) as utilizacao_pct,
  null::int as maquinas_do_modelo, null::int as pico_mesmo_dia,
  (100 * maq.motor_h / nullif(u.dias_uteis * public.sol_param('jornada_h'), 0)) < public.sol_param('utilizacao_min_pct') as alerta_utilizacao
from maq join uteis u using (mes)
union all
select 'modelo', maq.mes, null, null, maq.modelo, max(maq.grupo),
  round(sum(maq.motor_h)::numeric, 2), sum(maq.dias_com_motor)::int, max(u.dias_uteis),
  round((100 * sum(maq.motor_h) / nullif(max(f.maquinas_cadastradas) * max(u.dias_uteis) * public.sol_param('jornada_h'), 0))::numeric, 1),
  max(f.maquinas_cadastradas)::int, max(p.pico_mesmo_dia)::int,
  null
from maq join uteis u using (mes)
left join frota f on f.modelo = maq.modelo
left join pico p on p.mes = maq.mes and p.modelo = maq.modelo
where maq.modelo is not null
group by maq.mes, maq.modelo;

-- 8. Operador por mês (por código; nome fica no cadastro trancado) --------
create or replace view public.vw_operador_mes as
with b as (
  select * from public.vw_sol_base where not fora and operador is not null and operador not in ('0', '-1')
),
op as (  -- totais do operador no mês
  select mes, operador,
    sum(motor_h) as motor_h, sum(efetivo_h) as efetivo_h, sum(ocioso_h) as ocioso_h,
    sum(tempo_h) filter (where tipo = 'parada' and na_jornada) as paradas_h,
    count(distinct data) as dias_trabalhados
  from b group by 1, 2
),
ff as (  -- tempo fora da faixa (vazio até existir faixa)
  select b.mes, b.operador, sum(b.tempo_h) as fora_faixa_h
  from b join public.faixas_operacao f on f.cd_operacao = b.cd_operacao
  where b.vel < f.vel_min or b.vel > f.vel_max or b.rpm < f.rpm_min or b.rpm > f.rpm_max
  group by 1, 2
),
oper as (  -- por operação produtiva
  select mes, operador, cd_operacao, max(operacao) as operacao,
    sum(area_ha) as area_ha, sum(efetivo_h) as efetivo_h
  from b where tipo = 'produtiva' group by 1, 2, 3
),
media as (  -- média do grupo inteiro na operação, no mês
  select mes, cd_operacao, sum(area_ha) / nullif(sum(efetivo_h), 0) as ha_h
  from b where tipo = 'produtiva' group by 1, 2
)
select
  op.mes, op.operador,
  round(op.motor_h::numeric, 2)    as motor_h,
  round(op.efetivo_h::numeric, 2)  as efetivo_h,
  round(op.ocioso_h::numeric, 2)   as ocioso_h,
  op.dias_trabalhados,
  round((100 * op.motor_h / nullif(op.dias_trabalhados * public.sol_param('jornada_h'), 0))::numeric, 1) as aproveitamento_jornada_pct,
  round(coalesce(op.paradas_h, 0)::numeric, 2)   as paradas_h,
  round(coalesce(ff.fora_faixa_h, 0)::numeric, 2) as fora_faixa_h,
  o.cd_operacao, o.operacao,
  round(o.area_ha::numeric, 2)                              as operacao_area_ha,
  round(o.efetivo_h::numeric, 2)                            as operacao_efetivo_h,
  round((o.area_ha / nullif(o.efetivo_h, 0))::numeric, 3)   as operacao_ha_h,
  round(m.ha_h::numeric, 3)                                 as operacao_media_grupo_ha_h
from op
left join ff on ff.mes = op.mes and ff.operador = op.operador
left join oper o on o.mes = op.mes and o.operador = op.operador
left join media m on m.mes = o.mes and m.cd_operacao = o.cd_operacao;

-- 9. Talhão por mês (base do custo por talhão) ------------------------------
create or replace view public.vw_talhao_mes as
with t as (
  select b.mes, b.nucleo, b.talhao, b.maquina, max(b.maquina_nome) as maquina_nome,
    max(b.modelo) as modelo, max(b.grupo) as grupo,
    sum(b.motor_h) as motor_h, sum(b.area_ha) as area_ha, sum(b.litros) as litros,
    sum(b.litros * tx.rs_por_litro) as rs_manutencao
  from public.vw_sol_base b
  left join public.taxa_manutencao tx on tx.grupo = b.grupo and b.data between tx.inicio and tx.fim
  where not b.fora and coalesce(b.talhao, '') <> ''
  group by b.mes, b.nucleo, b.talhao, b.maquina
),
tal as (  -- R$/ha do talhão no mês (todas as máquinas)
  select mes, nucleo, talhao, sum(rs_manutencao) / nullif(sum(area_ha), 0) as rs_ha
  from t group by 1, 2, 3
),
med as (
  select mes, nucleo, percentile_cont(0.5) within group (order by rs_ha) as mediana_rs_ha
  from tal where rs_ha > 0 group by 1, 2
)
select
  t.mes, t.nucleo, t.talhao, t.maquina, t.maquina_nome, t.modelo, t.grupo,
  round(t.motor_h::numeric, 2)        as motor_h,
  round(t.area_ha::numeric, 2)        as area_ha,
  round(t.litros::numeric, 1)         as litros,
  round(t.rs_manutencao::numeric, 2)  as rs_manutencao_estimado,  -- vazio se faltar a taxa do trimestre
  round(tal.rs_ha::numeric, 2)        as talhao_rs_ha,
  round(med.mediana_rs_ha::numeric, 2) as nucleo_mediana_rs_ha,
  tal.rs_ha > med.mediana_rs_ha * public.sol_param('rs_ha_multiplo_mediana') as alerta_rs_ha
from t
join tal on tal.mes = t.mes and tal.nucleo = t.nucleo and tal.talhao = t.talhao
left join med on med.mes = t.mes and med.nucleo = t.nucleo;

-- Leitura pela chave pública: SÓ as visões agregadas. ----------------------
grant select on
  public.vw_status_robo, public.vw_maquinas_semana, public.vw_operacao_semana,
  public.vw_fora_horario_semana, public.vw_aplicacao_fora_faixa_semana,
  public.vw_horimetro_atual, public.vw_frota_mes, public.vw_operador_mes,
  public.vw_talhao_mes
to anon, authenticated;
revoke all on public.vw_sol_base from anon, authenticated;

-- Conferência (aparece no fim): horas de motor de 06 a 09/10/2026,
-- todas as máquinas — o site deu 483 h.
select round(sum(motor_h)::numeric, 1) as motor_h_06_a_09_10
from public.vw_sol_base
where data between '2026-10-06' and '2026-10-09';
