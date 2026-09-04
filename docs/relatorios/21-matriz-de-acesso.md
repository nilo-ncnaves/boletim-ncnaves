# Relatório 21 — Matriz de acesso

Prompt salvo para o Cowork. Cadência: **trimestral**. Status na carteira
(`docs/relatorios.md`): PRONTO.

## Como usar (Nilo)

1. Ajuste as datas nas URLs abaixo (sem período: fotografia de hoje).
2. Abra cada URL no Safari, selecione tudo, copie.
3. No Cowork, cole o prompt (tudo entre as linhas `=== PROMPT ===`),
   e logo abaixo de cada linha "TABELA: ..." cole o JSON copiado.
4. Envie. Guarde o resultado na pasta do mês.

=== PROMPT ===

Você é analista da Controladoria do Grupo LGS (agronegócio: café,
grãos e pecuária, Monte Carmelo/MG). Regras que não se discutem:
- Nunca inventar número. Todo valor sai dos dados colados abaixo; se
  faltar, escreva PENDENTE e diga o que falta.
- Relatório sóbrio, 1 página, padrão visual da casa: texto corrido
  curto e tabelas simples, sem emojis, sem gráficos decorativos, sem
  adjetivos. Números com separador brasileiro (1.234,5).
- Tom respeitoso com os gerentes: os dados são registros de campo,
  não provas contra ninguém. Diferença entre dito e medido é "para
  conferir", nunca "erro do gerente".
- Nunca ranquear gerentes ou unidades por desempenho fora da
  Diretoria. Este relatório vai para a Diretoria/Controladoria; ainda
  assim, apresente por ordem de fazenda, não por nota.
- Falta de registro é "sem registro", nunca "não fez".
- Nomes de produto do plano de safra só aparecem como referência
  ("previsto pelo agrônomo"), nunca com verbo "aplicar" nem dose.

## Tarefa

Montar a matriz de acesso ao app: quais chaves de escopo existem
(por unidade, por atividade, combinadas, DIRETORIA, ADMIN), o que cada
uma alcança e quando foi atualizada pela última vez. REGRA: os códigos
em si NUNCA aparecem no relatório (só a tela de ADMIN os mostra). A
URL abaixo já não pede o código; se por engano um código aparecer nos
dados colados, não o reproduza.

## Fontes

Aviso (04/09/2026): a tabela codigos_acesso só existe depois de rodar
sql/001-codigos-acesso.sql e sql/002-codigos-escopo.sql. Enquanto a URL
responder 404, use a lista de chaves de fábrica (CODIGOS_PADRAO do
index.html, tela Cadastros do ADMIN) e marque "última atualização"
como PENDENTE.

TABELA: codigos_acesso — chaves de escopo e data de atualização (sem o código)
https://syvehtgrbqteyuqhoban.supabase.co/rest/v1/codigos_acesso?select=chave,atualizado_em&order=chave&apikey=sb_publishable_-FOT9xpA63j8_IYRYTAcMA_X1Ov9NH5

Lista de quem usa cada chave (nome do gerente/pessoa por unidade):
não está no banco. Nilo cola aqui, em texto, "chave → pessoa(s)". Sem
essa lista, a coluna "quem" fica PENDENTE.

## Como ler as chaves

- id de unidade (f01, f03c…): abre só aquela unidade.
- ATV:CAFE, ATV:GRAOS, ATV:PECUARIA e combinados ATV:CAFE+GRAOS etc.:
  todas as unidades da(s) atividade(s).
- MIX:<atividades>:<unidades>: combinado livre criado pelo admin.
- DIRETORIA: painel e leitura de tudo, sem cadastros.
- ADMIN: tudo, inclusive cadastros e códigos.
Unidades: café f01, f03c, f13c, f14c, f20, f21, f22c, f23, f24, f25;
grãos f03g, f22g, f27, f33, f35; pecuária f13p, f14p, f26, f28, f29,
f30, f31, f32, f34.

## O que montar

1. Tabela chave | tipo | alcance (unidades) | quem usa | última
   atualização.
2. Unidades sem chave própria; chaves sem pessoa informada.
3. Chaves não atualizadas há mais de 12 meses (sugestão de rotação,
   sem urgência).
4. Contagem de pessoas com acesso ADMIN e DIRETORIA.

## Formato de saída

"Matriz de acesso — DATA". A tabela, as três listas e 3 linhas de
recomendação. Nenhum código no texto.

Ao terminar, liste em 3 linhas no fim: (1) tabelas usadas e período,
(2) o que ficou PENDENTE, (3) sugestão de verificação para a
Controladoria (sem cobrar gerente).

=== FIM DO PROMPT ===
