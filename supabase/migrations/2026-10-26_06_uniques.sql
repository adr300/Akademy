-- ============================================================================
-- 2026-10-26_06  Eindeutigkeit: keine doppelten Abzeichen, keine doppelten Kurstitel, keine doppelten Fortschrittszeilen
-- Status: VORBEREITET. Im Supabase-SQL-Editor ausführen (supabase/README.md). Bricht ab, wenn es heute schon Dubletten gibt –
--         dann zuerst die Kontrollabfragen unten ausführen und bereinigen.
-- ----------------------------------------------------------------------------
-- Zweck
--   - user_badges (user_id, badge_id): heute verhindert nur der Browser eine Doppelvergabe. Mit dem Unique kann die
--     RPC complete_lernkarten_set (Migration 07) «on conflict do nothing» nutzen.
--   - courses (title): der Import-Dublettenschutz liegt heute nur im Frontend.
--   - user_progress (user_id, course_index): Grundlage des bestehenden Upserts (sollte schon existieren; idempotent).
-- Rollback
--   drop index user_badges_user_badge_uidx; drop index courses_title_uidx; drop index user_progress_user_course_uidx;
-- ============================================================================
-- Kontrolle vorab (müssen 0 Zeilen liefern):
-- select user_id, badge_id, count(*) from public.user_badges group by 1,2 having count(*) > 1;
-- select lower(trim(title)), count(*) from public.courses group by 1 having count(*) > 1;
-- select user_id, course_index, count(*) from public.user_progress group by 1,2 having count(*) > 1;

begin;
create unique index if not exists user_badges_user_badge_uidx on public.user_badges (user_id, badge_id);
create unique index if not exists courses_title_uidx on public.courses (lower(trim(title)));
create unique index if not exists user_progress_user_course_uidx on public.user_progress (user_id, course_index);
commit;
