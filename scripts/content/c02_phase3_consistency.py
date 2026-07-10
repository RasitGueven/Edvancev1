"""C02 Phase 3 - Konsistenz Frage <-> belegte Loesung.

Der schaerfste automatisch pruefbare Fall sind Ankreuzaufgaben: die in der
Auswertung belegte Loesung MUSS unter den Optionen stehen, die der
Aufgabenstamm anbietet. Stamm und Loesung stammen aus verschiedenen Dateien -
stimmen sie ueberein, stuetzen sie sich gegenseitig. Weichen sie ab, ist
mindestens eine der beiden Quellen falsch gelesen.

Kein Ersatz fuer die Stichprobe, aber eine Pruefung ueber alle Items.
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
import c02_auswertung  # noqa: E402
from vera_lib import files_of, load_items  # noqa: E402

OUT = "data/c02_konsistenz.json"
MC_MARKER = re.compile(r"Kreuze\b", re.I)


def norm(text):
    text = (text or "").strip().lower().replace(",", ".")
    text = re.sub(r"\s+", "", text)
    return text.rstrip(".")


def optionen(part):
    """Antwortoptionen einer Ankreuz-Teilaufgabe."""
    if not MC_MARKER.search(part):
        return []
    opts = []
    for line in part.split("\n"):
        if "☐" in line:
            opts += [o.strip() for o in line.split("☐") if o.strip()]
        elif " | " in line and not MC_MARKER.search(line):
            opts += [o.strip() for o in line.split("|") if o.strip()]
    return opts


def teil_fuer_ta(teile, n_ta, nr):
    """Der Stammteil zu Teilaufgabe `nr` (1-basiert).

    Ausgerichtet wird an der Zahl der Teilaufgaben in der *Quelle*, nicht an der
    Zahl der geloesten - sonst verschiebt sich die Zuordnung, sobald eine
    Teilaufgabe keine belegte Loesung hat.
    """
    if len(teile) == n_ta:
        return teile[nr - 1]
    if len(teile) == n_ta + 1:  # teile[0] ist der gemeinsame Stamm
        return teile[nr]
    return None


def main():
    items = load_items()
    geprueft = {"mc_ok": [], "mc_mismatch": [], "mc_ohne_optionen": [],
                "ta_anzahl_abweichung": []}

    for item in items:
        teile = item.get("aufgabe_teile") or []
        tas = item.get("loesung_pro_ta") or []
        if not teile or not tas:
            continue
        n_ta = len(c02_auswertung.parse(files_of(item)["auswertung"])) or len(tas)

        if len(teile) not in (n_ta, n_ta + 1):
            geprueft["ta_anzahl_abweichung"].append(
                "%s: %d Stammteile, %d Teilaufgaben in der Auswertung"
                % (item["titel"], len(teile), n_ta))

        for ta in tas:
            part = teil_fuer_ta(teile, n_ta, ta["nr"])
            if part is None or not MC_MARKER.search(part):
                continue
            opts = optionen(part)
            eintrag = "%s TA%s" % (item["titel"], ta["nr"])
            if not opts:
                geprueft["mc_ohne_optionen"].append(eintrag)
                continue
            normiert = {norm(o) for o in opts}
            treffer = [a for a in ta["akzeptierte_antworten"] if norm(a) in normiert]
            if treffer:
                geprueft["mc_ok"].append(eintrag)
            else:
                geprueft["mc_mismatch"].append(
                    "%s: Loesung %s nicht unter Optionen %s"
                    % (eintrag, ta["akzeptierte_antworten"], opts))

    json.dump(geprueft, open(OUT, "w"), ensure_ascii=False, indent=1)
    for key, rows in geprueft.items():
        print("  %-22s %3d" % (key, len(rows)))
    print("\nmc_mismatch:")
    for row in geprueft["mc_mismatch"][:15]:
        print("   %s" % row)
    print("\nmc_ohne_optionen (Stamm nennt 'Kreuze', aber keine Optionen lesbar):")
    for row in geprueft["mc_ohne_optionen"][:10]:
        print("   %s" % row)
    print("\n-> %s" % OUT)


if __name__ == "__main__":
    main()
