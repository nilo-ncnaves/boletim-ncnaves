# Relatório 16 — Sanidade e monitoramento

Prompt salvo para o Cowork. Cadência: **semanal**. Status na carteira
(`docs/relatorios.md`): PRONTO.

## Como usar (Nilo)

1. Ajuste as datas nas URLs abaixo (segunda a domingo).
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
- Boletins antigos podem vir com id de fazenda antigo. De-para: f19 e
  f18 → f03c; f05, f15, f16 e f14 → f14c; f03 → f03c; f22 → f22c;
  f13 → f13c. Trate como a unidade atual.

## Tarefa

Consolidar o monitoramento de pragas, doenças e daninhas registrado
nos boletins (café e grãos): por fazenda e talhão, o que foi visto,
nível, ação registrada e há quantos dias o alvo está sendo visto sem
ação. Não recomendar produto; produtos do plano de safra só como
"previsto pelo agrônomo".

## Período

Semana: DE a ATE (para "dias até ação", use também as 3 semanas
anteriores: DE3 = DE − 21 dias).

## Fontes

TABELA: boletins — 4 semanas (monitoramento e ações)
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/boletins?select=fazenda_id,data,payload&data=gte.DE3&data=lte.ATE&fazenda_id=in.(f01,f03c,f03g,f13c,f14c,f20,f21,f22c,f22g,f23,f24,f27,f33,f35)&order=fazenda_id,data&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

TABELA: plano_fito_mes — alvos do mês previstos pelo agrônomo (referência)
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/plano_fito_mes?select=mes,fase,alvos,produtos&plano_id=is.null&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

## Onde estão os campos

- payload.fito[]: tipo (praga/doença/daninha), nome, talhaoId, nivel
  (Baixo/Médio/Alto), obs.
- Ações: payload.atividades[] com tipo "Pulverização", "Aplicação de
  herbicida", "Aplicação via drench / via solo", "Monitoramento de
  pragas (MIP)", "Fungicida", "Inseticida", "Herbicida pós-emergente";
  campos alvo, insumos[], talhaoId, data.
- payload.ocorrencias[] (tipo, grav, texto) para ocorrências ligadas a
  sanidade.

## O que calcular

1. Por fazenda e talhão: alvos vistos na semana, nível máximo, datas.
2. Para cada alvo com nível Médio/Alto: data da 1ª observação (nas 4
   semanas) e data da 1ª ação registrada no talhão; "dias até ação"
   ou "sem ação registrada" (nunca "não tratou").
3. Alvos previstos no mês pelo plano sem nenhum registro de
   monitoramento na fazenda: "sem registro de monitoramento".
4. Cobertura: talhões com MIP registrado na semana / talhões que
   tiveram registro no mês.

## Formato de saída

"Sanidade e monitoramento — semana DE a ATE". Tabela (fazenda |
talhão | alvo | nível | 1ª observação | ação registrada | dias até
ação) e lista "Alvos do mês sem registro" por fazenda. Fechar com 3
linhas de leitura para a Diretoria e o agrônomo.

Ao terminar, liste em 3 linhas no fim: (1) tabelas usadas e período,
(2) o que ficou PENDENTE, (3) sugestão de verificação para a
Controladoria (sem cobrar gerente).

=== FIM DO PROMPT ===
