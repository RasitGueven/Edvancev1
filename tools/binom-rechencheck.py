#!/usr/bin/env python3
"""Binomische Formeln (Stufe 3): Fehlbild je MC-Ablenker und zwei offene Aufgaben — Rechen-Check und Migration.

    PYTHONPATH=<sympy> python3 tools/binom-rechencheck.py            # nur rechnen, Exit 1 bei Abweichung
    PYTHONPATH=<sympy> python3 tools/binom-rechencheck.py --sql F    # zusätzlich Migration nach F schreiben

Je Ablenker steht hier, welcher falsche Rechenweg ihn erzeugt (`modell`). Geprüft wird mit sympy:
  1. die richtige Option ist gleich dem Aufgabenterm,
  2. der Ablenker ist NICHT gleich dem Aufgabenterm,
  3. der modellierte Fehlerweg ergibt genau den Ablenker (ausmultipliziert gleich).
Für die neuen NUMERIC-Aufgaben: Ergebnis, jedes known_error-Modell und die letzte Zahl der Musterlösung.
Die Options-Texte sind gegen Prod (dbread, 16.10.2026) abgeschrieben; die Wegwerf-DB-Prüfung gleicht sie erneut ab.
"""
import json
import re
import sys

from sympy import Rational, expand, symbols
from sympy.parsing.sympy_parser import (convert_xor, implicit_multiplication_application, parse_expr,
                                        standard_transformations)

x = symbols('x')
TR = standard_transformations + (implicit_multiplication_application, convert_xor)
HOCH = {'²': '**2', '³': '**3', '⁴': '**4'}


def term(s):
    s = s.replace('−', '-').replace('·', '*')
    for k, v in HOCH.items():
        s = s.replace(k, v)
    return parse_expr(s, transformations=TR, local_dict={'x': x})


def gleich(a, b):
    return expand(term(a) if isinstance(a, str) else a) == expand(term(b) if isinstance(b, str) else b)


# Neue Slugs (Klartext + Erklärung). Alle übrigen Zuordnungen nutzen vorhandene Slugs mit Klartext.
NEUE_SLUGS = {
    'binom_formel_verwechselt': ('gleichungen_umformen',
        'Verwechselt die binomischen Formeln, etwa (a − b)² statt (a + b)² oder (a + b)(a − b) statt (a + b)².',
        'Die drei binomischen Formeln unterscheiden sich nur in den Vorzeichen. Wer sie verwechselt, bekommt beim '
        'Mischglied 2ab das falsche Vorzeichen oder lässt es ganz weg. Geübt wird, vor dem Rechnen zu bestimmen, '
        'welche der drei Formen vorliegt.'),
    'mischglieder_nicht_aufgehoben': ('gleichungen_umformen',
        'Multipliziert (a + b)(a − b) aus, lässt die Mischglieder aber stehen, statt dass sie sich aufheben: '
        '(x + 4)(x − 4) = x² − 8x − 16.',
        'Beim Ausmultiplizieren von (a + b)(a − b) entstehen +ab und −ab; zusammen ergeben sie null. Wer beide '
        'Mischglieder mit Minus schreibt oder nur eines streicht, behält ein x-Glied, das nicht dorthin gehört. '
        'Geübt wird, alle vier Teilprodukte hinzuschreiben und erst dann zusammenzufassen.'),
    'faktor_nicht_quadriert': ('potenzen_wurzeln',
        'Quadriert bei (2x)² nur das x, nicht den Faktor davor: 2x² statt 4x².',
        'Das Quadrat einer Klammer wie (2x) betrifft jeden Faktor darin: (2x)² = 2² · x² = 4x². Wer nur x '
        'quadriert, behält den Faktor 2 statt 4. Geübt wird, den Faktor vor dem x beim Quadrieren mitzunehmen.'),
}

# MC-Ablenker ohne Fehlbild. modell = falscher Rechenweg, der den Ablenker erzeugt.
# (id, Knoten, Aufgabenterm, richtige Option (id, Text), {Ablenker-id: (Text, Slug, modell)})
MC = [
    ('18dbb731-98be-4b90-a8c2-5773114de6c6', 'term_binom_faktorisieren', '3x² + 12x + 12', ('c', '3(x + 2)²'), {
        'b': ('3(x + 4)²', 'halbieren_vergessen', 3 * (x + Rational(12, 3)) ** 2),             # 4 statt 4/2 in die Klammer
        'd': ('(3x + 6)²', 'klammer_falsch_gesetzt', (3 * (x + 2)) ** 2)}),                     # Faktor 3 in die Klammer gezogen
    ('9be9bb9c-a5b5-482e-bd76-51599553d61b', 'term_binom_faktorisieren', 'x² - 25', ('a', '(x + 5)(x - 5)'), {
        'd': ('(x + 25)(x - 1)', 'wurzel_vergessen', (x + 25) * (x - 1))}),                     # 25 statt √25 = 5 (unscharf)
    ('9d904128-a0ae-449c-b7de-e1c57c8238c5', 'term_binom_faktorisieren', 'x⁴ - 16', ('b', '(x² + 4)(x + 2)(x - 2)'), {
        'c': ('(x² - 4)(x² - 4)', 'quadratdifferenz_vorzeichen', (x**2 - 4) ** 2),             # beide Klammern mit Minus
        'd': ('(x + 2)⁴', 'wurzel_gliedweise', (x + 16 ** Rational(1, 4)) ** 4)}),              # ⁴√x⁴ und ⁴√16 einzeln
    ('b2bc0cfc-d927-4a29-aca4-4686606d9466', 'term_binom_faktorisieren', 'x² + 8x + 16', ('b', '(x + 4)²'), {
        'c': ('(x + 16)²', 'wurzel_vergessen', (x + 16) ** 2),                                  # b = 16 statt √16
        'd': ('(x + 4)(x - 4)', 'binom_formel_verwechselt', (x + 4) * (x - 4))}),               # 3. statt 1. Formel
    ('e4a18d51-9545-4f17-b1aa-10dc72c35cd3', 'term_binom_faktorisieren', '2x² - 18', ('b', '2(x + 3)(x - 3)'), {
        'd': ('(2x + 3)(2x - 3)', 'klammer_falsch_gesetzt', (2 * x + 3) * (2 * x - 3))}),       # Faktor 2 an jedes x
    ('1c519bed-37b4-4322-9668-849b4756efcf', 'term_binom_gemischt', '(x + 4)² - x² - 16', ('b', '8x'), {
        'c': ('8x + 32', 'falsches_vorzeichen_beim_zusammenfuehren', x**2 + 8*x + 16 - x**2 + 16),
        'd': ('8x - 32', 'falsches_vorzeichen_beim_zusammenfuehren', x**2 + 8*x - 16 - x**2 - 16)}),  # unscharf
    ('79c7a940-7a41-4b6b-b4ff-ce464425c758', 'term_binom_gemischt', '(x + 6)(x - 6) + (x + 2)²', ('b', '2x² + 4x - 32'), {
        'c': ('2x² - 32', 'quadrat_gliedweise', x**2 - 36 + x**2 + 4),
        'd': ('2x² + 4x - 40', 'falsches_vorzeichen_beim_zusammenfuehren', x**2 - 36 + x**2 + 4*x - 4)}),
    ('b7ac3c73-91eb-4a9c-9d9e-4d9f3790b261', 'term_binom_gemischt', '(x + 5)² - (x + 2)(x - 2)', ('a', '10x + 29'), {
        'd': ('2x² + 10x + 21', 'vorzeichen_ignoriert', (x + 5) ** 2 + (x**2 - 4))}),
    ('c31fdbb1-9a48-4cd8-9b0c-35393af84330', 'term_binom_gemischt', '(x + 3)² - (x - 3)²', ('c', '12x'), {
        'd': ('2x² + 18', 'vorzeichen_ignoriert', (x + 3) ** 2 + (x - 3) ** 2)}),
    ('dd4db5a2-2e96-4a93-b1c0-fca052b144ca', 'term_binom_gemischt', '(3x - 2)² - (x + 4)(x - 4)', ('a', '8x² - 12x + 20'), {
        'c': ('10x² - 12x + 20', 'klammer_vergessen', 9*x**2 - 12*x + 4 + x**2 + 16),          # Minus nur auf −16
        'd': ('8x² - 12x - 20', 'falsches_vorzeichen_beim_zusammenfuehren', 9*x**2 - 12*x - 4 - x**2 - 16)}),  # unscharf
    ('f8364853-03fa-4d7e-807c-b0a20dbe09e3', 'term_binom_gemischt', '(x + 3)² - (x - 1)²', ('b', '8x + 8'), {
        'c': ('4x + 8', 'binom_formel_verwechselt', (x + 3) ** 2 - (x + 1) ** 2),               # (x − 1)² als (x + 1)²
        'd': ('2x² + 8x + 8', 'klammer_vergessen', x**2 + 6*x + 9 + x**2 + 2*x - 1)}),          # Minus nicht auf x²
    ('513d03bd-0d8d-4f0a-9e99-ea63b38b8587', 'term_binom_quadrat', '(x + 4)²', ('a', 'x² + 8x + 16'), {
        'c': ('4x + 16', 'umfang_statt_flaeche', 4 * (x + 4)),
        'd': ('x² + 4x + 16', 'mal_zwei_vergessen', x**2 + 4*x + 16)}),
    ('9a598424-963b-4981-91ad-9a81cead51f4', 'term_binom_quadrat', '(x - 5)²', ('b', 'x² - 10x + 25'), {
        'd': ('x² - 10x - 25', 'vorzeichen_potenz', x**2 - 10*x - 5**2)}),                      # (−5)² als −25
    ('ae6fa0b8-283c-4570-b9d2-6271c17e3384', 'term_binom_quadrat', '(x + 3)²', ('c', 'x² + 6x + 9'), {
        'b': ('x² + 3x + 9', 'mal_zwei_vergessen', x**2 + 3*x + 9),
        'd': ('x² + 6x + 6', 'mal_exponent', x**2 + 6*x + 3 * 2)}),                             # 3² als 3 · 2
    ('de60d4ff-c473-4358-b050-85a54dd903a1', 'term_binom_quadrat', '(2x + 3)²', ('a', '4x² + 12x + 9'), {
        'c': ('2x² + 12x + 9', 'faktor_nicht_quadriert', 2*x**2 + 12*x + 9),
        'd': ('4x² + 6x + 9', 'mal_zwei_vergessen', 4*x**2 + 2*x*3 + 9)}),
    ('ebd05f6f-2ab0-41ad-bac3-16c075fc2592', 'term_binom_quadrat', '(3x - 4)²', ('d', '9x² - 24x + 16'), {
        'c': ('9x² - 24x - 16', 'vorzeichen_potenz', 9*x**2 - 24*x - 4**2)}),
    ('f54b2f2c-5c0e-46ae-bd6c-00acc3efa4fa', 'term_binom_quadrat', 'x² + 20x + 100', ('b', '(x + 10)²'), {
        'c': ('(x + 100)²', 'wurzel_vergessen', (x + 100) ** 2),
        'd': ('(x + 10)(x - 10)', 'binom_formel_verwechselt', (x + 10) * (x - 10))}),
    ('113aea0a-276a-4042-b634-805ef1e11db2', 'term_binom_quadratdifferenz', '(x + 5)(x - 5)', ('c', 'x² - 25'), {
        'd': ('x² - 10x - 25', 'mischglieder_nicht_aufgehoben', x**2 - 5*x - 5*x - 25)}),
    ('293413f8-8e31-4f0b-b64e-7ac2a183606e', 'term_binom_quadratdifferenz', '(x + 4)(x - 4)', ('a', 'x² - 16'), {
        'c': ('x² - 8x - 16', 'mischglieder_nicht_aufgehoben', x**2 - 4*x - 4*x - 16),
        'd': ('x² - 4x - 16', 'mischglieder_nicht_aufgehoben', x**2 - 4*x - 16)}),               # nur ein Mischglied
    ('94492e5a-3627-4f45-b628-41d06114a7a4', 'term_binom_quadratdifferenz', '(3x + 5)(3x - 5)', ('a', '9x² - 25'), {
        'c': ('3x² - 25', 'faktor_nicht_quadriert', 3*x**2 - 25),
        'd': ('9x² - 30x - 25', 'mischglieder_nicht_aufgehoben', 9*x**2 - 15*x - 15*x - 25)}),
    ('d47b8793-7e82-4036-9173-d446c554b907', 'term_binom_quadratdifferenz', '(2x - 9)(2x + 9)', ('d', '4x² - 81'), {
        'a': ('4x² - 36x - 81', 'mischglieder_nicht_aufgehoben', 4*x**2 - 18*x - 18*x - 81),
        'c': ('2x² - 81', 'faktor_nicht_quadriert', 2*x**2 - 81)}),
    ('eb3f28da-155b-49fc-aa17-1abfd882a373', 'term_binom_quadratdifferenz', '(x - 7)(x + 7)', ('c', 'x² - 49'), {
        'b': ('x² - 14x + 49', 'binom_formel_verwechselt', (x - 7) ** 2),
        'd': ('x² - 14x - 49', 'mischglieder_nicht_aufgehoben', x**2 - 7*x - 7*x - 49)}),
]

# Unscharfe Zuordnungen: Slug passt nur ungefähr, im Bericht ausgewiesen.
UNSCHARF = {('9be9bb9c-a5b5-482e-bd76-51599553d61b', 'd'), ('1c519bed-37b4-4322-9668-849b4756efcf', 'd'),
            ('dd4db5a2-2e96-4a93-b1c0-fca052b144ca', 'd')}

# Neue offene Aufgaben (NUMERIC, Muster: binom-faktor-06 / binom-quadratdiff-05, Felder wie fkt_linear_*).
NEU = [
    dict(id='3b1e6f0a-5c2d-4e8b-9f71-2a6d0c4b8e13', skill='term_binom_quadrat', ref='binom-quadrat-07',
         titel='Zweite binomische Formel · geschicktes Rechnen · 49²',
         frage='Berechne geschickt mit einer binomischen Formel.\n\n49² = ?',
         wert=49**2, richtig=['2401'],
         loesung='49² = (50 - 1)² = 50² - 2 · 50 · 1 + 1² = 2500 - 100 + 1 = 2401.',
         fehler=[  # (Wert, Slug, Modell, Fehlerbeschreibung, sokratische Frage)
             ('2499', 'quadrat_gliedweise', 50**2 - 1**2, 'Gliedweise quadriert, das Mischglied fehlt: 50² - 1² = 2499.',
              'Ist (50 - 1)² dasselbe wie 50² - 1²? Probiere es mit (3 - 1)² aus.'),
             ('2501', 'quadrat_gliedweise', 50**2 + 1**2, 'Gliedweise quadriert, das Mischglied fehlt: 50² + 1² = 2501.',
              'Ist (50 - 1)² dasselbe wie 50² + 1²? Probiere es mit (3 - 1)² aus.'),
             ('2451', 'mal_zwei_vergessen', 50**2 - 50 * 1 + 1, 'Mischglied ohne Faktor 2: 2500 - 50 + 1 = 2451.',
              'Wie heißt das mittlere Glied in (a - b)² = a² - … + b²?'),
             ('2399', 'vorzeichen_potenz', 50**2 - 100 - 1**2, 'Das letzte Glied mit Minus: 2500 - 100 - 1 = 2399.',
              'Kann ein Quadrat wie (-1)² negativ sein?'),
             ('2601', 'binom_formel_verwechselt', (50 + 1) ** 2, 'Erste statt zweiter Formel: 2500 + 100 + 1 = 2601.',
              'Ist 49² größer oder kleiner als 50²?'),
         ],
         grund_afb='Anwenden: Quadratzahl als (50 - 1)² zerlegen und mit der zweiten binomischen Formel rechnen.'),
    dict(id='8c4a2d71-0e9b-4f36-b5a8-6d1f3e7c9a24', skill='term_binom_gemischt', ref='binom-gemischt-07',
         titel='Binomische Formeln gemischt · vereinfachen und einsetzen · x = 100',
         frage='Vereinfache den Term zuerst mit den binomischen Formeln und setze dann x = 100 ein.\n\n'
               '(x + 5)² - (x + 2)(x - 2) = ?',
         wert=(term('(x + 5)² - (x + 2)(x - 2)')).subs(x, 100), richtig=['1029'],
         loesung='(x + 5)² = x² + 10x + 25\n(x + 2)(x - 2) = x² - 4\n'
                 'x² + 10x + 25 - (x² - 4) = 10x + 29\nFür x = 100: 10 · 100 + 29 = 1029.',
         fehler=[
             ('1021', 'quadratdifferenz_vorzeichen', (10 * x + 21).subs(x, 100),
              'Die Klammer x² - 4 mit falschem Vorzeichen abgezogen: 10x + 21, also 1021.',
              'Was ergibt -(x² - 4), wenn du die Klammer auflöst?'),
             ('29', 'quadrat_gliedweise', (x**2 + 25 - (x**2 - 4)).subs(x, 100),
              'Gliedweise quadriert: (x + 5)² = x² + 25, übrig bleibt 29.',
              'Ist (x + 5)² dasselbe wie x² + 25? Setze x = 1 ein und vergleiche.'),
             ('21021', 'vorzeichen_ignoriert', ((x + 5) ** 2 + (x**2 - 4)).subs(x, 100),
              'Das Minus vor dem zweiten Produkt weggelassen: 2x² + 10x + 21, also 21021.',
              'Welches Rechenzeichen steht zwischen den beiden Produkten?'),
         ],
         grund_afb='Anwenden: erste und dritte binomische Formel kombinieren, Minus vor der Klammer, dann einsetzen.'),
]
LEER_GRUND = 'Auftrag Binom/Session 16.10.2026: offene Aufgabe für die LSA, ohne Hinweise.'


def letzte_zahl(loesung):
    rest = re.match(r'.*[=≈](.*)$', loesung, re.S).group(1)
    return re.findall(r'[-+−–]?\s?[0-9]+(?:[.,][0-9]+)?', rest)[-1].strip()


def pruefe():
    fehler = 0
    print('== MC-Ablenker ==')
    for tid, knoten, aufgabe, (rid, rtext), abl in MC:
        ok_r = gleich(rtext, aufgabe)
        print(f'{knoten:28} {tid[:8]} richtig {rid} {rtext!r}: {"ok" if ok_r else "ABWEICHUNG"}')
        fehler += not ok_r
        for oid, (text, slug, modell) in abl.items():
            ok_n = not gleich(text, aufgabe)
            ok_m = gleich(text, modell)
            u = ' (unscharf)' if (tid, oid) in UNSCHARF else ''
            print(f'{"":28} {"":8} {oid} {text!r:22} -> {slug}{u}: '
                  f'{"ungleich Aufgabe" if ok_n else "GLEICH AUFGABE"}, Modell {"ok" if ok_m else "ABWEICHUNG"}')
            fehler += (not ok_n) + (not ok_m)
    print('== Neue Aufgaben ==')
    for a in NEU:
        ok = str(a['wert']) == a['richtig'][0] and letzte_zahl(a['loesung']) == a['richtig'][0]
        print(f"{a['skill']:28} {a['ref']}: Ergebnis {a['wert']}, Musterlösung endet {letzte_zahl(a['loesung'])}: "
              f"{'ok' if ok else 'ABWEICHUNG'}")
        fehler += not ok
        for wert, slug, modell, _, _ in a['fehler']:
            ok = str(modell) == wert and wert not in a['richtig']
            print(f"{'':28} {wert:>6} -> {slug}: Modell {modell} {'ok' if ok else 'ABWEICHUNG'}")
            fehler += not ok
    n = sum(len(m[4]) for m in MC)
    print(f'== {n} Ablenker, {len(NEU)} neue Aufgaben, {fehler} Abweichung(en) ==')
    return fehler


def q(s):
    return "'" + s.replace("'", "''") + "'"


def j(o):
    return q(json.dumps(o, ensure_ascii=False, separators=(',', ':'))) + '::jsonb'


def sql():
    zeilen = []
    for tid, knoten, _, _, abl in MC:
        zeilen.append(f"  ({q(tid)}::uuid, {j({o: s for o, (_, s, _) in abl.items()})}, "
                      f"{j({o: t for o, (t, _, _) in abl.items()})})")
    slugs = ',\n'.join(f'  ({q(s)}, {q(f)}, {q(k)},\n   {q(e)})' for s, (f, k, e) in NEUE_SLUGS.items())
    out = [f"""-- Binomische Formeln (Stufe 3): Fehlbild je MC-Ablenker, je eine offene Aufgabe für term_binom_gemischt und
-- term_binom_quadrat. Erzeugt von tools/binom-rechencheck.py (dort Rechen-Check mit sympy) — nicht von Hand editieren.
--
-- Mechanismus: pruef_auffaelligkeiten meldet mc_ablenker_ohne_fehlbild für jede Option, deren id weder in
-- correct_answers noch als Schlüssel in acceptance.known_errors steht. Hier werden die fehlenden Options-ids als
-- Schlüssel ergänzt ({{Options-id: Slug}}), vorhandene Schlüssel bleiben unverändert (neu || alt, alt gewinnt).
-- Ergänzt wird nur, wenn die Option noch den Text trägt, gegen den gerechnet wurde.
--
-- Neue Slugs ({', '.join(NEUE_SLUGS)}) mit Klartext, nicht freigegeben.
-- Neue Aufgaben: status draft, pruef_pilot, einsatz lsa, ohne Hinweise. Lösung über task_solution_upsert als
-- Systemaufruf (transaktionslokal). Fehlen Knoten oder Aufgaben (CI-Neuaufbau), passiert nichts.
-- Kein begin/commit: mig klammert mit psql -1.

insert into public.fehlbild_labels (slug, familie, klartext, erklaerung)
values
{slugs}
on conflict (slug) do nothing;

do $binom_a$
declare
  v_n integer;
begin
  with neu(task_id, ke, texte) as (values
{','.join(chr(10) + z for z in zeilen).lstrip(chr(10))}
  ), passt as (
    select n.task_id, n.ke
      from neu n join public.tasks t on t.id = n.task_id
     where not exists (select 1 from jsonb_each_text(n.texte) e
                        where not exists (select 1 from jsonb_array_elements(t.question_payload -> 'options') o
                                           where o ->> 'id' = e.key and o ->> 'label' = e.value)))
  update public.task_solutions s
     set acceptance = jsonb_set(s.acceptance, '{{known_errors}}',
                                p.ke || coalesce(s.acceptance -> 'known_errors', '{{}}'::jsonb))
    from passt p
   where s.task_id = p.task_id
     and jsonb_typeof(s.acceptance) = 'object'
     and exists (select 1 from jsonb_object_keys(p.ke) k where not coalesce(s.acceptance -> 'known_errors' ? k, false));
  get diagnostics v_n = row_count;
  raise notice 'binom_a: known_errors in % Aufgabe(n) ergaenzt', v_n;
end $binom_a$;
"""]
    for a in NEU:
        ke = {}
        for wert, slug, _, _, _ in a['fehler']:
            ke[wert] = slug
        acc = {'canonical': a['richtig'][0], 'known_errors': ke}
        te = [{'error': e, 'fehlbild': s, 'socratic_question': f} for _, s, _, e, f in a['fehler']]
        vb = {
            'afb': {'art': 'neu', 'grund': a['grund_afb'], 'charge': 'binom-session', 'sicher': 'mittel'},
            'solution': {'art': 'neu', 'grund': 'Nachgerechnet (tools/binom-rechencheck.py, sympy).',
                         'charge': 'binom-session', 'sicher': 'hoch'},
            'correct_answers': {'art': 'neu', 'grund': 'Nachgerechnet; ganze Zahl ohne Vorzeichenvarianten.',
                                'charge': 'binom-session', 'sicher': 'hoch'},
            'typical_errors': {'art': 'neu', 'grund': 'Aus acceptance.known_errors, je Wert ein Fehlerweg.',
                               'charge': 'binom-session', 'sicher': 'hoch'},
            'hints': {'art': 'leer', 'grund': LEER_GRUND, 'charge': 'binom-session'},
            'est_duration_sec': {'art': 'neu', 'grund': 'Zeitregel: AFB II, kein Sachkontext.',
                                 'charge': 'binom-session', 'sicher': 'mittel'},
        }
        payload = {'kind': 'short_input', 'prompt': a['frage']}
        out.append(f"""-- {a['ref']} · {a['titel']}
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, estimated_minutes, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, einsatz, pruef_pilot, vorbefuellt, vorbefuellt_am)
select {q(a['id'])}::uuid, 'exercise', {q(a['titel'])}, {q(a['frage'])}, {j(payload)}, 'NUMERIC', {q(a['skill'])},
  8, 8, (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Problemlösen, Operieren',
  60, 3, null, false, null, 'draft', 'edvance_k8_binom', {q(a['ref'])},
  false, true, false, false, '[]'::jsonb, '[]'::jsonb, array['lsa'], true, {j(vb)}, now()
 where exists (select 1 from public.tasks t where t.skill_key = {q(a['skill'])} and t.source = 'edvance_k8_binom')
on conflict do nothing;

do $neu$
begin
  if exists (select 1 from public.tasks t where t.id = {q(a['id'])}::uuid and t.status = 'draft')
     and not exists (select 1 from public.task_solutions s where s.task_id = {q(a['id'])}::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
      p_task_id         => {q(a['id'])}::uuid,
      p_correct_answers => {j(a['richtig'])},
      p_solution        => {q(a['loesung'])},
      p_hints           => '[]'::jsonb,
      p_coach_hints     => '[]'::jsonb,
      p_typical_errors  => {j(te)},
      p_beleg           => null,
      p_acceptance      => {j(acc)},
      p_option_scores   => null);
    raise notice 'binom_a: neue Aufgabe {a['ref']} angelegt';
  end if;
end $neu$;
""")
    return '\n'.join(out)


if __name__ == '__main__':
    f = pruefe()
    if '--sql' in sys.argv:
        if f:
            sys.exit('Abweichungen, keine Migration geschrieben')
        open(sys.argv[sys.argv.index('--sql') + 1], 'w').write(sql())
    sys.exit(1 if f else 0)
