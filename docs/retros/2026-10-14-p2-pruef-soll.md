# Retro 14.10.2026 · P2 Board mit Sollzahlen

**Gebaut:** drei Migrationen (20261014150100/150200/150300): Pilot-Flag für die 76 Aufgaben außerhalb von P1s
Zielmenge über den `pilot_aus`-Weg entzogen (Rücksetzliste `docs/themen/p2-pilot-entfernt.md`), Tabelle
`pruef_soll` mit RLS (lesen mit Prüfrecht, schreiben admin), Funktion `pruef_board_soll()` neben `pruef_board()`.
Board: Reiter „noch X zu prüfen“, Thema „X von Y nötig“ + „reicht für die LSA“, aufgeklappt Knoten mit Soll,
gezählt und „mind. 1 ohne Multiple Choice“. Abnahme mit Prod-Abzug (`tools/p2-wegwerf-db.sh`), pgTAP
`p2_pruef_soll`, Vitest.

**Entscheidungen (Rasit, 14.10.):** Board nur Batus Liste; Sollzahlen als Daten; gezählt = review oder ready;
höherer Sollwert bei mehreren Anlässen. Selbst gewählt: eigene Funktion statt Spalten an `pruef_board()`;
`min_ohne_mc` ebenfalls als Höchstwert; Rest = max(Soll − gezählt, min_ohne_mc − gezählt ohne MC, 0);
Reihenfolge der Session-Knoten (7/8 vor 9/10); FK mit `on delete cascade` wie `skill_thema` (inv10 löscht alle Knoten).

**Gelernt:** Die 76 stammen aus dem ersten Lena-Board-Piloten (PR #208), per Migration gesetzt, ohne Protokoll.
`pilot_aus` erhöht `pruef_version` (Trigger) — gleiche Nebenwirkung wie die Admin-Aktion.

**Offen:** `term_binom_gemischt` und `term_binom_quadrat` haben nur MC-Aufgaben, „mind. 1 ohne MC“ ist dort nicht
erfüllbar; „Weiter prüfen“ folgt weiter der Board-Reihenfolge (Klasse), nicht pruef_soll.sort; eine der 76
(`573dd0b7`) war schon „passt“. Einspielen nach Freigabe.
