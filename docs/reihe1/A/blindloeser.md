# Blindlöser je Bauform

Je Bauform löst ein frischer Subagent (ohne Kontext, nur die Kindertexte in `blindloeser/<KEY>/aufgaben.md`) zehn
zufällige grüne Instanzen. Gewertet wird über `format_werten_daten` in Prod (lesend), bei Zahl, MC und Mehrteiler über
denselben Weg wie `session_bewerten` (`scripts/bauformen/klassisch.py`). Figuren sieht der Blindlöser als PNG
(`tools/bauform-bilder.mjs`). Mehr als 10 % Abweichung
(mindestens eine) macht die Bauform verdächtig: Grund in `bauformen.verdacht`, Status `entwurf`, nicht im Board.

| Bauform | gelöst | abweichend | Ergebnis | Datum |
|---|---|---|---|---|
| WZ-1 | 10 | – | bestanden | 27.10.2026 |
| NP-2 | 10 | – | bestanden | 27.10.2026 |
| BIN-1 | 10 | – | bestanden | 28.10.2026 |
| BIN-2 | 10 | – | bestanden | 28.10.2026 |
| AUS-1 | 10 | – | bestanden | 28.10.2026 |
| EIN-1 | 10 | – | bestanden | 28.10.2026 |
| QW-1 | 10 | – | bestanden | 28.10.2026 |
| KO-1 | 10 | – | bestanden | 28.10.2026 |
| GL-1 | 10 | – | bestanden | 28.10.2026 |
