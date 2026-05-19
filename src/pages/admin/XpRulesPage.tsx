import { useEffect, useState, type JSX } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { listXpRules, updateXpRule } from '@/lib/supabase/xpRules'
import type { XpRule } from '@/types'

const TYPE_LABEL: Record<string, string> = {
  exercise: 'Übung',
  exercise_group: 'Mini-Test',
  article: 'Artikel',
  video: 'Video',
  course: 'Kurs',
}

type Draft = { base_xp: string; difficulty_multiplier: string }

export function XpRulesPage(): JSX.Element {
  const [rules, setRules] = useState<XpRule[]>([])
  const [draft, setDraft] = useState<Record<string, Draft>>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [savingType, setSavingType] = useState<string | null>(null)
  const [savedType, setSavedType] = useState<string | null>(null)

  const load = (): void => {
    setLoading(true)
    void listXpRules().then(({ data, error: e }) => {
      const list = data ?? []
      setRules(list)
      const d: Record<string, Draft> = {}
      for (const r of list) {
        d[r.content_type] = {
          base_xp: String(r.base_xp),
          difficulty_multiplier: String(r.difficulty_multiplier),
        }
      }
      setDraft(d)
      setError(e)
      setLoading(false)
    })
  }

  useEffect(load, [])

  const save = async (ct: string): Promise<void> => {
    const d = draft[ct]
    const base = Number(d?.base_xp)
    const mult = Number(d?.difficulty_multiplier)
    if (!Number.isInteger(base) || !Number.isInteger(mult) || base < 0 || mult < 0) {
      setError('Basis-XP und Multiplikator müssen ganze Zahlen ≥ 0 sein.')
      return
    }
    setSavingType(ct)
    setError(null)
    setSavedType(null)
    const { error: e } = await updateXpRule(ct, base, mult)
    setSavingType(null)
    if (e) {
      setError(e)
      return
    }
    setSavedType(ct)
  }

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="XP-Gewichtung" sticky />
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
        <div>
          <Link
            to="/admin"
            className="mb-2 flex items-center gap-1 text-sm text-[var(--text-muted)]"
          >
            <ArrowLeft className="h-4 w-4" /> Admin
          </Link>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            XP-Gewichtung
          </h1>
          <p className="mt-1 text-sm leading-relaxed text-[var(--text-secondary)]">
            Vergebene XP pro abgeschlossener Aufgabe ={' '}
            <span className="font-semibold">Basis-XP</span> +{' '}
            <span className="font-semibold">Multiplikator</span> ×
            Schwierigkeit (1–5). 500 XP = 1 Level.
          </p>
        </div>

        {error && (
          <p className="text-sm text-[var(--destructive)]">{error}</p>
        )}

        {loading ? (
          <LoadingPulse type="card" />
        ) : rules.length === 0 ? (
          <EmptyState
            icon="⚡"
            title="Keine Regeln"
            description="Migration 026 noch nicht angewendet?"
          />
        ) : (
          <div className="flex flex-col gap-4">
            {rules.map((r) => {
              const d = draft[r.content_type] ?? {
                base_xp: '0',
                difficulty_multiplier: '0',
              }
              return (
                <EdvanceCard
                  key={r.content_type}
                  className="flex flex-col gap-4 p-6"
                >
                  <p className="text-base font-semibold text-[var(--text-primary)]">
                    {TYPE_LABEL[r.content_type] ?? r.content_type}
                  </p>
                  <div className="flex flex-wrap items-end gap-4">
                    <div className="flex flex-col gap-2">
                      <Label htmlFor={`b-${r.content_type}`}>Basis-XP</Label>
                      <Input
                        id={`b-${r.content_type}`}
                        type="number"
                        min={0}
                        className="w-32"
                        value={d.base_xp}
                        onChange={(e) =>
                          setDraft((p) => ({
                            ...p,
                            [r.content_type]: {
                              ...d,
                              base_xp: e.target.value,
                            },
                          }))
                        }
                      />
                    </div>
                    <div className="flex flex-col gap-2">
                      <Label htmlFor={`m-${r.content_type}`}>
                        Multiplikator
                      </Label>
                      <Input
                        id={`m-${r.content_type}`}
                        type="number"
                        min={0}
                        className="w-32"
                        value={d.difficulty_multiplier}
                        onChange={(e) =>
                          setDraft((p) => ({
                            ...p,
                            [r.content_type]: {
                              ...d,
                              difficulty_multiplier: e.target.value,
                            },
                          }))
                        }
                      />
                    </div>
                    <Button
                      disabled={savingType === r.content_type}
                      onClick={() => save(r.content_type)}
                    >
                      {savingType === r.content_type
                        ? 'Speichert …'
                        : 'Speichern'}
                    </Button>
                    {savedType === r.content_type && (
                      <span className="text-sm text-[var(--success)]">
                        Gespeichert
                      </span>
                    )}
                  </div>
                </EdvanceCard>
              )
            })}
          </div>
        )}
      </main>
    </div>
  )
}
