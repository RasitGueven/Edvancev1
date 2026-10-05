// Uebersetzungsschluessel der Admin-Pruefansicht: Auslass-Gruende von pruef_sammel und die neuen HINTs.
// Reine Funktionen; die Texte stehen in src/i18n/locales/de/pruefenAdmin.json (Namespace pruefenAdmin).
// Bekannte Lena-HINTs uebersetzt weiter pruefen.json (fehlerSchluessel in texte.ts).

import type { PruefFehlerInfo, SammelAusgelassen, SammelGrund } from '@/types'
import { BEKANNTE_HINWEISE, fehlerSchluessel } from './texte'

/** Alle Auslass-Schluessel, die pruef_sammel liefern kann (Migration 20261005131306). */
export const AUSLASS_GRUENDE: readonly SammelGrund[] = [
  'schon_freigegeben', 'vera8', 'rueckfrage_offen', 'team_beanstandet', 'lena_passt_nicht', 'noch_nicht_bewertet',
  'geaendert', 'befund', 'freigegeben', 'nicht_bei_lena', 'schon_offen', 'schon_im_pilot', 'nicht_im_pilot',
  'schon_ausgeschlossen', 'nicht_von_hand', 'schon_drin', 'ausgeschlossen', 'schon_gesetzt', 'nicht_erlaubt',
  'nicht_gefunden', 'fehler',
]

/** Neue ED422-HINTs der Admin-Funktionen (Migrationen 20261005131059 … 131306). */
export const ADMIN_HINWEISE = ['erst_an_lena', 'nicht_freigegeben', 'wert_fehlt'] as const

/** Gruende, deren text ein Ausschluss-Schluessel ist (pruef_ausschluss) — uebersetzt ueber authoring:lena.ausschluss.*. */
const MIT_AUSSCHLUSS = new Set(['nicht_bei_lena', 'schon_ausgeschlossen', 'nicht_von_hand', 'ausgeschlossen'])

/** Ein i18n-Schluessel (mit Namespace) samt Werten; grundKey wird vorher uebersetzt und als {{grund}} eingesetzt. */
export type Uebersetzung = { key: string; werte?: Record<string, string>; grundKey?: string } | { text: string }

type T = (key: string, opts?: Record<string, unknown>) => string

/** Macht aus einer Uebersetzung den Text. */
export function uebersetze(t: T, u: Uebersetzung): string {
  if ('text' in u) return u.text
  return t(u.key, { ...u.werte, ...(u.grundKey ? { grund: t(u.grundKey) } : {}) })
}

/**
 * Text zu einem Fehler aus einer Admin-Aktion. Neue HINTs → pruefenAdmin:fehler.*, Lenas HINTs →
 * pruefen:fehlermeldung.*, das Gate (P0001) bringt seinen Text selbst mit.
 */
export function adminFehler(err: PruefFehlerInfo | null): Uebersetzung | null {
  if (!err) return null
  if (err.code === 'ED422' && (ADMIN_HINWEISE as readonly string[]).includes(err.hint ?? '')) {
    return { key: `pruefenAdmin:fehler.${err.hint}` }
  }
  if (err.code === 'P0001') return { text: err.message }
  return { key: `pruefen:${fehlerSchluessel(err) ?? 'fehlermeldung.allgemein'}` }
}

/** Schluessel und Werte fuer den Text eines Auslass-Grunds (Vorschau-Dialog, Ergebnis-Meldung). */
export function auslassText(a: Pick<SammelAusgelassen, 'grund' | 'text'>): Uebersetzung {
  const g = String(a.grund)
  if ((AUSLASS_GRUENDE as readonly string[]).includes(g)) {
    if (MIT_AUSSCHLUSS.has(g)) {
      return { key: `pruefenAdmin:ausgelassen.${g}`, grundKey: `authoring:lena.ausschluss.${a.text ?? ''}` }
    }
    return { key: `pruefenAdmin:ausgelassen.${g}`, werte: { text: a.text ?? '' } }
  }
  // Ein ED422 beim Schreiben traegt den HINT als Grund.
  if ((ADMIN_HINWEISE as readonly string[]).includes(g)) return { key: `pruefenAdmin:fehler.${g}` }
  if ((BEKANNTE_HINWEISE as readonly string[]).includes(g)) return { key: `pruefen:fehlermeldung.${g}` }
  return { key: 'pruefenAdmin:ausgelassen.fehler', werte: { text: a.text ?? g } }
}

/** Gruppiert ausgelassene Aufgaben nach Grund (und Text), in der Reihenfolge des ersten Auftretens. */
export function nachGrund(liste: SammelAusgelassen[]): { grund: string; text: string | null; ids: string[] }[] {
  const gruppen = new Map<string, { grund: string; text: string | null; ids: string[] }>()
  for (const a of liste) {
    // Der Gate-Text unterscheidet Befunde; die uebrigen Texte (Ausschluss-Grund) auch.
    const k = `${a.grund}|${a.grund === 'fehler' ? '' : (a.text ?? '')}`
    const g = gruppen.get(k) ?? { grund: String(a.grund), text: a.text, ids: [] }
    g.ids.push(a.task_id)
    gruppen.set(k, g)
  }
  return [...gruppen.values()]
}
