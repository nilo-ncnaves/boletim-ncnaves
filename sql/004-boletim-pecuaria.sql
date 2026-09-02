-- Pecuária do Boletim NCNaves (v50)
-- Rodar no SQL Editor do Supabase (projeto syvehtgrbqteyuqhoban).
--
-- O que é: cópia da parte de pecuária de cada boletim em tabela
-- própria, para alimentar o estoque de rebanho e o custeio no ERP
-- AgroGestão sem precisar abrir o payload gigante de "boletins".
-- O app continua gravando o boletim completo (pecuária dentro) na
-- tabela boletins — esta aqui é um espelho enviado junto, pela mesma
-- fila offline (item t:"pec" no syncFila do index.html).
-- Enquanto este SQL não rodar, o envio do espelho falha em silêncio e
-- fica na fila; o boletim em si continua subindo normalmente.

create table if not exists public.boletim_pecuaria (
  id text primary key,               -- MESMO id do boletim na tabela boletins
  fazenda_id text not null,          -- id da unidade no app (f26, f28, …)
  data date not null,
  responsavel text,                  -- quem preencheu (nome digitado no boletim)
  payload jsonb not null,            -- o bloco pecuária inteiro do boletim
  atualizado_em timestamptz not null default now()
);

comment on table public.boletim_pecuaria is
  'Espelho da seção de pecuária de cada boletim (Boletim NCNaves v50). payload = objeto pecuaria do boletim: mov (movimentação), san (sanidade), massa (vacinação/vermifugação em massa), rep (reprodução), nut (cocho por pasto), pasto (condição/cerca/visitas), lotes (contagem), eventos (outros manejos), cocho/sal/agua (resumo rápido), obs.';

create index if not exists boletim_pecuaria_fazenda_data
  on public.boletim_pecuaria (fazenda_id, data);

alter table public.boletim_pecuaria enable row level security;

-- Mesmo modelo de confiança das demais tabelas do app: a chave
-- publishable lê e grava (o controle fino é feito pelo próprio app).
create policy "boletim_pecuaria leitura" on public.boletim_pecuaria
  for select using (true);
create policy "boletim_pecuaria insercao" on public.boletim_pecuaria
  for insert with check (true);
create policy "boletim_pecuaria atualizacao" on public.boletim_pecuaria
  for update using (true) with check (true);

-- Gatilho simples para manter atualizado_em em dia nas correções
-- (o app reenvia o mesmo id quando o gerente corrige o boletim).
create or replace function public.boletim_pecuaria_toque()
returns trigger language plpgsql as $$
begin
  new.atualizado_em := now();
  return new;
end $$;
drop trigger if exists boletim_pecuaria_toque on public.boletim_pecuaria;
create trigger boletim_pecuaria_toque
  before update on public.boletim_pecuaria
  for each row execute function public.boletim_pecuaria_toque();

-- ---------------------------------------------------------------
-- Visão pronta para o ERP / conferência: um movimento por linha
-- (nascimento, morte, desmama, mudança, entrada, saída), já com os
-- campos abertos. Consulta exemplo:
--   select * from pecuaria_movimentos where data >= current_date - 7;
-- ---------------------------------------------------------------
create or replace view public.pecuaria_movimentos as
select
  b.id            as boletim_id,
  b.fazenda_id,
  b.data,
  b.responsavel,
  m.value->>'tipo'        as tipo,        -- Nascimento / Morte / Desmama / Mudança de pasto / Entrada / Saída
  m.value->>'categoria'   as categoria,   -- bezerro(a) mamando … touro
  nullif(m.value->>'qtd','')::numeric as qtd,
  m.value->>'modo'        as modo,        -- compra/venda/abate/transferência (entrada e saída)
  m.value->>'parto'       as parto,       -- nascimento
  m.value->>'sexo'        as sexo,        -- nascimento
  m.value->>'causa'       as causa,       -- morte
  m.value->>'brinco'      as brinco,
  m.value->>'pastoDe'     as pasto_origem_id,   -- id do talhão/pasto no app
  m.value->>'pastoPara'   as pasto_destino_id,
  m.value->>'contraparte' as contraparte, -- vendedor/comprador/fazenda
  m.value->>'obs'         as obs
from public.boletim_pecuaria b
cross join lateral jsonb_array_elements(coalesce(b.payload->'mov','[]'::jsonb)) m
where m.value->>'tipo' is not null and m.value->>'tipo' <> '';
