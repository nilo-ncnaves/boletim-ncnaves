-- Robô-redator — chave da API da Claude no cofre (v57)
-- Rodar no SQL Editor do Supabase DEPOIS do sql/030-redator.sql.
--
-- ANTES DE RODAR (1 minuto):
--   Troque o texto COLE_AQUI pela chave da API da Anthropic (começa com
--   "sk-ant-"). A chave fica SÓ na tabela segredos, trancada (RLS sem
--   policy de leitura): nunca no código do app, nunca neste arquivo do
--   repositório, nunca no WhatsApp. Só a função redator_chave() (security
--   definer) lê a linha, dentro do Supabase.
--
-- A tabela segredos já existe (é onde vive o token da iCrop). Ela pode ter
-- as colunas chave/valor ou nome/valor — este arquivo descobre sozinho.
-- Para conferir a estrutura antes:
--   select column_name from information_schema.columns where table_name = 'segredos';

do $$
declare c_chave text; c_valor text;
begin
  select column_name into c_chave from information_schema.columns
    where table_schema = 'public' and table_name = 'segredos' and column_name in ('chave', 'nome', 'id')
    order by array_position(array['chave', 'nome', 'id'], column_name::text) limit 1;
  select column_name into c_valor from information_schema.columns
    where table_schema = 'public' and table_name = 'segredos' and column_name in ('valor', 'token', 'value')
    order by array_position(array['valor', 'token', 'value'], column_name::text) limit 1;
  if c_chave is null or c_valor is null then
    raise exception 'tabela segredos não encontrada ou sem colunas chave/valor — confira a estrutura (consulta no cabeçalho)';
  end if;
  execute format('insert into public.segredos (%I, %I) values (%L, %L) on conflict (%I) do update set %I = excluded.%I',
    c_chave, c_valor, 'anthropic_key', 'COLE_AQUI', c_chave, c_valor, c_valor);   -- <<< trocar COLE_AQUI pela chave sk-ant-...
end $$;

-- Garantia: a tabela continua trancada (RLS ligado e sem policy de leitura).
alter table public.segredos enable row level security;

-- Conferência SEM mostrar a chave (só diz se está gravada):
--   select (public.redator_chave() is not null) as chave_ok;
-- Se aparecer "chave da API ainda não gravada", o COLE_AQUI não foi trocado.
