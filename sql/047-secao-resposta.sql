-- Resposta explícita de ausência por seção do boletim (v69)
-- Objetos: boletim_secao (catálogo), boletim_secao_resposta (a resposta),
-- vw_completude_boletim (leitura). Rodar no SQL Editor do Supabase
-- (projeto syvehtgrbqteyuqhoban).
--
-- PASSO A PASSO (pelo iPhone):
--   1. Abra o Supabase e entre no projeto do Boletim.
--   2. Toque em "SQL Editor" e em "New query".
--   3. Selecione TODO o texto deste arquivo, copie e cole na caixa.
--   4. Toque em "Run".
--   5. No fim aparece uma tabelinha de conferência (uma linha por
--      atividade: quantas seções eventuais, quantos boletins já têm
--      resposta). Pode rodar de novo quantas vezes quiser: nada duplica.
--
-- ANTES: sql/020 (motor) precisa ter rodado (rodou em 05/09/2026). Se
-- faltar, o bloco para com um aviso claro e não faz nada.
--
-- O QUE É: no boletim diário há seções que legitimamente podem não ter
-- nada num dia (pragas/doenças, ocorrências, movimentação e sanidade do
-- rebanho). Até a v68, cartão vazio e cartão pulado eram a mesma coisa.
-- Desde a v69 o gerente toca em "Nada a registrar hoje" e isso vira um
-- REGISTRO, com autor e hora — a resposta explícita de ausência.
--   • Linha em boletim_secao_resposta  = "sem ocorrência" (respondido).
--   • Seção com registro no payload    = "com registro".
--   • Nem uma coisa nem outra          = "não respondido".
-- Não existe valor "pendente": a ausência de linha É o não respondido.
-- "Sem ocorrência" e registro NUNCA coexistem: o app apaga a resposta
-- quando a seção ganha registro, e o banco confere de novo (trava abaixo).
--
-- COMO O DADO CHEGA: o app grava a resposta dentro do payload do boletim
-- (payload.secoes = { "CAFE-FITO": {resposta, por, em} }), na mesma fila
-- offline de sempre. Um gatilho em boletins (insert/update/delete)
-- reescreve as linhas de boletim_secao_resposta daquele boletim a partir
-- do payload — por isso a tabela não precisa de policy de escrita e não
-- depende de ordem de sincronização nem de delete pela REST. Boletins já
-- gravados antes deste SQL são reprocessados no passo 6.
--
-- VOCABULÁRIO (regra do projeto): "sem ocorrência" e "não respondido",
-- nunca "não fez", "pendente", "faltou". A resposta declara que não há o
-- que registrar — não afirma que a lavoura ou o rebanho estão bem.
--
-- SEGURANÇA: leitura anon por policy select; escrita só pelas funções
-- (security definer, dono da tabela) — sem policy de insert/update/delete.
-- Visão com security_invoker. Nenhum segredo aqui.
--
-- IDENTIDADE: boletim_secao.id é chave substituta imutável (CAFE-FITO,
-- GRAOS-FITO_OCOR, PEC-MOV…), espelho da constante SECOES_BOLETIM do
-- index.html e da tabela em docs/catalogos-por-atividade.md. Os dois
-- nunca divergem: mudou lá, muda aqui no mesmo pull request.

-- 0. Pré-requisito: o motor (sql/020) precisa existir
do $$
begin
  if to_regclass('public.rel_unidades') is null
     or to_regproc('public.rel_fz_atual') is null then
    raise exception 'Rode antes o sql/020-relatorios-motor.sql (faltam rel_unidades / rel_fz_atual).';
  end if;
  if to_regclass('public.boletins') is null then
    raise exception 'A tabela boletins não existe neste projeto.';
  end if;
end $$;

-- 1. Catálogo das seções do boletim, por atividade (eventual × esperada)
create table if not exists public.boletim_secao (
  id        text primary key,            -- chave substituta imutável (= SECOES_BOLETIM[].id)
  atividade text not null check (atividade in ('CAFE','GRAOS','PECUARIA')),
  nome      text not null,               -- só para exibição; nunca é chave
  tipo      text not null check (tipo in ('eventual','esperada')),
  campos    text[] not null default '{}', -- listas do payload que contam como registro (ex.: {fito}, {pecuaria.mov})
  ordem     int  not null default 0,
  ativo     boolean not null default true
);
comment on table public.boletim_secao is
  'Catálogo das seções do boletim diário por atividade (Boletim NCNaves v69). tipo eventual = pode não ter nada no dia e oferece "Nada a registrar hoje"; esperada = execução esperada, tratada pelo farol de leitura. campos = caminhos (a.b) de listas do payload que contam como registro. Espelho de SECOES_BOLETIM do index.html.';

insert into public.boletim_secao (id, atividade, nome, tipo, campos, ordem) values
  ('CAFE-CLIMA',      'CAFE',     'Clima do dia',                  'esperada', '{}',                              1),
  ('CAFE-MO',         'CAFE',     'Mão de obra',                   'esperada', '{}',                              2),
  ('CAFE-IRR',        'CAFE',     'Irrigação (gotejo)',            'esperada', '{}',                              3),
  ('CAFE-ATIV',       'CAFE',     'Atividades por talhão',         'esperada', '{}',                              4),
  ('CAFE-COLHEITA',   'CAFE',     'Colheita',                      'esperada', '{}',                              5),
  ('CAFE-FITO',       'CAFE',     'Pragas, doenças e daninhas',    'eventual', '{fito}',                          6),
  ('CAFE-OCOR',       'CAFE',     'Ocorrências gerais',            'eventual', '{ocorrencias}',                   7),
  ('CAFE-OBS',        'CAFE',     'Observações e pendências',      'esperada', '{}',                              8),
  ('GRAOS-CLIMA',     'GRAOS',    'Clima do dia',                  'esperada', '{}',                              1),
  ('GRAOS-MO',        'GRAOS',    'Mão de obra',                   'esperada', '{}',                              2),
  ('GRAOS-OPER',      'GRAOS',    'Operações do dia',              'esperada', '{}',                              3),
  ('GRAOS-IRG',       'GRAOS',    'Irrigação (pivôs)',             'esperada', '{}',                              4),
  ('GRAOS-FITO_OCOR', 'GRAOS',    'Pragas, doenças e ocorrências', 'eventual', '{fito,ocorrencias}',              5),
  ('GRAOS-OBS',       'GRAOS',    'Observações e pendências',      'esperada', '{}',                              6),
  ('PEC-CLIMA',       'PECUARIA', 'Clima do dia',                  'esperada', '{}',                              1),
  ('PEC-MO',          'PECUARIA', 'Mão de obra',                   'esperada', '{}',                              2),
  ('PEC-MOV',         'PECUARIA', 'Movimentação do rebanho',       'eventual', '{pecuaria.mov}',                  3),
  ('PEC-SAN',         'PECUARIA', 'Sanidade',                      'eventual', '{pecuaria.san,pecuaria.massa}',   4),
  ('PEC-REP',         'PECUARIA', 'Reprodução',                    'esperada', '{}',                              5),
  ('PEC-NUT',         'PECUARIA', 'Cocho e nutrição',              'esperada', '{}',                              6),
  ('PEC-CONT',        'PECUARIA', 'Contagem por lote / pasto',     'esperada', '{}',                              7),
  ('PEC-PASTO',       'PECUARIA', 'Pasto e estrutura',             'esperada', '{}',                              8),
  ('PEC-MANEJO',      'PECUARIA', 'Outros manejos',                'esperada', '{}',                              9),
  ('PEC-OBSPEC',      'PECUARIA', 'Observações de pecuária',       'esperada', '{}',                             10),
  ('PEC-OCOR',        'PECUARIA', 'Ocorrências e sanidade',        'eventual', '{ocorrencias}',                  11),
  ('PEC-OBS',         'PECUARIA', 'Observações e pendências',      'esperada', '{}',                             12)
on conflict (id) do update set
  atividade = excluded.atividade, nome = excluded.nome, tipo = excluded.tipo,
  campos = excluded.campos, ordem = excluded.ordem, ativo = true;

-- 2. Quantos registros o payload tem numa seção (soma do tamanho das listas em campos)
create or replace function public.boletim_secao_registros(p jsonb, campos text[]) returns int
language sql immutable as $$
  select coalesce(sum(case when jsonb_typeof(p #> string_to_array(c, '.')) = 'array'
                           then jsonb_array_length(p #> string_to_array(c, '.')) else 0 end), 0)::int
  from unnest(coalesce(campos, '{}'::text[])) as c $$;
comment on function public.boletim_secao_registros(jsonb, text[]) is
  'Registros de uma seção no payload do boletim: soma jsonb_array_length dos caminhos em campos (o mesmo cálculo de secaoRegistros no index.html).';

-- carimbo de hora vindo do app (ISO 8601); texto inválido vira nulo, nunca erro
create or replace function public.boletim_secao_ts(p text) returns timestamptz
language plpgsql immutable as $$
begin
  return p::timestamptz;
exception when others then
  return null;
end $$;

-- 3. A resposta explícita: uma linha = "sem ocorrência" declarado por alguém, numa hora
create table if not exists public.boletim_secao_resposta (
  id             uuid primary key default gen_random_uuid(),
  boletim_id     text not null,                        -- boletins.id
  secao_id       text not null references public.boletim_secao(id),
  atividade      text not null check (atividade in ('CAFE','GRAOS','PECUARIA')),
  resposta       text not null check (resposta in ('sem_ocorrencia')),  -- por ora só este valor; "não respondido" = ausência de linha
  respondido_por text,                                 -- nome de quem preenche (payload.secoes[].por, senão payload.responsavel)
  respondido_em  timestamptz not null,                 -- hora do toque no chip (payload.secoes[].em)
  fazenda_id     text,                                 -- cópia de boletins.fazenda_id (unidade do app)
  data           date,                                 -- cópia de boletins.data
  atualizado_em  timestamptz not null default now(),
  unique (boletim_id, secao_id)
);
comment on table public.boletim_secao_resposta is
  'Resposta explícita de ausência por seção eventual do boletim (v69): "Nada a registrar hoje" gravado com autor e hora. Ausência de linha = não respondido (não existe enum pendente). Escrita só pelo gatilho de boletins (boletim_secao_resposta_sync); leitura pela visão vw_completude_boletim.';
create index if not exists boletim_secao_resposta_boletim on public.boletim_secao_resposta (boletim_id);
create index if not exists boletim_secao_resposta_fazenda_data on public.boletim_secao_resposta (fazenda_id, data);

-- 4. Trava: "sem ocorrência" e registro não coexistem (conferida a cada insert/update)
create or replace function public.boletim_secao_resposta_trava() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_payload jsonb;
  v_fazenda text;
  v_campos  text[];
begin
  select payload, fazenda_id into v_payload, v_fazenda from public.boletins where id = new.boletim_id;
  if v_payload is null then
    raise exception 'boletim % não existe em boletins', new.boletim_id;
  end if;
  select s.campos into v_campos
  from public.boletim_secao s
  join public.rel_unidades u on u.id = public.rel_fz_atual(v_fazenda) and s.atividade = any (u.perfil)
  where s.id = new.secao_id and s.tipo = 'eventual' and s.ativo;
  if v_campos is null then
    raise exception 'seção % não é uma seção eventual ativa da atividade da unidade do boletim %', new.secao_id, new.boletim_id;
  end if;
  if public.boletim_secao_registros(v_payload, v_campos) > 0 then
    raise exception 'seção % do boletim % tem registro: "sem ocorrência" e registro não coexistem', new.secao_id, new.boletim_id;
  end if;
  new.atualizado_em := now();
  return new;
end $$;
drop trigger if exists boletim_secao_resposta_trava on public.boletim_secao_resposta;
create trigger boletim_secao_resposta_trava
  before insert or update on public.boletim_secao_resposta
  for each row execute function public.boletim_secao_resposta_trava();

-- 5. Sincronização a partir do payload do boletim (chamada pelo gatilho de boletins)
create or replace function public.boletim_secao_resposta_sync(p_boletim_id text) returns void
language plpgsql security definer set search_path = public as $$
declare
  b record;
begin
  delete from public.boletim_secao_resposta where boletim_id = p_boletim_id;
  select id, fazenda_id, data, payload into b from public.boletins where id = p_boletim_id;
  if b.id is null or coalesce((b.payload ->> 'exemplo')::boolean, false) then
    return;
  end if;
  insert into public.boletim_secao_resposta
    (boletim_id, secao_id, atividade, resposta, respondido_por, respondido_em, fazenda_id, data)
  select b.id, s.id, s.atividade, 'sem_ocorrencia',
         coalesce(nullif(e.value ->> 'por', ''), b.payload ->> 'responsavel'),
         coalesce(public.boletim_secao_ts(e.value ->> 'em'), now()),
         b.fazenda_id, b.data::date
  from jsonb_each(case when jsonb_typeof(b.payload -> 'secoes') = 'object' then b.payload -> 'secoes' else '{}'::jsonb end) e
  join public.boletim_secao s on s.id = e.key and s.tipo = 'eventual' and s.ativo
  join public.rel_unidades u on u.id = public.rel_fz_atual(b.fazenda_id) and s.atividade = any (u.perfil)
  where jsonb_typeof(e.value) = 'object'
    and e.value ->> 'resposta' = 'sem_ocorrencia'
    and public.boletim_secao_registros(b.payload, s.campos) = 0;
exception when others then
  -- nunca derrubar o envio do boletim por causa do espelho
  raise warning 'boletim_secao_resposta_sync(%): %', p_boletim_id, sqlerrm;
end $$;

create or replace function public.boletins_secao_resposta_tg() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    delete from public.boletim_secao_resposta where boletim_id = old.id;
    return old;
  end if;
  if tg_op = 'UPDATE' and old.id is distinct from new.id then
    delete from public.boletim_secao_resposta where boletim_id = old.id;
  end if;
  perform public.boletim_secao_resposta_sync(new.id);
  return new;
end $$;
drop trigger if exists boletins_secao_resposta on public.boletins;
create trigger boletins_secao_resposta
  after insert or update or delete on public.boletins
  for each row execute function public.boletins_secao_resposta_tg();

-- 6. Boletins já gravados antes deste SQL (aparelhos na v69 antes de o SQL rodar)
do $$
declare r record;
begin
  for r in select id from public.boletins where jsonb_typeof(payload -> 'secoes') = 'object' loop
    perform public.boletim_secao_resposta_sync(r.id);
  end loop;
end $$;

-- 7. Leitura: completude por boletim (seções eventuais × registro × resposta)
create or replace view public.vw_completude_boletim
with (security_invoker = true) as
with bol as (
  select b.id as boletim_id, public.rel_fz_atual(b.fazenda_id) as unidade_id, b.data::date as data, b.payload
  from public.boletins b
  where coalesce((b.payload ->> 'exemplo')::boolean, false) = false
),
par as (
  select bol.boletim_id, bol.unidade_id, bol.data, s.atividade, s.id as secao_id,
         public.boletim_secao_registros(bol.payload, s.campos) as registros,
         (r.id is not null) as respondida
  from bol
  join public.rel_unidades u on u.id = bol.unidade_id
  join public.boletim_secao s on s.tipo = 'eventual' and s.ativo and s.atividade = any (u.perfil)
  left join public.boletim_secao_resposta r on r.boletim_id = bol.boletim_id and r.secao_id = s.id
)
select boletim_id, unidade_id, atividade, data,
       count(*)::int                                                   as secoes_eventuais,
       (count(*) filter (where registros > 0))::int                    as com_registro,
       (count(*) filter (where registros = 0 and respondida))::int     as sem_ocorrencia,
       (count(*) filter (where registros = 0 and not respondida))::int as nao_respondidas,
       coalesce(array_agg(secao_id order by secao_id) filter (where registros > 0), '{}')                as ids_com_registro,
       coalesce(array_agg(secao_id order by secao_id) filter (where registros = 0 and respondida), '{}')     as ids_sem_ocorrencia,
       coalesce(array_agg(secao_id order by secao_id) filter (where registros = 0 and not respondida), '{}') as ids_nao_respondidas
from par
group by boletim_id, unidade_id, atividade, data;
comment on view public.vw_completude_boletim is
  'Por boletim (sem exemplo): seções eventuais da atividade da unidade, quantas têm registro, quantas têm "sem ocorrência" (boletim_secao_resposta) e quantas não foram respondidas — ausência de resposta, nunca "não fez". Alimenta o farol de completude.';

-- 8. Segurança (mesmo padrão do sql/020 e sql/040)
alter table public.boletim_secao enable row level security;
drop policy if exists "boletim_secao leitura" on public.boletim_secao;
create policy "boletim_secao leitura" on public.boletim_secao for select using (true);
alter table public.boletim_secao_resposta enable row level security;
drop policy if exists "boletim_secao_resposta leitura" on public.boletim_secao_resposta;
create policy "boletim_secao_resposta leitura" on public.boletim_secao_resposta for select using (true);
-- sem policy de insert/update/delete nas duas: só o SQL Editor e o gatilho (security definer) escrevem

-- 9. Conferência: uma linha por atividade
select s.atividade,
       count(*) filter (where s.tipo = 'eventual') as secoes_eventuais,
       count(*) filter (where s.tipo = 'esperada') as secoes_esperadas,
       (select count(distinct r.boletim_id) from public.boletim_secao_resposta r where r.atividade = s.atividade) as boletins_com_resposta
from public.boletim_secao s
group by s.atividade
order by s.atividade;
