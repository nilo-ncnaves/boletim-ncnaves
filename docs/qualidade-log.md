# Diário de qualidade — Boletim NCNaves

Registro, por entrega, do que foi validado antes do pull request e do
que ficou para teste manual. Uma entrada por tarefa, a mais recente em
cima. Formato: data · versão · entrega · o que foi verificado (como) ·
o que depende de teste manual · o que NÃO foi tocado. Criado na v59;
entregas anteriores estão descritas no ESTADO.md e no histórico do git.

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

**Depende de teste manual (Nilo).**
- Rodar o `sql/040` no SQL Editor e conferir a tabelinha final (3
  linhas: CAFE, GRAOS, PECUARIA). Com o banco de hoje (10 boletins, 1
  de grãos, 0 de pecuária) só Capoeira Grande × "Plantio / semeadura"
  terá `dias_sem_registro` numérico; todo o resto sai `nunca_registrado`.
- Opcional: `sql/041-dias-sem-registro-teste.sql` lista as combinações
  com registro.

**Não tocado.** Nenhuma tela (gerente, pós-colheita, Diretoria,
Cadastros), nenhuma seção de café, nenhuma tabela existente do
Supabase, `syncTudo` (a leitura nova não roda na sincronização).
