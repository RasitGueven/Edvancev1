import { useEffect, useMemo, useState } from 'react'
import { Button } from '@/components/ui/button'
import { Modal } from '@/components/edvance/Modal'
import {
  ItemEditorForm,
  type FormState,
} from '@/components/edvance/screening/ItemEditorForm'
import { ItemEditorPreview } from '@/components/edvance/screening/ItemEditorPreview'
import {
  createScreeningItem,
  updateScreeningItem,
} from '@/lib/supabase/screeningItems'
import type { ScreeningItem, ScreeningItemInput } from '@/types'

function initialFromItem(item: ScreeningItem | null): FormState {
  if (item) {
    return {
      topic: item.topic,
      skill_code: item.skill_code,
      skill_label: item.skill_label,
      class_level: item.class_level,
      level: item.level,
      curriculum_seq:
        item.curriculum_seq == null ? '' : String(item.curriculum_seq),
      input_type: item.input_type,
      check_type: item.check_type,
      afb: item.afb ?? '',
      phase: item.phase ?? '',
      prompt: item.prompt,
      payloadStr: JSON.stringify(item.payload ?? null, null, 2),
      canonicalStr: JSON.stringify(item.canonical, null, 2),
      tolerance: item.tolerance == null ? '' : String(item.tolerance),
      typical: item.typical_errors.join('\n'),
      explanation: item.explanation ?? '',
    }
  }
  return {
    topic: '',
    skill_code: '',
    skill_label: '',
    class_level: 8,
    level: 1,
    curriculum_seq: '',
    input_type: 'MC',
    check_type: 'mc_index',
    afb: '',
    phase: '',
    prompt: '',
    payloadStr: '{}',
    canonicalStr: '{}',
    tolerance: '',
    typical: '',
    explanation: '',
  }
}

function validate(s: FormState): string | null {
  if (!s.prompt.trim()) return 'Frage darf nicht leer sein.'
  if (!s.skill_code.trim()) return 'skill_code fehlt.'
  if (!s.skill_label.trim()) return 'skill_label fehlt.'
  if (!s.topic.trim()) return 'topic fehlt.'
  if ((s.input_type === 'OPEN') !== (s.check_type === 'manual'))
    return 'OPEN ↔ manual: offene Items brauchen check_type=manual und umgekehrt.'
  if ((s.afb === '') !== (s.phase === ''))
    return 'AFB und Phase entweder beide gesetzt (v2) oder beide leer (Legacy).'
  return null
}

function buildInput(
  s: FormState,
  clusterId: string,
  payload: unknown,
  canonical: unknown,
): ScreeningItemInput {
  return {
    cluster_id: clusterId,
    class_level: s.class_level,
    topic: s.topic.trim(),
    skill_code: s.skill_code.trim(),
    skill_label: s.skill_label.trim(),
    level: s.level,
    curriculum_seq:
      s.curriculum_seq.trim() === '' ? null : Number(s.curriculum_seq),
    input_type: s.input_type,
    prompt: s.prompt.trim(),
    payload,
    canonical,
    check_type: s.check_type,
    tolerance: s.tolerance.trim() === '' ? null : Number(s.tolerance),
    typical_errors: s.typical
      .split('\n')
      .map((t) => t.trim())
      .filter(Boolean),
    explanation: s.explanation.trim() === '' ? null : s.explanation.trim(),
    afb: s.afb === '' ? null : s.afb,
    phase: s.phase === '' ? null : s.phase,
  }
}

export function ItemEditorModal({
  open,
  onClose,
  onSaved,
  item,
  clusterId,
}: {
  open: boolean
  onClose: () => void
  onSaved: () => void
  item: ScreeningItem | null
  clusterId: string | null
}): JSX.Element | null {
  const [state, setState] = useState<FormState>(() => initialFromItem(item))
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (open) {
      setState(initialFromItem(item))
      setError(null)
    }
  }, [open, item])

  const set = <K extends keyof FormState>(k: K, v: FormState[K]): void =>
    setState((s) => ({ ...s, [k]: v }))

  const parsedPayload = useMemo<unknown>(() => {
    try {
      return state.payloadStr.trim() === ''
        ? null
        : JSON.parse(state.payloadStr)
    } catch {
      return null
    }
  }, [state.payloadStr])

  const save = async (): Promise<void> => {
    const vErr = validate(state)
    if (vErr) {
      setError(vErr)
      return
    }
    let payload: unknown
    let canonical: unknown
    try {
      payload =
        state.payloadStr.trim() === '' ? null : JSON.parse(state.payloadStr)
      canonical = JSON.parse(state.canonicalStr)
    } catch {
      setError('payload oder canonical ist kein gültiges JSON.')
      return
    }
    const cid = item ? item.cluster_id : clusterId
    if (!cid) {
      setError('Cluster fehlt — bitte auf der Liste ein Cluster wählen.')
      return
    }
    setBusy(true)
    setError(null)
    const input = buildInput(state, cid, payload, canonical)
    const { error: err } = item
      ? await updateScreeningItem(item.id, input)
      : await createScreeningItem(input)
    setBusy(false)
    if (err) {
      setError(err)
      return
    }
    onSaved()
  }

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={item ? 'Item bearbeiten' : 'Neues Item'}
      description={
        item
          ? `${item.skill_label} · ${item.topic}`
          : 'AFB + Phase setzen, damit das Item im v2-Pool landet.'
      }
      size="xl"
      footer={
        <>
          {error && (
            <span className="mr-auto text-sm text-[var(--destructive)]">
              {error}
            </span>
          )}
          <Button variant="outline" onClick={onClose} disabled={busy}>
            Abbrechen
          </Button>
          <Button onClick={save} disabled={busy}>
            {busy ? 'Speichert…' : item ? 'Speichern' : 'Anlegen'}
          </Button>
        </>
      }
    >
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <ItemEditorForm state={state} set={set} />
        <ItemEditorPreview
          prompt={state.prompt}
          inputType={state.input_type}
          payload={parsedPayload}
          afb={state.afb === '' ? null : state.afb}
          phase={state.phase === '' ? null : state.phase}
        />
      </div>
    </Modal>
  )
}
