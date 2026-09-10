# Ações por perfil — o que fica escondido e o que aparece desabilitado

**Situação: VIGENTE desde a v71.** Tabela produzida no Passo 1 da tarefa
(08/09/2026) e aprovada pelo Nilo antes de qualquer código; é a
referência permanente da regra de decisão (CLAUDE.md, item c9) e a
lista viva das ações sujeitas a perfil. Toda ação nova sujeita a perfil
entra no catálogo `ACOES_PERFIL` do index.html E nesta tabela, com o
motivo pelas três condições; linha nova "exibir desabilitada" só depois
do aval do Nilo (docs/definicao-de-pronto.md, item 12).

## Como o controle de acesso funciona hoje (levantamento)

- O aparelho guarda `bdf:acesso` = {codigo, chave}. A **chave** define o
  escopo (`escopoDaChave`, index.html ≈ linha 1168): id de unidade,
  `ATV:…` (atividade), `MIX:…` (combinado), `DIRETORIA` (tudo, só
  leitura, painel) ou `ADMIN` (tudo + Cadastros).
- O código é comparado **em texto puro** com `CODIGOS_PADRAO` e com a
  tabela `codigos_acesso` do Supabase (`baixarCodigos`). **Não existe
  hash SHA-256 nem tabela `acessos` no código** — o ESTADO.md já chama
  isso de "fechadura de porta, não cofre". Esta tarefa não mexe nisso.
- Verificações centrais já existem e são poucas: `podeVer(fz)`,
  `podePainel()`, `podeCadastros()`, `soLeitura()`,
  `unidadesPermitidas()`. O que está espalhado é a **decisão de
  esconder** (condicional dentro do HTML de cada tela) — 9 pontos,
  listados abaixo. A centralização proposta (Passo 4) é uma função
  `estadoAcao(acao)` → `permitido` | `bloqueado_visivel` | `oculto`,
  lendo um catálogo `ACOES_PERFIL`, e um componente único
  `botaoAcao(...)` para desenhar o botão nos três estados.

## Regra de decisão (vale para toda ação nova sujeita a perfil)

Só aparece **desabilitada** a ação que cumpre as três condições:
1. quem usa se beneficia de saber que ela existe (vai pedir a alguém,
   ou entende por que a tela dele é diferente);
2. o rótulo não revela produto, dose, custo nem dado de outra fazenda
   ou atividade;
3. a ação pertence ao mesmo domínio que a pessoa já enxerga.

Nunca aparece: ação de outra atividade; ação administrativa (ADMIN)
para perfil operacional; rótulo com produto/dose/custo; ação que revele
outra fazenda. Na dúvida, esconde. Isto é interface, não segurança: a
autorização real continua no Supabase (RLS), que esta tarefa não toca.

## Tabela de classificação

Perfis: **G** = gerente (código de unidade, de atividade ou combinado);
**P** = pós-colheita (mesmo código, papel "Terreiro"); **D** =
DIRETORIA; **A** = ADMIN.

| # | Ação (rótulo na tela) | Tela | Quem executa | Quem não vê hoje | Recomendação | Motivo |
|---|---|---|---|---|---|---|
| 1 | Café / Grãos / Pecuária (abrir boletim da atividade) | Entrada | G da atividade | G de outra atividade; D; A não usa | **continuar oculta** | Outra atividade (regra 1: pecuária não pode nem saber que existe tela de café). Para D, mostrar 3 botões cinza deixaria mais da metade da tela desabilitada. |
| 2 | Terreiro / Secador / Benefício (pós-colheita) | Entrada | G/P com café no escopo | G de grãos/pecuária; D | **continuar oculta** | Domínio do café; para quem não tem café é outra atividade. |
| 3 | Diretoria — acompanha todas as fazendas | Entrada | D, A | G, P | **continuar oculta** | O painel mostra todas as fazendas: fora do domínio do gerente (condição 3). Ele já sabe que existe Diretoria; o botão cinza não o ajuda a pedir nada. |
| 4 | Relatórios (textos para revisar e números) | Entrada | D, A | G, P | **continuar oculta** | Relatórios de todas as unidades e textos do robô-redator (a devolutiva chega ao gerente pelo WhatsApp, depois de revisada). O gerente já tem "Meus relatórios" na casa dele. |
| 5 | Escritório / Administrador (Cadastros) | Entrada | A | G, P, D | **continuar oculta** | Ação administrativa. Na tela de entrada da Diretoria, ver #7. |
| 6 | Lista de unidades (Qual fazenda?) | Escolha de unidade | G do escopo | G de outras unidades | **continuar oculta** | Revelaria nome de outra fazenda. |
| 7 | ⚙ Cadastros (botão do painel) | Painel da Diretoria | A | D | **exibir desabilitada** — "Ação do escritório (administrador)" | D já enxerga todas as fazendas (mesmo domínio); rótulo neutro; ao ver um nome de unidade ou talhão errado, a Diretoria aprende a quem pedir a correção. Densidade: 1 de 4 botões da linha. Único ponto em que uma ação de ADMIN aparece — e só para a Diretoria, nunca para gerente. |
| 8 | ✏️ Corrigir (boletim enviado) | Boletim enviado (detalhe) | G, até 48 h do envio | D, A | **exibir desabilitada** para D e A — "Ação do gerente (até 48 h após o envio)" | Mesmo boletim que D/A estão lendo; rótulo neutro; a Diretoria aprende que quem corrige é o gerente e que há prazo. Densidade: 1 de 4. |
| 9 | Marcar como visto / ✓ Visto | Boletim enviado (detalhe) | D, A | G | **exibir desabilitada** para G — "Ação da diretoria" | É o boletim do próprio gerente (mesmo domínio); rótulo neutro; mostra ao gerente que a Diretoria lê e marca os boletins — retorno que hoje ele não tem. Densidade: 1 de 3 ou 4. **É o caso mais discutível da tabela**: se o Nilo preferir, fica oculta. |
| 10 | Relatórios só da Diretoria (Balanço hídrico, Irrigação recomendado × executado, Custo físico por talhão, Rebanho — mês, Plano × registrado, textos do redator) | Casa do gerente › Meus relatórios | D, A | G | **continuar oculta** | Rótulos com "custo" e com plano (regras 3 e 4); faróis e plano são da Diretoria (regra 5). Acrescentar linhas cinza na casa do gerente também aumentaria a altura da tela. |
| 11 | Faróis de registro (botão e telas) | Painel › Faróis | D, A | G, P | **continuar oculta** | Regra 4 do plano de safra: o gerente não vê farol nenhum. |
| 12 | Tudo em Cadastros (Fazendas, Talhões, Ciclos, Lotes, Plano do mês, Códigos de acesso, Catálogos, Integrações e robôs, Importações, Sincronização, Unidades e versões do plano, gerar código, novo código combinado, relatorios.html) | Cadastros / Escritório | A | G, P, D | **continuar oculta** | Ação administrativa; códigos de acesso nunca aparecem fora de ADMIN (ESTADO.md). |
| 13 | Preencher boletim / pós-colheita | Entrada, casa | G, P | D | **continuar oculta** | D é só leitura por desenho; mostrar 3 a 4 botões cinza na entrada da Diretoria passaria da metade (limite de densidade). |
| 14 | 📋 Planejamento (área da reunião mensal e da semana) — **v77** | Entrada, painel | D, A | G, P | **continuar oculta** | A área lista tarefas de TODAS as unidades e as pendências com fornecedores — fora do domínio do gerente (condição 3) e com nome de outra fazenda no rótulo das listas (condição 2). O gerente já vê as tarefas DELE na faixa do topo do boletim e da casa, e responde num toque; não há nada para ele pedir a partir de um botão cinza. Densidade: a entrada da Diretoria já tem 3 botões, e cinza aqui não ajudaria ninguém. |

Fora do escopo desta tarefa (não é regra de perfil): "Corrigir" some para
o próprio gerente depois de 48 h e a tela já explica ("Prazo de correção
(48 h) encerrado — fale com o escritório"). Fica como está.

**Onde o estado desabilitado NÃO entra, por regra:** tela de apontamento
em 3 passos (nenhuma ação dela depende de perfil hoje; continua
intocada), qualquer ação de outra atividade, qualquer ação
administrativa para gerente.

## Redação da explicação (toque no botão desabilitado)

Uma linha discreta, cinza, sem modal, some sozinha: "Ação do escritório
(administrador)", "Ação do gerente (até 48 h após o envio)", "Ação da
diretoria". Proibido: "sem permissão", "acesso negado", "não
autorizado", "bloqueado", "sem privilégio".

## Resultado da aprovação e implementação (v71)

Aprovada a tabela inteira pelo Nilo em 08/09/2026: **#7, #8 e #9
aparecem desabilitados**; as outras 10 linhas continuam ocultas.
Nenhum é de outra atividade, nenhum mostra produto, dose, custo ou
outra fazenda; nenhum código de acesso; nenhuma linha passa de 1 botão
cinza em 4.

Como ficou no index.html:
- `ACOES_PERFIL` — catálogo: `boletim_atividade`, `pos_colheita`,
  `painel_diretoria`, `relatorios_diretoria`, `planejamento` (v77),
  `escritorio` (todas
  `visivel: false`, linhas #1 a #5), `cadastros_painel` (#7),
  `corrigir_boletim` (#8, `ctx.prazo` = dentro das 48 h) e
  `marcar_visto` (#9). Cada entrada tem `pode(ctx)`, `visivel(ctx)` e,
  quando visível, `papel` (texto do toque).
- `estadoAcao(id, ctx)` → `permitido` | `bloqueado_visivel` | `oculto`;
  `acaoOk(id, ctx)` para condicionais simples; `botaoAcao(id, ctx,
  {rotulo, aria, classe, attrs})` desenha o botão nos três estados
  (`.acao-off` no desabilitado, sem id/data de ação).
- Listas guiadas por escopo (#6 lista de unidades, #10 relatórios do
  gerente, #11 faróis, #12 Cadastros, #13 preencher) continuam como
  filtros de dado (`unidadesPermitidas`, `podeVer`, roteamento em
  `ir()`): não são botões que se esmaecem; estão na tabela para a
  decisão ficar registrada.
- Toque: tratador único em `app.onclick` (antes dos botões de ação)
  alterna a classe `mostra` (+ `dir` quando o botão está na metade
  direita da tela) por 2,5 s; o CSS desenha `data-papel` acima do botão.
