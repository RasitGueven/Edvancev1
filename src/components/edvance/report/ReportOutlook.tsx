import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { REPORT_PAKETE, type ReportNotes, type ReportPaket } from '@/types'

/**
 * Ausblick — die einzigen SCHREIBENDEN Felder des Reports.
 *
 * v1: der Coach formuliert Zielbild und Empfehlung frei und wählt das Paket von
 * Hand. Die Empfehlungsregeln (welches Paket folgt aus welchem Befund) kommen
 * später; bis dahin wird hier bewusst nichts automatisch vorbelegt.
 */
interface ReportOutlookProps {
  name: string
  notes: ReportNotes
  onChange: (notes: ReportNotes) => void
  onSave: () => void
  saving: boolean
  saved: boolean
  /** true, solange die Ablage-Migration fehlt — Felder bleiben lesbar. */
  unavailable: boolean
}

export function ReportOutlook({
  name,
  notes,
  onChange,
  onSave,
  saving,
  saved,
  unavailable,
}: ReportOutlookProps): JSX.Element {
  const { t } = useTranslation('report')

  const fieldClass =
    'min-h-[104px] w-full rounded-[var(--radius-md)] border border-[color-mix(in_srgb,var(--color-report-navy)_18%,transparent)] bg-white p-3 text-sm leading-relaxed text-[var(--color-report-navy)] outline-none focus:border-[var(--color-report-gold)] disabled:opacity-60'

  return (
    <section className="report-block flex flex-col gap-5">
      <h3 className="font-serif text-xl font-semibold text-[var(--color-report-navy)]">
        {t('outlook.title')}
      </h3>

      {unavailable && (
        <p className="print-hide rounded-[var(--radius-md)] bg-[var(--color-gold-warning-light)] p-3 text-xs text-[var(--color-gold-warning)]">
          {t('outlook.unavailable')}
        </p>
      )}

      <div className="flex flex-col gap-2">
        <label
          htmlFor="report-zielbild"
          className="text-sm font-semibold text-[var(--color-report-navy)]"
        >
          {t('outlook.goal')}
        </label>
        <textarea
          id="report-zielbild"
          className={fieldClass}
          value={notes.zielbild}
          disabled={unavailable}
          placeholder={t('outlook.goalPlaceholder', { name })}
          onChange={(e) => onChange({ ...notes, zielbild: e.target.value })}
        />
      </div>

      <div className="flex flex-col gap-2">
        <label
          htmlFor="report-empfehlung"
          className="text-sm font-semibold text-[var(--color-report-navy)]"
        >
          {t('outlook.recommendation')}
        </label>
        <textarea
          id="report-empfehlung"
          className={fieldClass}
          value={notes.empfehlung}
          disabled={unavailable}
          placeholder={t('outlook.recommendationPlaceholder')}
          onChange={(e) => onChange({ ...notes, empfehlung: e.target.value })}
        />
      </div>

      <div className="flex flex-col gap-2">
        <span className="text-sm font-semibold text-[var(--color-report-navy)]">
          {t('outlook.paket')}
        </span>
        <div className="flex flex-wrap gap-2">
          {REPORT_PAKETE.map((paket: ReportPaket) => {
            const active = notes.paket === paket
            return (
              <button
                key={paket}
                type="button"
                disabled={unavailable}
                aria-pressed={active}
                onClick={() =>
                  onChange({ ...notes, paket: active ? null : paket })
                }
                className={`min-h-[44px] rounded-[var(--radius-md)] border px-5 text-sm font-semibold transition-colors disabled:opacity-60 ${
                  active
                    ? 'border-[var(--color-report-gold)] bg-[var(--color-report-gold)] text-white'
                    : 'border-[color-mix(in_srgb,var(--color-report-navy)_18%,transparent)] bg-white text-[var(--color-report-navy)]'
                }`}
              >
                {t(`outlook.paketOption.${paket}`)}
              </button>
            )
          })}
        </div>
        {!notes.paket && (
          <p className="text-xs text-[color-mix(in_srgb,var(--color-report-navy)_55%,transparent)]">
            {t('outlook.paketNone')}
          </p>
        )}
      </div>

      <div className="print-hide flex items-center gap-3">
        <Button type="button" onClick={onSave} disabled={unavailable || saving}>
          {saving ? t('outlook.saving') : t('outlook.save')}
        </Button>
        {saved && !saving && (
          <span className="text-xs font-medium text-[var(--color-success)]">
            {t('outlook.saved')}
          </span>
        )}
      </div>
    </section>
  )
}
