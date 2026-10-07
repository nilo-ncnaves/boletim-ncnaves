# Confinamento — plano de implementação (rascunho para o Nilo, 01/10/2026)

Situação: EM IMPLEMENTAÇÃO. Perguntas respondidas pelo Nilo em 06/10/2026
(item 3, com a resposta ao lado de cada uma). v102 entregou a etapa 1 + o
diário (item 4); v103 foi a revisão de especialista (item 5: o cocho é do
curral, travas de faixa, registros leves e indicadores). O que já existe no
app está no ESTADO.md, seções "Confinamento (v103)" e "Confinamento (v102)".

## 0. O que já existe no app e pesa na decisão

- O app tem três atividades no catálogo `ATIVIDADES` (café, grãos,
  pecuária). A regra c) do CLAUDE.md diz que nada de uma atividade aparece
  na tela de outra. Por isso o confinamento entra como **quarta atividade
  (`CONFINAMENTO`)**, com unidade própria, código de acesso próprio e aba
  própria no painel — e não como sub-acordeão da pecuária (a ESTADO.md da
  v50 previa sub-acordeão; a decisão de "perfil próprio" muda isso).
- O papel **pós-colheita** (`papel:"pos"`) é o precedente de perfil com
  registro diário PRÓPRIO fora da tabela `boletins`: casa própria, rascunho
  próprio, item próprio na fila offline, mesma régua de 7 dias, mesma
  `faixaEnvio`. O Gerente de Confinamento segue esse molde (`papel:"conf"`).
- Já existe um talhão "Curral Confinamento" (3 ha, `t085`) cadastrado em
  **Vereda — Café (f22c)**, fazenda-mãe Vereda (f22, Romaria/MG). Isso
  sugere que a fazenda é a Vereda (f22), e não a "Vereda Romaria" (f23) —
  mas a regra 3 do plano de safra proíbe decidir por pedaço de nome:
  pergunta 1.
- Hoje "cocho", "lote", "cabeça", "brinco", "pesagem" e "embarque" são
  termos EXCLUSIVOS da pecuária na checagem de poluição. Passam a ser
  compartilhados entre pecuária e confinamento (docs/catalogos-por-
  atividade.md, "Termos exclusivos").
- Fila offline: cada tabela nova vira um tipo de item (`t`) em
  `syncEnviar`, com `id` gerado no aparelho, poucas colunas soltas para
  consulta e o registro inteiro em `payload` — igual a insumos e
  planejamento. Leitura numa função `baixarConfinamento()` só para quem tem
  unidade de confinamento no escopo ou painel.

## 1. Modelo de dados (sql/059-confinamento.sql)

Regras comuns às seis tabelas: `id text primary key` gerado no aparelho;
`unidade_id text` (id da unidade no app); `payload jsonb` com o registro
inteiro (quem lançou, hora, histórico); `atualizado timestamptz` com
gatilho; RLS com leitura/inserção/atualização anon (mesmo modelo das
demais); **sem policy de delete** — cancelar é status. Nenhuma tabela
existente é alterada.

**cf_lotes** — um lote = uma entrada (lote misto vira dois registros)
- id (text) — o próprio código: CF-VER-2026-01
- unidade_id (text), sigla_fazenda (text), ano (int), seq (int) — único por unidade+ano+seq
- curral_id (text) — curral atual (muda com transferência)
- grupo_genetico (text) — NELORE | CRUZADO_ANGUS
- entrada_data (date), cabecas_entrada (int), peso_entrada_kg (numeric; média de balança) — obrigatórios
- origem (text) — COMPRA | RECRIA; fornecedor (text); gta (text)
- preco_valor (numeric), preco_unidade (text) — ARROBA | KG
- status (text) — ATIVO | EM_SAIDA | AGUARDANDO_ROMANEIO | FECHADO | CANCELADO
- fechado_em (timestamptz), fechado_por (text)
- projecao (jsonb) — versão VIGENTE: {v, gmd_alvo, dias_previstos, peso_saida_kg, cms_previsto, rendimento_pct, custo_arroba, preco_teto, gmd_equilibrio, por, em}; as versões anteriores ficam em payload.projecoes[] (nunca editadas, como o plano de safra)
- payload (jsonb)

**cf_diario** — um registro por unidade e dia (é o "boletim" do confinamento)
- id (text) = unidade_id + "_" + data; único por (unidade_id, data)
- unidade_id (text), data (date), responsavel (text)
- chuva_mm (numeric), estresse_termico (bool), obs (text)
- payload.lotes[] — uma linha por lote ativo: {lote_id, cms_kg_ms, sobra_escore (0–4), enfermaria (int), curral_cond (SECO|UMIDO|LAMA), obs}
- payload.mortes — ids dos eventos de morte do dia (o NÚMERO de mortes vem dos eventos; nunca digitado duas vezes)
- visão `vw_cf_diario_lote`: uma linha por lote-dia, para o escritório cruzar com o FarmTell

**cf_eventos** — o que não é pesagem, sanidade nem saída
- id, unidade_id, lote_id, data, tipo (text) — TRANSFERENCIA | MORTE | LEITURA_SEMANAL
- transferência: curral_de, curral_para
- morte: cabecas (int), causa (text, lista curta), peso_estimado_kg (numeric) — único lugar do app que aceita peso estimado
- leitura semanal: rumo (text) — NO_RUMO | ATENCAO | FORA; motivo (text); pedido (text)
- responsavel, payload

**cf_pesagens** — só com balança
- id, unidade_id, lote_id, data, cabecas_pesadas (int, obrigatório), peso_medio_kg (numeric, obrigatório)
- responsavel, payload
- (a pesagem de entrada mora em cf_lotes; a de saída, em cf_saidas; a visão `vw_cf_lote_resumo` junta as três para calcular GMD no banco, só leitura)

**cf_sanidade** — carência que trava a saída
- id, unidade_id, lote_id, data
- brinco (text) — vazio = lote inteiro; cabecas (int)
- produto (text), dose (text), motivo (text) — ENFERMARIA | PREVENTIVO | OUTRO
- carencia_dias (int, obrigatório); carencia_ate (date, coluna gerada = data + carencia_dias)
- responsavel, payload

**cf_saidas** — embarque pelo gerente, romaneio pelo escritório, na mesma linha
- id, unidade_id, lote_id, data, frigorifico (text), cabecas (int, obrigatório), peso_vivo_kg (numeric, total de balança, obrigatório), nota (text)
- romaneio: peso_carcaca_kg (numeric), rendimento_pct (numeric, calculado), acabamento (text), bonus_valor (numeric), romaneio_em (timestamptz), romaneio_por (text)
- status (text) — ENVIADA | ROMANEIO_LANCADO
- responsavel, payload

**Calculado pelo app (função única `cfResumoLote(lote, dia)`, nunca gravado):**
dias de cocho; cabeças vivas = entrada − mortes − saídas; mortalidade % =
mortes ÷ entrada; GMD desde a entrada = (peso da última pesagem − peso de
entrada) ÷ dias; GMD desde a última pesagem; "em carência até dd/mm"
(maior carencia_ate futura do lote); farol contra a projeção.

## 2. Fluxo de telas — Gerente de Confinamento

Porta de entrada: código CONF-NNNN (atividade) ou VF-NNNN (unidade). Com
uma unidade só, abre direto a casa, como hoje.

**A. Casa (`vCasaConf`)** — cabeçalho contextual "Vereda › Confinamento",
régua de 7 dias, faixa de envio, e, nesta ordem:
1. Cartão do dia: botão "Preencher diário de hoje" (ou "Diário de hoje
   enviado às 18:02", tocável).
2. Lotes ativos, uma linha por lote (estado na própria linha, P7):
   "CF-VER-26-01 · Nelore · 118 cab · dia 42 · GMD 1,32 · ●". Toque abre
   o lote.
3. "＋ Entrada de lote".
4. Sexta-feira: faixa "Leitura da semana" no topo (como o ritual da
   Diretoria), pulável.
5. "Mandar resumo no WhatsApp".
Altura-alvo: 2 telas com até 8 lotes.

**B. Diário (`vFormConf`) — meta 2 minutos.** É formulário (como Clima),
não lançamento em 3 passos:
- Topo: chuva (mm) e "estresse térmico" (chip sim/não).
- Um cartão compacto por lote ativo: linha de identidade + CMS (numérico,
  uma casa; o de ontem aparece em cinza como referência), sobra de cocho
  (chips 0 · 1 · 2 · 3 · 4), enfermaria (número), curral (chips seco ·
  úmido · lama). Mortes aparecem como contador "0 mortes · ＋ morte", e o
  "＋" abre o evento de morte (causa, peso estimado) — o número nunca é
  digitado solto.
- Observação livre no fim.
- Rodapé fixo: "Enviar diário" (botão de avanço; inativo enquanto faltar
  o que a tela mostra, o toque explica "Informe o CMS do lote 02").
Conta de toques: 5 lotes × 4 campos ≈ 20 toques + 2 do clima.

**C. Lote (`vLoteConf`)** — cabeçalho contextual com o código do lote:
- Números: dias de cocho · cabeças vivas · mortalidade · GMD acumulado ·
  GMD desde a última pesagem, cada um ao lado da projeção ("alvo 1,40")
  com o farol ● verde/amarelo/vermelho (regra de corte: pergunta 11).
  Sem pesagem ainda: "sem pesagem desde a entrada", cinza — nunca vermelho.
- "Em carência até dd/mm (3 animais)" quando houver.
- "＋ Registrar" → O QUÊ em chips (Pesagem · Transferência · Morte ·
  Sanidade · Saída para abate) → só os campos daquele tipo. ONDE já é o
  lote, então são dois passos.
- Linha do tempo dos eventos (lista compacta, badge de uma letra por tipo).
- "⬇ CSV do lote".
- Saída para abate: botão "Registrar saída" nasce inativo com "N animais
  em carência até dd/mm" enquanto houver carência — a trava é visível.

**D. Entrada de lote** (3 passos): ONDE = curral (chips) → O QUÊ = grupo
genético (Nelore · Cruzado Angus) → DETALHES: data, cabeças, peso médio
de balança, origem (compra · recria), fornecedor, preço + unidade (R$/@ ·
R$/kg), GTA. "Criar lote" gera e mostra o código.

**E. Leitura semanal (sexta)**: folha por lote, como a folha de tarefa:
rumo (chips no rumo · atenção · fora do rumo), motivo (chips), pedido ao
escritório/consultoria (um campo de texto). Pulável; não bloqueia nada.

**Escritório (código ADMIN)** — Cadastros › Confinamento: Currais; Lotes →
lote: romaneio (peso de carcaça, acabamento, bônus; rendimento calculado),
"Fechar lote" (botão de avanço: só com romaneio lançado e zero cabeças
vivas), "Nova versão da projeção" (a anterior vai para o histórico).

**Diretoria** — cartão "Confinamento" no painel pelo `PAINEL_CARTOES`
(nasce fechado → lista de unidades → tela da unidade com a tabela de
lotes: dias, GMD, mortalidade, farol). A aba Confinamento entra sozinha em
`chipsAtividade` e nos Relatórios.

**WhatsApp diário** (`resumoWhatsConf`): cabeçalho "🐂 CONFINAMENTO VEREDA
— dd/mm", clima, uma linha por lote (cab · dia · CMS · sobra · enfermaria
· curral), bloco "Desvios" com os lotes amarelos/vermelhos e as mortes do
dia, observação.

**CSV por lote** (`cfCsvLote`): uma linha por evento de qualquer tipo
(entrada, diário, pesagem, transferência, morte, sanidade, saída,
romaneio, leitura semanal), colunas fixas, separador ";", BOM — formato
dos CSV que o app já gera.

## 3. Perguntas antes de codar

Identidade e acesso
1. Qual é a fazenda: Vereda (f22, Romaria/MG, onde já existe o talhão
   → **Vereda (f22).** Unidade f22f "Vereda — Confinamento" (v102).
   "Curral Confinamento") ou Vereda Romaria (f23)? Proposta: unidade nova
   "Vereda — Confinamento" (id f22f), fazenda-mãe Vereda.
2. Sigla de 3 letras no código do lote (CF-VER-2026-01)? Numeração
   → **Sim** (VER; reinicia por ano; dois dígitos).
   reinicia a cada ano? Dois dígitos bastam?
3. O Gerente de Confinamento é outra pessoa, ou o gerente de café/grãos
   → **Outra pessoa.** Código próprio VF-6318 (unidade) e CONF-4725 (atividade).
   da Vereda? Muda se o código é só da unidade (VF-NNNN) ou combinado.
4. Currais: quantos e como se chamam? Proposta: cadastrados como talhões
   → **Provisório:** Curral 1 a 6 como talhões tipo CURRAL; o Nilo ajusta em Cadastros.
   da unidade com tipo CURRAL, em Cadastros › Talhões.

Diário
5. Quais campos do diário são obrigatórios para enviar? Proposta: CMS,
   → Decidido: sobra e curral obrigatórios; CMS opcional; enfermaria vazio = 0; clima opcional.
   sobra e curral por lote; enfermaria aceita 0; clima opcional.
6. CMS do dia pode faltar (FarmTell atrasou)? Se sim, a linha envia sem CMS
   → **Sim**: a linha envia sem CMS e lê "sem CMS".
   e o escritório vê "sem CMS"?
7. Escala da sobra de cocho: confirmar rótulos 0 a 4 (0 = cocho limpo …
   → Pesquisado: escala 0–4 do padrão de leitura de cocho (0 cocho limpo · 1 restos espalhados · 2 camada fina · 3 sobra 25–50 % · 4 sobra > 50 %).
   4 = sobra alta) — vêm do padrão do FarmTell?

Lote e eventos
8. O lote pode sair em mais de um embarque? Se sim, fecha quando cabeças
   → **Sim.** Fecha com zero vivas e todos os romaneios lançados.
   vivas = 0 E todos os romaneios lançados.
9. Carência: um animal (brinco) em carência trava o lote inteiro?
   → v1: um animal em carência trava o lote inteiro.
   Proposta v1: trava tudo; "sair deixando os brincos X" fica para depois.
10. Pesagem por amostra (cabeças pesadas < vivas) vale para o GMD do lote?
   → Vale: o GMD usa o peso médio da amostra.

Projeção e farol
11. Cortes do farol: proposta verde ≥ 95 % do GMD-alvo, amarelo 85–95 %,
    vermelho < 85 %; cinza sem pesagem. Pode ser?
   → Mantidos: 95 % / 85 %; cinza sem pesagem.
12. O gerente vê o farol e o GMD-alvo (exceção à regra "farol é da
    Diretoria" do plano de safra). Custo/@ e preço-teto ficam só para
    escritório e Diretoria — confirma?
   → **Todo mundo vê tudo. Sem trava.** (v103: registrado no CLAUDE.md, junto
   da regra 4 do plano de safra, para ninguém "corrigir".)
13. Preço de compra: o gerente lança na entrada; depois disso, só o
    escritório vê — confirma?
   → Na maioria é recria: avaliação na entrada e preço ESTIMADO. Campo "Preço de referência (estimado na avaliação de entrada)", opcional, R$/@ ou R$/kg.
14. Quais campos da ficha de entrada entram na projeção do app (lista do
    item 1) e quem digita a primeira versão: escritório, antes da entrada?
   → Decidido: gmdAlvo, diasPrevistos, pesoSaidaKg, cmsPrevisto, rendimentoPct, custoArroba, precoTeto, gmdEquilibrio; o escritório digita a primeira versão (v104).

Escritório e saída
15. Grau de acabamento: escala do frigorífico (1 a 5) ou texto? Bônus em
    R$ total ou R$/@?
   → Escala 1 a 5 do frigorífico; bônus em R$/@.
16. "Registrar saída" ganha UMA confirmação (a única nova: lote, cabeças,
    peso, frigorífico)? Hoje o app tem 20 pontos de confirmação (c10).
   → Sim, uma só (v103).

Catálogos (listas curtas a confirmar)
17. Causas de morte: timpanismo · acidose · pneumonia · trauma/acidente ·
    clostridiose · desconhecida · outra.
   → **OK.**
18. Motivos da leitura semanal: clima · sanidade · consumo/dieta · lote
    desuniforme · instalação/cocho · outro.
   → Mantidos (v104).
19. Frigoríficos: lista fixa (quais?) ou texto com memória do último.
   → Texto com memória do último.
20. Ícone e rótulo da atividade na entrada e no painel: "🐂 Confinamento"
    repete o boi da pecuária; alternativa "🐃". Qual?
   → **🐃** (alternativa).

Saídas
21. CSV: quem baixa (gerente e escritório, ou só escritório)? O escritório
    tem um export do FarmTell de exemplo para alinhar nomes de colunas?
   → Qualquer pessoa, sem trava.
22. WhatsApp: "desvio" = farol amarelo/vermelho + mortes do dia + sobra 0
    ou 4 — confirma?
   → **OK.** **Trocada na v103 (07/10/2026), na revisão de especialista:** a
   sobra deixou de ser desvio por um dia só de 0 ou 4. Agora é desvio: sobra 0
   em 2 ou mais diários seguidos (cocho limpo um dia é leitura normal; dois
   seguidos indica trato curto) ou sobra 3 ou 4 em qualquer dia (sobra alta já
   no primeiro dia é sinal de queda de consumo). Também entram no "Fora do
   esperado": poeira ou lama no curral, bebedouro sujo ou com falha, ofegação
   3 ou mais, queda de consumo e farol de consumo amarelo/vermelho.

## 4. Etapas de código (uma versão por PR)

Reorganizadas em 06/10/2026: as etapas 1 e 2 saíram juntas na v102, para o
gerente poder começar a usar o diário no primeiro dia.

1. v102 — ENTREGUE. Fundação + diário: atividade CONFINAMENTO, unidade, currais, códigos
   CONF/VF, papel "conf", fila e `sql/059`, Casa, Entrada de lote, lista e
   tela do lote (sem eventos), Cadastros › Confinamento (currais, lotes),
   `scripts/teste_confinamento.cjs` e grupo novo no `checar-poluicao`.
   diário de 2 minutos com morte (evento) e desfazer, faixa de envio, régua,
   WhatsApp, CSV por lote, tela do lote com números calculados.
2. v103 — ENTREGUE. Revisão de especialista (item 5): diário por curral,
   travas de faixa, poeira, jejum na pesagem, "Algo fora do normal?",
   enfermaria em dois números, bebedouro, ofegação, necropsia e os
   indicadores calculados (queda de consumo, farol de consumo, adaptação,
   sobra em sequência, peso estimado, saída prevista, conversão, morbidade).
   A Parte D (importação do CSV do FarmTell) ficou pendente do export de
   exemplo (docs/exemplos/farmtell/LEIA-ME.md).
3. v104 — Eventos restantes (era a v103): pesagem (chip obrigatório "com
   jejum · sem jejum", campo `jejum` já no modelo; "amostra de N de M
   cabeças" ao lado do GMD), transferência (usa o `curralId` do dia gravado
   no diário), sanidade com carência (trava a saída; produto e dose são
   REGISTRO do que foi feito, nunca sugestão, padrão ou lista recomendada),
   saída para abate com a única confirmação nova (com a projeção de peso e
   data ao lado do real); farol com GMD real.
4. v105 — Escritório (era a v104): romaneio, fechar lote, projeção
   versionada, cartão da Diretoria pelo `PAINEL_CARTOES`, leitura semanal de
   sexta.
5. Importação do CSV do FarmTell pela porta única (como o PDF do Agro1) —
   Parte D da v103, assim que houver o export real; não bloqueia nada acima.

## 5. Revisão de especialista (v103, 07/10/2026) — decisões

Avaliação do módulo da v102 do ponto de vista de gestão de confinamento de
gado de corte. O que mudou e por quê:

| | Antes (v102) | Depois (v103) | Por quê |
|---|---|---|---|
| D1 | Sobra, condição do curral e CMS marcados POR LOTE | Marcados UMA vez por CURRAL; o lote fica com enfermaria, "Algo fora do normal?" e mortes | Lote misto vira dois lotes no mesmo curral, que comem no mesmo cocho; o CMS do FarmTell também é por curral |
| D2 | Qualquer número passava | Travas de faixa `CF_FAIXAS` (CMS 4–16 · peso de entrada 150–650 · peso da morte 100–800 · chuva 0–200) e nada acima das cabeças vivas | Um "98" no lugar de "9,8" estragava GMD, conversão e mortalidade do giro |
| D3 | Seco · Úmido · Lama | Seco · Poeira · Úmido · Lama | O giro é na seca; de agosto a outubro o problema do curral no Cerrado é poeira (doença respiratória) |
| D4 | Peso sem condição | Chip obrigatório "com jejum · sem jejum" na entrada; desconto de 4 % no GMD quando as condições diferem (**provisório — a confirmar com a AXYS**) | O enchimento (3 a 5 % do peso) virava ganho ou perda falsa |
| D5 | "Sobra de cocho" | "Sobra de cocho (leitura da manhã)" | A leitura é de manhã, antes do primeiro trato; o diário é preenchido no fim do dia |
| D6 | Regra 4 × "todo mundo vê tudo" sem registro; observação livre por lote × regra 2 | CLAUDE.md registra a exceção; observação do lote virou chips "Algo fora do normal?" (monta · briga · animal mancando · animal caído · cocho com problema · outro) | Machos inteiros: monta e briga são causa real de trauma e de perda de GMD |

Registros leves novos (chips ou números, nenhum texto livre): enfermaria em
dois números ("entraram hoje", com motivo; "estão na enfermaria") — a
morbidade (caso novo) é o que importa, não o estoque; bebedouro do curral
(obrigatório); escore de ofegação 0–4 do curral (opcional, no lugar do
"estresse térmico" do dia); necropsia na morte (opcional).

Indicadores (todos calculados, nenhum gravado; sem dado, "—" ou cinza com o
motivo, nunca vermelho): queda de consumo (CMS do dia > 10 % abaixo da média
dos 3 diários anteriores com CMS — primeiro sinal de acidose, doença
respiratória ou calor); farol diário de consumo × CMS previsto (na casa a
bolinha é o pior entre consumo e ganho); CMS em % do peso vivo estimado; selo
"adaptação · dia N" até 21 dias, com mortalidade e morbidade dos primeiros 21
dias à parte; sobra em sequência (pergunta 22, trocada); peso estimado hoje
(pelo alvo ou pelo GMD real) e saída prevista; conversão alimentar (só com
CMS em ≥ 70 % dos dias do período); morbidade.

Contagem do diário com 5 lotes em 4 currais (cada campo uma vez, como na
v102): 22 → 31 campos (+41 %); só os obrigatórios, 10 → 12 (+20 %). O teto
do pedido era +30 %: a decisão sobre quais campos ficam recolhidos é do
Nilo, antes do PR (proposta no ESTADO.md, PENDÊNCIAS).
