-- ============================================================================
-- 20  KONTROLLE nach dem Einspielen – nur lesend. Alle Zeilen sollten ok = true zeigen.
-- ============================================================================
select 'Tabelle lernskript_progress' as pruefung, (to_regclass('public.lernskript_progress') is not null)::text as ergebnis, to_regclass('public.lernskript_progress') is not null as ok
union all select 'Tabelle question_answers', (to_regclass('public.question_answers') is not null)::text, to_regclass('public.question_answers') is not null
union all select 'Tabelle xp_events', (to_regclass('public.xp_events') is not null)::text, to_regclass('public.xp_events') is not null
union all select 'Funktion award_xp(integer, text)', (to_regprocedure('public.award_xp(integer, text)') is not null)::text, to_regprocedure('public.award_xp(integer, text)') is not null
union all select 'Funktion complete_lernkarten_set', (to_regprocedure('public.complete_lernkarten_set(text, text, text)') is not null)::text, to_regprocedure('public.complete_lernkarten_set(text, text, text)') is not null
union all select 'Spalte user_progress.course_id',
                 coalesce((select data_type::text from information_schema.columns where table_schema = 'public' and table_name = 'user_progress' and column_name = 'course_id'), 'fehlt'),
                 exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'user_progress' and column_name = 'course_id')
union all select 'Abzeichen lk-112 … lk-115', count(*)::text, count(*) = 30 from public.badges where key like 'lk-11_-%'
union all select 'Index ' || i, (to_regclass('public.' || i) is not null)::text, to_regclass('public.' || i) is not null
  from unnest(array['lernkarten_progress_user_module_set_uidx','user_badges_user_badge_uidx','courses_title_uidx','user_progress_user_course_uidx','user_progress_course_id_idx']) i
union all select 'RLS aktiv ' || c.relname, c.relrowsecurity::text, c.relrowsecurity
  from pg_class c where c.relnamespace = 'public'::regnamespace and c.relname in ('lernkarten_progress','lernskript_progress','question_answers','xp_events')
union all select 'Policies ' || tablename, string_agg(policyname::text, ', '), count(*) > 0
  from pg_policies where schemaname = 'public' and tablename in ('lernkarten_progress','lernskript_progress','question_answers','xp_events') group by tablename
union all select 'Zeilen user_xp / user_badges / user_progress / lernkarten_progress',
       concat_ws(' / ', (select count(*) from public.user_xp), (select count(*) from public.user_badges),
                        (select count(*) from public.user_progress), (select count(*) from public.lernkarten_progress)), true;

-- Zusatz (Ergebnis bitte ebenfalls zurückmelden): Fortschrittszeilen ohne course_id nach dem Backfill.
-- Werte > 0 sind kein Fehler, wenn diese Zeilen auf Positionen ohne Kurs zeigen.
-- select count(*) from public.user_progress where course_id is null;
-- Zeilenzahlen mit der Vorabprüfung vergleichen: user_xp und user_progress gleich; user_badges und lernkarten_progress
-- gleich oder genau um die gemeldeten Dubletten kleiner.
