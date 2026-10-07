import { useEffect, useState } from 'react'
import { Button } from '@/components/ui/button'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { DashboardTiles } from '@/components/edvance/DashboardTiles'
import { useAuth } from '@/hooks/useAuth'
import {
  getSessionStudents,
  listSessionsForCoach,
  setAttendance,
} from '@/lib/supabase/sessions'
import {
  listInterventionsForSession,
  resolveIntervention,
  startIntervention,
} from '@/lib/supabase/interventions'
import { listStudentsWithName } from '@/lib/supabase/students'
import { formatDateLongDe } from '@/lib/utils'
import { berlinYMD, isoWeek } from '@/lib/datetime'
import { CalendarDays, Users, Clock, ClipboardCheck, FlaskConical, FolderOpen } from 'lucide-react'
import { useLocation } from 'react-router-dom'
import { getDarfPruefen } from '@/lib/supabase/freigabe'
import { HINWEIS_KEIN_PRUEFRECHT } from '@/components/edvance/ProtectedRoute'
import { useTranslation } from 'react-i18next'
import { datum } from '@/lib/akte/format'
import { amSelbenBerlinerTag, naechsteSession } from '@/lib/coachKennzahlen'
import { zaehleAktiveAkten } from '@/lib/supabase/akte'
import {
  SessionCard,
  sessionTime,
  PLACEHOLDER_DASH,
  type SessionVM,
} from '@/pages/coach/SessionCard'
import type { Intervention, SessionAttendance } from '@/types'
import { SessionsLive } from '@/pages/coach/SessionsLive'

type RangeFilter = 'today' | 'week' | 'all'

function inRange(
  iso: string,
  filter: RangeFilter,
  now: { y: number; m: number; d: number },
): boolean {
  if (filter === 'all') return true
  const s = berlinYMD(iso)
  if (filter === 'today') return s.y === now.y && s.m === now.m && s.d === now.d
  const sw = isoWeek(s.y, s.m, s.d)
  const nw = isoWeek(now.y, now.m, now.d)
  return sw.year === nw.year && sw.week === nw.week
}


function DashStatCard({
  label,
  value,
  icon,
  iconCls,
}: {
  label: string
  value: string | number
  icon: JSX.Element
  iconCls: string
}): JSX.Element {
  return (
    <EdvanceCard className="flex items-center gap-4">
      <div
        className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-xl ${iconCls}`}
      >
        {icon}
      </div>
      <div>
        <p className="text-xs font-medium uppercase tracking-wide text-muted">{label}</p>
        <p className="mt-0.5 text-3xl font-bold text-foreground">{value}</p>
      </div>
    </EdvanceCard>
  )
}

export function CoachDashboard(): JSX.Element {
  const { t, i18n } = useTranslation('coach')
  const { t: tPruefen } = useTranslation('pruefen')
  const { user } = useAuth()
  const [vms, setVms] = useState<SessionVM[]>([])
  const [intervBySession, setIntervBySession] = useState<
    Record<string, Intervention[]>
  >({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [range, setRange] = useState<RangeFilter>('today')

  const [aktiveSchueler, setAktiveSchueler] = useState<number | null>(null)
  // Kachel "Aufgaben pruefen" nur mit Pruefrecht (Lena-Board); die DB entscheidet.
  const [darfPruefen, setDarfPruefen] = useState(false)
  const keinPruefrecht = (useLocation().state as { hinweis?: string } | null)?.hinweis === HINWEIS_KEIN_PRUEFRECHT
  useEffect(() => {
    void getDarfPruefen().then((res) => setDarfPruefen(res.data === true))
  }, [])

  // "Sessions heute" zaehlt nach Berliner Kalendertag (berlinYMD fuer jetzt
  // und fuer die Session) — war schon vor S2b so (Prod-Beleg im PR).
  const jetztIso = new Date().toISOString()
  const now = berlinYMD(jetztIso)
  const todayCount = vms.filter((v) =>
    inRange(v.session.scheduled_at, 'today', now),
  ).length
  const naechste = naechsteSession(vms.map((v) => v.session), Date.now())
  const naechsteAnzeige = !naechste
    ? PLACEHOLDER_DASH
    : amSelbenBerlinerTag(naechste.scheduled_at, jetztIso)
      ? t('dashboard.naechsteHeute', { zeit: sessionTime(naechste.scheduled_at) })
      : t('dashboard.naechsteAm', {
          datum: datum(naechste.scheduled_at, i18n.language),
          zeit: sessionTime(naechste.scheduled_at),
        })

  useEffect(() => {
    void zaehleAktiveAkten().then(({ data }) => setAktiveSchueler(data))
  }, [])
  const filteredVms = vms.filter((v) =>
    inRange(v.session.scheduled_at, range, now),
  )

  const load = (): void => {
    if (!user) return
    setLoading(true)
    void (async () => {
      const [{ data: sessions, error: sErr }, { data: students }] = await Promise.all([
        listSessionsForCoach(user.id),
        listStudentsWithName(),
      ])
      if (sErr) {
        setError(sErr)
        setLoading(false)
        return
      }
      const nameMap = new Map(
        (students ?? []).map((st) => [
          st.id,
          {
            name: st.full_name ?? t('dashboard.unbenannt'),
            classLevel: st.class_level,
            schoolName: st.school_name,
            schoolType: st.school_type,
          },
        ]),
      )
      const built: SessionVM[] = []
      const interv: Record<string, Intervention[]> = {}
      for (const session of sessions ?? []) {
        const [{ data: links }, { data: ivs }] = await Promise.all([
          getSessionStudents(session.id),
          listInterventionsForSession(session.id),
        ])
        built.push({
          session,
          students: (links ?? []).map((l) => ({
            student_id: l.student_id,
            name: nameMap.get(l.student_id)?.name ?? t('dashboard.unbenannt'),
            classLevel: nameMap.get(l.student_id)?.classLevel ?? null,
            schoolName: nameMap.get(l.student_id)?.schoolName ?? null,
            schoolType: nameMap.get(l.student_id)?.schoolType ?? null,
            attendance: l.attendance,
          })),
        })
        interv[session.id] = ivs ?? []
      }
      setVms(built)
      setIntervBySession(interv)
      setLoading(false)
    })()
  }

  useEffect(load, [user])

  const onAttendance = async (
    sessionId: string,
    studentId: string,
    a: SessionAttendance,
  ): Promise<void> => {
    const { error: err } = await setAttendance(sessionId, studentId, a)
    if (err) {
      setError(err)
      return
    }
    load()
  }

  const onIntervene = async (
    sessionId: string,
    studentId: string,
  ): Promise<void> => {
    if (!user) return
    const { error: err } = await startIntervention(sessionId, studentId, user.id)
    if (err) {
      setError(err)
      return
    }
    load()
  }

  const onResolve = async (interventionId: string): Promise<void> => {
    const { error: err } = await resolveIntervention(interventionId)
    if (err) {
      setError(err)
      return
    }
    load()
  }

  return (
    <>
      <div>
        <div className="mb-6">
          <PageHeader titel={t('dashboard.titel')} satz={formatDateLongDe()} />
        </div>

        {keinPruefrecht && (
          <EdvanceCard className="mb-6 text-sm text-[var(--color-text-secondary)]">
            {tPruefen('keinRecht')}
          </EdvanceCard>
        )}

        <h2 className="mb-3 text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('tiles.schnellzugriff')}
        </h2>
        <div className="mb-8">
          <DashboardTiles
            tiles={[
              ...(darfPruefen
                ? [{
                    to: '/coach/pruefen',
                    icon: <ClipboardCheck className="h-5 w-5" />,
                    title: t('tiles.pruefen.title'),
                    description: t('tiles.pruefen.description'),
                  }]
                : []),
              {
                to: '/admin/akten',
                icon: <FolderOpen className="h-5 w-5" />,
                title: t('tiles.schueler.title'),
                description: t('tiles.schueler.description'),
              },
              {
                to: '/screening?view=coach',
                icon: <FlaskConical className="h-5 w-5" />,
                title: t('tiles.screening.title'),
                description: t('tiles.screening.description'),
              },
            ]}
          />
        </div>

        {!loading && <SessionsLive sessions={vms.map((v) => v.session)} />}

        <div className="mb-8 grid grid-cols-1 gap-4 sm:grid-cols-3">
          <DashStatCard
            label={t('dashboard.sessionsHeute')}
            value={todayCount}
            icon={<CalendarDays className="h-5 w-5 text-primary" />}
            iconCls="bg-[color-mix(in_srgb,var(--color-primary)_12%,transparent)]"
          />
          <DashStatCard
            label={t('dashboard.aktiveSchueler')}
            value={aktiveSchueler ?? PLACEHOLDER_DASH}
            icon={<Users className="h-5 w-5 text-success" />}
            iconCls="bg-[color-mix(in_srgb,var(--color-success)_12%,transparent)]"
          />
          <DashStatCard
            label={t('dashboard.naechsteSession')}
            value={naechsteAnzeige}
            icon={<Clock className="h-5 w-5 text-warning" />}
            iconCls="bg-[color-mix(in_srgb,var(--color-gold-warning)_12%,transparent)]"
          />
        </div>

        <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
          <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('dashboard.deineSessions', { zeitraum: t(`dashboard.zeitraum.${range}`) })}
          </h2>
          <div className="flex flex-wrap gap-2">
            {(['today', 'week', 'all'] as RangeFilter[]).map((r) => (
              <Button
                key={r}
                size="sm"
                variant={range === r ? 'default' : 'outline'}
                onClick={() => setRange(r)}
              >
                {t(`dashboard.zeitraum.${r}`)}
              </Button>
            ))}
          </div>
        </div>
        {error && <p className="mb-3 text-sm text-[var(--color-error-exam)]">{error}</p>}
        {loading ? (
          <LoadingPulse type="list" lines={3} />
        ) : filteredVms.length === 0 ? (
          <EmptyState
            icon="📅"
            title={t('dashboard.keineSessions')}
            description={
              range === 'all'
                ? t('dashboard.keineSessionsAlle')
                : t('dashboard.keineSessionsZeitraum', { zeitraum: t(`dashboard.zeitraum.${range}`) })
            }
          />
        ) : (
          <div className="flex flex-col gap-4">
            {filteredVms.map((vm) => (
              <SessionCard
                key={vm.session.id}
                vm={vm}
                onAttendance={(sid, a) => onAttendance(vm.session.id, sid, a)}
                interventions={intervBySession[vm.session.id] ?? []}
                onIntervene={(sid) => onIntervene(vm.session.id, sid)}
                onResolve={onResolve}
              />
            ))}
          </div>
        )}
      </div>
    </>
  )
}
