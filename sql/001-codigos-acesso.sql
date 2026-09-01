-- Códigos de acesso do Boletim NCNaves (v43)
-- Rodar no SQL Editor do Supabase (projeto syvehtgrbqteyuqhoban).
-- O app lê esta tabela a cada sincronização e na tela de código;
-- quando o admin gera um código novo em Cadastros, o app grava aqui
-- e o código antigo deixa de valer nos outros aparelhos.
-- Sem internet, o aparelho usa a última cópia baixada (ou os códigos
-- de fábrica do app).

create table if not exists public.codigos_acesso (
  chave text primary key,            -- id da unidade (f01, f22g, …) ou DIRETORIA / ADMIN
  codigo text not null,              -- código curto no formato XX-NNNN
  atualizado_em timestamptz not null default now()
);

comment on table public.codigos_acesso is
  'Código de acesso por unidade do Boletim NCNaves. chave = id da fazenda no app, ou DIRETORIA / ADMIN.';

alter table public.codigos_acesso enable row level security;

-- Mesmo modelo de confiança das demais tabelas do app: a chave
-- publishable lê e grava (o controle fino é feito pelo próprio app).
create policy "codigos_acesso leitura" on public.codigos_acesso
  for select using (true);
create policy "codigos_acesso insercao" on public.codigos_acesso
  for insert with check (true);
create policy "codigos_acesso atualizacao" on public.codigos_acesso
  for update using (true) with check (true);

-- Carga inicial: os mesmos códigos de fábrica do app (CODIGOS_PADRAO
-- no index.html). "on conflict do nothing" preserva códigos que o
-- admin já tiver trocado.
insert into public.codigos_acesso (chave, codigo) values
  ('f01',  'AL-4172'),  -- Água Limpa (café)
  ('f03c', 'RC-8305'),  -- Rio Preto-Lagamar — Café
  ('f03g', 'RG-2657'),  -- Rio Preto-Lagamar — Grãos
  ('f13c', 'MC-7914'),  -- Mata Preta — Café
  ('f13p', 'MP-3548'),  -- Mata Preta — Pecuária
  ('f14c', 'CC-6081'),  -- Monte Carmelo — Café
  ('f14p', 'CP-1739'),  -- Monte Carmelo — Pecuária
  ('f20',  'LR-8447'),  -- Lagamar Café (Rodrigo)
  ('f21',  'SF-9426'),  -- São Félix — Arrendamento
  ('f22c', 'VC-5883'),  -- Vereda — Café
  ('f22g', 'VG-2496'),  -- Vereda — Grãos
  ('f23',  'VR-7061'),  -- Vereda Romaria
  ('f24',  'VQ-3215'),  -- Vereda Café 5º e 6º
  ('f25',  'NC-1690'),  -- NC Naves — Armazém Geral
  ('f26',  'AS-6754'),  -- Água Santa
  ('f27',  'CG-5372'),  -- Capoeira Grande
  ('f28',  'CH-2381'),  -- Chapada
  ('f29',  'CD-8196'),  -- Chapadão
  ('f30',  'CF-3907'),  -- Confins
  ('f31',  'CR-5240'),  -- Cra Cra
  ('f32',  'FE-7623'),  -- Ferragem
  ('f33',  'FM-9028'),  -- Floramill
  ('f34',  'GA-1058'),  -- Gameleira
  ('f35',  'PB-4519'),  -- Porto Buriti
  ('DIRETORIA', 'LG-9351'),
  ('ADMIN',     'AD-4786')
on conflict (chave) do nothing;
