-- Conferência das visões de intervalo entre operações (opcional) — v62
-- Rodar DEPOIS do sql/043-intervalo-operacoes.sql, no SQL Editor:
--   1. SQL Editor › New query.  2. Cole tudo.  3. Run.
-- Duas tabelinhas:
--   (a) o ritmo de cada unidade × operação que já tem 2 registros ou mais
--       (mediana, mínimo, máximo dos dias entre registros, último registro),
--       ao lado dos dias sem registro de hoje (vw_dias_sem_registro) — as
--       duas métricas juntas: "a cada N dias" × "há M dias sem registro";
--   (b) os últimos 30 pares consecutivos (data, data anterior, intervalo),
--       para ver a conta feita. O primeiro registro de cada combinação
--       aparece com intervalo vazio (não é zero).
-- Com o banco de 07/09/2026 (10 boletins) espera-se ver poucas linhas —
-- ex.: f27 (Capoeira Grande) com 1 registro só, sem ritmo.

-- (a) ritmo × dias sem registro
select r.atividade, u.nome as unidade, r.unidade_id, r.operacao_id, c.nome as operacao,
       r.qtd_registros, r.qtd_intervalos,
       r.intervalo_mediano_dias, r.intervalo_minimo_dias, r.intervalo_maximo_dias,
       r.data_ultimo_registro, d.dias_sem_registro
from public.vw_ritmo_operacoes r
join public.rel_unidades u on u.id = r.unidade_id
join public.operacao_catalogo c on c.id = r.operacao_id
left join public.vw_dias_sem_registro d on d.unidade_id = r.unidade_id and d.operacao_id = r.operacao_id
where r.qtd_intervalos > 0
order by r.atividade, u.nome, r.intervalo_mediano_dias, r.operacao_id;

-- (b) últimos 30 pares consecutivos
select i.atividade, u.nome as unidade, i.unidade_id, i.operacao_id,
       i.data_registro, i.data_registro_anterior, i.intervalo_dias, i.lancamentos_no_dia
from public.vw_intervalo_operacoes i
join public.rel_unidades u on u.id = i.unidade_id
order by i.data_registro desc, u.nome, i.operacao_id
limit 30;
