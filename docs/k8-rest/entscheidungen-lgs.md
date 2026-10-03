# K8-Rest · Thema 1 Lineare Gleichungssysteme (`lgs`) – Entscheidungen

Stand 03.10.2026 · Grundlage `docs/k8-rest/phase1.md` · Graph live gelesen über `~/bin/dbread`.
Dateien: `supabase/migrations/20261003104943_substrat_k8_lgs.sql`,
`supabase/migrations/20261003104947_aufgaben_k8_lgs.sql` (erzeugt), `tools/k8-lgs-aufgaben.mjs`,
`tools/k8-lgs-aufgaben-2.mjs`, `tools/k8-lgs-charge.mjs`, `docs/prefill/k8-lgs*`,
`supabase/checks/k8_lgs_{substrat,aufgaben}.PRUEFUNG.sql`.

## Knotenschnitt und Tiefen

Fünf Knoten nach dem Vorschlag des Hubs (`gleichung_lgs_*`, Klasse 8):

| skill_key | Tiefe | direkte Voraussetzungen |
|---|---|---|
| `gleichung_lgs_einsetzen` | 7 | `term_minusklammer` (6), `gleichung_zweischrittig` (6), `term_einsetzen` (5) |
| `gleichung_lgs_gleichsetzen` | 8 | `gleichung_beidseitig` (7), `gleichung_neg_koeffizient` (7), `term_einsetzen` (5) |
| `gleichung_lgs_addition` | 8 | `gleichung_neg_koeffizient` (7), `term_ausmultiplizieren` (5), `term_einsetzen` (5) |
| `gleichung_lgs_grafisch` | 8 | `fkt_linear_graph` (7) |
| `gleichung_lgs_sachaufgabe` | 9 | `gleichung_modellieren` (8), `gleichung_lgs_einsetzen` (7), `gleichung_lgs_addition` (8) |

13 Kanten. Die Lösbarkeit (keine / unendlich viele Lösungen) ist **kein eigener Knoten**: Sie zeigt sich
in jedem Verfahren am Ende der Rechnung (0 = 5, 0 = 0) und grafisch an der Lage der Geraden. Ein
eigener Knoten hätte nur MC-Aufgaben und keine Zahlantworten tragen können.

## Kanten: gesetzt und weggelassen

- **Gesetzt, über den Hub-Vorschlag hinaus: `term_einsetzen` bei den drei Rechenverfahren.** Das
  Rückeinsetzen des ersten Werts ist der zweite Teil jedes Verfahrens. `term_einsetzen` ist von keiner
  anderen Voraussetzung aus erreichbar (geprüft: `term_minusklammer → term_ausmultiplizieren →
  term_zusammenfassen/vorzeichen_mult_div`, `gleichung_zweischrittig → gleichung_einschrittig →
  dezimal_div/vorzeichen_add_sub`, `gleichung_neg_koeffizient → gleichung_zweischrittig/vorzeichen_mult_div`).
- **Addition: `term_ausmultiplizieren` statt der „…“ im Vorschlag.** Eine Gleichung mit einem Faktor
  multiplizieren heißt, jedes Glied auszumultiplizieren (Fehlbild `nicht_alle_glieder_multipliziert`).
  `term_zusammenfassen` hängt darunter und ist deshalb nicht direkt gesetzt.
- **Weggelassen, weil transitiv:** `term_ausmultiplizieren`/`term_zusammenfassen` bei einsetzen (unter
  `term_minusklammer`), `gleichung_zweischrittig`/`vorzeichen_mult_div` bei gleichsetzen und addition
  (unter `gleichung_neg_koeffizient`/`gleichung_beidseitig`), `fkt_linear_steigung`,
  `fkt_linear_yabschnitt`, `geo_koordinaten` bei grafisch (unter `fkt_linear_graph`).
- **Weggelassen: `sachaufgabe → gleichsetzen`.** Gleichsetzen ist der Sonderfall des Einsetzens; die
  Sachaufgaben verlangen Einsetzen oder Addieren. Sach-04 (Tarife) wird gleichgesetzt, das ist mit
  der Kante zu einsetzen abgedeckt.
- **`einsetzen` ohne `gleichung_neg_koeffizient`:** beide Tiefe 7, eine Kante wäre nicht echt flacher.
  Die Einsetzen-Aufgaben vermeiden deshalb die Division durch einen negativen Koeffizienten als Kern;
  nur Einsetzen-04 hat im Musterweg `-10y = -30` (alternativ `33 - 3 = 10y`). Siehe Befunde.
- `fkt_linear_graph` ist ein Draft des Linear-Laufs; nur die Kante zeigt dorthin, dessen Aufgaben
  bleiben unberührt.

## Fehlbilder

Neu (phase1 d), Text wörtlich, Familie `gleichungen_umformen`, `freigegeben_am` NULL):
`nicht_alle_glieder_multipliziert` (4 Aufgaben), `seiten_ungleich_verknuepft` (5),
`loesungsanzahl_verwechselt` (4), `parallele_uebersehen` (4).

Wiederverwendet (nicht angefasst): aus der LGS-Liste `klammer_vergessen` (6), `division_vergessen` (7),
`vorzeichen_beim_umstellen` (5), `variablen_nicht_zusammengefuehrt` (5),
`falsches_vorzeichen_beim_zusammenfuehren` (3), `groessen_vertauscht` (8), `koordinaten_vertauscht` (4),
`bedingung_unvollstaendig` (2). `vorzeichen_ignoriert` kommt nicht vor (kein Fehler in den Aufgaben,
der sauber dazu passt). Zusätzlich aus dem Bestand, weil der Klartext genau passt:
- `falsche_groesse_beantwortet` (Einsetzen-02: y statt x angegeben, Rückeinsetzen fehlt),
- `koordinate_vorzeichen_verloren` (Grafisch-03: Schnittpunkt im dritten Quadranten ohne Minus),
- `klammer_falsch_gesetzt` (Sach-03: „3(x + y) = 26“ statt „3x + y = 26“),
- `umfang_falsch_modelliert` (Sach-06: Umfang mit zwei statt vier Seiten).
Alle vier existieren in Prod und lokal (Vorlauf-Substrate).

## Antwortformate

- **Lösungen als MULTI_PART** mit `short_input`-Teilen, Teil 1 = x, Teil 2 = y, `known_errors` je Teil.
  Jeder Teil hat mindestens ein Fehlbild. Schreibweisen über `formen` wie im Linear-Lauf (Komma/Punkt,
  `-`/`−`/`- `, `+` bei positiven Werten, Einheit mit/ohne Leerzeichen). Keine Tausenderpunkte.
- **Lösungsanzahl als MC** (vier Aufgaben, je eine bei gleichsetzen und addition, zwei bei grafisch),
  Optionen einheitlich `a` genau eine / `b` keine / `c` unendlich viele Lösungen. Falsche Option
  „genau eine“ → `parallele_uebersehen`, vertauschter Sonderfall → `loesungsanzahl_verwechselt`.
  Zwei Fälle „keine Lösung“ (gleiche Stundenpreise, parallele Geraden im Bild), zwei „unendlich viele“
  (Vielfaches im Sachkontext, `2y = x + 2`).
- **Sachknoten:** vier Aufgaben MULTI_PART **mc | x | y** (Muster `gleichung_modellieren`: Teil 1
  „Welches Gleichungssystem passt?“ mit drei Systemen als Optionen, jede falsche Option mit Slug),
  zwei Aufgaben (AFB III) nur **x | y**, System selbst aufstellen. **Abweichung von phase1 e)**
  („Teil 1 = x, Teil 2 = y“): mit MC-Teil sind x und y Teil 2 und 3.
- Die Charge prüft jede Gleichung exakt: Zerlegung in a·x + b·y = c, Cramer für x und y, Determinante
  und Verträglichkeit für die MC-Antwort, Koeffizientenvergleich für die richtige Systemoption (jede
  andere Option muss ungleichwertig sein), bei Figuren: `gl` beschreibt genau die gezeichneten Geraden.
- Zeit: AFB-Regel + 30 s Sachkontext; `zeit_teile` = MC-Teil 30 s, y-Teil 15 s, Rest x-Teil.
- `competency_process`: Operieren (Verfahren), Darstellen (Ablesen), Argumentieren (Lösungsanzahl),
  Problemlösen (Faktor selbst finden, Addition-04), Modellieren (Sachkontexte).

## Aufgabenzuschnitt je Knoten

| Knoten | 1–4 (Anwendung) | 5–6 (Kontext/Deutung) |
|---|---|---|
| einsetzen | y frei + Klammer (I), x frei (I), Minusklammer (II), erst umstellen (II) | Kinokarten (II), Zahlenrätsel (II) |
| gleichsetzen | beide nach y (I, I), negativer Koeffizient (II), erst umstellen (II) | Fahrradverleih (II), Kletterpark gleiche Stundenpreise → MC keine (II) |
| addition | direkt (I, I), mal Faktor (II), Faktor selbst (II) | Museum (II), Hefte/Stifte Vielfaches → MC unendlich viele (II) |
| grafisch | 1. Quadrant (I, I), 3. Quadrant (II), MC `2y = x + 2` ohne Bild (II) | Kanuverleih mit Bild (II), parallele Geraden im Bild → MC (II) |
| sachaufgabe | Schwimmbad, Kaffeemischung, Zahlenrätsel, Taxi (je mc + x + y, II) | Zoo, Beet (selbst aufstellen, III) |

Keine Personen, keine Marken („Ein Kino“, „Eine Rösterei“, „Zwei Taxiunternehmen“). „2 Erwachsene und
3 Kinder“ bezeichnet Ticketgruppen, keine Personen mit Namen.

## Figuren

Ja, fünf Aufgaben (`koordinatensystem`, zwei Geraden `f`, `g`): Schnittpunkte (2 | 3), (4 | 1),
(-2 | -1), (4 | 6) auf Gitterpunkten, mindestens eine Einheit vom Fensterrand, |m| ≤ 2 (prüft die
Charge). Grafisch-04 (Geraden aufeinander) ohne Bild: Zwei identische Geraden wären im Bild nicht
unterscheidbar. PNGs mit `exportiere.mjs` gerendert und angesehen: alles ablesbar. Grafisch-01 wurde
danach geändert (g: y = -0,5x + 4 statt y = -x + 5), weil das Label g auf dem Achsentitel x lag.
`alt_text` ohne Ziffern und ohne Hinweis auf die Lage (parallel) der Geraden.

## Offene Punkte / Befunde

1. **Sondierrang Rang 2 landet bei gleichsetzen, addition und grafisch auf einer MC-Aufgabe**
   (Profil {loesungsanzahl_verwechselt, parallele_uebersehen}, weil es die meisten neuen Slugs bringt).
   Algorithmisch korrekt; ob eine Sonderfall-MC-Aufgabe als zweite Sondieraufgabe gewollt ist, sollte
   Lena entscheiden. Bei MC rät ein Kind mit Wahrscheinlichkeit 1/3 richtig.
2. **Einsetzen-04** enthält im Musterweg die Division durch -10 (`gleichung_neg_koeffizient` ist
   gleich tief und kann keine Kante sein). Der Fehler `vorzeichen_beim_umstellen` bleibt erkennbar;
   der Abstieg führt dann über `gleichung_zweischrittig`, nicht direkt zum negativen Koeffizienten.
3. Manche Fehlbild-Werte sind im Kontext unplausibel (Sach-01: -70 Karten, Addition-05: -14 €). Sie sind
   genau das, was der modellierte Fehler ergibt; die sokratische Frage greift die Unplausibilität auf.
4. Mehrdeutige Fehlerwerte bewusst vermieden: Wo zwei Fehler dieselben Zahlen ergeben hätten
   (x + y = s, x − y = d: Seitenfehler = Vertauschung), wurden andere Zahlen gewählt (Sach-03, Addition-01).
5. `lsa_grade` wird für MC und mc-Teile nicht geprüft (binär über `lsa_is_correct`).
6. Gegen Prod laufen beide Prüfskripte fehlerfrei; ohne eingespielte Daten sind die Zeilen `f` oder
   leer (NULL bei leeren Mengen), nur die bestandsunabhängigen Zeilen sind `t`.
7. Die erzeugte Aufgaben-Migration hat 1274 Zeilen (generiert, nicht von Hand; wie Linear/Kreis).
8. Blind-Lösung (Stufe 2, Hub): frischer Subagent, 30/30 = 100 %, 0 unsicher, alle fünf Figuren
   ablesbar → `docs/prefill/k8-lgs-blind.json`.
