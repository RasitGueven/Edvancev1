import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { NotebookPen } from 'lucide-react'
import { EmptyState, LoadingPulse } from '@/components/edvance'
import { Label } from '@/components/ui/label'
import { SELECT_MD } from '@/lib/formStyles'
import { stufeFuerKlasse } from '@/lib/themen/suche'
import { planStand } from '@/lib/themen/vorbelegung'
import { fachSchluessel } from '@/lib/supabase/themen'
import { getClusterById } from '@/lib/supabase/tasks'
import { CLASS_LEVELS, SUBJECTS } from './intakeConstants'
import { OptionChips } from './OptionChips'
import { SchonBehandelt } from './SchonBehandelt'
import { StufenChips } from './StufenChips'
import { ThemaSuche } from './ThemaSuche'
import type { ThemaChipZustand } from './ThemaChip'
import type { IntakeFormState } from './formState'
import { useThemenAuswahl } from './useThemenAuswahl'

export type ThemenStatus = { aktuell: string | null; katalogLeer: boolean }

type ThemenAuswahlProps = {
  form: IntakeFormState
  patch: (next: Partial<IntakeFormState>) => void
  /** Das Fach der Themenauswahl — bei mehreren Faechern die Auswahl. */
  subject: string | null
  leadId: string | null
  onStatus: (status: ThemenStatus) => void
}

/**
 * „Aktuelles Thema" und „schon behandelt" aus dem Themenkatalog (ersetzt die
 * Cluster-Auswahl). Fehlen Klasse oder Fach, werden sie hier nachgetragen.
 * Bestandsleads mit altem Cluster zeigen dessen Namen, bis ein Thema gewaehlt
 * ist; die Spalte wird nicht mehr beschrieben.
 */
export function ThemenAuswahl({
  form,
  patch,
  subject,
  leadId,
  onStatus,
}: ThemenAuswahlProps): JSX.Element {
  const { t } = useTranslation('admin')
  const needsClass = form.class_level === null
  const needsSubject = form.subjects.length === 0
  const fach = !needsClass && subject !== null ? fachSchluessel(subject) : null

  const auswahl = useThemenAuswahl({
    leadId,
    fach,
    schuleId: form.schule_id,
    klasse: form.class_level,
  })
  const { katalog, plan, leadThemen, aktuell } = auswahl
  const katalogLeer = katalog !== null && katalog.length === 0

  useEffect(() => {
    onStatus({ aktuell, katalogLeer })
  }, [aktuell, katalogLeer, onStatus])

  const [altesCluster, setAltesCluster] = useState<string | null>(null)
  const clusterId = form.current_topic_cluster_id
  useEffect(() => {
    if (!clusterId) return
    let active = true
    void getClusterById(clusterId).then(({ data }) => {
      if (active) setAltesCluster(data?.name ?? null)
    })
    return () => {
      active = false
    }
  }, [clusterId])

  const kindStufe = stufeFuerKlasse(form.class_level)
  const hatPlan = form.schule_id !== null && plan.length > 0
  const zustandVon = (key: string): ThemaChipZustand => {
    const row = leadThemen.find((x) => x.thema_key === key)
    return row ? row.status : 'frei'
  }
  const ausPlan = (key: string): boolean =>
    leadThemen.some((x) => x.thema_key === key && x.quelle === 'schulplan')
  const aktuellLabel = katalog?.find((x) => x.thema_key === aktuell)?.label ?? null

  const toggleSubject = (value: string): void => {
    const list = form.subjects
    patch({ subjects: list.includes(value) ? list.filter((s) => s !== value) : [...list, value] })
  }

  const fehltText =
    needsClass && needsSubject
      ? t('intake.thema.fehltBeides')
      : needsClass
        ? t('intake.thema.fehltKlasse')
        : needsSubject
          ? t('intake.thema.fehltFach')
          : null

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-col gap-2">
        <Label htmlFor="thema-suche" className="text-base font-semibold">
          {t('intake.thema.label')}
        </Label>
        <p className="inline-flex items-center gap-2 text-xs text-[var(--color-text-tertiary)]">
          <NotebookPen className="h-4 w-4 shrink-0" aria-hidden />
          {t('intake.thema.heftHinweis')}
        </p>
        {altesCluster && aktuell === null && (
          <div className="flex flex-col gap-2 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-subtle)] p-4">
            <p className="text-sm text-[var(--color-text-secondary)]">
              {t('intake.thema.altesThema', { name: altesCluster })}
            </p>
            <p className="text-xs text-[var(--color-text-tertiary)]">
              {t('intake.thema.altesThemaHinweis')}
            </p>
          </div>
        )}
      </div>

      {fehltText !== null && (
        <div className="flex flex-col gap-4 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-subtle)] p-4">
          <p className="text-sm text-[var(--color-text-secondary)]">{fehltText}</p>
          {needsClass && (
            <div className="flex flex-col gap-2">
              <Label htmlFor="topic-class">{t('intake.lead.classLevel')}</Label>
              <select
                id="topic-class"
                className={SELECT_MD}
                value={form.class_level ?? ''}
                onChange={(e) =>
                  patch({ class_level: e.target.value ? Number(e.target.value) : null })
                }
              >
                <option value="">{t('intake.lead.none')}</option>
                {CLASS_LEVELS.map((level) => (
                  <option key={level} value={level}>
                    {t('intake.lead.classOption', { level })}
                  </option>
                ))}
              </select>
            </div>
          )}
          {needsSubject && (
            <div className="flex flex-col gap-2">
              <Label>{t('intake.lead.subjects')}</Label>
              <OptionChips
                options={SUBJECTS.map((s) => ({ value: s, label: s }))}
                selected={form.subjects}
                onToggle={toggleSubject}
              />
            </div>
          )}
        </div>
      )}

      {fehltText === null && subject === null && (
        <p className="text-xs text-[var(--color-text-tertiary)]">{t('intake.thema.fachWaehlen')}</p>
      )}

      {fach !== null && auswahl.loading && <LoadingPulse type="list" lines={2} />}

      {fach !== null && !auswahl.loading && auswahl.ladeFehler !== null && (
        <p className="text-sm text-[var(--color-error-exam)]">
          {t('intake.thema.ladeFehler', { fehler: auswahl.ladeFehler })}
        </p>
      )}

      {fach !== null && !auswahl.loading && katalogLeer && (
        <EmptyState
          icon="📚"
          title={t('intake.thema.leerTitel')}
          description={t('intake.thema.leerText', { fach: subject })}
        />
      )}

      {fach !== null && !auswahl.loading && katalog !== null && katalog.length > 0 && (
        <>
          <ThemaSuche
            katalog={katalog}
            stufe={kindStufe}
            aktuell={aktuell}
            disabled={auswahl.busy || leadId === null}
            onWaehle={(key) => void auswahl.waehleAktuell(key)}
          />
          {aktuellLabel && (
            <p className="text-sm font-semibold text-[var(--color-text-primary)]" role="status">
              {t('intake.thema.aktuell', { label: aktuellLabel })}
            </p>
          )}
          {auswahl.speicherFehler !== null && (
            <p className="text-sm text-[var(--color-error-exam)]">
              {t('intake.thema.speicherFehler', { fehler: auswahl.speicherFehler })}
            </p>
          )}
          <StufenChips
            katalog={katalog}
            plan={plan}
            kindStufe={kindStufe}
            zustandVon={zustandVon}
            ausPlan={ausPlan}
            disabled={auswahl.busy || leadId === null}
            onAktuell={(key) => void auswahl.waehleAktuell(key)}
            onBehandelt={(key) => void auswahl.toggleBehandelt(key)}
          />
          {kindStufe !== null && (
            <SchonBehandelt
              katalog={katalog}
              kindStufe={kindStufe}
              leadThemen={leadThemen}
              aktuell={aktuell}
              hatPlan={hatPlan}
              stand={planStand(plan)}
              disabled={auswahl.busy || leadId === null}
              onToggle={(key) => void auswahl.toggleBehandelt(key)}
            />
          )}
        </>
      )}
    </div>
  )
}
