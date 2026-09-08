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
   com o cabeçalho fica abaixo de ~25 % da altura útil.
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
4. **Três estados distintos no cabeçalho:** "○" (não respondido —
   neutro, sem vermelho, sem cobrança enquanto o boletim está aberto),
   "sem ocorrência", "N registros". Proibidos "pendente", "faltando",
   "obrigatório", "você não respondeu", emoji de alerta, exclamação.
5. **Seção esperada não recebe os chips** — a ausência ali é do farol
   de leitura. Aplicar nos dois lugares confunde os conceitos.
6. **Vocabulário pelo catálogo** (`acao` por chave): nunca
   `if(atividade==="…")` na tela. Mesmo componente nas três atividades.
7. **Envio nunca é bloqueado nem condicionado** pela resposta; rascunho
   automático guarda `rascunho.secoes` como qualquer outro campo.
8. **Checagem de poluição:** o par de chips faz parte do estado
   compacto da seção eventual (o script ignora `[data-resp-secao]` no
   item 3); qualquer outro chip antes do "＋" continua ❌.
9. **Leitura:** "não respondido" = sem registro E sem linha em
   `boletim_secao_resposta` — nunca "não fez" (docs/relatorios.md,
   "Resposta explícita de ausência").
