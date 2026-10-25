# LSA-L3 · Offene Punkte

Stand 25.10.2026. Bauauftrag `docs/lsa/Bauauftrag-L3.md`, Simulation `docs/lsa/l3-simulation.md`.

## Entscheidungen für Rasit

1. **80 % für Batu „geschrieben“ nicht erreichbar** (`l3-simulation.md` 6.1). 11 von 17 Bericht-Voraussetzungen sind
   direkt geprüft, mehr lassen sich unter Entscheidung 3 und 6 nicht direkt prüfen. Mögliche Wege:
   - (a) Eine direkte Probe darf ein mitbelegtes Urteil ersetzen. Das ändert `lsa_urteil_buchen_core`.
   - (b) In `vorschau_zuerst` läuft die Vorschau vor Thema kurz.
   - (c) Die Kennzahl zählt „mitbelegt sicher“ als geprüft.
   - (d) Abnahme mit 11/11 der prüfbaren Voraussetzungen.

   Bis dahin ist die Migration **nicht eingespielt** und der PR nicht gemergt.
2. **Entscheidung 7 im Themenraum** (`l3-simulation.md` 6.2). Phase T, Tiefe und Thema vertiefen bleiben ohne
   Klassengrenze, wie vor L3. Mit Klassengrenze verlören Kinder an 31 Schulen einen Einstieg ihres aktuellen Themas.
   An zwei Schulen bliebe das Thema leer (Reelle Zahlen in Klasse 8, Binomische Formeln in Klasse 7). Soll die Grenze
   trotzdem gelten?
3. **Ohne Thema** (aus der Retro zu #324, `l3-simulation.md` 6.3): Breite b und Schritt 5 ziehen Einstiege kommender
   Themen. Unverändert nach Entscheidung 1.

## Für später (nicht in L3)

Texte im Bericht nach Klassenarbeits-Stand. Sie gehören in einen Nachtrag zu Bericht v4; V4 ist gemergt (#321, #322).

- **Steht an:** „Die Arbeit zu {Thema} steht noch an. Darauf bereiten wir zuerst vor.“
- **Geschrieben, Note offen:** „Die Analyse zeigt für {Thema}: sicher war {X}, noch unsicher {Y}. Sobald Sie die Note
  kennen, gleichen wir das gemeinsam ab.“ Keine erwartete Note nennen.
- **Geschrieben, Note bekannt:** „Die Arbeit zu {Thema} ist mit Note {n} zurückgekommen. Dazu passt, was die Analyse
  zeigt: {Y} war noch unsicher. {Y} wird bei Klassenarbeit {k} wieder gebraucht.“ Nur „dazu passt“, keine Behauptung
  über die Ursache.
- **Erstgespräch:** Status und Note müssen vor dem LSA-Start beantwortet sein. Fehlen sie, gibt es einen Hinweis im
  Startdialog, und es läuft `thema_zuerst`. Der Modus wird beim ersten Aufruf der Auswahl festgestellt und steht in
  `lsa_sessions.ka_modus`; eine spätere Antwort ändert die laufende LSA nicht.
- **Note kommt nachträglich:** Eintrag im Erstgespräch, Anzeige im Monatsbericht. `lsa_sessions.ka_note` hält die Note
  vom Start fest.

## Kleineres

- Der Prod-Pool der Simulation ist die L2-Fixture (134 Aufgaben). In Prod sind heute 145 freigegeben. Eine neue
  Fixture ändert vorher und nachher gleich.
- Batus LSA ist mit dem Prod-Pool nach 10–12 Minuten leer, weil KA4 und der Rückblick der Klasse 7/8 keine freien
  Aufgaben haben (Freigabeliste für Lena aus L2).
- `vorschau_zuerst` hat kein „Thema vertiefen“ (Entscheidung 3). Endet die Sitzung früh, bleiben ungeprüfte Bereiche
  des Themenraums liegen; aufgefüllt wird nicht.
- Migration 684 Zeilen (über der 400-Zeilen-Regel). Wie bei L2 steht `lsa_select_next_core` vollständig in **einer**
  Migration (Auftrag: EINE Migration).
