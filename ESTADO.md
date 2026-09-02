# ESTADO.md — o que o app tem hoje

Fotografia atual do Boletim NCNaves. TODA tarefa que mudar
comportamento, catálogo, chave ou versão DEVE atualizar este arquivo
no mesmo pull request (regra no CLAUDE.md).

**Versão atual: v50** (rodapé da tela inicial + cache do sw.js).

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
  de pecuária**. Pastos/retiros = talhões tipo PASTO_PECUARIA (sem
  lista paralela); categorias animais na constante CATEGORIAS_ANIMAIS;
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
- Robô iCrop (pg_cron + pg_net no Supabase): grava icrop_manejo toda
  madrugada; o app LÊ (icropDo) e mostra medição do dia, compara
  lâmina informada × medida e alerta parcela vencida (icrop_fazendas
  e icrop_parcelas).
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

## Chaves ligadas/desligadas
- SOLINFTEC_AUTO = true (desde a v48). Enquanto sql/003-solinftec.sql não
  rodar no Supabase, o fetch falha em silêncio e nenhum cartão
  Solinftec aparece — o app segue normal.
- Sincronização Supabase: ligada por padrão (SYNC_PADRAO com a chave
  publishable).

## PENDÊNCIAS
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
- Token da iCrop (tabela segredos do Supabase) pendente de troca
  (rotação) — trocar direto no SQL Editor, nunca no código.
- Porto Buriti (f35): talhões reais a cadastrar (hoje só "Área geral
  (a cadastrar)"); pivôs entram pelo campo "Cadastrar pivô desta
  fazenda" da seção Irrigação (cadastro local da unidade).
- **docs/CAMPOS-LIVRES.md** (v44): mapa de todos os campos de
  digitação livre que poderiam virar lista (produto, cultivar,
  prestador, lotes, armazéns, prompts remanescentes…). Decisão campo
  a campo pendente com o Nilo — nada foi alterado ainda.
