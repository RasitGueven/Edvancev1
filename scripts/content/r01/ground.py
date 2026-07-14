"""R01 — Stufe 3 (GROUNDING). Hart.

Regel: Kein woertlicher Beleg aus der Quelle, kein Feld.

Konkret geprueft wird:

G1  Stamm/Prompt/Option gegen den ZEICHENVORRAT des EMF (Multimenge). Die
    Vision darf die Lesereihenfolge bestimmen — das ist ihr Job, denn die
    Reihenfolge steht im EMF nicht drin. Sie darf aber kein Zeichen erfinden.
    Steht ein Zeichen nicht im Vorrat, faellt das Feld.

G2  Loesung gegen die AUSWERTUNG, woertlich. Eine Loesung, die nicht als
    Zeichenkette in einer Auswertungszelle steht, wird nicht geschrieben.

G3  MC-Ordinalregel. Sagt die Auswertung "3. Kaestchen wurde angekreuzt", dann
    ist die Loesung die 3. Option in VISUELLER Reihenfolge (x-Ordnung der
    Kaestchen im EMF). Genau hier ist die alte Pipeline gestorben: bei
    zerfallener Reihenfolge zeigt das Ordinal auf die falsche Option.

G4  Einheiten. P01/DATENVERTRAG §3: keine Einheiten-Umrechnung. Der
    "[Anm.: ...]"-Block der Auswertung ist Kodierhinweis fuer Menschen, keine
    Liste maschinell akzeptierter Antworten. Er wird NICHT zu correct_answers.

G5  Tabellen bleiben Tabellen. Pipe-Fliesstext ist ein Fehler, kein Format.

G6  Restzeichen. G1 faengt Erfundenes, aber nichts Ausgelassenes: eine Lesung,
    der ein Zeichen FEHLT, ist immer noch eine Teilmenge des Vorrats. Genau so
    ist "2 1/2 Stunden" zu "2 Stunden" geworden. Deshalb wird zusaetzlich
    berichtet, welche Inhaltszeichen der Quelle in KEINEM Feld gelandet sind.
    Kein harter Stopp (Beschriftungen in Abbildungen bleiben legitim uebrig),
    aber ein sichtbarer Rest, den ein Mensch pruefen kann.

Ausgabe: data/r01_ergebnis.json + Befund je Feld (ok / GEFLAGGT).
"""
import json
import re
import sys
import unicodedata
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
EXTRACT = ROOT / "data/r01_extract"
VISION = ROOT / "data/r01_vision.json"
OUT = ROOT / "data/r01_ergebnis.json"

# Was die Vision als ein Zeichen liest, steht im EMF als mehrere Records:
# Ein Bruch ist Zaehler + Bruchstrich(Linie) + Nenner, eine Hochzahl ist eine
# normale Ziffer auf hoeherer Grundlinie. Fuer den Vorratsabgleich wird das
# zurueckgefaltet — sonst wuerde die Pipeline korrekt Gelesenes verwerfen.
UNFOLD = {
    "½": "12", "¼": "14", "¾": "34", "⅓": "13", "⅔": "23",
    "²": "2", "³": "3", "¹": "1", "⁰": "0", "⁴": "4",
    "–": "-", "—": "-", "−": "-", "’": "'", "“": '"', "”": '"',
}


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


def g1_vorrat(claim, vorrat):
    """Jedes Zeichen der Lesung muss im EMF-Vorrat sein (als Multimenge)."""
    need, have = Counter(norm(claim)), Counter(norm(vorrat))
    missing = need - have
    return (not missing), "".join(sorted(missing.elements()))


def g2_beleg(value, cells):
    """Woertlicher Beleg in einer Auswertungszelle."""
    v = norm_text(value)
    for c in cells:
        if v and v in norm_text(c):
            return True, c
    return False, None


ORDINAL = re.compile(r"(\d+)\s*\.\s*K[äa]stchen")

# Der CC-Lizenzblock ist ein eigenes EMF auf jeder Seite. Er gehoert nicht zum
# Aufgabentext — und sein Zeichenvorrat darf auch nicht als Beleg fuer einen
# Aufgabentext herhalten. Sonst koennte sich eine erfundene Lesung ihre
# Buchstaben aus der Lizenzzeile borgen.
LICENSE = re.compile(r"creativecommons|creative commons|licenses/by|\(cc by\)|copyright",
                     re.I)


def is_license(emf):
    return bool(LICENSE.search(emf["tokens"]))


def main():
    vision = json.loads(VISION.read_text(encoding="utf-8"))["items"]
    ergebnis, befunde = {}, []

    for item, v in vision.items():
        rec = json.loads((EXTRACT / f"{item}.json").read_text(encoding="utf-8"))
        emfs = rec["stufe2_aufgabe_emf"]
        inhalt_emfs = [e for e in emfs if not is_license(e)]
        vorrat = "".join(e["tokens"] for e in inhalt_emfs)
        verbraucht = []  # was in ein Feld gewandert ist -> fuer G6
        cells = [c for t in rec["stufe1_auswertung"]["tables"]
                 for row in t["cells"] for c in row]
        richtig = [row[1] for t in rec["stufe1_auswertung"]["tables"]
                   for row in t["cells"]
                   if len(row) > 1 and row[0].strip().upper() == "RICHTIG"]

        out = {"item": item, "input_type": v["input_type"], "parts": [],
               "assets": [], "flags": []}

        def check(label, claim, gate="G1"):
            ok, missing = g1_vorrat(claim, vorrat)
            befunde.append({"item": item, "feld": label, "gate": gate,
                            "ok": ok, "wert": claim,
                            "fehlende_zeichen": missing if not ok else ""})
            if ok:
                verbraucht.append(claim)
            return ok

        # --- Stamm (G1) ---
        if v.get("stem"):
            if check("stem", v["stem"]):
                out["stem"] = v["stem"]
            else:
                out["flags"].append("stem ohne Beleg im EMF-Vorrat -> leer gelassen")
                out["stem"] = ""
        else:
            out["stem"] = ""

        # --- Tabelle im Stamm (G5) ---
        for e in emfs:
            if e["table"]:
                out["assets"].append({
                    "kind": "table", "quelle": e["emf"], "png": e["png"],
                    "header": e["table"]["header"], "rows": e["table"]["rows"],
                })
        if v.get("stem_tabelle_erwartet") and not out["assets"]:
            out["flags"].append("G5: Tabelle erwartet, aber keine strukturierte "
                                "Tabelle rekonstruiert")

        # --- Teilaufgaben ---
        for i, part in enumerate(v["parts"]):
            p = {"nr": part["nr"], "kind": part["kind"]}
            if check(f"part{part['nr']}.prompt", part["prompt"]):
                p["prompt"] = part["prompt"]
            else:
                p["prompt"] = ""
                out["flags"].append(f"Teilaufgabe {part['nr']}: Prompt ohne Beleg "
                                    f"-> leer gelassen")

            if part.get("unit"):
                if check(f"part{part['nr']}.unit", part["unit"]):
                    p["unit"] = part["unit"]
                else:
                    out["flags"].append(f"Teilaufgabe {part['nr']}: Einheit "
                                        f"{part['unit']!r} ohne Beleg -> verworfen")

            # Optionen (G1) — Reihenfolge ist die visuelle x-Ordnung.
            if part["kind"] == "mc":
                opts = []
                for o in part["options"]:
                    if check(f"part{part['nr']}.option[{o['id']}]", o["label"]):
                        opts.append(o)
                    else:
                        out["flags"].append(f"Option {o['id']!r} ohne Beleg")
                p["options"] = opts

            # --- Loesung (G2/G3/G4) ---
            zelle = richtig[i] if i < len(richtig) else None
            if zelle is None:
                out["flags"].append(f"Teilaufgabe {part['nr']}: keine "
                                    f"RICHTIG-Zelle -> keine Loesung")
                out["parts"].append(p)
                continue

            m = ORDINAL.search(zelle)
            if m and part["kind"] == "mc":
                # G3: Ordinal gegen die visuelle Reihenfolge aufloesen.
                n = int(m.group(1))
                if 1 <= n <= len(p.get("options", [])):
                    opt = p["options"][n - 1]
                    p["correct_answers"] = [opt["id"]]
                    p["_beleg_loesung"] = {
                        "gate": "G3",
                        "auswertung_zelle": zelle,
                        "ordinal": n,
                        "aufgeloest_auf": opt["label"],
                        "reihenfolge": part.get("options_reihenfolge", ""),
                    }
                    befunde.append({"item": item, "feld": f"part{part['nr']}.loesung",
                                    "gate": "G3", "ok": True,
                                    "wert": f"{n}. Kaestchen -> {opt['label']} "
                                            f"(id={opt['id']})",
                                    "fehlende_zeichen": ""})
                else:
                    out["flags"].append(f"G3: Ordinal {n} zeigt ins Leere "
                                        f"(nur {len(p.get('options', []))} Optionen) "
                                        f"-> keine Loesung")
            else:
                # G2/G4: nur der Wert vor dem Kodierhinweis, woertlich belegt.
                # "[Anm.: ...]" und "Beispiel(e)/(Grenzfall)" sind Hinweise fuer
                # menschliche Kodierer, keine maschinell akzeptierten Antworten.
                haupt = re.split(r"\[Anm\.|Beispiel\(e\)", zelle)[0].strip()
                kandidaten = [x.strip() for x in haupt.splitlines() if x.strip()]
                akzeptiert = []
                for k in kandidaten:
                    ok, beleg = g2_beleg(k, cells)
                    if ok:
                        akzeptiert.append(k)
                    befunde.append({"item": item, "feld": f"part{part['nr']}.loesung",
                                    "gate": "G2", "ok": ok, "wert": k,
                                    "fehlende_zeichen": ""})
                if akzeptiert:
                    p["correct_answers"] = akzeptiert
                    p["_beleg_loesung"] = {"gate": "G2", "auswertung_zelle": zelle}
                else:
                    out["flags"].append(f"Teilaufgabe {part['nr']}: Loesung ohne "
                                        f"woertlichen Beleg -> NICHT geschrieben")

                if "[Anm." in zelle and re.search(r"anderer Einheit", zelle):
                    p["_g4_einheiten"] = (
                        "Umrechnungsvarianten aus dem [Anm.]-Block bewusst NICHT "
                        "als correct_answers uebernommen (P01: keine "
                        "Einheiten-Umrechnung; Einheit steht im Feld 'unit').")

            out["parts"].append(p)

        # --- G6: Restzeichen ---
        for a in out["assets"]:
            verbraucht += a["header"] + [c for r in a["rows"] for c in r]
        rest = Counter(norm(vorrat)) - Counter(norm("".join(verbraucht)))
        out["_g6_restzeichen"] = "".join(sorted(rest.elements()))
        befunde.append({
            "item": item, "feld": "_restzeichen", "gate": "G6", "ok": True,
            "wert": f'{sum(rest.values())} von {len(norm(vorrat))} Inhaltszeichen '
                    f'in keinem Feld',
            "fehlende_zeichen": "",
        })

        ergebnis[item] = out

    OUT.write_text(json.dumps({"items": ergebnis, "befunde": befunde},
                              ensure_ascii=False, indent=2), encoding="utf-8")

    n_ok = sum(1 for b in befunde if b["ok"])
    n_bad = len(befunde) - n_ok
    for b in befunde:
        if not b["ok"]:
            print(f'  GEFLAGGT {b["item"]}/{b["feld"]} ({b["gate"]}): '
                  f'fehlende Zeichen {b["fehlende_zeichen"]!r}')
    flags = [(k, f) for k, o in ergebnis.items() for f in o["flags"]]
    for k, f in flags:
        print(f"  FLAG {k}: {f}")
    print(f"\nGrounding-Checks: {n_ok} belegt, {n_bad} ohne Beleg. "
          f"Item-Flags: {len(flags)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
