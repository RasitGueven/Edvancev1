# Offene Punkte V1 (Vitest unter Last)

Stand 08.10.2026 · Branch `feat/rasit-v1-vitest-last`

## Messaufbau

- Maschine: 10 Kerne, 7,7 GB RAM, 2 GB Swap (WSL).
- Last: zwei weitere volle Vitest-Läufe in einer Schleife aus einem zweiten Worktree, wie zwei Agenten, die gleichzeitig ihr
  Gate laufen lassen. Gemessen wird ein voller Lauf in diesem Worktree, Ergebnis je Datei über den JSON-Reporter.
- Skripte (nicht im Repo, Scratchpad): `lastlauf.sh <anzahl> <tag>` (Last starten, Läufe protokollieren, Last beenden),
  `messen.sh` (Dauer und Spitzen-RSS der Worker ohne Last).

## Vorher: fünf Läufe, alte Konfiguration überall

| Lauf | Last | Tests | rote Dateien | Worker nicht gestartet |
|---|---|---|---|---|
| 1 | 35 | 1 rot, 999 grün | `Umstieg.test.tsx` | 0 |
| 2 | 41 | 4 rot (986 gelaufen) | `coachLiveRoute`, `Expertenliste`, `AdminPruefansichtPage`, `Umstieg` | 3 |
| 3 | 45 | 27 rot (989 gelaufen) | 13 Dateien, u. a. `prefill`, `verify-tasks-dateiquelle`, `HeutePage`, `VertragDetailPage`, `PruefansichtPage`, `Umstieg` | 2 |
| 4 | 60 | 13 rot (680 gelaufen) | 10 Dateien, u. a. `AuthoringPreview`, `CoachLivePage`, `Umstieg` | 27 |
| 5 | 68 | 7 rot (639 gelaufen) | 7 Dateien, u. a. `LeadFilterBar`, `ZugangscodeFeld`, `Umstieg` | 36 |

- Swap während der Läufe voll (2047 von 2048 MB), freier RAM ~110 MB.
- Fehlerarten: fast alles „Test timed out in 5000ms“ (einzelne Tests bis 192 s), dazu „Failed to start forks worker … Timeout
  waiting for worker to respond“. Diese Dateien fehlen im Ergebnis ganz; daher die schwankende Testzahl.
- `Umstieg.test.tsx` ist in allen fünf Läufen rot, in Lauf 1 als einzige Datei, bevor der Speicher knapp wurde.

## Ursache je Datei

1. **Alle Dateien außer `Umstieg`: Speicher und CPU überbucht.** Vitest startet standardmäßig Kerne − 1 = 9 Forks mit je
   ~200 MB (jsdom). Drei gleichzeitige Läufe = 27 Forks auf 10 Kernen und ~6 GB Worker-Speicher → Swap, Worker starten
   nicht, Tests laufen ins 5-s-Limit. Ohne Last braucht der langsamste Test 861 ms (`prefill`), also ~6-fachen Puffer.
   Kein fehlendes `await`, kein geteilter Zustand, keine echte Zeit statt Fake-Timer gefunden: Die Dateien sind einzeln und
   in allen zehn Abnahmeläufen grün, ohne dass an ihnen etwas geändert wurde.
   - `tests/prefill.test.ts` und `tests/verify-tasks-dateiquelle.test.ts`: reine Rechen- bzw. Dateiarbeit, kein Ereignis zum
     Warten; rot nur bei vollem Swap.
   - `AdminPruefansichtPage.test.tsx` (offene-punkte-l6 17): wartet schon auf Ereignisse (`findBy…`, `waitFor`); rot nur, wenn
     der ganze Test die 5 s überschritt.
2. **`Umstieg.test.tsx`: teure Abfrage im Warten.** `findByRole('link', { name })` berechnet bei jedem Versuch die
   zugänglichen Namen der ganzen App (Navigation plus Seite). Gemessen ohne Last: `getByRole` 33 ms, `getByText` 3 ms je
   Aufruf (237 Elemente). Unter Last schafft `findByRole` in seinem 1-s-Fenster kaum einen Versuch.

## Änderungen

1. `vitest.config.ts`: `maxWorkers: 4`. Gemessen ohne Last:

   | Worker | Dauer | Spitzen-RSS der Worker |
   |---|---|---|
   | Standard (9) | 45 s | 2026 MB |
   | 4 | 48 s | 978 MB |

   Drei Agenten gleichzeitig: 12 statt 27 Forks, ~3 statt ~6 GB.
2. `src/pages/admin/pruefen/Umstieg.test.tsx`: erst `findByText` auf den Linktext (das Ereignis), dann einmal
   `getByRole('link', { name })` und dieselbe `href`-Zusicherung. Kein Limit erhöht, keine Zusicherung entfernt.

## Nachher: zehn Läufe

Last wie vorher (zwei parallele volle Läufe), die Nachbarläufe mit `--maxWorkers=4` wie nach dem Merge:

| Lauf | Last | Tests | rot | Worker nicht gestartet | Dauer |
|---|---|---|---|---|---|
| 1 | 18,2 | 1000/1000 | – | 0 | 120 s |
| 2 | 19,7 | 1000/1000 | – | 0 | 113 s |
| 3 | 19,8 | 1000/1000 | – | 0 | 110 s |
| 4 | 18,8 | 1000/1000 | – | 0 | 111 s |
| 5 | 19,1 | 1000/1000 | – | 0 | 105 s |
| 6 | 19,0 | 1000/1000 | – | 0 | 105 s |
| 7 | 22,5 | 1000/1000 | – | 0 | 108 s |
| 8 | 18,4 | 1000/1000 | – | 0 | 109 s |
| 9 | 19,4 | 1000/1000 | – | 0 | 103 s |
| 10 | 21,7 | 1000/1000 | – | 0 | 107 s |

Alle 112 Dateien in jedem Lauf.

## Offen

1. **Wirkung erst nach dem Einmischen.** Die Grenze steht im Repo. Worktrees, die `dev` noch nicht eingemischt haben,
   starten weiter 9 Forks und belasten die Nachbarn. Gemessen (drei Läufe, dieser Lauf mit 4 Forks, die zwei Nachbarläufe
   mit dem alten Standard, Last 32–34): 3 × 1000/1000 grün, alle 112 Dateien, kein Worker-Startfehler. Mehr als diese
   drei Läufe sind für die gemischte Lage nicht belegt.
2. **„Ein weiterer“ aus offene-punkte-t1** ist nicht mehr bestimmbar (damals nicht festgehalten). In den fünf
   Ausgangsläufen lag jede rote Datei außer `Umstieg` an Swap und Worker-Start.
3. **`findByRole` auf der ganzen App:** Außer `Umstieg` rendert nur `coachLiveRoute.test.tsx` `<App />`, und es fragt nicht
   per `findByRole`. Kommt das Muster in einem neuen Test vor, gleiches Vorgehen wie in `Umstieg`.
4. **Mehr als drei gleichzeitige Gates** sind nicht gemessen. Bei vier oder mehr Agenten wäre `maxWorkers: 3` oder ein
   Wert in Prozent zu prüfen.
