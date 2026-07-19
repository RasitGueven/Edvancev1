#!/usr/bin/env python3
"""
OCR/Vision-Vorschlaege fuer VERA-Aufgaben.
Liest die gerenderten Aufgabenbilder via Claude-API und schlaegt pro Aufgabe
Stamm + parts + input_type + needs_image + Loesung vor.

NIE in die DB. Nur Vorschlagsdateien:
  data/ocr-vorschlaege/<slug>.json   (strukturierter Vorschlag)
  data/ocr-vorschlaege/vorschlaege.html  (Bild links, Vorschlag rechts, zum Pruefen)

Auswahl: parts-lose Aufgaben mit vorhandenen Sichtungs-Bildern, Querschnitt.
Limit per CLI-Arg (default 20).
"""
import os, sys, json, base64, subprocess, re, unicodedata, urllib.request, html, hashlib
from collections import defaultdict

LIMIT = int(sys.argv[1]) if len(sys.argv) > 1 else 20
MODEL = "claude-sonnet-4-5"   # stark genug fuer Formeln/Tabellen; nicht Haiku
SICHT = "data/vera8_sichtung"
OUT   = "data/ocr-vorschlaege"
os.makedirs(OUT, exist_ok=True)

KEY = None
for line in open(".env"):
    if line.startswith("ANTHROPIC_API_KEY="):
        KEY = line.split("=",1)[1].strip().strip('"').strip()
if not KEY:
    print("KEIN ANTHROPIC_API_KEY in .env"); sys.exit(1)

def slugify(t):
    t=(t or "").lower().strip().replace('ä','ae').replace('ö','oe').replace('ü','ue').replace('ß','ss')
    t=unicodedata.normalize('NFKD',t).encode('ascii','ignore').decode()
    return re.sub(r'[^a-z0-9]','',t)

def dburl():
    for line in open(".env"):
        if line.startswith("DATABASE_URL="):
            return line.split("=",1)[1].strip().strip('"')

# --- Aufgaben mit leeren parts + vorhandenen Bildern auswaehlen ---
def pick_tasks():
    q = ("select json_agg(json_build_object('id',id,'title',title,"
         "'question',coalesce(question,''),'input_type',coalesce(input_type,''),"
         "'has_parts',(parts is not null and jsonb_array_length(parts)>0))) from tasks")
    r = subprocess.run(["psql", dburl(), "-t","-A","-c", q], capture_output=True, text=True)
    tasks = json.loads(r.stdout.strip())
    # nur ohne parts, mit vorhandenem Bildordner
    cand = []
    for t in tasks:
        if t["has_parts"]: continue
        slug = slugify(t["title"])
        # Bildordner finden (exakt oder praefix)
        folder = None
        if os.path.isdir(os.path.join(SICHT, slug)):
            folder = slug
        else:
            for d in os.listdir(SICHT):
                if os.path.isdir(os.path.join(SICHT,d)) and (d.startswith(slug) or slug.startswith(d)):
                    folder = d; break
        if not folder: continue
        imgs = [f for f in sorted(os.listdir(os.path.join(SICHT,folder)))
                if f.lower().endswith(('.png','.jpg','.jpeg'))]
        if not imgs: continue
        t["folder"] = folder; t["images"] = imgs
        cand.append(t)
    # kleiner Test-Lauf (<=30): Querschnitt gestreut. Grosser Lauf: alle.
    if LIMIT <= 30 and len(cand) > LIMIT:
        step = max(1, len(cand)//LIMIT)
        cand = cand[::step][:LIMIT]
    return cand[:LIMIT]

# --- Deko-Hashes laden (Logo/Lizenz nicht mitschicken) ---
def deko_hashes():
    p = os.path.join(SICHT,"deko-hashes.csv")
    if not os.path.exists(p): return set()
    import csv
    return {row["hash"] for row in csv.DictReader(open(p))}

DEKO = deko_hashes()
def is_deko(path):
    try:
        h = hashlib.sha256(open(path,'rb').read()).hexdigest()
        return h[:16] in DEKO or h in DEKO
    except: return False

PROMPT = """Du liest eine deutsche Mathematik-Aufgabe (VERA-8, Klasse 8) aus Bildern. Die Aufgabe liegt als Bild vor, weil Text, Tabellen und Grafiken bei der Quelle eingebettet sind. Extrahiere die Struktur.

Gib AUSSCHLIESSLICH gueltiges JSON zurueck. KEIN Markdown, KEINE Backticks, KEIN Erklaertext davor oder danach. Escape alle Anfuehrungszeichen INNERHALB von Textwerten als \\". Format:
{
  "stamm": "gemeinsamer Einleitungstext der Aufgabe (Kontext, der fuer alle Teilaufgaben gilt)",
  "parts": [
    {
      "nr": 1,
      "kind": "mc" | "short_input" | "numeric" | "free_text",
      "prompt": "Fragetext der Teilaufgabe",
      "unit": "cm" | null,
      "options": [{"id":"a","label":"..."}]  (nur bei kind=mc, sonst weglassen),
      "loesung_vorschlag": "die vermutete richtige Antwort/Loesung",
      "mehrere_loesungen_moeglich": true|false
    }
  ],
  "input_type": "MC" | "SHORT_TEXT" | "NUMERIC" | "FREE_TEXT" | "MULTI_PART",
  "needs_image": true|false  (true NUR wenn eine echte Grafik/Diagramm/Figur zum Loesen noetig ist; false wenn nur Text/Tabelle/leeres Karogitter),
  "braucht_tabellentyp": true|false  (true wenn eine echte auszufuellende Tabelle mit mehreren Zellen die Aufgabe traegt, die sich NICHT sauber als einzelne numeric/short_input-Parts abbilden laesst),
  "ist_zeichenaufgabe": true|false  (true wenn das Kind etwas ZEICHNEN/EINZEICHNEN soll, z.B. in ein Koordinatensystem oder Gitter — solche Aufgaben kann die LSA nicht automatisch auswerten),
  "unsicher": "kurzer Hinweis, wo du dir unsicher warst, oder null"
}

Regeln:
- WICHTIG: Wenn eine Teilaufgabe SOWOHL eine Auswahl/Rechnung ALS AUCH eine Begruendung verlangt ("Kreuze an. Begruende deine Antwort."), mache daraus ZWEI getrennte parts: einen mc/numeric-Part fuer die Auswahl und einen free_text-Part fuer die Begruendung. Niemals beides in einem prompt zusammenlassen.
- Eine Tabelle wie 'ergaenze alpha/beta/gamma' ist KEIN braucht_tabellentyp — das sind einzelne numeric-Parts (je eine Zahl). braucht_tabellentyp nur bei echten Vielzell-Wertetabellen.
- ist_zeichenaufgabe=true bei "zeichne", "zeichne ein", "ergaenze im Koordinatensystem", "trage ein" mit Zeichenbezug. Diese Aufgaben sind fuer die automatische LSA ungeeignet — markiere sie, verflache sie NICHT zu free_text.
- Wenn eine Loesung mehrere richtige Moeglichkeiten hat (z.B. 'ergaenze eine Moeglichkeit'), setze mehrere_loesungen_moeglich=true und nenne im loesung_vorschlag die Bedingung.
- Lies Formeln und Zahlen praezise. Wenn ein Wert unklar ist, schreibe ihn in 'unsicher'.
- Erfinde nichts. Wenn ein Teil im Bild nicht lesbar ist, sag es in 'unsicher'."""

def call_api(image_paths, retry=True):
    content = []
    for p in image_paths:
        data = base64.b64encode(open(p,'rb').read()).decode()
        ext = p.lower().rsplit('.',1)[-1]
        media = "image/png" if ext=="png" else "image/jpeg"
        content.append({"type":"image","source":{"type":"base64","media_type":media,"data":data}})
    content.append({"type":"text","text":PROMPT})
    body = json.dumps({"model":MODEL,"max_tokens":2000,
                       "messages":[{"role":"user","content":content}]}).encode()
    req = urllib.request.Request("https://api.anthropic.com/v1/messages", data=body,
        headers={"x-api-key":KEY,"anthropic-version":"2023-06-01","content-type":"application/json"})
    resp = json.load(urllib.request.urlopen(req, timeout=120))
    txt = resp["content"][0]["text"].strip()
    txt = re.sub(r'^```json\s*|\s*```$', '', txt).strip()
    try:
        return json.loads(txt)
    except json.JSONDecodeError:
        # Bergungsversuch: nur den ersten {...}-Block nehmen
        m = re.search(r'\{.*\}', txt, re.DOTALL)
        if m:
            try:
                return json.loads(m.group(0))
            except json.JSONDecodeError:
                pass
        if retry:
            # einmal neu anfordern (LLM produziert oft beim 2. Mal sauberes JSON)
            return call_api(image_paths, retry=False)
        raise

def main():
    tasks = pick_tasks()
    print(f"{len(tasks)} Aufgaben ausgewaehlt (parts-los, mit Bildern)\n")
    results = []
    for i, t in enumerate(tasks, 1):
        folder = t["folder"]
        jpath = os.path.join(OUT, f"{folder}.json")
        # idempotent: schon vorhandene Vorschlaege nicht neu berechnen (spart API-Kosten)
        if os.path.exists(jpath):
            try:
                results.append(json.load(open(jpath)))
                print(f"[{i}/{len(tasks)}] {t['title']}: schon vorhanden, uebersprungen")
                continue
            except: pass
        imgs = [os.path.join(SICHT,folder,f) for f in t["images"]]
        echte = [p for p in imgs if not is_deko(p)]
        if not echte:
            print(f"[{i}/{len(tasks)}] {t['title']}: nur Deko-Bilder, uebersprungen"); continue
        try:
            vorschlag = call_api(echte)
            vorschlag["_task_id"] = t["id"]
            vorschlag["_title"] = t["title"]
            vorschlag["_slug"] = folder
            vorschlag["_images"] = [os.path.relpath(p, OUT) for p in echte]
            json.dump(vorschlag, open(os.path.join(OUT,f"{folder}.json"),"w"),
                      ensure_ascii=False, indent=2)
            results.append(vorschlag)
            np = len(vorschlag.get("parts",[]))
            tab = " [TABELLE!]" if vorschlag.get("braucht_tabellentyp") else ""
            print(f"[{i}/{len(tasks)}] {t['title']}: {np} parts, "
                  f"needs_image={vorschlag.get('needs_image')}{tab}")
        except Exception as e:
            print(f"[{i}/{len(tasks)}] {t['title']}: FEHLER {e}")
    build_html(results)
    print(f"\n=== FERTIG: {len(results)} Vorschlaege ===")
    print(f"Zum Pruefen: {OUT}/vorschlaege.html")
    tab = sum(1 for r in results if r.get("braucht_tabellentyp"))
    ni = sum(1 for r in results if r.get("needs_image"))
    zeich = sum(1 for r in results if r.get("ist_zeichenaufgabe"))
    unsi = sum(1 for r in results if r.get("unsicher"))
    print(f"  needs_image=true: {ni}")
    print(f"  braucht Tabellentyp: {tab}")
    print(f"  Zeichenaufgaben (LSA-ungeeignet): {zeich}")
    print(f"  mit Unsicherheit markiert: {unsi}")

def build_html(results):
    css = '''body{font-family:system-ui;max-width:1300px;margin:0 auto;padding:20px;background:#faf9f6}
    section{border:1px solid #ddd;border-radius:8px;padding:16px;margin:16px 0;background:#fff}
    h2{margin:0 0 4px;font-size:18px}.meta{color:#666;font-size:13px;margin-bottom:10px}
    .cols{display:flex;gap:20px}.imgs{flex:1;display:flex;flex-direction:column;gap:8px}
    img{max-width:100%;border:1px solid #ccc;background:#fff}
    .json{flex:1;background:#1e1e1e;color:#d4d4d4;padding:12px;border-radius:6px;
    font-family:monospace;font-size:12px;white-space:pre-wrap;overflow-x:auto}
    .tab{color:#b00;font-weight:bold}.ni{color:#080}'''
    blocks=[]
    for r in results:
        imgs = "".join(f'<img src="{html.escape(p)}">' for p in r.get("_images",[]))
        flags = []
        if r.get("ist_zeichenaufgabe"): flags.append('<span class="tab">ZEICHENAUFGABE — fuer LSA ungeeignet</span>')
        if r.get("braucht_tabellentyp"): flags.append('<span class="tab">TABELLENTYP NOETIG</span>')
        if r.get("needs_image"): flags.append('<span class="ni">needs_image</span>')
        if r.get("unsicher"): flags.append(f'<span style="color:#a60">unsicher: {html.escape(str(r["unsicher"]))}</span>')
        pretty = json.dumps({k:v for k,v in r.items() if not k.startswith("_")},
                            ensure_ascii=False, indent=2)
        blocks.append(f'''<section>
          <h2>{html.escape(r.get("_title",""))}</h2>
          <div class="meta">slug: {html.escape(r.get("_slug",""))} · input_type: {html.escape(r.get("input_type",""))} · {" · ".join(flags)}</div>
          <div class="cols"><div class="imgs">{imgs}</div>
          <div class="json">{html.escape(pretty)}</div></div></section>''')
    open(os.path.join(OUT,"vorschlaege.html"),"w").write(
        f"<!DOCTYPE html><html><head><meta charset='utf-8'><style>{css}</style></head>"
        f"<body><h1>OCR-Vorschlaege — {len(results)} Aufgaben</h1>"
        f"<p>Bild links, extrahierter Vorschlag rechts. Pruefen, dann im Autoring-Tool eintragen. "
        f"NICHTS wurde in die DB geschrieben.</p>{''.join(blocks)}</body></html>")

if __name__ == "__main__":
    main()
