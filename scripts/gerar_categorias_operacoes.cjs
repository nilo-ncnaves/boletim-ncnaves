#!/usr/bin/env node
/*
 gerar_categorias_operacoes.cjs — confere o catálogo de CATEGORIAS de operação
 (constante OP_CATEGORIAS do index.html, v67: badge de uma letra nas listas de
 leitura) e imprime o espelho em SQL para o Supabase (tabela operacao_categoria
 + coluna categoria_id em operacao_catalogo), já colado em
 sql/046-operacao-categoria.sql. Fonte oficial: docs/catalogos-por-atividade.md,
 seção "Categorias de operação (badge)".

 Uso (na raiz do repositório):
   node scripts/gerar_categorias_operacoes.cjs            # confere e imprime a tabela por atividade
   node scripts/gerar_categorias_operacoes.cjs --sql      # imprime o trecho SQL (recolar no sql/046)

 O que confere (regras do PR da v67):
   - no máximo 5 categorias por atividade;
   - letra única dentro da atividade, uma letra maiúscula, presente no nome;
   - toda operação do catálogo (LISTA_ATIV sem "Outra", OPS_GRAOS_FASES,
     OPS_PECUARIA_FASES) cai em UMA categoria, pelo id da operação
     (mesma regra de código de scripts/gerar_catalogo_operacoes.cjs) — nunca
     por pedaço de nome;
   - id de operação citado em `operacoes` existe no catálogo.
 Sai com código 1 se alguma regra falhar. Não é parte do app.
*/
const fs = require('fs');
const path = require('path');
const html = fs.readFileSync(path.join(__dirname, '..', 'index.html'), 'utf8');
const sql = process.argv.includes('--sql');

function trecho(ini, fim) { const i = html.indexOf(ini); if (i < 0) throw new Error('não achei ' + ini); const j = html.indexOf(fim, i); return html.slice(i, j + fim.length); }
const src = [
  trecho('const OPS_CAFE_GRUPOS = [', '\n];\n'),
  trecho('const OPS_GRAOS_FASES=[', '\n];\n'),
  trecho('const OPS_PECUARIA_FASES=[', '\n];\n'),
  trecho('const OP_CATEGORIAS={', '\n};\n'),
  trecho('const codigoOperacao=', '\n'),
  trecho('const OP_CATALOGO_FONTE=', '\n'),
].join('\n');
const { OP_CATEGORIAS, OP_CATALOGO_FONTE, codigoOperacao } = new Function(src + '\nreturn {OP_CATEGORIAS, OP_CATALOGO_FONTE, codigoOperacao};')();
const semAcento = s => String(s).normalize('NFD').replace(/[̀-ͯ]/g, '');
const q = s => "'" + String(s).replace(/'/g, "''") + "'";

let erros = 0, out = [], cats = [], ligacoes = [];
const err = m => { erros++; console.error('❌ ' + m); };
Object.keys(OP_CATEGORIAS).forEach(atv => {
  const lista = OP_CATEGORIAS[atv];
  if (lista.length > 5) err(atv + ': mais de 5 categorias');
  const letras = lista.map(c => c.letra);
  if (new Set(letras).size !== letras.length) err(atv + ': letra repetida (' + letras.join(' ') + ')');
  lista.forEach((c, i) => {
    if (!/^[A-Z]$/.test(c.letra)) err(atv + '/' + c.id + ': letra deve ser UMA maiúscula');
    if (!semAcento(c.nome).toUpperCase().includes(c.letra)) err(atv + '/' + c.id + ': a letra não aparece no nome');
    cats.push([atv + '-' + c.id, atv, c.letra, c.nome, i + 1]);
  });
  const [pref, fases] = OP_CATALOGO_FONTE[atv]();
  const ids = new Set();
  fases.forEach(([fase, ops]) => ops.forEach(nome => {
    const id = codigoOperacao(pref, nome); ids.add(id);
    const cat = lista.filter(c => (c.fase != null && c.fase === fase) || (c.operacoes || []).includes(id));
    if (cat.length !== 1) err(atv + ': ' + nome + ' (' + id + ') cai em ' + cat.length + ' categorias');
    else ligacoes.push([id, atv + '-' + cat[0].id]);
  }));
  lista.forEach(c => (c.operacoes || []).forEach(id => { if (!ids.has(id)) err(atv + '/' + c.id + ': operação inexistente ' + id); }));
  if (!sql) {
    out.push('\n' + atv + ' — ' + lista.length + ' categorias, ' + ids.size + ' operações');
    lista.forEach(c => out.push('  ' + c.letra + '  ' + c.nome + ': ' + ligacoes.filter(l => l[1] === atv + '-' + c.id).map(l => l[0]).join(', ')));
  }
});
if (erros) { console.error(erros + ' problema(s) no catálogo de categorias'); process.exit(1); }
if (!sql) { console.log(out.join('\n')); console.log('\n✅ catálogo de categorias consistente'); process.exit(0); }

let s = '';
s += '-- >>> seed gerado por scripts/gerar_categorias_operacoes.cjs (' + cats.length + ' categorias, ' + ligacoes.length + ' operações ligadas)\n';
s += 'insert into public.operacao_categoria (id, atividade, letra, nome, ordem) values\n';
s += cats.map(r => `  (${q(r[0])}, ${q(r[1])}, ${q(r[2])}, ${q(r[3])}, ${r[4]})`).join(',\n');
s += '\non conflict (id) do update set atividade = excluded.atividade, letra = excluded.letra, nome = excluded.nome, ordem = excluded.ordem;\n\n';
s += 'update public.operacao_catalogo as o set categoria_id = v.categoria_id\n  from (values\n';
s += ligacoes.map(r => `    (${q(r[0])}, ${q(r[1])})`).join(',\n');
s += '\n  ) as v (operacao_id, categoria_id)\n  where o.id = v.operacao_id;\n';
s += '-- <<< seed gerado\n';
process.stdout.write(s);
