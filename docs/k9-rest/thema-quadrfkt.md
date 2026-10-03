# K9-Rest – Thema quadrfkt (Quadratische Funktionen)

Stand 03.10.2026 · Branch `feat/k9-rest` · KLP Fkt-8/9 (Zweite Stufe) · `thema_key = quadratische_funktionen`.

30 Aufgaben, je sechs zu `fkt_quadr_parabel`, `fkt_quadr_scheitel`, `fkt_quadr_normalform`,
`fkt_quadr_nullstellen` und `fkt_quadr_extrem`. 4 davon mit Abbildung (Generator `koordinatensystem`).
Quelle: [`tools/k9-quadrfkt-charge.mjs`](../../tools/k9-quadrfkt-charge.mjs) → `docs/prefill/k9-quadrfkt.json` →
`supabase/migrations/20261003105904_aufgaben_k9_quadrfkt.sql` (vorlauf-build) und
`supabase/checks/k9_quadrfkt_aufgaben.PRUEFUNG.sql` (k9-rest-pruefung).

Ergebnisse: verify-tasks Charge-Fehler **0** · Prüfskript **16 von 16 t** (Wegwerf-DB mit allen acht
Substraten) · Wegwerf-DB **IDEMPOTENT: ok** (zweiter Lauf, gleiche Zeilenzahlen).

## Entscheidungen

- **Scheitelpunkte und Nullstellenpaare als MULTI_PART.** Der Tablet-Player nimmt nur Zahlen an.
  Teile heißen immer „x-Koordinate des Scheitelpunkts" / „y-Koordinate …" bzw. „kleinere Nullstelle" /
  „größere Nullstelle", damit die Zuordnung eindeutig ist. Bei `pq_vorzeichen` (x² − 2x − 8 → 2 und −4)
  sind die falschen Werte nach derselben Ordnung zugeordnet: kleinere −4, größere 2.
- **Vier Abbildungen** (Grenze 6): Verschiebung ablesen (parabel-02), Streckfaktor aus S und P
  (parabel-06), Scheitel ablesen (scheitel-02), Nullstellen ablesen (nullstellen-03). Alle Parabeln in
  Normalform aus der Scheitelform ausgerechnet; Scheitel, Punkte und Nullstellen liegen auf ganzzahligen
  Gitterpunkten. Jede Figur einmal mit `zeichne(params, 'hell')` gerendert und als PNG angesehen.
  alt_text ohne Ziffern und ohne Lagehinweis (verrät keine Vorzeichen).
- **Extremwertaufgaben nennen immer die gesuchte Größe** („größter Funktionswert", „maximale Höhe",
  „größtmöglicher Flächeninhalt in Quadratmetern"); `falsche_groesse_beantwortet` fängt die Stelle
  (x bzw. t) als Antwort. Bei der Zaunaufgabe (extrem-06, AFB III) ist A(x) bewusst nicht vorgegeben.
- **Exakt vs. gerundet:** Alle Aufgaben außer nullstellen-05 haben exakte (ganzzahlige oder abbrechende)
  Ergebnisse und sagen „Gib das Ergebnis exakt an." bzw. „Die gesuchten Werte sind ganzzahlig.".
  nullstellen-05 (Ball trifft den Boden) rundet auf zwei Stellen.
- **Bestands-Slugs über die genannte Liste hinaus**, nur wo die Bedeutung wörtlich passt:
  `mal_exponent` (Quadrat als „mal 2"), `vorzeichen_beim_umstellen` (Vorzeichen beim Umstellen/Teilen
  durch eine negative Zahl), `umgekehrt_geteilt` (16 : 8 statt 8 : 16), `mal_zwei_vergessen`
  (ausgeklammerter Faktor nicht auf die abgezogene Ergänzung angewandt), `bedingung_unvollstaendig`
  (Mauer als Rechteckseite übersehen). Keine neuen Slugs erfunden.
- **Neues Fehlbild `ergaenzung_vorzeichen` in 10 Aufgaben** (alle sechs der Normalform, dazu extrem-02 bis
  -05). Bei ausgeklammertem Faktor bedeutet es: die Ergänzung in der Klammer ein zweites Mal addiert
  (z. B. −0,1((x − 10)² + 100) + 1,5 = −8,5).
- Keine Hinweise, keine Personennamen, keine Mastery-Sprache; Zeitregel und Charge-Felder aus der Bibliothek.

## Aufgaben

Antwort bei MULTI_PART: Teil 1 / Teil 2. Rang = Sondierrang aus vorlauf-build.

| source_ref | Knoten | AFB | Begründung | Antwort | Fehlbilder | Rang | Abbildung |
|---|---|---|---|---|---|---|---|
| `quadrfkt-parabel-01` | parabel | I | Reproduzieren: eine positive Zahl in die Scheitelpunktform einsetzen. | 21 | `vorrang_ignoriert` (39), `mal_exponent` (15) | – | – |
| `quadrfkt-parabel-02` | parabel | I | Reproduzieren: Verschiebung einer Normalparabel am Gitter ablesen. | 3 | `koordinaten_vertauscht` (2) | – | y = x² − 4x + 7 |
| `quadrfkt-parabel-03` | parabel | II | Anwenden: negatives Argument, (−3)² richtig quadrieren. | 22 | `vorzeichen_potenz` (−32), `vorrang_ignoriert` (76) | 2 | – |
| `quadrfkt-parabel-04` | parabel | II | Anwenden: Punkt einsetzen, nach a umstellen. | 2 | `mal_exponent` (4), `vorzeichen_beim_umstellen` (2,375) | – | – |
| `quadrfkt-parabel-05` | parabel | II | Anwenden im Sachkontext (Wasserstrahl), negativer Streckfaktor. | 0,5 m | `vorrang_ignoriert` (7,25), `mal_exponent` (2) | – | – |
| `quadrfkt-parabel-06` | parabel | III | Problemlösen: S und P ablesen, Scheitelform aufstellen, a bestimmen. | 0,5 | `mal_exponent` (1), `umgekehrt_geteilt` (2), `koordinate_vorzeichen_verloren` (0,125) | 1 | y = 0,5x² − x − 2,5, S(1\|−3), P(5\|5) |
| `quadrfkt-scheitel-01` | scheitel | I | Reproduzieren: S(d\|e) direkt ablesen. | 3 / 1 | `vorzeichen_aus_klammer` (−3), `koordinaten_vertauscht` | – | – |
| `quadrfkt-scheitel-02` | scheitel | I | Reproduzieren: tiefsten Punkt am Gitter ablesen. | −2 / −3 | `koordinaten_vertauscht`, `koordinate_vorzeichen_verloren` | – | y = x² + 4x + 1 |
| `quadrfkt-scheitel-03` | scheitel | II | Anwenden: Plus in der Klammer, negativer Streckfaktor. | −4 / −5 | `vorzeichen_aus_klammer` (4), `koordinaten_vertauscht`, `koordinate_vorzeichen_verloren` (5) | 1 | – |
| `quadrfkt-scheitel-04` | scheitel | II | Anwenden: ungewohnte Reihenfolge y = 4 − 2(x − 6)². | 6 / 4 | `vorzeichen_aus_klammer` (−6), `koordinaten_vertauscht`, `vorrang_ignoriert` (2) | 2 | – |
| `quadrfkt-scheitel-05` | scheitel | II | Anwenden im Sachkontext (Brückenbogen), Dezimalzahlen. | 25 m / 12,5 m | `vorzeichen_aus_klammer` (−25), `koordinaten_vertauscht` | – | – |
| `quadrfkt-scheitel-06` | scheitel | III | Problemlösen: Rückrichtung S(2\|−1), a = 1 → c. | 3 | `vorzeichen_potenz` (−5), `koordinate_vorzeichen_verloren` (5) | – | – |
| `quadrfkt-normalform-01` | normalform | I | Reproduzieren: Ergänzung mit a = 1, gerades b. | 3 / −4 | `vorzeichen_aus_klammer` (−3), `halbieren_vergessen` (6), `ergaenzung_vorzeichen` (14) | – | – |
| `quadrfkt-normalform-02` | normalform | I | Reproduzieren: Ergänzung mit a = 1, positives b. | −2 / −3 | `vorzeichen_aus_klammer` (2), `halbieren_vergessen` (−4; −15), `ergaenzung_vorzeichen` (5) | – | – |
| `quadrfkt-normalform-03` | normalform | II | Anwenden: Faktor 2 ausklammern, dann ergänzen. | 2 / −5 | `vorzeichen_aus_klammer`, `halbieren_vergessen`, `ergaenzung_vorzeichen` (11), `mal_zwei_vergessen` (−1) | 1 | – |
| `quadrfkt-normalform-04` | normalform | II | Anwenden: ungerades b, Dezimal-Ergänzung. | 2,5 / −4,25 | `vorzeichen_aus_klammer`, `halbieren_vergessen` (5; −23), `ergaenzung_vorzeichen` (8,25) | – | – |
| `quadrfkt-normalform-05` | normalform | II | Anwenden im Sachkontext (Wurfbahn), negativer Dezimalfaktor. | 10 m / 11,5 m | `vorzeichen_aus_klammer`, `halbieren_vergessen` (20; 41,5), `ergaenzung_vorzeichen` (−8,5) | – | – |
| `quadrfkt-normalform-06` | normalform | III | Problemlösen: aus der Scheitelstelle b erschließen, dann y_S. | −2 | `ergaenzung_vorzeichen` (16), `falsche_groesse_beantwortet` (−6 = b) | 2 | – |
| `quadrfkt-nullstellen-01` | nullstellen | I | Reproduzieren: p-q-Formel, ganzzahlige Lösungen. | −2 / 4 | `pq_vorzeichen` (−4 / 2) | – | – |
| `quadrfkt-nullstellen-02` | nullstellen | I | Reproduzieren: Wurzelziehen aus der Scheitelform. | −1 / 3 | `vorzeichen_aus_klammer` (−3 / 1) | – | – |
| `quadrfkt-nullstellen-03` | nullstellen | II | Anwenden: nach unten geöffnet, Nullstellen von Scheitel und y-Abschnitt trennen. | −5 / 3 | `falsche_groesse_beantwortet` (−1), `koordinate_vorzeichen_verloren`, `koordinaten_vertauscht` (7,5) | 1 | y = −0,5x² − x + 7,5 |
| `quadrfkt-nullstellen-04` | nullstellen | II | Anwenden: erst durch 2 teilen, dann p-q-Formel. | −3 / 1 | `pq_vorzeichen` (−1 / 3) | – | – |
| `quadrfkt-nullstellen-05` | nullstellen | II | Anwenden im Sachkontext (Ball trifft den Boden), auf 2 Stellen. | 2,56 s | `pq_vorzeichen` (0,16), `vorzeichen_beim_umstellen` (2,22) | 2 | – |
| `quadrfkt-nullstellen-06` | nullstellen | III | Problemlösen: Scheitel als Mitte der Nullstellen, Term aufstellen. | −9 | `falsche_groesse_beantwortet` (2), `halbieren_vergessen` (−5) | – | – |
| `quadrfkt-extrem-01` | extrem | I | Reproduzieren: Extremwert aus der Scheitelform. | 7 | `falsche_groesse_beantwortet` (4), `koordinate_vorzeichen_verloren` (−7) | – | – |
| `quadrfkt-extrem-02` | extrem | I | Reproduzieren: Ergänzung, Minimum ablesen. | −6 | `ergaenzung_vorzeichen` (26), `falsche_groesse_beantwortet` (4) | – | – |
| `quadrfkt-extrem-03` | extrem | II | Anwenden: negativen Faktor ausklammern, Maximum. | 13 | `ergaenzung_vorzeichen` (−23), `falsche_groesse_beantwortet` (3), `mal_zwei_vergessen` (4) | 1 | – |
| `quadrfkt-extrem-04` | extrem | II | Anwenden: Zahlenrätsel, Produktfunktion aufstellen. | 100 | `falsche_groesse_beantwortet` (10), `ergaenzung_vorzeichen` (−100) | – | – |
| `quadrfkt-extrem-05` | extrem | II | Anwenden im Sachkontext (Wurfbahn), Höhe statt Zeitpunkt. | 21 m | `falsche_groesse_beantwortet` (2), `ergaenzung_vorzeichen` (−19), `vorrang_ignoriert` (141) | 2 | – |
| `quadrfkt-extrem-06` | extrem | III | Problemlösen im Sachkontext: Zielfunktion mit Mauer selbst aufstellen. | 200 m² | `falsche_groesse_beantwortet` (10), `bedingung_unvollstaendig` (100) | – | – |

## Offene Punkte / Befunde

1. **Rang 1 liegt in zwei Knoten auf einer Figuren-Aufgabe** (`quadrfkt-parabel-06`, `quadrfkt-nullstellen-03`;
   vorlauf-build wählt nach Fehlbildprofil). Die `task_figures`-Zeilen haben noch keinen `svg_hash`; bis
   `scripts/figures/upload_figures.py` gelaufen ist, liefert der Payload kein Bild, und diese Aufgaben sind
   ohne Bild nicht lösbar. Vor der Freigabe (Lena) also Upload, sonst sondiert der Abstieg mit einer
   bildlosen Aufgabe.
2. Das Prüfskript prüft lokal nur die neuen Slugs auf Existenz. Die benutzten Bestands-Slugs
   (`mal_exponent`, `umgekehrt_geteilt`, `mal_zwei_vergessen`, `vorzeichen_beim_umstellen`,
   `bedingung_unvollstaendig` u. a.) stehen in `fehlbild-bestand.json` (Prod-Abzug) – beim Prod-Lauf greift die
   volle Prüfung.
3. Lösungswege setzen Ergebnisse über die Bibliothek ein; negative Ergebnisse erscheinen dort mit
   ASCII-Minus („-4"), der übrige Text mit „−". Rein kosmetisch.
4. Voraussetzungen `term_einsetzen`, `geo_koordinaten`, `term_binom_quadrat` sind laut phase1 c) noch
   „dünn" (Entwürfe ohne Freigabe) – der Abstieg aus quadrfkt trägt erst nach deren Freigabe.
5. Testaufruf aus dem Auftrag `from figures import koordinatensystem as k` liefert die Funktion statt des
   Moduls (`figures/__init__` exportiert die Funktion gleichen Namens); gerendert wurde deshalb über
   `importlib.import_module('figures.koordinatensystem')`. Werkzeug nicht geändert.
