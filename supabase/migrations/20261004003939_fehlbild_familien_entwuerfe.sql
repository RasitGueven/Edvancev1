-- W5-a Nachtrag — Entwurfs-Familien für die Fehlbilder der ersten LSA.
--
-- Ausgangslage: 22 Slugs aus den Themen der ersten LSA (Reelle Zahlen samt
-- Grundlagen) haben keine Familie. Der Elternbericht zeigt nur Familien-
-- Elterntexte; ohne Familie fällt ein Befund dort still weg. Die fünf
-- bestehenden Familien passen auf Brüche, Kommazahlen, Potenzen/Wurzeln und
-- Runden nicht (docs/fehlbilder/klartexte-entscheidungen.md, E7).
--
-- Diese Migration
--   * legt fünf neue Familien als ENTWURF an: freigegeben_am und
--     freigegeben_von bleiben NULL. lsa_fehlbild_auswertung liefert
--     familie_elterntext nur bei gesetztem fehlbild_familien.freigegeben_am
--     (`case when fam.freigegeben_am is null then null …`), und
--     src/lib/reportFehlbilder.ts verwirft jede Zeile ohne Elterntext. Bis
--     Lena abnimmt, erscheint also nichts davon im Elternbericht.
--   * ordnet die passenden Slugs zu — nur, wo familie leer ist, und nur zu
--     einer dieser fünf Familien, solange sie NICHT freigegeben ist. Eine
--     schon freigegebene Familie wird nie neu zugeordnet.
--   * lässt teilgekuerzt aus (fehlbild_familien.PRUEFUNG.sql F14).
--
-- Wiederholbar: Familien per on conflict do nothing, Zuordnung nur in leere
-- Felder. Sicherheitsgrenzen nur nach oben (höchstens 5 Familien, höchstens
-- 33 Zuordnungen), damit der Neuaufbau auf leerer DB nicht anschlägt.
--
-- KEIN begin/commit (der Runner klammert).

insert into public.fehlbild_familien (schluessel, elterntext)
values
  ('brueche_anteile',
   'Ihr Kind wendet bei Brüchen und Anteilen eine Regel an, die an dieser Stelle nicht gilt, oder teilt zwei Zahlen in umgekehrter Reihenfolge, etwa 1/2 + 1/6 = 2/8 oder 1/5 = 5.'),
  ('kommazahlen',
   'Ihr Kind rechnet mit Kommazahlen, setzt dabei aber das Komma, eine Ziffer oder einen Übertrag an die falsche Stelle oder gibt weniger Stellen an als verlangt.'),
  ('potenzen_wurzeln',
   'Ihr Kind arbeitet bei Hochzahlen, Wurzeln und der Einordnung von Zahlen mit einer Vorstellung, die dort nicht passt, etwa 3² als 3 · 2 oder √36 als die Hälfte von 36.'),
  ('runden',
   'Ihr Kind rechnet richtig, rundet das Ergebnis aber anders als verlangt, schneidet Stellen nur ab oder lässt das Runden ganz weg.'),
  ('rechenart_formel',
   'Ihr Kind rechnet sauber, nimmt aber eine andere Rechenart oder Formel, als die Aufgabe verlangt, etwa Plus statt Mal oder den Umfang statt der Fläche.')
on conflict (schluessel) do nothing;

create temp table w5a_zuordnung (
  slug    text primary key,
  familie text not null
);

insert into w5a_zuordnung (slug, familie) values
  -- Brüche und Anteile (LSA: additiv_gekuerzt, ziffern_gelesen, umgekehrt_geteilt)
  ('additiv_gekuerzt',          'brueche_anteile'),
  ('ziffern_gelesen',           'brueche_anteile'),
  ('umgekehrt_geteilt',         'brueche_anteile'),
  ('bezug_vertauscht',          'brueche_anteile'),
  ('nenner_addiert',            'brueche_anteile'),
  ('nenner_addiert_zaehler_ok', 'brueche_anteile'),
  ('zaehler_nicht_erweitert',   'brueche_anteile'),
  ('falschen_gestuerzt',        'brueche_anteile'),
  ('nicht_gestuerzt',           'brueche_anteile'),
  ('hauptnenner_bei_mult',      'brueche_anteile'),
  -- Kommazahlen (alle LSA)
  ('kommastellen_zu_viel',      'kommazahlen'),
  ('kommastellen_zu_wenig',     'kommazahlen'),
  ('komma_ignoriert',           'kommazahlen'),
  ('komma_nicht_verschoben',    'kommazahlen'),
  ('stellenwert_ignoriert',     'kommazahlen'),
  ('uebertrag_vergessen',       'kommazahlen'),
  -- Potenzen und Wurzeln (LSA außer potenzgesetz_verwechselt)
  ('mal_exponent',              'potenzen_wurzeln'),
  ('wurzel_halbiert',           'potenzen_wurzeln'),
  ('basis_exponent_vertauscht', 'potenzen_wurzeln'),
  ('vorzeichen_potenz',         'potenzen_wurzeln'),
  ('faktor_ohne_wurzel',        'potenzen_wurzeln'),
  ('irrational_verwechselt',    'potenzen_wurzeln'),
  ('potenzgesetz_verwechselt',  'potenzen_wurzeln'),
  -- Runden (alle LSA)
  ('abgeschnitten',             'runden'),
  ('falsche_stelle',            'runden'),
  ('immer_aufgerundet',         'runden'),
  -- Rechenart oder Formel verwechselt (LSA: plus_statt_mal,
  -- umfang_statt_flaeche, falsche_operation)
  ('plus_statt_mal',            'rechenart_formel'),
  ('umfang_statt_flaeche',      'rechenart_formel'),
  ('falsche_operation',         'rechenart_formel'),
  ('multipliziert_statt_dividiert', 'rechenart_formel'),
  ('flaeche_statt_umfang',      'rechenart_formel'),
  ('oberflaeche_statt_volumen', 'rechenart_formel'),
  ('volumen_statt_oberflaeche', 'rechenart_formel');

do $w5a$
declare
  v_fam integer;
  v_zug integer;
begin
  if exists (select 1 from w5a_zuordnung where slug = 'teilgekuerzt') then
    raise exception 'W5-a: teilgekuerzt bleibt laut F14 ohne Familie';
  end if;

  select count(*) into v_fam
    from public.fehlbild_familien
   where schluessel in (select distinct familie from w5a_zuordnung);
  if v_fam > 5 then
    raise exception 'W5-a: % Zielfamilien, höchstens 5 erwartet', v_fam;
  end if;

  update public.fehlbild_labels l
     set familie = z.familie
    from w5a_zuordnung z
    join public.fehlbild_familien f
      on f.schluessel = z.familie
     and f.freigegeben_am is null          -- nie in eine freigegebene Familie
   where l.slug = z.slug
     and (l.familie is null or btrim(l.familie) = '');
  get diagnostics v_zug = row_count;

  if v_zug > 33 then
    raise exception 'W5-a: % Zuordnungen, höchstens 33 erwartet', v_zug;
  end if;
  raise notice 'W5-a: % Slugs einer Entwurfs-Familie zugeordnet', v_zug;
end
$w5a$;

drop table w5a_zuordnung;
