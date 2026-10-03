# K8-Rest – Entscheidungen

Stand 03.10.2026 · Branch `feat/k8-rest` · Auftrag `W4-k8-rest.md`. Grundlage: `phase1.md`.
Die Entscheidungen der vier Themen stehen ausführlich in eigenen Dateien:
[LGS](entscheidungen-lgs.md) · [Stochastik](entscheidungen-stoch.md) ·
[Flächen](entscheidungen-flaeche.md) · [Winkel/Thales](entscheidungen-winkel.md).
Hier stehen die übergreifenden Entscheidungen des Hubs und je Thema die wichtigsten.

## Übergreifend (Hub)

| Nr. | Entscheidung | Begründung |
|---|---|---|
| H1 | **Migrationen ohne begin/commit**, Lösungs-Upsert je `do`-Block mit `set_config('request.jwt.claim.role','service_role', true)` (neues Charge-Feld `ohne_transaktion` in `vorlauf-build.mjs`) | Auftrag: `mig` spielt mit `psql -1` ein. CI (`schema.yml`) und Wegwerf-DB spielen ohne Klammer ein; ein `set_config(…, true)` am Dateikopf wirkte dort nur für eine Anweisung und `task_solution_upsert` scheiterte mit „kein Pruefrecht“. Der `do`-Block ist in beiden Fällen eine Transaktion. Ohne das Feld bleibt die Ausgabe byte-gleich (Vorlauf, Linear, Kreis neu erzeugt: kein Diff). |
| H2 | `vorlauf-build.mjs` kennt MC (`basis.options`), MC-Teile (`parts[].options`) und `basis.figur.generator`; `exportiere.mjs` gibt MC-Optionen an den Blind-Löser | „keine/unendlich viele Lösungen“ und Termauswahl brauchen Auswahl; ohne Optionen im Export hätte der Blind-Löser die Auswahl nicht gesehen. Kein neues Antwortformat: MC und mc-Teile gibt es im Bestand (`term_binom_*`, `gleichung_modellieren`). |
| H3 | Versionen zentral beim Anlegen der Platzhalter per UTC-Zeit vergeben (20261003104943 … 104951), Einspielreihenfolge = Versionsreihenfolge | Auftrag; keine Kollision in Prod-Historie und Git geprüft. |
| H4 | Keine Voraussetzung aufgefüllt | Alle beteiligten Fundament-Knoten tragen (≥ 5 ready, Rang 1+2, known_errors). TERM-Knoten haben formatbedingt keine known_errors (Befund), `fkt_linear_*`/`term_einsetzen` sind Drafts anderer Läufe. |
| H5 | Zentrale Fehlbild-Liste: 17 neue Slugs, Familie nur `gleichungen_umformen` (LGS) sonst NULL | Muster Kreis/Binom; alle 17 werden verwendet, jeder in ≥ 3 Aufgaben. |
| H6 | Wiederverwendung über die phase1-Liste hinaus erlaubt, wenn der Slug in Prod existiert und sein Klartext passt | Die Themen haben sechs weitere Alt-Slugs genutzt (`falsche_groesse_beantwortet`, `falsche_gegenoperation`, `bedingung_unvollstaendig`, `seiten_verwechselt`, `multipliziert_statt_dividiert`, `halbieren_vergessen` bei Winkeln u. a.); unverändert gelassen. |
| H7 | Prüfskripte mit psql-Variable `lokal` | Lokal fehlen 52 Alt-Slugs (Datenimport) und `skill_clusters`; mit `-v lokal=true` entfallen genau diese Prüfungen, gegen Prod läuft alles. |
| H8 | Einstiege (Teil 3) nach Abschlussgröße, gemessen in der Wegwerf-DB | siehe unten |
| H9 | Stochastik: „in Prozent“ akzeptiert die nackte Prozentzahl, wenn > 1 | Blind-Abgleich: zwei Löser schrieben bei der Tombola „20“; das Feld hat keine Einheit. Regel im Charge-Skript. |

## Teil 3 – Einstiege

| thema_key | Einstiegsknoten | Abschluss | Grund |
|---|---|---|---|
| `lineare_gleichungen_lgs` | `gleichung_lgs_einsetzen`, `gleichung_lgs_addition`, `gleichung_lgs_grafisch` | 13, 13, 14 | drei verschiedene Lösungswege; gleichsetzen ist Sonderfall des Einsetzens (Breite), Sachaufgabe ist Anwendung |
| `zufallsexperimente` | `stoch_pfad_summe` | 10 | umfasst Produktregel, Gegenereignis, Laplace; ein zweiter Einstieg wiederholte nur Knoten aus diesem Abschluss |
| `flaechen_vielecke` | `geo_flaeche_trapez`, `geo_flaeche_drachen_raute`, `geo_flaeche_term` | 5, 5, 12 | zwei Grundfälle (Muster Kreis) und der eigene Term-Strang; zusammengesetzt und Rückrichtung sind Anwendung |
| `winkel_dreiecke` | `geo_winkel_dreieck` | 4 | Abschluss enthält alle Winkelknoten und `geo_winkel_summe` |
| `thales_konstruktionen` | `geo_winkel_thales` | 5 | einziger rechnerischer Knoten; Konstruktionen haben keine Knoten |

`stoch_kenngroessen` ist kein Einstieg: Median/Quartile sind Daten, nicht Zufall (Katalog:
`daten_streumasse` Kl. 5, `statistik_beurteilen` Kl. 9). Die Einstiege wirken erst, wenn ein
Einstiegsknoten ready-Aufgaben hat (`lsa_select_next_core`).

## Je Thema (Kurzfassung)

- **LGS:** 5 Knoten (`gleichung_lgs_einsetzen` 7, `_gleichsetzen` 8, `_addition` 8, `_grafisch` 8,
  `_sachaufgabe` 9), 13 Kanten, zusätzlich `term_einsetzen` als Voraussetzung der Rechenverfahren
  (Rückeinsetzen). Lösungen MULTI_PART x | y; Lösungsanzahl als MC; Sachknoten MULTI_PART mc | x | y.
  5 Figuren `koordinatensystem` mit zwei Geraden.
- **Stochastik:** 5 Knoten (`stoch_kenngroessen` 4, `_laplace` 5, `_gegenereignis` 6,
  `_pfad_produkt` 6, `_pfad_summe` 7), 9 Kanten; Kante `kenngroessen → vorzeichen_add_sub`
  (Temperaturreihe), `pfad_summe → gegenereignis` statt `→ bruch_add`. Quartile nur mit Reihen,
  für die alle Schul-Definitionen denselben Wert liefern. Keine Figuren.
- **Flächen:** 5 Knoten (`geo_flaeche_trapez` 5, `_drachen_raute` 5, `_zusammengesetzt` 6,
  `_term` 6, `_rueck` 6), 9 Kanten; Parallelogramm steckt schon in `geo_flaeche_dreieck`, deshalb
  als Rückrichtung. Terme als MC bzw. NUMERIC (nie TERM). Keine Figuren (kein Polygon-Generator).
- **Winkel/Thales:** 4 Knoten (`geo_winkel_neben_scheitel` 2, `_parallelen` 3, `_dreieck` 4,
  `_thales` 5), 5 Kanten; 2 Figuren `winkel`, sonst Text. Keine Konstruktionen.
