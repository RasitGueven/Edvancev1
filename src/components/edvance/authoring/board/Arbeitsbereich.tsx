// Der Arbeitsbildschirm des Boards: ein Fach einer Klasse. Oben der Stand
// ("33 von 361 geprueft") mit Balken, darunter vier Filter mit Anzahl und der
// Durchlauf ueber alles im Filter; darunter die Themen, nach Stufe gruppiert
// (die Stufe der Klasse zuerst, "Ohne Thema" zuletzt).
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
  stufenGruppen,
  themenVon,
  warteschlange,
  warteschlangeAb,
  type BoardFilter,
  type Thema,
  type Zuordnung,
} from '@/lib/authoring/board'
import { freigabeThema, type LetzteBeanstandung } from '@/lib/supabase/freigabe'
import type { AuthoringTask, PruefAdminZeile } from '@/types'
import { ChoiceChip } from '../wizard/ChoiceChip'
import { FortschrittsBalken } from './FortschrittsBalken'
import { ThemaZeile } from './ThemaZeile'

export function Arbeitsbereich({
  titel,
  returnTo,
  klasse,
  tasks,
  zuordnung,
  beanstandungen,
  lena,
  fehlbildName,
  isAdmin,
  onReload,
}: {
  /** "Mathematik · Klasse 8" — auch Label der Warteschlange. */
  titel: string
  /** Die URL dieses Bildschirms — hierhin fuehrt die Strecke zurueck. */
  returnTo: string
  /** Die Klasse des Boards — bestimmt Stufenfolge und Freigabe-Umfang. */
  klasse: number
  tasks: AuthoringTask[]
  zuordnung: Zuordnung
  beanstandungen: Map<string, LetzteBeanstandung>
  /** Lenas Ergebnis je Aufgabe (pruef_admin_liste), leer fuer Nicht-Admins. */
  lena: Map<string, PruefAdminZeile>
  fehlbildName: (slug: string) => string
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
  const themen = useMemo(() => themenVon(tasks, zuordnung, klasse), [tasks, zuordnung, klasse])
  const sichtbar = themen.filter((th) => th.tasks.some((task) => passtZuFilter(task, filter)))
  const abschnitte = stufenGruppen(sichtbar)

  const starte = (ids: string[], label: string): void => {
    if (ids.length === 0) return
    navigate('/admin/pflege', { state: { ids, label, returnTo, kontext: 'board' } })
  }
  const themaName = (th: Thema): string => th.name ?? t('board.ohneThema')
  const themaKey = (th: Thema): string => th.id ?? 'ohne'

  const freigeben = async (th: Thema): Promise<void> => {
    if (!th.id) return
    setBusy(true)
    setMeldung(null)
    const res = await freigabeThema(th.id, klasse)
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

      {sichtbar.length === 0 ? (
        <EdvanceCard className="flex flex-col px-6">
          <EmptyState
            icon="🔍"
            title={t('board.keinThemaTitel')}
            description={t(`board.keinThema.${filter}`)}
          />
        </EdvanceCard>
      ) : (
        abschnitte.map((abschnitt) => (
          <section key={abschnitt.stufe ?? 'ohne'} className="flex flex-col gap-2">
            <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
              {abschnitt.stufe ? t(`board.stufe.${abschnitt.stufe}`) : t('board.ohneZuordnung')}
            </h3>
            <EdvanceCard className="flex flex-col px-6">
              {abschnitt.themen.map((th) => (
                <ThemaZeile
                  key={themaKey(th)}
                  thema={th}
                  filter={filter}
                  offen={offenesThema === themaKey(th)}
                  isAdmin={isAdmin}
                  busy={busy}
                  beanstandungen={beanstandungen}
                  lena={lena}
                  fehlbildName={fehlbildName}
                  onReload={onReload}
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
              ))}
            </EdvanceCard>
          </section>
        ))
      )}
    </div>
  )
}
