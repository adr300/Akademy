-- ============================================================================
-- 2026-10-26_06  Eindeutigkeit: keine doppelten Abzeichen, keine doppelten Kurstitel, keine doppelten Fortschrittszeilen
-- Status: VORBEREITET. Im Supabase-SQL-Editor ausführen (supabase/README.md).
-- ----------------------------------------------------------------------------
-- Zweck
--   - user_badges (user_id, badge_id): heute verhindert nur der Browser eine Doppelvergabe. Mit dem Unique kann die
--     RPC complete_lernkarten_set (Migration 07) «on conflict do nothing» nutzen.
--   - courses (title): der Import-Dublettenschutz liegt heute nur im Frontend.
--   - user_progress (user_id, course_index): Grundlage des bestehenden Upserts (sollte schon existieren; idempotent).
-- Bestehende Daten
--   user_badges: exakt doppelte Zeilen (gleicher Nutzer, gleiches Abzeichen) werden auf die älteste reduziert – inhaltlich
--   ändert sich nichts, das Abzeichen bleibt vergeben. courses und user_progress werden NICHT verändert: gibt es dort
--   Dubletten, wird der jeweilige Index übersprungen und eine NOTICE ausgegeben (dann manuell klären).
-- Rollback
--   drop index user_badges_user_badge_uidx; drop index courses_title_uidx; drop index user_progress_user_course_uidx;
-- ============================================================================
-- Kontrolle vorab (siehe auch supabase/00_vorabpruefung.sql):
-- select user_id, badge_id, count(*) from public.user_badges group by 1,2 having count(*) > 1;
-- select lower(trim(title)), count(*) from public.courses group by 1 having count(*) > 1;
-- select user_id, course_index, count(*) from public.user_progress group by 1,2 having count(*) > 1;

begin;

delete from public.user_badges a
 using public.user_badges b
 where a.user_id = b.user_id and a.badge_id = b.badge_id and a.ctid > b.ctid;
create unique index if not exists user_badges_user_badge_uidx on public.user_badges (user_id, badge_id);

do $$
begin
  if exists (select 1 from public.courses group by lower(trim(title)) having count(*) > 1) then
    raise notice 'Migration 06: doppelte Kurstitel vorhanden – courses_title_uidx NICHT angelegt';
  else
    create unique index if not exists courses_title_uidx on public.courses (lower(trim(title)));
  end if;
  if exists (select 1 from public.user_progress group by user_id, course_index having count(*) > 1) then
    raise notice 'Migration 06: doppelte Fortschrittszeilen vorhanden – user_progress_user_course_uidx NICHT angelegt';
  else
    create unique index if not exists user_progress_user_course_uidx on public.user_progress (user_id, course_index);
  end if;
end $$;

commit;
