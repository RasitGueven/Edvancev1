// Erklaersequenzen pruefen (L6): Wege und Fehlerschluessel fuer i18n (Namespace erklaerPruefen).

import type { ErklaerFehler } from '@/types/erklaerPruefung'

export type ErklaerModus = 'lena' | 'admin'

/** Lena prueft unter /coach/pruefen, der Admin gibt unter /admin/pruefen frei. */
export function erklaerBasis(modus: ErklaerModus): string {
  return modus === 'admin' ? '/admin/pruefen/erklaerungen' : '/coach/pruefen/erklaerungen'
}

/** Aufgaben-Pruefung einer Check-Aufgabe: Lenas Pruefansicht bzw. die Admin-Pruefansicht. */
export function aufgabenPfad(modus: ErklaerModus, taskId: string): string {
  return modus === 'admin' ? `/admin/pruefen/${taskId}` : `/coach/pruefen/${taskId}`
}

/** HINT-Schluessel aus pruef_fehler, die erklaer_* liefern (Migrationen 20261010121015/121016). */
export const ERKLAER_HINWEISE = [
  'veraltet', 'grund_fehlt', 'grund_unbekannt', 'notiz_fehlt', 'nicht_bewertet', 'freigegeben', 'nicht_freigegeben',
  'keine_erklaerung', 'freigabe_unvollstaendig', 'antwort_fehlt', 'keine_rueckfrage', 'fehlbild_unbekannt',
  'erst_pruefen', 'formeln_fehlen',
] as const

export function erklaerFehlerSchluessel(err: ErklaerFehler | null): string {
  if (!err) return 'fehlermeldung.allgemein'
  if (err.code === 'ED422') {
    const hint = err.hint ?? ''
    return (ERKLAER_HINWEISE as readonly string[]).includes(hint) ? `fehlermeldung.${hint}` : 'fehlermeldung.eingabe'
  }
  if (err.code === '42501') return 'fehlermeldung.kein_recht'
  if (err.code === 'P0002') return 'fehlermeldung.nicht_gefunden'
  return 'fehlermeldung.allgemein'
}
