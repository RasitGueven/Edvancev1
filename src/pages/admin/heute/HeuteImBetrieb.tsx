import { Link } from 'react-router-dom'
import { ArrowRight } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard, EmptyState } from '@/components/edvance'
import { PlatzPunkte } from '@/components/edvance/PlatzPunkte'
import type { SessionHeute } from '@/lib/supabase/heute'
import type { LsaSessionListItem } from '@/types'
import { berlinZeit } from './ListenVertrieb'

type Eintrag = { key: string; zeit: string; sortier: number; titel: string; unterzeile: string; rechts: JSX.Element }

/**
 * Was heute im Haus passiert: Sessions aus coaching_sessions (Berliner Tag)
 * und die Lernstandsanalysen von heute. Absagen kommen mit dem Slots-Feature.
 */
export function HeuteImBetrieb({ sessions, lsa }: { sessions: SessionHeute[]; lsa: LsaSessionListItem[] }): JSX.Element {
  const { t, i18n } = useTranslation('admin')
  const lang = i18n.language
  const kinder = sessions.reduce((summe, s) => summe + s.belegt, 0)

  const eintraege: Eintrag[] = [
    ...sessions.map((s) => ({
      key: `s-${s.id}`,
      zeit: berlinZeit(s.scheduled_at, lang, false),
      sortier: new Date(s.scheduled_at).getTime(),
      titel: s.room ? t('heute.betrieb.raum', { raum: s.room }) : t('heute.betrieb.session'),
      unterzeile: s.coach_name ?? t('heute.betrieb.ohneCoach'),
      rechts: <PlatzPunkte raeume={[s.belegt]} mitZahl />,
    })),
    ...lsa.map((l) => {
      const zeitpunkt = l.started_at ?? l.completed_at
      return {
        key: `l-${l.session_id}`,
        zeit: zeitpunkt ? berlinZeit(zeitpunkt, lang, false) : '—',
        sortier: zeitpunkt ? new Date(zeitpunkt).getTime() : Number.MAX_SAFE_INTEGER,
        titel: l.first_name ?? '—',
        unterzeile: t('heute.betrieb.lsaMeta', { klasse: l.grade, fach: l.subject }),
        rechts: <EdvanceBadge variant="primary">{t('heute.betrieb.lsa')}</EdvanceBadge>,
      }
    }),
  ].sort((a, b) => a.sortier - b.sortier)

  return (
    <EdvanceCard className="flex flex-col gap-2 p-4">
      <h3 className="font-serif text-2xl font-semibold">
        {[t('heute.betrieb.sessions', { count: sessions.length }), t('heute.betrieb.kinder', { count: kinder })].join(' · ')}
      </h3>
      <p className="text-xs text-[var(--color-text-tertiary)]">{t('heute.betrieb.lsaAnzahl', { count: lsa.length })}</p>

      {eintraege.length === 0 ? (
        <EmptyState icon="🌤️" title={t('heute.betrieb.leerTitel')} description={t('heute.betrieb.leerText')} />
      ) : (
        <ol className="flex flex-col">
          {eintraege.map((e) => (
            <li
              key={e.key}
              className="grid min-h-[56px] grid-cols-[3.25rem_minmax(0,1fr)_auto] items-center gap-2 border-t border-[var(--color-border)] py-2"
            >
              <time className="text-sm font-semibold tabular-nums">{e.zeit}</time>
              <div className="flex min-w-0 flex-col">
                <span className="truncate text-sm font-semibold">{e.titel}</span>
                <span className="truncate text-xs text-[var(--color-text-tertiary)]">{e.unterzeile}</span>
              </div>
              {e.rechts}
            </li>
          ))}
        </ol>
      )}

      <div className="flex justify-end border-t border-[var(--color-border)] pt-1">
        <Link
          to="/admin/schedule"
          className="inline-flex min-h-[44px] items-center gap-2 text-sm font-semibold text-[var(--color-text-link)] hover:underline"
        >
          {t('heute.betrieb.fuss')}
          <ArrowRight aria-hidden="true" className="h-4 w-4" />
        </Link>
      </div>
    </EdvanceCard>
  )
}
