// Daten der Admin-Pruefansicht: die Pruefkarten-Sitzung wie bei Lena (usePruefSitzung: laden, entprellt
// speichern, Version, ED409), dazu Lenas Ergebnis, Team-Beanstandung, Ausschluss von Hand und Verlauf
// (getAdminPruefKontext) und die Befunde vor der Freigabe aus der Aufgabe im Editor-Format (computeFlags).
// Die Befunde laden nach jedem Speichern neu (neue pruef_version), damit „Freigeben“ nie gegen einen alten
// Stand gesperrt oder entsperrt ist.

import { useCallback, useEffect, useMemo, useState } from 'react'
import { befundeVorFreigabe, type Befund } from '@/lib/pruefung/befunde'
import { getFehlbilder } from '@/lib/supabase/pruefung'
import { getAdminPruefKontext } from '@/lib/supabase/pruefungAdmin'
import { getAuthoringTask, getTaskSolution, probeAuthoringSchema } from '@/lib/supabase/taskAuthoring'
import { usePruefSitzung, type Sitzung } from '@/pages/coach/pruefen/usePruefSitzung'
import type { AdminPruefKontext, AuthoringTask, Fehlbild, TaskSolution } from '@/types'

type Editorstand = { task: AuthoringTask; loesung: TaskSolution; stoffanker: boolean }

export type AdminPruefung = {
  s: Sitzung
  kontext: AdminPruefKontext | null
  befunde: { sperrend: Befund[]; hinweise: Befund[] }
  /** Befunde sind geladen (sonst bleibt „Freigeben“ gesperrt, bis sie da sind). */
  befundeGeladen: boolean
  fehlbilder: Fehlbild[]
  /** Pruefkarte, Kontext und Befunde neu laden (nach Pilot, ED409, Rueckkehr aus dem Editor). */
  neuLaden: () => void
}

export function useAdminPruefung(taskId: string | undefined): AdminPruefung {
  const s = usePruefSitzung(taskId)
  const [kontext, setKontext] = useState<AdminPruefKontext | null>(null)
  const [stand, setStand] = useState<Editorstand | null>(null)
  const [fehlbilder, setFehlbilder] = useState<Fehlbild[]>([])
  const [zaehler, setZaehler] = useState(0)

  useEffect(() => {
    void getFehlbilder().then((r) => r.data && setFehlbilder(r.data))
  }, [])

  useEffect(() => {
    if (!taskId) return
    let aktiv = true
    setKontext(null)
    void getAdminPruefKontext(taskId).then((r) => {
      if (aktiv) setKontext(r.data)
    })
    return () => {
      aktiv = false
    }
  }, [taskId, zaehler])

  const version = s.version
  useEffect(() => {
    if (!taskId) return
    let aktiv = true
    void Promise.all([probeAuthoringSchema(), getAuthoringTask(taskId), getTaskSolution(taskId)]).then(([schema, task, loesung]) => {
      if (!aktiv) return
      setStand(task.data && loesung.data ? { task: task.data, loesung: loesung.data, stoffanker: schema.hasStoffanker } : null)
    })
    return () => {
      aktiv = false
    }
  }, [taskId, version, zaehler])

  const ausschluss = s.aufgabe?.aufgabe.ausschluss ?? null
  const befunde = useMemo(
    () => (stand && stand.task.id === taskId
      ? befundeVorFreigabe(stand.task, stand.loesung, stand.stoffanker, ausschluss)
      : { sperrend: [], hinweise: [] }),
    [stand, taskId, ausschluss],
  )

  const { neuLaden: karteNeu } = s
  const neuLaden = useCallback(() => {
    karteNeu()
    setZaehler((n) => n + 1)
  }, [karteNeu])

  return { s, kontext, befunde, befundeGeladen: !!stand && stand.task.id === taskId, fehlbilder, neuLaden }
}
