#!/usr/bin/env python3
"""
carregar_plano_api.py — carrega o plano de safra no Supabase pela API pública
(a mesma chave publishable que o app usa), sem precisar colar o SQL 006 no
SQL Editor. Faz o mesmo que sql/006-plano-safra-seed-2627.sql; opcionalmente
faz também o que sql/007-publicar-planos-2627.sql faz.

Pré-requisito: sql/005-plano-safra.sql JÁ rodado no SQL Editor (cria as
tabelas — isso a API não faz). Se as tabelas não existirem, o script para e
explica.

Entrada: docs/plano/2026-27/carga_2627.json (gerado por gerar_seed_plano.py)
         docs/plano/2026-27/auditoria_v1_resultado.json (para --publicar)

Uso:
  python3 scripts/carregar_plano_api.py --dry-run     só mostra o que faria
  python3 scripts/carregar_plano_api.py               carrega (pode repetir: não duplica)
  python3 scripts/carregar_plano_api.py --publicar    carrega e publica as versões 1 como vigentes
  python3 scripts/carregar_plano_api.py --so-conferir só confere contagens e somas no banco

URL e chave: lidas de SYNC_PADRAO no index.html (ou SUPABASE_URL / SUPABASE_KEY
no ambiente). É a chave PÚBLICA do app — nenhum segredo entra aqui.
"""
import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from collections import defaultdict
from datetime import date, datetime, timezone
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
CARGA = RAIZ / 'docs/plano/2026-27/carga_2627.json'
AUDITORIA = RAIZ / 'docs/plano/2026-27/auditoria_v1_resultado.json'
INDEX = RAIZ / 'index.html'
APROVADO_POR = 'Salvino'
TABELAS = ['unidade_manejo', 'unidade_alias', 'unidade_manejo_log', 'plano_safra', 'plano_unidade', 'plano_adubo_mes',
           'plano_calagem', 'plano_fito_mes', 'plano_fito_excecao', 'plano_gantt', 'plano_parametros']
# chave única de cada tabela (para "on conflict do nothing" via API)
CONFLITO = {'unidade_manejo': 'codigo', 'plano_safra': 'fazenda_app,safra,versao', 'plano_unidade': 'plano_id,unidade_id',
            'plano_adubo_mes': 'plano_id,unidade_id,mes,insumo', 'plano_calagem': 'plano_id,unidade_id,subarea',
            'plano_fito_excecao': 'mes,produto,fazenda_app', 'plano_gantt': 'modelo,atividade', 'plano_parametros': 'chave'}


def credenciais():
    url, chave = os.environ.get('SUPABASE_URL'), os.environ.get('SUPABASE_KEY')
    if not (url and chave):
        html = INDEX.read_text(encoding='utf-8')
        m = re.search(r'SYNC_PADRAO\s*=\s*\{\s*url:"([^"]+)",\s*chave:"([^"]+)"', html)
        if not m:
            raise SystemExit('não achei SYNC_PADRAO no index.html; defina SUPABASE_URL e SUPABASE_KEY')
        url, chave = m.group(1), m.group(2)
    return url.rstrip('/'), chave


class Api:
    def __init__(self, url, chave, dry):
        self.url, self.chave, self.dry = url, chave, dry
        self.n_req = 0

    def _req(self, metodo, caminho, corpo=None, prefer=None, extra=None):
        h = {'apikey': self.chave, 'Authorization': 'Bearer ' + self.chave, 'Content-Type': 'application/json'}
        if prefer:
            h['Prefer'] = prefer
        if extra:
            h.update(extra)
        dados = json.dumps(corpo, ensure_ascii=False).encode('utf-8') if corpo is not None else None
        r = urllib.request.Request(self.url + '/rest/v1/' + caminho, data=dados, method=metodo, headers=h)
        self.n_req += 1
        try:
            with urllib.request.urlopen(r, timeout=120) as resp:
                txt = resp.read().decode('utf-8')
                return resp.status, (json.loads(txt) if txt else None), resp.headers
        except urllib.error.HTTPError as e:
            txt = e.read().decode('utf-8', 'replace')
            return e.code, (json.loads(txt) if txt.startswith('{') else txt), e.headers

    def get(self, caminho, contar=False):
        st, corpo, cab = self._req('GET', caminho, prefer='count=exact' if contar else None,
                                   extra={'Range-Unit': 'items', 'Range': '0-0'} if contar else None)
        if st not in (200, 206):
            raise RuntimeError(f'GET {caminho}: {st} {corpo}')
        if contar:
            cr = cab.get('Content-Range', '')
            return int(cr.split('/')[-1]) if '/' in cr and cr.split('/')[-1] != '*' else 0
        return corpo

    def get_todos(self, caminho):
        """pagina de 1000 em 1000 (limite padrão do Supabase)"""
        out, ini = [], 0
        while True:
            st, corpo, cab = self._req('GET', caminho, extra={'Range-Unit': 'items', 'Range': f'{ini}-{ini + 999}'})
            if st not in (200, 206):
                raise RuntimeError(f'GET {caminho}: {st} {corpo}')
            out.extend(corpo or [])
            if not corpo or len(corpo) < 1000:
                return out
            ini += 1000

    def post(self, tabela, linhas, conflito=None):
        if not linhas:
            return 0
        if self.dry:
            print(f'   [dry-run] POST {tabela}: {len(linhas)} linha(s)' + (f' (on_conflict={conflito}, ignora repetidas)' if conflito else ''))
            return len(linhas)
        n = 0
        for i in range(0, len(linhas), 300):
            lote = linhas[i:i + 300]
            caminho = tabela + (f'?on_conflict={urllib.parse.quote(conflito)}' if conflito else '')
            prefer = 'return=minimal' + (',resolution=ignore-duplicates' if conflito else '')
            st, corpo, _ = self._req('POST', caminho, lote, prefer=prefer)
            if st not in (200, 201):
                raise RuntimeError(f'POST {tabela} (lote {i // 300 + 1}): {st} {corpo}')
            n += len(lote)
        return n

    def patch(self, caminho, corpo):
        if self.dry:
            print(f'   [dry-run] PATCH {caminho} ← {json.dumps(corpo, ensure_ascii=False)[:120]}')
            return
        st, resp, _ = self._req('PATCH', caminho, corpo, prefer='return=minimal')
        if st not in (200, 204):
            raise RuntimeError(f'PATCH {caminho}: {st} {resp}')


def f(s):
    return urllib.parse.quote(str(s), safe='')


def conferir(api, carga):
    c = carga['conferencia']
    erros = []
    cods = ','.join('"' + x + '"' for x in c['codigos'])
    n_uni = api.get(f'unidade_manejo?select=id&codigo=in.({f(cods)})', contar=True)
    if n_uni != c['unidades']:
        erros.append(f"unidades: {n_uni} (esperado {c['unidades']})")
    planos = api.get(f"plano_safra?select=id,fazenda_app&safra=eq.{f(carga['safra'])}&versao=eq.{carga['versao']}")
    ids = {p['id']: p['fazenda_app'] for p in planos}
    if len(ids) != len(c['somas_kg']):
        erros.append(f"planos v{carga['versao']}: {len(ids)} (esperado {len(c['somas_kg'])})")
    lista_ids = ','.join('"' + i + '"' for i in ids)
    adubo = api.get_todos(f'plano_adubo_mes?select=plano_id,insumo,kg&plano_id=in.({f(lista_ids)})') if ids else []
    if len(adubo) != c['adubo_linhas']:
        erros.append(f"adubo: {len(adubo)} linhas (esperado {c['adubo_linhas']})")
    somas = defaultdict(lambda: defaultdict(float))
    for a in adubo:
        somas[ids[a['plano_id']]][a['insumo']] += float(a['kg'])
    for fz, esperado in c['somas_kg'].items():
        for ins, kg in esperado.items():
            if somas[fz][ins] != kg:
                erros.append(f'{fz} / {ins}: {somas[fz][ins]:g} kg (esperado {kg})')
    cal = api.get_todos(f'plano_calagem?select=t_total&plano_id=in.({f(lista_ids)})') if ids else []
    t = sum(float(x['t_total'] or 0) for x in cal)
    if len(cal) != c['calagem_linhas'] or t != c['calagem_t']:
        erros.append(f"calagem: {len(cal)} linhas / {t:g} t (esperado {c['calagem_linhas']} / {c['calagem_t']})")
    print(f'   unidades {n_uni} · planos {len(ids)} · adubo {len(adubo)} · calagem {len(cal)} ({t:g} t)')
    return erros


def carregar(api, carga):
    print('1. renomeações de cargas antigas')
    for r in carga['renomear']:
        for tb in ['unidade_manejo', 'unidade_alias', 'plano_safra', 'plano_fito_excecao']:
            n = api.get(f"{tb}?select=fazenda_app&fazenda_app=eq.{f(r['de'])}", contar=True)
            if n:
                api.patch(f"{tb}?fazenda_app=eq.{f(r['de'])}", {'fazenda_app': r['para']})
                print(f"   {tb}: {n} linha(s) '{r['de']}' → '{r['para']}'")
    print('2. unidade_manejo (pais antes dos filhos)')
    uns = carga['unidade_manejo']
    api.post('unidade_manejo', [u for u in uns if not u['pai_id']], CONFLITO['unidade_manejo'])
    api.post('unidade_manejo', [u for u in uns if u['pai_id']], CONFLITO['unidade_manejo'])
    print(f'   {len(uns)} unidades enviadas (repetidas são ignoradas)')
    print('3. unidade_alias (só os que ainda não existem)')
    existentes = {(a['sistema'], a['fazenda_app'], a['alias']) for a in api.get_todos('unidade_alias?select=sistema,fazenda_app,alias&vigente_ate=is.null')}
    novos = [a for a in carga['unidade_alias'] if (a['sistema'], a['fazenda_app'], a['alias']) not in existentes]
    api.post('unidade_alias', novos)
    print(f"   {len(novos)} novos de {len(carga['unidade_alias'])}")
    print('4. plano_safra, plano_unidade, adubo, calagem')
    for tb in ['plano_safra', 'plano_unidade', 'plano_adubo_mes', 'plano_calagem']:
        api.post(tb, carga[tb], CONFLITO[tb])
        print(f'   {tb}: {len(carga[tb])} enviadas')
    print('5. fito (grupo), exceções, gantt, parâmetros')
    meses = {x['mes'] for x in api.get('plano_fito_mes?select=mes&plano_id=is.null')}
    novos = [x for x in carga['plano_fito_mes'] if x['mes'] not in meses]
    api.post('plano_fito_mes', novos)
    print(f"   plano_fito_mes: {len(novos)} novos de {len(carga['plano_fito_mes'])}")
    for tb in ['plano_fito_excecao', 'plano_gantt', 'plano_parametros']:
        api.post(tb, carga[tb], CONFLITO[tb])
        print(f'   {tb}: {len(carga[tb])} enviadas')


def publicar(api, carga):
    aud = json.loads(AUDITORIA.read_text(encoding='utf-8'))
    hoje = date.today().isoformat()
    agora = datetime.now(timezone.utc).isoformat()
    n = 0
    for fz, r in aud['fazendas'].items():
        base = f"plano_safra?fazenda_app=eq.{f(fz)}&safra=eq.{f(carga['safra'])}"
        api.patch(f"{base}&versao=eq.{carga['versao']}&status=eq.rascunho", {'auditoria_ok': r['ok'], 'auditoria_json': r})
        if not r['ok']:
            print(f'   ✗ {fz}: auditoria com bloqueio — não publica')
            continue
        api.patch(f"{base}&status=eq.vigente&versao=neq.{carga['versao']}", {'status': 'superado'})
        api.patch(f"{base}&versao=eq.{carga['versao']}&status=eq.rascunho&auditoria_ok=is.true&aprovado_por=is.null", {'aprovado_por': APROVADO_POR})
        api.patch(f"{base}&versao=eq.{carga['versao']}&status=eq.rascunho&auditoria_ok=is.true",
                  {'status': 'vigente', 'vigente_de': hoje, 'aprovado_em': agora})
        n += 1
        print(f'   ✔ {fz}: versão {carga["versao"]} vigente')
    vig = api.get(f"plano_safra?select=fazenda_app,versao,status&safra=eq.{f(carga['safra'])}&status=eq.vigente") if not api.dry else []
    if not api.dry:
        print(f'   vigentes na safra: {len(vig)}')
    return n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('--publicar', action='store_true')
    ap.add_argument('--so-conferir', action='store_true')
    args = ap.parse_args()
    carga = json.loads(CARGA.read_text(encoding='utf-8'))
    url, chave = credenciais()
    api = Api(url, chave, args.dry_run)
    print(f'Supabase: {url} (chave publishable do app)')
    faltam = []
    for tb in TABELAS:
        st, corpo, _ = api._req('GET', f'{tb}?select=*&limit=0')
        if st == 404:
            faltam.append(tb)
        elif st != 200:
            raise SystemExit(f'{tb}: resposta {st} {corpo}')
    if faltam:
        print('\nAs tabelas do plano ainda não existem no Supabase: ' + ', '.join(faltam))
        print('Rode sql/005-plano-safra.sql no SQL Editor (Dashboard do Supabase › SQL Editor › New query › colar › Run) e chame este script de novo.')
        sys.exit(2)
    print('Tabelas do plano: ok')
    if not args.so_conferir:
        carregar(api, carga)
    print('6. conferência no banco')
    erros = [] if args.dry_run else conferir(api, carga)
    if erros:
        print('   CONFERÊNCIA FALHOU:')
        for e in erros:
            print('   ✗', e)
        print('   (a carga pela API não é atômica; rode de novo — repetidas são ignoradas — e, se persistir, avise)')
        sys.exit(3)
    print('   ✔ contagens e somas batem com o seed')
    if args.publicar:
        print('7. publicar versões como vigentes')
        publicar(api, carga)
    print(f'\nfeito ({api.n_req} chamadas à API)')


if __name__ == '__main__':
    main()
