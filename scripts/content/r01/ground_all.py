"""R01 — Stufe 3 (GROUNDING) fuer den ganzen Bestand. Hart.

Regel: Kein woertlicher Beleg aus der Quelle, kein Feld.

Die Gates sind dieselben wie im Kalibrierlauf (ground.py, §7 der Kalibrierung):

G1  Stamm/Prompt/Option gegen den ZEICHENVORRAT des EMF (Multimenge). Die Vision
    darf die Lesereihenfolge bestimmen — die steht im EMF nicht drin. Sie darf
    aber kein Zeichen erfinden.
G2  Loesung woertlich gegen eine Auswertungszelle.
G3  "N. Kaestchen wurde angekreuzt" -> N-te Option in VISUELLER Reihenfolge.
G4  Keine Einheiten-Umrechnung. "[Anm.: ...]" ist Kodierhinweis, keine Antwort.
G5  Tabellen bleiben Tabellen.
G6  Restzeichen: was in KEINEM Feld gelandet ist. Bericht, kein Stopp.

Neu gegenueber dem Kalibrierlauf, weil der volle Bestand es erzwingt:

G0  QUELLENKLASSE. 33 Items tragen ihren Aufgabentext als Rasterbild. Ein Raster
    hat keinen Zeichenvorrat — G1 ist dort nicht anwendbar. Solche Items werden
    NICHT stillschweigend als geprueft ausgegeben, sondern als ungeprueft
    markiert. Ein Gate, das mangels Datenlage durchwinkt, ist kein Gate.

G7  LIZENZ. Der Lizenzhinweis steht in jedem Item selbst und nennt ausdruecklich,
    was gedeckt ist: "Copyright Text und Teilaufgaben" — oder "Text, Grafik und
    Teilaufgaben". Fehlt das Wort "Grafik", ist die Abbildung nicht von CC BY
    gedeckt und wird als nicht verwendbar markiert.

Ausgabe: data/vera8_v2.json (NEU) + data/r01_befunde.json.
Status ist IMMER 'draft'. Freigabe ist ein menschlicher Akt.
"""
import json
import re
import sys
import unicodedata
from collections import Counter, OrderedDict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from visionqueue import richtig_je_teilaufgabe

ROOT = Path(__file__).resolve().parents[3]
EXTRACT = ROOT / "data/r01_extract"
VISION = ROOT / "data/r01_vision"
ALT = ROOT / "data/vera8_komplett_enriched.json"
OUT = ROOT / "data/vera8_v2.json"
BEFUNDE = ROOT / "data/r01_befunde.json"

# Was die Vision als EIN Zeichen liest, steht im EMF als mehrere Records: ein
# Bruch ist Zaehler + Bruchstrich(Linie) + Nenner, eine Hochzahl eine normale
# Ziffer auf hoeherer Grundlinie. Fuer den Vorratsabgleich wird das
# zurueckgefaltet — sonst wuerde die Pipeline korrekt Gelesenes verwerfen.
UNFOLD = {
    "½": "12", "¼": "14", "¾": "34", "⅓": "13", "⅔": "23", "⅛": "18",
    "²": "2", "³": "3", "¹": "1", "⁰": "0", "⁴": "4", "⁵": "5", "ⁿ": "n",
    # Tiefgestelltes ist im EMF eine normale Ziffer auf tieferer Grundlinie —
    # 'D₅' steht dort als 'D' und '5'. Ohne diese Ruecklaufregel verwirft G1 ein
    # korrekt gelesenes 'D₅', weil es das Zeichen '₅' im Vorrat nicht findet.
    "₀": "0", "₁": "1", "₂": "2", "₃": "3", "₄": "4", "₅": "5", "₆": "6",
    "₇": "7", "₈": "8", "₉": "9", "ₙ": "n", "₋": "-",
    "–": "-", "—": "-", "−": "-", "’": "'", "“": '"', "”": '"', "„": '"',
    "·": "*", "×": "*", "≈": "=", "'": "'",
}

ORDINAL = re.compile(r"(\d+)\s*\.\s*K[äa]stchen")
ANM = re.compile(r"\[Anm\.|Beispiel\(e\)|Beispiele:|\[Grenzfall")


def norm(s):
    """Zeichenvorrat-Normalform: Whitespace weg, Sonderformen zurueckgefaltet."""
    s = unicodedata.normalize("NFC", s or "")
    s = "".join(UNFOLD.get(c, c) for c in s)
    return re.sub(r"\s+", "", s).lower()


def norm_text(s):
    """Fuer woertliche Belege: Whitespace kollabieren, sonst nichts glaetten."""
    s = unicodedata.normalize("NFC", s or "")
    s = "".join(UNFOLD.get(c, c) for c in s)
    return re.sub(r"\s+", " ", s).strip().lower()


def inhalt(s):
    """Nur die bedeutungstragenden Zeichen: Buchstaben und Ziffern.

    WARUM NICHT ALLE ZEICHEN — das ist eine bewusste Abschwaechung gegenueber dem
    Kalibrierlauf, und sie hat einen Grund, den erst der Vollauf gezeigt hat:

    Ein EMF *schreibt* nicht alles, was man im Bild sieht. Das Eingabefeld
    `______` ist eine gezeichnete LINIE, kein Unterstrich. Das Ankreuzkaestchen
    `☐` ist ein gezeichnetes RECHTECK, kein Zeichen. Wer sie im Zeichenvorrat
    sucht, findet sie nie — und verwirft eine voellig korrekte Lesung, weil sie
    das Kaestchen benennt, das sie sieht.

    Dazu kommt die Interpunktion, die eine Lesung beim Zusammenfuegen erzeugt:
    Die Quelle setzt zwischen zwei Textbloecke gar nichts, die Lesung ein
    Semikolon. Das ist kein erfundener Inhalt.

    Erfundener INHALT dagegen — ein falsches Wort, eine falsche Zahl — besteht
    immer aus Buchstaben und Ziffern. Genau darauf bleibt G1 hart: Die
    Negativkontrollen des Kalibrierlaufs ('3 Stunden' -> fehlt '3', 'Sekunden'
    -> fehlt 'deks') fliegen weiter auf (NC13 in test_scale.py).

    Was an Interpunktion trotzdem unbelegt bleibt, verschwindet nicht: es geht
    als G1b-Befund in die Flags.
    """
    return "".join(c for c in norm(s) if c.isalnum())


def g1(claim, vorrat):
    """Jedes INHALTSZEICHEN der Lesung muss im Vorrat sein (Multimenge)."""
    missing = Counter(inhalt(claim)) - Counter(inhalt(vorrat))
    return (not missing), "".join(sorted(missing.elements()))


def g1b(claim, vorrat):
    """Bericht: Interpunktion/Layoutzeichen der Lesung ohne Beleg im Vorrat."""
    def punkt(s):
        return Counter(c for c in norm(s) if not c.isalnum())
    return "".join(sorted((punkt(claim) - punkt(vorrat)).elements()))


def g2(value, cells):
    """Woertlicher Beleg in einer Auswertungszelle."""
    v = norm_text(value)
    if not v:
        return False, None
    for c in cells:
        if v in norm_text(c):
            return True, c
    return False, None


def canon(slug):
    """Die zwei GeoGebra-Items heissen im Ordner wie ihre Datei
    ('dreieckimrechteck_Aufgabe.ggb'). Ohne diese Normalisierung faende der
    Abgleich sie nicht wieder und der Bestand haette 301 statt 299 Items."""
    return (slug or "").split("_Aufgabe.")[0]


def slug_map():
    """slug -> Alt-Item (fuer id/titel/klasse). Die Alt-JSON wird nur GELESEN."""
    out = {}
    for it in json.loads(ALT.read_text(encoding="utf-8")):
        url = (it.get("iqb_urls") or {}).get("aufgabe") or ""
        if url:
            out[canon(url.split("/")[-1])] = it
    return out


def kompetenzen(komm, nr):
    """AFB + Kompetenzen der Teilaufgabe nr — woertlich aus der Kommentierung."""
    if not komm:
        return {}, None
    tas = komm.get("teilaufgaben") or []
    ta = next((t for t in tas if t.get("nr") == nr), None)
    if ta is None and len(tas) == 1:
        ta = tas[0]                      # einteilige Aufgabe, Nummer oft ohne Wert
    if not ta:
        return {}, None
    felder = {
        "afb": ta.get("afb"),
        "afb_raw": ta.get("afb_raw"),
        "kompetenzen": ta.get("k_tags") or [],
        "kompetenzstufe": ta.get("kompetenzstufe_raw"),
        "leitidee": ta.get("leitidee_raw"),
    }
    zitat = " | ".join(x for x in (ta.get("leitidee_raw"), ta.get("kompetenz_raw"),
                                   ta.get("afb_raw")) if x)
    return felder, zitat


# Ein Flag ist nicht gleich ein Flag. "Die Grafik ist nicht lizenziert" ist eine
# Rechts-, keine Datenfrage — das Item bleibt loesbar. "Der Stamm hat keinen
# Beleg" heisst dagegen: hier steht moeglicherweise etwas Erfundenes. Nur die
# zweite Sorte darf ein Item aus dem Pool werfen; die erste wird berichtet.
BLOCKIEREND = ("G0", "G1", "G2", "G3", "G5")
BLOCKIEREND_TEXT = ("unbrauchbar", "keine Vision", "keine Quelle",
                    "keine Quelldatei", "kein Inhaltsbild", "keine Aufgaben-Datei")


def blockierend(flags):
    return [f for f in flags
            if f.startswith(BLOCKIEREND) or any(t in f for t in BLOCKIEREND_TEXT)]


def grade(item):
    """Auto-gradebar + vollstaendig — die zwei Zahlen, die den LSA-Pool bestimmen.

    Auto-gradebar: JEDE Teilaufgabe ist maschinell pruefbar (mc oder short_input,
    vgl. lsa_parts_valid) UND traegt eine belegte Loesung. Eine einzige
    free_text-Teilaufgabe macht das ganze Item coach-bewertet.

    Vollstaendig: Stamm/Prompt vorhanden, Loesung vorhanden, beides belegt, und
    kein blockierendes Flag. Ein Item ohne Prompt ist kein Item; ein Item mit
    unbelegtem Stamm ist ein Geruecht.
    """
    parts = item["parts"]
    if not parts:
        return False, False
    auto = all(p["kind"] in ("mc", "short_input") and p.get("correct_answers")
               and (p["kind"] != "mc" or p.get("options"))
               for p in parts)
    belegt = all(item["_grounding"].get(f"part{p['nr']}.prompt", {}).get("ok")
                 for p in parts)
    loesung = all(p.get("correct_answers") for p in parts)
    voll = (belegt and loesung
            and all(p.get("prompt") for p in parts)
            and not blockierend(item["_flags"]))
    return auto, voll


def input_type(parts):
    if len(parts) > 1:
        return "MULTI_PART"
    if not parts:
        return None
    return {"mc": "MC", "short_input": "SHORT_INPUT",
            "free_text": "FREE_TEXT"}.get(parts[0]["kind"])


def build(slug, rec, vis, alt):
    emfs = [e for e in rec["stufe2_aufgabe_emf"] if not e.get("fehler")]
    inhalt = [e for e in emfs if not e.get("is_license")]
    vorrat = "".join(e.get("tokens") or "" for e in inhalt)
    # G0: Ohne Zeichenvorrat gibt es nichts, woran sich eine Lesung messen liesse.
    raster = bool(inhalt) and not vorrat.strip()

    komm = rec.get("stufe1_kommentierung")
    richtig = richtig_je_teilaufgabe(rec)
    cells = [c for t in rec["stufe1_auswertung"]["tables"]
             for row in t["cells"] for c in row]

    item = {
        "id": (alt or {}).get("id"),
        "slug": slug,
        "titel": (alt or {}).get("titel") or slug,
        "quelle": "VERA8_IQB",
        "klasse": (alt or {}).get("klasse", 8),
        "status": "draft",          # IMMER. Freigabe ist ein menschlicher Akt.
        "is_diagnostic": True,
        "input_type": None,
        "stem": {"text": "", "table": None},
        "parts": [],
        "assets": [],
        "_grounding": OrderedDict(),
        "_flags": list(rec.get("flags", [])),
        "_quelle": {
            "dateien": rec["sources"],
            "zeichenvorrat": "raster (kein Zeichenvorrat, G1 nicht anwendbar)"
                             if raster else "vektor (EMF)",
        },
    }
    befunde = []

    def check(feld, claim, quelle="EMF-Zeichenvorrat"):
        """G1 — oder G0, wenn es keinen Vorrat gibt."""
        if raster:
            item["_grounding"][feld] = {
                "gate": "G0", "ok": False, "quelle": "Rasterbild",
                "zitat": None,
                "hinweis": "Rasterquelle: kein Zeichenvorrat, Lesung UNGEPRUEFT",
            }
            befunde.append({"item": slug, "feld": feld, "gate": "G0", "ok": False,
                            "wert": claim})
            return "ungeprueft"
        ok, missing = g1(claim, vorrat)
        item["_grounding"][feld] = {
            "gate": "G1", "ok": ok, "quelle": quelle,
            "zitat": claim if ok else None,
            "fehlende_zeichen": "" if ok else missing,
        }
        befunde.append({"item": slug, "feld": feld, "gate": "G1", "ok": ok,
                        "wert": claim, "fehlende_zeichen": "" if ok else missing})
        if ok:
            # G1b: Interpunktion ohne Beleg blockiert nicht, verschwindet aber
            # auch nicht — ein Mensch soll sehen, wo die Lesung geglaettet hat.
            rest = g1b(claim, vorrat)
            if rest:
                item["_grounding"][feld]["g1b_interpunktion_ohne_beleg"] = rest
                item["_flags"].append(
                    f"G1b: {feld}: Interpunktion/Layoutzeichen ohne Beleg im "
                    f"Zeichenvorrat: {rest!r} (Inhalt belegt, Zeichensetzung "
                    f"stammt aus der Lesung)")
        return ok

    verbraucht = []

    # --- Stamm (G1/G0) ---
    stem = (vis.get("stem") or "").strip()
    if stem:
        r = check("stem", stem)
        if r is False:
            item["_flags"].append("G1: Stamm ohne Beleg im Zeichenvorrat "
                                  "-> leer gelassen")
        else:
            item["stem"]["text"] = stem
            verbraucht.append(stem)
            if r == "ungeprueft":
                item["_flags"].append("G0: Stamm nur aus Rasterbild gelesen "
                                      "-> UNGEPRUEFT")

    # --- Tabelle im Stamm (G5) ---
    for e in inhalt:
        if e.get("table"):
            item["stem"]["table"] = {"header": e["table"]["header"],
                                     "rows": e["table"]["rows"]}
            item["_grounding"]["stem.table"] = {
                "gate": "G5", "ok": True, "quelle": e["emf"],
                "zitat": " | ".join(e["table"]["header"]),
            }
            verbraucht += e["table"]["header"] + [c for r in e["table"]["rows"]
                                                  for c in r]
            break
    if vis.get("stem_tabelle_erwartet") and not item["stem"]["table"]:
        item["_flags"].append("G5: Tabelle im Bild gesehen, aber keine "
                              "strukturierte Tabelle rekonstruiert")

    # --- Teilaufgaben ---
    for part in vis.get("parts", []):
        nr = part.get("nr") or 1
        p = {"nr": nr, "kind": part.get("kind") or "short_input", "prompt": "",
             "unit": None}

        r = check(f"part{nr}.prompt", part.get("prompt") or "")
        if r is False:
            item["_flags"].append(f"G1: Teilaufgabe {nr}: Prompt ohne Beleg "
                                  f"-> leer gelassen")
        else:
            p["prompt"] = (part.get("prompt") or "").strip()
            verbraucht.append(p["prompt"])

        if part.get("unit"):
            if check(f"part{nr}.unit", part["unit"]) is not False:
                p["unit"] = part["unit"]
                verbraucht.append(part["unit"])
            else:
                item["_flags"].append(f"Teilaufgabe {nr}: Einheit "
                                      f"{part['unit']!r} ohne Beleg -> verworfen")

        # Optionen (G1) — Reihenfolge ist die visuelle x-Ordnung aus dem Bild.
        if p["kind"] == "mc":
            opts = []
            for o in part.get("options") or []:
                if check(f"part{nr}.option[{o['id']}]", o["label"]) is not False:
                    opts.append({"id": o["id"], "label": o["label"]})
                    verbraucht.append(o["label"])
                else:
                    item["_flags"].append(f"Teilaufgabe {nr}: Option {o['id']!r} "
                                          f"ohne Beleg")
            p["options"] = opts
            if not opts:
                item["_flags"].append(f"Teilaufgabe {nr}: MC ohne belegte Optionen")

        # --- Loesung (G2/G3/G4) ---
        zellen = richtig.get(nr) or []
        zelle = zellen[0] if zellen else None
        if zelle is None:
            item["_flags"].append(f"G2: Teilaufgabe {nr}: keine RICHTIG-Zelle "
                                  f"-> keine Loesung")
        else:
            m = ORDINAL.search(zelle)
            if m and p["kind"] == "mc":
                # G3: Ordinal gegen die visuelle Reihenfolge aufloesen. Genau hier
                # ist die alte Pipeline gestorben: sie hat den String
                # "3. Kaestchen" als akzeptierte Antwort in die DB geschrieben.
                n = int(m.group(1))
                if 1 <= n <= len(p.get("options", [])):
                    opt = p["options"][n - 1]
                    p["correct_answers"] = [opt["id"]]
                    item["_grounding"][f"part{nr}.correct_answers"] = {
                        "gate": "G3", "ok": True,
                        "quelle": "Auswertung (RICHTIG-Zelle)",
                        "zitat": zelle,
                        "aufgeloest_auf": f"{n}. Option = {opt['label']} "
                                          f"(id={opt['id']})",
                    }
                    befunde.append({"item": slug, "feld": f"part{nr}.loesung",
                                    "gate": "G3", "ok": True, "wert": opt["label"]})
                else:
                    item["_flags"].append(
                        f"G3: Teilaufgabe {nr}: Ordinal {n} zeigt ins Leere "
                        f"({len(p.get('options', []))} Optionen) -> keine Loesung")
            else:
                # G2/G4: nur der Wert VOR dem Kodierhinweis, woertlich belegt.
                haupt = ANM.split(zelle)[0].strip()
                kandidaten = [x.strip() for x in haupt.splitlines() if x.strip()]
                akzeptiert = [k for k in kandidaten if g2(k, cells)[0]]
                if akzeptiert:
                    p["correct_answers"] = akzeptiert
                    item["_grounding"][f"part{nr}.correct_answers"] = {
                        "gate": "G2", "ok": True,
                        "quelle": "Auswertung (RICHTIG-Zelle)", "zitat": zelle,
                    }
                    befunde.append({"item": slug, "feld": f"part{nr}.loesung",
                                    "gate": "G2", "ok": True,
                                    "wert": "; ".join(akzeptiert)})
                else:
                    item["_flags"].append(f"G2: Teilaufgabe {nr}: Loesung ohne "
                                          f"woertlichen Beleg -> NICHT geschrieben")
                if "[Anm." in zelle and re.search(r"anderer Einheit", zelle):
                    item["_grounding"][f"part{nr}.g4_einheiten"] = {
                        "gate": "G4", "ok": True,
                        "quelle": "Auswertung ([Anm.]-Block)", "zitat": zelle,
                        "hinweis": "Umrechnungsvarianten bewusst NICHT als "
                                   "correct_answers uebernommen (P01: keine "
                                   "Einheiten-Umrechnung; Einheit steht in 'unit')",
                    }

        # --- AFB + Kompetenzen (Didaktische Kommentierung, woertlich) ---
        felder, zitat = kompetenzen(komm, nr)
        p.update({k: v for k, v in felder.items() if v not in (None, [])})
        if zitat:
            item["_grounding"][f"part{nr}.afb_kompetenzen"] = {
                "gate": "G2", "ok": True,
                "quelle": rec["sources"].get("Didaktische_Kommentierung", {})
                            .get("file"),
                "zitat": zitat,
            }
        elif komm:
            item["_flags"].append(f"Teilaufgabe {nr}: AFB/Kompetenzen nicht in "
                                  f"der Kommentierung gefunden")

        item["parts"].append(p)

    if not item["parts"]:
        item["_flags"].append("keine Teilaufgabe gelesen -> Item unbrauchbar")

    # --- Assets (G7: Lizenz) ---
    lz = rec.get("lizenz") or {}
    for e in inhalt:
        if not e.get("png"):
            continue
        item["assets"].append({
            "kind": "image",
            "quelle_datei": e["emf"],
            "verweis": e["png"],                    # Verweis, kein Upload
            "typ": e.get("quelle"),
            "lizenz_hinweis": lz.get("hinweis"),
            "grafik_gedeckt": lz.get("grafik_gedeckt", False),
            "verwendbar": bool(lz.get("grafik_gedeckt")),
            "begruendung": lz.get("begruendung"),
        })
    item["_grounding"]["assets.lizenz"] = {
        "gate": "G7", "ok": bool(lz.get("hinweis")),
        "quelle": "Lizenz-EMF im Item",
        "zitat": lz.get("hinweis"),
        "hinweis": lz.get("begruendung"),
    }
    if item["assets"] and not lz.get("grafik_gedeckt"):
        item["_flags"].append(
            "G7: " + (lz.get("begruendung") or "Lizenz unklar")
            + " -> Abbildung NICHT verwenden")

    # --- Vision-Zweifel uebernehmen ---
    for u in vis.get("unsicher") or []:
        item["_flags"].append(f"Vision unsicher: {u}")

    # --- G6: Restzeichen ---
    if vorrat.strip():
        rest = Counter(norm(vorrat)) - Counter(norm("".join(verbraucht)))
        item["_g6_restzeichen"] = {
            "rest": "".join(sorted(rest.elements()))[:200],
            "anzahl": sum(rest.values()),
            "von": len(norm(vorrat)),
        }

    item["input_type"] = input_type(item["parts"])
    auto, voll = grade(item)
    item["auto_gradebar"] = auto
    item["vollstaendig"] = voll
    item["lsa_pool_kandidat"] = auto and voll
    item["_flags_blockierend"] = blockierend(item["_flags"])
    return item, befunde


def main():
    alt = slug_map()
    items, befunde = [], []
    for f in sorted(EXTRACT.glob("*.json")):
        rec = json.loads(f.read_text(encoding="utf-8"))
        slug = canon(rec["item"])
        vf = VISION / f"{rec['item']}.json"
        vis = json.loads(vf.read_text(encoding="utf-8")) if vf.exists() else {}
        if not vf.exists():
            vis = {"parts": [], "unsicher": []}
        it, b = build(slug, rec, vis, alt.get(slug))
        if not vf.exists():
            it["_flags"].append("keine Vision-Lesung -> Stamm/Prompts fehlen")
            it["vollstaendig"] = False
            it["auto_gradebar"] = False
        items.append(it)
        befunde += b

    # Items der Alt-JSON ohne Quelldateien duerfen nicht verschwinden.
    haben = {i["slug"] for i in items}
    for slug, a in alt.items():
        if slug not in haben:
            items.append({
                "id": a["id"], "slug": slug, "titel": a["titel"],
                "quelle": "VERA8_IQB", "klasse": a.get("klasse", 8),
                "status": "draft", "is_diagnostic": True, "input_type": None,
                "stem": {"text": "", "table": None}, "parts": [], "assets": [],
                "_grounding": {}, "_flags": ["keine Quelldatei im Repo"],
                "auto_gradebar": False, "vollstaendig": False,
            })
    for a in json.loads(ALT.read_text(encoding="utf-8")):
        if not (a.get("iqb_urls") or {}).get("aufgabe"):
            items.append({
                "id": a["id"], "slug": None, "titel": a["titel"],
                "quelle": "VERA8_IQB", "klasse": a.get("klasse", 8),
                "status": "draft", "is_diagnostic": True, "input_type": None,
                "stem": {"text": "", "table": None}, "parts": [], "assets": [],
                "_grounding": {},
                "_flags": ["keine Quelle (iqb_urls leer) -> nicht extrahierbar"],
                "auto_gradebar": False, "vollstaendig": False,
            })

    OUT.write_text(json.dumps(items, ensure_ascii=False, indent=1),
                   encoding="utf-8")
    BEFUNDE.write_text(json.dumps(befunde, ensure_ascii=False, indent=1),
                       encoding="utf-8")

    n_ok = sum(1 for b in befunde if b["ok"])
    auto = sum(1 for i in items if i["auto_gradebar"])
    voll = sum(1 for i in items if i["vollstaendig"])
    pool = [i for i in items if i.get("lsa_pool_kandidat")]
    unsicher = sum(1 for i in pool
                   if any(f.startswith("Vision unsicher") for f in i["_flags"]))
    lizenz_warn = sum(1 for i in pool
                      if any(f.startswith("G7") for f in i["_flags"]))
    print(f"Items: {len(items)}  (Status: alle 'draft')")
    print(f"Grounding-Checks: {n_ok} belegt, {len(befunde) - n_ok} ohne Beleg")
    print(f"auto-gradebar: {auto}")
    print(f"vollstaendig (Stamm+Loesung+Belege, kein blockierendes Flag): {voll}")
    print(f"LSA-Pool (auto-gradebar UND vollstaendig): {len(pool)}")
    print(f"  davon mit Vision-Zweifel: {unsicher}")
    print(f"  davon mit nicht gedeckter Grafik (G7): {lizenz_warn}")
    print(f"Items mit blockierendem Flag: "
          f"{sum(1 for i in items if i.get('_flags_blockierend'))}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
