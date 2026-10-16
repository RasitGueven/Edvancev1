#!/usr/bin/env python3
"""Session E3: Musterlösungen für gleichung_einschrittig, gleichung_zweischrittig und term_ausklammern, dazu ein
Fehlbild je Ablenker in term_ausklammern — Rechen-Check und Migration.

    PYTHONPATH=<sympy> python3 tools/session-e3-rechencheck.py            # nur rechnen, Exit 1 bei Abweichung
    PYTHONPATH=<sympy> python3 tools/session-e3-rechencheck.py --sql F    # zusätzlich Migration nach F schreiben

Geprüft wird mit sympy:
  Gleichungen   – jede Zeile des Lösungswegs hat dieselbe Lösungsmenge wie die Aufgabe, die Umformung hinter „|“
                  führt genau zur nächsten Zeile, die letzte Zeile ist x = <correct_answers[0]>.
  Ausklammern   – der ggT stimmt, jede Seite der Gleichungskette ist gleich dem Aufgabenterm, die richtige Option ist
                  gleich dem Aufgabenterm und vollständig ausgeklammert, jeder Ablenker entsteht aus seinem Fehlerweg.
Aufgaben, Antworten und Options-Texte sind gegen Prod (dbread, 16.10.2026) abgeschrieben; die Wegwerf-DB gleicht sie ab.
"""
import json
import re
import sys
from math import gcd

from sympy import Eq, S, expand, solveset, symbols
from sympy.parsing.sympy_parser import (implicit_multiplication_application, parse_expr,
                                        standard_transformations)

x = symbols('x')
TR = standard_transformations + (implicit_multiplication_application,)


def term(s):
    return parse_expr(s.replace('−', '-').replace('·', '*').replace(':', '/'), transformations=TR, local_dict={'x': x})


def loesungen(zeile):
    l, r = zeile.split('=')
    return solveset(Eq(term(l), term(r)), x, S.Reals)


# Gleichungen: (id, Knoten, Gleichung wie im Aufgabentext, correct_answers[0], Lösungsweg)
GL = [
    ('bfd877b9-cd3e-490c-82ad-0274b4f85a8b', 'gleichung_einschrittig', 'x + 7 = 12', '5', ['x + 7 = 12 | − 7', 'x = 5']),
    ('4f6f7cdd-3415-4185-8eae-95083d061b71', 'gleichung_einschrittig', 'x − 4 = 9', '13', ['x − 4 = 9 | + 4', 'x = 13']),
    ('152bcdcd-897b-452b-9a8f-402375540a3f', 'gleichung_einschrittig', '3x = 18', '6', ['3x = 18 | : 3', 'x = 6']),
    ('d19c8070-85d9-44cc-b4cc-eac3e06010d0', 'gleichung_einschrittig', 'x + 12 = 20', '8', ['x + 12 = 20 | − 12', 'x = 8']),
    ('6fc6928a-6ae3-4c32-9c2e-b9a20451b97c', 'gleichung_einschrittig', 'x − 9 = 6', '15', ['x − 9 = 6 | + 9', 'x = 15']),
    ('fbd28765-b198-4ff6-bdbe-de9ccc5202de', 'gleichung_einschrittig', '4x = 24', '6', ['4x = 24 | : 4', 'x = 6']),
    ('7976c81f-9b0b-46d8-a0d1-b5b6cc3bc992', 'gleichung_zweischrittig', '3x + 6 = 24', '6',
     ['3x + 6 = 24 | − 6', '3x = 18 | : 3', 'x = 6']),
    ('e8348c89-67cb-4650-be91-235e69321776', 'gleichung_zweischrittig', '2x + 4 = 20', '8',
     ['2x + 4 = 20 | − 4', '2x = 16 | : 2', 'x = 8']),
    ('9d15a93e-961b-4569-be8b-c4482dc98301', 'gleichung_zweischrittig', '5x + 10 = 45', '7',
     ['5x + 10 = 45 | − 10', '5x = 35 | : 5', 'x = 7']),
    ('b01451c0-53e5-4da7-9591-280448264835', 'gleichung_zweischrittig', '4x + 8 = 40', '8',
     ['4x + 8 = 40 | − 8', '4x = 32 | : 4', 'x = 8']),
    ('17f3e728-2249-42ba-b5bf-c2a4b344dd00', 'gleichung_zweischrittig', '3x + 9 = 30', '7',
     ['3x + 9 = 30 | − 9', '3x = 21 | : 3', 'x = 7']),
    ('ff5710af-0c0a-47e5-9a57-b2a5bb4ef82d', 'gleichung_zweischrittig', '6x + 12 = 42', '5',
     ['6x + 12 = 42 | − 12', '6x = 30 | : 6', 'x = 5']),
]

NEUE_SLUGS = {
    'ausklammern_nicht_ggt': ('gleichungen_umformen',
        'Klammert einen gemeinsamen Teiler aus, aber nicht den größten: 8x + 12 = 2(4x + 6).',
        'Ausklammern „so weit wie möglich“ heißt: den größten gemeinsamen Teiler vor die Klammer ziehen. Wer einen '
        'kleineren Teiler nimmt, rechnet richtig, ist aber nicht fertig – in der Klammer steckt noch ein gemeinsamer '
        'Faktor. Geübt wird, nach dem Ausklammern zu prüfen, ob die Zahlen in der Klammer noch einen Teiler teilen.'),
    'ausklammern_glied_nicht_geteilt': ('gleichungen_umformen',
        'Klammert den Faktor aus, lässt das zweite Glied aber unverändert in der Klammer: 4x + 8 = 4(x + 8).',
        'Beim Ausklammern wird jedes Glied durch den ausgeklammerten Faktor geteilt. Wer das zweite Glied stehen '
        'lässt, bekommt beim Ausmultiplizieren nicht mehr den Ausgangsterm zurück. Geübt wird die Probe durch '
        'Ausmultiplizieren.'),
    'ausklammern_falsch_geteilt': ('gleichungen_umformen',
        'Klammert den richtigen Faktor aus, teilt das zweite Glied aber durch eine andere Zahl: 6x + 12 = 6(x + 4).',
        'Vor der Klammer steht ein Faktor, in der Klammer muss jedes Glied durch genau diesen Faktor geteilt sein. Wer '
        'das zweite Glied durch eine andere Zahl teilt, etwa durch die Hälfte, bekommt beim Ausmultiplizieren einen '
        'anderen Term. Geübt wird die Probe durch Ausmultiplizieren.'),
}

# Ausklammern: (id, Aufgabenterm a·x + b, richtige Option (id, Text), {Ablenker-id: (Text, Slug, Fehlerweg)})
# Fehlerwege: nicht_ggt = Teiler t < ggT; nicht_geteilt = ggT(… x + b); falsch_geteilt = ggT(… x + b/t) mit t ≠ ggT.
AK = [
    ('4baeeda9-3985-4a80-8fd0-ecf8bbcfd6af', (4, 8), ('d', '4(x + 2)'), {
        'a': ('2(2x + 4)', 'ausklammern_nicht_ggt', ('teiler', 2)),
        'b': ('4(x + 8)', 'ausklammern_glied_nicht_geteilt', ('ungeteilt', 4)),
        'c': ('4(x + 4)', 'ausklammern_falsch_geteilt', ('falsch', 4, 2))}),
    ('65841bd8-ee27-454f-b2a4-ea6f1bb0db33', (6, 12), ('c', '6(x + 2)'), {
        'a': ('6(x + 12)', 'ausklammern_glied_nicht_geteilt', ('ungeteilt', 6)),
        'b': ('6(x + 4)', 'ausklammern_falsch_geteilt', ('falsch', 6, 3)),
        'd': ('3(2x + 4)', 'ausklammern_nicht_ggt', ('teiler', 3))}),
    ('81f97d0e-1e95-4bbd-bc6a-d05149786c58', (4, 20), ('b', '4(x + 5)'), {
        'a': ('4(x + 10)', 'ausklammern_falsch_geteilt', ('falsch', 4, 2)),
        'c': ('2(2x + 10)', 'ausklammern_nicht_ggt', ('teiler', 2)),
        'd': ('4(x + 20)', 'ausklammern_glied_nicht_geteilt', ('ungeteilt', 4))}),
    ('b15b6be0-1b87-477d-bd88-23b095501581', (9, 27), ('a', '9(x + 3)'), {
        'b': ('3(3x + 9)', 'ausklammern_nicht_ggt', ('teiler', 3)),
        'c': ('9(x + 27)', 'ausklammern_glied_nicht_geteilt', ('ungeteilt', 9)),
        'd': ('9(x + 9)', 'ausklammern_falsch_geteilt', ('falsch', 9, 3))}),
    ('ea237a07-681d-4680-bcd0-d94316c899e9', (8, 12), ('d', '4(2x + 3)'), {
        'a': ('2(4x + 6)', 'ausklammern_nicht_ggt', ('teiler', 2)),
        'b': ('4(2x + 12)', 'ausklammern_glied_nicht_geteilt', ('ungeteilt', 4)),
        'c': ('4(2x + 6)', 'ausklammern_falsch_geteilt', ('falsch', 4, 2))}),
    ('02b24419-d7e8-40b8-8b74-ef3b4e806b3f', (12, 18), ('c', '6(2x + 3)'), {
        'a': ('6(2x + 18)', 'ausklammern_glied_nicht_geteilt', ('ungeteilt', 6)),
        'b': ('6(2x + 6)', 'ausklammern_falsch_geteilt', ('falsch', 6, 3)),
        'd': ('3(4x + 6)', 'ausklammern_nicht_ggt', ('teiler', 3))}),
]


def koeff(a):
    return '' if a == 1 else str(a)


def ak_aufgabe(a, b):
    return f'{a}x + {b}'


def ak_loesung(a, b):
    g = gcd(a, b)
    return (f'Der größte gemeinsame Teiler von {a} und {b} ist {g}.\n'
            f'{a}x + {b} = {g} · {koeff(a // g)}x + {g} · {b // g} = {g}({koeff(a // g)}x + {b // g}).')


def ak_fehlerweg(a, b, w):
    if w[0] == 'teiler':
        t = w[1]
        return f'{t}({koeff(a // t)}x + {b // t})'
    if w[0] == 'ungeteilt':
        t = w[1]
        return f'{t}({koeff(a // t)}x + {b})'
    t, falsch = w[1], w[2]
    return f'{t}({koeff(a // t)}x + {b // falsch})'


def gl_loesung(weg):
    return '\n'.join(weg) + '.'


def pruefe():
    fehler = 0
    print('== Gleichungen ==')
    for tid, knoten, gl, ca, weg in GL:
        ziel = loesungen(gl)
        ok = ziel == {term(ca)}
        zeilen = [z.split('|')[0].strip() for z in weg]
        for i, z in enumerate(zeilen):
            ok &= loesungen(z) == ziel
            if '|' in weg[i]:
                op = weg[i].split('|')[1].strip().replace('−', '-')
                l, r = z.split('=')
                nl, nr = zeilen[i + 1].split('=')
                ok &= expand(term(f'({l}){op}') - term(nl)) == 0 and expand(term(f'({r}){op}') - term(nr)) == 0
        ok &= zeilen[-1].replace(' ', '') == f'x={ca}'
        print(f'{knoten:24} {tid[:8]} {gl:14} -> x = {ca}: {"ok" if ok else "ABWEICHUNG"}   '
              f'{gl_loesung(weg)!r}')
        fehler += not ok
    print('== Ausklammern ==')
    for tid, (a, b), (rid, rtext), abl in AK:
        t = term(ak_aufgabe(a, b))
        g = gcd(a, b)
        lsg = ak_loesung(a, b)
        kette = lsg.split('\n')[1].rstrip('.').split('=')
        ok = all(expand(term(k) - t) == 0 for k in kette) and kette[-1].strip() == rtext
        ok &= expand(term(rtext) - t) == 0 and rtext.startswith(f'{g}(')
        print(f'term_ausklammern         {tid[:8]} {ak_aufgabe(a, b):8} ggT {g}, richtig {rid} {rtext!r}: '
              f'{"ok" if ok else "ABWEICHUNG"}   {lsg!r}')
        fehler += not ok
        for oid, (text, slug, weg) in abl.items():
            ok_m = ak_fehlerweg(a, b, weg) == text
            ok_n = expand(term(text) - t) != 0 or (slug == 'ausklammern_nicht_ggt' and not text.startswith(f'{g}('))
            print(f'{"":24} {"":8} {oid} {text!r:13} -> {slug}: Fehlerweg {"ok" if ok_m else "ABWEICHUNG"}, '
                  f'{"falsch bzw. nicht vollständig" if ok_n else "WÄRE RICHTIG"}')
            fehler += (not ok_m) + (not ok_n)
    print(f'== {len(GL)} Gleichungen, {len(AK)} Ausklammer-Aufgaben mit {sum(len(a[3]) for a in AK)} Ablenkern, '
          f'{fehler} Abweichung(en) ==')
    return fehler


def q(s):
    return "'" + s.replace("'", "''") + "'"


def j(o):
    return q(json.dumps(o, ensure_ascii=False, separators=(',', ':'))) + '::jsonb'


def sql():
    loes = [(tid, gl_loesung(weg), None, None) for tid, _, _, _, weg in GL]
    loes += [(tid, ak_loesung(a, b), {'canonical': rid, 'known_errors': {o: s for o, (_, s, _) in abl.items()}},
              {o: t for o, (t, _, _) in abl.items()} | {rid: rtext}) for tid, (a, b), (rid, rtext), abl in AK]
    werte = ',\n'.join(f'  ({q(t)}::uuid, {q(l)}, {j(a) if a else "null::jsonb"}, {j(o) if o else "null::jsonb"})'
                       for t, l, a, o in loes)
    slugs = ',\n'.join(f'  ({q(s)}, {q(f)}, {q(k)},\n   {q(e)})' for s, (f, k, e) in NEUE_SLUGS.items())
    marke = {'art': 'neu', 'grund': 'Nachgerechnet (tools/session-e3-rechencheck.py, sympy).',
             'charge': 'session-e3-ml', 'sicher': 'hoch'}
    return f"""-- Session E3: Musterlösungen für gleichung_einschrittig (6), gleichung_zweischrittig (6) und term_ausklammern (6),
-- dazu acceptance mit einem Fehlbild je Ablenker für term_ausklammern. Erzeugt von tools/session-e3-rechencheck.py
-- (dort Rechen-Check mit sympy) — nicht von Hand editieren.
--
-- Nur leere Felder: solution nur, wenn leer; acceptance nur, wenn NULL (term_ausklammern hat keine). Hinweise bleiben
-- unberührt, status bleibt draft. tasks.vorbefuellt bekommt den Schlüssel solution, wenn er fehlt.
-- Bei term_ausklammern wird nur geschrieben, wenn die Optionen noch die Texte tragen, gegen die gerechnet wurde, und
-- correct_answers die richtige Option ist.
-- Neue Slugs ({', '.join(NEUE_SLUGS)}) mit Klartext, nicht freigegeben.
-- Fehlen die Aufgaben (CI-Neuaufbau), passiert nichts. Kein begin/commit: mig klammert mit psql -1.

insert into public.fehlbild_labels (slug, familie, klartext, erklaerung)
values
{slugs}
on conflict (slug) do nothing;

do $session_e3$
declare
  v_l integer; v_a integer; v_v integer;
begin
  create temp table e3_neu (task_id uuid, loesung text, acc jsonb, texte jsonb) on commit drop;
  insert into e3_neu values
{werte};

  -- Nur Aufgaben, deren Optionen (bei MC) und richtige Antwort noch zum Rechen-Check passen.
  delete from e3_neu n
   where n.texte is not null
     and not exists (select 1 from public.tasks t join public.task_solutions s on s.task_id = t.id
                      where t.id = n.task_id and s.correct_answers = jsonb_build_array(n.acc ->> 'canonical')
                        and not exists (select 1 from jsonb_each_text(n.texte) e
                                         where not exists (select 1 from jsonb_array_elements(t.question_payload -> 'options') o
                                                            where o ->> 'id' = e.key and o ->> 'label' = e.value)));

  update public.task_solutions s set solution = n.loesung
    from e3_neu n where s.task_id = n.task_id and nullif(btrim(coalesce(s.solution, '')), '') is null;
  get diagnostics v_l = row_count;
  update public.task_solutions s set acceptance = n.acc
    from e3_neu n where s.task_id = n.task_id and n.acc is not null and s.acceptance is null;
  get diagnostics v_a = row_count;
  update public.tasks t set vorbefuellt = t.vorbefuellt || jsonb_build_object('solution', {j(marke)})
    from e3_neu n where t.id = n.task_id and not (t.vorbefuellt ? 'solution')
     and exists (select 1 from public.task_solutions s where s.task_id = t.id and s.solution = n.loesung);
  get diagnostics v_v = row_count;
  raise notice 'session_e3: % Musterloesung(en), % acceptance, % vorbefuellt-Marke(n)', v_l, v_a, v_v;
end $session_e3$;
"""


if __name__ == '__main__':
    f = pruefe()
    if '--sql' in sys.argv:
        if f:
            sys.exit('Abweichungen, keine Migration geschrieben')
        open(sys.argv[sys.argv.index('--sql') + 1], 'w').write(sql())
    sys.exit(1 if f else 0)
