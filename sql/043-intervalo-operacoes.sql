-- Intervalo entre operações (v62) — visões vw_intervalo_operacoes e vw_ritmo_operacoes
-- Rodar no SQL Editor do Supabase (projeto syvehtgrbqteyuqhoban).
--
-- PASSO A PASSO (pelo iPhone):
--   1. Abra o Supabase (app.supabase.com) e entre no projeto do Boletim.
--   2. No menu da esquerda, toque em "SQL Editor".
--   3. Toque em "New query".
--   4. Selecione TODO o texto deste arquivo (do começo ao fim), copie e
--      cole na caixa da consulta.
--   5. Toque em "Run".
--   6. No fim aparece uma tabelinha de conferência (uma linha por
--      atividade: quantas combinações unidade × operação têm registro,
--      quantas já têm 2 registros ou mais — e portanto um ritmo — e a
--      faixa das medianas). Se aparecer erro em vermelho, mande a
--      mensagem inteira para o Claude.
--   Pode rodar de novo quantas vezes quiser: só recria as duas visões.
--
-- ANTES: sql/020 (motor) e sql/040 (dias sem registro) precisam já ter
-- rodado (rodaram em 05/09 e 07/09/2026). Este bloco usa deles:
-- vw_dsr_registros (ocorrências extraídas dos boletins), operacao_alias,
-- operacao_catalogo e rel_unidades. Se faltar, o bloco para com um aviso
-- claro e não faz nada. Não cria tabela nem grava nada: só duas visões.
--
-- O QUE É: o RITMO de cada operação em cada unidade operacional — de
-- quanto em quanto tempo ela vem sendo registrada no boletim. É a outra
-- metade da métrica "dias sem registro" (sql/040):
--   dias_sem_registro  → do ÚLTIMO registro até HOJE (lacuna corrente,
--                        aberta: muda todo dia mesmo sem boletim novo);
--   intervalo_dias     → entre DOIS registros consecutivos do passado
--                        (ritmo histórico, fechado: só muda com boletim novo).
-- Uma unidade pode ter ritmo de 20 dias e estar há 3 dias sem registro
-- (normal) ou há 60 (vale olhar). As duas juntas dizem mais que cada uma.
--
-- IDENTIDADE (regra 6 do projeto): unidade = rel_unidades.id (f33, f26…),
-- operação = operacao_catalogo.id (código imutável), casadas pelo apelido
-- exato de operacao_alias — nunca LIKE, nunca pedaço de nome. Mesma base
-- da vw_dias_sem_registro: nada de extração é repetido aqui.
--
-- O QUE CONTA COMO UM REGISTRO: um DIA em que a operação aparece no
-- boletim da unidade. O boletim é um por unidade por dia (índice único
-- fazenda_id + data); a mesma operação lançada em vários talhões, lotes
-- ou pastos do mesmo boletim é o MESMO registro do dia (a coluna
-- lancamentos_no_dia guarda quantos foram). Por isso intervalo_dias = 0
-- não acontece com o app de hoje; se um dia dois boletins da mesma
-- unidade caírem no mesmo dia (ids antigos que apontam para a mesma
-- unidade, por exemplo), continua sendo um registro do dia — nada é
-- descartado como erro. Contar cada lançamento em vez de cada dia faria a
-- mediana de uma unidade com 4 pivôs (4 lançamentos de fungicida no mesmo
-- dia) cair para 0 e o ritmo mentiria.
--
-- PRIMEIRO REGISTRO ≠ ZERO: no primeiro registro de cada combinação
-- data_registro_anterior e intervalo_dias ficam NULL (não há anterior).
-- Com menos de 2 registros não há intervalo: qtd_intervalos = 0 e as
-- estatísticas ficam NULL — nenhuma estatística é inventada sobre amostra
-- que não existe.
--
-- MEDIANA, NÃO MÉDIA: um único intervalo longo (paralisação por chuva,
-- troca de equipe) puxa a média para cima e ela passa a mentir sobre o
-- ritmo típico; a mediana não se mexe. Mínimo e máximo vão junto para
-- quem quiser ver a faixa.
--
-- AS VISÕES NÃO JULGAM: não há coluna de status, farol, "atrasado",
-- "fora do padrão" nem "ritmo esperado" (não existe padrão cadastrado e
-- inventá-lo seria prescrição). Elas devolvem o número; janela e cor são
-- da vw_farol_registro (sql/042) e de decisões futuras. Não filtram por
-- perfil de acesso: isso é da camada de leitura (o app só baixa as
-- unidades do escopo do código). Café entra só como dado, pela mesma
-- regra das três atividades; nenhuma tela de café lê estas visões.
--
-- Índice: a operação vive dentro do jsonb do boletim, então não há índice
-- possível em (unidade, operação, data); o índice (fazenda_id, data) já
-- existe (sql/040 confere). Volume atual (centenas de boletins) não pede
-- mais nada.
--
-- Segurança: mesmo padrão do sql/040 — visões com security_invoker (rodam
-- com as permissões de quem lê; não afrouxam nada), leitura anon herdada
-- das tabelas de origem, nenhuma escrita.

-- 0. Pré-requisitos (sql/020 e sql/040)
do $$
begin
  if to_regclass('public.vw_dsr_registros') is null
     or to_regclass('public.operacao_alias') is null
     or to_regclass('public.operacao_catalogo') is null then
    raise exception 'Rode antes o sql/040-dias-sem-registro.sql (faltam vw_dsr_registros / operacao_alias / operacao_catalogo).';
  end if;
  if to_regclass('public.rel_unidades') is null then
    raise exception 'Rode antes o sql/020-relatorios-motor.sql (falta rel_unidades).';
  end if;
end $$;

-- 1. Intervalos: uma linha por registro (dia com a operação no boletim da
--    unidade), com a data do registro anterior da mesma combinação.
create or replace view public.vw_intervalo_operacoes
with (security_invoker = true) as
with dias as (
  -- um registro = um dia em que a operação aparece no boletim da unidade
  select r.unidade_id, al.operacao_id, r.data as data_registro,
         count(*)::integer as lancamentos_no_dia
  from public.vw_dsr_registros r
  join public.operacao_alias al on al.origem = r.origem and al.termo = r.termo
  where coalesce(r.termo, '') <> ''
  group by r.unidade_id, al.operacao_id, r.data
),
pares as (
  select d.unidade_id, d.operacao_id, c.atividade, d.data_registro, d.lancamentos_no_dia,
         lag(d.data_registro) over (partition by d.unidade_id, d.operacao_id
                                    order by d.data_registro) as data_registro_anterior
  from dias d
  join public.operacao_catalogo c on c.id = d.operacao_id and c.ativo
  join public.rel_unidades u on u.id = d.unidade_id and u.ativo and c.atividade = any (u.perfil)
)
select
  unidade_id,
  operacao_id,
  atividade,
  data_registro,
  data_registro_anterior,                                        -- NULL no 1º registro
  (data_registro - data_registro_anterior)::integer as intervalo_dias,  -- NULL no 1º registro
  lancamentos_no_dia
from pares;
comment on view public.vw_intervalo_operacoes is
  'Intervalo entre registros consecutivos da mesma operação na mesma unidade (Boletim NCNaves v62). Um registro = um dia com a operação no boletim da unidade (lancamentos_no_dia = quantos lançamentos naquele dia). intervalo_dias = data_registro − data_registro_anterior; NULL no primeiro registro. Sem status/alerta: a visão devolve o número.';

-- 2. Ritmo: uma linha por unidade × operação com pelo menos um registro.
--    Mediana (percentile_cont 0,5), mínimo e máximo dos intervalos.
create or replace view public.vw_ritmo_operacoes
with (security_invoker = true) as
select
  unidade_id,
  operacao_id,
  atividade,
  count(*)::integer                     as qtd_registros,
  count(intervalo_dias)::integer        as qtd_intervalos,        -- = qtd_registros − 1
  round((percentile_cont(0.5) within group (order by intervalo_dias))::numeric, 1)
                                        as intervalo_mediano_dias, -- NULL com menos de 2 registros
  min(intervalo_dias)                   as intervalo_minimo_dias,
  max(intervalo_dias)                   as intervalo_maximo_dias,
  max(data_registro)                    as data_ultimo_registro
from public.vw_intervalo_operacoes
group by unidade_id, operacao_id, atividade;
comment on view public.vw_ritmo_operacoes is
  'Ritmo de cada operação por unidade (Boletim NCNaves v62): quantidade de registros e de intervalos, mediana (não média), mínimo e máximo dos dias entre registros consecutivos, data do último registro. Combinação com 1 registro: qtd_intervalos = 0 e estatísticas NULL. Sem status, alerta ou ritmo esperado.';

-- 3. Conferência (aparece na tela ao terminar)
select atividade,
  count(*)                                          as combinacoes_com_registro,
  count(*) filter (where qtd_intervalos = 0)        as so_um_registro,
  count(*) filter (where qtd_intervalos > 0)        as com_ritmo,
  min(intervalo_mediano_dias)                       as menor_mediana_dias,
  max(intervalo_mediano_dias)                       as maior_mediana_dias,
  max(data_ultimo_registro)                         as ultimo_registro
from public.vw_ritmo_operacoes
group by atividade
order by atividade;
