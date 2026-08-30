-- K8-Charge 1 — Binomische Formeln: vier Knoten, zehn Kanten, drei Fehlbilder.
--
-- Legt Substrat an, KEINE Aufgaben. tasks und task_solutions werden nicht
-- angefasst; das Autorenwerk haengt am Folge-PR.
--
-- Kernlehrplan NRW G9, Inhaltsfeld Arithmetik/Algebra, Erste Stufe. Der KLP
-- bindet die Erste Stufe nicht an ein Schuljahr — klasse_herkunft = 8 ist die
-- uebliche Schnittfuehrung des Bestands (vgl. gleichung_modellieren), nicht
-- Lehrplantext.
--
-- ----------------------------------------------------------------------------
-- Warum begin/commit IN dieser Datei steht
-- ----------------------------------------------------------------------------
-- scripts/db-migrate.sh ruft `psql -f` ohne --single-transaction. Zwischen
-- skills und skill_kante liegt eine Abhaengigkeit: ein Abbruch dazwischen
-- liesse Knoten ohne Kante stehen — still, und erst im Betrieb sichtbar, weil
-- lsa_select_next_core kantenlose Knoten faktisch nie zieht. Deshalb klammert
-- die Datei selbst, wie 20260814140000_p5_gleichung_modellieren_item1.
--
-- ----------------------------------------------------------------------------
-- Warum die Fundamenttiefen 7/7/8/8 sind und nicht feiner gestuft
-- ----------------------------------------------------------------------------
-- skills_fundament_tiefe_check erlaubt 1..8, skill_kante_tiefe_guard verlangt
-- eine ECHT flachere Voraussetzung. term_ausklammern liegt bereits auf 7. Ueber
-- ihm bleibt genau eine Stufe. Eine vierstufige Kette
-- quadrat -> quadratdifferenz -> faktorisieren -> gemischt braeuchte die Tiefen
-- 6/7/8/9 und waere am CHECK gescheitert.
--
-- Der Schnitt loest das nicht durch Ausduennen, sondern durch die richtige
-- Form: die beiden Formelknoten sind Geschwister auf 7, die beiden
-- Anwendungsknoten Geschwister auf 8. Das ist auch fachlich der ehrlichere
-- Graph — Faktorisieren (Rueckrichtung) und gemischte Umformung (Vorwaerts-
-- richtung) bauen beide auf denselben zwei Formeln auf, aber nicht aufeinander.
--
-- Folge fuers Fundament, hier nur vermerkt, nicht behoben: mit dieser Charge
-- ist die Decke von 8 im Term-Ast erreicht. Die drei weiteren K8-Themen koennen
-- nicht mehr ueber term_binom_faktorisieren/-_gemischt gestapelt werden. Wer
-- das braucht, muss skills_fundament_tiefe_check anheben — eine
-- Fundament-Aenderung und ein eigener PR, kein Nebeneffekt dieser Charge.

begin;


-- ── 1. Die vier Knoten ──────────────────────────────────────────────────────
--
-- Kuerzel nach dem Muster des Bestands: <familie>_<unterfamilie>_<spezifikum>,
-- wie geo_flaeche_rechteck / geo_flaeche_dreieck. Familie ist term_, weil die
-- binomischen Formeln Termumformungen sind und alle Kanten nach unten in den
-- term_-Ast laufen.

insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
values
  ('term_binom_quadrat',          'Binomische Formeln (Quadrat einer Summe/Differenz)',
   'mathematik', 8, 7),
  ('term_binom_quadratdifferenz', 'Binomische Formel (Differenz von Quadraten)',
   'mathematik', 8, 7),
  ('term_binom_faktorisieren',    'Faktorisieren mit binomischer Formel',
   'mathematik', 8, 8),
  ('term_binom_gemischt',         'Binomische Formeln in Termumformungen',
   'mathematik', 8, 8)
on conflict (skill_key) do nothing;


-- ── 2. Die Kanten ───────────────────────────────────────────────────────────
--
-- Steht NACH den Skill-Inserts: skill_kante_tiefe ist zwar DEFERRABLE, aber
-- INITIALLY IMMEDIATE — der Guard liest fundament_tiefe beider Seiten schon
-- beim Insert. Waeren die Kanten vorher gesetzt, laege die Tiefe noch nicht vor
-- (und der FK haette ohnehin abgewiesen).
--
-- Redundante transitive Kanten sind bewusst weggelassen: skill_kante haelt laut
-- Tabellenkommentar nur DIREKTE Voraussetzungen, die Huelle wird abgefragt.
-- vorzeichen_mult_div etwa haengt bereits unter term_ausmultiplizieren.

insert into public.skill_kante (skill_key, voraussetzt_skill_key)
values
  -- Die Formel ist die abgekuerzte Doppelklammer; ohne Ausmultiplizieren laesst
  -- sich das Muster weder herleiten noch nachpruefen.
  ('term_binom_quadrat',          'term_ausmultiplizieren'),
  -- a^2 und b^2 muessen als Quadrate gelesen werden koennen, sonst ist der Term
  -- weder aufzustellen noch das Ergebnis zu deuten.
  ('term_binom_quadrat',          'potenzen'),

  -- Dass das gemischte Glied verschwindet, ist nur einsichtig, wenn die
  -- Doppelklammer gliedweise ausmultipliziert werden kann.
  ('term_binom_quadratdifferenz', 'term_ausmultiplizieren'),
  -- Das Ergebnis IST eine Differenz zweier Quadrate — ohne Quadratbegriff ist
  -- die Form nicht erkennbar.
  ('term_binom_quadratdifferenz', 'potenzen'),

  -- Faktorisieren beginnt mit dem Ausklammern gemeinsamer Faktoren; die
  -- binomische Zerlegung ist der Spezialfall, der danach kommt.
  ('term_binom_faktorisieren',    'term_ausklammern'),
  -- Die Rueckrichtung ist nur lesbar, wenn die Vorwaertsform als Muster sitzt.
  ('term_binom_faktorisieren',    'term_binom_quadrat'),
  -- a^2 - b^2 wird als faktorisierbar nur erkannt, wer die dritte Formel
  -- vorwaerts kennt.
  ('term_binom_faktorisieren',    'term_binom_quadratdifferenz'),

  -- Gemischte Terme kombinieren beide Muster; die Quadratformeln sind der
  -- Baustein, nicht das Ziel.
  ('term_binom_gemischt',         'term_binom_quadrat'),
  -- Ebenso die dritte Formel — in gemischten Umformungen stehen beide
  -- nebeneinander.
  ('term_binom_gemischt',         'term_binom_quadratdifferenz'),
  -- Das Formelergebnis steht in gemischten Umformungen regelmaessig hinter
  -- einem Minus; ohne Minusklammer kippen dort die Vorzeichen.
  ('term_binom_gemischt',         'term_minusklammer')
on conflict do nothing;


-- ── 3. Drei neue Fehlbilder ─────────────────────────────────────────────────
--
-- Gegen den Bestand geprueft (82 Slugs am 2026-08-30): keiner der drei
-- Denkfehler ist abgedeckt. quadrat_gliedweise hat keine Entsprechung;
-- falsches_vorzeichen_beim_zusammenfuehren meint das Zusammenfassen von
-- Summanden, nicht das gekippte b^2 der dritten Formel; teilgekuerzt ist der
-- strukturell verwandte, aber bruchspezifische Fall und daher nicht
-- wiederverwendbar.
--
-- freigegeben_am bleibt bewusst NULL. Laut AF3 heisst das "Entwurf, wird
-- nirgends ausgeliefert" — lsa_fehlbild_klartext gibt fuer solche Zeilen null
-- zurueck. Die Slugs sind damit sofort maschinell nutzbar, der Elterntext
-- erscheint erst nach Lenas Abnahme:
--   update public.fehlbild_labels
--      set freigegeben_am = now(), freigegeben_von = '<profil-uuid>'
--    where slug in (...);
--
-- Familienzuordnung, gegen die fuenf vorhandenen Familien geprueft:
--   gleichungen_umformen — "kennt das Verfahren, ueberspringt beim Umformen
--     aber Schritte oder wendet sie in der falschen Richtung an". Traegt beide
--     Struktur-Fehlbilder; dieselbe Familie haelt bereits klammer_vergessen und
--     klammer_falsch_gesetzt, also Term- und nicht Gleichungsfehler.
--   vorzeichen — "rechnet richtig, verliert aber das Vorzeichen, das Ergebnis
--     kippt ins Gegenteil". Genau der Fall der dritten Formel.
-- Keine neue Familie erfunden.

insert into public.fehlbild_labels (slug, familie, klartext, erklaerung)
values
  ('quadrat_gliedweise', 'gleichungen_umformen',
   'Quadriert die Klammer gliedweise – das mittlere Glied 2ab fehlt.',
   'Aus (a+b)² wird a²+b² gemacht. Der Schritt, der fehlt, ist das doppelte '
   'Produkt der beiden Glieder. Das ist kein Rechenfehler, sondern eine '
   'Abkürzung, die naheliegt, weil sie beim Ausmultiplizieren einer Summe '
   'tatsächlich erlaubt wäre. Wir zeigen die Formel deshalb einmal als '
   'ausgeschriebene Doppelklammer – danach ist das mittlere Glied sichtbar '
   'und der Fehler verschwindet meist schnell.'),

  ('quadratdifferenz_vorzeichen', 'vorzeichen',
   'Vorzeichen im Ergebnis gekippt – a²+b² statt a²−b².',
   'Bei (a+b)·(a−b) hebt sich das mittlere Glied auf, und das hintere Quadrat '
   'wird abgezogen, nicht addiert. Hier ist die Struktur erkannt, nur das '
   'Vorzeichen des letzten Glieds ist gekippt. Der Rechenweg stimmt also – '
   'geübt wird gezielt der Punkt, an dem Plus und Minus zusammentreffen.'),

  ('faktorisierung_unvollstaendig', 'gleichungen_umformen',
   'Klammert aus, erkennt die binomische Form darin aber nicht.',
   'Der erste Schritt ist richtig: der gemeinsame Faktor steht vor der '
   'Klammer. Was in der Klammer übrig bleibt, ist aber noch einmal eine '
   'binomische Form und liesse sich weiter zerlegen. Das Ergebnis ist damit '
   'nicht falsch, nur nicht zu Ende geführt. Wir üben, nach dem Ausklammern '
   'ein zweites Mal hinzusehen.')
on conflict (slug) do nothing;


commit;
