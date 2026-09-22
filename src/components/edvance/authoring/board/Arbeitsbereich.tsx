// Der Arbeitsbildschirm des Boards: ein Fach einer Klasse. Oben der Stand
// ("33 von 361 geprueft") mit Balken, darunter vier Filter mit Anzahl und der
// Durchlauf ueber alles im Filter; darunter die Themengebiete.
//
// Der Filter wirkt auf beide Ebenen: Themen ohne passende Aufgabe fallen weg,
// aufgeklappt stehen nur die passenden Aufgaben. Ein Durchlauf nimmt genau das,
// was der Filter zeigt — Standard ist "Offen".

import { useMemo, useState, type JSX } from 'react'
import { useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Play } from 'lucide-react'
import { EdvanceCard, EmptyState } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import {
  BOARD_FILTER,
  passtZuFilter,
  standVon,
  themenVon,
  warteschlange,
  warteschlangeAb,
  type BoardCluster,
  type BoardFilter,
  type Thema,
} from '@/lib/authoring/board'
import { freigabeCluster, type LetzteBeanstandung } from '@/lib/supabase/freigabe'
import type { AuthoringTask } from '@/types'
import { ChoiceChip } from '../wizard/ChoiceChip'
import { FortschrittsBalken } from './FortschrittsBalken'
import { ThemaZeile } from './ThemaZeile'

export function Arbeitsbereich({
  titel,
  returnTo,
  tasks,
  clusters,
  beanstandungen,
  isAdmin,
  onReload,
}: {
  /** "Mathematik · Klasse 8" — auch Label der Warteschlange. */
  titel: string
  /** Die URL dieses Bildschirms — hierhin fuehrt die Strecke zurueck. */
  returnTo: string
  tasks: AuthoringTask[]
  clusters: Map<string, BoardCluster>
  beanstandungen: Map<string, LetzteBeanstandung>
  isAdmin: boolean
  onReload: () => void
}): JSX.Element {
  const { t } = useTranslation('authoring')
  const navigate = useNavigate()
  const [filter, setFilter] = useState<BoardFilter>('offen')
  const [offenesThema, setOffenesThema] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  const [meldung, setMeldung] = useState<string | null>(null)

  const stand = useMemo(() => standVon(tasks), [tasks])
  const themen = useMemo(() => themenVon(tasks, clusters), [tasks, clusters])
  const sichtbar = themen.filter((th) => th.tasks.some((task) => passtZuFilter(task, filter)))

  const starte = (ids: string[], label: string): void => {
    if (ids.length === 0) return
    navigate('/admin/pflege', { state: { ids, label, returnTo } })
  }
  const themaName = (th: Thema): string => th.name ?? t('board.ohneThema')
  const themaKey = (th: Thema): string => th.id ?? 'ohne'

  const freigeben = async (th: Thema): Promise<void> => {
    if (!th.id) return
    setBusy(true)
    setMeldung(null)
    const res = await freigabeCluster(th.id)
    setBusy(false)
    if (res.error || res.data === null) {
      setMeldung(t('clusterRelease.failed', { error: res.error ?? '' }))
      return
    }
    setMeldung(t('clusterRelease.done', { count: res.data }))
    onReload()
  }

  const alle = warteschlange(themen, filter)

  return (
    <div className="flex flex-col gap-6">
      <EdvanceCard className="flex flex-col gap-4 p-6">
        <div className="flex flex-wrap items-baseline justify-between gap-2">
          <h2 className="text-base font-semibold text-[var(--color-text-primary)]">{titel}</h2>
          <span className="text-sm text-[var(--color-text-secondary)]">
            {t('board.stand', { geprueft: stand.geprueft, total: stand.total, frei: stand.freigegeben })}
          </span>
        </div>
        <FortschrittsBalken stand={stand} />
        <div className="flex flex-wrap items-center gap-2">
          {BOARD_FILTER.map((f) => (
            <ChoiceChip
              key={f}
              selected={filter === f}
              onClick={() => {
                setFilter(f)
                setOffenesThema(null)
              }}
            >
              {t(`board.filter.${f}`, { count: stand[f] })}
            </ChoiceChip>
          ))}
          <Button
            className="ml-auto"
            disabled={alle.length === 0}
            title={alle.length === 0 ? t('board.keineImFilter') : undefined}
            onClick={() => starte(alle, titel)}
          >
            <Play className="h-4 w-4" aria-hidden="true" />
            {t('board.durchlaufAlle', { count: alle.length })}
          </Button>
        </div>
        {meldung && (
          <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{meldung}</p>
        )}
      </EdvanceCard>

      <EdvanceCard className="flex flex-col px-6">
        {sichtbar.length === 0 ? (
          <EmptyState
            icon="🔍"
            title={t('board.keinThemaTitel')}
            description={t(`board.keinThema.${filter}`)}
          />
        ) : (
          sichtbar.map((th) => (
            <ThemaZeile
              key={themaKey(th)}
              thema={th}
              filter={filter}
              offen={offenesThema === themaKey(th)}
              isAdmin={isAdmin}
              busy={busy}
              beanstandungen={beanstandungen}
              onToggle={() =>
                setOffenesThema((o) => (o === themaKey(th) ? null : themaKey(th)))
              }
              onDurchlauf={() =>
                starte(
                  th.tasks.filter((task) => passtZuFilter(task, filter)).map((task) => task.id),
                  t('board.queueLabel', { titel, thema: themaName(th) }),
                )
              }
              onAufgabe={(id) =>
                starte(warteschlangeAb(th, id, 'offen'), t('board.queueLabel', { titel, thema: themaName(th) }))
              }
              onFreigeben={() => void freigeben(th)}
            />
          ))
        )}
      </EdvanceCard>
    </div>
  )
}
