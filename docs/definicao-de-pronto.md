# Definição de pronto — Boletim NCNaves

Checklist que TODA tarefa cumpre antes de abrir pull request. É a
versão detalhada da seção "PADRÕES DE TELA › d) DEFINIÇÃO DE PRONTO"
do CLAUDE.md (que continua sendo a lei; este arquivo explica como
cumprir cada item). Regra nova entra aqui e no CLAUDE.md na mesma
tarefa.

## 1. Checagem de poluição de tela
Rodar `node scripts/checar-poluicao.cjs` (sem rede, 390 px) e colar o
checklist ✅/❌ inteiro no resumo do PR. PR com ❌ NOVO não abre; os ❌
herdados estão no ESTADO.md ("Telas × padrões de tela") e a lista só
encolhe. Tela ou seção nova entra no ESTADO.md com ✅ em tudo e ganha
cenário no script se ele ainda não a alcança.

## 2. Regressão das telas
Rodar `scripts/regressao_render.cjs` contra `origin/main` e o branch e
conferir que as telas do gerente ficaram idênticas onde deviam. A
regra 1 do projeto isola COMPORTAMENTO, não arquivo (CLAUDE.md, c4):
tarefa de grãos ou pecuária deixa o café byte a byte igual, tarefa de
café deixa grãos e pecuária byte a byte iguais, e a melhoria aplicável
às três atividades entra nas três pelo mesmo componente. Diferença que
não foi pedida é regressão.

## 3. Sintaxe
`node --check` no JavaScript extraído do `index.html` e no `sw.js`.

## 4. Versão
Rodapé "Boletim NCNaves · vNN" (constante `APP_VERSAO`) e cache
`boletim-lgs-vNN` do `sw.js` no MESMO número, em toda mudança
publicável.

## 5. Documentação viva
ESTADO.md (comportamento, catálogo, chave, versão),
docs/catalogos-por-atividade.md (catálogos), docs/PLANO-DE-SAFRA.md
(plano), docs/qualidade-log.md (uma entrada por entrega) e, quando
houver tabela nova, o `sql/NNN-nome.sql` pronto para o SQL Editor.

## 6. Estados de lista: carregando, erro e vazio (desde a v61)
Toda tela ou seção DE LEITURA (lista de apontamentos, histórico,
relatório, farol, lista de cadastro, resultado de busca) distingue
três estados e passa os três pela função única do `index.html`:

- **Carregando** — pedido em andamento: `htmlEstado("carregando",
  {que:"relatórios"})` → "Carregando relatórios…". Discreto, sem
  alarme.
- **Erro** — o pedido falhou: `htmlEstado("erro", {que:"os
  relatórios"}, {acao:true})` → "Não foi possível carregar os
  relatórios." + botão "Tentar de novo" (`data-sync`). Neutro: nunca
  culpa a pessoa nem afirma que a conexão caiu.
- **Vazio** — o pedido voltou sem dados: `htmlEstado("vazio", {...})`
  monta a frase com `fraseVazio` a partir do RECORTE ATIVO.

Regras de redação do vazio (valem para qualquer texto de ausência de
dado no app):
1. **Nomeia o recorte** que produziu o vazio: unidade, atividade,
   operação, talhão, busca e/ou período. Nunca "Nenhum registro" ou
   "Nada encontrado" sozinhos.
2. **Relata ausência de registro, nunca de trabalho.** Termos
   proibidos: "não fez", "não realizou", "pendente", "atrasado",
   "faltou", "esqueceu", "nada foi feito", "você ainda não…". Vale
   também para legendas de farol (● enviado · ○ sem registro).
3. **Sem exclamação, sem emoji, sem tom de alerta.** Vazio é estado
   normal do sistema, sobretudo em atividade nova (grãos e pecuária).
4. **Curto:** uma frase, no máximo duas linhas no iPhone (≈ 100
   caracteres). Segunda linha opcional e discreta para orientar o
   caminho ("Os boletins aparecem aqui depois do primeiro envio.").
5. **Neutro quanto a janela aberta ou fechada.** Vermelho e "janela
   fechada" são de outra camada (faróis da Diretoria), nunca do vazio.
6. **Nomes vêm do cadastro por chave substituta** (`fazenda(id).nome`,
   `talhao(id).nome`, `rotuloAtividade(k)`), nunca de string
   hardcoded nem de pedaço de nome.
7. **Nenhuma string de vazio solta pelo código:** tela nova chama
   `htmlEstado`; se precisar de um recorte que a função não monta,
   acrescente o parâmetro na função, não escreva a frase na tela.
8. **Café** (desde a v65): as telas de café usam a mesma função que
   as demais — casa do gerente, pós-colheita, tela do relatório,
   cartão de cargas de café em trânsito e Unidades e Plano (que já
   tinha os três estados com textos próprios e foi padronizada). Até
   a v64 o café mantinha os textos antigos por uma leitura
   conservadora da regra 1; a leitura correta está em CLAUDE.md, c4.
   Nenhuma tela decide texto de vazio por `atividadeDe(fz)`.
9. **Tela de leitura por data** (desde a v73): o vazio de um dia
   escolhido nomeia o dia — `periodo: periodoVazio(dia, dia)` → "Sem
   boletim registrado em Vereda Romaria em 05/09/2026." Nunca "sem
   boletim ainda", "dia em branco" ou "nada neste dia". Hoje e dia
   passado usam a mesma frase; a régua (item 14) só troca o recorte.
10. **Inventário no PR:** toda tarefa que toque numa tela de leitura
   lista no PR os pontos de vazio da tela (o que exibe, filtros ativos,
   se distingue carregando/erro/vazio). O inventário completo feito na
   v73 está em docs/qualidade-log.md (entrada da v73).

Parâmetros de `fraseVazio(o)`: `que` (o que falta: "boletim
registrado", "relatório calculado", "unidade"…), `atividade` (chave
CAFE/GRAOS/PECUARIA), `operacao`, `unidade` (id do app) ou `onde`
(recorte sem id: "nas unidades deste código"), `prep` ("em" por padrão;
"para" quando a frase pede), `talhao` (id), `filtro` (texto da busca),
`periodo` (use `periodoVazio(de, ate)`), `ultimo` (data ISO do último
registro → "Último registro há N dias (dd/mm)"), `dica` (segunda linha,
texto) ou `dicaHtml` (segunda linha com botão). `htmlEstado(estado, o,
w)` embrulha em `p`, `li`, `td` (com `colspan`) ou `div`, com `classe`
e `estilo` opcionais.

Antes do PR: `git grep -n "não fez\|não realizou\|pendente\|atrasad\|faltou\|esqueceu"`
no que foi tocado, e a lista de todas as frases de vazio criadas ou
alteradas vai no resumo do PR, tela por tela, para o Nilo revisar.

## 7. Dado de fonte externa informa de quando é (desde a v63)
Toda tela ou bloco que mostre dado vindo de integração (iCrop,
Solinftec ou fonte futura) traz, no rodapé do bloco, UMA linha em
tipografia secundária dizendo de quando é aquele dado — pela função
única `linhaOrigemDado(fonte)` do `index.html`, que lê
`vw_status_integracoes` (`sql/045`; detalhe em docs/relatorios.md,
"Estado das integrações"). Nenhuma tela escreve a própria frase.

Regras:
1. **A data é a do dado gravado** (`ultimo_dado_em`), nunca a da busca
   nem a de abertura da tela: "Dados do iCrop de hoje, 04:05" / "de
   ontem, 04:20" / "de 05/09, 04:05". Hoje/ontem para as duas datas
   mais recentes; data curta dd/mm daí em diante.
2. **Fuso explícito**: o banco manda UTC; a tela converte para
   `America/Sao_Paulo` sempre, independente do fuso do aparelho.
3. **Dado velho** (mais de 26 h sem sucesso do robô —
   `ultima_execucao_ok_em`): "Última atualização do iCrop há 2 dias"
   em cor de atenção (`--amarelo`), sem ícone, sem exclamação, sem
   modal, sem bloquear a tela. Nunca culpa a conexão de quem usa: a
   falha pode estar na API de origem.
4. **Proibido** em qualquer tela: "atualizado agora", "em tempo real",
   "ao vivo" ou equivalente.
5. **Uma linha por bloco de dado externo, no máximo.** Tela com duas
   fontes no mesmo bloco consolida numa linha só quando couber.
6. **Sem status conhecido, nada aparece** (visão não criada, sem rede
   e sem cache): a tela fica exatamente como antes. Nunca estimar.
7. **Café e painel** (desde a v64, decisão do Nilo em 08/09/2026): a
   linha vale para as três atividades e para o painel da Diretoria,
   porque a data da medição de irrigação (iCrop) e de máquinas
   (Solinftec) é informação de gestão do cafeicultor. Só entra onde há
   dado de integração: pós-colheita e a dica de chuva na seção Clima
   continuam sem a linha.
8. **Tentativa ≠ sucesso ≠ dado**: quem mexer na visão ou na tela
   mantém os três horários separados (tabela em docs/relatorios.md).
   Colapsar qualquer um deles faz dado velho parecer novo.

## 8. Cabeçalho contextual nas telas de leitura (desde a v66)
Toda tela de leitura com unidade escolhida (casa do gerente, boletim
enviado, casa e registro do pós-colheita, relatório do gerente,
Diretoria › Faróis › unidade) abre pelo componente único
`cabecalhoContexto(fazendaId, {sub, voltar})` do `index.html`
(CLAUDE.md, item c5) — nunca por `topo()` com nome de fazenda montado
na tela. Antes do PR, conferir:
1. **Linha 1** `Fazenda › Unidade (1.234,56 ha)`: fazenda física por
   `maeDe`, unidade = rótulo da atividade por `ATIVIDADES`, área por
   `areaUnidade`/`fmtHa`. Unidade sem talhão com área (hoje Porto
   Buriti e Monte Carmelo — Pecuária) omite o parêntese inteiro.
2. **Linha 2** só do catálogo `CTX_ATIVIDADE` (grãos: "ciclo: …";
   café e pecuária sem ciclo) + o `sub` da tela. Nenhum rótulo de safra
   inventado; nenhum condicional por atividade na tela.
3. **Altura**: expandido ≤ 12 % da altura útil (medido: 83 px a
   390 × 844; 64 px colapsado); a linha 2 rola por baixo da barra sem
   JS e sem mudar altura de nada. Tela nova não pode empilhar outra
   barra sticky em cima — se precisar de régua ou filtro fixo, a soma
   com o cabeçalho fica abaixo de ~25 % da altura útil. Medido na v73
   com a régua de 7 dias (item 14): 148 px = 17,6 % de 844 (21,2 % de
   700 px úteis) na casa do gerente; 145 px no pós-colheita.
4. **Regressão** (`scripts/regressao_render.cjs`): a diferença entre
   main e branch nas telas de leitura é só o trecho `.topo.ctx` +
   `.ctx-l2`, igual nas três atividades; tela de apontamento, home das
   abas, painel e Cadastros byte a byte iguais.
5. **Sem** produtor, custo, produto, dose ou carimbo de origem de dado
   no cabeçalho (o carimbo fica no rodapé do bloco, item 7).

## 9. Badge de categoria da operação (desde a v67)
Lista de leitura que mistura naturezas de operação usa o componente
único `badgeCategoria(atividade, {id | nome})` (CLAUDE.md, item c6).
Antes do PR, conferir:
1. **Sem cor por categoria:** todo badge tem o mesmo fundo neutro
   (`--linha`) e o mesmo texto (`--tinta`). Cor é do farol; um badge
   colorido é ❌.
2. **Letra do catálogo:** vem de `OP_CATEGORIAS` por id da operação
   (`codigoOperacao`) — nunca de `substring`, `startsWith`, regex ou
   `opCatDe` sobre o nome. `node scripts/gerar_categorias_operacoes.cjs`
   passa (≤ 5 por atividade, letras únicas, toda operação em uma
   categoria).
3. **Sem placeholder:** operação sem categoria não mostra nada (nem
   "?", nem "—", nem quadrado vazio).
4. **Nome acessível:** `aria-label` e `title` com o nome da categoria;
   toque (ou Enter/Espaço) mostra o nome por 2,5 s. Nenhuma legenda
   fixa na tela.
5. **Não empurra o nome:** badge inline dentro do `<b>` do nome,
   20 × 20 px; conferir a 390 px que o nome continua na mesma linha.
6. **Onde não entra:** apontamento em 3 passos, listas de uma categoria
   só, resumos de uma linha. Lista deixada de fora vai citada no PR com
   o motivo.
7. **Regressão:** a diferença main × branch nas telas de leitura é só o
   `<span class="op-cat">`, igual nas três atividades (mesmo componente).

## 10. Texto longo em lista nasce colapsado (desde a v68)
Texto longo numa lista de leitura (textos do robô-redator em Diretoria
› Relatórios e na tela do relatório narrativo; qualquer texto de mais
de 3 linhas que venha a entrar numa lista) usa o componente único
`cartaoTextoLongo(o)` (CLAUDE.md, item c7). Antes do PR, conferir:
1. **Nasce colapsado:** tag de aviso, título, prévia de 3 linhas,
   origem compacta e duas ações lado a lado. Nunca o texto inteiro
   aberto numa lista.
2. **Ação principal sem expandir:** "copiar" (ou a ação da tela) está
   no cartão colapsado e age sobre o texto integral, nunca sobre a
   prévia. Um cartão cabe em menos de uma tela; o cabeçalho da seção
   seguinte fica visível sem rolar com um ou dois textos na lista.
3. **Corte por linha inteira:** a prévia termina em palavra inteira,
   com reticências reais; sem fade (gradiente é proibido). Texto que
   cabe em 3 linhas não mostra reticências nem "ler texto completo".
4. **Ler é em tela cheia** (`abrirFolhaTexto`), nunca expansão na
   lista: cabeçalho fixo com Fechar, ação principal fixa no rodapé,
   origem completa. Fechar devolve a posição de rolagem anterior.
5. **Origem em duas versões:** compacta no cartão ("robô-redator ·
   dd/mm hh:mm"); completa só na folha. Um aviso só (a tag).
6. **Sem campo novo:** o componente não edita nem grava texto.
7. **Medição:** `scripts/checar-poluicao.cjs`, item "8. Texto longo em
   lista" — roda com textos de exemplo semeados na tela Relatórios e
   mede cartão, cabeçalho "Números", prévia, folha e rolagem.

## 11. Seção eventual oferece resposta explícita de ausência (desde a v69)
Toda seção do boletim classificada como **eventual** em
docs/catalogos-por-atividade.md ("Seções do boletim: eventual ×
esperada") — hoje pragas/doenças, ocorrências, movimentação e sanidade
do rebanho — mostra, quando não há registro, o par de chips
**"Nada a registrar hoje" · "Registrar…"** pelo componente único
(`chipsRespostaSecao` / `resumoSecaoHtml` / `pintarSecoesResposta`,
catálogo `SECOES_BOLETIM`). Seção eventual NOVA entra no catálogo (id
imutável, `campos`, `resumo`, `botao`, `acao`), na tabela
`boletim_secao` (sql) e na tabela do docs na mesma tarefa. Antes do PR,
conferir:
1. **Texto exato** "Nada a registrar hoje". Proibidos "Nada aconteceu",
   "Sem problemas", "Tudo certo" ou qualquer frase que afirme sobre a
   lavoura ou o rebanho — o chip declara que não há o que registrar.
2. **Um toque grava e recolhe o cartão; o 2º toque desfaz.** Sem modal,
   sem confirmação, sem ação em massa ("marcar todas").
3. **Chips só sem registro.** Com registro, o cabeçalho mostra o
   contador de sempre; adicionar um registro numa seção respondida
   apaga a resposta sozinho (app e gatilho no banco).
4. **Três estados distintos no cabeçalho:** "sem resposta" (não
   respondido — texto neutro desde a v70, decisão do Nilo; sem vermelho,
   sem cobrança enquanto o boletim está aberto),
   "sem ocorrência", "N registros". Proibidos "pendente", "faltando",
   "obrigatório", "você não respondeu", emoji de alerta, exclamação.
5. **Seção esperada não recebe os chips** — a ausência ali é do farol
   de leitura. Aplicar nos dois lugares confunde os conceitos.
6. **Vocabulário pelo catálogo** (`acao` por chave): nunca
   `if(atividade==="…")` na tela. Mesmo componente nas três atividades.
7. **Envio exige resposta nas eventuais (desde a v70):** Enviar com
   seção eventual sem resposta abre as seções, mostra UM aviso âmbar
   inline ("Antes de enviar, responda: A · B. Registre o que houve ou
   toque em Nada a registrar hoje") acima da primeira e rola até ela —
   sem `alert`, sem modal, sem "pendente"/"faltou". O aviso some ao
   responder. Seções esperadas ficam fora da exigência. Rascunho
   automático guarda `rascunho.secoes` como qualquer outro campo.
8. **Checagem de poluição:** o par de chips faz parte do estado
   compacto da seção eventual (o script ignora `[data-resp-secao]` no
   item 3); qualquer outro chip antes do "＋" continua ❌.
9. **Leitura:** "não respondido" = sem registro E sem linha em
   `boletim_secao_resposta` — nunca "não fez" (docs/relatorios.md,
   "Resposta explícita de ausência").

## 12. Ação sujeita a perfil declara se fica oculta ou desabilitada visível (desde a v71)
Toda ação NOVA (botão, chip de ação, item de menu) que algum perfil não
executa entra no catálogo `ACOES_PERFIL` do `index.html` e é desenhada
por `botaoAcao` / decidida por `estadoAcao` (CLAUDE.md, item c9) —
nunca por condicional solta na tela. Antes do PR, conferir:
1. **Declaração explícita:** a linha do catálogo diz `visivel` (quem vê
   a ação esmaecida) e, se visível, o `papel` (texto do toque). A
   tabela em docs/acoes-por-perfil.md ganha a linha correspondente com
   ação, tela, quem executa, quem vê desabilitada (ou "oculta") e o
   MOTIVO pelas três condições da regra de decisão. Sem motivo escrito,
   a ação fica oculta.
2. **Aprovação do Nilo antes de implementar** para toda linha nova com
   "exibir desabilitada" — a classificação é de negócio e privacidade
   (o que a ação revela: que existe, quem faz, que a pessoa não é
   aquele papel).
3. **Nunca visível:** ação de outra atividade; ação administrativa para
   gerente/pós-colheita; rótulo com produto, dose ou custo; ação que
   revele outra fazenda; código de acesso. Na dúvida, oculta.
4. **Densidade:** ≤ metade das ações da linha/tela desabilitadas
   (medido pelo script); zero na tela de apontamento em 3 passos.
5. **Texto do toque:** "Ação do/da <papel>" (+ condição entre
   parênteses quando houver prazo). `git grep -n "permiss\|negad\|autoriz\|bloquead\|privil"`
   no que foi tocado não pode achar texto de tela.
6. **Visual e acessibilidade:** cinza neutro, borda tracejada, sem
   vermelho, sem cadeado/ícone; `aria-disabled`, `aria-label` com o
   papel; sem id/data-* de ação no botão desabilitado.
7. **Segurança inalterada:** o PR afirma que nenhuma política RLS e
   nenhum passo da validação do código de acesso mudou.
8. **Regressão:** a diferença main × branch nas telas do gerente é só o
   botão `.acao-off`, igual nas três atividades; pós-colheita e tela de
   apontamento byte a byte iguais.
9. **Medição:** `scripts/checar-poluicao.cjs`, grupo "9. Ação
   desabilitada por perfil" (painel da Diretoria, boletim enviado visto
   pela Diretoria e pelo gerente das três atividades, e contagem zero
   na tela de apontamento).

## 13. Decisão e confirmação: diálogo único, validação silenciosa, verbo no botão (desde a v72)
Regra em CLAUDE.md, item c10. Antes do PR, conferir:
1. **Nenhum `confirm()`, `alert()` ou `prompt()` NOVO no código:**
   `git grep -n "confirm(\|alert(\|prompt(" index.html` só pode achar
   os quatro `prompt()` herdados (recebimento de carga, novo plantio na
   tela do gerente), listados no ESTADO.md. Toda pergunta passa por
   `perguntar(...)`; todo aviso que só se descobre depois do toque passa
   por `avisoInline(...)`.
2. **Todo diálogo tem exatamente dois botões e nenhum campo** de
   digitação; `role="alertdialog"`, `aria-modal`; toque fora não decide.
3. **Pergunta:** termina em "?", diz o que vai acontecer, sem "tem
   certeza", sem emoji, sem exclamação, sem culpar, sem produto, dose ou
   custo (vale também para as linhas de `detalhes`).
4. **Botão afirmativo com verbo no infinitivo + objeto, até três
   palavras;** nunca "Sim", "OK", "Confirmar", "Continuar". Negativo:
   "Cancelar", "Voltar" ou "Revisar". Nenhum par Sim/Não genérico.
5. **Destaque só em ação reversível e frequente.** Ação destrutiva ou
   irreversível (descartar, remover, encerrar, inativar, publicar, gerar
   novo código, esquecer código, envio) leva `destaque:false` — os dois
   botões neutros. Lista das perguntas com destaque no PR, com o motivo.
6. **Validação silenciosa:** botão de avanço cuja pré-condição é
   visível nasce inativo por `botaoAvanco` (visual do `.acao-off` da
   v71: cinza, tracejado, sem vermelho, `aria-disabled`), o toque mostra
   o que falta como próxima ação, e o botão ativa no lugar quando a
   condição é satisfeita (`atualizarAvanco`), sem redesenhar. Texto sem
   "campo obrigatório", "preencha os dados", "erro de validação", "você
   esqueceu", "faltou", "pendente":
   `git grep -n "obrigat\|erro de valida\|esqueceu" index.html` no que
   foi tocado não pode achar texto de tela.
7. **Nunca desabilitar por condição invisível** (boletim já existente
   naquela data, erro do servidor, arquivo sem linhas): o toque é
   permitido e explicado por `avisoInline`. Nunca bloquear o envio por
   seção eventual sem resposta (item 11.7 continua valendo).
8. **Contagem de confirmações no PR:** antes × depois; a entrega não
   pode aumentar o número. Pontos onde se pensou em confirmar e não se
   confirmou, e confirmações que se sugere remover, vão listados.
9. **Fluxo de apontamento em 3 passos intocado:** só rótulo de botão ou
   troca de nativo por componente; nenhuma etapa, ordem ou comportamento
   muda; zero botão inativo dentro do cartão de apontamento.
10. **Medição:** `scripts/checar-poluicao.cjs`, grupo "10. Decisão e
    confirmação" — stub de `alert`/`confirm`/`prompt` em toda página
    (conta chamadas nativas: tem de ser zero), Enviar inativo no
    formulário vazio das três atividades e do pós-colheita, toque explica
    sem alert e sem sair da tela, clima/terreiro ativa o mesmo elemento,
    Descartar abre o diálogo (dois botões, sem campo, "?", verbo ≤ 3
    palavras, sem destaque) e Cancelar mantém a tela.

## 14. Régua de 7 dias nas telas de leitura por data (desde a v73)
Regra em CLAUDE.md, item c11. Tela de leitura por data (casa do gerente
das três atividades, casa do pós-colheita; qualquer tela futura em que
o dia é escolhido) usa o componente único `reguaDias` /
`diaRegua` / `cartaoDiaRegua` — nunca `input type="date"`, datepicker
ou teclado (regra 2 do projeto). Antes do PR, conferir:
1. **Sete células fixas**, do mais recente à esquerda ao mais antigo,
   sem rolagem de lado, sem setas, sem "carregar mais"; nenhum dia
   futuro. Cada célula ≥ 44 × 44 px (medido: 48,3 × 48 a 390 px). Só
   reduz para 5 se 7 não couberem com legibilidade — nunca rola.
2. **Dias em português abreviado** pelo catálogo `DIAS_SEMANA` (seg …
   dom) e número do dia embaixo; `aria-label` com o dia por extenso e a
   data ("terça-feira, 08/09").
3. **Hoje selecionado ao abrir** e reconhecível com outro dia escolhido
   (barra de 3 px embaixo; ", hoje" no rótulo acessível); selecionado
   com fundo, negrito e `aria-pressed` — nunca só cor.
4. **Um toque troca o dia** e redesenha mantendo a rolagem; nenhum
   teclado ou seletor nativo abre; `telaAtual` não muda.
5. **"Hoje" em Brasília** (`hojeBRT`), comparação por texto
   AAAA-MM-DD, sem deslocamento de fuso; ao voltar ao primeiro plano
   depois da virada do dia, a régua recalcula "hoje" e a casa redesenha
   (`visibilitychange`).
6. **Dia sem registro cai no vazio da função única** (item 6, regra 9):
   "Sem boletim registrado em <unidade> em dd/mm/aaaa." — nomeia unidade
   e dia, sem termo proibido, sem "dia em branco".
7. **Hoje selecionado = tela idêntica à anterior:** o cartão de hoje,
   o botão de preencher, "O que ficou de ontem" e "Últimos boletins" não
   mudam; a regressão (`scripts/regressao_render.cjs`) só pode mostrar o
   bloco `.regua` como diferença, igual nas três atividades e no
   pós-colheita; tela de apontamento, boletim enviado, painel e
   Cadastros byte a byte iguais.
8. **Orçamento de altura** com o cabeçalho contextual (item 8.3): a
   soma fica abaixo de ~25 % da altura útil; a régua é estática, nunca
   uma segunda barra sticky.
9. **Sem SQL, sem campo novo, sem navegação além de 7 dias.**
10. **Medição:** `scripts/checar-poluicao.cjs`, grupo "11. Régua de 7
    dias" — na casa do gerente de café, grãos e pecuária e na casa do
    pós-colheita.

## 15. Chips removíveis na multi-seleção (desde a v74)
Regra em CLAUDE.md, item c12. Toda multi-seleção por chips (café:
problemas da irrigação e setores fertirrigados; grãos: problemas do pivô;
Cadastros: atividades/unidades do código combinado, fazendas de uma
máquina, estrutura de pós-colheita; qualquer multi-seleção futura) exibe
a seleção pelo componente único `chipsSelecao` / `pintarSelecoes`. Antes
do PR, conferir:
1. **Só multi-seleção recebe o componente.** Seleção única (um valor por
   campo) nunca; nenhum `<select>` nativo foi trocado por chip por causa
   desta regra; o mecanismo de escolha (chips de opção `.on`) não mudou.
2. **Seleção vazia não desenha nada:** o contêiner `.sel-box` fica vazio
   e sem altura (nem "0 selecionados", nem espaço reservado).
3. **Contador e chips juntos:** "N <substantivo> selecionad(o|a)s" acima
   e um chip por item abaixo, na ordem do catálogo/cadastro; o
   substantivo vem de quem chama, por tela (`{um, varios}`), nunca por
   condicional de atividade.
4. **× remove na hora,** sem confirmação, sem `confirm()`/diálogo, sem
   sair da tela; o chip de opção correspondente apaga e o dado é gravado
   pelo tratador que já existia. Área de toque ≥ 44 × 44 px; `aria-label`
   e `title` "Remover <nome>". Remover o último volta ao vazio, sem aviso.
5. **Toque no corpo do chip não faz nada** (decisão única no app).
6. **Quebra em linhas, nunca rola de lado** (`flex-wrap: wrap`,
   `scrollWidth` da página ≤ 390 px); sem sombra, sem gradiente, sem cor
   por item (o × é `--tinta-2`, nunca vermelho).
7. **Mais de 6 itens:** 6 chips + "+K" que expande para todos; até 6, sem
   "+K".
8. **Rótulos pelo cadastro por id** (o texto do chip de opção); nunca
   pedaço de nome.
9. **Apontamento em 3 passos intocado** (ONDE e O QUÊ são escolha única);
   café, grãos e pecuária pelo mesmo componente — na regressão
   (`scripts/regressao_render.cjs`) a diferença main × branch é só o
   `.sel-box` (vazio onde nada foi escolhido; preenchido onde o cenário
   escolhe), igual nas três atividades.
10. **Medição:** `scripts/checar-poluicao.cjs`, grupo "12. Chips
    removíveis" — café (problemas 2 de 8; setores todos, 8 de 8 → 6 +
    "+2"), grãos (pivô, 2 de 6), Cadastros › Códigos › novo combinado (9
    unidades → 6 + "+3"); pecuária registra "sem multi-seleção".
