import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { School } from 'lucide-react'
import { LoadingPulse } from '@/components/edvance'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { listSchulenAuswahl, type SchuleAuswahl } from '@/lib/supabase/schulen'
import { sucheSchulen } from '@/lib/themen/suche'

type SchulAuswahlProps = {
  schulform: string | null
  schuleId: string | null
  schoolName: string
  onChange: (next: { schule_id: string | null; school_name: string }) => void
}

/**
 * Schule aus public.schulen, gefiltert auf die Schulform, Suche nach Name und
 * Stadtteil. Die Auswahl setzt schule_id und uebernimmt den Namen in
 * school_name. Nicht in der Liste: Freitext ohne schule_id.
 */
export function SchulAuswahl({
  schulform,
  schuleId,
  schoolName,
  onChange,
}: SchulAuswahlProps): JSX.Element {
  const { t } = useTranslation('admin')
  const [schulen, setSchulen] = useState<SchuleAuswahl[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(false)

  useEffect(() => {
    let active = true
    setLoading(true)
    void listSchulenAuswahl(schulform).then(({ data, error: err }) => {
      if (!active) return
      setLoading(false)
      setError(err !== null)
      setSchulen(data ?? [])
    })
    return () => {
      active = false
    }
  }, [schulform])

  const gewaehlt = schuleId !== null
  const treffer = gewaehlt ? [] : sucheSchulen(schulen, schoolName)
  const getippt = schoolName.trim() !== ''
  const stadtteil = schulen.find((s) => s.id === schuleId)?.stadtteil ?? null

  return (
    <div className="flex flex-col gap-2">
      <Label htmlFor="lead-schoolname">{t('intake.schule.label')}</Label>
      {gewaehlt ? (
        <div className="flex flex-wrap items-center justify-between gap-2 rounded-xl border border-[var(--color-primary)] bg-[var(--color-primary-light)] px-4 py-2">
          <span className="inline-flex items-center gap-2 text-sm text-[var(--color-text-primary)]">
            <School className="h-4 w-4 shrink-0" aria-hidden />
            <span className="font-semibold">{schoolName}</span>
            {stadtteil && <span className="text-[var(--color-text-secondary)]">· {stadtteil}</span>}
          </span>
          <button
            type="button"
            onClick={() => onChange({ schule_id: null, school_name: '' })}
            className="min-h-[44px] text-sm font-medium text-[var(--color-text-link)]"
          >
            {t('intake.schule.aendern')}
          </button>
        </div>
      ) : (
        <Input
          id="lead-schoolname"
          value={schoolName}
          onChange={(e) => onChange({ schule_id: null, school_name: e.target.value })}
          placeholder={t('intake.schule.placeholder')}
          autoComplete="off"
        />
      )}

      {!gewaehlt && getippt && loading && <LoadingPulse type="list" lines={1} />}

      {treffer.length > 0 && (
        <div className="flex flex-col gap-2">
          {treffer.map((s) => (
            <button
              key={s.id}
              type="button"
              onClick={() => onChange({ schule_id: s.id, school_name: s.name })}
              className="flex min-h-[44px] items-center justify-between gap-2 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 py-2 text-left text-sm text-[var(--color-text-primary)] hover:border-[var(--color-primary)]"
            >
              <span className="font-medium">{s.name}</span>
              {s.stadtteil && (
                <span className="text-[var(--color-text-tertiary)]">{s.stadtteil}</span>
              )}
            </button>
          ))}
        </div>
      )}

      <p className="text-xs text-[var(--color-text-tertiary)]">
        {gewaehlt
          ? t('intake.schule.ausListe')
          : error
            ? t('intake.schule.fehler')
            : getippt && !loading && treffer.length === 0
              ? t('intake.schule.freitext')
              : t('intake.schule.hint')}
      </p>
    </div>
  )
}
