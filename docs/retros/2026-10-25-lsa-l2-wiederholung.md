# Retro LSA-L2 · Batus Pool, keine Fast-Duplikate, Vorschau auf drei Klassenarbeiten (25.10.2026)

Bauauftrag `docs/lsa/Bauauftrag-L2.md` (Freigabe Rasit für Einspielen und Merge). Branch
`feat/rasit-lsa-l2-batu-pool`, Migration `20261025144025_lsa_l2_wiederholung`.

## Gebaut

- **Messung (Schritt 1):** `tools/lsa-testkinder/l2-gruppen.sql` bildet die Bereiche je Gruppe (Thema, KA2–KA4 mit
  Rand/Tiefe der Vorschau und den Signal-Voraussetzungen des Berichts, Grundlage, Rückblick, Ausblick);
  `l2-pool.sql` zählt den echten Pool je Bereich und sucht Fast-Duplikate. Ergebnis `docs/lsa/l2-batu-pool.md`.
- **Testkind Batu** (Profil aus seinem Testlauf, ohne IDs) und eine Simulation mit genau dem freigegebenen
  Prod-Pool (`l2-pool-fixture.sql`, `l2-fixture.sql`). `simulation.sh` kann jetzt Pools und Varianten und rechnet
  mit festen Sitzungs- und Aufgaben-ids — vorher/nachher zeigt nur noch die Änderung, nicht den md5-Zufall.
- **Migration:** `lsa_text_schluessel` (immutable), `lsa_ausgegebene_schluessel`; `lsa_freie_aufgabe` und
  Schritt 5 schließen Fast-Duplikate schon ausgegebener Aufgaben aus; bleiben für einen Zweitbeleg nur solche,
  entfällt er. `c_vorschau_themen` 2 → 3. Rollback stellt die Vorgänger textgleich her (lokal geprüft).
- **Tests:** `lsa_l2_wiederholung` (19), Batu in `lsa_testkinder`, eindeutige Texte in sechs bestehenden Fixtures,
  `lsa_v_vorschau` auf drei kommende Themen.
- **Freigabeliste für Lena:** `docs/lsa/freigabeliste-batu-1025.md`.

## Entscheidungen

- **Fast-Duplikat über die ganze Sitzung**, nicht nur je Skill (Regel A wörtlich). Im freien Pool gibt es über
  Skills hinweg heute keine gleichen Texte; der Unterschied zeigt sich nur in Test-Fixtures, die überall
  „Wie viel ist 2 + 3?“ benutzten — die bekamen eindeutige Texte.
- **Kein Index, keine Spalte:** `lsa_select_next_core` höchstens 6,3 ms (vorher 6,0).
- **C auf 3:** Bedingungen erfüllt (Themenraum gleich, ≤ 40, keine Verlängerung). Batu selbst gewinnt nichts, weil
  seine KA4-Voraussetzungen mitbelegt sind; ehrlich im Simulationsbericht vermerkt.
- **Migration über 400 Zeilen** (605): Sie muss `lsa_select_next_core` vollständig ersetzen; wie bei LSA-V/V2.

## Zweitprüfung

Frischer Subagent, liest Migration, Rollback, Vorgänger, Simulation und Test: **kein Verstoß gegen A–C.** A greift an
beiden Stellen, die `lsa_ausgegeben` ausschließen (alle Phasen über `lsa_freie_aufgabe`, Schritt 5); B ist durch
das Urteilsmodell garantiert; C ist die einzige Änderung an der Konstante; Migration und Rollback sind außerhalb der
LSA-L2-Stellen textgleich mit den Vorgängern. Umgesetzt aus den Befunden:

- **Aufgaben ohne Text** hätten alle denselben Schlüssel (`md5('')`) und sich gegenseitig ausgeschlossen, auch über
  Skills hinweg → leerer Text gibt jetzt keinen Schlüssel (`null` gleicht nichts). Test g.
- **Zweitbeleg nach MC richtig** mit nur Fast-Duplikaten → Test h (`traegt/1/final`).
- Zahl im Simulationsbericht korrigiert (134 freie Aufgaben zur Messung, nicht 136).

Bewusst so gelassen und zu wissen:

- In Skills, deren freie Aufgaben **alle** eine Fast-Duplikat-Gruppe bilden (etwa `bruch_dezimal`, `bruch_kuerzen`,
  `dezimal_*`, `gleichung_beidseitig`, `gleichung_zweischrittig`, `term_zusammenfassen`), entscheidet jetzt eine
  einzige falsche Antwort final `traegt_nicht` — so verlangt es die Ausnahme zu A. Abhilfe ist Inhalt (Lena): je
  Skill eine zweite, anders formulierte Aufgabe.
- Gleicher Rahmentext mit Inhalt nur in Payload oder Bild gilt als Fast-Duplikat; heute 0 Fälle im Pool.
- Unicode-Minus, geschütztes Leerzeichen und Vorzeichen werden nicht angeglichen (es entgehen höchstens Duplikate).
- `lsa_start` im Altmodus `fest` zieht zufällig ohne Auswahl (Standard ist adaptiv).
- „Ende spätestens 19 Minuten“ ist als „letzte Aufgabe vor Minute 19, keine Verlängerung durch C“ ausgelegt;
  Jonas (110 s je Antwort) endet in allen Ständen bei 20:56.
- Schritt 5 (ohne Thema) mit Fast-Duplikat ist nicht eigens getestet (schwer gezielt zu erreichen).

## Offen

- **Pool:** Mit dem echten Pool endet Batus LSA nach 20 Aufgaben bei 11:35 — der Rückblick (15 Bereiche Klasse
  7/8) und der Ausblick haben keine freie Aufgabe. `term_binom_quadrat` hat nur MC frei. Liste für Lena.
- **Mitbelegung vs. direkter Beleg:** KA4 (Potenzen) bleibt bei Batu ohne direkten Beleg, weil beide
  Voraussetzungen mitbelegt sind. Ob der Bericht für das Signal einen direkten Beleg braucht, ist eine
  Report-Frage (V4).
- **`gleichung_quadr_formel`** bestimmt das KA2-Signal im Bericht, die LSA prüft ihn aber nie (Thema Klasse 10,
  ersetzt durch seinen Rand). Abgleich Bericht ↔ Auswahl in der V4-Session.
- **`VORSCHAU_THEMEN = 2`** in `src/lib/report/elternbericht/vorgriff.ts` (Report-Code, V4-Session) — ohne Wirkung
  auf Berichte (Randknoten sind nie Vorgriffe), beim nächsten Report-Paket auf 3 angleichen.
- **Feld-Läufe (e):** fünf Aufgaben desselben Felds hintereinander kommen vor (Thema, Vorschau KA2). Keine Regel
  dafür beauftragt.
- **Lokale Testumgebung:** pgTAP gibt es lokal nur als geladene SQL-Datei; `session_x0` ist lokal auf dev rot.
