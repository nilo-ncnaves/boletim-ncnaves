#!/usr/bin/env node
/*
 teste_planejamento.cjs — prova do MÓDULO DE PLANEJAMENTO (v77) do Boletim NCNaves.

 É a validação escrita na tarefa da v77 (reunião mensal + planejamento semanal) e
 roda SEM REDE, como um celular offline, a 390 px de largura. Serve de trava: sai
 com código 1 quando qualquer prova falha.

 O que prova, na ordem da tarefa:
   1. Importa o texto REAL da ata (Vereda, Mata Preta e Lagamar (Grupo)) como a
      rodada "Reunião 10/09/26" e confere item a item: quantidade por fazenda,
      área de 96 ha, AGUARDANDO CLIMA, AGUARDANDO TERCEIRO (repasse e Cooxupé),
      responsável entre parênteses, tarefa sem prazo e status pela linguagem.
   2. Reimporta a MESMA ata e confere que nada duplica (idempotência).
   3. Cria a semana seguinte, compromete 3 tarefas, conclui 1, trava 1 por falta
      de insumo, deixa 1 sem ação e confere o fechamento semanal automático.
   4. Projeção de ritmo na tarefa de 96 ha (feito × área × dias úteis).
   5. Alerta de travada há mais de 7 dias (cobrança do escritório).
   6. Rascunho da próxima ata, cobrança por fornecedor e pauta da sexta — tudo
      dentro do app, sem ferramenta externa.
   7. De-para: Igrejinha e Lazaro como áreas de Monte Carmelo — Café; fazendas do
      Dr. Adilson ignoradas sem perguntar.
   8. Faixa do gerente: no máximo 3 linhas a 360 px, ordem 🔴 → 🟡 → ⏸️ → 🟢,
      nenhuma tarefa travada em vermelho, um toque muda o status.
   9. Gerente não enxerga tarefa de outra unidade.
  10. Sexta-feira abre sozinha a tela de fechamento da semana; dia 11 sem ata
      mostra a pastilha da rodada.
  11. Dois toques até qualquer função da área Planejamento.
  12. (v90) O QUADRO "Planejamento cafeicultura" do escritório (matriz fazenda ×
      insumo, 14/09/2026) colado por cima da ata de 10/09: detecção nos três
      separadores, data, 62 + 18 = 80 células, coluna inteira vazia, 2 linhas fora
      do escopo, de-para por id (Café 5º e 6º, Vereda 365, Ernane/Caxico como
      áreas), as três traduções de status, o bloco ❓ que não grava nada antes da
      resposta, os quatro grupos com contagem (A = 1 · B = 1 · C = 60 · 9 só na
      ata), tarefa nova sem prazo e ⏸️, produto pelo de-para, Pulverização sem
      produto, histórico com a origem, reimportação sem duplicar, status voltando,
      célula vazia que não altera, exceção do "aguardando", nome desconhecido e
      produto desconhecido parando na pré-visualização, rodada criada quando não
      existe, e a porta única classificando o quadro como ata.

 Uso (na raiz do repositório):
   node scripts/teste_planejamento.cjs
   node scripts/teste_planejamento.cjs --json    # imprime o resultado em JSON

 Precisa do pacote playwright (global) e do Chromium dele — mesma exigência de
 scripts/checar-poluicao.cjs. Não é parte do app.
*/
const fs = require('fs');
const path = require('path');
const http = require('http');
let pw;
try { pw = require('playwright'); } catch (e) { pw = require('/opt/node22/lib/node_modules/playwright'); }

const RAIZ = path.resolve(__dirname, '..');
const VP = { width: 390, height: 844 };
const LARGURA_FAIXA = 360;              /* medida da faixa do gerente exigida na tarefa */
const CODIGOS = { ADMIN: 'ADMIN-9561', f22c: 'VC-5883' };

/* texto REAL da ata usado na validação da tarefa */
const ATA = [
  '2.1 – Vereda',
  '- Colheita varrição falta setor 4,5,8 e 9 + - 96 há, tem 12 miac 3 dias de sol voltamos a levantar e 4 dias de serviço acabamos – PRAZO: 20/09/26',
  '- Fazer KCL e ferti PRAZO: 25/09/26',
  '- Instalar caixa dágua no setor 8 e quadra da represa (Tirar 2 caixas do Laboratório Biológico –(Renatinho/ Renato) PRAZO: 30/09/26',
  '- Calcario (aguardando repasse) - PRAZO: 10/10/26',
  '- Acompanhar as Irrigações.',
  '2.11 – Mata Preta',
  '- Kcl em andamento - PRAZO: 15/09/26',
  '- Montagem da irrigação Finalizado. - PRAZO: 30/09/26',
  '- Conserto Talude Piscinão quando parar chuvas - PRAZO: 30/09/26',
  '2.12 – Lagamar (Grupo)',
  '- Pós colheita Ok',
  '- Kcl falta chegar para aplicar (Cobrar Cooxupé entrega) - PRAZO: 30/09/26',
  '- Desbrota café novo iniciar na segunda. - PRAZO: 05/10/26',
  '2.20 – Marimbondo',
  '- Cercar o pasto novo - PRAZO: 30/09/26',
  '2.21 – Córrego Grande (Dr. Adilson)',
  '- Trocar bomba do poço - PRAZO: 30/09/26',
  'Assuntos gerais',
  '- Trânsito de caminhões na sede (Definido com Cristian)',
  '- Contratar motorista',
  'Necessidades de investimento',
  '- MIAC novo para a Vereda',
  '- Trator para a Mata Preta'
].join('\n');

/* v90: o QUADRO "Planejamento cafeicultura" de 14/09/2026 — transcrição conferida célula a célula
   (10 linhas × 8 colunas; "—" = célula vazia; Marimbondo e Cristo Redentor são fora do escopo) */
const QUADRO = [
  'PLANEJAMENTO CAFEICULTURA',
  'Mês: 09/2026 · 14/09/2026',
  'Fazenda | Uréia | Nitrato | KCl | Phusion | Sulf. Manganês | Ácido Bórico | Sulf. Zinco | Pulverização',
  'RIO PRETO CAFÉ RODRIGO | REALIZAR | — | REALIZAR | — | REALIZAR | REALIZAR | REALIZAR | REALIZAR',
  'MATA PRETA | OK | — | OK | — | OK | OK | OK | REALIZAR',
  'ÁGUA LIMPA | REALIZANDO | — | REALIZANDO | REALIZAR | REALIZANDO | REALIZANDO | REALIZANDO | REALIZAR',
  'CAXICO | OK | — | OK | REALIZAR | OK | OK | OK | REALIZAR',
  'MONTE CARMELO | REALIZANDO | — | OK | — | REALIZANDO | REALIZANDO | REALIZANDO | REALIZAR',
  'MONTE CARMELO - ERNANE | REALIZAR | — | OK | — | REALIZAR | REALIZAR | REALIZAR | REALIZAR',
  'RIO PRETO CAFÉ GRUPO | REALIZANDO | — | REALIZANDO | — | REALIZANDO | REALIZANDO | REALIZANDO | REALIZAR',
  'VEREDA 365 | REALIZAR | — | REALIZAR | — | REALIZAR | REALIZAR | REALIZAR | REALIZAR',
  'ROMARIA | REALIZANDO | — | REALIZANDO | — | REALIZANDO | REALIZANDO | REALIZANDO | REALIZAR',
  'CAFÉ 5º e 6º | REALIZAR | — | REALIZAR | — | REALIZAR | REALIZAR | REALIZAR | REALIZAR',
  'MARIMBONDO | OK | — | REALIZANDO | — | OK | OK | OK | REALIZAR',
  'CRISTO REDENTOR | OK | — | OK | — | OK | OK | OK | REALIZAR'
].join('\n');
/* quadro reemitido em 20/09: Mata Preta KCl VOLTA para REALIZANDO, Vereda 365 perde a célula Uréia
   (vazia não altera) e Rio Preto Café Grupo KCl continua REALIZAR (exceção do "aguardando") */
const QUADRO_2 = QUADRO.replace('14/09/2026', '20/09/2026')
  .replace('MATA PRETA | OK | — | OK |', 'MATA PRETA | OK | — | REALIZANDO |')
  .replace('VEREDA 365 | REALIZAR | —', 'VEREDA 365 | — | —')
  .replace('RIO PRETO CAFÉ GRUPO | REALIZANDO | — | REALIZANDO |', 'RIO PRETO CAFÉ GRUPO | REALIZANDO | — | REALIZAR |');

const provas = [];
const ok = (nome, passou, detalhe) => provas.push({ nome, ok: !!passou, detalhe: detalhe == null ? '' : String(detalhe) });

function servir(dir) {
  return new Promise(res => {
    const tipos = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.webmanifest': 'application/manifest+json', '.png': 'image/png' };
    const srv = http.createServer((req, r) => {
      let p = decodeURIComponent(req.url.split('?')[0]); if (p === '/') p = '/index.html';
      const f = path.join(dir, p);
      if (!f.startsWith(dir) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) { r.writeHead(404); return r.end(); }
      r.writeHead(200, { 'content-type': tipos[path.extname(f)] || 'application/octet-stream' });
      fs.createReadStream(f).pipe(r);
    });
    srv.listen(0, '127.0.0.1', () => res({ srv, base: 'http://127.0.0.1:' + srv.address().port }));
  });
}
/* relógio fixo: a data manda no farol, na sexta e na pastilha do dia 10 */
async function novaPagina(browser, base, acesso, quando, sessao) {
  const ctx = await browser.newContext({ viewport: VP, locale: 'pt-BR', timezoneId: 'America/Sao_Paulo' });
  await ctx.route('**/*', r => r.request().url().startsWith(base) ? r.continue() : r.abort());
  if (quando) { await ctx.clock.install({ time: new Date(quando) }); }
  const page = await ctx.newPage();
  const erros = [];
  page.on('pageerror', e => erros.push(String(e).split('\n')[0]));
  page.on('console', m => { if (m.type() === 'error' && !/Failed to load resource|ERR_FAILED|net::/.test(m.text())) erros.push('console: ' + m.text().slice(0, 160)); });
  await page.goto(base + '/index.html');
  await page.evaluate(([a, s]) => { localStorage.clear(); localStorage.setItem('bdf:acesso', JSON.stringify(a)); if (s) localStorage.setItem('bdf:sessao', JSON.stringify(s)); }, [acesso, sessao || null]);
  await page.reload(); await page.waitForTimeout(900);
  return { page, ctx, erros };
}
/* grava o estado do app (D) e devolve para outra página reaproveitar */
const lerD = page => page.evaluate(() => JSON.stringify(D));
const porD = (page, d) => page.evaluate(x => { D = JSON.parse(x); salvarDados(); }, d);

async function importarAta(page) {
  return page.evaluate(txt => {
    planNav = [{ v: 'menu' }, { v: 'importar' }];
    planUI.rodadaNome = 'Reunião 10/09/26';
    planUI.ata = ataParsear(txt);
    const a = planUI.ata;
    planAtaGravar();
    return { fora: a.fora, blocos: a.blocos.map(b => ({ nome: b.nome, unidade: b.unidade })) };
  }, ATA);
}
const tarefasDe = (page, fz) => page.evaluate(f => planTarefas().filter(t => t.unidade === f)
  .map(t => ({ id: t.id, desc: t.desc, prazo: t.prazo, area: t.area, status: t.status, resp: t.responsavel,
    quem: (t.bloqueio || {}).quem || '', farol: planFarol(t), origem: t.origemRot })), fz);

(async () => {
  const { srv, base } = await servir(RAIZ);
  const browser = await pw.chromium.launch();
  let estado = null;

  /* ---------- 1. importação da ata real (quinta, 10/09/2026) ---------- */
  {
    const { page, ctx, erros } = await novaPagina(browser, base, { codigo: CODIGOS.ADMIN, chave: 'ADMIN' }, '2026-09-10T09:00:00-03:00');
    const imp = await importarAta(page); await page.waitForTimeout(300);

    const ver = await tarefasDe(page, 'f22c');
    ok('Vereda — 5 tarefas importadas', ver.length === 5, ver.length + ' tarefa(s)');
    const t96 = ver.find(t => Number(t.area) === 96);
    ok('Vereda — tarefa de 96 ha reconhecida', !!t96, t96 ? t96.desc.slice(0, 46) + '… · ' + t96.area + ' ha' : '');
    ok('Vereda — a de 96 ha fica AGUARDANDO CLIMA ("3 dias de sol")', t96 && t96.status === 'aguardando_clima', t96 && t96.status);
    ok('Vereda — travada por clima NUNCA fica vermelha', t96 && t96.farol === 'cinza', t96 && t96.farol);
    const tResp = ver.find(t => /Renatinho/.test(t.resp || ''));
    ok('Vereda — responsável "(Renatinho/ Renato)" capturado', !!tResp, tResp ? tResp.resp : '');
    const tCal = ver.find(t => /Calcario/i.test(t.desc));
    ok('Vereda — "Calcario (aguardando repasse)" fica AGUARDANDO TERCEIRO', tCal && tCal.status === 'aguardando_terceiro', tCal && tCal.status);
    const tSem = ver.filter(t => !t.prazo);
    ok('Vereda — 1 tarefa sem prazo (farol cinza)', tSem.length === 1 && tSem[0].farol === 'cinza', tSem.map(t => t.desc).join(' · '));
    const tKcl = ver.find(t => /KCL/i.test(t.desc));
    ok('Vereda — "Fazer KCL e ferti" fica A INICIAR com prazo 25/09/26', tKcl && tKcl.status === 'a_iniciar' && tKcl.prazo === '2026-09-25', tKcl && (tKcl.status + ' · ' + tKcl.prazo));

    const mp = await tarefasDe(page, 'f13c');
    ok('Mata Preta — 3 tarefas', mp.length === 3, mp.length + '');
    ok('Mata Preta — 1 em execução, 1 finalizada, 1 aguardando clima',
      mp.filter(t => t.status === 'em_execucao').length === 1 && mp.filter(t => t.status === 'finalizado').length === 1 && mp.filter(t => t.status === 'aguardando_clima').length === 1,
      mp.map(t => t.status).join(' · '));

    const lg = await tarefasDe(page, 'f03c');
    ok('Lagamar (Grupo) — 3 tarefas', lg.length === 3, lg.length + '');
    ok('Lagamar (Grupo) — 1 finalizada, 1 aguardando Cooxupé, 1 a iniciar',
      lg.filter(t => t.status === 'finalizado').length === 1
      && lg.filter(t => t.status === 'aguardando_terceiro' && t.quem === 'Cooxupé').length === 1
      && lg.filter(t => t.status === 'a_iniciar').length === 1,
      lg.map(t => t.status + (t.quem ? '(' + t.quem + ')' : '')).join(' · '));

    /* de-para e fora do escopo */
    ok('De-para — "Vereda" → Vereda — Café; "Lagamar (Grupo)" → Rio Preto-Lagamar — Café',
      imp.blocos.some(b => b.nome === 'Vereda' && b.unidade === 'f22c') && imp.blocos.some(b => /Lagamar \(Grupo\)/.test(b.nome) && b.unidade === 'f03c'),
      imp.blocos.map(b => b.nome + '→' + (b.unidade || '—')).join(' · '));
    ok('Fora do escopo — Marimbondo e Dr. Adilson ignorados sem perguntar',
      imp.fora.length === 2 && imp.fora.some(n => /Marimbondo/.test(n)) && imp.fora.some(n => /Adilson/.test(n)),
      imp.fora.join(' · '));
    const semDono = await page.evaluate(() => planTarefas().filter(t => /Marimbondo|Adilson|bomba do po/i.test(t.desc)).length);
    ok('Fora do escopo — nenhuma tarefa dessas fazendas foi gravada', semDono === 0, semDono + ' gravada(s)');

    const ger = await page.evaluate(() => planTarefas().filter(t => t.tipoItem !== 'tarefa').map(t => t.tipoItem + ': ' + t.desc));
    ok('Assuntos gerais e investimentos vão para lista separada, sem fazenda e sem prazo',
      ger.length === 4 && ger.filter(x => x.startsWith('assunto')).length === 2 && ger.filter(x => x.startsWith('investimento')).length === 2
      && (await page.evaluate(() => planTarefas().filter(t => t.tipoItem !== 'tarefa').every(t => !t.unidade && !t.prazo))),
      ger.join(' · '));
    const cristian = await page.evaluate(() => (planTarefas().find(t => /caminh/i.test(t.desc)) || {}).responsavel || '');
    ok('Assunto geral — "Definido com Cristian" vira responsável', /Cristian/.test(cristian), cristian);

    /* Igrejinha e Lazaro como áreas de Monte Carmelo — Café */
    const areas = await page.evaluate(() => D.talhoes.filter(t => t.fazendaId === 'f14c' && /Igrejinha|Lazaro/.test(t.nome)).map(t => t.nome));
    ok('Igrejinha e Lazaro criados como áreas de Monte Carmelo — Café', areas.length === 2, areas.join(' · '));
    const dp = await page.evaluate(() => deparaAta().filter(x => /Igrejinha|Lazaro/.test(x.ata)).map(x => x.ata + '→' + x.unidade + '/' + x.area));
    ok('De-para de "FMC Igrejinha" e "FMC Lazaro" aponta para f14c', dp.length === 2 && dp.every(x => /f14c/.test(x)), dp.join(' · '));

    /* 2. idempotência */
    const antes = await page.evaluate(() => planTarefas().length);
    await importarAta(page); await page.waitForTimeout(200);
    const depois = await page.evaluate(() => planTarefas().length);
    ok('Reimportar a mesma ata não duplica', antes === depois, antes + ' → ' + depois);

    /* 11. dois toques até qualquer função */
    const toques = await page.evaluate(() => {
      planNav = [{ v: 'menu' }]; ir('planejamento');
      const alvos = [...document.querySelectorAll('#app [data-planv]')].map(b => b.dataset.planv);
      return { alvos, niveis: 1 };
    });
    ok('Dois toques até qualquer função (menu → item, tudo no primeiro nível)',
      ['semana', 'mes', 'rodadas', 'terceiros', 'arrastadas', 'assuntos', 'lista', 'saidas', 'nova'].every(v => toques.alvos.includes(v)),
      toques.alvos.join(' · '));

    ok('Nenhum erro de JavaScript na importação e na navegação', erros.length === 0, erros.join(' | '));
    estado = await lerD(page);
    await ctx.close();
  }

  /* ---------- 12. (v90) o quadro do escritório por cima da ata (segunda, 14/09/2026) ---------- */
  {
    const { page, ctx, erros } = await novaPagina(browser, base, { codigo: CODIGOS.ADMIN, chave: 'ADMIN' }, '2026-09-14T09:00:00-03:00');
    await porD(page, estado);
    const lerQuadro = (txt) => page.evaluate(q => {
      const d = quadroDetectar(q); const p = d ? quadroParsear(q) : null; if (!p) return { detecta: d };
      const c = quadroConciliar(p);
      return { detecta: d, data: p.data, ref: p.ref, semData: p.semData, fora: p.fora, colunas: p.colunas.map(x => x.rot + (x.conhecida ? '' : '?')),
        linhas: p.linhas.map(l => l.nome + '→' + (l.unidade || '?') + (l.area ? '/' + l.area : '')),
        preenchidas: c.preenchidas, vazias: c.vazias, total: c.total, perguntas: c.perguntas.map(x => x.cel.desc + ' × ' + x.t.desc),
        A: c.atualiza.length, B: c.sem.length, C: c.criar.length, D: c.soAta.length, falta: quadroFalta(p, c),
        semUnidade: c.semUnidade.length, semProduto: c.semProduto.length,
        nitrato: p.linhas.filter(l => l.valores[p.colunas.findIndex(x => x.chave === 'nitrato')]).length,
        phusion: p.linhas.filter(l => l.valores[p.colunas.findIndex(x => x.chave === 'phusion')]).map(l => l.nome) };
    }, txt);
    const detAta = await page.evaluate(a => quadroDetectar(a), ATA);
    ok('Quadro — a ata em blocos NÃO é reconhecida como quadro (o parser da ata continua sendo o dela)', detAta === false, String(detAta));
    const q1 = await lerQuadro(QUADRO);
    ok('Quadro — texto com "|" é reconhecido como quadro (3+ colunas conhecidas, linha com 2+ status)', q1.detecta === true, '');
    ok('Quadro — data 14/09/2026 lida do cabeçalho; rodada do mês = setembro/2026', q1.data === '2026-09-14' && q1.ref === '2026-09', q1.data + ' · ' + q1.ref);
    ok('Quadro — conferência: 10 linhas × 8 colunas = 80 células, 62 preenchidas e 18 vazias', q1.preenchidas === 62 && q1.vazias === 18 && q1.total === 80, `${q1.preenchidas} + ${q1.vazias} = ${q1.total}`);
    ok('Quadro — as 8 colunas reconhecidas na ordem do escritório', q1.colunas.join('|') === 'Uréia|Nitrato|KCl|Phusion|Sulf. Manganês|Ácido Bórico|Sulf. Zinco|Pulverização', q1.colunas.join(' | '));
    ok('Quadro — coluna Nitrato inteira vazia: coluna existe, zero célula (coluna vazia não é coluna ausente)', q1.colunas.includes('Nitrato') && q1.nitrato === 0, q1.nitrato + ' célula(s)');
    ok('Quadro — Phusion só em Água Limpa e Caxico', q1.phusion.length === 2 && /GUA LIMPA/.test(q1.phusion[0]) && /CAXICO/.test(q1.phusion[1]), q1.phusion.join(' · '));
    ok('Quadro — Marimbondo e Cristo Redentor descartados como "fora do escopo" (nunca "unidade não reconhecida")',
      q1.fora.length === 2 && q1.linhas.length === 10 && q1.semUnidade === 0, q1.fora.join(' · ') + ' · ' + q1.linhas.length + ' linha(s)');
    ok('Quadro — de-para por id: Café 5º e 6º → f24, Vereda 365 → f22c, Rio Preto Café Grupo → f03c, Rio Preto Café Rodrigo → f20, Romaria → f23',
      ['CAFÉ 5º e 6º→f24', 'VEREDA 365→f22c', 'RIO PRETO CAFÉ GRUPO→f03c', 'RIO PRETO CAFÉ RODRIGO→f20', 'ROMARIA→f23'].every(x => q1.linhas.includes(x)), q1.linhas.join(' · '));
    ok('Quadro — Monte Carmelo, Ernane e Caxico são a MESMA unidade (f14c) com área diferente',
      q1.linhas.includes('MONTE CARMELO→f14c') && q1.linhas.includes('MONTE CARMELO - ERNANE→f14c/Ernane') && q1.linhas.includes('CAXICO→f14c/Caxico'), '');
    ok('Quadro — três células em ❓ (as três de KCl), por semelhança forte com a ata', q1.perguntas.length === 3 && q1.perguntas.every(x => /^KCl × /.test(x)) && q1.perguntas.some(x => /Fazer KCL e ferti/.test(x)) && q1.perguntas.some(x => /Kcl em andamento/.test(x)) && q1.perguntas.some(x => /Kcl falta chegar/.test(x)), q1.perguntas.join(' · '));
    ok('Quadro — Gravar inativo enquanto há ❓ sem resposta, dizendo a próxima ação', q1.falta === "Responda as 3 pergunta(s) de 'é a mesma tarefa?'", q1.falta);

    /* a tela: pré-visualização, resposta num toque, nada gravado antes */
    const tela = await page.evaluate(async q => {
      planNav = [{ v: 'menu' }, { v: 'importar' }]; planUI.quadro = quadroParsear(q); planUI.ata = null; ir('planejamento');
      const tAntes = planTarefas().length, hAntes = planHist().length;
      const bt = document.getElementById('bt-plan-quadro-ok');
      const out = { titulo: (document.querySelector('#app .topo h1') || {}).textContent.replace(/\s+/g, ' ').trim(),
        grupos: [...document.querySelectorAll('#app .cad-grupo')].map(e => e.textContent.trim()),
        inativo: !!bt && bt.classList.contains('acao-off'),
        chips: [...document.querySelectorAll('#app .plan-perg')].map(p => [...p.querySelectorAll('.chip')].map(b => b.textContent.trim()).join('·')),
        campos: document.querySelectorAll('#app .plan-perg input, #app .plan-perg select, #app .plan-perg textarea').length,
        texto: document.querySelector('#app').textContent.replace(/\s+/g, ' ') };
      const c = quadroConciliar(planUI.quadro);
      c.perguntas.forEach(p => { const r = p.cel.linha.unidade === 'f03c' ? 'dif' : 'mesma'; document.querySelector('[data-plan-qresp="' + p.cel.k + ':' + r + ':' + p.t.id + '"]').click(); });
      await new Promise(r => setTimeout(r, 200));
      const c2 = quadroConciliar(planUI.quadro);
      out.depois = { A: c2.atualiza.length, B: c2.sem.length, C: c2.criar.length, D: c2.soAta.length, perg: c2.perguntas.length,
        grupos: [...document.querySelectorAll('#app .cad-grupo')].map(e => e.textContent.trim()),
        ativo: !document.getElementById('bt-plan-quadro-ok').classList.contains('acao-off'),
        A_txt: c2.atualiza.map(x => x.desc + ' · ' + planStatusRot(x.tarefa.status) + ' → ' + planStatusRot(x.status)),
        B_txt: c2.sem.map(x => x.desc + ' · ' + planStatusRot(x.status)),
        gravouAntes: planTarefas().length !== tAntes || planHist().length !== hAntes, tela: telaAtual };
      return out;
    }, QUADRO);
    ok('Tela "Conferir o quadro" — bloco ❓ com três chips por pergunta (É a mesma · São diferentes · Decidir depois), nenhum campo',
      tela.chips.length === 3 && tela.chips.every(c => c === 'É a mesma·São diferentes·Decidir depois') && tela.campos === 0, tela.chips.join(' | '));
    ok('Tela — ordem: o que pede resposta primeiro, depois os grupos contáveis', /^❓ Confirmar se é a mesma tarefa · 3$/.test(tela.grupos[0] || '') && tela.inativo, tela.grupos.join(' · '));
    ok('Tela — sem termo de cobrança nem exclamação', !/(não fez|não realizou|pendente|faltou|esqueceu|campo obrigatório)/i.test(tela.texto) && !/!/.test(tela.texto), '');
    ok('Respostas num toque (mesma, mesma, diferentes): A = 1 · B = 1 · C = 60 (soma 62) · 9 só na ata, e nada foi gravado ainda',
      tela.depois.A === 1 && tela.depois.B === 1 && tela.depois.C === 60 && tela.depois.D === 9 && tela.depois.perg === 0 && tela.depois.gravouAntes === false && tela.depois.tela === 'planejamento',
      `A ${tela.depois.A} · B ${tela.depois.B} · C ${tela.depois.C} · D ${tela.depois.D} · ❓ ${tela.depois.perg}`);
    ok('Grupos na tela: "Atualiza · 1", "Sem mudança · 1", "Criar · 60", "Só na ata · 9"; Gravar ativa no lugar',
      ['Atualiza · 1', 'Sem mudança · 1', 'Criar · 60', 'Só na ata · 9'].every(g => tela.depois.grupos.includes(g)) && tela.depois.ativo, tela.depois.grupos.join(' · '));
    ok('Atualiza — "KCl · Em execução → Finalizado" (Mata Preta: o status do quadro vence)', tela.depois.A_txt[0] === 'KCl · Em execução → Finalizado', tela.depois.A_txt.join(' · '));
    ok('Sem mudança — "KCl · A iniciar" (Vereda: a ata já dizia a iniciar)', tela.depois.B_txt[0] === 'KCl · A iniciar', tela.depois.B_txt.join(' · '));

    /* gravar */
    const grav = await page.evaluate(async () => {
      const tAntes = planTarefas().length, hAntes = planHist().length;
      document.getElementById('bt-plan-quadro-ok').click();
      await new Promise(r => setTimeout(r, 200));
      const mp = planTarefas().find(t => t.unidade === 'f13c' && /kcl em andamento/i.test(t.desc));
      const lg = planTarefas().find(t => t.unidade === 'f03c' && /kcl falta chegar/i.test(t.desc));
      const ver = planTarefas().find(t => t.unidade === 'f22c' && /fazer kcl/i.test(t.desc));
      const novas = planTarefas().filter(t => /quadro do escritório/.test(t.origemRot || ''));
      const ern = novas.find(t => t.unidade === 'f14c' && t.desc === 'Ernane — Uréia');
      const cax = novas.find(t => t.unidade === 'f14c' && t.desc === 'Caxico — Uréia');
      const mc = novas.find(t => t.unidade === 'f14c' && t.desc === 'Uréia');
      const pulv = novas.find(t => t.unidade === 'f22c' && t.desc === 'Pulverização');
      const mn = novas.find(t => t.desc === 'Sulf. Manganês');
      return { flash: (document.getElementById('plan-flash') || {}).textContent || '', tela: telaAtual, nav: planNav.map(n => n.v).join('>'),
        criadas: planTarefas().length - tAntes, hist: planHist().length - hAntes,
        mp: mp && { status: mp.status, rot: mp.quadroRotulo, hist: planHistDe(mp.id).map(planHistTexto) },
        lg: lg && { status: lg.status, nao: lg.quadroNao }, ver: ver && { status: ver.status, rot: ver.quadroRotulo, prazo: ver.prazo },
        novas: novas.length, semPrazo: novas.every(t => !t.prazo), cinza: novas.every(t => planFarol(t) === 'cinza' || t.status === 'finalizado'),
        statusNovas: { a: novas.filter(t => t.status === 'a_iniciar').length, e: novas.filter(t => t.status === 'em_execucao').length, f: novas.filter(t => t.status === 'finalizado').length },
        tres: !!(ern && cax && mc), ernProd: ern && ern.produto, pulv: pulv && { produto: pulv.produto || '', ops: planOperacoesDe(pulv) },
        mn: mn && { produto: mn.produto, cadastro: !!insProduto('Sulf. Manganês'), cat: (insProduto('Sulf. Manganês') || {}).categoria },
        nitrato: planTarefas().filter(t => /nitrato/i.test(t.desc)).length, depara: deparaAta().filter(x => !x.fora).length };
    });
    ok('Gravar — resumo de uma linha no flash: "Quadro de 14/09 importado · 1 tarefa atualizada · 60 criadas · 1 sem mudança · 9 só na ata · 2 linhas fora do escopo"',
      grav.flash.includes('Quadro de 14/09 importado · 1 tarefa atualizada · 60 criadas · 1 sem mudança · 9 só na ata · 2 linhas fora do escopo'), grav.flash);
    ok('Gravar — o app volta para a rodada (Reunião 10/09/26), sem rodada paralela', grav.tela === 'planejamento' && grav.nav === 'menu>rodadas>rodada' && (await page.evaluate(() => planRodadas().length)) === 1, grav.nav);
    ok('Criar — 60 tarefas novas, todas sem prazo (⏸️ cinza, nunca vermelho), com origem "quadro do escritório de 14/09"',
      grav.criadas === 60 && grav.novas === 60 && grav.semPrazo && grav.cinza, `${grav.criadas} criada(s)`);
    ok('Status — as três traduções: REALIZAR → a iniciar, REALIZANDO → em execução, OK → finalizado (nas 60 novas: 30 · 19 · 11)',
      grav.statusNovas.a === 30 && grav.statusNovas.e === 19 && grav.statusNovas.f === 11, JSON.stringify(grav.statusNovas));
    ok('Atualiza — Mata Preta "Kcl em andamento" ficou finalizado, com histórico "em execução → finalizado (quadro do escritório de 14/09)"',
      grav.mp && grav.mp.status === 'finalizado' && grav.mp.hist.some(h => /em execução → finalizado \(quadro do escritório de 14\/09\)/.test(h)), grav.mp && grav.mp.hist.join(' | '));
    ok('❓ "É a mesma" fica NA TAREFA (t.quadroRotulo = "KCl"), sem coleção nova', grav.mp && grav.mp.rot === 'KCl' && grav.ver && grav.ver.rot === 'KCl', '');
    ok('❓ "São diferentes" fica NA TAREFA (t.quadroNao = ["kcl"]) e a tarefa da ata não muda', grav.lg && grav.lg.status === 'aguardando_terceiro' && (grav.lg.nao || []).join() === 'kcl', JSON.stringify(grav.lg));
    ok('Sem mudança — Vereda "Fazer KCL e ferti" continua a iniciar e mantém o prazo da ata (25/09)', grav.ver && grav.ver.status === 'a_iniciar' && grav.ver.prazo === '2026-09-25', JSON.stringify(grav.ver));
    ok('Área na chave: "Ernane — Uréia", "Caxico — Uréia" e "Uréia" são três tarefas distintas de Monte Carmelo — Café', grav.tres, '');
    ok('Nutrição — a tarefa leva o produto pelo de-para ("Uréia" → Ureia) e "Sulf. Manganês" passa a existir em D.insumos como fertilizante',
      grav.ernProd === 'Ureia' && grav.mn && grav.mn.produto === 'Sulf. Manganês' && grav.mn.cadastro && grav.mn.cat === 'fertilizante', JSON.stringify(grav.mn));
    ok('Fitossanitário — "Pulverização" nasce SEM produto e casa com "Pulverização manual" pelo PLAN_SINONIMOS',
      grav.pulv && grav.pulv.produto === '' && grav.pulv.ops.includes('Pulverização manual'), JSON.stringify(grav.pulv));
    ok('Coluna vazia — zero tarefa de nitrato', grav.nitrato === 0, grav.nitrato + '');
    ok('De-para da ata — 22 nomes ligados (16 + 6 do quadro)', grav.depara === 22, grav.depara + '');

    /* reimportação: nada cria, nada altera */
    const re = await page.evaluate(async q => {
      const tAntes = planTarefas().length, hAntes = planHist().length;
      planNav = [{ v: 'menu' }, { v: 'importar' }]; planUI.quadro = quadroParsear(q); ir('planejamento');
      const c = quadroConciliar(planUI.quadro);
      document.getElementById('bt-plan-quadro-ok').click(); await new Promise(r => setTimeout(r, 200));
      return { A: c.atualiza.length, B: c.sem.length, C: c.criar.length, D: c.soAta.length, perg: c.perguntas.length,
        tarefas: planTarefas().length - tAntes, hist: planHist().length - hAntes, flash: (document.getElementById('plan-flash') || {}).textContent || '' };
    }, QUADRO);
    ok('Reimportar o MESMO quadro: 0 ❓, 62 sem mudança, nada criado, nada no histórico', re.perg === 0 && re.A === 0 && re.C === 0 && re.B === 62 && re.tarefas === 0 && re.hist === 0, `A ${re.A} · B ${re.B} · C ${re.C} · +${re.tarefas} tarefa(s) · +${re.hist} no histórico`);

    /* quadro mais novo: status volta (finalizado → em execução), célula vazia não altera, exceção do "aguardando" */
    const novo = await page.evaluate(async q2 => {
      const kclGrupo = planTarefas().find(t => t.unidade === 'f03c' && t.desc === 'KCl');
      planMudarStatus(kclGrupo.id, 'aguardando_terceiro', { motivo: 'falta insumo', texto: 'aguardando insumo', quem: 'Cooxupé' });
      const ureiaVer = planTarefas().find(t => t.unidade === 'f22c' && t.desc === 'Uréia');
      const stAntes = ureiaVer.status;
      planNav = [{ v: 'menu' }, { v: 'importar' }]; planUI.quadro = quadroParsear(q2); ir('planejamento');
      const c = quadroConciliar(planUI.quadro);
      const mp = c.atualiza.find(x => x.linha.unidade === 'f13c' && x.coluna.chave === 'kcl');
      const exc = c.sem.find(x => x.linha.unidade === 'f03c' && x.coluna.chave === 'kcl');
      const tAntes = planTarefas().length, mpTxt = mp && (mp.tarefa.status + '→' + mp.status);
      document.getElementById('bt-plan-quadro-ok').click(); await new Promise(r => setTimeout(r, 200));
      const mpT = planTarefas().find(t => t.unidade === 'f13c' && /kcl em andamento/i.test(t.desc));
      return { A: c.atualiza.length, C: c.criar.length, mp: mpTxt, exc: exc && exc.nota,
        mpDepois: mpT.status, hist: planHistDe(mpT.id).map(planHistTexto)[0], ureia: stAntes + '→' + planTarefas().find(t => t.id === ureiaVer.id).status,
        ureiaN: planTarefas().filter(t => t.unidade === 'f22c' && t.desc === 'Uréia').length, criadas: planTarefas().length - tAntes,
        kclGrupo: planTarefas().find(t => t.id === kclGrupo.id).status, flash: (document.getElementById('plan-flash') || {}).textContent || '' };
    }, QUADRO_2);
    ok('Quadro mais novo — status VOLTA (finalizado → em execução) no grupo Atualiza, e o histórico registra a origem',
      novo.mp === 'finalizado→em_execucao' && novo.mpDepois === 'em_execucao' && /finalizado .* em execu.*quadro do escritório de 20\/09/.test(novo.hist || ''),
      novo.mp + ' · depois ' + novo.mpDepois + ' · ' + novo.hist);
    ok('Célula vazia — Uréia da Vereda 365 apagada no quadro novo: a tarefa não muda de status e não duplica', novo.ureia === 'a_iniciar→a_iniciar' && novo.ureiaN === 1, novo.ureia + ' · ' + novo.ureiaN + ' tarefa(s)');
    ok('Exceção declarada — REALIZAR sobre AGUARDANDO TERCEIRO fica em "Sem mudança" com a nota, e a espera não é encerrada',
      /aguardando terceiro mantido — o quadro não diz que a espera acabou/.test(novo.exc || '') && novo.kclGrupo === 'aguardando_terceiro', novo.exc || '');
    ok('Quadro mais novo — só a mudança entra: 1 atualizada, 0 criadas', novo.A === 1 && novo.C === 0 && novo.criadas === 0 && /1 tarefa atualizada · 0 criadas/.test(novo.flash), novo.flash);

    /* separadores e data */
    const qTab = await lerQuadro(QUADRO.split('\n').map(l => l.replace(/\s*\|\s*/g, '\t').replace(/—/g, '')).join('\n'));
    ok('Formato — células por TABULAÇÃO (colagem de planilha, célula vazia = vazia): as mesmas 62 células', qTab.detecta && qTab.preenchidas === 62 && qTab.vazias === 18, `${qTab.preenchidas} + ${qTab.vazias}`);
    const qEsp = await lerQuadro(QUADRO.split('\n').map(l => l.replace(/\s*\|\s*/g, ' ')).join('\n'));
    ok('Formato — células por ESPAÇO (vazia = "—"): as mesmas 62 células e as mesmas 10 unidades', qEsp.detecta && qEsp.preenchidas === 62 && qEsp.linhas.join() === q1.linhas.join(), `${qEsp.preenchidas} · ${qEsp.linhas.length} linha(s)`);
    const qSem = await lerQuadro(QUADRO.split('\n').filter(l => !/14\/09\/2026/.test(l)).join('\n'));
    ok('Sem data no texto: vale o dia da colagem (14/09/2026 no relógio do teste)', qSem.semData === true && qSem.data === '2026-09-14', qSem.data);

    /* nome desconhecido e produto desconhecido param na pré-visualização */
    const desc = await lerQuadro(QUADRO.replace('ROMARIA', 'FAZENDA NOVA').replace('Sulf. Zinco', 'Boro'));
    ok('Nome desconhecido ("FAZENDA NOVA") para na pré-visualização como unidade não reconhecida — nunca adivinhado', desc.linhas.includes('FAZENDA NOVA→?') && desc.falta === 'Escolha a unidade das 1 linha(s) em aberto', desc.falta);
    ok('Produto desconhecido (coluna "Boro") para na pré-visualização para ligar ou deixar de fora', desc.colunas.includes('Boro?') && desc.semProduto === 9, desc.colunas.join(' | ') + ' · ' + desc.semProduto + ' célula(s)');
    await ctx.close();
  }
  {
    /* aparelho sem a rodada do mês: a pré-visualização avisa e a gravação cria "Reunião 14/09/2026" */
    const semRod = JSON.stringify(Object.assign(JSON.parse(estado), { rodadas: [], tarefas: [], tarefaHistorico: [], semanas: [] }));
    const { page, ctx, erros } = await novaPagina(browser, base, { codigo: CODIGOS.ADMIN, chave: 'ADMIN' }, '2026-09-14T09:00:00-03:00');
    await porD(page, semRod);
    const r = await page.evaluate(async q => {
      planNav = [{ v: 'menu' }, { v: 'importar' }]; planUI.quadro = quadroParsear(q); ir('planejamento');
      const aviso = (document.querySelector('#app .aviso') || {}).textContent || '';
      const c = quadroConciliar(planUI.quadro);
      document.getElementById('bt-plan-quadro-ok').click(); await new Promise(r => setTimeout(r, 200));
      const rod = planRodadas()[0];
      return { aviso: aviso.replace(/\s+/g, ' '), perg: c.perguntas.length, C: c.criar.length, rod: rod && { nome: rod.nome, ref: rod.ref }, n: planRodadas().length, tarefas: planTarefas().length };
    }, QUADRO);
    ok('Sem rodada do mês no aparelho: a pré-visualização avisa que a gravação vai criá-la', /Não existe rodada de setembro/.test(r.aviso) && /Reunião 14\/09\/2026/.test(r.aviso), r.aviso.slice(0, 120));
    ok('Gravar cria a rodada "Reunião 14/09/2026" (ref 2026-09) — uma só — com as 62 tarefas', r.n === 1 && r.rod && r.rod.nome === 'Reunião 14/09/2026' && r.rod.ref === '2026-09' && r.C === 62 && r.perg === 0 && r.tarefas === 62, JSON.stringify(r.rod) + ' · ' + r.tarefas);
    /* porta única "Colar do WhatsApp": o quadro é classificado como ata e usa a mesma pré-visualização */
    const porta = await page.evaluate(async q => {
      insLimpar(); insNav = [{ v: 'colar' }]; telaDeOnde = telaDeOnde || {}; ir('colar');
      insUI.texto = q; insUI.auto = insClassificar(q); insUI.tipo = insUI.auto.tipo; insAbrirPrev(); insRender();
      const frase = (document.querySelector('#app .aviso') || {}).textContent || '';
      const bt = document.getElementById('bt-ins-ata'); const rot = bt ? bt.textContent.trim() : '';
      if (bt) bt.click(); await new Promise(r => setTimeout(r, 200));
      return { tipo: insUI.auto.tipo, frase: frase.replace(/\s+/g, ' '), rot, tela: telaAtual, quadro: !!planUI.quadro, titulo: (document.querySelector('#app .topo h1') || {}).textContent.replace(/\s+/g, ' ').trim() };
    }, QUADRO);
    ok('Porta única — o quadro é classificado como ATA ("parece o quadro de planejamento do escritório")', porta.tipo === 'ata' && /parece o quadro de planejamento do escritório/.test(porta.frase), porta.frase.slice(0, 100));
    ok('Porta única — "Conferir e importar o quadro ›" leva à MESMA pré-visualização do Planejamento', /importar o quadro/.test(porta.rot) && porta.tela === 'planejamento' && porta.quadro && /Conferir o quadro/.test(porta.titulo), porta.rot + ' → ' + porta.titulo.slice(0, 40));
    ok('Nenhum erro de JavaScript no quadro', erros.length === 0, erros.join(' | '));
    await ctx.close();
  }

  /* ---------- 3 a 6. semana, projeção, cobrança e textos (segunda, 14/09/2026) ---------- */
  {
    const { page, ctx, erros } = await novaPagina(browser, base, { codigo: CODIGOS.ADMIN, chave: 'ADMIN' }, '2026-09-14T09:00:00-03:00');
    await porD(page, estado); await page.waitForTimeout(200);

    const sem = await page.evaluate(() => {
      planMotor(true);
      const s = planSemanaAtual() || planSemanaCriar(planSegundaDe(hojeBRT()));
      const alvo = planTarefas().filter(t => t.unidade === 'f22c' && planAberta(t)).slice(0, 3);
      alvo.forEach(t => planComprometer(t.id, s.id));
      planMudarStatus(alvo[0].id, 'finalizado');
      planMudarStatus(alvo[1].id, 'aguardando_terceiro', { motivo: 'insumo', texto: 'aguardando insumo' });
      salvarDados();
      return { id: s.id, rot: planSemanaRot(s), comprometidas: planComprometidas(s.id).length,
        semAcao: alvo[2].desc };
    });
    ok('Semana criada e 3 tarefas comprometidas', sem.comprometidas === 3, sem.rot + ' · ' + sem.comprometidas);

    /* a sexta seguinte fecha a semana sozinha */
    await ctx.clock.setFixedTime(new Date('2026-09-21T08:00:00-03:00'));
    const est2 = await lerD(page);
    await ctx.close();

    const p2 = await novaPagina(browser, base, { codigo: CODIGOS.ADMIN, chave: 'ADMIN' }, '2026-09-21T08:00:00-03:00');
    await porD(p2.page, est2); await p2.page.waitForTimeout(200);
    const fech = await p2.page.evaluate(() => { planMotor(true);
      const ant = planSemanaAnterior(); const f = ant ? planFecharSemana(ant) : null;
      return f ? { n: f.n, conc: f.concluidas.length, trav: f.travadas.length, abertas: f.abertas.length, placar: f.placar } : null; });
    ok('Fechamento semanal automático: comprometido × concluído × travado',
      fech && fech.n === 3 && fech.conc === 1 && fech.trav === 1 && fech.abertas === 1, fech && JSON.stringify(fech));
    ok('Placar "cumprimos X de Y"', fech && fech.placar === 'cumprimos 1 de 3', fech && fech.placar);

    /* 5. alerta de travada há mais de 7 dias */
    const cobr = await p2.page.evaluate(() => planAlertas().filter(a => a.tipo === 'cobranca').map(a => a.t.desc + ' — ' + a.txt));
    ok('Alerta de travada há mais de 7 dias (cobrança do escritório)', cobr.length >= 1, cobr.join(' · '));

    /* 4. projeção de ritmo na tarefa de 96 ha — 3 talhões registrados no boletim */
    const proj = await p2.page.evaluate(() => {
      const t = planTarefas().find(x => Number(x.area) === 96);
      planMudarStatus(t.id, 'em_execucao');
      t.inicioReal = diaISO(hojeBRT(), -6);
      const tals = talhoesDa('f22c').filter(x => x.fazendaId === 'f22c' && x.tipo !== 'ESTRUTURA' && x.tipo !== 'ARRENDADO').slice(0, 3);
      tals.forEach((tal, i) => D.boletins.push({ id: 'projteste' + i, fazendaId: 'f22c', data: diaISO(hojeBRT(), -(5 - i)),
        responsavel: 'Gerente', clima: { cond: 'Ensolarado', chuvaMm: '' }, mo: { proprios: '8', diaristas: '', funcoes: [] },
        atividades: [{ id: 'a' + i, tipo: 'Levantar café', talhaoId: tal.id, status: 'concluida' }],
        colheita: [], fito: [], ocorrencias: [], secoes: {} }));
      salvarDados(); planMotor(true);
      const p = planProjecao(planTarefa(t.id));
      return p ? { feito: Math.round(p.feito), area: p.area, fim: p.fim, atraso: p.atraso, ha: tals.reduce((s, x) => s + n0(x.area), 0) } : null;
    });
    ok('Projeção de ritmo na tarefa de 96 ha (feito de N ha · conclui em …)',
      proj && proj.feito > 0 && proj.area === 96 && /^\d{4}-\d{2}-\d{2}$/.test(proj.fim),
      proj && ('feito ' + proj.feito + ' de ' + proj.area + ' ha · conclui em ' + proj.fim + ' (' + proj.atraso + ' dias do prazo)'));

    /* ---------- v78: planejado × executado × restante, rastreabilidade e fora do plano ---------- */
    const tri = await p2.page.evaluate(() => {
      const t = planTarefas().find(x => Number(x.area) === 96);
      const p = planProgresso(t), ex = planExecucao(t);
      return { meta: p.meta, feito: p.feito, resta: p.resta, pct: p.pct, temMeta: p.temMeta,
        n: ex.n, talhoes: ex.talhoes, soma: p.feito + p.resta,
        itens: ex.itens.map(l => ({ data: l.data, nome: l.nome, area: l.area, por: l.por })),
        snap: t.exec };
    });
    ok('Três números na tarefa: planejado + restante fecham com a meta',
      tri.temMeta && tri.meta === 96 && tri.feito > 0 && tri.soma === tri.meta,
      'planejado ' + tri.meta + ' · executado ' + tri.feito + ' · restante ' + tri.resta + ' (' + tri.pct + '%)');
    ok('Executado é a soma dos talhões DISTINTOS com lançamento casado',
      tri.talhoes === tri.itens.length && tri.feito === tri.itens.reduce((a, x) => a + x.area, 0),
      tri.talhoes + ' talhão(ões) · ' + tri.itens.map(x => x.area).join(' + '));
    ok('Rastreabilidade: cada lançamento traz data, talhão, área e quem lançou',
      tri.itens.length > 0 && tri.itens.every(x => /^\d{4}-\d{2}-\d{2}$/.test(x.data) && x.nome && x.area > 0 && x.por),
      tri.itens.map(x => x.data.slice(8) + '/' + x.data.slice(5, 7) + ' ' + x.nome + ' ' + x.area + ' ha · ' + x.por).join(' | '));
    ok('A foto do executado fica na tarefa (é o que o relatório do Supabase lê)',
      tri.snap && tri.snap.ha === tri.feito && tri.snap.n === tri.n && tri.snap.meta === 96, JSON.stringify(tri.snap));

    /* meta definida pelo escritório liga a barra numa tarefa que a ata trouxe sem área */
    const meta = await p2.page.evaluate(() => {
      const t = planTarefas().find(x => /KCL/i.test(x.desc));
      const antes = planProgresso(t).temMeta;
      t.meta = 30; salvarDados();
      const p = planProgresso(t);
      return { antes, depois: p.temMeta, meta: p.meta, resta: p.resta };
    });
    ok('Tarefa sem área na ata: o escritório informa a meta e a barra liga',
      meta.antes === false && meta.depois === true && meta.meta === 30, 'sem meta → ' + meta.meta + ' ha · restante ' + meta.resta);

    /* lançamento que não casou com tarefa nenhuma = executado fora do plano */
    const fora = await p2.page.evaluate(() => {
      const tals = talhoesDa('f22c').filter(x => x.fazendaId === 'f22c' && x.tipo !== 'ESTRUTURA' && x.tipo !== 'ARRENDADO');
      D.boletins.push({ id: 'foratest', fazendaId: 'f22c', data: diaISO(hojeBRT(), -1), responsavel: 'Maria',
        clima: { cond: 'Ensolarado', chuvaMm: '' }, mo: { proprios: '4', diaristas: '', funcoes: [] },
        atividades: [{ id: 'xf', tipo: 'Catação', talhaoId: tals[0].id, status: 'concluida', pessoas: '4' }],
        colheita: [], fito: [], ocorrencias: [], secoes: {} });
      salvarDados(); planMotor(true);
      const r = planForaDoPlano('f22c', planMesDe(hojeBRT()));
      const dentro = planTarefaDoLancamento('f22c', 'Levantar café', tals[0].id, diaISO(hojeBRT(), -3));
      return { total: r.total, fora: r.fora, pct: r.pct, ops: r.grupos.map(g => g.op),
        casou: dentro ? dentro.desc.slice(0, 30) : null, texto: planTextoFora().split('\n')[0] };
    });
    ok('Lançamento sem tarefa casada vira "executado fora do plano"',
      fora.fora >= 1 && fora.ops.includes('Catação') && fora.pct !== null,
      fora.fora + ' de ' + fora.total + ' lançamentos (' + fora.pct + '%) · ' + fora.ops.join(', '));
    ok('Lançamento que casa com tarefa NÃO entra no fora do plano', !!fora.casou, fora.casou || '');
    ok('"Executado fora do plano" também sai em texto para a próxima ata', /fora do plano/i.test(fora.texto), fora.texto);

    /* fechamento mensal: % do plano, % fora do plano e tarefas sem lançamento */
    const fech2 = await p2.page.evaluate(() => {
      const r = planResumoMes(planMesDe(hojeBRT()), 'f22c');
      return { metaHa: r.metaHa, execHa: r.execHa, pctArea: r.pctArea, semLanc: r.semLancamento.length,
        foraPct: r.fora ? r.fora.pct : null, texto: planTextoFechamento('') };
    });
    ok('Fechamento por unidade traz % do plano executado em área',
      fech2.pctArea !== null && fech2.metaHa > 0 && /plano executado: \d+% da área/.test(fech2.texto),
      'planejado ' + fech2.metaHa + ' ha · executado ' + fech2.execHa + ' ha (' + fech2.pctArea + '%)');
    ok('Fechamento por unidade traz % do esforço fora do plano',
      fech2.foraPct !== null && /esfor[çc]o fora do plano: \d+%/.test(fech2.texto), 'fora ' + fech2.foraPct + '%');
    ok('Fechamento por unidade lista as tarefas sem NENHUM lançamento',
      fech2.semLanc > 0 && /sem nenhum lan[çc]amento:/.test(fech2.texto), fech2.semLanc + ' tarefa(s)');

    /* 6. textos prontos, sem ferramenta externa */
    const txt = await p2.page.evaluate(() => ({ pauta: planTextoPauta(), cobranca: planTextoCobranca(''), ata: planTextoAta(), fech: planTextoFechamento('') }));
    ok('Pauta da sexta traz vencidas, vencendo em 7 dias e travadas',
      /VENCIDAS/.test(txt.pauta) && /VENCENDO EM ATÉ 7 DIAS/.test(txt.pauta) && /TRAVADAS/.test(txt.pauta), txt.pauta.split('\n')[0]);
    ok('Cobrança por fornecedor nomeia quem, o quê, desde quando e quantas fazendas',
      /Cooxup/.test(txt.cobranca) && /desde/.test(txt.cobranca) && /fazenda/.test(txt.cobranca),
      (txt.cobranca.split('\n').find(l => /Cooxup/.test(l)) || '').slice(0, 140));
    ok('Rascunho da próxima ata sai no formato da reunião ("2.1 – Fazenda" + "- item … PRAZO:")',
      /^2\.1 – /m.test(txt.ata) && /^- .*PRAZO: /m.test(txt.ata), txt.ata.split('\n').slice(2, 4).join(' ⏎ ').slice(0, 140));
    ok('Fechamento do mês por unidade sai pronto', /concluídas/.test(txt.fech), txt.fech.split('\n')[2] || '');

    /* a tela do módulo mostra os três números e abre a lista dos lançamentos num toque */
    const naTela = await p2.page.evaluate(async () => {
      planNav = [{ v: 'menu' }, { v: 'lista' }]; planLimpar(); planUI.filtroUnid = 'f22c'; ir('planejamento');
      await new Promise(r => setTimeout(r, 250));
      const cel = [...document.querySelectorAll('#app .plan-tres > span')].slice(0, 3).map(x => x.textContent.replace(/\s+/g, ' ').trim());
      const bt = document.querySelector('#app .plan-exec');
      const barra = document.querySelector('#app .plan-trio .plan-barra > span');
      if (bt) bt.click();
      await new Promise(r => setTimeout(r, 250));
      /* a tela redesenha ao abrir a lista: medir DEPOIS, no elemento que ficou */
      const alt = document.querySelector('#app .plan-tres > span');
      const lista = document.querySelector('#app .plan-exec-lista');
      return { cel, alvo: alt ? +alt.getBoundingClientRect().height.toFixed(1) : 0,
        barra: barra ? barra.style.width : '', larg: document.documentElement.scrollWidth,
        linhas: lista ? lista.querySelectorAll('.plan-exec-l').length : 0,
        tela: telaAtual, nativos: window.__nativos || 0 };
    });
    ok('Na tela: os três números aparecem juntos, com barra, sem rolar de lado',
      naTela.cel.length === 3 && /planejado/.test(naTela.cel[0]) && /executado/.test(naTela.cel[1]) && /restante/.test(naTela.cel[2])
      && /%$/.test(naTela.barra) && naTela.larg <= 390, naTela.cel.join(' · ') + ' · barra ' + naTela.barra);
    ok('Tocar em "executado" abre a lista dos lançamentos, no lugar e com alvo ≥ 44 px',
      naTela.linhas > 0 && naTela.alvo >= 44 && naTela.tela === 'planejamento' && naTela.nativos === 0,
      naTela.linhas + ' lançamento(s); alvo ' + naTela.alvo + ' px');

    ok('Nenhum erro de JavaScript na semana e nos textos', p2.erros.length === 0, p2.erros.join(' | '));
    estado = await lerD(p2.page);
    await p2.ctx.close();
  }

  /* ---------- 8 e 9. faixa do gerente (Vereda — Café), 360 px ---------- */
  {
    const { page, ctx, erros } = await novaPagina(browser, base, { codigo: CODIGOS.f22c, chave: 'f22c' },
      '2026-09-21T08:00:00-03:00', { userId: 'u1', papel: 'gerente', nome: 'Gerente', atividade: 'CAFE', fazendaId: 'f22c' });
    await porD(page, estado);
    await page.setViewportSize({ width: LARGURA_FAIXA, height: 844 });
    await page.evaluate(() => ir('casa')); await page.waitForTimeout(400);
    const faixa = await page.evaluate(() => {
      const box = document.getElementById('tar-faixa');
      if (!box) return { existe: false };
      const itens = [...box.querySelectorAll('.tar-item')];
      const alturaLinha = itens.length ? Math.round(itens[0].getBoundingClientRect().height) : 0;
      return { existe: true, itens: itens.length,
        linhasVisuais: new Set(itens.map(i => Math.round(i.getBoundingClientRect().top))).size,
        umaLinhaCada: itens.every(i => i.getBoundingClientRect().height <= alturaLinha + 2),
        alvo: itens.every(i => i.getBoundingClientRect().height >= 44),
        farois: itens.map(i => (i.querySelector('.tar-farol') || {}).textContent || ''),
        texto: box.textContent.replace(/\s+/g, ' ').trim(),
        scrollW: document.documentElement.scrollWidth,
        mais: !!box.querySelector('[data-tar-todas]') };
    });
    ok('Faixa do gerente aparece no topo da casa, com no máximo 3 linhas',
      faixa.existe && faixa.itens <= 3 && faixa.itens >= 1, faixa.existe ? faixa.itens + ' linha(s)' : 'não apareceu');
    ok('Cada linha da faixa cabe em UMA linha visual a 360 px, com alvo de toque ≥ 44 px',
      faixa.linhasVisuais === faixa.itens && faixa.alvo && faixa.scrollW <= LARGURA_FAIXA,
      faixa.itens + ' item(ns) em ' + faixa.linhasVisuais + ' linha(s); página ' + faixa.scrollW + ' px');
    const ordemOk = (() => { const p = { '🔴': 0, '🟡': 1, '⏸️': 2, '🟢': 3 };
      const v = faixa.farois.map(f => p[f.trim()]); return v.every((x, i) => i === 0 || v[i - 1] <= x); })();
    ok('Ordem da faixa: 🔴 → 🟡 → ⏸️ → 🟢', ordemOk, faixa.farois.join(' '));
    ok('Faixa não usa termo de cobrança ("não fez", "pendente", "faltou", "esqueceu")',
      !/não fez|não realizou|pendente|faltou|esqueceu/i.test(faixa.texto), faixa.texto.slice(0, 120));
    ok('"＋N tarefas" abre a lista sem sair da tela', faixa.mais, faixa.mais ? 'botão presente' : '');

    /* um toque muda o status, sem digitar e sem diálogo nativo */
    const toque = await page.evaluate(async () => {
      const alvo = planAbertasDa('f22c')[0], id = alvo.id, de = alvo.status;
      const st = de === 'em_execucao' ? 'finalizado' : 'em_execucao';   /* toca no status que a tarefa ainda NÃO tem */
      document.querySelector('#tar-faixa [data-tar]').click();
      await new Promise(r => setTimeout(r, 150));
      const folha = !!document.getElementById('folha-tarefa');
      const bt = document.querySelector('#folha-tarefa [data-tar-st="' + st + '"]');
      if (bt) bt.click();
      await new Promise(r => setTimeout(r, 150));
      const campos = document.querySelectorAll('#folha-tarefa input, #folha-tarefa select, #folha-tarefa textarea').length;
      return { folha, de, esperado: st, para: planTarefa(id).status, campos, tela: telaAtual, nativos: window.__nativos || 0 };
    });
    ok('Gerente muda o status em UM toque, sem digitar', toque.folha && toque.para === toque.esperado && toque.campos === 0,
      toque.de + ' → ' + toque.para + '; ' + toque.campos + ' campo(s) de digitação');
    ok('O toque não tira o gerente da tela nem abre diálogo nativo', toque.tela === 'casa' && toque.nativos === 0, toque.tela);

    /* travar por falta de insumo continua em cinza, nunca vermelho */
    const trava = await page.evaluate(async () => {
      document.querySelector('#folha-tarefa [data-tar-trava]').click();
      await new Promise(r => setTimeout(r, 120));
      document.querySelector('#folha-tarefa [data-tar-mot="insumo"]').click();
      await new Promise(r => setTimeout(r, 120));
      const t = planAbertasDa('f22c').find(x => x.status === 'aguardando_terceiro');
      return t ? { farol: planFarol(t), texto: planLinhaTexto(t) } : null;
    });
    ok('Travado por falta de insumo fica ⏸️ (nunca vermelho para o campo)', trava && trava.farol === 'cinza', trava && (trava.farol + ' · ' + trava.texto));

    /* gerente não enxerga tarefa de outra unidade */
    const escopo = await page.evaluate(() => ({
      visiveis: [...new Set(planVisiveis().map(t => t.unidade).filter(Boolean))],
      outras: planTarefas().filter(t => t.unidade && !podeVer(t.unidade)).length,
      naFaixa: [...document.querySelectorAll('#tar-faixa [data-tar]')].every(b => planTarefa(b.dataset.tar).unidade === 'f22c')
    }));
    ok('Gerente enxerga só a unidade dele', escopo.visiveis.length === 1 && escopo.visiveis[0] === 'f22c' && escopo.outras > 0 && escopo.naFaixa,
      'visíveis: ' + escopo.visiveis.join(',') + ' · ' + escopo.outras + ' de outras unidades fora do alcance');

    /* faixa no topo do boletim, sem bloquear o preenchimento */
    await page.evaluate(() => { document.getElementById('bt-tar-fechar').click(); });
    await page.waitForTimeout(200);
    await page.click('#bt-preencher'); await page.waitForTimeout(400);
    const noForm = await page.evaluate(() => {
      const box = document.getElementById('tar-faixa');
      const secoes = [...document.querySelectorAll('#app details.secao[open]')].length;
      return { faixa: !!box, secoes, enviar: !!document.getElementById('bt-enviar') };
    });
    ok('Faixa aparece no topo do boletim e nada bloqueia o preenchimento',
      noForm.faixa && noForm.secoes === 0 && noForm.enviar, noForm.secoes + ' seção(ões) abertas ao abrir');

    /* v78: o gerente vê o placar na faixa, os três números na folha e a etiqueta 📋 no lançamento */
    const ger78 = await page.evaluate(async () => {
      ir('casa'); await new Promise(r => setTimeout(r, 300));
      const faixa = (document.getElementById('tar-faixa') || {}).textContent || '';
      document.querySelector('#tar-faixa [data-tar]').click();
      await new Promise(r => setTimeout(r, 250));
      const f = document.getElementById('folha-tarefa');
      const cel = f ? [...f.querySelectorAll('.plan-tres > span')].map(x => x.textContent.replace(/\s+/g, ' ').trim()) : [];
      const bt = f && f.querySelector('.plan-exec');
      if (bt) bt.click();
      await new Promise(r => setTimeout(r, 250));
      const linhas = f ? f.querySelectorAll('.plan-exec-l').length : 0;
      const campos = f ? f.querySelectorAll('input, select, textarea').length : -1;
      document.getElementById('bt-tar-fechar').click();
      await new Promise(r => setTimeout(r, 200));
      const b = D.boletins.filter(x => x.fazendaId === 'f22c' && (x.atividades || []).some(a => a.tipo === 'Levantar café'))[0];
      ir('detalhe', b ? b.id : '');
      await new Promise(r => setTimeout(r, 250));
      const vinc = document.querySelector('#app .plan-vinc');
      return { faixa: faixa.replace(/\s+/g, ' ').trim(), cel, linhas, campos,
        vinc: vinc ? vinc.textContent.trim() : '', tela: telaAtual };
    });
    ok('Faixa do gerente traz o placar da tarefa ("N de M ha")', /\d+ de \d+ ha/.test(ger78.faixa),
      (ger78.faixa.match(/\d+ de \d+ ha/) || [''])[0]);
    ok('Folha do gerente traz os três números e a rastreabilidade, sem digitar',
      ger78.cel.length === 3 && ger78.linhas > 0 && ger78.campos === 0,
      ger78.cel.join(' · ') + ' · ' + ger78.linhas + ' lançamento(s) · ' + ger78.campos + ' campo(s)');
    ok('O lançamento do boletim mostra que abateu a tarefa (📋)', /^📋 abate:/.test(ger78.vinc), ger78.vinc);
    ok('Nenhum erro de JavaScript na tela do gerente', erros.length === 0, erros.join(' | '));
    await ctx.close();
  }

  /* ---------- 10. rituais que se abrem sozinhos ---------- */
  {
    /* sexta-feira: a porta da Diretoria é a tela de fechar a semana */
    const { page, ctx } = await novaPagina(browser, base, { codigo: 'DIRETORIA-8034', chave: 'DIRETORIA' }, '2026-09-25T08:00:00-03:00');
    await porD(page, estado);
    await page.evaluate(() => { ritualPuladoSessao = false; ir('painel'); }); await page.waitForTimeout(300);
    const sexta = await page.evaluate(() => ({ tela: telaAtual, titulo: (document.querySelector('#app .topo h1') || {}).textContent || '',
      pular: !!document.getElementById('bt-plan-ritual-pular') }));
    ok('Sexta-feira: a Diretoria cai sozinha na tela "Fechar a semana e planejar a próxima"',
      sexta.tela === 'planejamento' && /Fechar a semana/.test(sexta.titulo), sexta.titulo.replace(/\s+/g, ' ').slice(0, 60));
    ok('O ritual é pulável com um toque', sexta.pular, sexta.pular ? 'botão "Pular por agora"' : '');
    const pulou = await page.evaluate(async () => { document.getElementById('bt-plan-ritual-pular').click();
      await new Promise(r => setTimeout(r, 200)); return telaAtual; });
    ok('Pular leva ao painel e não trava a Diretoria', pulou === 'painel', pulou);
    await ctx.close();
  }
  {
    /* dia 11 sem ata do mês: a pastilha aparece na porta de entrada */
    const semAta = JSON.stringify(Object.assign(JSON.parse(estado), { rodadas: [], tarefas: [], tarefaHistorico: [], semanas: [] }));
    const { page, ctx } = await novaPagina(browser, base, { codigo: CODIGOS.ADMIN, chave: 'ADMIN' }, '2026-10-11T09:00:00-03:00');
    await porD(page, semAta);
    await page.evaluate(() => { ritualPuladoSessao = true; sessao = null; ir('entrada'); }); await page.waitForTimeout(300);
    const past = await page.evaluate(() => [...document.querySelectorAll('#app .pastilha')].map(b => b.textContent.trim()));
    ok('Dia 11 sem ata: pastilha "Rodada de outubro não importada" na porta de entrada',
      past.some(p => /Rodada de outubro não importada/.test(p)), past.join(' · ') || 'nenhuma pastilha');
    const semPend = await page.evaluate(() => { const antes = planPastilhas().length;
      D.rodadas = [{ id: 'r1', ref: hojeBRT().slice(0, 7), nome: 'Reunião', data: hojeBRT() }]; salvarDados();
      return { antes, depois: planPastilhas().filter(p => /Rodada/.test(p.txt)).length }; });
    ok('Nenhuma pastilha aparece sem pendência', semPend.depois === 0, 'antes ' + semPend.antes + ' · depois ' + semPend.depois);
    await ctx.close();
  }

  await browser.close(); srv.close();

  const falhas = provas.filter(p => !p.ok);
  if (process.argv.includes('--json')) console.log(JSON.stringify({ provas, falhas: falhas.length }, null, 2));
  else {
    console.log('# Módulo de planejamento (v77) — prova da validação da tarefa\n');
    provas.forEach(p => console.log(`- ${p.ok ? '✅' : '❌'} ${p.nome}${p.detalhe ? ' — ' + p.detalhe : ''}`));
    console.log(`\n## Resultado: ${provas.length - falhas.length} ✅ · ${falhas.length} ❌`);
  }
  process.exit(falhas.length ? 1 : 0);
})();
