# CAMPOS-LIVRES.md — mapa da digitação livre no app

Auditoria (v44) de todos os pontos em que o usuário digita livremente
um nome que poderia vir de uma lista. NADA aqui foi alterado — cada
item será decidido um a um pelo Nilo. A escolha de pivô da seção
💧 Irrigação JÁ FOI corrigida na v44 e saiu deste mapa.

Legenda de esforço: baixo = trocar input por lista já existente;
médio = exige cadastro/fonte nova simples; alto = exige modelo novo
(cadastro + vínculo entre telas).

## 1. Produtos e insumos

| # | Onde (seção / operação) | Risco de dado sujo | Fonte oficial da lista | Esforço |
|---|---|---|---|---|
| 1 | Produto/defensivo da receita — Grãos › Operações do dia (aplicações, trat. de sementes) e 💧 Irrigação › quimigação (campo "Produto", sugestões dl-prod) | ALTO: mesmo defensivo com 3 grafias impede fechar custo e rastrear carência | Cadastro de insumos do app (D.insumos) + ERP AgroGestão; o histórico do aparelho (D.insumosAprendidos) já sugere | Médio |
| 2 | Produto/vacina — Pecuária › evento sanitário ("Ex.: vacina aftosa, Ivermectina 1%") | ALTO: controle sanitário por produto vira texto solto | Cadastro de insumos + AgroGestão (compras) | Médio |
| 3 | Formulação de adubo — Grãos › adubação de plantio ("Ex.: 08-28-16") e cobertura ("Outro → Qual produto?") | MÉDIO: formulação errada distorce custo/ha | Lista fixa ADUBOS_SUGERIDOS já existe (hoje é só sugestão); completar pelo AgroGestão | Baixo |
| 4 | Inoculante — Grãos › inoculação | MÉDIO | Cadastro de insumos | Baixo |

## 2. Cultivar, máquina e prestador

| # | Onde | Risco | Fonte oficial | Esforço |
|---|---|---|---|---|
| 5 | Cultivar/híbrido — Grãos › plantio, replantio e trat. de sementes ("Ex.: M 8210, DKB 390") | ALTO: censo de plantio e ciclos dependem disso | Não existe fonte ainda (criar cadastro de cultivares por cultura; conferir se a iCrop entrega a cultura da parcela) | Médio |
| 6 | Máquina/colhedora própria — Grãos › colheita ("Nome / nº da máquina") e máquinas da atividade (café/grãos) | MÉDIO: já tem sugestão dl-maq + resolverMaq (código COD), mas aceita texto solto | Cadastro de máquinas do app (D.maquinas) — JÁ EXISTE; falta virar seletor | Baixo |
| 7 | Prestador terceirizado — Grãos › colheita ("De terceiro → Nome do prestador") | MÉDIO: mesmo prestador com várias grafias impede comparar preço/desempenho | Não existe fonte ainda (criar cadastro de prestadores; AgroGestão tem os fornecedores) | Médio |

## 3. Pessoas

| # | Onde | Risco | Fonte oficial | Esforço |
|---|---|---|---|---|
| 8 | Nome do responsável — cabeçalho do boletim ("Seu nome (ex.: João Batista)") e do boletim de pós-colheita | MÉDIO: painel por pessoa não fecha; o app já "lembra" o último nome do aparelho | Cadastro de usuários do app (D.usuarios) — existe mas quase vazio; folha do AgroGestão | Médio |
| 9 | Função "Outra (digitar)…" — Mão de obra por função | BAIXO: só quando foge do catálogo; polui o comparativo por função | Catálogos LISTA_FUNCOES / _GRAOS / _PECUARIA — JÁ EXISTEM (o campo livre é o escape) | Baixo |
| 10 | Motorista/placa — colheita café › remessa p/ outra fazenda, e Grãos › transporte (opcional) | BAIXO: campo opcional, não entra em relatório | Não existe fonte ainda (motoristas/frota) | Baixo |

## 4. Pecuária e pós-colheita (lotes)

| # | Onde | Risco | Fonte oficial | Esforço |
|---|---|---|---|---|
| 11 | Lote/categoria — Pecuária › lotes por pasto e eventos ("Ex.: recria 2024") | ALTO: sem lote padronizado não há acompanhamento de GMD/contagem entre dias | Não existe fonte ainda (criar cadastro de lotes por unidade; histórico do aparelho pode sugerir) | Alto |
| 12 | Pasto/retiro — Pecuária | — já é seletor (talhões tipo PASTO) — sem risco | — | — |
| 13 | Lote — Pós-colheita › terreiro ("saiu hoje?"), secador, tulha e benefício ("Ex.: Lote 06") | ALTO: o mesmo lote precisa amarrar terreiro → secador → tulha → benefício; hoje é texto em 4 lugares | Histórico do próprio app (lotes citados nos boletins anteriores da unidade); no futuro, cadastro de lotes | Alto |

## 5. Destinos

| # | Onde | Risco | Fonte oficial | Esforço |
|---|---|---|---|---|
| 14 | Armazém de destino — Grãos › colheita/transporte: os chips dizem a categoria ("Armazém de terceiro"), mas NÃO qual armazém | MÉDIO: sem o nome não se confere romaneio/contranota | Não existe fonte ainda (criar cadastro de armazéns/compradores; AgroGestão tem) | Médio |
| 15 | Destino/laboratório — Grãos › amostragem de solo ("Para onde vão as amostras") | BAIXO | Não existe fonte ainda (lista curta de laboratórios) | Baixo |

## 6. Fito (praga / doença / daninha)

| # | Onde | Risco | Fonte oficial | Esforço |
|---|---|---|---|---|
| 16 | Alvo — Grãos › monitoramento, catação de daninha e aplicações ("Toque e escolha ou escreva") | BAIXO/MÉDIO: já tem lista por cultura; o livre é escape | Catálogo do app (docs/catalogos-por-atividade.md) — JÁ EXISTE | Baixo |
| 17 | Praga/doença "Outra…" — seção Pragas e ocorrências ("Escreva o nome") | BAIXO: mesmo caso do item 16 | Catálogo do app | Baixo |

## 7. window.prompt remanescentes (caixas nativas)

| # | Onde | Risco | Fonte oficial | Esforço |
|---|---|---|---|---|
| 18 | Confirmar recebimento de remessa — tela inicial do gerente ("Quantas carretas chegaram?" + observação) | MÉDIO: número digitado em caixa nativa, sem teclado numérico nem validação | É número/observação, não nome — trocar por caixa do próprio app | Baixo |
| 19 | Novo plantio — Grãos › Talhões e ciclos: cultura escolhida digitando "1/2/3" e DATA digitada à mão | ALTO: data livre ("31/02", "hoje") quebra o ciclo do talhão | Culturas já são lista (CULTURAS_ANUAIS); data deve ser `<input type="date">` do app | Baixo |
| 20 | Cadastros (ADMIN) — criar talhão, máquina, insumo e usuário por sequência de prompts | MÉDIO: só o admin usa, mas grava direto no cadastro oficial (erro aqui contamina todas as listas) | Formulários do próprio app na tela Cadastros | Médio |

## Digitação livre legítima (não mexer)

Observações, pendências, "conte em poucas linhas" das ocorrências,
detalhes de problema da irrigação: são narrativa do dia, não têm
lista possível — ficam como estão.
