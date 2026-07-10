"""C02 Phase 3b - Ankreuzaufgaben: Ordinalangabe + Optionsliste -> Antwort.

Die Auswertung nennt bei Ankreuzaufgaben keinen Wert, sondern eine Position:
'3. Kästchen wurde angekreuzt'. Erst zusammen mit der Optionsliste des
Aufgabenstamms ergibt das eine Antwort. Beide Angaben stehen woertlich in je
einer Quelldatei; die Verknuepfung ist mechanisch, nicht interpretierend.
Deshalb traegt das Ergebnis zwei `_grounding`-Belege.

Verweigert wird die Verknuepfung, wenn die Optionsliste nicht eindeutig
zerlegbar ist (Kaestchen sind Grafik, die Optionen kleben aneinander), wenn
mehrere Kreuze zu setzen sind oder wenn die Position raeumlich beschrieben ist
('oben links') und die lineare Reihenfolge nicht traegt.
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
import c02_auswertung  # noqa: E402
from vera_lib import files_of, load_items, save_items  # noqa: E402

REPORT = "data/c02_mc_join_report.json"

KREUZE = re.compile(r"Kreuze\b", re.I)
# Befunde aus Phase 2, die sich auf die *Positionsangabe* der Zelle bezogen und
# hinfaellig sind, sobald die echte Antwort aus der Optionsliste feststeht.
UEBERHOLT = ("antwort_ist_satz", "auswertung_ohne_konkrete_loesung")
ORDINAL = re.compile(r"(\d+)\s*(?:\.|tes|te|ter)?\s*K[äa]stchen", re.I)
NAMED = re.compile(r"^[„\"']?(.+?)[“\"']?\s+(?:ist|wird)\s+angekreuzt\.?$", re.I)
MULTI = re.compile(r"(alle|beide|bereits|\d+\s+der\s+\d+)\b[^.]*kreuz", re.I)
POSITIONAL = re.compile(r"\([^)]*(links|rechts|oben|unten|zeile|reihe|mitte)[^)]*\)", re.I)


def optionen(part):
    """Optionsliste in Anzeigereihenfolge. [] wenn nicht eindeutig zerlegbar.

    Gesucht wird nur *hinter* der 'Kreuze ...'-Zeile: davor stehen oft
    Abbildungsbeschriftungen, die genauso mit '|' getrennt sind ('K1 | K2')
    und die Reihenfolge der Optionen verfaelschen wuerden.
    """
    lines = part.split("\n")
    start = next((i for i, ln in enumerate(lines) if KREUZE.search(ln)), None)
    scan = lines[start + 1:] if start is not None else lines
    for line in scan:
        if "☐" in line:
            opts = [o.strip() for o in line.split("☐") if o.strip()]
            if len(opts) >= 2:
                return opts
    for line in scan:
        if "|" in line:
            opts = [o.strip() for o in line.split("|") if o.strip()]
            if len(opts) >= 2:
                return opts
    bullets = [ln.strip() for ln in scan if ln.strip().startswith("…")]
    return bullets if len(bullets) >= 2 else []


def teil_fuer(teile, n_ta, nr):
    if len(teile) == n_ta:
        return teile[nr - 1]
    if len(teile) == n_ta + 1:
        return teile[nr]
    return None


def main():
    items = load_items()
    report = {"ordinal_join": [], "named": [], "mehrfachauswahl": [],
              "position_uneindeutig": [], "optionen_nicht_zerlegbar": [],
              "ordinal_ausserhalb": []}

    for item in items:
        teile = item.get("aufgabe_teile") or []
        if not teile:
            continue
        auswertung = files_of(item)["auswertung"]
        tas = c02_auswertung.parse(auswertung)
        if not tas:
            continue

        neue_loesungen = {ta["nr"]: ta for ta in (item.get("loesung_pro_ta") or [])}
        problems = set(item.get("_problems") or [])
        geaendert = False

        for ta in tas:
            zelle = ta["kodierung"]
            if not re.search(r"angekreuzt|kreuze\s+sind|kästchen", zelle, re.I):
                continue
            kennung = "%s TA%s" % (item["titel"], ta["nr"])

            if MULTI.search(zelle):
                problems.add("ta%s_mc_mehrfachauswahl" % ta["nr"])
                report["mehrfachauswahl"].append(kennung)
                neue_loesungen.pop(ta["nr"], None)
                geaendert = True
                continue
            if POSITIONAL.search(zelle):
                problems.add("ta%s_mc_position_uneindeutig" % ta["nr"])
                report["position_uneindeutig"].append(kennung)
                neue_loesungen.pop(ta["nr"], None)
                geaendert = True
                continue

            # Ordinal zuerst: '1. Kästchen ist angekreuzt' ist eine Position,
            # keine benannte Antwort - sonst landet '1. Kästchen' im Pool.
            ordinal = ORDINAL.search(zelle)
            if not ordinal:
                benannt = NAMED.match(ta["loesung"].strip())
                if not benannt:
                    continue
                antwort = benannt.group(1).strip(" „“\"'")
                neue_loesungen[ta["nr"]] = {
                    "nr": ta["nr"], "loesung": antwort,
                    "akzeptierte_antworten": [antwort], "kodierung": zelle,
                    "_grounding": [{"quelle": ta["_grounding"]["quelle"],
                                    "zitat": ta["loesung"][:120],
                                    "methode": "woertlich"}],
                }
                report["named"].append("%s -> %r" % (kennung, antwort))
                geaendert = True
                continue
            part = teil_fuer(teile, len(tas), ta["nr"])
            opts = optionen(part) if part else []
            if not opts:
                problems.add("ta%s_mc_optionen_nicht_zerlegbar" % ta["nr"])
                report["optionen_nicht_zerlegbar"].append(kennung)
                neue_loesungen.pop(ta["nr"], None)
                geaendert = True
                continue
            index = int(ordinal.group(1))
            if not 1 <= index <= len(opts):
                problems.add("ta%s_mc_ordinal_ausserhalb" % ta["nr"])
                report["ordinal_ausserhalb"].append(
                    "%s: Kästchen %d, aber %d Optionen" % (kennung, index, len(opts)))
                neue_loesungen.pop(ta["nr"], None)
                geaendert = True
                continue

            antwort = opts[index - 1]
            problems -= {"ta%s_%s" % (ta["nr"], p) for p in UEBERHOLT}
            neue_loesungen[ta["nr"]] = {
                "nr": ta["nr"], "loesung": antwort,
                "akzeptierte_antworten": [antwort], "kodierung": zelle,
                "_grounding": [
                    {"quelle": ta["_grounding"]["quelle"],
                     "zitat": ordinal.group(0), "methode": "ordinal_position"},
                    {"quelle": os.path.basename(files_of(item)["aufgabe"]),
                     "zitat": " ☐ ".join(opts)[:160], "methode": "optionsliste"},
                ],
            }
            report["ordinal_join"].append("%s: Kästchen %d von %s -> %r"
                                          % (kennung, index, opts, antwort))
            geaendert = True

        if geaendert:
            loesungen = sorted(neue_loesungen.values(), key=lambda t: t["nr"])
            antworten = [a for t in loesungen for a in t["akzeptierte_antworten"]]
            if antworten:
                item["loesung_pro_ta"] = loesungen
                item["akzeptierte_antworten"] = antworten
                belege = [b for t in loesungen for b in t.get("_grounding", [])]
                if belege:
                    grounding = item.setdefault("_grounding", {})
                    grounding["akzeptierte_antworten"] = belege
                    grounding["loesung_pro_ta"] = belege
            else:
                item.pop("akzeptierte_antworten", None)
                item.pop("loesung_pro_ta", None)
                (item.get("_grounding") or {}).pop("akzeptierte_antworten", None)
                (item.get("_grounding") or {}).pop("loesung_pro_ta", None)
            item["_problems"] = sorted(problems)

    save_items(items)
    json.dump(report, open(REPORT, "w"), ensure_ascii=False, indent=1)
    for key, rows in report.items():
        print("  %-26s %3d" % (key, len(rows)))
    print("\nBeispiele ordinal_join:")
    for row in report["ordinal_join"][:8]:
        print("   %s" % row)
    print("\nVerweigert (Optionen nicht zerlegbar):")
    for row in report["optionen_nicht_zerlegbar"][:8]:
        print("   %s" % row)
    print("\n-> %s" % REPORT)


if __name__ == "__main__":
    main()
