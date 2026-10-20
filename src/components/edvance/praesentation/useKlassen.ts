import { useTranslation } from 'react-i18next'

import { klassenAngabe } from '@/lib/report/elternbericht/einordnung'
import type { Stufe } from '@/types'

/**
 * Die Klassenangabe wie im Druckbogen: eine Stufe → `elternbericht:stufe.<stufe>`
 * („Klasse 5/6"), mehrere → `stufe.spanne` („Klasse 5–8"). Ohne Stufen leer.
 */
export function useKlassen(): (stufen: readonly Stufe[]) => string {
  const { t } = useTranslation('elternbericht')
  return (stufen) => {
    const angabe = klassenAngabe(stufen)
    if (!angabe) return ''
    return 'stufe' in angabe ? t(`stufe.${angabe.stufe}`) : t('stufe.spanne', angabe)
  }
}
