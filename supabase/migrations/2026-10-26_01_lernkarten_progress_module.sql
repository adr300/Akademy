-- ============================================================================
-- 2026-10-26_01  lernkarten_progress: Module 1.1.1 bis 1.1.5, eindeutiger Schlüssel, RLS
-- Status: VORBEREITET, NICHT AUSGEFÜHRT. Zur Prüfung durch Adrian.
-- ----------------------------------------------------------------------------
-- Zweck
--   Das Frontend schreibt seit dem 26.10.2026 auch module = '1.1.2' … '1.1.5' (Set-Schlüssel '112-A' …) und liest alle fünf
--   Module in einer Abfrage (.in('module', …)). Diese Migration stellt sicher, dass die Tabelle das zulässt und dass ein
--   Lernender nur seine eigenen Zeilen lesen und schreiben kann.
-- Betroffene Tabellen
--   public.lernkarten_progress (user_id uuid, module text, set_key text, …)
-- Constraints und Indizes
--   - Falls ein CHECK auf module existiert (z. B. module = '1.1.1'), wird er entfernt und durch einen CHECK auf das Muster
--     '^\d+\.\d+\.\d+$' ersetzt (idempotent).
--   - Eindeutiger Index (user_id, module, set_key) – ihn braucht das Upsert mit onConflict 'user_id,module,set_key'.
-- RLS
--   - Policies «eigene Zeilen lesen/schreiben» auf auth.uid() = user_id; bestehende Policies gleichen Namens werden ersetzt.
-- Bestehende Daten
--   - Keine Umbenennung, kein Löschen. Vorhandene Zeilen mit module = '1.1.1' bleiben gültig.
-- Prüfung vor dem Einspielen
--   select conname, pg_get_constraintdef(oid) from pg_constraint where conrelid = 'public.lernkarten_progress'::regclass;
--   select indexname, indexdef from pg_indexes where tablename = 'lernkarten_progress';
--   select policyname, cmd, qual, with_check from pg_policies where tablename = 'lernkarten_progress';
-- Rollback
--   drop policy … ; drop index if exists lernkarten_progress_user_module_set_uidx; alter table … drop constraint lernkarten_progress_module_format;
-- ============================================================================
begin;

-- 1. Vorhandene CHECK-Constraints auf «module» entfernen (nur solche, die die Spalte module einschränken)
do $$
declare c record;
begin
  for c in
    select conname from pg_constraint
    where conrelid = 'public.lernkarten_progress'::regclass and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%module%'
  loop
    execute format('alter table public.lernkarten_progress drop constraint %I', c.conname);
  end loop;
end $$;

-- 2. Format des Modulschlüssels (1.1.1, 1.1.2, …)
alter table public.lernkarten_progress
  add constraint lernkarten_progress_module_format check (module ~ '^\d+\.\d+\.\d+$');

-- 3. Eindeutigkeit je Lernendem, Modul und Set (Grundlage des Upserts)
create unique index if not exists lernkarten_progress_user_module_set_uidx
  on public.lernkarten_progress (user_id, module, set_key);

-- 4. Zeitstempel, falls er fehlt
alter table public.lernkarten_progress add column if not exists updated_at timestamptz not null default now();

-- 5. RLS: nur eigene Zeilen
alter table public.lernkarten_progress enable row level security;
drop policy if exists "lernkarten_progress eigene lesen" on public.lernkarten_progress;
drop policy if exists "lernkarten_progress eigene schreiben" on public.lernkarten_progress;
drop policy if exists "lernkarten_progress eigene aendern" on public.lernkarten_progress;
create policy "lernkarten_progress eigene lesen" on public.lernkarten_progress
  for select to authenticated using (auth.uid() = user_id);
create policy "lernkarten_progress eigene schreiben" on public.lernkarten_progress
  for insert to authenticated with check (auth.uid() = user_id);
create policy "lernkarten_progress eigene aendern" on public.lernkarten_progress
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

commit;
