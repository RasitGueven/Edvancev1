"""R01 — Diff: Altbestand gegen Neuextraktion, ueber alle 299 Items.

Die Kalibrierung hat gezeigt, WO der Altbestand kaputt ist: nicht bei den
Loesungen, sondern bei den STAEMMEN. "2½ Stunden" wurde zu "2 Stunden" — die
Loesung 150 stand die ganze Zeit richtig daneben. Wer nur die Loesungen
vergleicht, sieht diesen Bug nie.

WARUM der Altbestand Staemme zerstoert (der Mechanismus, an zeitangabe belegt):
Der alte Stamm ist der Textinhalt der EMF-Zeichenlaeufe. Dieser Kanal kann
Sonderzeichen nicht dekodieren — er liefert fuer "2½ Stunden" die Zeichen
"2    Stunden". Das ½ steht im Zeichenvorrat der Quelle also gar nicht; die
Neuextraktion holt es aus dem gerenderten Bild (Vision). Ein Check "Zeichen
steht im Zeichenvorrat" kann diese Klasse deshalb NIE finden — der Zeichenvorrat
ist genau der verlustbehaftete Kanal. Wir vergleichen darum alten Stamm gegen
neuen Stamm, nicht gegen den Vorrat.

Fehlerklassen im ALTBESTAND:
  S1  Verlorene bedeutungstragende Zeichen (½, ², ³, ₁, ·, −, ...).
  S2  Alte Loesung passt nicht zum alten Stamm, zum neuen aber sehr wohl.
  S3  MC-Loesung steht nicht unter den Optionen.
  S4  Verschraenkte Textlaeufe ("mmiitt wweeißißeemm").

Fehlerklassen in der NEUEXTRAKTION (von den Gates NICHT erfasst):
  N1  MC-Schluessel ist keine Options-ID, sondern eine Kodierregel
      ("Nein UND Begruendung...") oder ein Bildverweis ("[pic]").
  N2  Optionen ohne Label.
  N3  SHORT_INPUT-Schluessel ist eine Kodierregel statt einer Antwort
      ("Angabe einer Groesse aus dem Intervall [30 m; 60 m]").

Vier Toepfe: identisch · neu besser · neu schlechter · beide defekt
Ausgabe: data/r01_diff.md
"""
import json
import re
import sys
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
ALT = ROOT / "data/vera8_komplett_enriched.json"
NEU = ROOT / "data/vera8_v2.json"
VISION = ROOT / "data/r01_vision"
OUT = ROOT / "data/r01_diff.md"

# Die 14 Items, die bereits im LSA-Pool stehen (scripts/import-lsa-items.ts).
IMPORTIERT = {
    "1a518b4b": ("Bestimme x", ["20"], None),
    "a880daf0": ("Das ist gerundet", ["5,1"], None),
    "4d8811de": ("Einfache Gleichung", ["2"], None),
    "17f4df4b": ("Gleichung lösen 1", ["-10"], None),
    "7ab3cfad": ("Kugeln ziehen", ["3"], None),
    "82e6559f": ("Papier", ["22"], "mm"),
    "b3c8ade1": ("Pflaumen", ["0,95"], "€"),
    "e9a54ab8": ("Temperaturdifferenz", ["19"], "°C"),
    "9c72e62c": ("20 Prozent", ["16"], "m"),
    "37337edb": ("Croissant", ["1,25"], "€"),
    "f464ecf3": ("Ecken an Pyramiden", ["5"], "Ecken"),
    "ad736c2a": ("Hälfte", ["500000", "500 000"], None),
    "df59c706": ("Lohnerhöhung", ["10"], "%"),
    "a833826c": ("Zwanzig Prozent", ["30"], "€"),
}

# Bedeutungstragende Zeichen: ihr Verlust aendert die AUFGABE, nicht nur das Layout.
MATH = set("½¼¾⅓⅔⅕⅖⅗⅘²³¹⁰⁴⁵⁶⁷⁸⁹₀₁₂₃₄₅₆₇₈₉ₙ√·÷±≤≥°€")
# Layoutzeichen: Verlust ist haesslich, aber nicht sinnentstellend.
LAYOUT = set("_☐…")

# Zeichen, die dasselbe BEDEUTEN und sich nur im Codepoint unterscheiden. Ohne
# diese Normalisierung meldet der Diff einen "Verlust", wo bloss ⋅ zu · wurde.
AEQUIVALENT = str.maketrans({
    "⋅": "·", "∙": "·", "•": "·", "×": "·", "*": "·",
    "−": "-", "–": "-", "—": "-", "‐": "-", "₋": "-",
    " ": " ",
})

DBL = re.compile(r"([A-Za-zÄÖÜäöüß])\1")
# Kodierregel statt Antwort — die Auswertung beschreibt, WAS zaehlt, statt es zu nennen.
# ACHTUNG: UND/ODER sind case-SENSITIVE. Der Konnektor der Auswertung ist gross
# ("Nein UND Begruendung"); ein kleines "und" ist das normale deutsche Wort und
# steht harmlos in jedem zweiten Antwortsatz.
KONNEKTOR = re.compile(r"\bUND\b|\bODER\b")
KODIERREGEL_I = re.compile(
    r"Begründung|Lösungsweg|Anm\.?:|angekreuzt|Kästchen"
    r"|richtig gesetzt|\[pic\]|Intervall|Angabe einer|Antworten aus|erkennen"
    r"|Verweis|Nachweis|Richtige[rs]?\s+(?:Term|Lösung|Ansatz|Wert|Angabe)",
    re.I)


def kodierregel(s):
    """Ist der Schluessel etwas anderes als ein vergleichbarer Wert?

    Der Diff prueft das unabhaengig von ground_all nach — er soll der Pipeline
    nicht glauben, sondern sie kontrollieren.
    """
    if KONNEKTOR.search(s) or KODIERREGEL_I.search(s):
        return True
    # Ein Schluessel ist ein Wert, kein Satz.
    if len(re.findall(r"[A-Za-zÄÖÜäöüß]{2,}", s)) >= 3:
        return True
    # Mehrere Gleichungen = mehrere Teilantworten in einem String.
    return s.count("=") > 1
# Verlangt eine menschliche Bewertung — kein Matcher der Welt repariert das.
COACH_PFLICHT = re.compile(
    r"Begründung|Lösungsweg|Nachweis|Verweis|richtig gesetzt|\[pic\]|angekreuzt"
    r"|erkennen|Richtige[rs]?\s+(?:Term|Lösung|Ansatz|Wert|Angabe)", re.I)


def norm(s):
    s = unicodedata.normalize("NFC", s or "").translate(AEQUIVALENT)
    return re.sub(r"\s+", " ", s).strip()


def nz(s):
    return re.sub(r"[\s ]+", "", str(s or "")).lower()


# --------------------------------------------------------------------------
# Zugriff auf die beiden Bestaende
# --------------------------------------------------------------------------
def alt_stamm(a):
    return norm(a.get("aufgabe_text") or "")


def alt_ta(a):
    return [t for t in (a.get("loesung_pro_ta") or []) if t.get("loesung")]


def neu_stamm(n):
    teile = [n["stem"]["text"]] + [p.get("prompt") or "" for p in n["parts"]]
    return norm(" ".join(t for t in teile if t))


def hat_vision(n):
    return (VISION / f"{n['slug']}.json").exists()


def vision_lesung(n):
    f = VISION / f"{n['slug']}.json"
    if not f.exists():
        return None
    return json.loads(f.read_text(encoding="utf-8"))


def nicht_verbaut(n):
    """Vision hat gelesen, der Bau hat es nicht uebernommen.

    Reiner Bau-Verzug: vera8_v2.json ist aelter als diese Vision-Lesungen. Kein
    Extraktionsfehler — ein erneuter Lauf von ground_all.py holt sie herein,
    ohne dass eine einzige Datei neu extrahiert werden muesste.
    """
    if n["parts"]:
        return 0
    v = vision_lesung(n)
    return len(v.get("parts") or []) if v else 0


# --------------------------------------------------------------------------
# Fehlerklassen im ALTBESTAND
# --------------------------------------------------------------------------
def s1_verlorene_zeichen(a, n):
    """Zeichen, die der neue Stamm hat und der alte nicht.

    Ohne Vorrat-Bedingung: der Vorrat ist der verlustbehaftete Kanal.
    """
    astamm, nstamm = alt_stamm(a), neu_stamm(n)
    if not astamm or not nstamm:
        return set(), set()
    fehlt = {c for c in nstamm if c not in astamm}
    return fehlt & MATH, fehlt & LAYOUT


def s3_mc(a, n):
    """MC: steht die alte Loesung unter den (neu rekonstruierten) Optionen?

    Die Optionen werden auf der NEUEN Seite gelesen — im alten Stamm sind
    Optionen, Tabellenzellen und Prosa zu einem |-Brei verschmolzen und nicht
    mehr auseinanderzuhalten.
    """
    treffer = []
    for p in n["parts"]:
        if p["kind"] != "mc" or not p.get("options") or not p.get("correct_answers"):
            continue
        ids = {o["id"]: o.get("label", "") for o in p["options"]}
        ta = next((t for t in alt_ta(a) if t.get("nr") == p["nr"]), None)
        if not ta:
            continue
        al = str(ta["loesung"])
        if nz(al) not in {nz(l) for l in ids.values()}:
            treffer.append((p["nr"], al, list(ids.values()),
                            [ids.get(c, c) for c in p["correct_answers"]]))
    return treffer


def s4_doppelung(a):
    """Verschraenkte Textlaeufe: Woerter mit >=3 Doppelbuchstaben."""
    return [w for w in re.findall(r"[A-Za-zÄÖÜäöüß]{5,}", alt_stamm(a))
            if len(DBL.findall(w)) >= 3]


# --------------------------------------------------------------------------
# Fehlerklassen in der NEUEXTRAKTION (die Gates sehen sie nicht)
# --------------------------------------------------------------------------
def n1_mc_schluessel(n):
    """correct_answers eines MC-Teils sind keine gueltigen Options-IDs."""
    out = []
    for p in n["parts"]:
        if p["kind"] != "mc" or not p.get("options") or not p.get("correct_answers"):
            continue
        ids = {o["id"] for o in p["options"]}
        if not set(p["correct_answers"]) <= ids:
            out.append((p["nr"], p["correct_answers"][:2]))
    return out


def n2_leere_optionen(n):
    return [p["nr"] for p in n["parts"]
            if p["kind"] == "mc" and p.get("options")
            and any(not (o.get("label") or "").strip() for o in p["options"])]


def n3_kodierregel(n):
    """SHORT_INPUT-Schluessel ist eine Kodierregel statt einer Antwort."""
    out = []
    for p in n["parts"]:
        if p["kind"] != "short_input":
            continue
        for ans in p.get("correct_answers") or []:
            if kodierregel(str(ans)) or len(str(ans)) > 45:
                out.append((p["nr"], str(ans)[:70]))
                break
    return out


# --------------------------------------------------------------------------
# Defekt-Praedikate. "Defekt" heisst: Daten kaputt — NICHT "nicht auto-gradebar".
# Ein sauberes FREE_TEXT-Item ist nicht defekt.
# --------------------------------------------------------------------------
def alt_defekt(a, s1m, s3, s4):
    g = []
    if not alt_stamm(a):
        g.append("kein Stamm")
    if not alt_ta(a):
        g.append("keine Loesung")
    if s1m:
        g.append(f"S1 verlorene Zeichen im Stamm: {''.join(sorted(s1m))}")
    if s3:
        g.append(f"S3 MC-Loesung nicht unter den Optionen ({len(s3)} Ta)")
    if s4:
        g.append(f"S4 verschraenkte Textlaeufe ({len(s4)} Woerter)")
    if a.get("_problems"):
        g.append(f"_problems: {len(a['_problems'])}")
    return g


def neu_defekt(n, n1, n2, n3):
    g = []
    if not n["parts"]:
        g.append("keine Teilaufgabe gelesen")
    else:
        if not all(p.get("prompt") for p in n["parts"]):
            g.append("Teilaufgabe ohne Prompt")
        if not all(p.get("correct_answers") for p in n["parts"]):
            g.append("Teilaufgabe ohne Loesung")
    g += [f for f in (n.get("_flags_blockierend") or [])
          if "keine Teilaufgabe gelesen" not in f]
    if n1:
        g.append(f"N1 MC-Schluessel ist keine Options-ID (Ta {[x[0] for x in n1]})")
    if n2:
        g.append(f"N2 Optionen ohne Label (Ta {n2})")
    if n3:
        g.append(f"N3 Schluessel ist Kodierregel (Ta {[x[0] for x in n3]})")
    return g


def pool_faehig(n, n1, n2, n3):
    """Auto-gradebar MIT dem gespeicherten Schluessel — was LSA heute kann.

    Strenger als das Pipeline-Feld auto_gradebar: das prueft nur, DASS ein
    correct_answers da ist, nicht, ob es eine benutzbare Antwort IST.
    """
    if not n["parts"]:
        return False
    if not all(p["kind"] in ("mc", "short_input") and p.get("correct_answers")
               and (p["kind"] != "mc" or p.get("options")) for p in n["parts"]):
        return False
    return not (n1 or n2 or n3)


def main():
    alt = json.loads(ALT.read_text(encoding="utf-8"))
    neu = json.loads(NEU.read_text(encoding="utf-8"))
    by_id = {n["id"]: n for n in neu if n.get("id")}

    toepfe = defaultdict(list)
    S1, S3, S4, N1, N2, N3 = [], [], [], [], [], []
    bestaetigt, unsauber, widerspruch, leer = [], [], [], []
    fehlend, pool = [], []
    vergleichbar = 0

    for a in alt:
        n = by_id.get(a["id"])
        if not n:
            fehlend.append(a["titel"])
            continue

        s1m, _s1l = s1_verlorene_zeichen(a, n)
        s3, s4 = s3_mc(a, n), s4_doppelung(a)
        n1, n2, n3 = n1_mc_schluessel(n), n2_leere_optionen(n), n3_kodierregel(n)

        if alt_stamm(a) and neu_stamm(n):
            vergleichbar += 1
        if s1m:
            S1.append((a["titel"], s1m, alt_stamm(a), neu_stamm(n),
                       [t["loesung"] for t in alt_ta(a)]))
        S3 += [(a["titel"], nr, al, lab, kor) for nr, al, lab, kor in s3]
        if s4:
            S4.append((a["titel"], s4[:4]))
        N1 += [(a["titel"], nr, ca) for nr, ca in n1]
        N2 += [(a["titel"], nr) for nr in n2]
        N3 += [(a["titel"], nr, ans) for nr, ans in n3]

        ad = alt_defekt(a, s1m, s3, s4)
        nd = neu_defekt(n, n1, n2, n3)
        e = {"titel": a["titel"], "slug": n["slug"], "alt": ad, "neu": nd,
             "alt_status": a.get("status"), "vision": hat_vision(n)}
        if ad and nd:
            toepfe["beide_defekt"].append(e)
        elif ad:
            toepfe["neu_besser"].append(e)
        elif nd:
            toepfe["neu_schlechter"].append(e)
        else:
            toepfe["identisch"].append(e)

        if pool_faehig(n, n1, n2, n3) and n["vollstaendig"]:
            pool.append(n)

        pref = a["id"][:8]
        if pref in IMPORTIERT:
            titel, answers, unit = IMPORTIERT[pref]
            nl = [x for p in n["parts"] for x in (p.get("correct_answers") or [])]
            nu = [p.get("unit") for p in n["parts"] if p.get("unit")]

            if not n["parts"]:
                leer.append((titel, n["slug"],
                             "keine Vision-Lesung vorhanden" if not hat_vision(n)
                             else "Vision-Lesung vorhanden, aber ohne Teilaufgabe"))
            else:
                # Exakt gleich? Oder steht der importierte Wert im neuen Schluessel
                # drin, nur mit Kodiertext drumherum ("22 (ODER ca. 22)")?
                exakt = bool({nz(x) for x in nl} & {nz(x) for x in answers})
                drin = any(nz(w) in nz(x) for x in nl for w in answers)
                e_ok = (not unit) or any(nz(unit) == nz(u) for u in nu)
                if exakt and e_ok:
                    bestaetigt.append((titel, n["slug"]))
                elif drin and e_ok:
                    unsauber.append((titel, n["slug"], answers, nl))
                else:
                    ab = [f"Loesung: importiert {answers} · neu {nl or '—'}"]
                    if not e_ok:
                        ab = [f"Einheit: importiert {unit!r} · neu {nu or '—'}"]
                    widerspruch.append((titel, n["slug"], ab))

    ohne_vision = [n for n in neu if not hat_vision(n)]
    ohne_parts = [n for n in neu if not n["parts"]]
    verzug = sorted(((n["titel"], nicht_verbaut(n)) for n in neu
                     if nicht_verbaut(n)), key=lambda x: x[0])
    typ = Counter(n["input_type"] for n in pool)
    pipeline_pool = [n for n in neu if n.get("lsa_pool_kandidat")]
    raus = [n for n in pipeline_pool if n["id"] not in {p["id"] for p in pool}]
    verloren = sorted(n["titel"] for n in raus)

    # Auto-gradebar, sauberer Schluessel — scheitert NUR am G1b-Gate.
    g1b = [n["titel"] for n in neu
           if pool_faehig(n, n1_mc_schluessel(n), n2_leere_optionen(n),
                          n3_kodierregel(n))
           and not n["vollstaendig"]
           and (n.get("_flags_blockierend") or [""])[0].startswith("G1b")]

    # Von den ausgeschiedenen: was braucht wirklich einen Coach, was ist nur ein
    # kaputter Schluessel?
    coach_pflicht, reparierbar = [], []
    for n in raus:
        keys = [str(a) for p in n["parts"] for a in (p.get("correct_answers") or [])]
        (coach_pflicht if any(COACH_PFLICHT.search(k) for k in keys)
         else reparierbar).append(n["titel"])

    bv_datei = ROOT / "data/r01_doc_bildverlust.json"
    bv = (json.loads(bv_datei.read_text(encoding="utf-8"))
          if bv_datei.exists() else None)

    L = []
    w = L.append
    w("# R01 — Diff: Altbestand gegen Neuextraktion")
    w("")
    w(f"**Alt:** `data/vera8_komplett_enriched.json` · **Neu:** "
      f"`data/vera8_v2.json` · **{len(alt)} Items**, beide Seiten deckungsgleich.")
    w("")
    w("Kein Import, kein DB-Schreibvorgang, kein Item auf `ready`. Alle 299 neuen "
      "Items stehen auf `draft`.")
    w("")
    w("---")
    w("")

    w("## Stand des Laufs")
    w("")
    w(f"Die Vision-Stufe ist **nachgezogen**: `data/r01_vision/` enthaelt jetzt "
      f"**{len(neu) - len(ohne_vision)} von {len(neu)}** Lesungen. "
      f"Die {len(ohne_vision)} ohne Lesung sind nicht nachholbar — ihnen fehlt "
      f"die Quelle:")
    w("")
    for n in sorted(ohne_vision, key=lambda x: x["titel"]):
        grund = next((f for f in (n.get("_flags") or [])
                      if "keine Quelle" in f or "keine Aufgaben-Datei" in f
                      or "kein Inhaltsbild" in f), "kein Render")
        w(f"- **{n['titel']}** — {grund}")
    w("")
    w("Jede Lesung wurde sofort auf die Platte geschrieben, bevor die naechste "
      "begann. Ein Abbruch haette keine Arbeit gekostet.")
    w("")
    w("### Bau-Verzug")
    w("")
    if verzug:
        w(f"**Fuer {len(verzug)} Items liegt eine brauchbare Vision-Lesung auf "
          f"der Platte, die `vera8_v2.json` nicht enthaelt.** Die Vision-Stufe "
          f"lief weiter, waehrend der Bau schon geschrieben war. Kein "
          f"Extraktionsfehler — ein Lauf von `ground_all.py` holt sie herein:")
        w("")
        w("| Item | Teilaufgaben in der Vision-Lesung |")
        w("|---|---:|")
        for t, k in verzug:
            w(f"| {t} | {k} |")
        w("")
    else:
        w("Beim ersten Bau war `vera8_v2.json` aelter als 27 Vision-Lesungen — "
          "22 Items hatten eine brauchbare Lesung auf der Platte, die der Bau nie "
          "gesehen hatte. **Das ist behoben:** `ground_all.py` ist nachgelaufen, "
          "der Bau enthaelt jetzt jede vorhandene Lesung. Abgesichert durch "
          "`NC15` in `test_scale.py`: Ein Bau, der eine vorhandene Lesung "
          "ignoriert, ist ab jetzt ein Testfehler.")
        w("")
    w("---")
    w("")

    if bv:
        w("## Der groesste offene Hebel: die .doc-Extraktion verliert Bilder")
        w("")
        w(f"**{bv['doc_items_mit_verlust']} von {bv['doc_items_geprueft']} "
          f".doc-Items verlieren Bilder — {bv['bilder_verloren']} Bilder "
          f"insgesamt.** Und in diesen Bildern stehen die Teilaufgaben.")
        w("")
        w("Der Nachlauf hat den Befund erst sichtbar gemacht: Elf unabhaengige "
          "Leser meldeten dasselbe — *\"nur EIN gerendertes Bild, darin nur der "
          "Stamm, keine Frage\"*. Sie haben korrekt gemeldet, dass im Bild keine "
          "Frage steht. Die Frage war nie im Bild.")
        w("")
        w("Ein VERA8-`.doc` legt **jede Teilaufgabe als eigenes eingebettetes "
          "Bild** ab:")
        w("")
        w("```")
        w("$ antiword temperaturen_Aufgabe.doc")
        w("Temperaturen in Frankfurt am Main")
        w("[pic]                 <- Stamm            } wird extrahiert")
        w("Teilaufgabe 1")
        w("[pic]                 <- die Frage        } bleibt in der Datei liegen")
        w("Teilaufgabe 2")
        w("[pic]                                     } bleibt in der Datei liegen")
        w("Teilaufgabe 3")
        w("[pic][pic]                                } bleibt in der Datei liegen")
        w("```")
        w("")
        w("`ole.media_in_doc()` holt aus dem Container nur **ein** Bild. Das ist "
          "kein Render- und kein Vision-Fehler, sondern ein **Extraktionsfehler** "
          "— eine Stufe frueher als vermutet.")
        w("")
        w("| Item | Bilder im Dokument | extrahiert | verloren |")
        w("|---|---:|---:|---:|")
        for b in sorted(bv["items"], key=lambda x: -x["verloren"])[:15]:
            w(f"| {b['item']} | {b['bilder_im_dokument']} | "
              f"{b['bilder_extrahiert']} | {b['verloren']} |")
        w(f"| … | | | **{bv['bilder_verloren']} gesamt** |")
        w("")
        w("Gemessen mit `scripts/content/r01/audit_doc_bilder.py` "
          "(`data/r01_doc_bildverlust.json`).")
        w("")
        w("**Das ist der naechste Hebel, und er ist groesser als alles bisher "
          "Gehobene.** Die Reihenfolge waere: `media_in_doc()` reparieren → neu "
          "rendern → Vision nur fuer die betroffenen Items nachziehen → bauen. "
          "Nicht angefasst: Das ist eine Neuextraktion, und die war fuer diesen "
          "Lauf ausgeschlossen.")
        w("")
        w("---")
        w("")

    w("## Die vier Toepfe")
    w("")
    w("| Topf | Items | Bedeutung |")
    w("|---|---:|---|")
    w(f"| identisch | {len(toepfe['identisch'])} | beide Seiten sauber |")
    w(f"| neu besser | {len(toepfe['neu_besser'])} | alt defekt, neu sauber |")
    w(f"| **neu schlechter** | {len(toepfe['neu_schlechter'])} | alt sauber, neu "
      f"defekt — **der wichtige Topf** |")
    w(f"| beide defekt | {len(toepfe['beide_defekt'])} | keine Version brauchbar |")
    w("")
    w("*Defekt* heisst: fehlender Stamm, fehlende Loesung, nachweislich "
      "zerstoerter Stamm (S1–S4), blockierendes Gate-Flag oder unbenutzbarer "
      "Loesungsschluessel (N1–N3). *Defekt* heisst **nicht** \"nicht "
      "auto-gradebar\" — ein sauberes FREE_TEXT-Item ist nicht defekt.")
    w("")

    w("## Der wichtige Topf: neu schlechter")
    w("")
    ns = sorted(toepfe["neu_schlechter"], key=lambda x: x["titel"])
    kein_vision = [e for e in ns if not e["vision"]]
    echt = [e for e in ns if e["vision"]]
    w(f"{len(ns)} Items — in zwei Gruppen, denn nur die zweite ist ein echter "
      f"Rueckschritt.")
    w("")
    w(f"### a) Vision-Stufe nie gelaufen ({len(kein_vision)})")
    w("")
    w("Kein Rueckschritt der Extraktion, sondern eine **offene Pipeline-Stufe**: "
      "Der Altbestand hat hier einen brauchbaren Datensatz, die Neuextraktion "
      "(noch) nichts. Nachlaufen lassen, dann neu bewerten.")
    w("")
    if kein_vision:
        w("| Item | alter Status |")
        w("|---|---|")
        for e in kein_vision:
            w(f"| {e['titel']} (`{e['slug']}`) | {e['alt_status']} |")
        w("")
    w(f"### b) Echter Rueckschritt ({len(echt)})")
    w("")
    if not echt:
        w("**Leer.** Kein Item, das im Altbestand sauber war und trotz gelaufener "
          "Vision-Lesung in der Neuextraktion defekt ist.")
    else:
        w("Vision ist gelaufen, das Ergebnis ist trotzdem schlechter als der "
          "Altbestand. Jedes Item einzeln:")
        w("")
        w("| Item | alter Status | was die Neuextraktion verliert |")
        w("|---|---|---|")
        for e in echt:
            w(f"| {e['titel']} (`{e['slug']}`) | {e['alt_status']} | "
              f"{'; '.join(e['neu'])[:170]} |")
    w("")

    w("---")
    w("")
    w("## Der Altbestand zerstoert STAEMME, nicht Loesungen")
    w("")
    w("### Der Mechanismus, belegt an `zeitangabe`")
    w("")
    w("Der alte Stamm ist der Textinhalt der EMF-Zeichenlaeufe. Dieser Kanal kann "
      "Sonderzeichen nicht dekodieren:")
    w("")
    w("```")
    w("Zeichenvorrat der Quelle : 'Wie viele Minuten sind 2    Stunden?'   <- kein ½")
    w("alter Stamm              : 'Wie viele Minuten sind 2 Stunden?'      <- 2 h = 120 min")
    w("alte Loesung             : '150min'                                 <- passt NICHT zu 2 h")
    w("neuer Stamm (Vision)     : 'Wie viele Minuten sind 2½ Stunden?'     <- 2,5 h = 150 min")
    w("```")
    w("")
    w("Die Loesung war die ganze Zeit richtig — sie kommt aus der Auswertungs-"
      "Datei, einem anderen Kanal. Kaputt war der Stamm. **Ein Check \"steht das "
      "Zeichen im Zeichenvorrat?\" kann diese Klasse nie finden**, denn der "
      "Zeichenvorrat ist genau der Kanal, der das ½ verliert. Deshalb vergleicht "
      "dieser Diff alten gegen neuen Stamm.")
    w("")
    w(f"Messbar ist das nur, wo **beide** Seiten einen Stamm haben "
      f"({vergleichbar} Items). Fuer die {len(ohne_parts)} Items ohne "
      f"Vision-Lesung ist unbekannt, ob ihr alter Stamm beschaedigt ist.")
    w("")

    w(f"### S1 — verlorene bedeutungstragende Zeichen im alten Stamm ({len(S1)})")
    w("")
    w("Zeichen, die der neue Stamm hat und der alte nicht: Brueche, Hoch- und "
      "Tiefstellungen, Malpunkt, echtes Minus. Jedes einzelne veraendert die "
      "Aufgabe.")
    w("")
    w("| Item | verloren | alter Stamm (Auszug) | neuer Stamm (Auszug) |")
    w("|---|---|---|---|")
    for t, m, ast, nst, _ in sorted(S1):
        w(f"| {t} | `{''.join(sorted(m))}` | {ast[:58].replace('|', '/')} | "
          f"{nst[:58].replace('|', '/')} |")
    w("")
    w("Daneben verlieren Items reine **Layoutzeichen** (`_`, `☐`, `…`) — "
      "Antwortlinien, Ankreuzkaestchen, Auslassungspunkte. Haesslich, aber nicht "
      "sinnentstellend, und darum hier nicht als Defekt gezaehlt.")
    w("")

    w("### S2 — die alte Loesung passt nicht zum alten Stamm, zum neuen aber sehr wohl")
    w("")
    w("S1 zu Ende gedacht: Wo der alte Stamm ein bedeutungstragendes Zeichen "
      "verloren hat, beschreibt er eine **andere Aufgabe** als die, zu der die "
      "unveraendert korrekte Loesung gehoert. Die Loesung ist der Zeuge dafuer, "
      "dass der Stamm luegt.")
    w("")
    w("Zwei Faelle lassen sich **nachrechnen** — bei ihnen ist die alte Loesung "
      "aus dem alten Stamm nicht nur unwahrscheinlich, sondern *unmoeglich*:")
    w("")
    w("| Item | alter Stamm | ergibt | alte Loesung | neuer Stamm | ergibt |")
    w("|---|---|---|---|---|---|")
    w("| Zeitangabe | `2 Stunden` | 120 min | **150 min** | `2½ Stunden` | "
      "**150 min** ✓ |")
    w("| Geraden im Koordinatensystem | `y = x − 2` | Nullstelle x = 2 | "
      "**x = 4** | `y = ½x − 2` | **x = 4** ✓ |")
    w("")
    w("`Zeitangabe` war der Kalibrierungsfall. `Geraden im Koordinatensystem` ist "
      "derselbe Bug, unabhaengig gefunden: Der Faktor ½ vor dem x ist im alten "
      "Stamm verschwunden, damit wandert die Nullstelle von 4 auf 2 — und die "
      "gespeicherte Loesung `x = 4` passt nur noch zur *neuen* Fassung. Die "
      "Loesung war nie falsch. Der Stamm war es.")
    w("")
    w("Die uebrigen S1-Faelle, jeweils mit alter Loesung:")
    w("")
    for t, m, ast, nst, al in sorted(S1):
        w(f"- **{t}** — alte Loesung: `{(al[0] if al else '—')}`")
        w(f"  - alter Stamm: `{ast[:120]}`")
        w(f"  - neuer Stamm: `{nst[:120]}`")
    w("")

    w(f"### S3 — MC: die alte Loesung steht nicht unter den Optionen ({len(S3)})")
    w("")
    w("Die Optionen sind auf der *neuen* Seite gelesen: im alten Stamm sind "
      "Optionen, Tabellenzellen und Prosa zu einem `|`-Brei verschmolzen und "
      "nicht mehr auseinanderzuhalten — das ist der eigentliche Befund.")
    w("")
    w("| Item | alte Loesung | neue Optionen | neu korrekt |")
    w("|---|---|---|---|")
    for t, nr, al, lab, kor in sorted(S3):
        opt = ", ".join(x[:20] for x in lab)[:64].replace("|", "/")
        w(f"| {t} (Ta{nr}) | `{al[:24]}` | {opt} | "
          f"{', '.join(str(k)[:20] for k in kor)[:30]} |")
    w("")
    w("Drei Sorten, und sie sind verschieden schlimm:")
    w("")
    w("- **Zeichen zerstoert, Wert richtig:** `16cm2` statt `16 cm²`, `90cm3` "
      "statt `90 cm³`, `xcm2` statt `x cm²`. Der Wert stimmt; als "
      "Vergleichsstring ist der Schluessel trotzdem unbrauchbar.")
    w("- **Wert FALSCH:** `Mädchenanteil` — alte Loesung **`8`**, richtig ist "
      "**`8/23`**. Der Bruchstrich ging verloren, uebrig blieb der Zaehler. Das "
      "ist keine Formatfrage mehr, sondern eine **falsche Loesung** im "
      "Altbestand.")
    w("- **Bildverweis:** `[pic]` — die Loesung war eine Grafik. Im Altbestand "
      "unbrauchbar, in der Neuextraktion **immer noch** unbrauchbar (siehe N1).")
    w("")

    w(f"### S4 — verschraenkte Textlaeufe ({len(S4)})")
    w("")
    w("Zwei ineinandergeschobene Textlaeufe verdoppeln die Buchstaben:")
    w("")
    for t, ws in sorted(S4):
        w(f"- **{t}** — z.B. {', '.join(repr(x) for x in ws)}")
    w("")

    w("---")
    w("")
    w("## Was die Neuextraktion ihrerseits falsch macht (N1–N3)")
    w("")
    w("Diese Klasse faellt durch die Gates: `grade()` in `ground_all.py` prueft "
      "nur, **dass** ein `correct_answers` da ist — nicht, ob es eine benutzbare "
      f"Antwort **ist**. Darum ist die Pipeline-Zahl ({len(pipeline_pool)}) zu "
      f"hoch.")
    w("")
    w(f"### N1 — MC-Schluessel ist keine Options-ID ({len(N1)} Teilaufgaben)")
    w("")
    w("Statt `\"c\"` steht im Schluessel die Kodierregel aus der Auswertung:")
    w("")
    for t, nr, ca in sorted(N1)[:12]:
        w(f"- **{t}** (Ta{nr}): `{str(ca)[:100]}`")
    if len(N1) > 12:
        w(f"- … und {len(N1) - 12} weitere")
    w("")
    w("Der Grossteil sind in Wahrheit **MC + Begruendung** — also gar keine reinen "
      "MC-Items, sondern coach-bewertete Items, die faelschlich als MC typisiert "
      "wurden.")
    w("")
    w(f"### N2 — Optionen ohne Label ({len(N2)})")
    w("")
    for t, nr in sorted(N2):
        w(f"- **{t}** (Ta{nr}): vier Optionen, alle Labels leer")
    w("")
    w(f"### N3 — SHORT_INPUT-Schluessel ist eine Kodierregel ({len(N3)})")
    w("")
    for t, nr, ans in sorted(N3)[:14]:
        w(f"- **{t}** (Ta{nr}): `{ans}`")
    if len(N3) > 14:
        w(f"- … und {len(N3) - 14} weitere")
    w("")
    w("Ein Teil davon ist mechanisch reparierbar — Intervalle und "
      "`ODER`-Alternativen lassen sich in einen Matcher uebersetzen. Aber "
      "**heute** kann LSA damit nicht bewerten.")
    w("")

    w("---")
    w("")
    w("## Die 14 bereits importierten Items")
    w("")
    w("Die Vorgabe war: Sie muessen identisch herauskommen. Weicht eines ab — "
      "melden, nicht aufloesen.")
    w("")
    w("| Befund | Items |")
    w("|---|---:|")
    w(f"| Loesung und Einheit **exakt bestaetigt** | {len(bestaetigt)} |")
    w(f"| Wert bestaetigt, aber **Schluessel unsauber** | {len(unsauber)} |")
    w(f"| **Widerspruch** (neue Loesung sagt etwas anderes) | "
      f"**{len(widerspruch)}** |")
    w(f"| leer (Neuextraktion hat keine Teilaufgabe) | {len(leer)} |")
    w("")
    if widerspruch:
        w("### Widerspruch — hier ist eine der beiden Versionen falsch")
        w("")
        for titel, slug, ab in widerspruch:
            w(f"- **{titel}** (`{slug}`): {' · '.join(ab)}")
        w("")
        w("**Nicht aufgeloest.** Das gehoert vor einen Menschen.")
        w("")
    else:
        w("**Kein einziges der 14 importierten Items wird von der Neuextraktion "
          "widerlegt.** Es gibt keinen Fall, in dem die neue Loesung etwas "
          "anderes sagt als die importierte.")
        w("")
    if unsauber:
        w("### Wert bestaetigt, Schluessel unsauber")
        w("")
        w("Der importierte Wert steckt im neuen Schluessel — aber mit dem "
          "Kodiertext der Auswertung drumherum. Inhaltlich eine Bestaetigung, "
          "technisch ein Schluessel, den kein Matcher vergleichen kann:")
        w("")
        for titel, slug, answers, nl in unsauber:
            w(f"- **{titel}** (`{slug}`): importiert `{answers}` · neu `{nl}`")
        w("")
    if leer:
        w("### Leer — weder bestaetigt noch widerlegt")
        w("")
        for titel, slug, grund in leer:
            w(f"- **{titel}** (`{slug}`): {grund}")
        w("")
        w("Das ist **kein Widerspruch**, sondern eine Leerstelle: Fuer diese Items "
          "hat die Neuextraktion nichts, woran man den Import messen koennte.")
        w("")

    w("---")
    w("")
    w("## Die entscheidende Zahl: der reale LSA-Pool")
    w("")
    w("Kriterium: **auto-gradebar** (jede Teilaufgabe MC oder SHORT_INPUT, mit "
      "einem Schluessel, den ein Matcher **heute** vergleichen kann) **UND "
      "vollstaendig** (Stamm + Loesung + Beleg, kein blockierendes Flag).")
    w("")
    w(f"# {len(pool)} von {len(neu)} Items")
    w("")
    w("| Typ | Items |")
    w("|---|---:|")
    for k in ("MC", "SHORT_INPUT", "MULTI_PART"):
        w(f"| {k} | {typ.get(k, 0)} |")
    w(f"| **Summe** | **{len(pool)}** |")
    w("")
    w(f"### Warum nicht {len(pipeline_pool)}")
    w("")
    w(f"Das Feld `lsa_pool_kandidat` in `vera8_v2.json` sagt "
      f"**{len(pipeline_pool)}**. Diese Zahl ist zu hoch: `grade()` akzeptiert "
      f"jeden nicht-leeren Schluessel. {len(verloren)} dieser Items tragen eine "
      f"Kodierregel oder einen Bildverweis statt einer Antwort (N1–N3) und sind "
      f"damit nicht maschinell bewertbar:")
    w("")
    w(", ".join(verloren))
    w("")
    w(f"**{len(pipeline_pool)} − {len(verloren)} = {len(pool)}.**")
    w("")
    w(f"Diese {len(verloren)} zerfallen wiederum in zwei Gruppen:")
    w("")
    w(f"- **{len(coach_pflicht)} brauchen wirklich einen Coach.** Der Schluessel "
      f"verlangt eine Begruendung, einen Loesungsweg oder war eine Grafik — das "
      f"repariert kein Matcher. Es sind Items, die als MC/SHORT_INPUT typisiert "
      f"wurden, in Wahrheit aber **MC + Begruendung** sind: "
      f"{', '.join(sorted(coach_pflicht))}.")
    w(f"- **{len(reparierbar)} haengen an einem Schluessel, den ein Mensch "
      f"entscheiden muss** — geflaggt, nicht geraten (Flag `SCHLUESSEL:` im "
      f"Item): {', '.join(sorted(reparierbar))}.")
    w("")
    w("### Das Schluessel-Aufraeumen: was mechanisch ging, ist erledigt")
    w("")
    w("Die Auswertungszelle ist fuer Menschen geschrieben, nicht fuer einen "
      "Matcher. `ground_all.schluessel_saeubern()` raeumt jetzt auf — aber **nur, "
      "wo es rein mechanisch ist**. Drei Regeln, jede fuer sich unstrittig:")
    w("")
    w("| Regel | Beispiel |")
    w("|---|---|")
    w("| Ab der ersten Kommentarzeile (`Anm.:`, `Anmerkung:`, `•`) ist alles "
      "Kommentar | `Holzstab`: `['1,5', 'Anm.: Akzeptiert werden auch...']` → "
      "`['1,5']` |")
    w("| Reine Konnektoren (`ODER`, `(Grenzfall)`) sind keine Antworten | "
      "`Fehlende Zahlen`: `['(-21)', 'ODER', '(Grenzfall)', '-21']` → `['-21']` |")
    w("| `A ODER B` sind zwei akzeptierte Alternativen — aufspalten; Klammern um "
      "reine Zahlen strippen | `Papier`: `['22 (ODER ca. 22)']` → `['22']` · "
      "`Außenthermometer`: `['10 ODER -10']` → `['10', '-10']` |")
    w("")
    w("Der Rohschluessel bleibt im `_grounding` stehen und belegbar — die "
      "Saeuberung verwischt nichts.")
    w("")
    w("**Wo die Bereinigung eine inhaltliche Entscheidung waere, wird geflaggt "
      "statt geraten.** Vier Faelle, in denen der Schluessel unveraendert bleibt:")
    w("")
    w("- **`UND`-Mehrfachantworten** (`Fliesen`: `50 UND 25 UND 12,5`) — mehrere "
      "*Pflicht*-Werte. Welcher davon ist \"die\" Antwort? Das ist eine Frage ans "
      "Datenmodell, nicht an einen Regex.")
    w("- **Toleranzintervalle** (`Butter`: `Ganzzahlige Antworten aus dem "
      "Intervall [70; 80]`) — braucht einen Range-Matcher. Ein Format dafuer zu "
      "erfinden, waere geraten.")
    w("- **Prosa-Saetze** (`Kraftfutter`: `Das Kraftfutter reicht 21 Tage.`) — die "
      "Antwort ist richtig, aber kein vergleichbarer Wert.")
    w("- **Mehrere Teilantworten in einem String** (`Suche die Zahl`: "
      "`5 = 10  3 = 24  7 = 21`).")
    w("")
    w("Eine Falle dabei, die fast zugeschnappt waere: Der Konnektor der Auswertung "
      "ist das **grosse** `UND`. Ein case-insensitives `\\bUND\\b` trifft auch das "
      "normale deutsche Woertchen \"und\", das harmlos in jedem zweiten "
      "Antwortsatz steht — und haette 11 voellig gesunde Schluessel als kaputt "
      "gemeldet. Die Regel ist deshalb case-sensitive.")
    w("")
    w("### G1b ist entschaerft — eng, nicht generell")
    w("")
    w("G1b hat denselben Wurzelgrund wie S1 und war deshalb ein **falscher "
      "Waechter**: Der Zeichenvorrat stammt aus den EMF-Zeichenlaeufen, und genau "
      "dieser Kanal *kann* reine Layoutzeichen nicht liefern. Ein EMF *zeichnet* "
      "die Antwortlinie und das Ankreuzfeld — es *schreibt* sie nicht. G1b "
      "verlangte einen Beleg aus einer Quelle, die ihn strukturell nie liefern "
      "kann (sie verliert ja sogar das ½).")
    w("")
    w("Fuer eine **enge, explizite Whitelist** ist G1b jetzt eine Notiz statt "
      "eines Blockers — `ground_all.LAYOUT_ZEICHEN`:")
    w("")
    w("| Zeichen | was es ist |")
    w("|---|---|")
    w("| `_` | Antwortlinie (gezeichnete Linie, kein Zeichen) |")
    w("| `…` | Auslassungspunkte |")
    w("| `☐ □ ▢ ⬜` | Ankreuzfelder (gezeichnete Rechtecke) |")
    w("")
    w("**Beleg-pflichtig bleibt alles, was den Inhalt aendern kann** — und das war "
      "die Mehrheit der G1b-Faelle: `/` (Bruchstrich: `Maedchenanteil` waere sonst "
      "`8` statt `8/23`), `,` (Dezimaltrenner), `^` (Exponent), `*` (Malzeichen "
      "oder Fussnote — mehrdeutig, also blockierend), Klammern, Interpunktion. "
      "Von den 11 Items, die an G1b hingen, waren nur **5** reine Layoutfaelle; "
      "die uebrigen 6 blockieren weiter, zu Recht. Im Zweifel: blockieren.")
    w("")
    w("Abgesichert durch `NC14` in `test_scale.py`: Antwortlinie und Ankreuzfeld "
      "sind eine Notiz, Bruchstrich/Dezimalkomma/Exponent/Malzeichen blockieren "
      "weiter, und die Whitelist enthaelt nachweislich nichts Bedeutungstragendes.")
    w("")
    if g1b:
        w(f"Rest, der noch an G1b haengt: {len(g1b)} — {', '.join(sorted(g1b))}")
        w("")
    w("### Und das ist eine Untergrenze")
    w("")
    w(f"{len(pool)} ist kein Endstand: {len(ohne_vision)} Items haben keine "
      f"Vision-Lesung und konnten gar nicht erst in die Bewertung. Laeuft die "
      f"Vision-Stufe nach, kommen Kandidaten dazu — darunter 4 der 14 bereits "
      f"importierten Items, die heute leer sind.")
    w("")
    w("### Die Pool-Items")
    w("")
    for k in ("MC", "SHORT_INPUT", "MULTI_PART"):
        items = sorted(n["titel"] for n in pool if n["input_type"] == k)
        if items:
            w(f"**{k} ({len(items)}):** {', '.join(items)}")
            w("")

    w("---")
    w("")
    w("## Topf-Details")
    w("")
    for key, titel in [("neu_besser", "neu besser"),
                       ("beide_defekt", "beide defekt"),
                       ("identisch", "identisch")]:
        e_ = sorted(toepfe[key], key=lambda x: x["titel"])
        w(f"### {titel} ({len(e_)})")
        w("")
        if key == "identisch":
            w(", ".join(x["titel"] for x in e_) or "—")
            w("")
            continue
        if key == "beide_defekt":
            ov = [x for x in e_ if not x["vision"]]
            w(f"Davon **{len(ov)} ohne Vision-Lesung**: die neue Seite ist leer, "
              f"weil die Stufe nicht gelaufen ist — nicht, weil sie gescheitert "
              f"waere.")
            w("")
        w("| Item | alt defekt weil | neu defekt weil |")
        w("|---|---|---|")
        for x in e_:
            w(f"| {x['titel']} | {'; '.join(x['alt'])[:95] or '—'} | "
              f"{'; '.join(x['neu'])[:95] or '—'} |")
        w("")

    OUT.write_text("\n".join(L) + "\n", encoding="utf-8")

    print(f"identisch={len(toepfe['identisch'])} "
          f"neu_besser={len(toepfe['neu_besser'])} "
          f"neu_schlechter={len(toepfe['neu_schlechter'])} "
          f"beide_defekt={len(toepfe['beide_defekt'])}")
    print(f"S1={len(S1)} S3={len(S3)} S4={len(S4)} | "
          f"N1={len(N1)} N2={len(N2)} N3={len(N3)}")
    print(f"LSA-Pool real={len(pool)} {dict(typ)} | +{len(reparierbar)} reparierbar "
          f"(Pipeline sagt {len(pipeline_pool)}, davon {len(verloren)} unbenutzbar)")
    print(f"nur an G1b gescheitert={len(g1b)} -> Pool waere "
          f"{len(pool) + len(reparierbar) + len(g1b)}")
    print(f"ohne Vision={len(ohne_vision)} ohne Teilaufgaben={len(ohne_parts)}")
    print(f"14 importierte: {len(bestaetigt)} exakt, {len(unsauber)} unsauber, "
          f"{len(widerspruch)} WIDERSPRUCH, {len(leer)} leer")
    if fehlend:
        print(f"NICHT in v2: {fehlend}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
