-- ====================================================================
-- 057 — Baixa do ERP × App: espelho da baixa oficial + conferência  ·  v96
-- ====================================================================
-- Objeto: insumo_baixa_erp. Rodar no SQL Editor do Supabase
-- (projeto syvehtgrbqteyuqhoban).
--
-- PASSO A PASSO (pelo iPhone):
--   1. Abra o Supabase e entre no projeto do Boletim.
--   2. Toque em "SQL Editor" e em "New query".
--   3. Selecione TODO o texto deste arquivo, copie e cole na caixa.
--   4. Toque em "Run".
--   5. No fim aparece uma tabelinha de conferência. Pode rodar de novo
--      quantas vezes quiser: nada duplica e nada se apaga.
--
-- O QUE É. A fertirrigação é feita, o escritório dá baixa dos insumos no
-- AgroGestão e o grupo "Aplicações Realizadas" avisa. O app passou a receber
-- a mensagem e o PDF "Aplicações de Insumos - Resumido" pela porta única
-- "📥 Colar do WhatsApp": cada linha do relatório (gleba × insumo) vira UMA
-- linha aqui — o ESPELHO da baixa oficial — junto com o resultado do
-- casamento que o app fez sozinho contra os lançamentos do boletim
-- (bate · lançado sem quantidade · quantidade diferente · talhão diferente
-- · fora da janela · só no ERP) e a situação da conferência do escritório.
--
-- PREMISSA: a baixa JÁ foi feita no ERP. O app nunca escreve no AgroGestão,
-- nunca gera arquivo de baixa e nunca cria um segundo consumo. Havendo baixa
-- do ERP para unidade + insumo + competência, ELA manda no saldo do app; os
-- lançamentos do boletim daquele mês viram só conferência. A baixa do ERP
-- NÃO acende farol de registro nem mexe nos "dias sem registro" (sql/040 e
-- sql/042 continuam lendo só os boletins).
--
-- HORA DO ERP É DE LANÇAMENTO, NÃO DE APLICAÇÃO. lancado_erp_ini e
-- lancado_erp_fim são os horários em que o escritório digitou (16:22 a
-- 16:34, fim 17:00 = digitação em lote). A competência (AAAA-MM) é o mês
-- da aplicação, da mensagem ou do período do relatório.
--
-- NADA SE APAGA. Relatório corrigido/relançado com outra quantidade: a
-- linha anterior recebe status = 'superada' e superada_por aponta a nova.
-- Por isso NÃO existe policy de delete.
--
-- COMO O DADO CHEGA: o app grava no aparelho e a mesma fila offline dos
-- boletins sobe cada linha por id (payload = a foto completa: casamento,
-- vínculos com o boletim, conferência e histórico). O app também LÊ esta
-- tabela a cada sincronização, então a importação feita no escritório
-- aparece no painel da Diretoria de qualquer aparelho.
--
-- ENQUANTO NÃO RODAR: o módulo funciona INTEIRO no aparelho de quem
-- importou — só não sincroniza entre celulares (as linhas ficam na fila,
-- "N registro(s) aguardando internet", e sobem sozinhas depois; nada se
-- perde). A trilha (mensagem colada, nome do arquivo, hash e texto
-- extraído do PDF) fica em mensagens_importadas (sql/055). O PDF em si
-- nunca é guardado: nem no aparelho, nem aqui.
--
-- VOCABULÁRIO (regra permanente): "sem registro no boletim", "sem baixa no
-- ERP", "para conferir" — nunca "não lançou", "não fez", "erro do gerente",
-- "pendente". Nenhum custo: mesmo que um relatório futuro traga R$, o app
-- não importa.
--
-- SEGURANÇA: leitura e escrita anon por policy, como insumo_remessa
-- (sql/054); a autorização real é o escopo do código de acesso. Nenhum
-- segredo aqui.
-- ====================================================================

create table if not exists public.insumo_baixa_erp (
  id               text primary key,              -- id gerado pelo app
  unidade_id       text,                          -- unidade do app (fazendas.id), pelo de-para da ata
  talhao_id        text,                          -- talhão do app (talhoes.id), pelo de-para aprendido da gleba
  gleba_erp        text,                          -- nome da gleba como saiu no ERP ("SETOR 1 ROMARIA")
  area_gleba_erp   numeric,                       -- área da gleba no ERP (ha)
  insumo_id        text,                          -- id do produto em D.insumos (quando cadastrado)
  insumo_erp       text,                          -- nome do insumo como saiu no ERP
  produto          text,                          -- nome canônico do produto no app
  unidade_medida   text,                          -- KG, L…
  area_ha          numeric,                       -- área aplicada da linha
  dose_ha          numeric,                       -- dose/ha da linha
  qtde             numeric not null,              -- quantidade total da linha (baixa oficial)
  competencia      text,                          -- AAAA-MM (mês da aplicação)
  operacao_erp     text,                          -- FERTIRRIGACAO, ADUBACAO…
  lancado_erp_ini  text,                          -- "AAAA-MM-DD HH:MM:SS" — hora de LANÇAMENTO no ERP
  lancado_erp_fim  text,
  emitido_erp_em   text,                          -- emissão do relatório
  origem_hash      text,                          -- hash do texto extraído (idempotência do relatório)
  mensagem_id      text,                          -- mensagens_importadas.id (trilha)
  status           text not null default 'vigente', -- vigente | superada
  superada_por     text,                          -- id da linha que substituiu esta
  resultado        text,                          -- bate | sem_qtd | qtd_dif | talhao_dif | fora_janela | so_erp
  conferencia      text,                          -- aberta | gerente | mesmo | diferentes | erp | '' (nada a conferir)
  criado_por       text,                          -- nome do perfil que importou (nunca telefone)
  criado_em        timestamptz not null default now(),
  payload          jsonb not null,                -- a foto completa (casamento, vínculos, conferência e histórico)
  atualizado       timestamptz not null default now()
);
comment on table public.insumo_baixa_erp is
  'v96 — espelho da baixa de insumo feita no ERP (AgroGestão), uma linha por gleba × insumo, com o casamento contra o boletim e a conferência do escritório. Nunca delete: superada é status.';
comment on column public.insumo_baixa_erp.lancado_erp_ini is 'hora de LANÇAMENTO no ERP (o escritório digitando), nunca hora de aplicação';
comment on column public.insumo_baixa_erp.competencia is 'mês da aplicação (AAAA-MM): da mensagem do grupo ou do período do relatório';

create index if not exists insumo_baixa_erp_unidade_idx on public.insumo_baixa_erp (unidade_id, competencia, status);
create index if not exists insumo_baixa_erp_hash_idx on public.insumo_baixa_erp (origem_hash);
create index if not exists insumo_baixa_erp_conf_idx on public.insumo_baixa_erp (conferencia) where conferencia in ('aberta','gerente');

create or replace function public.insumo_touch() returns trigger language plpgsql as $$
begin new.atualizado := now(); return new; end $$;

drop trigger if exists insumo_baixa_erp_touch on public.insumo_baixa_erp;
create trigger insumo_baixa_erp_touch before insert or update on public.insumo_baixa_erp
  for each row execute function public.insumo_touch();

-- ---------- políticas: ler, gravar e atualizar; NUNCA apagar ----------
alter table public.insumo_baixa_erp enable row level security;
drop policy if exists insumo_baixa_erp_ler on public.insumo_baixa_erp;
create policy insumo_baixa_erp_ler on public.insumo_baixa_erp for select using (true);
drop policy if exists insumo_baixa_erp_gravar on public.insumo_baixa_erp;
create policy insumo_baixa_erp_gravar on public.insumo_baixa_erp for insert with check (true);
drop policy if exists insumo_baixa_erp_atualizar on public.insumo_baixa_erp;
create policy insumo_baixa_erp_atualizar on public.insumo_baixa_erp for update using (true) with check (true);
-- (sem policy de delete, de propósito)

-- Avisa o PostgREST (a camada que o app conversa) que existe tabela nova.
notify pgrst, 'reload schema';

-- conferência
select 'insumo_baixa_erp criada' as passo,
       count(*)                                        as linhas,
       count(*) filter (where status = 'vigente')      as vigentes,
       count(*) filter (where conferencia in ('aberta','gerente')) as para_conferir,
       max(criado_em)                                  as ultima_importacao
from public.insumo_baixa_erp;
