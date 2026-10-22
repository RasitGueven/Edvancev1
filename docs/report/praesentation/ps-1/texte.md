# PS-1 · Texte zur Freigabe (Lena)

Stand 22.10.2026. Nur Namespace `praesentation`; am Namespace `elternbericht` und
am Druckbogen ist kein Wort geändert (Entscheidung 2).

## Neu

| Key | alt | neu | wo |
| --- | --- | --- | --- |
| `s2.alleFelder` | – | Alle Themenfelder zeigen | Station 02, unter den ersten vier Profilzeilen |
| `s2.wenigerFelder` | – | Weniger Themenfelder zeigen | Station 02, derselbe Knopf aufgeklappt |
| `s3.kette.titel` | – | Der Weg zum Thema. | Station 03, Titel der Kette mit Thema |
| `s3.kette.titelFeld` | – | Der Weg zum Themenfeld. | Station 03, Titel der Kette ohne Thema (erster Schwerpunkt ist ein Themenfeld) |
| `s3.kette.etikett.basis` | – | Sitzt schon | Kasten a |
| `s3.kette.etikett.start` | – | Hier hakt es | Kasten b |
| `s3.kette.etikett.naechster` | – | Baut darauf auf | Kasten c |
| `s3.kette.etikett.thema` | – | Ihr Thema | Kasten d |
| `s3.kette.etikett.themaSitzt` | – | Ihr Thema · sitzt | Kasten d, wenn im Thema alles sicher ist |
| `s3.kette.etikett.feld` | – | Themenfeld | Kasten d ohne Thema |
| `s3.kette.etikett.kommt` | – | Kommt als Nächstes | Kasten e |
| `s3.kette.info.start` | – | Hier setzen wir zuerst an. | Satz beim Antippen von „Hier hakt es“, wenn kein Satz aus dem Lernweg passt |
| `s3.kette.info.naechster` | – | Baut direkt auf {{start}} auf. | Satz beim Antippen von „Baut darauf auf“ (`s3.weg.info.basis` sagt „und das sitzt“, das stimmt hier nicht) |
| `s3.kette.info.thema` | – | Darauf arbeiten wir hin. | Satz beim Antippen von „Ihr Thema“ |
| `s3.kette.info.themaSitzt` | – | Was wir in diesem Thema geprüft haben, sitzt schon. | Satz beim Antippen von „Ihr Thema · sitzt“ |
| `s3.kette.info.feld` | – | Die Bereiche davor gehören zu diesem Themenfeld. | Satz beim Antippen von „Themenfeld“ |
| `s3.kette.ganzerWeg` | – | Ganzen Lernweg zeigen | Station 03, Knopf zur vollen Karte |
| `s3.kette.zurueck` | – | Zurück zum Weg | Station 03, Knopf zurück zur Kette |

## Wiederverwendet (unverändert)

- Station 02: „davon {{count}} übersprungen“ bzw. „{{count}} übersprungen“ als kleine
  Zeile = `zaehlung.davonUebersprungen` / `zaehlung.uebersprungen`; der Erklärsatz
  beim Antippen = `s2.uebersprungenHeisst(OhneName)`; „+n weitere“ =
  `elternbericht:s1.blick.weitere`.
- Station 03, Sätze beim Antippen: `s3.weg.info.eintrag` („Bruch in Dezimalzahl ·
  sicher.“), `s3.weg.info.ziele` („Darauf baut auf: …“), `s3.weg.info.basis` („Baut
  auf … auf, und das sitzt.“, nur bei einer direkten Kante), `s3.weg.info.naechstes`
  („… · kommt als Nächstes.“); der Hinweis aufs Antippen = `s3.weg.info.leer`.

## Nicht mehr angezeigt (Schlüssel bleiben)

Diese Schlüssel stehen in Anhang A der Anforderung und werden von INV-4.11 wörtlich
geprüft; sie bleiben deshalb in `praesentation.json`, erscheinen aber nicht mehr:

| Key | Text | Grund |
| --- | --- | --- |
| `s1.lead.*` | „Was schon gelingt … sehen wir uns jetzt gemeinsam an.“ | Entscheidung 5 |
| `s1.fachKlasse`, `s1.imBlick` | „Mathematik · Klasse 10“, „Im Blick: …“ | Entscheidung 5 |
| `s1.weiter`, `s1.weiterOhneName` | „Weiterwischen, um … zu sehen“ | Entscheidung 4 (nur Titel, Anliegen, Karten) |
| `s2.untersucht` | „x von y Bereichen bis Klasse z untersucht.“ | Entscheidung 8 (bleibt im Druckbogen) |
| `s2.profilHinweis` | „Jedes Segment steht für eine Kompetenz · Antippen für Details“ | Entscheidung 1 (ein Hinweis je Station) und 9 (keine Segmente) |
| `s2.zeileZahl` | „{{untersucht}} von {{vorhanden}}“ | Entscheidung 9 |
| `s2.zahl.uebersprungen`, `s2.zahl.davonUebersprungen` | Beschriftung der dritten großen Zahl | Entscheidung 7 |
| `s4.sicher`, `s4.keinSicher` | „Sicher im Test“, „In diesem Themenfeld war noch nichts sicher.“ | Entscheidung 17 |

`s2.zeileAria*` (Vorlesetext je Profilzeile) nennt „x von y untersucht“ weiterhin; er
ist nicht sichtbar.
