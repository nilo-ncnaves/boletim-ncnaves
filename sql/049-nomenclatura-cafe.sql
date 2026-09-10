-- 049-nomenclatura-cafe.sql — Boletim NCNaves v76
-- Nomenclatura das atividades e funções do café na palavra de quem faz o serviço.
--
-- O QUE ESTE ARQUIVO FAZ (rodar UMA vez no SQL Editor do Supabase, projeto
-- syvehtgrbqteyuqhoban; é idempotente, pode rodar de novo sem estragar nada):
--   1. Regrava o catálogo de operações do café (operacao_catalogo) com os termos
--      novos e com o GRUPO por natureza na coluna `fase` — o mesmo agrupamento que
--      o gerente vê no seletor do boletim.
--   2. Acrescenta o DE-PARA em operacao_alias: o nome ANTIGO continua sendo apelido
--      da operação NOVA. É isso que faz boletim já lançado continuar somando.
--   3. Tira de cena (ativo = false, SEM APAGAR) as duas operações que foram
--      renomeadas 1 para 1.
--
-- O QUE ELE NÃO FAZ, DE PROPÓSITO:
--   * Não reescreve nenhum boletim. `boletins.payload` fica exatamente como foi
--      gravado no dia; quem traduz o nome é a leitura (o app, por DEPARA_NOMES, e as
--      visões, por operacao_alias).
--   * Não apaga linha nenhuma de operacao_catalogo nem de operacao_alias.
--   * Não decide o destino dos quatro termos antigos que se abriram em DOIS novos
--      ("Pulverização", "Aplicação de herbicida", "Capina roçadeira / trincha" e
--      "Irrigação"): eles ficam ATIVOS, com o histórico deles intacto, até o Nilo
--      dizer para onde cada um vai. Enquanto isso o app não os oferece em
--      lançamento novo, e o farol de registro segue mostrando a data real deles.
--
-- Espelho oficial: OPS_CAFE_GRUPOS e DEPARA_NOMES no index.html; o seed abaixo sai de
-- `node scripts/gerar_catalogo_operacoes.cjs` (mesmo bloco já recolado no sql/040).

begin;

-- 1 e 2. catálogo do café (termos novos, grupo em `fase`) + apelidos
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
  ('CAFE-MANUTENCAO_DE_ESTRADAS_E_ACEIROS', 'CAFE', 'Estrutura e apoio', 'Manutenção de estradas e aceiros', 26)

on conflict (id) do update set atividade = excluded.atividade, fase = excluded.fase, nome = excluded.nome, ordem = excluded.ordem, ativo = true;

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
  ('CAFE-PODA_MECANIZADA_ESQUELETAMENTO', 'atividades.tipo', 'Poda (decote/esqueletamento)')
on conflict (operacao_id, origem, termo) do nothing;

-- 3. as duas renomeadas 1 para 1 saem da lista de operações esperadas — sem apagar.
--    O apelido antigo ("Desbrota", "Poda / esqueletamento") agora pertence à operação
--    nova, então o histórico continua contando lá.
update public.operacao_catalogo set ativo = false
 where id in ('CAFE-DESBROTA', 'CAFE-PODA_ESQUELETAMENTO');

commit;

-- Conferência (aparece na tela ao terminar)
-- A primeira tabela deve mostrar: Tratos culturais 18 · Irrigação e fertirrigação 4 ·
-- Colheita e pós-colheita 3 · Estrutura e apoio 1 — e mais UMA linha de grupo vazio com 4,
-- que são justamente os quatro termos legados esperando a decisão do Nilo ("Pulverização",
-- "Aplicação de herbicida", "Capina roçadeira / trincha" e "Irrigação"). Eles continuam
-- ativos de propósito: é o que mantém o histórico deles somando no farol de registro.
select fase as grupo, count(*) as operacoes
  from public.operacao_catalogo
 where atividade = 'CAFE' and ativo
 group by fase
 order by min(ordem);

select c.nome as operacao_de_hoje, a.termo as nome_antigo_reconhecido
  from public.operacao_alias a
  join public.operacao_catalogo c on c.id = a.operacao_id
 where c.atividade = 'CAFE' and a.termo <> c.nome
 order by c.ordem;
