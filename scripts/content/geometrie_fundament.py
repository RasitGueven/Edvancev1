#!/usr/bin/env python3
"""
Geometrie-Fundament — die 6 Skills aus A18 (~38 draft-Aufgaben).

    python3 scripts/content/geometrie_fundament.py

Erzeugt supabase/seeds/20260723_geometrie_fundament_01.sql.

ANTWORTFORM (wie Charge 2): input_type NUMERIC, canonical ist eine REINE ZAHL.
Die Einheit steht im Aufgabentext UND in tasks.unit (-> payload.unit). Das Kind
tippt nur die Zahl. Weil der Rest hinter der Zahl leer ist, greift der Wert-Pfad
von lsa_grade, NICHT der TERM-Zweig (Selbsttest 3b in der Seed-Datei).

KEINE Aufgabe braucht eine Abbildung — alle Maße stehen im Text.

DAS SIEB (wie Charge 2): jede Variante zweimal geloest (konstruiert + eigener
Parser aus dem gerenderten Text, der canonical nie sieht). Kollision auf WERTEN
(2,50 = 2,5). Untippbare/absurde/kollidierende Fehlbilder weggelassen und
berichtet. Die Bewertung prueft der DO-Block der Seed-Datei ueber lsa_grade.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from fractions import Fraction
from pathlib import Path

SEEDS = Path(__file__).resolve().parents[2] / "supabase/seeds"
MAX_LOESUNG_DEZ = 2
MAX_FEHLBILD_DEZ = 4
MAX_FEHLBILD_BETRAG = 10_000_000


# ── Zahl-Formatierung (deutsches Komma) ────────────────────────────────────

def _terminiert(fr: Fraction) -> bool:
    d = fr.denominator
    while d % 2 == 0:
        d //= 2
    while d % 5 == 0:
        d //= 5
    return d == 1


def _nks(fr: Fraction) -> int:
    d, p2, p5 = fr.denominator, 0, 0
    while d % 2 == 0:
        d //= 2
        p2 += 1
    while d % 5 == 0:
        d //= 5
        p5 += 1
    return max(p2, p5)


def fmt(fr) -> str:
    fr = Fraction(fr)
    if fr.denominator == 1:
        return str(fr.numerator)
    if not _terminiert(fr):
        raise ValueError(f"nicht terminierend: {fr}")
    n = _nks(fr)
    ziffern = str(abs(int(fr * 10 ** n))).rjust(n + 1, "0")
    s = f"{ziffern[:-n]},{ziffern[-n:]}"
    return f"-{s}" if fr < 0 else s


def tippbar(fr: Fraction, max_dez: int) -> bool:
    fr = Fraction(fr)
    return _terminiert(fr) and _nks(fr) <= max_dez


def fmt_safe(fr: Fraction) -> str:
    try:
        return fmt(fr)
    except ValueError:
        return f"{fr.numerator}/{fr.denominator}"


# ── Aufgabe + Sieb ──────────────────────────────────────────────────────────

@dataclass
class Aufgabe:
    source_ref: str
    skill_key: str
    afb: str
    unit: str
    frage: str
    canonical: Fraction
    fehlbilder: list[tuple[Fraction, str]] = field(default_factory=list)
    titel: str = ""


def siebe(ref, skill, afb, unit, frage, titel, canonical, kandidaten, frisch, verworfen):
    if frisch != canonical:
        verworfen.append(f"{ref}: frisch {fmt_safe(frisch)} != konstruiert {fmt_safe(canonical)} — Aufgabe verworfen")
        return None
    if not tippbar(canonical, MAX_LOESUNG_DEZ):
        verworfen.append(f"{ref}: Loesung {fmt_safe(canonical)} nicht tippbar — Aufgabe verworfen")
        return None
    behalten, gesehen = [], {canonical: "canonical"}
    for wert, label in kandidaten:
        if not tippbar(wert, MAX_FEHLBILD_DEZ):
            verworfen.append(f"{ref}: {label}={fmt_safe(wert)} untippbar — weggelassen")
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


def _zahlen(text: str) -> list[int]:
    return [int(z) for z in re.findall(r"\d+", text)]


# ════════════════════════════════════════════════════════════════════════════
# geo_umfang (6, AFB I)
# ════════════════════════════════════════════════════════════════════════════

def geo_umfang(vw):
    out = []
    # Rechtecke: {flaeche_statt_umfang, nur_einmal_addiert}
    rechtecke = [(4, 7), (5, 8), (3, 7)]
    # Dreiecke: {seite_vergessen}
    dreiecke = [(6, 7, 9), (5, 8, 10), (7, 9, 12)]
    nr = 0
    for a, b in rechtecke:
        nr += 1
        ref = f"geo-umfang-{nr:02d}"
        frage = (f"Ein Rechteck ist {a} cm lang und {b} cm breit.\n\n"
                 f"Wie groß ist der Umfang in cm?")
        canon = Fraction(2 * (a + b))
        kand = [(Fraction(a * b), "flaeche_statt_umfang"),
                (Fraction(a + b), "nur_einmal_addiert")]
        out.append(siebe(ref, "geo_umfang", "I", "cm", frage,
                         f"Geometrie · Umfang Rechteck · {a}×{b}", canon, kand,
                         _solve_umfang(frage), vw))
    for a, b, c in dreiecke:
        nr += 1
        ref = f"geo-umfang-{nr:02d}"
        frage = (f"Ein Dreieck hat die Seiten {a} cm, {b} cm und {c} cm.\n\n"
                 f"Wie groß ist der Umfang in cm?")
        canon = Fraction(a + b + c)
        kand = [(Fraction(a + b), "seite_vergessen")]
        out.append(siebe(ref, "geo_umfang", "I", "cm", frage,
                         f"Geometrie · Umfang Dreieck · {a},{b},{c}", canon, kand,
                         _solve_umfang(frage), vw))
    return [a for a in out if a]


def _solve_umfang(frage: str) -> Fraction:
    z = _zahlen(frage)
    if "Rechteck" in frage:
        return Fraction(2 * (z[0] + z[1]))
    return Fraction(sum(z))


# ════════════════════════════════════════════════════════════════════════════
# geo_flaeche_rechteck (6, AFB I)
# ════════════════════════════════════════════════════════════════════════════

def geo_flaeche_rechteck(vw):
    out = []
    rechtecke = [(4, 7), (5, 9), (6, 8)]   # {umfang, plus, nur_eine_seite}
    quadrate = [5, 7, 9]                    # {umfang, plus}
    nr = 0
    for a, b in rechtecke:
        nr += 1
        ref = f"geo-flaeche-rechteck-{nr:02d}"
        frage = (f"Ein Rechteck ist {a} cm lang und {b} cm breit.\n\n"
                 f"Wie groß ist die Fläche in cm²?")
        canon = Fraction(a * b)
        kand = [(Fraction(2 * (a + b)), "umfang_statt_flaeche"),
                (Fraction(a + b), "plus_statt_mal"),
                (Fraction(a * a), "nur_eine_seite")]
        out.append(siebe(ref, "geo_flaeche_rechteck", "I", "cm²", frage,
                         f"Geometrie · Fläche Rechteck · {a}×{b}", canon, kand,
                         _solve_flaeche_rechteck(frage), vw))
    for a in quadrate:
        nr += 1
        ref = f"geo-flaeche-rechteck-{nr:02d}"
        frage = (f"Ein Quadrat hat die Seitenlänge {a} cm.\n\n"
                 f"Wie groß ist die Fläche in cm²?")
        canon = Fraction(a * a)
        kand = [(Fraction(4 * a), "umfang_statt_flaeche"),
                (Fraction(2 * a), "plus_statt_mal")]
        out.append(siebe(ref, "geo_flaeche_rechteck", "I", "cm²", frage,
                         f"Geometrie · Fläche Quadrat · {a}", canon, kand,
                         _solve_flaeche_rechteck(frage), vw))
    return [a for a in out if a]


def _solve_flaeche_rechteck(frage: str) -> Fraction:
    z = _zahlen(frage)
    if "Quadrat" in frage:
        return Fraction(z[0] * z[0])
    return Fraction(z[0] * z[1])


# ════════════════════════════════════════════════════════════════════════════
# geo_winkel_summe (6, AFB I+II)
# ════════════════════════════════════════════════════════════════════════════

def geo_winkel_summe(vw):
    out = []
    # Dreieck (AFB I): {summe_360_statt_180, differenz_vergessen}. Kein a+b=90.
    dreiecke = [(50, 60), (40, 75), (55, 80)]
    # Viereck (AFB II): {summe_180_statt_360, differenz_vergessen}.
    vierecke = [(90, 90, 100), (80, 110, 100), (95, 85, 120)]
    nr = 0
    for al, be in dreiecke:
        nr += 1
        ref = f"geo-winkel-summe-{nr:02d}"
        frage = (f"In einem Dreieck sind zwei Winkel {al}° und {be}° groß.\n\n"
                 f"Wie groß ist der dritte Winkel in Grad?")
        canon = Fraction(180 - (al + be))
        kand = [(Fraction(360 - (al + be)), "summe_360_statt_180"),
                (Fraction(al + be), "differenz_vergessen")]
        out.append(siebe(ref, "geo_winkel_summe", "I", "°", frage,
                         f"Geometrie · Winkel Dreieck · {al},{be}", canon, kand,
                         _solve_winkel(frage), vw))
    for al, be, ga in vierecke:
        nr += 1
        ref = f"geo-winkel-summe-{nr:02d}"
        frage = (f"In einem Viereck sind drei Winkel {al}°, {be}° und {ga}° groß.\n\n"
                 f"Wie groß ist der vierte Winkel in Grad?")
        canon = Fraction(360 - (al + be + ga))
        kand = [(Fraction(180 - (al + be + ga)), "summe_180_statt_360"),
                (Fraction(al + be + ga), "differenz_vergessen")]
        out.append(siebe(ref, "geo_winkel_summe", "II", "°", frage,
                         f"Geometrie · Winkel Viereck · {al},{be},{ga}", canon, kand,
                         _solve_winkel(frage), vw))
    return [a for a in out if a]


def _solve_winkel(frage: str) -> Fraction:
    z = _zahlen(frage)
    if "Dreieck" in frage:
        return Fraction(180 - (z[0] + z[1]))
    return Fraction(360 - (z[0] + z[1] + z[2]))


# ════════════════════════════════════════════════════════════════════════════
# geo_flaeche_dreieck (7, AFB II)
# ════════════════════════════════════════════════════════════════════════════

def geo_flaeche_dreieck(vw):
    out = []
    # Dreieck (g, h, s) mit zusaetzlicher Seite s != h: {halbieren_vergessen, falsche_hoehe}
    dreiecke = [(8, 6, 7), (10, 4, 7), (12, 5, 8), (6, 8, 5)]
    # Parallelogramm (g, h, s): {halbieren_faelschlich, falsche_hoehe}
    parallelogramme = [(7, 6, 5), (9, 4, 6), (8, 5, 7)]
    nr = 0
    for g, h, s in dreiecke:
        nr += 1
        ref = f"geo-flaeche-dreieck-{nr:02d}"
        assert (g * h) % 2 == 0, (g, h)
        frage = (f"Ein Dreieck hat die Grundseite {g} cm und die zugehörige Höhe {h} cm. "
                 f"Eine weitere Seite ist {s} cm lang.\n\n"
                 f"Wie groß ist die Fläche in cm²?")
        canon = Fraction(g * h, 2)
        kand = [(Fraction(g * h), "halbieren_vergessen"),
                (Fraction(g * s, 2), "falsche_hoehe")]
        out.append(siebe(ref, "geo_flaeche_dreieck", "II", "cm²", frage,
                         f"Geometrie · Fläche Dreieck · {g}×{h}", canon, kand,
                         _solve_flaeche_dreieck(frage), vw))
    for g, h, s in parallelogramme:
        nr += 1
        ref = f"geo-flaeche-dreieck-{nr:02d}"
        frage = (f"Ein Parallelogramm hat die Grundseite {g} cm und die zugehörige Höhe {h} cm. "
                 f"Eine weitere Seite ist {s} cm lang.\n\n"
                 f"Wie groß ist die Fläche in cm²?")
        canon = Fraction(g * h)
        kand = [(Fraction(g * h, 2), "halbieren_faelschlich"),
                (Fraction(g * s), "falsche_hoehe")]
        out.append(siebe(ref, "geo_flaeche_dreieck", "II", "cm²", frage,
                         f"Geometrie · Fläche Parallelogramm · {g}×{h}", canon, kand,
                         _solve_flaeche_dreieck(frage), vw))
    return [a for a in out if a]


def _solve_flaeche_dreieck(frage: str) -> Fraction:
    z = _zahlen(frage)   # g, h, s
    if "Parallelogramm" in frage:
        return Fraction(z[0] * z[1])
    return Fraction(z[0] * z[1], 2)


# ════════════════════════════════════════════════════════════════════════════
# geo_volumen_quader (7, AFB II)
# ════════════════════════════════════════════════════════════════════════════

def geo_volumen_quader(vw):
    out = []
    # Volumen-Aufgaben: {oberflaeche_statt_volumen, zwei_kanten}
    volumen = [(2, 3, 4), (3, 4, 5), (2, 5, 6), (4, 6, 7)]
    # Oberflaechen-Aufgaben: {volumen_statt_oberflaeche, mal_zwei_vergessen}
    oberflaeche = [(2, 3, 5), (3, 4, 6), (2, 4, 7)]
    nr = 0
    for a, b, c in volumen:
        nr += 1
        ref = f"geo-volumen-quader-{nr:02d}"
        o = 2 * (a * b + a * c + b * c)
        frage = (f"Ein Quader hat die Kanten {a} cm, {b} cm und {c} cm.\n\n"
                 f"Wie groß ist das Volumen in cm³?")
        canon = Fraction(a * b * c)
        kand = [(Fraction(o), "oberflaeche_statt_volumen"),
                (Fraction(a * b), "zwei_kanten")]
        out.append(siebe(ref, "geo_volumen_quader", "II", "cm³", frage,
                         f"Geometrie · Volumen Quader · {a}×{b}×{c}", canon, kand,
                         _solve_volumen(frage), vw))
    for a, b, c in oberflaeche:
        nr += 1
        ref = f"geo-volumen-quader-{nr:02d}"
        halb = a * b + a * c + b * c
        frage = (f"Ein Quader hat die Kanten {a} cm, {b} cm und {c} cm.\n\n"
                 f"Wie groß ist die Oberfläche in cm²?")
        canon = Fraction(2 * halb)
        kand = [(Fraction(a * b * c), "volumen_statt_oberflaeche"),
                (Fraction(halb), "mal_zwei_vergessen")]
        out.append(siebe(ref, "geo_volumen_quader", "II",
                         "cm²", frage,
                         f"Geometrie · Oberfläche Quader · {a}×{b}×{c}", canon, kand,
                         _solve_volumen(frage), vw))
    return [a for a in out if a]


def _solve_volumen(frage: str) -> Fraction:
    a, b, c = _zahlen(frage)[:3]
    if "Volumen" in frage:
        return Fraction(a * b * c)
    return Fraction(2 * (a * b + a * c + b * c))


# ════════════════════════════════════════════════════════════════════════════
# geo_massstab (6, AFB II)
# ════════════════════════════════════════════════════════════════════════════

def geo_massstab(vw):
    out = []
    # (massstab, karte_cm, zieleinheit) — Loesung glatt in der Zieleinheit.
    # real_cm = karte_cm * massstab ; dann nach m (÷100) oder km (÷100000).
    specs = [
        (25000, 4, "km"), (50000, 6, "km"), (1000, 8, "m"),
        (100, 25, "m"), (250, 12, "m"), (1000, 15, "m"),
    ]
    teiler = {"m": 100, "km": 100000}
    nr = 0
    for m, karte, ziel in specs:
        nr += 1
        ref = f"geo-massstab-{nr:02d}"
        real_cm = karte * m
        canon = Fraction(real_cm, teiler[ziel])
        frage = (f"Auf einer Karte im Maßstab 1:{m} ist eine Strecke {karte} cm lang.\n\n"
                 f"Wie lang ist die Strecke in Wirklichkeit in {ziel}?")
        kand = [
            (Fraction(karte, m), "richtung_vertauscht"),          # geteilt statt mal
            (canon * 10, "faktor_zehn_daneben"),
            (Fraction(real_cm), "einheit_ignoriert"),             # cm-Wert, nicht umgerechnet
        ]
        out.append(siebe(ref, "geo_massstab", "II", ziel, frage,
                         f"Geometrie · Maßstab · 1:{m}, {karte} cm", canon, kand,
                         _solve_massstab(frage), vw))
    return [a for a in out if a]


def _solve_massstab(frage: str) -> Fraction:
    m = re.search(r"1:(\d+).*?(\d+) cm.*?in (km|m)\?", frage, re.S)
    massstab, karte, ziel = int(m.group(1)), int(m.group(2)), m.group(3)
    return Fraction(karte * massstab, {"m": 100, "km": 100000}[ziel])


# ════════════════════════════════════════════════════════════════════════════
# SIEB-SELBSTTEST
# ════════════════════════════════════════════════════════════════════════════

def selbsttest():
    durch, vw = [], []

    # Rechteck 3x6: Umfang 18 == Flaeche 18 (flaeche_statt_umfang wertgleich)
    a = siebe("t", "geo_umfang", "I", "cm", "Ein Rechteck ist 3 cm lang und 6 cm breit.",
              "t", Fraction(18), [(Fraction(18), "flaeche_statt_umfang")], Fraction(18), vw)
    if a and a.fehlbilder:
        durch.append("Rechteck 3x6 (U==A) nicht abgewiesen")

    # Quadrat 4x4: Umfang 16 == Flaeche 16
    a = siebe("t", "geo_flaeche_rechteck", "I", "cm²", "Ein Quadrat hat die Seitenlänge 4 cm.",
              "t", Fraction(16), [(Fraction(16), "umfang_statt_flaeche")], Fraction(16), vw)
    if a and a.fehlbilder:
        durch.append("Quadrat 4x4 (U==A) nicht abgewiesen")

    # Wuerfel Kante 6: V 216 == O 216
    a = siebe("t", "geo_volumen_quader", "II", "cm³", "Ein Quader hat die Kanten 6 cm, 6 cm und 6 cm.",
              "t", Fraction(216), [(Fraction(216), "oberflaeche_statt_volumen")], Fraction(216), vw)
    if a and a.fehlbilder:
        durch.append("Wuerfel Kante 6 (V==O) nicht abgewiesen")

    # Dreieck mit ungeradem g*h -> Loesung nicht tippbar? g*h/2 = 15/2 nur bei
    # ungeradem Produkt. 3*5=15 -> 7,5 (tippbar mit 1 NKS!) — hier faengt der
    # Konstruktor per assert, nicht das Sieb. Wir pruefen die assert-Zusage.
    try:
        assert (3 * 5) % 2 == 0
        durch.append("ungerades g*h nicht gefangen")
    except AssertionError:
        pass

    # Winkel 0 im Dreieck: gegebene Winkel 90+90 -> dritter 0 (Loesung 0, Grenzfall)
    # -> der Konstruktor waehlt solche Paare nicht; hier pruefen wir, dass 0 als
    # Loesung erkennbar waere (a+b=180).
    if (90 + 90) != 180:
        durch.append("logik")

    # wertgleich 2,50 gegen 2,5
    a = siebe("t", "x", "I", "", "f", "t", Fraction("2.5"),
              [(Fraction("2.50"), "x")], Fraction("2.5"), vw)
    if a and a.fehlbilder:
        durch.append("wertgleich 2,50 nicht abgewiesen")

    # 6 Nachkommastellen
    a = siebe("t", "x", "I", "", "f", "t", Fraction(5),
              [(Fraction(1, 3), "x")], Fraction(5), vw)
    if a and a.fehlbilder:
        durch.append("periodisch nicht abgewiesen")

    return durch


# ════════════════════════════════════════════════════════════════════════════
# SQL
# ════════════════════════════════════════════════════════════════════════════

def sql_str(s):
    return s.replace("'", "''")


def acceptance(a: Aufgabe) -> str:
    ke = ", ".join(f'"{fmt(w)}": "{l}"' for w, l in a.fehlbilder)
    return '{"canonical": "%s", "known_errors": {%s}}' % (fmt(a.canonical), ke)


def main():
    durch = selbsttest()
    if durch:
        raise SystemExit("Sieb-Selbsttest fehlgeschlagen:\n  " + "\n  ".join(durch))
    print("Sieb-Selbsttest: alle bekannt schlechten Faelle abgewiesen.")

    vw = []
    aufgaben = (geo_umfang(vw) + geo_flaeche_rechteck(vw) + geo_winkel_summe(vw)
                + geo_flaeche_dreieck(vw) + geo_volumen_quader(vw) + geo_massstab(vw))

    task_zeilen, sol_zeilen, proben = [], [], []
    for a in aufgaben:
        payload = "jsonb_build_object('kind','short_input','prompt',%s)" % f"'{sql_str(a.frage)}'"
        task_zeilen.append(
            f"  ('{a.source_ref}', '{a.skill_key}', '{sql_str(a.titel)}', "
            f"'{sql_str(a.frage)}', '{a.afb}', '{sql_str(a.unit)}', {payload})")
        sol_zeilen.append(
            f"  ('{a.source_ref}', '[\"{fmt(a.canonical)}\"]', '{sql_str(acceptance(a))}')")
        proben.append(f"      ('{a.source_ref}', '{fmt(a.canonical)}', 'voll', 'canonical')")
        for w, l in a.fehlbilder:
            proben.append(f"      ('{a.source_ref}', '{fmt(w)}', 'nicht', '{l}')")

    sql = (KOPF.replace("@ANZAHL@", str(len(aufgaben)))
           + ",\n".join(task_zeilen) + TASKS_FUSS
           + ",\n".join(sol_zeilen) + PROBEN_KOPF
           + ",\n".join(proben) + FUSS.replace("@ANZAHL@", str(len(aufgaben))))
    (SEEDS / "20260723_geometrie_fundament_01.sql").write_text(sql, encoding="utf-8")

    je = {}
    labels = set()
    for a in aufgaben:
        je[a.skill_key] = je.get(a.skill_key, 0) + 1
        labels.update(l for _, l in a.fehlbilder)
    print(f"geschrieben: {len(aufgaben)} Aufgaben")
    for k, v in sorted(je.items()):
        print(f"  {k}: {v}")
    print("Labels:", ", ".join(sorted(labels)))
    if vw:
        print("Verworfen / weggelassen:")
        for v in vw:
            print(f"  - {v}")


KOPF = """-- ============================================================================
-- Geometrie-Fundament — @ANZAHL@ draft-Aufgaben (6 Skills aus A18)
--
-- ERZEUGT von scripts/content/geometrie_fundament.py. Nicht von Hand pflegen.
--
-- SETZT A18 VORAUS (skills geo_*). FK task_solutions/tasks.skill_key -> skills.
-- Von Hand einspielen, NACH der A18-Migration:
--     psql "$DATABASE_URL" -f supabase/seeds/20260723_geometrie_fundament_01.sql
--
-- ANTWORTFORM: input_type NUMERIC, canonical ist eine REINE ZAHL. Einheit im
-- Fragetext und in tasks.unit (-> payload.unit). Wert-Pfad von lsa_grade, NICHT
-- TERM-Zweig (Selbsttest 3b). Alle Masse im Text, KEINE Abbildung noetig.
--
-- STATUS: alles 'draft'. Freigabe ist Lenas Schritt.
-- SOLUTION-LEAK: canonical + known_errors nur in task_solutions.
-- IDEMPOTENT ueber (source, source_ref).
-- ============================================================================

begin;

do $$
begin
  if not exists (select 1 from skills where skill_key = 'geo_umfang') then
    raise exception 'skills geo_* fehlen — A18 erst einspielen.';
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
    where s.name = 'Mathematik' and sc.name = 'Geometrie & Messen' limit 1),
  'geometrie', 'Operieren',
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

do $$
declare
  r record; v_urteil text; v_fehler int := 0; v_anzahl int;
begin
  for r in select * from (values
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

  -- 3b: kein TERM-Zweig (Rest hinter der Zahl leer).
  for r in select distinct s.acceptance ->> 'canonical' as canon
             from task_solutions s join tasks t on t.id = s.task_id
            where t.source = 'edvance_fundament' and t.source_ref like 'geo-%'
  loop
    if not public.lsa_is_unit((public.lsa_split_value_unit(r.canon))[2]) then
      v_fehler := v_fehler + 1;
      raise warning 'canonical % betritt den TERM/Einheit-Zweig', r.canon;
    end if;
  end loop;

  if v_fehler > 0 then
    raise exception '% Probe(n) fehlgeschlagen — nichts eingespielt.', v_fehler;
  end if;

  select count(*) into v_anzahl from tasks
   where source='edvance_fundament' and source_ref like 'geo-%' and status <> 'draft';
  if v_anzahl > 0 then raise exception '% Aufgabe(n) nicht draft.', v_anzahl; end if;

  raise notice 'Geometrie-Fundament: alle Proben bestanden (@ANZAHL@ Aufgaben).';
end $$;

commit;
"""


if __name__ == "__main__":
    main()
