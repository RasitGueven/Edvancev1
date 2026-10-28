#!/usr/bin/env python3
"""
Gemeinsame Basis der Bauformen (Sessionreihe 1, Konzept §3–§5).

Eine Bauform beschreibt einen Aufgabentyp mit Platzhaltern. Je Bauform eine Datei unter bauformen/<key>.py mit einer
Klasse, die von `Bauform` erbt und mindestens `parameter`, `erzeugen` und `loesen_unabhaengig` liefert. Die
Pruefmaschine (pruefmaschine.py) prueft jede erzeugte Instanz, der Export (export.py) schreibt Migration und Vorschau.

Grundsaetze
  - Gerechnet wird mit Fraction (exakt), nie mit float.
  - `erzeugen` baut die Kindersicht (Text, Payload) und die Loesung aus den Parametern.
  - `loesen_unabhaengig` rechnet die Loesung NEU aus dem fertigen Text bzw. den angezeigten Koeffizienten (sympy),
    nicht aus den Parametern — so faellt auf, wenn Text und Loesung auseinanderlaufen.
  - Fehlbilder sind Rechenregeln (wie entsteht die falsche Antwort) und gelten nur fuer die Stufen, fuer die sie im
    Steckbrief stehen.
"""

from __future__ import annotations

import hashlib
import inspect
import random
import re
from dataclasses import dataclass, field
from fractions import Fraction

ROLLEN = ('warmup', 'uebung', 'transfer', 'recap', 'beispiel', 'home', 'generalprobe')
ROLLE_KURZ = {'W': 'warmup', 'Ü': 'uebung', 'T': 'transfer', 'R': 'recap', 'B': 'beispiel', 'H': 'home', 'G': 'generalprobe'}
MINUS = '−'  # typografisches Minus (U+2212)


# ── Zahlen schreiben ─────────────────────────────────────────────────────────

def zahl(x: Fraction | int) -> str:
    """Zahl fuer den Kindertext: ganze Zahl oder gekuerzter Bruch, typografisches Minus, Dezimalkomma nie."""
    x = Fraction(x)
    vz = MINUS if x < 0 else ''
    x = abs(x)
    return f'{vz}{x.numerator}' if x.denominator == 1 else f'{vz}{x.numerator}/{x.denominator}'


def zahl_antwort(x: Fraction | int) -> str:
    """Zahl als Antwort-Text (ASCII-Minus, wie ein Kind tippt)."""
    return zahl(x).replace(MINUS, '-')


def koeff(a: Fraction | int, var: str, erstes: bool) -> str:
    """Ein Glied a·var fuer eine Summe: kein '1x', kein '+ −3x', kein '0x' (Pruefung 5). Leer bei a = 0."""
    a = Fraction(a)
    if a == 0:
        return ''
    betrag = abs(a)
    k = '' if (betrag == 1 and var) else zahl(betrag)
    if var and betrag.denominator != 1:
        k = f'{zahl(betrag)}'
    glied = f'{k}{var}'
    if erstes:
        return f'{MINUS}{glied}' if a < 0 else glied
    return f' {MINUS} {glied}' if a < 0 else f' + {glied}'


def summe(glieder: list[tuple[Fraction | int, str]]) -> str:
    """a·x² + b·x + c als Text aus (Koeffizient, Variable)-Paaren; '0', wenn alles null ist."""
    teile = []
    for a, var in glieder:
        t = koeff(a, var, erstes=not teile)
        if t:
            teile.append(t)
    return ''.join(teile) if teile else '0'


# ── Instanz ──────────────────────────────────────────────────────────────────

@dataclass
class Instanz:
    """Eine erzeugte Aufgabe. `loesung` und `fehlbilder` haben die Form aus DATENVERTRAG §13.6."""
    bauform: str
    rolle: str
    stufe: int
    params: dict
    frage: str                       # Kindertext (tasks.question)
    input_type: str                  # FELDMASKE, LOESUNGSMENGE, … oder NUMERIC/MC/MULTI_PART
    payload: dict                    # Kindersicht (question_payload), ohne Loesung
    loesung: dict                    # correct_answers[0] ohne fehlbilder (neue Formate) bzw. {"werte": [...]} (Zahl)
    fehlbilder: list[dict]           # [{"key", <Antwort-Bedeutung>}] — nur die fuer diese Stufe geltenden
    hinweise: list[str]              # drei Stufen
    loesungsweg: list[str]           # Schritte (task_solutions.solution, je Zeile ein Schritt)
    schreibweisen: list[dict] = field(default_factory=list)  # weitere richtige Antworten (Pruefung 4)
    figur: dict | None = None        # {"generator", "params", "alt"} bzw. Optionsfiguren
    pruefmaschine: dict = field(default_factory=dict)
    teile: list[dict] | None = None  # Mehrteiler/Tabelle: tasks.parts [{nr, kind: short_input|mc, prompt, options?}]

    @property
    def schluessel(self) -> str:
        """Fuer Dubletten (Pruefung 7): alles, was das Kind sieht (Text, Bedienelemente, Figur, Teile)."""
        import json
        return f'{self.input_type}|{self.frage}|' + json.dumps([self.figur, self.teile, self.payload], sort_keys=True,
                                                              ensure_ascii=False)


class Bauform:
    """Oberklasse je Bauform. Unterklassen setzen die Klassenattribute und die drei Methoden."""

    key: str = ''
    skill: str = ''
    kernidee: str | None = None
    format: str = ''
    rollen: tuple[str, ...] = ()
    stufen: dict[int, str] = {}        # Stufe → Beschreibung (Steckbrief)
    text: str = ''                     # Aufgabentext mit Platzhaltern (Steckbrief)
    fehlbild_steckbrief: list[dict] = []   # {"key", "regel", "rueckmeldung", "gilt_fuer_stufen"}
    hinweis_vorlagen: list[str] = []   # drei Stufen mit Platzhaltern
    loesungsweg_vorlage: list[str] = []
    warum: dict | None = None          # {"bei_schritt", "frage", "bausteine": [{id, text}], "richtig"}
    kontext: str | None = None
    zeit_sek: int = 90
    kann_entfallen: bool = False
    figur: dict | None = None
    # Mindestzahl Instanzen je Rolle und Stufe (Konzept §3.2); Generalprobe so viele, dass zehn Kinder je eine
    # ungesehene bekommen.
    anzahl: dict[str, int] = {'generalprobe': 12}
    anzahl_standard: int = 8

    # ── von Unterklassen ──
    def parameter(self, stufe: int, rng: random.Random) -> dict:  # pragma: no cover - abstrakt
        raise NotImplementedError

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:  # pragma: no cover - abstrakt
        raise NotImplementedError

    def loesen_unabhaengig(self, inst: Instanz) -> dict:  # pragma: no cover - abstrakt
        """Loesung neu aus dem angezeigten Text (sympy). Gleiche Form wie inst.loesung."""
        raise NotImplementedError

    def angenehm(self, inst: Instanz) -> str | None:
        """Pruefung 2: None, wenn die Zahlen zur Stufe passen, sonst der Grund."""
        return None

    # ── gemeinsam ──
    def stufen_der_rolle(self, rolle: str) -> list[int]:
        stufen = sorted(self.stufen)
        if rolle == 'home':
            return [s for s in stufen if s <= 3]
        if rolle == 'beispiel':
            return [s for s in stufen if s <= 2] or stufen[:1]
        return stufen

    def fehlbilder_fuer(self, stufe: int) -> list[dict]:
        return [f for f in self.fehlbild_steckbrief if stufe in f['gilt_fuer_stufen']]

    def steckbrief(self) -> dict:
        return {
            'text': self.text,
            'stufen': {str(k): v for k, v in sorted(self.stufen.items())},
            'fehlbilder': self.fehlbild_steckbrief,
            'hinweise': self.hinweis_vorlagen,
            'loesungsweg': self.loesungsweg_vorlage,
            'warum': self.warum,
            'kontext': self.kontext,
            'figur': self.figur,
            'zeit_sek': self.zeit_sek,
            'kann_entfallen': self.kann_entfallen,
            'generator_hash': hashlib.sha1(inspect.getsource(type(self)).encode()).hexdigest()[:12],
        }

    def alle_instanzen(self, seed: int = 1) -> list[Instanz]:
        """Je Rolle und Stufe bis zu `anzahl` Instanzen, keine zwei mit gleicher Kindersicht (auch nicht ueber Rollen).
        Je Stufe werden die Kandidaten reihum an die Rollen verteilt, damit bei kleinem Zahlenraum jede Rolle etwas
        bekommt (ein Kind sieht dieselbe Aufgabe nie in zwei Rollen)."""
        rng = random.Random(f'{self.key}-{seed}')
        aus: list[Instanz] = []
        gesehen: set[str] = set()
        for stufe in sorted(self.stufen):
            rollen = [r for r in self.rollen if stufe in self.stufen_der_rolle(r)]
            ziel = {r: self.anzahl.get(r, self.anzahl_standard) for r in rollen}
            stand = {r: 0 for r in rollen}
            versuche = 0
            while any(stand[r] < ziel[r] for r in rollen) and versuche < 400:
                for r in rollen:
                    if stand[r] >= ziel[r]:
                        continue
                    for _ in range(40):
                        versuche += 1
                        inst = self.erzeugen(self.parameter(stufe, rng), r, stufe)
                        if inst.schluessel not in gesehen:
                            gesehen.add(inst.schluessel)
                            aus.append(inst)
                            stand[r] += 1
                            break
        return aus


def ersetze(vorlage: str, werte: dict) -> str:
    """{name} → Wert; ein nicht ersetzter Platzhalter bleibt stehen (Pruefung 5 findet ihn)."""
    return re.sub(r'\{(\w+)\}', lambda m: str(werte.get(m.group(1), m.group(0))), vorlage)
