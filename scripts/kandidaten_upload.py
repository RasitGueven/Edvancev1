#!/usr/bin/env python3
"""
Laedt fuer die needs_image=true-Aufgaben die Nicht-Deko-Kandidatenbilder
aus data/vera8_sichtung/<slug>/ in den Storage nach
  task-assets/kandidaten/<task_id>/<bildname>

Damit der Pflege-Wizard (StepImages) sie als anklickbare Kandidaten zeigen kann.
Idempotent: schon hochgeladene Kandidaten werden uebersprungen.
KEINE Zuweisung an tasks.assets — das macht Lena im Wizard (auswaehlen + croppen).

Aufruf:
  python3 scripts/kandidaten_upload.py          # Dry-Run
  python3 scripts/kandidaten_upload.py apply    # laedt wirklich hoch
"""
import os, sys, json, subprocess, re, unicodedata, urllib.request, hashlib, csv, mimetypes

APPLY = len(sys.argv) > 1 and sys.argv[1] == "apply"
SICHT = "data/vera8_sichtung"
BUCKET = "task-assets"

def env(key):
    for line in open(".env"):
        if line.startswith(key+"="):
            return line.split("=",1)[1].strip().strip('"')

SUPABASE_URL = env("VITE_SUPABASE_URL")
SERVICE_KEY  = None
for line in open(".env"):
    if re.match(r'^(SERVICE_ROLE|SUPABASE_SERVICE)', line, re.I) or "SERVICE_ROLE" in line.upper() or "SERVICE_KEY" in line.upper():
        SERVICE_KEY = line.split("=",1)[1].strip().strip('"'); break
if not SERVICE_KEY:
    print("KEIN Service-Key in .env"); sys.exit(1)

def dburl():
    return env("DATABASE_URL")

def slugify(t):
    t=(t or "").lower().strip().replace('ä','ae').replace('ö','oe').replace('ü','ue').replace('ß','ss')
    t=unicodedata.normalize('NFKD',t).encode('ascii','ignore').decode()
    return re.sub(r'[^a-z0-9]','',t)

def deko_hashes():
    p = os.path.join(SICHT,"deko-hashes.csv")
    if not os.path.exists(p): return set()
    return {row["hash"] for row in csv.DictReader(open(p))}
DEKO = deko_hashes()
def is_deko(path):
    try:
        h = hashlib.sha256(open(path,'rb').read()).hexdigest()
        return h[:16] in DEKO or h in DEKO
    except: return False

def needs_image_tasks():
    """task_id + title fuer alle needs_image=true."""
    q = "select json_agg(json_build_object('id',id,'title',title)) from tasks where needs_image = true"
    r = subprocess.run(["psql", dburl(), "-t","-A","-c", q], capture_output=True, text=True)
    return json.loads(r.stdout.strip() or "[]")

def storage_list(prefix):
    body = json.dumps({"limit":1000,"prefix":prefix}).encode()
    req = urllib.request.Request(f"{SUPABASE_URL}/storage/v1/object/list/{BUCKET}",
        data=body, headers={"apikey":SERVICE_KEY,"Authorization":f"Bearer {SERVICE_KEY}",
        "Content-Type":"application/json"})
    try:
        return [o["name"] for o in json.load(urllib.request.urlopen(req)) if o.get("id")]
    except: return []

def storage_upload(path, local_file):
    data = open(local_file,"rb").read()
    ctype = mimetypes.guess_type(local_file)[0] or "image/png"
    req = urllib.request.Request(f"{SUPABASE_URL}/storage/v1/object/{BUCKET}/{path}",
        data=data, method="POST",
        headers={"apikey":SERVICE_KEY,"Authorization":f"Bearer {SERVICE_KEY}",
                 "Content-Type":ctype, "x-upsert":"true"})
    try:
        urllib.request.urlopen(req); return True
    except Exception as e:
        print(f"    Upload-Fehler {path}: {e}"); return False

def find_folder(slug):
    if os.path.isdir(os.path.join(SICHT, slug)): return slug
    for d in os.listdir(SICHT):
        if os.path.isdir(os.path.join(SICHT,d)) and (d.startswith(slug) or slug.startswith(d)):
            return d
    return None

def main():
    tasks = needs_image_tasks()
    print(f"{len(tasks)} needs_image-Aufgaben\n")
    total_uploads = 0; total_skip = 0; no_folder = 0
    for t in tasks:
        tid = t["id"]; slug = slugify(t["title"])
        folder = find_folder(slug)
        if not folder:
            no_folder += 1; continue
        fdir = os.path.join(SICHT, folder)
        kandidaten = [f for f in sorted(os.listdir(fdir))
                      if f.lower().endswith(('.png','.jpg','.jpeg'))
                      and not is_deko(os.path.join(fdir,f))]
        if not kandidaten: continue
        # schon hochgeladen?
        vorhanden = set(n.split('/')[-1] for n in storage_list(f"kandidaten/{tid}/")) if APPLY else set()
        for k in kandidaten:
            dest = f"kandidaten/{tid}/{k}"
            if k in vorhanden:
                total_skip += 1; continue
            if APPLY:
                if storage_upload(dest, os.path.join(fdir,k)):
                    total_uploads += 1
            else:
                total_uploads += 1  # im Dry-Run nur zaehlen
        print(f"  {t['title']}: {len(kandidaten)} Kandidat(en)")
    print(f"\n=== {'HOCHGELADEN' if APPLY else 'DRY-RUN'} ===")
    print(f"  Uploads: {total_uploads}")
    if APPLY: print(f"  uebersprungen (schon da): {total_skip}")
    print(f"  ohne Sichtungs-Ordner: {no_folder}")
    if not APPLY:
        print("\nZum echten Hochladen: python3 scripts/kandidaten_upload.py apply")

if __name__ == "__main__":
    main()
