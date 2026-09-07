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
conferir que as telas do gerente ficaram idênticas onde deviam (café é
intocável: regra 1 do projeto). Diferença que não foi pedida é
regressão.

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

## 6. Estados de lista: carregando, erro e vazio (desde a v60)
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
8. **Café** (regra 1): as telas do gerente de café mantêm o texto que
   já tinham; quem chama decide por `atividadeDe(fz)`. Telas
   compartilhadas (Diretoria, Relatórios, Cadastros) usam a função.

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
