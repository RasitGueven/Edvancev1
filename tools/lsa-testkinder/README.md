# LSA-Testkinder (LSA-T)

Sieben erfundene Kinder (Klasse 7, 8, 9) spielen je eine vollständige LSA durch die echte Auswahl und
Wertung, mit festem Antwortprofil von „macht nichts falsch“ bis „sehr, sehr schwach“, dazu ein Kind, das sich
durchklickt. Danach liegt für jedes
Kind ein Report unter `/admin/report/<sitzung>?fassung=r7`. Bauaufträge: `docs/lsa/Bauauftrag-LSA-T.md`,
`docs/lsa/Bauauftrag-LSA-T2.md` (Max, Schalter `nur`), `docs/lsa/Bauauftrag-LSA-R2.md` (Tim).

| Kind | Klasse | Schule | Thema | Profil |
| --- | --- | --- | --- | --- |
| Lina Berger | 9 Gymnasium | FWG (Schulplan) | Quadratische Funktionen | alles sicher, ein Ausrutscher (Fläche Dreieck); im Ausblick nur Kreise sicher, Potenzen und Pythagoras nicht |
| Emre Kaya | 9 Gymnasium | FWG (Schulplan) | Reelle Zahlen und Wurzeln | sicher bis auf Wurzelgesetze und teilweises Wurzelziehen, Fehlbild „Wurzel einer Summe“ |
| Sophie Wagner | 8 Realschule | ohne Plan | Lineare Funktionen | Klasse 7/8 falsch (Steigung vertauscht), Koordinaten unsicher, bis Klasse 6 sicher |
| Jonas Richter | 8 Gesamtschule | ohne Plan | Terme und Gleichungen | Klasse 7–10 „Weiß ich nicht“, bis Klasse 6 falsch (Vorzeichen) |
| Nele Schmitz | 7 Gymnasium | ohne Plan | Prozent- und Zinsrechnung | Prozentwert sicher, Grundwert und Prozentsatz falsch, Brüche teils |
| Max Hoffmann | 8 Gymnasium | FWG (Schulplan) | Lineare Funktionen | nichts falsch: jede Aufgabe kanonisch richtig, auch Vorschau, Rückblick, Zweitbeleg; im Ausblick nur Binomische Formeln sicher, Zufall und Flächen nicht |
| Tim Schuster | 8 Gesamtschule | ohne Plan | Terme und Gleichungen | klickt sich durch: 2–4 s je Aufgabe, fast alles falsch, ohne feste Grenze: höchstens 40 Aufgaben (Deckel, LSA-V2); seine LSA ist **nicht auswertbar** |

Die Profile stehen als Daten in `kinder.sql` (`grund` je Klassenstufe, `ausnahmen` je Skill,
bevorzugtes Fehlbild, Antwortdauer, optional `hoechstens` = Zahl der Aufgaben); `erzeugen.sql` bindet sie mit
`\ir kinder.sql` ein.

LSA-V2 (`docs/lsa/Bauauftrag-LSA-V2.md`): Max und Lina können vom Stoff, der als Nächstes kommt, nur das erste
kommende Plan-Thema. Die Einstiege der zwei Themen danach stehen in `ausnahmen` auf `uebung`. So zeigt jeder Lauf
den Ausblick und seinen Stopp (zwei Ausblick-Knoten hintereinander nicht sicher). Tim braucht `hoechstens` nicht
mehr: Seine LSA endet, wenn die Auswahl leer ist, spätestens beim Deckel 40.

## Was das Skript tut

`erzeugen.sql` ist reines SQL ohne DDL und läuft in einer Transaktion.

1. Legt je Kind einen Test-Lead mit Erstgespräch an (Phantasiedaten, Eltern-E-Mail
   `<vorname>@example.invalid`, keine Verträge) und den provisorischen Schüler mit fester UUID
   (`a5a7c41d-1ead-…` Leads, `a5a7c41d-5c00-…` Schüler). Ein zweiter Lauf aktualisiert nur die Angaben.
2. Setzt das aktuelle Thema (`lead_thema_setzen`), die behandelten Themen und das Anliegen
   (`lead_assessment_upsert`).
3. Gibt die LSA frei (`lead_lsa_freigeben`), beantwortet jede Aufgabe über `lsa_submit` und schließt mit
   `lsa_finish` ab — als bestehender Admin über `request.jwt.claims`, wie die App. Wertung, Urteile,
   Fehlbilder und `result_summary` entstehen ausschließlich in diesen Funktionen.
4. Simuliert die Uhr: `started_at` der neuen Sitzung wird vor der ersten Antwort um 20 Minuten
   zurückgesetzt, jede Antwort trägt `p_jetzt` = Beginn + bisherige Antwortdauern. Die Auswahl rechnet
   nur mit diesem Abstand, also genau wie bei einem Kind, das so lange braucht.
5. Gibt je Kind eine NOTICE (Profil, Abweichungen vom Profil) und am Ende die Tabelle aus:
   Kind · Klasse · Thema · Sitzung · Status · Aufgaben gesamt · davon ready · sicher · Übungsbedarf ·
   ohne Ansatz · auswertbar · Fehlbilder · Report-Pfad. Gezählt werden direkt geprüfte Bereiche. Die Tabelle zeigt nur
   die Kinder, die gelaufen sind.
6. Nimmt die Wertung eine ganz richtige Antwort nicht als richtig an (`lsa_responses.correct` nicht true),
   bricht der Lauf nicht ab: je Fall eine NOTICE `LSA-T: richtig beantwortet, nicht angenommen` mit
   task_id, skill_key, input_type und der gesendeten Antwort, ohne Kindername. Ist Max gelaufen, folgt
   nach der Tabelle seine Liste „richtig beantwortet, nicht angenommen“. Jeder Eintrag ist ein
   Inhaltsfehler für Lena; leer heißt: alles angenommen.

Gezogen wird aus dem Testkonto-Pool (`students.ist_test` → Entwürfe ohne Prüfausschluss), weil noch wenig
auf „ready“ steht; „davon ready“ zeigt, wie viele der gezogenen Aufgaben schon freigegeben sind.

## Starten

Erst prüfen, dass `DATABASE_URL` auf den Supabase-Pooler und die Datenbank `postgres` zeigt (`dbcheck`
prüft das nicht), dann laufen lassen. Alle sieben Kinder:

```bash
[[ "$DATABASE_URL" == *pooler.supabase.com* ]] && \
psql "$DATABASE_URL" -tAc "select current_database()" | grep -qx postgres && \
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f tools/lsa-testkinder/erzeugen.sql
```

Nur einzelne Kinder mit `-v nur=…` (Vorname, mehrere mit Komma, z. B. `-v nur=Max,Lina`):

```bash
[[ "$DATABASE_URL" == *pooler.supabase.com* ]] && \
psql "$DATABASE_URL" -tAc "select current_database()" | grep -qx postgres && \
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -v nur=Max -1 -f tools/lsa-testkinder/erzeugen.sql
```

Ein unbekannter Name bricht vor dem ersten Schreiben ab (`LSA-T: unbekannte Kinder in nur: …`, mit der
Liste der bekannten). Ohne `-1` läuft jeder Block für sich; dann bleibt bei einem Fehler ein halber Stand
stehen.

## Erneut laufen lassen

Jeder Lauf legt je Kind eine **neue** Sitzung an und löscht nichts (Rohdaten bleiben append-only). Die
Tabelle nennt die Sitzung dieses Laufs.

- **Nach LSA-V (neue Auswahl):** einfach erneut starten. Die neuen Sitzungen zeigen die neue Auswahl an
  denselben Kindern; die alten Sitzungen bleiben zum Vergleich stehen.
- **Nach R7-11 (neuer Report):** kein neuer Lauf nötig. Der Report rechnet beim Öffnen neu — dieselben
  Report-Pfade erneut öffnen.
- **Neue Aufgaben im Pool:** erneut starten; „davon ready“ steigt mit jeder Freigabe.

## Simulation vorher/nachher (LSA-V2)

`simulation.sh` baut zwei Wegwerf-DBs im lokalen Postgres (CI-Neuaufbau ohne bzw. mit der Migration
`*_lsa_v2_ausblick.sql`), lädt `neuaufbau-fixture.sql` (Admin und drei Aufgaben je Skill, dieselbe Fixture wie der
pgTAP-Test) und lässt alle Kinder laufen. `auswertung.sql` gibt je Kind Aufgaben, Dauer, Ende (Zeit, leer, Deckel),
Ausblick-Knoten und davon sicher, tiefste Klasse und Zweitbelege aus. Nie gegen Prod.

```bash
bash tools/lsa-testkinder/simulation.sh
```

Ergebnis vom 22.10.2026: `docs/lsa/lsa-v2-simulation.md`.

## Test

`supabase/tests/lsa_testkinder.test.sql` lässt das Skript im CI-Neuaufbau zweimal laufen (mit
`neuaufbau-fixture.sql`, der Neuaufbau hat keine LSA-Aufgaben) und prüft je Kind Abschluss, Profil,
Uhr, Fehlbild und den zweiten Lauf; für Max zusätzlich 100 % sicher und eine leere Liste „richtig
beantwortet, nicht angenommen“. Tim ist nicht auswertbar, die sechs anderen sind auswertbar (LSA-R2,
`lsa_durchklick_stand`). LSA-V2: Max und Lina mit Ausblick und Stopp, kein Kind über 40 Aufgaben, Tim endet durch
den Deckel oder die leere Auswahl, „Weiß ich nicht“ ohne Zweitbeleg, Jonas bis Klasse 5/6. Danach ein Lauf mit `nur=Max` (genau eine neue Sitzung) und einer mit
unbekanntem Namen (Abbruch).

Hinweis zu Tim: Alle Antworten eines Laufs liegen in einer Transaktion und tragen dieselbe Abgabezeit. Die
Reihenfolge der Abgaben ist dann nicht die echte; die Anteilsregel (ab 10 Antworten, 40 % schnell falsch)
macht ihn trotzdem sicher nicht auswertbar.
