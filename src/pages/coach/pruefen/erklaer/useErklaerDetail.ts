// Laden und Schreiben fuer die Detailseite einer Kernidee: Detail, Lenas Entscheidung, Schritt speichern,
// Freigabe, Ruecknahme, Antwort auf eine Rueckfrage. Nach jedem Schreiben wird das Detail neu geladen
// (neue pruef_version). Fehler kommen als i18n-Schluessel zurueck.

import { useCallback, useEffect, useState } from 'react'
import { erklaerFehlerSchluessel } from '@/lib/pruefung/erklaerTexte'
import {
  erklaerFreigabeZuruecknehmen,
  erklaerFreigeben,
  erklaerPruefen,
  erklaerRueckfrageBeantworten,
  erklaerSchrittSpeichern,
  getErklaerDetail,
} from '@/lib/supabase/erklaerPruefung'
import type {
  ErklaerDetail,
  ErklaerEntscheidung,
  ErklaerFehler,
  ErklaerFehlt,
  ErklaerGrund,
  ErklaerResult,
  ErklaerSchritt,
} from '@/types/erklaerPruefung'

export type ErklaerAktionFehler = { schluessel: string; fehlt: ErklaerFehlt[] | null }

export function useErklaerDetail(kernideeId: string | undefined) {
  const [detail, setDetail] = useState<ErklaerDetail | null>(null)
  const [ladeFehler, setLadeFehler] = useState<ErklaerFehler | null>(null)
  const [arbeitet, setArbeitet] = useState(false)
  const [fehler, setFehler] = useState<ErklaerAktionFehler | null>(null)

  const laden = useCallback(async (): Promise<void> => {
    if (!kernideeId) return
    const r = await getErklaerDetail(kernideeId)
    setDetail(r.data)
    setLadeFehler(r.error)
  }, [kernideeId])

  useEffect(() => {
    setDetail(null)
    setFehler(null)
    void laden()
  }, [laden])

  /** Fuehrt eine Aktion aus, laedt neu und liefert true bei Erfolg. */
  const ausfuehren = useCallback(async <T,>(aktion: () => Promise<ErklaerResult<T>>): Promise<boolean> => {
    setArbeitet(true)
    setFehler(null)
    const r = await aktion()
    if (r.error) setFehler({ schluessel: erklaerFehlerSchluessel(r.error), fehlt: r.error.fehlt })
    await laden()
    setArbeitet(false)
    return !r.error
  }, [laden])

  const version = detail?.kernidee.pruef_version ?? 0
  const id = kernideeId ?? ''

  return {
    detail,
    ladeFehler,
    arbeitet,
    fehler,
    setFehler,
    pruefen: (entscheidung: ErklaerEntscheidung, gruende?: ErklaerGrund[], notiz?: string) =>
      ausfuehren(() => erklaerPruefen({ kernideeId: id, version, entscheidung, gruende, notiz })),
    freigeben: () => ausfuehren(() => erklaerFreigeben(id, version)),
    zuruecknehmen: (grund: string) => ausfuehren(() => erklaerFreigabeZuruecknehmen(id, grund, version)),
    antworten: (antwort: string) => ausfuehren(() => erklaerRueckfrageBeantworten(id, antwort)),
    /** Schritt speichern; liefert den i18n-Schluessel eines Fehlers oder null. */
    schrittSpeichern: async (s: ErklaerSchritt, inhalt: string, slugs: string[]): Promise<string | null> => {
      const r = await erklaerSchrittSpeichern({
        kernideeId: id, variante: s.variante, art: s.art, inhalt, bild: s.bild, fehlbildSlugs: slugs,
      })
      await laden()
      return r.error ? erklaerFehlerSchluessel(r.error) : null
    },
  }
}
