-- ============================================================================
-- 2026-10-26_05  user_progress: Fortschritt an course_id binden (statt nur an die Position course_index)
-- Status: VORBEREITET. Im Supabase-SQL-Editor ausführen (siehe supabase/README.md). Vorher Backup/Export von user_progress.
-- ----------------------------------------------------------------------------
-- Befund
--   user_progress kennt den Kurs nur über course_index = Position in courses (sortiert nach sort_order). Wird ein Kurs
--   gelöscht oder umsortiert, zeigt der Fortschritt aller Lernenden auf andere Kurse.
-- Lösung
--   Neue Spalte course_id (uuid, FK courses.id, on delete set null). Backfill aus der heutigen Position. Das Frontend
--   schreibt course_id ab sofort mit (und fällt zurück, wenn die Spalte fehlt) und liest bevorzugt über course_id.
--   course_index bleibt erhalten (Admin-Auswertungen, Unique-Key des Upserts) – nichts wird umnummeriert.
-- Betroffene Tabellen
--   public.user_progress (neue Spalte course_id, Index)
-- Bestehende Daten
--   Backfill setzt course_id nach der Position ZUM ZEITPUNKT DER MIGRATION. Das ist nur korrekt, wenn seit den letzten
--   Einträgen nicht umsortiert/gelöscht wurde. Vorher prüfen: select count(*) from user_progress where course_index >= (select count(*) from courses);
-- Rollback
--   alter table public.user_progress drop column course_id;
-- ============================================================================
begin;

alter table public.user_progress add column if not exists course_id uuid references public.courses (id) on delete set null;
create index if not exists user_progress_course_id_idx on public.user_progress (course_id);

-- Backfill nach heutiger Position
with pos as (
  select id, row_number() over (order by sort_order, id) - 1 as idx from public.courses
)
update public.user_progress p
   set course_id = pos.id
  from pos
 where p.course_id is null and p.course_index = pos.idx;

commit;

-- Kontrolle: Zeilen ohne course_id (Kurs existiert nicht mehr an dieser Position)
-- select * from public.user_progress where course_id is null;
