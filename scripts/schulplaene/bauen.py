#!/usr/bin/env python3
"""Baut aus schulen.json und plaene/<slug>.json die Migration 3 und die CSV.

    python3 scripts/schulplaene/bauen.py <migrationsdatei>

Eingaben
  schulen.json         43 Gymnasien (Stadt Koeln), Stand, Plan-URLs
  plaene/<slug>.json   je Schule mit Plan: {"eintraege": [{klasse, position,
                       uv_titel, stunden, halbjahr, thema_key, quelle_url}],
                       "befunde": ["..."]}
  Themenkatalog        thema_keys und schlagworte aus Migration 2

Ausgaben
  <migrationsdatei>            schulen, schul_themenplan, Schlagwort-Nachtraege
  docs/themen/schulplaene.csv  eine Zeile je Unterrichtsvorhaben

Bricht ab bei unbekanntem thema_key, Luecken in den Positionen oder fehlender
quelle_url. Uebernommen werden nur Titel, Reihenfolge, Stunden, Halbjahr.
"""

import csv
import json
import re
import sys
from pathlib import Path

HIER = Path(__file__).resolve().parent
REPO = HIER.parent.parent
KATALOG = REPO / "supabase/migrations/20261001123005_themen_katalog_mathe.sql"
CSV_ZIEL = REPO / "docs/themen/schulplaene.csv"
BEFUND_ZIEL = REPO / "docs/themen/befunde-daten.md"

# Wiederkehrende Mischtitel aus dem Muster-Lehrplan (QUA-LiS) wurden von den
# Auslese-Durchgaengen unterschiedlich zugeordnet. Eine Regel fuer alle Schulen;
# jede Aenderung landet in befunde-daten.md.
HARMONISIERUNG = [
    (re.compile(r"kreise?,? prismen,? (und )?zylinder", re.I), None, "kreis",
     "Musterplan-UV Kreise/Prismen/Zylinder: Kreis zuerst genannt und Einstieg fuer Kinder (pi)"),
    (re.compile(r"^(stochastik: )?daten (und|&) wahrscheinlichkeit", re.I), (9, 10), "bedingte_wahrscheinlichkeit",
     "Musterplan-UV Daten und Wahrscheinlichkeit Kl. 9/10: Schwerpunkt Vierfeldertafel/bedingte Wkt."),
    (re.compile(r"muster und figuren", re.I), (6,), "winkel",
     "Musterplan-UV Muster und Figuren Kl. 6: Kreis, Winkel, Drehungen; Mehrheit 9 zu 7, Zweitpruefung ebenso"),
]
FACH = "mathematik"
MAX_SCHLAGWORTE = 15


def katalog() -> dict[str, list[str]]:
    sql = KATALOG.read_text()
    zeilen = re.findall(
        r"\('([a-z_]+)', 'mathematik', \d+, '\w+', \d+, '[^']+',\s*'\{[^}]*\}',\s*'\{([^}]*)\}'\)",
        sql,
    )
    return {k: w.split(",") for k, w in zeilen}


def q(wert) -> str:
    if wert is None:
        return "null"
    if isinstance(wert, int):
        return str(wert)
    return "'" + str(wert).replace("'", "''") + "'"


def falten(text: str) -> str:
    text = text.lower()
    for a, b in (("ä", "ae"), ("ö", "oe"), ("ü", "ue"), ("ß", "ss")):
        text = text.replace(a, b)
    return text


ZU_ALLGEMEIN = {"zahlen", "rechnen", "terme", "flächen", "zahlen und größen", "funktionen", "geometrie"}


def schlagwort_aus_titel(titel: str) -> str:
    """Sachteil eines Vorhabentitels als Schlagwort.

    "Raus aus den Schulden: Rechnen mit rationalen Zahlen" → "rechnen mit
    rationalen zahlen". Bereichs-Praefixe ("Geometrie:") und Mottos vor dem
    letzten Doppelpunkt fallen weg, ebenso Klammerzusaetze ("(optional)").
    """
    t = titel.lower().split(":")[-1]
    t = re.sub(r"\([^)]*\)?", "", t)
    t = re.sub(r"\s+", " ", t).strip(" .?!–-")
    if len(t) < 4 or len(t) > 50 or t in ZU_ALLGEMEIN:
        return ""
    return t


def pruefen(slug: str, eintraege: list[dict], keys: set[str]) -> None:
    je_klasse: dict[int, list[int]] = {}
    for e in eintraege:
        if e.get("thema_key") is not None and e["thema_key"] not in keys:
            sys.exit(f"{slug}: unbekannter thema_key {e['thema_key']}")
        if not e.get("quelle_url"):
            sys.exit(f"{slug}: quelle_url fehlt bei {e}")
        if not 5 <= e["klasse"] <= 10:
            sys.exit(f"{slug}: klasse {e['klasse']} ausserhalb 5-10")
        je_klasse.setdefault(e["klasse"], []).append(e["position"])
    for klasse, pos in je_klasse.items():
        if sorted(pos) != list(range(1, len(pos) + 1)):
            sys.exit(f"{slug}: Positionen Kl. {klasse} nicht lueckenlos ab 1: {sorted(pos)}")


def harmonisieren(slug: str, eintraege: list[dict], log: list[str]) -> None:
    for e in eintraege:
        for muster, klassen, key, grund in HARMONISIERUNG:
            if muster.search(e["uv_titel"]) and (klassen is None or e["klasse"] in klassen):
                if e.get("thema_key") != key:
                    log.append(f"{slug} Kl. {e['klasse']} Pos. {e['position']} '{e['uv_titel']}': "
                               f"{e.get('thema_key')} → {key} ({grund})")
                    e["thema_key"] = key


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    ziel = Path(sys.argv[1])
    schulen = json.loads((HIER / "schulen.json").read_text())
    themen = katalog()
    plaene: dict[str, dict] = {}
    harm_log: list[str] = []
    for s in schulen:
        datei = HIER / "plaene" / f"{s['slug']}.json"
        if datei.exists():
            plaene[s["slug"]] = json.loads(datei.read_text())
            harmonisieren(s["slug"], plaene[s["slug"]]["eintraege"], harm_log)
            pruefen(s["slug"], plaene[s["slug"]]["eintraege"], set(themen))

    # Schlagwort-Nachtraege: neue Vorhabentitel beim zugeordneten Thema, solange
    # das Thema unter MAX_SCHLAGWORTE bleibt und der Titel nicht schon per
    # Praefix von einem vorhandenen Schlagwort abgedeckt ist.
    nachtrag: dict[str, list[str]] = {}
    for p in plaene.values():
        for e in p["eintraege"]:
            k = e.get("thema_key")
            w = schlagwort_aus_titel(e["uv_titel"])
            if not k or not w:
                continue
            vorhanden = themen[k] + nachtrag.get(k, [])
            if any(falten(w).startswith(falten(v)) or falten(v) == falten(w) for v in vorhanden):
                continue
            if len(vorhanden) >= MAX_SCHLAGWORTE:
                continue
            nachtrag.setdefault(k, []).append(w)

    out = [
        "-- ============================================================================",
        "-- Koelner Gymnasien und ihre Mathe-Schulplaene (W1-4, Migration 3 von 3 — Daten)",
        "-- ============================================================================",
        "--",
        "-- Erzeugt von scripts/schulplaene/bauen.py — nicht von Hand aendern.",
        "-- Schulen: alphabetische Liste der Gymnasien der Stadt Koeln",
        "-- https://www.stadt-koeln.de/leben-in-koeln/bildung-und-schule/schulformen/alphabetische-liste-der-gymnasien",
        "-- Aus den Plaenen uebernommen: nur Titel der Unterrichtsvorhaben, ihre",
        "-- Reihenfolge, Stunden und Halbjahr; Quelle je Zeile in quelle_url.",
        "-- Befunde (nicht abrufbar, unvollstaendig, nicht zuordenbar): docs/themen/befunde.md",
        "",
        "insert into public.schulen (name, ort, schulform, stadtteil, traeger, website) values",
        ",\n".join(
            f"  ({q(s['name'])}, 'Köln', 'Gymnasium', {q(s['stadtteil'])}, {q(s['traeger'])}, {q(s['website'])})"
            for s in schulen
        ),
        "on conflict (lower(name), coalesce(ort, '')) do update",
        "   set schulform = excluded.schulform,",
        "       stadtteil = excluded.stadtteil,",
        "       traeger   = excluded.traeger,",
        "       website   = excluded.website;",
        "",
        "-- Wiederholbar: der Mathe-Plan dieser Schulen wird komplett ersetzt.",
        "delete from public.schul_themenplan sp",
        " using public.schulen s",
        f" where sp.schule_id = s.id and s.ort = 'Köln' and sp.fach = {q(FACH)}",
        "   and s.name in (" + ", ".join(q(s["name"]) for s in schulen) + ");",
        "",
    ]
    werte = []
    zeilen_csv = []
    for s in schulen:
        p = plaene.get(s["slug"])
        if not p:
            continue
        for e in sorted(p["eintraege"], key=lambda e: (e["klasse"], e["position"])):
            werte.append(
                f"  ({q(s['name'])}, {e['klasse']}, {e['position']}, {q(e.get('thema_key'))}, "
                f"{q(e['uv_titel'])}, {q(e.get('stunden'))}, {q(e.get('halbjahr'))}, "
                f"{q(e['quelle_url'])}, {q(s.get('stand'))})"
            )
            zeilen_csv.append([s["name"], e["klasse"], e["position"], e["uv_titel"],
                               e.get("thema_key") or "", e.get("stunden") or "",
                               e.get("halbjahr") or "", e["quelle_url"]])
    out += [
        "insert into public.schul_themenplan",
        "  (schule_id, fach, klasse, position, thema_key, uv_titel, stunden, halbjahr, quelle_url, stand)",
        f"select s.id, {q(FACH)}, v.klasse, v.position, v.thema_key, v.uv_titel, v.stunden, v.halbjahr, v.quelle_url, v.stand",
        "  from (values",
        ",\n".join(werte),
        "  ) as v (schule, klasse, position, thema_key, uv_titel, stunden, halbjahr, quelle_url, stand)",
        "  join public.schulen s on lower(s.name) = lower(v.schule) and s.ort = 'Köln';",
        "",
        "-- Neue Vorhabentitel als Schlagworte (nur fehlende, hoechstens "
        f"{MAX_SCHLAGWORTE} je Thema).",
    ]
    for k, neu in sorted(nachtrag.items()):
        arr = "array[" + ", ".join(q(w) for w in neu) + "]"
        out.append(
            f"update public.themen set schlagworte = schlagworte || array(select w from unnest({arr}) w "
            f"where w <> all(schlagworte)) where thema_key = {q(k)};"
        )
    ziel.write_text("\n".join(out) + "\n")

    CSV_ZIEL.parent.mkdir(parents=True, exist_ok=True)
    with CSV_ZIEL.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["schule", "klasse", "position", "uv_titel", "thema_key", "stunden", "halbjahr", "quelle_url"])
        w.writerows(zeilen_csv)
    befunde_schreiben(schulen, plaene, harm_log)
    print(f"{len(harm_log)} harmonisiert. {len(schulen)} Schulen, {len(plaene)} mit Plan, {len(werte)} Vorhaben, "
          f"{sum(len(v) for v in nachtrag.values())} neue Schlagworte")


def befunde_schreiben(schulen: list[dict], plaene: dict[str, dict], harm_log: list[str]) -> None:
    z = ["# Befunde aus den Schulplaenen (erzeugt von scripts/schulplaene/bauen.py)", ""]
    z += ["## Schulen ohne auswertbaren Plan", ""]
    for s in schulen:
        if not plaene.get(s["slug"], {}).get("eintraege"):
            z.append(f"- {s['name']}: {s['status']}")
    z += ["", "## Abdeckung Kl. 5–10 (Pflicht laut Pruefung: 5–8)", ""]
    for s in schulen:
        p = plaene.get(s["slug"])
        if not p or not p["eintraege"]:
            continue
        da = sorted({e["klasse"] for e in p["eintraege"]})
        fehlt = [k for k in range(5, 11) if k not in da]
        if fehlt:
            pflicht = " — **Kl. 5–8 unvollstaendig**" if any(k <= 8 for k in fehlt) else ""
            z.append(f"- {s['name']}: fehlt Kl. {', '.join(map(str, fehlt))}{pflicht}")
    z += ["", "## Nicht zuordenbar (thema_key NULL)", ""]
    for s in schulen:
        for e in plaene.get(s["slug"], {}).get("eintraege", []):
            if e.get("thema_key") is None:
                z.append(f"- {s['name']}, Kl. {e['klasse']} Pos. {e['position']}: {e['uv_titel']}")
    z += ["", "## Harmonisierte Zuordnungen", ""] + [f"- {h}" for h in harm_log]
    z += ["", "## Befunde je Schule (aus der Auslese)", ""]
    for s in schulen:
        b = plaene.get(s["slug"], {}).get("befunde", [])
        if b:
            z.append(f"### {s['name']}")
            z += [f"- {x}" for x in b] + [""]
    BEFUND_ZIEL.write_text("\n".join(z) + "\n")


if __name__ == "__main__":
    main()
