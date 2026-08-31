# ESTADO.md — o que o app tem hoje

Fotografia atual do Boletim NCNaves. TODA tarefa que mudar
comportamento, catálogo, chave ou versão DEVE atualizar este arquivo
no mesmo pull request (regra no CLAUDE.md).

**Versão atual: v42** (rodapé da tela inicial + cache do sw.js).

## Unidades operacionais (fazenda física + atividade)
- ☕ Café: Água Limpa (f01), Rio Preto-Lagamar — Café (f03c),
  Mata Preta — Café (f13c), Monte Carmelo — Café (f14c),
  São Félix — Arrendamento (f21), Vereda — Café (f22c),
  Vereda Romaria (f23), Vereda Café 5º e 6º (f24),
  Lagamar Café Rodrigo (f20), NC Naves — Armazém Geral (f25).
- 🌾 Grãos: Rio Preto-Lagamar — Grãos (f03g), Vereda — Grãos (f22g),
  Capoeira Grande (f27), Floramill (f33), Porto Buriti (f35).
- 🐂 Pecuária: Mata Preta — Pecuária (f13p), Monte Carmelo —
  Pecuária (f14p), Água Santa (f26), Chapada (f28), Chapadão (f29),
  Confins (f30), Cra Cra (f31), Ferragem (f32), Gameleira (f34).

Unidades desmembradas compartilham a fazenda-mãe (fazendaMae) no
painel; talhões tipo ESTRUTURA aparecem em todas as unidades irmãs.

## Perfis de uso
- Gerente: preenche o boletim da sua unidade.
- Diretoria: painel com farol, indicadores e cartões por atividade.
- Escritório/Admin: cadastros, importação e relatórios.
- Pós-colheita: boletim próprio de terreiro/secador/tulha (café).

## Seções do boletim por atividade
- ☕ Café: clima, mão de obra por função, talhões/atividades,
  irrigação (gotejo), colheita, pós-colheita, fito, ocorrências.
- 🌾 Grãos (redesenho v42): clima; mão de obra; **Operações do dia**
  (registro por talhão + operação escolhida em seletor agrupado por
  fase, com campos em cascata específicos de cada operação — fonte:
  docs/catalogos-por-atividade.md); **💧 Irrigação por pivô**
  (status/lâmina/percentímetro/quimigação/problemas por pivô, lista
  vinda da iCrop + cadastro local por unidade, comparação informado ×
  medido); pragas/doenças e ocorrências. Ciclo de cultura abre pelo
  plantio lançado e encerra quando a colheita atinge a área do
  talhão. Talhões ARRENDADO (milho semente → sementeira) aparecem só
  como etiqueta, sem operações/irrigação/colheita.
- 🐂 Pecuária: lotes por pasto, cocho/sal/água, eventos com campos em
  cascata (sanitário: produto + dose/cabeça; pesagem: peso médio;
  venda/compra: valor e contraparte).

## Robôs e integrações
- Supabase (sync): boletins, pos_colheitas, remessas, telemetria —
  gravação/leitura pelo app com a chave publishable.
- Robô iCrop (pg_cron + pg_net no Supabase): grava icrop_manejo toda
  madrugada; o app LÊ (icropDo) e mostra medição do dia, compara
  lâmina informada × medida e alerta parcela vencida (icrop_fazendas
  e icrop_parcelas).
- Solinftec: garagem pronta no código, DESLIGADA.

## Chaves ligadas/desligadas
- SOLINFTEC_AUTO = false (ligar só quando a tabela solinftec_diario
  existir no Supabase).
- Sincronização Supabase: ligada por padrão (SYNC_PADRAO com a chave
  publishable).

## PENDÊNCIAS
- Ciclos reais de grãos aguardando censo de plantio (o que está
  plantado hoje em cada pivô/talhão) para abrir os ciclos oficiais.
- solinftec_diario aguardando definição da API/exportação da
  Solinftec; quando existir, criar a tabela (sql/…) e ligar
  SOLINFTEC_AUTO.
- Token da iCrop (tabela segredos do Supabase) pendente de troca
  (rotação) — trocar direto no SQL Editor, nunca no código.
- Porto Buriti (f35): talhões reais a cadastrar (hoje só "Área geral
  (a cadastrar)"); pivôs entram pelo cadastro local da seção
  Irrigação.
