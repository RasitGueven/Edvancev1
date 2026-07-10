"""C02 - Zahlen fuer das RETRO."""
import collections
import json

items = json.load(open("data/vera8_komplett_enriched.json"))

mit_stamm = sum(1 for i in items if i.get("aufgabe_text"))
mit_loesung = sum(1 for i in items if i.get("akzeptierte_antworten"))
mit_fehler = sum(1 for i in items if (i.get("diagnostik") or {}).get("typische_fehler"))
mit_kod = sum(1 for i in items if (i.get("diagnostik") or {}).get("kodierung"))

print("Items gesamt              : %d" % len(items))
print("mit Aufgabenstamm         : %d" % mit_stamm)
print("mit belegter Loesung      : %d" % mit_loesung)
print("mit typischen Fehlern     : %d" % mit_fehler)
print("mit Kodierung             : %d" % mit_kod)
print("benoetigt_bild            : %d" % sum(1 for i in items if i.get("benoetigt_bild")))
print()
print("STATUS:", dict(collections.Counter(i["status"] for i in items).most_common()))
print("Stamm-Methode:", dict(collections.Counter(
    (i.get("_grounding", {}).get("aufgabe_text") or {}).get("methode") for i in items)))
print()
dp = [i for i in items if i["status"] == "doc_pending"]
print("doc_pending                        : %d" % len(dp))
print("doc_pending mit belegter Loesung   : %d" % sum(1 for i in dp if i.get("akzeptierte_antworten")))
print("=> Projektion ready nach .doc-Konv.: %d"
      % (sum(1 for i in items if i["status"] == "ready")
         + sum(1 for i in dp if i.get("akzeptierte_antworten"))))
print()
formel = sum(1 for i in items
             if "auswertung_loesung_nur_als_formelgrafik" in (i["_problems"] or []))
print("auswertung_loesung_nur_als_formelgrafik: %d" % formel)
print("keine_typischen_fehler_belegt          : %d"
      % sum(1 for i in items if "keine_typischen_fehler_belegt" in (i["_problems"] or [])))
