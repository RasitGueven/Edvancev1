// Eltern-Bericht R7 — der Genitiv des Rufnamens („Ilkays Lernstand").
//
// Endet der Name auf s, ß, x oder z (damit auch tz), steht nur der Apostroph
// (Max’, Moritz’, Hans’), sonst ein angehängtes „s" (Ilkays, Lenas, Emils).
// Typografischer Apostroph U+2019 wie im Muster.

const OHNE_S = /[sßxz]$/i

export function genitiv(name: string): string {
  const n = name.trim()
  return OHNE_S.test(n) ? `${n}’` : `${n}s`
}
