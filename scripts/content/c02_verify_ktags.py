"""Befund fuer RETRO-C02: Stammen die K-Tags/AFB der Items aus den Dokumenten?

Vergleicht das gespeicherte `teilaufgaben`-Feld (afb, kompetenzstufe) mit den
Merkmale-Tabellen der Didaktischen Kommentierung.

WICHTIG: Gegen den *aktuellen* Pool ist der Test tautologisch - Phase 2
schreibt afb und kompetenzstufe direkt aus der Kommentierung. Aussagekraeftig
ist nur der Vergleich mit dem Stand VOR dem Rebuild:

    git show e3f3304:data/vera8_komplett_enriched.json > /tmp/vorher.json
    python3 scripts/content/c02_verify_ktags.py /tmp/vorher.json
"""
import json
import os
import re
import sys
from collections import Counter

sys.path.insert(0, os.path.dirname(__file__))
import c02_kommentierung  # noqa: E402
from vera_lib import files_of, load_items  # noqa: E402

ROMAN2ARAB = {"i": "1", "ii": "2", "iii": "3", "iv": "4", "v": "5"}


def norm_stufe(value):
    """'III' und '3', '1B' und '1b' bezeichnen dieselbe Kompetenzstufe."""
    text = (value or "").strip().lower()
    match = re.fullmatch(r"([ivx]+)([a-z]?)", text)
    if match and match.group(1) in ROMAN2ARAB:
        return ROMAN2ARAB[match.group(1)] + match.group(2)
    return text

stats = Counter()
beispiele = {"afb_mismatch": [], "stufe_mismatch": [], "anzahl_mismatch": []}

quelle = sys.argv[1] if len(sys.argv) > 1 else None
items = json.load(open(quelle)) if quelle else load_items()
print("Vergleich gegen: %s\n" % (quelle or "aktueller Pool (tautologisch!)"))

for item in items:
    path = files_of(item)["kommentierung"]
    quelle = c02_kommentierung.parse(path)["teilaufgaben"]
    eigen = item.get("teilaufgaben") or []
    if not quelle:
        stats["ohne_kommentierung"] += 1
        continue
    stats["mit_kommentierung"] += 1

    if len(quelle) != len(eigen):
        stats["anzahl_mismatch"] += 1
        if len(beispiele["anzahl_mismatch"]) < 6:
            beispiele["anzahl_mismatch"].append(
                "%s: Item %d TA, Quelle %d TA" % (item["titel"][:30], len(eigen), len(quelle)))
        continue

    for src, own in zip(quelle, eigen):
        stats["ta_gesamt"] += 1
        if src.get("afb") is not None and own.get("afb") is not None:
            if src["afb"] == own["afb"]:
                stats["afb_gleich"] += 1
            else:
                stats["afb_mismatch"] += 1
                if len(beispiele["afb_mismatch"]) < 6:
                    beispiele["afb_mismatch"].append(
                        "%s TA%s: Item afb=%s, Quelle afb_raw=%r"
                        % (item["titel"][:26], src["nr"], own["afb"], src.get("afb_raw")))
        else:
            stats["afb_unbekannt"] += 1

        src_stufe = norm_stufe(src.get("kompetenzstufe_raw"))
        own_stufe = norm_stufe(str(own.get("kompetenzstufe") or ""))
        if src_stufe and own_stufe:
            if src_stufe == own_stufe:
                stats["stufe_gleich"] += 1
            else:
                stats["stufe_mismatch"] += 1
                if len(beispiele["stufe_mismatch"]) < 6:
                    beispiele["stufe_mismatch"].append(
                        "%s TA%s: Item=%r Quelle=%r"
                        % (item["titel"][:26], src["nr"], own_stufe, src_stufe))

print("K-Tag / AFB Echtheitspruefung")
for key in ("mit_kommentierung", "ohne_kommentierung", "anzahl_mismatch",
            "ta_gesamt", "afb_gleich", "afb_mismatch", "afb_unbekannt",
            "stufe_gleich", "stufe_mismatch"):
    print("  %-20s %4d" % (key, stats[key]))

if stats["afb_gleich"] + stats["afb_mismatch"]:
    quote = stats["afb_gleich"] / (stats["afb_gleich"] + stats["afb_mismatch"])
    print("\n  AFB-Uebereinstimmung   : %.1f%%" % (100 * quote))
if stats["stufe_gleich"] + stats["stufe_mismatch"]:
    quote = stats["stufe_gleich"] / (stats["stufe_gleich"] + stats["stufe_mismatch"])
    print("  Stufen-Uebereinstimmung: %.1f%%" % (100 * quote))

for key, rows in beispiele.items():
    if rows:
        print("\n  %s:" % key)
        for row in rows:
            print("    %s" % row)
