# Carteira de relatórios do Grupo LGS

Lista oficial dos relatórios que a Controladoria produz (ou vai
produzir) a partir do Boletim NCNaves e das integrações. Serve para
três coisas: saber o que existe, saber o que falta e conferir toda
semana o que estava previsto e não rodou (item da vistoria semanal em
`docs/vistoria-semanal.md`).

## Como ler a tabela

- **Fonte**: de onde saem os números. "app" = tabelas do Boletim
  (boletins, pos_colheitas, remessas, telemetria, boletim_pecuaria,
  codigos_acesso); "iCrop" = icrop_manejo, icrop_fazendas,
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
| 1 | Farol de completude | quem enviou/não enviou boletim | app | diário | painel + motor (`farol_7`, `farol_30`) | EXISTE |
| 2 | Devolutiva semanal por unidade | adesão, dito × medido, elogio | app + iCrop + Solinftec | sexta | Cowork | PRONTO — `docs/relatorios/02-devolutiva-semanal.md` |
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
| 23 | Painel executivo mensal | 1 página: produção, custo, água, máquinas, rebanho, adesão, 3 decisões | todos | dia 10 | Cowork | PRONTO — `docs/relatorios/23-painel-executivo.md` |
| 24 | Fechamento de safra por cultura | produtividade, custo, margem, decisões (renovar/arrancar/rotação/vender lote) | todos | anual | Cowork | AGUARDA fechamento da safra (e ERP para custo/margem) |

## Calendário resumido (para a vistoria de segunda)

| Quando | Relatórios previstos |
|---|---|
| Todo dia (motor, 05:00) | 1 (farol 7 e 30), 5 diário, 7 diário, 15 diário — sozinhos, em Diretoria › 📊 Relatórios |
| Segunda | 3 (vistoria do sistema, Code); 4 parcial do mês (motor, 05:30) |
| Sexta | 2 (devolutiva semanal); 5, 6 e 7 da semana (motor, 05:10) |
| Dia 1 (motor, 05:20) | 9 (custo físico), 14 (rebanho) e 4 (plano) do mês fechado |
| Toda semana (dia livre) | 8, 10, 16, 19 (painel) |
| Todo mês (até dia 10) | 5 (mensal, prompt), 10 (mensal), 12*, 13*, 18, 23 |
| Trimestral | 20*, 21 |
| Por ciclo/safra ou censo | 11, 17*, 22, 24* |

`*` = ainda AGUARDA; não cobrar enquanto o status não mudar.

## Motor de relatórios automáticos (v55)

Desde a v55 os relatórios marcados "motor" saem sozinhos: o Supabase
calcula em horário agendado (pg_cron) e grava o resultado pronto na
tabela `relatorios_gerados`; o app só lê e mostra (Diretoria › seção
📊 Relatórios; gerente › cartão 📊 Meus relatórios, só da unidade dele).
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
| `plano_executado_mes` | `plano_safra` (vigente por fazenda_app — mapa em `rel_unidades.fazenda_app` = PLANO_FAZENDA_APP), `plano_unidade`, `unidade_manejo`, `unidade_alias` (sistema app → talhaoId), `plano_adubo_mes`, `plano_calagem` (janela), `plano_fito_mes`/`plano_fito_excecao`, `plano_gantt`, `plano_parametros` × `boletins.payload`: atividades[].tipo por talhaoId (adubo = "Adubação via lanço"/"Adubação orgânica"/irr.fert Sim + fertSetores; calagem = "Calagem / gessagem"; fito = "Pulverização"/"Aplicação via drench / via solo"/"Monitoramento de pragas (MIP)" + fito[]), colheita[]. Faróis: verde registrado, branco em andamento, amarelo sem registro (após o dia `adubo_dia_limite_cadencia` / `gantt_pct_janela_amarelo` % da janela / `fito_dias_sem_monitoramento` dias), vermelho só com a janela fechada, cinza sem apelido app. Produtos só como "previsto pelo agrônomo". |

Formato de `dados`: JSON por unidade com `resumo` (contagens para o farol
da lista), tabelas por pivô/talhão/lote e `divergencias[]` com texto
pronto ("para conferir", nunca "erro"). Ver exemplos rodando
`sql/021-relatorios-teste.sql`. Unidade nova no app precisa de um `insert`
em `rel_unidades` (o farol lista quem existe por essa tabela).

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
