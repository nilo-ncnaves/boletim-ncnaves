# Relatório 7 — Máquinas dito × Solinftec

Prompt salvo para o Cowork. Cadência: **diário no painel; consolidado semanal no Cowork**. Status na carteira
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

Comparar, por fazenda e dia, as máquinas apontadas nos boletins
(horas e combustível por atividade) com a telemetria Solinftec
(horas, motor ligado/ocioso, área, litros, operação, talhão).

## Período

Semana: DE a ATE.

## Fontes

TABELA: boletins — todas as unidades
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/boletins?select=fazenda_id,data,payload&data=gte.DE&data=lte.ATE&order=fazenda_id,data&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

TABELA: solinftec_diario
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/solinftec_diario?select=fazenda_sol,fazenda_id,data,equipamento,cd_operacao,operacao,talhao,horas,motor_h,ocioso_h,area_ha,consumo_l&data=gte.DE&data=lte.ATE&order=fazenda_id,data,equipamento&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

## Como ligar as fontes

- Máquinas no boletim: payload.atividades[].maquinas[] (nome, horas,
  comb) ligadas ao tipo da atividade e ao talhaoId.
- Solinftec: fazenda_id é o id do app; linha com fazenda_id nulo =
  fazenda sem de-para (listar em "cadastro"). Máquinas pertencem à
  fazenda física: some as unidades irmãs (f03c+f03g, f22c+f22g,
  f13c+f13p, f14c+f14p) antes de comparar.
- "Operação NNN" = código sem nome no de-para; listar os códigos
  vistos.

## O que calcular

1. Por fazenda física e dia: horas apontadas × horas Solinftec;
   diferença > 30% ou máquina medida sem boletim = "para conferir".
2. Por equipamento: horas, motor ocioso % (ocioso_h/motor_h), área,
   litros/hora.
3. Operações registradas na Solinftec sem atividade correspondente no
   boletim (e o inverso).
4. Fazendas/equipamentos sem de-para ou sem nome de operação.

## Formato de saída

"Máquinas: boletim × Solinftec — semana DE a ATE". Tabela por fazenda
(dia | h boletim | h Solinftec | dif | obs), tabela por equipamento
(h | ocioso % | ha | L | L/h) e lista "Cadastro a ajustar". Fechar
com 3 linhas de leitura, sem culpar apontador ou gerente.

Ao terminar, liste em 3 linhas no fim: (1) tabelas usadas e período,
(2) o que ficou PENDENTE, (3) sugestão de verificação para a
Controladoria (sem cobrar gerente).

=== FIM DO PROMPT ===
