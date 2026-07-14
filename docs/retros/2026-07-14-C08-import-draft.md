# C08 — Neuextraktion als Draft ins Autoren-Tool

**Datum:** 2026-07-14
**Branch:** `feat/C08-import-draft`
**Quelle:** `data/vera8_v2.json` (299 Items, R01b)

## Was gebaut wurde

`npm run import:vera8-draft [-- --write|--verify]` — Erstbefuellung des Autoren-Tools
mit **allen 299** Items der Neuextraktion, nicht nur den pool-faehigen. Begruendung:
das Tool ist genau dafuer da, unfertige Items zu pflegen. Ein Item mit fehlender
Loesung gehoert ins Tool, nicht in eine JSON-Datei, die niemand oeffnet.

Der Bau (`scripts/content/vera8Draft.ts`) ist von der DB getrennt und **spiegelt die
drei Vertraege** (`lsa_parts_valid`, `lsa_table_valid`,
`tasks_question_payload_no_solution`). Was einen Vertrag verletzt, wird abgewiesen
und geflaggt — nicht wohlmeinend repariert und nicht am CHECK zerschellt.
17 Tests halten das fest (`scripts/content/vera8Draft.test.ts`).

## Bestand nach dem Lauf

| | |
|---|---|
| angelegt (draft) | **285** |
| uebersprungen (die 14 aus C03, `ready`) | **14** |
| Loesungen gesetzt (via `task_solution_upsert`) | 229 |
| `curriculum_grade` gesetzt | **0** — Handarbeit, wie vorgesehen |
| Loesung im `question_payload` | **0** |
| nach Pflege pool-faehig | **138** |

Typen: MULTI_PART 69, MC 52, SHORT_TEXT 34, NUMERIC 26, FREE_TEXT 23, ohne Typ 95.

Idempotent: der zweite `--write`-Lauf legt 0 an und fasst keine Zeile an. Match ueber
`(source, source_ref)`. Ein Item, das im Tool bearbeitet wurde, wird nie
zurueckgesetzt — der Import ist eine Erstbefuellung, kein Sync.

**138 statt 65:** die 65 aus R01b waren die Items, die *heute ohne jede Pflege*
pool-faehig waeren. 138 ist die Zahl nach der Pflege — alles gesetzt, was der Import
setzen KANN (Stamm, Typ, Loesung, Cluster, AFB); es fehlt nur noch, was ein Mensch
setzen muss: Stoffanker und Alt-Texte.

## Entscheidungen, die Rasit kippen koennen soll

1. **Loesungsbelege raus aus der oeffentlichen Datei.**
   `public/authoring/grounding-vera8.json` wird **statisch ohne Auth** ausgeliefert und
   enthielt die Auswertungs-Zitate ("RICHTIG-Zelle: 16") fuer **209 der 299 Items** —
   also die Loesungen, abrufbar von jedem Kind mitten in der LSA. Das ist derselbe
   Defekt, den T1/T1b gerade in `tasks` geschlossen haben (INV-6), eine Schicht
   darueber. Er war da, bevor dieser Lauf begann.
   Der Index wird jetzt **ohne Loesungsbelege** gebaut (Gegenprobe im Skript, sonst
   `exit 1`). Der Beleg geht stattdessen nach `task_solutions.solution` — die
   Server-Only-Zone, die nur Coach/Admin ueber `task_solution_get` liest. Der Pfleger
   sieht ihn also weiterhin, nur im Loesungsfeld statt im Beleg-Panel.
   *Preis:* `task_solutions.solution` traegt jetzt den Quellenbeleg statt eines
   Loesungswegs. Wer dort einen echten Loesungsweg schreibt, ueberschreibt den Beleg.

2. **`est_duration_sec` ist bei Multi-Part ein Platzhalter** (90 s je Teilaufgabe,
   69 Items). `tasks_multipart_check` verlangt einen Wert — ohne ihn kaeme das Item
   gar nicht in die Tabelle. Die Quelle nennt keine Bearbeitungszeit. Der Platzhalter
   ist geflaggt und im Tool sichtbar.

3. **`FREE_TEXT` steht jetzt im Typ-Umschalter des Editors.** Sonst waere der Typ der
   23 Freitext-Items unsichtbar — und ein Typ, den der Editor nicht anzeigt, ist einer,
   den der Pfleger versehentlich ueberschreibt. Freitext kommt nie in den LSA-Pool
   (`lsa_has_answers` verlangt `correct_answers`); der Erwartungshorizont steht als
   Beleg im Loesungsfeld, nicht als `correct_answers`.

4. **Leitidee → Cluster** (L1→Zahl & Rechnen, L2/L3→Geometrie & Messen,
   L4→Algebra & Funktionen, L5→Daten und Zufall) und **K-Kompetenz → NRW-Code**
   (uebernommen aus `scripts/content/enrich_full.py`, dieselbe Zuordnung wie C02).
   Bei mehreren Leitideen im Item bleibt `cluster_id` leer + Flag (7 Items).

## Ein Fehler, der still gewesen waere

`toPatch` in `editorState.ts` hat `question_payload` bei **jedem** Speichern neu gebaut
und alles verworfen, was der Editor nicht kennt. Die F01-Tabelle liegt genau dort —
**54 Items** haetten ihre Tabelle beim ersten Speichern im Tool verloren, ohne Meldung.
Die Tabelle wird jetzt read-only durchgereicht (`FormState.table`), bis es einen
Tabellen-Editor gibt. Vier Tests halten das fest.

## Was die Extraktion schuldig bleibt

- **45 der 54 "Tabellen" sind keine Tabellen**, sondern Layout-Raster aus dem DOCX
  (leere Kopfzeilen, Ankreuz-Spalten, Achsen-Gitter). F01 weist sie ab — richtig so:
  sie zu reparieren hiesse raten. Sie stehen roh im Beleg-Panel, zum Nachbauen.
- **61 der 130 MULTI_PART-Items** koennen ihre Teilaufgaben nicht speichern: P02 laesst
  nur `short_input|mc` (41× Freitext-Teil), verlangt einen Stamm (20× fehlt) und
  nicht-leere Prompts (7×). Sie sind als Rumpf drin; die Teilaufgaben stehen read-only
  im Beleg-Panel und muessen im Tool neu angelegt werden.
- **34 Items ohne jede gelesene Teilaufgabe** — reiner Arbeitsvorrat.
- **143 Abbildungen weggelassen:** die eingebettete Lizenzzeile nennt nur "Text und
  Teilaufgaben", keine "Grafik" — IQBs CC BY deckt sie nicht. Das pauschale
  `lizenz_status` am Item behauptet CC BY und ist fuer Grafiken schlicht falsch; es
  wird ignoriert. 380 gedeckte Abbildungen sind als Verweis gesetzt (kein Upload),
  Alt-Text leer — den schreibt ein Mensch, und er blockiert die Freigabe.

## Offen

- Der gegatete Kanal fuer Belege: `task_solutions.solution` ist die Notloesung, kein
  Zuhause. Sauber waere ein eigenes Feld (`task_solutions.beleg jsonb`) plus
  Rueckgabe in `task_solution_get` — **Migration, also bewusst nicht in diesem Lauf.**
- Ein Tabellen-Editor im Tool (54 Items brauchen ihn, 45 davon dringend).
- Stoffanker + Alt-Texte fuer die 138 pool-faehigen Items — Handarbeit, das ist der Job
  des Tools.
