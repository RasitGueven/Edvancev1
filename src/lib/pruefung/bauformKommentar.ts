// Prüfansicht einer Bauform (SP-1 S4): Kommentare, Zeitänderungen, Entwurf und die Antworten der typischen Fehler je
// Beispiel. Rein, ohne Texte; der Entwurf liegt im Browser je Bauform und Version (Repo-Muster ohne Server-Entwurf).
import type { BauformBeispiel } from '@/types/bauformPruefung'

export type KommentarAnker = 'grundgeruest' | 'stufen' | 'fehlbilder' | 'beispiel'

/** Gründe je Anker, wie in bauform_kommentar_gruende (Datenbank). */
export const GRUENDE: Record<KommentarAnker, readonly string[]> = {
  beispiel: ['rechnung_falsch', 'text_unklar', 'hinweis_verraet_loesung', 'rueckmeldung_passt_nicht', 'loesungsweg_unklar'],
  grundgeruest: ['text_unklar', 'nicht_altersgerecht'],
  stufen: ['stufe_passt_nicht', 'zahlen_anders_waehlen'],
  fehlbilder: ['fehlbild_fehlt', 'fehlbild_unrealistisch', 'rueckmeldung_passt_nicht'],
}

export type Kommentar = { anker: KommentarAnker; task_id: string | null; gruende: string[]; text: string }

export type Entwurf = { kommentare: Kommentar[]; zeiten: Record<string, number> }

export const LEER: Entwurf = { kommentare: [], zeiten: {} }

/** Eindeutiger Schlüssel eines Kommentars (je Anker einer, beim Beispiel je Instanz). */
export const kommentarSchluessel = (anker: KommentarAnker, taskId: string | null = null): string =>
  anker === 'beispiel' ? `beispiel:${taskId ?? ''}` : anker

export const schluesselVon = (k: Kommentar): string => kommentarSchluessel(k.anker, k.task_id)

export const istGueltig = (k: Kommentar): boolean => k.gruende.length > 0 || k.text.trim() !== ''

export function hinzufuegen(e: Entwurf, anker: KommentarAnker, taskId: string | null = null): Entwurf {
  const s = kommentarSchluessel(anker, taskId)
  if (e.kommentare.some((k) => schluesselVon(k) === s)) return e
  return { ...e, kommentare: [...e.kommentare, { anker, task_id: anker === 'beispiel' ? taskId : null, gruende: [], text: '' }] }
}

export const entfernen = (e: Entwurf, schluessel: string): Entwurf =>
  ({ ...e, kommentare: e.kommentare.filter((k) => schluesselVon(k) !== schluessel) })

export function aendern(e: Entwurf, schluessel: string, aenderung: Partial<Pick<Kommentar, 'gruende' | 'text'>>): Entwurf {
  return { ...e, kommentare: e.kommentare.map((k) => (schluesselVon(k) === schluessel ? { ...k, ...aenderung } : k)) }
}

export function grundUmschalten(e: Entwurf, schluessel: string, grund: string): Entwurf {
  const k = e.kommentare.find((x) => schluesselVon(x) === schluessel)
  if (!k) return e
  const gruende = k.gruende.includes(grund) ? k.gruende.filter((g) => g !== grund) : [...k.gruende, grund]
  return aendern(e, schluessel, { gruende })
}

/** Zeit-Richtwert: Schritte 0,5, Bereich 0,5 bis 10 (wie bauform_zeit_setzen). */
export const ZEIT_MIN = 0.5
export const ZEIT_MAX = 10
export function zeitSchritt(e: Entwurf, stufe: number, vorher: number, delta: number): Entwurf {
  const alt = e.zeiten[String(stufe)] ?? vorher
  const neu = Math.min(ZEIT_MAX, Math.max(ZEIT_MIN, Math.round((alt + delta) * 2) / 2))
  const zeiten = { ...e.zeiten }
  if (neu === vorher) delete zeiten[String(stufe)]
  else zeiten[String(stufe)] = neu
  return { ...e, zeiten }
}

/** Was an den Server geht: nur gültige Felder, Texte getrimmt. */
export const zumSenden = (e: Entwurf) => ({
  kommentare: e.kommentare.map((k) => ({
    anker: k.anker, ...(k.task_id ? { task_id: k.task_id } : {}), gruende: k.gruende, text: k.text.trim() || null,
  })),
  zeiten: e.zeiten,
})

export const sendbar = (e: Entwurf): boolean => e.kommentare.every(istGueltig)

// ── Entwurf im Browser ──────────────────────────────────────────────────────
const speicherSchluessel = (bauformId: string, version: number): string => `sp1-entwurf:${bauformId}:v${version}`

export function entwurfLaden(bauformId: string, version: number): Entwurf {
  try {
    const roh = window.localStorage.getItem(speicherSchluessel(bauformId, version))
    if (!roh) return LEER
    const e = JSON.parse(roh) as Entwurf
    return Array.isArray(e.kommentare) && e.zeiten && typeof e.zeiten === 'object' ? e : LEER
  } catch {
    return LEER
  }
}

export function entwurfSpeichern(bauformId: string, version: number, e: Entwurf): void {
  try {
    const s = speicherSchluessel(bauformId, version)
    if (e.kommentare.length === 0 && Object.keys(e.zeiten).length === 0) window.localStorage.removeItem(s)
    else window.localStorage.setItem(s, JSON.stringify(e))
  } catch {
    // Ohne Speicher (privates Fenster) geht nur der Entwurf verloren, die Prüfung selbst nicht.
  }
}

// ── Typische Fehler je Beispiel ─────────────────────────────────────────────
export type FehlerAntwort = { key: string; antwort: Record<string, unknown> }

/**
 * Gespeicherte falsche Antworten je Fehlbild (nichts wird nachgerechnet): bei den neuen Formaten aus
 * loesung.fehlbilder, bei Zahl und Auswahl aus known_errors (Antwort → Schlüssel; je Schlüssel die Schreibweise mit
 * typografischem Minus, sonst die erste).
 */
export function fehlerAntworten(b: Pick<BauformBeispiel, 'loesung' | 'known_errors' | 'payload'>): FehlerAntwort[] {
  const neu = b.loesung?.fehlbilder
  if (Array.isArray(neu)) {
    return (neu as Array<Record<string, unknown> & { key: string }>).map(({ key, ...rest }) => ({ key, antwort: rest }))
  }
  const je = new Map<string, string>()
  for (const [antwort, key] of Object.entries(b.known_errors ?? {})) {
    const bisher = je.get(key)
    if (!bisher || (!bisher.includes('−') && antwort.includes('−'))) je.set(key, antwort)
  }
  const mc = b.payload && 'options' in b.payload
  return [...je.entries()].map(([key, a]) => ({ key, antwort: mc ? { option: a } : { wert: a } }))
}
