-- ============================================================================
-- 30  XP-PRÜFUNG nach dem Update – ändert nichts (Testaufrufe werden intern zurückgerollt).
-- Im SQL Editor komplett einfügen (Strg+A, Strg+C) → Run. Alle Zeilen sollten ok = true zeigen.
-- ============================================================================
drop table if exists _xp_pruefung;
create temp table _xp_pruefung (nr integer, pruefung text, ergebnis text, ok boolean);

-- 1. Spaltentypen von user_xp (award_xp liefert integer zurück)
insert into _xp_pruefung
select 1, 'Spaltentypen user_xp', string_agg(column_name || ':' || data_type, ', ' order by ordinal_position),
       bool_and(column_name not in ('total_xp', 'level') or data_type = 'integer')
  from information_schema.columns where table_schema = 'public' and table_name = 'user_xp';

-- 2./3. Testaufrufe als echter Nutzer (zuletzt aktiver Eintrag in user_xp), 0 XP, danach vollständig zurückgerollt
do $$
declare v_uid uuid; r1 record; r2 record; r3 record; m1 text; m2 text; o1 boolean := false; o2 boolean := false;
begin
  select user_id into v_uid from public.user_xp order by updated_at desc nulls last limit 1;
  if v_uid is null then
    insert into _xp_pruefung values (2, 'award_xp Testaufruf', 'kein Eintrag in user_xp – Test nicht möglich', true);
    return;
  end if;
  perform set_config('request.jwt.claims', json_build_object('sub', v_uid, 'role', 'authenticated')::text, true);
  begin
    select * into r1 from public.award_xp(0, 'pruefung:test');
    select * into r2 from public.award_xp(0, 'pruefung:test');
    m1 := format('ok – total_xp %s, level %s; zweiter Aufruf mit gleichem Ereignis ändert nichts (%s)', r1.total_xp, r1.level, r2.total_xp);
    o1 := r1.total_xp = r2.total_xp;
    select * into r3 from public.complete_lernkarten_set('1.1.2', 'pruefung', null);
    m2 := format('ok – badge_awarded %s, total_xp %s', r3.badge_awarded, r3.total_xp);
    o2 := true;
    raise exception using errcode = 'P0001', message = '__zurueckrollen__';
  exception when others then
    if sqlerrm <> '__zurueckrollen__' then
      if m1 is null then m1 := 'FEHLER: ' || sqlerrm; else m2 := 'FEHLER: ' || sqlerrm; end if;
    end if;
  end;
  insert into _xp_pruefung values (2, 'award_xp Testaufruf (0 XP, zurückgerollt)', m1, o1);
  insert into _xp_pruefung values (3, 'complete_lernkarten_set Testaufruf (zurückgerollt)', coalesce(m2, 'nicht erreicht'), o2);
end $$;

-- 4. Level passt zur XP-Summe (level = größtes l mit l²·100 ≤ total_xp)
insert into _xp_pruefung
select 4, 'Nutzer mit falschem Level', count(*)::text, count(*) = 0
  from public.user_xp where level <> public.level_from_xp(total_xp);

-- 5. Nutzung seit dem Update (Info)
insert into _xp_pruefung
select 5, 'Einmal-Ereignisse in xp_events (Kurs, Tagesbonus, Abzeichen)',
       coalesce((select string_agg(art || ': ' || n, ', ') from (select split_part(event, ':', 1) as art, count(*) as n from public.xp_events group by 1) x), 'noch keine'),
       true;
insert into _xp_pruefung
select 6, 'Letzte XP-Änderung (user_xp.updated_at)', coalesce(max(updated_at)::text, '–'), true from public.user_xp;

select pruefung, ergebnis, ok from _xp_pruefung order by nr;
