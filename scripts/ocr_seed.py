#!/usr/bin/env python3
"""
Seedet die OCR-Vorschlaege als status='draft' in tasks.
- kind-Mapping: numeric/free_text -> short_input, mc -> mc
- ueberspringt Zeichenaufgaben (ist_zeichenaufgabe)
- ueberspringt Aufgaben, die schon parts haben (nur parts-lose befuellen)
- KEINE Assets (kommen im Autoring-Tool)
- Loesungsvorschlaege -> Begleitdatei loesungen.csv
- Backup + Revert-SQL vorher
- DRY-RUN per default; echtes Schreiben nur mit Arg 'apply'

Aufruf:
  python3 scripts/ocr_seed.py         # Dry-Run (zeigt nur)
  python3 scripts/ocr_seed.py apply   # schreibt wirklich
"""
import os, sys, json, glob, subprocess, csv, datetime

APPLY = len(sys.argv) > 1 and sys.argv[1] == "apply"
OCR = "data/ocr-vorschlaege"
BACKUP = f"data/seed-backup-{datetime.date.today().strftime('%Y%m%d')}"

def dburl():
    for line in open(".env"):
        if line.startswith("DATABASE_URL="):
            return line.split("=",1)[1].strip().strip('"')

def psql(sql, want_output=False):
    r = subprocess.run(["psql", dburl(), "-t", "-A", "-c", sql],
                       capture_output=True, text=True)
    if r.returncode != 0:
        print("PSQL-FEHLER:", r.stderr); sys.exit(1)
    return r.stdout.strip()

# kind-Mapping: DB kennt nur mc + short_input
KIND_MAP = {"mc":"mc", "short_input":"short_input",
            "numeric":"short_input", "free_text":"short_input"}

def build_part(p, nr):
    kind = KIND_MAP.get(p.get("kind","short_input"), "short_input")
    part = {
        "nr": nr,
        "afb": None,                 # Lena traegt AFB beim Freigeben nach
        "kind": kind,
        "unit": p.get("unit"),
        "prompt": p.get("prompt",""),
        "competency_content": None,
        "competency_process": None,
    }
    if kind == "mc" and p.get("options"):
        part["options"] = p["options"]
    return part

def main():
    files = sorted(glob.glob(f"{OCR}/*.json"))
    print(f"{len(files)} Vorschlags-Dateien gefunden\n")

    # Welche task_ids haben schon parts? (nicht ueberschreiben)
    rows = psql("select id from tasks where parts is not null and jsonb_array_length(parts)>0")
    hat_parts = set(rows.splitlines())

    plan = []       # (task_id, title, question, parts_json, input_type, needs_image)
    loesungen = []  # fuer Begleitdatei
    skip_zeichen = skip_hasparts = skip_notask = 0

    for f in files:
        v = json.load(open(f))
        tid = v.get("_task_id")
        title = v.get("_title","")
        if not tid:
            skip_notask += 1; continue
        if v.get("ist_zeichenaufgabe"):
            skip_zeichen += 1; continue
        if tid in hat_parts:
            skip_hasparts += 1; continue

        vparts = v.get("parts",[])
        stamm = v.get("stamm","")
        needs_image = bool(v.get("needs_image"))

        # WEICHE: >=2 parts -> MULTI_PART mit parts. Sonst einfacher Typ, parts=[].
        if len(vparts) >= 2:
            parts = [build_part(p, i+1) for i,p in enumerate(vparts)]
            input_type = "MULTI_PART"
            # Constraint verlangt question <> '' bei MULTI_PART. Bei leerem Stamm
            # Titel als Platzhalter (Lena ergaenzt den echten Stamm im Tool).
            question = stamm.strip() if stamm.strip() else f"[Stamm ergaenzen] {title}"
            est_dur = 60 * len(parts)   # grobes Default-Zeitbudget, Lena justiert
        else:
            # Ein-Part (oder null): einfacher Typ, KEINE parts (Constraint verlangt [])
            parts = []
            est_dur = None
            # Typ aus Claudes Vorschlag; bei einem Part dessen kind mappen
            if vparts:
                p0 = vparts[0]
                k = p0.get("kind","short_input")
                type_from_kind = {"mc":"MC","numeric":"NUMERIC",
                                  "short_input":"SHORT_TEXT","free_text":"FREE_TEXT"}
                input_type = v.get("input_type") or type_from_kind.get(k,"SHORT_TEXT")
                # Frage = Stamm + Part-Prompt (da keine parts, muss alles in question)
                pr = p0.get("prompt","")
                question = (stamm + "\n\n" + pr).strip() if stamm and pr != stamm else (stamm or pr)
            else:
                input_type = v.get("input_type")
                question = stamm

        plan.append({
            "id": tid, "title": title, "question": question,
            "parts": parts, "input_type": input_type, "needs_image": needs_image,
            "est_dur": est_dur,
            "tabelle": bool(v.get("braucht_tabellentyp")),
            "unsicher": v.get("unsicher"),
        })
        # Loesungen sammeln
        for i,p in enumerate(vparts):
            if p.get("loesung_vorschlag"):
                loesungen.append({
                    "task_id": tid, "title": title, "part_nr": i+1,
                    "kind": p.get("kind"), "prompt": p.get("prompt",""),
                    "loesung": p.get("loesung_vorschlag",""),
                    "mehrere_moeglich": p.get("mehrere_loesungen_moeglich", False),
                })

    print("=== PLAN ===")
    print(f"  zu seedende Entwuerfe:        {len(plan)}")
    print(f"  davon MULTI_PART (>=2 parts): {sum(1 for p in plan if p['input_type']=='MULTI_PART')}")
    print(f"  davon einfacher Typ (parts=[]): {sum(1 for p in plan if p['input_type']!='MULTI_PART')}")
    print(f"  davon needs_image=true:       {sum(1 for p in plan if p['needs_image'])}")
    print(f"  davon Tabellenfaelle:         {sum(1 for p in plan if p['tabelle'])}")
    print(f"  uebersprungen (Zeichenaufg.): {skip_zeichen}")
    print(f"  uebersprungen (hat schon parts): {skip_hasparts}")
    print(f"  uebersprungen (kein task_id): {skip_notask}")
    print(f"  Loesungsvorschlaege gesammelt: {len(loesungen)}")

    # Begleitdatei Loesungen (immer schreiben, auch im Dry-Run)
    os.makedirs(OCR, exist_ok=True)
    with open(f"{OCR}/loesungen.csv","w",newline='') as fh:
        w = csv.DictWriter(fh, fieldnames=["task_id","title","part_nr","kind","prompt","loesung","mehrere_moeglich"])
        w.writeheader(); w.writerows(loesungen)
    print(f"\nLoesungen geschrieben: {OCR}/loesungen.csv")

    if not APPLY:
        print("\n=== DRY-RUN — nichts in die DB geschrieben. ===")
        print("Beispiel (erste 2 Entwuerfe):")
        for p in plan[:2]:
            print(f"\n  {p['title']} (input_type={p['input_type']}, needs_image={p['needs_image']}):")
            print(f"    question: {p['question'][:80]}...")
            print(f"    parts: {json.dumps(p['parts'], ensure_ascii=False)[:200]}...")
        print("\nZum echten Schreiben: python3 scripts/ocr_seed.py apply")
        return

    # === APPLY: Backup + Schreiben ===
    os.makedirs(BACKUP, exist_ok=True)
    ids = "','".join(p["id"] for p in plan)
    # Backup der betroffenen Zeilen
    subprocess.run(["psql", dburl(), "-c",
        f"\\copy (select id,title,question,parts,input_type,needs_image,est_duration_sec,status "
        f"from tasks where id in ('{ids}')) to '{BACKUP}/vorher.csv' with csv header"])
    # Revert-SQL: alte Werte zuruecksetzen
    with open(f"{BACKUP}/revert.sql","w") as fh:
        for p in plan:
            fh.write(f"-- {p['title']}\n")
            fh.write(f"update tasks set parts='[]'::jsonb, question=null, "
                     f"input_type=null, needs_image=null, est_duration_sec=null "
                     f"where id='{p['id']}';\n")
    print(f"Backup: {BACKUP}/vorher.csv + revert.sql")

    # Schreiben (einzeln, mit Parametern ueber psql -v waere unsicher bei JSON;
    # daher via temporaerer SQL-Datei mit dollar-quoting)
    written = 0
    for p in plan:
        parts_json = json.dumps(p["parts"], ensure_ascii=False).replace("'", "''")
        q = (p["question"] or "").replace("'", "''")
        it = f"'{p['input_type']}'" if p["input_type"] else "null"
        ni = "true" if p["needs_image"] else "false"
        ed = str(p["est_dur"]) if p.get("est_dur") else "est_duration_sec"  # bei einfachem Typ unveraendert lassen
        sql = (f"update tasks set "
               f"question='{q}', "
               f"parts='{parts_json}'::jsonb, "
               f"input_type={it}, "
               f"needs_image={ni}, "
               f"est_duration_sec={ed}, "
               f"status='draft' "
               f"where id='{p['id']}' and status='draft';")
        r = subprocess.run(["psql", dburl(), "-c", sql], capture_output=True, text=True)
        if r.returncode == 0 and "UPDATE 1" in r.stdout:
            written += 1
        else:
            print(f"  FEHLER bei {p['title']}: {(r.stderr or r.stdout).strip()[:120]}")
    print(f"\n=== FERTIG: {written}/{len(plan)} Entwuerfe geseedet (status=draft) ===")
    print(f"Revert: psql \"$DATABASE_URL\" -f {BACKUP}/revert.sql")

if __name__ == "__main__":
    main()
