# R7-9 · Texte alt → neu (Entwürfe für Lena)

Stand 20.10.2026. Alle neuen und geänderten Texte sind Entwürfe; Lena gibt sie frei. Kein Text sagt
„trägt“, „gemeistert“, „Ebene“, „Fundament“ oder ein Fachkürzel (INV-4 in beiden Namespaces grün).

## Bericht (Namespace `elternbericht`)

### Geändert

| Schlüssel | alt | neu |
|---|---|---|
| `s3.kicker` | Einordnung im Lernstoff | {{wessen}} Lernweg |

`s3.titel` („Auf vorhandenen Stärken aufbauen.“) bleibt.

### Neu

| Schlüssel | Text |
|---|---|
| `s3.kickerOhneName` | Lernweg |
| `s3.weg.intro` | Von links nach rechts der Weg durch den Lernstoff: was {{name}} schon hinter sich hat, wo der Unterricht gerade steht und was in Klasse {{klasse}} {{quelle}} noch kommt. |
| `s3.weg.introOhneName` | … was Ihr Kind schon hinter sich hat … (sonst gleich) |
| `s3.weg.quelle.schule` | laut Schulplan der Schule {{schulname}} |
| `s3.weg.quelle.schuleOhneName` | laut Schulplan der Schule |
| `s3.weg.quelle.klp` | nach dem Kernlehrplan NRW |
| `s3.weg.quelleAus.schule` | dem Schulplan der Schule {{schulname}} |
| `s3.weg.quelleAus.schuleOhneName` | dem Schulplan der Schule |
| `s3.weg.quelleAus.klp` | dem Kernlehrplan NRW |
| `s3.weg.legende.sicher` | sicher |
| `s3.weg.legende.uebung` | Übungsbedarf |
| `s3.weg.legende.offen` | noch nicht geprüft |
| `s3.weg.legende.linie` | sitzt schon, darauf baut es auf |
| `s3.weg.legende.unter` | baut direkt darauf auf |
| `s3.weg.legende.broeckelt` | hier hat es gebröckelt |
| `s3.weg.legende.kommt` | kommt noch |
| `s3.weg.zone.grundlagen` / `weiterfuehrend` / `aktuell` / `kommt` | Grundlagen / Weiterführend / Aktuell / Kommt noch |
| `s3.weg.zone.aktuellKlasse` | Klasse {{klasse}} · {{thema}} |
| `s3.weg.zone.aktuellKlasseOhneThema` | Klasse {{klasse}} |
| `s3.weg.zone.kommtSchule` | Klasse {{klasse}}, Schulplan |
| `s3.weg.zone.kommtSchuleNaechste` | Klasse {{klasse}} und {{naechste}}, Schulplan (nur Präsentation) |
| `s3.weg.zone.kommtKlp` | Kernlehrplan NRW, {{stufe}} (z. B. „Kernlehrplan NRW, Klasse 9/10“) |
| `s3.weg.zone.naechste` | Klasse {{klasse}} (Spalte der nächsten Klasse, nur Präsentation) |
| `s3.weg.unter.eine` | baut darauf auf |
| `s3.weg.unter.beide` | baut auf beiden Verfahren auf |
| `s3.weg.unter.mehrere` | baut auf diesen {{count}} Bereichen auf |
| `s3.weg.unter.zeile` | {{wie}} · {{stand}} |
| `s3.weg.stand.sicher` / `uebung` / `offen` | sicher / Übungsbedarf / noch nicht geprüft |
| `s3.weg.spaeter` | Stoff aus Klasse {{klasse}} |
| `s3.weg.hier` | Sie sind hier · {{monat}} |
| `s3.weg.hierOhneMonat` | Sie sind hier |
| `s3.weg.hinweis` | Was worauf aufbaut, stammt aus unserem Voraussetzungsgraphen zum NRW-Lehrplan, die Reihenfolge der kommenden Themen aus {{quelle}}. Beides beschreibt den Lernstoff, keine Vorhersage. Nicht geprüfte Bereiche klären wir in den ersten Sitzungen. |

**Bitte prüfen:**
- „baut auf beiden Verfahren auf“ steht so im Bauauftrag. Es passt bei den Gleichungssystemen, nicht aber bei
  Batus echten Daten in Geometrie: Dort baut „Zusammengesetzte Vielecke“ auf Trapez und Drachen/Raute auf, und
  das sind keine Verfahren. Vorschlag: „baut auf beiden auf“.
- `s3.weg.unter.mehrere` (drei und mehr Basen) und `s3.weg.spaeter` stehen nicht im Auftrag; sie werden gebraucht.
- Die Quelle steht als „Schulplan der Schule {{schulname}}“, weil der Artikel vor einem Schulnamen
  wechselt (am Gymnasium, an der Gesamtschule). Im Entwurf stand „am Friedrich-Wilhelm-Gymnasium“ und „Schulplan
  FWG“; Abkürzungen der Schule gibt es nicht in den Daten, und Abkürzungen sollen weg.

## Präsentation (Namespace `praesentation`)

### Geändert (Anhang A, in INV-4.11 einzeln gelistet)

| Schlüssel | alt | neu |
|---|---|---|
| `leiste.station.3` | Einordnung | Lernweg |
| `s3.kicker` | Einordnung | Lernweg |

Der Titel der Station kommt aus `elternbericht:s3.titel` („Auf vorhandenen Stärken aufbauen.“); `s3.titel`
der Präsentation bleibt (Anhang A) ungenutzt stehen.

### Neu

| Schlüssel | Text |
|---|---|
| `s3.weg.desc` | Ziehen Sie die Fläche nach links in die Grundlagen und nach rechts in das, was laut {{quelle}} noch kommt. |
| `s3.weg.quelle.schule` | Schulplan der Schule {{schulname}} |
| `s3.weg.quelle.schuleOhneName` | Schulplan der Schule |
| `s3.weg.quelle.klp` | Kernlehrplan NRW |
| `s3.weg.abspielen` | Weg abspielen |
| `s3.weg.abspielenAria` | Lernweg noch einmal aufbauen |
| `s3.weg.buehneAria` | Lernweg, waagrecht verschiebbar |
| `s3.weg.zonenAria` | Zonen des Lernwegs |
| `s3.weg.info.eintrag` | {{label}} · {{stand}}. |
| `s3.weg.info.ziele` | Darauf baut auf: {{liste}}. |
| `s3.weg.info.basis` | Baut auf {{basis}} auf, und das sitzt. |
| `s3.weg.info.offen` | Das klären wir in den ersten Sitzungen. |
| `s3.weg.info.naechstes` | {{titel}} · kommt als Nächstes. |
| `s3.weg.info.spaeter` | {{titel}} · kommt in Klasse {{klasse}}. |
| `s3.weg.info.kommtBasis` | Baut auf, was schon sitzt: {{liste}}. |
| `s3.weg.info.leer` | Tippen Sie auf einen Bereich, um zu sehen, worauf er aufbaut und was darauf aufbaut. |

Legende, Zonen, ↳-Unterzeilen und Schild nimmt die Präsentation aus `elternbericht` (dieselben Schlüssel wie der Druck).
