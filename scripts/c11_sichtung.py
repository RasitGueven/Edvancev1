#!/usr/bin/env python3
"""
C11 Sichtungs-Paket — deterministisch, kein Agent.
Extrahiert Bilder aus allen vera8_docs, konvertiert EMF->PNG, trimmt Raender,
filtert Deko per Hash, baut sichtung.html + sichtung.csv + deko-hashes.csv.

Idempotent: bereits extrahierte Ordner werden uebersprungen (Bild-Extraktion),
aber die Sichtung wird immer ueber den KOMPLETTEN Bestand neu gebaut.
"""
import os, sys, zipfile, hashlib, subprocess, shutil, csv, html, re, unicodedata, tempfile
from collections import defaultdict, Counter

DOCS = "data/vera8_docs"
OUT  = "data/vera8_sichtung"
os.makedirs(OUT, exist_ok=True)

# ---------- DB: Titel + question + needs_image lesen (nur SELECT) ----------
def db_rows():
    """Liefert dict slug->{'title','task_id','question','needs_image'} via psql.
    question wird als JSON geladen, damit mehrzeilige Texte das Parsen nicht zerschiessen."""
    import subprocess, json
    dburl = None
    for line in open(".env"):
        if line.startswith("DATABASE_URL="):
            dburl = line.split("=",1)[1].strip().strip('"'); break
    if not dburl:
        print("WARN: DATABASE_URL nicht gefunden — Sichtung ohne DB-Text"); return {}
    # Eine Zeile pro Task als JSON-Objekt -> Umbrueche in question sind escaped
    q = ("select json_agg(json_build_object("
         "'id', id, 'title', title, "
         "'question', coalesce(question,''), "
         "'needs_image', coalesce(needs_image::text,''))) from tasks")
    r = subprocess.run(["psql", dburl, "-t", "-A", "-c", q],
                       capture_output=True, text=True)
    rows = {}
    try:
        for o in json.loads(r.stdout.strip()):
            rows[slugify(o["title"])] = {
                "title": o["title"], "task_id": o["id"],
                "question": o["question"], "needs_image": o["needs_image"]}
    except Exception as e:
        print(f"WARN: DB-Parse-Fehler: {e}")
    return rows

def slugify(t):
    t = (t or "").lower().strip()
    t = t.replace('ä','ae').replace('ö','oe').replace('ü','ue').replace('ß','ss')
    t = unicodedata.normalize('NFKD', t).encode('ascii','ignore').decode()
    return re.sub(r'[^a-z0-9]', '', t)

# ---------- Bild-Extraktion pro Aufgabe ----------
def find_aufgabe(folder):
    for f in os.listdir(folder):
        if 'Aufgabe' in f and f.lower().endswith('.docx'):
            return os.path.join(folder, f), 'docx'
    for f in os.listdir(folder):
        if 'Aufgabe' in f and f.lower().endswith('.doc'):
            return os.path.join(folder, f), 'doc'
    return None, None

def doc_to_docx(doc_path):
    tmp = tempfile.mkdtemp()
    subprocess.run(["soffice","--headless","--convert-to","docx","--outdir",tmp,doc_path],
                   capture_output=True, timeout=120)
    base = os.path.splitext(os.path.basename(doc_path))[0] + ".docx"
    out = os.path.join(tmp, base)
    return out if os.path.exists(out) else None

def extract_images(docx_path, dest):
    os.makedirs(dest, exist_ok=True)
    imgs = []
    try:
        z = zipfile.ZipFile(docx_path)
    except Exception as e:
        print(f"    ZIP-Fehler: {e}"); return imgs
    for n in z.namelist():
        if 'media/' not in n: continue
        name = n.split('/')[-1]
        data = z.read(n)
        raw = os.path.join(dest, name)
        open(raw,'wb').write(data)
        ext = name.lower().rsplit('.',1)[-1]
        if ext == 'emf':
            png = os.path.splitext(raw)[0] + '.png'
            subprocess.run(["inkscape", raw, "--export-type=png",
                            f"--export-filename={png}"],
                           capture_output=True, timeout=60)
            if os.path.exists(png):
                subprocess.run(["convert", png, "-trim", png], capture_output=True)
                os.remove(raw)
                imgs.append(png)
            else:
                imgs.append(raw)  # Konvertierung fehlgeschlagen, EMF behalten
        elif ext in ('png','jpg','jpeg','gif'):
            if ext in ('png',):
                subprocess.run(["convert", raw, "-trim", raw], capture_output=True)
            imgs.append(raw)
    return imgs

# ---------- Hauptlauf ----------
def main():
    folders = sorted(d for d in os.listdir(DOCS)
                     if os.path.isdir(os.path.join(DOCS, d)))
    print(f"{len(folders)} Aufgaben-Ordner gefunden")

    # 1) Extraktion (idempotent)
    aufgaben = {}  # slug -> {'folder','images':[paths]}
    for i, d in enumerate(folders, 1):
        dest = os.path.join(OUT, d)
        src  = os.path.join(DOCS, d)
        # schon extrahiert? (Ordner existiert und hat Bilder)
        if os.path.isdir(dest) and any(
            f.lower().endswith(('.png','.jpg','.jpeg','.gif','.emf'))
            for f in os.listdir(dest)):
            imgs = [os.path.join(dest,f) for f in sorted(os.listdir(dest))
                    if f.lower().endswith(('.png','.jpg','.jpeg','.gif','.emf'))]
            aufgaben[d] = {'folder':d, 'images':imgs}
            continue
        auf, kind = find_aufgabe(src)
        if not auf:
            print(f"[{i}/{len(folders)}] {d}: keine Aufgabe-Datei"); continue
        docx = auf if kind=='docx' else doc_to_docx(auf)
        if not docx:
            print(f"[{i}/{len(folders)}] {d}: .doc-Konvertierung fehlgeschlagen"); continue
        imgs = extract_images(docx, dest)
        aufgaben[d] = {'folder':d, 'images':imgs}
        print(f"[{i}/{len(folders)}] {d}: {len(imgs)} Bilder")

    # 2) Deko per Hash (>=5 Vorkommen)
    hashes = defaultdict(list)  # hash -> [(slug, path)]
    for slug, a in aufgaben.items():
        for p in a['images']:
            try:
                h = hashlib.sha256(open(p,'rb').read()).hexdigest()
                hashes[h].append((slug, p))
            except: pass
    deko = {h for h,v in hashes.items() if len(set(s for s,_ in v)) >= 5}
    path_hash = {p:h for h,v in hashes.items() for _,p in v}
    print(f"\nDeko-Hashes (>=5 Vorkommen): {len(deko)}")

    # 3) DB-Bruecke
    db = db_rows()
    print(f"DB-Items gelesen: {len(db)}")

    # 4) CSV + HTML
    write_outputs(aufgaben, deko, path_hash, hashes, db)

def write_outputs(aufgaben, deko, path_hash, hashes, db):
    # deko-hashes.csv
    with open(os.path.join(OUT,"deko-hashes.csv"),"w",newline='') as f:
        w = csv.writer(f); w.writerow(["hash","vorkommen","beispiel"])
        for h,v in sorted(hashes.items(), key=lambda x:-len(x[1])):
            if h in deko:
                w.writerow([h[:16], len(set(s for s,_ in v)), os.path.basename(v[0][1])])

    # sichtung.csv + HTML
    csv_rows = []
    blocks = []
    def find_db(slug):
        if slug in db: return db[slug]
        # Praefix-Match (innenwinkel2 -> innenwinkel, etc.)
        for dbslug, info in db.items():
            if slug.startswith(dbslug) or dbslug.startswith(slug):
                return info
        return {}

    for slug in sorted(aufgaben):
        a = aufgaben[slug]
        info = find_db(slug)
        match_unsicher = "" if info else "JA"
        echte = [p for p in a['images'] if path_hash.get(p) not in deko]
        dekobilder = [p for p in a['images'] if path_hash.get(p) in deko]
        groesst = max((os.path.getsize(p) for p in echte), default=0)
        hat_png = any(p.lower().endswith('.png') for p in echte)
        hat_emf = any(p.lower().endswith('.emf') for p in a['images'])
        # Heuristik-Vermutung
        if not echte:
            verm = "nur_text_tabelle_raster"
        elif groesst > 500000:
            verm = "grafik_kandidat_gross_evtl_raster"
        else:
            verm = "grafik_kandidat"
        csv_rows.append({
            "title": info.get("title",""), "slug": slug,
            "task_id": info.get("task_id",""), "match_unsicher": match_unsicher,
            "anzahl_gesamt": len(a['images']), "anzahl_echt": len(echte),
            "groesstes_bytes": groesst, "hat_png": hat_png, "hat_emf": hat_emf,
            "needs_image_aktuell": info.get("needs_image",""), "vermutung": verm,
        })
        # HTML-Block
        def imgtag(p):
            rel = os.path.relpath(p, OUT)
            return (f'<figure><img src="{html.escape(rel)}" loading="lazy">'
                    f'<figcaption>{html.escape(os.path.basename(p))} · '
                    f'{os.path.getsize(p)} B</figcaption></figure>')
        warn = ('<span class="warn">⚠ kein DB-Match</span>' if match_unsicher else '')
        blocks.append(f'''
<section>
  <h2>{html.escape(info.get("title",slug))} {warn}</h2>
  <div class="meta">slug: {html.escape(slug)} · task_id: {html.escape(info.get("task_id","—"))}
     · needs_image: {html.escape(info.get("needs_image","") or "—")}
     · Vermutung: <b>{verm}</b></div>
  <div class="cols">
    <div class="text">{html.escape(info.get("question","(kein Text in DB)"))}</div>
    <div class="imgs">{"".join(imgtag(p) for p in echte) or "<i>keine Nicht-Deko-Bilder</i>"}</div>
  </div>
  <details><summary>Deko ausgefiltert ({len(dekobilder)})</summary>
    <div class="deko">{"".join(imgtag(p) for p in dekobilder)}</div>
  </details>
</section>''')

    with open(os.path.join(OUT,"sichtung.csv"),"w",newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(csv_rows[0].keys()))
        w.writeheader(); w.writerows(csv_rows)

    css = '''body{font-family:system-ui,sans-serif;max-width:1200px;margin:0 auto;padding:20px;background:#faf9f6;color:#222}
    section{border:1px solid #ddd;border-radius:8px;padding:16px;margin:16px 0;background:#fff}
    h2{margin:0 0 8px;font-size:18px}.meta{color:#666;font-size:13px;margin-bottom:10px}
    .cols{display:flex;gap:20px}.text{flex:1;white-space:pre-wrap;font-size:14px;line-height:1.5;background:#f6f6f4;padding:10px;border-radius:6px}
    .imgs{flex:1;display:flex;flex-wrap:wrap;gap:10px;align-items:flex-start}
    figure{margin:0}img{max-width:280px;max-height:280px;border:1px solid #ccc;background:#fff}
    figcaption{font-size:11px;color:#888}.warn{color:#b00;font-size:13px}
    .deko img{max-width:120px;max-height:80px;opacity:.6}details{margin-top:8px;font-size:13px;color:#888}'''
    stats = Counter(r["vermutung"] for r in csv_rows)
    header = (f'<h1>VERA-8 Sichtung — {len(csv_rows)} Aufgaben</h1>'
              f'<p>grafik_kandidat: {stats.get("grafik_kandidat",0)} · '
              f'gross/raster: {stats.get("grafik_kandidat_gross_evtl_raster",0)} · '
              f'nur_text: {stats.get("nur_text_tabelle_raster",0)} · '
              f'kein DB-Match: {sum(1 for r in csv_rows if r["match_unsicher"])}</p>')
    with open(os.path.join(OUT,"sichtung.html"),"w") as f:
        f.write(f"<!DOCTYPE html><html><head><meta charset='utf-8'><style>{css}</style></head>"
                f"<body>{header}{''.join(blocks)}</body></html>")

    print(f"\n=== FERTIG ===")
    print(f"Aufgaben: {len(csv_rows)}")
    for k,v in stats.items(): print(f"  {k}: {v}")
    print(f"  kein DB-Match: {sum(1 for r in csv_rows if r['match_unsicher'])}")
    print(f"Ausgabe: {OUT}/sichtung.html, sichtung.csv, deko-hashes.csv")

if __name__ == "__main__":
    main()
