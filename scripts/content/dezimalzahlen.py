#!/usr/bin/env python3
"""Dezimalzahl-Fundamentaufgaben erzeugen — als Seed-Datei.

    python3 scripts/content/dezimalzahlen.py

Schreibt:
    supabase/seeds/20260722_dezimalzahlen_01.sql
    data/dezimalzahlen_01_report.json

Vierte Charge nach Bruechen, Vorzeichen und Gleichungen/Prozent. Dieselbe
Bauart: binaer (kein require_reduced, kein 'teilweise'), known_errors von
Anfang an, Sieb mit Selbsttest und Negativkontrolle.

LIVE GEPRUEFT (2026-07-22): lsa_values_equal vergleicht WERTGLEICH.
"0,30" = "0,3" ist true, "0,7" = "0.7" ist true. Zwei Folgen:
  * Ein Fehlbild braucht nur EINE Schreibweise — die kuerzeste reicht.
  * Ein Fehlbild, das WERTGLEICH zur Loesung ist, wuerde als 'voll' durchgehen.
    Genau das prueft das Sieb (Trennschaerfe auf Werten, nicht auf Strings).

WAS DAS SKRIPT NICHT TUT: Es fasst die Datenbank nicht an.
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass, field
from fractions import Fraction
from pathlib import Path

WURZEL = Path(__file__).resolve().parents[2]
SEED = WURZEL / "supabase" / "seeds" / "20260722_dezimalzahlen_01.sql"
BERICHT = WURZEL / "data" / "dezimalzahlen_01_report.json"

QUELLE = "edvance_fundament"

LABELS = {
    "stellenwert_ignoriert",
    "uebertrag_vergessen",
    "kommastellen_zu_wenig",
    "kommastellen_zu_viel",
    "komma_ignoriert",
    "komma_nicht_verschoben",
    "falsche_richtung",
    "ziffern_gelesen",
    "umgekehrt_geteilt",
}


def zahl(w: Fraction) -> str:
    """Deutsche Schreibweise, kuerzeste korrekte Form — "0,75", nicht "0,750"."""
    if w.denominator == 1:
        return str(w.numerator)
    s = f"{float(w):.10f}".rstrip("0").rstrip(".")
    return s.replace(".", ",")


def dez(text: str) -> Fraction:
    """"0,25" → Fraction(1,4). Exakt, ohne Umweg ueber float."""
    text = text.replace(",", ".")
    if "." not in text:
        return Fraction(int(text))
    ganzer, nach = text.split(".")
    return Fraction(int(ganzer or 0)) + Fraction(int(nach), 10 ** len(nach))


def nachkomma(text: str) -> str:
    """Die Ziffern hinter dem Komma, als Zeichenkette."""
    return text.split(",")[1] if "," in text else ""


def endlich(w: Fraction) -> bool:
    """Bricht die Dezimaldarstellung ab? Nur Zweier- und Fuenferpotenzen im Nenner."""
    n = w.denominator
    for p in (2, 5):
        while n % p == 0:
            n //= p
    return n == 1


def tippbar(w: Fraction) -> bool:
    """Ein Wert, den ein Kind hinschreibt: endlich und hoechstens vier Stellen.

    Aus dem Prozent-Lauf uebernommen und hier geweitet: dort reichten zwei
    Nachkommastellen, hier braucht es vier — "0,027" (Kommastellen zu viel) ist
    ein echtes Fehlbild und muss bleiben. Was faellt, sind periodische Werte
    wie 1,333333, die niemand so aufschreibt.
    """
    return endlich(w) and 10_000 % w.denominator == 0


@dataclass
class Variante:
    skill: str
    ref: str
    titel: str
    frage: str
    afb: str
    loesung: Fraction
    fehlbilder: dict[str, Fraction]
    verworfen: str | None = None
    weggelassen: list[str] = field(default_factory=list)
    proben: list[dict[str, str]] = field(default_factory=list)


# ── D-A: Addieren/Subtrahieren mit Komma ────────────────────────────────────
#
# BEIDE Fehlbilder derselben Familie schreiben die Summe der Nachkomma-ZIFFERN
# hinter das Komma. Was sie unterscheidet, ist die URSACHE — und die haengt an
# der Zahlenwahl:
#
#   Ungleich viele Nachkommastellen  → die Stellenwerte wurden nicht
#     ausgerichtet (0,5 + 0,25 → 5+25 = 30 → "0,30").  stellenwert_ignoriert
#   Gleich viele + Uebertrag         → die Stellenwerte stimmen, aber der
#     Uebertrag in die Einer fehlt (0,7 + 0,5 → 7+5 = 12 → "0,12").
#     uebertrag_vergessen
#
# Gleich viele Stellen OHNE Uebertrag ergibt genau die richtige Antwort — dann
# ist der Fehler unsichtbar und die Aufgabe diagnostisch wertlos. Das faengt
# das Sieb ab.


def d_addieren(a: str, b: str, i: int) -> Variante:
    wa, wb = dez(a), dez(b)
    loesung = wa + wb

    na, nb = nachkomma(a), nachkomma(b)
    summe_ziffern = int(na or "0") + int(nb or "0")
    # So schreibt das Kind es hin: "0," und dann die Ziffern der Summe.
    fehlwert = Fraction(summe_ziffern, 10 ** len(str(summe_ziffern)))

    label = "stellenwert_ignoriert" if len(na) != len(nb) else "uebertrag_vergessen"

    return Variante(
        skill="DA_addieren",
        ref=f"dezimal-addieren-{i:02d}",
        titel=f"Dezimalzahlen · Addieren · {a} + {b}",
        frage=f"Berechne.\n\n{a} + {b} = ?",
        afb="I",
        loesung=loesung,
        fehlbilder={label: fehlwert},
    )


# ── D-B: Multiplizieren ─────────────────────────────────────────────────────


def d_multiplizieren(a: str, b: str, i: int) -> Variante:
    wa, wb = dez(a), dez(b)
    loesung = wa * wb

    stellen = len(nachkomma(a)) + len(nachkomma(b))
    ziffern = int(nachkomma(a) or a) * int(nachkomma(b) or b)

    return Variante(
        skill="DB_multiplizieren",
        ref=f"dezimal-multiplizieren-{i:02d}",
        titel=f"Dezimalzahlen · Multiplizieren · {a} · {b}",
        frage=f"Berechne.\n\n{a} · {b} = ?",
        afb="I",
        loesung=loesung,
        fehlbilder={
            # Ziffern richtig, eine Kommastelle zu wenig.
            "kommastellen_zu_wenig": Fraction(ziffern, 10 ** (stellen - 1)),
            # Eine zu viel.
            "kommastellen_zu_viel": Fraction(ziffern, 10 ** (stellen + 1)),
            # Als ganze Zahlen gerechnet.
            "komma_ignoriert": Fraction(ziffern),
        },
    )


# ── D-C: Dividieren ─────────────────────────────────────────────────────────
#
# Der DIVISOR traegt ein Komma — sonst gibt es gar nichts zu verschieben und
# das Leitfehlbild existiert nicht.


def d_dividieren(a: str, b: str, i: int) -> Variante:
    loesung = dez(a) / dez(b)
    return Variante(
        skill="DC_dividieren",
        ref=f"dezimal-dividieren-{i:02d}",
        titel=f"Dezimalzahlen · Dividieren · {a} : {b}",
        frage=f"Berechne.\n\n{a} : {b} = ?",
        afb="I",
        loesung=loesung,
        fehlbilder={
            # Nur der Dividend behandelt, das Komma des Divisors ignoriert.
            "komma_nicht_verschoben": loesung / 10,
            # In die falsche Richtung verschoben.
            "falsche_richtung": loesung / 100,
        },
    )


# ── D-D: Bruch in Dezimalzahl ───────────────────────────────────────────────


def d_umwandeln(z: int, n: int, i: int) -> Variante:
    loesung = Fraction(z, n)
    ziffern = f"{z}{n}"
    return Variante(
        skill="DD_umwandeln",
        ref=f"dezimal-umwandeln-{i:02d}",
        titel=f"Dezimalzahlen · Bruch umwandeln · {z}/{n}",
        frage=f"Schreibe den Bruch als Dezimalzahl.\n\n{z}/{n} = ?",
        afb="I",
        loesung=loesung,
        fehlbilder={
            # Zaehler und Nenner als Ziffern hinter das Komma geschrieben.
            "ziffern_gelesen": Fraction(int(ziffern), 10 ** len(ziffern)),
            # Nenner durch Zaehler geteilt.
            "umgekehrt_geteilt": Fraction(n, z),
        },
    )


# ── Das Sieb ────────────────────────────────────────────────────────────────


def frisch_rechnen(v: Variante, roh: tuple) -> Fraction:
    """Rechnet die Loesung ein ZWEITES Mal, auf anderem Weg als der Konstruktor."""
    if v.skill == "DA_addieren":
        a, b = roh
        return dez(a) + dez(b)
    if v.skill == "DB_multiplizieren":
        a, b = roh
        return dez(a) * dez(b)
    if v.skill == "DC_dividieren":
        a, b = roh
        return dez(a) / dez(b)
    z, n = roh
    return Fraction(z) / Fraction(n)


def siebe(v: Variante, roh: tuple) -> Variante:
    """Fuenf Pruefungen. Was durchfaellt, wird verworfen — mit Grund."""
    # (1) Frisch nachgerechnet.
    frisch = frisch_rechnen(v, roh)
    if frisch != v.loesung:
        v.verworfen = (
            f"Nachrechnung ergibt {zahl(frisch)}, die Variante behauptet {zahl(v.loesung)}"
        )
        return v

    # (2) Die LOESUNG muss eine abbrechende Dezimalzahl sein. Ein periodisches
    #     Ergebnis waere nicht aufschreibbar, und die Aufgabe wuerde die
    #     Rundung pruefen statt das Rechnen.
    if not endlich(v.loesung):
        v.verworfen = f"Loesung {float(v.loesung):.6f}… ist periodisch, nicht aufschreibbar"
        return v

    # (3) Nur erlaubte Labels.
    unbekannt = set(v.fehlbilder) - LABELS
    if unbekannt:
        v.verworfen = f"unbekanntes Fehlbild-Label: {sorted(unbekannt)}"
        return v

    # (4) Fehlbilder muessen tippbar sein.
    behalten: dict[str, Fraction] = {}
    for label, wert in v.fehlbilder.items():
        if not tippbar(wert):
            v.weggelassen.append(f"{label} ({float(wert):.6f}…) ist kein tippbarer Wert")
            continue
        behalten[label] = wert
    v.fehlbilder = behalten

    # (5) Trennschaerfe — auf WERTEN, nicht auf Zeichenketten.
    #     lsa_values_equal vergleicht wertgleich (live geprueft): "0,30" und
    #     "0,3" sind dieselbe Zahl. Ein Fehlbild, das wertgleich zur Loesung
    #     ist, wuerde deshalb als 'voll' durchgehen — es waere kein Fehlbild,
    #     sondern eine zweite richtige Antwort.
    belegt: dict[Fraction, str] = {v.loesung: "loesung"}
    endgueltig: dict[str, Fraction] = {}
    for label, wert in v.fehlbilder.items():
        if wert in belegt:
            v.weggelassen.append(
                f"{label} ({zahl(wert)}) ist wertgleich mit {belegt[wert]}"
            )
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

# Gemischt: ungleiche Stellenzahl (→ stellenwert_ignoriert) und gleiche
# Stellenzahl MIT Uebertrag (→ uebertrag_vergessen).
ADDIEREN = [
    ("0,5", "0,25"),  # 0,75  | 0,30 stellenwert
    ("0,7", "0,5"),  #  1,2   | 0,12 uebertrag
    ("0,8", "0,45"),  # 1,25  | 0,53 stellenwert
    ("0,6", "0,4"),  #  1     | 0,10 uebertrag
    ("0,25", "0,4"),  # 0,65  | 0,29 stellenwert
    ("0,9", "0,35"),  # 1,25  | 0,44 stellenwert
    ("0,8", "0,7"),  #  1,5   | 0,15 uebertrag
    ("0,3", "0,45"),  # 0,75  | 0,48 stellenwert
]

MULTIPLIZIEREN = [
    ("0,3", "0,4"),  # 0,12 | 1,2  | 0,012 | 12
    ("0,2", "0,7"),  # 0,14 | 1,4  | 0,014 | 14
    ("0,6", "0,4"),  # 0,24 | 2,4  | 0,024 | 24
    ("0,9", "0,3"),  # 0,27 | 2,7  | 0,027 | 27
    ("0,5", "0,6"),  # 0,3  | 3    | 0,03  | 30
    ("0,8", "0,5"),  # 0,4  | 4    | 0,04  | 40
]

DIVIDIEREN = [
    ("4,8", "0,6"),  # 8 | 0,8 | 0,08
    ("3,5", "0,5"),  # 7 | 0,7 | 0,07
    ("7,2", "0,8"),  # 9 | 0,9 | 0,09
    ("2,4", "0,4"),  # 6 | 0,6 | 0,06
    ("5,4", "0,9"),  # 6 | 0,6 | 0,06
    ("1,2", "0,3"),  # 4 | 0,4 | 0,04
]

UMWANDELN = [
    (3, 4),  # 0,75  | 0,34 | 4/3 periodisch
    (1, 4),  # 0,25  | 0,14 | 4
    (1, 2),  # 0,5   | 0,12 | 2
    (1, 5),  # 0,2   | 0,15 | 5
    (3, 8),  # 0,375 | 0,38 | 8/3 periodisch
    (1, 8),  # 0,125 | 0,18 | 8
]


def alle_varianten() -> list[Variante]:
    out: list[Variante] = []
    for i, (a, b) in enumerate(ADDIEREN, 1):
        out.append(siebe(d_addieren(a, b, i), (a, b)))
    for i, (a, b) in enumerate(MULTIPLIZIEREN, 1):
        out.append(siebe(d_multiplizieren(a, b, i), (a, b)))
    for i, (a, b) in enumerate(DIVIDIEREN, 1):
        out.append(siebe(d_dividieren(a, b, i), (a, b)))
    for i, (z, n) in enumerate(UMWANDELN, 1):
        out.append(siebe(d_umwandeln(z, n, i), (z, n)))
    return out


# ── Selbsttest ──────────────────────────────────────────────────────────────


def selbsttest() -> None:
    """Bekannt schlechte Faelle, die beanstandet werden MUESSEN."""
    faelle: list[tuple[str, Variante, tuple]] = []

    luege = d_multiplizieren("0,3", "0,4", 99)
    luege.loesung = Fraction(12, 10)
    faelle.append(("gelogene Loesung", luege, ("0,3", "0,4")))

    # Gleich viele Stellen OHNE Uebertrag: 0,25 + 0,35 → Ziffern 25+35 = 60 →
    # "0,60" = 0,6 — und das IST die richtige Antwort. Der Fehler waere
    # unsichtbar.
    faelle.append(("Fehlbild unsichtbar", d_addieren("0,25", "0,35", 98), ("0,25", "0,35")))

    # 1/3 ist periodisch und als Loesung unzulaessig.
    faelle.append(("periodische Loesung", d_umwandeln(1, 3, 97), (1, 3)))

    unbekannt = d_dividieren("4,8", "0,6", 96)
    unbekannt.fehlbilder = {"phantasie_label": Fraction(1)}
    faelle.append(("unbekanntes Label", unbekannt, ("4,8", "0,6")))

    fehler = 0
    for name, v, roh in faelle:
        erg = siebe(v, roh)
        if erg.verworfen is None and not erg.weggelassen:
            print(f"  FEHLER: '{name}' ist unbeanstandet durchgelaufen")
            fehler += 1
        else:
            print(f"  ok: '{name}' → {erg.verworfen or '; '.join(erg.weggelassen)}")

    if fehler:
        raise SystemExit(f"{fehler} Selbsttest(s) fehlgeschlagen")
    print("Sieb beisst: alle bekannt schlechten Faelle beanstandet.\n")


# ── Ausgabe ─────────────────────────────────────────────────────────────────


def sql_text(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"


def sql_json(obj: object) -> str:
    return sql_text(json.dumps(obj, ensure_ascii=False))


def acceptance(v: Variante) -> dict[str, object]:
    return {
        "canonical": zahl(v.loesung),
        "known_errors": {zahl(w): l for l, w in v.fehlbilder.items()},
    }


def baue_sql(gueltig: list[Variante]) -> str:
    kopf = f"""-- ============================================================================
-- Dezimalzahlen, Charge 01 — {len(gueltig)} Aufgaben als DRAFT
--
-- ERZEUGT von scripts/content/dezimalzahlen.py. Nicht von Hand pflegen.
--
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/seeds/20260722_dezimalzahlen_01.sql
--
-- SETZT A11 (lsa_grade) UND A12 (known_errors) VORAUS.
-- STATUS: alles 'draft'. Die Freigabe ist Lenas Schritt.
--
-- SCHREIBWEISE: lsa_values_equal vergleicht WERTGLEICH — "0,30" und "0,3" sind
-- dieselbe Zahl (live geprueft). Deshalb steht jedes Fehlbild in genau EINER
-- Form, der kuerzesten. Und deshalb prueft das Sieb die Trennschaerfe auf
-- WERTEN: ein Fehlbild, das wertgleich zur Loesung waere, ginge sonst als
-- 'voll' durch — es waere kein Fehlbild, sondern eine zweite richtige Antwort.
--
-- BINAER: kein require_reduced, kein 'teilweise'. Deshalb known_errors ueberall.
--
-- SOLUTION-LEAK: Loesung, Akzeptanz-Set und Fehlbilder ausschliesslich in
-- task_solutions. In `tasks` steht nur die Frage.
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
  title, question, afb, curriculum_grade, needs_image,
  cluster_id, competency_content, competency_process, competency_id, question_payload
)
select
  {sql_text(QUELLE)}, v.source_ref, 'exercise', 'NUMERIC', 'draft', true, false,
  v.titel, v.frage, v.afb, 6, false,
  (select sc.id from skill_clusters sc
     join subjects s on s.id = sc.subject_id
    where s.name = 'Mathematik' and sc.name = 'Zahl & Rechnen' limit 1),
  'arithmetik_algebra', 'Operieren',
  (select pc.id from process_competencies pc where pc.code = 'Ope' limit 1),
  jsonb_build_object('kind', 'short_input', 'prompt', v.frage)
from (values
"""

    zeilen = [
        f"  ({sql_text(v.ref)}, {sql_text(v.titel)}, {sql_text(v.frage)}, {sql_text(v.afb)})"
        for v in gueltig
    ]
    kopf += ",\n".join(zeilen)
    kopf += """
) as v(source_ref, titel, frage, afb)
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

  raise notice 'Dezimalzahlen: alle echten Proben bestanden, Negativkontrolle greift.';
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

    skills = ["DA_addieren", "DB_multiplizieren", "DC_dividieren", "DD_umwandeln"]
    bericht = {
        "quelle": QUELLE,
        "status": "draft",
        "bewertung": "binaer (kein require_reduced, kein teilweise)",
        "schreibweise": "lsa_values_equal vergleicht wertgleich (0,30 = 0,3) — je Fehlbild eine Form",
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
