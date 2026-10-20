// Eltern-Bericht R7-9 — Lesepfad für den Lernweg: Heimat-Themen und der Plan
// der Klasse (Schulplan der Schule des Kindes, sonst Kernlehrplan NRW).
// Nur lesen. Die Rechnung steht in src/lib/report/elternbericht/plan.ts.
//
// Leserechte (RLS): schulen und leads liest nur der Admin. Für einen Coach
// fallen der Weg über den Lead und der Abgleich über den Namen weg; findet
// students.schule_id die Schule, gilt ihr Plan trotzdem (schul_themenplan liest
// auch der Coach), nur ohne Schulnamen.

import { supabase } from '@/lib/supabase/client'
import { findeSchule, planFuer, type KlpThema, type SchulplanZeile } from '@/lib/report/elternbericht/plan'
import type { HeimatThema, LernPlan, Stufe } from '@/types'

const FACH = 'mathematik'

/** skill_thema: das Heimat-Thema je Skill. Leer bei Fehler. */
export async function loadHeimatThemen(): Promise<HeimatThema[]> {
  try {
    const { data, error } = await supabase.from('skill_thema').select('skill_key, thema_key')
    if (error || !data) {
      console.warn('report: skill_thema lookup failed', error)
      return []
    }
    return (data as { skill_key: string; thema_key: string }[]).map((r) => ({
      skillKey: r.skill_key,
      themaKey: r.thema_key,
    }))
  } catch (e) {
    console.warn('report: skill_thema lookup failed', e)
    return []
  }
}

/** Die Schule des Kindes einer Sitzung, mit Namen, wenn lesbar. */
async function loadSchule(studentId: string): Promise<{ id: string; name: string | null } | null> {
  const { data: s, error } = await supabase
    .from('students')
    .select('schule_id, lead_id, school_name')
    .eq('id', studentId)
    .maybeSingle()
  if (error || !s) return null
  const student = s as { schule_id: string | null; lead_id: string | null; school_name: string | null }

  const [lead, schulen] = await Promise.all([
    student.schule_id || !student.lead_id
      ? Promise.resolve({ data: null })
      : supabase.from('leads').select('schule_id').eq('id', student.lead_id).maybeSingle(),
    supabase.from('schulen').select('id, name'),
  ])
  const liste = ((schulen.data ?? []) as { id: string; name: string }[])
  const gefunden = findeSchule({
    schuelerSchule: student.schule_id,
    leadSchule: (lead.data as { schule_id: string | null } | null)?.schule_id ?? null,
    schulname: student.school_name,
    schulen: liste,
  })
  if (!gefunden) return null
  return { id: gefunden.id, name: liste.find((x) => x.id === gefunden.id)?.name ?? null }
}

/**
 * Der Plan der Klasse für eine Sitzung (Entscheidung 3): Schulplan der Schule
 * des Kindes für lsa_sessions.grade (und grade + 1), sonst Kernlehrplan NRW.
 * null bei Fehler — dann zeigt der Lernweg kein „Kommt noch“.
 */
export async function loadPlan(sessionId: string): Promise<LernPlan | null> {
  try {
    const { data: sitzung, error } = await supabase
      .from('lsa_sessions')
      .select('student_id, grade')
      .eq('id', sessionId)
      .maybeSingle()
    if (error || !sitzung) return null
    const { student_id: studentId, grade: klasse } = sitzung as { student_id: string; grade: number }

    const [schule, themen] = await Promise.all([
      loadSchule(studentId),
      supabase.from('themen').select('thema_key, klasse, label, stufe, sort').eq('fach', FACH),
    ])
    if (themen.error) console.warn('report: themen lookup failed', themen.error)

    let schulZeilen: SchulplanZeile[] | null = null
    if (schule) {
      const { data, error: pErr } = await supabase
        .from('schul_themenplan')
        .select('klasse, position, thema_key, uv_titel, halbjahr')
        .eq('schule_id', schule.id)
        .eq('fach', FACH)
        .in('klasse', [klasse, klasse + 1])
      if (pErr) console.warn('report: schul_themenplan lookup failed', pErr)
      schulZeilen = ((data ?? []) as {
        klasse: number
        position: number
        thema_key: string | null
        uv_titel: string
        halbjahr: 1 | 2 | null
      }[]).map((z) => ({
        klasse: z.klasse,
        position: z.position,
        themaKey: z.thema_key,
        titel: z.uv_titel,
        halbjahr: z.halbjahr,
      }))
    }

    const klp: KlpThema[] = ((themen.data ?? []) as {
      thema_key: string
      klasse: number
      label: string | null
      stufe: Stufe
      sort: number | null
    }[])
      // Ohne Label kein Eintrag: der Schlüssel ist kein Titel für Eltern.
      .filter((t) => t.label?.trim())
      .map((t) => ({ themaKey: t.thema_key, klasse: t.klasse, label: t.label!.trim(), stufe: t.stufe, sort: t.sort }))

    return planFuer({ schulZeilen, schulname: schule?.name ?? null, themen: klp, klasse })
  } catch (e) {
    console.warn('report: plan lookup failed', e)
    return null
  }
}
