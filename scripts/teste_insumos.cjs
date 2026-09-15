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
/* v93: mensagem REAL do grupo de aplicações (15/09/2026) — "Caxico arrendo" é o talhão
   "José Eustáquio — Arrendamento" de Monte Carmelo — Café (confirmado pelo Nilo) */
const MSG_APLIC = ['Aplicação de Quatermon Caxico arrendo', '', '2lts Quatermon', 'Dose/ 400lts , vazão 100lts / hectares',
  'Gastou 5 arbus', '', 'Obs: daqui a 15 dias vamos repetir a aplicação'].join('\n');

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
    /* v92: o toque em "Ler a mensagem" com texto que o app NÃO reconhece abre a tela que pergunta o tipo —
       até a v91 a tela voltava para o campo de colar sem dizer nada, como se o toque não tivesse acontecido. */
    const naoRec = await page.evaluate(async msg => {
      abrirModulo('colar', () => { insLimpar(); insNav = [{ v: 'colar' }]; });
      await new Promise(r => setTimeout(r, 150));
      const ta = document.getElementById('ins-texto'); ta.value = msg; ta.dispatchEvent(new Event('input', { bubbles: true }));
      await new Promise(r => setTimeout(r, 50));
      document.getElementById('bt-ins-ler').click();
      await new Promise(r => setTimeout(r, 150));
      const h1 = (document.querySelector('#app .topo h1') || {}).textContent || '';
      const aviso = (document.querySelector('#app .aviso') || {}).textContent || '';
      const chips = [...document.querySelectorAll('#app [data-ins-tipo]')].length;
      const imp = document.getElementById('bt-ins-importar');
      const chip = document.querySelector('#app [data-ins-tipo="tarefas"]'); if (chip) chip.click();
      await new Promise(r => setTimeout(r, 150));
      const depoisTipo = insUI.tipo + '|' + (insUI.prev ? insUI.prev.itens.length : -1);
      const limpar = document.getElementById('bt-ins-limpar'); if (limpar) limpar.click();
      await new Promise(r => setTimeout(r, 150));
      const voltou = !!document.getElementById('ins-texto') && !insUI.lida;
      return { h1: h1.replace(/\s+/g, ' ').trim(), aviso: aviso.replace(/\s+/g, ' ').trim(), chips,
        impFalta: imp ? imp.getAttribute('data-falta') || '' : '', depoisTipo, voltou };
    }, MSG_SOLTA);
    ok('Porta única — "Ler a mensagem" com texto não reconhecido ABRE a tela que pergunta o tipo (nunca fica muda)',
      /Conferir a mensagem/.test(naoRec.h1) && /não reconheceu/.test(naoRec.aviso) && naoRec.chips === 5,
      naoRec.h1 + ' · ' + naoRec.chips + ' chip(s) · ' + naoRec.aviso.slice(0, 60));
    ok('Porta única — sem tipo escolhido o Importar fica inativo dizendo a próxima ação', /Escolha o tipo/.test(naoRec.impFalta), naoRec.impFalta);
    ok('Porta única — escolher o tipo por chip abre a pré-visualização; Descartar devolve ao campo de colar',
      /^tarefas\|\d+$/.test(naoRec.depoisTipo) && naoRec.voltou, naoRec.depoisTipo + ' · voltou: ' + naoRec.voltou);

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

  /* ---------- v93: relato de aplicação — escritório cola, gerente confirma com um toque ---------- */
  let estadoAplic = null;
  {
    const { page, ctx, erros } = await novaPagina(browser, base, { codigo: CODIGOS.ADMIN, chave: 'ADMIN' }, '2026-09-15T09:00:00-03:00');
    const lido = await page.evaluate(t => {
      const cls = insClassificar(t);
      const p = insLerAplicacao(t), it = p.itens[0];
      return { cls: cls.tipo + ' · ' + cls.motivo, produto: p.produto, termo: p.produtoTermo, local: it.nomeMsg, unidade: it.unidade, talhao: it.talhaoId,
        talhaoNome: it.talhaoId ? talhao(it.talhaoId).nome : '', ltanque: p.ltanque, vazao: p.vazao, tanques: p.tanques, receita: p.receita, obs: p.obs,
        area: insAplicAreaCalc(p), operacao: p.operacao, data: p.data };
    }, MSG_APLIC);
    ok('Relato de aplicação — a mensagem real do grupo é reconhecida como RELATO DE APLICAÇÃO', /^aplicacao/.test(lido.cls), lido.cls);
    ok('Relato de aplicação — produto lido da linha de calda ("2lts Quatermon" → Quatermon)', lido.produto === 'Quatermon', lido.produto + ' (de "' + lido.termo + '")');
    ok('Relato de aplicação — "Caxico arrendo" vai para Monte Carmelo — Café, talhão José Eustáquio — Arrendamento (por id, pelo de-para)',
      lido.unidade === 'f14c' && lido.talhao === 't055', lido.local + ' → ' + lido.unidade + ' / ' + lido.talhao + ' (' + lido.talhaoNome + ')');
    ok('Relato de aplicação — 400 L por tanque, vazão 100 L/ha, 5 tanques gastos; calda e observação como vieram',
      lido.ltanque === '400' && lido.vazao === '100' && lido.tanques === '5' && lido.receita === '2lts Quatermon' && /15 dias/.test(lido.obs),
      [lido.ltanque, lido.vazao, lido.tanques, JSON.stringify(lido.receita), lido.obs].join(' · '));
    ok('Relato de aplicação — área coberta calculada só para conferir (5 × 400 ÷ 100 = 20 ha)', lido.area === 20, lido.area + ' ha');
    ok('Relato de aplicação — a atividade do boletim NÃO é adivinhada pelo nome do produto (nasce vazia)', lido.operacao === '', '"' + lido.operacao + '"');

    const prev = await page.evaluate(t => {
      abrirModulo('colar', () => { insLimpar(); insNav = [{ v: 'colar' }]; });
      insUI.texto = t; insUI.auto = insClassificar(t); insUI.tipo = insUI.auto.tipo; insUI.lida = true; insAbrirPrev(); insRender();
      const bt = document.getElementById('bt-ins-importar');
      const faltaAntes = bt ? bt.getAttribute('data-falta') || '' : 'sem botão';
      const selOp = document.querySelector('#app select[data-insprev="-|operacao"]');
      const selTal = document.querySelector('#app select[data-insprev="0|talhaoId"]');
      const grupos = selOp ? [...selOp.querySelectorAll('optgroup')].map(g => g.label) : [];
      selOp.value = 'Pulverização mecanizada'; selOp.dispatchEvent(new Event('input', { bubbles: true })); selOp.dispatchEvent(new Event('change', { bubbles: true }));
      const faltaDepois = document.getElementById('bt-ins-importar').getAttribute('data-falta') || '';
      return { faltaAntes, faltaDepois, grupos, talSel: selTal ? selTal.value : 'sem select', rotulo: bt ? bt.textContent.trim() : '',
        nativos: window.__nativos || 0, texto: document.querySelector('#app').textContent.replace(/\s+/g, ' ') };
    }, MSG_APLIC);
    ok('Pré-visualização — pede a atividade do boletim antes de levar ao gerente (botão inativo diz o que falta)',
      /Escolha a atividade/.test(prev.faltaAntes) && prev.faltaDepois === '' && prev.rotulo === 'Levar ao boletim',
      '"' + prev.faltaAntes + '" → "' + prev.faltaDepois + '" · ' + prev.rotulo);
    ok('Pré-visualização — a lista de atividades é o catálogo do café por natureza; o talhão já vem escolhido pelo de-para',
      prev.grupos.length >= 4 && prev.talSel === 't055', prev.grupos.join(' · ') + ' · talhão ' + prev.talSel);
    ok('Pré-visualização — sem termo de cobrança e sem nativo', !/não fez|não realizou|faltou|esqueceu|pendente/i.test(prev.texto) && prev.nativos === 0, prev.nativos + ' nativo(s)');

    const grav = await page.evaluate(() => {
      insImportar();
      const rel = insAplicacoesRelatadas();
      const antes = rel.length;
      insUI.texto = insUI.texto; insUI.tipo = 'aplicacao'; insAbrirPrev(); insUI.prev.operacao = 'Pulverização mecanizada'; insImportar();
      return { antes, depois: insAplicacoesRelatadas().length, rel: rel[0], aprendida: insOperacaoAprendida('Quatermon', 'CAFE'),
        boletins: (D.boletins || []).filter(x => x.fazendaId === 'f14c' && !x.exemplo).length, status: rel[0] ? insRelatoStatus(rel[0]) : '', flash: insUI.flash };
    });
    ok('Levar ao boletim — o relato fica guardado com produto, talhão, atividade, calda e dia; nenhum boletim é gravado',
      grav.antes === 1 && grav.rel && grav.rel.unidade === 'f14c' && grav.rel.talhaoId === 't055' && grav.rel.operacao === 'Pulverização mecanizada' && grav.boletins === 0,
      grav.rel ? [grav.rel.produto, grav.rel.talhaoId, grav.rel.operacao, grav.rel.data].join(' · ') + ' · ' + grav.boletins + ' boletim' : 'nada guardado');
    ok('Levar ao boletim — reimportar a MESMA mensagem não duplica a sugestão', grav.depois === 1, grav.antes + ' → ' + grav.depois + ' · ' + grav.flash);
    ok('Levar ao boletim — o app lembra a atividade escolhida para este produto (próxima colagem já vem sugerida)', grav.aprendida === 'Pulverização mecanizada', grav.aprendida);
    ok('Mensagens importadas — a situação relata REGISTRO: "aguardando o boletim de …"', /^aguardando o boletim/.test(grav.status), grav.status);
    estadoAplic = await lerD(page);
    errosTodos.push(...erros);
    await ctx.close();
  }
  {
    const { page, ctx, erros } = await novaPagina(browser, base, { codigo: 'CC-6081', chave: 'f14c' },
      '2026-09-15T10:00:00-03:00', { userId: 'u1', papel: 'gerente', nome: 'Gerente — Monte Carmelo — Café', atividade: 'CAFE', fazendaId: 'f14c' });
    await porD(page, estadoAplic);
    await page.evaluate(() => { rascunho = null; ir('casa'); });
    await page.waitForTimeout(300);
    const cartao = await page.evaluate(() => {
      rascunho = novoRascunho(); ir('form');
      const c = document.querySelector('#app [data-ins-relato]');
      const bt = c ? c.querySelector('[data-ins-aplic$="|lancar"]') : null;
      return { existe: !!c, texto: c ? c.textContent.replace(/\s+/g, ' ').trim().slice(0, 220) : '',
        botoes: c ? [...c.querySelectorAll('[data-ins-aplic]')].map(b => b.textContent.trim()) : [],
        alvo: bt ? +bt.getBoundingClientRect().height.toFixed(1) : 0, ativ: rascunho.atividades.length };
    });
    ok('Boletim do gerente — a aplicação relatada aparece no topo como PERGUNTA ("foi assim?"), com duas respostas',
      cartao.existe && cartao.botoes.length === 2 && /foi assim\?/.test(cartao.texto) && cartao.ativ === 0, cartao.botoes.join(' · ') + ' · ' + cartao.texto.slice(0, 120));
    ok('Boletim do gerente — a pergunta traz talhão, calda, tanques e observação da mensagem',
      /José Eustáquio — Arrendamento/.test(cartao.texto) && /2lts Quatermon/.test(cartao.texto) && /5 tanques × 400 L/.test(cartao.texto) && /15 dias/.test(cartao.texto), cartao.texto.slice(0, 200));
    ok('Boletim do gerente — alvo de toque ≥ 44 px e sem termo de cobrança', cartao.alvo >= 44 && !/não fez|pendente|atrasad|faltou|esqueceu/i.test(cartao.texto), 'alvo ' + cartao.alvo + ' px');

    const lanc = await page.evaluate(async () => {
      window.__nativos = 0;
      document.querySelector('#app [data-ins-aplic$="|lancar"]').click();
      await new Promise(r => setTimeout(r, 250));
      const a = rascunho.atividades[0] || {};
      const card = document.querySelector('#app [data-ativ="' + a.id + '"]');
      const sel = card ? card.querySelector('select[data-a="talhaoId"]') : null;
      const rec = card ? card.querySelector('textarea[data-a="receita"]') : null;
      return { n: rascunho.atividades.length, tipo: a.tipo, talhao: a.talhaoId, receita: a.receita, tanques: a.tanques, ltanque: a.ltanque, obs: a.obs, relato: a.relatoId,
        cartaoSumiu: !document.querySelector('#app [data-ins-relato]'), tela: telaAtual, nativos: window.__nativos || 0,
        cardTal: sel ? sel.value : '', cardRec: rec ? rec.value : '', resp: JSON.stringify(rascunho.relatos), trocar: !!(card && card.querySelector('[data-troca-op]')) };
    });
    ok('UM toque em "Lançar no boletim" cria a atividade com talhão, atividade, calda, tanques, litros e observação',
      lanc.n === 1 && lanc.tipo === 'Pulverização mecanizada' && lanc.talhao === 't055' && lanc.receita === '2lts Quatermon' && lanc.tanques === '5' && lanc.ltanque === '400' && /15 dias/.test(lanc.obs),
      [lanc.tipo, lanc.talhao, JSON.stringify(lanc.receita), lanc.tanques, lanc.ltanque, lanc.obs].join(' · '));
    ok('Depois do toque a pergunta some, a atividade aparece editável no cartão de sempre (talhão, "trocar", calda), sem modal e sem nativo',
      lanc.cartaoSumiu && lanc.tela === 'form' && lanc.nativos === 0 && lanc.cardTal === 't055' && lanc.cardRec === '2lts Quatermon' && lanc.trocar,
      (lanc.cartaoSumiu ? 'sumiu' : 'continuou') + ' · ' + lanc.nativos + ' nativo(s) · card ' + lanc.cardTal + ' · trocar ' + lanc.trocar);
    ok('A resposta do gerente viaja no boletim (b.relatos), com a atividade ligada ao relato', /lancada/.test(lanc.resp) && !!lanc.relato, lanc.resp);

    const rem = await page.evaluate(async () => {
      document.querySelector('#app [data-rm-ativ]').click(); await new Promise(r => setTimeout(r, 150));
      ir('form'); await new Promise(r => setTimeout(r, 150));
      const volta = !!document.querySelector('#app [data-ins-relato]');
      /* lançamento manual do mesmo produto no mesmo talhão: o relato confere e NÃO pergunta de novo */
      rascunho.atividades.push({ id: uid(), talhaoId: 't055', tipo: 'Pulverização mecanizada', pessoas: '2', obs: '', status: '', falta: '', receita: '2 L Quatermon por tanque', tanques: '5', ltanque: '400', insumos: [], maquinas: [] });
      salvarRascunho(); ir('form'); await new Promise(r => setTimeout(r, 150));
      const linha = document.querySelector('#app [data-ins-relato-linha]');
      const pergunta = !!document.querySelector('#app [data-ins-relato]');
      rascunho.atividades = []; salvarRascunho(); ir('form'); await new Promise(r => setTimeout(r, 150));
      document.querySelector('#app [data-ins-aplic$="|nao"]').click(); await new Promise(r => setTimeout(r, 200));
      const naoLinha = document.querySelector('#app [data-ins-relato-linha]');
      const naoResp = JSON.stringify(rascunho.relatos);
      const desf = naoLinha ? naoLinha.querySelector('[data-ins-aplic$="|desfazer"]') : null;
      if (desf) desf.click(); await new Promise(r => setTimeout(r, 200));
      return { volta, confere: linha ? linha.textContent.replace(/\s+/g, ' ').trim() : '', pergunta, naoTexto: naoLinha ? naoLinha.textContent.replace(/\s+/g, ' ').trim() : '', naoResp,
        voltouPergunta: !!document.querySelector('#app [data-ins-relato]'), ativ: rascunho.atividades.length };
    });
    ok('"remover" a atividade lançada é o desfazer: a pergunta volta ao boletim', rem.volta, rem.volta ? 'voltou' : 'não voltou');
    ok('Aplicação já lançada à mão no mesmo talhão com o mesmo produto: o relato "confere ✔" e NÃO pergunta de novo (nunca conta duas vezes)',
      /confere com o lançamento/.test(rem.confere) && !rem.pergunta, rem.confere);
    ok('"Não lançar" grava a resposta no boletim, some com o cartão e deixa "desfazer" no lugar; desfazer devolve a pergunta',
      /nao/.test(rem.naoResp) && /não lançada/.test(rem.naoTexto) && rem.voltouPergunta && rem.ativ === 0, rem.naoTexto + ' · ' + rem.naoResp);
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
