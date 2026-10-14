# P1 · potenzen prüfbar — offene Punkte

Stand 14.10.2026, alle Zahlen per `dbread` gegen Produktion (nur lesend).

## Herkunft der 13 Beanstandungen

Prüfblock der A20-Migration `20260723150000_a20_review_und_labels.sql` (Commit `0e25f76`, PR #102), Zeile 325:
`lena_beanstande_muster(v_skill, v_label, 'fehlbild_falsch', 'Probe')` mit Admin `35e4f9ac-…`. Der Block sollte
zurückrollen, die Migration lief aber ohne begin/commit; alle Prüfungen bestanden, also blieb alles stehen
(geprueft_am 2026-07-24 06:48:02.349088+00).

## Sperren für potenzen

| Sperre | Beleg |
|---|---|
| keine `skill_thema`-Zeile → `pruef_ausschluss = ohne_fertigkeit` (24/24) | `20261005131059_admin_pruefen_rechte.sql:70` |
| dadurch nicht im Testlauf-Pool | `testlauf_inhalt_sichtbar` verlangt `pruef_ausschluss is null` |
| dadurch nicht in Lenas Prüfansicht | `pruef_board()`: `pruef_ausschluss is null` + inner join `skill_thema` |
| `pruef_pilot = false` (24/24) bei `nur_pilot = true` | `pruef_board()`, `pruef_im_pilot` |
| 13 × vom Team beanstandet | `pruef_team_beanstandet` (letzte Review von Admin) |

Entscheidungen Rasit (14.10.): Thema `rationale_zahlen`, Pilot-Flag in derselben Migration, beanstandet → draft
über `task_status_set` als Systemaufruf, nur die 13 Probe-Zeilen.

## Prüfung A · Pilot-Flag auf Batus Freigabeliste — BEFUND, Bau angehalten

LSA-Aufgaben (`'lsa' = any(einsatz)`), davon `pruef_pilot`, davon in `pruef_board()` (Aufruf als Admin; die
nachgebaute Logik ergibt dieselben Zahlen). Ausschlussgrund überall leer, außer `dezimal_mult` (teils `gate`).

| Stufe | Knoten | LSA | Pilot | Lena sieht |
|---|---|---|---|---|
| 1 | zahl_wurzel_irrational | 6 | 0 | 0 |
| 1 | zahl_wurzel_naeherung | 6 | 1 | 1 |
| 1 | zahl_wurzel_teilweise | 6 | 0 | 0 |
| 1 | zahl_wurzel_gesetze | 6 | 0 | 0 |
| 1 | zahl_wurzel_quadrat | 6 | 2 | 2 |
| 2 | bruch_dezimal | 6 | 0 | 0 |
| 2 | dezimal_div | 9 | 0 | 0 |
| 2 | dezimal_mult | 9 | 0 | 0 |
| 2 | vorzeichen_mult_div | 7 | 0 | 0 |
| 2 | runden_ueberschlag | 13 | 0 | 0 |
| 2 | dezimal_add_sub | 11 | 3 | 3 |
| 2 | bruch_kuerzen | 7 | 3 | 3 |
| 2 | vorzeichen_add_sub | 7 | 0 | 0 |
| 3 | fkt_linear_gleichung | 6 | 0 | 0 |
| 3 | fkt_linear_steigung | 6 | 3 | 3 |
| 3 | fkt_linear_yabschnitt | 6 | 0 | 0 |
| 3 | term_binom_faktorisieren | 6 | 0 | 0 |
| 3 | term_binom_gemischt | 6 | 0 | 0 |
| 3 | term_binom_quadrat | 6 | 3 | 3 |
| 3 | term_binom_quadratdifferenz | 6 | 0 | 0 |
| 3 | gleichung_lgs_addition | 6 | 0 | 0 |
| 3 | gleichung_lgs_einsetzen | 6 | 3 | 3 |
| 3 | gleichung_lgs_grafisch | 6 | 0 | 0 |
| 3 | geo_flaeche_drachen_raute | 6 | 0 | 0 |
| 3 | geo_flaeche_term | 6 | 0 | 0 |
| 3 | geo_flaeche_trapez | 6 | 0 | 0 |
| 3 | stoch_pfad_summe | 6 | 0 | 0 |
| 3 | geo_winkel_thales | 6 | 3 | 3 |

Session E3 (49 Aufgaben aus `docs/prefill/hinweise-e3-snapshot.json`, PR #244; alle 49 in Prod gefunden, alle
`lsa` + `session`):

| Knoten | Aufgaben | Pilot | Lena sieht |
|---|---|---|---|
| gleichung_einschrittig | 6 | 0 | 0 |
| gleichung_quadr_anzahl | 6 | 0 | 0 |
| gleichung_quadr_faktor | 6 | 0 | 0 |
| gleichung_quadr_formel | 6 | 0 | 0 |
| gleichung_quadr_wurzel | 6 | 3 | 3 |
| gleichung_zweischrittig | 6 | 0 | 0 |
| term_ausklammern | 6 | 0 | 0 |
| vorzeichen_add_sub | 7 | 0 | 0 |

Summe: 19 von 28 Knoten und 7 von 8 Session-Knoten haben kein einziges Pilot-Flag, Lena sieht dort nichts.
**Entschieden (Rasit, 14.10.):** `nur_pilot` bleibt an, M2 setzt das Flag (siehe unten).

## Prüfung B · weitere Reste aus dem A20-Prüfblock

- `task_reviews` mit Notiz wie `%probe%` oder geprüft 24.07. 06:40–07:00 UTC: nur die 13 bekannten. Das Konto
  `35e4f9ac-…` hat insgesamt genau 13 Reviews.
- **P4-Rest:** Aufgabe `c6990fb9-ae96-4a56-952e-da94736ac70f` (VERA8_IQB, MULTI_PART, draft, ohne skill_key)
  trägt am Fragetext den Zusatz ` (bitte genau lesen)` aus `lena_text_aendern` (Prüfblock Punkt 4). Für Lena
  unsichtbar (`pruef_ausschluss = vera8`), aber in `einsatz` steht `lsa,session`. Nicht angefasst.
- P1 des Prüfblocks schaltete eine draft-Aufgabe über beanstandet/ready/review zurück auf draft; Endstand draft, also kein
  sichtbarer Rest; welche Aufgabe es war, nicht weiter verfolgt.

**Entschieden (Rasit, 14.10.):** Der Zusatz wird entfernt (M3). Original belegt: `data/c10_dump.json` in Commit
`2a9cb31` (17.07.2026) ist zeichengleich mit dem heutigen Prod-Text ohne ` (bitte genau lesen)`.

## Migrationen (Bereich 20261014140000–145959, am 14.10. per dbread frei; Prod-Maximum 20261014121000)

| Version | Inhalt |
|---|---|
| `20261014140100_p1_potenzen_pruefbar` | 13 Probe-Beanstandungen → draft über `task_status_set` (Systemrolle transaktionslokal), nur bei exakter Probe-Signatur der letzten Review (Kategorie, Notiz, Prüfer, Zeitstempel); `skill_thema` potenzen → rationale_zahlen |
| `20261014140200_p1_batu_pilot` | `pruef_pilot = true` über `pruef_sammel_schreiben('pilot_an', …)` für die LSA-Aufgaben der 29 Knoten und die 49 E3-IDs; schreibt je Aufgabe eine `task_admin_protokoll`-Zeile (von = null) |
| `20261014140300_p1_a20_rest_text` | c6990fb9: Zusatz aus `question` entfernt, nur wenn der Text genau „Original + Zusatz“ ist |

### M2 · Pilot-Flags neu je Knoten (dbread 14.10.)

| Knoten | Ziel | schon | neu |
|---|---|---|---|
| zahl_wurzel_irrational | 6 | 0 | 6 |
| zahl_wurzel_naeherung | 6 | 1 | 5 |
| zahl_wurzel_teilweise | 6 | 0 | 6 |
| zahl_wurzel_gesetze | 6 | 0 | 6 |
| zahl_wurzel_quadrat | 6 | 2 | 4 |
| potenzen | 24 | 0 | 24 |
| bruch_dezimal | 6 | 0 | 6 |
| dezimal_div | 9 | 0 | 9 |
| dezimal_mult | 9 | 0 | 9 |
| vorzeichen_mult_div | 7 | 0 | 7 |
| runden_ueberschlag | 13 | 0 | 13 |
| dezimal_add_sub | 11 | 3 | 8 |
| bruch_kuerzen | 7 | 3 | 4 |
| vorzeichen_add_sub (auch E3) | 7 | 0 | 7 |
| fkt_linear_gleichung | 6 | 0 | 6 |
| fkt_linear_steigung | 6 | 3 | 3 |
| fkt_linear_yabschnitt | 6 | 0 | 6 |
| term_binom_faktorisieren | 6 | 0 | 6 |
| term_binom_gemischt | 6 | 0 | 6 |
| term_binom_quadrat | 6 | 3 | 3 |
| term_binom_quadratdifferenz | 6 | 0 | 6 |
| gleichung_lgs_addition | 6 | 0 | 6 |
| gleichung_lgs_einsetzen | 6 | 3 | 3 |
| gleichung_lgs_grafisch | 6 | 0 | 6 |
| geo_flaeche_drachen_raute | 6 | 0 | 6 |
| geo_flaeche_term | 6 | 0 | 6 |
| geo_flaeche_trapez | 6 | 0 | 6 |
| stoch_pfad_summe | 6 | 0 | 6 |
| geo_winkel_thales | 6 | 3 | 3 |
| E3 gleichung_einschrittig | 6 | 0 | 6 |
| E3 gleichung_quadr_anzahl | 6 | 0 | 6 |
| E3 gleichung_quadr_faktor | 6 | 0 | 6 |
| E3 gleichung_quadr_formel | 6 | 0 | 6 |
| E3 gleichung_quadr_wurzel | 6 | 3 | 3 |
| E3 gleichung_zweischrittig | 6 | 0 | 6 |
| E3 term_ausklammern | 6 | 0 | 6 |
| **Summe** | **255** | **24** | **231** |

## Offene Punkte

1. **Prüfblock ohne begin/rollback.** Der Block in `20260723150000_a20_review_und_labels.sql` (ab Zeile 285)
   kündigt „die Transaktion rollt zurueck“ an, rollt aber nur bei einem Fehler zurück; bestanden, bleiben seine
   Schreibvorgänge stehen (13 Beanstandungen, Textzusatz an c6990fb9). Er steht weiterhin in `supabase/migrations/`
   und läuft bei jedem CI-Neuaufbau mit (dort harmlos: im Wegwerf-Lauf traf M1 deshalb 0 Probe-Zeilen, weil der
   Zeitstempel ein anderer ist). Durchsicht aller 13 Dateien, die je unter `supabase/pending/` lagen
   (`git log --all --diff-filter=A -- 'supabase/pending/*.sql'`): **nur A20** hat einen schreibenden Prüfblock ohne
   begin/rollback. A21 hat seine Prüfung ausdrücklich in eine Schwesterdatei mit begin/rollback ausgelagert
   (`20260723160000_a21_freigabe_muster.PRUEFUNG.sql`), A15 klammert mit begin/commit ohne schreibende Prüfung,
   die übrigen haben keinen Prüfblock. Nur aufgelistet, nichts geändert.
2. **Nebenwirkung des Themas.** `skill_thema` liest nicht nur `pruef_ausschluss`/`pruef_board`, sondern auch
   `freigabe_thema`, `ziel_fertigkeiten_sitzung`, `naechste_luecke_sitzung`, `session_misch_kandidaten` und
   `quest_erzeugen` (`supabase/schema-erwartet.sql`). Ab M1 zählt potenzen dort zum Thema rationale_zahlen
   (Klasse 7). Den LSA-Themenraum berührt das nicht: der kommt aus `thema_einstieg` + `lsa_abschluss` über
   `skill_kante` (Test T7).
3. **Fachlich gemischt.** potenzen enthält auch `√36`/`√144` (eigentlich reelle_zahlen, Kl. 9) und Dezimalpotenzen
   aus dem Zins-Kontext (`zins-potenzen-*`). Bei Lenas Durchsicht prüfen, ob sie dort bleiben.
4. **dezimal_mult:** 1 von 9 Aufgaben bleibt regulär ausgeschlossen (`gate`: „Cluster fehlt“); 8 sichtbar, alle
   NUMERIC (≥ 3 ohne MC erfüllt).

## Einspielergebnis (14.10.2026, nach „P1 einspielen“)

Eingespielt mit `~/bin/mig` aus dem Worktree, je Migration eine Transaktion plus History-Eintrag. Meldungen: M1 13 Probe-Beanstandungen → draft, 1 `skill_thema`-Zeile; M2 231 Flags neu; M3 1 Zeile.

Kontrolle per dbread:

| Prüfung | Ergebnis |
|---|---|
| `schema_migrations` | 20261014140100, 140200, 140300 vorhanden |
| potenzen | 24 Aufgaben, 24 draft, 0 beanstandet, 0 ready, 24 Pilot, Thema rationale_zahlen, Testlauf-Pool 24, echter Pool 0 |
| `pruef_board()` als Admin | 255 Zielaufgaben, 1 regulär ausgeschlossen (dezimal_mult, gate), **254 sichtbar**; jeder Knoten vollständig |
| Pilot gesamt | 331 (vorher 100, +231); 231 `pilot_an`-Protokollzeilen |
| c6990fb9 | Text zeichengleich mit dem Original, Zusatz weg |
| Beanstandungen gesamt / `task_reviews` | 0 / 13 (Historie unverändert) |
| `tools/schema-snapshot.sh` | kein Unterschied zu `schema-erwartet.sql` (reine Datenmigrationen) |

**Korrektur:** Die Summe in der M2-Tabelle war 258/27, richtig ist 255/24 (Rechenfehler beim Addieren; die
Einzelzeilen und die 231 neuen Flags stimmten). Der Kopfkommentar von `20261014140200_p1_batu_pilot.sql` trägt
noch „258 … 27“; die Datei ist eingespielt und wird deshalb nicht mehr geändert.
