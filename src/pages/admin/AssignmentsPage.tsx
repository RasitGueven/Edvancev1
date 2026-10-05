import { useEffect, useMemo, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Input } from '@/components/ui/input'
import {
  EdvanceCard,
  EdvanceBadge,
  EmptyState,
  LoadingPulse,
} from '@/components/edvance'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { listStudentsWithName } from '@/lib/supabase/students'
import { getCoaches } from '@/lib/supabase/profiles'
import {
  listActiveAssignments,
  setStudentCoach,
} from '@/lib/supabase/studentCoach'
import { SELECT_MD } from '@/lib/formStyles'
import { cn } from '@/lib/utils'
import type { Coach, StudentWithName } from '@/types'

export function AssignmentsPage(): JSX.Element {
  const { t } = useTranslation('admin')
  const [students, setStudents] = useState<StudentWithName[]>([])
  const [coaches, setCoaches] = useState<Coach[]>([])
  const [assign, setAssign] = useState<Record<string, string>>({})
  const [query, setQuery] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [savingId, setSavingId] = useState<string | null>(null)

  const load = (): void => {
    setLoading(true)
    void Promise.all([
      listStudentsWithName(),
      getCoaches(),
      listActiveAssignments(),
    ]).then(([s, c, a]) => {
      setStudents(s.data ?? [])
      setCoaches(c.data ?? [])
      const map: Record<string, string> = {}
      for (const row of a.data ?? []) map[row.student_id] = row.coach_id
      setAssign(map)
      setError(s.error ?? c.error ?? a.error)
      setLoading(false)
    })
  }

  useEffect(load, [])

  const coachName = useMemo(() => {
    const m: Record<string, string> = {}
    for (const c of coaches) m[c.id] = c.full_name ?? t('zuordnung.unbenannt')
    return m
  }, [coaches, t])

  const visible = useMemo(() => {
    const q = query.trim().toLowerCase()
    if (!q) return students
    return students.filter((s) =>
      (s.full_name ?? '').toLowerCase().includes(q),
    )
  }, [students, query])

  const change = async (
    studentId: string,
    value: string,
  ): Promise<void> => {
    const coachId = value === '' ? null : value
    setSavingId(studentId)
    setError(null)
    const { error: e } = await setStudentCoach(studentId, coachId)
    setSavingId(null)
    if (e) {
      setError(e)
      return
    }
    setAssign((prev) => {
      const next = { ...prev }
      if (coachId === null) delete next[studentId]
      else next[studentId] = coachId
      return next
    })
  }

  return (
    <>
      <PageHeader rubrik={t('zuordnung.rubrik')} titel={t('zuordnung.titel')} satz={t('zuordnung.satz')} />

      {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}

      <Input
        className="max-w-md"
        placeholder={t('zuordnung.suche')}
        aria-label={t('zuordnung.suche')}
        value={query}
        onChange={(e) => setQuery(e.target.value)}
      />

      {loading ? (
        <LoadingPulse type="card" />
      ) : visible.length === 0 ? (
        <EmptyState icon="🧑‍🏫" title={t('zuordnung.leer.titel')} description={t('zuordnung.leer.beschreibung')} />
      ) : (
        <div className="grid grid-cols-1 gap-4 @5xl:grid-cols-2">
          {visible.map((s) => {
            const current = assign[s.id] ?? ''
            const name = s.full_name ?? t('zuordnung.unbenannt')
            return (
              <EdvanceCard
                key={s.id}
                className="flex flex-col gap-3 p-6 sm:flex-row sm:items-center sm:justify-between"
              >
                <div className="flex flex-col gap-1">
                  <p className="text-base font-semibold text-[var(--color-text-primary)]">{name}</p>
                  <div className="flex items-center gap-2">
                    {s.class_level && (
                      <span className="text-xs text-[var(--color-text-tertiary)]">
                        {t('zuordnung.klasse', { klasse: s.class_level })}
                      </span>
                    )}
                    <EdvanceBadge variant={current ? 'success' : 'muted'}>
                      {current ? (coachName[current] ?? t('zuordnung.coach')) : t('zuordnung.keinCoach')}
                    </EdvanceBadge>
                  </div>
                </div>
                <select
                  aria-label={t('zuordnung.coachFuer', { name })}
                  className={cn(SELECT_MD, 'w-full sm:w-64')}
                  value={current}
                  disabled={savingId === s.id}
                  onChange={(e) => void change(s.id, e.target.value)}
                >
                  <option value="">{t('zuordnung.keinCoachOption')}</option>
                  {coaches.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.full_name ?? t('zuordnung.unbenannt')}
                    </option>
                  ))}
                </select>
              </EdvanceCard>
            )
          })}
        </div>
      )}
    </>
  )
}
