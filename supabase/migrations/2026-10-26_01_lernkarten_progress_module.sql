-- ============================================================================
-- 2026-10-26_01  lernkarten_progress: Module 1.1.1 bis 1.1.5, eindeutiger Schlüssel, RLS
-- ----------------------------------------------------------------------------
-- Zweck: Das Frontend schreibt module = '1.1.1' … '1.1.5' (Set-Schlüssel 'A' …, '112-A' …) und liest alle Module in einer
--   Abfrage. Upsert mit onConflict 'user_id,module,set_key' braucht einen eindeutigen Index. Lernende sehen nur eigene Zeilen.
-- Bestehende Daten: nichts wird umbenannt. Exakte Dubletten (gleicher Nutzer, Modul, Set) werden auf eine Zeile reduziert,
--   sonst ließe sich der eindeutige Index nicht anlegen.
-- Rollback: drop index lernkarten_progress_user_module_set_uidx; alter table public.lernkarten_progress drop constraint lernkarten_progress_module_format;
-- ============================================================================
begin;

-- 1. Alte CHECK-Constraints auf «module» entfernen (z. B. module = '1.1.1'), außer dem neuen Format-Check
do $$
declare c record;
begin
  for c in
    select conname from pg_constraint
    where conrelid = 'public.lernkarten_progress'::regclass and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%module%' and conname <> 'lernkarten_progress_module_format'
  loop
    execute format('alter table public.lernkarten_progress drop constraint %I', c.conname);
  end loop;
end $$;

-- 2. Format des Modulschlüssels; «not valid» prüft nur neue Zeilen, alte bleiben unangetastet
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'lernkarten_progress_module_format' and conrelid = 'public.lernkarten_progress'::regclass) then
    alter table public.lernkarten_progress add constraint lernkarten_progress_module_format check (module ~ '^\d+\.\d+\.\d+$') not valid;
  end if;
end $$;

-- 3. Exakte Dubletten zusammenführen, dann eindeutiger Index (Grundlage des Upserts)
delete from public.lernkarten_progress a
 using public.lernkarten_progress b
 where a.user_id = b.user_id and a.module is not distinct from b.module and a.set_key = b.set_key and a.ctid > b.ctid;
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
