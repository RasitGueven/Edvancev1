"""C02 - Zahlen fuer das RETRO."""
import collections
import json

items = json.load(open("data/vera8_komplett_enriched.json"))

print("STATUS:", dict(collections.Counter(i["status"] for i in items).most_common()))
print("GROUNDING:", dict(sorted(collections.Counter(i["grounding_quote"] for i in items).items())))
print("Stamm-Methode:", dict(collections.Counter(
    (i.get("_grounding", {}).get("aufgabe_text") or {}).get("methode") for i in items)))

partial = [i for i in items if i["status"] == "partial"]
print("partial: nur_stamm=%d  nur_antworten=%d"
      % (sum(1 for i in partial if i.get("aufgabe_text") and not i.get("akzeptierte_antworten")),
         sum(1 for i in partial if i.get("akzeptierte_antworten") and not i.get("aufgabe_text"))))
print("doc_pending mit belegten Antworten: %d"
      % sum(1 for i in items if i["status"] == "doc_pending" and i.get("akzeptierte_antworten")))

for status in ("quarantined", "interaktiv_extern", "keine_quelle"):
    print("%s: %s" % (status, [i["titel"] for i in items if i["status"] == status]))

problems = collections.Counter(p.split(":")[0] for i in items for p in i["_problems"])
print("\nHaeufigste _problems:")
for name, n in problems.most_common(14):
    print("  %3d  %s" % (n, name))

print("\ndoc_pending Items (fuer die Windows-Konvertierung):")
dp = sorted(i["titel"] for i in items if i["status"] == "doc_pending")
for i in range(0, len(dp), 4):
    print("  " + " · ".join(dp[i:i + 4]))
