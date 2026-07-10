"""Integritaetspruefung der 216 'fertigen' Items.

Frage: Sind die akzeptierten Antworten im Quelltext (Aufgabe/Auswertung/
Kommentierung) tatsaechlich BELEGT - oder frei erfunden?

Methode: Jede Antwort wird normalisiert und als Teilstring im normalisierten
Quelltext gesucht. Zusaetzlich wird der Cache data/vera_nachlauf_raw/ bzw. die
Originaldatei herangezogen, damit auch Items ohne *_roh-Felder fair geprueft werden.
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from vera_nachlauf import convert, slug_of  # noqa: E402


def norm(text):
    """Kleinschreibung, Dezimalkomma->Punkt, alles Nicht-Alphanumerische raus."""
    t = (text or "").lower().replace(",", ".")
    t = t.replace(" ", " ")
    return re.sub(r"[^a-z0-9äöüß./%:-]+", "", t)


def source_text(item):
    """Voller Quelltext: roh-Felder + alle konvertierten Originaldateien."""
    parts = [item.get(k) or "" for k in
             ("aufgabe_text_roh", "auswertung_roh", "kommentierung_roh")]
    folder = os.path.join("data/vera8_docs", slug_of(item))
    if os.path.isdir(folder):
        for fname in os.listdir(folder):
            if fname.endswith((".doc", ".docx")):
                parts.append(convert(os.path.join(folder, fname)) or "")
    return norm("\n".join(parts))


doc = json.load(open("data/vera8_komplett.json"))
ready = [a for a in doc["aufgaben"]
         if a.get("aufgabe_text_clean") and a.get("akzeptierte_antworten")]

fully, partly, ungrounded = [], [], []
total_ans = grounded_ans = 0

for item in ready:
    src = source_text(item)
    answers = [a for a in item["akzeptierte_antworten"] if str(a).strip()]
    if not answers:
        continue
    hits = [a for a in answers if norm(str(a)) and norm(str(a)) in src]
    total_ans += len(answers)
    grounded_ans += len(hits)
    ratio = len(hits) / len(answers)
    rec = (ratio, len(hits), len(answers), item["iqb_titel"])
    (fully if ratio == 1 else partly if ratio > 0 else ungrounded).append(rec)

n = len(fully) + len(partly) + len(ungrounded)
print(f"Geprueft: {n} fertige Items mit Antworten   ({total_ans} Antwortvarianten)")
print(f"  Antwortvarianten im Quelltext belegt: {grounded_ans}/{total_ans} "
      f"({grounded_ans / total_ans:.1%})")
print()
print(f"  Items voll belegt      : {len(fully):3d} ({len(fully)/n:.0%})")
print(f"  Items teilweise belegt : {len(partly):3d} ({len(partly)/n:.0%})")
print(f"  Items GAR NICHT belegt : {len(ungrounded):3d} ({len(ungrounded)/n:.0%})")
print("\n  Beispiele ohne jeden Beleg (Antworten existieren nirgends in der Quelle):")
for _, h, t, titel in ungrounded[:12]:
    print(f"    {h}/{t}  {titel[:44]}")
print("\n  Beispiele voll belegt:")
for _, h, t, titel in fully[:8]:
    print(f"    {h}/{t}  {titel[:44]}")
