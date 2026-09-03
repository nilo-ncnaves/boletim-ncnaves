#!/usr/bin/env python3
"""
gerar_seed_plano.py — gera o SQL de carga inicial do plano de safra
(sql/006-plano-safra-seed-2627.sql) a partir de:

  docs/plano/2026-27/plano_2627_seed.json   dados do plano (única fonte; não editar à mão)
  docs/plano/2026-27/depara_fazendas.json   nome no plano → unidade do app (só exato; confirmado=true/false)
  docs/plano/2026-27/alias_app.json         unidade do plano → id do talhão no app (só inequívoco)
  index.html                                 cadastro real de fazendas e talhões (para conferir os dois acima)

Regras:
  - Nunca inventa, completa ou corrige valores do plano.
  - fazenda_app recebe o nome EXATO do app só quando o de-para está
    confirmado; senão fica o nome do plano e o SQL avisa (bloco AJUSTE
    PENDENTE no fim).
  - Alias sistema='app' só sai para fazendas confirmadas.
  - Ids são determinísticos (uuid5), então rodar o seed duas vezes não
    duplica nada (on conflict do nothing).
  - No fim do SQL há uma conferência que desfaz tudo se as somas não
    baterem com o item A0 do pedido.

Uso:  python3 scripts/gerar_seed_plano.py          (na raiz do repositório)
"""
import json
import re
import sys
import uuid
from collections import OrderedDict, defaultdict
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
SEED = RAIZ / 'docs/plano/2026-27/plano_2627_seed.json'
DEPARA = RAIZ / 'docs/plano/2026-27/depara_fazendas.json'
ALIAS_APP = RAIZ / 'docs/plano/2026-27/alias_app.json'
INDEX = RAIZ / 'index.html'
SAIDA = RAIZ / 'sql/006-plano-safra-seed-2627.sql'

NS = uuid.UUID('b0e7a1c4-5f3d-4c2a-9e8b-7d6c5b4a3f21')  # namespace fixo: ids estáveis entre execuções
SAFRA = '2026/27'
VERSAO = 1
INSUMOS = ['ureia', 'nitrato', 'sulfato_amonio', 'kcl', 'phusion', 'sulfato_mn', 'acido_borico', 'sulfato_zn']
PIVOS = {'VEC-P02', 'VEC-P06'}
# Observações do CADASTRO (unidade_manejo.obs), não do plano: exceções declaradas pelo Escritório.
# "sem área: ok" é o texto que a auditoria reconhece para não travar a publicação.
OBS_CADASTRO = {
    'MTP-3PT': 'sem área: ok — liberado pelo Escritório em 03/09/2026 para publicar a v1; área e identidade a informar pelo agrônomo',
}

# Gantt: tipo e evidência (item A1 do pedido). Rótulos entre aspas são os
# itens exatos de LISTA_ATIV do index.html.
EVIDENCIA = {
    'analise_solo':             ('evento_unico', 'sem chip — o catálogo de atividades do café (LISTA_ATIV) não tem coleta de solo; farol fica cinza', None),
    'analise_foliar':           ('evento_unico', 'sem chip — o catálogo de atividades do café não tem coleta foliar; farol fica cinza', None),
    'calagem_gessagem':         ('evento_unico', "atividade 'Calagem / gessagem' por talhão (✔ concluída / ⏳ continua amanhã)", 'Solinftec (distribuidor de calcário) · ERP AgroGestão (t por gleba)'),
    'adubacao_organica':        ('janela', "atividade 'Adubação orgânica' por talhão", 'ERP AgroGestão (kg por gleba)'),
    'limpeza_sistema_irrigacao':('janela', "atividade 'Limpeza do sistema de irrigação'", None),
    'adubacao_fertirrigacao':   ('janela', "módulo Irrigação (gotejo): 'Fertirrigação hoje? Sim' + chips de setor (irr.fertSetores)", 'iCrop (setores e lâminas)'),
    'adubacao_lanco':           ('janela', "atividade 'Adubação via lanço' por talhão", 'Solinftec (adubadeira) · ERP AgroGestão (kg por gleba)'),
    'mip':                      ('janela', "atividade 'Monitoramento de pragas (MIP)' e registros da seção Pragas, doenças e daninhas (fito)", None),
    'pulverizacao':             ('janela', "atividade 'Pulverização' por talhão + calda/receita aplicada", 'Solinftec (pulverizador)'),
    'drench':                   ('janela', "atividade 'Aplicação via drench / via solo' por talhão", None),
    'desbrota':                 ('janela', "atividade 'Desbrota' por talhão com ✔ concluída", None),
    'capina_manual':            ('janela', "atividade 'Capina manual' por talhão com ✔ concluída", None),
    'capina_rocadeira_trincha': ('janela', "atividade 'Capina roçadeira / trincha' por talhão", 'Solinftec (roçadeira / trincha)'),
    'herbicida':                ('janela', "atividade 'Aplicação de herbicida' por talhão", 'Solinftec (pulverizador)'),
    'colheita':                 ('janela', "módulo Colheita (registro por talhão) e atividade 'Colheita'", 'Solinftec (colhedora)'),
    'poda':                     ('evento_unico', "atividade 'Poda / esqueletamento' por talhão com ✔ concluída", None),
}

PARAMETROS = [
    ('fito_dias_sem_monitoramento', '10', 'Dias sem monitoramento de um alvo previsto no mês para o farol Fito ficar amarelo'),
    ('gantt_pct_janela_amarelo', '60', '% da janela decorrida sem registro para o farol Gantt ficar amarelo'),
    ('adubo_dia_limite_cadencia', '20', 'Dia do mês até o qual se espera o 1º registro de fertirrigação/adubação (e a 1ª pulverização nos meses de fungicida + inseticida)'),
    ('poda_data_limite', '2026-09-30', 'Data-limite para o chip de poda ✔ nas unidades com status poda'),
    ('desbrota_data_limite', '2026-12-31', 'Data-limite para o chip de desbrota ✔ nas unidades com status poda'),
    ('chumbinho_meses', '10,11,12', 'Meses em que o chip "chumbinho visível" aparece no bloco Clima (fase B)'),
]


def q(v):
    """literal SQL: None → null; texto com aspas duplicadas."""
    if v is None:
        return 'null'
    if isinstance(v, bool):
        return 'true' if v else 'false'
    if isinstance(v, (int, float)):
        return repr(v) if isinstance(v, int) else ('%g' % v)
    return "'" + str(v).replace("'", "''") + "'"


def arr(lista, tipo='text'):
    if not lista:
        return "'{}'::%s[]" % tipo
    itens = ', '.join(q(x) if tipo == 'text' else str(x) for x in lista)
    return 'array[%s]::%s[]' % (itens, tipo)


def uid(chave):
    return str(uuid.uuid5(NS, chave))


def ler_cadastro_app(html):
    """Lê fazendas e talhões do dadosSemente() do index.html (cadastro real)."""
    faz = OrderedDict((i, n) for i, n in re.findall(r'\{id:"(f\d+[a-z]?)", nome:"([^"]*)", municipio', html))
    tal = OrderedDict()
    for tid, fz, nome, area in re.findall(r'\{id:"(t\d+)", fazendaId:"(f\d+[a-z]?)", nome:"([^"]*)", area:([\d.]+)', html):
        tal[tid] = {'fazendaId': fz, 'nome': nome, 'area': float(area)}
    if len(faz) < 20 or len(tal) < 100:
        raise SystemExit(f'cadastro do app não lido direito: {len(faz)} fazendas, {len(tal)} talhões')
    return faz, tal


def main():
    seed = json.loads(SEED.read_text(encoding='utf-8'))
    depara = json.loads(DEPARA.read_text(encoding='utf-8'))['fazendas']
    alias_app = json.loads(ALIAS_APP.read_text(encoding='utf-8'))
    faz_app, tal_app = ler_cadastro_app(INDEX.read_text(encoding='utf-8'))
    erros, avisos = [], []

    # ---- de-para de fazendas: só exato ----------------------------------
    fazendas_plano = [f['fazenda_app'] for f in seed['fazendas']]
    dp = {d['plano']: d for d in depara}
    for fz in fazendas_plano:
        if fz not in dp:
            erros.append(f'fazenda do plano sem linha no de-para: {fz}')
    for d in depara:
        real = faz_app.get(d['app_id'])
        if real is None:
            erros.append(f"de-para {d['plano']}: app_id {d['app_id']} não existe no index.html")
        elif real != d['app_nome']:
            erros.append(f"de-para {d['plano']}: app_nome '{d['app_nome']}' ≠ cadastro '{real}'")
        if d['confirmado'] and d['plano'] != d['app_nome'] and 'confirmado pelo nilo' not in d.get('observacao', '').lower():
            erros.append(f"de-para {d['plano']}: confirmado=true mas o nome não é igual ao do app ('{d['app_nome']}') e a observação não registra a confirmação do Nilo — regra 5: pare e confirme")
        if not d['confirmado']:
            avisos.append(f"fazenda '{d['plano']}' NÃO confirmada (app candidato: {d['app_id']} '{d['app_nome']}') — seed grava o nome do plano; sem alias app; o app não carrega este plano")
    nome_db = {fz: (dp[fz]['app_nome'] if dp.get(fz, {}).get('confirmado') else fz) for fz in fazendas_plano}
    id_app_de = {fz: dp[fz]['app_id'] for fz in fazendas_plano if fz in dp}
    confirmada = {fz: bool(dp.get(fz, {}).get('confirmado')) for fz in fazendas_plano}

    # ---- unidades -------------------------------------------------------
    unidades = seed['unidades']
    codigos = [u['codigo'] for u in unidades]
    por_codigo = {u['codigo']: u for u in unidades}

    # ---- alias app: cobertura completa e coerência com o cadastro -------
    al = alias_app['aliases']
    sem = alias_app['sem_alias']
    for cod in codigos:
        if (cod in al) == (cod in sem):
            erros.append(f'alias_app.json: {cod} deve estar em exatamente um de "aliases" ou "sem_alias"')
    for cod in list(al) + list(sem):
        if cod not in por_codigo:
            erros.append(f'alias_app.json cita código inexistente: {cod}')
    for cod, info in al.items():
        u = por_codigo.get(cod)
        if not u:
            continue
        fz_id = id_app_de.get(u['fazenda_app'])
        for tid in info['talhoes']:
            t = tal_app.get(tid)
            if not t:
                erros.append(f'alias app {cod} → {tid}: talhão não existe no index.html')
            elif t['fazendaId'] != fz_id:
                erros.append(f"alias app {cod} → {tid}: talhão é da unidade {t['fazendaId']}, não de {fz_id}")
    if erros:
        print('ERROS — nada gerado:')
        for e in erros:
            print('  ✗', e)
        sys.exit(2)

    # ---- status derivado do deck (sem inventar) -------------------------
    def status_de(u):
        z = u['safra_zerada_tipo']
        if z == 'poda':
            return 'poda'
        if z == 'plantio':
            return 'plantio'
        if z == 'a_confirmar':
            return 'a_confirmar'
        return 'producao'  # nulo ou em_branco
    esperado = {'plantio': {'MTP-P26'}, 'a_confirmar': {'V56-6MN', 'MCC-CXR'}}
    for st, cods in esperado.items():
        got = {u['codigo'] for u in unidades if status_de(u) == st}
        if got != cods:
            erros.append(f'status {st}: esperado {sorted(cods)}, obtido {sorted(got)}')
    if erros:
        print('ERROS — nada gerado:'); [print('  ✗', e) for e in erros]; sys.exit(2)

    # ====================================================================
    L = []
    w = L.append
    w('-- Carga inicial do plano de safra 2026/27 (v52) — GERADO por scripts/gerar_seed_plano.py')
    w('-- Rodar no SQL Editor do Supabase DEPOIS do sql/005-plano-safra.sql.')
    w('-- Fonte única: docs/plano/2026-27/plano_2627_seed.json (7 PPTX do agrônomo, 03/09/2026).')
    w('-- Pode ser rodado de novo: os ids são fixos e tudo é "on conflict do nothing".')
    w('-- No fim há uma conferência: se alguma soma não bater, TUDO é desfeito.')
    w('--')
    w('-- Os planos entram como versão 1 em RASCUNHO. Publicar como vigente é na')
    w('-- tela Escritório › Unidades e Plano (rodar auditoria → aprovado por → publicar).')
    w('--')
    w('-- Números do plano são a proposta técnica do agrônomo (Salvino): referência')
    w('-- para comparação, nunca receituário.')
    for a in avisos:
        w('-- AVISO: ' + a)
    w('')
    w('begin;')
    w('')

    # renomeações de cargas anteriores ---------------------------------------
    # Fazenda confirmada cujo nome no plano difere do app: se uma carga anterior
    # gravou o nome do plano, corrige aqui (num banco vazio não faz nada).
    renomear = [d for d in depara if d['confirmado'] and d['plano'] != d['app_nome']]
    if renomear:
        w('-- 0. Nome do plano → nome exato do app em cargas anteriores (não faz nada num banco vazio)')
        for d in renomear:
            for tb in ['unidade_manejo', 'unidade_alias', 'plano_safra', 'plano_fito_excecao']:
                w('update public.%s set fazenda_app = %s where fazenda_app = %s;' % (tb, q(d['app_nome']), q(d['plano'])))
        w('')

    # unidade_manejo -------------------------------------------------------
    w('-- 1. unidade_manejo (%d unidades; pais antes dos filhos) ----------------' % len(unidades))
    ordenadas = [u for u in unidades if not u['pai']] + [u for u in unidades if u['pai']]
    empresa_de = {f['fazenda_app']: f['empresa'] for f in seed['fazendas']}
    for u in ordenadas:
        obs = u['obs']
        if u['safra_zerada_tipo'] == 'em_branco':
            nota = 'coluna de safra zerada em branco no deck — status "producao" assumido na carga'
            obs = (obs + '; ' + nota) if obs else nota
        if u['codigo'] in OBS_CADASTRO:
            obs = (obs + '; ' + OBS_CADASTRO[u['codigo']]) if obs else OBS_CADASTRO[u['codigo']]
        cols = OrderedDict([
            ('id', q(uid('unidade:' + u['codigo']))),
            ('codigo', q(u['codigo'])),
            ('fazenda_app', q(nome_db[u['fazenda_app']])),
            ('empresa', q(empresa_de[u['fazenda_app']])),
            ('nome_plano', q(u['nome_plano'])),
            ('nome_curto', q(u['nome_plano'])),
            ('pai_id', q(uid('unidade:' + u['pai'])) if u['pai'] else 'null'),
            ('area_ha', q(u['area_ha'])),
            ('fonte_area', q(u['fonte_area'])),
            ('irrigacao', q('pivo' if u['codigo'] in PIVOS else 'gotejo')),
            ('status', q(status_de(u))),
            ('area_zerada_ha', q(u['area_zerada_ha'])),
            ('obs', q(obs)),
        ])
        w('insert into public.unidade_manejo (%s) values (%s) on conflict (codigo) do nothing;'
          % (', '.join(cols), ', '.join(cols.values())))
    w('')

    # unidade_alias plano ---------------------------------------------------
    # Um apelido que o deck usa para VÁRIAS unidades da mesma fazenda (ex.: o bloco
    # "2º Plantio 180 hectares" dos 6 setores do 2º plantio) não identifica ninguém:
    # fica fora do cadastro de apelidos e é listado no relatório.
    w('-- 2. unidade_alias sistema=plano (nome do deck + apelidos) -----------------')
    uso = defaultdict(set)
    for u in unidades:
        for nm in [u['nome_plano']] + u['aliases_plano']:
            uso[(u['fazenda_app'], nm)].add(u['codigo'])
    ambiguos = {k: sorted(v) for k, v in uso.items() if len(v) > 1}
    n_al_plano = 0
    for u in unidades:
        nomes = []
        for nm in [u['nome_plano']] + u['aliases_plano']:
            if nm not in nomes and (u['fazenda_app'], nm) not in ambiguos:
                nomes.append(nm)
        for nm in nomes:
            w("insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values (%s, %s, 'plano', %s) "
              "on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;"
              % (q(uid('unidade:' + u['codigo'])), q(nome_db[u['fazenda_app']]), q(nm)))
            n_al_plano += 1
    for (fz, nm), cods in ambiguos.items():
        w('-- apelido AMBÍGUO não gravado: %s / "%s" vale para %s' % (fz, nm, ', '.join(cods)))
    w('')

    # unidade_alias app -----------------------------------------------------
    w('-- 3. unidade_alias sistema=app (id do talhão no cadastro do app) — só fazendas confirmadas')
    n_al_app, pendentes_app = 0, defaultdict(list)
    for cod, info in al.items():
        u = por_codigo[cod]
        if not confirmada[u['fazenda_app']]:
            pendentes_app[u['fazenda_app']].append((cod, info['talhoes']))
            continue
        for tid in info['talhoes']:
            w("insert into public.unidade_alias (unidade_id, fazenda_app, sistema, alias) values (%s, %s, 'app', %s) "
              "on conflict (sistema, fazenda_app, alias) where vigente_ate is null do nothing;  -- %s"
              % (q(uid('unidade:' + cod)), q(nome_db[u['fazenda_app']]), q(tid), tal_app[tid]['nome']))
            n_al_app += 1
    w('')

    # plano_safra -----------------------------------------------------------
    w('-- 4. plano_safra — versão 1 em rascunho, uma por fazenda -----------------')
    w('--    resumo_deck = kg/ano do slide-resumo do deck (a auditoria compara com a soma dos calendários)')
    resumo = defaultdict(dict)
    for r in seed['resumo_fazenda']:
        resumo[r['fazenda_app']][r['insumo']] = r['kg']
    plano_id = {}
    for f in seed['fazendas']:
        pid = uid('plano:%s:%s:v%d' % (f['fazenda_app'], SAFRA, VERSAO))
        plano_id[f['fazenda_app']] = pid
        rj = json.dumps(OrderedDict((i, resumo[f['fazenda_app']].get(i)) for i in INSUMOS), ensure_ascii=False)
        w("insert into public.plano_safra (id, fazenda_app, safra, versao, status, motivo, arquivo_origem, criado_por, auditoria_ok, resumo_deck) "
          "values (%s, %s, %s, %d, 'rascunho', 'carga inicial dos PPTX de 2026/27', %s, 'seed v52 (gerar_seed_plano.py)', false, %s::jsonb) "
          "on conflict (fazenda_app, safra, versao) do nothing;"
          % (q(pid), q(nome_db[f['fazenda_app']]), q(SAFRA), VERSAO, q(f['deck']), q(rj)))
    w('')

    # plano_unidade ---------------------------------------------------------
    w('-- 5. plano_unidade ----------------------------------------------------------')
    for u in unidades:
        w("insert into public.plano_unidade (plano_id, unidade_id, area_ha_plano, safra_zerada_tipo, area_zerada_ha, estimativa_sc_ha) "
          "values (%s, %s, %s, %s, %s, null) on conflict (plano_id, unidade_id) do nothing;"
          % (q(plano_id[u['fazenda_app']]), q(uid('unidade:' + u['codigo'])), q(u['area_ha']),
             q(u['safra_zerada_tipo']), q(u['area_zerada_ha'])))
    w('')

    # plano_adubo_mes -------------------------------------------------------
    # Formato compacto (código da unidade, mês, sigla do insumo, kg[, obs]); o SQL
    # resolve o id da unidade e o plano da fazenda pelo cadastro já gravado acima.
    adubo = seed['adubo_mes']
    sigla = {v: k for k, v in {'U': 'ureia', 'Ni': 'nitrato', 'SA': 'sulfato_amonio', 'K': 'kcl', 'Ph': 'phusion',
                               'Mn': 'sulfato_mn', 'B': 'acido_borico', 'Zn': 'sulfato_zn'}.items()}
    w('-- 6. plano_adubo_mes (%d linhas; via = null — não deduzida) ----------------' % len(adubo))
    w('--    siglas: U=ureia Ni=nitrato SA=sulfato_amonio K=kcl Ph=phusion Mn=sulfato_mn B=acido_borico Zn=sulfato_zn')
    LOTE = 400
    for i in range(0, len(adubo), LOTE):
        w('insert into public.plano_adubo_mes (plano_id, unidade_id, mes, insumo, kg, via, obs)')
        w('select p.id, u.id, v.mes, s.insumo, v.kg, null, v.obs from (values')
        linhas = []
        for a in adubo[i:i + LOTE]:
            linhas.append("(%s,%d,%s,%s%s)" % (q(a['codigo']), a['mes'], q(sigla[a['insumo']]), q(a['kg']),
                                                (',' + q(a['obs'])) if a['obs'] else ',null'))
        w(',\n'.join(linhas))
        w(') as v(codigo, mes, sg, kg, obs)')
        w("join (values ('U','ureia'),('Ni','nitrato'),('SA','sulfato_amonio'),('K','kcl'),('Ph','phusion'),('Mn','sulfato_mn'),('B','acido_borico'),('Zn','sulfato_zn')) as s(sg, insumo) on s.sg = v.sg")
        w('join public.unidade_manejo u on u.codigo = v.codigo')
        w("join public.plano_safra p on p.fazenda_app = u.fazenda_app and p.safra = %s and p.versao = %d" % (q(SAFRA), VERSAO))
        w('on conflict (plano_id, unidade_id, mes, insumo) do nothing;')
    w('')

    # plano_calagem ---------------------------------------------------------
    cal = seed['calagem']
    w('-- 7. plano_calagem (%d linhas; janela 01/09–31/10/2026) ------------------' % len(cal))
    for c in cal:
        u = por_codigo[c['codigo']]
        w("insert into public.plano_calagem (plano_id, unidade_id, subarea, t_ha, t_total, rateado, janela_ini, janela_fim) "
          "values (%s, %s, %s, %s, %s, %s, '2026-09-01', '2026-10-31') on conflict (plano_id, unidade_id, subarea) do nothing;"
          % (q(plano_id[u['fazenda_app']]), q(uid('unidade:' + c['codigo'])), q(c['subarea']), q(c['t_ha']), q(c['t_total']), q(c['rateado'])))
    w('')

    # plano_fito_mes + excecao ---------------------------------------------
    w('-- 8. plano_fito_mes (registro do grupo: plano_id nulo) e exceções ----------')
    n_exc = 0
    for fm in seed['fito_mes']:
        w("insert into public.plano_fito_mes (plano_id, mes, fase, alvos, produtos, via_solo) values (null, %d, %s, %s, %s, %s) "
          "on conflict (mes) where plano_id is null do nothing;"
          % (fm['mes'], q(fm['fase']), arr(fm['alvos']), arr(fm['produtos']), arr(fm['via_solo'])))
        for prod, fzs in fm['via_solo_excecao'].items():
            for fz in fzs:
                if fz not in nome_db:
                    erros.append(f'exceção fito cita fazenda desconhecida: {fz}')
                    continue
                w("insert into public.plano_fito_excecao (mes, produto, fazenda_app) values (%d, %s, %s) on conflict (mes, produto, fazenda_app) do nothing;"
                  % (fm['mes'], q(prod), q(nome_db[fz])))
                n_exc += 1
    w('')

    # plano_gantt -----------------------------------------------------------
    w('-- 9. plano_gantt (modelos NC e NR) ----------------------------------------')
    n_gantt = 0
    for modelo, ativs in seed['gantt'].items():
        for ativ, meses in ativs.items():
            if ativ not in EVIDENCIA:
                erros.append(f'atividade do Gantt sem evidência definida: {ativ}')
                continue
            tipo, ev_app, ev_ext = EVIDENCIA[ativ]
            w("insert into public.plano_gantt (modelo, atividade, meses, tipo, evidencia_app, evidencia_externa) values (%s, %s, %s, %s, %s, %s) "
              "on conflict (modelo, atividade) do nothing;"
              % (q(modelo), q(ativ), arr(meses, 'integer'), q(tipo), q(ev_app), q(ev_ext)))
            n_gantt += 1
    w('')

    # plano_parametros ------------------------------------------------------
    w('-- 10. plano_parametros (editáveis pelo ADMIN) -------------------------------')
    for chave, valor, desc in PARAMETROS:
        w("insert into public.plano_parametros (chave, valor, descricao) values (%s, %s, %s) on conflict (chave) do nothing;"
          % (q(chave), q(valor), q(desc)))
    w('')

    if erros:
        print('ERROS — nada gerado:'); [print('  ✗', e) for e in erros]; sys.exit(2)

    # conferência final -----------------------------------------------------
    somas = defaultdict(lambda: defaultdict(int))
    for a in adubo:
        somas[nome_db[por_codigo[a['codigo']]['fazenda_app']]][a['insumo']] += a['kg']
    w('-- 11. CONFERÊNCIA — se algo não bater, desfaz a carga inteira ---------------')
    w('do $$')
    w('declare n_dif integer; n_uni integer; n_adubo integer; n_cal integer; t_cal numeric;')
    w('begin')
    w('  select count(*) into n_dif from (values')
    vals = []
    for fz in sorted(somas):
        for ins in INSUMOS:
            vals.append('    (%s, %s, %s)' % (q(fz), q(ins), q(somas[fz][ins])))
    w(',\n'.join(vals))
    w('  ) as e(fz, ins, kg)')
    w('  left join (select p.fazenda_app fz, a.insumo ins, sum(a.kg) kg from public.plano_adubo_mes a')
    w("      join public.plano_safra p on p.id = a.plano_id where p.safra = %s and p.versao = %d group by 1, 2) s" % (q(SAFRA), VERSAO))
    w('    on s.fz = e.fz and s.ins = e.ins')
    w('  where coalesce(s.kg, 0) <> e.kg;')
    w("  if n_dif > 0 then raise exception 'seed do plano %s: %% soma(s) de kg por fazenda/insumo não bateram — carga desfeita', n_dif; end if;" % SAFRA)
    w('  select count(*) into n_uni from public.unidade_manejo where codigo in (%s);' % ', '.join(q(c) for c in codigos))
    w("  if n_uni <> %d then raise exception 'seed do plano: %% unidades gravadas (esperado %d) — carga desfeita', n_uni; end if;" % (len(unidades), len(unidades)))
    w("  select count(*) into n_adubo from public.plano_adubo_mes a join public.plano_safra p on p.id = a.plano_id where p.safra = %s and p.versao = %d;" % (q(SAFRA), VERSAO))
    w("  if n_adubo <> %d then raise exception 'seed do plano: %% linhas de adubo (esperado %d) — carga desfeita', n_adubo; end if;" % (len(adubo), len(adubo)))
    w("  select count(*), coalesce(sum(t_total), 0) into n_cal, t_cal from public.plano_calagem c join public.plano_safra p on p.id = c.plano_id where p.safra = %s and p.versao = %d;" % (q(SAFRA), VERSAO))
    soma_t = sum(c['t_total'] for c in cal)
    w("  if n_cal <> %d or t_cal <> %s then raise exception 'seed do plano: calagem %% linhas / %% t (esperado %d / %s) — carga desfeita', n_cal, t_cal; end if;" % (len(cal), q(soma_t), len(cal), soma_t))
    w("  raise notice 'plano %s carregado: %% unidades, %% linhas de adubo, %% linhas de calagem (%% t)', n_uni, n_adubo, n_cal, t_cal;" % SAFRA)
    w('end $$;')
    w('')
    w('commit;')
    w('')

    # ajuste pendente -------------------------------------------------------
    nao_conf = [d for d in depara if not d['confirmado']]
    if nao_conf:
        w('-- ====================================================================')
        w('-- AJUSTE PENDENTE — só depois que o Nilo confirmar o nome da fazenda')
        w('-- (regra 5: nomes não idênticos ao cadastro do app não são mapeados).')
        w('-- Passos: 1) trocar confirmado para true em docs/plano/2026-27/depara_fazendas.json;')
        w('--         2) rodar de novo scripts/gerar_seed_plano.py e o seed gerado (cria os aliases app);')
        w('--         3) se a carga acima JÁ foi feita, rodar também os updates abaixo (descomentar).')
        w('-- ====================================================================')
        for d in nao_conf:
            for tb in ['unidade_manejo', 'unidade_alias', 'plano_safra', 'plano_fito_excecao']:
                w('-- update public.%s set fazenda_app = %s where fazenda_app = %s;' % (tb, q(d['app_nome']), q(d['plano'])))
        w('')

    SAIDA.write_text('\n'.join(L), encoding='utf-8')

    # relatório ---------------------------------------------------------------
    print(f'✔ {SAIDA.relative_to(RAIZ)} gerado ({SAIDA.stat().st_size // 1024} KB)')
    print(f"  unidades: {len(unidades)} · alias plano: {n_al_plano} · alias app: {n_al_app} · planos: {len(seed['fazendas'])}")
    for (fz, nm), cods in ambiguos.items():
        print(f'  apelido ambíguo (não gravado): {fz} / "{nm}" → {", ".join(cods)}')
    print(f"  adubo: {len(adubo)} · calagem: {len(cal)} ({soma_t} t) · fito: {len(seed['fito_mes'])} + {n_exc} exceções · gantt: {n_gantt} · parâmetros: {len(PARAMETROS)}")
    if avisos:
        print('\nAVISOS:')
        for a in avisos:
            print('  ⚠', a)
    if pendentes_app:
        print('\nALIAS app que SAEM SOZINHOS depois da confirmação da fazenda:')
        for fz, itens in pendentes_app.items():
            print(f'  {fz}: ' + ', '.join(f"{c}→{'+'.join(t)}" for c, t in itens))
    print('\nUNIDADES SEM ALIAS app (resolver na tela de Escritório):')
    por_fz = defaultdict(list)
    for cod, motivo in sem.items():
        por_fz[por_codigo[cod]['fazenda_app']].append((cod, motivo))
    for fz in fazendas_plano:
        if por_fz.get(fz):
            print(f'  {fz}:')
            for cod, motivo in por_fz[fz]:
                print(f'    - {cod}: {motivo}')


if __name__ == '__main__':
    main()
