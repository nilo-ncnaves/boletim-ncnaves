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
| 1 | Farol de completude | quem enviou/não enviou boletim | app | diário | painel | EXISTE |
| 2 | Devolutiva semanal por unidade | adesão, dito × medido, elogio | app + iCrop + Solinftec | sexta | Cowork | PRONTO — `docs/relatorios/02-devolutiva-semanal.md` |
| 3 | Vistoria do sistema | site × código, robôs, segurança | repo + REST | segunda | Code | EXISTE — roteiro em `docs/vistoria-semanal.md` |
| **NÍVEL 2 — CONTROLE OPERACIONAL** | | | | | | |
| 4 | Plano × executado do mês | adubação/calagem/fito previstos × feitos | plano v52 + boletim | semanal/mensal | painel + Cowork | PRONTO — `docs/relatorios/04-plano-x-executado.md` |
| 5 | Divergência gerente × iCrop | rodou/não rodou × lâmina; chuva dita × pluviômetro | app + iCrop | diário/mensal | painel + Cowork | EXISTE (diário, painel) / PRONTO (mensal) — `docs/relatorios/05-divergencia-gerente-icrop.md` |
| 6 | Aderência à recomendação de irrigação | recomendado × executado, R$ necessário × realizado | iCrop | semanal | Cowork | PRONTO — `docs/relatorios/06-aderencia-irrigacao.md` |
| 7 | Máquinas dito × Solinftec | horas/área/operação apontadas × telemetria | app + Solinftec | diário | painel + Cowork | PRONTO — `docs/relatorios/07-maquinas-x-solinftec.md` |
| 8 | Caderno de campo / registro de aplicações | talhão, produto, dose, área, condição, operador | app | semanal | Cowork (PDF) | PRONTO — `docs/relatorios/08-caderno-de-campo.md` |
| **NÍVEL 3 — CUSTO E PRODUÇÃO** | | | | | | |
| 9 | Custo de irrigação por talhão/pivô | mm × ha × R$/mm | iCrop | mensal | Cowork | PRONTO — `docs/relatorios/09-custo-irrigacao.md` |
| 10 | Mão de obra por função e unidade | pessoas, diaristas, extras, custo/ha por serviço | app | semanal/mensal | Cowork | PRONTO — `docs/relatorios/10-mao-de-obra.md` |
| 11 | Colheita e produtividade | café: medidas/sacas/rendimento; grãos: sc/ha, umidade, quebra | app | ciclo/safra | painel + Cowork | PRONTO — `docs/relatorios/11-colheita-produtividade.md` |
| 12 | Remessas e balanço de produto | saiu da fazenda × entrou no armazém | app (+ tickets) | mensal | Cowork | AGUARDA tickets de balança |
| 13 | Custo por saca / por talhão | físico (app, iCrop, Solinftec) × R$ (ERP) | todos + AgroGestão | mensal | Cowork | AGUARDA ERP (AgroGestão não integrado) |
| **NÍVEL 4 — ZOOTECNIA E AGRONOMIA** | | | | | | |
| 14 | Rebanho | cabeças por lote/categoria, natalidade, mortalidade, prenhez, GMD, lotação, embarques | app | diário/mensal | painel + Cowork | PRONTO — `docs/relatorios/14-rebanho.md` |
| 15 | Balanço hídrico por pivô | ETo/ETc, déficit, umidade × segurança, atraso, fase, graus-dia | iCrop | diário | painel / Cowork | EXISTE (diário, cartão iCrop) / PRONTO (consolidado) — `docs/relatorios/15-balanco-hidrico.md` |
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
| Todo dia | 1 (painel), 5 diário (painel), 7 diário (painel), 14 diário (painel), 15 diário (cartão iCrop) |
| Segunda | 3 (vistoria do sistema, Code) |
| Sexta | 2 (devolutiva semanal) |
| Toda semana (dia livre) | 4, 6, 7 (consolidado), 8, 10, 16, 19 (painel) |
| Todo mês (até dia 10) | 4 (mensal), 5 (mensal), 9, 10 (mensal), 12*, 13*, 14 (mensal), 18, 23 |
| Trimestral | 20*, 21 |
| Por ciclo/safra ou censo | 11, 17*, 22, 24* |

`*` = ainda AGUARDA; não cobrar enquanto o status não mudar.

## Como rodar um relatório PRONTO no Cowork

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
