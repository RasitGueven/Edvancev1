// Slot-Auswahl (S10) — die iPad-Ansicht fürs Elterngespräch.
//
// Ablauf am Empfangstisch: Lead wählen, bis zu drei Favoriten antippen,
// optional direkt fest zuweisen. Die Kapazitätsgrenze prüft ausschließlich
// die DB (slot_assign RPC); dieses Fenster zeigt die Auslastung nur an.

import { useEffect, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { AdminHeader, EdvanceCard, EdvanceBadge, EmptyState, LoadingPulse, ToastBanner } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { SELECT_MD } from '@/lib/formStyles'
import { listLeads } from '@/lib/supabase/leads'
import {
  assignSlot,
  getActiveAssignment,
  listSlotsWithLoad,
  listWishesForLead,
  releaseSlot,
  setWishesForLead,
} from '@/lib/supabase/slots'
import { fillLevel, formatSlotTime } from '@/lib/slotGrid'
import { SlotCalendarGrid } from '@/pages/admin/slots/SlotCalendarGrid'
import type { Lead, SlotAssignment, SlotWithLoad } from '@/types'

const MAX_WISHES = 3

export function SlotPickerPage(): JSX.Element {
  const { t } = useTranslation('slots')

  const [leads, setLeads] = useState<Lead[]>([])
  const [leadsError, setLeadsError] = useState<string | null>(null)
  const [leadId, setLeadId] = useState('')

  const [slots, setSlots] = useState<SlotWithLoad[]>([])
  const [slotsLoading, setSlotsLoading] = useState(true)
  const [slotsError, setSlotsError] = useState<string | null>(null)

  const [favouriteIds, setFavouriteIds] = useState<string[]>([])
  const [wishError, setWishError] = useState<string | null>(null)
  const [savingWishes, setSavingWishes] = useState(false)

  const [assignment, setAssignment] = useState<SlotAssignment | null>(null)
  const [assigningId, setAssigningId] = useState<string | null>(null)
  const [releasing, setReleasing] = useState(false)
  const [actionError, setActionError] = useState<string | null>(null)

  const [toast, setToast] = useState<{ key: number; type: 'success' | 'error'; message: string } | null>(null)

  const showToast = (type: 'success' | 'error', message: string): void =>
    setToast((prev) => ({ key: (prev?.key ?? 0) + 1, type, message }))

  const reloadSlots = (): void => {
    setSlotsLoading(true)
    void listSlotsWithLoad({ onlyActive: true }).then(({ data, error }) => {
      if (error) setSlotsError(error)
      setSlots(data ?? [])
      setSlotsLoading(false)
    })
  }

  useEffect(() => {
    void listLeads().then(({ data, error }) => {
      if (error) setLeadsError(error)
      setLeads(data ?? [])
    })
    reloadSlots()
  }, [])

  useEffect(() => {
    setFavouriteIds([])
    setAssignment(null)
    setWishError(null)
    setActionError(null)
    if (!leadId) return
    void listWishesForLead(leadId).then(({ data }) => {
      setFavouriteIds((data ?? []).sort((a, b) => a.rang - b.rang).map((w) => w.slot_id))
    })
    void getActiveAssignment(leadId).then(({ data }) => setAssignment(data ?? null))
  }, [leadId])

  const handleToggle = (slot: SlotWithLoad): void => {
    setWishError(null)
    setFavouriteIds((prev) => {
      if (prev.includes(slot.id)) return prev.filter((id) => id !== slot.id)
      if (prev.length >= MAX_WISHES) {
        setWishError(t('picker.error.maxWishes'))
        return prev
      }
      return [...prev, slot.id]
    })
  }

  async function handleSaveWishes(): Promise<void> {
    if (!leadId) return
    setSavingWishes(true)
    setActionError(null)
    const { error } = await setWishesForLead(leadId, favouriteIds)
    setSavingWishes(false)
    if (error) {
      setActionError(error)
      return
    }
    showToast('success', t('picker.toast.wishesSaved'))
  }

  async function handleAssign(slotId: string): Promise<void> {
    if (!leadId) return
    setAssigningId(slotId)
    setActionError(null)
    const { data, error } = await assignSlot(slotId, leadId)
    setAssigningId(null)
    if (error) {
      setActionError(error)
      return
    }
    showToast('success', t('picker.toast.assigned'))
    reloadSlots()
    if (data) void getActiveAssignment(leadId).then(({ data: a }) => setAssignment(a ?? null))
  }

  async function handleRelease(): Promise<void> {
    if (!assignment) return
    setReleasing(true)
    setActionError(null)
    const { error } = await releaseSlot(assignment.id)
    setReleasing(false)
    if (error) {
      setActionError(error)
      return
    }
    setAssignment(null)
    showToast('success', t('picker.toast.released'))
    reloadSlots()
  }

  const assignedSlot = assignment ? (slots.find((s) => s.id === assignment.slot_id) ?? null) : null

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <EdvanceNavbar subtitle={t('picker.title')} sticky />
      <main className="mx-auto flex max-w-5xl flex-col gap-6 px-4 py-8">
        <AdminHeader
          eyebrow={t('picker.eyebrow')}
          title={t('picker.title')}
          description={t('picker.description')}
        />

        <div className="flex flex-col gap-2">
          <Label htmlFor="picker-lead">{t('picker.leadLabel')}</Label>
          <select
            id="picker-lead"
            className={SELECT_MD}
            value={leadId}
            onChange={(e) => setLeadId(e.target.value)}
          >
            <option value="">{t('picker.leadPlaceholder')}</option>
            {leads.map((lead) => (
              <option key={lead.id} value={lead.id}>
                {lead.full_name}
              </option>
            ))}
          </select>
        </div>

        {leadsError && <p className="text-sm text-[var(--color-error-exam)]">{leadsError}</p>}

        {!leadId ? (
          <EmptyState
            icon="👤"
            title={t('picker.noLead.title')}
            description={t('picker.noLead.description')}
          />
        ) : slotsLoading ? (
          <LoadingPulse type="card" />
        ) : slotsError ? (
          <p className="text-sm text-[var(--color-error-exam)]">{slotsError}</p>
        ) : slots.length === 0 ? (
          <EmptyState
            icon="🗓️"
            title={t('picker.noSlots.title')}
            description={t('picker.noSlots.description')}
          />
        ) : (
          <>
            <div className="flex flex-wrap items-center gap-4 text-xs text-[var(--color-text-tertiary)]">
              <span className="font-semibold uppercase tracking-widest">
                {t('picker.legend.heading')}
              </span>
              <span className="flex items-center gap-2">
                <span className="h-3 w-3 rounded-full border border-[var(--color-primary)] bg-[var(--color-primary-light)]" />
                {t('picker.legend.free')}
              </span>
              <span className="flex items-center gap-2">
                <span className="h-3 w-3 rounded-full border-2 border-[var(--color-accent)] bg-[var(--color-gold-warning-light)]" />
                {t('picker.legend.almost')}
              </span>
              <span className="flex items-center gap-2">
                <span className="h-3 w-3 rounded-full border border-[var(--color-border)] bg-[var(--color-bg-subtle)]" />
                {t('picker.legend.full')}
              </span>
            </div>

            <SlotCalendarGrid slots={slots} favouriteIds={favouriteIds} onToggle={handleToggle} />

            <EdvanceCard className="flex flex-col gap-4 p-6">
              <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                {t('picker.wishes.heading')}
              </p>
              <p className="text-sm text-[var(--color-text-secondary)]">{t('picker.wishes.hint')}</p>

              {wishError && <p className="text-sm text-[var(--color-error-exam)]">{wishError}</p>}

              {favouriteIds.length === 0 ? (
                <p className="text-sm text-[var(--color-text-tertiary)]">{t('picker.wishes.empty')}</p>
              ) : (
                <div className="flex flex-col gap-3">
                  {favouriteIds.map((slotId, index) => {
                    const slot = slots.find((s) => s.id === slotId)
                    if (!slot) return null
                    return (
                      <div
                        key={slotId}
                        className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-[var(--color-border)] p-3"
                      >
                        <div className="flex items-center gap-3">
                          <EdvanceBadge variant="primary">
                            {t('picker.card.rank', { rang: index + 1 })}
                          </EdvanceBadge>
                          <span className="text-sm text-[var(--color-text-primary)]">
                            {t(`weekday.${slot.weekday}`)} {formatSlotTime(slot.start_time)} ·{' '}
                            {t('picker.card.room', { room: slot.room })}
                          </span>
                        </div>
                        <Button
                          size="sm"
                          disabled={assigningId === slotId || fillLevel(slot) === 'full'}
                          onClick={() => handleAssign(slotId)}
                        >
                          {assigningId === slotId
                            ? t('picker.wishes.assigning')
                            : t('picker.wishes.assign')}
                        </Button>
                      </div>
                    )
                  })}
                </div>
              )}

              {actionError && <p className="text-sm text-[var(--color-error-exam)]">{actionError}</p>}

              <div>
                <Button
                  disabled={savingWishes || favouriteIds.length === 0}
                  onClick={handleSaveWishes}
                >
                  {savingWishes ? t('picker.wishes.saving') : t('picker.wishes.save')}
                </Button>
              </div>
            </EdvanceCard>

            <EdvanceCard className="flex flex-col gap-3 p-6">
              <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                {t('picker.assignment.heading')}
              </p>
              {!assignment ? (
                <p className="text-sm text-[var(--color-text-tertiary)]">{t('picker.assignment.none')}</p>
              ) : (
                <div className="flex flex-wrap items-center justify-between gap-3">
                  {assignedSlot && (
                    <span className="text-sm font-semibold text-[var(--color-text-primary)]">
                      {t('picker.assignment.current', {
                        weekday: t(`weekday.${assignedSlot.weekday}`),
                        time: formatSlotTime(assignedSlot.start_time),
                        room: assignedSlot.room,
                      })}
                    </span>
                  )}
                  <Button variant="outline" disabled={releasing} onClick={handleRelease}>
                    {releasing ? t('picker.assignment.releasing') : t('picker.assignment.release')}
                  </Button>
                </div>
              )}
            </EdvanceCard>
          </>
        )}
      </main>

      {toast && (
        <ToastBanner
          key={toast.key}
          type={toast.type}
          message={toast.message}
          onClose={() => setToast(null)}
        />
      )}
    </div>
  )
}
