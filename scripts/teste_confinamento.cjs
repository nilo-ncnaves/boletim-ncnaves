#!/usr/bin/env node
/*
 teste_confinamento.cjs — prova do módulo CONFINAMENTO (v102) do Boletim NCNaves.

 É a validação escrita na tarefa da v102 (perfil "Gerente de Confinamento", etapa 1 + diário) e roda
 SEM REDE, como um celular offline, a 390 px de largura. Serve de trava: sai com código 1 quando
 qualquer prova falha.

 O que prova (decisões do Nilo em 06/10/2026 — docs/CONFINAMENTO.md):
   a. O código da unidade (VF-NNNN) abre direto a casa do confinamento, com o cabeçalho
      "Vereda › Confinamento" e a régua de 7 dias; o dia sem registro cai no vazio da função única.
   b. Sem lote, "Preencher diário" nasce inativo e o toque diz a próxima ação ("Registre a entrada
      do primeiro lote"); nenhum termo de cobrança.
   c. Entrada de lote em 3 passos: ao abrir só os chips de curral (zero campo, zero seletor);
      escolhido o curral, só o grupo genético; escolhido o grupo, os detalhes com o código previsto
      CF-VER-<ano>-01; "Criar lote" inativo até cabeças, peso e origem, e ativa NO LUGAR.
   d. Lote misto = duas entradas: a segunda vira CF-VER-<ano>-02 (numeração por unidade e ano).
   e. Diário: uma linha por lote ativo; "Enviar diário" inativo nomeando o lote que falta; sobra e
      curral marcam no lugar; morte entra por "＋ morte" (causa em chips, peso estimado opcional),
      abate as cabeças vivas, tem "desfazer" no lugar e nunca é apagada (fica cancelada).
   f. Enviar → casa com o indicador de envio ("diário" na fila, offline), o diário de hoje guardado
      e o resumo WhatsApp com cabeçalho 🐃, uma linha por lote e a morte do dia.
   g. CSV do lote: cabeçalho fixo, separador ";", linhas ENTRADA, DIARIO e MORTE.
   h. Isolamento: as telas do café (f23) e da pecuária (f26) não ganham nenhum termo do
      confinamento; o código de pecuária não enxerga a unidade; o Administrador vê o botão novo e a
      Diretoria ganha a aba 🐃 no painel.
   i. Zero diálogo nativo e zero erro de página em todos os cenários; a fila offline recebe os três
      tipos novos (cfl, cfd, cfe).

 Uso (na raiz do repositório):
   node scripts/teste_confinamento.cjs
   node scripts/teste_confinamento.cjs --json

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
const CONF = { codigo: 'VF-6318', chave: 'f22f' };
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
async function novaPagina(browser, base, acesso, sessao) {
  const ctx = await browser.newContext({ viewport: VP, locale: 'pt-BR', timezoneId: 'America/Sao_Paulo' });
  await ctx.route('**/*', r => r.request().url().startsWith(base) ? r.continue() : r.abort());
  const page = await ctx.newPage();
  const erros = [];
  page.on('pageerror', e => erros.push(String(e).split('\n')[0]));
  await ctx.addInitScript(() => { window.__nativos = 0; ['alert', 'confirm', 'prompt'].forEach(k => { window[k] = () => { window.__nativos++; return k === 'confirm' ? true : null; }; }); });
  await page.goto(base + '/index.html');
  await page.evaluate(([a, s]) => { localStorage.clear(); localStorage.setItem('bdf:acesso', JSON.stringify(a)); if (s) localStorage.setItem('bdf:sessao', JSON.stringify(s)); }, [acesso, sessao]);
  await page.reload(); await page.waitForTimeout(900);
  await page.evaluate(() => { ritualPuladoSessao = true; });
  return { page, ctx, erros };
}
const texto = p => p.evaluate(() => document.querySelector('#app').innerText.replace(/\s+/g, ' '));
const visiveis = (p, sel) => p.evaluate(s => [...document.querySelectorAll('#app ' + s)].filter(el => el.getClientRects().length).length, sel);
const botao = (p, sel) => p.evaluate(s => { const b = document.querySelector(s); if (!b) return null;
  return { inativo: b.classList.contains('acao-off') && b.getAttribute('aria-disabled') === 'true', falta: b.getAttribute('data-falta') || '', texto: b.textContent.trim() }; }, sel);
const digita = async (p, sel, v) => { await p.fill(sel, v); await p.waitForTimeout(80); };
const PROIBIDO = /n[ãa]o fez|n[ãa]o realizou|pendente|atrasad|faltou|esqueceu|obrigat/i;
const TERMOS_CF = /confinamento|curral|\bCMS\b|lote no cocho|sobra de cocho|GMD/i;

(async () => {
  const { srv, base } = await servir(RAIZ);
  const browser = await pw.chromium.launch();
  try {
    /* ---- a/b: casa sem lote ---- */
    const { page, ctx, erros } = await novaPagina(browser, base, CONF, null);
    await page.evaluate(() => entrarPeloAcesso()); await page.waitForTimeout(300);   /* o que o toque em "Entrar" faz depois do código */
    const casa0 = await page.evaluate(() => ({ tela: telaAtual, papel: sessao && sessao.papel, fz: sessao && sessao.fazendaId,
      h1: (document.querySelector('#app .topo.ctx h1') || {}).textContent || '', regua: document.querySelectorAll('#app .regua-dia').length,
      largo: document.querySelector('#app').className }));
    ok('a. Código VF-6318 abre direto a casa do confinamento (papel "conf", unidade f22f)', casa0.tela === 'casa' && casa0.papel === 'conf' && casa0.fz === 'f22f', `${casa0.tela} · ${casa0.papel} · ${casa0.fz}`);
    ok('a. Cabeçalho contextual "Vereda › Confinamento" (componente único), tela estreita como a do gerente', /Vereda › Confinamento/.test(casa0.h1) && casa0.largo === '', `"${casa0.h1.trim()}" · classe "${casa0.largo}"`);
    ok('a. Régua de 7 dias na casa', casa0.regua === 7, casa0.regua + ' células');
    await page.click('#app .regua-dia >> nth=1'); await page.waitForTimeout(300);
    const vazioDia = await texto(page);
    const unNome = await page.evaluate(() => fazenda('f22f').nome);
    ok('a. Dia sem registro cai no vazio da função única, nomeando a unidade e o dia', new RegExp('Sem diário registrado em ' + unNome.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ' em \\d\\d/\\d\\d/\\d{4}').test(vazioDia) && !PROIBIDO.test(vazioDia), (vazioDia.match(/Sem diário[^.]*\./) || ['não achei'])[0]);
    await page.click('#app .regua-dia >> nth=0'); await page.waitForTimeout(300);
    const b0 = await botao(page, '#bt-preencher-cf');
    ok('b. Sem lote, "Preencher diário de hoje" nasce inativo e diz a próxima ação', b0 && b0.inativo && /Registre a entrada do primeiro lote/.test(b0.falta), b0 ? `"${b0.falta}"` : 'botão ausente');
    const t0 = await texto(page);
    ok('b. Casa sem lote: vazio da lista de lotes nomeia a unidade; nenhum termo de cobrança', /Sem lote ativo/.test(t0) && !PROIBIDO.test(t0), (t0.match(/Sem lote ativo[^.]*\./) || [''])[0]);

    /* ---- c: entrada de lote em 3 passos ---- */
    await page.click('#bt-cf-novo'); await page.waitForTimeout(300);
    const p1 = { tela: await page.evaluate(() => telaAtual), inputs: await visiveis(page, 'input, select, textarea'), chips: await visiveis(page, '[data-cfncur]'), gen: await visiveis(page, '[data-cfngen]') };
    ok('c. Ao abrir "Entrada de lote": só os chips de curral (ONDE) — zero campo, zero seletor, nada do passo 2', p1.tela === 'cfnovo' && p1.inputs === 0 && p1.chips >= 1 && p1.gen === 0, `${p1.chips} currais · ${p1.inputs} campos · ${p1.gen} chips de genética`);
    await page.click('[data-cfncur="tcf03"]'); await page.waitForTimeout(250);
    const p2 = { inputs: await visiveis(page, 'input, select, textarea'), gen: await visiveis(page, '[data-cfngen]'), cur: await visiveis(page, '[data-cfncur]') };
    ok('c. Escolhido o curral: só o grupo genético (O QUÊ), ainda sem campo', p2.inputs === 0 && p2.gen === 2 && p2.cur === 0, `${p2.gen} chips · ${p2.inputs} campos`);
    await page.click('[data-cfngen="NELORE"]'); await page.waitForTimeout(250);
    const ano = await page.evaluate(() => hojeBRT().slice(0, 4));
    const p3 = { inputs: await visiveis(page, 'input'), txt: await texto(page), bt: await botao(page, '#bt-cf-criar') };
    ok('c. Escolhido o grupo: detalhes com o código previsto CF-VER-' + ano + '-01', p3.inputs >= 5 && p3.txt.includes('CF-VER-' + ano + '-01'), `${p3.inputs} campos`);
    ok('c. "Criar lote" nasce inativo e diz o que falta (cabeças), sem acusar', p3.bt && p3.bt.inativo && /Informe as cabeças/.test(p3.bt.falta) && !PROIBIDO.test(p3.bt.falta), p3.bt ? `"${p3.bt.falta}"` : '');
    await page.evaluate(() => document.querySelector('#bt-cf-criar').setAttribute('data-marca-teste', '1'));
    await digita(page, 'input[data-cfn="cabecas"]', '120');
    await digita(page, 'input[data-cfn="peso"]', '380');
    const p3b = await botao(page, '#bt-cf-criar');
    await page.click('[data-cfnorig="RECRIA"]'); await page.waitForTimeout(250);
    const p3c = await page.evaluate(() => { const b = document.querySelector('#bt-cf-criar'); return { inativo: b.classList.contains('acao-off'), rot: [...document.querySelectorAll('#app label')].map(l => l.textContent).join('|') }; });
    ok('c. Com cabeças e peso o botão ainda pede a origem; com a origem ativa (recria: rótulo "Fazenda de origem" e preço estimado)', p3b.inativo && /origem/.test(p3b.falta) && !p3c.inativo && /Fazenda de origem/.test(p3c.rot) && /estimado/.test(p3c.rot), `"${p3b.falta}" → ${p3c.inativo ? 'inativo' : 'ativo'}`);
    await digita(page, 'input[data-cfn="fornecedor"]', 'Chapadão');
    await page.click('#bt-cf-criar'); await page.waitForTimeout(400);
    const l1 = await page.evaluate(() => ({ tela: telaAtual, txt: document.querySelector('#app').innerText.replace(/\s+/g, ' '), lote: (D.cfLotes || [])[0] || null, fila: syncFila.map(x => x.t) }));
    ok('c. Lote criado: CF-VER-' + ano + '-01, 120 cabeças, 380 kg, curral 3, Nelore, recria; tela do lote com dia 0, 120 vivas e "sem pesagem desde a entrada"',
      l1.tela === 'cflote' && l1.lote && l1.lote.id === 'CF-VER-' + ano + '-01' && l1.lote.cabecasEntrada === 120 && l1.lote.pesoEntradaKg === 380 && l1.lote.curralId === 'tcf03' && l1.lote.genetica === 'NELORE' && l1.lote.origem === 'RECRIA'
        && /dias de cocho/.test(l1.txt) && /120 de 120|120.*cabeças vivas/.test(l1.txt) && /sem pesagem desde a entrada/.test(l1.txt) && /Lote CF-VER-\d{4}-01 criado/.test(l1.txt) && l1.fila.includes('cfl'),
      l1.lote ? `${l1.lote.id} · fila ${l1.fila.join(',')}` : 'sem lote');
    ok('c. Tela do lote: sem projeção lançada diz isso com todas as letras, nunca farol vermelho', /Sem projeção lançada/.test(l1.txt) && !/critico/.test(await page.evaluate(() => [...document.querySelectorAll('#app .farol')].map(f => f.className).join(' '))), '');
    await page.click('#app [data-voltar]'); await page.waitForTimeout(300);
    ok('c. "‹ Voltar" da tela do lote devolve à casa', (await page.evaluate(() => telaAtual)) === 'casa', '');

    /* ---- d: segundo lote (lote misto = duas entradas) ---- */
    await page.click('#bt-cf-novo'); await page.waitForTimeout(250);
    await page.click('[data-cfncur="tcf03"]'); await page.waitForTimeout(200);
    await page.click('[data-cfngen="CRUZADO_ANGUS"]'); await page.waitForTimeout(200);
    await digita(page, 'input[data-cfn="cabecas"]', '80'); await digita(page, 'input[data-cfn="peso"]', '410');
    await page.click('[data-cfnorig="COMPRA"]'); await page.waitForTimeout(200);
    await digita(page, 'input[data-cfn="preco"]', '320'); await page.click('[data-cfnpun="ARROBA"]'); await page.waitForTimeout(100);
    await page.click('#bt-cf-criar'); await page.waitForTimeout(300);
    const l2 = await page.evaluate(() => ({ ids: (D.cfLotes || []).map(l => l.id), l: (D.cfLotes || [])[1] }));
    ok('d. Lote misto no mesmo curral = dois lotes: o segundo é CF-VER-' + ano + '-02 (Cruzado Angus, compra, 320 R$/@)', l2.ids.join() === `CF-VER-${ano}-01,CF-VER-${ano}-02` && l2.l && l2.l.genetica === 'CRUZADO_ANGUS' && l2.l.precoValor === 320 && l2.l.precoUn === 'ARROBA', l2.ids.join(' · '));
    await page.evaluate(() => ir('casa'));
    const casa1 = await page.evaluate(() => ({ lotes: document.querySelectorAll('#app [data-cflote]').length, txt: document.querySelector('#app').innerText.replace(/\s+/g, ' ') }));
    const bPre = await botao(page, '#bt-preencher-cf');
    ok('d. Casa: uma linha por lote ativo (código · genética · cabeças · dia) e "Preencher diário" ativo', casa1.lotes === 2 && /CF-VER-\d{4}-01 · Nelore · 120 cab · dia 0/.test(casa1.txt) && bPre && !bPre.inativo, `${casa1.lotes} linhas`);

    /* ---- e: diário ---- */
    await page.click('#bt-preencher-cf'); await page.waitForTimeout(300);
    const f0 = await page.evaluate(() => ({ tela: telaAtual, linhas: document.querySelectorAll('#app [data-cfl]').length, secoes: document.querySelectorAll('#app details[open]').length,
      rodape: (() => { const b = document.querySelector('#bt-enviar-cf'); if (!b) return null; const r = b.getBoundingClientRect(); return r.top >= 0 && r.bottom <= innerHeight; })() }));
    const e0 = await botao(page, '#bt-enviar-cf');
    ok('e. Diário: uma linha por lote ativo, "Enviar diário" fixo no rodapé, visível sem rolar', f0.tela === 'cfform' && f0.linhas === 2 && f0.rodape === true, `${f0.linhas} linhas · rodapé ${f0.rodape}`);
    ok('e. "Enviar diário" nasce inativo e nomeia o lote e o campo que faltam (sobra de cocho do lote 01)', e0 && e0.inativo && /Marque a sobra de cocho do lote CF-VER-\d{4}-01/.test(e0.falta), e0 ? `"${e0.falta}"` : '');
    await page.evaluate(() => document.querySelector('#bt-enviar-cf').setAttribute('data-marca-teste', '1'));
    await page.click('[data-cfsobra="0:2"]'); await page.waitForTimeout(100);
    const e1 = await botao(page, '#bt-enviar-cf');
    await page.click('[data-cfcur="0:SECO"]'); await page.waitForTimeout(100);
    const e2 = await botao(page, '#bt-enviar-cf');
    ok('e. Sobra marcada → agora falta o curral do lote 01; curral marcado → falta o lote 02 (um passo por vez, no lugar)', /curral do lote CF-VER-\d{4}-01/.test(e1.falta) && /sobra de cocho do lote CF-VER-\d{4}-02/.test(e2.falta), `"${e1.falta}" → "${e2.falta}"`);
    const chipsOn = await page.evaluate(() => [...document.querySelectorAll('#app [data-cfl="0"] .chip.on')].map(c => c.textContent.trim()));
    ok('e. Os chips escolhidos ficam acesos no lugar, sem redesenhar a tela', chipsOn.join() === '2,Seco', chipsOn.join(' · '));
    await digita(page, '[data-cfl="0"] input[data-cfd="cms"]', '9,8');
    await digita(page, '[data-cfl="0"] input[data-cfd="enfermaria"]', '1');
    /* morte do lote 01 */
    await page.click('[data-cfmorte="0"]'); await page.waitForTimeout(250);
    const m0 = { causas: await visiveis(page, '[data-cfcausa]'), bt: await botao(page, '#bt-cf-morte-ok') };
    ok('e. "＋ morte" abre causa em chips (7 causas) e "Registrar morte" inativo até a causa', m0.causas === 7 && m0.bt && m0.bt.inativo && /causa/.test(m0.bt.falta), `${m0.causas} causas · "${m0.bt ? m0.bt.falta : ''}"`);
    await page.click('[data-cfcausa="0:Timpanismo"]'); await page.waitForTimeout(100);
    await digita(page, 'input[data-cfm="peso"]', '420');
    await page.click('#bt-cf-morte-ok'); await page.waitForTimeout(300);
    const m1 = await page.evaluate(() => ({ txt: document.querySelector('#app [data-cfl="0"]').innerText.replace(/\s+/g, ' '), ev: (D.cfEventos || []).length, desfazer: !!document.querySelector('#app [data-cfdesfazer]'), fila: syncFila.map(x => x.t) }));
    ok('e. Morte registrada: linha "Morte · Timpanismo · 420 kg est." com "desfazer" no lugar; 119 cabeças vivas na linha do lote; evento na fila (cfe)', /Morte · Timpanismo · 420 kg est\./.test(m1.txt) && /119 cab/.test(m1.txt) && m1.ev === 1 && m1.desfazer && m1.fila.includes('cfe'), m1.txt.slice(0, 120));
    await page.click('#app [data-cfdesfazer]'); await page.waitForTimeout(300);
    const m2 = await page.evaluate(() => ({ txt: document.querySelector('#app [data-cfl="0"]').innerText.replace(/\s+/g, ' '), ev: (D.cfEventos || []).map(e => !!e.cancelado) }));
    ok('e. "desfazer" volta as 120 cabeças e NÃO apaga: o evento fica cancelado', /120 cab/.test(m2.txt) && !/Timpanismo/.test(m2.txt) && m2.ev.join() === 'true', `cancelado: ${m2.ev.join()}`);
    await page.click('[data-cfmorte="0"]'); await page.waitForTimeout(200);
    await page.click('[data-cfcausa="0:Acidose"]'); await page.waitForTimeout(100);
    await page.click('#bt-cf-morte-ok'); await page.waitForTimeout(300);
    /* lote 02 (o registro da morte redesenhou o formulário; a prova do "no lugar" é deste ponto em diante) */
    await page.evaluate(() => document.querySelector('#bt-enviar-cf').setAttribute('data-marca-teste', '1'));
    await page.click('[data-cfsobra="1:4"]'); await page.waitForTimeout(100);
    await page.click('[data-cfcur="1:LAMA"]'); await page.waitForTimeout(100);
    const e3 = await page.evaluate(() => { const b = document.querySelector('#bt-enviar-cf'); return { ativo: !b.classList.contains('acao-off') && !b.getAttribute('data-falta'), noLugar: b.getAttribute('data-marca-teste') === '1' }; });
    ok('e. Com os dois lotes marcados, "Enviar diário" ativa no lugar (mesmo elemento, sem redesenhar)', e3.ativo && e3.noLugar, `${e3.ativo ? 'ativo' : 'inativo'} · ${e3.noLugar ? 'mesmo elemento' : 'redesenhado'}`);
    const formTxt = await texto(page);
    ok('e. Diário sem termo de cobrança e sem seletor nativo de data', !PROIBIDO.test(formTxt) && (await visiveis(page, 'input[type=date], select')) === 0, '');

    /* ---- f: envio ---- */
    await page.click('#bt-enviar-cf'); await page.waitForTimeout(1500);
    await page.evaluate(() => ir('casa', null, true));   /* a tentativa de envio (abortada, offline) já terminou: estado final do indicador */
    const f1 = await page.evaluate(() => { const d = (D.cfDiarios || [])[0]; return { tela: telaAtual, n: (D.cfDiarios || []).length, id: d && d.id, fila: syncFila.map(x => x.t),
      txt: document.querySelector('#app').innerText.replace(/\s+/g, ' '), faixa: (document.querySelector('#app .aviso') || {}).textContent || '', zap: d ? resumoWhatsConf(d) : '', rasc: localStorage.getItem('bdf:rasccf'), nativos: window.__nativos }; });
    ok('f. Enviar → casa; diário gravado com id unidade_data e na fila (cfd); rascunho limpo', f1.tela === 'casa' && f1.n === 1 && /^f22f_\d{4}-\d{2}-\d{2}$/.test(f1.id) && f1.fila.includes('cfd') && !f1.rasc, `${f1.id} · fila ${f1.fila.join(',')}`);
    ok('f. Indicador de envio (componente único) fala em "diário" e, offline, "Aguardando internet" — nunca "enviado" antes do banco', /Aguardando internet \(1 diário na fila\)/.test(f1.faixa) && /Diário de hoje guardado no aparelho/.test(f1.txt), f1.faixa.replace(/\s+/g, ' ').slice(0, 90));
    ok('f. Resumo WhatsApp: cabeçalho 🐃 CONFINAMENTO VEREDA, clima, uma linha por lote com CMS/sobra/enfermaria/curral, a morte do dia e o desvio de sobra 4',
      /^🐃 \*CONFINAMENTO VEREDA\* — \d\d\/\d\d\/\d{4}/.test(f1.zap) && /🐂 CF-VER-\d{4}-01 · 119 cab · dia 0 · CMS 9,8 kg MS · sobra 2 · 1 na enfermaria · curral seco/.test(f1.zap)
        && /🐂 CF-VER-\d{4}-02 · 80 cab · dia 0 · sem CMS · sobra 4 · curral lama/.test(f1.zap) && /⚠️ Morte CF-VER-\d{4}-01: 1 \(acidose\)/.test(f1.zap) && /🔎 Fora do esperado: CF-VER-\d{4}-02 sobra 4/.test(f1.zap) && !PROIBIDO.test(f1.zap),
      f1.zap.split('\n').join(' | ').slice(0, 300));
    /* diário enviado e correção */
    await page.click('#bt-preencher-cf'); await page.waitForTimeout(300);
    const det = await page.evaluate(() => ({ tela: telaAtual, txt: document.querySelector('#app').innerText.replace(/\s+/g, ' '), corrigir: !!document.querySelector('#app [data-cfcorrigir]'), off: document.querySelectorAll('#app .acao-off').length }));
    ok('f. "Ver / corrigir diário de hoje" abre o diário enviado (sem CMS lê "sem CMS") com Corrigir permitido ao gerente de confinamento', det.tela === 'cfdetalhe' && /sem CMS/.test(det.txt) && /9,8 kg MS/.test(det.txt) && det.corrigir && det.off === 0, '');
    await page.click('#app [data-cfcorrigir]'); await page.waitForTimeout(300);
    await digita(page, '[data-cfl="1"] input[data-cfd="cms"]', '10,2');
    await page.click('#bt-enviar-cf'); await page.waitForTimeout(400);
    const cor = await page.evaluate(() => ({ n: (D.cfDiarios || []).length, cms: (D.cfDiarios || [])[0].lotes[1].cms, ed: !!(D.cfDiarios || [])[0].editadoEm, fila: syncFila.filter(x => x.t === 'cfd').length }));
    ok('f. Corrigir regrava o MESMO diário (um só por dia), marcado como corrigido, um item só na fila', cor.n === 1 && cor.cms === '10,2' && cor.ed && cor.fila === 1, `${cor.n} diário · CMS ${cor.cms}`);

    /* ---- g: CSV ---- */
    const csv = await page.evaluate(() => cfCsvTexto((D.cfLotes || [])[0].id));
    const linhas = csv.split('\r\n');
    ok('g. CSV do lote: cabeçalho fixo com ";" e uma linha por evento (ENTRADA, DIARIO, MORTE), sem a morte cancelada',
      linhas[0] === 'lote;unidade;tipo;data;cabecas;peso_kg;cms_kg_ms;sobra_escore;enfermaria;curral;causa;responsavel;obs' && linhas.length === 4
        && /;ENTRADA;\d{4}-\d\d-\d\d;120;380;/.test(csv) && /;DIARIO;[^;]+;;;9,8;2;1;Seco;/.test(csv) && /;MORTE;[^;]+;1;;;;;;Acidose;/.test(csv) && !/Timpanismo/.test(csv),
      linhas.length + ' linhas');
    ok('i. Cenário do gerente de confinamento: zero diálogo nativo e zero erro de página', f1.nativos === 0 && !erros.length, erros[0] || 'sem erro');
    await ctx.close();

    /* ---- h: isolamento ---- */
    for (const [rot, cod, chave, atv, fz, bt] of [['Café (f23)', 'VR-7061', 'f23', 'CAFE', 'f23', '#bt-preencher'], ['Pecuária (f26)', 'AS-6754', 'f26', 'PECUARIA', 'f26', '#bt-preencher']]) {
      const g = await novaPagina(browser, base, { codigo: cod, chave }, { userId: 'u1', papel: 'gerente', nome: 'Gerente', atividade: atv, fazendaId: fz });
      const casa = await texto(g.page);
      await g.page.click(bt).catch(() => {}); await g.page.waitForTimeout(400);
      await g.page.evaluate(() => document.querySelectorAll('details').forEach(d => { d.open = true; }));
      const form = await texto(g.page);
      const vis = await g.page.evaluate(() => unidadesPermitidas().map(f => f.id));
      ok(`h. ${rot}: casa e boletim sem nenhum termo do confinamento; a unidade f22f não entra no escopo`, !TERMOS_CF.test(casa) && !TERMOS_CF.test(form) && !vis.includes('f22f') && !g.erros.length, (casa.match(TERMOS_CF) || form.match(TERMOS_CF) || ['nenhum'])[0]);
      await g.ctx.close();
    }
    {
      const g = await novaPagina(browser, base, { codigo: 'PECU-5926', chave: 'ATV:PECUARIA' }, null);
      const r = await g.page.evaluate(() => ({ tela: telaAtual, vis: unidadesPermitidas().map(f => f.id), botao: !!document.querySelector('[data-atividade="CONFINAMENTO"]') }));
      ok('h. Código de pecuária (PECU) não enxerga a unidade de confinamento nem o botão dela', !r.vis.includes('f22f') && !r.botao, `${r.tela} · ${r.vis.length} unidades`);
      await g.ctx.close();
    }
    {
      const g = await novaPagina(browser, base, { codigo: 'CONF-4725', chave: 'ATV:CONFINAMENTO' }, null);
      await g.page.evaluate(() => entrarPeloAcesso()); await g.page.waitForTimeout(300);
      const r = await g.page.evaluate(() => ({ tela: telaAtual, papel: sessao && sessao.papel, fz: sessao && sessao.fazendaId }));
      ok('h. Código da atividade (CONF) com uma unidade só abre direto a casa do confinamento', r.tela === 'casa' && r.papel === 'conf' && r.fz === 'f22f', `${r.tela} · ${r.papel}`);
      await g.ctx.close();
    }
    {
      const g = await novaPagina(browser, base, { codigo: 'ADMIN-9561', chave: 'ADMIN' }, null);
      const r = await g.page.evaluate(() => ({ botao: !!document.querySelector('[data-atividade="CONFINAMENTO"]'), txt: document.querySelector('#app').innerText }));
      await g.page.click('[data-atividade="CONFINAMENTO"]'); await g.page.waitForTimeout(300);
      const r2 = await g.page.evaluate(() => ({ tela: telaAtual, papel: sessao && sessao.papel, lista: [...document.querySelectorAll('[data-fazenda]')].map(b => b.dataset.fazenda) }));
      await g.page.evaluate(() => { sessao = { userId: 'u3', papel: 'admin', nome: 'Escritório' }; ir('painel'); });
      await g.page.waitForTimeout(300);
      const r3 = await g.page.evaluate(() => ({ aba: !!document.querySelector('[data-atv-filtro="CONFINAMENTO"]'), txt: (document.querySelector('[data-atv-filtro="CONFINAMENTO"]') || {}).textContent || '' }));
      ok('h. Administrador vê o botão "🐃 Confinamento" na entrada; o toque leva à lista com a unidade Vereda — Confinamento', r.botao && r2.tela === 'fazendas' && r2.papel === 'conf' && r2.lista.join() === 'f22f', `${r2.tela} · ${r2.lista.join()}`);
      ok('h. Painel da Diretoria/Escritório ganha a aba 🐃 Confinamento pelo catálogo ATIVIDADES (componente único chipsAtividade)', r3.aba && /🐃 Confinamento/.test(r3.txt), r3.txt.trim());
      ok('i. Cenários de isolamento sem erro de página', !g.erros.length, g.erros[0] || 'sem erro');
      await g.ctx.close();
    }
  } finally { await browser.close(); srv.close(); }

  const falhas = provas.filter(p => !p.ok);
  if (process.argv.includes('--json')) console.log(JSON.stringify({ provas, falhas: falhas.length }, null, 2));
  else {
    console.log('# Confinamento (v102) — prova da validação da tarefa\n');
    provas.forEach(p => console.log(`- ${p.ok ? '✅' : '❌'} ${p.nome}${p.detalhe ? ' — ' + p.detalhe : ''}`));
    console.log(`\n## Resultado: ${provas.length - falhas.length} ✅ · ${falhas.length} ❌`);
  }
  process.exit(falhas.length ? 1 : 0);
})().catch(e => { console.error('FALHOU: ' + e.stack); process.exit(2); });
