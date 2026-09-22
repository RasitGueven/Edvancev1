// IBAN: normalisieren, per Pruefsumme (ISO 13616, mod 97) pruefen, maskieren.
// Die DB prueft nur das Format; die Pruefsumme liegt bewusst hier, damit das
// Formular sofort reagiert.

/** Grossbuchstaben, ohne Leer- und Trennzeichen. */
export function normalizeIban(raw: string): string {
  return raw.replace(/[\s-]/g, '').toUpperCase()
}

export function isValidIban(raw: string): boolean {
  const iban = normalizeIban(raw)
  if (!/^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$/.test(iban)) return false
  // Deutsche IBAN haben genau 22 Stellen — der haeufigste Tippfehler.
  if (iban.startsWith('DE') && iban.length !== 22) return false
  const rearranged = iban.slice(4) + iban.slice(0, 4)
  let rest = 0
  for (const ch of rearranged) {
    const value = ch >= 'A' ? String(ch.charCodeAt(0) - 55) : ch
    for (const digit of value) rest = (rest * 10 + Number(digit)) % 97
  }
  return rest === 1
}

/** Anzeige in Listen: DE** **** 1234 (gleiche Form wie vertraege.iban_masked). */
export function maskIban(raw: string): string {
  const iban = normalizeIban(raw)
  return `${iban.slice(0, 2)}** **** ${iban.slice(-4)}`
}

/** Vierergruppen fuer die Eingabe und das SEPA-Mandat. */
export function formatIban(raw: string): string {
  return normalizeIban(raw).replace(/(.{4})/g, '$1 ').trim()
}
