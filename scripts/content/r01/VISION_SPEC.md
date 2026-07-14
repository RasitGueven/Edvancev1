# Stufe 2 (SEHEN) — Auftrag an das Vision-Modell

Du liest **Bilder**, keinen Zeichenstrom. Jedes Bild unter `data/r01_render/<item>/`
ist die gerenderte Quelle: jedes Textfragment steht auf dem Pixel, den die
Originaldatei ihm zuweist. Zwei Spalten stehen nebeneinander, weil sie in der
Quelle nebeneinander stehen.

## Warum es dich gibt

Der Altbestand hat den Zeichenstrom der Datei in Record-Reihenfolge
aneinandergehängt. Dabei sind Stämme zerfallen — nicht die Lösungen:

- `2½ Stunden` wurde zu `2 Stunden` (Zähler und Nenner des Bruchs fielen aus dem Satz)
- `Ein gelber Holzwürfel …` wurde zu `EDirne igeertlubremr Hauoflezwinüarnfedle …`
  (zwei nebeneinanderliegende Textblöcke ineinander verschränkt)

Du sollst genau das verhindern: **lies das Bild wie ein Mensch.**

## Was du lieferst — und was nicht

Du lieferst **Stamm, Teilaufgaben, Prompts, Optionen, Einheiten**.

Du lieferst **KEINE Lösungen.** Die Lösung kommt deterministisch aus der
Auswertungsdatei; sie zu raten wäre genau der Fehler, den diese Pipeline behebt.

## Harte Regeln

1. **Nichts erfinden.** Was du nicht lesen kannst, lässt du leer und schreibst es
   in `unsicher`. Ein leeres Feld ist ein Befund; ein geratenes Feld ist ein Bug.
   Jede Behauptung wird anschließend maschinell gegen den Zeichenvorrat der
   Quelle geprüft (G1) — Erfundenes fliegt raus und das Item wird geflaggt.
2. **Sonderzeichen bleiben stehen.** `½`, `¾`, `²`, `€`, `°C`, `km²`, `≈`, `·`.
   Ein Bruch ist ein Bruch: `2½`, nicht `2 1/2` und schon gar nicht `2`.
   Verhältnisse bleiben Verhältnisse: `1:4`.
3. **Optionen in visueller Reihenfolge** — links nach rechts, oben nach unten,
   so wie die Ankreuzkästchen im Bild stehen. Die Auswertung sagt später
   „3. Kästchen"; das zählt gegen *deine* Reihenfolge ab. Reihenfolge falsch =
   Lösung falsch.
4. **Feld-Labels sind kein Prompt.** Zeilen wie `x = __________`, `Antwort:`,
   `mm`, `€` sind das Eingabefeld. Die Einheit gehört nach `unit`, der Rest
   fliegt raus.
5. **Tabellen sind Tabellen.** Steht im Bild ein Raster, setze
   `stem_tabelle_erwartet: true`. Die Tabelle selbst rekonstruiert die Pipeline
   deterministisch aus der Geometrie — du musst sie nicht abtippen.
6. **Abbildungs-Beschriftungen** (`gelb`, `blau`, `Beispiel:`, `Grafik: © IQB`)
   sind nicht Teil des Stamms.

## Ausgabe: `data/r01_vision/<item>.json`

```json
{
  "item": "zeitangabe",
  "gelesen_aus": ["data/r01_render/zeitangabe/00_image1.emf.png"],
  "stem": "",
  "stem_tabelle_erwartet": false,
  "parts": [
    {
      "nr": 1,
      "kind": "mc",
      "prompt": "Wie viele Minuten sind 2½ Stunden?",
      "unit": null,
      "options": [
        {"id": "a", "label": "60 min"},
        {"id": "b", "label": "90 min"},
        {"id": "c", "label": "150 min"},
        {"id": "d", "label": "250 min"}
      ],
      "options_reihenfolge": "visuell von links nach rechts"
    }
  ],
  "unsicher": []
}
```

### Felder

| Feld | Bedeutung |
|---|---|
| `stem` | Gemeinsamer Einleitungstext **vor** den Teilaufgaben. Gibt es keinen (die Frage steht direkt da), dann `""` — nicht die Frage hineinkopieren. |
| `parts[].kind` | `mc` (Ankreuzkästchen), `short_input` (kurze Zahl/Wort), `free_text` (Begründung, Beschreibung, „Erkläre", „Begründe") |
| `parts[].unit` | Einheit des Eingabefelds (`m`, `cm`, `€`, `%`, `°C`, `mm`, `Ecken`), sonst `null` |
| `parts[].options` | nur bei `kind: "mc"`, in visueller Reihenfolge, IDs `a`,`b`,`c`,… |
| `unsicher` | freie Sätze: was unlesbar/mehrdeutig war, wo du die Teilaufgabenzahl der Auswertung widersprichst |

`n_teilaufgaben_laut_auswertung` aus der Queue ist dein **Gegencheck**: Siehst du
eine andere Zahl von Teilaufgaben, dann folge dem Bild und schreib den
Widerspruch nach `unsicher`.

## Rasterbilder

Manche Items (`nur_raster: true` in der Queue) tragen ihren Text als Pixelbild.
Du liest sie genauso — aber es gibt für sie **keinen Zeichenvorrat**, gegen den
die Pipeline dich prüfen könnte. Sei dort besonders zurückhaltend: im Zweifel
`unsicher` statt einer Behauptung.
