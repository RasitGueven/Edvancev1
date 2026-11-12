# SP-1c C3 · Zweitprüfung NS-4 Stufe 2 und 3

Frischer Subagent, 12.11.2026, gegen `scripts/bauformen/bauformen/ns_4.py` (mit `graph_optionen`) und die 27 aktiven
Instanzen in Prod (12 in Stufe 2, 15 in Stufe 3, dbread). Ergebnis: **GESAMT bestätigt.**

| Aussage | Befund |
|---|---|
| Nullstellen ganzzahlig zwischen −5 und 5, nie 0, nie Gegenzahlen | bestätigt (`range(-5, 6)`, `0 not in`, `p != -q`) |
| Abstand 2, 4 oder 6 | bestätigt: gerade und |Scheitel-y| = (Abstand/2)² ≤ 9; in Prod kommen alle drei vor, kein anderer |
| Scheitel mit ganzen Koordinaten | bestätigt (gerader Abstand) |
| S2 nach oben wie die Normalparabel | bestätigt (a = 1) |
| S3 nach oben oder unten, Frage nennt die Öffnung, alle drei gleich geöffnet | bestätigt (a = ±1, Zusatz in der Frage, alle Varianten mit demselben a) |
| drei Parabeln zur Auswahl | bestätigt (immer drei, nie zusammenfallend; Prod: jede Instanz drei Optionen) |
| Beispiele wörtlich aus aktiven Instanzen | bestätigt (S2 x = −1 und x = 3; S3 dieselben, nach unten geöffnet) |
| Sprache: keine Klammer, kein „∈“, kein Schlüssel; S3 ausgeschrieben | bestätigt |
| Migration nur NS-4 S2/S3, keine Version; danach 112/112 | bestätigt |

Nicht genannt (unwesentlich für die Prüferin): Der Scheitel liegt nie genau bei (p | q) — das hält nur die
Auswahl-Parabeln verschieden.
