#!/usr/bin/env python3
"""
Termumformung, Charge 01 — Fundament-Aufgaben als DRAFT.

ERZEUGT supabase/seeds/20260722_term_fundament_01.sql. Nicht die SQL-Datei von
Hand pflegen — hier aendern und neu erzeugen:

    python3 scripts/content/term_fundament.py

VIER SKILLS, ZWEI ANTWORTFORMATE:
  T-A Zusammenfassen   afb I   Term-Eingabe (SHORT_TEXT)
  T-B Ausmultiplizieren afb I  Term-Eingabe (SHORT_TEXT)
  T-C Ausklammern      afb II  MULTIPLE CHOICE
  T-D Minusklammer     afb I   Term-Eingabe (SHORT_TEXT)

DAS SIEB (der eigentliche Zweck dieses Skripts):
Jede Variante wird ZWEIMAL bestimmt. Einmal didaktisch konstruiert (aus den
Operanden), einmal frisch geloest — indem der gerenderte Aufgabentext von einem
eigenen Parser gelesen und ausgewertet wird (`loese_frisch`). Beide Wege wissen
nichts voneinander. Weichen sie ab, fliegt die Variante raus.

Danach werden die Fehlbilder auf Kollision geprueft und die Zahlenwahl-Regeln je
Skill durchgesetzt. Was durchfaellt, steht im Bericht — nicht in der Seed-Datei.

Die Bewertung selbst prueft dieses Skript NICHT nach: das macht der DO-Block der
erzeugten SQL-Datei, indem er lsa_grade fragt. Zwei Wahrheiten darueber, was
richtig ist, waeren genau der Fehler, den die Server-Only-Zone verhindern soll.
"""

from __future__ import annotations

import re
from math import gcd
from pathlib import Path

OUT = Path(__file__).resolve().parents[2] / "supabase/seeds/20260722_term_fundament_01.sql"

# Die feste Taxonomie. Nicht erweitern.
LABELS = {
    "alles_addiert",
    "vorzeichen_verloren",
    "konstante_vergessen",
    "faktor_nur_erstes_glied",
    "addiert_statt_multipliziert",
    "vorzeichen_bei_negativem_faktor",
    "nicht_vollstaendig",
    "nur_erstes_geteilt",
    "falsch_geteilt",
    "klammer_nicht_aufgeloest",
    "beide_vorzeichen_behalten",
}


# ── Die Abgabeform ─────────────────────────────────────────────────────────
#
# Vereinbart mit der Term-Eingabe der App: `ax+b`, OHNE Leerzeichen, Minus
# direkt an der Zahl. a=1 -> "x+b", a=-1 -> "-x+b", b=0 -> "ax".
#
# lsa_normalize_answer macht daraus lower(trim(collapse_whitespace(...))) und
# ersetzt Komma durch Punkt — Leerraum wird KOLLABIERT, aber NICHT ENTFERNT.
# "5x + 4" und "5x+4" sind fuer den Server also zwei verschiedene Antworten.
# Deshalb steht beides in correct_answers (siehe `akzeptierte_formen`).


def term(a: int, b: int) -> str:
    """Die kanonische Form ohne Leerzeichen."""
    if a == 0:
        return str(b)
    kopf = "x" if a == 1 else "-x" if a == -1 else f"{a}x"
    if b == 0:
        return kopf
    return f"{kopf}+{b}" if b > 0 else f"{kopf}{b}"


def term_mit_luft(a: int, b: int) -> str:
    """Dieselbe Antwort, wie sie jemand mit Leerzeichen schriebe."""
    if a == 0 or b == 0:
        return term(a, b)
    kopf = "x" if a == 1 else "-x" if a == -1 else f"{a}x"
    return f"{kopf} + {b}" if b > 0 else f"{kopf} - {abs(b)}"


def akzeptierte_formen(a: int, b: int) -> list[str]:
    """
    Was als richtig zaehlt. Die vereinbarte Form zuerst — sie ist die, die im
    Aufgabentext gefordert wird und die die App baut. Die Variante mit
    Leerzeichen steht daneben, weil die Abgabeform der App zum Zeitpunkt dieses
    Laufs nicht gegengelesen werden konnte: Waere sie "5x + 4", wuerde ohne
    diesen zweiten Eintrag JEDE richtige Antwort als falsch bewertet.
    """
    formen = [term(a, b)]
    mit_luft = term_mit_luft(a, b)
    if mit_luft != formen[0]:
        formen.append(mit_luft)
    return formen


# ── Frisches Loesen: ein eigener Parser fuer lineare Terme ─────────────────
#
# Liest den gerenderten Aufgabentext und rechnet ihn aus, ohne die Konstruktion
# zu kennen. Grammatik (mehr kommt in diesen Aufgaben nicht vor):
#   expr   := ['-'] term (('+'|'-') term)*
#   term   := faktor+                      (implizite Multiplikation: 3(x+2))
#   faktor := zahl | 'x' | '(' expr ')'
# Werte sind lineare Polynome (a, b) fuer a*x + b.


def _tokens(s: str) -> list[str]:
    return re.findall(r"\d+|[x()+\-·*]", s.replace("−", "-"))


class _Leser:
    def __init__(self, s: str) -> None:
        self.t = _tokens(s)
        self.i = 0

    def schau(self) -> str | None:
        return self.t[self.i] if self.i < len(self.t) else None

    def nimm(self) -> str:
        z = self.t[self.i]
        self.i += 1
        return z

    def expr(self) -> tuple[int, int]:
        vorzeichen = 1
        if self.schau() == "-":
            self.nimm()
            vorzeichen = -1
        a, b = self.term()
        a, b = vorzeichen * a, vorzeichen * b
        while self.schau() in ("+", "-"):
            op = 1 if self.nimm() == "+" else -1
            a2, b2 = self.term()
            a, b = a + op * a2, b + op * b2
        return a, b

    def term(self) -> tuple[int, int]:
        a, b = self.faktor()
        while self.schau() is not None and self.schau() not in ("+", "-", ")"):
            if self.schau() in ("·", "*"):
                self.nimm()
                continue
            a2, b2 = self.faktor()
            # Nur lineare Terme: mindestens ein Faktor muss konstant sein.
            if a != 0 and a2 != 0:
                raise ValueError("nicht linear")
            if a == 0:
                a, b = b * a2, b * b2
            else:
                a, b = a * b2, b * b2
        return a, b

    def faktor(self) -> tuple[int, int]:
        z = self.nimm()
        if z == "(":
            a, b = self.expr()
            if self.nimm() != ")":
                raise ValueError("Klammer nicht geschlossen")
            return a, b
        if z == "x":
            return 1, 0
        if z == "-":
            a, b = self.faktor()
            return -a, -b
        return 0, int(z)


def loese_frisch(ausdruck: str) -> tuple[int, int]:
    leser = _Leser(ausdruck)
    a, b = leser.expr()
    if leser.i != len(leser.t):
        raise ValueError(f"Rest nicht gelesen: {ausdruck}")
    return a, b


# ── Die vier Skills ────────────────────────────────────────────────────────


class Verworfen(Exception):
    """Eine Variante, die das Sieb nicht passiert. Der Text ist der Grund."""


def pruefe_fehlbilder(kanonisch: str, fehlbilder: list[tuple[str, str]]) -> None:
    """Kein Fehlbild gleich der Loesung, keine zwei gleich."""
    gesehen: dict[str, str] = {}
    for wert, label in fehlbilder:
        if label not in LABELS:
            raise Verworfen(f"unbekanntes Label {label}")
        if wert == kanonisch:
            raise Verworfen(f"Fehlbild {label}={wert} ist die Loesung selbst")
        if wert in gesehen:
            raise Verworfen(f"Fehlbild {label}={wert} kollidiert mit {gesehen[wert]}")
        gesehen[wert] = label


def t_a(a1: int, c1: int, a2: int, c2: int, minus_auf_x: bool):
    """
    Zusammenfassen. `minus_auf_x` entscheidet, wo das Minus steht:
      False: a1x + c1 + a2x - c2
      True:  a1x + c1 - a2x + c2
    """
    if minus_auf_x:
        ausdruck = f"{a1}x + {c1} - {a2}x + {c2}"
        a, b = a1 - a2, c1 + c2
        # Das Minus ignoriert: das x-Glied wird addiert statt subtrahiert.
        vorzeichen_verloren = (a1 + a2, c1 + c2)
    else:
        ausdruck = f"{a1}x + {c1} + {a2}x - {c2}"
        a, b = a1 + a2, c1 - c2
        # Das Minus ignoriert: die Konstante wird addiert statt subtrahiert.
        vorzeichen_verloren = (a1 + a2, c1 + c2)

    if a in (0, 1, -1):
        raise Verworfen(f"Koeffizient {a} — 1/-1/0 hat eine Sonderform, die die App erst kennen muss")
    if b == 0:
        raise Verworfen("Konstante 0 — die Loesung haette die Form 'ax' statt 'ax+b'")
    if vorzeichen_verloren == (a, b):
        raise Verworfen("ohne wirksames Minus gaebe es vorzeichen_verloren nicht")

    # Alles in einen Topf: x-Glieder und Zahlen vermengt.
    summe = a + b
    if summe == 0:
        raise Verworfen("alles_addiert waere '0x'")

    fehlbilder = [
        (term(summe, 0), "alles_addiert"),
        (term(*vorzeichen_verloren), "vorzeichen_verloren"),
        (term(a, 0), "konstante_vergessen"),
    ]
    pruefe_fehlbilder(term(a, b), fehlbilder)
    return ausdruck, (a, b), fehlbilder


def t_b(f: int, c: int):
    """Ausmultiplizieren: f(x + c)."""
    innen = f"x + {c}" if c > 0 else f"x - {abs(c)}"
    ausdruck = f"{f}({innen})"
    a, b = f, f * c

    if abs(f) < 2:
        raise Verworfen(f"Faktor {f} — faktor_nur_erstes_glied waere nicht unterscheidbar")
    if b == 0:
        raise Verworfen("Produkt 0")

    fehlbilder = [
        (term(f, c), "faktor_nur_erstes_glied"),
        (term(f, f + c), "addiert_statt_multipliziert"),
    ]
    if f < 0:
        # Bei negativem Faktor das Vorzeichen im zweiten Glied verloren.
        fehlbilder.append((term(f, -b), "vorzeichen_bei_negativem_faktor"))

    pruefe_fehlbilder(term(a, b), fehlbilder)
    return ausdruck, (a, b), fehlbilder


def t_c(a: int, b: int):
    """
    Ausklammern, als Multiple Choice.

    Gibt (ausdruck, optionen) zurueck. `optionen` ist eine Liste
    (label, rolle) — Rolle 'richtig' oder ein Fehlbild-Label.
    """
    g = gcd(a, b)
    if g < 2:
        raise Verworfen(f"ggT({a},{b})={g} — es gibt nichts auszuklammern")

    # Der groesste ECHTE Teiler des ggT. Ohne ihn gibt es kein
    # 'nicht_vollstaendig', das ein Kind ernsthaft in Versuchung fuehrt.
    zwischen = max((d for d in range(2, g) if g % d == 0), default=None)
    if zwischen is None:
        raise Verworfen(f"ggT={g} ist prim — 'nicht_vollstaendig' waere unsinnig")

    ausdruck = f"{a}x + {b}"

    def klammer(faktor: int, ax: int, konst: int) -> str:
        kopf = "x" if ax == 1 else f"{ax}x"
        return f"{faktor}({kopf} + {konst})"

    optionen = [
        (klammer(g, a // g, b // g), "richtig"),
        (klammer(zwischen, a // zwischen, b // zwischen), "nicht_vollstaendig"),
        (klammer(g, a // g, b), "nur_erstes_geteilt"),
        (klammer(g, a // g, b // zwischen), "falsch_geteilt"),
    ]

    label_menge = {lab for lab, _ in optionen}
    if len(label_menge) != len(optionen):
        raise Verworfen("zwei Optionen tragen denselben Text")
    for lab, rolle in optionen:
        if rolle != "richtig" and rolle not in LABELS:
            raise Verworfen(f"unbekanntes Label {rolle}")

    # Genau EINE Option darf vollstaendig ausgeklammert UND wertgleich sein.
    richtig = [
        lab
        for lab, _ in optionen
        if loese_frisch(lab) == (a, b) and lab.startswith(f"{g}(")
    ]
    if len(richtig) != 1:
        raise Verworfen(f"{len(richtig)} Optionen sind vollstaendig ausgeklammert")

    return ausdruck, optionen


def t_d(k: int, a: int, c: int):
    """Minusklammer: k - (ax - c), c > 0."""
    if c <= 0:
        raise Verworfen("die Klammer enthaelt kein Minus — es gibt nichts zu drehen")
    if abs(a) < 2:
        raise Verworfen(f"Koeffizient {a} hat eine Sonderform")

    ausdruck = f"{k} - ({a}x - {c})"
    loesung = (-a, k + c)

    if k - c == 0:
        raise Verworfen("k = c — zwei Fehlbilder faenden dieselbe Konstante")
    if k + c == 0:
        raise Verworfen("k + c = 0 — die Loesung haette die Form 'ax'")

    fehlbilder = [
        # Nur das erste Vorzeichen gedreht, das zweite stehen gelassen.
        (term(-a, k - c), "klammer_nicht_aufgeloest"),
        # Die Klammer einfach weggelassen: beide Vorzeichen behalten.
        (term(a, k - c), "beide_vorzeichen_behalten"),
    ]
    pruefe_fehlbilder(term(*loesung), fehlbilder)
    return ausdruck, loesung, fehlbilder


# ── Die Varianten ──────────────────────────────────────────────────────────

VARIANTEN_A = [
    (3, 5, 2, 1, False),
    (4, 9, 3, 2, False),
    (2, 7, 6, 10, False),
    (5, 3, 4, 8, False),
    (7, 4, 2, 6, True),
    (9, 2, 4, 5, True),
    (6, 8, 2, 3, True),
    # Selbsttest (muss durchfallen): kein Minus im Term.
    (3, 5, 2, 0, False),
]

VARIANTEN_B = [
    (3, 2),
    (4, 5),
    (5, -3),
    (-3, 2),
    (-2, 7),
    (-4, -3),
    (6, 4),
]

VARIANTEN_C = [
    (4, 8),
    (6, 12),
    (4, 20),
    (9, 27),
    (8, 12),
    (12, 18),
    # Selbsttest (muss durchfallen): ggT 3 ist prim, kein Zwischenteiler.
    (6, 9),
]

VARIANTEN_D = [
    (5, 2, 3),
    (9, 3, 4),
    (7, 4, 2),
    (2, 5, 6),
    (10, 6, 1),
    (4, 7, 9),
    # Selbsttest (muss durchfallen): Klammer ohne Minus.
    (5, 2, -3),
]


SKILLS = [
    ("term-zusammenfassen", "Terme · Zusammenfassen", "I", "SHORT_TEXT",
     "Fasse zusammen. Gib das Ergebnis in der Form ax + b an."),
    ("term-ausmultiplizieren", "Terme · Ausmultiplizieren", "I", "SHORT_TEXT",
     "Multipliziere aus. Gib das Ergebnis in der Form ax + b an."),
    ("term-ausklammern", "Terme · Ausklammern", "II", "MC",
     "Klammere so weit wie möglich aus. Welcher Term ist richtig?"),
    ("term-minusklammer", "Terme · Minusklammer", "I", "SHORT_TEXT",
     "Löse die Klammer auf und fasse zusammen. Gib das Ergebnis in der Form ax + b an."),
]


def sql(s: str) -> str:
    return s.replace("'", "''")


def selbsttest() -> list[str]:
    """
    Faengt das Sieb, was es fangen soll? Ein Sieb, das nie etwas abweist, ist
    kein Sieb — diese Faelle MUESSEN durchfallen.
    """
    faelle = [
        ("Fehlbild gleich der Loesung",
         lambda: pruefe_fehlbilder("5x+4", [("5x+4", "alles_addiert")])),
        ("zwei Fehlbilder mit demselben Wert",
         lambda: pruefe_fehlbilder("5x+4", [("9x", "alles_addiert"), ("9x", "konstante_vergessen")])),
        ("unbekanntes Label",
         lambda: pruefe_fehlbilder("5x+4", [("9x", "voellig_neu")])),
        ("T-A ohne Minus im Term", lambda: t_a(3, 5, 2, 0, False)),
        ("T-C ohne echten Zwischenteiler (ggT prim)", lambda: t_c(6, 9)),
        ("T-C ohne gemeinsamen Teiler", lambda: t_c(5, 7)),
        ("T-D ohne Minus in der Klammer", lambda: t_d(5, 2, -3)),
        ("T-B mit Faktor 1", lambda: t_b(1, 4)),
    ]
    durchgerutscht = []
    for name, fn in faelle:
        try:
            fn()
        except Verworfen:
            continue
        durchgerutscht.append(name)
    return durchgerutscht


def main() -> None:
    durchgerutscht = selbsttest()
    if durchgerutscht:
        raise SystemExit(
            "Sieb-Selbsttest fehlgeschlagen — diese Faelle haetten abgewiesen werden muessen:\n  "
            + "\n  ".join(durchgerutscht)
        )
    print("Sieb-Selbsttest: alle bekannt schlechten Faelle abgewiesen.")

    aufgaben: list[dict] = []
    verworfen: list[str] = []

    def nimm_term(praefix: str, nr: int, bauer, args, instruktion: str, titel: str, afb: str):
        try:
            ausdruck, loesung, fehlbilder = bauer(*args)
        except Verworfen as e:
            verworfen.append(f"{praefix} {args}: {e}")
            return
        # Frisch loesen: den gerenderten Text lesen, nicht die Konstruktion.
        frisch = loese_frisch(ausdruck)
        if frisch != loesung:
            verworfen.append(
                f"{praefix} {args}: frisch geloest {term(*frisch)}, konstruiert {term(*loesung)}"
            )
            return
        # Jedes Fehlbild muss ein anderer Term sein als die Loesung — auch
        # inhaltlich, nicht nur als String.
        for wert, label in fehlbilder:
            if loese_frisch(wert) == loesung:
                verworfen.append(f"{praefix} {args}: {label}={wert} ist wertgleich mit der Loesung")
                return
        aufgaben.append({
            "source_ref": f"{praefix}-{nr:02d}",
            "titel": f"{titel} · {ausdruck}",
            "frage": f"{instruktion}\n\n{ausdruck} = ?",
            "afb": afb,
            "input_type": "SHORT_TEXT",
            "antworten": akzeptierte_formen(*loesung),
            "kanonisch": term(*loesung),
            "fehlbilder": fehlbilder,
            "optionen": None,
        })

    nr = 0
    for args in VARIANTEN_A:
        nr += 1
        nimm_term("term-zusammenfassen", nr, t_a, args, SKILLS[0][4], SKILLS[0][1], "I")

    nr = 0
    for args in VARIANTEN_B:
        nr += 1
        nimm_term("term-ausmultiplizieren", nr, t_b, args, SKILLS[1][4], SKILLS[1][1], "I")

    nr = 0
    for a, b in VARIANTEN_C:
        nr += 1
        try:
            ausdruck, optionen = t_c(a, b)
        except Verworfen as e:
            verworfen.append(f"term-ausklammern ({a},{b}): {e}")
            continue
        # Die richtige Option darf nicht immer an derselben Stelle stehen.
        gedreht = optionen[nr % len(optionen):] + optionen[: nr % len(optionen)]
        ids = "abcd"
        mit_id = [(ids[i], lab, rolle) for i, (lab, rolle) in enumerate(gedreht)]
        richtige = [i for i, _, rolle in mit_id if rolle == "richtig"]
        if len(richtige) != 1:
            verworfen.append(f"term-ausklammern ({a},{b}): nicht genau eine richtige Option")
            continue
        aufgaben.append({
            "source_ref": f"term-ausklammern-{nr:02d}",
            "titel": f"{SKILLS[2][1]} · {ausdruck}",
            "frage": f"{SKILLS[2][4]}\n\n{ausdruck} = ?",
            "afb": "II",
            "input_type": "MC",
            "antworten": [richtige[0]],
            "kanonisch": next(lab for _, lab, r in mit_id if r == "richtig"),
            "fehlbilder": [(lab, rolle) for _, lab, rolle in mit_id if rolle != "richtig"],
            "optionen": [(i, lab) for i, lab, _ in mit_id],
        })

    nr = 0
    for args in VARIANTEN_D:
        nr += 1
        nimm_term("term-minusklammer", nr, t_d, args, SKILLS[3][4], SKILLS[3][1], "I")

    # ── SQL bauen ──────────────────────────────────────────────────────────
    task_zeilen, loesungs_zeilen, proben, kommentare = [], [], [], []

    for auf in aufgaben:
        payload = (
            "jsonb_build_object('input_type', 'MC', 'options', '"
            + sql(
                "["
                + ", ".join(
                    '{"id": "%s", "label": "%s"}' % (i, lab.replace('"', '\\"'))
                    for i, lab in auf["optionen"]
                )
                + "]"
            )
            + "'::jsonb)"
            if auf["optionen"]
            else "jsonb_build_object('kind', 'short_input', 'prompt', %s)" % f"'{sql(auf['frage'])}'"
        )
        task_zeilen.append(
            f"  ('{auf['source_ref']}', '{sql(auf['titel'])}', '{sql(auf['frage'])}', "
            f"'{auf['input_type']}', '{auf['afb']}', {payload})"
        )
        antworten = "[" + ", ".join(f'"{sql(a)}"' for a in auf["antworten"]) + "]"
        loesungs_zeilen.append(f"  ('{auf['source_ref']}', '{sql(antworten)}')")

        if auf["input_type"] == "MC":
            proben.append(f"      ('{auf['source_ref']}', '{auf['antworten'][0]}', 'voll', 'richtig')")
            for i, lab in auf["optionen"]:
                if i != auf["antworten"][0]:
                    rolle = next(r for l, r in auf["fehlbilder"] if l == lab)
                    proben.append(f"      ('{auf['source_ref']}', '{i}', 'nicht', '{rolle}')")
            kommentare.append(
                f"--   {auf['source_ref']}: {auf['frage'].splitlines()[-1]}  richtig = "
                f"{auf['antworten'][0]}) {auf['kanonisch']}"
            )
            for lab, rolle in auf["fehlbilder"]:
                kommentare.append(f"--       {lab:<22} {rolle}")
        else:
            for form in auf["antworten"]:
                proben.append(f"      ('{auf['source_ref']}', '{sql(form)}', 'voll', 'kanonisch')")
            for wert, label in auf["fehlbilder"]:
                proben.append(f"      ('{auf['source_ref']}', '{sql(wert)}', 'nicht', '{label}')")
            kommentare.append(
                f"--   {auf['source_ref']}: {auf['frage'].splitlines()[-1]}  ->  {auf['kanonisch']}"
            )
            for wert, label in auf["fehlbilder"]:
                kommentare.append(f"--       {wert:<22} {label}")

    OUT.write_text(
        KOPF
        + "\n".join(kommentare)
        + TASKS_KOPF
        + ",\n".join(task_zeilen)
        + TASKS_FUSS
        + ",\n".join(loesungs_zeilen)
        + PROBEN_KOPF
        + ",\n".join(proben)
        + FUSS.replace("@ANZAHL@", str(len(aufgaben))),
        encoding="utf-8",
    )

    print(f"geschrieben: {OUT}")
    je_skill: dict[str, int] = {}
    for auf in aufgaben:
        je_skill[auf["source_ref"].rsplit("-", 1)[0]] = je_skill.get(auf["source_ref"].rsplit("-", 1)[0], 0) + 1
    for k, v in sorted(je_skill.items()):
        print(f"  {k}: {v}")
    print(f"  gesamt: {len(aufgaben)}   Proben: {len(proben)}")
    print("verworfen:")
    for v in verworfen:
        print(f"  - {v}")


KOPF = """-- ============================================================================
-- Termumformung, Charge 01 — Fundament-Aufgaben als DRAFT
--
-- ERZEUGT von scripts/content/term_fundament.py. Nicht von Hand pflegen:
-- neu erzeugen und die Datei ersetzen.
--
-- LAEUFT NICHT AUTOMATISCH. Von Hand einspielen:
--     psql "$DATABASE_URL" -f supabase/seeds/20260722_term_fundament_01.sql
--
-- STATUS: alles 'draft'. Die Freigabe ist Lenas Schritt.
--
-- ZWEI ANTWORTFORMATE:
--   Zusammenfassen / Ausmultiplizieren / Minusklammer  -> SHORT_TEXT, Form ax+b
--   Ausklammern                                        -> MC, afb II
--
-- KEIN acceptance-SATZ BEI DEN TERM-AUFGABEN — und das ist Absicht:
--
--   lsa_grade nimmt den Zahlen-Pfad, sobald acceptance ein 'canonical' hat.
--   Dort trennt lsa_split_value_unit "5x+4" in Wert "5" und Einheit "x+4" und
--   vergleicht nur den Wert. Live geprueft: mit canonical "5x+4" bewertet
--   lsa_grade die Antworten "5x+9", "5x+6", "5x-4" und "5x" ALLE als 'voll'.
--   Genau die Fehlbilder dieser Aufgaben faenden also volle Punkte.
--
--   Ohne acceptance faellt lsa_grade auf lsa_is_correct zurueck: normalisierter
--   String-Vergleich gegen correct_answers. Das ist fuer Terme das richtige
--   Verfahren — und das einzige, das hier korrekt urteilt.
--
--   FOLGE: known_errors ist fuer diese Aufgaben NICHT speicherbar. Es lebt in
--   acceptance, und lsa_acceptance_valid laesst es nur in einem Satz MIT
--   canonical zu (ohne canonical wird acceptance als Teilaufgaben-Abbildung
--   gelesen und der Schluessel 'known_errors' abgewiesen). Die Fehlbilder
--   stehen deshalb hier als Kommentar und in AUTONOMY_NOTES.md, nicht als
--   Daten. Sie zu erfinden waere ein zweiter Ort fuer Fehlerdiagnostik.
--
-- EXAKTER STRING-VERGLEICH: "4+5x" zaehlt NICHT als richtig, obwohl es
-- wertgleich ist. Deshalb steht die Zielform im Aufgabentext. In
-- correct_answers steht zusaetzlich die Schreibweise mit Leerzeichen, weil die
-- Abgabeform der App noch nicht gegengelesen ist.
--
-- SOLUTION-LEAK: Bei MC sind die OPTIONEN schuelerlesbar (question_payload,
-- ueber lsa_question_payload) — die richtige Option-Id steht in
-- task_solutions.correct_answers. Auf task_solutions hat weder anon noch
-- authenticated ein Grant (geprueft), nur service_role.
--
-- IDEMPOTENT ueber (source, source_ref).
--
-- ── DIE VARIANTEN UND IHRE FEHLBILDER ──────────────────────────────────────
"""

TASKS_KOPF = """

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
end $$;

-- ── 1. Die Aufgaben ────────────────────────────────────────────────────────

insert into tasks (
  source, source_ref, content_type, input_type, status, is_active, is_diagnostic,
  title, question, afb, curriculum_grade, needs_image,
  cluster_id, competency_content, competency_process, competency_id, question_payload
)
select
  'edvance_fundament', v.source_ref, 'exercise', v.input_type, 'draft', true, false,
  v.titel, v.frage, v.afb, 7, false,
  (select sc.id from skill_clusters sc
     join subjects s on s.id = sc.subject_id
    where s.name = 'Mathematik' and sc.name = 'Zahl & Rechnen' limit 1),
  'arithmetik_algebra', 'Operieren',
  (select pc.id from process_competencies pc where pc.code = 'Ope' limit 1),
  v.payload
from (values
"""

TASKS_FUSS = """
) as v(source_ref, titel, frage, input_type, afb, payload)
on conflict (source, source_ref) do nothing;

-- ── 2. Loesung (Server-Only-Zone) ──────────────────────────────────────────
--
-- Bei MC ist der Eintrag die Option-Id, bei den Term-Aufgaben der Antwortstring
-- in beiden Schreibweisen. acceptance bleibt NULL — Begruendung im Kopf.

insert into task_solutions (task_id, correct_answers, acceptance, updated_at)
select t.id, v.correct_answers::jsonb, null, now()
from (values
"""

PROBEN_KOPF = """
) as v(source_ref, correct_answers)
join tasks t on t.source = 'edvance_fundament' and t.source_ref = v.source_ref
on conflict (task_id) do update
   set correct_answers = excluded.correct_answers,
       acceptance      = excluded.acceptance,
       updated_at      = now();

-- ── 3. Selbsttest: urteilt lsa_grade so, wie die Didaktik es will? ─────────
--
-- Das Generator-Skript kennt die Bewertungsfunktion nicht und baut sie nicht
-- nach. Es fragt hier die Datenbank:
--
--   jede akzeptierte Schreibweise der Loesung -> 'voll'
--   jedes Fehlbild                            -> 'nicht'
--   bei MC: die richtige Option-Id            -> 'voll', jede andere -> 'nicht'
--
-- Weicht auch nur eine Probe ab, bricht die Transaktion ab und NICHTS wird
-- eingespielt.

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
    ) as p(source_ref, antwort, erwartet, rolle)
  loop
    select public.lsa_grade(
             t.input_type,
             s.acceptance,
             s.correct_answers,
             case when t.input_type = 'MC'
                  then jsonb_build_object('selected', jsonb_build_array(r.antwort))
                  else jsonb_build_object('text', r.antwort) end
           )
      into v_urteil
      from task_solutions s
      join tasks t on t.id = s.task_id
     where t.source = 'edvance_fundament' and t.source_ref = r.source_ref;

    if v_urteil is distinct from r.erwartet then
      v_fehler := v_fehler + 1;
      raise warning 'Probe %/% : lsa_grade sagt %, erwartet % (%)',
        r.source_ref, r.antwort, coalesce(v_urteil, '<null>'), r.erwartet, r.rolle;
    end if;
  end loop;

  if v_fehler > 0 then
    raise exception '% Probe(n) fehlgeschlagen — nichts eingespielt.', v_fehler;
  end if;

  -- Die Aufgaben sind da, stehen auf draft, und keine Term-Aufgabe hat sich
  -- doch noch ein acceptance eingefangen (das wuerde die Bewertung kippen).
  select count(*) into v_anzahl
    from tasks where source = 'edvance_fundament' and source_ref like 'term-%';
  if v_anzahl <> @ANZAHL@ then
    raise exception 'nur % von @ANZAHL@ Term-Aufgaben angelegt.', v_anzahl;
  end if;

  select count(*) into v_anzahl
    from tasks where source = 'edvance_fundament' and source_ref like 'term-%'
     and status <> 'draft';
  if v_anzahl > 0 then
    raise exception '% Term-Aufgabe(n) stehen nicht auf draft.', v_anzahl;
  end if;

  select count(*) into v_anzahl
    from task_solutions s join tasks t on t.id = s.task_id
   where t.source = 'edvance_fundament' and t.source_ref like 'term-%'
     and t.input_type <> 'MC' and s.acceptance is not null;
  if v_anzahl > 0 then
    raise exception '% Term-Aufgabe(n) haben ein acceptance — das kippt die Bewertung.', v_anzahl;
  end if;

  raise notice 'Termumformung: alle Proben bestanden, @ANZAHL@ Aufgaben.';
end $$;

commit;
"""


if __name__ == "__main__":
    main()
