"""Stufe 2 (SEHEN), Teil 1: EMF -> PNG.

Der Aufgabentext der IQB-Items steckt nicht als Text im DOCX, sondern als
EMF-Vektorgrafik. Ein EMF traegt pro Textfragment einen Ankerpunkt. Wir malen
jedes Fragment genau dorthin, wo das EMF es hinschreibt, dazu die Linien
(Tabellenraster, Ankreuzkaestchen, Zeichnungen).

Damit ist die Lesereihenfolge nicht mehr geraten, sondern *sichtbar*: zwei
Spalten stehen nebeneinander, weil sie im EMF nebeneinander stehen. Das Bild
geht an ein Vision-Modell, das es liest wie ein Mensch.

Bewusst kein LibreOffice/PDF: nicht installierbar (kein sudo). Der direkte Weg
ueber die EMF-Koordinaten ist ohnehin naeher an der Quelle — es wird nichts
umbrochen, neu umgebrochen oder geglaettet.
"""
import zipfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from emf import TA_CENTER, TA_RIGHT, parse

FONT_DIR = Path("/usr/share/fonts/truetype/dejavu")
SCALE = 3          # Device-Unit -> Pixel
PAD = 12


def _font(size_px, face=""):
    f = "DejaVuSerif.ttf" if "times" in face.lower() or "serif" in face.lower() else "DejaVuSans.ttf"
    return ImageFont.truetype(str(FONT_DIR / f), max(6, int(round(size_px))))


def render_emf(data, out_png):
    """Ein EMF -> ein PNG. Gibt (png_pfad, breite, hoehe) zurueck."""
    p = parse(data)
    xs, ys = [], []
    for t in p["texts"]:
        xs += [t["x"], t["x"] + max(1, len(t["text"])) * t["size"]]
        ys += [t["y"] - t["size"], t["y"] + t["size"]]
    for ln in p["lines"]:
        xs += [q[0] for q in ln]
        ys += [q[1] for q in ln]
    if not xs:
        xs, ys = [0, p["bounds"][2]], [0, p["bounds"][3]]

    x0, y0, x1, y1 = min(xs), min(ys), max(xs), max(ys)
    w = int((x1 - x0) * SCALE) + 2 * PAD
    h = int((y1 - y0) * SCALE) + 2 * PAD
    img = Image.new("RGB", (max(w, 40), max(h, 24)), "white")
    d = ImageDraw.Draw(img)

    def px(x, y):
        return ((x - x0) * SCALE + PAD, (y - y0) * SCALE + PAD)

    for ln in p["lines"]:
        if len(ln) >= 2:
            d.line([px(*q) for q in ln], fill="black", width=2)

    for t in p["texts"]:
        font = _font(t["size"] * SCALE, t["face"])
        s, dx = t["text"], t["dx"]
        # Breite aus den EMF-Vorschueben, nicht aus DejaVu-Metriken: das Bild
        # soll die Quelle zeigen, nicht unsere Ersatzschrift.
        width = sum(dx) * SCALE if len(dx) == len(s) else font.getlength(s)
        x, y = px(t["x"], t["y"])
        if t["align"] & TA_CENTER == TA_CENTER:
            x -= width / 2
        elif t["align"] & TA_RIGHT:
            x -= width

        if len(dx) == len(s):
            # Zeichenweise an die Original-Vorschuebe setzen. Sonst schieben
            # abweichende Glyphenbreiten Fragmente ineinander und aus zwei
            # Spalten wird optisch eine — der Fehler, den wir gerade beheben.
            cx = x
            for ch, adv in zip(s, dx):
                d.text((cx, y), ch, fill="black", font=font, anchor="ls")
                cx += adv * SCALE
        else:
            d.text((x, y), s, fill="black", font=font, anchor="ls")

    out_png = Path(out_png)
    out_png.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_png)
    return str(out_png), img.width, img.height


MEDIA = (".emf", ".wmf", ".png", ".jpeg", ".jpg", ".gif", ".bmp")


def media_in_docx(docx_path):
    """Bilder in Dokumentreihenfolge (nach Relationship-ID im document.xml).

    Reihenfolge ist inhaltlich relevant: Stamm, dann Abbildung, dann Teilaufgabe.

    Nicht nur EMF: ein Teil der Items traegt den Aufgabentext als *Rasterbild*
    (PNG) im Dokument. Fuer die Vision ist das dieselbe Quelle — fuer das
    Grounding nicht: ein Raster hat keinen Zeichenvorrat, an dem sich eine
    Lesung pruefen liesse (siehe pipeline.py / G1).
    """
    import re
    z = zipfile.ZipFile(docx_path)
    rels = z.read("word/_rels/document.xml.rels").decode("utf-8", "replace")
    rid2tgt = dict(re.findall(r'Id="([^"]+)"[^>]*Target="([^"]+)"', rels))
    doc = z.read("word/document.xml").decode("utf-8", "replace")
    out, seen = [], set()
    for rid in re.findall(r'r:(?:embed|id)="([^"]+)"', doc):
        tgt = rid2tgt.get(rid, "")
        ext = "." + tgt.rsplit(".", 1)[-1].lower() if "." in tgt else ""
        if ext not in MEDIA or rid in seen:
            continue
        seen.add(rid)
        name = "word/" + tgt.lstrip("/") if not tgt.startswith("word/") else tgt
        try:
            out.append((tgt.split("/")[-1], ext.lstrip("."), z.read(name)))
        except KeyError:
            pass
    return out


def emfs_in_docx(docx_path):
    """Nur die EMFs — Rueckwaertskompatibilitaet fuer extract.py (Kalibrierlauf)."""
    return [(n, b) for n, e, b in media_in_docx(docx_path) if e == "emf"]
