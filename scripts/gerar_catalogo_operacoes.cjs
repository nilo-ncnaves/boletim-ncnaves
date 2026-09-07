#!/usr/bin/env node
/*
 gerar_catalogo_operacoes.cjs — imprime o seed do catálogo de operações
 (tabelas operacao_catalogo e operacao_alias do Supabase) a partir das
 constantes do index.html: LISTA_ATIV (café), OPS_GRAOS_FASES (grãos) e
 OPS_PECUARIA_FASES (pecuária). Fonte oficial do vocabulário:
 docs/catalogos-por-atividade.md — o catálogo do Supabase é um espelho
 dele, no mesmo espírito de rel_unidades (espelho de FAZENDAS).

 Uso (na raiz do repositório):
   node scripts/gerar_catalogo_operacoes.cjs > /tmp/seed.sql
 O resultado já está colado dentro de sql/040-dias-sem-registro.sql.
 Mudou catálogo no index.html? Rode de novo e substitua o trecho entre
 os marcadores "-- >>> seed gerado" e "-- <<< seed gerado" do 040.

 Regras (CLAUDE.md, regra 6 do projeto): a identidade da operação é o
 código (operacao_catalogo.id); o nome que o app grava no payload entra
 só como apelido em operacao_alias, casado por igualdade EXATA — nunca
 por pedaço de nome.
*/
const fs = require('fs');
const path = require('path');
const html = fs.readFileSync(path.join(__dirname, '..', 'index.html'), 'utf8');

function constante(nome) {
  const ini = html.indexOf('const ' + nome + ' ');
  const ini2 = html.indexOf('const ' + nome + '=');
  const i = ini >= 0 && (ini2 < 0 || ini < ini2) ? ini : ini2;
  if (i < 0) throw new Error('constante não encontrada: ' + nome);
  const fim = html.indexOf('];', i);
  const trecho = html.slice(i, fim + 2).replace(/^const\s+\w+\s*=\s*/, '');
  return eval(trecho); // arrays literais de texto, sem código
}
const semAcento = s => String(s).normalize('NFD').replace(/[̀-ͯ]/g, '');
const codigo = (prefixo, nome) => prefixo + '-' + semAcento(nome).toUpperCase().replace(/\(.*?\)/g, '').replace(/[^A-Z0-9]+/g, '_').replace(/^_+|_+$/g, '');
const q = s => "'" + String(s).replace(/'/g, "''") + "'";

const cafe = constante('LISTA_ATIV').filter(n => n !== 'Outra');         // "Outra" não é operação identificável
const graos = constante('OPS_GRAOS_FASES');
const pec = constante('OPS_PECUARIA_FASES');

const cat = [], alias = [];
cafe.forEach((n, i) => { cat.push(['CAFE', codigo('CAFE', n), null, n, i + 1]); alias.push([codigo('CAFE', n), 'atividades.tipo', n]); });
let ordem = 0;
graos.forEach(([fase, ops]) => ops.forEach(n => { ordem++; cat.push(['GRAOS', codigo('GRAOS', n), fase, n, ordem]); alias.push([codigo('GRAOS', n), 'atividades.tipo', n]); }));
ordem = 0;
pec.forEach(([fase, ops]) => ops.forEach(n => { ordem++; cat.push(['PECUARIA', codigo('PEC', n), fase, n, ordem]); alias.push([codigo('PEC', n), 'pecuaria.eventos.tipo', n]); }));

/* blocos estruturados da pecuária (v50) que já são registro de uma operação do
   catálogo — chip exato gravado pelo app → operação. "*" = basta existir a linha. */
const pecId = n => { const c = cat.find(r => r[0] === 'PECUARIA' && r[3] === n); if (!c) throw new Error('op de pecuária não achada: ' + n); return c[1]; };
[
  ['pecuaria.mov.tipo', 'Nascimento', 'Parto / nascimento'],
  ['pecuaria.mov.tipo', 'Morte', 'Mortalidade (com causa)'],
  ['pecuaria.mov.tipo', 'Desmama', 'Desmama'],
  ['pecuaria.mov.tipo', 'Mudança de pasto', 'Rotação de pasto — entrada de lote'],
  ['pecuaria.mov.tipo', 'Mudança de pasto', 'Rotação de pasto — saída de lote'],
  ['pecuaria.mov.tipo', 'Entrada', 'Compra / entrada de animais'],
  ['pecuaria.mov.tipo', 'Saída', 'Embarque / venda'],
  ['pecuaria.massa.tipo', 'Vacinação', 'Vacinação (especificar)'],
  ['pecuaria.massa.tipo', 'Vermifugação', 'Vermifugação'],
  ['pecuaria.san.problema', 'Bicheira', 'Cura de bicheira'],
  ['pecuaria.san.problema', 'Carrapato / mosca em excesso', 'Controle de carrapato / mosca-do-chifre'],
  ['pecuaria.lotes', '*', 'Contagem'],
  ['pecuaria.nut', '*', 'Suplementação (sal mineral / proteinado / ração)'],
  ['pecuaria.rep.iatf', '*', 'IATF'],
  ['pecuaria.rep.dg', '*', 'Diagnóstico de gestação'],
].forEach(([origem, termo, op]) => alias.push([pecId(op), origem, termo]));

const ids = new Set(); cat.forEach(r => { if (ids.has(r[1])) throw new Error('código repetido: ' + r[1]); ids.add(r[1]); });

let out = '';
out += '-- >>> seed gerado por scripts/gerar_catalogo_operacoes.cjs (' + cat.length + ' operações, ' + alias.length + ' apelidos)\n';
out += 'insert into public.operacao_catalogo (id, atividade, fase, nome, ordem) values\n';
out += cat.map(r => `  (${q(r[1])}, ${q(r[0])}, ${r[2] === null ? 'null' : q(r[2])}, ${q(r[3])}, ${r[4]})`).join(',\n');
out += '\non conflict (id) do update set atividade = excluded.atividade, fase = excluded.fase, nome = excluded.nome, ordem = excluded.ordem;\n\n';
out += 'insert into public.operacao_alias (operacao_id, origem, termo) values\n';
out += alias.map(r => `  (${q(r[0])}, ${q(r[1])}, ${q(r[2])})`).join(',\n');
out += '\non conflict (operacao_id, origem, termo) do nothing;\n';
out += '-- <<< seed gerado\n';
process.stdout.write(out);
