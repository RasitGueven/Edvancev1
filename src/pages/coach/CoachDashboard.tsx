import { useEffect, useState } from 'react'
import { Button } from '@/components/ui/button'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
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
import { CalendarDays, Users, Clock, ClipboardList, FlaskConical, Inbox, FileText } from 'lucide-react'
import {
  SessionCard,
  sessionTime,
  PLACEHOLDER_DASH,
  type SessionVM,
} from '@/pages/coach/SessionCard'
import type { AttendanceStatus, Intervention } from '@/types'

type RangeFilter = 'today' | 'week' | 'all'

const RANGE_LABEL: Record<RangeFilter, string> = {
  today: 'Heute',
  week: 'Diese Woche',
  all: 'Alle',
}

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

function nextUpcomingTime(vms: SessionVM[]): string {
  const next = vms
    .filter((v) => v.session.status === 'upcoming')
    .sort((a, b) => a.session.scheduled_at.localeCompare(b.session.scheduled_at))[0]
  return next ? `${sessionTime(next.session.scheduled_at)} Uhr` : PLACEHOLDER_DASH
}

function totalActiveStudents(vms: SessionVM[]): number {
  return vms
    .filter((v) => v.session.status === 'active')
    .reduce((sum, v) => sum + v.students.length, 0)
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
  const { user } = useAuth()
  const [vms, setVms] = useState<SessionVM[]>([])
  const [intervBySession, setIntervBySession] = useState<
    Record<string, Intervention[]>
  >({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [range, setRange] = useState<RangeFilter>('today')

  const now = berlinYMD(new Date().toISOString())
  const todayCount = vms.filter((v) =>
    inRange(v.session.scheduled_at, 'today', now),
  ).length
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
            name: st.full_name ?? 'Unbenannt',
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
            name: nameMap.get(l.student_id)?.name ?? 'Unbenannt',
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
    a: AttendanceStatus,
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
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Coach-Dashboard" sticky />
      <main className="mx-auto max-w-4xl px-4 py-8">
        <div className="mb-6">
          <h1 className="text-2xl font-bold text-foreground">Guten Tag 👋</h1>
          <p className="mt-0.5 text-sm text-muted">{formatDateLongDe()}</p>
        </div>

        <h2 className="mb-3 text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          Schnellzugriff
        </h2>
        <div className="mb-8">
          <DashboardTiles
            tiles={[
              {
                to: '/coach/intake',
                icon: <ClipboardList className="h-5 w-5" />,
                title: 'Erstgespräch-Protokoll',
                description: 'Strukturiertes Erstgespräch erfassen und finalisieren',
              },
              {
                to: '/screening?view=coach',
                icon: <FlaskConical className="h-5 w-5" />,
                title: 'Screening (Coach-Sicht)',
                description: 'Lernstand-Diagnose begleiten und bewerten',
              },
              {
                to: '/coach/screening-results',
                icon: <ClipboardList className="h-5 w-5" />,
                title: 'Screening-Ergebnisse',
                description: 'Abgeschlossene Lernstand-Diagnosen einsehen',
              },
              {
                to: '/coach/reports',
                icon: <FileText className="h-5 w-5" />,
                title: 'Elternreport',
                description: 'KI-gestützten Report erstellen und freigeben',
              },
              {
                to: '/admin/leads',
                icon: <Inbox className="h-5 w-5" />,
                title: 'Leads',
                description: 'Interessent:innen erfassen und nachverfolgen',
              },
            ]}
          />
        </div>

        <div className="mb-8 grid grid-cols-1 gap-4 sm:grid-cols-3">
          <DashStatCard
            label="Sessions heute"
            value={todayCount}
            icon={<CalendarDays className="h-5 w-5 text-primary" />}
            iconCls="bg-[color-mix(in_srgb,var(--color-primary)_12%,transparent)]"
          />
          <DashStatCard
            label="Aktive Schüler"
            value={totalActiveStudents(vms)}
            icon={<Users className="h-5 w-5 text-success" />}
            iconCls="bg-[color-mix(in_srgb,var(--color-success)_12%,transparent)]"
          />
          <DashStatCard
            label="Nächste Session"
            value={nextUpcomingTime(vms)}
            icon={<Clock className="h-5 w-5 text-warning" />}
            iconCls="bg-[color-mix(in_srgb,var(--color-gold-warning)_12%,transparent)]"
          />
        </div>

        <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
          <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            Deine Sessions · {RANGE_LABEL[range]}
          </h2>
          <div className="flex flex-wrap gap-2">
            {(['today', 'week', 'all'] as RangeFilter[]).map((r) => (
              <Button
                key={r}
                size="sm"
                variant={range === r ? 'default' : 'outline'}
                onClick={() => setRange(r)}
              >
                {RANGE_LABEL[r]}
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
            title="Keine Sessions"
            description={
              range === 'all'
                ? 'Es sind noch keine Sessions für dich angelegt.'
                : `Keine Sessions im Zeitraum „${RANGE_LABEL[range]}".`
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
      </main>
    </div>
  )
}
