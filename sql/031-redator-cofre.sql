-- Robô-redator — chave da API da Claude no cofre (v57)
-- Rodar no SQL Editor do Supabase DEPOIS do sql/030-redator.sql.
--
-- É UMA LINHA SÓ. Troque COLE_AQUI (entre as aspas simples, no fim da linha)
-- pela chave da API da Anthropic, que começa com sk-ant- . Não apague as aspas.
-- A chave fica SÓ na tabela segredos, trancada (RLS sem policy de leitura):
-- nunca no código do app, nunca neste arquivo do repositório, nunca no
-- WhatsApp. Só a função redator_chave() (security definer) lê a linha,
-- dentro do Supabase. Para trocar a chave depois, rode a mesma linha de novo.

select public.redator_gravar_chave('COLE_AQUI');

-- Resposta esperada: "chave gravada (NN caracteres, termina em …xxxx)".
-- Se aparecer "nada gravado", o COLE_AQUI não foi trocado.
-- Conferência SEM mostrar a chave:
--   select (public.redator_chave() is not null) as chave_ok;
