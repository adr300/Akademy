-- ============================================================================
-- 2026-10-26_08  question_answers: Antwortprotokoll je Lernendem, Lektion und Frage
-- Status: VORBEREITET. Im Supabase-SQL-Editor ausführen (supabase/README.md).
-- ----------------------------------------------------------------------------
-- Befund
--   Eine Lektion speichert heute nur completed/score in user_progress. Welche Frage wie beantwortet wurde, ist weder für
--   Lernende (Nachsehen, Wiederholen der Fehler) noch für Manager (schwierige Fragen) sichtbar.
-- Lösung
--   Tabelle question_answers: eine Zeile je beantworteter Frage und Versuch. Das Frontend (Block BLUU-ANTWORTEN) schreibt sie
--   am Ende eines Tests; fehlt die Tabelle, bleibt das Protokoll im Browser. Die Analytics-Auswertung zeigt daraus die
--   Fragen mit der höchsten Fehlerquote.
-- Spalten
--   user_id uuid, course_id bigint (courses.id), question_id bigint (questions.id, null wenn die Frage gelöscht wurde),
--   attempt text (Versuchskennung = Startzeit), correct boolean, answer jsonb {typ, antwort, loesung}, answered_at timestamptz.
-- RLS
--   Lernende: eigene Zeilen lesen und einfügen (kein Update/Delete). Manager und Admins: alle lesen (über die bestehenden
--   Tabellen managers/admins, Spalte user_id – bitte prüfen).
-- Bestehende Daten
--   Keine. Datenschutz: Antworten sind personenbezogen; Aufbewahrung wie user_progress behandeln.
-- Rollback
--   drop table public.question_answers;
-- ============================================================================
begin;

create table if not exists public.question_answers (
  id           bigserial primary key,
  user_id      uuid        not null references auth.users (id) on delete cascade,
  course_id    bigint      not null,  -- courses.id (bigint); bewusst ohne FK, damit das Protokoll das Löschen eines Kurses überlebt
  question_id  bigint,
  attempt      text        not null,
  correct      boolean     not null,
  answer       jsonb       not null default '{}'::jsonb,
  answered_at  timestamptz not null default now()
);
create index if not exists question_answers_user_idx on public.question_answers (user_id, course_id, answered_at desc);
create index if not exists question_answers_question_idx on public.question_answers (course_id, question_id);

alter table public.question_answers enable row level security;
drop policy if exists "question_answers eigene lesen" on public.question_answers;
drop policy if exists "question_answers eigene schreiben" on public.question_answers;
drop policy if exists "question_answers verwaltung lesen" on public.question_answers;
create policy "question_answers eigene lesen" on public.question_answers
  for select to authenticated using (auth.uid() = user_id);
create policy "question_answers eigene schreiben" on public.question_answers
  for insert to authenticated with check (auth.uid() = user_id);
create policy "question_answers verwaltung lesen" on public.question_answers
  for select to authenticated using (
    exists (select 1 from public.admins a where a.user_id = auth.uid())
    or exists (select 1 from public.managers m where m.user_id = auth.uid())
  );

commit;
