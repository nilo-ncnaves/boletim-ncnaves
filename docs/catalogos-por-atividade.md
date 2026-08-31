# Catálogos por atividade — fonte oficial do vocabulário

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

## PECUÁRIA
Eventos por grupo (OPS_PECUARIA_FASES): manejo diário, sanitário,
reprodutivo, manejo de lote, pastagem e estrutura. Cada evento tem
lote/pasto, quantidade de cabeças e, onde couber (eventos
sanitários), produto + dose por cabeça.
