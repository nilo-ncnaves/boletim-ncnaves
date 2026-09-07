-- Estado das integrações (v63) — visão vw_status_integracoes
-- Rodar no SQL Editor do Supabase (projeto syvehtgrbqteyuqhoban).
--
-- PASSO A PASSO (pelo iPhone):
--   1. Abra o Supabase (app.supabase.com) e entre no projeto do Boletim.
--   2. No menu da esquerda, toque em "SQL Editor".
--   3. Toque em "New query".
--   4. Selecione TODO o texto deste arquivo (do começo ao fim), copie e
--      cole na caixa da consulta.
--   5. Toque em "Run".
--   6. No fim aparece uma tabelinha com DUAS linhas (icrop e solinftec)
--      e as colunas ultima_execucao_em, ultima_execucao_ok_em,
--      ultimo_dado_em, ultimo_dado_origem e horas_desde_ultimo_sucesso.
--      Horários em UTC (Brasília = 3 horas a menos). Coluna vazia (NULL)
--      é normal quando a informação ainda não existe — nunca é
--      inventada. Se aparecer erro em vermelho, mande a mensagem inteira
--      para o Claude.
--   Pode rodar de novo quantas vezes quiser: só recria os objetos.
--
-- ANTES: o robô iCrop (icrop_reqs, icrop_manejo — já no ar) e o robô
-- Solinftec (sql/003-solinftec.sql — solinftec_diario) precisam existir,
-- assim como as extensões pg_cron e pg_net (já ligadas pelos robôs). Se
-- faltar algo, o bloco para com um aviso claro e não faz nada.
--
-- O QUE É: uma linha por fonte externa (icrop, solinftec) dizendo de
-- QUANDO é o dado que o app mostra. Três horários que NÃO se misturam:
--   ultima_execucao_em     → última TENTATIVA do robô (o pg_cron disparou
--                            a função), deu certo ou não;
--   ultima_execucao_ok_em  → último SUCESSO: a API de origem respondeu OK
--                            (iCrop: resposta HTTP 200 a um pedido do robô;
--                            Solinftec: a função terminou sem erro — ela
--                            lança exceção em qualquer resposta ≠ 200);
--   ultimo_dado_em         → última GRAVAÇÃO de dado no Supabase
--                            (max de atualizado_em da tabela de dados);
--   ultimo_dado_origem     → data do dado mais recente NA ORIGEM (max da
--                            coluna data — o dia a que a medição se refere).
-- Robô que rodou e a API falhou: ultima_execucao_em avança, o resto não.
-- Robô que rodou, API OK e nenhum dado novo do lado de lá (ciclo vencido,
-- cálculo atrasado): ultima_execucao_ok_em avança, ultimo_dado_em não.
-- Colapsar esses horários é o que faz dado velho parecer novo.
--
-- DE ONDE VEM CADA UM:
--   tentativa → cron.job_run_details (diário do pg_cron: uma linha por
--               disparo, com status succeeded/failed e start_time).
--   sucesso   → Solinftec: o mesmo diário, status = 'succeeded'.
--               iCrop: o robô é assíncrono (pg_net): a função termina
--               "succeeded" ANTES de a iCrop responder, e icrop_reqs guarda
--               só req_id, criado_em, tipo e id_fazenda — sem status. O
--               status HTTP fica em net._http_response, que a pg_net apaga
--               em poucas horas. Por isso este bloco cria um diário
--               persistente (integracao_execucoes) e uma função de
--               colheita (integracao_colher_icrop) que copia para lá o
--               status de cada pedido, agendada 15 minutos depois de cada
--               rodada do robô (07:35 e 13:30 UTC = 04:35 e 10:30 em
--               Brasília — nunca no mesmo minuto dos passos do robô). Até a
--               primeira colheita, ultima_execucao_ok_em da iCrop fica NULL.
--   dado      → icrop_manejo.atualizado_em / solinftec_diario.atualizado_em
--               (carimbo de gravação) e a coluna data (dia na origem).
--
-- IDENTIDADE (regra 6 do projeto): fonte ↔ nome do job do pg_cron por
-- tabela de-para explícita (integracao_job), casando o nome EXATO —
-- nunca LIKE, nunca pedaço de nome. Job novo do robô = uma linha nova
-- nessa tabela (exemplo no fim).
--
-- FUSO: tudo sai em UTC (timestamptz). Converter para Brasília é papel
-- da tela (o app faz isso com America/Sao_Paulo explícito).
--
-- A VISÃO NÃO JULGA: não há coluna de farol, "parado" ou "atrasado".
-- horas_desde_ultimo_sucesso é só a conta (inteiro, NULL sem sucesso
-- conhecido); o limiar de "dado velho" (26 h) é decisão da tela.
--
-- SEGURANÇA: a visão roda com as permissões de quem a criou (postgres),
-- porque cron.job_run_details e net._http_response não são legíveis pela
-- chave pública do app — e ela expõe SÓ horários agregados e o nome da
-- fonte (nenhuma mensagem de erro, nenhum conteúdo de resposta). A função
-- de colheita fica revogada para anon/authenticated: só o SQL Editor e o
-- pg_cron a chamam. Nada de token ou senha aqui.

-- 0. Pré-requisitos
do $$
begin
  if to_regclass('cron.job_run_details') is null or to_regclass('cron.job') is null then
    raise exception 'Extensão pg_cron não encontrada (cron.job / cron.job_run_details). Os robôs iCrop e Solinftec dependem dela — conferir em Database › Extensions.';
  end if;
  if to_regclass('net._http_response') is null then
    raise exception 'Extensão pg_net não encontrada (net._http_response). O robô iCrop depende dela — conferir em Database › Extensions.';
  end if;
  if to_regclass('public.icrop_reqs') is null or to_regclass('public.icrop_manejo') is null then
    raise exception 'Tabelas do robô iCrop não encontradas (icrop_reqs / icrop_manejo).';
  end if;
  if to_regclass('public.solinftec_diario') is null then
    raise exception 'Rode antes o sql/003-solinftec.sql (falta solinftec_diario).';
  end if;
end $$;

-- 1. De-para fonte → nome do job no pg_cron (nome exato; sem LIKE)
create table if not exists public.integracao_job (
  jobname text primary key,
  fonte   text not null check (fonte in ('icrop', 'solinftec'))
);
comment on table public.integracao_job is
  'De-para explícito entre a fonte externa (icrop, solinftec) e o nome EXATO do job no pg_cron (Boletim NCNaves v63). Alimenta vw_status_integracoes. Job novo do robô = linha nova aqui.';
insert into public.integracao_job (jobname, fonte) values
  ('icrop_1_parcelas',         'icrop'),
  ('icrop_2_manejo',           'icrop'),
  ('icrop_3_gravar',           'icrop'),
  ('icrop_1_parcelas-reforco', 'icrop'),
  ('icrop_2_manejo-reforco',   'icrop'),
  ('icrop_3_gravar-reforco',   'icrop'),
  ('solinftec-madrugada',      'solinftec'),
  ('solinftec-dia',            'solinftec')
on conflict (jobname) do nothing;
alter table public.integracao_job enable row level security;
drop policy if exists "integracao_job leitura" on public.integracao_job;
create policy "integracao_job leitura" on public.integracao_job for select using (true);
-- sem policy de escrita: só o SQL Editor grava

-- 2. Diário persistente das respostas da API iCrop (o que icrop_reqs não guarda)
create table if not exists public.integracao_execucoes (
  fonte         text not null,
  req_id        bigint not null,           -- = icrop_reqs.req_id = net._http_response.id
  tipo          text,                      -- icrop_reqs.tipo (manejo_rot, parcelas_rot, …)
  pedido_em     timestamptz,               -- icrop_reqs.criado_em (quando o robô pediu)
  respondido_em timestamptz,               -- net._http_response.created (quando a API respondeu)
  status_code   integer,                   -- HTTP da resposta (200 = OK)
  ok            boolean not null,          -- 200, sem timeout e sem erro de transporte
  colhido_em    timestamptz not null default now(),
  primary key (fonte, req_id)
);
comment on table public.integracao_execucoes is
  'Diário persistente das respostas HTTP aos pedidos do robô iCrop (Boletim NCNaves v63). Copiado de net._http_response por integracao_colher_icrop() antes de a pg_net apagar. Só horários e status: nenhum conteúdo de resposta.';
create index if not exists integracao_execucoes_fonte_ok_idx
  on public.integracao_execucoes (fonte, ok, respondido_em);
alter table public.integracao_execucoes enable row level security;
drop policy if exists "integracao_execucoes leitura" on public.integracao_execucoes;
create policy "integracao_execucoes leitura" on public.integracao_execucoes for select using (true);
-- sem policy de escrita: só a função de colheita (security definer) grava

-- 3. Colheita: copia o status das respostas ainda vivas em net._http_response
create or replace function public.integracao_colher_icrop()
returns integer
language plpgsql
security definer
set search_path = public, net
as $$
declare
  n integer := 0;
begin
  insert into public.integracao_execucoes
    (fonte, req_id, tipo, pedido_em, respondido_em, status_code, ok)
  select 'icrop', r.req_id::bigint, r.tipo, r.criado_em, h.created, h.status_code,
         (h.status_code = 200 and coalesce(h.timed_out, false) = false and h.error_msg is null)
  from public.icrop_reqs r
  join net._http_response h on h.id = r.req_id::bigint
  where r.req_id is not null
  on conflict (fonte, req_id) do nothing;
  get diagnostics n = row_count;
  return n;   -- quantas respostas novas entraram no diário
end $$;
comment on function public.integracao_colher_icrop() is
  'Copia para integracao_execucoes o status HTTP das respostas da iCrop ainda presentes em net._http_response (Boletim NCNaves v63). Idempotente. Agendada 15 min depois de cada rodada do robô.';
revoke all on function public.integracao_colher_icrop() from public, anon, authenticated;

-- 4. Agenda da colheita (UTC): 15 min depois de icrop_3_gravar (07:20) e do
--    reforço (13:15). Minutos diferentes dos passos do robô, de propósito.
select cron.schedule('integracao-colher-icrop-madrugada', '35 7 * * *',
  $$select public.integracao_colher_icrop()$$);
select cron.schedule('integracao-colher-icrop-reforco', '30 13 * * *',
  $$select public.integracao_colher_icrop()$$);

-- 5. Colheita imediata: aproveita o que ainda está em net._http_response
select public.integracao_colher_icrop() as respostas_colhidas_agora;

-- 6. A visão: uma linha por fonte, tudo em UTC
create or replace view public.vw_status_integracoes as
with fontes as (
  select unnest(array['icrop', 'solinftec']) as fonte
),
execucoes as (
  -- diário do pg_cron: cada disparo é uma tentativa; 'succeeded' = a função terminou sem erro
  select j.fonte,
         max(d.start_time)                                                        as ultima_execucao_em,
         max(coalesce(d.end_time, d.start_time)) filter (where d.status = 'succeeded') as ultima_funcao_ok_em
  from public.integracao_job j
  join cron.job c on c.jobname = j.jobname
  join cron.job_run_details d on d.jobid = c.jobid
  group by j.fonte
),
respostas as (
  -- iCrop: sucesso = a API respondeu OK (diário persistente da colheita)
  select fonte, max(respondido_em) filter (where ok) as ultima_resposta_ok_em
  from public.integracao_execucoes
  group by fonte
),
dados as (
  select 'icrop'::text as fonte, max(atualizado_em) as ultimo_dado_em, max(data) as ultimo_dado_origem
  from public.icrop_manejo
  union all
  select 'solinftec', max(atualizado_em), max(data)
  from public.solinftec_diario
),
junto as (
  select f.fonte,
         e.ultima_execucao_em,
         case f.fonte
           when 'icrop'     then r.ultima_resposta_ok_em   -- função OK não basta: a resposta é assíncrona
           when 'solinftec' then e.ultima_funcao_ok_em     -- a função lança erro em resposta ≠ 200
         end as ultima_execucao_ok_em,
         d.ultimo_dado_em,
         d.ultimo_dado_origem
  from fontes f
  left join execucoes e on e.fonte = f.fonte
  left join respostas r on r.fonte = f.fonte
  left join dados     d on d.fonte = f.fonte
)
select
  fonte,
  ultima_execucao_em,
  ultima_execucao_ok_em,
  ultimo_dado_em,
  ultimo_dado_origem,
  floor(extract(epoch from (now() - ultima_execucao_ok_em)) / 3600)::integer as horas_desde_ultimo_sucesso
from junto
order by fonte;
comment on view public.vw_status_integracoes is
  'Estado das integrações externas (Boletim NCNaves v63): uma linha por fonte (icrop, solinftec). ultima_execucao_em = última tentativa do robô (pg_cron); ultima_execucao_ok_em = último sucesso da API (iCrop: HTTP 200 colhido em integracao_execucoes; Solinftec: função sem erro); ultimo_dado_em = última gravação (atualizado_em); ultimo_dado_origem = data do dado na origem; horas_desde_ultimo_sucesso = inteiro derivado. Tudo em UTC. NULL = informação ainda inexistente, nunca estimada.';
grant select on public.vw_status_integracoes to anon, authenticated;

-- 7. Conferência (aparece na tela ao terminar): as duas linhas da visão
select * from public.vw_status_integracoes;

-- ====================================================================
-- CONFERÊNCIAS OPCIONAIS (rodar depois, uma de cada vez, se quiser)
-- ====================================================================
-- Os jobs do de-para existem mesmo no pg_cron? (existe_no_pg_cron = true)
--   select j.fonte, j.jobname, (c.jobid is not null) as existe_no_pg_cron
--   from public.integracao_job j left join cron.job c on c.jobname = j.jobname
--   order by j.fonte, j.jobname;
--
-- Jobs do pg_cron que NÃO estão no de-para (se algum for de robô, inserir):
--   select jobname, schedule from cron.job
--   where jobname not in (select jobname from public.integracao_job) order by 1;
--   insert into public.integracao_job (jobname, fonte) values ('nome-exato-do-job', 'icrop');
--
-- Últimas respostas da iCrop colhidas (status por pedido):
--   select * from public.integracao_execucoes order by respondido_em desc limit 20;
--
-- Últimos disparos dos robôs (diário do pg_cron):
--   select c.jobname, d.status, d.start_time, d.end_time, left(d.return_message, 120)
--   from cron.job_run_details d join cron.job c on c.jobid = d.jobid
--   where c.jobname in (select jobname from public.integracao_job)
--   order by d.start_time desc limit 30;
