# Befunde und offene Punkte: Erklärsequenzen Lineare Funktionen (E2b)

Stand 08.10.2026 (alle fünf Skills), Branch `feat/rasit-session-e2b-inhalte`. Alles ist KI-Entwurf; freigegeben wird nichts.

## Dateien

| Datei | Inhalt |
|---|---|
| `erklaer-k8-linfkt-bestand.md` / `.json` | Bestand per dbread: Thema, Reihenfolge der Skills, Aufgaben, Fehlbilder |
| `tools/erklaer-k8-linfkt/<skill>.mjs` | **Quelle** der Inhalte (Kernideen, Varianten, Bilder, Rechnungen, Checks) |
| `erklaer-k8-linfkt.json` | Erklär-Charge (erzeugt von `tools/erklaer-k8-linfkt-charge.mjs`) |
| `erklaer-k8-linfkt-checks.json`, `-checks.csv`, `-checks-snapshot.json` | Check-Aufgaben im Charge-Format von `tools/vorlauf-build.mjs` |
| `erklaer-k8-linfkt-checks-verifikation.md` | Protokoll von `verify-tasks.mjs --prefill` (Nachrechnung, Blind-Abgleich) |
| `erklaer-k8-linfkt-checks-blind.json` | Antworten des Blind-Lösers |
| `erklaer-k8-linfkt-ids.json` | feste ids (bleiben bei jedem Lauf gleich) |
| `erklaer-k8-linfkt-vorschau.html` | Vorschau wie am Tablet, Varianten nebeneinander, Prüferteil je Check |
| `erklaer-k8-linfkt-zweitpruefung.md` | Befunde der unabhängigen Zweitprüfung und was daraus wurde |

## Neu bauen

```bash
node tools/erklaer-k8-linfkt-charge.mjs                      # Quelle -> Chargen (bricht ab, wenn die Nachrechnung rot ist)
node tools/vorlauf-build.mjs docs/prefill/erklaer-k8-linfkt-checks.json 20261010132749 erklaer_k8_linfkt_checks
node tools/erklaer-build.mjs docs/prefill/erklaer-k8-linfkt.json 20261010132750 erklaer_k8_linfkt
node tools/erklaer-rechnen.mjs docs/prefill/erklaer-k8-linfkt.json
node tools/verify-tasks.mjs --prefill docs/prefill/erklaer-k8-linfkt-checks.json \
     --snapshot docs/prefill/erklaer-k8-linfkt-checks-snapshot.json \
     --blind docs/prefill/erklaer-k8-linfkt-checks-blind.json --bericht docs/prefill/erklaer-k8-linfkt-checks-verifikation.md
node tools/erklaer-vorschau.mjs docs/prefill/erklaer-k8-linfkt.json docs/prefill/erklaer-k8-linfkt-vorschau.html
python3 scripts/figures/test_koordinatensystem.py && python3 scripts/figures/pruefe_koordinatensystem.py
```

## Regeln, die das Nachrechen-Skript durchsetzt (`tools/erklaer-rechnen.mjs`)

Jede Rechnung eines Schritts stimmt exakt. Jede Zahl im Text und in den Formeln ist belegt (Rechnung, Bildpunkt, m oder b
der Geraden). Keine Zahlwörter. Jeder Bildpunkt liegt auf der Geraden, jeder Punkt im Text steht so im Bild. Fehlbilder
nur aus den known_errors der Aufgaben desselben Skills (Bestand). Jedes Fehlbild eines Checks hat eine Variante oder ist
begründet ohne. Kein Schritt nennt die Antwort eines Checks seiner Kernidee als Ergebnis; kein Schritt des Skills nennt
alle Punkte eines Checks; kein Lösungsbeispiel rechnet mit einem Punkt eines Checks. Kein Check wiederholt die Zahlen einer
Aufgabe des Themas. 2 bis `kernideen_max` Kernideen, zwei Checks je Kernidee. Steigungsdreiecke liegen auf der
Geraden, haben Platz für ihre Beschriftung und stehen nie in einer Check-Figur. Ein Bildschirm: Überschrift
≤ 50 Zeichen, Lesetext ≤ 330 Zeichen, ≤ 5 Blöcke, Sätze ≤ 16 Wörter, Du-Form, keine Mastery-Sprache.

## Offene Punkte

1. **Zwei Checks je Kernidee, die Engine liest die Stellschraube nicht.** Entscheidung Rasit 07.10.: je Kernidee zwei
   Checks, damit Runde 2 einen neuen Check bekommt (Entscheidung 18); `check_aufgaben_je_kernidee` bleibt auf 1 als
   Mindestzahl für die Freigabe in L6 (`CHECKS_JE_KERNIDEE` in `tools/erklaer-k8-linfkt-charge.mjs`, das
   Nachrechen-Skript verlangt mindestens die Stellschraube). **Offen:** Die Engine liest die Stellschraube nicht; sie
   nimmt die vorhandenen Checks reihum (`erklaer_zeigen`: `v_checks[((p_runde - 1) % cardinality(v_checks)) + 1]`,
   `supabase/migrations/20261008124414_a2_erklaer_testlauf.sql`). Ob L6 oder die Freigabe die Mindestzahl prüfen, ist
   dort zu entscheiden. Der zweite Check kommt nur nach einem falschen ersten; ist er auch falsch, folgt das Signal
   (`erklaerrunden_bis_signal` = 2), seine Fehlbilder werden nur gespeichert.
2. **Steigungsdreieck im Generator (erledigt, Entscheidung Rasit 07.10.).** `scripts/figures/koordinatensystem.py` hat den
   optionalen Parameter `steigungsdreiecke` (`[{x, y, dx, dy}]`), gezeichnet in `scripts/figures/steigungsdreieck.py`,
   geprüft in `pruefe_koordinatensystem.py` (f: Schenkel am Pixelort, Beschriftung „rüber dx“ / „hoch dy“, dazu eine
   fünfte Negativkontrolle). Ohne den Parameter ist die Ausgabe byte-gleich: 53 bestehende Koordinatensystem-Figuren
   (Prod `task_figures` per dbread und alle Chargen unter `docs/prefill/`) in beiden Themes, 106 SVGs, vorher und
   nachher derselbe sha256. Das Nachrechen-Skript prüft, dass beide Ecken auf der Geraden liegen (hoch : rüber = m),
   dass genug Platz für die Beschriftung bleibt, und dass keine Check-Figur ein Dreieck trägt (es wäre die Lösung).
   `koordinatensystem.py` (vorher 418, jetzt 429 Zeilen) und `pruefe_koordinatensystem.py` (vorher 450, jetzt 481)
   lagen schon vorher über 400 Zeilen; das Zeichnen steht deshalb in einer eigenen Datei.
3. **Ein Bild, ein Theme.** `erklaer_schritt_json` liefert je Bild eine URL (`erklaer/bilder/<hash>.svg`). Die Bilder
   sind im Theme `dunkel` gezeichnet (wie `lsa_task_assets` für die Bühne). Für hellen Grund bräuchte es eine zweite
   Datei (siehe offene-punkte-e1 12 zu Formeln).
4. **Markdown-Konvention für E2a.** Die Schritte nutzen: erste Zeile `# Überschrift`, Absätze, `> Merksatz`,
   nummerierte Schritte `1. …`, Formeln in `$…$`. Die App muss das darstellen (E2a); die Vorschau zeigt, wie es gedacht
   ist (Dummy-Klassen `.merk`, `.worked`).
5. **Formeln erst nach `tools/formeln-svg.mjs`.** Bis dahin ist `formeln` leer und `erklaer_schritt_json` liefert keine
   Formel-URLs. Deshalb gehört der Lauf direkt hinter das Einspielen (offene-punkte-e1 14).
6. **Check-Figuren brauchen den Upload.** Die beiden Checks zu Kernidee 1 haben je eine Abbildung (`task_figures`). Ohne `svg_hash`
   meldet `pruef_ausschluss` `bild_fehlt`; dann fehlt der Check auch im Testlauf und `erklaer_naechste_kernidee`
   überspringt Kernidee 1. `scripts/figures/upload_figures.py` läuft beim Einspielen (Entscheidung Rasit 07.10.: übernehme
   ich, wenn die Zugangsdaten in der Umgebung liegen, sonst führt Rasit den Befehl aus).
7. **`betrag_fehler` ohne Variante bei Steigung.** Bei einer fallenden Geraden liefern „Vorzeichen vergessen“
   (`betrag_fehler`) und „Reihenfolge gemischt“ (`seiten_verwechselt`) denselben falschen Wert; `known_errors` kann ihm
   nur einen Slug geben. Der Check zu Kernidee 2 nimmt deshalb eine steigende Gerade, dort ist `seiten_verwechselt`
   eindeutig. `betrag_fehler` (1 Steigungs-Aufgabe im Bestand) hat bei Steigung keine eigene Variante; Variante B
   („Passt das Vorzeichen?“) spricht das Vorzeichen trotzdem an.
8. **„Häufig“ heißt hier: in vielen Aufgaben hinterlegt.** `lsa_responses` hat zu den `fkt_linear_*`-Skills keine
   Antwort mit Fehlbild (Bestand). Sobald Antworten da sind, die Varianten an der echten Häufigkeit prüfen.
9. **Nicht freigegebene Fehlbild-Labels.** `steigung_kehrwert` und `nur_einmal_addiert` haben kein `freigegeben_am`
   (Bestand). Die Variantenwahl hängt nicht daran; der Klartext ist für Lena aber noch ungeprüft.
10. **Checks erscheinen im Lena-Board.** `pruef_board` filtert nicht auf Einsatz. Die drei Check-Aufgaben stehen dort
    neben den sechs Aufgaben von `fkt_linear_steigung` (Titel beginnt mit „Check ·“). So prüft Lena sie wie jede
    Aufgabe (E0, Frage 5); Erklärschritte prüft sie in L6.
11. **`verify-tasks --prefill --migration`** meldet bei Chargen neuer Aufgaben „Anweisung ohne VERA8-Ausschluss“; das
    Gate ist für Prefill-Updates gebaut. Gegenprobe: `k8-lgs` meldet mit `--migration` 36 solche Fehler, ohne 0. Wie bei
    allen bisherigen Chargen neuer Aufgaben läuft die Prüfung ohne `--migration`; VERA8 fasst die Migration nicht an
    (nur `insert` mit eigener `source`).
12. **Testisolation in zwei fremden Tests.** `session_e1_fixture.sql` legte Kernideen 1–3 für `fkt_linear_steigung` an
    und kollidierte mit den echten Entwürfen (unique `skill_key, nr`); `inv10_lsa_thema_auswahl.test.sql` löscht alle
    Skills und scheiterte am Fremdschlüssel `erklaer_kernidee_skill_key_fkey`. Beide bekommen eine Löschzeile in ihrer
    zurückgerollten Transaktion; sonst keine Änderung.
13. **Längenregel ist eine Näherung.** Die Grenzen (50 / 330 Zeichen, 16 Wörter) und der 1194 × 834-Rahmen der Vorschau
    stammen aus dem Schüler-Dummy (`.seq`, Schriftgrößen). Ob es in der echten App ohne Scrollen passt, zeigt erst E2a.
14. **Versionen.** Der Bereich 20261010130000–135959 ist vorgegeben; innerhalb des Bereichs stehen Minute und Sekunde
    der Erzeugung (`date -u`). Per dbread am 08.10. geprüft: `20261010132749` und `20261010132750` sind frei; in Prod
    stehen inzwischen 14 andere Versionen `20261010%` (A2c, A2d, C2, L6, alle vor 1213). Vor dem Einspielen erneut prüfen.
15. **Klartext von `b_ignoriert` passt nicht zur Steigung.** Der Katalog beschreibt „Teilt sofort, ohne die Konstante
    vorher wegzurechnen“ (Gleichungen). Bei Steigung steht der Slug im Bestand für „wie bei einer Ursprungsgeraden
    gerechnet“ (`linfkt-steigung-06`, Wert 8). Variante C von Kernidee 3 spricht diesen Fehler an. Einen eigenen Slug
    oder einen allgemeineren Klartext legt Lena im Fehlbild-Katalog fest (Zweitprüfung Befund 1). Dasselbe gilt bei
    `fkt_linear_gleichung` (Bestand `linfkt-gleichung-05`: 6 = 0,30 · 20, „Grundgebühr vergessen“), Variante K3 B.
16. **Kein Fehlbild für Zählfehler am Gitter.** Die Zweitprüfung wünscht eine Variante für Zählfehler über die Achse
    (Befund 10). Der Bestand kennt dafür keinen Slug; ohne Slug wählt die Engine die nächste ungezeigte Variante.
17. **Punktnamen im Bild.** Der Generator setzt Namen über den Punkt (mit Steigungsdreieck von oben: darunter). Liegen
    Punkte auf der y-Achse oder an Achsenzahlen, wird es eng (Zweitprüfung Runde 2, Befund 6, „kann“). Eine Regel
    „Name auf die von der Geraden abgewandte Seite“ wäre eine weitere Generator-Änderung; bewusst nicht in diesem Schritt.
    Die Zweitprüfungen von y-Abschnitt und Gleichung melden dasselbe: S auf der y-Achse verdeckt die Achsenzahl an seiner
    Stelle, Namen liegen auf steilen Geraden („kann“).
18. **Varianten nur über den ersten Check erreichbar (R15).** `erklaer_zeigen` gibt in Runde 1 immer den ersten Check;
    eine Variante folgt nur auf einen falschen Check in Runde 1, in Runde 2 folgt das Signal. Ein Fehlbild, das nur im
    zweiten Check steht, wählt deshalb nie eine Variante. Das Nachrechen-Skript verlangt jetzt für jede Variante B/C ein
    Fehlbild des ersten Checks; bei Gleichung K2 und K3 wurden die Checks dafür umgestellt (Zweitprüfung Gleichung).
19. **„hoch -4“ statt „runter 4“.** Der Generator beschriftet fallende Dreiecke mit „hoch“ und negativem Wert, wie im
    abgenommenen Muster („Hoch: -1 - 5 = -6“). Die Zweitprüfung y-Abschnitt findet „hoch -4“ holprig. Eine Beschriftung
    „runter 4“ wäre eine Generator-Änderung mit neuer Byte-Gleichheitsprüfung; die Texte sagen dazu „nach unten“.
20. **Keine Ablese-Hilfslinien.** Beim Ablesen von Punkten (Graph K2) würden gestrichelte Linien von der Achse zum
    Punkt helfen (Zweitprüfung Graph Nr. 8). Der Generator hat sie nicht; die Texte beschreiben den Weg in Worten.
21. **L6: Merksatz „>“ nicht als Merksatz erkennbar.** Bildschirmfoto der Prüfseite (Coach-Route
    `/coach/pruefen/erklaerungen/:id`, Kinderansicht `ErklaerKindSchritt`) mit Daten aus der Wegwerf-DB
    (`erklaer_pruef_detail` als Admin, fiktive Profile, kein Prod): „#“ erscheint als Überschrift, „1.“ als
    nummerierte Liste, beides lesbar. „>“ wird als `<blockquote>` ohne eigene Gestaltung gezeigt (kein Rand, kein
    Einzug), sieht also aus wie ein normaler Absatz; lesbar, aber Lena erkennt den Merksatz nicht. `TEILE` in
    `ErklaerKindSchritt.tsx` hat für `blockquote` keinen Eintrag. Offener Punkt für L6, hier nicht geändert.
22. **L6: dunkle Bilder auf weißer Karte.** Dieselbe Kinderansicht zeigt das Bild (Theme `dunkel`, offener Punkt 3)
    auf heller Kartenfläche: Gitter und Achsen sind kaum zu sehen, nur Gerade und Dreieck. Für Lenas Prüfung
    braucht L6 entweder einen dunklen Bildgrund oder eine helle Bildfassung. Offener Punkt für L6.
