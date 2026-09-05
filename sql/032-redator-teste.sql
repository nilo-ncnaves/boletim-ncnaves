-- Robô-redator — disparo manual de teste e conferência (v57)
-- Rodar no SQL Editor DEPOIS do sql/030 e do sql/031 (chave gravada).
-- Cada bloco é independente. Custo de um disparo: ~3 mil tokens de entrada
-- e ~300 de saída (centavos de dólar).

-- 0. Pré-requisito: a fase 1 já gerou os números da semana (senão a devolutiva
--    sai vazia). Se precisar, gere agora:
-- select public.rel_farol(7); select public.rel_dito_medido_icrop(public.rel_hoje_brt() - 7, public.rel_hoje_brt() - 1);
-- select public.rel_dito_medido_solinftec(public.rel_hoje_brt() - 7, public.rel_hoje_brt() - 1);

-- 1. Dispara UMA devolutiva de teste (Floramill, últimos 7 dias até ontem).
--    Devolve o req_id do pedido.
select public.redigir_relatorio('devolutiva_semanal', public.rel_hoje_brt() - 7, public.rel_hoje_brt() - 1, 'f33');

-- 2. Espere 20 a 60 segundos e colha (pode repetir até o status virar "ok").
select public.redator_colher();

-- 3. Situação do pedido (status enviado → ok/erro; tokens gastos)
select req_id, relatorio, unidade_id, status, erro, tokens_in, tokens_out, criado_em, colhido_em
from public.relatorios_reqs order by criado_em desc limit 10;

-- 4. O texto gerado (o app mostra este mesmo texto acima dos números)
select relatorio, unidade_id, periodo_ini, periodo_fim, texto_em, texto_modelo, texto
from public.relatorios_gerados
where texto is not null order by texto_em desc limit 5;

-- 5. Painel executivo de teste (mês anterior fechado, linha do grupo) — só depois
--    de o dia 1 ter gerado custo/rebanho/plano do mês:
-- select public.redigir_relatorio('painel_executivo',
--   (date_trunc('month', public.rel_hoje_brt()) - interval '1 month')::date,
--   (date_trunc('month', public.rel_hoje_brt()) - interval '1 day')::date, null);
-- (espere 1 minuto) select public.redator_colher();

-- 6. Alerta de divergência de teste (uma unidade, o dia de ontem)
-- select public.redigir_relatorio('alerta_divergencia', public.rel_hoje_brt() - 1, public.rel_hoje_brt() - 1, 'f33');

-- 7. A rodada inteira como o pg_cron faz na sexta (24 pedidos de uma vez):
-- select public.redator_disparar('semana');   -- e, 15 min depois: select public.redator_rodar_colheita();

-- 8. Diário de bordo (falhas aparecem aqui com o motivo)
select relatorio, periodo_ini, periodo_fim, ok, erro, quando
from public.relatorios_execucoes where relatorio like 'redator%' or relatorio like 'devolutiva%' or relatorio like 'painel%'
order by quando desc limit 20;

-- 9. Se um pedido ficou "erro" com HTTP 401/403: a chave em segredos está errada
--    (rodar sql/031 de novo). HTTP 429: limite de taxa — repetir mais tarde.
--    "perdido": a resposta não chegou em 6 h (pg_net expira) — disparar de novo.
