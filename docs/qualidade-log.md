# Diário de qualidade — Boletim NCNaves

Registro, por entrega, do que foi validado antes do pull request e do
que ficou para teste manual. Uma entrada por tarefa, a mais recente em
cima. Formato: data · versão · entrega · o que foi verificado (como) ·
o que depende de teste manual · o que NÃO foi tocado. Criado na v59;
entregas anteriores estão descritas no ESTADO.md e no histórico do git.

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

**Depende de teste manual (Nilo).**
- Rodar o `sql/042` no SQL Editor e conferir a tabelinha final (linhas por
  atividade e farol). Com o banco de hoje: pecuária toda cinza (nenhum
  boletim de pecuária); em grãos, Capoeira Grande × monitoramento amarelo
  ("sem registro desde o 1º boletim (há 7 dias) · janela aberta, fecha em
  3 dias") e as outras quatro unidades de grãos cinza (sem boletim).
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
