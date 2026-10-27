import { useTranslation } from 'react-i18next'

import type { ReportNotes } from '@/types'

export type BestaetigungArt = 'zieleBestaetigt' | 'paketBestaetigt'

/** Nur für den Admin (ReportPage): Schalter „im Gespräch bestätigt“; ohne Prop keine Anzeige. */
export type TpBestaetigung = { onWechsel: (art: BestaetigungArt, an: boolean) => void }

/**
 * L5 Teil D (Entscheidung 14): dezente Schalter in Station 04 — Ziele bzw. Paket im Gespräch bestätigt. Gespeichert
 * wird sofort (ReportPage); die Präsentation selbst schreibt nichts. Nicht im Druck.
 */
export function Bestaetigung({
  notes,
  bestaetigung,
}: {
  notes: ReportNotes | null
  bestaetigung: TpBestaetigung
}): JSX.Element {
  const { t } = useTranslation('praesentation')
  const schalter = (art: BestaetigungArt, label: string, gesperrt = false): JSX.Element => {
    const an = notes?.[art] === true
    return (
      <button
        type="button"
        role="switch"
        aria-checked={an}
        disabled={gesperrt}
        title={gesperrt ? t('bestaetigung.ohnePaket') : undefined}
        className={an ? 'tp-bestaetigung-schalter tp-bestaetigung-an' : 'tp-bestaetigung-schalter'}
        onClick={() => bestaetigung.onWechsel(art, !an)}
      >
        <i aria-hidden="true" />
        {label}
      </button>
    )
  }
  return (
    <div className="tp-bestaetigung print-hide" role="group" aria-label={t('bestaetigung.aria')} data-testid="tp-bestaetigung">
      {schalter('zieleBestaetigt', t('bestaetigung.ziele'))}
      {schalter('paketBestaetigt', t('bestaetigung.paket'), !notes?.paket)}
    </div>
  )
}
