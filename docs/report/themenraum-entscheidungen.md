# Themenraum im Report — Entscheidungen (W5-d)

Stand 04.10.2026. Betrifft `lsa_finish`, `src/lib/report/themenraum.ts`, `suche.ts`,
`rueckbezug.ts`, den App-Lesepfad (`lsaReportErzaehlung.ts`) und den Entwurfs-Generator
(`scripts/report/`).

## Ausgangslage

#189 gliedert „Wie wir gesucht haben" nach dem Themenraum: Einstiegsknoten des Themas
(`thema_einstieg`), darunter ihr Voraussetzungsabschluss (`lsa_abschluss`), außerdem angesehen.
Zwei Lücken blieben:

1. **Rückbezug „Grundlagen fehlen"** (`rueckbezug.ts`, `strukturell`) zählte weiter alles mit
   kleinerer `fundament_tiefe` als „darunter geprüft" — auch Skills außerhalb des Themas. Bei einer
   Wurzel-Sitzung hätte eine Flächen-Aufgabe (Tiefe 3) die Vermutung „es fehlen Grundlagen"
   bestätigt. Das ist eine Ursachen-Behauptung außerhalb des Themenraums.
2. **Der Raum wurde bei jedem Öffnen aus den HEUTIGEN Tabellen gerechnet.** Seit K8–K10 ändern
   sich Kanten und Einstiege laufend; ein alter Report verschöbe sich nachträglich.

## Entscheidungen

### 1. Gespeichert wird in `result_summary.themenraum`, nicht in einer neuen Spalte

`{ thema_key, einstieg: [..], darunter: [..], stand }`. `result_summary` ist das Abschlussprotokoll
der Sitzung; der Raum gehört dazu. Eine Spalte hätte eine Tabellenänderung an `lsa_sessions`
gebraucht, ohne Mehrwert. Bestehende Felder bleiben byte-gleich: das neue Feld wird mit `||`
angehängt, nachdem `v_summary` unverändert gebaut ist (pgTAP: Sitzung mit und ohne Thema ergeben
bis auf `themenraum` dasselbe Objekt).

### 2. Die Definition steht einmal in SQL: `public.lsa_themenraum(thema_key)`

`darunter` = Vereinigung von `lsa_abschluss` über alle Einstiegsknoten **ohne die Einstiege selbst**
(bei Reelle Zahlen liegt `zahl_wurzel_irrational` unter `zahl_wurzel_teilweise`, ist aber selbst
Einstieg — er gehört zu Block 1, nicht zu den Grundlagen). Listen sortiert, damit derselbe Stand
byte-gleich gespeichert wird. Nur `service_role` darf sie ausführen, wie `lsa_abschluss`.
Die TS-Rückfallrechnung (`berechneThemenraum`) ist dieselbe Definition; ein Test rechnet den Graphen
aus dem pgTAP-Test nach.

### 3. `lsa_finish` wird nur erweitert

Kein Eingriff in `lsa_grade`, `lsa_is_correct`, `lsa_select_next_core`, `lsa_start` oder die
Urteilsbuchung. Der Basis-Körper ist md5-gleich mit Prod (`5fd50087…`) übernommen. Eine schon
abgeschlossene Sitzung gibt weiterhin ihr gespeichertes `result_summary` unverändert zurück —
dort wird nichts nachgeschrieben, denn `stand` wäre dann nicht der Abschlusszeitpunkt.

### 4. Nachtrag als eigene Migration, gekennzeichnet

Alte abgeschlossene Sitzungen mit `thema_key` bekommen den Raum aus dem Stand am Tag des Nachtrags,
`stand = 'nachgetragen'`. Nur wo das Feld fehlt; ein zweiter Lauf trifft 0 Zeilen. Prod am
04.10.: 0 abgeschlossene Sitzungen mit Thema — die Migration ist trotzdem nötig für jede Sitzung,
die zwischen jetzt und dem Einspielen von Teil 1 abgeschlossen wird (Reihenfolge: Funktion, dann
Nachtrag). Die Trigger auf `lsa_sessions` hängen an `UPDATE OF status` und laufen nicht mit.

**Parallel W5-b** schließt die Sitzung 4ebe9d9c über `lsa_finish`. Sie hat kein `thema_key`, bekommt
also in keiner Reihenfolge ein Feld; wäre es anders, fängt der Nachtrag sie auf.

### 5. Report: gespeichert bevorzugt, sonst berechnet

`themenraumFuer` nimmt `result_summary.themenraum`, wenn es zur Sitzung passt (`thema_key` gleich,
beide Listen Textlisten, `stand` gesetzt). Sonst — fehlt oder kaputt — rechnet es wie #189 aus
`thema_einstieg` + `skill_kante`; die werden im App-Pfad dann erst geladen. Ohne `thema_key` gibt es
keinen Raum (`null`), auch wenn ein Feld da wäre. Die Herkunft (`abschluss` / `nachgetragen` /
`berechnet`) steht im Typ und in der Konsolenzeile des Generators, nicht im Elterntext.

### 6. „Grundlagen fehlen" nur über `themenraum.darunter`

- `strukturell` zählt ausschließlich geprüfte Skills in `raum.darunter`. Entlastend bei keiner
  Lücke (schmal unter zwei Bereichen), bestätigend sonst; „mitte" vs. „durchgehend" entscheidet die
  tiefste geprüfte Lage **innerhalb** des Raums.
- Skills außerhalb des Raums kommen im Rückbezug nicht vor. Sie stehen in Abschnitt 02 unter
  „außerdem angesehen", ohne Ursachen-Satz.
- **Ohne Thema** gibt es keinen Raum, also auch keine Grundlagen des Themas: der Rückbezug lautet
  `grundlagen_offen`. Das ist eine Verhaltensänderung für alte Sitzungen ohne `thema_key` (vorher:
  Ebenen-Logik). Bewusst — sie war genau die Ursachen-Behauptung, die #189 in Abschnitt 02 schon
  abgeschafft hat, und Fazit und Abschnitt 02 widersprächen sich sonst.
- Die übrigen Rückbezüge (`Textverständnis` über `gleichung_modellieren`, Familien) bleiben
  unverändert: sie sind direkte Belege an einem genannten Skill, keine Abstiegs-Aussage.

### 7. `generate_parent_report` bleibt unverändert

Die Edge Function liest `screening_tests` (alte Screenings), nicht `lsa_sessions`, und baut keine
Suche oder Rückbezüge. Es gibt dort keinen Themenraum, den sie lesen könnte. Druck/PDF des
LSA-Reports ist der Druck von `ReportBody` (App-Pfad) bzw. der HTML-Entwurf aus
`scripts/report/` — beide laufen über `themenraumFuer`.

## Belege

- pgTAP `supabase/tests/lsa_finish_themenraum.test.sql` — 17/17 lokal (Wegwerf-DB aus allen
  Migrationen, pgTAP 1.3.4 aus dem Paket geladen).
- Vitest `src/lib/report/themenraum.test.ts` — Fixtures a–d.
- Prüfskript nach dem Einspielen: `supabase/checks/report_themenraum.PRUEFUNG.sql` (read-only);
  lokal gegengeprüft: rot bei fehlendem Raum, grün nach Nachtrag.
- Screenshots: `docs/report/w5-d/themenraum-fall-a.png`, `themenraum-fall-d.png`.

## Offen

- Die abgenommenen Rückbezug-Bausteine (`grundlagen_*`) sprechen noch von „tragen" und „Ebenen".
  Inhaltlich passen sie (sie beziehen sich auf „unterhalb des aktuellen Themas"), sprachlich nicht
  zur Regel „sicher / noch nicht sicher" — Neufassung über die Baustein-Abnahme.
- `inhaltsbereiche.ts` kennt `zahl_wurzel_*` nicht; die Quadratwurzel steht unter „Weitere Bereiche"
  (siehe Screenshot d).
