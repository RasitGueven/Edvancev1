#!/usr/bin/env python3
"""
Die Formate, die es schon gab (Konzept §7): Zahl/Bruch (NUMERIC), Multiple Choice (MC), Mehrteiler und Tabelle
(MULTI_PART). Gespeichert wie jede andere Aufgabe dieser Typen, damit Player (edvance-app `Buehne`) und
`session_bewerten` unveraendert gelten:

  Format      input_type   Kindersicht                              Loesung in der Instanz        DB
  zahl/bruch  NUMERIC      {kind: short_input, prompt}             {"werte": [kanonisch, …]}     correct_answers = werte
  mc          MC           {input_type: MC, options: [{id,label}]} {"option": "b"}                correct_answers = ["b"]
  mehrteiler, MULTI_PART   question_payload null, tasks.parts      {"teile": {"1": [kanonisch,…]}} correct_answers = teile
  tabelle

Fehlbilder: zahl {"key", "wert"}, mc {"key", "option"}, mehrteiler {"key", "teil", "wert"} → acceptance.known_errors
(Wert → Schluessel), je Teil unter acceptance."<nr>".
"""

from __future__ import annotations

KLASSISCH = {'zahl': 'NUMERIC', 'bruch': 'NUMERIC', 'mc': 'MC', 'mehrteiler': 'MULTI_PART', 'tabelle': 'MULTI_PART'}


def ist_klassisch(fmt: str) -> bool:
    return fmt in KLASSISCH


def zahl_payload(frage: str) -> dict:
    return {'kind': 'short_input', 'prompt': frage}


def mc_payload(optionen: list[tuple[str, str]]) -> dict:
    return {'input_type': 'MC', 'options': [{'id': i, 'label': l} for i, l in optionen]}


def teil(nr: int, prompt: str, optionen: list[tuple[str, str]] | None = None, einheit: str | None = None) -> dict:
    t = {'nr': nr, 'afb': None, 'kind': 'mc' if optionen else 'short_input', 'unit': einheit, 'prompt': prompt}
    if optionen:
        t['options'] = [{'id': i, 'label': l} for i, l in optionen]
    return t


def _mit_minus(w: str) -> list[str]:
    """Ein Wert in beiden Minus-Schreibweisen (ASCII und typografisch), lsa_is_correct normalisiert sie nicht."""
    return [w] + ([w.replace('-', '−')] if '-' in w else [])


def _dezimal(w: str) -> list[str]:
    """Ein Bruch mit endlicher Dezimalzahl auch als Dezimalzahl (Komma und Punkt), z. B. 81/2 → 40,5."""
    from fractions import Fraction
    try:
        x = Fraction(w.replace('−', '-'))
    except (ValueError, ZeroDivisionError):
        return []
    d = x.denominator
    while d % 2 == 0:
        d //= 2
    while d % 5 == 0:
        d //= 5
    if x.denominator == 1 or d != 1:
        return []
    t = f'{float(x):.6f}'.rstrip('0').rstrip('.')
    return [t.replace('.', ','), t]


def _regel(werte: list[str], fehler: dict[str, str]) -> dict:
    alle = list(dict.fromkeys(v for w in werte for v in _mit_minus(w)))
    r: dict = {'canonical': alle[0]}
    if len(alle) > 1:
        r['equivalents'] = alle[1:]
    if fehler:
        r['known_errors'] = {v: k for w, k in fehler.items() for d in [w, *_dezimal(w)] for v in _mit_minus(d)}
    return r


def _liste(werte: list[str]) -> list[str]:
    return list(dict.fromkeys(v for w in werte for v in _mit_minus(w)))


def db_loesung(fmt: str, loesung: dict, fehlbilder: list[dict]) -> tuple[object, dict]:
    """(correct_answers, acceptance) einer klassischen Instanz."""
    if fmt in ('zahl', 'bruch'):
        return _liste(loesung['werte']), _regel(loesung['werte'], {f['wert']: f['key'] for f in fehlbilder})
    if fmt == 'mc':
        return [loesung['option']], _regel([loesung['option']], {f['option']: f['key'] for f in fehlbilder})
    teile = {nr: _liste(w) for nr, w in loesung['teile'].items()}
    acc = {nr: _regel(w, {f['wert']: f['key'] for f in fehlbilder if str(f['teil']) == nr}) for nr, w in teile.items()
           if w}
    return teile, acc


def eingaben(fmt: str, loesung: dict, fehlbilder: list[dict], schreibweisen: list[dict],
             teile: list[dict] | None = None) -> list[dict]:
    """Probefaelle fuer Pruefung 4: {teil, eingabe, richtig, key}. Jede zulaessige Schreibweise trifft, jedes Fehlbild
    bekommt seinen Schluessel."""
    faelle = []
    if fmt in ('zahl', 'bruch'):
        for w in loesung['werte'] + [s['wert'] for s in schreibweisen]:
            faelle.append({'teil': None, 'eingabe': {'text': w}, 'richtig': True, 'key': None})
        faelle += [{'teil': None, 'eingabe': {'text': f['wert']}, 'richtig': False, 'key': f['key']} for f in fehlbilder]
    elif fmt == 'mc':
        faelle.append({'teil': None, 'eingabe': [loesung['option']], 'richtig': True, 'key': None})
        faelle += [{'teil': None, 'eingabe': [f['option']], 'richtig': False, 'key': f['key']} for f in fehlbilder]
    else:
        mc = {str(t['nr']) for t in teile or [] if t.get('kind') == 'mc'}

        def ein(nr: str, w: str):
            return [w] if nr in mc else {'text': w}
        for nr, werte in loesung['teile'].items():
            for w in werte + [s['wert'] for s in schreibweisen if str(s['teil']) == nr]:
                faelle.append({'teil': int(nr), 'eingabe': ein(nr, w), 'richtig': True, 'key': None})
        faelle += [{'teil': int(f['teil']), 'eingabe': ein(str(f['teil']), f['wert']), 'richtig': False, 'key': f['key']}
                   for f in fehlbilder]
    return faelle


# Genau der Weg von session_bewerten (Migration 20261027134831) fuer die bisherigen Formate, als reine Abfrage ueber
# die unveraenderlichen Funktionen lsa_part_answer, lsa_is_correct, lsa_grade, lsa_fehlbild_match.
WERTUNG_SQL = """
with f as (select x from jsonb_array_elements('{daten}'::jsonb) x),
w as (
  select x, pp.p, k.kind, r.resp,
         case when x->>'input_type' = 'MULTI_PART' then case when o.ok then 'voll' else 'nicht' end
              when x->>'input_type' in ('MC', 'TERM') then case when o.ok then 'voll' else 'nicht' end
              else public.lsa_grade(x->>'input_type', x->'acc', x->'ca', r.resp) end as st,
         case when x->>'input_type' = 'MULTI_PART'
              then coalesce(x->'acc'->(pp.p->>'nr')->'known_errors', x->'acc'->'known_errors')
              else x->'acc'->'known_errors' end as ke
    from f
    cross join lateral (select (select p from jsonb_array_elements(coalesce(x->'parts', '[]')) p
                                 where (p->>'nr')::int = (x->>'teil')::int) as p) pp
    cross join lateral (select case when x->>'input_type' = 'MULTI_PART' then pp.p->>'kind'
                                    else lower(x->>'input_type') end as kind) k
    cross join lateral (select public.lsa_part_answer(k.kind, x->'eingabe') as resp) r
    cross join lateral (select case when x->>'input_type' = 'MULTI_PART' then
                          coalesce(public.lsa_is_correct(case when k.kind = 'mc' then 'MC' else 'SHORT_TEXT' end,
                                   case when jsonb_typeof(x->'ca'->(pp.p->>'nr')) = 'array' then x->'ca'->(pp.p->>'nr')
                                        else '[]' end, r.resp), false)
                        else coalesce(public.lsa_is_correct(x->>'input_type', x->'ca', r.resp), false) end as ok) o
)
select jsonb_build_object('i', (x->>'i')::int, 'antwort', x->'eingabe', 'teil', x->'teil',
         'soll_richtig', (x->>'richtig')::boolean, 'soll_key', x->>'key', 'ist_richtig', st = 'voll',
         'ist_key', case when st <> 'voll' then public.lsa_fehlbild_match(kind, ke, resp) end)::text
  from w
 where (st = 'voll') is distinct from (x->>'richtig')::boolean
    or (st <> 'voll' and public.lsa_fehlbild_match(kind, ke, resp) is distinct from x->>'key');
"""
