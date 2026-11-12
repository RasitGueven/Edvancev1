#!/usr/bin/env bash
# bauform-rueckfragen.sh — schreibt alle offenen Rückfragen zu Bauformen (SP-1) nach docs/freigabe/sp1/rueckfragen/<KEY>.md:
# je Kommentar Ort (Anker), Gründe, Text, Status und bei Beispielen die betroffene Instanz mit Aufgabentext und Lösung.
# Nur lesend (~/bin/dbread). Ablauf danach: docs/freigabe/sp1/rueckfragen-ablauf.md.
#   bash tools/bauform-rueckfragen.sh            alle Bauformen mit Status rueckfrage und kommentierter letzter Prüfung
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
ZIEL=docs/freigabe/sp1/rueckfragen
mkdir -p "$ZIEL"
DBREAD=${DBREAD:-$HOME/bin/dbread}
JSON=$($DBREAD -q -tAc "
  select coalesce(jsonb_agg(jsonb_build_object(
           'key', b.schluessel, 'titel', b.titel, 'version', b.version, 'status', b.status,
           'generator', b.generator_pfad, 'pruefung_id', p.id, 'pruefung_version', p.version, 'am', p.geprueft_am,
           'kommentare', (select jsonb_agg(jsonb_build_object(
               'id', k.id, 'anker', k.anker, 'gruende', k.gruende, 'text', k.text, 'status', k.status,
               'notiz', k.erledigt_notiz, 'task_id', k.task_id, 'stufe', t.stufe, 'rolle', t.rolle,
               'frage', t.question, 'loesung', s.correct_answers -> 0, 'loesungsweg', s.solution, 'params', t.params)
               order by k.angelegt_am)
             from bauform_kommentare k
             left join tasks t on t.id = k.task_id
             left join task_solutions s on s.task_id = k.task_id
            where k.pruefung_id = p.id))
         order by b.schluessel), '[]'::jsonb)
    from bauformen b
    join lateral (select x.* from bauform_pruefungen x where x.bauform_id = b.id
                   order by x.geprueft_am desc, x.id limit 1) p on p.entscheidung = 'unsicher'
   where b.status = 'rueckfrage'
     and exists (select 1 from bauform_kommentare k where k.pruefung_id = p.id)" | grep -v '^\(BEGIN\|ROLLBACK\)$')
TMP=$(mktemp); trap 'rm -f "$TMP"' EXIT
printf '%s' "$JSON" > "$TMP"
python3 - "$ZIEL" "$TMP" <<'PY'
import json, sys, pathlib
ziel = pathlib.Path(sys.argv[1])
daten = json.loads(pathlib.Path(sys.argv[2]).read_text() or '[]')
ORT = {'grundgeruest': 'Grundgerüst', 'stufen': 'Stufen', 'fehlbilder': 'Typische Fehler', 'beispiel': 'Beispiel'}
for b in daten:
    z = [f"# Rückfrage {b['key']} · {b['titel'] or ''}", '',
         f"Version der Rückfrage: {b['pruefung_version']} · aktuelle Version: {b['version']} · Status: {b['status']} · "
         f"Prüfung {b['pruefung_id']} vom {b['am'][:10]}", f"Generator: `{b['generator']}`", '']
    for i, k in enumerate(b['kommentare'] or [], 1):
        z += [f"## {i}. {ORT.get(k['anker'], k['anker'])} · {k['status']}", '',
              f"- Kommentar-ID: `{k['id']}`",
              f"- Gründe: {', '.join(k['gruende']) or '–'}",
              f"- Text: {k['text'] or '–'}"]
        if k['task_id']:
            z += [f"- Instanz `{k['task_id']}` (Stufe {k['stufe']}, Rolle {k['rolle']}): {k['frage']}",
                  f"- Lösung: `{json.dumps(k['loesung'], ensure_ascii=False)}`",
                  f"- Parameter: `{json.dumps(k['params'], ensure_ascii=False)}`"]
            if k['loesungsweg']:
                z += ['- Lösungsweg:', '', '  ' + k['loesungsweg'].replace('\n', '\n  ')]
        if k['notiz']:
            z += [f"- Erledigt: {k['notiz']}"]
        z += ['']
    (ziel / f"{b['key']}.md").write_text('\n'.join(z))
    print(f"{b['key']}: {len(b['kommentare'] or [])} Kommentar(e)")
print(f"{len(daten)} offene Rückfrage(n) → {ziel}/")
PY
