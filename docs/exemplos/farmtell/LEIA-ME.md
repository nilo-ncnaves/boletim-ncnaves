# Exemplo do FarmTell — o que falta para o app importar o CMS sozinho

Situação em 07/10/2026 (v103): **a importação do FarmTell ainda não foi
feita** (Parte D da revisão de especialista do confinamento), porque esta
pasta não tem nenhum arquivo exportado do FarmTell. Sem ver o arquivo de
verdade, o app teria de adivinhar o nome das colunas, a unidade (matéria
seca ou matéria natural) e a escala da leitura de cocho — e adivinhar é
proibido aqui.

Enquanto isso, nada muda para o gerente: ele continua copiando o CMS do
FarmTell no diário (o campo é opcional) e marcando a sobra de cocho.

## Para que serve

Hoje o gerente digita de novo o CMS e a leitura de cocho que o FarmTell já
tem. É trabalho em dobro e abre espaço para erro de digitação. Com a
importação, o diário vem **pré-preenchido** com o CMS e a sobra de cada
curral, com a marca "do FarmTell"; o gerente só registra o que só ele vê
(enfermaria, bebedouro, ofegação, mortes, o que está fora do normal) e pode
trocar o valor importado — os dois ficam guardados.

## O que o Nilo precisa mandar (passo a passo)

1. Peça a quem opera o FarmTell Beef na Vereda (ou ao suporte do FarmTell)
   o relatório que mostra, **por curral e por dia**, o que foi fornecido no
   cocho e o consumo por cabeça. Se o FarmTell tiver também a **leitura de
   cocho** (a nota da sobra), peça que ela venha no mesmo relatório.
2. Escolha um período de **pelo menos 3 dias seguidos** e com **pelo menos
   2 currais** ocupados. De preferência, dias em que o diário do app também
   foi preenchido — assim dá para conferir um contra o outro.
3. Exporte em **planilha** (CSV ou Excel). Se houver as duas opções, mande
   as duas. PDF não serve para esta parte.
4. Antes de mandar, confira se no arquivo aparecem:
   - o nome ou número do curral do jeito que o FarmTell chama;
   - a data;
   - o número de cabeças do curral naquele dia;
   - a quantidade fornecida e/ou consumida — e se ela está em **matéria
     seca (MS)** ou **matéria natural (MN)**, por cabeça ou do curral
     inteiro;
   - o **teor de matéria seca** da dieta, se o relatório estiver em matéria
     natural (sem ele não dá para converter para kg MS/cab);
   - a leitura de cocho, com a escala usada (0 a 4, −1 a 4, ou outra).
5. Mande o arquivo numa conversa com o Claude Code e peça: **"salvar em
   docs/exemplos/farmtell/ e fazer a Parte D da v103"**. Se o arquivo tiver
   dado que não deve ficar no repositório (preço de ração, nome de
   fornecedor), avise na mesma mensagem para tirar essas colunas antes.

## O que acontece depois (para o Nilo saber o que vai ser perguntado)

- Antes de escrever qualquer código, o PR traz a tabela **coluna do
  FarmTell → campo do app → unidade**, para o Nilo conferir.
- Se o FarmTell der matéria natural ou o total do curral, a conversão para
  kg MS/cab aparece escrita, com a fonte do teor de MS.
- O curral do FarmTell é ligado ao curral do cadastro por um **de-para
  editável** em Cadastros › Confinamento — nunca por pedaço de nome.
- Se a leitura de cocho do FarmTell **não for de 0 a 4**, o app mostra o
  de-para proposto e **para** essa parte até o Nilo decidir.
- Diário já enviado **não é reescrito**: se o FarmTell discordar do que o
  gerente marcou, a tela do lote mostra "FarmTell difere do diário" para o
  escritório conferir. Importar de novo o mesmo arquivo não duplica nada
  (chave: curral + data).
- Dieta, fórmula, ingrediente e custo de ração **não** vão para a tela do
  gerente.
