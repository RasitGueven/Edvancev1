import { useEffect, useState } from 'react'

import { ladeKaErstgespraech, saveKaErstgespraech } from '@/lib/supabase/kaFolge'

import { kaAusForm, type IntakeFormState } from './formState'

/**
 * L5 Teil B: Anzahl und Themen der Mathearbeit im Erstgespräch laden und speichern. `verfuegbar` ist false, solange
 * die Migration fehlt oder nichts lesbar ist; dann bleiben die Felder ausgeblendet und es wird nichts geschrieben.
 */
export function useKaFolge(
  leadId: string | null,
  patch: (next: Partial<IntakeFormState>) => void,
): { verfuegbar: boolean; speichern: (id: string, form: IntakeFormState) => Promise<string | null> } {
  const [verfuegbar, setVerfuegbar] = useState(false)
  useEffect(() => {
    if (!leadId) return
    let aktiv = true
    void ladeKaErstgespraech(leadId).then((w) => {
      if (!aktiv) return
      setVerfuegbar(w !== null)
      if (w) patch({ ka_anzahl: w.anzahl, ka_themen: w.themaKeys })
    })
    return () => {
      aktiv = false
    }
    // patch ist je Render neu; geladen wird nur beim Wechsel des Leads.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [leadId])

  const speichern = async (id: string, form: IntakeFormState): Promise<string | null> => {
    if (!verfuegbar) return null
    const { error } = await saveKaErstgespraech(id, kaAusForm(form))
    return error
  }
  return { verfuegbar, speichern }
}
