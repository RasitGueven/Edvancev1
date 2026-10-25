# Retro · LSA-L3 Klassenarbeits-Modus (25.10.2026)

Auftrag `docs/lsa/Bauauftrag-L3.md`. Die LSA-Auswahl richtet sich nach dem Stand der Klassenarbeit zum aktuellen Thema.

## Gebaut

- **Migration `20261025223011_lsa_l3_ka_modus`** (mit Rollback, lokal geprüft: Funktion danach md5-gleich mit Prod).
  Sie bringt:
  - die Spalten `lsa_sessions.ka_modus` und `ka_note`; der Modus wird beim ersten Aufruf der Auswahl festgestellt;
  - `vorschau_zuerst`: Thema kurz, Vorschau, Tiefe, Rückblick;
  - das Auffüllen der Vorschau aus Klasse + 1 in beiden Modi;
  - die Hilfsfunktion `lsa_klp_themen`.
- **Werkzeuge**:
  - `erzeugen.sql` setzt den Klassenarbeits-Stand.
  - `l3-kinder.sql` bringt sechs Simulationskinder.
  - `l3-gruppen.sql` und `l3-auswertung.sql` werten die Läufe aus.
  - `simulation.sh` nimmt `KINDER_ZUSATZ` und `AUSWERTUNG`.
  - `lsa-weiter-messung.sql` nimmt `-v ka`.
- **Tests**: `lsa_l3_ka_modus` ist neu (23). `lsa_v_vorschau` f und `lsa_v2_ausblick` sind an das Auffüllen
  angepasst.
- **Doku**: `l3-simulation.md`, `l3-offen.md`, README der Testkinder.

## Entscheidungen in der Session

- Modus als eigene Spalte statt in `result_summary`, weil `lsa_finish` `result_summary` neu schreibt.
- Festgestellt im ersten Aufruf von `lsa_select_next_core`, nicht in `lsa_start`: Das ist die Stelle, an der heute
  `v_kommend` entsteht. So gilt er für jeden Weg, der eine Sitzung anlegt. Eine Sitzung, die schon Aufgaben hat (vor
  L3 gestartet), bleibt `thema_zuerst`.
- Drei Simulationsrunden, Konstanten am Ende: 4 / 1 / 16 / 18 Minuten. Begründung in `l3-simulation.md` 2.
- Themenraum ohne Klassengrenze, entgegen dem Wortlaut von Entscheidung 7. Prod zeigt: 31 Schulen unterrichten Terme
  und Gleichungen in Klasse 7, ein Einstieg hat Kernlehrplan-Klasse 8. An zwei Schulen liegen alle Einstiege des Themas
  darüber. Zur Entscheidung gemeldet.

## Ergebnis und Stopp

Das Kriterium „Batu geschrieben ≥ 80 %“ ist nicht erfüllt: 11/17, und genau 11 sind direkt prüfbar. Der Rest ist
Klasse-10-Stoff oder vom ersten Thema-Einstieg mitbelegt; das ist final, und Entscheidung 6 sperrt die Wertung. Der
Auftrag sagt „nur wenn die Zahlen passen“ und „danach mit Befund melden“. Deshalb zuerst nur ein Draft-PR mit Befund.
Nach der Meldung hat Rasit entschieden: einspielen und mergen. Eingespielt am 25.10.2026 per `mig`, nachgewiesen per
dbread (Historie, md5 von `lsa_select_next_core` und `lsa_klp_themen` gleich mit dem Neuaufbau, Spalten da, Rechte).
`schema-erwartet.sql` ist der Prod-Abzug, gefiltert gleich dem Neuaufbau.

Früh leer im Prod-Pool (Rückfrage Rasit): 17 der 19 Rückblick-Bereiche der Klasse 7/8 haben 0 freigegebene Aufgaben
(je 5–7 Entwürfe), dazu `term_binom_faktorisieren` in der Vorschau. Die übrigen Vorschau-Bereiche haben Aufgaben; sie
fehlen wegen Mitbelegung bzw. Abstieg nur unter Brüchen.

Alle anderen Kriterien sind erfüllt: `thema_zuerst` ist Aufgabe für Aufgabe gleich, Batu stark erfüllt seine
Kriterien, Mia bekommt die Klasse-8-Voraussetzungen, kein Ausblick, ≤ 40/19, keine Wiederholung, unter 20 ms.

## Gelernt

- Ein kürzeres Vorschaufenster im „Vorschau zuerst“-Modus kann weniger Vorschau bedeuten. `thema_zuerst` geht bei
  kleinen Themen ohnehin früh in die Vorschau. Runde 1 hat das gezeigt (BatuG 8/17 statt 11/17).
- Die Mitbelegung durch den ersten Thema-Einstieg bestimmt, was die Vorschau überhaupt noch direkt prüfen kann. Für
  die Kennzahl „direkt geprüft“ ist das wichtiger als jede Zeitkonstante.

## Offen

`docs/lsa/l3-offen.md`. ROADMAP: L3 eingespielt (Eintrag unten).
