#!/usr/bin/env python3
"""
Pruefmaschine der Bauformen (Konzept §5). Prueft jede Instanz; eine Instanz mit einem roten Punkt wird verworfen,
eine Bauform mit mehr als 30 % roten Instanzen ist selbst fehlerhaft (verdacht) und geht nicht ins Board.

  1 unabhaengig nachgerechnet (sympy aus dem angezeigten Text)       5 Schreibweise (kein „+ −3x“, „1x²“, „0x“,
  2 angenehme Zahlen je Stufe (Regeln der Bauform)                      leerer Platzhalter, ASCII-Minus)
  3 Fehlbilder durchgespielt (jede Fehlbild-Antwort anders als die    6 Figur nachgemessen (pruefe_-Module)
    richtige und als alle anderen)                                    7 keine Dubletten (untereinander, gegen LSA)
  4 Wertung getestet — gegen die ECHTE Wertung in der Datenbank (format_werten_daten per dbread, lesend): jede
    zulaessige Schreibweise der richtigen Antwort trifft, keine Fehlbild-Antwort trifft, jede bekommt ihr Fehlbild.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import tempfile
from fractions import Fraction

from .basis import Bauform, Instanz
from .rechnen import bruch

DBREAD = os.path.expanduser('~/bin/dbread')
ROT_GRENZE = 0.30


# ── Antworten aus Loesung und Fehlbild bauen (Form wie DATENVERTRAG §13.1) ───

def antwort_aus(fmt: str, payload: dict, wert: dict) -> dict:
    """Antwort-JSON, die ein Kind fuer diese Loesung bzw. dieses Fehlbild abschicken wuerde."""
    if fmt == 'loesungsmenge':
        return {'keine_loesung': True} if wert.get('keine_loesung') else {'werte': list(wert['menge'])}
    if fmt == 'feldmaske':
        felder: dict[str, str] = {}
        teile = payload['schablone']
        for i, t in enumerate(teile):
            if 'feld' not in t or t['typ'] == 'vorzeichen':
                continue
            v = wert['werte'][t['feld']]
            vor = teile[i - 1] if i > 0 else {}
            if vor.get('typ') == 'vorzeichen':
                negativ = bruch(v) < 0
                felder[vor['feld']] = '−' if negativ else '+'
                v = str(abs(bruch(v))).replace('-', '')
            felder[t['feld']] = v
        return {'felder': felder}
    if fmt == 'graph_auswahl':
        return {'gewaehlt': wert['option']}
    if fmt == 'fehler_finden':
        return {'zeile': wert.get('zeile'), 'warum': wert.get('warum')}
    if fmt == 'bausteine':
        return {'gewaehlt': list(wert['gewaehlt'])}
    if fmt == 'schritte_ordnen':
        return {'reihenfolge': list(wert['reihenfolgen'][0] if 'reihenfolgen' in wert else wert['reihenfolge'])}
    raise ValueError(f'Format {fmt} hat noch keine Antwort-Bildung')


def bedeutung(fmt: str, wert: dict) -> str:
    """Vergleichbare Bedeutung einer Antwort/Loesung (Pruefung 3): Mengen als Bruchmengen, sonst JSON."""
    if fmt == 'loesungsmenge':
        if wert.get('keine_loesung'):
            return 'leer'
        return repr(sorted({bruch(v) for v in wert['menge']}))
    if fmt == 'feldmaske':
        return repr(sorted((k, bruch(v)) for k, v in wert['werte'].items()))
    return json.dumps({k: v for k, v in wert.items() if k != 'key'}, sort_keys=True)


# ── Pruefungen je Instanz ────────────────────────────────────────────────────

SCHREIBFEHLER = [
    (re.compile(r'\+\s*[−-]'), '„+ −“'),
    (re.compile(r'(?<![\d,./])1x'), '„1x“'),
    (re.compile(r'(?<![\d,./])0x'), '„0x“'),
    (re.compile(r'\{[A-Za-z_]\w*\}'), 'leerer Platzhalter'),
    (re.compile(r'(?:^|[\s(={;|\[])-\s?\d'), 'ASCII-Minus statt −'),
    (re.compile(r'[−-]\s*[−-]'), 'doppeltes Minus'),
]


def texte(inst: Instanz) -> list[str]:
    t = [inst.frage, *inst.hinweise, *inst.loesungsweg]
    t += [s for s in re.findall(r'"([^"]*)"', json.dumps(inst.payload, ensure_ascii=False)) if not re.fullmatch(r'[a-z_]+', s)]
    return t


def pruefe_schreibweise(inst: Instanz) -> str | None:
    for text in texte(inst):
        for muster, name in SCHREIBFEHLER:
            if muster.search(text):
                return f'{name} in „{text}“'
    return None


def pruefe_fehlbilder(bf: Bauform, inst: Instanz) -> str | None:
    richtig = bedeutung(bf.format, inst.loesung)
    gesehen = {richtig: 'richtig'}
    for f in inst.fehlbilder:
        b = bedeutung(bf.format, f)
        if b in gesehen:
            return f'{f["key"]} ergibt dieselbe Antwort wie {gesehen[b]}'
        gesehen[b] = f['key']
    erlaubt = {f['key'] for f in bf.fehlbilder_fuer(inst.stufe)}
    fremd = [f['key'] for f in inst.fehlbilder if f['key'] not in erlaubt]
    return f'Fehlbild ausserhalb seiner Stufen: {fremd}' if fremd else None


def pruefe_figur(inst: Instanz) -> str | None:
    if not inst.figur:
        return None
    import importlib
    import sys
    wurzel = os.path.join(os.path.dirname(__file__), '..')
    if wurzel not in sys.path:
        sys.path.insert(0, wurzel)
    figuren = inst.figur if isinstance(inst.figur, list) else [inst.figur]
    for f in figuren:
        gen = importlib.import_module(f'figures.{f["generator"]}')
        pr = importlib.import_module(f'figures.pruefe_{f["generator"]}')
        for theme in ('dunkel', 'hell'):
            ok, meldung = pr.pruefe(gen.zeichne(f['params'], theme), f['params'])
            if not ok:
                return f'Figur {f.get("option", "")} [{theme}]: {meldung}'
        if re.search(r'\d', f.get('alt', '')):
            return 'Alternativtext enthält Ziffern'
    return None


def zahlenfolge(text: str) -> tuple[str, ...]:
    return tuple(re.findall(r'\d+(?:[.,]\d+)?', text))


# ── Pruefung 4 gegen die Datenbank ───────────────────────────────────────────

def dbread_json(sql: str) -> list[dict]:
    """Eine lesende Abfrage per ~/bin/dbread; jede Zeile ist ein JSON-Objekt."""
    with tempfile.NamedTemporaryFile('w', suffix='.sql', delete=False) as f:
        f.write('\\pset format unaligned\n\\pset tuples_only on\n' + sql)
        pfad = f.name
    try:
        out = subprocess.run([DBREAD, '-f', pfad], capture_output=True, text=True, check=True).stdout
    finally:
        os.unlink(pfad)
    return [json.loads(z) for z in out.splitlines() if z.startswith('{')]


def wertung_pruefen(bf: Bauform, instanzen: list[Instanz]) -> dict[int, str | None]:
    """Je Instanz None (alles trifft wie erwartet) oder der erste Widerspruch."""
    faelle = []
    for i, inst in enumerate(instanzen):
        loes = {**inst.loesung, 'fehlbilder': inst.fehlbilder}
        richtige = [antwort_aus(bf.format, inst.payload, inst.loesung)] + inst.schreibweisen
        for a in richtige:
            faelle.append({'i': i, 'antwort': a, 'richtig': True, 'key': None})
        for fb in inst.fehlbilder:
            faelle.append({'i': i, 'antwort': antwort_aus(bf.format, inst.payload, fb), 'richtig': False, 'key': fb['key']})
        for f in faelle:
            if f['i'] == i:
                f.update(fmt=bf.format, payload=inst.payload, loesung=loes)
    daten = json.dumps(faelle, ensure_ascii=False).replace("'", "''")
    sql = f"""
with f as (select x from jsonb_array_elements('{daten}'::jsonb) x)
select jsonb_build_object('i', (x->>'i')::int, 'antwort', x->'antwort', 'soll_richtig', (x->>'richtig')::boolean,
         'soll_key', x->>'key', 'ist_richtig', r.richtig, 'ist_key', r.fehlbild_key)::text
  from f, public.format_werten_daten(x->>'fmt', x->'payload', x->'loesung', x->'loesung'->'fehlbilder', x->'antwort') r
 where r.richtig is distinct from (x->>'richtig')::boolean
    or (not r.richtig and r.fehlbild_key is distinct from x->>'key');
"""
    ergebnis: dict[int, str | None] = {i: None for i in range(len(instanzen))}
    for z in dbread_json(sql):
        if ergebnis[z['i']] is None:
            ergebnis[z['i']] = (f'Antwort {json.dumps(z["antwort"], ensure_ascii=False)}: erwartet '
                                f'{"richtig" if z["soll_richtig"] else z["soll_key"]}, Wertung sagt '
                                f'{"richtig" if z["ist_richtig"] else (z["ist_key"] or "falsch ohne Fehlbild")}')
    return ergebnis


def lsa_zahlenfolgen(skill: str) -> set[tuple[str, ...]]:
    sql = f"""select jsonb_build_object('q', question)::text from public.tasks
               where skill_key = '{skill}' and 'lsa' = any (einsatz) and question is not null;"""
    return {zahlenfolge(z['q']) for z in dbread_json(sql)}


# ── Ablauf ───────────────────────────────────────────────────────────────────

def pruefen(bf: Bauform, instanzen: list[Instanz], mit_db: bool = True) -> dict:
    """Setzt inst.pruefmaschine je Instanz; liefert das Protokoll der Bauform."""
    wertung = wertung_pruefen(bf, instanzen) if mit_db else {i: None for i in range(len(instanzen))}
    lsa = lsa_zahlenfolgen(bf.skill) if mit_db else set()
    gesehen: set[str] = set()
    gruende: dict[str, int] = {}
    for i, inst in enumerate(instanzen):
        try:
            unabhaengig = bf.loesen_unabhaengig(inst)
            p1 = None if bedeutung(bf.format, unabhaengig) == bedeutung(bf.format, inst.loesung) else \
                f'nachgerechnet {unabhaengig}, angezeigt {inst.loesung}'
        except Exception as e:  # noqa: BLE001 — jede Ausnahme heisst: nicht nachrechenbar
            p1 = f'nicht nachrechenbar: {e}'
        p7 = None
        if inst.schluessel in gesehen:
            p7 = 'Dublette in der Bauform'
        elif zahlenfolge(inst.frage) in lsa:
            p7 = 'gleiche Zahlen wie eine LSA-Aufgabe des Skills'
        gesehen.add(inst.schluessel)
        befunde = {'1': p1, '2': bf.angenehm(inst), '3': pruefe_fehlbilder(bf, inst), '4': wertung[i],
                   '5': pruefe_schreibweise(inst), '6': pruefe_figur(inst), '7': p7}
        inst.pruefmaschine = {k: ({'ok': True} if v is None else {'ok': False, 'grund': v}) for k, v in befunde.items()}
        for k, v in befunde.items():
            if v is not None:
                gruende[k] = gruende.get(k, 0) + 1
    rot = sum(1 for inst in instanzen if any(not p['ok'] for p in inst.pruefmaschine.values()))
    anteil = round(rot / len(instanzen), 3) if instanzen else 1.0
    return {'gruen': len(instanzen) - rot, 'rot': rot, 'rot_anteil': anteil, 'gruende': gruende,
            'verdacht': f'Pruefmaschine: {anteil:.0%} rot' if anteil > ROT_GRENZE else None}


def gruene(instanzen: list[Instanz]) -> list[Instanz]:
    return [i for i in instanzen if all(p['ok'] for p in i.pruefmaschine.values())]
