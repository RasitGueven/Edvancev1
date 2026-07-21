#!/usr/bin/env python3
"""Bruch-Fundamentaufgaben erzeugen — als Seed-Datei, NICHT als DB-Schreibvorgang.

    python3 scripts/content/brueche_fundament.py

Schreibt:
    supabase/seeds/20260721_brueche_fundament_01.sql   (Insert als draft + Selbsttest)
    data/brueche_fundament_01_report.json              (Bericht fuer Lena)

WARUM EIN GENERATOR UND KEINE HANDGESCHRIEBENE SQL-DATEI:
Die Didaktik dieser vier Skills haengt an der Zahlenwahl. Ob eine Variante
brauchbar ist, entscheidet nicht der Geschmack, sondern eine Rechnung: Erzeugt
jedes Fehlbild einen EIGENEN Wert? Faellt der teilweise-Wert wirklich mit der
Loesung zusammen? Von Hand ist das bei 25 Varianten nicht zu halten — hier
rechnet es das Sieb (siehe `siebe`), und was durchfaellt, steht mit Grund im
Bericht.

WAS DAS SKRIPT NICHT TUT: Es fasst die Datenbank nicht an. Es oeffnet keine
Verbindung, es kennt keine Zugangsdaten. Der Insert passiert, wenn Rasit die
erzeugte Datei einspielt — und die Datei setzt NICHTS auf ready. Die Freigabe
ist Lenas Schritt.
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass, field
from fractions import Fraction
from math import gcd
from pathlib import Path

WURZEL = Path(__file__).resolve().parents[2]
SEED = WURZEL / "supabase" / "seeds" / "20260721_brueche_fundament_01.sql"
BERICHT = WURZEL / "data" / "brueche_fundament_01_report.json"

# Quellen-Tag im Sinne von Migration 007: "kanonischer Quellen-Tag". Er ist
# zugleich Lenas Griff im Autoren-Tool — der Quellen-Filter (PR #76) zeigt alles,
# was nicht 'VERA8_IQB' ist, als Eigenbau.
QUELLE = "edvance_fundament"


# ── Bruch-Handwerk ──────────────────────────────────────────────────────────


@dataclass(frozen=True)
class Bruch:
    """Ein Bruch, wie er GESCHRIEBEN wird — bewusst ungekuerzt gehalten.

    `Fraction` kuerzt beim Anlegen automatisch und wuerde damit genau die
    Information wegwerfen, um die es hier geht: ob die Schreibweise gekuerzt ist.
    """

    z: int
    n: int

    def __post_init__(self) -> None:
        if self.n <= 0:
            raise ValueError(f"Nenner muss positiv sein: {self}")

    @property
    def wert(self) -> Fraction:
        return Fraction(self.z, self.n)

    @property
    def gekuerzt(self) -> "Bruch":
        g = gcd(abs(self.z), self.n)
        return Bruch(self.z // g, self.n // g)

    @property
    def ist_gekuerzt(self) -> bool:
        return gcd(abs(self.z), self.n) == 1

    def __str__(self) -> str:
        return f"{self.z}/{self.n}"


def kgv(a: int, b: int) -> int:
    return a * b // gcd(a, b)


# ── Die vier Skills ─────────────────────────────────────────────────────────
#
# Die Didaktik ist VORGEGEBEN. Hier variieren nur die Zahlen; jede Funktion
# liefert dieselben vier Groessen:
#   loesung    — vollstaendig gekuerzt, das ist 'voll'
#   rohform    — der Wert VOR dem Kuerzen, das ist 'teilweise' (oder None,
#                wenn schon die Rohform gekuerzt ist — dann gibt es die Stufe
#                bei dieser Variante nicht)
#   fehlbilder — benannte Fehlvorstellungen mit ihrem Ergebniswert, das ist
#                'nicht'


@dataclass
class Variante:
    skill: str
    ref: str
    titel: str
    frage: str
    loesung: Bruch
    rohform: Bruch | None
    fehlbilder: dict[str, Bruch]
    verworfen: str | None = None
    proben: list[dict[str, str]] = field(default_factory=list)


FORMHINWEIS = "Gib das Ergebnis als vollständig gekürzten Bruch an."


def kuerzen(a: int, b: int, i: int) -> Variante:
    roh = Bruch(a, b)
    loesung = roh.gekuerzt

    # Teilgekuerzt: durch einen ECHTEN Teiler des ggT teilen. Das ist die
    # diagnostisch wertvolle Zwischenstufe — Konzept da, Ausfuehrung
    # unvollstaendig. Gibt es keinen echten Teiler (ggT ist prim), hat diese
    # Variante keine Zwischenstufe.
    g = gcd(a, b)
    teiler = next((d for d in range(2, g) if g % d == 0), None)
    teilweise = Bruch(a // teiler, b // teiler) if teiler else None

    return Variante(
        skill="A_kuerzen",
        ref=f"brueche-kuerzen-{i:02d}",
        titel=f"Brüche · Kürzen · {roh}",
        frage=f"Kürze den Bruch vollständig.\n\n{roh} = ?",
        loesung=loesung,
        rohform=teilweise,
        # Das additive Fehlbild: "oben und unten dasselbe abziehen".
        fehlbilder={"additiv": Bruch(a - 1, b - 1)},
    )


def addieren(a: int, b: int, c: int, d: int, i: int) -> Variante:
    n = kgv(b, d)
    roh = Bruch(a * (n // b) + c * (n // d), n)

    return Variante(
        skill="B_addieren",
        ref=f"brueche-addieren-{i:02d}",
        titel=f"Brüche · Addieren · {a}/{b} + {c}/{d}",
        frage=f"Berechne. {FORMHINWEIS}\n\n{a}/{b} + {c}/{d} = ?",
        loesung=roh.gekuerzt,
        rohform=None if roh.ist_gekuerzt else roh,
        # Das Leitfehlbild: Zähler+Zähler über Nenner+Nenner.
        fehlbilder={"zaehler_plus_nenner": Bruch(a + c, b + d)},
    )


def multiplizieren(a: int, b: int, c: int, d: int, i: int) -> Variante:
    roh = Bruch(a * c, b * d)
    summe_n = kgv(b, d)

    return Variante(
        skill="C_multiplizieren",
        ref=f"brueche-multiplizieren-{i:02d}",
        titel=f"Brüche · Multiplizieren · {a}/{b} · {c}/{d}",
        frage=f"Berechne. {FORMHINWEIS}\n\n{a}/{b} · {c}/{d} = ?",
        loesung=roh.gekuerzt,
        rohform=None if roh.ist_gekuerzt else roh,
        fehlbilder={
            # "über Kreuz" — verwechselt Mal mit Geteilt.
            "ueber_kreuz": Bruch(a * d, b * c),
            # "Hauptnenner gesucht" — wendet die Additionsregel an.
            "additionsregel": Bruch(a * (summe_n // b) + c * (summe_n // d), summe_n),
        },
    )


def dividieren(a: int, b: int, c: int, d: int, i: int) -> Variante:
    roh = Bruch(a * d, b * c)

    return Variante(
        skill="D_dividieren",
        ref=f"brueche-dividieren-{i:02d}",
        titel=f"Brüche · Dividieren · {a}/{b} : {c}/{d}",
        frage=f"Berechne. {FORMHINWEIS}\n\n{a}/{b} : {c}/{d} = ?",
        loesung=roh.gekuerzt,
        rohform=None if roh.ist_gekuerzt else roh,
        fehlbilder={
            # Gar nicht gestürzt: einfach multipliziert.
            "nicht_gestuerzt": Bruch(a * c, b * d),
            # Den FALSCHEN gestürzt: den ersten statt den zweiten.
            "falsch_gestuerzt": Bruch(b * c, a * d),
        },
    )


# ── Das Sieb ────────────────────────────────────────────────────────────────


def frische_probe(v: Variante, a: int, b: int, c: int | None, d: int | None) -> Fraction:
    """Rechnet die Aufgabe ein ZWEITES Mal, auf anderem Weg.

    Oben entsteht die Loesung aus der Bruch-Klasse (ganzzahlige Zaehler/Nenner,
    dann gekuerzt). Hier entsteht sie aus `Fraction`, also aus Pythons eigener
    Bruchrechnung. Stimmen beide nicht ueberein, ist die Variante kaputt — und
    zwar bevor irgendjemand sie sieht.
    """
    if v.skill == "A_kuerzen":
        return Fraction(a, b)
    assert c is not None and d is not None
    if v.skill == "B_addieren":
        return Fraction(a, b) + Fraction(c, d)
    if v.skill == "C_multiplizieren":
        return Fraction(a, b) * Fraction(c, d)
    return Fraction(a, b) / Fraction(c, d)


def siebe(v: Variante, operanden: tuple[int, int, int | None, int | None]) -> Variante:
    """Drei Pruefungen. Was durchfaellt, wird verworfen — mit Grund."""
    a, b, c, d = operanden

    # (1) Frisch nachgerechnet: stimmt die Loesung?
    frisch = frische_probe(v, a, b, c, d)
    if frisch != v.loesung.wert:
        v.verworfen = f"Nachrechnung ergibt {frisch}, die Variante behauptet {v.loesung.wert}"
        return v

    if not v.loesung.ist_gekuerzt:
        v.verworfen = f"Loesung {v.loesung} ist nicht vollstaendig gekuerzt"
        return v

    # Skill A misst das Kuerzen. Ein Bruch, der schon gekuerzt IST, misst
    # nichts — die richtige Antwort waere, die Aufgabe abzuschreiben.
    if v.skill == "A_kuerzen" and gcd(a, b) == 1:
        v.verworfen = f"{a}/{b} ist bereits gekuerzt — es gibt nichts zu kuerzen"
        return v

    # (2) Trennschaerfe: Loesung und JEDES Fehlbild muessen verschiedene WERTE
    #     haben. Gleiche Werte kann der Report spaeter nicht auseinanderhalten —
    #     und lsa_grade wuerde ein Fehlbild als 'voll' durchwinken.
    belegt: dict[Fraction, str] = {v.loesung.wert: "loesung"}
    for name, f in v.fehlbilder.items():
        if f.n <= 0:
            v.verworfen = f"Fehlbild {name} hat Nenner {f.n}"
            return v
        if f.wert in belegt:
            v.verworfen = f"Fehlbild {name} ({f}) faellt mit {belegt[f.wert]} auf denselben Wert"
            return v
        belegt[f.wert] = name

    # Die Zwischenstufe ist WERTGLEICH zur Loesung (das ist ihr Sinn), muss sich
    # aber in der SCHREIBWEISE unterscheiden — sonst ist sie keine.
    if v.rohform is not None:
        if v.rohform.wert != v.loesung.wert:
            v.verworfen = f"Rohform {v.rohform} ist nicht wertgleich zur Loesung {v.loesung}"
            return v
        if v.rohform.ist_gekuerzt:
            v.verworfen = f"Rohform {v.rohform} ist bereits gekuerzt — keine Zwischenstufe"
            return v

    # (3) Die Proben, die spaeter lsa_grade beantworten muss. Sie werden NICHT
    #     hier entschieden: Das Skript kennt die Bewertungsfunktion nicht und
    #     soll sie auch nicht nachbauen (zwei Wahrheiten). Es schreibt die
    #     Erwartung in die Seed-Datei, und die Datenbank prueft sie beim
    #     Einspielen selbst.
    v.proben = [{"antwort": str(v.loesung), "erwartet": "voll"}]
    if v.rohform is not None:
        v.proben.append({"antwort": str(v.rohform), "erwartet": "teilweise"})
    for name, f in v.fehlbilder.items():
        v.proben.append({"antwort": str(f), "erwartet": "nicht", "fehlbild": name})

    return v


# ── Die Zahlenwahl ──────────────────────────────────────────────────────────
#
# Alle Nenner (auch die Hauptnenner) bleiben <= 24 und kopfrechenbar.

KUERZEN = [(18, 24), (12, 16), (8, 12), (16, 24), (12, 18), (20, 24), (4, 12)]

ADDIEREN = [
    (1, 4, 2, 3),  # 11/12 — schon gekuerzt, keine Zwischenstufe
    (1, 6, 1, 3),  # 3/6 → 1/2
    (1, 4, 1, 12),  # 4/12 → 1/3
    (1, 2, 1, 6),  # 4/6 → 2/3
    (3, 4, 1, 8),  # 7/8 — schon gekuerzt
    (5, 12, 1, 4),  # 8/12 → 2/3
    (2, 9, 1, 6),  # 7/18 — schon gekuerzt
]

MULTIPLIZIEREN = [
    (2, 3, 4, 5),  # 8/15 — schon gekuerzt: prueft NUR Multiplizieren
    (2, 3, 3, 4),  # 6/12 → 1/2: prueft Multiplizieren UND Kuerzen
    (3, 4, 2, 5),  # 6/20 → 3/10
    (1, 2, 3, 5),  # 3/10 — schon gekuerzt
    (4, 5, 5, 6),  # 20/30 → 2/3
    (3, 8, 2, 3),  # 6/24 → 1/4
    (5, 6, 2, 3),  # 10/18 → 5/9
]

DIVIDIEREN = [
    (2, 3, 4, 5),  # 10/12 → 5/6
    (1, 2, 3, 4),  # 4/6 → 2/3
    (3, 4, 2, 3),  # 9/8 — schon gekuerzt
    (2, 5, 3, 4),  # 8/15 — schon gekuerzt
    (3, 8, 3, 4),  # 12/24 → 1/2
    (5, 6, 2, 3),  # 15/12 → 5/4
    (4, 9, 2, 3),  # 12/18 → 2/3
]


def alle_varianten() -> list[Variante]:
    out: list[Variante] = []
    for i, (a, b) in enumerate(KUERZEN, 1):
        out.append(siebe(kuerzen(a, b, i), (a, b, None, None)))
    for i, (a, b, c, d) in enumerate(ADDIEREN, 1):
        out.append(siebe(addieren(a, b, c, d, i), (a, b, c, d)))
    for i, (a, b, c, d) in enumerate(MULTIPLIZIEREN, 1):
        out.append(siebe(multiplizieren(a, b, c, d, i), (a, b, c, d)))
    for i, (a, b, c, d) in enumerate(DIVIDIEREN, 1):
        out.append(siebe(dividieren(a, b, c, d, i), (a, b, c, d)))
    return out


# ── Ausgabe ─────────────────────────────────────────────────────────────────


def sql_text(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"


def sql_json(obj: object) -> str:
    return sql_text(json.dumps(obj, ensure_ascii=False))


def acceptance(v: Variante) -> dict[str, object]:
    """Das Akzeptanz-Set (A10) mit der Kuerzungspflicht aus A11.

    `require_reduced` steht OBEN, nicht in `notation` — der A10-CHECK
    whitelistet die notation-Schluessel, und die Kuerzungspflicht ist eine
    Verschaerfung, keine Nachsicht.
    """
    return {"canonical": str(v.loesung), "require_reduced": True}


def baue_sql(gueltig: list[Variante]) -> str:
    kopf = f"""-- ============================================================================
-- Bruch-Fundament, Charge 01 — {len(gueltig)} Aufgaben als DRAFT
--
-- ERZEUGT von scripts/content/brueche_fundament.py. Nicht von Hand pflegen:
-- neu erzeugen und die Datei ersetzen.
--
-- LAEUFT NICHT AUTOMATISCH. supabase/seed.sql ist der Stammdaten-Seed (Faecher,
-- Cluster, Tarife) und wird bei `supabase db reset` gezogen. Diese Datei hier
-- ist Inhalt, kein Stammdatum, und wird bewusst von Hand eingespielt:
--     psql "$DATABASE_URL" -f supabase/seeds/20260721_brueche_fundament_01.sql
--
-- SETZT A10 + A11 VORAUS (task_solutions.acceptance, require_reduced, lsa_grade).
--
-- STATUS: alles 'draft'. NICHTS steht auf ready. Die Freigabe ist Lenas
-- Schritt — dieser Seed nimmt sie ihr nicht ab und darf es auch nicht.
--
-- SOLUTION-LEAK: Loesung und Akzeptanz-Set stehen ausschliesslich in
-- task_solutions (kein Grant fuer anon/authenticated). In `tasks` steht nur,
-- was das Kind ohnehin sieht — die Frage. Die Formanforderung
-- ("vollstaendig gekuerzt") gehoert in den FRAGETEXT, weil der Schueler-Payload
-- kein Feld fuer eine Instruktion hat.
--
-- IDEMPOTENT ueber (source, source_ref): zweimal einspielen legt nichts doppelt
-- an. Der Selbsttest am Ende laeuft trotzdem jedes Mal.
-- ============================================================================

begin;

-- ── 0. Voraussetzungen ─────────────────────────────────────────────────────
--
-- Ohne Cluster laege der Content zwar in der Tabelle, waere aber nicht
-- freigebbar (das Gate verlangt cluster_id fuer 'ready') — und niemand wuesste
-- warum. Lieber hier abbrechen als Lena spaeter raten lassen.

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
end $$;

-- ── 1. Die Aufgaben ────────────────────────────────────────────────────────

insert into tasks (
  source, source_ref, content_type, input_type, status, is_active, is_diagnostic,
  title, question, afb, curriculum_grade, needs_image,
  cluster_id, competency_content, competency_process, competency_id, question_payload
)
select
  {sql_text(QUELLE)}, v.source_ref, 'exercise', 'NUMERIC', 'draft', true, false,
  v.titel, v.frage, 'I', 6, false,
  (select sc.id from skill_clusters sc
     join subjects s on s.id = sc.subject_id
    where s.name = 'Mathematik' and sc.name = 'Zahl & Rechnen' limit 1),
  'arithmetik_algebra', 'Operieren',
  (select pc.id from process_competencies pc where pc.code = 'Ope' limit 1),
  jsonb_build_object('kind', 'short_input', 'prompt', v.frage)
from (values
"""

    zeilen = [
        f"  ({sql_text(v.ref)}, {sql_text(v.titel)}, {sql_text(v.frage)})"
        for v in gueltig
    ]
    kopf += ",\n".join(zeilen)
    kopf += """
) as v(source_ref, titel, frage)
on conflict (source, source_ref) do nothing;

-- ── 2. Loesung + Akzeptanz-Set (Server-Only-Zone) ──────────────────────────

insert into task_solutions (task_id, correct_answers, acceptance, updated_at)
select t.id, v.correct_answers::jsonb, v.acceptance::jsonb, now()
from (values
"""

    zeilen = []
    for v in gueltig:
        zeilen.append(
            f"  ({sql_text(v.ref)}, {sql_json([str(v.loesung)])}, {sql_json(acceptance(v))})"
        )
    kopf += ",\n".join(zeilen)
    kopf += f"""
) as v(source_ref, correct_answers, acceptance)
join tasks t on t.source = {sql_text(QUELLE)} and t.source_ref = v.source_ref
on conflict (task_id) do update
   set correct_answers = excluded.correct_answers,
       acceptance      = excluded.acceptance,
       updated_at      = now();

-- ── 3. Selbsttest: urteilt lsa_grade so, wie die Didaktik es will? ─────────
--
-- Das Skript, das diese Datei erzeugt hat, kennt die Bewertungsfunktion NICHT
-- und baut sie auch nicht nach — zwei Wahrheiten ueber "was zaehlt als richtig"
-- waeren genau der Fehler, den die Server-Only-Zone verhindern soll. Statt zu
-- behaupten, fragt die Datei hier die Datenbank:
--
--   die gekuerzte Loesung        -> 'voll'
--   dieselbe Zahl, ungekuerzt    -> 'teilweise'   (die diagnostische Zwischenstufe)
--   jedes Fehlbild               -> 'nicht'
--
-- Weicht auch nur eine Probe ab, bricht die Transaktion ab und NICHTS wird
-- eingespielt. Lieber kein Content als Content, der falsch bewertet wird.

do $$
declare
  r        record;
  v_urteil text;
  v_fehler int := 0;
begin
  for r in
    select * from (values
"""

    proben = []
    for v in gueltig:
        for p in v.proben:
            proben.append(
                f"      ({sql_text(v.ref)}, {sql_text(p['antwort'])}, "
                f"{sql_text(p['erwartet'])}, {sql_text(p.get('fehlbild', '—'))})"
            )
    kopf += ",\n".join(proben)
    kopf += f"""
    ) as p(source_ref, antwort, erwartet, fehlbild)
  loop
    select public.lsa_grade(
             'NUMERIC',
             s.acceptance,
             s.correct_answers,
             jsonb_build_object('value', r.antwort)
           )
      into v_urteil
      from task_solutions s
      join tasks t on t.id = s.task_id
     where t.source = {sql_text(QUELLE)} and t.source_ref = r.source_ref;

    if v_urteil is distinct from r.erwartet then
      v_fehler := v_fehler + 1;
      raise warning 'Probe %/% : lsa_grade sagt %, erwartet % (Fehlbild %)',
        r.source_ref, r.antwort, coalesce(v_urteil, '<null>'), r.erwartet, r.fehlbild;
    end if;
  end loop;

  if v_fehler > 0 then
    raise exception '% Probe(n) fehlgeschlagen — nichts eingespielt.', v_fehler;
  end if;

  raise notice 'Bruch-Fundament: alle Proben bestanden.';
end $$;

commit;
"""
    return kopf


def selbsttest() -> None:
    """Beisst das Sieb ueberhaupt?

    Ein Sieb, das bei der eigenen, vorher zurechtgelegten Zahlenwahl nie
    anschlaegt, ist kein Beweis — es koennte genauso gut kaputt sein. Deshalb
    hier vier Faelle, von denen bekannt ist, dass sie durchfallen MUESSEN.
    Laeuft mit `python3 scripts/content/brueche_fundament.py --selbsttest`.
    """
    faelle: list[tuple[str, Variante, tuple[int, int, int | None, int | None]]] = []

    # (1) Falsch behauptete Loesung — die frische Nachrechnung muss es merken.
    luege = kuerzen(18, 24, 99)
    luege.loesung = Bruch(2, 3)
    faelle.append(("gelogene Loesung", luege, (18, 24, None, None)))

    # (2) Nichts zu kuerzen.
    faelle.append(("schon gekuerzt", kuerzen(3, 4, 98), (3, 4, None, None)))

    # (3) Division, bei der beide Fehlbilder auf denselben Wert fallen (a = b).
    faelle.append(("Fehlbild-Kollision", dividieren(2, 2, 3, 4, 97), (2, 2, 3, 4)))

    # (4) Multiplikation, bei der "ueber Kreuz" zufaellig die Loesung trifft (c = d).
    faelle.append(("Fehlbild = Loesung", multiplizieren(2, 3, 3, 3, 96), (2, 3, 3, 3)))

    fehler = 0
    for name, v, operanden in faelle:
        ergebnis = siebe(v, operanden)
        if ergebnis.verworfen is None:
            print(f"  FEHLER: '{name}' haette verworfen werden muessen")
            fehler += 1
        else:
            print(f"  ok: '{name}' → {ergebnis.verworfen}")

    if fehler:
        raise SystemExit(f"{fehler} Selbsttest(s) fehlgeschlagen")
    print("Sieb beisst: alle vier bekannt schlechten Faelle verworfen.\n")


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
        "erzeugt": len(alle),
        "akzeptiert": len(gueltig),
        "verworfen": len(verworfen),
        "je_skill": {
            s: sum(1 for v in gueltig if v.skill == s)
            for s in ("A_kuerzen", "B_addieren", "C_multiplizieren", "D_dividieren")
        },
        "varianten": [
            {
                "skill": v.skill,
                "ref": v.ref,
                "frage": v.frage.replace("\n\n", " "),
                "voll": str(v.loesung),
                "teilweise": str(v.rohform) if v.rohform else None,
                "nicht": {k: str(f) for k, f in v.fehlbilder.items()},
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
    for v in verworfen:
        print(f"  VERWORFEN {v.ref}: {v.verworfen}")
    print(f"\n→ {SEED.relative_to(WURZEL)}")
    print(f"→ {BERICHT.relative_to(WURZEL)}")


if __name__ == "__main__":
    main()
