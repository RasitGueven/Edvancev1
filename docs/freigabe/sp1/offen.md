# SP-1 · Offene Befunde

## O1 · Session-Planung liest keine Aufgabenzeit (S0.6, betrifft S1.2 und Abnahme e)

Der Auftrag nimmt an, dass die Session-Planung die Bearbeitungszeit einer Aufgabe liest und künftig die Zeit der Stufe
lesen soll. Im Code gibt es diese Stelle nicht: `est_duration_sec` lesen nur LSA „fest“, Quests und die LSA-Liste
(`supabase/schema-erwartet.sql:10319, 14739, 15084`). Die Reihenplanung rechnet mit Minuten je Kernidee
(`reihe_planen`, Konzept §2.3), die Session-Schritte ziehen Aufgaben ohne Zeitbudget.

**Vorgehen in SP-1:** Die Zeit je Stufe wird gespeichert (`bauform_stufen.zeit_min`, Protokoll) und ist je Instanz über
eine Lesefunktion abrufbar. Einen Leser in der Planung baut SP-1 nicht: `session_naechster_schritt` und die
Reihenplanung gehören Auftrag C, und welche Planung die Zeit nutzen soll (Kapazität der Kernarbeit aus Aufgabenzeiten
statt Kernidee-Minuten?), ist eine Entscheidung der Gründer.

**Frage an Rasit:** Soll die Kernarbeit künftig mit der Summe der Stufenzeiten planen, und wenn ja, in welchem Auftrag?

## O2 · Neuer Untergrund für Graph-Optionen (Nachtrag 11.11.)

Aufgenommen als S4 Punkt 14 und Abnahmefall k.

## O3 · Rückfrage und Pausieren (Zweitprüfung S1, Befund 7)

Wird eine Bauform in Rückfrage gemeldet und pausiert (`aufgabe_melden`) oder setzt ein Export mit Verdacht sie ohne
Versionswechsel auf `entwurf`, geht der Status `rueckfrage` verloren; der nächste saubere Export öffnet sie dann wieder
für Lena, die Kommentare bleiben offen. Heute ohne Fall (0 Prüfungen). Die Überarbeitung nach `rueckfragen-ablauf.md`
prüft vor dem Export den Status.

## O4 · Strittige Klartexte (S2)

Nicht in der Datenmigration `20261112083401_sp1_klartext`; die Prüfansicht zeigt dort die Generator-Regel. Befund und
Textvorschlag je Stufe in `klartext-pruefung.md`:
- EIN-1 (alle Stufen: x = ±2 kommt nie vor), EX-2 S3 (Formel mit „…“), KO-1 S2 (0 ausgeschlossen, verschiedene Beträge),
  NP-4 S4 (Zahl vor x ≠ 0, zweite Lösung |·| ≤ 12), NS-4 S2/S3 (Abstand der Nullstellen gerade, nie 0, nie Gegenzahlen),
  NS-5 S3 (e ≠ 0).
- Fehlbild-Kurznamen: `qf_binom_vorzeichen`, `qf_oeffnung_aus_e`, `qf_ergaenzung_nicht_abgezogen`, `qf_ergaenzung_ohne_a`
  (in NF-5 andere Bedeutung, eigener Schlüssel nötig), `qf_nullprodukt_vorzeichen` (weich). Die Ansicht zeigt dort den
  Satz aus `fehlbild_labels.klartext`.
- Platzhalter PAR-4 `wie` (enthält in Stufe 4 auch die Streckung): Wort „Wert“.
- Generator: PQ-2 Stufe 2 Sonderzweig erzeugt p, q > 0 (von `angenehm()` verworfen, ohne Wirkung); DI-1 q bis 100 bei
  „genau eine Lösung“.
