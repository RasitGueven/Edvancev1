# K10-Rest – Thema exp (Exponentialfunktionen)

Stand 03.10.2026 · Branch `feat/k10-rest` · KLP G9 NRW, Zweite Stufe, Fkt-10, Fkt-12, Ari-10, Ari-11.
Quelle `tools/k10-exp-charge.mjs` → `docs/prefill/k10-exp.json` (ids in `docs/prefill/k10-exp-ids.json`)
→ Aufgaben-Migration per `tools/vorlauf-build.mjs` (Einspiel-Reihenfolge: nach
`20261003121328_substrat_k10_exp.sql`).

30 Aufgaben, je sechs zu `fkt_exp_wachstum`, `_term`, `_halbwert`, `_gleichung`, `_anwendung`.
26 `NUMERIC`, 4 `MULTI_PART` (term-01, -02, -05, -06), `curriculum_grade = 10`, „Algebra & Funktionen",
`competency_content = funktionen`, keine Hinweise, `source = edvance_k10_exp`. Zwei Aufgaben mit
Abbildung (term-04, term-05; Generator `koordinatensystem`, nur Punkte). AFB je Knoten 2× I, 3× II, 1× III.

## Ergebnis der Kette

- Charge: 30 Aufgaben, ohne „Charge abgelehnt". Fehlbild-Häufigkeit (Aufgaben):
  neu `linear_statt_exponentiell` 9, `anfangswert_faktor_vertauscht` 5, `log_falsch_geteilt` 5,
  `zeit_statt_perioden` 4, `abnahmefaktor_falsch` 3, `rate_aus_faktor_falsch` 3 (Mindestzahl 3);
  Bestand `mal_exponent` 7, `prozente_addiert` 6, `wachstumsfaktor_falsch` 5,
  `falsche_groesse_beantwortet` 4, `betrag_fehler` 2, `negativer_exponent_negativ` 2,
  `vorrang_ignoriert` 2, `wurzel_vergessen` 2, `zu_frueh_gerundet` 2, `umgekehrt_geteilt` 1.
- `k10-rest-minuscheck.mjs`: keine mehrdeutigen Ausdrücke.
- verify-prefill, Wegwerf-DB und Blind-Löser: macht der Auftraggeber (noch offen).

## Entscheidungen

- **Jede Zahl über Ausdrücke**, auch die falschen: Logarithmen als `L(c)/L(b)` (basisunabhängig),
  gebrochene Hochzahl als `H(2;10/3)`, negative Hochzahlen als `1/0.5^2`, negative Werte als `(0-2)`.
- **Rundung im Text**: „Gib das Ergebnis exakt an." bei abbrechenden Ergebnissen, „Runde auf zwei
  Stellen nach dem Komma." bei Logarithmen und Zinsen, „Gib die Anzahl der ganzen Jahre/Stunden an,
  nach denen … erstmals …" (`n: 'auf'`) bei Zeitpunkten, „Runde auf ganze Tiere." bei halbwert-06,
  Jahreszahl bei anwendung-05.
- **Grenzen eindeutig**: „erstmals mindestens/höchstens" dort, wo das lineare Fehlbild genau auf der
  Grenze landet (anwendung-01: 500 : 50 = 10; anwendung-02: 60 : 12 = 5), „erstmals mehr/weniger
  als" sonst. Keine richtige Lösung liegt auf einer Grenze (Proben im Lösungsweg).
- **Terme über Teile**: f(x) = a·bˣ wird als a und b abgefragt (term-02, -05, -06); term-01 fragt
  Anfangswert und Prozentsatz (Rückrichtung Faktor → Rate). Brüche als Eingabe bei term-05 (a = 3/2)
  und den Gleichungen mit 1/16, 1/64 (`bruch: true`).
- **Abbildungen**: nur Punkte (der Generator zeichnet keine Exponentialkurve). Text sagt „Die Punkte
  P und Q … liegen auf dem Graphen von f(x) = a · bˣ", Koordinaten stehen nicht im Text, alle Punkte
  auf Gitterpunkten im Fenster; alt_text ohne Ziffern. term-04: P(0|2), Q(1|6) → f(3);
  term-05: P(1|3), Q(3|12) → a, b (zwei Schritte: b² = 4).
- **`prozente_addiert` vs. `linear_statt_exponentiell`**: Wie in phase1.md d) – bei Prozent-Wachstum
  (Zinsen, Zu-/Abnahme um p %) `prozente_addiert`, sonst (Verdopplung, Halbierung, Folge, Punkte,
  „auf 80 %") `linear_statt_exponentiell`.
- **`rate_aus_faktor_falsch`** auch für „sinkt auf 80 %" als Abnahme um 80 % gelesen (anwendung-03,
  Faktor 0,2): genau die Verwechslung „0,8 als 80 % Abnahme".
- **`zeit_statt_perioden`** in anwendung-04 (0,5ᵗ statt 0,5^(t/6)): Der Wert fällt mit „Anzahl der
  Halbwertszeiten statt Stunden angegeben" zusammen; die Slug-Bedeutung (Zeit direkt als Hochzahl)
  trifft beide Wege.
- **Bestands-Slugs, die wörtlich passen**: `betrag_fehler` (−3 als 3, „Betrag richtig, Vorzeichen
  gekippt"), `vorrang_ignoriert` (2,5 · 1,04ˣ als 2,6ˣ – links nach rechts gerechnet),
  `wurzel_vergessen` (b² als b beim Term aus zwei Punkten), `umgekehrt_geteilt` (log b : log c),
  `zu_frueh_gerundet` (Hochzahl 10/3 als 3,33; Quotient 1,08 : 1,03 als 1,05).
  `negativer_exponent_negativ` nur im wörtlichen Sinn (b⁻ⁿ = −bⁿ: 0,5⁻² = −0,25; 2⁻⁴ = −16).
- Keine Personen mit Namen, keine Marken. Sachkontexte: Maschine, Kapital/Anlagen, Bakterien,
  Medikament, Tierpopulation, Fische, radioaktiver Stoff, Gemeinde. Keine Tausenderpunkte (größte
  Zahl im Text 9000).

## Aufgaben

N = NUMERIC, MP = MULTI_PART. Rang aus der Ausgabe von `vorlauf-build.mjs` (noch nicht gelaufen → –).

| source_ref | Knoten | Typ | AFB | Begründung | Antwort | Fehlbilder | Rang | Abbildung |
|---|---|---|---|---|---|---|---|---|
| `exp-wachstum-01` | wachstum | N | I | Reproduzieren: Wachstumsfaktor q = 1 + p/100 aus einem ganzzahligen Prozentsatz bilden. | 1,04 | `wachstumsfaktor_falsch` | – | – |
| `exp-wachstum-02` | wachstum | N | I | Reproduzieren: Faktor q = 1 − p/100 bei prozentualer Abnahme bilden. | 0,85 | `abnahmefaktor_falsch` | – | – |
| `exp-wachstum-03` | wachstum | N | II | Anwenden: Wachstumsfaktor bilden und als Potenz über mehrere Schritte anwenden. | 631,24 | `prozente_addiert`, `mal_exponent`, `wachstumsfaktor_falsch` | – | – |
| `exp-wachstum-04` | wachstum | N | II | Anwenden: konstanten Quotienten statt konstanter Differenz erkennen und zwei Schritte weiterrechnen. | 202,5 | `linear_statt_exponentiell`, `mal_exponent` | – | – |
| `exp-wachstum-05` | wachstum | N | II | Anwenden in der Rückrichtung: aus dem Abnahmefaktor die prozentuale Abnahme ablesen. | 12 % | `rate_aus_faktor_falsch` | – | – |
| `exp-wachstum-06` | wachstum | N | III | Problemlösen: exponentielles und lineares Fortschreiben selbst aufstellen und den Unterschied bilden. | 18,55 € | `falsche_groesse_beantwortet`, `wachstumsfaktor_falsch` | – | – |
| `exp-term-01` | term | MP | I | Reproduzieren: Anfangswert und Wachstumsrate aus dem Funktionsterm ablesen. | a = 250; Zunahme = 8 % | `anfangswert_faktor_vertauscht`, `rate_aus_faktor_falsch` | – | – |
| `exp-term-02` | term | MP | I | Reproduzieren: a und b aus Anfangswert und prozentualer Abnahme bestimmen. | a = 200; b = 0,9 | `anfangswert_faktor_vertauscht`, `abnahmefaktor_falsch` | – | – |
| `exp-term-03` | term | N | II | Anwenden: negative Hochzahl als Kehrwert deuten und mit dem Anfangswert multiplizieren. | 320 | `negativer_exponent_negativ`, `mal_exponent` | – | – |
| `exp-term-04` | term | N | II | Anwenden: Anfangswert und Faktor aus zwei abgelesenen Punkten bestimmen, dann auswerten. | 54 | `linear_statt_exponentiell`, `mal_exponent`, `anfangswert_faktor_vertauscht` | – | ja |
| `exp-term-05` | term | MP | II | Anwenden in der Rückrichtung: aus zwei Punkten den Faktor über zwei Schritte und daraus a bestimmen. | a = 1,5; b = 2 | `anfangswert_faktor_vertauscht`, `wurzel_vergessen`, `linear_statt_exponentiell` | – | ja |
| `exp-term-06` | term | MP | III | Problemlösen: aus zwei Messwerten den Faktor über zwei Schritte und den Anfangswert durch Zurückrechnen bestimmen. | a = 160; b = 1,5 | `linear_statt_exponentiell`, `anfangswert_faktor_vertauscht`, `wurzel_vergessen` | – | – |
| `exp-halbwert-01` | halbwert | N | I | Reproduzieren: Anzahl der Halbwertszeiten bestimmen und entsprechend oft halbieren. | 8 g | `mal_exponent`, `zeit_statt_perioden` | – | – |
| `exp-halbwert-02` | halbwert | N | I | Reproduzieren: Anzahl der Verdopplungszeiten bestimmen und entsprechend oft verdoppeln. | 2400 | `linear_statt_exponentiell`, `mal_exponent`, `zeit_statt_perioden` | – | – |
| `exp-halbwert-03` | halbwert | N | II | Anwenden: Verhältnis als Zweierpotenz erkennen, Anzahl der Halbwertszeiten in Zeit umrechnen. | 32 Tage | `falsche_groesse_beantwortet` | – | – |
| `exp-halbwert-04` | halbwert | N | II | Anwenden: Potenzen des Wachstumsfaktors probieren (oder logarithmieren) und die erste ganze Zahl über der Grenze wählen. | 7 Jahre | `wachstumsfaktor_falsch`, `prozente_addiert` | – | – |
| `exp-halbwert-05` | halbwert | N | II | Anwenden in der Rückrichtung: aus dem Restanteil die Anzahl der Halbierungen und daraus die Halbwertszeit bestimmen. | 4 h | `falsche_groesse_beantwortet`, `linear_statt_exponentiell` | – | – |
| `exp-halbwert-06` | halbwert | N | III | Problemlösen: nicht ganzzahlige Anzahl von Verdopplungszeiten als gebrochene Hochzahl einsetzen. | 5040 | `linear_statt_exponentiell`, `zu_frueh_gerundet`, `zeit_statt_perioden` | – | – |
| `exp-gleichung-01` | gleichung | N | I | Reproduzieren: ganzzahlige Lösung durch Potenzen der Basis finden. | 4 | `log_falsch_geteilt` | – | – |
| `exp-gleichung-02` | gleichung | N | I | Reproduzieren: Kehrwert einer Zweierpotenz als negative Hochzahl erkennen. | −3 | `betrag_fehler`, `log_falsch_geteilt` | – | – |
| `exp-gleichung-03` | gleichung | N | II | Anwenden im Sachkontext: Gleichung bˣ = c mit x = log c : log b lösen und runden. | 7,39 | `log_falsch_geteilt`, `umgekehrt_geteilt` | – | – |
| `exp-gleichung-04` | gleichung | N | II | Anwenden: erst durch den Vorfaktor teilen, dann logarithmieren und runden. | 11,98 | `vorrang_ignoriert`, `log_falsch_geteilt` | – | – |
| `exp-gleichung-05` | gleichung | N | II | Anwenden in der Rückrichtung: aus der Lösung den Wert c als Potenz mit negativer Hochzahl berechnen. | 0,0625 | `negativer_exponent_negativ`, `mal_exponent` | – | – |
| `exp-gleichung-06` | gleichung | N | III | Problemlösen: Vorfaktor abspalten, Bruch als Zweierpotenz mit negativer Hochzahl erkennen. | −5 | `betrag_fehler`, `vorrang_ignoriert`, `log_falsch_geteilt` | – | – |
| `exp-anwendung-01` | anwendung | N | I | Reproduzieren: Zinseszins-Gleichung aufstellen und die kleinste ganze Jahreszahl über der Grenze bestimmen. | 9 Jahre | `wachstumsfaktor_falsch`, `prozente_addiert` | – | – |
| `exp-anwendung-02` | anwendung | N | I | Reproduzieren: Abnahmefaktor bilden, Gleichung lösen und auf ganze Stunden aufrunden. | 9 h | `abnahmefaktor_falsch`, `prozente_addiert` | – | – |
| `exp-anwendung-03` | anwendung | N | II | Anwenden: „auf 80 %" als Faktor 0,8 deuten, Gleichung lösen, auf ganze Jahre aufrunden. | 7 Jahre | `rate_aus_faktor_falsch`, `linear_statt_exponentiell` | – | – |
| `exp-anwendung-04` | anwendung | N | II | Anwenden: Zeit über die Halbwertszeit in die Hochzahl einbauen, logarithmieren und aufrunden. | 20 h | `zeit_statt_perioden`, `linear_statt_exponentiell` | – | – |
| `exp-anwendung-05` | anwendung | N | II | Anwenden: Zeitpunkt berechnen und als Jahreszahl angeben (Anzahl der Jahre zum Startjahr addieren). | 2028 | `falsche_groesse_beantwortet`, `prozente_addiert` | – | – |
| `exp-anwendung-06` | anwendung | N | III | Problemlösen: zwei exponentielle Modelle gleichsetzen, durch Umformen auf bˣ = c bringen, logarithmieren und aufrunden. | 20 Jahre | `zu_frueh_gerundet`, `prozente_addiert` | – | – |

## Offene Punkte / Befunde

- **Kein Graph einer Exponentialfunktion**: `koordinatensystem` kann keine Exponentialkurve; „Graph
  lesen" ist nur über Punkte möglich (term-04, -05). Eigenschaften wie Asymptote, Monotonie oder
  „Graph geht durch (0|a)" sind ohne Kurve und ohne Auswahlformat nicht prüfbar.
- **Kein Term-Format**: f(x) = a·bˣ ist nur als zwei Zahlen (a, b) prüfbar; die Schreibweise des
  Terms selbst (z. B. 200 · 0,9ˣ statt 0,9 · 200ˣ) bleibt ungeprüft.
- **Fkt-10 „Wachstumsmodelle begründet wählen"**: nur indirekt (wachstum-04, -06; linear gegen
  exponentiell als Fehlbild), eine Entscheidung „linear oder exponentiell?" ist als Zahl nicht eingebbar.
- **Fkt-11** (Messreihen mit digitalen Werkzeugen) nicht abgebildet (phase1.md a).
- **`umgekehrt_geteilt`** und **`mal_exponent`** haben im Bestand keine Klartext-Bedeutung; benutzt im
  Sinn ihrer bisherigen Verwendung (umgekehrt geteilt; bⁿ als b·n).
- **anwendung-01/-02**: das Fehlbild mit falschem Faktor (1,5 bzw. 0,15) ergibt 1 Jahr/1 Stunde –
  plausibel als Schülerwert (1000 · 1,5 = 1500; 80 · 0,15 = 12), aber ein schwacher Diagnosewert.
- **halbwert-01**: `zeit_statt_perioden` ergibt 0,001953125 g – exakt, aber lang; ein Kind mit
  gerundeter Taschenrechnerausgabe trifft den Wert nicht.
- Lösungswege nennen negative Ergebnisse mit ASCII-Minus (`x = -3`), weil die Bibliothek die erste
  Antwortform wörtlich im Weg verlangt.
- Freigabe durch Lena steht aus (`draft`); die Voraussetzungen `prozent_zins_zinseszins`,
  `fkt_linear_gleichung`, `zahl_potenz_negativ` sind selbst noch Entwurf (phase1.md c).
