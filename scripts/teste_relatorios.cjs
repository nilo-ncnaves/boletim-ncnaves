#!/usr/bin/env node
/*
 teste_relatorios.cjs — prova dos RELATÓRIOS DA DIRETORIA EM TRÊS NÍVEIS (v99) do Boletim NCNaves.

 É a validação escrita na tarefa da v99 (menu › abas por atividade › folha da unidade) e roda
 SEM REDE, como um celular offline, a 390 px de largura. Serve de trava: sai com código 1
 quando qualquer prova falha.

 O que prova, na ordem da tarefa (item 4):
   a. 24 textos por unidade + 1 de grupo → 4 abas, contadores 🏢 1 · ☕ 10 · 🌾 5 · 🐂 9,
      na ordem fixa; nível 1 com duas linhas de menu e o estado na linha.
   b. Código de escopo só de pecuária → sem abas, 9 linhas (hoje nenhum código com painel é
      de uma atividade só, e o texto do redator só desce para escopo total — a prova simula
      o escopo, com a trava de baixarRelatorios, para a regra valer quando ele existir).
   c. Unidade do escopo sem texto → linha "sem texto neste período", sem ação.
   d. Tocar a linha → a folha abre com o texto integral daquela unidade e de nenhuma outra.
   e. Fechar a folha → mesma aba, mesma rolagem.
   f. unidade_id fora do catálogo → cai em 🏢 Grupo, com o id visível, sem quebrar a tela.
   g. Nenhuma linha usa trecho do nome para decidir atividade: uma unidade de pecuária
      rebatizada "Café do Sul" continua em 🐂 Pecuária.
   Mais: o gerente continua sem ver texto nenhum; a folha é a mesma da v68 (relCopiar
   copia o texto integral); Números é o conteúdo de antes em tela própria; voltar sobe um
   degrau por vez.

 Uso (na raiz do repositório):
   node scripts/teste_relatorios.cjs
   node scripts/teste_relatorios.cjs --json    # imprime o resultado em JSON

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
const DIRETORIA = { codigo: 'DIRETORIA-8034', chave: 'DIRETORIA' };
const SESSAO = { userId: 'u2', papel: 'proprietario', nome: 'Diretoria' };

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
/* 24 devolutivas (uma por unidade do cadastro) + 1 painel executivo (grupo) + 1 farol — roda dentro da página */
const SEMENTE = () => {
  const d = n => { const x = new Date(); x.setDate(x.getDate() - n); return x.toISOString().slice(0, 10); };
  const em = new Date(d(0) + 'T05:35:00-03:00').toISOString(), base = { gerado_em: em, texto_em: em, texto_modelo: 'claude-sonnet-4-6', dados: { composto: true, fontes: [] } };
  const ls = D.fazendas.map((f, i) => ({ id: 'tx-' + f.id, relatorio: 'devolutiva_semanal', periodo_ini: d(12), periodo_fim: d(6), unidade_id: f.id,
    texto: f.nome + ' — devolutiva da semana (' + f.id + ').\n\n' + 'Boletins: a unidade registrou boletim em 5 dos 6 dias úteis da semana; o dia sem registro foi a quarta-feira. '.repeat(4 + i % 3), ...base }));
  ls.push({ id: 'tx-grupo', relatorio: 'painel_executivo', periodo_ini: d(40).slice(0, 8) + '01', periodo_fim: d(10), unidade_id: null, texto: 'Painel executivo do grupo.\n\nTexto do mês para os sócios.', ...base });
  ls.push({ id: 'n1', relatorio: 'farol_7', periodo_ini: d(7), periodo_fim: d(1), unidade_id: 'f33', dados: { em_dia: false, enviados: 5, uteis: 6, marcas: '●●○●●●' }, gerado_em: em, texto: null });
  relCache = ls; relEstado.erro = false; relTextosVista.aba = '';
};
const ABAS = () => [...document.querySelectorAll('#app [data-relaba]')].map(b => b.textContent.trim() + (b.classList.contains('on') ? ' *' : ''));
const LINHAS = () => [...document.querySelectorAll('#app .cad-item')].map(b => ({ nome: (b.querySelector('b') || {}).textContent || '', estado: (b.querySelector('.mut') || {}).textContent || '', botao: b.tagName === 'BUTTON', seta: !!b.querySelector('.seta'), un: b.dataset.relUn || '', chave: b.dataset.txtler || '' }));

(async () => {
  const { srv, base } = await servir(RAIZ);
  const browser = await pw.chromium.launch();
  try {
    /* ---- a, c, d, e, f, g: Diretoria com 24 textos + 1 de grupo ---- */
    {
      const { page, ctx, erros } = await novaPagina(browser, base, DIRETORIA, SESSAO);
      await page.evaluate(SEMENTE);
      await page.evaluate(() => ir('relatorios')); await page.waitForTimeout(300);
      const nivel1 = await page.evaluate(LINHAS_STR => { const LINHAS = eval(LINHAS_STR); return { tela: telaAtual, telas: +(document.documentElement.scrollHeight / 844).toFixed(2), linhas: LINHAS(), previas: document.querySelectorAll('#app .txt-previa, #app .txt-cartao').length, cartoes: document.querySelectorAll('#app .cartao').length }; }, LINHAS.toString());
      ok('a. Nível 1 — duas linhas de menu, sem prévia e sem cartão, em 1 tela', nivel1.linhas.length === 2 && nivel1.previas === 0 && nivel1.cartoes === 0 && nivel1.telas <= 1,
        `${nivel1.linhas.length} linhas · ${nivel1.previas} prévia(s) · ${nivel1.cartoes} cartão(ões) · ${nivel1.telas} telas`);
      ok('a. Nível 1 — estado na linha: "2 relatórios · 25 textos" e "último: … · 1 para conferir"',
        nivel1.linhas[0].estado === '2 relatórios · 25 textos' && /^último: \d\d a \d\d\/\d\d · 1 para conferir$/.test(nivel1.linhas[1].estado),
        `"${nivel1.linhas[0].estado}" · "${nivel1.linhas[1].estado}"`);
      await page.click('#bt-rel-textos'); await page.waitForTimeout(300);
      const abas = await page.evaluate(ABAS_STR => eval(ABAS_STR)(), ABAS.toString());
      ok('a. 24 textos por unidade + 1 de grupo → 4 abas, contadores 🏢 1 · ☕ 10 · 🌾 5 · 🐂 9, na ordem fixa, Grupo aberta primeiro',
        abas.join(' | ') === '🏢 Grupo (1) * | ☕ Café (10) | 🌾 Grãos (5) | 🐂 Pecuária (9)', abas.join(' | '));
      const fila = await page.evaluate(() => { const f = document.querySelector('#app .rel-abas'); return { largura: f.scrollWidth, cliente: f.clientWidth, pagina: document.documentElement.scrollWidth, wrap: getComputedStyle(f).flexWrap }; });
      ok('a. A fileira de abas quebra em linhas e nunca passa de 390 px', fila.wrap === 'wrap' && fila.largura <= fila.cliente + 1 && fila.pagina <= 390, `${fila.largura} px em ${fila.cliente}; página ${fila.pagina} px`);
      /* g. nome enganoso: uma unidade de pecuária rebatizada "Café do Sul" continua em 🐂 */
      const g = await page.evaluate(LINHAS_STR => { const LINHAS = eval(LINHAS_STR);
        const un = D.fazendas.find(f => atividadeDe(f.id) === 'PECUARIA'); const nomeAntes = un.nome; un.nome = 'Café do Sul';
        relTextosVista.aba = 'CAFE'; ir('reltextos', null, true); const emCafe = LINHAS().some(l => l.un === un.id);
        relTextosVista.aba = 'PECUARIA'; ir('reltextos', null, true); const pec = LINHAS(); const emPec = pec.some(l => l.un === un.id && l.nome === 'Café do Sul');
        un.nome = nomeAntes; ir('reltextos', null, true);
        return { emCafe, emPec, nPec: pec.length, id: un.id }; }, LINHAS.toString());
      ok('g. Nenhuma linha decide atividade por trecho do nome: pecuária rebatizada "Café do Sul" fica em 🐂 Pecuária, não em ☕ Café',
        !g.emCafe && g.emPec && g.nPec === 9, `${g.id} em Café: ${g.emCafe}; em Pecuária: ${g.emPec}; ${g.nPec} linhas de pecuária`);
      /* ☕ Café: 10 linhas na ordem da tela inicial */
      await page.click('[data-relaba="CAFE"]'); await page.waitForTimeout(250);
      const cafe = await page.evaluate(LINHAS_STR => { const LINHAS = eval(LINHAS_STR); return { linhas: LINHAS(), ordem: unidadesPermitidas().filter(f => atividadeDe(f.id) === 'CAFE').map(f => f.nome), telas: +(document.documentElement.scrollHeight / 844).toFixed(2), aba: relTextosVista.aba }; }, LINHAS.toString());
      ok('☕ Café — 10 linhas, uma por unidade, na ordem da tela inicial, nome + "robô-redator · dd/mm hh:mm", em até 2 telas',
        cafe.linhas.length === 10 && cafe.linhas.map(l => l.nome).join('|') === cafe.ordem.join('|') && cafe.linhas.every(l => /^robô-redator · \d\d\/\d\d \d\d:\d\d$/.test(l.estado) && l.botao && l.seta) && cafe.telas <= 2,
        `${cafe.linhas.length} linhas · ${cafe.telas} telas · "${cafe.linhas[0].estado}"`);
      /* d. tocar a 4ª linha abre a folha com o texto integral DAQUELA unidade */
      const antesY = await page.evaluate(() => { window.scrollTo(0, 180); return window.scrollY; });
      const alvo = await page.evaluate(() => { const b = document.querySelectorAll('#app [data-txtler]')[3]; const l = relCache.find(x => 'rel:' + x.id === b.dataset.txtler); b.click(); return { un: l.unidade_id, nome: relUni(l.unidade_id), texto: l.texto }; });
      await page.waitForTimeout(300);
      const folha = await page.evaluate(() => { const f = document.querySelector('#folha-texto'); return f ? { titulo: f.querySelector('h1').textContent, texto: f.querySelector('.txt-completo').textContent, tag: (f.querySelector('.tag') || {}).textContent || '', origem: (f.querySelector('.txt-origem') || {}).textContent || '', travado: document.body.classList.contains('folha-aberta'), copiar: (document.querySelector('#bt-folha-copiar') || {}).textContent || '' } : null; });
      const outros = await page.evaluate(un => relCache.filter(l => l.texto && l.unidade_id !== un).map(l => l.texto), alvo.un);
      ok('d. Tocar a linha abre a folha de leitura (v68) com o texto integral daquela unidade e de nenhuma outra',
        !!folha && folha.texto === alvo.texto && folha.titulo === '📝 ' + alvo.nome && !outros.some(t => folha.texto.includes(t.slice(0, 60))) && folha.travado && /revisar antes de enviar/.test(folha.tag) && /^Redigido no Supabase/.test(folha.origem) && /copiar para WhatsApp/.test(folha.copiar),
        folha ? `"${folha.titulo}" · ${folha.texto.length} caracteres · ${folha.texto === alvo.texto ? 'igual ao relCache' : 'DIFERENTE'}` : 'folha não abriu');
      /* a folha continua a mesma: copiar copia o texto integral (relCopiar) */
      const copiado = await page.evaluate(async un => { let cop = ''; navigator.clipboard.writeText = t => { cop = t; return Promise.resolve(); }; const z = window.open; window.open = () => null; document.getElementById('bt-folha-copiar').click(); await new Promise(r => setTimeout(r, 150)); window.open = z; return { cop, botao: document.getElementById('bt-folha-copiar').textContent }; }, alvo.un);
      ok('A folha não mudou: "copiar para WhatsApp" copia o texto integral e marca "✔ copiado"', copiado.cop === alvo.texto && /copiado/.test(copiado.botao), `${copiado.cop.length} caracteres · "${copiado.botao}"`);
      /* e. fechar → mesma aba, mesma rolagem */
      await page.click('#bt-folha-fechar'); await page.waitForTimeout(250);
      const depois = await page.evaluate(ABAS_STR => ({ y: window.scrollY, aba: relTextosVista.aba, tela: telaAtual, folha: !!document.querySelector('#folha-texto'), travado: document.body.classList.contains('folha-aberta'), abas: eval(ABAS_STR)() }), ABAS.toString());
      ok('e. Fechar a folha devolve a mesma aba (☕ Café) e a mesma rolagem', !depois.folha && !depois.travado && depois.tela === 'reltextos' && depois.aba === 'CAFE' && depois.abas.includes('☕ Café (10) *') && depois.y === antesY,
        `aba ${depois.aba} · antes ${antesY} px, depois ${depois.y} px`);
      /* c. unidade sem texto */
      const c = await page.evaluate(LINHAS_STR => { const LINHAS = eval(LINHAS_STR);
        const un = unidadesPermitidas().filter(f => atividadeDe(f.id) === 'CAFE')[2]; relCache = relCache.filter(l => l.unidade_id !== un.id); ir('reltextos', null, true);
        const l = LINHAS().find(x => x.un === un.id); const el = document.querySelector('#app .cad-item[data-rel-un="' + un.id + '"]');
        const nativos = window.__nativos, tela = telaAtual; if (el) el.click();
        return { nome: un.nome, linha: l, n: LINHAS().length, contador: (document.querySelector('[data-relaba="CAFE"]') || {}).textContent || '', cor: el ? getComputedStyle(el.querySelector('b')).color : '', mesmaTela: telaAtual === tela && !document.querySelector('#folha-texto') && window.__nativos === nativos }; }, LINHAS.toString());
      ok('c. Unidade do escopo sem texto → "sem texto neste período", em cinza, sem seta e sem ação; a aba conta 9',
        !!c.linha && c.linha.estado === 'sem texto neste período' && !c.linha.botao && !c.linha.seta && !c.linha.chave && c.n === 10 && /\(9\)/.test(c.contador) && c.mesmaTela,
        `${c.nome}: "${(c.linha || {}).estado}" · ${c.n} linhas · aba "${c.contador}" · toque ${c.mesmaTela ? 'não faz nada' : 'FEZ algo'}`);
      /* f. unidade_id fora do catálogo → 🏢 Grupo com o id visível */
      const f = await page.evaluate(([LINHAS_STR, ABAS_STR]) => { const LINHAS = eval(LINHAS_STR), ABAS = eval(ABAS_STR);
        relCache.push({ id: 'tx-x', relatorio: 'devolutiva_semanal', periodo_ini: relCache[0].periodo_ini, periodo_fim: relCache[0].periodo_fim, unidade_id: 'f99', texto: 'Texto de uma unidade que não existe no cadastro.', texto_em: relCache[0].texto_em, gerado_em: relCache[0].gerado_em, dados: {} });
        relTextosVista.aba = 'GRUPO'; ir('reltextos', null, true);
        return { abas: ABAS(), linhas: LINHAS(), largura: document.documentElement.scrollWidth }; }, [LINHAS.toString(), ABAS.toString()]);
      ok('f. unidade_id fora do catálogo cai em 🏢 Grupo com o id visível, sem quebrar a tela',
        /🏢 Grupo \(2\)/.test(f.abas[0]) && f.linhas.some(l => l.nome === 'f99' && l.botao) && f.linhas.length === 2 && f.largura <= 390,
        `${f.abas[0]} · linhas: ${f.linhas.map(l => l.nome).join(', ')}`);
      /* voltar sobe um degrau por vez; Números é o conteúdo de antes */
      await page.evaluate(() => { [...document.querySelectorAll('#app [data-voltar]')].pop().click(); }); await page.waitForTimeout(200);
      const v1 = await page.evaluate(() => telaAtual);
      await page.click('#bt-rel-numeros'); await page.waitForTimeout(250);
      const num = await page.evaluate(() => ({ tela: telaAtual, filtros: [...document.querySelectorAll('#app [data-relper]')].map(b => b.textContent.trim()).join('/'), itens: document.querySelectorAll('#app [data-relab]').length, texto: document.querySelector('#app').innerText }));
      await page.click('#app [data-relab] >> nth=0'); await page.waitForTimeout(250);
      const relat = await page.evaluate(() => ({ tela: telaAtual, nav: document.querySelectorAll('#app [data-relnav]').length, zap: !!document.querySelector('#bt-rel-zap'), pdf: !!document.querySelector('#bt-rel-pdf') }));
      await page.click('#app .topo [data-voltar]'); await page.waitForTimeout(200);
      const v2 = await page.evaluate(() => telaAtual);
      ok('Voltar sobe um degrau: Textos → menu; relatório aberto pela lista de Números → Números', v1 === 'relatorios' && v2 === 'relnumeros', `${v1} · ${v2}`);
      ok('Números — filtro Todos/Dia/Semana/Mês, lista com "para conferir", toque abre o relatório com anterior/próximo, Compartilhar e PDF',
        num.tela === 'relnumeros' && num.filtros === 'Todos/Dia/Semana/Mês' && num.itens === 1 && /para conferir/.test(num.texto) && relat.tela === 'relat' && relat.nav === 2 && relat.zap && relat.pdf,
        `${num.filtros} · ${num.itens} relatório · ${relat.nav} setas`);
      /* nada nativo, nenhum erro */
      const nat = await page.evaluate(() => window.__nativos);
      ok('Nenhum diálogo nativo e nenhum erro de JavaScript', nat === 0 && !erros.length, erros[0] || `${nat} nativo(s)`);
      await ctx.close();
    }
    /* ---- b: código de escopo só de pecuária → sem abas, 9 linhas ---- */
    {
      const { page, ctx, erros } = await novaPagina(browser, base, { codigo: 'PECU-5926', chave: 'ATV:PECUARIA' }, SESSAO);
      const b = await page.evaluate(([SEM, LINHAS_STR, ABAS_STR]) => { const LINHAS = eval(LINHAS_STR), ABAS = eval(ABAS_STR);
        /* hoje nenhum código de uma atividade só abre o painel; a prova dá painel ao escopo ATV:PECUARIA só nesta página */
        const orig = escopoDaChave; escopoDaChave = ch => { const e = orig(ch); if (e && ch === 'ATV:PECUARIA') e.painel = true; return e; };
        sessao = { userId: 'u2', papel: 'proprietario', nome: 'Diretoria' };   /* a sessão da Diretoria cai na abertura porque o código não tem painel */
        eval('(' + SEM + ')')();
        /* a trava de baixarRelatorios: unidade fora do escopo nunca fica no aparelho (e a linha do grupo só entra com escopo total) */
        relCache = relCache.filter(l => l.unidade_id && podeVer(l.unidade_id));
        ir('relatorios'); const menu = LINHAS(); ir('reltextos');
        return { menu: menu.map(l => l.estado), abas: ABAS(), linhas: LINHAS(), atvs: [...new Set(LINHAS().map(l => atividadeDe(l.un)))], escopo: unidadesPermitidas().length }; }, [SEMENTE.toString(), LINHAS.toString(), ABAS.toString()]);
      ok('b. Código de escopo só de pecuária → nenhuma aba, só a lista com as 9 unidades de pecuária (e nada de café ou grãos)',
        b.abas.length === 0 && b.linhas.length === 9 && b.atvs.join() === 'PECUARIA' && b.escopo === 9, `${b.abas.length} abas · ${b.linhas.length} linhas · ${b.atvs.join('/')} · menu: "${b.menu[0]}"`);
      ok('b. Nenhum erro de JavaScript com escopo de uma atividade', !erros.length, erros[0] || 'sem erro');
      await ctx.close();
    }
    /* ---- o gerente continua sem ver texto nenhum ---- */
    {
      const { page, ctx } = await novaPagina(browser, base, { codigo: 'VR-7061', chave: 'f23' }, { userId: 'u1', papel: 'gerente', nome: 'Gerente', atividade: 'CAFE', fazendaId: 'f23' });
      const ger = await page.evaluate(SEM => { eval('(' + SEM + ')')(); ir('casa'); const t = document.querySelector('#app').innerText;
        ir('reltextos'); const tela = telaAtual; return { casaTemTexto: /robô-redator|Textos para revisar|devolutiva da semana/i.test(t), tela }; }, SEMENTE.toString());
      ok('Gerente — a casa não mostra texto do robô-redator e a tela Textos para revisar não abre para ele', !ger.casaTemTexto && ger.tela !== 'reltextos', `tela ${ger.tela}`);
      await ctx.close();
    }
  } finally { await browser.close(); srv.close(); }

  const falhas = provas.filter(p => !p.ok);
  if (process.argv.includes('--json')) console.log(JSON.stringify({ provas, falhas: falhas.length }, null, 2));
  else {
    console.log('# Relatórios da Diretoria em três níveis (v99) — prova da validação da tarefa\n');
    provas.forEach(p => console.log(`- ${p.ok ? '✅' : '❌'} ${p.nome}${p.detalhe ? ' — ' + p.detalhe : ''}`));
    console.log(`\n## Resultado: ${provas.length - falhas.length} ✅ · ${falhas.length} ❌`);
  }
  process.exit(falhas.length ? 1 : 0);
})().catch(e => { console.error('FALHOU: ' + e.stack); process.exit(2); });
