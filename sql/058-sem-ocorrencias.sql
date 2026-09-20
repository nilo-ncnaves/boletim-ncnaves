-- ====================================================================
-- 058 — Boletim sem a seção "Ocorrências" (acidente e ocorrências)  ·  v101
-- ====================================================================
-- Objeto: boletim_secao (catálogo das seções do boletim, sql/047).
-- Rodar no SQL Editor do Supabase (projeto syvehtgrbqteyuqhoban).
--
-- PASSO A PASSO (pelo iPhone):
--   1. Abra o Supabase e entre no projeto do Boletim.
--   2. Toque em "SQL Editor" e em "New query".
--   3. Selecione TODO o texto deste arquivo, copie e cole na caixa.
--   4. Toque em "Run".
--   5. No fim aparece uma tabelinha de conferência. Pode rodar de novo
--      quantas vezes quiser: nada duplica e nada se apaga.
--
-- O QUE É. Por decisão do Nilo (20/09/2026), o app deixou de oferecer o
-- registro de "Ocorrências" (acidente de trabalho, quebra de equipamento,
-- dano climático, visita técnica, recebimento de insumos, e as listas de
-- grãos e pecuária). O catálogo do app (SECOES_BOLETIM) não tem mais as
-- seções CAFE-OCOR e PEC-OCOR, e a seção dos grãos GRAOS-FITO_OCOR passou a
-- ser só "Pragas, doenças e daninhas" (campo fito). Este arquivo faz o
-- espelho no banco, pela regra de sempre: nada se apaga.
--
--   • CAFE-OCOR e PEC-OCOR ficam com ativo = false. A visão
--     vw_completude_boletim e o gatilho de boletim_secao_resposta só olham
--     seções ativas, então essas duas param de contar como "sem resposta"
--     nos boletins novos — e as respostas já gravadas continuam na tabela.
--   • GRAOS-FITO_OCOR mantém o id (chave substituta, gravada em
--     payload.secoes dos boletins que já subiram) e troca só o nome e os
--     campos que contam como registro.
--
-- Boletins antigos com payload.ocorrencias NÃO são tocados: continuam
-- legíveis no app (boletim enviado, WhatsApp, CSV, alertas). Se um dia o
-- Nilo quiser apagar esse histórico, é outra decisão e outro arquivo.

update public.boletim_secao
   set ativo = false
 where id in ('CAFE-OCOR', 'PEC-OCOR');

update public.boletim_secao
   set nome   = 'Pragas, doenças e daninhas',
       campos = '{fito}'
 where id = 'GRAOS-FITO_OCOR';

-- Conferência: as três linhas como devem ficar.
select id, atividade, nome, tipo, campos, ativo
  from public.boletim_secao
 where id in ('CAFE-OCOR', 'PEC-OCOR', 'GRAOS-FITO_OCOR')
 order by id;
