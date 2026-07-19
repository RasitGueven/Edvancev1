#!/usr/bin/env python3
"""C11 Schritt 2-5: Deko-Filter, DB-Bruecke, Sichtungs-HTML, Uebersichts-CSV.

Liest data/c11_tasks.json (read-only Dump) + die extrahierten Bilder aus
data/vera8_sichtung/<slug>/. Schreibt sichtung.html, sichtung.csv und
deko-hashes.csv. Trifft KEINE Entscheidung — alle Einordnungen sind
Vermutungen fuer die menschliche Sichtung.
"""
from __future__ import annotations

import collections
import csv
import hashlib
import html
import json
import os
import re
import subprocess
import unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SICHT = os.path.join(ROOT, "data", "vera8_sichtung")

# Ein Hash, der in mindestens so vielen verschiedenen Aufgaben auftaucht,
# kann keine aufgabenspezifische Grafik sein -> Deko (Logo, Lizenzstempel).
DEKO_MIN_AUFGABEN = 5

# Schwellen fuer die Vermutung "nur Text/Tabelle/Raster als Bild":
# seitengrosse Bilder mit sehr wenig Tinte sind typischerweise abfotografierter
# Aufgabentext, leere Antwortkaesten oder Karogitter.
SEITENBREIT_PX = 1000
TINTE_MAX = 0.08


# ---------------------------------------------------------------- Bild-Fakten

def sha256(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def bildmasse(path: str):
    """(breite, hoehe, tinte-anteil) — tinte = Anteil nicht-weisser Pixel."""
    try:
        out = subprocess.run(
            ["magick", path + "[0]", "-colorspace", "Gray", "-threshold", "85%",
             "-format", "%w %h %[fx:1-mean]", "info:"],
            capture_output=True, text=True, timeout=60,
        ).stdout.split()
        return int(out[0]), int(out[1]), float(out[2])
    except Exception:
        return 0, 0, 0.0


def bilder_je_slug() -> dict:
    result = {}
    for slug in sorted(os.listdir(SICHT)):
        d = os.path.join(SICHT, slug)
        if not os.path.isdir(d):
            continue
        imgs = []
        for name in sorted(os.listdir(d)):
            p = os.path.join(d, name)
            if not os.path.isfile(p):
                continue
            w, h, tinte = bildmasse(p)
            imgs.append({
                "datei": name,
                "bytes": os.path.getsize(p),
                "hash": sha256(p),
                "breite": w, "hoehe": h, "tinte": tinte,
            })
        result[slug] = imgs
    return result


# ------------------------------------------------------------- DB-Bruecke

def norm(s: str) -> str:
    s = (s or "").lower()
    for a, b in (("ä", "ae"), ("ö", "oe"), ("ü", "ue"), ("ß", "ss")):
        s = s.replace(a, b)
    s = unicodedata.normalize("NFKD", s)
    return re.sub(r"[^a-z0-9]", "", s)


def matche(tasks, slugs):
    """title -> docx-Ordner. Exakt, sonst Praefix. Mehrdeutig = unsicher."""
    by_slug = {}
    for t in tasks:
        key = norm(t["title"])
        t["slug_norm"] = key
        kandidaten = [s for s in slugs if norm(s) == key]
        art = "exakt"
        if not kandidaten:
            # Ordner tragen teils Suffixe ("innenwinkel" -> "innenwinkel2")
            kandidaten = [s for s in slugs if norm(s).startswith(key) and key]
            art = "praefix"
        if not kandidaten:
            kandidaten = [s for s in slugs if key.startswith(norm(s)) and norm(s)]
            art = "praefix_umgekehrt"

        if len(kandidaten) == 1:
            t["slug"] = kandidaten[0]
            t["match_unsicher"] = "" if art == "exakt" else art
        elif len(kandidaten) > 1:
            t["slug"] = ""
            t["match_unsicher"] = "mehrdeutig: " + "|".join(sorted(kandidaten))
        else:
            t["slug"] = ""
            t["match_unsicher"] = "kein_ordner_gefunden"

        if t["slug"]:
            by_slug.setdefault(t["slug"], []).append(t)

    # Ein Ordner, auf den mehrere Titel zeigen -> beide Seiten unsicher
    for slug, ts in by_slug.items():
        if len(ts) > 1:
            for t in ts:
                t["match_unsicher"] = "ordner_doppelt_belegt: " + slug
    return tasks


# ---------------------------------------------------------------- Auswertung

def vermutung(nicht_deko) -> str:
    """Heuristik, ausdruecklich Vermutung — keine Entscheidung."""
    if not nicht_deko:
        return "nur_text_tabelle_raster"
    seitig_und_leer = all(
        b["breite"] >= SEITENBREIT_PX and b["tinte"] < TINTE_MAX
        for b in nicht_deko
    )
    return "nur_text_tabelle_raster" if seitig_und_leer else "grafik_kandidat"


def main() -> None:
    tasks = json.load(open(os.path.join(ROOT, "data", "c11_tasks.json"), encoding="utf-8"))
    bilder = bilder_je_slug()
    tasks = matche(tasks, sorted(bilder))

    # --- Schritt 2: Deko-Hashes
    vorkommen = collections.defaultdict(set)
    beispiel = {}
    for slug, imgs in bilder.items():
        for b in imgs:
            vorkommen[b["hash"]].add(slug)
            beispiel.setdefault(b["hash"], f"{slug}/{b['datei']}")
    deko = {h for h, s in vorkommen.items() if len(s) >= DEKO_MIN_AUFGABEN}

    with open(os.path.join(SICHT, "deko-hashes.csv"), "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["hash", "vorkommen", "beispiel_dateiname"])
        for h in sorted(deko, key=lambda x: -len(vorkommen[x])):
            w.writerow([h, len(vorkommen[h]), beispiel[h]])

    for imgs in bilder.values():
        for b in imgs:
            b["deko"] = b["hash"] in deko

    # --- Schritt 5: CSV
    zeilen = []
    for t in sorted(tasks, key=lambda x: (x["slug"] or "zzz", x["title"] or "")):
        imgs = bilder.get(t["slug"], [])
        rest = [b for b in imgs if not b["deko"]]
        zeilen.append({
            "title": t["title"] or "",
            "slug": t["slug"],
            "task_id": t["id"],
            "match_unsicher": t["match_unsicher"],
            "anzahl_bilder_gesamt": len(imgs),
            "anzahl_nach_dekofilter": len(rest),
            "groesstes_bild_bytes": max((b["bytes"] for b in rest), default=0),
            # hat_png = echtes Pixelbild aus dem Dokument, kein gerenderter Vektor
            "hat_png": int(any(b["datei"].lower().endswith(".png")
                               and ".emf." not in b["datei"].lower()
                               and ".wmf." not in b["datei"].lower() for b in rest)),
            "hat_emf": int(any(".emf" in b["datei"].lower() or ".wmf" in b["datei"].lower()
                               for b in rest)),
            "needs_image_aktuell": "" if t["needs_image"] is None else str(t["needs_image"]).lower(),
            "vermutung": vermutung(rest),
        })

    with open(os.path.join(SICHT, "sichtung.csv"), "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(zeilen[0].keys()))
        w.writeheader()
        w.writerows(zeilen)

    # --- Schritt 4: HTML
    schreibe_html(tasks, bilder, zeilen)

    kand = sum(1 for z in zeilen if z["vermutung"] == "grafik_kandidat")
    unsicher = sum(1 for z in zeilen if z["match_unsicher"])
    print(f"Aufgaben          : {len(zeilen)}")
    print(f"grafik_kandidat   : {kand}")
    print(f"nur_text_...      : {len(zeilen) - kand}")
    print(f"match_unsicher    : {unsicher}")
    print(f"Deko-Hashes       : {len(deko)}")


def schreibe_html(tasks, bilder, zeilen) -> None:
    by_id = {z["task_id"]: z for z in zeilen}
    e = html.escape
    out = ["""<!doctype html><html lang="de"><head><meta charset="utf-8">
<title>VERA8 Bild-Sichtung</title><style>
body{font:15px/1.55 system-ui,sans-serif;background:#fff;color:#111;margin:0;padding:24px}
h1{font-size:20px}
.hinweis{background:#f4f4f4;border-left:3px solid #888;padding:12px 16px;max-width:900px;margin-bottom:24px}
.aufgabe{border-top:1px solid #ddd;padding:20px 0;display:grid;grid-template-columns:minmax(280px,1fr) 2fr;gap:24px}
.kopf{grid-column:1/-1;display:flex;flex-wrap:wrap;gap:12px;align-items:baseline}
.kopf b{font-size:17px}
.meta{color:#666;font-size:13px}
.warn{background:#fff3cd;border:1px solid #e0c05a;padding:2px 8px;font-size:13px}
.frage{white-space:pre-wrap;font-size:14px;color:#333;max-height:420px;overflow:auto;background:#fafafa;padding:12px;border:1px solid #eee}
.bilder{display:flex;flex-wrap:wrap;gap:16px;align-items:flex-start}
.bild{max-width:340px}
.bild img{max-width:340px;max-height:420px;border:1px solid #ccc;display:block;background:#fff}
.bild .cap{font-size:12px;color:#666;margin-top:4px;word-break:break-all}
.deko{margin-top:14px;padding-top:10px;border-top:1px dashed #ccc}
.deko .titel{font-size:12px;color:#999;margin-bottom:6px}
.deko img{max-width:70px;max-height:70px;border:1px solid #eee;opacity:.6}
.leer{color:#a00;font-size:14px}
</style></head><body>
<h1>VERA8 &mdash; Bild-Sichtung (Arbeitsdokument)</h1>
<div class="hinweis">
Pro Aufgabe entscheiden: <b>1.</b> Braucht sie ein Bild? <b>2.</b> Welches der Bilder ist
die echte Grafik? <b>3.</b> Ist Text mit der Grafik verschmolzen?<br>
Die Spalte &bdquo;Vermutung&ldquo; ist eine Heuristik, <b>keine Entscheidung</b>.
Ausgefilterte Deko (Logo/Lizenzstempel/Wiederholer) steht unten in jedem Block und
ist nicht geloescht, nur zurueckgestellt.
</div>"""]

    for t in sorted(tasks, key=lambda x: (x["slug"] or "zzz", x["title"] or "")):
        z = by_id[t["id"]]
        imgs = bilder.get(t["slug"], [])
        rest = [b for b in imgs if not b["deko"]]
        dek = [b for b in imgs if b["deko"]]

        out.append('<div class="aufgabe"><div class="kopf">')
        out.append(f'<b>{e(t["title"] or "(ohne Titel)")}</b>')
        out.append(f'<span class="meta">slug: {e(t["slug"]) or "&mdash;"} &middot; '
                   f'task_id: {e(t["id"])} &middot; needs_image: '
                   f'{e(z["needs_image_aktuell"]) or "NULL"} &middot; '
                   f'Vermutung: {e(z["vermutung"])}</span>')
        if t["match_unsicher"]:
            out.append(f'<span class="warn">match unsicher: {e(t["match_unsicher"])}</span>')
        out.append('</div>')

        out.append(f'<div class="frage">{e(t["question"] or "(keine question in der DB)")}</div>')

        out.append('<div><div class="bilder">')
        if rest:
            for b in rest:
                src = f'{t["slug"]}/{b["datei"]}'
                out.append(f'<div class="bild"><img src="{e(src)}" loading="lazy" alt="">'
                           f'<div class="cap">{e(b["datei"])} &middot; {b["bytes"]:,} B &middot; '
                           f'{b["breite"]}&times;{b["hoehe"]}</div></div>'.replace(",", "."))
        else:
            out.append('<div class="leer">Nach Deko-Filter kein Bild uebrig.</div>')
        out.append('</div>')

        if dek:
            out.append('<div class="deko"><div class="titel">ausgefiltert: Logo/Lizenz '
                       f'({len(dek)})</div>')
            for b in dek:
                src = f'{t["slug"]}/{b["datei"]}'
                out.append(f'<img src="{e(src)}" loading="lazy" alt="" title="{e(b["datei"])}">')
            out.append('</div>')
        out.append('</div></div>')

    out.append("</body></html>")
    with open(os.path.join(SICHT, "sichtung.html"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(out))


if __name__ == "__main__":
    main()
