# Vistoria semanal do sistema (relatório nº 3 da carteira)

Roteiro que o Claude Code segue toda segunda-feira, a pedido do Nilo,
para conferir se o Boletim NCNaves está de pé e igual ao que o
repositório diz. Sem alterar nada: a vistoria só lê e reporta. O que
precisar de conserto vira tarefa própria (branch + pull request).

## Itens da vistoria

1. **Site × código**: a versão publicada em
   https://boletim-ncnaves.netlify.app (rodapé "Boletim NCNaves · vNN")
   é a mesma do `index.html` no `main` e do cache `boletim-lgs-vNN` no
   `sw.js`; o `manifest.webmanifest` abre. Sintaxe do JavaScript do
   `index.html` extraído passa no `node --check`.
2. **Robôs**: pela REST do Supabase (só leitura, chave publishable),
   última data/atualizado_em em `icrop_manejo` (robô iCrop, madrugada
   + reforço 9h45) e em `solinftec_diario` (robô Solinftec, 03:05 +
   horários). Mais de um dia sem gravação = robô parado (ver ESTADO.md,
   seção Robôs, para o remédio: Restart project no Supabase; ciclos
   vencidos na iCrop são outra coisa e ficam com o agrônomo).
3. **Boletins**: último boletim por unidade nos 7 dias em `boletins`
   (mesma leitura do farol de completude do painel); unidades sem
   nenhum boletim na semana entram no relatório como "sem registro".
4. **Segurança**: nenhum token, senha ou chave secreta no repositório
   (`git grep` por "token", "senha", "secret", "sb_secret",
   "service_role"); só a chave publishable pode aparecer. Tabelas
   `segredos` e `solinftec_segredos` continuam sem policy de leitura
   (a REST deve responder erro/vazio, nunca conteúdo).
5. **Tabelas pendentes**: quais arquivos de `sql/` ainda não foram
   rodados (URL da tabela responde 404) — comparar com as PENDÊNCIAS
   do ESTADO.md e listar.
6. **Documentação viva**: ESTADO.md bate com a versão atual;
   `docs/catalogos-por-atividade.md` não diverge dos catálogos do
   `index.html` (amostra: LISTA_ATIV, OPS_GRAOS_FASES, PEC_*).
7. **Relatórios da semana**: conferir em `docs/relatorios.md` quais
   estavam previstos para a semana (cadência) e perguntar ao Nilo se
   rodaram; listar os não rodados.
8. **Checagem de poluição**: executar `node scripts/checar-poluicao.cjs`
   na raiz, com o `main` atualizado (roda sem rede, a 390 px; precisa
   do Playwright, como a regressão), e listar qualquer ❌. Comparar com
   a seção "Telas × padrões de tela" do ESTADO.md: ❌ que não consta lá
   é regressão — entrou sem passar pela DEFINIÇÃO DE PRONTO do
   CLAUDE.md (PADRÕES DE TELA) — e ❌ que sumiu de lá foi corrigido
   (atualizar o ESTADO.md vira tarefa). Se houver ❌, gerar o prompt de
   correção pronto para o Nilo colar no Claude Code: tela e seção,
   item reprovado com o dado medido (campos visíveis, altura em telas,
   termo achado), o que o padrão exige (letra e número do CLAUDE.md:
   a, P3, c…), a instrução de manter o resto da tela idêntico
   (regressão em scripts/regressao_render.cjs) e de rodar a checagem de
   novo antes do PR, colando o checklist no resumo.

## Saída

Mensagem curta em português, por item: OK / atenção / problema, com o
dado que sustenta (data, versão, tabela). Encerrar com a lista de
relatórios não rodados na semana, a lista de ❌ da checagem de poluição
(com o prompt de correção pronto, se houver) e o que precisa de
decisão do Nilo.
