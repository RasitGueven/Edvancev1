"""
Achsenzahlen des Koordinatensystems — ohne Ueberlappung (Pruefung App-Darstellung, 18.10.2026).

Mit Schrift 20 lagen „0“ und „-1“ am Ursprung uebereinander, und Randzahlen stiessen
an die Kurven. Jede Zahl bekommt einen geschaetzten Textkasten (svg_basis.text_kasten):
  - Stammplatz: x-Zahlen unter der Achse, y-Zahlen links der Achse (mit Abstand),
    die 0 einmal links unter dem Ursprung.
  - Stoesst eine Zahl dort an eine schon gesetzte Zahl oder an eine Kurve, steht sie
    auf der anderen Seite der Achse.
  - Geht beides nicht, entfaellt sie — das Gitter zeigt den Massstab weiter.
pruefe_koordinatensystem.pruefe_beschriftung_frei prueft das am fertigen SVG nach.
"""

from __future__ import annotations

from typing import Callable

from .svg_basis import beschriftung, kaesten_ueberlappen, linie, strecke_trifft_kasten, text_kasten
from .tokens import SCHRIFT, Palette


def achsenzahlen_svg(
    px: Callable[[float], float],
    py: Callable[[float], float],
    fenster: tuple[int, int, int, int],
    flaeche: tuple[float, float, float, float],
    achse_x: float,
    achse_y: float,
    null_sichtbar: bool,
    kurven_px: list[list[tuple[float, float]]],
    farben: Palette,
    skala: float,
    schriftgroesse: float,
    stark_achse: float,
    stark_betont: float,
    belegt: list[tuple[float, float, float, float]] | None = None,
    titel: tuple[str, str] = ('', ''),
) -> list[str]:
    """Teilstriche und Zahlen. `belegt`: Kaesten der schon gesetzten Texte (Titel, Punkte, Labels)."""
    x_min, x_max, y_min, y_max = fenster
    links, oben, rechts, unten = flaeche
    strich = 4 * skala
    abstand_y = strich + 8 * skala
    luft = 2 * skala
    # Zwischen zwei Texten mehr Luft: „-1“ und „0“ dicht nebeneinander lesen sich wie „-10“.
    luft_text = 0.4 * schriftgroesse
    halb_strich = stark_betont / 2 + luft
    belegt = list(belegt or [])
    teile: list[str] = []

    def trifft_kurve(k: tuple[float, float, float, float]) -> bool:
        # Nur innerhalb der Zeichenflaeche: ausserhalb schneidet der clipPath die Kurve weg.
        weit = (max(k[0] - halb_strich, links), max(k[1] - halb_strich, oben),
                min(k[2] + halb_strich, rechts), min(k[3] + halb_strich, unten))
        if weit[0] > weit[2] or weit[1] > weit[3]:
            return False
        return any(strecke_trifft_kasten(zug[i], zug[i + 1], weit)
                   for zug in kurven_px for i in range(len(zug) - 1))

    def setze(text: str, kandidaten: list[tuple[float, float, str]], pflicht: bool = False) -> None:
        # pflicht: ein Achsentitel entfaellt nie; passt keine Stelle, steht er an der ersten.
        for nr, (x, y, anker) in enumerate(kandidaten):
            k = text_kasten(x, y, text, schriftgroesse, anker)
            letzte = pflicht and nr == len(kandidaten) - 1
            if not letzte and (any(kaesten_ueberlappen(k, b, luft_text) for b in belegt) or trifft_kurve(k)):
                continue
            belegt.append(k)
            teile.append(beschriftung(
                x, y, text, farben.beschriftung, schriftgroesse, SCHRIFT, anker=anker, grundlinie='middle',
            ))
            return

    # Achsentitel zuerst: x ueber dem rechten Achsenende, y rechts neben der Spitze;
    # ausweichen nach unten bzw. links (etwa vor einem Steigungsdreieck).
    titel_x, titel_y = titel
    if titel_x:
        setze(titel_x, [(rechts - 2 * skala, achse_y - schriftgroesse, 'end'),
                        (rechts - 2 * skala, achse_y + strich + 2 * schriftgroesse, 'end'),
                        (rechts + schriftgroesse, achse_y - schriftgroesse, 'start'),
                        (rechts + schriftgroesse, achse_y + schriftgroesse, 'start')], pflicht=True)
    if titel_y:
        setze(titel_y, [(achse_x + schriftgroesse, oben + 2 * skala, 'start'),
                        (achse_x - schriftgroesse, oben + 2 * skala, 'end'),
                        (achse_x + schriftgroesse, oben - schriftgroesse, 'start'),
                        (achse_x - schriftgroesse, oben - schriftgroesse, 'end')], pflicht=True)
    if null_sichtbar:
        # Einmal, links unter dem Ursprung; geht dort eine Kurve durch, rechts darunter
        # oder links darueber.
        setze('0', [(achse_x - abstand_y, achse_y + strich + schriftgroesse, 'end'),
                    (achse_x + abstand_y, achse_y + strich + schriftgroesse, 'start'),
                    (achse_x - abstand_y, achse_y - strich - schriftgroesse, 'end')])
    for x in range(x_min, x_max + 1):
        if x == 0:
            continue
        teile.append(linie(px(x), achse_y - strich, px(x), achse_y + strich, farben.achse, stark_achse))
        setze(str(x), [(px(x), achse_y + strich + schriftgroesse, 'middle'),
                       (px(x), achse_y - strich - schriftgroesse, 'middle')])
    for y in range(y_min, y_max + 1):
        if y == 0:
            continue
        teile.append(linie(achse_x - strich, py(y), achse_x + strich, py(y), farben.achse, stark_achse))
        setze(str(y), [(achse_x - abstand_y, py(y), 'end'), (achse_x + abstand_y, py(y), 'start')])
    return teile
