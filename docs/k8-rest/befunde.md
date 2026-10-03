# K8-Rest – Befunde

Stand 03.10.2026 · Branch `feat/k8-rest` · Auftrag `W4-k8-rest.md`.
Entscheidungen: [entscheidungen.md](entscheidungen.md). Einspielen: [einspielen.md](einspielen.md).

## Für Lenas Planung: Aufgaben je Thema

Alle Aufgaben `draft`, mit Kennzeichen `vorbefuellt` (Werte und Gründe je Feld in der CSV),
ohne Hinweise, `class_level` 8, Stoffanker 8.

| Thema | Knoten | Aufgaben | davon mit Figur | Formate | CSV zur Prüfung |
|---|---|---|---|---|---|
| Lineare Gleichungssysteme | 5 | **30** | 5 | 22 MULTI_PART x\|y, 4 MC, 4 MULTI_PART mc\|x\|y | `docs/prefill/k8-lgs.csv` |
| Daten und Wahrscheinlichkeit | 5 | **30** | 0 | 30 NUMERIC | `docs/prefill/k8-stoch.csv` |
| Flächen | 5 | **30** | 0 | 26 NUMERIC, 4 MC | `docs/prefill/k8-flaeche.csv` |
| Thales und Winkelsätze | 4 | **24** | 2 | 24 NUMERIC | `docs/prefill/k8-winkel.csv` |
| **Summe** | **19** | **114** | **7** | | |

Dazu 36 Kanten, 17 neue Fehlbilder (unfreigegeben, Klartext + Erklärung für Eltern) und 9
Einstiege in 5 Themen.

## Prüfprotokoll (Teil 4)

| Stufe | Ergebnis |
|---|---|
| Nachrechnen beim Erzeugen | je Thema Charge-Skript, exakt mit `prefill-rechnen` (jede Antwort, jeder falsche Wert, Schreibweisen-Kollisionen) |
| verify-prefill | **0 Charge-Fehler** in allen vier Chargen (`docs/prefill/k8-*-verifikation.md`) |
| Struktur (verify-tasks Stufe 1) | 114 ok, 0 beanstandet |
| Blind-Löser LGS | frischer Subagent: **30/30** |
| Blind-Löser Flächen | frischer Subagent: **30/30** |
| Blind-Löser Winkel | frischer Subagent: **24/24** |
| Blind-Löser Stochastik | Lauf 1: 28/30. `laplace-05` Ist „20“, Soll „20 %“; `gegenereignis-04` Ist „3/8“, Soll „5/8“. Lauf 2 (frischer Subagent, nur diese zwei): „20“ und „0.625“. `gegenereignis-04` damit Rechenfehler von Lauf 1, Aufgabe richtig. `laplace-05`: beide weichen ab → **Aufgabe korrigiert** (nackte Prozentzahl gilt, Regel für alle elf Prozent-Aufgaben). Lauf 3 (frischer Subagent, ganze Charge): **30/30** |
| Wegwerf-DB (frisch, Grundlage + 100 Migrationen + 9 neue) | eingespielt ohne Fehler; zweiter Lauf der 9 Dateien: Zeilenzahlen gleich → **idempotent** |
| Tiefen-Guard | hält (jede neue Kante echt flacher, Prüfzeile in allen vier Substrat-Skripten) |
| Prüfskripte lokal (`-v lokal=true`) | 9 Dateien, **0 rote Zeilen** (8+9+6+8 Substrat, 22+18+19+21 Aufgaben, 6 Einstieg) |
| Prüfskripte gegen Prod (dbread) | laufen fehlerfrei read-only (vor dem Einspielen erwartbar rot) |
| Figuren | `upload_figures.py --dry-run` gegen die Wegwerf-DB: geladen=19 (7 neue + 12 Alt-Zeilen ohne Hash lokal), **fehler=0** |
| Schema | `pg_dump --schema-only` Basis-DB vs. Gesamt-DB: identisch (nur die zufälligen `\restrict`-Tokens) → reine Datenmigrationen |
| Frontend | `npx tsc --noEmit` exit 0, `npm run typecheck` ok, `npm run lint` 0 Warnungen, `npm run test` 674/674 (67 Dateien) |

Kein Schreibbefehl gegen Prod, auch kein Trockenlauf mit rollback. Gelesen nur über `~/bin/dbread`.

## Abweichungen vom Auftrag bzw. von phase1

1. **Werkzeuge erweitert** (`vorlauf-build.mjs`, `blind-loeser/exportiere.mjs`): Ohne das wären
   Dateien ohne begin/commit in CI rot geworden und MC-Aufgaben für den Blind-Löser unlösbar
   (H1, H2). Alte Chargen erzeugen byte-gleiche Migrationen.
2. **Sechs Alt-Slugs über die phase1-Liste hinaus** wiederverwendet (H6).
3. **Thema 4 bedient zwei Themen-Keys** (`winkel_dreiecke`, `thales_konstruktionen`).
4. **LGS-Sachknoten:** Der MC-Teil „Welches System passt?“ ist Teil 1, x und y sind Teil 2 und 3
   (phase1 nannte x = Teil 1 als Regel für reine LGS-Aufgaben).

## Offene Punkte

### Für Lena (fachlich)
1. **Sondierrang auf MC-Aufgaben (LGS):** Bei gleichsetzen, addition und grafisch landet Rang 2 auf
   der MC-Aufgabe zur Lösungsanzahl (breitestes neues Profil). Das ist algorithmisch korrekt, aber
   die Ratewahrscheinlichkeit liegt bei 1/3. Soll eine Zahlaufgabe Rang 2 tragen?
2. **Quartile:** Die Reihen sind so gewählt, dass alle Schul-Definitionen übereinstimmen. Soll die
   Plattform eine Definition festlegen?
3. **Wenig Fehlbilder:** Für Spannweite (Stochastik) und „falscher Winkel gewählt“ (Parallelen)
   gibt es keine Slugs. Rang 2 bei `geo_winkel_parallelen` hat nur ein Profil-Slug.
4. **Alt-Slugs ohne Klartext** tragen viele known_errors (`halbieren_vergessen`, `plus_statt_mal`,
   `summe_360_statt_180`, `differenz_vergessen` …), offener Punkt aus `specs/active/fehlbild-labels-eltern.md`.
5. **`stoch-pfad-produkt-06`:** „0,1“ für 0,1 % wird als falsch gewertet (als Dezimalzahl wäre es 10 %).
6. **MC-Optionen ohne Slug** (`flaeche-term-01` d, `-04` b, d): Eine falsche Wahl wird nur als falsch
   gewertet, ohne Fehlbild.
7. Einige Fehlbild-Werte sind im Sachkontext unplausibel (LGS: -70 Karten). Sie sind genau das
   Ergebnis des Fehlers; die sokratische Frage greift das auf.

### Technisch / spätere Läufe
8. **Generatoren fehlen:** Polygone/Strecken (Trapez, Drachen, zusammengesetzte Figuren, Flächen im
   Koordinatensystem), Parallelen mit Schnittgerade, Dreieck, Thaleskreis, Baumdiagramm, Boxplot.
   Die Text-Aufgaben sind lösbar, aber lesehaltig; Darstellungskompetenz (Sto-4, Geo) ist so nicht prüfbar.
9. **TERM-Voraussetzungen ohne known_errors** (`term_minusklammer`, `term_zusammenfassen`,
   `term_ausmultiplizieren`): Der Abstieg von LGS-Einsetzen und Flächen-Term dorthin liefert nur
   richtig/falsch. Nicht aufgefüllt (phase1 c).
10. **Gleiche Tiefe verhindert Kanten:** `gleichung_lgs_einsetzen` (7) kann nicht unter
    `gleichung_neg_koeffizient` (7) hängen, obwohl `einsetzen-04` durch -10 teilt.
11. **Einstiege wirken erst mit ready-Aufgaben.** Bis Lena die Entwürfe freigibt, wählt die LSA
    für diese fünf Themen wie bisher ohne Thema.
12. `stoch_kenngroessen` hat keinen Themen-Einstieg (Daten gehört zu `daten_streumasse` Kl. 5 /
    `statistik_beurteilen` Kl. 9).
13. In beiden `winkel`-Figuren steht das Label α außerhalb des Bogens (Generator-Regel), laut
    Blind-Löser nicht mehrdeutig.
