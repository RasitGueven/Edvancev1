#!/usr/bin/env python3
"""
Geometriepruefungen fuer den Koordinatensystem-Generator — IMPORTIERBAR.

WARUM ES DIESE DATEI GIBT: Die Verhaeltnispruefungen (m=1 unter 45 Grad,
Determinismus, Parabel-Zerlegung, Label-Quadrant) standen als Anweisungen im
KOERPER von test_koordinatensystem.py — nicht aufrufbar, und ein Import haette den
ganzen Testlauf mitgestartet. upload_figures.py (A19) braucht aber ein
`pruefe(svg, params)`, um ein Bild VOR dem Upload zu pruefen. Also stehen die
Pruefungen hier als Funktionen, die SVG-TEXT entgegennehmen und Befunde
zurueckgeben. Der Testlauf ruft sie nur noch auf.

WAS HIER NEU IST — ABSOLUTE RUECKRECHNUNG statt Verhaeltnis:
Eine Verhaeltnispruefung (dx == dy bei m=1) besteht auch ein Bild, dessen
Ursprung eine halbe Einheit daneben sitzt: alles ist gleichmaessig verschoben,
die Verhaeltnisse stimmen, das Bild ist trotzdem falsch. Deshalb rechnet jede
Pruefung hier den PIXELORT aus dem SVG zurueck (viewBox + clipPath-Rechteck
liefern Rand und Einheit) und vergleicht ihn mit dem Sollwert aus den
Parametern:
  s) beide Achsen haben DIESELBE Pixel-pro-Einheit (absolut, nicht als Verhaeltnis)
  a) das Achsenkreuz liegt am rechnerisch richtigen Pixelort
  b) je Gerade fuehrt der Pfad durch die Pixelpunkte zu (0, b) und (1, m + b)
  c) je Parabel durch Scheitel und zwei weitere Stellen
  d) je Punkt liegt der Kreis am Pixelort der Koordinate
  e) die Gitterlinien sitzen auf ganzzahligen Werten

Die Einheit wird NIE aus den Eingabeparametern uebernommen — immer aus dem SVG
zurueckgerechnet (Plot-Breite / Anzahl Einheiten). Nur so schlaegt ein
systematischer Versatz an, der die Masse unveraendert laesst.
"""

from __future__ import annotations

import math
import re

# Toleranzen in Pixel. Koordinaten stehen auf zwei Nachkommastellen (svg_basis
# STELLEN=2) — ein echter Versatz ist immer groesser.
EPS_EXAKT = 0.5      # Achsen, Gitter, Punkt-Mittelpunkt: gezeichnet == round(soll, 2)
EPS_GERADE = 0.8     # Lotabstand eines Stuetzpunkts zur gezeichneten Geraden
EPS_PARABEL = 1.0    # Abstand einer Stelle zum gezeichneten (dichten) Bogen
EPS_SKALA = 0.1      # Differenz der beiden Achs-Einheiten


# ── SVG einlesen ─────────────────────────────────────────────────────────────

def _floats(text: str) -> list[float]:
    return [float(t) for t in re.findall(r'-?\d+(?:\.\d+)?', text)]


def _kopf(svg: str) -> tuple[float, float]:
    m = re.search(r'<svg\b[^>]*\bwidth="([\d.-]+)"[^>]*\bheight="([\d.-]+)"', svg)
    if not m:
        raise ValueError('SVG ohne width/height im Kopf.')
    return float(m.group(1)), float(m.group(2))


def _clip(svg: str) -> tuple[float, float, float, float]:
    """Rand und Plotflaeche aus dem clipPath-Rechteck — die ID darf praefixiert sein."""
    m = re.search(
        r'<clipPath id="[^"]*edvance-plot"><rect x="([\d.-]+)" y="([\d.-]+)" '
        r'width="([\d.-]+)" height="([\d.-]+)"',
        svg,
    )
    if not m:
        raise ValueError('clipPath-Rechteck nicht gefunden — Plotflaeche unbestimmbar.')
    return float(m.group(1)), float(m.group(2)), float(m.group(3)), float(m.group(4))


def _linien(svg: str) -> list[tuple[float, float, float, float]]:
    aus = []
    for m in re.finditer(
        r'<line x1="([\d.-]+)" y1="([\d.-]+)" x2="([\d.-]+)" y2="([\d.-]+)"', svg
    ):
        aus.append(tuple(float(g) for g in m.groups()))
    return aus


def _polylinien(svg: str) -> list[list[tuple[float, float]]]:
    aus = []
    for m in re.finditer(r'<polyline points="([^"]+)"', svg):
        zahlen = _floats(m.group(1))
        aus.append([(zahlen[i], zahlen[i + 1]) for i in range(0, len(zahlen) - 1, 2)])
    return aus


def _kreise(svg: str) -> list[tuple[float, float, float]]:
    aus = []
    for m in re.finditer(r'<circle cx="([\d.-]+)" cy="([\d.-]+)" r="([\d.-]+)"', svg):
        aus.append(tuple(float(g) for g in m.groups()))
    return aus


# ── Abstands-Geometrie ───────────────────────────────────────────────────────

def _lot(p, a, b) -> float:
    """Lotabstand des Punkts p zur GERADEN durch a und b (unendlich verlaengert)."""
    (px, py), (ax, ay), (bx, by) = p, a, b
    dx, dy = bx - ax, by - ay
    laenge = math.hypot(dx, dy)
    if laenge == 0:
        return math.hypot(px - ax, py - ay)
    return abs(dx * (ay - py) - dy * (ax - px)) / laenge


def _strecke(p, a, b) -> float:
    """Abstand des Punkts p zur STRECKE a-b (Projektion auf [0,1] geklemmt)."""
    (px, py), (ax, ay), (bx, by) = p, a, b
    dx, dy = bx - ax, by - ay
    quadrat = dx * dx + dy * dy
    if quadrat == 0:
        return math.hypot(px - ax, py - ay)
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / quadrat))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


def _dist_zu_zug(p, zug: list[tuple[float, float]]) -> float:
    if len(zug) == 1:
        return math.hypot(p[0] - zug[0][0], p[1] - zug[0][1])
    return min(_strecke(p, zug[i], zug[i + 1]) for i in range(len(zug) - 1))


# ── Rueckgerechnete Abbildung ────────────────────────────────────────────────

class Abbild:
    """
    Die Pixel-Abbildung, ausschliesslich AUS DEM SVG zurueckgerechnet.

    Aus dem clipPath-Rechteck kommen Rand (links, oben) und Plotmasse; die
    Einheit ist Plotmasse / Anzahl Einheiten. Die Anzahl Einheiten ist die
    einzige Zahl aus den Parametern — die Pixelorte selbst werden NICHT
    uebernommen, sondern hier neu gerechnet und gegen das SVG gehalten.
    """

    def __init__(self, svg: str, x_min: int, x_max: int, y_min: int, y_max: int):
        self.breite, self.hoehe = _kopf(svg)
        self.links, self.oben, self.wp, self.hp = _clip(svg)
        self.rechts, self.unten = self.links + self.wp, self.oben + self.hp
        self.x_min, self.x_max, self.y_min, self.y_max = x_min, x_max, y_min, y_max
        self.eh_x = self.wp / (x_max - x_min)
        self.eh_y = self.hp / (y_max - y_min)

    def px(self, x: float) -> float:
        return self.links + (x - self.x_min) * self.eh_x

    def py(self, y: float) -> float:
        return self.oben + (self.y_max - y) * self.eh_y


# ── Einzelpruefungen: SVG-Text rein, Befunde raus ────────────────────────────

def pruefe_skalierung(svg: str, params: dict) -> list[str]:
    """s) Beide Achsen tragen dieselbe Pixel-pro-Einheit — absolut gerechnet."""
    ab = Abbild(svg, params['x_min'], params['x_max'], params['y_min'], params['y_max'])
    if abs(ab.eh_x - ab.eh_y) > EPS_SKALA:
        return [f's) ungleiche Achsenskalierung: x={ab.eh_x:.3f} px/Einheit, '
                f'y={ab.eh_y:.3f} px/Einheit.']
    return []


def pruefe_achsenkreuz(svg: str, params: dict) -> list[str]:
    """a) Waagerechte und senkrechte Achse am rechnerisch richtigen Pixelort."""
    ab = Abbild(svg, params['x_min'], params['x_max'], params['y_min'], params['y_max'])
    soll_y = min(max(ab.py(0), ab.oben), ab.unten)   # Lage der x-Achse
    soll_x = min(max(ab.px(0), ab.links), ab.rechts)  # Lage der y-Achse
    linien = _linien(svg)
    befunde = []

    hat_x = any(
        abs(y1 - y2) < EPS_EXAKT and abs(y1 - soll_y) < EPS_EXAKT
        and abs(min(x1, x2) - ab.links) < EPS_EXAKT and abs(max(x1, x2) - ab.rechts) < EPS_EXAKT
        for x1, y1, x2, y2 in linien
    )
    if not hat_x:
        befunde.append(f'a) keine waagerechte Achse bei y={soll_y:.2f} (Breite {ab.links:.0f}..{ab.rechts:.0f}).')

    hat_y = any(
        abs(x1 - x2) < EPS_EXAKT and abs(x1 - soll_x) < EPS_EXAKT
        and abs(min(y1, y2) - ab.oben) < EPS_EXAKT and abs(max(y1, y2) - ab.unten) < EPS_EXAKT
        for x1, y1, x2, y2 in linien
    )
    if not hat_y:
        befunde.append(f'a) keine senkrechte Achse bei x={soll_x:.2f} (Hoehe {ab.oben:.0f}..{ab.unten:.0f}).')
    return befunde


def pruefe_geraden(svg: str, params: dict) -> list[str]:
    """b) Je Gerade: der Pfad fuehrt durch die Pixelpunkte zu (0, b) und (1, m + b)."""
    ab = Abbild(svg, params['x_min'], params['x_max'], params['y_min'], params['y_max'])
    zuege = _polylinien(svg)
    befunde = []
    for i, f in enumerate(params.get('funktionen') or []):
        if f.get('typ') != 'linear':
            continue
        m, b = f['m'], f['b']
        p0 = (ab.px(0), ab.py(b))          # (0, b)
        p1 = (ab.px(1), ab.py(m + b))      # (1, m + b)
        kandidaten = [z for z in zuege if len(z) >= 2]
        if not kandidaten:
            befunde.append(f'b) funktionen[{i}] (m={m}, b={b}): keine gezeichnete Kurve gefunden.')
            continue
        # Der Streckenzug, der p0 am naechsten liegt, IST diese Gerade — und muss
        # dann auch p1 tragen. Beides misst Steigung UND Achsenabschnitt absolut.
        bester = min(kandidaten, key=lambda z: _lot(p0, z[0], z[-1]))
        d0, d1 = _lot(p0, bester[0], bester[-1]), _lot(p1, bester[0], bester[-1])
        if max(d0, d1) > EPS_GERADE:
            befunde.append(
                f'b) funktionen[{i}] (m={m}, b={b}): Pfad fuehrt nicht durch (0,b)/(1,m+b) '
                f'(Lot {d0:.2f}/{d1:.2f} px).'
            )
    return befunde


def _parabel_stellen(f: dict, x_min: int, x_max: int, y_min: int, y_max: int) -> list[float]:
    a, b = f['a'], f['b']
    scheitel = -b / (2 * a)
    spanne = x_max - x_min
    roh = [scheitel, x_min + spanne * 0.25, x_min + spanne * 0.75, x_min + 1, x_max - 1]
    drin: list[float] = []
    for x in roh:
        if not (x_min <= x <= x_max):
            continue
        y = a * x * x + b * x + f['c']
        if not (y_min <= y <= y_max):
            continue
        if all(abs(x - vorhanden) > 1e-9 for vorhanden in drin):
            drin.append(x)
        if len(drin) == 3:
            break
    return drin


def pruefe_parabeln(svg: str, params: dict) -> list[str]:
    """c) Je Parabel: Scheitel (wenn im Fenster) und zwei weitere Stellen liegen auf dem Bogen."""
    ab = Abbild(svg, params['x_min'], params['x_max'], params['y_min'], params['y_max'])
    zuege = [z for z in _polylinien(svg) if len(z) >= 2]
    befunde = []
    for i, f in enumerate(params.get('funktionen') or []):
        if f.get('typ') != 'quadratisch':
            continue
        stellen = _parabel_stellen(f, ab.x_min, ab.x_max, ab.y_min, ab.y_max)
        if not stellen:
            continue  # kein Bogen im Fenster — nichts zu vergleichen
        if not zuege:
            befunde.append(f'c) funktionen[{i}]: keine gezeichnete Kurve gefunden.')
            continue
        for x in stellen:
            y = f['a'] * x * x + f['b'] * x + f['c']
            q = (ab.px(x), ab.py(y))
            d = min(_dist_zu_zug(q, z) for z in zuege)
            if d > EPS_PARABEL:
                befunde.append(
                    f'c) funktionen[{i}]: Stelle x={x:.2f} liegt {d:.2f} px neben dem Bogen.'
                )
    return befunde


def pruefe_punkte(svg: str, params: dict) -> list[str]:
    """d) Je Punkt: ein Kreis am Pixelort der Koordinate — auch innerhalb der viewBox."""
    ab = Abbild(svg, params['x_min'], params['x_max'], params['y_min'], params['y_max'])
    kreise = _kreise(svg)
    befunde = []
    for i, p in enumerate(params.get('punkte') or []):
        soll = (ab.px(p['x']), ab.py(p['y']))
        naechster = min(
            (math.hypot(cx - soll[0], cy - soll[1]) for cx, cy, _ in kreise),
            default=math.inf,
        )
        if naechster > EPS_EXAKT:
            befunde.append(
                f'd) punkte[{i}] ({p["x"]}|{p["y"]}): kein Kreis am Pixelort '
                f'({soll[0]:.2f}, {soll[1]:.2f}); naechster {naechster:.2f} px entfernt.'
            )
    return befunde


def pruefe_gitter(svg: str, params: dict) -> list[str]:
    """e) Gitterlinien sitzen auf ganzzahligen Werten — nirgends dazwischen."""
    if not params.get('gitter', True):
        return []  # ohne Gitter gibt es keine zu pruefenden Linien
    ab = Abbild(svg, params['x_min'], params['x_max'], params['y_min'], params['y_max'])
    linien = _linien(svg)

    def eindeutig(werte: list[float]) -> list[float]:
        werte = sorted(werte)
        aus: list[float] = []
        for w in werte:
            if not aus or abs(w - aus[-1]) > EPS_EXAKT:
                aus.append(w)
        return aus

    # Volle-Hoehe-Senkrechte (Gitter + y-Achse) bzw. Volle-Breite-Waagerechte.
    ist_x = eindeutig([
        x1 for x1, y1, x2, y2 in linien
        if abs(x1 - x2) < EPS_EXAKT
        and abs(min(y1, y2) - ab.oben) < EPS_EXAKT and abs(max(y1, y2) - ab.unten) < EPS_EXAKT
    ])
    ist_y = eindeutig([
        y1 for x1, y1, x2, y2 in linien
        if abs(y1 - y2) < EPS_EXAKT
        and abs(min(x1, x2) - ab.links) < EPS_EXAKT and abs(max(x1, x2) - ab.rechts) < EPS_EXAKT
    ])
    soll_x = eindeutig([ab.px(x) for x in range(ab.x_min, ab.x_max + 1)])
    soll_y = eindeutig([ab.py(y) for y in range(ab.y_min, ab.y_max + 1)])

    befunde = []
    if not _mengen_gleich(ist_x, soll_x):
        befunde.append(f'e) senkrechte Gitterlinien nicht auf ganzzahligen Werten '
                       f'(ist {len(ist_x)}, soll {len(soll_x)}).')
    if not _mengen_gleich(ist_y, soll_y):
        befunde.append(f'e) waagerechte Gitterlinien nicht auf ganzzahligen Werten '
                       f'(ist {len(ist_y)}, soll {len(soll_y)}).')
    return befunde


def _mengen_gleich(a: list[float], b: list[float]) -> bool:
    if len(a) != len(b):
        return False
    return all(abs(x - y) < EPS_EXAKT for x, y in zip(a, b))


# ── Sammelpruefung + Adapter fuer den Upload ─────────────────────────────────

_ALLE = (
    pruefe_skalierung,
    pruefe_achsenkreuz,
    pruefe_geraden,
    pruefe_parabeln,
    pruefe_punkte,
    pruefe_gitter,
)


def pruefe_geometrie(svg: str, params: dict) -> list[str]:
    """Alle Geometriepruefungen. Leere Liste heisst: nichts gefunden."""
    befunde: list[str] = []
    for pruefung in _ALLE:
        befunde.extend(pruefung(svg, params))
    return befunde


def pruefe(svg: str, params: dict) -> tuple[bool, str]:
    """
    Die Schnittstelle fuer upload_figures.py: (bestanden, meldung).

    bestanden == True nur, wenn KEIN Befund vorliegt — dann darf hochgeladen
    werden. Sonst traegt die Meldung alle Befunde, und der Aufrufer laedt nichts.
    """
    befunde = pruefe_geometrie(svg, params)
    if befunde:
        return False, ' | '.join(befunde)
    return True, 'ok'


# ── Negativkontrolle ─────────────────────────────────────────────────────────
#
# erwarte_fehler() im Testlauf prueft schlechte EINGABEN — das ist
# Eingabevalidierung. Die Negativkontrolle beweist etwas anderes: dass die
# Geometriepruefungen bei schlechter AUSGABE anschlagen. Sie nimmt ein KORREKTES
# SVG, verletzt es an genau einer Stelle und stellt sicher, dass ein Befund
# faellt. Ein Selbsttest, der nie anschlaegt, beweist nichts.

def _erste_kreis_cx(svg: str, plus: float) -> str:
    return re.sub(
        r'(<circle cx=")([\d.-]+)(")',
        lambda m: f'{m.group(1)}{float(m.group(2)) + plus:g}{m.group(3)}',
        svg, count=1,
    )


def _hoehe_stauchen(svg: str, faktor: float) -> str:
    """viewBox, height UND clipPath-Hoehe zugleich strecken — erzwingt eh_x != eh_y."""
    def kopf(m):
        neu = float(m.group(2)) * faktor
        return f'{m.group(1)}{neu:g}{m.group(3)}'
    svg = re.sub(r'(<svg\b[^>]*\bheight=")([\d.-]+)(")', kopf, svg, count=1)
    svg = re.sub(r'(viewBox="0 0 [\d.-]+ )([\d.-]+)(")',
                 lambda m: f'{m.group(1)}{float(m.group(2)) * faktor:g}{m.group(3)}', svg, count=1)
    svg = re.sub(r'(<rect x="[\d.-]+" y="[\d.-]+" width="[\d.-]+" height=")([\d.-]+)(")',
                 lambda m: f'{m.group(1)}{float(m.group(2)) * faktor:g}{m.group(3)}', svg, count=1)
    return svg


def _erste_gerade_verbiegen(svg: str, dy: float) -> str:
    """Letzten Punkt der ersten Polylinie verschieben — falsche Steigung."""
    def einmal(m):
        paare = m.group(1).split()
        x, y = paare[-1].split(',')
        paare[-1] = f'{x},{float(y) + dy:g}'
        return f'<polyline points="{" ".join(paare)}"'
    return re.sub(r'<polyline points="([^"]+)"', einmal, svg, count=1)


def negativkontrolle() -> list[tuple[str, bool, list[str]]]:
    """
    Vier Verletzungen an korrekten SVGs. Rueckgabe je Fall:
    (Name, hat_angeschlagen, Befunde). hat_angeschlagen == False ist ein Versagen
    der Pruefung selbst.
    """
    from figures.koordinatensystem import koordinatensystem

    mit_punkt = dict(x_min=-3, x_max=3, y_min=-3, y_max=3,
                     punkte=[{'x': 1, 'y': 2, 'label': 'P'}])
    mit_gerade = dict(x_min=-4, x_max=4, y_min=-4, y_max=4,
                      funktionen=[{'typ': 'linear', 'm': 1, 'b': 0, 'label': 'f'}])

    faelle = [
        ('1 px Versatz (Punkt verschoben)',
         _erste_kreis_cx(koordinatensystem(**mit_punkt), 1.0), mit_punkt),
        ('ungleiche Achsenskalierung erzwungen',
         _hoehe_stauchen(koordinatensystem(**mit_punkt), 1.25), mit_punkt),
        ('Gerade mit falschem m',
         _erste_gerade_verbiegen(koordinatensystem(**mit_gerade), 60.0), mit_gerade),
        ('Punkt ausserhalb der viewBox',
         _erste_kreis_cx(koordinatensystem(**mit_punkt), 9000.0), mit_punkt),
    ]

    ergebnis = []
    for name, svg, params in faelle:
        befunde = pruefe_geometrie(svg, params)
        ergebnis.append((name, bool(befunde), befunde))
    return ergebnis


def _main() -> int:
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

    print('Negativkontrolle — jede Zeile ist ein absichtlich kaputtes SVG.')
    print('Die Pruefung MUSS bei jeder anschlagen; Stille waere das Versagen.\n')
    alle_gut = True
    for name, angeschlagen, befunde in negativkontrolle():
        marke = 'ANGESCHLAGEN' if angeschlagen else 'STILL GEBLIEBEN (!!)'
        print(f'[{marke}] {name}')
        for b in befunde:
            print(f'    -> {b}')
        if not angeschlagen:
            alle_gut = False
        print()

    if not alle_gut:
        print('FEHLER: mindestens eine Verletzung blieb unentdeckt.')
        return 1
    print('Alle vier Verletzungen wurden erkannt.')
    return 0


if __name__ == '__main__':
    raise SystemExit(_main())
