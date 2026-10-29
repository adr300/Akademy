-- ============================================================================
-- 00  VORABPRÜFUNG – nur lesend, ändert nichts. Im Supabase-SQL-Editor ausführen und das Ergebnis zurückmelden.
-- Jede Zeile ist eine Prüfung: «pruefung», «ergebnis», «ok» (true = unkritisch).
-- ============================================================================
with spalten as (
  select table_name, string_agg(column_name || ':' || data_type, ', ' order by ordinal_position) as liste
    from information_schema.columns
   where table_schema = 'public'
     and table_name in ('courses','user_progress','user_xp','badges','user_badges','lernkarten_progress')
   group by table_name
)
select 'Spalten ' || table_name as pruefung, liste as ergebnis, true as ok from spalten
union all
select 'Typ courses.id', format_type(a.atttypid, a.atttypmod), true
  from pg_attribute a where a.attrelid = 'public.courses'::regclass and a.attname = 'id'
union all
select 'Schon vorhanden: lernskript_progress, question_answers, xp_events',
       coalesce(concat_ws(', ', to_regclass('public.lernskript_progress')::text, to_regclass('public.question_answers')::text, to_regclass('public.xp_events')::text), '–'),
       true
union all
select 'Schon vorhanden: award_xp, complete_lernkarten_set',
       coalesce(string_agg(p.oid::regprocedure::text, ', '), '–'), true
  from pg_proc p where p.pronamespace = 'public'::regnamespace and p.proname in ('award_xp','complete_lernkarten_set')
union all
select 'Dubletten lernkarten_progress (user_id, module, set_key)', count(*)::text, count(*) = 0
  from (select 1 from public.lernkarten_progress group by user_id, module, set_key having count(*) > 1) d
union all
select 'Module in lernkarten_progress', coalesce(string_agg(distinct module, ', '), '–'), true from public.lernkarten_progress
union all
select 'Dubletten user_badges (user_id, badge_id)', count(*)::text, count(*) = 0
  from (select 1 from public.user_badges group by user_id, badge_id having count(*) > 1) d
union all
select 'Dubletten courses (Titel)', count(*)::text, count(*) = 0
  from (select 1 from public.courses group by lower(trim(title)) having count(*) > 1) d
union all
select 'Dubletten user_progress (user_id, course_index)', count(*)::text, count(*) = 0
  from (select 1 from public.user_progress group by user_id, course_index having count(*) > 1) d
union all
select 'user_progress mit course_index ohne passenden Kurs', count(*)::text, count(*) = 0
  from public.user_progress where course_index >= (select count(*) from public.courses)
union all
select 'Abzeichen lk-112 … lk-115 schon vorhanden', count(*)::text, true
  from public.badges where key like 'lk-11_-%'
union all
select 'Zeilen user_xp / user_badges / user_progress / lernkarten_progress',
       concat_ws(' / ', (select count(*) from public.user_xp), (select count(*) from public.user_badges),
                        (select count(*) from public.user_progress), (select count(*) from public.lernkarten_progress)),
       true;
