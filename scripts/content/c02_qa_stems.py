"""QA der Phase-1-Extraktion: Laengen, Ausreisser, Lizenz-Leckage."""
import json
import re

MANIFEST = json.load(open("data/vera8_assets_manifest.json"))
STEMS = json.load(open("data/c02_stems.json"))

full = {s: "\n".join(t["text"] for t in v["teile"]) for s, v in STEMS.items()}
mit = {s: t for s, t in full.items() if t.strip()}

lens = sorted(len(t) for t in mit.values())
print("Items mit EMF-Text: %d" % len(mit))
print("  Zeichen: min=%d  p25=%d  median=%d  p75=%d  max=%d"
      % (lens[0], lens[len(lens) // 4], lens[len(lens) // 2],
         lens[3 * len(lens) // 4], lens[-1]))

print("\n--- Lizenz-Leckage (CC/Copyright im Stamm) ---")
leak = [s for s, t in mit.items()
        if re.search(r"creativecommons|creative commons|\(cc by\)", t, re.I)]
print("  betroffen: %d %s" % (len(leak), leak[:5]))

print("\n--- Items ohne Lizenz-Medium (Verdacht: Lizenz nicht erkannt) ---")
no_lic = [s for s, v in MANIFEST.items()
          if not any(m["typ"] == "license" for m in v["medien"])]
for s in no_lic:
    print("  %s -> %s" % (s, [(m["typ"], m["quelle"].split("/")[-1]) for m in MANIFEST[s]["medien"]]))

print("\n--- 8 kuerzeste EMF-Staemme (Verdacht: unvollstaendig) ---")
for s, t in sorted(mit.items(), key=lambda kv: len(kv[1]))[:8]:
    print("  %-28s %3d  %r" % (s[:28], len(t), t[:70]))

print("\n--- Items ohne EMF-Text (Vision noetig) ---")
ohne = [s for s, t in full.items() if not t.strip()]
print("  %d Items" % len(ohne))
for s in ohne:
    typen = [m["typ"] for m in MANIFEST[s]["medien"]]
    print("  %-30s %s" % (s[:30], typen))
