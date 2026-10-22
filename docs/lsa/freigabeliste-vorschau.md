# Freigabeliste Vorschau (LSA-V)

Für Lena und Rasit. Stand Prod 22.10.2026 (dbread, nur lesend).

**Wofür:** Die LSA mit Thema prüft nach dem Thema die Voraussetzungen der zwei nächsten Plan-Themen
(Vorschau, docs/lsa/Bauauftrag-LSA-V.md). Ein Kind mit echtem Konto bekommt nur freigegebene Aufgaben
(`ready`). Fehlen sie, überspringt die Vorschau den Bereich, und die LSA endet früher. Testkonto B
(Sitzung 6220b7e8, Klasse 9, Reelle Zahlen) endet mit dem echten Pool schon nach 7 Aufgaben bei Minute 7:30
(docs/lsa/lsa-v-simulation.md).

**Beispiel:** FWG, Klasse 9, nach Reelle Zahlen. Die zwei nächsten Plan-Themen sind
1. Quadratische Funktionen
2. Kreise, Prismen und Zylinder

**Regel** (aus der Freigabeliste für Lena): Ein Bereich braucht mindestens 2 freigegebene Aufgaben, davon
mindestens eine ohne Multiple Choice.

**Spalten:**
- **Art:** „Rand“ kommt immer dran. „tiefer“ kommt nur, wenn der Bereich darüber nicht trägt.
- **Thema:** das kommende Thema, zu dem der Bereich gehört; „beide“ heißt, er ist Voraussetzung beider Themen.
  Diese Bereiche kommen zuerst.
- **ready:** freigegeben und im LSA-Pool.
- **Entwurf:** status `draft`.

| Bereich (Skill) | Art | Thema | Klasse | ready | ready ohne MC | Entwurf | reicht |
|---|---|---|---:|---:|---:|---:|---|
| term_einsetzen | Rand | beide | 7 | 0 | 0 | 6 | **nein** |
| geo_koordinaten | Rand | Quadratische Funktionen | 6 | 0 | 0 | 6 | **nein** |
| gleichung_modellieren | Rand | Quadratische Funktionen | 8 | 0 | 0 | 10 | **nein** |
| gleichung_zweischrittig | Rand | Quadratische Funktionen | 7 | 0 | 0 | 6 | **nein** |
| term_binom_quadrat | Rand | Quadratische Funktionen | 8 | 0 | 0 | 7 | **nein** |
| zahl_wurzel_quadrat | Rand | Quadratische Funktionen | 9 | 5 | 5 | 0 | ja |
| dezimal_div | Rand | Kreise, Prismen und Zylinder | 6 | 0 | 0 | 9 | **nein** |
| geo_flaeche_dreieck | Rand | Kreise, Prismen und Zylinder | 7 | 0 | 0 | 9 | **nein** |
| geo_flaeche_rechteck | Rand | Kreise, Prismen und Zylinder | 5 | 0 | 0 | 6 | **nein** |
| geo_umfang | Rand | Kreise, Prismen und Zylinder | 5 | 0 | 0 | 6 | **nein** |
| groessen_flaechen | Rand | Kreise, Prismen und Zylinder | 6 | 0 | 0 | 11 | **nein** |
| potenzen | Rand | Kreise, Prismen und Zylinder | 7 | 18 | 18 | 6 | ja |
| proportionalitaet | Rand | Kreise, Prismen und Zylinder | 7 | 0 | 0 | 17 | **nein** |
| runden_ueberschlag | Rand | Kreise, Prismen und Zylinder | 5 | 10 | 10 | 3 | ja |
| dezimal_add_sub | tiefer | Quadratische Funktionen | 5 | 0 | 0 | 11 | **nein** |
| dezimal_mult | tiefer | Quadratische Funktionen | 6 | 0 | 0 | 9 | **nein** |
| gleichung_beidseitig | tiefer | Quadratische Funktionen | 7 | 0 | 0 | 7 | **nein** |
| gleichung_einschrittig | tiefer | Quadratische Funktionen | 7 | 0 | 0 | 6 | **nein** |
| term_ausmultiplizieren | tiefer | Quadratische Funktionen | 7 | 0 | 0 | 7 | **nein** |
| term_zusammenfassen | tiefer | Quadratische Funktionen | 7 | 0 | 0 | 7 | **nein** |
| vorzeichen_add_sub | tiefer | Quadratische Funktionen | 7 | 7 | 7 | 0 | ja |
| vorzeichen_mult_div | tiefer | Quadratische Funktionen | 7 | 7 | 7 | 0 | ja |
| vorzeichen_vorrang | tiefer | Quadratische Funktionen | 7 | 1 | 1 | 8 | **nein** |
| groessen_laengen | tiefer | Kreise, Prismen und Zylinder | 5 | 0 | 0 | 9 | **nein** |

**Ergebnis:** 5 von 24 Bereichen reichen. Am dringendsten sind die Randbereiche von Quadratische Funktionen:
term_einsetzen (für beide Themen), gleichung_modellieren, gleichung_zweischrittig, term_binom_quadrat und
geo_koordinaten. Alle liegen nur im Entwurf vor.

Neu erzeugen: Kandidaten wie in lsa_select_next_core (Rand der kommenden Themen, Ersetzung durch den eigenen
Rand bei Themen, die noch kommen, Klasse ≤ 9). Zahlen je Skill: `lsa_im_pool(id, false)`, davon `input_type <> 'MC'`,
`status = 'draft'`.
