# Screening-Items — Ableitungs-Analyse (READ-ONLY)

Erzeugt von `scripts/analyze-screening-derivation.ts` · **keine** DB-Mutation.
Gesamt: **299** screening_items.

## 1. aufgabe_typ-Verteilung

| aufgabe_typ | Anzahl | mit akzeptierte_antworten | mit loesung_pro_ta |
|---|--:|--:|--:|
| `mehrteilig` | 127 | 126 | 127 |
| `∅` | 81 | 0 | 0 |
| `kurzantwort` | 31 | 31 | 31 |
| `mc_single` | 29 | 29 | 29 |
| `offen` | 17 | 17 | 17 |
| `mc_multi` | 6 | 6 | 6 |
| `zuordnung` | 4 | 4 | 4 |
| `lueckentext` | 3 | 3 | 3 |
| `unvollstaendig` | 1 | 0 | 1 |

## 2. Kategorie-Counts

| Kategorie | Anzahl | Anteil |
|---|--:|--:|
| AUTO_SHORT_TEXT | 14 | 4.7% |
| RUBRIK_FREE_TEXT | 30 | 10.0% |
| COORDINATE_FLAG | 4 | 1.3% |
| OTHER_TYPE | 170 | 56.9% |
| NO_KEY | 81 | 27.1% |

### OTHER_TYPE nach Subtyp

| aufgabe_typ → Vorschlag | Anzahl |
|---|--:|
| mehrteilig → FREE_TEXT | 127 |
| mc_single → MC | 29 |
| mc_multi → MC | 6 |
| zuordnung → MATCHING | 4 |
| lueckentext → CLOZE | 3 |
| unvollstaendig → FREE_TEXT | 1 |

## 3. Stichproben (je Kategorie, akzeptierte_antworten zur Prüfung)

### AUTO_SHORT_TEXT (14)

| item_id | Vorschlag | akzeptierte_antworten / Grund |
|---|---|---|
| `1b9cbabd` | SHORT_TEXT | ["5,1"] |
| `2afcb042` | SHORT_TEXT | ["16 m","0,016 km","160 dm","1600 cm"] |
| `cda2b3ca` | SHORT_TEXT | ["4","vier","4 ungefärbte Flächen"] |
| `235b5913` | SHORT_TEXT | ["1,25","1,25 Euro","€ 1,25","1.25 Euro"] |
| `9a52f2fe` | SHORT_TEXT | ["10/20","1/2","0,5","50%","50 Prozent"] |
| `b5dd001f` | SHORT_TEXT | ["22","ca. 22","22 mm","2,2 cm","22 Millimeter"] |
| `a538074b` | SHORT_TEXT | ["x = 20","20"] |
| `75bbfd96` | SHORT_TEXT | ["5","fünf","5 Ecken"] |
| `537a2b22` | SHORT_TEXT | ["15","15 cm²","15 Quadratcentimeter"] |
| `a075b552` | SHORT_TEXT | ["x = -10","-10","x=-10"] |
| `84280807` | SHORT_TEXT | ["280 ml","280","280 Milliliter"] |
| `153cef6c` | SHORT_TEXT | ["500 000","500000","fünfhunderttausend","Fünfhunderttausend"] |
| `e5f100d9` | SHORT_TEXT | ["32 cm²","32","32 cm2"] |
| `81a6bd50` | SHORT_TEXT | ["30 Euro","30€","€30","30"] |

### RUBRIK_FREE_TEXT (30)

| item_id | Vorschlag | akzeptierte_antworten / Grund |
|---|---|---|
| `e8868ea8` | FREE_TEXT | ["Rechnerischer Vergleich: 19.900 € × 0,88 × 1,19 = 20.839,28 € (korrekt) vs. 19.900 € × 1… |
| `d9e0add8` | FREE_TEXT | ["Rechteck mit gegebener Strecke als Basis und drei zusätzlichen Seiten im rechten Winkel"… |
| `33daade5` | FREE_TEXT | ["Gerade durch Mittelpunkte zweier gegenüberliegender Seiten","Parallele zur kurzen Seite … |
| `82cdd621` | FREE_TEXT | ["Die Aufwendungen sind in 5 Jahren um etwa 5 Mrd. € gestiegen (ca. 1 Mrd. € pro Jahr). Im… |
| `c12ff813` | FREE_TEXT | ["weiß-rot, weiß-blau, weiß-grün, rot-blau, rot-grün, blau-grün","wr, wb, wg, rb, rg, bg",… |
| `bfdf20c0` | FREE_TEXT | ["6","3 × 2 × 1 = 6","3! = 6"] |
| `30e923ae` | FREE_TEXT | ["Summe aller Kantenlängen","4(a + b + c) für Quader","12·a für Würfel","Numerische Lösung… |
| `f02c7c63` | FREE_TEXT | ["1:1:3","rote : blaue : gelbe = 1 : 1 : 3","1 Teil rot, 1 Teil blau, 3 Teile gelb","Verhä… |
| `c3e2bd36` | FREE_TEXT | ["10%","10 Prozent","10","0,50 € / 5,00 € = 0,1 = 10%"] |
| `58c1861e` | FREE_TEXT | ["Alle Netze, bei denen die zwei fehlenden Flächen an topologisch korrekten Positionen ang… |
| `5f04b4ec` | FREE_TEXT | ["x = 2","2","Die Lösung ist 2"] |
| `f3e54281` | FREE_TEXT | ["Münzwurf ist wahrscheinlicher","Kopf ist wahrscheinlicher als Sechs","Die Wahrscheinlich… |
| `4532fcba` | FREE_TEXT | ["Ganzzahlige Antworten aus dem Intervall [70; 80]","Ganzzahlige Antworten aus dem Interva… |
| `4c5f9482` | FREE_TEXT | ["Raute durch Spiegelung des Dreiecks an einer Seite konstruiert","Raute durch Parallelver… |
| `fc476ee8` | FREE_TEXT | ["Etwa 38 m (wenn Kopfhöhe 25 cm und Körpergröße 1,60 m als Referenz)","Etwa 30 m (wenn ha… |

### COORDINATE_FLAG (4)

| item_id | Vorschlag | akzeptierte_antworten / Grund |
|---|---|---|
| `92da9690` | FREE_TEXT ⚑COORDINATE | ["Beide Geraden haben die Steigung 4. Sie sind also parallel.","Beide Geraden haben diesel… |
| `de4eceb2` | FREE_TEXT ⚑COORDINATE | ["Punkt korrekt eingetragen mit Beschriftung","Punkt korrekt eingetragen ohne Beschriftung… |
| `3ecc1ddf` | FREE_TEXT ⚑COORDINATE | ["Punkt mit Beschriftung eingezeichnet","Punkt ohne Beschriftung eingezeichnet"] |
| `7bf049ba` | FREE_TEXT ⚑COORDINATE | ["Gerade mit steilerer Steigung als die erste Gerade","Gerade, die unter einem größeren Wi… |

### OTHER_TYPE (170)

| item_id | Vorschlag | akzeptierte_antworten / Grund |
|---|---|---|
| `84e18b36` | FREE_TEXT ⚑OTHER_TYPE_UNBUILDABLE | ["1/24","1:24","0,0417","4,17%","≈4%","1/18","1:18","0,0556","5,56%","≈5,6%","1","100%","g… |
| `70463a7b` | FREE_TEXT ⚑OTHER_TYPE_UNBUILDABLE | ["9","neun Nullen","3. Antwortalternative","1000000","1.000.000","1 Million","1 Mio.","100… |
| `03e2327c` | FREE_TEXT ⚑OTHER_TYPE_UNBUILDABLE | ["5","5,0","Alle Punktzahlen im Bereich [89; 91)","x = 90","89","90","90,5","Note = (Punkt… |
| `a76aa68a` | MATCHING ⚑OTHER_TYPE_UNBUILDABLE | ["A","D","B"] |
| `40faaa13` | FREE_TEXT ⚑OTHER_TYPE_UNBUILDABLE | ["α = 45°, γ = 90°","β = 180° - 3·α","β = 180 - 3α","β = 180 - α - 2α","β = 180° - α - 2α"… |
| `8479390c` | FREE_TEXT ⚑OTHER_TYPE_UNBUILDABLE | ["26 Frauen und 43 Männer","69 Fahrräder insgesamt","Es sind 26 Fahrräder von Frauen und 4… |
| `1cd0c49c` | FREE_TEXT ⚑OTHER_TYPE_UNBUILDABLE | ["Schüler des Bistros befragen","Informationen zu Vorlieben/Gewohnheiten sammeln","Stichpr… |
| `be735971` | FREE_TEXT ⚑OTHER_TYPE_UNBUILDABLE | ["30","30%","0,3 → 30%","0,8","8/10","80/100"] |
| `4961b20c` | FREE_TEXT ⚑OTHER_TYPE_UNBUILDABLE | ["6,80","6.80 Euro","6,80€","Kästchen 3","Die dritte Option","y = 0,09x + 4,99 (oder äquiv… |
| `2ae94335` | FREE_TEXT ⚑OTHER_TYPE_UNBUILDABLE | ["12","4 mal 3","4 × 3 = 12","2 Wechselringe und 6 Wechselarmbänder, 3 Wechselringe und 4 … |
| `d0b4151f` | FREE_TEXT ⚑OTHER_TYPE_UNBUILDABLE | ["12 Würfel","12","3. Kästchen","Option 3","Kästchen drei"] |
| `e4d11f56` | FREE_TEXT ⚑OTHER_TYPE_UNBUILDABLE | ["Korrekte Anwendung des Dreisatzes auf proportionalen Zusammenhang","Korrekte Erkennung u… |
| `7f85dcaf` | FREE_TEXT ⚑OTHER_TYPE_UNBUILDABLE | ["Numerisch korrekte Lösung mit gültiger Begründung durch Pfadregel","Baumdiagramm mit kor… |
| `96eda407` | MC ⚑OTHER_TYPE_UNBUILDABLE | ["0,0612","Antwort 3","Kästchen 3"] |
| `d54c3739` | FREE_TEXT ⚑OTHER_TYPE_UNBUILDABLE | ["Korrekte Bruchdarstellung mit korrektem Prozentsatz","Nenner = Gesamtzahl gleich großer … |

### NO_KEY (81)

| item_id | Vorschlag | akzeptierte_antworten / Grund |
|---|---|---|
| `cffaa1c8` | FREE_TEXT | _(kein akzeptierte_antworten und kein verwertbares loesung_pro_ta)_ |
| `c41cafc2` | FREE_TEXT | _(kein akzeptierte_antworten und kein verwertbares loesung_pro_ta)_ |
| `8bf1148a` | FREE_TEXT | _(kein akzeptierte_antworten und kein verwertbares loesung_pro_ta)_ |
| `ce59e3df` | FREE_TEXT | _(kein akzeptierte_antworten und kein verwertbares loesung_pro_ta)_ |
| `51fedf9f` | FREE_TEXT | _(kein akzeptierte_antworten und kein verwertbares loesung_pro_ta)_ |
| `d38f743a` | FREE_TEXT | _(kein akzeptierte_antworten und kein verwertbares loesung_pro_ta)_ |
| `b2f08873` | FREE_TEXT | _(kein akzeptierte_antworten und kein verwertbares loesung_pro_ta)_ |
| `9f0950d4` | FREE_TEXT | _(kein akzeptierte_antworten und kein verwertbares loesung_pro_ta)_ |
| `bbe39a75` | FREE_TEXT | _(kein akzeptierte_antworten und kein verwertbares loesung_pro_ta)_ |
| `9966caeb` | FREE_TEXT | _(kein akzeptierte_antworten und kein verwertbares loesung_pro_ta)_ |
| `be3891ae` | FREE_TEXT | _(kein akzeptierte_antworten und kein verwertbares loesung_pro_ta)_ |
| `ccbe787c` | FREE_TEXT | _(kein akzeptierte_antworten und kein verwertbares loesung_pro_ta)_ |
| `932c9096` | FREE_TEXT | _(kein akzeptierte_antworten und kein verwertbares loesung_pro_ta)_ |
| `90d69515` | FREE_TEXT | _(kein akzeptierte_antworten und kein verwertbares loesung_pro_ta)_ |
| `c1efb9ad` | FREE_TEXT | _(kein akzeptierte_antworten und kein verwertbares loesung_pro_ta)_ |

## 4. Fazit

- **Auto-prüfbar nach Anwendung (Screening-Pool):** 14 Items
  (AUTO_SHORT_TEXT + sicher baubare OTHER_TYPE wie TRUE_FALSE).
- **Bleibt coach-bewertet (FREE_TEXT):** 285 Items.
- **Lena-Review nötig:** COORDINATE_FLAG = 4, OTHER_TYPE-unbaubar = 170.

> Vorschlag ist konservativ: im Zweifel FREE_TEXT/Lena-Flag statt falsch auto.
> Apply-Migration erst nach Prüfung durch Rasit/Lena.
