#!/usr/bin/env node
/*
 regressao_render.cjs — prova de regressão do Boletim NCNaves.

 Abre o app em um Chromium sem rede (todo pedido externo é bloqueado, como
 um celular offline), entra com códigos de acesso de cada perfil, preenche
 um boletim inteiro por atividade (café, grãos, pecuária, pós-colheita),
 envia, e grava o HTML de cada tela + o resumo WhatsApp + o localStorage
 (rascunho, fila de sincronização). Rodando contra duas versões do app
 (ex.: main e o branch), o diff dos arquivos gerados mostra exatamente o
 que mudou para o usuário.

 Uso:
   python3 -m http.server 8151 --directory <pasta com o index.html antigo> &
   python3 -m http.server 8152 --directory .  &
   node scripts/regressao_render.cjs http://localhost:8151 /tmp/dumps/v51
   node scripts/regressao_render.cjs http://localhost:8152 /tmp/dumps/v52
   diff -r /tmp/dumps/v51 /tmp/dumps/v52

 Precisa do pacote playwright (global) e do Chromium dele. Não é parte do
 app — é só ferramenta de teste.
*/
const fs = require('fs');
const path = require('path');
let pw;
try { pw = require('playwright'); } catch (e) { pw = require('/opt/node22/lib/node_modules/playwright'); }

const base = process.argv[2];
const out = process.argv[3];
const mocks = process.argv[4] ? JSON.parse(fs.readFileSync(process.argv[4], 'utf8')) : null;
if (!base || !out) { console.error('uso: node regressao_render.cjs <url base> <pasta de saída> [mocks.json]'); process.exit(1); }
fs.mkdirSync(out, { recursive: true });

const CODIGOS = { f23: 'VR-7061', f33: 'FM-9028', f26: 'AS-6754', f01: 'AL-4172', DIRETORIA: 'DIRETORIA-8034', ADMIN: 'ADMIN-9561' };
const html = p => p.evaluate(() => document.querySelector('#app').innerHTML);
const abrirDetails = p => p.evaluate(() => document.querySelectorAll('details').forEach(d => { d.open = true; }));
const pausa = (p, ms) => p.waitForTimeout(ms || 200);
async function clique(p, sel) { await abrirDetails(p); await p.click(sel, { timeout: 4000 }); await pausa(p); }
async function preenche(p, sel, v) { await abrirDetails(p); await p.fill(sel, v, { timeout: 4000 }); await pausa(p, 120); }
async function escolhe(p, sel, v) { await abrirDetails(p); await p.selectOption(sel, v, { timeout: 4000 }); await pausa(p); }
async function primeiraOpcao(p, sel) { return p.evaluate(s => { const o = [...document.querySelector(s).options].find(x => x.value && x.value !== 'geral'); return o ? o.value : ''; }, sel); }

async function cenario(browser, nome, acesso, sessao, passos) {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, locale: 'pt-BR', timezoneId: 'America/Sao_Paulo' });
  const chamadas = [];
  await ctx.route('**/*', route => {
    const u = route.request().url();
    if (u.startsWith(base)) return route.continue();
    if (mocks) {
      const hit = Object.keys(mocks).find(k => u.includes(k));
      if (hit) {
        chamadas.push({ metodo: route.request().method(), url: u.replace(/^https?:\/\/[^/]+/, ''), corpo: route.request().postData() || null });
        const m = mocks[hit];
        return route.fulfill({ status: m.status || 200, contentType: 'application/json', body: JSON.stringify(m.body == null ? [] : m.body) });
      }
    }
    return route.abort(); /* sem rede: igual a um celular offline */
  });
  const page = await ctx.newPage();
  const erros = [];
  page.on('pageerror', e => erros.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') erros.push('console: ' + m.text()); });
  /* ids e horas determinísticos para o diff entre versões não acusar o relógio */
  await page.addInitScript(() => { let t = 1700000000000; Date.now = () => (t += 1000); Math.random = () => 0.4242424242; });
  await page.goto(base + '/index.html');
  await page.evaluate(([a, s]) => { localStorage.clear(); localStorage.setItem('bdf:acesso', JSON.stringify(a)); if (s) localStorage.setItem('bdf:sessao', JSON.stringify(s)); }, [acesso, sessao]);
  await page.reload(); await pausa(page, 1500);
  const dumps = {};
  dumps['00-inicio'] = await html(page);
  for (const [rot, fn] of passos) {
    try { await fn(page); await pausa(page, 250); dumps[rot] = await html(page); }
    catch (e) { dumps[rot] = 'FALHOU: ' + String(e).split('\n')[0]; }
  }
  dumps['zz-localStorage'] = await page.evaluate(() => { const o = {}; for (const k of Object.keys(localStorage).sort()) o[k] = localStorage.getItem(k); return o; });
  fs.writeFileSync(path.join(out, nome + '.json'), JSON.stringify({ dumps, erros, chamadas }, null, 1));
  console.log(`${nome}: ${Object.keys(dumps).length} telas, ${erros.length} erro(s) de página${chamadas.length ? ', ' + chamadas.length + ' chamada(s) ao Supabase simulado' : ''}`);
  await ctx.close();
}

(async () => {
  const browser = await pw.chromium.launch();
  const ger = (fz, atv) => ({ userId: 'u1', papel: 'gerente', nome: 'Gerente', atividade: atv, fazendaId: fz });

  /* ☕ café — boletim completo: clima, mão de obra, irrigação + fertirrigação, atividades, colheita, fito, ocorrência, envio, WhatsApp, detalhe */
  await cenario(browser, 'cafe-f23', { codigo: CODIGOS.f23, chave: 'f23' }, ger('f23', 'CAFE'), [
    ['10-form', async p => { await clique(p, '#bt-preencher'); }],
    ['20-clima', async p => { await clique(p, '[data-clima="Ensolarado"]'); await clique(p, '[data-cflor="florada"]'); await preenche(p, 'input[data-c="chuvaMm"]', '12'); await preenche(p, 'input[data-c="obs"]', 'vento fraco'); }],
    ['30-mo', async p => { await clique(p, '[data-step="1"][data-alvo="proprios"]'); await clique(p, '[data-step="1"][data-alvo="proprios"]'); await clique(p, '[data-step="1"][data-alvo="diaristas"]'); }],
    ['40-irrigacao', async p => { await clique(p, '[data-irrst="Rodou normal"]'); await clique(p, '[data-irrag="Máximo"]'); await clique(p, '[data-irrft="Sim"]'); await abrirDetails(p); await p.click('[data-irrfsec] >> nth=0'); await p.click('[data-irrfsec] >> nth=1'); await preenche(p, 'textarea[data-irr="fertReceita"]', '200 kg MAP + 150 kg KCl, 2 tanques'); }],
    ['50-atividade', async p => { await clique(p, '#bt-add-ativ'); const t = await primeiraOpcao(p, 'select[data-a="talhaoId"]'); await escolhe(p, 'select[data-a="talhaoId"]', t); await escolhe(p, 'select[data-a="tipo"]', 'Pulverização'); await preenche(p, 'input[data-a="pessoas"]', '3'); await clique(p, '[data-ast="concluida"]'); await preenche(p, 'textarea[data-a="receita"]', '500 ml Mirus, 1,2 L Priori Top'); await preenche(p, 'input[data-a="tanques"]', '4'); await preenche(p, 'input[data-a="ltanque"]', '2000'); await clique(p, '[data-add-maq]'); await preenche(p, 'input[data-m="nome"]', '13'); await preenche(p, 'input[data-m="horas"]', '6'); }],
    ['55-atividade2', async p => { await clique(p, '#bt-add-ativ'); const sel = 'select[data-a="talhaoId"] >> nth=1'; const t = await p.evaluate(() => { const s = document.querySelectorAll('select[data-a="talhaoId"]')[1]; const o = [...s.options].find(x => x.value && x.value !== 'geral'); return o ? o.value : ''; }); await escolhe(p, sel, t); await escolhe(p, 'select[data-a="tipo"] >> nth=1', 'Calagem / gessagem'); await abrirDetails(p); await p.click('[data-ast="continua"] >> nth=1'); await p.fill('input[data-a="falta"] >> nth=1', '3 ruas do fundo'); }],
    ['60-colheita', async p => { await clique(p, '#bt-add-col'); const t = await primeiraOpcao(p, 'select[data-cc="talhaoId"]'); await escolhe(p, 'select[data-cc="talhaoId"]', t); await clique(p, '[data-cmodo="Mecânica"]'); await preenche(p, 'input[data-cc="carretas"]', '9,5'); await preenche(p, 'input[data-cc="sacas"]', '40'); await clique(p, '[data-cpas="1ª passada"]'); await clique(p, '[data-dest="Terreiro"]'); await preenche(p, 'input[data-cc="cereja"]', '60'); await preenche(p, 'input[data-cc="verde"]', '25'); await preenche(p, 'input[data-cc="seco"]', '15'); }],
    ['70-fito', async p => { await clique(p, '#bt-add-fito'); await clique(p, '[data-ftipo="Praga"]'); await clique(p, '[data-fnome="Broca-do-café"]'); const t = await primeiraOpcao(p, 'select[data-f="talhaoId"]'); await escolhe(p, 'select[data-f="talhaoId"]', t); await clique(p, '[data-fniv="Médio"]'); await preenche(p, 'input[data-f="obs"]', 'amostragem 3%'); }],
    ['80-ocorrencia', async p => { await clique(p, '#bt-add-oc'); await escolhe(p, 'select[data-o="tipo"]', 'Quebra de equipamento'); await clique(p, '[data-ograv="Média"]'); await preenche(p, 'textarea[data-o="texto"]', 'mangueira estourou'); }],
    ['85-obs', async p => { await preenche(p, 'textarea[data-t="obsGeral"]', 'dia normal'); await preenche(p, 'textarea[data-t="pendencias"]', 'terminar setor 3'); }],
    ['90-whats-rascunho', async p => { const txt = await p.evaluate(() => resumoWhats(rascunho)); await p.evaluate(t => { document.querySelector('#app').setAttribute('data-whats', t); }, txt); }],
    ['95-enviado', async p => { await clique(p, '#bt-enviar'); const cx = await p.$('#bt-aviso-confirmar'); if (cx) { await cx.click(); await pausa(p, 300); } }],
    ['96-detalhe', async p => { await p.click('[data-ver] >> nth=0'); }],
    ['97-whats-enviado', async p => { const txt = await p.evaluate(() => resumoWhats(D.boletins[D.boletins.length - 1])); await p.evaluate(t => { document.querySelector('#app').setAttribute('data-whats', t); }, txt); }],
  ]);

  /* 🌾 grãos — operações, irrigação por pivô, fito/ocorrências */
  await cenario(browser, 'graos-f33', { codigo: CODIGOS.f33, chave: 'f33' }, ger('f33', 'GRAOS'), [
    ['10-form', async p => { await clique(p, '#bt-preencher'); }],
    ['20-clima', async p => { await clique(p, '[data-clima="Nublado"]'); await preenche(p, 'input[data-c="chuvaMm"]', '3'); }],
    ['30-operacao', async p => { await clique(p, '#bt-add-ativ'); const t = await primeiraOpcao(p, 'select[data-a="talhaoId"]'); await escolhe(p, 'select[data-a="talhaoId"]', t); await abrirDetails(p); const chip = await p.$('[data-escop]'); if (chip) { await chip.click(); await pausa(p); } }],
    ['40-pivos', async p => { await clique(p, '#bt-add-todos-pivos'); await abrirDetails(p); const st = await p.$('[data-igst$="|Rodou"]'); if (st) { await st.click(); await pausa(p); } const lam = await p.$('input[data-ig="lamina"]'); if (lam) { await lam.fill('8'); await pausa(p); } }],
    ['50-fito', async p => { await clique(p, '#bt-add-fito'); await clique(p, '[data-ftipo="Praga"]'); const t = await primeiraOpcao(p, 'select[data-f="talhaoId"]'); await escolhe(p, 'select[data-f="talhaoId"]', t); await clique(p, '[data-fniv="Baixo"]'); }],
    ['60-ocorr', async p => { await clique(p, '#bt-add-oc'); await escolhe(p, 'select[data-o="tipo"]', 'Quebra de máquina'); await clique(p, '[data-ograv="Baixa"]'); await preenche(p, 'textarea[data-o="texto"]', 'pneu'); }],
    ['90-whats-rascunho', async p => { const txt = await p.evaluate(() => resumoWhats(rascunho)); await p.evaluate(t => { document.querySelector('#app').setAttribute('data-whats', t); }, txt); }],
    ['95-enviado', async p => { await clique(p, '#bt-enviar'); const cx = await p.$('#bt-aviso-confirmar'); if (cx) { await cx.click(); await pausa(p, 300); } }],
  ]);

  /* 🐂 pecuária — movimentação, sanidade, cocho, pasto, observação */
  await cenario(browser, 'pecuaria-f26', { codigo: CODIGOS.f26, chave: 'f26' }, ger('f26', 'PECUARIA'), [
    ['10-form', async p => { await clique(p, '#bt-preencher'); }],
    ['20-clima', async p => { await clique(p, '[data-clima="Ensolarado"]'); }],
    ['30-mov', async p => { await clique(p, '#bt-add-mov-pec'); await clique(p, '[data-mvc="0|tipo|Nascimento"]'); await preenche(p, 'input[data-mv="qtd"]', '2'); }],
    ['40-san', async p => { await clique(p, '#bt-add-san-pec'); await clique(p, '[data-snc="0|problema|Bicheira"]'); await clique(p, '[data-snc="0|acao|Medicou"]'); }],
    ['50-cocho', async p => { await clique(p, '[data-pec-cocho="OK"]'); await clique(p, '[data-pec-agua="OK"]'); }],
    ['60-pasto', async p => { await clique(p, '[data-psc="condicao|No ponto"]'); }],
    ['70-obs', async p => { await preenche(p, 'textarea[data-pec="obs"]', 'tudo em ordem'); }],
    ['90-whats-rascunho', async p => { const txt = await p.evaluate(() => resumoWhats(rascunho)); await p.evaluate(t => { document.querySelector('#app').setAttribute('data-whats', t); }, txt); }],
    ['95-enviado', async p => { await clique(p, '#bt-enviar'); const cx = await p.$('#bt-aviso-confirmar'); if (cx) { await cx.click(); await pausa(p, 300); } }],
  ]);

  /* 🏭 pós-colheita */
  await cenario(browser, 'pos-f23', { codigo: CODIGOS.f23, chave: 'f23' }, { userId: 'u4', papel: 'pos', nome: 'Pós-colheita', fazendaId: 'f23' }, [
    ['10-formpos', async p => { await clique(p, '#bt-preencher-pos'); }],
    ['20-terreiro', async p => { await preenche(p, 'input[data-pt="entradaLatas"]', '300'); }],
  ]);

  /* 📋 diretoria — painel, filtro por fazenda, relatório */
  await cenario(browser, 'diretoria', { codigo: CODIGOS.DIRETORIA, chave: 'DIRETORIA' }, null, [
    ['10-painel-fz', async p => { await p.click('[data-fz="f23"]'); }],
    ['20-relatorio', async p => { await clique(p, '#bt-rel'); }],
  ]);

  /* ⚙️ admin — entrada, painel, cadastros, unidades e plano (v52) */
  await cenario(browser, 'admin', { codigo: CODIGOS.ADMIN, chave: 'ADMIN' }, null, [
    ['10-painel', async p => { await p.click('[data-perfil="admin"]'); }],
    ['20-cadastros', async p => { await clique(p, '#bt-cad'); }],
    ['30-unidplano', async p => { const b = await p.$('#bt-unidplano'); if (!b) throw new Error('sem botão Unidades e Plano (versão antiga)'); await b.click(); await pausa(p, 1500); }],
    ['40-unidplano-fz2', async p => { const chip = await p.$('[data-up="fz"][data-upv="Água Limpa"]'); if (chip) { await chip.click(); await pausa(p, 300); } else { const chips = await p.$$('[data-up="fz"]'); if (chips.length > 1) { await chips[1].click(); await pausa(p, 300); } } }],
    ['50-editar', async p => { const b = await p.$('[data-up="editar"]'); if (b) { await b.click(); await pausa(p, 300); } }],
    ['60-auditar', async p => { const b = await p.$('[data-up="auditar"]'); if (b) { await b.click(); await pausa(p, 1500); } }],
  ]);

  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
