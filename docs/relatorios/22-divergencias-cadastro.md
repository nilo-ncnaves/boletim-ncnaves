# Relatório 22 — Divergências de cadastro

Prompt salvo para o Cowork. Cadência: **por censo (quando houver inventário novo)**. Status na carteira
(`docs/relatorios.md`): PRONTO.

## Como usar (Nilo)

1. Ajuste as datas nas URLs abaixo (sem período: fotografia de hoje; DE30 = hoje menos 30 dias, no formato AAAA-MM-DD).
2. Abra cada URL no Safari, selecione tudo, copie.
3. No Cowork, cole o prompt (tudo entre as linhas `=== PROMPT ===`),
   e logo abaixo de cada linha "TABELA: ..." cole o JSON copiado.
4. Envie. Guarde o resultado na pasta do mês.

=== PROMPT ===

Você é analista da Controladoria do Grupo LGS (agronegócio: café,
grãos e pecuária, Monte Carmelo/MG). Regras que não se discutem:
- Nunca inventar número. Todo valor sai dos dados colados abaixo; se
  faltar, escreva PENDENTE e diga o que falta.
- Relatório sóbrio, 1 página, padrão visual da casa: texto corrido
  curto e tabelas simples, sem emojis, sem gráficos decorativos, sem
  adjetivos. Números com separador brasileiro (1.234,5).
- Tom respeitoso com os gerentes: os dados são registros de campo,
  não provas contra ninguém. Diferença entre dito e medido é "para
  conferir", nunca "erro do gerente".
- Nunca ranquear gerentes ou unidades por desempenho fora da
  Diretoria. Este relatório vai para a Diretoria/Controladoria; ainda
  assim, apresente por ordem de fazenda, não por nota.
- Falta de registro é "sem registro", nunca "não fez".
- Nomes de produto do plano de safra só aparecem como referência
  ("previsto pelo agrônomo"), nunca com verbo "aplicar" nem dose.

## Tarefa

Cruzar os cadastros e apontar divergências: unidades e talhões do
app × cadastro mestre do plano (unidade_manejo/unidade_alias) ×
fazendas/parcelas da iCrop × fazendas da Solinftec × ERP AgroGestão
(exportação colada pelo Nilo, enquanto não há integração) ×
inventário/censo de campo (texto colado). Não corrigir nada: só
listar o que não bate e quem deve decidir.

## Fontes

TABELA: unidade_manejo — cadastro mestre (identidade = id/codigo)
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/unidade_manejo?select=id,codigo,fazenda_app,empresa,nome_plano,nome_curto,area_ha,irrigacao,status,ativo&order=fazenda_app,codigo&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

TABELA: unidade_alias — apelidos por sistema
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/unidade_alias?select=unidade_id,fazenda_app,sistema,alias,vigente_de,vigente_ate&order=fazenda_app,sistema,alias&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

TABELA: icrop_fazendas
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/icrop_fazendas?select=id_da_fazenda,nome&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

TABELA: icrop_parcelas
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/icrop_parcelas?select=id_fazenda,parcela&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

TABELA: solinftec_depara — pedaço do nome Solinftec → unidade do app
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/solinftec_depara?select=padrao,fazenda_id&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

TABELA: solinftec_diario — fazendas vistas nos últimos 30 dias (nome Solinftec × id do app)
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/solinftec_diario?select=fazenda_sol,fazenda_id&data=gte.DE30&limit=1000&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

CADASTRO DO APP (não está no banco): cole aqui a lista de unidades e
talhões do app (Escritório › Cadastros, ou o cadastro
docs/plano/2026-27/alias_app.json e ESTADO.md, seção Unidades).

ERP AGROGESTÃO: cole aqui a exportação de fazendas/talhões (nome,
área) — PENDENTE enquanto não houver.

INVENTÁRIO / CENSO: cole aqui o texto do censo de campo (o que está
plantado em cada pivô/talhão, áreas medidas).

## O que apontar

1. Fazenda em um sistema sem correspondente no outro (Solinftec com
   fazenda_id nulo; iCrop sem parcela ativa; unidade_manejo sem
   apelido app).
2. Nomes que não batem exatamente (regra do plano: nome de fazenda só
   é mapeado se idêntico; senão pergunta ao Nilo).
3. Áreas diferentes para o mesmo talhão (app × plano × ERP × censo),
   com a diferença em ha.
4. Talhões do app sem cultura/ciclo conhecido no censo.
5. Apelidos vencidos (vigente_ate preenchido) ainda em uso.

## Formato de saída

"Divergências de cadastro — DATA". Uma tabela por tipo de divergência
(item | app | plano | iCrop | Solinftec | ERP | censo | quem decide).
Fechar com "Perguntas para o Nilo/agrônomo" (lista curta) e PENDENTES.

Ao terminar, liste em 3 linhas no fim: (1) tabelas usadas e período,
(2) o que ficou PENDENTE, (3) sugestão de verificação para a
Controladoria (sem cobrar gerente).

=== FIM DO PROMPT ===
