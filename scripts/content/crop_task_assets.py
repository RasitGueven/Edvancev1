"""Schneidet den Aufgabenstamm-Text von den VERA-8-Abbildungen ab.

Warum: Die PNGs in data/vera8_assets/ sind Seitenfragmente, keine Figuren. Die
Stamm-PNG (aufgabe_01.png) enthaelt den Aufgabentext UND darunter die Abbildung.
Der Text steht bereits in tasks.question — ihn mit ins Bild zu brennen zeigt ihn
doppelt und verstoesst gegen die i18n-Regel (CLAUDE.md §12: keine Sprache in
Assets). Also: Text oben abschneiden, Abbildung behalten.

Schnittkante: die groesste vertikale Weissluecke im oberen Bilddrittel. Zwischen
Textzeilen liegen wenige Pixel, zwischen Textblock und Abbildung deutlich mehr.
Ergebnis ist NICHT blind zu uebernehmen — jeder Crop wurde visuell abgenommen
(13.07.2026). Neue Items also erst ansehen, dann ausliefern.

Nicht anwendbar auf Eiscafe: dort steht die Figur RECHTS neben dem Text, ein
zeilenweiser Schnitt kann das nicht trennen.

Aufruf: python3 scripts/content/crop_task_assets.py
Ausgabe: data/vera8_assets_cropped/<slug>.png
"""
import os

from PIL import Image

SRC = "data/vera8_assets"
OUT = "data/vera8_assets_cropped"

# Nur handgeprueft freigegebene Stamm-Abbildungen (data/vera8_asset_selection.json).
SLUGS = ["freibad", "muckibude", "wahl", "verbindungsstrecken", "wuerfelturm2", "kreisfiguren"]

INK = 200  # alles dunkler gilt als Tinte
TOP_LIMIT = 0.65  # Schnittkante muss im oberen Bereich liegen


def flatten(path):
    """Transparenz auf Weiss legen — sonst zaehlt jeder transparente Pixel als Tinte."""
    im = Image.open(path).convert("RGBA")
    bg = Image.new("RGBA", im.size, (255, 255, 255, 255))
    return Image.alpha_composite(bg, im).convert("RGB")


def ink_rows(img):
    g = img.convert("L")
    w, h = g.size
    px = g.load()
    return [y for y in range(h) if any(px[x, y] < INK for x in range(w))]


def trim(img):
    g = img.convert("L")
    w, h = g.size
    px = g.load()
    xs = [x for x in range(w) if any(px[x, y] < INK for y in range(h))]
    ys = [y for y in range(h) if any(px[x, y] < INK for x in range(w))]
    return img.crop((xs[0], ys[0], xs[-1] + 1, ys[-1] + 1))


def main():
    os.makedirs(OUT, exist_ok=True)
    for slug in SLUGS:
        src = flatten(f"{SRC}/{slug}/aufgabe_01.png")
        h = src.size[1]
        rows = ink_rows(src)
        gaps = sorted(
            ((rows[i + 1] - rows[i], rows[i + 1]) for i in range(len(rows) - 1) if rows[i + 1] - rows[i] > 1),
            reverse=True,
        )
        top = next((start for _, start in gaps if start < h * TOP_LIMIT), None)
        if top is None:
            print(f"{slug}: keine Schnittkante gefunden — uebersprungen")
            continue
        out = trim(src.crop((0, top, src.size[0], h)))
        out.save(f"{OUT}/{slug}.png", optimize=True)
        print(f"{slug}: Schnitt bei y={top} -> {out.size}")


if __name__ == "__main__":
    main()
