# Plano de safra 2026/27 — auditoria da carga inicial (v1)

Inconsistências JÁ CONHECIDAS dos 7 PPTX do agrônomo (Salvino), levantadas
na extração de 03/09/2026. Nenhuma foi corrigida na carga: os números do
seed (`docs/plano/2026-27/plano_2627_seed.json`) são exatamente os dos
decks. Quem decide o que fazer com cada item é o agrônomo, e a correção
entra sempre como **nova versão** do plano (nunca editando a vigente).

## AUDITORIA_V1 (lista literal do apêndice)

- Água Limpa: soma das áreas = 92 ha; slide totaliza 81 (erro de soma).
- Vereda: resumo − calendários: SA −24.500, KCl +18.000, U +2.000, Ni −2.000, Zn −175, B −25. Setor 08 SA 21000+21000 provável erro.
- Monte Carmelo: resumo − calendários: U +4.000, Ni +17.000, SA +7.500, KCl +4.000, Ph −8.000, Mn +250, B +550, Zn +325.
- Lagamar: resumo − calendários: U +8.000, KCl +4.000.
- Romaria: resumo − calendários: KCl +6.000, U −500.
- Mata Preta: resumo − calendários: U −500.
- Romaria safra zerada: 2+34+23 = 59; slide diz 49.
- Gantt NR difere do NC em 4 linhas (limpeza, fertirrigação, lanço, herbicida).
- Vereda S07 sem KCl; S09 sem uréia e sem mar–jul; Pivô 2 calagem cobre 109 ha de 120.
- Nomes múltiplos: V56-6MN (3 nomes), V56-5BX (3 nomes), AGL-T1 (Catuaí × Catucaí), MTP-3PT sem calagem e sem área, MTP-P26 sem calendário.
- Fito: "Auto 400" (ago) vs "Alto 400" (mar) — grafia mantida como no deck; confirmar se é o mesmo produto.
- Uréia mai–jul não tem canal (fertirrigação/lanço) em nenhum Gantt; coluna via ainda não definida.

## Como estes itens aparecem no app

- A auditoria da tela **Escritório › Unidades e Plano › Rodar auditoria**
  recalcula, a partir das tabelas do Supabase, os itens que dão para
  medir (soma por insumo × resumo do deck, kg/ha fora da mediana,
  unidade sem área, unidade com calendário sem calagem e vice-versa,
  status "a confirmar", insumo-mês sem via). O resultado fica em
  `plano_safra.auditoria_json`.
- Os dois itens que travam a publicação (✱) são: unidade do plano
  inativa ou de outra fazenda, e unidade com calendário sem área. Na
  carga v1 o MTP-3PT (3º plantio, torres) tem calendário e não tem
  área: o plano de **Mata Preta** só pode ser publicado depois que o
  agrônomo informar a área (ou registrar a exceção em `obs`).

## Achados da própria carga (03/09/2026, v52)

Coisas que apareceram ao materializar o apêndice e que não estavam na
lista original. Não alteram dados; ficam registradas para decisão.

- **3 nomes de fazenda do plano não batem exatamente com o cadastro do
  app** (regra 5 do pedido: não mapear "por parecido"):
  `Vereda Café` × app `Vereda — Café` (f22c); `Lagamar Café – Rodrigo` ×
  app `Lagamar Café (Rodrigo)` (f20); `Mata Preta - Café` × app
  `Mata Preta — Café` (f13c). Enquanto o Nilo não confirmar, o seed grava
  o nome do plano em `fazenda_app`, o app não carrega o plano dessas
  três fazendas e nenhum alias `app` é criado para elas
  (`docs/plano/2026-27/depara_fazendas.json`, campo `confirmado`).
- Nomes do plano se repetem entre fazendas ("Setor 01" existe em Vereda,
  Rio Preto, Lagamar e Mata Preta). Por isso a unicidade de
  `unidade_alias` é por (sistema, fazenda_app, alias), não por
  (sistema, alias) como no rascunho do pedido.
- Rio Preto: o app tem "Setor 1 (café grupo)" … "Setor 7 (café grupo)";
  o plano tem Setor 01–06 do 1º plantio E st01–06 do 2º plantio. Mesmo
  número em duas unidades da mesma fazenda → nenhum alias `app` criado.
- Vereda Café 5º e 6º: o app tem só "Café 5º" (80 ha) e "Café 6º"
  (50 ha); o plano tem 3 unidades no 5º e 2 no 6º → sem alias `app`
  (várias unidades para um talhão só).
- Monte Carmelo: "M. Carmelo st01–st08", "Caxico represa", "Sr. Ernani
  alto/baixo" não têm talhão equivalente no app (o app tem "Café Talhão
  1/2", "Caxico — Área Nova" e um único "Ernane — Área geral").
- Vereda Café: "Pivô 2" e "Pivô 6" do plano de café estão cadastrados
  no app na unidade **Vereda — Grãos** (f22g), não na de café.
- Romaria 01 b (ROM-S01B) é filha de ROM-S01 e não tem talhão próprio
  no app (Setor 1 = 21 ha = 14 + 7).
- `resumo_fazenda` do deck diverge da soma dos calendários em 5
  fazendas (já listado acima); a conferência oficial do seed usa a soma
  dos calendários, não o resumo.
