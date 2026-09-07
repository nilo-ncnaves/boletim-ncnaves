-- Conferência da visão vw_dias_sem_registro (opcional) — v59
-- Rodar DEPOIS do sql/040-dias-sem-registro.sql, no SQL Editor:
--   1. SQL Editor › New query.  2. Cole tudo.  3. Run.
-- Mostra as combinações unidade × operação que JÁ têm registro, com a
-- data do último boletim e os dias sem registro. As que nunca tiveram
-- registro ficam de fora desta lista (na visão elas existem, com
-- dias_sem_registro nulo e nunca_registrado = true).
-- Com o banco de 07/09/2026 (10 boletins) espera-se ver poucas linhas —
-- ex.: f27 (Capoeira Grande) × GRAOS-PLANTIO_SEMEADURA, data 31/08.
select v.atividade, u.nome as unidade, v.unidade_id, v.operacao_id, v.operacao_nome,
       v.data_ultimo_registro, v.dias_sem_registro, v.nunca_registrado
from public.vw_dias_sem_registro v
join public.rel_unidades u on u.id = v.unidade_id
where not v.nunca_registrado
order by v.atividade, u.nome, v.dias_sem_registro desc, v.operacao_id;
