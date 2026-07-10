"""C02 Phase 2 - belegte Inhalte in den Pool schreiben.

Jedes befuellte Feld bekommt einen `_grounding`-Eintrag mit Quelldatei und
woertlichem Zitat. Felder ohne Beleg bleiben leer und bekommen einen Eintrag
in `_problems`. Es wird nichts ergaenzt, geglaettet oder geraten.

Quellen je Feld:
  aufgabe_text           <- EMF-Textrecords der Aufgabendatei (Phase 1)
  akzeptierte_antworten  <- RICHTIG-Zellen der Auswertung
  loesung_pro_ta         <- dito, je Teilaufgabe
  kodierung              <- dito, woertliche Zelle
  typische_fehler        <- Fehlerabsaetze der Didaktischen Kommentierung
  teilaufgaben.afb/stufe <- Merkmale-Tabellen der Kommentierung
"""
import json
import os
import sys
import zipfile

sys.path.insert(0, os.path.dirname(__file__))
import c02_auswertung  # noqa: E402
import c02_kommentierung  # noqa: E402
from emf_text import emf_to_text, is_license_emf  # noqa: E402
from vera_lib import files_of, load_items, save_items, slug_of  # noqa: E402

STEMS = "data/c02_stems.json"
REPORT = "data/c02_phase2_report.json"


def emf_formeln(path):
    """Formeltexte aus den EMF einer Auswertungsdatei (Beleg-Kandidaten)."""
    if not path or not path.endswith(".docx"):
        return []
    out = []
    with zipfile.ZipFile(path) as zf:
        for name in sorted(x for x in zf.namelist() if x.endswith(".emf")):
            data = zf.read(name)
            if is_license_emf(data):
                continue
            text = emf_to_text(data)
            if text:
                out.append({"medium": name.split("/")[-1], "text": text})
    return out


def stamm(stems, slug):
    teile = [t["text"] for t in stems.get(slug, {}).get("teile", [])]
    return "\n\n".join(teile), teile


def main():
    items = load_items()
    stems = json.load(open(STEMS))
    report = {"ohne_stamm": [], "ohne_antwort": [], "nur_formelgrafik": [],
              "freitext_loesung": [], "ta_anzahl_inkonsistent": []}

    for item in items:
        paths = files_of(item)
        slug = slug_of(item)
        grounding, problems = {}, []

        # --- Aufgabenstamm (Phase 1) --------------------------------------
        text, teile = stamm(stems, slug)
        if text:
            item["aufgabe_text"] = text
            item["aufgabe_teile"] = teile
            grounding["aufgabe_text"] = {
                "quelle": os.path.basename(paths["aufgabe"]),
                "methode": "emf_text_records",
                "zitat": text[:200],
            }
        else:
            problems.append("kein_stamm_extrahierbar")
            report["ohne_stamm"].append(item["titel"])

        # --- Loesungen aus der Auswertung ---------------------------------
        tas = c02_auswertung.parse(paths["auswertung"])
        formeln = emf_formeln(paths["auswertung"])
        loesungen, alle_antworten, kodierungen = [], [], []
        for ta in tas:
            problems += ["ta%s_%s" % (ta["nr"], p) for p in ta["_problems"]]
            if ta["akzeptierte_antworten"]:
                loesungen.append({
                    "nr": ta["nr"],
                    "loesung": ta["loesung"],
                    "akzeptierte_antworten": ta["akzeptierte_antworten"],
                    "kodierung": ta["kodierung"],
                })
                alle_antworten += ta["akzeptierte_antworten"]
            if ta["kodierung"]:
                kodierungen.append("Ta%s: %s" % (ta["nr"], ta["kodierung"]))

        if loesungen:
            item["loesung_pro_ta"] = loesungen
            item["akzeptierte_antworten"] = alle_antworten
            grounding["akzeptierte_antworten"] = [
                {"quelle": t["_grounding"]["quelle"], "zitat": t["_grounding"]["zitat"]}
                for t in tas if t["akzeptierte_antworten"]]
            grounding["loesung_pro_ta"] = grounding["akzeptierte_antworten"]
        else:
            report["ohne_antwort"].append(item["titel"])

        if any("zelle_leer" in p for p in problems) and formeln:
            problems.append("auswertung_loesung_nur_als_formelgrafik")
            item["_formel_kandidaten"] = formeln
            report["nur_formelgrafik"].append(item["titel"])
        if any("freitext" in p for p in problems):
            report["freitext_loesung"].append(item["titel"])

        if kodierungen:
            item.setdefault("diagnostik", {})["kodierung"] = "\n".join(kodierungen)
            grounding["kodierung"] = {
                "quelle": tas[0]["_grounding"]["quelle"],
                "zitat": kodierungen[0][:300],
            }

        # --- Typische Fehler aus der Kommentierung ------------------------
        kom = c02_kommentierung.parse(paths["kommentierung"])
        if kom["typische_fehler"]:
            item.setdefault("diagnostik", {})["typische_fehler"] = kom["typische_fehler"]
            grounding["typische_fehler"] = {
                "quelle": kom["quelle"],
                "zitat": kom["typische_fehler"][0][:300],
            }
        else:
            problems.append("keine_typischen_fehler_belegt")

        # --- Merkmale je Teilaufgabe --------------------------------------
        quelle_tas = kom["teilaufgaben"]
        eigene = item.get("teilaufgaben") or []
        if quelle_tas and len(quelle_tas) == len(eigene):
            for src, own in zip(quelle_tas, eigene):
                own["afb"] = src.get("afb", own.get("afb"))
                own["afb_raw"] = src.get("afb_raw")
                own["k_tags"] = src.get("k_tags", [])
                own["kompetenzstufe"] = src.get("kompetenzstufe_raw")
                own["leitidee_raw"] = src.get("leitidee_raw")
            grounding["teilaufgaben"] = {
                "quelle": kom["quelle"],
                "zitat": "Leitidee=%r; Kompetenz=%r; AFB=%r" % (
                    quelle_tas[0].get("leitidee_raw"),
                    quelle_tas[0].get("kompetenz_raw"),
                    quelle_tas[0].get("afb_raw")),
            }
        elif quelle_tas:
            problems.append("ta_anzahl_inkonsistent")
            report["ta_anzahl_inkonsistent"].append(
                "%s: Item %d, Quelle %d" % (item["titel"], len(eigene), len(quelle_tas)))

        item["_grounding"] = grounding
        item["_problems"] = sorted(set(problems))

    save_items(items)
    json.dump(report, open(REPORT, "w"), ensure_ascii=False, indent=1)

    print("Items gesamt              : %d" % len(items))
    print("  mit Aufgabenstamm       : %d" % sum(1 for i in items if i.get("aufgabe_text")))
    print("  mit belegten Antworten  : %d" % sum(1 for i in items if i.get("akzeptierte_antworten")))
    print("  mit typischen Fehlern   : %d" % sum(1 for i in items if (i.get("diagnostik") or {}).get("typische_fehler")))
    print("  mit Kodierung           : %d" % sum(1 for i in items if (i.get("diagnostik") or {}).get("kodierung")))
    print()
    for key, rows in report.items():
        print("  %-24s %3d" % (key, len(rows)))
    print("\n-> %s" % REPORT)


if __name__ == "__main__":
    main()
