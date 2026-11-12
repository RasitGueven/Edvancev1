# SP-1c · Fortschritt

| Datum | Phase | Ergebnis | PR |
|---|---|---|---|
| 12.11.2026 | C0 | Worktree `Edvancev1-SP1c` von origin/dev (f3304977), npm ci, sympy aus `Edvancev1-A`. Gelesen: sp1b `offen.md` (B1, B2), `bericht.md`. Prod vorher: 47 × v1 `zur_pruefung`, 0 Prüfungen; NF-2 0 Prüfungen, 0 Kommentare, 84 Instanzen. | – |
| 12.11.2026 | C1 | Prüfmaschine (Prüfung 5): Platzhalter `\{[A-Za-z_]+\}` auch in Fehlbild-Rückmeldungen, `warum.frage`, `warum.bausteine[].text`; ein Treffer im Steckbrief macht alle Instanzen rot (Bauform verdächtig). Negativkontrollen: `({h})²` in `warum.frage` verwirft die Bauform; Baustein und Rückmeldung; „L = {0; 18}“ bleibt grün. pytest 19/19. Lauf `--alle --platzhalter`: 1 Treffer, NF-2 (`platzhalter.md`). | – |
