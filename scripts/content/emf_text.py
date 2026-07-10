"""Extrahiert echten Text aus EMF-Vektorgrafiken (EMR_EXTTEXTOUTW/A).

Warum: Die IQB-Aufgabenstaemme liegen in den .docx als eingebettete EMF-Bilder.
EMF ist ein Vektorformat und speichert Text als Zeichen-Records - nicht als
Pixel. Der Aufgabentext ist damit *woertlich* rekonstruierbar, ohne OCR und
ohne Vision. Die Quelle ist die Datei selbst, nicht eine Interpretation.

Record-Layout EMR_EXTTEXTOUTW (MS-EMF 2.3.5.2):
    Type(4) Size(4) Bounds(16) iGraphicsMode(4) exScale(4) eyScale(4)
    EmrText: Reference(8) Chars(4) offString(4) Options(4) Rect(16) offDx(4)
offString ist relativ zum Record-Anfang.

Zeilenrekonstruktion: EMF speichert pro Textfragment nur eine Grundlinie (y) und
einen Startpunkt (x), keine Zeilenumbrueche. Fragmente werden daher nach y
geclustert und innerhalb einer Zeile nach x sortiert. Hochgestellte Zeichen
(Exponenten wie km^2) sitzen auf einer eigenen, hoeheren Grundlinie und werden
ueber x-Naehe wieder an ihre Basis gehaengt - in einem Mathe-Pool ist das
Korrektheit, nicht Kosmetik.
"""
import re
import struct

EMR_SETTEXTALIGN = 22
EMR_MOVETOEX = 27
EMR_SAVEDC = 33
EMR_RESTOREDC = 34
EMR_SETWORLDTRANSFORM = 35
EMR_MODIFYWORLDTRANSFORM = 36
EMR_EXTTEXTOUTA = 83
EMR_EXTTEXTOUTW = 84

MWT_IDENTITY, MWT_LEFTMULTIPLY, MWT_RIGHTMULTIPLY, MWT_SET = 1, 2, 3, 4
IDENTITY = (1.0, 0.0, 0.0, 1.0, 0.0, 0.0)  # m11 m12 m21 m22 dx dy

TA_UPDATECP = 0x0001
TA_RIGHT = 0x0002
TA_CENTER = 0x0006

# Word setzt mathematische Zeichen als Symbol-Font-Glyphen in die Private Use
# Area (0xF000 + Zeichencode). Ohne Ruecksetzung stuende im Aufgabentext ein
# Ersatzzeichen statt '=' oder '·'. Codes nach Adobe-Symbol-Encoding.
SYMBOL_PUA = {
    0x2B: "+", 0x2D: "−", 0x3D: "=", 0x3C: "<", 0x3E: ">",
    0xB1: "±", 0xB4: "×", 0xB7: "·", 0xBB: "≈", 0xD7: "⋅",
    0xB9: "≠", 0xA3: "≤", 0xB3: "≥", 0xB8: "÷", 0xD6: "√",
    0xA5: "∞", 0x70: "π", 0x61: "α", 0x62: "β", 0x67: "γ",
    0x64: "δ", 0x65: "ε", 0x6C: "λ", 0x6D: "μ", 0x73: "σ",
    0x77: "ω", 0x2F: "/", 0x28: "(", 0x29: ")",
}

# Boilerplate-Zeilen, die in praktisch jedem IQB-Dokument stehen.
BOILERPLATE = re.compile(
    r"^(copyright|iqb e\.?\s?v\.?|text und teilaufgaben|teilaufgabe\s*\d*\s*:?|"
    r"alle rechte vorbehalten|seite \d+|m\d{4,6}[_a-z]*)$",
    re.I,
)

# Ganze EMFs, die nur den CC-Lizenzblock rendern.
LICENSE_EMF = re.compile(r"creativecommons|creative commons|licenses/by|\(cc by\)", re.I)

WS = re.compile(r"[^\S\n]+")  # Whitespace ausser Newline (inkl. NBSP)

# Hoch-/Tiefstellung ist im EMF durch eine versetzte Grundlinie belegt. Sie als
# Unicode zu setzen gibt die Quelle wieder - 'km2' statt 'km²' waere ein Fehler.
SUP_MAP = str.maketrans("0123456789+-()n", "⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁽⁾ⁿ")
SUB_MAP = str.maketrans("0123456789+-()n", "₀₁₂₃₄₅₆₇₈₉₊₋₍₎ₙ")


def _records(data):
    """Iteriert (type, offset, size) ueber alle EMF-Records."""
    off, n = 0, len(data)
    while off + 8 <= n:
        rtype, size = struct.unpack_from("<II", data, off)
        if size < 8 or off + size > n:
            break
        yield rtype, off, size
        off += size


def _mat_mul(a, b):
    """Verkettung zweier XFORMs in Zeilenvektor-Konvention: p' = p * a * b."""
    a11, a12, a21, a22, adx, ady = a
    b11, b12, b21, b22, bdx, bdy = b
    return (a11 * b11 + a12 * b21, a11 * b12 + a12 * b22,
            a21 * b11 + a22 * b21, a21 * b12 + a22 * b22,
            adx * b11 + ady * b21 + bdx, adx * b12 + ady * b22 + bdy)


def _apply(xf, x, y):
    m11, m12, m21, m22, dx, dy = xf
    return x * m11 + y * m21 + dx, x * m12 + y * m22 + dy


def _world_transform(data, off, size, current):
    """Neuer Welt-Transform nach einem SET/MODIFY_WORLDTRANSFORM-Record.

    Gleichungen und gedrehte Beschriftungen platzieren ihre Glyphen ueber diese
    Matrix. Wer sie ignoriert, liest die Zeichen an falschen Koordinaten - und
    baut aus '4x + 6 = -46' die Zeichenfolge '+=-46x'.
    """
    try:
        xf = struct.unpack_from("<6f", data, off + 8)
    except struct.error:
        return current
    if off + 32 + 4 > off + size:
        return xf
    mode = struct.unpack_from("<I", data, off + 32)[0]
    if mode == MWT_IDENTITY:
        return IDENTITY
    if mode == MWT_LEFTMULTIPLY:
        return _mat_mul(xf, current)
    if mode == MWT_RIGHTMULTIPLY:
        return _mat_mul(current, xf)
    return xf  # MWT_SET


def _dx_array(data, off, size, off_dx, nchars, fallback=7.0):
    """Vorschubbreite je Zeichen.

    Ein einzelner Text-Record kann seine Zeichen ueber das Dx-Array beliebig
    verteilen - Formelobjekte tun das. Nur mit den Einzelbreiten laesst sich
    jedes Zeichen an seinen wahren Platz setzen; Records ueberlappen sonst.

    Word schreibt den Vorschub des *letzten* Zeichens als 0; er wird durch die
    mittlere Breite der uebrigen ersetzt.
    """
    dx = None
    if 8 <= off_dx < size and off + off_dx + 4 * nchars <= off + size:
        try:
            dx = list(struct.unpack_from("<%dI" % nchars, data, off + off_dx))
        except struct.error:
            dx = None
    if not dx or not any(dx):
        return [fallback] * nchars
    if dx[-1] == 0 and len(dx) > 1:
        dx[-1] = sum(dx[:-1]) / (len(dx) - 1)
    return dx


def _demap_symbol(text):
    """Symbol-Font-Glyphen aus der Private Use Area zurueckuebersetzen."""
    if not any(0xF000 <= ord(c) <= 0xF0FF for c in text):
        return text
    out = []
    for ch in text:
        code = ord(ch)
        if 0xF000 <= code <= 0xF0FF:
            low = code - 0xF000
            out.append(SYMBOL_PUA.get(low, chr(low) if 0x20 <= low < 0x7F else ch))
        else:
            out.append(ch)
    return "".join(out)


def _texts(data):
    """[(y, x, x_end, zeichen)] aller Zeichen, in Geraetekoordinaten.

    Ausgegeben wird pro *Zeichen*, nicht pro Record: Formelobjekte verteilen die
    Glyphen eines Records ueber die halbe Zeile und verschraenken sie mit denen
    anderer Records. Nur zeichenweise laesst sich '18 - 3x = 12' aus den Records
    '-=', '18312' und 'x' zurueckgewinnen.

    Nachgebildeter Geraetezustand: Welt-Transform, Textausrichtung und aktuelle
    Zeichenposition, jeweils ueber den SAVEDC/RESTOREDC-Stack.
    """
    out = []
    world, align, cp = IDENTITY, 0, (0, 0)
    stack = []
    for rtype, off, size in _records(data):
        if rtype == EMR_SAVEDC:
            stack.append((world, align, cp))
            continue
        if rtype == EMR_RESTOREDC:
            world, align, cp = stack.pop() if stack else (IDENTITY, 0, (0, 0))
            continue
        if rtype in (EMR_SETWORLDTRANSFORM, EMR_MODIFYWORLDTRANSFORM):
            world = _world_transform(data, off, size, world)
            continue
        if rtype == EMR_SETTEXTALIGN:
            align = struct.unpack_from("<I", data, off + 8)[0]
            continue
        if rtype == EMR_MOVETOEX:
            cp = struct.unpack_from("<ii", data, off + 8)
            continue
        if rtype not in (EMR_EXTTEXTOUTA, EMR_EXTTEXTOUTW):
            continue
        try:
            ref_x, ref_y = struct.unpack_from("<ii", data, off + 36)
            nchars, off_string = struct.unpack_from("<II", data, off + 44)
            off_dx = struct.unpack_from("<I", data, off + 72)[0]
        except struct.error:
            continue
        if nchars == 0 or off_string < 8 or off_string >= size:
            continue
        start = off + off_string
        width = 2 if rtype == EMR_EXTTEXTOUTW else 1
        if start + nchars * width > off + size:
            continue
        raw = data[start:start + nchars * width]
        text = raw.decode("utf-16-le", "replace") if width == 2 else raw.decode("cp1252", "replace")

        dx = _dx_array(data, off, size, off_dx, nchars)
        total = sum(dx)
        # TA_UPDATECP: der Bezugspunkt ist die aktuelle Position, nicht Reference.
        ox, oy = cp if align & TA_UPDATECP else (ref_x, ref_y)
        if align & TA_CENTER == TA_CENTER:
            ox -= total / 2
        elif align & TA_RIGHT:
            ox -= total
        if align & TA_UPDATECP:
            cp = (ox + total, oy)

        # Ein Record, der Platz fuer ein eingebettetes Objekt freihaelt, tut das
        # mit einer *Folge* von Leerzeichen. Ein einzelnes Leerzeichen ist immer
        # ein Worttrenner und darf nie verworfen werden.
        runs = [i for i, ch in enumerate(text) if ch.isspace()
                and ((i and text[i - 1].isspace()) or
                     (i + 1 < len(text) and text[i + 1].isspace()))]
        filler = set(runs)

        pos = 0.0
        for i, (ch, adv) in enumerate(zip(text, dx)):
            x0, y0 = _apply(world, ox + pos, oy)
            x1, _ = _apply(world, ox + pos + adv, oy)
            pos += adv
            out.append((round(y0), round(x0), round(x1), _demap_symbol(ch), i in filler))
    return out


def _weight(line):
    return sum(len(t.strip()) for _, _, t, _, _ in line["frags"])


def _cluster(chunks, y_tol):
    lines = []
    for y, x, x_end, text, filler in sorted(chunks, key=lambda c: (c[0], c[1])):
        frag = (x, x_end, text, "", filler)
        if lines and abs(lines[-1]["anchor"] - y) <= y_tol:
            lines[-1]["frags"].append(frag)
        else:
            lines.append({"anchor": y, "frags": [frag]})
    return lines


def _reattach_floats(lines, median_gap):
    """Haengt hoch-/tiefgestellte Kleinstfragmente an ihre Basiszeile.

    Ein 'Float' ist eine Zeile mit hoechstens 2 Zeichen Gesamttext - typisch der
    Exponent. Zugeordnet wird zur vertikal benachbarten Zeile mit der geringsten
    x-Distanz: der Exponent steht unmittelbar rechts neben seiner Basis. Ob er
    hoch- oder tiefgestellt ist, verraet die Richtung des Grundlinienversatzes
    (y waechst nach unten).
    """
    max_dy = max(3, int(0.6 * median_gap))
    alive = [True] * len(lines)
    for i, line in enumerate(lines):
        weight = _weight(line)
        if weight == 0 or weight > 2:  # 0 = reine Leerzeichen-Zeile
            continue
        cands = [j for j in (i - 1, i + 1)
                 if 0 <= j < len(lines) and alive[j]
                 and abs(lines[j]["anchor"] - line["anchor"]) <= max_dy]
        if not cands:
            continue

        def x_dist(j):
            return min(abs(fx - x) for x, _, _, _, _ in line["frags"]
                       for fx, _, _, _, _ in lines[j]["frags"])

        best = min(cands, key=x_dist)
        if x_dist(best) > 25:
            continue
        rel = "sup" if line["anchor"] < lines[best]["anchor"] else "sub"
        lines[best]["frags"].extend((x, xe, t, rel, f) for x, xe, t, _, f in line["frags"])
        alive[i] = False
    return [ln for ln, keep in zip(lines, alive) if keep]


def _merge_near(lines, median_gap):
    """Fuehrt Zeilen zusammen, deren Grundlinien nur durch unterschiedliche
    Schriftgroessen minimal versetzt sind."""
    tol = max(3, int(0.3 * median_gap))
    out = []
    for line in lines:
        if out and abs(out[-1]["anchor"] - line["anchor"]) <= tol:
            out[-1]["frags"].extend(line["frags"])
        else:
            out.append(line)
    return out


def _char_width(chunks):
    """Mittlere Zeichenbreite - Massstab fuer 'was ist eine echte Luecke'."""
    widths = [x_end - x for _, x, x_end, t, _ in chunks if t.strip() and x_end > x]
    return sorted(widths)[len(widths) // 2] if widths else 7.0


def _render(text, rel):
    if rel == "sup":
        return text.translate(SUP_MAP)
    if rel == "sub":
        return text.translate(SUB_MAP)
    return text


def _drop_overlapped_spaces(frags):
    """Entfernt Fuell-Leerzeichen, die unter anderen Zeichen liegen.

    Ein Fliesstext reserviert die Luecke fuer ein eingebettetes Formelobjekt
    durch eine Folge echter Leerzeichen; die Formel wird darueber gezeichnet.
    Ohne diesen Schritt verschraenken sich beide zu '1 8 - 3 x = 1 2'.

    Nur als Fuellung markierte Leerzeichen (Teil einer Folge) kommen in Frage,
    und nur bei echter Ueberdeckung: die Breite des letzten Zeichens eines
    Records ist geschaetzt, ein Worttrenner ragt dadurch regelmaessig ein paar
    Einheiten in das folgende Zeichen hinein.

    Hoch-/Tiefgestelltes zaehlt nicht als Ueberdeckung - es steht neben der
    Grundlinie und kam erst durch das Wiederanhaengen in diese Zeile. Sonst
    verschluckt das Exponentenzeichen den Wortabstand ('km² betrug').
    """
    solid = [(x, x_end) for x, x_end, t, rel, _ in frags if t.strip() and not rel]
    keep = []
    for frag in frags:
        x, x_end, text, _, filler = frag
        if text.strip() or not filler:
            keep.append(frag)
            continue
        width = max(x_end - x, 1)
        covered = sum(max(0, min(x_end, s_end) - max(x, s_x)) for s_x, s_end in solid)
        if covered <= 0.5 * width:
            keep.append(frag)
    return keep


def _compose(line, char_w):
    """Setzt eine Zeile aus ihren Einzelzeichen zusammen.

    Wortabstaende sind echte Leerzeichen im Quelltext und stehen als eigene
    Zeichen in der Liste - es wird daher fugenlos verkettet. Nur eine Luecke von
    mehreren Zeichenbreiten, die kein Leerzeichen ueberbrueckt, ist eine
    Tabellenspalte.

    Ausnahme: hinter einer Hoch-/Tiefstellung fehlt das Leerzeichen im Record -
    Word zieht es in das Feld hinein. Dort ist eine Luecke der einzige Hinweis
    auf eine Wortgrenze ('km² betrug').
    """
    frags = _drop_overlapped_spaces(sorted(line["frags"], key=lambda f: f[0]))
    parts, prev_end, prev_rel = [], None, ""
    for x, x_end, text, rel, _ in frags:
        if prev_end is not None:
            gap = x - prev_end
            if gap > 4 * char_w:
                parts.append(" | ")
            elif prev_rel and not rel and gap > 0.3 * char_w and text.strip():
                parts.append(" ")
        parts.append(_render(text, rel))
        prev_end = x_end if prev_end is None else max(prev_end, x_end)
        prev_rel = rel
    return WS.sub(" ", "".join(parts)).strip()


def _assemble(chunks):
    if not chunks:
        return ""
    ys = sorted({y for y, _, _, _, _ in chunks})
    gaps = [b - a for a, b in zip(ys, ys[1:])]
    median_gap = sorted(gaps)[len(gaps) // 2] if gaps else 10
    char_w = _char_width(chunks)

    lines = _cluster(chunks, y_tol=3)
    lines = _reattach_floats(lines, median_gap)
    lines = _merge_near(lines, median_gap)

    out = [_compose(ln, char_w) for ln in lines]
    return "\n".join(ln for ln in out if ln)


def emf_to_text(data, drop_boilerplate=True):
    """Woertlicher Text einer EMF. '' wenn sie keinen Text bzw. nur Lizenz enthaelt."""
    text = _assemble(_texts(data))
    if not drop_boilerplate:
        return text
    if LICENSE_EMF.search(text):
        return ""
    keep = [ln for ln in text.split("\n") if not BOILERPLATE.match(ln.strip())]
    return "\n".join(keep).strip()


def is_license_emf(data):
    return bool(LICENSE_EMF.search(_assemble(_texts(data))))


def is_pure_graphic(data):
    """True, wenn die EMF keinen einzigen Text-Record hat (echte Zeichnung)."""
    return not _texts(data)
