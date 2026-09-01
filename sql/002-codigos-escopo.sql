-- Códigos de acesso com escopo por atividade (v46)
-- Rodar no SQL Editor do Supabase (projeto syvehtgrbqteyuqhoban),
-- DEPOIS do sql/001-codigos-acesso.sql (que cria a tabela).
-- Se o 001 ainda não foi rodado, rode o 001 primeiro e este em seguida.
--
-- O que este bloco faz:
-- 1. Insere as chaves novas de escopo por atividade e combinados
--    (ATV:…). "do nothing" preserva códigos que o admin já trocar.
-- 2. Troca DIRETORIA e ADMIN para o formato novo (DIRETORIA-NNNN /
--    ADMIN-NNNN) — mas SÓ se ainda estiverem com o código de fábrica
--    antigo (LG-9351 / AD-4786); código já trocado pelo admin fica.
-- Os códigos por unidade (XX-NNNN) não mudam.

insert into public.codigos_acesso (chave, codigo) values
  ('ATV:CAFE',           'CAFE-2740'),   -- todas as unidades de café
  ('ATV:GRAOS',          'GRAOS-3815'),  -- todas as unidades de grãos
  ('ATV:PECUARIA',       'PECU-5926'),   -- todas as unidades de pecuária
  ('ATV:CAFE+GRAOS',     'CAFEGRAOS-4157'),  -- café + grãos
  ('ATV:CAFE+PECUARIA',  'CAFEPECU-6283'),   -- café + pecuária (uso futuro)
  ('ATV:GRAOS+PECUARIA', 'GRAOSPECU-7492')   -- grãos + pecuária (uso futuro)
on conflict (chave) do nothing;

insert into public.codigos_acesso (chave, codigo) values
  ('DIRETORIA', 'DIRETORIA-8034'),
  ('ADMIN',     'ADMIN-9561')
on conflict (chave) do update
  set codigo = excluded.codigo, atualizado_em = now()
  where codigos_acesso.codigo in ('LG-9351', 'AD-4786');

comment on table public.codigos_acesso is
  'Código de acesso por escopo do Boletim NCNaves. chave = id da unidade (f01, f22g, …), ATV:<atividades> (escopo por atividade), MIX:<atividades>:<unidades> (combinado criado em Cadastros), DIRETORIA ou ADMIN.';
