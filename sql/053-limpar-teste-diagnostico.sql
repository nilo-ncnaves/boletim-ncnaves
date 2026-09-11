-- Apagar os registros do teste de diagnóstico de 11/09/2026
-- Rodar no SQL Editor do Supabase (projeto syvehtgrbqteyuqhoban).
--
-- PASSO A PASSO (pelo iPhone):
--   1. Abra o Supabase e entre no projeto do Boletim.
--   2. Toque em "SQL Editor" e em "New query".
--   3. Selecione TODO o texto deste arquivo, copie e cole na caixa.
--   4. Toque em "Run". No fim aparece quantas linhas saíram.
--
-- O QUE É: para descobrir se o banco estava aceitando gravação (e não era
-- política de acesso, campo obrigatório ou unidade inexistente), foi
-- gravado UM registro de teste em cada uma das três tabelas de escrita do
-- app, todos marcados com o texto TESTE-DIAGNOSTICO. As três gravações
-- responderam HTTP 201 (aceito) — ou seja, o banco estava recebendo
-- normalmente. Este arquivo apaga esses três registros e nada mais.
--
-- SEGURANÇA: os delete abaixo são por id EXATO. Nenhum boletim de verdade
-- é tocado. Pode rodar de novo: na segunda vez apaga 0 linhas.

with b as (delete from public.boletins      where id = 'TESTE-DIAGNOSTICO-1' returning 1),
     p as (delete from public.pos_colheitas where id = 'TESTE-DIAGNOSTICO-p' returning 1),
     t as (delete from public.telemetria    where id = 'TESTE-DIAGNOSTICO-t' returning 1)
select (select count(*) from b) as boletins_apagados,
       (select count(*) from p) as pos_colheitas_apagadas,
       (select count(*) from t) as telemetria_apagada;

-- conferência: não pode sobrar nada com esse nome
select 'sobrou em boletins'      as onde, count(*) from public.boletins      where id like 'TESTE-DIAGNOSTICO%'
union all
select 'sobrou em pos_colheitas', count(*) from public.pos_colheitas where id like 'TESTE-DIAGNOSTICO%'
union all
select 'sobrou em telemetria',    count(*) from public.telemetria    where id like 'TESTE-DIAGNOSTICO%';
