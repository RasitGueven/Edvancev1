// S10: Admin-Verwaltung des Wochen-Zeitrasters.
//
// Reine CRUD-Seite: Slots anlegen, Liste (inkl. inaktiver) ansehen, aktiv/inaktiv
// schalten. Keine Zuweisungslogik hier — die liegt in slots.ts (slot_assign RPC)
// und wird vom Erstgespräch-Slot-Picker konsumiert.

import { useEffect, useMemo, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Info } from 'lucide-react'
import {
  AdminHeader,
  EdvanceCard,
  EdvanceBadge,
  EmptyState,
  LoadingPulse,
  ToastBanner,
} from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { SELECT_MD } from '@/lib/formStyles'
import { formatSlotTime } from '@/lib/slotGrid'
import { createSlot, listSlotsWithLoad, setSlotActive } from '@/lib/supabase/slots'
import type { SlotWithLoad, Weekday } from '@/types'

const WEEKDAYS: Weekday[] = [0, 1, 2, 3, 4, 5, 6]
const DEFAULT_CAPACITY = 5

export function SlotsManagePage(): JSX.Element {
  const { t } = useTranslation('slots')

  const [slots, setSlots] = useState<SlotWithLoad[]>([])
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState<string | null>(null)

  const [weekday, setWeekday] = useState<Weekday>(0)
  const [startTime, setStartTime] = useState('')
  const [room, setRoom] = useState('')
  const [capacity, setCapacity] = useState(DEFAULT_CAPACITY)
  const [formError, setFormError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)

  const [togglingId, setTogglingId] = useState<string | null>(null)
  const [toast, setToast] = useState<{ key: number; type: 'success' | 'error'; message: string } | null>(
    null,
  )

  const showToast = (type: 'success' | 'error', message: string): void =>
    setToast((prev) => ({ key: (prev?.key ?? 0) + 1, type, message }))

  const load = (): void => {
    setLoading(true)
    void listSlotsWithLoad().then(({ data, error }) => {
      if (error) {
        setLoadError(t('manage.error.load'))
        setLoading(false)
        return
      }
      setLoadError(null)
      setSlots(data ?? [])
      setLoading(false)
    })
  }

  useEffect(load, [])

  const grouped = useMemo(() => {
    const byWeekday = new Map<Weekday, SlotWithLoad[]>()
    for (const slot of slots) {
      const list = byWeekday.get(slot.weekday) ?? []
      list.push(slot)
      byWeekday.set(slot.weekday, list)
    }
    return [...byWeekday.entries()]
  }, [slots])

  const submit = async (): Promise<void> => {
    if (!room.trim()) {
      setFormError(t('manage.error.roomRequired'))
      return
    }
    if (!startTime) {
      setFormError(t('manage.error.timeRequired'))
      return
    }
    setFormError(null)
    setSaving(true)
    const { error } = await createSlot({
      weekday,
      start_time: startTime,
      room: room.trim(),
      capacity,
    })
    setSaving(false)
    if (error) {
      setFormError(error)
      return
    }
    setStartTime('')
    setRoom('')
    setCapacity(DEFAULT_CAPACITY)
    showToast('success', t('manage.toast.created'))
    load()
  }

  const toggle = async (slot: SlotWithLoad): Promise<void> => {
    setTogglingId(slot.id)
    const { error } = await setSlotActive(slot.id, !slot.active)
    setTogglingId(null)
    if (error) {
      showToast('error', error)
      return
    }
    showToast('success', slot.active ? t('manage.toast.deactivated') : t('manage.toast.activated'))
    load()
  }

  return (
    <div className="flex min-h-screen flex-col bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <EdvanceNavbar subtitle="Admin" />
      <main className="mx-auto flex w-full max-w-5xl flex-col gap-6 px-4 py-8 sm:px-6">
        <AdminHeader
          title={t('manage.title')}
          eyebrow={t('manage.eyebrow')}
          description={t('manage.description')}
        />

        <EdvanceCard className="flex items-start gap-3 border-[var(--color-gold-warning)] bg-[var(--color-gold-warning-light)] p-4">
          <Info className="mt-0.5 h-5 w-5 shrink-0 text-[var(--color-gold-warning)]" aria-hidden="true" />
          <p className="text-sm leading-relaxed text-[var(--color-gold-warning)]">
            {t('manage.rasterHint')}
          </p>
        </EdvanceCard>

        <EdvanceCard className="flex flex-col gap-4 p-6">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('manage.form.legend')}
          </p>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <div className="flex flex-col gap-2">
              <Label htmlFor="slot-weekday">{t('manage.form.weekday')}</Label>
              <select
                id="slot-weekday"
                className={SELECT_MD}
                value={weekday}
                onChange={(e) => setWeekday(Number(e.target.value) as Weekday)}
              >
                {WEEKDAYS.map((day) => (
                  <option key={day} value={day}>
                    {t(`weekday.${day}`)}
                  </option>
                ))}
              </select>
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="slot-start">{t('manage.form.startTime')}</Label>
              <Input
                id="slot-start"
                type="time"
                value={startTime}
                onChange={(e) => setStartTime(e.target.value)}
              />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="slot-room">{t('manage.form.room')}</Label>
              <Input
                id="slot-room"
                value={room}
                placeholder={t('manage.form.roomPlaceholder')}
                onChange={(e) => setRoom(e.target.value)}
              />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="slot-capacity">{t('manage.form.capacity')}</Label>
              <Input
                id="slot-capacity"
                type="number"
                min={1}
                max={5}
                value={capacity}
                onChange={(e) => setCapacity(Number(e.target.value))}
              />
            </div>
          </div>
          {formError && <p className="text-sm text-[var(--color-error-exam)]">{formError}</p>}
          <div>
            <Button onClick={submit} disabled={saving}>
              {saving ? t('manage.form.submitting') : t('manage.form.submit')}
            </Button>
          </div>
        </EdvanceCard>

        {loadError && <p className="text-sm text-[var(--color-error-exam)]">{loadError}</p>}

        {!loadError && (
          <>
            <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
              {t('manage.list.heading')}
            </p>

            {loading ? (
              <LoadingPulse type="list" lines={5} />
            ) : slots.length === 0 ? (
              <EmptyState
                icon="🗓️"
                title={t('manage.empty.title')}
                description={t('manage.empty.description')}
              />
            ) : (
              <div className="flex flex-col gap-6">
                {grouped.map(([day, daySlots]) => (
                  <div key={day} className="flex flex-col gap-3">
                    <p className="text-sm font-semibold text-[var(--color-text-secondary)]">
                      {t(`weekday.${day}`)}
                    </p>
                    <div className="flex flex-col gap-4">
                      {daySlots.map((slot) => (
                        <EdvanceCard
                          key={slot.id}
                          className="flex flex-wrap items-center justify-between gap-3 p-6"
                        >
                          <span className="text-base font-semibold text-[var(--color-text-primary)]">
                            {formatSlotTime(slot.start_time)} · {slot.room}
                          </span>
                          <div className="flex flex-wrap items-center gap-2">
                            <EdvanceBadge variant="primary">
                              {t('manage.list.load', { belegt: slot.belegt, capacity: slot.capacity })}
                            </EdvanceBadge>
                            {!slot.active && (
                              <EdvanceBadge variant="muted">{t('manage.list.inactive')}</EdvanceBadge>
                            )}
                            <Button
                              variant="outline"
                              size="sm"
                              disabled={togglingId === slot.id}
                              onClick={() => toggle(slot)}
                            >
                              {slot.active ? t('manage.list.deactivate') : t('manage.list.activate')}
                            </Button>
                          </div>
                        </EdvanceCard>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            )}
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
