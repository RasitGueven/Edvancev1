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

/** Bericht v4: Ziele im Gespräch bestätigt, ohne eigenes Zielbild — Seite 5 zeigt den Systemvorschlag (zieleV4). */
export const NOTIZEN_ZIELE: ReportNotes = { ...NOTIZEN, zielbild: '', zieleBestaetigt: true }

/** Ein langes Zielbild ohne Namen (sechs Zeilen im Lernziel-Kasten), synthetisch. */
export const NOTIZEN_LANG: ReportNotes = {
  ...NOTIZEN,
  zielbild:
    'Ihr Kind rechnet mit Brüchen und Dezimalzahlen sicher, auch wenn die Aufgabe in einen Text eingebettet ist, und löst Prozentaufgaben in beide Richtungen, also auch dann, wenn der Grundwert gesucht ist. Terme fasst es zusammen und klammert aus, ohne ein Vorzeichen zu verlieren. Bei Figuren wählt es die passende Formel für Umfang und Fläche und rechnet Flächeneinheiten richtig um. Danach festigen wir die Grundlagen für das nächste Thema. Wir überprüfen den Stand regelmäßig in den Sitzungen, besprechen ihn mit Ihnen und passen den Plan an, sobald sich etwas verschiebt.',
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
