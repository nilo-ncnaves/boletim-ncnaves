# Investigação — cadeia de estados (Recomendado → Planejado → Realizado → Saldo)

Apuração feita em **09/09/2026** sobre o repositório na v74, para decidir se a
Onda 2 pode abrir com a cadeia de estados e a confirmação em dois toques.
**Nada foi alterado**: nenhuma tabela, visão, função, índice ou política foi
criada, mudada ou apagada, e nenhum SQL de escrita foi executado.

**Base da apuração.** Leitura completa de `CLAUDE.md`, `ESTADO.md`, `docs/`
(incluindo `PLANO-DE-SAFRA.md`, `PLANO-2627-AUDITORIA.md`, `CAMPOS-LIVRES.md`,
`relatorios.md`, `catalogos-por-atividade.md`, `qualidade-log.md`,
`vistoria-semanal.md`), de todos os arquivos em `sql/` e do `index.html`
(consultas ao Supabase, envio do boletim, sincronização, catálogos).

**Limite desta apuração.** Não houve leitura do banco real. Tentei uma consulta
somente-leitura pela API pública do Supabase e o ambiente desta sessão bloqueou
a chamada. Por isso **tudo que depende do estado atual do banco está marcado
"não apurado"** e vai no bloco SQL do fim, para o Nilo rodar. O que está afirmado
aqui sem essa marca vem do código e da documentação, que são fato.

---

## 1. Resumo em cinco linhas

1. **Existe plano no banco?** A **estrutura** existe escrita e pronta
   (`sql/005`–`007`: 9 tabelas, 69 unidades, 71 calagens, 1.533 linhas de adubo
   mês a mês) mas **só para café, em 8 fazendas**, e a última evidência do
   repositório (04/09/2026) diz que essas tabelas **ainda não foram criadas** no
   Supabase. Grãos e pecuária não têm plano nenhum, nem estrutura nem dado.
2. **Como o plano entraria?** Hoje, só por **carga manual**: PPTX do Salvino →
   script Python → arquivo SQL colado no SQL Editor, uma vez por versão. O iCrop
   entrega uma **recomendação de irrigação** de verdade (é o único "Recomendado"
   automático que já existe no banco); a Solinftec entrega **só execução**; o ERP
   AgroGestão não está integrado.
3. **Identidade das entidades?** As duas chaves que a cadeia precisa **existem e
   são estáveis**: unidade operacional (`f01`, `f03c`…) e operação
   (`operacao_catalogo.id` + de-para por igualdade exata). O defeito do Sigma
   aparece em outro lugar: iCrop e Solinftec são conciliados por **pedaço de nome
   de fazenda**, o **talhão só existe no aparelho** (não está no banco), e
   produto, lote, cultivar e prestador são **texto livre**.
4. **Como o apontamento é gravado?** **Uma linha por unidade e por dia**
   (`boletins`, chave `fazenda_id + data`), com o boletim inteiro num JSON.
   Não existe linha por operação, não existe coluna de estado no apontamento e
   não existe histórico: corrigir um boletim **sobrescreve** o anterior.
5. **Comportamento observado?** **Não apurável.** O "Nada a registrar hoje"
   entrou no main em **08/09/2026** — ontem — e o `sql/047`, que é o que grava
   isso em tabela, ainda consta como não rodado. Não há tempo de uso suficiente.

---

## 2. Bloco 1 — Existe plano no banco?

### 2.1 A estrutura existe (escrita, no repositório)

`sql/005-plano-safra.sql` cria 11 tabelas. As que guardam **intenção futura**:

| Tabela | O que guarda | Colunas que importam |
|---|---|---|
| `plano_safra` | a versão do plano de uma fazenda numa safra | `fazenda_app`, `safra`, `versao`, `status` (rascunho → vigente → superado), `vigente_de`, `aprovado_por`, `auditoria_ok` |
| `plano_unidade` | quais unidades a versão cobre | `plano_id`, `unidade_id`, `area_ha_plano`, `safra_zerada_tipo` |
| `plano_adubo_mes` | **adubação prevista por unidade, mês e insumo** | `plano_id`, `unidade_id`, `mes` (1–12), `insumo` (8 valores fechados), `kg`, `via` |
| `plano_calagem` | calagem prevista com janela | `unidade_id`, `subarea`, `t_ha`, `t_total`, `janela_ini`, `janela_fim` |
| `plano_fito_mes` | calendário fitossanitário do grupo | `mes`, `fase`, `alvos[]`, `produtos[]`, `via_solo[]` |
| `plano_gantt` | **janela do ano por atividade** (modelo NC / NR) | `modelo`, `atividade` (slug), `meses[]`, `tipo` (janela / evento_unico), `evidencia_app` |
| `plano_parametros` | limites dos faróis | `chave`, `valor` |

Duas observações que mudam o desenho:

- **A unidade do plano não é a unidade operacional do app.** `plano_*` aponta para
  `unidade_manejo` — o **setor / talhão de café** (ex.: `VEC-S08`), não para
  `f22c`. A ligação com o app é `unidade_alias` com `sistema = 'app'`, cujo
  apelido é o **id do talhão** (`t093`).
- **`plano_adubo_mes` é a coisa mais próxima de "operação prevista"**, mas é
  previsão de **insumo e quantidade por mês**, não de operação por data.
  A previsão de **operação** existe só no `plano_gantt`, e em granularidade de
  **mês × atividade × modelo de empresa** — não por unidade.

### 2.2 Está populada? — provavelmente não, e isso precisa ser confirmado

Evidência no repositório, na ordem:

- `ESTADO.md`, "Pendências", item **"Plano de safra (v52) — para o Nilo"**:
  ainda pede, em aberto, "1. Rodar `sql/005` e depois `sql/006`… 2. Publicar as
  versões vigentes". Não há marca de FEITO, ao contrário do `sql/045` ("FEITO em
  08/09/2026"), do `sql/042` e do `sql/040` ("FEITO em 07/09/2026") e do robô-
  redator ("feito em 05/09/2026: sql/020, 030 e 031 rodados").
- `docs/relatorios.md`, "Avisos sobre as fontes": *"**Tabelas ainda não criadas**
  (04/09/2026): plano_* (sql/005–007) e codigos_acesso (sql/001–002) respondem
  404 até o Nilo rodar os SQL"*.
- `docs/relatorios/04-plano-x-executado.md` repete o mesmo aviso e diz que o
  relatório fica PENDENTE até lá.

**Não apurado:** se o Nilo rodou os três arquivos depois de 04/09/2026. É a
primeira linha do bloco SQL do fim. Enquanto não rodar, a diferença é decisiva:
hoje não existe nem a tabela vazia.

### 2.3 Cobertura, se rodar

- **Atividades:** só **café**. Grãos e pecuária não aparecem em nenhuma tabela
  de plano.
- **Fazendas:** **8** de 24 unidades operacionais — Água Limpa (f01), Rio
  Preto-Lagamar — Café (f03c), Mata Preta — Café (f13c), Monte Carmelo — Café
  (f14c), Lagamar Café Rodrigo (f20), Vereda — Café (f22c), Vereda Romaria
  (f23), Vereda Café 5º e 6º (f24). Ficam de fora São Félix (f21) e o Armazém
  Geral (f25), que são de café mas não têm deck.
- **Unidades de manejo:** 69 no seed; **43 têm apelido `app`** (47 apelidos) e
  **26 não têm** — não é falha de carga, é que o cadastro de talhões do app não
  comporta (várias unidades do plano para um talhão só). Para essas 26, o plano
  existe e **não tem como ser comparado com registro do gerente**.
- **Safra:** 2026/27, versão 1, que nasce em **rascunho**. Sem publicar
  (`sql/007` ou a tela Unidades e Plano), o app não lê nada: `baixarPlano()`
  busca `status = 'vigente'`.

### 2.4 Onde mais existe intenção futura no banco

Fora do plano de safra, três coisas:

| Onde | O que é | Cobertura |
|---|---|---|
| `operacao_janela` (`sql/042`) | **cadência esperada** de registro por operação: "espera-se ver esta operação a cada N dias, com N dias de tolerância" | 10 linhas semeadas, todas com `origem = 'proposta'`: 9 de pecuária, 1 de grãos. Nenhuma de café. |
| `plano_calagem.janela_ini/fim` | janela de data para a calagem | só café, dentro do plano |
| `icrop_manejo.bruto` | **recomendação de irrigação do iCrop** (ver Bloco 2) | as 4 fazendas com iCrop |

`operacao_janela` é uma **expectativa de ritmo**, não um plano: não diz data,
não diz quantidade, não diz unidade (a linha geral vale para toda a atividade).
Serve de farol, não de "Planejado".

**Não existe** nenhuma coluna de "data prevista" em registro de apontamento,
nenhuma tabela de agenda e nenhum campo de programação semanal.

---

## 3. Bloco 2 — Como o plano entraria

### 3.1 Rotinas de importação que existem hoje

| Rotina | De onde | Para onde | Frequência | Onde mora o código |
|---|---|---|---|---|
| Robô iCrop | API iCrop Vision | `icrop_manejo`, `icrop_fazendas`, `icrop_parcelas` | 03h50 / 04h05 / 04h20 (BRT) + reforço 09h45 / 10h00 / 10h15 | **Só no Supabase** — não está no repositório |
| Robô Solinftec | API "Detalhes da Operação V3" | `solinftec_diario` | 03h05 (dia anterior fechado) + de hora em hora, 09h35–20h35 (parcial) | `sql/003-solinftec.sql` |
| Motor de relatórios | as tabelas acima + `boletins` | `relatorios_gerados` | pg_cron 05:00 BRT | `sql/020-relatorios-motor.sql` |
| Robô-redator | `relatorios_gerados.dados` → API Anthropic | `relatorios_gerados.texto` | junto com o relatório | `sql/030-redator.sql` |
| Colheita de status HTTP | `net._http_response` | `integracao_execucoes` | 07:35 e 13:30 UTC | `sql/045` |
| **Carga do plano** | **7 PPTX do Salvino** | `plano_*` | **manual, uma vez por versão** | `docs/plano/importar_plano.py` → `scripts/expandir_apendice_plano.py` → `scripts/gerar_seed_plano.py` → `sql/006` |
| Telemetria | arquivo importado à mão na tela | `telemetria` | quando alguém importa | `index.html` |

Duas coisas a registrar:

- **A carga do plano não é uma integração, é uma obra.** São quatro passos
  manuais, com conferência que trava se as somas não baterem, e o resultado é um
  arquivo SQL de 200 KB colado no SQL Editor. Plano novo = repetir tudo. Não há
  nenhum robô, agendamento ou API envolvida.
- **O código do robô iCrop não está no repositório.** `ESTADO.md` cita
  `sql/003-robo-icrop-reforco.sql`, mas esse arquivo não existe em `sql/`. Se o
  projeto do Supabase for perdido, o robô iCrop se perde junto.

### 3.2 O que o iCrop efetivamente traz (o que está gravado, não o que o manual promete)

Pelo `select` de `baixarIcrop()` no `index.html` e pelas fontes dos relatórios
6, 15 e 18, `icrop_manejo` tem colunas próprias (`fazenda`, `equipamento`,
`parcela`, `data`, `irrigacao_mm`, `precipitacao_mm`, `etc`, `eto`,
`atualizado_em`) e uma coluna `bruto` (JSON) de onde o app lê:

- **Recomendação:** `percentimetro_recomendado`, `tempo_de_irrigacao`,
  `lamina_minima`, `deficit_previsto`, `dias_em_atraso`.
- **Medição / estado:** `umidade`, `capacidade_de_campo`,
  `umidade_de_seguranca`, `deficit_consolidado`, `fase_atual`,
  `gd_dia_acumulado`, `acumulado_irrigacao`, `acumulado_precipitacao`,
  `eficiencia_irrigacao`, `problemas_irrigacao`.
- **Clima da estação:** `temperatura_minima/maxima`,
  `umidade_relativa_do_ar`, `velocidade_do_vento`, `chuva_pluviometro`.
- **Custo:** `reais_mm_ha`, `reais_por_irrigacao_necessaria`,
  `reais_por_irrigacao_realizada`.

**Conclusão do bloco:** o iCrop **é** uma fonte de "Recomendado", e ela já está
no banco e já aparece na tela (cartão "iCrop — medição automática do dia", linha
"Recomendação iCrop"). Mas é recomendação **de irrigação, por parcela e por dia**,
nas 4 fazendas com estação (Rio Preto-Lagamar, Vereda, Floramill, Capoeira
Grande). Não é plano de operações e não cobre café de sequeiro, grãos secos nem
pecuária. `icrop_parcelas` traz o cadastro de parcelas ativas com data de fim de
ciclo — é cadastro e vencimento, não programação de serviço.

### 3.3 O que a Solinftec expõe

`solinftec_diario` só tem **execução**: `data`, `equipamento`, `cd_operacao`,
`operacao`, `talhao`, `horas`, `motor_h`, `ocioso_h`, `area_ha`, `consumo_l`.
Nenhuma coluna de previsão, ordem de serviço ou programação. A API usada é
"Detalhes da Operação V3", que é relatório do que a máquina fez.
**Não apurado:** se a Solinftec tem outro endpoint com ordem de serviço — isso
se pergunta ao fornecedor, não se lê no banco.

### 3.4 Decisão anterior sobre importar os planos do agrônomo

Sim, existe, e é explícita — `docs/PLANO-DE-SAFRA.md`:

- **O que o plano é:** "referência e comparação". **O que não é:** "receituário".
- **Como entra uma versão nova:** PPTX → extrator → resolver cada nome contra
  `unidade_alias` → montar o seed da versão N+1 → rascunho → auditoria →
  publicar. Nunca editando a versão vigente.
- **O que ficou de fora de propósito:** "Solinftec/iCrop cruzados com o plano,
  kg do ERP, trilha de produção, estimativa automática, robô semanal em pg_cron,
  devolutiva automática… Tabelas `execucoes_externas`, `plano_farol`,
  `estimativa_checkpoint` e `devolutivas` não existem ainda."

Ou seja: a decisão registrada é que o plano entra **à mão, por versão**, e que
cruzar plano com execução externa **foi adiado de propósito**.

---

## 4. Bloco 3 — Identidade das entidades

Este é o bloco que decide a viabilidade. A resposta curta: **a identidade que a
cadeia precisa existe; a identidade das camadas em volta, não.**

### 4.1 Unidade operacional

| Fonte | Chave usada | É estável? |
|---|---|---|
| `boletins` | `fazenda_id` = id do app (`f01`, `f03c`, `f22g`…) | **Sim.** Chave substituta, curta, imutável. |
| `rel_unidades` (`sql/020`) | mesma chave, espelhada com nome, fazenda-mãe e perfil | **Sim.** 24 unidades. |
| `boletim_pecuaria`, `pos_colheitas`, `remessas` | mesma chave | **Sim.** |
| `unidade_manejo` (plano) | `codigo` (`VEC-S08`), com gatilho que **impede** mudar o código | **Sim**, e é o modelo certo. Mas é outro nível: setor, não unidade operacional. |
| `solinftec_diario` | `fazenda_id` preenchido por **`solinftec_depara`: pedaço do nome em minúsculas** (`'rio preto' → f03g`, `'caxico' → f14c`) | **Não.** É conciliação por texto. |
| `icrop_manejo` | não tem coluna de unidade; o app decide por **`DEPARA_ICROP`, também pedaço de nome**, e separa café × grãos procurando a palavra "cafe" no nome do equipamento/parcela | **Não.** É conciliação por texto, duas vezes. |
| Talhão | `talhaoId` (`t093`) dentro do JSON do boletim | **A chave é estável, mas o cadastro não está no banco** (item 4.4). |

Há de-para para as duas fontes externas (`solinftec_depara`, `rel_icrop_depara` /
`DEPARA_ICROP`), o que é o certo — mas o de-para é **por substring**, não por
identificador do fornecedor. Regras registradas: "o padrão mais comprido ganha
quando dois casarem". Duas fazendas ficam de fora de propósito ("Estreito" e
"-1"). Consequência prática: fazenda nova, nome renomeado na Solinftec ou
equipamento de café batizado sem a palavra "café" cai na unidade errada, ou em
nenhuma, **em silêncio**.

### 4.2 Operação / serviço

**Tem catálogo e tem chave substituta**, e isso é o achado mais favorável desta
investigação.

- `operacao_catalogo` (`sql/040`): **75 operações** — 19 de café, 28 de grãos,
  28 de pecuária. `id` é texto imutável (`CAFE-PULVERIZACAO`,
  `PEC-VERMIFUGACAO`), com `atividade`, `fase`, `nome`, `ordem`, `ativo`. O
  comentário da tabela é explícito: "Identidade = id."
- `operacao_alias` (90 linhas): de-para do **texto exato** gravado no payload
  para o id do catálogo, **por igualdade exata, nunca LIKE**, com a coluna
  `origem` dizendo em que caminho do JSON o texto mora
  (`atividades.tipo`, `pecuaria.mov.tipo`, `pecuaria.san.problema`…). Um termo
  pode apontar para duas operações (Mudança de pasto = entrada e saída de lote).
- `operacao_categoria` / `OP_CATEGORIAS` (v67): 5 categorias por atividade,
  letra única, categoria ligada **pelo id do catálogo**, com a regra escrita de
  que "a letra é ATRIBUTO do catálogo, nunca derivada de pedaço de nome".
- O gerente **não digita** o nome da operação: escolhe em chip ou em seletor
  alimentado pelo catálogo.

Duas frestas, e as duas importam para a cadeia:

1. **"Outra".** `LISTA_ATIV` termina em `"Outra"`, e o gerador do catálogo o
   exclui de propósito (`LISTA_ATIV.filter(n => n !== "Outra")`). Uma atividade
   lançada como "Outra" **não tem id, não tem de-para e é invisível** para
   `vw_dias_sem_registro`, `vw_farol_registro`, `vw_ritmo_operacoes` e para
   qualquer cadeia de estados. Não é erro: é o escape do catálogo. Mas é um
   buraco por onde a cadeia vaza.
2. **Termos extras dos catálogos (v56).** Em Cadastros › Catálogos o escritório
   pode acrescentar termos de operação (`catExtraAdd`). Esse termo entra nas
   listas do gerente **naquele aparelho**, é gravado no payload como texto, e
   **não existe** em `operacao_catalogo` nem em `operacao_alias`. Mesmo efeito:
   registro invisível para o catálogo.

### 4.3 Tabelas de conciliação que existem

| De-para | Liga | Como |
|---|---|---|
| `operacao_alias` | texto do payload → operação do catálogo | igualdade exata ✔ |
| `unidade_alias` | unidade do plano → nome no deck, id do talhão do app, nome na Solinftec, nome no iCrop, nome no AgroGestão | igualdade exata, com vigência e unicidade por (sistema, fazenda, apelido) ✔ |
| `solinftec_depara` | nome da fazenda na Solinftec → unidade do app | **substring** ✘ |
| `rel_icrop_depara` / `DEPARA_ICROP` | nome da fazenda no iCrop → fazenda física | **substring** ✘ |
| `solinftec_operacoes` | código da operação Solinftec → nome amigável | igualdade exata, mas **vazio** (pendência: pedir a lista à Solinftec) |
| `FZ_LEGADO` / `rel_fz_atual` | ids antigos de fazenda → unidade atual (f19→f03c, f05/f15/f16/f14→f14c…) | igualdade exata ✔ |

`unidade_alias` já prevê o slot `agrogestao`, mas **o ERP não está integrado**
(`docs/relatorios.md`: "AGUARDA ERP (AgroGestão não integrado)").

### 4.4 Duplicidade — onde o defeito do Sigma mora neste app

O caso `SULFATO DE MANGANES` × `Sulfato de manganes` **é exatamente o risco
mapeado neste projeto**, e já está catalogado em `docs/CAMPOS-LIVRES.md` (v44),
que lista **20 pontos de digitação livre**. Os de risco ALTO:

| # | Campo livre | Por que quebra a cadeia |
|---|---|---|
| 1 | Produto / defensivo da receita (grãos, quimigação) | "mesmo defensivo com 3 grafias impede fechar custo e rastrear carência" |
| 2 | Produto / vacina (pecuária) | controle sanitário por produto vira texto solto |
| 5 | Cultivar / híbrido | "censo de plantio e ciclos dependem disso" |
| 11 | Lote / categoria (pecuária) | sem lote padronizado não há GMD nem contagem entre dias |
| 13 | Lote (pós-colheita: terreiro → secador → tulha → benefício) | "o mesmo lote precisa amarrar 4 etapas; hoje é texto em 4 lugares" |
| 7 | Prestador terceirizado | comparar preço e desempenho não fecha |

O app até "aprende" os nomes digitados (`D.insumosAprendidos`) e os oferece como
sugestão — o que reduz a divergência, mas **no aparelho de quem digitou**, e não
impede grafia nova.

**Não apurado:** quantas grafias divergentes já existem de fato no banco. O bloco
SQL do fim conta exatamente isto: "grafias distintas de produto/insumo" e
"produtos com mais de uma grafia" (comparação sem acento e sem caixa).

### 4.5 O cadastro de talhões não está no banco

Achado que não estava explicitado em lugar nenhum e que muda o desenho:

- `D` (fazendas, **talhões**, máquinas, insumos, usuários, ciclos, inventário de
  pecuária, catálogos extras) vive em `localStorage`, na chave `bdf:dados`,
  semeado por constantes do `index.html`.
- A fila de sincronização (`syncEnfileirar`) só carrega **seis tipos**: boletim,
  pós-colheita, remessa, telemetria, código de acesso e espelho de pecuária.
  **Nenhum cadastro sobe.**
- Portanto: um talhão criado em Cadastros num iPhone **não existe** no Supabase
  nem no iPhone de mais ninguém. `docs/relatorios.md` confirma pelo outro lado —
  "**Nomes de talhão** vivem no cadastro do `index.html`" e "**Ciclos de grãos
  não têm tabela própria**".
- No banco, `talhaoId` é só um texto dentro do JSON. Não há tabela para dar
  nome, área ou fazenda a ele.

---

## 5. Bloco 4 — Estrutura do apontamento atual

### 5.1 Como um apontamento é gravado

**Uma linha por unidade e por dia.** A gravação é um `POST` com
`on_conflict=fazenda_id,data`, ou seja, um **upsert**:

```
boletins:  id (texto)  ·  fazenda_id  ·  data  ·  payload (JSON com o boletim inteiro)
```

Dentro do `payload` ficam as listas: `atividades[]` (uma entrada por lançamento
do gerente, com `talhaoId`, `tipo`, `pessoas`, `insumos[]`, `produtos[]`…),
`irg[]` (pivôs), `fito[]`, `ocorrencias[]`, `colheita[]`, `mo`, `clima`,
`pecuaria{}` e, desde a v69, `secoes{}`.

Consequências diretas para a cadeia de estados:

- **Não existe linha por operação.** As visões de farol (`vw_dsr_registros`)
  desmontam o JSON com `jsonb_array_elements` a cada consulta para chegar em
  (unidade, data, operação). Funciona para leitura; não serve de âncora para
  gravar um estado por operação.
- **A chave é a unidade-dia, não o registro.** Dois aparelhos preenchendo a
  mesma unidade no mesmo dia **sobrescrevem um ao outro** — vence o último a
  sincronizar. O app tenta evitar isso na tela ("Já existe boletim de … nesta
  unidade"), mas o banco não impede.
- Há **duas cópias parciais** do mesmo dado: `boletim_pecuaria` (espelho da parte
  de pecuária, para consulta/ERP) e `boletim_secao_resposta` (gravada por gatilho
  a partir de `payload.secoes`). Ambas derivadas, nunca fonte.
- Pós-colheita é a mesma forma (`pos_colheitas`, upsert por `fazenda_id + data`).

### 5.2 Existe noção de estado em algum registro?

Sim — em cinco lugares, e nenhum deles no apontamento em si:

| Onde | Estados | Quem muda | Onde vive |
|---|---|---|---|
| `atividades[].status` (dentro do payload) | `concluida` ⇄ `continua` (+ campo `falta`: "o que falta?") | o gerente, em chip | JSON do boletim |
| `remessas.status` | `enviada` → `recebida` (com `recebidoEm`, `recebidoQtd`, `obsReceb`) | o gerente **da fazenda de destino** | tabela própria |
| `plano_safra.status` | `rascunho` → `vigente` → `superado` | ADMIN, na tela Unidades e Plano | tabela própria |
| `unidade_manejo.status` | `producao`, `poda`, `renovacao`, `recepa`, `plantio`, `a_confirmar` | ADMIN | tabela própria |
| `ciclos` (grãos) | abre no plantio, encerra quando a colheita cobre a área do talhão | o app, propondo ao gerente | **só no aparelho** |

**Dois desses são precedentes valiosos para a Onda 2**, e vale dizer em voz alta:

- **`atividades[].status = "continua"`** é, na prática, um estado de execução
  parcial que **atravessa o dia**: a tela "O que ficou de ontem" traz de volta as
  atividades marcadas assim, com o texto do que falta. Já é meia cadeia.
- **`remessas`** é o único **fluxo com confirmação em outro toque, por outra
  pessoa**: quem envia cria "enviada", quem recebe confirma e vira "recebida",
  com registro de divergência de quantidade. É o modelo mais próximo da
  confirmação em dois toques que já roda em produção.

O que **não** existe: nenhuma coluna de estado numa tabela de apontamento, e
nenhum estado que signifique "previsto e ainda não confirmado".

### 5.3 Existe histórico de alteração?

| Registro | Histórico |
|---|---|
| Boletim | **Não.** Só o campo `editadoEm` no payload, que registra a data da última correção. O upsert substitui o payload inteiro; a versão anterior desaparece. |
| Unidade de manejo (plano) | **Sim** — `unidade_manejo_log`: uma linha por campo alterado, com `antes`, `depois`, `quem`, `quando`. É o único log de campo do projeto. |
| Plano de safra | **Sim, por versão** — nova linha em `plano_safra`, a anterior vira `superado`. Nada se apaga (não há política de DELETE em nenhuma tabela do plano). |
| Robôs | **Sim** — `relatorios_execucoes` (diário das rodadas) e `integracao_execucoes` (status HTTP de cada pedido à iCrop). |

Duas observações que o desenho precisa levar em conta:

- **O prazo de 48 h para o gerente corrigir é só de interface.** Está em
  `ACOES_PERFIL.corrigir_boletim` no `index.html`, e o próprio código diz a regra
  ("Isto é interface, não segurança"). No banco, a chave publishable pode dar
  upsert em qualquer `fazenda_id + data`, de qualquer data, sem limite e sem
  deixar rastro.
- **As políticas do plano permitem escrita pública.** `sql/005` cria, para as 11
  tabelas, política de `select using (true)`, `insert with check (true)` e
  `update using (true)`. "Só a tela de ADMIN escreve" é combinação, não trava.

### 5.4 O que o botão "Enviar boletim" grava

Na ordem em que acontece (`validarEnviar` → `concluirEnvio`, `index.html`):

1. **Barreiras antes de enviar** — botão inativo se o boletim está vazio; aviso
   se já existe boletim naquela data na unidade; **desde a v70, exige resposta em
   toda seção eventual** (registro ou "Nada a registrar hoje"); se houver avisos
   de conferência (dito × medido do iCrop), abre o diálogo com a lista.
2. **Limpa a resposta de seção que ganhou registro** e carimba quem respondeu.
3. **Aprende para a próxima vez, no aparelho:** últimas doses, receitas por
   operação, últimas operações e receitas por talhão, última fertirrigação,
   nomes de insumo novos, último evento de pecuária.
4. **Propõe abrir ciclo** dos talhões plantados no dia (grãos), num único
   diálogo.
5. **Grava o boletim** — se é novo, gera `id` e carimba
   `enviadoEm = data + hora`; se é correção, substitui o registro e carimba
   `editadoEm`.
6. **Enfileira para o Supabase:** `boletins` sempre; `boletim_pecuaria` se houver
   pecuária. A fila é offline: sobe na próxima sincronização.
7. **Gera as remessas** de café enviado para outra fazenda (status `enviada`).
8. Espelha a colheita de grãos, salva, apaga o rascunho e volta para a casa.

O que **não** grava: nada em tabela de operação, nada em tabela de estado,
nenhuma linha por atividade. Tudo vai dentro do JSON.

---

## 6. Bloco 5 — Comportamento observado

**Não apurável hoje.** O item existe, mas não há tempo de uso:

- A resposta explícita de ausência ("Nada a registrar hoje") entrou no main em
  **08/09/2026** (v69) e a exigência no envio em **08/09/2026** (v70). Hoje é
  **09/09/2026** — um dia.
- O que grava isso em tabela é `sql/047-secao-resposta.sql`, e o teste manual no
  `docs/qualidade-log.md` ainda está escrito como tarefa em aberto ("**Teste
  manual (Nilo, no iPhone).** Rodar `sql/047`"), sem marca de FEITO. Sem ele, as
  respostas existem **só dentro de `boletins.payload.secoes`** — dá para contar,
  mas não pela visão `vw_completude_boletim`.
- Além disso, os aparelhos dos gerentes só recebem a v70 depois de o service
  worker trocar o cache; o alcance real no primeiro dia é desconhecido.

**Sobre a segunda pergunta — "com que frequência 'sem ocorrência' é marcado em
poucos segundos após abrir o boletim":** ela **não é medível como está escrita**,
e é importante dizer isso antes de alguém tentar. O app **não guarda a hora em
que o boletim foi aberto**. O que existe é `secoes[id].em` (hora exata do toque
no chip, em ISO) e `enviadoEm` (data + hora do envio, **só até o minuto**).

O que **dá** para medir, e mede a mesma coisa, é o **carimbo em lote**: quando
duas ou mais seções eventuais são respondidas com poucos segundos entre uma e
outra, é toque automático em sequência, não leitura. O bloco SQL do fim já traz
essa contagem e a mediana de segundos entre a primeira e a última resposta do
mesmo boletim. Vale rodar de novo daqui a **duas ou três semanas** — antes disso,
qualquer número é ruído.

---

## 7. Tabela de lacunas

| # | O que é | Por que bloqueia a cadeia | O que resolveria |
|---|---|---|---|
| 1 | **Não há plano para grãos e pecuária** — nem estrutura, nem dado | Sem "Planejado", 2 das 3 atividades não têm o que confirmar; a confirmação em dois toques não tem objeto | Uma fonte de intenção para essas atividades (programação semanal do gerente ou do agrônomo). Decisão de negócio, não de código. Enquanto não houver, `operacao_janela` dá só "esperado por ritmo". |
| 2 | **O plano de café provavelmente não está no banco** (404 em 04/09/2026) | Sem `plano_*` populado e **publicado como vigente**, nem o café tem "Planejado" | Rodar `sql/005` → `006` → `007` (ou publicar pela tela Unidades e Plano). É a primeira linha do bloco SQL. |
| 3 | **26 das 69 unidades do plano não têm apelido `app`** | Para essas, previsto e registrado não se encontram: o farol fica cinza e o "Saldo" não fecha | Desmembrar talhões no app (muda os chips do gerente — versão própria) ou aceitar cobertura parcial e dizer isso na tela. |
| 4 | **O plano prevê insumo e kg por mês, não operação por data** | A cadeia é de **operação**; o plano de hoje é de **adubação**. `plano_gantt` tem operação, mas por mês e por modelo de empresa, não por unidade | Ou a cadeia nasce só para as operações que o Gantt cobre (16 atividades de café, granularidade de mês), ou o agrônomo passa a entregar operação × unidade × janela. |
| 5 | **`boletins` é uma linha por unidade-dia, com o boletim inteiro em JSON** | Não há onde gravar o estado de **uma** operação; confirmar em dois toques exige um registro com identidade e estado próprios | Tabela nova de execução por (unidade, operação, data, estado), alimentada pelo app. É mudança de modelo, não de tela — e é o item mais caro da Onda 2. |
| 6 | **Não há histórico de alteração do boletim** | "Confirmado por fulano às 14h" e depois desfeito não deixa rastro; a cadeia de estados vive de trilha | Tabela de eventos (append-only), no modelo de `unidade_manejo_log` ou de `plano_safra` (versão). Nada se apaga. |
| 7 | **O cadastro de talhões só existe no aparelho** | O plano aponta para `talhaoId`; o banco não sabe o que é `t093`. Nenhum cálculo de saldo por área fecha no servidor | Subir o cadastro de talhões (id, nome, unidade, área, tipo) para o Supabase, como já se fez com `rel_unidades`. |
| 8 | **iCrop e Solinftec conciliados por pedaço de nome** | Execução externa entrando na conta do "Realizado" errado, em silêncio | Trocar por identificador do fornecedor onde ele existir, ou migrar os dois para `unidade_alias` (que já tem os slots `icrop` e `solinftec` e é por igualdade exata). |
| 9 | **"Outra" e os termos extras de catálogo não têm id** | Registro feito por esses caminhos é invisível para a cadeia | Ou aceitar (e dizer que "Outra" fica fora), ou dar id ao termo extra no momento em que o escritório o cria. |
| 10 | **Produto, lote, cultivar e prestador são texto livre** | É o defeito do Sigma. Sem isso, "Saldo" em kg, em lote ou em produto não fecha | `docs/CAMPOS-LIVRES.md` já mapeou os 20 pontos e o esforço de cada um. Decisão campo a campo, pendente com o Nilo desde a v44. |
| 11 | **Não se sabe quanto o "Nada a registrar hoje" é carimbo automático** | Se for alto, a confirmação em lote da cadeia nasce com o mesmo vício | Rodar o bloco SQL daqui a 2–3 semanas e olhar "todas em até 10 s". |
| 12 | **`plano_*` aceita escrita com a chave pública** | Um plano é o "Planejado": se qualquer um pode gravar, o estado não é confiável | Restringir as políticas de insert/update das tabelas de plano. Já vale hoje, independente da Onda 2. |

---

## 8. Veredito

### **Viável parcialmente.**

Com precisão, porque "parcialmente" quer dizer coisas diferentes em cada
atividade:

**☕ Café (8 fazendas com deck), depois de rodar `sql/005`→`007` e publicar:**
os quatro estados são possíveis, com estas fronteiras:

- **Recomendado** — existe de verdade para **irrigação**, vindo do iCrop
  (percentímetro, lâmina mínima, tempo, déficit previsto), nas 4 fazendas com
  estação. Para o resto, não existe e não há de onde tirar.
- **Planejado** — existe para **adubação (kg por unidade e mês)**, **calagem
  (t e janela)** e **fito (alvos do mês)**, nas 43 unidades com apelido `app`.
  Para as outras 26, o plano existe e não encontra o registro.
- **Realizado** — existe hoje, com boa identidade: operação pelo catálogo, unidade
  pela chave do app.
- **Saldo** — calculável só onde Planejado e Realizado falam a mesma unidade de
  medida. Hoje **não falam**: o plano está em kg e t; o boletim registra o evento
  ("Adubação via lanço no talhão X"), não a quantidade. O saldo possível é de
  **evento** ("previsto no mês × registrado / sem registro"), que é exatamente o
  que o relatório `plano_executado_mes` já faz — não é saldo de quantidade.

**🌾 Grãos e 🐂 Pecuária:** sem "Planejado" e sem "Recomendado". Sobra
**Realizado + farol de ritmo**, que é o que a Onda 1 já entregou
(`vw_dias_sem_registro`, `vw_farol_registro`, `vw_ritmo_operacoes`). Uma cadeia
de estados aqui seria uma etiqueta nova sobre o mesmo dado.

**E uma pré-condição que vale para as três, e que não é sobre o plano:** a
confirmação em dois toques precisa gravar **um registro por operação, com estado
próprio e trilha**. O `boletins` de hoje não comporta isso: é um documento por
dia, sobrescrito a cada correção. Enquanto esse registro não existir, "confirmar
o previsto" vira mais um campo dentro do mesmo JSON — e aí a cadeia é enfeite,
não modelo.

**Recomendação de sequenciamento** (é opinião, não apuração):

1. Rodar `sql/005`→`007` e publicar pelo menos uma fazenda. Sem isso não há o que
   desenhar, e o custo é uma tarde de SQL Editor.
2. Subir o cadastro de talhões para o Supabase (lacuna 7). É pequeno, destrava a
   lacuna 3 e serve a tudo, não só à Onda 2.
3. Só então decidir entre: (a) cadeia completa **só de café**, sobre adubação /
   calagem / fito, aceitando a cobertura de 43 unidades; ou (b) adiar a cadeia e
   entregar antes o registro por operação com estado (lacunas 5 e 6), que é a
   fundação que ela vai precisar de qualquer jeito.

---

## 9. Bloco SQL de leitura — para o Nilo rodar

Este bloco **só lê**. Não cria, não altera e não apaga nada. Ele responde as
perguntas que dependem do banco e que eu não consegui apurar daqui.

**Como fazer, pelo iPhone:**

1. Abra o **Supabase** (o projeto `syvehtgrbqteyuqhoban`).
2. Toque em **SQL Editor**.
3. Cole **o bloco inteiro** de uma vez (é uma consulta só).
4. Toque em **Run**.
5. Copie o resultado (são cerca de 39 linhas, em 3 colunas) e mande de volta.

Se aparecer algum erro, copie a mensagem inteira e mande também — não tente
consertar.

```sql
-- Boletim NCNaves — raio-X de leitura para a investigação da cadeia de estados.
-- SÓ LÊ. Não cria, não altera e não apaga nada.
with alvo(bloco, item) as (values
  ('1 plano',      'plano_safra'),      ('1 plano',      'plano_unidade'),
  ('1 plano',      'plano_adubo_mes'),  ('1 plano',      'plano_calagem'),
  ('1 plano',      'plano_fito_mes'),   ('1 plano',      'plano_gantt'),
  ('1 plano',      'plano_parametros'), ('1 plano',      'unidade_manejo'),
  ('1 plano',      'unidade_alias'),
  ('2 fontes',     'icrop_manejo'),     ('2 fontes',     'solinftec_diario'),
  ('3 identidade', 'rel_unidades'),     ('3 identidade', 'operacao_catalogo'),
  ('3 identidade', 'operacao_alias'),   ('3 identidade', 'operacao_janela'),
  ('3 identidade', 'solinftec_depara'), ('3 identidade', 'rel_icrop_depara'),
  ('4 apontamento','boletins'),         ('4 apontamento','pos_colheitas'),
  ('4 apontamento','remessas'),         ('4 apontamento','boletim_pecuaria'),
  ('5 secoes',     'boletim_secao'),    ('5 secoes',     'boletim_secao_resposta')
),
tab as (
  select bloco, 'tabela '||item as item,
    case when to_regclass('public.'||item) is null then 'NAO EXISTE'
         else (xpath('/row/c/text()', query_to_xml(
                'select count(*) as c from public.'||item, false, true, '')))[1]::text || ' linhas'
    end as resposta
  from alvo
),
b as (select fazenda_id, data, payload from public.boletins
      where coalesce((payload->>'exemplo')::boolean, false) = false),
lst as (select e from b cross join lateral jsonb_array_elements(
    case when jsonb_typeof(payload->'atividades')='array' then payload->'atividades' else '[]'::jsonb end) e),
nomes as (
  select p->>'nome' as nome from lst, lateral jsonb_array_elements(
    case when jsonb_typeof(e->'insumos')='array' then e->'insumos' else '[]'::jsonb end) p
  union all
  select p->>'nome' from lst, lateral jsonb_array_elements(
    case when jsonb_typeof(e->'produtos')='array' then e->'produtos' else '[]'::jsonb end) p),
nome_ok as (
  select btrim(nome) as nome,
    upper(translate(btrim(nome),'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
                                'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC')) as chave
  from nomes where coalesce(btrim(nome),'') <> ''),
secs as (select payload from b where jsonb_typeof(payload->'secoes')='object'),
resp as (
  select (select min((v->>'em')::timestamptz) from jsonb_each(payload->'secoes') s(k,v)
            where v->>'em' ~ '^\d{4}-\d{2}-\d{2}T') as ini,
         (select max((v->>'em')::timestamptz) from jsonb_each(payload->'secoes') s(k,v)
            where v->>'em' ~ '^\d{4}-\d{2}-\d{2}T') as fim,
         (select count(*) from jsonb_each(payload->'secoes') s(k,v)
            where v->>'resposta'='sem_ocorrencia') as n
  from secs),
extra(bloco, item, resposta) as (
  select '1 plano','planos com status vigente',
    case when to_regclass('public.plano_safra') is null then 'sem a tabela plano_safra'
    else (xpath('/row/c/text()', query_to_xml(
      'select count(*) as c from public.plano_safra where status = ''vigente''', false,true,'')))[1]::text end
  union all select '3 identidade','grafias de operacao sem de-para no catalogo',
    case when to_regclass('public.operacao_alias') is null then 'sem a tabela operacao_alias'
    else (xpath('/row/c/text()', query_to_xml($q$
      select count(distinct t) as c from (
        select e->>'tipo' as t from public.boletins b cross join lateral jsonb_array_elements(
          case when jsonb_typeof(b.payload->'atividades')='array' then b.payload->'atividades' else '[]'::jsonb end) e
        where coalesce(e->>'tipo','') <> '') x
      where t not in (select termo from public.operacao_alias where origem = 'atividades.tipo')
    $q$, false,true,'')))[1]::text end
  union all select '3 identidade','grafias distintas de operacao gravadas', count(distinct e->>'tipo')::text
    from lst where coalesce(e->>'tipo','') <> ''
  union all select '3 identidade','operacoes gravadas como "Outra"', count(*)::text from lst where e->>'tipo'='Outra'
  union all select '3 identidade','grafias distintas de produto/insumo', count(distinct nome)::text from nome_ok
  union all select '3 identidade','produtos com mais de uma grafia', count(*)::text
    from (select chave from nome_ok group by chave having count(distinct nome)>1) g
  union all select '4 apontamento','boletins reais (fora os de exemplo)', count(*)::text from b
  union all select '4 apontamento','unidades com boletim', count(distinct fazenda_id)::text from b
  union all select '4 apontamento','1o e ultimo boletim',
    coalesce(min(data)::text,'-')||' a '||coalesce(max(data)::text,'-') from b
  union all select '4 apontamento','linhas de atividade dentro dos payloads', count(*)::text from lst
  union all select '4 apontamento','RLS e policies de boletins',
    (select case when relrowsecurity then 'RLS ligado' else 'RLS DESLIGADO' end
       from pg_class where oid = 'public.boletins'::regclass)
    || ' · ' || coalesce((select string_agg(cmd||' '||policyname, ' · ' order by policyname)
       from pg_policies where schemaname='public' and tablename='boletins'), 'sem policy')
  union all select '4 apontamento','colunas status/estado/situacao no banco',
    coalesce((select string_agg(table_name||'.'||column_name, ' · ' order by table_name, column_name)
      from information_schema.columns
      where table_schema='public' and column_name in ('status','estado','situacao')), 'nenhuma')
  union all select '5 secoes','boletins com o campo secoes no payload', count(*)::text from secs
  union all select '5 secoes','boletins com "Nada a registrar hoje"', count(*)::text from resp where n>0
  union all select '5 secoes','com 2+ respostas: todas em ate 10 s', count(*)::text
    from resp where n>1 and fim-ini <= interval '10 seconds'
  union all select '5 secoes','com 2+ respostas: mediana de segundos entre a 1a e a ultima',
    coalesce(round(percentile_cont(0.5) within group (order by extract(epoch from (fim-ini))))::text,'-')
    from resp where n>1
)
select bloco, item, resposta from tab
union all select bloco, item, resposta from extra
order by 1, 2;
```

**Como o bloco foi conferido antes de chegar aqui:** rodado num PostgreSQL 16
local, em dois cenários — (a) banco com `boletins`, `operacao_catalogo`,
`operacao_alias`, `rel_unidades`, `icrop_manejo` e `solinftec_diario` e **sem** as
tabelas de plano; (b) banco com `plano_safra` presente, `data` do boletim como
texto e um carimbo de hora inválido no payload. Nos dois casos: 39 linhas, sem
erro, tabela que não existe aparece como `NAO EXISTE` em vez de derrubar a
consulta, e a contagem de grafias juntou corretamente `SULFATO DE MANGANES`,
`Sulfato de manganes` e `sulfato de Manganês` como o mesmo produto com 3 grafias.

**Como ler o resultado:**

| Se aparecer | Quer dizer |
|---|---|
| `tabela plano_safra · NAO EXISTE` | o `sql/005` nunca foi rodado — a estrutura do plano não existe |
| `tabela plano_safra · 8 linhas` + `planos com status vigente · 0` | as tabelas existem, o seed entrou, **mas nada foi publicado** — o app não lê |
| `planos com status vigente · 8` | o café tem "Planejado" de verdade |
| `grafias de operacao sem de-para no catalogo` alto | há registro que a cadeia não enxerga (termos extras, "Outra", grafia antiga) |
| `produtos com mais de uma grafia` alto | é o caso do Sigma acontecendo aqui |
| `RLS DESLIGADO` em `boletins` | qualquer um com a chave pública lê e grava boletim |
| `com 2+ respostas: todas em ate 10 s` alto | carimbo automático — a confirmação em lote precisa nascer protegida |

---

## 10. Coisas que provavelmente ninguém sabe que estão (ou não estão) no banco

Encontradas por acidente, todas verificadas no código. Nenhuma é urgente; três
são incômodas.

1. **"Marcar como visto" nunca sai do celular.** O botão da Diretoria grava
   `b.visto` no aparelho e **não entra na fila de sincronização**. Pior: na
   sincronização seguinte o boletim é rebaixado pela cópia do servidor, que não
   tem esse campo — ou seja, **o "visto" é apagado sozinho**. Quem marcou acha
   que marcou; ninguém mais vê, e depois nem quem marcou.
2. **Todo o cadastro vive só no aparelho.** Talhões, máquinas, insumos, usuários,
   ciclos de grãos, inventário de pecuária e os termos extras dos catálogos estão
   em `localStorage`, nunca no Supabase. Um talhão criado em Cadastros existe só
   naquele iPhone. Se o aparelho for trocado ou o navegador limpo, o cadastro
   volta ao que veio dentro do `index.html`.
3. **Operação lançada como "Outra" some dos faróis.** Ela é excluída de propósito
   do catálogo (`operacao_catalogo`), então não tem id — e tudo que é farol,
   ritmo, dias sem registro e relatório passa por id. O mesmo vale para qualquer
   termo que o escritório acrescente em Cadastros › Catálogos.
4. **O prazo de 48 h de correção é combinado, não trancado.** A trava está na
   tela; o banco aceita gravar boletim de qualquer data, quantas vezes quiser.
5. **Corrigir um boletim apaga a versão anterior.** É um upsert por unidade+dia:
   fica só o `editadoEm` dizendo que houve correção, sem dizer o que mudou.
6. **O iCrop já entrega recomendação, e ela já está gravada.** Percentímetro
   recomendado, lâmina mínima, tempo de irrigação e déficit previsto estão em
   `icrop_manejo.bruto` desde a v47. Se um dia se quiser um "Recomendado" de
   verdade na tela, ele já existe — para irrigação.
7. **As tabelas do plano aceitam escrita com a chave pública.** `sql/005` cria
   políticas de insert e update com `true`. "Só o ADMIN escreve" é a tela, não o
   banco.
8. **O robô do iCrop não está no repositório.** Ele vive só dentro do Supabase.
   O `ESTADO.md` cita um arquivo `sql/003-robo-icrop-reforco.sql` que **não
   existe** em `sql/`. Se o projeto do Supabase se perder, o robô se perde junto
   — vale exportar as três funções para o repositório numa tarefa qualquer.
9. **`relatorios_gerados.texto` guarda texto escrito por IA.** O robô-redator
   (sql/030) chama a API da Anthropic pela madrugada e grava o texto no banco.
   Está sinalizado na tela ("gerado automaticamente — revisar antes de enviar"),
   mas quem olhar a tabela direto vê texto de máquina misturado a número medido.
10. **`solinftec_operacoes` está vazio.** Por isso a tela mostra "Operação NNN":
    falta a Solinftec mandar a lista de código → nome. É pendência antiga, e
    atrapalha qualquer cruzamento de máquina com operação do catálogo.

---

*Investigação de leitura. Nenhum arquivo do app, nenhuma tabela e nenhuma
política foram alterados.*
