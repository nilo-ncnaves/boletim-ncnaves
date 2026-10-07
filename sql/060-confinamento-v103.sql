-- ====================================================================
-- 060 — Confinamento v103: o diário por curral na visão do escritório
-- ====================================================================
-- Objetos: recria a visão vw_cf_diario_lote (só leitura) e atualiza os
-- comentários de cf_lotes, cf_diario, cf_eventos e cf_pesagens.
-- NENHUMA tabela nova, NENHUMA coluna removida, NENHUM dado tocado.
-- Rodar no SQL Editor do Supabase (projeto syvehtgrbqteyuqhoban), DEPOIS
-- do sql/059-confinamento.sql.
--
-- PASSO A PASSO (pelo iPhone):
--   1. Abra o Supabase e entre no projeto do Boletim.
--   2. Toque em "SQL Editor" e em "New query".
--   3. Selecione TODO o texto deste arquivo, copie e cole na caixa.
--   4. Toque em "Run".
--   5. No fim aparece uma tabelinha de conferência (quantos diários em
--      cada formato). Pode rodar de novo quantas vezes quiser: a visão é
--      substituída, nada duplica e nada se apaga.
--
-- O QUE MUDOU NO APP (v103). O cocho é do CURRAL, não do lote: dois lotes
-- do mesmo curral comem no mesmo cocho. Desde a v103 o diário grava, em
-- cf_diario.payload:
--   • currais[] = {curralId, cms, sobra, cond, bebedouro, ofegacao}
--                 — uma vez por curral ocupado;
--   • lotes[]   = {loteId, curralId (o curral do lote NAQUELE dia),
--                  enfEntraram, enfMotivos[], enfEstao, foraNormal[]}.
-- O diário da v102 (tudo por lote: {loteId, cms, sobra, enfermaria,
-- curral, obs}) NÃO é reescrito: esta visão lê os dois formatos.
--
-- A VISÃO continua com UMA LINHA POR LOTE E DIA, nas mesmas colunas de
-- antes (mesma ordem), e ganha colunas novas no fim:
--   curral_id        curral do lote no dia (v102: o curral do cadastro)
--   enf_entraram     casos novos na enfermaria no dia; NULO = "não
--                    informado" (diário da v102) — nunca zero inventado
--   enf_motivos      motivos dos casos novos, separados por vírgula
--   bebedouro        OK | SUJO | FALHA (do curral)
--   ofegacao_escore  0 a 4 (do curral; opcional)
--   fora_normal      "Algo fora do normal?" do lote, separado por vírgula
--   necropsias_dia   mortes do dia com necropsia feita
--   formato          'v102' ou 'v103'
-- Nas colunas antigas: cms_kg_ms, sobra_escore e curral_cond vêm do
-- curral do lote (v103) ou do próprio lote (v102); enfermaria = animais
-- que ESTÃO na enfermaria; estresse_termico fica nulo nos diários da v103
-- (o escore de ofegação, por curral, substituiu o sim/não do dia).
--
-- JEJUM (só documentação; nada muda em tabela): a pesagem de entrada grava
-- cf_lotes.payload.pesoEntradaJejum e a pesagem intermediária grava
-- cf_pesagens.payload.jejum — SIM | NAO; vazio = não informado. O app
-- desconta 4 % do peso SEM jejum quando compara pesos de condições
-- diferentes (valor provisório, a confirmar com a consultoria AXYS). A
-- visão vw_cf_lote_resumo (sql/059) continua SEM esse desconto.
--
-- VOCABULÁRIO: relata REGISTRO ("não informado", "sem CMS") — nunca "não
-- fez", "pendente", "atrasado". Nenhum indicador é gravado: queda de
-- consumo, conversão, morbidade e peso estimado são calculados no app.
-- ====================================================================

-- ---------- números digitados no celular, lidos sem quebrar a visão ----------
-- "9,8" e "9.8" viram 9.8; texto que não é número vira nulo (a visão nunca
-- falha por causa de uma linha mal digitada).
create or replace function public.cf_num(t text) returns numeric
language sql immutable as $$
  select case when btrim(coalesce(t, '')) ~ '^-?[0-9]+([.,][0-9]+)?$'
              then replace(btrim(t), ',', '.')::numeric end
$$;
comment on function public.cf_num(text) is 'v103 — número digitado no app (vírgula ou ponto); texto que não é número vira nulo.';

-- ---------- visão: uma linha por lote-dia (para cruzar com o FarmTell) ----------
drop view if exists public.vw_cf_diario_lote;
create view public.vw_cf_diario_lote with (security_invoker = true) as
select d.unidade_id,
       d.data,
       l->>'loteId'                                                    as lote_id,
       public.cf_num(coalesce(c->>'cms', l->>'cms'))                   as cms_kg_ms,
       public.cf_num(coalesce(c->>'sobra', l->>'sobra'))::integer      as sobra_escore,
       coalesce(public.cf_num(coalesce(l->>'enfEstao', l->>'enfermaria')), 0)::integer as enfermaria,
       coalesce(c->>'cond', l->>'curral')                              as curral_cond,
       d.chuva_mm,
       d.estresse_termico,
       d.responsavel,
       l->>'obs'                                                       as obs,
       (select coalesce(sum(coalesce(e.cabecas, 1)), 0) from public.cf_eventos e
         where e.lote_id = l->>'loteId' and e.tipo = 'MORTE' and e.data = d.data and not e.cancelado) as mortes_dia,
       -- v103: colunas novas (sempre no fim)
       coalesce(nullif(l->>'curralId', ''), lt.curral_id)              as curral_id,
       case when v103.sim then coalesce(public.cf_num(l->>'enfEntraram'), 0)::integer end as enf_entraram,
       (select string_agg(m, ',') from jsonb_array_elements_text(
          case when jsonb_typeof(l->'enfMotivos') = 'array' then l->'enfMotivos' else '[]'::jsonb end) m) as enf_motivos,
       nullif(c->>'bebedouro', '')                                     as bebedouro,
       public.cf_num(c->>'ofegacao')::integer                          as ofegacao_escore,
       (select string_agg(f, ',') from jsonb_array_elements_text(
          case when jsonb_typeof(l->'foraNormal') = 'array' then l->'foraNormal' else '[]'::jsonb end) f) as fora_normal,
       (select count(*) from public.cf_eventos e
         where e.lote_id = l->>'loteId' and e.tipo = 'MORTE' and e.data = d.data and not e.cancelado
           and e.payload->>'necropsia' = 'FEITA')                      as necropsias_dia,
       case when v103.sim then 'v103' else 'v102' end                  as formato
  from public.cf_diario d
  cross join lateral (select jsonb_typeof(d.payload->'currais') = 'array' as sim) v103
  cross join lateral jsonb_array_elements(
         case when jsonb_typeof(d.payload->'lotes') = 'array' then d.payload->'lotes' else '[]'::jsonb end) l
  left join lateral (
         select x from jsonb_array_elements(case when v103.sim then d.payload->'currais' else '[]'::jsonb end) x
          where x->>'curralId' = l->>'curralId'
          limit 1) cc(c) on true
  left join public.cf_lotes lt on lt.id = l->>'loteId';
comment on view public.vw_cf_diario_lote is
  'v103 — o diário aberto em uma linha por lote e dia, nos dois formatos (v102: tudo por lote; v103: CMS, sobra, condição, bebedouro e ofegação no curral do lote naquele dia). enf_entraram nulo = não informado (v102). mortes_dia e necropsias_dia vêm de cf_eventos.';

-- ---------- comentários (documentação no próprio banco) ----------
comment on table public.cf_diario is
  'v102/v103 — diário do confinamento: um registro por unidade e dia. v103: payload.currais[] = {curralId, cms, sobra (0–4, leitura da manhã), cond (SECO|POEIRA|UMIDO|LAMA), bebedouro (OK|SUJO|FALHA), ofegacao (0–4)} e payload.lotes[] = {loteId, curralId, enfEntraram, enfMotivos[], enfEstao, foraNormal[]}. v102: payload.lotes[] = {loteId, cms, sobra, enfermaria, curral, obs} — continua legível, nunca reescrito. O número de mortes vem de cf_eventos.';
comment on table public.cf_lotes is
  'v102 — um lote de confinamento por entrada. payload.projecao = versão vigente da ficha de entrada (gmdAlvo, diasPrevistos, pesoSaidaKg, cmsPrevisto, rendimentoPct, custoArroba, precoTeto, gmdEquilibrio); payload.projecoes[] = versões anteriores, nunca editadas. v103: payload.pesoEntradaJejum = SIM | NAO (vazio = não informado).';
comment on table public.cf_eventos is
  'v102 — eventos do lote que não são pesagem, sanidade nem saída. cancelado = desfeito pelo gerente (fica para a trilha). v103: morte com payload.necropsia = FEITA | NAO_FEITA (opcional).';
comment on table public.cf_pesagens is
  'v102 — pesagem intermediária do lote (prevista a cada 30 dias, registrada quando ocorre). A de entrada mora em cf_lotes; a de saída, em cf_saidas. v103: payload.jejum = SIM | NAO (vazio = não informado).';

-- ---------- conferência ----------
select formato, count(distinct (unidade_id, data)) as diarios, count(*) as linhas_lote_dia
  from public.vw_cf_diario_lote group by formato
union all
select 'total', count(distinct (unidade_id, data)), count(*) from public.vw_cf_diario_lote;
