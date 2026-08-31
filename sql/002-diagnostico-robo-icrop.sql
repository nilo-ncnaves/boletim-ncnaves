-- ============================================================
-- 002 — Diagnóstico do robô iCrop (colar no SQL Editor do Supabase)
-- Contexto: o painel avisou "Robô iCrop sem dados novos" e o vigia
-- apontou "robô/token". Rode os blocos NA ORDEM, um de cada vez.
-- ============================================================

-- ------------------------------------------------------------
-- BLOCO 1 — O que a iCrop respondeu nas últimas chamadas?
-- Mostra o código de status e o começo do conteúdo das últimas
-- respostas guardadas pelo pg_net.
--   status_code 200 = iCrop respondeu bem (o problema é outro:
--     leia o inicio_do_conteudo para ver se veio lista vazia).
--   status_code 401 ou 403 = token vencido/inválido → BLOCO 2.
--   status_code 5xx ou timed_out = iCrop fora do ar → tentar
--     de novo mais tarde (BLOCO 3).
--   Nenhuma linha recente = o pg_cron não está disparando →
--     conferir em cron.job / cron.job_run_details (BLOCO 1b).
-- ------------------------------------------------------------
select id,
       created,
       status_code,
       timed_out,
       error_msg,
       left(content::text, 300) as inicio_do_conteudo
from net._http_response
order by id desc
limit 10;

-- BLOCO 1b (opcional) — o agendador rodou nas últimas madrugadas?
select jobid, jobname, schedule, active
from cron.job;

select j.jobname, d.status, d.return_message, d.start_time
from cron.job_run_details d
join cron.job j on j.jobid = d.jobid
order by d.start_time desc
limit 15;

-- ------------------------------------------------------------
-- BLOCO 2 — Trocar o token (SÓ se o Bloco 1 mostrou 401/403).
-- Pegue o token novo na Vision/iCrop, troque TOKEN_NOVO abaixo
-- e tire o "--" do começo da linha antes de rodar.
-- ------------------------------------------------------------
-- update segredos set valor = 'TOKEN_NOVO' where chave = 'icrop_token';

-- Conferir que gravou (mostra só o tamanho, nunca o token inteiro):
select chave, length(valor) as tamanho, char_length(valor) > 10 as parece_ok
from segredos
where chave = 'icrop_token';

-- ------------------------------------------------------------
-- BLOCO 3 — Rerodar o robô agora, sem esperar a madrugada.
-- Primeiro confirme os nomes exatos das funções do robô:
-- ------------------------------------------------------------
select proname as funcao_do_robo
from pg_proc
where proname like 'icrop%'
order by proname;

-- Depois rode UMA CHAMADA DE CADA VEZ, aguardando 20 a 30 segundos
-- entre uma e outra (o pg_net busca na iCrop em segundo plano; sem
-- a pausa, o passo seguinte roda antes de o anterior terminar).
-- Se algum nome for diferente do listado acima, use o nome certo.

select icrop_passo1_parcelas();
-- ... aguarde 20-30 segundos ...

select icrop_passo2_manejo();
-- ... aguarde 20-30 segundos ...

select icrop_passo3_gravar();
-- ... aguarde 20-30 segundos ...

-- ------------------------------------------------------------
-- BLOCO 4 — Conferir se voltou a gravar dado novo.
-- Esperado: primeira linha com data de ontem ou de hoje.
-- Depois abra o painel do app e toque em "Atualizar".
-- ------------------------------------------------------------
select data, fazenda, count(*) as linhas, max(atualizado_em) as gravado_em
from icrop_manejo
group by data, fazenda
order by data desc
limit 10;
