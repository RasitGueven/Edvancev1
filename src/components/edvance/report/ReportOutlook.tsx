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
  /** Coach: liest den Ausblick, schreibt ihn nicht (Entscheidung 26). */
  nurLesen?: boolean
  /** L5 Teil D: Spalten für „im Gespräch bestätigt“ vorhanden — sonst keine Schalter. */
  bestaetigung?: boolean
}

export function ReportOutlook({
  name,
  notes,
  onChange,
  onSave,
  saving,
  saved,
  unavailable,
  nurLesen = false,
  bestaetigung = false,
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
          disabled={unavailable || nurLesen}
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
          disabled={unavailable || nurLesen}
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
                disabled={unavailable || nurLesen}
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

      {bestaetigung && (
        <div className="print-hide flex flex-col gap-2" data-testid="report-bestaetigung">
          <BestaetigtSchalter
            label={t('outlook.zieleBestaetigt')}
            an={notes.zieleBestaetigt === true}
            gesperrt={unavailable || nurLesen}
            onWechsel={(an) => onChange({ ...notes, zieleBestaetigt: an })}
          />
          <BestaetigtSchalter
            label={t('outlook.paketBestaetigt')}
            an={notes.paketBestaetigt === true}
            gesperrt={unavailable || nurLesen || notes.paket === null}
            hinweis={notes.paket === null ? t('outlook.paketBestaetigtOhnePaket') : undefined}
            onWechsel={(an) => onChange({ ...notes, paketBestaetigt: an })}
          />
          <p className="text-xs text-[color-mix(in_srgb,var(--color-report-navy)_55%,transparent)]">
            {t('outlook.bestaetigtHilfe')}
          </p>
        </div>
      )}

      {!nurLesen && (
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
      )}
    </section>
  )
}

/** L5 Teil D: Schalter „… im Gespräch bestätigt“ (role=switch, 44 px hoch). */
export function BestaetigtSchalter({
  label,
  an,
  gesperrt = false,
  hinweis,
  onWechsel,
}: {
  label: string
  an: boolean
  gesperrt?: boolean
  /** Grund, warum der Schalter gesperrt ist (Tooltip). */
  hinweis?: string
  onWechsel: (an: boolean) => void
}): JSX.Element {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={an}
      disabled={gesperrt}
      title={hinweis}
      onClick={() => onWechsel(!an)}
      className="flex min-h-[44px] items-center gap-3 self-start rounded-[var(--radius-md)] px-1 text-sm font-semibold text-[var(--color-report-navy)] disabled:opacity-60"
    >
      <span
        aria-hidden="true"
        className={`relative h-6 w-10 rounded-full transition-colors ${an ? 'bg-[var(--color-report-gold)]' : 'bg-[color-mix(in_srgb,var(--color-report-navy)_18%,transparent)]'}`}
      >
        <span className={`absolute top-1 h-4 w-4 rounded-full bg-white transition-all ${an ? 'left-5' : 'left-1'}`} />
      </span>
      {label}
    </button>
  )
}
