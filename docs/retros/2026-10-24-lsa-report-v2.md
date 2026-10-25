# Retro 24.10.2026 · Eltern-Bericht v2

Auftrag: Rasit, 24.10.2026 (Bericht v2 für alle Seiten, Testlauf mit der LSA von Rasit Batu). Branch
`feat/lsa-report-v2`.

## Gebaut
- **Regeln zentral:** `src/lib/report/elternbericht/berichtKonfig.ts` (Kontakt, Klassenstufen-Kurzsatz,
  Lücken-Felder, Sorgfalt, Ursachen-Regeln, Deutung Seite 2, Paketvorschlag). Die Sätze stehen in i18n
  (`ursache`, `grund`, `feldMit`, `s1.systematik`, `s1.stufen`, `s3.v2`, `s4.muster`, `s5.grund`).
- **Rechnung:** `stufenBlick.ts`, `ursache.ts`, `fehlermuster.ts`, `lueckenweg.ts` (mit `duenneLueckenweg`),
  `paketVorschlag.ts`. In `schwerpunkte.ts` kommen dazu `schwerpunkteMitGrund` und die Startlogik nach dem
  Stand der Klassenarbeit. Die Gründe liegen als parallele Liste `bericht.gruende` vor, damit `EbSchwerpunkt`
  für die Präsentation gleich bleibt.
- **Lesepfad:**
  - `lsaReportErstgespraech.ts` liest Note, Trend, seit wann, Ziele, Klassenarbeit und Datum aus `leads`
    (nur Admin).
  - `reportNotes.ts` liest `paket_bestaetigt`, mit Rückfall auf `false`.
- **Seiten:**
  - Kopf mit beschrifteter Navigation, Überschriften in Literata (nur im Bogen-Scope).
  - Seite 1: Anlass und Antwort, Systematik, Stufen.
  - Seite 2: ohne Umrisse, Warum-Kasten, Anteilsregel.
  - Seite 3: Lücken → kommende Themen, stufenweise ausgedünnt.
  - Seite 4: Fehlermuster mit Zahlen, Grund je Schwerpunkt, Coach-Satz nur hier.
  - Seite 5: Pakete nur mit Rhythmus, Vorschlag, Ziele, Kontakt, Vertrag.
- **Migration** `20261024135226_bericht_v2` (nicht eingespielt) mit Rollback. `schema.sql` dokumentiert,
  `schema-erwartet.sql` aus lokalem Neuaufbau (nur die drei neuen Zeilen weichen ab).
- **Tests:** Seitentests neu, Unit-Tests der neuen Module, Druck-Spec für Navigation, Chip und Literata. Seite 3
  hat jetzt eine eigene Prüfung; `lernweg-grenzen.spec.ts` (Druck) ist entfallen.

## Entscheidungen
- Vorname = `leads.first_name` („Rasit Batu“), keine Genitivformen des Namens mehr.
- Die Präsentation behält Lernweg und R7-Sätze. Angepasst ist nur der Genitiv des Schulnamens.
- Bis die Migration eingespielt ist, zeigt Seite 5 den Systemvorschlag. Die bisherige Coach-Wahl (`paket`)
  wirkt erst nach Bestätigung.
- „Klassenarbeit geschrieben“ für Batu nur im Render-Harness gesetzt, nicht im Code.

## Zweitprüfung
Ein frischer Subagent hat alle Zahlen per dbread gegen Prod geprüft: alles ✅ außer
- Paket (gewollt, siehe oben) und
- Fehlermuster-Satz: „in den meisten falschen Antworten“ war zu stark (6 von 11 eingeordneten, 14 falsche
  Aufgaben). Der Satz nennt jetzt die Zahlen.

## Gelernt
- Die Namensmessung entfernt den Vornamen im ganzen Bogen, sobald eine Seite überläuft. Ein Überlauf auf
  Seite 2 sah deshalb zuerst wie ein Namensfehler aus.
- Ohne Umrisse greift die schmale Profilspur nicht mehr. Ab zehn Kästchen stieß die Spur an den rechten Text.

## Offen
`docs/report/v2/offene-punkte.md`
