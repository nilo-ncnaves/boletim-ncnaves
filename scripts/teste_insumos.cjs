#!/usr/bin/env node
/*
 teste_insumos.cjs — prova do MÓDULO DE INSUMOS (v86) do Boletim NCNaves.

 É a validação escrita na tarefa da v86 (programação de entrega, recebimento,
 saldo e consumo por unidade + a porta única "📥 Colar do WhatsApp") e roda SEM
 REDE, como um celular offline, a 390 px de largura. Serve de trava: sai com
 código 1 quando qualquer prova falha.

 O que prova, na ordem da tarefa (seções 10 e 11.7):
   1. Cola a mensagem REAL do nitrato e confere a leitura: produto, fornecedor,
      8 alocações casadas pelo de-para e o total de 486.000 kg (486 t).
   2. Conferência agronômica na pré-visualização (kg/ha por unidade).
   3. Grava a remessa; reimportar a MESMA mensagem não duplica nada.
   4. Gerente da Vereda: cartão de chegada no topo do boletim e "Chegou tudo"
      em UM toque — a tarefa que estava aguardando o produto é liberada sozinha.
   5. Mata Preta: chegada PARCIAL de 20 t mantém o cartão com o saldo a receber.
   6. Adubação de 400 kg/ha em 10 ha no boletim vira consumo de 4.000 kg, e o
      saldo (recebido − aplicado) cai sozinho — nada digitado duas vezes.
   7. Cobrança por fornecedor das entregas programadas e não registradas.
   8. Classificação da porta única: ata, remessa, tarefas avulsas e o texto que
      o app NÃO reconhece (pede o tipo em vez de adivinhar).
   9. Trilha de origem: a mensagem fica inteira em Mensagens importadas e a
      busca por "nitrato" a encontra.

 Uso (na raiz do repositório):
   node scripts/teste_insumos.cjs
   node scripts/teste_insumos.cjs --json    # imprime o resultado em JSON

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
const CODIGOS = { ADMIN: 'ADMIN-9561', f22c: 'VC-5883' };

/* mensagem REAL do grupo, exatamente como está na tarefa */
const MSG_NITRATO = [
  'Relação de NITRATO que a Cooxupé vai entregar nas fazendas:',
  '106.000 kg - VEREDA',
  '35.000 kg - CAFÉ 5°',
  '50.000 kg - ROMARIA',
  '85.000 kg - FAZ. MONTE CARMELO',
  '26.000 kg - ÁGUA LIMPA',
  '80.000 kg - LAGAMAR (GRUPO)',
  '60.000 kg - LAGAMAR (RODRIGO)',
  '44.000 kg - MATA PRETA'
].join('\n');

/* trecho real da ata (bloco 14 do módulo de planejamento) */
const MSG_ATA = [
  '2.1 – Vereda',
  '- Colheita varrição falta setor 4,5,8 e 9 + - 96 há – PRAZO: 20/09/26',
  '- Fazer KCL e ferti PRAZO: 25/09/26',
  '- Calcario (aguardando repasse) - PRAZO: 10/10/26',
  '2.12 – Lagamar (Grupo)',
  '- Kcl falta chegar para aplicar (Cobrar Cooxupé entrega) - PRAZO: 30/09/26',
  '- Desbrota café novo iniciar na segunda. - PRAZO: 05/10/26'
].join('\n');

const MSG_TAREFAS = 'Falta trocar a bomba do pivô 3; comprar mourão';
const MSG_SOLTA = 'Bom dia a todos! A reunião de amanhã foi remarcada para as 14h na sede.';
const MSG_CHUVA = ['Chuva de ontem:', 'Vereda 32 mm', 'Mata Preta 18 mm'].join('\n');

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
const lerD = page => page.evaluate(() => JSON.stringify(D));
const porD = (page, d) => page.evaluate(x => { D = JSON.parse(x); salvarDados(); }, d);

(async () => {
  const { srv, base } = await servir(RAIZ);
  const browser = await pw.chromium.launch();
  let estado = null;
  const errosTodos = [];

  /* ---------- escritório: colagem, leitura e gravação ---------- */
  {
    const { page, ctx, erros } = await novaPagina(browser, base, { codigo: CODIGOS.ADMIN, chave: 'ADMIN' }, '2026-09-11T09:00:00-03:00');

    /* 8. classificação da porta única (item 11.2 / 11.7) */
    const cls = await page.evaluate(([nit, ata, tar, solta, chuva]) => ({
      nitrato: insClassificar(nit), ata: insClassificar(ata), tarefas: insClassificar(tar),
      solta: insClassificar(solta), chuva: insClassificar(chuva)
    }), [MSG_NITRATO, MSG_ATA, MSG_TAREFAS, MSG_SOLTA, MSG_CHUVA]);
    ok('Porta única — a mensagem do nitrato é reconhecida como REMESSA DE INSUMO', cls.nitrato.tipo === 'remessa', cls.nitrato.tipo + ' · ' + cls.nitrato.motivo);
    ok('Porta única — o trecho da ata é reconhecido como ATA DE REUNIÃO', cls.ata.tipo === 'ata', cls.ata.tipo + ' · ' + cls.ata.motivo);
    ok('Porta única — a lista solta é reconhecida como TAREFAS AVULSAS', cls.tarefas.tipo === 'tarefas', cls.tarefas.tipo + ' · ' + cls.tarefas.motivo);
    ok('Porta única — o relato de chuva é reconhecido como RELATO DE CHUVA', cls.chuva.tipo === 'chuva', cls.chuva.tipo + ' · ' + cls.chuva.motivo);
    ok('Porta única — texto sem relação NÃO é adivinhado (o app pede o tipo)', cls.solta.tipo === '', '"' + cls.solta.tipo + '"');

    /* 1. leitura da remessa real */
    const prev = await page.evaluate(t => {
      const p = insLerRemessa(t);
      return { produto: p.produto, termo: p.produtoTermo, fornecedor: p.fornecedor,
        itens: p.itens.map(i => ({ nome: i.nomeMsg, kg: i.kg, unidade: i.unidade })),
        total: p.itens.reduce((s, i) => s + i.kg, 0), fora: p.fora, soltas: p.soltas };
    }, MSG_NITRATO);
    ok('Remessa — produto lido ("NITRATO" → Nitrato de amônio)', /nitrato/i.test(prev.produto), prev.produto + ' (de "' + prev.termo + '")');
    ok('Remessa — fornecedor lido: Cooxupé', /cooxup/i.test(prev.fornecedor), prev.fornecedor);
    ok('Remessa — 8 alocações lidas', prev.itens.length === 8, prev.itens.length + ' linha(s)');
    ok('Remessa — total de 486.000 kg (486 t)', prev.total === 486000, prev.total + ' kg');
    ok('Remessa — todas as 8 unidades casadas pelo de-para (nenhuma adivinhada)',
      prev.itens.every(i => !!i.unidade), prev.itens.map(i => i.nome + '→' + (i.unidade || '—')).join(' · '));
    const esperado = { VEREDA: 'f22c', 'CAFÉ 5°': 'f24', ROMARIA: 'f23', 'FAZ. MONTE CARMELO': 'f14c',
      'ÁGUA LIMPA': 'f01', 'LAGAMAR (GRUPO)': 'f03c', 'LAGAMAR (RODRIGO)': 'f20', 'MATA PRETA': 'f13c' };
    const erradas = prev.itens.filter(i => esperado[i.nome] !== i.unidade);
    ok('Remessa — cada nome foi para a unidade certa do cadastro', erradas.length === 0,
      erradas.map(i => i.nome + '→' + i.unidade).join(' · ') || 'todas certas');
    ok('Remessa — 106.000 kg na Vereda e 44.000 kg na Mata Preta',
      prev.itens.find(i => i.unidade === 'f22c').kg === 106000 && prev.itens.find(i => i.unidade === 'f13c').kg === 44000,
      prev.itens.map(i => i.kg).join(' · '));

    /* formatos alternativos aceitos pela tarefa */
    const alt = await page.evaluate(() => ['106.000kg – VEREDA', '106 t - VEREDA', 'VEREDA - 106.000 kg', '1.234,5 kg - VEREDA']
      .map(l => { const x = insLerAlocacao(l); return x ? x.kg + '|' + x.unidade : 'null'; }));
    ok('Remessa — aceita "106.000kg – VEREDA", "106 t - VEREDA", "VEREDA - 106.000 kg" e decimal com vírgula',
      alt[0] === '106000|f22c' && alt[1] === '106000|f22c' && alt[2] === '106000|f22c' && alt[3] === '1234.5|f22c', alt.join(' · '));

    /* 2. conferência agronômica na pré-visualização */
    const conf = await page.evaluate(() => { const c = insConferencia('f22c', 106000, 'Nitrato de amônio');
      return c ? { kgHa: Math.round(c.kgHa), area: c.area, txt: insKgHaTxt(c) } : null; });
    ok('Conferência agronômica — kg/ha calculado na pré-visualização', conf && conf.kgHa > 0,
      conf ? conf.txt : 'sem área cadastrada na unidade');

    /* 3. gravação e idempotência */
    const grav = await page.evaluate(t => {
      insUI.texto = t; insUI.auto = insClassificar(t); insUI.tipo = insUI.auto.tipo; insAbrirPrev();
      insImportar();
      return { remessas: insRemessas().length, aloc: (insRemessas()[0] || {}).alocacoes.length, msgs: insMensagens().length };
    }, MSG_NITRATO);
    ok('Remessa gravada com as 8 alocações', grav.remessas === 1 && grav.aloc === 8, grav.remessas + ' remessa(s) · ' + grav.aloc + ' alocações');
    const dupl = await page.evaluate(t => {
      insUI.texto = t; insUI.tipo = 'remessa'; insAbrirPrev(); insImportar();
      return { remessas: insRemessas().length, msgs: insMensagens().length };
    }, MSG_NITRATO);
    ok('Reimportar a MESMA mensagem não duplica a remessa', dupl.remessas === 1, dupl.remessas + ' remessa(s)');
    ok('Reimportar a MESMA mensagem não duplica a trilha de origem', dupl.msgs === 1, dupl.msgs + ' mensagem(ns)');

    /* produto entrou no catálogo, com categoria e fornecedor */
    const prod = await page.evaluate(() => { const p = insProduto('Nitrato de amônio');
      return p ? { nome: p.nome, cat: p.categoria, forn: p.fornecedor, un: p.un } : null; });
    ok('Produto entrou no catálogo com categoria e fornecedor', prod && prod.cat === 'fertilizante' && /cooxup/i.test(prod.forn || ''),
      prod ? [prod.nome, prod.cat, prod.forn, prod.un].join(' · ') : 'não criado');

    /* 9. trilha de origem e busca */
    const busca = await page.evaluate(() => {
      insNav = [{ v: 'colar' }, { v: 'mensagens' }]; insUI.busca = 'nitrato'; ir('colar');
      const achou = [...document.querySelectorAll('#app [data-ins-msg]')].length;
      insUI.busca = 'calcário que não existe'; ir('colar');
      const vazio = document.querySelector('#app p.mut.centro') ? document.querySelector('#app p.mut.centro').textContent : '';
      insUI.busca = '';
      return { achou, vazio };
    });
    ok('Mensagens importadas — a busca por "nitrato" encontra a mensagem', busca.achou === 1, busca.achou + ' resultado(s)');
    ok('Mensagens importadas — vazio pela função única, nomeando o filtro',
      /^Sem mensagem importada/.test(busca.vazio) && !/não fez|pendente|atrasad/i.test(busca.vazio), busca.vazio.slice(0, 90));

    /* importa a ata (para o teste do desbloqueio) e trava a tarefa do KCl citando o fornecedor */
    await page.evaluate(txt => {
      planNav = [{ v: 'menu' }, { v: 'importar' }];
      planUI.rodadaNome = 'Reunião 10/09/26'; planUI.ata = ataParsear(txt); planAtaGravar();
      const t = planTarefas().find(x => x.unidade === 'f22c' && /KCL/i.test(x.desc));
      planMudarStatus(t.id, 'aguardando_terceiro', { quem: 'Cooxupé', motivo: 'insumo', texto: 'aguardando a entrega do nitrato' });
    }, MSG_ATA);
    const travadas = await page.evaluate(() => planTarefas().filter(t => t.status === 'aguardando_terceiro').map(t => t.unidade + ': ' + t.desc.slice(0, 30)));
    ok('Cenário — tarefas aguardando terceiro antes da chegada', travadas.length >= 2, travadas.join(' · '));

    /* 7. cobrança do fornecedor (anúncio de 10 dias atrás) */
    const cob = await page.evaluate(() => {
      insRemessas()[0].data = '2026-09-01';
      const g = insACobrar();
      return { grupos: g.length, quem: (g[0] || {}).quem, dias: (g[0] || {}).dias, unidades: (g[0] || {}).itens.length,
        paradas: (g[0] || {}).itens.reduce((s, i) => s + i.paradas.length, 0), texto: insTextoCobranca((g[0] || {}).quem) };
    });
    ok('Cobrança — a Cooxupé aparece com as entregas não registradas', cob.grupos === 1 && /cooxup/i.test(cob.quem || ''),
      cob.quem + ' · ' + cob.unidades + ' unidades · ' + cob.dias + ' dias');
    ok('Cobrança — o texto pronto diz quais fazendas estão paradas por causa disso',
      /Cooxup/.test(cob.texto) && /parada aguardando/.test(cob.texto) && cob.paradas >= 1, cob.paradas + ' tarefa(s) citada(s)');
    ok('Cobrança — o texto não cobra o campo ("não fez", "pendente", "atrasado")',
      !/não fez|não realizou|pendente|atrasad|faltou|esqueceu/i.test(cob.texto), cob.texto.split('\n')[0]);

    estado = await lerD(page);
    errosTodos.push(...erros);
    await ctx.close();
  }

  /* ---------- gerente da Vereda: chegada em um toque, consumo e saldo ---------- */
  {
    const { page, ctx, erros } = await novaPagina(browser, base, { codigo: CODIGOS.f22c, chave: 'f22c' },
      '2026-09-11T09:00:00-03:00', { userId: 'u1', papel: 'gerente', nome: 'Gerente — Vereda — Café', atividade: 'CAFE', fazendaId: 'f22c' });
    await porD(page, estado);
    await page.evaluate(() => { rascunho = null; ir('casa'); });
    await page.waitForTimeout(300);

    /* 4. cartão de chegada no topo do boletim */
    const cartao = await page.evaluate(() => {
      rascunho = novoRascunho(); ir('form');
      const c = document.querySelector('#app [data-ins-cartao]');
      const secoes = [...document.querySelectorAll('#app details.secao')].filter(d => d.open).length;
      return c ? { texto: c.textContent.replace(/\s+/g, ' ').trim().slice(0, 150),
        botoes: [...c.querySelectorAll('[data-ins-rec]')].map(b => b.textContent.trim()),
        alvo: Math.min(...[...c.querySelectorAll('[data-ins-rec]')].map(b => Math.round(b.getBoundingClientRect().height))),
        abertas: secoes } : null;
    });
    ok('Boletim — o cartão de chegada aparece no topo, com os três botões', cartao && cartao.botoes.length === 3, cartao ? cartao.botoes.join(' · ') : 'sem cartão');
    ok('Boletim — o cartão diz o produto, a quantidade e o fornecedor', cartao && /Nitrato/.test(cartao.texto) && /106/.test(cartao.texto) && /Cooxup/.test(cartao.texto), cartao && cartao.texto);
    ok('Boletim — alvo de toque dos botões ≥ 44 px', cartao && cartao.alvo >= 44, cartao && cartao.alvo + ' px');
    ok('Boletim — nenhuma seção nasce aberta por causa do módulo', cartao && cartao.abertas === 0, cartao && cartao.abertas + ' seção(ões) aberta(s)');

    /* UM toque: "Chegou tudo" */
    const chegou = await page.evaluate(() => {
      document.querySelector('#app [data-ins-rec$="|tudo"]').click();
      return new Promise(r => setTimeout(() => {
        const rec = insRecebimentos().filter(x => x.unidade === 'f22c');
        const lib = planTarefas().filter(t => t.unidade === 'f22c' && /KCL/i.test(t.desc)).map(t => t.status);
        const aviso = document.querySelector('#app #ins-liberadas');
        const nota = document.querySelector('#app #ins-nota-campo');
        const hist = planHist().filter(h => /chegou/i.test(h.motivo || '')).length;
        r({ n: rec.length, kg: rec.reduce((s, x) => s + x.kg, 0), lib, aviso: aviso ? aviso.textContent.replace(/\s+/g, ' ').trim() : '',
          temNota: !!nota, hist });
      }, 250));
    });
    ok('Chegada em UM toque: 106.000 kg registrados sem digitar nada', chegou.n === 1 && chegou.kg === 106000, chegou.kg + ' kg em ' + chegou.n + ' registro');
    ok('Desbloqueio automático — a tarefa que aguardava o nitrato voltou para A INICIAR', chegou.lib.join('') === 'a_iniciar', chegou.lib.join(' · '));
    ok('Desbloqueio — o gerente é avisado do que foi liberado', /liberada/.test(chegou.aviso) && /KCL/i.test(chegou.aviso), chegou.aviso.slice(0, 110));
    ok('Desbloqueio — fica registrado no histórico da tarefa', chegou.hist >= 1, chegou.hist + ' linha(s) de histórico');
    ok('Nº da nota é pedido depois, e é pulável', chegou.temNota, chegou.temNota ? 'campo opcional oferecido' : 'não apareceu');

    /* o cartão sai da tela quando não há mais chegada pendente */
    const sumiu = await page.evaluate(() => {
      insUI.nota = ''; ir('form');
      return { cartoes: document.querySelectorAll('#app [data-ins-cartao]').length, pend: insPendentesDa('f22c').length };
    });
    ok('Cartão some sozinho quando não há mais chegada pendente', sumiu.cartoes === 0 && sumiu.pend === 0, sumiu.cartoes + ' cartão(ões)');

    /* 6. consumo a partir do lançamento do boletim */
    const cons = await page.evaluate(() => {
      const tal = talhoesDa('f22c').filter(t => t.tipo !== 'ESTRUTURA' && t.tipo !== 'ARRENDADO')[0];
      rascunho.clima = { cond: 'Ensolarado', chuvaMm: '', obs: '' };
      rascunho.responsavel = 'João';
      rascunho.atividades = [{ id: uid(), talhaoId: tal.id, tipo: 'Adubação via lanço', pessoas: '4',
        insProduto: 'Nitrato de amônio', insDoseKgHa: '400', insAreaHa: '10', insumos: [], maquinas: [] }];
      concluirEnvio();
      return new Promise(r => {
        /* a folha "📋 Amanhã" (v75) abre antes de gravar: o envio segue com um toque em "Pular" */
        setTimeout(() => { const b = document.getElementById('bt-plano-pular'); if (b) b.click(); }, 250);
        setTimeout(() => {
          const l = insSaldos('f22c').find(x => /nitrato/i.test(x.nome));
          r({ recebido: l.recebido, aplicado: l.aplicado, saldo: l.saldo, n: insConsumos('f22c').length,
            boletins: (D.boletins || []).filter(x => x.fazendaId === 'f22c' && !x.exemplo).length });
        }, 900);
      });
    });
    ok('Consumo — adubação de 400 kg/ha em 10 ha vira 4.000 kg aplicados', cons.aplicado === 4000, cons.aplicado + ' kg em ' + cons.n + ' lançamento(s) · ' + cons.boletins + ' boletim enviado');
    ok('Saldo é CALCULADO: 106.000 recebidos − 4.000 aplicados = 102.000 kg', cons.saldo === 102000 && cons.recebido === 106000,
      cons.recebido + ' − ' + cons.aplicado + ' = ' + cons.saldo);

    /* a seção do saldo no boletim */
    const secao = await page.evaluate(() => {
      rascunho = novoRascunho(); ir('form');
      const s = [...document.querySelectorAll('#app details.secao')].find(d => /Insumos na fazenda/.test(d.textContent));
      if (!s) return null;
      const aberta = s.open;
      s.querySelector('summary').click();
      const txt = s.textContent.replace(/\s+/g, ' ');
      const bt = s.querySelector('[data-ins-cons]');
      return { aberta, txt: txt.slice(0, 220), temBotao: !!bt, proibido: /não fez|não realizou|pendente|atrasad|faltou|esqueceu/i.test(txt) };
    });
    ok('Boletim — seção "Insumos na fazenda" nasce FECHADA', secao && secao.aberta === false, secao ? 'aberta=' + secao.aberta : 'seção não encontrada');
    ok('Boletim — a seção mostra recebido, aplicado e saldo', secao && /recebido/i.test(secao.txt) && /aplicado/i.test(secao.txt) && /saldo/i.test(secao.txt), secao && secao.txt.slice(0, 120));
    ok('Boletim — tocar no aplicado abre os lançamentos que o compuseram', secao && secao.temBotao, secao && (secao.temBotao ? 'rastreável' : 'sem rastreio'));
    ok('Boletim — a seção não usa termo de cobrança', secao && !secao.proibido, secao && (secao.proibido ? 'termo proibido encontrado' : 'vocabulário ok'));

    estado = await lerD(page);
    errosTodos.push(...erros);
    await ctx.close();
  }

  /* ---------- Mata Preta: chegada PARCIAL ---------- */
  {
    const { page, ctx, erros } = await novaPagina(browser, base, { codigo: CODIGOS.ADMIN, chave: 'ADMIN' }, '2026-09-11T09:00:00-03:00');
    await porD(page, estado);
    const parcial = await page.evaluate(() => {
      const r = insRemessas()[0];
      insReceber(r.id, 'f13c', 20000);
      const l = insSaldos('f13c').find(x => /nitrato/i.test(x.nome));
      return { recebido: l.recebido, aReceber: l.aReceber, pend: insPendentesDa('f13c').length, falta: insAReceber(r, 'f13c') };
    });
    ok('Parcial — 20 t registrados na Mata Preta', parcial.recebido === 20000, parcial.recebido + ' kg');
    ok('Parcial — o cartão continua com o saldo a receber (24 t)', parcial.pend === 1 && parcial.falta === 24000, parcial.falta + ' kg a receber');

    /* divergências e saldo negativo */
    const div = await page.evaluate(() => {
      const r = insRemessas()[0], antes = r.data;
      r.data = hojeBRT();
      const nova = insDivergencias().filter(x => x.tipo === 'quantidade' && x.unidade === 'f13c').length;
      r.data = antes;
      const velha = insDivergencias().filter(x => x.tipo === 'quantidade' && x.unidade === 'f13c');
      return { nova, velha: velha.length, texto: (velha[0] || {}).texto || '' };
    });
    ok('Divergências — entrega parcial recém-anunciada não vira divergência (ainda é entrega em andamento)',
      div.nova === 0, div.nova + ' divergência(s) de quantidade');
    ok('Divergências — passados 7 dias, a falta é relatada ao escritório', div.velha === 1, div.texto);

    /* painel da Diretoria */
    const painel = await page.evaluate(() => {
      sessao = { userId: 'u2', papel: 'proprietario', nome: 'Diretoria' };
      ritualPuladoSessao = true;   /* 11/09/2026 é sexta: o ritual da semana abriria no lugar do painel */
      ir('painel');
      const s = [...document.querySelectorAll('#app details.secao')].find(d => /Insumos/.test(d.querySelector('summary').textContent));
      if (!s) return null;
      const nasceAberto = s.open;
      s.querySelector('summary').click();
      const txt = s.textContent.replace(/\s+/g, ' ');
      return { nasceAberto, cobranca: /A cobrar do fornecedor/.test(txt), chips: s.querySelectorAll('[data-ins-prod]').length,
        proibido: /não fez|não realizou|faltou|esqueceu/i.test(txt), txt: txt.slice(0, 200) };
    });
    ok('Painel — o cartão "Insumos" nasce recolhido (P5)', painel && painel.nasceAberto === false, painel ? 'aberto=' + painel.nasceAberto : 'cartão não encontrado');
    ok('Painel — traz programado, recebido, aplicado e saldo por unidade',
      painel && /programado/.test(painel.txt) && /recebido/.test(painel.txt) && /aplicado/.test(painel.txt) && /saldo/.test(painel.txt), painel && painel.txt.slice(0, 120));
    ok('Painel — traz a cobrança por fornecedor', painel && painel.cobranca, painel && (painel.cobranca ? 'bloco presente' : 'sem bloco'));
    ok('Painel — sem termo de cobrança ao campo', painel && !painel.proibido, painel && (painel.proibido ? 'termo proibido' : 'vocabulário ok'));

    errosTodos.push(...erros);
    await ctx.close();
  }

  /* ---------- tarefas avulsas e relato de chuva pela porta única ---------- */
  {
    const { page, ctx, erros } = await novaPagina(browser, base, { codigo: CODIGOS.ADMIN, chave: 'ADMIN' }, '2026-09-11T09:00:00-03:00');
    const tar = await page.evaluate(t => {
      insUI.texto = t; insUI.auto = insClassificar(t); insUI.tipo = insUI.auto.tipo; insAbrirPrev();
      const semUn = insUI.prev.itens.filter(i => !i.unidade).length;
      const falta = (function () { insRender(); const b = document.getElementById('bt-ins-importar'); return b ? b.getAttribute('data-falta') || '' : 'sem botão'; })();
      insUI.prev.itens.forEach(i => { i.unidade = 'f22c'; });
      insImportar();
      const novas = planTarefas().filter(x => x.unidade === 'f22c').length;
      insUI.texto = t; insUI.tipo = 'tarefas'; insAbrirPrev(); insUI.prev.itens.forEach(i => { i.unidade = 'f22c'; }); insImportar();
      return { semUn, falta, novas, depois: planTarefas().filter(x => x.unidade === 'f22c').length };
    }, MSG_TAREFAS);
    ok('Tarefas avulsas — as duas linhas pedem a unidade antes de gravar', tar.semUn === 2 && /unidade/i.test(tar.falta), tar.semUn + ' sem unidade · botão: "' + tar.falta + '"');
    ok('Tarefas avulsas — gravadas na unidade escolhida', tar.novas === 2, tar.novas + ' tarefa(s)');
    ok('Tarefas avulsas — reimportar a mesma lista não duplica', tar.depois === tar.novas, tar.novas + ' → ' + tar.depois);

    const chuva = await page.evaluate(t => {
      insUI.texto = t; insUI.auto = insClassificar(t); insUI.tipo = insUI.auto.tipo; insAbrirPrev();
      const itens = insUI.prev.itens.map(i => i.nomeMsg + '→' + (i.unidade || '—') + ':' + i.mm);
      insImportar();
      const b = (D.boletins || []).filter(x => x.fazendaId === 'f22c' && x.data === hojeBRT()).length;
      return { itens, sug: insChuvaSugerida('f22c', hojeBRT()), boletins: b };
    }, MSG_CHUVA);
    ok('Relato de chuva — lê os milímetros por fazenda', chuva.itens.length === 2, chuva.itens.join(' · '));
    ok('Relato de chuva — vira SUGESTÃO, nunca grava no boletim de ninguém',
      chuva.sug && chuva.sug.mm === 32 && chuva.boletins === 0, (chuva.sug ? chuva.sug.mm + ' mm sugeridos' : 'sem sugestão') + ' · ' + chuva.boletins + ' boletim gravado');

    errosTodos.push(...erros);
    await ctx.close();
  }

  await browser.close(); srv.close();

  ok('Nenhum erro de JavaScript em nenhum cenário', errosTodos.length === 0, errosTodos.slice(0, 3).join(' | '));

  const falhas = provas.filter(p => !p.ok).length;
  if (process.argv.includes('--json')) console.log(JSON.stringify({ provas, falhas }, null, 2));
  else {
    console.log('\n# Módulo de insumos (v86) — provas da tarefa\n');
    provas.forEach(p => console.log((p.ok ? '- ✅ ' : '- ❌ ') + p.nome + (p.detalhe ? ' — ' + p.detalhe : '')));
    console.log('\n## Resultado: ' + (provas.length - falhas) + ' ✅ · ' + falhas + ' ❌');
  }
  process.exit(falhas ? 1 : 0);
})().catch(e => { console.error(e); process.exit(1); });
