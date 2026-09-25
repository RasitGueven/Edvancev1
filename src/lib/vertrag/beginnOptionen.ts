// Vertragsbeginn ist immer der Erste eines Monats (Entscheidung 3). Das Feld
// ist deshalb eine Auswahl und kein Datumsfeld — ein <input type="date"> laedt
// ein, den 17. zu tippen, und der Check-Constraint weist ihn erst beim
// Speichern ab.
//
// Rechnung ueber Jahr und Monat, nicht ueber Millisekunden: Tage addieren
// verschluckt an der Zeitumstellung eine Stunde und landet einen Tag frueher.

/** Die naechsten `anzahl` Monatsersten, beginnend mit dem kommenden Monat. */
export function beginnOptionen(heute: string, anzahl = 18): string[] {
  const jahr = Number(heute.slice(0, 4))
  const monat = Number(heute.slice(5, 7))
  const optionen: string[] = []
  for (let i = 1; i <= anzahl; i++) {
    const roh = monat - 1 + i
    const y = jahr + Math.floor(roh / 12)
    const m = (roh % 12) + 1
    optionen.push(`${y}-${String(m).padStart(2, '0')}-01`)
  }
  return optionen
}

/**
 * Die Auswahl fuer ein konkretes Formular. Ein bereits gespeicherter Beginn
 * bleibt waehlbar, auch wenn er inzwischen in der Vergangenheit liegt — sonst
 * verloere ein liegen gebliebener Antrag beim Oeffnen seinen eigenen Wert.
 */
export function beginnAuswahl(heute: string, gespeichert: string | null, anzahl = 18): string[] {
  const optionen = beginnOptionen(heute, anzahl)
  if (gespeichert && !optionen.includes(gespeichert)) {
    return [gespeichert, ...optionen].sort()
  }
  return optionen
}
