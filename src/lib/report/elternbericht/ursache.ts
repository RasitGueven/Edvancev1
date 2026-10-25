// Eltern-Bericht v2 — Seite 1: die Antwort auf die vermutete Ursache.
//
// Je genannter Ursache (lead_assessments.weak_topics) ein Baustein aus i18n
// (`ursache.<key>.<variante>`), gewählt nach der Regel in URSACHEN
// (berichtKonfig.ts). Varianten:
//   bestaetigt — die Daten stützen die Vermutung,
//   eherNicht  — die Daten sprechen eher dagegen,
//   offen      — die Analyse misst das nicht oder hat dazu keine Aufgabe.
// Die Bausteine nennen keine Aufgaben und sagen nichts voraus.

import { URSACHEN } from '@/lib/report/elternbericht/berichtKonfig'
import type { Fehlermuster } from '@/lib/report/elternbericht/fehlermuster'
import { lueckenStufe } from '@/lib/report/elternbericht/stufenBlick'
import type { EbBereich, EbStufeKey, EbStufenZeile, ReportFehlbild } from '@/types'

export type UrsachenVariante = 'bestaetigt' | 'eherNicht' | 'offen'

export type UrsachenAntwort = {
  /** i18n-Schlüssel unter `ursache.` (grundlagen, textverstaendnis …). */
  key: string
  variante: UrsachenVariante
  /** Nur bei grundlagen: wo die Lücken liegen und ob 5/6 weitgehend sitzt. */
  lueckenIn?: EbStufeKey
  grundlagenSitzen?: boolean
}

export function ursachenAntworten({
  genannt,
  stufen,
  bereiche,
  fehlbilder,
  muster,
}: {
  /** Die Rohwerte aus weak_topics, in der Reihenfolge der Eltern. */
  genannt: readonly string[]
  stufen: readonly EbStufenZeile[]
  bereiche: readonly EbBereich[]
  fehlbilder: readonly ReportFehlbild[]
  muster: Fehlermuster | null
}): UrsachenAntwort[] {
  return [...new Set(genannt)].flatMap((wert) => {
    const u = URSACHEN[wert]
    if (!u) return []
    const r = u.regel
    if (r.art === 'grundlagen') return [grundlagen(stufen)]
    if (r.art === 'sorgfalt') return [{ key: u.key, variante: muster?.sorgfalt ? 'bestaetigt' : 'offen' }]
    if (r.art === 'nichtMessbar') return [{ key: u.key, variante: 'offen' }]
    const familien = new Set(fehlbilder.map((f) => f.familie))
    const geprueft = bereiche.filter((b) => r.skills.includes(b.skillKey))
    const belegt = r.familien.some((f) => familien.has(f)) || geprueft.some((b) => !b.sicher)
    if (belegt) return [{ key: u.key, variante: 'bestaetigt' }]
    // „eher nicht“ nur, wenn es etwas Geprüftes dazu gab; sonst wissen wir es nicht.
    const gesehen = geprueft.length > 0 || (r.skills.length === 0 && fehlbilder.length > 0)
    return [{ key: u.key, variante: gesehen ? 'eherNicht' : 'offen' }]
  })
}

/**
 * Grundlagen: Wo liegt der meiste Übungsbedarf? In einer früheren Stufe als
 * der aktuellen → bestätigt; in der aktuellen → eher nicht. Ohne Übungsbedarf
 * → eher nicht. Dazu, ob Klasse 5/6 weitgehend sitzt (Urteil sicher/weitgehend).
 */
function grundlagen(stufen: readonly EbStufenZeile[]): UrsachenAntwort {
  const luecken = lueckenStufe(stufen) ?? undefined
  const basis = stufen.find((z) => z.stufe === 'grundlagen')
  const grundlagenSitzen = basis ? basis.urteil === 'sicher' || basis.urteil === 'weitgehend' : false
  const frueher = luecken === 'grundlagen' || luecken === 'weiterfuehrend'
  return { key: 'grundlagen', variante: frueher ? 'bestaetigt' : 'eherNicht', lueckenIn: luecken, grundlagenSitzen }
}
