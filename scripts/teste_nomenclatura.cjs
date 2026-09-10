#!/usr/bin/env node
/*
 teste_nomenclatura.cjs — prova da REGRA CENTRAL da v76 (CLAUDE.md,
 "Nomenclatura e histórico"; docs/definicao-de-pronto.md, item 17):
 renomear termo NUNCA reescreve boletim, e o histórico continua sendo
 exibido, somado e cruzado com o plano pelo nome de hoje.

 Roda num Chromium sem rede (todo pedido de fora é bloqueado, como um
 celular offline), a 390 × 844 px. Não é parte do app — é ferramenta de
 teste, para rodar antes de qualquer PR que renomeie termo de catálogo.

 Uso (na raiz do repositório):
   python3 -m http.server 8152 --directory . &
   node scripts/teste_nomenclatura.cjs http://localhost:8152

 Sai com código 1 se alguma prova falhar.
 Precisa do pacote playwright (global) e do Chromium dele.
*/
let pw; try{pw=require('playwright');}catch(e){pw=require('/opt/node22/lib/node_modules/playwright');}
const base=process.argv[2]||'http://localhost:8152';
let falhas=0;
const ok=(c,t,extra)=>{ if(!c) falhas++; console.log((c?'✅':'❌')+' '+t+(extra?' — '+extra:'')); };

/* 1. De-para na leitura: exibição, soma, plano, filtro e badge */
async function provaDePara(){

  const b=await pw.chromium.launch({args:['--no-sandbox']});
  const p=await b.newPage({viewport:{width:390,height:844}});
  await p.route('**://**',r=>r.request().url().startsWith(base)?r.continue():r.abort());
  await p.goto(base+'/index.html'); await p.waitForFunction(()=>typeof nomeAtual==='function');

  const r=await p.evaluate(()=>{
    const out={};
    out.depara = nomeAtual('Desbrota')+' | '+nomeAtual('Poda / esqueletamento')+' | '+nomeAtual('Roçada costal')
      +' | '+nomeAtual('Aplicação de herbicida (costal)')+' | '+nomeAtual('Aplicação de defensivo (costal)');
    out.intacto = nomeAtual('Colheita')+' | '+nomeAtual('Pulverização')+' | '+nomeAtual('Termo do escritório');
    out.grupos = OPS_CAFE_GRUPOS.map(([g,ops])=>g+' ('+ops.length+')').join(' · ');
    out.total = LISTA_ATIV.length;
    /* badge/categoria: termo antigo renomeado, termo antigo ambíguo e termo de hoje */
    const cat=n=>{const c=categoriaOperacao('CAFE',{nome:n});return c?c.letra+' '+c.nome:'—';};
    out.catAntigo=cat('Desbrota'); out.catLegado=cat('Pulverização'); out.catNovo=cat('Desbrota manual');
    out.catIrrLegado=cat('Irrigação');
    /* plano × executado: plano gravado com o nome ANTIGO, boletim com o nome NOVO */
    const bol={data:'2026-09-09',fazendaId:'f23',clima:{cond:'Ensolarado'},
      atividades:[{tipo:'Desbrota manual',talhaoId:'geral',status:'concluida'}]};
    const av1=avaliarPlano({itens:[{op:'Desbrota',ondes:['geral']}]},bol);
    out.planoAntigoxNovo=av1.itens[0].status;
    /* e o contrário: plano com o nome NOVO, boletim antigo com o nome ANTIGO */
    const bol2={data:'2026-09-09',fazendaId:'f23',clima:{cond:'Ensolarado'},
      atividades:[{tipo:'Desbrota',talhaoId:'geral',status:'concluida'}]};
    const av2=avaliarPlano({itens:[{op:'Desbrota manual',ondes:['geral']}]},bol2);
    out.planoNovoxAntigo=av2.itens[0].status;
    /* filtro do painel (recorte por nome de atividade — a mesma chave que uma meta usaria) */
    out.resumo=resumo1linha(bol2);
    const casaFiltro=(reg,filtro)=>(reg.atividades||[]).some(a=>nomeAtual(a.tipo)===nomeAtual(filtro));
    out.filtroNovoxAntigo=casaFiltro(bol2,'Desbrota manual');   /* filtro de hoje × boletim antigo */
    out.filtroAntigoxNovo=casaFiltro(bol,'Desbrota');           /* filtro antigo (meta velha) × registro novo */
    out.filtroOutro=casaFiltro(bol2,'Capina manual');           /* não pode casar com outra coisa */
    /* extras do escritório entram num 5º grupo, sem sumir */
    D.catalogoExtra=D.catalogoExtra||{}; D.catalogoExtra['operacoes:CAFE']=['Serviço combinado XPTO'];
    out.gruposComExtra=gruposAtivCafe().map(([g])=>g).join(' · ');
    /* WhatsApp do boletim antigo */
    
    return out;
  });
  console.log(JSON.stringify(r,null,1));
  ok(r.depara==='Desbrota manual | Poda mecanizada esqueletamento | Capina mecânica com roçadeira | Capina química manual | Pulverização manual','de-para antigo → novo',r.depara);
  ok(r.intacto==='Colheita | Pulverização | Termo do escritório','termo sem de-para volta igual',r.intacto);
  ok(r.total===27,'lista do café agrupada em 4 naturezas','27 termos: '+r.grupos);
  ok(r.catAntigo==='T Tratos culturais','badge do termo renomeado no histórico',r.catAntigo);
  ok(r.catLegado==='T Tratos culturais','badge do termo legado (natureza conhecida)',r.catLegado);
  ok(r.catIrrLegado==='I Irrigação e fertirrigação','badge do legado "Irrigação"',r.catIrrLegado);
  ok(r.planoAntigoxNovo==='feito','plano com nome ANTIGO fecha com registro NOVO',r.planoAntigoxNovo);
  ok(r.planoNovoxAntigo==='feito','plano com nome NOVO fecha com registro ANTIGO',r.planoNovoxAntigo);
  ok(/Desbrota manual/.test(r.resumo),'boletim antigo mostra o nome de hoje',r.resumo);
  ok(r.filtroNovoxAntigo===true,'filtro/meta no nome de hoje acha o boletim antigo');
  ok(r.filtroAntigoxNovo===true,'filtro/meta no nome antigo acha o registro de hoje');
  ok(r.filtroOutro===false,'o de-para não junta o que é diferente');
  ok(r.gruposComExtra==='Tratos culturais · Irrigação e fertirrigação · Colheita e pós-colheita · Estrutura e apoio · Outras (cadastro do escritório)',
     'termo do escritório entra num 5º grupo, sem sumir',r.gruposComExtra);
  await b.close();
}

/* 2. Tela: boletim antigo continua legível e a lista nova é agrupada e recolhida (3 passos) */
async function provaTela(){

  const b=await pw.chromium.launch({args:['--no-sandbox']});
  const p=await b.newPage({viewport:{width:390,height:844}});
  await p.route('**://**',r=>r.request().url().startsWith(base)?r.continue():r.abort());
  await p.goto(base+'/index.html'); await p.waitForFunction(()=>typeof ir==='function');
  /* boletim ANTIGO semeado direto no armazenamento, com os termos de antes da v76 */
  await p.evaluate(()=>{
    localStorage.setItem('bdf:acesso',JSON.stringify({codigo:'VR-7061',chave:'f23'}));
    location.reload();
  });
  await p.waitForFunction(()=>typeof ir==='function'); await p.waitForTimeout(400);
  await p.evaluate(()=>{
    sessao={userId:'u1',papel:'gerente',nome:'Gerente',fazendaId:'f23'};
    D.boletins.unshift({id:'antigo1',data:'2026-09-08',fazendaId:'f23',responsavel:'Zé',
      clima:{cond:'Ensolarado',chuvaMm:''},mo:{proprios:'4',diaristas:'0',funcoes:[{nome:'Roçada costal',prop:'4',diar:'',hx:''}]},
      atividades:[{id:'a1',tipo:'Desbrota',talhaoId:'geral',pessoas:'4',status:'concluida',obs:''},
                  {id:'a2',tipo:'Pulverização',talhaoId:'geral',pessoas:'2',status:'concluida',obs:''}],
      colheita:[],fito:[],ocorrencias:[],pos:{},secoes:{},obsGeral:'',pendencias:'',enviadoEm:'2026-09-08 18:00'});
    ir('detalhe','antigo1');
  });
  await p.waitForTimeout(300);
  const det=await p.evaluate(()=>document.querySelector('#app').innerText);
  ok(/Desbrota manual/.test(det),'boletim de 08/09 exibe o termo de hoje no lugar do antigo');
  ok(!/(^|\W)Desbrota(\s|$)/.test(det.replace(/Desbrota manual/g,'')),'sem sobra do termo antigo na tela');
  ok(/Pulverização/.test(det),'termo legado (ainda sem decisão) continua legível');
  ok(/Capina mecânica com roçadeira/.test(det),'função de mão de obra antiga aparece com o nome de hoje');
  ok(/T\s*Tratos culturais|Tratos culturais/.test(await p.evaluate(()=>document.querySelector('#app').innerHTML.includes('Tratos culturais')?'Tratos culturais':'')),'badge de natureza no histórico');
  /* o dado gravado não muda */
  const bruto=await p.evaluate(()=>JSON.stringify(D.boletins.find(x=>x.id==='antigo1').atividades.map(a=>a.tipo)));
  ok(bruto==='["Desbrota","Pulverização"]','o registro no armazenamento NÃO foi reescrito',bruto);

  /* 3 passos no boletim novo */
  await p.evaluate(()=>{ rascunho=novoRascunho(); ir('form'); });
  await p.waitForTimeout(400);
  await p.evaluate(()=>document.querySelectorAll('details.secao').forEach(d=>{ if(/Atividades por talh/.test(d.innerText)) d.open=true; }));
  await p.click('#bt-add-ativ'); await p.waitForTimeout(200);
  let passo=await p.evaluate(()=>{const c=document.querySelector('[data-ativ]');
    return {sel:c.querySelectorAll('select').length,inp:c.querySelectorAll('input,textarea').length,
            grupos:c.querySelectorAll('details.fase-op').length,chips:c.querySelectorAll('.chip').length};});
  ok(passo.sel===1&&passo.inp===0&&passo.grupos===0,'passo 1 (ONDE): só o talhão, sem campo e sem lista de atividade',JSON.stringify(passo));
  const t=await p.evaluate(()=>{const s=document.querySelector('[data-ativ] select[data-a="talhaoId"]');
    const o=[...s.options].find(x=>x.value&&x.value!=='geral'); return o?o.value:'geral';});
  await p.selectOption('[data-ativ] select[data-a="talhaoId"]',t); await p.waitForTimeout(250);
  passo=await p.evaluate(()=>{const c=document.querySelector('[data-ativ]');
    return {grupos:[...c.querySelectorAll('details.fase-op')].map(d=>d.querySelector('summary').textContent),
            abertos:[...c.querySelectorAll('details.fase-op')].filter(d=>d.open).length,
            chipsVisiveis:[...c.querySelectorAll('.chip')].filter(x=>x.checkVisibility({contentVisibilityAuto:true,visibilityProperty:true})).length,
            alturaCartao:Math.round(c.getBoundingClientRect().height),
            inp:c.querySelectorAll('input,textarea').length};});
  ok(passo.grupos.length===4,'passo 2 (O QUÊ): 4 grupos por natureza',passo.grupos.join(' · '));
  ok(passo.abertos===0&&passo.chipsVisiveis===0,'nenhum grupo aberto por padrão','abertos: '+passo.abertos+', chips visíveis: '+passo.chipsVisiveis+', cartão de '+passo.alturaCartao+' px');
  ok(passo.inp===0,'nenhum campo de detalhe antes de escolher a atividade','campos: '+passo.inp);
  await p.evaluate(()=>{const d=[...document.querySelectorAll('[data-ativ] details.fase-op')].find(x=>/Tratos/.test(x.textContent)); d.open=true;});
  const chips=await p.evaluate(()=>[...document.querySelectorAll('[data-ativ] details.fase-op[open] .chip')].map(c=>c.textContent));
  ok(chips.includes('Capina mecânica com trincha')&&chips.includes('Levantar café')&&chips.includes('Desbrota manual'),
     'o funcionário acha as palavras dele no grupo aberto',chips.length+' chips');
  await p.click('[data-escop$="|Levantar café"]'); await p.waitForTimeout(250);
  const passo3=await p.evaluate(()=>{const c=document.querySelector('[data-ativ]');
    return {txt:c.innerText.slice(0,60).replace(/\n/g,' | '),inp:c.querySelectorAll('input,textarea').length};});
  ok(passo3.inp>0,'passo 3 (DETALHES): os campos só aparecem depois da escolha',JSON.stringify(passo3));
  await b.close();
}

(async()=>{ await provaDePara(); await provaTela();
  console.log(falhas?('\n'+falhas+' falha(s)'):'\nTudo certo');
  process.exit(falhas?1:0);
})();
