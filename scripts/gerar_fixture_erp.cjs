#!/usr/bin/env node
/*
 gerar_fixture_erp.cjs — gera o PDF SINTÉTICO do relatório "Aplicações de
 Insumos - Resumido" do AgroGestão (AgroLavoura 5.26.11.0) usado nas provas da
 v96 (baixa do ERP × app).

 POR QUE SINTÉTICO. O PDF real de 15/09/2026 (fertirrigação da Vereda Romaria)
 não foi subido em tests/fixtures/. Este script reproduz o MESMO layout e os
 MESMOS números da tabela da tarefa (8 glebas × 3 insumos = 24 linhas,
 164,90 ha, 1.900 / 775 / 950 kg), inclusive as duas armadilhas que o leitor
 por posição precisa vencer: nome de insumo QUEBRADO em duas linhas ("SULFATO
 DE MANG" / "ANES BRANCO 31%") e as colunas de data final / hora final da
 linha quebrada caindo na SEGUNDA linha visual. Quando o Nilo subir o PDF real
 em tests/fixtures/erp-ferti-vereda-romaria-2026-09-15.pdf, basta trocar o
 arquivo — os testes não mudam (pendência registrada no ESTADO.md).

 Uso (na raiz do repositório):
   node scripts/gerar_fixture_erp.cjs
 Escreve tests/fixtures/erp-ferti-vereda-romaria-2026-09-15.pdf. Sem
 dependência nenhuma: o PDF é escrito à mão (Helvetica, WinAnsi).
*/
const fs = require('fs');
const path = require('path');

const SAIDA = path.resolve(__dirname, '..', 'tests', 'fixtures', 'erp-ferti-vereda-romaria-2026-09-15.pdf');

/* ---- os números da tarefa (item 1 do prompt) ---- */
const GLEBAS = [
  ['SETOR 1 ROMARIA', 21.00, '16:22:44', 300, 14.2857, 125, 5.9524, 150, 7.1429],
  ['SETOR 2 ROMARIA', 22.15, '16:24:39', 200, 9.0293, 100, 4.5147, 100, 4.5147],
  ['SETOR 3 ROMARIA', 22.15, '16:27:54', 250, 11.2867, 100, 4.5147, 125, 5.6433],
  ['SETOR 4 ROMARIA', 22.15, '16:29:18', 250, 11.2867, 100, 4.5147, 125, 5.6433],
  ['SETOR 5 ROMARIA', 22.15, '16:30:38', 200, 9.0293, 100, 4.5147, 100, 4.5147],
  ['SETOR 6 ROMARIA', 22.15, '16:32:01', 200, 9.0293, 100, 4.5147, 100, 4.5147],
  ['SETOR 7 ROMARIA', 22.15, '16:33:18', 200, 9.0293, 100, 4.5147, 100, 4.5147],
  ['SETOR 8 ROMARIA', 11.00, '16:34:36', 300, 27.2727, 50, 4.5455, 150, 13.6364],
];
const INSUMOS = ['ACIDO BORICO', 'SULFATO DE MANGANES BRANCO 31%', 'SULFATO DE ZINCO 20%'];

/* ---- formatação brasileira do ERP: 4 casas, vírgula decimal, ponto de milhar ---- */
const br4 = v => { const [i, d] = v.toFixed(4).split('.'); return i.replace(/\B(?=(\d{3})+(?!\d))/g, '.') + ',' + d; };

/* ---- larguras aproximadas da Helvetica (por 1000 de em) para alinhar à direita ---- */
const W = { '0': 556, '1': 556, '2': 556, '3': 556, '4': 556, '5': 556, '6': 556, '7': 556, '8': 556, '9': 556, '.': 278, ',': 278, ' ': 278, ':': 278, '/': 278, '%': 889, '(': 333, ')': 333, '-': 333 };
const largura = (s, tam) => [...s].reduce((a, ch) => a + (W[ch] || (ch === ch.toUpperCase() ? 667 : 556)), 0) * tam / 1000;

/* ---- página A4 deitada: 842 × 595 pt ---- */
const PAG = { w: 842, h: 595 };
/* âncoras das colunas (x do início do título) — Insumo é ESTREITA de propósito (72 pt) para o nome quebrar */
const COL = { dataIni: 40, horaIni: 96, dataFim: 134, horaFim: 190, operacao: 228, insumo: 300, un: 372, area: 396, doseHa: 450, doseTrat: 508, dose100: 570, qtde: 640 };
const COL_FIM = { qtde: 720 };   /* borda direita da última coluna */
const dir = (k, s, tam) => { const prox = Object.values(COL).find(x => x > COL[k]) || COL_FIM.qtde; return prox - 6 - largura(s, tam); };

const paginas = [[]];   /* páginas de {x, y, txt, bold, tam} */
const T = (x, y, txt, o) => paginas[paginas.length - 1].push({ x, y, txt, bold: !!(o && o.bold), tam: (o && o.tam) || 7 });
let y;
const TIT = { dataIni: 'Data Inicial', horaIni: 'Hora I.', dataFim: 'Data Final', horaFim: 'Hora F.', operacao: 'Operação', insumo: 'Insumo', un: 'Un.', area: 'Área aplic.', doseHa: 'Dose/ha', doseTrat: 'Dose Trat.', dose100: 'Dose/100Kg', qtde: 'Qtde. Total' };
/* cabeçalho de página, como o ERP repete: título, filtros (só na 1ª) e a linha de títulos das colunas */
function cabecalho(primeira) {
  y = PAG.h - 30;
  T(300, y, 'Aplicações de Insumos - Resumido', { bold: true, tam: 11 }); T(40, y, 'AgroLavoura 5.26.11.0', { tam: 7 });
  y -= 22;
  if (primeira) {
    T(40, y, 'Filtros', { bold: true }); y -= 11;
    const filtro = (rot, val) => { T(40, y, rot + ':', { bold: true }); T(40 + largura(rot + ':', 7) + 6, y, val); y -= 11; };
    filtro('Operação', 'FERTIRRIGAÇAO');
    filtro('Propriedade', 'FAZENDA VEREDA ROMARIA');
    filtro('Atividade', 'CAFE');
    filtro('Empreendimento', 'CAFE - 26 X 27 - FAZ. ROMARIA');
    filtro('Período', '15/09/2026 a 15/09/2026');
    filtro('Safra', 'SAFRA 2026/2027');
    y -= 8;
  }
  Object.keys(TIT).forEach(k => T(COL[k], y, TIT[k], { bold: true }));
  y -= 13;
}
/* rodapé de página e quebra quando não cabe mais */
const rodape = () => { const n = paginas.length; T(40, 20, 'Emitido em 15/09/2026 16:39:47'); T(700, 20, 'Página ' + n + ' de 2'); };
const cabe = alt => { if (y - alt < 40) { rodape(); paginas.push([]); cabecalho(false); } };
cabecalho(true);

/* quebra do nome do insumo em pedaços de até 15 caracteres, como o ERP faz na coluna estreita */
const quebra = s => { const out = []; let r = s; while (r.length > 15) { out.push(r.slice(0, 15)); r = r.slice(15); } out.push(r); return out; };

const totais = [0, 0, 0]; let areaTotal = 0;
GLEBAS.forEach(g => {
  const [nome, area, hora, ...v] = g;
  areaTotal += area;
  cabe(12 + 3 * 11 + 2 * 9 + 4);
  T(40, y, nome + ' (' + br4(area).replace(/,(\d{2})\d+$/, ',$1') + 'ha)', { bold: true }); y -= 12;
  INSUMOS.forEach((ins, i) => {
    const qt = v[i * 2], dose = v[i * 2 + 1];
    totais[i] += qt;
    const partes = quebra(ins);
    T(COL.dataIni, y, '15/09/2026'); T(COL.horaIni, y, hora);
    /* linha inteira: data final e hora final na mesma linha; linha QUEBRADA: caem na segunda linha visual */
    if (partes.length === 1) { T(COL.dataFim, y, '15/09/2026'); T(COL.horaFim, y, '17:00:00'); }
    T(COL.operacao, y, 'FERTIRRIGAÇAO');
    T(COL.insumo, y, partes[0]);
    T(COL.un, y, 'KG');
    T(dir('area', br4(area), 7), y, br4(area));
    T(dir('doseHa', br4(dose), 7), y, br4(dose));
    T(dir('doseTrat', br4(0), 7), y, br4(0));
    T(dir('qtde', br4(qt), 7), y, br4(qt));
    if (partes.length > 1) { y -= 9; T(COL.dataFim, y, '15/09/2026'); T(COL.horaFim, y, '17:00:00'); T(COL.insumo, y, partes.slice(1).join('')); }
    y -= 11;
  });
  y -= 4;
});
/* totais, como o ERP fecha o relatório */
y -= 4;
cabe(11 * (INSUMOS.length + 2));
T(40, y, 'Totais por insumo', { bold: true }); y -= 11;
INSUMOS.forEach((ins, i) => { T(COL.insumo, y, 'Total ' + ins); T(dir('qtde', br4(totais[i]), 7), y, br4(totais[i])); y -= 11; });
T(40, y, 'Total geral', { bold: true }); T(dir('area', br4(areaTotal), 7), y, br4(areaTotal)); T(dir('qtde', br4(totais.reduce((a, b) => a + b, 0)), 7), y, br4(totais.reduce((a, b) => a + b, 0)));
rodape();

/* ---- escrita do PDF (N páginas, duas fontes, WinAnsi para os acentos) ---- */
const escPdf = s => s.replace(/\\/g, '\\\\').replace(/\(/g, '\\(').replace(/\)/g, '\\)');
const fluxos = paginas.map(itens => {
  let fluxo = 'BT\n';
  itens.forEach(it => { fluxo += `/${it.bold ? 'F2' : 'F1'} ${it.tam} Tf 1 0 0 1 ${it.x.toFixed(2)} ${it.y.toFixed(2)} Tm (${escPdf(it.txt)}) Tj\n`; });
  return Buffer.from(fluxo + 'ET\n', 'latin1');
});
/* objetos: 1 catálogo · 2 páginas · 3 F1 · 4 F2 · 5 info · depois, por página, [página, fluxo] */
const nPag = paginas.length;
const objs = [];
objs.push('<< /Type /Catalog /Pages 2 0 R >>');
objs.push(`<< /Type /Pages /Kids [${paginas.map((_, i) => (6 + i * 2) + ' 0 R').join(' ')}] /Count ${nPag} >>`);
objs.push('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>');
objs.push('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>');
objs.push('<< /Producer (AgroLavoura 5.26.11.0 - fixture sintetica v96) /Title (Aplicacoes de Insumos - Resumido) >>');
paginas.forEach((_, i) => {
  objs.push(`<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${PAG.w} ${PAG.h}] /Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents ${7 + i * 2} 0 R >>`);
  objs.push({ fluxo: fluxos[i] });
});

const partes = [Buffer.from('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n', 'latin1')];
const offsets = [];
let pos = partes[0].length;
objs.forEach((o, i) => {
  offsets.push(pos);
  let b;
  if (o && o.fluxo) b = Buffer.concat([Buffer.from(`${i + 1} 0 obj\n<< /Length ${o.fluxo.length} >>\nstream\n`, 'latin1'), o.fluxo, Buffer.from('\nendstream\nendobj\n', 'latin1')]);
  else b = Buffer.from(`${i + 1} 0 obj\n${o}\nendobj\n`, 'latin1');
  partes.push(b); pos += b.length;
});
const xref = pos;
let tabela = `xref\n0 ${objs.length + 1}\n0000000000 65535 f \n`;
offsets.forEach(o => { tabela += String(o).padStart(10, '0') + ' 00000 n \n'; });
tabela += `trailer\n<< /Size ${objs.length + 1} /Root 1 0 R /Info 5 0 R >>\nstartxref\n${xref}\n%%EOF\n`;
partes.push(Buffer.from(tabela, 'latin1'));

fs.mkdirSync(path.dirname(SAIDA), { recursive: true });
fs.writeFileSync(SAIDA, Buffer.concat(partes));
console.log('gravado ' + path.relative(process.cwd(), SAIDA) + ' · ' + nPag + ' páginas · ' + paginas.reduce((s, p) => s + p.length, 0) + ' pedaços de texto · ' + GLEBAS.length + ' glebas · ' + (GLEBAS.length * INSUMOS.length) + ' linhas · ' + areaTotal.toFixed(2) + ' ha · ' + totais.join(' / ') + ' kg');
