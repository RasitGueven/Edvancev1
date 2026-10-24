# Bericht v2 · offene Punkte (24.10.2026)

## Fehlende Felder

| Feld | Stand | Fallback im Bericht |
|---|---|---|
| Klassenarbeit „geschrieben“ | Spalte fehlt. Migration `20261024135226_bericht_v2` legt `leads.klassenarbeit_status` an (nicht eingespielt). Das Erstgespräch hat dafür noch kein Eingabefeld. | Ohne Spalte gilt ein `next_exam_date` ab dem Tag der Sitzung als „bevorstehend“, sonst „unbekannt“ → aktuelles Thema zuerst. Für Batu im Testlauf per Override auf „geschrieben“ gesetzt (Harness, nicht im Code). |
| Paket vom Coach bestätigt | Spalte fehlt. Dieselbe Migration legt `lsa_report_notes.paket_bestaetigt` an. Der Ausblick braucht danach einen Schalter „Vorschlag übernehmen / Paket bestätigen“. | Seite 5 zeigt den Systemvorschlag mit dem Schild „Vorschlag“. Das bisherige `paket` (z. B. Batu: „basis“) wirkt erst mit Bestätigung. |
| Telefonnummer | Nirgends hinterlegt. | `KONTAKT.telefon` in `berichtKonfig.ts` ist `null`; die Zeile entfällt im PDF. |
| Halbjahr im Schulplan | `schul_themenplan.halbjahr` ist beim FWG überall leer. | „voraussichtlich in Klasse 9“ statt „voraussichtlich im 1. Halbjahr“. |
| Ziele (6 Monate) | `leads.goal` ist bei Batu leer. Der Bericht nimmt zuerst `lsa_report_notes.zielbild` (Coach), dann `leads.goal`. | Ohne beides entfällt der Abschnitt. Batus Zielbild ist Testeingabe („uhuzhuhuuh“) und steht deshalb im PDF. |

## Schwellen zur Entscheidung (alle in `src/lib/report/elternbericht/berichtKonfig.ts`)

- **Paketvorschlag:** Premium ab Anteil Übungsbedarf ≥ 50 % **und** ≥ 3 Schwerpunkte. Basic nur bei Anteil
  ≤ 15 % **und** ≤ 1 Schwerpunkt. Sonst Standard. Batu: 11/23 = 48 %, 4 Schwerpunkte → Standard
  (knapp unter Premium).
- **Klassenstufen-Kurzsatz:** Die Stufe mit dem meisten Übungsbedarf heißt „hier liegen die Lücken“, wenn dort
  ≥ 50 % Übungsbedarf ist. Sonst gilt: 100 % sicher → „sicher“, ≥ 75 % → „sitzen weitgehend“ (aktuell:
  „fast sicher“), ≥ 50 % → „teils, teils“.
- **Sorgfalt-Kernaussage:** Die Familien Vorzeichen, Schritt vergessen und Figuren stellen ≥ 3 Fehlbild-Aufgaben
  und ≥ 50 % aller Fehlbild-Aufgaben. Batu: 6 von 11.
- **„Lücken liegen vor allem bei …“:** Themenfelder mit ≥ 2 Übungsbedarf, höchstens zwei.
- **Seite 2 „meister Übungsbedarf“:** höchster Anteil, nur Felder mit ≥ 2 geprüften Bereichen.

## Graph-Befund: „Terme für Flächeninhalte“ vs. „Fläche von Dreieck und Parallelogramm“

`skill_kante` sagt: `geo_flaeche_term` setzt `geo_flaeche_dreieck` voraus (dazu `term_einsetzen` und
`term_ausmultiplizieren`). In Batus LSA:

- `geo_flaeche_term`: 2 Aufgaben, beide richtig → `traegt` (sicher).
- `geo_flaeche_dreieck`: 2 Aufgaben, eine richtig, eine falsch (Fehlbild `falsche_hoehe`, Familie „Figuren“:
  schräge Seite statt Höhe) → `traegt_teilweise` (Übungsbedarf).

Der Graph ist nicht falsch. „Sicher“ verlangt, dass alle Proben gelingen, „Übungsbedarf“ heißt hier ein
Teilfehler. Der Fehler passt zum Sorgfaltsmuster: Der Rechenweg stimmte, aber die falsche Strecke wurde
eingesetzt. Nichts geändert.
Zu entscheiden wäre, ob `traegt_teilweise` mit einem Sorgfaltsfehler im Bericht anders heißen soll als
`traegt_nicht`.

## Weitere Punkte

- Der Bericht liest die Lead-Felder direkt aus `leads`. Das darf nur der Admin. Beim Coach entfallen Anlass und
  Antwort auf Seite 1 still.
- Die Präsentation (Station 01–05) nutzt noch die R7-Sätze und den Lernweg. Nur der Schulname-Genitiv ist
  angeglichen.
- Fehlermuster-Texte aus `fehlbild_familien` beginnen mit „Ihr Kind“. Seite 4 ersetzt das am Satzanfang durch
  den Vornamen. Spätere Pronomen („es“) bleiben stehen.
- `leads.first_name` ist bei Batu „Rasit Batu“. Der Bericht spricht ihn so an, ohne Genitiv.

## Aus der unabhängigen Zahlenprüfung (24.10.2026)

- **Paket:** `lsa_report_notes.paket` ist bei Batu „basis“, das PDF schlägt Standard vor. Das ist gewollt: Ohne
  `paket_bestaetigt` gilt der Systemvorschlag. Zu entscheiden: Soll eine vorhandene Coach-Wahl bis zur Migration
  als bestätigt gelten?
- **Fehlermuster:** Die Kernaussage beruht auf den 11 eingeordneten Fehlern (je 1 Beobachtung). Falsch
  beantwortet wurden 14 Aufgaben. Der Satz nennt deshalb jetzt die Zahl („Bei 6 von 11 Fehlern, die wir
  einordnen konnten …“) statt „in den meisten falschen Antworten“.
- **Dünne Belege:** „Flächeninhalt des Trapezes“ steht als Übungsbedarf, beruht aber nur auf einem „Weiß ich
  nicht“ (`nicht_angesetzt`). Mehrere „sicher“ beruhen auf einer einzigen richtigen Antwort. Das gehört zur
  Bewertungsregel, nicht zum Bericht.
- **Plan-Thema „kreis“:** Der Schulplan-Eintrag „Kreise, Prismen und Zylinder“ trägt nur `thema_key kreis`.
  Kanten nach `prismen_zylinder` (z. B. `geo_koerper_prisma ← geo_flaeche_dreieck`) zählen deshalb nicht.
  Für Batu ändert das nichts.
- **„Terme für Flächeninhalte“ sicher, beide direkten Voraussetzungen (Dreieck, Werte einsetzen) nur teilweise:**
  Auf Seite 2 sieht man das nebeneinander in Geometrie und Terme. Seite 3/4 nennen „Terme für Flächeninhalte“ nur
  in „n weitere“.
