# Szenario „Batu“: LSA-Muster und Erwartung für die erste Session

Stand 08.10.2026 · Paket F1, Umfang B2 · **Entwurf, wartet auf „Muster Batu ok“** · Maschinenlesbar: `batu.json`

Belege: dbread 08.10.2026, Abfragen unter `/tmp/claude-1000/f1/b1/` und `/tmp/claude-1000/f1/b2*.sql`;
Funktionen aus `supabase/schema-erwartet.sql` (Stand Prod).

## 0. Vor der Abnahme zu entscheiden

Drei Befunde aus B1 betreffen das Werkzeug (B3). Sie gehören vor das Muster, weil sie bestimmen, ob das Muster
überhaupt so ankommen kann.

**E1 Testkind.** Es gibt kein Testkind, das alle Bedingungen erfüllt:
- Klasse 9 gibt es 5 Testkinder (`students.ist_test`), davon 4 mit laufendem Vertrag. Alle 5 haben einen leeren Lernpfad.
- **Kein Lead in Prod hat `ist_test = true`** (0 von allen). „An einem Testlead“ erfüllt also niemand.
- Am nächsten kommt **TESTLEAD Zweitmann** (`5737b689…`): Vertrag aktiv bis 30.04.2027, keine LSA, kein Thema, keine
  Buchung. Lead `converted`, Klasse 9, `ist_test = false`.
- Das provisorische Kind „Batu Demirel“ hat keinen Vertrag und kein Profil. Es kommt nicht in Frage (kein Vertrag bauen).
- **Vorschlag:** Zweitmann spielt „Batu“. Dass sein Lead kein Testlead ist, stört keine der Funktionen auf dem Weg
  (`lsa_start` prüft im Testlauf nur `students.ist_test`; ohne Testlauf gar nichts dazu). Den Lead als Test markieren
  wäre eine Datenänderung, die ich nicht vornehme.

**E2 LSA-Weg (Blocker).** Der verlangte Weg „echte LSA, nicht als Testlauf, damit Lernpfad und Report entstehen“ geht
mit dem Bestand nicht:
- **Ohne Testlauf ist der Pool leer.** `lsa_im_pool(task, false)` verlangt `status = 'ready'`. Von den 22 Skills des
  Szenarios (Wurzel-Thema, seine Fundamente, quadratische Themen) ist **kein einziges Item `ready`**, alle sind `draft`
  (dbread). `lsa_start` fände in Phase T nichts.
- **Im Testlauf entsteht kein Lernpfad.** `lernpfad_lsa_urteile` filtert Testlauf-LSAs heraus. Darauf bauen
  `lernpfad_aus_lsa` (Lernpfad) und `session_sichere_skills` (Warm-up) auf. `lsa_uebernahme` wirft bei einem Testlauf
  einen Fehler. Ein Testlauf-LSA erzeugt nur den Report (`lsa_finish` → `result_summary`).
- Optionen (Entscheidung Rasit):
  - **A (Vorschlag):** Testkonten (`students.ist_test`) bekommen auch außerhalb eines Testlaufs den Testlauf-Pool
    (`lsa_im_pool`: Entwürfe ohne `pruef_ausschluss`).
    - Das ist eine Migration an der LSA-Auswahl, gilt aber nur für Testkonten. Echte Kinder sehen weiter nur `ready`.
    - Entscheidung 27 bleibt unberührt: Diese LSA ist kein Testlauf, sie hinterlässt bewusst Spuren am Testkonto.
    - Danach laufen `lsa_start`, `lsa_submit`, `lsa_finish` und `lernpfad_aus_lsa` unverändert.
  - **B:** Testlauf-LSA. Dazu ein eigener Admin-Schritt „Szenario übernehmen“, der für Testkonten auch
    Testlauf-Urteile in den Lernpfad schreibt. Das weicht die Testlauf-Regel auf, deshalb nicht empfohlen.
  - **C:** Die Items der beteiligten Skills werden `ready` gesetzt. Das ist Inhaltsarbeit und kein Teil von F1.
- Direkt in `lsa_skill_urteil` oder `lernpfad` zu schreiben, schließe ich aus: Dafür gibt es Funktionen.

**E3 Warm-up (Befund, Engine unverändert).** Mit diesem Muster kommt im Warm-up **nicht** die Wurzel, sondern
„Dezimalzahlen addieren/subtrahieren“ (Klasse 5). Die Herleitung steht unter 3. Ursache ist die Reihenfolge in
`session_plan_warmup`:
- Unter den sicheren Voraussetzungen gibt es keinen Vorrang für direkt belegte oder zielnahe Skills.
- Bei Gleichstand entscheidet der `skill_key`, also das Alphabet.
- Die Mitbelegung (`lsa_mitbelegung`) macht mit „Wurzel ziehen trägt“ auch alle Fundamente darunter sicher.

Die Engine darf ich laut Auftrag nur ändern, wenn A6 einen Fehler belegt; das tut A6 nicht. Optionen:
- **(i)** so lassen und im Ablauf (B5) ehrlich beschreiben;
- **(ii)** Folgepaket: Tie-Break im Warm-up, zum Beispiel direkt belegte Skills vor mitbelegten und höhere
  `fundament_tiefe` zuerst;
- **(iii)** Freigabe für (ii) schon in F1, mit Test vorher rot und nachher grün.

## 1. Lage des Kindes

| | |
|---|---|
| Kind | „Batu“ = TESTLEAD Zweitmann (E1), Klasse 9, Lernpfad leer |
| Schulthema vor der LSA | `reelle_zahlen` „Reelle Zahlen und Wurzeln“ (setzt das Werkzeug über `lead_thema_setzen`) |
| LSA | adaptiv (Option B, `lsa_select_next_core`): Phase T auf den Einstiegen, dann Tiefe unter gebrochenen Knoten |
| Thema der ersten Session | `quadratische_gleichungen` (der Coach wählt es über die Oberfläche aus A1) |
| Wurzel als Voraussetzung | `gleichung_quadr_wurzel → zahl_wurzel_quadrat` direkt. Einstieg `gleichung_quadr_formel` über 2 Stufen, `fkt_quadr_nullstellen` über 3 (dbread) |

Themenraum `reelle_zahlen`:
- Einstiege: `zahl_wurzel_irrational`, `zahl_wurzel_naeherung`, `zahl_wurzel_teilweise`.
- Darunter: `zahl_wurzel_gesetze` und `zahl_wurzel_quadrat` (beide Klasse 9) sowie Fundamente aus Klasse 5 bis 7.

Die für das Muster wichtigen Kanten:

```
zahl_wurzel_teilweise  → zahl_wurzel_gesetze → zahl_wurzel_quadrat → potenzen → dezimal_mult, vorzeichen_mult_div
zahl_wurzel_irrational → zahl_wurzel_quadrat, bruch_dezimal
zahl_wurzel_naeherung  → zahl_wurzel_quadrat, runden_ueberschlag → dezimal_add_sub
```

`potenzen` steht in keinem Pool, auch nicht im Testlauf (`pruef_ausschluss = ohne_fertigkeit`, keine
`skill_thema`-Zeile). Getestet werden kann es deshalb nicht; es wird nur mitbelegt.

## 2. Das Muster

**Gemischtes Bild:**
- Wurzel ziehen sicher.
- Wurzelgesetze teils.
- Irrationale Zahlen einordnen wackelig.
- Darunter fehlt ein Fundament: Runden.

Batu schneidet Nachkommastellen ab, statt zu runden. Das zieht sich durch Näherung und Runden.

**Wie das Werkzeug antwortet.**
- Die Aufgabe wählt der Server (`lsa_submit` nimmt nur ausgegebene Items). Das Muster legt deshalb je Skill fest,
  *wie* geantwortet wird, nicht welche Aufgabe kommt.
- Eine falsche Antwort ist immer ein Schlüssel aus den `known_errors` der gerade ausgegebenen Aufgabe. Bevorzugt wird
  das genannte Fehlbild; hat die Aufgabe es nicht, nimmt das Werkzeug ihr erstes.
- Eine richtige Antwort ist `correct_answers[0]`.
- **Ohne `known_errors`** (nur `wurzel-naeherung-01`, MULTI_PART) antwortet das Werkzeug in jedem Teil mit der
  richtigen Zahl plus 1. Das ist ein Fehler ohne Fehlbild; das Werkzeug meldet ihn in der Ausgabe.

**Urteilsregel** (`lsa_urteil_buchen_core`, freie Eingabe):
- Probe 1 richtig → „trägt“, und alle Voraussetzungen werden mitbelegt.
- Probe 1 falsch → Zweitprobe. Danach: falsch + richtig → „trägt teilweise“, falsch + falsch → „trägt nicht“.

| Reihenfolge (erwartet) | Skill | Kl. | Probe 1 | Probe 2 | Urteil | Fehlbild (bevorzugt) |
|---|---|---|---|---|---|---|
| T | `zahl_wurzel_teilweise` | 9 | falsch | falsch | trägt nicht | `faktor_ohne_wurzel` |
| T | `zahl_wurzel_irrational` | 9 | falsch | richtig | trägt teilweise („wackelig“) | `irrational_verwechselt` |
| T | `zahl_wurzel_naeherung` | 9 | falsch | falsch | trägt nicht | `abgeschnitten` |
| Tiefe unter teilweise | `zahl_wurzel_gesetze` | 9 | falsch | richtig | trägt teilweise („teils“) | `wurzel_gliedweise` |
| Tiefe unter näherung | `zahl_wurzel_quadrat` | 9 | richtig | – | trägt („sicher“) | – |
| Tiefe unter näherung | `runden_ueberschlag` | 5 | falsch | falsch | trägt nicht („Fundament fehlt“) | `abgeschnitten` bzw. erstes |
| (mitbelegt durch quadrat) | `potenzen`, `dezimal_mult`, `dezimal_add_sub`, `vorzeichen_mult_div`, `vorzeichen_add_sub` | 5–7 | – | – | trägt (`belegt_direkt = false`) | – |

**Ablauf der LSA:**
- Reihenfolge in Phase T: Der Server nimmt den Einstieg „mit dem größten offenen Abschluss“ zuerst. Ein offener
  Zweitbeleg hat immer Vorrang. Die Reihenfolge der drei Einstiege kann deshalb abweichen. Das Urteil hängt nur an den
  Antworten je Skill.
- Tiefe: Der Server steigt nur unter „trägt nicht“ und „nicht angesetzt“ ab, höchste `fundament_tiefe` zuerst
  (gesetze 6, quadrat 5, runden 2). Er steigt nur bis 12 Minuten nach dem Start ab.
- Zeit: Das Werkzeug legt den Start 12 Minuten zurück (`p_jetzt`) und gibt jede Antwort 55 s später ab.
  11 Antworten ergeben etwa 10 Minuten, also bleibt die Tiefe innerhalb der Grenze.
- `runden_ueberschlag` steigt nicht weiter ab: Seine Voraussetzung `dezimal_add_sub` ist durch die Mitbelegung schon
  „trägt“.
- **Ende:** Kommt ein Item zu einem Skill, der nicht im Muster steht (Breite), ruft das Werkzeug `lsa_finish`. Ein
  echtes Kind säße bis Minute 19. Wer die Breite mit im Szenario haben will, sagt es; dann antwortet Batu dort richtig.
  Dabei entstehen weitere „trägt“-Zeilen.

## 3. Erwartung danach

**LSA-Report** (`lsa_sessions.result_summary` aus `lsa_finish`):
- `answered` 11.
- Urteile je Skill wie in der Tabelle: 1 „trägt“ direkt und 5 mitbelegt, 2 „trägt teilweise“, 3 „trägt nicht“.
- `proposal.weak_clusters`: berechnet `lsa_finish` aus den Antworten. Die genaue Liste ist nicht vorhergesagt; B3 prüft sie gegen den echten Lauf.
- Themenraum-Snapshot `reelle_zahlen`.

**Lernpfad** (`lernpfad_aus_lsa`, Quelle `lsa`, `letzte_uebung_am` leer), 11 Zeilen:

| Stand | Skills |
|---|---|
| `sicher` | zahl_wurzel_quadrat, potenzen, dezimal_mult, dezimal_add_sub, vorzeichen_mult_div, vorzeichen_add_sub |
| `noch_nicht_sicher` | zahl_wurzel_teilweise, zahl_wurzel_irrational, zahl_wurzel_naeherung, zahl_wurzel_gesetze, runden_ueberschlag |

**Erste Session, Testlauf, Thema `quadratische_gleichungen` (vom Coach gewählt):**
- **Zielliste** (`ziel_fertigkeiten_core`, mit dem Lernpfad oben):
  1. zahl_wurzel_quadrat (Voraussetzung, sicher);
  2. **gleichung_quadr_faktor** (Einstieg);
  3. gleichung_quadr_wurzel;
  4. gleichung_quadr_formel;
  5. gleichung_quadr_anzahl.

  Sortiert wird nach der Zahl der Voraussetzungen in der Liste, dann Klasse, dann `fundament_tiefe`. quadrat (0, Tiefe 5)
  steht vor faktor (0, Tiefe 8); wurzel hat 1, formel 2, anzahl 3. **Erster offener Skill ist faktor**, nicht wurzel.
- **Warm-up** (`session_plan_warmup`, 3 Aufgaben, eine Stufe leichter):
  - Alle sechs sicheren Skills sind Voraussetzungen des Ziels (`lsa_abschluss`).
  - Bei Gleichstand gewinnt das Alphabet, also **dezimal_add_sub ×3** (E3).
  - `potenzen` hätte keine Aufgabe; `zahl_wurzel_quadrat` käme erst danach.
  - Gewünscht ist das Warm-up auf `zahl_wurzel_quadrat`. Das kommt erst mit E3 (ii) oder (iii).
- **Kernarbeit:** gleichung_quadr_faktor ist neu.
  - Im Testlauf kommt zuerst die **Platzhalter-Erklärsequenz** (B4, Status `entwurf`, nur im Testlauf sichtbar).
  - Danach ein Lösungsbeispiel und eine ähnliche Aufgabe (`neu_aehnliche_aufgabe`).
  - Ist faktor heute sicher (2 richtig ohne Hinweis), rückt die Engine zu gleichung_quadr_wurzel weiter.
- **Coach-Schublade:**
  - Im Ziel steht zahl_wurzel_quadrat als „Voraussetzung · sicher“.
  - „Heute“ zeigt das Warm-up mit Zahl, dann die Erklärsequenz mit Kernidee 1.
  - Unter „Falsche Antworten“ stehen nur die Fehler der aktuellen Aufgabe (A3).
  - Hinweise zeigen im Testlauf „nicht verfügbar“ (offener Punkt, T3).
- **Alternative Quadratische Funktionen:**
  - Die Kernarbeit begänne bei `fkt_quadr_parabel`, einem Thema-Skill und kein Einstieg.
  - zahl_wurzel_quadrat stünde nicht in der Zielliste: Es ist keine direkte Voraussetzung.
  - Darum der Vorschlag Quadratische Gleichungen.

## 4. Was das Werkzeug schreibt (B3, erst nach Abnahme und Entscheidung E2)

Nacheinander, jeder Schritt in `--dry-run` sichtbar:
1. `lead_thema_setzen`: Thema reelle_zahlen an den Lead.
2. `lsa_start(kind, 9, 'mathematik', 'adaptiv', jetzt − 12 min, false)`.
3. `lsa_submit` je Item nach Muster.
4. `lsa_finish`.
5. `lernpfad_aus_lsa`.

`szenario-zuruecksetzen.mjs` entfernt in umgekehrter Reihenfolge, was das Werkzeug angelegt hat:
- Lernpfad-Zeilen und Protokoll der `lsa`-Übernahme,
- die LSA-Session mit Antworten, Urteilen und Ausgaben,
- das gesetzte Lead-Thema.

Grundlage ist eine Liste der IDs, die das Werkzeug bei jedem Lauf schreibt (`~/szenario/batu-<kind>.json`).
`lernpfad_protokoll` ist append-only; ob das Zurücksetzen dort löschen darf, klärt B3 mit dir.
