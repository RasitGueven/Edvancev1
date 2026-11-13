-- ============================================================================
-- SF-1 · S2 Lehrplan je Schulform: klp_themenplan und skill_schulform
-- ============================================================================
-- 1. klp_themenplan: Themen des Kernlehrplans je Schulform, Fassung, Doppeljahrgang und Kurs, abgebildet auf
--    public.themen. Quelle Lehrplannavigator NRW (Dateien in docs/msa/quellen/, Abruf 12.11.2026), Fundstelle
--    je Zeile. Für Gymnasien ohne eigenen Plan die Fassung 'g9': Klasse je Thema = häufigste Klasse unter den
--    Gymnasien mit Plan (schul_themenplan, dbread 13.11.2026).
--    Reihenfolge (position) innerhalb eines Doppeljahrgangs: Der KLP legt keine fest (MSA-0 §5b). Sie folgt der
--    üblichen Lage am Gymnasium (häufigste Klasse, dann mittlere Position im Schulplan), sonst themen.sort.
-- 2. skill_schulform: Skills, die eine Schulform (bzw. ein Kurs) nach einer KLP-Fassung nicht verlangt. Kein
--    Eintrag = zulässig. Die Fassung ist nötig: Der KLP 2022 nimmt bedingte Wahrscheinlichkeit, Vierfeldertafel und
--    a·sin(b·x) auf, die der KLP 2004 nicht kennt (docs/schulformen/sf1/quellen/skill_sperren.csv).
--    skill_zulaessig(skill, schulform, kurs, fassung) liest das; Kurs null gilt als E, Fassung null prüft nur die
--    Sperren für alle Fassungen.
-- 3. klp_fassung(schuljahr, klasse, schulform): Regel aus ist-analyse §5 an einer Stelle (RdErl. 02.06.2022).
-- Erzeugt von scripts/schulformen/klp_sql.py aus docs/schulformen/sf1/quellen/klp_themen.csv und
-- docs/schulformen/sf1/quellen/skill_sperren.csv.
-- Rollback: supabase/rollback/20261113153241_sf1_klp_themenplan.sql
-- ============================================================================

-- 1 · klp_themenplan ------------------------------------------------------------
create table public.klp_themenplan (
  id             bigint generated always as identity primary key,
  fach           text not null check (fach = lower(fach)),
  schulform      text not null check (schulform = any (array['Gymnasium', 'Realschule', 'Gesamtschule', 'Sekundarschule'])),
  klp_fassung    text not null check (klp_fassung = any (array['2004', '2022', 'g9'])),
  doppeljahrgang text not null check (doppeljahrgang = any (array['7/8', '9/10', '7', '8', '9', '10'])),
  kurs           text not null default 'alle' check (kurs = any (array['E', 'G', 'alle'])),
  position       integer not null check (position > 0),
  thema_key      text not null references public.themen (thema_key) on delete cascade,
  nur_teil       text,
  fundstelle     text not null,
  constraint klp_themenplan_g9_check check ((klp_fassung = 'g9') = (strpos(doppeljahrgang, '/') = 0)),
  constraint klp_themenplan_uniq unique (fach, schulform, klp_fassung, doppeljahrgang, kurs, thema_key)
);
alter table public.klp_themenplan enable row level security;
create policy klp_themenplan_lesen on public.klp_themenplan for select to authenticated
  using (public.get_my_role() = any (array['admin', 'coach']));
revoke all on public.klp_themenplan from public, anon, authenticated;
grant select on public.klp_themenplan to authenticated;

-- 2 · skill_schulform -----------------------------------------------------------
create table public.skill_schulform (
  skill_key  text not null references public.skills (skill_key) on delete cascade,
  schulform  text not null check (schulform = any (array['Gymnasium', 'Realschule', 'Gesamtschule', 'Sekundarschule'])),
  kurs       text not null check (kurs = any (array['E', 'G', 'alle'])),
  klp_fassung text not null check (klp_fassung = any (array['2004', '2022', 'g9', 'alle'])),
  zulaessig  boolean not null,
  fundstelle text not null,
  primary key (skill_key, schulform, kurs, klp_fassung)
);
alter table public.skill_schulform enable row level security;
create policy skill_schulform_lesen on public.skill_schulform for select to authenticated
  using (public.get_my_role() = any (array['admin', 'coach']));
revoke all on public.skill_schulform from public, anon, authenticated;
grant select on public.skill_schulform to authenticated;

-- Zulässig, solange keine Sperre greift: Kurs 'alle' oder der Kurs selbst (null = E), Fassung 'alle' oder die Fassung.
create function public.skill_zulaessig(p_skill_key text, p_schulform text, p_kurs text default null,
                                       p_klp_fassung text default null)
  returns boolean
  language sql stable security invoker
  set search_path to 'public', 'pg_temp'
  as $$
  -- Invoker: Wer skill_schulform nicht lesen darf (Kinder), sieht keine Sperre und erfährt nichts.
  -- Definer-Funktionen (LSA) lesen als Eigentümer.
  select not exists (
    select 1 from public.skill_schulform s
     where s.skill_key = p_skill_key and s.schulform = p_schulform and not s.zulaessig
       and s.kurs = any (array['alle', coalesce(p_kurs, 'E')])
       and s.klp_fassung = any (array['alle', p_klp_fassung]))
$$;
revoke all on function public.skill_zulaessig(text, text, text, text) from public, anon;
grant execute on function public.skill_zulaessig(text, text, text, text) to authenticated;

-- 3 · Fassung des Kernlehrplans ------------------------------------------------
-- Klasse k im Schuljahr mit Beginn y war im Schuljahr y − (k − 5) in Klasse 5. Ab 2022/23 gilt der KLP 2022
-- („beginnend mit Klasse 5 aufsteigend“), davor 2004. Gymnasien: g9. Ohne Schulform: null.
create function public.klp_fassung(p_schuljahr text, p_klasse integer, p_schulform text)
  returns text
  language sql immutable
  set search_path to 'public', 'pg_temp'
  as $$
  select case when p_schulform is null or p_schuljahr is null or p_klasse is null then null
              when p_schulform = 'Gymnasium' then 'g9'
              when left(p_schuljahr, 4)::int - (p_klasse - 5) >= 2022 then '2022'
              else '2004' end
$$;
revoke all on function public.klp_fassung(text, integer, text) from public, anon;
grant execute on function public.klp_fassung(text, integer, text) to authenticated;

-- 4 · Daten (generiert) ---------------------------------------------------------
insert into public.klp_themenplan (fach, schulform, klp_fassung, doppeljahrgang, kurs, position, thema_key, nur_teil, fundstelle)
values
  ('mathematik', 'Gesamtschule', '2004', '7/8', 'E', 1, 'daten_streumasse', null, 'klp_gs_mathematik.pdf S. 26 (PDF-S. 26): „nutzen Median, Spannweite und Quartile … als Boxplots (kursiv-fett)“'),
  ('mathematik', 'Gesamtschule', '2004', '7/8', 'alle', 2, 'rationale_zahlen', null, 'klp_gs_mathematik.pdf S. 24 (PDF-S. 24): „ordnen und vergleichen rationale Zahlen“'),
  ('mathematik', 'Gesamtschule', '2004', '7/8', 'alle', 3, 'zuordnungen', 'G: lineare Zuordnungen kursiv-fett (nur E)', 'klp_gs_mathematik.pdf S. 25 (PDF-S. 25): „wenden die Eigenschaften von proportionalen, antiproportionalen … Zuordnungen sowie einfache Dreisatzverfahren … an“'),
  ('mathematik', 'Gesamtschule', '2004', '7/8', 'alle', 4, 'zinsrechnung', null, 'klp_gs_mathematik.pdf S. 25 (PDF-S. 25): „berechnen Prozentwert, Prozentsatz und Grundwert in Realsituationen (auch Zinsrechnung)“'),
  ('mathematik', 'Gesamtschule', '2004', '7/8', 'alle', 5, 'terme_gleichungen', null, 'klp_gs_mathematik.pdf S. 24 (PDF-S. 24): „lösen lineare Gleichungen sowohl durch Probieren als auch algebraisch“'),
  ('mathematik', 'Gesamtschule', '2004', '7/8', 'alle', 6, 'winkel_dreiecke', 'G: nur Dreieckskonstruktion; Winkelsätze/Kongruenz kursiv-fett (nur E)', 'klp_gs_mathematik.pdf S. 25 (PDF-S. 25): „zeichnen Dreiecke aus gegebenen Winkel- und Seitenmaßen“'),
  ('mathematik', 'Gesamtschule', '2004', '7/8', 'alle', 7, 'zufallsexperimente', 'G: nur einstufig; zweistufig/Pfadregeln Ende 10 kursiv-fett (nur E)', 'klp_gs_mathematik.pdf S. 26 (PDF-S. 26): „bestimmen Wahrscheinlichkeiten bei einstufigen Zufallsexperimenten mit Hilfe der Laplace-Regel“'),
  ('mathematik', 'Gesamtschule', '2004', '7/8', 'E', 8, 'lineare_funktionen', null, 'klp_gs_mathematik.pdf S. 25 (PDF-S. 25): „interpretieren Grafen von Zuordnungen und Terme linearer funktionaler Zusammenhänge (ab „und Terme“ kursiv-fett)“'),
  ('mathematik', 'Gesamtschule', '2004', '7/8', 'alle', 9, 'terme_binomische_formeln', 'G-Kurs: kein Produkt von Summen; binomische Formeln nur E (kursiv-fett)', 'klp_gs_mathematik.pdf S. 24 (PDF-S. 24): „multiplizieren sie aus (G-Kurs: kein Produkt von Summen) … binomische Formeln als Rechenstrategie“'),
  ('mathematik', 'Gesamtschule', '2004', '7/8', 'alle', 10, 'flaechen_vielecke', null, 'klp_gs_mathematik.pdf S. 25 (PDF-S. 25): „bestimmen Umfang und Flächeninhalt von Dreiecken, Parallelogrammen und daraus zusammengesetzten Figuren“'),
  ('mathematik', 'Gesamtschule', '2004', '7/8', 'alle', 11, 'prismen_zylinder', null, 'klp_gs_mathematik.pdf S. 25 (PDF-S. 25): „bestimmen Oberflächen und Volumina von einfachen Prismen“'),
  ('mathematik', 'Gesamtschule', '2004', '9/10', 'G', 1, 'lineare_funktionen', 'G-Kurs erst Ende 10 (Ende 8 kursiv-fett, nur E)', 'klp_gs_mathematik.pdf S. 30 (PDF-S. 30): „stellen Funktionen (lineare, quadratische (G-Kurs; nur f(x)=ax2) … dar“'),
  ('mathematik', 'Gesamtschule', '2004', '9/10', 'E', 2, 'lineare_gleichungen_lgs', null, 'klp_gs_mathematik.pdf S. 29 (PDF-S. 29): „lösen lineare Gleichungssysteme mit zwei Variablen … (kursiv-fett)“'),
  ('mathematik', 'Gesamtschule', '2004', '9/10', 'E', 3, 'thales_konstruktionen', null, 'klp_gs_mathematik.pdf S. 30 (PDF-S. 30): „begründen Eigenschaften von Figuren mit Hilfe des Satzes des Thales (kursiv-fett)“'),
  ('mathematik', 'Gesamtschule', '2004', '9/10', 'alle', 4, 'reelle_zahlen', 'G: nur Radizieren/Quadratwurzeln; rational/irrational, Intervallschachtelung kursiv-fett (nur E)', 'klp_gs_mathematik.pdf S. 29 (PDF-S. 29): „wenden das Radizieren als Umkehren des Potenzierens an“'),
  ('mathematik', 'Gesamtschule', '2004', '9/10', 'alle', 5, 'quadratische_funktionen', 'G-Kurs; nur f(x)=ax2', 'klp_gs_mathematik.pdf S. 30 (PDF-S. 30): „stellen Funktionen (lineare, quadratische (G-Kurs; nur f(x)=ax2) …) … dar“'),
  ('mathematik', 'Gesamtschule', '2004', '9/10', 'alle', 6, 'kreis', null, 'klp_gs_mathematik.pdf S. 30 (PDF-S. 30): „schätzen und bestimmen Umfänge und Flächeninhalte von Kreisen“'),
  ('mathematik', 'Gesamtschule', '2004', '9/10', 'alle', 7, 'pythagoras', null, 'klp_gs_mathematik.pdf S. 30 (PDF-S. 30): „berechnen geometrische Größen und verwenden dazu den Satz des Pythagoras“'),
  ('mathematik', 'Gesamtschule', '2004', '9/10', 'alle', 8, 'potenzen', null, 'klp_gs_mathematik.pdf S. 29 (PDF-S. 29): „lesen und schreiben Zahlen in Zehnerpotenz-Schreibweise … Potenzschreibweise mit ganzzahligen Exponenten“'),
  ('mathematik', 'Gesamtschule', '2004', '9/10', 'alle', 9, 'statistik_beurteilen', null, 'klp_gs_mathematik.pdf S. 31 (PDF-S. 31): „analysieren grafische statistische Darstellungen kritisch und erkennen Manipulationen“'),
  ('mathematik', 'Gesamtschule', '2004', '9/10', 'alle', 10, 'quadratische_gleichungen', 'G-Kurs: rein-quadratisch', 'klp_gs_mathematik.pdf S. 29 (PDF-S. 29): „lösen einfache quadratische Gleichungen (G-Kurs: rein-quadratisch)“'),
  ('mathematik', 'Gesamtschule', '2004', '9/10', 'alle', 11, 'koerper_pyramide_kegel_kugel', null, 'klp_gs_mathematik.pdf S. 30 (PDF-S. 30): „Oberflächen und Volumina von Zylindern, Pyramiden, Kegeln und Kugeln“'),
  ('mathematik', 'Gesamtschule', '2004', '9/10', 'alle', 12, 'aehnlichkeit', 'G: nur maßstabsgetreues Vergrößern/Verkleinern; Ähnlichkeitsbeziehungen kursiv-fett (nur E)', 'klp_gs_mathematik.pdf S. 30 (PDF-S. 30): „vergrößern und verkleinern einfache Figuren maßstabsgetreu“'),
  ('mathematik', 'Gesamtschule', '2004', '9/10', 'alle', 13, 'exponentialfunktionen', 'G-Kurs; Eigenschaften exponentiellen Wachstums', 'klp_gs_mathematik.pdf S. 30 (PDF-S. 30): „exponentielle Funktionen (G-Kurs; Eigenschaften exponentiellen Wachstums) zur Lösung … an“'),
  ('mathematik', 'Gesamtschule', '2004', '9/10', 'E', 14, 'trigonometrie', null, 'klp_gs_mathematik.pdf S. 30 (PDF-S. 30): „die Definitionen von Sinus, Kosinus und Tangens (kursiv-fett)“'),
  ('mathematik', 'Gesamtschule', '2004', '9/10', 'E', 15, 'sinusfunktion', null, 'klp_gs_mathematik.pdf S. 30 (PDF-S. 30): „stellen Funktionen (… exponentielle, Sinusfunktion) … dar (kursiv-fett)“'),
  ('mathematik', 'Gesamtschule', '2022', '7/8', 'E', 1, 'daten_streumasse', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 36 (PDF-S. 35): „statistische Daten und Kenngrößen: Quartile und Boxplots [fett]“'),
  ('mathematik', 'Gesamtschule', '2022', '7/8', 'alle', 2, 'rationale_zahlen', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 33 (PDF-S. 32): „(2) stellen rationale Zahlen auf der Zahlengeraden dar und ordnen sie der Größe nach“'),
  ('mathematik', 'Gesamtschule', '2022', '7/8', 'alle', 3, 'zuordnungen', 'G: ohne Quotienten-/Produktgleichheit und Proportionalitätsfaktor (fett, nur E)', 'klp_gesk_m_klp_2022_06_17.pdf S. 34 (PDF-S. 33): „(1) charakterisieren Zuordnungen und grenzen diese anhand ihrer Eigenschaften voneinander ab“'),
  ('mathematik', 'Gesamtschule', '2022', '7/8', 'alle', 4, 'zinsrechnung', 'G: ohne Wachstumsfaktor, Kombination prozentualer Veränderungen, Exponenten im Zins (fett, nur E)', 'klp_gesk_m_klp_2022_06_17.pdf S. 34 (PDF-S. 33): „(8) unterscheiden … Grundwert, Prozentsatz und -wert und berechnen fehlende Größen“'),
  ('mathematik', 'Gesamtschule', '2022', '7/8', 'alle', 5, 'terme_gleichungen', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 33 (PDF-S. 32): „(10) ermitteln Lösungsmengen linearer Gleichungen sowohl durch systematisches Probieren als auch algebraisch“'),
  ('mathematik', 'Gesamtschule', '2022', '7/8', 'alle', 6, 'winkel_dreiecke', 'G: ohne Kongruenzsätze und Beweis der Innenwinkelsumme (fett, nur E)', 'klp_gesk_m_klp_2022_06_17.pdf S. 35 (PDF-S. 34): „(1) nutzen geometrische Sätze zur Winkelbestimmung in ebenen Figuren“'),
  ('mathematik', 'Gesamtschule', '2022', '7/8', 'alle', 7, 'zufallsexperimente', 'G: nur einstufig; zweistufig/Pfadregeln 9/10 fett (nur E)', 'klp_gesk_m_klp_2022_06_17.pdf S. 36 (PDF-S. 35): „(2) bestimmen Wahrscheinlichkeiten bei einstufigen Zufallsexperimenten mithilfe der Laplace-Regel“'),
  ('mathematik', 'Gesamtschule', '2022', '7/8', 'alle', 8, 'lineare_funktionen', 'nur lineare Zuordnungen; Steigung, Achsenabschnitt erst 9/10 (PDF-S. 38). G: lineare Zuordnungen ohne Terme/Eigenschaften in KE (5),(6) (fett, nur E)', 'klp_gesk_m_klp_2022_06_17.pdf S. 33 (PDF-S. 32): „lineare Zuordnungen: Zuordnungsterm, Graph, Tabelle, Wortform“'),
  ('mathematik', 'Gesamtschule', '2022', '7/8', 'E', 9, 'terme_binomische_formeln', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 33 (PDF-S. 32): „(8) formen Terme (auch mithilfe der binomischen Formeln) zielgerichtet um [Klammer fett]“'),
  ('mathematik', 'Gesamtschule', '2022', '7/8', 'alle', 10, 'flaechen_vielecke', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 35 (PDF-S. 34): „Umfang und Flächeninhalt: Dreieck, Viereck, zusammengesetzte Figuren“'),
  ('mathematik', 'Gesamtschule', '2022', '7/8', 'alle', 11, 'thales_konstruktionen', 'G: nur Konstruktion Dreieck/Mittelsenkrechte; Satz des Thales fett (nur E)', 'klp_gesk_m_klp_2022_06_17.pdf S. 35 (PDF-S. 34): „Konstruktion: Dreieck, Mittelsenkrechte“'),
  ('mathematik', 'Gesamtschule', '2022', '7/8', 'alle', 12, 'prismen_zylinder', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 35 (PDF-S. 34): „(3) benennen und charakterisieren einfache Prismen und bestimmen Oberflächeninhalt und Volumen“'),
  ('mathematik', 'Gesamtschule', '2022', '9/10', 'E', 1, 'lineare_gleichungen_lgs', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 38 (PDF-S. 37): „(7) ermitteln algebraisch und graphisch Lösungsmengen linearer Gleichungssysteme mit zwei Variablen [fett]“'),
  ('mathematik', 'Gesamtschule', '2022', '9/10', 'alle', 2, 'reelle_zahlen', 'G: nur Radizieren/Quadratwurzeln; rational/irrational, Näherungsverfahren fett (nur E)', 'klp_gesk_m_klp_2022_06_17.pdf S. 38 (PDF-S. 37): „(6) berechnen und überschlagen Quadratwurzeln einfacher Zahlen im Kopf“'),
  ('mathematik', 'Gesamtschule', '2022', '9/10', 'alle', 3, 'quadratische_funktionen', 'G-Kurs: keine Verschiebung entlang der x-Achse', 'klp_gesk_m_klp_2022_06_17.pdf S. 39 (PDF-S. 38): „Transformation der Normalparabel (G-Kurs: keine Verschiebung entlang der x-Achse)“'),
  ('mathematik', 'Gesamtschule', '2022', '9/10', 'alle', 4, 'kreis', 'G: ohne Kreisbogen/Kreissektor (fett, nur E)', 'klp_gesk_m_klp_2022_06_17.pdf S. 40 (PDF-S. 39): „Kreis: Umfang und Flächeninhalt (Kreis, Kreisbogen, Kreissektor)“'),
  ('mathematik', 'Gesamtschule', '2022', '9/10', 'alle', 5, 'pythagoras', 'G: ohne Beweis, KE (4) fett (nur E)', 'klp_gesk_m_klp_2022_06_17.pdf S. 40 (PDF-S. 39): „geometrische Sätze: Satz des Pythagoras“'),
  ('mathematik', 'Gesamtschule', '2022', '9/10', 'alle', 6, 'potenzen', 'G: nur Zehnerpotenzschreibweise; Potenzgesetze, Bruch-/Potenzschreibweise fett (nur E)', 'klp_gesk_m_klp_2022_06_17.pdf S. 38 (PDF-S. 37): „(1) stellen Zahlen in Zehnerpotenzschreibweise dar“'),
  ('mathematik', 'Gesamtschule', '2022', '9/10', 'E', 7, 'bedingte_wahrscheinlichkeit', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 41 (PDF-S. 40): „Pfadregeln, bedingte Wahrscheinlichkeit, Vierfeldertafel [fett]“'),
  ('mathematik', 'Gesamtschule', '2022', '9/10', 'alle', 8, 'statistik_beurteilen', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 41 (PDF-S. 40): „(2) analysieren … graphische Darstellungen statistischer Erhebungen kritisch und erkennen Manipulationen“'),
  ('mathematik', 'Gesamtschule', '2022', '9/10', 'alle', 9, 'quadratische_gleichungen', 'für G-Kurs: lösen rein quadratische Gleichungen', 'klp_gesk_m_klp_2022_06_17.pdf S. 38 (PDF-S. 37): „für G-Kurs: lösen rein quadratische Gleichungen“'),
  ('mathematik', 'Gesamtschule', '2022', '9/10', 'alle', 10, 'koerper_pyramide_kegel_kugel', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 40 (PDF-S. 39): „Körper: Kugel, Zylinder, Kegel und Pyramide, Oberflächeninhalt und Volumen“'),
  ('mathematik', 'Gesamtschule', '2022', '9/10', 'alle', 11, 'aehnlichkeit', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 41 (PDF-S. 40): „(6) berechnen Größen mithilfe von Ähnlichkeitsbeziehungen, geometrischen Sätzen“'),
  ('mathematik', 'Gesamtschule', '2022', '9/10', 'alle', 12, 'exponentialfunktionen', 'Für G-Kurs: exponentielle Wachstumsprozesse', 'klp_gesk_m_klp_2022_06_17.pdf S. 39 (PDF-S. 38): „Für G-Kurs: exponentielle Wachstumsprozesse“'),
  ('mathematik', 'Gesamtschule', '2022', '9/10', 'E', 13, 'trigonometrie', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 40 (PDF-S. 39): „Trigonometrie: Sinus, Kosinus, Tangens [fett]“'),
  ('mathematik', 'Gesamtschule', '2022', '9/10', 'E', 14, 'sinusfunktion', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 40 (PDF-S. 39): „(14) … periodische Vorgänge mithilfe von Sinusfunktionen der Form f(x) = a⋅sin(b⋅x) [fett]“'),
  ('mathematik', 'Gymnasium', 'g9', '10', 'alle', 1, 'quadratische_gleichungen', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (19 Schulen; Verteilung 9:4 10:19), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '10', 'alle', 2, 'koerper_pyramide_kegel_kugel', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (8 Schulen; Verteilung 10:8), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '10', 'alle', 3, 'aehnlichkeit', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (17 Schulen; Verteilung 8:4 9:8 10:17), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '10', 'alle', 4, 'exponentialfunktionen', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (25 Schulen; Verteilung 10:25), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '10', 'alle', 5, 'trigonometrie', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (25 Schulen; Verteilung 10:25), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '10', 'alle', 6, 'sinusfunktion', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (25 Schulen; Verteilung 10:25), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '7', 'alle', 1, 'rationale_zahlen', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (29 Schulen; Verteilung 6:3 7:29), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '7', 'alle', 2, 'zuordnungen', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (31 Schulen; Verteilung 7:31), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '7', 'alle', 3, 'zinsrechnung', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (31 Schulen; Verteilung 7:31 8:2), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '7', 'alle', 4, 'terme_gleichungen', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (31 Schulen; Verteilung 7:31 8:3), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '7', 'alle', 5, 'winkel_dreiecke', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (31 Schulen; Verteilung 7:31), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '7', 'alle', 6, 'zufallsexperimente', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (27 Schulen; Verteilung 7:27 8:24), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '8', 'alle', 1, 'lineare_funktionen', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (30 Schulen; Verteilung 8:30), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '8', 'alle', 2, 'terme_binomische_formeln', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (27 Schulen; Verteilung 7:1 8:27), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '8', 'alle', 3, 'flaechen_vielecke', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (26 Schulen; Verteilung 7:3 8:26), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '8', 'alle', 4, 'lineare_gleichungen_lgs', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (30 Schulen; Verteilung 8:30), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '8', 'alle', 5, 'thales_konstruktionen', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (25 Schulen; Verteilung 7:3 8:25), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '9', 'alle', 1, 'reelle_zahlen', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (26 Schulen; Verteilung 8:1 9:26), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '9', 'alle', 2, 'quadratische_funktionen', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (27 Schulen; Verteilung 9:27), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '9', 'alle', 3, 'kreis', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (26 Schulen; Verteilung 8:1 9:26), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '9', 'alle', 4, 'pythagoras', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (26 Schulen; Verteilung 9:26), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '9', 'alle', 5, 'potenzen', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (27 Schulen; Verteilung 9:27 10:3), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '9', 'alle', 6, 'prismen_zylinder', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (7 Schulen; Verteilung 9:7), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '9', 'alle', 7, 'bedingte_wahrscheinlichkeit', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (20 Schulen; Verteilung 9:20 10:19), dbread 13.11.2026'),
  ('mathematik', 'Gymnasium', 'g9', '9', 'alle', 8, 'statistik_beurteilen', null, 'schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan (5 Schulen; Verteilung 9:5), dbread 13.11.2026'),
  ('mathematik', 'Realschule', '2004', '7/8', 'alle', 1, 'koerper_quader', null, 'klp_rs_mathematik_0.pdf S. 25 (PDF-S. 25): „entwerfen Netze von Würfeln und Quadern … Oberflächen und Volumina von Würfeln, Quadern“'),
  ('mathematik', 'Realschule', '2004', '7/8', 'alle', 2, 'daten_streumasse', null, 'klp_rs_mathematik_0.pdf S. 26 (PDF-S. 26): „nutzen Median, Spannweite und Quartile zur Darstellung von Häufigkeitsverteilungen als Boxplots“'),
  ('mathematik', 'Realschule', '2004', '7/8', 'alle', 3, 'rationale_zahlen', null, 'klp_rs_mathematik_0.pdf S. 24 (PDF-S. 24): „ordnen und vergleichen rationale Zahlen“'),
  ('mathematik', 'Realschule', '2004', '7/8', 'alle', 4, 'zuordnungen', null, 'klp_rs_mathematik_0.pdf S. 25 (PDF-S. 25): „identifizieren proportionale, antiproportionale und lineare Zuordnungen in Tabellen, Termen und Realsituationen“'),
  ('mathematik', 'Realschule', '2004', '7/8', 'alle', 5, 'zinsrechnung', null, 'klp_rs_mathematik_0.pdf S. 25 (PDF-S. 25): „berechnen Prozentwert, Prozentsatz und Grundwert in Realsituationen (auch Zinsrechnung)“'),
  ('mathematik', 'Realschule', '2004', '7/8', 'alle', 6, 'terme_gleichungen', null, 'klp_rs_mathematik_0.pdf S. 24 (PDF-S. 24): „lösen lineare Gleichungen sowohl durch Probieren als auch algebraisch“'),
  ('mathematik', 'Realschule', '2004', '7/8', 'alle', 7, 'winkel_dreiecke', null, 'klp_rs_mathematik_0.pdf S. 25 (PDF-S. 25): „zeichnen Dreiecke aus gegebenen Winkel- und Seitenmaßen … einfachen Winkelsätzen oder der Kongruenz“'),
  ('mathematik', 'Realschule', '2004', '7/8', 'alle', 8, 'zufallsexperimente', null, 'klp_rs_mathematik_0.pdf S. 26 (PDF-S. 26): „bestimmen Wahrscheinlichkeiten bei einstufigen Zufallsexperimenten mit Hilfe der Laplace-Regel“'),
  ('mathematik', 'Realschule', '2004', '7/8', 'alle', 9, 'lineare_funktionen', null, 'klp_rs_mathematik_0.pdf S. 25 (PDF-S. 25): „interpretieren Grafen von Zuordnungen und Terme linearer funktionaler Zusammenhänge“'),
  ('mathematik', 'Realschule', '2004', '7/8', 'alle', 10, 'terme_binomische_formeln', null, 'klp_rs_mathematik_0.pdf S. 24 (PDF-S. 24): „fassen Terme zusammen, multiplizieren sie aus …; sie nutzen binomische Formeln als Rechenstrategie“'),
  ('mathematik', 'Realschule', '2004', '7/8', 'alle', 11, 'flaechen_vielecke', null, 'klp_rs_mathematik_0.pdf S. 25 (PDF-S. 25): „bestimmen Umfang und Flächeninhalt von Dreiecken, Parallelogrammen und daraus zusammengesetzten Figuren“'),
  ('mathematik', 'Realschule', '2004', '7/8', 'alle', 12, 'prismen_zylinder', null, 'klp_rs_mathematik_0.pdf S. 25 (PDF-S. 25): „bestimmen Oberflächen und Volumina von Würfeln, Quadern und einfachen Prismen“'),
  ('mathematik', 'Realschule', '2004', '9/10', 'alle', 1, 'lineare_gleichungen_lgs', null, 'klp_rs_mathematik_0.pdf S. 29 (PDF-S. 29): „lösen lineare Gleichungssysteme mit zwei Variablen sowohl durch Probieren als auch algebraisch“'),
  ('mathematik', 'Realschule', '2004', '9/10', 'alle', 2, 'thales_konstruktionen', null, 'klp_rs_mathematik_0.pdf S. 30 (PDF-S. 30): „begründen Eigenschaften von Figuren mit Hilfe des Satzes des Thales“'),
  ('mathematik', 'Realschule', '2004', '9/10', 'alle', 3, 'reelle_zahlen', null, 'klp_rs_mathematik_0.pdf S. 29 (PDF-S. 29): „unterscheiden rationale und irrationale Zahlen“'),
  ('mathematik', 'Realschule', '2004', '9/10', 'alle', 4, 'quadratische_funktionen', null, 'klp_rs_mathematik_0.pdf S. 30 (PDF-S. 30): „deuten die Parameter der Termdarstellungen von linearen und quadratischen Funktionen“'),
  ('mathematik', 'Realschule', '2004', '9/10', 'alle', 5, 'kreis', null, 'klp_rs_mathematik_0.pdf S. 30 (PDF-S. 30): „schätzen und bestimmen Umfänge und Flächeninhalte von Kreisen“'),
  ('mathematik', 'Realschule', '2004', '9/10', 'alle', 6, 'pythagoras', null, 'klp_rs_mathematik_0.pdf S. 30 (PDF-S. 30): „berechnen geometrische Größen und verwenden dazu den Satz des Pythagoras“'),
  ('mathematik', 'Realschule', '2004', '9/10', 'alle', 7, 'potenzen', null, 'klp_rs_mathematik_0.pdf S. 29 (PDF-S. 29): „lesen und schreiben Zahlen in Zehnerpotenz-Schreibweise … Potenzschreibweise mit ganzzahligen Exponenten“'),
  ('mathematik', 'Realschule', '2004', '9/10', 'alle', 8, 'statistik_beurteilen', null, 'klp_rs_mathematik_0.pdf S. 31 (PDF-S. 31): „analysieren grafische statistische Darstellungen kritisch und erkennen Manipulationen“'),
  ('mathematik', 'Realschule', '2004', '9/10', 'alle', 9, 'quadratische_gleichungen', null, 'klp_rs_mathematik_0.pdf S. 29 (PDF-S. 29): „lösen einfache quadratische Gleichungen“'),
  ('mathematik', 'Realschule', '2004', '9/10', 'alle', 10, 'koerper_pyramide_kegel_kugel', null, 'klp_rs_mathematik_0.pdf S. 30 (PDF-S. 30): „Oberflächen und Volumina von Zylindern, Pyramiden, Kegeln und Kugeln“'),
  ('mathematik', 'Realschule', '2004', '9/10', 'alle', 11, 'aehnlichkeit', null, 'klp_rs_mathematik_0.pdf S. 30 (PDF-S. 30): „vergrößern und verkleinern einfache Figuren maßstabsgetreu … Ähnlichkeitsbeziehungen“'),
  ('mathematik', 'Realschule', '2004', '9/10', 'alle', 12, 'exponentialfunktionen', null, 'klp_rs_mathematik_0.pdf S. 30 (PDF-S. 30): „wenden lineare, quadratische und exponentielle Funktionen … an (auch Zinseszins)“'),
  ('mathematik', 'Realschule', '2004', '9/10', 'alle', 13, 'trigonometrie', null, 'klp_rs_mathematik_0.pdf S. 30 (PDF-S. 30): „die Definitionen von Sinus, Kosinus und Tangens“'),
  ('mathematik', 'Realschule', '2004', '9/10', 'alle', 14, 'sinusfunktion', null, 'klp_rs_mathematik_0.pdf S. 30 (PDF-S. 30): „stellen Funktionen (lineare, quadratische, exponentielle, Sinusfunktion) mit eigenen Worten … dar“'),
  ('mathematik', 'Realschule', '2022', '7/8', 'alle', 1, 'daten_streumasse', null, 'klp_rs_m_klp_2022_06_17.pdf S. 36 (PDF-S. 35): „(5) interpretieren Spannweite und Quartile … stellen … Häufigkeitsverteilungen als Boxplots dar“'),
  ('mathematik', 'Realschule', '2022', '7/8', 'alle', 2, 'rationale_zahlen', null, 'klp_rs_m_klp_2022_06_17.pdf S. 33 (PDF-S. 32): „(2) stellen rationale Zahlen auf der Zahlengeraden dar und ordnen sie der Größe nach“'),
  ('mathematik', 'Realschule', '2022', '7/8', 'alle', 3, 'zuordnungen', null, 'klp_rs_m_klp_2022_06_17.pdf S. 34 (PDF-S. 33): „(6) wenden die Eigenschaften von proportionalen, antiproportionalen und linearen Zuordnungen sowie Dreisatzverfahren … an“'),
  ('mathematik', 'Realschule', '2022', '7/8', 'alle', 4, 'zinsrechnung', null, 'klp_rs_m_klp_2022_06_17.pdf S. 34 (PDF-S. 33): „(9) wenden Prozent- und Zinsrechnung auf allgemeine Konsumsituationen an“'),
  ('mathematik', 'Realschule', '2022', '7/8', 'alle', 5, 'terme_gleichungen', null, 'klp_rs_m_klp_2022_06_17.pdf S. 33 (PDF-S. 32): „(10) ermitteln Lösungsmengen linearer Gleichungen sowohl durch systematisches Probieren als auch algebraisch“'),
  ('mathematik', 'Realschule', '2022', '7/8', 'alle', 6, 'winkel_dreiecke', null, 'klp_rs_m_klp_2022_06_17.pdf S. 35 (PDF-S. 34): „Neben-, Scheitel-, Stufen- und Wechselwinkelsatz, Innenwinkelsatz (Dreieck, Viereck), Kongruenzsätze“'),
  ('mathematik', 'Realschule', '2022', '7/8', 'alle', 7, 'zufallsexperimente', null, 'klp_rs_m_klp_2022_06_17.pdf S. 36 (PDF-S. 35): „(2) bestimmen Wahrscheinlichkeiten bei einstufigen Zufallsexperimenten mithilfe der Laplace-Regel“'),
  ('mathematik', 'Realschule', '2022', '7/8', 'alle', 8, 'lineare_funktionen', 'nur lineare Zuordnungen; Steigung, Achsenabschnitt erst 9/10 (PDF-S. 38)', 'klp_rs_m_klp_2022_06_17.pdf S. 34 (PDF-S. 33): „(5) interpretieren Graphen von Zuordnungen und Terme linearer Zuordnungen“'),
  ('mathematik', 'Realschule', '2022', '7/8', 'alle', 9, 'terme_binomische_formeln', null, 'klp_rs_m_klp_2022_06_17.pdf S. 33 (PDF-S. 32): „(8) formen Terme auch mithilfe der binomischen Formeln zielgerichtet um“'),
  ('mathematik', 'Realschule', '2022', '7/8', 'alle', 10, 'flaechen_vielecke', null, 'klp_rs_m_klp_2022_06_17.pdf S. 35 (PDF-S. 34): „Umfang und Flächeninhalt: Dreieck, Viereck, zusammengesetzte Figuren“'),
  ('mathematik', 'Realschule', '2022', '7/8', 'alle', 11, 'thales_konstruktionen', null, 'klp_rs_m_klp_2022_06_17.pdf S. 35 (PDF-S. 34): „Kongruenzsätze, Satz des Thales – Konstruktion: Dreieck, Mittelsenkrechte“'),
  ('mathematik', 'Realschule', '2022', '7/8', 'alle', 12, 'prismen_zylinder', null, 'klp_rs_m_klp_2022_06_17.pdf S. 35 (PDF-S. 34): „Körper: Oberflächeninhalt und Volumen einfacher Prismen“'),
  ('mathematik', 'Realschule', '2022', '9/10', 'alle', 1, 'lineare_gleichungen_lgs', null, 'klp_rs_m_klp_2022_06_17.pdf S. 38 (PDF-S. 37): „(7) ermitteln alegbraisch [sic] und graphisch Lösungsmengen linearer Gleichungssysteme mit zwei Variablen“'),
  ('mathematik', 'Realschule', '2022', '9/10', 'alle', 2, 'reelle_zahlen', null, 'klp_rs_m_klp_2022_06_17.pdf S. 38 (PDF-S. 37): „(2) unterscheiden rationale und irrationale Zahlen und geben Beispiele für irrationale Zahlen an“'),
  ('mathematik', 'Realschule', '2022', '9/10', 'alle', 3, 'quadratische_funktionen', null, 'klp_rs_m_klp_2022_06_17.pdf S. 39 (PDF-S. 38): „quadratische Funktionen: Term (Normalform, Scheitelpunktform) … Transformation der Normalparabel“'),
  ('mathematik', 'Realschule', '2022', '9/10', 'alle', 4, 'kreis', null, 'klp_rs_m_klp_2022_06_17.pdf S. 40 (PDF-S. 39): „Kreis: Umfang und Flächeninhalt (Kreis, Kreisbogen, Kreissektor)“'),
  ('mathematik', 'Realschule', '2022', '9/10', 'alle', 5, 'pythagoras', null, 'klp_rs_m_klp_2022_06_17.pdf S. 40 (PDF-S. 39): „geometrische Sätze: Satz des Pythagoras“'),
  ('mathematik', 'Realschule', '2022', '9/10', 'alle', 6, 'potenzen', null, 'klp_rs_m_klp_2022_06_17.pdf S. 38 (PDF-S. 37): „(3) vereinfachen Terme, bei denen die Potenzgesetze unmittelbar anzuwenden sind“'),
  ('mathematik', 'Realschule', '2022', '9/10', 'alle', 7, 'bedingte_wahrscheinlichkeit', null, 'klp_rs_m_klp_2022_06_17.pdf S. 41 (PDF-S. 40): „zweistufige Zufallsversuche, Baumdiagramme, Pfadregeln, bedingte Wahrscheinlichkeit, Vierfeldertafel“'),
  ('mathematik', 'Realschule', '2022', '9/10', 'alle', 8, 'statistik_beurteilen', null, 'klp_rs_m_klp_2022_06_17.pdf S. 41 (PDF-S. 40): „(2) analysieren … graphische Darstellungen statistischer Erhebungen kritisch und erkennen Manipulationen“'),
  ('mathematik', 'Realschule', '2022', '9/10', 'alle', 9, 'quadratische_gleichungen', null, 'klp_rs_m_klp_2022_06_17.pdf S. 37 (PDF-S. 36): „Lösungsverfahren für quadratische Gleichungen (quadratische Ergänzung, p-q-Formel)“'),
  ('mathematik', 'Realschule', '2022', '9/10', 'alle', 10, 'koerper_pyramide_kegel_kugel', null, 'klp_rs_m_klp_2022_06_17.pdf S. 40 (PDF-S. 39): „Körper: Kugel, Zylinder, Kegel und Pyramide, Oberflächeninhalt und Volumen“'),
  ('mathematik', 'Realschule', '2022', '9/10', 'alle', 11, 'aehnlichkeit', null, 'klp_rs_m_klp_2022_06_17.pdf S. 40 (PDF-S. 39): „maßstäbliches Vergößern [sic] und Verkleinern – Ähnlichkeit“'),
  ('mathematik', 'Realschule', '2022', '9/10', 'alle', 12, 'exponentialfunktionen', null, 'klp_rs_m_klp_2022_06_17.pdf S. 39 (PDF-S. 38): „exponentielle Funktionen: f(x) = a ⋅ q^x, a > 0, q > 0“'),
  ('mathematik', 'Realschule', '2022', '9/10', 'alle', 13, 'trigonometrie', null, 'klp_rs_m_klp_2022_06_17.pdf S. 40 (PDF-S. 39): „Trigonometrie: Sinus, Kosinus, Tangens“'),
  ('mathematik', 'Realschule', '2022', '9/10', 'alle', 14, 'sinusfunktion', null, 'klp_rs_m_klp_2022_06_17.pdf S. 40 (PDF-S. 39): „(14) … periodische Vorgänge mithilfe von Sinusfunktionen der Form f(x) = a⋅sin(b⋅x)“'),
  ('mathematik', 'Sekundarschule', '2004', '7/8', 'E', 1, 'daten_streumasse', null, 'klp_gs_mathematik.pdf S. 26 (PDF-S. 26): „nutzen Median, Spannweite und Quartile … als Boxplots (kursiv-fett)“'),
  ('mathematik', 'Sekundarschule', '2004', '7/8', 'alle', 2, 'rationale_zahlen', null, 'klp_gs_mathematik.pdf S. 24 (PDF-S. 24): „ordnen und vergleichen rationale Zahlen“'),
  ('mathematik', 'Sekundarschule', '2004', '7/8', 'alle', 3, 'zuordnungen', 'G: lineare Zuordnungen kursiv-fett (nur E)', 'klp_gs_mathematik.pdf S. 25 (PDF-S. 25): „wenden die Eigenschaften von proportionalen, antiproportionalen … Zuordnungen sowie einfache Dreisatzverfahren … an“'),
  ('mathematik', 'Sekundarschule', '2004', '7/8', 'alle', 4, 'zinsrechnung', null, 'klp_gs_mathematik.pdf S. 25 (PDF-S. 25): „berechnen Prozentwert, Prozentsatz und Grundwert in Realsituationen (auch Zinsrechnung)“'),
  ('mathematik', 'Sekundarschule', '2004', '7/8', 'alle', 5, 'terme_gleichungen', null, 'klp_gs_mathematik.pdf S. 24 (PDF-S. 24): „lösen lineare Gleichungen sowohl durch Probieren als auch algebraisch“'),
  ('mathematik', 'Sekundarschule', '2004', '7/8', 'alle', 6, 'winkel_dreiecke', 'G: nur Dreieckskonstruktion; Winkelsätze/Kongruenz kursiv-fett (nur E)', 'klp_gs_mathematik.pdf S. 25 (PDF-S. 25): „zeichnen Dreiecke aus gegebenen Winkel- und Seitenmaßen“'),
  ('mathematik', 'Sekundarschule', '2004', '7/8', 'alle', 7, 'zufallsexperimente', 'G: nur einstufig; zweistufig/Pfadregeln Ende 10 kursiv-fett (nur E)', 'klp_gs_mathematik.pdf S. 26 (PDF-S. 26): „bestimmen Wahrscheinlichkeiten bei einstufigen Zufallsexperimenten mit Hilfe der Laplace-Regel“'),
  ('mathematik', 'Sekundarschule', '2004', '7/8', 'E', 8, 'lineare_funktionen', null, 'klp_gs_mathematik.pdf S. 25 (PDF-S. 25): „interpretieren Grafen von Zuordnungen und Terme linearer funktionaler Zusammenhänge (ab „und Terme“ kursiv-fett)“'),
  ('mathematik', 'Sekundarschule', '2004', '7/8', 'alle', 9, 'terme_binomische_formeln', 'G-Kurs: kein Produkt von Summen; binomische Formeln nur E (kursiv-fett)', 'klp_gs_mathematik.pdf S. 24 (PDF-S. 24): „multiplizieren sie aus (G-Kurs: kein Produkt von Summen) … binomische Formeln als Rechenstrategie“'),
  ('mathematik', 'Sekundarschule', '2004', '7/8', 'alle', 10, 'flaechen_vielecke', null, 'klp_gs_mathematik.pdf S. 25 (PDF-S. 25): „bestimmen Umfang und Flächeninhalt von Dreiecken, Parallelogrammen und daraus zusammengesetzten Figuren“'),
  ('mathematik', 'Sekundarschule', '2004', '7/8', 'alle', 11, 'prismen_zylinder', null, 'klp_gs_mathematik.pdf S. 25 (PDF-S. 25): „bestimmen Oberflächen und Volumina von einfachen Prismen“'),
  ('mathematik', 'Sekundarschule', '2004', '9/10', 'G', 1, 'lineare_funktionen', 'G-Kurs erst Ende 10 (Ende 8 kursiv-fett, nur E)', 'klp_gs_mathematik.pdf S. 30 (PDF-S. 30): „stellen Funktionen (lineare, quadratische (G-Kurs; nur f(x)=ax2) … dar“'),
  ('mathematik', 'Sekundarschule', '2004', '9/10', 'E', 2, 'lineare_gleichungen_lgs', null, 'klp_gs_mathematik.pdf S. 29 (PDF-S. 29): „lösen lineare Gleichungssysteme mit zwei Variablen … (kursiv-fett)“'),
  ('mathematik', 'Sekundarschule', '2004', '9/10', 'E', 3, 'thales_konstruktionen', null, 'klp_gs_mathematik.pdf S. 30 (PDF-S. 30): „begründen Eigenschaften von Figuren mit Hilfe des Satzes des Thales (kursiv-fett)“'),
  ('mathematik', 'Sekundarschule', '2004', '9/10', 'alle', 4, 'reelle_zahlen', 'G: nur Radizieren/Quadratwurzeln; rational/irrational, Intervallschachtelung kursiv-fett (nur E)', 'klp_gs_mathematik.pdf S. 29 (PDF-S. 29): „wenden das Radizieren als Umkehren des Potenzierens an“'),
  ('mathematik', 'Sekundarschule', '2004', '9/10', 'alle', 5, 'quadratische_funktionen', 'G-Kurs; nur f(x)=ax2', 'klp_gs_mathematik.pdf S. 30 (PDF-S. 30): „stellen Funktionen (lineare, quadratische (G-Kurs; nur f(x)=ax2) …) … dar“'),
  ('mathematik', 'Sekundarschule', '2004', '9/10', 'alle', 6, 'kreis', null, 'klp_gs_mathematik.pdf S. 30 (PDF-S. 30): „schätzen und bestimmen Umfänge und Flächeninhalte von Kreisen“'),
  ('mathematik', 'Sekundarschule', '2004', '9/10', 'alle', 7, 'pythagoras', null, 'klp_gs_mathematik.pdf S. 30 (PDF-S. 30): „berechnen geometrische Größen und verwenden dazu den Satz des Pythagoras“'),
  ('mathematik', 'Sekundarschule', '2004', '9/10', 'alle', 8, 'potenzen', null, 'klp_gs_mathematik.pdf S. 29 (PDF-S. 29): „lesen und schreiben Zahlen in Zehnerpotenz-Schreibweise … Potenzschreibweise mit ganzzahligen Exponenten“'),
  ('mathematik', 'Sekundarschule', '2004', '9/10', 'alle', 9, 'statistik_beurteilen', null, 'klp_gs_mathematik.pdf S. 31 (PDF-S. 31): „analysieren grafische statistische Darstellungen kritisch und erkennen Manipulationen“'),
  ('mathematik', 'Sekundarschule', '2004', '9/10', 'alle', 10, 'quadratische_gleichungen', 'G-Kurs: rein-quadratisch', 'klp_gs_mathematik.pdf S. 29 (PDF-S. 29): „lösen einfache quadratische Gleichungen (G-Kurs: rein-quadratisch)“'),
  ('mathematik', 'Sekundarschule', '2004', '9/10', 'alle', 11, 'koerper_pyramide_kegel_kugel', null, 'klp_gs_mathematik.pdf S. 30 (PDF-S. 30): „Oberflächen und Volumina von Zylindern, Pyramiden, Kegeln und Kugeln“'),
  ('mathematik', 'Sekundarschule', '2004', '9/10', 'alle', 12, 'aehnlichkeit', 'G: nur maßstabsgetreues Vergrößern/Verkleinern; Ähnlichkeitsbeziehungen kursiv-fett (nur E)', 'klp_gs_mathematik.pdf S. 30 (PDF-S. 30): „vergrößern und verkleinern einfache Figuren maßstabsgetreu“'),
  ('mathematik', 'Sekundarschule', '2004', '9/10', 'alle', 13, 'exponentialfunktionen', 'G-Kurs; Eigenschaften exponentiellen Wachstums', 'klp_gs_mathematik.pdf S. 30 (PDF-S. 30): „exponentielle Funktionen (G-Kurs; Eigenschaften exponentiellen Wachstums) zur Lösung … an“'),
  ('mathematik', 'Sekundarschule', '2004', '9/10', 'E', 14, 'trigonometrie', null, 'klp_gs_mathematik.pdf S. 30 (PDF-S. 30): „die Definitionen von Sinus, Kosinus und Tangens (kursiv-fett)“'),
  ('mathematik', 'Sekundarschule', '2004', '9/10', 'E', 15, 'sinusfunktion', null, 'klp_gs_mathematik.pdf S. 30 (PDF-S. 30): „stellen Funktionen (… exponentielle, Sinusfunktion) … dar (kursiv-fett)“'),
  ('mathematik', 'Sekundarschule', '2022', '7/8', 'E', 1, 'daten_streumasse', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 36 (PDF-S. 35): „statistische Daten und Kenngrößen: Quartile und Boxplots [fett]“'),
  ('mathematik', 'Sekundarschule', '2022', '7/8', 'alle', 2, 'rationale_zahlen', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 33 (PDF-S. 32): „(2) stellen rationale Zahlen auf der Zahlengeraden dar und ordnen sie der Größe nach“'),
  ('mathematik', 'Sekundarschule', '2022', '7/8', 'alle', 3, 'zuordnungen', 'G: ohne Quotienten-/Produktgleichheit und Proportionalitätsfaktor (fett, nur E)', 'klp_gesk_m_klp_2022_06_17.pdf S. 34 (PDF-S. 33): „(1) charakterisieren Zuordnungen und grenzen diese anhand ihrer Eigenschaften voneinander ab“'),
  ('mathematik', 'Sekundarschule', '2022', '7/8', 'alle', 4, 'zinsrechnung', 'G: ohne Wachstumsfaktor, Kombination prozentualer Veränderungen, Exponenten im Zins (fett, nur E)', 'klp_gesk_m_klp_2022_06_17.pdf S. 34 (PDF-S. 33): „(8) unterscheiden … Grundwert, Prozentsatz und -wert und berechnen fehlende Größen“'),
  ('mathematik', 'Sekundarschule', '2022', '7/8', 'alle', 5, 'terme_gleichungen', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 33 (PDF-S. 32): „(10) ermitteln Lösungsmengen linearer Gleichungen sowohl durch systematisches Probieren als auch algebraisch“'),
  ('mathematik', 'Sekundarschule', '2022', '7/8', 'alle', 6, 'winkel_dreiecke', 'G: ohne Kongruenzsätze und Beweis der Innenwinkelsumme (fett, nur E)', 'klp_gesk_m_klp_2022_06_17.pdf S. 35 (PDF-S. 34): „(1) nutzen geometrische Sätze zur Winkelbestimmung in ebenen Figuren“'),
  ('mathematik', 'Sekundarschule', '2022', '7/8', 'alle', 7, 'zufallsexperimente', 'G: nur einstufig; zweistufig/Pfadregeln 9/10 fett (nur E)', 'klp_gesk_m_klp_2022_06_17.pdf S. 36 (PDF-S. 35): „(2) bestimmen Wahrscheinlichkeiten bei einstufigen Zufallsexperimenten mithilfe der Laplace-Regel“'),
  ('mathematik', 'Sekundarschule', '2022', '7/8', 'alle', 8, 'lineare_funktionen', 'nur lineare Zuordnungen; Steigung, Achsenabschnitt erst 9/10 (PDF-S. 38). G: lineare Zuordnungen ohne Terme/Eigenschaften in KE (5),(6) (fett, nur E)', 'klp_gesk_m_klp_2022_06_17.pdf S. 33 (PDF-S. 32): „lineare Zuordnungen: Zuordnungsterm, Graph, Tabelle, Wortform“'),
  ('mathematik', 'Sekundarschule', '2022', '7/8', 'E', 9, 'terme_binomische_formeln', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 33 (PDF-S. 32): „(8) formen Terme (auch mithilfe der binomischen Formeln) zielgerichtet um [Klammer fett]“'),
  ('mathematik', 'Sekundarschule', '2022', '7/8', 'alle', 10, 'flaechen_vielecke', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 35 (PDF-S. 34): „Umfang und Flächeninhalt: Dreieck, Viereck, zusammengesetzte Figuren“'),
  ('mathematik', 'Sekundarschule', '2022', '7/8', 'alle', 11, 'thales_konstruktionen', 'G: nur Konstruktion Dreieck/Mittelsenkrechte; Satz des Thales fett (nur E)', 'klp_gesk_m_klp_2022_06_17.pdf S. 35 (PDF-S. 34): „Konstruktion: Dreieck, Mittelsenkrechte“'),
  ('mathematik', 'Sekundarschule', '2022', '7/8', 'alle', 12, 'prismen_zylinder', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 35 (PDF-S. 34): „(3) benennen und charakterisieren einfache Prismen und bestimmen Oberflächeninhalt und Volumen“'),
  ('mathematik', 'Sekundarschule', '2022', '9/10', 'E', 1, 'lineare_gleichungen_lgs', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 38 (PDF-S. 37): „(7) ermitteln algebraisch und graphisch Lösungsmengen linearer Gleichungssysteme mit zwei Variablen [fett]“'),
  ('mathematik', 'Sekundarschule', '2022', '9/10', 'alle', 2, 'reelle_zahlen', 'G: nur Radizieren/Quadratwurzeln; rational/irrational, Näherungsverfahren fett (nur E)', 'klp_gesk_m_klp_2022_06_17.pdf S. 38 (PDF-S. 37): „(6) berechnen und überschlagen Quadratwurzeln einfacher Zahlen im Kopf“'),
  ('mathematik', 'Sekundarschule', '2022', '9/10', 'alle', 3, 'quadratische_funktionen', 'G-Kurs: keine Verschiebung entlang der x-Achse', 'klp_gesk_m_klp_2022_06_17.pdf S. 39 (PDF-S. 38): „Transformation der Normalparabel (G-Kurs: keine Verschiebung entlang der x-Achse)“'),
  ('mathematik', 'Sekundarschule', '2022', '9/10', 'alle', 4, 'kreis', 'G: ohne Kreisbogen/Kreissektor (fett, nur E)', 'klp_gesk_m_klp_2022_06_17.pdf S. 40 (PDF-S. 39): „Kreis: Umfang und Flächeninhalt (Kreis, Kreisbogen, Kreissektor)“'),
  ('mathematik', 'Sekundarschule', '2022', '9/10', 'alle', 5, 'pythagoras', 'G: ohne Beweis, KE (4) fett (nur E)', 'klp_gesk_m_klp_2022_06_17.pdf S. 40 (PDF-S. 39): „geometrische Sätze: Satz des Pythagoras“'),
  ('mathematik', 'Sekundarschule', '2022', '9/10', 'alle', 6, 'potenzen', 'G: nur Zehnerpotenzschreibweise; Potenzgesetze, Bruch-/Potenzschreibweise fett (nur E)', 'klp_gesk_m_klp_2022_06_17.pdf S. 38 (PDF-S. 37): „(1) stellen Zahlen in Zehnerpotenzschreibweise dar“'),
  ('mathematik', 'Sekundarschule', '2022', '9/10', 'E', 7, 'bedingte_wahrscheinlichkeit', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 41 (PDF-S. 40): „Pfadregeln, bedingte Wahrscheinlichkeit, Vierfeldertafel [fett]“'),
  ('mathematik', 'Sekundarschule', '2022', '9/10', 'alle', 8, 'statistik_beurteilen', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 41 (PDF-S. 40): „(2) analysieren … graphische Darstellungen statistischer Erhebungen kritisch und erkennen Manipulationen“'),
  ('mathematik', 'Sekundarschule', '2022', '9/10', 'alle', 9, 'quadratische_gleichungen', 'für G-Kurs: lösen rein quadratische Gleichungen', 'klp_gesk_m_klp_2022_06_17.pdf S. 38 (PDF-S. 37): „für G-Kurs: lösen rein quadratische Gleichungen“'),
  ('mathematik', 'Sekundarschule', '2022', '9/10', 'alle', 10, 'koerper_pyramide_kegel_kugel', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 40 (PDF-S. 39): „Körper: Kugel, Zylinder, Kegel und Pyramide, Oberflächeninhalt und Volumen“'),
  ('mathematik', 'Sekundarschule', '2022', '9/10', 'alle', 11, 'aehnlichkeit', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 41 (PDF-S. 40): „(6) berechnen Größen mithilfe von Ähnlichkeitsbeziehungen, geometrischen Sätzen“'),
  ('mathematik', 'Sekundarschule', '2022', '9/10', 'alle', 12, 'exponentialfunktionen', 'Für G-Kurs: exponentielle Wachstumsprozesse', 'klp_gesk_m_klp_2022_06_17.pdf S. 39 (PDF-S. 38): „Für G-Kurs: exponentielle Wachstumsprozesse“'),
  ('mathematik', 'Sekundarschule', '2022', '9/10', 'E', 13, 'trigonometrie', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 40 (PDF-S. 39): „Trigonometrie: Sinus, Kosinus, Tangens [fett]“'),
  ('mathematik', 'Sekundarschule', '2022', '9/10', 'E', 14, 'sinusfunktion', null, 'klp_gesk_m_klp_2022_06_17.pdf S. 40 (PDF-S. 39): „(14) … periodische Vorgänge mithilfe von Sinusfunktionen der Form f(x) = a⋅sin(b⋅x) [fett]“');

insert into public.skill_schulform (skill_key, schulform, kurs, klp_fassung, zulaessig, fundstelle)
values
  ('fkt_quadr_extrem', 'Gesamtschule', 'G', '2004', false, 'KLP GE 2004 S. 30: „quadratische (G-Kurs; nur f(x)=ax2)“'),
  ('fkt_quadr_nullstellen', 'Gesamtschule', 'G', '2004', false, 'KLP GE 2004 S. 30: „quadratische (G-Kurs; nur f(x)=ax2)“'),
  ('fkt_quadr_parabel', 'Gesamtschule', 'G', '2004', false, 'KLP GE 2004 S. 30: „quadratische (G-Kurs; nur f(x)=ax2)“ (2022 nur ohne Verschiebung entlang der x-Achse, PDF-S. 38)'),
  ('fkt_sinus_parameter', 'Gesamtschule', 'G', '2022', false, 'KLP GESK 2022 PDF-S. 39, KE (14) Sinusfunktionen a·sin(b·x) fett = nur Erweiterungskurs (Regel PDF-S. 14)'),
  ('stoch_bedingt_umkehr', 'Gesamtschule', 'G', '2022', false, 'KLP GESK 2022 PDF-S. 40: „bedingte Wahrscheinlichkeit, Vierfeldertafel“ fett = nur Erweiterungskurs (Regel PDF-S. 14)'),
  ('stoch_bedingt_vierfeld', 'Gesamtschule', 'G', '2022', false, 'KLP GESK 2022 PDF-S. 40: „Vierfeldertafel“ fett = nur Erweiterungskurs (Regel PDF-S. 14)'),
  ('stoch_bedingt_wkeit', 'Gesamtschule', 'G', '2022', false, 'KLP GESK 2022 PDF-S. 40: „bedingte Wahrscheinlichkeit, Vierfeldertafel“ fett = nur Erweiterungskurs (Regel PDF-S. 14)'),
  ('fkt_exp_anwendung', 'Gesamtschule', 'G', 'alle', false, 'KLP GE 2004 S. 30: „(G-Kurs; Eigenschaften exponentiellen Wachstums)“; KLP GESK 2022 PDF-S. 38: „Für G-Kurs: exponentielle Wachstumsprozesse“'),
  ('fkt_exp_gleichung', 'Gesamtschule', 'G', 'alle', false, 'KLP GE 2004 S. 29–30: b^x = c kursiv-fett, G-Kurs nur Eigenschaften exponentiellen Wachstums; KLP GESK 2022 PDF-S. 37: Exponentialgleichungen fett'),
  ('fkt_exp_term', 'Gesamtschule', 'G', 'alle', false, 'KLP GE 2004 S. 30: „exponentielle Funktionen (G-Kurs; Eigenschaften exponentiellen Wachstums)“; KLP GESK 2022 PDF-S. 38: „Für G-Kurs: exponentielle Wachstumsprozesse“, f(x) = a·q^x fett'),
  ('fkt_quadr_normalform', 'Gesamtschule', 'G', 'alle', false, 'KLP GE 2004 S. 30: „quadratische (G-Kurs; nur f(x)=ax2)“; KLP GESK 2022 PDF-S. 38: Scheitelpunktform fett, KE (9) Termumformung fett = nur Erweiterungskurs'),
  ('fkt_quadr_scheitel', 'Gesamtschule', 'G', 'alle', false, 'KLP GE 2004 S. 30: „(G-Kurs; nur f(x)=ax2)“; KLP GESK 2022 PDF-S. 38: Scheitelpunktform fett = nur Erweiterungskurs'),
  ('gleichung_quadr_anzahl', 'Gesamtschule', 'G', 'alle', false, 'KLP GE 2004 S. 29: „(G-Kurs: rein-quadratisch)“; KLP GESK 2022 PDF-S. 37: „für G-Kurs: lösen rein quadratische Gleichungen“'),
  ('gleichung_quadr_faktor', 'Gesamtschule', 'G', 'alle', false, 'KLP GE 2004 S. 29: „(G-Kurs: rein-quadratisch)“; KLP GESK 2022 PDF-S. 37: „für G-Kurs: lösen rein quadratische Gleichungen“'),
  ('gleichung_quadr_formel', 'Gesamtschule', 'G', 'alle', false, 'KLP GE 2004 S. 29: „lösen einfache quadratische Gleichungen (G-Kurs: rein-quadratisch)“; KLP GESK 2022 PDF-S. 37: „für G-Kurs: lösen rein quadratische Gleichungen“'),
  ('term_binom_faktorisieren', 'Gesamtschule', 'G', 'alle', false, 'KLP GE 2004 S. 24: binomische Formeln kursiv-fett; KLP GESK 2022 PDF-S. 32: binomische Formeln fett'),
  ('term_binom_gemischt', 'Gesamtschule', 'G', 'alle', false, 'KLP GE 2004 S. 24: „(G-Kurs: kein Produkt von Summen)“; KLP GESK 2022 PDF-S. 32: binomische Formeln fett'),
  ('term_binom_quadrat', 'Gesamtschule', 'G', 'alle', false, 'KLP GE 2004 S. 24: „multiplizieren sie aus (G-Kurs: kein Produkt von Summen)“, binomische Formeln kursiv-fett; KLP GESK 2022 PDF-S. 32: binomische Formeln fett'),
  ('term_binom_quadratdifferenz', 'Gesamtschule', 'G', 'alle', false, 'KLP GE 2004 S. 24: „(G-Kurs: kein Produkt von Summen)“; KLP GESK 2022 PDF-S. 32: binomische Formeln fett'),
  ('fkt_sinus_parameter', 'Gesamtschule', 'alle', '2004', false, 'KLP RS/GE 2004 (S. 30): nur „Sinusfunktion“, ohne a·sin(b·x); MSA-0 §1. KLP 2022 nennt f(x) = a·sin(b·x) (PDF-S. 38)'),
  ('stoch_bedingt_umkehr', 'Gesamtschule', 'alle', '2004', false, 'KLP RS/GE 2004 (S. 31): keine bedingte Wahrscheinlichkeit; MSA-0 §1. KLP 2022 nennt bedingte Wahrscheinlichkeit und Vierfeldertafel (PDF-S. 40), aber wie der KLP G9 (PDF-S. 35) kein ausdrückliches Umkehren'),
  ('stoch_bedingt_vierfeld', 'Gesamtschule', 'alle', '2004', false, 'KLP RS/GE 2004 (S. 31): keine Vierfeldertafel; MSA-0 §1. KLP 2022 nennt sie (PDF-S. 40)'),
  ('stoch_bedingt_wkeit', 'Gesamtschule', 'alle', '2004', false, 'KLP RS/GE 2004 (S. 31): nur Pfadregeln, keine bedingte Wahrscheinlichkeit; Formelsammlung MSA ohne; MSA-0 §1. KLP 2022 nennt sie (PDF-S. 40)'),
  ('fkt_sinus_bogenmass', 'Gesamtschule', 'alle', 'alle', false, 'Nur KLP G9 (klp_g9 PDF-S. 33: „Grad- und Bogenmaß“); fehlt in KLP RS/GE 2004 und RS/GESK 2022; MSA-0 §1'),
  ('fkt_sinus_einheitskreis', 'Gesamtschule', 'alle', 'alle', false, 'Nur KLP G9 (klp_g9 PDF-S. 34: „Sinus und Kosinus am Einheitskreis“); fehlt in KLP RS/GE 2004 und RS/GESK 2022; MSA-0 §1'),
  ('geo_trigo_kosinussatz', 'Gesamtschule', 'alle', 'alle', false, 'Nur KLP G9 (klp_g9 PDF-S. 34–35: „Kosinussatz“); fehlt in KLP RS/GE 2004 (S. 29–31) und RS/GESK 2022 (PDF-S. 36–40: nur rechtwinklige Dreiecke); MSA-0 §1'),
  ('stoch_bedingt_unabhaengig', 'Gesamtschule', 'alle', 'alle', false, 'Nur KLP G9 (klp_g9 PDF-S. 35: „stochastische Unabhängigkeit“); fehlt in KLP RS/GE 2004 und RS/GESK 2022; MSA-0 §1'),
  ('fkt_sinus_parameter', 'Realschule', 'alle', '2004', false, 'KLP RS/GE 2004 (S. 30): nur „Sinusfunktion“, ohne a·sin(b·x); MSA-0 §1. KLP 2022 nennt f(x) = a·sin(b·x) (PDF-S. 38)'),
  ('stoch_bedingt_umkehr', 'Realschule', 'alle', '2004', false, 'KLP RS/GE 2004 (S. 31): keine bedingte Wahrscheinlichkeit; MSA-0 §1. KLP 2022 nennt bedingte Wahrscheinlichkeit und Vierfeldertafel (PDF-S. 40), aber wie der KLP G9 (PDF-S. 35) kein ausdrückliches Umkehren'),
  ('stoch_bedingt_vierfeld', 'Realschule', 'alle', '2004', false, 'KLP RS/GE 2004 (S. 31): keine Vierfeldertafel; MSA-0 §1. KLP 2022 nennt sie (PDF-S. 40)'),
  ('stoch_bedingt_wkeit', 'Realschule', 'alle', '2004', false, 'KLP RS/GE 2004 (S. 31): nur Pfadregeln, keine bedingte Wahrscheinlichkeit; Formelsammlung MSA ohne; MSA-0 §1. KLP 2022 nennt sie (PDF-S. 40)'),
  ('fkt_sinus_bogenmass', 'Realschule', 'alle', 'alle', false, 'Nur KLP G9 (klp_g9 PDF-S. 33: „Grad- und Bogenmaß“); fehlt in KLP RS/GE 2004 und RS/GESK 2022; MSA-0 §1'),
  ('fkt_sinus_einheitskreis', 'Realschule', 'alle', 'alle', false, 'Nur KLP G9 (klp_g9 PDF-S. 34: „Sinus und Kosinus am Einheitskreis“); fehlt in KLP RS/GE 2004 und RS/GESK 2022; MSA-0 §1'),
  ('geo_trigo_kosinussatz', 'Realschule', 'alle', 'alle', false, 'Nur KLP G9 (klp_g9 PDF-S. 34–35: „Kosinussatz“); fehlt in KLP RS/GE 2004 (S. 29–31) und RS/GESK 2022 (PDF-S. 36–40: nur rechtwinklige Dreiecke); MSA-0 §1'),
  ('stoch_bedingt_unabhaengig', 'Realschule', 'alle', 'alle', false, 'Nur KLP G9 (klp_g9 PDF-S. 35: „stochastische Unabhängigkeit“); fehlt in KLP RS/GE 2004 und RS/GESK 2022; MSA-0 §1'),
  ('fkt_quadr_extrem', 'Sekundarschule', 'G', '2004', false, 'KLP GE 2004 S. 30: „quadratische (G-Kurs; nur f(x)=ax2)“'),
  ('fkt_quadr_nullstellen', 'Sekundarschule', 'G', '2004', false, 'KLP GE 2004 S. 30: „quadratische (G-Kurs; nur f(x)=ax2)“'),
  ('fkt_quadr_parabel', 'Sekundarschule', 'G', '2004', false, 'KLP GE 2004 S. 30: „quadratische (G-Kurs; nur f(x)=ax2)“ (2022 nur ohne Verschiebung entlang der x-Achse, PDF-S. 38)'),
  ('fkt_sinus_parameter', 'Sekundarschule', 'G', '2022', false, 'KLP GESK 2022 PDF-S. 39, KE (14) Sinusfunktionen a·sin(b·x) fett = nur Erweiterungskurs (Regel PDF-S. 14)'),
  ('stoch_bedingt_umkehr', 'Sekundarschule', 'G', '2022', false, 'KLP GESK 2022 PDF-S. 40: „bedingte Wahrscheinlichkeit, Vierfeldertafel“ fett = nur Erweiterungskurs (Regel PDF-S. 14)'),
  ('stoch_bedingt_vierfeld', 'Sekundarschule', 'G', '2022', false, 'KLP GESK 2022 PDF-S. 40: „Vierfeldertafel“ fett = nur Erweiterungskurs (Regel PDF-S. 14)'),
  ('stoch_bedingt_wkeit', 'Sekundarschule', 'G', '2022', false, 'KLP GESK 2022 PDF-S. 40: „bedingte Wahrscheinlichkeit, Vierfeldertafel“ fett = nur Erweiterungskurs (Regel PDF-S. 14)'),
  ('fkt_exp_anwendung', 'Sekundarschule', 'G', 'alle', false, 'KLP GE 2004 S. 30: „(G-Kurs; Eigenschaften exponentiellen Wachstums)“; KLP GESK 2022 PDF-S. 38: „Für G-Kurs: exponentielle Wachstumsprozesse“'),
  ('fkt_exp_gleichung', 'Sekundarschule', 'G', 'alle', false, 'KLP GE 2004 S. 29–30: b^x = c kursiv-fett, G-Kurs nur Eigenschaften exponentiellen Wachstums; KLP GESK 2022 PDF-S. 37: Exponentialgleichungen fett'),
  ('fkt_exp_term', 'Sekundarschule', 'G', 'alle', false, 'KLP GE 2004 S. 30: „exponentielle Funktionen (G-Kurs; Eigenschaften exponentiellen Wachstums)“; KLP GESK 2022 PDF-S. 38: „Für G-Kurs: exponentielle Wachstumsprozesse“, f(x) = a·q^x fett'),
  ('fkt_quadr_normalform', 'Sekundarschule', 'G', 'alle', false, 'KLP GE 2004 S. 30: „quadratische (G-Kurs; nur f(x)=ax2)“; KLP GESK 2022 PDF-S. 38: Scheitelpunktform fett, KE (9) Termumformung fett = nur Erweiterungskurs'),
  ('fkt_quadr_scheitel', 'Sekundarschule', 'G', 'alle', false, 'KLP GE 2004 S. 30: „(G-Kurs; nur f(x)=ax2)“; KLP GESK 2022 PDF-S. 38: Scheitelpunktform fett = nur Erweiterungskurs'),
  ('gleichung_quadr_anzahl', 'Sekundarschule', 'G', 'alle', false, 'KLP GE 2004 S. 29: „(G-Kurs: rein-quadratisch)“; KLP GESK 2022 PDF-S. 37: „für G-Kurs: lösen rein quadratische Gleichungen“'),
  ('gleichung_quadr_faktor', 'Sekundarschule', 'G', 'alle', false, 'KLP GE 2004 S. 29: „(G-Kurs: rein-quadratisch)“; KLP GESK 2022 PDF-S. 37: „für G-Kurs: lösen rein quadratische Gleichungen“'),
  ('gleichung_quadr_formel', 'Sekundarschule', 'G', 'alle', false, 'KLP GE 2004 S. 29: „lösen einfache quadratische Gleichungen (G-Kurs: rein-quadratisch)“; KLP GESK 2022 PDF-S. 37: „für G-Kurs: lösen rein quadratische Gleichungen“'),
  ('term_binom_faktorisieren', 'Sekundarschule', 'G', 'alle', false, 'KLP GE 2004 S. 24: binomische Formeln kursiv-fett; KLP GESK 2022 PDF-S. 32: binomische Formeln fett'),
  ('term_binom_gemischt', 'Sekundarschule', 'G', 'alle', false, 'KLP GE 2004 S. 24: „(G-Kurs: kein Produkt von Summen)“; KLP GESK 2022 PDF-S. 32: binomische Formeln fett'),
  ('term_binom_quadrat', 'Sekundarschule', 'G', 'alle', false, 'KLP GE 2004 S. 24: „multiplizieren sie aus (G-Kurs: kein Produkt von Summen)“, binomische Formeln kursiv-fett; KLP GESK 2022 PDF-S. 32: binomische Formeln fett'),
  ('term_binom_quadratdifferenz', 'Sekundarschule', 'G', 'alle', false, 'KLP GE 2004 S. 24: „(G-Kurs: kein Produkt von Summen)“; KLP GESK 2022 PDF-S. 32: binomische Formeln fett'),
  ('fkt_sinus_parameter', 'Sekundarschule', 'alle', '2004', false, 'KLP RS/GE 2004 (S. 30): nur „Sinusfunktion“, ohne a·sin(b·x); MSA-0 §1. KLP 2022 nennt f(x) = a·sin(b·x) (PDF-S. 38)'),
  ('stoch_bedingt_umkehr', 'Sekundarschule', 'alle', '2004', false, 'KLP RS/GE 2004 (S. 31): keine bedingte Wahrscheinlichkeit; MSA-0 §1. KLP 2022 nennt bedingte Wahrscheinlichkeit und Vierfeldertafel (PDF-S. 40), aber wie der KLP G9 (PDF-S. 35) kein ausdrückliches Umkehren'),
  ('stoch_bedingt_vierfeld', 'Sekundarschule', 'alle', '2004', false, 'KLP RS/GE 2004 (S. 31): keine Vierfeldertafel; MSA-0 §1. KLP 2022 nennt sie (PDF-S. 40)'),
  ('stoch_bedingt_wkeit', 'Sekundarschule', 'alle', '2004', false, 'KLP RS/GE 2004 (S. 31): nur Pfadregeln, keine bedingte Wahrscheinlichkeit; Formelsammlung MSA ohne; MSA-0 §1. KLP 2022 nennt sie (PDF-S. 40)'),
  ('fkt_sinus_bogenmass', 'Sekundarschule', 'alle', 'alle', false, 'Nur KLP G9 (klp_g9 PDF-S. 33: „Grad- und Bogenmaß“); fehlt in KLP RS/GE 2004 und RS/GESK 2022; MSA-0 §1'),
  ('fkt_sinus_einheitskreis', 'Sekundarschule', 'alle', 'alle', false, 'Nur KLP G9 (klp_g9 PDF-S. 34: „Sinus und Kosinus am Einheitskreis“); fehlt in KLP RS/GE 2004 und RS/GESK 2022; MSA-0 §1'),
  ('geo_trigo_kosinussatz', 'Sekundarschule', 'alle', 'alle', false, 'Nur KLP G9 (klp_g9 PDF-S. 34–35: „Kosinussatz“); fehlt in KLP RS/GE 2004 (S. 29–31) und RS/GESK 2022 (PDF-S. 36–40: nur rechtwinklige Dreiecke); MSA-0 §1'),
  ('stoch_bedingt_unabhaengig', 'Sekundarschule', 'alle', 'alle', false, 'Nur KLP G9 (klp_g9 PDF-S. 35: „stochastische Unabhängigkeit“); fehlt in KLP RS/GE 2004 und RS/GESK 2022; MSA-0 §1');
