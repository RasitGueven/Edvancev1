# Fehlerfamilien und Elterntexte für Batus Pilot-Aufgaben

Stand 18.10.2026. Alle Daten wörtlich per `~/bin/dbread` aus Produktion (nur lesend). Nicht committet.
Umgesetzt in Migration `20261016170100_fehlerfamilien_batu.sql` (PR folgt), nach Rasits Entscheidungen vom 18.10.:
alles in einer Migration, `falsche_richtung` bleibt in `sachaufgaben` (Aufteilen später), `zu_frueh_gerundet` kommt
nach `runden` (dafür „oder zu früh“ im Satz), `teilgekuerzt` nach `schritt_vergessen` (F14 angepasst, Begründung unten).

Umfang: die **77 Slugs**, die in den 257 Pilot-Aufgaben (`tasks.pruef_pilot`) über
`pruef_fehler_gruppen(acceptance)` vorkommen (76 vor #266, dazu `faktor_zehn_daneben` bei `21f1c9f4`).
62 davon haben eine Familie, **15 keine**.

## Kurzliste: Elterntexte und Slugs je Familie (Migration 20261016170100)

Je Familie der Elterntext alt → neu wörtlich (neue Familien: nur neu), darunter die Slugs aus Batus Pilot-Aufgaben mit einer Beispielantwort (Aufgabe: falsche Antwort statt richtige). ✔ = schon freigegeben, ➕ = wird mit dieser Migration freigegeben. Slugs der Familie, die in Batus Aufgaben nicht vorkommen, stehen nur mit Namen dabei.

### gleichungen_umformen ✔
- alt: „Ihr Kind kennt das Verfahren, überspringt beim Umformen aber Schritte oder wendet sie in der falschen Richtung an.“
- neu: „Ihr Kind geht beim Lösen von Gleichungen den richtigen Weg, lässt aber einen Schritt aus, führt ihn nur zum Teil oder in die falsche Richtung aus oder übersieht eine zweite Lösung.“
- `addiert_statt_subtrahiert`: 3x + 9 = 30 → 13 statt 7
- `b_ignoriert`: 3x + 9 = 30 → 10 statt 7
- `division_vergessen`: x + 2y = 12 und x − 2y = 4 → x = 16 statt 8
- `falsche_gegenoperation`: 3x = 18 → 15 statt 6
- `wurzel_vergessen`: Rechteck 4 cm länger als breit, 60 cm², längere Seite → 66 statt 10
- `nicht_alle_glieder_multipliziert`: Eintrittspreise mit dem Additionsverfahren, Erwachsene → 48 € statt 8 €
- `seiten_ungleich_verknuepft`: x + 2y = 12 und x − 2y = 4 → x = 4 statt 8
- `negative_loesung_vergessen`: 2x² − 18 = 0, kleinere Lösung → 3 statt −3
- `loesung_null_verloren`: x² − 5x = 0, kleinere Lösung → 5 statt 0
- weitere: ergaenzung_vorzeichen, variablen_nicht_zusammengefuehrt
- geht ab: 7 Slugs nach klammern, 5 nach geraden_schaubilder, 2 nach schritt_vergessen

### vorzeichen ✔
- alt: „Ihr Kind rechnet richtig, verliert beim Rechnen mit negativen Zahlen aber das Vorzeichen – das Ergebnis kippt ins Gegenteil.“
- neu: „Ihr Kind geht den richtigen Rechenweg, setzt aber ein Plus oder Minus falsch: ein Minuszeichen geht verloren, kommt hinzu oder wird umgedreht.“
- `betrag_fehler`: −4 + 9 → −5 statt 5
- `seiten_verwechselt`: x − 4 = 9 → −5 statt 13
- `koordinate_vorzeichen_verloren`: Schnittpunkt zweier Geraden ablesen, x → 2 statt −2
- `pq_vorzeichen`: x² − 6x + 5 = 0, kleinere Lösung → −5 statt 1
- `vorzeichen_aus_klammer`: (x − 3)(x + 5) = 0, kleinere Lösung → −3 statt −5
- `vorzeichen_ignoriert`: −3 · 5 → 15 statt −15
- `falsches_vorzeichen_beim_zusammenfuehren`: (x + 4)² − x² − 16 → 8x + 32 statt 8x
- `quadratdifferenz_vorzeichen`: (x + 4)(x − 4) → x² + 16 statt x² − 16
- `vorzeichen_beim_umstellen`: h = 20t − 5t², wann ist der Ball wieder am Boden → −4 statt 4
- weitere: kosinussatz_vorzeichen, negativer_exponent_negativ, quadrant_vorzeichen, zehnerexponent_vorzeichen

### sachaufgaben ✔
- alt: „Ihr Kind rechnet sauber, wählt bei Textaufgaben aber den falschen Rechenweg für die beschriebene Situation.“
- neu: „Ihr Kind rechnet sauber, beantwortet aber nicht genau die gestellte Frage: Es wählt einen Rechenweg, der nicht zur beschriebenen Situation passt, oder gibt eine andere Größe an als die gesuchte.“
- `groessen_vertauscht`: K(x) = 0,1x + 8, Grundpreis → 0,1 statt 8
- `differenz_ignoriert`: Quadrat mit Seite x, eine Seite +5 m, die andere −5 m → x² statt x² − 25
- `falsche_groesse_beantwortet`: Kerze 24 cm, brennt 1,5 cm pro Stunde ab, Länge nach 6 Stunden → 9 statt 15
- `falsche_richtung`: 4,8 m Schnur in Stücke zu 0,6 m → 0,125 statt 8 (passt weder zum alten noch zum neuen Satz; wird später in zwei Slugs geteilt)
- `zuruecklegen_ignoriert` (neu hier): 10 Lose, 3 Gewinne, zwei Züge ohne Zurücklegen, genau ein Gewinn → 0,42 statt 7/15
- weitere: absolut_statt_relativ, achse_abgeschnitten_uebersehen, anteil_falsch_verteilt, antiproportional_verwechselt, bedingung_unvollstaendig, bedingung_vertauscht, dezimalverschiebung, einheit_verrutscht, gesamtheit_statt_bedingung, linear_statt_exponentiell, prozente_addiert, randsumme_verwechselt, text_direkt_gerechnet, umfang_falsch_modelliert, zeit_statt_perioden, zeitfaktor_vergessen
- geht ab: zu_frueh_gerundet nach runden

### einheiten_massstab ✔
- alt: „Ihr Kind erkennt die Aufgabe, rechnet beim Umwandeln aber mit dem falschen Faktor oder in die falsche Richtung.“
- neu: „Ihr Kind erkennt, was gefragt ist, rechnet beim Umrechnen aber mit dem falschen Faktor, in die falsche Richtung oder gar nicht um.“
- `einheit_uebersprungen`: quadratischer Teppich, mindestens 6 m², Seite in ganzen Zentimetern → 2,45 statt 245
- `faktor_zehn_daneben`: 0,25 l pro Sekunde, 12 Sekunden → 30 statt 3
- weitere: abnahmefaktor_falsch, additiv_statt_multiplikativ, grad_bogen_faktor_falsch, linearer_faktor, rate_aus_faktor_falsch, richtung_vertauscht, streckfaktor_kehrwert, wachstumsfaktor_falsch, zinszeit_falsch_umgerechnet

### potenzen_wurzeln ➕
- alt: „Ihr Kind arbeitet bei Hochzahlen, Wurzeln und der Einordnung von Zahlen mit einer Vorstellung, die dort nicht passt, etwa 3² als 3 · 2 oder √36 als die Hälfte von 36.“
- neu: „Ihr Kind rechnet bei Hochzahlen und Wurzeln nach einer Regel, die dort nicht gilt, etwa 3² als 3 · 2 oder √36 als die Hälfte von 36, oder ordnet eine Zahl falsch ein, etwa √49 als Zahl, die sich nicht genau angeben lässt.“
- `mal_exponent`: 3² → 6 statt 9
- `basis_exponent_vertauscht`: 3² → 8 statt 9
- `wurzel_halbiert`: √30 auf zwei Stellen → 15 statt 5,48
- `vorzeichen_potenz`: (−5)² → −25 statt 25
- `faktor_nicht_quadriert`: (3x + 5)(3x − 5) → 3x² − 25 statt 9x² − 25
- `faktor_ohne_wurzel`: √72 = a · √2 → a = 36 statt 6
- `irrational_verwechselt`: Für wie viele n von 1 bis 60 ist √n rational → 0 statt 7
- `wurzel_gliedweise` (neu hier): √(36 + 64) → 14 statt 10
- weitere: potenzgesetz_verwechselt

### runden ➕
- alt: „Ihr Kind rechnet richtig, rundet das Ergebnis aber anders als verlangt, schneidet Stellen nur ab oder lässt das Runden ganz weg.“
- neu: „Ihr Kind rechnet richtig, rundet aber anders als verlangt oder zu früh, schneidet Stellen nur ab oder lässt das Runden ganz weg.“
- `abgeschnitten`: 2,85 auf eine Nachkommastelle → 2,8 statt 2,9
- `falsche_stelle`: 47,38 € auf ganze Euro → 47,4 statt 47
- `immer_aufgerundet`: 3,71 auf eine Nachkommastelle → 3,8 statt 3,7
- `zu_frueh_gerundet` (neu hier, nicht in Batus Aufgaben): 500 Tiere, verdoppeln sich alle 3 Jahre, nach 10 Jahren → 5028 statt 5040

### schritt_vergessen (neu) ➕
- neu: „Ihr Kind geht den richtigen Rechenweg, lässt aber einen Teil davon weg oder hört zu früh auf, etwa wenn es beim Dreieck das Halbieren vergisst oder einen Bruch nicht bis zum Ende kürzt.“
- `halbieren_vergessen`: Dreieck mit Grundseite (x + 4) cm und Höhe 6 cm → 6x + 24 statt 3x + 12
- `mal_zwei_vergessen`: (x + 3)² → x² + 3x + 9 statt x² + 6x + 9
- `teilgekuerzt`: 18/24 vollständig kürzen → 9/12 statt 3/4
- `differenz_vergessen`: Halbkreisfenster, Strebe mit 32° zur Unterkante, gesuchter Winkel → 122° statt 58°
- `gegenereignis_nicht_abgezogen`: zwei Würfe, mindestens eine Sechs → 25/36 statt 11/36
- `nur_ein_pfad`: 10 Lose, 3 Gewinne, zwei Züge, genau ein Gewinn → 7/30 statt 7/15
- `nur_einmal_addiert`: Steigung 2 durch P(1 | 3), y bei x = 4 → 5 statt 9
- `ausklammern_nicht_ggt`: 12x + 18 → 3(4x + 6) statt 6(2x + 3)
- `faktorisierung_unvollstaendig`: 2x² − 18 → 2(x² − 9) statt 2(x + 3)(x − 3)

### figuren (neu) ➕
- neu: „Ihr Kind geht bei Figuren den richtigen Weg, setzt aber eine falsche Strecke oder einen falschen Winkel ein oder lässt einen Teil der Figur weg, etwa die schräge Seite statt der Höhe.“
- `falsche_hoehe`: Raute mit Seite 13 cm und Diagonalen 24 cm und 10 cm → 169 cm² statt 120 cm²
- `nur_eine_grundseite`: Trapez a = 8 cm, c = 4 cm, h = 5 cm → 20 cm² statt 30 cm²
- `teilflaeche_vergessen`: Rechteck x mal 4 cm mit angesetztem Quadrat (4 cm) → 4x statt 4x + 16
- `basiswinkel_falsch_zugeordnet`: Thaleskreis, ∠BMC = 64°, α → 26° statt 32°
- `rechter_winkel_falsche_ecke`: Thaleskreis, α = 35°, β → 90° statt 55°

### geraden_schaubilder (neu) ➕
- neu: „Ihr Kind arbeitet mit Geraden und Schaubildern, verwechselt dabei aber, welche Zahl wofür steht, etwa den Wert nach rechts mit dem nach oben, oder erkennt nicht richtig, ob und wo sich zwei Geraden schneiden.“
- `koordinaten_vertauscht`: Schnittpunkt ablesen → (3 | 2) statt (2 | 3)
- `achsenabschnitt_verwechselt`: f(x) = 4x − 6, Schnitt mit der y-Achse → 1,5 statt −6
- `m_b_vertauscht`: f(x) = 3x + 5, Schnitt mit der y-Achse → 3 statt 5
- `steigung_kehrwert`: Gerade durch A(0 | 1) und B(2 | 5), Steigung → 1/2 statt 2
- `loesungsanzahl_verwechselt`: zwei parallele Geraden, wie viele Lösungen → „unendlich viele“ statt „keine“
- `parallele_uebersehen`: dieselbe Aufgabe → „genau eine“ statt „keine“

### klammern (neu) ➕
- neu: „Ihr Kind rechnet mit Klammern, verrechnet dabei aber nicht jeden Teil richtig, nimmt eine falsche Regel oder lässt eine nötige Klammer weg, etwa (x + 3)² = x² + 9 statt x² + 6x + 9.“
- `binom_formel_verwechselt`: x² + 8x + 16 als Quadrat → (x + 4)(x − 4) statt (x + 4)²
- `mischglieder_nicht_aufgehoben`: (x + 4)(x − 4) → x² − 8x − 16 statt x² − 16
- `quadrat_gliedweise`: 2,5² → 4,25 statt 6,25
- `klammer_falsch_gesetzt`: 3x² + 12x + 12 → (3x + 6)² statt 3(x + 2)²
- `klammer_vergessen`: Dreieck mit Grundseite (x + 4) cm und Höhe 6 cm → 3x + 4 statt 3x + 12
- `ausklammern_falsch_geteilt`: 6x + 12 → 6(x + 4) statt 6(x + 2)
- `ausklammern_glied_nicht_geteilt`: 4x + 8 → 4(x + 8) statt 4(x + 2)

### brueche_anteile ➕ (Text bleibt)
- „Ihr Kind wendet bei Brüchen und Anteilen eine Regel an, die an dieser Stelle nicht gilt, oder teilt zwei Zahlen in umgekehrter Reihenfolge, etwa 1/2 + 1/6 = 2/8 oder 1/5 = 5.“
- `additiv_gekuerzt`: 18/24 kürzen → 17/23 statt 3/4
- `umgekehrt_geteilt`: 1/5 als Kommazahl → 5 statt 0,2
- `ziffern_gelesen`: 1/5 als Kommazahl → 0,15 statt 0,2
- weitere: bezug_vertauscht, falschen_gestuerzt, hauptnenner_bei_mult, nenner_addiert, nenner_addiert_zaehler_ok, nicht_gestuerzt, zaehler_nicht_erweitert

### kommazahlen ➕ (Text bleibt)
- „Ihr Kind rechnet mit Kommazahlen, setzt dabei aber das Komma, eine Ziffer oder einen Übertrag an die falsche Stelle oder gibt weniger Stellen an als verlangt.“
- `komma_ignoriert`: 0,6 · 0,4 → 24 statt 0,24
- `komma_nicht_verschoben`: 4,8 : 0,6 → 0,8 statt 8
- `kommastellen_zu_viel`: 0,6 · 0,4 → 0,024 statt 0,24
- `kommastellen_zu_wenig`: 0,6 · 0,4 → 2,4 statt 0,24
- `stellenwert_ignoriert`: 0,25 + 0,4 → 0,29 statt 0,65
- `uebertrag_vergessen`: 0,8 + 0,7 → 0,15 statt 1,5

### rechenart_formel ➕ (Text bleibt)
- „Ihr Kind rechnet sauber, nimmt aber eine andere Rechenart oder Formel, als die Aufgabe verlangt, etwa Plus statt Mal oder den Umfang statt der Fläche.“
- `falsche_operation`: Rucksack leer 0,85 kg, voll 3,2 kg, Inhalt → 4,05 statt 2,35
- `plus_statt_mal`: Beet doppelt so lang wie breit, Breite 3,5 m, Fläche → 10,5 statt 24,5
- `umfang_statt_flaeche`: Rechteck x cm lang, 5 cm breit, Flächenterm → 2x + 10 statt 5x
- `mult_add_verwechslung` (neu hier): −3 · 5 → 2 statt −15
- `pfadregel_addiert` (neu hier): zwei Würfe, mindestens eine Sechs → 1/3 statt 11/36
- weitere: flaeche_statt_umfang, multipliziert_statt_dividiert, oberflaeche_statt_volumen, volumen_statt_oberflaeche

### rechenreihenfolge ✔ (Text bleibt, nicht mehr bei Batu)
- „Ihr Kind rechnet der Reihe nach von links nach rechts, statt auf die Rechenreihenfolge zu achten.“
- gibt ab: mult_add_verwechslung nach rechenart_formel, wurzel_gliedweise nach potenzen_wurzeln
- bleibt: vorrang_ignoriert

### teilgekuerzt und F14

F14 in `supabase/checks/fehlbild_familien.PRUEFUNG.sql` hielt den Slug seit AF4 (14.08.) ohne Familie und Klartext. Grund:
In den damals belegten Fällen (bruch_add) ist das Ergebnis gar nicht gekürzt (4/12 statt 1/3), der Name sagt aber „teilweise“.
Das ist eine Frage des Slug-Namens, kein inhaltlicher Grund gegen eine Familie: Der Klartext seit 20261016120100 („Kürzt den Bruch
nicht vollständig …“) und der Satz von `schritt_vergessen` („einen Bruch nicht bis zum Ende kürzt“) treffen beide Fälle. Bei
Batu sind die Belege ohnehin teilweise gekürzt (18/24 → 9/12). Deshalb: `schritt_vergessen`. F14 prüft jetzt, dass
`teilgekuerzt` keine andere Familie bekommt. Das Umbenennen bleibt offen.

---

## Vorschlag vom 18.10. (Grundlage der Entscheidungen)

### Was im Eltern-Report ankommt

- Angezeigt wird nur `fehlbild_familien.elterntext`. Er erscheint nur bei gesetztem
  `fehlbild_familien.freigegeben_am` und erst ab 2 Vorkommen in 2 Aufgaben, gezählt über die ganze Familie
  (`src/lib/reportFehlbilder.ts`). Slugs ohne Familie fallen still weg.
- Die Freigabe des einzelnen Slugs (`fehlbild_labels.freigegeben_am`) spielt dafür keine Rolle (E2 in
  `docs/fehlbilder/klartexte-entscheidungen.md`).
- **Bereits freigegeben:** `gleichungen_umformen`, `vorzeichen`, `sachaufgaben`, `einheiten_massstab` und
  `rechenreihenfolge`. Dort wirkt jede Text- und jede Zuordnungsänderung sofort beim Einspielen.
- Verschiebt man einen Slug aus einer freigegebenen in eine noch nicht freigegebene Familie, verschwindet er
  aus dem Report, bis die neue Familie freigegeben ist.
- Größere Familien erreichen die Schwelle früher, weil die Vorkommen aller Slugs zusammengezählt werden.

### Kurzfassung

- **15 Slugs ohne Familie:** 2 kommen in bestehende Familien (`pfadregel_addiert` → `rechenart_formel`,
  `zuruecklegen_ignoriert` → `sachaufgaben`), 13 in vier neue Familien.
- **Neue Familien, alle mit Elterntext-Entwurf:**
  - `schritt_vergessen`: richtiger Weg, ein Teil fehlt oder hört zu früh auf
  - `figuren`: falsche Strecke, falscher Winkel oder ein Teil der Figur fehlt
  - `geraden_schaubilder`: verwechselt, welche Zahl wofür steht
  - `klammern`: Rechnen mit Klammern
- **`gleichungen_umformen`** trägt heute 23 von Batus Slugs, darunter Terme, Klammern und Geraden. Der Satz
  „überspringt beim Umformen Schritte“ passt auf 14 davon nicht. Vorschlag: 14 umhängen, Text für die
  verbleibenden 9 schärfen.
- **Weitere Umhängungen:**
  - `rechenreihenfolge`: Die beiden Batu-Slugs passen nicht (Plus/Mal verwechselt; Wurzel aus einer Summe) →
    `rechenart_formel` bzw. `potenzen_wurzeln`.
  - `falsche_richtung` → `kommazahlen`.
- **Text anpassen:** `gleichungen_umformen`, `vorzeichen`, `sachaufgaben`, `einheiten_massstab`,
  `kommazahlen` (wegen `falsche_richtung`) und `potenzen_wurzeln` (leicht).
- **Unverändert:** `brueche_anteile`, `rechenart_formel`, `runden`.

Aufgaben je Familie, vorher → nachher (verschiedene Pilot-Aufgaben mit mindestens einem Slug der Familie; Slugs in Klammern):

| Familie | vorher | nachher |
|---|---|---|
| gleichungen_umformen ✔ | 101 (23) | 47 (9) |
| vorzeichen ✔ | 61 (9) | 61 (9) |
| sachaufgaben ✔ | 34 (4) | 28 (4) |
| rechenreihenfolge ✔ | 18 (2) | 0 (0) |
| einheiten_massstab ✔ | 3 (2) | 3 (2) |
| potenzen_wurzeln | 62 (7) | 63 (8) |
| kommazahlen | 34 (6) | 34 (7) |
| runden | 19 (3) | 19 (3) |
| rechenart_formel | 16 (3) | 33 (5) |
| brueche_anteile | 13 (3) | 13 (3) |
| schritt_vergessen (neu) | – | 53 (9) |
| klammern (neu) | – | 43 (7) |
| geraden_schaubilder (neu) | – | 22 (6) |
| figuren (neu) | – | 13 (5) |
| ohne Familie | 52 (15) | 0 (0) |

✔ = schon freigegeben.

---

### Liste A: Slugs ohne Familie (15)

Je Slug: Pilot-Aufgaben und Knoten, ein Beispiel (richtig → falsch), Vorschlag. Geprüft wurden zuerst die
bestehenden Familien; wo keine passt, steht der Grund dabei.

| Slug | Aufg. | Knoten | Beispiel | Vorschlag | Warum |
|---|---|---|---|---|---|
| `pfadregel_addiert` | 3 | stoch_pfad_summe | Würfel zweimal, mindestens eine Sechs: 11/36 → 1/3 | **rechenart_formel** (bestehend) | „Plus statt Mal“ steht so schon im Familiensatz. |
| `zuruecklegen_ignoriert` | 3 | stoch_pfad_summe | ohne Zurücklegen: 7/15 → 0,52 | **sachaufgaben** (bestehend, Text angepasst, s. Liste B) | Rechnet so, als würde zurückgelegt; der Rechenweg passt nicht zur beschriebenen Situation. |
| `halbieren_vergessen` | 23 | geo_flaeche_drachen_raute, geo_flaeche_term, geo_flaeche_trapez, geo_winkel_thales, gleichung_quadr_anzahl, term_binom_faktorisieren, term_binom_quadrat | Dreieck, Grundseite (x + 4), Höhe 6: 3x + 12 → 6x + 24 | **schritt_vergessen** (neu) | Kommt in Flächen, Winkeln und Termen vor. „Beim Umformen“ (`gleichungen_umformen`) trifft Flächenformeln nicht, und `rechenart_formel` passt auch nicht, weil die Formel richtig ist. |
| `mal_zwei_vergessen` | 4 | term_binom_quadrat | (x + 3)² = x² + 6x + 9 → x² + 3x + 9 | **schritt_vergessen** (neu) | Außerhalb des Piloten auch bei Oberflächen (Prisma, Zylinder, Quader); ein Klammer-Satz würde dort nicht passen. |
| `teilgekuerzt` | 9 | bruch_kuerzen, zahl_wurzel_irrational | 12/18 → 6/9 statt 2/3 | **schritt_vergessen** (neu) | `brueche_anteile` beschreibt „eine Regel, die nicht gilt“; hier ist die Regel richtig, nur nicht zu Ende geführt. ⚠ Die Prüfdatei `supabase/checks/fehlbild_familien.PRUEFUNG.sql` (F14) verlangt noch, dass `teilgekuerzt` ohne Familie bleibt. Sie ist schon seit dem Klartext veraltet und muss mit angepasst werden. |
| `differenz_vergessen` | 2 | geo_winkel_thales | 58° → 122° (Zwischenergebnis) | **schritt_vergessen** (neu) | Der letzte Abzug fehlt; keine bestehende Familie beschreibt „hört zu früh auf“. |
| `gegenereignis_nicht_abgezogen` | 2 | stoch_pfad_summe | mindestens eine Sechs: 11/36 → 25/36 | **schritt_vergessen** (neu) | Rechnet richtig, zieht am Ende nicht von 1 ab. |
| `nur_ein_pfad` | 5 | stoch_pfad_summe | 7/15 → 7/30 | **schritt_vergessen** (neu) | Lässt einen von mehreren passenden Wegen weg. |
| `nur_einmal_addiert` | 1 | fkt_linear_steigung | Steigung 2 durch P(1 \| 3), y bei x = 4: 9 → 5 | **schritt_vergessen** (neu) | Zählt einmal statt dreimal dazu. |
| `falsche_hoehe` | 2 | geo_flaeche_drachen_raute, geo_flaeche_trapez | Raute mit e = 24, f = 10: 120 → 169 (Seite · Seite) | **figuren** (neu) | Formel richtig, falsche Strecke eingesetzt; `rechenart_formel` meint eine andere Formel. |
| `nur_eine_grundseite` | 6 | geo_flaeche_trapez | a = 8, c = 4, h = 5: 30 → 20 | **figuren** (neu) | wie oben |
| `teilflaeche_vergessen` | 1 | geo_flaeche_term | Rechteck plus Quadrat: 4x + 16 → 4x | **figuren** (neu) | Ein Teil der Figur fehlt. |
| `basiswinkel_falsch_zugeordnet` | 2 | geo_winkel_thales | 32° → 26° | **figuren** (neu) | Falscher Winkel; keine bestehende Familie zu Winkeln. |
| `rechter_winkel_falsche_ecke` | 3 | geo_winkel_thales | 55° → 90° | **figuren** (neu) | wie oben |
| `koordinaten_vertauscht` | 4 | gleichung_lgs_grafisch | Schnittpunkt x = 2, y = 3 → x = 3, y = 2 | **geraden_schaubilder** (neu) | Kein „Umformen“; außerhalb des Piloten bei Parabeln, Sinus und Koordinaten (16 Aufgaben). |

### Neue Familien: Elterntext-Entwürfe

Jeder Satz ist an allen Slugs der Familie geprüft, auch an denen, die aus Liste B dazukommen (*kursiv*).

**`schritt_vergessen`**
> Ihr Kind geht den richtigen Rechenweg, lässt aber einen Teil davon weg oder hört zu früh auf, etwa wenn es beim Dreieck das Halbieren vergisst oder einen Bruch nicht bis zum Ende kürzt.

Slugs: halbieren_vergessen, mal_zwei_vergessen, teilgekuerzt, differenz_vergessen, gegenereignis_nicht_abgezogen,
nur_ein_pfad, nur_einmal_addiert, *faktorisierung_unvollstaendig*, *ausklammern_nicht_ggt*.

**`figuren`**
> Ihr Kind geht bei Figuren den richtigen Weg, setzt aber eine falsche Strecke oder einen falschen Winkel ein oder lässt einen Teil der Figur weg, etwa die schräge Seite statt der Höhe.

Slugs: falsche_hoehe, nur_eine_grundseite, teilflaeche_vergessen, basiswinkel_falsch_zugeordnet, rechter_winkel_falsche_ecke.
Später passen hier wohl auch Slugs ohne Familie außerhalb von Batus Aufgaben (seite_vergessen, nur_eine_seite,
summe_180_statt_360, aussenwinkel_verwechselt). Das ist nicht Teil dieses Pakets.

**`geraden_schaubilder`**
> Ihr Kind arbeitet mit Geraden und Schaubildern, verwechselt dabei aber, welche Zahl wofür steht, etwa den Wert nach rechts mit dem nach oben, oder erkennt nicht richtig, ob und wo sich zwei Geraden schneiden.

Slugs: koordinaten_vertauscht, *achsenabschnitt_verwechselt*, *m_b_vertauscht*, *steigung_kehrwert*,
*loesungsanzahl_verwechselt*, *parallele_uebersehen*.

**`klammern`**
> Ihr Kind rechnet mit Klammern, verrechnet dabei aber nicht jeden Teil richtig, nimmt eine falsche Regel oder lässt eine nötige Klammer weg, etwa (x + 3)² = x² + 9 statt x² + 6x + 9.

Slugs: *binom_formel_verwechselt*, *mischglieder_nicht_aufgehoben*, *quadrat_gliedweise*, *klammer_falsch_gesetzt*,
*klammer_vergessen*, *ausklammern_falsch_geteilt*, *ausklammern_glied_nicht_geteilt*.

Die Schlüssel sind nur intern und werden nie angezeigt (INV-4.3). Andere Namen sind problemlos möglich.

---

### Liste B: Elterntexte der Familien mit Batus Slugs

Texte wörtlich aus Produktion. Bei jeder Familie stehen Batus Slugs mit ihrem Klartext und darunter die übrigen
Slugs der Familie, weil ein geänderter Satz auch für sie passen muss.
⚠ = Der Satz trifft mindestens ein Fehlbild nicht; Gegenvorschlag folgt.

### ⚠ `gleichungen_umformen` (freigegeben 14.08.)

> Ihr Kind kennt das Verfahren, überspringt beim Umformen aber Schritte oder wendet sie in der falschen Richtung an.

Batus Slugs (23), mit Befund:

| Slug | passt? | Vorschlag |
|---|---|---|
| addiert_statt_subtrahiert | ja (falsche Richtung) | bleibt |
| b_ignoriert | ja (Schritt übersprungen) | bleibt |
| division_vergessen | ja | bleibt |
| falsche_gegenoperation | ja (falsche Richtung) | bleibt |
| wurzel_vergessen | ja | bleibt |
| nicht_alle_glieder_multipliziert | halb: Der Schritt wird nur auf einen Teil angewendet | bleibt, Text deckt es ab |
| seiten_ungleich_verknuepft | halb: links anders als rechts | bleibt, Text deckt es ab |
| negative_loesung_vergessen | nein: Es wird kein Schritt übersprungen, eine zweite Lösung fehlt | bleibt, Text deckt es ab |
| loesung_null_verloren | nein: wie oben | bleibt, Text deckt es ab |
| binom_formel_verwechselt | nein: kein Umformen; die falsche binomische Formel | → klammern |
| mischglieder_nicht_aufgehoben | nein | → klammern |
| quadrat_gliedweise | nein | → klammern |
| klammer_falsch_gesetzt | nein | → klammern |
| klammer_vergessen | nein | → klammern |
| ausklammern_falsch_geteilt | nein | → klammern |
| ausklammern_glied_nicht_geteilt | nein | → klammern |
| ausklammern_nicht_ggt | nein: richtig, aber nicht so weit wie möglich | → schritt_vergessen |
| faktorisierung_unvollstaendig | nein: richtig, aber nicht zu Ende | → schritt_vergessen |
| achsenabschnitt_verwechselt | nein: Ablesen, kein Umformen | → geraden_schaubilder |
| m_b_vertauscht | nein | → geraden_schaubilder |
| steigung_kehrwert | nein | → geraden_schaubilder |
| loesungsanzahl_verwechselt | nein: Lage zweier Geraden | → geraden_schaubilder |
| parallele_uebersehen | nein | → geraden_schaubilder |

Weitere Slugs der Familie: ergaenzung_vorzeichen, variablen_nicht_zusammengefuehrt.

**Gegenvorschlag Text:**
> Ihr Kind geht beim Lösen von Gleichungen den richtigen Weg, lässt aber einen Schritt aus, führt ihn nur zum Teil oder in die falsche Richtung aus oder übersieht eine zweite Lösung.

Warum: „kennt das Verfahren“ ist eine Aussage über das Können, nicht über das Tun. Der neue Satz sagt, worum
es geht (Gleichungen), und deckt die beiden Fälle mit fehlender zweiter Lösung ab. Er passt auch auf
ergaenzung_vorzeichen (falsche Richtung) und variablen_nicht_zusammengefuehrt (Schritt ausgelassen). Bei
wurzel_vergessen außerhalb des Piloten (Pythagoras) trifft er ebenfalls zu.

Alternative ohne Umhängen: Den Text so weit fassen, dass er auch Terme und Geraden abdeckt. Dann wird er für Eltern zu
allgemein („wendet eine Regel falsch an“). Das empfehle ich nicht.

### ⚠ `vorzeichen` (freigegeben 14.08.)

> Ihr Kind rechnet richtig, verliert beim Rechnen mit negativen Zahlen aber das Vorzeichen – das Ergebnis kippt ins Gegenteil.

| Slug | Klartext | passt? |
|---|---|---|
| betrag_fehler | Betrag richtig, Vorzeichen des Ergebnisses gekippt. | ja |
| seiten_verwechselt | Subtrahiert in umgekehrter Reihenfolge, Ergebnis mit falschem Vorzeichen. | ja |
| koordinate_vorzeichen_verloren | Koordinate richtig abgelesen, aber das Minus fehlt. | ja |
| pq_vorzeichen | Setzt in der p-q-Formel die Zahl vor dem x mit falschem Vorzeichen ein; … | ja |
| vorzeichen_aus_klammer | Liest aus einer Klammer wie (x − 3) den Wert mit falschem Vorzeichen ab: −3 statt 3. | ja |
| vorzeichen_ignoriert | Lässt die Minuszeichen weg und addiert die Beträge. | **nein**: −4 + 9 → 13, das ist nicht das Gegenteil von 5 |
| falsches_vorzeichen_beim_zusammenfuehren | x-Terme richtig zusammengefasst, die Konstante addiert statt subtrahiert. | **nein**: 8x + 32 statt 8x; nur ein Teil kippt |
| quadratdifferenz_vorzeichen | Schreibt bei (a + b)(a − b) am Ende Plus statt Minus: … | **nein**: kein Rechnen mit negativen Zahlen, ein Minus im Term wird zum Plus |
| vorzeichen_beim_umstellen | Betrag richtig, das Minus des Koeffizienten bleibt am Ergebnis hängen. | **nein**: Hier kommt ein Minus hinzu, es geht keines verloren |

Weitere Slugs der Familie: kosinussatz_vorzeichen, negativer_exponent_negativ, quadrant_vorzeichen,
zehnerexponent_vorzeichen.

**Gegenvorschlag Text:**
> Ihr Kind geht den richtigen Rechenweg, setzt aber ein Plus oder Minus falsch: ein Minuszeichen geht verloren, kommt hinzu oder wird umgedreht.

Warum: Der neue Satz passt auf alle 13, auch auf negativer_exponent_negativ (2⁻³ = −8: ein Minus kommt hinzu)
und kosinussatz_vorzeichen (das Minus wird zum Plus). „Kippt ins Gegenteil“ fällt weg.

### ⚠ `sachaufgaben` (freigegeben 14.08.)

> Ihr Kind rechnet sauber, wählt bei Textaufgaben aber den falschen Rechenweg für die beschriebene Situation.

| Slug | Klartext | passt? | Vorschlag |
|---|---|---|---|
| groessen_vertauscht | Vertauscht Grundbetrag und Rate beim Aufstellen. | ja | bleibt |
| differenz_ignoriert | Verteilt gleichmäßig, der genannte Unterschied entfällt. | ja | bleibt |
| falsche_groesse_beantwortet | Rechnet richtig, gibt aber die andere gesuchte Größe an. | **nein**: Der Rechenweg stimmt, nur die Antwort ist eine andere Größe. Kommt in 18 Pilot-Aufgaben vor, viele davon keine Textaufgaben (zahl_wurzel_teilweise, zahl_wurzel_irrational) | bleibt, Text anpassen |
| falsche_richtung | Rechnet den Kehrwert oder verschiebt das Komma um zwei Stellen. | **nein**: Bei Batu nur dezimal_div (4,8 : 0,6 → 0,125 oder 0,08), keine Textaufgabe | → kommazahlen |
| *zuruecklegen_ignoriert* (neu) | Rechnet beim Ziehen ohne Zurücklegen im zweiten Zug mit der alten Anzahl weiter (oder umgekehrt). | ja, mit neuem Text | neu |

Weitere Slugs der Familie (17), unter anderem: absolut_statt_relativ, antiproportional_verwechselt,
bedingung_unvollstaendig, bedingung_vertauscht, dezimalverschiebung, prozente_addiert, zu_frueh_gerundet.

**Gegenvorschlag Text:**
> Ihr Kind rechnet sauber, beantwortet aber nicht genau die gestellte Frage: Es wählt einen Rechenweg, der nicht zur beschriebenen Situation passt, oder gibt eine andere Größe an als die gesuchte.

Nebenbefunde außerhalb von Batus Slugs, nicht Teil dieses Pakets:
- `zu_frueh_gerundet` passt weder zum alten noch zum neuen Satz und gehört eher zu `runden`.
- `falsche_richtung` hat zwei Bedeutungen: Bei prozent_veraenderung (10 Aufgaben, z. B. 25 % Abnahme von 60 € → 75)
  steht der Slug für vertauschte Zu- und Abnahme, sein Klartext beschreibt aber nur den Fall bei dezimal_div.
  Wird er nach `kommazahlen` verschoben, bekommen diese 10 Aufgaben einen unpassenden Satz. Sauber wäre ein
  eigener Slug für die Prozentfälle, etwa `zu_abnahme_vertauscht`. Das ändert die Akzeptanz und gehört in ein
  eigenes Paket wie #266.

### ⚠ `einheiten_massstab` (freigegeben 14.08.)

> Ihr Kind erkennt die Aufgabe, rechnet beim Umwandeln aber mit dem falschen Faktor oder in die falsche Richtung.

| Slug | Klartext | passt? |
|---|---|---|
| einheit_uebersprungen | Rechnet gar nicht um, die Ausgangszahl bleibt stehen. | **nein**: 2,25 m² → Seite 1,5 statt 150 cm; es wird gar nicht umgerechnet |
| faktor_zehn_daneben | Ergebnis um den Faktor 10 daneben, in beide Richtungen. | halb: In 41 Aufgaben außerhalb des Piloten (Größen, Maßstab, Zehnerpotenzen) passt es. Bei Batu nur `21f1c9f4` (dezimal_mult, 0,25 · 12 → 30), dort geht es nicht ums Umwandeln. Einzelfall, die Familie bleibt |

Weitere Slugs: richtung_vertauscht, linearer_faktor, streckfaktor_kehrwert, additiv_statt_multiplikativ,
wachstumsfaktor_falsch, abnahmefaktor_falsch, rate_aus_faktor_falsch, grad_bogen_faktor_falsch,
zinszeit_falsch_umgerechnet.

**Gegenvorschlag Text:**
> Ihr Kind erkennt, was gefragt ist, rechnet beim Umrechnen aber mit dem falschen Faktor, in die falsche Richtung oder gar nicht um.

### ⚠ `rechenreihenfolge` (freigegeben 14.08.)

> Ihr Kind rechnet der Reihe nach von links nach rechts, statt auf die Rechenreihenfolge zu achten.

| Slug | Klartext | passt? | Vorschlag |
|---|---|---|---|
| mult_add_verwechslung | Führt die Strichoperation als Punktoperation aus. | **nein**: −3 · 5 → 2 (addiert), −4 + 9 → −36 (multipliziert); verwechselt Plus und Mal, nichts mit der Reihenfolge | → rechenart_formel |
| wurzel_gliedweise | Zieht die Wurzel aus einer Summe Glied für Glied: √(9 + 16) als √9 + √16. | **nein**: keine Reihenfolge von links nach rechts | → potenzen_wurzeln |

Weiterer Slug: vorrang_ignoriert, dazu passt der Satz. Der Text bleibt; die Familie betrifft Batu danach nicht mehr.
Nebenbefund: Der Klartext von mult_add_verwechslung beschreibt nur eine Richtung, die Beispiele zeigen beide.

### `brueche_anteile` (nicht freigegeben)

> Ihr Kind wendet bei Brüchen und Anteilen eine Regel an, die an dieser Stelle nicht gilt, oder teilt zwei Zahlen in umgekehrter Reihenfolge, etwa 1/2 + 1/6 = 2/8 oder 1/5 = 5.

| Slug | Klartext | passt? |
|---|---|---|
| additiv_gekuerzt | Beim Kürzen wurde von Zähler und Nenner jeweils 1 abgezogen, statt beide durch dieselbe Zahl zu teilen. | ja |
| umgekehrt_geteilt | Beim Teilen wurde die Reihenfolge umgedreht, etwa 1/5 als 5 : 1 gerechnet. | ja |
| ziffern_gelesen | Zähler und Nenner wurden hinter das Komma geschrieben, etwa 1/5 als 0,15. | ja („Regel, die nicht gilt“) |

Weitere Slugs: bezug_vertauscht, falschen_gestuerzt, hauptnenner_bei_mult, nenner_addiert, nenner_addiert_zaehler_ok,
nicht_gestuerzt, zaehler_nicht_erweitert. Alle passen. **Text bleibt.**

### ⚠ `kommazahlen` (nicht freigegeben), nur wegen `falsche_richtung`

> Ihr Kind rechnet mit Kommazahlen, setzt dabei aber das Komma, eine Ziffer oder einen Übertrag an die falsche Stelle oder gibt weniger Stellen an als verlangt.

| Slug | Klartext | passt? |
|---|---|---|
| komma_ignoriert | Beim Malnehmen von Kommazahlen wurde das Komma im Ergebnis weggelassen. | ja |
| komma_nicht_verschoben | Beim Teilen durch eine Kommazahl wurde das Komma nicht bei beiden Zahlen verschoben. | ja |
| kommastellen_zu_viel | Das Komma steht im Ergebnis eine Stelle zu weit links, … | ja |
| kommastellen_zu_wenig | Das Ergebnis hat zu wenige Stellen nach dem Komma, … | ja |
| stellenwert_ignoriert | Schreibt Kommazahlen nicht Stelle unter Stelle … | ja |
| uebertrag_vergessen | Beim Addieren von Kommazahlen wurde der Übertrag vor das Komma vergessen. | ja |
| *falsche_richtung* (neu) | Rechnet den Kehrwert oder verschiebt das Komma um zwei Stellen. | nur mit Ergänzung („teilt umgekehrt“) |

**Gegenvorschlag Text** (nur, wenn falsche_richtung hierher kommt):
> Ihr Kind rechnet mit Kommazahlen, setzt dabei aber das Komma, eine Ziffer oder einen Übertrag an die falsche Stelle, gibt weniger Stellen an als verlangt oder teilt in umgekehrter Reihenfolge.

Ohne falsche_richtung bleibt der Text.

### ⚠ `potenzen_wurzeln` (nicht freigegeben), nur Maßstab „was das Kind tut“

> Ihr Kind arbeitet bei Hochzahlen, Wurzeln und der Einordnung von Zahlen mit einer Vorstellung, die dort nicht passt, etwa 3² als 3 · 2 oder √36 als die Hälfte von 36.

| Slug | Klartext | passt? |
|---|---|---|
| mal_exponent | Die Hochzahl wurde als Faktor genommen, etwa 3² als 3 · 2 = 6 statt 3 · 3 = 9. | ja |
| basis_exponent_vertauscht | Grundzahl und Hochzahl wurden vertauscht, etwa 2⁵ als 5² gerechnet. | ja |
| wurzel_halbiert | Statt die Wurzel zu ziehen, wurde die Zahl halbiert, etwa √36 = 18 statt 6. | ja |
| vorzeichen_potenz | Behandelt das Minuszeichen beim Hochnehmen falsch: … | ja |
| faktor_nicht_quadriert | Quadriert bei (2x)² nur das x, nicht den Faktor davor: 2x² statt 4x². | ja |
| faktor_ohne_wurzel | Holt eine Quadratzahl aus der Wurzel, ohne aus ihr die Wurzel zu ziehen: … | ja |
| irrational_verwechselt | Hält Wurzeln aus Quadratzahlen oder periodische Dezimalzahlen für irrational, oder umgekehrt. | ja |
| *wurzel_gliedweise* (neu) | Zieht die Wurzel aus einer Summe Glied für Glied: √(9 + 16) als √9 + √16. | ja |

Weiterer Slug: potenzgesetz_verwechselt (passt).
Alle passen fachlich. „Arbeitet mit einer Vorstellung“ beschreibt aber das Denken, nicht das Tun, und
„Einordnung von Zahlen“ bleibt für Eltern unklar.

**Gegenvorschlag Text:**
> Ihr Kind rechnet bei Hochzahlen und Wurzeln nach einer Regel, die dort nicht gilt, etwa 3² als 3 · 2 oder √36 als die Hälfte von 36, oder ordnet eine Zahl falsch ein, etwa √49 als Zahl, die sich nicht genau angeben lässt.

Wenn dir der Teil zu irrational_verwechselt zu lang ist: Den alten Text lassen, er ist fachlich in Ordnung.

### `rechenart_formel` (nicht freigegeben)

> Ihr Kind rechnet sauber, nimmt aber eine andere Rechenart oder Formel, als die Aufgabe verlangt, etwa Plus statt Mal oder den Umfang statt der Fläche.

| Slug | Klartext | passt? |
|---|---|---|
| falsche_operation | Es wurde eine andere Rechenart gewählt, als die Aufgabe verlangt. | ja (3,2 − 0,85 → 4,05) |
| plus_statt_mal | Es wurde addiert, wo malgenommen werden muss. | ja |
| umfang_statt_flaeche | Statt der Fläche wurde der Umfang berechnet. | ja |
| *mult_add_verwechslung* (neu) | Führt die Strichoperation als Punktoperation aus. | ja (Plus und Mal verwechselt) |
| *pfadregel_addiert* (neu) | Zählt Wahrscheinlichkeiten zusammen, wo sie malgenommen werden müssen, … | ja |

Weitere Slugs: flaeche_statt_umfang, multipliziert_statt_dividiert, oberflaeche_statt_volumen, volumen_statt_oberflaeche. Alle passen. **Text bleibt.**

### `runden` (nicht freigegeben)

> Ihr Kind rechnet richtig, rundet das Ergebnis aber anders als verlangt, schneidet Stellen nur ab oder lässt das Runden ganz weg.

| Slug | Klartext | passt? |
|---|---|---|
| abgeschnitten | Überzählige Nachkommastellen wurden einfach weggelassen. | ja |
| falsche_stelle | Es wurde auf eine andere Stelle gerundet als verlangt oder gar nicht gerundet. | ja |
| immer_aufgerundet | Es wurde aufgerundet, obwohl abgerundet werden muss. | ja |

Keine weiteren Slugs. **Text bleibt.**

---

### Für die Migration (nach deiner Durchsicht)

Nach deiner Entscheidung kommen in die Migration:
1. Neue Familien per `insert … on conflict do nothing`.
2. Umhängungen, nur wenn die alte Familie noch stimmt (`where slug = … and familie is not distinct from <alt>`).
3. Textänderungen mit `where elterntext = <Vorher-Text>`.
4. `freigegeben_am` für die bestätigten Familien, nur wo leer.

Dazu passe ich F14 in `supabase/checks/fehlbild_familien.PRUEFUNG.sql` an, falls `teilgekuerzt` eine Familie bekommt.
