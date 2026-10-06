// Feste Leisten der Pruefansichten (Entscheidungsleiste, Admin-Leiste, Meldung) stehen in der Huelle neben der
// Seitenleiste, nicht darueber. Eingerueckt wird ueber die Layout-Modi der Huelle: dieselben Breakpoints
// (spalte:/voll:, --breakpoint-*) und Breiten (--container-leiste*) wie AppShell, keine festen Pixel.
// Schublade (unter spalte) und ausserhalb der Huelle: volle Breite.

/** Linker Rand einer fixierten Leiste (left-Utilities). */
export function leisteLinks(imShell: boolean): string {
  return imShell ? 'left-0 spalte:left-[var(--container-leiste-schmal)] voll:left-[var(--container-leiste)]' : 'left-0'
}

/** Mitte des Inhaltsbereichs fuer zentrierte Meldungen ueber der Leiste. */
export function meldungMitte(imShell: boolean): string {
  return imShell
    ? 'left-1/2 spalte:left-[calc(50%+var(--container-leiste-schmal)/2)] voll:left-[calc(50%+var(--container-leiste)/2)]'
    : 'left-1/2'
}
