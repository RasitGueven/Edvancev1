#!/usr/bin/env python3
"""
Fundament-Charge 2 — die neun Skills, die heute null Aufgaben tragen.

    python3 scripts/content/fundament_charge2.py

Erzeugt VIER Seed-Dateien (eine je Gruppe) nach supabase/seeds/:
    20260723_groessen_fundament_01.sql        (34, sechs Groessen-Skills)
    20260723_potenzen_fundament_01.sql        (16)
    20260723_proportionalitaet_fundament_01.sql (14)
    20260723_runden_fundament_01.sql          (10)

ANTWORTFORM (alle Gruppen):
  input_type NUMERIC, canonical ist eine REINE ZAHL ohne Einheit. Die Einheit
  steht im Fragetext UND in tasks.unit (fliesst ueber lsa_question_payload nach
  payload.unit). Das Kind tippt nur die Zahl — sonst misst die Aufgabe das
  Tippen der Einheit statt der Umrechnung. unit_graded/require_reduced bleiben
  damit irrelevant und werden nicht gesetzt.

  WICHTIG: Weil canonical eine reine Zahl ist, ist der Rest hinter der Zahl leer,
  lsa_is_unit('') = true, und der Wert-Pfad von lsa_grade greift — nicht der
  TERM-Zweig (A13). Der Selbsttest der Seed-Datei zeigt das.

DAS SIEB (der eigentliche Zweck):
  Jede Variante wird ZWEIMAL geloest — einmal aus den Operanden konstruiert,
  einmal von einem eigenen Parser aus dem GERENDERTEN Fragetext. Der Parser
  sieht die canonical nie. Weichen sie ab, fliegt die Variante raus.

  Kollisionspruefung IMMER auf WERTEN (exakte Fraction, = wertgleich wie
  lsa_values_equal), nie auf Zeichenketten: 2,50 = 2,5. Ein Fehlbild, das
  wertgleich zur Loesung ist, ginge sonst als 'voll' durch.

  Untippbare Fehlbilder (periodisch oder > 4 Nachkommastellen) und Kollisionen
  werden WEGGELASSEN und berichtet — nicht geraten, nicht erzwungen. Eine
  Aufgabe bleibt gueltig, nur mit weniger Fehlbildern.

  Die Bewertung selbst prueft dieses Skript NICHT nach: das macht der DO-Block
  der Seed-Datei ueber lsa_grade. Zwei Wahrheiten ueber "was zaehlt als richtig"
  waeren genau der Fehler, den die Server-Only-Zone verhindert.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from decimal import Decimal, ROUND_HALF_UP
from fractions import Fraction
from math import isqrt
from pathlib import Path

SEEDS = Path(__file__).resolve().parents[2] / "supabase/seeds"

MAX_LOESUNG_DEZ = 2      # Loesung: ganzzahlig oder <= 2 Nachkommastellen
MAX_FEHLBILD_DEZ = 4     # Fehlbild: <= 4 Nachkommastellen, nie periodisch
MAX_FEHLBILD_BETRAG = 10_000_000   # kein Kind tippt Millionenwerte; Absurdes faellt


# ── Zahl-Formatierung (deutsches Komma) ────────────────────────────────────

def _terminiert(fr: Fraction) -> bool:
    d = fr.denominator
    while d % 2 == 0:
        d //= 2
    while d % 5 == 0:
        d //= 5
    return d == 1


def _nachkommastellen(fr: Fraction) -> int:
    d = fr.denominator
    p2 = p5 = 0
    while d % 2 == 0:
        d //= 2
        p2 += 1
    while d % 5 == 0:
        d //= 5
        p5 += 1
    return max(p2, p5)


def fmt(fr) -> str:
    """Exakte Fraction -> String, wie ein Kind ihn tippt. Kein Tausendertrenner."""
    fr = Fraction(fr)
    if fr.denominator == 1:
        return str(fr.numerator)
    if not _terminiert(fr):
        raise ValueError(f"nicht terminierend: {fr}")
    stellen = _nachkommastellen(fr)
    skaliert = fr * (10 ** stellen)
    ziffern = str(abs(int(skaliert))).rjust(stellen + 1, "0")
    s = f"{ziffern[:-stellen]},{ziffern[-stellen:]}"
    return f"-{s}" if fr < 0 else s


def tippbar(fr: Fraction, max_dez: int) -> bool:
    return _terminiert(Fraction(fr)) and _nachkommastellen(Fraction(fr)) <= max_dez


# ── Eine Aufgabe ────────────────────────────────────────────────────────────

@dataclass
class Aufgabe:
    source_ref: str
    skill_key: str
    afb: str
    unit: str                       # die Einheit fuer tasks.unit + Fragetext
    frage: str                      # der volle Fragetext (mehrzeilig)
    canonical: Fraction
    fehlbilder: list[tuple[Fraction, str]] = field(default_factory=list)
    titel: str = ""


class Verworfen(Exception):
    pass


# ── Sieb: eine Variante annehmen oder verwerfen ────────────────────────────

def siebe(
    ref: str, skill: str, afb: str, unit: str, frage: str, titel: str,
    canonical: Fraction, kandidaten: list[tuple[Fraction, str]],
    frisch: Fraction, verworfen: list[str],
) -> Aufgabe | None:
    """
    canonical: konstruiert. frisch: unabhaengig aus dem Fragetext geloest.
    kandidaten: (wert, label). Untippbare/kollidierende werden weggelassen.
    """
    if frisch != canonical:
        verworfen.append(f"{ref}: frisch {fmt_safe(frisch)} != konstruiert {fmt_safe(canonical)} — Aufgabe verworfen")
        return None
    if not tippbar(canonical, MAX_LOESUNG_DEZ):
        verworfen.append(f"{ref}: Loesung {fmt_safe(canonical)} nicht tippbar — Aufgabe verworfen")
        return None

    behalten: list[tuple[Fraction, str]] = []
    gesehen: dict[Fraction, str] = {canonical: "canonical"}
    for wert, label in kandidaten:
        if not tippbar(wert, MAX_FEHLBILD_DEZ):
            verworfen.append(f"{ref}: {label}={fmt_safe(wert)} untippbar (periodisch/>4 NKS) — weggelassen")
            continue
        if abs(wert) > MAX_FEHLBILD_BETRAG:
            verworfen.append(f"{ref}: {label}={fmt(wert)} unrealistisch gross — weggelassen")
            continue
        if wert in gesehen:
            verworfen.append(f"{ref}: {label}={fmt(wert)} wertgleich mit {gesehen[wert]} — weggelassen")
            continue
        gesehen[wert] = label
        behalten.append((wert, label))

    if not behalten:
        verworfen.append(f"{ref}: kein Fehlbild ueberlebt — Aufgabe verworfen")
        return None

    return Aufgabe(ref, skill, afb, unit, frage, canonical, behalten, titel)


def fmt_safe(fr: Fraction) -> str:
    try:
        return fmt(fr)
    except ValueError:
        return f"{fr.numerator}/{fr.denominator}"


# ════════════════════════════════════════════════════════════════════════════
# GRUPPE 1: GROESSEN UND EINHEITEN
# ════════════════════════════════════════════════════════════════════════════

# Laengen in mm; (Faktor, Rung in Zehnerschritten)
LEN = {"mm": (1, 0), "cm": (10, 1), "dm": (100, 2), "m": (1000, 3), "km": (1000000, 6)}
# Massen in mg; Rung in TAUSENDERschritten
MAS = {"mg": (1, 0), "g": (1000, 1), "kg": (10**6, 2), "t": (10**9, 3)}
# Flaechen in mm2; Rung in HUNDERTerschritten
FLA = {"mm2": (1, 0), "cm2": (100, 1), "dm2": (10**4, 2), "m2": (10**6, 3),
       "a": (10**8, 4), "ha": (10**10, 5), "km2": (10**12, 6)}
# Volumen in mm3; Rung in TAUSENDERschritten. l=dm3, ml=cm3, hl=100 l.
VOL = {"mm3": (1, 0), "cm3": (1000, 1), "dm3": (10**6, 2), "m3": (10**9, 3)}
VOL_LITER = {"ml": 1000, "l": 10**6, "hl": 10**8}   # in mm3

EINHEIT_ANZEIGE = {
    "mm2": "mm²", "cm2": "cm²", "dm2": "dm²", "m2": "m²", "km2": "km²",
    "mm3": "mm³", "cm3": "cm³", "dm3": "dm³", "m3": "m³",
}


def zeige(u: str) -> str:
    return EINHEIT_ANZEIGE.get(u, u)


def frage_umrechnung(val: Fraction, von: str, nach: str) -> str:
    return (f"Wandle um.\n\n{fmt(val)} {zeige(von)} = ? {zeige(nach)}")


# Ein Parser, der die drei Operanden aus dem gerenderten Text zurueckliest und
# die Loesung UNABHAENGIG neu rechnet — ueber Rung-Differenzen, nicht ueber die
# Faktor-Tabelle des Konstruktors.
_ANZEIGE_ZU_KEY = {v: k for k, v in EINHEIT_ANZEIGE.items()}


def _key(anzeige: str) -> str:
    return _ANZEIGE_ZU_KEY.get(anzeige, anzeige)


def solve_umrechnung_text(frage: str, tabelle: dict, schritt: int) -> Fraction:
    m = re.search(r"([-\d,]+)\s+(\S+)\s+=\s+\?\s+(\S+)", frage)
    val = Fraction(m.group(1).replace(",", "."))
    von, nach = _key(m.group(2)), _key(m.group(3))
    rung_v = tabelle[von][1]
    rung_n = tabelle[nach][1]
    return val * Fraction(schritt) ** (rung_v - rung_n)


def _umrechnung(tabelle: dict, schritt: int, val, von: str, nach: str) -> Fraction:
    return Fraction(val) * Fraction(tabelle[von][0], tabelle[nach][0])


def groessen_laengen(verworfen: list[str]) -> list[Aufgabe]:
    # (val, von, nach) — span >= 2 Rungs, damit einheit_uebersprungen darstellbar
    tuples = [
        (3, "m", "cm"), (250, "cm", "m"), (Fraction("4.2"), "m", "mm"),
        (7500, "mm", "m"), (6, "km", "m"), (3200, "m", "km"),
    ]
    out = []
    for i, (val, von, nach) in enumerate(tuples, 1):
        ref = f"groessen-laengen-{i:02d}"
        val = Fraction(val)
        exp = LEN[von][1] - LEN[nach][1]
        canon = _umrechnung(LEN, 10, val, von, nach)
        sign = 1 if exp > 0 else -1
        kand = [
            (_umrechnung(LEN, 10, val, nach, von), "richtung_vertauscht"),
            (val * Fraction(10) ** (exp - sign), "einheit_uebersprungen"),
            # Gegenrichtung zu einheit_uebersprungen (das ist canonical/10^sign),
            # sonst fallen die beiden zusammen.
            (canon * Fraction(10) ** sign, "faktor_zehn_daneben"),
        ]
        frisch = solve_umrechnung_text(frage_umrechnung(val, von, nach), LEN, 10)
        a = siebe(ref, "groessen_laengen", "I", zeige(nach),
                  frage_umrechnung(val, von, nach),
                  f"Größen · Längen · {fmt(val)} {zeige(von)}", canon, kand, frisch, verworfen)
        if a:
            out.append(a)
    return out


def groessen_massen(verworfen: list[str]) -> list[Aufgabe]:
    tuples = [
        (3, "kg", "g"), (2500, "g", "kg"), (4, "t", "kg"),
        (750, "g", "kg"), (5000, "mg", "g"),
    ]
    out = []
    for i, (val, von, nach) in enumerate(tuples, 1):
        ref = f"groessen-massen-{i:02d}"
        val = Fraction(val)
        exp = MAS[von][1] - MAS[nach][1]
        canon = _umrechnung(MAS, 1000, val, von, nach)
        sign = 1 if exp > 0 else -1
        kand = [
            (_umrechnung(MAS, 1000, val, nach, von), "richtung_vertauscht"),
            # Gegenrichtung zu faktor_hundert_statt_tausend (das ist
            # canonical/10^exp), sonst kollidieren die beiden bei |exp|=1.
            (canon * Fraction(10) ** sign, "faktor_zehn_daneben"),
            (val * Fraction(100) ** exp, "faktor_hundert_statt_tausend"),
        ]
        frisch = solve_umrechnung_text(frage_umrechnung(val, von, nach), MAS, 1000)
        a = siebe(ref, "groessen_massen", "I", zeige(nach),
                  frage_umrechnung(val, von, nach),
                  f"Größen · Massen · {fmt(val)} {zeige(von)}", canon, kand, frisch, verworfen)
        if a:
            out.append(a)
    return out


def groessen_flaechen(verworfen: list[str]) -> list[Aufgabe]:
    # 3 benachbart (|exp|=1): {linearer, richtung}. 3 uebersprungen (|exp|=3):
    # {linearer, einheit}. Bei |exp|=2 fallen linearer und einheit zusammen,
    # bei |exp|=3 ist richtung untippbar (bis 6 NKS) — Sieb laesst beides fallen.
    # Uebersprungen: Ausgangswert gross, Ziel klein (rueckwaerts gerechnet, damit
    # canonical tippbar bleibt); richtung_vertauscht ist dort untippbar und faellt.
    tuples = [
        (3, "dm2", "cm2"), (250, "cm2", "dm2"), (4, "m2", "dm2"),      # benachbart
        (3000000, "mm2", "m2"), (4000000, "cm2", "a"), (5000000, "dm2", "ha"),  # uebersprungen
    ]
    out = []
    for i, (val, von, nach) in enumerate(tuples, 1):
        ref = f"groessen-flaechen-{i:02d}"
        val = Fraction(val)
        exp = FLA[von][1] - FLA[nach][1]
        canon = _umrechnung(FLA, 100, val, von, nach)
        sign = 1 if exp > 0 else -1
        kand = [
            (val * Fraction(10) ** exp, "linearer_faktor"),                    # 10 statt 100 je Stufe
            (_umrechnung(FLA, 100, val, nach, von), "richtung_vertauscht"),
            (val * Fraction(100) ** (exp - sign), "einheit_uebersprungen"),
        ]
        frisch = solve_umrechnung_text(frage_umrechnung(val, von, nach), FLA, 100)
        a = siebe(ref, "groessen_flaechen", "II", zeige(nach),
                  frage_umrechnung(val, von, nach),
                  f"Größen · Flächen · {fmt(val)} {zeige(von)}", canon, kand, frisch, verworfen)
        if a:
            out.append(a)
    return out


def groessen_volumen(verworfen: list[str]) -> list[Aufgabe]:
    # Aufgaben mit Liter tragen liter_kubik_falsch; reine Kubikaufgaben nicht.
    # (val, von, nach, liter?) — liter? gibt an, ob 1 l = 1 dm3 gebrueckt wird.
    out = []
    # 1) 2 l = ? cm3 : l->dm3->cm3, alle drei Fehlbilder
    for i, (val, von, nach, liter) in enumerate([
        (2, "l", "cm3", True), (3, "l", "ml", True), (5000, "cm3", "l", True),
        (4, "dm3", "cm3", False), (6000, "mm3", "cm3", False),
    ], 1):
        ref = f"groessen-volumen-{i:02d}"
        val = Fraction(val)
        canon = _vol_umrechnung(val, von, nach)
        kand = [(_vol_faktor10(val, von, nach), "linearer_faktor"),
                (_vol_umrechnung(val, nach, von), "richtung_vertauscht")]
        if liter:
            kand.append((_vol_liter_falsch(val, von, nach), "liter_kubik_falsch"))
        frisch = solve_vol_text(frage_umrechnung(val, von, nach))
        a = siebe(ref, "groessen_volumen", "II", zeige(nach),
                  frage_umrechnung(val, von, nach),
                  f"Größen · Volumen · {fmt(val)} {zeige(von)}", canon, kand, frisch, verworfen)
        if a:
            out.append(a)
    return out


def _vol_faktor_mm3(u: str) -> int:
    return VOL[u][0] if u in VOL else VOL_LITER[u]


def _vol_umrechnung(val, von, nach) -> Fraction:
    return Fraction(val) * Fraction(_vol_faktor_mm3(von), _vol_faktor_mm3(nach))


def _vol_rung(u: str) -> int:
    # Rung in Tausenderschritten (mm3=0..m3=3); Liter ueber ihre Kubik-Gleichung.
    if u in VOL:
        return VOL[u][1]
    return {"ml": 1, "l": 2, "hl": Fraction(2) + Fraction(1)}[u]  # hl gesondert


def _vol_faktor10(val, von, nach) -> Fraction:
    # linearer_faktor: 10 statt 1000 je Tausenderstufe
    exp = _vol_rung(von) - _vol_rung(nach)
    return Fraction(val) * Fraction(10) ** exp


def _vol_liter_falsch(val, von, nach) -> Fraction:
    # 1 l = 1 dm3 nicht erkannt: die Liter<->Kubik-Bruecke faellt um Faktor 1000
    # in die falsche Richtung. Konkret: die Loesung, aber ohne den Liter-Schritt.
    canon = _vol_umrechnung(val, von, nach)
    liter_seite = von if von in VOL_LITER else nach
    # Wird von Liter WEG gerechnet (l->cm3): Bruecke fehlt -> /1000. Umgekehrt *1000.
    if von in VOL_LITER:
        return canon / 1000
    return canon * 1000


def solve_vol_text(frage: str) -> Fraction:
    m = re.search(r"([-\d,]+)\s+(\S+)\s+=\s+\?\s+(\S+)", frage)
    val = Fraction(m.group(1).replace(",", "."))
    von, nach = _key(m.group(2)), _key(m.group(3))
    return val * Fraction(_vol_faktor_mm3(von), _vol_faktor_mm3(nach))


# ── Zeit ────────────────────────────────────────────────────────────────────

MINSET = [6, 12, 15, 18, 24, 30, 36, 42, 45, 48, 54]


def frage_zeit(gesamt_min: int) -> str:
    return f"Wandle um.\n\n{gesamt_min} min = ? h"


def groessen_zeit(verworfen: list[str]) -> list[Aufgabe]:
    # min -> h (die saubere Richtung: richtung_vertauscht = *60 bleibt ganzzahlig).
    # (volle_h, minutenanteil, afb)
    tuples = [
        (2, 30, "I"), (1, 6, "I"), (3, 18, "I"), (2, 48, "I"),
        (1, 15, "II"), (3, 45, "II"),
    ]
    out = []
    for i, (H, m, afb) in enumerate(tuples, 1):
        ref = f"groessen-zeit-{i:02d}"
        assert m in MINSET, m
        gesamt = H * 60 + m
        canon = Fraction(gesamt, 60)
        kand = [
            (Fraction(gesamt * 60), "richtung_vertauscht"),         # *60 statt /60
            (Fraction(H) + Fraction(m, 100), "dezimal_statt_sexagesimal"),
            (Fraction(gesamt, 100), "faktor_hundert_statt_sechzig"),
        ]
        frisch = solve_zeit_text(frage_zeit(gesamt))
        a = siebe(ref, "groessen_zeit", afb, "h", frage_zeit(gesamt),
                  f"Größen · Zeit · {gesamt} min", canon, kand, frisch, verworfen)
        if a:
            out.append(a)
    return out


def solve_zeit_text(frage: str) -> Fraction:
    m = re.search(r"(\d+)\s+min\s+=\s+\?\s+h", frage)
    return Fraction(int(m.group(1)), 60)


# ── Gemischte Schreibweise ─────────────────────────────────────────────────

def groessen_gemischt(verworfen: list[str]) -> list[Aufgabe]:
    """
    Jede Aufgabe ist bespoke: die Fehlbilder haengen an der konkreten Ziffernlage
    (fuehrende Null / Sexagesimal / Komma-als-Trenner). Deshalb explizite Formeln.
    """
    out = []
    specs = [
        # (ref-nr, val, von, nach, frage-zahl-anzeige, canonical, [(wert,label)])
        # 1,05 m = ? cm : fuehrende Null nach dem Komma
        (1, "1,05", "m", "cm", Fraction(105),
         [(Fraction(150), "fuehrende_null_ignoriert")]),           # 1,5 m
        # 2,08 kg = ? g
        (2, "2,08", "kg", "g", Fraction(2080),
         [(Fraction(2800), "fuehrende_null_ignoriert")]),          # 2,8 kg
        # 3,4 kg = ? g : Komma als Trenner (3 kg 4 g)
        (3, "3,4", "kg", "g", Fraction(3400),
         [(Fraction(3004), "komma_als_trenner")]),
        # 2,5 h = ? min : Sexagesimal + Komma-Trenner
        (4, "2,5", "h", "min", Fraction(150),
         [(Fraction(170), "dezimal_statt_sexagesimal"),            # 2 h 50 min
          (Fraction(125), "komma_als_trenner")]),                  # 2 h 5 min
        # 1,25 h = ? min
        (5, "1,25", "h", "min", Fraction(75),
         [(Fraction(85), "dezimal_statt_sexagesimal")]),           # 1 h 25 min
        # 4,05 m = ? cm : fuehrende Null
        (6, "4,05", "m", "cm", Fraction(405),
         [(Fraction(450), "fuehrende_null_ignoriert")]),
    ]
    for nr, anzeige, von, nach, canon, kand in specs:
        ref = f"groessen-gemischt-{nr:02d}"
        frage = f"Wandle um.\n\n{anzeige} {zeige(von)} = ? {zeige(nach)}"
        frisch = solve_gemischt_text(frage, von, nach)
        a = siebe(ref, "groessen_gemischt", "II", zeige(nach), frage,
                  f"Größen · Gemischt · {anzeige} {zeige(von)}", canon, kand, frisch, verworfen)
        if a:
            out.append(a)
    return out


def solve_gemischt_text(frage: str, von: str, nach: str) -> Fraction:
    # Unabhaengig: liest die Dezimalzahl und rechnet ueber die passende Tabelle.
    m = re.search(r"([-\d,]+)\s+(\S+)\s+=\s+\?\s+(\S+)", frage)
    val = Fraction(m.group(1).replace(",", "."))
    if von in ("h", "min"):
        return val * 60 if (von == "h" and nach == "min") else val / 60
    return _umrechnung(LEN if von in LEN else MAS, 10 if von in LEN else 1000, val, von, nach)


# ════════════════════════════════════════════════════════════════════════════
# GRUPPE 2: POTENZEN
# ════════════════════════════════════════════════════════════════════════════

def potenzen(verworfen: list[str]) -> list[Aufgabe]:
    out = []
    # ('pow', base, exp) | ('negpow', base, exp) fuer (-b)^e | ('minuspow',b,e) fuer -b^e
    # | ('sqrt', n)
    specs = [
        ("pow", 3, 4, "I"), ("pow", 2, 5, "I"), ("pow", 5, 3, "II"),
        ("pow", 4, 3, "I"), ("pow", 6, 2, "I"), ("pow", 7, 2, "I"),
        ("pow", 10, 2, "I"), ("pow", 2, 3, "I"),
        ("negpow", 3, 2, "II"), ("negpow", 4, 2, "II"),   # gerade
        ("negpow", 2, 3, "II"), ("negpow", 3, 3, "II"),   # ungerade
        ("negpow", 5, 2, "II"),
        ("minuspow", 2, 2, "II"),                          # -2^2 = -4
        ("sqrt", 36, "II"), ("sqrt", 144, "II"),
    ]
    for idx, spec in enumerate(specs, 1):
        ref = f"potenzen-{idx:02d}"
        art = spec[0]
        if art == "sqrt":
            n = spec[1]
            afb = spec[2]
            wurzel = isqrt(n)
            assert wurzel * wurzel == n, n
            frage = f"Berechne.\n\n√{n} = ?"
            canon = Fraction(wurzel)
            kand = [(Fraction(n, 2), "wurzel_halbiert")]
            frisch = solve_sqrt_text(frage)
        else:
            base, exp, afb = spec[1], spec[2], spec[3]
            if art == "pow":
                frage = f"Berechne.\n\n{base}^{exp} = ?"
                canon = Fraction(base) ** exp
                kand = [
                    (Fraction(base * exp), "mal_exponent"),
                    (Fraction(exp) ** base, "basis_exponent_vertauscht"),
                ]
                frisch = solve_pow_text(frage)
            elif art == "negpow":
                frage = f"Berechne.\n\n(-{base})^{exp} = ?"
                canon = Fraction(-base) ** exp
                kand = [(-canon, "vorzeichen_potenz"),
                        (Fraction(-base * exp), "mal_exponent")]
                frisch = solve_negpow_text(frage)
            else:  # minuspow: -b^e = -(b^e)
                frage = f"Berechne.\n\n-{base}^{exp} = ?"
                canon = -(Fraction(base) ** exp)
                kand = [(-canon, "vorzeichen_potenz")]
                frisch = solve_minuspow_text(frage)
        a = siebe(ref, "potenzen", afb, "", frage,
                  f"Potenzen · {frage.splitlines()[-1]}", canon, kand, frisch, verworfen)
        if a:
            out.append(a)
    return out


def solve_pow_text(frage: str) -> Fraction:
    m = re.search(r"(\d+)\^(\d+)", frage)
    b, e = int(m.group(1)), int(m.group(2))
    r = Fraction(1)
    for _ in range(e):
        r *= b
    return r


def solve_negpow_text(frage: str) -> Fraction:
    m = re.search(r"\(-(\d+)\)\^(\d+)", frage)
    b, e = int(m.group(1)), int(m.group(2))
    r = Fraction(1)
    for _ in range(e):
        r *= -b
    return r


def solve_minuspow_text(frage: str) -> Fraction:
    m = re.search(r"-(\d+)\^(\d+)", frage)
    b, e = int(m.group(1)), int(m.group(2))
    r = Fraction(1)
    for _ in range(e):
        r *= b
    return -r


def solve_sqrt_text(frage: str) -> Fraction:
    m = re.search(r"√(\d+)", frage)
    return Fraction(isqrt(int(m.group(1))))


# ════════════════════════════════════════════════════════════════════════════
# GRUPPE 3: PROPORTIONALITAET
# ════════════════════════════════════════════════════════════════════════════

_PROP_SACH = [
    ("{a} L Saft kosten {b} €.", "Was kosten {c} L?"),
    ("{a} Hefte kosten {b} €.", "Was kosten {c} Hefte?"),
    ("{a} kg Äpfel kosten {b} €.", "Was kosten {c} kg?"),
    ("{a} m Stoff kosten {b} €.", "Was kosten {c} m?"),
    ("{a} Flaschen kosten {b} €.", "Was kosten {c} Flaschen?"),
    ("{a} Tickets kosten {b} €.", "Was kosten {c} Tickets?"),
    ("{a} Stifte kosten {b} €.", "Was kosten {c} Stifte?"),
]
_ANTI_SACH = [
    ("{a} Arbeiter schaffen eine Aufgabe in {b} Stunden.", "Wie lange brauchen {c} Arbeiter?"),
    ("{a} Pumpen leeren ein Becken in {b} Stunden.", "Wie lange brauchen {c} Pumpen?"),
    ("{a} Maler streichen eine Wand in {b} Stunden.", "Wie lange brauchen {c} Maler?"),
    ("{a} Helfer räumen eine Halle in {b} Stunden.", "Wie lange brauchen {c} Helfer?"),
    ("{a} Bagger heben eine Grube in {b} Stunden.", "Wie lange brauchen {c} Bagger?"),
    ("{a} Mäher mähen ein Feld in {b} Stunden.", "Wie lange brauchen {c} Mäher?"),
    ("{a} Drucker erledigen einen Auftrag in {b} Stunden.", "Wie lange brauchen {c} Drucker?"),
]


def _prop_kandidaten(a, b, c, prop: bool):
    if prop:
        return [(Fraction(a * b, c), "antiproportional_verwechselt"),
                (Fraction(a * c, b), "falscher_bezug"),
                (Fraction(b * c), "einheit_verrutscht")]
    return [(Fraction(b * c, a), "antiproportional_verwechselt"),
            (Fraction(a * c, b), "falscher_bezug"),
            (Fraction(a * b), "einheit_verrutscht")]


def _prop_suche(prop: bool, anzahl: int):
    """
    Sucht Zahlentripel (a,b,c) mit GANZZAHLIGER Loesung und >= 2 tippbaren,
    verschiedenen Fehlbildern. Grundwert a != 1 (sonst kein Dreisatz), a != c.
    """
    treffer = []
    gesehen_canon = set()
    for a in range(2, 10):
        for b in range(3, 41):
            for c in range(2, 16):
                if c == a or b == a or b == c:
                    continue
                canon = Fraction(b * c, a) if prop else Fraction(a * b, c)
                if canon.denominator != 1 or canon <= 0 or canon == b:
                    continue
                kand = _prop_kandidaten(a, b, c, prop)
                vals = {canon}
                ueberlebt = []
                for w, l in kand:
                    if tippbar(w, MAX_FEHLBILD_DEZ) and w not in vals:
                        vals.add(w)
                        ueberlebt.append(l)
                if len(ueberlebt) >= 2 and int(canon) not in gesehen_canon:
                    gesehen_canon.add(int(canon))
                    treffer.append((a, b, c))
                    if len(treffer) >= anzahl:
                        return treffer
    return treffer


def proportionalitaet(verworfen: list[str]) -> list[Aufgabe]:
    out = []
    nr = 0
    for prop, sachliste, afb in ((True, _PROP_SACH, "I"), (False, _ANTI_SACH, "II")):
        tripel = _prop_suche(prop, 7)
        for j, (a, b, c) in enumerate(tripel):
            nr += 1
            ref = f"proportionalitaet-{nr:02d}"
            vorn, hinten = sachliste[j % len(sachliste)]
            geg = vorn.format(a=a, b=b, c=c)
            frage = f"{geg} {hinten.format(a=a, b=b, c=c)}"
            canon = Fraction(b * c, a) if prop else Fraction(a * b, c)
            frisch = solve_prop_text(frage)
            a_obj = siebe(ref, "proportionalitaet", afb, "€" if prop else "Stunden",
                          frage, f"Dreisatz · {geg}", canon,
                          _prop_kandidaten(a, b, c, prop), frisch, verworfen)
            if a_obj:
                out.append(a_obj)
    return out


def solve_prop_text(frage: str) -> Fraction:
    # Unabhaengig: liest die ersten drei Zahlen aus dem Text und erkennt an den
    # Schluesselwoertern, ob proportional ("kosten") oder antiproportional
    # ("brauchen"). Rechnet ueber den Zwischenwert je Einheit — sieht canonical nie.
    zahlen = [int(z) for z in re.findall(r"\d+", frage)]
    a, b, c = zahlen[0], zahlen[1], zahlen[2]
    if "kosten" in frage:
        return Fraction(b, a) * c
    return Fraction(a * b, c)


# ════════════════════════════════════════════════════════════════════════════
# GRUPPE 4: RUNDEN
# ════════════════════════════════════════════════════════════════════════════

def _round_half_up(x: Decimal, p: int) -> Decimal:
    return x.quantize(Decimal(1).scaleb(-p), rounding=ROUND_HALF_UP)


def runden(verworfen: list[str]) -> list[Aufgabe]:
    out = []
    # (zahl, stelle p, art) art: 'ab' digit>=5 (abgeschnitten/falsche_stelle),
    #                          'auf' digit<5 (immer_aufgerundet/falsche_stelle)
    # >=3 mit einer 5 an der entscheidenden Stelle.
    specs = [
        # 'ab' = entscheidende Ziffer >= 5 (rundet auf, abgeschnitten weicht ab);
        # 'auf' = entscheidende Ziffer < 5 (rundet ab, immer_aufgerundet weicht ab).
        ("3,47", 1, "ab"), ("2,85", 1, "ab"), ("7,152", 2, "auf"),
        ("4,45", 1, "ab"), ("12,6", 0, "ab"),                          # 2,85/4,45/9,25: 5 an Stelle
        ("5,32", 1, "auf"), ("8,214", 2, "auf"), ("3,71", 1, "auf"),
        ("6,048", 2, "ab"), ("9,25", 1, "ab"),
    ]
    for i, (zahl, p, art) in enumerate(specs, 1):
        ref = f"runden-{i:02d}"
        x = Decimal(zahl.replace(",", "."))
        canon = Fraction(_round_half_up(x, p))
        abgeschnitten = Fraction(_trunc(x, p))
        aufgerundet = Fraction(_ceil(x, p))
        # falsche_stelle: eine Stelle FEINER gerundet (die Zahl selbst bei
        # genug Ziffern) — verschieden von canonical, solange die Zahl mehr
        # Nachkommastellen als p hat. Das Sieb faengt den Rest.
        falsch = Fraction(_round_half_up(x, p + 1))
        kand = []
        if art == "ab":
            kand.append((abgeschnitten, "abgeschnitten"))
        else:
            kand.append((aufgerundet, "immer_aufgerundet"))
        kand.append((falsch, "falsche_stelle"))
        stelle_txt = {0: "eine ganze Zahl", 1: "eine Nachkommastelle",
                      2: "zwei Nachkommastellen"}[p]
        frage = f"Runde auf {stelle_txt}.\n\n{zahl} = ?"
        frisch = solve_runden_text(frage)
        a = siebe(ref, "runden_ueberschlag", "I", "", frage,
                  f"Runden · {zahl}", canon, kand, frisch, verworfen)
        if a:
            out.append(a)
    return out


def _trunc(x: Decimal, p: int) -> Decimal:
    from decimal import ROUND_DOWN
    return x.quantize(Decimal(1).scaleb(-p), rounding=ROUND_DOWN)


def _ceil(x: Decimal, p: int) -> Decimal:
    from decimal import ROUND_UP
    return x.quantize(Decimal(1).scaleb(-p), rounding=ROUND_UP)


def solve_runden_text(frage: str) -> Fraction:
    m = re.search(r"Runde auf (.+?)\.\n\n([-\d,]+)", frage)
    stelle = {"eine ganze Zahl": 0, "eine Nachkommastelle": 1,
              "zwei Nachkommastellen": 2}[m.group(1)]
    x = Decimal(m.group(2).replace(",", "."))
    return Fraction(_round_half_up(x, stelle))


# ════════════════════════════════════════════════════════════════════════════
# SIEB-SELBSTTEST (bekannt schlechte Faelle muessen abgewiesen werden)
# ════════════════════════════════════════════════════════════════════════════

def selbsttest() -> list[str]:
    durch = []
    vw: list[str] = []

    # Minutenanteil 25 (periodisch): canonical (H*60+25)/60 nicht tippbar
    if tippbar(Fraction(2 * 60 + 25, 60), MAX_LOESUNG_DEZ):
        durch.append("Minutenanteil 25 gilt faelschlich als tippbar")

    # Nachkommastelle 0 bei Zeit: 2,0 h -> dezimal == canonical (nicht unterscheidbar)
    if Fraction(2) != Fraction(2) + Fraction(0, 100):
        durch.append("logik kaputt")  # trivial, nur zur Form

    # benachbarte Flaeche (|exp|=1): einheit_uebersprungen == linearer? Test via Sieb
    vw2: list[str] = []
    val, von, nach = Fraction(3), "dm2", "cm2"
    exp = FLA[von][1] - FLA[nach][1]
    canon = _umrechnung(FLA, 100, val, von, nach)
    kand = [(val * Fraction(100) ** (exp - (1 if exp > 0 else -1)), "einheit_uebersprungen")]
    a = siebe("test", "x", "II", "", "Wandle um.\n\n3 dm² = ? cm²", "t", canon, kand,
              canon, vw2)
    if a and any(l == "einheit_uebersprungen" for _, l in a.fehlbilder):
        # bei |exp|=1 ist einheit = val*100^0 = val = 3, canonical=300 — nicht wertgleich,
        # aber didaktisch keine uebersprungene Stufe. Das faengt der Konstruktor
        # (nur |exp|>=2 fuer flaechen-skip), nicht das Sieb — hier nur Doku.
        pass

    # wertgleiches Fehlbild (2,50 gegen 2,5)
    vw3: list[str] = []
    a = siebe("test", "x", "I", "", "f", "t", Fraction("2.5"),
              [(Fraction("2.50"), "wertgleich")], Fraction("2.5"), vw3)
    if a and a.fehlbilder:
        durch.append("wertgleiches Fehlbild 2,50 nicht abgewiesen")

    # Fehlbild mit 6 Nachkommastellen
    vw4: list[str] = []
    a = siebe("test", "x", "I", "", "f", "t", Fraction(5),
              [(Fraction(1, 3), "periodisch")], Fraction(5), vw4)
    if a and a.fehlbilder:
        durch.append("periodisches Fehlbild nicht abgewiesen")

    # 2^2 bei potenzen: mal_exponent == canonical
    vw5: list[str] = []
    a = siebe("test", "potenzen", "I", "", "f", "t", Fraction(4),
              [(Fraction(4), "mal_exponent")], Fraction(4), vw5)
    if a and a.fehlbilder:
        durch.append("2^2 (mal_exponent==canonical) nicht abgewiesen")

    # 3,42 bei runden: abgeschnitten == canonical
    x = Decimal("3.42")
    if Fraction(_round_half_up(x, 1)) == Fraction(_trunc(x, 1)):
        pass  # sie SIND gleich (beide 3,4) -> das Sieb weist abgeschnitten ab
    vw6: list[str] = []
    a = siebe("test", "runden", "I", "", "f", "t", Fraction("3.4"),
              [(Fraction("3.4"), "abgeschnitten")], Fraction("3.4"), vw6)
    if a and a.fehlbilder:
        durch.append("3,42->3,4 (abgeschnitten==canonical) nicht abgewiesen")

    # frisch != konstruiert
    vw7: list[str] = []
    a = siebe("test", "x", "I", "", "f", "t", Fraction(10),
              [(Fraction(3), "x")], Fraction(11), vw7)
    if a is not None:
        durch.append("Abweichung frisch/konstruiert nicht abgewiesen")

    return durch


# ════════════════════════════════════════════════════════════════════════════
# SQL-EMISSION
# ════════════════════════════════════════════════════════════════════════════

def sql_str(s: str) -> str:
    return s.replace("'", "''")


def acceptance(a: Aufgabe) -> str:
    ke = ", ".join(f'"{fmt(w)}": "{l}"' for w, l in a.fehlbilder)
    return '{"canonical": "%s", "known_errors": {%s}}' % (fmt(a.canonical), ke)


def emit(dateiname: str, titel: str, aufgaben: list[Aufgabe], anzahl_soll: int) -> str:
    task_zeilen, sol_zeilen, proben = [], [], []
    for a in aufgaben:
        payload = "jsonb_build_object('kind','short_input','prompt',%s)" % f"'{sql_str(a.frage)}'"
        unit = f"'{sql_str(a.unit)}'" if a.unit else "null"
        task_zeilen.append(
            f"  ('{a.source_ref}', '{a.skill_key}', '{sql_str(a.titel)}', "
            f"'{sql_str(a.frage)}', '{a.afb}', {unit}, {payload})")
        sol_zeilen.append(
            f"  ('{a.source_ref}', '[\"{fmt(a.canonical)}\"]', '{sql_str(acceptance(a))}')")
        proben.append(f"      ('{a.source_ref}', '{fmt(a.canonical)}', 'voll', 'canonical')")
        for w, l in a.fehlbilder:
            proben.append(f"      ('{a.source_ref}', '{fmt(w)}', 'nicht', '{l}')")

    voll = (KOPF + ",\n".join(task_zeilen) + TASKS_FUSS
            + ",\n".join(sol_zeilen) + PROBEN_KOPF
            + ",\n".join(proben) + FUSS)
    return voll.replace("@TITEL@", titel).replace("@ANZAHL@", str(anzahl_soll))


KOPF = """-- ============================================================================
-- @TITEL@ — Fundament-Charge 2 als DRAFT (@ANZAHL@ Aufgaben)
--
-- ERZEUGT von scripts/content/fundament_charge2.py. Nicht von Hand pflegen.
--
-- LAEUFT NICHT AUTOMATISCH. Von Hand einspielen:
--     psql "$DATABASE_URL" -f supabase/seeds/<diese-datei>.sql
--
-- SETZT A13 (TERM-Grader-Fix) + A14 (skills, tasks.skill_key) VORAUS.
--
-- ANTWORTFORM: input_type NUMERIC, canonical ist eine REINE ZAHL. Die Einheit
-- steht im Fragetext und in tasks.unit (-> payload.unit). Das Kind tippt nur die
-- Zahl. Weil der Rest hinter der Zahl leer ist, greift der Wert-Pfad von
-- lsa_grade, NICHT der TERM-Zweig (Selbsttest 3b unten zeigt es).
--
-- STATUS: alles 'draft'. Freigabe ist Lenas Schritt.
-- SOLUTION-LEAK: canonical + known_errors nur in task_solutions (kein
-- anon/authenticated-Grant). tasks.question_payload traegt nur prompt + unit.
--
-- IDEMPOTENT ueber (source, source_ref).
-- ============================================================================

begin;

do $$
begin
  if not exists (select 1 from information_schema.columns
                  where table_name='tasks' and column_name='skill_key') then
    raise exception 'tasks.skill_key fehlt — A14 erst einspielen.';
  end if;
end $$;

insert into tasks (
  source, source_ref, content_type, input_type, status, is_active, is_diagnostic,
  skill_key, title, question, afb, curriculum_grade, needs_image,
  cluster_id, competency_content, competency_process, competency_id, unit, question_payload
)
select
  'edvance_fundament', v.source_ref, 'exercise', 'NUMERIC', 'draft', true, false,
  v.skill_key, v.titel, v.frage, v.afb, 7, false,
  (select sc.id from skill_clusters sc join subjects s on s.id = sc.subject_id
    where s.name = 'Mathematik' and sc.name = 'Zahl & Rechnen' limit 1),
  'arithmetik_algebra', 'Operieren',
  (select pc.id from process_competencies pc where pc.code = 'Ope' limit 1),
  v.unit, v.payload
from (values
"""

TASKS_FUSS = """
) as v(source_ref, skill_key, titel, frage, afb, unit, payload)
on conflict (source, source_ref) do nothing;

insert into task_solutions (task_id, correct_answers, acceptance, updated_at)
select t.id, v.correct_answers::jsonb, v.acceptance::jsonb, now()
from (values
"""

PROBEN_KOPF = """
) as v(source_ref, correct_answers, acceptance)
join tasks t on t.source = 'edvance_fundament' and t.source_ref = v.source_ref
on conflict (task_id) do update
   set correct_answers = excluded.correct_answers,
       acceptance      = excluded.acceptance,
       updated_at      = now();

-- ── Selbsttest ─────────────────────────────────────────────────────────────
--   canonical -> 'voll', jedes Fehlbild -> 'nicht'. Weicht eine Probe ab,
--   bricht die Transaktion ab und NICHTS wird eingespielt.

do $$
declare
  r        record;
  v_urteil text;
  v_fehler int := 0;
  v_anzahl int;
begin
  for r in
    select * from (values
"""

FUSS = """
    ) as p(source_ref, antwort, erwartet, label)
  loop
    select public.lsa_grade('NUMERIC', s.acceptance, s.correct_answers,
                            jsonb_build_object('text', r.antwort))
      into v_urteil
      from task_solutions s join tasks t on t.id = s.task_id
     where t.source = 'edvance_fundament' and t.source_ref = r.source_ref;
    if v_urteil is distinct from r.erwartet then
      v_fehler := v_fehler + 1;
      raise warning 'Probe %/% : lsa_grade sagt %, erwartet % (%)',
        r.source_ref, r.antwort, coalesce(v_urteil,'<null>'), r.erwartet, r.label;
    end if;
  end loop;

  -- 3b: diese Aufgaben betreten den TERM-Zweig NICHT (Rest hinter der Zahl leer).
  for r in
    select distinct s.acceptance ->> 'canonical' as canon
      from task_solutions s join tasks t on t.id = s.task_id
     where t.source = 'edvance_fundament' and t.source_ref like '@REFPREFIX@%'
  loop
    if not public.lsa_is_unit((public.lsa_split_value_unit(r.canon))[2]) then
      v_fehler := v_fehler + 1;
      raise warning 'canonical % betritt den TERM/Einheit-Zweig — Rest ist keine leere Einheit', r.canon;
    end if;
  end loop;

  if v_fehler > 0 then
    raise exception '% Probe(n) fehlgeschlagen — nichts eingespielt.', v_fehler;
  end if;

  select count(*) into v_anzahl from tasks
   where source='edvance_fundament' and source_ref like '@REFPREFIX@%' and status <> 'draft';
  if v_anzahl > 0 then
    raise exception '% Aufgabe(n) stehen nicht auf draft.', v_anzahl;
  end if;

  raise notice '@TITEL@: alle Proben bestanden.';
end $$;

commit;
"""


def main() -> None:
    durch = selbsttest()
    if durch:
        raise SystemExit("Sieb-Selbsttest fehlgeschlagen:\n  " + "\n  ".join(durch))
    print("Sieb-Selbsttest: alle bekannt schlechten Faelle abgewiesen.")

    verworfen: list[str] = []

    groessen = (groessen_laengen(verworfen) + groessen_massen(verworfen)
                + groessen_zeit(verworfen) + groessen_flaechen(verworfen)
                + groessen_volumen(verworfen) + groessen_gemischt(verworfen))
    pot = potenzen(verworfen)
    prop = proportionalitaet(verworfen)
    rnd = runden(verworfen)

    dateien = [
        ("20260723_groessen_fundament_01.sql", "Größen und Einheiten", groessen, 34, "groessen-"),
        ("20260723_potenzen_fundament_01.sql", "Potenzen und Quadratzahlen", pot, 16, "potenzen-"),
        ("20260723_proportionalitaet_fundament_01.sql", "Proportionalität und Dreisatz", prop, 14, "proportionalitaet-"),
        ("20260723_runden_fundament_01.sql", "Runden und Überschlag", rnd, 10, "runden-"),
    ]
    labels: set[str] = set()
    for name, titel, aufg, soll, prefix in dateien:
        sql = emit(name, titel, aufg, soll).replace("@REFPREFIX@", prefix)
        (SEEDS / name).write_text(sql, encoding="utf-8")
        for a in aufg:
            labels.update(l for _, l in a.fehlbilder)
        print(f"{name}: {len(aufg)} Aufgaben "
              f"({sum(len(a.fehlbilder) for a in aufg)} Fehlbilder)")

    print("\nknown_errors-Labels (alle):")
    for l in sorted(labels):
        print(f"  {l}")
    if verworfen:
        print("\nVerworfen / weggelassen:")
        for v in verworfen:
            print(f"  - {v}")


if __name__ == "__main__":
    main()
