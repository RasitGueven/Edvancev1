# LSA-V2 · Neue Texte für Lena

Stand 22.10.2026. Bauauftrag `docs/lsa/Bauauftrag-LSA-V2.md`, Entscheidung 14. Alle Texte stehen nur in i18n;
Änderungen bitte direkt dort oder als Kommentar am PR.

Anlass: Starke Kinder bekommen in der LSA einen **Ausblick** auf den Stoff, der als Nächstes kommt. Was dort noch
nicht sitzt, ist kein Übungsbedarf, sondern „noch nicht behandelt“. Es erscheint im Lernweg (Seite 3 und
Station 03) in „Kommt noch“ mit leerem Kreis. Was dort schon sitzt, hat den grünen Punkt wie jeder sichere Bereich.

| Wo | i18n-Schlüssel | Text | Wann sichtbar |
| --- | --- | --- | --- |
| Seite 3 und Station 03, Legende | `elternbericht:s3.weg.legende.vorgriff` | noch nicht behandelt | wenn im Lernweg ein Vorgriff steht, der noch nicht sitzt |
| Seite 3 und Station 03, Stand eines Eintrags (auch „↳ baut darauf auf · …“) | `elternbericht:s3.weg.stand.vorgriff` | noch nicht behandelt | Stand des Eintrags, z. B. in der Zeile unter einem Bereich |
| Seite 3, gekürzte Insel („+ 2 weitere …“) | `elternbericht:s3.weg.weitere.stand.vorgriff` | noch nicht behandelt | nur, wenn eine Insel in „Kommt noch“ gekürzt werden muss |
| Station 03, Info zum angetippten Eintrag | `praesentation:s3.weg.info.vorgriff` | Das kommt im Unterricht erst noch. Wir haben schon einen Blick darauf geworfen; dass es noch nicht sitzt, ist kein Übungsbedarf. | nach Tippen auf einen Vorgriff, der noch nicht sitzt |

Unverändert, aber zur Einordnung:

| Wo | i18n-Schlüssel | Text |
| --- | --- | --- |
| Legende, nicht geprüfte Bereiche | `elternbericht:s3.weg.legende.offen` | noch nicht geprüft |
| Station 02, „übersprungen“ | `praesentation:…uebersprungenHeisst` | Übersprungen heißt: Bei allen Aufgaben zu diesem Bereich hat {{name}} „Weiß ich nicht“ gewählt oder nichts eingetragen. … |

„Übersprungen“ bleibt richtig: Nach LSA-V2 ist ein „Weiß ich nicht“ bei der ersten Aufgabe sofort das Urteil
(eine Aufgabe, kein Zweitbeleg). „Bei allen Aufgaben zu diesem Bereich“ heißt dann: bei der einen.

## Fragen an Lena

1. „noch nicht behandelt“ oder „kommt im Unterricht noch“? Der kurze Text steht in Legende und Zeile; er soll
   nicht wie ein Versäumnis klingen.
2. Der Infotext in Station 03 ist für das Gespräch mit Eltern und Kind gedacht. Passt der Ton?
