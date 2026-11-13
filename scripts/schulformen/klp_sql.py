#!/usr/bin/env python3
"""SF-1 S2: schreibt den Datenteil von 20261113153241_sf1_klp_themenplan.sql.

Eingaben (docs/schulformen/sf1/quellen/):
  klp_themen.csv     Themen je KLP-Fassung, Schulform, Doppeljahrgang und Kurs mit Fundstelle (Lehrplannavigator)
  g9_klassen.csv     häufigste Klasse je Thema unter den Gymnasien mit Plan (dbread 13.11.2026)
  skill_sperren.csv  Skills, die eine Schulform/ein Kurs nicht verlangt, mit Fundstelle

Reihenfolge innerhalb eines Doppeljahrgangs: wie am Gymnasium üblich (Klasse, dann mittlere Position im Schulplan).
Sekundarschule: Für die Sekundarschule gilt derselbe KLP wie für die Gesamtschule (KLP GE/SK 2022; bis ZP10 2027
KLP GE 2004, docs/msa/quellen/README.md c), daher dieselben Zeilen mit schulform 'Sekundarschule'.
Aufruf: python3 scripts/schulformen/klp_sql.py  (schreibt die Migration in place, ab der Marke „4 · Daten“).
"""
import csv
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
Q = ROOT / 'docs/schulformen/sf1/quellen'
MIG = ROOT / 'supabase/migrations/20261113153241_sf1_klp_themenplan.sql'
MARKE = '-- 4 · Daten (generiert) ---------------------------------------------------------\n'


def lies(name):
    with open(Q / name, encoding='utf-8') as f:
        return list(csv.DictReader(line for line in f if not line.startswith('#')))


def q(s):
    return 'null' if s is None or s == '' else "'" + s.replace("'", "''") + "'"


g9 = {r['thema_key']: r for r in lies('g9_klassen.csv')}
ordnung = {k: (int(r['klasse']), float(r['pos']), k) for k, r in g9.items()}

zeilen = []  # (schulform, fassung, dj, kurs, thema_key, nur_teil, fundstelle)
for k, r in g9.items():
    kl = int(r['klasse'])
    if 7 <= kl <= 10:
        fund = (f"schul_themenplan: häufigste Klasse unter den Gymnasien mit Plan ({r['schulen']} Schulen; "
                f"Verteilung {r['verteilung']}), dbread 13.11.2026")
        zeilen.append(('Gymnasium', 'g9', str(kl), 'alle', k, None, fund))

klp = lies('klp_themen.csv')
for r in klp:
    if r['thema_key'] not in ordnung:
        raise SystemExit(f"unbekanntes Thema {r['thema_key']}")
    fund = f"{r['datei']} S. {r['gedruckte_seite']} (PDF-S. {r['pdf_seite']}): „{r['zitat']}“"
    formen = [r['schulform']] + (['Sekundarschule'] if r['schulform'] == 'Gesamtschule' else [])
    for sf in formen:
        zeilen.append((sf, r['fassung'], r['doppeljahrgang'], r['kurs'], r['thema_key'], r['nur_teil'] or None, fund))

# position je (schulform, fassung, dj) nach der Ordnung am Gymnasium; gleiche Themen in E- und alle-Zeilen gleich
pos = {}
for gruppe in sorted({z[:3] for z in zeilen}):
    themen = sorted({z[4] for z in zeilen if z[:3] == gruppe}, key=lambda t: ordnung[t])
    for i, t in enumerate(themen, 1):
        pos[gruppe + (t,)] = i

sql = ['insert into public.klp_themenplan (fach, schulform, klp_fassung, doppeljahrgang, kurs, position, thema_key, nur_teil, fundstelle)',
       'values']
werte = []
for z in sorted(zeilen, key=lambda z: (z[0], z[1], z[2], pos[z[:3] + (z[4],)], z[3])):
    werte.append(f"  ('mathematik', {q(z[0])}, {q(z[1])}, {q(z[2])}, {q(z[3])}, {pos[z[:3] + (z[4],)]}, "
                 f"{q(z[4])}, {q(z[5])}, {q(z[6])})")
sql.append(',\n'.join(werte) + ';')

sperren = [(r['skill_key'], sf, r['kurs'], r['klp_fassung'], r['fundstelle'])
           for r in lies('skill_sperren.csv') for sf in r['schulformen'].split('|')]
sql += ['', 'insert into public.skill_schulform (skill_key, schulform, kurs, klp_fassung, zulaessig, fundstelle)', 'values']
sql.append(',\n'.join(f"  ({q(a)}, {q(b)}, {q(c)}, {q(d)}, false, {q(e)})"
                      for a, b, c, d, e in sorted(sperren, key=lambda r: (r[1], r[2], r[3], r[0]))) + ';')

text = MIG.read_text(encoding='utf-8')
MIG.write_text(text[:text.index(MARKE) + len(MARKE)] + '\n'.join(sql) + '\n', encoding='utf-8')
print(f'{len(werte)} Zeilen klp_themenplan, {len(sperren)} Sperren')
