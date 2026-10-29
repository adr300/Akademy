-- ============================================================================
-- 2026-10-26_02  lernskript_progress: Lernskript-Stand je Lernendem und Modul (geräteübergreifend)
-- Status: VORBEREITET, NICHT AUSGEFÜHRT. Zur Prüfung durch Adrian.
-- ----------------------------------------------------------------------------
-- Zweck
--   Der Lernskript-Stand (Kapitel, Häkchen «Das kann ich jetzt», Eingaben, Schriftgröße) liegt heute nur im Browser
--   (localStorage «bluu-ls-<modul>-<uid>»). Der Block BLUU-LS-SYNC im Frontend schreibt den Stand zusätzlich in diese Tabelle
--   und führt beim Öffnen des Lernskripts den Browser-Stand mit dem Server-Stand zusammen (Regeln: docs/DATENMODELL.md).
--   Fehlt die Tabelle, merkt das Frontend das am Fehlercode und bleibt still beim Browser-Stand – diese Migration ist
--   also optional, aber nötig für den Gerätewechsel.
-- Betroffene Tabellen
--   neu: public.lernskript_progress
-- Spalten
--   user_id uuid (auth.users), module text ('1.1.1' …), chapter text (zuletzt besuchtes Kapitel oder 'start'),
--   completed_chapters text[] (Kapitel mit allen Häkchen), stand jsonb (vollständiger Browser-Stand, Quelle der Wahrheit
--   für Eingaben), updated_at timestamptz.
-- Constraints und Indizes
--   Primärschlüssel (user_id, module); CHECK auf das Modulformat; Index auf updated_at für spätere Auswertungen.
-- RLS
--   Nur eigene Zeilen (select/insert/update). Manager und Admins sehen diese Tabelle nicht – wenn Auswertungen gewünscht
--   sind, bitte eine eigene Policy auf Basis der bestehenden Rollen-Tabellen (managers/admins) ergänzen.
-- Bestehende Daten
--   Keine. Der Browser-Stand wird beim ersten Öffnen nach der Migration hochgeladen (Merge, nichts geht verloren).
-- Prüfung vor dem Einspielen
--   select to_regclass('public.lernskript_progress');  -- muss null sein
-- Rollback
--   drop table public.lernskript_progress;
-- ============================================================================
begin;

create table if not exists public.lernskript_progress (
  user_id            uuid        not null references auth.users (id) on delete cascade,
  module             text        not null check (module ~ '^\d+\.\d+\.\d+$'),
  chapter            text        not null default 'start',
  completed_chapters text[]      not null default '{}',
  stand              jsonb       not null default '{}'::jsonb,
  updated_at         timestamptz not null default now(),
  primary key (user_id, module)
);

create index if not exists lernskript_progress_updated_idx on public.lernskript_progress (updated_at);

alter table public.lernskript_progress enable row level security;
drop policy if exists "lernskript_progress eigene lesen" on public.lernskript_progress;
drop policy if exists "lernskript_progress eigene schreiben" on public.lernskript_progress;
drop policy if exists "lernskript_progress eigene aendern" on public.lernskript_progress;
create policy "lernskript_progress eigene lesen" on public.lernskript_progress
  for select to authenticated using (auth.uid() = user_id);
create policy "lernskript_progress eigene schreiben" on public.lernskript_progress
  for insert to authenticated with check (auth.uid() = user_id);
create policy "lernskript_progress eigene aendern" on public.lernskript_progress
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Schutz gegen Zurückschreiben älterer Stände: ein Update darf updated_at nicht in die Vergangenheit setzen.
create or replace function public.lernskript_progress_guard() returns trigger
language plpgsql as $$
begin
  if tg_op = 'UPDATE' and new.updated_at < old.updated_at then
    -- älterer Stand: nicht überschreiben, bestehende Zeile behalten
    return old;
  end if;
  return new;
end $$;
drop trigger if exists lernskript_progress_guard on public.lernskript_progress;
create trigger lernskript_progress_guard before update on public.lernskript_progress
  for each row execute function public.lernskript_progress_guard();

commit;
