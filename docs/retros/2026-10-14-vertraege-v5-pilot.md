# Retro 14.10.2026 — Verträge V5: Pilotvereinbarung

## Gebaut
- **Datenbank** (`20261014110412_vertrag_pilot.sql`):
  - `vertraege.vertragsart` (`regulaer` | `pilot`) mit drei CHECKs: ohne Tarif, Konditionen ab Versand, kein Verzug.
  - `vertrag_dokumente.vertragsarten` mit neuer Pflichtvorlage `pilotvereinbarung`.
  - `vertrag_pilot_vorschlag`, interne Prüfung `vertrag_pilot_pruefen`.
  - Angepasst: Guard, `vertrag_starten(p_lead_id, p_vertragsart)`, `vertrag_versenden`, `vertrag_abschliessen`
    (Pilot-Zweig), `vertraege_aktuell` (Spalte am Ende, Beitrag 0) und `slots_vertrag_json` (`vertragsart`, Rhythmus
    1/Woche).
- **Oberfläche:**
  - Auswahl der Vertragsart im Formular. Beim Pilot fallen Paket, Laufzeit und SEPA weg; Ende und Einheiten kommen
    mit Vorschlag dazu.
  - Abschluss vor Ort mit nur einer Unterschrift. Einpflegen ohne Paket und Laufzeit.
  - Schritt 2 und die Unterlagen zeigen die Pilotvorlage, ohne SEPA-Mandat.
  - Kennzeichen „Pilot“ in Menü, Assistent, Detail, Verlauf, Akte und Slots. Mandatsreferenz und Bankdaten
    erscheinen beim Pilot nicht.
- **Edge Functions:**
  - PDF der Pilotvereinbarung ohne Mandat. Bündel und Mails je Vertragsart, eigene Mailtexte.
  - `vertrag_buendel.ts` ausgelagert.
- **Kennzahlen:** `summen` zählt Pilots im Betrieb als laufend („davon x Pilot“, Entscheidung Rasit 14.10.), nie bei
  Abbuchung und Widerruf. `imVerzug` lässt sie aus, `buendelVollstaendig` verlangt bei ihnen kein Mandat.

## Entscheidungen beim Bauen
- **Dokumente je Vertragsart als Spalte am Dokument, nicht als Sonderfall im Code.**
  - Die Pflichtprüfung, das Festhalten der Fassungen beim Versand und die Zustimmungen vor Ort lesen dieselbe Spalte.
  - Vor Ort mitgeschickte Zustimmungen zu Dokumenten der anderen Art werden nicht gespeichert. Gefunden hat das
    `vertraege_prozess.PRUEFUNG.sql`.
- **Ende und Einheiten liegen beim Pilot am Vertrag.** Der Admin setzt sie in der Vorbereitung, der Guard lässt sie
  durch. `vertrag_abschliessen` hat deshalb keine neuen Parameter, Signatur und Ergebnisform bleiben gleich.
- **Kein Sonderfall in `slots_vertrag_am`, `slots_kinder_basis` oder `slots_kind_zugelassen`.** Ein Pilot erfüllt deren
  Bedingungen (abgeschlossen, Einheiten, Beginn, Ende). `slots_wochengrenze` fällt ohne Rhythmus schon auf
  einen Termin pro Woche zurück.
- **Kein Abo.** Kein Leser macht Login, Akte, Session, Lernpfad oder Reports von `student_subscriptions` abhängig.
  Geprüft per Codesuche über SQL, `src/` und Edge Functions.

## Geprüft
- pgTAP `v5_pilot`: 43 Zusicherungen. Volle Suite in der Wegwerf-DB (Port 55454) wie in der CI: 46 grün, die 8 aus
  `bekannt-rot.txt` rot wie erwartet.
- CI-Prüfskripte grün. Die fünf Vertrags-PRUEFUNG-Skripte laufen lokal mit Admin-Profil grün. In
  `vertrag_abschluss.PRUEFUNG.sql` zählt die Fassungsprüfung jetzt das Bündel der eigenen Vertragsart.
- Typecheck, Lint, Vitest (132 Dateien) grün. Deno-Tests der PDF-Erzeugung 13 grün, `deno check` der drei Functions grün.
- Schema-Abzug aus der Wegwerf-DB. Gegenüber dem dev-Stand weichen nur die eigenen Objekte ab.
- Zweitprüfung durch eine frische Instanz, keine Blocker. Umgesetzt: Ein Pilot speichert keine IBAN mehr, Versand
  und Abschluss löschen vorhandene Bankdaten, die Wochenzählung ist zeitzonenunabhängig, die Hinweistexte im
  Assistenten haben Pilot-Fassungen. Die Rückfrage, ob ein Pilot als „laufender Vertrag“ zählt, ist entschieden: ja, im Betrieb.
- Browser: fünf Ansichten per Vite-Harness mit erfundenen Daten (Formular Pilot und Regulär, Übersicht, Detail,
  Slots-Kind). Kein Konsolenfehler. Danach auf der Detailseite Widerruf und Zahlung beim Pilot ausgeblendet.

## Offen
`docs/vertraege/offene-punkte-v5.md`
