#!/usr/bin/env python3
"""
Die Farben der Abbildungen — GEMESSEN, nicht erfunden.

Jeder Wert unten steht so in `src/styles/tokens.css` (Zeilennummern als
Herkunft dahinter). Nichts hier ist eine Designentscheidung dieses Moduls; die
einzige Entscheidung ist die ZUORDNUNG von Token zu Rolle (Gitter, Achse,
Kurve), und die steht als Kommentar an der Rolle.

WARUM KOPIERT UND NICHT GELESEN: Ein Generator, der beim Rendern eine CSS-Datei
parst, ist vom Arbeitsverzeichnis abhaengig und faellt um, sobald er aus einem
anderen Ordner laeuft. Die Kopie ist dafuer driftgefaehrdet — genau deshalb gibt
es `pruefe_drift()`: findet die Funktion `tokens.css`, vergleicht sie Wert fuer
Wert und meldet jede Abweichung. Der Test ruft sie auf. Damit kann die Kopie
veralten, aber nicht unbemerkt.

ZWEI THEMES, WEIL ZWEI TRAEGER:
- 'dunkel': Die Abbildung sitzt auf der Schueler-BUEHNE, einer dunklen Flaeche
  (rgba(11,17,31,0.5) ueber dem Stage-Gradient). Traeger ist Navy.
- 'hell':   Der Eltern-Report hat Druck-CSS. Traeger ist weisses Papier.
Ein Schema kann beides nicht: Was auf Navy traegt, ist auf Papier unsichtbar.

HINTERGRUND IST IMMER TRANSPARENT. Kein Theme fuellt eine Flaeche — die
Abbildung liegt auf dem Traeger, sie bringt keinen eigenen mit.
"""

from __future__ import annotations

import re
from pathlib import Path

try:
    from .svg_basis import Farbe
except ImportError:
    # Direkt aufgerufen (`python3 scripts/figures/tokens.py`) statt als Paket
    # importiert — dann gibt es kein Elternpaket fuer den relativen Import.
    from svg_basis import Farbe  # type: ignore[no-redef]

# ── Gemessene Werte aus src/styles/tokens.css ────────────────────────────────
# Token-Name -> Hex. Genau diese Menge prueft `pruefe_drift()` gegen die Datei.
GEMESSEN: dict[str, str] = {
    'color-stage-text': '#F7F5EE',      # tokens.css:136 — warmes Off-White (Typo auf der Buehne)
    'color-gold-altgold': '#D4A843',    # tokens.css:56  — mattes Altgold, kein Leuchtakzent
    'color-border': '#E8E8E5',          # tokens.css:42  — Linie auf hellem Grund
    'color-text-secondary': '#4A4A47',  # tokens.css:46  — Sekundaertext auf Papier
    'color-report-navy': '#102038',     # tokens.css:65  — Eltern-Report, Marken-Navy
    'color-report-gold': '#DA9721',     # tokens.css:66  — Eltern-Report, Gold (dunkler als Altgold,
                                        #                  damit es auf Papier noch traegt)
}

# Die Buehnen-Typo laeuft in der App ueber abgestufte Deckkraft derselben
# Cream-Achse (edvance-app/src/design/tokens.ts: alpha.creamMuted 0.55,
# alpha.creamFaint 0.45, alpha.glassBorder 0.18). Dieselbe Abstufung hier —
# eine Alpha-Stufe auf einem gemessenen Ton ist keine neue Farbe.
#
# Die Deckkraft steht als eigener Wert und NICHT als rgba()-String: rgba() ist
# in SVG-1.1-Praesentationsattributen ungueltig und wird von Renderern nach
# Schwarz verworfen. Siehe `Farbe` in svg_basis.py.
def _cream(deckkraft: float) -> Farbe:
    return Farbe(GEMESSEN['color-stage-text'], deckkraft)


class Palette:
    """Die fuenf Rollen, die eine Abbildung braucht. Mehr gibt es nicht."""

    def __init__(
        self,
        gitter: Farbe,
        achse: Farbe,
        beschriftung: Farbe,
        kurve: Farbe,
        kurve_betont: Farbe,
    ) -> None:
        self.gitter = gitter
        self.achse = achse
        self.beschriftung = beschriftung
        self.kurve = kurve
        self.kurve_betont = kurve_betont


# Die Hierarchie ist in beiden Themes dieselbe, nur der Traeger dreht sich um:
# Gitter am leisesten, Achse als Rahmen, Kurve als lauteste Ebene. Der betonte
# Strich ist Gold — mattes Altgold auf Navy, das dunklere Report-Gold auf Papier.
PALETTEN: dict[str, Palette] = {
    'dunkel': Palette(
        gitter=_cream(0.18),                          # wie alpha.glassBorder
        achse=_cream(0.55),                           # wie alpha.creamMuted
        beschriftung=_cream(0.55),
        kurve=_cream(1.0),                            # volle Cream — die lauteste Ebene
        kurve_betont=Farbe(GEMESSEN['color-gold-altgold']),
    ),
    'hell': Palette(
        gitter=Farbe(GEMESSEN['color-border']),
        achse=Farbe(GEMESSEN['color-text-secondary']),
        beschriftung=Farbe(GEMESSEN['color-text-secondary']),
        kurve=Farbe(GEMESSEN['color-report-navy']),
        kurve_betont=Farbe(GEMESSEN['color-report-gold']),
    ),
}

THEMES = tuple(PALETTEN)

# Fallback-Kette statt blossem Familiennamen: Eine extern geladene SVG hat
# keinen garantierten Zugriff auf die App-Fonts. Ohne Kette faellt der Renderer
# auf eine Serife zurueck und die Abbildung sieht aus wie aus einem anderen
# Produkt. DIE DARSTELLUNG AM GERAET IST ZU BESTAETIGEN.
SCHRIFT = 'Schibsted Grotesk, Helvetica, Arial, sans-serif'


def palette(theme: str) -> Palette:
    if theme not in PALETTEN:
        erlaubt = ', '.join(repr(t) for t in THEMES)
        raise ValueError(f'theme muss eines von {erlaubt} sein, nicht {theme!r}.')
    return PALETTEN[theme]


# ── Driftprüfung ─────────────────────────────────────────────────────────────

def _tokens_css() -> Path | None:
    """Sucht src/styles/tokens.css aufwaerts vom Modul aus. None, wenn nicht da."""
    for ordner in Path(__file__).resolve().parents:
        kandidat = ordner / 'src' / 'styles' / 'tokens.css'
        if kandidat.is_file():
            return kandidat
    return None


def pruefe_drift() -> list[str]:
    """
    Vergleicht GEMESSEN gegen tokens.css. Gibt eine Liste von Klartext-Befunden
    zurueck — leer heisst: deckungsgleich.

    Ausserhalb des Repos (Datei nicht gefunden) wird nicht geraten, sondern ein
    Befund gemeldet. Ein stilles "alles gut" waere hier die schlechtere Antwort.
    """
    pfad = _tokens_css()
    if pfad is None:
        return ['tokens.css nicht gefunden — Drift nicht pruefbar.']

    inhalt = pfad.read_text(encoding='utf-8')
    gefunden = {
        treffer.group(1): treffer.group(2).upper()
        for treffer in re.finditer(r'--([a-z0-9-]+):\s*(#[0-9A-Fa-f]{6})\s*;', inhalt)
    }

    befunde: list[str] = []
    for name, erwartet in sorted(GEMESSEN.items()):
        ist = gefunden.get(name)
        if ist is None:
            befunde.append(f'--{name} steht nicht mehr in tokens.css.')
        elif ist != erwartet.upper():
            befunde.append(f'--{name}: tokens.css sagt {ist}, hier steht {erwartet}.')
    return befunde


if __name__ == '__main__':
    ergebnis = pruefe_drift()
    if ergebnis:
        for zeile in ergebnis:
            print(f'DRIFT: {zeile}')
        raise SystemExit(1)
    print(f'{len(GEMESSEN)} Tokens deckungsgleich mit tokens.css.')
