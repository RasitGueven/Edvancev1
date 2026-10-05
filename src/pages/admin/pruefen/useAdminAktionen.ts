// Entscheidungen der Admin-Pruefansicht (Bauauftrag C 9 bis C 13). Vor jeder Entscheidung wird die Pruefkarte
// gespeichert (pruef_speichern); scheitert das, bleibt die Aufgabe offen. Rueckfragen laufen ueber
// pruef_rueckfrage_klaeren, alles andere ueber die Admin-Funktionen. Danach oeffnet sich die naechste Aufgabe der
// Reihe (am Ende die Abschlussseite); eine Meldung bestaetigt 5 s lang mit „Oeffnen“. Kein Rueckgaengig.

import { useCallback, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { adminFehler, uebersetze } from '@/lib/pruefung/adminTexte'
import type { LeistenAktion } from '@/lib/pruefung/leiste'
import { naechste, speichereReihe, vermerke, type Reihe, type ReiheArt } from '@/lib/pruefung/reihe'
import { pruefRueckfrageKlaeren } from '@/lib/supabase/pruefung'
import {
  pruefAdminFreigeben, pruefAdminZurueckweisen, pruefAnLena, pruefFreigabeZuruecknehmen,
} from '@/lib/supabase/pruefungAdmin'
import type { PruefFehlerInfo, PruefResult } from '@/types'
import type { LeistenEingabe } from './AdminLeiste'
import type { AdminPruefung } from './useAdminPruefung'

export type Meldung = { text: string; oeffnen?: () => void }

type Args = {
  taskId: string | undefined
  p: AdminPruefung
  reihe: Reihe | null
  setReihe: (r: Reihe | null) => void
  /** Antwort an Lena bei einer Rueckfrage (Feld ueber der Leiste). */
  antwort: string
  /** Nach einer Entscheidung: Felder ueber der Leiste schliessen. */
  aufraeumen: () => void
}

const ART: Partial<Record<LeistenAktion, ReiheArt>> = {
  freigeben: 'freigegeben', anLena: 'anLena', aufOffen: 'anLena', zurueckweisen: 'zurueckgewiesen',
}

export function useAdminAktionen({ taskId, p, reihe, setReihe, antwort, aufraeumen }: Args) {
  const { t } = useTranslation('pruefenAdmin')
  const navigate = useNavigate()
  const [arbeitet, setArbeitet] = useState(false)
  const [fehler, setFehler] = useState<string | null>(null)
  const [meldung, setMeldung] = useState<Meldung | null>(null)

  useEffect(() => setFehler(null), [taskId])
  useEffect(() => {
    if (!meldung) return
    const timer = setTimeout(() => setMeldung(null), 5000)
    return () => clearTimeout(timer)
  }, [meldung])

  const zeigeFehler = useCallback((err: PruefFehlerInfo | null): void => {
    const u = adminFehler(err)
    setFehler(u ? uebersetze(t, u) : t('pruefen:fehlermeldung.allgemein'))
  }, [t])

  /** Zur naechsten Aufgabe der Reihe bzw. zur Abschlussseite; ohne Reihe bleibt die Aufgabe offen. */
  const weiter = useCallback((id: string, art: ReiheArt | null): void => {
    if (!reihe) {
      p.neuLaden()
      return
    }
    const neu = art ? vermerke(reihe, id, art) : reihe
    speichereReihe(neu)
    setReihe(neu)
    const n = naechste(neu, id)
    navigate(n ? `/admin/pruefen/${n}` : '/admin/pruefen/ende')
  }, [reihe, setReihe, navigate, p])

  const entscheide = useCallback(async (aktion: LeistenAktion, eingabe: LeistenEingabe = {}): Promise<void> => {
    const a = p.s.aufgabe
    if (!taskId || !a || arbeitet) return
    const rueckfrage = a.aufgabe.status === 'rueckfrage'
    setArbeitet(true)
    setFehler(null)
    // Ungespeicherte Aenderungen der Pruefkarte zuerst (wie bei Lena vor jeder Entscheidung).
    if (!(await p.s.sichern())) {
      setArbeitet(false)
      return
    }
    let res: PruefResult<unknown>
    if (aktion === 'freigeben') {
      res = rueckfrage ? await pruefRueckfrageKlaeren(taskId, 'freigeben', antwort) : await pruefAdminFreigeben(taskId)
    } else if (aktion === 'anLena') {
      res = rueckfrage
        ? await pruefRueckfrageKlaeren(taskId, 'an_lena', eingabe.nachricht ?? antwort)
        : await pruefAnLena(taskId, eingabe.nachricht)
    } else if (aktion === 'aufOffen') {
      res = await pruefAnLena(taskId, null)
    } else if (aktion === 'zurueckweisen') {
      const gruende = eingabe.gruende ?? []
      res = rueckfrage
        ? await pruefRueckfrageKlaeren(taskId, 'zurueckweisen', eingabe.notiz?.trim() || antwort, gruende)
        : await pruefAdminZurueckweisen(taskId, gruende, eingabe.notiz)
    } else if (aktion === 'freigabeZurueck') {
      res = await pruefFreigabeZuruecknehmen(taskId)
    } else {
      setArbeitet(false)
      return
    }
    setArbeitet(false)
    if (res.error) return zeigeFehler(res.error)

    aufraeumen()
    const id = taskId
    setMeldung({
      text: t(`meldung.${aktion}`, { titel: a.kopf.kurztitel }),
      oeffnen: aktion === 'freigabeZurueck' ? undefined : () => {
        setMeldung(null)
        navigate(`/admin/pruefen/${id}`)
      },
    })
    // Freigabe zuruecknehmen ist keine Entscheidung ueber die Aufgabe: sie bleibt offen.
    if (aktion === 'freigabeZurueck') p.neuLaden()
    else weiter(id, ART[aktion] ?? null)
  }, [taskId, p, arbeitet, antwort, aufraeumen, t, navigate, weiter, zeigeFehler])

  return { arbeitet, fehler, setFehler, zeigeFehler, meldung, setMeldung, entscheide, weiter }
}
