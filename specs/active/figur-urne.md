---
id: figur-urne
type: code
repo: edvancev1
branch: spec/figur-urne
depends_on: []
gates:
  - npm run typecheck
  - npm test -- figur-urne
---

## Ziel

Ein parametrischer SVG-Generator für **eine Urne mit Kugeln**, nach dem Muster des bestehenden
Koordinatensystem-Generators (PR #96). Er nimmt Parameter entgegen und liefert ein
SVG, das im React-Native-Client gerendert werden kann.

## Kontext

- Der Koordinatensystem-Generator ist die Vorlage: gleiche Schnittstelle, gleiche
  Ablage, gleiche Namenskonventionen. Erst ansehen, dann bauen.
- Figuren werden über `task_figures` (A19) an eine Aufgabe gebunden:
  `generator`, `params`, `svg_hash`, `alt_text`.
- Das SVG muss in React Native über react-native-svg darstellbar sein — kein CSS,
  keine externen Schriften, keine `<foreignObject>`.
- `alt_text` ist Pflicht und wird aus den Parametern erzeugt, nicht von Hand gesetzt.

## Geometrie

Gefäßumriss, darin die Kugeln versetzt angeordnet, sodass alle sichtbar bleiben.
Farben aus dem Edvance-Token-Satz, nicht frei gewählt. Bei `beschriftet` eine Zahl
je Farbe daneben. Bis 20 Kugeln darstellbar.

## Akzeptanz

- Generator `urne` mit den Parametern: `kugeln: { farbe: string, anzahl: number }[]`, `beschriftet?: boolean`
- Erzeugt gültiges SVG mit fester `viewBox`, unabhängig von den Parameterwerten
- Bei gleichen Parametern gleiches SVG — byteweise, damit `svg_hash` trägt
- Ungültige Parameter (negativ, null, ausserhalb des Wertebereichs) führen zu einem
  klaren Fehler, nicht zu einer kaputten Figur
- `alt_text` wird aus den Parametern erzeugt und beschreibt die Figur in einem Satz
- Tests in `tests/figur-urne.test.ts`: gültige Parameter, Randwerte, ungültige
  Parameter, Reproduzierbarkeit des Hashes

## Nicht-Ziele

- Keine Anbindung an konkrete Aufgaben — nur der Generator
- Keine Änderung an `task_figures` oder am Koordinatensystem-Generator
- Keine Interaktivität, keine Animation
- Keine Beschriftung ausserhalb dessen, was die Geometrie verlangt
