-- ====================================================================
-- 055 — Mensagens importadas do WhatsApp (trilha de origem)  ·  v86
-- ====================================================================
-- Objeto: mensagens_importadas. Rodar no SQL Editor do Supabase
-- (projeto syvehtgrbqteyuqhoban).
--
-- PASSO A PASSO (pelo iPhone):
--   1. Abra o Supabase e entre no projeto do Boletim.
--   2. Toque em "SQL Editor" e em "New query".
--   3. Selecione TODO o texto deste arquivo, copie e cole na caixa.
--   4. Toque em "Run".
--   5. No fim aparece uma tabelinha de conferência. Pode rodar de novo
--      quantas vezes quiser: nada duplica e nada se apaga.
--
-- O QUE É. Toda mensagem colada na porta única "📥 Colar do WhatsApp" fica
-- guardada INTEIRA, com quem colou, quando, o tipo identificado (ata de
-- reunião, remessa de insumo, tarefas avulsas, relato de chuva) e a lista do
-- que foi criado a partir dela. É a trilha que responde, meses depois,
-- "quando o Lusmar anunciou o nitrato da Mata Preta e quanto chegou?".
--
-- POR QUE NO BANCO (e não só no celular): porque o histórico do grupo é o
-- contexto da PERGUNTA LIVRE (fase 3) — quando o motor de perguntas existir,
-- ele lê daqui. Nada do motor foi construído nesta tarefa.
--
-- O QUE ELA NÃO É: não é cópia do grupo de WhatsApp. Só entra o que alguém
-- do escritório colou de propósito na tela de importação. Não há telefone,
-- não há foto, não há quem falou no grupo — só o texto colado e o nome de
-- quem colou (o nome do perfil no app).
--
-- ENQUANTO NÃO RODAR: a colagem funciona igual e a trilha fica no aparelho
-- de quem colou (a mensagem entra na fila e sobe sozinha depois).
--
-- SEGURANÇA: leitura e escrita anon por policy, como as demais tabelas que o
-- app alimenta. Nenhum segredo aqui.
-- ====================================================================

create table if not exists public.mensagens_importadas (
  id          text primary key,                 -- id gerado pelo app
  tipo        text,                             -- ata | remessa | tarefas | chuva
  texto       text not null,                    -- a mensagem original, inteira
  colado_por  text,                             -- nome do perfil que colou (nunca telefone)
  colado_em   timestamptz not null default now(),
  criados     jsonb not null default '[]'::jsonb, -- o que a mensagem criou (ids de remessa/tarefa, sugestões)
  atualizado  timestamptz not null default now()
);
comment on table public.mensagens_importadas is
  'v86 — trilha de origem das colagens do grupo. Contexto da pergunta livre (fase 3). Só o que alguém colou de propósito.';

create index if not exists msg_import_em_idx on public.mensagens_importadas (colado_em desc);
create index if not exists msg_import_tipo_idx on public.mensagens_importadas (tipo, colado_em desc);

create or replace function public.msg_import_touch() returns trigger language plpgsql as $$
begin new.atualizado := now(); return new; end $$;

drop trigger if exists msg_import_touch on public.mensagens_importadas;
create trigger msg_import_touch before insert or update on public.mensagens_importadas
  for each row execute function public.msg_import_touch();

alter table public.mensagens_importadas enable row level security;
drop policy if exists msg_import_ler on public.mensagens_importadas;
create policy msg_import_ler on public.mensagens_importadas for select using (true);
drop policy if exists msg_import_gravar on public.mensagens_importadas;
create policy msg_import_gravar on public.mensagens_importadas for insert with check (true);
drop policy if exists msg_import_atualizar on public.mensagens_importadas;
create policy msg_import_atualizar on public.mensagens_importadas for update using (true) with check (true);

notify pgrst, 'reload schema';

-- conferência
select 'mensagens_importadas criada' as passo,
       count(*) as mensagens,
       max(colado_em) as ultima_colagem
from public.mensagens_importadas;
