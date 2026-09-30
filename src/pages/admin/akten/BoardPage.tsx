import { useEffect, useMemo, useState } from 'react'
import { useLocation } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { AdminHeader, EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { useAuth } from '@/hooks/useAuth'
import { SELECT_MD } from '@/lib/formStyles'
import { listBoardSchueler } from '@/lib/supabase/akte'
import { baueSpalten, type BoardSortierung, type ZustandFilter } from '@/lib/akte/board'
import type { BoardSchueler } from '@/types'
import { BoardSpalte } from './BoardSpalte'

export type BoardHinweis = 'ruhendCoach' | 'nichtGefunden'

/**
 * Menue "Schueler" (/admin/akten): eine Spalte je Klassenstufe.
 * Admin und Coach sehen dieselbe Seite; welche Akten sie bekommen, entscheidet
 * board_schueler() in der Datenbank (Coach: nur aktive). Der Zustandsfilter
 * ist eine Admin-Bedienung — ein Coach hat ohnehin nur aktive Akten.
 */
export function BoardPage(): JSX.Element {
  const { t } = useTranslation('akte')
  const { role } = useAuth()
  const location = useLocation()
  const hinweis = (location.state as { hinweis?: BoardHinweis } | null)?.hinweis ?? null
  const istAdmin = role === 'admin'

  const [liste, setListe] = useState<BoardSchueler[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [sucheGlobal, setSucheGlobal] = useState('')
  const [sucheSpalte, setSucheSpalte] = useState<Record<string, string>>({})
  const [sortierung, setSortierung] = useState<BoardSortierung>('nachname')
  const [zustand, setZustand] = useState<ZustandFilter>('aktiv')

  useEffect(() => {
    void listBoardSchueler().then(({ data, error: e }) => {
      setListe(data ?? [])
      setError(e)
      setLoading(false)
    })
  }, [])

  const { spalten, trefferGesamt } = useMemo(
    () => baueSpalten(liste, { zustand: istAdmin ? zustand : 'aktiv', sucheGlobal, sucheSpalte, sortierung }),
    [liste, istAdmin, zustand, sucheGlobal, sucheSpalte, sortierung],
  )

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <EdvanceNavbar subtitle={t('board.titel')} sticky />
      <main className="mx-auto flex max-w-7xl flex-col gap-6 px-4 py-8">
        <AdminHeader
          eyebrow={t('board.eyebrow')}
          title={t('board.titel')}
          description={t('board.beschreibung')}
          backTo={istAdmin ? '/admin' : '/coach'}
          backLabel={istAdmin ? t('board.zurueckAdmin') : t('board.zurueckCoach')}
        />

        {hinweis && (
          <p role="status" className="rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] p-4 text-sm text-[var(--color-text-secondary)]">
            {t(`board.${hinweis}`)}
          </p>
        )}
        {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}

        <div className="flex flex-wrap items-end gap-4">
          <div className="flex min-w-64 flex-1 flex-col gap-2">
            <Label htmlFor="akte-suche">{t('board.sucheGlobal')}</Label>
            <Input id="akte-suche" value={sucheGlobal} onChange={(e) => setSucheGlobal(e.target.value)} />
          </div>
          {sucheGlobal.trim() && (
            <span className="pb-2 text-sm text-[var(--color-text-secondary)]">
              {t('board.sucheGlobalTreffer', { count: trefferGesamt })}
            </span>
          )}
          <div className="flex flex-col gap-2">
            <Label htmlFor="akte-sort">{t('board.sortierung')}</Label>
            <select
              id="akte-sort"
              className={SELECT_MD}
              value={sortierung}
              onChange={(e) => setSortierung(e.target.value as BoardSortierung)}
            >
              <option value="nachname">{t('board.sortNachname')}</option>
              <option value="rueckstand">{t('board.sortRueckstand')}</option>
            </select>
          </div>
          {istAdmin && (
            <div className="flex flex-col gap-2">
              <Label htmlFor="akte-zustand">{t('board.zustandFilter')}</Label>
              <select
                id="akte-zustand"
                className={SELECT_MD}
                value={zustand}
                onChange={(e) => setZustand(e.target.value as ZustandFilter)}
              >
                {(['aktiv', 'ruhend', 'alle'] as const).map((z) => (
                  <option key={z} value={z}>
                    {t(`board.zustand.${z}`)}
                  </option>
                ))}
              </select>
            </div>
          )}
        </div>

        {loading ? (
          <LoadingPulse type="list" lines={6} />
        ) : spalten.length === 0 ? (
          <EmptyState icon="🗂️" title={t('board.leerTitel')} description={t('board.leerText')} />
        ) : (
          <div className="flex gap-4 overflow-x-auto pb-4">
            {spalten.map((sp) => (
              <BoardSpalte
                key={String(sp.klasse)}
                spalte={sp}
                suche={sucheSpalte[String(sp.klasse)] ?? ''}
                onSuche={(wert) => setSucheSpalte((alt) => ({ ...alt, [String(sp.klasse)]: wert }))}
              />
            ))}
          </div>
        )}
      </main>
    </div>
  )
}
