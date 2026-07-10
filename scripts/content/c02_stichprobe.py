"""C02 - Stichprobe: Item-Feld gegen Quellstelle, zum Nachlesen im RETRO.

Druckt fuer ausgewaehlte Items nebeneinander, was im Pool steht und woher es
kommt. Fuer .docx-Staemme zusaetzlich den EMF-Rohtext, fuer Rastergrafiken den
Bildpfad, damit Bild und Transkription verglichen werden koennen.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from vera_lib import files_of, load_items  # noqa: E402

STICHPROBE = ["20 Prozent", "Bevölkerungsdichte", "Anzahl von Nullen",
              "Rollrasen", "Adventskalender", "Freibad"]


def kurz(text, n=150):
    text = (text or "").replace("\n", " ⏎ ")
    return text[:n] + ("…" if len(text) > n else "")


items = {i["titel"]: i for i in load_items()}
for titel in sys.argv[1:] or STICHPROBE:
    item = items[titel]
    grounding = item.get("_grounding") or {}
    print("\n" + "=" * 78)
    print("%s   [status=%s  grounding=%s]" % (titel, item["status"], item["grounding_quote"]))
    print("=" * 78)
    print("Quelldateien: %s" % {k: os.path.basename(v) if v else None
                                for k, v in files_of(item).items()})

    print("\n  aufgabe_text : %s" % kurz(item.get("aufgabe_text"), 220))
    beleg = grounding.get("aufgabe_text")
    if beleg:
        print("    <- %s (%s)" % (beleg["quelle"], beleg["methode"]))
        if beleg.get("bilder"):
            print("    Bilder: %s" % ", ".join(beleg["bilder"]))

    print("\n  akzeptierte_antworten: %s" % (item.get("akzeptierte_antworten") or "— leer —"))
    for beleg in grounding.get("akzeptierte_antworten") or []:
        print("    <- %s [%s] %r" % (beleg["quelle"], beleg.get("methode", "zellentext"),
                                     kurz(beleg["zitat"], 110)))

    for ta in item.get("loesung_pro_ta") or []:
        print("\n  TA%s loesung=%r" % (ta["nr"], kurz(ta["loesung"], 70)))

    fehler = (item.get("diagnostik") or {}).get("typische_fehler") or []
    if fehler:
        beleg = grounding.get("typische_fehler") or {}
        print("\n  typische_fehler (%d, Quelle %s):" % (len(fehler), beleg.get("quelle")))
        for zeile in fehler[:2]:
            print("    • %s" % kurz(zeile, 130))

    if item.get("_problems"):
        print("\n  _problems: %s" % item["_problems"])
    if item.get("bild_pfade"):
        print("  bild_pfade: %s" % item["bild_pfade"][:3])
