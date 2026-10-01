# Blind-Löser ohne API-Schlüssel

Stufe 2 von `tools/verify-tasks.mjs` ist der Blind-Löser. Er prüft, ob jemand die Aufgabe ohne Kenntnis der Lösung löst und dabei auf die hinterlegte Antwort kommt. Das braucht keinen `ANTHROPIC_API_KEY` mehr: Ein frischer Subagent (Agent-Tool) löst die Aufgaben, `verify-tasks` vergleicht seine Antworten deterministisch mit den Lösungen. Der Vergleich nutzt dieselbe Bewertung wie der Schülerpfad (`lsa_is_correct`).

## Ablauf

### 1. Aufgaben exportieren

```bash
node tools/blind-loeser/exportiere.mjs docs/prefill/<batch>.json <ordner>
```

Das Skript schreibt `<ordner>/aufgaben.json` mit Aufgabentext, Teilprompts und Einheit. Jede Figur wird mit demselben Generator wie in `upload_figures.py` als PNG gerendert. Lösungen, `known_errors` und Figurparameter landen **nicht** im Export. Ein Selbstcheck bricht ab, sobald ein Lösungsschlüssel auftaucht.

`<ordner>` sollte außerhalb des Repos liegen, zum Beispiel unter `$CLAUDE_JOB_DIR/tmp`. Der Löser soll das Repo gar nicht erst sehen.

### 2. Subagent lösen lassen

Den Text aus [`AUFTRAG.md`](AUFTRAG.md) als Prompt an einen **frischen** Subagenten geben, mit dem eingesetzten Ordner. Ein Fork kommt nicht in Frage, denn er erbt den Kontext mitsamt den Lösungen. Das JSON-Array vom Ende seiner Antwort speichert man als `docs/prefill/<batch>-blind.json`:

```json
[{"task_id": "…", "part": null, "antwort": "-3", "unsicher": "nein", "anmerkung": ""},
 {"task_id": "…", "part": "1",  "antwort": "4",  "unsicher": "nein", "anmerkung": ""}]
```

### 3. Vergleichen

```bash
node tools/verify-tasks.mjs --from-file docs/prefill/<batch>.json \
     --answers-from docs/prefill/<batch>-blind.json --min-pass 1.0
```

Nach dem Einspielen geht dasselbe gegen Prod, mit `--source <herkunft> --answers-from …` statt `--from-file`.

## Bewertung

- **Richtig** ist eine Antwort, wenn sie nach der Normalisierung des Schülerpfads einer hinterlegten Variante gleicht. Die Normalisierung macht: trimmen, Leerraum zusammenfassen, Komma zu Punkt, Kleinschreibung. Siehe `lsa_normalize_answer` und `lsa_is_correct`.
- **Toleranz und `equivalents`:** Hat `acceptance` ein `canonical`, gelten zusätzlich `equivalents` und `tolerance` (`exact`, `absolute`, `decimals`), wie in `lsa_grade` und `lsa_values_equal`. Das gilt nur für Aufgaben ohne Teilaufgaben, die keine Auswahlaufgaben sind. Achtung: Der Schülerpfad speichert `lsa_responses.correct` allein über `lsa_is_correct`, und das kennt keine Toleranz. Stimmt eine Antwort nur über die Toleranz, zählt sie als richtig, der Bericht meldet sie aber gesondert. In dem Fall eine Variante in `correct_answers` ergänzen.
- **Teilaufgaben:** Jeder Teil wird gegen seine eigenen Varianten geprüft. Die Aufgabe zählt nur, wenn alle Teile stimmen.
- **Fehlende Antwort:** Fehlt die Antwort zu einer Aufgabe oder einem Teil, ist die Aufgabe *ungeprüft* und senkt die Quote.
- **`unsicher: ja`** ändert die Wertung nicht. Der Bericht listet solche Aufgaben aber gesondert, damit jemand hinsieht.

Ohne `--answers-from` und ohne Schlüssel bricht `verify-tasks` vor Stufe 2 mit einem Hinweis auf diesen Ablauf ab. Es geht dann kein API-Aufruf raus.
