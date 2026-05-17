import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { EdvanceCard, EdvanceBadge, EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { createTier, listAllTiers, updateTier } from '@/lib/supabase/tiers'
import type { TierInput, TierPlan } from '@/types'

type FormState = {
  name: string
  price_euro: string
  features_text: string
  sort_order: string
}

const EMPTY: FormState = { name: '', price_euro: '', features_text: '', sort_order: '0' }

function toInput(f: FormState): TierInput | null {
  const price = Number(f.price_euro.replace(',', '.'))
  if (f.name.trim() === '' || Number.isNaN(price)) return null
  return {
    name: f.name.trim(),
    price_cents: Math.round(price * 100),
    features: f.features_text
      .split('\n')
      .map((l) => l.trim())
      .filter(Boolean),
    sort_order: Number(f.sort_order) || 0,
  }
}

export function TiersPage(): JSX.Element {
  const [tiers, setTiers] = useState<TierPlan[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [form, setForm] = useState<FormState>(EMPTY)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  const load = (): void => {
    setLoading(true)
    listAllTiers().then(({ data, error: err }) => {
      setTiers(data ?? [])
      setError(err)
      setLoading(false)
    })
  }
  useEffect(load, [])

  const edit = (t: TierPlan): void => {
    setEditingId(t.id)
    setForm({
      name: t.name,
      price_euro: String(t.price_cents / 100),
      features_text: t.features.join('\n'),
      sort_order: String(t.sort_order),
    })
  }

  const save = async (): Promise<void> => {
    const input = toInput(form)
    if (!input) {
      setError('Name und gültiger Preis erforderlich.')
      return
    }
    setBusy(true)
    setError(null)
    const res = editingId
      ? await updateTier(editingId, input)
      : await createTier(input)
    setBusy(false)
    if (res.error) {
      setError(res.error)
      return
    }
    setForm(EMPTY)
    setEditingId(null)
    load()
  }

  const toggleActive = async (t: TierPlan): Promise<void> => {
    const { error: err } = await updateTier(t.id, { active: !t.active })
    if (err) {
      setError(err)
      return
    }
    load()
  }

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Tarif-Verwaltung" sticky />
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
        <div>
          <Link
            to="/admin"
            className="mb-2 flex items-center gap-1 text-sm text-[var(--text-muted)]"
          >
            <ArrowLeft className="h-4 w-4" /> Admin
          </Link>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">Tarife</h1>
        </div>

        {error && <p className="text-sm text-[var(--destructive)]">{error}</p>}

        <EdvanceCard className="flex flex-col gap-4 p-6">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
            {editingId ? 'Tarif bearbeiten' : 'Neuer Tarif'}
          </p>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <div className="flex flex-col gap-2">
              <Label htmlFor="t-name">Name</Label>
              <Input
                id="t-name"
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
              />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="t-price">Preis (€/Monat)</Label>
              <Input
                id="t-price"
                value={form.price_euro}
                onChange={(e) => setForm({ ...form, price_euro: e.target.value })}
              />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="t-sort">Reihenfolge</Label>
              <Input
                id="t-sort"
                value={form.sort_order}
                onChange={(e) => setForm({ ...form, sort_order: e.target.value })}
              />
            </div>
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="t-feat">Features (eine pro Zeile)</Label>
            <textarea
              id="t-feat"
              className="min-h-[96px] rounded-xl border border-[var(--border)] bg-[var(--card)] px-3 py-2 text-sm text-[var(--text-primary)]"
              value={form.features_text}
              onChange={(e) => setForm({ ...form, features_text: e.target.value })}
            />
          </div>
          <div className="flex gap-2">
            <Button onClick={save} disabled={busy}>
              {busy ? 'Speichert…' : editingId ? 'Aktualisieren' : 'Tarif anlegen'}
            </Button>
            {editingId && (
              <Button
                variant="outline"
                onClick={() => {
                  setEditingId(null)
                  setForm(EMPTY)
                }}
              >
                Abbrechen
              </Button>
            )}
          </div>
        </EdvanceCard>

        {loading ? (
          <LoadingPulse type="list" lines={3} />
        ) : tiers.length === 0 ? (
          <EmptyState
            icon="💳"
            title="Keine Tarife"
            description="Lege den ersten Tarif über das Formular oben an."
          />
        ) : (
          <div className="flex flex-col gap-4">
            {tiers.map((t) => (
              <EdvanceCard key={t.id} className="flex flex-col gap-3 p-6">
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <span className="text-base font-semibold text-[var(--text-primary)]">
                    {t.name} · {(t.price_cents / 100).toLocaleString('de-DE')} €
                  </span>
                  <EdvanceBadge variant={t.active ? 'success' : 'muted'}>
                    {t.active ? 'Aktiv' : 'Inaktiv'}
                  </EdvanceBadge>
                </div>
                <ul className="flex flex-col gap-0.5 text-sm text-[var(--text-secondary)]">
                  {t.features.map((f) => (
                    <li key={f}>· {f}</li>
                  ))}
                </ul>
                <div className="flex gap-2">
                  <Button size="sm" variant="outline" onClick={() => edit(t)}>
                    Bearbeiten
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => toggleActive(t)}
                  >
                    {t.active ? 'Deaktivieren' : 'Aktivieren'}
                  </Button>
                </div>
              </EdvanceCard>
            ))}
          </div>
        )}
      </main>
    </div>
  )
}
