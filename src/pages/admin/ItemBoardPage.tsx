// Item-Pflege (/admin/authoring) — das Freigabe-Board.
//
// Vier Ebenen, jede als eigener Bildschirm, der Zustand steht in der URL
// (?bereich=lsa&klasse=8&fach=Mathematik) — Zurueck im Browser funktioniert,
// und die Pflege-Strecke kehrt an genau diese Stelle zurueck:
//
//   Bereich (Lernstandsanalyse | Sessions) › Klasse (8 | 9 | 10) › Fach › Arbeit
//
// Auf dem Arbeitsbildschirm stehen die Heimat-Themen der Aufgaben (skill_thema),
// nicht mehr die Cluster/Inhaltsfelder (W4).
//
// Die Zuordnungsregeln stehen in src/lib/authoring/board.ts. Die bisherige
// Filterliste bleibt als Expertenansicht unter /admin/authoring/liste.

import { useEffect, useMemo, useState, type JSX } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { ChevronRight } from 'lucide-react'
import { AdminHeader, EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { buttonVariants } from '@/components/ui/button'
import { Arbeitsbereich } from '@/components/edvance/authoring/board/Arbeitsbereich'
import { BoardKachel } from '@/components/edvance/authoring/board/BoardKachel'
import {
  aktiveKlassen,
  boardBestand,
  boardKlassen,
  FAECHER,
  fachVon,
  inKlasse,
  standVon,
  zuordnungAus,
  type BoardCluster,
  type Zuordnung,
} from '@/lib/authoring/board'
import { listLetzteBeanstandungen, type LetzteBeanstandung } from '@/lib/supabase/freigabe'
import { listAuthoringTasks, listClustersWithSubject } from '@/lib/supabase/taskAuthoring'
import { listSkillThemen } from '@/lib/supabase/themen'
import { useAuth } from '@/hooks/useAuth'
import type { AuthoringTask, Fehlbild, PruefAdminZeile } from '@/types'
import { getFehlbilder, getPruefAdminListe } from '@/lib/supabase/pruefung'
import { PruefEinstellungenKarte } from '@/components/edvance/authoring/board/PruefEinstellungenKarte'

const BASIS = '/admin/authoring'

export function ItemBoardPage(): JSX.Element {
  const { t } = useTranslation('authoring')
  const { role } = useAuth()
  const [params, setParams] = useSearchParams()
  const bereich = params.get('bereich')
  const klasse = params.get('klasse') ? Number(params.get('klasse')) : null
  const fach = params.get('fach')

  const [tasks, setTasks] = useState<AuthoringTask[]>([])
  const [clusters, setClusters] = useState<Map<string, BoardCluster>>(new Map())
  const [zuordnung, setZuordnung] = useState<Zuordnung>(new Map())
  const [beanstandungen, setBeanstandungen] = useState<Map<string, LetzteBeanstandung>>(new Map())
  const [lena, setLena] = useState<Map<string, PruefAdminZeile>>(new Map())
  const [fehlbilder, setFehlbilder] = useState<Fehlbild[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [reloadKey, setReloadKey] = useState(0)

  useEffect(() => {
    let alive = true
    void (async () => {
      const [taskRes, clusterRes, themaRes, reviewRes, lenaRes, fehlbildRes] = await Promise.all([
        listAuthoringTasks(),
        listClustersWithSubject(),
        listSkillThemen(),
        listLetzteBeanstandungen(),
        getPruefAdminListe(),
        getFehlbilder(),
      ])
      if (!alive) return
      if (taskRes.error || !taskRes.data) {
        setError(taskRes.error ?? t('page.loadError'))
      } else {
        setError(null)
        // VERA8 gehoert nicht ins Board — die Expertenliste zeigt weiter alles.
        setTasks(boardBestand(taskRes.data))
      }
      setClusters(new Map((clusterRes.data ?? []).map((c) => [c.id, c])))
      // Ohne Zuordnung bleibt das Board bedienbar — alles steht dann unter "Ohne Thema".
      setZuordnung(zuordnungAus(themaRes.data ?? []))
      // Ohne Gruende bleibt das Board bedienbar — sie fehlen dann nur unter den Aufgaben.
      setBeanstandungen(reviewRes.data ?? new Map())
      // Lenas Ergebnis (Lena-Board). Ohne es bleibt das Board bedienbar.
      setLena(new Map((lenaRes.data ?? []).map((z) => [z.task_id, z])))
      setFehlbilder(fehlbildRes.data ?? [])
      setLoading(false)
    })()
    return () => {
      alive = false
    }
  }, [reloadKey, t])

  const inBereich = useMemo(() => (bereich === 'lsa' ? tasks : []), [bereich, tasks])
  const aktive = useMemo(() => aktiveKlassen(tasks), [tasks])
  const inKlasseListe = useMemo(
    () => (klasse == null ? [] : inBereich.filter((task) => inKlasse(task, klasse, aktive))),
    [inBereich, klasse, aktive],
  )
  const imFach = useMemo(
    () => (fach == null ? [] : inKlasseListe.filter((task) => fachVon(task, clusters) === fach)),
    [inKlasseListe, fach, clusters],
  )

  const url = (p: Record<string, string>): string => `${BASIS}?${new URLSearchParams(p).toString()}`
  const gehe = (p: Record<string, string>): void => setParams(p)
  const fachLabel = (f: string): string => t(`board.fach.${f}`, { defaultValue: f })
  const klasseLabel = (k: number): string => t('board.klasse', { klasse: k })

  let titel = t('page.listTitle')
  let backTo = '/admin'
  if (bereich) {
    titel = t(`board.bereich.${bereich}`)
    backTo = BASIS
  }
  if (bereich && klasse != null) {
    titel = klasseLabel(klasse)
    backTo = url({ bereich })
  }
  if (bereich && klasse != null && fach) {
    titel = t('board.titelArbeit', { fach: fachLabel(fach), klasse })
    backTo = url({ bereich, klasse: String(klasse) })
  }

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <EdvanceNavbar subtitle={t('page.listSubtitle')} sticky />
      <main className="mx-auto flex max-w-5xl flex-col gap-6 px-4 py-8">
        <AdminHeader
          title={titel}
          backTo={backTo}
          backLabel={t('page.back')}
          description={t(`board.ebene.${fach ? 'arbeit' : klasse != null ? 'fach' : bereich ? 'klasse' : 'bereich'}`)}
          actions={
            !bereich ? (
              <Link to={`${BASIS}/liste`} className={buttonVariants({ variant: 'outline', size: 'sm' })}>
                {t('board.expertenliste')}
              </Link>
            ) : undefined
          }
        />

        {bereich && (
          <nav aria-label={t('board.pfad')} className="flex flex-wrap items-center gap-2 text-sm">
            <Link to={url({ bereich })} className="text-[var(--color-text-link)] hover:underline">
              {t(`board.bereich.${bereich}`)}
            </Link>
            {klasse != null && (
              <>
                <ChevronRight className="h-4 w-4 text-[var(--color-text-tertiary)]" aria-hidden="true" />
                <Link
                  to={url({ bereich, klasse: String(klasse) })}
                  className="text-[var(--color-text-link)] hover:underline"
                >
                  {klasseLabel(klasse)}
                </Link>
              </>
            )}
            {fach && (
              <>
                <ChevronRight className="h-4 w-4 text-[var(--color-text-tertiary)]" aria-hidden="true" />
                <span className="text-[var(--color-text-secondary)]">{fachLabel(fach)}</span>
              </>
            )}
          </nav>
        )}

        {error && <EmptyState icon="⚠️" title={t('list.errorTitle')} description={error} />}
        {!error && loading && <LoadingPulse type="list" lines={4} />}

        {!error && !loading && !bereich && role === 'admin' && (
          <PruefEinstellungenKarte pilotAnzahl={[...lena.values()].filter((z) => z.pilot).length} />
        )}

        {!error && !loading && !bereich && (
          <div className="grid gap-4 sm:grid-cols-2">
            <BoardKachel titel={t('board.bereich.lsa')} stand={standVon(tasks)} onOpen={() => gehe({ bereich: 'lsa' })} />
            <BoardKachel titel={t('board.bereich.sessions')} stand={standVon([])} onOpen={() => undefined} />
          </div>
        )}

        {!error && !loading && bereich && klasse == null && (
          <div className="grid gap-4 sm:grid-cols-3">
            {boardKlassen(aktive).map((k) => (
              <BoardKachel
                key={k}
                titel={klasseLabel(k)}
                stand={standVon(inBereich.filter((task) => inKlasse(task, k, aktive)))}
                onOpen={() => gehe({ bereich, klasse: String(k) })}
              />
            ))}
          </div>
        )}

        {!error && !loading && bereich && klasse != null && !fach && (
          <div className="grid gap-4 sm:grid-cols-3">
            {FAECHER.map((f) => (
              <BoardKachel
                key={f}
                titel={fachLabel(f)}
                stand={standVon(inKlasseListe.filter((task) => fachVon(task, clusters) === f))}
                onOpen={() => gehe({ bereich, klasse: String(klasse), fach: f })}
              />
            ))}
          </div>
        )}

        {!error && !loading && bereich && klasse != null && fach && (
          <Arbeitsbereich
            titel={titel}
            returnTo={url({ bereich, klasse: String(klasse), fach })}
            klasse={klasse}
            tasks={imFach}
            zuordnung={zuordnung}
            beanstandungen={beanstandungen}
            lena={lena}
            fehlbildName={(slug) => fehlbilder.find((f) => f.slug === slug)?.klartext ?? slug}
            isAdmin={role === 'admin'}
            onReload={() => setReloadKey((k) => k + 1)}
          />
        )}
      </main>
    </div>
  )
}
