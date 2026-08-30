import { useEffect, useState } from 'react'
import { Label } from '@/components/ui/label'
import { SELECT_MD } from '@/lib/formStyles'
import { getClustersBySubject, getSubjects } from '@/lib/supabase/tasks'
import type { SkillCluster } from '@/types'
import { CLASS_LEVELS, SUBJECTS } from './intakeConstants'
import { OptionChips } from './OptionChips'
import type { IntakeFormState } from './formState'

type TopicSelectProps = {
  form: IntakeFormState
  patch: (next: Partial<IntakeFormState>) => void
  /** Das Fach, nach dem gefiltert wird — bei mehreren Faechern die Auswahl. */
  subject: string | null
}

/**
 * „Aktuelles Thema" — Auswahl aus den Themenclustern des Fachs, gefiltert auf
 * die Klassenstufe des Leads. Die Schulform filtert bewusst NICHT mit.
 * Gespeichert wird die Cluster-ID, nicht der Anzeigetext.
 *
 * Fehlen Klasse oder Fach, werden sie hier direkt nachgetragen statt den
 * Nutzer zurueck in Schritt 1 zu schicken — geschrieben wird in dieselben
 * Lead-Felder.
 */
export function TopicSelect({ form, patch, subject }: TopicSelectProps): JSX.Element {
  const [clusters, setClusters] = useState<SkillCluster[] | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const needsClass = form.class_level === null
  const needsSubject = form.subjects.length === 0
  const ready = !needsClass && !needsSubject && subject !== null

  useEffect(() => {
    if (!ready || form.class_level === null || subject === null) {
      setClusters(null)
      return
    }
    let active = true
    setLoading(true)
    setError(null)
    // Der Lead speichert Fachnamen, getClustersBySubject erwartet die UUID —
    // deshalb erst die Faecher aufloesen.
    void getSubjects().then(({ data: subjects, error: sErr }) => {
      if (!active) return
      if (sErr || !subjects) {
        setLoading(false)
        setError(sErr ?? 'Fächer konnten nicht geladen werden.')
        return
      }
      const match = subjects.find((s) => s.name === subject)
      if (!match) {
        setLoading(false)
        setClusters([])
        return
      }
      void getClustersBySubject(match.id, form.class_level ?? undefined).then(
        ({ data, error: cErr }) => {
          if (!active) return
          setLoading(false)
          if (cErr) {
            setError(cErr)
            return
          }
          setClusters(data ?? [])
        },
      )
    })
    return () => {
      active = false
    }
  }, [ready, subject, form.class_level])

  const toggleSubject = (value: string): void => {
    const list = form.subjects
    patch({
      subjects: list.includes(value) ? list.filter((s) => s !== value) : [...list, value],
      // Fachwechsel entwertet ein bereits gewaehltes Thema.
      current_topic_cluster_id: null,
    })
  }

  const missing = [needsClass ? 'Klasse' : null, needsSubject ? 'Fach' : null].filter(
    (v): v is string => v !== null,
  )

  return (
    <div className="flex flex-col gap-3">
      {missing.length > 0 && (
        <div className="flex flex-col gap-3 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-subtle)] p-4">
          <p className="text-sm text-[var(--color-text-secondary)]">
            Für die Themenauswahl fehlt noch: {missing.join(' und ')}
          </p>
          {needsClass && (
            <div className="flex flex-col gap-2">
              <Label htmlFor="topic-class">Klasse</Label>
              <select
                id="topic-class"
                className={SELECT_MD}
                value={form.class_level ?? ''}
                onChange={(e) =>
                  patch({
                    class_level: e.target.value ? Number(e.target.value) : null,
                    current_topic_cluster_id: null,
                  })
                }
              >
                <option value="">–</option>
                {CLASS_LEVELS.map((lvl) => (
                  <option key={lvl} value={lvl}>
                    {lvl}. Klasse
                  </option>
                ))}
              </select>
            </div>
          )}
          {needsSubject && (
            <div className="flex flex-col gap-2">
              <Label>Fach / Fächer</Label>
              <OptionChips
                options={SUBJECTS.map((s) => ({ value: s, label: s }))}
                selected={form.subjects}
                onToggle={toggleSubject}
              />
            </div>
          )}
        </div>
      )}

      <div className="flex flex-col gap-2">
        <Label htmlFor="topic-cluster">Aktuelles Thema</Label>
        <select
          id="topic-cluster"
          className={SELECT_MD}
          disabled={!ready || loading || (clusters?.length ?? 0) === 0}
          value={form.current_topic_cluster_id ?? ''}
          onChange={(e) => patch({ current_topic_cluster_id: e.target.value || null })}
        >
          <option value="">–</option>
          {(clusters ?? []).map((cluster) => (
            <option key={cluster.id} value={cluster.id}>
              {cluster.name}
            </option>
          ))}
        </select>

        {!ready && missing.length === 0 && subject === null && (
          <p className="text-xs text-[var(--color-text-tertiary)]">
            Bitte unten das Fach wählen — danach lässt sich das Thema auswählen.
          </p>
        )}
        {ready && loading && (
          <p className="text-xs text-[var(--color-text-tertiary)]">Themen werden geladen …</p>
        )}
        {ready && !loading && error !== null && (
          <p className="text-xs text-[var(--color-error-exam)]">{error}</p>
        )}
        {ready && !loading && error === null && clusters !== null && clusters.length === 0 && (
          <p className="text-xs text-[var(--color-text-tertiary)]">
            Für {subject} in Klasse {form.class_level} sind noch keine Themen hinterlegt.
          </p>
        )}
      </div>
    </div>
  )
}
