import { useEffect, useState, type JSX } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Avatar } from '@/components/ui/avatar'
import { Badge } from '@/components/ui/badge'
import { EdvanceCard, LoadingPulse, StreakPill } from '@/components/edvance'
import { getStudentProgress } from '@/lib/supabase/progress'
import { getInitials } from '@/lib/utils'
import type {
  AttendanceStatus,
  CoachingSession,
  Intervention,
  SessionStatus,
  StudentProgress,
} from '@/types'

export const PLACEHOLDER_DASH = '–'

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

export type StudentVM = {
  student_id: string
  name: string
  classLevel: number | null
  schoolName: string | null
  schoolType: string | null
  attendance: AttendanceStatus
}
export type SessionVM = { session: CoachingSession; students: StudentVM[] }

function StudentProfilePanel({ s }: { s: StudentVM }): JSX.Element {
  const [progress, setProgress] = useState<StudentProgress | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let cancelled = false
    void getStudentProgress(s.student_id).then(({ data }) => {
      if (cancelled) return
      setProgress(data)
      setLoading(false)
    })
    return () => {
      cancelled = true
    }
  }, [s.student_id])

  return (
    <EdvanceCard variant="subtle" className="mt-1 flex flex-col gap-2 p-4">
      <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        Kurzprofil
      </p>
      {loading ? (
        <LoadingPulse type="list" lines={2} />
      ) : (
        <div className="flex flex-wrap items-center gap-2 text-sm text-[var(--color-text-secondary)]">
          <span className="font-semibold">Level {progress?.level ?? 1}</span>
          <span>·</span>
          <span>{(progress?.xp_total ?? 0).toLocaleString('de-DE')} XP</span>
          <StreakPill
            variant="presence"
            count={progress?.presence_streak_weeks ?? 0}
            multiplier={progress?.presence_streak_multiplier ?? 1}
            className="ml-1"
          />
          <StreakPill
            variant="home"
            count={progress?.home_streak_sessions ?? 0}
          />
          <span className="ml-auto">
            Kl. {s.classLevel ?? PLACEHOLDER_DASH}
            {s.schoolType ? ` · ${s.schoolType}` : ''}
          </span>
          {s.schoolName && <span>{s.schoolName}</span>}
        </div>
      )}
    </EdvanceCard>
  )
}

export function sessionTime(iso: string): string {
  return new Date(iso).toLocaleTimeString('de-DE', {
    timeZone: 'Europe/Berlin',
    hour: '2-digit',
    minute: '2-digit',
  })
}

export function SessionCard({
  vm,
  onAttendance,
  interventions,
  onIntervene,
  onResolve,
}: {
  vm: SessionVM
  onAttendance: (studentId: string, a: AttendanceStatus) => void
  interventions: Intervention[]
  onIntervene: (studentId: string) => void
  onResolve: (interventionId: string) => void
}): JSX.Element {
  const { session, students } = vm
  const [openProfile, setOpenProfile] = useState<string | null>(null)
  const openFor = (studentId: string): Intervention | undefined =>
    interventions.find(
      (i) => i.student_id === studentId && i.resolved_at === null,
    )

  return (
    <Card
      className={`border-l-4 ${STATUS_BORDER_COLOR[session.status]} ${STATUS_BG[session.status]} ${session.status === 'active' ? 'shadow-active-session' : 'shadow-card'}`}
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
            {students.map((s) => {
              const open = openFor(s.student_id)
              const profileOpen = openProfile === s.student_id
              return (
                <div key={s.student_id} className="flex flex-col gap-2">
                <div className="flex flex-wrap items-center justify-between gap-2">
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
                  <div className="flex flex-wrap items-center gap-1.5">
                    <Button
                      size="sm"
                      variant={profileOpen ? 'default' : 'outline'}
                      onClick={() =>
                        setOpenProfile(profileOpen ? null : s.student_id)
                      }
                    >
                      Profil
                    </Button>
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
                    {open ? (
                      <>
                        <span className="text-xs font-semibold text-[var(--color-error-exam)]">
                          Eingriff seit {sessionTime(open.started_at)}
                        </span>
                        <Button
                          size="sm"
                          variant="default"
                          onClick={() => onResolve(open.id)}
                        >
                          Gelöst
                        </Button>
                      </>
                    ) : (
                      <Button
                        size="sm"
                        variant="destructive"
                        onClick={() => onIntervene(s.student_id)}
                      >
                        Eingegriffen
                      </Button>
                    )}
                  </div>
                </div>
                {profileOpen && <StudentProfilePanel s={s} />}
                </div>
              )
            })}
          </div>
        )}
      </CardContent>
    </Card>
  )
}
