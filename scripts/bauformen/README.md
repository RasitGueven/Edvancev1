# Bauformen (Sessionreihe 1, Bauauftrag A4)

Generator, Prüfmaschine und Export der Bauformen. Konzept: `docs/reihe1/Konzept-Sessionreihe-1-und-Bauformen.md` §3–§5.

| Datei | Inhalt |
|---|---|
| `basis.py` | `Bauform` (Steckbrief, Stufen, Rollen, Fehlbilder mit `gilt_fuer_stufen`), `Instanz`, Zahlen- und Summenschreibweise |
| `rechnen.py` | unabhängiges Nachrechnen mit sympy aus dem angezeigten Text |
| `pruefmaschine.py` | die sieben Prüfungen; Prüfung 4 gegen die echte Wertung (`format_werten_daten`, Prod, lesend per `~/bin/dbread`) |
| `klassisch.py` | Zahl/Bruch (NUMERIC), MC, Mehrteiler/Tabelle (MULTI_PART): Speicherung und Prüfung 4 über denselben Weg wie `session_bewerten` |
| `formen.py` | gemeinsame Bausteine: Feldmasken-Kurzschrift, Lösungsmengen, Werte mit Vorzeichen |
| `export.py` | JSON-Vorschau, Kindertexte für den Blindlöser, Auswertung, Datenmigration und Rollback |
| `bauformen/<key>.py` | je Bauform eine Klasse, `BAUFORM = …` |
| `test_pruefmaschine.py` | Negativkontrollen (falsche Lösung, kollidierende Fehlbilder, „+ −“, „1x²“, leerer Platzhalter, ASCII-Minus, Dublette, LSA-Zwilling, falsche Stufe, Wertung) |

## Ablauf je Bauform

```bash
python3 -m pip install --target scripts/bauformen/.pydeps sympy      # einmal, lokal, nicht im Repo
bash tools/bauform.sh NP-2                                           # erzeugen, prüfen, Vorschau, Blindlöser-Texte
# Orchestrator: frischer Subagent löst docs/reihe1/A/blindloeser/NP-2/aufgaben.md → antworten.json
bash tools/bauform.sh NP-2 --blind antworten.json                    # Blindlöser werten, Migration + Rollback schreiben
PYTHONPATH=scripts/bauformen/.pydeps python3 -m pytest scripts/bauformen -q
```

Eine Instanz mit einem roten Punkt wird verworfen. Mehr als 30 % rot oder mehr als 10 % Abweichung beim Blindlöser
macht die Bauform verdächtig (`bauformen.verdacht`, Status `entwurf`, nicht im Board). Die Generierung ist
deterministisch (Seed je Schlüssel); dieselbe Bauform ergibt dieselben Instanzen. Instanzen starten `draft`, die
Bauform `zur_pruefung`; Lena prüft je Bauform, Admins geben frei (`bauform_freigeben`).
