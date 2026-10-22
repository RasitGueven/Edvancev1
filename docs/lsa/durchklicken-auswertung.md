# LSA-R Schritt 1: Durchklicken erkennen, Auswertung

Stand 22.10.2026. Bauauftrag: `docs/lsa/Bauauftrag-LSA-R.md`. Die Daten stammen aus Prod und wurden nur lesend
über `dbread` abgefragt. Es gab kein DDL und keine Code-Änderung. Der Bericht nennt keine Namen, IDs oder
Zeitstempel. Testkinder heißen wie im Generator (erfundene Namen), die übrigen Läufe werden durchnummeriert.

## 0. Wichtigster Befund vorab

**In Prod gibt es keine einzige LSA eines echten Kindes.** Alle 31 Sitzungen mit Antworten gehören zu einem
Testkonto (`students.ist_test`) oder zu einem Testlauf (`lsa_sessions.testlauf`). Die Frage „wie viele Fehlalarme
bei echten Kindern“ lässt sich deshalb **nicht messen**. Die Auswertung nimmt als Ersatz drei Gruppen:

| Gruppe | Abgeschlossen | Was es ist | Aussagekraft für Zeiten |
|---|---|---|---|
| Testkinder (Lina, Emre, Sophie, Jonas, Nele, Max) | 6 | `tools/lsa-testkinder/erzeugen.sql` | **keine**: Die Dauer ist fest gesetzt (35–110 s × Muster 0,75–1,3; bei `nicht_angesetzt` halbiert), mindestens 26 s |
| Testkonto, von Hand geklickt (H1–H21) | 21 | Team und Erwachsene probieren die LSA aus | echte menschliche Zeiten, aber von Erwachsenen und teils bewusst schnell |
| Testlauf | 2 | T1 (normal), **K = die Klick-LSA** | K ist der Anlass |

Dazu kommen 9 abgebrochene Testkonto-Sitzungen und 2 laufende Testläufe. Sie fehlen in den Tabellen 1 und 3.

**Die Klick-LSA K** ist der Testlauf vom 21.10. mit den meisten Aufgaben: **135 Aufgaben** (147 Antwortzeilen
mit Teilaufgaben) in 18,4 Minuten, 11 richtig, 122 falsch, 2 „Weiß ich nicht“, Median 2,8 s. Im Bauauftrag stehen
70 Aufgaben. Nach etwa 7 Minuten war K bei Aufgabe 75 (siehe 4). Vermutlich stammt die Zahl 70 von dort, oder
der Report zeigt etwas anderes (Frage 1 unten). K ist ein **Testlauf**, kein normaler Testkonto-Lauf. Das Konto
ist trotzdem ein Testkonto.

### Zählweise

- Eine **Antwort** ist eine abgegebene Aufgabe. Bei Multi-Part zählt die Aufgabe einmal, nicht jede Teilaufgabe;
  `duration_ms` steht in allen Teilzeilen gleich.
- **richtig**: Alle beantworteten Teile sind richtig. **falsch**: mindestens ein Teil ist falsch.
  **Weiß ich nicht** (WN): `abgabeart = 'weiss_nicht'`. „leer“ kam nicht vor.
- **schnell falsch** (sf) bei *s* Sekunden: falsch und `duration_ms < s·1000`. WN zählt nicht als falsch und
  unterbricht eine Folge.
- Die Reihenfolge ergibt sich aus der Abgabezeit der Antwort.

## 1. Je abgeschlossene LSA

Zeiten in Sekunden als p10 / Median / p90, in Klammern die Zahl der Antworten. „sf %“ ist der Anteil schnell
falscher Antworten an allen Antworten, „Folge“ die längste Folge schnell falscher Antworten, jeweils bei 5 | 8 | 12 s.

| Lauf | Aufg. | richtig | falsch | Weiß ich nicht | sf % 5 \| 8 \| 12 | Folge 5 \| 8 \| 12 |
|---|---:|---|---|---|---|---|
| Lina | 18 | 31,0/41,0/51,0 (16) | 36,8/40,0/43,2 (2) | – | 0 \| 0 \| 0 | 0 \| 0 \| 0 |
| Emre | 19 | 46,2/60,0/75,0 (15) | 49,8/64,5/77,1 (4) | – | 0 \| 0 \| 0 | 0 \| 0 \| 0 |
| Sophie | 14 | 67,2/80,0/83,2 (3) | 64,0/88,0/104,0 (11) | – | 0 \| 0 \| 0 | 0 \| 0 \| 0 |
| Jonas | 16 | – | 85,3/107,3/132,0 (6) | 43,7/56,4/69,0 (10) | 0 \| 0 \| 0 | 0 \| 0 \| 0 |
| Nele | 10 | 60,2/71,8/83,3 (4) | 57,8/73,5/89,3 (6) | – | 0 \| 0 \| 0 | 0 \| 0 \| 0 |
| Max | 8 | 27,5/35,9/44,3 (8) | – | – | 0 \| 0 \| 0 | 0 \| 0 \| 0 |
| H1 | 7 | 9,6/13,7/14,4 (3) | 12,4/20,6/30,6 (4) | – | 0 \| 0 \| 14 | 0 \| 0 \| 1 |
| H2 | 7 | 7,5/9,4/13,1 (4) | 5,3/5,9/8,8 (3) | – | 0 \| 29 \| 43 | 0 \| 2 \| 3 |
| H3 | 8 | 5,6/7,7/18,9 (6) | 6,0/10,9/15,8 (2) | – | 13 \| 13 \| 13 | 1 \| 1 \| 1 |
| H4 | 7 | 5,3/7,7/8,3 (3) | 8,7/13,8/36,3 (4) | – | 0 \| 14 \| 14 | 0 \| 1 \| 1 |
| H5 | 7 | 4,8/6,7/8,7 (2) | 5,1 (1) | 5,2/52,5/101,0 (4) | 0 \| 14 \| 14 | 0 \| 1 \| 1 |
| H6 | 8 | 3,6/7,5/19,1 (7) | 3,0 (1) | – | 13 \| 13 \| 13 | 1 \| 1 \| 1 |
| H7 | 7 | 3,0/4,2/5,4 (2) | 2,3/3,1/10,9 (5) | – | 43 \| 57 \| 57 | 2 \| 4 \| 4 |
| H8 | 7 | – | – | 0,8/1,0/1504 (7) | 0 \| 0 \| 0 | 0 \| 0 \| 0 |
| H9 | 8 | – | 1,8/6,3/47,3 (4) | 0,8/1,1/1,8 (4) | 25 \| 25 \| 38 | 2 \| 2 \| 2 |
| H10 | 35 | 5,5/11,0/23,5 (10) | 4,3/19,2/52,3 (11) | 0,7/1,4/2,4 (14) | 6 \| 6 \| 11 | 1 \| 1 \| 2 |
| H11 | 24 | 5,6/11,5/19,7 (19) | 8,3/14,3/24,4 (5) | – | 0 \| 4 \| 8 | 0 \| 1 \| 1 |
| H12 | 4 | 20,2 (1) | 11,1/19,3/27,5 (2) | 2,6 (1) | 0 \| 0 \| 25 | 0 \| 0 \| 1 |
| H13 | 24 | 5,0/14,2/30,4 (17) | 7,0/24,5/77,7 (5) | 2,1/2,5/2,9 (2) | 0 \| 8 \| 8 | 0 \| 1 \| 1 |
| H14 | 25 | 10,9/19,5/107,2 (12) | 10,3/35,8/74,8 (13) | – | 0 \| 8 \| 8 | 0 \| 1 \| 1 |
| H15 | 14 | 19,4/35,6/138,2 (8) | 43,3/102,4/119,9 (4) | 84,9/88,2/91,5 (2) | 0 \| 0 \| 0 | 0 \| 0 \| 0 |
| H16 | 43 | 6,5/23,4/56,6 (13) | 5,5/11,9/32,1 (30) | – | 5 \| 12 \| 35 | 1 \| 1 \| 4 |
| H17 | 17 | 27,1/52,5/77,3 (6) | 16,3/45,3/132,2 (11) | – | 0 \| 0 \| 0 | 0 \| 0 \| 0 |
| H18 | 32 | 4,1/8,5/20,4 (16) | 6,9/11,2/18,4 (12) | 4,3/5,8/7,7 (4) | 0 \| 6 \| 22 | 0 \| 1 \| 2 |
| H19 | 3 | 17,4 (1) | – | 1,2/2,2/3,2 (2) | 0 \| 0 \| 0 | 0 \| 0 \| 0 |
| H20 | 19 | 12,4/22,0/75,4 (7) | 26,5/36,0/121,5 (9) | 12,3/15,2/124,9 (3) | 0 \| 0 \| 0 | 0 \| 0 \| 0 |
| H21 | 11 | 55,0 (3) | 55,0 (8) | – | 0 \| 0 \| 0 | 0 \| 0 \| 0 |
| T1 | 22 | 16,3/45,7/71,6 (6) | 17,1/56,9/126,8 (11) | 5,2/11,7/27,3 (5) | 0 \| 0 \| 0 | 0 \| 0 \| 0 |
| **K** | **135** | 2,7/3,3/8,1 (11) | 1,7/2,8/8,3 (122) | 6,0/6,1/6,3 (2) | **75 \| 80 \| 88** | **15 \| 17 \| 39** |

Auffällig:

- H21 hat immer genau 55,0 s. Das sieht nach einem Skriptlauf aus, nicht nach einem Menschen.
- H8 hat siebenmal WN in etwa 1 s, eine Aufgabe blieb rund 25 Minuten offen.
- H9 und H10 drücken WN meist in 1–2 s. Das ist „Weiß ich nicht“ als Durchklick-Taste, auch das ist nicht
  mitgemacht. Die Regel unten fängt es nicht (siehe Frage 3).
- H7 hat 7 Aufgaben, 5 davon falsch in rund 3 s. Wahrscheinlich ein bewusst schneller Test. Mit unter 10
  Antworten greift die Anteilsregel nicht.

## 2. Antwortzeiten je input_type

Grundlage sind die Handläufe H1–H21 und T1 (ohne K und ohne Testkinder), weil es keine echten Kinder gibt. Die
Zahlen kommen von **Erwachsenen**. Kinder sind vermutlich langsamer, die Grenzen hier liegen also eher zu niedrig.

| input_type | Art | n | p10 | Median | p90 | Minimum | < 3 s | < 5 s | < 8 s | < 12 s |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| MC | richtig | 7 | 9,4 | 16,9 | 24,4 | 9,3 | 0 | 0 | 0 | 2 |
| MC | falsch | 11 | 6,2 | 15,4 | 35,0 | 5,3 | 0 | 0 | 3 | 5 |
| NUMERIC | richtig | 133 | 5,1 | 12,7 | 53,9 | 2,4 | 2 | 13 | 37 | 64 |
| NUMERIC | falsch | 139 | 5,0 | 16,3 | 57,1 | 1,8 | 6 | 14 | 32 | 54 |
| NUMERIC | Weiß ich nicht | 47 | 0,8 | 2,6 | 93,7 | 0,6 | 25 | 29 | 31 | 37 |
| TERM | richtig | 2 | 62,9 | 92,7 | 122,6 | 55,4 | 0 | 0 | 0 | 0 |
| TERM | falsch | 13 | 12,3 | 24,5 | 74,6 | 2,2 | 1 | 1 | 1 | 2 |
| TERM | Weiß ich nicht | 4 | 1,1 | 4,1 | 7,7 | 0,7 | 2 | 2 | 3 | 4 |
| MULTI_PART | richtig | 9 | 22,3 | 62,7 | 97,3 | 17,4 | 0 | 0 | 0 | 0 |
| MULTI_PART | falsch | 5 | 69,0 | 136,1 | 182,2 | 64,8 | 0 | 0 | 0 | 0 |

Unter welcher Zeit antwortet praktisch niemand richtig?

- **Unter 3 s**: 2 von 133 richtigen NUMERIC-Antworten, sonst keine. Unter 3 s ist richtig praktisch Zufall.
- **3 bis 5 s**: 11 weitere richtige NUMERIC-Antworten (10 % aller richtigen NUMERIC). Erwachsene schaffen leichte
  Zahlaufgaben so schnell.
- **5 bis 8 s**: Hier liegen schon 28 % der richtigen NUMERIC-Antworten. **8 s ist für Erwachsene normales Tempo
  bei leichten Aufgaben.** Ein Kind, das leichte Grundlagenaufgaben sicher kann (Phase Tiefe steigt ab!), liegt
  dort wahrscheinlich auch.
- MC, TERM und MULTI_PART wurden nie unter 5 s richtig beantwortet. Die Mengen sind aber klein.
- Zum Vergleich K: Median falsch 2,8 s, p90 8,3 s.

**Folgerung:** Raten ist ab **unter 5 s** wahrscheinlich, bei 8 s noch nicht. Eine Grenze je input_type lohnt
sich bei dieser Datenmenge nicht. Bei 5 s erfasst eine Grenze für alle Typen K genauso gut (siehe 3).

## 3. Schwelle × Regel: Was würde markiert?

„Nicht auswertbar“ bei Anteil heißt: mindestens 10 Antworten und Anteil schnell falsch ≥ *k* %. Basis sind die
abgeschlossenen LSAs: 21 Handläufe, 6 Testkinder und K.

| Schwelle | Regel | Handläufe markiert (von 21) | Testkinder markiert (von 6) | K markiert |
|---:|---|---:|---:|:---:|
| 5 s | 3 in Folge | 0 | 0 | ja |
| 5 s | 4 in Folge | 0 | 0 | ja |
| 5 s | 5 in Folge | 0 | 0 | ja |
| 5 s | ≥ 30 % | 0 | 0 | ja |
| 5 s | ≥ 40 % | 0 | 0 | ja |
| 5 s | ≥ 50 % | 0 | 0 | ja |
| 5 s | **5 in Folge ODER ≥ 40 %** | **0** | **0** | **ja** |
| 8 s | 3 in Folge | 1 (H7) | 0 | ja |
| 8 s | 4 in Folge | 1 (H7) | 0 | ja |
| 8 s | 5 in Folge | 0 | 0 | ja |
| 8 s | ≥ 30 / 40 / 50 % | 0 | 0 | ja |
| 8 s | 5 in Folge ODER ≥ 40 % (Vorschlag) | 0 | 0 | ja |
| 8 s | 4 in Folge ODER ≥ 40 % | 1 (H7) | 0 | ja |
| 12 s | 3 in Folge | 3 (H2, H7, H16) | 0 | ja |
| 12 s | 4 in Folge | 2 (H7, H16) | 0 | ja |
| 12 s | 5 in Folge | 0 | 0 | ja |
| 12 s | ≥ 30 % | 1 (H16) | 0 | ja |
| 12 s | ≥ 40 / 50 % | 0 | 0 | ja |
| 12 s | 5 in Folge ODER ≥ 30 % | 1 (H16) | 0 | ja |

- **K wird von jeder Kombination markiert**, der Abstand ist groß: 75 % schnell falsch und 15 in Folge schon bei 5 s.
- **Die Testkinder können nie markiert werden**, auch Jonas nicht, weil der Generator jede Antwort mindestens 26 s
  dauern lässt. Diese Prüfung ist erfüllt, beweist aber nichts. Ein Testkind, das die Regel wirklich prüft, fehlt
  (Vorschlag in Schritt 2).
- Der größte Wert eines Handlaufs bei 5 s ist eine Folge von 2 (H7, H9). Beim Anteil ab 10 Antworten sind es 6 %
  (H10). Bis zur Regel „5 in Folge ODER 40 %“ ist also viel Platz.
- **Nur Schnelligkeit, ohne richtig/falsch** (siehe 6, Hinweis für das Kind): 3 Abgaben (ohne WN) unter 5 s in
  Folge kommen in keinem Handlauf und keinem Testkind vor, nur in K.

## 4. Die Klick-LSA K im Detail

Zeitverlauf in Blöcken zu 15 Aufgaben. „bis Min.“ ist die aufsummierte Antwortdauer am Ende des Blocks. Die
Wanduhr lag am Ende bei 18,4 Minuten, einige Aufgaben blieben länger offen.

| Aufgaben | richtig | falsch | WN | Median s | Maximum s | sf < 5 s | sf < 8 s | Typen | bis Min. |
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|
| 1–15 | 1 | 14 | 0 | 2,6 | 11,1 | 11 | 12 | NUMERIC | 0,9 |
| 16–30 | 2 | 13 | 0 | 2,2 | 33,1 | 11 | 12 | MC, MULTI_PART, NUMERIC | 2,3 |
| 31–45 | 3 | 12 | 0 | 3,4 | 9,0 | 7 | 9 | MC, MULTI_PART, NUMERIC | 3,4 |
| 46–60 | 1 | 14 | 0 | 2,8 | 5,0 | 14 | 14 | MC, NUMERIC | 4,2 |
| 61–75 | 2 | 11 | 2 | 5,9 | 98,4 | 7 | 9 | MULTI_PART, NUMERIC, TERM | 7,0 |
| 76–90 | 0 | 15 | 0 | 2,3 | 5,3 | 14 | 15 | MULTI_PART, NUMERIC | 7,7 |
| 91–105 | 2 | 13 | 0 | 3,4 | 333,9 | 10 | 10 | MC, MULTI_PART, NUMERIC | 14,2 |
| 106–120 | 0 | 15 | 0 | 2,9 | 9,3 | 12 | 12 | MC, NUMERIC | 15,2 |
| 121–135 | 0 | 15 | 0 | 2,3 | 5,0 | 15 | 15 | NUMERIC | 15,9 |

Ab welcher Aufgabe die Regel greift:

| Schwelle | 3 in Folge | 4 in Folge | 5 in Folge | ≥ 30 % (ab 10) | ≥ 40 % (ab 10) | ≥ 50 % (ab 10) |
|---:|---:|---:|---:|---:|---:|---:|
| 5 s | Aufgabe 8 | 9 | **10** (nach 0,7 Min.) | 10 | 10 | 10 |
| 8 s | 5 | 6 | 7 (0,6 Min.) | 10 | 10 | 10 |
| 12 s | 3 | 4 | 5 (0,5 Min.) | 10 | 10 | 10 |

Bei 5 s erschiene der Hinweis an das Kind nach Aufgabe 8. Spätestens bei Aufgabe 10, nach weniger als einer
Minute, wäre die LSA als nicht auswertbar erkannt. Der Deckel von 40 hätte K nach 3,1 Minuten beendet.

## 5. Höchstzahl an Aufgaben und Deckel

Für echte Kinder gibt es keinen Wert (siehe 0). Ersatzwerte:

| Lauf | Aufgaben | aufsummierte Minuten | Aufgabe 30 nach | Aufgabe 40 nach | rechnerisch in 19 Min. beim Median-Tempo |
|---|---:|---:|---:|---:|---:|
| K | 135 | 15,9 | 2,3 Min. | 3,1 Min. | 402 |
| H16 | 43 | 14,0 | 11,6 Min. | 13,4 Min. | 89 |
| H10 | 35 | 7,4 | 6,0 Min. | – | 171 |
| H18 | 32 | 5,8 | 5,5 Min. | – | 125 |
| H14 | 25 | 19,2 | – | – | 41 |
| H11 / H13 | 24 | 5,7 / 7,8 | – | – | 97 / 84 |
| T1 | 22 | 18,1 | – | – | 29 |
| Testkinder | höchstens 19 | – | – | – | – |

- Nur ein Handlauf ist über 40 gekommen (H16, ein Erwachsener, schnell und mit 70 % falsch). Er hätte bei Aufgabe
  40 nach 13,4 Minuten geendet und dabei 3 Aufgaben verloren.
- Alle anderen Handläufe enden weit vor 40, die festen LSAs schon nach 7–8 Items.
- Ein Kind, das im Mittel länger als 28,5 s je Aufgabe braucht, kommt in 19 Minuten nicht auf 40. Bei den
  Handläufen mit sinnvollem Tempo (T1, H14, H17, H20) liegt der Median bei 20–55 s.
- **Der Deckel 40 passt.** Er schützt vor dem Fall K, auch wenn die Regel einmal versagt, und kostet ein normales
  Kind nichts. Ein höherer Wert brächte nichts, solange die Auswahl vorher von selbst endet.

## 6. Wo das Ende entsteht, wo Deckel und Markierung hingehören

### Ende der LSA heute

1. `lsa_submit` → bei `modus = 'adaptiv'` `lsa_select_next_core(session, ['ready'], p_jetzt)`.
   Dort liefert die Funktion `null`, wenn
   - die Sitzung nicht `in_progress` ist,
   - **`p_jetzt > diagnose_ab/started_at/created_at + 19 Minuten`** (die einzige Zeitgrenze),
   - die Schleife nach 100 Durchläufen oder ohne Kandidat endet.
   Bei `fest` gibt `lsa_submit` `null` zurück, wenn kein Item aus `item_ids` mehr offen ist.
2. `platz_submit` reicht `{ok, next}` unverändert an die App durch. In `edvance-app` heißt `next === null`
   „Session durch“ (`src/types/content.ts`, `src/lib/queries/lsa.ts`). Die App ruft dann `platz_finish` auf
   (`app/(student)/lsa/platz-task.tsx`).
3. `platz_finish` → `lsa_finish`. Hier entsteht `result_summary`, dann `status = 'completed'`. Das Ende steuert
   also die Auswahl, `lsa_finish` hält es nur fest.

### Deckel

**In `lsa_select_next_core`, direkt neben der 19-Minuten-Prüfung**: `return null`, wenn die Sitzung 40
ausgegebene Aufgaben hat (`lsa_ausgegeben` zählen, nicht die Antwortzeilen, weil Multi-Part mehrere Zeilen hat).
So gilt der Deckel überall, wo die Auswahl läuft (Platz, Admin-Testlauf, Testkinder), und App und `lsa_finish`
bleiben unverändert. Für `fest` braucht es keinen Deckel, `item_ids` ist dort schon begrenzt.

Optional kann die Auswahl auch sofort enden, sobald die Regel „nicht auswertbar“ zutrifft, also bei K nach
Aufgabe 10 statt erst beim Deckel (Frage 4).

### Markierung „nicht auswertbar“

**Empfehlung: eine eigene Spalte an `lsa_sessions`**, gesetzt in `lsa_finish`, zum Beispiel
`auswertbar boolean not null default true` plus `nicht_auswertbar_grund jsonb` (Schwelle, Regel, Kennzahlen).
Die Kennzahlen kommen zusätzlich in `result_summary`. Gründe:

- **Filtern und sperren**: Die Admin-Liste (`listLsaReports`), die Präsentation (`ReportPage` mit
  `?ansicht=praesentation`) und die Übernahme in den Lernpfad müssen danach entscheiden. Eine Spalte lässt sich
  per `select`/RLS/RPC direkt abfragen und in einem CHECK oder Trigger verwenden. Ein Feld in jsonb wäre überall
  eine Konvention.
- **`result_summary` ist eine Momentaufnahme** von `lsa_finish` mit festem Vertrag
  („kein Score, keine Quote“). Ein Urteil über die Gültigkeit der ganzen Sitzung gehört nicht zu den Kennzahlen.
  Will der Coach es später aufheben („trotzdem auswerten“), ist das ein Update einer Spalte, kein Umschreiben
  der Momentaufnahme.
- Alte Sitzungen bekommen über den Default `true`. Für die bestehenden Testläufe ist kein Backfill nötig.
- Für das Live-Bild während der LSA braucht es **nichts Gespeichertes**. Die Kennzahl lässt sich aus
  `lsa_responses` berechnen, am besten in einer Funktion `lsa_durchklick_stand(session)`, die `lsa_finish`, das
  Live-Bild und `platz_submit` gemeinsam benutzen. So sind die Schwellen an genau einer Stelle festgelegt.

## Empfehlung

| | Vorschlag Bauauftrag | **Empfehlung** | Begründung |
|---|---|---|---|
| Schwelle „schnell falsch“ | < 8 s | **< 5 s** | Erwachsene beantworten 28 % der richtigen Zahlaufgaben unter 8 s, aber nur 10 % unter 5 s. K liegt im Median bei 2,8 s und wird bei 5 s genauso sicher erkannt. |
| Regel „nicht auswertbar“ | ≥ 5 in Folge ODER ≥ 40 % (ab 10) | **unverändert** | 0 Fehlalarme bei 21 Handläufen und 6 Testkindern, K ab Aufgabe 10 erkannt. Größter Handlauf-Wert bei 5 s: Folge 2, Anteil 6 %. |
| Hinweis an das Kind | 3 schnelle falsche in Folge | **3 Abgaben unter 5 s in Folge, unabhängig von richtig/falsch, ohne WN**, einmal je LSA | Ein Hinweis, der an „falsch“ hängt, verrät dem Kind indirekt, dass die Antworten falsch waren (§6: kein Feedback richtig/falsch). Nach Tempo allein: ebenfalls 0 Treffer in Handläufen und Testkindern, K nach Aufgabe 8. |
| Deckel | 40 Aufgaben | **40** | Kein Testkind über 19, ein einziger Handlauf über 40 (Erwachsener, 43). |
| Fehlalarme bei echten Kindern | – | **nicht messbar: 0 echte LSAs in Prod** | Die Schwellen nach den ersten 20 echten LSAs erneut prüfen. Die Abfragen dieses Berichts lassen sich wiederverwenden. |

## Vorschlag für Schritt 2

### Edvancev1

| Was | Datei(en) | Umfang |
|---|---|---|
| Migration: Spalten `auswertbar`, `nicht_auswertbar_grund`; Funktion `lsa_durchklick_stand`; Deckel in `lsa_select_next_core`; Markierung in `lsa_finish`; Hinweis-Flag in `platz_submit` (`{ok, next, hinweis_tempo}`) | `supabase/migrations/<date -u>_lsa_durchklicken.sql`, Schema-Abzug | ~150 Zeilen SQL, dazu pgTAP |
| pgTAP: Klick-Folge markiert, Jonas-artiges Profil (langsam, viel WN) nicht, Deckel 40, Hinweis nur einmal | `supabase/tests/…` | ~120 Zeilen |
| Testkinder: siebtes Kind „Durchklicker“ (2–4 s, falsch) und WN-schnell-Variante | `tools/lsa-testkinder/erzeugen.sql`, README | ~40 Zeilen |
| Typen und lib: `auswertbar` in Report-Daten und Liste | `src/types/report.ts`, `src/lib/supabase/lsaReport.ts`, `lsaReportListe.ts` (Foundation-Zone) | ~30 Zeilen |
| Report-Bogen R7: statt Seiten 2–4 ein sachlicher Hinweis und „LSA wiederholen“ | `src/components/edvance/elternbericht/**`, i18n `elternbericht` | ~80 Zeilen |
| Präsentation sperren: `ReportPage` öffnet `?ansicht=praesentation` nicht, Button mit Tooltip warum | `src/pages/admin/ReportPage.tsx`, `src/pages/admin/lsaReports/LsaReportsPage.tsx`, i18n | ~40 Zeilen |
| Live-Markierung | **Ein Coach-Live-Bild für die LSA gibt es nicht.** Laufende LSAs zeigt nur Admin „Heute“ (`src/pages/admin/heute/HeuteImBetrieb.tsx` über `listTodaysLsaSessions`). Dort ein Badge „schnell“ | ~40 Zeilen (Frage 5) |

### edvance-app (eigener PR)

| Was | Datei(en) | Umfang |
|---|---|---|
| `hinweis_tempo` aus `platz_submit` lesen | `src/lib/queries/platz.ts`, `src/types/content.ts` | ~15 Zeilen |
| Ruhiger Hinweis einmal je LSA, ohne Wertung, ohne Rot, z. B. „Lies dir die Aufgabe in Ruhe durch, du hast Zeit.“ | `app/(student)/lsa/platz-task.tsx`, neue Komponente unter `src/components/lsa/`, i18n | ~60 Zeilen |

## Offene Fragen an Rasit

1. **70 oder 135?** Die Klick-LSA in Prod hat 135 Aufgaben und ist ein Testlauf. Meint der Bauauftrag dieselbe
   Sitzung? Wenn der Report „70“ zeigt, zählt er anders (Frage für R7).
2. **5 s statt 8 s** für „schnell falsch“ einverstanden?
3. **„Weiß ich nicht“ in 1 s als Durchklick-Taste** (H8–H10): zählt das mit? Jonas drückt WN langsam (44–69 s),
   ein echtes Kind kann WN aber auch schnell und ehrlich drücken. Vorschlag: zunächst nicht mitzählen. Eine LSA
   mit fast nur WN zeigt der Report schon als unbeantwortet. Nach den ersten echten LSAs neu entscheiden.
4. **Bei „nicht auswertbar“ sofort beenden** oder bis zum Deckel weiterlaufen lassen? Sofort beenden spart dem
   Kind Zeit, verrät aber über das plötzliche Ende ebenfalls etwas.
5. **Coach-Live-Bild**: Es gibt kein LSA-Live-Bild für Coaches, nur Admin „Heute“. Reicht dort ein Badge, oder ist
   das ein eigener Bauauftrag?
6. **Hinweis nach Tempo statt nach falsch** (wegen §6) einverstanden?
7. **Soll der Coach eine Markierung aufheben dürfen** („trotzdem auswerten“)? Davon hängt ab, ob die Spalte eine
   Coach-RPC braucht (Auth/RLS, Consensus-Trigger §8).
