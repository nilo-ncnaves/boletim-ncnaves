-- ====================================================================
-- 054 — Módulo de insumos: remessa programada e recebimento  ·  v86
-- ====================================================================
-- Objetos: insumo_remessa, insumo_recebimento e a visão vw_insumo_saldo
-- (leitura). Rodar no SQL Editor do Supabase (projeto syvehtgrbqteyuqhoban).
--
-- PASSO A PASSO (pelo iPhone):
--   1. Abra o Supabase e entre no projeto do Boletim.
--   2. Toque em "SQL Editor" e em "New query".
--   3. Selecione TODO o texto deste arquivo, copie e cole na caixa.
--   4. Toque em "Run".
--   5. No fim aparece uma tabelinha de conferência. Pode rodar de novo
--      quantas vezes quiser: nada duplica e nada se apaga.
--
-- O QUE É. A entrega de fertilizante é anunciada numa mensagem do WhatsApp
-- ("Relação de NITRATO que a Cooxupé vai entregar nas fazendas: 106.000 kg
-- - VEREDA…"). O app transforma a mensagem em uma REMESSA (produto +
-- fornecedor + a lista de alocações por unidade) e cada chegada confirmada
-- pelo gerente vira um RECEBIMENTO. Entrega parcial é só outra linha de
-- recebimento: nada é sobrescrito.
--
--   • insumo_remessa      = o anúncio (programação), com as alocações no payload.
--   • insumo_recebimento  = uma chegada confirmada por um gerente, com quantidade,
--                           data, nº da nota (opcional) e quem conferiu.
--   • vw_insumo_saldo     = programado × recebido por unidade e produto (leitura).
--
-- SALDO É CALCULADO, NUNCA DIGITADO. O "aplicado" NÃO entra nesta visão de
-- propósito: quem sabe transformar o lançamento do boletim em quilos é o app
-- (produto × dose × área, com o de-para de produtos que mora no index.html).
-- O relatório mensal que junta os três números está no sql/056.
--
-- COMO O DADO CHEGA: o app grava tudo no aparelho (offline first) e a fila de
-- sincronização sobe cada registro por id, do mesmo jeito que já faz com
-- boletins, pós-colheita, remessas de café e planejamento. O app também LÊ
-- estas tabelas a cada sincronização, então a remessa importada no escritório
-- aparece no celular do gerente e a chegada confirmada por ele aparece no
-- painel da Diretoria.
--
-- ENQUANTO NÃO RODAR: o módulo funciona INTEIRO no aparelho de quem digitou —
-- só não sincroniza entre celulares. Uma remessa criada fica na fila (o aviso
-- "N registro(s) aguardando internet" aparece até o SQL rodar, e aí tudo sobe
-- sozinho; nada se perde).
--
-- VOCABULÁRIO (regra permanente do projeto): as telas relatam CHEGADA e
-- REGISTRO — nunca "não fez", "pendente", "atrasado". Divergência entre
-- programado e recebido é assunto do escritório, nunca cobrança do campo.
--
-- SEGURANÇA: leitura e escrita anon por policy, como as demais tabelas que o
-- app alimenta (a autorização real é o escopo do código de acesso; ver
-- CLAUDE.md, "Segurança"). Nenhum segredo aqui.
-- ====================================================================

create table if not exists public.insumo_remessa (
  id          text primary key,                 -- id gerado pelo app
  produto     text not null,                    -- nome canônico do produto (ex.: Nitrato de amônio)
  fornecedor  text,                             -- quem entrega (ex.: Cooxupé)
  data        date,                             -- data do anúncio da entrega
  payload     jsonb not null,                   -- a remessa inteira, com as alocações por unidade
  atualizado  timestamptz not null default now()
);
comment on table public.insumo_remessa is
  'v86 — programação de entrega de insumo lida da mensagem do grupo. payload.alocacoes = [{unidade, kg}].';

create table if not exists public.insumo_recebimento (
  id          text primary key,                 -- id gerado pelo app
  remessa_id  text,                             -- insumo_remessa.id (sem FK: o app é offline first)
  unidade_id  text,                             -- unidade que recebeu (fazendas.id do app)
  produto     text not null,
  kg          numeric,                          -- quantidade recebida, na base do produto (kg ou L)
  data        date,
  payload     jsonb not null,                   -- nota/romaneio, foto, observação e quem conferiu
  atualizado  timestamptz not null default now()
);
comment on table public.insumo_recebimento is
  'v86 — uma chegada confirmada pelo gerente (um toque). Entrega parcial é outra linha; nada é sobrescrito.';

create index if not exists insumo_remessa_data_idx on public.insumo_remessa (data desc);
create index if not exists insumo_receb_unidade_idx on public.insumo_recebimento (unidade_id, data desc);
create index if not exists insumo_receb_remessa_idx on public.insumo_recebimento (remessa_id);

create or replace function public.insumo_touch() returns trigger language plpgsql as $$
begin new.atualizado := now(); return new; end $$;

drop trigger if exists insumo_remessa_touch on public.insumo_remessa;
create trigger insumo_remessa_touch before insert or update on public.insumo_remessa
  for each row execute function public.insumo_touch();
drop trigger if exists insumo_receb_touch on public.insumo_recebimento;
create trigger insumo_receb_touch before insert or update on public.insumo_recebimento
  for each row execute function public.insumo_touch();

-- ---------- políticas (mesma regra das outras tabelas do app) ----------
alter table public.insumo_remessa enable row level security;
drop policy if exists insumo_remessa_ler on public.insumo_remessa;
create policy insumo_remessa_ler on public.insumo_remessa for select using (true);
drop policy if exists insumo_remessa_gravar on public.insumo_remessa;
create policy insumo_remessa_gravar on public.insumo_remessa for insert with check (true);
drop policy if exists insumo_remessa_atualizar on public.insumo_remessa;
create policy insumo_remessa_atualizar on public.insumo_remessa for update using (true) with check (true);

alter table public.insumo_recebimento enable row level security;
drop policy if exists insumo_receb_ler on public.insumo_recebimento;
create policy insumo_receb_ler on public.insumo_recebimento for select using (true);
drop policy if exists insumo_receb_gravar on public.insumo_recebimento;
create policy insumo_receb_gravar on public.insumo_recebimento for insert with check (true);
drop policy if exists insumo_receb_atualizar on public.insumo_recebimento;
create policy insumo_receb_atualizar on public.insumo_recebimento for update using (true) with check (true);

-- ---------- visão de leitura: programado × recebido por unidade e produto ----------
drop view if exists public.vw_insumo_saldo;
create view public.vw_insumo_saldo with (security_invoker = true) as
with alocado as (
  select r.id                                   as remessa_id,
         r.produto,
         r.fornecedor,
         r.data                                 as anunciado_em,
         a->>'unidade'                          as unidade_id,
         coalesce((a->>'kg')::numeric, 0)       as kg_programado
    from public.insumo_remessa r
    cross join lateral jsonb_array_elements(coalesce(r.payload->'alocacoes','[]'::jsonb)) a
),
recebido as (
  select remessa_id, unidade_id, sum(coalesce(kg,0)) as kg_recebido, max(data) as ultima_chegada
    from public.insumo_recebimento
   group by remessa_id, unidade_id
)
select al.unidade_id,
       al.produto,
       al.fornecedor,
       al.remessa_id,
       al.anunciado_em,
       al.kg_programado,
       coalesce(rc.kg_recebido, 0)                                   as kg_recebido,
       greatest(al.kg_programado - coalesce(rc.kg_recebido,0), 0)    as kg_a_receber,
       rc.ultima_chegada,
       (current_date - al.anunciado_em)                              as dias_desde_o_anuncio
  from alocado al
  left join recebido rc
    on rc.remessa_id = al.remessa_id and rc.unidade_id = al.unidade_id;

comment on view public.vw_insumo_saldo is
  'v86 — programado × recebido por unidade e produto. "A receber" é ausência de REGISTRO de chegada, nunca afirmação de que a carga não saiu.';

-- Avisa o PostgREST (a camada que o app conversa) que existem tabelas novas.
notify pgrst, 'reload schema';

-- conferência
select 'insumos criados' as passo,
       (select count(*) from public.insumo_remessa)      as remessas,
       (select count(*) from public.insumo_recebimento)  as recebimentos,
       (select count(*) from public.vw_insumo_saldo)     as linhas_na_visao;
