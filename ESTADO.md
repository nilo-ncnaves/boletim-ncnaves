# ESTADO.md — o que o app tem hoje

Fotografia atual do Boletim NCNaves. TODA tarefa que mudar
comportamento, catálogo, chave ou versão DEVE atualizar este arquivo
no mesmo pull request (regra no CLAUDE.md).

**Versão atual: v57** (rodapé da tela inicial + cache do sw.js).

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
- Aparelhos que entraram na v45 com código de unidade continuam
  dentro (migração automática do acesso gravado); os códigos antigos
  de DIRETORIA (LG-9351) e ADMIN (AD-4786) foram substituídos pelo
  formato novo — esses aparelhos pedem o código novo uma vez.

## Seções do boletim por atividade
- ☕ Café: clima, mão de obra por função, talhões/atividades,
  irrigação (gotejo), colheita, pós-colheita, fito, ocorrências.
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
de aplicativos de gestão: **menu** (11 assuntos, cartões grandes com
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
8. **🔌 Integrações e robôs** — Supabase, robô iCrop (última medição ×
   última gravação, de-para, parcelas vencendo), robô Solinftec
   (SOLINFTEC_AUTO, última data, linhas sem de-para, operações sem
   nome), plano de safra; "Baixar agora" = syncTudo.
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
  inexistente = silêncio. Diretoria: seção "📊 Relatórios" (fechada) com
  filtro dia/semana/mês, último período gerado, "N para conferir" em
  âmbar; toque abre a tela do relatório (tabelas compactas `.rel-tab`,
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

## PENDÊNCIAS
- **Robô-redator (v57) — para o Nilo:** colar no SQL Editor, nesta ordem:
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
- **Rodar sql/001-codigos-acesso.sql e depois
  sql/002-codigos-escopo.sql no SQL Editor do Supabase** (001 cria a
  tabela codigos_acesso; 002 insere as chaves de escopo por atividade
  e troca DIRETORIA/ADMIN para o formato novo). Sem eles o app
  continua funcionando com os códigos de fábrica, mas "gerar novo
  código" e os combinados criados em Cadastros não alcançam os
  outros aparelhos.
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
