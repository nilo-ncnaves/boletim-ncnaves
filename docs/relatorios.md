# Carteira de relatórios do Grupo LGS

Lista oficial dos relatórios que a Controladoria produz (ou vai
produzir) a partir do Boletim NCNaves e das integrações. Serve para
três coisas: saber o que existe, saber o que falta e conferir toda
semana o que estava previsto e não rodou (item da vistoria semanal em
`docs/vistoria-semanal.md`).

## Como ler a tabela

- **Fonte**: de onde saem os números. "app" = tabelas do Boletim
  (boletins, pos_colheitas, remessas, telemetria, boletim_pecuaria,
  codigos_acesso; desde a v59 a visão vw_dias_sem_registro, na v60
  operacao_janela + vw_farol_registro e, na v62, vw_intervalo_operacoes +
  vw_ritmo_operacoes — seções próprias abaixo); "iCrop" = icrop_manejo, icrop_fazendas,
  icrop_parcelas (robô da madrugada); "Solinftec" = solinftec_diario
  (robô, integrada desde a v49); "plano v52" = tabelas do plano de
  safra (plano_safra, plano_adubo_mes, plano_calagem, plano_fito_mes,
  plano_gantt, unidade_manejo, unidade_alias); "ERP" = AgroGestão
  (ainda NÃO integrado).
- **Cadência**: quando o relatório deve sair.
- **Dono/produtor**: quem gera. "painel" = sai sozinho no painel da
  Diretoria dentro do app; "Cowork" = o Nilo roda o prompt salvo em
  `docs/relatorios/nn-nome.md` no Cowork; "Code" = sessão de Claude
  Code no repositório.
- **Status**:
  - **EXISTE** — já sai do app/painel, sem trabalho extra.
  - **PRONTO** — os dados já existem no Supabase; falta rodar o prompt
    salvo no Cowork.
  - **AGUARDA** — depende de integração ou de dado que ainda não há
    (o que falta vem escrito ao lado).

## A carteira

| nº | Nome | O que responde | Fonte | Cadência | Dono/produtor | Status |
|---:|---|---|---|---|---|---|
| **NÍVEL 1 — SUSTENTAÇÃO** | | | | | | |
| 1 | Farol de completude | quem enviou/não enviou boletim; desde a v69, por seção eventual: com registro · sem ocorrência · não respondida (`vw_completude_boletim`, sem tela ainda) | app | diário | painel + motor (`farol_7`, `farol_30`) | EXISTE (por seção: visão pronta, tela futura) |
| 2 | Devolutiva semanal por unidade | adesão, dito × medido, elogio | app + iCrop + Solinftec | sexta | robô-redator (`devolutiva_semanal`, revisar antes de enviar) | EXISTE (v57 — texto redigido no Supabase) — prompt `docs/relatorios/02-devolutiva-semanal.md` |
| 3 | Vistoria do sistema | site × código, robôs, segurança | repo + REST | segunda | Code | EXISTE — roteiro em `docs/vistoria-semanal.md` |
| **NÍVEL 2 — CONTROLE OPERACIONAL** | | | | | | |
| 4 | Plano × executado do mês | adubação/calagem/fito previstos × feitos | plano v52 + boletim | segunda (parcial) / dia 1 (fechado) | motor (`plano_executado_mes`) + Cowork | EXISTE (motor, v55 — grava aviso enquanto sql/005–007 não rodarem) — prompt `docs/relatorios/04-plano-x-executado.md` |
| 5 | Divergência gerente × iCrop | rodou/não rodou × lâmina; chuva dita × pluviômetro | app + iCrop | diário / sexta (semana) | motor (`dito_medido_icrop_dia`, `_semana`) + painel | EXISTE (motor, v55) — mensal ainda pelo prompt `docs/relatorios/05-divergencia-gerente-icrop.md` |
| 6 | Aderência à recomendação de irrigação | recomendado × executado, R$ necessário × realizado | iCrop | sexta | motor (`irrigacao_rec_exec_semana`) | EXISTE (motor, v55) — prompt `docs/relatorios/06-aderencia-irrigacao.md` |
| 7 | Máquinas dito × Solinftec | horas/área/operação apontadas × telemetria | app + Solinftec | diário / sexta (semana) | motor (`dito_medido_solinftec_dia`, `_semana`) | EXISTE (motor, v55) — prompt `docs/relatorios/07-maquinas-x-solinftec.md` |
| 8 | Caderno de campo / registro de aplicações | talhão, produto, dose, área, condição, operador | app | semanal | Cowork (PDF) | PRONTO — `docs/relatorios/08-caderno-de-campo.md` |
| **NÍVEL 3 — CUSTO E PRODUÇÃO** | | | | | | |
| 9 | Custo físico por talhão/pivô | mm irrigados e R$/mm, horas-máquina e diesel por operação, pessoas-dia por função, produtos e doses (R$ de insumo em branco para o ERP) | app + iCrop + Solinftec | dia 1 (mês fechado) | motor (`custo_fisico_talhao_mes`) | EXISTE (motor, v55) — prompt `docs/relatorios/09-custo-irrigacao.md` |
| 10 | Mão de obra por função e unidade | pessoas, diaristas, extras, custo/ha por serviço | app | semanal/mensal | Cowork | PRONTO — `docs/relatorios/10-mao-de-obra.md` |
| 11 | Colheita e produtividade | café: medidas/sacas/rendimento; grãos: sc/ha, umidade, quebra | app | ciclo/safra | painel + Cowork | PRONTO — `docs/relatorios/11-colheita-produtividade.md` |
| 12 | Remessas e balanço de produto | saiu da fazenda × entrou no armazém | app (+ tickets) | mensal | Cowork | AGUARDA tickets de balança |
| 13 | Custo por saca / por talhão | físico (app, iCrop, Solinftec) × R$ (ERP) | todos + AgroGestão | mensal | Cowork | AGUARDA ERP (AgroGestão não integrado) |
| **NÍVEL 4 — ZOOTECNIA E AGRONOMIA** | | | | | | |
| 14 | Rebanho | cabeças por lote/categoria, natalidade, mortalidade, prenhez, GMD, lotação, embarques | app | dia 1 (mês fechado) | motor (`rebanho_mes`) + painel | EXISTE (motor, v55; lotação pendente — área do pasto não está no Supabase) — prompt `docs/relatorios/14-rebanho.md` |
| 15 | Balanço hídrico por pivô | ETo/ETc, déficit, umidade × segurança, atraso, fase, graus-dia | iCrop | diário | motor (`balanco_hidrico_dia`) + cartão iCrop | EXISTE (motor, v55) — consolidado pelo prompt `docs/relatorios/15-balanco-hidrico.md` |
| 16 | Sanidade e monitoramento | pragas/doenças, nível, decisão, dias até ação | app | semanal | Cowork | PRONTO — `docs/relatorios/16-sanidade-monitoramento.md` |
| 17 | Ciclos e rotação | histórico por talhão de grãos: custo, lâmina, produtividade por ciclo | app + iCrop + Solinftec | safra | Cowork | AGUARDA 1ª safra fechada (e censo de plantio) |
| 18 | Chuva e clima por fazenda | medido × digitado, acumulados, comparação | app + iCrop | mensal | Cowork | PRONTO — `docs/relatorios/18-chuva-clima.md` |
| **NÍVEL 5 — CADASTRO E CONFORMIDADE** | | | | | | |
| 19 | Cadastro na iCrop | parcelas vencendo, fazendas sem parcela, pivôs sem de-para | iCrop | semanal | painel | EXISTE |
| 20 | Arrendamentos | áreas cedidas/tomadas, vigências, valores | contratos | trimestral | Cowork | AGUARDA contratos (não há cadastro no app) |
| 21 | Matriz de acesso | quem tem qual código/escopo | app | trimestral | Cowork | PRONTO — `docs/relatorios/21-matriz-de-acesso.md` |
| 22 | Divergências de cadastro | app × ERP × inventário | docs | por censo | Cowork | PRONTO — `docs/relatorios/22-divergencias-cadastro.md` |
| **NÍVEL 6 — DIREÇÃO** | | | | | | |
| 23 | Painel executivo mensal | 1 página: produção, custo, água, máquinas, rebanho, adesão, 3 decisões | todos | dia 8 | robô-redator (`painel_executivo`, revisar antes de enviar) | EXISTE (v57 — texto redigido no Supabase; custo por saca AGUARDA ERP) — prompt `docs/relatorios/23-painel-executivo.md` |
| 24 | Fechamento de safra por cultura | produtividade, custo, margem, decisões (renovar/arrancar/rotação/vender lote) | todos | anual | Cowork | AGUARDA fechamento da safra (e ERP para custo/margem) |
| 25 | Ata × executado | o que a reunião do mês combinou × o que já foi respondido, por unidade (cumprimento, atrasadas, travadas, arrastadas, motivos) | app (planejamento_tarefa, v77) | mensal (dia 9) | motor (`ata_x_executado`) + painel/Planejamento | EXISTE (v77 — precisa de `sql/050` e `sql/051` rodados) |
| 26 | Insumos: programado × recebido × aplicado | por unidade e produto: o que foi programado na mensagem do grupo, o que o gerente confirmou que chegou, o que os lançamentos consumiram e o saldo; mais dias de espera por fornecedor | app (insumo_remessa, insumo_recebimento, boletins) | mensal (dia 9) | motor (`insumos_programado_recebido_aplicado`) + painel | EXISTE (v86 — precisa de `sql/054` e `sql/056` rodados) |

**Planejado × executado do plano do DIA (v75).** Não confundir com o
item 4 acima: aquele compara o plano de safra do agrônomo (adubo,
calagem, fito do ano) com o boletim; este compara o que o GERENTE
planejou para o dia seguinte, ao fechar o boletim, com o que o boletim
do dia seguinte registrou. Fonte: `boletins.payload -> 'plano'` (nenhuma
tabela nova). Objetos em `sql/048-plano-x-executado-diario.sql`: visão
`vw_plano_x_executado` (um item de plano por linha) e função
`rel_plano_x_executado_diario(ini, fim)` → `relatorios_gerados` com
`relatorio = 'plano_x_executado_diario'` (mês corrente pela
`rel_rodar_plano_dia()`; agendamento comentado no fim do arquivo). O app
lê pela vitrine de Relatórios (`REL_CATALOGO`, "Planejado × executado
(plano do dia) — mês"). Vocabulário: `nao_feito` é SEM REGISTRO — nunca
"não fez". Regra completa em CLAUDE.md, item c13.

## Ata × executado — `planejamento_tarefa` + `vw_planejamento_mes` (v77)

**O que responde:** o que a reunião administrativa do mês combinou, por
fazenda, × o que já foi respondido — cumprimento, atrasadas, travadas,
arrastadas e os motivos da trava.

**De onde vem:** o módulo de planejamento do app (sql/050). Toda reunião
(por volta do dia 10) vira uma RODADA; a ata entra por colagem e cada
linha iniciada por "-" vira uma tarefa da unidade. Toda sexta há
planejamento semanal, sem reunião: é a MESMA tarefa, comprometida na
semana. O gerente responde no celular com um toque (Comecei · Concluí ·
Travado), e a resposta sobe pela fila offline de sempre.

**Relatório mensal:** `sql/051-ata-x-executado.sql` grava
`relatorio = 'ata_x_executado'` em `relatorios_gerados` — uma linha por
unidade e uma linha do grupo (unidade_id nulo). Mês corrente na hora
pela `rel_rodar_ata()`; agendamento (dia 9, véspera da reunião)
comentado no fim do arquivo. O app lê pela vitrine de Relatórios
(`REL_CATALOGO`, "Ata × executado (planejamento do mês) — mês").

**Colunas de `dados` (por unidade):** `unidade`, `unidade_nome`,
`tarefas`, `finalizadas`, `canceladas`, `cumprimento_pct`, `atrasadas`,
`travadas`, `arrastadas`, `area_ha`, `motivos` (contagem por motivo de
trava) e `farol` (vermelho = tem atrasada; amarelo = tem travada; verde
= o resto). **Desde a v78** também `area_planejada`, `area_executada`,
`pct_area` e `tarefas_sem_lancamento`.

**Planejado × executado (v78): quem calcula é o app.** Os quatro campos
acima saem da FOTO que o app grava em cada tarefa
(`planejamento_tarefa.payload.exec` = `{ha, n, meta, em}`), regravada
sozinha a cada sincronização. O motivo é simples: casar a descrição da ata
("Fazer KCL e ferti") com a operação do boletim ("Adubação via lanço")
depende do de-para de sinônimos, que mora no index.html e em
docs/catalogos-por-atividade.md — não no banco. O SQL só LÊ a foto.
Pelo mesmo motivo, o **"% do esforço fora do plano"** não entra neste
relatório: ele fica no app (Planejamento › Executado fora do plano, no
fechamento por unidade e no texto de copiar).

**Regra que não se discute:** tarefa parada por TERCEIRO ou por CHUVA
conta como TRAVADA, nunca como atrasada — ela tem status próprio, farol
⏸️ e vira cobrança do escritório ("🔗 Pendências com terceiros" no app,
com o texto de cobrança pronto para copiar). `atrasadas` só olha A
INICIAR e EM EXECUÇÃO com prazo vencido. Vocabulário: o relatório relata
PRAZO e REGISTRO — nunca "não fez". Regra completa em CLAUDE.md, item c15.

**Saídas prontas dentro do app (botão copiar, sem ferramenta externa):**
pauta da sexta por fazenda · cobrança por fornecedor · fechamento mensal
por unidade · rascunho da próxima ata, já no formato do texto da reunião.

## Insumos: programado × recebido × aplicado — `insumo_remessa` + `insumo_recebimento` (v86)

**O que responde:** por unidade e produto, o que foi programado na
mensagem do grupo, o que chegou de verdade, o que os lançamentos do
boletim consumiram e quanto sobrou — e, por fornecedor, o que está
programado e ainda sem chegada registrada, com os dias de espera.

**De onde vem:** o módulo de insumos do app (sql/054). A mensagem do
WhatsApp ("Relação de NITRATO que a Cooxupé vai entregar nas fazendas:
106.000 kg - VEREDA…") é colada na porta única "📥 Colar do WhatsApp",
conferida na pré-visualização e vira uma REMESSA com as alocações por
unidade. Cada chegada confirmada pelo gerente (um toque, no topo do
boletim) vira um RECEBIMENTO; entrega parcial é outra linha.

**Relatório mensal:** `sql/056-insumos-relatorio.sql` grava
`relatorio = 'insumos_programado_recebido_aplicado'` em
`relatorios_gerados` — uma linha por unidade e uma linha do grupo
(unidade_id nulo). Mês corrente na hora pela `rel_rodar_insumos()`;
agendamento (dia 9, véspera da reunião) comentado no fim do arquivo. O app
lê pela vitrine de Relatórios (`REL_CATALOGO`, "Insumos: programado ×
recebido × aplicado — mês").

**Colunas de `dados` (por unidade):** `unidade`, `unidade_nome`,
`produtos`, `programado`, `recebido`, `a_receber`, `aplicado`, `saldo`,
`maior_espera_dias` e `detalhe` (uma entrada por produto, com o
fornecedor).

**Quem calcula o quê.** `programado` e `recebido` saem da visão
`vw_insumo_saldo`, no banco. `aplicado` e `saldo` saem da FOTO que o app
grava dentro da própria remessa (`payload.alocacoes[].apl` e `.sal`),
regravada sozinha a cada sincronização — pelo mesmo motivo do planejado ×
executado da v78: transformar o lançamento do boletim em quilos depende do
de-para de produtos e das doses, que moram no index.html. A foto é do par
unidade × produto (acumulada), então a visão `vw_insumo_aplicado` usa o
MAIOR valor do par, nunca a soma das remessas. **Sem foto, o relatório traz
programado e recebido e deixa `aplicado` nulo — nunca estima.**

**Regra que não se discute:** "a receber" e "sem recebimento registrado"
são ausência de REGISTRO — nunca afirmação de que a carga não saiu nem de
que o serviço não foi feito. Divergência entre programado e recebido é
assunto do escritório (painel da Diretoria), nunca cobrança do campo.
Regra completa em CLAUDE.md, item c18.

## Calendário resumido (para a vistoria de segunda)

| Quando | Relatórios previstos |
|---|---|
| Todo dia (motor, 05:00) | 1 (farol 7 e 30), 5 diário, 7 diário, 15 diário — sozinhos, no app em 📊 Relatórios |
| Segunda | 3 (vistoria do sistema, Code); 4 parcial do mês (motor, 05:30) |
| Sexta | 2 (devolutiva semanal); 5, 6 e 7 da semana (motor, 05:10) |
| Dia 1 (motor, 05:20) | 9 (custo físico), 14 (rebanho) e 4 (plano) do mês fechado |
| Toda semana (dia livre) | 8, 10, 16, 19 (painel) |
| Todo mês (até dia 10) | 5 (mensal, prompt), 10 (mensal), 12*, 13*, 18, 23; **25 (ata × executado, motor no dia 9)** |
| Trimestral | 20*, 21 |
| Por ciclo/safra ou censo | 11, 17*, 22, 24* |

`*` = ainda AGUARDA; não cobrar enquanto o status não mudar.

## Motor de relatórios automáticos (v55)

Desde a v55 os relatórios marcados "motor" saem sozinhos: o Supabase
calcula em horário agendado (pg_cron) e grava o resultado pronto na
tabela `relatorios_gerados`; o app só lê e mostra (Diretoria/ADMIN ›
botão 📊 Relatórios no topo do painel ou atalho na tela de entrada →
tela com "Textos para revisar" em cima e "Números" embaixo, v58;
gerente › cartão 📊 Meus relatórios, só da unidade dele).
Nada é calculado no celular além de formatação (nome do talhão pelo
cadastro do `index.html`, datas, números). Arquivos:
`sql/020-relatorios-motor.sql` (tabelas, funções, agenda) e
`sql/021-relatorios-teste.sql` (chamadas manuais + consultas de
conferência). Diário de bordo das rodadas: `relatorios_execucoes`.

Uma linha por relatório × período × unidade (`unidade_id`); a linha com
`unidade_id` nulo é o placar do grupo e só vai para aparelhos com painel.
O app baixa (`baixarRelatorios`, dentro de `syncTudo`) só as unidades do
escopo do código de acesso, com filtro `unidade_id=in.(...)` na REST e uma
trava local que descarta qualquer linha de fora; guarda em `bdf:relatorios`
(farol: 8 dias; diários: 14 dias; semanais/mensais: 60 dias) e funciona
offline com o último baixado. Tabela ainda não criada = silêncio (a
seção diz "ainda não há relatório calculado").

Agenda (UTC no cron; Brasília = UTC−3): diário 08:00 UTC = 05:00 BRT
(`rel_rodar_diario`); sexta 05:10 (`rel_rodar_semanal`, semana = últimos 7
dias até quinta); dia 1 05:20 (`rel_rodar_mensal`, mês anterior fechado);
segunda 05:30 (`rel_rodar_plano`, mês corrente até domingo). Não colide
com os robôs iCrop (03:50–04:20 e 09:45–10:15) nem Solinftec (03:05 e :35
de cada hora).

| chave (`relatorio`) | o que lê (tabela → campos reais do app) |
|---|---|
| `farol_7`, `farol_30` | `boletins` (fazenda_id, data, payload->>'exemplo'); lista de unidades em `rel_unidades` (espelho de FAZENDAS do index.html). Domingo não conta; "em dia" = boletim no último dia do período ou no anterior. |
| `dito_medido_icrop_dia` / `_semana` | `boletins.payload`: grãos `irg[]` (nome, k, status, lamina, percent), café `irr.status`, `clima.chuvaMm`; `icrop_manejo`: fazenda, equipamento, parcela, data, irrigacao_mm, precipitacao_mm, `bruto->>chuva_pluviometro`, `bruto->>problemas_irrigacao`. Fazenda pelo de-para `rel_icrop_depara` (= DEPARA_ICROP); unidade café × grãos pela palavra "caf" no equipamento/parcela (regra do icropDo); pivô casado pelo NÚMERO (chavePivo). Divergências: disse rodou sem lâmina, disse não rodou com lâmina, lâmina diferente (> 20% e > 1 mm), sem medição, sem registro; chuva com diferença > 5 mm. |
| `dito_medido_solinftec_dia` / `_semana` | `solinftec_diario` (fazenda_id, data, equipamento, operacao, cd_operacao, talhao, horas, motor_h, ocioso_h, area_ha, consumo_l) × `boletins.payload.atividades[].maquinas[]` (nome, horas, comb) + tipo/talhaoId. Por fazenda física (unidades irmãs recebem a mesma linha, `compartilhado: true`); máquina casada pelo número "COD nn". Divergência: horas diferentes > 30%, medido sem apontamento, apontado sem medição, sem boletim no dia. |
| `irrigacao_rec_exec_semana` | `icrop_manejo` (irrigacao_mm, etc, eto e `bruto->>` percentimetro_recomendado, tempo_de_irrigacao, lamina_minima, deficit_previsto, deficit_consolidado, dias_em_atraso, eficiencia_irrigacao, reais_por_irrigacao_necessaria, reais_por_irrigacao_realizada, area_da_parcela, reais_mm_ha). Percentímetro/tempo EXECUTADOS só se a iCrop mandar no bruto (chaves tentadas: percentimetro_realizado/executado, tempo_realizado/executado); senão fica nulo e a execução é a lâmina. |
| `balanco_hidrico_dia` | `icrop_manejo` (eto, etc, irrigacao_mm, precipitacao_mm e `bruto->>` deficit_consolidado, deficit_previsto, umidade, capacidade_de_campo, umidade_de_seguranca, dias_em_atraso, fase_atual, gd_dia_acumulado, acumulado_irrigacao, acumulado_precipitacao, problemas_irrigacao). Alerta: atraso ≥ 3 dias ou umidade abaixo da segurança. |
| `custo_fisico_talhao_mes` | `boletins.payload`: atividades[] (talhaoId, tipo, pessoas, maquinas[] nome/horas/comb, insumos[] nome/dose/qtd, produtos[] nome/dose/un, receita, areaHa, produtoAdb/produtoTipo/formulacao/produtoInoc, doseKgHa/doseTHa/doseInoc), irg[] (k, nome, quimiProdutos[]), irr (fert, fertSetores, fertReceita), mo (proprios, diaristas, faltas, horasExtras, funcoes[] nome/prop/pessoas/diar/hx); `icrop_manejo` (irrigacao_mm, `bruto->>` reais_mm_ha, reais_por_irrigacao_realizada/necessaria, area_da_parcela) casada ao talhão pelo número do pivô de irg; `solinftec_diario` por talhão (nome da Solinftec). `custo_rs` fica nulo até o ERP. |
| `rebanho_mes` | `boletins.payload.pecuaria` das unidades PECUARIA: mov[] (tipo, categoria, qtd, modo, sexo, parto, causa, brinco, pastoDe/Para, contraparte), lotes[] (talhaoId, lote, cabecas — última contagem), rep (dgPrenhes, dgVazias, coberturas, iatfEtapa, iatfQtd, ocorTouro), san[], massa[], nut[] (talhaoId, insumo, qtd, un, cocho, agua), pasto.condicao, cocho/sal/agua, eventos[] (tipo, lote, qtd, pesoMedio, valor, contraparte). GMD só com duas pesagens do mesmo lote; lotação pendente (área do pasto não está no Supabase). |
| `plano_x_executado_diario` (v75) | `vw_plano_x_executado` (sql/048) sobre `boletins.payload -> 'plano'`: itens[] (op, ondes[], pessoas, status feito/parcial/nao_feito calculado pelo APP a partir dos registros do próprio boletim), clima (cond, chuvaMm, impedido), motivo (id clima/chuva/maquina/gente/insumo/prioridade/outro; vazio = não informado), replanejado, pessoasPrev × pessoasReal; nomes de unidade em `rel_unidades`. Uma linha por unidade + a linha do grupo. Métricas: aderência = itens `feito` / itens; dias com plano; replanejados; dias impedidos; desvios de clima × evitáveis (dia impedido NUNCA entra em evitável); precisão de esforço = pessoas lançadas / previstas; distribuição de motivos por dia com desvio. Nada é recalculado no SQL: o status vem do app. |
| `plano_executado_mes` | `plano_safra` (vigente por fazenda_app — mapa em `rel_unidades.fazenda_app` = PLANO_FAZENDA_APP), `plano_unidade`, `unidade_manejo`, `unidade_alias` (sistema app → talhaoId), `plano_adubo_mes`, `plano_calagem` (janela), `plano_fito_mes`/`plano_fito_excecao`, `plano_gantt`, `plano_parametros` × `boletins.payload`: atividades[].tipo por talhaoId (adubo = "Adubação via lanço"/"Adubação orgânica"/irr.fert Sim + fertSetores; calagem = "Calagem / gessagem"; fito = "Pulverização"/"Aplicação via drench / via solo"/"Monitoramento de pragas (MIP)" + fito[]), colheita[]. Faróis: verde registrado, branco em andamento, amarelo sem registro (após o dia `adubo_dia_limite_cadencia` / `gantt_pct_janela_amarelo` % da janela / `fito_dias_sem_monitoramento` dias), vermelho só com a janela fechada, cinza sem apelido app. Produtos só como "previsto pelo agrônomo". |

Formato de `dados`: JSON por unidade com `resumo` (contagens para o farol
da lista), tabelas por pivô/talhão/lote e `divergencias[]` com texto
pronto ("para conferir", nunca "erro"). Ver exemplos rodando
`sql/021-relatorios-teste.sql`. Unidade nova no app precisa de um `insert`
em `rel_unidades` (o farol lista quem existe por essa tabela).

## Robô-redator (fase 2, v57)

`sql/030-redator.sql` liga a API da Claude ao motor: para cada relatório
narrativo cadastrado em `relatorios_modelos` (texto-modelo em
`docs/redator-modelos.md`), o Supabase monta uma linha composta em
`relatorios_gerados` (`dados.fontes` = fontes da fase 1 compactadas) e
pede o texto à API (`net.http_post` → `net._http_response`, dispara/colhe
como o robô iCrop). O texto vai para `relatorios_gerados.texto`; o app o
mostra acima dos números, marcado "gerado automaticamente — revisar antes
de enviar", com o botão "copiar para WhatsApp". A chave da API vive só em
`segredos` (sql/031); nenhuma chamada sai do app.

| chave | cadência | quem | fontes (fase 1) | agenda (UTC) |
|---|---|---|---|---|
| `devolutiva_semanal` | semana (últimos 7 dias até quinta) | uma por unidade ativa | `farol_7`, `dito_medido_icrop_semana`, `dito_medido_solinftec_semana` | sexta 08:20 dispara / 08:35 colhe |
| `painel_executivo` | mês anterior fechado | linha do grupo | `farol_30`, `custo_fisico_talhao_mes`, `rebanho_mes`, `plano_executado_mes`, semanas de `irrigacao_rec_exec_semana` e dito × medido, resumos do mês anterior | dia 8 08:20 / 08:35 |
| `alerta_divergencia` | manual (sql/032) | por unidade e dia | `dito_medido_icrop_dia`, `dito_medido_solinftec_dia` | — |

### Tela "Textos para revisar" (v68): cartão colapsado + folha de leitura

Desde a v68 cada texto do redator entra na tela (Diretoria › 📊
Relatórios, seção "Textos para revisar", e a tela do relatório narrativo
aberta por "ver com os números ›") pelo componente único
`cartaoTextoLongo` do `index.html` (CLAUDE.md, item c7). O cartão nasce
**colapsado**: tag "gerado automaticamente — revisar antes de enviar",
título (unidade destinatária), prévia de 3 linhas cortada por linha
inteira com reticências, linha compacta de origem e dois botões lado a
lado — "ler texto completo ›" e "📲 copiar para WhatsApp". Copiar
funciona sem expandir e copia o texto integral de
`relatorios_gerados.texto` (nunca a prévia). Texto curto (cabe nas 3
linhas) não mostra reticências nem "ler texto completo".

"ler texto completo ›" abre uma folha de tela cheia (não expande na
lista): cabeçalho fixo com "‹ Fechar", a tag, o texto completo rolável,
a origem completa e um rodapé fixo com Fechar e copiar. Ao fechar, a
lista volta à posição de rolagem de antes.

Regra da origem: no cartão só a versão compacta, `robô-redator ·
dd/mm hh:mm` (de `texto_em`); a completa — "Redigido no Supabase por
<texto_modelo> em dd/mm, hh:mm a partir dos números do relatório" — só
na folha. O aviso "Confira e ajuste antes de mandar" saiu do rodapé: a
tag já diz isso. O texto continua SÓ leitura no app: o ajuste é feito
no WhatsApp, depois de colar; nada é editado nem gravado.

Na lista "Números": quando o total de unidades e o número "para
conferir" coincidem, a linha diz "N unidades · todas para conferir"
("1 unidade · para conferir" no singular); diferentes, os dois números
continuam.

Pedido: modelo `claude-sonnet-4-6`, `max_tokens` 1500 (300 no alerta),
system = instruções do modelo, uma mensagem de usuário com data, unidade,
período e o JSON das fontes. Custo típico: devolutiva ≈ 2,5 mil tokens de
entrada + 300 de saída (≈ US$ 0,01); painel ≈ 10 mil + 800 (≈ US$ 0,05);
alerta ≈ 1 mil + 100. Diário de bordo: `relatorios_reqs` (status e tokens)
e `relatorios_execucoes`. Erro 401/403 = chave errada (rodar sql/031);
429 = limite de taxa; "perdido" = resposta não chegou em 6 h.

## Visão `vw_dias_sem_registro` (v59) — dias sem registro por unidade × operação

Métrica de leitura, calculada no Supabase, que diz **há quantos dias uma
operação não é registrada em uma unidade operacional**. Hoje o farol de
completude (nº 1) é binário — boletim enviado ou não; esta visão separa
"3 dias sem registro" de "47 dias sem registro" sem criar ranking entre
fazendas e sem afirmar que alguém deixou de fazer algo. Arquivo:
`sql/040-dias-sem-registro.sql` (bloco único, passo a passo no cabeçalho;
pré-requisito: `sql/020`, já rodado). Conferência opcional:
`sql/041-dias-sem-registro-teste.sql`.

O que o bloco cria:

| objeto | o que é |
|---|---|
| `operacao_catalogo` | catálogo mestre de operações (id imutável `CAFE-…`, `GRAOS-…`, `PEC-…`; atividade, fase, nome, ordem, ativo). Espelho de LISTA_ATIV, OPS_GRAOS_FASES e OPS_PECUARIA_FASES do `index.html`, gerado por `scripts/gerar_catalogo_operacoes.cjs` (75 operações; "Outra" do café fica de fora). Só o SQL Editor escreve. |
| `operacao_alias` | de-para **texto exato gravado no payload → operacao_id** (origem + termo). 90 apelidos. Mesmo modelo de `unidade_manejo` + `unidade_alias`: identidade é o código, o nome é apelido. Um termo pode apontar para duas operações ("Mudança de pasto" = entrada e saída de lote). |
| `vw_dsr_registros` | ocorrências extraídas de `boletins.payload`: (unidade, data, origem, termo). Base da visão principal. |
| `vw_dias_sem_registro` | a métrica, uma linha por unidade ativa × operação ativa da atividade dela. |

Colunas de `vw_dias_sem_registro`:

| coluna | descrição |
|---|---|
| `unidade_id` | id da unidade no app (`rel_unidades.id`: f33, f26…) — ids antigos passam por `rel_fz_atual` |
| `operacao_id` | `operacao_catalogo.id` |
| `atividade` | CAFE / GRAOS / PECUARIA (a da unidade em `rel_unidades.perfil`) |
| `operacao_nome`, `fase` | nome e fase do catálogo (só para exibição) |
| `data_ultimo_registro` | data do boletim mais recente com essa operação nessa unidade; NULL se nunca houve |
| `dias_sem_registro` | inteiro: hoje (Brasília, `rel_hoje_brt`) − `data_ultimo_registro`; **NULL se nunca houve** |
| `nunca_registrado` | true quando não há nenhum registro dessa combinação |

**NULL ≠ 0.** `dias_sem_registro = 0` significa "registrado hoje";
`dias_sem_registro` NULL com `nunca_registrado = true` significa "não há
histórico nenhum" — são situações diferentes e a visão nunca as confunde
(nem usa 0, nem um número grande, para a ausência). A visão **não julga**:
não há coluna de status, farol, atraso ou equivalente; a janela e a cor
são decisão de outra camada (item futuro do backlog). Não filtra por
perfil de acesso — isso é da camada de leitura.

De onde vem cada registro (`boletins.payload`, boletins "exemplo" fora):

| origem no payload | termo casado (igualdade exata) | operação |
|---|---|---|
| `atividades[].tipo` | nome da LISTA_ATIV (café) / OPS_GRAOS_FASES (grãos) | a própria |
| `pecuaria.eventos[].tipo` | nome da OPS_PECUARIA_FASES ("Outros manejos") | a própria |
| `pecuaria.mov[].tipo` | Nascimento · Morte · Desmama · Entrada · Saída · Mudança de pasto | Parto / nascimento · Mortalidade · Desmama · Compra / entrada · Embarque / venda · Rotação de pasto (entrada E saída) |
| `pecuaria.massa[].tipo` | Vacinação · Vermifugação | Vacinação · Vermifugação |
| `pecuaria.san[].problema` | Bicheira · Carrapato / mosca em excesso | Cura de bicheira · Controle de carrapato / mosca-do-chifre |
| `pecuaria.lotes[]` (cabeças > 0) | `*` (basta existir) | Contagem |
| `pecuaria.nut[]` (insumo preenchido) | `*` | Suplementação |
| `pecuaria.rep.iatfEtapa` | `*` | IATF |
| `pecuaria.rep.dgPrenhes` / `dgVazias` (> 0) | `*` | Diagnóstico de gestação |

Nenhuma junção usa LIKE ou pedaço de nome: "Capina" gravado à mão não
vira "Capina manual". Termo do app que não esteja em `operacao_alias`
simplesmente não conta — para incluir, inserir o apelido (SQL Editor).
Termo novo no catálogo do `index.html`: rodar o script gerador e recolar
o trecho entre os marcadores do `sql/040`. Unidade nova no app: inserir
em `rel_unidades` (como já vale para o motor).

Consumo no app (v59): `baixarDiasSemRegistro({atividade, unidade})` lê a
visão pela REST (só unidades do escopo do código, com trava local),
guarda em `dsrCache` e em `bdf:diasSemRegistro`; `diasSemRegistroDe(unidade,
operacao)` e `textoDiasSemRegistro(linha)` ("há 12 dias" / "hoje" / "sem
registro") ficam prontos para telas futuras. A função não roda na
sincronização; quem mostra o número é a `vw_farol_registro` (v60), em
Diretoria › Faróis de registro › unidade. Desde a v65 as unidades de café
também aparecem lá (sem janela: só "há N dias" / "sem registro" por
operação, no bloco "Operações sem janela").

REST de leitura (chave publishable, filtros opcionais):
`rest/v1/vw_dias_sem_registro?select=*&atividade=eq.PECUARIA&unidade_id=eq.f26&order=operacao_id`.

## Janela e farol de registro — `operacao_janela` + `vw_farol_registro` (v60)

Camada de julgamento em cima da visão de dias sem registro: a **janela** de
uma operação é a cadência com que a Diretoria espera ver um registro dela
no boletim (`cadencia_dias`) mais uma tolerância (`tolerancia_dias`, a
janela fica aberta por mais N dias). Arquivo: `sql/042-janela-farol.sql`
(bloco único, passo a passo no cabeçalho; pré-requisitos: sql/020 e 040).
Janela **não é prescrição**: não diz o que fazer no campo, com que produto
ou dose — diz onde a Diretoria deve olhar.

| objeto | o que é |
|---|---|
| `operacao_janela` | operacao_id, unidade_id (nulo = geral da atividade; linha por unidade vence a geral e pode desligar com `ativo = false`), cadencia_dias, tolerancia_dias, origem (proposta / agronomo / veterinario / nilo), obs, ativo. Só o SQL Editor escreve. |
| `vw_dsr_boletim_unidade` | primeiro e último boletim por unidade (referência para "nunca registrado"). |
| `vw_farol_registro` | todas as colunas de `vw_dias_sem_registro` + primeiro_boletim, cadencia_dias, tolerancia_dias, janela_origem, janela_da_unidade, **farol**, fecha_em_dias, **situacao** (texto pronto). |

Regras do farol (calculadas no Supabase; o app só mostra):

| farol | quando | texto (`situacao`) |
|---|---|---|
| nulo | operação sem janela (ou janela desligada) | — (o app mostra "há N dias" / "sem registro") |
| cinza | unidade sem nenhum boletim | "unidade sem boletim · sem histórico" |
| verde | registrado há ≤ cadência dias | "registrado hoje" / "registrado há N dias" |
| amarelo | sem registro, mas dentro de cadência + tolerância | "sem registro há N dias · janela aberta, fecha em M dias" |
| vermelho | **só depois de a janela fechar** (> cadência + tolerância) | "sem registro há N dias · janela fechada há M dias" |

Nunca registrado: os dias contam desde o **1º boletim da unidade** e o
texto diz isso ("sem registro desde o 1º boletim (há N dias) · …"); nunca
vira verde. Vocabulário fixo: "sem registro", "janela aberta", "janela
fechada", "em dia" — nunca "não fez", "atrasado", "pendente".

Janelas propostas no seed (origem `proposta`, para o Nilo, o agrônomo e o
veterinário ajustarem por SQL): pecuária — suplementação 7 (+3),
conferência de água 7 (+3), contagem 30 (+10), controle de carrapato /
mosca 30 (+15), manutenção de cerca / cocho / bebedouro 30 (+15), controle
de formiga 60 (+30), pesagem 90 (+30), vermifugação 90 (+30), vacinação
180 (+30); grãos — monitoramento de pragas e doenças 7 (+3), que só faz
sentido com lavoura no campo (desligar por unidade no vazio: linha com
`unidade_id` e `ativo = false`). **Café não tem janela** nesta versão: já
tem os faróis do plano de safra (`plano_executado_mes`).

Consumo no app (v60): `baixarFarolRegistro()` (dentro de `syncTudo`, só
para códigos com painel) lê a visão para as unidades do escopo e guarda em
`bdf:farolRegistro`; telas **Faróis de registro** (`farois`: lista por
unidade, pior cor manda, busca) e **unidade** (`farol`: operações com
janela ordenadas por cor; "Operações sem janela" fechado embaixo), abertas
pelo botão "Faróis de registro" do painel da Diretoria. O gerente não baixa
nem vê. REST: `rest/v1/vw_farol_registro?select=*&farol=not.is.null&order=unidade_id`.

## Intervalo entre operações — `vw_intervalo_operacoes` + `vw_ritmo_operacoes` (v62)

Métrica de leitura, calculada no Supabase, que diz **de quanto em quanto
tempo uma operação vem sendo registrada em uma unidade operacional** — o
ritmo. Vem do rodapé de cada manejo do app Sigma (Fundação ABC):
"Intervalo de 35 dias entre manejos". Arquivo:
`sql/043-intervalo-operacoes.sql` (bloco único, passo a passo no
cabeçalho; pré-requisitos: `sql/020` e `sql/040`, já rodados). Conferência
opcional: `sql/044-intervalo-operacoes-teste.sql`. Não cria tabela nem
grava nada: são duas visões.

### Não confundir com "dias sem registro"

| métrica | olha para | mede | muda quando |
|---|---|---|---|
| `dias_sem_registro` (v59, `vw_dias_sem_registro`) | do **último registro até hoje** | a lacuna corrente, **aberta** | todo dia, mesmo sem boletim novo |
| `intervalo_dias` (v62, `vw_intervalo_operacoes`) | entre **dois registros consecutivos do passado** | o ritmo histórico, **fechado** | só quando entra um registro novo |

Uma unidade pode ter ritmo mediano de 20 dias e estar há 3 dias sem
registro (normal) ou há 60 dias sem registro (vale olhar). O par das duas
diz mais que qualquer uma sozinha; em relatório, as duas vêm lado a lado e
nunca uma no lugar da outra. `data_ultimo_registro` é a mesma nas duas
visões (conferido).

### O que é um registro

Um **dia** em que a operação aparece no boletim da unidade. O boletim é um
por unidade por dia (índice único `fazenda_id` + `data`); a mesma operação
lançada em vários talhões, lotes ou pastos do mesmo boletim é o **mesmo
registro do dia** — a coluna `lancamentos_no_dia` guarda quantos foram.
Por isso `intervalo_dias = 0` não acontece com o app de hoje. Se um dia
dois boletins da mesma unidade caírem na mesma data (ids antigos que
apontam para a mesma unidade, por exemplo), continuam sendo um registro
do dia: nada é descartado como erro. Contar cada lançamento em vez de cada
dia faria a mediana de uma unidade com 4 pivôs (4 lançamentos de fungicida
no mesmo boletim) cair para 0 — testado: 0 por lançamento contra 14 por
dia — e o ritmo mentiria.

### Objetos e colunas

| objeto | o que é |
|---|---|
| `vw_intervalo_operacoes` | uma linha por registro (dia) de cada unidade × operação, com o registro anterior da mesma combinação. Base: `vw_dsr_registros` + `operacao_alias` (mesma extração da v59, nada repetido) filtrada por `operacao_catalogo.ativo` e `rel_unidades.ativo` com a atividade no perfil da unidade (mesmas combinações da `vw_dias_sem_registro`). `LAG()` particionado por unidade e operação, ordenado por data. |
| `vw_ritmo_operacoes` | agrega a anterior: uma linha por unidade × operação **com pelo menos um registro**. |

Colunas de `vw_intervalo_operacoes`:

| coluna | descrição |
|---|---|
| `unidade_id` | `rel_unidades.id` (ids antigos passam por `rel_fz_atual`) |
| `operacao_id` | `operacao_catalogo.id` |
| `atividade` | CAFE / GRAOS / PECUARIA (a da operação no catálogo, igual à do perfil da unidade) |
| `data_registro` | data do boletim com a operação |
| `data_registro_anterior` | data do registro imediatamente anterior da mesma combinação; **NULL no primeiro** |
| `intervalo_dias` | `data_registro − data_registro_anterior`; **NULL no primeiro registro** (nunca 0 no lugar de "não há anterior") |
| `lancamentos_no_dia` | quantos lançamentos da operação havia naquele boletim (talhões, lotes, pastos) |

Colunas de `vw_ritmo_operacoes`:

| coluna | descrição |
|---|---|
| `unidade_id`, `operacao_id`, `atividade` | identificação, como acima |
| `qtd_registros` | total de registros (dias) da combinação |
| `qtd_intervalos` | total de intervalos observados = `qtd_registros − 1` |
| `intervalo_mediano_dias` | **mediana** dos intervalos (`percentile_cont(0.5)`, 1 casa decimal); NULL com menos de 2 registros |
| `intervalo_minimo_dias`, `intervalo_maximo_dias` | menor e maior intervalo; NULL com menos de 2 registros |
| `data_ultimo_registro` | data mais recente |

**Mediana, não média.** Um único intervalo longo (paralisação por chuva,
troca de equipe) puxa a média para cima e ela passa a mentir sobre o ritmo
típico; a mediana não se mexe. Exemplo testado: roçada em −60, −50, −40 e
−3 dias → intervalos 10, 10 e 37 → mediana 10, média 19. Mínimo e máximo
vão junto para quem quiser ver a faixa.

**Amostra de 1 não vira estatística.** Combinação com um registro só traz
`qtd_intervalos = 0` e as três colunas de intervalo NULL — nada é
fabricado sobre amostra que não existe (o erro do Sigma ao desenhar dois
pontos como série).

**As visões não julgam.** Não há coluna de status, farol, "atrasado",
"fora do padrão" nem "ritmo esperado": não existe padrão cadastrado e
inventá-lo seria prescrição. Janela e cor continuam na `vw_farol_registro`
(v60). Não filtram por perfil de acesso (isso é da camada de leitura);
as três atividades entram pela mesma regra (até a v64 o app só lia grãos
e pecuária; desde a v65 lê café também). Nenhuma junção usa LIKE ou
pedaço de nome. Nenhum texto compara unidades ou fazendas.

Consumo no app (v62): `baixarRitmoOperacoes({atividade, unidade})` lê a
visão de resumo pela REST (só unidades do escopo, com trava local; a
atividade pode ser uma ou uma lista), guarda em `ritmoCache` /
`bdf:ritmoOperacoes`; `baixarIntervaloOperacoes(filtro)` lê os pares sob
demanda, sem cache; `ritmoDe(unidade, operacao)` e `textoRitmo(linha)`
("a cada 18 dias"; vazio quando `qtd_intervalos = 0`) servem as telas. Em
`syncTudo`, só códigos com painel baixam (até a v64 só GRAOS e PECUARIA;
desde a v65 as três atividades). Onde aparece: Diretoria › Faróis de
registro › unidade, como texto secundário "ritmo: a cada N dias" ao lado
de "sem registro há N dias" — as duas métricas juntas — nas três
atividades e apenas com dois registros ou mais; sem intervalo a linha é
omitida (nada de "sem ritmo" ou traço). O eixo de ciclo do café (florada,
poda) não entra aqui: a métrica mede o intervalo entre dois registros
consecutivos, sem marco (eixo de ciclo é item da Onda 2).

REST de leitura (chave publishable, filtros opcionais):
`rest/v1/vw_ritmo_operacoes?select=*&atividade=in.(GRAOS,PECUARIA)&unidade_id=eq.f33&order=operacao_id`
e `rest/v1/vw_intervalo_operacoes?select=*&unidade_id=eq.f33&operacao_id=eq.GRAOS-FUNGICIDA&order=data_registro`.

## Estado das integrações — `vw_status_integracoes` (v63)

Visão de leitura que diz **de quando é o dado que veio de fora** (iCrop e
Solinftec). Vem do app Sigma (Fundação ABC), que carimba cada bloco de
estação meteorológica com "Transmitido em 07/09/2026 às 08:00": quem lê
nunca confunde "agora" com "a última vez que o sistema conseguiu buscar".
Arquivo: `sql/045-status-integracoes.sql` (bloco único, passo a passo no
cabeçalho; pré-requisitos: robô iCrop no ar, `sql/003` rodado, pg_cron e
pg_net ligados). Uma linha por fonte (`icrop`, `solinftec`), tudo em UTC.

### Três horários que nunca se colapsam

| coluna | pergunta que responde | de onde vem | avança quando |
|---|---|---|---|
| `ultima_execucao_em` | quando o robô **tentou** pela última vez? | `cron.job_run_details` (diário do pg_cron), pelos jobs listados em `integracao_job` | a cada disparo do pg_cron, deu certo ou não |
| `ultima_execucao_ok_em` | quando a API de origem **respondeu OK** pela última vez? | iCrop: `integracao_execucoes` (HTTP 200 colhido de `net._http_response`); Solinftec: o mesmo diário do pg_cron com `status = 'succeeded'` (a função lança erro em resposta ≠ 200) | só com resposta boa da API |
| `ultimo_dado_em` | quando o último **dado foi gravado** no Supabase? | `max(atualizado_em)` de `icrop_manejo` / `solinftec_diario` | só quando o robô escreve linha nova ou regrava |
| `ultimo_dado_origem` | a que **dia** o dado mais recente se refere, lá na origem? | `max(data)` das mesmas tabelas | só com medição de dia novo |
| `horas_desde_ultimo_sucesso` | há quantas horas inteiras a API não responde OK? | conta sobre `ultima_execucao_ok_em`; NULL sem sucesso conhecido | — |

Exemplos reais (07/09/2026): a iCrop respondeu 200 de madrugada
(`ultima_execucao_ok_em` de hoje), mas a última gravação é de 02/09 e o
dado mais novo é de 30/08 — robô e token bons; ciclos vencidos na Vision.
Se um dia o robô rodar e a API falhar, `ultima_execucao_em` avança sozinha.
Colapsar qualquer um desses horários no outro é o que faz dado velho
parecer novo; por isso a visão devolve os quatro e a tela escolhe o que
mostrar (`ultimo_dado_em` na linha de origem; `ultima_execucao_ok_em` para
decidir se o dado está velho).

### Por que a iCrop precisa de um diário próprio

O robô iCrop é assíncrono (pg_net): a função `icrop_passo2_manejo` termina
"succeeded" no pg_cron **antes** de a iCrop responder, e `icrop_reqs` guarda
só `req_id`, `criado_em`, `tipo` e `id_fazenda` — nenhum status. O status
HTTP fica em `net._http_response`, que a pg_net apaga em poucas horas. O
`sql/045` cria `integracao_execucoes` (fonte, req_id, tipo, pedido_em,
respondido_em, status_code, ok) e a função `integracao_colher_icrop()`, que
copia para lá o status de cada pedido ainda vivo; o pg_cron a chama às
07:35 e 13:30 UTC (04:35 e 10:30 em Brasília), 15 minutos depois de cada
rodada do robô, e o próprio bloco faz uma colheita na hora. Até a primeira
colheita, `ultima_execucao_ok_em` da iCrop é NULL — nunca estimado.
"Sucesso" da iCrop = qualquer pedido do robô (manejo ou parcelas) com
resposta 200; a coluna `tipo` do diário permite separar isso no futuro.

### Identidade, fuso e segurança

- Fonte ↔ job do pg_cron por tabela de-para (`integracao_job`), nome
  **exato** — nunca LIKE nem pedaço de nome (regra 6). Job novo do robô =
  linha nova (exemplo no fim do arquivo SQL).
- Tudo sai em UTC (`timestamptz`). Converter para Brasília é papel da
  tela: o `index.html` usa `America/Sao_Paulo` explícito
  (`textoOrigemDado`, `fmtDHBRT`), independente do fuso do aparelho.
- A visão roda com as permissões de quem a criou (postgres), porque
  `cron.*` e `net.*` não são legíveis pela chave pública; expõe SÓ
  horários agregados e o nome da fonte — nenhuma mensagem de erro,
  nenhum conteúdo de resposta. A função de colheita fica revogada para
  anon/authenticated.
- A visão não julga: sem farol, sem "parado", sem "atrasado". O limiar
  de "dado velho" (26 h sem sucesso) é decisão da tela.

### Como o app usa (v63)

`baixarStatusIntegracoes` (na sincronização, em todo aparelho com
sync) guarda as linhas em `bdf:statusIntegracoes`. `textoOrigemDado(fonte)`
monta uma linha por bloco de dado externo, no rodapé, em tipografia
secundária: "Dados do iCrop de hoje, 04:05" / "de ontem, 04:20" / "de
05/09, 04:05" (hoje/ontem pelas duas datas mais recentes em Brasília).
Com mais de 26 h sem sucesso: "Última atualização do iCrop há 2 dias" em
cor de atenção, sem ícone, sem exclamação, sem bloquear. As horas são
recontadas no aparelho (o número da visão envelhece no cache). Onde
aparece (v64, decisão do Nilo em 08/09/2026 de incluir o café): cartão
iCrop do boletim do gerente (café e grãos), cartão Solinftec da casa do
gerente (café, grãos e pecuária), cartões "iCrop — medição de ontem" e
"Solinftec — medição de ontem" do painel da Diretoria, e o bloco "Estado
dos robôs" em Escritório › Integrações e robôs. Sem linha: pós-colheita
(não tem dado de integração) e a dica de chuva na seção Clima (o cartão
iCrop do mesmo boletim já a carrega).

## Resposta explícita de ausência — `boletim_secao`, `boletim_secao_resposta` + `vw_completude_boletim` (v69)

Núcleo conceitual: **"não respondido" e "sem ocorrência" são coisas
diferentes** — é o mesmo problema de "sem registro × não fez", aplicado
à ENTRADA em vez da leitura. Até a v68, um cartão vazio de Pragas ou de
Ocorrências podia significar "olhei e não havia" ou "ninguém abriu";
qualquer relatório de sanidade herdava essa ambiguidade. Desde a v69 o
gerente toca em **"Nada a registrar hoje"** e a ausência vira um
REGISTRO, com autor e hora. Arquivo: `sql/047-secao-resposta.sql`
(bloco único, passo a passo no cabeçalho; pré-requisito: `sql/020`).

| estado da seção eventual | como se reconhece | significa |
|---|---|---|
| **com registro** | `boletim_secao_registros(payload, campos) > 0` | há lançamento (praga, ocorrência, movimento, tratamento) |
| **sem ocorrência** | linha em `boletim_secao_resposta` (`resposta = 'sem_ocorrencia'`) | alguém olhou e declarou que não há o que registrar; sabe-se quem e quando |
| **não respondido** | nem registro nem linha | a seção não foi respondida — ausência de resposta, NUNCA "não fez" nem "não havia" |

Desde a v70 o app não envia boletim com seção eventual sem resposta, então
"não respondido" só aparece no histórico anterior e em aparelhos ainda
não atualizados (a visão continua calculando).
Não existe valor "pendente" nem "não respondido" gravado: a ausência de
linha É o não respondido (gravar um enum duplicaria o estado e criaria
divergência). "Sem ocorrência" e registro nunca coexistem: o app apaga
a resposta ao adicionar um registro, e o banco confere de novo (gatilho
`boletim_secao_resposta_trava`).

| objeto | o que é |
|---|---|
| `boletim_secao` | catálogo das seções do boletim por atividade: `id` (chave substituta imutável: CAFE-FITO, GRAOS-FITO_OCOR, PEC-MOV…), `atividade`, `nome` (só rótulo), `tipo` (eventual / esperada), `campos` (caminhos das listas do payload que contam como registro), `ordem`, `ativo`. Espelho de `SECOES_BOLETIM` do index.html e da tabela em docs/catalogos-por-atividade.md. Só o SQL Editor escreve. |
| `boletim_secao_resposta` | a resposta: `id` (uuid), `boletim_id`, `secao_id` → `boletim_secao`, `atividade`, `resposta` (check: só `sem_ocorrencia` por ora), `respondido_por` (nome de quem preenche; `payload.secoes[].por`, senão `payload.responsavel`), `respondido_em` (hora do toque no chip, `payload.secoes[].em`), `fazenda_id`, `data` (cópias de boletins), `atualizado_em`; `unique (boletim_id, secao_id)`. |
| `boletim_secao_registros(payload, campos)` | soma `jsonb_array_length` dos caminhos em `campos` — o mesmo cálculo de `secaoRegistros` no app. |
| gatilho `boletins_secao_resposta` | em insert/update/delete de `boletins`: reescreve as linhas de `boletim_secao_resposta` daquele boletim a partir de `payload.secoes` (só seções eventuais ativas da atividade da unidade e só com 0 registros). É por isso que o app NÃO escreve na tabela: grava a resposta dentro do payload, na fila offline de sempre, sem policy de escrita, sem delete pela REST e sem depender de ordem de sincronização. Protegido por exception: nunca derruba o envio do boletim. Correção do boletim (mesmo id) e troca de id no upsert (merge) limpam as linhas antigas. |
| `vw_completude_boletim` | por boletim (sem "exemplo"): `boletim_id`, `unidade_id` (ids antigos por `rel_fz_atual`), `atividade`, `data`, `secoes_eventuais` (quantas a atividade tem), `com_registro`, `sem_ocorrencia`, `nao_respondidas` e os arrays `ids_com_registro`, `ids_sem_ocorrencia`, `ids_nao_respondidas`. Alimenta o farol de completude por seção (relatório nº 1, evolução prevista). |

Como o dado chega (app, v69): `rascunho.secoes = { "CAFE-FITO":
{resposta:"sem_ocorrencia", por:"João", em:"2026-09-08T14:03:00Z"} }`
sobe dentro do payload do boletim, como sempre. Leitura no app:
`baixarCompletudeBoletim({unidade, de, ate})` (sob demanda, sem tela;
mesma trava de escopo das outras visões). Segurança: leitura anon por
policy select nas duas tabelas; escrita só pelas funções (security
definer); visão com security_invoker. Boletins gravados antes de o SQL
rodar são reprocessados pelo próprio bloco (passo 6).

## Como rodar um relatório PRONTO no Cowork

Caminho curto (v54): no app, com código ADMIN, Escritório › Cadastros ›
"Abrir carteira de relatórios" abre a página
https://boletim-ncnaves.netlify.app/relatorios.html, que lê esta carteira
e os prompts direto da pasta docs e tem o botão "copiar prompt" em cada
um. O passo a passo manual é o mesmo:

1. Abrir `docs/relatorios/nn-nome.md` e copiar o prompt inteiro.
2. Abrir no Safari cada URL REST listada no prompt (a chave publishable
   já vai na URL; é a mesma que está no app), selecionar tudo e copiar.
   Ajustar as datas do período antes de abrir.
3. No Cowork: colar o prompt, depois colar cada resposta JSON logo
   abaixo do nome da tabela correspondente, e enviar.
4. O relatório sai em 1 página, no padrão da casa. Guardar o resultado
   na pasta do mês (é dele que o nº 23 é montado).

Todas as URLs partem de
`https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/` e usam a chave
publishable `sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5` (pública
por natureza; nenhum segredo vai em URL). Só há leitura: nenhum
relatório grava no banco.

## Avisos sobre as fontes

- **Ciclos de grãos não têm tabela própria.** O app guarda os ciclos no
  aparelho; no Supabase eles se reconstroem pelas operações de plantio
  e colheita dentro de `boletins.payload.atividades`. Por isso o nº 17
  espera a 1ª safra fechada e o censo de plantio.
- **Nomes de talhão** vivem no cadastro do `index.html` (talhaoId →
  nome). Nos prompts, quando o nome faltar, o relatório mostra o id e
  marca PENDENTE; a exportação CSV do painel já traz os nomes.
- **Ids antigos de fazenda** aparecem em boletins gravados por versões
  antigas (f19/f18 → f03c; f05/f15/f16/f14 → f14c; f03 → f03c;
  f22 → f22c; f13 → f13c). Os prompts já trazem esse de-para.
- **Tabelas ainda não criadas** (04/09/2026): plano_* (sql/005–007) e
  codigos_acesso (sql/001–002) respondem 404 até o Nilo rodar os SQL;
  os prompts 04 e 21 avisam e ficam PENDENTES até lá.
- **Códigos de acesso** nunca aparecem em relatório (regra do app: só
  a tela de ADMIN os mostra). O nº 21 lista chave/escopo, sem código.
