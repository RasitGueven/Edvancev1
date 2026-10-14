import { useTranslation } from 'react-i18next'
import { vertragspartner } from '@/lib/vertrag/menue'
import type { VertragAktuell } from '@/types'
import { Datenblock, type Zeile } from './Datenblock'
import { IbanFeld } from './IbanFeld'

/**
 * Block "Vertragspartner" der Detailansicht. V5: Eine Pilotvereinbarung hat
 * keine Bankdaten und kein Mandat — Kontoinhaber, IBAN und Mandatsreferenz
 * stehen dort nicht (Entscheidung 2).
 */
export function PartnerBlock({ v, onFehler }: { v: VertragAktuell; onFehler: (e: string) => void }): JSX.Element {
  const { t } = useTranslation('vertraege')
  const bank: Zeile[] =
    v.vertragsart === 'pilot'
      ? []
      : [
          { label: t('field.kontoinhaber'), wert: v.kontoinhaber ?? '—' },
          { label: t('field.iban'), wert: <IbanFeld vertragId={v.id} maskiert={v.iban_masked} onFehler={onFehler} /> },
          { label: t('field.mandatsreferenz'), wert: v.mandatsreferenz },
        ]
  return (
    <Datenblock
      titel={t('form.parent')}
      zeilen={[
        { label: t('menue.spalte.partner'), wert: vertragspartner(v) || '—' },
        { label: t('field.strasse'), wert: [v.strasse, v.hausnummer].filter(Boolean).join(' ') || '—' },
        { label: t('field.ort'), wert: [v.plz, v.ort].filter(Boolean).join(' ') || '—' },
        { label: t('field.eltern_email'), wert: v.eltern_email ?? '—' },
        { label: t('field.eltern_telefon'), wert: v.eltern_telefon ?? '—' },
        ...bank,
      ]}
    />
  )
}
