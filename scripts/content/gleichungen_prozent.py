#!/usr/bin/env python3
"""Gleichungen- und Prozent-Fundamentaufgaben erzeugen — als Seed-Datei.

    python3 scripts/content/gleichungen_prozent.py

Schreibt:
    supabase/seeds/20260722_gleichungen_prozent_01.sql
    data/gleichungen_prozent_01_report.json

Dritte Charge nach brueche_fundament.py und vorzeichen_fundament.py, im selben
Muster: binaere Bewertung (kein require_reduced, kein 'teilweise'),
known_errors von Anfang an, Sieb mit Selbsttest.

EINHEITEN: Die Antwort ist immer NUR DIE ZAHL. Das Kind tippt "12", nicht
"12 €". Die Einheit steht im Eingabefeld und kommt aus der SPALTE `tasks.unit`
— `lsa_question_payload` baut daraus das `unit`-Feld des Schueler-Payloads.
`acceptance.unit` wird zusaetzlich gesetzt (es beschreibt die Loesung), aber
`unit_graded` bleibt aus: die Einheit ist hier nicht die Kompetenz.

WAS DAS SKRIPT NICHT TUT: Es fasst die Datenbank nicht an.
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass, field
from fractions import Fraction
from pathlib import Path

WURZEL = Path(__file__).resolve().parents[2]
SEED = WURZEL / "supabase" / "seeds" / "20260722_gleichungen_prozent_01.sql"
BERICHT = WURZEL / "data" / "gleichungen_prozent_01_report.json"

QUELLE = "edvance_fundament"

# Die erlaubten Fehlbild-Labels dieser Charge. Passt ein Fehlbild in keins,
# wird es WEGGELASSEN — ein neues zu erfinden waere eine Taxonomie-Entscheidung
# und gehoert zu Lena.
LABELS = {
    # Gleichungen
    "falsche_gegenoperation",
    "seiten_verwechselt",
    "division_vergessen",
    "addiert_statt_subtrahiert",
    "b_ignoriert",
    "vorzeichen_beim_umstellen",
    "variablen_nicht_zusammengefuehrt",
    "falsches_vorzeichen_beim_zusammenfuehren",
    # Prozent
    "dezimalverschiebung",
    "grundwert_verwechselt",
    "bezug_vertauscht",
    "faktor_100_vergessen",
    "multipliziert_statt_dividiert",
    "nur_prozentwert",
    "falsche_richtung",
}


def zahl(w: Fraction) -> str:
    """Deutsche Schreibweise — so, wie das Kind sie tippt.

    Ganze Zahlen ohne Nachkomma, sonst mit KOMMA. `lsa_normalize_answer` macht
    daraus serverseitig einen Punkt; live geprueft, dass "0,15" als 0,15
    ankommt und nicht mit 15 verwechselt wird.
    """
    if w.denominator == 1:
        return str(w.numerator)
    s = f"{float(w):.6f}".rstrip("0").rstrip(".")
    return s.replace(".", ",")


def ganz(w: Fraction) -> bool:
    return w.denominator == 1


def tippbar(w: Fraction) -> bool:
    """Ist das ein Wert, den ein Kind tatsaechlich hinschreibt?

    Hoechstens zwei Nachkommastellen, also ein Nenner, der 100 teilt: 1,8 und
    7,5 und 0,15 ja — 533,333333 nein. Ein periodischer Dezimalbruch ist keine
    Antwort, die jemand aufschreibt; als Fehlbild waere er tot.
    """
    return 100 % w.denominator == 0


@dataclass
class Variante:
    gruppe: str
    skill: str
    ref: str
    titel: str
    frage: str
    afb: str
    loesung: Fraction
    fehlbilder: dict[str, Fraction]
    unit: str | None = None
    verworfen: str | None = None
    weggelassen: list[str] = field(default_factory=list)
    proben: list[dict[str, str]] = field(default_factory=list)


GIB_X = "Gib den Wert für x an."


# ── Gruppe 1: Lineare Gleichungen ───────────────────────────────────────────


def g_einschrittig(art: str, a: int, b: int, c: int, i: int) -> Variante:
    """x + b = c · x - b = c · a·x = c"""
    if art == "plus":
        gleichung, loesung = f"x + {b} = {c}", Fraction(c - b)
        fehl = {"falsche_gegenoperation": Fraction(c + b), "seiten_verwechselt": Fraction(b - c)}
    elif art == "minus":
        gleichung, loesung = f"x − {b} = {c}", Fraction(c + b)
        fehl = {"falsche_gegenoperation": Fraction(c - b), "seiten_verwechselt": Fraction(b - c)}
    else:  # mal
        gleichung, loesung = f"{a}x = {c}", Fraction(c, a)
        # "Seiten verwechselt" waere a/c — bei diesen Zahlen fast nie ganzzahlig
        # und damit keine Antwort, die ein Kind je hinschreibt.
        fehl = {"falsche_gegenoperation": Fraction(c - a)}

    return Variante(
        gruppe="gleichungen",
        skill="GA_einschrittig",
        ref=f"gleichung-einschrittig-{i:02d}",
        titel=f"Gleichungen · Einschrittig · {gleichung}",
        frage=f"Löse die Gleichung. {GIB_X}\n\n{gleichung}",
        afb="I",
        loesung=loesung,
        fehlbilder=fehl,
    )


def g_zweischrittig(a: int, b: int, c: int, i: int) -> Variante:
    gleichung = f"{a}x + {b} = {c}"
    return Variante(
        gruppe="gleichungen",
        skill="GB_zweischrittig",
        ref=f"gleichung-zweischrittig-{i:02d}",
        titel=f"Gleichungen · Zweischrittig · {gleichung}",
        frage=f"Löse die Gleichung. {GIB_X}\n\n{gleichung}",
        afb="I",
        loesung=Fraction(c - b, a),
        fehlbilder={
            # Der haeufigste Fehler: subtrahiert, aber nicht mehr geteilt.
            "division_vergessen": Fraction(c - b),
            "addiert_statt_subtrahiert": Fraction(c + b, a),
            "b_ignoriert": Fraction(c, a),
        },
    )


def g_negativ(b: int, a: int, c: int, i: int) -> Variante:
    """b − a·x = c — hier trifft das Vorzeichen-Fundament auf die Gleichung."""
    gleichung = f"{b} − {a}x = {c}"
    loesung = Fraction(b - c, a)
    return Variante(
        gruppe="gleichungen",
        skill="GC_negativ",
        ref=f"gleichung-negativ-{i:02d}",
        titel=f"Gleichungen · Negativer Koeffizient · {gleichung}",
        frage=f"Löse die Gleichung. {GIB_X}\n\n{gleichung}",
        afb="I",
        loesung=loesung,
        fehlbilder={
            "vorzeichen_beim_umstellen": -loesung,
            "division_vergessen": Fraction(b - c),
        },
    )


def g_beidseitig(a: int, b: int, d: int, e: int, i: int) -> Variante:
    """a·x + b = d·x + e"""
    gleichung = f"{a}x + {b} = {d}x + {e}"
    return Variante(
        gruppe="gleichungen",
        skill="GD_beidseitig",
        ref=f"gleichung-beidseitig-{i:02d}",
        titel=f"Gleichungen · Variable beidseitig · {gleichung}",
        frage=f"Löse die Gleichung. {GIB_X}\n\n{gleichung}",
        # AFB II: Zwei Schritte muessen verknuepft werden — Variablen
        # zusammenfuehren UND aufloesen. Kein reproduziertes Verfahren.
        afb="II",
        loesung=Fraction(e - b, a - d),
        fehlbilder={
            # Nur eine Seite behandelt: durch a statt durch (a−d) geteilt.
            "variablen_nicht_zusammengefuehrt": Fraction(e - b, a),
            # Beim Zusammenfuehren das Vorzeichen von b verloren.
            "falsches_vorzeichen_beim_zusammenfuehren": Fraction(e + b, a - d),
        },
    )


# ── Gruppe 2: Prozent ───────────────────────────────────────────────────────


def p_prozentwert(grund: int, satz: int, kontext: tuple[str, str], i: int) -> Variante:
    """Prozentwert gesucht."""
    was, wofuer = kontext
    loesung = Fraction(grund * satz, 100)
    return Variante(
        gruppe="prozent",
        skill="PA_prozentwert",
        ref=f"prozent-wert-{i:02d}",
        titel=f"Prozent · Prozentwert · {satz} % von {grund}",
        frage=(
            f"{was} kostet {grund} €. Der Preis wird um {satz} % reduziert.\n\n"
            f"Wie viel Euro beträgt die Ermäßigung?"
        ),
        afb="I",
        unit="€",
        loesung=loesung,
        fehlbilder={
            # Mit 15 statt 0,15 gerechnet.
            "dezimalverschiebung": Fraction(grund * satz),
            # Die Grundwert-Formel angewandt, wo der Prozentwert gesucht war.
            "grundwert_verwechselt": Fraction(grund * 100, satz),
        },
    )


def p_prozentsatz(anteil: int, grund: int, kontext: str, i: int) -> Variante:
    loesung = Fraction(anteil * 100, grund)
    return Variante(
        gruppe="prozent",
        skill="PB_prozentsatz",
        ref=f"prozent-satz-{i:02d}",
        titel=f"Prozent · Prozentsatz · {anteil} von {grund}",
        frage=f"Von {grund} {kontext} haben {anteil} eine Eins.\n\nWie viel Prozent sind das?",
        afb="I",
        unit="%",
        loesung=loesung,
        fehlbilder={
            "bezug_vertauscht": Fraction(grund * 100, anteil),
            # Richtig geteilt, aber nicht mit 100 multipliziert.
            "faktor_100_vergessen": Fraction(anteil, grund),
        },
    )


def p_grundwert(anteil: int, satz: int, kontext: str, i: int) -> Variante:
    loesung = Fraction(anteil * 100, satz)
    return Variante(
        gruppe="prozent",
        skill="PC_grundwert",
        ref=f"prozent-grundwert-{i:02d}",
        titel=f"Prozent · Grundwert · {anteil} sind {satz} %",
        frage=(
            f"{anteil} {kontext} sind {satz} % aller {kontext}.\n\n"
            f"Wie viele {kontext} sind es insgesamt?"
        ),
        # AFB II: Das Verhaeltnis muss umgekehrt gedacht werden. Der schwerste
        # der drei Grundtypen — und das eigentliche Sieb.
        afb="II",
        loesung=loesung,
        fehlbilder={
            # Das Leitsymptom: mechanisch die Prozentwert-Formel angewandt.
            "multipliziert_statt_dividiert": Fraction(anteil * satz, 100),
            "dezimalverschiebung": Fraction(anteil * satz),
        },
    )


def p_veraenderung(grund: int, satz: int, rauf: bool, was: str, i: int) -> Variante:
    delta = Fraction(grund * satz, 100)
    loesung = Fraction(grund) + delta if rauf else Fraction(grund) - delta
    richtung = "steigt" if rauf else "sinkt"
    return Variante(
        gruppe="prozent",
        skill="PD_veraenderung",
        ref=f"prozent-veraenderung-{i:02d}",
        titel=f"Prozent · Veränderung · {grund} € {'+' if rauf else '−'}{satz} %",
        frage=(
            f"{was} kostet {grund} €. Der Preis {richtung} um {satz} %.\n\n"
            f"Wie viel Euro kostet es danach?"
        ),
        afb="II",
        unit="€",
        loesung=loesung,
        fehlbilder={
            # Nur die Veraenderung angegeben statt des neuen Werts.
            "nur_prozentwert": delta,
            # In die falsche Richtung gerechnet.
            "falsche_richtung": Fraction(grund) - delta if rauf else Fraction(grund) + delta,
        },
    )


# ── Das Sieb ────────────────────────────────────────────────────────────────


def frisch_rechnen(v: Variante, roh: tuple) -> Fraction:
    """Rechnet die Loesung ein ZWEITES Mal, auf anderem Weg als der Konstruktor."""
    if v.skill == "GA_einschrittig":
        art, a, b, c = roh
        if art == "plus":
            return Fraction(c) - Fraction(b)
        if art == "minus":
            return Fraction(c) + Fraction(b)
        return Fraction(c) / Fraction(a)
    if v.skill == "GB_zweischrittig":
        a, b, c = roh
        return (Fraction(c) - Fraction(b)) / Fraction(a)
    if v.skill == "GC_negativ":
        b, a, c = roh
        return (Fraction(b) - Fraction(c)) / Fraction(a)
    if v.skill == "GD_beidseitig":
        a, b, d, e = roh
        return (Fraction(e) - Fraction(b)) / (Fraction(a) - Fraction(d))
    if v.skill == "PA_prozentwert":
        grund, satz = roh
        return Fraction(grund) * Fraction(satz, 100)
    if v.skill == "PB_prozentsatz":
        anteil, grund = roh
        return Fraction(anteil) / Fraction(grund) * 100
    if v.skill == "PC_grundwert":
        anteil, satz = roh
        return Fraction(anteil) / Fraction(satz, 100)
    grund, satz, rauf = roh
    d = Fraction(grund) * Fraction(satz, 100)
    return Fraction(grund) + d if rauf else Fraction(grund) - d


def siebe(v: Variante, roh: tuple) -> Variante:
    """Fuenf Pruefungen. Was durchfaellt, wird verworfen — mit Grund."""
    # (1) Frisch nachgerechnet.
    frisch = frisch_rechnen(v, roh)
    if frisch != v.loesung:
        v.verworfen = f"Nachrechnung ergibt {zahl(frisch)}, die Variante behauptet {zahl(v.loesung)}"
        return v

    # (2) Die Loesung selbst muss ganzzahlig sein. Eine krumme Loesung macht
    #     die Antwortform (Runden, Nachkommastellen) zum eigenen Problem und
    #     verfaelscht damit die Diagnose.
    if not ganz(v.loesung):
        v.verworfen = f"Loesung {zahl(v.loesung)} ist nicht ganzzahlig"
        return v

    # (3) Nur erlaubte Labels.
    unbekannt = set(v.fehlbilder) - LABELS
    if unbekannt:
        v.verworfen = f"unbekanntes Fehlbild-Label: {sorted(unbekannt)}"
        return v

    # (4) Fehlbilder muessen TIPPBAR sein, nicht ganzzahlig.
    #
    #     Die Ganzzahl-Forderung gilt der LOESUNG: dort wuerde die Antwortform
    #     (Runden, Nachkommastellen) zum eigenen Problem und die Diagnose
    #     verfaelschen. Ein Fehlbild muss dagegen nur eines sein: der Wert, den
    #     ein Kind mit dieser Fehlvorstellung wirklich hinschreibt. "1,8" und
    #     "7,5" sind genau das — und bei PC_grundwert ist "1,8" sogar das
    #     LEITSYMPTOM (mechanisch die Prozentwert-Formel angewandt). Es wegen
    #     einer Nachkommastelle zu streichen hiesse, dem schwersten der drei
    #     Grundtypen seine wichtigste Diagnose zu nehmen.
    #     Weggelassen werden deshalb nur periodische Werte wie 533,333333, die
    #     niemand so aufschreibt.
    behalten: dict[str, Fraction] = {}
    for label, wert in v.fehlbilder.items():
        if not tippbar(wert):
            v.weggelassen.append(f"{label} ({zahl(wert)}) ist kein tippbarer Wert")
            continue
        behalten[label] = wert
    v.fehlbilder = behalten

    # (5) Trennschaerfe: kein Fehlbild darf auf die Loesung oder auf ein anderes
    #     Fehlbild fallen. Sonst wuerde lsa_grade es als 'voll' werten bzw. der
    #     Report koennte die Fehler nicht auseinanderhalten.
    belegt: dict[Fraction, str] = {v.loesung: "loesung"}
    endgueltig: dict[str, Fraction] = {}
    for label, wert in v.fehlbilder.items():
        if wert in belegt:
            v.weggelassen.append(f"{label} ({zahl(wert)}) faellt mit {belegt[wert]} zusammen")
            continue
        belegt[wert] = label
        endgueltig[label] = wert
    v.fehlbilder = endgueltig

    if not v.fehlbilder:
        v.verworfen = "kein einziges trennscharfes Fehlbild uebrig"
        return v

    v.proben = [{"antwort": zahl(v.loesung), "erwartet": "voll", "label": "—"}]
    for label, wert in v.fehlbilder.items():
        v.proben.append({"antwort": zahl(wert), "erwartet": "nicht", "label": label})

    return v


# ── Die Zahlenwahl ──────────────────────────────────────────────────────────

EINSCHRITTIG = [
    ("plus", 0, 7, 12),  # x + 7 = 12  → 5
    ("minus", 0, 4, 9),  # x − 4 = 9   → 13
    ("mal", 3, 0, 18),  #  3x = 18     → 6
    ("plus", 0, 12, 20),  # x + 12 = 20 → 8
    ("minus", 0, 9, 6),  # x − 9 = 6   → 15
    ("mal", 4, 0, 24),  #  4x = 24     → 6
]

# a teilt (c−b), (c+b) UND c — damit alle drei Fehlbilder ganzzahlig werden.
ZWEISCHRITTIG = [
    (3, 6, 24),  # → 6  | 18 | 10 | 8
    (2, 4, 20),  # → 8  | 16 | 12 | 10
    (5, 10, 45),  # → 7  | 35 | 11 | 9
    (4, 8, 40),  # → 8  | 32 | 12 | 10
    (3, 9, 30),  # → 7  | 21 | 13 | 10
    (6, 12, 42),  # → 5  | 30 | 9  | 7
]

NEGATIV = [
    (18, 3, 12),  # 18 − 3x = 12 → 2
    (20, 4, 8),  #  20 − 4x = 8  → 3
    (15, 5, 5),  #  15 − 5x = 5  → 2
    (24, 2, 10),  # 24 − 2x = 10 → 7
    (30, 6, 12),  # 30 − 6x = 12 → 3
]

BEIDSEITIG = [
    (5, 3, 2, 18),  # 5x+3 = 2x+18 → 5  | 3  | 7
    (4, 2, 2, 14),  # 4x+2 = 2x+14 → 6  | 3  | 8
    (5, 5, 3, 25),  # 5x+5 = 3x+25 → 10 | 4  | 15
    (7, 2, 3, 30),  # 7x+2 = 3x+30 → 7  | 4  | 8
    (6, 4, 2, 28),  # 6x+4 = 2x+28 → 6  | 4  | 8
]

# (Grundwert, Satz, (Ware, —))
PROZENTWERT = [
    (80, 15, ("Ein Pullover", "")),
    (200, 20, ("Ein Fahrrad", "")),
    (60, 25, ("Ein Rucksack", "")),
    (150, 20, ("Ein Paar Schuhe", "")),
    (40, 50, ("Ein Buch", "")),
    (90, 10, ("Eine Jacke", "")),
]

# (Anteil, Grundwert, Kontext)
PROZENTSATZ = [
    (12, 80, "Schülerinnen und Schülern"),
    (20, 80, "Schülerinnen und Schülern"),
    (15, 60, "Schülerinnen und Schülern"),
    (9, 90, "Schülerinnen und Schülern"),
    (30, 60, "Schülerinnen und Schülern"),
    (16, 80, "Schülerinnen und Schülern"),
]

# (Anteil, Satz, Kontext)
GRUNDWERT = [
    (12, 15, "Bücher"),
    (20, 25, "Bälle"),
    (30, 20, "Karten"),
    (40, 50, "Stifte"),
    (12, 25, "Hefte"),
    (15, 50, "Plätze"),
]

# (Grundwert, Satz, rauf, Ware)
VERAENDERUNG = [
    (200, 20, True, "Ein Fahrrad"),
    (80, 25, False, "Ein Pullover"),
    (150, 10, True, "Ein Rucksack"),
    (60, 25, False, "Ein Buch"),
    (250, 20, True, "Ein Zelt"),
]


def alle_varianten() -> list[Variante]:
    out: list[Variante] = []
    for i, (art, a, b, c) in enumerate(EINSCHRITTIG, 1):
        out.append(siebe(g_einschrittig(art, a, b, c, i), (art, a, b, c)))
    for i, (a, b, c) in enumerate(ZWEISCHRITTIG, 1):
        out.append(siebe(g_zweischrittig(a, b, c, i), (a, b, c)))
    for i, (b, a, c) in enumerate(NEGATIV, 1):
        out.append(siebe(g_negativ(b, a, c, i), (b, a, c)))
    for i, (a, b, d, e) in enumerate(BEIDSEITIG, 1):
        out.append(siebe(g_beidseitig(a, b, d, e, i), (a, b, d, e)))
    for i, (g, s, k) in enumerate(PROZENTWERT, 1):
        out.append(siebe(p_prozentwert(g, s, k, i), (g, s)))
    for i, (an, g, k) in enumerate(PROZENTSATZ, 1):
        out.append(siebe(p_prozentsatz(an, g, k, i), (an, g)))
    for i, (an, s, k) in enumerate(GRUNDWERT, 1):
        out.append(siebe(p_grundwert(an, s, k, i), (an, s)))
    for i, (g, s, r, w) in enumerate(VERAENDERUNG, 1):
        out.append(siebe(p_veraenderung(g, s, r, w, i), (g, s, r)))
    return out


# ── Selbsttest ──────────────────────────────────────────────────────────────


def selbsttest() -> None:
    """Bekannt schlechte Faelle, die durchfallen MUESSEN."""
    faelle: list[tuple[str, Variante, tuple]] = []

    luege = g_zweischrittig(3, 6, 24, 99)
    luege.loesung = Fraction(7)
    faelle.append(("gelogene Loesung", luege, (3, 6, 24)))

    # 3x + 4 = 19: Loesung 5, aber (19+4)/3 und 19/3 sind krumm.
    krumm = g_zweischrittig(3, 4, 19, 98)
    faelle.append(("krumme Fehlbilder", krumm, (3, 4, 19)))

    # 12 sind 7 % → 171,43…: krumme Loesung.
    krumm_p = p_grundwert(12, 7, "Bücher", 97)
    faelle.append(("krumme Loesung (Prozent)", krumm_p, (12, 7)))

    # Fehlbild faellt auf die Loesung: 60 € −50 % → 30, und die Veraenderung
    # ist ebenfalls 30.
    gleich = p_veraenderung(60, 50, False, "Ein Buch", 96)
    faelle.append(("Fehlbild gleich Loesung", gleich, (60, 50, False)))

    unbekannt = g_zweischrittig(3, 6, 24, 95)
    unbekannt.fehlbilder = {"phantasie_label": Fraction(1)}
    faelle.append(("unbekanntes Label", unbekannt, (3, 6, 24)))

    fehler = 0
    for name, v, roh in faelle:
        erg = siebe(v, roh)
        # „Durchgefallen" heisst: verworfen ODER mindestens ein Fehlbild
        # weggelassen. Beides ist ein Anschlagen des Siebs.
        if erg.verworfen is None and not erg.weggelassen:
            print(f"  FEHLER: '{name}' ist unbeanstandet durchgelaufen")
            fehler += 1
        else:
            grund = erg.verworfen or "; ".join(erg.weggelassen)
            print(f"  ok: '{name}' → {grund}")

    if fehler:
        raise SystemExit(f"{fehler} Selbsttest(s) fehlgeschlagen")
    print("Sieb beisst: alle bekannt schlechten Faelle beanstandet.\n")


# ── Ausgabe ─────────────────────────────────────────────────────────────────


def sql_text(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"


def sql_json(obj: object) -> str:
    return sql_text(json.dumps(obj, ensure_ascii=False))


def sql_nullable(s: str | None) -> str:
    return "null" if s is None else sql_text(s)


def acceptance(v: Variante) -> dict[str, object]:
    """canonical + known_errors, bei Prozent zusaetzlich unit.

    KEIN require_reduced (an einer ganzen Zahl gibt es nichts zu kuerzen) und
    KEIN unit_graded: Die Einheit steht im Feld, das Kind tippt nur die Zahl.
    Sie zu bewerten hiesse, eine Kompetenz zu pruefen, die hier nicht gefragt
    ist.
    """
    a: dict[str, object] = {
        "canonical": zahl(v.loesung),
        "known_errors": {zahl(w): l for l, w in v.fehlbilder.items()},
    }
    if v.unit:
        a["unit"] = v.unit
    return a


def baue_sql(gueltig: list[Variante]) -> str:
    kopf = f"""-- ============================================================================
-- Gleichungen + Prozent, Charge 01 — {len(gueltig)} Aufgaben als DRAFT
--
-- ERZEUGT von scripts/content/gleichungen_prozent.py. Nicht von Hand pflegen.
--
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/seeds/20260722_gleichungen_prozent_01.sql
--
-- SETZT A11 (lsa_grade) UND A12 (known_errors) VORAUS.
--
-- STATUS: alles 'draft'. Die Freigabe ist Lenas Schritt.
--
-- BINAER: kein require_reduced, kein 'teilweise'. Eine Gleichung ist geloest
-- oder nicht. Deshalb tragen alle Aufgaben known_errors — bei binaerer
-- Bewertung sind die Fehlbilder die einzige Feindiagnostik.
--
-- EINHEITEN: Das Kind tippt NUR DIE ZAHL ("12", nicht "12 €"). Die Einheit
-- steht im Eingabefeld und kommt aus der SPALTE tasks.unit —
-- lsa_question_payload baut daraus das unit-Feld des Schueler-Payloads.
-- acceptance.unit ist zusaetzlich gesetzt (es beschreibt die Loesung), aber
-- unit_graded bleibt aus: die Einheit ist hier nicht die Kompetenz.
--
-- SOLUTION-LEAK: Loesung, Akzeptanz-Set und Fehlbilder ausschliesslich in
-- task_solutions. In `tasks` steht nur die Frage (und die Einheit, die das Kind
-- ohnehin sieht).
--
-- IDEMPOTENT ueber (source, source_ref).
-- ============================================================================

begin;

-- ── 0. Voraussetzungen ─────────────────────────────────────────────────────

do $$
begin
  if not exists (
    select 1 from skill_clusters sc
      join subjects s on s.id = sc.subject_id
     where s.name = 'Mathematik' and sc.name = 'Zahl & Rechnen'
  ) then
    raise exception 'Cluster "Zahl & Rechnen" (Mathematik) fehlt — erst supabase/seed.sql einspielen.';
  end if;
  if not exists (select 1 from process_competencies where code = 'Ope') then
    raise exception 'Prozesskompetenz "Ope" fehlt — erst supabase/seed.sql einspielen.';
  end if;
  if to_regprocedure('public.lsa_grade(text,jsonb,jsonb,jsonb)') is null then
    raise exception 'lsa_grade fehlt — A11 ist nicht eingespielt.';
  end if;
end $$;

-- ── 1. Die Aufgaben ────────────────────────────────────────────────────────

insert into tasks (
  source, source_ref, content_type, input_type, status, is_active, is_diagnostic,
  title, question, afb, curriculum_grade, needs_image, unit,
  cluster_id, competency_content, competency_process, competency_id, question_payload
)
select
  {sql_text(QUELLE)}, v.source_ref, 'exercise', 'NUMERIC', 'draft', true, false,
  v.titel, v.frage, v.afb, 7, false, v.unit,
  (select sc.id from skill_clusters sc
     join subjects s on s.id = sc.subject_id
    where s.name = 'Mathematik' and sc.name = 'Zahl & Rechnen' limit 1),
  'arithmetik_algebra', 'Operieren',
  (select pc.id from process_competencies pc where pc.code = 'Ope' limit 1),
  jsonb_strip_nulls(jsonb_build_object(
    'kind', 'short_input', 'prompt', v.frage, 'unit', v.unit))
from (values
"""

    zeilen = [
        f"  ({sql_text(v.ref)}, {sql_text(v.titel)}, {sql_text(v.frage)}, "
        f"{sql_text(v.afb)}, {sql_nullable(v.unit)})"
        for v in gueltig
    ]
    kopf += ",\n".join(zeilen)
    kopf += """
) as v(source_ref, titel, frage, afb, unit)
on conflict (source, source_ref) do nothing;

-- ── 2. Loesung, Akzeptanz-Set und Fehlbilder (Server-Only-Zone) ────────────

insert into task_solutions (task_id, correct_answers, acceptance, updated_at)
select t.id, v.correct_answers::jsonb, v.acceptance::jsonb, now()
from (values
"""

    zeilen = [
        f"  ({sql_text(v.ref)}, {sql_json([zahl(v.loesung)])}, {sql_json(acceptance(v))})"
        for v in gueltig
    ]
    kopf += ",\n".join(zeilen)
    kopf += f"""
) as v(source_ref, correct_answers, acceptance)
join tasks t on t.source = {sql_text(QUELLE)} and t.source_ref = v.source_ref
on conflict (task_id) do update
   set correct_answers = excluded.correct_answers,
       acceptance      = excluded.acceptance,
       updated_at      = now();

-- ── 3. Proben gegen lsa_grade, mit Negativkontrolle ────────────────────────
--
-- Der Generator kennt die Bewertungsfunktion nicht und baut sie nicht nach.
-- Er schreibt die Erwartung hierher, und die Datenbank prueft sie selbst.
--
-- Die letzte Zeile ist ABSICHTLICH falsch erwartet. Schlaegt sie nicht an,
-- prueft die Schleife in Wahrheit nichts — dann bricht der Block ebenfalls ab.

do $$
declare
  r           record;
  v_urteil    text;
  v_echte     int := 0;
  v_kontrolle int := 0;
begin
  for r in
    select * from (values
"""

    proben = []
    for v in gueltig:
        for p in v.proben:
            proben.append(
                f"      ({sql_text(v.ref)}, {sql_text(p['antwort'])}, "
                f"{sql_text(p['erwartet'])}, {sql_text(p['label'])}, false)"
            )
    erste = gueltig[0]
    proben.append(
        f"      ({sql_text(erste.ref)}, {sql_text(zahl(erste.loesung))}, "
        f"'nicht', 'NEGATIVKONTROLLE', true)"
    )
    kopf += ",\n".join(proben)
    kopf += f"""
    ) as p(source_ref, antwort, erwartet, label, ist_kontrolle)
  loop
    select public.lsa_grade(
             'NUMERIC', s.acceptance, s.correct_answers,
             jsonb_build_object('value', r.antwort)
           )
      into v_urteil
      from task_solutions s
      join tasks t on t.id = s.task_id
     where t.source = {sql_text(QUELLE)} and t.source_ref = r.source_ref;

    if v_urteil is distinct from r.erwartet then
      if r.ist_kontrolle then
        v_kontrolle := v_kontrolle + 1;
        raise notice 'Negativkontrolle hat angeschlagen (so soll es sein): %/% ist %',
          r.source_ref, r.antwort, coalesce(v_urteil, '<null>');
      else
        v_echte := v_echte + 1;
        raise warning 'Probe %/% : lsa_grade sagt %, erwartet % (%)',
          r.source_ref, r.antwort, coalesce(v_urteil, '<null>'), r.erwartet, r.label;
      end if;
    end if;
  end loop;

  if v_echte > 0 then
    raise exception '% echte Probe(n) fehlgeschlagen — nichts eingespielt.', v_echte;
  end if;
  if v_kontrolle <> 1 then
    raise exception 'Negativkontrolle hat NICHT angeschlagen — die Probenschleife prueft nichts.';
  end if;

  raise notice 'Gleichungen + Prozent: alle echten Proben bestanden, Negativkontrolle greift.';
end $$;

commit;
"""
    return kopf


def main() -> None:
    if "--selbsttest" in sys.argv:
        selbsttest()
        return

    selbsttest()
    alle = alle_varianten()
    gueltig = [v for v in alle if v.verworfen is None]
    verworfen = [v for v in alle if v.verworfen is not None]

    SEED.parent.mkdir(parents=True, exist_ok=True)
    SEED.write_text(baue_sql(gueltig), encoding="utf-8")

    skills = [
        "GA_einschrittig", "GB_zweischrittig", "GC_negativ", "GD_beidseitig",
        "PA_prozentwert", "PB_prozentsatz", "PC_grundwert", "PD_veraenderung",
    ]
    bericht = {
        "quelle": QUELLE,
        "status": "draft",
        "bewertung": "binaer (kein require_reduced, kein teilweise)",
        "einheiten": "tasks.unit gesetzt (Anzeige im Feld); unit_graded aus",
        "erzeugt": len(alle),
        "akzeptiert": len(gueltig),
        "verworfen": len(verworfen),
        "je_skill": {s: sum(1 for v in gueltig if v.skill == s) for s in skills},
        "varianten": [
            {
                "skill": v.skill,
                "ref": v.ref,
                "frage": " ".join(v.frage.split()),
                "afb": v.afb,
                "unit": v.unit,
                "voll": zahl(v.loesung),
                "known_errors": {zahl(w): l for l, w in v.fehlbilder.items()},
                "weggelassen": v.weggelassen,
            }
            for v in gueltig
        ],
        "verworfene": [{"ref": v.ref, "grund": v.verworfen} for v in verworfen],
    }
    BERICHT.write_text(
        json.dumps(bericht, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    print(f"{len(gueltig)} Varianten akzeptiert, {len(verworfen)} verworfen")
    for s in skills:
        print(f"  {s}: {bericht['je_skill'][s]}")
    for v in gueltig:
        for w in v.weggelassen:
            print(f"  weggelassen bei {v.ref}: {w}")
    for v in verworfen:
        print(f"  VERWORFEN {v.ref}: {v.verworfen}")
    print(f"\n→ {SEED.relative_to(WURZEL)}")
    print(f"→ {BERICHT.relative_to(WURZEL)}")


if __name__ == "__main__":
    main()
