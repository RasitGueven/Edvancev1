# Offene Punkte C3 (Schublade der Coach-Live-Sicht: Pfad-Vorschlag, Heute, Grund mit Zahl)

Stand 08.10.2026, Branch `feat/rasit-session-c3-schublade`. **Eingespielt 08.10.2026** (`20261011100100`, `20261011100200`). Beweis: `supabase/tests/session_c3.test.sql`,
`src/lib/session/coachLiveSchublade.test.ts`, `src/pages/coach/live/SchubladeC3.test.tsx`.

## Erledigt aus den Vorgängern

| Herkunft | Punkt | Wie |
|---|---|---|
| c2-3, a2d-2 d | Pfad-Vorschlag mit Zahlen | `coach_kind_detail.pfad_vorschlag` (A2d-Felder, Klasse, Fehlbild, Thema); Typen nachgezogen |
| c2-4 | „Heute“-Zeilen | `coach_kind_detail.heute`, gezählt wie die Engine (F4) |
| c2-4 | Grund mit Zahl | `session_schritte.details` (Entscheidung Rasit 08.10.), `coach_kind_detail.schritt_details` |
| c2-5 | Erklärsequenz mit allen Kernideen und Fehlbild je Runde | `coach_kind_detail.erklaer_kernideen` (nur gelesen, an E1/L6 nichts geändert) |
| c2-6 | Warm-up-Beleg von heute | aus `heute` (Warm-up-Zeile des Kandidat-Skills) |
| a2d-2 e | Signal vor A2d | Zahlen null, die Zeile fehlt (pgTAP 2, Vitest) |

## Herkunft je Feld

| Feld (`src/types/coachLive.ts`) | Quelle |
|---|---|
| `pfadVorschlag.skillPlan` | Signal `ziel_skill_key` → `session_label` |
| `pfadVorschlag.skillTiefer` | Signal `voraussetzung_label` (vor A2d: Label von `skill_key`) |
| `pfadVorschlag.klasseTiefer` | `skills.klasse_herkunft` der Voraussetzung |
| `pfadVorschlag.warmupRichtig/warmupVon` | Signal `warmup_richtig`/`warmup_aufgaben` (A2d; vorher null) |
| `pfadVorschlag.fehlbild` | letzte Antwort dieser Session auf der Voraussetzung mit Fehlbild → `fehlbild_labels.klartext` |
| `pfadVorschlag.fehlbildAm` | letzte frühere Session des Kindes mit demselben Fehlbild-Slug (`session_antworten`) |
| `pfadVorschlag.themaLabel` | `session_checkin.ziel_thema_key` → `themen.label` |
| Anzeige des Vorschlags | nur solange kein `signal_erledigt` (art `entscheidung`) nach dem Signal steht, oder nach „Ändern“ |
| `heute` ankommen | erste `session_tablets.zugewiesen_am` |
| `heute` warmup/kern/eingemischt | `session_ausgegeben` (Phase, `eingemischt`) × `session_aufgabe_stand`: von = erledigt, richtig = Erfolg; Hinweise = gelieferte `hinweis`-Ereignisse |
| `heute` erklaerung | `erklaer_fortschritt`: Kernideen mit `richtig`, Nr. und Runde der jüngsten Zeile |
| `grundLetzterSchritt` | `schritt_details` (richtig, von, ziel, aenderung bzw. mischanteil); ohne: grob aus `grund_code` wie C2 |
| `erklaersequenz.kernideen` | `erklaer_kernideen`: alle Kernideen des Skills (Status wie Testlauf), Stand, max. Runde, Variante, Fehlbild der letzten falschen Runde (Klartext) |
| `masteryKandidat.belege` warmupHeute | Warm-up-Zeilen von `heute` auf dem Kandidat-Skill |

## Offen

1. **Migrationsversionen** `20261011100100` und `20261011100200` liegen im Auftragsbereich, also in der Zukunft
   (heute 08.10.; CLAUDE.md §10 verlangt `date -u`). Per dbread am 08.10. geprüft: beide frei, Prod-Maximum
   `20261010121018`. Die ersetzten Funktionen (`session_plan_kern`, `session_naechster_schritt`, `coach_kind_detail`)
   haben in Prod dieselbe Definition wie im Neuaufbau (md5 von `pg_get_functiondef` gleich).
2. **Schema-Abzug (erledigt 08.10.).** Nach dem Einspielen `tools/schema-snapshot.sh` aus Prod gezogen; gefiltert wie
   in CI gleich dem Neuaufbau aus allen 238 Migrationen. `schema.sql`/`schema_content.sql` pflegt seit #130 kein
   Session-Paket mehr (Quelle ist `schema-erwartet.sql`), deshalb nicht angefasst.
3. **Grund im Zielbereich (entschieden, Rasit 08.10.).** Bleibt die Stufe nach dem Fenster (`aenderung = 0`), zeigt
   die Schublade „{richtig} von {von} ohne Hinweis richtig, im Zielbereich um {ziel}, gleiche Stufe.“ Kein Fehlbild,
   keine Wertung (`schublade.grund.imZiel` in `coachLive.json`, dem Namensraum der Live-Sicht). pgTAP 1G, Vitest.
4. **Testabdeckung der Fenster-Richtungen.** pgTAP prüft `aenderung = -1` (0 von 5), `0` (3 von 5 bei Ziel 0,6;
   dafür braucht „sicher“ im Test sechs richtige, sonst wechselt die Engine nach zwei den Skill) und den Mischanteil.
   Für `+1` gibt es keinen Fall: Fünf Erfolge machen den Skill sicher, bevor das Fenster voll ist. Der Code-Pfad ist
   derselbe.
5. **Fehlbild-Datum: Frage an Fatih (Rasit 08.10.: so lassen).** `fehlbildAm` sucht denselben Fehlbild-Slug in
   früheren Sessions auf jedem Skill, nicht nur auf der Voraussetzung. Fehlbilder hängen am Denkfehler, nicht am Skill.
   Antworten ohne Klartext zählen für `fehlbild` nicht. **Frage an Fatih:** Soll „Gleiches Fehlbild wie am …“ nur
   frühere Fehler auf derselben Voraussetzung zählen?
6. **Erklär-Signal.** Hängt das Kind an einer Kernidee (Stand `signal`), zeigt die Liste die Kernidee als „läuft“.
   Das Signal selbst steht in der Warteschlange. Die Liste gilt für die jüngste Sequenz dieser Session; eine
   fertige frühere Sequenz bleibt sichtbar, bis eine neue beginnt (die Kachel blendet fertige Sequenzen wie in C2 aus).
7. **Doppelter Beleg (entschieden, Rasit 08.10.: so wie gebaut).** Mit dem Warm-up-Beleg von heute fällt der
   Session-Beleg derselben Session aus `lernpfad.belege` weg. „Abstand zur letzten Übung“ rechnet unverändert ab dem
   ersten Beleg (C2) und zeigt beim ersten Beleg von heute „0 Tage“.
8. **„Heute“ ohne Exit.** Die Exit-Aufgaben (Check-out) gehören zum Check-out-Block und stehen nicht in „Heute“.
   Die Zusätze `lsaSicher` und `tiefer` aus C1 bleiben leer, weil der Server sie nicht je Zeile belegt.
9. **Warm-up-Zahlen je Voraussetzung.** Wie in A2d (offene-punkte-a2d 2 c) zählen die Warm-up-Zahlen nur auf der
   Voraussetzung, an der das Signal hängt.

10. **X0c-Ausnahmeliste.** `session_x0c.test.sql` nimmt die C3-Funktionen namentlich vom NULL-Wächter aus, „bis
    C3 sie übernimmt“ (offene-punkte-x0c, Für C3 Nr. 2: streichen, sobald C3 gemergt ist). Mit C3 ist `session_x0c`
    grün. Die Liste gehört X0c und ist hier nicht angefasst. Wer: nach dem Merge von C3 X0c oder Rasit; die Liste darf
    nur schrumpfen.

## Consensus-Check (CLAUDE.md §8)

Zweite, unabhängige Instanz (Review-Agent, statisch über die Migrationen). Kein Blocker, kein Leck ans Tablet,
Rechte unverändert.

| Befund | Umgang |
|---|---|
| Engine ändert sich nur um `details` | bestätigt (diff gegen A2d/A2b) |
| `details` am Tablet | nicht erreichbar (Whitelist); pgTAP 3 |
| `schema-erwartet.sql` fehlt (mittel) | so beauftragt, Punkt 2 |
| Fenster +1/0/-2 ungetestet (niedrig) | Punkt 4 |
| Doppelausgabe einer Aufgabe zählt doppelt (niedrig) | kommt nicht vor: `session_aufgabe_waehlen` gibt eine Aufgabe nie zweimal in einer Session aus |
| Erklär-Signal als „läuft“, jüngste Sequenz (niedrig) | Punkt 6, Kommentar in der Migration |
| `fehlbild_am` über alle Skills, nur beschriftete Fehlbilder (niedrig) | Punkt 5, Kommentar in der Migration |
| Kind ohne Tablet: keine Zeile `ankommen` | pgTAP 1-0 (Kind ohne Ereignisse und ohne Tablet: `heute` leer) |
