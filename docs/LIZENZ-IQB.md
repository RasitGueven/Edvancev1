# Lizenzlage IQB / VERA-8 — Grafiken

**Status:** verbindlich. Gilt fuer jedes Script, jeden Import und jeden Agenten,
der VERA-8-Material anfasst.

Die VERA-8-Items des IQB stehen unter CC BY 4.0. **Das gilt aber nicht
automatisch fuer die eingebetteten Grafiken.** Der IQB lizenziert pro Item
explizit, was gedeckt ist — und schliesst Grafiken in einem Teil der Items
bewusst aus.

## 1. Die einzige gueltige Rechtequelle

Massgeblich ist **allein der eingebettete Lizenzhinweis pro Item**. Er liegt in
jedem Aufgaben-Docx als eigene EMF-Datei (im Manifest `typ: "license"`) und
rendert den Copyright-Block. Sein Wortlaut variiert pro Item:

| Wortlaut im Lizenzhinweis | Bedeutung |
|---|---|
| `Copyright Text, **Grafik** und Teilaufgaben: IQB e.V.` | Grafik ist gedeckt — verwendbar |
| `Copyright Text und Teilaufgaben: IQB e.V.` (ohne "Grafik") | Grafik ist **NICHT** gedeckt — nicht verwendbar |
| kein Lizenzhinweis vorhanden | ungeklaert — **fail closed**, nicht verwenden |

Pruefregel: Text des license-EMF extrahieren (UTF-16LE) und auf das Wort
`Grafik` pruefen. Fehlt es, ist die Grafik des Items fremd oder ungeklaert und
darf **nicht hochgeladen, nicht verknuepft und nicht ausgespielt** werden.

## 2. `lizenz_status` ist FALSCH und darf nicht verwendet werden

Das Feld `lizenz_status` in `data/vera8_komplett_enriched.json` traegt fuer
**alle** Items denselben pauschalen Wert:

```
"CC BY 4.0 (IQB/VERA-8) — Attribution erforderlich;
 kommerzielle Nutzung geklaert (Rasit, 10.07.2026)"
```

Dieser Wert ist fuer Grafiken **pauschal und nachweislich falsch**: Er steht
auch bei Items, deren eigener Lizenzhinweis die Grafik ausdruecklich ausnimmt
(z. B. *Messzylinder*, *Bahncard*, *Kugeln ziehen*).

> **Kein Script und kein Agent darf `lizenz_status` als Rechtegrundlage fuer
> Grafiken heranziehen.** Wer es tut, veroeffentlicht fremde Grafiken.

Das Feld beschreibt bestenfalls die Textlizenz. Fuer Grafiken gilt
ausschliesslich Abschnitt 1.

## 3. Bekannte Ausschluesse (Grafik NICHT gedeckt)

Items mit **verifizierter Grafik** (PNG-Raster oder `emf_graphic`), deren
Lizenzhinweis das Wort "Grafik" nicht enthaelt — Stand 13.07.2026, 12 Items:

| Item | Grafiken |
|---|---|
| Aufgabenreihen | 3 PNG |
| Bahncard | 3 PNG |
| Bestimme x | 1 PNG |
| Geld anlegen | 2 PNG |
| Jubilaeumsgeschenk | 3 PNG |
| Kugeln ziehen | 2 PNG |
| Messzylinder | EMF-Figur (handverifiziert, 84 Zeichenrecords) |
| Rot, gelb, gruen | 3 PNG |
| Schluessel | 1 PNG |
| Temperatur | 3 PNG |
| Werbelotterie | 3 PNG |
| Zwischen zwei Zahlen 2 | 2 PNG |

Diese Liste ist **nicht abschliessend**. Sie deckt nur Items ab, deren Grafik
bereits verifiziert ist. Die Regel aus Abschnitt 1 ist immer zur Laufzeit pro
Item anzuwenden — nicht diese Liste abzuschreiben.

*Bestimme x* und *Kugeln ziehen* sind bereits als Tasks importiert (Charge 1).
Das ist unkritisch, solange ihre Grafik nicht verwendet wird: `tasks.assets` ist
bei beiden leer (geprueft 13.07.2026). Ihre Grafiken duerfen auch spaeter nicht
nachgeruestet werden.

## 4. Warum das Manifest-Feld `typ` die Grafiken nicht findet

`data/vera8_assets_manifest.json` klassifiziert Medien als `emf_text`,
`emf_graphic`, `raster`, `license`. Das Feld ist fuer die Asset-Auswahl
**unbrauchbar** — in beide Richtungen:

- `emf_text` heisst nur "enthaelt Textrecords" (`is_pure_graphic()` verlangt
  *null* Text). Eine Zeichnung mit Achsenbeschriftung landet dort. *Quadrat im
  Gitter* hat 212 Zeichenrecords und ist als `emf_text` gefuehrt.
- `raster` heisst nicht "Figur". Die PNGs sind **Seitenfragmente**: z. B. ist
  `kreisfiguren/aufgabe_02.png` reiner Aufgabentext samt Antwortluecken, ohne
  jede Abbildung.

Asset-Auswahl braucht daher eine kuratierte, review-te Liste — keine Ableitung
aus `typ`.

## 5. Offener Punkt: Attribution (CC BY)

CC BY verlangt bei jeder Nutzung eine **Namensnennung der Quelle**. Aktuell gibt
es dafuer keinen Ausspielweg zum Client:

- `tasks.source` haelt die Quelle (`'VERA8_IQB'`).
- `lsa_public_assets()` whitelistet aber nur `url` und `alt`
  (`supabase/migrations/20260712100000_p01_datenvertrag.sql:197-212`).
- `lsa_question_payload()` gibt `source` nicht mit aus.

**Folge:** Sobald die erste IQB-Grafik ausgespielt wird, fehlt die
Attribution — CC BY ist dann nicht erfuellt. Zu klaeren, bevor Assets live
gehen. Optionen: Attribution ins `alt`/`caption`-Feld, eine eigene
`attribution`-Spalte in der Whitelist, oder ein statischer Quellenhinweis im
Aufgaben-UI.

Betrifft bereits jetzt `durchstich/derstern.png` im Bucket `task-assets`
(Grafik ist gedeckt, Attribution fehlt aber).
