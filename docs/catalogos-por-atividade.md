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
- Em "Operações do dia", o funcionário toca "＋ operação" e escolhe na
  LISTA NATIVA do celular AGRUPADA POR FASE (Pré-plantio / Plantio /
  Condução / Colheita / Pós-colheita — v86; até a v85 eram fases
  recolhidas com chips). A fase de agora vem primeiro, marcada
  "· fase de agora" no título do grupo.
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
Fonte: `OPS_CAFE_GRUPOS`, `LISTA_FUNCOES`, `DEPARA_NOMES`,
`TERMOS_LEGADO` e `SUGESTAO_FITO` do index.html. Revisto na v76 com o
Nilo: o termo é o que o funcionário fala, e diz COMO o serviço foi feito
(manual × mecanizado × químico), porque é isso que muda o custo e o
planejamento. Nada do que já foi lançado é reescrito — quem traduz nome
antigo para nome de hoje é a leitura (item 17 da definição de pronto).

### Princípios de tela (café)
- Atividade por talhão em 3 passos: ONDE (talhão) → O QUÊ (LISTA NATIVA
  do celular, agrupada por natureza — v86, a mesma forma da "Função /
  serviço" da mão de obra, a pedido dos gerentes) → DETALHES (pessoas,
  como terminou o dia, calda, máquinas). Nada do passo seguinte aparece
  antes do toque no anterior; a lista abre com "— toque para escolher —"
  e nada vem escolhido de antemão. O seletor é o componente ÚNICO
  `seletorOperacao`, o mesmo dos grãos — lá o grupo é a FASE do ciclo,
  aqui é a NATUREZA do serviço (CLAUDE.md, c4). Até a v85 eram grupos
  recolhidos com chips dentro; a turma reclamou da rolagem.
- Irrigação de café é seção própria (💧 gotejo). As operações
  "Irrigação manual", "Irrigação automática" e "Adubação via
  fertirrigação" existem na lista por talhão porque são serviço de gente
  no talhão, com custo e apontamento — não substituem a seção.

### Operações por talhão — 4 grupos, 27 termos (`OPS_CAFE_GRUPOS`)
**Tratos culturais (badge T) — 18**
Pulverização manual · Pulverização mecanizada · Adubação manual ·
Adubação via lanço · Adubação orgânica · Aplicação via drench / via solo
· Calagem / gessagem · Capina manual · Capina mecânica com trincha ·
Capina mecânica com roçadeira · Capina química manual · Capina química
mecanizada · Desbrota manual · Poda mecanizada esqueletamento ·
Levantar café · Arruação / esparramação de cisco · Monitoramento de
pragas (MIP) · Plantio / renovação

**Irrigação e fertirrigação (badge I) — 4**
Irrigação manual · Irrigação automática · Adubação via fertirrigação ·
Limpeza do sistema de irrigação

**Colheita e pós-colheita (badge C) — 3**
Colheita · Catação · Repasse

**Estrutura e apoio (badge E) — 2**
Manutenção de estradas e aceiros · Outra

"Outra" não é operação identificável: não entra no espelho do Supabase
nem recebe badge. Termos que o escritório acrescentar em Cadastros ›
Catálogos entram num 5º grupo, "Outras (cadastro do escritório)", que só
aparece quando existe pelo menos um.

### Funções de mão de obra — 25 (`LISTA_FUNCOES`)
Colheita manual (derriça) · Varrição / rapagem · Abanação ·
Carregamento de café · Terreiro (mexer/rodar café) · Secador / tulha
(apoio) · Benefício (apoio) · Capina manual · Capina mecânica com
roçadeira · Capina química manual · Arranquio de corda-de-viola ·
Desbrota manual · Poda mecanizada esqueletamento · Levantar café ·
Arruação · Esparramação de cisco · Adubação manual · Pulverização manual
· Plantio / replantio de mudas · Irrigação manual · Irrigação
(manutenção/filtros) · Limpeza de carreadores · Manutenção de
cercas/benfeitorias · Apoio a máquinas (abastecimento) · Serviços gerais

A lista de funções é de MÃO DE OBRA: entram os serviços que uma pessoa
faz. Os termos mecanizados que só existem como operação de máquina
(Pulverização mecanizada, Capina mecânica com trincha, Capina química
mecanizada, Irrigação automática, Adubação via fertirrigação) ficam de
fora daqui — quem trabalha na máquina aparece em "Apoio a máquinas
(abastecimento)" e a máquina é apontada na própria atividade.
"Irrigação (manutenção/filtros)" continua separada de "Irrigação
manual": uma é conserto, a outra é molhar a lavoura.

### De-para de nomenclatura (v76) — `DEPARA_NOMES`
Termo antigo → termo de hoje. Vale na LEITURA (exibição, soma, plano,
filtro, badge); o registro no banco nunca muda.

| termo antigo | termo de hoje | onde |
| --- | --- | --- |
| Desbrota | Desbrota manual | atividade e função |
| Poda / esqueletamento | Poda mecanizada esqueletamento | atividade |
| Poda (decote/esqueletamento) | Poda mecanizada esqueletamento | função |
| Roçada costal | Capina mecânica com roçadeira | função |
| Aplicação de herbicida (costal) | Capina química manual | função |
| Aplicação de defensivo (costal) | Pulverização manual | função |

### Termos legados — `TERMOS_LEGADO.CAFE` (aguardam decisão do Nilo)
Um antigo que se abriu em DOIS novos: o app não adivinha. Some da
escolha de lançamento novo, continua legível e continua somando com o
nome gravado. O valor guardado é a NATUREZA, igual nos dois candidatos,
para o badge e as somas por natureza não se perderem.

| termo antigo | natureza | pergunta em aberto |
| --- | --- | --- |
| Pulverização | Tratos culturais | manual ou mecanizada? |
| Aplicação de herbicida | Tratos culturais | capina química manual ou mecanizada? |
| Capina roçadeira / trincha | Tratos culturais | com trincha ou com roçadeira? |
| Irrigação | Irrigação e fertirrigação | manual ou automática? |

### Espelho no Supabase
`operacao_catalogo` (o grupo vai na coluna `fase`) e `operacao_alias` (o
nome antigo é apelido da operação de hoje), gerados por
`node scripts/gerar_catalogo_operacoes.cjs`. O bloco pronto para rodar
está em `sql/049-nomenclatura-cafe.sql`; o mesmo seed está recolado
entre os marcadores do `sql/040`. As duas operações renomeadas 1 para 1
saem de cena com `ativo = false` — nunca com `delete`.

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

## Régua de 7 dias — vocabulário por tela (v73)

O componente único `reguaDias` (CLAUDE.md, item c11) é o mesmo nas
três atividades e no pós-colheita: dias da semana pelo catálogo
`DIAS_SEMANA` (dom, seg, ter, qua, qui, sex, sáb — português, nunca
Mon/Sun) e "hoje" pela data civil em Brasília. O que muda por tela é
só o nome do registro e o `que` do vazio — passados por quem chama,
por perfil de tela, nunca por condicional de atividade:

| Tela | Rótulo do registro do dia | `que` do vazio | Frase do vazio (exemplo) |
|---|---|---|---|
| Casa do gerente — ☕ café, 🌾 grãos, 🐂 pecuária | "Boletim de dd/mm enviado" | boletim registrado | "Sem boletim registrado em Floramill em 05/09/2026." |
| Casa do pós-colheita (café) | "Registro de dd/mm enviado" | registro de pós-colheita | "Sem registro de pós-colheita em Vereda Romaria em 05/09/2026." |

Não existe termo de dia próprio de uma atividade (piquete, retiro,
talhão, pivô não entram na régua: a tela de leitura é por unidade, não
por subdivisão — mesma decisão do cabeçalho contextual acima).

## Chips removíveis — vocabulário do contador por tela (v74)

Componente único `chipsSelecao(attr, {um, varios})` (CLAUDE.md, item
c12). O substantivo do contador é dado por quem chama, por tela — nunca
por `if(atividade==="…")`. "selecionado(s)/selecionada(s)" acompanha o
gênero do substantivo. Tabela vigente:

| Tela / bloco | `attr` (data-* do chip de opção) | 1 item | N itens |
|---|---|---|---|
| ☕ Café › Irrigação › "Qual foi o problema?" | `irrpb` | 1 problema selecionado | N problemas selecionados |
| ☕ Café › Irrigação › Fertirrigação › "Em quais setores?" | `irrfsec` | 1 setor selecionado | N setores selecionados |
| Cadastros › Códigos › novo combinado › Atividades inteiras | `combo-atv` | 1 atividade selecionada | N atividades selecionadas |
| Cadastros › Códigos › novo combinado › Unidades avulsas | `combo-uni` | 1 unidade selecionada | N unidades selecionadas |
| Cadastros › Catálogos › Máquinas › vínculo com fazendas | `vinc-faz` | 1 fazenda selecionada | N fazendas selecionadas |
| Cadastros › Fazendas › detalhe › Estrutura de pós-colheita | `estr` | 1 item selecionado | N itens selecionados |

🌾 Grãos: a única multi-seleção ("Qual foi o problema?" no cartão do
pivô, `igpb`) mora DENTRO da tela de apontamento em 3 passos e por isso
NÃO recebe o componente (CLAUDE.md, item c12; regra 7). Se um dia os
grãos ganharem multi-seleção fora do apontamento, ela entra nesta tabela
com o mesmo componente. 🐂 Pecuária: nenhuma multi-seleção hoje (cada
campo escolhe um valor); mesma regra. Rótulos dos chips: os do chip de
opção (nome do talhão/unidade/fazenda pelo cadastro por id; opções fixas
pelo catálogo). Limite visível: 6 + "+K".

## Plano do dia seguinte — vocabulário por atividade (v75)

Componente único `abrirFolhaPlano` / `faixaPlanoHoje` / `avaliarPlano`
(CLAUDE.md, item c13). O que muda por atividade vem do catálogo
`PLANO_ATIVIDADE` do index.html, por chave — nunca de `if(atividade===…)`
nas telas. Tabela vigente:

| Atividade | Rótulo do ONDE (1º passo) | Opção "área toda" | Catálogo do O QUÊ (2º passo) | Onde o app procura o registro do dia |
|---|---|---|---|---|
| ☕ Café | Talhão | Área geral | `LISTA_ATIV` (sem "Outra") | `atividades[].tipo` + `talhaoId`; "continua amanhã" → ◐ parcial |
| 🌾 Grãos | Talhão / pivô | Área geral / sede | `OPS_GRAOS_FASES` (todas as fases) | `atividades[].tipo` + `talhaoId`; "continua amanhã" → ◐ parcial |
| 🐂 Pecuária | Pasto / retiro | Toda a fazenda | `LISTA_PECUARIA` (`OPS_PECUARIA_FASES`) | `pecuaria.eventos[].tipo` + o de-para `PLANO_PEC_DEPARA` (abaixo) |

O 3º passo (DETALHES) é igual nas três: "Quantas pessoas você prevê" —
um campo, sem obrigatoriedade. Nenhum termo exclusivo de uma atividade
aparece na tela de outra: "pivô" só nos grãos, "pasto/retiro" só na
pecuária, "talhão" (que não é exclusivo) no café e nos grãos.

**De-para da pecuária (`PLANO_PEC_DEPARA`).** Espelho exato de
`operacao_alias` (sql/040-dias-sem-registro.sql): o plano conta como
feito o que o gerente registrou na seção própria, não só em "Outros
manejos".

| Bloco do payload | Valor registrado | Operação do catálogo |
|---|---|---|
| `pecuaria.mov[].tipo` | Nascimento | Parto / nascimento |
| `pecuaria.mov[].tipo` | Morte | Mortalidade (com causa) |
| `pecuaria.mov[].tipo` | Desmama | Desmama |
| `pecuaria.mov[].tipo` | Mudança de pasto | Rotação de pasto — entrada de lote |
| `pecuaria.mov[].tipo` | Entrada | Compra / entrada de animais |
| `pecuaria.mov[].tipo` | Saída | Embarque / venda |
| `pecuaria.massa[].tipo` | Vacinação | Vacinação (especificar) |
| `pecuaria.massa[].tipo` | Vermifugação | Vermifugação |
| `pecuaria.san[].problema` | Bicheira | Cura de bicheira |
| `pecuaria.san[].problema` | Carrapato / mosca em excesso | Controle de carrapato / mosca-do-chifre |
| `pecuaria.lotes[]` (cabeças > 0) | — | Contagem |
| `pecuaria.nut[]` (repôs no cocho) | — | Suplementação (sal mineral / proteinado / ração) |
| `pecuaria.rep.iatfEtapa` | — | IATF |
| `pecuaria.rep.dgPrenhes/dgVazias` | — | Diagnóstico de gestação |

**Motivos do desvio (`PLANO_MOTIVOS`).** Iguais nas três atividades — o
motivo é de gestão, não de agronomia. "Clima" não é chip: só o app o usa,
quando o dia foi impedido pelo clima declarado no boletim.

| id | Rótulo no chip | Conta como |
|---|---|---|
| `clima` | *(não aparece — automático)* | clima |
| `chuva` | Choveu | clima |
| `maquina` | Máquina quebrou | evitável |
| `gente` | Faltou gente | evitável |
| `insumo` | Faltou insumo | evitável |
| `prioridade` | Mudou a prioridade | evitável |
| `outro` | Outro *(revela uma linha de texto)* | evitável |
| *(sem resposta)* | — | evitável, como "não informado" |

**Clima que impede o dia (`CLIMA_IMPEDITIVO`, `PLANO_CHUVA_MM`).** Só o
clima DECLARADO pelo gerente na seção Clima — nada é inferido de estação
nem de fora do boletim: condição "Chuva forte", "Granizo" ou "Geada", ou
chuva declarada ≥ 25 mm no dia. Vale igual nas três atividades e serve às
duas contas: o desvio do dia vira "clima" e o dia sai dos trabalháveis.
A lista e o limite são parâmetros do catálogo — mudar é decisão do Nilo
com o agrônomo, na mesma tarefa que atualizar esta tabela.

**Status do item.** ✅ feito · ◐ parcial · ⚪ não feito, sempre no
sentido de REGISTRO. O rótulo visível é a palavra ao lado do ícone
("feito", "parcial", "não feito"); a cor não é usada como sinal (canal
reservado ao farol, regra 4 do plano de safra).

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

### ☕ Café — categoria = grupo do catálogo (OPS_CAFE_GRUPOS), desde a v76
Até a v75 as categorias do café eram uma proposta à parte, pendente de
aprovação. Na v76 a proposta caiu: a categoria do café É o grupo por
natureza que o gerente vê no seletor do boletim, ligado por `fase`
exatamente como em grãos e pecuária. Uma fonte só, um agrupamento só.

| Letra | Categoria (grupo) | Operações |
|---|---|---|
| **T** | Tratos culturais | Pulverização manual · Pulverização mecanizada · Adubação manual · Adubação via lanço · Adubação orgânica · Aplicação via drench / via solo · Calagem / gessagem · Capina manual · Capina mecânica com trincha · Capina mecânica com roçadeira · Capina química manual · Capina química mecanizada · Desbrota manual · Poda mecanizada esqueletamento · Levantar café · Arruação / esparramação de cisco · Monitoramento de pragas (MIP) · Plantio / renovação |
| **I** | Irrigação e fertirrigação | Irrigação manual · Irrigação automática · Adubação via fertirrigação · Limpeza do sistema de irrigação |
| **C** | Colheita e pós-colheita | Colheita · Catação · Repasse |
| **E** | Estrutura e apoio | Manutenção de estradas e aceiros |

"Outra": sem categoria, sem badge. Termo ANTIGO gravado num boletim de
antes da v76 continua com badge: o de-para (`DEPARA_NOMES`) leva ao
termo de hoje e, quando o antigo é ambíguo, `TERMOS_LEGADO` guarda a
natureza dele — que é a mesma nos dois candidatos.

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
Sem ação em massa, sem modal, sem campo novo de digitação. Desde a v70
(decisão do Nilo) o envio exige resposta em toda seção eventual:
registro ou "Nada a registrar hoje"; seção esperada fica fora.

## Planejamento — reunião mensal e semana (v77)

Fonte oficial do vocabulário do módulo de planejamento. Componentes
ÚNICOS nas três atividades: o que muda por atividade é o de-para de
descrição → operação do boletim (sinônimos abaixo), nunca a tela.

### Status da tarefa (`PLAN_STATUS`)

| id | rótulo | farol |
|---|---|---|
| `a_iniciar` | A iniciar | por prazo (🟢 🟡 🔴) |
| `em_execucao` | Em execução | por prazo (🟢 🟡 🔴) |
| `finalizado` | Finalizado | ✅ |
| `aguardando_terceiro` | Aguardando terceiro | ⏸️ cinza — **nunca vermelho** |
| `aguardando_clima` | Aguardando clima | ⏸️ cinza — **nunca vermelho** |
| `cancelado` | Cancelado (com motivo) | — |

Tarefa **sem prazo** também é ⏸️ cinza. Vermelho é só 2 dias, hoje ou
vencido (rótulo ATRASADO, que descreve o PRAZO, nunca a pessoa);
amarelo é de 3 a 7 dias; verde é mais de 7 dias.

### Motivos de trava (`PLAN_MOTIVOS_TRAVA`) — chips de um toque

| id | chip | vira o status |
|---|---|---|
| `insumo` | falta insumo | aguardando terceiro ("aguardando insumo") |
| `peca` | falta peça | aguardando terceiro ("aguardando peça") |
| `gente` | falta gente | aguardando terceiro ("aguardando gente") |
| `maquina` | falta máquina | aguardando terceiro ("aguardando máquina") |
| `chuva` | chuva | aguardando clima ("aguardando o tempo firmar") |
| `outro` | outro | aguardando terceiro ("aguardando") |

### Novo prazo em um toque (`PLAN_NOVOS_PRAZOS`)
`+7 dias` · `+15 dias` · `fim do mês` · `próxima reunião` (dia 10).
Nunca calendário nem teclado: quem está no campo não digita.

### Origem da tarefa (`PLAN_ORIGENS`)
`mensal` = rodada da reunião · `semana` = tarefa nova da semana ·
`avulsa` = criada no escritório fora dos dois ritos.

### Tipo do item (`PLAN_TIPOS_ITEM`)
`tarefa` (tem unidade e prazo) · `assunto` (assuntos gerais da ata) ·
`investimento` (necessidades de investimento). Assunto e investimento
não têm fazenda nem prazo, por desenho.

### De-para da ata (`DEPARA_ATA_PADRAO`, editável em Cadastros)

| nome na ata | unidade do app | observação |
|---|---|---|
| FMC Igrejinha | f14c Monte Carmelo — Café | área "Igrejinha" |
| FMC Lazaro | f14c Monte Carmelo — Café | área "Lazaro" |
| FMC Caxico | f14c Monte Carmelo — Café | área "Caxico" |
| FMC Ernane | f14c Monte Carmelo — Café | área "Ernane" |
| FMC Arrendo | f14c Monte Carmelo — Café | área "José Eustáquio" |
| Lagamar (Rodrigo) | f20 Lagamar Café (Rodrigo) | |
| Lagamar (Grupo) | f03c Rio Preto-Lagamar — Café | |
| Café 5º · Café 6º | f24 Vereda Café 5º e 6º | |
| Romaria | f23 Vereda Romaria | |
| Vereda | f22c Vereda — Café | |
| Mata Preta | f13c Mata Preta — Café | |
| Água Limpa | f01 Água Limpa | |
| São Félix | f21 São Félix — Arrendamento | |
| Marimbondo · Cristo Redentor · Córrego Grande (Dr. Adilson) | — | **fora do escopo**: ignoradas sempre, sem perguntar |

Identidade pelo **id** da unidade, nunca por pedaço de nome. Nome que
não está aqui NÃO é adivinhado: entra na pré-visualização como
"unidade não reconhecida" e a pessoa escolhe (regra 3 do plano de
safra). Igrejinha e Lazaro entraram como áreas de Monte Carmelo — Café
(talhões `t057` e `t058`, área a confirmar em Cadastros), no mesmo
padrão de Caxico, Ernane e José Eustáquio.

### Leitura da ata pela linguagem

| o que aparece na linha | vira |
|---|---|
| `PRAZO: DD/MM/AA` | prazo (sem isso, tarefa sem prazo → farol cinza) |
| `96 há`, `22 ha`, `40 hectares` | área em ha |
| "Ok", "Finalizado", "Concluído", "Pronto", "Feito" | FINALIZADO |
| "em andamento", "iniciou", "iniciado", "finalizando", "começou" | EM EXECUÇÃO |
| "falta", "fazer", "aplicar", "programar", "iniciar" | A INICIAR (é também o padrão) |
| "aguardando…", "falta chegar", "falta entregar", "falta peças", "cobrar <fornecedor>", "aguardando repasse", "aguardando aprovar" | AGUARDANDO TERCEIRO (captura o terceiro: Cooxupé, Diferpan, Cemig…) |
| "aguardando sol", "quando parar as chuvas", "N dias de sol", "parar de chover" | AGUARDANDO CLIMA |
| `(Renatinho/ Renato)`, "Definido com Cristian" | responsável |
| "Assuntos gerais", "Necessidades de investimento" | lista separada, sem fazenda e sem prazo |

Ordem de decisão: FINALIZADO vence tudo; depois clima; depois terceiro;
depois a linguagem de execução. Reimportar a mesma ata não duplica
(chave: rodada + unidade + descrição normalizada).

### Vínculo com o boletim (`PLAN_SINONIMOS`) — o app SUGERE, nunca conclui

Descrição da tarefa → operação do catálogo da atividade da unidade. Só
para SUGERIR a conclusão quando o registro correspondente entra no
boletim do dia; a conclusão continua sendo um toque da pessoa.

- **Café:** kcl → Adubação via lanço · ferti/fertirrigação → Adubação
  via fertirrigação · esqueletar/esqueletamento → Poda mecanizada
  esqueletamento · varrição → Colheita · levantar → Levantar café ·
  calcário/gesso → Calagem / gessagem · herbicida → Capina química
  manual · roçada → Capina mecânica com roçadeira · adubação → Adubação
  manual · desbrota → Desbrota manual · pulverização → Pulverização
  manual · irrigação → Irrigação automática.
- **Grãos:** kcl/cobertura → Adubação de cobertura · calcário → Calagem ·
  gesso → Gessagem · dessecação → Dessecação de pré-plantio · plantio →
  Plantio / semeadura · colheita → Colheita mecanizada · herbicida →
  Herbicida pós-emergente · fungicida → Fungicida · inseticida →
  Inseticida.
- **Pecuária:** vacina/vacinação → Vacinação (especificar) ·
  vermifugação → Vermifugação · roçada → Roçada · cerca/cocho →
  Manutenção de cerca / cocho / bebedouro · pesagem → Pesagem · desmama
  → Desmama · formiga → Controle de formiga.

Além dos sinônimos, casa por palavra inteira de 5+ letras do nome da
operação. **Tarefa de estrutura** (caixa d'água, piscinão, talude,
adutora, barracão, cerca, estrada, aceiro, represa, bomba, poço, rede
elétrica, curral, laboratório, reforma, construção, montagem) NUNCA
recebe sugestão: status só manual.

### Planejado × executado (v78) — o que cada número significa

| número | de onde sai | regra |
|---|---|---|
| **planejado** | `t.meta` (informada pelo escritório) ou `t.area` (a área que a ata trouxe) | sem nenhum dos dois não há barra nem restante — o app conta os lançamentos e diz que falta a área |
| **executado** | soma da área dos talhões DISTINTOS com lançamento casado, na janela da tarefa | o mesmo talhão lançado duas vezes conta UMA vez; nunca passa da meta na barra (o excedente aparece à parte) |
| **restante** | planejado − executado | arredondado depois do executado: os três SEMPRE fecham na tela |
| **janela da tarefa** | de `inicioReal` (ou `criadoEm`) até hoje — ou até `concluidoEm` | tarefa concluída congela o número |
| **esforço** | lançamentos (talhão × operação × dia) e, quando houver, pessoas-dia | é o denominador do "% fora do plano" |

**Executado fora do plano** = lançamento do mês que não casou com nenhuma
tarefa da unidade (qualquer status, menos cancelada). Não é cobrança: é o
que apareceu no dia e não estava na ata — assunto para a próxima reunião.
**Sem lançamento** = nenhum registro do boletim casou com a tarefa; é
ausência de REGISTRO, nunca afirmação de que não foi feito.

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

> A revisão de nomenclatura da v76 não acrescentou termo exclusivo
> novo: "desbrota" já estava na lista (e "Desbrota manual" a contém),
> "Levantar café" cai em "café", e "trincha", "roçadeira",
> "pulverização", "capina", "adubação" e "fertirrigação" têm uso
> legítimo em grãos e/ou pecuária — pelo mesmo motivo que "roçada" e
> "plantio" ficaram de fora desde o começo.

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
