// Die Entscheidungen aus Schritt 4 — und ihre Tasten (F / Z / L).
//
// Jede Entscheidung speichert zuerst den Entwurf (saveStep), dann den Status,
// dann weiter zum naechsten Item. Scheitert das Speichern oder der Status, bleibt
// die Strecke stehen und zeigt den Fehler — lieber stehen als still verlieren.

import { useCallback, useEffect, useRef, useState } from 'react'
import { beanstandeAufgabe } from '@/lib/supabase/freigabe'
import { setTaskStatus } from '@/lib/supabase/taskAuthoring'
import type { BeanstandungsKategorie, EditorSettableStatus, TaskStatus } from '@/types'
import type { WizardOutcome } from './WizardScreens'

type Args = {
  currentId: string | null
  status: TaskStatus | null
  isAdmin: boolean
  canWrite: boolean
  blocked: boolean
  /** Ist Schritt 4 gerade offen? Nur dann gelten F / Z / L. */
  active: boolean
  /** Bei offener Vorschau sieht man die Entscheidung nicht — keine Tasten. */
  previewOpen: boolean
  busy: boolean
  setBusy: (busy: boolean) => void
  saveStep: () => Promise<boolean>
  advanceItem: (outcome?: WizardOutcome) => void
}

export function useReleaseActions(a: Args): {
  error: string | null
  rejectOpen: boolean
  /** Schliesst ein offenes Zurueckweisen-Feld; true, wenn es offen war (Esc). */
  closeReject: () => boolean
  primary: () => void
  revoke: () => void
  toggleReject: () => void
  reject: (kategorie: BeanstandungsKategorie, notiz: string | null) => void
  later: () => void
} {
  const { currentId, saveStep, advanceItem, setBusy } = a
  const [error, setError] = useState<string | null>(null)
  const [rejectOpen, setRejectOpen] = useState(false)

  useEffect(() => {
    setError(null)
    setRejectOpen(false)
  }, [currentId])

  const run = useCallback(
    async (write: () => Promise<{ error: string | null }>, outcome: WizardOutcome) => {
      if (!currentId) return
      setError(null)
      if (!(await saveStep())) return
      setBusy(true)
      const res = await write()
      setBusy(false)
      if (res.error) {
        setError(res.error)
        return
      }
      advanceItem(outcome)
    },
    [currentId, saveStep, setBusy, advanceItem],
  )

  const setStatus = useCallback(
    (status: EditorSettableStatus, outcome: WizardOutcome) =>
      void run(() => setTaskStatus(currentId ?? '', status), outcome),
    [run, currentId],
  )

  const primary = useCallback(
    () => (a.isAdmin ? setStatus('ready', 'released') : setStatus('review', 'reviewed')),
    [a.isAdmin, setStatus],
  )
  const revoke = useCallback(() => setStatus('draft', 'revoked'), [setStatus])
  const reject = useCallback(
    (kategorie: BeanstandungsKategorie, notiz: string | null) =>
      void run(() => beanstandeAufgabe(currentId ?? '', kategorie, notiz), 'rejected'),
    [run, currentId],
  )
  const later = useCallback(() => {
    void (async () => {
      if (await saveStep()) advanceItem('skipped')
    })()
  }, [saveStep, advanceItem])
  const toggleReject = useCallback(() => setRejectOpen((o) => !o), [])
  const rejectOpenRef = useRef(rejectOpen)
  rejectOpenRef.current = rejectOpen
  const closeReject = useCallback((): boolean => {
    if (!rejectOpenRef.current) return false
    setRejectOpen(false)
    return true
  }, [])

  // Tasten nur in Schritt 4, nie beim Tippen. Refs statt Abhaengigkeiten:
  // ein Listener, immer der aktuelle Stand.
  const ctx = useRef({ ...a, rejectOpen, primary, toggleReject, later })
  ctx.current = { ...a, rejectOpen, primary, toggleReject, later }
  useEffect(() => {
    const onKey = (e: KeyboardEvent): void => {
      const c = ctx.current
      if (!c.active || c.previewOpen || c.busy || e.metaKey || e.ctrlKey || e.altKey) return
      const tag = (e.target as HTMLElement | null)?.tagName ?? ''
      if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return
      const key = e.key.toLowerCase()
      const done = c.status === 'ready' || (!c.isAdmin && c.status === 'review')
      // Bei offenem Zurueckweisen-Feld gilt nur Z (zu) — F/L wuerden die
      // begonnene Rueckweisung still verwerfen.
      if (key === 'z' && c.canWrite && (c.isAdmin || c.status !== 'ready')) c.toggleReject()
      else if (c.rejectOpen) return
      else if (key === 'f' && c.canWrite && !done && !c.blocked) c.primary()
      else if (key === 'l') c.later()
      else return
      e.preventDefault()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  return { error, rejectOpen, closeReject, primary, revoke, toggleReject, reject, later }
}
