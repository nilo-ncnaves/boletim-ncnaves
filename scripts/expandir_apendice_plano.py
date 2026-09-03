#!/usr/bin/env python3
"""
expandir_apendice_plano.py — transforma o apêndice compacto do plano de safra
(docs/plano/2026-27/apendice_dados.md) no JSON expandido
(docs/plano/2026-27/plano_2627_seed.json).

Regra de ouro: o script NÃO inventa, NÃO completa e NÃO corrige valores.
Campo vazio no apêndice vira null no JSON. Se alguma conferência obrigatória
falhar, o script para com erro (o defeito está na expansão, nunca nos dados).

Uso:
  python3 scripts/expandir_apendice_plano.py \
      docs/plano/2026-27/apendice_dados.md docs/plano/2026-27/plano_2627_seed.json
"""
import json
import re
import sys
from collections import OrderedDict

INSUMO_ABREV = {'U': 'ureia', 'Ni': 'nitrato', 'SA': 'sulfato_amonio', 'K': 'kcl',
                'Ph': 'phusion', 'Mn': 'sulfato_mn', 'B': 'acido_borico', 'Zn': 'sulfato_zn'}
INSUMOS = list(INSUMO_ABREV.values())

# Conferências obrigatórias (item A0 do pedido). A ordem dos kg é a de INSUMOS.
CONFERENCIA_KG = {
    'Vereda Café':               [71000, 306000, 163500, 369000, 3500, 4700, 10625, 6125],
    'Rio Preto-Lagamar — Café':  [55000, 223500, 101000, 150000, 0, 3525, 7650, 4425],
    'Vereda Romaria':            [34500, 136000, 60500, 177000, 4500, 2100, 4950, 2600],
    'Vereda Café 5º e 6º':       [23500, 101000, 45500, 91000, 0, 1550, 3500, 1950],
    'Água Limpa':                [17000, 74000, 33000, 77500, 2000, 1175, 2500, 1500],
    'Monte Carmelo — Café':      [61500, 251000, 115000, 211000, 32500, 4050, 8600, 4825],
    'Lagamar Café – Rodrigo':    [40000, 169500, 76500, 105000, 0, 2700, 5800, 3250],
    'Mata Preta - Café':         [31000, 124000, 57000, 86000, 9000, 2050, 4300, 2425],
}
ESPERADO = {'unidades': 69, 'calagem_linhas': 71, 'calagem_t': 4648, 'adubo_linhas': 1533,
            'fito_meses': 10, 'gantt_linhas': 32, 'auditoria_itens': 12}


def numero(txt):
    """'16' -> 16, '2,5' -> 2.5, '' -> None. Nunca inventa valor."""
    t = (txt or '').strip()
    if t == '':
        return None
    t = t.replace(',', '.')
    v = float(t)
    return int(v) if v == int(v) else v


def texto(txt):
    t = (txt or '').strip()
    return t if t else None


def ler_secoes(caminho):
    secoes = OrderedDict()
    atual = None
    with open(caminho, encoding='utf-8') as f:
        for linha in f:
            linha = linha.rstrip('\n')
            if linha.startswith('### '):
                atual = linha[4:].split()[0]
                secoes[atual] = []
                continue
            if atual is None or not linha.strip():
                continue
            secoes[atual].append(linha)
    return secoes


def campos(linha, n=None):
    partes = [p.strip() for p in linha.split('|')]
    if n is not None:
        if len(partes) < n:
            partes += [''] * (n - len(partes))
        if len(partes) > n:
            raise ValueError(f'linha com {len(partes)} campos (esperado {n}): {linha}')
    return partes


def dividir_fora_de_parenteses(s, sep):
    out, cur, nivel = [], '', 0
    for ch in s:
        if ch == '(':
            nivel += 1
        elif ch == ')':
            nivel -= 1
        if ch == sep and nivel == 0:
            out.append(cur)
            cur = ''
        else:
            cur += ch
    out.append(cur)
    return [p for p in out if p.strip()]


def expandir(secoes):
    out = OrderedDict()
    out['safra'] = '2026/27'
    out['origem'] = '7 PPTX do agrônomo, extraídos por XML em 03/09/2026'

    out['fazendas'] = []
    for l in secoes['FAZENDAS']:
        fz, emp, gantt, deck = campos(l, 4)
        out['fazendas'].append(OrderedDict(fazenda_app=fz, empresa=emp, gantt_modelo=gantt, deck=deck))

    out['unidades'] = []
    for l in secoes['UNIDADES']:
        cod, fz, nome, aliases, area, fonte, zerada, area_z, pai, obs = campos(l, 10)
        out['unidades'].append(OrderedDict(
            codigo=cod, fazenda_app=fz, nome_plano=nome,
            aliases_plano=[a.strip() for a in aliases.split(';') if a.strip()],
            area_ha=numero(area), fonte_area=texto(fonte), safra_zerada_tipo=texto(zerada),
            area_zerada_ha=numero(area_z), pai=texto(pai), obs=texto(obs)))

    out['calagem'] = []
    for l in secoes['CALAGEM']:
        cod, sub, t_ha, t_tot, rateado = campos(l, 5)
        if rateado not in ('sim', 'não'):
            raise ValueError(f'rateado inválido em: {l}')
        out['calagem'].append(OrderedDict(codigo=cod, subarea=sub, t_ha=numero(t_ha),
                                          t_total=numero(t_tot), rateado=(rateado == 'sim')))

    out['adubo_mes'] = []
    item_re = re.compile(r'^(U|Ni|SA|K|Ph|Mn|B|Zn)=(\d+(?:[.,]\d+)?)(?:\((.*)\))?$')
    for l in secoes['ADUBO_MES']:
        cod, prog = campos(l, 2)
        for bloco in prog.split(';'):
            bloco = bloco.strip()
            if not bloco:
                continue
            mes_txt, itens = bloco.split(':', 1)
            mes = int(mes_txt)
            if not 1 <= mes <= 12:
                raise ValueError(f'mês inválido em {cod}: {bloco}')
            for item in dividir_fora_de_parenteses(itens, ','):
                m = item_re.match(item.strip())
                if not m:
                    raise ValueError(f'item de adubo não reconhecido em {cod}: "{item}"')
                out['adubo_mes'].append(OrderedDict(codigo=cod, mes=mes, insumo=INSUMO_ABREV[m.group(1)],
                                                    kg=numero(m.group(2)), obs=texto(m.group(3))))

    out['resumo_fazenda'] = []
    for l in secoes['RESUMO_FAZENDA']:
        fz, itens = campos(l, 2)
        for item in itens.split(','):
            ab, kg = item.split('=')
            out['resumo_fazenda'].append(OrderedDict(fazenda_app=fz, insumo=INSUMO_ABREV[ab.strip()], kg=numero(kg)))

    out['fito_mes'] = []
    exc_re = re.compile(r'^(.+?) em (.+)$')
    for l in secoes['FITO_MES']:
        mes, fase, alvos, produtos, via_solo, excecao = campos(l, 6)
        exc = OrderedDict()
        if excecao.strip():
            m = exc_re.match(excecao.strip())
            if not m:
                raise ValueError(f'exceção de via solo não reconhecida: {excecao}')
            exc[m.group(1).strip()] = [f.strip() for f in m.group(2).split(',') if f.strip()]
        lista = lambda s: [x.strip() for x in s.split(',') if x.strip()]
        out['fito_mes'].append(OrderedDict(mes=int(mes), fase=texto(fase), alvos=lista(alvos),
                                           produtos=lista(produtos), via_solo=lista(via_solo),
                                           via_solo_excecao=exc))

    out['gantt'] = OrderedDict()
    for l in secoes['GANTT']:
        modelo, ativ, meses = campos(l, 3)
        out['gantt'].setdefault(modelo, OrderedDict())[ativ] = [int(x) for x in meses.split(',') if x.strip()]

    out['auditoria_v1'] = [re.sub(r'^-\s*', '', l).strip() for l in secoes['AUDITORIA_V1']]
    return out


def conferir(d):
    erros = []
    fazendas = {f['fazenda_app'] for f in d['fazendas']}
    if len(d['unidades']) != ESPERADO['unidades']:
        erros.append(f"unidades: {len(d['unidades'])} (esperado {ESPERADO['unidades']})")
    codigos = [u['codigo'] for u in d['unidades']]
    if len(set(codigos)) != len(codigos):
        erros.append('códigos de unidade repetidos')
    for u in d['unidades']:
        if u['fazenda_app'] not in fazendas:
            erros.append(f"unidade {u['codigo']} com fazenda desconhecida: {u['fazenda_app']}")
        if u['pai'] and u['pai'] not in codigos:
            erros.append(f"unidade {u['codigo']} com pai desconhecido: {u['pai']}")
    if len(d['calagem']) != ESPERADO['calagem_linhas']:
        erros.append(f"calagem: {len(d['calagem'])} linhas (esperado {ESPERADO['calagem_linhas']})")
    soma_t = sum(c['t_total'] or 0 for c in d['calagem'])
    if soma_t != ESPERADO['calagem_t']:
        erros.append(f"calagem: soma {soma_t} t (esperado {ESPERADO['calagem_t']})")
    for c in d['calagem']:
        if c['codigo'] not in codigos:
            erros.append(f"calagem com código desconhecido: {c['codigo']}")
    if len(d['adubo_mes']) != ESPERADO['adubo_linhas']:
        erros.append(f"adubo_mes: {len(d['adubo_mes'])} linhas (esperado {ESPERADO['adubo_linhas']})")
    faz_de = {u['codigo']: u['fazenda_app'] for u in d['unidades']}
    somas = {fz: {i: 0 for i in INSUMOS} for fz in fazendas}
    for a in d['adubo_mes']:
        if a['codigo'] not in faz_de:
            erros.append(f"adubo com código desconhecido: {a['codigo']}")
            continue
        somas[faz_de[a['codigo']]][a['insumo']] += a['kg']
    for fz, esperado in CONFERENCIA_KG.items():
        obtido = [somas[fz][i] for i in INSUMOS]
        if obtido != esperado:
            erros.append(f'soma de kg de {fz}: obtido {obtido}, esperado {esperado}')
    if len(d['fito_mes']) != ESPERADO['fito_meses']:
        erros.append(f"fito_mes: {len(d['fito_mes'])} meses (esperado {ESPERADO['fito_meses']})")
    n_gantt = sum(len(v) for v in d['gantt'].values())
    if n_gantt != ESPERADO['gantt_linhas']:
        erros.append(f'gantt: {n_gantt} linhas (esperado {ESPERADO["gantt_linhas"]})')
    if len(d['auditoria_v1']) != ESPERADO['auditoria_itens']:
        erros.append(f"auditoria_v1: {len(d['auditoria_v1'])} itens (esperado {ESPERADO['auditoria_itens']})")
    return erros, somas, soma_t


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    entrada, saida = sys.argv[1], sys.argv[2]
    d = expandir(ler_secoes(entrada))
    erros, somas, soma_t = conferir(d)
    print(f"unidades: {len(d['unidades'])} · calagem: {len(d['calagem'])} linhas / {soma_t} t · "
          f"adubo_mes: {len(d['adubo_mes'])} · fito: {len(d['fito_mes'])} meses · "
          f"gantt: {sum(len(v) for v in d['gantt'].values())} · auditoria: {len(d['auditoria_v1'])}")
    for fz in CONFERENCIA_KG:
        print(f"  {fz}: {[somas[fz][i] for i in INSUMOS]}")
    if erros:
        print('\nCONFERÊNCIA FALHOU — corrija a expansão, nunca os dados:')
        for e in erros:
            print('  ✗', e)
        sys.exit(2)
    with open(saida, 'w', encoding='utf-8') as f:
        json.dump(d, f, ensure_ascii=False, indent=1)
        f.write('\n')
    print(f'\n✔ todas as conferências passaram · gravado em {saida}')


if __name__ == '__main__':
    main()
