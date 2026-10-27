#!/usr/bin/env python3
"""
Export einer Bauform: JSON-Vorschau, Kindertexte fuer den Blindloeser, Datenmigration (Konzept §3.2, Auftrag A4.4).

  vorschau(bf)            → docs/reihe1/A/bauformen/<KEY>.json (Steckbrief, Pruefprotokoll, alle Instanzen)
  blindaufgaben(bf)       → docs/reihe1/A/blindloeser/<KEY>/aufgaben.md (zehn zufaellige gruene Instanzen, nur
                            Kindertext und Antwortform, keine Loesung, kein Steckbrief)
  blind_auswerten(...)    → wertet die Antworten des Blindloesers ueber format_werten_daten (Prod, lesend) aus
  migration(bf, …)        → supabase/migrations/<V>_reihe1_bauform_<key>.sql: Bauform (Upsert, Version per Trigger),
                            gruene Instanzen (draft), Loesungen, Hinweise (entwurf), Fehlbilder, Figuren
"""

from __future__ import annotations

import hashlib
import json
import random
import subprocess
from dataclasses import asdict
from pathlib import Path

from .basis import Bauform, Instanz
from .pruefmaschine import dbread_json

WURZEL = Path(__file__).resolve().parents[2]
VORSCHAU = WURZEL / 'docs' / 'reihe1' / 'A' / 'bauformen'
BLIND = WURZEL / 'docs' / 'reihe1' / 'A' / 'blindloeser'
BLIND_ANZAHL = 10
BLIND_GRENZE = 0.10

ANTWORTFORM = {
    'loesungsmenge': 'Gib alle Lösungen an, getrennt durch Semikolon, z. B. „2; −5“. Gibt es keine, schreib „keine Lösung“.',
    'feldmaske': 'Gib die Zahl je Feld an, z. B. „Feld 1: …, Vorzeichen: −, Feld 2: …“.',
    'graph_auswahl': 'Gib den Buchstaben der Option an.',
    'fehler_finden': 'Gib die Zeilennummer und den Buchstaben der Begründung an.',
    'bausteine': 'Gib den Buchstaben (oder die zwei Buchstaben) an.',
    'schritte_ordnen': 'Gib die Reihenfolge der Schritt-Buchstaben an, z. B. „B, A, C“.',
}


def schluessel_datei(key: str) -> str:
    return key.lower().replace('-', '_')


def vorschau(bf: Bauform, instanzen: list[Instanz], protokoll: dict) -> Path:
    VORSCHAU.mkdir(parents=True, exist_ok=True)
    pfad = VORSCHAU / f'{bf.key}.json'
    pfad.write_text(json.dumps({
        'schluessel': bf.key, 'skill': bf.skill, 'kernidee': bf.kernidee, 'format': bf.format, 'rollen': list(bf.rollen),
        'steckbrief': bf.steckbrief(), 'pruefprotokoll': protokoll, 'blindloeser': None,
        'instanzen': [asdict(i) for i in instanzen],
    }, ensure_ascii=False, indent=1, default=str) + '\n')
    return pfad


def _kindertext(inst: dict, fmt: str) -> str:
    """Was das Kind sieht, als Text: Frage und die Bedienelemente des Formats (Optionen mit Buchstaben)."""
    p = inst['payload']
    zeilen = [inst['frage']]
    buchstaben = 'ABCDEFGH'
    if fmt == 'feldmaske':
        zeilen.append('Schablone: ' + ''.join(t.get('text') or (' [±] ' if t.get('typ') == 'vorzeichen' else ' [ ] ')
                                                for t in p['schablone']))
    elif fmt == 'graph_auswahl':
        zeilen += [f'{buchstaben[i]}: {o["alt"]}' for i, o in enumerate(p['optionen'])]
    elif fmt == 'fehler_finden':
        zeilen += [f'Zeile {z["nr"]}: {z["text"]}' for z in p['zeilen']]
        zeilen += ['Begründungen:'] + [f'{buchstaben[i]}: {w["text"]}' for i, w in enumerate(p['warum'])]
    elif fmt in ('bausteine', 'schritte_ordnen'):
        liste = p['bausteine'] if fmt == 'bausteine' else p['schritte']
        zeilen += [f'{buchstaben[i]}: {b["text"]}' for i, b in enumerate(liste)]
    return '\n'.join(zeilen)


def blindaufgaben(bf: Bauform) -> Path:
    daten = json.loads((VORSCHAU / f'{bf.key}.json').read_text())
    gruen = [i for i in daten['instanzen'] if all(p['ok'] for p in i['pruefmaschine'].values())]
    auswahl = random.Random(f'blind-{bf.key}').sample(gruen, min(BLIND_ANZAHL, len(gruen)))
    ordner = BLIND / bf.key
    ordner.mkdir(parents=True, exist_ok=True)
    (ordner / 'auswahl.json').write_text(json.dumps([gruen.index(i) for i in auswahl]) + '\n')
    text = [f'# Blindlöser {bf.key}', '', f'Antwortform: {ANTWORTFORM[bf.format]}', '']
    for n, inst in enumerate(auswahl, 1):
        text += [f'## Aufgabe {n}', '', _kindertext(inst, bf.format), '']
    (ordner / 'aufgaben.md').write_text('\n'.join(text))
    return ordner / 'aufgaben.md'


def _antwort_json(fmt: str, roh: str, inst: dict) -> dict:
    """Antwort des Blindloesers (Text) → Antwort-JSON des Formats."""
    t = roh.strip()
    if fmt == 'loesungsmenge':
        if 'keine' in t.lower():
            return {'keine_loesung': True}
        return {'werte': [w.strip() for w in t.replace(',', ';').split(';') if w.strip()] if ';' in t or ',' in t
                else [t]}
    buchstaben = 'ABCDEFGH'
    if fmt == 'graph_auswahl':
        return {'gewaehlt': inst['payload']['optionen'][buchstaben.index(t[0].upper())]['id']}
    if fmt == 'bausteine':
        return {'gewaehlt': [inst['payload']['bausteine'][buchstaben.index(c)]['id'] for c in t.upper() if c in buchstaben]}
    if fmt == 'schritte_ordnen':
        return {'reihenfolge': [inst['payload']['schritte'][buchstaben.index(c)]['id'] for c in t.upper() if c in buchstaben]}
    if fmt == 'fehler_finden':
        nr = int(''.join(ch for ch in t if ch.isdigit()))
        b = [c for c in t.upper() if c in buchstaben][-1]
        return {'zeile': nr, 'warum': inst['payload']['warum'][buchstaben.index(b)]['id']}
    raise ValueError(f'{fmt}: Antwort des Blindlösers nicht lesbar')


def blind_auswerten(bf: Bauform, antworten: dict[str, str]) -> dict:
    """antworten: {"1": "…", …} in der Reihenfolge von aufgaben.md. Wertet ueber format_werten_daten (Prod, lesend)."""
    daten = json.loads((VORSCHAU / f'{bf.key}.json').read_text())
    gruen = [i for i in daten['instanzen'] if all(p['ok'] for p in i['pruefmaschine'].values())]
    auswahl = [gruen[k] for k in json.loads((BLIND / bf.key / 'auswahl.json').read_text())]
    faelle = []
    for n, inst in enumerate(auswahl, 1):
        try:
            a = _antwort_json(bf.format, antworten.get(str(n), ''), inst)
        except (ValueError, IndexError):
            a = {}
        faelle.append({'n': n, 'fmt': bf.format, 'payload': inst['payload'],
                       'loesung': {**inst['loesung'], 'fehlbilder': inst['fehlbilder']}, 'antwort': a})
    daten_sql = json.dumps(faelle, ensure_ascii=False).replace("'", "''")
    ergebnis = dbread_json(f"""
select jsonb_build_object('n', (x->>'n')::int, 'richtig', r.richtig)::text
  from jsonb_array_elements('{daten_sql}'::jsonb) x,
       public.format_werten_daten(x->>'fmt', x->'payload', x->'loesung', x->'loesung'->'fehlbilder', x->'antwort') r;""")
    abweichend = sorted(z['n'] for z in ergebnis if not z['richtig'])
    anteil = round(len(abweichend) / len(auswahl), 3) if auswahl else 1.0
    befund = {'geloest': len(auswahl), 'abweichend': abweichend, 'anteil': anteil,
              'bestanden': anteil <= BLIND_GRENZE and len(auswahl) > 0,
              'antworten': antworten}
    daten['blindloeser'] = befund
    (VORSCHAU / f'{bf.key}.json').write_text(json.dumps(daten, ensure_ascii=False, indent=1, default=str) + '\n')
    return befund


def _sql(wert) -> str:
    return "'" + json.dumps(wert, ensure_ascii=False).replace("'", "''") + "'::jsonb"


def _text(wert: str | None) -> str:
    return 'null' if wert is None else "'" + wert.replace("'", "''") + "'"


def migration(bf: Bauform) -> Path:
    """Datenmigration aus der Vorschau (nur gruene Instanzen). Version per `date -u` (CLAUDE.md §10)."""
    daten = json.loads((VORSCHAU / f'{bf.key}.json').read_text())
    blind = daten.get('blindloeser')
    proto = daten['pruefprotokoll']
    verdacht = proto.get('verdacht') or (None if (blind and blind['bestanden']) else
                                         f'Blindlöser: {blind["anteil"]:.0%} abweichend' if blind else 'Blindlöser fehlt')
    gruen = [i for i in daten['instanzen'] if all(p['ok'] for p in i['pruefmaschine'].values())]
    zeilen = []
    for n, i in enumerate(gruen, 1):
        zeilen.append({
            # Inhalt im Schluessel (Zweitpruefung A4 Befund 1): eine korrigierte Instanz bekommt einen neuen Schluessel.
            'suffix': f'{i["rolle"]}-s{i["stufe"]}-' + hashlib.sha1(json.dumps([i['frage'], i['payload'], i['params']],
                                                                                sort_keys=True, ensure_ascii=False).encode()).hexdigest()[:10], 'input_type': i['input_type'], 'frage': i['frage'],
            'payload': i['payload'], 'params': i['params'], 'stufe': i['stufe'], 'rolle': i['rolle'],
            'pm': i['pruefmaschine'], 'afb': 'III' if i['rolle'] == 'transfer' else ('I' if i['stufe'] <= 2 else 'II'),
            'correct': [{**i['loesung'], 'fehlbilder': i['fehlbilder']}],
            'solution': '\n'.join(i['loesungsweg']),
            'hints': [{'level': k + 1, 'text': h, 'status': 'entwurf'} for k, h in enumerate(i['hinweise'])],
        })
    version = subprocess.run(['date', '-u', '+%Y%m%d%H%M%S'], capture_output=True, text=True, check=True).stdout.strip()
    pfad = WURZEL / 'supabase' / 'migrations' / f'{version}_reihe1_bauform_{schluessel_datei(bf.key)}.sql'
    proto_db = {**proto, 'lauf_am': version}
    status = 'entwurf' if verdacht else 'zur_pruefung'
    sql = f"""-- Reihe 1 · Bauform {bf.key} ({bf.skill}), erzeugt von tools/bauform.sh (scripts/bauformen/bauformen/{schluessel_datei(bf.key)}.py).
-- Steckbrief und {len(gruen)} gruene Instanzen (Status draft, Pool session). Pruefmaschine: {proto['gruen']} gruen,
-- {proto['rot']} rot (verworfen). Blindloeser: {json.dumps(blind and {k: blind[k] for k in ('geloest', 'abweichend', 'bestanden')})}.
-- Vorschau: docs/reihe1/A/bauformen/{bf.key}.json. Aendert sich der Steckbrief, steigt die Version (Trigger); die
-- Instanzen tragen die neue Version, die alten bleiben fuer die Historie. Der Steckbrief enthaelt den Hash des
-- Generators: aendert sich der Generator, steigt die Version ebenfalls.
--
-- Pruefabfrage: select count(*) from tasks t join bauformen b on b.id = t.bauform_id
--                where b.schluessel = '{bf.key}' and t.bauform_version = b.version;   → {len(gruen)}
do $$ begin perform set_config('edvance.bauform_export', '1', true); end $$;
insert into public.bauformen (schluessel, skill_key, kernidee_key, format, rollen, steckbrief, generator_pfad, status,
                              pruefprotokoll, blindloeser, verdacht)
values ({_text(bf.key)}, {_text(bf.skill)}, {_text(bf.kernidee)}, {_text(bf.format)}, {_text('{' + ','.join(bf.rollen) + '}')}::text[],
        {_sql(bf.steckbrief())}, {_text('scripts/bauformen/bauformen/' + schluessel_datei(bf.key) + '.py')}, {_text(status)},
        {_sql(proto_db)}, {_sql(blind) if blind else 'null'}, {_text(verdacht)})
on conflict (schluessel) do update
   set skill_key = excluded.skill_key, kernidee_key = excluded.kernidee_key, format = excluded.format,
       rollen = excluded.rollen, steckbrief = excluded.steckbrief, generator_pfad = excluded.generator_pfad,
       pruefprotokoll = excluded.pruefprotokoll, blindloeser = excluded.blindloeser, verdacht = excluded.verdacht,
       -- Lenas Entscheidung bleibt, solange sich nichts aendert; eine neue Version oeffnet der Trigger.
       status = case when excluded.verdacht is not null then 'entwurf'
                     when bauformen.status = 'entwurf' then 'zur_pruefung'
                     else bauformen.status end;

do $$ begin perform set_config('edvance.hinweis_status', 'setzen', true); end $$;
with b as (select id, version from public.bauformen where schluessel = {_text(bf.key)}),
     v as (select * from jsonb_to_recordset({_sql(zeilen)})
             as v(suffix text, input_type text, frage text, payload jsonb, params jsonb, stufe int, rolle text,
                  pm jsonb, afb text, correct jsonb, solution text, hints jsonb)),
     neu as (
  insert into public.tasks (content_type, input_type, status, is_active, title, question, question_payload, skill_key,
                            difficulty, afb, class_level, est_duration_sec, source, source_ref, einsatz, bauform_id,
                            bauform_version, params, stufe, rolle, kernidee_key, pruefmaschine)
  select 'exercise', v.input_type, 'draft', true, {_text(bf.key)} || ' · ' || v.rolle || ' · S' || v.stufe, v.frage,
         v.payload, {_text(bf.skill)}, v.stufe, v.afb, 9, {bf.zeit_sek}, 'bauform',
         {_text(bf.key)} || '-v' || b.version || '-' || v.suffix, '{{session}}', b.id, b.version, v.params, v.stufe,
         v.rolle, {_text(bf.kernidee)}, v.pm
    from b, v
  on conflict (source, source_ref) do nothing
  returning id, source_ref)
insert into public.task_solutions (task_id, correct_answers, solution, hints)
select neu.id, v.correct, v.solution, v.hints
  from neu join b on true join v on neu.source_ref = {_text(bf.key)} || '-v' || b.version || '-' || v.suffix;
do $$ begin perform set_config('edvance.hinweis_status', '', true); perform set_config('edvance.bauform_export', '', true); end $$;
"""
    pfad.write_text(sql)
    (WURZEL / 'supabase' / 'rollback' / pfad.name).write_text(f"""-- Rollback zu {pfad.stem}: nichts loeschen (Leitplanke A),
-- sondern stilllegen — die Instanzen dieser Bauform werden inaktiv (nie mehr gezogen), die Bauform geht auf entwurf
-- (nicht im Board). Danach den Eintrag in supabase_migrations.schema_migrations loeschen.
update public.tasks set is_active = false where source = 'bauform' and source_ref like {_text(bf.key + '-v%')};
update public.bauformen set status = 'entwurf' where schluessel = {_text(bf.key)};
""")
    return pfad
