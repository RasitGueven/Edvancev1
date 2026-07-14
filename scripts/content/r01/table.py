"""Tabellen aus EMF-Geometrie rekonstruieren — als Tabelle, nicht als Fliesstext.

Die alte Pipeline hat aus der Bevoelkerungsdichte-Tabelle Pipe-Text gemacht
("Baden-Wuerttemberg | 301 Bayern | 177"). Damit ist die Zuordnung Zelle->Spalte
verloren: aus einer Tabelle wird ein Satz, und ein Satz laesst sich nicht mehr
zuverlaessig zuruecklesen.

Hier passiert das Gegenteil. Word zeichnet jede Tabellenzelle als eigenes
Rechteck. Wir sammeln die Rechtecke, gruppieren die zusammenhaengenden zu einem
Raster und legen jedes Textfragment in genau die Zelle, in der sein Ankerpunkt
liegt. Deterministisch, ohne Modell, ohne Raten.
"""

import layout

TOL = 2.0  # Device-Units: Toleranz, ab wann zwei Kanten dieselbe sind


def _rects(lines):
    """Achsenparallele Rechtecke aus geschlossenen Polygonen."""
    out = []
    for ln in lines:
        pts = ln[:-1] if len(ln) > 1 and _same(ln[0], ln[-1]) else ln
        if len(pts) != 4:
            continue
        xs = sorted({round(p[0], 1) for p in pts})
        ys = sorted({round(p[1], 1) for p in pts})
        if len(xs) != 2 or len(ys) != 2:
            continue  # nicht achsenparallel -> keine Zelle
        if xs[1] - xs[0] < 3 or ys[1] - ys[0] < 3:
            continue
        out.append((xs[0], ys[0], xs[1], ys[1]))
    return sorted(set(out))


def _same(a, b):
    return abs(a[0] - b[0]) <= TOL and abs(a[1] - b[1]) <= TOL


def _touch(a, b):
    """Zwei Zellen gehoeren zum selben Raster, wenn sie sich beruehren."""
    return (a[0] - TOL <= b[2] and b[0] - TOL <= a[2]
            and a[1] - TOL <= b[3] and b[1] - TOL <= a[3])


def _largest_group(rects):
    """Groesste zusammenhaengende Menge von Zellen = die Tabelle."""
    parent = list(range(len(rects)))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    for i in range(len(rects)):
        for j in range(i + 1, len(rects)):
            if _touch(rects[i], rects[j]):
                parent[find(i)] = find(j)
    groups = {}
    for i in range(len(rects)):
        groups.setdefault(find(i), []).append(rects[i])
    return max(groups.values(), key=len) if groups else []


def _edges(vals):
    out = []
    for v in sorted(vals):
        if not out or v - out[-1] > TOL:
            out.append(v)
    return out


def extract(parsed, min_rows=3, min_cols=2):
    """-> {'header': [...], 'rows': [[...]]} oder None, wenn kein Raster da ist.

    Kein Raster = keine Tabelle. Dann wird auch keine behauptet.
    """
    cells = _largest_group(_rects(parsed["lines"]))
    if len(cells) < min_rows * min_cols:
        return None

    xs = _edges([c[0] for c in cells] + [c[2] for c in cells])
    ys = _edges([c[1] for c in cells] + [c[3] for c in cells])
    ncol, nrow = len(xs) - 1, len(ys) - 1
    if nrow < min_rows or ncol < min_cols:
        return None

    def slot(v, edges):
        return next((i for i in range(len(edges) - 1)
                     if edges[i] - TOL <= v < edges[i + 1] - TOL), None)

    grid = [[[] for _ in range(ncol)] for _ in range(nrow)]
    hit = 0
    x0, y0, x1, y1 = xs[0], ys[0], xs[-1], ys[-1]
    for t in parsed["texts"]:
        if not t["text"].strip():
            continue
        # Ankerpunkt ist die Grundlinie; der Zellinhalt sitzt knapp darueber.
        cy = t["y"] - t["size"] * 0.35
        if not (x0 - TOL <= t["x"] <= x1 and y0 - TOL <= cy <= y1):
            continue  # Text ausserhalb des Rasters (Ueberschrift, Quellenzeile)
        r, c = slot(cy, ys), slot(t["x"], xs)
        if r is None or c is None:
            continue
        grid[r][c].append(t)
        hit += 1
    if not hit:
        return None

    out = [[layout.text(cell).replace("\n", " ") for cell in row] for row in grid]
    out = [row for row in out if any(c for c in row)]
    if len(out) < min_rows:
        return None
    return {"header": out[0], "rows": out[1:]}
