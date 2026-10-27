-- ============================================================================
-- 2026-10-26_03  award_xp: XP serverseitig vergeben, einmalige Ereignisse ohne Doppelvergabe
-- ----------------------------------------------------------------------------
-- Befund: awardXP() im Browser rechnet total_xp/level selbst und schreibt per Upsert auf user_xp. Wiederholte Anfragen
--   (zwei Tabs, Doppelklick, Neuladen) können XP für denselben Kursabschluss oder dasselbe Abzeichen doppelt vergeben.
-- Lösung: award_xp(p_amount, p_event) mit SECURITY DEFINER. Schreibt nur für auth.uid(), begrenzt den Betrag, rechnet das
--   Level wie levelFromXP() im Frontend (lvl² · 100). Mit p_event (z. B. 'kurs:42', 'abzeichen:stromlaeufer') wird das Ereignis
--   in xp_events vermerkt; ein zweiter Aufruf mit demselben Ereignis vergibt nichts. Ohne p_event (Lernkarten) wie bisher.
-- Das Frontend ruft die Funktion auf, wenn sie existiert, sonst bisheriges Upsert.
-- 3b (später, separat): direktes Schreiben auf user_xp aus dem Browser entziehen – siehe unten.
-- Rollback: drop function public.award_xp(integer, text); drop table public.xp_events; drop function public.level_from_xp(integer);
-- ============================================================================
begin;

create or replace function public.level_from_xp(p_xp integer) returns integer
language sql immutable as $$
  select greatest(1, floor(sqrt(greatest(p_xp, 0) / 100.0))::integer);
$$;

create table if not exists public.xp_events (
  user_id    uuid        not null references auth.users (id) on delete cascade,
  event      text        not null check (length(event) between 1 and 120),
  amount     integer     not null,
  created_at timestamptz not null default now(),
  primary key (user_id, event)
);
alter table public.xp_events enable row level security;
drop policy if exists "xp_events eigene lesen" on public.xp_events;
create policy "xp_events eigene lesen" on public.xp_events for select to authenticated using (auth.uid() = user_id);
-- keine Insert/Update-Policy: Einträge entstehen nur über award_xp (SECURITY DEFINER)

drop function if exists public.award_xp(integer);
create or replace function public.award_xp(p_amount integer, p_event text default null)
returns table (total_xp integer, level integer)
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid(); v_n integer;
begin
  if v_uid is null then raise exception 'nicht angemeldet' using errcode = '28000'; end if;
  if p_amount is null or p_amount < 0 or p_amount > 500 then raise exception 'ungueltiger XP-Betrag' using errcode = '22023'; end if;
  if p_event is not null then
    insert into public.xp_events (user_id, event, amount) values (v_uid, p_event, p_amount) on conflict do nothing;
    get diagnostics v_n = row_count;
    if v_n = 0 then
      return query select u.total_xp, u.level from public.user_xp u where u.user_id = v_uid;
      return;
    end if;
  end if;
  insert into public.user_xp as u (user_id, total_xp, level, updated_at)
    values (v_uid, p_amount, public.level_from_xp(p_amount), now())
  on conflict (user_id) do update
    set total_xp = u.total_xp + excluded.total_xp,
        level = public.level_from_xp(u.total_xp + excluded.total_xp),
        updated_at = now();
  return query select u.total_xp, u.level from public.user_xp u where u.user_id = v_uid;
end $$;

revoke all on function public.award_xp(integer, text) from public;
grant execute on function public.award_xp(integer, text) to authenticated;

commit;

-- ---------------------------------------------------------------------------
-- 3b (ERST NACH TEST): direktes Schreiben auf user_xp aus dem Browser unterbinden (nur noch über award_xp).
-- begin;
-- revoke insert, update on public.user_xp from authenticated;
-- commit;
