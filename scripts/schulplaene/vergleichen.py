#!/usr/bin/env python3
"""Vergleicht die Zuordnung (plaene/) mit einer unabhaengigen Zweitzuordnung.

    python3 scripts/schulplaene/vergleichen.py <ordner-zweitzuordnung> <slug> ...

Je Schule und Klasse werden die Vorhaben ueber den Titel gepaart (aehnlichster
Titel, sonst gleiche Position). Ausgabe als Markdown: Abweichungen beim
thema_key, Vorhaben nur in einer der beiden Fassungen, Trefferquote. Die erste
Zuordnung wird so verglichen, wie sie eingespielt wird (mit den Regeln aus
HARMONISIERUNG in bauen.py); die zweite bleibt unveraendert.
"""

import difflib
import json
import sys
from pathlib import Path

HIER = Path(__file__).resolve().parent
sys.path.insert(0, str(HIER))
from bauen import HARMONISIERUNG  # noqa: E402


def key_nach_regel(e: dict) -> str | None:
    for muster, klassen, key, _ in HARMONISIERUNG:
        if muster.search(e["uv_titel"]) and (klassen is None or e["klasse"] in klassen):
            return key
    return e.get("thema_key")


def paaren(a: list[dict], b: list[dict]) -> list[tuple[dict | None, dict | None]]:
    """Paart global nach Titelaehnlichkeit; gleiche Position gibt einen Bonus."""
    kandidaten = sorted(
        ((difflib.SequenceMatcher(None, x["uv_titel"].lower(), y["uv_titel"].lower()).ratio()
          + (0.3 if x["position"] == y["position"] else 0), i, j)
         for i, x in enumerate(a) for j, y in enumerate(b)),
        reverse=True,
    )
    frei_a, frei_b, paare = set(range(len(a))), set(range(len(b))), []
    for guete, i, j in kandidaten:
        if guete >= 0.45 and i in frei_a and j in frei_b:
            paare.append((a[i], b[j]))
            frei_a.discard(i)
            frei_b.discard(j)
    paare += [(a[i], None) for i in sorted(frei_a)] + [(None, b[j]) for j in sorted(frei_b)]
    return paare


def main() -> None:
    ordner = Path(sys.argv[1])
    gesamt = gleich = 0
    print("| Schule | Kl. | Vorhaben (erste / zweite Zuordnung) | thema_key erste | thema_key zweite |")
    print("|---|---|---|---|---|")
    for slug in sys.argv[2:]:
        erst = json.loads((HIER / "plaene" / f"{slug}.json").read_text())["eintraege"]
        zweit = json.loads((ordner / f"{slug}.json").read_text())["eintraege"]
        for klasse in range(5, 11):
            a = [e for e in erst if e["klasse"] == klasse]
            b = [e for e in zweit if e["klasse"] == klasse]
            for x, y in paaren(a, b):
                gesamt += 1
                kx = key_nach_regel(x) if x else "—"
                ky = y.get("thema_key") if y else "—"
                if kx == ky:
                    gleich += 1
                    continue
                titel = " / ".join(t["uv_titel"] if t else "(fehlt)" for t in (x, y))
                print(f"| {slug} | {klasse} | {titel} | {kx} | {ky} |")
    print(f"\nUebereinstimmung: {gleich} von {gesamt} Paaren ({100 * gleich / max(gesamt, 1):.0f} %)")


if __name__ == "__main__":
    main()
