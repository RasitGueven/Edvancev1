# Befunde K8-/K9-Vorlauf

Stand 01.10.2026. Live-DB nur gelesen (Guard `current_database() = postgres`, Sitzung read-only).
Trockenlauf in einer frischen Wegwerf-DB aus allen Migrationen (lokaler Socket, **nicht** `edvance_shadow`,
nach dem Lauf gelöscht).

## Einspiel-Reihenfolge

1. `20261001115718_tiefe_k8_vorlauf.sql`: `skills_fundament_tiefe_check` auf 1..12, Tabellenkommentar.
2. `20261001115812_substrat_k8_vorlauf.sql`: Knoten `geo_koordinaten` und `term_einsetzen`, drei Kanten, zwei Fehlbilder.
3. `20261001120554_aufgaben_k8_vorlauf.sql`: zwölf Aufgaben, Lösungen, sechs Figuraufträge.

Jede Datei klammert sich selbst mit `begin`/`commit`. Danach:

- `supabase/checks/k8_vorlauf.PRUEFUNG.sql` ausführen (V1–V9, Rollback).
- `bash tools/schema-snapshot.sh` ausführen, wegen des geänderten CHECK.
- `scripts/figures/upload_figures.py` ausführen, für die sechs Abbildungen.

## Befunde: wo die DB vom Auftrag abweicht

| Nr. | Befund | Umgang |
|---|---|---|
| B1 | `task_figures` ist in Prod **leer**. Es gibt keinen vorhandenen Koordinatensystem- oder Winkel-Auftrag für den Dry-Run. | Dry-Run gegen die Wegwerf-DB: die sechs neuen Koordinatensystem-Aufträge und ein Winkel-Testauftrag an einer Binom-Aufgabe. Ergebnis `geladen=7 fehler=0`. |
| B2 | `COORDINATE` steht zwar im CHECK, hat aber **0 Aufgaben**. Der LSA-Payload kennt nur `mc`, `short_input` und `multi_part`. | Das Koordinatenpaar läuft im vorhandenen Format `MULTI_PART` mit zwei `short_input`-Teilen (x, y). Davon gibt es im Bestand 160. Es gibt kein neues Antwortformat. |
| B3 | Teilaufgaben haben **kein Zeitbudget** (weder Spalte noch Typ noch UI, siehe `bestandsaufnahme.md`). | Die Teilbudgets stehen in `basis.zeit_teile` und in der CSV. `vorlauf-build.mjs` prüft, dass ihre Summe `est_duration_sec` ergibt. |
| B4 | `task_solution_upsert` lässt nur admin, Prüfer oder einen Systemaufruf zu. In Prod liefert `auth.role()` ohne JWT `NULL` (Systemaufruf). In der CI-Grundlage liefert es `'anon'`. Der erste Trockenlauf scheiterte deshalb mit „kein Prüfrecht“. | Migration 3 setzt `set_config('request.jwt.claim.role', 'service_role', true)`. Das gilt nur für die Transaktion und endet mit dem `commit`. |
| B5 | `lsa_normalize_answer` gleicht das Unicode-Minus „−“ nicht an das ASCII-„-“ an. | Antwortvarianten `-3`, `−3`, `- 3` und bei positiven Werten `+3`. Prüfpunkt V6 bestätigt, dass `−3` gewertet wird. |
| B6 | Stoffanker `geo_koordinaten` ist Klasse 6 (Geo-6). Negative Koordinaten setzen aber `vorzeichen_add_sub` voraus, und das ist Klasse 7. | Die Kante bildet das ab. `klasse_herkunft` bleibt 6, so wie vorgeschlagen. Aufgabe 1 kommt ohne Minus aus. |
| B7 | Der Fehlbild-Katalog hat 85 Slugs, 53 davon ohne Familie und ohne Klartext. | Wiederverwendet: `vorzeichen_potenz` (−2² statt (−2)²), `vorrang_ignoriert`, `vorzeichen_ignoriert`, `betrag_fehler`, `halbieren_vergessen`, `plus_statt_mal`. Neu: `koordinaten_vertauscht` und `koordinate_vorzeichen_verloren` (Begründung im Kopf von Migration 2). |
| B8 | `ANTHROPIC_API_KEY` wird mit **401** abgewiesen. Stufe 2 von `verify-tasks.mjs` läuft nicht. | Stufe 1 ist grün (12/12). Als Ersatz hat ein unabhängiger Löser die Aufgaben blind gelöst. Er sah nur Text und gerenderte Abbildung, die Lösungen nicht. Ergebnis 18/18 im Blind-Abgleich von `verify-prefill`. **Stufe 2 bleibt offen, bis ein gültiger Schlüssel da ist.** |
| B9 | `verify-tasks` Stufe 1, erster Lauf. **Ist:** 10 ok, 2 beanstandet („wortgleiche Dublette“). Die Aufgaben 2 und 3 hatten denselben Text wie Aufgabe 1 („… des Punktes P …“), nur die Abbildung war anders. **Soll:** 0 beanstandet. | Nur die Punktnamen geändert (P, Q, R, T). Rechnung und Lösung sind gleich geblieben. Danach 12 ok. |
| B10 | Hinweise des Blindlösers. Aufgabe 4: „liegt nicht auf einer Gitterlinie“ war sachlich falsch, T liegt auf x = 3. Aufgabe 5: Die Beschriftungen A und B verdeckten die Skalenzahlen −4 und 3. | Text geändert zu „nicht auf einem Gitterpunkt“. A und B von y = −1 nach y = −3 verschoben, D bleibt (−4\|2). Aufgabe 5 danach erneut blind gelöst: ok. |
| B11 | `pruefe_koordinatensystem` erkennt nicht, wenn eine Punktbeschriftung eine Skalenzahl überdeckt (siehe B10). | Vorschlag für einen späteren Generator-PR: Abstand zwischen Label und Achsenbeschriftung prüfen. In diesem PR nicht geändert. |
| B12 | `supabase/schema-erwartet.sql` darf nur `tools/schema-snapshot.sh` schreiben, und das Skript liest aus Prod. | Der CI-Schemavergleich bleibt **rot, bis Migration 1 eingespielt ist** und der Snapshot auf diesen Branch committet wurde. |
| B13 | `src/types/reportFundament.ts` hat den Kommentar „8 liegt am weitesten oben“. Code nimmt 8 nirgends an (`fundament.ts` rechnet mit `Math.max`). | Nur der Kommentar ist veraltet, keine Logik. Gehört ins Foundation-Fenster. |
| B14 | `k8_binomische_formeln.PRUEFUNG.sql` (B3) prüft „1..8“ nur im Bereich `term_binom_%`. | Das bleibt wahr und muss nicht geändert werden. |

## Teil 1: wer `fundament_tiefe` liest

`pg_proc` mit `prosrc ilike '%fundament_tiefe%'` findet zwei Funktionen:

- `skill_kante_tiefe_guard`: vergleicht relativ (`voraussetzt >= skill` führt zum Fehler).
- `lsa_select_next_core`: sortiert nur (`order by fundament_tiefe desc` in Schritt 3 und 4). `v_iter > 100` ist eine Iterationsbremse.

Keine Funktion nimmt 8 fest an. Views, Mat-Views und Policies lesen die Spalte nicht.

Prüfquery vor dem Einspielen: `max(fundament_tiefe) = 8`, 63 Kanten, davon würde der Guard **0** ablehnen.

## Aufgaben und AFB

`source = 'edvance_fundament_vorlauf'`, `status = 'draft'`, alle Lena-Felder in `tasks.vorbefuellt` als `neu` markiert,
`hints` als `leer` („ohne Hilfe lösbar“).

| Nr. | source_ref | Aufgabe | AFB | Begründung |
|---|---|---|---|---|
| 1 | `vorlauf-koord-01` | P ablesen, 1. Quadrant | I | Reproduzieren: Ablesen im ersten Quadranten, beide Werte positiv, ganzzahlig. |
| 2 | `vorlauf-koord-02` | Q ablesen, 2. Quadrant | I | Reproduzieren: Ablesen im zweiten Quadranten, ein negativer Wert. |
| 3 | `vorlauf-koord-03` | R ablesen, 3. Quadrant | I | Reproduzieren: beide Werte negativ, derselbe Ablauf wie in Aufgabe 2. |
| 4 | `vorlauf-koord-04` | T ablesen, 4. Quadrant, halbe Einheit | II | Zusammenhänge herstellen: Der y-Wert liegt zwischen zwei Gitterlinien und muss als halbe Einheit erschlossen werden, außerdem ist er negativ. |
| 5 | `vorlauf-koord-05` | vierter Eckpunkt D eines Rechtecks (Rückrichtung) | II | D ist nicht abzulesen. Man erschließt ihn aus den Eigenschaften des Rechtecks: x-Wert wie A, y-Wert wie C. |
| 6 | `vorlauf-koord-06` | Boot auf der Seekarte (Sachkontext) | II | Zwei Schritte verknüpfen: S ablesen, dann die Verschiebung übertragen. Das Ziel liegt im 4. Quadranten. |
| 7 | `vorlauf-einsetzen-01` | 2 · x + 5 für x = −4 | I | Reproduzieren: einen negativen Wert in einen linearen Term einsetzen. |
| 8 | `vorlauf-einsetzen-02` | 5 − 3 · x für x = −2 | I | Reproduzieren: Punkt vor Strich und Minus mal Minus sind beide geübt, kommen hier aber in einem Schritt zusammen. |
| 9 | `vorlauf-einsetzen-03` | 3 · x² für x = −2 | II | Das Quadrat gilt nur für x, und der negative Wert muss als Ganzes quadriert werden. |
| 10 | `vorlauf-einsetzen-04` | x² − 2 · x für x = −3 | II | x kommt zweimal vor. Potenz-, Vorrang- und Vorzeichenregel greifen zusammen. |
| 11 | `vorlauf-einsetzen-05` | A = g · h : 2 (Sachkontext) | II | Formel mit zwei Variablen lesen, Werte zuordnen. Das Ergebnis ist ein Dezimalwert. |
| 12 | `vorlauf-einsetzen-06` | F = 1,8 · C + 32 für C = −10 (Sachformel) | II | Sachformel lesen, einen negativen Wert mit Dezimalfaktor einsetzen, Vorrang beachten. |

Keine Aufgabe ist AFB III. Der Auftrag verlangt Fundament-Aufgaben, die ohne Hilfe lösbar sind.

## Fehlbilder je Aufgabe

| Slug | neu? | Aufgaben |
|---|---|---|
| `koordinaten_vertauscht` | neu, Familie NULL | 1–6 |
| `koordinate_vorzeichen_verloren` | neu, Familie `vorzeichen` | 2–6 |
| `vorzeichen_ignoriert` | Bestand | 7, 8, 10, 12 |
| `vorrang_ignoriert` | Bestand | 8, 9, 10, 12 |
| `vorzeichen_potenz` | Bestand | 9, 10 |
| `betrag_fehler` | Bestand | 7, 12 |
| `halbieren_vergessen`, `plus_statt_mal` | Bestand | 11 |

## Sondierrang

Verfahren aus `docs/sondierrang_vorschlag.md`, Profil = Menge der Slugs. Bei MULTI_PART zählen die Slugs aller Teile.

- `geo_koordinaten`: Rang 1 `vorlauf-koord-02`, Profil {vertauscht, vorzeichen_verloren}. Rang 2 `vorlauf-koord-01`, Profil {vertauscht}.
  Mehr als zwei Fehlbilder gibt es hier nicht. Rang 2 kommt deshalb aus einem echten Teilprofil, wie es das Verfahren für diesen Fall vorsieht.
- `term_einsetzen`: Rang 1 `vorlauf-einsetzen-04`, Profil {vorrang, vorzeichen_ignoriert, vorzeichen_potenz}. Rang 2 `vorlauf-einsetzen-05`,
  Profil {halbieren_vergessen, plus_statt_mal}, das sind zwei neue Fehlbilder.

## Offen für Lena und Rasit

1. **Familie für `koordinaten_vertauscht`:** Keine der fünf Familien passt. Eine neue Familie bräuchte einen Elterntext und eine Abnahme.
2. **Klartexte der zwei neuen Fehlbilder abnehmen** (`freigegeben_am` ist NULL).
3. **Gültigen `ANTHROPIC_API_KEY` hinterlegen**, damit Stufe 2 von `verify-tasks` nachläuft (B8).
4. Abbildungen hochladen (`upload_figures.py`). Bis dahin liefert der Payload für die sechs Koordinaten-Aufgaben **kein Bild**, und sie sind nicht lösbar. Status `draft` schützt davor, dass sie ausgespielt werden.

## Prüfprotokoll

| Prüfung | Ergebnis |
|---|---|
| `verify-tasks.mjs --prefill` (Constraints, Vollständigkeit, exakte Nachrechnung, Blind-Abgleich) | 0 Charge-Fehler, 18/18 Nachrechnungen, 18/18 Blind-Abgleich → `k8-vorlauf-verifikation.md` |
| `verify-tasks.mjs` Stufe 1 (Struktur) | 12 ok, 0 beanstandet (erster Lauf: 2 Dubletten, siehe B9) |
| `verify-tasks.mjs` Stufe 2 (LLM-Blindlöser) | **nicht gelaufen**: HTTP 401 (B8) |
| Trockenlauf: begin → M1, M2, M3 → V1–V9 → rollback | alle neun Prüfpunkte ok. Nach dem Rollback gilt wieder der alte Stand (43 Skills, CHECK 1..8). |
| Einspielen wie Rasit (je Datei mit eigenem begin/commit), dann Prüfskript und Zweitlauf | ok, V1–V9 ok, Zweitlauf ohne Änderung (idempotent) |
| Endstand Wegwerf-DB gegen Charge | 12 Aufgaben, 264 Feldvergleiche, 0 Abweichungen |
| DML von M2 und M3 als `EXPLAIN` gegen Prod (read-only) | 34/34 Anweisungen geplant, keine Kollision mit IDs, Herkunft, Skills oder Slugs |
| `upload_figures.py --dry-run` (6 Koordinatensystem + 1 Winkel) | `geladen=7 uebersprungen=0 fehler=0` |
| `pytest scripts/figures/` | 91 passed |

## Dateien

| Datei | Inhalt |
|---|---|
| `k8-vorlauf.json` | **Quelle**: Charge-Format plus `basis` (Text, Teile, known_errors, Figur) |
| `k8-vorlauf-snapshot.json` | Rohzustand für `verify-prefill`, aus `basis` erzeugt |
| `k8-vorlauf.csv` | Für Lena: jedes gesetzte Feld mit Unsicherheit und Begründung, dazu known_errors, Sondierrang, Figuren, Teilbudgets |
| `k8-vorlauf-blind.json` | Antworten des unabhängigen Lösers |
| `k8-vorlauf-verifikation.md` | Protokoll von `verify-tasks.mjs --prefill` |

Neu erzeugen: `node tools/vorlauf-build.mjs docs/prefill/k8-vorlauf.json 20261001120554 aufgaben_k8_vorlauf`
