# Carteira de relatórios do Grupo LGS

Lista oficial dos relatórios que a Controladoria produz (ou vai
produzir) a partir do Boletim NCNaves e das integrações. Serve para
três coisas: saber o que existe, saber o que falta e conferir toda
semana o que estava previsto e não rodou (item da vistoria semanal em
`docs/vistoria-semanal.md`).

## Como ler a tabela

- **Fonte**: de onde saem os números. "app" = tabelas do Boletim
  (boletins, pos_colheitas, remessas, telemetria, boletim_pecuaria,
  codigos_acesso; desde a v59 a visão vw_dias_sem_registro e, na v60,
  operacao_janela + vw_farol_registro — seções próprias abaixo); "iCrop" = icrop_manejo, icrop_fazendas,
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

## Calendário resumido (para a vistoria de segunda)

| Quando | Relatórios previstos |
|---|---|
| Todo dia (motor, 05:00) | 1 (farol 7 e 30), 5 diário, 7 diário, 15 diário — sozinhos, no app em 📊 Relatórios |
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
registro") ficam prontos para telas futuras. Nenhuma tela mostra o número
ainda e a função não roda na sincronização. Telas de café não leem a
visão (o café entra nela só como dado, pela mesma regra das outras
atividades).

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
