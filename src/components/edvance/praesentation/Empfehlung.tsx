import { Trans, useTranslation } from 'react-i18next'

import type { TpEmpfehlung } from '@/types'

/**
 * Die Empfehlungszeile unter Station 04 (Entscheidung 9): Paketname fett, dahinter
 * „Basic ist ebenfalls möglich.", außer das Paket ist schon das erste. Nie ein
 * Preis, keine Laufzeit.
 */
export function Empfehlung({ e, name }: { e: TpEmpfehlung; name: string | null }): JSX.Element {
  const { t } = useTranslation('praesentation')
  return (
    <p className="tp-s4-empfehlung tp-reveal" data-testid="tp-empfehlung">
      <span className="tp-s4-empfehlung-punkt" aria-hidden="true" />
      <span>
        <Trans
          t={t}
          i18nKey={name ? 's4.empfehlung' : 's4.empfehlungOhneName'}
          values={{ name, paket: e.paket }}
          components={{ b: <b /> }}
        />
      </span>
      {e.basis && <span className="tp-s4-basis">{t('s4.basisMoeglich', { basis: e.basis })}</span>}
    </p>
  )
}
