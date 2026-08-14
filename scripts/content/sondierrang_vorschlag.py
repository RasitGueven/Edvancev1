#!/usr/bin/env python3
"""
Erzeugt die drei abgeleiteten Dateien zum sondierrang der Fundament-Aufgaben:

    docs/sondierrang_vorschlag.md   Entscheidungsvorlage (Profile je Skill)
    scripts/sql/sondierrang_setzen.sql  die UPDATEs, eine Zeile je Aufgabe
    out/sondierrang-bericht.md      Begruendung je Skill, ohne DB lesbar

    python3 scripts/content/sondierrang_vorschlag.py

Das Skript SCHREIBT NICHT IN DIE DATENBANK. Es liest nur und legt ein
SQL-Skript ab; das scharfe Setzen macht Rasit nach Durchsicht des Berichts
(sondierrang ist laut Spaltenkommentar Handarbeit Rasit/Lena).

Kein Erzeugungsdatum in den Ausgaben — sonst aendern sie sich bei jedem Lauf
ohne inhaltlichen Grund.

WAS DIE AUSWAHL TRAEGT — und was nicht:

Der urspruengliche Auftrag wollte "kontextfrei zuerst". Das unterscheidet die
Fundament-Aufgaben kaum; was unterscheidet, ist das FEHLBILDPROFIL: welche
Denkfehler eine Aufgabe ueberhaupt sichtbar machen kann.

ACHTUNG, hier liegt die Falle: known_errors ist ein Objekt
{"<falsche Antwort>": "<Fehlbild>"}, zum Beispiel

    {"3/7": "nenner_addiert", "3/12": "zaehler_nicht_erweitert"}

Die SCHLUESSEL sind die konkreten falschen Antworten — sie haengen an den
Zahlen der Aufgabe und sind darum fast fuer jede Aufgabe verschieden. Die WERTE
sind die Fehlbilder. Ein Profil aus Schluesseln waere praktisch die Aufgaben-
Identitaet und koennte nichts buendeln; gruppiert wird deshalb nach den WERTEN.
Der Unterschied ist in out/sondierrang-bericht.md ausdruecklich vermerkt, weil
supabase/checks/sondierrang.PRUEFUNG.sql nach Schluesseln prueft.

Damit die Pruefung trotzdem haelt, erzwingt die Auswahl zusaetzlich
verschiedene Schluesselprofile, wo der Skill mehr als eines hat (P4).
"""

from __future__ import annotations

import json
import os
import re
import subprocess
from collections import defaultdict
from pathlib import Path

from sondierrang_texte import BERICHT_KOPF, FUSS, KOPF, SQL_KOPF

WURZEL = Path(__file__).resolve().parents[2]
OUT_DOC = WURZEL / "docs/sondierrang_vorschlag.md"
OUT_SQL = WURZEL / "scripts/sql/sondierrang_setzen.sql"
OUT_BERICHT = WURZEL / "out/sondierrang-bericht.md"

# Skill-Label und Fundament-Tiefe kommen aus der Tabelle skills. Sie hier noch
# einmal zu pflegen waere die zweite Wahrheit, die das Substrat vermeiden soll.
ABFRAGE = """
select json_agg(z order by z.skill_key, z.source_ref)
from (
  select t.id::text        as id,
         t.skill_key       as skill_key,
         k.label           as label,
         k.fundament_tiefe as tiefe,
         t.source_ref      as source_ref,
         t.afb             as afb,
         t.question        as question,
         coalesce(s.acceptance -> 'known_errors', '{}'::jsonb) as known_errors
    from tasks t
    join skills k          on k.skill_key = t.skill_key
    join task_solutions s  on s.task_id = t.id
   where t.source = 'edvance_fundament'
     and t.status = 'ready'
) z
"""

ZAHL = re.compile(r"\d+(?:[.,]\d+)?")


def db_url() -> str:
    """DATABASE_URL aus der Umgebung, sonst aus .env.

    .env quotet den Wert mit Apostrophen; ein reines strip('"') liess den
    Apostroph stehen, psql las den String dann als Datenbanknamen.
    """
    if os.environ.get("DATABASE_URL"):
        return os.environ["DATABASE_URL"]
    for zeile in (WURZEL / ".env").read_text().splitlines():
        if zeile.startswith("DATABASE_URL="):
            wert = zeile.split("=", 1)[1].strip()
            if len(wert) >= 2 and wert[0] == wert[-1] and wert[0] in "\"'":
                wert = wert[1:-1]
            return wert
    raise SystemExit("DATABASE_URL weder in der Umgebung noch in .env gefunden.")


def hole_aufgaben() -> list[dict]:
    url = db_url()
    lauf = subprocess.run(
        ["psql", url, "-P", "pager=off", "-Atc", ABFRAGE],
        capture_output=True, text=True, check=False,
        env=dict(os.environ, DATABASE_URL=url),
    )
    if lauf.returncode != 0:
        # Verbindungsstring nicht ins Log — er enthaelt das Passwort.
        raise SystemExit(f"psql fehlgeschlagen (Code {lauf.returncode}):\n"
                         + lauf.stderr[-800:])
    return json.loads(lauf.stdout.strip())


def aufgabentext(question: str) -> str:
    """Fragetext einzeilig. Nicht auf die dritte Zeile verkuerzen — bei den
    Geometrie- und Dreisatz-Aufgaben stehen die Zahlen in der ersten."""
    return " ".join(question.split())


def zahlengroesse(question: str) -> float:
    """Summe der Zahlen im Fragetext. Grober, aber nachvollziehbarer Massstab
    fuer 'kleinere Zahlen zuerst' — der Tiebreak, wenn das Profil nichts mehr
    unterscheidet."""
    return sum(float(z.replace(",", ".")) for z in ZAHL.findall(question))


def anzahl(n: int, einzahl: str, mehrzahl: str) -> str:
    return f"{n} {einzahl if n == 1 else mehrzahl}"


def waehle(posten: list[dict]) -> tuple[dict, dict, str]:
    """Rang 1 und 2 fuer einen Skill. Gibt zusaetzlich die Begruendung zurueck."""
    nach_profil: dict[tuple[str, ...], list[dict]] = defaultdict(list)
    for a in posten:
        nach_profil[a["fehlbilder"]].append(a)
    for gruppe in nach_profil.values():
        gruppe.sort(key=lambda a: (a["zahlen"], a["source_ref"]))

    # Breitestes Profil zuerst: die Aufgabe, die die meisten Fehlbilder zeigen
    # kann. Bei gleicher Breite entscheidet dieselbe Regel wie innerhalb eines
    # Profils — kleinere Zahlen zuerst.
    ordnung = sorted(nach_profil, key=lambda p: (-len(p), nach_profil[p][0]["zahlen"], p))

    if len(ordnung) > 1:
        erst = ordnung[0]
        # Rang 2 soll etwas NEUES zeigen. Unter den uebrigen Profilen also das,
        # das die meisten Fehlbilder beitraegt, die Rang 1 nicht schon zeigt —
        # nicht einfach das zweitbreiteste. Wo ein Profil Teilmenge des ersten
        # ist, bringt es null Neue und faellt damit von selbst nach hinten.
        zweit = max(ordnung[1:], key=lambda p: (len(set(p) - set(erst)), len(p),
                                                -nach_profil[p][0]["zahlen"]))
        r1 = nach_profil[erst][0]
        r2 = nach_profil[zweit][0]

        neu = len(set(zweit) - set(erst))
        breite = anzahl(len(erst), "Fehlbild", "Fehlbilder")
        kopf = (f"Rang 1 aus dem breitesten Fehlbildprofil ({breite})"
                if len(erst) > len(ordnung[1]) else
                f"Rang 1 aus dem Profil mit den kleineren Zahlen — die vorderen Profile "
                f"zeigen gleich viele Fehlbilder ({len(erst)})")
        if neu:
            grund = (f"{kopf}; Rang 2 aus dem Profil, das am meisten Neues beitraegt "
                     f"({anzahl(neu, 'weiteres Fehlbild', 'weitere Fehlbilder')}) — zusammen "
                     f"{anzahl(len(set(erst) | set(zweit)), 'Fehlbild', 'Fehlbilder')}.")
        else:
            grund = (f"{kopf}; Rang 2 aus einem anderen Profil, das aber eine Teilmenge des "
                     f"ersten ist — mehr gibt der Bestand hier nicht her, die zweite "
                     f"Sondierung zeigt kein zusaetzliches Fehlbild.")
    else:
        gruppe = nach_profil[ordnung[0]]
        r1, r2 = gruppe[0], gruppe[1]
        grund = ("Nur ein Fehlbildprofil — nach Profil ist hier nichts zu unterscheiden; "
                 "es entscheidet die Zahlenwahl, kleinere Zahlen zuerst.")

    # P4 der PRUEFUNG zaehlt Schluesselprofile, nicht Fehlbilder. Wo der Skill
    # mehr als eines hat, muessen Rang 1 und 2 sich auch dort unterscheiden.
    if len({a["antworten"] for a in posten}) > 1 and r1["antworten"] == r2["antworten"]:
        rest = [a for a in sorted(posten, key=lambda a: (a["zahlen"], a["source_ref"]))
                if a["id"] != r1["id"] and a["antworten"] != r1["antworten"]]
        if not rest:
            raise SystemExit(f"{r1['skill_key']}: kein zweites Schluesselprofil gefunden.")
        r2 = rest[0]
        grund += " Rang 2 nachgezogen, damit sich auch die falschen Antworten unterscheiden."

    return r1, r2, grund


def main() -> None:
    aufgaben = hole_aufgaben()
    for a in aufgaben:
        a["fehlbilder"] = tuple(sorted(set(a["known_errors"].values())))
        a["antworten"] = tuple(sorted(a["known_errors"].keys()))
        a["text"] = aufgabentext(a["question"])
        a["zahlen"] = zahlengroesse(a["question"])

    je_skill: dict[str, list[dict]] = defaultdict(list)
    for a in aufgaben:
        je_skill[a["skill_key"]].append(a)

    skills = sorted(je_skill, key=lambda s: (je_skill[s][0]["tiefe"] or 0, s))
    wahl = {s: waehle(je_skill[s]) for s in skills}

    pruefe(je_skill, wahl)
    schreibe_doc(je_skill, skills, wahl)
    schreibe_sql(skills, wahl)
    schreibe_bericht(je_skill, skills, wahl)

    ohne = [s for s in skills if not any(a["fehlbilder"] for a in je_skill[s])]
    print(f"geschrieben: {OUT_DOC}\n             {OUT_SQL}\n             {OUT_BERICHT}")
    print(f"  Skills: {len(skills)}   Aufgaben: {len(aufgaben)}   "
          f"UPDATEs: {2 * len(skills)}")
    if ohne:
        print(f"  ohne known_errors: {', '.join(ohne)}")


def pruefe(je_skill: dict[str, list[dict]], wahl: dict) -> None:
    """Dieselben Zusicherungen, die supabase/checks/sondierrang.PRUEFUNG.sql
    danach an der Datenbank prueft — hier schon, damit ein Fehler nicht erst im
    Probelauf auffaellt."""
    for skill, posten in je_skill.items():
        r1, r2, _ = wahl[skill]
        if r1["id"] == r2["id"]:
            raise SystemExit(f"{skill}: Rang 1 und 2 sind dieselbe Aufgabe.")
        if len({a["antworten"] for a in posten}) > 1 and r1["antworten"] == r2["antworten"]:
            raise SystemExit(f"{skill}: P4 verletzt — gleiches Schluesselprofil.")


def schreibe_doc(je_skill, skills, wahl) -> None:
    zeilen = [KOPF.replace("@AUFGABEN@", str(sum(len(je_skill[s]) for s in skills)))
                  .replace("@SKILLS@", str(len(skills)))]
    for skill in skills:
        posten = je_skill[skill]
        label, tiefe = posten[0]["label"], posten[0]["tiefe"]
        r1, r2, _ = wahl[skill]

        profile: dict[tuple[str, ...], list[dict]] = defaultdict(list)
        for a in posten:
            profile[a["fehlbilder"]].append(a)

        zeilen.append(f"\n## `{skill}` — {label}\n")
        zeilen.append(f"\nFundament-Tiefe {tiefe} · {len(posten)} Aufgaben · "
                      f"{anzahl(len(profile), 'Fehlbildprofil', 'Fehlbildprofile')}\n")
        if len(profile) == 1 and not next(iter(profile)):
            zeilen.append(
                "\n> **Keine `known_errors` gepflegt.** Nach Profil laesst sich hier nichts "
                "unterscheiden — es entscheidet die Zahlenwahl (siehe Kopf).\n")

        for nr, schluessel in enumerate(
                sorted(profile, key=lambda p: (-len(p), p)), start=1):
            titel = ", ".join(f"`{s}`" for s in schluessel) if schluessel else "_(keine)_"
            zeilen.append(f"\n**Profil {nr}:** {titel}\n")
            zeilen.append("\n| Rang | source_ref | Aufgabe | AFB | id |")
            zeilen.append("\n|---|---|---|---|---|")
            for a in sorted(profile[schluessel], key=lambda a: (a["zahlen"], a["source_ref"])):
                rang = "**1**" if a["id"] == r1["id"] else "**2**" if a["id"] == r2["id"] else "—"
                zeilen.append(f"\n| {rang} | `{a['source_ref']}` | {a['text']} "
                              f"| {a['afb']} | `{a['id'][:8]}` |")
            zeilen.append("\n")
    zeilen.append(FUSS)
    OUT_DOC.write_text("".join(zeilen), encoding="utf-8")


def schreibe_sql(skills, wahl) -> None:
    zeilen = [SQL_KOPF.replace("@N@", str(2 * len(skills))).replace("@SKILLS@", str(len(skills)))]
    for skill in skills:
        r1, r2, _ = wahl[skill]
        zeilen.append(f"\n-- {skill} — {r1['label']}\n")
        for rang, a in ((1, r1), (2, r2)):
            zeilen.append(f"update tasks set sondierrang = {rang}\n"
                          f" where id = '{a['id']}'  -- {a['source_ref']}\n"
                          f"   and source = 'edvance_fundament' and status = 'ready'\n"
                          f"   and sondierrang is distinct from {rang};\n")
    OUT_SQL.write_text("".join(zeilen), encoding="utf-8")


def schreibe_bericht(je_skill, skills, wahl) -> None:
    # Wie viel bringt die zweite Sondierung? Das ist der Punkt, an dem die
    # Durchsicht ansetzen sollte.
    neu, teilmenge, einzeln = [], [], []
    for s in skills:
        r1, r2, _ = wahl[s]
        if len({a["fehlbilder"] for a in je_skill[s]}) == 1:
            einzeln.append(s)
        elif set(r2["fehlbilder"]) - set(r1["fehlbilder"]):
            neu.append(s)
        else:
            teilmenge.append(s)

    zeilen = [BERICHT_KOPF
              .replace("@AUFGABEN@", str(sum(len(je_skill[s]) for s in skills)))
              .replace("@SKILLS@", str(len(skills)))
              .replace("@N@", str(2 * len(skills)))
              .replace("@NEU@", str(len(neu)))
              .replace("@TEILMENGE@", str(len(teilmenge)))
              .replace("@EINZELN@", str(len(einzeln)))
              .replace("@TEILMENGE_LISTE@", ", ".join(f"`{s}`" for s in teilmenge) or "keine")]
    for skill in skills:
        posten = je_skill[skill]
        r1, r2, grund = wahl[skill]
        anzahl_profile = len({a["fehlbilder"] for a in posten})
        zeilen.append(f"\n## `{skill}` — {posten[0]['label']}\n")
        zeilen.append(f"\n{len(posten)} Aufgaben · "
                      f"{anzahl(anzahl_profile, 'Fehlbildprofil', 'Fehlbildprofile')}\n")
        for rang, a in ((1, r1), (2, r2)):
            bilder = ", ".join(f"`{s}`" for s in a["fehlbilder"]) or "_(keine gepflegt)_"
            zeilen.append(f"\n- **Rang {rang}** · `{a['source_ref']}` · {a['text']}\n")
            zeilen.append(f"  - Fehlbilder: {bilder}\n")
            zeilen.append(f"  - `{a['id']}`\n")
        zeilen.append(f"\n{grund}\n")
    OUT_BERICHT.write_text("".join(zeilen), encoding="utf-8")



if __name__ == "__main__":
    main()
