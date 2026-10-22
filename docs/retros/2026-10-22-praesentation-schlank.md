# Retro 22.10.2026 · PS-1 Tablet-Präsentation schlank

Bauauftrag: `docs/report/praesentation/Bauauftrag-PS-1.md`. Branch
`feat/rasit-praesentation-schlank`, zwei Commits (01/02/04, dann die Kette in 03).

## Gebaut

- **Station 01:** nur Kicker, Kopfsatz, Anliegen (höchstens zwei Sätze) und die zwei
  Karten. Je Karte zwei Zeilen untereinander, dann „+n weitere“; mit
  Thema-Schwerpunkt steht die Startstelle in „Gezielt üben“ zuerst. `ueberblick()`
  liefert dafür jetzt alle Felder; gekürzt wird in der Karte.
- **Station 02:** zwei große Zahlen; „davon n übersprungen“ als kleine Zeile unter
  Übungsbedarf, Antippen öffnet den Erklärsatz. Profil mit höchstens vier Zeilen
  (`profilReihenfolge`: Feld der Startstelle, dann Schwerpunkte und „danach“, dann
  sichere Felder), Rest hinter „Alle Themenfelder zeigen“. Je Zeile ein Balken mit
  zwei Anteilen (übersprungen als Punktmuster im Übungsbedarf), kein „x von y“,
  Detail mit höchstens drei Bereichen je Liste.
- **Station 03:** Kette aus höchstens fünf Kästen (`kette.ts`, `Lernkette.tsx`,
  `station3-kette.css`) als Standard; „Ganzen Lernweg zeigen“ / „Zurück zum Weg“
  schaltet in derselben Station auf die unveränderte Bühne. Zurück ohne zweiten
  Aufbau.
- **Station 04:** höchstens drei Punkte, nur „Hier üben wir“ (Startstelle zuerst),
  kein „danach“, der Hinweis als Caption unter der Empfehlung.
- Daten: `TpSchwerpunkt.start/naechster`, `PraesentationDaten.thema` und
  `themaWeg` (Reihe und direkte Kanten im Themenraum, mit `themaReihenfolge` aus
  schwerpunkte.ts gerechnet — dieselbe Reihenfolge wie im Bericht).

## Entscheidungen im Bau

- **Basis über Kanten:** Die Kanten der Lernweg-Karte (`lernweg.linien`) sind nach
  den Grenzen gekürzt; die Kette nimmt deshalb die direkten Kanten aus
  `erzaehlung.kanten` (über `themaWeg`), nicht die gezeichneten Linien.
- **„Ohne Thema“** heißt: kein `bericht.thema` (themaAbdeckung). `lernweg.thema`
  ist auch bei nicht abgestuften LSA gesetzt und taugt dafür nicht.
- Der Knopf zur vollen Karte sitzt in der Kicker-Zeile und ragt über sie hinaus
  (`margin-block: -15px`), sonst wird die Bühne niedriger.
- Profilkarte in 02 endet nach ihrem Inhalt (vorher streckten sich die Zeilen über
  die freie Höhe, bei vier Zeilen im Hochformat ~200 px je Zeile).
- `station2-zahlen.css`, `station2-detail.css`, `index.css` und
  `e2e-praesentation/*.spec.ts` angepasst, obwohl der Umfang nur `station2.css`
  nennt: Es sind Teile derselben Station bzw. die Ansichtstests der Präsentation.

## Offen

- Kette mit weniger als drei Kästen: „Ihr Thema · sitzt“ ohne nächstes Thema steht
  allein (Fixture `abgestuftThemaSicher`); ohne Basis und ohne `naechster` sind es
  zwei Kästen (Startstelle, Thema). Siehe Fotos `abgestuftThemaSicher_*`.
- `naechstesThema` (leads.next_exam_topic) ist in keiner Thema-Fixture gesetzt; eine
  Kette mit fünf Kästen gibt es nur im Unit-Test.
- Fahrt-Tests in `lernweg.spec.ts` schwanken unter paralleler Last, auf dev
  genauso (3 von 6 Wiederholungen rot) — Gebiet von PF-1.
- Schlüssel, die nicht mehr angezeigt werden, bleiben wegen INV-4.11 (Anhang A
  wörtlich) in `praesentation.json`.
