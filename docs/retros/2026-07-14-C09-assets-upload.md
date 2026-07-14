# C09 — Die Abbildungen der Pool-Items in den Bucket

**Datum:** 2026-07-14 · **Branch:** `feat/C09-assets-upload`
**Script:** `scripts/upload-task-assets.ts` (`npm run assets:upload`)
**Bericht:** `data/c09_assets_report.json`

## Ausgangslage

C08 hat 380 Abbildungen als Verweis in `tasks.assets` gesetzt, aber keine einzige
Datei hochgeladen. Die URLs waren lokale Dateipfade
(`data/r01_render/<slug>/<datei>.png`) — der Browser kann die nicht auflösen, im
Autoren-Tool war jedes Bild kaputt.

## Was gemacht wurde

Für die **pool-fähigen Items** (`poolReadyAfterCare` aus
`scripts/content/vera8Draft.ts` — 138 Items, dieselbe Definition, die C08 für
seinen Bericht benutzt, hier bewusst **nicht** zweitdefiniert):

- **157 Abbildungen** in 70 Items in den Bucket `task-assets` geladen,
  deterministisch unter `lsa/<slug>/<datei>.png`.
- Die 157 URLs in `tasks.assets[].url` auf die **Public URL** umgeschrieben.
- Alle 157 URLs per HTTP-HEAD nachgeprüft: liefern ein Bild aus (200, `image/*`).

Der Bucket ist public (`storage.buckets.public = true`) — also Public URLs, kein
Signieren. Das Script bricht ab, falls der Bucket jemals privat wird, statt tote
URLs zu schreiben.

## Die Lizenz-Regel — das Zentrale

Hochgeladen wird eine Abbildung **nur**, wenn der pro Item eingebettete
Lizenzhinweis das Wort „Grafik" trägt (`docs/LIZENZ-IQB.md` §1). Das wird im
Script **gegen die Quelle neu geprüft**, nicht dem DB-Stand geglaubt: Ein
DB-Verweis, zu dem sich in `vera8_v2.json` kein gedecktes Asset finden lässt,
wird übersprungen (fail closed). Das pauschale Feld `lizenz_status` ist für
Grafiken nachweislich falsch und wird nirgends herangezogen.

**93 Abbildungen in 67 Pool-Items** sind dadurch draußen (im Gesamtkorpus: 210).
C08s Entscheidung wurde nicht revidiert.

Befund am Rande: Der Lizenzhinweis hängt am **Item**, nicht am einzelnen Bild.
Deshalb ist die Menge sauber zweigeteilt — 71 Items sind vollständig gedeckt, 67
vollständig ungedeckt, **kein einziges gemischt**.

## Stand danach

| | Items |
|---|---|
| pool-fähig (nach Pflege) | 138 |
| davon vollständig sichtbar (alle Abbildungen online bzw. gedeckt) | **70** |
| davon ohne Abbildung, weil Lizenz sie nicht deckt | 67 |
| offen: Verknüpfung fehlt (siehe unten) | 1 |

Die 67 sind nicht kaputt — sie tragen gar keinen Bildverweis und rendern als
reiner Text. Ob ein Item ohne seine Abbildung überhaupt lösbar ist, ist eine
inhaltliche Frage für die Pflege, keine technische.

## Offene Punkte

- **„Ecken an Pyramiden" (`ready`)** trägt in der DB kein Asset, obwohl die Quelle
  eine lizenzrechtlich gedeckte Abbildung kennt. Ursache: Die Zeile stammt aus
  C03; C08 fasst vorhandene Zeilen nicht an. Das Script hat sie **nicht still
  nachgezogen** — ein Bild an ein bereits freigegebenes Item zu hängen, ist eine
  inhaltliche Entscheidung. Ein Mensch entscheidet.
- **Attribution (CC BY)** bleibt offen — unverändert der Punkt aus
  `docs/LIZENZ-IQB.md` §5: `lsa_public_assets()` whitelistet nur `url` und `alt`,
  eine Quellenangabe hat keinen Ausspielweg zum Client. Mit diesem Lauf gehen die
  ersten IQB-Grafiken in Menge live — **vor dem Ausspielen an Kinder zu klären**.
- Im Bucket liegen aus C04 noch `vera8/*` (6 handgecroppte PNGs) und
  `durchstich/derstern.png` — **unverknüpft**, kein Task zeigt darauf. Sie stammen
  aus der alten Extraktion und sind durch die `lsa/`-Renders abgelöst.

## Was das Script nicht tut

Keine Migration, kein Item auf `ready` (Statusverteilung vorher/nachher identisch:
13 `ready`, 285 `draft`, 1 `review`), **keine generierten Alt-Texte** (alle bleiben
`""` — die schreibt ein Mensch im Tool, sie blockieren die Freigabe), und keine
Items außerhalb der Pool-Menge: die 222 Abbildungen der Nicht-Pool-Items stehen
unverändert als lokaler Pfad in der DB.

Idempotent: Der zweite Lauf lädt 0 Bilder und schreibt 0 URLs um.
