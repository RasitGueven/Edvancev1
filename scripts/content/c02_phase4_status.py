"""C02 Phase 4 - Statusmodell, Matrix-Abdeckung, Review-CSV.

Bewusste Abweichung von der Spec: `enrich_full.py` wird NICHT erneut ausgefuehrt.
Es erzeugt den Pool aus `vera8_komplett.json` - also aus genau den fabrizierten
Feldern, die dieser Lauf ersetzt. Ein Re-Run wuerde den Rebuild ueberschreiben.
Stattdessen wird hier dieselbe Abbildungslogik (Leitidee -> Inhaltsfeld,
K1-K6 -> NRW-Prozesskompetenz) auf die *belegten* Felder angewendet.

Statusmodell:
  ready             Stamm + mindestens eine belegte Loesung, keine Blocker
  partial           genau eines von beidem
  quarantined       keines von beidem
  doc_pending       .doc-Quelle: Stamm steckt im Bild, antiword liefert keines
  interaktiv_extern GeoGebra-Applet
  keine_quelle      keine Quelldatei bekannt
"""
import csv
import json
import os
import re
import sys
from collections import Counter

sys.path.insert(0, os.path.dirname(__file__))
from vera_lib import files_of, load_items, save_items  # noqa: E402

CSV_OUT = "data/vera8_review_lena.csv"
REPORT = "data/c02_phase4_report.json"

LEITIDEE_ZU_INHALTSFELD = {
    "L1": "arithmetik_algebra", "L2": "geometrie", "L3": "geometrie",
    "L4": "funktionen", "L5": "stochastik",
}
K_ZU_NRW = {"K1": "arg", "K2": "pro", "K3": "mod", "K4": "kom", "K5": "ope", "K6": "kom"}
FELDER = ["arithmetik_algebra", "funktionen", "geometrie", "stochastik"]
KOMPS = ["ope", "mod", "pro", "arg", "kom", "wkz"]

INHALT_FELDER = ["aufgabe_text", "akzeptierte_antworten", "loesung_pro_ta",
                 "kodierung", "typische_fehler"]
# Probleme, die ein Item unbrauchbar machen, auch wenn Stamm und Loesung da sind.
BLOCKER = re.compile(r"fremdes_medium_in_quelle|prompt_fehlt|frage_loesung_inkonsistent"
                     r"|ta_anzahl_inkonsistent")


def leitidee_ids(raw):
    """L-Nummern aus 'Zahl (L1)' oder '1. Zahl'."""
    if not raw:
        return []
    ids = re.findall(r"\(L\s?(\d)\)", raw)
    if not ids:
        ids = re.findall(r"^\s*(\d)\.", raw, re.M)
    return ["L%s" % i for i in ids]


def matrix_von(item):
    felder, komps, afbs = set(), set(), []
    for ta in item.get("teilaufgaben") or []:
        for lid in leitidee_ids(ta.get("leitidee_raw")):
            if lid in LEITIDEE_ZU_INHALTSFELD:
                felder.add(LEITIDEE_ZU_INHALTSFELD[lid])
        for k in ta.get("k_tags") or []:
            if k in K_ZU_NRW:
                komps.add(K_ZU_NRW[k])
        if ta.get("afb"):
            afbs.append(ta["afb"])
    return sorted(felder), sorted(komps), (max(afbs) if afbs else None)


def task_type_von(item, n_ta):
    """Aufgabentyp aus dem belegten Inhalt, nicht aus einem geerbten Label."""
    teile = item.get("aufgabe_teile") or []
    problems = item.get("_problems") or []
    if n_ta > 1:
        return "MULTI_PART"
    if any(re.search(r"Kreuze\b", t, re.I) for t in teile):
        return "MULTIPLE_CHOICE"
    if any("erfordert_begruendung" in p or "freitext" in p for p in problems):
        return "FREE_TEXT"
    if item.get("akzeptierte_antworten"):
        return "SHORT_INPUT"
    return None


def grounding_quote(item):
    grounding = item.get("_grounding") or {}
    belegt = sum(1 for f in INHALT_FELDER if grounding.get(f))
    return belegt, len(INHALT_FELDER)


def status_von(item):
    # GeoGebra-Applets liegen als .ggb neben dem Ordnerschema; erkannt wird
    # deshalb an der Quell-URL, nicht am aufgeloesten Pfad.
    url = (item.get("iqb_urls") or {}).get("aufgabe") or ""
    if url.endswith(".ggb"):
        return "interaktiv_extern"
    pfad = files_of(item)["aufgabe"]
    if not pfad:
        return "keine_quelle"
    if pfad.endswith(".doc"):
        return "doc_pending"
    hat_stamm = bool(item.get("aufgabe_text"))
    hat_loesung = bool(item.get("akzeptierte_antworten"))
    if any(BLOCKER.search(p) for p in item.get("_problems") or []):
        return "quarantined"
    if hat_stamm and hat_loesung:
        return "ready"
    if hat_stamm or hat_loesung:
        return "partial"
    return "quarantined"


def drucke_matrix(items, label):
    zellen = Counter()
    for item in items:
        felder = item["edvance_matrix"]["inhaltsfelder"]
        komps = item["edvance_matrix"]["prozesskompetenzen"]
        for feld in felder:
            for komp in komps:
                zellen[(feld, komp)] += 1
    print("\nMatrix-Abdeckung — %s (%d Items):" % (label, len(items)))
    print("%-22s%s" % ("", "".join("%6s" % k for k in KOMPS)))
    for feld in FELDER:
        print("%-22s%s" % (feld, "".join("%6d" % zellen.get((feld, k), 0) for k in KOMPS)))


def main():
    items = load_items()
    grounding_map = {}
    for item in items:
        felder, komps, afb_max = matrix_von(item)
        n_ta = len(item.get("teilaufgaben") or [])
        item["edvance_matrix"] = {"inhaltsfelder": felder, "prozesskompetenzen": komps,
                                  "afb_max": afb_max, "schwierigkeit": None}
        item["task_type"] = task_type_von(item, n_ta)
        item["status"] = status_von(item)
        belegt, gesamt = grounding_quote(item)
        item["grounding_quote"] = "%d/%d" % (belegt, gesamt)
        item["_derivation"] = {
            "matrix": "auto (Leitidee->Inhaltsfeld, K1-K6->NRW) aus Didaktischer Kommentierung",
            "task_type": "auto (Teilaufgabenzahl, 'Kreuze', Begruendungspflicht)",
            "inhalt": "C02 grounded rebuild — jedes Inhaltsfeld mit _grounding belegt",
            "review_durch_lena_erforderlich": True,
        }
        grounding_map[item["titel"]] = belegt

    save_items(items)

    verteilung = Counter(i["status"] for i in items)
    ready = [i for i in items if i["status"] == "ready"]

    zeilen = []
    for item in sorted(items, key=lambda i: i["titel"]):
        bilder = item.get("bild_pfade") or []
        zeilen.append({
            "titel": item["titel"],
            "status": item["status"],
            "grounding_quote": item["grounding_quote"],
            "task_type": item["task_type"] or "?",
            "inhaltsfelder": "|".join(item["edvance_matrix"]["inhaltsfelder"]),
            "kompetenzen": "|".join(item["edvance_matrix"]["prozesskompetenzen"]),
            "afb_max": item["edvance_matrix"]["afb_max"] or "?",
            "stamm_quelle": (item.get("_grounding", {}).get("aufgabe_text") or {}).get("methode", "-"),
            "bild_pfad": bilder[0] if bilder else "",
            "n_antworten": len(item.get("akzeptierte_antworten") or []),
            "probleme": "; ".join(item.get("_problems") or []),
        })
    with open(CSV_OUT, "w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=list(zeilen[0].keys()))
        writer.writeheader()
        writer.writerows(zeilen)

    report = {"status": dict(verteilung),
              "grounding_quote": dict(Counter(i["grounding_quote"] for i in items)),
              "task_type_ready": dict(Counter(i["task_type"] for i in ready))}
    json.dump(report, open(REPORT, "w"), ensure_ascii=False, indent=1)

    print("Statusverteilung (%d Items):" % len(items))
    for status, n in verteilung.most_common():
        print("  %-18s %3d" % (status, n))
    print("\nGrounding-Quote (belegte Inhaltsfelder von 5):")
    for quote, n in sorted(Counter(i["grounding_quote"] for i in items).items()):
        print("  %-6s %3d" % (quote, n))
    drucke_matrix(items, "ALLE 299")
    drucke_matrix(ready, "nur READY")
    print("\nTask-Type (ready): %s" % dict(Counter(i["task_type"] for i in ready)))
    print("\n-> %s\n-> %s" % (CSV_OUT, REPORT))


if __name__ == "__main__":
    main()
