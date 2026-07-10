"""Wieviele der 81 Items liessen sich OHNE Raten ehrlich befuellen?

Kriterium: Die Auswertungsdatei enthaelt eine konkrete Loesung - also Text
jenseits von 'RICHTIG/FALSCH' und IQB-Item-IDs.
"""
import os
import re
from collections import Counter

RAW = "data/vera_nachlauf_raw"


def has_concrete_answer(text):
    body = re.sub(r"\[pic\]", " ", text).replace("|", " ")
    body = re.sub(r"\bM\d{4,6}[_A-Z]*\b", " ", body)   # IQB-Item-IDs
    body = re.sub(r"Teilaufgabe\s*\d+\s*:?", " ", body)
    body = re.sub(r"\b(RICHTIG|FALSCH|Alle anderen Antworten\.?)\b", " ", body, flags=re.I)
    body = re.sub(r"\s+", " ", body).strip()
    # konkrete Loesung = mindestens eine Ziffer UND nennenswerter Resttext
    return bool(re.search(r"\d", body)) and len(body) > 40, body


rows = []
for fname in sorted(os.listdir(RAW)):
    if not fname.endswith("_auswertung.txt"):
        continue
    slug = fname[: -len("_auswertung.txt")]
    text = open(os.path.join(RAW, fname)).read()
    ok, body = has_concrete_answer(text)
    rows.append((slug, ok, len(body), body[:90]))

c = Counter(ok for _, ok, _, _ in rows)
print(f"Auswertungen im Cache: {len(rows)}")
print(f"  mit konkreter, ableitbarer Loesung : {c[True]:3d}")
print(f"  ohne (nur RICHTIG/FALSCH, Rest Bild): {c[False]:3d}")
print("\n--- Beispiele MIT konkreter Loesung ---")
for slug, ok, n, prev in rows:
    if ok:
        print(f"  {slug[:26]:28s} {prev}")
print("\n--- Beispiele OHNE (nicht ehrlich befuellbar) ---")
shown = 0
for slug, ok, n, prev in rows:
    if not ok and shown < 10:
        print(f"  {slug[:26]:28s} rest={n:3d}  {prev!r}")
        shown += 1
