# Solinftec na gestão (out/2026)

Projeto à parte do app: deixa no Supabase o que os relatórios de gestão de
máquinas precisam, a partir da API da Solinftec. Os relatórios em si são
tarefas agendadas do Claude que só LEEM as visões daqui (chave pública).
O app Boletim não lê nada disto — exceto que o arquivo 02 pôs nome nas
operações de `solinftec_operacoes`, que o cartão Solinftec já usava.

## Ordem de colar no SQL Editor (colados em 16/10/2026)

Atenção: a versão do `03-visoes.sql` desta pasta conta as paradas só dentro
da jornada (7h–17h, seg–sáb). Se `vw_maquinas_semana.paradas_h` ainda mostra
mais horas de parada que de motor, cole o 03 de novo.

| Ordem | Arquivo | O que faz |
|---|---|---|
| 1 | `01-solinftec-hora.sql` | Robô completo: nova `solinftec_pull` grava `solinftec_diario` igual a antes (o app usa) e também `solinftec_hora` (uma linha por registro da API, trancada) |
| 2 | `02-cadastros.sql` | `maquinas`, `solinftec_nucleo`, tipo e nome em `solinftec_operacoes`, `solinftec_operadores` (trancada), `faixas_operacao`, `taxa_manutencao`, `parametros` |
| 3 | `03-visoes.sql` | As 9 visões agregadas que a chave pública lê (a base `vw_sol_base` é privada) |

Os três podem ser rodados de novo sem estragar nada.

## Visões

`vw_status_robo`, `vw_maquinas_semana`, `vw_operacao_semana`,
`vw_fora_horario_semana`, `vw_aplicacao_fora_faixa_semana`,
`vw_horimetro_atual`, `vw_frota_mes`, `vw_operador_mes`, `vw_talhao_mes`.
Definições (dia, semana, efetivo, paradas na jornada) no cabeçalho do 03.

## Conferência

06 a 09/10/2026: 482,9 h de motor ligado nas visões × 483 h na exportação
do site (diferença de arredondamento).

## Pendências

- **Diesel:** a API manda consumo zero em todos os registros desde 31/08 —
  sem L/h, sem alerta de consumo e sem R$ de manutenção por talhão até a
  Solinftec ativar o consumo ou entrar outra fonte (abastecimentos do
  AgroGestão).
- **Nomes das paradas** (aparecem "Operação 250") e **dos operadores**
  (aparecem por código). Antes de pôr nome de operador numa visão pública,
  decisão do Nilo: a chave pública está no código do app.
- **Duas máquinas sem código** no nome da Solinftec: SEM-COD-1
  ("New Holland TT-75F") e SEM-COD-2 ("TRATOR NEW HOLLAND").
- **Faixas de velocidade/RPM:** o agrônomo preenche `faixas_operacao`.
- **Taxa de manutenção do 4º trimestre** (só jul–set/2026 cadastrada).
- O parcial do dia corrente (busca de hora em hora) vem vazio da API; o dia
  fechado chega na busca da madrugada.

Exemplos de cada ajuste (uma linha cada) no cabeçalho do `02-cadastros.sql`.
