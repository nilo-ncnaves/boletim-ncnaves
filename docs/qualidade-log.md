# Diário de qualidade — Boletim NCNaves

Registro, por entrega, do que foi validado antes do pull request e do
que ficou para teste manual. Uma entrada por tarefa, a mais recente em
cima. Formato: data · versão · entrega · o que foi verificado (como) ·
o que depende de teste manual · o que NÃO foi tocado. Criado na v59;
entregas anteriores estão descritas no ESTADO.md e no histórico do git.

## 07/09/2026 · v62 · intervalo entre operações (ritmo por unidade × operação)

**Entrega.** `sql/043-intervalo-operacoes.sql` (visões
`vw_intervalo_operacoes` — `LAG()` por unidade × operação, uma linha por
registro com o anterior — e `vw_ritmo_operacoes` — mediana, mínimo,
máximo, contagens, último registro), `sql/044-intervalo-operacoes-teste.sql`
(conferência opcional), funções de leitura `baixarRitmoOperacoes` /
`baixarIntervaloOperacoes` / `ritmoDe` / `textoRitmo` no `index.html`,
texto secundário "ritmo: a cada N dias" em Diretoria › Faróis de registro
› unidade (só grãos e pecuária, só com dois registros ou mais), cenário
com linhas de ritmo em `scripts/checar-poluicao.cjs`, docs (relatorios.md
com a distinção dias_sem_registro × intervalo_dias e o porquê da
mediana; ESTADO.md; CLAUDE.md). Versão v62 (rodapé + cache do sw.js).
Decisão de modelagem registrada: um registro é um DIA com a operação no
boletim (vários talhões no mesmo boletim = mesmo registro), porque contar
cada lançamento faria a mediana de uma unidade com 4 pivôs cair para 0
(testado: 0 por lançamento × 14 por dia).

**Verificado (automático, sem tocar o Supabase).**
- Bloco SQL rodado 2× num PostgreSQL 16 local com `rel_unidades`,
  `rel_fz_atual`, `rel_hoje_brt`, `rel_num` copiados do `sql/020`, uma
  tabela `boletins` igual à do app e o `sql/040` aplicado antes: sem erro,
  idempotente. 12 checagens com 17 boletins de teste (grãos com fungicida
  em 4 pivôs a cada 14 dias, plantio único, pecuária com roçada em −60,
  −50, −40, −3 e contagem 3 dias seguidos, café, id antigo f19 + f03c no
  mesmo dia, boletim "exemplo", payload malformado, "Capina" solta): linhas
  para GRAOS e PECUARIA; primeiro registro de cada combinação com
  anterior NULL e intervalo NULL (0 violações; 0 intervalos zero);
  combinação com 1 registro → qtd_intervalos 0 e três estatísticas NULL
  (0 violações); mediana 10 contra média 19 na roçada; qtd_intervalos =
  qtd_registros − 1, mínimo ≤ mediana ≤ máximo e data_ultimo = max em
  todas; café entra como dado (Colheita a cada 7 dias) e f19 + f03c no
  mesmo dia viram 1 registro com 2 lançamentos; exemplo, malformado e
  "Capina" não contam; colunas exatas, nenhuma com status/alerta/atraso/
  farol/esperado; definição sem LIKE/ILIKE/regex/nome; mesma
  data_ultimo_registro da `vw_dias_sem_registro` em toda combinação e
  nenhuma combinação fora dela; papel anon lê.
- `node --check` no JavaScript extraído do `index.html`, no `sw.js` e no
  `scripts/checar-poluicao.cjs`.
- Prova Playwright (sem rede, main × branch, mesmas linhas injetadas nos
  caches, inclusive ritmo de CAFÉ de propósito): tela Faróis › unidade de
  café e lista de Faróis byte a byte iguais à main, sem "ritmo"/"a cada";
  grãos mostra "ritmo: a cada 7 dias" (mediana 6,5 arredondada) na
  operação com janela e "a cada 14 dias" na sem janela, e nada — nem
  traço — na operação com 1 registro; pecuária idem; nenhum termo
  proibido; nenhum texto comparando unidades. A primeira rodada pegou a
  frase nova do rodapé vazando para a unidade de café; foi restrita a
  grãos/pecuária e a prova passou.
- `scripts/checar-poluicao.cjs`: 221 ✅ · 41 ❌, igual ao retrato da v61
  (nenhum ❌ novo); Faróis › unidade com as linhas de ritmo: 1 tela, ✅.
- `scripts/regressao_render.cjs` main (v61) × branch: telas do gerente
  (café, grãos, pecuária), pós-colheita, Diretoria e Cadastros idênticas
  fora o rodapé de versão e horários (offline as telas de faróis mostram
  o estado de erro nas duas versões).
- `git grep` por "não fez", "não realizou", "pendente", "atrasad",
  "ranking", "melhor que" nos trechos novos: nada.

**Teste manual (Nilo).** Rodar `sql/043` no SQL Editor (a tabelinha final
mostra, por atividade, quantas combinações têm registro e quantas já têm
ritmo). Opcional: `sql/044`. Com código DIRETORIA/ADMIN, sincronizar e
abrir painel › Faróis de registro › uma unidade de grãos ou pecuária: com
o banco de 07/09/2026 quase nenhuma combinação tem dois registros, então
a linha de ritmo deve ser rara ou ausente — é o esperado, não erro.

**Não tocado.** Telas do gerente (as três atividades) e da pós-colheita,
casa do gerente, painel da Diretoria, tela 📊 Relatórios, lista de Faróis,
tela de unidade de café nos Faróis, `vw_dias_sem_registro` /
`vw_farol_registro` e demais objetos do sql/040 e 042, tabelas existentes,
catálogos. Nenhum campo novo de digitação; nenhuma linguagem de produto ou
dose; nenhum ranking, custo ou push.

## 07/09/2026 · v61 · estados vazios informativos (carregando · erro · vazio com recorte)

**Entrega.** Função única `fraseVazio` / `htmlEstado` (+ `periodoVazio`,
`haDias`) no `index.html`; 29 pontos passaram por ela (27 vazios +
carregando + erro): casa do gerente de grãos/pecuária, seção Talhões e
ciclos, Irrigação por pivô, painel da Diretoria (lista de boletins com
todos os filtros e "último registro" da unidade, cartão da unidade,
Resumo do período), tela Relatórios com os três estados e "Tentar de
novo", tela do relatório, tabelas dos relatórios, escolha de fazenda e
15 listas e buscas de Cadastros — 5 pontos antes ficavam em branco
absoluto (Lotes, Plano › fazenda com busca, Catálogo com busca,
Importações manuais, escolha de fazenda); legenda do farol do
painel "○ faltou" → "○ sem registro"; `relEstado` separa "baixando" e
"não conseguiu baixar" de "o motor não gerou nada". Ao trazer a main
(v60, Faróis de registro), as duas telas novas de faróis entraram na
mesma regra: `farolEstado` (carregando / erro com Tentar de novo) e
vazios "Sem farol baixado para as unidades deste código…", "Sem
operação com janela nas unidades deste código." e "Sem operação com
janela em Água Santa." (era "Nenhum farol baixado ainda…" / "Nenhuma
operação com janela nesta unidade."). Docs:
`docs/definicao-de-pronto.md` (novo, item 6 = regra permanente),
CLAUDE.md (item c2), ESTADO.md. Versão v61 (rodapé + cache do sw.js).

**Verificado (automático, sem rede).**
- `node --check` no JavaScript extraído do `index.html` e no `sw.js`.
- Frases geradas fora do navegador (21 combinações de recorte): nenhuma
  com "não fez", "não realizou", "pendente", "atrasado", "faltou",
  "esqueceu", "você ainda" ou "!"; a mais longa com todos os filtros do
  painel ao mesmo tempo tem 120 caracteres (3 linhas — caso extremo com
  5 filtros), as demais ≤ 92 (2 linhas a 390 px).
- `scripts/regressao_render.cjs` main (v60) × branch: 55 telas; café
  (f23) e pós-colheita idênticos fora o relógio de "Enviado às"; as
  únicas diferenças reais são as pedidas — casa do gerente de grãos
  (f33) e de pecuária (f26) com o vazio novo, a legenda do farol no
  painel e as duas telas de faróis (sem rede a lista mostra o estado de
  erro com Tentar de novo, que é o correto: o pedido falhou, não
  "não há dados").
- `scripts/checar-poluicao.cjs`: 221 ✅ · 41 ❌, igual ao retrato da v60
  (nenhum ❌ novo; nenhum termo de outra atividade nas frases novas).
- `git grep` pelos termos proibidos nos trechos alterados: nada.

**Teste manual (Nilo).** Com rede e código DIRETORIA: abrir 📊
Relatórios num aparelho sem cache em modo avião (deve mostrar "Não foi
possível carregar os relatórios" + Tentar de novo), ligar a rede e tocar
em Tentar de novo (passa por "Carregando relatórios…" e chega aos
relatórios); no painel, filtrar por uma unidade sem boletim na semana e
conferir a frase com "Último registro há N dias". Com código de grãos ou
pecuária num aparelho novo: conferir o vazio da casa do gerente.

**Não tocado.** Telas do gerente de café e de pós-colheita (textos
"Nenhum boletim ainda." / "Nenhum registro ainda." preservados por
`atividadeDe(fz)`), cartão de cargas de café, Unidades e Plano (já tinha
os três estados: é o padrão de referência), avisos dos robôs, cartões
que somem sem dado (Solinftec, iCrop, Meus relatórios — decisão da v55),
listas de lançamento do boletim (vazio silencioso por desenho do padrão
a: só o "＋"), Supabase, `syncTudo`. Deixado para decisão do Nilo: o
título "Boletim de hoje pendente" / "Registro de hoje pendente" das
casas do gerente e do pós-colheita (rótulo de situação, não vazio; mexer
toca o café) e "pendente" no relatório de rebanho (GMD e lotação, texto
vindo do motor). O enriquecimento com a visão `vw_dias_sem_registro`
(por operação) fica para o item do backlog "janela por operação e
farol": hoje não há vazio por operação em tela, e o "último registro"
do painel usa os boletins já baixados no aparelho.

## 07/09/2026 · v60 · janela e farol de registro na Diretoria

**Entrega.** `sql/042-janela-farol.sql` (tabela `operacao_janela` com
janelas propostas para grãos e pecuária, visões `vw_dsr_boletim_unidade`
e `vw_farol_registro`), telas **Faróis de registro** e **unidade** na
Diretoria (botão no painel), `baixarFarolRegistro` em `syncTudo` só para
códigos com painel, cenários novos em `scripts/checar-poluicao.cjs` e
`scripts/regressao_render.cjs`, docs.

**Verificado (automático, sem tocar o Supabase).**
- SQL 040 + 042 rodados 2× no PostgreSQL local (idempotentes) com
  boletins de teste: verde (registrado hoje), amarelo (35 dias numa
  janela 30+10, fecha em 5), vermelho (130 dias numa janela 90+30,
  fechada há 10), nunca registrado desde o 1º boletim (amarelo com
  histórico de 130 dias; vermelho com 300), cinza (unidade sem boletim),
  janela desligada por unidade (sem farol), operação sem janela (sem
  farol), café sem farol, "vermelho só com janela fechada" e "verde só
  com registro dentro da cadência" sem violações, nenhum texto proibido,
  definição sem LIKE, anon lê, 582 linhas — 17 checagens ✅.
- `node --check` no JavaScript do `index.html`, `sw.js` e nos dois scripts.
- `scripts/checar-poluicao.cjs` (telas novas medidas com os padrões de
  Cadastros, com linhas de exemplo no formato da visão) e
  `scripts/regressao_render.cjs` main × branch: resultado no PR e no
  ESTADO.md ("Telas × padrões de tela").

**Teste manual (Nilo) — `sql/042` FEITO em 07/09/2026.** Conferência pela
REST pública logo depois: 10 janelas propostas ativas; 582 combinações
(café 190 sem janela; grãos 135 sem janela + 1 amarelo + 4 cinza;
pecuária 171 sem janela + 81 cinza); Capoeira Grande × monitoramento
amarelo "sem registro desde o 1º boletim (há 7 dias) · janela aberta,
fecha em 3 dias"; 0 vermelhos com janela aberta; 0 verdes sem registro;
café sem farol; nenhum texto proibido. Ainda manual:
- Sincronizar o app com código DIRETORIA ou ADMIN e abrir o painel ›
  "Faróis de registro".
- Ajustar as janelas propostas com o agrônomo e o veterinário (SQL no
  cabeçalho do 042).

**Não tocado.** Telas do gerente e da pós-colheita (idênticas ao main na
regressão), seções de café, tabelas existentes. O painel da Diretoria
ganhou um botão; a tela 📊 Relatórios não mudou.

## 07/09/2026 · v59 · métrica "dias sem registro" (visão no Supabase + leitura no app)

**Entrega.** `sql/040-dias-sem-registro.sql` (catálogo mestre
`operacao_catalogo`, apelidos `operacao_alias`, visões
`vw_dsr_registros` e `vw_dias_sem_registro`), gerador do seed
`scripts/gerar_catalogo_operacoes.cjs`, funções de leitura
`baixarDiasSemRegistro` / `diasSemRegistroDe` / `textoDiasSemRegistro`
no `index.html` (sem tela), docs.

**Verificado (automático, sem tocar o Supabase).**
- Bloco SQL rodado 2× num PostgreSQL local (pgserver) com as tabelas de
  apoio copiadas do `sql/020` (`rel_unidades`, `rel_fz_atual`,
  `rel_hoje_brt`, `rel_num`) e uma tabela `boletins` igual à do app:
  sem erro, idempotente (INSERT 0 0 na 2ª rodada dos apelidos).
- 26 checagens com boletins de teste (grãos, pecuária, café, id antigo
  f19, boletim "exemplo", payload malformado): linhas para GRAOS e
  PECUARIA; nunca_registrado ⇒ dias NULL (0 violações); registro de
  hoje ⇒ 0; registro de 12 dias ⇒ 12; "Capina" digitado não casa com
  "Capina manual"; cada bloco da pecuária (mov, massa, san, lotes, nut,
  rep, eventos) chega à operação certa; "Mudança de pasto" conta para
  entrada e saída de lote; exemplo não conta; f19 → f03c; unidade de
  grãos não recebe operação de café; colunas exatas (sem status/farol);
  definição das visões sem LIKE/ILIKE/regex; papel anon lê a visão;
  75 operações ativas; índice (fazenda_id, data) presente.
- `node --check` no JavaScript extraído do `index.html`, no `sw.js` e
  no gerador.
- `scripts/checar-poluicao.cjs`: 209 ✅ · 41 ❌, igual ao retrato da v58
  (nenhum ❌ novo). `scripts/regressao_render.cjs` main × branch: 53
  telas, 0 diferentes além do rodapé de versão e de horários.
- Vocabulário: `git grep` por "não fez", "atrasad", "pendente" nos
  arquivos novos — nada.

**Teste manual (Nilo) — FEITO em 07/09/2026.** `sql/040` rodado no SQL
Editor; conferência pela REST pública logo depois: 75 operações, 90
apelidos, 582 combinações (café 190, grãos 140, pecuária 252), 0
violações da regra NULL ≠ 0, Capoeira Grande × "Plantio / semeadura"
= 7 dias (último boletim 31/08), pecuária toda "sem registro".
Opcional: `sql/041-dias-sem-registro-teste.sql` lista as combinações
com registro.

**Não tocado.** Nenhuma tela (gerente, pós-colheita, Diretoria,
Cadastros), nenhuma seção de café, nenhuma tabela existente do
Supabase, `syncTudo` (a leitura nova não roda na sincronização).
