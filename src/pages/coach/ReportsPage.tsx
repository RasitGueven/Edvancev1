import { useEffect, useState, type JSX } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { listStudentsWithName } from '@/lib/supabase/students'
import { generateParentReport } from '@/lib/supabase/generateParentReport'
import { createParentReport, publishReport } from '@/lib/supabase/parentReports'
import type { ParentReportDraft, StudentWithName } from '@/types'

const SELECT_CLASS =
  'h-11 rounded-xl border border-[var(--border)] bg-[var(--card)] px-3 text-sm'
const TEXTAREA_CLASS =
  'min-h-[90px] w-full resize-y rounded-xl border border-[var(--border)] bg-card p-3 text-sm leading-relaxed focus:border-[var(--primary)] focus:outline-none'

const FIELDS: { key: keyof ParentReportDraft; label: string }[] = [
  { key: 'lernfortschritt', label: 'Lernfortschritt' },
  { key: 'anwesenheit', label: 'Anwesenheit' },
  { key: 'eingriffe', label: 'Eingriffe' },
  { key: 'empfehlung', label: 'Empfehlung / nächste Schritte' },
  { key: 'coach_notiz', label: 'Persönliche Coach-Notiz' },
]

function isoDaysAgo(days: number): string {
  return new Date(Date.now() - days * 864e5).toISOString().slice(0, 10)
}

export function ReportsPage(): JSX.Element {
  const [students, setStudents] = useState<StudentWithName[]>([])
  const [studentId, setStudentId] = useState('')
  const [from, setFrom] = useState(isoDaysAgo(14))
  const [to, setTo] = useState(isoDaysAgo(0))
  const [context, setContext] = useState('')
  const [draft, setDraft] = useState<ParentReportDraft | null>(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [done, setDone] = useState<string | null>(null)

  useEffect(() => {
    void listStudentsWithName().then(({ data }) => setStudents(data ?? []))
  }, [])

  const generate = async (): Promise<void> => {
    if (!studentId) {
      setError('Bitte Schüler auswählen.')
      return
    }
    setBusy(true)
    setError(null)
    setDone(null)
    const { data, error: err } = await generateParentReport({
      student_id: studentId,
      period_start: from,
      period_end: to,
      coach_context: context.trim() || null,
    })
    setBusy(false)
    if (err) {
      setError(err)
      return
    }
    setDraft(data)
  }

  const setField = (k: keyof ParentReportDraft, v: string): void => {
    if (!draft) return
    setDraft({ ...draft, [k]: v })
  }

  const save = async (publish: boolean): Promise<void> => {
    if (!draft) return
    setBusy(true)
    setError(null)
    const { coach_notiz, ...summary } = draft
    const { data, error: err } = await createParentReport({
      student_id: studentId,
      period_start: from,
      period_end: to,
      summary,
      coach_note: coach_notiz,
    })
    if (err || !data) {
      setBusy(false)
      setError(err ?? 'Speichern fehlgeschlagen')
      return
    }
    if (publish) {
      const { error: pErr } = await publishReport(data.id)
      if (pErr) {
        setBusy(false)
        setError(pErr)
        return
      }
    }
    setBusy(false)
    setDraft(null)
    setDone(
      publish
        ? 'Report freigegeben — für die Eltern sichtbar.'
        : 'Als Entwurf gespeichert (für Eltern noch unsichtbar).',
    )
  }

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Elternreport" sticky />
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
        <div>
          <Link
            to="/coach"
            className="mb-2 flex items-center gap-1 text-sm text-[var(--text-muted)]"
          >
            <ArrowLeft className="h-4 w-4" /> Coach
          </Link>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            Elternreport (KI-gestützt)
          </h1>
        </div>

        {error && <p className="text-sm text-[var(--destructive)]">{error}</p>}
        {done && <p className="text-sm text-[var(--success)]">{done}</p>}

        <EdvanceCard className="flex flex-col gap-4 p-6">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div className="flex flex-col gap-2">
              <Label htmlFor="r-stud">Schüler *</Label>
              <select
                id="r-stud"
                className={SELECT_CLASS}
                value={studentId}
                onChange={(e) => setStudentId(e.target.value)}
              >
                <option value="">–</option>
                {students.map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.full_name ?? 'Unbenannt'}
                    {s.class_level ? ` · Kl. ${s.class_level}` : ''}
                  </option>
                ))}
              </select>
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="r-from">Zeitraum von</Label>
              <Input
                id="r-from"
                type="date"
                value={from}
                onChange={(e) => setFrom(e.target.value)}
              />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="r-to">Zeitraum bis</Label>
              <Input
                id="r-to"
                type="date"
                value={to}
                onChange={(e) => setTo(e.target.value)}
              />
            </div>
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="r-ctx">Kontext / Schwerpunkte (optional)</Label>
            <textarea
              id="r-ctx"
              className={TEXTAREA_CLASS}
              value={context}
              onChange={(e) => setContext(e.target.value)}
              placeholder="z. B. Klausurvorbereitung Mathe, Motivationsthema …"
            />
          </div>
          <div>
            <Button onClick={generate} disabled={busy}>
              {busy && !draft ? 'Generiert …' : 'Entwurf generieren'}
            </Button>
          </div>
        </EdvanceCard>

        {busy && !draft && <LoadingPulse type="card" />}

        {draft ? (
          <EdvanceCard className="flex flex-col gap-4 p-6">
            <p className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
              Entwurf — vor Freigabe prüfen und anpassen
            </p>
            {FIELDS.map((f) => (
              <div key={f.key} className="flex flex-col gap-2">
                <Label htmlFor={`f-${f.key}`}>{f.label}</Label>
                <textarea
                  id={`f-${f.key}`}
                  className={TEXTAREA_CLASS}
                  value={draft[f.key]}
                  onChange={(e) => setField(f.key, e.target.value)}
                />
              </div>
            ))}
            <div className="flex flex-wrap gap-2">
              <Button disabled={busy} onClick={() => save(true)}>
                {busy ? 'Speichert …' : 'Speichern & freigeben'}
              </Button>
              <Button
                variant="outline"
                disabled={busy}
                onClick={() => save(false)}
              >
                Nur als Entwurf speichern
              </Button>
            </div>
          </EdvanceCard>
        ) : (
          !busy &&
          !done && (
            <EmptyState
              icon="📝"
              title="Noch kein Entwurf"
              description="Wähle Schüler und Zeitraum und generiere den Entwurf."
            />
          )
        )}
      </main>
    </div>
  )
}
