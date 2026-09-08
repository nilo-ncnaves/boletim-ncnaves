# Catálogos por atividade — fonte oficial do vocabulário

> **Termos acrescentados pelo escritório (v56).** Em Cadastros › Catálogos
> o ADMIN pode acrescentar termos em funções (mão de obra), operações
> (café: LISTA_ATIV; grãos: fase "Outras (cadastro do escritório)") e
> pragas/doenças/daninhas de café e grãos. Eles ficam em
> `D.catalogoExtra` no aparelho (sincronizam junto com os dados) e
> entram no fim das listas do gerente daquela atividade. Este arquivo
> descreve só o vocabulário padrão do código; termos extras são locais
> e não constam aqui.


> **Espelho no Supabase (v59).** As operações deste catálogo também
> vivem na tabela `operacao_catalogo` (id imutável + apelidos em
> `operacao_alias`), usada pela visão `vw_dias_sem_registro`
> (`sql/040-dias-sem-registro.sql`). O seed é gerado por
> `scripts/gerar_catalogo_operacoes.cjs` a partir das constantes do
> `index.html` — mudou operação aqui e no código? Rode o script e recole
> o trecho marcado do `sql/040`. Detalhes em `docs/relatorios.md`.

Este arquivo é a especificação oficial das operações e dos campos do
boletim, por atividade. O código (index.html) implementa EXATAMENTE
o que está aqui — nem mais, nem menos. Mudou aqui? Muda no código no
mesmo pull request (e vice-versa).

---

## GRÃOS (soja, milho comercial, feijão)

### Princípios de tela
- Seções nascem FECHADAS.
- Em "Operações do dia", o funcionário toca "＋ operação" e escolhe
  num seletor AGRUPADO POR FASE (Pré-plantio / Plantio / Condução /
  Colheita / Pós-colheita), com as fases recolhidas — toca na fase e
  ela mostra só as operações dela.
- Escolhida a operação, aparecem SOMENTE os campos daquela operação.
- O seletor é filtrado pela cultura do ciclo ativo do talhão:
  operação de soja não aparece em milho e vice-versa (marcações
  [soja], [feijão], [milho] abaixo).
- Cabeçalho do registro: "Talhão · Cultura · X dias após plantio".
- Botão "repetir última operação deste talhão".
- Irrigação NÃO é operação: vive na seção 💧 Irrigação.

### Bloco-padrão APLICAÇÃO
Usado por toda operação de pulverização:
- Alvo (lista de pragas/doenças/daninhas da cultura)
- Receita: 1..n produtos (nome, dose/ha, unidade L / kg / mL / g)
- Calda (L/ha)
- Área (ha) — pré-preenchida com a área do talhão, editável
- Equipamento: autopropelido / barra / avião / quimigação via pivô /
  costal
- Condição: vento (ok / forte) e período (manhã / tarde / noite)

### PRÉ-PLANTIO
| Operação | Campos |
|---|---|
| Dessecação de pré-plantio | bloco APLICAÇÃO |
| Calagem | produto (calcário calcítico / dolomítico), dose (t/ha), área, incorporado (sim/não) |
| Gessagem | dose (t/ha), área |
| Gradagem / preparo de solo | implemento (grade / subsolador / niveladora), área, observação |
| Manejo da palhada | método (rolo-faca / triturador / roçadora), área, observação |
| Amostragem de solo | profundidade (0-20 / 20-40 / ambas), nº de amostras, destino/laboratório |

### PLANTIO
| Operação | Campos |
|---|---|
| Tratamento de sementes | produto(s) + dose por 100 kg de sementes, cultivar tratada, quantidade (kg ou sacas) |
| Inoculação [soja][feijão] | produto, dose, quantidade de sementes |
| Plantio / semeadura | cultivar/híbrido, população (sementes/m OU mil plantas/ha), espaçamento (cm), área plantada (ha); ao concluir, o app oferece "abrir/atualizar ciclo" com a data |
| Adubação de plantio (sulco) | formulação (texto, ex.: 08-28-16), dose (kg/ha), área |
| Replantio | área, motivo (falha de estande / chuva / praga), cultivar |
| Avaliação de estande | plantas/m encontradas, pontos avaliados, decisão (ok / replantar) |

### CONDUÇÃO
| Operação | Campos |
|---|---|
| Adubação de cobertura | produto (ureia / KCl / outro), dose (kg/ha), área, forma (lanço / via pivô) |
| Herbicida pós-emergente | bloco APLICAÇÃO |
| Fungicida | bloco APLICAÇÃO |
| Inseticida | bloco APLICAÇÃO |
| Aplicação foliar / micronutrientes | bloco APLICAÇÃO |
| Monitoramento de pragas e doenças | alvo, nível (baixo/médio/alto) ou contagem por ponto, decisão (aplicar / aguardar / reavaliar em X dias) |
| Controle de daninhas manual (escape) | alvo, área, nº de pessoas |

Irrigação NÃO aparece aqui — é seção própria (💧 Irrigação).

### COLHEITA
| Operação | Campos |
|---|---|
| Dessecação de pré-colheita [feijão][soja] | bloco APLICAÇÃO |
| Colheita mecanizada | área colhida (ha); produção (sacas 60 kg OU kg); umidade (%); impureza (%); máquina: própria (nome/número) OU de terceiro (nome do prestador); destino: Armazém próprio da fazenda / Armazém Geral NC Naves / Armazém de terceiro / Entrega direta (comprador); nº de cargas. Ao atingir a área total do talhão, o app oferece "encerrar ciclo" |
| Transporte ao armazém | nº de cargas, destino (mesmas opções), placa/motorista (opcional) |
| Pesagem | nº do ticket, peso líquido (kg), local |
| Amostragem de umidade / impureza | umidade (%), impureza (%), local |
| Secagem / pré-limpeza | local, umidade de entrada (%), umidade de saída (%), quebra (%) |

### PÓS-COLHEITA
| Operação | Campos |
|---|---|
| Destruição de restos culturais | método (roçada / gradagem / herbicida), área; se herbicida, bloco APLICAÇÃO |
| Semeadura de cobertura | espécie (braquiária / milheto / outra), dose (kg/ha), área |
| Vazio sanitário [soja] | registro simples: talhão, data de início, observação |

### 💧 IRRIGAÇÃO (seção obrigatória em toda unidade de grãos)
Aparece em TODAS as unidades de grãos — Floramill, Capoeira Grande,
Porto Buriti, Vereda — Grãos e Rio Preto-Lagamar — Grãos —
independentemente de haver dados da iCrop.

Lista de pivôs da unidade:
1. Equipamentos que a iCrop entrega para a fazenda (excluindo os com
   "café" no nome, que pertencem à unidade Café);
2. MAIS cadastro local: botão "＋ pivô/equipamento" (nome livre,
   ex.: "Pivô 01"), guardado por unidade — para fazendas sem iCrop
   (ex.: Porto Buriti) ou com pivô fora dela.

Por pivô, no dia:
- Status: rodou / não rodou / parcial / manutenção
- Lâmina (mm) OU percentímetro (%)
- Quimigação/fertirrigação via pivô (produto + dose, só se acionado)
- Problemas: energia / bomba / torre / vazamento

Abaixo da lista, o cartão "💧 iCrop — medição automática do dia"
quando houver dados; o cinto de segurança do envio compara
informado × medido por pivô.

### MILHO SEMENTE = ÁREA ARRENDADA
As áreas de milho semente são arrendadas a sementeiras (ex.:
Pioneer). Talhões tipo ARRENDADO aparecem na lista com a etiqueta
"Arrendado — sementeira", SEM operações, SEM irrigação, SEM colheita;
apenas ocorrência livre opcional. Ciclos não se aplicam a eles.
Não existem operações de campo de semente (despendoamento, roguing,
isolamento, vistorias) em nenhum catálogo.

### Ocorrências (grãos)
Quebra de máquina · Falta de insumo · Chuva impediu aplicação ·
Atraso de operação · + lista geral do app.

### Sugestões fitossanitárias (grãos)
- Pragas: percevejo-marrom (soja), lagarta Spodoptera/Helicoverpa,
  mosca-branca, cigarrinha-do-milho (enfezamento), lagarta-do-cartucho
  (milho), percevejo-barriga-verde (milho), vaquinha (feijão),
  nematoides, formiga, ataque de pássaros/javali.
- Doenças: ferrugem-asiática (soja), mofo-branco, oídio, antracnose,
  mancha-branca (milho), helmintosporiose (milho), ferrugem-polissora
  (milho), grãos ardidos (milho), mancha-angular (feijão),
  crestamento bacteriano (feijão), mosaico-dourado (feijão).
- Daninhas: buva (resistente), capim-amargoso (resistente), caruru,
  trapoeraba, picão-preto.
As listas são filtradas pela cultura do ciclo do talhão.

---

## CAFÉ
Catálogo original do app (LISTA_ATIV, LISTA_FUNCOES, SUGESTAO_FITO)
— INTOCADO por este redesenho.

## PECUÁRIA (módulo de campo — v50)

### Princípios de tela
- Uma seção 🐂 Pecuária no boletim, com SUB-ACORDEÕES fechados por
  padrão: o capataz abre só o que teve movimento. Dia parado = tudo
  fechado, nada no resumo. Meta: preencher em até 3 minutos.
- Chips grandes, teclado numérico, mínimo de digitação. Linguagem do
  campo: cabeça, cocho, sal, berro, bicheira.
- Retiros/pastos (v51): os selects "Pasto / retiro" listam o cadastro
  PASTOS_POR_FAZENDA do index.html — nomes reais de pasto por fazenda
  (já cadastradas: Mata Preta, Água Santa e Cracrá). Fazenda ainda sem
  lista mostra só "Selecione…" e "Outro…"; "Outro…" abre campo de
  texto livre e o texto digitado é o valor salvo. Para incluir uma
  fazenda, basta acrescentar a chave dela na constante. Boletins
  antigos gravados com id de talhão continuam abrindo normalmente.
- Categorias animais padronizadas em TODO o módulo
  (CATEGORIAS_ANIMAIS): bezerro(a) mamando, desmamado(a), garrote,
  novilha, boi magro, boi gordo, vaca, vaca descarte, touro.
- Confinamento: fora do módulo por decisão de escopo (as fazendas do
  grupo engordam a pasto). Se um dia entrar, vira sub-acordeão novo.

### 📋 Movimentação do rebanho
Cada movimento = um lançamento (tipo + categoria + qtd +
origem/destino + observação). Tipos (PEC_MOV_TIPOS) e campos:
| Tipo | Campos |
|---|---|
| Nascimento | qtd, parto (normal/assistido), sexo da cria (macho/fêmea), pasto — tudo opcional além da qtd |
| Morte | categoria, qtd, causa (doença, acidente, cobra, raio, atolamento, desconhecida, outra), brinco, pasto |
| Desmama | qtd, pasto de origem → pasto de destino |
| Mudança de pasto | categoria, qtd, origem → destino |
| Entrada | como entrou (compra / transferência do grupo), categoria, qtd, de onde veio, pasto de destino |
| Saída | como saiu (venda / abate / transferência do grupo), categoria, qtd, para onde foi, pasto de origem |

Contador do dia por tipo no cabeçalho do sub-acordeão
("2 nascimentos · 1 morte") para conferência antes de enviar.

### 💉 Sanidade
- Animal/lote tratado: categoria · qtd OU brinco · problema
  (PEC_PROBLEMAS_SAN: bicheira, pneumonia, diarreia, casco, olho,
  carrapato/mosca em excesso, outro + campo livre) · o que fez
  (PEC_ACOES_SAN: medicou, vacinou, everminou, curou, apartou p/
  enfermaria) · produto (texto curto, com sugestões do datalist)
  · observação.
- Vacinação/vermifugação em massa (PEC_MASSA_TIPOS): tipo, categoria,
  qtd, produto.

### 🐄 Reprodução (cria)
Touros no pasto? (sim/não + em quais retiros) · coberturas vistas
(berro, qtd) · etapa de IATF do dia (PEC_IATF_ETAPAS: implante D0,
retirada, inseminação, ressincronização, outra) + vacas no dia ·
diagnóstico de gestação (prenhes / vazias) · ocorrência com touro
(PEC_OCOR_TOURO: OK, brigou, machucou, manqueira + campo livre).

### 🧂 Cocho e nutrição
- Por pasto/lote: repôs no cocho (PEC_COCHO_INSUMOS: sal mineral,
  sal proteinado, ração, silagem/volumoso) + qual produto + quanto
  (sacos ou kg) · situação do cocho (PEC_LEITURA_COCHO: vazio,
  lambido, com sobra) · água/aguadas (PEC_AGUA_SIT: OK, baixa,
  problema bomba/bebedouro).
- Resumo rápido da fazenda inteira (um toque, herdado da v41):
  cocho / sal / água = OK ou Problema + observação.

### 🐮 Contagem por lote/pasto (herdada da v41)
Pasto + lote/categoria + cabeças contadas; total no cabeçalho.

### 🌱 Pasto e estrutura
Condição do pasto (PEC_CONDICAO_PASTO: sobrando, no ponto,
apertando, crítico) · cerca/porteira com problema (texto: qual
pasto) · visita na fazenda (PEC_VISITAS: veterinário, comprador,
fiscal, outra + quem/o quê). Chuva fica na seção Clima e equipe na
Mão de obra — sem duplicação.

### 🔧 Outros manejos (catálogo herdado — OPS_PECUARIA_FASES)
Pesagem, marcação/brincagem, castração, apartação, embarque/venda,
roçada, adubação de pastagem etc., com campos em cascata (sanitário:
produto + dose/cabeça; pesagem: peso médio; venda/compra: valor e
contraparte). Botão "usar o último lançamento".

### 📝 Observações de pecuária
Campo livre; sempre entra no resumo quando preenchido.

### Resumo WhatsApp — bloco 🐂 PECUÁRIA
Só aparece se algo foi preenchido; toda linha preenchida entra:
cabeçalho com o contador do dia; 📋 um movimento por linha;
💉 sanidade e manejos em massa; 🐄 reprodução; 🧂 cocho por pasto e
resumo rápido; 🐮 contagem; 🌱 pasto/cerca/visitas; 🔧 outros
manejos; 📝 observações.

### Sincronização
A pecuária vai dentro do payload do boletim (tabela boletins, como
sempre) E espelhada na tabela boletim_pecuaria
(sql/004-boletim-pecuaria.sql), item t:"pec" da mesma fila offline.
A visão pecuaria_movimentos abre um movimento por linha para o ERP
AgroGestão.

---

## Cabeçalho contextual — unidade operacional e ciclo por atividade (v66)

Vocabulário que o componente único `cabecalhoContexto` do index.html
usa, por chave de atividade (constante `CTX_ATIVIDADE`; nunca
condicional por atividade na tela). A unidade operacional das telas
de leitura é a mesma nas três atividades — fazenda física + atividade
(`fazendaMae` + `perfil`), identificada pelo id da fazenda — e a
subdivisão de campo (o ONDE do apontamento) NÃO entra no cabeçalho,
porque nenhuma tela de leitura é por subdivisão.

| Atividade | Linha 1 (sempre) | Subdivisão de campo (só no apontamento) | Linha 2: ciclo / safra |
|---|---|---|---|
| ☕ Café | Fazenda › Café (área ha) | talhão / setor | **nenhum** — café perene; o app não modela safra de café (o plano do agrônomo tem "safra 2026/27", mas é referência, não safra operacional: não vira rótulo) |
| 🌾 Grãos | Fazenda › Grãos (área ha) | talhão / pivô | "ciclo: Feijão, Soja" — culturas dos ciclos ativos dos talhões (`D.ciclos` por `talhaoId`, rótulo por `rotuloCultura`); sem ciclo ativo, nada. Não existe safra nem época (verão/safrinha/inverno) modelada — não inventar |
| 🐂 Pecuária | Fazenda › Pecuária (área ha) | pasto / retiro | **nenhum** — pecuária a pasto não tem safra |

Área = soma dos talhões cadastrados na unidade (sem ESTRUTURA e sem
ARRENDADO), `1.234,56 ha`; sem área o parêntese some. Depois da linha
2 do catálogo vem o texto próprio da tela (papel, data, período).

## Categorias de operação — badge de uma letra (v67)

Fonte oficial das categorias (natureza da operação) e das letras que o
componente único `badgeCategoria(atividade, {id | nome})` do index.html
mostra nas listas de leitura (constante `OP_CATEGORIAS`; espelho
opcional no Supabase em `sql/046-operacao-categoria.sql`, gerado por
`scripts/gerar_categorias_operacoes.cjs`). A decisão mora aqui: mudou a
tabela? Muda a constante no mesmo pull request (o script confere).

Regras (CLAUDE.md, item c6): no máximo 5 categorias por atividade;
letra única dentro da atividade, sempre presente no nome; a letra é
ATRIBUTO da categoria, nunca derivada do nome; a operação liga-se à
categoria pelo id do catálogo (`operacao_catalogo.id`, o mesmo do
sql/040) — em grãos e pecuária pela FASE do catálogo, que já é a
natureza da operação; nenhuma categoria é classe de agroquímico
(herbicida, inseticida, fungicida, adubo — vocabulário do Sigma que
NÃO foi copiado); fundo neutro único, sem cor por categoria (a cor é
canal do farol). Operação sem categoria ("Outra", termo acrescentado
pelo escritório) não tem badge.

### ☕ Café — PROPOSTA (pendente de aprovação do Nilo)
O catálogo do café (LISTA_ATIV) não tem fase; as 5 categorias abaixo
são proposta desta entrega e podem ser trocadas antes do merge (só
dados: `OP_CATEGORIAS.CAFE` e esta tabela).

| Letra | Categoria | Operações (LISTA_ATIV) |
|---|---|---|
| **C** | Colheita | Colheita · Catação · Repasse |
| **A** | Aplicação (natureza: levar insumo à lavoura, qualquer produto) | Pulverização · Aplicação de herbicida · Adubação via lanço · Adubação orgânica · Aplicação via drench / via solo · Calagem / gessagem |
| **T** | Trato cultural (manejo da planta e do solo, manual ou mecânico) | Capina manual · Capina roçadeira / trincha · Arruação / esparramação de cisco · Desbrota · Poda / esqueletamento · Plantio / renovação |
| **M** | Monitoramento | Monitoramento de pragas (MIP) |
| **I** | Irrigação e infraestrutura | Irrigação · Limpeza do sistema de irrigação · Manutenção de estradas e aceiros |

"Outra": sem categoria, sem badge.

### 🌾 Grãos — categoria = fase do catálogo (OPS_GRAOS_FASES)
| Letra | Categoria (fase) | Operações |
|---|---|---|
| **R** | Pré-plantio (p**R**é) | Dessecação de pré-plantio · Calagem · Gessagem · Gradagem / preparo de solo · Manejo da palhada · Amostragem de solo |
| **P** | Plantio | Plantio / semeadura · Tratamento de sementes · Inoculação · Adubação de plantio (sulco) · Replantio · Avaliação de estande |
| **D** | Condução (con**D**ução) | Adubação de cobertura · Herbicida pós-emergente · Fungicida · Inseticida · Aplicação foliar / micronutrientes · Monitoramento de pragas e doenças · Controle de daninhas manual (escape) |
| **C** | Colheita | Dessecação de pré-colheita · Colheita mecanizada · Transporte ao armazém · Pesagem · Amostragem de umidade / impureza · Secagem / pré-limpeza |
| **S** | Pós-colheita (pó**S**) | Destruição de restos culturais · Semeadura de cobertura · Vazio sanitário |

Pré-plantio, Condução e Pós-colheita não podem usar a inicial (P e C
já são de Plantio e Colheita): a letra escolhida é a segunda/terceira
do nome, como manda a regra "letra que apareça no nome". "Outras
(cadastro do escritório)": sem categoria, sem badge.

### 🐂 Pecuária — categoria = grupo do catálogo (OPS_PECUARIA_FASES)
| Letra | Categoria (grupo) | Operações |
|---|---|---|
| **D** | Manejo diário | Contagem · Suplementação · Conferência de água / aguadas · Rotação de pasto (entrada e saída de lote) |
| **S** | Sanitário | Vacinação · Vermifugação · Controle de carrapato / mosca-do-chifre · Cura de bicheira · Cura de umbigo · Tratamento individual · Mortalidade |
| **R** | Reprodutivo | Estação de monta · IATF · Diagnóstico de gestação · Parto / nascimento · Desmama |
| **L** | Manejo de lote | Marcação / brincagem · Castração · Apartação · Pesagem · Embarque / venda · Compra / entrada de animais |
| **P** | Pastagem e estrutura | Roçada · Adubação de pastagem · Reforma de pasto · Manutenção de cerca / cocho / bebedouro · Controle de formiga |

Onde o badge aparece (v67): Diretoria › Faróis › unidade (todas as
operações da unidade, pelo id da visão) e boletim enviado (cartão
"Atividades" / "Operações do dia" do café e grãos; "Outros manejos" da
pecuária), pelo nome exato gravado no boletim. Onde NÃO aparece, por
desenho: apontamento em 3 passos; resumo de uma linha do boletim
(casa do gerente e painel — é resumo, não lista de operações);
movimentação, sanidade e manejo em massa da pecuária (blocos próprios,
cada um de uma natureza só); Cadastros › Catálogos (grãos e pecuária já
listam por fase — uma categoria por bloco; café mantido igual).

## Seções do boletim: eventual × esperada (v69)

Fonte oficial da classificação das seções do boletim diário, por
atividade, que alimenta o catálogo `SECOES_BOLETIM` do index.html e a
tabela `boletim_secao` do Supabase (`sql/047-secao-resposta.sql`). Os
três nunca divergem: mudou aqui, muda nos dois no mesmo pull request.
Classificação confirmada pelo Nilo em 08/09/2026 (decisão de negócio,
não técnica).

- **Eventual** — a seção registra eventos que legitimamente podem não
  acontecer num dia. Sem registro, o cartão oferece os dois chips
  **"Nada a registrar hoje" · "Registrar…"**: um toque grava a resposta
  explícita de ausência (`rascunho.secoes[id]`, com autor e hora) e
  recolhe o cartão; o 2º toque desfaz. A resposta declara que não há o
  que registrar — nunca que "está tudo bem" (regra 5 dos faróis).
- **Esperada** — execução esperada no dia (clima, equipe, operações,
  irrigação, cocho…). Não recebe os chips: a ausência ali é assunto do
  farol de leitura (dias sem registro, janela), nunca da tela de
  entrada. Aplicar nos dois lugares confundiria os conceitos.

A identidade é o `id` (chave substituta imutável, mesmo padrão de
`operacao_catalogo`); o nome é só rótulo. `campos` = listas do payload
cujo tamanho conta como registro (o mesmo cálculo no app,
`secaoRegistros`, e no banco, `boletim_secao_registros`). O rótulo do
2º chip (`acao`) é vocabulário por chave — nunca condicional por
atividade na tela.

| id | Atividade | Seção (cartão do boletim) | Tipo | campos (registro) | 2º chip |
|---|---|---|---|---|---|
| CAFE-CLIMA | ☕ Café | Clima do dia | esperada | — | — |
| CAFE-MO | ☕ Café | Mão de obra | esperada | — | — |
| CAFE-IRR | ☕ Café | Irrigação (gotejo) | esperada (já tem "Dia sem irrigação") | — | — |
| CAFE-ATIV | ☕ Café | Atividades por talhão | esperada | — | — |
| CAFE-COLHEITA | ☕ Café | Colheita | esperada (sazonal: fora da safra não há o que responder) | — | — |
| **CAFE-FITO** | ☕ Café | Pragas, doenças e daninhas | **eventual** | fito | Registrar ocorrência |
| **CAFE-OCOR** | ☕ Café | Ocorrências gerais | **eventual** | ocorrencias | Registrar ocorrência |
| CAFE-OBS | ☕ Café | Observações e pendências | esperada (texto livre) | — | — |
| GRAOS-CLIMA | 🌾 Grãos | Clima do dia | esperada | — | — |
| GRAOS-MO | 🌾 Grãos | Mão de obra | esperada | — | — |
| GRAOS-OPER | 🌾 Grãos | Operações do dia | esperada | — | — |
| GRAOS-IRG | 🌾 Grãos | Irrigação (pivôs) | esperada (já tem "Não rodou" por pivô) | — | — |
| **GRAOS-FITO_OCOR** | 🌾 Grãos | Pragas, doenças e ocorrências (um cartão, duas listas; UMA resposta por cartão — decisão do Nilo) | **eventual** | fito + ocorrencias | Registrar ocorrência (aciona "＋ ocorrência") |
| GRAOS-OBS | 🌾 Grãos | Observações e pendências | esperada | — | — |
| PEC-CLIMA | 🐂 Pecuária | Clima do dia | esperada | — | — |
| PEC-MO | 🐂 Pecuária | Mão de obra | esperada | — | — |
| **PEC-MOV** | 🐂 Pecuária | Pecuária › Movimentação do rebanho | **eventual** | pecuaria.mov | Registrar movimento |
| **PEC-SAN** | 🐂 Pecuária | Pecuária › Sanidade | **eventual** | pecuaria.san + pecuaria.massa | Registrar tratamento |
| PEC-REP | 🐂 Pecuária | Pecuária › Reprodução | esperada (formulário de estado) | — | — |
| PEC-NUT | 🐂 Pecuária | Pecuária › Cocho e nutrição | esperada (trato diário) | — | — |
| PEC-CONT | 🐂 Pecuária | Pecuária › Contagem por lote / pasto | esperada | — | — |
| PEC-PASTO | 🐂 Pecuária | Pecuária › Pasto e estrutura | esperada (formulário de estado) | — | — |
| PEC-MANEJO | 🐂 Pecuária | Pecuária › Outros manejos | esperada (pelo farol de leitura; opção "Outros manejos eventual" não escolhida) | — | — |
| PEC-OBSPEC | 🐂 Pecuária | Pecuária › Observações de pecuária | esperada (texto livre) | — | — |
| **PEC-OCOR** | 🐂 Pecuária | Ocorrências e sanidade | **eventual** | ocorrencias | Registrar ocorrência |
| PEC-OBS | 🐂 Pecuária | Observações e pendências | esperada | — | — |

Estados do cabeçalho do cartão eventual (componente único
`resumoSecaoHtml` / `chipsRespostaSecao` / `pintarSecoesResposta`):
"sem resposta" (não respondido — texto neutro desde a v70, cinza
`--tinta-2`, sem cobrança),
"sem ocorrência" (respondido — cinza) e "N registros" (verde, como
sempre; Movimentação mantém o contador próprio "2 nascimentos · 1
morte"). Registro e "sem ocorrência" nunca coexistem: adicionar um
registro apaga a resposta (`limparRespostasSecao`), no app e no banco.
Sem ação em massa, sem modal, sem campo novo de digitação.

## Termos exclusivos por atividade (checagem de poluição)

Lista oficial que `scripts/checar-poluicao.cjs` lê para procurar
vocabulário de uma atividade na tela de outra (regra do CLAUDE.md,
seção PADRÕES DE TELA, item c). Só entram aqui palavras que NÃO têm
uso legítimo fora da própria atividade — "sacas", "colheita",
"lâmina", "umidade", "lote", "plantio" e "roçada" ficaram de fora
porque aparecem em mais de uma. Comparação sem acento, sem
maiúscula e por palavra inteira. Termo novo em catálogo de uma
atividade? Acrescente aqui na mesma tarefa.

### Café
café, cafezal, cereja, florada, requeima, lata, latas, terreiro,
secador, tulha, gotejo, gotejadores, derriça, desbrota, arruação,
esparramação, peneira, catação, bicho-mineiro, broca-do-café,
passada, repasse, maturação, benefício

### Grãos
pivô, pivôs, soja, milho, feijão, percentímetro, dessecação,
estande, cultivar, híbrido, palhada, vazio sanitário, semeadura,
inoculação, população, espaçamento, subsolador, sementeira,
arrendado, quimigação, buva, capim-amargoso, ferrugem-asiática,
percevejo, cigarrinha, lagarta, mosca-branca, silo, grãos ardidos

### Pecuária
cabeça, cabeças, cocho, bezerro, bezerra, garrote, novilha, touro,
touros, vaca, vacas, boi, rebanho, pasto, pastos, retiro, retiros,
IATF, bicheira, berro, desmama, brinco, sal mineral, proteinado,
vermifugação, everminou, apartação, castração, pesagem, embarque,
gado, aguadas, porteira, capataz, prenhes, gestação, carrapato
