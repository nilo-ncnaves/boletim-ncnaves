-- Categoria (natureza) da operação (v67) — espelho no Supabase
-- Rodar no SQL Editor do Supabase (projeto syvehtgrbqteyuqhoban).
--
-- OPCIONAL E SÓ DEPOIS DA APROVAÇÃO: o app NÃO lê este bloco. O badge de
-- categoria da v67 é resolvido no aparelho pelo catálogo do index.html
-- (constante OP_CATEGORIAS). Este arquivo só mantém o espelho
-- operacao_catalogo (sql/040) fiel ao app, para uma visão futura poder
-- agrupar por categoria. Rode apenas quando a tabela de categorias do
-- café (proposta no PR da v67) estiver aprovada; se mudar a proposta,
-- gere de novo com `node scripts/gerar_categorias_operacoes.cjs --sql`
-- e recole o trecho entre os marcadores.
--
-- PASSO A PASSO (pelo iPhone):
--   1. Abra o Supabase (app.supabase.com) e entre no projeto do Boletim.
--   2. No menu da esquerda, toque em "SQL Editor".
--   3. Toque em "New query".
--   4. Selecione TODO o texto deste arquivo (do começo ao fim), copie e
--      cole na caixa da consulta.
--   5. Toque em "Run".
--   6. No fim aparece uma tabelinha de conferência (uma linha por
--      atividade: quantas categorias e quantas operações ligadas — o
--      esperado é café 5/19, grãos 5/28, pecuária 5/28). Se aparecer erro
--      em vermelho, mande a mensagem inteira para o Claude.
--   Pode rodar de novo quantas vezes quiser: nada se duplica, nada se
--   apaga. Não é migração de dados: só acrescenta uma tabela pequena e
--   uma coluna nova (categoria_id) nas linhas já existentes do catálogo.
--
-- ANTES: sql/040-dias-sem-registro.sql precisa já ter rodado (tabela
-- operacao_catalogo). Se faltar, o bloco para com aviso e não faz nada.
--
-- IDENTIDADE (regra 6 do projeto): categoria = operacao_categoria.id
-- (ATIVIDADE-CHAVE, imutável); a ligação operação → categoria é pelo id da
-- operação (operacao_catalogo.id), nunca por pedaço de nome. A LETRA é
-- atributo da categoria (coluna letra), nunca derivada do nome. Máximo 5
-- categorias por atividade; letra única dentro da atividade (índice
-- abaixo garante); nenhuma categoria é classe de agroquímico.
--
-- Segurança: mesmo padrão do sql/040 — leitura anon via policy select;
-- escrita só pelo SQL Editor (sem policy de insert/update/delete).

-- 0. Pré-requisito: o catálogo (sql/040) precisa existir
do $$
begin
  if to_regclass('public.operacao_catalogo') is null then
    raise exception 'Rode antes o sql/040-dias-sem-registro.sql (falta operacao_catalogo).';
  end if;
end $$;

-- 1. Catálogo de categorias (identidade = id)
create table if not exists public.operacao_categoria (
  id        text primary key,                 -- CAFE-COLHEITA, GRAOS-PLANTIO, PECUARIA-SANITARIO… (nunca muda)
  atividade text not null check (atividade in ('CAFE', 'GRAOS', 'PECUARIA')),
  letra     text not null check (letra ~ '^[A-Z]$'),   -- a letra do badge: atributo, não derivação
  nome      text not null,                    -- nome de exibição (legenda do badge)
  ordem     integer not null default 0,
  criado_em timestamptz not null default now(),
  unique (atividade, letra)                   -- letra única dentro da atividade
);
comment on table public.operacao_categoria is
  'Categoria (natureza) da operação — badge de uma letra do Boletim NCNaves (espelho de OP_CATEGORIAS do index.html; seed por scripts/gerar_categorias_operacoes.cjs). Sem cor: a cor é canal do farol. Só o SQL Editor escreve.';

-- 2. Ligação operação → categoria (coluna nova no catálogo; nulo = sem badge)
alter table public.operacao_catalogo add column if not exists categoria_id text references public.operacao_categoria (id);
comment on column public.operacao_catalogo.categoria_id is
  'Categoria (natureza) da operação para o badge de uma letra (v67). Nulo = operação sem categoria (sem badge).';

alter table public.operacao_categoria enable row level security;
drop policy if exists "operacao_categoria leitura" on public.operacao_categoria;
create policy "operacao_categoria leitura" on public.operacao_categoria for select using (true);
-- sem policy de insert/update/delete: só o SQL Editor (dono) escreve

-- 3. Seed das categorias e da ligação
-- >>> seed gerado por scripts/gerar_categorias_operacoes.cjs (15 categorias, 75 operações ligadas)
insert into public.operacao_categoria (id, atividade, letra, nome, ordem) values
  ('GRAOS-PRE_PLANTIO', 'GRAOS', 'R', 'Pré-plantio', 1),
  ('GRAOS-PLANTIO', 'GRAOS', 'P', 'Plantio', 2),
  ('GRAOS-CONDUCAO', 'GRAOS', 'D', 'Condução', 3),
  ('GRAOS-COLHEITA', 'GRAOS', 'C', 'Colheita', 4),
  ('GRAOS-POS_COLHEITA', 'GRAOS', 'S', 'Pós-colheita', 5),
  ('PECUARIA-MANEJO_DIARIO', 'PECUARIA', 'D', 'Manejo diário', 1),
  ('PECUARIA-SANITARIO', 'PECUARIA', 'S', 'Sanitário', 2),
  ('PECUARIA-REPRODUTIVO', 'PECUARIA', 'R', 'Reprodutivo', 3),
  ('PECUARIA-MANEJO_LOTE', 'PECUARIA', 'L', 'Manejo de lote', 4),
  ('PECUARIA-PASTAGEM_ESTRUTURA', 'PECUARIA', 'P', 'Pastagem e estrutura', 5),
  ('CAFE-COLHEITA', 'CAFE', 'C', 'Colheita', 1),
  ('CAFE-APLICACAO', 'CAFE', 'A', 'Aplicação', 2),
  ('CAFE-TRATO_CULTURAL', 'CAFE', 'T', 'Trato cultural', 3),
  ('CAFE-MONITORAMENTO', 'CAFE', 'M', 'Monitoramento', 4),
  ('CAFE-IRRIGACAO_INFRA', 'CAFE', 'I', 'Irrigação e infraestrutura', 5)
on conflict (id) do update set atividade = excluded.atividade, letra = excluded.letra, nome = excluded.nome, ordem = excluded.ordem;

update public.operacao_catalogo as o set categoria_id = v.categoria_id
  from (values
    ('GRAOS-DESSECACAO_DE_PRE_PLANTIO', 'GRAOS-PRE_PLANTIO'),
    ('GRAOS-CALAGEM', 'GRAOS-PRE_PLANTIO'),
    ('GRAOS-GESSAGEM', 'GRAOS-PRE_PLANTIO'),
    ('GRAOS-GRADAGEM_PREPARO_DE_SOLO', 'GRAOS-PRE_PLANTIO'),
    ('GRAOS-MANEJO_DA_PALHADA', 'GRAOS-PRE_PLANTIO'),
    ('GRAOS-AMOSTRAGEM_DE_SOLO', 'GRAOS-PRE_PLANTIO'),
    ('GRAOS-PLANTIO_SEMEADURA', 'GRAOS-PLANTIO'),
    ('GRAOS-TRATAMENTO_DE_SEMENTES', 'GRAOS-PLANTIO'),
    ('GRAOS-INOCULACAO', 'GRAOS-PLANTIO'),
    ('GRAOS-ADUBACAO_DE_PLANTIO', 'GRAOS-PLANTIO'),
    ('GRAOS-REPLANTIO', 'GRAOS-PLANTIO'),
    ('GRAOS-AVALIACAO_DE_ESTANDE', 'GRAOS-PLANTIO'),
    ('GRAOS-ADUBACAO_DE_COBERTURA', 'GRAOS-CONDUCAO'),
    ('GRAOS-HERBICIDA_POS_EMERGENTE', 'GRAOS-CONDUCAO'),
    ('GRAOS-FUNGICIDA', 'GRAOS-CONDUCAO'),
    ('GRAOS-INSETICIDA', 'GRAOS-CONDUCAO'),
    ('GRAOS-APLICACAO_FOLIAR_MICRONUTRIENTES', 'GRAOS-CONDUCAO'),
    ('GRAOS-MONITORAMENTO_DE_PRAGAS_E_DOENCAS', 'GRAOS-CONDUCAO'),
    ('GRAOS-CONTROLE_DE_DANINHAS_MANUAL', 'GRAOS-CONDUCAO'),
    ('GRAOS-DESSECACAO_DE_PRE_COLHEITA', 'GRAOS-COLHEITA'),
    ('GRAOS-COLHEITA_MECANIZADA', 'GRAOS-COLHEITA'),
    ('GRAOS-TRANSPORTE_AO_ARMAZEM', 'GRAOS-COLHEITA'),
    ('GRAOS-PESAGEM', 'GRAOS-COLHEITA'),
    ('GRAOS-AMOSTRAGEM_DE_UMIDADE_IMPUREZA', 'GRAOS-COLHEITA'),
    ('GRAOS-SECAGEM_PRE_LIMPEZA', 'GRAOS-COLHEITA'),
    ('GRAOS-DESTRUICAO_DE_RESTOS_CULTURAIS', 'GRAOS-POS_COLHEITA'),
    ('GRAOS-SEMEADURA_DE_COBERTURA', 'GRAOS-POS_COLHEITA'),
    ('GRAOS-VAZIO_SANITARIO', 'GRAOS-POS_COLHEITA'),
    ('PEC-CONTAGEM', 'PECUARIA-MANEJO_DIARIO'),
    ('PEC-SUPLEMENTACAO', 'PECUARIA-MANEJO_DIARIO'),
    ('PEC-CONFERENCIA_DE_AGUA_AGUADAS', 'PECUARIA-MANEJO_DIARIO'),
    ('PEC-ROTACAO_DE_PASTO_ENTRADA_DE_LOTE', 'PECUARIA-MANEJO_DIARIO'),
    ('PEC-ROTACAO_DE_PASTO_SAIDA_DE_LOTE', 'PECUARIA-MANEJO_DIARIO'),
    ('PEC-VACINACAO', 'PECUARIA-SANITARIO'),
    ('PEC-VERMIFUGACAO', 'PECUARIA-SANITARIO'),
    ('PEC-CONTROLE_DE_CARRAPATO_MOSCA_DO_CHIFRE', 'PECUARIA-SANITARIO'),
    ('PEC-CURA_DE_BICHEIRA', 'PECUARIA-SANITARIO'),
    ('PEC-CURA_DE_UMBIGO', 'PECUARIA-SANITARIO'),
    ('PEC-TRATAMENTO_INDIVIDUAL', 'PECUARIA-SANITARIO'),
    ('PEC-MORTALIDADE', 'PECUARIA-SANITARIO'),
    ('PEC-ESTACAO_DE_MONTA', 'PECUARIA-REPRODUTIVO'),
    ('PEC-IATF', 'PECUARIA-REPRODUTIVO'),
    ('PEC-DIAGNOSTICO_DE_GESTACAO', 'PECUARIA-REPRODUTIVO'),
    ('PEC-PARTO_NASCIMENTO', 'PECUARIA-REPRODUTIVO'),
    ('PEC-DESMAMA', 'PECUARIA-REPRODUTIVO'),
    ('PEC-MARCACAO_BRINCAGEM', 'PECUARIA-MANEJO_LOTE'),
    ('PEC-CASTRACAO', 'PECUARIA-MANEJO_LOTE'),
    ('PEC-APARTACAO', 'PECUARIA-MANEJO_LOTE'),
    ('PEC-PESAGEM', 'PECUARIA-MANEJO_LOTE'),
    ('PEC-EMBARQUE_VENDA', 'PECUARIA-MANEJO_LOTE'),
    ('PEC-COMPRA_ENTRADA_DE_ANIMAIS', 'PECUARIA-MANEJO_LOTE'),
    ('PEC-ROCADA', 'PECUARIA-PASTAGEM_ESTRUTURA'),
    ('PEC-ADUBACAO_DE_PASTAGEM', 'PECUARIA-PASTAGEM_ESTRUTURA'),
    ('PEC-REFORMA_DE_PASTO', 'PECUARIA-PASTAGEM_ESTRUTURA'),
    ('PEC-MANUTENCAO_DE_CERCA_COCHO_BEBEDOURO', 'PECUARIA-PASTAGEM_ESTRUTURA'),
    ('PEC-CONTROLE_DE_FORMIGA', 'PECUARIA-PASTAGEM_ESTRUTURA'),
    ('CAFE-COLHEITA', 'CAFE-COLHEITA'),
    ('CAFE-CATACAO', 'CAFE-COLHEITA'),
    ('CAFE-REPASSE', 'CAFE-COLHEITA'),
    ('CAFE-PULVERIZACAO', 'CAFE-APLICACAO'),
    ('CAFE-APLICACAO_DE_HERBICIDA', 'CAFE-APLICACAO'),
    ('CAFE-ADUBACAO_VIA_LANCO', 'CAFE-APLICACAO'),
    ('CAFE-ADUBACAO_ORGANICA', 'CAFE-APLICACAO'),
    ('CAFE-APLICACAO_VIA_DRENCH_VIA_SOLO', 'CAFE-APLICACAO'),
    ('CAFE-CALAGEM_GESSAGEM', 'CAFE-APLICACAO'),
    ('CAFE-CAPINA_MANUAL', 'CAFE-TRATO_CULTURAL'),
    ('CAFE-CAPINA_ROCADEIRA_TRINCHA', 'CAFE-TRATO_CULTURAL'),
    ('CAFE-ARRUACAO_ESPARRAMACAO_DE_CISCO', 'CAFE-TRATO_CULTURAL'),
    ('CAFE-DESBROTA', 'CAFE-TRATO_CULTURAL'),
    ('CAFE-PODA_ESQUELETAMENTO', 'CAFE-TRATO_CULTURAL'),
    ('CAFE-MONITORAMENTO_DE_PRAGAS', 'CAFE-MONITORAMENTO'),
    ('CAFE-LIMPEZA_DO_SISTEMA_DE_IRRIGACAO', 'CAFE-IRRIGACAO_INFRA'),
    ('CAFE-IRRIGACAO', 'CAFE-IRRIGACAO_INFRA'),
    ('CAFE-PLANTIO_RENOVACAO', 'CAFE-TRATO_CULTURAL'),
    ('CAFE-MANUTENCAO_DE_ESTRADAS_E_ACEIROS', 'CAFE-IRRIGACAO_INFRA')
  ) as v (operacao_id, categoria_id)
  where o.id = v.operacao_id;
-- <<< seed gerado

-- 4. Conferência: categorias e operações ligadas por atividade
select c.atividade,
       count(distinct c.id)                         as categorias,
       count(o.id)                                  as operacoes_ligadas,
       string_agg(distinct c.letra, ' ' order by c.letra) as letras
  from public.operacao_categoria c
  left join public.operacao_catalogo o on o.categoria_id = c.id
 group by c.atividade
 order by c.atividade;
