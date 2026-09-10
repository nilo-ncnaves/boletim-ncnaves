# Investigação — cadeia de estados (Recomendado → Planejado → Realizado → Saldo)

Apuração para decidir se a Onda 2 pode abrir com a cadeia de estados e a
confirmação em dois toques.

> **Leia esta nota antes do resto.** A apuração foi feita em **09/09/2026**
> sobre a **v74**. Entre a apuração e a entrega deste relatório entraram no
> `main` as versões **v75, v76, v77 e v78** — e três delas constroem
> exatamente aquilo que a investigação tinha ido apurar se dava para
> construir. O relatório foi **reescrito em 10/09/2026 contra a v78**. A
> seção 2 conta o que mudou e o que da apuração original sobreviveu; o
> restante já está atualizado.

**Nada foi alterado** nesta tarefa: nenhuma tabela, visão, função, índice ou
política foi criada, mudada ou apagada, e nenhum SQL de escrita foi executado.

**Base da apuração.** Leitura completa de `CLAUDE.md`, `ESTADO.md`, `docs/`
(incluindo `PLANO-DE-SAFRA.md`, `PLANO-2627-AUDITORIA.md`, `CAMPOS-LIVRES.md`,
`relatorios.md`, `catalogos-por-atividade.md`, `qualidade-log.md`), de todos os
arquivos em `sql/` e do `index.html` — na v74 e, na reescrita, na v78.

**Limite desta apuração.** Não houve leitura do banco real. Tentei uma consulta
somente-leitura pela API pública do Supabase e o ambiente da sessão bloqueou a
chamada. Por isso **tudo que depende do estado atual do banco está marcado
"não apurado"** e vai no bloco SQL da seção 9. O que está afirmado sem essa
marca vem do código e da documentação da v78, que são fato.

---

## 1. Resumo em cinco linhas

1. **Existe plano no banco?** Existem **dois planos diferentes, e eles não se
   falam.** O do agrônomo (`plano_safra`, adubação/calagem/fito de café)
   continua **escrito e não rodado** no Supabase. O **plano de execução**
   (tarefas da ata mensal e da semana, `planejamento_tarefa`, e o plano do dia
   seguinte dentro do boletim) **nasceu na v75/v77, vale para as três
   atividades** e está no aparelho — no banco, só quando o `sql/050` rodar.
2. **Como o plano entraria?** O do agrônomo, só por carga manual de PPTX, uma
   vez por versão. O de execução **já entra sozinho**: ata colada pelo
   escritório, tarefa da semana, plano do dia seguinte em chips pelo gerente.
   O iCrop segue como a única fonte de "Recomendado" automática — e só de
   irrigação. A Solinftec só entrega execução; o ERP não está integrado.
3. **Identidade das entidades?** A unidade operacional (`f01`, `f03c`…) e a
   operação (`operacao_catalogo.id`, com apelidos por igualdade exata) têm
   chave estável, e a v76 provou isso ao renomear operações **sem quebrar
   boletim antigo**. Mas o elo **tarefa → operação é feito por casamento de
   texto** da descrição da ata, o cadastro de talhões continua só no aparelho,
   e produto/lote/cultivar seguem em texto livre.
4. **Como o apontamento é gravado?** `boletins` continua **uma linha por
   unidade-dia**, com tudo num JSON, sobrescrita na correção e sem histórico.
   Mas agora existe, **ao lado**, um registro com identidade e estado próprios:
   `planejamento_tarefa`, com 6 status, prazo, unidade e trilha de alteração.
5. **Comportamento observado?** **Não apurável.** O "Nada a registrar hoje" tem
   dois dias de main; o módulo de planejamento tem um. E a pergunta "quantos
   segundos após abrir o boletim" **não é medível**: o app não guarda a hora de
   abertura.

**Veredito: viável parcialmente — e bem mais perto do que estava há dois dias.**
Detalhe na seção 8.

---

## 2. O que mudou entre a apuração e este relatório (v75 → v78)

Quatro versões entraram no `main` em 10/09/2026. Três mexem no coração desta
investigação.

### 2.1 v75 — plano do dia seguinte × executado (três atividades)

O gerente planeja o dia seguinte em chips ao fechar o boletim (ONDE → O QUÊ →
pessoas previstas, até 3 linhas) e, no dia seguinte, **o app confere sozinho**:
a caixinha de cada linha vai de ⚪ para ◐/✅ conforme os lançamentos entram, no
lugar, sem ninguém digitar status.

- **Onde mora:** `D.planoDia` enquanto o dia-alvo não fecha; ao enviar o
  boletim do dia-alvo, `gravarPlanoNoBoletim` fecha o plano **dentro do
  boletim**, em `b.plano`. Como vive no payload de `boletins`, **sincroniza
  pelo caminho que já existia** — nenhuma tabela nova.
- **Status (`avaliarPlano`), sempre sobre REGISTRO:** ✅ todos os "onde" do item
  com registro; ◐ parte deles ou registro "continua amanhã"; ⚪ nenhum.
- Correlações calculadas, nada digitado: aderência em 7 e 30 dias, motivos,
  desvios evitáveis × de clima, dias trabalháveis × impedidos, precisão de
  esforço (pessoas previstas × lançadas).
- Supabase: `sql/048` (visão `vw_plano_x_executado` + relatório mensal) —
  **falta rodar**.

### 2.2 v76 — nomenclatura do café, e a prova de que a identidade aguenta

As operações do café foram renomeadas para a palavra da lavoura. O jeito como
isso foi feito **é a melhor evidência desta investigação** de que a chave da
operação é estável:

- operações novas entram em `operacao_catalogo` com o grupo na coluna `fase`;
- o nome antigo vira **apelido** em `operacao_alias`;
- as renomeadas 1 para 1 são **desativadas** (`ativo = false`), nunca apagadas;
- boletim antigo gravado com "Desbrota" continua na tela mostrando "Desbrota
  manual", com o dado bruto intacto; plano gravado com nome antigo fecha como
  feito com registro no nome novo, e o contrário também.

Supabase: `sql/049` — **falta rodar**.

### 2.3 v77 e v78 — módulo de planejamento, e o "Saldo" existindo de fato

A mesma tarefa vista em dois horizontes (reunião mensal e semana); concluir num
atualiza o outro, sem cópia. É aqui que a cadeia aparece inteira:

- **Planejado** — a ata da reunião entra por **colagem**, com pré-visualização
  editável item a item; reimportar não duplica. A semana nasce sozinha na
  sexta. A meta é a área que a ata trouxe (`t.area`) ou a que o escritório
  informar (`t.meta`).
- **Realizado** — a soma da área dos **talhões distintos** com lançamento
  casado, na janela da tarefa (de "Comecei" até "Concluí"; depois congela).
- **Saldo** — `planProgresso` devolve **planejado · executado · restante** com
  barra, arredondando antes de subtrair para os três fecharem na tela. Sem
  meta, **não inventa denominador**: conta os lançamentos e diz isso com todas
  as letras.
- **Rastreabilidade** — um toque no "executado" abre a lista dos lançamentos
  que o compuseram: data, local, área e quem lançou.
- **Confirmação em um toque** — na folha do gerente: *Comecei · Concluí ·
  Travado* (com chips de motivo) · "💬 Falar com o Nilo". Zero campo de
  digitação, zero diálogo, nada bloqueia o boletim.
- **A sugestão de dois toques já existe** — quando a descrição casa com uma
  operação e o registro entra no boletim do dia: *"Você lançou levantar café
  hoje — concluir a tarefa?"*, com os chips "Concluí" e "ainda não". Tarefa de
  estrutura nunca recebe sugestão.
- **A outra metade** — 🧾 Executado fora do plano: os lançamentos que não
  casaram com tarefa nenhuma, agrupados por operação. A tela diz, em letras,
  que **não é cobrança**.
- Supabase: `sql/050` (as três tabelas + `vw_planejamento_mes`) e `sql/051`
  (relatório `ata_x_executado`) — **faltam rodar**. Enquanto isso o módulo
  funciona inteiro no aparelho e as tarefas ficam na fila de sincronização.

### 2.4 O que da apuração original caiu, e o que sobreviveu

| Conclusão da v74 | Situação na v78 |
|---|---|
| "Grãos e pecuária não têm plano nenhum" | **Caiu.** A v75 deu plano do dia seguinte às três atividades; a v77 deu tarefas de ata e de semana às três. |
| "Não há onde gravar o estado de uma operação" | **Caiu.** `planejamento_tarefa.status` com 6 estados, e `b.plano[].status` por item do plano do dia. |
| "Não há histórico de alteração" | **Caiu para a tarefa.** `payload.historico` (quem, quando, de → para, motivo); "cancelar é status, nunca delete". Continua valendo para o **boletim**. |
| "Saldo não fecha, o plano está em kg e o boletim registra evento" | **Caiu para a tarefa** (planejado/executado/restante em ha). **Continua valendo** para o plano do agrônomo, que segue em kg. |
| Plano do agrônomo não rodado no Supabase | **Sobreviveu** — o `ESTADO.md` da v78 ainda lista `sql/005`→`007` como pendentes. |
| Identidade por pedaço de nome no iCrop e na Solinftec | **Sobreviveu**, intocado. |
| Cadastro de talhões só no aparelho | **Sobreviveu** — e agora dói mais (a projeção de ritmo e a meta em ha dependem da área do talhão). |
| `boletins` é uma linha por unidade-dia, sobrescrita, sem histórico | **Sobreviveu**, intocado. |
| Produto, lote, cultivar em texto livre | **Sobreviveu** — `docs/CAMPOS-LIVRES.md` segue sem decisão. |

---

## 3. Bloco 1 — Existe plano no banco?

Existem **dois planos**, com donos, formatos e finalidades diferentes. Confundir
os dois é o erro mais fácil de cometer no desenho da Onda 2.

### 3.1 Plano A — o do agrônomo (`plano_safra`, só café)

Estrutura escrita em `sql/005-plano-safra.sql`, 11 tabelas. As que guardam
intenção futura:

| Tabela | O que guarda | Colunas que importam |
|---|---|---|
| `plano_safra` | a versão do plano de uma fazenda numa safra | `fazenda_app`, `safra`, `versao`, `status` (rascunho → vigente → superado), `aprovado_por`, `auditoria_ok` |
| `plano_unidade` | quais unidades a versão cobre | `unidade_id`, `area_ha_plano`, `safra_zerada_tipo` |
| `plano_adubo_mes` | **adubação prevista por unidade, mês e insumo** | `mes` (1–12), `insumo` (8 valores fechados), `kg`, `via` |
| `plano_calagem` | calagem prevista com janela | `subarea`, `t_ha`, `t_total`, `janela_ini`, `janela_fim` |
| `plano_fito_mes` | calendário fitossanitário do grupo | `mes`, `fase`, `alvos[]`, `produtos[]` |
| `plano_gantt` | **janela do ano por atividade** (modelo NC / NR) | `atividade` (slug), `meses[]`, `tipo`, `evidencia_app` |

Três coisas que o desenho precisa saber:

- **A unidade do plano não é a unidade operacional.** `plano_*` aponta para
  `unidade_manejo` — o setor de café (`VEC-S08`), não `f22c`. A ligação com o
  app é `unidade_alias` com `sistema = 'app'`, cujo apelido é o **id do
  talhão** (`t093`).
- **É previsão de insumo e quantidade por mês, não de operação por data.** A
  previsão de operação existe só no `plano_gantt`, em granularidade de mês ×
  atividade × modelo de empresa — não por unidade.
- **Cobertura:** só café, **8 de 24 unidades**, 69 unidades de manejo, das
  quais **43 têm apelido `app` e 26 não têm** — para essas, o plano existe e
  não tem como encontrar o registro do gerente.

**Está populado? Quase certamente não.** O `ESTADO.md` da v78 ainda lista
"Rodar `sql/005` e depois `sql/006`" como pendência aberta, e
`docs/relatorios.md` registra que as URLs de `plano_*` respondiam 404 em
04/09/2026. **Não apurado:** se o Nilo rodou depois. É a primeira linha do
bloco SQL. E note a diferença: hoje não existe nem a tabela vazia.

### 3.2 Plano B — o de execução (`planejamento_*` + `b.plano`, três atividades)

Nasceu na v75/v77. É este que a cadeia de estados pode usar.

```
planejamento_rodada   id · ref (AAAA-MM) · payload            -- a ata do mês
planejamento_semana   id · ini (segunda) · payload            -- a semana
planejamento_tarefa   id · unidade_id · prazo · status · payload
                      status ∈ a_iniciar | em_execucao | finalizado
                              | aguardando_terceiro | aguardando_clima | cancelado
                      payload.historico = quem, quando, de → para, motivo
                      payload.exec = {ha, n, meta, em}  -- a foto que o relatório lê
```

Mais `b.plano` dentro do payload de `boletins`: o plano do dia seguinte, com
status por item, motivo, clima declarado e pessoas previstas × lançadas.

**Está populado?** **Não apurado.** O `sql/050` consta como pendente; enquanto
não rodar, tudo vive no aparelho e as tarefas ficam na fila de sincronização —
o `ESTADO.md` é explícito em que **nada se perde**, sobe tudo quando as tabelas
existirem.

### 3.3 Outras formas de intenção futura no banco

| Onde | O que é | Cobertura |
|---|---|---|
| `operacao_janela` (`sql/042`) | **cadência esperada** de registro por operação | 10 linhas, todas `origem = 'proposta'`: 9 de pecuária, 1 de grãos |
| `icrop_manejo.bruto` | **recomendação de irrigação do iCrop** | as 4 fazendas com estação |
| `plano_calagem.janela_ini/fim` | janela de data | só café, dentro do plano A |

`operacao_janela` é expectativa de **ritmo**, não plano: não diz data, nem
quantidade, nem unidade. Serve de farol.

---

## 4. Bloco 2 — Como o plano entraria

### 4.1 Rotinas que existem hoje

| Rotina | De onde | Para onde | Frequência | Código |
|---|---|---|---|---|
| Robô iCrop | API iCrop Vision | `icrop_manejo`, `icrop_fazendas`, `icrop_parcelas` | 03h50 / 04h05 / 04h20 + reforço 09h45–10h15 | **Só no Supabase** |
| Robô Solinftec | API Detalhes da Operação V3 | `solinftec_diario` | 03h05 + de hora em hora, 09h35–20h35 | `sql/003` |
| Motor de relatórios | as acima + `boletins` | `relatorios_gerados` | pg_cron 05:00 BRT | `sql/020` |
| Robô-redator | `relatorios_gerados.dados` → API Anthropic | `relatorios_gerados.texto` | junto com o relatório | `sql/030` |
| **Ata da reunião** | **texto colado pelo escritório** | `planejamento_rodada` + `_tarefa` | **mensal, por volta do dia 10** | `index.html` |
| **Plano do dia seguinte** | **chips do gerente, ao enviar** | `D.planoDia` → `b.plano` | **diária** | `index.html` |
| Plano do agrônomo | 7 PPTX | `plano_*` | **manual, uma vez por versão** | 4 scripts → `sql/006` |
| Telemetria | arquivo importado na tela | `telemetria` | quando importam | `index.html` |

A diferença que importa: **o plano de execução já tem entrada de rotina, feita
por quem tem a informação.** O do agrônomo continua sendo uma obra de quatro
passos manuais, com conferência que trava se as somas não baterem.

**O código do robô iCrop não está no repositório.** O `ESTADO.md` cita
`sql/003-robo-icrop-reforco.sql`, que não existe em `sql/`. Se o projeto do
Supabase se perder, o robô se perde junto.

### 4.2 O que o iCrop efetivamente traz

Pelo `select` de `baixarIcrop()` e pelas fontes dos relatórios 6, 15 e 18,
`icrop_manejo` tem colunas próprias (`fazenda`, `equipamento`, `parcela`,
`data`, `irrigacao_mm`, `precipitacao_mm`, `etc`, `eto`) e uma coluna `bruto`
de onde o app lê:

- **Recomendação:** `percentimetro_recomendado`, `tempo_de_irrigacao`,
  `lamina_minima`, `deficit_previsto`, `dias_em_atraso`.
- **Medição / estado:** `umidade`, `capacidade_de_campo`,
  `umidade_de_seguranca`, `deficit_consolidado`, `fase_atual`,
  `acumulado_irrigacao`, `eficiencia_irrigacao`, `problemas_irrigacao`.
- **Clima e custo:** temperatura, UR, vento, chuva do pluviômetro;
  `reais_mm_ha`, `reais_por_irrigacao_necessaria/realizada`.

**O iCrop é uma fonte de "Recomendado" de verdade, já gravada e já na tela**
(cartão "iCrop", linha "Recomendação iCrop"). Mas é recomendação **de
irrigação, por parcela e por dia**, nas 4 fazendas com estação.
`icrop_parcelas` traz parcelas ativas com fim de ciclo — cadastro e
vencimento, não programação de serviço.

### 4.3 O que a Solinftec expõe

`solinftec_diario` só tem execução: `data`, `equipamento`, `cd_operacao`,
`operacao`, `talhao`, `horas`, `motor_h`, `ocioso_h`, `area_ha`, `consumo_l`.
Nenhuma coluna de previsão ou ordem de serviço. **Não apurado:** se a Solinftec
tem outro endpoint com ordem de serviço — pergunta para o fornecedor.

### 4.4 Decisão anterior sobre importar os planos do agrônomo

Registrada em `docs/PLANO-DE-SAFRA.md`: o plano é "referência e comparação",
**não é receituário**; versão nova entra por PPTX → extrator → resolver nomes
contra `unidade_alias` → rascunho → auditoria → publicar, nunca editando a
vigente. E ficou de fora **de propósito**: "Solinftec/iCrop cruzados com o
plano, kg do ERP, trilha de produção, estimativa automática, robô semanal…"

---

## 5. Bloco 3 — Identidade das entidades

A resposta curta: **as duas chaves centrais são estáveis e a v76 provou isso na
prática. O elo novo — tarefa → operação — é por texto.**

### 5.1 Unidade operacional

| Fonte | Chave | Estável? |
|---|---|---|
| `boletins`, `pos_colheitas`, `remessas`, `boletim_pecuaria` | `fazenda_id` = id do app (`f01`, `f03c`…) | **Sim** |
| `rel_unidades` (`sql/020`) | a mesma, espelhada, 24 unidades | **Sim** |
| **`planejamento_tarefa`** | **`unidade_id`, normalizado por gatilho** (`plan_normalizar` chama `rel_fz_atual`, então id antigo cai na unidade de hoje) | **Sim — e é o melhor de todos** |
| `unidade_manejo` (plano A) | `codigo` (`VEC-S08`), com gatilho que **impede** mudar | **Sim**, mas é outro nível (setor) |
| `solinftec_diario` | `fazenda_id` via `solinftec_depara`: **pedaço do nome em minúsculas** | **Não** |
| `icrop_manejo` | sem coluna de unidade; o app decide por `DEPARA_ICROP`, **também pedaço de nome**, e separa café × grãos procurando "cafe" no nome do equipamento | **Não** |
| **Fazenda na ata** | `deparaAtaDe`: chave exata e, se falhar, **`includes` para chaves > 3 letras** | **Parcial** — mas nome não reconhecido **não é adivinhado**: vai para a pré-visualização, e o de-para é editável em Cadastros |
| Talhão | `talhaoId` (`t093`) dentro do JSON | Chave estável, **cadastro fora do banco** (5.5) |

### 5.2 Operação / serviço — e a prova da v76

**Tem catálogo e chave substituta**, e é o achado mais favorável desta
investigação:

- `operacao_catalogo` (`sql/040`, atualizado pelo `sql/049`): id de texto
  imutável (`CAFE-PULVERIZACAO`), com `atividade`, `fase`, `nome`, `ordem`,
  `ativo`. O comentário da tabela é explícito: "Identidade = id".
- `operacao_alias`: de-para do texto exato do payload → id, **por igualdade
  exata, nunca LIKE**, com a coluna `origem` dizendo em que caminho do JSON o
  texto mora.
- **A v76 renomeou operações de café e nada quebrou** — nome antigo virou
  apelido, renomeada 1 para 1 foi desativada sem apagar, boletim antigo
  continua legível e o plano fecha nos dois sentidos. É a demonstração de que
  o modelo aguenta mudança de nome.
- O gerente **não digita** operação: escolhe em chip ou seletor do catálogo.

### 5.3 O elo novo, e onde ele é frágil

`planejamento_tarefa` guarda `unidade_id` (id) e `status` (enum), mas **não
guarda o id da operação**. O casamento tarefa → operação é feito em
`planOperacoesDe(t)`, no aparelho, **por texto da descrição da ata**:

1. tabela de sinônimos `PLAN_SINONIMOS[atividade]` — descrição contém a chave;
2. senão, qualquer palavra de **5 letras ou mais** do nome da operação que
   apareça na descrição.

É a decisão certa para o problema (a ata é texto humano, escrito na reunião), e
o app é honesto quando falha: *"A descrição não casa com nenhuma operação do
catálogo — o app não consegue somar sozinho."* Mas é bom não se iludir:
**o número de "executado" de uma tarefa depende de casamento de palavras.**
Duas consequências práticas:

- descrição escrita de outro jeito na ata do mês que vem → a tarefa deixa de
  somar, em silêncio, e cai no "fora do plano";
- palavra de 5 letras compartilhada por duas operações → soma a mais.

O caminho de conserto já existe e é barato: guardar na tarefa o **id da
operação** escolhido na pré-visualização da ata (que já é editável item a
item), e usar o texto só como sugestão inicial.

### 5.4 Duplicidade — onde o defeito do Sigma mora

O caso `SULFATO DE MANGANES` × `Sulfato de manganes` é o risco já mapeado em
`docs/CAMPOS-LIVRES.md` (v44), com **20 pontos de digitação livre**. Os de
risco ALTO:

| # | Campo livre | Por que quebra |
|---|---|---|
| 1 | Produto / defensivo da receita | "mesmo defensivo com 3 grafias impede fechar custo e rastrear carência" |
| 2 | Produto / vacina (pecuária) | controle sanitário vira texto solto |
| 5 | Cultivar / híbrido | censo de plantio e ciclos dependem disso |
| 11 | Lote / categoria (pecuária) | sem lote padronizado não há GMD nem contagem |
| 13 | Lote (terreiro → secador → tulha → benefício) | o mesmo lote em 4 lugares, como texto |
| 7 | Prestador terceirizado | comparar preço e desempenho não fecha |

**Não apurado:** quantas grafias divergentes já existem. O bloco SQL conta
exatamente isso, ignorando acento e caixa.

### 5.5 O cadastro de talhões continua fora do banco

- `D` (fazendas, **talhões**, máquinas, insumos, usuários, ciclos, inventário
  de pecuária, catálogos extras, **de-para da ata**) vive em `localStorage`,
  na chave `bdf:dados`.
- A fila de sincronização carrega **nove tipos**: boletim, pós-colheita,
  remessa, telemetria, código de acesso, espelho de pecuária e — novos na v77 —
  `tar`, `rod`, `sem`. **Nenhum cadastro sobe.**
- Um talhão criado em Cadastros **não existe** no Supabase nem no aparelho de
  mais ninguém. `docs/relatorios.md` confirma pelo outro lado: "Nomes de talhão
  vivem no cadastro do `index.html`".

**Isto piorou com a v78.** A meta em hectares e a projeção de ritmo saem da
**área do talhão** — que só existe no celular. Duas pessoas com cadastros
diferentes veem "executado" diferente para a mesma tarefa. E o `ESTADO.md`
já registra o sintoma: Igrejinha e Lazaro entraram com **0 ha**, e sem isso
não há projeção.

### 5.6 De-paras que existem

| De-para | Liga | Como |
|---|---|---|
| `operacao_alias` | texto do payload → operação | igualdade exata ✔ |
| `unidade_alias` | unidade do plano → deck, talhão do app, Solinftec, iCrop, AgroGestão | igualdade exata, com vigência ✔ |
| `FZ_LEGADO` / `rel_fz_atual` | id antigo de fazenda → unidade atual | igualdade exata ✔ |
| `DEPARA_ATA_PADRAO` | nome da fazenda na ata → unidade | exato, com `includes` de reserva; **editável em Cadastros**, mora no aparelho |
| `PLAN_SINONIMOS` | descrição da ata → operação | casamento de palavras (5.3) |
| `solinftec_depara` | nome na Solinftec → unidade | **substring** ✘ |
| `rel_icrop_depara` / `DEPARA_ICROP` | nome no iCrop → fazenda física | **substring** ✘ |
| `solinftec_operacoes` | código Solinftec → nome | exato, mas **vazio** |

`unidade_alias` já prevê o slot `agrogestao`, mas o ERP **não está integrado**.

---

## 6. Bloco 4 — Estrutura do apontamento atual

### 6.1 Como um apontamento é gravado

**Uma linha por unidade e por dia**, com upsert em `fazenda_id + data`:

```
boletins:  id · fazenda_id · data · payload (o boletim inteiro em JSON)
```

Dentro do payload: `atividades[]`, `irg[]`, `fito[]`, `ocorrencias[]`,
`colheita[]`, `mo`, `clima`, `pecuaria{}`, `secoes{}` (v69) e **`plano{}`**
(v75).

Consequências, todas ainda de pé:

- **Não existe linha por operação.** As visões de farol desmontam o JSON com
  `jsonb_array_elements` a cada consulta.
- **A chave é a unidade-dia.** Dois aparelhos na mesma unidade no mesmo dia
  sobrescrevem um ao outro; o app avisa na tela, o banco não impede.
- Existem **cópias derivadas**: `boletim_pecuaria`, `boletim_secao_resposta`
  (por gatilho) e, agora, `planejamento_tarefa.payload.exec` (foto que o app
  grava para o relatório ler). Todas derivadas, nunca fonte.

### 6.2 Noção de estado — agora são sete lugares

| Onde | Estados | Quem muda | Onde vive |
|---|---|---|---|
| **`planejamento_tarefa.status`** | a_iniciar · em_execucao · finalizado · aguardando_terceiro · aguardando_clima · cancelado | gerente (1 toque) e escritório | **tabela própria, com enum no banco** |
| **`b.plano[].status`** | ⚪ · ◐ · ✅ | **ninguém — o app avalia sozinho pelo registro** | JSON do boletim |
| `atividades[].status` | concluida ⇄ continua (+ `falta`) | gerente, em chip | JSON do boletim |
| `remessas.status` | enviada → recebida | o gerente **do destino** | tabela própria |
| `plano_safra.status` | rascunho → vigente → superado | ADMIN | tabela própria |
| `unidade_manejo.status` | producao, poda, renovacao, recepa, plantio, a_confirmar | ADMIN | tabela própria |
| `ciclos` (grãos) | abre no plantio, encerra na colheita | o app, propondo | **só no aparelho** |

Vale sublinhar dois: **`b.plano[].status` é o único que ninguém digita** — o app
o deriva do registro, que é exatamente o espírito da cadeia; e **`remessas`** é
o precedente antigo de confirmação por outra pessoa (quem envia cria, quem
recebe confirma, com registro de divergência).

### 6.3 Histórico de alteração

| Registro | Histórico |
|---|---|
| **Tarefa do planejamento** | **Sim** — `payload.historico` / `D.tarefaHistorico`: quem, quando, de → para, motivo. "Cancelar é status, nunca delete." |
| **Boletim** | **Não.** Só `editadoEm`. O upsert substitui o payload inteiro; a versão anterior desaparece. |
| Unidade de manejo (plano A) | **Sim** — `unidade_manejo_log`, uma linha por campo alterado |
| Plano de safra | **Sim, por versão** — a anterior vira `superado`; nada se apaga |
| Robôs | **Sim** — `relatorios_execucoes`, `integracao_execucoes` |

Duas coisas que o desenho precisa levar em conta:

- **O prazo de 48 h para o gerente corrigir é só de interface**
  (`ACOES_PERFIL.corrigir_boletim`); o próprio código diz "isto é interface,
  não segurança". No banco, a chave publishable dá upsert em qualquer data, sem
  limite e sem rastro.
- **As políticas do plano A permitem escrita pública:** `sql/005` cria, para as
  11 tabelas, `select using (true)`, `insert with check (true)` e
  `update using (true)`.

### 6.4 O que o botão "Enviar boletim" grava

1. **Barreiras:** botão inativo com boletim vazio; aviso se já existe boletim na
   data; **exige resposta em toda seção eventual** (v70); diálogo de avisos de
   conferência (dito × medido do iCrop).
2. **Limpa** a resposta de seção que ganhou registro e carimba quem respondeu.
3. **Aprende no aparelho:** doses, receitas por operação e por talhão,
   fertirrigação, insumos novos, último evento de pecuária.
4. **Propõe abrir ciclo** dos talhões plantados (grãos), num diálogo só.
5. **(v75) Abre a folha "📋 Amanhã"** — pergunta o que atrapalhou hoje, se for o
   caso, e coleta o plano de amanhã em até 3 linhas. "Pular" e "Salvar plano"
   **enviam o boletim do mesmo jeito**.
6. **(v75) `gravarPlanoNoBoletim`** fecha o plano do dia-alvo em `b.plano`.
7. **Grava o boletim:** novo ganha `id` e `enviadoEm`; correção substitui e
   carimba `editadoEm`.
8. **Enfileira:** `boletins` sempre, `boletim_pecuaria` se houver pecuária.
9. **Gera as remessas** de café para outra fazenda (status `enviada`).

O que **não** grava: nenhuma linha por operação. Tudo dentro do JSON — inclusive
o plano do dia.

---

## 7. Bloco 5 — Comportamento observado

**Não apurável.** E agora por dois motivos:

- O "Nada a registrar hoje" (v69/v70) entrou no `main` em **08/09/2026**; o
  módulo de planejamento (v77/v78), em **10/09/2026**. Hoje é 10/09/2026.
- O que grava as respostas em tabela é o `sql/047`, e o que grava as tarefas é o
  `sql/050` — **os dois constam como não rodados**. Sem eles, tudo vive dentro
  de `boletins.payload` e no aparelho: dá para contar, mas não pelas visões.
- Os aparelhos dos gerentes só recebem a versão nova quando o service worker
  troca o cache. O alcance real nos primeiros dias é desconhecido.

**Sobre "com que frequência 'sem ocorrência' é marcado em poucos segundos após
abrir o boletim":** a pergunta **não é medível como está escrita**, e é
importante dizer isso antes de alguém tentar. O app **não guarda a hora em que o
boletim foi aberto**. Existe `secoes[id].em` (hora exata do toque, em ISO) e
`enviadoEm` (só até o minuto).

O que **dá** para medir, e mede a mesma coisa, é o **carimbo em lote**: duas ou
mais seções respondidas com poucos segundos entre uma e outra é toque
automático, não leitura. O bloco SQL traz a contagem e a mediana de segundos
entre a primeira e a última resposta do mesmo boletim.

**E agora há mais o que medir, pelo mesmo motivo.** A v77 pôs ações de um toque
(*Comecei · Concluí · Travado*) e a v78 pôs a sugestão de dois toques
("concluir a tarefa?"). Se o carimbo automático for um hábito, ele vai aparecer
ali também — e o `payload.historico` da tarefa registra **quem, quando e de →
para**, então dá para medir com precisão assim que o `sql/050` rodar. Vale
olhar os dois juntos daqui a **duas ou três semanas**. Antes disso é ruído.

---

## 8. Tabela de lacunas

| # | O que é | Por que bloqueia | O que resolveria |
|---|---|---|---|
| 1 | **Cinco SQL pendentes** (`048`, `049`, `050`, `051` e os antigos `005`→`007`) | Enquanto o `050` não rodar, o planejamento não sincroniza entre celulares e o relatório não existe; sem o `049`, o catálogo do banco não conhece os nomes novos do café | Rodar no SQL Editor, nesta ordem: `049`, `050`, `051`, `048`. O do agrônomo (`005`→`007`) é decisão à parte |
| 2 | **O cadastro de talhões só existe no aparelho** | A meta em ha e a projeção de ritmo saem da área do talhão; celulares com cadastros diferentes mostram "executado" diferente | Subir o cadastro para o Supabase, como já se fez com `rel_unidades`. **É a lacuna mais urgente hoje** |
| 3 | **A tarefa não guarda o id da operação** | O "executado" depende de casamento de palavras da descrição da ata; descrição reescrita deixa de somar, em silêncio | Gravar o id escolhido na pré-visualização da ata (que já é editável) e usar o texto só como sugestão |
| 4 | **Os dois planos não se falam** | O do agrônomo (kg, por setor de café) e o de execução (tarefas, por unidade) não se cruzam; a mesma calagem pode aparecer nos dois sem se reconhecer | Decidir se o plano do agrônomo vira **origem de tarefas** da ata, ou se fica só como referência (é o que a regra do projeto diz hoje) |
| 5 | **Não há histórico de alteração do boletim** | A tarefa tem trilha; o boletim, não. Correção apaga a versão anterior — e o "executado" é calculado sobre boletins | Tabela de eventos append-only, no molde de `unidade_manejo_log` |
| 6 | **iCrop e Solinftec conciliados por pedaço de nome** | Execução externa entrando na unidade errada, em silêncio | Identificador do fornecedor onde existir, ou migrar para `unidade_alias` (que já tem os slots e é por igualdade exata) |
| 7 | **"Outra" e termos extras de catálogo não têm id** | Registro por esses caminhos é invisível para farol, ritmo e para o "executado" da tarefa | Ou aceitar e dizer, ou dar id ao termo no momento em que o escritório o cria |
| 8 | **Produto, lote, cultivar e prestador em texto livre** | É o defeito do Sigma. "Saldo" em kg, lote ou produto não fecha | `docs/CAMPOS-LIVRES.md` já mapeou os 20 pontos e o esforço de cada um |
| 9 | **"Recomendado" só existe para irrigação** | Dos quatro estados, é o único sem fonte para o resto | Ou o plano do agrônomo publicado (café), ou aceitar que a cadeia comece em "Planejado" |
| 10 | **26 das 69 unidades do plano A sem apelido `app`** | Para elas, previsto e registrado não se encontram | Desmembrar talhões (muda os chips do gerente — versão própria) ou assumir a cobertura parcial e dizer na tela |
| 11 | **Tarefa sem meta não tem barra nem restante** | Sem denominador não há Saldo. A ata só traz área em algumas linhas | O escritório informa a meta pelo chip "Definir meta" nas tarefas grandes — já existe, é uso, não código |
| 12 | **`plano_*` aceita escrita com a chave pública** | O "Planejado" precisa ser confiável | Restringir as políticas de insert/update. Vale hoje, independente da Onda 2 |
| 13 | **Não se sabe quanto do "sem ocorrência" e do "Concluí" é carimbo automático** | Se for alto, a confirmação em lote nasce com o mesmo vício | Rodar o bloco SQL daqui a 2–3 semanas, depois do `sql/047` e do `sql/050` |

---

## 9. Veredito

### **Viável parcialmente — e a maior parte já foi construída.**

A pergunta que abriu esta investigação era se a cadeia podia existir. Entre a
apuração e este relatório, três das quatro pontas passaram a existir. O que
sobra é diferente do que se esperava.

**O que já está de pé, nas três atividades:**

- **Planejado** — tarefas da ata e da semana (`planejamento_tarefa`, com prazo,
  unidade por id e 6 status) e o plano do dia seguinte (`b.plano`).
- **Realizado** — os lançamentos do boletim, casados por operação do catálogo.
- **Saldo** — planejado · executado · restante em hectares, com barra e
  rastreabilidade lançamento a lançamento (`planTrio` / `planProgresso`).
- **Confirmação em toque** — *Comecei · Concluí · Travado* na folha do gerente,
  e a sugestão de dois toques quando o lançamento casa com a tarefa.
- **Trilha** — `payload.historico` com quem, quando, de → para e motivo.

**O que falta, em ordem de importância:**

1. **Rodar os SQL.** Enquanto o `sql/050` não rodar, tudo isso existe **só no
   aparelho de quem digitou**. É a diferença entre um módulo e um caderno.
2. **Subir o cadastro de talhões.** O Saldo é medido em hectares que só existem
   no celular. Duas pessoas veem números diferentes para a mesma tarefa, e
   ninguém percebe.
3. **Dar id de operação à tarefa.** Hoje o elo Planejado → Realizado é
   casamento de palavras. Funciona, é honesto quando falha, mas é o ponto em
   que a cadeia se desfaz sem avisar.
4. **"Recomendado".** É a ponta que continua faltando, e não há de onde tirá-la
   fora da irrigação — a não ser publicando o plano do agrônomo, que cobre
   adubação, calagem e fito de café, em 43 unidades.

**E uma coisa que não é lacuna, é decisão:** o app hoje tem **dois planos que
não se falam**. O do agrônomo diz kg de sulfato por setor por mês; o da ata diz
"levantar café na Vereda até 20/09". Antes de desenhar a Onda 2, vale decidir se
o do agrônomo vira **origem de tarefas** — e aí a cadeia é uma só — ou se
continua sendo referência de leitura, como a regra do projeto diz hoje. As duas
respostas são defensáveis; o que não dá é deixar em aberto e descobrir depois
que a mesma calagem está contada duas vezes.

**Sequenciamento que eu recomendo** (opinião, não apuração):

1. Rodar `sql/049` → `050` → `051` → `048`. Uma tarde de SQL Editor, e destrava
   tudo que já foi construído.
2. Subir o cadastro de talhões para o Supabase (lacuna 2).
3. Guardar o id da operação na tarefa (lacuna 3).
4. Só então decidir sobre o plano do agrônomo (lacuna 4) e sobre "Recomendado".

---

## 10. Bloco SQL de leitura — para o Nilo rodar

Os dois blocos abaixo **só leem**. Não criam, não alteram e não apagam nada, e
podem ser rodados quantas vezes quiser — antes e depois dos SQL pendentes, para
comparar.

> **Não tente copiar o resultado: tire um print.** A grade de resultado do
> Supabase no iPhone não deixa marcar mais de uma linha — foi por isso que a
> versão curta existe. Print da tela resolve, e vale para qualquer consulta.

**Como fazer, pelo iPhone:**

1. Abra o **Supabase** (projeto `syvehtgrbqteyuqhoban`).
2. Toque em **SQL Editor** e em **New query**.
3. Cole **o bloco inteiro** de uma vez (é uma consulta só).
4. Toque em **Run**.
5. **Tire o print** da tabela de resultado e mande.

Se der erro, tire o print da mensagem inteira e mande também — não tente
consertar.

### 10.1 Versão curta — 6 linhas (é esta que se usa no iPhone)

Mesma informação da versão completa, condensada em seis linhas, para caber num
print só, sem rolar. Se alguma linha aparecer cortada com "…", tocar na célula
abre o texto inteiro.

```sql
-- Boletim NCNaves — raio-X compacto (6 linhas). SÓ LÊ.
with t(n) as (select unnest(array[
  'plano_safra','plano_unidade','plano_adubo_mes','plano_calagem','plano_fito_mes',
  'plano_gantt','unidade_manejo','unidade_alias'])),
p(n) as (select unnest(array[
  'planejamento_rodada','planejamento_semana','planejamento_tarefa','vw_planejamento_mes'])),
cnt as (
  select n, case when to_regclass('public.'||n) is null then null
    else (xpath('/row/c/text()', query_to_xml('select count(*) as c from public.'||n, false,true,'')))[1]::text::bigint
    end as k from (select n from t union all select n from p) z),
b as (select fazenda_id, data, payload from public.boletins
      where coalesce((payload->>'exemplo')::boolean,false)=false),
lst as (select e from b cross join lateral jsonb_array_elements(
  case when jsonb_typeof(payload->'atividades')='array' then payload->'atividades' else '[]'::jsonb end) e),
nm as (select btrim(p->>'nome') as nome from lst, lateral jsonb_array_elements(
    case when jsonb_typeof(e->'insumos')='array' then e->'insumos' else '[]'::jsonb end) p
  union all select btrim(p->>'nome') from lst, lateral jsonb_array_elements(
    case when jsonb_typeof(e->'produtos')='array' then e->'produtos' else '[]'::jsonb end) p),
nk as (select nome, upper(translate(nome,'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
       'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC')) as ch from nm where coalesce(nome,'')<>''),
sc as (select payload from b where jsonb_typeof(payload->'secoes')='object'),
rp as (select
  (select min((v->>'em')::timestamptz) from jsonb_each(payload->'secoes') s(k,v) where v->>'em' ~ '^\d{4}-\d{2}-\d{2}T') i,
  (select max((v->>'em')::timestamptz) from jsonb_each(payload->'secoes') s(k,v) where v->>'em' ~ '^\d{4}-\d{2}-\d{2}T') f,
  (select count(*) from jsonb_each(payload->'secoes') s(k,v) where v->>'resposta'='sem_ocorrencia') n from sc)
select '1 plano do agronomo' as bloco,
  (select count(*) filter (where k is not null) from cnt join t on t.n=cnt.n)||' de 8 tabelas'
  || ' · vigentes: ' || coalesce(case when to_regclass('public.plano_safra') is null then 'sem tabela'
       else (xpath('/row/c/text()', query_to_xml('select count(*) as c from public.plano_safra where status=''vigente''',false,true,'')))[1]::text end,'?') as resposta
union all select '2 planejamento',
  (select count(*) filter (where k is not null) from cnt join p on p.n=cnt.n)||' de 4'
  || ' · tarefas: ' || case when to_regclass('public.planejamento_tarefa') is null then 'sem tabela'
     else coalesce((xpath('/row/c/text()', query_to_xml($q$
       select coalesce(string_agg(status||' '||n,', ' order by status),'0') as c
       from (select status, count(*) n from public.planejamento_tarefa group by status) z $q$,false,true,'')))[1]::text,'0') end
  || ' · plano do dia: ' || (select count(*) from b where jsonb_typeof(payload->'plano')='object')
union all select '3 identidade',
  'ops ' || coalesce(case when to_regclass('public.operacao_catalogo') is null then 'sem tabela'
     else (xpath('/row/c/text()', query_to_xml('select count(*) as c from public.operacao_catalogo',false,true,'')))[1]::text end,'?')
  || ' · sem de-para ' || case when to_regclass('public.operacao_alias') is null then 'sem tabela'
     else (xpath('/row/c/text()', query_to_xml($q$
       select count(distinct t) as c from (select e->>'tipo' t from public.boletins b cross join lateral
         jsonb_array_elements(case when jsonb_typeof(b.payload->'atividades')='array' then b.payload->'atividades' else '[]'::jsonb end) e
         where coalesce(e->>'tipo','')<>'') x
       where t not in (select termo from public.operacao_alias where origem='atividades.tipo') $q$,false,true,'')))[1]::text end
  || ' · Outra ' || (select count(*) from lst where e->>'tipo'='Outra')
  || ' · produtos ' || (select count(distinct nome) from nk)
  || ', dobrados ' || (select count(*) from (select ch from nk group by ch having count(distinct nome)>1) g)
union all select '4 apontamento',
  (select count(*) from b)||' bol · '||(select count(distinct fazenda_id) from b)||' un · '
  || (select coalesce(min(data)::text,'-')||' a '||coalesce(max(data)::text,'-') from b)
  || ' · ' || (select case when relrowsecurity then 'RLS ligado' else 'RLS DESLIGADO' end from pg_class where oid='public.boletins'::regclass)
  || ', ' || coalesce((select count(*)::text from pg_policies where schemaname='public' and tablename='boletins'),'0') || ' policies'
union all select '5 secoes',
  (select count(*) from sc)||' c/secoes · '||(select count(*) from rp where n>0)||' c/nada-a-registrar'
  || ' · ate 10s ' || (select count(*) from rp where n>1 and f-i<=interval '10 seconds')
  || ' de '|| (select count(*) from rp where n>1)||' c/2+ respostas'
union all select '6 fontes externas',
  'icrop_manejo ' || coalesce(case when to_regclass('public.icrop_manejo') is null then 'sem tabela'
     else (xpath('/row/c/text()', query_to_xml('select count(*) as c from public.icrop_manejo',false,true,'')))[1]::text end,'?')
  || ' · solinftec_diario ' || coalesce(case when to_regclass('public.solinftec_diario') is null then 'sem tabela'
     else (xpath('/row/c/text()', query_to_xml('select count(*) as c from public.solinftec_diario',false,true,'')))[1]::text end,'?')
order by 1;
```

O resultado tem esta forma (exemplo de teste, não o banco real):

```
1 plano do agronomo | 0 de 8 tabelas · vigentes: sem tabela
2 planejamento      | 4 de 4 · tarefas: a_iniciar 2, em_execucao 1, finalizado 1 · plano do dia: 1
3 identidade        | ops 1 · sem de-para 2 · Outra 1 · produtos 3, dobrados 1
4 apontamento       | 2 bol · 2 un · 2026-09-01 a 2026-09-05 · RLS ligado, 2 policies
5 secoes            | 1 c/secoes · 1 c/nada-a-registrar · ate 10s 1 de 1 c/2+ respostas
6 fontes externas   | icrop_manejo 0 · solinftec_diario sem tabela
```

**Conferida** num PostgreSQL 16 local em dois cenários — (a) o banco de hoje,
sem as tabelas de plano nem as de planejamento, com `data` do boletim em texto e
payload malformado (`atividades` e `plano.itens` gravados como texto em vez de
lista); (b) planejamento rodando, com tarefas em quatro status, RLS ligada e
boletins com plano do dia. Nos dois: **6 linhas, sem erro**; tabela que não
existe aparece como `sem tabela` em vez de derrubar a consulta.

### 10.2 Versão completa — 46 linhas (para o computador, ou quando faltar detalhe)

Abre cada tabela e cada número separadamente. No iPhone precisa de dois ou três
prints; num computador o resultado se copia inteiro.

```sql
-- Boletim NCNaves — raio-X de leitura para a investigação da cadeia de estados.
-- SÓ LÊ. Não cria, não altera e não apaga nada.
with alvo(bloco, item) as (values
  ('1 plano agronomo','plano_safra'),      ('1 plano agronomo','plano_unidade'),
  ('1 plano agronomo','plano_adubo_mes'),  ('1 plano agronomo','plano_calagem'),
  ('1 plano agronomo','plano_fito_mes'),   ('1 plano agronomo','plano_gantt'),
  ('1 plano agronomo','unidade_manejo'),   ('1 plano agronomo','unidade_alias'),
  ('2 planejamento', 'planejamento_rodada'),
  ('2 planejamento', 'planejamento_semana'),
  ('2 planejamento', 'planejamento_tarefa'),
  ('2 planejamento', 'vw_planejamento_mes'),
  ('3 fontes',       'icrop_manejo'),      ('3 fontes',       'solinftec_diario'),
  ('4 identidade',   'rel_unidades'),      ('4 identidade',   'operacao_catalogo'),
  ('4 identidade',   'operacao_alias'),    ('4 identidade',   'operacao_janela'),
  ('4 identidade',   'solinftec_depara'),  ('4 identidade',   'rel_icrop_depara'),
  ('5 apontamento',  'boletins'),          ('5 apontamento',  'pos_colheitas'),
  ('5 apontamento',  'remessas'),          ('5 apontamento',  'boletim_pecuaria'),
  ('6 secoes',       'boletim_secao'),     ('6 secoes',       'boletim_secao_resposta')
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
plan as (select payload from b where jsonb_typeof(payload->'plano')='object'),
plit as (select i from plan cross join lateral jsonb_array_elements(
    case when jsonb_typeof(payload->'plano'->'itens')='array' then payload->'plano'->'itens' else '[]'::jsonb end) i),
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
  select '1 plano agronomo','planos com status vigente',
    case when to_regclass('public.plano_safra') is null then 'sem a tabela plano_safra'
    else (xpath('/row/c/text()', query_to_xml(
      'select count(*) as c from public.plano_safra where status = ''vigente''', false,true,'')))[1]::text end
  union all select '2 planejamento','tarefas por status',
    case when to_regclass('public.planejamento_tarefa') is null then 'sem a tabela planejamento_tarefa'
    else coalesce((xpath('/row/c/text()', query_to_xml($q$
      select coalesce(string_agg(status||': '||n, ' · ' order by status), 'nenhuma tarefa') as c
      from (select status, count(*) as n from public.planejamento_tarefa group by status) z
    $q$, false,true,'')))[1]::text, 'nenhuma tarefa') end
  union all select '2 planejamento','tarefas com historico no payload',
    case when to_regclass('public.planejamento_tarefa') is null then 'sem a tabela planejamento_tarefa'
    else (xpath('/row/c/text()', query_to_xml($q$
      select count(*) as c from public.planejamento_tarefa
      where jsonb_typeof(payload->'historico') = 'array' and jsonb_array_length(payload->'historico') > 0
    $q$, false,true,'')))[1]::text end
  union all select '2 planejamento','boletins com plano do dia seguinte', count(*)::text from plan
  union all select '2 planejamento','itens de plano do dia · ja avaliados',
    count(*)::text || ' · ' || count(*) filter (where coalesce(i->>'status','') <> '')::text from plit
  union all select '4 identidade','grafias de operacao sem de-para no catalogo',
    case when to_regclass('public.operacao_alias') is null then 'sem a tabela operacao_alias'
    else (xpath('/row/c/text()', query_to_xml($q$
      select count(distinct t) as c from (
        select e->>'tipo' as t from public.boletins b cross join lateral jsonb_array_elements(
          case when jsonb_typeof(b.payload->'atividades')='array' then b.payload->'atividades' else '[]'::jsonb end) e
        where coalesce(e->>'tipo','') <> '') x
      where t not in (select termo from public.operacao_alias where origem = 'atividades.tipo')
    $q$, false,true,'')))[1]::text end
  union all select '4 identidade','grafias distintas de operacao gravadas', count(distinct e->>'tipo')::text
    from lst where coalesce(e->>'tipo','') <> ''
  union all select '4 identidade','operacoes gravadas como "Outra"', count(*)::text from lst where e->>'tipo'='Outra'
  union all select '4 identidade','grafias distintas de produto/insumo', count(distinct nome)::text from nome_ok
  union all select '4 identidade','produtos com mais de uma grafia', count(*)::text
    from (select chave from nome_ok group by chave having count(distinct nome)>1) g
  union all select '5 apontamento','boletins reais (fora os de exemplo)', count(*)::text from b
  union all select '5 apontamento','unidades com boletim', count(distinct fazenda_id)::text from b
  union all select '5 apontamento','1o e ultimo boletim',
    coalesce(min(data)::text,'-')||' a '||coalesce(max(data)::text,'-') from b
  union all select '5 apontamento','linhas de atividade dentro dos payloads', count(*)::text from lst
  union all select '5 apontamento','RLS e policies de boletins',
    (select case when relrowsecurity then 'RLS ligado' else 'RLS DESLIGADO' end
       from pg_class where oid = 'public.boletins'::regclass)
    || ' · ' || coalesce((select string_agg(cmd||' '||policyname, ' · ' order by policyname)
       from pg_policies where schemaname='public' and tablename='boletins'), 'sem policy')
  union all select '5 apontamento','colunas status/estado/situacao no banco',
    coalesce((select string_agg(table_name||'.'||column_name, ' · ' order by table_name, column_name)
      from information_schema.columns
      where table_schema='public' and column_name in ('status','estado','situacao')), 'nenhuma')
  union all select '6 secoes','boletins com o campo secoes no payload', count(*)::text from secs
  union all select '6 secoes','boletins com "Nada a registrar hoje"', count(*)::text from resp where n>0
  union all select '6 secoes','com 2+ respostas: todas em ate 10 s', count(*)::text
    from resp where n>1 and fim-ini <= interval '10 seconds'
  union all select '6 secoes','com 2+ respostas: mediana de segundos entre a 1a e a ultima',
    coalesce(round(percentile_cont(0.5) within group (order by extract(epoch from (fim-ini))))::text,'-')
    from resp where n>1
)
select bloco, item, resposta from tab
union all select bloco, item, resposta from extra
order by 1, 2;
```

**Como o bloco foi conferido:** rodado num PostgreSQL 16 local em três
cenários — (a) o banco de hoje, sem as tabelas de plano nem as de planejamento;
(b) com `plano_safra` populada, a coluna `data` do boletim como **texto**,
carimbo de hora inválido em `secoes` e payload malformado (`plano.itens` e
`atividades` gravados como texto em vez de lista); (c) com
`planejamento_tarefa` em quatro status diferentes, `vw_planejamento_mes`,
RLS ligada com duas policies e boletins com `plano` no payload. Nos três: **46
linhas, sem erro**; tabela ausente vira `NAO EXISTE` em vez de derrubar a
consulta; payload malformado é ignorado em silêncio; a contagem por status sai
agregada numa linha só (`a_iniciar: 1 · em_execucao: 1 …`); e a contagem de
grafias juntou corretamente `SULFATO DE MANGANES`, `Sulfato de manganes` e
`sulfato de Manganês` como o mesmo produto com 3 grafias.

### 10.3 Como ler o resultado (vale para as duas versões)

| Na versão curta | Na versão completa | Quer dizer |
|---|---|---|
| `2 planejamento · 0 de 4` | `tabela planejamento_tarefa · NAO EXISTE` | o `sql/050` não rodou — o planejamento existe só nos celulares |
| `4 de 4 · tarefas: a_iniciar 12, …` | `tarefas por status` preenchido | o módulo está sincronizando de verdade |
| `plano do dia: 0` | `boletins com plano do dia seguinte · 0` | a v75 ainda não chegou aos celulares, ou ninguém salvou plano |
| `1 plano do agronomo · 0 de 8 tabelas` | `tabela plano_safra · NAO EXISTE` | o `sql/005` nunca rodou |
| `8 de 8 tabelas · vigentes: 0` | `plano_safra · 8 linhas` + `planos vigentes · 0` | o seed entrou mas nada foi publicado — o app não lê |
| `sem de-para` alto | `grafias de operacao sem de-para no catalogo` alto | há registro que a cadeia não enxerga (o `sql/049` pode ser a causa) |
| `dobrados` maior que zero | `produtos com mais de uma grafia` alto | é o caso do Sigma acontecendo aqui |
| `RLS DESLIGADO` | `RLS DESLIGADO` em `boletins` | qualquer um com a chave pública lê e grava boletim |
| `ate 10s 8 de 10` | `com 2+ respostas: todas em ate 10 s` alto | carimbo automático — a confirmação em lote precisa nascer protegida |
| `sem tabela` em qualquer lugar | `NAO EXISTE` | o SQL daquele assunto ainda não rodou — não é erro da consulta |

---

## 11. Coisas que provavelmente ninguém sabe que estão (ou não estão) no banco

Encontradas de passagem, todas verificadas no código da v78.

1. **"Marcar como visto" nunca sai do celular.** O botão da Diretoria grava
   `b.visto` no aparelho e **não entra na fila de sincronização** — continua
   assim na v78. Pior: na sincronização seguinte a cópia do servidor rebaixa o
   registro local, e **o "visto" é apagado sozinho**.
2. **Todo o cadastro vive só no aparelho.** Talhões, máquinas, insumos,
   usuários, ciclos de grãos, inventário de pecuária, termos extras dos
   catálogos e o **de-para da ata**. A fila sincroniza nove tipos de registro;
   cadastro não é nenhum deles.
3. **O "executado" em hectares depende do cadastro do celular.** Como a área do
   talhão só existe ali, dois aparelhos com cadastros diferentes mostram números
   diferentes para a mesma tarefa — e nada na tela avisa.
4. **Operação lançada como "Outra" some dos faróis e do "executado".** É
   excluída de propósito do catálogo, então não tem id. O mesmo vale para termo
   acrescentado em Cadastros › Catálogos.
5. **O prazo de 48 h de correção é combinado, não trancado.** A trava está na
   tela; o banco aceita gravar boletim de qualquer data, quantas vezes quiser.
6. **Corrigir um boletim apaga a versão anterior.** Fica só o `editadoEm`
   dizendo que houve correção, sem dizer o que mudou. E o "executado" das
   tarefas é calculado sobre boletins.
7. **O iCrop já entrega recomendação, e ela já está gravada.** Percentímetro
   recomendado, lâmina mínima, tempo de irrigação e déficit previsto estão em
   `icrop_manejo.bruto` desde a v47.
8. **As tabelas do plano do agrônomo aceitam escrita com a chave pública.**
   `sql/005` cria políticas de insert e update com `true`.
9. **O robô do iCrop não está no repositório.** Vive só dentro do Supabase, e o
   arquivo `sql/003-robo-icrop-reforco.sql` citado no `ESTADO.md` **não existe**
   em `sql/`. Vale exportar as três funções numa tarefa qualquer.
10. **`relatorios_gerados.texto` guarda texto escrito por IA.** O robô-redator
    chama a API da Anthropic pela madrugada e grava no banco. Está sinalizado na
    tela, mas quem olhar a tabela direto vê texto de máquina ao lado de número
    medido.
11. **`solinftec_operacoes` está vazio.** Por isso a tela mostra "Operação NNN".
12. **Notificação do planejamento não é push de verdade.** Os avisos disparam
    quando o app é aberto a partir da hora marcada — e no iPhone só se o app
    estiver instalado na tela de início.

---

*Investigação de leitura. Nenhum arquivo do app, nenhuma tabela e nenhuma
política foram alterados. Apurado na v74 em 09/09/2026, reescrito contra a v78
em 10/09/2026.*
