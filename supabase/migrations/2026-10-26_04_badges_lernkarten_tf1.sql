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
begin;

create temp table _bluu_neue_badges (key text, title text, description text, icon text, xp_reward integer, sort_order integer) on commit drop;

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

commit;
