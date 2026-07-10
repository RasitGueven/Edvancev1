"""Kontrollgruppe: Erkennt stem_chars() bei den 216 FERTIGEN Items echten Text?

Wenn ja, ist das Verdikt 'stem_nur_bild' fuer die 81 belastbar und kein Artefakt
einer zu aggressiven Regex.
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from vera_nachlauf import convert, slug_of, stem_chars  # noqa: E402

doc = json.load(open("data/vera8_komplett.json"))
ready = [a for a in doc["aufgaben"] if a.get("aufgabe_text_clean")]

stems, checked, skipped = [], 0, 0
for item in ready:
    url = item["urls"].get("aufgabe")
    if not url or url.endswith(".ggb"):
        skipped += 1
        continue
    path = os.path.join("data/vera8_docs", slug_of(item), os.path.basename(url))
    if not os.path.exists(path):
        skipped += 1
        continue
    raw = convert(path)
    if raw is None:
        skipped += 1
        continue
    stems.append((stem_chars(raw, item["iqb_titel"]), item["iqb_titel"]))
    checked += 1

stems.sort()
print(f"Kontrollgruppe (fertige Items) geprueft: {checked}  (uebersprungen: {skipped})")
if not stems:
    sys.exit("keine Daten")

vals = [s for s, _ in stems]
print(f"  stem_chars  min={vals[0]}  median={vals[len(vals)//2]}  max={vals[-1]}")
below = sum(1 for v in vals if v < 30)
print(f"  unter Schwelle 30 (= faelschlich als 'nur Bild' geflaggt): {below} / {checked}"
      f"  ({below / checked:.0%})")
print("\n  5 niedrigste fertige Items:")
for v, t in stems[:5]:
    print(f"    {v:6d}  {t[:44]}")
print("\n  5 hoechste fertige Items:")
for v, t in stems[-5:]:
    print(f"    {v:6d}  {t[:44]}")
