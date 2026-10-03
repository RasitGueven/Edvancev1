import { useCallback, useEffect, useState } from 'react'
import { abgleichBehandelt, vorbelegungBehandelt } from '@/lib/themen/vorbelegung'
import {
  behandeltAnlegen,
  behandeltEntfernen,
  listLeadThemen,
  listSchulPlan,
  listThemen,
  setAktuellesThema,
} from '@/lib/supabase/themen'
import type { LeadThema, SchulPlanZeile, Thema } from '@/types'

type Args = {
  leadId: string | null
  /** fach im Katalog ("mathematik"); null = noch kein Fach gewaehlt. */
  fach: string | null
  schuleId: string | null
  klasse: number | null
}

export type ThemenAuswahl = {
  katalog: Thema[] | null
  plan: SchulPlanZeile[]
  leadThemen: LeadThema[]
  loading: boolean
  busy: boolean
  ladeFehler: string | null
  speicherFehler: string | null
  aktuell: string | null
  waehleAktuell: (themaKey: string) => Promise<void>
  toggleBehandelt: (themaKey: string) => Promise<void>
}

/**
 * Daten und Schreibwege der Themenauswahl im Erstgespraech. Geschrieben wird
 * sofort in lead_themen, nicht ueber den Lead-Payload: das Thema haengt am
 * angelegten Lead, und Schritt 2 ist erst mit Lead erreichbar.
 */
export function useThemenAuswahl({ leadId, fach, schuleId, klasse }: Args): ThemenAuswahl {
  const [katalog, setKatalog] = useState<Thema[] | null>(null)
  const [plan, setPlan] = useState<SchulPlanZeile[]>([])
  const [leadThemen, setLeadThemen] = useState<LeadThema[]>([])
  const [loading, setLoading] = useState(false)
  const [busy, setBusy] = useState(false)
  const [ladeFehler, setLadeFehler] = useState<string | null>(null)
  const [speicherFehler, setSpeicherFehler] = useState<string | null>(null)

  useEffect(() => {
    if (fach === null) {
      setKatalog(null)
      return
    }
    let active = true
    setLoading(true)
    setLadeFehler(null)
    void Promise.all([
      listThemen(fach),
      schuleId ? listSchulPlan(schuleId, fach) : Promise.resolve({ data: [], error: null }),
      leadId ? listLeadThemen(leadId, fach) : Promise.resolve({ data: [], error: null }),
    ]).then(([k, p, l]) => {
      if (!active) return
      setLoading(false)
      const err = k.error ?? p.error ?? l.error
      if (err) setLadeFehler(err)
      setKatalog(k.data ?? [])
      setPlan(p.data ?? [])
      setLeadThemen(l.data ?? [])
    })
    return () => {
      active = false
    }
  }, [fach, schuleId, leadId])

  const neuLaden = useCallback(async (): Promise<LeadThema[]> => {
    if (!leadId || fach === null) return []
    const { data, error } = await listLeadThemen(leadId, fach)
    if (error) setSpeicherFehler(error)
    const rows = data ?? []
    setLeadThemen(rows)
    return rows
  }, [leadId, fach])

  const aktuell = leadThemen.find((t) => t.status === 'aktuell')?.thema_key ?? null

  const waehleAktuell = async (themaKey: string): Promise<void> => {
    if (!leadId || fach === null || busy || themaKey === aktuell) return
    setBusy(true)
    setSpeicherFehler(null)
    const { error } = await setAktuellesThema(leadId, fach, themaKey)
    if (error) {
      setSpeicherFehler(error)
      setBusy(false)
      return
    }
    // Vorbelegung aus dem Schulplan an das neue Thema anpassen.
    if (schuleId && plan.length > 0) {
      const vorhanden = await neuLaden()
      const { anlegen, entfernen } = abgleichBehandelt(
        vorhanden,
        vorbelegungBehandelt(plan, klasse, themaKey),
      )
      const a = await behandeltAnlegen(leadId, fach, anlegen, 'schulplan')
      const e = await behandeltEntfernen(leadId, entfernen)
      if (a.error ?? e.error) setSpeicherFehler(a.error ?? e.error)
    }
    await neuLaden()
    setBusy(false)
  }

  const toggleBehandelt = async (themaKey: string): Promise<void> => {
    if (!leadId || fach === null || busy || themaKey === aktuell) return
    setBusy(true)
    setSpeicherFehler(null)
    const istBehandelt = leadThemen.some(
      (t) => t.thema_key === themaKey && t.status === 'behandelt',
    )
    const { error } = istBehandelt
      ? await behandeltEntfernen(leadId, [themaKey])
      : await behandeltAnlegen(leadId, fach, [themaKey], 'gespraech')
    if (error) setSpeicherFehler(error)
    await neuLaden()
    setBusy(false)
  }

  return {
    katalog,
    plan,
    leadThemen,
    loading,
    busy,
    ladeFehler,
    speicherFehler,
    aktuell,
    waehleAktuell,
    toggleBehandelt,
  }
}
