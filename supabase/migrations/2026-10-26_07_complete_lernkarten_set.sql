-- ============================================================================
-- 2026-10-26_07  complete_lernkarten_set: Abschluss eines Lernkarten-Sets als eine Transaktion (Abschluss + Abzeichen + XP)
-- Status: VORBEREITET. Voraussetzungen: Migration 03 (award_xp) und 06 (Unique auf user_badges). Im SQL-Editor ausführen.
-- ----------------------------------------------------------------------------
-- Zweck
--   Heute macht der Browser drei getrennte Schreibzugriffe (lernkarten_progress, user_badges, user_xp). Schlägt einer fehl,
--   bleibt ein Teilzustand. Diese Funktion macht alles in einer Transaktion und ist idempotent: ein zweiter Aufruf legt
--   nichts doppelt an und vergibt kein zweites Abzeichen und keine zweiten Abzeichen-XP.
--   Das Frontend ruft sie auf, wenn sie existiert (sonst bisheriger Weg).
-- Sicherheit
--   SECURITY DEFINER, schreibt nur für auth.uid(); Eingaben werden geprüft (Modulformat, Set-Schlüssel, Abzeichen-Schlüssel).
--   Ausführung nur für authenticated.
-- Rollback
--   drop function public.complete_lernkarten_set(text, text, text);
-- ============================================================================
begin;

create or replace function public.complete_lernkarten_set(p_module text, p_set_key text, p_badge_key text default null)
returns table (badge_awarded boolean, total_xp integer, level integer)
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_badge record;
  v_n integer := 0;
  v_awarded boolean := false;
begin
  if v_uid is null then raise exception 'nicht angemeldet' using errcode = '28000'; end if;
  if p_module is null or p_module !~ '^\d+\.\d+\.\d+$' then raise exception 'ungueltiges Modul' using errcode = '22023'; end if;
  if p_set_key is null or length(p_set_key) < 1 or length(p_set_key) > 20 then raise exception 'ungueltiger Set-Schluessel' using errcode = '22023'; end if;

  -- 1. Abschluss (idempotent)
  insert into public.lernkarten_progress (user_id, module, set_key)
    values (v_uid, p_module, p_set_key)
  on conflict (user_id, module, set_key) do nothing;

  -- 2. Abzeichen, falls definiert und noch nicht vergeben
  if p_badge_key is not null then
    select b.id, coalesce(b.xp_reward, 50) as xp_reward into v_badge from public.badges b where b.key = p_badge_key;
    if found then
      insert into public.user_badges (user_id, badge_id) values (v_uid, v_badge.id)
      on conflict (user_id, badge_id) do nothing;
      get diagnostics v_n = row_count;
      if v_n > 0 then
        v_awarded := true;
        perform public.award_xp(v_badge.xp_reward);
      end if;
    end if;
  end if;

  -- 3. Stand zurückgeben
  return query
    select v_awarded, coalesce(u.total_xp, 0), coalesce(u.level, 1)
      from (select 1) s left join public.user_xp u on u.user_id = v_uid;
end $$;

revoke all on function public.complete_lernkarten_set(text, text, text) from public;
grant execute on function public.complete_lernkarten_set(text, text, text) to authenticated;

commit;
