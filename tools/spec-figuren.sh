#!/usr/bin/env bash
# spec-figuren.sh — erzeugt die sechs Figuren-Specs.
#
# Sie unterscheiden sich fast nur im Figurtyp, deshalb ein Generator statt sechs
# fast gleicher Dateien von Hand. Danach jede einzeln durchsehen und die Abschnitte
# "Geometrie" und "Nicht-Ziele" anpassen — dort steckt das Fachliche.
#
#   bash tools/spec-figuren.sh

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
mkdir -p specs/active

erzeuge() {
  local id="$1" figur="$2" params="$3" geometrie="$4"
  local datei="specs/active/figur-${id}.md"

  if [[ -e "$datei" ]]; then echo "  · $datei besteht — übersprungen"; return; fi

  cat > "$datei" <<EOF
---
id: figur-${id}
type: code
repo: edvancev1
branch: spec/figur-${id}
depends_on: []
gates:
  - npm run typecheck
  - npm test -- figur-${id}
---

## Ziel

Ein parametrischer SVG-Generator für **${figur}**, nach dem Muster des bestehenden
Koordinatensystem-Generators (PR #96). Er nimmt Parameter entgegen und liefert ein
SVG, das im React-Native-Client gerendert werden kann.

## Kontext

- Der Koordinatensystem-Generator ist die Vorlage: gleiche Schnittstelle, gleiche
  Ablage, gleiche Namenskonventionen. Erst ansehen, dann bauen.
- Figuren werden über \`task_figures\` (A19) an eine Aufgabe gebunden:
  \`generator\`, \`params\`, \`svg_hash\`, \`alt_text\`.
- Das SVG muss in React Native über react-native-svg darstellbar sein — kein CSS,
  keine externen Schriften, keine \`<foreignObject>\`.
- \`alt_text\` ist Pflicht und wird aus den Parametern erzeugt, nicht von Hand gesetzt.

## Geometrie

${geometrie}

## Akzeptanz

- Generator \`${id}\` mit den Parametern: ${params}
- Erzeugt gültiges SVG mit fester \`viewBox\`, unabhängig von den Parameterwerten
- Bei gleichen Parametern gleiches SVG — byteweise, damit \`svg_hash\` trägt
- Ungültige Parameter (negativ, null, ausserhalb des Wertebereichs) führen zu einem
  klaren Fehler, nicht zu einer kaputten Figur
- \`alt_text\` wird aus den Parametern erzeugt und beschreibt die Figur in einem Satz
- Tests in \`tests/figur-${id}.test.ts\`: gültige Parameter, Randwerte, ungültige
  Parameter, Reproduzierbarkeit des Hashes

## Nicht-Ziele

- Keine Anbindung an konkrete Aufgaben — nur der Generator
- Keine Änderung an \`task_figures\` oder am Koordinatensystem-Generator
- Keine Interaktivität, keine Animation
- Keine Beschriftung ausserhalb dessen, was die Geometrie verlangt
EOF
  echo "  ✓ $datei"
}

echo
echo "══ Figuren-Specs"
echo

erzeuge saeulendiagramm "ein Säulendiagramm" \
  "\`werte: number[]\`, \`beschriftungen: string[]\`, \`achsentitel?: string\`, \`max?: number\`" \
  "Senkrechte Säulen gleicher Breite, gleicher Abstand. Y-Achse mit Teilstrichen bei
runden Werten. Skalierung so, dass die höchste Säule etwa 85 % der Zeichenfläche
einnimmt. Beschriftung unter jeder Säule."

erzeuge baumdiagramm "ein Baumdiagramm" \
  "\`stufen: { zweige: { beschriftung: string, wahrscheinlichkeit?: string }[] }[]\`" \
  "Waagerecht von links nach rechts. Zwei bis drei Stufen. Zweige als gerade Linien,
Wahrscheinlichkeiten an den Zweigen, Endergebnisse rechts. Die Beschriftung darf
sich nicht überlappen — Höhe der Zeichenfläche wächst mit der Zahl der Pfade."

erzeuge urne "eine Urne mit Kugeln" \
  "\`kugeln: { farbe: string, anzahl: number }[]\`, \`beschriftet?: boolean\`" \
  "Gefäßumriss, darin die Kugeln versetzt angeordnet, sodass alle sichtbar bleiben.
Farben aus dem Edvance-Token-Satz, nicht frei gewählt. Bei \`beschriftet\` eine Zahl
je Farbe daneben. Bis 20 Kugeln darstellbar."

erzeuge rechteck "ein Rechteck oder Quadrat" \
  "\`laenge: number\`, \`breite: number\`, \`einheit?: string\`, \`diagonale?: boolean\`" \
  "Massstäblich, solange das Seitenverhältnis zwischen 1:4 und 4:1 liegt; darüber
gestaucht mit sichtbarem Bruchzeichen an den Seiten. Masse an den Seiten
aussen. Rechter Winkel an einer Ecke markiert."

erzeuge dreieck "ein Dreieck" \
  "\`grundseite: number\`, \`hoehe: number\`, \`art?: 'beliebig'|'rechtwinklig'|'gleichschenklig'\`, \`einheit?: string\`" \
  "Grundseite waagerecht. Höhe als gestrichelte Linie mit rechtem Winkel zur
Grundseite eingezeichnet. Bei \`rechtwinklig\` der rechte Winkel markiert. Masse
aussen an Grundseite und Höhe."

erzeuge winkel "einen Winkel" \
  "\`grad: number\`, \`benennung?: string\`, \`mit_bogen?: boolean\`" \
  "Zwei Schenkel vom Scheitel aus, der untere waagerecht. Winkelbogen zwischen den
Schenkeln, Gradzahl daran. Bei 90 Grad das rechteckige Zeichen statt des Bogens.
Muss von 1 bis 359 Grad korrekt darstellen, auch überstumpfe Winkel."

echo
echo "  Jede Datei einzeln durchsehen — 'Geometrie' und 'Nicht-Ziele' sind Vorschläge."
echo "  Dann:  node orchestrator/orch.mjs list"
echo
