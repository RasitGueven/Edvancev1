# Bericht v3 · Befund und offene Punkte (24.10.2026)

Auftrag: Nachbesserungen aus der Gründerrunde vom 24.10.2026. Baut auf v2 auf
(`docs/report/v2/offene-punkte.md`).

## Paket A: Voraussetzungsgraph

Befund in Prod (`skill_kante`, dbread, 24.10.2026):

| Erwartete Kante | Stand in Prod | Vorschlag (Migration `20261024143626_graph_wurzel_faktorisieren`, nicht eingespielt) |
|---|---|---|
| „Teilweise die Wurzel ziehen“ → „Der Satz des Pythagoras …“ | fehlt. `zahl_wurzel_teilweise` ist für **keinen** Skill Voraussetzung. Die Pythagoras-Skills setzen nur `zahl_wurzel_quadrat`, `geo_koordinaten` und sich gegenseitig voraus. | `geo_pythagoras_anwendung ← zahl_wurzel_teilweise` (Längen wie √72 = 6√2) |
| „Faktorisieren mit binomischer Formel“ → „Quadratische Funktionen“ | fehlt. `term_binom_faktorisieren` ist für **keinen** Skill Voraussetzung. Quadratische Funktionen setzen `term_binom_quadrat` und `term_einsetzen` voraus. | `fkt_quadr_nullstellen ← term_binom_faktorisieren` (Nullstellen über die faktorisierte Form) |

- **Warum nicht an anderen Stellen:**
  - `fkt_quadr_normalform` ← faktorisieren würde die bestehende Kante `normalform ← term_binom_quadrat` transitiv
    redundant machen. Das widerspricht der Konvention der Substrat-Migrationen.
  - Kein Kreis: Geprüft wurde, dass keine der beiden Lücken transitiv von ihrem neuen Nachfolger abhängt.
- **Wirkung über den Bericht hinaus:** `lsa_select_next_core` und die Mitbelegung lesen `skill_kante`. In der
  abgestuften LSA kann ein nicht sicherer Pythagoras- bzw. Nullstellen-Knoten danach auf diese Bereiche
  zurückgehen.
- **pgTAP:** Die Ergebnisse waren lokal mit und ohne die zwei Kanten identisch.
- **Report:** Er liest `skill_kante` live. Nach dem Einspielen bekommt Pythagoras bei Batu einen eigenen
  Themenblock („Teilweise die Wurzel ziehen“). „Faktorisieren“ steht dann bei Quadratische Funktionen statt unter
  „Weitere Bereiche“. Die PDFs v3-A/B sind mit beiden Kanten gerendert (Override im Harness, nicht im Code).
- **Ohne die Kanten (heutiger Stand)** zeigt Seite 3 nur Quadratische Funktionen und Kreise als Blöcke.
  Pythagoras erscheint nur als „betrifft auch“ bei „Punkte im Koordinatensystem“. „Teilweise die Wurzel ziehen“
  und „Faktorisieren“ stehen unter „Weitere Bereiche“. Seite 4 zeigt das Thema dann als „Vorhandene Lücke“ mit
  „weil im aktuellen Schulthema noch eine Lücke offen ist“.

## Offene Punkte

- **Telefonnummer:** weiterhin keine hinterlegt (`KONTAKT.telefon = null` in `berichtKonfig.ts`). Seite 5 nimmt
  dann den Satz ohne Anruf („schreiben Sie mir gern“).
- **Ziele-Feld:**
  - Neue Migration `20261024145154_bericht_v3_ziele` (nicht eingespielt) legt
    `lsa_report_notes.ziele_bestaetigt` an.
  - Bis dahin zeigt Seite 5 keine Ziele, auch nicht das Test-Zielbild „uhuzhuhuuh“.
  - Nach Bestätigung erscheint das Zielbild des Coachs, sonst der Systemvorschlag.
  - Der Ausblick braucht noch Schalter für „Ziele bestätigt“ und „Paket bestätigt“.
  - Systemvorschlag für Batu (Standard = 3 Schwerpunkte, dazu das Sorgfaltsmuster):
    1. Terme und Gleichungen sicher anwenden, bevor das Thema „Quadratische Funktionen“ beginnt
    2. Größen und Einheiten sicher anwenden, bevor das Thema „Kreise, Prismen und Zylinder“ beginnt
    3. Flächen und Figuren sicher anwenden, bevor das Thema „Kreise, Prismen und Zylinder“ beginnt
    4. Rechenwege sorgfältig zu Ende führen und Ergebnisse selbst kontrollieren
- **Halbjahre im Schulplan:** `schul_themenplan.halbjahr` ist beim FWG leer. Seite 3 zeigt deshalb keine
  Zeitangabe mehr.
- **Tablet-Link:** Eine Elternfassung gibt es nicht; die Präsentation läuft unter
  `/admin/report/:id?ansicht=praesentation` nur für Admins. Platz ist vorgesehen (`TABLET_LINK` in der
  Konfig), solange `null` erscheint nichts.
- **Klassenarbeits-Status:** weiterhin ohne Eingabefeld im Erstgespräch (Spalte aus der v2-Migration). Für Batu
  per Override „geschrieben“.
- **Layout Seite 3:** Variante B ist Standard (`EINORDNUNG_LAYOUT`). Die Wahl trifft ihr.
- **Gleiche Begründung auf Seite 4:** Der Graph trägt „weil Geometrie darauf aufbaut“ nicht; keine
  Geometrie-Lücke setzt die Größen voraus. Die Regel lautet daher: Bei gleichem kommenden Thema kommt das frühere
  Klassenband zuerst. Die Begründung nennt das Band („zuerst, weil es Stoff aus Klasse 5/6 ist“ / „danach, weil
  es Stoff aus Klasse 7/8 ist“).
