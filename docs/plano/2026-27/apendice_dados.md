# APÊNDICE 1 — Dados do plano de safra 2026/27 (fonte única)

Cópia literal do Apêndice 1 do pedido de 03/09/2026 (7 PPTX do agrônomo,
extraídos por XML). É a ÚNICA fonte de dados do plano: nada aqui foi
inventado, completado ou corrigido — o que estava ausente fica nulo.
Este arquivo é lido por `scripts/expandir_apendice_plano.py`, que gera
`plano_2627_seed.json`. Nunca edite os dois separadamente.

### FAZENDAS  (fazenda_app | empresa | modelo_gantt | deck)
Vereda Café | NC Naves | NC | Vereda_NC_NAVES_safra_26_27.pptx
Rio Preto-Lagamar — Café | NC Naves | NC | Rio_Preto_NC_NAVES_safra_26_27.pptx
Vereda Romaria | NC Naves | NC | Romaria_NC_NAVES_safra__26_27.pptx
Vereda Café 5º e 6º | NC Naves | NC | Romaria_NC_NAVES_safra__26_27.pptx
Água Limpa | NC Naves | NC | A___Limpa_NC_NAVES_safra_26_27.pptx
Monte Carmelo — Café | NC Naves | NC | MC_Caxico__NC_NAVES_safra_26_27.pptx
Lagamar Café – Rodrigo | NR Agropecuária | NR | NR_Lagamar_safra_26_27.pptx
Mata Preta - Café | NR Agropecuária | NR | NR_Mata_Preta_safra_26_27.pptx

### UNIDADES  (codigo | fazenda_app | nome_plano | aliases_plano separados por ; | area_ha | fonte_area | safra_zerada_tipo | area_zerada_ha | pai | obs)
VEC-S01 | Vereda Café | Setor 01 | Vereda setor 01;setor 01 Vereda | 16 | estimativa | poda | 16 |  | Zn set 150 vs 75 nos outros meses (conferir)
VEC-S02 | Vereda Café | Setor 02 | Vereda setor 02;setor 02 Vereda | 23 | estimativa |  | 0 |  | 
VEC-S03 | Vereda Café | Setor 03 | Vereda setor 03;setor 03 Vereda | 20 | estimativa |  | 0 |  | calcário implica 21 ha
VEC-S04 | Vereda Café | Setor 04 | Vereda setor 04;setor 04 Vereda | 18 | estimativa |  | 0 |  | 
VEC-S05 | Vereda Café | Setor 05 | Vereda setor 05;setor 05 Vereda | 18 | estimativa |  | 0 |  | 
VEC-S06 | Vereda Café | Setor 06 | Vereda setor 06;setor 06 Vereda | 21 | estimativa | poda | 11 |  | 
VEC-S07 | Vereda Café | Setor 07 | Vereda setor 07;setor 07 Vereda | 19 | estimativa |  | 0 |  | KCl = 0 o ano todo (conferir com agrônomo)
VEC-S08 | Vereda Café | Setor 08 | Vereda 08 alto;Vereda 08 baixo;setor 08 Vereda | 59 | estimativa |  | 0 |  | SO4 amônia 21000+21000 kg (712 kg/ha, 2x o padrão) — provável erro; resumo da fazenda fecha com ~17500
VEC-S09 | Vereda Café | Setor 9 | Vereda setor 09;setor 09 Vereda | 14 | estimativa |  | 0 |  | sem uréia; nada de mar a jul (plantio novo?)
VEC-P02 | Vereda Café | Pivô 2 | Vereda pivô 02 t01;Vereda pivô 02 t02;Vereda pivô 02 t03;Pivô 02 Vereda | 120 | estimativa |  | 0 |  | calagem cobre 109 ha (26+27+56), não 120
VEC-P06 | Vereda Café | Pivô 6 | Vereda pivô 06 t01;Vereda pivô 06 t02;Pivô 06 Vereda | 53 | estimativa |  | 0 |  | calagem t01/t02 idêntica à do pivô 2 (cópia?)
RPL-1P-S01 | Rio Preto-Lagamar — Café | Setor 01 | St01 1º plantio;1º plantio st01 | 16 | estimativa |  | 0 |  | 
RPL-1P-S02 | Rio Preto-Lagamar — Café | Setor 02 | St02 1º plantio;1º plantio st02 | 16 | estimativa |  | 0 |  | 
RPL-1P-S03 | Rio Preto-Lagamar — Café | Setor 03 | St03 1º plantio;1º plantio st03 | 16 | estimativa |  | 0 |  | 
RPL-1P-S04 | Rio Preto-Lagamar — Café | Setor 04 | St04 1º plantio;1º plantio st04 | 16 | estimativa |  | 0 |  | 
RPL-1P-S05 | Rio Preto-Lagamar — Café | Setor 05 | St05 1º plantio;1º plantio st05 | 16 | estimativa |  | 0 |  | 
RPL-1P-S06 | Rio Preto-Lagamar — Café | Setor 06 | St06 1º plantio;1º plantio st06 | 19 | estimativa |  | 0 |  | calcário implica 20 ha
RPL-2P-S01 | Rio Preto-Lagamar — Café | 2º plantio st01 | 2º plantio st01;2º Plantio 180 hectares | 30 | calcario_rateado | em_branco |  |  | 180 ha ÷ 6 (bloco único na calagem); não está na estimativa
RPL-2P-S02 | Rio Preto-Lagamar — Café | 2º plantio st02 | 2º plantio st02;2º Plantio 180 hectares | 30 | calcario_rateado | em_branco |  |  | 180 ha ÷ 6 (bloco único na calagem); não está na estimativa
RPL-2P-S03 | Rio Preto-Lagamar — Café | 2º plantio st03 | 2º plantio st03;2º Plantio 180 hectares | 30 | calcario_rateado | em_branco |  |  | 180 ha ÷ 6 (bloco único na calagem); não está na estimativa
RPL-2P-S04 | Rio Preto-Lagamar — Café | 2º plantio st04 | 2º plantio st04;2º Plantio 180 hectares | 30 | calcario_rateado | em_branco |  |  | 180 ha ÷ 6 (bloco único na calagem); não está na estimativa
RPL-2P-S05 | Rio Preto-Lagamar — Café | 2º plantio st05 | 2º plantio st05;2º Plantio 180 hectares | 30 | calcario_rateado | em_branco |  |  | 180 ha ÷ 6 (bloco único na calagem); não está na estimativa
RPL-2P-S06 | Rio Preto-Lagamar — Café | 2º plantio st06 | 2º plantio st06;2º Plantio 180 hectares | 30 | calcario_rateado | em_branco |  |  | 180 ha ÷ 6 (bloco único na calagem); não está na estimativa
ROM-S01B | Vereda Romaria | Romaria 01 b |  | 7 | estimativa |  | 0 | ROM-S01 | sem calagem nem calendário próprios; contido em "Romaria setor 01" (21 ha)
ROM-S01 | Vereda Romaria | Romaria 01 | Romaria setor 01;setor 01 Romaria | 14 | estimativa |  | 0 |  | calagem e calendário cobrem 01 + 01b (21 ha); Phusion out "4500 no café 2º"
ROM-S02 | Vereda Romaria | Romaria 02 | Romaria setor 02;setor 02 Romaria | 21 | estimativa |  | 0 |  | 
ROM-S03 | Vereda Romaria | Romaria 03 | Romaria setor 03;setor 03 Romaria | 25 | estimativa |  | 0 |  | 
ROM-S04 | Vereda Romaria | Romaria 04 | Romaria setor 04;setor 04 Romaria | 25 | estimativa |  | 0 |  | 
ROM-S05 | Vereda Romaria | Romaria 05 | Romaria setor 05;setor 05 Romaria | 20 | estimativa |  | 0 |  | 
ROM-S06 | Vereda Romaria | Romaria 06 | Romaria setor 06;setor 06 Romaria | 20 | estimativa |  | 0 |  | 
ROM-S07 | Vereda Romaria | Romaria 07 | Romaria setor 07;setor 07 Romaria | 20 | estimativa |  | 0 |  | 
ROM-S08 | Vereda Romaria | Romaria 08 | Romaria setor 08;setor 08 Romaria | 12 | estimativa | poda | 2 |  | 
V56-5PA | Vereda Café 5º e 6º | 5º Paraíso | Café 5º Paraíso;5º paraíso (st 01,02,03) | 34 | estimativa | poda | 34 |  | 3 setores de irrigação; calcário implica 33 ha
V56-5CA | Vereda Café 5º e 6º | 5º Catucaí | Café 5º Catucaí;5º Catucaí (st 04,05) | 23 | estimativa | poda | 23 |  | calcário implica 22 ha
V56-5BX | Vereda Café 5º e 6º | 5º café novo | Café 5º novo;5º baixada (st 06,07) | 22 | estimativa |  | 0 |  | 3 nomes para a mesma área
V56-6MN | Vereda Café 5º e 6º | 6º M Novo | Café 6º renovação;6º Catuaí | 24 | estimativa | a_confirmar |  |  | 3 nomes e cultivares contraditórias; "renovação" no nome mas coluna vazia — PERGUNTAR
V56-6IPR | Vereda Café 5º e 6º | 6º IPR 100 + 99 | Café 6º IPR 100/ CT 99;6º IPR100 | 30 | estimativa |  | 0 |  | 
AGL-T1 | Água Limpa | T1 Catuaí / IBC | T1 Catuaí / IBC (setor 04);Água Limpa talhão Catucaí 01 | 11 | estimativa | poda | 2 |  | Catuaí × Catucaí entre slides — PERGUNTAR
AGL-T2B | Água Limpa | T2 casinha para baixo | T2 casinha para baixo (setores 7 e 8);talhão 02 casinha para baixo | 24 | estimativa |  | 0 |  | 
AGL-T2C | Água Limpa | T2 casinha para cima | T3 casinha para cima (setores 5 e 6);talhão 02 casinha para cima | 24 | estimativa | poda | 24 |  | numeração muda entre slides (T2/T3)
AGL-T3 | Água Limpa | T3 2º LD | T4 2º LD (setor 02);talhão 03 (2º LD) | 11 | estimativa |  | 0 |  | numeração muda entre slides (T3/T4)
AGL-T4 | Água Limpa | T4 1º e 3º LD | T5 1º e 3º LD (setores 1 e 3);talhão 04 (1º e 3º LD) | 22 | estimativa |  | 0 |  | 1 unidade = 2 setores de irrigação; numeração T4/T5
MCC-CXT | Monte Carmelo — Café | Caxico Topázio | Caxico topázio | 27 | calcario | em_branco |  |  | 
MCC-CXR | Monte Carmelo — Café | Caxico M Novo recepa | Caxico Mundo novo recepa | 29 | calcario | a_confirmar |  |  | "recepa" no nome, coluna vazia — PERGUNTAR
MCC-CXP | Monte Carmelo — Café | Caxico represa | Caxico represa (Mundo novo e Catuaí99) | 27 | calcario | em_branco |  |  | KCl 1407 kg/ha, o maior do grupo
MCC-S01 | Monte Carmelo — Café | M. Carmelo st01 | Monte Carmelo st01 | 15 | calcario | em_branco |  |  | 
MCC-S02 | Monte Carmelo — Café | M. Carmelo st02 | Monte Carmelo st02 | 15 | calcario | em_branco |  |  | 
MCC-S03 | Monte Carmelo — Café | M. Carmelo st03 | Monte Carmelo st03 | 15 | calcario | em_branco |  |  | 
MCC-S04 | Monte Carmelo — Café | M. Carmelo st04 | Monte Carmelo st04 | 15 | calcario | em_branco |  |  | 
MCC-S05 | Monte Carmelo — Café | M. Carmelo st05 | Monte Carmelo st05 | 15 | calcario | em_branco |  |  | 
MCC-S06 | Monte Carmelo — Café | M. Carmelo st06 | Monte Carmelo st06 | 15 | calcario | em_branco |  |  | 
MCC-S07 | Monte Carmelo — Café | M. Carmelo st07 | Monte Carmelo st07 | 15 | calcario | em_branco |  |  | 
MCC-S08 | Monte Carmelo — Café | M. Carmelo st08 | Monte Carmelo st08 | 15 | calcario | em_branco |  |  | 
MCC-ERA | Monte Carmelo — Café | Sr. Ernani alto |  | 50 | calcario | em_branco |  |  | 2,4 t/ha de fontes de N (padrão 1,35) — conferir área
MCC-ERB | Monte Carmelo — Café | Sr. Ernani baixo |  | 25 | calcario | em_branco |  |  | 
LAG-S01 | Lagamar Café – Rodrigo | Setor 01 | setor 01 | 24 | calcario | em_branco |  |  | 
LAG-S02 | Lagamar Café – Rodrigo | Setor 02 | setor 02 | 24 | calcario | em_branco |  |  | 
LAG-S03 | Lagamar Café – Rodrigo | Setor 03 | setor 03 | 24 | calcario | em_branco |  |  | 
LAG-S04 | Lagamar Café – Rodrigo | Setor 04 | setor 04 | 21 | calcario | em_branco |  |  | KCl 190 kg/ha, parcela única em jan
LAG-S05 | Lagamar Café – Rodrigo | Setor 05 | setor 05 | 21 | calcario | em_branco |  |  | 
LAG-S06 | Lagamar Café – Rodrigo | Setor 06 | setor 06 | 21 | calcario | em_branco |  |  | KCl 190 kg/ha, parcela única em jan
LAG-JX | Lagamar Café – Rodrigo | João Xavier | Joao Xavier | 26 | calcario |  | 0 |  | não está na estimativa
MTP-S01 | Mata Preta - Café | Setor 01 | setor 01 | 19 | calcario |  | 0 |  | 
MTP-S02 | Mata Preta - Café | Setor 02 | setor 02 | 19 | calcario |  | 0 |  | 
MTP-S03 | Mata Preta - Café | Setor 03 | setor 03 | 20 | calcario |  | 0 |  | 
MTP-S04 | Mata Preta - Café | Setor 04 | setor 04 | 20 | calcario |  | 0 |  | 
MTP-S05 | Mata Preta - Café | Setor 05 | setor 05 | 20 | calcario |  | 0 |  | 
MTP-P26 | Mata Preta - Café | Plantio 2026 |  | 45 | calcario | plantio | 45 |  | só na calagem; sem calendário de adubação
MTP-3PT | Mata Preta - Café | 3º plantio (torres) |  |  |  |  | 0 |  | só no calendário; sem calagem; maior programa do deck — PERGUNTAR área e identidade

### CALAGEM  (codigo | subarea | t_ha | t_total | rateado)
VEC-S01 | Vereda setor 01 | 3 | 48 | não
VEC-S02 | Vereda setor 02 | 3 | 69 | não
VEC-S03 | Vereda setor 03 | 2 | 42 | não
VEC-S04 | Vereda setor 04 | 3 | 54 | não
VEC-S05 | Vereda setor 05 | 3 | 54 | não
VEC-S06 | Vereda setor 06 | 2 | 42 | não
VEC-S07 | Vereda setor 07 | 3 | 57 | não
VEC-S08 | Vereda 08 alto | 4 | 120 | não
VEC-S08 | Vereda 08 baixo | 2 | 58 | não
VEC-S09 | Vereda setor 09 | 3 | 42 | não
VEC-P02 | Vereda pivô 02 t01 | 4 | 104 | não
VEC-P02 | Vereda pivô 02 t02 | 5 | 135 | não
VEC-P02 | Vereda pivô 02 t03 | 4 | 224 | não
VEC-P06 | Vereda pivô 06 t01 | 4 | 104 | não
VEC-P06 | Vereda pivô 06 t02 | 5 | 135 | não
RPL-1P-S01 | St01 1º plantio | 3 | 48 | não
RPL-1P-S02 | St02 1º plantio | 3 | 48 | não
RPL-1P-S03 | St03 1º plantio | 3 | 48 | não
RPL-1P-S04 | St04 1º plantio | 2 | 32 | não
RPL-1P-S05 | St05 1º plantio | 2 | 32 | não
RPL-1P-S06 | St06 1º plantio | 4 | 80 | não
RPL-2P-S01 | 2º Plantio 180 hectares (bloco ÷ 6) | 2 | 60 | sim
RPL-2P-S02 | 2º Plantio 180 hectares (bloco ÷ 6) | 2 | 60 | sim
RPL-2P-S03 | 2º Plantio 180 hectares (bloco ÷ 6) | 2 | 60 | sim
RPL-2P-S04 | 2º Plantio 180 hectares (bloco ÷ 6) | 2 | 60 | sim
RPL-2P-S05 | 2º Plantio 180 hectares (bloco ÷ 6) | 2 | 60 | sim
RPL-2P-S06 | 2º Plantio 180 hectares (bloco ÷ 6) | 2 | 60 | sim
ROM-S01 | Romaria setor 01 | 4 | 84 | não
ROM-S02 | Romaria setor 02 | 3 | 63 | não
ROM-S03 | Romaria setor 03 | 2 | 50 | não
ROM-S04 | Romaria setor 04 | 2 | 50 | não
ROM-S05 | Romaria setor 05 | 4 | 80 | não
ROM-S06 | Romaria setor 06 | 3 | 60 | não
ROM-S07 | Romaria setor 07 | 3 | 60 | não
ROM-S08 | Romaria setor 08 | 4 | 48 | não
V56-5PA | Café 5º Paraíso | 3 | 99 | não
V56-5CA | Café 5º Catucaí | 4 | 88 | não
V56-5BX | Café 5º novo | 2 | 44 | não
V56-6MN | Café 6º renovação | 2 | 48 | não
V56-6IPR | Café 6º IPR 100/ CT 99 | 2 | 60 | não
AGL-T1 | T1 Catuaí / IBC (setor 04) | 3 | 33 | não
AGL-T2B | T2 casinha para baixo (setores 7 e 8) | 3 | 72 | não
AGL-T2C | T3 casinha para cima (setores 5 e 6) | 3 | 72 | não
AGL-T3 | T4 2º LD (setor 02) | 5 | 55 | não
AGL-T4 | T5 1º e 3º LD (setores 1 e 3) | 4 | 88 | não
MCC-CXT | Caxico Topázio | 4 | 108 | não
MCC-CXR | Caxico M Novo recepa | 3 | 87 | não
MCC-CXP | Caxico represa | 2 | 54 | não
MCC-S01 | M. Carmelo st01 | 3 | 45 | não
MCC-S02 | M. Carmelo st02 | 1 | 15 | não
MCC-S03 | M. Carmelo st03 | 1 | 15 | não
MCC-S04 | M. Carmelo st04 | 2 | 30 | não
MCC-S05 | M. Carmelo st05 | 2 | 30 | não
MCC-S06 | M. Carmelo st06 | 2 | 30 | não
MCC-S07 | M. Carmelo st07 | 2 | 30 | não
MCC-S08 | M. Carmelo st08 | 2 | 30 | não
MCC-ERA | Sr. Ernani alto | 3 | 150 | não
MCC-ERB | Sr. Ernani baixo | 3 | 75 | não
LAG-S01 | setor 01 | 3 | 72 | não
LAG-S02 | setor 02 | 5 | 120 | não
LAG-S03 | setor 03 | 5 | 120 | não
LAG-S04 | setor 04 | 3 | 63 | não
LAG-S05 | setor 05 | 3 | 63 | não
LAG-S06 | setor 06 | 3 | 63 | não
LAG-JX | Joao Xavier | 2 | 52 | não
MTP-S01 | setor 01 | 2 | 38 | não
MTP-S02 | setor 02 | 2 | 38 | não
MTP-S03 | setor 03 | 2 | 40 | não
MTP-S04 | setor 04 | 2 | 40 | não
MTP-S05 | setor 05 | 3 | 60 | não
MTP-P26 | Plantio 2026 | 2 | 90 | não

### ADUBO_MES  (codigo | mes:insumo=kg,insumo=kg;mes:... — insumos U=ureia Ni=nitrato SA=sulfato_amonio K=kcl Ph=phusion Mn=sulfato_mn B=acido_borico Zn=sulfato_zn; obs entre parênteses; meses ausentes = sem adubação)
VEC-S01 | 9:U=500,K=3000,Mn=75,B=150,Zn=150;10:SA=3000;11:SA=3000,K=2000,Mn=75,B=150,Zn=75;12:Ni=4500;1:Ni=4000,K=2000,Mn=50,B=125,Zn=75;2:Ni=4000;3:U=500;4:U=500;5:U=500;6:U=500;7:U=500
VEC-S02 | 9:U=1000,K=9000,Mn=100,B=250,Zn=150;10:SA=4000;11:SA=4000,K=9000,Mn=100,B=200,Zn=100;12:Ni=6000;1:Ni=6000,K=3000,Mn=100,B=200,Zn=100;2:Ni=6000;3:U=1000;4:U=1000;5:U=500;6:U=500;7:U=500
VEC-S03 | 9:U=1000,K=5000,Mn=100,B=200,Zn=125;10:SA=4000;11:SA=3500,Mn=100,B=200,Zn=100;12:Ni=6500;1:Ni=5000,K=5000,Mn=50,B=200,Zn=100;2:Ni=5000;3:U=1000;4:U=500;5:U=500;6:U=500;7:U=500
VEC-S04 | 9:U=1000,K=9000,Mn=75,B=200,Zn=150;10:SA=3500;11:SA=3000,K=9000,Mn=75,B=150,Zn=125;12:Ni=5000;1:Ni=5000,K=3000,Mn=75,B=150,Zn=100;2:Ni=4000;3:U=500;4:U=500;5:U=500;6:U=500;7:U=500
VEC-S05 | 9:U=1000,K=8000,Mn=100,B=200,Zn=125;10:SA=4000,Ph=3500;11:SA=3500,Mn=75,B=200,Zn=100;12:Ni=6500;1:Ni=5000,K=3000,Mn=75,B=200,Zn=100;2:Ni=5000;3:U=1000;4:U=500;5:U=500;6:U=500;7:U=500
VEC-S06 | 9:U=1000,K=9000,Mn=75,B=175,Zn=100;10:SA=4000;11:SA=3000,K=9000,Mn=75,B=175,Zn=100;12:Ni=5000;1:Ni=5000,K=8000,Mn=75,B=175,Zn=100;2:Ni=5000;3:U=500;4:U=500;5:U=500;6:U=500;7:U=500
VEC-S07 | 9:U=1000,Mn=75,B=175,Zn=100;10:SA=4000;11:SA=3000,Mn=75,B=175,Zn=100;12:Ni=5000;1:Ni=5000,Mn=75,B=175,Zn=100;2:Ni=5000;3:U=500;4:U=500;5:U=500;6:U=500;7:U=500
VEC-S08 | 9:U=2000,K=19000,Mn=250,B=550,Zn=300;10:SA=21000;11:SA=21000,K=19000,Mn=250,B=550,Zn=300;12:Ni=16000;1:Ni=16000,K=18000,Mn=200,B=500,Zn=300;2:Ni=14500;3:U=2000;4:U=2000;5:U=2000;6:U=2000;7:U=1000
VEC-S09 | 9:K=7000,Mn=75,B=150,Zn=75;10:SA=4000;11:SA=4000,K=7000,Mn=75,B=150,Zn=75;12:Ni=4000;1:Ni=4000,K=4000,Mn=50,B=100,Zn=75;2:Ni=4000
VEC-P02 | 9:U=4000,K=60000,Mn=500,B=1150,Zn=650;10:SA=25000;11:SA=20000,K=60000,Mn=500,B=1100,Zn=650;12:Ni=33000;1:Ni=33000,K=24000,Mn=500,B=1100,Zn=600;2:Ni=33000;3:U=4000;4:U=4000;5:U=4000;6:U=4000;7:U=4000
VEC-P06 | 9:U=2000,K=22000,Mn=225,B=500,Zn=275;10:SA=10000;11:SA=9000,K=22000,Mn=200,B=500,Zn=275;12:Ni=14000;1:Ni=14000,K=11000,Mn=200,B=450,Zn=275;2:Ni=13000;3:U=2000;4:U=2000;5:U=2000;6:U=1000;7:U=1000
RPL-1P-S01 | 9:U=1000,K=7000,Mn=100,B=200,Zn=125;10:SA=4000;11:SA=4000,K=7000,Mn=100,B=200,Zn=125;12:Ni=6000;1:Ni=6000,K=4000,Mn=75,B=200,Zn=100;2:Ni=5500;3:U=1000;4:U=1000;5:U=500;6:U=500;7:U=500
RPL-1P-S02 | 9:U=1000,K=7000,Mn=100,B=200,Zn=125;10:SA=4000;11:SA=4000,K=7000,Mn=100,B=200,Zn=125;12:Ni=6000;1:Ni=6000,K=4000,Mn=75,B=200,Zn=100;2:Ni=5500;3:U=1000;4:U=1000;5:U=500;6:U=500;7:U=500
RPL-1P-S03 | 9:U=1000,K=7000,Mn=100,B=200,Zn=125;10:SA=4000;11:SA=4000,K=7000,Mn=100,B=200,Zn=125;12:Ni=6000;1:Ni=6000,K=4000,Mn=75,B=200,Zn=100;2:Ni=5500;3:U=1000;4:U=1000;5:U=500;6:U=500;7:U=500
RPL-1P-S04 | 9:U=1000,K=6000,Mn=100,B=200,Zn=125;10:SA=4000;11:SA=4000,K=6000,Mn=100,B=200,Zn=125;12:Ni=6000;1:Ni=6000,K=3000,Mn=75,B=200,Zn=100;2:Ni=5500;3:U=1000;4:U=1000;5:U=500;6:U=500;7:U=500
RPL-1P-S05 | 9:U=1000,K=6000,Mn=100,B=200,Zn=125;10:SA=4000;11:SA=4000,K=6000,Mn=100,B=200,Zn=125;12:Ni=6000;1:Ni=6000,K=3000,Mn=75,B=200,Zn=100;2:Ni=5500;3:U=1000;4:U=1000;5:U=500;6:U=500;7:U=500
RPL-1P-S06 | 9:U=1000,K=9000,Mn=125,B=250,Zn=150;10:SA=5000;11:SA=5000,K=9000,Mn=125,B=250,Zn=150;12:Ni=8000;1:Ni=7000,K=6000,Mn=100,B=250,Zn=125;2:Ni=7000;3:U=1000;4:U=1000;5:U=1000;6:U=1000;7:U=500
RPL-2P-S01 | 9:U=1000,K=3000,Mn=100,B=225,Zn=125;10:SA=4500;11:SA=4000,K=2000,Mn=100,B=225,Zn=125;12:Ni=7000;1:Ni=6000,K=2000,Mn=100,B=200,Zn=125;2:Ni=6000;3:U=1000;4:U=1000;5:U=500;6:U=500;7:U=500
RPL-2P-S02 | 9:U=1000,K=3000,Mn=100,B=225,Zn=125;10:SA=4500;11:SA=4000,K=2000,Mn=100,B=225,Zn=125;12:Ni=7000;1:Ni=6000,K=2000,Mn=100,B=200,Zn=125;2:Ni=6000;3:U=1000;4:U=1000;5:U=500;6:U=500;7:U=500
RPL-2P-S03 | 9:U=1000,K=3000,Mn=100,B=225,Zn=125;10:SA=4500;11:SA=4000,K=2000,Mn=100,B=225,Zn=125;12:Ni=7000;1:Ni=6000,K=2000,Mn=100,B=200,Zn=125;2:Ni=6000;3:U=1000;4:U=1000;5:U=500;6:U=500;7:U=500
RPL-2P-S04 | 9:U=1000,K=3000,Mn=100,B=225,Zn=125;10:SA=4500;11:SA=4000,K=2000,Mn=100,B=225,Zn=125;12:Ni=7000;1:Ni=6000,K=2000,Mn=100,B=200,Zn=125;2:Ni=6000;3:U=1000;4:U=1000;5:U=500;6:U=500;7:U=500
RPL-2P-S05 | 9:U=1000,K=3000,Mn=100,B=225,Zn=125;10:SA=4500;11:SA=4000,K=2000,Mn=100,B=225,Zn=125;12:Ni=7000;1:Ni=6000,K=2000,Mn=100,B=200,Zn=125;2:Ni=6000;3:U=1000;4:U=1000;5:U=500;6:U=500;7:U=500
RPL-2P-S06 | 9:U=1000,K=3000,Mn=100,B=225,Zn=125;10:SA=4500;11:SA=4000,K=2000,Mn=100,B=225,Zn=125;12:Ni=7000;1:Ni=6000,K=2000,Mn=100,B=200,Zn=125;2:Ni=6000;3:U=1000;4:U=1000;5:U=500;6:U=500;7:U=500
ROM-S01 | 9:U=1000,K=11000,Mn=125,B=300,Zn=150;10:SA=5000,Ph=4500(4500 no café 2º);11:SA=5000,K=11000,Mn=125,B=300,Zn=150;12:Ni=8000;1:Ni=7000,K=6000,Mn=100,B=200,Zn=150;2:Ni=7000;3:U=1000;4:U=1000;5:U=1000;6:U=1000;7:U=500
ROM-S02 | 9:U=1000,K=10000,Mn=100,B=200,Zn=100;10:SA=4000;11:SA=3000,K=10000,Mn=75,B=200,Zn=100;12:Ni=6000;1:Ni=5000,K=5000,Mn=75,B=200,Zn=100;2:Ni=5000;3:U=1000;4:U=500;5:U=500;6:U=500;7:U=500
ROM-S03 | 9:U=1000,K=9000,Mn=100,B=250,Zn=125;10:SA=5000;11:SA=4000,K=9000,Mn=100,B=250,Zn=125;12:Ni=7000;1:Ni=7000,K=5000,Mn=100,B=200,Zn=125;2:Ni=6000;3:U=1000;4:U=1000;5:U=1000;6:U=500;7:U=500
ROM-S04 | 9:U=1000,K=10000,Mn=100,B=250,Zn=125;10:SA=5000;11:SA=4000,K=10000,Mn=100,B=250,Zn=125;12:Ni=7000;1:Ni=7000,K=5000,Mn=100,B=200,Zn=125;2:Ni=6000;3:U=1000;4:U=1000;5:U=1000;6:U=500;7:U=500
ROM-S05 | 9:U=1000,K=10000,Mn=100,B=200,Zn=100;10:SA=4000;11:SA=3000,K=10000,Mn=100,B=200,Zn=100;12:Ni=6000;1:Ni=5000,K=5000,Mn=50,B=200,Zn=100;2:Ni=5000;3:U=1000;4:U=500;5:U=500;6:U=500;7:U=500
ROM-S06 | 9:U=1000,K=8000,Mn=100,B=200,Zn=100;10:SA=4000;11:SA=3000,K=8000,Mn=100,B=200,Zn=100;12:Ni=6000;1:Ni=5000,K=5000,Mn=50,B=200,Zn=100;2:Ni=5000;3:U=1000;4:U=500;5:U=500;6:U=500;7:U=500
ROM-S07 | 9:U=1000,K=7000,Mn=100,B=200,Zn=100;10:SA=4000;11:SA=3000,K=7000,Mn=100,B=200,Zn=100;12:Ni=6000;1:Ni=5000,K=5000,Mn=50,B=200,Zn=100;2:Ni=5000;3:U=1000;4:U=500;5:U=500;6:U=500;7:U=500
ROM-S08 | 9:U=500,K=4000,Mn=50,B=125,Zn=75;10:SA=2500;11:SA=2000,K=4000,Mn=50,B=125,Zn=75;12:Ni=4000;1:Ni=3000,K=3000,Mn=50,B=100,Zn=50;2:Ni=3000;3:U=500;4:U=500;5:U=500;6:U=500;7:U=500
V56-5PA | 9:U=1000,K=7000,Mn=150,B=300,Zn=200;10:SA=6000;11:SA=6000,K=7000,Mn=150,B=300,Zn=150;12:Ni=9000;1:Ni=9000,K=6000,Mn=100,B=300,Zn=150;2:Ni=8000;3:U=1000;4:U=1000;5:U=1000;6:U=1000;7:U=1000
V56-5CA | 9:U=1000,K=7000,Mn=100,B=200,Zn=125;10:SA=4000;11:SA=4000,K=7000,Mn=100,B=200,Zn=125;12:Ni=6000;1:Ni=6000,K=7000,Mn=75,B=200,Zn=100;2:Ni=5500;3:U=1000;4:U=500;5:U=500;6:U=500;7:U=500
V56-5BX | 9:U=1000,K=8000,Mn=100,B=200,Zn=125;10:SA=4000;11:SA=4000,K=7000,Mn=100,B=200,Zn=125;12:Ni=6000;1:Ni=6000,K=7000,Mn=75,B=200,Zn=100;2:Ni=5500;3:U=1000;4:U=500;5:U=500;6:U=500;7:U=500
V56-6MN | 9:U=1000,K=2000,Mn=100,B=200,Zn=100;10:SA=4000;11:SA=3000,K=2000,Mn=75,B=200,Zn=100;12:Ni=6000;1:Ni=5000,K=2000,Mn=75,B=200,Zn=100;2:Ni=5000;3:U=1000;4:U=500;5:U=500;6:U=500;7:U=500
V56-6IPR | 9:U=1000,K=8000,Mn=125,B=300,Zn=150;10:SA=5500;11:SA=5000,K=7000,Mn=125,B=300,Zn=150;12:Ni=8000;1:Ni=8000,K=7000,Mn=100,B=200,Zn=150;2:Ni=8000;3:U=1000;4:U=1000;5:U=1000;6:U=1000;7:U=500
AGL-T1 | 9:U=500,K=3000,Ph=1000,Mn=50,B=100,Zn=75;10:SA=2000;11:SA=2000,K=3000,Mn=50,B=100,Zn=50;12:Ni=3000;1:Ni=3000,K=2500,Mn=50,B=100,Zn=50;2:Ni=3000;3:U=500;4:U=250;5:U=250;6:U=250;7:U=250
AGL-T2B | 9:U=1000,K=10000,Mn=100,B=225,Zn=150;10:SA=4500;11:SA=4000,K=10000,Mn=100,B=225,Zn=150;12:Ni=7000;1:Ni=6000,K=6000,Mn=100,B=200,Zn=100;2:Ni=6000;3:U=1000;4:U=1000;5:U=500;6:U=500;7:U=500
AGL-T2C | 9:U=1000,K=8000,Mn=100,B=225,Zn=150;10:SA=4500;11:SA=4000,K=8000,Mn=100,B=225,Zn=150;12:Ni=7000;1:Ni=6000,K=6000,Mn=100,B=200,Zn=100;2:Ni=6000;3:U=1000;4:U=1000;5:U=500;6:U=500;7:U=500
AGL-T3 | 9:U=500,K=4000,Mn=50,B=100,Zn=75;10:SA=2000;11:SA=2000,K=3000,Mn=50,B=100,Zn=50;12:Ni=3000;1:Ni=3000,K=3000,Mn=50,B=100,Zn=50;2:Ni=3000;3:U=500;4:U=250;5:U=250;6:U=250;7:U=250
AGL-T4 | 9:U=1000,K=4000,Ph=1000,Mn=100,B=200,Zn=125;10:SA=4000;11:SA=4000,K=4000,Mn=100,B=200,Zn=125;12:Ni=6000;1:Ni=6000,K=3000,Mn=75,B=200,Zn=100;2:Ni=6000;3:U=1000;4:U=500;5:U=500;6:U=500;7:U=500
MCC-CXT | 9:U=1000,K=7000,Ph=8000,Mn=125,B=250,Zn=150;10:SA=5000;11:SA=5000,K=7000,Mn=125,B=250,Zn=150;12:Ni=7000;1:Ni=7000,K=4000,Mn=100,B=250,Zn=125;2:Ni=7000;3:U=1000;4:U=1000;5:U=1000;6:U=500;7:U=500
MCC-CXR | 9:U=1000,K=8000,Mn=125,B=275,Zn=150;10:SA=5500;11:SA=5000,Mn=125,B=275,Zn=150;12:Ni=8000;1:Ni=8000,K=3000,Mn=100,B=250,Zn=150;2:Ni=7000;3:U=1000;4:U=1000;5:U=1000;6:U=1000;7:U=500
MCC-CXP | 9:U=1000,K=15000,Ph=8000,Mn=125,B=250,Zn=150;10:SA=5000;11:SA=5000,K=15000,Mn=125,B=250,Zn=150;12:Ni=7000;1:Ni=7000,K=8000,Mn=100,B=250,Zn=125;2:Ni=7000;3:U=1000;4:U=1000;5:U=1000;6:U=500;7:U=500
MCC-S01 | 9:U=500,K=4000,Mn=75,B=150,Zn=75;10:SA=3000,Ph=4500;11:SA=2500,Mn=75,B=125,Zn=75;12:Ni=4000;1:Ni=4000,K=3000,Mn=50,B=125,Zn=75;2:Ni=4000;3:U=500;4:U=500;5:U=500;6:U=500;7:U=500
MCC-S02 | 9:U=500,K=3000,Mn=75,B=150,Zn=75;10:SA=3000;11:SA=2500,Mn=75,B=125,Zn=75;12:Ni=4000;1:Ni=4000,K=3000,Mn=50,B=125,Zn=75;2:Ni=4000;3:U=500;4:U=500;5:U=500;6:U=500;7:U=500
MCC-S03 | 9:U=500,K=3000,Mn=75,B=150,Zn=75;10:SA=3000,Ph=1500;11:SA=2500,Mn=75,B=125,Zn=75;12:Ni=4000;1:Ni=4000,K=3000,Mn=50,B=125,Zn=75;2:Ni=4000;3:U=500;4:U=500;5:U=500;6:U=500;7:U=500
MCC-S04 | 9:U=500,K=3000,Mn=75,B=150,Zn=75;10:SA=3000,Ph=4500;11:SA=2500,Mn=75,B=125,Zn=75;12:Ni=4000;1:Ni=4000,K=2000,Mn=50,B=125,Zn=75;2:Ni=4000;3:U=500;4:U=500;5:U=500;6:U=500;7:U=500
MCC-S05 | 9:U=500,K=4000,Mn=75,B=150,Zn=75;10:SA=3000,Ph=6000;11:SA=2500,K=4000,Mn=75,B=125,Zn=75;12:Ni=4000;1:Ni=4000,K=3000,Mn=50,B=125,Zn=75;2:Ni=4000;3:U=500;4:U=500;5:U=500;6:U=500;7:U=500
MCC-S06 | 9:U=500,K=5000,Mn=75,B=150,Zn=75;10:SA=3000;11:SA=2500,K=5000,Mn=75,B=125,Zn=75;12:Ni=4000;1:Ni=4000,K=3000,Mn=50,B=125,Zn=75;2:Ni=4000;3:U=500;4:U=500;5:U=500;6:U=500;7:U=500
MCC-S07 | 9:U=500,K=5000,Mn=75,B=150,Zn=75;10:SA=3000;11:SA=2500,K=5000,Mn=75,B=125,Zn=75;12:Ni=4000;1:Ni=4000,K=3000,Mn=50,B=125,Zn=75;2:Ni=4000;3:U=500;4:U=500;5:U=500;6:U=500;7:U=500
MCC-S08 | 9:U=500,K=4500,Mn=75,B=150,Zn=75;10:SA=3000;11:SA=2500,K=4500,Mn=75,B=125,Zn=75;12:Ni=4000;1:Ni=4000,K=3000,Mn=50,B=125,Zn=75;2:Ni=4000;3:U=500;4:U=500;5:U=500;6:U=500;7:U=500
MCC-ERA | 9:U=3000,K=21000,Mn=400,B=800,Zn=450;10:SA=16500;11:SA=15000,K=21000,Mn=350,B=800,Zn=450;12:Ni=24000;1:Ni=24000,K=11000,Mn=350,B=800,Zn=450;2:Ni=22000;3:U=3000;4:U=3000;5:U=3000;6:U=3000;7:U=2000
MCC-ERB | 9:U=1000,K=7000,Mn=100,B=300,Zn=125;10:SA=5000;11:SA=4000,K=7000,Mn=100,B=200,Zn=125;12:Ni=7000;1:Ni=7000,K=4000,Mn=100,B=200,Zn=125;2:Ni=6000;3:U=1000;4:U=1000;5:U=1000;6:U=500;7:U=500
LAG-S01 | 9:U=2000,K=10000,Mn=175,B=400,Zn=225;10:SA=8000;11:SA=7500,K=10000,Mn=175,B=400,Zn=225;12:Ni=12000;1:Ni=12000,K=6000,Mn=150,B=350,Zn=200;2:Ni=10000;3:U=2000;4:U=2000;5:U=1000;6:U=500;7:U=500
LAG-S02 | 9:U=2000,K=10000,Mn=175,B=400,Zn=225;10:SA=8000;11:SA=7500,K=10000,Mn=175,B=400,Zn=225;12:Ni=12000;1:Ni=12000,K=6000,Mn=150,B=350,Zn=200;2:Ni=10000;3:U=2000;4:U=2000;5:U=1000;6:U=500;7:U=500
LAG-S03 | 9:U=2000,K=10000,Mn=175,B=400,Zn=225;10:SA=8000;11:SA=7500,K=10000,Mn=175,B=400,Zn=225;12:Ni=12000;1:Ni=12000,K=6000,Mn=150,B=350,Zn=200;2:Ni=10000;3:U=2000;4:U=2000;5:U=1000;6:U=500;7:U=500
LAG-S04 | 9:U=1000,Mn=100,B=200,Zn=125;10:SA=4000;11:SA=3500,Mn=100,B=200,Zn=100;12:Ni=6000;1:Ni=6000,K=4000,Mn=100,B=200,Zn=100;2:Ni=5000;3:U=1000;4:U=500;5:U=500;6:U=500;7:U=500
LAG-S05 | 9:U=1000,Mn=100,B=200,Zn=125;10:SA=4000;11:SA=3500,K=4000,Mn=100,B=200,Zn=100;12:Ni=6000;1:Ni=6000,K=4000,Mn=100,B=200,Zn=100;2:Ni=5000;3:U=1000;4:U=500;5:U=500;6:U=500;7:U=500
LAG-S06 | 9:U=1000,Mn=100,B=200,Zn=125;10:SA=4000;11:SA=3500,Mn=100,B=200,Zn=100;12:Ni=6000;1:Ni=6000,K=4000,Mn=100,B=200,Zn=100;2:Ni=5000;3:U=1000;4:U=500;5:U=500;6:U=500;7:U=500
LAG-JX | 9:U=1000,K=4000,Mn=100,B=200,Zn=125;10:SA=4000;11:SA=3500,K=4000,Mn=100,B=200,Zn=100;12:Ni=5500;1:Ni=5500,K=3000,Mn=100,B=150,Zn=100;2:Ni=5500;3:U=1000;4:U=500;5:U=500;6:U=500;7:U=500
MTP-S01 | 9:U=1000,K=3000,Mn=100,B=175,Zn=100;10:SA=4000;11:SA=3000,K=3000,Mn=100,B=175,Zn=100;12:Ni=5000;1:Ni=5000,K=2000,Mn=100,B=175,Zn=100;2:Ni=5000;3:U=500;4:U=500;5:U=500;6:U=500;7:U=500
MTP-S02 | 9:U=1000,K=3000,Mn=100,B=175,Zn=100;10:SA=4000;11:SA=3000,K=3000,Mn=100,B=175,Zn=100;12:Ni=5000;1:Ni=5000,K=3000,Mn=100,B=175,Zn=100;2:Ni=5000;3:U=500;4:U=500;5:U=500;6:U=500;7:U=500
MTP-S03 | 9:U=1000,K=6000,Mn=100,B=250,Zn=150;10:SA=5000,Ph=3000;11:SA=5000,K=6000,Mn=100,B=250,Zn=150;12:Ni=8000;1:Ni=7000,K=4000,Mn=100,B=250,Zn=125;2:Ni=7000;3:U=1000;4:U=1000;5:U=1000;6:U=1000;7:U=500
MTP-S04 | 9:U=1000,K=6000,Mn=125,B=250,Zn=150;10:SA=5000,Ph=3000;11:SA=5000,K=6000,Mn=125,B=250,Zn=150;12:Ni=8000;1:Ni=7000,K=4000,Mn=100,B=250,Zn=125;2:Ni=7000;3:U=1000;4:U=1000;5:U=1000;6:U=1000;7:U=500
MTP-S05 | 9:U=1000,K=8000,Mn=125,B=250,Zn=150;10:SA=5000,Ph=3000;11:SA=5000,K=8000,Mn=125,B=250,Zn=150;12:Ni=8000;1:Ni=7000,K=3000,Mn=100,B=250,Zn=125;2:Ni=7000;3:U=1000;4:U=1000;5:U=1000;6:U=1000;7:U=500
MTP-3PT | 9:U=1500,K=7000,Mn=150,B=400,Zn=200;10:SA=7000;11:SA=6000,K=7000,Mn=150,B=300,Zn=200;12:Ni=10000;1:Ni=9000,K=4000,Mn=150,B=300,Zn=150;2:Ni=9000;3:U=1500;4:U=1500;5:U=1000;6:U=1000;7:U=1000

### RESUMO_FAZENDA (kg/ano no slide-resumo do deck; NÃO bate com a soma dos calendários em 5 fazendas — usar só na auditoria)
Vereda Café | U=73000,Ni=304000,SA=139000,K=387000,Ph=3500,Mn=4700,B=10600,Zn=5950
Rio Preto-Lagamar — Café | U=55000,Ni=223500,SA=101000,K=150000,Ph=0,Mn=3525,B=7650,Zn=4425
Vereda Romaria | U=34000,Ni=136000,SA=60500,K=183000,Ph=4500,Mn=2100,B=4950,Zn=2600
Vereda Café 5º e 6º | U=23500,Ni=101000,SA=45500,K=91000,Ph=0,Mn=1550,B=3500,Zn=1950
Água Limpa | U=17000,Ni=74000,SA=33000,K=77500,Ph=2000,Mn=1175,B=2500,Zn=1500
Monte Carmelo — Café | U=65500,Ni=268000,SA=122500,K=215000,Ph=24500,Mn=4300,B=9150,Zn=5150
Lagamar Café – Rodrigo | U=48000,Ni=169500,SA=76500,K=109000,Ph=0,Mn=2700,B=5800,Zn=3250
Mata Preta - Café | U=30500,Ni=124000,SA=57000,K=86000,Ph=9000,Mn=2050,B=4300,Zn=2425

### FITO_MES  (mes | fase | alvos | produtos | via_solo | excecao_via_solo)
8 | Pré-florada |  | Mirus,Priori Top,Auto 400,Oberon,Ochima |  | 
9 | Pós-florada | bicho-mineiro,ácaro | Mirus,Miravis Duo,Curyon,Vertimec,Ochima |  | 
10 | Pós-florada | phoma,antracnose,cercospora,bicho-mineiro | Mirus,Nativo Plus,Bayfolan | Verdadero,Actara | Vaniva em Vereda Café, Vereda Romaria, Vereda Café 5º e 6º, Água Limpa
11 | Fungicida + inseticida | ferrugem,phoma,antracnose,broca,bicho-mineiro | Mirus,Priori Xtra,Joiner,Ochima |  | 
12 | Preventivo | bactéria,seca,cercospora,broca | Auge,Bravonil |  | 
1 | Fungicida + inseticida | ferrugem,phoma,antracnose,cercospora,broca,bicho-mineiro | Mirus,Priori Xtra,Durivo,Vertimec,Ochima |  | 
2 | Fungicida + inseticida | ferrugem,phoma,antracnose,cercospora,broca,bicho-mineiro | Mirus,Priori Xtra,Ochima | Actara | 
3 | Fungicida + inseticida | ferrugem,phoma,antracnose,cercospora,broca,bicho-mineiro | Mirus,Alto 400,Joiner,Ochima |  | 
4 | Fungicida + inseticida | phoma,antracnose,cercospora,bicho-mineiro | Mirus,Cercobim,Orlist |  | 
5 | Pós-colheita |  | Mirus,Auge,Bravonil |  | 

### GANTT  (modelo | atividade | meses)
NC | analise_solo | 5,6
NC | analise_foliar | 11,12,1,2
NC | calagem_gessagem | 9,10
NC | adubacao_organica | 9,10
NC | limpeza_sistema_irrigacao | 9,10,3,4
NC | adubacao_fertirrigacao | 8,9,10,1,2,3,4
NC | adubacao_lanco | 9,10,11,12,1
NC | mip | 8,9,10,11,12,1,2,3,4,5,6,7
NC | pulverizacao | 8,9,10,11,12,1,2,3,4,5
NC | drench | 10,11,1,2
NC | desbrota | 10,11,12
NC | capina_manual | 11,12,3,4
NC | capina_rocadeira_trincha | 10,11,12,1,2,3
NC | herbicida | 12,2,4,5
NC | colheita | 8,5,6,7
NC | poda | 8,9
NR | analise_solo | 5,6
NR | analise_foliar | 11,12,1,2
NR | calagem_gessagem | 9,10
NR | adubacao_organica | 9,10
NR | limpeza_sistema_irrigacao | 9,10
NR | adubacao_fertirrigacao | 8,9,10,11,12,1,2,3,4
NR | adubacao_lanco | 9,10,11,12
NR | mip | 8,9,10,11,12,1,2,3,4,5,6,7
NR | pulverizacao | 8,9,10,11,12,1,2,3,4,5
NR | drench | 10,11,1,2
NR | desbrota | 10,11,12
NR | capina_manual | 11,12,3,4
NR | capina_rocadeira_trincha | 10,11,12,1,2,3
NR | herbicida | 12,4,5
NR | colheita | 8,5,6,7
NR | poda | 8,9

### AUDITORIA_V1 (inconsistências já conhecidas; gravar em docs/PLANO-2627-AUDITORIA.md)
- Água Limpa: soma das áreas = 92 ha; slide totaliza 81 (erro de soma).
- Vereda: resumo − calendários: SA −24.500, KCl +18.000, U +2.000, Ni −2.000, Zn −175, B −25. Setor 08 SA 21000+21000 provável erro.
- Monte Carmelo: resumo − calendários: U +4.000, Ni +17.000, SA +7.500, KCl +4.000, Ph −8.000, Mn +250, B +550, Zn +325.
- Lagamar: resumo − calendários: U +8.000, KCl +4.000.
- Romaria: resumo − calendários: KCl +6.000, U −500.
- Mata Preta: resumo − calendários: U −500.
- Romaria safra zerada: 2+34+23 = 59; slide diz 49.
- Gantt NR difere do NC em 4 linhas (limpeza, fertirrigação, lanço, herbicida).
- Vereda S07 sem KCl; S09 sem uréia e sem mar–jul; Pivô 2 calagem cobre 109 ha de 120.
- Nomes múltiplos: V56-6MN (3 nomes), V56-5BX (3 nomes), AGL-T1 (Catuaí × Catucaí), MTP-3PT sem calagem e sem área, MTP-P26 sem calendário.
- Fito: "Auto 400" (ago) vs "Alto 400" (mar) — grafia mantida como no deck; confirmar se é o mesmo produto.
- Uréia mai–jul não tem canal (fertirrigação/lanço) em nenhum Gantt; coluna via ainda não definida.
