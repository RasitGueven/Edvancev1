# Bauauftrag R7-10 · Seite 2: Deutung erst ab zwei geprüften Bereichen, Umrisse kräftiger

Stand 20.10.2026. Ein kleines Paket aus den offenen Punkten von R7-8 (#287). Es kann parallel zu R7-9
laufen: R7-9 lässt Seite 2 unberührt, R7-10 berührt nur Seite 2.

## Befund

- **Deutung:** „Was die Grafik zeigt“ nennt Brüche & Dezimalzahlen bei Batu „überwiegend sicher“. Der Satz
  stützt sich auf einen einzigen geprüften Bereich (1 sicher). Seit R7-8 stehen daneben vier umrandete
  Kästchen ohne Farbe. Dadurch liest sich der Satz so, als wäre das ganze Feld sicher.
- **Umrisse:** Die umrandeten Kästchen (`--color-eb-schraffur-rand`, 0,7 pt) sind am Bildschirm gut zu
  sehen, auf Papier aber womöglich zu blass.

## Prompt

```
Du arbeitest im Repo Edvancev1 (WSL). Paket R7-10: zwei kleine Änderungen auf Seite 2 des Eltern-Berichts R7. Voraussetzung: R7-8 (#287) ist in dev gemergt, sonst STOPP. R7-9 kann gleichzeitig in einem anderen Worktree laufen; fasse dort nichts an. Lies zuerst docs/report/r7/offene-punkte-r7-8.md und lege diesen Bauauftrag als docs/report/r7/Bauauftrag-R7-10.md im PR ab.

## Entscheidungen (nicht neu verhandeln)
1. deutung() in src/components/edvance/elternbericht/seite2Rechnung.ts: Ein Themenfeld kommt nur dann in einen der beiden Sätze, wenn darin mindestens 2 Bereiche direkt geprüft wurden (sicher + uebung ≥ 2).
   - Die Schwelle gilt für beide Sätze, „überwiegend sicher“ und „den meisten Übungsbedarf“.
   - Als benannte Konstante mit Kommentar (MIN_GEPRUEFT_DEUTUNG = 2).
   - Alles andere bleibt wie bisher:
     - mehr sicher als Übungsbedarf → Satz sicher; sonst mit Übungsbedarf → Satz Übung
     - je Satz höchstens zwei Felder
     - Sortierung nach Anzahl, Gleichstand nach Profilreihenfolge
   - Abgeleitete Bereiche zählen nie mit.
2. Der Coach-Satz („Ob dahinter ein gemeinsames Muster liegt …“) steht nur, wenn vor ihm mindestens einer der beiden Sätze steht und es Übungsbedarf gibt. Er bezieht sich auf den Satz davor und darf nicht allein stehen.
   - Steht keiner der drei Sätze, entfällt der Absatz; Kicker und Fußnote bleiben.
3. Umriss der abgeleiteten Kästchen (.eb-s2-segment-abgeleitet, auch in der Legende):
   - Rand --color-eb-weg-ring statt --color-eb-schraffur-rand, Strichstärke 0,8.
   - Fläche bleibt --color-eb-papier.
   - Kein neues Token, keine Hex-Werte.
4. Keine neuen oder geänderten Texte in elternbericht.json.

## Erwartung
- abgestuft (Batu): „Überwiegend sicher war das Themenfeld Terme & Gleichungen.“
  - Brüche & Dezimalzahlen ist nicht mehr genannt.
  - Der Satz zum Übungsbedarf nennt weiterhin Geometrie und Zahlen & Rechnen.
  - Dahinter steht der Coach-Satz.
- ilkay: Text wörtlich unverändert, weil jedes Feld dort mindestens 3 geprüfte Bereiche hat. Das hält ein Test fest.
- Alle anderen FAELLE: Wo sich der Text ändert, nenne ihn im PR alt → neu.

## Umfang
- src/components/edvance/elternbericht/seite2Rechnung.ts und seite2Rechnung.test.ts
- Seite2.tsx (nur Entscheidung 2) und Seite2.test.tsx
- src/styles/elternbericht/seite2.css (nur Entscheidung 3)
- docs/report/r7/Bauauftrag-R7-10.md, docs/report/r7/offene-punkte-r7-10.md, Retro
- Nicht anfassen: alles andere, insbesondere Profil.tsx (außer die Legende bekommt die Farbe nicht über seite2.css), Seite3 und alles aus R7-9, lib/**, types/**, fixtures/**, i18n, praesentation/**, e2e-druck/**, supabase/**.

## Tests
- Vitest deutung:
  - Feld mit 1 geprüftem Bereich (sicher) nicht genannt; mit 2 (2 sicher, oder 1 sicher + 1 Übung je nach Mehrheit) genannt
  - Schwelle auch im Übungssatz
  - abgeleitete zählen nicht
  - Batu und Ilkay gegen die Erwartung
- Seite2: Coach-Satz nie allein; Absatz entfällt ohne Satz.
- Druck-Tests für ALLE Fälle grün: EB_PORT=5192 EB_AUSGABE=docs/report/r7/abnahme/r7-10 npx playwright test -c playwright.elternbericht.config.ts
- inv4-elternbericht, Typecheck, Lint, Vitest grün.

## Leitplanken
- Worktree ../Edvancev1-r7j auf feat/rasit-report-r7-deutung von origin/dev. PR gegen dev, nie main.
- Kein DDL, keine Migration.
- Designregeln wie R7: INV-4.11, Dateien ≤ 400 Zeilen.
- CI: Ist in schema/neuaufbau NUR session_a2 rot (Laufzeitmessung), ist das nicht dein Fehler. Im PR vermerken, nichts ändern.
- Keine Zweitprüfung nötig (kleines Paket). STOPP nach dem PR.

## Melden
- PR-Link
- Bildschirmfoto Seite 2 von abgestuft und ilkay
- PDFs aus docs/report/r7/abnahme/r7-10/ (abgestuft, ilkay, allesSicher, nichtsSicher)
- Textänderungen je Fall alt → neu
- offene Punkte
```
