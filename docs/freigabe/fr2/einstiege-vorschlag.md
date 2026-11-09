# FR-2 · F4.1 Einstiegsknoten: Vorschlag

**Stand:** 09.11.2026, Prod per `dbread`.

## Welche Themen

Der Bericht nennt 15 von 37 Themen ohne `thema_einstieg` (über alle Stufen). In den Plänen der Klassen 8–10 und in
der Kernlehrplan-Folge der Klassen 8–10 (`lsa_klp_themen`, Rückfall für Schulen ohne Plan) sind es **drei**. Die
übrigen zwölf gehören zu den Stufen 5–7 und kommen in keinem Plan der Klassen 8–10 vor. Sie sind nicht Teil von FR-2.

| Thema | Klasse (Stufe) | in Plänen Kl. 8–10 | Skills (`skill_thema`, Klasse, Fundamenttiefe) |
|---|---|---|---|
| `rationale_zahlen` „Rationale Zahlen“ | 7 (erste) | 0 (nur Kernlehrplan Kl. 8) | vorzeichen_vorrang (7, 4), potenzen (7, 4), vorzeichen_mult_div (7, 2), vorzeichen_add_sub (7, 1) |
| `zuordnungen` „Proportionale und antiproportionale Zuordnungen“ | 7 (erste) | 0 (nur Kernlehrplan Kl. 8) | proportionalitaet (7, 4) |
| `statistik_beurteilen` „Statistische Erhebungen beurteilen“ | 9 (zweite) | 5 Schulpläne Kl. 9 | stoch_bedingt_irrefuehrend (9, 8) |

**Muster der bestehenden Einstiege:** Einstieg sind die „obersten“ Skills eines Themas, also die, die kein anderer
Skill des Themas voraussetzt. Der Rest des Themas liegt dann im Themenraum (`lsa_abschluss`). Beispiele:
`reelle_zahlen` → zahl_wurzel_irrational, zahl_wurzel_teilweise, zahl_wurzel_naeherung; `lineare_funktionen` →
fkt_linear_gleichung, fkt_linear_steigung, fkt_linear_yabschnitt.

## Vorschlag

| Thema | Einstiege | Themenraum danach | Begründung (Kernlehrplan Mathematik NRW G9) |
|---|---|---|---|
| `rationale_zahlen` | **vorzeichen_vorrang**, **potenzen** | + vorzeichen_mult_div, vorzeichen_add_sub (Kanten vorrang → mult_div → add_sub; potenzen → mult_div, dezimal_mult) | KLP Kl. 7, Inhaltsfeld Arithmetik/Algebra: Rechnen mit rationalen Zahlen in allen Grundrechenarten, Rechengesetze und Vorrangregeln mit Vorzeichen; Quadratzahlen und Potenzschreibweise. Die Vorrangregeln mit Vorzeichen bündeln Addition, Subtraktion, Multiplikation und Division ganzer und rationaler Zahlen. Potenzen sind der zweite oberste Skill des Themas und setzen die Vorzeichenmultiplikation voraus. |
| `zuordnungen` | **proportionalitaet** | + dezimal_div (Kante proportionalitaet → dezimal_div) und deren Abschluss | KLP Kl. 7, Inhaltsfeld Funktionen: proportionale und antiproportionale Zuordnungen erkennen, Dreisatz. Einziger Skill des Themas. |
| `statistik_beurteilen` | **stoch_bedingt_irrefuehrend** | + prozent_prozentsatz, stoch_bedingt_wkeit und deren Abschluss | KLP Kl. 9/10, Inhaltsfeld Stochastik: statistische Erhebungen und Darstellungen kritisch beurteilen, irreführende Aussagen (auch bei bedingten Wahrscheinlichkeiten) erkennen. Einziger Skill des Themas. |

**Wirkung:** Die 5 Pakete der Klasse 9 mit `statistik_beurteilen` haben dann Einstiegsknoten (heute Rot wegen
`hat_einstieg = false`). Für Schulen ohne Plan für Klasse 8 startet die Thema-LSA zu „Rationale Zahlen“ und
„Zuordnungen“.

## Fachliche Zweitprüfung

Ein frischer Subagent ohne Kontext prüft den Vorschlag (Datei unten ergänzt). In die Migration kommen nur Einstiege,
die er ohne Einwand bestätigt. Strittige bleiben hier offen für Rasit.

**Ergebnis (frischer Subagent als Fachdidaktiker, nur lesend, 09.11.2026):**

| Thema → Einstieg | Ergebnis |
|---|---|
| rationale_zahlen → vorzeichen_vorrang | **bestätigt ohne Einwand**: bündelt alle Grundrechenarten mit Vorzeichen, Kette vorrang → mult_div → add_sub stimmt |
| rationale_zahlen → potenzen | **strittig**: Quadratzahlen/Potenzschreibweise sind Stoff Kl. 5/6, Potenzen als Thema Kl. 9; als Einstieg zöge es das Thema über dezimal_mult in die Dezimalrechnung. Höchstens Potenzen mit negativer Basis passen. Vorschlag des Prüfers: kein Einstieg. |
| zuordnungen → proportionalitaet | **bestätigt ohne Einwand** |
| statistik_beurteilen → stoch_bedingt_irrefuehrend | **bestätigt ohne Einwand** |

Hinweise des Prüfers (nicht Teil dieser Migration):
- Für Ordnen, Zahlengerade, Betrag und Rechnen mit negativen Brüchen/Dezimalzahlen gibt es keinen Skill; die
  vorzeichen-Skills meinen eher ganze Zahlen.
- `stoch_bedingt_irrefuehrend` hat als Voraussetzungen nur `stoch_bedingt_wkeit` und `prozent_prozentsatz`;
  `stoch_kenngroessen` (Median, Quartile) könnte eine Kante wert sein.

## Entscheidung für die Migration

In die Migration kommen nur die drei bestätigten Einstiege. **Offen für Rasit:** `rationale_zahlen → potenzen`
(strittig) sowie die beiden Hinweise zum Skill-Graphen.
