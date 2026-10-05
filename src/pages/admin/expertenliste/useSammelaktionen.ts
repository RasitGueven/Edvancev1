// Sammelaktionen der Expertenliste (Bauauftrag E 18): welcher Vorschau-Dialog offen ist, die Fertigkeitsauswahl
// fuer die ausgewaehlten Aufgaben (einmal geladen, wenn sie gebraucht wird) und die Ergebnis-Meldung
// „9 freigegeben, 3 ausgelassen.“ mit „Ausgelassene anzeigen“: Filter zuruecksetzen, genau diese Aufgaben waehlen.

import { useCallback, useEffect, useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { EMPTY_FILTERS, type FilterState } from '@/components/edvance/authoring/AuthoringFilters'
import { ausgelasseneAuswahl, fertigkeitWahl, type FertigkeitWahl } from '@/lib/authoring/auswahl'
import { getFertigkeitsgraph, type Fertigkeitsgraph } from '@/lib/supabase/pruefungAdmin'
import type { SammelAktion, SammelErgebnis, SkillThema } from '@/types'

export type ListenMeldung = { text: string; aktion?: { label: string; los: () => void } }

type Args = {
  auswahlIds: string[]
  skillVon: (id: string) => string | null
  themen: SkillThema[]
  setFiltersRoh: (f: FilterState) => void
  setAuswahl: (s: Set<string>) => void
  neuLaden: () => void
}

export function useSammelaktionen({ auswahlIds, skillVon, themen, setFiltersRoh, setAuswahl, neuLaden }: Args) {
  const { t } = useTranslation('pruefenAdmin')
  const [dialog, setDialog] = useState<SammelAktion | null>(null)
  const [graph, setGraph] = useState<Fertigkeitsgraph | null>(null)
  const [meldung, setMeldung] = useState<ListenMeldung | null>(null)

  useEffect(() => {
    if (dialog !== 'fertigkeit' || graph) return
    void getFertigkeitsgraph().then((r) => r.data && setGraph(r.data))
  }, [dialog, graph])

  useEffect(() => {
    if (!meldung) return
    const timer = setTimeout(() => setMeldung(null), meldung.aktion ? 10000 : 5000)
    return () => clearTimeout(timer)
  }, [meldung])

  const fertigkeiten: FertigkeitWahl[] = useMemo(
    () => (dialog === 'fertigkeit' && graph
      ? fertigkeitWahl(auswahlIds.map(skillVon), themen, graph.skills, graph.kanten, t('pruefen:einordnung.voraussetzungen'))
      : []),
    [dialog, graph, auswahlIds, skillVon, themen, t],
  )

  const fertig = useCallback((ergebnis: SammelErgebnis, aktion: SammelAktion): void => {
    setDialog(null)
    const ausgelassen = ausgelasseneAuswahl(ergebnis)
    setMeldung({
      text: t(`sammel.ergebnis.${aktion}`, { count: ergebnis.betrifft.length, ausgelassen: ausgelassen.size }),
      aktion: ausgelassen.size > 0
        ? {
            label: t('sammel.ausgelasseneAnzeigen'),
            los: () => {
              // Alle Quellen, damit keine ausgelassene Aufgabe hinter dem Standardfilter verschwindet.
              setFiltersRoh({ ...EMPTY_FILTERS, source: 'all' })
              setAuswahl(ausgelassen)
              setMeldung({ text: t('sammel.ausgelasseneGewaehlt', { count: ausgelassen.size }) })
            },
          }
        : undefined,
    })
    setAuswahl(new Set())
    neuLaden()
  }, [t, setFiltersRoh, setAuswahl, neuLaden])

  return { dialog, setDialog, fertigkeiten, meldung, setMeldung, fertig }
}
