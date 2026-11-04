# Retro 04.11.2026 · V4-S: Karte „steht an“

## Gebaut
- `src/lib/report/elternbericht/anstehend.ts`: Gruppen a (Heimat-Thema = aktuelles Thema) und b (Voraussetzungen,
  Kante wie `signaleJeThema`), Signal über beide. Nur bei `'bevorstehend'`; das Feld `bericht.anstehend` fehlt sonst.
- Fahrplan: Signal der aktuellen Station über `signalAktuell` (nur `'bevorstehend'`, nicht nach Datum geschrieben).
- Station 03: Karte „steht an“ mit einer Zeile, Signal und den Gruppen; Seite 3: erster Block für die Arbeit.
- Lernpfad: Feld-Schwerpunkte mit Lücken aus a/b bereiten Station 1 vor und rücken nach vorn.
- Testkind Ida (Schaurte-Plan), Fixture `idaV4.ts`, Snapshot von Batu vor der Änderung.
- Nebenbei: Wochenplan-Test mit fester Uhr (kippte ab 04.11.2026, auch auf dev).

## Entscheidungen
- Schaurte statt FWG für das Testkind (FWG hat Ähnlichkeit erst in Klasse 10, ohne Halbjahr kein Fahrplan).
- Ein Bereich in a und b zählt zu a.
- Bereiche der anstehenden Arbeit bleiben zusätzlich in „Weitere Stärken“ / „Wird später wichtig“ (Entscheidung 5).

## Offen
- „Wird später wichtig“ nennt bei `'bevorstehend'` weiter die Lücken des aktuellen Themas, obwohl sie jetzt im ersten
  Block stehen (vom Auftrag so erlaubt; inhaltlich ist es doppelt).
- Steht ein Feld-Schwerpunkt mit Lücke aus a/b hinter Platz 4, landet er in `danach` und nicht am Anfang des Lernpfads.
