#!/usr/bin/env python3
"""C10 Voll-Audit — erzeugt docs/content/AUDIT-2026-07.md aus den CSVs + Quellen."""
import csv, json, os, sys, collections
sys.path.insert(0, "scripts")
from c10_stoffanker import T
from c10_sicht import S
from c10_sicht2 import S2

SICHT = {**S, **S2}
db = json.load(open("data/c10_db_complete.json"))
http = json.load(open("data/c10_http_report.json"))
items = list(csv.DictReader(open("data/audit-2026-07.csv")))
bilder = list(csv.DictReader(open("data/audit-bilder.csv")))


def c(pred):
    return sum(1 for r in items if pred(r))


# --- Bestand ---
n = len(items)
status_c = collections.Counter(r["status"] for r in db)
it_c = collections.Counter((r["input_type"] or "NULL") for r in db)
has_correct = sum(1 for r in db if r["has_correct"])
has_beleg = sum(1 for r in db if r["has_beleg"])
has_sol_text = sum(1 for r in db if r["has_solution_text"])
has_sol_row = sum(1 for r in db if r["has_solution_row"])
no_row = sum(1 for r in db if not r["has_solution_row"])

# --- Stoffanker ---
konf_c = collections.Counter(v[1] for v in T.values())
grade_sicher = collections.Counter(v[0] for v in T.values() if v[1] == "sicher")
vorbelegt = [r for r in items if r["vorbelegt"] == "ja"]
grade_vorbelegt = collections.Counter(int(r["stoffanker_vorschlag"]) for r in vorbelegt)
sicher_ready = [r for r in items if r["konfidenz"] == "sicher" and r["status"] == "ready"]

# --- Assets ---
asset_c = collections.Counter(r["asset_status"] for r in items)
http_ok = sum(1 for b in bilder if b["http_status"] == "200")
sicht_c = collections.Counter(b["sichtbefund"] for b in bilder)
crop_imgs = sum(1 for b in bilder if b["sichtbefund"] == "text_eingebrannt")
crop_items = c(lambda r: r["crop_noetig"] == "ja")
partB = [r for r in items if r["asset_status"] == "tote_pfade_nachladbar"]
partC = [r for r in items if r["asset_status"] == "text_verweis"]
broken = [r for r in items if r["asset_status"] == "bild_ohne_grafik"]
bild_da = [r for r in items if r["asset_status"] == "bild_vorhanden"]
lb_B = collections.Counter(r["ohne_bild_loesbar"] for r in partB)
lb_C = collections.Counter(r["ohne_bild_loesbar"] for r in partC)
lb_broken = collections.Counter(r["ohne_bild_loesbar"] for r in broken)

# --- Pflege-Plan Buckets (ueberlappend: ein Item kann in mehreren stehen) ---
P5 = [r for r in items if (r["loesung_da"] == "nein" or r["input_type"] == "")]
P4 = [r for r in items if r["asset_status"] in ("bild_ohne_grafik", "tote_pfade_nachladbar", "text_verweis")]
P4_repair = [r for r in P4 if r["ohne_bild_loesbar"] in ("nein", "vielleicht")]
P4_optional = [r for r in P4 if r["ohne_bild_loesbar"] == "ja_sicher"]
P2 = [r for r in items if r["crop_noetig"] == "ja"]
P3 = [r for r in items if r["asset_status"] == "bild_vorhanden"]
# P1 = reine Schnell-Gewinne: vorbelegt, vollstaendig, ohne Bild-Baustelle
P1 = [r for r in items if r["vorbelegt"] == "ja" and r["loesung_da"] == "ja"
      and r["input_type"] != "" and r["asset_status"] == "kein_bild"]


def titles(rows, k=8):
    ts = [r["title"] for r in rows]
    s = ", ".join(ts[:k])
    return s + (f" … (+{len(ts)-k})" if len(ts) > k else "")


L = []
w = L.append
w("# Content-Voll-Audit — Aufgabenbestand (Stand 2026-07)")
w("")
w("> Read-only-Audit des gesamten Aufgabenbestands (299 Items) mit kontrollierter,")
w("> eng begrenzter Stoffanker-Vorbelegung. Ausser dem einen Schreibschritt in Teil 4")
w("> (nur Spalte `curriculum_grade`) wurde ausschliesslich gelesen (SELECT).")
w("")
w("## Methodik")
w("")
w("- **Aufgabentext**: `tasks.question` + `tasks.parts` (`question_payload` ist bei 286/299 leer).")
w("- **Loesung/Beleg**: `task_solutions` (nur gelesen): `correct_answers`, `solution`, `beleg`.")
w("- **Lizenz**: massgeblich ist der pro Item eingebettete Hinweis (Wort *Grafik* ⇒ Grafik gedeckt),")
w("  Regel aus `docs/LIZENZ-IQB.md`. Das Feld `lizenz_status` ist fuer Grafiken unzuverlaessig und")
w("  wurde bewusst NICHT verwendet.")
w("- **Stoffanker (`curriculum_grade`)**: pro Item handklassifiziert gegen die NRW-Progression")
w("  (nicht mit AFB verwechselt).")
w(f"- **Bild-Sichtpruefung**: alle {len(http)} vorhandenen Bilddateien (URL-Assets) wurden")
w("  heruntergeladen und einzeln **angesehen** und klassifiziert (sauber / text_eingebrannt / unbrauchbar).")
w("")
w("## 1. Bestand in Zahlen")
w("")
w(f"- **Items gesamt:** {n}  —  Status: " + ", ".join(f"{k}={v}" for k, v in sorted(status_c.items())))
w("- **input_type:** " + ", ".join(f"{k}={v}" for k, v in sorted(it_c.items(), key=lambda x: -x[1])))
w(f"- **Loesungsschluessel (`correct_answers`) vorhanden:** {has_correct}/{n}  "
  f"→ **{n-has_correct} ohne Loesungsschluessel**")
w(f"- **Beleg (`beleg`) vorhanden:** {has_beleg}/{n}  → {n-has_beleg} ohne Beleg")
w(f"- **Ausformulierte Musterloesung (`solution`-Text):** nur {has_sol_text}/{n} "
  f"(faktisch die {status_c.get('ready',0)} ready-Items)")
w(f"- **Kein `task_solutions`-Datensatz ueberhaupt:** {no_row} Items")
w("")
w("## 2. Stoffanker (Teil 1)")
w("")
w("Konfidenz-Verteilung ueber alle 299 Items:")
w("")
w(f"- **sicher:** {konf_c['sicher']}")
w(f"- **unsicher:** {konf_c['unsicher']} (beide Kandidaten je Item in `data/audit-2026-07.csv` / Stoffanker-Quelle dokumentiert)")
w(f"- **nicht bestimmbar:** {konf_c['nicht_bestimmbar']} (bleibt NULL — nicht geraten)")
w("")
w("Klassen-Verteilung der **sicheren** Anker:")
w("")
w("| Klasse | sichere Items |")
w("|---|---|")
for g in sorted(grade_sicher):
    w(f"| {g} | {grade_sicher[g]} |")
w("")
w("## 3. Teil 4 — Stoffanker-Vorbelegung (der EINE Schreibschritt)")
w("")
w(f"- **Gesetzt (`curriculum_grade`):** {len(vorbelegt)} Items — Bedingung: Konfidenz=sicher"
  " UND `status='draft'` UND `curriculum_grade IS NULL`.")
w("- Verteilung der gesetzten Anker: " + ", ".join(f"Kl.{g}={grade_vorbelegt[g]}" for g in sorted(grade_vorbelegt)) + ".")
w(f"- **Bewusst offen gelassen (NULL):** {konf_c['unsicher']} unsicher + {konf_c['nicht_bestimmbar']} nicht bestimmbar"
  f" + {len(sicher_ready)} sichere aber `ready` (ready wird nie angefasst).")
w("- Ruecknahme jederzeit ueber `data/stoffanker-revert.sql` (setzt exakt diese IDs auf NULL).")
w("- **Sinn:** Lena *bestaetigt* die Anker im Freigabe-Schritt — die Freigabe bleibt der menschliche Akt.")
w("")
w("## 4. Asset-Audit (Teil 2)")
w("")
w("Verteilung der Items nach Bild-Situation:")
w("")
for k, v in asset_c.most_common():
    w(f"- `{k}`: {v}")
w("")
w("**A) Vorhandene Bilder (URL-Assets):** "
  f"{len(bild_da)+len(broken)} Items / {len(http)} Dateien. "
  f"HTTP 200 & Bild: {http_ok}/{len(http)}.")
w("")
w("Sichtbefund je Bild:")
for k in ("sauber", "text_eingebrannt", "unbrauchbar"):
    w(f"- **{k}:** {sicht_c.get(k,0)}")
w("")
w(f"- **Crop noetig** (Aufgabentext ins Bild eingebrannt): {crop_imgs} Bilder in {crop_items} Items.")
w(f"- **Render verloren / keine echte Grafik** (alle Bilder eines Items unbrauchbar): {len(broken)} Items.")
w(f"  Davon ohne Bild loesbar: " + ", ".join(f"{k}={v}" for k, v in lb_broken.items()) + ".")
w("  Kritisch (lösungsrelevante Grafik im Render verloren): "
  + titles([r for r in broken if r["ohne_bild_loesbar"] == "nein"]) + ".")
w("")
w(f"**B) Tote Pfade** (`data/r01_render/…`): {len(partB)} Items — Lizenzhinweis deckt in **allen** Faellen")
w("die Grafik (Wort *Grafik*), Quelle liegt lokal in `data/` ⇒ **nachladbar**.")
w("Ohne Bild loesbar (Vorschlag fuers menschliche Urteil): "
  + ", ".join(f"{k}={v}" for k, v in lb_B.items()) + ".")
w("")
w(f"**C) Text-Bild-Verweise ohne Asset:** {len(partC)} Items — Text erwaehnt eine Abbildung,")
w("kein echtes Bild vorhanden. Ohne Bild loesbar: "
  + ", ".join(f"{k}={v}" for k, v in lb_C.items()) + ".")
w("")
w(f"**D) Fehlende Alt-Texte:** **alle** {len(http)} Bilder haben `alt=''`. Fuer die {len(bild_da)} Items")
w("mit echter, vorhandener Grafik liefert `data/audit-2026-07.csv` einen Alt-Text-Vorschlag")
w("(aus der Sichtpruefung) — nur Vorschlag.")
w("")
w("## 5. Top-Befunde")
w("")
w(f"1. **Loesungsschluessel-Luecke:** {n-has_correct} von {n} Items haben keinen `correct_answers`-Eintrag"
  " — der groesste Vollstaendigkeits-Mangel.")
w(f"2. **Renderverlust bei EMF-Grafiken:** {len(broken)} URL-Items zeigen statt der Grafik nur Text/Antwortkasten"
  " oder MC-Optionen; bei "
  + str(len([r for r in broken if r['ohne_bild_loesbar']=='nein']))
  + " davon ist die verlorene Grafik loesungsrelevant.")
w("3. **MC-Optionen als Bild:** Viele `…_imageN`-Renders sind gar keine Grafik, sondern die"
  " Antwortoptionen/Teilaufgaben als Pixelbild — gehoeren strukturiert in `parts`/`options`.")
w(f"4. **Crop-Bedarf:** {crop_items} Items mit vorhandener Grafik haben Aufgabentext eingebrannt und brauchen einen Zuschnitt.")
w(f"5. **input_type fehlt** bei {it_c.get('NULL',0)} Items.")
w(f"6. **Nachladbare Grafiken:** alle {len(partB)} toten Pfade sind lizenzrechtlich gedeckt und lokal vorhanden.")
w("")
w("## 6. Pflege-Plan (Prioritaeten)")
w("")
w("Die Kategorien **ueberlappen** (ein Item kann mehrere Baustellen haben); die Zahlen sind der")
w("jeweilige Arbeitsumfang. Je Item nennt `data/audit-2026-07.csv` (`empfohlene_aktion`) die dominante Aktion.")
w("")
w(f"- **P1 — nur Anker bestaetigen** ({len(P1)} Items): vollstaendig, ohne Bild-Baustelle, Anker vorbelegt —")
w("  Lena muss nur bestaetigen. Schnellster Hebel.")
w(f"- **P2 — Crop noetig** ({len(P2)} Items): Grafik vorhanden, Aufgabentext eingebrannt → zuschneiden.")
w(f"- **P3 — Alt-Text** ({len(P3)} Items): jede vorhandene echte Grafik hat `alt=''`; Vorschlag liegt im CSV.")
w(f"- **P4 — Bild-Entscheidung** ({len(P4)} Items): referenziertes Bild fehlt/ist unbrauchbar.")
w(f"  Davon **{len(P4_repair)} reparieren** (nachladen/neu zeichnen — Grafik loesungsrelevant) und")
w(f"  **{len(P4_optional)} optional** (Item ist auch ohne Bild loesbar, Bild ggf. entfernen).")
w(f"- **P5 — unvollstaendig** ({len(P5)} Items): Loesungsschluessel oder `input_type` fehlt.")
w("")
w("## 7. Artefakte")
w("")
w("- `data/audit-2026-07.csv` — pro Item: Anker, Konfidenz, Vorbelegung, Dauer, Asset-Status, Crop,")
w("  Ohne-Bild-Loesbarkeit, Alt-Text-Vorschlag, Loesung/Beleg, empfohlene Aktion.")
w("- `data/audit-bilder.csv` — pro Bild: URL, HTTP-Status, Sichtbefund, Crop-Beschreibung.")
w("- `data/stoffanker-revert.sql` — Rueckabwicklung der Vorbelegung.")
w("- `data/stoffanker-apply.sql` — die eine Teil-4-Transaktion (zur Nachvollziehbarkeit).")
w("")

os.makedirs("docs/content", exist_ok=True)
open("docs/content/AUDIT-2026-07.md", "w").write("\n".join(L))
print("docs/content/AUDIT-2026-07.md geschrieben:", len(L), "Zeilen")
