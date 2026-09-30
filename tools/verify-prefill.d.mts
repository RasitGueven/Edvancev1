// Typen fuer den Pruefer der Vorbefuellung (siehe verify-prefill.mjs).

export function pruefePrefill(opt: {
  charge: string
  snapshot: string
  blind?: string
  /** Pfad der Migration dieser Charge — prueft zusaetzlich, dass sie nur Charge-Aufgaben anfasst. */
  migration?: string
}):Promise<{ fehler: string[]; bestand: string[]; bericht: string }>
