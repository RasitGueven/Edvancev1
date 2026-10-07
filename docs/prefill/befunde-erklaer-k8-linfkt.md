# Befunde und offene Punkte: Erklärsequenzen Lineare Funktionen (E2b)

Stand 07.10.2026, Branch `feat/rasit-session-e2b-inhalte`. Alles ist KI-Entwurf; freigegeben wird nichts.

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
```

## Regeln, die das Nachrechen-Skript durchsetzt (`tools/erklaer-rechnen.mjs`)

Jede Rechnung eines Schritts stimmt exakt. Jede Zahl im Text und in den Formeln ist belegt (Rechnung, Bildpunkt, m oder b
der Geraden). Keine Zahlwörter. Jeder Bildpunkt liegt auf der Geraden, jeder Punkt im Text steht so im Bild. Fehlbilder
nur aus den known_errors der Aufgaben desselben Skills (Bestand). Jedes Fehlbild eines Checks hat eine Variante oder ist
begründet ohne. Kein Schritt nennt die Antwort eines Checks seiner Kernidee als Ergebnis; kein Schritt des Skills nennt
alle Punkte eines Checks; kein Lösungsbeispiel rechnet mit einem Punkt eines Checks. Kein Check wiederholt die Zahlen einer
Aufgabe des Themas. 2 bis `kernideen_max` Kernideen, `check_aufgaben_je_kernidee` Checks. Ein Bildschirm: Überschrift
≤ 50 Zeichen, Lesetext ≤ 330 Zeichen, ≤ 5 Blöcke, Sätze ≤ 16 Wörter, Du-Form, keine Mastery-Sprache.

## Offene Punkte

1. **Ein Check je Kernidee heißt: in Runde 2 derselbe Check.** `check_aufgaben_je_kernidee` steht in Prod auf 1 (dbread).
   Die Engine liest die Stellschraube nicht, sie nimmt reihum die vorhandenen Checks
   (`erklaer_zeigen`: `v_checks[((p_runde - 1) % cardinality(v_checks)) + 1]`,
   `supabase/migrations/20261008124414_a2_erklaer_testlauf.sql`). Mit einem Check sieht das Kind nach Variante B
   dieselbe Aufgabe noch einmal; Entscheidung 18 sagt „dann ein neuer Check“. **Frage an Rasit:** 2 Checks je Kernidee
   (Spanne 1–3)? Das Werkzeug kann das ohne Umbau (Stellschraube in `tools/erklaer-k8-linfkt-charge.mjs`).
2. **Kein Steigungsdreieck im Bild.** Der Generator `koordinatensystem` zeichnet Geraden und Punkte, aber keine Dreiecke
   oder Pfeile (`scripts/figures/pruefungen.py`: erlaubte Schlüssel). Der Schüler-Dummy zeigt eins. Die Bilder hier
   zeigen die zwei Punkte mit Buchstaben; „hoch“ und „rüber“ stehen im Text. Eine Erweiterung des Generators gehört nicht
   in E2b (nur Daten und tools/).
3. **Ein Bild, ein Theme.** `erklaer_schritt_json` liefert je Bild eine URL (`erklaer/bilder/<hash>.svg`). Die Bilder
   sind im Theme `dunkel` gezeichnet (wie `lsa_task_assets` für die Bühne). Für hellen Grund bräuchte es eine zweite
   Datei (siehe offene-punkte-e1 12 zu Formeln).
4. **Markdown-Konvention für E2a.** Die Schritte nutzen: erste Zeile `# Überschrift`, Absätze, `> Merksatz`,
   nummerierte Schritte `1. …`, Formeln in `$…$`. Die App muss das darstellen (E2a); die Vorschau zeigt, wie es gedacht
   ist (Dummy-Klassen `.merk`, `.worked`).
5. **Formeln erst nach `tools/formeln-svg.mjs`.** Bis dahin ist `formeln` leer und `erklaer_schritt_json` liefert keine
   Formel-URLs. Deshalb gehört der Lauf direkt hinter das Einspielen (offene-punkte-e1 14).
6. **Check-Figur braucht den Upload.** Der Check zu Kernidee 1 hat eine Abbildung (`task_figures`). Ohne `svg_hash`
   meldet `pruef_ausschluss` `bild_fehlt`; dann fehlt der Check auch im Testlauf und `erklaer_naechste_kernidee`
   überspringt Kernidee 1. `scripts/figures/upload_figures.py` muss nach dem Einspielen laufen (laut Kopf von Rasit).
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
    der Erzeugung (`date -u`). Vor dem Einspielen per dbread geprüft: keine Version `20261010%` in Prod.
15. **Klartext von `b_ignoriert` passt nicht zur Steigung.** Der Katalog beschreibt „Teilt sofort, ohne die Konstante
    vorher wegzurechnen“ (Gleichungen). Bei Steigung steht der Slug im Bestand für „wie bei einer Ursprungsgeraden
    gerechnet“ (`linfkt-steigung-06`, Wert 8). Variante C von Kernidee 3 spricht diesen Fehler an. Einen eigenen Slug
    oder einen allgemeineren Klartext legt Lena im Fehlbild-Katalog fest (Zweitprüfung Befund 1).
16. **Kein Fehlbild für Zählfehler am Gitter.** Die Zweitprüfung wünscht eine Variante für Zählfehler über die Achse
    (Befund 10). Der Bestand kennt dafür keinen Slug; ohne Slug wählt die Engine die nächste ungezeigte Variante.
