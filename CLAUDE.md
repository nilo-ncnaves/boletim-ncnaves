# CLAUDE.md — Manual do projeto Boletim NCNaves

## O que é este projeto
PWA de boletim diário das fazendas do Grupo LGS (agronegócio: café,
grãos e pecuária — Monte Carmelo/MG). Gerentes de ~15 fazendas
preenchem pelo celular: clima, mão de obra por função, irrigação,
atividades por talhão, colheita, pós-colheita, remessas e ocorrências.
Arquitetura: arquivo único index.html (HTML+CSS+JS puro, sem
frameworks e sem etapa de build) + sw.js (service worker) + manifest.
Funciona offline (localStorage + fila de sincronização).

## Quem é o dono do projeto
Nilo, controller do grupo. NÃO é programador e trabalha exclusivamente
pelo iPhone. Toda comunicação com ele deve ser em português do Brasil,
clara e sem jargão. Explique o que fez em termos de negócio.

## Publicação (NÃO ALTERAR ESTE FLUXO)
O Netlify publica automaticamente o branch main em
https://boletim-ncnaves.netlify.app. Não há build command; o site é
servido como está. Portanto: NUNCA quebre o main. Trabalhe sempre em
branch próprio e abra pull request (ou faça merge apenas quando o
Nilo pedir explicitamente).

## Regra de versão (OBRIGATÓRIA em toda mudança publicável)
1. Incrementar a versão no rodapé da tela inicial
   ("Boletim NCNaves · vNN").
2. Trocar o nome do cache no sw.js ("boletim-lgs-vNN") para o MESMO
   número. Sem isso os celulares dos gerentes não atualizam.

## Banco de dados (Supabase)
URL: https://syvehtgrbqteyuqhoban.supabase.co
No código só existe a chave publishable (pública por natureza).
Tabelas que o app usa: boletins, pos_colheitas, remessas, telemetria,
icrop_manejo, icrop_fazendas, icrop_parcelas (leitura), solinftec_diario
(leitura), codigos_acesso, boletim_pecuaria e, desde a v52, as do plano
de safra: unidade_manejo, unidade_alias, unidade_manejo_log,
plano_safra, plano_unidade, plano_adubo_mes, plano_calagem,
plano_fito_mes, plano_fito_excecao, plano_gantt, plano_parametros
(o app lê; só a tela de ADMIN escreve).
Desde a v59: operacao_catalogo, operacao_alias e a visão
vw_dias_sem_registro (sql/040; o app só lê, sob demanda). Desde a v60:
operacao_janela e a visão vw_farol_registro (sql/042; só aparelhos com
painel baixam). Desde a v62: as visões vw_intervalo_operacoes e
vw_ritmo_operacoes (sql/043; ritmo entre registros, só leitura; até a
v64 só grãos e pecuária, desde a v65 nas três atividades). Desde a v63: integracao_job,
integracao_execucoes e a visão vw_status_integracoes (sql/045; de
quando é o dado do iCrop/Solinftec — tentativa, sucesso e dado
gravado são horários distintos; o app só lê). Desde a v64 a linha de
origem vale também para café e para o painel da Diretoria. Desde a
v65 as unidades de café aparecem em Diretoria › Faróis de registro
(sem janela, só "dias sem registro" e ritmo).
Desde a v67 (opcional, o app não lê): operacao_categoria e a coluna
operacao_catalogo.categoria_id (sql/046; espelho do catálogo de
categorias OP_CATEGORIAS do index.html).
Desde a v69: boletim_secao (catálogo das seções do boletim, eventual ×
esperada), boletim_secao_resposta (resposta explícita de ausência —
"Nada a registrar hoje", com autor e hora; escrita SÓ por gatilho a
partir de boletins.payload.secoes) e a visão vw_completude_boletim
(sql/047; o app só lê, sob demanda).
Desde a v76: NENHUMA tabela nova. A revisão da nomenclatura do café só
acrescenta LINHAS ao catálogo que já existe — operacao_catalogo (agora
com o grupo por natureza na coluna fase) e operacao_alias (o nome antigo
vira apelido da operação de hoje) — pelo sql/049, e desativa (ativo =
false, sem apagar) as duas operações renomeadas. Nenhum boletim é
reescrito.
Desde a v75: NENHUMA tabela nova. O plano do dia seguinte viaja dentro
de boletins.payload.plano (o app grava e lê) e o sql/048 só acrescenta
leitura ao motor de relatórios: a visão vw_plano_x_executado e o
relatório mensal plano_x_executado_diario em relatorios_gerados (o app
só lê, como os outros).
Desde a v77: planejamento_rodada, planejamento_semana e
planejamento_tarefa mais a visão vw_planejamento_mes (sql/050; o app lê
E escreve, na mesma fila offline dos boletins — o histórico de cada
tarefa viaja dentro do payload) e o relatório mensal ata_x_executado em
relatorios_gerados (sql/051; o app só lê, como os outros).
Desde a v78: NENHUMA tabela nova. A foto do planejado × executado viaja
dentro de planejamento_tarefa.payload.exec ({ha, n, meta, em}, gravada
pelo app porque o de-para descrição → operação mora no index.html), e o
sql/050 e o sql/051 só acrescentam LEITURA dela (area_planejada,
area_executada, pct_area, tarefas_sem_lancamento). Rodar de novo os dois
arquivos é seguro: eles substituem a visão e as funções, sem tocar em
dado nenhum.
Desde a v82: aparelho_sync (sql/052; carimbo de "este aparelho
sincronizou" — id aleatório do aparelho, unidade aberta, versão do app e
tamanho da fila; alimenta o cartão "📡 Chegada dos boletins hoje" da
Diretoria). O app escreve DIRETO, fora da fila offline, e lê só com
painel. Não guarda nome, telefone nem localização.
Um robô (pg_cron + pg_net no Supabase) busca dados da API iCrop toda
madrugada e grava em icrop_manejo. O app apenas LÊ essas tabelas.

## Nomenclatura e histórico (REGRA PERMANENTE desde a v76)
Os termos do app são os que o funcionário fala. Revisar nomenclatura é
tarefa normal — reescrever o passado, nunca.
1. **Nenhum boletim já lançado perde sentido.** Trocar o texto de um
   termo NÃO altera nada que já foi gravado (boletins.payload e
   companhia). O registro fica com a palavra do dia em que foi feito.
2. **Quem traduz é a leitura.** Antigo → novo vive na tabela ÚNICA
   `DEPARA_NOMES` do index.html, aplicada pela função única
   `nomeAtual(nome)` em toda exibição, soma, comparação (plano, filtro,
   última receita) e classificação (badge de categoria). Nenhuma tela
   monta o próprio de-para.
3. **De-para é de UM para UM.** Termo antigo que se abre em DOIS novos
   não é adivinhado: entra em `TERMOS_LEGADO` (com a NATUREZA dele, que
   é a mesma nos dois candidatos), sai da escolha de lançamento novo,
   continua legível e somando, e a pergunta vai ao Nilo no resumo do PR.
4. **Espelho no Supabase pela mesma regra:** nome antigo vira apelido em
   `operacao_alias` (igualdade exata) e a operação substituída sai com
   `ativo = false` — nunca `delete`, nunca `update` de payload.
5. **PR de renomeação traz três colunas:** termo antigo → termo novo,
   termos acrescentados, termos mantidos; mais a lista dos ambíguos.
Prova: `node scripts/teste_nomenclatura.cjs` (sem rede, 390 px).
Detalhe em docs/definicao-de-pronto.md, item 17; o catálogo
vigente do café está em docs/catalogos-por-atividade.md, seção CAFÉ.

## Segurança (INEGOCIÁVEL)
- NUNCA colocar tokens, senhas ou chaves secretas no código ou em
  commits. O token da iCrop vive só no Supabase (tabela segredos,
  acessível apenas pelo SQL Editor). A única chave permitida no
  código é a publishable do Supabase.
- Não criar dependências externas (CDNs, bibliotecas) sem pedido
  explícito.

## Estilo visual (identidade do app — respeitar sempre)
Tons de papel, vermelho óxido nas ações primárias, verde folha para
conformidade, âmbar para alertas. Números em fonte monoespaçada
tabular. PROIBIDO: gradientes, sombras, cantos arredondados, botões
em formato pílula, emojis decorativos novos.

## Domínio (vocabulário)
Fazenda > Talhão (menor unidade de custo). Fazendas irrigadas com
iCrop: Cachoeira do Rio Preto—Lagamar (f03), Vereda (f22),
Floramill (f33), Capoeira Grande (f27). O de-para nome-iCrop → id
do app está na constante DEPARA_ICROP do index.html.
Perfis de uso: gerente (preenche) e diretoria (painel).

## Plano de safra (regras permanentes desde a v52)
O plano do agrônomo (Salvino) entra no app SÓ como referência e
comparação — nunca como receituário. Modelo de dados e fluxo em
docs/PLANO-DE-SAFRA.md. Regras que não se discutem:
1. **Nenhum texto do app pode ser lido como prescrição.** Nome de
   produto do plano só aparece (a) em cartão de leitura com o rótulo
   fixo "previsto pelo agrônomo — registre o que foi feito" e (b) como
   chip que preenche a calda com o nome do produto que o gerente JÁ
   usou. Nunca com o verbo "aplicar", nunca com dose.
2. **kg do plano nunca aparecem por padrão** na tela do gerente. Só ao
   tocar em "ver plano", rotulados "plano v_N".
3. **Identidade só pelo cadastro mestre.** A chave é unidade_manejo.id
   (codigo imutável); nomes são aliases em unidade_alias. Nenhuma regra
   pode usar pedaço de nome de fazenda, arquivo ou slide ("Lagamar"
   está em 2 fazendas, "Rio Preto" em 2, "Vereda" em 3). Nome de
   fazenda do plano que não bate EXATAMENTE com o cadastro do app não
   é mapeado: pare e pergunte ao Nilo.
4. **Faróis dizem "sem registro", nunca "não fez".** Vermelho só depois
   de a janela fechar. Farol e alerta do plano são da Diretoria; o
   gerente não vê nenhum.
5. **Mudança no plano só por nova versão** (Escritório/ADMIN), nunca
   editando as tabelas vigentes. Uma versão vigente por fazenda-safra;
   publicar passa a anterior para "superado". Nada se apaga.
Zero campos novos para o gerente por causa do plano (única exceção
prevista: o chip "chumbinho visível", fase B). Sem plano ou sem rede,
o boletim funciona exatamente como antes.

## Como trabalhar neste código
- index.html é grande; localize funções por busca (ex.: icropDo,
  baixarIcrop, telemetriaDo, SYNC_PADRAO).
- Toda mudança: mínima e cirúrgica. Não reformatar o arquivo, não
  renomear funções existentes, não "melhorar" o que não foi pedido.
- Antes de finalizar, validar sintaxe do JavaScript extraído
  (node --check) e conferir que o HTML abre sem erro.
- Cartões novos seguem o padrão dos existentes (classe "cartao",
  avisos com classe "aviso").

## PADRÕES DE TELA (obrigatórios em qualquer tela nova ou alterada)
Lei da casa desde 05/09/2026: poluição de tela é barrada na entrada —
em toda tarefa, antes do PR. Vale para tela nova e para tela alterada
(mexeu numa seção, a seção inteira passa a ter de cumprir o padrão).

### a) Boletim — padrão de lançamento em 3 passos
Toda seção de lançamento (atividade, operação, colheita, praga,
ocorrência, pivô, função de mão de obra, movimento de rebanho,
sanidade, cocho, contagem, manejo) segue a mesma sequência:
1. ONDE — chips de talhão / pivô / lote / pasto;
2. O QUÊ — chips de fase / tipo / grupo;
3. DETALHES — só os campos pertinentes ao que foi escolhido.
Nada visível antes do toque anterior: ao tocar em "＋" aparecem só os
chips do ONDE; escolhido o ONDE, só os chips do O QUÊ; escolhido o
O QUÊ, só os campos daquela escolha. Seção fechada por padrão. Ao
abrir, mostra só a lista compacta do que já foi lançado e o botão
"＋". Depois de adicionar, o registro vira linha compacta e a seção
volta ao estado compacto. Seletor (select) não substitui chip no
ONDE nem no O QUÊ.

### b) Cadastros e telas administrativas — padrões P1 a P10
- P1 Uma tela, um propósito.
- P2 Navegação menu → lista → detalhe, no máximo 3 níveis.
- P3 Altura-alvo de 2 telas (2 × 844 px a 390 px de largura); busca
  obrigatória em toda lista com mais de 12 itens.
- P4 Cabeçalho fixo com "‹ Voltar" e ação principal fixa no rodapé,
  visível sem rolar.
- P5 Progressive disclosure: "Mais opções" e "Zona de cuidado"
  existem e nascem fechados; o raro e o perigoso moram lá.
- P6 Ordem por frequência de uso: o que se faz todo dia vem primeiro.
- P7 Estado visível na própria linha da lista (ativo/inativo, ciclo,
  área, código), sem precisar abrir o item.
- P8 Retorno ao contexto depois de salvar: volta à lista, na posição
  do item, com "Salvo" discreto.
- P9 Sem popup em cadeia (alert/prompt/confirm em sequência) e sem
  acordeão dentro de acordeão.
- P10 Padrão visual da casa: sem gradiente, sem sombra, sem canto
  arredondado, sem botão-pílula; alvo de toque ≥ 44 px. Tela nova usa
  as classes de Cadastros (cad-menu, cad-item, cad-busca, cad-rodape,
  cad-bloco), que já cumprem o padrão.

### c) Regra de exibição por atividade
Nenhuma seção, campo, chip, rótulo ou termo de uma atividade aparece
na tela de outra: café não vê pivô nem cabeça; grãos não vê lata nem
cocho; pecuária não vê talhão de café nem soja. A lista oficial de
termos exclusivos está em docs/catalogos-por-atividade.md, seção
"Termos exclusivos por atividade" — termo novo no catálogo de uma
atividade entra lá na mesma tarefa.

### c2) Estados de lista: carregando, erro e vazio (desde a v61)
Toda tela ou seção de leitura distingue os três estados e passa
pela função única `htmlEstado(estado, recorte, embrulho)` /
`fraseVazio(recorte)` do index.html — nenhuma tela escreve a própria
frase de vazio. O vazio NOMEIA o recorte ativo (unidade, atividade,
operação, talhão, busca, período: "Sem boletim registrado em
Floramill de 01/09 a 07/09/2026") e relata ausência de REGISTRO,
nunca de trabalho: proibidos "não fez", "não realizou", "pendente",
"atrasado", "faltou", "esqueceu"; sem exclamação, sem emoji, sem
culpar quem usa; uma frase, no máximo duas linhas no iPhone. Nomes
só pelo cadastro por id. Vale para as três atividades pela mesma
função (café desde a v65; até a v64 o café mantinha os textos
antigos). Detalhe, parâmetros e exemplos em
docs/definicao-de-pronto.md, item 6.

### c3) Dado de fonte externa diz de quando é (desde a v63)
Todo bloco que mostre dado de integração (iCrop, Solinftec, fonte
futura) leva no rodapé UMA linha secundária pela função única
`linhaOrigemDado(fonte)` — "Dados do iCrop de hoje, 04:05" (data do
dado gravado, em Brasília; hoje/ontem/dd/mm) — e, com mais de 26 h sem
sucesso do robô, "Última atualização do iCrop há 2 dias" em cor de
atenção, sem ícone, exclamação ou bloqueio. Proibido "agora" / "tempo
real". Vale para as três atividades e para o painel da Diretoria
(café desde a v64, por decisão do Nilo: dado de irrigação iCrop e de
máquinas é gestão do cafeicultor). Detalhe em
docs/definicao-de-pronto.md, item 7.

### c4) Isolamento é de comportamento, não de arquivo (desde 08/09/2026)
Correção de escopo decidida pelo Nilo: a regra 1 (café intocado)
significa que uma alteração feita para grãos ou pecuária NUNCA muda o
que o café faz — e vice-versa; nunca significou que o café não pode
receber a mesma melhoria. Toda melhoria de leitura (métrica, estado de
lista, carimbo de origem, navegação) é aplicada às três atividades,
com um filtro de aplicabilidade agronômica ("isto faz sentido para a
cafeicultura?") respondido por escrito no PR quando não se aplica.
Regras: (1) mesmo componente, mesma função, mesma view — nunca uma
variante por atividade; (2) diferença legítima de vocabulário vem do
catálogo por atividade, por chave substituta, nunca de condicional
por atividade no código; (3) nenhum campo novo de digitação, nenhum
texto prescritivo, "sem registro" e nunca "não fez"; (4) a tela de
apontamento em 3 passos não recebe navegação nem métrica; (5) a prova
de isolamento é a regressão (scripts/regressao_render.cjs): grãos e
pecuária idênticos quando a tarefa é de café, e o contrário.

### c5) Cabeçalho contextual nas telas de leitura (desde a v66)
Toda tela de leitura com unidade escolhida mostra onde a pessoa está
pelo componente ÚNICO `cabecalhoContexto(fazendaId, {sub, voltar})`
do index.html — nunca uma variante por atividade e nunca `topo()` com
o nome da fazenda montado à mão. Telas: casa do gerente, boletim
enviado, casa e registro do pós-colheita, relatório do gerente e
Diretoria › Faróis › unidade, nas três atividades. Fora, por desenho:
a home das três abas e a escolha de unidade (contexto ainda não
escolhido), a tela de apontamento em 3 passos e o formulário do
pós-colheita (entrada), e as telas de grupo da Diretoria (painel,
Relatórios, Faróis, Resumo do período) e de Cadastros.
- **Linha 1 (sempre visível, na barra sticky `.topo.ctx`):**
  `Fazenda › Unidade (1.234,56 ha)`. Fazenda = fazenda física
  (`maeDe(f).nome`); unidade = rótulo da atividade pelo catálogo
  `ATIVIDADES` (unidade operacional = fazenda física + atividade,
  identificada por id, nunca por pedaço de nome); área = `areaUnidade`
  (soma dos talhões cadastrados na unidade, sem ESTRUTURA e sem
  ARRENDADO), formatada por `fmtHa` (duas casas, vírgula, ponto de
  milhar), em tipografia secundária. Sem área, o parêntese inteiro
  some — nunca "(— ha)", "(0 ha)" ou "(sem área)".
- **Linha 2 (só no topo da tela, faixa `.ctx-l2`):** ciclo da
  atividade pelo catálogo `CTX_ATIVIDADE[atv].ciclo` (grãos: "ciclo:
  Feijão, Soja" — culturas dos ciclos ativos dos talhões; café e
  pecuária: `null`, sem safra inventada) + texto próprio da tela
  (`sub`: papel, data, período). Vocabulário só pelo catálogo, por
  chave; proibido `if(atividade==="CAFE")` nas telas.
- **Colapso sem JS e sem salto:** a faixa da linha 2 é estática e rola
  por baixo da barra sticky; ao voltar ao topo reaparece. Nada muda de
  altura. Medidas a 390 × 844: barra 64 px + faixa 19 px = 83 px
  expandido (9,9 % de 844; 11,9 % de 700 px úteis), 64 px colapsado
  (7,6 %). O piso de 64 px é dos botões "‹" e "⇥" da barra.
- **Ordem de corte se não couber:** atividade (já é a unidade da linha
  1), depois ciclo; fazenda, unidade e área ficam. A linha 1 pode
  ocupar duas linhas visuais dentro dos 40 px dos botões (line-clamp).
- **Orçamento conjunto com a régua de 7 dias (desde a v73, item c11):**
  nenhuma tela empilha outra barra sticky sobre o cabeçalho; a régua é
  estática, logo abaixo dele, e o conteúdo vem abaixo dos dois.
  Medido a 390 × 844: cabeçalho expandido 83 px + faixa de cor 3 px +
  régua 48 px + margem 12 px = 148 px (17,6 % de 844; 21,2 % de 700 px
  úteis; no pós-colheita, sem faixa de cor, 145 px) — teto de ~25 %.
  Colapsado (rolando), só a barra de 64 px fica fixa. Se um dia não
  couber, o cabeçalho corta na ordem acima antes de a régua encolher;
  a régua nunca ganha rolagem.
- **Proibido no cabeçalho:** produtor/empresa, ícone de cultura, custo,
  produto, dose, "não fez"/"pendente", carimbo de origem de dado (esse
  fica no rodapé do bloco, item c3).

### c6) Badge de categoria da operação nas listas de leitura (desde a v67)
Nas listas de leitura que misturam naturezas de operação, cada linha
leva à esquerda do nome um quadrado de UMA letra maiúscula pelo
componente ÚNICO `badgeCategoria(atividade, {id | nome})` do
index.html — nunca uma variante por atividade. A categoria e a letra
vêm do catálogo `OP_CATEGORIAS` (fonte:
docs/catalogos-por-atividade.md, "Categorias de operação"), ligadas à
operação pelo id do catálogo (`operacao_catalogo.id`): a letra é
ATRIBUTO do catálogo, nunca derivada de pedaço de nome; máximo 5
categorias por atividade, letra única na atividade; nenhuma categoria
é classe de agroquímico — descreve a natureza da operação. Ideia do
app Sigma (Fundação ABC): só o mecanismo visual, nunca as categorias.
- **Sem cor por categoria — decisão explícita.** Fundo neutro único
  (`--linha`) e texto `--tinta` para todas as letras. A cor é canal
  semântico reservado ao farol (regra 4 do plano de safra): se a
  categoria ganhasse cor, verde e vermelho passariam a significar duas
  coisas na mesma tela. A letra já carrega a informação.
- **Visual:** 20 × 20 px, sem raio, sem sombra, monoespaçado, à
  esquerda do nome e centrado na primeira linha (inline dentro do
  `<b>` do nome); nunca empurra o nome para a segunda linha.
- **Acessível:** nome da categoria em `aria-label` e `title`;
  `role="button"`, Enter/Espaço equivalem ao toque.
- **Legenda só sob demanda:** toque no badge mostra o nome da
  categoria por 2,5 s (ou até o 2º toque / toque fora). Nunca legenda
  fixa ocupando espaço. Área de toque de 44 px por pseudo-elemento, sem
  crescer o quadrado.
- **Sem categoria, sem badge:** operação fora do catálogo ("Outra",
  termo do escritório) não recebe placeholder, traço ou "?".
- **Onde não entra:** apontamento em 3 passos; lista já filtrada por
  uma categoria (repetir a mesma letra é ruído); resumos de uma linha.
- Conferência: `node scripts/gerar_categorias_operacoes.cjs` (≤ 5,
  letras únicas, toda operação em uma categoria). Espelho opcional no
  Supabase: sql/046 (o app não lê).

### c7) Texto longo em lista nasce colapsado (desde a v68)
Todo texto longo numa lista de leitura (hoje: os textos do robô-redator
em Diretoria › Relatórios › "Textos para revisar" e na tela do relatório
narrativo) entra pelo componente ÚNICO `cartaoTextoLongo(o)` do
index.html — nunca uma variante por atividade ou por perfil. O cartão
nasce COLAPSADO, nesta ordem: tag de aviso ("gerado automaticamente —
revisar antes de enviar"), título (destinatário), prévia de 3 linhas,
linha compacta de origem e duas ações lado a lado: "ler texto completo
›" e a ação principal ("📲 copiar para WhatsApp").
- **A ação principal funciona sem expandir** e age sempre sobre o texto
  integral (nunca sobre a prévia). Um cartão colapsado cabe em menos de
  uma tela do iPhone; com um ou dois textos, o cabeçalho da seção
  seguinte ("Números") fica visível sem rolar.
- **Prévia corta por linha inteira** (`max-height` em múltiplo do
  `line-height`), nunca no meio da palavra, com reticências reais no
  canto reservado. Fade é gradiente, e gradiente é proibido. Texto que
  cabe nas 3 linhas não mostra reticências nem "ler texto completo"
  (`ajustarTextosLongos` mede depois de desenhar).
- **Ler é em tela cheia** (`abrirFolhaTexto`, classe `.folha`), nunca
  expansão na lista: cabeçalho fixo com "‹ Fechar", tag, texto completo
  rolável, origem completa e rodapé fixo com Fechar + ação principal.
  Ao fechar, a lista volta exatamente à posição de rolagem de antes
  (corpo travado por `body.folha-aberta` enquanto a folha está aberta).
- **Origem em duas versões:** compacta no cartão ("robô-redator ·
  dd/mm hh:mm") e completa só na folha ("Redigido no Supabase por
  <modelo> em dd/mm, hh:mm a partir dos números do relatório"). Um
  aviso só: a tag; nenhum "confira antes de mandar" repetido no rodapé.
- **Nenhum campo de digitação:** o texto é só leitura; o ajuste é feito
  no WhatsApp depois de colar. Nada é editado nem gravado pelo app.
- Conferência: `scripts/checar-poluicao.cjs`, item 8 (semente de
  textos em Relatórios); detalhe em docs/definicao-de-pronto.md, item 10.

### c8) Resposta explícita de ausência nas seções eventuais (desde a v69)
Seção do boletim classificada como EVENTUAL (docs/catalogos-por-
atividade.md, "Seções do boletim: eventual × esperada"; catálogo
`SECOES_BOLETIM` do index.html, espelho em `boletim_secao`) mostra, sem
registro, o par de chips **"Nada a registrar hoje" · "Registrar…"** pelo
componente ÚNICO (`chipsRespostaSecao` / `resumoSecaoHtml` /
`pintarSecoesResposta`) nas três atividades. Um toque grava
(`rascunho.secoes[id] = {resposta:"sem_ocorrencia", por, em}`) e
recolhe o cartão; o 2º toque desfaz; sem modal, sem ação em massa, sem
campo novo. Cabeçalho com três estados: "sem resposta" (não respondido
— texto neutro desde a v70, nunca vermelho nem cobrança), "sem ocorrência", "N registros". Registro
e resposta nunca coexistem (app e gatilho no banco). Ausência de linha
é o "não respondido" — não existe enum pendente. Seção ESPERADA nunca
recebe os chips (a ausência ali é do farol de leitura). Texto exato
"Nada a registrar hoje": proibido "Nada aconteceu", "Tudo certo",
"Sem problemas". Desde a v70 (decisão do Nilo) o envio EXIGE resposta em
toda seção eventual — registro ou "Nada a registrar hoje": ao tocar em
Enviar com seção sem resposta, o app abre as seções, mostra um aviso
âmbar ("Antes de enviar, responda: …") e não envia; nunca alert, nunca
"pendente"/"faltou". Seção esperada continua fora da exigência (não
existe "nada a registrar" legítimo nela; forçar criaria dado inventado).
Checagem em docs/definicao-de-pronto.md, item 11.

### c9) Ação de outro papel: oculta ou desabilitada visível (desde a v71)
Toda ação sujeita a perfil passa pela função ÚNICA `estadoAcao(id, ctx)`
do index.html, que lê o catálogo `ACOES_PERFIL` e devolve um de três
estados: **permitido** (o botão de sempre), **bloqueado_visivel**
(mesma forma e posição, esmaecido, nada executa) ou **oculto** (nada é
desenhado). O botão é desenhado por `botaoAcao(id, ctx, {rotulo, aria,
classe, attrs})`; `acaoOk(id, ctx)` responde só permitido/não. Nenhuma
tela decide sozinha com `if(sessao.papel===…)` ou `podeCadastros()?…:""`
em volta de um botão — a condição mora no catálogo. Mesmo componente nas
três atividades e em todos os perfis; nunca uma variante.
- **Regra de decisão da visibilidade** (negócio e privacidade, não
  técnica — a tabela vigente está em docs/acoes-por-perfil.md e toda
  linha nova é aprovada pelo Nilo antes de implementar). Só aparece
  desabilitada a ação que cumpre as TRÊS condições: (1) quem usa se
  beneficia de saber que ela existe — vai pedir a alguém, ou entende
  por que a tela dele é diferente da de um colega; (2) o rótulo não
  revela produto, dose, custo nem conteúdo de outra fazenda ou
  atividade; (3) a ação pertence ao mesmo domínio que a pessoa já
  enxerga. **Nunca** aparece: ação de outra atividade (pecuária não vê
  ação de café esmaecida — regra 1); ação administrativa de ADMIN para
  gerente ou pós-colheita; rótulo com produto, dose ou custo; ação que
  revele outra fazenda; código de acesso. Na dúvida, oculta.
- **Densidade:** nenhuma linha ou tela com mais da metade das ações
  desabilitadas; passou disso, as ações voltam a ficar ocultas. A tela
  de apontamento em 3 passos nunca recebe ação desabilitada.
- **Visual:** cinza neutro (`--tinta-2` sobre `--papel`, borda
  tracejada, sem sombra), mesma forma e posição da ação habilitada.
  Sem vermelho (cor é do farol, regra 4 do plano), sem cadeado, sem
  ícone de proibido, sem emoji novo. A borda tracejada existe para o
  estado não depender só do esmaecimento (baixa visão).
- **Comportamento:** o toque não executa nada e mostra por 2,5 s uma
  linha discreta acima do botão com quem executa a ação (some no 2º
  toque ou ao tocar fora); sem modal, sem alert. Texto pelo catálogo
  (`papel`), no formato "Ação do gerente (até 48 h após o envio)",
  "Ação da diretoria", "Ação do escritório (administrador)". Proibido
  "sem permissão", "acesso negado", "não autorizado", "bloqueado", "sem
  privilégio" — o tom nomeia o papel, não repreende a pessoa.
- **Acessível:** `aria-disabled="true"`, `aria-label` = rótulo + " — " +
  papel, `title`; o botão desabilitado não leva id nem data-* de ação,
  então nenhum tratador o alcança. Enter/Espaço equivalem ao toque.
- **Isto é interface, não segurança.** Esconder ou esmaecer botão não
  protege nada: a autorização real é das políticas RLS do Supabase e do
  escopo do código de acesso, que este padrão nunca afrouxa.
- Conferência: `scripts/checar-poluicao.cjs`, grupo "9. Ação
  desabilitada por perfil"; detalhe em docs/definicao-de-pronto.md,
  item 12.

### c10) Decisão e confirmação: diálogo único, validação silenciosa, verbo no botão (desde a v72)
Três padrões ligados a decisão (ideias do app Sigma, Fundação ABC: o
diálogo Não/Sim que resolve um planejamento num toque, o "Prosseguir"
cinza até existir ponto marcado e "Fazer Upload" no lugar de "OK").
- **Diálogo binário — componente ÚNICO `perguntar({pergunta, sim, nao,
  destaque, detalhes})`** do index.html (Promise<boolean>). `confirm()`
  e `alert()` nativos são PROIBIDOS (quebram o visual e não aceitam
  verbo no botão). Pergunta curta, em linguagem natural, terminada em
  "?", que DIZ o que vai acontecer — nunca "tem certeza?", sem emoji,
  sem exclamação, sem culpar ou advertir, nunca produto, dose ou custo.
  Exatamente dois botões e nenhum campo de digitação (regra 2): à
  esquerda a alternativa neutra ("Cancelar", "Voltar", "Revisar"); à
  direita a afirmativa com o verbo. `detalhes` (lista de linhas) só para
  o cinto de segurança do envio. Toque fora não decide; Escape cancela.
  Nunca uma variante por atividade ou por perfil.
- **Quando destacar a afirmativa (`destaque:true`, verde):** SÓ quando
  a ação é reversível E o caminho provável é claramente o mais frequente
  ("o sistema propõe, a pessoa aceita" — hoje só "Abrir ciclos" depois de
  um plantio lançado). **Nunca** em ação destrutiva ou irreversível
  (descartar rascunho, remover, encerrar, inativar, publicar, gerar novo
  código, esquecer o código, envio do boletim): os dois botões ficam
  neutros (`btn sec`) para a pessoa parar e escolher. Destaque em tudo
  treina o toque automático e esvazia as outras perguntas. Nunca usar
  diálogo binário para decisão cuja consequência a pessoa não prevê
  pelo texto da pergunta.
- **Validação silenciosa — componente ÚNICO `botaoAvanco(id, {rotulo,
  falta, classe, attrs})` / `atualizarAvanco(id, falta)`.** Botão de
  avanço, envio ou conclusão cuja pré-condição a pessoa ENXERGA na tela
  (formulário vazio, chip não escolhido, coluna não mapeada) nasce
  inativo com o MESMO visual do botão de perfil (c9: classe `.acao-off`,
  cinza neutro, borda tracejada, sem vermelho, sem cadeado — um só
  estilo de "inativo" no app), `aria-disabled`, não executa; o toque
  mostra `data-falta` por 2,5 s (mesmo mecanismo do `data-papel`) e,
  satisfeita a condição, o botão ativa NO LUGAR, sem redesenhar
  (`salvarRascunho` / `salvarRascPos` / `onchange` chamam
  `atualizarAvanco`). Diferença única em relação ao botão de perfil: este
  guarda o id (o interceptador de `.acao-off` no clique garante que nada
  executa). Texto de `falta` diz a próxima ação ("Registre o clima ou uma
  observação do dia", "Escolha a cultura do plantio"); proibidos "campo
  obrigatório", "preencha os dados", "erro de validação", "você
  esqueceu". Condição INVISÍVEL na tela (boletim já existente na data,
  erro do servidor, arquivo sem linhas) NÃO desabilita: o toque é
  permitido e explicado por `avisoInline(ancora, texto)` — uma linha
  `.aviso` acima do botão, que some no próximo redesenho. Nunca bloquear
  o envio por seção eventual sem resposta (c8/v70 decide isso com o
  aviso âmbar). A tela de apontamento em 3 passos não recebe botão de
  avanço (c4).
- **Verbo no botão:** todo botão de confirmação diz o que faz — verbo no
  infinitivo + objeto, até três palavras ("Enviar boletim", "Descartar
  rascunho", "Remover talhão", "Publicar versão"). Proibidos "OK", "Sim",
  "Confirmar", "Continuar", "Salvar" sozinho. O par nunca é Sim/Não:
  o afirmativo carrega o verbo, o negativo é "Cancelar"/"Voltar"/
  "Revisar". Botão que destrói nomeia a destruição.
- **Contenção:** entrega nova NÃO aumenta o número de confirmações do
  app (v72: 20 pontos, contagem no PR). Ponto que "poderia" ter
  confirmação e não tem vira sugestão no PR, nunca código; confirmação
  desnecessária em ação trivialmente reversível vira proposta de remoção
  (só com aval do Nilo). `prompt()` (campo dentro de diálogo) não entra
  em diálogo novo; os quatro que restam (recebimento de carga, novo
  plantio) estão listados no ESTADO.md como pendência.
- Conferência: `scripts/checar-poluicao.cjs`, grupo "10. Decisão e
  confirmação" (nenhum nativo dispara; Enviar inativo no formulário
  vazio, toque explica, clima ativa no lugar; Descartar abre o diálogo
  com dois botões, sem campo, pergunta com "?", verbo, sem destaque);
  detalhe em docs/definicao-de-pronto.md, item 13.

### c11) Régua de 7 dias nas telas de leitura por data (desde a v73)
Toda tela de leitura por data (hoje: casa do gerente nas três
atividades e casa do pós-colheita) escolhe o dia pelo componente ÚNICO
`reguaDias(fazendaId, dia)` do index.html, com `diaRegua(fazendaId)`
(dia escolhido; hoje por padrão) e `cartaoDiaRegua({dia, reg, que,
unidade, rotulo, attr, sub, farol})` (registro do dia escolhido ou o
vazio pela função única) — nunca uma variante por atividade ou por
perfil; nunca `input type="date"` nem datepicker nativo (regra 2:
nenhum campo de digitação). Fora, por desenho: tela de apontamento em
3 passos, home das abas, escolha de unidade, boletim enviado (uma
data só), telas de grupo da Diretoria (o painel e o Resumo do período
filtram por período, de/até) e Cadastros.
- **Sete células fixas**, do mais recente (esquerda — o polegar chega
  primeiro) ao mais antigo; nenhum dia futuro; sem rolagem de lado,
  sem setas, sem "carregar mais" (escopo fechado em 7 dias). Se um dia
  não couber com legibilidade, reduz para 5 — nunca rola. Medido a
  390 px: 7 células de 48,3 × 48 px (≥ 44 px), régua de 362 px.
- **Duas linhas por célula:** dia da semana em cima pelo catálogo
  `DIAS_SEMANA` (seg · ter · qua · qui · sex · sáb · dom — português,
  nunca Mon/Sun), número do dia embaixo em monoespaçado tabular.
- **Selecionado não depende só da cor:** fundo `--verde`, texto
  branco, número em negrito e `aria-pressed="true"`. **Hoje é
  reconhecível com outro dia escolhido:** barra de 3 px embaixo da
  célula (verde; branca quando também selecionada) e ", hoje" no
  `aria-label`/`title` ("quarta-feira, 09/09, hoje").
- **Um toque troca o dia** (`data-regua`) e redesenha a tela mantendo
  a rolagem; a escolha vive só na memória (`reguaVista`) e volta para
  hoje ao trocar de unidade, ao sair da janela de 7 dias e ao virar o
  dia com o app aberto (`visibilitychange` → primeiro plano recalcula
  "hoje" e redesenha a casa).
- **"Hoje" é o dia civil em Brasília** (`hojeBRT()`, `FUSO_BRT`),
  independente do fuso do aparelho; os registros guardam a data como
  texto AAAA-MM-DD e a comparação é por texto — sem deslocamento em
  relação ao banco (UTC).
- **Dia escolhido ≠ hoje:** a tela mostra o registro daquele dia numa
  linha tocável ("Boletim de 05/09 enviado · Enviado às 18:02 · …",
  abre o boletim) ou o vazio pela função única
  (`htmlEstado("vazio", {que, unidade, periodo: periodoVazio(dia,dia)})`
  → "Sem boletim registrado em Vereda Romaria em 05/09/2026."). O
  cartão de hoje, o botão "Preencher boletim de hoje", "O que ficou de
  ontem" e "Últimos boletins" continuam como eram (hoje selecionado =
  tela idêntica à v72). O cartão Solinftec segue o dia escolhido
  ("medição automática de 05/09"); o carimbo de origem fica no rodapé
  do bloco (c3), nunca na régua.
- **Vocabulário por chave:** o rótulo do registro ("Boletim" /
  "Registro" do pós-colheita) e o `que` do vazio ("boletim registrado"
  / "registro de pós-colheita") vêm de quem chama, por perfil de tela,
  nunca por `if(atividade==="…")`; dias e "hoje" são iguais nas três
  atividades (docs/catalogos-por-atividade.md, "Régua de 7 dias").
- **Altura:** régua estática (não sticky) abaixo do cabeçalho
  contextual; orçamento conjunto em c5 (148 px = 17,6 % de 844).
- **Proibido:** dia futuro, rolagem horizontal, datepicker ou teclado,
  navegação além dos 7 dias, "atrasado"/"pendente"/"faltou" no dia sem
  registro, cor como único sinal de seleção, régua na tela de
  apontamento.
- Conferência: `scripts/checar-poluicao.cjs`, grupo "11. Régua de 7
  dias" (7 células ≥ 44 px sem rolar de lado, pt-BR, hoje selecionado e
  marcado, toque sem nativo e sem sair da tela, vazio nomeia unidade e
  dia, conjunto ≤ 25 %, zero `input type=date`); detalhe em
  docs/definicao-de-pronto.md, item 14.

### c12) Chips removíveis na multi-seleção (desde a v74)
Toda multi-seleção FORA da tela de apontamento (o gerente ou o escritório
marca VÁRIOS itens de uma lista de chips: problemas da irrigação e setores
fertirrigados do café; atividades/unidades do código combinado, fazendas de
uma máquina e estrutura de pós-colheita em Cadastros) mostra
a seleção já feita pelo componente ÚNICO `chipsSelecao(attr, {um,
varios})` + `pintarSelecoes()` do index.html — nunca uma variante por
atividade ou por perfil. Ele só EXIBE a seleção: o mecanismo de escolha
(os chips de opção com `.on`) continua o que era; seleção única
(clima, status, destino, gravidade…) nunca recebe o componente; nenhum
seletor nativo foi trocado por chip nesta regra ("Talhão afetado" das
pragas fica para outra entrega). Pecuária não tem multi-seleção hoje
(cada campo escolhe um valor) — quando tiver, entra pelo mesmo
componente.
- **O que aparece, só quando há item escolhido:** contador ("3 setores
  selecionados" — substantivo por tela, vindo de quem chama, nunca de
  `if(atividade==="…")`; docs/catalogos-por-atividade.md, "Chips
  removíveis") e, abaixo, um chip por item na ordem do catálogo/
  cadastro, rótulo + × à direita. Contador e chips convivem; um não
  substitui o outro. **Seleção vazia não desenha nada:** nem contador
  zerado, nem área reservada (`.sel-box:empty{display:none}`).
- **O × remove na hora,** sem confirmação (é trivialmente reversível:
  basta tocar a opção de novo) e reaproveita o tratador do chip de
  opção (dispara o toque dele — nenhum mecanismo novo). Área de toque
  do × ≥ 44 × 44 px (o botão tem 44 px por si, sem crescer o chip);
  rótulo acessível "Remover <nome>" (`aria-label` e `title`), nunca só
  "x". Remover o último é estado válido: o bloco some, nenhum aviso.
- **O corpo do chip não faz nada** (decisão única em todo o app): a
  lista de opções está logo abaixo, no mesmo bloco, então "abrir a
  lista" não teria o que abrir; um alvo só evita remover o item errado
  com o polegar no sol.
- **Mais de 6 itens:** os 6 primeiros + um chip "+K" que expande (a
  expansão vive só na memória, `selExpandido`, e some quando a seleção
  cai). Quebra em linhas (`flex-wrap`); rolagem horizontal é PROIBIDA
  (esconde itens).
- **Visual:** mesma família dos chips de opção (`.chip`), sem cor nova
  (a cor verde é do chip de opção aceso; o chip removível é neutro), sem
  sombra, sem gradiente; × em `--tinta-2`. Rótulos são os do chip de
  opção, que quem chama já desenha pelo cadastro por id — nunca pedaço
  de nome.
- **Onde não entra:** seleção única; **tela de apontamento em 3 passos**
  (regra 7: nem no ONDE, nem no O QUÊ, nem nos DETALHES) — é por isso
  que o cartão do pivô dos grãos, cuja única multi-seleção ("Qual foi o
  problema?") mora ali, ficou de fora, e os grãos hoje não têm nenhuma
  multi-seleção fora do apontamento; listas de leitura; resumos de uma
  linha.
- Conferência: `scripts/checar-poluicao.cjs`, grupo "12. Chips
  removíveis" (café: problemas e setores; Cadastros: código combinado
  com 9 unidades) — e, nos grãos, a prova da AUSÊNCIA: com dois
  problemas do pivô escolhidos, zero contêiner na tela. Detalhe em
  docs/definicao-de-pronto.md, item 15.

### c13) Plano do dia seguinte × executado (desde a v75)
O gerente planeja SÓ o dia seguinte, ao fechar o boletim; as metas do mês
continuam sendo assunto da programação (Diretoria/Escritório). O app
cruza os dois níveis sozinho — nada de status digitado.
- **Onde mora o dado.** `D.planoDia` guarda os planos cujo dia-alvo ainda
  não fechou. Ao enviar o boletim do dia-alvo, o plano fechado (itens +
  status automático + motivo + clima declarado do dia) entra DENTRO do
  próprio boletim, em `b.plano`, e sai do `D.planoDia`. Assim ele sobe
  pelo payload de `boletins`, que já sincroniza: sem tabela nova, sem
  caminho de sincronização novo e sem nada digitado duas vezes. Por isso
  o campo de texto do boletim voltou a se chamar "O que ficou para
  terminar" — o plano de amanhã tem lugar próprio.
- **Componentes ÚNICOS, três atividades:** `abrirFolhaPlano(r, {alvo,
  replan})` (a folha "📋 Amanhã"), `faixaPlanoHoje(r)` /
  `pintarPlanoHoje(r)` (a faixa do topo do boletim), `linhaPlanoCasa` /
  `linhaPlanoSemana` (casa do gerente), `cartaoPlanoPainel()`
  (Diretoria), `avaliarPlano(plano, b)` (status), `planoResumo(fz, dias)`
  (todas as correlações), `gravarPlanoNoBoletim(r, motivo)` (o fechamento).
  A diferença de vocabulário — onde se planeja, quais operações existem,
  onde o registro aparece no payload — vem do catálogo `PLANO_ATIVIDADE`,
  por chave; proibido `if(atividade==="…")` nas telas (regra c4).
- **A folha "📋 Amanhã"** abre DEPOIS do cinto de segurança e ANTES de
  gravar, só quando o boletim que fecha é do dia de hoje. É pulável com
  um toque, nunca obrigatória, e nunca bloqueia o envio: dois botões no
  rodapé ("Pular" · "Salvar plano"), verbo no afirmativo (c10). Até 3
  linhas, no padrão de 3 passos (ONDE em chips → O QUÊ em chips →
  DETALHES: pessoas previstas), nada visível antes do toque anterior. Por
  ser apontamento em 3 passos, ela NÃO recebe régua (c11), chip removível
  (c12), ação desabilitada por perfil (c9), botão de avanço (c10), badge
  de categoria (c6) nem métrica (c4).
- **Sugestão automática:** o que o gerente marcou como "continua amanhã"
  já vem preenchido, com a tag "sugestão" — ele só confirma ou troca. A
  pré-marcação pelas METAS EM RISCO depende do módulo de programação/metas,
  que ainda não existe (ESTADO.md, PENDÊNCIAS).
- **A faixa "📋 O plano de ontem para hoje"** fica no topo do boletim, com
  até 3 linhas (uma linha visual cada a 360 px) e a caixinha de status que
  o app troca de ⚪ para ✅ sozinho conforme os lançamentos, no lugar, sem
  redesenhar. Unidade sem plano não mostra NADA — nem faixa, nem linha na
  casa, nem linha no cartão da Diretoria.
- **Status relata REGISTRO, nunca trabalho:** ✅ feito (todos os "onde" do
  item têm registro daquela operação), ◐ parcial (parte deles, ou registro
  marcado "continua amanhã"), ⚪ não feito (nenhum). Registro sem
  talhão/pasto cobre o item inteiro — na dúvida, a favor de quem
  registrou. Proibidos "não fez", "não realizou", "pendente", "atrasado",
  "faltou", "esqueceu".
- **Motivo do desvio:** com ⚪ ou ◐, UMA pergunta por chips ao fechar
  ("o que atrapalhou hoje?": choveu · máquina quebrou · faltou gente ·
  faltou insumo · mudou a prioridade · outro). Sem resposta grava "não
  informado" e o envio segue. **Dia impedido pelo clima DECLARADO no
  boletim** (`CLIMA_IMPEDITIVO` = Chuva forte, Granizo, Geada, ou chuva
  declarada ≥ `PLANO_CHUVA_MM`) nem é perguntado: o motivo entra
  automático como "clima" e **nunca conta como desvio evitável**.
- **Regras de justiça (não se discutem):** (1) item sem registro em dia
  impedido pelo clima é "clima", nunca evitável; (2) nenhuma tela expõe um
  gerente para outro — o cartão da Diretoria lista UNIDADES, sem nome de
  pessoa, ordenado por "unidades com mais desvios evitáveis" (apoio, não
  ranking); (3) o plano pode ser trocado no próprio dia (botão "ajustar" na
  faixa) e a troca fica registrada como "replanejado", nunca como falha.
- **Correlações, todas calculadas (`planoResumo`):** aderência (itens ✅ /
  itens planejados) em 7 e 30 dias; distribuição dos motivos no período;
  desvios evitáveis × de clima; dias trabalháveis × dias impedidos (fonte:
  o clima declarado no boletim); precisão de esforço (pessoas previstas ×
  pessoas lançadas na mão de obra). META × RITMO fica para quando o módulo
  de metas existir.
- **WhatsApp:** a primeira linha do resumo não muda; a aderência da semana
  entra SÓ no resumo de sexta.
- Conferência: `scripts/checar-poluicao.cjs`, grupo "13. Plano do dia";
  detalhe em docs/definicao-de-pronto.md, item 16. Consolidado mensal
  opcional no Supabase: sql/048 (o app lê pela vitrine de relatórios).

### c14) Lista longa de lançamento nasce agrupada e recolhida (desde a v76)
Quando o catálogo de uma seção de lançamento cresce a ponto de virar
listona, o passo O QUÊ passa a ser agrupado por natureza, com os grupos
RECOLHIDOS, pelo componente ÚNICO `seletorOperacao(a, {rotulo, grupos,
destaque, nota})` do index.html — o mesmo dos grãos desde a v58, agora
também do café. Nunca uma variante por atividade: o que muda é o
CATÁLOGO que quem chama passa (grãos agrupa por fase do ciclo, café por
natureza do serviço) e o rótulo do passo ("Operação" · "Atividade").
- **Nenhum grupo aberto por padrão.** Ao escolher o ONDE aparecem só os
  nomes dos grupos; o toque num deles revela as operações daquele grupo,
  em chips. Escolhida a operação, ela vira uma linha com "trocar" e só
  então os DETALHES aparecem.
- **Máximo 5 grupos**, os mesmos de `OP_CATEGORIAS` (o badge da c6 e o
  grupo do seletor são a MESMA coisa — uma fonte só).
- **Seletor nativo continua valendo no ONDE** enquanto o talhão/pivô/
  pasto não virar chip; isso é ❌ herdado listado no ESTADO.md, igual nas
  três atividades, e sai numa tarefa própria (mexeria nas três).
- Conferência: `scripts/checar-poluicao.cjs`, item 4 (depois do "＋", só
  o ONDE; nenhum campo e nenhum chip antes da escolha).

### c15) Planejamento: um toque no campo, cobrança no escritório (desde a v77)
O módulo de planejamento (reunião mensal + planejamento semanal) é a MESMA
tarefa vista em dois horizontes: a rodada da ata (por volta do dia 10) e a
semana (toda sexta, sem reunião). Concluir num horizonte atualiza o outro —
não existe cópia. Componentes ÚNICOS nas três atividades; o que muda por
atividade é o CATÁLOGO (`PLAN_VINCULO`/`PLAN_SINONIMOS`), nunca a tela.
- **O gerente muda status com UM toque e nunca digita.** A faixa
  `faixaTarefas(fz)` fica no topo da casa e do boletim (no máximo 3 linhas,
  ordem 🔴 → 🟡 → ⏸️ → 🟢, "＋N tarefas" para o resto); o toque abre a folha
  `planFolhaAbrir`, com Comecei · Concluí · Travado (chips) · Falar com o
  Nilo. Zero campo de digitação, zero diálogo. Novo prazo, quando existe, é
  chip (`PLAN_NOVOS_PRAZOS`), nunca calendário.
- **Tarefa travada por terceiro ou por chuva NUNCA fica vermelha para o
  campo.** Tem status próprio (AGUARDANDO TERCEIRO · AGUARDANDO CLIMA),
  farol ⏸️ cinza, e vira cobrança do escritório em "🔗 Pendências com
  terceiros". Tarefa sem prazo também é cinza. Vermelho é só prazo de 2
  dias, hoje ou vencido, e só em A INICIAR / EM EXECUÇÃO.
- **AGUARDANDO CLIMA sai da pausa sozinha** quando o boletim da unidade
  registra `PLAN_DIAS_SOL` dias seguidos sem clima impeditivo (a mesma
  fonte do plano do dia, v75). O prazo mostra "ajustado +N dias de chuva" e
  o prazo original nunca se perde (`prazoOriginal`).
- **Nada bloqueia o preenchimento do boletim.** A faixa é leitura; o envio
  não olha para tarefa nenhuma.
- **"Assumir", não "comprometer" (desde a v81).** O botão da tela da Semana que põe
  uma tarefa na semana corrente diz **assumir**; a lista é "Parte A · tarefas
  assumidas nesta semana" e o histórico lê "assumida na semana". A palavra
  anterior ("comprometer") não se explicava sozinha — o próprio dono do app
  precisou perguntar o que ela fazia. Regra que fica: **botão que muda o
  compromisso da semana usa o verbo que o escritório fala**, e o rótulo diz a AÇÃO
  ("assumir"), não o conceito ("compromisso").
  A chave gravada continua `campo:"compromisso"` em `D.tarefaHistorico`: é chave
  substituta, nunca aparece na tela, e trocá-la apagaria o sentido do histórico já
  gravado (regra da v76, item 2 — quem traduz é a leitura: `planHistTexto` monta o
  texto a partir do campo, então registro antigo também passa a ler "assumida").
- **Tudo roda dentro do app.** A ata entra por colagem (`ataParsear` +
  pré-visualização editável item a item, idempotente por rodada + unidade +
  descrição); a pauta da sexta, a cobrança por fornecedor, o fechamento do
  mês e o RASCUNHO DA PRÓXIMA ATA saem por botão copiar. Nenhuma planilha,
  nenhuma exportação.
- **Nada depende de alguém lembrar de abrir uma tela.** `planMotor()` roda
  na abertura do app, a cada sincronização e ao entrar no módulo; as
  pastilhas aparecem na porta de entrada (e somem sem pendência); na sexta e
  do dia 10 em diante a porta da Diretoria/Escritório é a tela curta do
  ritual, pulável — e o "pulado" vale só para a sessão, então volta no
  próximo acesso do mesmo dia.
- **De-para da ata por id, nunca por pedaço de nome** (`DEPARA_ATA_PADRAO`,
  editável em Cadastros › De-para da ata). Nome que não está no de-para NÃO
  é adivinhado: entra na pré-visualização como "unidade não reconhecida" e
  a pessoa escolhe (mesma regra 3 do plano de safra). Fazenda marcada
  `fora:true` é ignorada sempre, sem perguntar.
- **Nenhuma confirmação nova** (c10, contenção): toda ação do módulo é
  reversível e registrada em `D.tarefaHistorico`; cancelar é um STATUS com
  motivo, nunca um delete.
- **Planejado × executado × restante (desde a v78), componentes ÚNICOS.**
  `planTrio(t,{attr,aberta})` na folha do gerente e nas listas da área
  Planejamento. `planProgresso(t)` arredonda ANTES de subtrair: planejado,
  executado e restante SEMPRE fecham na tela. A meta é a área da ata (`t.area`)
  ou a que o escritório informar (`t.meta`, chip "Definir meta"); **sem meta não
  há barra nem restante** — o app diz isso com todas as letras e conta os
  lançamentos, nunca inventa denominador.
- **Duas formas, decididas pelo dado, não pela tela (desde a v79).** COM meta,
  os TRÊS números em três colunas iguais, com barra — é a forma certa para três
  números curtos ("96 ha · 42 ha · 54 ha"). SEM meta, "planejado" e "restante"
  não existem: o app mostra UMA linha, rótulo ao lado do valor
  (`.plan-um`), e a nota explica por quê. **Nunca desenhar coluna cujo valor é
  travessão** — é andaime vazio, pela mesma razão do `.sel-box:empty` da v74, e
  espremia o valor em duas linhas num terço da largura.
- **Rótulo no topo da coluna, nunca centrado.** Com `justify-content:center` um
  valor de duas linhas subia o próprio rótulo e descia os outros dois: os três
  títulos saíam de linha (10 px medidos a 390 px). Regra: numa fileira de
  colunas rotuladas, o rótulo ancora no topo (`flex-start`), para os títulos
  ficarem sempre na mesma linha de base qualquer que seja a altura do valor.
- **Fileira de filtros NÃO rola de lado (desde a v80).** Chip fora da tela é chip que
  não existe: na v79 as seis situações ("A iniciar", "Em execução", "Finalizado",
  "Aguardando terceiro", "Aguardando clima", "Cancelado") ficavam depois da borda
  direita e só apareciam arrastando. `.cad-saltos` passou a QUEBRAR EM LINHAS
  (`flex-wrap`), pela mesma razão que a rolagem lateral já era proibida nos chips
  removíveis da v74 (c12). Regras da fileira de filtros:
  (a) **nasce fechada** — a lista é o que a pessoa veio ver; o painel abre por
  `planBarraFiltros` num toque (P5);
  (b) **filtro ligado nunca fica invisível**: com o painel fechado, a própria linha
  nomeia o que está ligado e traz "limpar";
  (c) **cada grupo tem rótulo** (Prazo · Situação · Unidade · Origem) — sem rótulo a
  fileira quebrada vira um amontoado de chips sem sentido;
  (d) fileira com mais de `PLAN_FILA_MAX` chips mostra os primeiros e um "＋N" que abre
  o resto no lugar (mesmo mecanismo do "+K" da v74), e a fileira do filtro escolhido
  abre sozinha;
  (e) medido a 390 px: fechado, a 1ª tarefa começa a 193 px; aberto, os 22 chips
  visíveis, **zero escondidos e nenhuma fileira rolando**.
  A mesma classe serve os atalhos de Cadastros (`cadSaltos`), que tinham o defeito
  PIOR — 18 de 21 fazendas fora da tela: lá o teto é `CAD_SALTOS_MAX` e o atalho
  escolhido entra sempre entre os visíveis, para a escolha não sumir atrás do "＋N".
- **O alvo de 44 px é do BOTÃO, não do contêiner que o embrulha.** Na v78 o
  `.plan-tres > span` tinha 44 px e o `.plan-exec` dentro dele tinha 26 px — o
  dedo tinha 26 px. Hoje o botão ocupa a linha inteira na forma de uma linha, e
  no trio é esticado por pseudo-elemento (mesma técnica do × dos chips da v74 e
  do badge da v67), sem crescer a coluna.
- **O executado é RASTREÁVEL.** Um toque em "executado" abre, no lugar, a lista
  dos lançamentos que o compuseram — data, local, área e quem lançou
  (`planExecLista`). A soma em ha conta cada talhão UMA vez
  (`planExecucao`), e a janela vai do começo da tarefa até hoje ou até o dia em
  que ela foi concluída (`planJanela`) — depois disso o número congela.
- **O lançamento diz o que abateu.** Quando um registro do boletim casa com uma
  tarefa, ele leva a etiqueta `planTagVinculo` ("📋 abate: …") no boletim em
  edição e no boletim enviado, nas três atividades. É ETIQUETA de leitura,
  nunca botão nem métrica (regra c4-4).
- **Executado FORA do plano é a outra metade da história.** O lançamento que não
  casou com tarefa nenhuma aparece por unidade em Planejamento › Executado fora
  do plano (`planForaDoPlano`), com % dos lançamentos e pessoas-dia, e sai em
  texto para a próxima ata. A tela DIZ que não é cobrança — é o que apareceu no
  dia e não estava planejado.
- **Fechamento mensal por unidade** traz % do plano executado em ÁREA, % do
  esforço fora do plano e as tarefas sem NENHUM lançamento casado — na tela, no
  cartão do painel e no texto de copiar. "Sem lançamento" é ausência de
  REGISTRO casado, nunca afirmação de que não foi feito.
- **Vocabulário:** o módulo relata PRAZO e REGISTRO. "ATRASADO" é rótulo do
  prazo vencido, nunca julgamento de pessoa; proibidos "não fez", "não
  realizou", "pendente", "faltou", "esqueceu". Nenhuma tela expõe um
  gerente para outro: as listas da Diretoria são de UNIDADES.
- Conferência: `node scripts/teste_planejamento.cjs` (a validação da tarefa,
  com o texto real da ata) e `scripts/checar-poluicao.cjs`, grupo "14.
  Planejamento"; detalhe em docs/definicao-de-pronto.md, item 18.

### c16) Envio: a tela nunca diz "enviado" antes do banco confirmar (desde a v82)
Lição do primeiro dia de preenchimento (11/09/2026): até a v81 a casa do
gerente escrevia "Boletim de hoje enviado" assim que o boletim era gravado
no APARELHO, e o erro de rede do envio era engolido em silêncio.
- **Quem responde "enviado" é a FILA**, nunca a gravação local: registro
  fora de `syncFila` = o banco confirmou (recibo em `reg.sincEm`, escrito
  só quando o POST responde ok). Toda tela que anuncie envio passa por
  `estadoEnvio(t,id)` / `naFila(t,id)`.
- **Componente ÚNICO `faixaEnvio(fz,{t,rotulo})`** nas três atividades e no
  pós-colheita, estático (nunca sticky — orçamento de c5/c11), quatro
  estados: `✅ enviado às HH:MM` · `⏳ Enviando…` · `⏳ Aguardando internet
  (N na fila)` + "🔄 Tentar enviar agora" · `⏳ Aguardando envio` com o
  código HTTP da recusa. Some quando não há nada a dizer. `t` é chave
  substituta ("b"/"p") e o substantivo vem de quem chama — nunca
  `if(atividade==="…")`.
- **Erro nunca é invisível, e nunca culpa quem usa:** proibidos "erro",
  "falha", "você esqueceu"; a frase diz o que houve e que nada se perdeu.
- **Três chances automáticas** de esvaziar a fila: abrir o app, evento
  `online` e voltar ao app (`visibilitychange`). O indicador troca no
  lugar; o FORMULÁRIO nunca é redesenhado por isso (tira o foco de quem
  digita).
- **Gravação de diagnóstico vai DIRETO, fora da fila offline.** Tabela que
  ainda não existe devolve 404 e, na fila, o item ficaria preso para sempre
  acusando "aguardando internet" — foi o que aconteceu com
  `codigos_acesso`. Sem a tabela, falha em silêncio e o app fica idêntico.
- **Monitor do escritório relata RECEBIMENTO, nunca trabalho:**
  `cartaoChegadaBoletins()` nasce recolhido (P5), lista UNIDADES (nunca
  pessoas) e diz "nada recebido" — proibidos "não fez", "pendente",
  "atrasado" (c2).
- **Carimbo que não cabe em nenhuma linha da lista não pode sumir (desde a
  v84).** O aparelho que sincronizou SEM unidade aberta (`unidade_id` null
  — é o que acontece no código de Administrador, que abre na tela de
  escolher atividade) ganha um rodapé próprio no cartão: quantos são, há
  quanto tempo falaram com o banco, versão, código e fila. Sem ele o
  escritório veria "nada recebido" e nenhum aparelho — igualzinho a um
  celular nunca aberto, quando na verdade o celular está vivo. Regra geral:
  **lista agrupada por chave nunca engole a linha cuja chave está vazia** —
  ou ela aparece num rodapé nomeado, ou o cartão mente por omissão.
- Conferência: `scripts/checar-poluicao.cjs` (nenhum ❌ novo) e
  `scripts/regressao_render.cjs` contra origin/main — só a casa depois de
  enviar e o painel da Diretoria podem mudar; detalhe em
  docs/definicao-de-pronto.md, item 19.

### c17) Porta de entrada: código errado nunca é beco sem saída (desde a v83)
Lição de 11/09/2026: os ~15 gerentes estavam todos com um código de
administrador — que não abre a fazenda de ninguém (pergunta a atividade e
depois qual das 24 unidades) — e um código com uma letra trocada devolvia
só "Código inválido.", sem dizer o que fazer.
- **Código recusado diz o próximo passo, nunca só o veredito:** conferir
  letras e números e, se não entrar, pedir ao escritório o código **da
  própria fazenda**, que abre direto o boletim dela. Proibido "acesso
  negado", "não autorizado", "sem permissão" (mesmo tom de c9) e proibido
  revelar qualquer código.
- **Igualdade exata continua valendo:** `escopoDoCodigo` normaliza
  (maiúsculas, sem espaço, traço opcional) e compara igual. Tolerar "quase
  certo" transformaria a fechadura em sugestão.
- **Quem relata "este aparelho está no código errado" é o MONITOR, não a
  porta.** O cartão de chegada da Diretoria (c16) mostra o código de cada
  aparelho junto da última sincronização: a informação chega a quem age.
  **Aviso na porta de entrada foi tentado na v83 e retirado na v85** (decisão
  do Nilo): quem via o texto todos os dias era justamente o administrador,
  que já sabe — o gerente com o código da própria unidade nunca passa por
  aquela tela. Regra que fica: **aviso só na tela de quem pode agir sobre
  ele**; aviso permanente na porta de quem já conhece a situação é ruído, e
  ruído diário treina a pessoa a não ler.
- Continua sendo interface, não segurança (c9): a autorização real é das
  políticas RLS do Supabase. Detalhe em docs/definicao-de-pronto.md,
  item 20.

### d) DEFINIÇÃO DE PRONTO (obrigatória antes de abrir qualquer PR)
Versão detalhada em docs/definicao-de-pronto.md.
1. Rodar `node scripts/checar-poluicao.cjs` (instruções no cabeçalho
   do script; roda sem rede, a 390 px) e colar o checklist ✅/❌
   inteiro no resumo do PR.
2. PR com item ❌ NOVO não pode ser aberto — corrige antes. Os ❌ que
   já existiam estão listados no ESTADO.md (seção "Telas × padrões de
   tela"); tarefa que mexer numa tela com ❌ herdado deve zerá-lo, ou
   dizer no PR por que não zerou. A lista de ❌ só encolhe; nunca
   cresce.
3. Tela ou seção nova entra no ESTADO.md na mesma tarefa, com ✅ em
   todos os itens, e ganha cenário no script se ele ainda não a
   alcança.

## Documentação viva (OBRIGATÓRIO em toda tarefa)
- ESTADO.md (na raiz) descreve o que o app tem hoje e as pendências.
  TODA tarefa que mudar comportamento, catálogo, chave ou versão deve
  ATUALIZAR o ESTADO.md no mesmo pull request.
- docs/catalogos-por-atividade.md é a fonte oficial do vocabulário de
  operações e campos por atividade. Mudou catálogo no index.html?
  Atualize o arquivo junto — os dois nunca podem divergir.
- Quando uma tarefa exigir tabela nova no Supabase, gerar o arquivo
  sql/NNN-nome.sql no repositório com o bloco SQL pronto (create
  table, policies, comentários) e avisar no resumo final que o Nilo
  precisa rodá-lo no SQL Editor.
- docs/PLANO-DE-SAFRA.md descreve o modelo do plano de safra, o
  versionamento e o mapa Gantt ↔ chips. Mudou tabela, cache
  (bdf:plano), auditoria ou mapa? Atualize junto. Os dados de uma
  safra vivem em docs/plano/AAAA-AA/ e só entram por script
  (nunca editar o seed JSON à mão).
- Antes de abrir PR que mexa no index.html, rodar
  scripts/regressao_render.cjs contra a versão anterior (origin/main)
  e a nova, e conferir que as telas de gerente ficaram idênticas onde
  deviam (instruções no cabeçalho do script).
- Antes de abrir QUALQUER PR que mexa em tela, rodar
  scripts/checar-poluicao.cjs e colar o checklist no resumo do PR
  (DEFINIÇÃO DE PRONTO, seção PADRÕES DE TELA). Mudou o resultado de
  alguma tela? Atualize a seção "Telas × padrões de tela" do ESTADO.md
  junto.
