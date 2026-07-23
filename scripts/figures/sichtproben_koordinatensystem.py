#!/usr/bin/env python3
"""
Schreibt Sichtproben des Koordinatensystem-Generators auf den Windows-Desktop.

    python3 scripts/figures/sichtproben_koordinatensystem.py

Ziel: <Desktop>/edvance-assets/koordinatensystem/
Die Dateien gehoeren NICHT ins Repo — nur der Generator wird versioniert.

Neben den SVGs entsteht eine `index.html`. Die ist der eigentliche Punkt der
Uebung: Ein SVG allein im Browser sagt nichts darueber, ob es auf seinem TRAEGER
funktioniert. Die Seite legt die dunkle Variante auf den Buehnen-Verlauf und die
helle auf weisses Papier — dort entscheidet sich, ob ein Gitter zu laut ist oder
eine Achse verschwindet.

Der Lauf prueft sich selbst: Jede Datei wird zweimal erzeugt und byteweise
verglichen. Weicht etwas ab, bricht er ab, statt ein Ergebnis abzulegen, dem
man nicht trauen kann.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from figures.koordinatensystem import koordinatensystem  # noqa: E402
from figures.tokens import pruefe_drift  # noqa: E402

ORDNER = 'edvance-assets/koordinatensystem'

# Rasterbreite der Sichtprobe. Im SVG-Quelltext sieht man nicht, ob die
# Achsenbeschriftung bei realer Groesse lesbar ist — ein PNG in Anzeigebreite
# schon. 400 px ist etwa die Breite auf der 340-px-Buehne plus Rand.
PNG_BREITE = 400

# Bühnen-Verlauf und Overlay der Vorschau — gemessen aus src/styles/tokens.css
# (--color-stage-top/-mid/-bottom) bzw. der Buehne in edvance-app.
STAGE_TOP, STAGE_MID, STAGE_BOTTOM = '#2E3E63', '#1E2B49', '#14213D'
STAGE_OVERLAY = 'rgba(11,17,31,0.5)'

# Jede Probe zielt auf genau eine Eigenschaft, die man SEHEN muss, um sie zu
# pruefen. Reine Rechenfehler faengt der Test ab; hier geht es um das Bild.
PROBEN: list[tuple[str, str, dict]] = [
    ('leer', 'Nur Achsen und Gitter — traegt das Raster, ohne den Inhalt zu uebertoenen?', dict(
        x_min=-5, x_max=5, y_min=-5, y_max=5,
    )),
    ('gerade', 'Eine Gerade mit Beschriftung.', dict(
        x_min=-5, x_max=5, y_min=-5, y_max=5,
        funktionen=[{'typ': 'linear', 'm': 2, 'b': -1, 'label': 'f(x) = 2x - 1'}],
    )),
    ('steigung-eins', 'DIE SKALENPROBE: m = 1 muss exakt unter 45 Grad stehen.', dict(
        x_min=-4, x_max=4, y_min=-4, y_max=4,
        funktionen=[{'typ': 'linear', 'm': 1, 'b': 0, 'label': 'm = 1'}],
    )),
    ('zwei-geraden', 'Betont gegen normal — ist die Hierarchie auf einen Blick da?', dict(
        x_min=-6, x_max=6, y_min=-6, y_max=6,
        funktionen=[
            {'typ': 'linear', 'm': 0.5, 'b': 2, 'label': 'g'},
            {'typ': 'linear', 'm': -1, 'b': -1, 'label': 'f', 'betont': True},
        ],
    )),
    ('schnittpunkt', 'Zwei Geraden plus markierter Schnittpunkt.', dict(
        x_min=-5, x_max=5, y_min=-5, y_max=5,
        funktionen=[
            {'typ': 'linear', 'm': 1, 'b': 1, 'label': 'f'},
            {'typ': 'linear', 'm': -0.5, 'b': 4, 'label': 'g'},
        ],
        punkte=[{'x': 2, 'y': 3, 'label': 'S(2|3)', 'betont': True}],
    )),
    ('parabel', 'Normalparabel, Scheitel im Fenster.', dict(
        x_min=-4, x_max=4, y_min=-2, y_max=10,
        funktionen=[{'typ': 'quadratisch', 'a': 1, 'b': 0, 'c': 0,
                     'label': 'f(x) = x²', 'betont': True}],
    )),
    ('parabel-geteilt', 'Scheitel UNTER dem Fenster: zwei Aeste, keine Sehne quer durchs Bild.', dict(
        x_min=-5, x_max=5, y_min=4, y_max=20,
        funktionen=[{'typ': 'quadratisch', 'a': 1, 'b': 0, 'c': 0, 'label': 'x²'}],
    )),
    ('parabel-nullstellen', 'Parabel mit den beiden Nullstellen als Punkte.', dict(
        x_min=-5, x_max=5, y_min=-6, y_max=6,
        funktionen=[{'typ': 'quadratisch', 'a': 0.5, 'b': 0, 'c': -2,
                     'label': 'f', 'betont': True}],
        punkte=[{'x': -2, 'y': 0, 'label': 'N₁'}, {'x': 2, 'y': 0, 'label': 'N₂'}],
    )),
    ('ohne-gitter', 'Gitter aus — bleibt die Abbildung lesbar?', dict(
        x_min=-5, x_max=5, y_min=-5, y_max=5, gitter=False,
        funktionen=[{'typ': 'linear', 'm': -2, 'b': 3, 'label': 'f'}],
    )),
    ('verschoben', 'Ursprung NICHT im Fenster: Achsen am Rand, Teilstriche mit echten Werten.', dict(
        x_min=2, x_max=10, y_min=2, y_max=10,
        funktionen=[{'typ': 'linear', 'm': 1, 'b': 1, 'label': 'f'}],
        punkte=[{'x': 5, 'y': 6, 'label': 'P(5|6)'}],
    )),
    ('flach-und-breit', 'Asymmetrisches Fenster (20 x 4) — die Skala darf NICHT nachgeben.', dict(
        x_min=-10, x_max=10, y_min=-2, y_max=2,
        funktionen=[{'typ': 'linear', 'm': 0.1, 'b': 0, 'label': 'm = 0,1'}],
    )),
    ('eigene-achsen', 'Eigene Achsenbeschriftung (Sachkontext).', dict(
        x_min=0, x_max=8, y_min=0, y_max=8,
        achsen={'x': 'Zeit t (h)', 'y': 'Weg s (km)'},
        funktionen=[{'typ': 'linear', 'm': 0.75, 'b': 0, 'label': 's(t)', 'betont': True}],
    )),
]


def desktop() -> Path:
    """
    Findet den Desktop. Beide Varianten werden geprueft — bei OneDrive-Umleitung
    liegt er unter <user>/OneDrive/Desktop. Wird keiner gefunden, bricht die
    Funktion ab, statt einen Pfad zu raten und Dateien irgendwo abzulegen.
    """
    basis = Path('/mnt/c/Users')
    if not basis.is_dir():
        raise SystemExit('Kein /mnt/c/Users — laeuft das hier ausserhalb von WSL?')

    kandidaten: list[Path] = []
    for nutzer in sorted(basis.iterdir()):
        if nutzer.name in {'All Users', 'Default', 'Default User', 'Public', 'WsiAccount'}:
            continue
        kandidaten += [nutzer / 'Desktop', nutzer / 'OneDrive' / 'Desktop']

    gefunden = [pfad for pfad in kandidaten if pfad.is_dir()]
    if not gefunden:
        geprueft = '\n  '.join(str(k) for k in kandidaten)
        raise SystemExit(f'Kein Desktop gefunden. Geprueft:\n  {geprueft}')
    return gefunden[0]


def dateiname(name: str, theme: str) -> str:
    return f'koordinatensystem-{name}-{theme}.svg'


def finde_png_wandler():
    """
    Sucht einen Weg, ein SVG bei PNG_BREITE zu rastern. Zwei bekannte, in KEINER
    Reihenfolge bevorzugte Wege — der erste vorhandene gewinnt:

      cairosvg      Python-Bibliothek (pip install cairosvg --break-system-packages)
      rsvg-convert  Kommandozeile aus librsvg (apt install librsvg2-bin)

    Rueckgabe: (name, wandler) mit wandler(svg_text, ziel_pfad) -> None, oder
    (None, None), wenn keiner da ist. Dann wird GEMELDET, nicht gebastelt: kein
    handgeschriebener PNG-Encoder, keine halbe Loesung.
    """
    try:
        import cairosvg  # type: ignore

        def per_cairo(svg: str, ziel: Path) -> None:
            cairosvg.svg2png(bytestring=svg.encode('utf-8'),
                             write_to=str(ziel), output_width=PNG_BREITE)

        return 'cairosvg', per_cairo
    except ImportError:
        pass

    if shutil.which('rsvg-convert'):
        def per_rsvg(svg: str, ziel: Path) -> None:
            subprocess.run(
                ['rsvg-convert', '-w', str(PNG_BREITE), '-o', str(ziel), '-'],
                input=svg.encode('utf-8'), check=True,
            )

        return 'rsvg-convert', per_rsvg

    return None, None


def vorschau(eintraege: list[tuple[str, str, str, str]]) -> str:
    """Eine Seite, die jede Probe auf ihrem echten Traeger zeigt."""
    bloecke = []
    for name, zweck, datei_dunkel, datei_hell in eintraege:
        bloecke.append(f"""  <section>
    <h2>{name}</h2>
    <p class="zweck">{zweck}</p>
    <div class="paar">
      <figure class="buehne"><img src="{datei_dunkel}" alt=""><figcaption>dunkel — Buehne</figcaption></figure>
      <figure class="papier"><img src="{datei_hell}" alt=""><figcaption>hell — Eltern-Report</figcaption></figure>
    </div>
  </section>""")

    return f"""<!doctype html>
<html lang="de">
<meta charset="utf-8">
<title>Sichtproben — Koordinatensystem</title>
<style>
  body {{ margin: 0; padding: 32px; background: #14213D; color: #F7F5EE;
         font-family: 'Schibsted Grotesk', Helvetica, Arial, sans-serif; }}
  h1 {{ font-size: 22px; font-weight: 600; }}
  .hinweis {{ color: rgba(247,245,238,0.55); max-width: 70ch; line-height: 1.6; }}
  section {{ margin: 40px 0; }}
  h2 {{ font-size: 15px; text-transform: uppercase; letter-spacing: 1.6px;
        color: rgba(247,245,238,0.55); font-weight: 600; }}
  .zweck {{ color: rgba(247,245,238,0.75); margin: 4px 0 14px; }}
  .paar {{ display: flex; gap: 20px; flex-wrap: wrap; align-items: flex-start; }}
  figure {{ margin: 0; padding: 18px; border-radius: 14px; }}
  figcaption {{ margin-top: 10px; font-size: 12px; text-transform: uppercase;
                letter-spacing: 1.2px; }}
  .buehne {{ background:
      linear-gradient({STAGE_OVERLAY}, {STAGE_OVERLAY}),
      linear-gradient(168deg, {STAGE_TOP} 0%, {STAGE_MID} 50%, {STAGE_BOTTOM} 100%);
      color: rgba(247,245,238,0.55); }}
  .papier {{ background: #FFFFFF; color: #4A4A47; }}
  img {{ display: block; max-width: 100%; height: auto; }}
</style>
<h1>Sichtproben — Koordinatensystem</h1>
<p class="hinweis">Links auf der Buehne (dunkel), rechts auf Papier (hell). Die
SVGs sind transparent — was hier als Hintergrund erscheint, gehoert zum Traeger,
nicht zur Abbildung. Die Schrift ist eine Fallback-Kette; ob am Geraet wirklich
Schibsted Grotesk greift, ist dort zu bestaetigen.</p>
{chr(10).join(bloecke)}
</html>
"""


def main() -> None:
    for befund in pruefe_drift():
        print(f'WARNUNG Token-Drift: {befund}')

    ziel = desktop() / ORDNER
    ziel.mkdir(parents=True, exist_ok=True)

    png_name, png_wandler = finde_png_wandler()

    eintraege: list[tuple[str, str, str, str]] = []
    geschrieben = 0
    png_geschrieben = 0

    for name, zweck, argumente in PROBEN:
        namen_je_theme = {}
        for theme in ('dunkel', 'hell'):
            svg = koordinatensystem(**argumente, theme=theme)

            # Selbstprobe: derselbe Aufruf muss dasselbe Byte-fuer-Byte liefern.
            if koordinatensystem(**argumente, theme=theme) != svg:
                raise SystemExit(f'NICHT DETERMINISTISCH: {name}/{theme} — Lauf abgebrochen.')

            datei = ziel / dateiname(name, theme)
            datei.write_text(svg, encoding='utf-8')
            namen_je_theme[theme] = datei.name
            geschrieben += 1

            if png_wandler is not None:
                png_wandler(svg, datei.with_suffix('.png'))
                png_geschrieben += 1

        eintraege.append((name, zweck, namen_je_theme['dunkel'], namen_je_theme['hell']))

    (ziel / 'index.html').write_text(vorschau(eintraege), encoding='utf-8')

    print(f'{geschrieben} SVG + index.html geschrieben nach:')
    print(f'  {ziel}')
    print('Windows-Pfad:')
    print('  ' + str(ziel).replace('/mnt/c/', 'C:\\').replace('/', '\\'))

    if png_wandler is not None:
        print(f'{png_geschrieben} PNG bei {PNG_BREITE} px Breite (via {png_name}) daneben geschrieben.')
    else:
        print(f'KEINE PNG geschrieben: weder cairosvg noch rsvg-convert gefunden. '
              f'Fuer die {PNG_BREITE}-px-Sichtprobe eines installieren:')
        print('  pip install cairosvg --break-system-packages')
        print('  # oder: sudo apt install librsvg2-bin')


if __name__ == '__main__':
    main()
