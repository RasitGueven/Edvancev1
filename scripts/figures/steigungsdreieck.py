"""
Optionales Steigungsdreieck im Koordinatensystem (E2b, Erklaersequenz „hoch durch rueber“).

Ab (x|y) eine Strecke dx waagerecht, dann dy senkrecht, in Gold (kurve_betont) wie ein
betonter Strich: Das Dreieck ist das, worauf es ankommt. Die Beschriftung steht aussen:
„rüber dx“ auf der dem senkrechten Schenkel abgewandten Seite der Waagerechten, „hoch dy“
neben der Senkrechten, weg von der Geraden. Ohne Dreieck ruft koordinatensystem() dieses
Modul nicht auf; die Ausgabe bleibt dann byteidentisch.
"""

from __future__ import annotations

from typing import Callable

from .pruefungen import dreieck_text
from .svg_basis import beschriftung, element, linie
from .tokens import SCHRIFT, Palette


def steigungsdreiecke_svg(
    dreiecke: list[dict],
    px: Callable[[float], float],
    py: Callable[[float], float],
    farben: Palette,
    skala: float,
    schriftgroesse: float,
) -> str:
    teile: list[str] = []
    strich = 2.5 * skala
    for d in dreiecke:
        x0, y0 = px(d['x']), py(d['y'])
        x1, y1 = px(d['x'] + d['dx']), py(d['y'] + d['dy'])
        teile.append(linie(x0, y0, x1, y0, farben.kurve_betont, strich))
        teile.append(linie(x1, y0, x1, y1, farben.kurve_betont, strich))
        teile.append(beschriftung(
            (x0 + x1) / 2, y0 + (schriftgroesse if d['dy'] > 0 else -schriftgroesse),
            f"rüber {dreieck_text(d['dx'])}", farben.kurve_betont, schriftgroesse, SCHRIFT,
            anker='middle', grundlinie='middle', fett=True,
        ))
        rechts = d['dx'] > 0
        teile.append(beschriftung(
            x1 + (6 * skala if rechts else -6 * skala), (y0 + y1) / 2,
            f"hoch {dreieck_text(d['dy'])}", farben.kurve_betont, schriftgroesse, SCHRIFT,
            anker='start' if rechts else 'end', grundlinie='middle', fett=True,
        ))
    return element('g', [], ''.join(teile))


def label_unten(dreiecke: list[dict], punkt: dict) -> bool:
    """Endet der senkrechte Schenkel eines Dreiecks von oben in diesem Punkt (dy < 0)?"""
    return any(d['dy'] < 0 and d['x'] + d['dx'] == punkt['x'] and d['y'] + d['dy'] == punkt['y']
               for d in dreiecke)
