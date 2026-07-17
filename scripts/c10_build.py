#!/usr/bin/env python3
"""C10-Audit Schritt 1: Master-Arbeitstabelle bauen (read-only).
Mappt Tasks auf r01_extract-Slugs, haengt Lizenzhinweis, Asset-Split,
Text-Bild-Verweise und Vollstaendigkeitsfelder an. -> data/c10_master.json"""
from __future__ import annotations

import collections
import json
import os
import re
import unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "data")

data = json.load(open(os.path.join(DATA, "c10_dump.json")))
extract_dir = os.path.join(DATA, "r01_extract")
extract = set(f[:-5] for f in os.listdir(extract_dir) if f.endswith(".json"))


def slug_from_assets(t):
    for a in (t.get("assets") or []):
        u = a.get("url", "")
        m = re.search(r"/(?:lsa|r01_render)/([a-z0-9_]+)/", u)
        if m:
            return m.group(1)
    return None


def norm_title(s):
    s = s.lower()
    for a, b in (("ä", "ae"), ("ö", "oe"), ("ü", "ue"), ("ß", "ss")):
        s = s.replace(a, b)
    s = unicodedata.normalize("NFKD", s)
    return re.sub(r"[^a-z0-9]", "", s)


def norm_slug(s):
    # Extract-Slugs koennen Suffixe tragen (…_Aufgabe.ggb)
    return re.sub(r"[^a-z0-9]", "", s.lower().split("_aufgabe")[0])


# handverifizierte Umbenennungen Task-Titel -> Extract-Slug
RENAMES = {
    "kaufeinesdvdplayers": "dvdplayer",
    "quadratimkoordinatensystem": "koordinatensystem",
    "koerpermitseitenflaechen": "seitenflaechen",
    "temperaturenin frankfurtammain".replace(" ", ""): "temperaturen",
    "geometrischekoerpererkennen": "geometrischekoerper",
    "linearefunktionenanwenden": "linearefunktionen",
}


IMG_WORDS = re.compile(
    r"\b(Abbildung|Abb\.|Bild|Grafik|Skizze|Zeichnung|Diagramm|Figur|Foto|"
    r"Darstellung|abgebildet|dargestellt|siehe unten|nebenstehend|Schaubild|Netz|Karte)\b",
    re.IGNORECASE,
)

rows = []
nomap = []
for t in data:
    slug = slug_from_assets(t)
    if not slug or slug not in extract:
        nt = norm_title(t["title"])
        nt = RENAMES.get(nt, nt)
        exact = [e for e in extract if norm_slug(e) == nt]
        if len(exact) == 1:
            slug = exact[0]
        else:
            # Slug kann ein abgeschnittener Titel-Praefix sein (z.B. aussagenzurprop)
            pref = [e for e in extract if len(norm_slug(e)) >= 10 and nt.startswith(norm_slug(e))]
            if len(pref) == 1:
                slug = pref[0]

    lic = None
    if slug in extract:
        ex = json.load(open(os.path.join(extract_dir, slug + ".json")))
        lz = ex.get("lizenz") or {}
        hinweis = lz.get("hinweis") or ""
        lic = {
            "hinweis": hinweis,
            # Regel aus docs/LIZENZ-IQB.md: Wort "Grafik" im Hinweis
            "grafik_gedeckt_wortcheck": bool(re.search(r"\bGrafik\b", hinweis)),
            "grafik_gedeckt_feld": lz.get("grafik_gedeckt"),
        }
    else:
        nomap.append(t["title"])

    urls, dead = [], []
    for a in (t.get("assets") or []):
        u = a.get("url", "")
        (urls if "supabase.co" in u else dead).append(a)

    # Text-Bild-Verweise: question + parts durchsuchen
    text_blobs = [t.get("question") or ""]
    for p in (t.get("parts") or []):
        if isinstance(p, dict):
            for v in p.values():
                if isinstance(v, str):
                    text_blobs.append(v)
    full = "\n".join(text_blobs)
    mentions = []
    for m in IMG_WORDS.finditer(full):
        s = max(0, m.start() - 60)
        mentions.append(full[s : m.end() + 60].replace("\n", " "))
    rows.append(
        {
            "id": t["id"],
            "title": t["title"],
            "slug": slug if slug in extract else None,
            "status": t["status"],
            "input_type": t["input_type"],
            "afb": t.get("afb"),
            "curriculum_grade": t.get("curriculum_grade"),
            "est_duration_sec": t.get("est_duration_sec"),
            "n_parts": len(t.get("parts") or []),
            "url_assets": urls,
            "dead_assets": dead,
            "img_mentions": mentions[:4],
            "has_solution": t.get("has_solution"),
            "has_beleg": t.get("has_beleg"),
            "has_correct_answers": bool(t.get("correct_answers")),
            "lizenz": lic,
        }
    )

json.dump(rows, open(os.path.join(DATA, "c10_master.json"), "w"), ensure_ascii=False, indent=1)

dups = [s for s, c in collections.Counter(r["slug"] for r in rows if r["slug"]).items() if c > 1]
print("rows:", len(rows), "| unmapped:", len(nomap), nomap[:20])
print("dup slugs:", dups)
n_url = sum(1 for r in rows if r["url_assets"])
n_dead = sum(1 for r in rows if r["dead_assets"])
n_ment = sum(1 for r in rows if r["img_mentions"] and not r["url_assets"] and not r["dead_assets"])
print(f"items mit URL-Assets: {n_url} | mit toten Pfaden: {n_dead} | nur Text-Verweis: {n_ment}")
print("ohne Loesung:", sum(1 for r in rows if not r["has_solution"]))
print("ohne Beleg:", sum(1 for r in rows if not r["has_beleg"]))
