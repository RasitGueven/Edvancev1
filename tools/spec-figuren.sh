#!/usr/bin/env bash
# spec-figuren.sh — Figuren-Specs nach dem Muster von koordinatensystem.py.
#
# Dritte Fassung. Vorher falsch:
#   1. npm/TypeScript-Gates — der operative Pfad ist Python (upload_figures.py)
#   2. alt_text als Funktion im Generator — das Muster ist ein zweites Modul
#      pruefe_<name>.py mit pruefe(svg, params) -> (bestanden, meldung)
#
# Das tragende Element ist pruefe_<name>.py: es liest das erzeugte SVG zurueck und
# misst nach. Nicht "hat der Generator etwas ausgegeben", sondern "sitzt es am
# rechnerisch richtigen Ort". Genau deshalb ist es das Gate.
#
#   bash tools/spec-figuren.sh [--force]

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
mkdir -p specs/active

FORCE=0; [[ "${1:-}" == "--force" ]] && FORCE=1

erzeuge() {
  local id="$1" figur="$2" params="$3" geometrie="$4" pruefungen="$5"
  local datei="specs/active/figur-${id}.md"
  if [[ -e "$datei" && "$FORCE" -eq 0 ]]; then echo "  · $datei besteht"; return; fi

  cat > "$datei" <<EOF
---
id: figur-${id}
type: code
repo: edvancev1
branch: spec/figur-${id}
depends_on: []
gates:
  - python3 -m pytest scripts/figures/test_${id}.py -q
  - python3 -c "import sys; sys.path.insert(0,'scripts/figures'); import ${id}, pruefe_${id}"
  - bash -c 'test \$(grep -c "^def pruefe_" scripts/figures/pruefe_${id}.py) -ge 3'
  - bash -c 'grep -q "negativkontrolle\|Negativkontrolle" scripts/figures/test_${id}.py'
---

## Ziel

Ein parametrischer SVG-Generator für **${figur}**, nach dem Muster von
\`scripts/figures/koordinatensystem.py\`.

## Kontext

**Erst \`koordinatensystem.py\` und \`pruefe_koordinatensystem.py\` lesen.** Das Muster
steht dort vollständig; es wird übernommen, nicht neu erfunden.

Der Aufbau ist zweiteilig:

- **\`scripts/figures/${id}.py\`** mit \`zeichne(params: dict, theme: str) -> str\`
- **\`scripts/figures/pruefe_${id}.py\`** mit \`pruefe(svg: str, params: dict) -> tuple[bool, str]\`

\`pruefe\` ist der wichtigere Teil. Es **liest das erzeugte SVG zurück und misst nach** —
Koordinaten aus dem SVG parsen, gegen das rechnen, was die Parameter verlangen, und
Abweichungen als Befunde melden. \`bestanden == True\` nur bei leerer Befundliste.
\`upload_figures.py\` lädt nichts hoch, was \`pruefe\` nicht besteht.

Der Grund steht im Docstring der Vorlage: *„Ein falsches Bild ist schlimmer als kein
Bild. Bei Text fällt ein Fehler in der fachlichen Prüfung auf; einen Zahlendreher in
der Skalierung sieht niemand."*

Weiteres:

- \`svg_basis.py\` liefert Zahlformatierung, Escaping, Element-Bau. Importieren, nicht nachbauen.
- \`tokens.py\` ist die **einzige** Quelle für Farbwerte. Keine Hex-Codes im Generator.
- \`pruefungen.py\` enthält die gemeinsamen Eingabeprüfungen. Parameter werden **vor**
  dem Zeichnen geprüft. Unbekannte Schlüssel sind ein Fehler, kein stiller Verzicht —
  \`'labl'\` statt \`'label'\` würde sonst die Beschriftung verschlucken.
- \`upload_figures.py\` hat in \`_lade_generator\` eine Positivliste, die derzeit nur
  \`koordinatensystem\` kennt. Der neue Generator muss dort eingetragen werden.
  **Der Kommentar dort verweist auf eine „Positivliste in der Migration"** — prüfen,
  ob \`task_figures.generator\` einen CHECK trägt. Wenn ja, braucht es zusätzlich eine
  Migration nach dem üblichen Schema, und \`tools/schema-snapshot.sh\` muss neu laufen.
- Gerendert wird über react-native-svg: kein CSS, keine externen Schriften,
  kein \`<foreignObject>\`.
- **alt-Text:** \`task_figures\` trägt den CHECK \`alt_text !~ '[0-9]'\`. Ein Screenreader,
  der die Masse vorliest, löst die Aufgabe. Wo der alt-Text im Vorbild erzeugt wird,
  aus dem Code übernehmen — nicht raten.

## Geometrie

${geometrie}

## Was \`pruefe\` messen muss

${pruefungen}

Dazu, wie im Vorbild: eine **Negativkontrolle** im Test. Ein absichtlich verfälschtes
SVG (eine Koordinate verschoben) muss von \`pruefe\` abgelehnt werden. Ohne sie ist
nicht belegt, dass die Prüfung überhaupt greifen kann.

## Akzeptanz

- \`scripts/figures/${id}.py\` mit \`zeichne(params, theme)\`, Signatur wie im Vorbild
- Parameter: ${params}
- \`scripts/figures/pruefe_${id}.py\` mit \`pruefe(svg, params) -> (bestanden, meldung)\`
  und mindestens drei \`pruefe_*\`-Einzelprüfungen
- Gültiges SVG mit fester \`viewBox\`, unabhängig von den Parameterwerten
- Gleiche Parameter → byteweise gleiches SVG, damit \`svg_hash\` trägt
- Ungültige Parameter lösen vor dem Zeichnen einen klaren Fehler aus
- \`scripts/figures/test_${id}.py\`: gültige Parameter, Randwerte je Parameter,
  ungültige Parameter, Reproduzierbarkeit, beide Themes, **Negativkontrolle**
- In \`upload_figures.py\` eingetragen; falls \`task_figures.generator\` einen CHECK
  trägt, zusätzlich eine Migration und \`supabase/schema-erwartet.sql\` neu erzeugt

## Nicht-Ziele

- **Keine TypeScript-Fassung.** \`scripts/figures/rechteck.ts\` und \`svgBasis.ts\` sind
  ein Irrläufer aus einer fehlerhaften Spec. Nicht als Vorlage nehmen, nicht erweitern.
- Keine Farbwerte ausserhalb von \`tokens.py\`
- Keine Änderung an \`koordinatensystem.py\`, \`pruefe_koordinatensystem.py\`,
  \`svg_basis.py\`, \`tokens.py\` oder \`pruefungen.py\`
- Keine Anbindung an konkrete Aufgaben
- Keine Interaktivität, keine Animation
EOF
  echo "  ✓ $datei"
}

echo
echo "══ Figuren-Specs (zeichne + pruefe)"
echo

erzeuge saeulendiagramm "ein Säulendiagramm" \
  "\`werte: list[float]\`, \`beschriftungen: list[str]\`, \`achsentitel: str | None\`, \`max_wert: float | None\`" \
  "Senkrechte Säulen gleicher Breite und gleichen Abstands. Y-Achse mit Teilstrichen bei
runden Werten. Die höchste Säule nimmt etwa 85 % der Zeichenfläche ein. Beschriftung
unter jeder Säule; ab sieben Säulen gekippt, damit nichts überlappt." \
  "- Höhenverhältnis: das Verhältnis zweier Säulenhöhen in Pixeln entspricht dem
  Verhältnis ihrer Werte. Das ist die Prüfung, die einen Skalierungsfehler findet.
- Nulllinie: alle Säulen beginnen auf derselben Pixelhöhe.
- Teilstriche sitzen auf runden Werten, nirgends dazwischen.
- Anzahl der Säulen entspricht der Anzahl der Werte."

erzeuge baumdiagramm "ein Baumdiagramm" \
  "\`stufen: list[list[dict]]\` — je Stufe Zweige mit \`beschriftung\` und optional \`wahrscheinlichkeit\`" \
  "Waagerecht von links nach rechts, zwei bis drei Stufen. Zweige als gerade Linien,
Wahrscheinlichkeiten an den Zweigen, Endergebnisse rechts. Die Höhe der Zeichenfläche
wächst mit der Pfadzahl, damit sich keine Beschriftung überlappt." \
  "- Pfadzahl: die Zahl der Endknoten entspricht dem Produkt der Zweigzahlen je Stufe.
- Jeder Zweig einer Stufe beginnt am Endpunkt seines Elternzweigs — kein loser Ast.
- Beschriftungen überlappen nicht: die senkrechten Abstände zwischen Textankern
  sind grösser als die Zeilenhöhe.
- Alle Wahrscheinlichkeiten einer Verzweigung stehen am zugehörigen Zweig."

erzeuge urne "eine Urne mit Kugeln" \
  "\`kugeln: list[dict]\` mit \`farbe\` (Tokenname) und \`anzahl\`, \`beschriftet: bool\`" \
  "Gefässumriss, darin die Kugeln versetzt angeordnet, sodass alle sichtbar bleiben.
Farben ausschliesslich über \`tokens.py\`. Bei \`beschriftet\` eine Zahl je Farbe daneben.
Bis 20 Kugeln; darüber ein klarer Fehler statt Gedränge." \
  "- Kugelzahl je Farbe im SVG entspricht der Angabe in den Parametern.
- Keine Kugel liegt ausserhalb des Gefässumrisses.
- Keine zwei Kugeln überdecken sich um mehr als einen Radius —
  eine verdeckte Kugel ist eine gezählte, die niemand sieht.
- Alle verwendeten Farbwerte stammen aus \`tokens.py\`."

erzeuge dreieck "ein Dreieck" \
  "\`grundseite: float\`, \`hoehe: float\`, \`art: str\` (beliebig / rechtwinklig / gleichschenklig), \`einheit: str\`" \
  "Grundseite waagerecht. Höhe als gestrichelte Linie mit rechtem Winkel zur Grundseite.
Bei \`rechtwinklig\` der rechte Winkel markiert. Masse aussen. Über 1:4 wird auf den
Bandrand gekappt; die gekappten Seiten tragen dann ein Zickzack, und der alt-Text sagt
es. Eine stille Stauchung wäre der Fehler, den niemand nachsieht." \
  "- Massstäblichkeit: solange das Verhältnis innerhalb 1:4 liegt, entspricht
  Pixelhöhe/Pixelgrundseite dem Verhältnis hoehe/grundseite.
- Ist gekappt worden, existiert das Zickzack-Element — kein stilles Stauchen.
- Die Höhenlinie steht senkrecht auf der Grundseite (Skalarprodukt nahe null).
- Bei \`rechtwinklig\` sitzt das Winkelzeichen an der richtigen Ecke."

erzeuge winkel "einen Winkel" \
  "\`grad: float\`, \`benennung: str | None\`, \`mit_bogen: bool\`" \
  "Zwei Schenkel vom Scheitel, der untere waagerecht. Winkelbogen zwischen den Schenkeln,
Gradzahl daran. Bei genau 90 Grad das rechteckige Zeichen statt des Bogens. Korrekt von
1 bis 359 Grad, auch überstumpf — dort liegt der Bogen aussen." \
  "- Der gemessene Winkel zwischen den beiden Schenkeln im SVG entspricht \`grad\`
  (Toleranz unter 0,5°). Das ist die Kernprüfung.
- Der untere Schenkel ist waagerecht.
- Beide Schenkel gehen vom selben Punkt aus.
- Bei überstumpfem Winkel liegt der Bogen auf der richtigen Seite — sonst zeigt
  die Figur den Gegenwinkel und niemand merkt es.
- Bei genau 90° gibt es kein Bogenelement, sondern das rechteckige Zeichen."

echo
echo "  Rechteck fehlt: liegt als .ts auf dev (PR #113), Portierung als eigene Spec."
echo
echo "  Vor dem ersten Lauf prüfen, ob task_figures.generator einen CHECK traegt:"
echo "    grep -n 'generator' supabase/migrations/*a19*"
echo
