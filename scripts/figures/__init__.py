"""
Parametrische Abbildungs-Generatoren fuer Aufgaben und Reports.

Jeder Generator gibt ein vollstaendiges SVG als String zurueck und schreibt
selbst keine Dateien — Ausgabe entscheidet der Aufrufer. Zwei Zusagen gelten
fuer alle Generatoren dieses Pakets:

  DETERMINISMUS  Gleiche Parameter ergeben ein byteidentisches SVG. Keine
                 Zeitstempel, keine Zufalls-IDs, keine Iteration ueber
                 ungeordnete Mengen.
  TRANSPARENZ    Kein Generator malt einen Hintergrund. Die Abbildung liegt auf
                 ihrem Traeger (dunkle Buehne oder weisses Papier), sie bringt
                 keinen mit.

Die Farben stammen aus `tokens.py` und sind aus `src/styles/tokens.css`
gemessen; `python3 scripts/figures/tokens.py` prueft sie gegen die Datei.
"""

from .koordinatensystem import EINHEIT_STANDARD, koordinatensystem

__all__ = ['koordinatensystem', 'EINHEIT_STANDARD']
