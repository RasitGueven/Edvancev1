import { useEffect, useState } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Avatar } from '@/components/ui/avatar'
import { Badge } from '@/components/ui/badge'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { EmptyState, LoadingPulse } from '@/components/edvance'
import { DashboardTiles } from '@/components/edvance/DashboardTiles'
import { useAuth } from '@/hooks/useAuth'
import {
  getSessionStudents,
  listSessionsForCoach,
  setAttendance,
} from '@/lib/supabase/sessions'
import { listStudentsWithName } from '@/lib/supabase/students'
import { formatDateLongDe, getInitials } from '@/lib/utils'
import { CalendarDays, Users, Clock, ClipboardList, FlaskConical, Inbox } from 'lucide-react'
import type {
  AttendanceStatus,
  CoachingSession,
  SessionStatus,
} from '@/types'

const PLACEHOLDER_DASH = '–'
const SHADOW_CARD = '0 1px 6px 0 rgba(0,0,0,0.07)'
const SHADOW_ACTIVE = '0 2px 12px 0 rgba(15,110,86,0.10)'
const ICON_BG_PRIMARY = 'color-mix(in srgb, var(--primary) 12%, transparent)'
const ICON_BG_SUCCESS = 'color-mix(in srgb, var(--success) 12%, transparent)'
const ICON_BG_WARNING = 'color-mix(in srgb, var(--warning) 12%, transparent)'

const STATUS_BORDER_COLOR: Record<SessionStatus, string> = {
  active: 'border-l-success',
  done: 'border-l-border',
  upcoming: 'border-l-primary',
}
const STATUS_BG: Record<SessionStatus, string> = {
  active: 'bg-success/5',
  done: 'bg-card',
  upcoming: 'bg-card',
}

type StudentVM = {
  student_id: string
  name: string
  classLevel: number | null
  attendance: AttendanceStatus
}
type SessionVM = { session: CoachingSession; students: StudentVM[] }

function sessionTime(iso: string): string {
  return new Date(iso).toLocaleTimeString('de-DE', {
    hour: '2-digit',
    minute: '2-digit',
  })
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

function StatCard({
  label,
  value,
  icon,
  iconBackground,
}: {
  label: string
  value: string | number
  icon: JSX.Element
  iconBackground: string
}): JSX.Element {
  return (
    <Card style={{ boxShadow: SHADOW_CARD }}>
      <CardContent className="flex items-center gap-4 pt-6">
        <div
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl"
          style={{ backgroundColor: iconBackground }}
        >
          {icon}
        </div>
        <div>
          <p className="text-xs font-medium uppercase tracking-wide text-muted">{label}</p>
          <p className="mt-0.5 text-3xl font-bold text-foreground">{value}</p>
        </div>
      </CardContent>
    </Card>
  )
}

function SessionCard({
  vm,
  onAttendance,
}: {
  vm: SessionVM
  onAttendance: (studentId: string, a: AttendanceStatus) => void
}): JSX.Element {
  const { session, students } = vm
  return (
    <Card
      className={`border-l-4 ${STATUS_BORDER_COLOR[session.status]} ${STATUS_BG[session.status]}`}
      style={{ boxShadow: session.status === 'active' ? SHADOW_ACTIVE : SHADOW_CARD }}
    >
      <CardHeader className="pb-2">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <div className="flex items-center gap-3">
            <span className="text-xl font-bold text-foreground">
              {sessionTime(session.scheduled_at)} Uhr
            </span>
            <Badge variant={session.status} />
          </div>
          <div className="flex items-center gap-2 text-sm text-muted">
            <span>{session.room ?? PLACEHOLDER_DASH}</span>
            <span>·</span>
            <span>{students.length} Schüler</span>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        {students.length === 0 ? (
          <p className="mb-2 text-sm text-muted">Keine Teilnehmer eingetragen.</p>
        ) : (
          <div className="mb-5 flex flex-col gap-3">
            {students.map((s) => (
              <div key={s.student_id} className="flex items-center justify-between gap-2">
                <div className="flex items-center gap-2">
                  <Avatar initials={getInitials(s.name)} attendance={s.attendance} />
                  <div>
                    <p className="text-sm font-medium text-foreground leading-tight">
                      {s.name.split(' ')[0]}
                    </p>
                    <p className="text-xs text-muted leading-tight">
                      Kl. {s.classLevel ?? PLACEHOLDER_DASH}
                    </p>
                  </div>
                </div>
                <div className="flex gap-1.5">
                  <Button
                    size="sm"
                    variant={s.attendance === 'present' ? 'default' : 'outline'}
                    onClick={() => onAttendance(s.student_id, 'present')}
                  >
                    Da
                  </Button>
                  <Button
                    size="sm"
                    variant={s.attendance === 'absent' ? 'default' : 'outline'}
                    onClick={() => onAttendance(s.student_id, 'absent')}
                  >
                    Fehlt
                  </Button>
                </div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  )
}

export function CoachDashboard(): JSX.Element {
  const { user } = useAuth()
  const [vms, setVms] = useState<SessionVM[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

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
          { name: st.full_name ?? 'Unbenannt', classLevel: st.class_level },
        ]),
      )
      const built: SessionVM[] = []
      for (const session of sessions ?? []) {
        const { data: links } = await getSessionStudents(session.id)
        built.push({
          session,
          students: (links ?? []).map((l) => ({
            student_id: l.student_id,
            name: nameMap.get(l.student_id)?.name ?? 'Unbenannt',
            classLevel: nameMap.get(l.student_id)?.classLevel ?? null,
            attendance: l.attendance,
          })),
        })
      }
      setVms(built)
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

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Coach-Dashboard" sticky />
      <main className="mx-auto max-w-4xl px-4 py-8">
        <div className="mb-6">
          <h1 className="text-2xl font-bold text-foreground">Guten Tag 👋</h1>
          <p className="mt-0.5 text-sm text-muted">{formatDateLongDe()}</p>
        </div>

        <h2 className="mb-3 text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
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
                to: '/admin/leads',
                icon: <Inbox className="h-5 w-5" />,
                title: 'Leads',
                description: 'Interessent:innen erfassen und nachverfolgen',
              },
            ]}
          />
        </div>

        <div className="mb-8 grid grid-cols-1 gap-4 sm:grid-cols-3">
          <StatCard
            label="Sessions heute"
            value={vms.length}
            icon={<CalendarDays className="h-5 w-5 text-primary" />}
            iconBackground={ICON_BG_PRIMARY}
          />
          <StatCard
            label="Aktive Schüler"
            value={totalActiveStudents(vms)}
            icon={<Users className="h-5 w-5 text-success" />}
            iconBackground={ICON_BG_SUCCESS}
          />
          <StatCard
            label="Nächste Session"
            value={nextUpcomingTime(vms)}
            icon={<Clock className="h-5 w-5 text-warning" />}
            iconBackground={ICON_BG_WARNING}
          />
        </div>

        <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-muted">
          Deine Sessions
        </h2>
        {error && <p className="mb-3 text-sm text-[var(--destructive)]">{error}</p>}
        {loading ? (
          <LoadingPulse type="list" lines={3} />
        ) : vms.length === 0 ? (
          <EmptyState
            icon="📅"
            title="Keine Sessions"
            description="Es sind noch keine Sessions für dich angelegt."
          />
        ) : (
          <div className="flex flex-col gap-4">
            {vms.map((vm) => (
              <SessionCard
                key={vm.session.id}
                vm={vm}
                onAttendance={(sid, a) => onAttendance(vm.session.id, sid, a)}
              />
            ))}
          </div>
        )}
      </main>
    </div>
  )
}
