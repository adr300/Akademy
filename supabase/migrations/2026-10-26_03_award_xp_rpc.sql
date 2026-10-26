-- ============================================================================
-- 2026-10-26_03  award_xp: XP serverseitig vergeben (statt direktem Schreiben auf user_xp aus dem Browser)
-- Status: VORBEREITET, NICHT AUSGEFÜHRT. Zur Prüfung durch Adrian. Enthält zwei Stufen: 3a (Funktion, kompatibel) und
--         3b (Schreibrechte entziehen) – 3b erst einspielen, wenn das Frontend mit 3a nachweislich läuft.
-- ----------------------------------------------------------------------------
-- Befund
--   awardXP() im Frontend rechnet total_xp und level selbst aus und schreibt per upsert auf public.user_xp. Mit einer
--   RLS-Policy «eigene Zeile schreiben» kann ein Lernender den Wert damit beliebig setzen (Browser-Konsole). XP werden
--   außerdem bei jedem erneuten «Gewusst» einer Lernkarte erneut vergeben (Wiederholungen zählen) – das ist heute für
--   1.1.1 so und wurde für 1.1.2–1.1.5 beibehalten; eine Änderung ist eine fachliche Entscheidung (siehe DATENMODELL.md).
-- Lösung
--   Funktion award_xp(p_amount) mit SECURITY DEFINER, die nur für auth.uid() schreibt, den Betrag begrenzt und
--   total_xp/level zurückgibt. Das Frontend ruft sie auf, wenn sie existiert (Fehlercode PGRST202/42883 → Rückfall auf
--   das bisherige Upsert). Die Level-Formel entspricht levelFromXP() im Frontend und muss bei Änderungen dort mitgezogen werden.
-- Betroffene Objekte
--   public.user_xp (user_id, total_xp, level, updated_at); neue Funktion public.award_xp(integer)
-- RLS
--   3a ändert keine Policies. 3b entzieht authenticated das INSERT/UPDATE-Recht auf user_xp (nur noch über die Funktion).
-- Bestehende Daten
--   Unverändert.
-- Prüfung vor dem Einspielen
--   - levelFromXP() im Frontend mit der Formel unten vergleichen (Schwellen!).
--   - select * from pg_policies where tablename = 'user_xp';
-- Rollback
--   drop function public.award_xp(integer); (3b: grant insert, update on public.user_xp to authenticated;)
-- ============================================================================
begin;

-- Level-Formel wie im Frontend: xpForLevel(lvl) = lvl² · 100 (100, 400, 900, 1600 …), levelFromXP = größtes lvl mit lvl²·100 ≤ xp, mindestens 1.
-- BITTE MIT xpForLevel()/levelFromXP() IM FRONTEND ABGLEICHEN, bevor die Funktion eingespielt wird.
create or replace function public.level_from_xp(p_xp integer) returns integer
language sql immutable as $$
  select greatest(1, floor(sqrt(greatest(p_xp, 0) / 100.0))::integer);
$$;

create or replace function public.award_xp(p_amount integer)
returns table (total_xp integer, level integer)
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'nicht angemeldet' using errcode = '28000'; end if;
  if p_amount is null or p_amount < 0 or p_amount > 500 then raise exception 'ungueltiger XP-Betrag' using errcode = '22023'; end if;
  insert into public.user_xp as u (user_id, total_xp, level, updated_at)
    values (v_uid, p_amount, public.level_from_xp(p_amount), now())
  on conflict (user_id) do update
    set total_xp = u.total_xp + excluded.total_xp,
        level = public.level_from_xp(u.total_xp + excluded.total_xp),
        updated_at = now();
  return query select u.total_xp, u.level from public.user_xp u where u.user_id = v_uid;
end $$;

revoke all on function public.award_xp(integer) from public;
grant execute on function public.award_xp(integer) to authenticated;

commit;

-- ---------------------------------------------------------------------------
-- 3b (SPÄTER, nach Freigabe): direktes Schreiben auf user_xp aus dem Browser unterbinden.
-- begin;
-- revoke insert, update on public.user_xp from authenticated;
-- -- Lesen bleibt über die bestehende RLS-Policy möglich.
-- commit;
