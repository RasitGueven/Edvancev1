// Typen fuer den Pruefer der Vorbefuellung (siehe verify-prefill.mjs).

export function pruefePrefill(opt: {
  charge: string
  snapshot: string
  blind?: string
}): Promise<{ fehler: string[]; bestand: string[]; bericht: string }>
