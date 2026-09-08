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
Um robô (pg_cron + pg_net no Supabase) busca dados da API iCrop toda
madrugada e grava em icrop_manejo. O app apenas LÊ essas tabelas.

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
