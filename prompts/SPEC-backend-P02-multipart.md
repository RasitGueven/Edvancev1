# SPEC: backend-P02 — Multi-Part-Aufgabentyp

**Ziel:** Die LSA kann Aufgaben mit mehreren Teilaufgaben stellen. Jede Teilaufgabe hat einen
eigenen Antworttyp und eigene Kompetenzen. Die Auswertung erfolgt **pro Teilaufgabe**, nicht
pro Item.

**Warum das wichtig ist:** Im VERA-Bestand tragen 86 von 144 `ready`-Items mehrere Teilaufgaben.
Jede davon hat im Quelldatensatz **eigene `kompetenzen` und ein eigenes `afb`**. Ein Multi-Part-Item
mit drei Teilaufgaben liefert also drei Kompetenz-Datenpunkte statt einem — es ist diagnostisch
*wertvoller* als ein flaches Item, nicht nur zusätzlich.

**Nicht in diesem Lauf: der Import der 86 Items.** Das ist C07 und kommt danach. Erst der Vertrag,
dann die Daten. Wer beides gleichzeitig baut, baut gegen ein Modell, das er gerade selbst erfindet.

---

## 1. Entscheidungen (getroffen, nicht zur Diskussion)

| Frage | Entscheidung | Begründung |
|---|---|---|
| Ein Screen oder Schritt für Schritt? | **Ein Screen.** Stamm oben, alle Teilaufgaben darunter, ein „Weiter". | Teilaufgabe 2 baut fachlich auf 1 auf. Sequenzielles Durchreichen zerreißt den Zusammenhang — und das Kind sieht es im VERA-Original ebenfalls als ein Blatt. |
| Teilweise richtig — was zählt? | **Auswertung pro Teilaufgabe, kein Item-Gesamtergebnis.** | Jede Teilaufgabe misst eine eigene Kompetenz. Ein zusammengefasstes „2 von 3" wäre diagnostisch wertlos. |

---

## 2. Der Payload

`lsa_question_payload` baut für Multi-Part-Items:

```json
{
  "kind": "multi_part",
  "task_id": "...",
  "stem": "Der gemeinsame Aufgabentext, der für alle Teilaufgaben gilt.",
  "assets": [ ... ],
  "parts": [
    { "nr": 1, "kind": "short_input", "prompt": "...", "unit": "cm" },
    { "nr": 2, "kind": "mc",          "prompt": "...", "options": [{"id":"a","label":"..."}] },
    { "nr": 3, "kind": "short_input", "prompt": "...", "unit": null }
  ]
}
```

**Harte Regeln:**
- Der Payload enthält **keine Lösung**. Kein `correct`, kein `accepted`, in keiner Verschachtelungsebene.
  Die Whitelist von `lsa_question_payload` gilt rekursiv.
- Teilaufgaben-`kind` ist auf `short_input` und `mc` beschränkt (auto-gradebar). Alles andere gehört
  nicht in die LSA.
- `stem` und `parts[].prompt` sind getrennt. Ein Multi-Part-Item **ohne** sauber abtrennbaren Stamm
  ist kein Multi-Part-Item — dann Import verweigern und melden.

---

## 3. Datenmodell

### `tasks`
- `input_type = 'MULTI_PART'` (neuer erlaubter Wert im `tasks_input_type_check`).
  **Prüfen, wie der Constraint aktuell aussieht — nicht raten.**
- `est_duration_sec` ist bei Multi-Part die **Summe** über alle Teilaufgaben. Relevant für §5.

### `task_solutions.correct_answers`
Wird zum Objekt, mit der Teilaufgaben-Nummer als Schlüssel:
```json
{ "1": ["20"], "2": ["b"], "3": ["16"] }
```
Für flache Items bleibt das bestehende Array-Format gültig. **Beide Formen müssen koexistieren** —
die 14 importierten Items dürfen nicht brechen.

### `lsa_responses`
Bekommt eine Spalte **`part_nr`** (`int`, `null` für flache Items).
- Eine Zeile **pro Teilaufgabe**, nicht pro Item.
- Der Primärschlüssel bzw. Unique-Constraint muss `part_nr` einschließen. **Bestehende Constraints
  prüfen** — ein `unique(session_id, task_id)` würde Multi-Part hart blockieren.
- Migration: bestehende Zeilen bekommen `part_nr = null`.

---

## 4. `lsa_submit` — Vertragserweiterung

Der Client sendet für ein Multi-Part-Item **eine** Submit-Anfrage mit allen Teilantworten:

```json
p_response = { "1": "20", "2": "b", "3": "16" }
```

Für flache Items bleibt das bisherige Format (Skalar/Array) gültig. `lsa_submit` unterscheidet
anhand des `input_type` der Task, **nicht** anhand der Form des Payloads.

**Unverändert und nicht verhandelbar:**
- Die Response enthält **keine per-Item- und keine per-Teilaufgaben-Korrektheit**. Auch nicht
  aggregiert, auch nicht als Zähler. `{ok, next}` bleibt.
- `lsa_submit` schreibt **keine `xp_events`** und fasst `student_progress` nicht an.
- Bewertung je Teilaufgabe über `lsa_normalize_answer` bzw. `lsa_is_correct` — dieselbe Konvention
  wie bisher, keine zweite.

---

## 5. `lsa_start` — Zeitbudget

Ein Multi-Part-Item mit vier Teilaufgaben kostet das Zeitbudget von vier Aufgaben. Wenn der Pool
blind nach Item-Anzahl zieht, sprengt die LSA die 20 Minuten.

**`lsa_start` zieht gegen ein Zeitbudget, nicht gegen eine Item-Anzahl** — Summe über
`est_duration_sec`. Der bestehende Ziehalgorithmus muss entsprechend angepasst werden.

Falls `est_duration_sec` bei Bestandsitems nicht gesetzt ist: melden, nicht schätzen.

---

## 6. `result_summary` — pro Kompetenz

Die Auswertung aggregiert **über Teilaufgaben nach Kompetenz**, nicht über Items.

Ein Item mit drei Teilaufgaben zu drei verschiedenen Kompetenzen erzeugt drei unabhängige
Datenpunkte. Es gibt **kein** Item-Gesamtergebnis, keine „2 von 3"-Quote, keinen Item-Score.

Die Kompetenz-Zuordnung je Teilaufgabe kommt aus dem Item (`teilaufgaben[].kompetenzen`,
`teilaufgaben[].afb`) und muss beim Import mitgeführt werden — siehe C07.
**Prüfen, wo `tasks` die Kompetenz je Teilaufgabe halten kann.** Falls das Schema das nicht
hergibt: melden. Das ist der Kern der Diagnostik und darf nicht verlorengehen.

---

## 7. Frontend (`edvance-app`, eigener PR)

`MultiPartContainer.tsx`:
- Stamm oben (inkl. `assets`, Bild über dem Text)
- Darunter alle Teilaufgaben untereinander, jede mit ihrem eigenen Eingabetyp
- **Ein** „Weiter"-Button. Aktiv, sobald **alle** Teilaufgaben beantwortet sind.
- **Kein Richtig/Falsch**, auf keiner Ebene. Keine Häkchen, keine Farben, kein Zwischenfeedback.
- Kein XP, keine Streak-Anzeige während der LSA.

Die bestehenden `MultipleChoice`- und `ShortInput`-Komponenten werden wiederverwendet, nicht kopiert.

---

## 8. Definition of Done

- [ ] Migration: `input_type = 'MULTI_PART'` erlaubt, `lsa_responses.part_nr`, Constraints angepasst
- [ ] `lsa_question_payload` baut den Multi-Part-Payload, **rekursiv ohne Lösung** — per pgTAP belegt
- [ ] `lsa_submit` nimmt Teilantworten entgegen, schreibt eine `lsa_responses`-Zeile pro Teilaufgabe
- [ ] `lsa_submit`-Response verrät **keine** Korrektheit — pgTAP
- [ ] `lsa_submit`/`lsa_finish` schreiben **keine** `xp_events` — pgTAP (INV-2)
- [ ] `lsa_start` zieht gegen ein Zeitbudget
- [ ] `result_summary` aggregiert pro Kompetenz, nicht pro Item
- [ ] **Die 14 flachen Bestandsitems laufen unverändert** — Regressionstest
- [ ] `DATENVERTRAG.md` aktualisiert
- [ ] pgTAP grün, `tsc` grün, `db lint` sauber

---

## 9. Explizit NICHT in diesem Lauf

- **Kein Import der 86 MULTI_PART-Items.** Das ist C07 und braucht Sichtung (Trefferquote im
  Bestand: ~40 %).
- Keine neuen Aufgabentypen außer Multi-Part.
- Kein Freitext, keine Handschrift, kein Foto — nicht auto-gradebar, gehört in die Session.
- Kein Deploy.
- Keine Änderung an `xp_rules`, `apply_xp_event`, den Triggern.
- Kein Anfassen von `screening_items` oder dem alten Screening-Pfad.
