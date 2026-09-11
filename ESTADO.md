# ESTADO.md — o que o app tem hoje

Fotografia atual do Boletim NCNaves. TODA tarefa que mudar
comportamento, catálogo, chave ou versão DEVE atualizar este arquivo
no mesmo pull request (regra no CLAUDE.md).

**Versão atual: v85** (rodapé da tela inicial + cache do sw.js).

## Unidades operacionais (fazenda física + atividade)
- ☕ Café: Água Limpa (f01), Rio Preto-Lagamar — Café (f03c),
  Mata Preta — Café (f13c), Monte Carmelo — Café (f14c),
  São Félix — Arrendamento (f21), Vereda — Café (f22c),
  Vereda Romaria (f23), Vereda Café 5º e 6º (f24),
  Lagamar Café Rodrigo (f20), NC Naves — Armazém Geral (f25).
- 🌾 Grãos: Rio Preto-Lagamar — Grãos (f03g), Vereda — Grãos (f22g),
  Capoeira Grande (f27), Floramill (f33), Porto Buriti (f35).
- 🐂 Pecuária: Mata Preta — Pecuária (f13p), Monte Carmelo —
  Pecuária (f14p), Água Santa (f26), Chapada (f28), Chapadão (f29),
  Confins (f30), Cra Cra (f31), Ferragem (f32), Gameleira (f34).

Unidades desmembradas compartilham a fazenda-mãe (fazendaMae) no
painel; talhões tipo ESTRUTURA aparecem em todas as unidades irmãs.

## Perfis de uso e controle de acesso (v43, escopos v46)
- O app só abre com um **código de acesso** (formato prefixo-NNNN),
  digitado uma vez e gravado no aparelho. Código errado é barrado,
  sem dica. "Sair" discreto no rodapé da tela de atividades esquece
  o código do aparelho.
- Cada código aponta para uma **chave de escopo** (escopoDaChave no
  index.html): lista de atividades e/ou lista de unidades +
  permissões (painel, cadastros). Tipos:
  - **Por unidade** (XX-NNNN, chave = id da fazenda): abre só ela e
    vai direto ao boletim.
  - **Por atividade** (CAFE-NNNN, GRAOS-NNNN, PECU-NNNN; chaves
    ATV:CAFE etc.): todas as unidades da atividade. Unidade criada
    no futuro entra sozinha no escopo (calculado na hora pelo perfil
    da fazenda).
  - **Combinados de atividades** (CAFEGRAOS-NNNN, CAFEPECU-NNNN,
    GRAOSPECU-NNNN; chaves ATV:CAFE+GRAOS etc.).
  - **Combinados livres** (MIX:<atividades>:<unidades>): o admin cria
    em Cadastros escolhendo atividades inteiras e/ou unidades
    avulsas; o código nasce com prefixo MIX (ou o das atividades).
  - **DIRETORIA-NNNN**: painel + leitura de todas as unidades, sem
    Cadastros; não preenche boletim.
  - **ADMIN-NNNN**: tudo, inclusive Cadastros e a gestão de códigos.
- Navegação dentro do escopo: a tela de atividades mostra só as
  atividades permitidas; com uma atividade só, pula direto para a
  lista de unidades; com uma unidade só, abre direto o boletim.
  "Trocar fazenda/atividade" também respeita o escopo. A
  sincronização baixa/envia só o que o escopo permite lançar
  (pós-colheita aparece se houver unidade de café no escopo).
- Fonte dos códigos: constante CODIGOS_PADRAO no index.html + tabela
  codigos_acesso no Supabase (baixada a cada sincronização e na tela
  de código; chaves MIX criadas pelo admin também chegam por ela).
  Em Cadastros (só ADMIN) fica a lista completa código → escopo, com
  "gerar novo" por linha (invalida o anterior; os aparelhos com o
  código antigo caem para a tela de código na próxima sincronização)
  e o botão "novo código combinado". Códigos nunca aparecem em telas
  que não sejam de ADMIN.
- Perfis: Gerente preenche o boletim da unidade; Diretoria acompanha o
  painel; Escritório/Admin cadastra, importa e tira relatórios;
  Pós-colheita tem boletim próprio de terreiro/secador/tulha (café).
- **Ação de outro papel (v71):** toda ação sujeita a perfil passa por
  `estadoAcao(id)` / catálogo `ACOES_PERFIL` (permitido ·
  bloqueado_visivel · oculto). Três ações aparecem esmaecidas em vez de
  sumir (ver "Ações por perfil (v71)" abaixo); as demais continuam
  ocultas. Isto é interface: a autorização real é do escopo do código e
  das políticas do Supabase, que não mudaram.
- **Decisão e confirmação (v72):** nenhum `confirm()`/`alert()` nativo;
  toda pergunta passa pelo diálogo único `perguntar` (dois botões, verbo
  no afirmativo, destaque só em ação reversível), o botão de avanço
  nasce inativo enquanto falta o que a pessoa enxerga (`botaoAvanco`,
  mesmo visual do botão de perfil) e o que ela não enxerga é explicado
  depois do toque (`avisoInline`). Ver "Decisão e confirmação (v72)".
- Aparelhos que entraram na v45 com código de unidade continuam
  dentro (migração automática do acesso gravado); os códigos antigos
  de DIRETORIA (LG-9351) e ADMIN (AD-4786) foram substituídos pelo
  formato novo — esses aparelhos pedem o código novo uma vez.

## Seções do boletim por atividade
Desde a v69 cada seção tem uma classificação **eventual × esperada**
(docs/catalogos-por-atividade.md, "Seções do boletim: eventual ×
esperada"; catálogo `SECOES_BOLETIM`; confirmada pelo Nilo em
08/09/2026): as eventuais — café: Pragas, doenças e daninhas e
Ocorrências gerais; grãos: Pragas, doenças e ocorrências (uma resposta
por cartão); pecuária: Movimentação do rebanho, Sanidade e Ocorrências
e sanidade — oferecem o par de chips "Nada a registrar hoje" ·
"Registrar…" quando não há registro (seção própria abaixo).
- ☕ Café: clima, mão de obra por função, talhões/atividades,
  irrigação (gotejo), colheita, pós-colheita, fito, ocorrências.
  Desde a v76 a seção **Atividades por talhão** é cascata de 3 passos —
  talhão → atividade num seletor agrupado por natureza, com os 4 grupos
  recolhidos → detalhes — e usa a nomenclatura da lavoura (seção
  "Nomenclatura do café na palavra da lavoura").
- 🌾 Grãos (redesenho v42): clima; mão de obra; **Operações do dia**
  (registro por talhão + operação escolhida em seletor agrupado por
  fase, com campos em cascata específicos de cada operação — fonte:
  docs/catalogos-por-atividade.md); **💧 Irrigação por pivô** (v44,
  ajustada na v45: sem digitação de nome — o seletor "Talhão / pivô"
  aparece só na hora de escolher; pivô escolhido vira LINHA COMPACTA
  "Nome — área · situação"; a lista une talhões-pivô do cadastro
  oficial + equipamentos da iCrop sem "café" no nome + cadastro local
  da unidade, unificados pelo NÚMERO do pivô — o "01" da iCrop e o
  talhão "Pivô 01" são o mesmo pivô (chavePivo); rascunhos que
  ficaram com pivô em dobro na v44 são consertados sozinhos ao abrir
  (migrarIrg); pivô já lançado some da lista; botão "adicionar todos
  os pivôs" cria uma linha por pivô com situação em branco; fazenda
  sem pivô na lista, caso Porto Buriti, ganha o campo "Cadastrar
  pivô desta fazenda" no próprio app — com lista, vira o link
  "cadastrar outro pivô"; seguem status/lâmina/percentímetro/
  quimigação/problemas por pivô e a comparação informado × medido);
  pragas/doenças e ocorrências. Ciclo de cultura abre pelo
  plantio lançado e encerra quando a colheita atinge a área do
  talhão. Talhões ARRENDADO (milho semente → sementeira) aparecem só
  como etiqueta, sem operações/irrigação/colheita.
- 🐂 Pecuária (módulo de campo redesenhado na v50 — fonte:
  docs/catalogos-por-atividade.md, seção PECUÁRIA): uma seção 🐂 com
  sub-acordeões fechados por padrão, tudo opcional:
  **📋 Movimentação do rebanho** (nascimento com parto/sexo, morte com
  causa em chips e brinco, desmama, mudança de pasto, entrada por
  compra/transferência, saída por venda/abate/transferência — cada
  movimento com categoria animal padronizada, qtd e origem → destino;
  contador do dia por tipo para conferência); **💉 Sanidade** (animal/
  lote com problema em chips — bicheira, pneumonia, diarreia, casco,
  olho, carrapato/mosca —, ação, produto; vacinação/vermifugação em
  massa); **🐄 Reprodução** (touros no pasto, coberturas vistas, etapa
  de IATF + qtd, DG prenhes/vazias, ocorrência com touro);
  **🧂 Cocho e nutrição** (por pasto: sal/proteinado/ração em sacos ou
  kg, leitura de cocho vazio/lambido/com sobra, água; + resumo rápido
  OK/Problema da v41); **🐮 Contagem por lote/pasto** (v41);
  **🌱 Pasto e estrutura** (condição do pasto, cerca/porteira,
  visitas — chuva e equipe seguem nas seções Clima e Mão de obra);
  **🔧 Outros manejos** (catálogo OPS_PECUARIA_FASES da v41: pesagem,
  castração, embarque etc., com campos em cascata) e **📝 Observações
  de pecuária**. Pastos/retiros (v51): todos os selects "Pasto /
  retiro" listam o cadastro **PASTOS_POR_FAZENDA** do index.html —
  nomes reais de pasto por fazenda (já cadastradas: Mata Preta,
  Água Santa e Cracrá). Fazenda ainda sem lista mostra só
  "Selecione…" e "Outro…"; "Outro…" abre campo de texto livre e o
  texto digitado é o valor salvo. Para incluir uma fazenda, basta
  acrescentar a chave dela na constante (o nome casa sem
  acento/espaços e ignora a palavra "fazenda" — "Cracrá" acha a
  unidade "Cra Cra", e unidades desmembradas casam pela
  fazenda-mãe). Boletins antigos gravados com id de talhão
  continuam abrindo e exibindo o nome certo. Categorias animais na
  constante CATEGORIAS_ANIMAIS;
  demais catálogos nas constantes PEC_* do index.html. Confinamento
  ficou fora de propósito (engorda do grupo é a pasto). Tudo que for
  preenchido sai no bloco 🐂 PECUÁRIA do resumo WhatsApp e no cartão
  do painel; boletins antigos continuam abrindo (migração leve
  pecMigrar).

## Robôs e integrações
- Supabase (sync): boletins, pos_colheitas, remessas, telemetria —
  gravação/leitura pelo app com a chave publishable. Desde a v50,
  boletim com pecuária preenchida também sobe um espelho para a
  tabela **boletim_pecuaria** (item t:"pec" da mesma fila offline;
  id = id do boletim), pensado para o estoque de rebanho e o custeio
  no ERP AgroGestão — a visão pecuaria_movimentos entrega um
  movimento por linha. O app não lê essa tabela (o boletim completo
  continua em boletins).
- Robô iCrop (pg_cron + pg_net no Supabase): corrente de 3 funções —
  icrop_passo1_parcelas (03h50), icrop_passo2_manejo (04h05) e
  icrop_passo3_gravar (04h20, Brasília) — mais a rodada de reforço
  9h45/10h00/10h15 (sql/003-robo-icrop-reforco.sql, 01/09/2026). Os
  passos NUNCA podem rodar no mesmo minuto: cada um espera a resposta
  da iCrop ao anterior (pg_net é assíncrono). O robô não pede data —
  grava o que a iCrop tiver — e o app LÊ (icropDo): medição do dia,
  lâmina informada × medida e alerta de parcela vencida
  (icrop_fazendas e icrop_parcelas). O vigia do painel (v53) usa o
  atualizado_em de icrop_manejo para separar "iCrop sem medição nova"
  (robô e token OK — atraso da iCrop ou ciclo vencido na Vision) de
  "Robô iCrop parado" (nada gravado há mais de um dia — aí sim
  token/Vision). Histórico 04/09/2026: token rotacionado pelo Nilo
  (ok) e os motores pg_cron/pg_net do projeto travaram e foram
  revividos com Restart project no painel do Supabase — se os robôs
  pararem TODOS de uma vez (Solinftec junto), o remédio é esse.
- Cartão iCrop enriquecido (v47) com os campos que o robô já grava na
  coluna bruto (baixarIcrop lê via bruto->>: percentímetro
  recomendado, tempo de irrigação, umidade/capacidade de campo/
  umidade de segurança, déficit previsto, lâmina mínima, fase, graus-
  dia, problemas de irrigação, clima da estação, chuva do
  pluviômetro, eficiência, acumulados do ciclo, R$ necessário/
  realizado e dias em atraso). Nada disso exige digitação — tom
  "só confira":
  - Gerente (café e grãos): o cartão "iCrop — medição automática do
    dia" tem 3 linhas fechadas por padrão, abrindo ao toque —
    **Hoje** (lâmina medida por pivô/parcela, chuva da estação,
    problemas sinalizados), **Recomendação iCrop** (percentímetro %,
    tempo h, déficit previsto amanhã, lâmina mínima) e **Solo e
    planta** (umidade % vs limite de segurança em âmbar se abaixo,
    fase, graus-dia acumulados, dias em atraso em âmbar se > 0).
  - Seção Clima: além da chuva já sugerida, mostra a estação iCrop
    do dia (T mín/máx, UR, vento) como sugestão.
  - Painel da diretoria (medição de ontem, por unidade irrigada):
    R$ necessário × R$ realizado com a diferença (a estimativa
    antiga lâmina × área × R$/mm só aparece quando a iCrop não
    manda os R$), eficiência %, acumulados do ciclo (mm irrigados e
    mm chuva) e alerta âmbar por pivô com dias em atraso ≥ 3 ou
    umidade abaixo da segurança.
- Robô Solinftec (v48/v49 — pg_cron + extensão http no Supabase,
  sql/003-solinftec.sql): busca na API "Detalhes da Operação V3"
  (https://scdi.saas-solinftec.com — token de 1 min gerado a cada
  chamada, /pull paginado, identifier 23) e grava o resumo diário por
  fazenda/equipamento/operação/talhão em solinftec_diario (horas,
  motor ligado/ocioso, área, litros). ATENÇÃO: a API real manda os
  campos em minúsculas e alguns com nome diferente do manual em PDF
  (vltempo, dtbase, fgtpoperacao…) — o robô aceita as duas grafias.
  Agenda: 03:05 (Brasília) o dia anterior fechado + de hora em hora
  (09:35–20:35) o parcial do dia. Usuário/senha vivem SÓ na tabela
  solinftec_segredos do Supabase (trancada — RLS sem policies; a
  tabela segredos da iCrop tem outra estrutura e ficou intocada).
  O app LÊ (baixarSolinftec) e mostra o cartão do gerente ("medição
  automática do dia") e o do painel ("medição de ontem") em QUALQUER
  fazenda com máquinas medidas (v49 — a frota atende café, grãos e
  pecuária; ex.: trator na Faz. Monte Carmelo). Unidades irmãs da
  mesma fazenda física veem o mesmo cartão (comparação por
  fazenda-mãe em solinftecDo). De-para de fazenda (solinftec_depara:
  pedaço do nome Solinftec → id de unidade; o padrão mais comprido
  ganha) e de operação (solinftec_operacoes: código → nome; vazio
  mostra "Operação NNN") ajustáveis no SQL Editor. A importação
  manual por arquivo continua como plano B.

- Estado das integrações (v63 — `sql/045-status-integracoes.sql`):
  a visão **vw_status_integracoes** devolve uma linha por fonte (icrop,
  solinftec) com quatro horários que NÃO se misturam — ultima_execucao_em
  (última tentativa: diário do pg_cron, jobs listados por nome exato em
  `integracao_job`), ultima_execucao_ok_em (último sucesso: iCrop = HTTP
  200 colhido de net._http_response para o diário persistente
  `integracao_execucoes` pela função `integracao_colher_icrop`, agendada
  07:35 e 13:30 UTC; Solinftec = função sem erro no pg_cron), ultimo_dado_em
  (max de atualizado_em) e ultimo_dado_origem (max da coluna data) — mais
  horas_desde_ultimo_sucesso. Tudo em UTC; NULL é "ainda não existe",
  nunca estimativa. O app lê na sincronização (`baixarStatusIntegracoes`,
  cache bdf:statusIntegracoes; aparelho só de café não baixa) e mostra
  UMA linha secundária no rodapé de cada bloco de dado externo
  (`linhaOrigemDado`): "Dados do iCrop de hoje, 04:05" / "de ontem,
  04:20" / "de 05/09, 04:05", convertido para Brasília com
  America/Sao_Paulo explícito; com mais de 26 h sem sucesso do robô vira
  "Última atualização do iCrop há 2 dias" em âmbar, sem ícone ou
  bloqueio. Onde (v64 — o Nilo decidiu em 08/09/2026 incluir o café,
  porque data de medição de irrigação e de máquinas é gestão do
  cafeicultor): cartão iCrop do boletim do gerente (café e grãos),
  cartão Solinftec da casa do gerente (café, grãos e pecuária), cartões
  "iCrop — medição de ontem" e "Solinftec — medição de ontem" do painel
  da Diretoria, bloco "Estado dos robôs" em Escritório › Integrações e
  robôs. Sem linha: pós-colheita e a dica de chuva na seção Clima.
  Detalhe em docs/relatorios.md, "Estado das integrações".

## Plano de safra 2026/27 (v52 — fase A, "Fundação")
Detalhes em docs/PLANO-DE-SAFRA.md. Resumo do que existe hoje:
- **O plano do agrônomo (Salvino) entra no app só como referência e
  comparação, nunca como receituário.** Nada de produto, dose, época
  ou lâmina recomendada; kg do plano nunca aparecem por padrão ao
  gerente. Na v52 **nada mudou na tela do gerente** (café, grãos e
  pecuária idênticos à v51 — prova em scripts/regressao_render.cjs).
- Dados: `docs/plano/2026-27/apendice_dados.md` (fonte única, 7 PPTX
  extraídos em 03/09/2026) → `scripts/expandir_apendice_plano.py` →
  `plano_2627_seed.json` (69 unidades, 71 calagens = 4.648 t, 1.533
  linhas de adubo mês a mês, fito de 10 meses, Gantt NC e NR) →
  `scripts/gerar_seed_plano.py` → `sql/006-plano-safra-seed-2627.sql`.
  Extrator dos PPTX: `docs/plano/importar_plano.py`. Inconsistências
  conhecidas dos decks: `docs/PLANO-2627-AUDITORIA.md`.
- Supabase (`sql/005-plano-safra.sql`): unidade_manejo (cadastro
  mestre; identidade = id/codigo, nomes são apelidos), unidade_alias
  (por sistema: plano, app = id do talhão do index.html, solinftec,
  icrop, agrogestao), unidade_manejo_log, plano_safra (versões:
  rascunho → vigente → superado; uma vigente por fazenda-safra),
  plano_unidade, plano_adubo_mes, plano_calagem, plano_fito_mes,
  plano_fito_excecao, plano_gantt, plano_parametros. O app LÊ; só a
  tela de ADMIN escreve. Nada se apaga (sem policy de delete).
- App: `baixarPlano()` (dentro de syncTudo) guarda em `bdf:plano` o
  plano **vigente** das fazendas de café do escopo que estão em
  `PLANO_FAZENDA_APP` (id do app → nome exato em fazenda_app):
  unidades, apelidos app, adubo do mês e do próximo, calagem, fito,
  Gantt do modelo da empresa, parâmetros. Sem rede fica o cache; sem
  cache o app é a v51. Tabelas ainda não criadas → silêncio.
- Tela **Escritório › Cadastros › Unidades e Plano** (só ADMIN, precisa
  de rede): editar unidades (nome curto, status, área, obs — cada
  campo alterado vira linha de log), adicionar/encerrar apelidos,
  inativar; por fazenda, versões do plano com **Rodar auditoria**
  (resultado em plano_safra.auditoria_json; ✱ trava publicação) e
  **Publicar como vigente** (exige auditoria ✔ + nome do agrônomo).
- As 8 fazendas do plano estão ligadas ao app (`PLANO_FAZENDA_APP`):
  Água Limpa (f01), Rio Preto-Lagamar — Café (f03c), Mata Preta — Café
  (f13c), Monte Carmelo — Café (f14c), Lagamar Café (Rodrigo) (f20),
  Vereda — Café (f22c), Vereda Romaria (f23), Vereda Café 5º e 6º (f24).
  Três nomes do plano diferiam do cadastro só na pontuação ("Vereda
  Café", "Lagamar Café – Rodrigo", "Mata Preta - Café") e foram
  confirmados pelo Nilo em 03/09/2026; o seed grava sempre o nome exato
  do app e renomeia cargas antigas. De-para em
  `docs/plano/2026-27/depara_fazendas.json`.
- Apelidos `app` (ligação unidade do plano → talhão do app): 47 em 43
  unidades — Água Limpa por setor de irrigação + área, Romaria, Vereda,
  Lagamar e Mata Preta por número, Caxico por nome, Rio Preto 1º
  plantio inferido (setores 1–5 e 6+7 = 19 ha; o 2º plantio é o bloco de
  180 ha) e Caxico represa por eliminação — os inferidos estão marcados
  em `docs/plano/2026-27/alias_app.json`. **26 unidades continuam sem
  apelido `app` porque o cadastro de talhões do app não permite**
  (várias unidades para um talhão só: 2º plantio de Rio Preto → Sede
  Abdala, Café 5º/6º, M. Carmelo st01–08 → Café Talhão 1/2, Sr. Ernani
  alto/baixo → Ernane; pivôs 2 e 6 do café cadastrados em Vereda —
  Grãos; Romaria 01 b filha do 01; Mata Preta Plantio 2026 e 3º
  plantio). Ligar essas exige desmembrar talhões no app, o que muda os
  chips do gerente — decisão para uma versão futura.
- `sql/007-publicar-planos-2627.sql` (opcional): publica as 8 versões 1
  como vigentes de uma vez, gravando a auditoria de
  `docs/plano/2026-27/auditoria_v1_resultado.json` (as 8 passaram; Mata
  Preta só porque MTP-3PT recebeu a exceção "sem área: ok" em obs).
  Rodar só quando o agrônomo aprovar; senão, usar a tela.

## Chaves ligadas/desligadas
- SOLINFTEC_AUTO = true (desde a v48). Enquanto sql/003-solinftec.sql não
  rodar no Supabase, o fetch falha em silêncio e nenhum cartão
  Solinftec aparece — o app segue normal.
- Sincronização Supabase: ligada por padrão (SYNC_PADRAO com a chave
  publishable).

## Cadastros (v56 — menu → assunto → item)
A tela única e longa de Cadastros virou navegação em níveis, no padrão
de aplicativos de gestão: **menu** (12 assuntos desde a v77, cartões grandes com
número-resumo e busca global no topo) → **lista** do assunto (busca
quando há mais de 12 itens, agrupada por fazenda/unidade; listas longas
abrem com os grupos fechados e chips de salto por grupo) → **detalhe**
do item (cabeçalho fixo com "‹ Voltar" para o nível anterior, botão
principal fixo no rodapé, "Mais opções" e "Zona de cuidado" fechados,
confirmações inline, "Salvo" discreto e retorno à lista na posição do
item). Só o código ADMIN vê. Telas de gerente, pós-colheita e Diretoria
idênticas à v55 (scripts/regressao_render.cjs). Onde cada função antiga
passou a morar:
1. **🏡 Fazendas e unidades** — perfil/atividade da fazenda (era
   "Perfil das fazendas"), estrutura de pós-colheita (era "Estrutura de
   pós-colheita"), nome, entidade/CNPJ, município, ativa/inativa,
   fazenda física e irmãs; Zona de cuidado: desmembrar (cria unidade
   irmã) e unificar (talhões vão para a irmã, esta fica inativa).
2. **🗺️ Talhões, pivôs e pastos** — cadastro de talhões (era "Talhões":
   unidade, tipo de uso, remover, adicionar — agora formulário em vez
   de prompts em cadeia; prefixo de área + nome, área) e os pivôs
   cadastrados no app pela unidade (D.pivosLocais, antes só na seção
   Irrigação do gerente).
3. **🌾 Ciclos e plantios** — "Novo plantio" / "Encerrar colheita" (eram
   botões da lista de talhões) com cultura em chips e data, histórico
   do talhão em "Mais opções". O gerente continua com o botão dele no
   boletim, inalterado.
4. **🐂 Lotes e inventário** — NOVO: inventário por categoria animal
   por unidade (D.inventarioPec), última contagem por lote vinda do
   boletim, histórico; Zona de cuidado: inventário inicial e ajuste
   com motivo. Não muda nada no boletim do gerente.
5. **📅 Plano do mês** — leitura do plano vigente baixado (bdf:plano):
   por fazenda, mês atual/próximo, adubo (kg rotulados "plano vN"),
   calagem, fito e ligação com o talhão do app; entrada "Unidades e
   versões do plano" abre a tela Unidades e Plano (era o botão "Abrir
   Unidades e Plano"), que agora volta para cá.
6. **🔐 Códigos de acesso** — lista com escopo e código (era "Códigos
   de acesso"), detalhe com "gerar novo" em Zona de cuidado (confirmação
   e código novo inline, sem alert) e "＋ Novo código combinado" (era
   "novo código combinado").
7. **📚 Catálogos** — por atividade (Café, Grãos, Pecuária), cada lista
   fechada com contagem; termos padrão vêm do código (só leitura) e o
   escritório pode **acrescentar termos** (D.catalogoExtra) em funções,
   operações e pragas/doenças/daninhas — entram nas listas do gerente
   daquela atividade (funcoesDa, opcoesAtiv/fasesDa, sugestaoFitoDa);
   sem termos extras nada muda. Máquinas e equipamentos (era o cartão
   com busca e vínculo por fazenda) e Insumos (era "Insumos") moram
   aqui, com formulário inline em vez de prompts.
7b. **📋 De-para da ata (v77)** — como cada nome que a ata da reunião usa
   ("FMC Igrejinha", "Lagamar (Grupo)") é lido pelo app: unidade do
   cadastro, "sem ligação" ou "fora do escopo (ignorar sempre)". Um
   seletor por linha, que grava na hora; "＋ nome da ata" acrescenta um
   nome novo. Padrão em `DEPARA_ATA_PADRAO`; o que a pessoa muda vive em
   `D.deparaAta` e vence o padrão.
8. **🔌 Integrações e robôs** — Supabase, robô iCrop (última medição ×
   última gravação, de-para, parcelas vencendo), robô Solinftec
   (SOLINFTEC_AUTO, última data, linhas sem de-para, operações sem
   nome), plano de safra; "Baixar agora" = syncTudo. Desde a v63, logo
   abaixo do Supabase, o bloco de leitura **Estado dos robôs
   (vw_status_integracoes)**: por fonte, última tentativa · último
   sucesso · último dado gravado (e o dia do dado na origem) · horas
   desde o último sucesso, em Brasília; sem cache, frase de vazio.
9. **📡 Importações manuais** — importador de planilha Solinftec/iCrop
   (era "Telemetria — Importar arquivo do dia") e a lista das
   importações feitas; a tela de importar volta para cá.
10. **🔄 Sincronização e dados** — status e fila (era "Sincronização
    entre celulares"), URL/chave em "Mais opções", "Sincronizar agora",
    exportar CSV (era o botão do painel, que continua lá) e backup JSON
    (novo); Zona de cuidado: limpar dados de teste (registros exemplo).
11. **ℹ️ Sobre** — versão, LEIA-ME, carteira de relatórios (era o cartão
    "Relatórios da Controladoria" da v54), ESTADO.md, contato.
Constante APP_VERSAO alimenta os rodapés e o Sobre. Migração de seed
preserva catalogoExtra, inventarioPec, unidades criadas por desmembrar
e os campos entidade/inativa.
## Relatórios automáticos — fase 1 (v55): motor no Supabase + vitrine
Princípio: o Supabase calcula em horário agendado (pg_cron) e grava o
resultado pronto; o app só lê e exibe. Nada é calculado no celular além
de formatação. Detalhe por relatório (tabelas e campos reais lidos,
agenda, formato) em `docs/relatorios.md`, seção "Motor de relatórios
automáticos".
- **Motor** (`sql/020-relatorios-motor.sql`): tabela `relatorios_gerados`
  (relatorio, periodo_ini, periodo_fim, unidade_id nulo = grupo, gerado_em,
  dados jsonb, texto reservado) com leitura anon e escrita só pelas funções
  (security definer; sem policy de insert/update); `relatorios_execucoes`
  (diário de bordo); `rel_unidades` (espelho das 24 unidades do app —
  unidade nova no app precisa de insert aqui) e `rel_icrop_depara`.
  Funções: `rel_farol(7|30)`, `rel_dito_medido_icrop`,
  `rel_dito_medido_solinftec`, `rel_irrigacao_recomendado_executado`,
  `rel_balanco_hidrico`, `rel_custo_fisico_talhao`, `rel_rebanho`,
  `rel_plano_executado`, cada uma lendo as tabelas reais (boletins.payload,
  icrop_manejo e bruto, solinftec_diario, plano_*), mais as rodadas
  `rel_rodar_diario/semanal/mensal/plano` (cada relatório protegido por
  exception). Ids antigos de fazenda passam por `rel_fz_atual` (= FZ_LEGADO).
  Agenda pg_cron (UTC): diário 08:00 (05:00 BRT), sexta 08:10, dia 1 08:20,
  segunda 08:30 — fora dos horários dos robôs iCrop e Solinftec.
  `sql/021-relatorios-teste.sql`: chamadas manuais + consultas de conferência.
- **App**: `baixarRelatorios()` em `syncTudo` baixa só as unidades do
  escopo do código (filtro na REST + trava local), guarda em
  `bdf:relatorios`, funciona offline com o último baixado; tabela
  inexistente = silêncio. Diretoria/ADMIN (v58): botão grande
  "📊 Relatórios" no topo do painel e atalho "Relatórios" na tela de
  entrada abrem a tela própria `vRelatorios` — em cima "📝 Textos para
  revisar" (devolutivas e painel executivo do último período, texto
  visível, botão copiar para WhatsApp), embaixo "📊 Números" com filtro
  dia/semana/mês, último período gerado e "N para conferir" em âmbar
  (a seção fechada dentro do painel, da v55, deixou de existir; o botão
  antigo "📊 Relatório" do painel virou "📈 Resumo do período"); toque
  abre a tela do relatório (tabelas compactas `.rel-tab`,
  fonte tabular, âmbar = para conferir, vermelho só janela fechada) com
  navegação anterior/próximo, "📲 Compartilhar" (texto limpo para
  WhatsApp) e "🖨 PDF" (impressão). Gerente: cartão "📊 Meus relatórios"
  com farol 7 dias e dito × medido (iCrop e Solinftec) SOMENTE da unidade
  dele; a tela filtra de novo por `sessao.fazendaId` e nunca abre
  relatórios da Diretoria. Sem relatório baixado o cartão não aparece
  (telas do gerente idênticas à v54 — prova em scripts/regressao_render.cjs).
- Vocabulário obrigatório: "sem registro" (nunca "não fez"); diferença
  entre dito e medido é "para conferir" (nunca "erro"); produto do plano só
  como "previsto pelo agrônomo".
- **Fase 2 (v57): robô-redator com a API da Claude dentro do Supabase**
  (`sql/030-redator.sql`). Tabela `relatorios_modelos` (um texto-modelo por
  relatório narrativo, semeada com `docs/redator-modelos.md` — os dois nunca
  divergem; cadência, por_unidade, fontes, max_tokens), `relatorios_reqs`
  (pedidos em andamento: req_id, status enviado/ok/erro/perdido, tokens) e
  colunas texto_em/texto_modelo em relatorios_gerados. Função
  `redigir_relatorio(relatorio, ini, fim, unidade)` monta a linha composta
  (fontes da fase 1 compactadas em `dados.fontes`) e DISPARA via
  `net.http_post` para https://api.anthropic.com/v1/messages (modelo
  claude-sonnet-4-6, max_tokens 1500, system = instruções do modelo);
  `redator_colher()` lê `net._http_response` minutos depois e grava
  `relatorios_gerados.texto`. Padrão assíncrono igual ao robô iCrop.
  Agenda pg_cron (UTC): sexta 08:20/08:35 (devolutiva por unidade), dia 8
  08:20/08:35 (painel executivo do mês anterior); `redator_disparar(cadencia)`
  reaproveita o par para qualquer modelo cadastrado. `alerta_divergencia`
  fica manual (sql/032). A chave da API vive SÓ em `segredos`
  (chave anthropic_key, gravada por `sql/031-redator-cofre.sql`), lida por
  `redator_chave()` (security definer); nenhuma função é chamável pela chave
  publishable; o app nunca chama a API. `rel_gravar` passou a preservar o
  texto quando a fase 1 regrava os números.
- App (v57): relatórios narrativos (`devolutiva_semanal`, `painel_executivo`,
  `alerta_divergencia`) entram na seção 📊 Relatórios da Diretoria; a tela
  mostra o texto ACIMA dos números, com o marcador "gerado automaticamente —
  revisar antes de enviar" e o botão "📲 copiar para WhatsApp" (copia e abre
  o compartilhar); os números (fontes) ficam fechados abaixo. Só aparelhos
  com painel baixam texto: o gerente não recebe rascunho nenhum (a devolutiva
  chega a ele pelo WhatsApp, depois de revisada). Telas do gerente idênticas
  à v56 (regressão em scripts/regressao_render.cjs).

## Dias sem registro (v59) — visão no Supabase, leitura sem tela
Métrica que diz há quantos dias uma operação não é registrada em uma
unidade operacional (o farol nº 1 é binário; esta separa "3 dias" de "47
dias" sem ranking e sem dizer "não fez"). Detalhe em `docs/relatorios.md`,
seção "Visão vw_dias_sem_registro".
- **Supabase** (`sql/040-dias-sem-registro.sql`, bloco único com passo a
  passo; precisa do `sql/020` já rodado): `operacao_catalogo` (catálogo
  mestre de operações — id imutável CAFE-…/GRAOS-…/PEC-…, espelho de
  LISTA_ATIV, OPS_GRAOS_FASES e OPS_PECUARIA_FASES; seed por
  `scripts/gerar_catalogo_operacoes.cjs`; 75 operações), `operacao_alias`
  (texto exato do payload → operação, igualdade exata, nunca LIKE; 90
  apelidos, inclusive os blocos estruturados da pecuária: mov, massa,
  san.problema, lotes, nut, rep), `vw_dsr_registros` e
  `vw_dias_sem_registro` (unidade_id, operacao_id, atividade,
  operacao_nome, fase, data_ultimo_registro, dias_sem_registro,
  nunca_registrado). **Nunca registrado = dias NULL + nunca_registrado
  true**, nunca 0. Sem coluna de status/farol/atraso: a janela é de outra
  camada (backlog). Leitura anon, escrita só pelo SQL Editor; visões com
  security_invoker. As três atividades entram pela mesma regra (até a
  v64 nenhuma tela de café lia; desde a v65 a unidade de café aparece em
  Faróis de registro, ver v60).
- **App**: `baixarDiasSemRegistro({atividade, unidade})` (junto de
  `baixarRelatorios`) lê a visão pela REST só para as unidades do escopo,
  guarda em `dsrCache` / `bdf:diasSemRegistro`; `diasSemRegistroDe` e
  `textoDiasSemRegistro` ("há 12 dias" / "hoje" / "sem registro") ficam
  prontos para telas futuras. Não roda em `syncTudo`; nenhuma tela mostra
  o número na v59 (as telas candidatas — painel e 📊 Relatórios — são
  compartilhadas com o café; Cadastros › Lotes é outro assunto, P1).
  Telas idênticas à v58 (prova em scripts/regressao_render.cjs).
- Diário de validação por entrega: `docs/qualidade-log.md` (novo na v59).

## Janela e farol de registro na Diretoria (v60)
Em cima da métrica da v59. Detalhe em `docs/relatorios.md`, seção "Janela
e farol de registro".
- **Supabase** (`sql/042-janela-farol.sql`, bloco único; precisa dos
  sql/020 e 040): `operacao_janela` (cadência esperada de registro por
  operação — cadencia_dias + tolerancia_dias; linha geral da atividade ou
  por unidade, que vence a geral e pode desligar com ativo = false; origem
  proposta/agronomo/veterinario/nilo; só o SQL Editor escreve),
  `vw_dsr_boletim_unidade` (1º e último boletim por unidade) e
  `vw_farol_registro` (tudo da vw_dias_sem_registro + janela + **farol** +
  **situacao** em texto pronto). Farol: verde = registrado na cadência;
  amarelo = sem registro com a janela aberta; **vermelho só depois de a
  janela fechar**; cinza = unidade sem boletim; sem janela = sem farol.
  Nunca registrado conta desde o 1º boletim da unidade e o texto diz isso.
  Janela não é prescrição (não diz o que fazer, produto nem dose).
  Seed proposto só para grãos (monitoramento 7+3) e pecuária (9
  operações: suplementação 7+3 … vacinação 180+30) — **café sem janela**
  (já tem os faróis do plano). Ajuste por SQL, exemplos no cabeçalho.
- **App**: `baixarFarolRegistro()` em `syncTudo` só para códigos com painel
  (gerente não baixa nem vê), cache em `bdf:farolRegistro`. Painel da
  Diretoria ganhou o botão **"Faróis de registro"** (abaixo de 📊
  Relatórios, com "N com janela fechada · N com janela aberta"). Telas
  novas, nas classes cad-*: **Faróis de registro** (lista por unidade
  agrupada por atividade, pior cor manda, contagem em dia / janela aberta /
  janela fechada / sem histórico na linha, busca) e **unidade** (operações
  com janela ordenadas por cor com o texto da situação e a janela; bloco
  "Operações sem janela" fechado com "há N dias" / "sem registro"). Farol
  quadrado (`.farol.reto`) e botões sem sombra/raio nas telas novas (P10).
  Vocabulário: "sem registro", "janela aberta/fechada", "em dia", "sem
  histórico" — nunca "não fez", "atrasado", "pendente".
- **v65 — café na lista:** unidade cujas operações não têm janela
  nenhuma (hoje, as 10 de café — decisão da v60 de não dar janela ao
  café continua) entra no fim da lista, sem cor, com "sem janela · N de
  M operações com registro" na linha (P7); a tela da unidade mostra o
  vazio "Sem operação com janela em Água Limpa." e o bloco "Operações
  sem janela" (fechado, como nas outras) com "há N dias" / "sem
  registro" e o ritmo. Unidade com pelo menos uma janela é mostrada
  exatamente como antes (regressão byte a byte em grãos e pecuária).
  Regra neutra quanto à atividade: uma unidade de grãos com todas as
  janelas desligadas por unidade passaria a aparecer do mesmo jeito.
- Telas do gerente e da pós-colheita idênticas à v59 (regressão em
  scripts/regressao_render.cjs, que agora também abre as duas telas novas);
  `scripts/checar-poluicao.cjs` mede as telas novas com os padrões de
  Cadastros, usando linhas de exemplo no formato da visão.

## Estados de lista (v61) — carregando · erro · vazio com recorte
Regra permanente (CLAUDE.md item c2; detalhe em
`docs/definicao-de-pronto.md`, item 6). Motivação: grãos e pecuária
começam com pouco histórico e um vazio mudo faz o gerente achar que o
app quebrou; o vazio bem escrito diz o que está vazio e sob qual
filtro, sem imputar omissão.
- **Função única** no `index.html`: `fraseVazio(recorte)` monta a frase
  ("Sem boletim registrado em Floramill. Os boletins aparecem aqui
  depois do primeiro envio."; "Sem boletim de grãos em Capoeira Grande
  de 01/09 a 07/09/2026. Último registro há 7 dias (31/08).") e
  `htmlEstado("carregando"|"erro"|"vazio", recorte, {tag, classe,
  colspan, acao})` embrulha em `p`/`li`/`td`/`div`; `periodoVazio(de,
  ate)` e `haDias(iso)` são apoio. Nomes só por id (`fazenda(id).nome`,
  `talhao(id).nome`); vocabulário "sem registro", nunca "não fez" /
  "pendente" / "atrasado" / "faltou"; sem exclamação nem emoji.
- **Onde vale (29 pontos):** casa do gerente de grãos e pecuária
  ("Últimos boletins"), seção Talhões e ciclos (sem talhão de grãos),
  Irrigação por pivô (sem pivô cadastrado), painel da Diretoria (lista
  de boletins nomeando atividade, unidade, operação, busca e período,
  com "último registro" quando há unidade escolhida; cartão da unidade;
  Resumo do período), escolha de fazenda (código sem unidade da
  atividade), tela 📊 Relatórios (textos, números por filtro, sem
  cache), tela do relatório (período + unidade), tabelas dos
  relatórios ("Sem registro neste período") e 15 listas/buscas de
  Cadastros (busca global, fazendas, talhões, ciclos e histórico,
  lotes e inventário e histórico, plano por fazenda e busca de unidade,
  códigos, catálogo com busca, máquinas, insumos, importações manuais).
  Cinco desses pontos ficavam em branco absoluto antes da v61.
- **Faróis de registro (v60)** entraram na mesma regra na v61:
  `farolEstado` em `baixarFarolRegistro` (carregando / erro com Tentar
  de novo) e vazios "Sem farol baixado para as unidades deste código.
  Com internet, toque em Atualizar…", "Sem operação com janela nas
  unidades deste código." e, na unidade, "Sem operação com janela em
  {unidade}."
- **Carregando e erro** (Relatórios e Faróis leem da rede sem já ter
  os três estados): `relEstado` em `baixarRelatorios` separa "baixando"
  ("Carregando relatórios…", também enquanto `syncOcupado`) e "não
  conseguiu baixar" ("Não foi possível carregar os relatórios." +
  botão Tentar de novo, `data-sync`, que redesenha já em carregando) de
  "o motor não gerou nada" (vazio). Com cache no aparelho, o cache é
  mostrado e nenhum desses aparece. Unidades e Plano (v52) já tinha os
  três estados e é a referência.
- **Café (v65):** as telas de café passaram a usar a mesma função
  (até a v64 mantinham os textos antigos): casa do gerente de café
  ("Sem boletim registrado em Vereda Romaria. Os boletins aparecem aqui
  depois do primeiro envio."), casa da pós-colheita ("Sem registro de
  pós-colheita em Vereda Romaria. …"), tela do relatório para o gerente
  de café ("Sem relatório calculado em Vereda Romaria para
  05/09/2026."), cartão "Café em trânsito" do painel ("Sem carga de café
  aguardando confirmação do destino.") e Escritório › Unidades e Plano
  (carregando "Carregando o plano de safra…", erro "Não foi possível
  carregar o plano de safra." + motivo + Tentar de novo próprio, vazios
  "Sem fazenda com plano de safra cadastrada." / "Sem versão do plano
  para Água Limpa." / "Sem unidade do plano em Água Limpa."). Nenhuma
  tela decide texto por `atividadeDe(fz)`. Fora por desenho: o marcador
  inline "sem apelidos" (rótulo por item, como "sem área"), o cartão de
  cargas a receber (some sem dado) e os avisos dos robôs. Legenda do
  farol do painel passou de "○ faltou" para "○ sem registro" na v61.
- **Fica de fora, por desenho:** listas de lançamento do boletim (só o
  "＋", padrão a), cartões que somem sem dado (Solinftec, iCrop, Meus
  relatórios), avisos dos robôs. Para decisão do Nilo: os títulos
  "Boletim de hoje pendente" / "Registro de hoje pendente" (rótulo de
  situação nas casas do gerente e do pós-colheita, mexer toca o café)
  e "pendente" no relatório de rebanho (GMD/lotação, texto do motor).
  Enriquecer com `vw_dias_sem_registro` (por operação) fica para o
  item "janela por operação e farol".

## Intervalo entre operações (v62) — ritmo por unidade × operação
A outra metade da métrica da v59: **de quanto em quanto tempo** uma
operação vem sendo registrada em uma unidade (ideia do rodapé de manejo do
app Sigma, Fundação ABC). Detalhe em `docs/relatorios.md`, seção
"Intervalo entre operações". Não confundir: `dias_sem_registro` olha do
último registro até hoje (lacuna aberta); `intervalo_dias` olha entre dois
registros consecutivos do passado (ritmo fechado). Ritmo de 20 dias com 3
dias sem registro é normal; com 60, vale olhar.
- **Supabase** (`sql/043-intervalo-operacoes.sql`, bloco único com passo a
  passo; precisa dos sql/020 e 040; conferência opcional em `sql/044`):
  `vw_intervalo_operacoes` (uma linha por registro com o anterior da mesma
  unidade × operação: data_registro, data_registro_anterior,
  intervalo_dias, lancamentos_no_dia; `LAG()` por unidade e operação) e
  `vw_ritmo_operacoes` (qtd_registros, qtd_intervalos, **mediana** — não
  média —, mínimo, máximo, data_ultimo_registro). Base é a
  `vw_dsr_registros` + `operacao_alias` da v59 (nada de extração
  repetido); mesmas combinações da `vw_dias_sem_registro`. **Um registro
  = um dia** com a operação no boletim da unidade (vários talhões no
  mesmo boletim = mesmo registro; `lancamentos_no_dia` guarda quantos).
  **Primeiro registro = intervalo NULL**, nunca 0; **1 registro só =
  qtd_intervalos 0 e estatísticas NULL**. Sem status, alerta, atraso ou
  "ritmo esperado" (não há padrão cadastrado; seria prescrição). Leitura
  anon herdada, security_invoker, nenhuma escrita. Café entra só como
  dado; nenhuma tela de café lê.
- **App**: `baixarRitmoOperacoes({atividade, unidade})` (cache
  `ritmoCache` / `bdf:ritmoOperacoes`; em `syncTudo` só para códigos com
  painel e só GRAOS + PECUARIA), `baixarIntervaloOperacoes` (pares, sob
  demanda), `ritmoDe`, `textoRitmo` ("a cada 18 dias"; vazio sem
  intervalo). Única tela: **Diretoria › Faróis de registro › unidade**
  ganha o texto secundário "ritmo: a cada N dias" na linha da operação
  (com janela: depois da janela; sem janela: abaixo do nome), só com
  dois registros ou mais — sem intervalo a linha é omitida (nada de
  "sem ritmo" nem traço); o rodapé explica o ritmo. Até a v64 só em
  unidades de grãos e pecuária (o app só baixava GRAOS e PECUARIA e a
  tela recusava CAFE); **desde a v65 nas três atividades**: `syncTudo`
  baixa o ritmo sem filtro de atividade e a tela da unidade de café
  mostra "ritmo: a cada N dias" pelo mesmo `textoRitmo`. Não há eixo de
  florada/poda aqui (Onda 2): a métrica mede intervalo entre registros
  consecutivos, sem marco. Gerente não baixa nem vê. Nenhum campo novo.
- Versão v62 (rodapé + cache do sw.js).

## Cabeçalho contextual (v66) — telas de leitura, três atividades
Regra permanente em CLAUDE.md, item c5; checagem em
docs/definicao-de-pronto.md, item 8; vocabulário em
docs/catalogos-por-atividade.md, "Cabeçalho contextual". Ideia do app
Sigma (Fundação ABC) adaptada: mesmo valor informativo, fração do
espaço.
- **Componente único** `cabecalhoContexto(fazendaId, {sub, voltar})`
  substitui `topo()` nas telas de leitura com unidade escolhida: casa
  do gerente (café, grãos, pecuária), boletim enviado (as três), casa e
  registro do pós-colheita (café), tela do relatório quando aberta pelo
  gerente (as três) e Diretoria › Faróis de registro › unidade (as
  três). Painel, Relatórios, Faróis (lista) e Resumo do período são de
  grupo (sem unidade escolhida) e ficam com `topo()`; home das abas,
  escolha de unidade, boletim em 3 passos, formulário do pós e Cadastros
  intocados.
- **Linha 1** (barra sticky `.topo.ctx`, sempre visível): "Fazenda ›
  Unidade (área)" — fazenda física por `maeDe`, unidade = rótulo da
  atividade (`ATIVIDADES`, por id; unidade operacional = fazenda física
  + atividade, o que evita "Mata Preta › Mata Preta — Café"), área =
  `areaUnidade` (soma dos talhões cadastrados na unidade, sem ESTRUTURA
  e sem ARRENDADO) em `fmtHa` ("1.234,56 ha"), tipografia secundária.
  Sem área (Porto Buriti, Monte Carmelo — Pecuária) o parêntese some.
- **Linha 2** (faixa `.ctx-l2`, só no topo da tela): catálogo
  `CTX_ATIVIDADE[atv].ciclo` — grãos "ciclo: Feijão, Soja" (culturas
  dos ciclos ativos dos talhões); café e pecuária sem ciclo (nenhuma
  safra inventada) — mais o texto da tela: "Gerente", "dd/mm/aaaa ·
  responsável", "Terreiro · Secador · Benefício", "dd/mm/aaaa ·
  Pós-colheita · responsável", "nome do relatório · período", "Faróis de
  registro".
- **Colapso** sem JS: a faixa é estática e rola por baixo da barra
  sticky; volta ao rolar para o topo; nada muda de altura (sem salto).
  Medido a 390 × 844: 64 + 19 = 83 px expandido (9,9 %; 11,9 % de 700
  px úteis), 64 px colapsado (7,6 %; piso dos botões "‹"/"⇥" de 40 px).
- Desde a v73 a régua de 7 dias (#19) entra logo abaixo do cabeçalho
  nas casas do gerente e do pós-colheita (seção "Régua de 7 dias
  (v73)"): conjunto medido em 148 px (17,6 % de 844); o carimbo de
  origem de dado (#3) segue no rodapé de cada bloco.
- Sem SQL, sem campo novo, sem texto prescritivo; a área do plano
  (`unidade_manejo`) não é usada. Regressão: diferença main × branch só
  no trecho do cabeçalho, igual nas três atividades.

## Texto longo em lista nasce colapsado (v68) — Relatórios da Diretoria
Regra permanente em CLAUDE.md, item c7; checagem em
docs/definicao-de-pronto.md, item 10; comportamento da tela em
docs/relatorios.md, "Tela Textos para revisar (v68)".
- **Problema resolvido:** em Diretoria › 📊 Relatórios cada texto do
  robô-redator nascia inteiro (mais de uma tela do iPhone), escondia a
  seção "Números" e deixava o "copiar para WhatsApp" no fim de uma
  tela e meia de leitura.
- **Componente único** `cartaoTextoLongo(o)` + `abrirFolhaTexto(o)` /
  `fecharFolhaTexto()` + `ajustarTextosLongos()` (CSS `.txt-cartao`,
  `.txt-previa`, `.txt-acoes`, `.folha`, `body.folha-aberta`). O cartão
  nasce colapsado: tag de aviso, título, prévia de 3 linhas (corte por
  linha inteira, reticências reais, sem fade/gradiente), origem
  compacta "robô-redator · dd/mm hh:mm", e "ler texto completo ›" +
  "📲 copiar para WhatsApp" lado a lado. Copiar funciona sem expandir e
  copia o texto integral (`relCopiar`). Texto que cabe nas 3 linhas
  não mostra reticências nem "ler texto completo".
- **Folha de leitura** em tela cheia (`.folha`, fora do `#app`):
  cabeçalho fixo "‹ Fechar", tag, texto completo, origem completa
  ("Redigido no Supabase por <modelo> em dd/mm, hh:mm a partir dos
  números do relatório"), rodapé fixo com Fechar + copiar. Corpo da
  página travado enquanto aberta; ao fechar volta à posição de rolagem
  anterior (Escape também fecha).
- **Textos:** "Confira e ajuste antes de mandar" saiu do rodapé do
  cartão (a tag já avisa). Lista "Números": "N unidades · todas para
  conferir" quando total e "para conferir" coincidem ("1 unidade · para
  conferir" no singular); diferentes, os dois números ficam.
- **Onde entra:** seção "Textos para revisar" e a tela do relatório
  narrativo ("ver com os números ›"), mesmo componente. Só
  Diretoria/ADMIN veem textos (o gerente nunca baixa rascunho — igual à
  v57). Sem variação por atividade. **Não editável, como antes:** o app
  nunca gravou ajuste de texto; nada foi acrescentado.
- Sem campo novo, sem SQL, sem texto prescritivo. Medição nova em
  `scripts/checar-poluicao.cjs` (item 8, com textos de exemplo) e
  passos `25–28` da Diretoria em `scripts/regressao_render.cjs`.

## Badge de categoria da operação (v67) — listas de leitura, três atividades
Regra permanente em CLAUDE.md, item c6; checagem em
docs/definicao-de-pronto.md, item 9; categorias e letras em
docs/catalogos-por-atividade.md, "Categorias de operação". Ideia do
app Sigma (Fundação ABC): o quadradinho cinza de uma letra — só o
mecanismo; as categorias do Sigma (herbicida, inseticida, fungicida,
adubo) NÃO foram copiadas.
- **Componente único** `badgeCategoria(atividade, {id | nome})` +
  catálogo `OP_CATEGORIAS` + `codigoOperacao` (mesma regra de id do
  sql/040) + `categoriaOperacao`. Uma letra maiúscula, 20 × 20 px,
  fundo `--linha`, texto `--tinta`, monoespaçado, sem raio, sem sombra,
  inline dentro do `<b>` do nome (centrado na primeira linha, nunca
  empurra o nome). `aria-label` e `title` com o nome da categoria;
  `role="button"`, Enter/Espaço = toque.
- **Sem cor por categoria** (decisão explícita): a cor é canal do
  farol. Fundo neutro único para todas as letras.
- **Categoria = natureza da operação, por chave.** Grãos e pecuária:
  a fase/grupo do catálogo (`OPS_GRAOS_FASES`, `OPS_PECUARIA_FASES`),
  5 por atividade — grãos R/P/D/C/S (Pré-plantio, Plantio, Condução,
  Colheita, Pós-colheita), pecuária D/S/R/L/P (Manejo diário,
  Sanitário, Reprodutivo, Manejo de lote, Pastagem e estrutura). Café:
  o catálogo não tinha fase; **proposta pendente de aprovação do
  Nilo** — C Colheita · A Aplicação · T Trato cultural · M
  Monitoramento · I Irrigação e infraestrutura (tabela no
  docs/catalogos-por-atividade.md). Operação sem categoria ("Outra",
  termo do escritório) não tem badge, sem placeholder.
- **Legenda sob demanda:** toque no badge mostra o nome da categoria
  numa etiqueta por 2,5 s (2º toque ou toque fora fecha). Nenhuma
  legenda fixa. Área de toque de 44 px por `::before`.
- **Onde entra:** Diretoria › Faróis › unidade (com janela e "sem
  janela", pelo `operacao_id` da visão) e boletim enviado (cartão
  "Atividades" do café, "Operações do dia" dos grãos e "Outros
  manejos" da pecuária, pelo nome exato gravado). **Onde não entra,
  por desenho:** apontamento em 3 passos; resumo de uma linha da casa
  do gerente e do painel; movimentação/sanidade/manejo em massa da
  pecuária (blocos de uma natureza só); Cadastros › Catálogos (grãos e
  pecuária já listam por fase; café mantido igual).
- **Conferência:** `node scripts/gerar_categorias_operacoes.cjs` (≤ 5,
  letras únicas, toda operação em uma categoria; `--sql` gera o
  espelho). Espelho opcional no Supabase: `sql/046-operacao-categoria.sql`
  (tabela `operacao_categoria` + coluna `categoria_id`; o app NÃO lê —
  rodar só depois da aprovação das categorias do café).
- Sem campo novo, sem texto prescritivo, sem SQL obrigatório. Regressão:
  diferença main × branch nas telas de leitura é só o
  `<span class="op-cat">`, igual nas três atividades.

## Resposta explícita de ausência por seção (v69) — boletim, três atividades
Regra permanente em CLAUDE.md, item c8; checagem em
docs/definicao-de-pronto.md, item 11; classificação das seções em
docs/catalogos-por-atividade.md; tabela e visão em docs/relatorios.md.
- **Problema resolvido:** cartão vazio parecia cartão resolvido (não
  havia diferença entre "olhei e não havia praga" e "nem abri"), e
  silêncio não é dado — sem registro de broca não se sabe se não havia
  ou se ninguém verificou. Com pressa, pular custava zero e registrar
  custava várias decisões.
- **Solução:** nas seções EVENTUAIS, sem registro, o cartão mostra
  dois chips (padrão `.chip` de sempre): **"Nada a registrar hoje"**
  (um toque grava `rascunho.secoes[id] = {resposta:"sem_ocorrencia",
  por, em}` e recolhe o cartão; o 2º toque desfaz — "toque de novo
  para desfazer" ao lado; sem modal) e **"Registrar…"** (aciona o "＋"
  de sempre: ocorrência, movimento, tratamento — rótulo pelo catálogo).
  Com registro os chips somem. Sem ação em massa. O chip declara que
  não há o que registrar, nunca que "está tudo bem".
- **Três estados no cabeçalho** (componente único `resumoSecaoHtml`;
  repintura por `pintarSecoesResposta`): "sem resposta" cinza = não
  respondido (texto neutro desde a v70, decisão do Nilo — a v69 usava
  "○"; neutro: sem vermelho, sem "pendente"/"faltando"/"obrigatório", sem
  emoji de alerta — a janela do dia ainda não fechou); "sem ocorrência"
  cinza = respondido; "N registros" verde = com registros (Movimentação
  mantém "2 nascimentos · 1 morte").
- **Registro e resposta nunca coexistem:** adicionar um registro numa
  seção respondida apaga a resposta sozinho (`limparRespostasSecao`, em
  cada "＋"/remover e no envio); no banco o gatilho refaz o cálculo e a
  trava recusa linha em seção com registro.
- **Dados:** a resposta sobe DENTRO do payload do boletim (fila offline
  de sempre; rascunho automático em `bdf:rascunho` a guarda). No
  Supabase (`sql/047-secao-resposta.sql`): `boletim_secao` (catálogo,
  id imutável = chave substituta), `boletim_secao_resposta` (uma linha
  = "sem ocorrência" com autor e hora; ausência de linha = não
  respondido, sem enum pendente; escrita SÓ pelo gatilho de `boletins`
  a partir de `payload.secoes`, security definer, sem policy de
  escrita) e `vw_completude_boletim` (por boletim: seções eventuais,
  com registro, sem ocorrência, não respondidas + ids). Leitura no app:
  `baixarCompletudeBoletim({unidade, de, ate})`, sob demanda, sem tela.
- **Envio (v70, decisão do Nilo):** Enviar com seção eventual sem
  resposta não envia: o app abre as seções, mostra um aviso âmbar
  acima da primeira ("Antes de enviar, responda: … Registre o que houve
  ou toque em Nada a registrar hoje") e rola até ela; o aviso some ao
  responder. Um toque por seção, sem ação em massa. Só as eventuais;
  as esperadas seguem a regra de sempre (clima ou observação). Com
  isso, boletim enviado a partir da v70 não tem "não respondido" —
  a visão `vw_completude_boletim` continua valendo para o histórico e
  para aparelhos que ainda não atualizaram.
- **Não mudou:** ordem dos
  cartões (a ordem é a narrativa do dia e Observações continua por
  último; reordenar dinamicamente faria a seção pular entre
  redesenhos — sugestão futura, ver PR), tela de apontamento em 3
  passos, seções esperadas (Irrigação já tinha "Dia sem irrigação" /
  "Não rodou"), resumo WhatsApp, boletim enviado, painel, Cadastros.
  Café, grãos e pecuária recebem o MESMO componente; nenhum
  `if(atividade==="…")` na tela — vocabulário por chave do catálogo.

## Ações por perfil (v71) — oculta ou desabilitada visível, três atividades
Regra permanente em CLAUDE.md, item c9; checagem em
docs/definicao-de-pronto.md, item 12; tabela vigente (ação × tela ×
perfis × decisão × motivo) em docs/acoes-por-perfil.md.
- **Problema resolvido:** o app escondia tudo o que o perfil não podia
  fazer; quem nunca viu a ação não sabia que ela existia nem a quem
  pedir (ideia do app Sigma, Fundação ABC: o botão de outro papel
  aparece esmaecido e ensina a hierarquia sem treinamento).
- **Limite:** mostrar demais é pior que esconder — cada botão esmaecido
  revela que a função existe, que outro papel a executa e que a pessoa
  não é esse papel. Regra de decisão em três condições (útil para
  pedir · rótulo sem produto/dose/custo/outra fazenda · mesmo domínio
  que a pessoa já vê) e lista do que nunca aparece (outra atividade,
  administrativo para gerente, custo, outra fazenda, código). Na
  dúvida, oculto. Classificação aprovada pelo Nilo em 08/09/2026 antes
  do código.
- **Aplicado (3):** "⚙ Cadastros" no painel, para a Diretoria ("Ação do
  escritório (administrador)"); "✏️ Corrigir" no boletim enviado, para
  Diretoria e ADMIN ("Ação do gerente (até 48 h após o envio)"); "Marcar
  como visto" no boletim enviado, para o gerente ("Ação da diretoria").
  Em cada linha 1 de 4 botões.
- **Continuam ocultas (10):** botões de atividade e pós-colheita na
  entrada (outra atividade; para a Diretoria passaria da metade),
  Diretoria/Relatórios/Escritório na entrada do gerente (todas as
  fazendas; administrativo), lista de unidades (outra fazenda),
  relatórios só da Diretoria na casa do gerente (custo, plano), Faróis
  (regra 4 do plano), tudo em Cadastros (administrativo, códigos),
  preencher boletim para a Diretoria (só leitura; densidade).
- **Componente:** `botaoAcao(id, ctx, {rotulo, aria, classe, attrs})`
  desenha os três estados; o esmaecido é `.acao-off` (cinza `--tinta-2`
  sobre `--papel`, borda tracejada, sem sombra, sem cadeado),
  `aria-disabled`, `aria-label` com o papel, sem id/data de ação; toque
  mostra `data-papel` por 2,5 s (classe `mostra`, `dir` quando o botão
  está na metade direita), sem modal. Mesmo componente nas três
  atividades e em todos os perfis.
- **Centralização:** as 8 decisões de perfil das telas de entrada,
  painel e boletim enviado saíram dos templates e entraram no catálogo
  (saída HTML idêntica onde o estado é permitido/oculto — prova na
  regressão). As listas guiadas por escopo (`unidadesPermitidas`,
  `podeVer` nos relatórios e faróis) continuam como estão: são filtros
  de dado, não ações. Ação nova sujeita a perfil entra no catálogo e na
  tabela do docs, com `visivel` declarado.
- **Fora, por regra:** tela de apontamento em 3 passos (zero ações
  desabilitadas, medido), "Corrigir" para o próprio gerente depois de
  48 h (regra de prazo, não de perfil; a tela já explica).

## Régua de 7 dias (v73) — telas de leitura por data, três atividades e pós-colheita
Regra permanente em CLAUDE.md, item c11; checagem em
docs/definicao-de-pronto.md, item 14; vocabulário em
docs/catalogos-por-atividade.md, "Régua de 7 dias". Ideia do app Sigma
(Fundação ABC) adaptada: só o mecanismo (sete dias tocáveis); dias em
português, sem datepicker nativo, sem rolagem de lado.
- **Problema resolvido:** a casa do gerente e a do pós-colheita só
  falavam de hoje; ver outro dia exigia achar o boletim na lista de
  "Últimos boletins" (5 itens) ou pedir à Diretoria. A regra 2 proíbe
  campo de digitação e o datepicker do iOS é ruim de uma mão só, no sol.
- **Componente único** `reguaDias(fazendaId, dia)` + `diaRegua(fazendaId)`
  + `cartaoDiaRegua(o)` + catálogo `DIAS_SEMANA`/`DIAS_SEMANA_LONGO` +
  `hojeBRT()` (`FUSO_BRT`) + estado em memória `reguaVista`; CSS
  `.regua`, `.regua-dia` (`.on`, `.hoje`, `.ds`, `.dn`). Sete células
  fixas de 48,3 × 48 px a 390 px (362 px de régua, sem rolar de lado),
  do mais recente (esquerda) ao mais antigo; dia da semana em cima
  (seg · ter · qua · qui · sex · sáb · dom) e número embaixo em
  monoespaçado; nenhum dia futuro; sem setas nem "carregar mais".
  Selecionado = fundo verde + número em negrito + `aria-pressed`; hoje =
  barra de 3 px embaixo (branca quando selecionado) e ", hoje" no
  `aria-label`. Um toque (`data-regua`) troca o dia e redesenha a casa
  mantendo a rolagem; a escolha volta para hoje ao trocar de unidade, ao
  sair da janela de 7 dias e ao voltar ao primeiro plano depois da
  virada do dia (`visibilitychange`). "Hoje" é o dia civil em Brasília,
  comparação por texto AAAA-MM-DD (sem deslocamento em relação ao banco).
- **Onde entra:** casa do gerente (café, grãos, pecuária — mesmo
  componente) logo abaixo do cabeçalho contextual e da faixa de cor da
  atividade, e casa do pós-colheita abaixo do cabeçalho. Fora, por
  desenho: tela de apontamento em 3 passos, home das abas, escolha de
  unidade, boletim enviado (uma data só), painel e Resumo do período da
  Diretoria (filtram por período de/até com os `input type=date` que já
  existiam — ver PENDÊNCIAS), Faróis (sem data), Cadastros.
- **O que muda com o dia escolhido:** só o cartão do dia e o cartão
  Solinftec. Hoje selecionado = tela idêntica à v72 ("Boletim de hoje
  enviado/pendente", "Preencher boletim de hoje", "O que ficou de
  ontem", "Últimos boletins"). Outro dia: linha tocável "Boletim de
  dd/mm enviado · Enviado às hh:mm · resumo" (abre o boletim; farol
  vermelho com ocorrência/praga alta ou irrigação crítica, como na
  lista) ou o vazio pela função única — "Sem boletim registrado em
  Floramill em 05/09/2026." / "Sem registro de pós-colheita em Vereda
  Romaria em 05/09/2026." (`periodo: periodoVazio(dia, dia)`); Solinftec
  "medição automática de dd/mm" com a linha de origem no rodapé (c3).
  Nada de preencher boletim de dia passado pela régua (o apontamento
  continua só o de hoje).
- **Medidas** (390 × 844): cabeçalho 83,4 px + faixa 3 px + régua 48 px
  + margem 12 px = 148,4 px (17,6 % de 844; 21,2 % de 700 px úteis;
  pós-colheita 145,4 px, 17,2 %) — abaixo do teto de ~25 %; régua
  estática (não sticky), o primeiro cartão começa em 160 px.
- Sem SQL, sem campo novo, sem texto prescritivo, sem navegação além de
  7 dias. Regressão main × branch: diferença só o bloco `.regua` nas
  casas (igual nas três atividades e no pós); apontamento em 3 passos,
  boletim enviado, painel, Relatórios, Faróis e Cadastros byte a byte
  iguais. Medição nova em `scripts/checar-poluicao.cjs` (grupo 11, 24
  itens ✅, inclusive a casa do pós-colheita, que passou a ser medida) e
  passos `05-regua-ontem`/`06-regua-hoje` em
  `scripts/regressao_render.cjs`.

## Plano do dia seguinte × executado (v75) — três atividades
Regra permanente em CLAUDE.md, item c13; checagem em
docs/definicao-de-pronto.md, item 16; vocabulário e de-para em
docs/catalogos-por-atividade.md, "Plano do dia seguinte".
- **Problema resolvido:** o boletim registrava o que ACONTECEU, e a única
  forma de dizer o que ia acontecer era um campo de texto livre
  ("Pendente / programado para amanhã") que ninguém conseguia comparar
  depois. Agora o gerente planeja o dia seguinte em chips (uns 20 s, ao
  fechar o boletim) e o app confere sozinho, no dia seguinte, o que foi
  registrado — sem digitar status e sem tela nova de acompanhamento.
- **Onde mora o dado (nenhuma tabela nova):** `D.planoDia` guarda os
  planos cujo dia-alvo ainda não fechou; ao enviar o boletim do dia-alvo,
  `gravarPlanoNoBoletim` fecha o plano DENTRO do boletim, em `b.plano`
  (itens com status, motivo, clima declarado do dia, pessoas previstas ×
  lançadas), e o tira do `D.planoDia`. Como `b.plano` vive no payload de
  `boletins`, ele sincroniza pelo caminho que já existia e a Diretoria o
  lê nos boletins que já baixa. Plano pendente vence `b.plano` (é o
  replanejamento do próprio dia).
- **Componentes únicos:** `abrirFolhaPlano(r, {alvo, replan})` (folha
  "📋 Amanhã", classe `.folha` compartilhada com a folha de leitura da
  v68 por `travarFolha`/`destravarFolha`), `planoGuardar`,
  `faixaPlanoHoje` / `htmlPlanoFaixaCorpo` / `pintarPlanoHoje` (faixa do
  topo do boletim), `linhaPlanoCasa` e `linhaPlanoSemana` (casa do
  gerente), `cartaoPlanoPainel` (Diretoria), `avaliarPlano` (status),
  `planoResumo` + `planoMotivosTexto` (todas as correlações),
  `planoDiaDe` / `planoPendente` (leitura). Catálogos: `PLANO_ATIVIDADE`
  (ONDE, O QUÊ e onde procurar o registro, por atividade),
  `PLANO_PEC_DEPARA` (espelho de `operacao_alias` do sql/040),
  `PLANO_MOTIVOS`, `PLANO_ST`, `CLIMA_IMPEDITIVO`, `PLANO_CHUVA_MM`
  (25 mm), `PLANO_MAX_ITENS` (3).
- **Fluxo do gerente.** (1) Ao enviar, depois do cinto de segurança e
  antes de gravar, abre a folha "📋 Amanhã": se o plano de hoje ficou com
  ⚪ ou ◐ e o dia NÃO foi impedido pelo clima declarado, o primeiro bloco
  pergunta uma vez "O que atrapalhou hoje?" por chips; abaixo, o plano de
  amanhã em até 3 linhas, no padrão de 3 passos (ONDE em chips → O QUÊ em
  chips → pessoas previstas), com o que ficou "continua amanhã" já
  sugerido. Dois botões: "Pular" · "Salvar plano" — nos dois casos o
  boletim é enviado. (2) No dia seguinte, a faixa "📋 O plano de ontem
  para hoje" fica no topo do boletim, e a caixinha de cada linha vai de
  ⚪ para ◐/✅ sozinha conforme os lançamentos, no lugar. (3) O botão
  "ajustar" da faixa reabre a folha para o próprio dia: fica
  "replanejado", nunca falha. (4) Na casa, uma linha: "📋 Plano de hoje:
  2 de 3 ✅ · 1 não feito (máquina quebrou)"; de sexta a domingo, também
  "📋 Você cumpriu 78% do que planejou nesta semana."
- **Status (`avaliarPlano`), sempre sobre REGISTRO:** ✅ todos os "onde"
  do item com registro daquela operação; ◐ parte deles, ou registro
  marcado "continua amanhã"; ⚪ nenhum. Registro sem talhão/pasto cobre o
  item inteiro (na dúvida, a favor de quem registrou).
- **Correlações calculadas (`planoResumo(fz, dias)`), nada digitado:**
  aderência (itens ✅ / planejados) em 7 e 30 dias; distribuição dos
  motivos; desvios evitáveis × de clima; dias trabalháveis × dias
  impedidos (fonte: o clima declarado no boletim); precisão de esforço
  (pessoas previstas × pessoas lançadas na mão de obra); dias
  replanejados.
- **Diretoria:** cartão "📋 Planejado × Executado" no painel, uma linha
  por unidade com plano nos últimos 30 dias, ordenada por **unidades com
  mais desvios evitáveis** (empate desfeito pela aderência) — rótulo de
  apoio, nunca ranking; só nome de UNIDADE, nunca de pessoa. Sem plano no
  período, cai no vazio da função única, nomeando o recorte.
- **WhatsApp:** primeira linha do resumo intocada; a aderência da semana
  entra só no resumo de sexta. O campo de texto do boletim virou "O que
  ficou para terminar" (era "Pendente / programado para amanhã") e a
  linha do resumo virou "📌 Ficou para terminar:" — o plano de amanhã tem
  lugar próprio, então nada é digitado duas vezes.
- **Justiça:** dia impedido pelo clima declarado nunca conta como desvio
  evitável (o motivo entra automático como "clima" e nem é perguntado);
  nenhuma tela expõe um gerente para outro; replanejar não é falha.
- **Supabase:** `sql/048-plano-x-executado-diario.sql` (testado num
  PostgreSQL 16 local com boletins semeados — números, idempotência e
  permissão do papel `anon` conferidos; falta rodar no SQL Editor) —
  visão `vw_plano_x_executado` (um item de plano por linha) e o
  relatório mensal `plano_x_executado_diario` em `relatorios_gerados`,
  que o app já lê pela vitrine (`REL_CATALOGO`). Sem o SQL rodado, tudo
  no app funciona igual; só o relatório mensal não existe.
- Sem campo novo de digitação para o gerente além do plano (chips +
  pessoas previstas), sem texto prescritivo, **apontamento em 3 passos do
  boletim intocado**. Medição nova em `scripts/checar-poluicao.cjs`,
  grupo "13. Plano do dia" (93 ✅: um cenário por atividade, a variante
  do dia de chuva no café e o cartão da Diretoria).
- **Fica para o módulo de programação/metas** (que o app ainda não tem):
  a pré-marcação das atividades das metas em risco e o cruzamento META ×
  RITMO (quanto do avanço de cada meta veio de dia planejado). Ver
  PENDÊNCIAS.

## Chips removíveis da multi-seleção (v74) — três atividades e Cadastros
Regra permanente em CLAUDE.md, item c12; checagem em
docs/definicao-de-pronto.md, item 15; vocabulário do contador por tela
em docs/catalogos-por-atividade.md, "Chips removíveis".
- **Problema resolvido:** nas multi-seleções por chips a pessoa só via a
  escolha pelos chips acesos espalhados na lista de opções (8 problemas,
  8 setores, 24 unidades…): sem contagem, sem lista do que já marcou e
  sem jeito de tirar um item senão procurá-lo na lista.
- **Componente único** `chipsSelecao(attr, {um, varios})` +
  `pintarSelecoes()` (CSS `.sel-box`, `.sel-cont`, `.chip.sel`, `.sel-x`,
  `.sel-mais`; `SEL_MAX = 6`; `selExpandido`). Só EXIBE a seleção, lida do
  estado `.on` dos chips de opção do mesmo bloco: contador ("3 setores
  selecionados", substantivo por tela) + um chip por item na ordem do
  cadastro, rótulo + × à direita. O × dispara o toque do chip de opção
  correspondente — o tratador que já existia remove e grava (nenhum
  mecanismo novo). Remoção imediata, sem confirmação. × de 44 × 44 px,
  `aria-label`/`title` "Remover <nome>". Corpo do chip inerte (decisão
  única). Mais de 6 → 6 + "+K" que expande. Vazio → nada desenhado.
  Quebra em linhas; nunca rola de lado. Sem cor nova, sem sombra.
- **Onde entra (6 multi-seleções — todas as que o app tem fora do
  apontamento):** ☕ Café › Irrigação › "Qual foi o problema?" (`irrpb`)
  e Fertirrigação › "Em quais setores?" (`irrfsec`, talhões por id);
  Cadastros › Códigos › novo combinado › Atividades inteiras
  (`combo-atv`) e Unidades avulsas (`combo-uni`); Cadastros › Catálogos ›
  Máquinas › vínculo com fazendas (`vinc-faz`); Cadastros › Fazendas ›
  detalhe › Estrutura de pós-colheita (`estr`).
- **Onde NÃO entra, por desenho:** **tela de apontamento em 3 passos**
  (regra 7) — é o caso da ÚNICA multi-seleção dos grãos, "Qual foi o
  problema?" no cartão do pivô (`igpb`): ficou de fora, e por isso a
  atividade grãos não recebeu o componente em lugar nenhum (o script
  prova a ausência: dois problemas escolhidos, zero contêiner na tela).
  🐂 Pecuária não tem multi-seleção (cada campo escolhe um valor).
  Também fora: seleção única (clima, status, água, destino, gravidade,
  nível, modo, passada, período, filtros da Diretoria, chips da
  pecuária); os dois toques independentes de "Na lavoura hoje" (florada /
  requeima — não são uma seleção, são dois sim/não); as operações por
  talhão de grãos (`data-opgrao`: cada toque cria um registro, que já
  vira linha compacta); nenhum `<select>` nativo foi trocado por chip
  ("Talhão afetado" das pragas fica para outra entrega).
- **Isolamento:** só o café recebe o componente na tela do gerente (os
  dois blocos da irrigação por gotejo, que são formulário, não seção de
  lançamento); regressão main × branch: **formulário de grãos e de
  pecuária byte a byte iguais ao main**; no café, só o `.sel-box` (vazio
  nos problemas; "2 setores selecionados" a partir do passo da
  irrigação). Pós-colheita, Diretoria e Cadastros iguais (fora rodapé
  v73→v74 e relógio).
- Sem campo novo, sem SQL, sem texto prescritivo, **apontamento em 3
  passos intocado** (nenhuma etapa, ordem, comportamento ou elemento
  novo). Medição nova em `scripts/checar-poluicao.cjs`, grupo "12. Chips
  removíveis" (27 ✅, incluindo a prova de ausência nos grãos).

## Decisão e confirmação (v72) — diálogo único, validação silenciosa, verbo no botão
Regra permanente em CLAUDE.md, item c10; checagem em
docs/definicao-de-pronto.md, item 13. Três ideias do app Sigma
(Fundação ABC): o diálogo Não/Sim que resolve um planejamento num
toque, o "Prosseguir" cinza até existir ponto marcado e "Fazer Upload"
em vez de "OK".
- **Problema resolvido:** o app tinha 11 `confirm()`, 22 `alert()` e
  14 `prompt()` nativos (caixa cinza do sistema, botão "OK", fora do
  visual do app), mais dois padrões próprios de confirmação (a caixa
  "Antes de enviar, confira" com "Confirmar e enviar" verde e o
  `cadConfirmar` inline de Cadastros com "Confirmar" verde). Metade dos
  nativos estava em tratadores mortos desde os Cadastros da v56.
- **Diálogo binário — componente único `perguntar({pergunta, sim, nao,
  destaque, detalhes})`** (Promise, `role="alertdialog"`, dois botões,
  nenhum campo, Escape cancela, toque fora não decide). Pontos (20
  confirmações, contagem igual à de antes — 11 nativas + 9 inline):
  Descartar rascunho · Esquecer código (Sair) · cinto de segurança do
  envio (Revisar · Enviar boletim / Salvar correção, avisos como
  detalhes) · Abrir ciclos depois de plantio lançado (grãos; ÚNICA com
  destaque: reversível em Cadastros › Ciclos e caminho provável claro;
  uma pergunta para todos os talhões do dia) · Encerrar ciclos com 100 %
  colhido (grãos; uma pergunta, sem destaque) · Inativar unidade ·
  Encerrar apelido · Publicar versão (Unidades e Plano) · Remover
  talhão / pivô / termo / máquina / insumo · Encerrar colheita · Criar
  unidade irmã · Unificar unidades · Apagar exemplos · Gerar novo código
  (Cadastros, Zona de cuidado — antes inline, agora o mesmo diálogo).
  Todas as perguntas terminam em "?", dizem o que vai acontecer e não
  citam produto, dose ou custo.
- **Validação silenciosa — `botaoAvanco(id, {rotulo, falta, classe,
  attrs})` + `atualizarAvanco(id, falta)`:** Enviar boletim / Salvar
  correção (três atividades; falta "Registre o clima ou uma observação
  do dia"; `salvarRascunho` atualiza no lugar), Enviar registro do dia
  (pós-colheita; "Registre terreiro, secador, tulha ou benefício do
  dia"; `salvarRascPos`), Publicar como vigente (auditoria ✔ e nome do
  agrônomo — antes `disabled` nativo sem explicação), 1 · Ler o arquivo e
  3 · Importar N linhas (arquivo/colar; coluna obrigatória e data),
  Registrar plantio (cultura por chip) e Gerar código combinado (chips)
  em Cadastros. Mesmo visual do `.acao-off` da v71 (cinza neutro, borda
  tracejada, `aria-disabled`); o toque mostra `data-falta` por 2,5 s;
  guarda o id porque o estado muda com a digitação.
- **Aviso depois do toque — `avisoInline(ancora, texto)`** para o que a
  pessoa não enxerga antes: boletim/registro já existente naquela data,
  arquivo sem linhas, Excel ilegível ou sem internet, área inválida ou
  sem fonte, apelido vazio, erro do Supabase em Unidades e Plano, "1, 2
  ou 3" do novo plantio. Uma linha `.aviso` acima do botão; some no
  próximo redesenho.
- **Rótulos com verbo:** "Confirmar e enviar" → "Enviar boletim" /
  "Salvar correção"; "Confirmar" (×10 em Cadastros) → verbo da ação;
  "Criar" → "Criar máquina" / "Criar insumo"; "Acrescentar" →
  "Acrescentar termo"; "Salvar" → "Salvar unidade" / "Salvar talhão" /
  "Salvar pivô". Nenhum "OK", "Sim", "Confirmar" sobrou.
- **Textos do cinto de segurança reescritos:** "Esqueceu a mão de
  obra?" → "Confira a mão de obra."; "Confirma que o dia foi assim?" →
  "Confira se o dia foi assim."; o aviso de aplicação sem receita
  deixou de citar produto, dose e custo ("sem receita preenchida. Sem
  ela não dá para rastrear a aplicação.").
- **Removido (código morto, sem elemento que o acionasse):** tratadores
  `data-novo-cod`, `bt-combo-gerar`, `bt-sync-salvar`, `data-enc-ciclo`
  e `cadastroClique` (add/rm de cadastro por `prompt`), todos
  substituídos pelos Cadastros da v56.
- **Fica como pendência (fora desta entrega):** 4 `prompt()` — "✔
  Confirmar recebimento" da carga de café (quantas carretas; observação
  se diferente) e "🌱 Novo plantio" na tela do gerente de grãos (cultura
  1/2/3 e data). São campos de digitação dentro de diálogo nativo;
  trocar por chips/campos na tela é mudança de fluxo, a decidir com o
  Nilo. O envio do boletim NÃO é bloqueado por seção eventual sem
  resposta (v70 continua com o aviso âmbar).

## Carteira de relatórios: ver docs/relatorios.md
Desde a v54 o app aponta para ela: em Escritório › Cadastros › Sobre
(só ADMIN; na v54 era um cartão da tela única) "Carteira de relatórios" abre `relatorios.html`, página
nova do site (fora do index.html e do cache do sw.js) que lê
`docs/relatorios.md` e os prompts da pasta `docs/relatorios/` e mostra
um botão "copiar prompt" por relatório. Precisa de internet; nada é
copiado para dentro do app. Telas de gerente, pós-colheita e Diretoria
idênticas à v53 (prova em scripts/regressao_render.cjs).
A lista oficial dos 24 relatórios do Grupo LGS (nível, o que responde,
fonte, cadência, dono e status EXISTE / PRONTO / AGUARDA) está em
`docs/relatorios.md`. Os prompts salvos para o Cowork, um por relatório
PRONTO, ficam em `docs/relatorios/nn-nome.md` (cabeçalho de papel da
Controladoria + URLs REST do Supabase que o Nilo abre no Safari e
cola). A vistoria de segunda (`docs/vistoria-semanal.md`) confere
quais relatórios da semana rodaram. Nada disso muda o app; os
relatórios só leem as tabelas. Aviso: os prompts 04 (plano) e 21
(matriz de acesso) dependem de tabelas ainda não criadas (sql/005-007
e sql/001-002, listadas nas PENDÊNCIAS).

## Nomenclatura do café na palavra da lavoura (v76)
Revisão feita com o Nilo: o termo do app passou a ser o que o
funcionário fala, e a dizer COMO o serviço foi feito (manual ×
mecanizado × químico) — é isso que muda custo e planejamento. Vale para
as atividades por talhão e, onde faz sentido como serviço de gente, para
as funções de mão de obra. Catálogo completo em
docs/catalogos-por-atividade.md, seção CAFÉ.

**Onde os termos novos aparecem:** lista de atividades por talhão do
boletim, funções de mão de obra, Cadastros › Catálogos › Café, filtro de
atividade do painel da Diretoria, folha "📋 Amanhã" e faixa do plano,
resumo do WhatsApp, exportação CSV e badge de categoria.

**Agrupamento (o que evitou a listona).** A lista passou de 20 para 27
termos, então o passo O QUÊ virou 4 grupos por natureza, RECOLHIDOS:
Tratos culturais (18) · Irrigação e fertirrigação (4) · Colheita e
pós-colheita (3) · Estrutura e apoio (2, com "Outra"). O componente é o
`seletorOperacao` que os grãos já usavam desde a v58 — mesma função,
mesmo visual, catálogo diferente (CLAUDE.md, c14). O cartão de atividade
do café virou cascata de verdade: ONDE (talhão) → O QUÊ (grupos) →
DETALHES. Nada aparece antes do toque anterior; nenhum grupo nasce
aberto (cartão de 369 px a 390 px, com os 4 grupos fechados).

**Categorias do badge (c6).** A "proposta pendente de aprovação" da v67
para o café caiu: a categoria do café É o grupo do catálogo, ligada por
`fase` como em grãos e pecuária. Letras: T · I · C · E.

**De-para (`DEPARA_NOMES`) — a regra central.** Nenhum boletim já
lançado foi tocado. O registro fica no banco com a palavra do dia; quem
traduz é a leitura, pela função única `nomeAtual(nome)`, aplicada em
exibição, soma, comparação com o plano, filtro do painel, chave de
"última receita" e classificação do badge. De-para vigente:

| termo antigo | termo de hoje | onde |
| --- | --- | --- |
| Desbrota | Desbrota manual | atividade e função |
| Poda / esqueletamento | Poda mecanizada esqueletamento | atividade |
| Poda (decote/esqueletamento) | Poda mecanizada esqueletamento | função |
| Roçada costal | Capina mecânica com roçadeira | função |
| Aplicação de herbicida (costal) | Capina química manual | função |
| Aplicação de defensivo (costal) | Pulverização manual | função |

**Termos legados (`TERMOS_LEGADO.CAFE`) — esperando o Nilo.** Quatro
termos antigos se abriram em DOIS novos cada, e o app não adivinha qual
foi: "Pulverização", "Aplicação de herbicida", "Capina roçadeira /
trincha" e "Irrigação". Eles saíram da escolha de lançamento novo,
continuam legíveis e continuam somando com o nome gravado; o app guarda
a NATUREZA de cada um (a mesma nos dois candidatos), então badge e somas
por natureza não se perdem. Decisão pendente — ver PENDÊNCIAS.

**Espelho no Supabase:** `sql/049-nomenclatura-cafe.sql` (o Nilo roda uma
vez no SQL Editor) acrescenta as operações novas em `operacao_catalogo`
com o grupo na coluna `fase`, põe o nome antigo como apelido em
`operacao_alias` e desativa (`ativo = false`, sem apagar) as duas
operações renomeadas 1 para 1. O mesmo seed está recolado no `sql/040`,
e o `sql/046` (categorias, opcional) foi regerado: café 4/26.

**Provas rodadas nesta entrega** (sem rede, 390 px): boletim antigo
semeado com "Desbrota" e "Roçada costal" continua na tela — mostrando
"Desbrota manual" e "Capina mecânica com roçadeira" — enquanto o dado
bruto no armazenamento segue `["Desbrota","Pulverização"]`; plano
gravado com o nome antigo fecha como "feito" com registro no nome novo, e
o contrário também; regressão main × branch com grãos e pecuária
idênticos (só o relógio do envio difere).

## "Assumir" no lugar de "comprometer" (v81)
Troca de vocabulário pedida pelo Nilo em 10/09/2026, depois de perguntar o que o
botão "comprometer" fazia. Se o dono do app precisou perguntar, o escritório
também precisaria. Nada de comportamento mudou — só a palavra.
- **Botão:** `comprometer` → **`assumir`** (nas duas telas: Semana › Sugestões e
  o ritual da sexta).
- **Cabeçalho da semana:** "1 COMPROMISSO(S)" → "1 TAREFA ASSUMIDA" (plural
  correto: "3 TAREFAS ASSUMIDAS").
- **Título do grupo:** "Parte A · compromissos da semana" → "Parte A · tarefas
  assumidas nesta semana".
- **Vazios:** "Nenhum compromisso marcado ainda…" → "Nenhuma tarefa assumida
  ainda. Toque em «assumir» nas sugestões abaixo."; "Nenhum compromisso na semana
  que passou." → "Nenhuma tarefa assumida na semana que passou."
- **Menu da área:** "N comprometida(s)" → "N assumida(s)".
- **Histórico:** "comprometida na semana" → "assumida na semana". Como
  `planHistTexto` monta o texto na LEITURA a partir de `h.campo`, **o registro
  antigo também passa a ler "assumida"** — nada gravado foi reescrito (regra da
  v76, item 2).
- **A chave `campo:"compromisso"` NÃO mudou** em `D.tarefaHistorico`: é chave
  substituta, nunca aparece na tela, e trocá-la apagaria o sentido do histórico já
  gravado.
- **O placar continua "cumprimos X de Y"** — não usa a palavra e é o que dá sentido
  ao botão: Y é quantas tarefas foram assumidas na semana.
- Provas: `teste_planejamento` 64 ✅ · 0 ❌ (nenhuma prova dependia da palavra);
  `checar-poluicao` 589 ✅ · 41 ❌, os mesmos herdados; `teste_nomenclatura` tudo
  certo. Medido na tela: cabeçalho "1 TAREFA ASSUMIDA", grupo "Parte A · tarefas
  assumidas nesta semana", os dois botões "assumir", histórico "assumida na semana".

## Filtros de Planejamento sem rolagem lateral (v80)
Correção pedida pelo Nilo em 10/09/2026: em Planejamento › Todas as tarefas, as seis
opções de SITUAÇÃO ("A iniciar", "Em execução", "Finalizado", "Aguardando terceiro",
"Aguardando clima", "Cancelado") ficavam depois da borda direita e só apareciam
arrastando a fileira para o lado. Regra permanente em CLAUDE.md, item c15.
- **A fileira quebra em linhas** (`.cad-saltos` com `flex-wrap`), nunca rola de lado —
  a mesma razão pela qual a rolagem lateral já era proibida nos chips removíveis da
  v74. Vale também para os saltos de Cadastros, que usam a mesma classe.
- **Só quebrar não bastava:** com tudo aberto os filtros passaram a ocupar 634 px e a
  1ª tarefa só começava a 788 px — abaixo da dobra. Por isso o painel **nasce fechado**
  (`planBarraFiltros`, P5) e abre num toque.
- **Filtro ligado nunca fica invisível:** com o painel fechado, a linha mostra
  "Filtrar · N", nomeia o que está ligado ("Em execução") e traz "limpar".
- **Quatro grupos com rótulo:** Prazo (os 4 faróis) · Situação (as 6) · Unidade ·
  Origem. Fileira com mais de 8 chips mostra os primeiros e um "＋N" que abre o resto
  no lugar; a fileira do filtro escolhido abre sozinha.
- **Medido a 390 px:** fechado, a 1ª tarefa começa a **193 px** (era 590 px com as
  fileiras que rolavam); aberto, **22 chips visíveis, zero escondidos, nenhuma fileira
  rolando**; página em 390 px.
- **Cadastros tinha o mesmo defeito, pior.** A classe `.cad-saltos` também serve os
  atalhos por fazenda de Cadastros (`cadSaltos`): em Fazendas e unidades, **18 dos 21
  chips estavam fora da tela**, alcançáveis só arrastando. Agora quebram em linhas,
  com teto `CAD_SALTOS_MAX = 4` + "＋N"; o atalho escolhido entra sempre entre os
  visíveis. Medido: de 50 px com 18 escondidos para 142 px com **zero escondidos**.
  A expansão volta a fechar ao trocar de tela (`cadLimpar`).
- **Cobertura das provas:** a regressão compara HTML, então ela não enxerga mudança
  só de CSS — a fileira de Cadastros foi conferida por medição direta no navegador
  (chips, escondidos, rolagem e altura), nas duas versões.

## Layout do trio e do cartão de tarefa (v79)
Correção de layout pedida pelo Nilo em 10/09/2026, a partir da tela real do
iPhone dele. Nenhuma regra de negócio mudou: os números, o casamento com o
boletim e os status são exatamente os da v78.

- **Os três rótulos saíam de linha.** `.plan-tres > span` usava
  `justify-content:center`; quando o valor do meio quebrava em duas linhas
  ("nenhum lançamento"), o rótulo dele subia e os outros dois desciam —
  **10 px de desalinhamento**, medidos a 390 px. Agora o rótulo ancora no topo
  (`flex-start`): medido de novo, os três em `y = 0`.
- **Sem meta, o trio virou uma linha.** "Planejado" e "restante" não existem
  quando a ata não trouxe a área: eram duas colunas de travessão, e sobrava um
  terço da largura para "nenhum lançamento", que quebrava em duas linhas
  sublinhadas. Agora é `.plan-um` — rótulo ao lado do valor, uma linha. Com
  meta o trio continua igual à v78 (é a forma certa para três números curtos).
- **O alvo de toque do "executado" tinha 26 px.** Os 44 px eram do contêiner,
  não do botão. Agora o botão ocupa a linha inteira na forma de uma linha e, no
  trio, é esticado a 44 px por pseudo-elemento — sem crescer a coluna (mesma
  técnica do × dos chips da v74 e do badge da v67).
- **Farol e "⋯" ancorados no topo do cartão.** O `.cad-item` de Cadastros
  centraliza, e num cartão de várias linhas os dois flutuavam no meio.
- **"96 ha" saía com um vão de dígito no meio** (na monoespaçada o espaço tem
  largura de número): `word-spacing:-.2em` só no par número+unidade do trio.
- **Medido, main × branch, a 390 px:** rótulos de `[10, 0, 10]` para
  `[0, 0, 0]`; três cartões sem meta de 548 px para 530 px; página em 390 px
  (nunca rola de lado). `teste_planejamento.cjs` **64 ✅ · 0 ❌**;
  `checar-poluicao.cjs` **589 ✅ · 41 ❌**, os MESMOS 41 herdados;
  `teste_nomenclatura.cjs` tudo certo; regressão `regressao_render.cjs`
  main × branch: café, grãos, pecuária e pós-colheita **idênticos** (só o
  relógio do envio), Diretoria e Cadastros só no `v78`→`v79` do rodapé.
- **Selo "Powered by Netlify":** continua injetado pelo Netlify, fora do
  código (ver a pendência própria). Não dá para tratar por CSS nosso; desliga-se
  em Netlify › projeto › Project configuration › General.

## Módulo de planejamento (v77) — reunião mensal + semana

A MESMA tarefa vista em dois horizontes. Concluir num horizonte atualiza o
outro: não existe cópia. Componentes ÚNICOS nas três atividades; o que muda
por atividade é o catálogo de sinônimos, nunca a tela. Regra permanente em
CLAUDE.md, item c15; catálogo em docs/catalogos-por-atividade.md,
"Planejamento — reunião mensal e semana (v77)"; checagem em
docs/definicao-de-pronto.md, item 18.

### O que alimenta
- **📅 Rodada mensal.** Toda reunião administrativa (por volta do dia 10)
  vira uma rodada. A ata entra por COLAGEM em Planejamento › Importar ata:
  o app lê os blocos por fazenda ("2.1 – Vereda"), cada linha iniciada por
  "-" vira uma tarefa, e mostra PRÉ-VISUALIZAÇÃO EDITÁVEL item a item antes
  de gravar. Reimportar a mesma ata não duplica (rodada + unidade +
  descrição normalizada).
- **🗓️ Semana.** A tela "Semana DD/MM a DD/MM" nasce sozinha (e a da semana
  seguinte nasce na sexta). Parte A: comprometer tarefas do mensal, com
  sugestões automáticas (prazo ≤ 7 dias, atrasadas e recém-destravadas).
  Parte B: "＋ tarefa da semana". Na sexta seguinte a tela mostra o
  comparativo da semana que passou — comprometido × concluído × travado —
  com o placar "cumprimos X de Y".
- **Revisão das arrastadas.** Toda rodada nova começa por ela: o que ficou
  aberto na rodada anterior chega marcado "arrastada (N reuniões)" para
  MANTER · REPACTUAR (novo prazo com motivo) · CANCELAR (com motivo).

### Status, farol e o motor que roda sozinho
- Status: A INICIAR · EM EXECUÇÃO · FINALIZADO · AGUARDANDO TERCEIRO ·
  AGUARDANDO CLIMA · CANCELADO (com motivo). Cancelar é STATUS, nunca
  delete: nada se apaga e tudo fica em `D.tarefaHistorico` (quem, quando,
  de → para, motivo).
- Farol só para A INICIAR e EM EXECUÇÃO: 🟢 mais de 7 dias · 🟡 7 a 3 dias ·
  🔴 2 dias, hoje ou vencido (rótulo ATRASADO). Os dois "aguardando" e a
  tarefa sem prazo são ⏸️ cinza — **nunca vermelho para o campo**.
- `planMotor()` roda na abertura do app, a cada sincronização e ao entrar no
  módulo: recalcula farol, conta os dias de chuva de cada tarefa parada pelo
  tempo, tira da pausa sozinha a que já teve 2 dias seguidos sem clima
  impeditivo no boletim (o prazo passa a mostrar "ajustado +N dias de
  chuva", com o original preservado) e garante a semana corrente.
- **Projeção de ritmo** nas tarefas com área: "feito 42 de 96 ha · no ritmo
  atual conclui em 30/09 (10 dias após o prazo)". O "feito" sai dos talhões
  já registrados no boletim para a operação casada com a descrição — nada
  digitado. Dias úteis = sem domingo e sem os dias de chuva declarados.
- **Alertas automáticos:** 7 dias (🟡), 2 dias (🔴), vencida, travada há mais
  de 7 dias (cobrança), destravada (volta ao radar do gerente) e arrastada
  há 2+ reuniões (alerta da Diretoria). **Linha do tempo** do mês por
  unidade mostra a semana congestionada ("6 tarefas vencendo em 30/09").

### Tela do gerente
Faixa "📋 Tarefas da reunião" no topo da casa e do boletim, no máximo 3
linhas, ordem 🔴 → 🟡 → ⏸️ → 🟢, com "＋N tarefas"; tudo em dia vira uma linha
("📋 Tarefas em dia · próxima vence 25/09"). Sem tarefa aberta na unidade,
NADA aparece. O toque abre a folha com ações de UM TOQUE — Comecei · Concluí ·
Travado (chips: falta insumo · falta peça · falta gente · falta máquina ·
chuva · outro) · "💬 Falar com o Nilo" (uma linha pronta). Zero campo de
digitação, zero diálogo, e nada bloqueia o boletim. O gerente vê só a
unidade dele.

### Planejado × executado × restante (v78, forma revista na v79)
Na folha do gerente e nas listas da área Planejamento — componente ÚNICO
`planTrio`. **Duas formas, decididas pelo dado (v79):** com meta, os TRÊS
números em três colunas iguais e a barra; sem meta, UMA linha
("executado · nenhum lançamento"), porque "planejado" e "restante" não
existem — três colunas em que duas são travessão é andaime vazio. Ver
"Layout do trio e do cartão de tarefa (v79)" abaixo.
- **Planejado** é a meta: a área que a ata trouxe (`t.area`) ou a que o
  escritório informar pelo chip "Definir meta" (`t.meta`). **Sem meta não há
  barra nem restante:** o app conta os lançamentos casados e diz que falta a
  área — nunca inventa denominador.
- **Executado** é a soma da área dos talhões DISTINTOS com lançamento casado
  (o mesmo talhão lançado duas vezes conta uma vez), na janela da tarefa: do
  começo dela até hoje, ou até o dia em que foi concluída — depois disso o
  número congela.
- **Restante** é planejado − executado. `planProgresso` arredonda ANTES de
  subtrair, então os três SEMPRE fecham na tela.
- **Rastreabilidade total:** um toque em "executado" abre, no lugar, a lista
  dos lançamentos que o compuseram — data, local, área e quem lançou —, com o
  cabeçalho "N lançamentos em M locais · P pessoas-dia · de dd/mm a dd/mm".
- **O lançamento diz o que abateu:** registro do boletim que casa com uma
  tarefa leva a etiqueta "📋 abate: …" no boletim em edição e no enviado, nas
  três atividades. É etiqueta de leitura, nunca botão.
- Na faixa do gerente o placar entra na mesma linha visual: "42 de 96 ha ·
  vence 20/09".

### Executado fora do plano (v78) — a outra metade da história
Planejamento › **🧾 Executado fora do plano**: por unidade, no mês corrente, os
lançamentos do boletim que NÃO casaram com nenhuma tarefa da ata, agrupados por
operação (quantos, em quantos locais, quantos ha, último dia), com % dos
lançamentos e pessoas-dia. A tela diz, em letras: **não é cobrança** — é o que
apareceu no dia e não estava planejado, e serve para a ata do mês que vem.
Também sai em texto pronto ("📲 copiar para a próxima ata").

### Fechamento mensal por unidade (v78)
Na rodada, no Mês por unidade, no cartão do painel e no texto de copiar:
**% do plano executado em ÁREA** (ha executados de ha planejados), **% do
esforço fora do plano** (lançamentos fora / lançamentos do mês) e as **tarefas
sem NENHUM lançamento casado** — ausência de REGISTRO, nunca "não fez".
No Supabase, o relatório `ata_x_executado` ganhou `area_planejada`,
`area_executada`, `pct_area` e `tarefas_sem_lancamento`, lidos da foto que o
app grava em `planejamento_tarefa.payload.exec` ({ha, n, meta, em}) — o de-para
descrição → operação mora no app, então quem calcula é ele. O "% fora do plano"
fica só no app, pelo mesmo motivo (documentado em docs/relatorios.md).

### Vínculo com o boletim (o app sugere, nunca conclui)
Quando a descrição casa com uma operação do catálogo e o registro entra no
boletim do dia, a casa do gerente mostra "Você lançou levantar café hoje —
concluir a tarefa?" com dois chips: "Concluí" e "ainda não" (some pelo resto
do dia). Tarefa de estrutura (caixa d'água, piscinão, talude, adutora…)
nunca recebe sugestão: status só manual.

### Área Planejamento (Diretoria/Escritório)
Item de PRIMEIRO NÍVEL, ao lado do Painel — na porta de entrada e por botão
no painel; nunca dentro de Cadastros. Dois toques até qualquer função. Usa
as classes de Cadastros (P10). Cabeçalho permanente: "Setembro · 62%
concluído · 5 atrasadas · 3 travadas · próxima cobrança: Cooxupé". Telas:
🗓️ Semana · 📅 Mês por unidade (barra, contagem 🔴🟡⏸️✅, atrasadas e linha do
tempo) · 📥 Rodadas (e o fechamento do mês por unidade) · 🔗 Pendências com
terceiros (por fornecedor, desde quando, quantas fazendas paradas) ·
📌 Arrastadas · 🗒️ Assuntos e investimentos · 🔎 Todas as tarefas (busca +
filtros de status, farol, unidade e origem) · 📲 Textos prontos. "＋ tarefa"
fixo no rodapé (4 campos: unidade, descrição, prazo, área; o resto em "Mais
opções"). Nas listas, o "⋯" abre a ação rápida NO LUGAR: Comecei · Concluí ·
Travado · Novo prazo (chips +7 · +15 · fim do mês · próxima reunião).

### Interface que não deixa esquecer
- **Pastilhas na porta de entrada**, tocáveis; nenhuma aparece sem
  pendência. Admin/Diretoria: "🔴 N tarefas atrasadas" · "📌 N travadas há +7
  dias" · "🗓️ Planejamento da semana pendente" · "📅 Rodada de <mês> não
  importada" (do dia 10 em diante). Gerente: "📋 N tarefas vencendo esta
  semana".
- **Rituais que se abrem sozinhos:** na sexta, a porta da Diretoria/
  Escritório é "Fechar a semana e planejar a próxima" (esquerda: o
  comprometido, com Concluí/Travado em um toque; direita: as sugestões da
  semana nova). Do dia 10 em diante, "Importar a ata da reunião", com atalho
  para a revisão das arrastadas. Pulável com um toque — e o "pulado" vale só
  para a sessão, então volta no próximo acesso do MESMO dia.
- **Notificações** (só se o navegador permitir): oferecidas UMA vez, sem
  insistir (linha discreta no painel). Sexta 7h "Planejamento da semana";
  dia 10, 7h "Ata da reunião"; diária 6h ao gerente com tarefa vencendo em 2
  dias ou atrasada. **Limitação conhecida:** o app não tem servidor de push
  — os avisos disparam quando o app é aberto a partir da hora marcada (uma
  vez por aviso por dia, por aparelho). Aviso garantido no horário exige
  push server, que é tarefa própria (PENDÊNCIAS).

### Saídas prontas, sem ferramenta externa (botão copiar)
Pauta da sexta por fazenda (vencidas · vencendo em 7 dias · travadas e por
quem) · Cobrança por fornecedor ("Cooxupé: KCl pendente para Rio
Preto-Lagamar — Café desde 10/09 — 1 fazenda parada.") · Fechamento mensal
por unidade · **Rascunho da próxima ata**, já no formato do texto da reunião
("2.1 – Fazenda" + "- item … – PRAZO: DD/MM/AA").

### Painel e relatórios
Painel da Diretoria: cartão "📋 Planejamento do mês" (cumprimento por
unidade, atrasadas, travadas, arrastadas; lista UNIDADES, nunca pessoas) e
o botão "📋 Planejamento". Resumo do WhatsApp: o farol das tarefas entra na
PRIMEIRA linha do boletim ("· tarefas 🔴 1 🟡 2 ⏸️ 1"). Relatório mensal
`ata_x_executado` em `relatorios_gerados` (sql/051) — na vitrine de
Relatórios como "Ata × executado (planejamento do mês) — mês"; detalhe em
docs/relatorios.md.

### Dados e sincronização
`D.rodadas`, `D.semanas`, `D.tarefas`, `D.tarefaHistorico` e `D.deparaAta`
no aparelho; no Supabase, `planejamento_rodada`, `planejamento_semana` e
`planejamento_tarefa` + a visão `vw_planejamento_mes` (sql/050). A fila de
sincronização ganhou os tipos `tar`, `rod` e `sem`, no mesmo molde dos
boletins (offline first, envia e baixa por id). O histórico de cada tarefa
viaja dentro de `payload.historico` e volta para a coleção do app.
De-para da ata em `DEPARA_ATA_PADRAO`, editável em **Cadastros › De-para da
ata**; "FMC Igrejinha" e "FMC Lazaro" viraram áreas de Monte Carmelo — Café
(talhões `t057` e `t058`, área a confirmar); Marimbondo, Cristo Redentor e
Córrego Grande (Dr. Adilson) ficaram marcadas fora do escopo — ignoradas
sempre, sem perguntar.

**Provas rodadas na v78** (sem rede, 390 px, relógio fixo):
`node scripts/teste_planejamento.cjs` → **64 ✅ · 0 ❌** (as 48 da v77 mais 16
do reforço: os três números fechando com a meta, o executado como soma dos
talhões distintos, a rastreabilidade com data/talhão/área/autor, a foto que o
Supabase lê, a meta informada pelo escritório ligando a barra, o lançamento
fora do plano, o que casa não entrando nele, o texto para a próxima ata, o
fechamento com % de área, % fora do plano e tarefas sem lançamento, o trio na
tela com barra, o toque abrindo a rastreabilidade, o placar na faixa, o trio na
folha do gerente sem nenhum campo e a etiqueta 📋 no boletim enviado);
`scripts/checar-poluicao.cjs` → **589 ✅ · 41 ❌**, os MESMOS 41 ❌ herdados
(nenhum novo), com 7 itens novos no grupo "14. Planejamento".

**Provas rodadas na v77** (sem rede, 390 px, relógio fixo):
`node scripts/teste_planejamento.cjs` → **48 ✅ · 0 ❌** (o texto real da ata
da reunião de 10/09/26, a semana, o fechamento automático, a projeção dos 96
ha, o alerta de travada, os quatro textos prontos, a faixa do gerente a 360
px, o gerente sem acesso a outra unidade, a sexta abrindo o ritual e a
pastilha do dia 11); `scripts/checar-poluicao.cjs` → **575 ✅ · 41 ❌**, os
MESMOS 41 ❌ herdados da v58 (nenhum novo), com o grupo novo "14.
Planejamento" (10 itens ✅) e 16 telas do módulo medidas com as regras de
Cadastros; regressão main × v77 com as telas do gerente e do pós-colheita
IDÊNTICAS nas três atividades (só o localStorage difere, pelas coleções
novas).

## Módulo de insumos (v86) — da mensagem do grupo ao saldo da fazenda

**O problema real.** A entrega de fertilizante é anunciada numa mensagem do
WhatsApp ("Relação de NITRATO que a Cooxupé vai entregar nas fazendas:
106.000 kg - VEREDA…") e depois ninguém sabe o que chegou, quanto foi
aplicado e quanto sobrou. Várias tarefas do planejamento (v77) ficam paradas
"aguardando insumo" sem que o escritório saiba que o insumo já chegou.

### O que o app faz agora
1. **A mensagem vira dado em menos de um minuto.** Em "📥 Colar do WhatsApp"
   (primeiro nível na Diretoria/Admin, atalho no topo de Planejamento e em
   Cadastros › Insumos) a pessoa cola o texto; o app diz o que entendeu,
   mostra a pré-visualização com os totais de conferência ("8 fazendas ·
   486.000 kg · 486 t") e só grava depois do toque em "Importar".
2. **O gerente confirma a chegada com UM toque.** Enquanto houver remessa
   programada e não recebida, o topo do boletim traz "📦 Nitrato de amônio —
   106 t programado (Cooxupé) · chegou?" com "✅ Chegou tudo" · "➗ Chegou
   parte" · "❌ Ainda não chegou". Nº da nota e foto vêm depois e são
   puláveis. Nada bloqueia o boletim; respondida a chegada, o cartão some.
3. **O saldo é calculado, nunca digitado:** recebido − aplicado. O aplicado
   sai dos lançamentos que o gerente já faz; um toque nele abre a lista dos
   lançamentos que o compuseram. A seção "📦 Insumos na fazenda" nasce
   fechada no boletim das três atividades.
4. **Chegou o insumo, o planejamento anda sozinho:** tarefa em AGUARDANDO
   TERCEIRO cujo bloqueio cite o produto ou o fornecedor volta a A INICIAR,
   com aviso ao gerente e registro no histórico.
5. **O escritório vê o que falta e cobra:** cartão "📦 Insumos" no painel
   (recolhido), com programado × recebido × aplicado × saldo por unidade,
   filtro por produto, "🔗 A cobrar do fornecedor" (com os dias de espera, as
   fazendas paradas e o texto pronto para copiar) e "⚠️ Divergências".

### Onde mora o dado
| coleção | o que guarda | sincronização |
| --- | --- | --- |
| `D.insumos` | catálogo de produtos (nome, unidade, **categoria**, **fornecedor**) | junto com os dados do aparelho |
| `D.remessasInsumo` | a remessa programada, com as alocações por unidade | fila offline → `insumo_remessa` (sql/054) |
| `D.recebimentos` | uma chegada confirmada (quantidade, data, nota, foto, quem conferiu) | fila offline → `insumo_recebimento` (sql/054) |
| `D.mensagensImportadas` | o texto integral de cada colagem, com o que criou | fila offline → `mensagens_importadas` (sql/055) |
| `D.deparaProdutos` | apelido do grupo → produto do cadastro (aprendizado) | junto com os dados do aparelho |
| `D.deparaAta` | nome da mensagem → unidade (a MESMA tabela do planejamento, ampliada) | junto com os dados do aparelho |

**Não existe `D.produtos`.** O catálogo de produtos já existia como
`D.insumos` (Cadastros › Insumos, agora item de primeiro nível do menu, com
as remessas por baixo); criar uma segunda lista faria o app ter dois nomes
para a mesma coisa. A tarefa pedia `D.produtos`: a decisão de reaproveitar
está registrada aqui e no resumo do PR.

### O que NÃO vira quilos, de propósito
A calda do café ("receita") é texto livre; saca e lata não têm equivalência
declarada em kg; dose em litro só conta para produto cuja base é litro. O app
não estima nada — e a seção diz de onde vem cada número. Por isso o café
ganhou três campos OPCIONAIS (produto, dose kg/ha, área) apenas nas operações
de adubação e correção de solo (`INS_OPS_CONSUMO`): sem eles, não havia como
saber quanto saiu do estoque sem digitar o consumo duas vezes.

### Provas
`node scripts/teste_insumos.cjs` — **54 ✅ · 0 ❌**, sem rede, a 390 px, com a
mensagem real do nitrato: 8 alocações casadas pelo de-para e 486.000 kg;
formatos alternativos ("106.000kg – VEREDA", "106 t - VEREDA", "VEREDA -
106.000 kg", decimal com vírgula); reimportação sem duplicar; chegada na
Vereda em um toque liberando a tarefa "Fazer KCL e ferti"; parcial de 20 t na
Mata Preta com 24 t a receber; adubação de 400 kg/ha em 10 ha virando 4.000 kg
aplicados e saldo de 102.000 kg; cobrança da Cooxupé com as tarefas paradas;
classificação dos quatro tipos e o texto sem relação que o app NÃO adivinha.
`scripts/checar-poluicao.cjs`: **637 ✅ · 42 ❌** — os mesmos 42 ❌ da v85,
nenhum novo, com 49 itens novos (grupo "15. Insumos" e 6 telas medidas).
`scripts/regressao_render.cjs` contra `origin/main`: no boletim das três
atividades só mudam o `datalist` de produtos (elemento invisível) e, no café,
o bloco opcional "INSUMO APLICADO"; o painel e o pós-colheita ficam idênticos
sem nenhuma remessa importada.

### Limitação conhecida (item 11.6 da tarefa)
**Compartilhar direto do WhatsApp não foi implementado.** O Web Share Target
só existe em PWA no Android/Chrome; o iPhone — o aparelho do Nilo e dos
gerentes — não o suporta. Declarar o `share_target` no manifesto deixaria no
código um caminho que ninguém aqui consegue usar, então ficou só a colagem
manual. Se um dia o grupo passar a usar Android, é uma entrada no manifesto
mais o tratamento do parâmetro na abertura do app.

## Aparelho sem unidade aberta no monitor de chegada (v84)
Fecha o diagnóstico de 11/09/2026. O Nilo confirmou: o código era
`ADMIN-9561` (o `AMNIN` da mensagem anterior foi erro de digitação dele) —
os gerentes **entraram** no app.

**Caminho medido em navegador real, dos dois jeitos:**

| código | toques até abrir o boletim | decisões pelo caminho |
|---|---|---|
| `ADMIN-9561` | **4** | 8 opções (Café · Grãos · Pecuária · Terreiro · Diretoria · Relatórios · Planejamento · Escritório), depois 10 fazendas de café |
| `VR-7061` (da unidade) | **2** | nenhuma — cai direto em "Vereda Romaria › Café (164,90 ha)" |

**O envio funciona pelo caminho do Administrador** — testado de ponta a
ponta com o Supabase simulado respondendo 200: escolher Café → a fazenda →
Preencher → clima → responder as duas seções eventuais → Enviar produz
`POST /rest/v1/boletins` com `fazenda_id: f23` correto, e a tela mostra
"✅ Boletim de hoje enviado às HH:MM — o escritório já recebeu". Nenhum
erro de página. Ou seja: o app **não** estava barrando ninguém; a porta de
entrada é que não era a do gerente — em vez da fazenda dele, uma tela de
administrador que o treinamento não cobriu.

**O furo que isso revelou no monitor da v82.** Com o código de
Administrador o app abre na tela de escolher atividade, `sessao.fazendaId`
é `null` e o carimbo de `aparelho_sync` sobe **sem unidade** — foi o que o
teste mostrou (`unidade_id=null, chave=ADMIN`). O cartão "📡 Chegada dos
boletins hoje" lista uma linha por unidade, então esse aparelho não cabia
em linha nenhuma e **sumia**: o escritório veria "nada recebido" e nenhum
aparelho, exatamente igual a um celular que nunca foi aberto. Justamente na
situação em que o Nilo está.

**Correção:** o cartão ganhou um rodapé com os aparelhos que sincronizaram
sem unidade aberta — quantos são, há quanto tempo cada um falou com o
banco, em que versão, com que código e quantos registros na fila, e a frase
que explica o que aquilo quer dizer: *"O celular falou com o banco, mas
parou antes de escolher a unidade. Com o código da própria fazenda o app
abre direto no boletim dela."* Máximo 6 linhas + "e mais N". Sem aparelho
solto, o cartão fica **byte a byte igual ao da v83**.

### Provas
- `scripts/checar-poluicao.cjs`: **589 ✅ · 43 ❌** na v84 e na v83
  (`origin/main`), medidos na mesma hora — o diff do relatório inteiro é a
  linha da versão. Nenhum ❌ novo.
- `scripts/regressao_render.cjs` contra `origin/main`: café, grãos,
  pecuária e pós-colheita **idênticos em tudo**; o painel da
  Diretoria/ADMIN muda **uma linha em branco** (sem aparelho solto o bloco
  novo não desenha nada).
- Teste do monitor com 5 aparelhos semeados (2 com unidade, 3 no código de
  Administrador sem unidade): as duas linhas por unidade continuam, e os
  três soltos aparecem no rodapé com hora, versão, código e fila.
- Teste de envio ponta a ponta pelo caminho do Administrador (acima).
- `node scripts/teste_planejamento.cjs` (64 ✅ · 0 ❌) verde.

## Código errado no aparelho do gerente (v83)
Continuação direta do diagnóstico de 11/09/2026. Depois da v82, o Nilo
informou o dado que faltava: **os ~15 gerentes estavam todos com o código
`AMNIN-9561`**. Medido em navegador real (390 × 844, sem rede):

| código digitado | onde o aparelho para |
|---|---|
| `AMNIN-9561` | **não entra** — "Código inválido", tela de código |
| `ADMIN-9561` | entra na tela do **Administrador**, com 8 opções (Café, Grãos, Pecuária, Terreiro, Diretoria, Relatórios, Planejamento, Escritório) e nenhuma delas é a fazenda dele |
| `VR-7061` (código da unidade) | cai **direto** na casa da unidade: "Vereda Romaria › Café (164,90 ha) · Boletim de hoje pendente" |

`escopoDoCodigo` exige igualdade exata depois de normalizar (maiúsculas,
sem espaço, traço opcional): `AMNIN-9561` não é `ADMIN-9561`, logo seria
recusado. **Resolvido na mesma tarefa:** o `AMNIN` foi erro de digitação na
mensagem — o código em uso era `ADMIN-9561`, e os gerentes entraram. O que
os parou foi a porta do administrador, não a fechadura (medição na seção
da v84, acima).

A correção é operacional: **cada gerente usa o código da própria unidade**
(`CODIGOS_PADRAO`, um por fazenda), que abre direto o boletim dela em 2
toques, contra 4 e duas decisões pelo caminho do administrador.

**O que a v83 mudou no app** (nada disso substitui a troca dos códigos —
só faz o app dizer o que está acontecendo):
1. **"Código inválido" virou uma frase com saída.** Era um ponto final que
   não dizia o que fazer. Agora: *"Este código não foi reconhecido. Confira
   as letras e os 4 números e tente de novo. Se não entrar, peça ao
   escritório o código da sua fazenda — cada unidade tem o seu, e ele abre
   direto o boletim dela."* Sem revelar código nenhum.
2. ~~`avisoEscopoAmplo()` na porta de entrada~~ — **retirado na v85**, por
   decisão do Nilo. O aviso dizia ao aparelho no código de Administrador
   que ele abre todas as fazendas e que o gerente devia pedir o código da
   unidade dele. Só que quem via o texto todos os dias era justamente o
   administrador, que já sabe: o gerente com o código da própria unidade
   nunca passa por aquela tela, e o gerente no código de Administrador não
   é quem resolve o problema — quem resolve é o escritório. Com o aviso
   fora, a porta de entrada voltou a ter 1.301 px (eram 1.471 px). Fica a
   regra: **aviso só na tela de quem pode agir sobre ele**; aviso permanente
   na porta de quem já conhece a situação é ruído, e ruído diário treina a
   pessoa a não ler. A informação continua existindo onde serve — no item 3
   abaixo.
3. **O monitor de chegada (v82) mostra o código do aparelho** — é hoje o
   único lugar que relata "este aparelho está no código errado", e está na
   tela de quem age:
   "aparelho sincronizou há 12 min · v83 · código Administrador · 0 na
   fila". É assim que o escritório vê, sem perguntar a ninguém, que um
   aparelho de campo está no código errado. Depende de rodar o sql/052.

### Provas
- `scripts/checar-poluicao.cjs`: **589 ✅ · 43 ❌** na v83 e **589 ✅ ·
  43 ❌** na v82 (`origin/main`), medidos na mesma hora — o diff do
  relatório inteiro é a linha do número da versão. Nenhum ❌ novo.
  (A contagem oscila com a hora do dia: cenários que dependem do relógio —
  farol de "espera" depois das 17 h, ritual do dia 10 — mudam de resultado.
  A medição da v82 registrada acima, 586 ✅ · 43 + 3 ❌, foi feita às 02:10;
  esta, às 10:00. O que vale para a regra "a lista de ❌ só encolhe" é
  comparar as duas versões na MESMA hora, que é o que este diff faz.)
- `scripts/regressao_render.cjs` contra `origin/main`: café, grãos,
  pecuária e pós-colheita **idênticos em tudo**; Diretoria e ADMIN mudam só
  o `00-inicio` (a Diretoria, só o número da versão; o ADMIN, o aviso novo).
- Teste em navegador dos quatro códigos (`AMNIN-9561`, `ADMIN-9561`,
  `VR-7061`, `DIRETORIA-8034`), que produziu a tabela acima.
- `node scripts/teste_planejamento.cjs` (64 ✅ · 0 ❌) e
  `node scripts/teste_nomenclatura.cjs` verdes.

## Indicador de envio e monitor de chegada (v82)
Nasceu do diagnóstico de 11/09/2026 (primeiro dia de preenchimento dos
gerentes; nenhum boletim deles chegou ao banco).

**O que o banco mostrava naquele dia** (consulta REST com a chave
publishable, tabela por tabela): 12 boletins no total, os dois mais
recentes de 10/09 (Mata Preta — Café e Monte Carmelo — Café, o
treinamento do Nilo); **zero** registros com data de 11/09 em `boletins`,
`pos_colheitas`, `remessas`, `boletim_pecuaria` e `telemetria`. Ou seja:
nada foi enviado — não era leitura escondendo registro.

**O que foi descartado com prova:**
- **Rejeição do banco (RLS, campo obrigatório, id de unidade):** um POST
  anônimo com a chave publishable, exatamente como o app faz
  (`on_conflict=fazenda_id,data`), respondeu **HTTP 201** em `boletins`,
  `pos_colheitas` e `telemetria`. O banco estava recebendo.
- **Leitura filtrando demais:** o escopo ADMIN cai em `e.tudo`, então
  `syncBaixar` monta a URL **sem** `fazenda_id=in.(…)`, com `limit=2000`.
  Nada é escondido do aparelho do Nilo.
- **Versão presa no celular:** o `sw.js` é *network-first* (tenta a
  internet primeiro, cache só como reserva), então aparelho com sinal
  sempre pega a versão nova.

**O defeito real, que era do app:** até a v81 a casa do gerente escrevia
"Boletim de hoje enviado · Enviado às HH:MM" assim que o boletim era
gravado no APARELHO. O envio ao banco vinha depois, pela fila, e o erro
de rede era engolido (`catch(e){ resto.push(item) }`) sem nenhum aviso —
a prova está na regressão: num Chromium **sem rede nenhuma**, a v81
mostrava "✅ Boletim enviado!". O único sinal da fila era uma linha
discreta abaixo de quatro cartões, sem botão de tentar de novo. E não
havia nada, em lugar nenhum, que dissesse se o aparelho de um gerente
tinha ao menos conversado com o banco.

### a) Indicador de envio (gerente e pós-colheita, três atividades)
Componente ÚNICO `faixaEnvio(fz, {t, rotulo})`, estático (nunca sticky —
orçamento de altura de c5/c11), logo abaixo da régua de 7 dias na casa e
no topo do formulário do boletim. Quatro estados, todos lidos da FILA, não
da gravação local:
- `✅ Boletim de hoje enviado às HH:MM — o escritório já recebeu.`
- `⏳ Enviando…` (tentativa no ar; não assusta com "sem internet" no
  segundo do envio).
- `⏳ Aguardando internet (N boletins na fila)` + botão **🔄 Tentar enviar
  agora**.
- `⏳ Aguardando envio (N …)` + `O banco respondeu <código> e não gravou.
  Nada se perdeu — está guardado neste aparelho. Avise o escritório.`
Some quando não há nada a dizer. `t` é chave substituta ("b" boletim /
"p" pós-colheita) e o vocabulário ("boletim" / "registro") vem de quem
chama, como na régua (c11) — nunca `if(atividade==="…")`.

Junto: `syncEnviar` guarda o recibo do banco no próprio registro
(`reg.sincEm`, gravado só quando o POST responde ok) e o código HTTP da
recusa no item da fila (`item.http`, `item.tent`); os títulos "Boletim de
hoje enviado" e "✅ Boletim enviado!" passaram a dizer "guardado no
aparelho" enquanto o registro estiver na fila; `syncTudo` redesenha a casa
do gerente/pós quando a fila muda de tamanho (o FORMULÁRIO nunca é
redesenhado, para não tirar o foco de quem digita); e voltar ao app
(`visibilitychange`) virou a terceira chance de esvaziar a fila, junto do
evento `online` e da abertura do app, que já existiam.

### b) Monitor de chegada (Diretoria / ADMIN)
`cartaoChegadaBoletins()` no painel, acima do farol de 7 dias, nasce
RECOLHIDO (P5) com o resumo "3 de 24 · 21 sem nada recebido". Aberto, uma
linha por unidade: `recebido HH:MM` (hora em que a linha entrou no banco —
coluna `atualizado`, agora baixada junto do payload como `recebidoEm`) ou
`nada recebido`, e embaixo, quando existir, `aparelho sincronizou há N min
· v82 · N na fila`. Relata RECEBIMENTO, nunca trabalho: "nada recebido" é
ausência de registro; proibidos "não fez", "pendente", "atrasado" (c2).
Nenhuma pessoa aparece — as linhas são de UNIDADES.

O carimbo por aparelho vem da tabela nova `aparelho_sync`
(**sql/052-aparelho-sync.sql**, pendente de rodar): id aleatório do
aparelho, unidade aberta, escopo do código, versão do app, quantos
registros esperam na fila e a hora. Não guarda nome, telefone, localização
nem nada digitado. A gravação vai **direto, fora da fila offline**, de
propósito: se fosse pela fila, tabela inexistente devolveria 404 e o item
ficaria preso para sempre acusando "aguardando internet" — que é
exatamente o que acontece hoje com `codigos_acesso` (sql/001 nunca
rodado). Sem a tabela, o carimbo falha em silêncio e o cartão mostra só a
hora de chegada do boletim.

### Provas
- `scripts/checar-poluicao.cjs`: **586 ✅ · 46 ❌**, os mesmos 46 ❌ da
  v81 — nenhum ❌ novo. O painel da Diretoria foi de 4 para 4,15 telas
  (por isso o cartão nasce recolhido).
- `scripts/regressao_render.cjs` contra `origin/main`: as únicas telas que
  mudaram são a casa depois de enviar (café, grãos, pecuária e
  pós-colheita) e o painel da Diretoria/ADMIN. Todo o resto ficou idêntico,
  inclusive o boletim em 3 passos. O cenário do pós-colheita ganhou o passo
  `30-enviado`, que o script ainda não alcançava.
- Com o Supabase mockado respondendo 200, a casa troca sozinha para
  "✅ Boletim de hoje enviado às HH:MM" — e o POST de `aparelho_sync` sai
  com `{unidade_id, chave, versao, na_fila, visto_em}`.
- `node scripts/teste_nomenclatura.cjs` e `node scripts/teste_planejamento.cjs`
  (64 ✅ · 0 ❌) seguem verdes.

### O que ficou por confirmar com os gerentes
O app não tem como distinguir, sozinho, "o gerente não preencheu" de
"preencheu e ficou na fila" — é justamente o que a v82 passa a mostrar.
Uma hipótese permanece aberta e só o Nilo responde: **se ele gerou códigos
novos em Cadastros para o treinamento**, esses códigos NÃO chegaram aos
celulares dos gerentes (a tabela `codigos_acesso` não existe no banco,
sql/001 nunca rodado), e nesse caso os gerentes nem conseguiram entrar no
app. As perguntas objetivas estão no resumo do PR.

## Telas × padrões de tela (checagem de poluição — desde 05/09/2026)
Os PADRÕES DE TELA viraram lei da casa no CLAUDE.md (a: boletim em 3
passos; b: P1–P10 dos cadastros; c: nada de uma atividade na tela de
outra; d: DEFINIÇÃO DE PRONTO). A medição é de
`scripts/checar-poluicao.cjs` (sem rede, 390 × 844 px). Medição vigente,
v86, 11/09/2026: **637 ✅ · 42 ❌** — os mesmos 42 ❌ da v85, nenhum novo. A
v86 acrescentou o grupo "15. Insumos" (13 itens ✅: a porta única com uma tela
e um campo; o botão de avanço inativo dizendo a próxima ação; a classificação
automática com troca de tipo por chips; totais de conferência na
pré-visualização; nome não casado pedindo a unidade em vez de adivinhar; o
cartão de chegada como único elemento novo sempre visível, com três respostas,
alvo de 46 px, um toque que grava no lugar sem modal nem nativo e o
desaparecimento depois da resposta; a seção de saldo nascendo fechada; o
cartão "📦 Insumos" do painel recolhido e com a cobrança por fornecedor; e
zero termo de cobrança em todas essas telas) e 6 telas novas medidas com as
MESMAS regras de Cadastros (Colar do WhatsApp — colar, conferir a remessa,
mensagens importadas, mensagem; Cadastros › Insumos e remessas; Cadastros ›
Insumos › Remessas programadas), mais o boletim do gerente com chegada
pendente. Medição anterior registrada aqui,
v82, 11/09/2026: **586 ✅ · 46 ❌** — os mesmos 46 ❌ da v81, nenhum novo
(a v82 acrescentou o cartão "📡 Chegada dos boletins hoje", recolhido, e a
faixa de estado do envio, que reusa `.aviso`; o painel foi de 4 para 4,15
telas). Medição anterior registrada aqui, v78, 10/09/2026:
**589 ✅ · 41 ❌** — os mesmos 41 ❌ da v58;
a v78 acrescentou 7 itens ao grupo "14. Planejamento" (três números com barra
na tarefa; toque em "executado" abrindo a rastreabilidade no lugar, com alvo de
44 px, sem modal e sem nativo; cada linha da rastreabilidade com data, local,
autor e área; o lançamento sem tarefa casada aparecendo em "executado fora do
plano" por unidade; a tela do fora do plano sem termo de cobrança e com o aviso
de que não é cobrança; a folha do gerente com os três números e a
rastreabilidade ainda sem NENHUM campo de digitação; e a etiqueta "📋 abate:"
no boletim enviado, como etiqueta e não como botão) e uma tela nova
("Planejamento › Executado fora do plano", medida com as regras de Cadastros).
Nenhum ❌ novo.
a v77 acrescentou o grupo "14. Planejamento" (10 itens ✅: o "⋯" abre a ação
rápida no lugar, sem tela nova e sem modal; um toque muda o status com alvo
de 44 px e zero diálogo nativo; travada por chuva e por terceiro em ⏸️,
nunca vermelho; nenhuma pastilha sem pendência; faixa do gerente com 3
linhas a 360 px, uma linha visual cada, ordem 🔴 → 🟡 → ⏸️ → 🟢, sem termo de
cobrança, e a folha sem nenhum campo de digitação) e 16 telas novas medidas
com as MESMAS regras de Cadastros (usam as classes `cad-*`). Nenhum ❌ novo:
as listas longas do módulo (fechamento da rodada, revisão das arrastadas,
conferir a ata) nasceram com busca; as duas linhas ❌ de P10 em "Diretoria" e
"Cadastros / Escritório" listam alguns exemplos a mais, todos de classes já
existentes (`.cartao`, `.btn`, `.chip`). A v76 não mexeu na contagem: a v76 não mexeu na contagem:
a única linha que mudou de texto é a do "＋ Adicionar atividade" do café,
que caiu de "2 seletores, 5 campos, 2 chips, 7 rótulos" para "1 seletor,
0 campos, 0 chips, 1 rótulo" — o mesmo retrato do "＋ operação" dos
grãos, e continua ❌ só porque o ONDE ainda é `<select>` (item herdado,
igual nas três atividades, que sai numa tarefa própria: zerá-lo aqui
mexeria em grãos, que esta tarefa tinha de deixar intacto). A v75
acrescentou o grupo
"13. Plano do dia" (93 itens ✅: um cenário por atividade — sem plano nada
aparece; com plano de hoje semeado, faixa de 3 linhas no topo do boletim,
cada item em UMA linha visual a 360 px (faixa de 154,3 px = 18,3 %), "0 de
3 ✅" que vira "1 de 3 ✅" no lugar quando o registro entra, folha
"Amanhã" com "Pular" · "Salvar plano" e zero régua/chip removível/ação de
perfil/botão de avanço/badge/`input type=date`, 3 passos revelados um a um
(ONDE 9/14/11 chips e zero campo → O QUÊ → 1 campo), plano de hoje fechado
dentro do boletim com status calculado, plano de amanhã guardado, zero
termo de outra atividade; a variante do dia de chuva no café não pergunta
motivo e grava "clima"; o cartão da Diretoria ordena por desvios
evitáveis, separa clima de evitável, nomeia o recorte no vazio e não mostra
nome de pessoa). Nenhum ❌ novo: as duas linhas ❌ de P10 em "Diretoria"
listam um exemplo a mais (o `.cartao` novo, do CSS-base); a faixa reusa
`.aviso` e a folha reusa `.folha`/`.chip`, todas classes já existentes.
A v74 acrescentou o grupo
"12. Chips removíveis" (27 itens ✅: café — problemas da irrigação 2 de 8
e setores fertirrigados 8 de 8 → 6 + "+2"; Cadastros › Códigos › novo
combinado — 9 unidades → 6 + "+3"; grãos prova a AUSÊNCIA no cartão do
pivô (dois problemas escolhidos, zero contêiner) e
pecuária registra "sem multi-seleção"; em cada um: vazio sem área,
contador + chips, × de 44 px com "Remover <nome>", quebra sem rolar de
lado, corpo inerte, × remove sem nativo e sem sair da tela, remover o
último volta ao vazio; nenhum ❌ novo — nenhum `.sel-*` aparece em raio,
sombra ou toque); a v73 acrescentou o grupo
"11. Régua de 7 dias" (24 itens ✅ na casa do gerente das três
atividades e na casa do pós-colheita, que passou a ser medida como tela
"Gerente (casa)": 7 células de 48,3 × 48 px sem rolar de lado, dias em
pt-BR do mais recente à esquerda, zero dia futuro, hoje selecionado e
marcado, toque em ontem sem nativo e sem sair da tela, vazio "Sem
boletim registrado em … em dd/mm/aaaa.", conjunto 148,4 px = 17,6 %,
zero `input type=date`; as duas linhas ❌ de P10 em "Gerente (casa)"
listam mais exemplos por causa da casa do pós, todos do CSS-base —
nenhum da régua, que tem raio 0 e sombra nenhuma); a v72 acrescentou o grupo
"10. Decisão e confirmação" (30 itens ✅: stub de alert/confirm/prompt
em toda página com zero chamadas nos cenários; Enviar inativo no
formulário vazio das três atividades e do pós-colheita, toque explica
sem alert e sem sair da tela, clima/terreiro ativa o mesmo elemento;
Descartar abre o diálogo único com dois botões, sem campo, pergunta com
"?", verbo de até três palavras e sem destaque; Cancelar mantém a tela)
e passou a contar no grupo 9 só o botão de perfil (`.acao-off[data-papel]`);
a v71 acrescentou o grupo
"9. Ação desabilitada por perfil" (28 itens ✅, medidos no painel da
Diretoria, no boletim enviado visto pela Diretoria e pelo gerente das
três atividades — com um boletim de exemplo semeado — e a contagem zero
na tela de apontamento) e passou a medir o boletim enviado do gerente
como tela do grupo "Gerente (casa)"; a linha de botões do painel ganhou
`flex-wrap` para não rolar de lado com 4 botões; a v69 acrescentou o par de
chips de resposta explícita de ausência nas seis seções eventuais — o
script passou a tratar `[data-resp-secao]` como parte do estado compacto
da seção (docs/definicao-de-pronto.md, item 11), e o resultado ficou
idêntico ao da v68; a v68 acrescentou a medição
da tela Relatórios com dois textos do robô-redator semeados (um longo,
um curto) e o grupo "8. Texto longo em lista" com 13 itens, todos ✅,
mais os itens de renderização/altura da tela semeada (1,6 telas, 390 px
de largura); a v67 acrescentou o badge de
categoria (span de 20 px, sem raio, sem sombra, fora da lista de alvos de
toque medidos; área de toque de 44 px por pseudo-elemento) nas linhas de
Faróis › unidade — medido com as linhas de exemplo das três atividades,
resultado idêntico ao da v66; a v66 trocou a barra das
telas de leitura pelo cabeçalho contextual (mesmos botões, mesma
posição sticky, uma faixa de 19 px a mais só no topo da página):
resultado idêntico ao da v65; a v60 acrescentou as duas
telas de faróis, todas ✅; a v61 só trocou textos de vazio e acrescentou
os estados carregando/erro em Relatórios e Faróis, sem campo, chip ou
seção nova; a v62 acrescentou um texto secundário "ritmo: a cada N dias"
em Faróis › unidade, medido com linhas de exemplo de ritmo: 1 tela, ✅;
a v63 acrescentou a linha de origem "Dados do iCrop de hoje, 04:05" nos
cartões iCrop/Solinftec de grãos e pecuária e o bloco "Estado dos robôs"
em Integrações e robôs — medidos com dado de integração e status de
exemplo semeados no script: casa de grãos/pecuária 1,0 tela, Integrações
1,2 telas, termos de outra atividade zero, ✅; a v64 estendeu a linha ao
café e aos cartões de ontem do painel, com semente também na casa de café
e no painel — 221 ✅ · 41 ❌ de novo, casa de café 1,0 tela, painel 3,2
telas com busca; a v65 pôs as unidades de café nos Faróis e mede a tela
de uma unidade de café com linhas de exemplo: 6 itens novos, todos ✅ —
227 ✅ · 41 ❌; a lista de Faróis passou de 14 para 24 unidades, 2,2
telas com busca). Esta lista é o retrato dos ❌ herdados: cada tarefa
que tocar numa tela ❌ deve zerá-la; **nenhum ❌ novo entra**. Quem
mudar o resultado atualiza esta seção no mesmo PR.

### Boletim do gerente (padrão a)
Colunas: fechada por padrão · ao abrir só lista + ＋ · 3 passos após ＋
(ONDE em chips, um passo por vez) · termos de outra atividade.
- ☕ Café (f23) — telas casa e boletim ✅ (1,1 telas, tudo fechado);
  termos de grãos/pecuária ✅ zero.
  - Clima · Irrigação (gotejo) · Observações: formulários, não são de
    lançamento — fechados ✅.
  - Mão de obra: fechada ✅ · ao abrir ❌ (5 totais com ＋/− visíveis
    antes do "＋ função") · "＋ função" ❌ (seletor + 3 campos de uma vez).
  - Atividades por talhão: fechada ✅ · ao abrir ✅ · "＋" ❌ parcial
    (v76: só o ONDE aparece — progressivo ✓ —, mas em seletor, não
    chips; O QUÊ por natureza em grupos recolhidos ✓; DETALHES só depois
    da escolha ✓ — mesmo retrato do "＋ operação" dos grãos).
  - Colheita: fechada ✅ · ao abrir ✅ · "＋" ❌ (talhão em seletor, 8
    rótulos de uma vez).
  - Pragas, doenças e daninhas: fechada ✅ · ao abrir ✅ (v69: só o par
    "Nada a registrar hoje" · "Registrar ocorrência" + lista + ＋) · "＋"
    ❌ (tipo em chips ✓, mas talhão em seletor e tudo junto; ordem O QUÊ
    → ONDE).
  - Ocorrências gerais: fechada ✅ · ao abrir ✅ (v69: idem) · "＋" ❌
    (tipo em seletor + gravidade + texto + foto de uma vez).
- 🌾 Grãos (f33) — casa e boletim ✅ (1 tela, tudo fechado); termos de
  café/pecuária ✅ zero.
  - Mão de obra: idem café ❌ ❌.
  - Operações do dia: fechada ✅ · ao abrir ✅ · "＋ operação" ❌ parcial
    — só o ONDE aparece (progressivo ✓), mas em seletor, não chips; O
    QUÊ por fase em chips ✓; DETALHES só da operação ✓.
  - Irrigação (pivôs): fechada ✅ · ao abrir ❌ (além do "＋ pivô": botão
    "adicionar todos os pivôs" e link "cadastrar outro pivô") · "＋ pivô"
    ❌ (pivô em seletor; depois vira linha compacta ✓).
  - Pragas, doenças e ocorrências: fechada ✅ · ao abrir ✅ (v69: um par
    de chips para o cartão inteiro) · "＋" ❌ ❌ (mesmos cartões do café).
- 🐂 Pecuária (f26) — casa e boletim ✅ (1 tela, tudo fechado); termos
  de café/grãos ✅ zero.
  - Mão de obra: idem café ❌ ❌.
  - Seção 🐂 Pecuária: fechada ✅ · **acordeão dentro de acordeão ❌** (7
    sub-acordeões) · campo "Observações de pecuária" visível ao abrir.
    - Movimentação do rebanho: ao abrir ✅ (v69: par "Nada a registrar
      hoje" · "Registrar movimento") · "＋ movimento" ✅ (chips "O que
      houve" sozinhos; pasto vem depois, em seletor — ordem O QUÊ →
      ONDE, a ajustar quando a seção for tocada).
    - Sanidade: ao abrir ✅ (v69: par "Nada a registrar hoje" ·
      "Registrar tratamento") · "＋ animal tratado" ❌ (21 chips + 4
      campos de uma vez) · "＋ manejo em massa" ❌ (11 chips + 2 campos).
    - Reprodução · Pasto e estrutura: formulários, fechados ✅.
    - Cocho e nutrição: ao abrir ❌ (resumo rápido OK/Problema visível)
      · "＋ pasto" ❌ (pasto em seletor + 10 chips de uma vez).
    - Contagem por lote/pasto: ao abrir ✅ · "＋ lote" ❌ (seletor + 2
      campos).
    - Outros manejos: ao abrir ✅ · "＋ manejo" ❌ (2 seletores + 3
      campos).
  - Ocorrências e sanidade: ao abrir ✅ (v69: par de chips) · "＋" ❌
    (idem café).
- 🏭 Pós-colheita (f23): **4 seções abertas por padrão ❌**; Secador,
  Tulha e Benefício mostram um cartão com campos ao abrir ❌ ❌ ❌;
  "Enviar registro do dia" não é fixo no rodapé ❌; termos de
  grãos/pecuária ✅ zero.
- Botão principal do boletim (Enviar/Descartar) fixo no rodapé ✅ nas
  três atividades.

### Diretoria e Escritório (padrões b e c)
- Painel da Diretoria: renderiza ✅ · 3,2 telas de altura com a busca
  de boletins ✅ (referência; v71: 4 botões em duas linhas, 390 px sem
  rolar de lado ✅) · Relatórios 1 tela ✅ · Resumo do período
  1,2 telas ✅.
- Decisão e confirmação (v72, grupo 10): boletim de café, grãos e
  pecuária e registro do pós-colheita — Enviar inativo ao abrir (cinza,
  tracejado, aria-disabled) ✅ · toque mostra "Registre o clima ou uma
  observação do dia" / "Registre terreiro, secador, tulha ou benefício
  do dia" sem alert e sem sair da tela ✅ · ativa no mesmo elemento ao
  escolher o clima / digitar a lata ✅ · Descartar abre o diálogo com 2
  botões, 0 campos, "?" no fim, "Cancelar" · "Descartar rascunho", ambos
  neutros ✅ · zero nativos nos cenários ✅.
- Ação desabilitada por perfil (v71, grupo 9): painel da Diretoria
  ("⚙ Cadastros") e boletim enviado visto pela Diretoria ("✏️
  Corrigir") e pelo gerente de café, grãos e pecuária ("Marcar como
  visto") — aria-disabled e sem id/data ✅ · cinza neutro, tracejado,
  sem vermelho/ícone ✅ · toque mostra o papel sem modal/alert/troca de
  tela ✅ · texto "Ação do/da …" sem termo proibido ✅ · 1 de 4 botões
  ✅ · zero na tela de apontamento (três atividades) ✅.
- Diretoria › Relatórios com textos do redator (v68, medida com dois
  textos de exemplo, um longo e um curto): 13 itens do grupo "8. Texto
  longo em lista" ✅ — cartão colapsado de 3 linhas, cabe em menos de
  uma tela, "Números" visível sem rolar, copiar sem expandir e integral,
  corte por linha inteira, texto curto sem reticências, origem compacta,
  "todas para conferir", folha em tela cheia com cabeçalho e ação
  fixos, origem completa, padrão visual da folha, rolagem devolvida.
- Diretoria › Faróis de registro (v60, medida como Cadastros): lista 1,5
  telas com busca ✅ (14 unidades > 12 → busca) · nível 2 ✅ · cabeçalho
  fixo com voltar ✅ · blocos fechados ✅. Faróis › unidade: 1 tela ✅ ·
  só leitura ✅ · nível 3 ✅ · "Operações sem janela" fechado ✅ · v62:
  "ritmo: a cada N dias" como texto secundário, sem campo, chip ou seção
  nova, omitido sem intervalo ✅. v65: lista com 24 unidades (café no
  fim, "sem janela · N de M operações com registro"), 2,2 telas com
  busca ✅; Faróis › unidade (café): 1 tela ✅ · só leitura ✅ · nível 3 ✅
  · cabeçalho fixo ✅ · "Operações sem janela" fechado ✅.
- Cadastros (25 telas medidas: menu, 11 assuntos, detalhes e "novo"):
  P2 níveis ≤ 3 ✅ em todas · P3 altura ≤ 2 telas ou busca ✅ em todas
  (Talhões 2,0 telas com busca) · P3 lista > 12 com busca ✅ (Fazendas
  24, Talhões 103, Ciclos 30, Códigos 32, Catálogos 77/80/124,
  Máquinas 407 — todas com busca) · P4 cabeçalho fixo com voltar ✅ em
  todas · P4 ação principal fixa no rodapé ✅ em todas as telas com
  formulário; Lotes › detalhe, Plano › fazenda e Códigos › detalhe são
  só de leitura (ações na Zona de cuidado) ✅ · P5 "Mais opções"/"Zona
  de cuidado" fechados ✅ em todas.
- Escritório › Importar telemetria: formulário sem ação principal fixa
  no rodapé ❌ ("1 · Ler o arquivo" dentro do cartão).
- Diretoria › painel › cartão "📋 Planejado × Executado" (v75, medido
  com três boletins de exemplo em duas unidades): P1 um propósito ✅ ·
  só leitura, sem campo ✅ · uma linha por unidade com plano, ordenada
  por desvios evitáveis ✅ · vazio pela função única nomeando o recorte
  ✅ · nenhum nome de pessoa ✅ · P10 ❌ herdado (usa `.cartao`, com raio
  e sombra do CSS-base).
- Boletim do gerente › faixa "📋 O plano de ontem para hoje" (v75, três
  atividades, medida com plano de hoje semeado): até 3 linhas, cada uma
  em UMA linha visual a 360 px ✅ · 154,3 px = 18,3 % da tela no caso
  comum e 202 px = 23,9 % no pior caso (observação de amanhã escrita +
  dia replanejado), abaixo do teto de ~25 % ✅ · zero
  campo de digitação ✅ · status ⚪→✅ trocado pelo app no lugar ✅ · zero
  termo de cobrança ✅ · P10 ❌ herdado (usa `.aviso`, raio 10 px do
  CSS-base).
- Folha "📋 Amanhã" (v75, três atividades + variante de dia de chuva):
  padrão a em 3 passos ✅ (ONDE só em chips, zero campo e zero seletor;
  O QUÊ só depois; DETALHES só depois; depois de adicionar volta ao
  compacto) · pulável com um toque, dois botões com verbo ✅ · nenhum
  nativo ✅ · zero régua, chip removível, ação de perfil, botão de
  avanço, badge e `input type=date` ✅ · termos de outra atividade ✅
  zero · P10 ❌ herdado (`.chip` é pílula de 24 px, `.btn.suave.mini`
  tem 40 px — o mesmo CSS-base de todas as telas).
- Colar do WhatsApp (v86, 4 telas medidas com as regras de Cadastros):
  colar a mensagem 1 tela ✅ · um campo só ✅ · botão de avanço inativo com
  a próxima ação ✅ · conferir a remessa 1,4 telas ✅ · mensagens importadas
  ✅ (busca a partir de 12) · mensagem (texto original) ✅ · níveis ≤ 3 ✅ ·
  cabeçalho fixo com voltar ✅ · ação principal fixa no rodapé ✅ · P10 ❌
  herdado (usa `.cartao`, `.btn` e `.chip` do CSS-base).
- Cadastros › Insumos e remessas (v86): 1 tela ✅ · busca a partir de 12
  produtos ✅ · estado na própria linha (categoria, unidade, fornecedor,
  saldo do grupo) ✅ · Remessas programadas em nível 3, com o detalhe
  abrindo NO LUGAR (sem quarto nível) ✅ · ação principal fixa no rodapé ✅.
- Boletim do gerente › cartão "📦 chegou?" (v86, três atividades, medido
  com remessa pendente semeada): único elemento novo sempre visível ✅ ·
  três respostas com alvo de 46 px ✅ · um toque grava no lugar, sem modal e
  sem nativo ✅ · some depois da resposta ✅ · nenhuma seção nasce aberta por
  causa dele ✅ · zero termo de cobrança ✅ · P10 ❌ herdado (`.cartao` e
  `.chip` do CSS-base).
- Boletim do gerente › seção "📦 Insumos na fazenda" (v86): nasce fechada
  ✅ · só leitura ✅ · recebido/aplicado/saldo com barra ✅ · toque no
  aplicado abre os lançamentos no lugar ✅ · zero termo de cobrança ✅.
- Diretoria › painel › cartão "📦 Insumos" (v86): nasce recolhido ✅ · uma
  linha por unidade, sem nome de pessoa ✅ · filtro por produto em chips que
  quebram em linhas (sem rolagem lateral) ✅ · cobrança por fornecedor com
  botão copiar ✅ · divergências sem termo de cobrança ✅ · P10 ❌ herdado.
- Escritório › Unidades e Plano: precisa de rede — fora da medição
  offline (conferir à mão quando for tocada).

### P10 — padrão visual (❌ em TODAS as telas: é o CSS-base do app)
Sem gradiente ✅ em tudo. Sombra ❌ (`.cartao` e `.btn` usam
`--sombra`), canto arredondado ❌ (`--raio:12px` em cartão, seção e
botão; 10 px em input/select; chips são pílula de 24 px), toque < 44 px
❌ (`.btn-topo` 40 px, `.btn.mini` 40 px, chips de salto 40 px, filtro
de fazenda do painel, "Sair" da entrada). Só as classes `cad-*` da v56
já cumprem o padrão. **Zerar isto é uma versão própria (troca do
CSS-base) e precisa de decisão do Nilo** — até lá, tela nova usa as
classes `cad-*` e não acrescenta raio/sombra/pílula novos.

## PENDÊNCIAS
- **Insumos (v86) — rodar três SQL no Supabase.** Na ordem:
  `sql/054-insumos.sql` (tabelas `insumo_remessa` e `insumo_recebimento` e a
  visão `vw_insumo_saldo`), `sql/055-mensagens-importadas.sql` (a trilha das
  colagens) e, por último, `sql/056-insumos-relatorio.sql` (a visão
  `vw_insumo_aplicado` e o relatório mensal
  `insumos_programado_recebido_aplicado`; exige o `sql/020` já rodado).
  Enquanto não rodarem, o módulo funciona INTEIRO no aparelho (é offline
  first) — só não sincroniza entre celulares e o relatório não aparece na
  vitrine. Como no planejamento da v77, uma remessa criada fica na fila até o
  SQL rodar (o aviso "N registro(s) aguardando internet" aparece; nada se
  perde).
- **Pergunta livre (Fase 3) deve incluir `mensagens_importadas` no
  contexto** — permite perguntas como "quando a Cooxupé prometeu o nitrato da
  Mata Preta e quanto chegou?". A tabela já guarda o texto integral de cada
  mensagem colada, quem colou, quando, o tipo e o que foi criado a partir
  dela (sql/055). Nada do motor de perguntas foi construído na v86.
- **Insumos (v86) — para o Nilo conferir/decidir:**
  1. **Sete dias para virar cobrança.** `INS_COBRANCA_DIAS` = 7: remessa
     programada e sem chegada registrada há mais de 7 dias entra na lista de
     cobrança por fornecedor. Trocar é uma linha.
  2. **20 % de diferença para o âmbar.** `INS_DIVERG_PCT` = 20: a
     pré-visualização compara kg/ha programado com a dose do plano do
     agrônomo (quando há plano vigente baixado) e sinaliza acima disso.
     Informativo, nunca bloqueante — e só nas telas do escritório.
  3. **Área da unidade manda no kg/ha.** O cálculo usa `areaUnidade` (soma
     dos talhões cadastrados, sem estrutura e sem arrendado). Unidade com
     talhão faltando no cadastro mostra kg/ha alto — vale conferir o cadastro
     antes de estranhar o número.
  4. **Três campos novos no boletim do café.** Produto, dose (kg/ha) e área
     aparecem SÓ nas operações de adubação e correção de solo e são
     opcionais. Sem eles, não há como abater do saldo sem digitar o consumo
     duas vezes. Se o pessoal não preencher, o saldo mostra o recebido e diz
     que não houve lançamento com dose — nunca inventa.
  5. **Saca e lata não viram kg.** Se o grupo passar a anunciar entrega em
     sacas, é preciso declarar a equivalência (kg por saca) no catálogo — o
     app não a adivinha.
- **Investigação da cadeia de estados (10/09/2026) —
  `docs/investigacao-cadeia-estados.md`.** Apuração de leitura (nada foi
  alterado no banco) sobre o que a Onda 2 precisa para a cadeia Recomendado →
  Planejado → Realizado → Saldo. Veredito: **viável parcialmente, com a maior
  parte já construída** — Planejado, Realizado, Saldo, confirmação em um toque
  e trilha de alteração já existem nas três atividades (v75/v77/v78). O que
  falta, em ordem: (1) rodar os SQL pendentes desta lista — enquanto o
  `sql/050` não rodar, o planejamento existe só no aparelho de quem digitou;
  (2) subir o cadastro de talhões para o Supabase, porque o "executado" em
  hectares sai da área do talhão, que hoje só existe no celular — dois
  aparelhos com cadastros diferentes mostram números diferentes para a mesma
  tarefa; (3) guardar o id da operação na tarefa, já que hoje o elo tarefa →
  lançamento é casamento de texto da descrição da ata e descrição reescrita
  deixa de somar em silêncio; (4) decidir se o plano do agrônomo (kg por setor
  de café) vira origem de tarefas ou continua só referência — são **dois planos
  que não se falam**. O relatório traz uma tabela com 13 lacunas e, na seção
  10, um **bloco SQL só de leitura** para o Nilo rodar (versão curta de 6
  linhas para o iPhone, versão completa de 46 para computador) — o resultado
  fecha o que ainda está marcado "não apurado".
- **Planejamento (v77) — rodar dois SQL no Supabase.** `sql/050-planejamento.sql`
  (tabelas `planejamento_rodada`, `planejamento_semana`, `planejamento_tarefa`
  e a visão `vw_planejamento_mes`) e, depois dele, `sql/051-ata-x-executado.sql`
  (relatório mensal). Enquanto não rodarem, o módulo funciona inteiro NO
  APARELHO (é offline first) — só não sincroniza entre celulares e o
  relatório não aparece na vitrine. Enquanto as tabelas não existirem, uma
  tarefa criada fica na fila de sincronização (o mesmo comportamento de
  qualquer registro sem rede: o aviso "N registro(s) aguardando internet"
  aparece até o SQL rodar, e aí tudo sobe sozinho — nada se perde).
- **Planejamento (v77) — notificação garantida no horário exige push
  server.** Hoje os avisos (sexta 7h, dia 10 7h, gerente 6h) usam a API
  `Notification` do navegador e disparam quando o app é aberto a partir da
  hora marcada, uma vez por aviso por dia, por aparelho. Push de verdade
  (chegar sem o app aberto) precisa de `PushManager` + chaves VAPID + um
  endpoint que empurre — tabela e serviço novos, tarefa própria. O iPhone
  ainda exige que o app esteja instalado na tela de início para aceitar
  notificação.
- **Planejado × executado (v78) — para o Nilo conferir/decidir:**
  1. **Meta das tarefas sem área.** A ata só traz área em algumas linhas. Sem
     meta não há barra nem restante (o app conta os lançamentos e diz isso).
     Onde fizer sentido, o escritório informa a meta pelo chip "Definir meta"
     na área Planejamento — vale a pena fazer isso nas tarefas grandes.
  2. **Esforço = lançamentos.** O "% fora do plano" usa lançamentos (talhão ×
     operação × dia) como denominador, e mostra pessoas-dia ao lado quando o
     boletim tem o número de pessoas. Se o Nilo preferir pessoas-dia como
     medida principal, é uma linha.
  3. **A janela da tarefa** começa em "Comecei" (ou na criação, quando o
     gerente não marcou) e termina em "Concluí". Lançamento de antes de a
     tarefa existir não conta — confirmar que é o desejado.
- **Planejamento (v77) — para o Nilo conferir/decidir:**
  1. **Área de Igrejinha e Lazaro.** As duas entraram como áreas de Monte
     Carmelo — Café com **0 ha** (a ata não diz a área). Preencher em
     Cadastros › Talhões quando souber — sem isso não há projeção de ritmo
     nessas áreas.
  2. **Dois dias de sol para destravar.** Tarefa parada por chuva volta
     sozinha depois de `PLAN_DIAS_SOL` = 2 dias seguidos sem clima
     impeditivo no boletim. Confirmar 2 (o texto da ata fala em "3 dias de
     sol" para voltar a levantar café — se o número certo for 3, é uma
     linha do catálogo).
  3. **Sete dias para virar cobrança.** Travada há mais de
     `PLAN_TRAVA_COBRANCA` = 7 dias vira alerta de cobrança do escritório.
  4. **"Falar com o Nilo"** abre o WhatsApp com UMA linha pronta e sem
     destinatário (o app não guarda telefone de ninguém). Se for para ir
     direto para um número, é uma decisão de cadastro — e de privacidade.
- **Nomenclatura do café (v76) — quatro decisões do Nilo.** Cada termo
  antigo abaixo virou DOIS termos novos, e o app não tem como saber qual
  foi. Enquanto a resposta não vem, o termo antigo continua reconhecido e
  somando com o nome que foi gravado (nada se perde), mas ele não é mais
  oferecido em lançamento novo — quem for lançar hoje já escolhe o termo
  específico. Respondida cada linha, é uma linha em `DEPARA_NOMES` e uma
  linha de apelido no Supabase:
  1. **"Pulverização"** (histórico) → Pulverização manual ou
     Pulverização mecanizada?
  2. **"Aplicação de herbicida"** → Capina química manual ou Capina
     química mecanizada?
  3. **"Capina roçadeira / trincha"** → Capina mecânica com trincha ou
     Capina mecânica com roçadeira?
  4. **"Irrigação"** → Irrigação manual ou Irrigação automática?
  Uma quinta pergunta, de catálogo e não de histórico: **"Adubação via
  lanço" e "Adubação orgânica" continuam na lista?** Elas ficaram
  (não conflitam com "Adubação manual" nem com "Adubação via
  fertirrigação"), mas se o pessoal não usa essas duas palavras no dia a
  dia, elas saem e viram de-para na mesma regra.
- **ONDE (talhão) ainda é `<select>` nas três atividades.** O passo O
  QUÊ virou chip agrupado no café (v76) e já era nos grãos; o ONDE
  continua em seletor nas três — é o ❌ herdado que sobra em "＋
  Adicionar atividade" e "＋ operação". Trocar por chips é tarefa
  própria, porque muda café, grãos e pecuária no mesmo componente.
- **MÓDULO DE PROGRAMAÇÃO/METAS — não existe no app (bloqueia parte da
  v75).** A tarefa da v75 tinha como pré-requisito um módulo de
  programação/metas do mês (metas por unidade, semáforo de metas, fonte
  declarada de dias impedidos F1..F5). Nada disso existe no repositório
  — não há tabela, catálogo, tela nem coluna de meta. O que foi entregue
  é o nível do gerente (plano do dia seguinte) e todas as correlações que
  se calculam sem meta. **Ficou de fora, por dependência:** (a) a
  pré-marcação automática das "atividades das metas em risco e os
  talhões pendentes delas" na folha "Amanhã" — no lugar dela, a sugestão
  vem do que o gerente marcou como "continua amanhã" no próprio boletim;
  (b) o cruzamento META × RITMO (quanto do avanço de cada meta veio de
  dia planejado × não planejado) e, no cartão da Diretoria, "quais metas
  atrasaram por motivo evitável vs clima"; (c) a faixa do plano não fica
  "junto ao semáforo de metas" (não há semáforo): fica no topo do
  boletim, que é onde o boletim abre. **Para o Nilo decidir:** se o
  módulo de metas vira tarefa própria (é o caminho recomendado — mexe em
  Diretoria/Escritório, tabela nova e versionamento) ou se as metas
  entram como leitura do plano de safra que já existe.
- **Plano do dia (v75) — parâmetro para o Nilo confirmar com o
  agrônomo:** o dia só é considerado "impedido pelo clima" quando o
  gerente declara "Chuva forte", "Granizo" ou "Geada", ou chuva ≥ 25 mm
  (`CLIMA_IMPEDITIVO` e `PLANO_CHUVA_MM`). O número muda quem entra em
  "desvio de clima" e quem entra em "evitável" nos números da Diretoria
  — confirmar 25 mm, e se "Geada" deve mesmo impedir o dia nas três
  atividades. Trocar é uma linha do catálogo.
- **Plano do dia (v75) — para o Nilo testar no iPhone:** numa unidade de
  cada atividade, (1) preencher e enviar um boletim: depois dos avisos,
  a tela "📋 Amanhã" — tocar em "Pular" (o boletim vai igual) e, no dia
  seguinte, repetir salvando 2 ou 3 linhas (ONDE → O QUÊ → pessoas);
  (2) no dia seguinte, ver a faixa no topo do boletim e lançar uma das
  operações planejadas: a caixinha vira ✅ na hora; (3) enviar com uma
  linha ⚪: a pergunta "O que atrapalhou hoje?" — responder e conferir a
  linha da casa ("📋 Plano de ontem: 2 de 3 ✅ · 1 não feito (…)"); (4)
  num dia de chuva forte, conferir que a pergunta NÃO aparece e o desvio
  sai como clima; (5) com código DIRETORIA, o cartão "📋 Planejado ×
  Executado" no painel. **Decisões que ficaram com o Nilo:** (a) o campo
  "Pendente / programado para amanhã" passou a se chamar "O que ficou
  pendente hoje", para não pedir o plano duas vezes — manter?; (b) a
  pergunta do motivo e o plano de amanhã ficaram na MESMA folha (uma tela
  só antes do envio, em vez de duas) — manter?; (c) o limite de 3 linhas
  por plano; (d) rodar `sql/048-plano-x-executado-diario.sql` no SQL
  Editor quando quiser o consolidado mensal na vitrine de Relatórios (sem
  ele o app funciona igual).
- **Chips removíveis (v74) — para o Nilo testar no iPhone:** café ›
  Irrigação › "Rodou com problema" › tocar 2 problemas (aparece "2
  problemas selecionados" + 2 chips com ×; o × tira na hora); "Sim, fez
  fertirrigação" › tocar todos os setores (6 chips + "+2"; "+2" mostra
  todos); ADMIN › Códigos › novo combinado › marcar 9 unidades (6 +
  "+3"); ADMIN › Catálogos › Máquinas › vínculo; ADMIN › Fazendas ›
  detalhe › Estrutura de pós-colheita. Com luva e sol: o × tem 44 px —
  se ainda for difícil, dá para separá-lo mais do rótulo. **Decisões que
  ficaram com o Nilo:** (a) o cartão do pivô (grãos) NÃO recebeu os
  chips, porque é tela de apontamento em 3 passos e a regra 7 não admite
  elemento novo ali — se ele quiser a contagem de problemas no pivô, é
  uma decisão dele e vira tarefa própria; (b) o corpo do chip não faz
  nada (só o × age) — manter?; (c) limite de 6 chips antes do "+K".
- **Régua de 7 dias (v73) — para o Nilo testar no iPhone:** na casa
  do gerente de uma unidade de cada atividade e na casa do
  pós-colheita: (1) a régua abaixo do cabeçalho, com sete dias, hoje à
  esquerda em verde; tocar em ontem e ver o cartão do dia mudar (boletim
  daquele dia ou "Sem boletim registrado em … em dd/mm/aaaa."), sem
  abrir teclado; (2) hoje continua com a barra embaixo quando outro dia
  está escolhido; (3) deixar o app aberto na virada do dia e voltar a
  ele: a régua deve mostrar o novo hoje; (4) com luva/sol: as células
  têm 48 px — se parecerem pequenas, a alternativa prevista é 5 dias
  (nunca rolagem). **Decisões que ficaram com o Nilo:** (a) a régua
  entrou só nas casas do gerente e do pós-colheita — entrar também no
  boletim enviado (trocar de dia sem voltar) é possível com o mesmo
  componente; (b) o painel e o Resumo do período da Diretoria continuam
  com os dois `input type=date` (de/até) que já existiam desde antes da
  v61 — são filtro de período, não escolha de dia, e não foram trocados
  nesta entrega; (c) os itens #37 (estados vazios, v61/v65) e #1/#2
  (cabeçalho contextual, v66) já estavam no main — a v73 só os auditou
  contra os critérios do lote e mediu de novo; os rótulos "Boletim de
  hoje pendente" / "Registro de hoje pendente" seguem como estavam,
  aguardando a decisão da v61.
- **Decisão e confirmação (v72) — para o Nilo:** (1) testar no iPhone,
  numa unidade de cada atividade: abrir o boletim vazio e tocar em
  "Enviar boletim" (cinza tracejado; aparece "Registre o clima ou uma
  observação do dia" por 2,5 s), escolher o clima e ver o botão ficar
  verde sem a tela piscar, tocar em "Descartar" e ver o diálogo com
  "Cancelar" · "Descartar rascunho" (os dois neutros), cancelar; no
  pós-colheita, o mesmo com "Enviar registro do dia"; (2) em grãos,
  lançar uma operação de plantio e enviar: a pergunta "Abrir o ciclo dos
  talhões plantados hoje…?" com "Abrir ciclos" em verde; (3) decidir
  sobre os 4 `prompt()` que ficaram (recebimento de carga; novo plantio
  na tela do gerente) e sobre as sugestões do PR (remover a pergunta de
  "Sair", juntar as perguntas de ciclo ao cinto de segurança do envio).
- **Resposta explícita de ausência (v69) — para o Nilo:** (1) rodar
  `sql/047-secao-resposta.sql` no SQL Editor (bloco único, passo a
  passo no cabeçalho; até lá a resposta já sobe dentro do payload e o
  bloco reprocessa os boletins antigos quando rodar); (2) testar no
  iPhone, uma unidade de cada atividade: cartão de Pragas/Ocorrências
  (café), Pragas e ocorrências (grãos), Movimentação/Sanidade/
  Ocorrências (pecuária) — "sem resposta" no cabeçalho, os dois chips ao abrir,
  toque em "Nada a registrar hoje" recolhe o cartão e o cabeçalho vira
  "sem ocorrência", 2º toque desfaz, "＋" apaga a resposta, rascunho
  sobrevive a fechar o app, Enviar com seção sem resposta abre a seção
  com o aviso âmbar e não envia; (3) [decidido em 08/09/2026: texto
  neutro "sem resposta" no lugar do "○" e envio exigindo resposta nas
  eventuais, v70]; (4) futuro: farol de completude por seção no painel (a visão
  `vw_completude_boletim` já existe; tela fora desta entrega) e ordem
  dos cartões (sugestão no PR).
- **Selo "Powered by Netlify" (v68) — decisão do Nilo, sem custo:** o
  selo que flutua sobre o rodapé é injetado pelo Netlify (não está no
  código nem se desliga por netlify.toml). Pela documentação do Netlify
  (changelog de 19/08/2026), ele aparece por padrão em projetos do
  plano Free criados a partir dessa data e pode ser desligado em
  qualquer plano, sem custo, em Netlify › projeto boletim-ncnaves ›
  Project configuration › General › "Powered by Netlify badge" (vale
  no próximo acesso, sem novo deploy). Cada visitante também pode
  escondê-lo só no próprio aparelho. Não mexer em plano.
- **Textos colapsados (v68) — para o Nilo testar no iPhone:** Diretoria
  › 📊 Relatórios: cada texto aparece com 3 linhas, "ler texto completo
  ›" e "copiar para WhatsApp" lado a lado; "Números" visível sem rolar;
  copiar sem abrir cola o texto inteiro; "ler" abre a folha, Fechar
  volta ao mesmo ponto da lista.
- **Badge de categoria (v67) — decisão do Nilo antes do merge:** aprovar
  (ou trocar) as 5 categorias e letras do café propostas em
  docs/catalogos-por-atividade.md (C Colheita · A Aplicação · T Trato
  cultural · M Monitoramento · I Irrigação e infraestrutura) e as letras
  de grãos (R Pré-plantio · D Condução · S Pós-colheita, porque P e C
  já são de Plantio e Colheita). Testar no iPhone: Diretoria › Faróis ›
  unidade (uma de cada atividade) e um boletim enviado — o quadradinho
  fica à esquerda do nome, na mesma linha; tocar nele mostra o nome da
  categoria e some sozinho. Só depois de aprovar, rodar o sql/046
  (opcional: espelho do catálogo no Supabase; o app não depende dele).
- **Cabeçalho contextual (v66) — para o Nilo testar no iPhone:** abrir
  a casa do gerente de uma unidade de cada atividade (e o pós-colheita,
  um boletim enviado, Diretoria › Faróis › unidade): linha 1 "Fazenda ›
  Atividade (área)", linha 2 abaixo; rolar e ver a linha 2 sumir por
  baixo da barra sem tranco; voltar ao topo. Decidir: (a) nome completo
  da unidade na linha 1 ("Mata Preta › Mata Preta — Café") em vez de
  "Mata Preta › Café"; (b) ARRENDADO entra na área?; (c) cadastrar
  talhões de Porto Buriti e Monte Carmelo — Pecuária (hoje sem área,
  parêntese omitido). Nenhum SQL.
- **Onda 1 estendida ao café (v65) — para o Nilo testar:** com código
  DIRETORIA/ADMIN, sincronizar e abrir painel › Faróis de registro: as
  10 unidades de café aparecem no fim da lista ("sem janela · N de M
  operações com registro"); tocar numa delas mostra "Operações sem
  janela" com "há N dias" / "sem registro" e, onde já há dois registros,
  "ritmo: a cada N dias". Com código de gerente de café numa unidade sem
  boletim no aparelho, ver "Sem boletim registrado em …" na casa; com
  pós-colheita, "Sem registro de pós-colheita em …". Nenhum SQL novo.
  **Régua de 7 dias (#19):** entregue na v73 (seção "Régua de 7 dias
  (v73)"). Decisão da v60 mantida: café continua sem janela (sem farol
  colorido).
- **Estado das integrações (v63):** `sql/045-status-integracoes.sql`
  RODADO pelo Nilo em 08/09/2026 e conferido pela REST pública logo
  depois: as duas linhas da visão (iCrop: tentativa 07:20 UTC, sucesso
  07:05 UTC — resposta 200 do manejo — dado gravado 02/09, origem
  30/08; Solinftec: tentativa e sucesso 06:05 UTC, dado de 07/09), 44
  respostas no diário `integracao_execucoes`, 8 jobs no de-para. Ainda
  manual: sincronizar com código de grãos/pecuária e ver a linha no
  rodapé dos cartões iCrop/Solinftec; com ADMIN, o bloco "Estado dos
  robôs" em Escritório › Integrações e robôs. Decidido pelo Nilo em
  08/09/2026 (v64): a linha vale para café e para o painel da Diretoria.
  Ainda com o Nilo: (b) a dica de chuva da estação iCrop na seção Clima
  segue sem linha (o cartão iCrop do mesmo boletim já a carrega); (c)
  `ultima_execucao_ok_em` da iCrop conta qualquer pedido com HTTP 200
  (manejo ou parcelas) — a coluna `tipo` do diário permite apertar isso.
- **Intervalo entre operações (v62) — para o Nilo:** rodar
  `sql/043-intervalo-operacoes.sql` no SQL Editor (bloco único; passo a
  passo no cabeçalho; só cria duas visões). Depois, opcional,
  `sql/044-intervalo-operacoes-teste.sql` lista o ritmo ao lado dos dias
  sem registro. No app, com código DIRETORIA/ADMIN: sincronizar e abrir
  painel › Faróis de registro › uma unidade de grãos ou pecuária — a
  linha "ritmo: a cada N dias" só aparece onde já há dois registros ou
  mais (com o banco de 07/09/2026, quase nada ainda). Sem o SQL rodado o
  app segue igual (a leitura falha em silêncio e nada aparece).
- **Estados vazios (v61) — para o Nilo:** revisar as frases (lista no
  PR da v61 e em docs/qualidade-log.md) e decidir sobre "Boletim de
  hoje pendente" / "Registro de hoje pendente" nas casas do gerente e
  do pós-colheita (rótulo de situação; trocar toca o café).
- **Janela e farol (v60):** `sql/042-janela-farol.sql` RODADO pelo Nilo em
  07/09/2026 e conferido pela REST (10 janelas propostas ativas; 582
  combinações; Capoeira Grande × monitoramento amarelo "sem registro desde
  o 1º boletim (há 7 dias) · janela aberta, fecha em 3 dias"; 4 unidades
  de grãos e as 9 de pecuária cinza por não terem boletim; café sem farol;
  0 violações de "vermelho só com janela fechada"). Pendente: revisar as
  janelas PROPOSTAS com o agrônomo (grãos) e o veterinário (pecuária) e
  ajustar por SQL (exemplos no cabeçalho do 042); conferir no app, com
  código DIRETORIA/ADMIN, painel › "Faróis de registro".
- **Dias sem registro (v59):** `sql/040-dias-sem-registro.sql` RODADO
  pelo Nilo em 07/09/2026 e conferido pela REST (75 operações, 90
  apelidos, 582 combinações; Capoeira Grande × Plantio / semeadura = 7
  dias; pecuária toda "sem registro" por não haver boletim). Item
  seguinte do backlog: janela por operação e farol (verde/âmbar/vermelho
  só com janela fechada) na Diretoria, lendo esta visão.
- **Padrão visual P10 — decisão do Nilo:** o CSS-base do app (raio 12
  px, sombra, chips-pílula, botões de 40 px) contraria o padrão visual
  do CLAUDE.md em todas as telas (ver "Telas × padrões de tela"). Trocar
  é uma versão só de CSS, com regressão visual antes/depois; enquanto
  não decidir, nenhuma tela nova pode acrescentar raio, sombra ou
  pílula.
- **❌ herdados dos padrões de tela** (lista acima): Mão de obra (3
  atividades), cartões "＋" do café (4), grãos (4) e pecuária (6),
  sub-acordeões da pecuária, Irrigação (pivôs) ao abrir, Pós-colheita
  (seções abertas + botão solto), Importar telemetria sem rodapé. Cada
  um é zerado na tarefa que tocar a tela; nenhum ❌ novo entra.
- **Robô-redator (v57) — para o Nilo:** (feito em 05/09/2026: sql/020,
  030 e 031 rodados, primeira devolutiva da Floramill gerada) colar no
  SQL Editor, nesta ordem:
  `sql/030-redator.sql` (depois do 020), `sql/031-redator-cofre.sql`
  trocando COLE_AQUI pela chave sk-ant-… da Anthropic (a chave nunca entra
  no repositório), e `sql/032-redator-teste.sql` (dispara uma devolutiva de
  teste da Floramill e mostra o texto). Sem a chave, o disparo falha com
  aviso claro no diário `relatorios_execucoes` e nada mais muda. Custo
  estimado: ~US$ 0,01 por devolutiva (24 por semana), ~US$ 0,05 por painel
  executivo — menos de US$ 2 por mês.
- **Relatórios automáticos (v55) — para o Nilo:** colar no SQL Editor,
  nesta ordem, o que ainda faltar: `sql/003-solinftec.sql` (se não rodou),
  `sql/005` → `006` → `007` (plano; sem eles o relatório plano × executado
  grava só um aviso), depois `sql/020-relatorios-motor.sql` e, para não
  esperar a madrugada, `sql/021-relatorios-teste.sql` (gera tudo na hora e
  traz as consultas de conferência). Depois sincronizar o app e abrir
  Diretoria › 📊 Relatórios. Unidade nova no app: inserir também em
  `rel_unidades`. Fase 2 (futuro): texto pronto na coluna `texto`, custo
  em R$ de insumo (ERP AgroGestão), lotação (área de pasto no Supabase),
  percentímetro executado (se a iCrop mandar no bruto).
- **Plano de safra (v52) — para o Nilo:**
  1. Rodar `sql/005-plano-safra.sql` e depois
     `sql/006-plano-safra-seed-2627.sql` no SQL Editor (o seed confere
     as somas e desfaz tudo se algo não bater).
  2. Publicar as versões vigentes: ou `sql/007-publicar-planos-2627.sql`
     de uma vez (quando o agrônomo aprovar), ou fazenda por fazenda na
     tela Unidades e Plano (Rodar auditoria → Aprovado por → Publicar).
     Sem plano vigente a fase B não tem o que mostrar.
  3. Decidir se os talhões do app serão desmembrados para ligar as 26
     unidades ainda sem apelido `app` (lista e motivos em
     `docs/plano/2026-27/alias_app.json`); isso muda os chips do
     gerente e fica para uma versão própria.
  4. Perguntas ao agrônomo herdadas dos decks: V56-6MN (renovação?),
     MCC-CXR (recepa?), AGL-T1 (Catuaí × Catucaí), MTP-3PT (área e
     identidade), Auto 400 × Alto 400, via da uréia mai–jul, e conferir
     os apelidos inferidos (Rio Preto 1º plantio, Caxico represa).
- **Fase B (versão futura)**: cartão "Plano do mês", chips ordenados pelo plano,
  modo safra zerada, chip "chumbinho visível", faróis do plano na
  Diretoria e texto "Plano × Semana" — só depois do merge da v52 e de
  pelo menos uma fazenda com plano vigente.
- **Rodar sql/004-boletim-pecuaria.sql no SQL Editor do Supabase**
  (cria a tabela boletim_pecuaria + visão pecuaria_movimentos).
  Enquanto não rodar, o espelho da pecuária fica na fila offline e o
  boletim continua subindo normal para a tabela boletins.
- **Trocar o código de acesso nos celulares dos gerentes** (ação do Nilo,
  não é código): em 11/09/2026 os ~15 gerentes estavam todos com o código
  `ADMIN-9561` (confirmado pelo Nilo). Cada um deve usar o código da PRÓPRIA unidade
  (CODIGOS_PADRAO, um por fazenda) — ele abre direto o boletim dela. No
  celular: tela inicial › "Sair" no rodapé › digitar o código novo. Com o
  código de administrador o gerente vê as 24 unidades e pode lançar na
  fazenda errada, além de alcançar Cadastros.
- **Rodar sql/052-aparelho-sync.sql no SQL Editor do Supabase** (cria a
  tabela `aparelho_sync`, o carimbo de "este aparelho sincronizou" que
  alimenta o cartão "📡 Chegada dos boletins hoje"). Enquanto não rodar,
  o cartão mostra só a hora de chegada do boletim e a linha do aparelho
  não aparece; nada mais muda (o carimbo vai fora da fila e falha em
  silêncio, de propósito).
- **Rodar sql/053-limpar-teste-diagnostico.sql no SQL Editor do Supabase**
  para apagar os três registros do teste de gravação de 11/09/2026
  (`TESTE-DIAGNOSTICO-1` em boletins, `-p` em pos_colheitas, `-t` em
  telemetria). Eles já foram marcados `exemplo:true`, então o app não os
  exibe, mas continuam ocupando a linha f22c/2026-09-11 no banco. A chave
  publishable **não apaga** (não existe policy de delete — o DELETE volta
  204 sem remover nada), só o SQL Editor.
- **Rodar sql/001-codigos-acesso.sql e depois
  sql/002-codigos-escopo.sql no SQL Editor do Supabase** (001 cria a
  tabela codigos_acesso; 002 insere as chaves de escopo por atividade
  e troca DIRETORIA/ADMIN para o formato novo). Sem eles o app
  continua funcionando com os códigos de fábrica, mas "gerar novo
  código" e os combinados criados em Cadastros não alcançam os
  outros aparelhos. **Confirmado em 11/09/2026:** a tabela não existe no
  banco (a consulta volta PGRST205). Consequência prática, e uma das
  hipóteses do silêncio do primeiro dia de preenchimento: código novo
  gerado em Cadastros vale SÓ no aparelho do admin — se ele for repassado
  aos gerentes, o app deles recusa (só conhece os de fábrica) e eles não
  entram. Além disso o item fica preso na fila daquele aparelho para
  sempre (404 a cada tentativa), acusando "aguardando internet".
- **Limitação conhecida**: o controle de acesso é fechadura de porta,
  não cofre — os códigos de fábrica vivem no código do app (público)
  e um aparelho que nunca sincroniza não fica sabendo de código
  trocado. Serve para organizar o uso, não para segurança forte.
  Degrau futuro: **login por pessoa com Supabase Auth** (cada gerente
  com usuário e senha próprios, permissões no banco).
- Ciclos reais de grãos aguardando censo de plantio (o que está
  plantado hoje em cada pivô/talhão) para abrir os ciclos oficiais.
- **Rodar sql/003-solinftec.sql no SQL Editor do Supabase**, trocando
  antes o texto COLE_AQUI_A_SENHA pela senha do PDF de configuração da
  Solinftec (a senha nunca entra no repositório). Depois da primeira
  carga, conferir se sobrou fazenda sem unidade (consulta pronta no
  fim do arquivo) e ajustar solinftec_depara.
- Pedir à Solinftec a lista de operações (código → nome) e preencher
  solinftec_operacoes; enquanto isso o app mostra "Operação NNN".
- Token da iCrop: rotação FEITA pelo Nilo em 04/09/2026 (validada,
  respostas 200). Próximas trocas: direto no SQL Editor (tabela
  segredos), nunca no código.
- **Ciclos vencidos na iCrop (04/09/2026)**: parte das fazendas está
  devolvendo lista de parcelas vazia e nenhuma medição depois de
  30/08 — ciclos encerraram sem novo plantio cadastrado na Vision
  (ex.: feijão da Floramill venceu 04/09). Quem resolve: agrônomo
  (Salvino) cadastrando os plantios; sem isso não há medição nova,
  com qualquer token.
- Porto Buriti (f35): talhões reais a cadastrar (hoje só "Área geral
  (a cadastrar)"); pivôs entram pelo campo "Cadastrar pivô desta
  fazenda" da seção Irrigação (cadastro local da unidade).
- **docs/CAMPOS-LIVRES.md** (v44): mapa de todos os campos de
  digitação livre que poderiam virar lista (produto, cultivar,
  prestador, lotes, armazéns, prompts remanescentes…). Decisão campo
  a campo pendente com o Nilo — nada foi alterado ainda.
