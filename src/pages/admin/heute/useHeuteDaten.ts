import { useCallback, useEffect, useState } from 'react'
import { getAdminStats, type AdminStats } from '@/lib/supabase/adminStats'
import { listBoardSchueler } from '@/lib/supabase/akte'
import { berlinToday } from '@/lib/datetime'
import { listAufgabenFuerAdmin, type AufgabeFuerAdmin } from '@/lib/supabase/heute'
import { listReportSessionsByLead } from '@/lib/supabase/leadLsa'
import { listLeads } from '@/lib/supabase/leads'
import { listTodaysLsaSessions } from '@/lib/supabase/lsaReport'
import { listActivePlaetzeByLead, type LeadPlatz } from '@/lib/supabase/platz'
import { listSkillThemen } from '@/lib/supabase/themen'
import { listVertraege } from '@/lib/supabase/vertraege'
import { listVertraegeAktuell } from '@/lib/supabase/vertraegeMenue'
import { ladeTag } from '@/lib/supabase/slotplan'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import type { SlotsTag } from '@/types/slotplan'
import type {
  BoardSchueler,
  Lead,
  LsaSessionListItem,
  SkillThema,
  VertragAktuell,
  VertragMitLead,
} from '@/types'

export type HeuteDaten = {
  stats: AdminStats | null
  leads: Lead[]
  platzByLead: Record<string, LeadPlatz>
  reportByLead: Record<string, string>
  vertraege: VertragAktuell[]
  antraege: VertragMitLead[]
  schueler: BoardSchueler[]
  aufgaben: AufgabeFuerAdmin[]
  skillThemen: SkillThema[]
  /** Slots SL3: Raum-Termine, Sessions ohne Raum und Absagen des Tages aus slots_tag. */
  tag: SlotsTag | null
  /** i18n-Schlüssel im Namespace slots, wenn slots_tag scheitert (nie Rohtext). */
  tagFehler: string | null
  lsaHeute: LsaSessionListItem[]
}

const LEER: HeuteDaten = {
  stats: null,
  leads: [],
  platzByLead: {},
  reportByLead: {},
  vertraege: [],
  antraege: [],
  schueler: [],
  aufgaben: [],
  skillThemen: [],
  tag: null,
  tagFehler: null,
  lsaHeute: [],
}

/**
 * Lädt alles für „Heute“ parallel über die bestehenden Lesefunktionen. Ein
 * Fehler in einer Quelle leert nur deren Liste; die erste Meldung steht in
 * error, damit eine leere Liste nicht stillschweigend „nichts offen“ heißt.
 */
export function useHeuteDaten(): { daten: HeuteDaten; loading: boolean; error: string | null; neuLaden: () => void } {
  const [daten, setDaten] = useState<HeuteDaten>(LEER)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const laden = useCallback((): (() => void) => {
    let aktiv = true
    void (async () => {
      const [stats, leads, platz, vertraege, antraege, schueler, aufgaben, skillThemen, tag, lsaHeute] =
        await Promise.all([
          getAdminStats(),
          listLeads(),
          listActivePlaetzeByLead(),
          listVertraegeAktuell(),
          listVertraege(),
          listBoardSchueler(),
          listAufgabenFuerAdmin(),
          listSkillThemen(),
          ladeTag(berlinToday()),
          listTodaysLsaSessions(),
        ])
      const fertig = (leads.data ?? []).filter((l) => l.status === 'lsa_fertig').map((l) => l.id)
      const reports = await listReportSessionsByLead(fertig)
      if (!aktiv) return
      setDaten({
        stats: stats.data,
        leads: leads.data ?? [],
        platzByLead: platz.data ?? {},
        reportByLead: reports.data ?? {},
        vertraege: vertraege.data ?? [],
        antraege: antraege.data ?? [],
        schueler: schueler.data ?? [],
        aufgaben: aufgaben.data ?? [],
        skillThemen: skillThemen.data ?? [],
        tag: tag.data,
        tagFehler: tag.error !== null ? slotsFehlerSchluessel(tag) : null,
        lsaHeute: lsaHeute.data ?? [],
      })
      setError(
        stats.error ?? leads.error ?? platz.error ?? vertraege.error ?? antraege.error ?? schueler.error ??
          aufgaben.error ?? skillThemen.error ?? lsaHeute.error ?? reports.error,
      )
      setLoading(false)
    })()
    return () => {
      aktiv = false
    }
  }, [])

  useEffect(() => laden(), [laden])
  const neuLaden = useCallback((): void => {
    laden()
  }, [laden])

  return { daten, loading, error, neuLaden }
}
