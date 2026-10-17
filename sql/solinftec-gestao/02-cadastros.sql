-- ====================================================================
-- 02-cadastros.sql — Projeto "Solinftec na gestão" (Grupo LGS)
-- ====================================================================
-- COMO USAR: Supabase › SQL Editor › New query › colar o arquivo
-- INTEIRO › Run. Leva poucos segundos. Rodar de novo é seguro.
-- PRÉ-REQUISITO: 01-solinftec-hora.sql já rodado.
--
-- O QUE ESTE ARQUIVO FAZ (só cadastros e parâmetros; nada da API):
--   1. solinftec_nucleo ..... fazenda da Solinftec → núcleo
--                             (Caxico + Monte Carmelo = um núcleo;
--                             Vereda + Café Quinto + Romaria = um núcleo;
--                             Estreito e "-1" fora dos relatórios).
--   2. maquinas ............. as 33 máquinas com Solinftec: código,
--                             nome, modelo, grupo e núcleo habitual
--                             (montado com 7 semanas de dados da
--                             Solinftec e confirmado pelo Nilo).
--   3. solinftec_operacoes .. ganha a coluna TIPO (produtiva / parada /
--                             deslocamento) e os nomes já descobertos.
--                             Código sem nome continua "Operação NNN",
--                             exatamente como o app mostra hoje.
--   4. solinftec_operadores . código do operador (nomes depois).
--                             Trancada: nome de pessoa não sai pela
--                             chave pública.
--   5. faixas_operacao ...... vazia — o agrônomo preenche depois.
--   6. taxa_manutencao ...... R$ por litro, jul–set/2026.
--   7. parametros ........... jornada e limites dos alertas.
--
-- COMO COMPLETAR DEPOIS (exemplos, uma linha cada):
--   Nome de uma operação ou parada:
--     update solinftec_operacoes set descricao = 'Deslocamento', tipo = 'deslocamento' where cd = '250';
--   Nome de um operador:
--     update solinftec_operadores set nome = 'Fulano de Tal' where cd = '1000046';
--   Código de uma das duas máquinas sem código no nome:
--     update maquinas set codigo = '665' where codigo = 'SEM-COD-1';
--   Faixa de velocidade e RPM de uma operação (agrônomo):
--     insert into faixas_operacao values ('135', 5, 7, 1700, 2100);
--   Taxa do próximo trimestre:
--     insert into taxa_manutencao values ('Tratores café', '2026-T4', '2026-10-01', '2026-12-31', 4.10);
-- ====================================================================

-- 1. Núcleos -----------------------------------------------------------
-- A chave é o nome da fazenda EXATAMENTE como vem da Solinftec
-- (dsFazenda). Fazenda nova que não esteja aqui vira um núcleo com o
-- próprio nome (regra "cada outra fazenda = um núcleo").
create table if not exists public.solinftec_nucleo (
  fazenda_sol text primary key,
  nucleo      text not null,
  fora        boolean not null default false  -- true = fora dos relatórios
);
comment on table public.solinftec_nucleo is
  'Fazenda da Solinftec (dsFazenda, nome exato) → núcleo dos relatórios de gestão. fora = true: não entra nos relatórios.';

insert into public.solinftec_nucleo (fazenda_sol, nucleo, fora) values
  ('Faz. Monte Carmelo',       'Monte Carmelo',     false),
  ('Caxico',                   'Monte Carmelo',     false),
  ('Vereda',                   'Vereda',            false),
  ('Cafe Quinto',              'Vereda',            false),
  ('Romaria',                  'Vereda',            false),
  ('Rio Preto Santana - Cafe', 'Rio Preto Santana', false),
  ('Agua Limpa',               'Água Limpa',        false),
  ('Estreito',                 'Estreito',          true),
  ('-1',                       'Sem fazenda',       true)
on conflict (fazenda_sol) do update
  set nucleo = excluded.nucleo, fora = excluded.fora;

-- 2. Máquinas ----------------------------------------------------------
create table if not exists public.maquinas (
  codigo          text primary key,  -- o número do "(COD nnn)"
  nome            text not null,
  nome_solinftec  text,              -- nome exato na Solinftec (casa as máquinas sem COD no nome)
  modelo          text,
  grupo           text,              -- grupo de máquina do AgroGestão (o mesmo da taxa_manutencao)
  tem_solinftec   boolean not null default true,
  nucleo_habitual text               -- vazio = ainda sem uso suficiente para dizer
);
comment on table public.maquinas is
  'Cadastro das máquinas para os relatórios de gestão. codigo = número do (COD nnn) do nome na Solinftec. grupo = grupo do AgroGestão, igual ao da taxa_manutencao.';

insert into public.maquinas (codigo, nome, nome_solinftec, modelo, grupo, tem_solinftec, nucleo_habitual) values
  ('6',   'TRATOR MF 265 (COD 6)',   'TRATOR MF 265 (COD 6)',   'MF 265', 'Tratores café', true, 'Água Limpa'),
  ('7',   'TRATOR MF 265 (COD 7)',   'TRATOR MF 265 (COD 7)',   'MF 265', 'Tratores café', true, 'Vereda'),
  ('8',   'TRATOR MF 265 (COD 8)',   'TRATOR MF 265 (COD 8)',   'MF 265', 'Tratores café', true, 'Vereda'),
  ('11',  'TRATOR MF 275 (COD 11)',  'TRATOR MF 275 (COD 11)',  'MF 275', 'Tratores café', true, 'Monte Carmelo'),
  ('13',  'TRATOR MF 275 (COD 13)',  'TRATOR MF 275 (COD 13)',  'MF 275', 'Tratores café', true, null),
  ('15',  'TRATOR MF 275 (COD 15)',  'TRATOR MF 275 (COD 15)',  'MF 275', 'Tratores café', true, 'Vereda'),
  ('16',  'TRATOR MF 275 (COD 16)',  'TRATOR MF 275 (COD 16)',  'MF 275', 'Tratores café', true, 'Vereda'),
  ('17',  'TRATOR MF 275 (COD 17)',  'TRATOR MF 275 (COD 17)',  'MF 275', 'Tratores café', true, 'Vereda'),
  ('18',  'TRATOR MF 275 (COD 18)',  'TRATOR MF 275 (COD 18)',  'MF 275', 'Tratores café', true, null),
  ('19',  'TRATOR MF 275 (COD 19)',  'TRATOR MF 275 (COD 19)',  'MF 275', 'Tratores café', true, 'Vereda'),
  ('24',  'TRATOR LS N01 (COD 24)',  'TRATOR LS N01 (COD 24)',  'LS',     'Tratores café', true, 'Vereda'),
  ('25',  'TRATOR LS N02 (COD 25)',  'TRATOR LS N02 (COD 25)',  'LS',     'Tratores café', true, 'Vereda'),
  ('26',  'TRATOR LS N03 (COD 26)',  'TRATOR LS N03 (COD 26)',  'LS',     'Tratores café', true, 'Água Limpa'),
  ('30',  'TRATOR NEW HOLLAND TT3880 (COD 30)', 'TRATOR NEW HOLLAND TT3880 (COD 30)', 'NH TT3880', 'Tratores café', true, 'Vereda'),
  ('31',  'TRATOR NEW HOLLAND TT3880 (COD 31)', 'TRATOR NEW HOLLAND TT3880 (COD 31)', 'NH TT3880', 'Tratores café', true, 'Vereda'),
  ('82',  'COLHEITADEIRA JACTO K-3 N02 (COD82)',     'COLHEITADEIRA JACTO K-3 N02 (COD82)',     'Jacto K-3',    'Colhedora café', true, null),
  ('84',  'COLHEITADEIRA JACTO K-3500 N04 (COD84)',  'COLHEITADEIRA JACTO K-3500 N04 (COD84)',  'Jacto K-3500', 'Colhedora café', true, null),
  ('476', 'TRATOR NEW HOLLAND TT75 N05 (COD 476)',   'TRATOR NEW HOLLAND TT75 N05 (COD 476)',   'NH TT75',      'Tratores café', true, 'Vereda'),
  ('508', 'TRATOR NEW HOLLAND TT75 N02 - RODRIGO (COD 508)', 'TRATOR NEW HOLLAND TT75 N02 - RODRIGO (COD 508)', 'NH TT75', 'Tratores café', true, 'Rio Preto Santana'),
  ('513', 'TRATOR NEW HOLLAND T-4 85 F N08 (COD 513)', 'TRATOR NEW HOLLAND T-4 85 F N08 (COD 513)', 'NH T4 85F', 'Tratores café', true, 'Vereda'),
  ('521', 'TRATOR NEW HOLLAND TT75 N06 (COD 521)',   'TRATOR NEW HOLLAND TT75 N06 (COD 521)',   'NH TT75',      'Tratores café', true, 'Vereda'),
  ('523', 'TRATOR NEW HOLLAND TT75 N07 (COD 523)',   'TRATOR NEW HOLLAND TT75 N07 (COD 523)',   'NH TT75',      'Tratores café', true, 'Vereda'),
  ('546', 'COLHEITADEIRA JACTO K-3 N05 (COD 546)',   'COLHEITADEIRA JACTO K-3 N05 (COD 546)',   'Jacto K-3',    'Colhedora café', true, null),
  ('698', 'TRATOR MF 3407 (COD 698)',     'TRATOR MF 3407 (COD 698)',     'MF 3407',    'Tratores café', true, 'Rio Preto Santana'),
  ('722', 'TRATOR JD 5080 EN (COD 722)',  'TRATOR JD 5080 EN (COD 722)',  'JD 5080 EN', 'Tratores café', true, 'Monte Carmelo'),
  ('723', 'TRATOR JD 5080 EN (COD 723)',  'TRATOR JD 5080 EN (COD 723)',  'JD 5080 EN', 'Tratores café', true, 'Monte Carmelo'),
  ('724', 'TRATOR JD 5080 EN (COD 724)',  'TRATOR JD 5080 EN (COD 724)',  'JD 5080 EN', 'Tratores café', true, 'Vereda'),
  ('725', 'TRATOR JD 5080 EN (COD 725)',  'TRATOR JD 5080 EN (COD 725)',  'JD 5080 EN', 'Tratores café', true, 'Vereda'),
  ('745', 'TRATOR JD 5080 EN (COD 745)',  'TRATOR JD 5080 EN (COD 745)',  'JD 5080 EN', 'Tratores café', true, null),
  ('746', 'TRATOR JD 5080 EN (COD 746)',  'TRATOR JD 5080 EN (COD 746)',  'JD 5080 EN', 'Tratores café', true, 'Rio Preto Santana'),
  ('770', 'TRATOR JD 5080 EN (COD 770)',  'TRATOR JD 5080 EN (COD 770)',  'JD 5080 EN', 'Tratores café', true, 'Rio Preto Santana'),
  -- Sem código no nome da Solinftec: casadas pelo nome exato. Quando o
  -- código for conhecido, trocar com o update do cabeçalho.
  ('SEM-COD-1', 'New Holland TT-75F', 'New Holland TT-75F', 'NH TT75', 'Tratores café', true, 'Água Limpa'),
  ('SEM-COD-2', 'TRATOR NEW HOLLAND', 'TRATOR NEW HOLLAND', null,      'Tratores café', true, 'Vereda')
on conflict (codigo) do nothing;  -- não desfaz correções feitas depois

-- 3. Operações: tipo + nomes -------------------------------------------
-- A tabela já existe (sql/003 do Boletim). Só ganha a coluna tipo.
alter table public.solinftec_operacoes add column if not exists tipo text;
alter table public.solinftec_operacoes drop constraint if exists solinftec_operacoes_tipo_chk;
alter table public.solinftec_operacoes add constraint solinftec_operacoes_tipo_chk
  check (tipo in ('produtiva', 'parada', 'deslocamento'));

-- Nomes: descobertos cruzando o relatório do site (jul–set/2026) com a
-- API — em todos os dias em que a máquina fez um processo só, o código
-- apareceu sempre nesse processo. Paradas: códigos que aparecem dentro
-- de vários processos diferentes; nome ainda desconhecido.
insert into public.solinftec_operacoes (cd, descricao, tipo) values
  ('128',   'Colheita varrição',            'produtiva'),
  ('116',   'Rastelação',                   'produtiva'),
  ('119',   'Trincha',                      'produtiva'),
  ('123',   'Transportes de café colhido',  'produtiva'),
  ('133',   'Transporte geral',             'produtiva'),
  ('135',   'Herbicida',                    'produtiva'),
  ('11509', 'Pulverização setembro',        'produtiva'),
  ('118',   'Roçadeira',                    'produtiva'),
  ('10001', 'Cloreto via lanço',            'produtiva'),
  ('140',   'Batedor de sulco',             'produtiva'),
  ('114',   'Poda café',                    'produtiva'),
  ('11508', 'Pulverização agosto',          'produtiva'),
  ('145',   'Pulverização com arco',        'produtiva'),
  ('105',   'Calcário',                     'produtiva'),
  ('110',   'Gesso',                        'produtiva'),
  ('109',   'Esterco',                      'produtiva'),
  ('107',   'Esqueletadeira',               'produtiva'),
  ('103',   'Soprador',                     'produtiva'),
  ('11504', 'Pulverização abril',           'produtiva'),
  ('139',   'Grade chegar terra',           'produtiva'),
  -- produtivas pela família do código (1xx, 10xxx, 115xx), nome a confirmar
  ('101',   'Operação 101',   'produtiva'),
  ('120',   'Operação 120',   'produtiva'),
  ('126',   'Operação 126',   'produtiva'),
  ('141',   'Operação 141',   'produtiva'),
  ('10002', 'Operação 10002', 'produtiva'),
  ('10003', 'Operação 10003', 'produtiva'),
  ('11507', 'Operação 11507', 'produtiva'),
  ('11510', 'Operação 11510', 'produtiva'),
  -- paradas (nome a confirmar)
  ('28',  'Operação 28',  'parada'), ('167', 'Operação 167', 'parada'),
  ('250', 'Operação 250', 'parada'), ('251', 'Operação 251', 'parada'),
  ('300', 'Operação 300', 'parada'), ('301', 'Operação 301', 'parada'),
  ('303', 'Operação 303', 'parada'), ('304', 'Operação 304', 'parada'),
  ('308', 'Operação 308', 'parada'), ('309', 'Operação 309', 'parada'),
  ('316', 'Operação 316', 'parada'), ('317', 'Operação 317', 'parada'),
  ('318', 'Operação 318', 'parada'), ('321', 'Operação 321', 'parada'),
  ('322', 'Operação 322', 'parada'), ('323', 'Operação 323', 'parada'),
  ('326', 'Operação 326', 'parada'), ('327', 'Operação 327', 'parada'),
  ('328', 'Operação 328', 'parada'), ('329', 'Operação 329', 'parada'),
  ('330', 'Operação 330', 'parada'), ('331', 'Operação 331', 'parada'),
  ('334', 'Operação 334', 'parada'), ('336', 'Operação 336', 'parada'),
  ('337', 'Operação 337', 'parada'), ('339', 'Operação 339', 'parada'),
  ('340', 'Operação 340', 'parada'), ('342', 'Operação 342', 'parada'),
  ('343', 'Operação 343', 'parada'), ('344', 'Operação 344', 'parada'),
  ('345', 'Operação 345', 'parada'), ('346', 'Operação 346', 'parada'),
  ('347', 'Operação 347', 'parada'), ('348', 'Operação 348', 'parada')
on conflict (cd) do update
  set tipo = coalesce(public.solinftec_operacoes.tipo, excluded.tipo),
      -- só põe nome onde ainda não há nome de verdade
      descricao = case when public.solinftec_operacoes.descricao like 'Operação %'
                       then excluded.descricao
                       else public.solinftec_operacoes.descricao end;

-- O cartão do app passa a mostrar os nomes também nos dias já gravados
-- (a mesma consulta que o sql/003 já previa; só troca o rótulo).
update public.solinftec_diario s set operacao = op.descricao
  from public.solinftec_operacoes op
  where op.cd = s.cd_operacao and s.operacao is distinct from op.descricao;

-- 4. Operadores ----------------------------------------------------------
create table if not exists public.solinftec_operadores (
  cd   text primary key,
  nome text
);
comment on table public.solinftec_operadores is
  'Código do operador na Solinftec → nome. Trancada (nome de pessoa): só o SQL Editor lê.';
alter table public.solinftec_operadores enable row level security;
revoke all on table public.solinftec_operadores from anon, authenticated;

insert into public.solinftec_operadores (cd)
  select distinct cd_operador from public.solinftec_hora where cd_operador is not null
on conflict (cd) do nothing;

-- 5. Faixas de velocidade e RPM (o agrônomo preenche) --------------------
create table if not exists public.faixas_operacao (
  cd_operacao text primary key,  -- código da operação (solinftec_operacoes.cd)
  vel_min numeric, vel_max numeric,  -- km/h
  rpm_min numeric, rpm_max numeric
);
comment on table public.faixas_operacao is
  'Faixa correta de velocidade (km/h) e RPM por operação. Preenchida pelo agrônomo; vazio = sem conferência de faixa.';

-- 6. Taxa de manutenção -------------------------------------------------
create table if not exists public.taxa_manutencao (
  grupo        text not null,   -- igual a maquinas.grupo
  trimestre    text not null,   -- ex.: 2026-T3
  inicio       date not null,
  fim          date not null,
  rs_por_litro numeric not null,
  primary key (grupo, trimestre)
);
comment on table public.taxa_manutencao is
  'Custo de manutenção estimado em R$ por litro de diesel, por grupo de máquina e trimestre.';

insert into public.taxa_manutencao values
  ('Tratores café',    '2026-T3', '2026-07-01', '2026-09-30',  3.91),
  ('Tratores cereais', '2026-T3', '2026-07-01', '2026-09-30',  3.24),
  ('Colhedora café',   '2026-T3', '2026-07-01', '2026-09-30',  8.86),
  ('Colhedoras',       '2026-T3', '2026-07-01', '2026-09-30',  5.72),
  ('Caminhões',        '2026-T3', '2026-07-01', '2026-09-30',  6.47),
  ('Carregadeira',     '2026-T3', '2026-07-01', '2026-09-30',  8.36),
  ('Pulverizadores',   '2026-T3', '2026-07-01', '2026-09-30', 22.59)
on conflict (grupo, trimestre) do update set rs_por_litro = excluded.rs_por_litro;

-- 7. Parâmetros -------------------------------------------------------------
create table if not exists public.parametros (
  chave     text primary key,
  valor     numeric not null,
  descricao text not null
);
comment on table public.parametros is
  'Jornada e limites dos alertas dos relatórios de gestão. Mudar um limite = update de uma linha.';

insert into public.parametros (chave, valor, descricao) values
  ('jornada_h',               9,   'Horas de jornada por dia útil (7h–17h, 1 h de almoço)'),
  ('dias_uteis_semana',       6,   'Dias úteis: segunda a sábado'),
  ('motor_min_dia_util_h',    4.5, 'Alerta: motor ligado abaixo disto num dia útil'),
  ('ociosidade_max_pct',      20,  'Alerta: ociosidade (ocioso / motor ligado) acima disto'),
  ('ha_h_queda_pct',          30,  'Alerta: ha/h abaixo da média das 4 semanas anteriores da mesma operação por mais que isto'),
  ('l_h_acima_mediana_pct',   25,  'Alerta: litros por hora acima da mediana do modelo por mais que isto'),
  ('utilizacao_min_pct',      30,  'Alerta: utilização mensal da máquina abaixo disto'),
  ('rs_ha_multiplo_mediana',  2,   'Alerta: R$/ha do talhão acima de N vezes a mediana do núcleo'),
  ('robo_dias_sem_dado',      2,   'Alerta: robô sem dado há mais que N dias'),
  ('noite_inicio_h',          19,  'Fora de horário: motor ligado a partir desta hora'),
  ('noite_fim_h',             5,   'Fora de horário: motor ligado antes desta hora')
on conflict (chave) do nothing;  -- não desfaz ajustes feitos depois

-- Leitura: cadastros sem dado pessoal podem ser lidos pela chave
-- pública (as tarefas agendadas precisam deles). Ninguém escreve por ela.
do $$
declare t text;
begin
  foreach t in array array['solinftec_nucleo','maquinas','faixas_operacao','taxa_manutencao','parametros'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "%s leitura" on public.%I', t, t);
    execute format('create policy "%s leitura" on public.%I for select using (true)', t, t);
  end loop;
end $$;

-- Conferência rápida (aparece no fim):
select 'maquinas' as cadastro, count(*) as linhas from public.maquinas
union all select 'operacoes com tipo', count(*) from public.solinftec_operacoes where tipo is not null
union all select 'operadores (códigos)', count(*) from public.solinftec_operadores
union all select 'taxas', count(*) from public.taxa_manutencao
union all select 'parametros', count(*) from public.parametros;
