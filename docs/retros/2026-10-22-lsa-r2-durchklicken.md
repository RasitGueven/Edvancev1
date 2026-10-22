# Retro 22.10.2026 · LSA-R2 Durchgeklickte LSA erkennen

Bauauftrag `docs/lsa/Bauauftrag-LSA-R2.md`, Auswertung `docs/lsa/durchklicken-auswertung.md`.

## Gebaut

- **Migration `20261022131037_lsa_durchklicken`** (geschrieben, nicht eingespielt):
  - `lsa_durchklick_stand(session)` mit den Schwellen als Konstanten (5 s, Folge 5, 40 % ab 10 Antworten,
    Hinweis nach 3). Liefert die geforderten Kennzahlen und zusätzlich `schwellen`, damit Aufrufer
    (`platz_submit`, Admin „Heute“, Report-Texte) die Grenzen nie selbst kennen.
  - `lsa_sessions.auswertbar` (Default true, kein Backfill), `nicht_auswertbar_grund`, `hinweis_tempo_am`.
  - `lsa_finish` setzt beide Spalten in derselben Anweisung wie `completed`; `result_summary.durchklick`.
  - `platz_submit` gibt `hinweis_tempo` zurück, `ok` und `next` unverändert.
- **pgTAP** `lsa_durchklicken` (43 Zusicherungen, D1–D9), `lsa_finish_themenraum` kennt den achten Schlüssel.
- **Testkinder:** Profile nach `kinder.sql`, siebtes Kind Tim (2–4 s, fast alles falsch, 30 Aufgaben).
  `lsa_testkinder` 51 Zusicherungen.
- **Frontend:** `lsaDurchklick.ts`; Kennzeichen und gesperrte Präsentation in „LSA-Reports“; ReportPage mit
  Hinweisbalken, „LSA wiederholen“ und der Ein-Seiten-Fassung des Bogens; Badge „schnell“ in „Heute“.
- Texte für Lena: `docs/lsa/lsa-r2-texte.md`. Fotos: `docs/screenshots/lsa-r2/`.

## Entscheidungen

- **Rechte über ein transaktionslokales Flag.** `lsa_durchklick_stand` prüft wie die übrigen LSA-Funktionen
  `lsa_may_act_for`, lässt aber das Kind selbst nicht zu (nur admin/coach). `lsa_finish` und `platz_submit`
  rufen sie mit `edvance.lsa_intern = '1'` (wie `edvance.allow_provisional`), weil `lsa_finish` laut
  `lsa_may_act_for` auch vom Kind selbst aufgerufen werden darf. Ein PostgREST-Client kann dieses Flag nicht setzen.
- **Reihenfolge = Abgabezeit, bei Gleichstand task_id.** Echte Abgaben sind eigene Transaktionen. In Tests und
  im Testkinder-Generator haben alle Zeilen dieselbe Zeit; der pgTAP-Test trägt deshalb feste Zeiten ein bzw.
  rückt nach jedem `platz_submit` die Zeiten zurück.
- **„leer“** (nichts eingegeben) ist keine schnell falsche Antwort und unterbricht die Folge; für den Hinweis
  zählt sie als schnelle Abgabe (nur WN ist ausgenommen). In Prod kam „leer“ bisher nicht vor.
- **Liste ohne langen id-Filter:** `loadNichtAuswertbar()` fragt nur `auswertbar = false` ab, eigene Abfrage,
  damit die Liste ohne Migration weiter lädt.
- **„LSA wiederholen“** führt nach `/admin/leads?lead=<id>`: die Lead-Maske öffnet im Erstgespräch, dort steht
  „LSA freigeben“ (`lead_lsa_freigeben`). Dafür ein kleiner Parameter in `LeadsPage.tsx` (außerhalb der im
  Auftrag genannten Dateien, analog `?neu=1`). Coaches sehen den Knopf gesperrt (Freigabe ist admin-only).
- **`Seite.tsx` bekommt `gesamt`** (Fuß „1 / 1“, ohne die fünf Navigationspunkte). Ebenfalls außerhalb der
  genannten Dateien, aber ohne das wäre der Druck „1 / 5“.
- **Tim endet nach 30 Aufgaben** (`hoechstens`): bei 3 s je Aufgabe wären 19 Minuten mehrere hundert Aufgaben,
  der Generator bricht über 200 ab.

## Geprüft

- Wegwerf-DB (eigener Cluster, Port 55441) aus allen Migrationen + Seed: pgTAP-Suite 66 grün, die 8 aus
  `bekannt-rot.txt` rot wie vorher.
- `npm run typecheck && npm run lint && npm run test`: 218 Dateien, 2385 Tests grün.
- Prod per dbread vorgerechnet (dieselbe Regel als SQL): von 31 Sitzungen mit Antworten wäre genau eine nicht
  auswertbar, die Klick-LSA (135 Antworten, 101 schnell falsch, 75 %, Folge 15, Grund „folge“). Den Hinweis
  hätte ebenfalls nur sie bekommen (längste schnelle Folge sonst höchstens 2).
- Zweitprüfung (unabhängige Instanz, nur lesend): **freigabefähig**, kein hoher Befund. Umgesetzt: Coach-Rechte
  getestet (mit und ohne aktive Akte), kein zweiter Hinweis nach Unterbrechung und neuer Folge, reine Klickkette
  bei der fünften Antwort nicht auswertbar (39 → 43 Zusicherungen). Offen gelassen und hier dokumentiert:
  Eltern-Leserecht auf die Kennzahlen, „leer“ zählt für den Hinweis als schnell, Anzeige des Anteils auf zwei
  Stellen gerundet (die Regel rechnet mit den Zählern), `\restrict`-Zeilen fallen im Schema-Abzug weg wie bei
  `tools/schema-snapshot.sh`.

## Offen

- Einspielen der Migration (Befehl im PR), danach `tools/schema-snapshot.sh`.
- edvance-app: `hinweis_tempo` lesen und den ruhigen Hinweis zeigen (eigener PR, Vertrag im PR-Text).
- LSA-V2: Deckel 40 Aufgaben.
- Schwellen nach den ersten 20 echten LSAs erneut prüfen (Abfrage aus der Vorrechnung wiederverwendbar).
- Ein Lead, der schon konvertiert ist, kann über `lead_lsa_freigeben` keine neue LSA bekommen; „LSA wiederholen“
  öffnet dann die Maske, die Freigabe scheitert dort mit Meldung.
- Eltern lesen `lsa_sessions` per Policy zeilenweise, also auch `auswertbar` und die Kennzahlen. Es gibt dafür
  noch keine Elternfläche.
