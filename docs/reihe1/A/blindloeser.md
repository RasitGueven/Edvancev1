# Blindlöser je Bauform

Je Bauform löst ein frischer Subagent (ohne Kontext, nur die Kindertexte in `blindloeser/<KEY>/aufgaben.md`) zehn
zufällige grüne Instanzen. Gewertet wird über `format_werten_daten` in Prod (lesend). Mehr als 10 % Abweichung
(mindestens eine) macht die Bauform verdächtig: Grund in `bauformen.verdacht`, Status `entwurf`, nicht im Board.

| Bauform | gelöst | abweichend | Ergebnis | Datum |
|---|---|---|---|---|
| WZ-1 | 10 | – | bestanden | 27.10.2026 |
| NP-2 | 10 | – | bestanden | 27.10.2026 |
