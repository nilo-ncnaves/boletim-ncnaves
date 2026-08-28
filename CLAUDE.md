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
icrop_manejo, icrop_fazendas, icrop_parcelas (leitura).
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

## Como trabalhar neste código
- index.html é grande; localize funções por busca (ex.: icropDo,
  baixarIcrop, telemetriaDo, SYNC_PADRAO).
- Toda mudança: mínima e cirúrgica. Não reformatar o arquivo, não
  renomear funções existentes, não "melhorar" o que não foi pedido.
- Antes de finalizar, validar sintaxe do JavaScript extraído
  (node --check) e conferir que o HTML abre sem erro.
- Cartões novos seguem o padrão dos existentes (classe "cartao",
  avisos com classe "aviso").
