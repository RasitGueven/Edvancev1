// Fälle für den Lernweg (R7-9, „Testfälle“ im Bauauftrag). Abgeleitet aus
// abgestuft (Batu) und Ilkay; nur von Tests und der Vorschau importiert.

import { abgestuft } from '@/lib/report/elternbericht/fixtures/abgestuft'
import { datenAus, type SitzungRoh } from '@/lib/report/elternbericht/fixtures/basis'
import { ILKAY_ROH, ILKAY_URTEILE } from '@/lib/report/elternbericht/fixtures/ilkay'
import { FWG_NAME, FWG_PLAN } from '@/lib/report/elternbericht/fixtures/plaene'
import { schulPlan } from '@/lib/report/elternbericht/plan'
import type { ReportData } from '@/types'

const wie = (basis: ReportData, id: string, erzaehlung: Partial<ReportData['erzaehlung']>, rest: Partial<ReportData> = {}): ReportData => ({
  ...basis,
  sessionId: `00000000-0000-4000-8000-0000000000${id}`,
  ...rest,
  erzaehlung: { ...basis.erzaehlung, ...erzaehlung },
})

/** Wie abgestuft, aber ohne eine einzige Kante: keine Linien, kein ↳. */
export const ohneKanten = wie(abgestuft, '40', { kanten: [] })

/**
 * Schule mit Plan, Sitzung ohne Thema: Position nach Datum. Der FWG-Plan hat in
 * Prod kein Halbjahr; hier synthetisch Positionen 1–3 im ersten, 4–6 im
 * zweiten Halbjahr. Sitzung im März → zweites Halbjahr → Kommt noch ab Position 5.
 */
export const planOhneThema = wie(
  abgestuft,
  '41',
  {
    raum: null,
    suche: abgestuft.erzaehlung.suche ? { ...abgestuft.erzaehlung.suche, themaLabel: null } : null,
    plan: schulPlan(
      FWG_PLAN.map((z) => ({ ...z, halbjahr: z.position <= 3 ? 1 : 2 })),
      9,
      FWG_NAME,
    ),
  },
  { analysedAt: '2027-03-10T10:00:00.000Z' },
)

/** Alles aus Ilkays Analyse sicher: mehr als 6 mögliche Linien, mehr als 8 nicht geprüfte Ziele. */
export const vieleKanten: ReportData = datenAus({
  ...ILKAY_ROH,
  sessionId: '00000000-0000-4000-8000-000000000042',
  urteile: ILKAY_URTEILE.map((s) => ({ ...s, zustand: 'traegt' })),
} satisfies SitzungRoh)

/**
 * Lange Labels (45+ Zeichen) mit ↳-Unterzeile in einer Insel: Terme &
 * Gleichungen aus abgestuft, die beiden Verfahren ausführlich benannt. Das
 * Ziel „LGS aus Sachsituationen …“ kommt aus dem Katalog (55 Zeichen für Eltern).
 */
export const langeLabels = wie(abgestuft, '43', {
  kompetenzen: abgestuft.erzaehlung.kompetenzen.map((k) =>
    k.skillKey === 'gleichung_lgs_addition'
      ? { ...k, label: 'Additionsverfahren bei linearen Gleichungssystemen mit zwei Variablen' }
      : k.skillKey === 'gleichung_lgs_einsetzen'
        ? { ...k, label: 'Einsetzungsverfahren bei linearen Gleichungssystemen mit zwei Variablen' }
        : k,
  ),
})
