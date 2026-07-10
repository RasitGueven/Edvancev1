import json, csv, uuid
from collections import Counter

wrap = json.load(open('vera8_komplett.json'))
data = wrap['aufgaben']

LEITIDEE_TO_INHALTSFELD = {
    'Zahl': 'arithmetik_algebra', 'Messen': 'geometrie', 'Raum und Form': 'geometrie',
    'Funktionaler Zusammenhang': 'funktionen', 'Daten und Zufall': 'stochastik',
}
K_TO_NRW = {'K1':'arg','K2':'pro','K3':'mod','K4':'kom','K5':'ope','K6':'kom'}
TYP_TO_TASKTYPE = {
    'kurzantwort':'SHORT_INPUT','mehrteilig':'MULTI_PART','zuordnung':'MATCHING',
    'offen':'FREE_TEXT','lueckentext':'CLOZE','mc_single':'MULTIPLE_CHOICE','mc_multi':'MULTIPLE_SELECT',
}

enriched, review_rows = [], []
for it in data:
    problems = []
    l_ids = [s.strip() for s in (it.get('leitidee_raw') or '').split(',') if s.strip()]
    fields = sorted({LEITIDEE_TO_INHALTSFELD[l] for l in l_ids if l in LEITIDEE_TO_INHALTSFELD})
    unknown_l = [l for l in l_ids if l not in LEITIDEE_TO_INHALTSFELD]
    if unknown_l: problems.append(f'Leitidee unbekannt: {unknown_l}')
    if not fields: problems.append('kein Inhaltsfeld ableitbar')

    komp, komp_pro_ta = set(), []
    for ta in (it.get('teilaufgaben') or []):
        ks = sorted({K_TO_NRW[k] for k in (ta.get('allgemeine_kompetenzen') or []) if k in K_TO_NRW})
        komp_pro_ta.append({'nr': ta.get('nr'),'kompetenzen': ks,'afb': ta.get('afb'),
                            'kompetenzstufe': ta.get('kompetenzstufe'),'phase_empfehlung': ta.get('phase_empfehlung')})
        komp.update(ks)
    komp = sorted(komp)
    if not komp: problems.append('keine Prozesskompetenz (K-Tags fehlen)')

    task_type = TYP_TO_TASKTYPE.get(it.get('aufgabe_typ'))
    text_ok = bool(it.get('aufgabe_text_clean'))
    answers = it.get('akzeptierte_antworten') or []
    if not text_ok:
        src = (it.get('urls') or {}).get('aufgabe') or '?'
        reason = 'ALT-DOC (Konverter noetig)' if it.get('datei_ext')=='doc' else 'DOCX-Scrapefehler'
        problems.append(f'Text fehlt [{reason}]: {src}')
    if not answers: problems.append('keine akzeptierten Antworten')
    if not task_type: problems.append('task_type nicht ableitbar (aufgabe_typ leer/unvollstaendig)')

    afbs = [ta.get('afb') for ta in (it.get('teilaufgaben') or []) if ta.get('afb')]
    status = 'ready' if not problems else 'incomplete'
    e = {
        'id': str(uuid.uuid5(uuid.NAMESPACE_URL, 'edvance/vera8/' + (it.get('iqb_titel') or ''))),
        'titel': it.get('iqb_titel'), 'quelle': 'VERA8_IQB',
        'lizenz_status': 'UNGEKLAERT — quelle_lizenz=IQB_KLAEREN, NICHT produktiv nutzen bis geklaert',
        'klasse': it.get('klasse'), 'status': status, 'is_diagnostic': True,
        'task_type': task_type,
        'edvance_matrix': {'inhaltsfelder': fields,'prozesskompetenzen': komp,
                           'afb_max': max(afbs) if afbs else it.get('afb_ki'),
                           'schwierigkeit': (it.get('meta') or {}).get('schwierigkeit')},
        'aufgabe_text': it.get('aufgabe_text_clean'), 'kontext': it.get('kontext'),
        'akzeptierte_antworten': answers or None, 'teilaufgaben': komp_pro_ta,
        'loesung_pro_ta': it.get('loesung_pro_ta'),
        'diagnostik': {'typische_fehler': (it.get('kommentar_highlights') or {}).get('typische_fehler'),
                       'kodierung': it.get('kodierung')},
        'iqb_urls': it.get('urls'),
        '_derivation': {'matrix':'auto (Leitidee->Inhaltsfeld, K1-K6->NRW)','task_type':'auto (aufgabe_typ)',
                        'review_durch_lena_erforderlich': True},
        '_problems': problems,
    }
    enriched.append(e)
    review_rows.append({'titel': e['titel'],'status': status,'inhaltsfelder':'|'.join(fields),
        'kompetenzen':'|'.join(komp),'task_type': task_type or '?',
        'afb_max': e['edvance_matrix']['afb_max'] or '?','text':'ja' if text_ok else 'FEHLT',
        'probleme':'; '.join(problems)})

json.dump(enriched, open('vera8_komplett_enriched.json','w'), ensure_ascii=False, indent=1)
with open('vera8_komplett_review_lena.csv','w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=list(review_rows[0].keys())); w.writeheader(); w.writerows(review_rows)

ready=[e for e in enriched if e['status']=='ready']
print(f"GESAMT: {len(enriched)} | ready (sofort spielbar): {len(ready)} | incomplete: {len(enriched)-len(ready)}")
print()
def matrix(items,label):
    cells=Counter()
    for e in items:
        for f_ in e['edvance_matrix']['inhaltsfelder']:
            for k in e['edvance_matrix']['prozesskompetenzen']: cells[(f_,k)]+=1
    felder=['arithmetik_algebra','funktionen','geometrie','stochastik']; komps=['ope','mod','pro','arg','kom','wkz']
    print(f"Matrix-Abdeckung — {label}:")
    print(f"{'':22}"+''.join(f"{k:>6}" for k in komps))
    for f_ in felder: print(f"{f_:22}"+''.join(f"{cells.get((f_,k),0):>6}" for k in komps))
    print()
matrix(enriched,'ALLE 299')
matrix(ready,f'nur READY ({len(ready)})')
print("Task-Type-Verteilung (ready):", dict(Counter(e['task_type'] for e in ready)))
