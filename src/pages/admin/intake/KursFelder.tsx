import { useTranslation } from 'react-i18next'
import { Label } from '@/components/ui/label'
import { SELECT_MD } from '@/lib/formStyles'
import type { Abschlussziel, KursMathe } from '@/types'
import { ABSCHLUSSZIELE, KURSE_MATHE } from './intakeConstants'

type KursFelderProps = {
  idPrefix: string
  kurs: KursMathe | null
  ziel: Abschlussziel | null
  disabled?: boolean
  onChange: (next: { kurs_mathe?: KursMathe | null; abschlussziel?: Abschlussziel | null }) => void
}

/**
 * SF-1: Mathe-Kurs (E/G) und Abschlussziel. Erscheint bei Gesamt- und Sekundarschule — im Erstgespräch
 * (leads) und in der Schülerakte (kind_kurs). Werte für die DB, Anzeige über i18n.
 */
export function KursFelder({
  idPrefix,
  kurs,
  ziel,
  disabled = false,
  onChange,
}: KursFelderProps): JSX.Element {
  const { t } = useTranslation('admin')
  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
      <div className="flex flex-col gap-2">
        <Label htmlFor={`${idPrefix}-kurs`}>{t('intake.kurs.kurs')}</Label>
        <select
          id={`${idPrefix}-kurs`}
          className={SELECT_MD}
          value={kurs ?? ''}
          disabled={disabled}
          onChange={(e) =>
            onChange({
              kurs_mathe: (e.target.value || null) as KursMathe | null,
            })
          }
        >
          <option value="">{t('intake.kurs.offen')}</option>
          {KURSE_MATHE.map((k) => (
            <option key={k} value={k}>
              {t(`intake.kurs.kurse.${k}`)}
            </option>
          ))}
        </select>
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor={`${idPrefix}-ziel`}>{t('intake.kurs.ziel')}</Label>
        <select
          id={`${idPrefix}-ziel`}
          className={SELECT_MD}
          value={ziel ?? ''}
          disabled={disabled}
          onChange={(e) =>
            onChange({
              abschlussziel: (e.target.value || null) as Abschlussziel | null,
            })
          }
        >
          <option value="">{t('intake.kurs.offen')}</option>
          {ABSCHLUSSZIELE.map((z) => (
            <option key={z} value={z}>
              {t(`intake.kurs.ziele.${z}`)}
            </option>
          ))}
        </select>
      </div>
    </div>
  )
}
