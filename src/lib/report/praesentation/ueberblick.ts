// Tablet-Präsentation — die zwei Karten in Station 01 (Entscheidung 6).
//
// „Schon gelungen": Themenfelder mit mehr sicheren Bereichen als Bereichen mit
// Übungsbedarf. „Gezielt üben": die übrigen Felder mit Übungsbedarf. Gezählt
// wie R7 (übersprungen gehört zum Übungsbedarf). Absteigend nach Anzahl, bei
// Gleichstand nach THEMENFELDER (Reihenfolge von bericht.profil). Kein Feld
// steht in beiden Karten. Alle Felder kommen zurück; die Karte zeigt zwei und
// „+n weitere" (PS-1, Entscheidung 6).
//
// R7-3 („Was die Grafik zeigt") war beim Bau noch nicht auf dev; die Regel
// steht deshalb hier. Kommt sie dort als reine Funktion, eine von beiden
// entfernen (offene-punkte-t1.md).

import type { EbProfilZeile, Elternbericht, TpUeberblick } from '@/types'

function oben(zeilen: EbProfilZeile[], anzahl: (z: EbProfilZeile) => number): EbProfilZeile['feld'][] {
  // Array.prototype.sort ist stabil: Gleichstand behält die Reihenfolge des Profils.
  return [...zeilen]
    .sort((a, b) => anzahl(b) - anzahl(a))
    .map((z) => z.feld)
}

export function ueberblick(bericht: Elternbericht): TpUeberblick {
  const { profil, zaehlung, sicherListe, uebungListe } = bericht
  const ueberwiegendSicher = profil.filter((z) => z.sicher > z.uebung)
  const mitUebung = profil.filter((z) => z.sicher <= z.uebung && z.uebung > 0)

  const gelungen = oben(ueberwiegendSicher, (z) => z.sicher)
  const ueben = oben(mitUebung, (z) => z.uebung)

  return {
    gelungen,
    ueben,
    beispielSicher:
      gelungen.length === 0 && zaehlung.sicher > 0 && sicherListe.length > 0
        ? { label: sicherListe[0].label, anzahl: zaehlung.sicher }
        : null,
    beispielUebung:
      ueben.length === 0 && zaehlung.uebung > 0 && uebungListe.length > 0
        ? { label: uebungListe[0].label, anzahl: zaehlung.uebung }
        : null,
  }
}
