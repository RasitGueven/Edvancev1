"""EMF-Parser: liest Textfragmente MIT Koordinaten und Vektor-Geometrie.

Warum neu (und nicht scripts/content/emf_text.py):
emf_text.py rekonstruiert *Text* und muss dafuer raten, welche Fragmente eine
Zeile bilden. Genau daran ist C01/C02 gescheitert: bei zweispaltigem Layout
klebt es Fragmente aus beiden Spalten zu einer Zeile zusammen
("EDirne igeertlubremr Hauoflezwinuerfedle").

Dieses Modul rekonstruiert *keinen* Text. Es liefert nur, was im EMF
nachweislich steht: pro Fragment die Zeichen und den Punkt, an dem sie stehen.
Die Lesereihenfolge wird nicht erraten, sondern in Stufe 2 (Rendern + Sehen)
aus der tatsaechlichen 2D-Lage abgeleitet — so, wie ein Mensch es auch tut.

Record-Layout nach MS-EMF.
"""
import struct

# --- Record-Typen (MS-EMF 2.1.1) ---
HEADER = 1
POLYGON, POLYLINE = 3, 4
SAVEDC, RESTOREDC = 33, 34
SETWORLDTRANSFORM, MODIFYWORLDTRANSFORM = 35, 36
SELECTOBJECT, DELETEOBJECT = 37, 40
MOVETOEX, LINETO = 27, 54
RECTANGLE = 43
SETTEXTALIGN = 22
EXTTEXTOUTA, EXTTEXTOUTW = 83, 84
POLYGON16, POLYLINE16 = 86, 87
EXTCREATEFONTINDIRECTW = 82

MWT_IDENTITY, MWT_LEFTMULTIPLY, MWT_RIGHTMULTIPLY, MWT_SET = 1, 2, 3, 4
IDENTITY = (1.0, 0.0, 0.0, 1.0, 0.0, 0.0)  # m11 m12 m21 m22 dx dy

TA_UPDATECP = 0x0001
TA_RIGHT, TA_CENTER = 0x0002, 0x0006

# Word setzt mathematische Zeichen als Symbol-Font-Glyphen in die Private Use
# Area (0xF000 + Code). Ohne Ruecksetzung stuende '' statt '=' im Text.
SYMBOL_PUA = {
    0x2B: "+", 0x2D: "−", 0x3D: "=", 0x3C: "<", 0x3E: ">",
    0xB1: "±", 0xB4: "×", 0xB7: "·", 0xBB: "≈", 0xD7: "⋅",
    0xB9: "≠", 0xA3: "≤", 0xB3: "≥", 0xB8: "÷", 0xD6: "√",
    0xA5: "∞", 0x70: "π", 0x61: "α", 0x62: "β", 0x67: "γ",
    0x64: "δ", 0x65: "ε", 0x6C: "λ", 0x6D: "μ", 0x73: "σ",
    0x77: "ω", 0x2F: "/", 0x28: "(", 0x29: ")",
}


def _mul(a, b):
    """a danach b (Punkt * a * b)."""
    return (
        a[0] * b[0] + a[1] * b[2], a[0] * b[1] + a[1] * b[3],
        a[2] * b[0] + a[3] * b[2], a[2] * b[1] + a[3] * b[3],
        a[4] * b[0] + a[5] * b[2] + b[4], a[4] * b[1] + a[5] * b[3] + b[5],
    )


def _apply(m, x, y):
    return (m[0] * x + m[2] * y + m[4], m[1] * x + m[3] * y + m[5])


def _records(data):
    off, n = 0, len(data)
    while off + 8 <= n:
        rtype, size = struct.unpack_from("<II", data, off)
        if size < 8 or off + size > n:
            break
        yield rtype, off, size
        off += size


def _decode(raw, wide):
    """Zeichen dekodieren, Symbol-PUA zuruecksetzen."""
    s = raw.decode("utf-16-le", "replace") if wide else raw.decode("cp1252", "replace")
    return "".join(SYMBOL_PUA.get(ord(c) - 0xF000, c) if 0xF000 <= ord(c) <= 0xF0FF else c
                   for c in s)


def parse(data):
    """-> dict(bounds, texts, lines).

    texts: [{text, x, y, size, dx}]  — x/y = Referenzpunkt in Device-Units,
           size = Fontgroesse in Device-Units, dx = Zeichenbreiten (falls da).
    lines: [[(x,y), ...]]            — Polygone/Polylinien/LineTo, Device-Units.
    Alles bereits durch die World-Transform gejagt.
    """
    bounds = struct.unpack_from("<4i", data, 8)
    xf = IDENTITY
    fonts = {}          # ihObject -> (height, facename)
    cur_font = (12.0, "")
    align = 0
    cur_pt = (0.0, 0.0)
    texts, lines = [], []
    # Word rendert Brueche (und alles Hoch-/Tiefgestellte) als SAVEDC ->
    # MODIFYWORLDTRANSFORM -> Text -> RESTOREDC. Ohne diesen Stack landen
    # Zaehler und Nenner auf demselben Punkt — das '1' und das '2' von '1/2'
    # faelt dann aus dem Satz heraus. Genau so ist "2 1/2 Stunden" im
    # Altbestand zu "2 Stunden" geworden.
    dc_stack = []

    for rtype, off, size in _records(data):
        if rtype == SAVEDC:
            dc_stack.append((xf, cur_font, align))

        elif rtype == RESTOREDC:
            n = struct.unpack_from("<i", data, off + 8)[0]
            # nSavedDC ist relativ (-1 = zuletzt gesichert).
            depth = -n if n < 0 else max(0, len(dc_stack) - n)
            for _ in range(max(1, depth)):
                if not dc_stack:
                    break
                xf, cur_font, align = dc_stack.pop()

        elif rtype == SETWORLDTRANSFORM:
            xf = struct.unpack_from("<6f", data, off + 8)

        elif rtype == MODIFYWORLDTRANSFORM:
            m = struct.unpack_from("<6f", data, off + 8)
            mode = struct.unpack_from("<I", data, off + 32)[0]
            if mode == MWT_IDENTITY:
                xf = IDENTITY
            elif mode == MWT_SET:
                xf = m
            elif mode == MWT_LEFTMULTIPLY:
                xf = _mul(m, xf)
            elif mode == MWT_RIGHTMULTIPLY:
                xf = _mul(xf, m)

        elif rtype == EXTCREATEFONTINDIRECTW:
            ih = struct.unpack_from("<I", data, off + 8)[0]
            h = struct.unpack_from("<i", data, off + 12)[0]
            face = data[off + 40:off + 40 + 64].decode("utf-16-le", "replace").split("\x00")[0]
            fonts[ih] = (abs(h) or 12.0, face)

        elif rtype == SELECTOBJECT:
            ih = struct.unpack_from("<I", data, off + 8)[0]
            if ih in fonts:
                cur_font = fonts[ih]

        elif rtype == DELETEOBJECT:
            fonts.pop(struct.unpack_from("<I", data, off + 8)[0], None)

        elif rtype == SETTEXTALIGN:
            align = struct.unpack_from("<I", data, off + 8)[0]

        elif rtype in (EXTTEXTOUTW, EXTTEXTOUTA):
            rx, ry = struct.unpack_from("<2i", data, off + 36)
            nchars, offstr = struct.unpack_from("<2I", data, off + 44)
            offdx = struct.unpack_from("<I", data, off + 72)[0]
            if not nchars or offstr == 0:
                continue
            wide = rtype == EXTTEXTOUTW
            nbytes = nchars * (2 if wide else 1)
            if off + offstr + nbytes > len(data):
                continue
            s = _decode(data[off + offstr:off + offstr + nbytes], wide)
            dx = []
            if offdx and off + offdx + 4 * nchars <= len(data):
                dx = list(struct.unpack_from(f"<{nchars}i", data, off + offdx))
            # TA_UPDATECP: der Anker ist NICHT der Referenzpunkt des Records
            # (der ist dann 0,0), sondern die aktuelle Position aus MOVETOEX.
            # Word setzt so Zaehler und Nenner eines Bruchs. Wer das Flag
            # ignoriert, legt beide auf denselben Punkt — und aus "2 1/2
            # Stunden" wird "2 Stunden".
            if align & TA_UPDATECP:
                x, y = cur_pt
            else:
                x, y = _apply(xf, rx, ry)
            # Fontgroesse skaliert mit dem vertikalen Anteil der Transform.
            sy = (xf[1] ** 2 + xf[3] ** 2) ** 0.5 or 1.0
            sx = (xf[0] ** 2 + xf[2] ** 2) ** 0.5 or 1.0
            texts.append({
                "text": s, "x": x, "y": y,
                "size": cur_font[0] * sy, "face": cur_font[1],
                "dx": [d * sx for d in dx],
                "align": align,
            })

        elif rtype in (POLYGON16, POLYLINE16):
            cpts = struct.unpack_from("<I", data, off + 24)[0]
            if off + 28 + 4 * cpts > len(data):
                continue
            pts = struct.unpack_from(f"<{2 * cpts}h", data, off + 28)
            lines.append([_apply(xf, pts[i], pts[i + 1]) for i in range(0, len(pts), 2)])

        elif rtype in (POLYGON, POLYLINE):
            cpts = struct.unpack_from("<I", data, off + 24)[0]
            if off + 28 + 8 * cpts > len(data):
                continue
            pts = struct.unpack_from(f"<{2 * cpts}i", data, off + 28)
            lines.append([_apply(xf, pts[i], pts[i + 1]) for i in range(0, len(pts), 2)])

        elif rtype == MOVETOEX:
            px, py = struct.unpack_from("<2i", data, off + 8)
            cur_pt = _apply(xf, px, py)

        elif rtype == LINETO:
            px, py = struct.unpack_from("<2i", data, off + 8)
            p = _apply(xf, px, py)
            lines.append([cur_pt, p])
            cur_pt = p

        elif rtype == RECTANGLE:
            l, t, r, b = struct.unpack_from("<4i", data, off + 8)
            c = [(l, t), (r, t), (r, b), (l, b), (l, t)]
            lines.append([_apply(xf, px, py) for px, py in c])

    return {"bounds": bounds, "texts": texts, "lines": lines}


def tokens(parsed):
    """Multimenge aller Zeichen im EMF — die Grundwahrheit fuer das Grounding.

    Stufe 2 (Sehen) darf die *Reihenfolge* bestimmen, aber keine Zeichen
    erfinden. Was die Vision liest, muss aus diesem Vorrat stammen.
    """
    return "".join(t["text"] for t in parsed["texts"])
