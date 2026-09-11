-- Carimbo de "este aparelho sincronizou" (v82)
-- Objeto: aparelho_sync (uma linha por aparelho). Rodar no SQL Editor do
-- Supabase (projeto syvehtgrbqteyuqhoban).
--
-- PASSO A PASSO (pelo iPhone):
--   1. Abra o Supabase e entre no projeto do Boletim.
--   2. Toque em "SQL Editor" e em "New query".
--   3. Selecione TODO o texto deste arquivo, copie e cole na caixa.
--   4. Toque em "Run".
--   5. No fim aparece uma tabelinha de conferência. Pode rodar de novo
--      quantas vezes quiser: nada duplica e nada se apaga.
--
-- POR QUE EXISTE: no dia 11/09/2026 nenhum boletim de gerente chegou ao
-- banco e o escritório não tinha como distinguir as duas causas possíveis
-- — "o gerente não preencheu" e "preencheu, mas o boletim ficou guardado
-- no celular sem sinal". Esta tabela guarda, por aparelho, a última vez
-- que ele conversou com o banco, em que versão do app ele está e quantos
-- registros ainda esperam na fila dele. Com isso o cartão "📡 Chegada dos
-- boletins hoje" (painel da Diretoria/ADMIN) responde a pergunta.
--
-- O QUE ELA NÃO É: não é rastreamento de pessoa. Não guarda nome, telefone,
-- localização nem nada digitado. O id é um número aleatório criado pelo
-- próprio aparelho na primeira sincronização; a unidade é a que está aberta
-- no momento. Ninguém aparece para ninguém: as telas listam UNIDADES.
--
-- ENQUANTO NÃO RODAR: o app funciona exatamente como antes. A gravação do
-- carimbo vai DIRETO (fora da fila offline), de propósito — se fosse pela
-- fila, a tabela ausente devolveria 404 e o item ficaria preso para sempre
-- acusando "aguardando internet" (foi o que aconteceu com codigos_acesso).
-- Sem a tabela, o carimbo falha em silêncio e o cartão do painel mostra só
-- a hora de chegada do boletim.

create table if not exists public.aparelho_sync (
  id          text primary key,                 -- id aleatório do aparelho (bdf:aparelho)
  unidade_id  text,                             -- unidade aberta no aparelho (fazendas.id do app)
  chave       text,                             -- escopo do código de acesso em uso (ADMIN, f22c, ATV:CAFE…)
  versao      text,                             -- versão do app no aparelho (ex.: v82)
  na_fila     integer default 0,                -- registros ainda esperando envio naquele aparelho
  visto_em    timestamptz not null default now(),
  atualizado  timestamptz not null default now()
);

comment on table public.aparelho_sync is
  'v82 — última sincronização por aparelho. Serve ao cartão "Chegada dos boletins hoje". Não guarda dado pessoal.';

create index if not exists aparelho_sync_unidade_idx on public.aparelho_sync (unidade_id, visto_em desc);

-- carimbo de atualização
create or replace function public.aparelho_sync_touch() returns trigger language plpgsql as $$
begin new.atualizado := now(); return new; end $$;

drop trigger if exists aparelho_sync_touch on public.aparelho_sync;
create trigger aparelho_sync_touch before insert or update on public.aparelho_sync
  for each row execute function public.aparelho_sync_touch();

-- Mesma política das demais tabelas do app: a chave publishable escreve e lê.
-- É fechadura de porta, não cofre (ver ESTADO.md, "Limitação conhecida").
alter table public.aparelho_sync enable row level security;

drop policy if exists aparelho_sync_ler on public.aparelho_sync;
create policy aparelho_sync_ler on public.aparelho_sync for select using (true);

drop policy if exists aparelho_sync_gravar on public.aparelho_sync;
create policy aparelho_sync_gravar on public.aparelho_sync for insert with check (true);

drop policy if exists aparelho_sync_atualizar on public.aparelho_sync;
create policy aparelho_sync_atualizar on public.aparelho_sync for update using (true) with check (true);

-- conferência
select 'aparelho_sync criada' as passo,
       count(*) as aparelhos_registrados,
       max(visto_em) as ultima_sincronizacao
from public.aparelho_sync;
