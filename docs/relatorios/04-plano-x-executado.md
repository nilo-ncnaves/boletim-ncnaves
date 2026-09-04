# Relatório 4 — Plano × executado do mês

Prompt salvo para o Cowork. Cadência: **semanal (parcial) e mensal (fechado)**. Status na carteira
(`docs/relatorios.md`): PRONTO.

## Como usar (Nilo)

1. Ajuste as datas nas URLs abaixo (primeiro e último dia do mês; MES = número do mês).
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

Comparar, para cada fazenda de café com plano vigente (v52), o que o
agrônomo previu para o mês (adubação, calagem, fito) com o que os
boletins registraram. Regra permanente: o plano é referência, não
receituário. O relatório diz "previsto × registrado"; nunca "faltou
aplicar". Fora da janela ainda aberta, o status é "em andamento".

## Período

Mês em análise: DE = 1º dia, ATE = último dia (ou hoje, no parcial).
MES = número do mês (1–12). Calagem tem janela própria
(janela_ini/janela_fim, normalmente 01/09 a 31/10).

## Fontes

Aviso (04/09/2026): as tabelas do plano só existem depois de rodar
sql/005-plano-safra.sql e sql/006-plano-safra-seed-2627.sql e de
publicar as versões vigentes (sql/007 ou a tela Unidades e Plano).
Enquanto isso as URLs de plano_* respondem 404 e o relatório fica
PENDENTE — ver pendências no ESTADO.md.

TABELA: plano_safra — versões vigentes
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/plano_safra?select=id,fazenda_app,safra,versao,vigente_de,aprovado_por&status=eq.vigente&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

TABELA: unidade_manejo — unidades do plano (identidade = id/codigo)
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/unidade_manejo?select=id,codigo,fazenda_app,nome_curto,area_ha,status&ativo=is.true&order=fazenda_app,codigo&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

TABELA: unidade_alias — apelido app (id do talhão no app) por unidade
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/unidade_alias?select=unidade_id,fazenda_app,alias&sistema=eq.app&vigente_ate=is.null&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

TABELA: plano_adubo_mes — adubação prevista no mês
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/plano_adubo_mes?select=plano_id,unidade_id,mes,insumo,kg,via&mes=eq.MES&order=unidade_id,insumo&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

TABELA: plano_calagem — calagem prevista
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/plano_calagem?select=plano_id,unidade_id,subarea,t_ha,t_total,rateado,janela_ini,janela_fim&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

TABELA: plano_fito_mes — calendário fito do grupo no mês
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/plano_fito_mes?select=plano_id,mes,fase,alvos,produtos,via_solo&mes=eq.MES&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

TABELA: plano_gantt — janelas e evidência esperada
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/plano_gantt?select=modelo,atividade,meses,tipo,evidencia_app&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

TABELA: boletins — registros do mês das fazendas de café do plano
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/boletins?select=fazenda_id,data,payload&data=gte.DE&data=lte.ATE&fazenda_id=in.(f01,f03c,f13c,f14c,f20,f22c,f23,f24)&order=fazenda_id,data&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

## Como ligar as fontes

- fazenda_app → id do app: "Água Limpa" f01, "Rio Preto-Lagamar — Café"
  f03c, "Mata Preta — Café" f13c, "Monte Carmelo — Café" f14c, "Lagamar
  Café (Rodrigo)" f20, "Vereda — Café" f22c, "Vereda Romaria" f23,
  "Vereda Café 5º e 6º" f24.
- Considere só plano_adubo_mes/plano_calagem cujo plano_id está em
  plano_safra com status vigente. Se uma fazenda não tiver plano
  vigente, escreva "sem plano vigente" e pule.
- unidade_alias (sistema app) liga unidade_id → talhaoId do boletim.
  Unidade sem apelido app: "sem ligação com talhão do app" (são 26
  conhecidas; não é falha do gerente).
- Evidência no boletim (payload.atividades[].tipo, por talhaoId):
  adubação = "Adubação via lanço", "Adubação orgânica" ou
  payload.irr.fert = "Sim" (fertirrigação, com irr.fertSetores);
  calagem = "Calagem / gessagem"; fito = "Pulverização", "Aplicação via
  drench / via solo", "Monitoramento de pragas (MIP)" e a seção
  payload.fito[] (tipo, nome, talhaoId, nivel). Insumos usados ficam em
  atividades[].insumos[] (nome, dose, qtd) e atividades[].receita.

## O que calcular

1. Adubação: por fazenda e unidade, insumos previstos no mês (kg) e
   se há registro de adubação/fertirrigação no período (data do 1º
   registro). Não comparar kg previsto com kg feito se o boletim não
   traz kg; escreva "kg realizado: não registrado no boletim".
2. Calagem: t previstas por subárea e se há "Calagem / gessagem"
   registrada dentro da janela. Antes de janela_fim: "em andamento".
3. Fito: alvos do mês × registros de MIP/pulverização/drench por
   fazenda; produtos citados no plano listados só como "previsto pelo
   agrônomo".
4. Gantt: para cada atividade cujo mês inclui MES, se há evidência
   (evidencia_app) em algum boletim da fazenda.

## Formato de saída

"Plano × registrado — MES/ANO (parcial até ATE)". Uma tabela por
fazenda: unidade | previsto (insumos/kg, calagem t, fito alvos) |
registro no boletim (data ou "sem registro") | situação (registrado /
em andamento / janela fechada sem registro / sem ligação). Fechar com
"Leituras para a Diretoria" (3 linhas) e pendências de cadastro.

Ao terminar, liste em 3 linhas no fim: (1) tabelas usadas e período,
(2) o que ficou PENDENTE, (3) sugestão de verificação para a
Controladoria (sem cobrar gerente).

=== FIM DO PROMPT ===
