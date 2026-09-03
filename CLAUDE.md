# CLAUDE.md — Manual do projeto Boletim NCNaves

## O que é este projeto
PWA de boletim diário das fazendas do Grupo LGS (agronegócio: café,
grãos e pecuária — Monte Carmelo/MG). Gerentes de ~15 fazendas
preenchem pelo celular: clima, mão de obra por função, irrigação,
atividades por talhão, colheita, pós-colheita, remessas e ocorrências.
Arquitetura: arquivo único index.html (HTML+CSS+JS puro, sem
frameworks e sem etapa de build) + sw.js (service worker) + manifest.
Funciona offline (localStorage + fila de sincronização).

## Quem é o dono do projeto
Nilo, controller do grupo. NÃO é programador e trabalha exclusivamente
pelo iPhone. Toda comunicação com ele deve ser em português do Brasil,
clara e sem jargão. Explique o que fez em termos de negócio.

## Publicação (NÃO ALTERAR ESTE FLUXO)
O Netlify publica automaticamente o branch main em
https://boletim-ncnaves.netlify.app. Não há build command; o site é
servido como está. Portanto: NUNCA quebre o main. Trabalhe sempre em
branch próprio e abra pull request (ou faça merge apenas quando o
Nilo pedir explicitamente).

## Regra de versão (OBRIGATÓRIA em toda mudança publicável)
1. Incrementar a versão no rodapé da tela inicial
   ("Boletim NCNaves · vNN").
2. Trocar o nome do cache no sw.js ("boletim-lgs-vNN") para o MESMO
   número. Sem isso os celulares dos gerentes não atualizam.

## Banco de dados (Supabase)
URL: https://syvehtgrbqteyuqhoban.supabase.co
No código só existe a chave publishable (pública por natureza).
Tabelas que o app usa: boletins, pos_colheitas, remessas, telemetria,
icrop_manejo, icrop_fazendas, icrop_parcelas (leitura), solinftec_diario
(leitura), codigos_acesso, boletim_pecuaria e, desde a v52, as do plano
de safra: unidade_manejo, unidade_alias, unidade_manejo_log,
plano_safra, plano_unidade, plano_adubo_mes, plano_calagem,
plano_fito_mes, plano_fito_excecao, plano_gantt, plano_parametros
(o app lê; só a tela de ADMIN escreve).
Um robô (pg_cron + pg_net no Supabase) busca dados da API iCrop toda
madrugada e grava em icrop_manejo. O app apenas LÊ essas tabelas.

## Segurança (INEGOCIÁVEL)
- NUNCA colocar tokens, senhas ou chaves secretas no código ou em
  commits. O token da iCrop vive só no Supabase (tabela segredos,
  acessível apenas pelo SQL Editor). A única chave permitida no
  código é a publishable do Supabase.
- Não criar dependências externas (CDNs, bibliotecas) sem pedido
  explícito.

## Estilo visual (identidade do app — respeitar sempre)
Tons de papel, vermelho óxido nas ações primárias, verde folha para
conformidade, âmbar para alertas. Números em fonte monoespaçada
tabular. PROIBIDO: gradientes, sombras, cantos arredondados, botões
em formato pílula, emojis decorativos novos.

## Domínio (vocabulário)
Fazenda > Talhão (menor unidade de custo). Fazendas irrigadas com
iCrop: Cachoeira do Rio Preto—Lagamar (f03), Vereda (f22),
Floramill (f33), Capoeira Grande (f27). O de-para nome-iCrop → id
do app está na constante DEPARA_ICROP do index.html.
Perfis de uso: gerente (preenche) e diretoria (painel).

## Plano de safra (regras permanentes desde a v52)
O plano do agrônomo (Salvino) entra no app SÓ como referência e
comparação — nunca como receituário. Modelo de dados e fluxo em
docs/PLANO-DE-SAFRA.md. Regras que não se discutem:
1. **Nenhum texto do app pode ser lido como prescrição.** Nome de
   produto do plano só aparece (a) em cartão de leitura com o rótulo
   fixo "previsto pelo agrônomo — registre o que foi feito" e (b) como
   chip que preenche a calda com o nome do produto que o gerente JÁ
   usou. Nunca com o verbo "aplicar", nunca com dose.
2. **kg do plano nunca aparecem por padrão** na tela do gerente. Só ao
   tocar em "ver plano", rotulados "plano v_N".
3. **Identidade só pelo cadastro mestre.** A chave é unidade_manejo.id
   (codigo imutável); nomes são aliases em unidade_alias. Nenhuma regra
   pode usar pedaço de nome de fazenda, arquivo ou slide ("Lagamar"
   está em 2 fazendas, "Rio Preto" em 2, "Vereda" em 3). Nome de
   fazenda do plano que não bate EXATAMENTE com o cadastro do app não
   é mapeado: pare e pergunte ao Nilo.
4. **Faróis dizem "sem registro", nunca "não fez".** Vermelho só depois
   de a janela fechar. Farol e alerta do plano são da Diretoria; o
   gerente não vê nenhum.
5. **Mudança no plano só por nova versão** (Escritório/ADMIN), nunca
   editando as tabelas vigentes. Uma versão vigente por fazenda-safra;
   publicar passa a anterior para "superado". Nada se apaga.
Zero campos novos para o gerente por causa do plano (única exceção
prevista: o chip "chumbinho visível", fase B). Sem plano ou sem rede,
o boletim funciona exatamente como antes.

## Como trabalhar neste código
- index.html é grande; localize funções por busca (ex.: icropDo,
  baixarIcrop, telemetriaDo, SYNC_PADRAO).
- Toda mudança: mínima e cirúrgica. Não reformatar o arquivo, não
  renomear funções existentes, não "melhorar" o que não foi pedido.
- Antes de finalizar, validar sintaxe do JavaScript extraído
  (node --check) e conferir que o HTML abre sem erro.
- Cartões novos seguem o padrão dos existentes (classe "cartao",
  avisos com classe "aviso").

## Documentação viva (OBRIGATÓRIO em toda tarefa)
- ESTADO.md (na raiz) descreve o que o app tem hoje e as pendências.
  TODA tarefa que mudar comportamento, catálogo, chave ou versão deve
  ATUALIZAR o ESTADO.md no mesmo pull request.
- docs/catalogos-por-atividade.md é a fonte oficial do vocabulário de
  operações e campos por atividade. Mudou catálogo no index.html?
  Atualize o arquivo junto — os dois nunca podem divergir.
- Quando uma tarefa exigir tabela nova no Supabase, gerar o arquivo
  sql/NNN-nome.sql no repositório com o bloco SQL pronto (create
  table, policies, comentários) e avisar no resumo final que o Nilo
  precisa rodá-lo no SQL Editor.
- docs/PLANO-DE-SAFRA.md descreve o modelo do plano de safra, o
  versionamento e o mapa Gantt ↔ chips. Mudou tabela, cache
  (bdf:plano), auditoria ou mapa? Atualize junto. Os dados de uma
  safra vivem em docs/plano/AAAA-AA/ e só entram por script
  (nunca editar o seed JSON à mão).
- Antes de abrir PR que mexa no index.html, rodar
  scripts/regressao_render.cjs contra a versão anterior (origin/main)
  e a nova, e conferir que as telas de gerente ficaram idênticas onde
  deviam (instruções no cabeçalho do script).
