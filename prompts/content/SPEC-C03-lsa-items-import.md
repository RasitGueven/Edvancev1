# SPEC: C03 — Import der geprüften LSA-Items (SHORT_INPUT, Charge 1)

**Ziel:** 15 manuell geprüfte VERA-8-Items aus `data/vera8_komplett_enriched.json` nach
`tasks` + `task_solutions` importieren, `status='ready'`, damit die LSA echte Aufgaben hat.

**Kontext:** Der bisherige `seed:vera8` schreibt nach `screening_items` — das ist der *alte*
Screening-Pool und wird von der LSA **nicht** gelesen. P01 legt den LSA-Pool auf
`tasks.status = 'ready'`. Es gibt bisher keinen Importpfad dorthin. Dieser Lauf baut ihn.

---

## 0. Kritische Vorbemerkung — warum genau diese 15

`status = 'ready'` im JSON heißt **nicht** „von Lena geprüft". Es heißt „Pipeline durchgelaufen".
Das Feld `_derivation.review_durch_lena_erforderlich` steht auf `true`.

Der Bestand enthält nachweislich defekte Items mit `status='ready'`:
- *Zeitangabe*: „Wie viele Minuten sind 2 Stunden?" → hinterlegte Lösung **150min**. Falsch.
- *Holzwürfel*, *Winkel Gamma*: PDF-Extraktion hat Textspalten ineinander verschränkt.
- Diverse Zeichen-/Messaufgaben, die auf einem Tablet nicht lösbar sind.

**Die 15 Items unten wurden einzeln gesichtet.** Es werden ausschließlich diese importiert.
**Keine Ausweitung, keine „ähnlichen" Items, kein Filter über `status`.** Wer den Pool erweitern
will, macht das über ein Review mit Lena — nicht über einen Agentenlauf.

---

## 1. Die 15 Items

ID-Präfixe (die vollen UUIDs aus dem JSON auflösen — Präfixe sind eindeutig):

| # | Präfix | Titel | Antwort | `unit` |
|---|---|---|---|---|
| 1 | `1a518b4b` | Bestimme x | `20` | — |
| 2 | `a880daf0` | Das ist gerundet | `5,1` | — |
| 3 | `4d8811de` | Einfache Gleichung | `2` | — |
| 4 | `17f4df4b` | Gleichung lösen 1 | `-10` | — |
| 5 | `7ab3cfad` | Kugeln ziehen | `3` | — |
| 6 | `82e6559f` | Papier | `22` | `mm` |
| 7 | `b3c8ade1` | Pflaumen | `0,95` | `€` |
| 8 | `e9a54ab8` | Temperaturdifferenz | `19` | `°C` |
| 9 | `9c72e62c` | 20 Prozent | `16` | `m` |
| 10 | `37337edb` | Croissant | `1,25` | `€` |
| 11 | `f464ecf3` | Ecken an Pyramiden | `5` | `Ecken` |
| 12 | `ad736c2a` | Hälfte | `500000` | — |
| 13 | `df59c706` | Lohnerhöhung | `10` | `%` |
| 14 | `e29bc024` | Winkel im Dreieck | `90` | `°` |
| 15 | `a833826c` | Zwanzig Prozent | `30` | `€` |

**Die `Antwort`-Spalte ist verbindlich und ersetzt `akzeptierte_antworten` aus dem JSON.**
Grund: Mehrere Items führen dort Lösungen in umgerechneten Einheiten (Item 9: `16`, `0,016 km`,
`160 dm`, `1600 cm`). P01 hat entschieden: **keine Einheiten-Umrechnung.** Das Feld fragt in `m`,
also ist `16` die Lösung. Alles andere würde `160` als korrekt durchgehen lassen.

Bei Item 12 zusätzlich `500 000` (mit Leerzeichen) akzeptieren, **falls** `lsa_normalize_answer`
Leerzeichen nicht ohnehin entfernt. Erst die Funktion lesen, dann entscheiden.

---

## 2. Prompt-Bereinigung

Die `aufgabe_text`-Felder enthalten am Ende das **Label des Eingabefelds** als eigene Zeile —
z.B. bei Item 9: `"Berechne 20% von 80m.\nm"`. Das trailing `m` ist nicht Teil der Frage,
sondern die Einheit.

**Regel:** Die abschließende Einheiten-Zeile aus dem Prompt entfernen und in `unit` überführen.
Der Prompt endet mit der Frage, nicht mit dem Feld-Label.

Wo die Einheit mitten im Satz steht (Item 8: „Die Temperatur ist um __ °C gestiegen."), den Satz
sinnvoll kürzen. **Im Zweifel: nicht raten, sondern melden.** Ein verstümmelter Prompt ist
schlimmer als ein nicht importiertes Item.

---

## 3. Zielstruktur

### `tasks`
- `input_type = 'short_input'` (der Diskriminator — **nicht** `content_type`)
- `status = 'ready'`
- `is_active = true`
- `afb` aus `teilaufgaben[0].afb_raw` (`I` / `II` / `III`)
- `question_payload`: Prompt + ggf. `unit`. **Enthält keine Lösung. Kein `correct`, kein `accepted`.**
- Fachliche Zuordnung aus `edvance_matrix` (`inhaltsfelder`, `prozesskompetenzen`) auf die
  vorhandenen Spalten mappen.

**Pflichtfelder und Spaltennamen aus `schema.sql` ableiten — nichts erfinden.** Wenn ein Feld
verlangt wird, das die Quelldaten nicht hergeben: **stoppen und melden**, nicht mit Defaults füllen.

### `task_solutions`
- Über die RPC **`task_solution_upsert`**, nicht per direktem `INSERT`.
  Die Tabelle hat bewusst keine Grants für `anon`/`authenticated`.
- Prüfen, ob `service_role` die RPC ausführen darf. Falls die `REVOKE ... FROM PUBLIC`-Zeile
  auch `service_role` ausgesperrt hat: **stoppen und melden.** Nicht selbst granten.

### Lizenz
Alle Items sind **CC BY 4.0 (IQB/VERA-8), Attribution erforderlich.** Prüfen, ob `tasks` ein Feld
für Quelle/Lizenz hat. Falls ja: aus `quelle` und `lizenz_status` befüllen. Falls nein: melden —
das ist eine rechtliche Pflicht, keine Nettigkeit.

---

## 4. Form

`scripts/import-lsa-items.ts`, Muster analog zu den bestehenden Seed-Scripts
(`tsx`, `--env-file=.env`, `SUPABASE_SERVICE_ROLE_KEY`). npm-Script `import:lsa-items`.

**Idempotent:** Zweiter Lauf legt nichts doppelt an und überschreibt keine manuellen Korrekturen
an bestehenden Zeilen.

**Keine Migration.** Das sind Daten, kein Schema.

---

## 5. Definition of Done

- [ ] 15 Zeilen in `tasks` mit `status='ready'`, `input_type='short_input'`
- [ ] 15 zugehörige Einträge in `task_solutions`
- [ ] `question_payload` enthält bei keinem Item eine Lösung — per Query belegen
- [ ] Prompts enthalten keine trailing Einheiten-Labels mehr
- [ ] `npx tsc --noEmit` grün
- [ ] Zweiter Lauf ändert nichts (Idempotenz gezeigt)
- [ ] Abschlussbericht: Tabelle mit den 15 Items — Titel, `afb`, `unit`, importierte Lösung

---

## 6. Explizit NICHT in diesem Lauf

- Keine anderen Items als die 15 oben. Auch keine, die „auch sauber aussehen".
- Kein `MULTIPLE_CHOICE` (Optionen stecken als Fließtext im Prompt — eigener Lauf mit Parser
  und manueller Sichtprüfung).
- Kein `MULTI_PART` (86 Items — braucht eine didaktische Entscheidung zur Aufspaltung, gehört
  zu Lena).
- Keine Items, die ein Bild brauchen (Assets sind nicht verifiziert im Bucket).
- Keine Änderungen an `screening_items`, `seed_vera8.ts` oder dem alten Screening-Pfad.
- Keine Schema-Änderungen, keine Migration, kein Deploy.
- Kein Anfassen von `xp_rules`, `apply_xp_event`, den Triggern.

---

## 7. Verifikation (Teil des Laufs, am Ende)

```sql
select status, input_type, count(*) from tasks group by 1,2;
select count(*) from task_solutions;
-- Gegenprobe: keine Lösung im Payload
select count(*) from tasks
where question_payload::text ilike '%correct%'
   or question_payload::text ilike '%accepted%'
   or question_payload::text ilike '%loesung%';
```
Die letzte Query muss **0** liefern.
