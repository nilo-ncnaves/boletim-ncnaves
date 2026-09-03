#!/usr/bin/env python3
"""
gerar_publicacao_plano.py — gera sql/007-publicar-planos-2627.sql, o atalho
OPCIONAL para publicar como VIGENTE, de uma vez, as versões 1 dos 8 planos
da safra 2026/27 (em vez de fazer fazenda por fazenda na tela de Escritório).

Entrada: docs/plano/2026-27/auditoria_v1_resultado.json — resultado da
auditoria (a mesma função auditarPlano() do index.html) rodada sobre os dados
do seed; o SQL grava esse resultado em plano_safra.auditoria_json e só publica
os planos cuja auditoria passou (ok = true).

Regras que o SQL respeita:
  - só publica versão em rascunho e com auditoria ok;
  - "aprovado_por" tem que ser o nome de quem aprovou (o agrônomo);
  - a versão vigente anterior (se houver) passa a "superado";
  - continua valendo uma vigente por fazenda-safra (índice único).

Uso:  python3 scripts/gerar_publicacao_plano.py   (na raiz do repositório)
"""
import json
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
ENTRADA = RAIZ / 'docs/plano/2026-27/auditoria_v1_resultado.json'
SAIDA = RAIZ / 'sql/007-publicar-planos-2627.sql'
SAFRA = '2026/27'
VERSAO = 1
APROVADO_POR = 'Salvino'  # <<< trocar aqui se quem aprovou for outro


def q(v):
    if v is None:
        return 'null'
    return "'" + str(v).replace("'", "''") + "'"


def main():
    aud = json.loads(ENTRADA.read_text(encoding='utf-8'))
    L = []
    w = L.append
    w('-- Publicar os planos 2026/27 como VIGENTES — atalho OPCIONAL (v52)')
    w('-- Rodar no SQL Editor do Supabase DEPOIS do sql/005 e do sql/006, e SÓ quando o')
    w('-- agrônomo tiver aprovado o plano. O caminho normal é a tela Escritório ›')
    w('-- Cadastros › Unidades e Plano (Rodar auditoria → Aprovado por → Publicar),')
    w('-- fazenda por fazenda; este arquivo faz o mesmo de uma vez.')
    w('--')
    w('-- Gerado por scripts/gerar_publicacao_plano.py a partir de')
    w('-- docs/plano/2026-27/auditoria_v1_resultado.json (auditoria rodada em %s' % aud.get('quando', '?'))
    w('-- sobre os mesmos dados do seed, com a função auditarPlano() do app).')
    w('-- Só publica versão em rascunho com auditoria ok; a vigente anterior vira "superado".')
    w('-- Pode ser rodado de novo: plano já vigente não muda.')
    w('')
    w('begin;')
    w('')
    n_pub = 0
    for fz, r in aud['fazendas'].items():
        j = json.dumps(r, ensure_ascii=False)
        w('-- %s — auditoria %s' % (fz, 'OK' if r['ok'] else 'COM BLOQUEIO (não publica)'))
        w("update public.plano_safra set auditoria_ok = %s, auditoria_json = %s::jsonb" % ('true' if r['ok'] else 'false', q(j)))
        w("  where fazenda_app = %s and safra = %s and versao = %d and status = 'rascunho';" % (q(fz), q(SAFRA), VERSAO))
        if r['ok']:
            w("update public.plano_safra set status = 'superado' where fazenda_app = %s and safra = %s and status = 'vigente' and versao <> %d;" % (q(fz), q(SAFRA), VERSAO))
            w("update public.plano_safra set status = 'vigente', vigente_de = current_date, aprovado_por = coalesce(aprovado_por, %s), aprovado_em = coalesce(aprovado_em, now())" % q(APROVADO_POR))
            w("  where fazenda_app = %s and safra = %s and versao = %d and status = 'rascunho' and auditoria_ok;" % (q(fz), q(SAFRA), VERSAO))
            n_pub += 1
        w('')
    w('-- conferência: uma vigente por fazenda')
    w('do $$')
    w('declare n integer;')
    w('begin')
    w("  select count(*) into n from public.plano_safra where safra = %s and status = 'vigente';" % q(SAFRA))
    w("  raise notice 'planos vigentes na safra %s: %%', n;" % SAFRA)
    w('end $$;')
    w('')
    w('commit;')
    SAIDA.write_text('\n'.join(L) + '\n', encoding='utf-8')
    print(f'✔ {SAIDA.relative_to(RAIZ)}: {n_pub} de {len(aud["fazendas"])} planos serão publicados (aprovado por: {APROVADO_POR})')
    for fz, r in aud['fazendas'].items():
        bloq = [i['titulo'] for i in r['itens'] if i['bloqueante'] and not i['ok']]
        print(f"  {'✔' if r['ok'] else '✗'} {fz}" + (f' — bloqueio: {bloq}' if bloq else ''))


if __name__ == '__main__':
    main()
