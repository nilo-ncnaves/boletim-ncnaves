#!/usr/bin/env node
/*
 checar-poluicao.cjs — checagem de poluição de tela do Boletim NCNaves.

 É a "DEFINIÇÃO DE PRONTO" do CLAUDE.md (seção PADRÕES DE TELA): roda em
 TODA tarefa que mexa no index.html, antes de abrir o pull request, e o
 resultado (checklist ✅/❌) vai colado no resumo do PR. PR com ❌ novo não
 pode ser aberto — corrige antes. Os ❌ que já existiam estão listados no
 ESTADO.md (seção "Telas × padrões") e vão sendo zerados tarefa a tarefa.

 O que ela faz (tudo sem rede, como um celular offline, largura 390 px):
   1. Renderiza uma unidade de café (f23), uma de grãos (f33), uma de
      pecuária (f26), o boletim de pós-colheita (f23), o painel da
      Diretoria, a tela Relatórios, os Faróis de registro (v60, com linhas de
      exemplo, medidos como Cadastros) e TODOS os níveis de Cadastros (ADMIN).
   2. Mede a altura de cada tela ao abrir: no boletim nenhuma seção pode
      nascer aberta; em Cadastros nenhuma tela acima de 2 alturas (2 × 844 px)
      sem campo de busca.
   3. Abre cada seção de lançamento (as que têm botão "＋") e conta o que
      fica visível: só a lista compacta e o "＋" — nenhum campo, chip ou
      seletor antes do toque em "＋". Exceção definida na v69: o par de
      chips de resposta explícita de ausência ("Nada a registrar hoje" ·
      "Registrar…", container [data-resp-secao]) faz parte do estado
      compacto das seções EVENTUAIS (docs/definicao-de-pronto.md, item 11).
   4. Toca em "＋" e confere o padrão de 3 passos: primeiro só o ONDE
      (chips de talhão/pivô/pasto), nada de campo ou seletor junto.
   5. Procura termos de café nas telas de grãos/pecuária e vice-versa.
      A lista de termos exclusivos vive em docs/catalogos-por-atividade.md,
      seção "Termos exclusivos por atividade" — o script lê de lá.
   6. Confere que toda lista com mais de 12 itens tem busca e que todo
      detalhe tem a ação principal visível sem rolar.
   7. Padrão visual da casa: sem gradiente, sem sombra, sem canto
      arredondado, toque ≥ 44 px — medido no CSS calculado de cada tela.
   8. Texto longo em lista (v68): na tela Relatórios com textos do
      robô-redator semeados, o cartão nasce colapsado (3 linhas, corte
      por linha inteira), cabe em menos de uma tela, deixa o cabeçalho
      "Números" visível sem rolar, copia o texto integral sem expandir,
      e "ler texto completo" abre a folha de tela cheia (cabeçalho fixo,
      ação principal visível, origem completa) e devolve a rolagem.
   9. Ação desabilitada por perfil (v71): no painel da Diretoria e no
      boletim enviado (visto pela Diretoria e pelo gerente das três
      atividades) a ação de outro papel aparece esmaecida em cinza neutro,
      com aria-disabled; o toque mostra "Ação do/da …" sem modal e sem
      mudar de tela; nenhum texto de culpa ("sem permissão", "bloqueado");
      nunca mais da metade das ações da linha; zero na tela de apontamento.
  10. Decisão e confirmação (v72): nenhum confirm()/alert() nativo dispara em
      nenhum cenário; o botão de avanço (Enviar boletim / Enviar registro do
      dia) nasce inativo no formulário vazio com o MESMO visual do botão de
      perfil, o toque mostra o que falta (próxima ação, sem "obrigatório" /
      "esqueceu"), e ele ativa no lugar ao escolher o clima (sem redesenhar);
      "Descartar" abre o diálogo único: pergunta terminada em "?", sem "tem
      certeza", emoji ou exclamação, exatamente dois botões, nenhum campo,
      verbo no afirmativo (até três palavras, nunca Sim/OK/Confirmar) e, por
      ser destrutivo, sem destaque; "Cancelar" fecha sem sair da tela.
  11. Régua de 7 dias (v73): na casa do gerente das três atividades e na
      casa do pós-colheita a régua tem 7 células fixas (sem rolar de lado,
      cada uma ≥ 44 px), dias em português (seg…dom), do mais recente à
      esquerda, nenhum dia futuro, hoje selecionado ao abrir e marcado
      mesmo com outro dia escolhido; o toque troca o dia sem teclado nem
      seletor nativo, sem sair da tela, e o dia sem registro cai no vazio
      da função única (nomeia unidade e dia, sem termo proibido); cabeçalho
      contextual + régua abaixo de 25 % da altura útil; nenhum
      input type=date na tela.
  12. Chips removíveis da multi-seleção (v74): em toda multi-seleção (café:
      problemas da irrigação e setores fertirrigados; grãos: problemas do
      pivô; Cadastros: código combinado) a seleção vazia não desenha nada
      (nem contador zerado, nem área reservada); ao escolher, aparecem o
      contador ("N … selecionados") e um chip por item com × à direita
      (44 × 44 px, rótulo acessível "Remover <nome>"), quebrando em linhas
      sem rolar de lado; mais de 6 itens → 6 + "+K" que expande; o × remove
      na hora sem confirmação, sem nativo e sem sair da tela; o toque no
      corpo do chip não faz nada; remover o último volta ao vazio.

 Uso (na raiz do repositório):
   node scripts/checar-poluicao.cjs                # imprime o checklist
   node scripts/checar-poluicao.cjs /tmp/poluicao  # + grava JSON e o .md
   node scripts/checar-poluicao.cjs --so-resumo    # só a linha final

 Precisa do pacote playwright (global) e do Chromium dele — mesma
 exigência do scripts/regressao_render.cjs. Não é parte do app.
 Sai com código 1 quando há algum ❌ (para servir de trava em CI).
*/
const fs = require('fs');
const path = require('path');
const http = require('http');
let pw;
try { pw = require('playwright'); } catch (e) { pw = require('/opt/node22/lib/node_modules/playwright'); }

const RAIZ = path.resolve(__dirname, '..');
const argv = process.argv.slice(2);
const soResumo = argv.includes('--so-resumo');
const saida = argv.find(a => !a.startsWith('--')) || null;
const VP = { width: 390, height: 844 };   /* iPhone 12–14: largura ≤ 400 px */
const ALVO_TELAS = 2;                       /* altura-alvo: 2 telas */
const TOQUE_MIN = 44;                       /* alvo de toque mínimo, px */
const LISTA_MAX_SEM_BUSCA = 12;
const CODIGOS = { f23: 'VR-7061', f33: 'FM-9028', f26: 'AS-6754', DIRETORIA: 'DIRETORIA-8034', ADMIN: 'ADMIN-9561' };

/* ---------- termos exclusivos por atividade (fonte: docs/catalogos-por-atividade.md) ---------- */
function lerTermos() {
  const md = fs.readFileSync(path.join(RAIZ, 'docs/catalogos-por-atividade.md'), 'utf8').split('\n');
  const ini = md.findIndex(l => /^## .*Termos exclusivos por atividade/i.test(l));
  if (ini < 0) throw new Error('docs/catalogos-por-atividade.md sem a seção "Termos exclusivos por atividade"');
  const termos = {}; let atual = null;
  for (let i = ini + 1; i < md.length; i++) {
    const l = md[i];
    if (/^## /.test(l)) break;
    const h = /^### (Caf[ée]|Gr[ãa]os|Pecu[áa]ria)/i.exec(l);
    if (h) { atual = norm(h[1]).startsWith('caf') ? 'CAFE' : norm(h[1]).startsWith('gra') ? 'GRAOS' : 'PECUARIA'; termos[atual] = termos[atual] || []; continue; }
    if (!atual || !l.trim() || l.trim().startsWith('>') || l.trim().startsWith('<!--')) continue;
    l.split(/[,;·]/).map(t => t.trim()).filter(Boolean).forEach(t => termos[atual].push(t));
  }
  ['CAFE', 'GRAOS', 'PECUARIA'].forEach(a => { if (!termos[a] || !termos[a].length) throw new Error('lista de termos vazia para ' + a); });
  return termos;
}
const norm = s => String(s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');
function acharTermos(texto, lista) {
  const t = ' ' + norm(texto).replace(/[^a-z0-9]+/g, ' ') + ' ';
  return lista.filter(termo => t.includes(' ' + norm(termo).replace(/[^a-z0-9]+/g, ' ') + ' '));
}

/* ---------- servidor estático (só os arquivos do app) ---------- */
function servir(dir) {
  return new Promise(res => {
    const tipos = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.webmanifest': 'application/manifest+json', '.png': 'image/png', '.md': 'text/plain; charset=utf-8', '.txt': 'text/plain; charset=utf-8' };
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

/* ---------- código que roda DENTRO da página ---------- */
const NA_PAGINA = {
  /* medidas gerais da tela como ela abre */
  medir: () => {
    const vis = el => el.getClientRects().length > 0 && getComputedStyle(el).visibility !== 'hidden';
    const app = document.querySelector('#app');
    const acao = [...app.querySelectorAll('.rodape .btn, .cad-rodape .btn, #bt-enviar, #bt-enviar-pos')].find(vis);
    let acaoVisivel = null;
    if (acao) { const r = acao.getBoundingClientRect(); acaoVisivel = r.top >= 0 && r.bottom <= innerHeight; }
    return {
      altura: document.documentElement.scrollHeight,
      largura: document.documentElement.scrollWidth,
      secoesAbertas: [...app.querySelectorAll('details.secao[open]')].map(d => d.querySelector('summary').textContent.trim().split('\n')[0].replace(/\s+/g, ' ').slice(0, 40)),
      subsecoesAbertas: app.querySelectorAll('details.subsec[open]').length,
      temBusca: !!app.querySelector('.cad-busca, input[placeholder^="Buscar"]'),
      itensLista: app.querySelectorAll('.cad-item, .cad-menu, .perfil-btn').length,
      acaoPrincipal: acao ? acao.textContent.trim().replace(/\s+/g, ' ').slice(0, 40) : null,
      acaoVisivel,
      /* formulário visível fora de "Mais opções"/"Zona de cuidado" (a busca não conta) */
      temForm: [...app.querySelectorAll('input:not(.cad-busca):not([type=file]), select, textarea')].filter(vis).length > 0,
      temVoltar: !!app.querySelector('.topo [data-cadvoltar], .topo [data-voltar], .topo #bt-voltar') || [...app.querySelectorAll('.topo button')].some(b => b.textContent.includes('‹')),
      topoFixo: (() => { const t = app.querySelector('.topo'); return !!t && ['sticky', 'fixed'].includes(getComputedStyle(t).position); })(),
      blocosAbertos: [...app.querySelectorAll('details.cad-bloco[open]')].map(d => d.querySelector('summary').textContent.trim().replace(/\s+/g, ' ').slice(0, 30)),
      titulo: (app.querySelector('.topo h1, h1') || {}).textContent || '',
    };
  },
  /* v71: ações desabilitadas por perfil (.acao-off) — visual, acessibilidade, toque, densidade */
  acoesOff: () => {
    const vis = el => el.getClientRects().length > 0 && getComputedStyle(el).visibility !== 'hidden';
    const app = document.querySelector('#app');
    const offs = [...app.querySelectorAll('.acao-off[data-papel]')].filter(vis);
    const linhas = [...new Set(offs.map(b => b.parentElement))];
    const total = linhas.reduce((s, l) => s + [...l.querySelectorAll('button')].filter(vis).length, 0);
    const cores = el => { const cs = getComputedStyle(el); return [cs.color, cs.backgroundColor, cs.borderTopColor].join(' | '); };
    const proibidos = /permiss|negad|autoriz|bloquead|privil|proibid/i;
    let alertas = 0; const alertaOrig = window.alert; window.alert = () => { alertas++; };
    const telaAntes = telaAtual, htmlAntes = app.innerHTML.length;
    const itens = offs.map(b => {
      b.click();
      const conteudo = getComputedStyle(b, '::after').content || '';
      const nota = /^"/.test(conteudo) ? conteudo.slice(1, -1) : '';
      const r = {
        rotulo: b.textContent.trim(), ariaDisabled: b.getAttribute('aria-disabled') === 'true', ariaLabel: b.getAttribute('aria-label') || '',
        temAcao: !!(b.id || Object.keys(b.dataset).some(k => k !== 'papel')), estilo: b.classList.contains('acao-off') ? getComputedStyle(b).borderTopStyle : '',
        cores: cores(b), vermelho: /181, 67, 46/.test(cores(b)), icone: /[\u{1F512}\u{1F6AB}\u{26D4}]/u.test(b.textContent),
        nota, mostrou: b.classList.contains('mostra') && nota.length > 0, proibido: proibidos.test(nota + ' ' + (b.getAttribute('aria-label') || '')),
        modal: !!document.querySelector('dialog[open], #folha-texto'),
      };
      b.click();
      return r;
    });
    window.alert = alertaOrig;
    return { itens, total, alertas, mesmaTela: telaAtual === telaAntes && app.innerHTML.length === htmlAntes, tela: telaAtual };
  },
  /* padrão visual da casa, medido no CSS calculado do que está visível */
  visual: () => {
    const vis = el => el.getClientRects().length > 0 && getComputedStyle(el).visibility !== 'hidden';
    const rot = el => (el.tagName.toLowerCase() + (el.className && typeof el.className === 'string' ? '.' + el.className.trim().split(/\s+/).join('.') : '') + ' "' + (el.textContent || el.placeholder || '').trim().replace(/\s+/g, ' ').slice(0, 24) + '"');
    const app = document.querySelector('#app');
    const out = { raio: [], sombra: [], gradiente: [], toque: [] };
    const junta = (arr, el) => { const r = rot(el); if (!arr.includes(r)) arr.push(r); };
    [...app.querySelectorAll('*')].filter(vis).forEach(el => {
      const cs = getComputedStyle(el);
      if (cs.backgroundImage && cs.backgroundImage.includes('gradient')) junta(out.gradiente, el);
      if (cs.boxShadow && cs.boxShadow !== 'none') junta(out.sombra, el);
      if (el.matches('button, input, select, textarea, .cartao, .secao, .subcartao, .aviso, .cad-item, .cad-menu, .cad-bloco, .chip, .tag, .perfil-btn, img, .farol, .ico') && parseFloat(cs.borderTopLeftRadius) > 0 && el.offsetWidth > 20) junta(out.raio, el);
      if (el.matches('button, input, select, textarea, a[href], summary, .chip, .cad-item, .cad-menu') && !el.matches('input[type=file]')) {
        const b = el.getBoundingClientRect(); if (b.height > 0 && b.height < 44) junta(out.toque, el);
      }
    });
    return out;
  },
  /* seções de lançamento: abre uma a uma e conta o que aparece antes do "＋" */
  secoes: () => {
    const vis = el => el.getClientRects().length > 0 && getComputedStyle(el).visibility !== 'hidden';
    const app = document.querySelector('#app');
    const txt = el => el.textContent.trim().replace(/\s+/g, ' ');
    const inspecionar = (det, nivel) => {
      const corpo = det.querySelector(':scope > .corpo') || det;
      /* v69: o par de chips de resposta explícita de ausência ("Nada a registrar hoje" · "Registrar…", [data-resp-secao])
         faz parte do estado compacto da seção eventual — não é campo de lançamento antes do ＋ */
      const campos = [...corpo.querySelectorAll('input, select, textarea, .chip')].filter(vis).filter(el => !el.closest('[data-resp-secao]')).filter(el => !el.closest('details.subsec, details.fase-op') || el.closest('details.subsec, details.fase-op') === det);
      const botoes = [...corpo.querySelectorAll('button')].filter(vis).filter(b => !b.closest('[data-resp-secao]')).filter(b => !b.classList.contains('chip') && !b.closest('details.subsec') || b.closest('details.subsec') === det);
      const mais = botoes.filter(b => txt(b).startsWith('＋'));
      const outros = botoes.filter(b => !txt(b).startsWith('＋'));
      const camposFora = campos.filter(el => !el.closest('details.subsec') || el.closest('details.subsec') === det);
      return {
        titulo: txt(det.querySelector(':scope > summary')).replace(/›$/, '').trim().slice(0, 48),
        nivel, ehLancamento: mais.length > 0,
        mais: mais.map(txt), camposVisiveis: camposFora.length,
        exemplosCampos: camposFora.slice(0, 5).map(el => el.tagName.toLowerCase() + (el.placeholder ? ' "' + el.placeholder.slice(0, 22) + '"' : el.classList.contains('chip') ? ' "' + txt(el).slice(0, 22) + '"' : '')),
        outrosBotoes: outros.map(txt).slice(0, 6),
        subsecoes: nivel === 1 ? [...det.querySelectorAll('details.subsec')].map(s => { s.open = true; const r = inspecionar(s, 2); s.open = false; return r; }) : [],
      };
    };
    const res = [];
    [...app.querySelectorAll('details.secao')].forEach(det => { det.open = true; res.push(inspecionar(det, 1)); det.open = false; });
    return res;
  },
  /* depois do toque em "＋": o que o cartão novo mostra de uma vez */
  cartaoNovo: (idBotao) => {
    const vis = el => el.getClientRects().length > 0 && getComputedStyle(el).visibility !== 'hidden';
    const app = document.querySelector('#app');
    const bt = app.querySelector(idBotao); if (!bt) return null;
    const det = bt.closest('details'); if (det) { det.open = true; let d2 = det.parentElement.closest('details'); while (d2) { d2.open = true; d2 = d2.parentElement.closest('details'); } }
    const antes = app.querySelectorAll('input, select, textarea, .chip').length;
    bt.click();
    /* o cartão novo é o que apareceu perto do botão (lista logo acima); a seção pode ter sido re-renderizada */
    const bt2 = app.querySelector(idBotao) || bt;
    const lista = bt2.previousElementSibling && bt2.previousElementSibling.matches('div[id^="lista"], div[id^="bloco"]') ? bt2.previousElementSibling : (bt2.parentElement || app);
    const cartao = lista.lastElementChild && lista.lastElementChild.matches('.subcartao, [data-pecmov], [data-pecsan], [data-pecmassa], [data-pecnut], [data-peclote], [data-pecev], [data-irg], [data-fnrow]') ? lista.lastElementChild : lista;
    const q = s => [...cartao.querySelectorAll(s)].filter(vis);
    const labels = q('label').map(l => l.textContent.trim().replace(/\s+/g, ' ').slice(0, 30));
    return {
      botao: bt.textContent.trim().replace(/\s+/g, ' '),
      selects: q('select').length, inputs: q('input:not([type=file]), textarea').length, chips: q('.chip').length,
      rotulos: labels.slice(0, 8), totalRotulos: labels.length,
      primeiroRotulo: labels[0] || '',
      primeiroControle: (() => { const c = [...cartao.querySelectorAll('select, input:not([type=file]), textarea, .chip')].filter(vis)[0]; return c ? (c.classList.contains('chip') ? 'chip' : c.tagName.toLowerCase()) : ''; })(),
      apareceu: app.querySelectorAll('input, select, textarea, .chip').length - antes,
    };
  },
  /* v68: cartão colapsado do texto longo (tela Relatórios com semente) — mede o 1º cartão (texto longo) e o 2º (texto curto) */
  textoLongo: () => {
    const vis = el => el.getClientRects().length > 0 && getComputedStyle(el).visibility !== 'hidden';
    const app = document.querySelector('#app');
    const cartoes = [...app.querySelectorAll('.txt-cartao')];
    const h2 = [...app.querySelectorAll('h2')].find(h => /Números/.test(h.textContent));
    const olhar = c => {
      if (!c) return null;
      const r = c.getBoundingClientRect(), previa = c.querySelector('.txt-previa'), ler = c.querySelector('.txt-ler'), cop = c.querySelector('[data-txtcopiar]');
      const lh = previa ? parseFloat(getComputedStyle(previa).lineHeight) : 0;
      /* último caractere visível da prévia: o corte é por linha inteira se o que vem depois dele é espaço/quebra (ou fim) */
      let corteInteiro = null, ultimo = '';
      if (previa && previa.firstChild && previa.firstChild.nodeType === 3) {
        const tn = previa.firstChild, lim = previa.getBoundingClientRect().top + previa.clientHeight + 0.5, rg = document.createRange(); let ult = -1;
        for (let i = 0; i < tn.length; i++) { rg.setStart(tn, i); rg.setEnd(tn, i + 1); const rr = rg.getBoundingClientRect(); if (rr.height && rr.bottom <= lim) ult = i; }
        ultimo = tn.data.slice(Math.max(0, ult - 20), ult + 1);
        corteInteiro = ult < 0 || ult >= tn.length - 1 || /\s/.test(tn.data[ult + 1]) || /\s/.test(tn.data[ult]);
      }
      const chave = cop && cop.dataset.txtcopiar, o = chave && textosLongos.get(chave);
      return {
        altura: Math.round(r.height), cabe: r.height < innerHeight,
        linhas: previa && lh ? Math.round(previa.clientHeight / lh) : 0, cortado: !!(previa && previa.classList.contains('cortado')),
        lerVisivel: !!(ler && vis(ler)), copiarVisivel: !!(cop && vis(cop)), copiarNaTela: !!(cop && cop.getBoundingClientRect().bottom <= innerHeight),
        copiaIntegral: !!(o && o.texto && (relCache.find(l => 'rel:' + l.id === chave) || {}).texto === o.texto && o.texto.length >= previa.textContent.length), origem: (c.querySelector('.txt-origem') || {}).textContent || '',
        tag: (c.querySelector('.tag') || {}).textContent || '', corteInteiro, ultimo,
        gradiente: !!(previa && (getComputedStyle(previa, '::after').backgroundImage || '').includes('gradient')),
      };
    };
    return { cartoes: cartoes.length, numerosVisivel: !!(h2 && h2.getBoundingClientRect().top < innerHeight), numerosTopo: h2 ? Math.round(h2.getBoundingClientRect().top) : null,
      longo: olhar(cartoes[0]), curto: olhar(cartoes[1]), rodape: /Confira e ajuste antes de mandar/.test(app.innerText), todas: /todas para conferir/.test(app.innerText) };
  },
  /* v68: folha de leitura em tela cheia (fora do #app) */
  folha: () => {
    const f = document.querySelector('#folha-texto'); if (!f) return null;
    const vis = el => el.getClientRects().length > 0 && getComputedStyle(el).visibility !== 'hidden';
    const rot = el => (el.tagName.toLowerCase() + (el.className && typeof el.className === 'string' ? '.' + el.className.trim().split(/\s+/).join('.') : '') + ' "' + (el.textContent || '').trim().replace(/\s+/g, ' ').slice(0, 24) + '"');
    const out = { raio: [], sombra: [], gradiente: [], toque: [] };
    const junta = (arr, el) => { const r = rot(el); if (!arr.includes(r)) arr.push(r); };
    [...f.querySelectorAll('*')].filter(vis).forEach(el => {
      const cs = getComputedStyle(el);
      if (cs.backgroundImage && cs.backgroundImage.includes('gradient')) junta(out.gradiente, el);
      if (cs.boxShadow && cs.boxShadow !== 'none') junta(out.sombra, el);
      if (el.matches('button, .cartao, .tag') && parseFloat(cs.borderTopLeftRadius) > 0 && el.offsetWidth > 20) junta(out.raio, el);
      if (el.matches('button')) { const b = el.getBoundingClientRect(); if (b.height > 0 && b.height < 44) junta(out.toque, el); }
    });
    const topo = f.querySelector('.topo'), acao = f.querySelector('.rodape .btn:not(.sec)'), r = acao && acao.getBoundingClientRect();
    return {
      topoFixo: !!topo && ['sticky', 'fixed'].includes(getComputedStyle(topo).position), temVoltar: !!(topo && [...topo.querySelectorAll('button')].some(b => /‹|Fechar/.test(b.textContent))),
      acaoVisivel: !!(r && r.top >= 0 && r.bottom <= innerHeight), acao: acao ? acao.textContent.trim() : '',
      texto: (f.querySelector('.txt-completo') || {}).textContent || '', origem: (f.querySelector('.txt-origem') || {}).textContent || '', tag: (f.querySelector('.tag') || {}).textContent || '',
      bodyTravado: document.body.classList.contains('folha-aberta'), rola: f.scrollHeight > f.clientHeight, visual: out,
    };
  },
  /* todo o texto que o gerente pode ver na tela (tudo aberto), com placeholders e opções */
  textoTudo: () => {
    const app = document.querySelector('#app');
    app.querySelectorAll('details').forEach(d => { d.open = true; });
    const partes = [app.innerText];
    app.querySelectorAll('[placeholder]').forEach(el => partes.push(el.placeholder));
    app.querySelectorAll('select option, select optgroup').forEach(o => partes.push(o.label || o.textContent));
    app.querySelectorAll('[title]').forEach(el => partes.push(el.title));
    return partes.join('\n');
  },
};

/* v73: régua de 7 dias — medidas na casa do gerente / do pós-colheita */
NA_PAGINA.regua = () => {
  const cels = [...document.querySelectorAll('#app .regua-dia')];
  if (!cels.length) return { existe: false };
  const r = document.querySelector('#app .regua').getBoundingClientRect();
  const hoje = hojeBRT();
  const dias = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];
  return { existe: true, n: cels.length, scrollW: document.documentElement.scrollWidth, larguraRegua: +r.width.toFixed(1),
    minW: Math.min(...cels.map(c => c.getBoundingClientRect().width)), minH: Math.min(...cels.map(c => c.getBoundingClientRect().height)),
    ordem: cels.map(c => c.dataset.regua), futuros: cels.filter(c => c.dataset.regua > hoje).length,
    decrescente: cels.every((c, i) => !i || c.dataset.regua < cels[i - 1].dataset.regua),
    diasPt: cels.every(c => dias.includes(c.querySelector('.ds').textContent.trim())),
    rotulos: cels.map(c => c.querySelector('.ds').textContent.trim()).join(' '),
    hojeSelecionado: (cels.find(c => c.classList.contains('on')) || {}).dataset && cels.find(c => c.classList.contains('on')).dataset.regua === hoje,
    hojeMarcado: cels.some(c => c.classList.contains('hoje') && c.dataset.regua === hoje),
    ariaPressed: cels.every(c => c.getAttribute('aria-pressed') === (c.classList.contains('on') ? 'true' : 'false')),
    conjunto: +r.bottom.toFixed(1), pct: +(r.bottom / innerHeight * 100).toFixed(1), inputsDate: document.querySelectorAll('#app input[type=date]').length };
};
NA_PAGINA.reguaDepois = () => {
  const cels = [...document.querySelectorAll('#app .regua-dia')];
  const on = cels.find(c => c.classList.contains('on')), hj = cels.find(c => c.classList.contains('hoje'));
  const cart = document.querySelector('#app .regua ~ .cartao');
  const texto = cart ? cart.textContent.trim().replace(/\s+/g, ' ') : '';
  return { on: on && on.dataset.regua, hojeAindaMarcado: !!hj && hj.dataset.regua === hojeBRT() && hj !== on,
    hojeBarra: hj ? getComputedStyle(hj).borderBottomWidth : '', texto, temInputDate: !!document.querySelector('#app input[type=date]'),
    foco: document.activeElement ? document.activeElement.tagName : '', tela: telaAtual, nativos: window.__nativos,
    proibido: /n[aã]o fez|n[aã]o realizou|pendente|atrasad|faltou|esqueceu|nada aqui|nenhum dado/i.test(texto),
    nomeiaDia: /\d{2}\/\d{2}\/\d{4}/.test(texto) };
};
async function medirRegua(page) {
  const antes = await page.evaluate(NA_PAGINA.regua);
  if (!antes.existe) return antes;
  await page.click('#app .regua-dia >> nth=1'); await page.waitForTimeout(300);
  antes.depois = await page.evaluate(NA_PAGINA.reguaDepois);
  await page.click('#app .regua-dia >> nth=0'); await page.waitForTimeout(300);
  antes.voltou = await page.evaluate(() => { const on = document.querySelector('#app .regua-dia.on'); return on && on.dataset.regua === hojeBRT(); });
  return antes;
}

/* ---------- cenários ---------- */
async function novaPagina(browser, base, acesso, sessao) {
  const ctx = await browser.newContext({ viewport: VP, locale: 'pt-BR', timezoneId: 'America/Sao_Paulo' });
  await ctx.route('**/*', route => route.request().url().startsWith(base) ? route.continue() : route.abort());
  const page = await ctx.newPage();
  const erros = [];
  page.on('pageerror', e => erros.push(String(e).split('\n')[0]));
  /* pedidos de rede abortados (Supabase) são o esperado offline — não contam como erro */
  page.on('console', m => { if (m.type() === 'error' && !/Failed to load resource|ERR_FAILED|net::/.test(m.text())) erros.push('console: ' + m.text().slice(0, 120)); });
  /* v72: nenhum diálogo nativo pode disparar — conta as chamadas em vez de deixá-las travar a página */
  await ctx.addInitScript(() => { window.__nativos = 0; ['alert', 'confirm', 'prompt'].forEach(k => { window[k] = () => { window.__nativos++; return k === 'confirm' ? true : null; }; }); });
  await page.goto(base + '/index.html');
  await page.evaluate(([a, s]) => { localStorage.clear(); localStorage.setItem('bdf:acesso', JSON.stringify(a)); if (s) localStorage.setItem('bdf:sessao', JSON.stringify(s)); }, [acesso, sessao]);
  await page.reload(); await page.waitForTimeout(900);
  return { page, ctx, erros };
}
const gerente = (fz, atv) => ({ userId: 'u1', papel: 'gerente', nome: 'Gerente', atividade: atv, fazendaId: fz });

/* v74: chips removíveis da multi-seleção — `attr` é o data-* dos chips de opção; `opcoes` são os seletores a tocar.
   Cada toque é um passo separado com espera: a repintura roda um tique depois do toque e, em Cadastros, a tela inteira
   redesenha a cada toque — por isso tudo é consultado de novo no DOM a cada passo. */
const SEL_ESTADO = attr => {
  const box = document.querySelector('.sel-box[data-sel-de="' + attr + '"]'); if (!box) return { existe: false };
  const chips = [...box.querySelectorAll('.chip.sel')], xs = [...box.querySelectorAll('.sel-x')], mais = box.querySelector('.sel-mais'), lista = box.querySelector('.sel-chips');
  return { existe: true, vazio: !box.innerHTML, altura: +box.getBoundingClientRect().height.toFixed(1), display: getComputedStyle(box).display, cont: ((box.querySelector('.sel-cont') || {}).textContent || '').trim(),
    chips: chips.map(c => c.querySelector('.sel-rot').textContent.trim()), n: chips.length, mais: mais ? mais.textContent.trim() : null,
    xMin: xs.length ? +Math.min(...xs.map(x => Math.min(x.getBoundingClientRect().width, x.getBoundingClientRect().height))).toFixed(1) : null,
    aria: xs.map(x => x.getAttribute('aria-label') || ''), scrollW: document.documentElement.scrollWidth, wrap: lista ? getComputedStyle(lista).flexWrap : '',
    rolaLado: lista ? lista.scrollWidth > lista.clientWidth + 1 : false, linhas: new Set(chips.map(c => Math.round(c.getBoundingClientRect().top))).size,
    vermelho: xs.some(x => /181, 67, 46/.test(getComputedStyle(x).color)), sombra: getComputedStyle(box).boxShadow !== 'none' || chips.some(c => getComputedStyle(c).boxShadow !== 'none'),
    gradiente: chips.some(c => /gradient/.test(getComputedStyle(c).backgroundImage)), primeiroX: xs.length ? xs[0].dataset.selRm : null, tela: telaAtual, nativos: window.__nativos };
};
async function medirSelecao(page, attr, opcoes) {
  const est = () => page.evaluate(SEL_ESTADO, attr);
  const toca = async sel => { const ok = await page.evaluate(s => { const el = document.querySelector(s); if (el) el.click(); return !!el; }, sel); await page.waitForTimeout(120); return ok; };
  const r = { antes: await est() };
  if (!r.antes.existe) return { existe: false };
  r.existe = true; r.tela = r.antes.tela; r.nat0 = r.antes.nativos; r.k = 0;
  for (const sel of opcoes) if (await toca(sel)) r.k++;
  r.depois = await est();
  await toca('.sel-box[data-sel-de="' + attr + '"] .sel-rot');           /* corpo do chip: nada acontece */
  r.corpo = await est(); r.corpoTela = r.corpo.tela;
  if (r.depois.mais) { await toca('.sel-box[data-sel-de="' + attr + '"] .sel-mais'); r.expandido = await est(); }
  const val = (r.expandido || r.corpo).primeiroX; const alvoVal = val ? val.slice(attr.length + 1) : null;
  await toca('.sel-box[data-sel-de="' + attr + '"] .sel-x');              /* × do primeiro */
  r.removeu = { est: await est(), opcaoOn: await page.evaluate(([a, v]) => { const o = v === null ? null : document.querySelector('.chip[data-' + a + '="' + CSS.escape(v) + '"]'); return o ? o.classList.contains('on') : null; }, [attr, alvoVal]) };
  r.removeu.tela = r.removeu.est.tela; r.removeu.nativos = r.removeu.est.nativos - r.nat0;
  let guarda = 40; while (guarda-- && await page.evaluate(a => !!document.querySelector('.sel-box[data-sel-de="' + a + '"] .sel-x'), attr)) await toca('.sel-box[data-sel-de="' + attr + '"] .sel-x');
  r.fim = await est(); r.fimTela = r.fim.tela; r.nativos = r.fim.nativos - r.nat0;
  return r;
}

/* v72: validação silenciosa do botão de avanço + diálogo único do "Descartar" (quando houver) */
async function medirDecisao(page, btSel, gatilhoSel, descartarSel) {
  const r = await page.evaluate(sel => {
    const b = document.querySelector(sel); if (!b) return { existe: false };
    const telaAntes = telaAtual, htmlAntes = document.querySelector('#app').innerHTML.length, nat = window.__nativos;
    b.click();
    const conteudo = getComputedStyle(b, '::after').content || '';
    const nota = /^"/.test(conteudo) ? conteudo.slice(1, -1) : '';
    const cs = getComputedStyle(b);
    const r0 = { existe: true, inativo: b.classList.contains('acao-off') && b.getAttribute('aria-disabled') === 'true' && !!b.getAttribute('data-falta'),
      estilo: cs.borderTopStyle, vermelho: /181, 67, 46/.test([cs.color, cs.backgroundColor, cs.borderTopColor].join(' ')), icone: /[\u{1F512}\u{1F6AB}\u{26D4}]/u.test(b.textContent),
      nota, mostrou: b.classList.contains('mostra') && nota.length > 0, proibido: /obrigat|erro de valida|esqueceu|você|faltou|pendente/i.test(nota),
      nativos: window.__nativos - nat };
    b.click(); b.setAttribute('data-marca-teste', '1');   /* 2º toque some a nota; só então compara a tela */
    r0.mesmaTela = telaAtual === telaAntes && document.querySelector('#app').innerHTML.length === htmlAntes + ' data-marca-teste="1"'.length;
    return r0;
  }, btSel);
  if (!r.existe) return r;
  /* satisfaz a pré-condição pela tela (chip de clima / lata do terreiro) e olha o botão sem redesenhar */
  /* pelo DOM (a seção pode estar fechada): chip → click(); campo → valor + evento input, como a digitação */
  await page.evaluate(sel => { const g = document.querySelector(sel); if (!g) return;
    if (g.tagName === 'INPUT') { g.value = '300'; g.dispatchEvent(new Event('input', { bubbles: true })); } else g.click(); }, gatilhoSel);
  await page.waitForTimeout(250);
  r.depois = await page.evaluate(sel => { const b = document.querySelector(sel); return b ? { ativo: !b.classList.contains('acao-off') && !b.getAttribute('aria-disabled') && !b.getAttribute('data-falta'), noLugar: b.getAttribute('data-marca-teste') === '1' } : null; }, btSel);
  if (descartarSel) {
    await page.evaluate(sel => { const b = document.querySelector(sel); if (b) b.click(); }, descartarSel); await page.waitForTimeout(200);
    r.dialogo = await page.evaluate(() => {
      const d = document.querySelector('#dialogo'); if (!d) return null;
      const bts = [...d.querySelectorAll('button')], sim = d.querySelector('#bt-dialogo-sim'), nao = d.querySelector('#bt-dialogo-nao');
      const pergunta = (d.querySelector('.pergunta') || {}).textContent || '';
      const verde = el => /47, 82, 51/.test(getComputedStyle(el).backgroundColor);
      return { botoes: bts.length, campos: d.querySelectorAll('input, select, textarea').length, pergunta, terminaInterrogacao: /\?\s*$/.test(pergunta),
        temCerteza: /tem certeza|!|[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/u.test(pergunta), produto: /produto|dose|custo/i.test(pergunta),
        sim: sim ? sim.textContent.trim() : '', nao: nao ? nao.textContent.trim() : '', simGenerico: /^(sim|ok|confirmar|continuar)$/i.test(sim ? sim.textContent.trim() : ''),
        simPalavras: sim ? sim.textContent.trim().split(/\s+/).length : 0, simDestaque: sim ? verde(sim) : false, naoDestaque: nao ? verde(nao) : false, papel: d.getAttribute('role'), modal: d.getAttribute('aria-modal') };
    });
    await page.click('#bt-dialogo-nao').catch(() => {}); await page.waitForTimeout(150);
    r.fechou = await page.evaluate(() => ({ aberto: !!document.querySelector('#dialogo'), tela: telaAtual }));
  }
  return r;
}
async function medirTela(page, nome, grupo, extra) {
  const m = await page.evaluate(NA_PAGINA.medir);
  const v = await page.evaluate(NA_PAGINA.visual);
  return Object.assign({ nome, grupo, telas: +(m.altura / VP.height).toFixed(2) }, m, { visual: v }, extra || {});
}

/* v63: linhas de exemplo no formato de vw_status_integracoes (uma fonte em dia, outra sem sucesso há 30 h,
   para a variante "velho" aparecer). Horários em UTC, como a visão manda. */
const statusIntegracoesExemplo = () => {
  const agora = Date.now(), t = ms => new Date(agora - ms).toISOString(), dia = ms => new Date(agora - ms).toISOString().slice(0, 10);
  return [
    { fonte: 'icrop', ultima_execucao_em: t(2 * 36e5), ultima_execucao_ok_em: t(2 * 36e5), ultimo_dado_em: t(2 * 36e5), ultimo_dado_origem: dia(0), horas_desde_ultimo_sucesso: 2 },
    { fonte: 'solinftec', ultima_execucao_em: t(1 * 36e5), ultima_execucao_ok_em: t(30 * 36e5), ultimo_dado_em: t(30 * 36e5), ultimo_dado_origem: dia(864e5), horas_desde_ultimo_sucesso: 30 },
  ];
};

/* v68: linhas de exemplo de relatorios_gerados — um texto LONGO (devolutiva, f33) e um CURTO (alerta, f26) do
   robô-redator, mais números (farol_7 nas duas unidades "para conferir" → "todas para conferir"; farol_30 em dia).
   Datas relativas a hoje para caírem no recorte da tela. */
const relatoriosExemplo = () => {
  const d = n => { const x = new Date(); x.setDate(x.getDate() - n); return x.toISOString().slice(0, 10); };
  const em = new Date(d(0) + 'T05:35:00-03:00');   /* 05:35 de Brasília, como o robô grava */
  const longo = ['Floramill — devolutiva da semana de ' + d(7).slice(8) + '/' + d(7).slice(5, 7) + ' a ' + d(1).slice(8) + '/' + d(1).slice(5, 7),
    '',
    'Boletins: a unidade registrou boletim em 5 dos 6 dias úteis da semana. O dia sem registro foi a quarta-feira; o boletim de quinta trouxe as operações dos dois dias, o que mantém o histórico completo para a Diretoria.',
    '',
    'Irrigação: os pivôs 01, 02 e 03 informaram lâmina nos quatro dias em que o iCrop mediu irrigação. No pivô 04 o boletim marcou "Rodou" na terça-feira e o iCrop não registrou lâmina naquele dia — ponto para conferir com o gerente, sem conclusão sobre o que aconteceu no campo.',
    '',
    'Máquinas: a Solinftec mediu 41 horas de motor na semana e o boletim apontou 38 horas nas operações de plantio e pulverização. A diferença de 3 horas está dentro do esperado para deslocamento e abastecimento.',
    '',
    'Clima: 12 mm de chuva acumulados, coerentes com o pluviômetro do iCrop (11 mm).',
    '',
    'Pontos para a conversa da semana: confirmar a irrigação do pivô 04 na terça-feira e lembrar que o boletim de quarta pode ser enviado no dia seguinte, sem prejuízo.'].join('\n');
  const curto = 'Água Santa — ' + d(1).slice(8) + '/' + d(1).slice(5, 7) + ': boletim e medição batem; sem ponto para conferir hoje.';
  const base = { gerado_em: em.toISOString(), texto_em: em.toISOString(), texto_modelo: 'claude-sonnet-4-6' };
  return [
    { id: 'ex-txt-1', relatorio: 'devolutiva_semanal', periodo_ini: d(7), periodo_fim: d(1), unidade_id: 'f33', dados: { composto: true, fontes: [] }, texto: longo, ...base },
    { id: 'ex-txt-2', relatorio: 'alerta_divergencia', periodo_ini: d(1), periodo_fim: d(1), unidade_id: 'f26', dados: { composto: true, fontes: [] }, texto: curto, ...base },
    { id: 'ex-num-1', relatorio: 'farol_7', periodo_ini: d(7), periodo_fim: d(1), unidade_id: 'f33', dados: { em_dia: false, enviados: 5, uteis: 6, marcas: '●●○●●●' }, gerado_em: em.toISOString(), texto: null },
    { id: 'ex-num-2', relatorio: 'farol_7', periodo_ini: d(7), periodo_fim: d(1), unidade_id: 'f26', dados: { em_dia: false, enviados: 4, uteis: 6, marcas: '●○○●●●' }, gerado_em: em.toISOString(), texto: null },
    { id: 'ex-num-3', relatorio: 'farol_30', periodo_ini: d(30), periodo_fim: d(1), unidade_id: 'f33', dados: { em_dia: true, enviados: 24, uteis: 26, marcas: '' }, gerado_em: em.toISOString(), texto: null },
  ];
};

async function cenarioBoletim(browser, base, R, rot, fz, atv, termos) {
  const { page, ctx, erros } = await novaPagina(browser, base, { codigo: CODIGOS[fz], chave: fz }, gerente(fz, atv));
  /* v63: dado de integração do dia + estado dos robôs, para os cartões iCrop/Solinftec e a linha
     "Dados do iCrop de hoje, 04:05" entrarem na medição. v64: café também (decisão do Nilo, 08/09/2026). */
  {
    await page.evaluate(([f, st]) => {
      const hoje = hojeISO();
      statusIntegracoes = st;
      D.solinftecDados = [{ fazenda_id: f, data: hoje, equipamento: 'Trator 01', operacao: 'Operação 205', talhao: '', horas: 3.2, area_ha: 12, consumo_l: 40 }];
      if (temCultura(f, 'GRAOS')) D.icropDados = [{ fazenda: 'NC Naves - Floramill', equipamento: 'Pivô 01', parcela: 'Gleba A', data: hoje, atualizado_em: new Date().toISOString(), irrigacao_mm: 4.2, precipitacao_mm: 0, etc: 3, eto: 4 }];
      ir('casa');
    }, [fz, statusIntegracoesExemplo()]);
    await page.waitForTimeout(300);
  }
  const casa = await medirTela(page, rot + ' — casa do gerente', 'gerente');
  casa.regua = await medirRegua(page);   /* v73 */
  await page.click('#bt-preencher'); await page.waitForTimeout(400);
  const form = await medirTela(page, rot + ' — boletim (ao abrir)', 'boletim', { atividade: atv });
  form.secoes = await page.evaluate(NA_PAGINA.secoes);
  /* v72: ainda com o formulário vazio — Enviar inativo, toque explica, clima ativa no lugar; Descartar abre o diálogo único */
  form.decisao = await medirDecisao(page, '#bt-enviar', '[data-clima]', '#bt-descartar');
  /* toca em cada "＋" (um por seção/subseção) e olha o cartão novo */
  /* "＋ adicionar todos os pivôs" é ação em massa, não abre cartão — fica de fora */
  const ids = await page.evaluate(() => [...document.querySelectorAll('#app details.secao button')].filter(b => b.textContent.trim().startsWith('＋') && b.id && !/todos/i.test(b.textContent)).map(b => '#' + b.id));
  form.cartoes = [];
  for (const id of ids) {
    const c = await page.evaluate(NA_PAGINA.cartaoNovo, id).catch(e => ({ botao: id, erro: String(e).split('\n')[0] }));
    await page.waitForTimeout(150);
    if (c) form.cartoes.push(Object.assign({ id }, c));
  }
  /* pecuária: as pastagens têm select "Outro…"; grãos: escolher um talhão para ver o 2º passo */
  form.texto = await page.evaluate(NA_PAGINA.textoTudo);
  const outras = { CAFE: ['GRAOS', 'PECUARIA'], GRAOS: ['CAFE', 'PECUARIA'], PECUARIA: ['CAFE', 'GRAOS'] }[atv];
  form.termosAlheios = {};
  outras.forEach(o => { form.termosAlheios[o] = acharTermos(form.texto, termos[o]); });
  form.termosProprios = acharTermos(form.texto, termos[atv]).length;
  form.erros = erros.slice();
  form.acoesOffForm = await page.evaluate(() => document.querySelectorAll('#app .acao-off[data-papel]').length);
  /* v74: chips removíveis das multi-seleções do boletim (café: problemas da irrigação e setores fertirrigados; grãos:
     problemas do pivô — precisa de um pivô lançado com "Não rodou"; pecuária: não tem multi-seleção — nada a medir) */
  form.selecoes = [];
  await page.evaluate(() => document.querySelectorAll('#app details').forEach(d => { d.open = true; }));
  if (atv === 'CAFE') {
    await page.evaluate(() => { const b = document.querySelector('[data-irrst="Rodou com problema"]'); if (b) b.click(); }); await page.waitForTimeout(100);
    form.selecoes.push(Object.assign({ nome: 'Irrigação › Qual foi o problema? (2 de 8)' }, await medirSelecao(page, 'irrpb', ['[data-irrpb="Bomba"]', '[data-irrpb="Filtro"]'])));
    await page.evaluate(() => { const b = document.querySelector('[data-irrft="Sim"]'); if (b) b.click(); }); await page.waitForTimeout(100);
    const setores = await page.evaluate(() => [...document.querySelectorAll('[data-irrfsec]')].map(c => '[data-irrfsec="' + c.dataset.irrfsec + '"]'));
    form.selecoes.push(Object.assign({ nome: `Irrigação › Fertirrigação › Em quais setores? (${setores.length} de ${setores.length})` }, await medirSelecao(page, 'irrfsec', setores)));
  }
  if (atv === 'GRAOS') {
    await page.evaluate(() => { const b = [...document.querySelectorAll('#app details.secao button')].find(x => /todos os piv/i.test(x.textContent)); if (b) b.click(); }); await page.waitForTimeout(300);
    await page.evaluate(() => { const s = document.querySelector('[data-igst$="|Não rodou"]'); if (s) s.click(); }); await page.waitForTimeout(200);
    const probs = await page.evaluate(() => [...document.querySelectorAll('[data-igpb]')].slice(0, 2).map(c => '[data-igpb="' + c.dataset.igpb.replace(/"/g, '\\"') + '"]'));
    form.selecoes.push(Object.assign({ nome: 'Irrigação (pivôs) › Qual foi o problema? (2 de 6)' }, await medirSelecao(page, 'igpb', probs)));
  }
  R.telas.push(casa, form);
  /* v71: boletim enviado visto pelo gerente — "Marcar como visto" (ação da Diretoria) aparece desabilitado */
  await page.evaluate(f => {
    const hoje = hojeISO();
    D.boletins.push({ id: 'ex-det-' + f, exemplo: true, data: hoje, fazendaId: f, responsavel: 'Exemplo', enviadoEm: hoje + ' 18:00',
      clima: { cond: 'Sol', chuvaMm: 0 }, mo: { proprios: 2, diaristas: 0, faltas: 0, horasExtras: 0, funcoes: [] }, atividades: [], colheita: [], fito: [], ocorrencias: [] });
    ir('detalhe', 'ex-det-' + f);
  }, fz); await page.waitForTimeout(300);
  const det = await medirTela(page, rot + ' — boletim enviado (gerente)', 'gerente');
  det.acoesOff = await page.evaluate(NA_PAGINA.acoesOff);
  det.nativos = await page.evaluate(() => window.__nativos);
  R.telas.push(det);
  await ctx.close();
}

async function cenarioPos(browser, base, R, termos) {
  const { page, ctx, erros } = await novaPagina(browser, base, { codigo: CODIGOS.f23, chave: 'f23' }, { userId: 'u4', papel: 'pos', nome: 'Pós-colheita', fazendaId: 'f23' });
  const casaPos = await medirTela(page, 'Pós-colheita (f23) — casa', 'gerente');   /* v73: régua na casa do pós */
  casaPos.regua = await medirRegua(page);
  casaPos.erros = erros.slice();
  R.telas.push(casaPos);
  await page.click('#bt-preencher-pos').catch(() => {}); await page.waitForTimeout(400);
  const form = await medirTela(page, 'Pós-colheita (f23) — registro (ao abrir)', 'boletim', { atividade: 'CAFE' });
  form.secoes = await page.evaluate(NA_PAGINA.secoes);
  form.cartoes = [];
  form.texto = await page.evaluate(NA_PAGINA.textoTudo);
  form.termosAlheios = { GRAOS: acharTermos(form.texto, termos.GRAOS), PECUARIA: acharTermos(form.texto, termos.PECUARIA) };
  form.erros = erros.slice();
  form.decisao = await medirDecisao(page, '#bt-enviar-pos', 'input[data-pt="entradaLatas"]', null);
  R.telas.push(form);
  await ctx.close();
}

async function cenarioDiretoria(browser, base, R) {
  const { page, ctx, erros } = await novaPagina(browser, base, { codigo: CODIGOS.DIRETORIA, chave: 'DIRETORIA' }, null);
  await page.click('[data-perfil="proprietario"]').catch(() => {}); await page.waitForTimeout(500);
  /* v64: medição de ontem (iCrop e Solinftec) + estado dos robôs, para os cartões do painel e a linha de origem entrarem na medição */
  await page.evaluate(st => {
    const ontem = ontemISO();
    statusIntegracoes = st;
    D.solinftecDados = [{ fazenda_id: 'f33', data: ontem, equipamento: 'Trator 01', operacao: 'Operação 205', talhao: '', horas: 3.2, area_ha: 12, consumo_l: 40 }];
    D.icropDados = [{ fazenda: 'NC Naves - Floramill', equipamento: 'Pivô 01', parcela: 'Gleba A', data: ontem, atualizado_em: new Date().toISOString(), irrigacao_mm: 4.2, precipitacao_mm: 0, etc: 3, eto: 4 }];
    ir('painel');
  }, statusIntegracoesExemplo()); await page.waitForTimeout(300);
  const painel = await medirTela(page, 'Diretoria — painel', 'diretoria');
  painel.acoesOff = await page.evaluate(NA_PAGINA.acoesOff);   /* v71: "⚙ Cadastros" do administrador, desabilitado */
  R.telas.push(painel);
  /* v71: boletim enviado visto pela Diretoria — "Corrigir" (ação do gerente) aparece desabilitado */
  await page.evaluate(() => ir('detalhe', (D.boletins.find(b => b.fazendaId === 'f22c') || D.boletins[0] || {}).id)); await page.waitForTimeout(300);
  const det = await medirTela(page, 'Diretoria — boletim enviado', 'diretoria');
  det.acoesOff = await page.evaluate(NA_PAGINA.acoesOff);
  R.telas.push(det);
  await page.evaluate(() => ir('relatorios')); await page.waitForTimeout(300);
  R.telas.push(await medirTela(page, 'Diretoria — Relatórios', 'diretoria'));
  /* v68: textos do robô-redator semeados — cartão colapsado, "Números" sem rolar, folha de leitura, rolagem devolvida */
  await page.evaluate(ex => { relCache = ex; ir('relatorios'); }, relatoriosExemplo()); await page.waitForTimeout(300);
  const relTx = await medirTela(page, 'Diretoria — Relatórios (com textos do redator)', 'diretoria');
  relTx.textoLongo = await page.evaluate(NA_PAGINA.textoLongo);
  relTx.antesY = await page.evaluate(() => { window.scrollTo(0, 120); return window.scrollY; });
  await page.click('#app .txt-ler >> nth=0').catch(() => {}); await page.waitForTimeout(250);
  relTx.folha = await page.evaluate(NA_PAGINA.folha);
  relTx.folhaVisual = relTx.folha ? relTx.folha.visual : null;
  await page.click('#bt-folha-fechar').catch(() => {}); await page.waitForTimeout(250);
  relTx.depois = await page.evaluate(() => ({ y: window.scrollY, folha: !!document.querySelector('#folha-texto'), travado: document.body.classList.contains('folha-aberta') }));
  R.telas.push(relTx);
  await page.evaluate(() => { relCache = []; window.scrollTo(0, 0); });
  await page.evaluate(() => ir('relatorio')); await page.waitForTimeout(300);
  R.telas.push(await medirTela(page, 'Diretoria — Resumo do período', 'diretoria'));
  /* Faróis de registro (v60): tela nova da Diretoria, medida com os padrões de Cadastros (P1–P10).
     Offline não há visão baixada, então a página recebe linhas de exemplo no formato de vw_farol_registro. */
  await page.evaluate(() => {
    const OPS = {
      PECUARIA: [['PEC-SUPLEMENTACAO', 'Suplementação (sal mineral / proteinado / ração)', 7, 3], ['PEC-CONTAGEM', 'Contagem', 30, 10], ['PEC-VACINACAO', 'Vacinação (especificar)', 180, 30], ['PEC-ROCADA', 'Roçada', null, null]],
      GRAOS: [['GRAOS-MONITORAMENTO_DE_PRAGAS_E_DOENCAS', 'Monitoramento de pragas e doenças', 7, 3], ['GRAOS-FUNGICIDA', 'Fungicida', null, null]],
      /* v65: café entra sem janela (decisão da v60) — a unidade aparece no fim da lista e a tela dela mostra só "Operações sem janela" */
      CAFE: [['CAFE-ADUBACAO_VIA_LANCO', 'Adubação via lanço', null, null], ['CAFE-PULVERIZACAO', 'Pulverização', null, null], ['CAFE-DESBROTA', 'Desbrota', null, null]],
    };
    const EX = [[0, 'verde', 'registrado hoje'], [12, 'amarelo', 'sem registro há 12 dias · janela aberta, fecha em 2 dias'], [47, 'vermelho', 'sem registro há 47 dias · janela fechada há 7 dias'], [3, 'verde', 'registrado há 3 dias']];
    farolCache = D.fazendas.filter(f => temCultura(f.id, 'GRAOS') || temCultura(f.id, 'PECUARIA') || temCultura(f.id, 'CAFE')).flatMap((f, k) => {
      const atv = temCultura(f.id, 'PECUARIA') ? 'PECUARIA' : temCultura(f.id, 'GRAOS') ? 'GRAOS' : 'CAFE';
      return OPS[atv].map(([id, nome, c, tol], i) => { const e = EX[(i + k) % 4]; return { unidade_id: f.id, operacao_id: id, atividade: atv, operacao_nome: nome, fase: null, data_ultimo_registro: '2026-08-20', dias_sem_registro: e[0], nunca_registrado: false, primeiro_boletim: '2026-07-01', cadencia_dias: c, tolerancia_dias: tol, janela_origem: c ? 'proposta' : null, farol: c ? e[1] : null, fecha_em_dias: c ? 2 : null, situacao: c ? e[2] : null }; });
    });
    farolBaixadoEm = '2026-09-07T12:00:00Z';
    /* v62: ritmo observado (vw_ritmo_operacoes) — linhas de exemplo (v65: nas três atividades); a 2ª operação de cada unidade fica sem intervalo (linha omitida) */
    ritmoCache = farolCache.map((l, i) => ({ unidade_id: l.unidade_id, operacao_id: l.operacao_id, atividade: l.atividade, qtd_registros: i % 2 ? 1 : 6, qtd_intervalos: i % 2 ? 0 : 5, intervalo_mediano_dias: i % 2 ? null : 7 + (i % 3) * 5, intervalo_minimo_dias: i % 2 ? null : 5, intervalo_maximo_dias: i % 2 ? null : 30, data_ultimo_registro: '2026-08-20' }));
    ir('farois');
  }); await page.waitForTimeout(300);
  R.telas.push(await medirTela(page, 'Diretoria › Faróis de registro', 'cadastros', { tipo: 'lista', niveis: 2 }));
  const unFarol = await page.evaluate(() => (D.fazendas.find(f => temCultura(f.id, 'PECUARIA')) || {}).id || '');
  await page.evaluate(u => ir('farol', u), unFarol); await page.waitForTimeout(300);
  R.telas.push(await medirTela(page, 'Diretoria › Faróis › unidade', 'cadastros', { tipo: 'detalhe', niveis: 3 }));
  /* v65: unidade de café (sem janela): vazio pela função única + bloco "Operações sem janela" fechado, com dias sem registro e ritmo */
  const unFarolCafe = await page.evaluate(() => (D.fazendas.find(f => temCultura(f.id, 'CAFE')) || {}).id || '');
  await page.evaluate(u => ir('farol', u), unFarolCafe); await page.waitForTimeout(300);
  R.telas.push(await medirTela(page, 'Diretoria › Faróis › unidade (café)', 'cadastros', { tipo: 'detalhe', niveis: 3 }));
  R.errosDiretoria = erros.slice();
  await ctx.close();
}

async function cenarioCadastros(browser, base, R) {
  const { page, ctx, erros } = await novaPagina(browser, base, { codigo: CODIGOS.ADMIN, chave: 'ADMIN' }, null);
  await page.click('[data-perfil="admin"]').catch(() => {}); await page.waitForTimeout(400);
  /* v63: estado dos robôs (vw_status_integracoes) para o bloco de leitura de Integrações e robôs aparecer preenchido */
  await page.evaluate(st => { statusIntegracoes = st; }, statusIntegracoesExemplo());
  const ids = await page.evaluate(() => ({
    fz: D.fazendas[0].id, tal: D.talhoes[0].id,
    grao: (D.talhoes.find(t => t.tipo === 'GRAO_ANUAL') || {}).id || '',
    pec: (D.fazendas.find(f => temCultura(f.id, 'PECUARIA')) || {}).id || '',
    plano: Object.keys(PLANO_FAZENDA_APP)[0],
  }));
  const niveis = [
    ['Cadastros — menu', [{ v: 'menu' }], 'lista'],
    ['Cadastros › Fazendas e unidades', [{ v: 'fazendas' }], 'lista'],
    ['Cadastros › Fazendas › detalhe', [{ v: 'fazendas' }, { v: 'fazenda', id: ids.fz }], 'detalhe'],
    ['Cadastros › Talhões, pivôs e pastos', [{ v: 'talhoes' }], 'lista'],
    ['Cadastros › Talhões › detalhe', [{ v: 'talhoes' }, { v: 'talhao', id: ids.tal }], 'detalhe'],
    ['Cadastros › Talhões › novo', [{ v: 'talhoes' }, { v: 'talhao', id: 'novo' }], 'detalhe'],
    ['Cadastros › Ciclos e plantios', [{ v: 'ciclos' }], 'lista'],
    ['Cadastros › Ciclos › detalhe', [{ v: 'ciclos' }, { v: 'ciclo', id: ids.grao }], 'detalhe'],
    ['Cadastros › Lotes e inventário', [{ v: 'lotes' }], 'lista'],
    ['Cadastros › Lotes › detalhe', [{ v: 'lotes' }, { v: 'lote', id: ids.pec }], 'detalhe'],
    ['Cadastros › Plano do mês', [{ v: 'plano' }], 'lista'],
    ['Cadastros › Plano › fazenda', [{ v: 'plano' }, { v: 'planofz', id: ids.plano }], 'detalhe'],
    ['Cadastros › Códigos de acesso', [{ v: 'codigos' }], 'lista'],
    ['Cadastros › Códigos › detalhe', [{ v: 'codigos' }, { v: 'codigo', id: ids.fz }], 'detalhe'],
    ['Cadastros › Códigos › novo combinado', [{ v: 'codigos' }, { v: 'codigonovo' }], 'detalhe'],
    ['Cadastros › Catálogos', [{ v: 'catalogos' }], 'lista'],
    ['Cadastros › Catálogos › Café', [{ v: 'catalogos' }, { v: 'catalogo', id: 'CAFE' }], 'lista'],
    ['Cadastros › Catálogos › Grãos', [{ v: 'catalogos' }, { v: 'catalogo', id: 'GRAOS' }], 'lista'],
    ['Cadastros › Catálogos › Pecuária', [{ v: 'catalogos' }, { v: 'catalogo', id: 'PECUARIA' }], 'lista'],
    ['Cadastros › Catálogos › Máquinas', [{ v: 'catalogos' }, { v: 'maquinas' }], 'lista'],
    ['Cadastros › Catálogos › Insumos', [{ v: 'catalogos' }, { v: 'insumos' }], 'lista'],
    ['Cadastros › Integrações e robôs', [{ v: 'integracoes' }], 'detalhe'],
    ['Cadastros › Importações manuais', [{ v: 'importacoes' }], 'lista'],
    ['Cadastros › Sincronização e dados', [{ v: 'sync' }], 'detalhe'],
    ['Cadastros › Sobre', [{ v: 'sobre' }], 'lista'],
  ];
  for (const [nome, pilha, tipo] of niveis) {
    await page.evaluate(p => { cadNav = [{ v: 'menu' }]; cadLimpar(); p.filter(x => x.v !== 'menu').forEach(x => cadNav.push(x)); if (p.length && p[p.length - 1].v === 'codigonovo') novoCombo = { ativs: [], unis: [] }; ir('cadastros'); }, pilha);
    await page.waitForTimeout(250);
    R.telas.push(await medirTela(page, nome, 'cadastros', { tipo, niveis: pilha.length }));
  }
  await page.evaluate(() => ir('importar')); await page.waitForTimeout(250);
  R.telas.push(await medirTela(page, 'Escritório › Importar telemetria', 'cadastros', { tipo: 'detalhe', niveis: 3 }));
  /* v74: chips removíveis na multi-seleção de Cadastros › Códigos › novo combinado (9 unidades → 6 + "+3"; a tela redesenha a cada toque) */
  await page.evaluate(() => { cadNav = [{ v: 'menu' }, { v: 'codigos' }, { v: 'codigonovo' }]; novoCombo = { ativs: [], unis: [] }; ir('cadastros'); }); await page.waitForTimeout(250);
  const unis = await page.evaluate(() => D.fazendas.slice(0, 9).map(f => '[data-combo-uni="' + f.id + '"]'));
  const combo = await medirSelecao(page, 'combo-uni', unis);
  combo.nome = 'Unidades avulsas (9 de ' + await page.evaluate(() => D.fazendas.length) + ')';
  const cadTela = R.telas.find(t => t.nome === 'Cadastros › Códigos › novo combinado');
  if (cadTela) cadTela.selecoes = [combo];
  R.errosCadastros = erros.slice();
  await ctx.close();
}

/* ---------- avaliação: transforma medidas em ✅/❌ ---------- */
function avaliar(R) {
  const itens = []; /* {grupo, nome, ok, detalhe} */
  const add = (grupo, nome, ok, detalhe) => itens.push({ grupo, nome, ok: !!ok, detalhe: detalhe || '' });
  const boletins = R.telas.filter(t => t.grupo === 'boletim');
  const cads = R.telas.filter(t => t.grupo === 'cadastros');

  /* 1. renderização a ≤ 400 px, sem erro e sem rolagem lateral */
  R.telas.forEach(t => add('1. Renderiza a ≤ 400 px', t.nome, t.largura <= VP.width && !(t.erros || []).length,
    t.largura > VP.width ? `rola de lado: ${t.largura} px de largura` : (t.erros || []).length ? 'erro de página: ' + t.erros[0] : `${t.largura} px`));

  /* 2. altura ao abrir */
  boletins.forEach(t => add('2. Altura ao abrir', t.nome + ' — nenhuma seção aberta por padrão', !t.secoesAbertas.length && !t.subsecoesAbertas,
    t.secoesAbertas.length ? 'abertas: ' + t.secoesAbertas.join(', ') : `${t.telas} telas de altura, tudo fechado`));
  cads.forEach(t => add('2. Altura ao abrir', `${t.nome} — ${t.telas} telas` + (t.temBusca ? ' (com busca)' : ''), t.telas <= ALVO_TELAS || t.temBusca,
    t.telas > ALVO_TELAS && !t.temBusca ? `acima de ${ALVO_TELAS} telas sem busca` : ''));
  R.telas.filter(t => t.grupo === 'diretoria' || t.grupo === 'gerente').forEach(t => add('2. Altura ao abrir', `${t.nome} — ${t.telas} telas` + (t.temBusca ? ' (com busca)' : ''), t.telas <= ALVO_TELAS || t.temBusca,
    t.telas > ALVO_TELAS ? (t.temBusca ? `acima de ${ALVO_TELAS} telas, mas com busca` : `acima de ${ALVO_TELAS} telas sem busca`) : ''));

  /* 3. seções de lançamento: só lista compacta + ＋ */
  boletins.forEach(t => (t.secoes || []).forEach(s => {
    const olhar = (sec, pref) => {
      if (!sec.ehLancamento) return;
      const ok = sec.camposVisiveis === 0 && sec.outrosBotoes.length === 0;
      add('3. Seção de lançamento ao abrir: só lista + ＋', `${t.nome.split(' — ')[0]} › ${pref}${sec.titulo}`, ok,
        ok ? sec.mais.join(' · ') : `${sec.camposVisiveis} campo(s) visíveis antes do ＋` + (sec.exemplosCampos.length ? ' (' + sec.exemplosCampos.join(', ') + ')' : '') + (sec.outrosBotoes.length ? '; botões extras: ' + sec.outrosBotoes.join(', ') : ''));
    };
    olhar(s, '');
    (s.subsecoes || []).forEach(sub => olhar(sub, s.titulo + ' › '));
    if ((s.subsecoes || []).length) add('3. Seção de lançamento ao abrir: só lista + ＋', `${t.nome.split(' — ')[0]} › ${s.titulo} — sem acordeão dentro de acordeão`, false, `${s.subsecoes.length} sub-acordeões dentro da seção`);
  }));

  /* 4. três passos após o ＋ */
  boletins.forEach(t => (t.cartoes || []).forEach(c => {
    if (c.erro) { add('4. Três passos após o ＋ (ONDE em chips, só ele)', `${t.nome.split(' — ')[0]} › ${c.botao}`, false, c.erro); return; }
    const soOnde = c.selects === 0 && c.inputs === 0 && c.chips > 0;
    add('4. Três passos após o ＋ (ONDE em chips, só ele)', `${t.nome.split(' — ')[0]} › ${c.botao}`, soOnde,
      soOnde ? `${c.chips} chips de ${c.primeiroRotulo || 'ONDE'}` : `aparecem de uma vez: ${c.selects} seletor(es), ${c.inputs} campo(s), ${c.chips} chip(s)` + (c.totalRotulos ? ` — ${c.totalRotulos} rótulos: ${c.rotulos.join(' / ')}${c.totalRotulos > c.rotulos.length ? '…' : ''}` : ''));
  }));

  /* 5. termos de outra atividade (a própria atividade serve de prova de que o detector enxerga) */
  boletins.forEach(t => {
    const propria = t.termosProprios ? ` (detector ativo: ${t.termosProprios} termos da própria atividade na tela)` : '';
    Object.entries(t.termosAlheios || {}).forEach(([atv, achados]) => {
      const rot = { CAFE: 'café', GRAOS: 'grãos', PECUARIA: 'pecuária' }[atv];
      add('5. Zero termos de outra atividade', `${t.nome.split(' — ')[0]} — termos de ${rot}`, !achados.length, achados.length ? achados.join(', ') : 'nenhum' + propria);
    });
  });

  /* 6. listas > 12 com busca; detalhe com ação principal visível; níveis; cabeçalho; blocos fechados */
  cads.forEach(t => {
    if (t.tipo === 'lista') add('6a. Lista > 12 itens tem busca', `${t.nome} — ${t.itensLista} itens`, t.itensLista <= LISTA_MAX_SEM_BUSCA || t.temBusca, t.itensLista > LISTA_MAX_SEM_BUSCA && !t.temBusca ? 'sem busca' : (t.temBusca ? 'com busca' : ''));
    if (t.acaoPrincipal !== null) add('6b. Ação principal visível sem rolar', `${t.nome} — "${t.acaoPrincipal}"`, t.acaoVisivel, t.acaoVisivel ? 'fixa no rodapé' : 'fora da tela ao abrir');
    else if (t.tipo === 'detalhe') add('6b. Ação principal visível sem rolar', `${t.nome}`, !t.temForm, t.temForm ? 'formulário sem botão principal fixo no rodapé' : 'tela só de leitura (ações em Zona de cuidado / Mais opções)');
    add('6c. Menu → lista → detalhe (máx. 3 níveis)', `${t.nome} — nível ${t.niveis}`, t.niveis <= 3, '');
    add('6d. Cabeçalho fixo com voltar', t.nome, t.topoFixo && (t.temVoltar || t.niveis === 1), !t.topoFixo ? 'cabeçalho não é fixo' : (!t.temVoltar && t.niveis > 1 ? 'sem "‹ Voltar"' : ''));
    add('6e. "Mais opções" e "Zona de cuidado" fechados ao abrir', t.nome, !t.blocosAbertos.length, t.blocosAbertos.length ? 'abertos: ' + t.blocosAbertos.join(', ') : '');
  });
  boletins.forEach(t => add('6b. Ação principal visível sem rolar', `${t.nome} — "${t.acaoPrincipal || '—'}"`, t.acaoVisivel === true, t.acaoVisivel ? 'fixa no rodapé' : 'fora da tela ao abrir'));

  /* 7. padrão visual */
  const porGrupo = {};
  R.telas.forEach(t => { const g = porGrupo[t.grupo] = porGrupo[t.grupo] || { raio: new Set(), sombra: new Set(), gradiente: new Set(), toque: new Set() }; ['raio', 'sombra', 'gradiente', 'toque'].forEach(k => t.visual[k].forEach(x => g[k].add(x))); });
  const rotG = { gerente: 'Gerente (casa)', boletim: 'Boletim (café, grãos, pecuária, pós)', diretoria: 'Diretoria', cadastros: 'Cadastros / Escritório' };
  Object.entries(porGrupo).forEach(([g, v]) => {
    const ex = s => [...s].slice(0, 4).join('; ') + (s.size > 4 ? ` … (+${s.size - 4})` : '');
    add('7. Padrão visual — sem gradiente', rotG[g], !v.gradiente.size, v.gradiente.size ? ex(v.gradiente) : '');
    add('7. Padrão visual — sem sombra', rotG[g], !v.sombra.size, v.sombra.size ? ex(v.sombra) : '');
    add('7. Padrão visual — sem canto arredondado', rotG[g], !v.raio.size, v.raio.size ? ex(v.raio) : '');
    add('7. Padrão visual — toque ≥ 44 px', rotG[g], !v.toque.size, v.toque.size ? ex(v.toque) : '');
  });
  /* 8. texto longo em lista (v68) */
  R.telas.filter(t => t.textoLongo).forEach(t => {
    const g = '8. Texto longo em lista: colapsado, copiar sem expandir, folha de leitura', x = t.textoLongo, L = x.longo || {}, C = x.curto || {}, F = t.folha, nome = t.nome.split(' — ')[0] + ' › Relatórios';
    add(g, `${nome} — cartão nasce colapsado (prévia de 3 linhas)`, x.cartoes >= 2 && L.linhas === 3 && L.cortado, `${x.cartoes} cartões; prévia com ${L.linhas} linhas${L.cortado ? ', com reticências' : ', sem reticências'}`);
    add(g, `${nome} — cartão colapsado cabe em menos de uma tela`, L.cabe, `${L.altura} px de ${VP.height}`);
    add(g, `${nome} — cabeçalho "Números" visível sem rolar (2 textos na lista)`, x.numerosVisivel, x.numerosTopo === null ? 'sem cabeçalho Números' : `topo a ${x.numerosTopo} px`);
    add(g, `${nome} — copiar visível no cartão colapsado e copia o texto integral`, L.copiarVisivel && L.copiaIntegral, `${L.copiarVisivel ? 'botão visível' : 'botão ausente'}; ${L.copiaIntegral ? 'texto integral' : 'texto diferente da linha'}`);
    add(g, `${nome} — prévia corta por linha inteira, nunca no meio da palavra`, L.corteInteiro === true && !L.gradiente, `…${(L.ultimo || '').trim()}${L.gradiente ? ' (fade em gradiente)' : ''}`);
    add(g, `${nome} — texto curto sem "ler texto completo" e sem reticências`, C.altura > 0 && !C.lerVisivel && !C.cortado, `${C.linhas} linha(s); ler ${C.lerVisivel ? 'visível' : 'oculto'}; ${C.cortado ? 'com' : 'sem'} reticências`);
    add(g, `${nome} — origem compacta "robô-redator · dd/mm hh:mm" no cartão; aviso só no badge`, /^robô-redator · \d\d\/\d\d \d\d:\d\d$/.test(L.origem) && !x.rodape && /revisar antes de enviar/.test(L.tag), `"${L.origem}"${x.rodape ? '; ainda há "Confira e ajuste antes de mandar"' : ''}`);
    add(g, `${nome} — "N unidades · todas para conferir" quando os números coincidem`, x.todas, x.todas ? '' : 'texto não encontrado');
    add(g, `${nome} — "ler texto completo" abre folha de tela cheia (não expande na lista)`, !!F && F.bodyTravado, F ? (F.bodyTravado ? 'folha aberta, lista travada por baixo' : 'folha aberta sem travar a lista') : 'folha não abriu');
    add(g, `${nome} — folha: cabeçalho fixo com Fechar e ação principal visível sem rolar`, !!F && F.topoFixo && F.temVoltar && F.acaoVisivel, F ? `${F.topoFixo ? 'cabeçalho fixo' : 'cabeçalho solto'}; "${F.acao}" ${F.acaoVisivel ? 'no rodapé' : 'fora da tela'}` : '');
    add(g, `${nome} — folha: texto completo, badge e origem completa`, !!F && F.texto.length > 400 && /revisar antes de enviar/.test(F.tag) && /^Redigido no Supabase por .+ em \d\d\/\d\d, \d\d:\d\d/.test(F.origem), F ? `${F.texto.length} caracteres; "${F.origem}"` : '');
    add(g, `${nome} — folha: padrão visual (sem gradiente, sem sombra, sem canto, toque ≥ 44 px)`, !!F && !F.visual.gradiente.length && !F.visual.sombra.length && !F.visual.raio.length && !F.visual.toque.length, F ? ['gradiente', 'sombra', 'raio', 'toque'].filter(k => F.visual[k].length).map(k => k + ': ' + F.visual[k].slice(0, 3).join('; ')).join(' | ') : '');
    add(g, `${nome} — ao fechar a folha volta à posição de rolagem anterior`, !!t.depois && !t.depois.folha && !t.depois.travado && t.depois.y === t.antesY, t.depois ? `antes ${t.antesY} px, depois ${t.depois.y} px${t.depois.travado ? '; corpo continua travado' : ''}` : '');
  });
  /* 9. ação desabilitada por perfil (v71) */
  {
    const g = '9. Ação desabilitada por perfil: cinza neutro, explica ao toque, nunca mais da metade';
    R.telas.filter(t => t.acoesOffForm !== undefined).forEach(t => add(g, `${t.nome} — nenhuma ação desabilitada na tela de apontamento`, t.acoesOffForm === 0, `${t.acoesOffForm} encontrada(s)`));
    R.telas.filter(t => t.acoesOff).forEach(t => {
      const x = t.acoesOff, it = x.itens, rot = it.map(i => `"${i.rotulo}"`).join(', ');
      add(g, `${t.nome} — ação de outro papel aparece desabilitada, com aria-disabled e sem id/data de ação`, it.length > 0 && it.every(i => i.ariaDisabled && !i.temAcao && /—/.test(i.ariaLabel)), it.length ? `${rot}; aria-label ${it.map(i => `"${i.ariaLabel}"`).join(', ')}` : 'nenhuma');
      add(g, `${t.nome} — cinza neutro: sem vermelho, borda tracejada, sem cadeado/ícone`, it.length > 0 && it.every(i => !i.vermelho && i.estilo === 'dashed' && !i.icone), it.map(i => i.cores).join(' ; '));
      add(g, `${t.nome} — toque mostra quem executa, sem modal, sem alert e sem mudar de tela`, it.length > 0 && it.every(i => i.mostrou && !i.modal) && !x.alertas && x.mesmaTela, it.map(i => `"${i.nota}"`).join(', ') + (x.alertas ? `; ${x.alertas} alert` : '') + (x.mesmaTela ? '' : '; a tela mudou'));
      add(g, `${t.nome} — texto nomeia o papel ("Ação do/da …"), sem "sem permissão / acesso negado / bloqueado"`, it.length > 0 && it.every(i => /^Ação d[oa] /.test(i.nota) && !i.proibido), it.map(i => `"${i.nota}"`).join(', '));
      add(g, `${t.nome} — no máximo metade das ações da linha desabilitada`, it.length > 0 && it.length * 2 <= x.total, `${it.length} de ${x.total} botões`);
    });
  }
  /* 10. decisão e confirmação (v72) */
  {
    const g = '10. Decisão e confirmação: validação silenciosa, diálogo único, sem confirm/alert nativo';
    R.telas.filter(t => t.nativos !== undefined).forEach(t => add(g, `${t.nome.split(' — ')[0]} — nenhum confirm()/alert()/prompt() nativo disparou no cenário`, t.nativos === 0, `${t.nativos} chamada(s)`));
    R.telas.filter(t => t.decisao && t.decisao.existe).forEach(t => {
      const x = t.decisao, nome = t.nome;
      add(g, `${nome} — botão de avanço nasce inativo no formulário vazio, com o visual do botão de perfil (cinza, tracejado, aria-disabled)`, x.inativo && x.estilo === 'dashed' && !x.vermelho && !x.icone, `${x.inativo ? 'inativo' : 'ativo'}; borda ${x.estilo}${x.vermelho ? '; vermelho' : ''}`);
      add(g, `${nome} — toque no botão inativo mostra o que falta (próxima ação), sem acusar, sem alert e sem sair da tela`, x.mostrou && !x.proibido && x.mesmaTela && x.nativos === 0, `"${x.nota}"${x.proibido ? ' (termo proibido)' : ''}${x.mesmaTela ? '' : '; a tela mudou'}${x.nativos ? '; ' + x.nativos + ' nativo(s)' : ''}`);
      add(g, `${nome} — satisfeita a pré-condição, o botão ativa no lugar, sem redesenhar a tela`, !!x.depois && x.depois.ativo && x.depois.noLugar, x.depois ? `${x.depois.ativo ? 'ativo' : 'ainda inativo'}${x.depois.noLugar ? ', mesmo elemento' : ', elemento redesenhado'}` : 'botão sumiu');
      if (x.dialogo !== undefined) {
        const d = x.dialogo;
        add(g, `${nome} — "Descartar" abre o diálogo único: dois botões, nenhum campo, role alertdialog`, !!d && d.botoes === 2 && d.campos === 0 && d.papel === 'alertdialog' && d.modal === 'true', d ? `${d.botoes} botões, ${d.campos} campo(s), role ${d.papel}` : 'diálogo não abriu');
        add(g, `${nome} — pergunta termina em "?", sem "tem certeza", emoji ou exclamação, sem produto/dose/custo`, !!d && d.terminaInterrogacao && !d.temCerteza && !d.produto, d ? `"${d.pergunta}"` : '');
        add(g, `${nome} — afirmativa com verbo e objeto (≤ 3 palavras, nunca Sim/OK/Confirmar); negativa "Cancelar"/"Voltar"/"Revisar"`, !!d && !d.simGenerico && d.simPalavras >= 2 && d.simPalavras <= 3 && /^(Cancelar|Voltar|Revisar)$/.test(d.nao), d ? `"${d.nao}" · "${d.sim}"` : '');
        add(g, `${nome} — ação destrutiva sem destaque: nenhum dos dois botões em verde`, !!d && !d.simDestaque && !d.naoDestaque, d ? `sim ${d.simDestaque ? 'verde' : 'neutro'}, cancelar ${d.naoDestaque ? 'verde' : 'neutro'}` : '');
        add(g, `${nome} — "Cancelar" fecha o diálogo e mantém a tela`, !!x.fechou && !x.fechou.aberto && x.fechou.tela === 'form', x.fechou ? `${x.fechou.aberto ? 'ainda aberto' : 'fechado'}; tela ${x.fechou.tela}` : '');
      }
    });
  }
  /* 11. régua de 7 dias (v73) */
  {
    const g = '11. Régua de 7 dias: sete células fixas, pt-BR, hoje marcado, toque sem seletor nativo, vazio nomeia o dia';
    R.telas.filter(t => t.regua).forEach(t => {
      const r = t.regua, nome = t.nome;
      add(g, `${nome} — régua presente com 7 células, sem rolar de lado, cada uma ≥ ${TOQUE_MIN} px`, r.existe && r.n === 7 && r.scrollW <= VP.width && r.minW >= TOQUE_MIN && r.minH >= TOQUE_MIN, r.existe ? `${r.n} células de ${r.minW.toFixed(1)} × ${r.minH} px; ${r.larguraRegua} px em ${r.scrollW} px` : 'sem régua');
      if (!r.existe) return;
      add(g, `${nome} — dias em português (seg…dom), do mais recente à esquerda, nenhum dia futuro`, r.diasPt && r.decrescente && r.futuros === 0, `${r.rotulos}; ${r.futuros} futuro(s)`);
      add(g, `${nome} — hoje selecionado ao abrir, marcado (barra) e aria-pressed coerente`, r.hojeSelecionado && r.hojeMarcado && r.ariaPressed, `selecionado ${r.ordem[0]}`);
      add(g, `${nome} — toque em ontem troca o dia sem teclado nem seletor nativo, sem sair da tela; hoje continua marcado`, !!r.depois && r.depois.on === r.ordem[1] && r.depois.hojeAindaMarcado && r.depois.hojeBarra === '3px' && !r.depois.temInputDate && r.depois.foco !== 'INPUT' && r.depois.tela === 'casa' && r.depois.nativos === 0 && r.voltou, r.depois ? `escolhido ${r.depois.on}; tela ${r.depois.tela}; ${r.depois.nativos} nativo(s); volta a hoje ${r.voltou ? 'ok' : 'falhou'}` : '');
      add(g, `${nome} — dia sem registro cai no vazio da função única: nomeia unidade e dia, sem termo proibido`, !!r.depois && r.depois.nomeiaDia && !r.depois.proibido && /^Sem /.test(r.depois.texto), r.depois ? `"${r.depois.texto.slice(0, 90)}"` : '');
      add(g, `${nome} — cabeçalho contextual + régua abaixo de 25 % da altura útil; nenhum input type=date`, r.pct <= 25 && r.inputsDate === 0, `${r.conjunto} px = ${r.pct} % de ${VP.height} px; ${r.inputsDate} input date`);
    });
  }
  /* 12. chips removíveis da multi-seleção (v74) */
  {
    const g = '12. Chips removíveis: vazio sem área, contador + chips, × de 44 px remove na hora, quebra sem rolar, +K expande';
    R.telas.filter(t => t.selecoes).forEach(t => {
      const tela = t.nome.split(' — ')[0];
      if (!t.selecoes.length) { add(g, `${tela} — sem multi-seleção nesta atividade: nada a medir`, true, 'pecuária escolhe um valor por campo'); return; }
      t.selecoes.forEach(s => {
        const nome = `${tela} › ${s.nome}`;
        if (!s.existe) { add(g, `${nome} — componente presente`, false, 'sem .sel-box'); return; }
        const A = s.antes, D = s.depois, F = s.fim, X = s.removeu, k = s.k, vis = Math.min(k, 6);
        add(g, `${nome} — seleção vazia não desenha nada (nem contador zerado, nem área reservada)`, A.vazio && A.altura === 0 && A.display === 'none', `${A.altura} px; display ${A.display}`);
        add(g, `${nome} — contador "${k} … selecionad…" e um chip por item, rótulo + × à direita`, new RegExp('^' + k + ' .*selecionad[oa]s?$').test(D.cont) && D.n === vis && D.aria.every(a => /^Remover .+/.test(a)), `"${D.cont}"; ${D.n} chip(s): ${D.chips.slice(0, 4).join(', ')}${D.n > 4 ? ' …' : ''}`);
        add(g, `${nome} — × com 44 × 44 px, rótulo acessível "Remover <nome>", sem vermelho`, D.xMin >= TOQUE_MIN && D.aria.length === D.n && !D.vermelho, `× ${D.xMin} px; aria "${D.aria[0] || ''}"`);
        add(g, `${nome} — quebra em linhas, sem rolar de lado; sem sombra nem gradiente`, D.wrap === 'wrap' && !D.rolaLado && D.scrollW <= VP.width && !D.sombra && !D.gradiente, `${D.linhas} linha(s); página ${D.scrollW} px de largura`);
        if (k > 6) add(g, `${nome} — mais de 6 itens: 6 chips + "+${k - 6}", que expande para todos`, D.mais === '+' + (k - 6) && !!s.expandido && s.expandido.n === k && !s.expandido.mais, `"${D.mais}" → ${s.expandido ? s.expandido.n : '?'} chips`);
        else add(g, `${nome} — até 6 itens: todos os chips, sem "+K"`, D.mais === null, D.mais ? `"${D.mais}"` : '');
        add(g, `${nome} — toque no corpo do chip não faz nada`, s.corpo.n === D.n && s.corpo.cont === D.cont && s.corpoTela === s.tela, `${s.corpo.n} chip(s) depois; tela ${s.corpoTela}`);
        add(g, `${nome} — × remove na hora: sem confirmação, sem nativo, sem sair da tela; a opção apaga`, X.est.n === k - 1 && X.opcaoOn === false && X.nativos === 0 && X.tela === s.tela, `${X.est.n} chip(s); "${X.est.cont}"; opção ${X.opcaoOn ? 'ainda acesa' : 'apagada'}; ${X.nativos} nativo(s); tela ${X.tela}`);
        add(g, `${nome} — remover o último volta ao vazio (estado válido, nenhum aviso)`, F.vazio && F.altura === 0 && s.nativos === 0 && s.fimTela === s.tela, `${F.altura} px; ${s.nativos} nativo(s)`);
      });
    });
  }
  /* agrupa por item, mantendo a ordem de chegada dentro de cada um */
  return itens.map((i, n) => Object.assign(i, { n })).sort((a, b) => a.grupo.localeCompare(b.grupo, 'pt-BR') || a.n - b.n);
}

function relatorio(itens, R) {
  const versao = (/APP_VERSAO="(v\d+)"/.exec(fs.readFileSync(path.join(RAIZ, 'index.html'), 'utf8')) || [])[1] || '?';
  const ok = itens.filter(i => i.ok).length, nok = itens.length - ok;
  const linhas = [`# Checagem de poluição — Boletim NCNaves ${versao} — ${new Date().toISOString().slice(0, 16).replace('T', ' ')}`,
    `Largura ${VP.width} px · altura de referência ${VP.height} px · alvo ${ALVO_TELAS} telas · toque ≥ ${TOQUE_MIN} px · sem rede`, ''];
  let grupo = '';
  itens.forEach(i => {
    if (i.grupo !== grupo) { grupo = i.grupo; linhas.push(`## ${grupo}`); }
    linhas.push(`- ${i.ok ? '✅' : '❌'} ${i.nome}${i.detalhe ? ' — ' + i.detalhe : ''}`);
  });
  linhas.push('', `## Resultado: ${ok} ✅ · ${nok} ❌${nok ? ' — corrigir antes do PR (ou constar como ❌ herdado no ESTADO.md)' : ''}`);
  return linhas.join('\n');
}

(async () => {
  const termos = lerTermos();
  const { srv, base } = await servir(RAIZ);
  const browser = await pw.chromium.launch();
  const R = { telas: [] };
  try {
    await cenarioBoletim(browser, base, R, 'Café (f23 Vereda Romaria)', 'f23', 'CAFE', termos);
    await cenarioBoletim(browser, base, R, 'Grãos (f33 Floramill)', 'f33', 'GRAOS', termos);
    await cenarioBoletim(browser, base, R, 'Pecuária (f26 Água Santa)', 'f26', 'PECUARIA', termos);
    await cenarioPos(browser, base, R, termos);
    await cenarioDiretoria(browser, base, R);
    await cenarioCadastros(browser, base, R);
  } finally { await browser.close(); srv.close(); }
  const itens = avaliar(R);
  const md = relatorio(itens, R);
  if (saida) {
    fs.mkdirSync(saida, { recursive: true });
    R.telas.forEach(t => { delete t.texto; });
    fs.writeFileSync(path.join(saida, 'checagem.json'), JSON.stringify({ itens, telas: R.telas }, null, 1));
    fs.writeFileSync(path.join(saida, 'checagem.md'), md);
  }
  console.log(soResumo ? md.split('\n').slice(-1)[0] : md);
  process.exit(itens.some(i => !i.ok) ? 1 : 0);
})().catch(e => { console.error('FALHOU: ' + e.stack); process.exit(2); });
