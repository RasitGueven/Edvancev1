import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Radio } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard, EmptyState } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { amSelbenBerlinerTag } from '@/lib/coachKennzahlen'
import { sessionStarten } from '@/lib/supabase/sessionCoach'
import { sessionsOffen } from '@/lib/supabase/sessionC2'
import type { CoachingSession, OffeneSession } from '@/types'

const zeit = (iso: string, lang: string, mitDatum = false): string =>
  new Intl.DateTimeFormat(lang, {
    timeZone: 'Europe/Berlin',
    ...(mitDatum ? { weekday: 'short', day: '2-digit', month: '2-digit' } : {}),
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(iso))

const liveRoute = (id: string): string => `/coach/session/${id}/live`

function HeuteKarte({ s, onFehler }: { s: CoachingSession; onFehler: (f: string) => void }): JSX.Element {
  const { t, i18n } = useTranslation('coach')
  const navigate = useNavigate()
  const [startet, setStartet] = useState(false)

  const starten = async (): Promise<void> => {
    setStartet(true)
    const res = await sessionStarten(s.id)
    setStartet(false)
    if (res.error !== null) {
      onFehler(t('live.startFehler'))
      return
    }
    navigate(liveRoute(s.id))
  }

  return (
    <EdvanceCard className="flex flex-wrap items-center gap-4 p-6">
      <div className="flex min-w-0 flex-1 flex-col gap-2">
        <span className="flex flex-wrap items-center gap-2">
          <b className="text-base font-semibold">{t('live.zeile', { zeit: zeit(s.scheduled_at, i18n.language), raum: s.room ?? '–' })}</b>
          <EdvanceBadge variant={s.status === 'active' ? 'success' : 'primary'}>{t(`live.status.${s.status}`)}</EdvanceBadge>
          {s.testlauf && <EdvanceBadge variant="warning">{t('live.testlauf')}</EdvanceBadge>}
        </span>
      </div>
      {s.status === 'upcoming' ? (
        <span className="flex flex-wrap items-center gap-2">
          <Link to={liveRoute(s.id)} className="inline-flex min-h-[44px] items-center px-2 text-sm font-semibold text-[var(--color-text-link)] hover:underline">
            {t('live.vorbereiten')}
          </Link>
          <Button loading={startet} onClick={() => void starten()}>
            {t('live.starten')}
          </Button>
        </span>
      ) : (
        <Button variant={s.status === 'active' ? 'default' : 'outline'} onClick={() => navigate(liveRoute(s.id))}>
          {t('live.oeffnen')}
        </Button>
      )}
    </EdvanceCard>
  )
}

/**
 * Coach-Startseite (C2): die Sessions von heute mit „Live-Sicht öffnen“ bzw. „Session starten“
 * (session_starten, offene-punkte-c1 Nr. 11) und die eigenen Sessions, die nach ihrem Ende nicht
 * abgeschlossen sind (offene-punkte-a2 Befund 16).
 */
export function SessionsLive({ sessions }: { sessions: CoachingSession[] }): JSX.Element {
  const { t, i18n } = useTranslation('coach')
  const [offen, setOffen] = useState<OffeneSession[]>([])
  const [fehler, setFehler] = useState<string | null>(null)
  const jetzt = new Date().toISOString()
  const heute = sessions.filter((s) => amSelbenBerlinerTag(s.scheduled_at, jetzt))

  useEffect(() => {
    let aktiv = true
    void sessionsOffen().then((res) => {
      if (aktiv) setOffen(res.data ?? [])
    })
    return () => {
      aktiv = false
    }
  }, [])

  return (
    <section className="mb-8 flex flex-col gap-4" aria-labelledby="coach-live">
      <h2 id="coach-live" className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('live.titel')}
      </h2>
      {fehler && <p className="text-sm text-[var(--color-error-exam)]">{fehler}</p>}
      {heute.length === 0 ? (
        <EmptyState icon="☀️" title={t('live.leerTitel')} description={t('live.leerText')} />
      ) : (
        heute.map((s) => <HeuteKarte key={s.id} s={s} onFehler={setFehler} />)
      )}
      {offen.length > 0 && (
        <EdvanceCard className="flex flex-col gap-2 p-6">
          <b className="text-base font-semibold">{t('live.offenTitel', { count: offen.length })}</b>
          <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{t('live.offenText')}</p>
          <ul className="flex flex-col">
            {offen.map((o) => (
              <li key={o.session_id} className="flex min-h-[44px] items-center gap-2 border-t border-[var(--color-border)]">
                <Radio className="h-4 w-4 text-[var(--color-gold-warning)]" aria-hidden />
                <span className="min-w-0 flex-1 text-sm">{t('live.zeile', { zeit: zeit(o.scheduled_at, i18n.language, true), raum: o.room ?? '–' })}</span>
                {o.testlauf && <EdvanceBadge variant="warning">{t('live.testlauf')}</EdvanceBadge>}
                <Link to={liveRoute(o.session_id)} className="inline-flex min-h-[44px] items-center text-sm font-semibold text-[var(--color-text-link)] hover:underline">
                  {t('live.abschliessen')}
                </Link>
              </li>
            ))}
          </ul>
        </EdvanceCard>
      )}
    </section>
  )
}
