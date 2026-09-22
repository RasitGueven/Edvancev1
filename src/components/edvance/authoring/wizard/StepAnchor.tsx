// Schritt 2 — EINORDNUNG: Stoffanker und Themengebiet. Bestaetigen oder setzen.
//
// Ist der Wert vorbelegt (naechtliches Audit schreibt curriculum_grade direkt),
// erscheint er als VORSCHLAG: "Klasse 7 — bestaetigen?" mit einem Klick. Der
// Klick schreibt nichts — der Wert steht ja schon — er traegt nur weiter.
// Geaendert wird per Klick-Auswahl 5–9 (der VERA-Bestand ist Sek-I-Stoff); ein
// Bestandswert ausserhalb bleibt als eigene Kachel sichtbar, statt zu
// verschwinden. AFB steht daneben als reine Anzeige — andere Achse.
//
// Das THEMENGEBIET ist der Cluster (Entscheidung 22.09.: Skills erst in Runde
// zwei). Vorbelegt mit dem aktuellen Cluster; eine Aenderung wird wie jede
// andere beim Schrittwechsel gespeichert.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Check } from 'lucide-react'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import type { AuthoringCluster } from '@/lib/supabase/taskAuthoring'
import type { AuthoringTask } from '@/types'
import { ChoiceChip } from './ChoiceChip'

/** Klick-Auswahl des Wizards: Sek I. Der Editor kennt weiterhin 5–13. */
const WIZARD_GRADES = [5, 6, 7, 8, 9]

export function StepAnchor({
  task,
  grade,
  hasStoffanker,
  canWrite,
  clusters,
  clusterId,
  onSelect,
  onCluster,
  onConfirm,
}: {
  task: AuthoringTask
  /** Aktueller Formularwert (editorState.curriculum_grade, '' = nicht gesetzt). */
  grade: string
  hasStoffanker: boolean
  canWrite: boolean
  /** Waehlbare Themengebiete — die Cluster des Fachs. */
  clusters: AuthoringCluster[]
  /** Aktueller Formularwert (editorState.cluster_id, '' = nicht gesetzt). */
  clusterId: string
  onSelect: (grade: string) => void
  onCluster: (clusterId: string) => void
  /** Ein Klick: Vorschlag angenommen → naechster Schritt (speichert, wenn noetig). */
  onConfirm: () => void
}): JSX.Element {
  const { t } = useTranslation('authoring')

  const current = grade === '' ? null : Number.parseInt(grade, 10)
  const choices = [...WIZARD_GRADES]
  if (current != null && !choices.includes(current)) choices.push(current)
  choices.sort((a, b) => a - b)

  const partAfbs = task.parts.filter((p) => p.afb)

  return (
    <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,20rem)]">
      <EdvanceCard className="flex flex-col gap-4 p-6">
        <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('wizard.anchor.title')}
        </h3>

        <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
          {current != null
            ? t('wizard.anchor.suggestion', { grade: current })
            : t('wizard.anchor.unset')}
        </p>

        {current != null && (
          <Button size="lg" className="self-start" disabled={!hasStoffanker} onClick={onConfirm}>
            <Check className="h-4 w-4" aria-hidden="true" />
            {t('wizard.anchor.confirm')}
          </Button>
        )}

        <div className="flex flex-col gap-2">
          {current != null && (
            <span className="text-xs text-[var(--color-text-tertiary)]">
              {t('wizard.anchor.changeHint')}
            </span>
          )}
          <div className="flex flex-wrap gap-2">
            {choices.map((g) => (
              <ChoiceChip
                key={g}
                selected={current === g}
                disabled={!hasStoffanker || !canWrite}
                onClick={() => onSelect(String(g))}
              >
                {t('stoffanker.grade', { grade: g })}
              </ChoiceChip>
            ))}
          </div>
        </div>

        <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
          {hasStoffanker ? t('stoffanker.help') : t('schema.stoffanker')}
        </p>
        <span className="text-xs text-[var(--color-text-tertiary)]">
          {task.class_level != null
            ? t('stoffanker.origin', { grade: task.class_level })
            : t('stoffanker.originUnknown')}
        </span>

        <div className="flex flex-col gap-2 border-t border-[var(--color-border)] pt-4">
          <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('wizard.anchor.themeTitle')}
          </h3>
          <div className="flex flex-wrap gap-2">
            {clusters.map((c) => (
              <ChoiceChip
                key={c.id}
                selected={clusterId === c.id}
                disabled={!canWrite}
                onClick={() => onCluster(c.id)}
              >
                {c.name}
              </ChoiceChip>
            ))}
          </div>
          <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
            {clusterId === '' ? t('wizard.anchor.themeUnset') : t('wizard.anchor.themeHint')}
          </p>
        </div>
      </EdvanceCard>

      <EdvanceCard className="flex h-fit flex-col gap-3 p-6">
        <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('wizard.anchor.afbTitle')}
        </h3>
        {task.afb ? (
          <span className="text-sm font-semibold text-[var(--color-text-primary)]">
            {t(`afbLevel.${task.afb}`)}
          </span>
        ) : partAfbs.length > 0 ? (
          <ul className="flex flex-col gap-1">
            {partAfbs.map((p) => (
              <li key={p.nr} className="text-sm text-[var(--color-text-secondary)]">
                {t('wizard.anchor.afbPart', { nr: p.nr, afb: p.afb })}
              </li>
            ))}
          </ul>
        ) : (
          <span className="text-sm text-[var(--color-text-tertiary)]">
            {t('wizard.anchor.afbNone')}
          </span>
        )}
      </EdvanceCard>
    </div>
  )
}
