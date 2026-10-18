#!/usr/bin/env python3
"""
Figuren Welle 1 (F2, PR 2): Konsistenz der Figuren mit dem Aufgabentext und die Daten-Migration.

    python3 tools/figuren-welle1.py konsistenz docs/figuren/welle1.json <prod.json>
    python3 tools/figuren-welle1.py sql        docs/figuren/welle1.json <prod.json>  > supabase/migrations/…sql

<prod.json> ist ein read-only Abzug je Aufgabe (dbread, nicht eingecheckt):
    {"<task_id>": {"question", "md5", "correct", "figur", "entscheidung", "status", "pruef_version"}}

konsistenz prueft je Figur:
  1. pruefe_<generator> besteht in beiden Themes
  2. jede Zahl in der Figur steht im Aufgabentext (gleiche Zahlen)
  3. jede Bezeichnung (Punkt, Winkelname, Term) steht im Aufgabentext (gleiche Bezeichnungen)
  4. keine Zahl aus correct_answers steht in der Figur, die nicht schon im Text steht (verraet nichts)
  5. alt_text nicht leer, ohne Ziffern; die Aufgabe hat noch keine Figur
"""

from __future__ import annotations

import importlib
import json
import re
import sys
from pathlib import Path

WURZEL = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(WURZEL / 'scripts'))

ZAHL = re.compile(r'\d+(?:[.,]\d+)?')
NAMEN = re.compile(r'^[ABCM]$|^[αβγ]')


def _zahlen(text: str) -> set[str]:
    return {z.replace('.', ',') for z in ZAHL.findall(text)}


def _texte(svg: str) -> list[str]:
    return [t.replace('&lt;', '<').replace('&gt;', '>').replace('&amp;', '&') for t in re.findall(r'>([^<>]+)</text>', svg)]


def _ohne_leer(text: str) -> str:
    return re.sub(r'\s+', '', text).replace('−', '-')


def _bezeichnungen(texte: list[str]) -> set[str]:
    """Punktnamen, Winkelnamen (α, β, γ) und Terme mit x — alles, was gleich heissen muss wie im Text."""
    aus = set()
    for t in texte:
        if NAMEN.match(t):
            aus.add(t[0])
        m = re.match(r'^(\(?x[^)]*\)?|x)\s*[a-z]*$', t.replace('²', ''))
        if 'x' in t and m:
            aus.add(re.sub(r'\s*(cm|m)$', '', t))
    return aus


def konsistenz(spec: dict, prod: dict) -> list[str]:
    befunde = []
    for f in spec['figuren']:
        tid, kurz = f['task_id'], f['task_id'][:8]
        p = prod.get(tid)
        if p is None:
            befunde.append(f'{kurz}: Aufgabe fehlt im Prod-Abzug.')
            continue
        gen = importlib.import_module(f"figures.{f['generator']}")
        pr = importlib.import_module(f"figures.pruefe_{f['generator']}")
        svgs = {th: gen.zeichne(f['params'], th) for th in ('dunkel', 'hell')}
        for th, svg in svgs.items():
            ok, meldung = pr.pruefe(svg, f['params'])
            if not ok:
                befunde.append(f'{kurz} [{th}]: pruefe: {meldung}')
        texte = _texte(svgs['dunkel'])
        frage = p['question']
        for z in sorted(set().union(*(_zahlen(t) for t in texte)) - _zahlen(frage)):
            befunde.append(f'{kurz}: Zahl {z} in der Figur, nicht im Aufgabentext.')
        for b in sorted(_bezeichnungen(texte)):
            if _ohne_leer(b) not in _ohne_leer(frage):
                befunde.append(f'{kurz}: Bezeichnung {b!r} in der Figur, nicht im Aufgabentext.')
        loesung = set().union(*(_zahlen(str(c)) for c in (p['correct'] or []))) if isinstance(p['correct'], list) else set()
        for z in sorted((loesung & set().union(*(_zahlen(t) for t in texte))) - _zahlen(frage)):
            befunde.append(f'{kurz}: Loesung {z} steht in der Figur.')
        if not f['alt_text'].strip() or re.search(r'\d', f['alt_text']):
            befunde.append(f'{kurz}: alt_text leer oder mit Ziffern.')
        if p['figur']:
            befunde.append(f'{kurz}: hat schon eine Figur — wird nicht ueberschrieben.')
        print(f'{kurz} {f["generator"]:9} Texte: {" | ".join(texte)}')
    return befunde


def _lit(text: str) -> str:
    return "'" + text.replace("'", "''") + "'"


def sql(spec: dict, prod: dict) -> str:
    zeilen = []
    for f in spec['figuren']:
        p = prod[f['task_id']]
        params = json.dumps(f['params'], ensure_ascii=False, sort_keys=True)
        zeilen.append(f"  ({_lit(f['task_id'])}::uuid, {_lit(p['md5'])}, {_lit(f['generator'])}, "
                      f"{_lit(params)}::jsonb,\n   {_lit(f['alt_text'])})")
    return f"""-- Figuren Welle 1 (F2, PR 2): {len(zeilen)} Figuren fuer Pilot-Aufgaben.
--
-- Quelle: docs/figuren/welle1.json (Specs aus docs/figuren/bedarf.json, F1), erzeugt mit
-- tools/figuren-welle1.py sql. Setzt PR 1 voraus (CHECK kennt thales, rechtecke, rechteck).
--
-- Gezielt je Aufgabe und nur, wenn
--   - die Aufgabe den Text hat, fuer den die Figur gebaut ist (md5 der Frage wie beim Bau), und
--   - noch keine Figur hat (on conflict do nothing).
-- svg_hash bleibt leer: Erst upload_figures.py erzeugt, prueft, laedt hoch und stempelt. Bis dahin
-- erscheint nichts im Payload (lsa_task_assets verlangt svg_hash). tasks bleibt unberuehrt — Status,
-- pruef_version und Lenas Pruefstand aendern sich nicht.

with neu (task_id, frage_md5, generator, params, alt_text) as (values
{(',' + chr(10)).join(zeilen)}
), eingefuegt as (
  insert into public.task_figures (task_id, generator, params, alt_text)
  select n.task_id, n.generator, n.params, n.alt_text
    from neu n
    join public.tasks t on t.id = n.task_id and md5(t.question) = n.frage_md5
  on conflict (task_id) do nothing
  returning task_id
)
select 'figuren-welle1: ' || count(*) || ' Figuren angelegt' as figuren_welle1 from eingefuegt;
"""


def main() -> int:
    befehl, spec_pfad, prod_pfad = sys.argv[1:4]
    spec = json.loads(Path(spec_pfad).read_text(encoding='utf-8'))
    prod = json.loads(Path(prod_pfad).read_text(encoding='utf-8'))
    if befehl == 'sql':
        sys.stdout.write(sql(spec, prod))
        return 0
    befunde = konsistenz(spec, prod)
    for b in befunde:
        print('BEFUND', b)
    print(f'{len(spec["figuren"])} Figuren, {len(befunde)} Befunde')
    return 1 if befunde else 0


if __name__ == '__main__':
    raise SystemExit(main())
