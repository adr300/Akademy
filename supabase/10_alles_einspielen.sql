-- ============================================================================
-- 10  ALLES EINSPIELEN – Migrationen 2026-10-26_01 bis _08 in EINER Transaktion.
-- Erzeugt aus supabase/migrations/ (die Einzeldateien bleiben die Referenz). Schlägt ein Schritt fehl, wird nichts übernommen.
-- Vorher: Backup (Anleitung Schritt 1) und 00_vorabpruefung.sql. Danach: 20_kontrolle.sql.
-- NICHT enthalten: Teil 3b (Entzug des direkten Schreibrechts auf user_xp) – erst nach erfolgreichem Test, separat.
-- Kann gefahrlos ein zweites Mal ausgeführt werden (alle Schritte idempotent).
-- ============================================================================
begin;


-- >>>>>>>>>> 2026-10-26_01_lernkarten_progress_module.sql <<<<<<<<<<
-- ============================================================================
-- 2026-10-26_01  lernkarten_progress: Module 1.1.1 bis 1.1.5, eindeutiger Schlüssel, RLS
-- ----------------------------------------------------------------------------
-- Zweck: Das Frontend schreibt module = '1.1.1' … '1.1.5' (Set-Schlüssel 'A' …, '112-A' …) und liest alle Module in einer
--   Abfrage. Upsert mit onConflict 'user_id,module,set_key' braucht einen eindeutigen Index. Lernende sehen nur eigene Zeilen.
-- Bestehende Daten: nichts wird umbenannt. Exakte Dubletten (gleicher Nutzer, Modul, Set) werden auf eine Zeile reduziert,
--   sonst ließe sich der eindeutige Index nicht anlegen.
-- Rollback: drop index lernkarten_progress_user_module_set_uidx; alter table public.lernkarten_progress drop constraint lernkarten_progress_module_format;
-- ============================================================================

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


-- >>>>>>>>>> 2026-10-26_02_lernskript_progress.sql <<<<<<<<<<
-- ============================================================================
-- 2026-10-26_02  lernskript_progress: Lernskript-Stand je Lernendem und Modul (geräteübergreifend)
-- Status: VORBEREITET, NICHT AUSGEFÜHRT. Zur Prüfung durch Adrian.
-- ----------------------------------------------------------------------------
-- Zweck
--   Der Lernskript-Stand (Kapitel, Häkchen «Das kann ich jetzt», Eingaben, Schriftgröße) liegt heute nur im Browser
--   (localStorage «bluu-ls-<modul>-<uid>»). Der Block BLUU-LS-SYNC im Frontend schreibt den Stand zusätzlich in diese Tabelle
--   und führt beim Öffnen des Lernskripts den Browser-Stand mit dem Server-Stand zusammen (Regeln: docs/DATENMODELL.md).
--   Fehlt die Tabelle, merkt das Frontend das am Fehlercode und bleibt still beim Browser-Stand – diese Migration ist
--   also optional, aber nötig für den Gerätewechsel.
-- Betroffene Tabellen
--   neu: public.lernskript_progress
-- Spalten
--   user_id uuid (auth.users), module text ('1.1.1' …), chapter text (zuletzt besuchtes Kapitel oder 'start'),
--   completed_chapters text[] (Kapitel mit allen Häkchen), stand jsonb (vollständiger Browser-Stand, Quelle der Wahrheit
--   für Eingaben), updated_at timestamptz.
-- Constraints und Indizes
--   Primärschlüssel (user_id, module); CHECK auf das Modulformat; Index auf updated_at für spätere Auswertungen.
-- RLS
--   Nur eigene Zeilen (select/insert/update). Manager und Admins sehen diese Tabelle nicht – wenn Auswertungen gewünscht
--   sind, bitte eine eigene Policy auf Basis der bestehenden Rollen-Tabellen (managers/admins) ergänzen.
-- Bestehende Daten
--   Keine. Der Browser-Stand wird beim ersten Öffnen nach der Migration hochgeladen (Merge, nichts geht verloren).
-- Prüfung vor dem Einspielen
--   select to_regclass('public.lernskript_progress');  -- muss null sein
-- Rollback
--   drop table public.lernskript_progress;
-- ============================================================================

create table if not exists public.lernskript_progress (
  user_id            uuid        not null references auth.users (id) on delete cascade,
  module             text        not null check (module ~ '^\d+\.\d+\.\d+$'),
  chapter            text        not null default 'start',
  completed_chapters text[]      not null default '{}',
  stand              jsonb       not null default '{}'::jsonb,
  updated_at         timestamptz not null default now(),
  primary key (user_id, module)
);

create index if not exists lernskript_progress_updated_idx on public.lernskript_progress (updated_at);

alter table public.lernskript_progress enable row level security;
drop policy if exists "lernskript_progress eigene lesen" on public.lernskript_progress;
drop policy if exists "lernskript_progress eigene schreiben" on public.lernskript_progress;
drop policy if exists "lernskript_progress eigene aendern" on public.lernskript_progress;
create policy "lernskript_progress eigene lesen" on public.lernskript_progress
  for select to authenticated using (auth.uid() = user_id);
create policy "lernskript_progress eigene schreiben" on public.lernskript_progress
  for insert to authenticated with check (auth.uid() = user_id);
create policy "lernskript_progress eigene aendern" on public.lernskript_progress
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Schutz gegen Zurückschreiben älterer Stände: ein Update darf updated_at nicht in die Vergangenheit setzen.
create or replace function public.lernskript_progress_guard() returns trigger
language plpgsql as $$
begin
  if tg_op = 'UPDATE' and new.updated_at < old.updated_at then
    -- älterer Stand: nicht überschreiben, bestehende Zeile behalten
    return old;
  end if;
  return new;
end $$;
drop trigger if exists lernskript_progress_guard on public.lernskript_progress;
create trigger lernskript_progress_guard before update on public.lernskript_progress
  for each row execute function public.lernskript_progress_guard();


-- >>>>>>>>>> 2026-10-26_03_award_xp_rpc.sql <<<<<<<<<<
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


-- >>>>>>>>>> 2026-10-26_04_badges_lernkarten_tf1.sql <<<<<<<<<<
-- ============================================================================
-- 2026-10-26_04  Abzeichen für die Lernkarten-Sets 1.1.2 bis 1.1.5
-- Status: VORBEREITET. 1.1.2: Namen aus dem Lernkarten-Dokument (Entflechter … Rechnungsleser); 1.1.3–1.1.5: Set-Titel als Vorschlag.
-- ----------------------------------------------------------------------------
-- Befund
--   Die Sets von 1.1.1 vergeben beim Abschluss ein Abzeichen (badges.key «stromlaeufer» …, aus dem Lernkarten-Dokument).
--   Die Word-Dateien 1.1.2–1.1.5 nennen keine Abzeichen. Das Frontend trägt für jedes neue Set den Schlüssel
--   «lk-<modul ohne Punkte>-<Buchstabe>» (z. B. lk-112-A) ein; existiert dazu keine Zeile in public.badges, gibt es kein
--   Abzeichen und auch keinen irreführenden Hinweis im Abschluss-Popup. Sobald diese Zeilen vorhanden sind, vergibt das
--   Frontend sie ohne weitere Änderung (einmalig je Nutzer, wie bei 1.1.1 über user_badges).
-- Betroffene Tabellen
--   public.badges – Pflicht sind key und title; das Frontend liest key, title, icon, xp_reward.
-- Bestehende Daten
--   Nur Inserts für Schlüssel, die es noch nicht gibt (kein «on conflict», damit kein Unique-Index auf key nötig ist).
--   Eingefügt werden nur die Spalten, die public.badges tatsächlich hat (description/icon/xp_reward/sort_order optional).
--   Bereits vorhandene oder vergebene Abzeichen bleiben unberührt.
-- Rollback
--   delete from public.badges where key like 'lk-11[2345]-%';
-- ============================================================================

drop table if exists _bluu_neue_badges;
create temp table _bluu_neue_badges (key text, title text, description text, icon text, xp_reward integer, sort_order integer);

insert into _bluu_neue_badges (key, title, description, icon, xp_reward, sort_order) values
  -- 1.1.2 Aufbau des Energiemarktes
  ('lk-112-A', 'Entflechter', 'Lernkarten-Set A von Modul 1.1.2 gelernt', '🏅', 50, 200),
  ('lk-112-B', 'Monopol-Kenner',           'Lernkarten-Set B von Modul 1.1.2 gelernt', '🏅', 50, 201),
  ('lk-112-C', 'Rollenprofi',          'Lernkarten-Set C von Modul 1.1.2 gelernt', '🏅', 50, 202),
  ('lk-112-D', 'Kundenversteher',                   'Lernkarten-Set D von Modul 1.1.2 gelernt', '🏅', 50, 203),
  ('lk-112-E', 'Regelkenner',               'Lernkarten-Set E von Modul 1.1.2 gelernt', '🏅', 50, 204),
  ('lk-112-F', 'Prozess-Pilot',          'Lernkarten-Set F von Modul 1.1.2 gelernt', '🏅', 50, 205),
  ('lk-112-G', 'Spartenprofi',             'Lernkarten-Set G von Modul 1.1.2 gelernt', '🏅', 50, 206),
  ('lk-112-H', 'Wertschöpfer', 'Lernkarten-Set H von Modul 1.1.2 gelernt', '🏅', 50, 207),
  ('lk-112-I', 'Rechnungsleser', 'Lernkarten-Set I von Modul 1.1.2 gelernt', '🏅', 50, 208),
  -- 1.1.3 Marktrollen im Strommarkt
  ('lk-113-A', 'Warum ein Rollenmodell?',                'Lernkarten-Set A von Modul 1.1.3 gelernt', '🏅', 50, 210),
  ('lk-113-B', 'Ein Unternehmen, mehrere Rollen',        'Lernkarten-Set B von Modul 1.1.3 gelernt', '🏅', 50, 211),
  ('lk-113-C', 'Netzbetreiber und Lieferant',            'Lernkarten-Set C von Modul 1.1.3 gelernt', '🏅', 50, 212),
  ('lk-113-D', 'Messstellenbetreiber und Bilanzkreisverantwortlicher', 'Lernkarten-Set D von Modul 1.1.3 gelernt', '🏅', 50, 213),
  ('lk-113-E', 'Übertragungsnetzbetreiber, Bilanzkreis und Gebiete',  'Lernkarten-Set E von Modul 1.1.3 gelernt', '🏅', 50, 214),
  ('lk-113-F', 'Marktwelt und Technikwelt',              'Lernkarten-Set F von Modul 1.1.3 gelernt', '🏅', 50, 215),
  ('lk-113-G', 'Praxisfall: Eine Marktlokation, viele Beteiligte', 'Lernkarten-Set G von Modul 1.1.3 gelernt', '🏅', 50, 216),
  -- 1.1.4 Marktrollen im Gasmarkt
  ('lk-114-A', 'Gas ist anders',                         'Lernkarten-Set A von Modul 1.1.4 gelernt', '🏅', 50, 220),
  ('lk-114-B', 'Rollenmodell und Entry-Exit',            'Lernkarten-Set B von Modul 1.1.4 gelernt', '🏅', 50, 221),
  ('lk-114-C', 'Netzbetreiber und Marktgebietsverantwortlicher', 'Lernkarten-Set C von Modul 1.1.4 gelernt', '🏅', 50, 222),
  ('lk-114-D', 'Transportkunde, Lieferant und BKV',      'Lernkarten-Set D von Modul 1.1.4 gelernt', '🏅', 50, 223),
  ('lk-114-E', 'Messung und Objekte im Gas',             'Lernkarten-Set E von Modul 1.1.4 gelernt', '🏅', 50, 224),
  ('lk-114-F', 'Marktgebiet und Regelwerke',             'Lernkarten-Set F von Modul 1.1.4 gelernt', '🏅', 50, 225),
  ('lk-114-G', 'Zusammenspiel und Praxis',               'Lernkarten-Set G von Modul 1.1.4 gelernt', '🏅', 50, 226),
  -- 1.1.5 Lokationen und Identifikatoren
  ('lk-115-A', 'Warum IDs? Der Überblick',               'Lernkarten-Set A von Modul 1.1.5 gelernt', '🏅', 50, 230),
  ('lk-115-B', 'Marktlokation, Messlokation und Zählpunkt', 'Lernkarten-Set B von Modul 1.1.5 gelernt', '🏅', 50, 231),
  ('lk-115-C', 'Die Marktpartner-ID',                    'Lernkarten-Set C von Modul 1.1.5 gelernt', '🏅', 50, 232),
  ('lk-115-D', 'Die Marktlokations-ID',                  'Lernkarten-Set D von Modul 1.1.5 gelernt', '🏅', 50, 233),
  ('lk-115-E', 'NeLo-, NeBe-, Ressourcen- und Paket-ID', 'Lernkarten-Set E von Modul 1.1.5 gelernt', '🏅', 50, 234),
  ('lk-115-F', 'Vergabe, Zuordnung und Prüfziffern',     'Lernkarten-Set F von Modul 1.1.5 gelernt', '🏅', 50, 235),
  ('lk-115-G', 'Praxisfall: Der ID-Check',               'Lernkarten-Set G von Modul 1.1.5 gelernt', '🏅', 50, 236);

do $$
declare v_spalten text; v_n integer;
begin
  select string_agg(quote_ident(c), ', ' order by o) into v_spalten
    from unnest(array['key','title','description','icon','xp_reward','sort_order']) with ordinality as t(c, o)
   where exists (select 1 from information_schema.columns
                  where table_schema = 'public' and table_name = 'badges' and column_name = t.c);
  if v_spalten is null or v_spalten not like '%key%' or v_spalten not like '%title%' then
    raise exception 'public.badges hat keine Spalten key/title – Migration 04 abgebrochen';
  end if;
  execute format('insert into public.badges (%1$s) select %1$s from _bluu_neue_badges n
                   where not exists (select 1 from public.badges b where b.key = n.key)', v_spalten);
  get diagnostics v_n = row_count;
  raise notice 'Migration 04: % Abzeichen neu angelegt (Spalten: %)', v_n, v_spalten;
end $$;


-- >>>>>>>>>> 2026-10-26_05_user_progress_course_id.sql <<<<<<<<<<
-- ============================================================================
-- 2026-10-26_05  user_progress: Fortschritt an course_id binden (statt nur an die Position course_index)
-- Status: VORBEREITET. Im Supabase-SQL-Editor ausführen (siehe supabase/README.md). Vorher Backup/Export von user_progress.
-- ----------------------------------------------------------------------------
-- Befund
--   user_progress kennt den Kurs nur über course_index = Position in courses (sortiert nach sort_order). Wird ein Kurs
--   gelöscht oder umsortiert, zeigt der Fortschritt aller Lernenden auf andere Kurse.
-- Lösung
--   Neue Spalte course_id (gleicher Typ wie courses.id – heute bigint –, FK courses.id, on delete set null). Backfill aus der heutigen Position. Das Frontend
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

do $$
declare v_typ text;
begin
  select format_type(a.atttypid, a.atttypmod) into v_typ
    from pg_attribute a where a.attrelid = 'public.courses'::regclass and a.attname = 'id' and not a.attisdropped;
  if not exists (select 1 from information_schema.columns
                  where table_schema = 'public' and table_name = 'user_progress' and column_name = 'course_id') then
    execute format('alter table public.user_progress add column course_id %s references public.courses (id) on delete set null', v_typ);
  end if;
end $$;
create index if not exists user_progress_course_id_idx on public.user_progress (course_id);

-- Backfill nach heutiger Position
with pos as (
  select id, row_number() over (order by sort_order, id) - 1 as idx from public.courses
)
update public.user_progress p
   set course_id = pos.id
  from pos
 where p.course_id is null and p.course_index = pos.idx;


-- Kontrolle: Zeilen ohne course_id (Kurs existiert nicht mehr an dieser Position)
-- select * from public.user_progress where course_id is null;


-- >>>>>>>>>> 2026-10-26_06_uniques.sql <<<<<<<<<<
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


-- >>>>>>>>>> 2026-10-26_07_complete_lernkarten_set.sql <<<<<<<<<<
-- ============================================================================
-- 2026-10-26_07  complete_lernkarten_set: Abschluss eines Lernkarten-Sets als eine Transaktion (Abschluss + Abzeichen + XP)
-- Status: VORBEREITET. Voraussetzungen: Migration 01 (Unique auf lernkarten_progress), 03 (award_xp mit Ereignis) und
--         06 (Unique auf user_badges). Im SQL-Editor ausführen.
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
        perform public.award_xp(least(v_badge.xp_reward, 500), 'abzeichen:' || p_badge_key);
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


-- >>>>>>>>>> 2026-10-26_08_question_answers.sql <<<<<<<<<<
-- ============================================================================
-- 2026-10-26_08  question_answers: Antwortprotokoll je Lernendem, Lektion und Frage
-- Status: VORBEREITET. Im Supabase-SQL-Editor ausführen (supabase/README.md).
-- ----------------------------------------------------------------------------
-- Befund
--   Eine Lektion speichert heute nur completed/score in user_progress. Welche Frage wie beantwortet wurde, ist weder für
--   Lernende (Nachsehen, Wiederholen der Fehler) noch für Manager (schwierige Fragen) sichtbar.
-- Lösung
--   Tabelle question_answers: eine Zeile je beantworteter Frage und Versuch. Das Frontend (Block BLUU-ANTWORTEN) schreibt sie
--   am Ende eines Tests; fehlt die Tabelle, bleibt das Protokoll im Browser. Die Analytics-Auswertung zeigt daraus die
--   Fragen mit der höchsten Fehlerquote.
-- Spalten
--   user_id uuid, course_id bigint (courses.id), question_id bigint (questions.id, null wenn die Frage gelöscht wurde),
--   attempt text (Versuchskennung = Startzeit), correct boolean, answer jsonb {typ, antwort, loesung}, answered_at timestamptz.
-- RLS
--   Lernende: eigene Zeilen lesen und einfügen (kein Update/Delete). Manager und Admins: alle lesen (über die bestehenden
--   Tabellen managers/admins, Spalte user_id – bitte prüfen).
-- Bestehende Daten
--   Keine. Datenschutz: Antworten sind personenbezogen; Aufbewahrung wie user_progress behandeln.
-- Rollback
--   drop table public.question_answers;
-- ============================================================================

create table if not exists public.question_answers (
  id           bigserial primary key,
  user_id      uuid        not null references auth.users (id) on delete cascade,
  course_id    bigint      not null,  -- courses.id (bigint); bewusst ohne FK, damit das Protokoll das Löschen eines Kurses überlebt
  question_id  bigint,
  attempt      text        not null,
  correct      boolean     not null,
  answer       jsonb       not null default '{}'::jsonb,
  answered_at  timestamptz not null default now()
);
create index if not exists question_answers_user_idx on public.question_answers (user_id, course_id, answered_at desc);
create index if not exists question_answers_question_idx on public.question_answers (course_id, question_id);

alter table public.question_answers enable row level security;
drop policy if exists "question_answers eigene lesen" on public.question_answers;
drop policy if exists "question_answers eigene schreiben" on public.question_answers;
drop policy if exists "question_answers verwaltung lesen" on public.question_answers;
create policy "question_answers eigene lesen" on public.question_answers
  for select to authenticated using (auth.uid() = user_id);
create policy "question_answers eigene schreiben" on public.question_answers
  for insert to authenticated with check (auth.uid() = user_id);
create policy "question_answers verwaltung lesen" on public.question_answers
  for select to authenticated using (
    exists (select 1 from public.admins a where a.user_id = auth.uid())
    or exists (select 1 from public.managers m where m.user_id = auth.uid())
  );


commit;
