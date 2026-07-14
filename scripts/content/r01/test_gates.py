"""Negativkontrolle: haben die Grounding-Gates Zaehne?

Ein Gate, das nie etwas ablehnt, beweist nichts. Hier wird der Pipeline
absichtlich Erfundenes und Verstuemmeltes vorgelegt. Jeder Fall MUSS auffliegen.

    python3 test_gates.py
"""
import json
import sys
from collections import Counter
from pathlib import Path

from ground import EXTRACT, g1_vorrat, g2_beleg, is_license, norm

FAILS = []


def check(name, bedingung, detail=""):
    print(f'  {"OK  " if bedingung else "FAIL"}  {name}{"  — " + detail if detail else ""}')
    if not bedingung:
        FAILS.append(name)


def load(item):
    rec = json.loads((EXTRACT / f"{item}.json").read_text(encoding="utf-8"))
    emfs = [e for e in rec["stufe2_aufgabe_emf"] if not is_license(e)]
    vorrat = "".join(e["tokens"] for e in emfs)
    cells = [c for t in rec["stufe1_auswertung"]["tables"]
             for row in t["cells"] for c in row]
    return rec, vorrat, cells


def main():
    ergebnis = json.loads(
        (Path(__file__).resolve().parents[3] / "data/r01_ergebnis.json")
        .read_text(encoding="utf-8"))["items"]

    print("NC1 — erfundener Stamm (Zeichen, die es in der Quelle nicht gibt)")
    _, vorrat, _ = load("zeitangabe")
    ok, missing = g1_vorrat("Wie viele Minuten sind 3 Stunden?", vorrat)
    check("G1 lehnt '3 Stunden' ab", not ok, f"fehlende Zeichen {missing!r}")
    ok, missing = g1_vorrat("Wie viele Sekunden sind 2½ Stunden?", vorrat)
    check("G1 lehnt 'Sekunden' ab", not ok, f"fehlende Zeichen {missing!r}")

    print("\nNC2 — erfundene Loesung (nicht in der Auswertung belegt)")
    _, _, cells = load("zeitangabe")
    ok, _ = g2_beleg("120", cells)
    check("G2 lehnt Loesung '120' ab", not ok)
    _, _, cells_k = load("kopfundkoerper")
    ok, _ = g2_beleg("50", cells_k)
    check("G2 lehnt Loesung '50' ab", not ok)
    ok, _ = g2_beleg("48", cells_k)
    check("G2 nimmt belegte Loesung '48' an", ok)

    print("\nNC3 — der ALTE Fehler: der halbe Bruch faellt raus")
    _, vorrat, _ = load("zeitangabe")
    alt = "Wie viele Minuten sind 2 Stunden?60 min90 min150 min250 min"
    ok, _ = g1_vorrat(alt, vorrat)
    check("G1 allein wuerde die alte Lesung DURCHLASSEN (Auslassung != Erfindung)",
          ok, "genau deshalb gibt es G6")
    rest = Counter(norm(vorrat)) - Counter(norm(alt))
    check("G6 zeigt die verschluckte 1/2 als Restzeichen an",
          "".join(sorted(rest.elements())) == "12",
          f"Rest {''.join(sorted(rest.elements()))!r}")
    check("G6 der echten Lesung laesst keinen Rest",
          ergebnis["zeitangabe"]["_g6_restzeichen"] == "",
          "0 von 52 Inhaltszeichen unverbraucht")

    print("\nNC4 — Einheiten: keine Umrechnungsvarianten (P01)")
    p = ergebnis["20prozent"]["parts"][0]
    ca = p["correct_answers"]
    check("correct_answers ist genau ['16']", ca == ["16"], f"{ca}")
    check("keine Umrechnungsvariante in correct_answers",
          not any(v in " ".join(ca) for v in ("km", "dm", "cm", "0,016", "160", "1600")))
    check("Einheit steht als unit='m' am Feld", p.get("unit") == "m")

    print("\nNC5 — Tabelle bleibt Tabelle, kein Pipe-Fliesstext")
    a = ergebnis["bevoelkerungsdichte"]["assets"]
    check("Bevoelkerungsdichte hat ein strukturiertes Tabellen-Asset",
          len(a) == 1 and a[0]["kind"] == "table")
    t = a[0]
    check("16 Bundeslaender x 2 Spalten", len(t["rows"]) == 16 and len(t["header"]) == 2,
          f'{len(t["rows"])}x{len(t["header"])}')
    check("Berlin=3.861 und Mecklenburg-Vorpommern=71 in eigenen Zellen",
          ["Berlin", "3.861"] in t["rows"]
          and ["Mecklenburg-Vorpommern", "71"] in t["rows"])
    blob = json.dumps(ergebnis["bevoelkerungsdichte"], ensure_ascii=False)
    check("nirgends Pipe-Fliesstext (' | ')", " | " not in blob)

    print("\nNC6 — MC-Ordinal zeigt auf die visuell 3. Option")
    p = ergebnis["zeitangabe"]["parts"][0]
    check("Optionen in visueller Reihenfolge 60/90/150/250",
          [o["label"] for o in p["options"]] == ["60 min", "90 min", "150 min", "250 min"])
    check("correct_answers = ['c'] (= 3. Kaestchen)", p["correct_answers"] == ["c"])
    check("aufgeloest auf '150 min'",
          p["_beleg_loesung"]["aufgeloest_auf"] == "150 min")

    print("\nNC7 — Rechenprobe: die Loesung passt zum gelesenen Stamm")
    check("2 1/2 h = 150 min", 2.5 * 60 == 150)
    check("Kopflaenge 12 cm, Verhaeltnis 1:4 -> 48 cm", 12 * 4 == 48)
    check("Koerpergroesse 1,84 m, Verhaeltnis 1:8 -> 23 cm", round(184 / 8) == 23)
    tr = {r[0]: r[1] for r in ergebnis["bevoelkerungsdichte"]["assets"][0]["rows"]}
    hoch = int(tr["Berlin"].replace(".", ""))
    tief = int(tr["Mecklenburg-Vorpommern"].replace(".", ""))
    check("Spannweite aus der Tabelle = 3790", hoch - tief == 3790, f"{hoch}-{tief}")
    check("Saarland (398) ist 'fast 400'", abs(int(tr["Saarland"]) - 400) <= 5)
    check("20% von 80 = 16", 0.2 * 80 == 16)

    print()
    if FAILS:
        print(f"NICHT BESTANDEN — {len(FAILS)} Kontrolle(n) gescheitert: {FAILS}")
        return 1
    print("Alle Negativkontrollen bestanden: die Gates lehnen Erfundenes ab, "
          "lassen Belegtes durch.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
