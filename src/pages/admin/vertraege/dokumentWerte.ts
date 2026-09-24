// Werte fuer die {{platzhalter}} in Vertrag und SEPA-Mandat.

import type { TFunction } from 'i18next'
import { formatDateOnly } from '@/lib/datetime'
import { formatIban } from '@/lib/vertrag/iban'
import type { Vertrag } from '@/types'
import { formatEuro } from './VertragForm'
import { elternName } from './vertragModel'

type Quellen = {
  vertrag: Vertrag
  iban: string | null
  paket: string | null
  glaeubigerId: string | null
  locale: string
  t: TFunction
}

export function dokumentWerte({ vertrag: v, iban, paket, glaeubigerId, locale, t }: Quellen): Record<string, string | null> {
  const datum = (ymd: string | null): string | null => (ymd ? formatDateOnly(ymd, locale) : null)
  const strasse = [v.strasse, v.hausnummer].filter(Boolean).join(' ')
  const ort = [v.plz, v.ort].filter(Boolean).join(' ')
  const eltern = elternName(v)
  return {
    eltern_name: eltern,
    anschrift: [strasse, ort].filter((x) => x !== '').join('\n') || null,
    eltern_telefon: v.eltern_telefon,
    eltern_email: v.eltern_email,
    kind_name: [v.kind_vorname, v.kind_nachname].filter(Boolean).join(' ') || null,
    kind_geburtsdatum: datum(v.kind_geburtsdatum),
    klasse: v.klasse !== null ? String(v.klasse) : null,
    fach: v.fach,
    schule: v.schule,
    paket,
    preis: v.preis_cents !== null ? formatEuro(v.preis_cents, locale) : null,
    laufzeit: v.laufzeit_monate !== null ? t('form.months', { count: v.laufzeit_monate }) : null,
    vertragsbeginn: datum(v.vertragsbeginn),
    kontoinhaber: v.kontoinhaber ?? eltern,
    iban: iban ? formatIban(iban) : null,
    mandatsreferenz: v.mandatsreferenz,
    glaeubiger_id: v.glaeubiger_id ?? glaeubigerId,
  }
}
