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
/* v96: mensagem REAL do grupo "Aplicações Realizadas" (15/09/2026) — a baixa já feita no Agro1; o PDF é a fixture sintética
   tests/fixtures/erp-ferti-vereda-romaria-2026-09-15.pdf (mesmo layout e números do relatório real) */
/* v100: mensagem REAL do grupo (17/09/2026) — DOIS talhões no mesmo relato ("Caxico topázio e mundo novo"),
   calda de cinco sais, 10 tanques de 2.000 L; a atividade que o escritório escolhe é Pulverização mecanizada */
const MSG_SAIS = ['Aplicação de sais Caxico topázio e mundo novo', '', 'Ureia 5kg', 'Cloreto pó 10kg', 'Map purificado 10kg',
  'Sulfato magnésio 15kg', 'Sulfato zinco 5kg', '', 'Dose / 2000lts', 'Gastou 10 arbus'].join('\n');
const MSG_ERP = ['Ferti-irrigação mês de Setembro/26 Fazenda Vereda-Romaria , finalizada ✅', '', 'Obs : Adubos já baixados no sistema !', '', 'Acido borico', 'Sulf. Manganês', 'Sulf. Zinco'].join('\n');

const provas = [];
const ok = (nome, passou, detalhe) => provas.push({ nome, ok: !!passou, detalhe: detalhe == null ? '' : String(detalhe) });

function servir(dir) {
  return new Promise(res => {
    const tipos = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.mjs': 'text/javascript', '.pdf': 'application/pdf', '.webmanifest': 'application/manifest+json', '.png': 'image/png' };
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
      /Conferir a mensagem/.test(naoRec.h1) && /não reconheceu/.test(naoRec.aviso) && naoRec.chips === 6,   /* v96: + "Aplicação realizada (baixa do Agro1)" */
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
      const talSel = [...document.querySelectorAll('#app .chip.on[data-ins-tal]')].map(b => b.dataset.insTal).join();
      const grupos = selOp ? [...selOp.querySelectorAll('optgroup')].map(g => g.label) : [];
      selOp.value = 'Pulverização mecanizada'; selOp.dispatchEvent(new Event('input', { bubbles: true })); selOp.dispatchEvent(new Event('change', { bubbles: true }));
      const faltaDepois = document.getElementById('bt-ins-importar').getAttribute('data-falta') || '';
      return { faltaAntes, faltaDepois, grupos, talSel, rotulo: bt ? bt.textContent.trim() : '',
        nativos: window.__nativos || 0, texto: document.querySelector('#app').textContent.replace(/\s+/g, ' ') };
    }, MSG_APLIC);
    ok('Pré-visualização — pede a atividade do boletim antes de levar ao gerente (botão inativo diz o que falta)',
      /Escolha a atividade/.test(prev.faltaAntes) && prev.faltaDepois === '' && prev.rotulo === 'Levar ao boletim',
      '"' + prev.faltaAntes + '" → "' + prev.faltaDepois + '" · ' + prev.rotulo);
    ok('Pré-visualização — a lista de atividades é o catálogo do café por natureza; o talhão já vem escolhido pelo de-para (chip aceso)',
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

  /* ---------- v93 (ajuste): a mensagem chega DEPOIS de a atividade estar no boletim ---------- */
  {
    const { page, ctx, erros } = await novaPagina(browser, base, { codigo: CODIGOS.ADMIN, chave: 'ADMIN' }, '2026-09-15T09:00:00-03:00');
    /* o boletim real do Rubens de 14/09: "Aplicação via drench / via solo — José Eustáquio — Arrendamento · 1p · 🧪 Quatermon" */
    const liga = await page.evaluate(t => {
      const s0 = sessao; sessao = { userId: 'u1', papel: 'gerente', nome: 'Rubens', atividade: 'CAFE', fazendaId: 'f14c' };
      const b = novoRascunho('2026-09-14'); sessao = s0; b.id = 'b-rubens-1409'; b.responsavel = 'Rubens'; b.data = '2026-09-14'; b.fazendaId = 'f14c';
      b.atividades = [{ id: 'a-drench', talhaoId: 't055', tipo: 'Aplicação via drench / via solo', pessoas: '1', obs: '', status: '', falta: '', receita: 'Quatermon', tanques: '', ltanque: '', insumos: [], maquinas: [{ nome: '11', horas: '0', comb: '' }] }];
      D.boletins.push(b); salvarDados();
      abrirModulo('colar', () => { insLimpar(); insNav = [{ v: 'colar' }]; });
      insUI.texto = t; insUI.auto = insClassificar(t); insUI.tipo = insUI.auto.tipo; insUI.lida = true; insAbrirPrev(); insRender();
      const p = insUI.prev, bt = document.getElementById('bt-ins-importar');
      const av = document.querySelector('#app [data-ins-vinculo]');
      const selects = document.querySelectorAll('#app select[data-insprev]').length;
      return { vinculo: p.vinculo, data: p.data, rotulo: bt ? bt.textContent.trim() : '', inativo: !!bt && bt.classList.contains('acao-off'),
        aviso: av ? av.textContent.replace(/\s+/g, ' ').trim() : '', selects, nativos: window.__nativos || 0 };
    }, MSG_APLIC);
    ok('Mensagem depois do boletim — o app ACHA o lançamento que confere (boletim de 14/09, mesmo talhão, Quatermon na calda)',
      liga.vinculo && liga.vinculo.boletimId === 'b-rubens-1409' && liga.vinculo.atividadeId === 'a-drench' && liga.data === '2026-09-14',
      liga.vinculo ? liga.vinculo.data + ' · ' + liga.vinculo.tipo + ' · ' + liga.vinculo.talhaoId : 'não achou');
    ok('Pré-visualização — diz "Confere com o boletim de 14/09", esconde talhão/atividade e o botão vira "Ligar ao lançamento", já ativo',
      /Confere com o boletim de 14\/09/.test(liga.aviso) && /Aplicação via drench/.test(liga.aviso) && liga.selects === 0 && liga.rotulo === 'Ligar ao lançamento' && !liga.inativo,
      liga.rotulo + ' · ' + liga.selects + ' lista(s) · ' + liga.aviso.slice(0, 90));
    const desl = await page.evaluate(async () => {
      document.querySelector('#app [data-ins-desvinc]').click(); await new Promise(r => setTimeout(r, 150));
      const semV = { vinculo: insUI.prev.vinculo, rotulo: document.getElementById('bt-ins-importar').textContent.trim(), data: insUI.prev.data,
        selects: document.querySelectorAll('#app select[data-insprev]').length, chips: document.querySelectorAll('#app [data-ins-tal]').length };
      document.querySelector('#app [data-ins-revinc]').click(); await new Promise(r => setTimeout(r, 150));
      return { semV, deNovo: !!insUI.prev.vinculo };
    });
    ok('"Não é este lançamento" volta ao caminho da pergunta (dia de hoje, talhão em chips e atividade em lista); "procurar de novo" religa',
      desl.semV.vinculo === null && desl.semV.rotulo === 'Levar ao boletim' && desl.semV.selects === 1 && desl.semV.chips > 0 && desl.deNovo, JSON.stringify(desl.semV.rotulo) + ' · ' + desl.semV.selects + ' lista(s) · ' + desl.semV.chips + ' chip(s) · religou: ' + desl.deNovo);
    const grav = await page.evaluate(() => {
      const antesB = D.boletins.length, antesA = D.boletins.find(b => b.id === 'b-rubens-1409').atividades.length;
      insImportar();
      const rel = insAplicacoesRelatadas().find(c => c.vinculo);
      insUI.texto = insUI.texto; insUI.tipo = 'aplicacao'; insAbrirPrev(); insImportar();
      const b = D.boletins.find(x => x.id === 'b-rubens-1409');
      const cons = insConsumos('f14c').filter(c => /quatermon/i.test(c.produto));
      /* boletim enviado: o detalhe aparece embaixo da atividade, sem reescrever o boletim */
      sessao = { userId: 'u3', papel: 'admin', nome: 'Escritório' }; ir('detalhe', b.id);
      const html = document.querySelector('#app').textContent.replace(/\s+/g, ' ');
      return { rel, n: insAplicacoesRelatadas().filter(c => c.vinculo).length, boletins: D.boletins.length - antesB, ativ: b.atividades.length - antesA,
        receita: b.atividades[0].receita, status: rel ? insRelatoStatus(rel) : '', flash: insUI.flash, cons: cons.map(c => c.kg + ' ' + c.base + ' · ' + c.area + ' ha · ' + c.op),
        saldoUn: (insProduto('Quatermon') || {}).un, detalhe: (html.match(/Detalhe do grupo[^🔧]{0,160}/) || [''])[0] };
    });
    ok('"Ligar ao lançamento" — o relato fica ligado (boletimId, atividadeId, dia 14/09); nada é criado e o boletim do Rubens não é reescrito',
      grav.rel && grav.rel.vinculo.atividadeId === 'a-drench' && grav.rel.data === '2026-09-14' && grav.boletins === 0 && grav.ativ === 0 && grav.receita === 'Quatermon',
      grav.rel ? grav.rel.data + ' · ' + grav.boletins + ' boletim novo · ' + grav.ativ + ' atividade nova · calda "' + grav.receita + '"' : 'nada');
    ok('Reimportar a mesma mensagem não duplica o detalhe ligado', grav.n === 1, grav.n + ' · ' + grav.flash);
    ok('Mensagens importadas — a situação lê "ligada ao boletim de 14/09"', grav.status === 'ligada ao boletim de 14/09', grav.status);
    ok('Boletim enviado — o detalhe do grupo aparece embaixo da atividade, com a data em que foi colado (c3)',
      /Detalhe do grupo \(colado 15\/09\): 2lts Quatermon · 5 tanques × 400 L · vazão 100 L\/ha/.test(grav.detalhe), grav.detalhe.slice(0, 140));
    ok('Insumos — o detalhe ligado vira consumo calculado: 2 L × 5 tanques = 10 L de Quatermon em ≈ 20 ha (produto em L no catálogo)',
      grav.cons.length === 1 && /^10 L · 20 ha · Aplicação via drench/.test(grav.cons[0]) && grav.saldoUn === 'L', grav.cons.join(' | ') + ' · un ' + grav.saldoUn);
    estadoAplic = await lerD(page);
    errosTodos.push(...erros);
    await ctx.close();
  }
  {
    /* o gerente no dia 15/09: nenhuma pergunta (o relato está ligado ao boletim de ontem) */
    const { page, ctx, erros } = await novaPagina(browser, base, { codigo: 'CC-6081', chave: 'f14c' },
      '2026-09-15T10:00:00-03:00', { userId: 'u1', papel: 'gerente', nome: 'Gerente — Monte Carmelo — Café', atividade: 'CAFE', fazendaId: 'f14c' });
    await porD(page, estadoAplic);
    const sem = await page.evaluate(() => {
      rascunho = null; ir('casa'); rascunho = novoRascunho(); ir('form');
      const pergunta = !!document.querySelector('#app [data-ins-relato]'), linha = !!document.querySelector('#app [data-ins-relato-linha]');
      /* e se um relato SEM vínculo, datado de hoje, chegasse depois de o gerente já ter lançado ontem? confere pelo boletim de ontem, sem perguntar */
      insMensagens().push({ id: 'm-solto', chave: 'x', tipo: 'aplicacao', texto: 'teste', por: 'Escritório', em: '2026-09-15T12:00:00Z', data: '2026-09-15',
        criados: [{ tipo: 'aplicacao', id: 'rel-solto', unidade: 'f14c', talhaoId: 't055', data: '2026-09-15', produto: 'Quatermon', operacao: 'Pulverização mecanizada', receita: '2lts Quatermon', tanques: '5', ltanque: '400', vazao: '100', obs: '' }] });
      ir('form');
      const l2 = document.querySelector('#app [data-ins-relato-linha]');
      return { pergunta, linha, pergunta2: !!document.querySelector('#app [data-ins-relato]'), linha2: l2 ? l2.textContent.replace(/\s+/g, ' ').trim() : '' };
    });
    ok('Boletim do gerente em 15/09 — relato ligado ao boletim de ontem NÃO vira pergunta nem linha', !sem.pergunta && !sem.linha, (sem.pergunta ? 'perguntou' : 'sem pergunta') + ' · ' + (sem.linha ? 'com linha' : 'sem linha'));
    ok('Boletim do gerente — relato solto de hoje com lançamento igual no boletim de ONTEM: "confere com o lançamento … de 14/09 ✔", sem pergunta (nunca duas vezes)',
      !sem.pergunta2 && /confere com o lançamento em José Eustáquio — Arrendamento de 14\/09/.test(sem.linha2), sem.linha2);
    errosTodos.push(...erros);
    await ctx.close();
  }


  /* ======================================================================
     v100 — DOIS TALHÕES NO MESMO RELATO (mensagem real de 17/09/2026: "Aplicação de sais
     Caxico topázio e mundo novo"). O escritório marca os talhões em chips removíveis; o
     gerente lança uma atividade por talhão com um toque; os tanques contam uma vez.
     ====================================================================== */
  let estadoSais = null;
  {
    const { page, ctx, erros } = await novaPagina(browser, base, { codigo: CODIGOS.ADMIN, chave: 'ADMIN' }, '2026-09-17T09:00:00-03:00');
    const lido = await page.evaluate(t => {
      const cls = insClassificar(t), p = insLerAplicacao(t), it = p.itens[0];
      return { cls: cls.tipo, unidade: it.unidade, talhoes: it.talhoes, nomes: insRelatoOnde(it), sugeridos: it.sugeridos, produto: p.produto,
        tanques: p.tanques, ltanque: p.ltanque, calda: p.calda.map(c => c.nome + ' ' + c.qtd + c.un).join(' · '), operacao: p.operacao,
        /* o mesmo leitor com UM talhão pelo nome inteiro, e com um nome que casa com dois talhões (não adivinha) */
        um: insTalhoesDoLocal('sais Caxico topázio', 'f14c', deparaAtaDe('Caxico')).join(),
        /* com a área "Igrejinha" no de-para, "área geral" casa com "Área geral" (sede) E com "Igrejinha — Área geral": dois talhões → não entra */
        ambiguo: insTalhoesDoLocal('sais área geral', 'f14c', deparaAtaDe('FMC Igrejinha')).join(),
        soUnidade: insTalhoesDoLocal('Caxico', 'f14c', deparaAtaDe('Caxico')).join() };
    }, MSG_SAIS);
    ok('Sais — a mensagem real é reconhecida como relato de aplicação, na unidade Monte Carmelo — Café (de-para "Caxico", por id)', lido.cls === 'aplicacao' && lido.unidade === 'f14c', lido.cls + ' · ' + lido.unidade);
    ok('Sais — "Caxico topázio e mundo novo" vira DOIS talhões sugeridos pelo nome inteiro do cadastro, na ordem do cadastro (t020 Mundo Novo, t021 Topázio)',
      (lido.talhoes || []).join() === 't020,t021' && lido.sugeridos === 2 && lido.nomes === 'Caxico — Mundo Novo · Caxico — Topázio', (lido.talhoes || []).join() + ' · ' + lido.nomes);
    ok('Sais — calda com os cinco sais, 10 tanques de 2.000 L; produto e atividade NÃO são adivinhados (nascem vazios)',
      lido.tanques === '10' && lido.ltanque === '2000' && /Ureia 5kg .* Sulfato zinco 5kg/.test(lido.calda) && lido.produto === '' && lido.operacao === '',
      lido.tanques + ' × ' + lido.ltanque + ' · ' + lido.calda + ' · produto "' + lido.produto + '"');
    ok('Sais — um talhão só pelo nome inteiro entra ("sais Caxico topázio" → t021); nome que casa com mais de um talhão ou só a área NÃO entra',
      lido.um === 't021' && lido.ambiguo === '' && lido.soUnidade === '', lido.um + ' · "' + lido.ambiguo + '" · "' + lido.soUnidade + '"');

    const prev = await page.evaluate(async t => {
      abrirModulo('colar', () => { insLimpar(); insNav = [{ v: 'colar' }]; });
      insUI.texto = t; insUI.auto = insClassificar(t); insUI.tipo = insUI.auto.tipo; insUI.lida = true; insAbrirPrev(); insRender();
      await new Promise(r => setTimeout(r, 120));
      const q = s => document.querySelector('#app ' + s), qa = s => [...document.querySelectorAll('#app ' + s)];
      const bt = () => document.getElementById('bt-ins-importar');
      const out = { falta0: bt().getAttribute('data-falta') || '', selects: qa('select[data-insprev]').length, nativos: window.__nativos || 0,
        acesos: qa('.chip.on[data-ins-tal]').map(b => b.dataset.insTal).join(), chips: qa('[data-ins-tal]').length,
        contador: (q('.sel-box .sel-cont') || {}).textContent || '', removiveis: qa('.sel-box .sel-x').map(b => b.getAttribute('aria-label')).join(' · '),
        alvoX: Math.min(...qa('.sel-box .sel-x').map(b => b.getBoundingClientRect().height)), alvoChip: Math.min(...qa('[data-ins-tal]').map(b => b.getBoundingClientRect().height)),
        rola: document.querySelector('#app .plan-acoes .chips').scrollWidth > 390, texto: document.querySelector('#app').textContent.replace(/\s+/g, ' ') };
      /* a fileira nasce curta (＋N, v80, P5): só os escolhidos; "＋N" abre o resto no lugar */
      out.curta = qa('[data-ins-tal]').length; out.mais = (q('[data-ins-tal-mais]') || {}).textContent || ''; out.geralAntes = !!q('[data-ins-tal="geral"]');
      /* × remove Topázio (o chip some da fileira curta); abrir o ＋N e tocar o chip de novo devolve */
      qa('.sel-box .sel-x').find(b => /Topázio/.test(b.getAttribute('aria-label'))).click(); await new Promise(r => setTimeout(r, 120));
      out.depoisX = qa('.chip.on[data-ins-tal]').map(b => b.dataset.insTal).join(); out.contadorX = (q('.sel-box .sel-cont') || {}).textContent || '';
      q('[data-ins-tal-mais]').click(); await new Promise(r => setTimeout(r, 120));
      out.aberta = qa('[data-ins-tal]').length; out.maisDepois = !!q('[data-ins-tal-mais]');
      q('[data-ins-tal="t021"]').click(); await new Promise(r => setTimeout(r, 120));
      out.deVolta = qa('.chip.on[data-ins-tal]').map(b => b.dataset.insTal).join();
      /* "Área geral / sede" é excludente */
      q('[data-ins-tal="geral"]').click(); await new Promise(r => setTimeout(r, 120));
      out.geral = qa('.chip.on[data-ins-tal]').map(b => b.dataset.insTal).join();
      q('[data-ins-tal="t020"]').click(); await new Promise(r => setTimeout(r, 120)); q('[data-ins-tal="t021"]').click(); await new Promise(r => setTimeout(r, 120));
      out.final = qa('.chip.on[data-ins-tal]').map(b => b.dataset.insTal).join();
      const inp = q('input[data-insprev="-|produto"]'); inp.value = 'Sais'; inp.dispatchEvent(new Event('input', { bubbles: true }));
      out.falta1 = bt().getAttribute('data-falta') || '';
      const selOp = q('select[data-insprev="-|operacao"]'); selOp.value = 'Pulverização mecanizada'; selOp.dispatchEvent(new Event('input', { bubbles: true })); selOp.dispatchEvent(new Event('change', { bubbles: true }));
      out.falta2 = bt().getAttribute('data-falta') || ''; out.rotulo = bt().textContent.trim();
      return out;
    }, MSG_SAIS);
    ok('Pré-visualização — os dois talhões vêm acesos em chips (nunca lista nativa para multi-seleção) e "Levar ao boletim" pede o produto',
      prev.acesos === 't020,t021' && prev.selects === 1 && prev.nativos === 0 && /Escreva qual é o produto/.test(prev.falta0), prev.acesos + ' · ' + prev.selects + ' lista(s) · "' + prev.falta0 + '"');
    ok('Pré-visualização — chips removíveis (c12): "2 talhões selecionados", um × por talhão com "Remover <nome>", alvo ≥ 44 px, fileira sem rolar de lado',
      /^2 talhões selecionados$/.test(prev.contador.trim()) && prev.removiveis === 'Remover Caxico — Mundo Novo · Remover Caxico — Topázio' && prev.alvoX >= 44 && prev.alvoChip >= 44 && !prev.rola,
      prev.contador.trim() + ' · ' + prev.removiveis + ' · × ' + prev.alvoX + ' px · chip ' + prev.alvoChip + ' px');
    ok('Pré-visualização — o × tira o talhão na hora ("1 talhão selecionado"), tocar o chip devolve; "Área geral / sede" é excludente',
      prev.depoisX === 't020' && /^1 talhão selecionado$/.test(prev.contadorX.trim()) && prev.deVolta === 't020,t021' && prev.geral === 'geral' && prev.final === 't020,t021',
      prev.depoisX + ' · ' + prev.contadorX.trim() + ' · ' + prev.deVolta + ' · ' + prev.geral + ' · ' + prev.final);
    ok('Pré-visualização — a fileira de talhões nasce curta (só os 2 escolhidos + ＋9; "Área geral" atrás do ＋N, P5) e o ＋N abre os 11 no lugar',
      prev.curta === 2 && prev.mais === '＋9' && !prev.geralAntes && prev.aberta === 11 && !prev.maisDepois, prev.curta + ' chip(s) · ' + prev.mais + ' → ' + prev.aberta + ' chip(s)');
    ok('Pré-visualização — a tela diz que os talhões foram sugeridos pelo nome e que o gerente lança uma atividade por talhão; sem termo de cobrança',
      /[Ss]ugeridos pelo nome/.test(prev.texto) && /uma atividade por talhão/.test(prev.texto) && !/não fez|não realizou|faltou|esqueceu|pendente/i.test(prev.texto), '');
    ok('Pré-visualização — com produto escrito falta só a atividade; escolhida, "Levar ao boletim" fica ativo',
      /Escolha a atividade/.test(prev.falta1) && prev.falta2 === '' && prev.rotulo === 'Levar ao boletim', '"' + prev.falta1 + '" → "' + prev.falta2 + '" · ' + prev.rotulo);

    const grav = await page.evaluate(() => {
      insImportar();
      const rel = insAplicacoesRelatadas().filter(c => /sais/i.test(c.produto));
      insUI.texto = insUI.texto; insUI.tipo = 'aplicacao'; insAbrirPrev(); insUI.prev.produto = 'Sais'; insUI.prev.operacao = 'Pulverização mecanizada'; insImportar();
      const c = rel[0] || {};
      return { n: rel.length, depois: insAplicacoesRelatadas().filter(c => /sais/i.test(c.produto)).length, talhoes: (c.talhoes || []).join(), talhaoId: c.talhaoId,
        onde: insRelatoOnde(c), tanques: c.tanques, ltanque: c.ltanque, calda: (c.calda || []).length, boletins: (D.boletins || []).filter(x => x.fazendaId === 'f14c' && !x.exemplo).length,
        depara: (D.deparaAta || []).filter(x => /topazio|mundo/i.test(planChaveAta(x.ata))).map(x => x.ata + '→' + (x.talhao || '—')).join(' · '), flash: insUI.flash,
        linha: (document.querySelector('#app') || {}).textContent };
    });
    ok('Levar ao boletim — UM relato com os dois talhões (talhoes = t020,t021; talhaoId = o primeiro, para leitores antigos), 10 tanques × 2.000 L, calda de 5 itens; nenhum boletim gravado',
      grav.n === 1 && grav.talhoes === 't020,t021' && grav.talhaoId === 't020' && grav.tanques === '10' && grav.ltanque === '2000' && grav.calda === 5 && grav.boletins === 0,
      grav.talhoes + ' · ' + grav.talhaoId + ' · ' + grav.tanques + ' × ' + grav.ltanque + ' · ' + grav.calda + ' itens · ' + grav.boletins + ' boletim');
    ok('Levar ao boletim — reimportar a mesma mensagem (mesmos talhões) não duplica', grav.depois === 1, grav.n + ' → ' + grav.depois + ' · ' + grav.flash);
    ok('De-para — com mais de um talhão o app aprende só a unidade do nome composto; nenhum talhão é gravado no de-para', grav.depara === 'sais Caxico topázio e mundo novo→—', grav.depara || 'nada gravado');
    estadoSais = await lerD(page);
    errosTodos.push(...erros);
    await ctx.close();
  }
  {
    const { page, ctx, erros } = await novaPagina(browser, base, { codigo: 'CC-6081', chave: 'f14c' },
      '2026-09-17T10:00:00-03:00', { userId: 'u1', papel: 'gerente', nome: 'Gerente — Monte Carmelo — Café', atividade: 'CAFE', fazendaId: 'f14c' });
    await porD(page, estadoSais);
    await page.evaluate(() => { rascunho = null; ir('casa'); });
    await page.waitForTimeout(300);
    const cartao = await page.evaluate(async () => {
      rascunho = novoRascunho(); ir('form'); await new Promise(r => setTimeout(r, 150));
      const c = document.querySelector('#app [data-ins-relato]');
      const out = { existe: !!c, texto: c ? c.textContent.replace(/\s+/g, ' ').trim() : '', campos: c ? c.querySelectorAll('input,textarea,select').length : -1,
        botoes: c ? [...c.querySelectorAll('[data-ins-aplic]')].map(b => b.textContent.trim()) : [] };
      window.__nativos = 0;
      c.querySelector('[data-ins-aplic$="|lancar"]').click(); await new Promise(r => setTimeout(r, 250));
      const as = rascunho.atividades;
      out.n = as.length; out.ativs = as.map(a => [a.tipo, a.talhaoId, a.tanques, a.ltanque, a.obs].join(' | '));
      out.relatoIds = as.map(a => !!a.relatoId).join(); out.resp = JSON.stringify(rascunho.relatos); out.sumiu = !document.querySelector('#app [data-ins-relato]');
      out.nativos = window.__nativos || 0; out.tela = telaAtual;
      out.cards = as.map(a => !!document.querySelector('#app [data-ativ="' + a.id + '"] [data-troca-op]')).join();
      /* remover as duas devolve a pergunta */
      [...document.querySelectorAll('#app [data-rm-ativ]')].forEach(b => b.click()); await new Promise(r => setTimeout(r, 200)); ir('form'); await new Promise(r => setTimeout(r, 150));
      out.voltou = !!document.querySelector('#app [data-ins-relato]');
      return out;
    });
    ok('Boletim do gerente — a pergunta lista os DOIS talhões, uma vez só ("foi assim?"), com duas respostas e nenhum campo',
      cartao.existe && /Caxico — Mundo Novo · Caxico — Topázio/.test(cartao.texto) && /foi assim\?/.test(cartao.texto) && /uma atividade por talhão/.test(cartao.texto) && cartao.botoes.length === 2 && cartao.campos === 0,
      cartao.botoes.join(' · ') + ' · ' + cartao.texto.slice(0, 160));
    ok('UM toque em "Lançar no boletim" cria UMA atividade por talhão (2), Pulverização mecanizada, no lugar, sem nativo, as duas editáveis',
      cartao.n === 2 && cartao.ativs.every(a => /^Pulverização mecanizada \| t02[01] \|/.test(a)) && cartao.tela === 'form' && cartao.nativos === 0 && cartao.cards === 'true,true' && cartao.sumiu,
      cartao.ativs.join(' || '));
    ok('Os 10 tanques da mensagem entram UMA vez (na primeira, Mundo Novo) e a de Topázio diz onde a calda foi contada — nada é somado duas vezes',
      /\| t020 \| 10 \| 2000 \| 10 tanques no total, junto com Caxico — Topázio$/.test(cartao.ativs[0] || '') && /\| t021 \|  \| 2000 \| calda contada em Caxico — Mundo Novo \(10 tanques no total\)$/.test(cartao.ativs[1] || ''),
      cartao.ativs.join(' || '));
    ok('A resposta viaja no boletim com as duas atividades ligadas ao relato; remover as duas devolve a pergunta',
      /lancada/.test(cartao.resp) && /atividadeIds/.test(cartao.resp) && cartao.relatoIds === 'true,true' && cartao.voltou, cartao.resp + ' · voltou: ' + cartao.voltou);

    const parcial = await page.evaluate(async () => {
      /* o gerente já lançou Topázio à mão, com a calda dos sais: o cartão pergunta só por Mundo Novo */
      rascunho.atividades = [{ id: uid(), talhaoId: 't021', tipo: 'Pulverização mecanizada', pessoas: '2', obs: '', status: '', falta: '', receita: 'Ureia 5kg, Cloreto pó 10kg', tanques: '5', ltanque: '2000', insumos: [], maquinas: [] }];
      salvarRascunho(); ir('form'); await new Promise(r => setTimeout(r, 150));
      const c = document.querySelector('#app [data-ins-relato]');
      const out = { texto: c ? c.textContent.replace(/\s+/g, ' ').trim() : 'sem pergunta' };
      c.querySelector('[data-ins-aplic$="|lancar"]').click(); await new Promise(r => setTimeout(r, 250));
      out.n = rascunho.atividades.length; out.novas = rascunho.atividades.filter(a => a.relatoId).map(a => a.talhaoId + ':' + a.tanques).join();
      /* tudo lançado à mão (os dois talhões): "confere ✔", sem pergunta */
      rascunho.atividades = ['t020', 't021'].map(t => ({ id: uid(), talhaoId: t, tipo: 'Pulverização mecanizada', pessoas: '2', obs: '', status: '', falta: '', receita: 'Ureia 5kg', tanques: '5', ltanque: '2000', insumos: [], maquinas: [] }));
      salvarRascunho(); ir('form'); await new Promise(r => setTimeout(r, 150));
      const l = document.querySelector('#app [data-ins-relato-linha]');
      out.pergunta = !!document.querySelector('#app [data-ins-relato]'); out.confere = l ? l.textContent.replace(/\s+/g, ' ').trim() : '';
      return out;
    });
    ok('Parte já lançada à mão (Topázio, com a calda dos sais): o cartão diz que Topázio já tem lançamento e que o toque lança só em Mundo Novo',
      /Caxico — Topázio já tem lançamento ✔ — o toque lança só em Caxico — Mundo Novo/.test(parcial.texto), parcial.texto.slice(0, 220));
    ok('O toque cria só a atividade que faltava (Mundo Novo), com os 10 tanques inteiros', parcial.n === 2 && parcial.novas === 't020:10', parcial.n + ' atividade(s) · ' + parcial.novas);
    ok('Os dois talhões lançados à mão: "confere com os lançamentos em … ✔", sem pergunta (nunca conta duas vezes)',
      !parcial.pergunta && /confere com os lançamentos em Caxico — Mundo Novo · Caxico — Topázio ✔/.test(parcial.confere), parcial.confere);
    errosTodos.push(...erros);
    await ctx.close();
  }
  {
    /* a mensagem chega DEPOIS: os dois talhões já estão no boletim enviado de ontem → liga aos dois lançamentos, conta o consumo uma vez */
    const { page, ctx, erros } = await novaPagina(browser, base, { codigo: CODIGOS.ADMIN, chave: 'ADMIN' }, '2026-09-17T09:00:00-03:00');
    const liga = await page.evaluate(async t => {
      const s0 = sessao; sessao = { userId: 'u1', papel: 'gerente', nome: 'Rubens', atividade: 'CAFE', fazendaId: 'f14c' };
      const b = novoRascunho('2026-09-16'); sessao = s0; b.id = 'b-sais-1609'; b.responsavel = 'Rubens'; b.data = '2026-09-16'; b.fazendaId = 'f14c';
      b.atividades = ['t020', 't021'].map((tal, i) => ({ id: 'a-sais-' + i, talhaoId: tal, tipo: 'Pulverização mecanizada', pessoas: '2', obs: '', status: '', falta: '', receita: 'Ureia 5kg, Cloreto 10kg', tanques: '', ltanque: '', insumos: [], maquinas: [] }));
      D.boletins.push(b); salvarDados();
      abrirModulo('colar', () => { insLimpar(); insNav = [{ v: 'colar' }]; });
      insUI.texto = t; insUI.auto = insClassificar(t); insUI.tipo = insUI.auto.tipo; insUI.lida = true; insAbrirPrev();
      insUI.prev.produto = 'Sais'; insUI.prev.produtoTermo = 'Sais'; insAplicProcurarVinculo(insUI.prev); insRender();
      await new Promise(r => setTimeout(r, 120));
      const p = insUI.prev, bt = document.getElementById('bt-ins-importar'), av = document.querySelector('#app [data-ins-vinculo]');
      const out = { vinculos: (p.vinculos || []).map(v => v.atividadeId + '@' + v.talhaoId).join(), rotulo: bt.textContent.trim(), inativo: bt.classList.contains('acao-off'),
        aviso: av ? av.textContent.replace(/\s+/g, ' ').trim() : '', chips: document.querySelectorAll('#app [data-ins-tal]').length };
      const antesA = b.atividades.length; insImportar(); await new Promise(r => setTimeout(r, 100));
      const c = insAplicacoesRelatadas().find(x => /sais/i.test(x.produto) && x.vinculo);
      out.ativNovas = D.boletins.find(x => x.id === 'b-sais-1609').atividades.length - antesA;
      out.rel = c ? (c.talhoes || []).join() + ' · ' + (c.vinculos || []).length + ' vínculos · ' + c.data : 'sem relato';
      const cons = insConsumos('f14c').filter(x => /ureia/i.test(x.produto));
      out.cons = cons.map(x => x.kg + ' ' + x.base + ' · ' + x.area + ' ha · ' + x.nome).join(' | ');
      sessao = { userId: 'u3', papel: 'admin', nome: 'Escritório' }; ir('detalhe', 'b-sais-1609'); await new Promise(r => setTimeout(r, 100));
      out.detalhes = (document.querySelector('#app').textContent.match(/Detalhe do grupo/g) || []).length;
      return out;
    }, MSG_SAIS);
    ok('Mensagem depois do boletim — com os DOIS talhões lançados ontem, o app liga aos dois lançamentos (um por talhão) e o botão é "Ligar ao lançamento", sem chips',
      liga.vinculos === 'a-sais-0@t020,a-sais-1@t021' && liga.rotulo === 'Ligar ao lançamento' && !liga.inativo && liga.chips === 0 && /Confere com o boletim de 16\/09/.test(liga.aviso) && /Mundo Novo/.test(liga.aviso) && /Topázio/.test(liga.aviso),
      liga.vinculos + ' · ' + liga.rotulo + ' · ' + liga.aviso.slice(0, 120));
    ok('Ligar — nada é criado no boletim; o relato guarda os dois talhões e os dois vínculos; o detalhe aparece embaixo das duas atividades',
      liga.ativNovas === 0 && liga.rel === 't020,t021 · 2 vínculos · 2026-09-16' && liga.detalhes === 2, liga.rel + ' · ' + liga.ativNovas + ' nova(s) · ' + liga.detalhes + ' detalhe(s)');
    ok('Insumos — a calda ligada conta UMA vez: 5 kg × 10 tanques = 50 kg de ureia em 55 ha (soma dos dois talhões, sem vazão na mensagem)',
      /^50 kg · 55 ha · Caxico — Mundo Novo · Caxico — Topázio$/.test(liga.cons), liga.cons);
    errosTodos.push(...erros);
    await ctx.close();
  }
  /* ======================================================================
     v96 — BAIXA DO AGRO1 × BOLETIM: o app casa sozinho, completa e abre a conferência
     (cenários a–o da tarefa, com o PDF da fixture — sintético, mesmo layout e
     mesmos números do relatório real de 15/09/2026 — e a mensagem real do grupo)
     ====================================================================== */
  let estadoErp = null;
  {
    const { page, ctx, erros } = await novaPagina(browser, base, { codigo: CODIGOS.ADMIN, chave: 'ADMIN' }, '2026-09-15T17:00:00-03:00');
    /* boletins semeados em Vereda Romaria (cenário e) + tarefa da ata + recebimentos para o saldo */
    await page.evaluate(() => {
      sessao = { userId: 'u3', papel: 'admin', nome: 'Escritório' };
      const mk = (id, data, ativs, irr) => ({ id, fazendaId: 'f23', data, responsavel: 'Gerente Romaria', clima: { cond: 'Ensolarado', chuvaMm: '' }, mo: { proprios: '', diaristas: '', funcoes: [] },
        atividades: ativs || [], colheita: [], fito: [], ocorrencias: [], obsGeral: '', pendencias: '', secoes: {}, irr: irr || null, enviadoEm: data + 'T18:00:00' });
      const fert = (id, t, prod, kg, area) => ({ id, talhaoId: t, tipo: 'Adubação via fertirrigação', pessoas: '2', obs: '', status: '', insProduto: prod, insDoseKgHa: String(kg / area), insAreaHa: String(area) });
      D.boletins = D.boletins.filter(b => b.fazendaId !== 'f23');
      D.boletins.push(mk('b0905', '2026-09-05', [fert('a1', 't101', 'Ácido Bórico', 300, 21), fert('a2', 't101', 'Sulf. Manganês', 125, 21), fert('a3', 't101', 'Sulf. Zinco', 150, 21)]));
      D.boletins.push(mk('b0903', '2026-09-03', [fert('a4', 't102', 'Ácido Bórico', 100, 22.15), { id: 'a9', talhaoId: 't102', tipo: 'Adubação manual', pessoas: '3', obs: '', status: '', insProduto: 'Ureia', insDoseKgHa: '10', insAreaHa: '22.15' }]));
      D.boletins.push(mk('b0904', '2026-09-04', [fert('a5', 't102', 'Ácido Bórico', 100, 22.15)]));
      D.boletins.push(mk('b0912', '2026-09-12', [fert('a6', 't103', 'Ácido Bórico', 200, 22.15)]));
      D.boletins.push(mk('b0911', '2026-09-11', [fert('a7', 't105', 'Ácido Bórico', 250, 22.15)]));
      D.boletins.push(mk('b0910', '2026-09-10', [], { status: 'Rodou normal', agua: 'Médio', problemas: [], fert: 'Sim', fertSetores: ['t106'], fertReceita: '', obs: '' }));
      D.boletins.push(mk('b0820', '2026-08-20', [fert('a8', 't107', 'Ácido Bórico', 200, 22.15)]));
      D.boletins.push(mk('b0908', '2026-09-08', [fert('a10', 't102', 'KCl', 200, 22.15)]));
      /* a tarefa da ata de 10/09: "Ferti Iniciou – PRAZO: 15/09/26" de Vereda Romaria */
      const t = planNovaTarefa({ origemTipo: 'rodada', origemRot: 'ata de 10/09', unidade: 'f23', desc: 'Ferti Iniciou', prazo: '2026-09-15', status: 'a_iniciar', tipoItem: 'tarefa' });
      t.id = 'tar-ferti'; planGravar(t);
      insRecebimentos().push({ id: 'rec-zn', unidade: 'f23', produto: 'Sulf. Zinco', kg: 2000, data: '2026-09-01', por: 'Gerente Romaria' });
      salvarDados();
    });
    /* a) leitura do PDF por posição */
    const L = await page.evaluate(async base => {
      abrirModulo('colar', () => { insLimpar(); insNav = [{ v: 'colar' }]; });
      await new Promise(r => setTimeout(r, 150));
      const campos = [...document.querySelectorAll('#app textarea, #app input:not([type=hidden])')].length;
      const btPdf = document.getElementById('bt-ins-pdf');
      const buf = await (await fetch(base + '/tests/fixtures/erp-ferti-vereda-romaria-2026-09-15.pdf')).arrayBuffer();
      const L = await erpAnexarBytes(buf, 'erp-ferti-vereda-romaria-2026-09-15.pdf');
      const insumos = [...new Set(L.linhas.map(r => r.campos.insumo))];
      const tot = nome => L.linhas.filter(r => r.campos.insumo === nome).reduce((s, r) => s + r.campos.qtde, 0);
      return { campos, btPdf: btPdf ? btPdf.textContent.trim() : '', ok: L.ok, n: L.n, glebas: L.glebas.length, area: L.somaArea, insumos, totais: insumos.map(tot), duvidosas: L.linhas.filter(r => !r.ok).length,
        l0: L.linhas[0].campos, cab: L.cab, tipo: insUI.tipo, tela: telaAtual, texto: document.querySelector('#app').textContent.replace(/\s+/g, ' ') };
    }, base);
    ok('Agro1 a) Porta única — o botão "📎 Anexar relatório do Agro1 (PDF)" existe e a tela de colar continua com UM campo', L.btPdf === '📎 Anexar relatório do Agro1 (PDF)' && L.campos === 1, L.btPdf + ' · ' + L.campos + ' campo(s)');
    ok('Agro1 a) Leitura por posição — 24 linhas, 8 glebas, 164,90 ha, nenhuma leitura duvidosa', L.ok && L.n === 24 && L.glebas === 8 && Math.abs(L.area - 164.9) < 0.01 && L.duvidosas === 0, L.n + ' linhas · ' + L.glebas + ' glebas · ' + L.area + ' ha · ' + L.duvidosas + ' duvidosa(s)');
    ok('Agro1 a) Leitura — totais 1.900 / 775 / 950 kg e "SULFATO DE MANGANES BRANCO 31%" reunido (nome quebrado em duas linhas)',
      L.insumos.join('|') === 'ACIDO BORICO|SULFATO DE MANGANES BRANCO 31%|SULFATO DE ZINCO 20%' && L.totais.join('/') === '1900/775/950', L.insumos.join(' | ') + ' · ' + L.totais.join(' / '));
    ok('Agro1 a) Cabeçalho — propriedade, atividade, empreendimento, safra, operação, período e emissão lidos',
      L.cab.propriedade === 'FAZENDA VEREDA ROMARIA' && L.cab.atividade === 'CAFE' && /FAZ\. ROMARIA/.test(L.cab.empreendimento) && L.cab.safra === '2026/2027' && L.cab.operacoes[0] === 'FERTIRRIGAÇAO' && L.cab.periodo.de === '2026-09-15' && L.cab.emitidoEm === '2026-09-15 16:39:47',
      JSON.stringify(L.cab).slice(0, 200));
    ok('Agro1 a) Com o PDF anexado a classificação é certa: tipo "erp", pré-visualização aberta na hora, sem outro toque', L.tipo === 'erp' && L.tela === 'colar' && /Conferir a mensagem/.test(L.texto) && /lido por posição: 24 linhas/.test(L.texto), L.tipo + ' · ' + L.tela);
    /* b) datas: hora de lançamento, competência do mês */
    ok('Agro1 b) Hora do Agro1 é de LANÇAMENTO (16:22:44 · 17:00:00), competência 2026-09; nenhuma tela diz "aplicado às"',
      L.l0.dataIni === '2026-09-15' && L.l0.horaIni === '16:22:44' && L.l0.horaFim === '17:00:00' && !/aplicad[oa]s? às/i.test(L.texto) && /LANÇAMENTO, não de aplicação/.test(L.texto), L.l0.horaIni + ' → ' + L.l0.horaFim);
    /* identidade por id + e) o casamento */
    const C = await page.evaluate(() => {
      const p = insUI.prev;
      const antes = { unidade: p.unidade, comp: p.competencia, op: p.operacaoErp, falta: erpFalta(p), glebasSemTalhao: p.glebas.filter(g => !g.talhaoId).length, produtos: p.produtos.map(x => x.erp + '→' + x.produto),
        selects: document.querySelectorAll('#app select[data-erpsel^="gleba"]').length, inativo: !!document.getElementById('bt-ins-importar') && document.getElementById('bt-ins-importar').classList.contains('acao-off') };
      /* o escritório liga cada gleba ao talhão (por id) na pré-visualização — a primeira vez pergunta, a próxima não */
      p.glebas.forEach((g, i) => { g.talhaoId = 't10' + (i + 1); }); erpRecalcular(p); ir('colar');
      const r1 = JSON.stringify(p.itens.map(it => it.res)); erpRecalcular(p); const r2 = JSON.stringify(p.itens.map(it => it.res));
      const por = (setor, prod) => { const it = p.itens.find(x => x.gleba === 'SETOR ' + setor + ' ROMARIA' && x.produto === prod); return it ? it.res.resultado : '?'; };
      const bt = document.getElementById('bt-ins-importar');
      return { antes, falta: erpFalta(p), resumo: p.resumo, reproduz: r1 === r2, soApp: p.soApp.map(erpTextoSoApp), dose: p.dose.map(d => d.gleba + ' · ' + d.produto),
        tarefas: p.tarefas.map(t => t.desc), avisos: p.avisos, rotulo: bt ? bt.textContent.trim() : '', inativo: !!bt && bt.classList.contains('acao-off'),
        s1: [por(1, 'Ácido Bórico'), por(1, 'Sulf. Manganês'), por(1, 'Sulf. Zinco')], s2: por(2, 'Ácido Bórico'), s3: por(3, 'Ácido Bórico'), s4: por(4, 'Ácido Bórico'), s5: por(5, 'Ácido Bórico'),
        s6: [por(6, 'Ácido Bórico'), por(6, 'Sulf. Manganês'), por(6, 'Sulf. Zinco')], s7: por(7, 'Ácido Bórico'), s8: [por(8, 'Ácido Bórico'), por(8, 'Sulf. Manganês'), por(8, 'Sulf. Zinco')],
        outras: p.itens.filter(it => !['SETOR 1 ROMARIA', 'SETOR 6 ROMARIA', 'SETOR 8 ROMARIA'].includes(it.gleba) && it.produto !== 'Ácido Bórico').map(it => it.res.resultado),
        texto3: erpTextoLinha(p.itens.find(x => x.gleba === 'SETOR 3 ROMARIA' && x.produto === 'Ácido Bórico'), 'f23'), texto4: erpTextoLinha(p.itens.find(x => x.gleba === 'SETOR 4 ROMARIA' && x.produto === 'Ácido Bórico'), 'f23'),
        abertos: [...document.querySelectorAll('#app details[data-erp-grupo]')].map(d => d.querySelector('summary').textContent.replace(/\s+/g, ' ').replace(/›\s*$/, '').trim() + (d.open ? ' [aberto]' : ' [fechado]')),
        texto: document.querySelector('#app').textContent.replace(/\s+/g, ' '), nativos: window.__nativos || 0 };
    });
    ok('Agro1 2.3) Propriedade do Agro1 → unidade pelo de-para da ata por id (FAZENDA VEREDA ROMARIA → f23); competência set/2026 do período; operação FERTIRRIGACAO',
      C.antes.unidade === 'f23' && C.antes.comp === '2026-09' && C.antes.op === 'FERTIRRIGACAO', C.antes.unidade + ' · ' + C.antes.comp + ' · ' + C.antes.op);
    ok('Agro1 2.3) Gleba do Agro1 → talhão NÃO é adivinhada ("SETOR 1" nunca casa por conter "1"): 8 seletores, botão inativo dizendo o que falta',
      C.antes.glebasSemTalhao === 8 && C.antes.selects === 8 && C.antes.inativo && /Ligue cada gleba/.test(C.antes.falta), C.antes.glebasSemTalhao + ' sem talhão · ' + C.antes.selects + ' seletor(es) · "' + C.antes.falta + '"');
    ok('Agro1 2.3) Insumo do Agro1 → D.insumos pelo de-para de produtos (ACIDO BORICO → Ácido Bórico, SULFATO DE MANGANES BRANCO 31% → Sulf. Manganês, SULFATO DE ZINCO 20% → Sulf. Zinco)',
      C.antes.produtos.join('|') === 'ACIDO BORICO→Ácido Bórico|SULFATO DE MANGANES BRANCO 31%→Sulf. Manganês|SULFATO DE ZINCO 20%→Sulf. Zinco', C.antes.produtos.join(' | '));
    ok('Agro1 e) SETOR 1: 300 kg bórico, 125 kg Mn e 150 kg Zn em 05/09 → as 3 linhas ✅ Bate', C.s1.join() === 'bate,bate,bate', C.s1.join(' · '));
    ok('Agro1 e) SETOR 2: bórico 100 kg em 03/09 + 100 kg em 04/09 → ✅ Bate (soma)', C.s2 === 'bate', C.s2);
    ok('Agro1 e) SETOR 3: bórico 200 kg em 12/09 → ⚠️ Quantidade diferente, explicada em palavras', C.s3 === 'qtd_dif' && /boletim 200 kg \(12\/09\) × Agro1 250 kg/.test(C.texto3), C.texto3);
    ok('Agro1 e) SETOR 4 sem bórico e SETOR 5 com 250 kg em 11/09 → SETOR 4 ⚠️ Talhão diferente ("possível setor trocado") e SETOR 5 ➕ Só no Agro1 (o lançamento já foi usado no desempate)',
      C.s4 === 'talhao_dif' && C.s5 === 'so_erp' && /possível setor trocado: boletim no Setor 5 .*Agro1 no Setor 4/.test(C.texto4), C.s4 + ' · ' + C.s5 + ' · ' + C.texto4);
    ok('Agro1 e) SETOR 6 marcado em "Em quais setores?" em 10/09, sem produto → as 3 linhas ✅ Lançado sem quantidade', C.s6.join() === 'sem_qtd,sem_qtd,sem_qtd', C.s6.join(' · '));
    ok('Agro1 e) SETOR 7: bórico 200 kg em 20/08 → ⚠️ Fora da janela', C.s7 === 'fora_janela', C.s7);
    ok('Agro1 e) SETOR 8 sem nada → as 3 linhas ➕ Só no Agro1; todas as outras linhas sem lançamento → ➕', C.s8.join() === 'so_erp,so_erp,so_erp' && C.outras.every(r => r === 'so_erp'), C.s8.join(' · ') + ' · outras: ' + [...new Set(C.outras)].join(','));
    ok('Agro1 e) Fertirrigação de KCl no SETOR 2 em 08/09 (insumo fora do PDF) → 🔸 Só no boletim; a adubação de solo de 03/09 NÃO aparece como 🔸',
      C.soApp.length === 1 && /Setor 2 · kcl · 200 kg no boletim de 08\/09 — sem baixa no Agro1 — conferir o estoque/.test(C.soApp[0]), C.soApp.join(' | '));
    ok('Agro1 Resumo no topo — "Vereda Romaria · Fertirrigação · set/2026 · 24 linhas do Agro1 · ✅ 7 batem · ➕ 14 completadas pelo Agro1 · ⚠️ 3 para conferir · 🔸 1 só no boletim"',
      /Vereda Romaria · Fertirrigação · set\/2026 · 24 linhas do Agro1 · ✅ 7 batem · ➕ 14 completadas pelo Agro1 · ⚠️ 3 para conferir · 🔸 1 só no boletim/.test(C.texto), JSON.stringify(C.resumo));
    ok('Agro1 f) Reprodutível — rodar o casamento duas vezes com a mesma entrada dá resultado idêntico', C.reproduz, '');
    ok('Agro1 j) C7 dose/ha fora do padrão do relatório dispara SÓ no SETOR 8 (bórico e zinco), sem juízo agronômico',
      C.dose.length === 2 && C.dose.every(d => /^SETOR 8 ROMARIA/.test(d)) && /Ácido Bórico/.test(C.dose[0]) && /Sulf\. Zinco/.test(C.dose[1]) && /fora do padrão deste relatório/.test(C.texto) && !/dose alta|errada|tóxic/i.test(C.texto), C.dose.join(' | '));
    ok('Agro1 k) C8 — a tarefa «Ferti Iniciou» é sugerida na pré-visualização; nada muda antes de importar', C.tarefas.join() === 'Ferti Iniciou' && /A tarefa «Ferti Iniciou» casa com esta aplicação — concluir\?/.test(C.texto) && /nunca conclui sozinho/.test(C.texto), C.tarefas.join(' | '));
    ok('Agro1 2.6) Pré-visualização — grupos na ordem ⚠️ → 🔸 → ➕ → ✅, com ⚠️ e 🔸 abertos e ➕ e ✅ recolhidos (P5)',
      C.abertos.length === 4 && /^⚠️\s*Para conferir\s*3 \[aberto\]$/.test(C.abertos[0]) && /^🔸\s*Só no boletim\s*1 \[aberto\]$/.test(C.abertos[1]) && /^➕\s*Completado pelo Agro1\s*14 \[fechado\]$/.test(C.abertos[2]) && /^✅\s*Batem\s*7 \[fechado\]$/.test(C.abertos[3]), C.abertos.join(' | '));
    ok('Agro1 2.6) UM botão "Importar e abrir conferência", ativo depois de ligar as glebas; zero diálogo nativo', C.rotulo === 'Importar e abrir conferência' && !C.inativo && C.falta === '' && !C.nativos, C.rotulo + ' · falta "' + C.falta + '"');
    ok('Agro1 n) Pré-visualização — nenhum custo e nenhum termo proibido', !/R\$|custo|não fez|não lançou|erro do gerente|pendente|atrasad/i.test(C.texto), '');
    /* g) completar: importa e prova que farol, dias sem registro e boletins ficam idênticos */
    const G = await page.evaluate(async () => {
      const antes = { bol: JSON.stringify(D.boletins), farol: JSON.stringify(farolPorUnidade()), dsr: JSON.stringify(dsrCache), baixas: erpBaixas().length, msgs: insMensagens().length };
      window.__nativos = 0;
      document.getElementById('bt-ins-importar').click();
      await new Promise(r => setTimeout(r, 200));
      const depois = { bol: JSON.stringify(D.boletins), farol: JSON.stringify(farolPorUnidade()), dsr: JSON.stringify(dsrCache), baixas: erpBaixas().length, msgs: insMensagens().length };
      const b1 = erpBaixas().find(b => b.glebaErp === 'SETOR 1 ROMARIA' && b.produto === 'Ácido Bórico');
      const imp = erpImportacoes()[0];
      const abertos = erpAbertos();
      const past = planPastilhas().map(p => p.txt);
      const ex = planExecucao(planTarefa('tar-ferti'));
      const zn = insSaldos('f23').find(l => l.nome === 'Sulf. Zinco');
      insUI.cons = 'f23|' + insChaveProd('Sulf. Zinco'); ir('colar', null, true);
      const listaApl = insListaAplicadoErp('f23', zn).replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ');
      const det = [...document.querySelectorAll('#app details[data-erp-grupo]')].map(d => d.querySelector('summary').textContent.replace(/\s+/g, ' ').replace(/›\s*$/, '').trim() + (d.open ? ' [aberto]' : ' [fechado]'));
      const alvo = Math.min(...[...document.querySelectorAll('#app [data-erp-abrir]')].map(b => b.getBoundingClientRect().height));
      return { antes, depois, b1, impResumo: imp && imp.resumo, impLinhas: imp ? imp.linhas.length : 0, soApp: imp ? imp.soApp.length : 0, abertos: abertos.length, past, nativos: window.__nativos,
        tela: telaAtual, nav: (insNav[insNav.length - 1] || {}).v, h1: (document.querySelector('#app .topo h1') || {}).textContent.replace(/\s+/g, ' ').trim(),
        ex: { ha: ex.ha, n: ex.n, erp: ex.itens.filter(l => l.origem === 'erp').length, por: [...new Set(ex.itens.map(l => l.por))] }, zn: zn && { recebido: zn.recebido, aplicado: zn.aplicado, saldo: zn.saldo, erp: zn.baixadoErp },
        listaApl, det, alvo, fila: syncFila.filter(x => x.t === 'erp').length, texto: document.querySelector('#app').textContent.replace(/\s+/g, ' ') };
    });
    ok('Agro1 g) "Importar e abrir conferência" grava 24 linhas em D.baixasErp (fila offline "erp") e a trilha em Mensagens importadas; abre a tela da conferência',
      G.depois.baixas - G.antes.baixas === 24 && G.fila === 24 && G.depois.msgs - G.antes.msgs === 1 && G.tela === 'colar' && G.nav === 'erpconf' && /Conferência Agro1 × Boletim/.test(G.h1) && !G.nativos,
      (G.depois.baixas - G.antes.baixas) + ' linhas · fila ' + G.fila + ' · ' + G.nav + ' · ' + G.h1);
    ok('Agro1 b) A linha gravada leva lancado_erp_ini "2026-09-15 16:22:44", lancado_erp_fim "2026-09-15 17:00:00", competência 2026-09, status vigente, emitido 15/09 16:39:47',
      G.b1 && G.b1.lancadoErpIni === '2026-09-15 16:22:44' && G.b1.lancadoErpFim === '2026-09-15 17:00:00' && G.b1.competencia === '2026-09' && G.b1.status === 'vigente' && G.b1.emitidoErpEm === '2026-09-15 16:39:47' && G.b1.talhaoId === 't101',
      G.b1 ? G.b1.lancadoErpIni + ' → ' + G.b1.lancadoErpFim + ' · ' + G.b1.competencia : 'linha não achada');
    ok('Agro1 g) Nenhum boletim é reescrito; farol de registro e dias sem registro de Vereda Romaria ficam idênticos antes e depois da importação',
      G.antes.bol === G.depois.bol && G.antes.farol === G.depois.farol && G.antes.dsr === G.depois.dsr, '');
    ok('Agro1 g) As linhas ➕ COMPLETAM o executado da tarefa «Ferti Iniciou» com "origem: Agro1" (soma em ha dos talhões distintos)',
      G.ex.erp > 0 && G.ex.por.includes('origem: Agro1') && G.ex.ha > 0, G.ex.n + ' lançamento(s), ' + G.ex.erp + ' do Agro1, ' + G.ex.ha + ' ha · por: ' + G.ex.por.join(' / '));
    ok('Agro1 2.5) Regra de saldo — sulf. zinco: recebido 2.000 + boletim 150 kg (set) + baixa Agro1 950 kg → aplicado 950 e saldo 1.050 (a baixa manda; o boletim do mês vira conferência, nunca soma)',
      G.zn && G.zn.recebido === 2000 && Math.abs(G.zn.aplicado - 950) < 0.01 && Math.abs(G.zn.saldo - 1050) < 0.01 && Math.abs(G.zn.erp - 950) < 0.01, JSON.stringify(G.zn));
    ok('Agro1 2.5) O toque no "aplicado" diz de onde veio o número: "baixa do Agro1 de 15/09 · origem: Agro1" e o lançamento do boletim como "conferência · mês coberto pela baixa do Agro1, não soma"',
      /baixa do Agro1 de 15\/09/.test(G.listaApl) && /origem: Agro1/.test(G.listaApl) && /conferência · mês coberto pela baixa do Agro1, não soma/.test(G.listaApl), G.listaApl.slice(0, 160));
    ok('Agro1 2.6) Tela da conferência — ⚠️ 3 e 🔸 1 abertos, ➕ 14 e ✅ 7 recolhidos; cada item é UMA linha tocável ≥ 44 px',
      G.det.length === 4 && /⚠️\s*Para conferir\s*3 \[aberto\]/.test(G.det[0]) && /🔸\s*Só no boletim\s*1 \[aberto\]/.test(G.det[1]) && /\[fechado\]/.test(G.det[2]) && /\[fechado\]/.test(G.det[3]) && G.alvo >= 44, G.det.join(' | ') + ' · alvo ' + G.alvo + ' px');
    ok('Agro1 i) Pastilha "🔎 4 lançamentos do Agro1 para conferir" (3 ⚠️ + 1 🔸) na porta de entrada; zero notificação push',
      G.past.includes('🔎 4 lançamentos do Agro1 para conferir') && G.abertos === 4, G.past.join(' | '));
    ok('Agro1 n) Tela da conferência — sem custo e sem termo proibido', !/R\$|custo|não fez|não lançou|erro do gerente|pendente|atrasad/i.test(G.texto), '');
    /* h) resolver com chips e desfazer no lugar */
    const H = await page.evaluate(async () => {
      const b3 = erpBaixas().find(b => b.glebaErp === 'SETOR 3 ROMARIA' && b.produto === 'Ácido Bórico');
      document.querySelector('[data-erp-abrir="' + b3.id + '"]').click(); await new Promise(r => setTimeout(r, 100));
      const chips = [...document.querySelectorAll('[data-erp-res^="' + b3.id + '|"]')].map(c => c.textContent.trim());
      const lado = document.querySelector('[data-erp-item="' + b3.id + '"] .plan-acoes').textContent.replace(/\s+/g, ' ');
      const alturaAntes = document.documentElement.scrollHeight, telaAntes = telaAtual, campos = document.querySelectorAll('[data-erp-item="' + b3.id + '"] input, [data-erp-item="' + b3.id + '"] select, [data-erp-item="' + b3.id + '"] textarea').length;
      window.__nativos = 0;
      document.querySelector('[data-erp-res="' + b3.id + '|mesmo"]').click(); await new Promise(r => setTimeout(r, 100));
      const dep1 = { estado: b3.conf.estado, hist: b3.conf.historico.length, abertos: erpAbertos().length, salvo: (document.querySelector('[data-erp-item="' + b3.id + '"]') || {}).textContent.replace(/\s+/g, ' '), desfazer: !!document.querySelector('[data-erp-res="' + b3.id + '|desfazer"]') };
      document.querySelector('[data-erp-res="' + b3.id + '|desfazer"]').click(); await new Promise(r => setTimeout(r, 100));
      const dep2 = { estado: b3.conf.estado, hist: b3.conf.historico.length, abertos: erpAbertos().length, motivo: b3.conf.historico[1] && b3.conf.historico[1].motivo, quem: b3.conf.historico[0].por };
      return { chips, lado, campos, dep1, dep2, nativos: window.__nativos, mesmaTela: telaAtual === telaAntes, modal: !!document.querySelector('dialog[open], .folha') };
    });
    ok('Agro1 2.6) O toque abre, NO LUGAR, a linha do Agro1 lado a lado com o lançamento do app (data, talhão, quantidade e quem lançou), sem campo e sem modal',
      /Agro1\s*SETOR 3 ROMARIA · ACIDO BORICO · lançado no Agro1 em 15\/09/.test(H.lado) && /Boletim\s*12\/09 · Setor 3 · Adubação via fertirrigação · Gerente Romaria/.test(H.lado) && H.campos === 0 && !H.modal && H.mesmaTela, H.lado.slice(0, 200));
    ok('Agro1 2.6) Chips de resolução: é o mesmo lançamento · são aplicações diferentes · pedir conferência ao gerente · Agro1 precisa de correção',
      H.chips.join(' · ') === 'é o mesmo lançamento · são aplicações diferentes · pedir conferência ao gerente · Agro1 precisa de correção', H.chips.join(' · '));
    ok('Agro1 h) "é o mesmo lançamento" grava na hora: o item sai da contagem aberta (4 → 3), "✔ Salvo · é o mesmo lançamento · desfazer" no lugar, 1 entrada no histórico; zero nativo',
      H.dep1.estado === 'mesmo' && H.dep1.hist === 1 && H.dep1.abertos === 3 && /✔ Salvo · é o mesmo lançamento/.test(H.dep1.salvo) && H.dep1.desfazer && !H.nativos, H.dep1.estado + ' · ' + H.dep1.abertos + ' abertos');
    ok('Agro1 h) "desfazer" volta ao estado anterior (aberta, 4 para conferir) com 2 entradas no histórico (quem, quando, de → para, "desfeito")',
      H.dep2.estado === 'aberta' && H.dep2.hist === 2 && H.dep2.abertos === 4 && H.dep2.motivo === 'desfeito' && H.dep2.quem === 'Escritório', H.dep2.estado + ' · ' + H.dep2.hist + ' · ' + H.dep2.abertos);
    /* k) a tarefa só muda com o toque em "Concluí" */
    const K = await page.evaluate(async () => {
      const antes = planTarefa('tar-ferti').status;
      const chip = document.querySelector('[data-erp-tar="tar-ferti|concluir"]'); const rot = [...document.querySelectorAll('[data-erp-tar^="tar-ferti|"]')].map(c => c.textContent.trim());
      if (chip) chip.click(); await new Promise(r => setTimeout(r, 150));
      return { antes, rot, depois: planTarefa('tar-ferti').status, hist: planHistDe('tar-ferti').filter(h => h.campo === 'status').length };
    });
    ok('Agro1 k) C8 — «Ferti Iniciou» estava A INICIAR; os chips "Concluí · ainda não" existem e o status só muda com o toque em Concluí',
      K.antes === 'a_iniciar' && K.rot.join(' · ') === 'Concluí · ainda não' && K.depois === 'finalizado' && K.hist === 1, K.antes + ' → ' + K.depois + ' · ' + K.rot.join(' · '));
    /* c) reimportação: 0 linhas novas e botão inativo com a falta certa */
    const R = await page.evaluate(async base => {
      insLimpar(); insNav = [{ v: 'colar' }]; ir('colar');
      const buf = await (await fetch(base + '/tests/fixtures/erp-ferti-vereda-romaria-2026-09-15.pdf')).arrayBuffer();
      await erpAnexarBytes(buf, 'erp-ferti-vereda-romaria-2026-09-15.pdf');
      const p = insUI.prev, bt = document.getElementById('bt-ins-importar');
      const antes = erpBaixas().length; bt.click(); await new Promise(r => setTimeout(r, 100));
      return { glebasLigadas: p.glebas.filter(g => g.talhaoId).length, ja: p.jaImportadas, hashIgual: p.hashIgual, falta: bt.getAttribute('data-falta') || '', inativo: bt.classList.contains('acao-off'), novas: erpBaixas().length - antes,
        texto: document.querySelector('#app').textContent.replace(/\s+/g, ' ') };
    }, base);
    ok('Agro1 2.3) Na segunda importação as 8 glebas já vêm ligadas aos talhões (de-para aprendido — não pergunta de novo)', R.glebasLigadas === 8, R.glebasLigadas + ' ligadas');
    ok('Agro1 c) C1 — o mesmo PDF dá 0 linhas novas (24 "já importada em 15/09 por Escritório") e o botão fica inativo com "Este relatório já foi importado em 15/09."',
      R.ja === 24 && R.hashIgual && R.inativo && R.falta === 'Este relatório já foi importado em 15/09.' && R.novas === 0 && /já importada/i.test(R.texto) && /por Escritório/.test(R.texto), R.ja + ' já importadas · "' + R.falta + '" · ' + R.novas + ' nova(s)');
    /* d) C3 — mesmo PDF com SETOR 3 ácido bórico = 300: três chips, nada gravado antes da resposta; "substituir" deixa 2 linhas (1 superada) */
    const D3 = await page.evaluate(async () => {
      const L = insUI.erp; const r = L.linhas.find(x => x.gleba === 'SETOR 3 ROMARIA' && /BORICO/.test(x.campos.insumo));
      r.campos.qtde = 300; r.campos.doseHa = 300 / 22.15; L.hash = 'x' + L.hash; insAbrirPrev(); ir('colar');
      const p = insUI.prev, bt = document.getElementById('bt-ins-importar');
      const it = p.conflitos[0];
      const chips = [...document.querySelectorAll('[data-erp-c3]')].map(c => c.textContent.trim());
      const textoPrev = document.querySelector('#app').textContent.replace(/\s+/g, ' ');
      const marcadoAntes = p.conflitos.filter(x => x.conflito.resposta).length;
      const antes = erpBaixas().length;
      bt.click(); await new Promise(r => setTimeout(r, 100));
      const gravouAntes = erpBaixas().length - antes;
      const falta = bt.getAttribute('data-falta') || '';
      document.querySelector('[data-erp-c3="' + it.i + '|substituir"]').click(); await new Promise(r => setTimeout(r, 100));
      const bt2 = document.getElementById('bt-ins-importar'); const ativo = !bt2.classList.contains('acao-off');
      bt2.click(); await new Promise(r => setTimeout(r, 200));
      const s3 = erpBaixas().filter(b => b.glebaErp === 'SETOR 3 ROMARIA' && b.produto === 'Ácido Bórico');
      return { conflitos: p.conflitos.length, chips, marcado: marcadoAntes, gravouAntes, falta, ativo, novas: erpBaixas().length - antes,
        s3: s3.map(b => b.qtde + ' ' + b.status + (b.superadaPor ? ' → superada por outra' : '') + (b.substitui ? ' (substitui a anterior)' : '')), res300: (s3.find(b => b.qtde === 300) || { casamento: {} }).casamento.resultado, texto: textoPrev };
    });
    ok('Agro1 d) C3 — a linha já importada com OUTRA quantidade mostra "já existe 250 kg (lançado 15/09); este relatório traz 300 kg" com três chips, nenhum marcado',
      D3.conflitos === 1 && D3.chips.join(' · ') === 'substituir · somar como outra aplicação · ignorar esta linha' && D3.marcado === 0 && /já existe 250 kg \(lançado 15\/09\); este relatório traz 300 kg/.test(D3.texto), D3.chips.join(' · ') + ' · ' + (D3.texto.match(/já existe[^·]{0,80}/) || [''])[0]);
    ok('Agro1 d) C3 — o "Importar" fica inativo até o conflito ser respondido e NADA é gravado antes', D3.gravouAntes === 0 && /Responda o que fazer/.test(D3.falta), '"' + D3.falta + '" · ' + D3.gravouAntes + ' gravada(s)');
    ok('Agro1 d) C3 — "substituir" libera o botão e deixa 2 linhas no banco: a de 250 kg superada (com a ligação) e a de 300 kg vigente; as outras 23 não entram de novo',
      D3.ativo && D3.novas === 1 && D3.s3.length === 2 && D3.s3.includes('250 superada → superada por outra') && D3.s3.includes('300 vigente (substitui a anterior)') && D3.res300 === 'qtd_dif', D3.s3.join(' | ') + ' · ' + D3.novas + ' nova(s) · a nova é ' + D3.res300 + ' (o lançamento de 200 kg foi liberado pela linha substituída)');
    /* m) só a mensagem: relato sem quantidade, sem casamento, saldo inalterado */
    const M = await page.evaluate(async msg => {
      const saldoAntes = JSON.stringify(insSaldos('f23'));
      insLimpar(); insNav = [{ v: 'colar' }]; ir('colar'); await new Promise(r => setTimeout(r, 100));
      const ta = document.getElementById('ins-texto'); ta.value = msg; ta.dispatchEvent(new Event('input', { bubbles: true })); await new Promise(r => setTimeout(r, 50));
      document.getElementById('bt-ins-ler').click(); await new Promise(r => setTimeout(r, 150));
      const cls = insClassificar(msg), p = insUI.prev, bt = document.getElementById('bt-ins-importar');
      const out = { tipo: cls.tipo, soMensagem: !!(p && p.soMensagem), unidade: p && p.unidade, comp: p && p.competencia, op: p && p.operacaoErp, produtos: p ? p.produtos.map(x => x.erp + '→' + x.produto) : [], finalizada: p && p.finalizada,
        rotulo: bt ? bt.textContent.trim() : '', inativo: !!bt && bt.classList.contains('acao-off'), texto: document.querySelector('#app').textContent.replace(/\s+/g, ' ') };
      const antesB = erpBaixas().length; bt.click(); await new Promise(r => setTimeout(r, 150));
      out.baixasNovas = erpBaixas().length - antesB; out.relatos = erpRelatos().length; out.flash = insUI.flash; out.saldoIgual = JSON.stringify(insSaldos('f23')) === saldoAntes;
      insNav = [{ v: 'colar' }, { v: 'erp' }]; ir('colar'); out.lista = document.querySelector('#app').textContent.replace(/\s+/g, ' ');
      return out;
    }, MSG_ERP);
    ok('Agro1 m) Só a mensagem — classificada como "Aplicação realizada (baixa do Agro1)"; unidade Vereda-Romaria → f23 por id, competência 2026-09 ("mês de Setembro/26"), fertirrigação, 3 produtos pelo de-para, "finalizada"',
      M.tipo === 'erp' && M.soMensagem && M.unidade === 'f23' && M.comp === '2026-09' && M.op === 'FERTIRRIGACAO' && M.produtos.join('|') === 'Acido borico→Ácido Bórico|Sulf. Manganês→Sulf. Manganês|Sulf. Zinco→Sulf. Zinco' && M.finalizada,
      M.tipo + ' · ' + M.unidade + ' · ' + M.comp + ' · ' + M.produtos.join(' | '));
    ok('Agro1 m) Só a mensagem — "Importar relato" grava um relato SEM quantidade (0 baixas, 0 casamento), o saldo não muda e a lista diz "aguardando relatório do Agro1"; nunca estima kg',
      M.rotulo === 'Importar relato' && !M.inativo && M.baixasNovas === 0 && M.relatos === 1 && M.saldoIgual && /aguardando relatório do Agro1/.test(M.lista) && /Nunca estimamos kg/.test(M.texto), M.rotulo + ' · ' + M.baixasNovas + ' baixa(s) · ' + M.relatos + ' relato(s)');
    /* o) layout desconhecido: nada gravado, texto na trilha */
    const O = await page.evaluate(async () => {
      const lido = erpLerItens([[{ s: 'Relatório de estoque', x: 40, y: 500, w: 80 }, { s: 'Produto', x: 40, y: 480, w: 30 }, { s: 'Saldo', x: 200, y: 480, w: 20 }, { s: 'Ureia', x: 40, y: 468, w: 20 }, { s: '1.000', x: 200, y: 468, w: 20 }]], 'estoque.pdf');
      const original = erpLerBytes; erpLerBytes = async () => lido;
      insLimpar(); insNav = [{ v: 'colar' }]; ir('colar'); await new Promise(r => setTimeout(r, 100));
      const antes = { baixas: erpBaixas().length, msgs: insMensagens().length };
      await erpAnexarBytes(new ArrayBuffer(8), 'estoque.pdf'); await new Promise(r => setTimeout(r, 100));
      erpLerBytes = original;
      const m = insMensagens()[insMensagens().length - 1];
      return { ok: lido.ok, motivo: lido.motivo, baixas: erpBaixas().length - antes.baixas, msgs: insMensagens().length - antes.msgs, prev: !!insUI.prev, texto: document.querySelector('#app').textContent.replace(/\s+/g, ' '), guardou: /Relatório de estoque/.test(m.texto) };
    });
    ok('Agro1 o) Layout desconhecido — "Não reconheci este relatório do Agro1.", nada gravado, texto extraído guardado na trilha de mensagens',
      !O.ok && O.motivo === 'Não reconheci este relatório do Agro1.' && O.baixas === 0 && O.msgs === 1 && O.guardou && !O.prev && /Não reconheci este relatório do Agro1/.test(O.texto), O.motivo + ' · ' + O.baixas + ' baixa(s) · ' + O.msgs + ' mensagem(ns)');
    /* painel (c19) e Cadastros › Insumos › Baixas do Agro1 */
    const PC = await page.evaluate(async () => {
      sessao = { userId: 'u2', papel: 'proprietario', nome: 'Diretoria' }; ritualPuladoSessao = true; ir('painel'); await new Promise(r => setTimeout(r, 200));
      const det = [...document.querySelectorAll('#app details.secao')].find(d => /Conferência Agro1 × Boletim/.test(d.querySelector('summary').textContent));
      if (!det) return { existe: false };
      const out = { existe: true, fechado: !det.open, resumo: det.querySelector('summary .resumo').textContent.trim() };
      det.open = true; const uns = [...det.querySelectorAll('[data-painelun]')];
      out.unidades = uns.map(b => b.querySelector('b').textContent.trim()); out.campos = det.querySelectorAll('.corpo input, .corpo select, .corpo textarea').length; out.alvo = Math.min(...uns.map(b => b.getBoundingClientRect().height));
      uns[0].click(); await new Promise(r => setTimeout(r, 200));
      out.un = { tela: telaAtual, ctx: (document.querySelector('.topo.ctx h1') || {}).textContent.replace(/\s+/g, ' ').trim(), chips: document.querySelectorAll('#app [data-erp-abrir]').length, texto: document.querySelector('#app').textContent.replace(/\s+/g, ' ') };
      const insCard = [...document.querySelectorAll('#app details.secao')].find(d => /Insumos/.test(d.querySelector('summary').textContent));
      ir('painel'); await new Promise(r => setTimeout(r, 150));
      const ins = [...document.querySelectorAll('#app details.secao')].find(d => /^\s*📦\s*Insumos/.test(d.querySelector('summary').textContent.replace(/\s+/g, ' ')));
      out.insTexto = ins ? ins.textContent.replace(/\s+/g, ' ') : '';
      sessao = { userId: 'u3', papel: 'admin', nome: 'Escritório' }; cadNav = [{ v: 'menu' }, { v: 'insumos' }]; cadLimpar(); ir('cadastros'); await new Promise(r => setTimeout(r, 150));
      out.cadInsumos = document.querySelector('#app').textContent.replace(/\s+/g, ' ');
      cadNav = [{ v: 'menu' }, { v: 'insumos' }, { v: 'insbaixas' }]; ir('cadastros'); await new Promise(r => setTimeout(r, 150));
      out.cadBaixas = document.querySelector('#app').textContent.replace(/\s+/g, ' '); out.cadNivel = cadNav.length;
      const item = document.querySelector('#app [data-erp-abrirconf]'); if (item) item.click(); await new Promise(r => setTimeout(r, 200));
      out.abriu = { tela: telaAtual, nav: (insNav[insNav.length - 1] || {}).v }; for (let k = 0; k < 3; k++) { document.querySelector('[data-insvoltar]').click(); await new Promise(r => setTimeout(r, 100)); } out.voltou = telaAtual;
      return out;
    });
    ok('Agro1 2.6) Painel — cartão "🔎 Conferência Agro1 × Boletim" no padrão c19: nasce fechado, resumo neutro na linha, lista só UNIDADES (alvo ≥ 44 px, zero campo)',
      PC.existe && PC.fechado && /1 unidade · 4 para conferir/.test(PC.resumo) && PC.unidades.join() === 'Vereda Romaria' && PC.campos === 0 && PC.alvo >= 44, PC.existe ? PC.resumo + ' · ' + PC.unidades.join(',') : 'cartão não encontrado');
    ok('Agro1 2.6) Painel — o toque abre a TELA da unidade com cabeçalho contextual e a conferência inteira (itens tocáveis), sem nome de pessoa e sem termo proibido',
      PC.existe && PC.un.tela === 'painelun' && /Vereda Romaria/.test(PC.un.ctx) && PC.un.chips >= 4 && !/não fez|não lançou|erro do gerente|pendente|R\$|custo/i.test(PC.un.texto), PC.existe ? PC.un.tela + ' · ' + PC.un.ctx + ' · ' + PC.un.chips + ' chip(s)' : '');
    ok('Agro1 2.6) Painel › cartão "📦 Insumos" — a unidade mostra "baixado no Agro1" ao lado de recebido, aplicado e saldo', /baixado no Agro1/.test(PC.insTexto || ''), (PC.insTexto || '').slice(0, 200));
    ok('Agro1 2.6) Cadastros › Insumos › "🔎 Baixas do Agro1" (nível 3): lista por unidade e competência com link para a conferência; "‹ Voltar" devolve a Cadastros',
      /Baixas do Agro1/.test(PC.cadInsumos) && PC.cadNivel === 3 && /Vereda Romaria · set\/2026/.test(PC.cadBaixas) && /linhas · /.test(PC.cadBaixas) && PC.abriu.tela === 'colar' && PC.abriu.nav === 'erpconf' && PC.voltou === 'cadastros', PC.abriu.tela + '/' + PC.abriu.nav + ' → ' + PC.voltou);
    /* i) resolvidos todos, a pastilha some */
    const I = await page.evaluate(() => {
      erpAbertos().forEach(x => erpResolver(x.id, 'diferentes'));
      return { abertos: erpAbertos().length, past: planPastilhas().map(p => p.txt), notif: typeof Notification === 'undefined' ? 'sem' : 'ok' };
    });
    ok('Agro1 i) Resolvidos os 4 itens em aberto (a linha de 250 kg superada no C3 saiu da conta; a de 300 kg entrou), a pastilha "🔎 … para conferir" some (N = 0); nenhuma notificação push existe no módulo', I.abertos === 0 && !I.past.some(t => /🔎/.test(t)), I.past.join(' | ') || 'sem pastilha');
    estadoErp = await lerD(page);
    errosTodos.push(...erros);
    await ctx.close();
  }
  /* l) o exemplo literal da tarefa: recebido 2.000 kg de ácido bórico + boletim com 100 kg + baixa Agro1 de 1.900 kg dá saldo 100 (não 0) */
  {
    const { page, ctx, erros } = await novaPagina(browser, base, { codigo: CODIGOS.ADMIN, chave: 'ADMIN' }, '2026-09-15T17:00:00-03:00');
    const Lq = await page.evaluate(async base => {
      sessao = { userId: 'u3', papel: 'admin', nome: 'Escritório' };
      D.boletins = D.boletins.filter(b => b.fazendaId !== 'f23');
      D.boletins.push({ id: 'bl1', fazendaId: 'f23', data: '2026-09-06', responsavel: 'Gerente Romaria', clima: { cond: 'Ensolarado', chuvaMm: '' }, mo: { proprios: '', diaristas: '', funcoes: [] },
        atividades: [{ id: 'al1', talhaoId: 't102', tipo: 'Adubação via fertirrigação', pessoas: '2', obs: '', status: '', insProduto: 'Ácido Bórico', insDoseKgHa: String(100 / 22.15), insAreaHa: '22.15' }],
        colheita: [], fito: [], ocorrencias: [], obsGeral: '', pendencias: '', secoes: {}, enviadoEm: '2026-09-06T18:00:00' });
      insRecebimentos().push({ id: 'rec-b', unidade: 'f23', produto: 'Ácido Bórico', kg: 2000, data: '2026-09-01', por: 'Gerente Romaria' });
      salvarDados();
      const antes = insSaldos('f23').find(l => l.nome === 'Ácido Bórico');
      abrirModulo('colar', () => { insLimpar(); insNav = [{ v: 'colar' }]; }); await new Promise(r => setTimeout(r, 100));
      const buf = await (await fetch(base + '/tests/fixtures/erp-ferti-vereda-romaria-2026-09-15.pdf')).arrayBuffer();
      await erpAnexarBytes(buf, 'erp-ferti-vereda-romaria-2026-09-15.pdf');
      const p = insUI.prev; p.glebas.forEach((g, i) => { g.talhaoId = 't10' + (i + 1); }); erpRecalcular(p); erpImportar(); await new Promise(r => setTimeout(r, 100));
      const depois = insSaldos('f23').find(l => l.nome === 'Ácido Bórico');
      return { antes: antes && { aplicado: antes.aplicado, saldo: antes.saldo }, depois: depois && { aplicado: depois.aplicado, saldo: depois.saldo, erp: depois.baixadoErp } };
    }, base);
    ok('Agro1 l) Saldo — recebido 2.000 kg de ácido bórico + boletim com 100 kg + baixa Agro1 de 1.900 kg dá saldo 100 kg (não 0): antes 1.900, depois 100',
      Lq.antes && Math.abs(Lq.antes.saldo - 1900) < 0.01 && Lq.depois && Math.abs(Lq.depois.aplicado - 1900) < 0.01 && Math.abs(Lq.depois.saldo - 100) < 0.01, JSON.stringify(Lq));
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
