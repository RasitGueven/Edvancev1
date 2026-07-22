#!/usr/bin/env python3
"""Vorzeichen-Fundamentaufgaben erzeugen — als Seed-Datei, NICHT als DB-Schreibvorgang.

    python3 scripts/content/vorzeichen_fundament.py

Schreibt:
    supabase/seeds/20260722_vorzeichen_fundament_01.sql
    data/vorzeichen_fundament_01_report.json

Schwester von scripts/content/brueche_fundament.py, mit zwei Unterschieden:

  BINAER STATT DREISTUFIG. "-3 - 5 = -8" ist richtig oder falsch; eine
  Zwischenstufe gibt es nicht, weil es nichts zu kuerzen und keine Form zu
  verfehlen gibt. Also kein require_reduced, kein 'teilweise'.

  known_errors VON ANFANG AN. Genau WEIL die Bewertung binaer ist, sind die
  Fehlbilder die einzige Feindiagnostik, die dieser Aufgabentyp hergibt. Bei
  den Bruechen kamen sie nachtraeglich; hier stehen sie im ersten Wurf.

WAS DAS SKRIPT NICHT TUT: Es fasst die Datenbank nicht an — keine Verbindung,
keine Zugangsdaten. Der Insert passiert, wenn Rasit die erzeugte Datei
einspielt, und die Datei setzt NICHTS auf ready.
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass, field
from fractions import Fraction
from pathlib import Path

WURZEL = Path(__file__).resolve().parents[2]
SEED = WURZEL / "supabase" / "seeds" / "20260722_vorzeichen_fundament_01.sql"
BERICHT = WURZEL / "data" / "vorzeichen_fundament_01_report.json"

QUELLE = "edvance_fundament"

# Die vier erlaubten Fehlbild-Labels. Passt ein Fehlbild in keins davon, wird es
# WEGGELASSEN — ein neues zu erfinden waere eine Taxonomie-Entscheidung, und die
# gehoert zu Lena, nicht in einen Generator.
LABELS = {
    "mult_add_verwechslung",
    "betrag_fehler",
    "vorzeichen_ignoriert",
    "vorrang_ignoriert",
}


@dataclass
class Variante:
    skill: str
    ref: str
    titel: str
    frage: str
    afb: str
    loesung: int
    fehlbilder: dict[str, int]  # Label -> Wert
    verworfen: str | None = None
    weggelassen: list[str] = field(default_factory=list)
    proben: list[dict[str, str]] = field(default_factory=list)


def zahl(n: int) -> str:
    """Negative Zweitoperanden in Klammern — "-4 · (-6)" statt "-4 · -6"."""
    return f"({n})" if n < 0 else str(n)


# ── Skill A: Addieren/Subtrahieren ──────────────────────────────────────────
#
# Der Term ist immer x + y mit vorzeichenbehafteten Summanden; geschrieben wird
# er als "x - |y|", wenn y negativ ist. "-3 - 5" ist also x=-3, y=-5.


def addieren(x: int, y: int, i: int) -> Variante:
    term = f"{x} {'+' if y >= 0 else '-'} {abs(y)}"
    loesung = x + y

    # Die Multiplikations-Vorzeichenregel auf eine Addition angewandt.
    fehl = {"mult_add_verwechslung": x * y}

    # Mit den Betraegen gerechnet und das Vorzeichen geraten. Zwei Kandidaten;
    # genommen wird der, der NICHT die Loesung ist (sonst waere das Fehlbild
    # unsichtbar) und nicht mit einem anderen kollidiert.
    for kandidat in (abs(x) - abs(y), abs(y) - abs(x)):
        if kandidat != loesung and kandidat not in fehl.values():
            fehl["betrag_fehler"] = kandidat
            break

    # Alle Vorzeichen weggelassen.
    fehl["vorzeichen_ignoriert"] = abs(x) + abs(y)

    return Variante(
        skill="A_addieren",
        ref=f"vorzeichen-addieren-{i:02d}",
        titel=f"Vorzeichen · Addieren · {term}",
        frage=f"Berechne.\n\n{term} = ?",
        afb="I",
        loesung=loesung,
        fehlbilder=fehl,
    )


# ── Skill B: Multiplizieren/Dividieren ──────────────────────────────────────


def punktrechnung(x: int, y: int, op: str, i: int) -> Variante:
    term = f"{x} {'·' if op == '*' else ':'} {zahl(y)}"
    loesung = x * y if op == "*" else x // y

    fehl = {
        # Betrag richtig, Vorzeichen verloren: dasselbe Ergebnis mit dem
        # anderen Vorzeichen.
        "vorzeichen_ignoriert": -loesung,
        # Statt zu multiplizieren addiert.
        "mult_add_verwechslung": x + y,
    }

    return Variante(
        skill="B_punktrechnung",
        ref=f"vorzeichen-punktrechnung-{i:02d}",
        titel=f"Vorzeichen · {'Multiplizieren' if op == '*' else 'Dividieren'} · {term}",
        frage=f"Berechne.\n\n{term} = ?",
        afb="I",
        loesung=loesung,
        fehlbilder=fehl,
    )


# ── Skill C: Vorrangregel mit Vorzeichen ────────────────────────────────────
#
# Term: a op (b · c). Die Multiplikation steht NIE ganz links — sonst liefern
# "Punkt vor Strich" und "von links nach rechts" oft dasselbe, und das Fehlbild
# waere unsichtbar (siehe Sieb, Pruefung 3).


def vorrang(a: int, op: str, b: int, c: int, i: int) -> Variante:
    term = f"{a} {op} {zahl(b)} · {zahl(c)}"
    produkt = b * c
    loesung = a + produkt if op == "+" else a - produkt

    fehl = {
        # Von links nach rechts gerechnet.
        "vorrang_ignoriert": (a + b) * c if op == "+" else (a - b) * c,
    }

    # Vorrang richtig, aber das Vorzeichen des Produkts verloren. Nur sinnvoll,
    # wenn das Produkt ueberhaupt negativ ist — sonst gibt es nichts zu
    # verlieren, und der Wert waere identisch mit der Loesung.
    if produkt < 0:
        fehl["vorzeichen_ignoriert"] = a + abs(produkt) if op == "+" else a - abs(produkt)

    return Variante(
        skill="C_vorrang",
        ref=f"vorzeichen-vorrang-{i:02d}",
        titel=f"Vorzeichen · Vorrang · {term}",
        frage=f"Berechne.\n\n{term} = ?",
        # AFB II statt I: Hier wird nicht eine Regel reproduziert, sondern zwei
        # Regeln in der richtigen Reihenfolge verknuepft (Punkt vor Strich UND
        # Vorzeichenregel). Das ist "Zusammenhaenge herstellen", nicht
        # "Wiedergeben".
        afb="II",
        loesung=loesung,
        fehlbilder=fehl,
    )


# ── Das Sieb ────────────────────────────────────────────────────────────────


def frisch_rechnen(v: Variante, roh: tuple) -> int:
    """Rechnet die Aufgabe ein ZWEITES Mal, unabhaengig vom Konstruktor.

    Oben entsteht die Loesung aus ganzzahliger Arithmetik. Hier entsteht sie
    ueber `Fraction` — anderer Typ, anderer Weg. Weichen beide ab, ist die
    Variante kaputt, bevor sie jemand sieht.
    """
    if v.skill == "A_addieren":
        x, y = roh
        return int(Fraction(x) + Fraction(y))
    if v.skill == "B_punktrechnung":
        x, y, op = roh
        return int(Fraction(x) * Fraction(y) if op == "*" else Fraction(x) / Fraction(y))
    a, op, b, c = roh
    produkt = Fraction(b) * Fraction(c)
    return int(Fraction(a) + produkt if op == "+" else Fraction(a) - produkt)


def siebe(v: Variante, roh: tuple) -> Variante:
    """Vier Pruefungen. Was durchfaellt, wird verworfen — mit Grund."""
    # (1) Frisch nachgerechnet.
    frisch = frisch_rechnen(v, roh)
    if frisch != v.loesung:
        v.verworfen = f"Nachrechnung ergibt {frisch}, die Variante behauptet {v.loesung}"
        return v

    # (2) Nur erlaubte Labels.
    unbekannt = set(v.fehlbilder) - LABELS
    if unbekannt:
        v.verworfen = f"unbekanntes Fehlbild-Label: {sorted(unbekannt)}"
        return v

    # (3) Skill C: beide Rechenwege muessen sich UNTERSCHEIDEN. Sind sie gleich,
    #     ist der Vorrangfehler an dieser Aufgabe nicht sichtbar — sie misst
    #     dann genau das nicht, wofuer es sie gibt.
    if v.skill == "C_vorrang" and v.fehlbilder.get("vorrang_ignoriert") == v.loesung:
        v.verworfen = "Punkt-vor-Strich und links-nach-rechts liefern dasselbe — Fehlbild unsichtbar"
        return v

    # (4) Trennschaerfe. Ein Fehlbild, das auf die Loesung faellt, wuerde von
    #     lsa_grade als 'voll' gewertet; zwei Fehlbilder auf demselben Wert kann
    #     der Report nicht auseinanderhalten. Betroffene Eintraege werden
    #     WEGGELASSEN (nicht die ganze Variante verworfen) — die uebrigen
    #     bleiben brauchbar.
    belegt: dict[int, str] = {v.loesung: "loesung"}
    behalten: dict[str, int] = {}
    for label, wert in v.fehlbilder.items():
        if wert in belegt:
            v.weggelassen.append(f"{label} ({wert}) faellt mit {belegt[wert]} zusammen")
            continue
        belegt[wert] = label
        behalten[label] = wert
    v.fehlbilder = behalten

    if not v.fehlbilder:
        v.verworfen = "kein einziges trennscharfes Fehlbild uebrig"
        return v

    # (5) Die Proben, die spaeter lsa_grade beantworten muss. Entschieden wird
    #     hier NICHTS — das Skript kennt die Bewertungsfunktion nicht und baut
    #     sie nicht nach. Es schreibt die Erwartung in die Seed-Datei, und die
    #     Datenbank prueft sie beim Einspielen selbst.
    v.proben = [{"antwort": str(v.loesung), "erwartet": "voll", "label": "—"}]
    for label, wert in v.fehlbilder.items():
        v.proben.append({"antwort": str(wert), "erwartet": "nicht", "label": label})

    return v


# ── Die Zahlenwahl ──────────────────────────────────────────────────────────

# (x, y) — der Term ist x + y, geschrieben als "x - |y|" bei negativem y.
# Verschiedene Betraege, beide einstellig.
ADDIEREN = [
    (-3, -5),  # -3 - 5 = -8
    (-7, 4),  #  -7 + 4 = -3
    (2, -9),  #   2 - 9 = -7
    (-6, -2),  # -6 - 2 = -8
    (-4, 9),  #  -4 + 9 =  5
    (3, -8),  #   3 - 8 = -5
    (-9, 5),  #  -9 + 5 = -4
]

# (x, y, op)
PUNKTRECHNUNG = [
    (-3, 5, "*"),  # -15
    (-4, -6, "*"),  #  24
    (-20, 4, ":"),  #  -5
    (7, -3, "*"),  # -21
    (-8, -3, "*"),  #  24
    (-36, -6, ":"),  #   6
    (24, -4, ":"),  #  -6
]

# (a, op, b, c) — Term: a op (b · c). Multiplikation NIE ganz links.
VORRANG = [
    (4, "+", -2, 3),  # -2  | links-nach-rechts 6   | ohne Vorzeichen 10
    (5, "-", 2, -3),  # 11  | -9                    | -1
    (-3, "+", 4, 2),  #  5  | 2                     | (Produkt positiv)
    (6, "+", -3, 4),  # -6  | 12                    | 18
    (-2, "-", 3, -4),  # 10  | 20                   | -14
    (8, "+", -5, 2),  # -2  | 6                     | 18
    (3, "-", 4, -2),  # 11  | 2                     | -5
]


def alle_varianten() -> list[Variante]:
    out: list[Variante] = []
    for i, (x, y) in enumerate(ADDIEREN, 1):
        out.append(siebe(addieren(x, y, i), (x, y)))
    for i, (x, y, op) in enumerate(PUNKTRECHNUNG, 1):
        out.append(siebe(punktrechnung(x, y, op, i), (x, y, op)))
    for i, (a, op, b, c) in enumerate(VORRANG, 1):
        out.append(siebe(vorrang(a, op, b, c, i), (a, op, b, c)))
    return out


# ── Selbsttest: beisst das Sieb? ────────────────────────────────────────────


def selbsttest() -> None:
    """Vier bekannt schlechte Faelle, die durchfallen MUESSEN.

    Ein Sieb, das bei der eigenen, vorher zurechtgelegten Zahlenwahl nie
    anschlaegt, ist kein Beweis — es koennte genauso gut kaputt sein.
    """
    faelle: list[tuple[str, Variante, tuple]] = []

    luege = addieren(-3, -5, 99)
    luege.loesung = -7
    faelle.append(("gelogene Loesung", luege, (-3, -5)))

    # Multiplikation ganz links: 2 · 3 + 4 → beide Wege ergeben 10.
    faelle.append(("Vorrangfehler unsichtbar", vorrang(0, "+", 2, 3, 98), (0, "+", 2, 3)))

    unbekannt = addieren(-3, -5, 97)
    unbekannt.fehlbilder = {"phantasie_label": 1}
    faelle.append(("unbekanntes Label", unbekannt, (-3, -5)))

    # 2 · 2 = 2 + 2: Produkt gleich Summe, die Verwechslung waere unsichtbar,
    # und mit -(-4) = 4 faellt auch das zweite Fehlbild weg.
    leer = punktrechnung(2, 2, "*", 96)
    leer.fehlbilder = {"mult_add_verwechslung": 4}
    faelle.append(("kein trennscharfes Fehlbild", leer, (2, 2, "*")))

    fehler = 0
    for name, v, roh in faelle:
        if siebe(v, roh).verworfen is None:
            print(f"  FEHLER: '{name}' haette verworfen werden muessen")
            fehler += 1
        else:
            print(f"  ok: '{name}' → {v.verworfen}")

    if fehler:
        raise SystemExit(f"{fehler} Selbsttest(s) fehlgeschlagen")
    print("Sieb beisst: alle vier bekannt schlechten Faelle verworfen.\n")


# ── Ausgabe ─────────────────────────────────────────────────────────────────


def sql_text(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"


def sql_json(obj: object) -> str:
    return sql_text(json.dumps(obj, ensure_ascii=False))


def acceptance(v: Variante) -> dict[str, object]:
    """Nur canonical + known_errors.

    KEIN require_reduced: an einer ganzen Zahl gibt es nichts zu kuerzen, und
    ein Flag, das nie greift, ist eine Behauptung ueber die Aufgabe, die nicht
    stimmt.
    """
    return {
        "canonical": str(v.loesung),
        "known_errors": {str(wert): label for label, wert in v.fehlbilder.items()},
    }


def baue_sql(gueltig: list[Variante]) -> str:
    kopf = f"""-- ============================================================================
-- Vorzeichen-Fundament, Charge 01 — {len(gueltig)} Aufgaben als DRAFT
--
-- ERZEUGT von scripts/content/vorzeichen_fundament.py. Nicht von Hand pflegen:
-- neu erzeugen und die Datei ersetzen.
--
-- LAEUFT NICHT AUTOMATISCH:
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/seeds/20260722_vorzeichen_fundament_01.sql
--
-- SETZT A11 (lsa_grade) UND A12 (known_errors) VORAUS.
--
-- STATUS: alles 'draft'. NICHTS steht auf ready — die Freigabe ist Lenas
-- Schritt, und dieser Seed nimmt sie ihr nicht ab.
--
-- BINAER, NICHT DREISTUFIG: "-3 - 5 = -8" ist richtig oder falsch. Es gibt
-- nichts zu kuerzen und keine Form zu verfehlen, also kein require_reduced und
-- kein 'teilweise'. Genau deshalb tragen diese Aufgaben known_errors von
-- Anfang an: bei binaerer Bewertung sind die Fehlbilder die EINZIGE
-- Feindiagnostik, die der Typ hergibt.
--
-- SOLUTION-LEAK: Loesung, Akzeptanz-Set und Fehlbilder stehen ausschliesslich
-- in task_solutions (kein Grant fuer anon/authenticated). In `tasks` steht nur
-- die Frage.
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
  v.titel, v.frage, v.afb, 7, false,
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
        f"  ({sql_text(v.ref)}, {sql_json([str(v.loesung)])}, {sql_json(acceptance(v))})"
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

-- ── 3. Proben: urteilt lsa_grade so, wie die Didaktik es will? ─────────────
--
-- Der Generator kennt die Bewertungsfunktion NICHT und baut sie nicht nach —
-- zwei Wahrheiten ueber "was zaehlt als richtig" waeren genau der Fehler, den
-- die Server-Only-Zone verhindern soll. Statt zu behaupten, fragt die Datei
-- hier die Datenbank:
--
--   die korrekte Zahl -> 'voll'
--   jeder Fehlbildwert -> 'nicht'
--
-- MIT NEGATIVKONTROLLE: die letzte Zeile der Probenliste ist ABSICHTLICH
-- falsch erwartet. Laeuft der Block gruen durch, ohne sie zu melden, prueft er
-- nichts — dann ist der Selbsttest selbst kaputt. Erwartet wird also GENAU EIN
-- gemeldeter Fehler, und der Block sagt das ausdruecklich.

do $$
declare
  r             record;
  v_urteil      text;
  v_echte       int := 0;
  v_kontrolle   int := 0;
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
    # Negativkontrolle: die kanonische Antwort der ersten Variante wird
    # absichtlich als 'nicht' erwartet.
    erste = gueltig[0]
    proben.append(
        f"      ({sql_text(erste.ref)}, {sql_text(str(erste.loesung))}, "
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
        raise notice 'Negativkontrolle hat angeschlagen (so soll es sein): %/% ist %, erwartet war absichtlich %',
          r.source_ref, r.antwort, coalesce(v_urteil, '<null>'), r.erwartet;
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

  -- Ein Selbsttest, der nie anschlaegt, beweist nichts. Schlaegt die
  -- Negativkontrolle NICHT an, prueft die Schleife in Wahrheit gar nichts.
  if v_kontrolle <> 1 then
    raise exception 'Negativkontrolle hat NICHT angeschlagen — die Probenschleife prueft nichts.';
  end if;

  raise notice 'Vorzeichen-Fundament: alle echten Proben bestanden, Negativkontrolle greift.';
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

    bericht = {
        "quelle": QUELLE,
        "status": "draft",
        "bewertung": "binaer (kein require_reduced, kein teilweise)",
        "erzeugt": len(alle),
        "akzeptiert": len(gueltig),
        "verworfen": len(verworfen),
        "je_skill": {
            s: sum(1 for v in gueltig if v.skill == s)
            for s in ("A_addieren", "B_punktrechnung", "C_vorrang")
        },
        "varianten": [
            {
                "skill": v.skill,
                "ref": v.ref,
                "frage": v.frage.replace("\n\n", " "),
                "afb": v.afb,
                "voll": str(v.loesung),
                "known_errors": {str(w): l for l, w in v.fehlbilder.items()},
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
    for s, n in bericht["je_skill"].items():
        print(f"  {s}: {n}")
    for v in gueltig:
        for w in v.weggelassen:
            print(f"  weggelassen bei {v.ref}: {w}")
    for v in verworfen:
        print(f"  VERWORFEN {v.ref}: {v.verworfen}")
    print(f"\n→ {SEED.relative_to(WURZEL)}")
    print(f"→ {BERICHT.relative_to(WURZEL)}")


if __name__ == "__main__":
    main()
