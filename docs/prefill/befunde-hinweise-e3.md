# Befunde und offene Punkte: Hinweise als Entwurf (E3)

Stand 12.10.2026, Branch `feat/rasit-session-e3-hinweise`. Alles ist KI-Entwurf (`status = 'entwurf'`); geprüft
wird in L5 (Lena), freigegeben vom Admin. Nichts wird automatisch geprüft oder freigegeben.

## Dateien

| Datei | Inhalt |
|---|---|
| `tools/hinweise-e3/<skill>.mjs` | **Quelle**: drei Stufen je Aufgabe (Schlüssel `tasks.source_ref`), mit Belegen für jede Zahl |
| `tools/hinweise-e3-lib.mjs` | Nachrechnung (exakt, über `tools/prefill-rechnen.mjs`), ohne DB und ohne LLM |
| `tools/hinweise-e3.mjs` | `pruefen`, `vorschau`, `migration` |
| `tests/hinweise-e3.test.ts` | Gate: echte Quellen grün, gezielt verdorbene Kopien rot |
| `hinweise-e3-snapshot.json` | Bestand der Aufgaben per dbread (Prod, nur gelesen) |
| `hinweise-e3-vorschau.md` | Vorschau: Aufgabe, Lösungsweg, Stufe 1–3 nebeneinander |

## Bestand (Schritt 1)

dbread 12.10.2026, Prod. Session-Aufgaben = `'session' = any(tasks.einsatz)`; „ohne Hinweise“ = `hints` leer oder null.

| Skill | Aufgaben gesamt | davon Session | davon ohne Hinweise | Status der Session-Aufgaben | VERA8 |
|---|---|---|---|---|---|
| `gleichung_quadr_faktor` | 7 | 6 | 6 | 6 × `draft` | 0 |
| `gleichung_quadr_wurzel` | 6 | 6 | 6 | 6 × `draft` | 0 |
| `gleichung_quadr_formel` | 6 | 6 | 6 | 6 × `draft` | 0 |
| `gleichung_quadr_anzahl` | 6 | 6 | 6 | 6 × `draft` | 0 |
| `gleichung_einschrittig` | 6 | 6 | 6 | 6 × `draft` | 0 |
| `gleichung_zweischrittig` | 6 | 6 | 6 | 6 × `draft` | 0 |
| `term_ausklammern` | 6 | 6 | 6 | 6 × `draft` | 0 |
| `vorzeichen_add_sub` | 7 | 7 | 7 | 7 × `draft` | 0 |
| **Summe** | 50 | **49** | **49** | 49 × `draft` | 0 |

- `gleichung_quadr_*` (alle) umfasst auch `gleichung_quadr_anzahl` (fünftes Ziel im Szenario Batu, `docs/szenario/batu.md`);
  `offene-punkte-t3.md` Punkt 1 nennt es nicht. Es ist hier dabei.
- Die siebte Aufgabe von `gleichung_quadr_faktor` hat keinen Einsatz `session` und bleibt unberührt.
- Herkunft: 24 Aufgaben `edvance_k9_quadrgl` (die vier `gleichung_quadr_*`), 25 `edvance_fundament` (die übrigen
  vier Skills), keine VERA8. Eingabe: 31 `NUMERIC`, 12 `MULTI_PART`, 6 `MC` (`term_ausklammern`).
- Nebenwirkung beim Setzen: Der Trigger `task_solutions_pruef_version` zählt `tasks.pruef_version` der Aufgabe
  hoch (L5 sieht einen neuen Stand). Sonst ändert sich an `tasks` nichts.

## Regeln, die das Nachrechen-Skript durchsetzt (`tools/hinweise-e3-lib.mjs`)

- Genau drei Stufen, jede höchstens zwei Sätze und 200 Zeichen, keine zwei gleichen Texte.
- Kein „richtig“, „falsch“, „Fehler“, keine Wertung („super“, „leicht“, „einfach“), keine Sie-Form.
- Schreibweise wie in den Lösungen: `−`, `·`, `x²`; kein ASCII-Minus zwischen Termen, kein `*`, `^`, `$`.
- Jede Zahl ist belegt: Sie steht in der Aufgabe, ist `0` (Nullprodukt, „= 0“), oder ein Beleg rechnet sie
  exakt nach — Termumformung (`≡`, gleichwertig als Polynom), Gleichungsumformung (`gl`, (L−R) bleibt bis auf
  einen Faktor gleich) oder Rechnung (`=`). Die Eingangszahlen eines Belegs müssen selbst belegt sein; der
  umgeformte Term steht wörtlich im Text.
- Stufe 1 nennt nur Zahlen aus der Aufgabe.
- Keine Stufe nennt ein Ergebnis: keine Zuweisung „x = Lösung“ (bzw. die gesuchte Größe, z. B. `b`, `t`), kein
  „die Lösung ist …“, keine Lösungszahl frei im Text. Eine Lösungszahl darf nur innerhalb eines belegten Terms
  stehen (z. B. `3x · (x − 4)` in Stufe 3).
- Ein genanntes Fehlbild steht in `known_errors` der Aufgabe.
- Abdeckung: jede Session-Aufgabe des Skills aus dem Bestand hat einen Eintrag, kein Eintrag ohne Aufgabe; keine
  Aufgabe mit vorhandenen Hinweisen, ohne Einsatz `session` oder aus VERA8.

Was das Skript nicht sieht (Inhalt, Passung zum Lösungsweg, indirektes Verraten), prüft die Zweitprüfung.

## Abweichungen vom Auftrag

1. **Keine Formeln in `$…$`.** Der Auftrag sagt „Formeln in $…$ wie in den Lösungen“. Keine einzige Lösung in Prod
   nutzt `$` (dbread 12.10.: 0 von 1128 `task_solutions.solution`); die Lösungen der 49 Aufgaben schreiben
   `3x² − 12x = 0` als Klartext mit Unicode. Die Hinweise folgen den Lösungen. Ob das Tablet `$…$` in Hinweisen
   setzen würde, ist offen (Hinweise haben kein `formeln`-Feld wie die Erklärschritte).
2. **„Wir-Form (F2b)“:** Eine Datei F2b gibt es im Repo nicht (Suche in `docs/` und `git log --all`). Umgesetzt:
   Du-Form; Wir-Form in Stufe 3, wo wir den Weg gemeinsam gehen („Wir klammern x aus: …“).

## Zweitprüfung

Frischer Claude-Code-Subagent, der die Hinweise nicht geschrieben hat, nur lesend (keine API, kein Schlüssel).
Er rechnet jede Aufgabe und jede Zahl selbst nach und urteilt je Aufgabe „ok“, „muss“ oder „kann“. Protokoll je
Skill: `hinweise-e3-zweitpruefung-<skill>.md`.

### gleichung_quadr_faktor (Muster)

| Aufgabe | Runde 1 | Was daraus wurde | Runde 2 |
|---|---|---|---|
| faktor-01 | ok; kann: Fehlbild `vorzeichen_aus_klammer` fehlt | Stufe 3 spricht es an („wann die Klammer null wird“) | ok; kann: Satz vom Nullprodukt fehlt jetzt → wieder aufgenommen |
| faktor-02 | **muss**: Stufe 3 „auf beiden Seiten − 5“ verrät x = −5 (Teilaufgabe 1) | Stufe 3 neu: „die Zahl neben x auf die andere Seite bringen“ | ok |
| faktor-03 | ok; kann: Stufe 1 nennt den Ansatz schon | bleibt: Stufe 1 soll laut Regel den passenden Ansatz nennen | – (Prüfer: tragfähig) |
| faktor-04 | ok; kann: Stufe 3 verkürzt | Vorschlag übernommen | ok |
| faktor-05 | ok; kann: Fehlbild `division_vergessen` fehlt | Stufe 3: „rechne, bis t allein steht“ | ok |
| faktor-06 | ok | – | – |

Rechenfehler: keiner. Jedes genannte Fehlbild steht in `known_errors` der Aufgabe.
