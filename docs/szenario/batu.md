# Szenario „Batu“: LSA-Muster und Erwartung für die erste Session

Stand 09.10.2026 · Paket F1, Umfang B2 · **abgenommen („Muster Batu ok“, Rasit 08.10.)** · Maschinenlesbar: `batu.json`

Belege: dbread 08.10.2026, Abfragen unter `/tmp/claude-1000/f1/b1/` und `/tmp/claude-1000/f1/b2*.sql`;
Funktionen aus `supabase/schema-erwartet.sql` (Stand Prod).

## 0. Entscheidungen (Rasit, 08.10.2026)

Die Befunde aus dem Entwurf (Herleitung in der Git-Historie dieser Datei) und wie sie entschieden sind:

| | Befund | Entscheidung |
|---|---|---|
| **E1** | Kein Lead in Prod hat `ist_test`; kein Testkind erfüllt „Testlead“. | **TESTLEAD Zweitmann** (`5737b689…`, Klasse 9, Vertrag aktiv, Lernpfad leer) spielt Batu. |
| **E2** | Ohne Testlauf ist der LSA-Pool für diese Skills leer (kein Item `ready`); ein Testlauf-LSA erzeugt keinen Lernpfad. | **Vorschlag A:** Testkonten bekommen in der LSA-Auswahl auch ohne Testlauf den Testlauf-Pool (Migration `20261011140200`). `session_im_pool`, Hinweise, Anzeige und Entscheidung 27 unverändert. |
| **E3** | Das Warm-up wählte bei Gleichstand alphabetisch (Batu: `dezimal_add_sub`). | **Option iii:** neue Reihenfolge in `session_plan_warmup` (Migration `20261011140300`, Annahme F17 in offene-punkte-a2). Kandidatenmenge bleibt. |

Kernarbeit ab `gleichung_quadr_faktor` ist gewollt; die Platzhalter-Sequenz (B4) hängt am ersten offenen Ziel-Skill.

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
- **Warm-up mit der neuen Regel (F17):** **vorzeichen_add_sub** („Negative Zahlen addieren/subtrahieren“, Kl. 7), drei
  Aufgaben, eine Stufe leichter. Warum:
  - Kandidaten sind die sechs sicheren Skills (zahl_wurzel_quadrat direkt, fünf mitbelegt). Alle sind Voraussetzungen
    des Ziels (`lsa_abschluss` der Ziel-Skills).
  - (1) Alle haben einen bekannten Stand (Lernpfad aus der LSA). (2) Alle sind sicher.
  - (3) Abstand zum ersten offenen Ziel-Skill **gleichung_quadr_faktor** (dbread `skill_kante`): vorzeichen_add_sub 2,
    vorzeichen_mult_div und dezimal_mult 3, dezimal_add_sub 4. zahl_wurzel_quadrat und potenzen sind von faktor
    aus **nicht erreichbar** (Ausklammern braucht keine Wurzel), sie kommen zuletzt.
  - Im Testlauf-Pool hat vorzeichen_add_sub 7 Aufgaben (dbread). Das Warm-up bleibt bei ihm (Fokus, F9).
- **Die Verbindung LSA → Session** zeigt sich bei Batu deshalb nicht im Warm-up, solange keine Kante von den
  Einstiegen der quadratischen Gleichungen zu einem Wurzel-Skill führt (offener Punkt an die Inhaltspflege,
  offene-punkte-f1). Sie zeigt sich
  - im **LSA-Report** (Urteile zu den Wurzel-Skills, Runden als fehlendes Fundament),
  - in der **Zielliste** (zahl_wurzel_quadrat als „Voraussetzung · sicher“) und
  - beim **Einmischen** (F13): eingemischt werden sichere Voraussetzungen des Ziels, darunter zahl_wurzel_quadrat.
    Einschränkung: Auch hier entscheidet bei Gleichstand das Alphabet (`session_misch_kandidaten`: Voraussetzung,
    zuletzt geübt, dann skill_key). Vor zahl_wurzel_quadrat kommen dezimal_add_sub, dezimal_mult und
    vorzeichen_mult_div (potenzen hat keine Aufgabe); die Wurzel ist also etwa die vierte eingemischte Aufgabe
    (Mischanteil 30 %, Einführungsaufgaben zählen nicht). Offener Punkt, nicht geändert.
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

## 4. Was das Werkzeug schreibt (B3)

`tools/szenario-lsa.mjs` (gemeinsame Teile in `tools/szenario-lib.mjs`). Alles in **einer** Transaktion, als Admin
(Claims transaktionslokal wie trockenlauf.md Schritt 6), über die Funktionen einer echten LSA:
1. `lead_thema_setzen`: Thema reelle_zahlen als aktuelles Schulthema des Leads (nur, wenn es nicht schon so ist).
2. `lsa_start(kind, 9, 'Mathematik', 'adaptiv', jetzt − 12 min, false)` (kein Testlauf, E2).
3. `lsa_submit` je Item, das der Server ausgibt, mit der Antwort nach `batu.json`; Zeitpunkt je Antwort +55 s.
4. `lsa_finish` (Report), sobald kein Item mehr kommt oder eins zu einem Skill außerhalb des Musters.
5. `lernpfad_aus_lsa` (Lernpfad).

- `--dry-run` zeigt jeden Schreibschritt mit Ergebnis (Urteil je Antwort, Lernpfad) und rollt zurück.
- Abbruch, wenn das Kind kein Testkonto ist, schon eine andere LSA oder einen Lernpfad hat.
- Ein zweiter Lauf findet die abgeschlossene Szenario-LSA und tut nichts.
- Das Ergebnis (Session-ID, Lead, Lead-Thema vorher) steht in `~/szenario/batu-<kind>.json` (chmod 600).

`tools/szenario-zuruecksetzen.mjs --protokoll <datei>` entfernt genau das wieder:
- `lernpfad_protokoll`: die 11 Übernahme-Zeilen dieser LSA. Die Tabelle hat keine Lösch-Sperre; gelöscht werden nur
  Zeilen mit `aktion = 'uebernahme'` und `neu.lsa_session_id` = Szenario-LSA. **Abbruch**, sobald es für das Kind
  andere Protokollzeilen, Belege oder eine Coach-Entscheidung gibt (dann wurde mit dem Lernpfad gearbeitet).
- `lernpfad`: die Zeilen dieser LSA.
- `lsa_sessions`: die Session; Antworten, Urteile und Ausgaben hängen per Cascade daran. Abbruch bei einem Eltern-Report.
- `lead_themen`: das gesetzte Thema; ein vorheriges Thema setzt es wieder.

**Beleg (Wegwerf-DB, `docs/szenario/b3-wegwerf.sql`, 09.10.):** 11 Antworten genau nach Muster, Urteile wie in der
Tabelle, 11 Lernpfad-Zeilen (6 sicher, 5 noch nicht sicher), `result_summary` vorhanden, `testlauf = false`. Zweiter
Lauf: keine Änderung. Zurücksetzen: alle Zähler wie vorher. Nicht-Testkonto: Abbruch, nichts geschrieben. In der
Wegwerf-DB kam nach runden_ueberschlag kein weiteres Item (kleiner Pool); in Prod endet die LSA beim ersten Item der
Breite. `lsa_skill_urteil` trägt zusätzlich Zeilen `ungeprueft` für den Rest des Themenraums (35 in der Wegwerf-DB);
sie gehen nicht in den Lernpfad.
