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
