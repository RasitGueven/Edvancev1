# SF-1 · Fortschritt

| Datum | Phase | Schritt | Ergebnis |
|---|---|---|---|
| 13.11.2026 | S0 | Worktree `../Edvancev1-SF1` ab `origin/dev` @ `75489322` | angelegt |
| 13.11.2026 | S0 | IU-1 U1 auf `origin/dev`? | nein (`docs/inhalte/iu1/fortschritt.md` fehlt) → S2 wartet, S3 vorgezogen |
| 13.11.2026 | S0 | Schulverzeichnis NRW (Open Data) abgerufen | Köln 20 RS, 25 GE, 0 SK, 0 Primus; Kerpen 1 GE |
| 13.11.2026 | S0 | Übergangsregel KLP 2022 | RdErl. 02.06.2022 bestätigt: Kl. 10 2026/27 = KLP 2004 |
| 13.11.2026 | S0 | `ist-analyse.md` | geschrieben |
| 13.11.2026 | S0 | PR #413 | CI `quality` grün, `neuaufbau` rot (Runner-Image, s. u.) → nicht gemergt |
| 13.11.2026 | S1 | Migrationen `20261113082727_sf1_schulformen_kurs`, `20261113082851_sf1_schulen` | geschrieben, PR #414 |
| 13.11.2026 | S1 | pgTAP `sf1_schulformen` 39/39, volle Suite lokal grün bis auf die 8 aus `bekannt-rot.txt` | grün (X0b/X0c fingen eine offene Rollenprüfung, korrigiert) |
| 13.11.2026 | S1 | Zweitprüfung (frischer Subagent) | 3× „falsch“ (Rollback-Guards, `erfasst_am` fälschbar) behoben; Gegenprüfung ohne „falsch“/„bricht“ |
| 13.11.2026 | S1 | Rollbacks in Wegwerf-DB ausgeführt | Guards greifen; RB2+RB1 → Schema = `origin/dev` |
| 13.11.2026 | S1 | Einspielen | **angehalten**: CI `neuaufbau` rot (nur `pg_attver`-Zeilen, „erwartet, nicht erzeugt“ leer) |
| 13.11.2026 | S3 | Intake, Vertrag, Akte; Ansichtstests 16/16; Vitest 3383 | PR #415 (Entwurf, hängt an #414) |
| 13.11.2026 | S2/S4 | IU-1 U1/U2 nicht auf `origin/dev` | warten |
| 13.11.2026 | – | Wiederaufnahme nach WSL-Neustart: Worktree sauber, Prod ohne SF-1-Migration | nichts halb eingespielt |
| 13.11.2026 | – | IU-1 #417 „CI: pg_attver im Schema-Vergleich ignorieren“ in `dev` | Haltepunkt aufgehoben |
| 13.11.2026 | S0–S3 | `origin/dev` eingemischt (Force-Push per Hook gesperrt, daher Merge statt Rebase) | CI grün (#414: `session_a2` Test 15 mit 200,2 ms, Neulauf grün) |
| 13.11.2026 | S0 | PR #413 | gemergt |
| 13.11.2026 | S1 | `20261113082727_sf1_schulformen_kurs`, `20261113082851_sf1_schulen` per `~/bin/mig` in Prod | eingespielt; 90 Schulen, 46 mit Schulnummer, Trigger `kind_kurs_von_lead` da |
| 13.11.2026 | S1 | Prod-Abzug gegen `schema-erwartet.sql` | alle SF-1-Zeilen da, alte CHECKs weg; übrige Abweichung nur IU-1 U1 (in Prod vor `dev` eingespielt, #416 offen) |
| 13.11.2026 | S1 | PR #414 | gemergt |
| 13.11.2026 | S3 | Vertrag: Hinweis, wenn die Lead-Angabe zum Mathe-Kurs beim Abschluss verfällt (`KursHinweis`, ohne Schemaänderung) | Vitest 2/2, Typecheck grün |

## Haltepunkt 13.11.2026 (aufgehoben durch #417)

`neuaufbau` ist seit dem Runner-Image `ubuntu26/20261101.186` für jede PR rot (auch IU-1 #412): `pg_dump` gibt
`ALTER TABLE ONLY … ALTER COLUMN … SET (pg_attver=…)` aus. Abhilfe unter `.github/workflows/schema.yml` (darf SF-1
nicht ändern): `pg_attver` in den `grep -vE`-Filter beider Seiten aufnehmen oder `runs-on: ubuntu-24.04` pinnen.

## Offene Punkte S1 (aus der Zweitprüfung)

- Lead trägt nur den Mathe-Kurs; E/G für Englisch/Deutsch am Lead nicht erfassbar (`kind_kurs` kann es).
- `stadtteil` der 46 neuen Schulen leer (Verzeichnis hat keinen); Gymnasien ohne Schulnummer.
- ~~Hat ein Kind schon eine Mathe-Zeile, verfällt die Lead-Angabe beim Vertrag still.~~ Erledigt: Der Vertrag zeigt
  den Hinweis, wenn Lead und Akte abweichen (#415).
- Abschluss ESA (nach Kl. 9) nicht erfassbar (nicht verlangt).
- Kerpener und Kölner Willy-Brandt-Gesamtschule tragen den Ort im Namen (Abweichung vom amtlichen Namen, damit die
  Freitext-Zuordnung der LSA nie die falsche Schule trifft).
