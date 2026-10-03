# K8-Rest · Thema 4 Thales und Winkelsätze (`winkel`) – Entscheidungen

Stand 03.10.2026 · Grundlage `docs/k8-rest/phase1.md` (verbindlich) und der Themenblock des Hubs.
Live-Graph über `~/bin/dbread` gelesen: `geo_winkel_summe` (Kl. 7, Tiefe 3) hat genau eine Kante
(→ `dezimal_add_sub`, Tiefe 1), keine Ahnen darüber hinaus.

## Knotenschnitt und Tiefen

| skill_key | label | Tiefe | direkte Voraussetzungen |
|---|---|---|---|
| `geo_winkel_neben_scheitel` | Neben- und Scheitelwinkel | 2 | `dezimal_add_sub` (1) |
| `geo_winkel_parallelen` | Stufen- und Wechselwinkel an Parallelen | 3 | `geo_winkel_neben_scheitel` (2) |
| `geo_winkel_dreieck` | Winkel in Dreiecken (Basiswinkel, Außenwinkel, Winkelsätze kombiniert) | 4 | `geo_winkel_summe` (3), `geo_winkel_parallelen` (3) |
| `geo_winkel_thales` | Satz des Thales (Winkel berechnen) | 5 | `geo_winkel_dreieck` (4) |

- **Vorschlag des Hubs unverändert übernommen** (vier Knoten, keinen fünften). Ein eigener
  Außenwinkel-Knoten hätte nur einen Satz (Nebenwinkel des Innenwinkels) und keine sechs
  unterschiedlichen Aufgaben getragen; er steckt in `dreieck`.
- `geo_winkel_summe` bleibt unverändert, keine Kante vom Bestand auf die neuen Knoten (Prüfskript).
- Tiefe = 1 + tiefste direkte Voraussetzung, jede Kante echt flacher (Prüfskript, auch rechnerisch).

## Kanten (5)

Gesetzt: siehe Tabelle, jede Kante in der Migration mit einem Satz begründet.
Bewusst **nicht** gesetzt (transitiv erreichbar, gegen den Live-Graphen geprüft):
`parallelen → dezimal_add_sub`, `dreieck → dezimal_add_sub` (über `geo_winkel_summe`),
`dreieck → neben_scheitel` (über `parallelen`), `thales → geo_winkel_summe` (über `dreieck`).
Keine bewusst transitive Kante. Keine Kante zu `geo_kreis_*` (Kl. 9, Tiefe 6/7, nicht flacher;
Thales braucht nur die Begriffe Durchmesser/Radius, die im Text erklärt sind).

## Fehlbilder

- Neu (Text wörtlich aus phase1 d, maschinell gegen die Tabelle verglichen, Familie NULL,
  `freigegeben_am` NULL): `winkelbeziehung_verwechselt` (11 Aufgaben),
  `basiswinkel_falsch_zugeordnet` (5), `rechter_winkel_falsche_ecke` (3),
  `aussenwinkel_verwechselt` (3). **`aussenwinkel_verwechselt` wird angelegt**, weil drei
  Außenwinkel-Aufgaben gestellt werden (dreieck-02, -04, -06).
- Wiederverwendet: `summe_360_statt_180` (10), `differenz_vergessen` (4) – im Bestand-Sinn von
  `geo_winkel_summe` (bekannte Winkel addiert statt von der Summe abgezogen).
- **Abweichung:** zusätzlich `halbieren_vergessen` (5, Bestand `geo_flaeche_dreieck`, in Prod
  vorhanden) für „Rest für zwei gleich große Winkel nicht halbiert“ (Basiswinkel, Scheitelwinkel-
  Paar). Kein neuer Slug nötig; phase1 nennt ihn bei Flächen, die Bedeutung ist dieselbe.
- `summe_180_statt_360` nicht verwendet: keine Aufgabe mit Vollwinkel 360° in dieser Charge.
- Kein Slug für „richtige Beziehung, falscher Winkel abgelesen“ (etwa β statt α angegeben); solche
  Werte stehen bewusst **nicht** in known_errors, statt sie einem unpassenden Slug zuzuordnen.

## Aufgaben und Formate

- 24 Aufgaben, je sechs pro Knoten: vier Anwendung (I, I, II, II), zwei Sachkontext oder
  Rückrichtung (Leiter, Straßenkreuzung, Bahnschienen, Zaunlatten, Satteldach, Halbkreisfenster;
  Rückrichtung dreieck-06, thales-06 als AFB III). Keine Personen, keine Marken, keine Konstruktion.
- **Alle NUMERIC**, `unit` `°`, ganzzahlige positive Grad. MC/MULTI_PART nicht nötig: das
  Erkennen der Beziehung steckt in den Aufgaben ohne genannte Beziehung (neben-03/-04,
  parallel-03 bis -06), deren Text die Lage eindeutig festlegt (oberhalb/unterhalb von g bzw. h,
  links/rechts von s; bei Zaun und Schienen über „zwischen den Latten/Schienen“ und „Seite des Weges“).
- `correct_answers`: `n`, `+n`, `n °`, `n°`, `+n °`, `+n°` (kein Komma nötig, keine Negativwerte).
  `known_errors` in denselben sechs Schreibweisen je falschem Wert.
- Lösungswege nennen die Beziehung ausdrücklich (Stufen-/Wechsel-/Nebenwinkel, Basiswinkel,
  Thales), damit Lena den Weg prüft und nicht nur das Ergebnis.

## Figuren

- Zwei Aufgaben mit Generator `winkel` (`neben-01`: 50°, `neben-02`: 115°, `benennung` α,
  `mit_bogen` true): Dort ist die Situation wirklich ein einzelner Winkel, die Gradzahl steht nur
  im Bild. Gerendert mit `exportiere.mjs`, PNGs angesehen: Schenkel, Bogen, Gradzahl und α lesbar,
  der Bogen liegt beim stumpfen Winkel innen.
- Parallelen, Dreiecke und Thaleskreise: reiner Text (kein Generator kann sie zeichnen).

## Sondierrang (aus vorlauf-build)

- neben_scheitel: neben-01 = 1 {summe_360, winkelbeziehung}, neben-04 = 2 {halbieren, winkelbeziehung}
- parallelen: parallel-05 = 1 {summe_360, winkelbeziehung}, parallel-02 = 2 {winkelbeziehung}
- dreieck: dreieck-01 = 1 {basiswinkel, halbieren, summe_360}, dreieck-06 = 2 {aussenwinkel, differenz}
- thales: thales-05 = 1 {differenz, rechter_winkel}, thales-04 = 2 {basiswinkel, halbieren}

## Prüfskripte

- psql-Variable `lokal` wie im Kreis-Muster (`cluster_pflicht`): mit `-v lokal=true` entfallen
  `cluster_id` und „wiederverwendete Alt-Slugs vorhanden“. Beide Skripte rein lesend (kein
  begin/rollback mit update wie im Linear-Skript), laufen deshalb auch mit `dbread`.

## Offene Punkte / Befunde

1. **Parallelen-Knoten hat ein schmales Fehlbildprofil:** Rang 2 ist nur {winkelbeziehung}. Mehr
   gibt der Stoff ehrlich nicht her; ein Slug „falscher Winkel gewählt“ (z. B. Stufenwinkel an der
   falschen Seite von s) fehlt im Katalog. Vorschlag für einen späteren Lauf, kein Ad-hoc-Slug.
2. **Kein Generator für Parallelen mit Schnittgerade, Dreieck oder Thaleskreis.** Für die Schüler
   ist eine Skizze bei Lagebeschreibungen (oberhalb/rechts von s) eine echte Hilfe; die
   Text-Aufgaben sind lösbar, aber lesehaltig. Befund für einen Figuren-Lauf.
3. `differenz_vergessen`, `summe_360_statt_180`, `halbieren_vergessen` haben in Prod weiterhin
   keinen Klartext (Altbestand, nicht angefasst; offener Punkt aus specs/active/fehlbild-labels-eltern.md).
4. `summe_180_statt_360` und `aussenwinkel_verwechselt` (über drei Aufgaben hinaus) bleiben dünn;
   Vollwinkel-Aufgaben (360° um einen Punkt) wären ein natürlicher Ausbau von `neben_scheitel`.
5. Blind-Lösung (Hub): frischer Subagent, 24/24 = 100 %, 0 unsicher, auch parallel-05 und dreieck-03
   eindeutig gelöst → `docs/prefill/k8-winkel-blind.json`. Anmerkung des Lösers: In beiden
   `winkel`-Figuren steht das Label α außerhalb des Bogens (Generator-Regel: Benennung auf der
   abgewandten Seite); nicht mehrdeutig.
