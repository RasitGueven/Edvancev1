"""C02 - maschinelle Abnahmepruefung.

Die zentrale Invariante: kein Inhaltsfeld ist befuellt, ohne dass `_grounding`
dafuer eine Quelle nennt. Wird sie verletzt, ist der Lauf wertlos.
"""
import json
import os

ITEMS = json.load(open("data/vera8_komplett_enriched.json"))

PAARE = [
    ("aufgabe_text", lambda i: i.get("aufgabe_text")),
    ("akzeptierte_antworten", lambda i: i.get("akzeptierte_antworten")),
    ("loesung_pro_ta", lambda i: i.get("loesung_pro_ta")),
    ("kodierung", lambda i: (i.get("diagnostik") or {}).get("kodierung")),
    ("typische_fehler", lambda i: (i.get("diagnostik") or {}).get("typische_fehler")),
]

ohne_beleg = []
for item in ITEMS:
    grounding = item.get("_grounding") or {}
    for feld, holen in PAARE:
        if holen(item) and not grounding.get(feld):
            ohne_beleg.append("%s / %s" % (item["titel"], feld))

adventskalender = next(i for i in ITEMS if i["titel"] == "Adventskalender")
ohne_status = [i["titel"] for i in ITEMS if not i.get("status")]

print("Items gesamt                       : %d" % len(ITEMS))
print("data/ref_item.json geloescht       : %s" % (not os.path.exists("data/ref_item.json")))
print("Assets-Manifest vorhanden          : %s" % os.path.exists("data/vera8_assets_manifest.json"))
print("Items ohne status                  : %d" % len(ohne_status))
print("Felder befuellt OHNE _grounding    : %d" % len(ohne_beleg))
for row in ohne_beleg[:10]:
    print("    %s" % row)

print("\nAdventskalender (Referenzfall der Fabrikation):")
print("  status                : %s" % adventskalender["status"])
print("  akzeptierte_antworten : %r" % adventskalender.get("akzeptierte_antworten"))
print("  loesung_pro_ta        : %r" % adventskalender.get("loesung_pro_ta"))
print("  _problems             : %s" % adventskalender["_problems"])

fabriziert = sum(1 for i in ITEMS if i.get("_fabriziert_backup"))
print("\nItems mit _fabriziert_backup (Audit-Spur): %d" % fabriziert)
