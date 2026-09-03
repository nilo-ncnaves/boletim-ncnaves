# PLANO-DE-SAFRA.md — o plano do agrônomo dentro do app

Como o Boletim NCNaves guarda, versiona e usa o plano de safra
(proposta técnica do agrônomo Salvino, um PowerPoint por fazenda).
Vale a partir da **v52** (fase A, "Fundação"). A fase B (v53) vai usar
esta base para o cartão "Plano do mês", os chips ordenados pelo plano
e os faróis da Diretoria.

## O que o plano é (e o que não é)

- É **referência e comparação**: o que o agrônomo previu por unidade,
  mês e atividade, para o Escritório/Diretoria comparar com o que o
  gerente registrou.
- **Não é receituário.** O app nunca recomenda produto, dose, mistura,
  época nem lâmina. Todo texto vindo do plano leva o rótulo "previsto
  pelo agrônomo — registre o que foi feito". kg nunca aparecem por
  padrão para o gerente.
- **Não duplica** o ERP AgroGestão (kg, R$), a iCrop (lâminas) nem a
  Solinftec (hora-máquina). O app registra o evento de campo.
- Na v52 **nada muda para o gerente**: o plano é baixado e guardado no
  aparelho, e o Escritório ganha a tela "Unidades e Plano". Só isso.

## Modelo de dados (Supabase — `sql/005-plano-safra.sql`)

```
unidade_manejo ──< unidade_alias        (apelidos por sistema, com vigência)
      │ ──< unidade_manejo_log          (campo, antes, depois, quem, quando)
      │
      └──< plano_unidade >── plano_safra  (versões: rascunho → vigente → superado)
                               │ ──< plano_adubo_mes   (kg por unidade, mês, insumo; via)
                               │ ──< plano_calagem     (t/ha, t total, janela 01/09–31/10)
plano_fito_mes (plano_id nulo = grupo)   plano_fito_excecao (produto × fazenda × mês)
plano_gantt (modelo NC / NR × atividade × meses, evidência)
plano_parametros (limites dos faróis, editáveis pelo ADMIN)
```

Pontos que importam:

- **A identidade é `unidade_manejo.id`/`codigo`** (ex.: `VEC-S08`). O
  código nunca muda (gatilho impede). Nomes são apelidos em
  `unidade_alias`, por sistema: `plano` (nomes dos decks), `app`
  (**id do talhão** no cadastro do `index.html`, ex.: `t093` — é isso
  que liga o plano aos chips do boletim), `solinftec`, `icrop`,
  `agrogestao`. Um apelido só pode apontar para uma unidade por
  sistema **dentro da fazenda** enquanto vigente (a fazenda entra na
  chave porque "Setor 01" existe em quatro fazendas). Apelido que o
  deck usa para várias unidades ao mesmo tempo ("2º Plantio 180
  hectares") não entra.
- **Nada se apaga**: unidade se inativa (`ativo=false`), apelido se
  encerra (`vigente_ate`), plano se supera. Não há policy de DELETE.
- **Uma versão vigente por fazenda-safra** (índice único parcial).
  Mudou o plano? Nova linha em `plano_safra` (versão N+1) com seu
  conteúdo; publicar passa a anterior para `superado`. Nunca se edita
  o conteúdo da vigente.
- `fazenda_app` é o **nome exato** da unidade no cadastro do app. O app
  liga id ↔ nome pela constante `PLANO_FAZENDA_APP` do `index.html`
  (mesmo papel da `DEPARA_ICROP`). Só entram fazendas cujo nome no
  plano é idêntico ao do app; as três divergentes (ver abaixo) ficam
  fora até o Nilo confirmar.
- `plano_safra.resumo_deck` guarda o slide-resumo do deck (kg/ano por
  insumo) só para a auditoria comparar com a soma dos calendários.
- RLS: mesmo modelo das outras tabelas do app (a chave publishable lê e
  grava; o controle é do próprio app — só a tela de ADMIN escreve).

## Carga da safra 2026/27 (v1)

Arquivos, na ordem em que nascem:

| Passo | Arquivo | O que é |
|---|---|---|
| 1 | `docs/plano/importar_plano.py` | Extrai as tabelas dos PPTX para JSON bruto (nomes como estão nos slides). Precisa de `python-pptx`. Os PPTX não ficam no repositório. |
| 2 | `docs/plano/2026-27/apendice_dados.md` | Fonte única desta safra: o apêndice compacto do pedido (unidades, calagem, adubo mês a mês, resumo, fito, Gantt, inconsistências). |
| 3 | `scripts/expandir_apendice_plano.py` | Expande o apêndice para `plano_2627_seed.json` e **trava** se as conferências falharem (69 unidades; 71 calagens = 4.648 t; 1.533 linhas de adubo; kg por fazenda e insumo). |
| 4 | `docs/plano/2026-27/depara_fazendas.json` | Nome no plano → unidade do app. Só exato; `confirmado: false` para os três que não batem. |
| 5 | `docs/plano/2026-27/alias_app.json` | Unidade → talhão do app, só quando inequívoco (mesmo nome ou mesmo número na mesma fazenda, conferido pela área), com a evidência; e a lista `sem_alias` com o motivo. |
| 6 | `scripts/gerar_seed_plano.py` | Lê 3, 4, 5 e o cadastro real do `index.html`, confere tudo e gera `sql/006-plano-safra-seed-2627.sql` (ids fixos por uuid5; `on conflict do nothing`; conferência final que desfaz a carga se as somas não baterem). |
| 7 | `sql/005-plano-safra.sql` → `sql/006-plano-safra-seed-2627.sql` | Rodar nesta ordem no SQL Editor. Os 8 planos entram como **versão 1 em rascunho**. |
| 8 | Tela Escritório › Cadastros › **Unidades e Plano** | Rodar auditoria → preencher "Aprovado por" (agrônomo) → **Publicar como vigente**. |

Como carregar uma **nova versão** do plano (PPTX novos):
PPTX → `importar_plano.py` (JSON bruto) → resolver cada nome contra
`unidade_alias` (sistema `plano`; nome novo? cadastrar o apelido na tela
de Escritório antes) → montar o seed da versão N+1 (mesmo gerador,
outra safra/versão) → rodar como rascunho → auditoria → publicar.
Unidade nova (plantio, desmembramento) nasce em `unidade_manejo` com
código novo; unidade que sumiu se inativa. Nunca se reaproveita código.

## Fazendas do plano × cadastro do app

| Plano (deck) | App | Situação |
|---|---|---|
| Água Limpa | f01 Água Limpa | igual |
| Rio Preto-Lagamar — Café | f03c Rio Preto-Lagamar — Café | igual |
| Vereda Romaria | f23 Vereda Romaria | igual |
| Vereda Café 5º e 6º | f24 Vereda Café 5º e 6º | igual |
| Monte Carmelo — Café | f14c Monte Carmelo — Café | igual |
| Vereda Café | f22c **Vereda — Café** | **não bate** (travessão; e "Vereda Café" é prefixo de "Vereda Café 5º e 6º") |
| Lagamar Café – Rodrigo | f20 **Lagamar Café (Rodrigo)** | **não bate** (meia-risca × parênteses) |
| Mata Preta - Café | f13c **Mata Preta — Café** | **não bate** (hífen × travessão) |

Para liberar uma fazenda divergente: confirmar com o Nilo → trocar
`confirmado` para `true` no de-para → rodar `gerar_seed_plano.py` e o
seed (cria os apelidos `app`) → rodar o bloco "AJUSTE PENDENTE" do fim
do seed (renomeia `fazenda_app` nas tabelas já carregadas) → incluir a
fazenda em `PLANO_FAZENDA_APP` no `index.html` (nova versão do app).

## Mapa Gantt ↔ registros do app (`plano_gantt.evidencia_app`)

| Atividade do Gantt | Evidência no app (catálogo `LISTA_ATIV` do café) | Externa |
|---|---|---|
| analise_solo | — (sem chip de coleta de solo; farol cinza) | — |
| analise_foliar | — (sem chip; farol cinza) | — |
| calagem_gessagem | "Calagem / gessagem" por talhão (✔/⏳) | Solinftec · ERP |
| adubacao_organica | "Adubação orgânica" por talhão | ERP |
| limpeza_sistema_irrigacao | "Limpeza do sistema de irrigação" | — |
| adubacao_fertirrigacao | Irrigação › "Fertirrigação hoje? Sim" + chips de setor | iCrop |
| adubacao_lanco | "Adubação via lanço" por talhão | Solinftec · ERP |
| mip | "Monitoramento de pragas (MIP)" + seção Pragas, doenças e daninhas | — |
| pulverizacao | "Pulverização" por talhão + calda | Solinftec |
| drench | "Aplicação via drench / via solo" por talhão | — |
| desbrota | "Desbrota" por talhão com ✔ | — |
| capina_manual | "Capina manual" por talhão com ✔ | — |
| capina_rocadeira_trincha | "Capina roçadeira / trincha" por talhão | Solinftec |
| herbicida | "Aplicação de herbicida" por talhão | Solinftec |
| colheita | módulo Colheita + "Colheita" | Solinftec |
| poda | "Poda / esqueletamento" por talhão com ✔ | — |

`tipo = evento_unico`: calagem_gessagem, analise_solo, analise_foliar,
poda. As demais são `janela`. Os chips de calagem, poda e desbrota **já
existem** no catálogo do café — nenhum chip novo foi criado na v52.

## Cache no aparelho (`bdf:plano`) — o que a fase B vai ler

`baixarPlano()` roda dentro de `syncTudo()` (ao abrir com rede e a cada
sincronização), só para fazendas de café do escopo do código que estão
em `PLANO_FAZENDA_APP`. Busca a versão **vigente** e guarda, por id de
fazenda do app:

```
planoCache[fz] = { plano_versao_id, versao, vigente_de, fazenda_app, modelo (NC|NR),
  baixado_em, mes, unidades[], aliasApp[{unidade_id, alias=t0xx}],
  adubo[] (mês corrente e próximo), calagem[], fito[] (mês corrente e próximo),
  fitoExc[], gantt[] (só do modelo da empresa), parametros{chave: valor} }
```

Sem rede fica o cache; sem cache o app se comporta como a v51. Tabelas
ainda não criadas → o fetch falha em silêncio. Fazenda sem plano vigente
→ sai do cache. `planoDe(fz)` devolve o objeto (ou null).

## Tela Escritório › Unidades e Plano (só ADMIN)

- **Unidades** por fazenda: código, nome curto, área + fonte, status +
  desde, apelidos por sistema. Editar (nome curto, status, status desde,
  área, fonte, obs), adicionar/encerrar apelido, inativar. Cada campo
  alterado vira uma linha em `unidade_manejo_log`.
- **Plano de safra** por fazenda: versões com status, motivo, arquivo,
  resultado da auditoria. Em rascunho: **Rodar auditoria** e **Publicar
  como vigente** (só com auditoria ✔ e "Aprovado por" preenchido).
- **Auditoria** (`auditarPlano()` no `index.html`; resultado em
  `plano_safra.auditoria_json`). ✱ = trava a publicação:
  - ✱ toda unidade do plano existe, está ativa e é desta fazenda;
  - ✱ nenhuma unidade com calendário de adubação sem área — exceção:
    escrever `sem área: ok` na obs da unidade;
  - soma de kg por insumo × `resumo_deck` (informa);
  - kg/ha por insumo fora de ±50% da mediana da fazenda (informa; pega
    VEC-S08 sulfato de amônio, VEC-S07 KCl, VEC-S09 ureia, MCC-ERA);
  - calendário sem calagem / calagem sem calendário (informa);
  - status "a confirmar" (informa);
  - insumo-mês sem via (informa — na v1 nenhuma tem, é esperado).
  Nada é corrigido automaticamente.

## O que ficou de fora (de propósito)

Solinftec/iCrop cruzados com o plano, kg do ERP, trilha de produção,
estimativa automática, robô semanal em pg_cron, devolutiva automática,
contagem de frutos, dose, receita estruturada, edição do Gantt pelo
gerente. Tabelas `execucoes_externas`, `plano_farol`,
`estimativa_checkpoint` e `devolutivas` não existem ainda.

## Fase B (v53) — o que vem a seguir, resumido

Cartão "Plano do mês" (leitura, colapsado) no boletim de café; chips
de atividade/alvo/setor ordenados pelo plano e chips "usei:" de produto
acima da calda; modo safra zerada; chip "chumbinho visível" (único campo
novo do gerente); bloco "Plano" nos faróis da Diretoria
(`calcularFaroisPlano(fazenda, dataRef)`) e o texto "Plano × Semana".
Pré-requisito: pelo menos uma fazenda com plano **vigente**.
