# R7-8 · Offene Punkte und Messwerte

Stand 20.10.2026, Branch `feat/rasit-report-r7-seite2-klassen`. Seite 2 zeigt je Themenfeld die
Klassenstufen. Bei abgestufter LSA stehen die abgeleiteten Bereiche als Umriss-Kästchen da, und alle
Zeilen haben einen gemeinsamen Maßstab.

## Abnahme-Material

- Druck-Tests aller Fälle: `EB_PORT=5189 EB_AUSGABE=docs/report/r7/abnahme/r7-8 npx playwright test -c
  playwright.elternbericht.config.ts`: 24 von 24 grün, PDFs unter `docs/report/r7/abnahme/r7-8/<fall>.pdf`.
- Bildschirmfotos Seite 2 unter `fotos/`:
  - mit abgeleiteten: `seite2-abgestuft.png`, `seite2-abgestuftMitOffen.png`, `seite2-abgestuftLang.png`
  - ohne abgeleitete: `seite2-ilkay.png`, `seite2-weitereBereiche.png`

## Entscheidungen während des Pakets (Rasit, 20.10.2026)

1. **Klassen der abgeleiteten Bereiche in themaAbdeckung.** INV-4.3/4.11 verbietet den Bezeichner
   `skillKey` im Code des Bogens außer als React-key. Ein Katalog-Nachschlagen in der Komponente ginge
   nur mit ihm. Deshalb liefert `themaAbdeckung` neben `abgeleiteteSchluessel` auch
   `abgeleiteteBereiche: { feld, klasse | null }[]`. Das Feld kommt über `feldVon`, die Klasse aus dem
   Katalog, `null` ohne Eintrag. Seite 2 arbeitet nur damit. INV-4.11 bleibt unverändert.
2. **Spur 206 pt, sobald das Profil abgeleitete Bereiche hat.** Mit 226 pt lief die längste Zeile in
   den rechten Text. Bei `abgestuft` endete die Spur 4,4 pt hinter dem Textanfang von „4 geprüft ·
   5 abgeleitet“. 206 pt gelten dann für alle Zeilen des Profils, damit der Maßstab gleich bleibt.
   **Ohne abgeleitete Bereiche bleiben es 226 pt.**
   - Neuer Fall `abgestuftLang` (synthetisch): 12 geprüft und 14 abgeleitet in einer Zeile, also der
     längste mögliche rechte Text „12 geprüft · 14 abgeleitet“ in der längsten Zeile (26 Kästchen,
     Lücke 2 pt, Breite 6 pt).
   - Neue Druck-Prüfung in `e2e-druck/elternbericht.spec.ts` für alle Fälle: In jeder Profilzeile
     endet die Spur mindestens 6 pt vor dem rechten Text. Für `abgestuftLang` steht dort außerdem
     fest, dass der Text „12 geprüft · 14 abgeleitet“ wirklich vorkommt.
   - Gegenprobe mit 226 pt: rot in `abgestuft` (−4,40 pt), `abgestuftMitOffen` (−4,43 pt) und
     `abgestuftLang` (−6,13 pt). Mit 206 pt verschieben sich alle drei um 20 pt, auf rund +15,6,
     +15,6 und +13,9 pt.
   - `e2e-druck/**` und die Fixtures standen nicht im Umfang des Auftrags; beides kam auf Rasits
     Anweisung dazu.

## Messwerte Seite 2 (Chromium, Druck)

| Fall | Zeilen | Überlauf | Luft bis y 800 |
|---|---|---|---|
| abgestuft | 5 | nein | 45,5 pt |
| abgestuftMitOffen | 2 | nein | 192,5 pt |
| ilkay | 6 | nein | 24,7 pt |
| weitereBereiche | 7 | nein | 71,6 pt |
| alleFelder | 8 | nein | 50,6 pt |

- Die Klassenzeile endet bei höchstens 38 pt, die Spur beginnt bei 165 pt.
- Die Unterkante der Klassenzeile liegt bei 22 pt, die Trennlinie bei mindestens 25,8 pt. Die
  Zeilenabstände (40,8 / 33,4 / 30 pt) bleiben unverändert.
- Legende: Der dritte Eintrag steht bei x 147,4 pt, gemessen am Textende von „Übungsbedarf“ (129,1 pt)
  plus derselbe Abstand wie zwischen den ersten beiden (41,6 → 59,9 pt).

## Gegenrechnung Batu Test1 (6220b7e8, dbread 20.10.2026, nur lesend)

Thema „Reelle Zahlen und Wurzeln“: 14 Bereiche, 5 direkt, 9 abgeleitet, 0 offen. Der Thema-Satz
stimmt mit den Umrissen überein (Summe 9). Maßstab: 9 Kästchen, Spur 206 pt, Breite 19,33 pt, Lücke 4 pt.

| Feld | geprüft | sicher | Übungsbedarf | abgeleitet | Klasse |
|---|---|---|---|---|---|
| Brüche & Dezimalzahlen | 1 | 1 | 0 | 4 | 5–6 |
| Terme & Gleichungen | 3 | 2 | 1 | 0 | 8 |
| Geometrie | 4 | 0 | 4 | 0 | 8 |
| Zahlen & Rechnen | 4 | 1 | 3 | 5 | 5–9 |
| Daten & Zufall | 1 | 0 | 1 | 0 | 8 |

Hinweis: In Prod hat Batu 13 direkte Urteile, darunter eines `nicht_angesetzt` (Geometrie). Es zählt
wie seit R7-1 als Übungsbedarf, deshalb steht Geometrie in Prod bei 4, in der Fixture `abgestuft` bei
3 (dort ist es bewusst weggelassen, siehe Kopf von `abgestuft.ts`). R7-8 ändert die Zählung nicht.

## Testanpassungen außerhalb der genannten Dateien

- `Seite1Thema.test.tsx`:
  - Hinweistext neu.
  - „abgeleitete Urteile erscheinen nirgends …“ und „Seite 1 und 2 nennen dieselben Zahlen“ zählen
    jetzt die **farbigen** Kästchen der Spur (vorher alle Rechtecke). Dazu kommt neu: Umrisse in der
    Spur = `themaAbdeckung.abgeleitet`.
  - Die Thema-Satz-Hilfe bekommt die zwei neuen Felder.
- `fixtures.test.ts`: `abgestuft` per `toMatchObject` (neue Felder), `abgestuftLang` in der Liste der
  Fälle mit Thema-Satz.
- `inv4-elternbericht.test.ts` (INV-4.9): neue Liste `R7_8_GEAENDERT` mit `s2.profil.hinweis` und
  `s2.fussnote`, eigener Test „R7-8: die neu gefassten Schlüssel aus Anhang A wörtlich“. Für
  `s2.fussnote`, das schon R7-6 geändert hatte, erwartet der R7-6-Test den R7-8-Wortlaut. Nichts
  gelockert.

## Offen

- `ariaAbgeleitet_one` und `ariaNurAbgeleitet_*` sind über den Auftrag hinaus (texte-r7-8.md).
- „Was die Grafik zeigt“ wertet nur direkt Geprüftes. Bei `abgestuft` heißt es „überwiegend sicher …
  Brüche & Dezimalzahlen“ bei 1 von 1 geprüft, neben vier Umrissen. Unverändert seit R7-3, aber jetzt
  sichtbarer.
- Die Umriss-Kästchen sind hell (Fläche Papier, Rand `--color-eb-schraffur-rand`) und können im Druck
  blass wirken. Das ist eine Designfrage, im Ausdruck ansehen (Fund der Zweitprüfung).
