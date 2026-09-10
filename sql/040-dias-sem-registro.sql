-- Dias sem registro (v59) — visão vw_dias_sem_registro
-- Rodar no SQL Editor do Supabase (projeto syvehtgrbqteyuqhoban).
--
-- PASSO A PASSO (pelo iPhone):
--   1. Abra o Supabase (app.supabase.com) e entre no projeto do Boletim.
--   2. No menu da esquerda, toque em "SQL Editor".
--   3. Toque em "New query".
--   4. Selecione TODO o texto deste arquivo (do começo ao fim), copie e
--      cole na caixa da consulta.
--   5. Toque em "Run".
--   6. No fim aparece uma tabelinha de conferência (uma linha por
--      atividade: quantas combinações unidade × operação existem e
--      quantas já têm registro). Se aparecer erro em vermelho, mande a
--      mensagem inteira para o Claude.
--   Pode rodar de novo quantas vezes quiser: nada se duplica.
--
-- ANTES: sql/020-relatorios-motor.sql precisa já ter rodado (rodou em
-- 05/09/2026). Este bloco usa dele: rel_unidades (lista das unidades e da
-- atividade de cada uma), rel_fz_atual (ids antigos de fazenda) e
-- rel_hoje_brt (data de hoje em Brasília). Se faltar, o bloco para com
-- um aviso claro e não faz nada.
--
-- O QUE É: um inteiro por unidade operacional × operação do catálogo
-- dizendo há quantos dias aquela operação não é registrada no boletim.
-- A visão NÃO julga: não há coluna de status, farol, atraso ou "não fez".
-- A janela e a cor do farol são decisão de outra camada (backlog).
--
-- IDENTIDADE (regra 6 do projeto): unidade = rel_unidades.id (f33, f26…),
-- operação = operacao_catalogo.id (código imutável). O nome que o app
-- grava no payload do boletim é só um APELIDO (operacao_alias), casado
-- por igualdade exata do texto — nunca LIKE, nunca pedaço de nome. Mesmo
-- modelo de unidade_manejo + unidade_alias do plano de safra.
--
-- DE ONDE VEM O REGISTRO (boletins.payload):
--   atividades[].tipo         → café e grãos (LISTA_ATIV / OPS_GRAOS_FASES)
--   pecuaria.eventos[].tipo   → pecuária, "Outros manejos" (OPS_PECUARIA_FASES)
--   pecuaria.mov[].tipo       → Nascimento, Morte, Desmama, Mudança de pasto
--                               (entrada E saída de lote), Entrada, Saída
--   pecuaria.massa[].tipo     → Vacinação, Vermifugação
--   pecuaria.san[].problema   → Bicheira, Carrapato / mosca em excesso
--   pecuaria.lotes[] (cabeças > 0) → Contagem            (termo "*")
--   pecuaria.nut[]   (insumo)      → Suplementação       (termo "*")
--   pecuaria.rep.iatfEtapa         → IATF                (termo "*")
--   pecuaria.rep.dgPrenhes/dgVazias → Diagnóstico de gestação (termo "*")
-- Boletins marcados "exemplo" (dados de fábrica) não contam.
-- Café entra na visão só como dado (mesma regra para as três atividades);
-- nenhuma tela de café lê esta visão.
--
-- NUNCA registrado ≠ zero dias: dias_sem_registro fica NULL e
-- nunca_registrado = true. Zero significa "registrado hoje".
-- "Hoje" é a data de Brasília (rel_hoje_brt), como nos demais relatórios.
--
-- Índice: boletins já tem índice único em (fazenda_id, data) — é o que
-- permite o upsert on_conflict=fazenda_id,data do app. A operação vive
-- dentro do jsonb, então não há índice possível em (unidade, operação,
-- data); o bloco abaixo só cria o índice (fazenda_id, data) se por acaso
-- não existir.
--
-- Segurança: mesmo padrão das outras visões (pecuaria_movimentos) e das
-- tabelas do motor (leitura anon via policy select; escrita só pelo SQL
-- Editor — sem policy de insert/update/delete). A visão roda com
-- security_invoker, ou seja, com as permissões de quem lê: não afrouxa
-- nada que já não estivesse liberado.
--
-- Seed do catálogo: gerado por scripts/gerar_catalogo_operacoes.cjs a
-- partir das constantes do index.html. Termo novo no app → rodar o
-- script e recolar o trecho entre os marcadores.

-- 0. Pré-requisito: o motor (sql/020) precisa existir
do $$
begin
  if to_regclass('public.rel_unidades') is null
     or to_regproc('public.rel_fz_atual') is null
     or to_regproc('public.rel_hoje_brt') is null then
    raise exception 'Rode antes o sql/020-relatorios-motor.sql (faltam rel_unidades / rel_fz_atual / rel_hoje_brt).';
  end if;
end $$;

-- 1. Catálogo mestre de operações (identidade = id, código imutável)
create table if not exists public.operacao_catalogo (
  id        text primary key,                 -- CAFE-…, GRAOS-…, PEC-… (nunca muda)
  atividade text not null check (atividade in ('CAFE', 'GRAOS', 'PECUARIA')),
  fase      text,                             -- fase do catálogo (grãos/pecuária); nulo no café
  nome      text not null,                    -- nome de exibição (o mesmo do index.html)
  ordem     integer not null default 0,       -- ordem do catálogo do app
  ativo     boolean not null default true,    -- false = fora da visão, sem apagar
  criado_em timestamptz not null default now()
);
comment on table public.operacao_catalogo is
  'Catálogo mestre de operações do Boletim NCNaves (espelho de LISTA_ATIV, OPS_GRAOS_FASES e OPS_PECUARIA_FASES do index.html; seed por scripts/gerar_catalogo_operacoes.cjs). Identidade = id. Só o SQL Editor escreve.';
create index if not exists operacao_catalogo_atividade on public.operacao_catalogo (atividade) where ativo;

-- 2. Apelidos: texto exato que o app grava → operação (igualdade exata, nunca LIKE)
create table if not exists public.operacao_alias (
  operacao_id text not null references public.operacao_catalogo (id),
  origem      text not null,   -- caminho no payload: atividades.tipo, pecuaria.eventos.tipo, pecuaria.mov.tipo, pecuaria.massa.tipo, pecuaria.san.problema, pecuaria.lotes, pecuaria.nut, pecuaria.rep.iatf, pecuaria.rep.dg
  termo       text not null,   -- valor exato gravado pelo app; "*" = basta a linha existir
  criado_em   timestamptz not null default now(),
  primary key (operacao_id, origem, termo)
);
comment on table public.operacao_alias is
  'De-para texto do payload → operacao_catalogo.id (igualdade exata). Um termo pode apontar para mais de uma operação (ex.: Mudança de pasto = entrada e saída de lote).';
create index if not exists operacao_alias_origem_termo on public.operacao_alias (origem, termo);

alter table public.operacao_catalogo enable row level security;
drop policy if exists "operacao_catalogo leitura" on public.operacao_catalogo;
create policy "operacao_catalogo leitura" on public.operacao_catalogo for select using (true);
alter table public.operacao_alias enable row level security;
drop policy if exists "operacao_alias leitura" on public.operacao_alias;
create policy "operacao_alias leitura" on public.operacao_alias for select using (true);
-- sem policy de insert/update/delete: só o SQL Editor (dono) escreve

-- 3. Seed do catálogo e dos apelidos
-- >>> seed gerado por scripts/gerar_catalogo_operacoes.cjs (82 operações, 103 apelidos)
insert into public.operacao_catalogo (id, atividade, fase, nome, ordem) values
  ('CAFE-PULVERIZACAO_MANUAL', 'CAFE', 'Tratos culturais', 'Pulverização manual', 1),
  ('CAFE-PULVERIZACAO_MECANIZADA', 'CAFE', 'Tratos culturais', 'Pulverização mecanizada', 2),
  ('CAFE-ADUBACAO_MANUAL', 'CAFE', 'Tratos culturais', 'Adubação manual', 3),
  ('CAFE-ADUBACAO_VIA_LANCO', 'CAFE', 'Tratos culturais', 'Adubação via lanço', 4),
  ('CAFE-ADUBACAO_ORGANICA', 'CAFE', 'Tratos culturais', 'Adubação orgânica', 5),
  ('CAFE-APLICACAO_VIA_DRENCH_VIA_SOLO', 'CAFE', 'Tratos culturais', 'Aplicação via drench / via solo', 6),
  ('CAFE-CALAGEM_GESSAGEM', 'CAFE', 'Tratos culturais', 'Calagem / gessagem', 7),
  ('CAFE-CAPINA_MANUAL', 'CAFE', 'Tratos culturais', 'Capina manual', 8),
  ('CAFE-CAPINA_MECANICA_COM_TRINCHA', 'CAFE', 'Tratos culturais', 'Capina mecânica com trincha', 9),
  ('CAFE-CAPINA_MECANICA_COM_ROCADEIRA', 'CAFE', 'Tratos culturais', 'Capina mecânica com roçadeira', 10),
  ('CAFE-CAPINA_QUIMICA_MANUAL', 'CAFE', 'Tratos culturais', 'Capina química manual', 11),
  ('CAFE-CAPINA_QUIMICA_MECANIZADA', 'CAFE', 'Tratos culturais', 'Capina química mecanizada', 12),
  ('CAFE-DESBROTA_MANUAL', 'CAFE', 'Tratos culturais', 'Desbrota manual', 13),
  ('CAFE-PODA_MECANIZADA_ESQUELETAMENTO', 'CAFE', 'Tratos culturais', 'Poda mecanizada esqueletamento', 14),
  ('CAFE-LEVANTAR_CAFE', 'CAFE', 'Tratos culturais', 'Levantar café', 15),
  ('CAFE-ARRUACAO_ESPARRAMACAO_DE_CISCO', 'CAFE', 'Tratos culturais', 'Arruação / esparramação de cisco', 16),
  ('CAFE-MONITORAMENTO_DE_PRAGAS', 'CAFE', 'Tratos culturais', 'Monitoramento de pragas (MIP)', 17),
  ('CAFE-PLANTIO_RENOVACAO', 'CAFE', 'Tratos culturais', 'Plantio / renovação', 18),
  ('CAFE-IRRIGACAO_MANUAL', 'CAFE', 'Irrigação e fertirrigação', 'Irrigação manual', 19),
  ('CAFE-IRRIGACAO_AUTOMATICA', 'CAFE', 'Irrigação e fertirrigação', 'Irrigação automática', 20),
  ('CAFE-ADUBACAO_VIA_FERTIRRIGACAO', 'CAFE', 'Irrigação e fertirrigação', 'Adubação via fertirrigação', 21),
  ('CAFE-LIMPEZA_DO_SISTEMA_DE_IRRIGACAO', 'CAFE', 'Irrigação e fertirrigação', 'Limpeza do sistema de irrigação', 22),
  ('CAFE-COLHEITA', 'CAFE', 'Colheita e pós-colheita', 'Colheita', 23),
  ('CAFE-CATACAO', 'CAFE', 'Colheita e pós-colheita', 'Catação', 24),
  ('CAFE-REPASSE', 'CAFE', 'Colheita e pós-colheita', 'Repasse', 25),
  ('CAFE-MANUTENCAO_DE_ESTRADAS_E_ACEIROS', 'CAFE', 'Estrutura e apoio', 'Manutenção de estradas e aceiros', 26),
  ('GRAOS-DESSECACAO_DE_PRE_PLANTIO', 'GRAOS', 'Pré-plantio', 'Dessecação de pré-plantio', 1),
  ('GRAOS-CALAGEM', 'GRAOS', 'Pré-plantio', 'Calagem', 2),
  ('GRAOS-GESSAGEM', 'GRAOS', 'Pré-plantio', 'Gessagem', 3),
  ('GRAOS-GRADAGEM_PREPARO_DE_SOLO', 'GRAOS', 'Pré-plantio', 'Gradagem / preparo de solo', 4),
  ('GRAOS-MANEJO_DA_PALHADA', 'GRAOS', 'Pré-plantio', 'Manejo da palhada', 5),
  ('GRAOS-AMOSTRAGEM_DE_SOLO', 'GRAOS', 'Pré-plantio', 'Amostragem de solo', 6),
  ('GRAOS-PLANTIO_SEMEADURA', 'GRAOS', 'Plantio', 'Plantio / semeadura', 7),
  ('GRAOS-TRATAMENTO_DE_SEMENTES', 'GRAOS', 'Plantio', 'Tratamento de sementes', 8),
  ('GRAOS-INOCULACAO', 'GRAOS', 'Plantio', 'Inoculação (soja/feijão)', 9),
  ('GRAOS-ADUBACAO_DE_PLANTIO', 'GRAOS', 'Plantio', 'Adubação de plantio (sulco)', 10),
  ('GRAOS-REPLANTIO', 'GRAOS', 'Plantio', 'Replantio', 11),
  ('GRAOS-AVALIACAO_DE_ESTANDE', 'GRAOS', 'Plantio', 'Avaliação de estande', 12),
  ('GRAOS-ADUBACAO_DE_COBERTURA', 'GRAOS', 'Condução', 'Adubação de cobertura', 13),
  ('GRAOS-HERBICIDA_POS_EMERGENTE', 'GRAOS', 'Condução', 'Herbicida pós-emergente', 14),
  ('GRAOS-FUNGICIDA', 'GRAOS', 'Condução', 'Fungicida', 15),
  ('GRAOS-INSETICIDA', 'GRAOS', 'Condução', 'Inseticida', 16),
  ('GRAOS-APLICACAO_FOLIAR_MICRONUTRIENTES', 'GRAOS', 'Condução', 'Aplicação foliar / micronutrientes', 17),
  ('GRAOS-MONITORAMENTO_DE_PRAGAS_E_DOENCAS', 'GRAOS', 'Condução', 'Monitoramento de pragas e doenças', 18),
  ('GRAOS-CONTROLE_DE_DANINHAS_MANUAL', 'GRAOS', 'Condução', 'Controle de daninhas manual (escape)', 19),
  ('GRAOS-DESSECACAO_DE_PRE_COLHEITA', 'GRAOS', 'Colheita', 'Dessecação de pré-colheita (feijão/soja)', 20),
  ('GRAOS-COLHEITA_MECANIZADA', 'GRAOS', 'Colheita', 'Colheita mecanizada', 21),
  ('GRAOS-TRANSPORTE_AO_ARMAZEM', 'GRAOS', 'Colheita', 'Transporte ao armazém', 22),
  ('GRAOS-PESAGEM', 'GRAOS', 'Colheita', 'Pesagem', 23),
  ('GRAOS-AMOSTRAGEM_DE_UMIDADE_IMPUREZA', 'GRAOS', 'Colheita', 'Amostragem de umidade / impureza', 24),
  ('GRAOS-SECAGEM_PRE_LIMPEZA', 'GRAOS', 'Colheita', 'Secagem / pré-limpeza', 25),
  ('GRAOS-DESTRUICAO_DE_RESTOS_CULTURAIS', 'GRAOS', 'Pós-colheita', 'Destruição de restos culturais', 26),
  ('GRAOS-SEMEADURA_DE_COBERTURA', 'GRAOS', 'Pós-colheita', 'Semeadura de cobertura', 27),
  ('GRAOS-VAZIO_SANITARIO', 'GRAOS', 'Pós-colheita', 'Vazio sanitário (soja)', 28),
  ('PEC-CONTAGEM', 'PECUARIA', 'Manejo diário', 'Contagem', 1),
  ('PEC-SUPLEMENTACAO', 'PECUARIA', 'Manejo diário', 'Suplementação (sal mineral / proteinado / ração)', 2),
  ('PEC-CONFERENCIA_DE_AGUA_AGUADAS', 'PECUARIA', 'Manejo diário', 'Conferência de água / aguadas', 3),
  ('PEC-ROTACAO_DE_PASTO_ENTRADA_DE_LOTE', 'PECUARIA', 'Manejo diário', 'Rotação de pasto — entrada de lote', 4),
  ('PEC-ROTACAO_DE_PASTO_SAIDA_DE_LOTE', 'PECUARIA', 'Manejo diário', 'Rotação de pasto — saída de lote', 5),
  ('PEC-VACINACAO', 'PECUARIA', 'Sanitário', 'Vacinação (especificar)', 6),
  ('PEC-VERMIFUGACAO', 'PECUARIA', 'Sanitário', 'Vermifugação', 7),
  ('PEC-CONTROLE_DE_CARRAPATO_MOSCA_DO_CHIFRE', 'PECUARIA', 'Sanitário', 'Controle de carrapato / mosca-do-chifre', 8),
  ('PEC-CURA_DE_BICHEIRA', 'PECUARIA', 'Sanitário', 'Cura de bicheira', 9),
  ('PEC-CURA_DE_UMBIGO', 'PECUARIA', 'Sanitário', 'Cura de umbigo', 10),
  ('PEC-TRATAMENTO_INDIVIDUAL', 'PECUARIA', 'Sanitário', 'Tratamento individual (especificar)', 11),
  ('PEC-MORTALIDADE', 'PECUARIA', 'Sanitário', 'Mortalidade (com causa)', 12),
  ('PEC-ESTACAO_DE_MONTA', 'PECUARIA', 'Reprodutivo', 'Estação de monta', 13),
  ('PEC-IATF', 'PECUARIA', 'Reprodutivo', 'IATF', 14),
  ('PEC-DIAGNOSTICO_DE_GESTACAO', 'PECUARIA', 'Reprodutivo', 'Diagnóstico de gestação', 15),
  ('PEC-PARTO_NASCIMENTO', 'PECUARIA', 'Reprodutivo', 'Parto / nascimento', 16),
  ('PEC-DESMAMA', 'PECUARIA', 'Reprodutivo', 'Desmama', 17),
  ('PEC-MARCACAO_BRINCAGEM', 'PECUARIA', 'Manejo de lote', 'Marcação / brincagem', 18),
  ('PEC-CASTRACAO', 'PECUARIA', 'Manejo de lote', 'Castração', 19),
  ('PEC-APARTACAO', 'PECUARIA', 'Manejo de lote', 'Apartação', 20),
  ('PEC-PESAGEM', 'PECUARIA', 'Manejo de lote', 'Pesagem', 21),
  ('PEC-EMBARQUE_VENDA', 'PECUARIA', 'Manejo de lote', 'Embarque / venda', 22),
  ('PEC-COMPRA_ENTRADA_DE_ANIMAIS', 'PECUARIA', 'Manejo de lote', 'Compra / entrada de animais', 23),
  ('PEC-ROCADA', 'PECUARIA', 'Pastagem e estrutura', 'Roçada', 24),
  ('PEC-ADUBACAO_DE_PASTAGEM', 'PECUARIA', 'Pastagem e estrutura', 'Adubação de pastagem', 25),
  ('PEC-REFORMA_DE_PASTO', 'PECUARIA', 'Pastagem e estrutura', 'Reforma de pasto', 26),
  ('PEC-MANUTENCAO_DE_CERCA_COCHO_BEBEDOURO', 'PECUARIA', 'Pastagem e estrutura', 'Manutenção de cerca / cocho / bebedouro', 27),
  ('PEC-CONTROLE_DE_FORMIGA', 'PECUARIA', 'Pastagem e estrutura', 'Controle de formiga', 28)
on conflict (id) do update set atividade = excluded.atividade, fase = excluded.fase, nome = excluded.nome, ordem = excluded.ordem;

insert into public.operacao_alias (operacao_id, origem, termo) values
  ('CAFE-PULVERIZACAO_MANUAL', 'atividades.tipo', 'Pulverização manual'),
  ('CAFE-PULVERIZACAO_MECANIZADA', 'atividades.tipo', 'Pulverização mecanizada'),
  ('CAFE-ADUBACAO_MANUAL', 'atividades.tipo', 'Adubação manual'),
  ('CAFE-ADUBACAO_VIA_LANCO', 'atividades.tipo', 'Adubação via lanço'),
  ('CAFE-ADUBACAO_ORGANICA', 'atividades.tipo', 'Adubação orgânica'),
  ('CAFE-APLICACAO_VIA_DRENCH_VIA_SOLO', 'atividades.tipo', 'Aplicação via drench / via solo'),
  ('CAFE-CALAGEM_GESSAGEM', 'atividades.tipo', 'Calagem / gessagem'),
  ('CAFE-CAPINA_MANUAL', 'atividades.tipo', 'Capina manual'),
  ('CAFE-CAPINA_MECANICA_COM_TRINCHA', 'atividades.tipo', 'Capina mecânica com trincha'),
  ('CAFE-CAPINA_MECANICA_COM_ROCADEIRA', 'atividades.tipo', 'Capina mecânica com roçadeira'),
  ('CAFE-CAPINA_QUIMICA_MANUAL', 'atividades.tipo', 'Capina química manual'),
  ('CAFE-CAPINA_QUIMICA_MECANIZADA', 'atividades.tipo', 'Capina química mecanizada'),
  ('CAFE-DESBROTA_MANUAL', 'atividades.tipo', 'Desbrota manual'),
  ('CAFE-PODA_MECANIZADA_ESQUELETAMENTO', 'atividades.tipo', 'Poda mecanizada esqueletamento'),
  ('CAFE-LEVANTAR_CAFE', 'atividades.tipo', 'Levantar café'),
  ('CAFE-ARRUACAO_ESPARRAMACAO_DE_CISCO', 'atividades.tipo', 'Arruação / esparramação de cisco'),
  ('CAFE-MONITORAMENTO_DE_PRAGAS', 'atividades.tipo', 'Monitoramento de pragas (MIP)'),
  ('CAFE-PLANTIO_RENOVACAO', 'atividades.tipo', 'Plantio / renovação'),
  ('CAFE-IRRIGACAO_MANUAL', 'atividades.tipo', 'Irrigação manual'),
  ('CAFE-IRRIGACAO_AUTOMATICA', 'atividades.tipo', 'Irrigação automática'),
  ('CAFE-ADUBACAO_VIA_FERTIRRIGACAO', 'atividades.tipo', 'Adubação via fertirrigação'),
  ('CAFE-LIMPEZA_DO_SISTEMA_DE_IRRIGACAO', 'atividades.tipo', 'Limpeza do sistema de irrigação'),
  ('CAFE-COLHEITA', 'atividades.tipo', 'Colheita'),
  ('CAFE-CATACAO', 'atividades.tipo', 'Catação'),
  ('CAFE-REPASSE', 'atividades.tipo', 'Repasse'),
  ('CAFE-MANUTENCAO_DE_ESTRADAS_E_ACEIROS', 'atividades.tipo', 'Manutenção de estradas e aceiros'),
  ('CAFE-DESBROTA_MANUAL', 'atividades.tipo', 'Desbrota'),
  ('CAFE-PODA_MECANIZADA_ESQUELETAMENTO', 'atividades.tipo', 'Poda / esqueletamento'),
  ('CAFE-CAPINA_MECANICA_COM_ROCADEIRA', 'atividades.tipo', 'Roçada costal'),
  ('CAFE-CAPINA_QUIMICA_MANUAL', 'atividades.tipo', 'Aplicação de herbicida (costal)'),
  ('CAFE-PULVERIZACAO_MANUAL', 'atividades.tipo', 'Aplicação de defensivo (costal)'),
  ('CAFE-PODA_MECANIZADA_ESQUELETAMENTO', 'atividades.tipo', 'Poda (decote/esqueletamento)'),
  ('GRAOS-DESSECACAO_DE_PRE_PLANTIO', 'atividades.tipo', 'Dessecação de pré-plantio'),
  ('GRAOS-CALAGEM', 'atividades.tipo', 'Calagem'),
  ('GRAOS-GESSAGEM', 'atividades.tipo', 'Gessagem'),
  ('GRAOS-GRADAGEM_PREPARO_DE_SOLO', 'atividades.tipo', 'Gradagem / preparo de solo'),
  ('GRAOS-MANEJO_DA_PALHADA', 'atividades.tipo', 'Manejo da palhada'),
  ('GRAOS-AMOSTRAGEM_DE_SOLO', 'atividades.tipo', 'Amostragem de solo'),
  ('GRAOS-PLANTIO_SEMEADURA', 'atividades.tipo', 'Plantio / semeadura'),
  ('GRAOS-TRATAMENTO_DE_SEMENTES', 'atividades.tipo', 'Tratamento de sementes'),
  ('GRAOS-INOCULACAO', 'atividades.tipo', 'Inoculação (soja/feijão)'),
  ('GRAOS-ADUBACAO_DE_PLANTIO', 'atividades.tipo', 'Adubação de plantio (sulco)'),
  ('GRAOS-REPLANTIO', 'atividades.tipo', 'Replantio'),
  ('GRAOS-AVALIACAO_DE_ESTANDE', 'atividades.tipo', 'Avaliação de estande'),
  ('GRAOS-ADUBACAO_DE_COBERTURA', 'atividades.tipo', 'Adubação de cobertura'),
  ('GRAOS-HERBICIDA_POS_EMERGENTE', 'atividades.tipo', 'Herbicida pós-emergente'),
  ('GRAOS-FUNGICIDA', 'atividades.tipo', 'Fungicida'),
  ('GRAOS-INSETICIDA', 'atividades.tipo', 'Inseticida'),
  ('GRAOS-APLICACAO_FOLIAR_MICRONUTRIENTES', 'atividades.tipo', 'Aplicação foliar / micronutrientes'),
  ('GRAOS-MONITORAMENTO_DE_PRAGAS_E_DOENCAS', 'atividades.tipo', 'Monitoramento de pragas e doenças'),
  ('GRAOS-CONTROLE_DE_DANINHAS_MANUAL', 'atividades.tipo', 'Controle de daninhas manual (escape)'),
  ('GRAOS-DESSECACAO_DE_PRE_COLHEITA', 'atividades.tipo', 'Dessecação de pré-colheita (feijão/soja)'),
  ('GRAOS-COLHEITA_MECANIZADA', 'atividades.tipo', 'Colheita mecanizada'),
  ('GRAOS-TRANSPORTE_AO_ARMAZEM', 'atividades.tipo', 'Transporte ao armazém'),
  ('GRAOS-PESAGEM', 'atividades.tipo', 'Pesagem'),
  ('GRAOS-AMOSTRAGEM_DE_UMIDADE_IMPUREZA', 'atividades.tipo', 'Amostragem de umidade / impureza'),
  ('GRAOS-SECAGEM_PRE_LIMPEZA', 'atividades.tipo', 'Secagem / pré-limpeza'),
  ('GRAOS-DESTRUICAO_DE_RESTOS_CULTURAIS', 'atividades.tipo', 'Destruição de restos culturais'),
  ('GRAOS-SEMEADURA_DE_COBERTURA', 'atividades.tipo', 'Semeadura de cobertura'),
  ('GRAOS-VAZIO_SANITARIO', 'atividades.tipo', 'Vazio sanitário (soja)'),
  ('PEC-CONTAGEM', 'pecuaria.eventos.tipo', 'Contagem'),
  ('PEC-SUPLEMENTACAO', 'pecuaria.eventos.tipo', 'Suplementação (sal mineral / proteinado / ração)'),
  ('PEC-CONFERENCIA_DE_AGUA_AGUADAS', 'pecuaria.eventos.tipo', 'Conferência de água / aguadas'),
  ('PEC-ROTACAO_DE_PASTO_ENTRADA_DE_LOTE', 'pecuaria.eventos.tipo', 'Rotação de pasto — entrada de lote'),
  ('PEC-ROTACAO_DE_PASTO_SAIDA_DE_LOTE', 'pecuaria.eventos.tipo', 'Rotação de pasto — saída de lote'),
  ('PEC-VACINACAO', 'pecuaria.eventos.tipo', 'Vacinação (especificar)'),
  ('PEC-VERMIFUGACAO', 'pecuaria.eventos.tipo', 'Vermifugação'),
  ('PEC-CONTROLE_DE_CARRAPATO_MOSCA_DO_CHIFRE', 'pecuaria.eventos.tipo', 'Controle de carrapato / mosca-do-chifre'),
  ('PEC-CURA_DE_BICHEIRA', 'pecuaria.eventos.tipo', 'Cura de bicheira'),
  ('PEC-CURA_DE_UMBIGO', 'pecuaria.eventos.tipo', 'Cura de umbigo'),
  ('PEC-TRATAMENTO_INDIVIDUAL', 'pecuaria.eventos.tipo', 'Tratamento individual (especificar)'),
  ('PEC-MORTALIDADE', 'pecuaria.eventos.tipo', 'Mortalidade (com causa)'),
  ('PEC-ESTACAO_DE_MONTA', 'pecuaria.eventos.tipo', 'Estação de monta'),
  ('PEC-IATF', 'pecuaria.eventos.tipo', 'IATF'),
  ('PEC-DIAGNOSTICO_DE_GESTACAO', 'pecuaria.eventos.tipo', 'Diagnóstico de gestação'),
  ('PEC-PARTO_NASCIMENTO', 'pecuaria.eventos.tipo', 'Parto / nascimento'),
  ('PEC-DESMAMA', 'pecuaria.eventos.tipo', 'Desmama'),
  ('PEC-MARCACAO_BRINCAGEM', 'pecuaria.eventos.tipo', 'Marcação / brincagem'),
  ('PEC-CASTRACAO', 'pecuaria.eventos.tipo', 'Castração'),
  ('PEC-APARTACAO', 'pecuaria.eventos.tipo', 'Apartação'),
  ('PEC-PESAGEM', 'pecuaria.eventos.tipo', 'Pesagem'),
  ('PEC-EMBARQUE_VENDA', 'pecuaria.eventos.tipo', 'Embarque / venda'),
  ('PEC-COMPRA_ENTRADA_DE_ANIMAIS', 'pecuaria.eventos.tipo', 'Compra / entrada de animais'),
  ('PEC-ROCADA', 'pecuaria.eventos.tipo', 'Roçada'),
  ('PEC-ADUBACAO_DE_PASTAGEM', 'pecuaria.eventos.tipo', 'Adubação de pastagem'),
  ('PEC-REFORMA_DE_PASTO', 'pecuaria.eventos.tipo', 'Reforma de pasto'),
  ('PEC-MANUTENCAO_DE_CERCA_COCHO_BEBEDOURO', 'pecuaria.eventos.tipo', 'Manutenção de cerca / cocho / bebedouro'),
  ('PEC-CONTROLE_DE_FORMIGA', 'pecuaria.eventos.tipo', 'Controle de formiga'),
  ('PEC-PARTO_NASCIMENTO', 'pecuaria.mov.tipo', 'Nascimento'),
  ('PEC-MORTALIDADE', 'pecuaria.mov.tipo', 'Morte'),
  ('PEC-DESMAMA', 'pecuaria.mov.tipo', 'Desmama'),
  ('PEC-ROTACAO_DE_PASTO_ENTRADA_DE_LOTE', 'pecuaria.mov.tipo', 'Mudança de pasto'),
  ('PEC-ROTACAO_DE_PASTO_SAIDA_DE_LOTE', 'pecuaria.mov.tipo', 'Mudança de pasto'),
  ('PEC-COMPRA_ENTRADA_DE_ANIMAIS', 'pecuaria.mov.tipo', 'Entrada'),
  ('PEC-EMBARQUE_VENDA', 'pecuaria.mov.tipo', 'Saída'),
  ('PEC-VACINACAO', 'pecuaria.massa.tipo', 'Vacinação'),
  ('PEC-VERMIFUGACAO', 'pecuaria.massa.tipo', 'Vermifugação'),
  ('PEC-CURA_DE_BICHEIRA', 'pecuaria.san.problema', 'Bicheira'),
  ('PEC-CONTROLE_DE_CARRAPATO_MOSCA_DO_CHIFRE', 'pecuaria.san.problema', 'Carrapato / mosca em excesso'),
  ('PEC-CONTAGEM', 'pecuaria.lotes', '*'),
  ('PEC-SUPLEMENTACAO', 'pecuaria.nut', '*'),
  ('PEC-IATF', 'pecuaria.rep.iatf', '*'),
  ('PEC-DIAGNOSTICO_DE_GESTACAO', 'pecuaria.rep.dg', '*')
on conflict (operacao_id, origem, termo) do nothing;
-- <<< seed gerado

-- 4. Índice de apoio em boletins (só se ainda não houver um em fazenda_id, data)
do $$
begin
  if not exists (
    select 1 from pg_indexes
    where schemaname = 'public' and tablename = 'boletins'
      and indexdef ~* '\(\s*fazenda_id\s*,\s*data\s*(desc|asc)?\s*\)') then
    create index boletins_fazenda_id_data on public.boletins (fazenda_id, data);
  end if;
end $$;

-- 5. Auxiliar: devolve o array do jsonb, ou vazio quando não é array
create or replace function public.dsr_lista(p jsonb) returns jsonb
language sql immutable as $$
  select case when jsonb_typeof(p) = 'array' then p else '[]'::jsonb end $$;

-- 6. Registros extraídos dos boletins: (unidade, data, origem, termo)
--    Uma linha por ocorrência; o termo é o texto exato gravado pelo app.
create or replace view public.vw_dsr_registros
with (security_invoker = true) as
with bol as (
  select public.rel_fz_atual(b.fazenda_id) as unidade_id, b.data::date as data, b.payload
  from public.boletins b
  where coalesce((b.payload ->> 'exemplo')::boolean, false) = false
)
select unidade_id, data, 'atividades.tipo' as origem, e ->> 'tipo' as termo
  from bol cross join lateral jsonb_array_elements(public.dsr_lista(payload -> 'atividades')) e
union all
select unidade_id, data, 'pecuaria.eventos.tipo', e ->> 'tipo'
  from bol cross join lateral jsonb_array_elements(public.dsr_lista(payload -> 'pecuaria' -> 'eventos')) e
union all
select unidade_id, data, 'pecuaria.mov.tipo', e ->> 'tipo'
  from bol cross join lateral jsonb_array_elements(public.dsr_lista(payload -> 'pecuaria' -> 'mov')) e
union all
select unidade_id, data, 'pecuaria.massa.tipo', e ->> 'tipo'
  from bol cross join lateral jsonb_array_elements(public.dsr_lista(payload -> 'pecuaria' -> 'massa')) e
union all
select unidade_id, data, 'pecuaria.san.problema', e ->> 'problema'
  from bol cross join lateral jsonb_array_elements(public.dsr_lista(payload -> 'pecuaria' -> 'san')) e
union all
select unidade_id, data, 'pecuaria.lotes', '*'
  from bol cross join lateral jsonb_array_elements(public.dsr_lista(payload -> 'pecuaria' -> 'lotes')) e
  where coalesce(public.rel_num(e ->> 'cabecas'), 0) > 0
union all
select unidade_id, data, 'pecuaria.nut', '*'
  from bol cross join lateral jsonb_array_elements(public.dsr_lista(payload -> 'pecuaria' -> 'nut')) e
  where coalesce(e ->> 'insumo', '') <> ''
union all
select unidade_id, data, 'pecuaria.rep.iatf', '*'
  from bol where coalesce(payload -> 'pecuaria' -> 'rep' ->> 'iatfEtapa', '') <> ''
union all
select unidade_id, data, 'pecuaria.rep.dg', '*'
  from bol where coalesce(public.rel_num(payload -> 'pecuaria' -> 'rep' ->> 'dgPrenhes'), 0) > 0
          or coalesce(public.rel_num(payload -> 'pecuaria' -> 'rep' ->> 'dgVazias'), 0) > 0;
comment on view public.vw_dsr_registros is
  'Ocorrências de operação extraídas de boletins.payload (unidade, data, origem, termo exato). Base da vw_dias_sem_registro.';

-- 7. A visão: uma linha por unidade ativa × operação ativa da atividade dela
create or replace view public.vw_dias_sem_registro
with (security_invoker = true) as
with unidades as (
  select u.id as unidade_id, a.atividade
  from public.rel_unidades u cross join lateral unnest(u.perfil) as a(atividade)
  where u.ativo
),
pares as (
  select u.unidade_id, u.atividade, c.id as operacao_id, c.fase, c.nome as operacao_nome, c.ordem
  from unidades u
  join public.operacao_catalogo c on c.atividade = u.atividade and c.ativo
),
ultimo as (
  select r.unidade_id, al.operacao_id, max(r.data) as data_ultimo_registro
  from public.vw_dsr_registros r
  join public.operacao_alias al on al.origem = r.origem and al.termo = r.termo
  where coalesce(r.termo, '') <> ''
  group by r.unidade_id, al.operacao_id
)
select
  p.unidade_id,
  p.operacao_id,
  p.atividade,
  p.operacao_nome,
  p.fase,
  u.data_ultimo_registro,
  case when u.data_ultimo_registro is null then null
       else (public.rel_hoje_brt() - u.data_ultimo_registro)::integer end as dias_sem_registro,
  (u.data_ultimo_registro is null) as nunca_registrado
from pares p
left join ultimo u on u.unidade_id = p.unidade_id and u.operacao_id = p.operacao_id;
comment on view public.vw_dias_sem_registro is
  'Dias sem registro por unidade × operação (Boletim NCNaves v59). dias_sem_registro = hoje (Brasília) − data do último registro; NULL e nunca_registrado = true quando nunca houve. Sem status/farol: a janela é decisão de outra camada.';

-- 8. Conferência (aparece na tela ao terminar)
select atividade,
  count(*)                                        as combinacoes,
  count(*) filter (where nunca_registrado)        as nunca_registradas,
  count(*) filter (where not nunca_registrado)    as com_registro,
  min(dias_sem_registro)                          as menor_dias,
  max(dias_sem_registro)                          as maior_dias
from public.vw_dias_sem_registro
group by atividade
order by atividade;
