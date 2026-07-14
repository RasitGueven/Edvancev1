"""Negativkontrolle fuer die Gates, die erst der volle Bestand erzwungen hat.

test_gates.py prueft die sechs Gates des Kalibrierlaufs. Hier kommen die drei
Stellen dazu, an denen der Vollauf ueber 299 Items neue Wege aufgemacht hat —
und jeder neue Weg ist eine neue Gelegenheit, still das Falsche auszugeben:

  G0  Rasterquellen. 33 Items tragen ihren Text als Pixelbild. Dort gibt es
      keinen Zeichenvorrat. Ein Gate, das mangels Daten durchwinkt, ist kein
      Gate — es MUSS 'ungeprueft' sagen.
  G7  Lizenz. Die Grafik ist nur dann von CC BY gedeckt, wenn die Lizenzzeile
      des Items das Wort 'Grafik' nennt.
  OLE Die 74 .doc-Items. Sie waren im Altbestand 'doc_pending' — nie extrahiert.

    python3 test_scale.py
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ground_all import LAYOUT_ZEICHEN, g1, g1b, norm
from ole import media_in_doc
from pipeline import _is_license, lizenz

ROOT = Path(__file__).resolve().parents[3]
EXTRACT = ROOT / "data/r01_extract"
DOCS = ROOT / "data/vera8_docs"
V2 = ROOT / "data/vera8_v2.json"

FAILS = []


def check(name, bedingung, detail=""):
    print(f'  {"OK  " if bedingung else "FAIL"}  {name}'
          f'{"  — " + detail if detail else ""}')
    if not bedingung:
        FAILS.append(name)


def rec(item):
    return json.loads((EXTRACT / f"{item}.json").read_text(encoding="utf-8"))


def main():
    print("NC8 — Lizenzerkennung trennt Lizenzblock von Aufgabentext")
    # Der Stamm von 'holzwuerfel' traegt die Bildunterschrift "Grafik: © IQB"
    # MITTEN im Aufgaben-EMF. Eine zu weite Lizenzerkennung wirft genau diesen
    # Stamm weg — und damit die Aufgabe. Das ist waehrend des Baus passiert.
    check("Bildunterschrift 'Grafik: © IQB' ist KEIN Lizenzblock",
          not _is_license("Ein gelber Holzwürfel ... Beispiel: gelb blau rot "
                          "Grafik: © IQB"))
    check("die echte CC-Zeile IST ein Lizenzblock",
          _is_license("Copyright Text und Teilaufgaben: IQB e. V., Lizenz: "
                      "Creative Commons (CC BY)."))
    hw = rec("holzwuerfel")
    stamm_emf = [e for e in hw["stufe2_aufgabe_emf"] if not e.get("is_license")]
    check("holzwuerfel behaelt sein Inhalts-EMF", len(stamm_emf) >= 1,
          f"{len(stamm_emf)} Inhalts-EMF(s)")

    print("\nNC9 — G7: 'Grafik' in der Lizenzzeile entscheidet")
    ohne = lizenz([{"is_license": True, "tokens":
                    "Copyright Text und Teilaufgaben: IQB e. V., Lizenz: "
                    "Creative Commons (CC BY)."}])
    mit = lizenz([{"is_license": True, "tokens":
                   "Copyright Text, Grafik und Teilaufgaben: IQB e. V., Lizenz: "
                   "Creative Commons (CC BY)."}])
    check("Lizenz ohne 'Grafik' deckt die Grafik NICHT",
          ohne["grafik_gedeckt"] is False)
    check("Lizenz mit 'Grafik' deckt die Grafik", mit["grafik_gedeckt"] is True)
    check("fehlender Lizenzhinweis deckt NICHTS (kein stillschweigendes Ja)",
          lizenz([])["grafik_gedeckt"] is False)
    # Gegenprobe an der echten Quelle: zeitangabe nennt keine Grafik, holzwuerfel schon.
    check("zeitangabe (Quelle): Grafik nicht gedeckt",
          rec("zeitangabe")["lizenz"]["grafik_gedeckt"] is False)
    check("holzwuerfel (Quelle): Grafik gedeckt",
          rec("holzwuerfel")["lizenz"]["grafik_gedeckt"] is True)

    print("\nNC10 — OLE: die 74 .doc-Items sind wirklich lesbar")
    m = media_in_doc(DOCS / "700milliarden/700milliarden_Aufgabe.doc")
    check("700milliarden liefert mindestens ein Bild aus dem OLE-Container",
          len(m) >= 1, f"{len(m)} Bild(er)")
    r7 = rec("700milliarden")
    vorrat = "".join(e.get("tokens") or "" for e in r7["stufe2_aufgabe_emf"]
                     if not e.get("is_license"))
    check("der Aufgabentext steht im Zeichenvorrat",
          "700 Milliarden Dollar" in vorrat, vorrat[:60] + "…")
    ok, missing = g1("Schreibe diese Zahl in Ziffern.", vorrat)
    check("G1 belegt einen echten Satz aus dem .doc", ok)
    ok, _ = g1("Schreibe diese Zahl in Hexadezimal.", vorrat)
    check("G1 lehnt einen erfundenen Satz aus dem .doc ab", not ok)

    print("\nNC11 — G0: Rasterquellen werden NICHT als geprueft ausgegeben")
    items = json.loads(V2.read_text(encoding="utf-8"))
    raster = [i for i in items
              if (i.get("_quelle") or {}).get("zeichenvorrat", "").startswith("raster")]
    check("es gibt Rasteritems", len(raster) > 0, f"{len(raster)} Items")
    schlecht = [i["slug"] for i in raster
                if any(g.get("gate") == "G1" and g.get("ok")
                       for g in i["_grounding"].values())]
    check("kein Rasteritem behauptet einen G1-Beleg", not schlecht,
          f"Verstoesse: {schlecht[:3]}")
    ohne_flag = [i["slug"] for i in raster
                 if not any(f.startswith("G0") for f in i["_flags"])
                 and i["stem"]["text"]]
    check("jedes Rasteritem mit Stamm traegt das G0-Flag 'UNGEPRUEFT'",
          not ohne_flag, f"ohne Flag: {ohne_flag[:3]}")
    check("kein Rasteritem gilt als vollstaendig",
          not [i["slug"] for i in raster if i["vollstaendig"]])

    print("\nNC13 — G1 hat nach der Abschwaechung auf Inhaltszeichen noch Zaehne")
    # G1 vergleicht im Vollauf nur noch Buchstaben und Ziffern (ground_all.inhalt):
    # gezeichnete Kaestchen und Eingabelinien stehen nicht im Zeichenvorrat. Die
    # Negativkontrollen der Kalibrierung MUESSEN trotzdem weiter auffliegen —
    # sonst waere aus der Abschwaechung ein Loch geworden.
    z = rec("zeitangabe")
    vorrat = "".join(e.get("tokens") or "" for e in z["stufe2_aufgabe_emf"]
                     if not e.get("is_license"))
    ok, missing = g1("Wie viele Minuten sind 3 Stunden?", vorrat)
    check("G1 lehnt weiterhin '3 Stunden' ab", not ok, f"fehlt {missing!r}")
    ok, missing = g1("Wie viele Sekunden sind 2½ Stunden?", vorrat)
    check("G1 lehnt weiterhin 'Sekunden' ab", not ok, f"fehlt {missing!r}")
    ok, _ = g1("Wie viele Minuten sind 2½ Stunden?", vorrat)
    check("G1 nimmt die belegte Lesung an", ok)
    # Nur das Layoutzeichen isolieren: die WOERTER muessen aus dem Vorrat
    # stammen, sonst prueft der Test den Inhalt und nicht das Kaestchen.
    ok, _ = g1("☐ 60min ☐ 90min", vorrat)
    check("G1 stolpert NICHT ueber gezeichnete Kaestchen", ok)
    ok, _ = g1("Minuten ______ 150min", vorrat)
    check("G1 stolpert NICHT ueber gezeichnete Eingabelinien", ok)

    print("\nNC14 — die Layout-Whitelist von G1b ist eng")
    # G1b darf NUR reine Layoutzeichen durchwinken. Alles, was den Inhalt
    # aendern kann, muss weiterhin blockieren — sonst waere die Entschaerfung
    # ein Loch. 'Maedchenanteil' ist der Zeuge: 8 statt 8/23.
    layout, bedeutung = g1b("Minuten ______ 150min", vorrat)
    check("Antwortlinie ist eine Notiz", layout == "_" * 6 and not bedeutung)
    layout, bedeutung = g1b("☐ 60min", vorrat)
    check("Ankreuzfeld ist eine Notiz", layout == "☐" and not bedeutung)
    _, bedeutung = g1b("8/23 Minuten", vorrat)
    check("Bruchstrich blockiert weiter", "/" in bedeutung)
    _, bedeutung = g1b("1,5 Minuten", vorrat)
    check("Dezimalkomma blockiert weiter", "," in bedeutung)
    _, bedeutung = g1b("10^6 Minuten", vorrat)
    check("Exponent blockiert weiter", "^" in bedeutung)
    _, bedeutung = g1b("60 * 3 Minuten", vorrat)
    check("Malzeichen blockiert weiter", "*" in bedeutung)
    check("die Whitelist enthaelt nichts Bedeutungstragendes",
          not (LAYOUT_ZEICHEN & set("/,.*^-()|:;")),
          f"Whitelist: {''.join(sorted(LAYOUT_ZEICHEN))!r}")

    print("\nNC15 — der Bau hat JEDE vorhandene Vision-Lesung verbaut")
    # Der Bug, der 22 fertige Lesungen gekostet hat: ground_all lief, waehrend
    # die Vision-Stufe noch schrieb. Die Lesungen lagen auf der Platte, der Bau
    # hat sie nie gesehen — und niemand hat es gemerkt, weil das Item einfach
    # "keine Teilaufgabe gelesen" hiess, so als waere nie gelesen worden.
    # Ein Bau, der eine vorhandene Lesung ignoriert, ist ab jetzt ein Fehler.
    vision = ROOT / "data/r01_vision"
    ignoriert = []
    for i in items:
        if i["parts"] or not i.get("slug"):
            continue
        f = vision / f"{i['slug']}.json"
        if not f.exists():
            continue
        v = json.loads(f.read_text(encoding="utf-8"))
        if v.get("parts"):
            ignoriert.append(f"{i['slug']} ({len(v['parts'])} Ta)")
    check("keine Vision-Lesung liegt unverbaut herum", not ignoriert,
          f"ignoriert: {ignoriert[:5]}" if ignoriert
          else f"{len(list(vision.glob('*.json')))} Lesungen, alle verbaut")

    print("\nNC12 — Status: kein Item kommt auf 'ready'")
    check("alle Items stehen auf 'draft'",
          all(i["status"] == "draft" for i in items),
          f"{len(items)} Items")
    check("die Alt-JSON ist unangetastet (kein 'draft'-Leak dorthin)",
          all(a["status"] != "draft" for a in json.loads(
              (ROOT / "data/vera8_komplett_enriched.json")
              .read_text(encoding="utf-8"))))

    print()
    if FAILS:
        print(f"NICHT BESTANDEN — {len(FAILS)} Kontrolle(n) gescheitert: {FAILS}")
        return 1
    print("Alle Negativkontrollen des Vollaufs bestanden.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
