# Relatório 5 — Divergência gerente × iCrop (consolidado mensal)

Prompt salvo para o Cowork. Cadência: **mensal (o diário já sai no painel)**. Status na carteira
(`docs/relatorios.md`): PRONTO.

## Como usar (Nilo)

1. Ajuste as datas nas URLs abaixo (primeiro e último dia do mês).
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

Consolidar no mês as diferenças entre o que o gerente registrou no
boletim e o que a iCrop mediu, nas 4 fazendas irrigadas com iCrop:
rodou/não rodou × lâmina medida, lâmina informada × medida e chuva
digitada × pluviômetro da estação. Diferença é "para conferir",
nunca "erro".

## Período

Mês fechado: DE a ATE.

## Fontes

TABELA: boletins — fazendas com iCrop (café e grãos)
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/boletins?select=fazenda_id,data,payload&data=gte.DE&data=lte.ATE&fazenda_id=in.(f03c,f03g,f22c,f22g,f27,f33)&order=fazenda_id,data&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

TABELA: icrop_manejo — medição do mês
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/icrop_manejo?select=fazenda,equipamento,parcela,data,irrigacao_mm,precipitacao_mm,chuva_pluv:bruto->>chuva_pluviometro,probs:bruto->>problemas_irrigacao&data=gte.DE&data=lte.ATE&order=fazenda,data&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

## Como ligar as fontes

- iCrop "fazenda" contém "rio preto" → f03c/f03g; "vereda" → f22c/f22g;
  "floramil" → f33; "capoeira grande" → f27.
- Pivô: o número do equipamento da iCrop ("01") e o pivô do boletim
  ("Pivô 01", payload.irg[].nome) são o mesmo pivô.
- Boletim de café: payload.irr.status ("Rodou", "Rodou com problema",
  "Não rodou", vazio) e payload.irr.agua. Boletim de grãos:
  payload.irg[] com status, lamina (mm) e percent por pivô.
- Chuva: payload.clima.chuvaMm × precipitacao_mm (ou chuva_pluv).

## O que calcular, por fazenda e pivô

1. Dias "rodou" no boletim com irrigacao_mm = 0 na iCrop, e dias
   "não rodou" com irrigacao_mm > 0.
2. Soma mensal: lâmina informada (payload.irg[].lamina) × lâmina
   medida (irrigacao_mm); diferença em mm e %.
3. Chuva do mês: soma digitada × soma da estação, por fazenda; dias
   com diferença > 5 mm.
4. Dias sem boletim e dias sem medição (separar: "sem registro do
   gerente" e "sem medição iCrop" são coisas diferentes).

## Formato de saída

"Gerente × iCrop — MES/ANO". Tabela por fazenda/pivô (dias rodou×0 |
dias não rodou×>0 | mm informado | mm medido | dif %) e tabela de
chuva por fazenda (mm digitado | mm estação | dias divergentes).
Fechar com 3 linhas "O que conferir" (sem nomes de pessoas).

Ao terminar, liste em 3 linhas no fim: (1) tabelas usadas e período,
(2) o que ficou PENDENTE, (3) sugestão de verificação para a
Controladoria (sem cobrar gerente).

=== FIM DO PROMPT ===
