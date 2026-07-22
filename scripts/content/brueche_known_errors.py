#!/usr/bin/env python3
"""
Traegt known_errors in die 28 Bruch-Fundamentaufgaben (Charge 01) nach.

ERZEUGT supabase/seeds/20260722_brueche_known_errors.sql. Nicht die SQL-Datei
von Hand pflegen — hier aendern und neu erzeugen:

    python3 scripts/content/brueche_known_errors.py

REIN DEKLARATIV. Die Bewertung (lsa_grade) bleibt unveraendert. known_errors ist
Rohmaterial fuer die spaetere Report-Feindiagnostik, kein Bewertungsschalter.

Die Fehlbild-Werte werden hier AUS DER DIDAKTIK BERECHNET (aus den Operanden),
nicht abgeschrieben. Die erzeugte SQL-Datei prueft anschliessend jeden Wert
gegen lsa_grade — die Datenbank hat das letzte Wort, nicht dieses Skript.
"""

from __future__ import annotations

from fractions import Fraction
from math import gcd
from pathlib import Path

OUT = Path(__file__).resolve().parents[2] / "supabase/seeds/20260722_brueche_known_errors.sql"

# Die feste Taxonomie. Nicht erweitern — ein Fehlbild, das in keins dieser
# Labels passt, wird weggelassen und im Bericht genannt.
LABELS = {
    "nenner_addiert",
    "zaehler_nicht_erweitert",
    "nenner_addiert_zaehler_ok",
    "nicht_gestuerzt",
    "falschen_gestuerzt",
    "hauptnenner_bei_mult",
    "additiv_gekuerzt",
    "teilgekuerzt",
}


def lcm(a: int, b: int) -> int:
    return a * b // gcd(a, b)


def frac(n: int, d: int) -> str:
    """Genau die Schreibweise, die ein Kind eintippen wuerde."""
    return f"{n}/{d}"


def is_reduced(n: int, d: int) -> bool:
    return gcd(abs(n), abs(d)) == 1


# ── Die 28 Aufgaben ────────────────────────────────────────────────────────
# (source_ref, skill, operanden)
#   kuerzen:  ((n, d),)
#   sonst:    ((a, b), (c, d))
AUFGABEN = [
    ("brueche-kuerzen-01", "kuerzen", ((18, 24),)),
    ("brueche-kuerzen-02", "kuerzen", ((12, 16),)),
    ("brueche-kuerzen-03", "kuerzen", ((8, 12),)),
    ("brueche-kuerzen-04", "kuerzen", ((16, 24),)),
    ("brueche-kuerzen-05", "kuerzen", ((12, 18),)),
    ("brueche-kuerzen-06", "kuerzen", ((20, 24),)),
    ("brueche-kuerzen-07", "kuerzen", ((4, 12),)),
    ("brueche-addieren-01", "addieren", ((1, 4), (2, 3))),
    ("brueche-addieren-02", "addieren", ((1, 6), (1, 3))),
    ("brueche-addieren-03", "addieren", ((1, 4), (1, 12))),
    ("brueche-addieren-04", "addieren", ((1, 2), (1, 6))),
    ("brueche-addieren-05", "addieren", ((3, 4), (1, 8))),
    ("brueche-addieren-06", "addieren", ((5, 12), (1, 4))),
    ("brueche-addieren-07", "addieren", ((2, 9), (1, 6))),
    ("brueche-multiplizieren-01", "multiplizieren", ((2, 3), (4, 5))),
    ("brueche-multiplizieren-02", "multiplizieren", ((2, 3), (3, 4))),
    ("brueche-multiplizieren-03", "multiplizieren", ((3, 4), (2, 5))),
    ("brueche-multiplizieren-04", "multiplizieren", ((1, 2), (3, 5))),
    ("brueche-multiplizieren-05", "multiplizieren", ((4, 5), (5, 6))),
    ("brueche-multiplizieren-06", "multiplizieren", ((3, 8), (2, 3))),
    ("brueche-multiplizieren-07", "multiplizieren", ((5, 6), (2, 3))),
    ("brueche-dividieren-01", "dividieren", ((2, 3), (4, 5))),
    ("brueche-dividieren-02", "dividieren", ((1, 2), (3, 4))),
    ("brueche-dividieren-03", "dividieren", ((3, 4), (2, 3))),
    ("brueche-dividieren-04", "dividieren", ((2, 5), (3, 4))),
    ("brueche-dividieren-05", "dividieren", ((3, 8), (3, 4))),
    ("brueche-dividieren-06", "dividieren", ((5, 6), (2, 3))),
    ("brueche-dividieren-07", "dividieren", ((4, 9), (2, 3))),
]


def kanonisch(skill: str, ops) -> Fraction:
    if skill == "kuerzen":
        (n, d), = ops
        return Fraction(n, d)
    (a, b), (c, d) = ops
    if skill == "addieren":
        return Fraction(a, b) + Fraction(c, d)
    if skill == "multiplizieren":
        return Fraction(a, b) * Fraction(c, d)
    return Fraction(a, b) / Fraction(c, d)


def fehlbilder(skill: str, ops) -> list[tuple[str, str, str]]:
    """(wert, label, herleitung) — die Herleitung landet als Kommentar in der SQL."""
    out: list[tuple[str, str, str]] = []

    if skill == "kuerzen":
        (n, d), = ops
        # Oben und unten dieselbe Zahl abgezogen — das klassische Fehlbild,
        # das Kuerzen mit Subtrahieren verwechselt.
        out.append((frac(n - 1, d - 1), "additiv_gekuerzt", f"{n}-1 / {d}-1"))
        # Wertgleich, aber nur einen Schritt weit gekuerzt: durch den kleinsten
        # Primfaktor des ggT statt durch den ggT.
        g = gcd(n, d)
        p = next(k for k in range(2, g + 1) if g % k == 0)
        out.append((frac(n // p, d // p), "teilgekuerzt", f"nur durch {p} gekuerzt"))
        return out

    (a, b), (c, d) = ops

    if skill == "addieren":
        L = lcm(b, d)
        za, zc = a * (L // b), c * (L // d)
        # Leitfehlbild: Zaehler+Zaehler, Nenner+Nenner.
        out.append((frac(a + c, b + d), "nenner_addiert", f"({a}+{c})/({b}+{d})"))
        # Hauptnenner erkannt, aber die urspruenglichen Zaehler addiert.
        out.append((frac(a + c, L), "zaehler_nicht_erweitert", f"({a}+{c})/{L}"))
        # Zaehler richtig erweitert und addiert, aber die Nenner addiert.
        out.append((frac(za + zc, b + d), "nenner_addiert_zaehler_ok", f"({za}+{zc})/({b}+{d})"))
        # Ungekuerzte Summe — nur wenn sie ueberhaupt kuerzbar war.
        if not is_reduced(za + zc, L):
            out.append((frac(za + zc, L), "teilgekuerzt", f"({za}+{zc})/{L}"))
        return out

    if skill == "multiplizieren":
        L = lcm(b, d)
        za, zc = a * (L // b), c * (L // d)
        # Faelschlich gleichnamig gemacht und dann nach Additionsregel verrechnet.
        out.append((frac(za + zc, L), "hauptnenner_bei_mult", f"gleichnamig ({za}+{zc})/{L}"))
        if not is_reduced(a * c, b * d):
            out.append((frac(a * c, b * d), "teilgekuerzt", f"{a}·{c}/{b}·{d}"))
        return out

    # dividieren
    # Ohne Kehrwert einfach multipliziert.
    out.append((frac(a * c, b * d), "nicht_gestuerzt", f"{a}·{c}/{b}·{d}"))
    # Den ersten statt den zweiten Bruch gestuerzt.
    out.append((frac(b * c, a * d), "falschen_gestuerzt", f"{b}/{a} · {c}/{d}"))
    if not is_reduced(a * d, b * c):
        out.append((frac(a * d, b * c), "teilgekuerzt", f"{a}·{d}/{b}·{c}"))
    return out


def main() -> None:
    zeilen: list[str] = []
    proben: list[str] = []
    weggelassen: list[str] = []

    for ref, skill, ops in AUFGABEN:
        kan = kanonisch(skill, ops)
        kan_str = frac(kan.numerator, kan.denominator)

        gewaehlt: dict[str, str] = {}
        for wert, label, warum in fehlbilder(skill, ops):
            assert label in LABELS, f"unbekanntes Label {label}"
            if wert == kan_str:
                weggelassen.append(f"{ref}: {wert} ({label}) — identisch mit canonical")
                continue
            if wert in gewaehlt:
                weggelassen.append(
                    f"{ref}: {wert} ({label}) — Kollision mit {gewaehlt[wert]}"
                )
                continue
            gewaehlt[wert] = label
            erwartet = "teilweise" if label == "teilgekuerzt" else "nicht"
            proben.append(f"      ('{ref}', '{wert}', '{erwartet}', '{label}'),")

        eintraege = ", ".join(f'"{w}": "{l}"' for w, l in gewaehlt.items())
        zeilen.append(f"  ('{ref}', '{{{eintraege}}}'),")

    zeilen[-1] = zeilen[-1].rstrip(",")
    proben[-1] = proben[-1].rstrip(",")

    OUT.write_text(KOPF + "\n".join(zeilen) + MITTE + "\n".join(proben) + FUSS, encoding="utf-8")

    print(f"geschrieben: {OUT}")
    print(f"Aufgaben: {len(AUFGABEN)}   known_errors-Eintraege: {len(proben)}")
    if weggelassen:
        print("weggelassen:")
        for w in weggelassen:
            print(f"  - {w}")
    else:
        print("weggelassen: keine")


KOPF = """-- ============================================================================
-- Bruch-Fundament, Charge 01 — known_errors nachgetragen
--
-- ERZEUGT von scripts/content/brueche_known_errors.py. Nicht von Hand pflegen:
-- neu erzeugen und die Datei ersetzen.
--
-- LAEUFT NICHT AUTOMATISCH. Von Hand einspielen:
--     psql "$DATABASE_URL" -f supabase/seeds/20260722_brueche_known_errors.sql
--
-- SETZT A12 VORAUS (known_errors als erlaubter acceptance-Key). Ohne A12
-- weist der CHECK task_solutions_acceptance_check das UPDATE ab und die
-- Transaktion bricht ab — genau so soll es sein.
--
-- REIN DEKLARATIV: die Bewertung bleibt, wie sie ist. lsa_grade wird nicht
-- angefasst, kein Schema geaendert, kein Status bewegt (alles bleibt 'draft' —
-- die Freigabe ist Lenas Schritt). known_errors ist Rohmaterial fuer die
-- Report-Feindiagnostik: es beantwortet nicht "richtig oder falsch", sondern
-- "welcher Denkfehler steckt hinter dieser falschen Antwort".
--
-- SOLUTION-LEAK: known_errors landet ausschliesslich in task_solutions (kein
-- Grant fuer anon/authenticated). In `tasks` steht davon nichts.
--
-- ERGAENZT, ERSETZT NICHT: das UPDATE verwendet `acceptance || ...`, canonical
-- und require_reduced bleiben unangetastet.
--
-- IDEMPOTENT: zweimal einspielen schreibt zweimal dasselbe.
-- ============================================================================

begin;

-- ── 1. Die Fehlbilder je Aufgabe ───────────────────────────────────────────
--
-- Wert -> Fehlertyp. Die Werte stehen genau so, wie ein Kind sie eintippen
-- wuerde. Berechnet aus der Didaktik (siehe Generator-Skript), nicht geraten.

update task_solutions ts
   set acceptance = ts.acceptance || jsonb_build_object('known_errors', v.known_errors::jsonb),
       updated_at = now()
  from (values
"""

MITTE = """
) as v(source_ref, known_errors)
 where ts.task_id = (
         select t.id from tasks t
          where t.source = 'edvance_fundament' and t.source_ref = v.source_ref
       )
   and ts.acceptance ? 'canonical';

-- ── 2. Selbsttest: urteilt lsa_grade ueber jedes Fehlbild wie erwartet? ────
--
-- Das Generator-Skript kennt die Bewertungsfunktion nicht und baut sie nicht
-- nach. Es fragt hier die Datenbank:
--
--   jedes Fehlbild ausser teilgekuerzt  -> 'nicht'
--   der teilgekuerzt-Wert               -> 'teilweise'
--
-- Zusaetzlich wird geprueft, dass canonical und require_reduced das UPDATE
-- ueberlebt haben und dass jeder gepruefte Wert auch wirklich in der
-- geschriebenen known_errors-Abbildung steht.
--
-- Weicht auch nur eine Probe ab, bricht die Transaktion ab und NICHTS wird
-- geschrieben. Lieber keine Feindiagnostik als eine falsche.

do $$
declare
  r        record;
  v_urteil text;
  v_label  text;
  v_fehler int := 0;
  v_anzahl int;
begin
  -- 2a. Die Akzeptanz-Grundlage darf das UPDATE nicht verloren haben.
  select count(*) into v_anzahl
    from task_solutions s
    join tasks t on t.id = s.task_id
   where t.source = 'edvance_fundament'
     and (s.acceptance -> 'canonical' is null
          or s.acceptance -> 'require_reduced' is null);
  if v_anzahl > 0 then
    raise exception '% Aufgabe(n) haben canonical/require_reduced verloren.', v_anzahl;
  end if;

  -- 2b. Jedes einzelne Fehlbild gegen lsa_grade.
  for r in
    select * from (values
"""

FUSS = """
    ) as p(source_ref, antwort, erwartet, label)
  loop
    select public.lsa_grade(
             'NUMERIC',
             s.acceptance,
             s.correct_answers,
             jsonb_build_object('value', r.antwort)
           ),
           s.acceptance #>> array['known_errors', r.antwort]
      into v_urteil, v_label
      from task_solutions s
      join tasks t on t.id = s.task_id
     where t.source = 'edvance_fundament' and t.source_ref = r.source_ref;

    if v_urteil is distinct from r.erwartet then
      v_fehler := v_fehler + 1;
      raise warning 'Probe %/% : lsa_grade sagt %, erwartet % (Fehlbild %)',
        r.source_ref, r.antwort, coalesce(v_urteil, '<null>'), r.erwartet, r.label;
    end if;

    if v_label is distinct from r.label then
      v_fehler := v_fehler + 1;
      raise warning 'Probe %/% : known_errors sagt %, erwartet %',
        r.source_ref, r.antwort, coalesce(v_label, '<fehlt>'), r.label;
    end if;
  end loop;

  if v_fehler > 0 then
    raise exception '% Probe(n) fehlgeschlagen — nichts geschrieben.', v_fehler;
  end if;

  -- 2c. Alle 28 haben jetzt known_errors, und der Status ist unberuehrt.
  select count(*) into v_anzahl
    from task_solutions s
    join tasks t on t.id = s.task_id
   where t.source = 'edvance_fundament' and s.acceptance ? 'known_errors';
  if v_anzahl <> 28 then
    raise exception 'nur % von 28 Aufgaben haben known_errors.', v_anzahl;
  end if;

  select count(*) into v_anzahl
    from tasks where source = 'edvance_fundament' and status <> 'draft';
  if v_anzahl > 0 then
    raise exception '% Aufgabe(n) stehen nicht mehr auf draft.', v_anzahl;
  end if;

  raise notice 'known_errors: alle Proben bestanden, 28 Aufgaben aktualisiert.';
end $$;

commit;
"""


if __name__ == "__main__":
    main()
