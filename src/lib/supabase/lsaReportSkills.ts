// Eltern-Report — die Skill-Ebene der Diagnose (R2).
//
// Eigene Datei, weil lsaReport.ts sonst über die 400-Zeilen-Grenze liefe
// (CLAUDE §4) — und weil dieser Lesepfad eine andere Quelle hat als der Rest
// des Reports: lsa_skill_urteil statt lsa_responses/tasks.

import { supabase } from '@/lib/supabase/client'
import type { ReportSkillbefund, ReportSkillbefunde } from '@/types'

/**
 * Die Skill-Ebene der Diagnose (R2) — „Was wir uns genauer ansehen".
 *
 * Bis R2 erhob die LSA je Sitzung Dutzende Skill-Urteile, von denen im
 * Elternreport keines auftauchte. Ein Kind mit sechs nicht tragenden Skills
 * bekam einen Report, in dem „Das läuft gut" stand.
 *
 * Gelesen wird DIREKT aus lsa_skill_urteil: die Tabelle trägt zwei
 * Lesepolicies — lsa_skill_urteil_coach_admin_read und
 * lsa_skill_urteil_parent_read — und `authenticated` hat SELECT. Es braucht
 * also weder eine neue RPC noch einen neuen Grant. (Die Fehlbild-RPCs gibt es
 * aus einem anderen Grund: auf lsa_responses.fehlbild_slug liegt kein Grant.)
 *
 * Zwei Abfragen statt eines PostgREST-Embeds: die Zuordnung Urteil -> Label
 * ist ein einfacher Join über den Schlüssel, und zwei klare Abfragen sind hier
 * weniger fehleranfällig als eine eingebettete.
 *
 * Ein Fehler darf den Report nicht kippen — der Abschnitt ist eine Ergänzung,
 * nicht der Report. Deshalb null statt Fehlerdurchreichung.
 */
export async function loadSkillbefunde(
  sessionId: string,
): Promise<ReportSkillbefunde | null> {
  const { data: urteile, error } = await supabase
    .from('lsa_skill_urteil')
    .select('skill_key, zustand')
    .eq('session_id', sessionId)
    // NUR direkt geprüfte Skills. Mitbelegte Urteile sind aus dem
    // Voraussetzungsgraphen abgeleitet — wer einen Skill trägt, trägt implizit
    // dessen Voraussetzungen. Das ist eine Schlussfolgerung, keine Beobachtung,
    // und gehört nicht als Befund in ein Elterngespräch.
    .eq('belegt_direkt', true)
  if (error || !urteile || urteile.length === 0) return null

  type Urteil = { skill_key: string; zustand: string }
  const rows = urteile as Urteil[]

  // 'traegt_nicht' und 'traegt_teilweise' sind Befunde. 'nicht_angesetzt' und
  // 'ungeprueft' sind KEINE: dort hat das Kind nichts versucht, und fehlende
  // Evidenz ist kein Befund. Sie zählen deshalb weder hier noch bei den
  // tragenden Bereichen mit.
  const nichtTragendKeys = rows
    .filter((r) => r.zustand === 'traegt_nicht' || r.zustand === 'traegt_teilweise')
    .map((r) => r.skill_key)
  const tragendAnzahl = rows.filter((r) => r.zustand === 'traegt').length

  if (nichtTragendKeys.length === 0) {
    return { nichtTragend: [], tragendAnzahl, zurueckgegangen: false }
  }

  const { data: skills, error: sErr } = await supabase
    .from('skills')
    .select('skill_key, label, fundament_tiefe')
    .in('skill_key', nichtTragendKeys)
  if (sErr || !skills) return null

  const nichtTragend: ReportSkillbefund[] = []
  for (const s of skills as {
    skill_key: string
    label: string | null
    fundament_tiefe: number | null
  }[]) {
    const label = s.label?.trim()
    // Ohne Label kein Eintrag: der Schlüssel selbst ist snake_case und kein
    // Satz für Eltern (INV-4.3). Erfunden wird hier nichts.
    if (!label || s.fundament_tiefe == null) continue
    nichtTragend.push({
      skillKey: s.skill_key,
      label,
      fundamentTiefe: s.fundament_tiefe,
    })
  }

  // Absteigend nach Fundamenttiefe: zuerst das, was am nächsten am Einstieg
  // liegt, zuletzt das Grundlegendste. Bei Gleichstand alphabetisch, damit die
  // Reihenfolge nicht von der Zeilenreihenfolge der Datenbank abhängt.
  nichtTragend.sort(
    (a, b) => b.fundamentTiefe - a.fundamentTiefe || a.label.localeCompare(b.label, 'de'),
  )

  // Streuen die Befunde über mehr als eine Fundamentstufe, musste die Analyse
  // hinter den Einstieg zurückgehen. Liegen alle auf einer Stufe, gibt es dazu
  // nichts zu sagen.
  const stufen = new Set(nichtTragend.map((s) => s.fundamentTiefe))

  return { nichtTragend, tragendAnzahl, zurueckgegangen: stufen.size > 1 }
}
