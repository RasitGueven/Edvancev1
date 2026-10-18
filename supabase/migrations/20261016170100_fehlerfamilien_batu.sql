-- Fehlerfamilien für Batus Pilot-Aufgaben: Zuordnungen, Elterntexte, Freigabe.
--
-- Grundlage: docs/themen/fehlerfamilien-batu.md (18.10.), von Rasit durchgesehen. Der Eltern-Report zeigt je Familie
-- nur fehlbild_familien.elterntext, und nur bei gesetztem fehlbild_familien.freigegeben_am (lsa_fehlbild_auswertung,
-- src/lib/reportFehlbilder.ts). Slugs ohne Familie fallen dort still weg.
--
-- 1. Vier neue Familien (schritt_vergessen, figuren, geraden_schaubilder, klammern), per on conflict do nothing.
-- 2. 32 Zuordnungen: 15 Slugs ohne Familie bekommen eine, 17 wechseln die Familie. Jede nur, wo die alte Familie noch
--    steht (is not distinct from).
-- 3. Sechs Elterntexte neu (gleichungen_umformen, vorzeichen, sachaufgaben, einheiten_massstab, potenzen_wurzeln, runden),
--    jeweils nur, wo noch der Vorher-Text steht.
-- 4. freigegeben_am = now() für die neun noch nicht freigegebenen Familien, nur wo leer. freigegeben_von bleibt leer.
--
-- Alles in einer Transaktion (mig klammert mit psql -1): Kein Slug fällt zwischendurch aus dem Report, auch nicht die
-- 17, die aus den schon freigegebenen Familien gleichungen_umformen, rechenreihenfolge und sachaufgaben in eine bisher
-- nicht freigegebene wechseln.
--
-- teilgekuerzt bekommt eine Familie (schritt_vergessen). F14 in supabase/checks/fehlbild_familien.PRUEFUNG.sql hielt
-- ihn offen, weil die Belege meist GAR NICHT gekürzt sind (4/12 statt 1/3), der Name aber „teilweise“ sagt. Das ist
-- eine Frage des Slug-Namens, nicht des Inhalts: Klartext („Kürzt den Bruch nicht vollständig …“, seit 20261016120100)
-- und Familiensatz („ohne einen Bruch bis zum Ende zu kürzen“) treffen beide Fälle. Das Umbenennen bleibt offen.
--
-- Idempotent; kein begin/commit.

do $ffb$
declare
  v_n integer;
  v_s integer := 0;
begin
  insert into public.fehlbild_familien (schluessel, elterntext)
  values
    ('schritt_vergessen',
     'Ihr Kind geht den richtigen Rechenweg, lässt aber einen Teil davon weg oder hört zu früh auf, etwa ohne das Halbieren in der Flächenformel eines Dreiecks oder ohne einen Bruch bis zum Ende zu kürzen.'),
    ('figuren',
     'Ihr Kind geht bei Figuren den richtigen Weg, setzt aber eine falsche Strecke oder einen falschen Winkel ein oder lässt einen Teil der Figur weg, etwa die schräge Seite statt der Höhe.'),
    ('geraden_schaubilder',
     'Ihr Kind arbeitet mit Geraden und Schaubildern, verwechselt dabei aber, welche Zahl wofür steht, etwa den Wert nach rechts mit dem nach oben, oder schätzt falsch ein, ob und wo sich zwei Geraden treffen.'),
    ('klammern',
     'Ihr Kind rechnet mit Klammern, verrechnet dabei aber nicht jeden Teil richtig, nimmt eine falsche Regel oder lässt eine nötige Klammer weg, etwa (x + 3)² = x² + 9 statt x² + 6x + 9.')
  on conflict (schluessel) do nothing;
  get diagnostics v_n = row_count;
  raise notice 'fehlerfamilien_batu: % neue Familie(n)', v_n;

  create temp table ffb_zuordnung (slug text primary key, alt text, neu text not null) on commit drop;
  insert into ffb_zuordnung (slug, alt, neu) values
    ('pfadregel_addiert', null, 'rechenart_formel'),
    ('zuruecklegen_ignoriert', null, 'sachaufgaben'),
    ('halbieren_vergessen', null, 'schritt_vergessen'),
    ('mal_zwei_vergessen', null, 'schritt_vergessen'),
    ('teilgekuerzt', null, 'schritt_vergessen'),
    ('differenz_vergessen', null, 'schritt_vergessen'),
    ('gegenereignis_nicht_abgezogen', null, 'schritt_vergessen'),
    ('nur_ein_pfad', null, 'schritt_vergessen'),
    ('nur_einmal_addiert', null, 'schritt_vergessen'),
    ('falsche_hoehe', null, 'figuren'),
    ('nur_eine_grundseite', null, 'figuren'),
    ('teilflaeche_vergessen', null, 'figuren'),
    ('basiswinkel_falsch_zugeordnet', null, 'figuren'),
    ('rechter_winkel_falsche_ecke', null, 'figuren'),
    ('koordinaten_vertauscht', null, 'geraden_schaubilder'),
    ('binom_formel_verwechselt', 'gleichungen_umformen', 'klammern'),
    ('mischglieder_nicht_aufgehoben', 'gleichungen_umformen', 'klammern'),
    ('quadrat_gliedweise', 'gleichungen_umformen', 'klammern'),
    ('klammer_falsch_gesetzt', 'gleichungen_umformen', 'klammern'),
    ('klammer_vergessen', 'gleichungen_umformen', 'klammern'),
    ('ausklammern_falsch_geteilt', 'gleichungen_umformen', 'klammern'),
    ('ausklammern_glied_nicht_geteilt', 'gleichungen_umformen', 'klammern'),
    ('ausklammern_nicht_ggt', 'gleichungen_umformen', 'schritt_vergessen'),
    ('faktorisierung_unvollstaendig', 'gleichungen_umformen', 'schritt_vergessen'),
    ('achsenabschnitt_verwechselt', 'gleichungen_umformen', 'geraden_schaubilder'),
    ('m_b_vertauscht', 'gleichungen_umformen', 'geraden_schaubilder'),
    ('steigung_kehrwert', 'gleichungen_umformen', 'geraden_schaubilder'),
    ('loesungsanzahl_verwechselt', 'gleichungen_umformen', 'geraden_schaubilder'),
    ('parallele_uebersehen', 'gleichungen_umformen', 'geraden_schaubilder'),
    ('mult_add_verwechslung', 'rechenreihenfolge', 'rechenart_formel'),
    ('wurzel_gliedweise', 'rechenreihenfolge', 'potenzen_wurzeln'),
    ('zu_frueh_gerundet', 'sachaufgaben', 'runden');

  update public.fehlbild_labels l
     set familie = z.neu
    from ffb_zuordnung z
   where l.slug = z.slug
     and l.familie is not distinct from z.alt;
  get diagnostics v_n = row_count;
  raise notice 'fehlerfamilien_batu: % Zuordnung(en) geändert', v_n;

  update public.fehlbild_familien
     set elterntext = 'Ihr Kind geht beim Lösen von Gleichungen den richtigen Weg, lässt aber einen Schritt aus, führt ihn nur zum Teil oder in die falsche Richtung aus oder übersieht eine zweite Lösung.'
   where schluessel = 'gleichungen_umformen'
     and elterntext = 'Ihr Kind kennt das Verfahren, überspringt beim Umformen aber Schritte oder wendet sie in der falschen Richtung an.';
  get diagnostics v_n = row_count; v_s := v_s + v_n;

  update public.fehlbild_familien
     set elterntext = 'Ihr Kind geht den richtigen Rechenweg, setzt aber ein Plus oder Minus falsch: ein Minuszeichen geht verloren, kommt hinzu oder wird umgedreht.'
   where schluessel = 'vorzeichen'
     and elterntext = 'Ihr Kind rechnet richtig, verliert beim Rechnen mit negativen Zahlen aber das Vorzeichen – das Ergebnis kippt ins Gegenteil.';
  get diagnostics v_n = row_count; v_s := v_s + v_n;

  update public.fehlbild_familien
     set elterntext = 'Ihr Kind rechnet sauber, beantwortet aber nicht genau die gestellte Frage: Es wählt einen Rechenweg, der nicht zur beschriebenen Situation passt, oder gibt eine andere Größe an als die gesuchte.'
   where schluessel = 'sachaufgaben'
     and elterntext = 'Ihr Kind rechnet sauber, wählt bei Textaufgaben aber den falschen Rechenweg für die beschriebene Situation.';
  get diagnostics v_n = row_count; v_s := v_s + v_n;

  update public.fehlbild_familien
     set elterntext = 'Ihr Kind erkennt, was gefragt ist, rechnet beim Umrechnen aber mit dem falschen Faktor, in die falsche Richtung oder gar nicht um.'
   where schluessel = 'einheiten_massstab'
     and elterntext = 'Ihr Kind erkennt die Aufgabe, rechnet beim Umwandeln aber mit dem falschen Faktor oder in die falsche Richtung.';
  get diagnostics v_n = row_count; v_s := v_s + v_n;

  update public.fehlbild_familien
     set elterntext = 'Ihr Kind rechnet bei Hochzahlen und Wurzeln nach einer Regel, die dort nicht gilt, oder hält eine Zahl fälschlich für eine Kommazahl, die endlos ohne Muster weitergeht, oder umgekehrt, etwa 3² als 3 · 2 oder √36 als die Hälfte von 36.'
   where schluessel = 'potenzen_wurzeln'
     and elterntext = 'Ihr Kind arbeitet bei Hochzahlen, Wurzeln und der Einordnung von Zahlen mit einer Vorstellung, die dort nicht passt, etwa 3² als 3 · 2 oder √36 als die Hälfte von 36.';
  get diagnostics v_n = row_count; v_s := v_s + v_n;

  update public.fehlbild_familien
     set elterntext = 'Ihr Kind rechnet richtig, rundet aber anders als verlangt oder zu früh, schneidet Stellen nur ab oder lässt das Runden ganz weg.'
   where schluessel = 'runden'
     and elterntext = 'Ihr Kind rechnet richtig, rundet das Ergebnis aber anders als verlangt, schneidet Stellen nur ab oder lässt das Runden ganz weg.';
  get diagnostics v_n = row_count; v_s := v_s + v_n;

  raise notice 'fehlerfamilien_batu: % Elterntext(e) geändert', v_s;

  update public.fehlbild_familien
     set freigegeben_am = now()
   where schluessel in ('brueche_anteile', 'kommazahlen', 'potenzen_wurzeln', 'rechenart_formel', 'runden', 'schritt_vergessen', 'figuren', 'geraden_schaubilder', 'klammern')
     and freigegeben_am is null
     and nullif(btrim(coalesce(elterntext, '')), '') is not null;
  get diagnostics v_n = row_count;
  raise notice 'fehlerfamilien_batu: % Familie(n) freigegeben', v_n;
end $ffb$;
