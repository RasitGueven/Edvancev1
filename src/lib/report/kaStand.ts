// LSA-L4 Teil D (Bauauftrag L4, Entscheidung 13): Der Bericht zeigt den Klassenarbeits-Stand der Sitzung, auf der er
// beruht (lsa_sessions.ka_modus / ka_note, festgestellt beim LSA-Start), nicht den heutigen Stand des Leads. Fehlt der
// Modus (Sitzung vor L3), gilt der Lead wie bisher. Weicht der Lead heute ab, meldet kaAbweichung das nur für die
// Admin-Ansicht; der Elternbericht zeigt es nicht.
//
// ka_modus unterscheidet nur „geschrieben“ (vorschau_zuerst) von „nicht geschrieben“ (thema_zuerst: bevorstehend oder
// unbekannt). Bei thema_zuerst bleibt ein bevorstehender Stand des Leads stehen; meldet der Lead heute „geschrieben“,
// war es beim Start nicht so, und der Stand gilt als unbekannt.

import type { KaAbweichung, KaStand, ReportErstgespraech } from '@/types'

export type KaModus = 'thema_zuerst' | 'vorschau_zuerst'

const note16 = (n: unknown): number | null => (typeof n === 'number' && n >= 1 && n <= 6 ? n : null)

export function klassenarbeitDerSitzung(
  erstgespraech: ReportErstgespraech | null,
  modus: KaModus | null,
  sitzungsNote: number | null,
): { erstgespraech: ReportErstgespraech | null; abweichung: KaAbweichung | null } {
  if (!erstgespraech || !modus) return { erstgespraech, abweichung: null }
  const lead: KaStand = { status: erstgespraech.klassenarbeit, note: note16(erstgespraech.letzteNote) }
  const sitzung: KaStand =
    modus === 'vorschau_zuerst'
      ? { status: 'geschrieben', note: note16(sitzungsNote) }
      : { status: lead.status === 'geschrieben' ? null : lead.status, note: null }
  const gleich =
    sitzung.status === lead.status && (sitzung.status !== 'geschrieben' || sitzung.note === lead.note)
  return {
    erstgespraech: { ...erstgespraech, klassenarbeit: sitzung.status, letzteNote: sitzung.note },
    abweichung: gleich ? null : { sitzung, lead },
  }
}
