-- ====================================================================
-- 01-solinftec-hora.sql — Projeto "Solinftec na gestão" (Grupo LGS)
-- ====================================================================
-- COMO USAR (2 minutos):
--   1. Abra o Supabase › SQL Editor › New query.
--   2. Cole este arquivo INTEIRO e toque em "Run".
--   3. A parte final busca os últimos 10 dias na Solinftec. Pode levar
--      alguns minutos. No fim aparece uma tabelinha com uma linha por
--      dia: quantos registros chegaram e quantas horas de motor.
--   4. Se o SQL Editor reclamar de tempo esgotado ("timeout"), não tem
--      problema: tudo o que vem antes da busca já ficou gravado. Rode
--      então só as linhas da seção "BUSCA DIA A DIA" (no fim), uma por
--      vez.
--
-- PRÉ-REQUISITO: o sql/003-solinftec.sql do Boletim já rodado (é ele
-- que guarda a senha em solinftec_segredos e agenda o robô). Este
-- arquivo NÃO pede nem contém senha.
--
-- O QUE ESTE ARQUIVO FAZ:
--   1. Cria a tabela solinftec_hora: uma linha por registro da API
--      (hora × máquina × operador × operação × talhão), com todos os
--      campos que a Solinftec manda e a linha original guardada inteira.
--      Trancada: a chave pública do app NÃO lê esta tabela.
--   2. Troca o robô (função solinftec_pull) por uma versão que continua
--      gravando o resumo solinftec_diario EXATAMENTE como antes (o app
--      usa) e passa a gravar também solinftec_hora. Os agendamentos de
--      hoje (madrugada e de hora em hora) não mudam.
--   3. Busca os últimos 10 dias (a API só guarda 10).
--
-- Rodar este arquivo de novo é seguro: nada se duplica.
-- ====================================================================

-- 1. Tabela ----------------------------------------------------------
create table if not exists public.solinftec_hora (
  id                     bigserial primary key,
  data                   date not null,      -- dia buscado na API
  cd_fazenda             text,
  ds_fazenda             text,
  cd_grp_equipamento     text,
  ds_grp_equipamento     text,
  cd_equipamento         text,
  ds_equipamento         text,
  cd_operador            text,
  cd_implemento          text,
  dt_movimentacao        text,               -- como veio da API
  dt_hr_movimento        text,               -- como veio da API
  inicio                 timestamp,          -- dt_hr_movimento lido como data e hora (Brasília)
  hora                   smallint,           -- hora do dia (0 a 23)
  cd_operacao_cb         text,
  cd_operacao            text,
  cd_tp_operacao         text,
  cd_operacao_parada     text,
  cd_talhao              text,
  ds_talhao              text,
  vl_horim_min_hora      numeric,            -- horímetro no começo da hora
  vl_horim_max_hora      numeric,            -- horímetro no fim da hora
  vl_tempo_segundos      numeric,            -- tempo do registro, em segundos
  vl_tempo_motor_ligado  numeric,            -- segundos
  vl_tempo_motor_ocioso  numeric,            -- segundos
  vl_area_operacional    numeric,            -- ha
  vl_consumo_medio       numeric,            -- como veio (unidade a confirmar)
  vl_velocidade_media    numeric,            -- km/h
  vl_rpm_medio           numeric,
  bruto                  jsonb not null,     -- a linha original da API, inteira
  atualizado_em          timestamptz not null default now()
);
comment on table public.solinftec_hora is
  'Solinftec Detalhes da Operação V3, uma linha por registro da API (hora × equipamento × operador × operação × talhão). Gravada pelo robô solinftec_pull (apaga o dia e regrava). Dado bruto: fechado para a chave pública; a leitura é pelas visões agregadas.';

create index if not exists solinftec_hora_data_idx on public.solinftec_hora (data);
create index if not exists solinftec_hora_equip_idx on public.solinftec_hora (cd_equipamento, data);

-- Trancada: RLS ligado e nenhuma policy. A chave pública (anon) e
-- usuários logados não leem nem escrevem; só o robô e o SQL Editor.
alter table public.solinftec_hora enable row level security;
revoke all on table public.solinftec_hora from anon, authenticated;
revoke all on sequence public.solinftec_hora_id_seq from anon, authenticated;

-- 2. Funções de apoio (leitura tolerante dos campos) ------------------
-- Pega um campo aceitando as duas grafias (dsFazenda / dsfazenda) e
-- nomes alternativos. Texto vazio conta como ausente.
create or replace function public.solinftec_campo(l jsonb, variadic nomes text[])
returns text
language sql
immutable
as $$
  select v from (
    select nullif(coalesce(l ->> lower(n), l ->> n), '') as v, ord
    from unnest(nomes) with ordinality as u(n, ord)
  ) x
  where v is not null
  order by ord
  limit 1
$$;

-- Número tolerante: aceita "12.5", "12,5" e notação científica;
-- qualquer outra coisa vira vazio (nunca derruba o robô).
create or replace function public.solinftec_num(t text)
returns numeric
language sql
immutable
as $$
  select case
    when t ~ '^\s*-?\d+(\.\d+)?([eE][-+]?\d+)?\s*$' then trim(t)::numeric
    when t ~ '^\s*-?\d+,\d+\s*$'                     then replace(trim(t), ',', '.')::numeric
    else null
  end
$$;

-- Data e hora tolerante, sempre devolvida no horário de Brasília.
-- Aceita "2026-10-06 07:00:00", "2026-10-06T07:00:00Z",
-- "06/10/2026 07:00:00" e milissegundos desde 1970.
create or replace function public.solinftec_ts(t text)
returns timestamp
language sql
stable
as $$
  select case
    when t is null then null
    when t ~ '^\d{12,13}$'
      then to_timestamp(t::numeric / 1000) at time zone 'America/Sao_Paulo'
    when t ~ '^\d{4}-\d{2}-\d{2}.*(Z|[+-]\d{2}:?\d{2})$'
      then t::timestamptz at time zone 'America/Sao_Paulo'
    when t ~ '^\d{4}-\d{2}-\d{2}'
      then t::timestamp
    when t ~ '^\d{2}/\d{2}/\d{4} \d{1,2}:\d{2}'
      then to_timestamp(t, 'DD/MM/YYYY HH24:MI:SS')::timestamp
    when t ~ '^\d{2}/\d{2}/\d{4}$'
      then to_date(t, 'DD/MM/YYYY')::timestamp
    else null
  end
$$;

-- 3. Robô: nova versão de solinftec_pull ------------------------------
-- Mesmo nome e mesmo jeito de chamar: os agendamentos de hoje
-- continuam valendo. A parte do solinftec_diario é a MESMA do
-- sql/003-solinftec.sql, sem nenhuma mudança.
create or replace function public.solinftec_pull(dia date)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  tok   text;
  resp  extensions.http_response;
  corpo jsonb;
  pag   int := 1;
  tot   int := 1;
begin
  perform extensions.http_set_curlopt('CURLOPT_TIMEOUT', '180');
  tok := public.solinftec_token();

  drop table if exists _solinftec_tmp;
  create temp table _solinftec_tmp (l jsonb) on commit drop;

  loop
    select * into resp from extensions.http((
      'POST',
      'https://scdi.saas-solinftec.com/pull',
      array[extensions.http_header('X-Auth-Token', tok),
            extensions.http_header('Content-Type', 'application/json')],
      'application/json',
      jsonb_build_object(
        'identifier', '23',  -- código NC Naves (PDF de configuração da Solinftec)
        'filters', jsonb_build_object(
          'page', pag, 'size', 10000, 'data', to_char(dia, 'DD/MM/YYYY'))
      )::text
    )::extensions.http_request);
    if resp.status <> 200 then
      raise exception 'Solinftec /pull (página %) devolveu status %: %', pag, resp.status, left(resp.content, 300);
    end if;
    corpo := resp.content::jsonb;
    insert into _solinftec_tmp (l)
      select jsonb_array_elements(coalesce(corpo -> 'data', '[]'::jsonb));
    tot := coalesce((corpo ->> 'total_pages')::int, 1);
    exit when pag >= tot;
    pag := pag + 1;
    -- cada resposta traz um token novo (o anterior vence em ~1 min)
    tok := coalesce(corpo ->> 'token', public.solinftec_token());
  end loop;

  -- 3a. Resumo diário (o app lê) — idêntico ao sql/003 ---------------
  delete from public.solinftec_diario where data = dia;

  -- A API real manda os campos em minúsculas e alguns com nome
  -- diferente do manual em PDF (vltempo, dtbase, fgtpoperacao...);
  -- o coalesce aceita as duas grafias.
  with linhas as (
    select
      coalesce(l ->> 'dsfazenda', l ->> 'dsFazenda', '')                     as fazenda_sol,
      coalesce(nullif(l ->> 'dsequipamento', ''), nullif(l ->> 'dsEquipamento', ''),
               l ->> 'cdequipamento', l ->> 'cdEquipamento', '')             as equipamento,
      coalesce(l ->> 'cdoperacao', l ->> 'cdOperacao', '')                   as cd_operacao,
      coalesce(l ->> 'dstalhao', l ->> 'dsTalhao', '')                       as talhao,
      coalesce((l ->> 'vltempo')::numeric, (l ->> 'vltemposegundos')::numeric,
               (l ->> 'vlTempoSegundos')::numeric, 0)                        as seg,
      coalesce((l ->> 'vltempomotorligado')::numeric,
               (l ->> 'vlTempoMotorLigado')::numeric, 0)                     as motor,
      coalesce((l ->> 'vltempomotorocioso')::numeric,
               (l ->> 'vlTempoMotorOcioso')::numeric, 0)                     as ocioso,
      coalesce((l ->> 'vlareaoperacional')::numeric,
               (l ->> 'vlAreaOperacional')::numeric, 0)                      as area,
      coalesce((l ->> 'vlconsumomedio')::numeric,
               (l ->> 'vlConsumoMedio')::numeric, 0)                         as litros
    from _solinftec_tmp
  ),
  ag as (
    select fazenda_sol, equipamento, cd_operacao, talhao,
      sum(seg) seg, sum(motor) motor, sum(ocioso) ocioso,
      sum(area) area, sum(litros) litros
    from linhas
    group by 1, 2, 3, 4
  )
  insert into public.solinftec_diario
    (data, fazenda_sol, fazenda_id, equipamento, cd_operacao, operacao,
     talhao, horas, motor_h, ocioso_h, area_ha, consumo_l)
  select dia, ag.fazenda_sol, dp.fazenda_id, ag.equipamento, ag.cd_operacao,
    coalesce(op.descricao,
      case when ag.cd_operacao = '' then '' else 'Operação ' || ag.cd_operacao end),
    ag.talhao,
    round(ag.seg    / 3600.0, 2),
    round(ag.motor  / 3600.0, 2),
    round(ag.ocioso / 3600.0, 2),
    round(ag.area, 2),
    round(ag.litros, 1)
  from ag
  left join lateral (
    select d.fazenda_id from public.solinftec_depara d
    where lower(ag.fazenda_sol) like '%' || d.padrao || '%'
    order by length(d.padrao) desc
    limit 1
  ) dp on true
  left join public.solinftec_operacoes op on op.cd = ag.cd_operacao;

  -- 3b. Registro a registro (base dos relatórios de gestão) ----------
  delete from public.solinftec_hora where data = dia;

  with c as (
    select l,
      public.solinftec_campo(l, 'dtHrMovimento')                       as dthr,
      public.solinftec_ts(public.solinftec_campo(l, 'dtHrMovimento'))  as ts
    from _solinftec_tmp
  )
  insert into public.solinftec_hora
    (data, cd_fazenda, ds_fazenda, cd_grp_equipamento, ds_grp_equipamento,
     cd_equipamento, ds_equipamento, cd_operador, cd_implemento,
     dt_movimentacao, dt_hr_movimento, inicio, hora,
     cd_operacao_cb, cd_operacao, cd_tp_operacao, cd_operacao_parada,
     cd_talhao, ds_talhao,
     vl_horim_min_hora, vl_horim_max_hora, vl_tempo_segundos,
     vl_tempo_motor_ligado, vl_tempo_motor_ocioso, vl_area_operacional,
     vl_consumo_medio, vl_velocidade_media, vl_rpm_medio, bruto)
  select
    dia,
    public.solinftec_campo(l, 'cdFazenda'),
    public.solinftec_campo(l, 'dsFazenda'),
    public.solinftec_campo(l, 'cdGrpEquipamento'),
    public.solinftec_campo(l, 'dsGrpEquipamento'),
    public.solinftec_campo(l, 'cdEquipamento'),
    public.solinftec_campo(l, 'dsEquipamento'),
    public.solinftec_campo(l, 'cdOperador'),
    public.solinftec_campo(l, 'cdImplemento'),
    public.solinftec_campo(l, 'dtMovimentacao', 'dtBase'),
    dthr,
    -- hora só com o número da hora ("7") vira dia + 7 h
    coalesce(ts, case when dthr ~ '^\d{1,2}$' and dthr::int between 0 and 23
                      then dia + make_interval(hours => dthr::int) end),
    case when dthr ~ '^\d{1,2}$' and dthr::int between 0 and 23 then dthr::int
         else extract(hour from ts)::int end,
    public.solinftec_campo(l, 'cdOperacaoCb'),
    public.solinftec_campo(l, 'cdOperacao'),
    public.solinftec_campo(l, 'cdTpOperacao', 'fgTpOperacao'),
    public.solinftec_campo(l, 'cdOperacaoParada'),
    public.solinftec_campo(l, 'cdTalhao'),
    public.solinftec_campo(l, 'dsTalhao'),
    public.solinftec_num(public.solinftec_campo(l, 'vlHorimMinHora')),
    public.solinftec_num(public.solinftec_campo(l, 'vlHorimMaxHora')),
    public.solinftec_num(public.solinftec_campo(l, 'vlTempo', 'vlTempoSegundos')),
    public.solinftec_num(public.solinftec_campo(l, 'vlTempoMotorLigado')),
    public.solinftec_num(public.solinftec_campo(l, 'vlTempoMotorOcioso')),
    public.solinftec_num(public.solinftec_campo(l, 'vlAreaOperacional')),
    public.solinftec_num(public.solinftec_campo(l, 'vlConsumoMedio')),
    public.solinftec_num(public.solinftec_campo(l, 'vlVelocidadeMedia')),
    public.solinftec_num(public.solinftec_campo(l, 'vlRpmMedio', 'VlRpmMedio')),
    l
  from c;
end $$;

-- Continua trancada: só o robô (pg_cron) e o SQL Editor chamam.
revoke all on function public.solinftec_pull(date) from public, anon, authenticated;

-- ====================================================================
-- 4. BUSCA DOS ÚLTIMOS 10 DIAS
-- ====================================================================
-- Um dia de cada vez; se um dia der erro, os outros seguem e o erro
-- aparece na tabelinha final. Também regrava o solinftec_diario desses
-- dias, com os mesmos valores de antes.
create temp table if not exists _solinftec_carga (dia date, resultado text);
truncate _solinftec_carga;

do $$
declare
  d date;
begin
  for d in
    select ((now() at time zone 'America/Sao_Paulo')::date - g)::date
    from generate_series(10, 1, -1) g
  loop
    begin
      perform public.solinftec_pull(d);
      insert into _solinftec_carga values (d, 'ok');
    exception when others then
      insert into _solinftec_carga values (d, 'ERRO: ' || left(sqlerrm, 200));
    end;
  end loop;
end $$;

-- Resultado: uma linha por dia.
select c.dia,
       c.resultado,
       count(h.id)                                         as registros,
       round(sum(h.vl_tempo_motor_ligado) / 3600.0, 1)     as horas_motor,
       count(distinct h.cd_equipamento)                    as maquinas,
       count(h.id) filter (where h.inicio is null)          as sem_hora_lida
from _solinftec_carga c
left join public.solinftec_hora h on h.data = c.dia
group by c.dia, c.resultado
order by c.dia;

-- ====================================================================
-- BUSCA DIA A DIA (só se a busca acima estourar o tempo)
-- Rode UMA linha por vez, trocando os dias se precisar:
-- ====================================================================
--   select public.solinftec_pull(date '2026-10-06');
--   select public.solinftec_pull(date '2026-10-07');
--   select public.solinftec_pull(date '2026-10-08');
--   select public.solinftec_pull(date '2026-10-09');
--
-- CONFERÊNCIAS (opcionais):
--   Uma amostra do que chegou:
--     select * from public.solinftec_hora order by id desc limit 20;
--   Campos que a API manda e que talvez não estejam nas colunas:
--     select distinct jsonb_object_keys(bruto) from public.solinftec_hora;
--   O resumo do app continua igual (mesmas horas nas duas tabelas):
--     select data, sum(motor_h) from public.solinftec_diario group by 1 order by 1;
--     select data, round(sum(vl_tempo_motor_ligado)/3600.0, 2) from public.solinftec_hora group by 1 order by 1;
