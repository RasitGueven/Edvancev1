"""Textfragmente zu Zeilen fuegen — anhand ihrer Lage, nicht ihrer Reihenfolge.

Ein EMF speichert Text als viele kleine Fragmente ohne Zeilenumbrueche. Wer sie
in Record-Reihenfolge aneinanderhaengt, bekommt Buchstabensalat; wer sie stumpf
mit Leerzeichen verbindet, bekommt "Baden - Wuerttemberg" und "3 . 861".

Deshalb wird hier gerechnet statt geraten:
- Zeilen entstehen durch Clustern der Grundlinien (y).
- Innerhalb der Zeile zaehlt x, nicht die Record-Reihenfolge.
- Ein Leerzeichen kommt nur dort hin, wo im EMF auch eine Luecke ist — die
  Breite eines Fragments steht in seinen Vorschueben (dx).
- Hochgestelltes (km^2) sitzt auf einer hoeheren Grundlinie in kleinerer Schrift
  und wird als Unicode-Hochzahl angehaengt. 'km2' waere hier ein Fehler.
"""
SUP = str.maketrans("0123456789+-()n", "⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁽⁾ⁿ")


def _width(t):
    # Word schreibt fuer Ein-Zeichen-Runs oft den Vorschub 0 ('-', '.'). Ein
    # blindes sum(dx) macht daraus die Breite 0 und damit eine Scheinluecke —
    # so entsteht "Baden - Wuerttemberg" und "3 . 861". Die Schaetzung aus der
    # Schriftgroesse ist die Untergrenze.
    est = 0.5 * t["size"] * len(t["text"])
    if len(t["dx"]) == len(t["text"]):
        return max(sum(t["dx"]), est)
    return est


def lines(texts):
    """-> [[frag, ...], ...] nach Grundlinie geclustert, je Zeile nach x sortiert."""
    ts = [t for t in texts if t["text"].strip()]
    if not ts:
        return []
    med = sorted(t["size"] for t in ts)[len(ts) // 2] or 10.0
    out = []
    for t in sorted(ts, key=lambda t: (t["y"], t["x"])):
        # Hochgestelltes darf die Zeile nicht sprengen -> grosszuegige Toleranz.
        row = next((r for r in out if abs(r[0]["y"] - t["y"]) <= 0.6 * med), None)
        if row is None:
            out.append([t])
        else:
            row.append(t)
    for r in out:
        r.sort(key=lambda t: t["x"])
    out.sort(key=lambda r: min(t["y"] for t in r))
    return out


def join_line(row, med=None):
    """Eine Zeile Fragmente -> ein String."""
    if not row:
        return ""
    med = med or (sorted(t["size"] for t in row)[len(row) // 2] or 10.0)
    base = max(t["y"] for t in row)  # Grundlinie der normalen Schrift
    s, prev_end = "", None
    for t in row:
        txt = t["text"]
        sup = t["size"] < 0.75 * med and t["y"] < base - 0.15 * med
        if sup:
            txt = txt.strip().translate(SUP)
        if prev_end is not None:
            gap = t["x"] - prev_end
            # Die Fragmente tragen ihre Leerzeichen meist selbst ('sind ').
            # Ein zusaetzliches Leerzeichen darf nur dort entstehen, wo im Bild
            # wirklich eine Luecke von Zeichenbreite klafft — sonst zerschneidet
            # jede Run-Grenze ein Wort.
            if not sup and gap > 0.9 * t["size"]:
                s += " "
        s += txt
        prev_end = t["x"] + _width(t)
    return " ".join(s.split()) if "  " in s else s.strip()


def text(texts):
    """Fragmente -> mehrzeiliger Text in Lesereihenfolge."""
    ls = lines(texts)
    if not ls:
        return ""
    allt = [t for r in ls for t in r]
    med = sorted(t["size"] for t in allt)[len(allt) // 2] or 10.0
    return "\n".join(join_line(r, med) for r in ls).strip()
