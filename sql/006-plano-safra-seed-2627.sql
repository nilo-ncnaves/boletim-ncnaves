-- Carga inicial do plano de safra 2026/27 (v52) — GERADO por scripts/gerar_seed_plano.py
-- Rodar no SQL Editor do Supabase DEPOIS do sql/005-plano-safra.sql.
-- Fonte única: docs/plano/2026-27/plano_2627_seed.json (7 PPTX do agrônomo, 03/09/2026).
-- Pode ser rodado de novo: os ids são fixos e tudo é "on conflict do nothing".
-- No fim há uma conferência: se alguma soma não bater, TUDO é desfeito.
--
-- Os planos entram como versão 1 em RASCUNHO. Publicar como vigente é na
-- tela Escritório › Unidades e Plano (rodar auditoria → aprovado por → publicar).
--
-- Números do plano são a proposta técnica do agrônomo (Salvino): referência
-- para comparação, nunca receituário.

begin;

-- 0. Nome do plano → nome exato do app em cargas anteriores (não faz nada num banco vazio)
update public.unidade_manejo set fazenda_app = 'Vereda — Café' where fazenda_app = 'Vereda Café';
update public.unidade_alias set fazenda_app = 'Vereda — Café' where fazenda_app = 'Vereda Café';
update public.plano_safra set fazenda_app = 'Vereda — Café' where fazenda_app = 'Vereda Café';
update public.plano_fito_excecao set fazenda_app = 'Vereda — Café' where fazenda_app = 'Vereda Café';
update public.unidade_manejo set fazenda_app = 'Lagamar Café (Rodrigo)' where fazenda_app = 'Lagamar Café – Rodrigo';
update public.unidade_alias set fazenda_app = 'Lagamar Café (Rodrigo)' where fazenda_app = 'Lagamar Café – Rodrigo';
update public.plano_safra set fazenda_app = 'Lagamar Café (Rodrigo)' where fazenda_app = 'Lagamar Café – Rodrigo';
update public.plano_fito_excecao set fazenda_app = 'Lagamar Café (Rodrigo)' where fazenda_app = 'Lagamar Café – Rodrigo';
update public.unidade_manejo set fazenda_app = 'Mata Preta — Café' where fazenda_app = 'Mata Preta - Café';
update public.unidade_alias set fazenda_app = 'Mata Preta — Café' where fazenda_app = 'Mata Preta - Café';
update public.plano_safra set fazenda_app = 'Mata Preta — Café' where fazenda_app = 'Mata Preta - Café';
update public.plano_fito_excecao set fazenda_app = 'Mata Preta — Café' where fazenda_app = 'Mata Preta - Café';

-- 1. unidade_manejo (69 unidades; pais antes dos filhos) ----------------
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('cea5a300-adcb-57e0-be8f-7a8ff70047b7', 'VEC-S01', 'Vereda — Café', 'NC Naves', 'Setor 01', 'Setor 01', null, 16, 'estimativa', 'gotejo', 'poda', 16, 'Zn set 150 vs 75 nos outros meses (conferir)') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('0d74c8e4-798c-534e-9bd0-838710c38867', 'VEC-S02', 'Vereda — Café', 'NC Naves', 'Setor 02', 'Setor 02', null, 23, 'estimativa', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('077292a8-e8ca-5518-b830-58c7c9478509', 'VEC-S03', 'Vereda — Café', 'NC Naves', 'Setor 03', 'Setor 03', null, 20, 'estimativa', 'gotejo', 'producao', 0, 'calcário implica 21 ha') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('51b4ff94-68e2-5bf1-bcf9-3ac595cb7355', 'VEC-S04', 'Vereda — Café', 'NC Naves', 'Setor 04', 'Setor 04', null, 18, 'estimativa', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('922e16bf-e805-5091-bbf8-5d104e3db726', 'VEC-S05', 'Vereda — Café', 'NC Naves', 'Setor 05', 'Setor 05', null, 18, 'estimativa', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('8794ebc3-0652-5321-af14-77cbca328844', 'VEC-S06', 'Vereda — Café', 'NC Naves', 'Setor 06', 'Setor 06', null, 21, 'estimativa', 'gotejo', 'poda', 11, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('d151add8-c2dc-5dd2-82a4-232798ae5be4', 'VEC-S07', 'Vereda — Café', 'NC Naves', 'Setor 07', 'Setor 07', null, 19, 'estimativa', 'gotejo', 'producao', 0, 'KCl = 0 o ano todo (conferir com agrônomo)') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('bb9810e0-8608-5e51-85c2-b3c0c64ee499', 'VEC-S08', 'Vereda — Café', 'NC Naves', 'Setor 08', 'Setor 08', null, 59, 'estimativa', 'gotejo', 'producao', 0, 'SO4 amônia 21000+21000 kg (712 kg/ha, 2x o padrão) — provável erro; resumo da fazenda fecha com ~17500') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('c37449fa-8e4d-5dc2-93fc-9a93bc61337d', 'VEC-S09', 'Vereda — Café', 'NC Naves', 'Setor 9', 'Setor 9', null, 14, 'estimativa', 'gotejo', 'producao', 0, 'sem uréia; nada de mar a jul (plantio novo?)') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('be8d4fed-6766-5e34-b303-4ab9bbd18171', 'VEC-P02', 'Vereda — Café', 'NC Naves', 'Pivô 2', 'Pivô 2', null, 120, 'estimativa', 'pivo', 'producao', 0, 'calagem cobre 109 ha (26+27+56), não 120') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('ae05e0a3-12ab-5f6c-a652-656bff7f1003', 'VEC-P06', 'Vereda — Café', 'NC Naves', 'Pivô 6', 'Pivô 6', null, 53, 'estimativa', 'pivo', 'producao', 0, 'calagem t01/t02 idêntica à do pivô 2 (cópia?)') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('05444656-96f3-593e-9154-eed917760ba4', 'RPL-1P-S01', 'Rio Preto-Lagamar — Café', 'NC Naves', 'Setor 01', 'Setor 01', null, 16, 'estimativa', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('9305a42d-8042-53a8-b963-014655eead9e', 'RPL-1P-S02', 'Rio Preto-Lagamar — Café', 'NC Naves', 'Setor 02', 'Setor 02', null, 16, 'estimativa', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('21c9be63-81e0-5f60-bac8-5779e5852b1e', 'RPL-1P-S03', 'Rio Preto-Lagamar — Café', 'NC Naves', 'Setor 03', 'Setor 03', null, 16, 'estimativa', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('68b975ed-2dcd-57c1-ab2a-ef1f757f488c', 'RPL-1P-S04', 'Rio Preto-Lagamar — Café', 'NC Naves', 'Setor 04', 'Setor 04', null, 16, 'estimativa', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('a0cb7127-3d74-52ad-8cd5-55a1e26f2928', 'RPL-1P-S05', 'Rio Preto-Lagamar — Café', 'NC Naves', 'Setor 05', 'Setor 05', null, 16, 'estimativa', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('530f38fd-d7e9-5aa7-9163-93572635267c', 'RPL-1P-S06', 'Rio Preto-Lagamar — Café', 'NC Naves', 'Setor 06', 'Setor 06', null, 19, 'estimativa', 'gotejo', 'producao', 0, 'calcário implica 20 ha') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('faf865cd-664e-5b0b-b35a-dc32ff72d19e', 'RPL-2P-S01', 'Rio Preto-Lagamar — Café', 'NC Naves', '2º plantio st01', '2º plantio st01', null, 30, 'calcario_rateado', 'gotejo', 'producao', null, '180 ha ÷ 6 (bloco único na calagem); não está na estimativa; coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('5ae9a8d4-7916-5f01-ad2b-dcf7aa0012f4', 'RPL-2P-S02', 'Rio Preto-Lagamar — Café', 'NC Naves', '2º plantio st02', '2º plantio st02', null, 30, 'calcario_rateado', 'gotejo', 'producao', null, '180 ha ÷ 6 (bloco único na calagem); não está na estimativa; coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('4a5f6ffc-385c-5312-8d03-feb7d99aa7a1', 'RPL-2P-S03', 'Rio Preto-Lagamar — Café', 'NC Naves', '2º plantio st03', '2º plantio st03', null, 30, 'calcario_rateado', 'gotejo', 'producao', null, '180 ha ÷ 6 (bloco único na calagem); não está na estimativa; coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('ce3386ac-b315-5910-bb9b-f08fa02759f6', 'RPL-2P-S04', 'Rio Preto-Lagamar — Café', 'NC Naves', '2º plantio st04', '2º plantio st04', null, 30, 'calcario_rateado', 'gotejo', 'producao', null, '180 ha ÷ 6 (bloco único na calagem); não está na estimativa; coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('b1f29351-3db9-5847-94fe-622ab0e449ce', 'RPL-2P-S05', 'Rio Preto-Lagamar — Café', 'NC Naves', '2º plantio st05', '2º plantio st05', null, 30, 'calcario_rateado', 'gotejo', 'producao', null, '180 ha ÷ 6 (bloco único na calagem); não está na estimativa; coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('1d3ba683-7a81-5fdc-bc74-cb59d6af8cb2', 'RPL-2P-S06', 'Rio Preto-Lagamar — Café', 'NC Naves', '2º plantio st06', '2º plantio st06', null, 30, 'calcario_rateado', 'gotejo', 'producao', null, '180 ha ÷ 6 (bloco único na calagem); não está na estimativa; coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('b2d9746a-56e0-5520-9a1d-04aec4418429', 'ROM-S01', 'Vereda Romaria', 'NC Naves', 'Romaria 01', 'Romaria 01', null, 14, 'estimativa', 'gotejo', 'producao', 0, 'calagem e calendário cobrem 01 + 01b (21 ha); Phusion out "4500 no café 2º"') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('321e7e53-05ce-5a3f-bfe8-f1b20e9c4d64', 'ROM-S02', 'Vereda Romaria', 'NC Naves', 'Romaria 02', 'Romaria 02', null, 21, 'estimativa', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('12dc5936-3cf9-546c-a9c0-08e269fd34b9', 'ROM-S03', 'Vereda Romaria', 'NC Naves', 'Romaria 03', 'Romaria 03', null, 25, 'estimativa', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('5e5ab1ed-72db-5e2f-af9d-0be644f4e531', 'ROM-S04', 'Vereda Romaria', 'NC Naves', 'Romaria 04', 'Romaria 04', null, 25, 'estimativa', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('de2ec3af-d83a-5825-ab6e-5a6faea364a7', 'ROM-S05', 'Vereda Romaria', 'NC Naves', 'Romaria 05', 'Romaria 05', null, 20, 'estimativa', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('8e4d0c58-9a49-502e-9cbf-a1ac6427cd37', 'ROM-S06', 'Vereda Romaria', 'NC Naves', 'Romaria 06', 'Romaria 06', null, 20, 'estimativa', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('3a030670-ca55-57f8-8154-8c6e309dcdde', 'ROM-S07', 'Vereda Romaria', 'NC Naves', 'Romaria 07', 'Romaria 07', null, 20, 'estimativa', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('0ac3ef47-0647-559e-ba94-426854020a00', 'ROM-S08', 'Vereda Romaria', 'NC Naves', 'Romaria 08', 'Romaria 08', null, 12, 'estimativa', 'gotejo', 'poda', 2, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('4f82988a-db81-56ad-8f9d-3ff374703b30', 'V56-5PA', 'Vereda Café 5º e 6º', 'NC Naves', '5º Paraíso', '5º Paraíso', null, 34, 'estimativa', 'gotejo', 'poda', 34, '3 setores de irrigação; calcário implica 33 ha') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('f2a64fb7-41dd-5db9-8494-c3a140044061', 'V56-5CA', 'Vereda Café 5º e 6º', 'NC Naves', '5º Catucaí', '5º Catucaí', null, 23, 'estimativa', 'gotejo', 'poda', 23, 'calcário implica 22 ha') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('67532357-b28e-5945-9bac-9f1f790aeda3', 'V56-5BX', 'Vereda Café 5º e 6º', 'NC Naves', '5º café novo', '5º café novo', null, 22, 'estimativa', 'gotejo', 'producao', 0, '3 nomes para a mesma área') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('83da31b8-bc9d-5196-afec-eb837eb67521', 'V56-6MN', 'Vereda Café 5º e 6º', 'NC Naves', '6º M Novo', '6º M Novo', null, 24, 'estimativa', 'gotejo', 'a_confirmar', null, '3 nomes e cultivares contraditórias; "renovação" no nome mas coluna vazia — PERGUNTAR') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('38fe974d-7141-53fd-9108-7f6986f70e28', 'V56-6IPR', 'Vereda Café 5º e 6º', 'NC Naves', '6º IPR 100 + 99', '6º IPR 100 + 99', null, 30, 'estimativa', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('9fb0d512-4eb8-579d-ba1a-b493d8b92699', 'AGL-T1', 'Água Limpa', 'NC Naves', 'T1 Catuaí / IBC', 'T1 Catuaí / IBC', null, 11, 'estimativa', 'gotejo', 'poda', 2, 'Catuaí × Catucaí entre slides — PERGUNTAR') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('7a0dcfc7-802c-5935-9cab-8d97b1195404', 'AGL-T2B', 'Água Limpa', 'NC Naves', 'T2 casinha para baixo', 'T2 casinha para baixo', null, 24, 'estimativa', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('a0c3c64c-19cd-5773-ba30-ed90ab54a8cc', 'AGL-T2C', 'Água Limpa', 'NC Naves', 'T2 casinha para cima', 'T2 casinha para cima', null, 24, 'estimativa', 'gotejo', 'poda', 24, 'numeração muda entre slides (T2/T3)') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('ee998f11-5829-5204-ac4a-4d130b54f202', 'AGL-T3', 'Água Limpa', 'NC Naves', 'T3 2º LD', 'T3 2º LD', null, 11, 'estimativa', 'gotejo', 'producao', 0, 'numeração muda entre slides (T3/T4)') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('1fb5403f-8001-5fe3-9e07-95e25d23906f', 'AGL-T4', 'Água Limpa', 'NC Naves', 'T4 1º e 3º LD', 'T4 1º e 3º LD', null, 22, 'estimativa', 'gotejo', 'producao', 0, '1 unidade = 2 setores de irrigação; numeração T4/T5') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('d5a9be00-bdd8-5330-a596-56d890e33b8c', 'MCC-CXT', 'Monte Carmelo — Café', 'NC Naves', 'Caxico Topázio', 'Caxico Topázio', null, 27, 'calcario', 'gotejo', 'producao', null, 'coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('a7e4adad-b2f2-5e23-8463-3787bb2652fb', 'MCC-CXR', 'Monte Carmelo — Café', 'NC Naves', 'Caxico M Novo recepa', 'Caxico M Novo recepa', null, 29, 'calcario', 'gotejo', 'a_confirmar', null, '"recepa" no nome, coluna vazia — PERGUNTAR') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('7f41a1b1-7ce0-54f3-aaaf-288e22cb0df1', 'MCC-CXP', 'Monte Carmelo — Café', 'NC Naves', 'Caxico represa', 'Caxico represa', null, 27, 'calcario', 'gotejo', 'producao', null, 'KCl 1407 kg/ha, o maior do grupo; coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('68659749-f1c4-59d1-b55a-6f3999140911', 'MCC-S01', 'Monte Carmelo — Café', 'NC Naves', 'M. Carmelo st01', 'M. Carmelo st01', null, 15, 'calcario', 'gotejo', 'producao', null, 'coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('d6b5a1ae-a55d-5dd1-b7a7-e7da3cec855c', 'MCC-S02', 'Monte Carmelo — Café', 'NC Naves', 'M. Carmelo st02', 'M. Carmelo st02', null, 15, 'calcario', 'gotejo', 'producao', null, 'coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('e1ccf609-4fa9-50dd-a186-a18cf0abc3bf', 'MCC-S03', 'Monte Carmelo — Café', 'NC Naves', 'M. Carmelo st03', 'M. Carmelo st03', null, 15, 'calcario', 'gotejo', 'producao', null, 'coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('ece1c8fb-a45f-508b-be01-2c7c3ddbe1af', 'MCC-S04', 'Monte Carmelo — Café', 'NC Naves', 'M. Carmelo st04', 'M. Carmelo st04', null, 15, 'calcario', 'gotejo', 'producao', null, 'coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('92bbe608-c8b7-546f-8968-c1c002d5373a', 'MCC-S05', 'Monte Carmelo — Café', 'NC Naves', 'M. Carmelo st05', 'M. Carmelo st05', null, 15, 'calcario', 'gotejo', 'producao', null, 'coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('66846a44-48cd-5b70-b369-43c45bb73e0f', 'MCC-S06', 'Monte Carmelo — Café', 'NC Naves', 'M. Carmelo st06', 'M. Carmelo st06', null, 15, 'calcario', 'gotejo', 'producao', null, 'coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('dd00abfc-9872-5557-9c8b-988048c9e374', 'MCC-S07', 'Monte Carmelo — Café', 'NC Naves', 'M. Carmelo st07', 'M. Carmelo st07', null, 15, 'calcario', 'gotejo', 'producao', null, 'coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('b34ee153-138e-59ac-a01a-e83272f27443', 'MCC-S08', 'Monte Carmelo — Café', 'NC Naves', 'M. Carmelo st08', 'M. Carmelo st08', null, 15, 'calcario', 'gotejo', 'producao', null, 'coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('4e8a2405-f0a5-5a2c-9dc0-b75ae24703c4', 'MCC-ERA', 'Monte Carmelo — Café', 'NC Naves', 'Sr. Ernani alto', 'Sr. Ernani alto', null, 50, 'calcario', 'gotejo', 'producao', null, '2,4 t/ha de fontes de N (padrão 1,35) — conferir área; coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('3b27bf08-59be-5113-928d-35b82561f0ce', 'MCC-ERB', 'Monte Carmelo — Café', 'NC Naves', 'Sr. Ernani baixo', 'Sr. Ernani baixo', null, 25, 'calcario', 'gotejo', 'producao', null, 'coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('6bea1c27-7fba-5e9f-a8e3-3f3f6106c916', 'LAG-S01', 'Lagamar Café (Rodrigo)', 'NR Agropecuária', 'Setor 01', 'Setor 01', null, 24, 'calcario', 'gotejo', 'producao', null, 'coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('14d58085-9586-5ded-a32c-343711392423', 'LAG-S02', 'Lagamar Café (Rodrigo)', 'NR Agropecuária', 'Setor 02', 'Setor 02', null, 24, 'calcario', 'gotejo', 'producao', null, 'coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('2dff98c4-b84a-5ee5-87ff-68d61e06e24a', 'LAG-S03', 'Lagamar Café (Rodrigo)', 'NR Agropecuária', 'Setor 03', 'Setor 03', null, 24, 'calcario', 'gotejo', 'producao', null, 'coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('4c511371-72fe-5b55-aa8e-8d2bf4556d50', 'LAG-S04', 'Lagamar Café (Rodrigo)', 'NR Agropecuária', 'Setor 04', 'Setor 04', null, 21, 'calcario', 'gotejo', 'producao', null, 'KCl 190 kg/ha, parcela única em jan; coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('e65700e9-2521-575f-9cc1-f758505bf792', 'LAG-S05', 'Lagamar Café (Rodrigo)', 'NR Agropecuária', 'Setor 05', 'Setor 05', null, 21, 'calcario', 'gotejo', 'producao', null, 'coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('4480ebf3-2cd7-5b72-947d-7bc47924b559', 'LAG-S06', 'Lagamar Café (Rodrigo)', 'NR Agropecuária', 'Setor 06', 'Setor 06', null, 21, 'calcario', 'gotejo', 'producao', null, 'KCl 190 kg/ha, parcela única em jan; coluna de safra zerada em branco no deck — status "producao" assumido na carga') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('a3273601-419a-5ea5-a9ed-385e506124a3', 'LAG-JX', 'Lagamar Café (Rodrigo)', 'NR Agropecuária', 'João Xavier', 'João Xavier', null, 26, 'calcario', 'gotejo', 'producao', 0, 'não está na estimativa') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('11741a30-74ef-55e1-9e5c-6e7587d8ab6d', 'MTP-S01', 'Mata Preta — Café', 'NR Agropecuária', 'Setor 01', 'Setor 01', null, 19, 'calcario', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('6a7ae5ab-b93c-5183-aefb-0cbc27c323e2', 'MTP-S02', 'Mata Preta — Café', 'NR Agropecuária', 'Setor 02', 'Setor 02', null, 19, 'calcario', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('1a67fd03-2921-5347-a427-016d3cfb5a5c', 'MTP-S03', 'Mata Preta — Café', 'NR Agropecuária', 'Setor 03', 'Setor 03', null, 20, 'calcario', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('6797f7f4-63fa-546f-8805-76ff097e1a82', 'MTP-S04', 'Mata Preta — Café', 'NR Agropecuária', 'Setor 04', 'Setor 04', null, 20, 'calcario', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('4e33f057-81de-558a-a5e7-6f17acdb1bc2', 'MTP-S05', 'Mata Preta — Café', 'NR Agropecuária', 'Setor 05', 'Setor 05', null, 20, 'calcario', 'gotejo', 'producao', 0, null) on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('cd1794c9-fb60-5d58-b1b3-08b75a82f9ee', 'MTP-P26', 'Mata Preta — Café', 'NR Agropecuária', 'Plantio 2026', 'Plantio 2026', null, 45, 'calcario', 'gotejo', 'plantio', 45, 'só na calagem; sem calendário de adubação') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('2ddaf15a-ea77-573d-9709-0da47cada1d1', 'MTP-3PT', 'Mata Preta — Café', 'NR Agropecuária', '3º plantio (torres)', '3º plantio (torres)', null, null, null, 'gotejo', 'producao', 0, 'só no calendário; sem calagem; maior programa do deck — PERGUNTAR área e identidade; sem área: ok — liberado pelo Escritório em 03/09/2026 para publicar a v1; área e identidade a informar pelo agrônomo') on conflict (codigo) do nothing;
insert into public.unidade_manejo (id, codigo, fazenda_app, empresa, nome_plano, nome_curto, pai_id, area_ha, fonte_area, irrigacao, status, area_zerada_ha, obs) values ('83ff034d-ee46-5f43-84fc-b3570b265738', 'ROM-S01B', 'Vereda Romaria', 'NC Naves', 'Romaria 01 b', 'Romaria 01 b', 'b2d9746a-56e0-5520-9a1d-04aec4418429', 7, 'estimativa', 'gotejo', 'producao', 0, 'sem calagem nem calendário próprios; contido em "Romaria setor 01" (21 ha)') on conflict (codigo) do nothing;

-- 2. unidade_alias sistema=plano (nome do deck + apelidos) -----------------
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('cea5a300-adcb-57e0-be8f-7a8ff70047b7', 'Vereda — Café', 'plano', 'Setor 01') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('cea5a300-adcb-57e0-be8f-7a8ff70047b7', 'Vereda — Café', 'plano', 'Vereda setor 01') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('cea5a300-adcb-57e0-be8f-7a8ff70047b7', 'Vereda — Café', 'plano', 'setor 01 Vereda') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('0d74c8e4-798c-534e-9bd0-838710c38867', 'Vereda — Café', 'plano', 'Setor 02') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('0d74c8e4-798c-534e-9bd0-838710c38867', 'Vereda — Café', 'plano', 'Vereda setor 02') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('0d74c8e4-798c-534e-9bd0-838710c38867', 'Vereda — Café', 'plano', 'setor 02 Vereda') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('077292a8-e8ca-5518-b830-58c7c9478509', 'Vereda — Café', 'plano', 'Setor 03') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('077292a8-e8ca-5518-b830-58c7c9478509', 'Vereda — Café', 'plano', 'Vereda setor 03') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('077292a8-e8ca-5518-b830-58c7c9478509', 'Vereda — Café', 'plano', 'setor 03 Vereda') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('51b4ff94-68e2-5bf1-bcf9-3ac595cb7355', 'Vereda — Café', 'plano', 'Setor 04') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('51b4ff94-68e2-5bf1-bcf9-3ac595cb7355', 'Vereda — Café', 'plano', 'Vereda setor 04') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('51b4ff94-68e2-5bf1-bcf9-3ac595cb7355', 'Vereda — Café', 'plano', 'setor 04 Vereda') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('922e16bf-e805-5091-bbf8-5d104e3db726', 'Vereda — Café', 'plano', 'Setor 05') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('922e16bf-e805-5091-bbf8-5d104e3db726', 'Vereda — Café', 'plano', 'Vereda setor 05') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('922e16bf-e805-5091-bbf8-5d104e3db726', 'Vereda — Café', 'plano', 'setor 05 Vereda') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('8794ebc3-0652-5321-af14-77cbca328844', 'Vereda — Café', 'plano', 'Setor 06') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('8794ebc3-0652-5321-af14-77cbca328844', 'Vereda — Café', 'plano', 'Vereda setor 06') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('8794ebc3-0652-5321-af14-77cbca328844', 'Vereda — Café', 'plano', 'setor 06 Vereda') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('d151add8-c2dc-5dd2-82a4-232798ae5be4', 'Vereda — Café', 'plano', 'Setor 07') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('d151add8-c2dc-5dd2-82a4-232798ae5be4', 'Vereda — Café', 'plano', 'Vereda setor 07') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('d151add8-c2dc-5dd2-82a4-232798ae5be4', 'Vereda — Café', 'plano', 'setor 07 Vereda') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('bb9810e0-8608-5e51-85c2-b3c0c64ee499', 'Vereda — Café', 'plano', 'Setor 08') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('bb9810e0-8608-5e51-85c2-b3c0c64ee499', 'Vereda — Café', 'plano', 'Vereda 08 alto') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('bb9810e0-8608-5e51-85c2-b3c0c64ee499', 'Vereda — Café', 'plano', 'Vereda 08 baixo') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('bb9810e0-8608-5e51-85c2-b3c0c64ee499', 'Vereda — Café', 'plano', 'setor 08 Vereda') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('c37449fa-8e4d-5dc2-93fc-9a93bc61337d', 'Vereda — Café', 'plano', 'Setor 9') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('c37449fa-8e4d-5dc2-93fc-9a93bc61337d', 'Vereda — Café', 'plano', 'Vereda setor 09') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('c37449fa-8e4d-5dc2-93fc-9a93bc61337d', 'Vereda — Café', 'plano', 'setor 09 Vereda') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('be8d4fed-6766-5e34-b303-4ab9bbd18171', 'Vereda — Café', 'plano', 'Pivô 2') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('be8d4fed-6766-5e34-b303-4ab9bbd18171', 'Vereda — Café', 'plano', 'Vereda pivô 02 t01') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('be8d4fed-6766-5e34-b303-4ab9bbd18171', 'Vereda — Café', 'plano', 'Vereda pivô 02 t02') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('be8d4fed-6766-5e34-b303-4ab9bbd18171', 'Vereda — Café', 'plano', 'Vereda pivô 02 t03') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('be8d4fed-6766-5e34-b303-4ab9bbd18171', 'Vereda — Café', 'plano', 'Pivô 02 Vereda') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('ae05e0a3-12ab-5f6c-a652-656bff7f1003', 'Vereda — Café', 'plano', 'Pivô 6') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('ae05e0a3-12ab-5f6c-a652-656bff7f1003', 'Vereda — Café', 'plano', 'Vereda pivô 06 t01') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('ae05e0a3-12ab-5f6c-a652-656bff7f1003', 'Vereda — Café', 'plano', 'Vereda pivô 06 t02') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('ae05e0a3-12ab-5f6c-a652-656bff7f1003', 'Vereda — Café', 'plano', 'Pivô 06 Vereda') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('05444656-96f3-593e-9154-eed917760ba4', 'Rio Preto-Lagamar — Café', 'plano', 'Setor 01') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('05444656-96f3-593e-9154-eed917760ba4', 'Rio Preto-Lagamar — Café', 'plano', 'St01 1º plantio') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('05444656-96f3-593e-9154-eed917760ba4', 'Rio Preto-Lagamar — Café', 'plano', '1º plantio st01') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('9305a42d-8042-53a8-b963-014655eead9e', 'Rio Preto-Lagamar — Café', 'plano', 'Setor 02') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('9305a42d-8042-53a8-b963-014655eead9e', 'Rio Preto-Lagamar — Café', 'plano', 'St02 1º plantio') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('9305a42d-8042-53a8-b963-014655eead9e', 'Rio Preto-Lagamar — Café', 'plano', '1º plantio st02') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('21c9be63-81e0-5f60-bac8-5779e5852b1e', 'Rio Preto-Lagamar — Café', 'plano', 'Setor 03') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('21c9be63-81e0-5f60-bac8-5779e5852b1e', 'Rio Preto-Lagamar — Café', 'plano', 'St03 1º plantio') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('21c9be63-81e0-5f60-bac8-5779e5852b1e', 'Rio Preto-Lagamar — Café', 'plano', '1º plantio st03') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('68b975ed-2dcd-57c1-ab2a-ef1f757f488c', 'Rio Preto-Lagamar — Café', 'plano', 'Setor 04') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('68b975ed-2dcd-57c1-ab2a-ef1f757f488c', 'Rio Preto-Lagamar — Café', 'plano', 'St04 1º plantio') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('68b975ed-2dcd-57c1-ab2a-ef1f757f488c', 'Rio Preto-Lagamar — Café', 'plano', '1º plantio st04') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('a0cb7127-3d74-52ad-8cd5-55a1e26f2928', 'Rio Preto-Lagamar — Café', 'plano', 'Setor 05') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('a0cb7127-3d74-52ad-8cd5-55a1e26f2928', 'Rio Preto-Lagamar — Café', 'plano', 'St05 1º plantio') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('a0cb7127-3d74-52ad-8cd5-55a1e26f2928', 'Rio Preto-Lagamar — Café', 'plano', '1º plantio st05') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('530f38fd-d7e9-5aa7-9163-93572635267c', 'Rio Preto-Lagamar — Café', 'plano', 'Setor 06') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('530f38fd-d7e9-5aa7-9163-93572635267c', 'Rio Preto-Lagamar — Café', 'plano', 'St06 1º plantio') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('530f38fd-d7e9-5aa7-9163-93572635267c', 'Rio Preto-Lagamar — Café', 'plano', '1º plantio st06') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('faf865cd-664e-5b0b-b35a-dc32ff72d19e', 'Rio Preto-Lagamar — Café', 'plano', '2º plantio st01') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('5ae9a8d4-7916-5f01-ad2b-dcf7aa0012f4', 'Rio Preto-Lagamar — Café', 'plano', '2º plantio st02') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('4a5f6ffc-385c-5312-8d03-feb7d99aa7a1', 'Rio Preto-Lagamar — Café', 'plano', '2º plantio st03') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('ce3386ac-b315-5910-bb9b-f08fa02759f6', 'Rio Preto-Lagamar — Café', 'plano', '2º plantio st04') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('b1f29351-3db9-5847-94fe-622ab0e449ce', 'Rio Preto-Lagamar — Café', 'plano', '2º plantio st05') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('1d3ba683-7a81-5fdc-bc74-cb59d6af8cb2', 'Rio Preto-Lagamar — Café', 'plano', '2º plantio st06') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('83ff034d-ee46-5f43-84fc-b3570b265738', 'Vereda Romaria', 'plano', 'Romaria 01 b') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('b2d9746a-56e0-5520-9a1d-04aec4418429', 'Vereda Romaria', 'plano', 'Romaria 01') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('b2d9746a-56e0-5520-9a1d-04aec4418429', 'Vereda Romaria', 'plano', 'Romaria setor 01') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('b2d9746a-56e0-5520-9a1d-04aec4418429', 'Vereda Romaria', 'plano', 'setor 01 Romaria') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('321e7e53-05ce-5a3f-bfe8-f1b20e9c4d64', 'Vereda Romaria', 'plano', 'Romaria 02') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('321e7e53-05ce-5a3f-bfe8-f1b20e9c4d64', 'Vereda Romaria', 'plano', 'Romaria setor 02') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('321e7e53-05ce-5a3f-bfe8-f1b20e9c4d64', 'Vereda Romaria', 'plano', 'setor 02 Romaria') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('12dc5936-3cf9-546c-a9c0-08e269fd34b9', 'Vereda Romaria', 'plano', 'Romaria 03') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('12dc5936-3cf9-546c-a9c0-08e269fd34b9', 'Vereda Romaria', 'plano', 'Romaria setor 03') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('12dc5936-3cf9-546c-a9c0-08e269fd34b9', 'Vereda Romaria', 'plano', 'setor 03 Romaria') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('5e5ab1ed-72db-5e2f-af9d-0be644f4e531', 'Vereda Romaria', 'plano', 'Romaria 04') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('5e5ab1ed-72db-5e2f-af9d-0be644f4e531', 'Vereda Romaria', 'plano', 'Romaria setor 04') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('5e5ab1ed-72db-5e2f-af9d-0be644f4e531', 'Vereda Romaria', 'plano', 'setor 04 Romaria') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('de2ec3af-d83a-5825-ab6e-5a6faea364a7', 'Vereda Romaria', 'plano', 'Romaria 05') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('de2ec3af-d83a-5825-ab6e-5a6faea364a7', 'Vereda Romaria', 'plano', 'Romaria setor 05') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('de2ec3af-d83a-5825-ab6e-5a6faea364a7', 'Vereda Romaria', 'plano', 'setor 05 Romaria') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('8e4d0c58-9a49-502e-9cbf-a1ac6427cd37', 'Vereda Romaria', 'plano', 'Romaria 06') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('8e4d0c58-9a49-502e-9cbf-a1ac6427cd37', 'Vereda Romaria', 'plano', 'Romaria setor 06') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('8e4d0c58-9a49-502e-9cbf-a1ac6427cd37', 'Vereda Romaria', 'plano', 'setor 06 Romaria') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('3a030670-ca55-57f8-8154-8c6e309dcdde', 'Vereda Romaria', 'plano', 'Romaria 07') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('3a030670-ca55-57f8-8154-8c6e309dcdde', 'Vereda Romaria', 'plano', 'Romaria setor 07') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('3a030670-ca55-57f8-8154-8c6e309dcdde', 'Vereda Romaria', 'plano', 'setor 07 Romaria') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('0ac3ef47-0647-559e-ba94-426854020a00', 'Vereda Romaria', 'plano', 'Romaria 08') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('0ac3ef47-0647-559e-ba94-426854020a00', 'Vereda Romaria', 'plano', 'Romaria setor 08') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('0ac3ef47-0647-559e-ba94-426854020a00', 'Vereda Romaria', 'plano', 'setor 08 Romaria') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('4f82988a-db81-56ad-8f9d-3ff374703b30', 'Vereda Café 5º e 6º', 'plano', '5º Paraíso') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('4f82988a-db81-56ad-8f9d-3ff374703b30', 'Vereda Café 5º e 6º', 'plano', 'Café 5º Paraíso') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('4f82988a-db81-56ad-8f9d-3ff374703b30', 'Vereda Café 5º e 6º', 'plano', '5º paraíso (st 01,02,03)') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('f2a64fb7-41dd-5db9-8494-c3a140044061', 'Vereda Café 5º e 6º', 'plano', '5º Catucaí') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('f2a64fb7-41dd-5db9-8494-c3a140044061', 'Vereda Café 5º e 6º', 'plano', 'Café 5º Catucaí') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('f2a64fb7-41dd-5db9-8494-c3a140044061', 'Vereda Café 5º e 6º', 'plano', '5º Catucaí (st 04,05)') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('67532357-b28e-5945-9bac-9f1f790aeda3', 'Vereda Café 5º e 6º', 'plano', '5º café novo') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('67532357-b28e-5945-9bac-9f1f790aeda3', 'Vereda Café 5º e 6º', 'plano', 'Café 5º novo') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('67532357-b28e-5945-9bac-9f1f790aeda3', 'Vereda Café 5º e 6º', 'plano', '5º baixada (st 06,07)') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('83da31b8-bc9d-5196-afec-eb837eb67521', 'Vereda Café 5º e 6º', 'plano', '6º M Novo') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('83da31b8-bc9d-5196-afec-eb837eb67521', 'Vereda Café 5º e 6º', 'plano', 'Café 6º renovação') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('83da31b8-bc9d-5196-afec-eb837eb67521', 'Vereda Café 5º e 6º', 'plano', '6º Catuaí') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('38fe974d-7141-53fd-9108-7f6986f70e28', 'Vereda Café 5º e 6º', 'plano', '6º IPR 100 + 99') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('38fe974d-7141-53fd-9108-7f6986f70e28', 'Vereda Café 5º e 6º', 'plano', 'Café 6º IPR 100/ CT 99') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('38fe974d-7141-53fd-9108-7f6986f70e28', 'Vereda Café 5º e 6º', 'plano', '6º IPR100') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('9fb0d512-4eb8-579d-ba1a-b493d8b92699', 'Água Limpa', 'plano', 'T1 Catuaí / IBC') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('9fb0d512-4eb8-579d-ba1a-b493d8b92699', 'Água Limpa', 'plano', 'T1 Catuaí / IBC (setor 04)') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('9fb0d512-4eb8-579d-ba1a-b493d8b92699', 'Água Limpa', 'plano', 'Água Limpa talhão Catucaí 01') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('7a0dcfc7-802c-5935-9cab-8d97b1195404', 'Água Limpa', 'plano', 'T2 casinha para baixo') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('7a0dcfc7-802c-5935-9cab-8d97b1195404', 'Água Limpa', 'plano', 'T2 casinha para baixo (setores 7 e 8)') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('7a0dcfc7-802c-5935-9cab-8d97b1195404', 'Água Limpa', 'plano', 'talhão 02 casinha para baixo') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('a0c3c64c-19cd-5773-ba30-ed90ab54a8cc', 'Água Limpa', 'plano', 'T2 casinha para cima') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('a0c3c64c-19cd-5773-ba30-ed90ab54a8cc', 'Água Limpa', 'plano', 'T3 casinha para cima (setores 5 e 6)') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('a0c3c64c-19cd-5773-ba30-ed90ab54a8cc', 'Água Limpa', 'plano', 'talhão 02 casinha para cima') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('ee998f11-5829-5204-ac4a-4d130b54f202', 'Água Limpa', 'plano', 'T3 2º LD') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('ee998f11-5829-5204-ac4a-4d130b54f202', 'Água Limpa', 'plano', 'T4 2º LD (setor 02)') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('ee998f11-5829-5204-ac4a-4d130b54f202', 'Água Limpa', 'plano', 'talhão 03 (2º LD)') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('1fb5403f-8001-5fe3-9e07-95e25d23906f', 'Água Limpa', 'plano', 'T4 1º e 3º LD') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('1fb5403f-8001-5fe3-9e07-95e25d23906f', 'Água Limpa', 'plano', 'T5 1º e 3º LD (setores 1 e 3)') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('1fb5403f-8001-5fe3-9e07-95e25d23906f', 'Água Limpa', 'plano', 'talhão 04 (1º e 3º LD)') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('d5a9be00-bdd8-5330-a596-56d890e33b8c', 'Monte Carmelo — Café', 'plano', 'Caxico Topázio') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('d5a9be00-bdd8-5330-a596-56d890e33b8c', 'Monte Carmelo — Café', 'plano', 'Caxico topázio') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('a7e4adad-b2f2-5e23-8463-3787bb2652fb', 'Monte Carmelo — Café', 'plano', 'Caxico M Novo recepa') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('a7e4adad-b2f2-5e23-8463-3787bb2652fb', 'Monte Carmelo — Café', 'plano', 'Caxico Mundo novo recepa') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('7f41a1b1-7ce0-54f3-aaaf-288e22cb0df1', 'Monte Carmelo — Café', 'plano', 'Caxico represa') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('7f41a1b1-7ce0-54f3-aaaf-288e22cb0df1', 'Monte Carmelo — Café', 'plano', 'Caxico represa (Mundo novo e Catuaí99)') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('68659749-f1c4-59d1-b55a-6f3999140911', 'Monte Carmelo — Café', 'plano', 'M. Carmelo st01') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('68659749-f1c4-59d1-b55a-6f3999140911', 'Monte Carmelo — Café', 'plano', 'Monte Carmelo st01') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('d6b5a1ae-a55d-5dd1-b7a7-e7da3cec855c', 'Monte Carmelo — Café', 'plano', 'M. Carmelo st02') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('d6b5a1ae-a55d-5dd1-b7a7-e7da3cec855c', 'Monte Carmelo — Café', 'plano', 'Monte Carmelo st02') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('e1ccf609-4fa9-50dd-a186-a18cf0abc3bf', 'Monte Carmelo — Café', 'plano', 'M. Carmelo st03') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('e1ccf609-4fa9-50dd-a186-a18cf0abc3bf', 'Monte Carmelo — Café', 'plano', 'Monte Carmelo st03') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('ece1c8fb-a45f-508b-be01-2c7c3ddbe1af', 'Monte Carmelo — Café', 'plano', 'M. Carmelo st04') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('ece1c8fb-a45f-508b-be01-2c7c3ddbe1af', 'Monte Carmelo — Café', 'plano', 'Monte Carmelo st04') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('92bbe608-c8b7-546f-8968-c1c002d5373a', 'Monte Carmelo — Café', 'plano', 'M. Carmelo st05') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('92bbe608-c8b7-546f-8968-c1c002d5373a', 'Monte Carmelo — Café', 'plano', 'Monte Carmelo st05') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('66846a44-48cd-5b70-b369-43c45bb73e0f', 'Monte Carmelo — Café', 'plano', 'M. Carmelo st06') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('66846a44-48cd-5b70-b369-43c45bb73e0f', 'Monte Carmelo — Café', 'plano', 'Monte Carmelo st06') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('dd00abfc-9872-5557-9c8b-988048c9e374', 'Monte Carmelo — Café', 'plano', 'M. Carmelo st07') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('dd00abfc-9872-5557-9c8b-988048c9e374', 'Monte Carmelo — Café', 'plano', 'Monte Carmelo st07') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('b34ee153-138e-59ac-a01a-e83272f27443', 'Monte Carmelo — Café', 'plano', 'M. Carmelo st08') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('b34ee153-138e-59ac-a01a-e83272f27443', 'Monte Carmelo — Café', 'plano', 'Monte Carmelo st08') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('4e8a2405-f0a5-5a2c-9dc0-b75ae24703c4', 'Monte Carmelo — Café', 'plano', 'Sr. Ernani alto') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('3b27bf08-59be-5113-928d-35b82561f0ce', 'Monte Carmelo — Café', 'plano', 'Sr. Ernani baixo') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('6bea1c27-7fba-5e9f-a8e3-3f3f6106c916', 'Lagamar Café (Rodrigo)', 'plano', 'Setor 01') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('6bea1c27-7fba-5e9f-a8e3-3f3f6106c916', 'Lagamar Café (Rodrigo)', 'plano', 'setor 01') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('14d58085-9586-5ded-a32c-343711392423', 'Lagamar Café (Rodrigo)', 'plano', 'Setor 02') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('14d58085-9586-5ded-a32c-343711392423', 'Lagamar Café (Rodrigo)', 'plano', 'setor 02') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('2dff98c4-b84a-5ee5-87ff-68d61e06e24a', 'Lagamar Café (Rodrigo)', 'plano', 'Setor 03') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('2dff98c4-b84a-5ee5-87ff-68d61e06e24a', 'Lagamar Café (Rodrigo)', 'plano', 'setor 03') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('4c511371-72fe-5b55-aa8e-8d2bf4556d50', 'Lagamar Café (Rodrigo)', 'plano', 'Setor 04') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('4c511371-72fe-5b55-aa8e-8d2bf4556d50', 'Lagamar Café (Rodrigo)', 'plano', 'setor 04') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('e65700e9-2521-575f-9cc1-f758505bf792', 'Lagamar Café (Rodrigo)', 'plano', 'Setor 05') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('e65700e9-2521-575f-9cc1-f758505bf792', 'Lagamar Café (Rodrigo)', 'plano', 'setor 05') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('4480ebf3-2cd7-5b72-947d-7bc47924b559', 'Lagamar Café (Rodrigo)', 'plano', 'Setor 06') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('4480ebf3-2cd7-5b72-947d-7bc47924b559', 'Lagamar Café (Rodrigo)', 'plano', 'setor 06') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('a3273601-419a-5ea5-a9ed-385e506124a3', 'Lagamar Café (Rodrigo)', 'plano', 'João Xavier') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('a3273601-419a-5ea5-a9ed-385e506124a3', 'Lagamar Café (Rodrigo)', 'plano', 'Joao Xavier') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('11741a30-74ef-55e1-9e5c-6e7587d8ab6d', 'Mata Preta — Café', 'plano', 'Setor 01') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('11741a30-74ef-55e1-9e5c-6e7587d8ab6d', 'Mata Preta — Café', 'plano', 'setor 01') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('6a7ae5ab-b93c-5183-aefb-0cbc27c323e2', 'Mata Preta — Café', 'plano', 'Setor 02') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('6a7ae5ab-b93c-5183-aefb-0cbc27c323e2', 'Mata Preta — Café', 'plano', 'setor 02') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('1a67fd03-2921-5347-a427-016d3cfb5a5c', 'Mata Preta — Café', 'plano', 'Setor 03') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('1a67fd03-2921-5347-a427-016d3cfb5a5c', 'Mata Preta — Café', 'plano', 'setor 03') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('6797f7f4-63fa-546f-8805-76ff097e1a82', 'Mata Preta — Café', 'plano', 'Setor 04') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('6797f7f4-63fa-546f-8805-76ff097e1a82', 'Mata Preta — Café', 'plano', 'setor 04') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('4e33f057-81de-558a-a5e7-6f17acdb1bc2', 'Mata Preta — Café', 'plano', 'Setor 05') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('4e33f057-81de-558a-a5e7-6f17acdb1bc2', 'Mata Preta — Café', 'plano', 'setor 05') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('cd1794c9-fb60-5d58-b1b3-08b75a82f9ee', 'Mata Preta — Café', 'plano', 'Plantio 2026') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('2ddaf15a-ea77-573d-9709-0da47cada1d1', 'Mata Preta — Café', 'plano', '3º plantio (torres)') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;
-- apelido AMBÍGUO não gravado: Rio Preto-Lagamar — Café / "2º Plantio 180 hectares" vale para RPL-2P-S01, RPL-2P-S02, RPL-2P-S03, RPL-2P-S04, RPL-2P-S05, RPL-2P-S06

-- 3. unidade_alias sistema=app (id do talhão no cadastro do app) — só fazendas confirmadas
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('9fb0d512-4eb8-579d-ba1a-b493d8b92699', 'Água Limpa', 'app', 't004') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 4 — Catuaí
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('7a0dcfc7-802c-5935-9cab-8d97b1195404', 'Água Limpa', 'app', 't007') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 7 — IPR 100
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('7a0dcfc7-802c-5935-9cab-8d97b1195404', 'Água Limpa', 'app', 't008') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 8 — IPR 100
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('a0c3c64c-19cd-5773-ba30-ed90ab54a8cc', 'Água Limpa', 'app', 't005') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 5 — IPR 100
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('a0c3c64c-19cd-5773-ba30-ed90ab54a8cc', 'Água Limpa', 'app', 't006') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 6 — IPR 100
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('ee998f11-5829-5204-ac4a-4d130b54f202', 'Água Limpa', 'app', 't002') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 2 — IPR 100
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('1fb5403f-8001-5fe3-9e07-95e25d23906f', 'Água Limpa', 'app', 't001') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 1 — IBC 12
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('1fb5403f-8001-5fe3-9e07-95e25d23906f', 'Água Limpa', 'app', 't003') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 3 — IBC 12
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('d5a9be00-bdd8-5330-a596-56d890e33b8c', 'Monte Carmelo — Café', 'app', 't021') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Caxico — Topázio
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('a7e4adad-b2f2-5e23-8463-3787bb2652fb', 'Monte Carmelo — Café', 'app', 't020') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Caxico — Mundo Novo
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('b2d9746a-56e0-5520-9a1d-04aec4418429', 'Vereda Romaria', 'app', 't101') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 1
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('321e7e53-05ce-5a3f-bfe8-f1b20e9c4d64', 'Vereda Romaria', 'app', 't102') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 2
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('12dc5936-3cf9-546c-a9c0-08e269fd34b9', 'Vereda Romaria', 'app', 't103') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 3
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('5e5ab1ed-72db-5e2f-af9d-0be644f4e531', 'Vereda Romaria', 'app', 't104') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 4
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('de2ec3af-d83a-5825-ab6e-5a6faea364a7', 'Vereda Romaria', 'app', 't105') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 5
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('8e4d0c58-9a49-502e-9cbf-a1ac6427cd37', 'Vereda Romaria', 'app', 't106') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 6
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('3a030670-ca55-57f8-8154-8c6e309dcdde', 'Vereda Romaria', 'app', 't107') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 7
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('0ac3ef47-0647-559e-ba94-426854020a00', 'Vereda Romaria', 'app', 't108') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 8
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('cea5a300-adcb-57e0-be8f-7a8ff70047b7', 'Vereda — Café', 'app', 't086') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 01
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('0d74c8e4-798c-534e-9bd0-838710c38867', 'Vereda — Café', 'app', 't087') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 02
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('077292a8-e8ca-5518-b830-58c7c9478509', 'Vereda — Café', 'app', 't088') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 03
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('51b4ff94-68e2-5bf1-bcf9-3ac595cb7355', 'Vereda — Café', 'app', 't089') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 04
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('922e16bf-e805-5091-bbf8-5d104e3db726', 'Vereda — Café', 'app', 't090') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 05
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('8794ebc3-0652-5321-af14-77cbca328844', 'Vereda — Café', 'app', 't091') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 06
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('d151add8-c2dc-5dd2-82a4-232798ae5be4', 'Vereda — Café', 'app', 't092') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 07
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('bb9810e0-8608-5e51-85c2-b3c0c64ee499', 'Vereda — Café', 'app', 't093') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 08
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('c37449fa-8e4d-5dc2-93fc-9a93bc61337d', 'Vereda — Café', 'app', 't094') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 09
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('6bea1c27-7fba-5e9f-a8e3-3f3f6106c916', 'Lagamar Café (Rodrigo)', 'app', 't077') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Café Rodrigo — Setor 1
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('14d58085-9586-5ded-a32c-343711392423', 'Lagamar Café (Rodrigo)', 'app', 't078') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Café Rodrigo — Setor 2
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('2dff98c4-b84a-5ee5-87ff-68d61e06e24a', 'Lagamar Café (Rodrigo)', 'app', 't079') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Café Rodrigo — Setor 3
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('4c511371-72fe-5b55-aa8e-8d2bf4556d50', 'Lagamar Café (Rodrigo)', 'app', 't080') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Café Rodrigo — Setor 4
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('e65700e9-2521-575f-9cc1-f758505bf792', 'Lagamar Café (Rodrigo)', 'app', 't081') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Café Rodrigo — Setor 5
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('4480ebf3-2cd7-5b72-947d-7bc47924b559', 'Lagamar Café (Rodrigo)', 'app', 't082') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Café Rodrigo — Setor 6
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('a3273601-419a-5ea5-a9ed-385e506124a3', 'Lagamar Café (Rodrigo)', 'app', 't083') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Arrendo João Xavier
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('11741a30-74ef-55e1-9e5c-6e7587d8ab6d', 'Mata Preta — Café', 'app', 't045') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 1
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('6a7ae5ab-b93c-5183-aefb-0cbc27c323e2', 'Mata Preta — Café', 'app', 't046') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 2
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('1a67fd03-2921-5347-a427-016d3cfb5a5c', 'Mata Preta — Café', 'app', 't047') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 3
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('6797f7f4-63fa-546f-8805-76ff097e1a82', 'Mata Preta — Café', 'app', 't048') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 4
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('4e33f057-81de-558a-a5e7-6f17acdb1bc2', 'Mata Preta — Café', 'app', 't049') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 5
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('05444656-96f3-593e-9154-eed917760ba4', 'Rio Preto-Lagamar — Café', 'app', 't064') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 1 (café grupo)
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('9305a42d-8042-53a8-b963-014655eead9e', 'Rio Preto-Lagamar — Café', 'app', 't065') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 2 (café grupo)
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('21c9be63-81e0-5f60-bac8-5779e5852b1e', 'Rio Preto-Lagamar — Café', 'app', 't066') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 3 (café grupo)
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('68b975ed-2dcd-57c1-ab2a-ef1f757f488c', 'Rio Preto-Lagamar — Café', 'app', 't067') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 4 (café grupo)
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('a0cb7127-3d74-52ad-8cd5-55a1e26f2928', 'Rio Preto-Lagamar — Café', 'app', 't068') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 5 (café grupo)
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('530f38fd-d7e9-5aa7-9163-93572635267c', 'Rio Preto-Lagamar — Café', 'app', 't069') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 6 (café grupo)
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('530f38fd-d7e9-5aa7-9163-93572635267c', 'Rio Preto-Lagamar — Café', 'app', 't070') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Setor 7 (café grupo)
insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values ('7f41a1b1-7ce0-54f3-aaaf-288e22cb0df1', 'Monte Carmelo — Café', 'app', 't019') on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- Caxico — Área Nova

-- 4. plano_safra — versão 1 em rascunho, uma por fazenda -----------------
--    resumo_deck = kg/ano do slide-resumo do deck (a auditoria compara com a soma dos calendários)
insert into public.plano_safra (id, fazenda_app, safra, versao, status, motivo, arquivo_origem, criado_por, auditoria_ok, resumo_deck) values ('cef76739-e882-56ac-8be7-bc599da7808c', 'Vereda — Café', '2026/27', 1, 'rascunho', 'carga inicial dos PPTX de 2026/27', 'Vereda_NC_NAVES_safra_26_27.pptx', 'seed v52 (gerar_seed_plano.py)', false, '{"ureia": 73000, "nitrato": 304000, "sulfato_amonio": 139000, "kcl": 387000, "phusion": 3500, "sulfato_mn": 4700, "acido_borico": 10600, "sulfato_zn": 5950}'::jsonb) on conflict (fazenda_app, safra, versao) do nothing;
insert into public.plano_safra (id, fazenda_app, safra, versao, status, motivo, arquivo_origem, criado_por, auditoria_ok, resumo_deck) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', 'Rio Preto-Lagamar — Café', '2026/27', 1, 'rascunho', 'carga inicial dos PPTX de 2026/27', 'Rio_Preto_NC_NAVES_safra_26_27.pptx', 'seed v52 (gerar_seed_plano.py)', false, '{"ureia": 55000, "nitrato": 223500, "sulfato_amonio": 101000, "kcl": 150000, "phusion": 0, "sulfato_mn": 3525, "acido_borico": 7650, "sulfato_zn": 4425}'::jsonb) on conflict (fazenda_app, safra, versao) do nothing;
insert into public.plano_safra (id, fazenda_app, safra, versao, status, motivo, arquivo_origem, criado_por, auditoria_ok, resumo_deck) values ('3bc4573e-978d-58dd-a97d-26d240b75da5', 'Vereda Romaria', '2026/27', 1, 'rascunho', 'carga inicial dos PPTX de 2026/27', 'Romaria_NC_NAVES_safra__26_27.pptx', 'seed v52 (gerar_seed_plano.py)', false, '{"ureia": 34000, "nitrato": 136000, "sulfato_amonio": 60500, "kcl": 183000, "phusion": 4500, "sulfato_mn": 2100, "acido_borico": 4950, "sulfato_zn": 2600}'::jsonb) on conflict (fazenda_app, safra, versao) do nothing;
insert into public.plano_safra (id, fazenda_app, safra, versao, status, motivo, arquivo_origem, criado_por, auditoria_ok, resumo_deck) values ('d6b4408b-6b1c-5793-ae94-87383995a6fc', 'Vereda Café 5º e 6º', '2026/27', 1, 'rascunho', 'carga inicial dos PPTX de 2026/27', 'Romaria_NC_NAVES_safra__26_27.pptx', 'seed v52 (gerar_seed_plano.py)', false, '{"ureia": 23500, "nitrato": 101000, "sulfato_amonio": 45500, "kcl": 91000, "phusion": 0, "sulfato_mn": 1550, "acido_borico": 3500, "sulfato_zn": 1950}'::jsonb) on conflict (fazenda_app, safra, versao) do nothing;
insert into public.plano_safra (id, fazenda_app, safra, versao, status, motivo, arquivo_origem, criado_por, auditoria_ok, resumo_deck) values ('8cc75fc4-d102-5f55-952d-e4fb6b86c85a', 'Água Limpa', '2026/27', 1, 'rascunho', 'carga inicial dos PPTX de 2026/27', 'A___Limpa_NC_NAVES_safra_26_27.pptx', 'seed v52 (gerar_seed_plano.py)', false, '{"ureia": 17000, "nitrato": 74000, "sulfato_amonio": 33000, "kcl": 77500, "phusion": 2000, "sulfato_mn": 1175, "acido_borico": 2500, "sulfato_zn": 1500}'::jsonb) on conflict (fazenda_app, safra, versao) do nothing;
insert into public.plano_safra (id, fazenda_app, safra, versao, status, motivo, arquivo_origem, criado_por, auditoria_ok, resumo_deck) values ('3b55c314-02b1-58ff-b191-8c38c1616578', 'Monte Carmelo — Café', '2026/27', 1, 'rascunho', 'carga inicial dos PPTX de 2026/27', 'MC_Caxico__NC_NAVES_safra_26_27.pptx', 'seed v52 (gerar_seed_plano.py)', false, '{"ureia": 65500, "nitrato": 268000, "sulfato_amonio": 122500, "kcl": 215000, "phusion": 24500, "sulfato_mn": 4300, "acido_borico": 9150, "sulfato_zn": 5150}'::jsonb) on conflict (fazenda_app, safra, versao) do nothing;
insert into public.plano_safra (id, fazenda_app, safra, versao, status, motivo, arquivo_origem, criado_por, auditoria_ok, resumo_deck) values ('08e5d773-03d4-5e3c-a22a-2b75d766167a', 'Lagamar Café (Rodrigo)', '2026/27', 1, 'rascunho', 'carga inicial dos PPTX de 2026/27', 'NR_Lagamar_safra_26_27.pptx', 'seed v52 (gerar_seed_plano.py)', false, '{"ureia": 48000, "nitrato": 169500, "sulfato_amonio": 76500, "kcl": 109000, "phusion": 0, "sulfato_mn": 2700, "acido_borico": 5800, "sulfato_zn": 3250}'::jsonb) on conflict (fazenda_app, safra, versao) do nothing;
insert into public.plano_safra (id, fazenda_app, safra, versao, status, motivo, arquivo_origem, criado_por, auditoria_ok, resumo_deck) values ('c38db03e-55d9-5cd5-a6d4-95ca186126b5', 'Mata Preta — Café', '2026/27', 1, 'rascunho', 'carga inicial dos PPTX de 2026/27', 'NR_Mata_Preta_safra_26_27.pptx', 'seed v52 (gerar_seed_plano.py)', false, '{"ureia": 30500, "nitrato": 124000, "sulfato_amonio": 57000, "kcl": 86000, "phusion": 9000, "sulfato_mn": 2050, "acido_borico": 4300, "sulfato_zn": 2425}'::jsonb) on conflict (fazenda_app, safra, versao) do nothing;

-- 5. plano_unidade ----------------------------------------------------------
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('cef76739-e882-56ac-8be7-bc599da7808c', 'cea5a300-adcb-57e0-be8f-7a8ff70047b7', 16, 'poda', 16, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('cef76739-e882-56ac-8be7-bc599da7808c', '0d74c8e4-798c-534e-9bd0-838710c38867', 23, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('cef76739-e882-56ac-8be7-bc599da7808c', '077292a8-e8ca-5518-b830-58c7c9478509', 20, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('cef76739-e882-56ac-8be7-bc599da7808c', '51b4ff94-68e2-5bf1-bcf9-3ac595cb7355', 18, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('cef76739-e882-56ac-8be7-bc599da7808c', '922e16bf-e805-5091-bbf8-5d104e3db726', 18, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('cef76739-e882-56ac-8be7-bc599da7808c', '8794ebc3-0652-5321-af14-77cbca328844', 21, 'poda', 11, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('cef76739-e882-56ac-8be7-bc599da7808c', 'd151add8-c2dc-5dd2-82a4-232798ae5be4', 19, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('cef76739-e882-56ac-8be7-bc599da7808c', 'bb9810e0-8608-5e51-85c2-b3c0c64ee499', 59, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('cef76739-e882-56ac-8be7-bc599da7808c', 'c37449fa-8e4d-5dc2-93fc-9a93bc61337d', 14, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('cef76739-e882-56ac-8be7-bc599da7808c', 'be8d4fed-6766-5e34-b303-4ab9bbd18171', 120, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('cef76739-e882-56ac-8be7-bc599da7808c', 'ae05e0a3-12ab-5f6c-a652-656bff7f1003', 53, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', '05444656-96f3-593e-9154-eed917760ba4', 16, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', '9305a42d-8042-53a8-b963-014655eead9e', 16, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', '21c9be63-81e0-5f60-bac8-5779e5852b1e', 16, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', '68b975ed-2dcd-57c1-ab2a-ef1f757f488c', 16, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', 'a0cb7127-3d74-52ad-8cd5-55a1e26f2928', 16, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', '530f38fd-d7e9-5aa7-9163-93572635267c', 19, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', 'faf865cd-664e-5b0b-b35a-dc32ff72d19e', 30, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', '5ae9a8d4-7916-5f01-ad2b-dcf7aa0012f4', 30, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', '4a5f6ffc-385c-5312-8d03-feb7d99aa7a1', 30, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', 'ce3386ac-b315-5910-bb9b-f08fa02759f6', 30, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', 'b1f29351-3db9-5847-94fe-622ab0e449ce', 30, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', '1d3ba683-7a81-5fdc-bc74-cb59d6af8cb2', 30, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3bc4573e-978d-58dd-a97d-26d240b75da5', '83ff034d-ee46-5f43-84fc-b3570b265738', 7, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3bc4573e-978d-58dd-a97d-26d240b75da5', 'b2d9746a-56e0-5520-9a1d-04aec4418429', 14, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3bc4573e-978d-58dd-a97d-26d240b75da5', '321e7e53-05ce-5a3f-bfe8-f1b20e9c4d64', 21, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3bc4573e-978d-58dd-a97d-26d240b75da5', '12dc5936-3cf9-546c-a9c0-08e269fd34b9', 25, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3bc4573e-978d-58dd-a97d-26d240b75da5', '5e5ab1ed-72db-5e2f-af9d-0be644f4e531', 25, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3bc4573e-978d-58dd-a97d-26d240b75da5', 'de2ec3af-d83a-5825-ab6e-5a6faea364a7', 20, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3bc4573e-978d-58dd-a97d-26d240b75da5', '8e4d0c58-9a49-502e-9cbf-a1ac6427cd37', 20, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3bc4573e-978d-58dd-a97d-26d240b75da5', '3a030670-ca55-57f8-8154-8c6e309dcdde', 20, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3bc4573e-978d-58dd-a97d-26d240b75da5', '0ac3ef47-0647-559e-ba94-426854020a00', 12, 'poda', 2, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('d6b4408b-6b1c-5793-ae94-87383995a6fc', '4f82988a-db81-56ad-8f9d-3ff374703b30', 34, 'poda', 34, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('d6b4408b-6b1c-5793-ae94-87383995a6fc', 'f2a64fb7-41dd-5db9-8494-c3a140044061', 23, 'poda', 23, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('d6b4408b-6b1c-5793-ae94-87383995a6fc', '67532357-b28e-5945-9bac-9f1f790aeda3', 22, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('d6b4408b-6b1c-5793-ae94-87383995a6fc', '83da31b8-bc9d-5196-afec-eb837eb67521', 24, 'a_confirmar', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('d6b4408b-6b1c-5793-ae94-87383995a6fc', '38fe974d-7141-53fd-9108-7f6986f70e28', 30, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('8cc75fc4-d102-5f55-952d-e4fb6b86c85a', '9fb0d512-4eb8-579d-ba1a-b493d8b92699', 11, 'poda', 2, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('8cc75fc4-d102-5f55-952d-e4fb6b86c85a', '7a0dcfc7-802c-5935-9cab-8d97b1195404', 24, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('8cc75fc4-d102-5f55-952d-e4fb6b86c85a', 'a0c3c64c-19cd-5773-ba30-ed90ab54a8cc', 24, 'poda', 24, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('8cc75fc4-d102-5f55-952d-e4fb6b86c85a', 'ee998f11-5829-5204-ac4a-4d130b54f202', 11, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('8cc75fc4-d102-5f55-952d-e4fb6b86c85a', '1fb5403f-8001-5fe3-9e07-95e25d23906f', 22, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3b55c314-02b1-58ff-b191-8c38c1616578', 'd5a9be00-bdd8-5330-a596-56d890e33b8c', 27, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3b55c314-02b1-58ff-b191-8c38c1616578', 'a7e4adad-b2f2-5e23-8463-3787bb2652fb', 29, 'a_confirmar', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3b55c314-02b1-58ff-b191-8c38c1616578', '7f41a1b1-7ce0-54f3-aaaf-288e22cb0df1', 27, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3b55c314-02b1-58ff-b191-8c38c1616578', '68659749-f1c4-59d1-b55a-6f3999140911', 15, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3b55c314-02b1-58ff-b191-8c38c1616578', 'd6b5a1ae-a55d-5dd1-b7a7-e7da3cec855c', 15, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3b55c314-02b1-58ff-b191-8c38c1616578', 'e1ccf609-4fa9-50dd-a186-a18cf0abc3bf', 15, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3b55c314-02b1-58ff-b191-8c38c1616578', 'ece1c8fb-a45f-508b-be01-2c7c3ddbe1af', 15, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3b55c314-02b1-58ff-b191-8c38c1616578', '92bbe608-c8b7-546f-8968-c1c002d5373a', 15, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3b55c314-02b1-58ff-b191-8c38c1616578', '66846a44-48cd-5b70-b369-43c45bb73e0f', 15, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3b55c314-02b1-58ff-b191-8c38c1616578', 'dd00abfc-9872-5557-9c8b-988048c9e374', 15, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3b55c314-02b1-58ff-b191-8c38c1616578', 'b34ee153-138e-59ac-a01a-e83272f27443', 15, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3b55c314-02b1-58ff-b191-8c38c1616578', '4e8a2405-f0a5-5a2c-9dc0-b75ae24703c4', 50, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('3b55c314-02b1-58ff-b191-8c38c1616578', '3b27bf08-59be-5113-928d-35b82561f0ce', 25, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('08e5d773-03d4-5e3c-a22a-2b75d766167a', '6bea1c27-7fba-5e9f-a8e3-3f3f6106c916', 24, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('08e5d773-03d4-5e3c-a22a-2b75d766167a', '14d58085-9586-5ded-a32c-343711392423', 24, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('08e5d773-03d4-5e3c-a22a-2b75d766167a', '2dff98c4-b84a-5ee5-87ff-68d61e06e24a', 24, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('08e5d773-03d4-5e3c-a22a-2b75d766167a', '4c511371-72fe-5b55-aa8e-8d2bf4556d50', 21, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('08e5d773-03d4-5e3c-a22a-2b75d766167a', 'e65700e9-2521-575f-9cc1-f758505bf792', 21, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('08e5d773-03d4-5e3c-a22a-2b75d766167a', '4480ebf3-2cd7-5b72-947d-7bc47924b559', 21, 'em_branco', null, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('08e5d773-03d4-5e3c-a22a-2b75d766167a', 'a3273601-419a-5ea5-a9ed-385e506124a3', 26, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('c38db03e-55d9-5cd5-a6d4-95ca186126b5', '11741a30-74ef-55e1-9e5c-6e7587d8ab6d', 19, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('c38db03e-55d9-5cd5-a6d4-95ca186126b5', '6a7ae5ab-b93c-5183-aefb-0cbc27c323e2', 19, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('c38db03e-55d9-5cd5-a6d4-95ca186126b5', '1a67fd03-2921-5347-a427-016d3cfb5a5c', 20, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('c38db03e-55d9-5cd5-a6d4-95ca186126b5', '6797f7f4-63fa-546f-8805-76ff097e1a82', 20, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('c38db03e-55d9-5cd5-a6d4-95ca186126b5', '4e33f057-81de-558a-a5e7-6f17acdb1bc2', 20, null, 0, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('c38db03e-55d9-5cd5-a6d4-95ca186126b5', 'cd1794c9-fb60-5d58-b1b3-08b75a82f9ee', 45, 'plantio', 45, null) on conflict (plano_id, unidade_id) do nothing;
insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) values ('c38db03e-55d9-5cd5-a6d4-95ca186126b5', '2ddaf15a-ea77-573d-9709-0da47cada1d1', null, null, 0, null) on conflict (plano_id, unidade_id) do nothing;

-- 6. plano_adubo_mes (1533 linhas; via = null — não deduzida) ----------------
--    siglas: U=ureia Ni=nitrato SA=sulfato_amonio K=kcl Ph=phusion Mn=sulfato_mn B=acido_borico Zn=sulfato_zn
insert into public.plano_adubo_mes (plano_id, unidade_id, mes, insumo, kg, via, obs)
select p.id, u.id, v.mes, s.insumo, v.kg, null, v.obs from (values
('VEC-S01',9,'U',500,null),
('VEC-S01',9,'K',3000,null),
('VEC-S01',9,'Mn',75,null),
('VEC-S01',9,'B',150,null),
('VEC-S01',9,'Zn',150,null),
('VEC-S01',10,'SA',3000,null),
('VEC-S01',11,'SA',3000,null),
('VEC-S01',11,'K',2000,null),
('VEC-S01',11,'Mn',75,null),
('VEC-S01',11,'B',150,null),
('VEC-S01',11,'Zn',75,null),
('VEC-S01',12,'Ni',4500,null),
('VEC-S01',1,'Ni',4000,null),
('VEC-S01',1,'K',2000,null),
('VEC-S01',1,'Mn',50,null),
('VEC-S01',1,'B',125,null),
('VEC-S01',1,'Zn',75,null),
('VEC-S01',2,'Ni',4000,null),
('VEC-S01',3,'U',500,null),
('VEC-S01',4,'U',500,null),
('VEC-S01',5,'U',500,null),
('VEC-S01',6,'U',500,null),
('VEC-S01',7,'U',500,null),
('VEC-S02',9,'U',1000,null),
('VEC-S02',9,'K',9000,null),
('VEC-S02',9,'Mn',100,null),
('VEC-S02',9,'B',250,null),
('VEC-S02',9,'Zn',150,null),
('VEC-S02',10,'SA',4000,null),
('VEC-S02',11,'SA',4000,null),
('VEC-S02',11,'K',9000,null),
('VEC-S02',11,'Mn',100,null),
('VEC-S02',11,'B',200,null),
('VEC-S02',11,'Zn',100,null),
('VEC-S02',12,'Ni',6000,null),
('VEC-S02',1,'Ni',6000,null),
('VEC-S02',1,'K',3000,null),
('VEC-S02',1,'Mn',100,null),
('VEC-S02',1,'B',200,null),
('VEC-S02',1,'Zn',100,null),
('VEC-S02',2,'Ni',6000,null),
('VEC-S02',3,'U',1000,null),
('VEC-S02',4,'U',1000,null),
('VEC-S02',5,'U',500,null),
('VEC-S02',6,'U',500,null),
('VEC-S02',7,'U',500,null),
('VEC-S03',9,'U',1000,null),
('VEC-S03',9,'K',5000,null),
('VEC-S03',9,'Mn',100,null),
('VEC-S03',9,'B',200,null),
('VEC-S03',9,'Zn',125,null),
('VEC-S03',10,'SA',4000,null),
('VEC-S03',11,'SA',3500,null),
('VEC-S03',11,'Mn',100,null),
('VEC-S03',11,'B',200,null),
('VEC-S03',11,'Zn',100,null),
('VEC-S03',12,'Ni',6500,null),
('VEC-S03',1,'Ni',5000,null),
('VEC-S03',1,'K',5000,null),
('VEC-S03',1,'Mn',50,null),
('VEC-S03',1,'B',200,null),
('VEC-S03',1,'Zn',100,null),
('VEC-S03',2,'Ni',5000,null),
('VEC-S03',3,'U',1000,null),
('VEC-S03',4,'U',500,null),
('VEC-S03',5,'U',500,null),
('VEC-S03',6,'U',500,null),
('VEC-S03',7,'U',500,null),
('VEC-S04',9,'U',1000,null),
('VEC-S04',9,'K',9000,null),
('VEC-S04',9,'Mn',75,null),
('VEC-S04',9,'B',200,null),
('VEC-S04',9,'Zn',150,null),
('VEC-S04',10,'SA',3500,null),
('VEC-S04',11,'SA',3000,null),
('VEC-S04',11,'K',9000,null),
('VEC-S04',11,'Mn',75,null),
('VEC-S04',11,'B',150,null),
('VEC-S04',11,'Zn',125,null),
('VEC-S04',12,'Ni',5000,null),
('VEC-S04',1,'Ni',5000,null),
('VEC-S04',1,'K',3000,null),
('VEC-S04',1,'Mn',75,null),
('VEC-S04',1,'B',150,null),
('VEC-S04',1,'Zn',100,null),
('VEC-S04',2,'Ni',4000,null),
('VEC-S04',3,'U',500,null),
('VEC-S04',4,'U',500,null),
('VEC-S04',5,'U',500,null),
('VEC-S04',6,'U',500,null),
('VEC-S04',7,'U',500,null),
('VEC-S05',9,'U',1000,null),
('VEC-S05',9,'K',8000,null),
('VEC-S05',9,'Mn',100,null),
('VEC-S05',9,'B',200,null),
('VEC-S05',9,'Zn',125,null),
('VEC-S05',10,'SA',4000,null),
('VEC-S05',10,'Ph',3500,null),
('VEC-S05',11,'SA',3500,null),
('VEC-S05',11,'Mn',75,null),
('VEC-S05',11,'B',200,null),
('VEC-S05',11,'Zn',100,null),
('VEC-S05',12,'Ni',6500,null),
('VEC-S05',1,'Ni',5000,null),
('VEC-S05',1,'K',3000,null),
('VEC-S05',1,'Mn',75,null),
('VEC-S05',1,'B',200,null),
('VEC-S05',1,'Zn',100,null),
('VEC-S05',2,'Ni',5000,null),
('VEC-S05',3,'U',1000,null),
('VEC-S05',4,'U',500,null),
('VEC-S05',5,'U',500,null),
('VEC-S05',6,'U',500,null),
('VEC-S05',7,'U',500,null),
('VEC-S06',9,'U',1000,null),
('VEC-S06',9,'K',9000,null),
('VEC-S06',9,'Mn',75,null),
('VEC-S06',9,'B',175,null),
('VEC-S06',9,'Zn',100,null),
('VEC-S06',10,'SA',4000,null),
('VEC-S06',11,'SA',3000,null),
('VEC-S06',11,'K',9000,null),
('VEC-S06',11,'Mn',75,null),
('VEC-S06',11,'B',175,null),
('VEC-S06',11,'Zn',100,null),
('VEC-S06',12,'Ni',5000,null),
('VEC-S06',1,'Ni',5000,null),
('VEC-S06',1,'K',8000,null),
('VEC-S06',1,'Mn',75,null),
('VEC-S06',1,'B',175,null),
('VEC-S06',1,'Zn',100,null),
('VEC-S06',2,'Ni',5000,null),
('VEC-S06',3,'U',500,null),
('VEC-S06',4,'U',500,null),
('VEC-S06',5,'U',500,null),
('VEC-S06',6,'U',500,null),
('VEC-S06',7,'U',500,null),
('VEC-S07',9,'U',1000,null),
('VEC-S07',9,'Mn',75,null),
('VEC-S07',9,'B',175,null),
('VEC-S07',9,'Zn',100,null),
('VEC-S07',10,'SA',4000,null),
('VEC-S07',11,'SA',3000,null),
('VEC-S07',11,'Mn',75,null),
('VEC-S07',11,'B',175,null),
('VEC-S07',11,'Zn',100,null),
('VEC-S07',12,'Ni',5000,null),
('VEC-S07',1,'Ni',5000,null),
('VEC-S07',1,'Mn',75,null),
('VEC-S07',1,'B',175,null),
('VEC-S07',1,'Zn',100,null),
('VEC-S07',2,'Ni',5000,null),
('VEC-S07',3,'U',500,null),
('VEC-S07',4,'U',500,null),
('VEC-S07',5,'U',500,null),
('VEC-S07',6,'U',500,null),
('VEC-S07',7,'U',500,null),
('VEC-S08',9,'U',2000,null),
('VEC-S08',9,'K',19000,null),
('VEC-S08',9,'Mn',250,null),
('VEC-S08',9,'B',550,null),
('VEC-S08',9,'Zn',300,null),
('VEC-S08',10,'SA',21000,null),
('VEC-S08',11,'SA',21000,null),
('VEC-S08',11,'K',19000,null),
('VEC-S08',11,'Mn',250,null),
('VEC-S08',11,'B',550,null),
('VEC-S08',11,'Zn',300,null),
('VEC-S08',12,'Ni',16000,null),
('VEC-S08',1,'Ni',16000,null),
('VEC-S08',1,'K',18000,null),
('VEC-S08',1,'Mn',200,null),
('VEC-S08',1,'B',500,null),
('VEC-S08',1,'Zn',300,null),
('VEC-S08',2,'Ni',14500,null),
('VEC-S08',3,'U',2000,null),
('VEC-S08',4,'U',2000,null),
('VEC-S08',5,'U',2000,null),
('VEC-S08',6,'U',2000,null),
('VEC-S08',7,'U',1000,null),
('VEC-S09',9,'K',7000,null),
('VEC-S09',9,'Mn',75,null),
('VEC-S09',9,'B',150,null),
('VEC-S09',9,'Zn',75,null),
('VEC-S09',10,'SA',4000,null),
('VEC-S09',11,'SA',4000,null),
('VEC-S09',11,'K',7000,null),
('VEC-S09',11,'Mn',75,null),
('VEC-S09',11,'B',150,null),
('VEC-S09',11,'Zn',75,null),
('VEC-S09',12,'Ni',4000,null),
('VEC-S09',1,'Ni',4000,null),
('VEC-S09',1,'K',4000,null),
('VEC-S09',1,'Mn',50,null),
('VEC-S09',1,'B',100,null),
('VEC-S09',1,'Zn',75,null),
('VEC-S09',2,'Ni',4000,null),
('VEC-P02',9,'U',4000,null),
('VEC-P02',9,'K',60000,null),
('VEC-P02',9,'Mn',500,null),
('VEC-P02',9,'B',1150,null),
('VEC-P02',9,'Zn',650,null),
('VEC-P02',10,'SA',25000,null),
('VEC-P02',11,'SA',20000,null),
('VEC-P02',11,'K',60000,null),
('VEC-P02',11,'Mn',500,null),
('VEC-P02',11,'B',1100,null),
('VEC-P02',11,'Zn',650,null),
('VEC-P02',12,'Ni',33000,null),
('VEC-P02',1,'Ni',33000,null),
('VEC-P02',1,'K',24000,null),
('VEC-P02',1,'Mn',500,null),
('VEC-P02',1,'B',1100,null),
('VEC-P02',1,'Zn',600,null),
('VEC-P02',2,'Ni',33000,null),
('VEC-P02',3,'U',4000,null),
('VEC-P02',4,'U',4000,null),
('VEC-P02',5,'U',4000,null),
('VEC-P02',6,'U',4000,null),
('VEC-P02',7,'U',4000,null),
('VEC-P06',9,'U',2000,null),
('VEC-P06',9,'K',22000,null),
('VEC-P06',9,'Mn',225,null),
('VEC-P06',9,'B',500,null),
('VEC-P06',9,'Zn',275,null),
('VEC-P06',10,'SA',10000,null),
('VEC-P06',11,'SA',9000,null),
('VEC-P06',11,'K',22000,null),
('VEC-P06',11,'Mn',200,null),
('VEC-P06',11,'B',500,null),
('VEC-P06',11,'Zn',275,null),
('VEC-P06',12,'Ni',14000,null),
('VEC-P06',1,'Ni',14000,null),
('VEC-P06',1,'K',11000,null),
('VEC-P06',1,'Mn',200,null),
('VEC-P06',1,'B',450,null),
('VEC-P06',1,'Zn',275,null),
('VEC-P06',2,'Ni',13000,null),
('VEC-P06',3,'U',2000,null),
('VEC-P06',4,'U',2000,null),
('VEC-P06',5,'U',2000,null),
('VEC-P06',6,'U',1000,null),
('VEC-P06',7,'U',1000,null),
('RPL-1P-S01',9,'U',1000,null),
('RPL-1P-S01',9,'K',7000,null),
('RPL-1P-S01',9,'Mn',100,null),
('RPL-1P-S01',9,'B',200,null),
('RPL-1P-S01',9,'Zn',125,null),
('RPL-1P-S01',10,'SA',4000,null),
('RPL-1P-S01',11,'SA',4000,null),
('RPL-1P-S01',11,'K',7000,null),
('RPL-1P-S01',11,'Mn',100,null),
('RPL-1P-S01',11,'B',200,null),
('RPL-1P-S01',11,'Zn',125,null),
('RPL-1P-S01',12,'Ni',6000,null),
('RPL-1P-S01',1,'Ni',6000,null),
('RPL-1P-S01',1,'K',4000,null),
('RPL-1P-S01',1,'Mn',75,null),
('RPL-1P-S01',1,'B',200,null),
('RPL-1P-S01',1,'Zn',100,null),
('RPL-1P-S01',2,'Ni',5500,null),
('RPL-1P-S01',3,'U',1000,null),
('RPL-1P-S01',4,'U',1000,null),
('RPL-1P-S01',5,'U',500,null),
('RPL-1P-S01',6,'U',500,null),
('RPL-1P-S01',7,'U',500,null),
('RPL-1P-S02',9,'U',1000,null),
('RPL-1P-S02',9,'K',7000,null),
('RPL-1P-S02',9,'Mn',100,null),
('RPL-1P-S02',9,'B',200,null),
('RPL-1P-S02',9,'Zn',125,null),
('RPL-1P-S02',10,'SA',4000,null),
('RPL-1P-S02',11,'SA',4000,null),
('RPL-1P-S02',11,'K',7000,null),
('RPL-1P-S02',11,'Mn',100,null),
('RPL-1P-S02',11,'B',200,null),
('RPL-1P-S02',11,'Zn',125,null),
('RPL-1P-S02',12,'Ni',6000,null),
('RPL-1P-S02',1,'Ni',6000,null),
('RPL-1P-S02',1,'K',4000,null),
('RPL-1P-S02',1,'Mn',75,null),
('RPL-1P-S02',1,'B',200,null),
('RPL-1P-S02',1,'Zn',100,null),
('RPL-1P-S02',2,'Ni',5500,null),
('RPL-1P-S02',3,'U',1000,null),
('RPL-1P-S02',4,'U',1000,null),
('RPL-1P-S02',5,'U',500,null),
('RPL-1P-S02',6,'U',500,null),
('RPL-1P-S02',7,'U',500,null),
('RPL-1P-S03',9,'U',1000,null),
('RPL-1P-S03',9,'K',7000,null),
('RPL-1P-S03',9,'Mn',100,null),
('RPL-1P-S03',9,'B',200,null),
('RPL-1P-S03',9,'Zn',125,null),
('RPL-1P-S03',10,'SA',4000,null),
('RPL-1P-S03',11,'SA',4000,null),
('RPL-1P-S03',11,'K',7000,null),
('RPL-1P-S03',11,'Mn',100,null),
('RPL-1P-S03',11,'B',200,null),
('RPL-1P-S03',11,'Zn',125,null),
('RPL-1P-S03',12,'Ni',6000,null),
('RPL-1P-S03',1,'Ni',6000,null),
('RPL-1P-S03',1,'K',4000,null),
('RPL-1P-S03',1,'Mn',75,null),
('RPL-1P-S03',1,'B',200,null),
('RPL-1P-S03',1,'Zn',100,null),
('RPL-1P-S03',2,'Ni',5500,null),
('RPL-1P-S03',3,'U',1000,null),
('RPL-1P-S03',4,'U',1000,null),
('RPL-1P-S03',5,'U',500,null),
('RPL-1P-S03',6,'U',500,null),
('RPL-1P-S03',7,'U',500,null),
('RPL-1P-S04',9,'U',1000,null),
('RPL-1P-S04',9,'K',6000,null),
('RPL-1P-S04',9,'Mn',100,null),
('RPL-1P-S04',9,'B',200,null),
('RPL-1P-S04',9,'Zn',125,null),
('RPL-1P-S04',10,'SA',4000,null),
('RPL-1P-S04',11,'SA',4000,null),
('RPL-1P-S04',11,'K',6000,null),
('RPL-1P-S04',11,'Mn',100,null),
('RPL-1P-S04',11,'B',200,null),
('RPL-1P-S04',11,'Zn',125,null),
('RPL-1P-S04',12,'Ni',6000,null),
('RPL-1P-S04',1,'Ni',6000,null),
('RPL-1P-S04',1,'K',3000,null),
('RPL-1P-S04',1,'Mn',75,null),
('RPL-1P-S04',1,'B',200,null),
('RPL-1P-S04',1,'Zn',100,null),
('RPL-1P-S04',2,'Ni',5500,null),
('RPL-1P-S04',3,'U',1000,null),
('RPL-1P-S04',4,'U',1000,null),
('RPL-1P-S04',5,'U',500,null),
('RPL-1P-S04',6,'U',500,null),
('RPL-1P-S04',7,'U',500,null),
('RPL-1P-S05',9,'U',1000,null),
('RPL-1P-S05',9,'K',6000,null),
('RPL-1P-S05',9,'Mn',100,null),
('RPL-1P-S05',9,'B',200,null),
('RPL-1P-S05',9,'Zn',125,null),
('RPL-1P-S05',10,'SA',4000,null),
('RPL-1P-S05',11,'SA',4000,null),
('RPL-1P-S05',11,'K',6000,null),
('RPL-1P-S05',11,'Mn',100,null),
('RPL-1P-S05',11,'B',200,null),
('RPL-1P-S05',11,'Zn',125,null),
('RPL-1P-S05',12,'Ni',6000,null),
('RPL-1P-S05',1,'Ni',6000,null),
('RPL-1P-S05',1,'K',3000,null),
('RPL-1P-S05',1,'Mn',75,null),
('RPL-1P-S05',1,'B',200,null),
('RPL-1P-S05',1,'Zn',100,null),
('RPL-1P-S05',2,'Ni',5500,null),
('RPL-1P-S05',3,'U',1000,null),
('RPL-1P-S05',4,'U',1000,null),
('RPL-1P-S05',5,'U',500,null),
('RPL-1P-S05',6,'U',500,null),
('RPL-1P-S05',7,'U',500,null),
('RPL-1P-S06',9,'U',1000,null),
('RPL-1P-S06',9,'K',9000,null),
('RPL-1P-S06',9,'Mn',125,null),
('RPL-1P-S06',9,'B',250,null),
('RPL-1P-S06',9,'Zn',150,null),
('RPL-1P-S06',10,'SA',5000,null),
('RPL-1P-S06',11,'SA',5000,null),
('RPL-1P-S06',11,'K',9000,null),
('RPL-1P-S06',11,'Mn',125,null),
('RPL-1P-S06',11,'B',250,null),
('RPL-1P-S06',11,'Zn',150,null),
('RPL-1P-S06',12,'Ni',8000,null),
('RPL-1P-S06',1,'Ni',7000,null),
('RPL-1P-S06',1,'K',6000,null),
('RPL-1P-S06',1,'Mn',100,null),
('RPL-1P-S06',1,'B',250,null),
('RPL-1P-S06',1,'Zn',125,null),
('RPL-1P-S06',2,'Ni',7000,null),
('RPL-1P-S06',3,'U',1000,null),
('RPL-1P-S06',4,'U',1000,null),
('RPL-1P-S06',5,'U',1000,null),
('RPL-1P-S06',6,'U',1000,null),
('RPL-1P-S06',7,'U',500,null),
('RPL-2P-S01',9,'U',1000,null),
('RPL-2P-S01',9,'K',3000,null),
('RPL-2P-S01',9,'Mn',100,null),
('RPL-2P-S01',9,'B',225,null),
('RPL-2P-S01',9,'Zn',125,null),
('RPL-2P-S01',10,'SA',4500,null),
('RPL-2P-S01',11,'SA',4000,null),
('RPL-2P-S01',11,'K',2000,null),
('RPL-2P-S01',11,'Mn',100,null),
('RPL-2P-S01',11,'B',225,null),
('RPL-2P-S01',11,'Zn',125,null),
('RPL-2P-S01',12,'Ni',7000,null),
('RPL-2P-S01',1,'Ni',6000,null),
('RPL-2P-S01',1,'K',2000,null),
('RPL-2P-S01',1,'Mn',100,null),
('RPL-2P-S01',1,'B',200,null),
('RPL-2P-S01',1,'Zn',125,null),
('RPL-2P-S01',2,'Ni',6000,null),
('RPL-2P-S01',3,'U',1000,null)
) as v(codigo, mes, sg, kg, obs)
join (values ('U','ureia'),('Ni','nitrato'),('SA','sulfato_amonio'),('K','kcl'),('Ph','phusion'),('Mn','sulfato_mn'),('B','acido_borico'),('Zn','sulfato_zn')) as s(sg, insumo) on s.sg = v.sg
join public.unidade_manejo u on u.codigo = v.codigo
join public.plano_safra p on p.fazenda_app = u.fazenda_app and p.safra = '2026/27' and p.versao = 1
on conflict (plano_id, unidade_id, mes, insumo) do nothing;
insert into public.plano_adubo_mes (plano_id, unidade_id, mes, insumo, kg, via, obs)
select p.id, u.id, v.mes, s.insumo, v.kg, null, v.obs from (values
('RPL-2P-S01',4,'U',1000,null),
('RPL-2P-S01',5,'U',500,null),
('RPL-2P-S01',6,'U',500,null),
('RPL-2P-S01',7,'U',500,null),
('RPL-2P-S02',9,'U',1000,null),
('RPL-2P-S02',9,'K',3000,null),
('RPL-2P-S02',9,'Mn',100,null),
('RPL-2P-S02',9,'B',225,null),
('RPL-2P-S02',9,'Zn',125,null),
('RPL-2P-S02',10,'SA',4500,null),
('RPL-2P-S02',11,'SA',4000,null),
('RPL-2P-S02',11,'K',2000,null),
('RPL-2P-S02',11,'Mn',100,null),
('RPL-2P-S02',11,'B',225,null),
('RPL-2P-S02',11,'Zn',125,null),
('RPL-2P-S02',12,'Ni',7000,null),
('RPL-2P-S02',1,'Ni',6000,null),
('RPL-2P-S02',1,'K',2000,null),
('RPL-2P-S02',1,'Mn',100,null),
('RPL-2P-S02',1,'B',200,null),
('RPL-2P-S02',1,'Zn',125,null),
('RPL-2P-S02',2,'Ni',6000,null),
('RPL-2P-S02',3,'U',1000,null),
('RPL-2P-S02',4,'U',1000,null),
('RPL-2P-S02',5,'U',500,null),
('RPL-2P-S02',6,'U',500,null),
('RPL-2P-S02',7,'U',500,null),
('RPL-2P-S03',9,'U',1000,null),
('RPL-2P-S03',9,'K',3000,null),
('RPL-2P-S03',9,'Mn',100,null),
('RPL-2P-S03',9,'B',225,null),
('RPL-2P-S03',9,'Zn',125,null),
('RPL-2P-S03',10,'SA',4500,null),
('RPL-2P-S03',11,'SA',4000,null),
('RPL-2P-S03',11,'K',2000,null),
('RPL-2P-S03',11,'Mn',100,null),
('RPL-2P-S03',11,'B',225,null),
('RPL-2P-S03',11,'Zn',125,null),
('RPL-2P-S03',12,'Ni',7000,null),
('RPL-2P-S03',1,'Ni',6000,null),
('RPL-2P-S03',1,'K',2000,null),
('RPL-2P-S03',1,'Mn',100,null),
('RPL-2P-S03',1,'B',200,null),
('RPL-2P-S03',1,'Zn',125,null),
('RPL-2P-S03',2,'Ni',6000,null),
('RPL-2P-S03',3,'U',1000,null),
('RPL-2P-S03',4,'U',1000,null),
('RPL-2P-S03',5,'U',500,null),
('RPL-2P-S03',6,'U',500,null),
('RPL-2P-S03',7,'U',500,null),
('RPL-2P-S04',9,'U',1000,null),
('RPL-2P-S04',9,'K',3000,null),
('RPL-2P-S04',9,'Mn',100,null),
('RPL-2P-S04',9,'B',225,null),
('RPL-2P-S04',9,'Zn',125,null),
('RPL-2P-S04',10,'SA',4500,null),
('RPL-2P-S04',11,'SA',4000,null),
('RPL-2P-S04',11,'K',2000,null),
('RPL-2P-S04',11,'Mn',100,null),
('RPL-2P-S04',11,'B',225,null),
('RPL-2P-S04',11,'Zn',125,null),
('RPL-2P-S04',12,'Ni',7000,null),
('RPL-2P-S04',1,'Ni',6000,null),
('RPL-2P-S04',1,'K',2000,null),
('RPL-2P-S04',1,'Mn',100,null),
('RPL-2P-S04',1,'B',200,null),
('RPL-2P-S04',1,'Zn',125,null),
('RPL-2P-S04',2,'Ni',6000,null),
('RPL-2P-S04',3,'U',1000,null),
('RPL-2P-S04',4,'U',1000,null),
('RPL-2P-S04',5,'U',500,null),
('RPL-2P-S04',6,'U',500,null),
('RPL-2P-S04',7,'U',500,null),
('RPL-2P-S05',9,'U',1000,null),
('RPL-2P-S05',9,'K',3000,null),
('RPL-2P-S05',9,'Mn',100,null),
('RPL-2P-S05',9,'B',225,null),
('RPL-2P-S05',9,'Zn',125,null),
('RPL-2P-S05',10,'SA',4500,null),
('RPL-2P-S05',11,'SA',4000,null),
('RPL-2P-S05',11,'K',2000,null),
('RPL-2P-S05',11,'Mn',100,null),
('RPL-2P-S05',11,'B',225,null),
('RPL-2P-S05',11,'Zn',125,null),
('RPL-2P-S05',12,'Ni',7000,null),
('RPL-2P-S05',1,'Ni',6000,null),
('RPL-2P-S05',1,'K',2000,null),
('RPL-2P-S05',1,'Mn',100,null),
('RPL-2P-S05',1,'B',200,null),
('RPL-2P-S05',1,'Zn',125,null),
('RPL-2P-S05',2,'Ni',6000,null),
('RPL-2P-S05',3,'U',1000,null),
('RPL-2P-S05',4,'U',1000,null),
('RPL-2P-S05',5,'U',500,null),
('RPL-2P-S05',6,'U',500,null),
('RPL-2P-S05',7,'U',500,null),
('RPL-2P-S06',9,'U',1000,null),
('RPL-2P-S06',9,'K',3000,null),
('RPL-2P-S06',9,'Mn',100,null),
('RPL-2P-S06',9,'B',225,null),
('RPL-2P-S06',9,'Zn',125,null),
('RPL-2P-S06',10,'SA',4500,null),
('RPL-2P-S06',11,'SA',4000,null),
('RPL-2P-S06',11,'K',2000,null),
('RPL-2P-S06',11,'Mn',100,null),
('RPL-2P-S06',11,'B',225,null),
('RPL-2P-S06',11,'Zn',125,null),
('RPL-2P-S06',12,'Ni',7000,null),
('RPL-2P-S06',1,'Ni',6000,null),
('RPL-2P-S06',1,'K',2000,null),
('RPL-2P-S06',1,'Mn',100,null),
('RPL-2P-S06',1,'B',200,null),
('RPL-2P-S06',1,'Zn',125,null),
('RPL-2P-S06',2,'Ni',6000,null),
('RPL-2P-S06',3,'U',1000,null),
('RPL-2P-S06',4,'U',1000,null),
('RPL-2P-S06',5,'U',500,null),
('RPL-2P-S06',6,'U',500,null),
('RPL-2P-S06',7,'U',500,null),
('ROM-S01',9,'U',1000,null),
('ROM-S01',9,'K',11000,null),
('ROM-S01',9,'Mn',125,null),
('ROM-S01',9,'B',300,null),
('ROM-S01',9,'Zn',150,null),
('ROM-S01',10,'SA',5000,null),
('ROM-S01',10,'Ph',4500,'4500 no café 2º'),
('ROM-S01',11,'SA',5000,null),
('ROM-S01',11,'K',11000,null),
('ROM-S01',11,'Mn',125,null),
('ROM-S01',11,'B',300,null),
('ROM-S01',11,'Zn',150,null),
('ROM-S01',12,'Ni',8000,null),
('ROM-S01',1,'Ni',7000,null),
('ROM-S01',1,'K',6000,null),
('ROM-S01',1,'Mn',100,null),
('ROM-S01',1,'B',200,null),
('ROM-S01',1,'Zn',150,null),
('ROM-S01',2,'Ni',7000,null),
('ROM-S01',3,'U',1000,null),
('ROM-S01',4,'U',1000,null),
('ROM-S01',5,'U',1000,null),
('ROM-S01',6,'U',1000,null),
('ROM-S01',7,'U',500,null),
('ROM-S02',9,'U',1000,null),
('ROM-S02',9,'K',10000,null),
('ROM-S02',9,'Mn',100,null),
('ROM-S02',9,'B',200,null),
('ROM-S02',9,'Zn',100,null),
('ROM-S02',10,'SA',4000,null),
('ROM-S02',11,'SA',3000,null),
('ROM-S02',11,'K',10000,null),
('ROM-S02',11,'Mn',75,null),
('ROM-S02',11,'B',200,null),
('ROM-S02',11,'Zn',100,null),
('ROM-S02',12,'Ni',6000,null),
('ROM-S02',1,'Ni',5000,null),
('ROM-S02',1,'K',5000,null),
('ROM-S02',1,'Mn',75,null),
('ROM-S02',1,'B',200,null),
('ROM-S02',1,'Zn',100,null),
('ROM-S02',2,'Ni',5000,null),
('ROM-S02',3,'U',1000,null),
('ROM-S02',4,'U',500,null),
('ROM-S02',5,'U',500,null),
('ROM-S02',6,'U',500,null),
('ROM-S02',7,'U',500,null),
('ROM-S03',9,'U',1000,null),
('ROM-S03',9,'K',9000,null),
('ROM-S03',9,'Mn',100,null),
('ROM-S03',9,'B',250,null),
('ROM-S03',9,'Zn',125,null),
('ROM-S03',10,'SA',5000,null),
('ROM-S03',11,'SA',4000,null),
('ROM-S03',11,'K',9000,null),
('ROM-S03',11,'Mn',100,null),
('ROM-S03',11,'B',250,null),
('ROM-S03',11,'Zn',125,null),
('ROM-S03',12,'Ni',7000,null),
('ROM-S03',1,'Ni',7000,null),
('ROM-S03',1,'K',5000,null),
('ROM-S03',1,'Mn',100,null),
('ROM-S03',1,'B',200,null),
('ROM-S03',1,'Zn',125,null),
('ROM-S03',2,'Ni',6000,null),
('ROM-S03',3,'U',1000,null),
('ROM-S03',4,'U',1000,null),
('ROM-S03',5,'U',1000,null),
('ROM-S03',6,'U',500,null),
('ROM-S03',7,'U',500,null),
('ROM-S04',9,'U',1000,null),
('ROM-S04',9,'K',10000,null),
('ROM-S04',9,'Mn',100,null),
('ROM-S04',9,'B',250,null),
('ROM-S04',9,'Zn',125,null),
('ROM-S04',10,'SA',5000,null),
('ROM-S04',11,'SA',4000,null),
('ROM-S04',11,'K',10000,null),
('ROM-S04',11,'Mn',100,null),
('ROM-S04',11,'B',250,null),
('ROM-S04',11,'Zn',125,null),
('ROM-S04',12,'Ni',7000,null),
('ROM-S04',1,'Ni',7000,null),
('ROM-S04',1,'K',5000,null),
('ROM-S04',1,'Mn',100,null),
('ROM-S04',1,'B',200,null),
('ROM-S04',1,'Zn',125,null),
('ROM-S04',2,'Ni',6000,null),
('ROM-S04',3,'U',1000,null),
('ROM-S04',4,'U',1000,null),
('ROM-S04',5,'U',1000,null),
('ROM-S04',6,'U',500,null),
('ROM-S04',7,'U',500,null),
('ROM-S05',9,'U',1000,null),
('ROM-S05',9,'K',10000,null),
('ROM-S05',9,'Mn',100,null),
('ROM-S05',9,'B',200,null),
('ROM-S05',9,'Zn',100,null),
('ROM-S05',10,'SA',4000,null),
('ROM-S05',11,'SA',3000,null),
('ROM-S05',11,'K',10000,null),
('ROM-S05',11,'Mn',100,null),
('ROM-S05',11,'B',200,null),
('ROM-S05',11,'Zn',100,null),
('ROM-S05',12,'Ni',6000,null),
('ROM-S05',1,'Ni',5000,null),
('ROM-S05',1,'K',5000,null),
('ROM-S05',1,'Mn',50,null),
('ROM-S05',1,'B',200,null),
('ROM-S05',1,'Zn',100,null),
('ROM-S05',2,'Ni',5000,null),
('ROM-S05',3,'U',1000,null),
('ROM-S05',4,'U',500,null),
('ROM-S05',5,'U',500,null),
('ROM-S05',6,'U',500,null),
('ROM-S05',7,'U',500,null),
('ROM-S06',9,'U',1000,null),
('ROM-S06',9,'K',8000,null),
('ROM-S06',9,'Mn',100,null),
('ROM-S06',9,'B',200,null),
('ROM-S06',9,'Zn',100,null),
('ROM-S06',10,'SA',4000,null),
('ROM-S06',11,'SA',3000,null),
('ROM-S06',11,'K',8000,null),
('ROM-S06',11,'Mn',100,null),
('ROM-S06',11,'B',200,null),
('ROM-S06',11,'Zn',100,null),
('ROM-S06',12,'Ni',6000,null),
('ROM-S06',1,'Ni',5000,null),
('ROM-S06',1,'K',5000,null),
('ROM-S06',1,'Mn',50,null),
('ROM-S06',1,'B',200,null),
('ROM-S06',1,'Zn',100,null),
('ROM-S06',2,'Ni',5000,null),
('ROM-S06',3,'U',1000,null),
('ROM-S06',4,'U',500,null),
('ROM-S06',5,'U',500,null),
('ROM-S06',6,'U',500,null),
('ROM-S06',7,'U',500,null),
('ROM-S07',9,'U',1000,null),
('ROM-S07',9,'K',7000,null),
('ROM-S07',9,'Mn',100,null),
('ROM-S07',9,'B',200,null),
('ROM-S07',9,'Zn',100,null),
('ROM-S07',10,'SA',4000,null),
('ROM-S07',11,'SA',3000,null),
('ROM-S07',11,'K',7000,null),
('ROM-S07',11,'Mn',100,null),
('ROM-S07',11,'B',200,null),
('ROM-S07',11,'Zn',100,null),
('ROM-S07',12,'Ni',6000,null),
('ROM-S07',1,'Ni',5000,null),
('ROM-S07',1,'K',5000,null),
('ROM-S07',1,'Mn',50,null),
('ROM-S07',1,'B',200,null),
('ROM-S07',1,'Zn',100,null),
('ROM-S07',2,'Ni',5000,null),
('ROM-S07',3,'U',1000,null),
('ROM-S07',4,'U',500,null),
('ROM-S07',5,'U',500,null),
('ROM-S07',6,'U',500,null),
('ROM-S07',7,'U',500,null),
('ROM-S08',9,'U',500,null),
('ROM-S08',9,'K',4000,null),
('ROM-S08',9,'Mn',50,null),
('ROM-S08',9,'B',125,null),
('ROM-S08',9,'Zn',75,null),
('ROM-S08',10,'SA',2500,null),
('ROM-S08',11,'SA',2000,null),
('ROM-S08',11,'K',4000,null),
('ROM-S08',11,'Mn',50,null),
('ROM-S08',11,'B',125,null),
('ROM-S08',11,'Zn',75,null),
('ROM-S08',12,'Ni',4000,null),
('ROM-S08',1,'Ni',3000,null),
('ROM-S08',1,'K',3000,null),
('ROM-S08',1,'Mn',50,null),
('ROM-S08',1,'B',100,null),
('ROM-S08',1,'Zn',50,null),
('ROM-S08',2,'Ni',3000,null),
('ROM-S08',3,'U',500,null),
('ROM-S08',4,'U',500,null),
('ROM-S08',5,'U',500,null),
('ROM-S08',6,'U',500,null),
('ROM-S08',7,'U',500,null),
('V56-5PA',9,'U',1000,null),
('V56-5PA',9,'K',7000,null),
('V56-5PA',9,'Mn',150,null),
('V56-5PA',9,'B',300,null),
('V56-5PA',9,'Zn',200,null),
('V56-5PA',10,'SA',6000,null),
('V56-5PA',11,'SA',6000,null),
('V56-5PA',11,'K',7000,null),
('V56-5PA',11,'Mn',150,null),
('V56-5PA',11,'B',300,null),
('V56-5PA',11,'Zn',150,null),
('V56-5PA',12,'Ni',9000,null),
('V56-5PA',1,'Ni',9000,null),
('V56-5PA',1,'K',6000,null),
('V56-5PA',1,'Mn',100,null),
('V56-5PA',1,'B',300,null),
('V56-5PA',1,'Zn',150,null),
('V56-5PA',2,'Ni',8000,null),
('V56-5PA',3,'U',1000,null),
('V56-5PA',4,'U',1000,null),
('V56-5PA',5,'U',1000,null),
('V56-5PA',6,'U',1000,null),
('V56-5PA',7,'U',1000,null),
('V56-5CA',9,'U',1000,null),
('V56-5CA',9,'K',7000,null),
('V56-5CA',9,'Mn',100,null),
('V56-5CA',9,'B',200,null),
('V56-5CA',9,'Zn',125,null),
('V56-5CA',10,'SA',4000,null),
('V56-5CA',11,'SA',4000,null),
('V56-5CA',11,'K',7000,null),
('V56-5CA',11,'Mn',100,null),
('V56-5CA',11,'B',200,null),
('V56-5CA',11,'Zn',125,null),
('V56-5CA',12,'Ni',6000,null),
('V56-5CA',1,'Ni',6000,null),
('V56-5CA',1,'K',7000,null),
('V56-5CA',1,'Mn',75,null),
('V56-5CA',1,'B',200,null),
('V56-5CA',1,'Zn',100,null),
('V56-5CA',2,'Ni',5500,null),
('V56-5CA',3,'U',1000,null),
('V56-5CA',4,'U',500,null),
('V56-5CA',5,'U',500,null),
('V56-5CA',6,'U',500,null),
('V56-5CA',7,'U',500,null),
('V56-5BX',9,'U',1000,null),
('V56-5BX',9,'K',8000,null),
('V56-5BX',9,'Mn',100,null),
('V56-5BX',9,'B',200,null),
('V56-5BX',9,'Zn',125,null),
('V56-5BX',10,'SA',4000,null),
('V56-5BX',11,'SA',4000,null),
('V56-5BX',11,'K',7000,null),
('V56-5BX',11,'Mn',100,null),
('V56-5BX',11,'B',200,null),
('V56-5BX',11,'Zn',125,null),
('V56-5BX',12,'Ni',6000,null),
('V56-5BX',1,'Ni',6000,null),
('V56-5BX',1,'K',7000,null),
('V56-5BX',1,'Mn',75,null),
('V56-5BX',1,'B',200,null),
('V56-5BX',1,'Zn',100,null),
('V56-5BX',2,'Ni',5500,null),
('V56-5BX',3,'U',1000,null),
('V56-5BX',4,'U',500,null),
('V56-5BX',5,'U',500,null),
('V56-5BX',6,'U',500,null),
('V56-5BX',7,'U',500,null),
('V56-6MN',9,'U',1000,null),
('V56-6MN',9,'K',2000,null),
('V56-6MN',9,'Mn',100,null),
('V56-6MN',9,'B',200,null),
('V56-6MN',9,'Zn',100,null),
('V56-6MN',10,'SA',4000,null),
('V56-6MN',11,'SA',3000,null),
('V56-6MN',11,'K',2000,null),
('V56-6MN',11,'Mn',75,null),
('V56-6MN',11,'B',200,null),
('V56-6MN',11,'Zn',100,null),
('V56-6MN',12,'Ni',6000,null),
('V56-6MN',1,'Ni',5000,null),
('V56-6MN',1,'K',2000,null),
('V56-6MN',1,'Mn',75,null),
('V56-6MN',1,'B',200,null),
('V56-6MN',1,'Zn',100,null),
('V56-6MN',2,'Ni',5000,null),
('V56-6MN',3,'U',1000,null),
('V56-6MN',4,'U',500,null),
('V56-6MN',5,'U',500,null),
('V56-6MN',6,'U',500,null),
('V56-6MN',7,'U',500,null),
('V56-6IPR',9,'U',1000,null),
('V56-6IPR',9,'K',8000,null),
('V56-6IPR',9,'Mn',125,null),
('V56-6IPR',9,'B',300,null)
) as v(codigo, mes, sg, kg, obs)
join (values ('U','ureia'),('Ni','nitrato'),('SA','sulfato_amonio'),('K','kcl'),('Ph','phusion'),('Mn','sulfato_mn'),('B','acido_borico'),('Zn','sulfato_zn')) as s(sg, insumo) on s.sg = v.sg
join public.unidade_manejo u on u.codigo = v.codigo
join public.plano_safra p on p.fazenda_app = u.fazenda_app and p.safra = '2026/27' and p.versao = 1
on conflict (plano_id, unidade_id, mes, insumo) do nothing;
insert into public.plano_adubo_mes (plano_id, unidade_id, mes, insumo, kg, via, obs)
select p.id, u.id, v.mes, s.insumo, v.kg, null, v.obs from (values
('V56-6IPR',9,'Zn',150,null),
('V56-6IPR',10,'SA',5500,null),
('V56-6IPR',11,'SA',5000,null),
('V56-6IPR',11,'K',7000,null),
('V56-6IPR',11,'Mn',125,null),
('V56-6IPR',11,'B',300,null),
('V56-6IPR',11,'Zn',150,null),
('V56-6IPR',12,'Ni',8000,null),
('V56-6IPR',1,'Ni',8000,null),
('V56-6IPR',1,'K',7000,null),
('V56-6IPR',1,'Mn',100,null),
('V56-6IPR',1,'B',200,null),
('V56-6IPR',1,'Zn',150,null),
('V56-6IPR',2,'Ni',8000,null),
('V56-6IPR',3,'U',1000,null),
('V56-6IPR',4,'U',1000,null),
('V56-6IPR',5,'U',1000,null),
('V56-6IPR',6,'U',1000,null),
('V56-6IPR',7,'U',500,null),
('AGL-T1',9,'U',500,null),
('AGL-T1',9,'K',3000,null),
('AGL-T1',9,'Ph',1000,null),
('AGL-T1',9,'Mn',50,null),
('AGL-T1',9,'B',100,null),
('AGL-T1',9,'Zn',75,null),
('AGL-T1',10,'SA',2000,null),
('AGL-T1',11,'SA',2000,null),
('AGL-T1',11,'K',3000,null),
('AGL-T1',11,'Mn',50,null),
('AGL-T1',11,'B',100,null),
('AGL-T1',11,'Zn',50,null),
('AGL-T1',12,'Ni',3000,null),
('AGL-T1',1,'Ni',3000,null),
('AGL-T1',1,'K',2500,null),
('AGL-T1',1,'Mn',50,null),
('AGL-T1',1,'B',100,null),
('AGL-T1',1,'Zn',50,null),
('AGL-T1',2,'Ni',3000,null),
('AGL-T1',3,'U',500,null),
('AGL-T1',4,'U',250,null),
('AGL-T1',5,'U',250,null),
('AGL-T1',6,'U',250,null),
('AGL-T1',7,'U',250,null),
('AGL-T2B',9,'U',1000,null),
('AGL-T2B',9,'K',10000,null),
('AGL-T2B',9,'Mn',100,null),
('AGL-T2B',9,'B',225,null),
('AGL-T2B',9,'Zn',150,null),
('AGL-T2B',10,'SA',4500,null),
('AGL-T2B',11,'SA',4000,null),
('AGL-T2B',11,'K',10000,null),
('AGL-T2B',11,'Mn',100,null),
('AGL-T2B',11,'B',225,null),
('AGL-T2B',11,'Zn',150,null),
('AGL-T2B',12,'Ni',7000,null),
('AGL-T2B',1,'Ni',6000,null),
('AGL-T2B',1,'K',6000,null),
('AGL-T2B',1,'Mn',100,null),
('AGL-T2B',1,'B',200,null),
('AGL-T2B',1,'Zn',100,null),
('AGL-T2B',2,'Ni',6000,null),
('AGL-T2B',3,'U',1000,null),
('AGL-T2B',4,'U',1000,null),
('AGL-T2B',5,'U',500,null),
('AGL-T2B',6,'U',500,null),
('AGL-T2B',7,'U',500,null),
('AGL-T2C',9,'U',1000,null),
('AGL-T2C',9,'K',8000,null),
('AGL-T2C',9,'Mn',100,null),
('AGL-T2C',9,'B',225,null),
('AGL-T2C',9,'Zn',150,null),
('AGL-T2C',10,'SA',4500,null),
('AGL-T2C',11,'SA',4000,null),
('AGL-T2C',11,'K',8000,null),
('AGL-T2C',11,'Mn',100,null),
('AGL-T2C',11,'B',225,null),
('AGL-T2C',11,'Zn',150,null),
('AGL-T2C',12,'Ni',7000,null),
('AGL-T2C',1,'Ni',6000,null),
('AGL-T2C',1,'K',6000,null),
('AGL-T2C',1,'Mn',100,null),
('AGL-T2C',1,'B',200,null),
('AGL-T2C',1,'Zn',100,null),
('AGL-T2C',2,'Ni',6000,null),
('AGL-T2C',3,'U',1000,null),
('AGL-T2C',4,'U',1000,null),
('AGL-T2C',5,'U',500,null),
('AGL-T2C',6,'U',500,null),
('AGL-T2C',7,'U',500,null),
('AGL-T3',9,'U',500,null),
('AGL-T3',9,'K',4000,null),
('AGL-T3',9,'Mn',50,null),
('AGL-T3',9,'B',100,null),
('AGL-T3',9,'Zn',75,null),
('AGL-T3',10,'SA',2000,null),
('AGL-T3',11,'SA',2000,null),
('AGL-T3',11,'K',3000,null),
('AGL-T3',11,'Mn',50,null),
('AGL-T3',11,'B',100,null),
('AGL-T3',11,'Zn',50,null),
('AGL-T3',12,'Ni',3000,null),
('AGL-T3',1,'Ni',3000,null),
('AGL-T3',1,'K',3000,null),
('AGL-T3',1,'Mn',50,null),
('AGL-T3',1,'B',100,null),
('AGL-T3',1,'Zn',50,null),
('AGL-T3',2,'Ni',3000,null),
('AGL-T3',3,'U',500,null),
('AGL-T3',4,'U',250,null),
('AGL-T3',5,'U',250,null),
('AGL-T3',6,'U',250,null),
('AGL-T3',7,'U',250,null),
('AGL-T4',9,'U',1000,null),
('AGL-T4',9,'K',4000,null),
('AGL-T4',9,'Ph',1000,null),
('AGL-T4',9,'Mn',100,null),
('AGL-T4',9,'B',200,null),
('AGL-T4',9,'Zn',125,null),
('AGL-T4',10,'SA',4000,null),
('AGL-T4',11,'SA',4000,null),
('AGL-T4',11,'K',4000,null),
('AGL-T4',11,'Mn',100,null),
('AGL-T4',11,'B',200,null),
('AGL-T4',11,'Zn',125,null),
('AGL-T4',12,'Ni',6000,null),
('AGL-T4',1,'Ni',6000,null),
('AGL-T4',1,'K',3000,null),
('AGL-T4',1,'Mn',75,null),
('AGL-T4',1,'B',200,null),
('AGL-T4',1,'Zn',100,null),
('AGL-T4',2,'Ni',6000,null),
('AGL-T4',3,'U',1000,null),
('AGL-T4',4,'U',500,null),
('AGL-T4',5,'U',500,null),
('AGL-T4',6,'U',500,null),
('AGL-T4',7,'U',500,null),
('MCC-CXT',9,'U',1000,null),
('MCC-CXT',9,'K',7000,null),
('MCC-CXT',9,'Ph',8000,null),
('MCC-CXT',9,'Mn',125,null),
('MCC-CXT',9,'B',250,null),
('MCC-CXT',9,'Zn',150,null),
('MCC-CXT',10,'SA',5000,null),
('MCC-CXT',11,'SA',5000,null),
('MCC-CXT',11,'K',7000,null),
('MCC-CXT',11,'Mn',125,null),
('MCC-CXT',11,'B',250,null),
('MCC-CXT',11,'Zn',150,null),
('MCC-CXT',12,'Ni',7000,null),
('MCC-CXT',1,'Ni',7000,null),
('MCC-CXT',1,'K',4000,null),
('MCC-CXT',1,'Mn',100,null),
('MCC-CXT',1,'B',250,null),
('MCC-CXT',1,'Zn',125,null),
('MCC-CXT',2,'Ni',7000,null),
('MCC-CXT',3,'U',1000,null),
('MCC-CXT',4,'U',1000,null),
('MCC-CXT',5,'U',1000,null),
('MCC-CXT',6,'U',500,null),
('MCC-CXT',7,'U',500,null),
('MCC-CXR',9,'U',1000,null),
('MCC-CXR',9,'K',8000,null),
('MCC-CXR',9,'Mn',125,null),
('MCC-CXR',9,'B',275,null),
('MCC-CXR',9,'Zn',150,null),
('MCC-CXR',10,'SA',5500,null),
('MCC-CXR',11,'SA',5000,null),
('MCC-CXR',11,'Mn',125,null),
('MCC-CXR',11,'B',275,null),
('MCC-CXR',11,'Zn',150,null),
('MCC-CXR',12,'Ni',8000,null),
('MCC-CXR',1,'Ni',8000,null),
('MCC-CXR',1,'K',3000,null),
('MCC-CXR',1,'Mn',100,null),
('MCC-CXR',1,'B',250,null),
('MCC-CXR',1,'Zn',150,null),
('MCC-CXR',2,'Ni',7000,null),
('MCC-CXR',3,'U',1000,null),
('MCC-CXR',4,'U',1000,null),
('MCC-CXR',5,'U',1000,null),
('MCC-CXR',6,'U',1000,null),
('MCC-CXR',7,'U',500,null),
('MCC-CXP',9,'U',1000,null),
('MCC-CXP',9,'K',15000,null),
('MCC-CXP',9,'Ph',8000,null),
('MCC-CXP',9,'Mn',125,null),
('MCC-CXP',9,'B',250,null),
('MCC-CXP',9,'Zn',150,null),
('MCC-CXP',10,'SA',5000,null),
('MCC-CXP',11,'SA',5000,null),
('MCC-CXP',11,'K',15000,null),
('MCC-CXP',11,'Mn',125,null),
('MCC-CXP',11,'B',250,null),
('MCC-CXP',11,'Zn',150,null),
('MCC-CXP',12,'Ni',7000,null),
('MCC-CXP',1,'Ni',7000,null),
('MCC-CXP',1,'K',8000,null),
('MCC-CXP',1,'Mn',100,null),
('MCC-CXP',1,'B',250,null),
('MCC-CXP',1,'Zn',125,null),
('MCC-CXP',2,'Ni',7000,null),
('MCC-CXP',3,'U',1000,null),
('MCC-CXP',4,'U',1000,null),
('MCC-CXP',5,'U',1000,null),
('MCC-CXP',6,'U',500,null),
('MCC-CXP',7,'U',500,null),
('MCC-S01',9,'U',500,null),
('MCC-S01',9,'K',4000,null),
('MCC-S01',9,'Mn',75,null),
('MCC-S01',9,'B',150,null),
('MCC-S01',9,'Zn',75,null),
('MCC-S01',10,'SA',3000,null),
('MCC-S01',10,'Ph',4500,null),
('MCC-S01',11,'SA',2500,null),
('MCC-S01',11,'Mn',75,null),
('MCC-S01',11,'B',125,null),
('MCC-S01',11,'Zn',75,null),
('MCC-S01',12,'Ni',4000,null),
('MCC-S01',1,'Ni',4000,null),
('MCC-S01',1,'K',3000,null),
('MCC-S01',1,'Mn',50,null),
('MCC-S01',1,'B',125,null),
('MCC-S01',1,'Zn',75,null),
('MCC-S01',2,'Ni',4000,null),
('MCC-S01',3,'U',500,null),
('MCC-S01',4,'U',500,null),
('MCC-S01',5,'U',500,null),
('MCC-S01',6,'U',500,null),
('MCC-S01',7,'U',500,null),
('MCC-S02',9,'U',500,null),
('MCC-S02',9,'K',3000,null),
('MCC-S02',9,'Mn',75,null),
('MCC-S02',9,'B',150,null),
('MCC-S02',9,'Zn',75,null),
('MCC-S02',10,'SA',3000,null),
('MCC-S02',11,'SA',2500,null),
('MCC-S02',11,'Mn',75,null),
('MCC-S02',11,'B',125,null),
('MCC-S02',11,'Zn',75,null),
('MCC-S02',12,'Ni',4000,null),
('MCC-S02',1,'Ni',4000,null),
('MCC-S02',1,'K',3000,null),
('MCC-S02',1,'Mn',50,null),
('MCC-S02',1,'B',125,null),
('MCC-S02',1,'Zn',75,null),
('MCC-S02',2,'Ni',4000,null),
('MCC-S02',3,'U',500,null),
('MCC-S02',4,'U',500,null),
('MCC-S02',5,'U',500,null),
('MCC-S02',6,'U',500,null),
('MCC-S02',7,'U',500,null),
('MCC-S03',9,'U',500,null),
('MCC-S03',9,'K',3000,null),
('MCC-S03',9,'Mn',75,null),
('MCC-S03',9,'B',150,null),
('MCC-S03',9,'Zn',75,null),
('MCC-S03',10,'SA',3000,null),
('MCC-S03',10,'Ph',1500,null),
('MCC-S03',11,'SA',2500,null),
('MCC-S03',11,'Mn',75,null),
('MCC-S03',11,'B',125,null),
('MCC-S03',11,'Zn',75,null),
('MCC-S03',12,'Ni',4000,null),
('MCC-S03',1,'Ni',4000,null),
('MCC-S03',1,'K',3000,null),
('MCC-S03',1,'Mn',50,null),
('MCC-S03',1,'B',125,null),
('MCC-S03',1,'Zn',75,null),
('MCC-S03',2,'Ni',4000,null),
('MCC-S03',3,'U',500,null),
('MCC-S03',4,'U',500,null),
('MCC-S03',5,'U',500,null),
('MCC-S03',6,'U',500,null),
('MCC-S03',7,'U',500,null),
('MCC-S04',9,'U',500,null),
('MCC-S04',9,'K',3000,null),
('MCC-S04',9,'Mn',75,null),
('MCC-S04',9,'B',150,null),
('MCC-S04',9,'Zn',75,null),
('MCC-S04',10,'SA',3000,null),
('MCC-S04',10,'Ph',4500,null),
('MCC-S04',11,'SA',2500,null),
('MCC-S04',11,'Mn',75,null),
('MCC-S04',11,'B',125,null),
('MCC-S04',11,'Zn',75,null),
('MCC-S04',12,'Ni',4000,null),
('MCC-S04',1,'Ni',4000,null),
('MCC-S04',1,'K',2000,null),
('MCC-S04',1,'Mn',50,null),
('MCC-S04',1,'B',125,null),
('MCC-S04',1,'Zn',75,null),
('MCC-S04',2,'Ni',4000,null),
('MCC-S04',3,'U',500,null),
('MCC-S04',4,'U',500,null),
('MCC-S04',5,'U',500,null),
('MCC-S04',6,'U',500,null),
('MCC-S04',7,'U',500,null),
('MCC-S05',9,'U',500,null),
('MCC-S05',9,'K',4000,null),
('MCC-S05',9,'Mn',75,null),
('MCC-S05',9,'B',150,null),
('MCC-S05',9,'Zn',75,null),
('MCC-S05',10,'SA',3000,null),
('MCC-S05',10,'Ph',6000,null),
('MCC-S05',11,'SA',2500,null),
('MCC-S05',11,'K',4000,null),
('MCC-S05',11,'Mn',75,null),
('MCC-S05',11,'B',125,null),
('MCC-S05',11,'Zn',75,null),
('MCC-S05',12,'Ni',4000,null),
('MCC-S05',1,'Ni',4000,null),
('MCC-S05',1,'K',3000,null),
('MCC-S05',1,'Mn',50,null),
('MCC-S05',1,'B',125,null),
('MCC-S05',1,'Zn',75,null),
('MCC-S05',2,'Ni',4000,null),
('MCC-S05',3,'U',500,null),
('MCC-S05',4,'U',500,null),
('MCC-S05',5,'U',500,null),
('MCC-S05',6,'U',500,null),
('MCC-S05',7,'U',500,null),
('MCC-S06',9,'U',500,null),
('MCC-S06',9,'K',5000,null),
('MCC-S06',9,'Mn',75,null),
('MCC-S06',9,'B',150,null),
('MCC-S06',9,'Zn',75,null),
('MCC-S06',10,'SA',3000,null),
('MCC-S06',11,'SA',2500,null),
('MCC-S06',11,'K',5000,null),
('MCC-S06',11,'Mn',75,null),
('MCC-S06',11,'B',125,null),
('MCC-S06',11,'Zn',75,null),
('MCC-S06',12,'Ni',4000,null),
('MCC-S06',1,'Ni',4000,null),
('MCC-S06',1,'K',3000,null),
('MCC-S06',1,'Mn',50,null),
('MCC-S06',1,'B',125,null),
('MCC-S06',1,'Zn',75,null),
('MCC-S06',2,'Ni',4000,null),
('MCC-S06',3,'U',500,null),
('MCC-S06',4,'U',500,null),
('MCC-S06',5,'U',500,null),
('MCC-S06',6,'U',500,null),
('MCC-S06',7,'U',500,null),
('MCC-S07',9,'U',500,null),
('MCC-S07',9,'K',5000,null),
('MCC-S07',9,'Mn',75,null),
('MCC-S07',9,'B',150,null),
('MCC-S07',9,'Zn',75,null),
('MCC-S07',10,'SA',3000,null),
('MCC-S07',11,'SA',2500,null),
('MCC-S07',11,'K',5000,null),
('MCC-S07',11,'Mn',75,null),
('MCC-S07',11,'B',125,null),
('MCC-S07',11,'Zn',75,null),
('MCC-S07',12,'Ni',4000,null),
('MCC-S07',1,'Ni',4000,null),
('MCC-S07',1,'K',3000,null),
('MCC-S07',1,'Mn',50,null),
('MCC-S07',1,'B',125,null),
('MCC-S07',1,'Zn',75,null),
('MCC-S07',2,'Ni',4000,null),
('MCC-S07',3,'U',500,null),
('MCC-S07',4,'U',500,null),
('MCC-S07',5,'U',500,null),
('MCC-S07',6,'U',500,null),
('MCC-S07',7,'U',500,null),
('MCC-S08',9,'U',500,null),
('MCC-S08',9,'K',4500,null),
('MCC-S08',9,'Mn',75,null),
('MCC-S08',9,'B',150,null),
('MCC-S08',9,'Zn',75,null),
('MCC-S08',10,'SA',3000,null),
('MCC-S08',11,'SA',2500,null),
('MCC-S08',11,'K',4500,null),
('MCC-S08',11,'Mn',75,null),
('MCC-S08',11,'B',125,null),
('MCC-S08',11,'Zn',75,null),
('MCC-S08',12,'Ni',4000,null),
('MCC-S08',1,'Ni',4000,null),
('MCC-S08',1,'K',3000,null),
('MCC-S08',1,'Mn',50,null),
('MCC-S08',1,'B',125,null),
('MCC-S08',1,'Zn',75,null),
('MCC-S08',2,'Ni',4000,null),
('MCC-S08',3,'U',500,null),
('MCC-S08',4,'U',500,null),
('MCC-S08',5,'U',500,null),
('MCC-S08',6,'U',500,null),
('MCC-S08',7,'U',500,null),
('MCC-ERA',9,'U',3000,null),
('MCC-ERA',9,'K',21000,null),
('MCC-ERA',9,'Mn',400,null),
('MCC-ERA',9,'B',800,null),
('MCC-ERA',9,'Zn',450,null),
('MCC-ERA',10,'SA',16500,null),
('MCC-ERA',11,'SA',15000,null),
('MCC-ERA',11,'K',21000,null),
('MCC-ERA',11,'Mn',350,null),
('MCC-ERA',11,'B',800,null)
) as v(codigo, mes, sg, kg, obs)
join (values ('U','ureia'),('Ni','nitrato'),('SA','sulfato_amonio'),('K','kcl'),('Ph','phusion'),('Mn','sulfato_mn'),('B','acido_borico'),('Zn','sulfato_zn')) as s(sg, insumo) on s.sg = v.sg
join public.unidade_manejo u on u.codigo = v.codigo
join public.plano_safra p on p.fazenda_app = u.fazenda_app and p.safra = '2026/27' and p.versao = 1
on conflict (plano_id, unidade_id, mes, insumo) do nothing;
insert into public.plano_adubo_mes (plano_id, unidade_id, mes, insumo, kg, via, obs)
select p.id, u.id, v.mes, s.insumo, v.kg, null, v.obs from (values
('MCC-ERA',11,'Zn',450,null),
('MCC-ERA',12,'Ni',24000,null),
('MCC-ERA',1,'Ni',24000,null),
('MCC-ERA',1,'K',11000,null),
('MCC-ERA',1,'Mn',350,null),
('MCC-ERA',1,'B',800,null),
('MCC-ERA',1,'Zn',450,null),
('MCC-ERA',2,'Ni',22000,null),
('MCC-ERA',3,'U',3000,null),
('MCC-ERA',4,'U',3000,null),
('MCC-ERA',5,'U',3000,null),
('MCC-ERA',6,'U',3000,null),
('MCC-ERA',7,'U',2000,null),
('MCC-ERB',9,'U',1000,null),
('MCC-ERB',9,'K',7000,null),
('MCC-ERB',9,'Mn',100,null),
('MCC-ERB',9,'B',300,null),
('MCC-ERB',9,'Zn',125,null),
('MCC-ERB',10,'SA',5000,null),
('MCC-ERB',11,'SA',4000,null),
('MCC-ERB',11,'K',7000,null),
('MCC-ERB',11,'Mn',100,null),
('MCC-ERB',11,'B',200,null),
('MCC-ERB',11,'Zn',125,null),
('MCC-ERB',12,'Ni',7000,null),
('MCC-ERB',1,'Ni',7000,null),
('MCC-ERB',1,'K',4000,null),
('MCC-ERB',1,'Mn',100,null),
('MCC-ERB',1,'B',200,null),
('MCC-ERB',1,'Zn',125,null),
('MCC-ERB',2,'Ni',6000,null),
('MCC-ERB',3,'U',1000,null),
('MCC-ERB',4,'U',1000,null),
('MCC-ERB',5,'U',1000,null),
('MCC-ERB',6,'U',500,null),
('MCC-ERB',7,'U',500,null),
('LAG-S01',9,'U',2000,null),
('LAG-S01',9,'K',10000,null),
('LAG-S01',9,'Mn',175,null),
('LAG-S01',9,'B',400,null),
('LAG-S01',9,'Zn',225,null),
('LAG-S01',10,'SA',8000,null),
('LAG-S01',11,'SA',7500,null),
('LAG-S01',11,'K',10000,null),
('LAG-S01',11,'Mn',175,null),
('LAG-S01',11,'B',400,null),
('LAG-S01',11,'Zn',225,null),
('LAG-S01',12,'Ni',12000,null),
('LAG-S01',1,'Ni',12000,null),
('LAG-S01',1,'K',6000,null),
('LAG-S01',1,'Mn',150,null),
('LAG-S01',1,'B',350,null),
('LAG-S01',1,'Zn',200,null),
('LAG-S01',2,'Ni',10000,null),
('LAG-S01',3,'U',2000,null),
('LAG-S01',4,'U',2000,null),
('LAG-S01',5,'U',1000,null),
('LAG-S01',6,'U',500,null),
('LAG-S01',7,'U',500,null),
('LAG-S02',9,'U',2000,null),
('LAG-S02',9,'K',10000,null),
('LAG-S02',9,'Mn',175,null),
('LAG-S02',9,'B',400,null),
('LAG-S02',9,'Zn',225,null),
('LAG-S02',10,'SA',8000,null),
('LAG-S02',11,'SA',7500,null),
('LAG-S02',11,'K',10000,null),
('LAG-S02',11,'Mn',175,null),
('LAG-S02',11,'B',400,null),
('LAG-S02',11,'Zn',225,null),
('LAG-S02',12,'Ni',12000,null),
('LAG-S02',1,'Ni',12000,null),
('LAG-S02',1,'K',6000,null),
('LAG-S02',1,'Mn',150,null),
('LAG-S02',1,'B',350,null),
('LAG-S02',1,'Zn',200,null),
('LAG-S02',2,'Ni',10000,null),
('LAG-S02',3,'U',2000,null),
('LAG-S02',4,'U',2000,null),
('LAG-S02',5,'U',1000,null),
('LAG-S02',6,'U',500,null),
('LAG-S02',7,'U',500,null),
('LAG-S03',9,'U',2000,null),
('LAG-S03',9,'K',10000,null),
('LAG-S03',9,'Mn',175,null),
('LAG-S03',9,'B',400,null),
('LAG-S03',9,'Zn',225,null),
('LAG-S03',10,'SA',8000,null),
('LAG-S03',11,'SA',7500,null),
('LAG-S03',11,'K',10000,null),
('LAG-S03',11,'Mn',175,null),
('LAG-S03',11,'B',400,null),
('LAG-S03',11,'Zn',225,null),
('LAG-S03',12,'Ni',12000,null),
('LAG-S03',1,'Ni',12000,null),
('LAG-S03',1,'K',6000,null),
('LAG-S03',1,'Mn',150,null),
('LAG-S03',1,'B',350,null),
('LAG-S03',1,'Zn',200,null),
('LAG-S03',2,'Ni',10000,null),
('LAG-S03',3,'U',2000,null),
('LAG-S03',4,'U',2000,null),
('LAG-S03',5,'U',1000,null),
('LAG-S03',6,'U',500,null),
('LAG-S03',7,'U',500,null),
('LAG-S04',9,'U',1000,null),
('LAG-S04',9,'Mn',100,null),
('LAG-S04',9,'B',200,null),
('LAG-S04',9,'Zn',125,null),
('LAG-S04',10,'SA',4000,null),
('LAG-S04',11,'SA',3500,null),
('LAG-S04',11,'Mn',100,null),
('LAG-S04',11,'B',200,null),
('LAG-S04',11,'Zn',100,null),
('LAG-S04',12,'Ni',6000,null),
('LAG-S04',1,'Ni',6000,null),
('LAG-S04',1,'K',4000,null),
('LAG-S04',1,'Mn',100,null),
('LAG-S04',1,'B',200,null),
('LAG-S04',1,'Zn',100,null),
('LAG-S04',2,'Ni',5000,null),
('LAG-S04',3,'U',1000,null),
('LAG-S04',4,'U',500,null),
('LAG-S04',5,'U',500,null),
('LAG-S04',6,'U',500,null),
('LAG-S04',7,'U',500,null),
('LAG-S05',9,'U',1000,null),
('LAG-S05',9,'Mn',100,null),
('LAG-S05',9,'B',200,null),
('LAG-S05',9,'Zn',125,null),
('LAG-S05',10,'SA',4000,null),
('LAG-S05',11,'SA',3500,null),
('LAG-S05',11,'K',4000,null),
('LAG-S05',11,'Mn',100,null),
('LAG-S05',11,'B',200,null),
('LAG-S05',11,'Zn',100,null),
('LAG-S05',12,'Ni',6000,null),
('LAG-S05',1,'Ni',6000,null),
('LAG-S05',1,'K',4000,null),
('LAG-S05',1,'Mn',100,null),
('LAG-S05',1,'B',200,null),
('LAG-S05',1,'Zn',100,null),
('LAG-S05',2,'Ni',5000,null),
('LAG-S05',3,'U',1000,null),
('LAG-S05',4,'U',500,null),
('LAG-S05',5,'U',500,null),
('LAG-S05',6,'U',500,null),
('LAG-S05',7,'U',500,null),
('LAG-S06',9,'U',1000,null),
('LAG-S06',9,'Mn',100,null),
('LAG-S06',9,'B',200,null),
('LAG-S06',9,'Zn',125,null),
('LAG-S06',10,'SA',4000,null),
('LAG-S06',11,'SA',3500,null),
('LAG-S06',11,'Mn',100,null),
('LAG-S06',11,'B',200,null),
('LAG-S06',11,'Zn',100,null),
('LAG-S06',12,'Ni',6000,null),
('LAG-S06',1,'Ni',6000,null),
('LAG-S06',1,'K',4000,null),
('LAG-S06',1,'Mn',100,null),
('LAG-S06',1,'B',200,null),
('LAG-S06',1,'Zn',100,null),
('LAG-S06',2,'Ni',5000,null),
('LAG-S06',3,'U',1000,null),
('LAG-S06',4,'U',500,null),
('LAG-S06',5,'U',500,null),
('LAG-S06',6,'U',500,null),
('LAG-S06',7,'U',500,null),
('LAG-JX',9,'U',1000,null),
('LAG-JX',9,'K',4000,null),
('LAG-JX',9,'Mn',100,null),
('LAG-JX',9,'B',200,null),
('LAG-JX',9,'Zn',125,null),
('LAG-JX',10,'SA',4000,null),
('LAG-JX',11,'SA',3500,null),
('LAG-JX',11,'K',4000,null),
('LAG-JX',11,'Mn',100,null),
('LAG-JX',11,'B',200,null),
('LAG-JX',11,'Zn',100,null),
('LAG-JX',12,'Ni',5500,null),
('LAG-JX',1,'Ni',5500,null),
('LAG-JX',1,'K',3000,null),
('LAG-JX',1,'Mn',100,null),
('LAG-JX',1,'B',150,null),
('LAG-JX',1,'Zn',100,null),
('LAG-JX',2,'Ni',5500,null),
('LAG-JX',3,'U',1000,null),
('LAG-JX',4,'U',500,null),
('LAG-JX',5,'U',500,null),
('LAG-JX',6,'U',500,null),
('LAG-JX',7,'U',500,null),
('MTP-S01',9,'U',1000,null),
('MTP-S01',9,'K',3000,null),
('MTP-S01',9,'Mn',100,null),
('MTP-S01',9,'B',175,null),
('MTP-S01',9,'Zn',100,null),
('MTP-S01',10,'SA',4000,null),
('MTP-S01',11,'SA',3000,null),
('MTP-S01',11,'K',3000,null),
('MTP-S01',11,'Mn',100,null),
('MTP-S01',11,'B',175,null),
('MTP-S01',11,'Zn',100,null),
('MTP-S01',12,'Ni',5000,null),
('MTP-S01',1,'Ni',5000,null),
('MTP-S01',1,'K',2000,null),
('MTP-S01',1,'Mn',100,null),
('MTP-S01',1,'B',175,null),
('MTP-S01',1,'Zn',100,null),
('MTP-S01',2,'Ni',5000,null),
('MTP-S01',3,'U',500,null),
('MTP-S01',4,'U',500,null),
('MTP-S01',5,'U',500,null),
('MTP-S01',6,'U',500,null),
('MTP-S01',7,'U',500,null),
('MTP-S02',9,'U',1000,null),
('MTP-S02',9,'K',3000,null),
('MTP-S02',9,'Mn',100,null),
('MTP-S02',9,'B',175,null),
('MTP-S02',9,'Zn',100,null),
('MTP-S02',10,'SA',4000,null),
('MTP-S02',11,'SA',3000,null),
('MTP-S02',11,'K',3000,null),
('MTP-S02',11,'Mn',100,null),
('MTP-S02',11,'B',175,null),
('MTP-S02',11,'Zn',100,null),
('MTP-S02',12,'Ni',5000,null),
('MTP-S02',1,'Ni',5000,null),
('MTP-S02',1,'K',3000,null),
('MTP-S02',1,'Mn',100,null),
('MTP-S02',1,'B',175,null),
('MTP-S02',1,'Zn',100,null),
('MTP-S02',2,'Ni',5000,null),
('MTP-S02',3,'U',500,null),
('MTP-S02',4,'U',500,null),
('MTP-S02',5,'U',500,null),
('MTP-S02',6,'U',500,null),
('MTP-S02',7,'U',500,null),
('MTP-S03',9,'U',1000,null),
('MTP-S03',9,'K',6000,null),
('MTP-S03',9,'Mn',100,null),
('MTP-S03',9,'B',250,null),
('MTP-S03',9,'Zn',150,null),
('MTP-S03',10,'SA',5000,null),
('MTP-S03',10,'Ph',3000,null),
('MTP-S03',11,'SA',5000,null),
('MTP-S03',11,'K',6000,null),
('MTP-S03',11,'Mn',100,null),
('MTP-S03',11,'B',250,null),
('MTP-S03',11,'Zn',150,null),
('MTP-S03',12,'Ni',8000,null),
('MTP-S03',1,'Ni',7000,null),
('MTP-S03',1,'K',4000,null),
('MTP-S03',1,'Mn',100,null),
('MTP-S03',1,'B',250,null),
('MTP-S03',1,'Zn',125,null),
('MTP-S03',2,'Ni',7000,null),
('MTP-S03',3,'U',1000,null),
('MTP-S03',4,'U',1000,null),
('MTP-S03',5,'U',1000,null),
('MTP-S03',6,'U',1000,null),
('MTP-S03',7,'U',500,null),
('MTP-S04',9,'U',1000,null),
('MTP-S04',9,'K',6000,null),
('MTP-S04',9,'Mn',125,null),
('MTP-S04',9,'B',250,null),
('MTP-S04',9,'Zn',150,null),
('MTP-S04',10,'SA',5000,null),
('MTP-S04',10,'Ph',3000,null),
('MTP-S04',11,'SA',5000,null),
('MTP-S04',11,'K',6000,null),
('MTP-S04',11,'Mn',125,null),
('MTP-S04',11,'B',250,null),
('MTP-S04',11,'Zn',150,null),
('MTP-S04',12,'Ni',8000,null),
('MTP-S04',1,'Ni',7000,null),
('MTP-S04',1,'K',4000,null),
('MTP-S04',1,'Mn',100,null),
('MTP-S04',1,'B',250,null),
('MTP-S04',1,'Zn',125,null),
('MTP-S04',2,'Ni',7000,null),
('MTP-S04',3,'U',1000,null),
('MTP-S04',4,'U',1000,null),
('MTP-S04',5,'U',1000,null),
('MTP-S04',6,'U',1000,null),
('MTP-S04',7,'U',500,null),
('MTP-S05',9,'U',1000,null),
('MTP-S05',9,'K',8000,null),
('MTP-S05',9,'Mn',125,null),
('MTP-S05',9,'B',250,null),
('MTP-S05',9,'Zn',150,null),
('MTP-S05',10,'SA',5000,null),
('MTP-S05',10,'Ph',3000,null),
('MTP-S05',11,'SA',5000,null),
('MTP-S05',11,'K',8000,null),
('MTP-S05',11,'Mn',125,null),
('MTP-S05',11,'B',250,null),
('MTP-S05',11,'Zn',150,null),
('MTP-S05',12,'Ni',8000,null),
('MTP-S05',1,'Ni',7000,null),
('MTP-S05',1,'K',3000,null),
('MTP-S05',1,'Mn',100,null),
('MTP-S05',1,'B',250,null),
('MTP-S05',1,'Zn',125,null),
('MTP-S05',2,'Ni',7000,null),
('MTP-S05',3,'U',1000,null),
('MTP-S05',4,'U',1000,null),
('MTP-S05',5,'U',1000,null),
('MTP-S05',6,'U',1000,null),
('MTP-S05',7,'U',500,null),
('MTP-3PT',9,'U',1500,null),
('MTP-3PT',9,'K',7000,null),
('MTP-3PT',9,'Mn',150,null),
('MTP-3PT',9,'B',400,null),
('MTP-3PT',9,'Zn',200,null),
('MTP-3PT',10,'SA',7000,null),
('MTP-3PT',11,'SA',6000,null),
('MTP-3PT',11,'K',7000,null),
('MTP-3PT',11,'Mn',150,null),
('MTP-3PT',11,'B',300,null),
('MTP-3PT',11,'Zn',200,null),
('MTP-3PT',12,'Ni',10000,null),
('MTP-3PT',1,'Ni',9000,null),
('MTP-3PT',1,'K',4000,null),
('MTP-3PT',1,'Mn',150,null),
('MTP-3PT',1,'B',300,null),
('MTP-3PT',1,'Zn',150,null),
('MTP-3PT',2,'Ni',9000,null),
('MTP-3PT',3,'U',1500,null),
('MTP-3PT',4,'U',1500,null),
('MTP-3PT',5,'U',1000,null),
('MTP-3PT',6,'U',1000,null),
('MTP-3PT',7,'U',1000,null)
) as v(codigo, mes, sg, kg, obs)
join (values ('U','ureia'),('Ni','nitrato'),('SA','sulfato_amonio'),('K','kcl'),('Ph','phusion'),('Mn','sulfato_mn'),('B','acido_borico'),('Zn','sulfato_zn')) as s(sg, insumo) on s.sg = v.sg
join public.unidade_manejo u on u.codigo = v.codigo
join public.plano_safra p on p.fazenda_app = u.fazenda_app and p.safra = '2026/27' and p.versao = 1
on conflict (plano_id, unidade_id, mes, insumo) do nothing;

-- 7. plano_calagem (71 linhas; janela 01/09–31/10/2026) ------------------
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('cef76739-e882-56ac-8be7-bc599da7808c', 'cea5a300-adcb-57e0-be8f-7a8ff70047b7', 'Vereda setor 01', 3, 48, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('cef76739-e882-56ac-8be7-bc599da7808c', '0d74c8e4-798c-534e-9bd0-838710c38867', 'Vereda setor 02', 3, 69, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('cef76739-e882-56ac-8be7-bc599da7808c', '077292a8-e8ca-5518-b830-58c7c9478509', 'Vereda setor 03', 2, 42, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('cef76739-e882-56ac-8be7-bc599da7808c', '51b4ff94-68e2-5bf1-bcf9-3ac595cb7355', 'Vereda setor 04', 3, 54, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('cef76739-e882-56ac-8be7-bc599da7808c', '922e16bf-e805-5091-bbf8-5d104e3db726', 'Vereda setor 05', 3, 54, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('cef76739-e882-56ac-8be7-bc599da7808c', '8794ebc3-0652-5321-af14-77cbca328844', 'Vereda setor 06', 2, 42, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('cef76739-e882-56ac-8be7-bc599da7808c', 'd151add8-c2dc-5dd2-82a4-232798ae5be4', 'Vereda setor 07', 3, 57, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('cef76739-e882-56ac-8be7-bc599da7808c', 'bb9810e0-8608-5e51-85c2-b3c0c64ee499', 'Vereda 08 alto', 4, 120, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('cef76739-e882-56ac-8be7-bc599da7808c', 'bb9810e0-8608-5e51-85c2-b3c0c64ee499', 'Vereda 08 baixo', 2, 58, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('cef76739-e882-56ac-8be7-bc599da7808c', 'c37449fa-8e4d-5dc2-93fc-9a93bc61337d', 'Vereda setor 09', 3, 42, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('cef76739-e882-56ac-8be7-bc599da7808c', 'be8d4fed-6766-5e34-b303-4ab9bbd18171', 'Vereda pivô 02 t01', 4, 104, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('cef76739-e882-56ac-8be7-bc599da7808c', 'be8d4fed-6766-5e34-b303-4ab9bbd18171', 'Vereda pivô 02 t02', 5, 135, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('cef76739-e882-56ac-8be7-bc599da7808c', 'be8d4fed-6766-5e34-b303-4ab9bbd18171', 'Vereda pivô 02 t03', 4, 224, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('cef76739-e882-56ac-8be7-bc599da7808c', 'ae05e0a3-12ab-5f6c-a652-656bff7f1003', 'Vereda pivô 06 t01', 4, 104, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('cef76739-e882-56ac-8be7-bc599da7808c', 'ae05e0a3-12ab-5f6c-a652-656bff7f1003', 'Vereda pivô 06 t02', 5, 135, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', '05444656-96f3-593e-9154-eed917760ba4', 'St01 1º plantio', 3, 48, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', '9305a42d-8042-53a8-b963-014655eead9e', 'St02 1º plantio', 3, 48, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', '21c9be63-81e0-5f60-bac8-5779e5852b1e', 'St03 1º plantio', 3, 48, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', '68b975ed-2dcd-57c1-ab2a-ef1f757f488c', 'St04 1º plantio', 2, 32, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', 'a0cb7127-3d74-52ad-8cd5-55a1e26f2928', 'St05 1º plantio', 2, 32, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', '530f38fd-d7e9-5aa7-9163-93572635267c', 'St06 1º plantio', 4, 80, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', 'faf865cd-664e-5b0b-b35a-dc32ff72d19e', '2º Plantio 180 hectares (bloco ÷ 6)', 2, 60, true, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', '5ae9a8d4-7916-5f01-ad2b-dcf7aa0012f4', '2º Plantio 180 hectares (bloco ÷ 6)', 2, 60, true, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', '4a5f6ffc-385c-5312-8d03-feb7d99aa7a1', '2º Plantio 180 hectares (bloco ÷ 6)', 2, 60, true, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', 'ce3386ac-b315-5910-bb9b-f08fa02759f6', '2º Plantio 180 hectares (bloco ÷ 6)', 2, 60, true, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', 'b1f29351-3db9-5847-94fe-622ab0e449ce', '2º Plantio 180 hectares (bloco ÷ 6)', 2, 60, true, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('b7799692-9a55-566e-b492-b8bfc6a1328e', '1d3ba683-7a81-5fdc-bc74-cb59d6af8cb2', '2º Plantio 180 hectares (bloco ÷ 6)', 2, 60, true, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3bc4573e-978d-58dd-a97d-26d240b75da5', 'b2d9746a-56e0-5520-9a1d-04aec4418429', 'Romaria setor 01', 4, 84, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3bc4573e-978d-58dd-a97d-26d240b75da5', '321e7e53-05ce-5a3f-bfe8-f1b20e9c4d64', 'Romaria setor 02', 3, 63, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3bc4573e-978d-58dd-a97d-26d240b75da5', '12dc5936-3cf9-546c-a9c0-08e269fd34b9', 'Romaria setor 03', 2, 50, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3bc4573e-978d-58dd-a97d-26d240b75da5', '5e5ab1ed-72db-5e2f-af9d-0be644f4e531', 'Romaria setor 04', 2, 50, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3bc4573e-978d-58dd-a97d-26d240b75da5', 'de2ec3af-d83a-5825-ab6e-5a6faea364a7', 'Romaria setor 05', 4, 80, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3bc4573e-978d-58dd-a97d-26d240b75da5', '8e4d0c58-9a49-502e-9cbf-a1ac6427cd37', 'Romaria setor 06', 3, 60, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3bc4573e-978d-58dd-a97d-26d240b75da5', '3a030670-ca55-57f8-8154-8c6e309dcdde', 'Romaria setor 07', 3, 60, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3bc4573e-978d-58dd-a97d-26d240b75da5', '0ac3ef47-0647-559e-ba94-426854020a00', 'Romaria setor 08', 4, 48, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('d6b4408b-6b1c-5793-ae94-87383995a6fc', '4f82988a-db81-56ad-8f9d-3ff374703b30', 'Café 5º Paraíso', 3, 99, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('d6b4408b-6b1c-5793-ae94-87383995a6fc', 'f2a64fb7-41dd-5db9-8494-c3a140044061', 'Café 5º Catucaí', 4, 88, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('d6b4408b-6b1c-5793-ae94-87383995a6fc', '67532357-b28e-5945-9bac-9f1f790aeda3', 'Café 5º novo', 2, 44, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('d6b4408b-6b1c-5793-ae94-87383995a6fc', '83da31b8-bc9d-5196-afec-eb837eb67521', 'Café 6º renovação', 2, 48, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('d6b4408b-6b1c-5793-ae94-87383995a6fc', '38fe974d-7141-53fd-9108-7f6986f70e28', 'Café 6º IPR 100/ CT 99', 2, 60, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('8cc75fc4-d102-5f55-952d-e4fb6b86c85a', '9fb0d512-4eb8-579d-ba1a-b493d8b92699', 'T1 Catuaí / IBC (setor 04)', 3, 33, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('8cc75fc4-d102-5f55-952d-e4fb6b86c85a', '7a0dcfc7-802c-5935-9cab-8d97b1195404', 'T2 casinha para baixo (setores 7 e 8)', 3, 72, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('8cc75fc4-d102-5f55-952d-e4fb6b86c85a', 'a0c3c64c-19cd-5773-ba30-ed90ab54a8cc', 'T3 casinha para cima (setores 5 e 6)', 3, 72, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('8cc75fc4-d102-5f55-952d-e4fb6b86c85a', 'ee998f11-5829-5204-ac4a-4d130b54f202', 'T4 2º LD (setor 02)', 5, 55, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('8cc75fc4-d102-5f55-952d-e4fb6b86c85a', '1fb5403f-8001-5fe3-9e07-95e25d23906f', 'T5 1º e 3º LD (setores 1 e 3)', 4, 88, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3b55c314-02b1-58ff-b191-8c38c1616578', 'd5a9be00-bdd8-5330-a596-56d890e33b8c', 'Caxico Topázio', 4, 108, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3b55c314-02b1-58ff-b191-8c38c1616578', 'a7e4adad-b2f2-5e23-8463-3787bb2652fb', 'Caxico M Novo recepa', 3, 87, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3b55c314-02b1-58ff-b191-8c38c1616578', '7f41a1b1-7ce0-54f3-aaaf-288e22cb0df1', 'Caxico represa', 2, 54, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3b55c314-02b1-58ff-b191-8c38c1616578', '68659749-f1c4-59d1-b55a-6f3999140911', 'M. Carmelo st01', 3, 45, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3b55c314-02b1-58ff-b191-8c38c1616578', 'd6b5a1ae-a55d-5dd1-b7a7-e7da3cec855c', 'M. Carmelo st02', 1, 15, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3b55c314-02b1-58ff-b191-8c38c1616578', 'e1ccf609-4fa9-50dd-a186-a18cf0abc3bf', 'M. Carmelo st03', 1, 15, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3b55c314-02b1-58ff-b191-8c38c1616578', 'ece1c8fb-a45f-508b-be01-2c7c3ddbe1af', 'M. Carmelo st04', 2, 30, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3b55c314-02b1-58ff-b191-8c38c1616578', '92bbe608-c8b7-546f-8968-c1c002d5373a', 'M. Carmelo st05', 2, 30, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3b55c314-02b1-58ff-b191-8c38c1616578', '66846a44-48cd-5b70-b369-43c45bb73e0f', 'M. Carmelo st06', 2, 30, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3b55c314-02b1-58ff-b191-8c38c1616578', 'dd00abfc-9872-5557-9c8b-988048c9e374', 'M. Carmelo st07', 2, 30, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3b55c314-02b1-58ff-b191-8c38c1616578', 'b34ee153-138e-59ac-a01a-e83272f27443', 'M. Carmelo st08', 2, 30, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3b55c314-02b1-58ff-b191-8c38c1616578', '4e8a2405-f0a5-5a2c-9dc0-b75ae24703c4', 'Sr. Ernani alto', 3, 150, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('3b55c314-02b1-58ff-b191-8c38c1616578', '3b27bf08-59be-5113-928d-35b82561f0ce', 'Sr. Ernani baixo', 3, 75, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('08e5d773-03d4-5e3c-a22a-2b75d766167a', '6bea1c27-7fba-5e9f-a8e3-3f3f6106c916', 'setor 01', 3, 72, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('08e5d773-03d4-5e3c-a22a-2b75d766167a', '14d58085-9586-5ded-a32c-343711392423', 'setor 02', 5, 120, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('08e5d773-03d4-5e3c-a22a-2b75d766167a', '2dff98c4-b84a-5ee5-87ff-68d61e06e24a', 'setor 03', 5, 120, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('08e5d773-03d4-5e3c-a22a-2b75d766167a', '4c511371-72fe-5b55-aa8e-8d2bf4556d50', 'setor 04', 3, 63, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('08e5d773-03d4-5e3c-a22a-2b75d766167a', 'e65700e9-2521-575f-9cc1-f758505bf792', 'setor 05', 3, 63, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('08e5d773-03d4-5e3c-a22a-2b75d766167a', '4480ebf3-2cd7-5b72-947d-7bc47924b559', 'setor 06', 3, 63, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('08e5d773-03d4-5e3c-a22a-2b75d766167a', 'a3273601-419a-5ea5-a9ed-385e506124a3', 'Joao Xavier', 2, 52, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('c38db03e-55d9-5cd5-a6d4-95ca186126b5', '11741a30-74ef-55e1-9e5c-6e7587d8ab6d', 'setor 01', 2, 38, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('c38db03e-55d9-5cd5-a6d4-95ca186126b5', '6a7ae5ab-b93c-5183-aefb-0cbc27c323e2', 'setor 02', 2, 38, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('c38db03e-55d9-5cd5-a6d4-95ca186126b5', '1a67fd03-2921-5347-a427-016d3cfb5a5c', 'setor 03', 2, 40, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('c38db03e-55d9-5cd5-a6d4-95ca186126b5', '6797f7f4-63fa-546f-8805-76ff097e1a82', 'setor 04', 2, 40, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('c38db03e-55d9-5cd5-a6d4-95ca186126b5', '4e33f057-81de-558a-a5e7-6f17acdb1bc2', 'setor 05', 3, 60, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;
insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) values ('c38db03e-55d9-5cd5-a6d4-95ca186126b5', 'cd1794c9-fb60-5d58-b1b3-08b75a82f9ee', 'Plantio 2026', 2, 90, false, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;

-- 8. plano_fito_mes (registro do grupo: plano_id nulo) e exceções ----------
insert into public.plano_fito_mes (plano_id, mes, fase, alvos, produtos, via_solo) values (null, 8, 'Pré-florada', '{}'::text[], array['Mirus', 'Priori Top', 'Auto 400', 'Oberon', 'Ochima']::text[], '{}'::text[]) on conflict (mes) where plano_id is null do nothing;
insert into public.plano_fito_mes (plano_id, mes, fase, alvos, produtos, via_solo) values (null, 9, 'Pós-florada', array['bicho-mineiro', 'ácaro']::text[], array['Mirus', 'Miravis Duo', 'Curyon', 'Vertimec', 'Ochima']::text[], '{}'::text[]) on conflict (mes) where plano_id is null do nothing;
insert into public.plano_fito_mes (plano_id, mes, fase, alvos, produtos, via_solo) values (null, 10, 'Pós-florada', array['phoma', 'antracnose', 'cercospora', 'bicho-mineiro']::text[], array['Mirus', 'Nativo Plus', 'Bayfolan']::text[], array['Verdadero', 'Actara']::text[]) on conflict (mes) where plano_id is null do nothing;
insert into public.plano_fito_excecao (mes, produto, fazenda_app) values (10, 'Vaniva', 'Vereda — Café') on conflict (mes, produto, fazenda_app) do nothing;
insert into public.plano_fito_excecao (mes, produto, fazenda_app) values (10, 'Vaniva', 'Vereda Romaria') on conflict (mes, produto, fazenda_app) do nothing;
insert into public.plano_fito_excecao (mes, produto, fazenda_app) values (10, 'Vaniva', 'Vereda Café 5º e 6º') on conflict (mes, produto, fazenda_app) do nothing;
insert into public.plano_fito_excecao (mes, produto, fazenda_app) values (10, 'Vaniva', 'Água Limpa') on conflict (mes, produto, fazenda_app) do nothing;
insert into public.plano_fito_mes (plano_id, mes, fase, alvos, produtos, via_solo) values (null, 11, 'Fungicida + inseticida', array['ferrugem', 'phoma', 'antracnose', 'broca', 'bicho-mineiro']::text[], array['Mirus', 'Priori Xtra', 'Joiner', 'Ochima']::text[], '{}'::text[]) on conflict (mes) where plano_id is null do nothing;
insert into public.plano_fito_mes (plano_id, mes, fase, alvos, produtos, via_solo) values (null, 12, 'Preventivo', array['bactéria', 'seca', 'cercospora', 'broca']::text[], array['Auge', 'Bravonil']::text[], '{}'::text[]) on conflict (mes) where plano_id is null do nothing;
insert into public.plano_fito_mes (plano_id, mes, fase, alvos, produtos, via_solo) values (null, 1, 'Fungicida + inseticida', array['ferrugem', 'phoma', 'antracnose', 'cercospora', 'broca', 'bicho-mineiro']::text[], array['Mirus', 'Priori Xtra', 'Durivo', 'Vertimec', 'Ochima']::text[], '{}'::text[]) on conflict (mes) where plano_id is null do nothing;
insert into public.plano_fito_mes (plano_id, mes, fase, alvos, produtos, via_solo) values (null, 2, 'Fungicida + inseticida', array['ferrugem', 'phoma', 'antracnose', 'cercospora', 'broca', 'bicho-mineiro']::text[], array['Mirus', 'Priori Xtra', 'Ochima']::text[], array['Actara']::text[]) on conflict (mes) where plano_id is null do nothing;
insert into public.plano_fito_mes (plano_id, mes, fase, alvos, produtos, via_solo) values (null, 3, 'Fungicida + inseticida', array['ferrugem', 'phoma', 'antracnose', 'cercospora', 'broca', 'bicho-mineiro']::text[], array['Mirus', 'Alto 400', 'Joiner', 'Ochima']::text[], '{}'::text[]) on conflict (mes) where plano_id is null do nothing;
insert into public.plano_fito_mes (plano_id, mes, fase, alvos, produtos, via_solo) values (null, 4, 'Fungicida + inseticida', array['phoma', 'antracnose', 'cercospora', 'bicho-mineiro']::text[], array['Mirus', 'Cercobim', 'Orlist']::text[], '{}'::text[]) on conflict (mes) where plano_id is null do nothing;
insert into public.plano_fito_mes (plano_id, mes, fase, alvos, produtos, via_solo) values (null, 5, 'Pós-colheita', '{}'::text[], array['Mirus', 'Auge', 'Bravonil']::text[], '{}'::text[]) on conflict (mes) where plano_id is null do nothing;

-- 9. plano_gantt (modelos NC e NR) ----------------------------------------
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NC', 'analise_solo', array[5, 6]::integer[], 'evento_unico', 'sem chip — o catálogo de atividades do café (LISTA_ATIV) não tem coleta de solo; farol fica cinza', null) on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NC', 'analise_foliar', array[11, 12, 1, 2]::integer[], 'evento_unico', 'sem chip — o catálogo de atividades do café não tem coleta foliar; farol fica cinza', null) on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NC', 'calagem_gessagem', array[9, 10]::integer[], 'evento_unico', 'atividade ''Calagem / gessagem'' por talhão (✔ concluída / ⏳ continua amanhã)', 'Solinftec (distribuidor de calcário) · ERP AgroGestão (t por gleba)') on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NC', 'adubacao_organica', array[9, 10]::integer[], 'janela', 'atividade ''Adubação orgânica'' por talhão', 'ERP AgroGestão (kg por gleba)') on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NC', 'limpeza_sistema_irrigacao', array[9, 10, 3, 4]::integer[], 'janela', 'atividade ''Limpeza do sistema de irrigação''', null) on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NC', 'adubacao_fertirrigacao', array[8, 9, 10, 1, 2, 3, 4]::integer[], 'janela', 'módulo Irrigação (gotejo): ''Fertirrigação hoje? Sim'' + chips de setor (irr.fertSetores)', 'iCrop (setores e lâminas)') on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NC', 'adubacao_lanco', array[9, 10, 11, 12, 1]::integer[], 'janela', 'atividade ''Adubação via lanço'' por talhão', 'Solinftec (adubadeira) · ERP AgroGestão (kg por gleba)') on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NC', 'mip', array[8, 9, 10, 11, 12, 1, 2, 3, 4, 5, 6, 7]::integer[], 'janela', 'atividade ''Monitoramento de pragas (MIP)'' e registros da seção Pragas, doenças e daninhas (fito)', null) on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NC', 'pulverizacao', array[8, 9, 10, 11, 12, 1, 2, 3, 4, 5]::integer[], 'janela', 'atividade ''Pulverização'' por talhão + calda/receita aplicada', 'Solinftec (pulverizador)') on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NC', 'drench', array[10, 11, 1, 2]::integer[], 'janela', 'atividade ''Aplicação via drench / via solo'' por talhão', null) on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NC', 'desbrota', array[10, 11, 12]::integer[], 'janela', 'atividade ''Desbrota'' por talhão com ✔ concluída', null) on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NC', 'capina_manual', array[11, 12, 3, 4]::integer[], 'janela', 'atividade ''Capina manual'' por talhão com ✔ concluída', null) on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NC', 'capina_rocadeira_trincha', array[10, 11, 12, 1, 2, 3]::integer[], 'janela', 'atividade ''Capina roçadeira / trincha'' por talhão', 'Solinftec (roçadeira / trincha)') on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NC', 'herbicida', array[12, 2, 4, 5]::integer[], 'janela', 'atividade ''Aplicação de herbicida'' por talhão', 'Solinftec (pulverizador)') on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NC', 'colheita', array[8, 5, 6, 7]::integer[], 'janela', 'módulo Colheita (registro por talhão) e atividade ''Colheita''', 'Solinftec (colhedora)') on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NC', 'poda', array[8, 9]::integer[], 'evento_unico', 'atividade ''Poda / esqueletamento'' por talhão com ✔ concluída', null) on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NR', 'analise_solo', array[5, 6]::integer[], 'evento_unico', 'sem chip — o catálogo de atividades do café (LISTA_ATIV) não tem coleta de solo; farol fica cinza', null) on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NR', 'analise_foliar', array[11, 12, 1, 2]::integer[], 'evento_unico', 'sem chip — o catálogo de atividades do café não tem coleta foliar; farol fica cinza', null) on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NR', 'calagem_gessagem', array[9, 10]::integer[], 'evento_unico', 'atividade ''Calagem / gessagem'' por talhão (✔ concluída / ⏳ continua amanhã)', 'Solinftec (distribuidor de calcário) · ERP AgroGestão (t por gleba)') on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NR', 'adubacao_organica', array[9, 10]::integer[], 'janela', 'atividade ''Adubação orgânica'' por talhão', 'ERP AgroGestão (kg por gleba)') on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NR', 'limpeza_sistema_irrigacao', array[9, 10]::integer[], 'janela', 'atividade ''Limpeza do sistema de irrigação''', null) on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NR', 'adubacao_fertirrigacao', array[8, 9, 10, 11, 12, 1, 2, 3, 4]::integer[], 'janela', 'módulo Irrigação (gotejo): ''Fertirrigação hoje? Sim'' + chips de setor (irr.fertSetores)', 'iCrop (setores e lâminas)') on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NR', 'adubacao_lanco', array[9, 10, 11, 12]::integer[], 'janela', 'atividade ''Adubação via lanço'' por talhão', 'Solinftec (adubadeira) · ERP AgroGestão (kg por gleba)') on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NR', 'mip', array[8, 9, 10, 11, 12, 1, 2, 3, 4, 5, 6, 7]::integer[], 'janela', 'atividade ''Monitoramento de pragas (MIP)'' e registros da seção Pragas, doenças e daninhas (fito)', null) on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NR', 'pulverizacao', array[8, 9, 10, 11, 12, 1, 2, 3, 4, 5]::integer[], 'janela', 'atividade ''Pulverização'' por talhão + calda/receita aplicada', 'Solinftec (pulverizador)') on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NR', 'drench', array[10, 11, 1, 2]::integer[], 'janela', 'atividade ''Aplicação via drench / via solo'' por talhão', null) on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NR', 'desbrota', array[10, 11, 12]::integer[], 'janela', 'atividade ''Desbrota'' por talhão com ✔ concluída', null) on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NR', 'capina_manual', array[11, 12, 3, 4]::integer[], 'janela', 'atividade ''Capina manual'' por talhão com ✔ concluída', null) on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NR', 'capina_rocadeira_trincha', array[10, 11, 12, 1, 2, 3]::integer[], 'janela', 'atividade ''Capina roçadeira / trincha'' por talhão', 'Solinftec (roçadeira / trincha)') on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NR', 'herbicida', array[12, 4, 5]::integer[], 'janela', 'atividade ''Aplicação de herbicida'' por talhão', 'Solinftec (pulverizador)') on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NR', 'colheita', array[8, 5, 6, 7]::integer[], 'janela', 'módulo Colheita (registro por talhão) e atividade ''Colheita''', 'Solinftec (colhedora)') on conflict (modelo, atividade) do nothing;
insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values ('NR', 'poda', array[8, 9]::integer[], 'evento_unico', 'atividade ''Poda / esqueletamento'' por talhão com ✔ concluída', null) on conflict (modelo, atividade) do nothing;

-- 10. plano_parametros (editáveis pelo ADMIN) -------------------------------
insert into public.plano_parametros (chave, valor, descricao) values ('fito_dias_sem_monitoramento', '10', 'Dias sem monitoramento de um alvo previsto no mês para o farol Fito ficar amarelo') on conflict (chave) do nothing;
insert into public.plano_parametros (chave, valor, descricao) values ('gantt_pct_janela_amarelo', '60', '% da janela decorrida sem registro para o farol Gantt ficar amarelo') on conflict (chave) do nothing;
insert into public.plano_parametros (chave, valor, descricao) values ('adubo_dia_limite_cadencia', '20', 'Dia do mês até o qual se espera o 1º registro de fertirrigação/adubação (e a 1ª pulverização nos meses de fungicida + inseticida)') on conflict (chave) do nothing;
insert into public.plano_parametros (chave, valor, descricao) values ('poda_data_limite', '2026-09-30', 'Data-limite para o chip de poda ✔ nas unidades com status poda') on conflict (chave) do nothing;
insert into public.plano_parametros (chave, valor, descricao) values ('desbrota_data_limite', '2026-12-31', 'Data-limite para o chip de desbrota ✔ nas unidades com status poda') on conflict (chave) do nothing;
insert into public.plano_parametros (chave, valor, descricao) values ('chumbinho_meses', '10,11,12', 'Meses em que o chip "chumbinho visível" aparece no bloco Clima (fase B)') on conflict (chave) do nothing;

-- 11. CONFERÊNCIA — se algo não bater, desfaz a carga inteira ---------------
do $$
declare n_dif integer; n_uni integer; n_adubo integer; n_cal integer; t_cal numeric;
begin
  select count(*) into n_dif from (values
    ('Lagamar Café (Rodrigo)', 'ureia', 40000),
    ('Lagamar Café (Rodrigo)', 'nitrato', 169500),
    ('Lagamar Café (Rodrigo)', 'sulfato_amonio', 76500),
    ('Lagamar Café (Rodrigo)', 'kcl', 105000),
    ('Lagamar Café (Rodrigo)', 'phusion', 0),
    ('Lagamar Café (Rodrigo)', 'sulfato_mn', 2700),
    ('Lagamar Café (Rodrigo)', 'acido_borico', 5800),
    ('Lagamar Café (Rodrigo)', 'sulfato_zn', 3250),
    ('Mata Preta — Café', 'ureia', 31000),
    ('Mata Preta — Café', 'nitrato', 124000),
    ('Mata Preta — Café', 'sulfato_amonio', 57000),
    ('Mata Preta — Café', 'kcl', 86000),
    ('Mata Preta — Café', 'phusion', 9000),
    ('Mata Preta — Café', 'sulfato_mn', 2050),
    ('Mata Preta — Café', 'acido_borico', 4300),
    ('Mata Preta — Café', 'sulfato_zn', 2425),
    ('Monte Carmelo — Café', 'ureia', 61500),
    ('Monte Carmelo — Café', 'nitrato', 251000),
    ('Monte Carmelo — Café', 'sulfato_amonio', 115000),
    ('Monte Carmelo — Café', 'kcl', 211000),
    ('Monte Carmelo — Café', 'phusion', 32500),
    ('Monte Carmelo — Café', 'sulfato_mn', 4050),
    ('Monte Carmelo — Café', 'acido_borico', 8600),
    ('Monte Carmelo — Café', 'sulfato_zn', 4825),
    ('Rio Preto-Lagamar — Café', 'ureia', 55000),
    ('Rio Preto-Lagamar — Café', 'nitrato', 223500),
    ('Rio Preto-Lagamar — Café', 'sulfato_amonio', 101000),
    ('Rio Preto-Lagamar — Café', 'kcl', 150000),
    ('Rio Preto-Lagamar — Café', 'phusion', 0),
    ('Rio Preto-Lagamar — Café', 'sulfato_mn', 3525),
    ('Rio Preto-Lagamar — Café', 'acido_borico', 7650),
    ('Rio Preto-Lagamar — Café', 'sulfato_zn', 4425),
    ('Vereda Café 5º e 6º', 'ureia', 23500),
    ('Vereda Café 5º e 6º', 'nitrato', 101000),
    ('Vereda Café 5º e 6º', 'sulfato_amonio', 45500),
    ('Vereda Café 5º e 6º', 'kcl', 91000),
    ('Vereda Café 5º e 6º', 'phusion', 0),
    ('Vereda Café 5º e 6º', 'sulfato_mn', 1550),
    ('Vereda Café 5º e 6º', 'acido_borico', 3500),
    ('Vereda Café 5º e 6º', 'sulfato_zn', 1950),
    ('Vereda Romaria', 'ureia', 34500),
    ('Vereda Romaria', 'nitrato', 136000),
    ('Vereda Romaria', 'sulfato_amonio', 60500),
    ('Vereda Romaria', 'kcl', 177000),
    ('Vereda Romaria', 'phusion', 4500),
    ('Vereda Romaria', 'sulfato_mn', 2100),
    ('Vereda Romaria', 'acido_borico', 4950),
    ('Vereda Romaria', 'sulfato_zn', 2600),
    ('Vereda — Café', 'ureia', 71000),
    ('Vereda — Café', 'nitrato', 306000),
    ('Vereda — Café', 'sulfato_amonio', 163500),
    ('Vereda — Café', 'kcl', 369000),
    ('Vereda — Café', 'phusion', 3500),
    ('Vereda — Café', 'sulfato_mn', 4700),
    ('Vereda — Café', 'acido_borico', 10625),
    ('Vereda — Café', 'sulfato_zn', 6125),
    ('Água Limpa', 'ureia', 17000),
    ('Água Limpa', 'nitrato', 74000),
    ('Água Limpa', 'sulfato_amonio', 33000),
    ('Água Limpa', 'kcl', 77500),
    ('Água Limpa', 'phusion', 2000),
    ('Água Limpa', 'sulfato_mn', 1175),
    ('Água Limpa', 'acido_borico', 2500),
    ('Água Limpa', 'sulfato_zn', 1500)
  ) as e(fz, ins, kg)
  left join (select p.fazenda_app fz, a.insumo ins, sum(a.kg) kg from public.plano_adubo_mes a
      join public.plano_safra p on p.id = a.plano_id where p.safra = '2026/27' and p.versao = 1 group by 1, 2) s
    on s.fz = e.fz and s.ins = e.ins
  where coalesce(s.kg, 0) <> e.kg;
  if n_dif > 0 then raise exception 'seed do plano 2026/27: % soma(s) de kg por fazenda/insumo não bateram — carga desfeita', n_dif; end if;
  select count(*) into n_uni from public.unidade_manejo where codigo in ('VEC-S01', 'VEC-S02', 'VEC-S03', 'VEC-S04', 'VEC-S05', 'VEC-S06', 'VEC-S07', 'VEC-S08', 'VEC-S09', 'VEC-P02', 'VEC-P06', 'RPL-1P-S01', 'RPL-1P-S02', 'RPL-1P-S03', 'RPL-1P-S04', 'RPL-1P-S05', 'RPL-1P-S06', 'RPL-2P-S01', 'RPL-2P-S02', 'RPL-2P-S03', 'RPL-2P-S04', 'RPL-2P-S05', 'RPL-2P-S06', 'ROM-S01B', 'ROM-S01', 'ROM-S02', 'ROM-S03', 'ROM-S04', 'ROM-S05', 'ROM-S06', 'ROM-S07', 'ROM-S08', 'V56-5PA', 'V56-5CA', 'V56-5BX', 'V56-6MN', 'V56-6IPR', 'AGL-T1', 'AGL-T2B', 'AGL-T2C', 'AGL-T3', 'AGL-T4', 'MCC-CXT', 'MCC-CXR', 'MCC-CXP', 'MCC-S01', 'MCC-S02', 'MCC-S03', 'MCC-S04', 'MCC-S05', 'MCC-S06', 'MCC-S07', 'MCC-S08', 'MCC-ERA', 'MCC-ERB', 'LAG-S01', 'LAG-S02', 'LAG-S03', 'LAG-S04', 'LAG-S05', 'LAG-S06', 'LAG-JX', 'MTP-S01', 'MTP-S02', 'MTP-S03', 'MTP-S04', 'MTP-S05', 'MTP-P26', 'MTP-3PT');
  if n_uni <> 69 then raise exception 'seed do plano: % unidades gravadas (esperado 69) — carga desfeita', n_uni; end if;
  select count(*) into n_adubo from public.plano_adubo_mes a join public.plano_safra p on p.id = a.plano_id where p.safra = '2026/27' and p.versao = 1;
  if n_adubo <> 1533 then raise exception 'seed do plano: % linhas de adubo (esperado 1533) — carga desfeita', n_adubo; end if;
  select count(*), coalesce(sum(t_total), 0) into n_cal, t_cal from public.plano_calagem c join public.plano_safra p on p.id = c.plano_id where p.safra = '2026/27' and p.versao = 1;
  if n_cal <> 71 or t_cal <> 4648 then raise exception 'seed do plano: calagem % linhas / % t (esperado 71 / 4648) — carga desfeita', n_cal, t_cal; end if;
  raise notice 'plano 2026/27 carregado: % unidades, % linhas de adubo, % linhas de calagem (% t)', n_uni, n_adubo, n_cal, t_cal;
end $$;

commit;
