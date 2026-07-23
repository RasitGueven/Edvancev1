#!/usr/bin/env python3
"""
Erzeugt docs/sondierrang_vorschlag.md — die Entscheidungsvorlage fuer den
sondierrang der Fundament-Aufgaben.

    python3 scripts/content/sondierrang_vorschlag.py

Das Skript SETZT KEINEN RANG. sondierrang ist Handarbeit (Rasit/Lena); hier
entsteht nur die Liste, aus der sich Rang 1 und 2 sinnvoll waehlen lassen.

WAS DIE SORTIERUNG TRAEGT — und was nicht:

Der Auftrag wollte "kontextfrei zuerst". Gemessen: KEINE der 146
Fundament-Aufgaben traegt einen Sachkontext. Alle sind nackte Rechnungen, der
laengste Fragetext besteht aus Arbeitsanweisung plus Term. Das Kriterium kann
also nichts unterscheiden — es waere eine Sortierung, die so tut, als haette sie
etwas gesehen.

Was unterscheidet, ist das FEHLBILDPROFIL: welche Denkfehler eine Aufgabe
ueberhaupt sichtbar machen kann. Genau darauf zielt der Auftrag ja ab ("damit
sich die Fehlbildprofile unterscheiden"). Die Aufgaben stehen deshalb nach
Profil gruppiert: Rang 1 aus dem einen Profil, Rang 2 aus einem anderen, dann
decken die ersten beiden Sondier-Aufgaben zusammen mehr ab als zwei aus
demselben Topf.

Die Skill-Zuordnung spiegelt den Backfill der A14-Migration (source_ref-Praefix
-> skill_key). Solange A14 nicht eingespielt ist, gibt es die Spalte
tasks.skill_key noch nicht, deshalb rechnet das Skript sie hier selbst aus.
"""

from __future__ import annotations

import json
import os
import subprocess
from collections import defaultdict
from pathlib import Path

WURZEL = Path(__file__).resolve().parents[2]
OUT = WURZEL / "docs/sondierrang_vorschlag.md"

# Spiegelt Abschnitt 7 der A14-Migration. Eine Aenderung hier ohne dort waere
# genau die zweite Wahrheit, die das Substrat vermeiden soll.
GRUPPE_ZU_SKILL = {
    "brueche-kuerzen": "bruch_kuerzen",
    "brueche-addieren": "bruch_add",
    "brueche-multiplizieren": "bruch_mult",
    "brueche-dividieren": "bruch_div",
    "dezimal-addieren": "dezimal_add_sub",
    "dezimal-multiplizieren": "dezimal_mult",
    "dezimal-dividieren": "dezimal_div",
    "dezimal-umwandeln": "bruch_dezimal",
    "vorzeichen-addieren": "vorzeichen_add_sub",
    "vorzeichen-punktrechnung": "vorzeichen_mult_div",
    "vorzeichen-vorrang": "vorzeichen_vorrang",
    "term-zusammenfassen": "term_zusammenfassen",
    "term-ausmultiplizieren": "term_ausmultiplizieren",
    "term-ausklammern": "term_ausklammern",
    "term-minusklammer": "term_minusklammer",
    "gleichung-einschrittig": "gleichung_einschrittig",
    "gleichung-zweischrittig": "gleichung_zweischrittig",
    "gleichung-negativ": "gleichung_neg_koeffizient",
    "gleichung-beidseitig": "gleichung_beidseitig",
    "prozent-wert": "prozent_prozentwert",
    "prozent-satz": "prozent_prozentsatz",
    "prozent-grundwert": "prozent_grundwert",
    "prozent-veraenderung": "prozent_veraenderung",
}

# skill_key -> (Label, fundament_tiefe). Ebenfalls aus A14.
SKILL_INFO = {
    "dezimal_add_sub": ("Dezimalzahlen addieren/subtrahieren", 1),
    "bruch_kuerzen": ("Brüche kürzen", 1),
    "vorzeichen_add_sub": ("Negative Zahlen addieren/subtrahieren", 1),
    "dezimal_mult": ("Dezimalzahlen multiplizieren", 2),
    "bruch_add": ("Brüche addieren", 2),
    "bruch_mult": ("Brüche multiplizieren", 2),
    "vorzeichen_mult_div": ("Negative Zahlen multiplizieren/dividieren", 2),
    "dezimal_div": ("Dezimalzahlen dividieren", 3),
    "bruch_div": ("Brüche dividieren", 3),
    "bruch_dezimal": ("Bruch in Dezimalzahl", 4),
    "vorzeichen_vorrang": ("Vorrangregeln mit Vorzeichen", 4),
    "term_zusammenfassen": ("Terme zusammenfassen", 4),
    "term_ausmultiplizieren": ("Ausmultiplizieren", 5),
    "gleichung_einschrittig": ("Einschrittige Gleichungen", 5),
    "term_minusklammer": ("Minusklammer auflösen", 6),
    "gleichung_zweischrittig": ("Zweischrittige Gleichungen", 6),
    "prozent_prozentwert": ("Prozentwert berechnen", 6),
    "term_ausklammern": ("Ausklammern", 7),
    "gleichung_neg_koeffizient": ("Gleichungen mit negativem Koeffizienten", 7),
    "gleichung_beidseitig": ("Beidseitige Gleichungen", 7),
    "prozent_grundwert": ("Grundwert berechnen", 7),
    "prozent_prozentsatz": ("Prozentsatz berechnen", 7),
    "prozent_veraenderung": ("Prozentuale Veränderung", 8),
}

ABFRAGE = """
select json_agg(z order by z.source_ref)
from (
  select t.id::text            as id,
         t.source_ref          as source_ref,
         t.afb                 as afb,
         t.input_type          as input_type,
         btrim(split_part(t.question, chr(10), 3)) as aufgabe,
         coalesce(s.acceptance -> 'known_errors', '{}'::jsonb) as known_errors
    from tasks t
    join task_solutions s on s.task_id = t.id
   where t.source = 'edvance_fundament'
) z
"""


def hole_aufgaben() -> list[dict]:
    umgebung = dict(os.environ)
    if "DATABASE_URL" not in umgebung:
        for zeile in (WURZEL / ".env").read_text().splitlines():
            if zeile.startswith("DATABASE_URL="):
                umgebung["DATABASE_URL"] = zeile.split("=", 1)[1].strip().strip('"')
    roh = subprocess.run(
        ["psql", umgebung["DATABASE_URL"], "-P", "pager=off", "-Atc", ABFRAGE],
        capture_output=True, text=True, check=True, env=umgebung,
    ).stdout.strip()
    return json.loads(roh)


def main() -> None:
    aufgaben = hole_aufgaben()

    je_skill: dict[str, list[dict]] = defaultdict(list)
    for a in aufgaben:
        gruppe = a["source_ref"].rsplit("-", 1)[0]
        skill = GRUPPE_ZU_SKILL.get(gruppe)
        if skill is None:
            raise SystemExit(f"Gruppe {gruppe} hat keinen Skill — Mapping ergaenzen.")
        je_skill[skill].append(a)

    zeilen: list[str] = [KOPF]
    ohne_fehlbilder: list[str] = []

    for skill in sorted(je_skill, key=lambda s: (SKILL_INFO[s][1], s)):
        label, tiefe = SKILL_INFO[skill]
        posten = je_skill[skill]

        # Nach Fehlbildprofil buendeln — das ist die Entscheidungsachse.
        profile: dict[tuple[str, ...], list[dict]] = defaultdict(list)
        for a in posten:
            schluessel = tuple(sorted(set(a["known_errors"].values())))
            profile[schluessel].append(a)

        zeilen.append(f"\n## `{skill}` — {label}\n")
        zeilen.append(f"Fundament-Tiefe {tiefe} · {len(posten)} Aufgaben · "
                      f"{len(profile)} Fehlbildprofil(e)\n")

        if len(profile) == 1 and not next(iter(profile)):
            ohne_fehlbilder.append(skill)
            zeilen.append(
                "\n> **Keine `known_errors` gepflegt.** Nach Profil laesst sich hier nichts "
                "unterscheiden — die Auswahl von Rang 1 und 2 braucht erst die Fehlbilder "
                "(siehe Kopf).\n"
            )

        for nr, (schluessel, gruppe) in enumerate(
            sorted(profile.items(), key=lambda kv: (-len(kv[0]), kv[0])), start=1
        ):
            titel = ", ".join(f"`{s}`" for s in schluessel) if schluessel else "_(keine)_"
            zeilen.append(f"\n**Profil {nr}:** {titel}\n")
            zeilen.append("\n| source_ref | Aufgabe | AFB | id |")
            zeilen.append("\n|---|---|---|---|")
            for a in gruppe:
                zeilen.append(
                    f"\n| `{a['source_ref']}` | `{a['aufgabe']}` | {a['afb']} | `{a['id'][:8]}` |"
                )
            zeilen.append("\n")

    zeilen.append(FUSS.replace("@OHNE@", ", ".join(f"`{s}`" for s in ohne_fehlbilder) or "keine"))
    OUT.write_text("".join(zeilen), encoding="utf-8")

    print(f"geschrieben: {OUT}")
    print(f"  Skills: {len(je_skill)}   Aufgaben: {len(aufgaben)}")
    if ohne_fehlbilder:
        print(f"  ohne known_errors: {', '.join(ohne_fehlbilder)}")


KOPF = """# Sondierrang — Entscheidungsvorlage

**Erzeugt von `scripts/content/sondierrang_vorschlag.py`. Nicht von Hand pflegen.**

`tasks.sondierrang` ist in der A14-Migration angelegt und steht **überall auf
`NULL`**. Diese Datei setzt keinen Rang — sie ist die Liste, aus der Rasit und
Lena Rang 1 und 2 je Skill wählen.

## Warum nicht „kontextfrei zuerst"

Der ursprüngliche Auftrag wollte die Aufgaben nach „kontextfrei zuerst" sortiert.
Gemessen an den echten Daten: **keine der 146 Fundament-Aufgaben trägt einen
Sachkontext.** Alle sind nackte Rechnungen; der längste Fragetext ist
Arbeitsanweisung plus Term (24 Wörter, `term-minusklammer`). Das Kriterium kann
hier also nichts unterscheiden, und eine Sortierung danach würde eine Auswahl
vortäuschen, die keine ist.

Was unterscheidet, ist das **Fehlbildprofil**: welche Denkfehler eine Aufgabe
überhaupt sichtbar machen kann. Genau darauf zielt der Auftrag auch ab — Rang 1
und 2 sollen sich in den Fehlbildern unterscheiden. Die Aufgaben stehen deshalb
nach Profil gebündelt.

## Wie man das liest

Je Skill sind die Aufgaben nach ihrem Fehlbildprofil gruppiert. Zwei Aufgaben im
selben Profil machen dieselben Denkfehler sichtbar — sie als Rang 1 und 2 zu
wählen verschenkt die zweite Sondierung.

**Faustregel:** Rang 1 aus dem breitesten Profil (die meisten Fehlbilder,
steht oben), Rang 2 aus einem *anderen* Profil.

Wo ein Skill nur ein einziges Profil hat, ist die Wahl innerhalb des Skills
gleichgültig — dann entscheidet die Zahlenwahl, und die sieht man in der Spalte
`Aufgabe`.
"""

FUSS = """
---

## Offen

**Ohne `known_errors`:** @OHNE@

Diese Skills sind die Term-Gruppen. Ihre Fehlbilder sind berechnet und
dokumentiert (im Kopf von `supabase/seeds/20260722_term_fundament_01.sql`),
aber **nicht als Daten speicherbar**: `known_errors` lebt in `acceptance`, und
`acceptance` mit `canonical` kippt bei Termen die Bewertung. Der Weg dorthin
steht in `AUTONOMY_NOTES.md` (Eintrag 3) und hängt an der A13-Migration.

Bis dahin lässt sich der Sondierrang für diese vier Skills nicht nach Profil
wählen — nur nach Augenschein an der Zahlenwahl.

**Neun Skills haben noch gar keine Aufgaben:** `runden_ueberschlag`,
`groessen_laengen`, `groessen_massen`, `groessen_zeit`, `potenzen`,
`proportionalitaet`, `groessen_flaechen`, `groessen_gemischt`,
`groessen_volumen`. Sie tauchen hier nicht auf, weil es nichts zu ranken gibt.
"""


if __name__ == "__main__":
    main()
