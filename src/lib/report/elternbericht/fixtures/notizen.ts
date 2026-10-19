// Coach-Notizen und Pakete wie im Muster E7 (Seite 4 und 5). Nur von Tests und
// der Vorschau importiert. Die Pakete tragen Platzhalter-IDs und keinen Preis:
// der Bogen zeigt keinen (Entscheidung 10), price_cents ist hier bedeutungslos.

import type { ReportNotes, TierPlan } from '@/types'

export const NOTIZEN: ReportNotes = {
  zielbild:
    'Ilkay löst Umrechnungen und Prozentaufgaben in beide Richtungen, rechnet mit Brüchen sicher und hat die Grundlagen für Algebra & Funktionen gefestigt. Wir überprüfen den Stand regelmäßig in den Sitzungen und passen den Plan an.',
  empfehlung: 'Vier Förderthemen, die regelmäßig Wiederholung brauchen.',
  paket: 'premium',
}

const tier = (n: number, name: string, features: string[]): TierPlan => ({
  id: `00000000-0000-4000-8000-00000000t00${n}`,
  name,
  price_cents: 0,
  features,
  sort_order: n,
  active: true,
})

export const TIERS: TierPlan[] = [
  tier(1, 'Basic', ['1 Session pro Woche', '1 Fach']),
  tier(2, 'Standard', ['1,5 Sessions pro Woche', 'bis zu 2 Fächer']),
  tier(3, 'Premium', ['2 Sessions pro Woche', 'bis zu 2 Fächer']),
]
