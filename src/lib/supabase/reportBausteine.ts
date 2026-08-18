// Eltern-Report — Lesepfad für Erzählbausteine, Zuordnung und Ansprechpartner (R4).
//
// Eigene Datei neben lsaReport.ts, weil lsaReport.ts sonst über die
// 400-Zeilen-Grenze liefe (CLAUDE §4) — und weil diese drei Lesepfade eine
// andere Quelle haben als der Rest des Reports: Registry-Tabellen und die
// Platzvergabe statt lsa_responses.
//
// Alle drei Funktionen geben im Fehlerfall den leeren Fall zurück, nicht einen
// Fehler: Fehlt ein Baustein, bleibt eine Stelle im Dokument leer — fehlt der
// ganze Report, ist das Elterngespräch geplatzt. Die Abwägung ist dieselbe wie
// bei loadSkillbefunde.

import { supabase } from '@/lib/supabase/client'
import type { AnlassZuordnung, ReportAnsprechpartner, ReportBaustein } from '@/types'

/**
 * Die ABGENOMMENEN Erzählbausteine.
 *
 * Der Filter auf `freigegeben_am` ist die Abnahme-Schranke und steht bewusst
 * HIER, im einzigen Lesepfad, statt in jeder aufrufenden Komponente. Ein
 * unabgenommener Satz über den Lernstand eines Kindes darf die Elternfläche
 * nicht erreichen — auch nicht versehentlich, auch nicht als Entwurf.
 *
 * Das ist dieselbe Schranke wie in lsa_fehlbild_auswertung, nur an anderer
 * Stelle: Dort nullt die RPC den Text, hier fällt die Zeile weg. Beides führt
 * zum selben Ergebnis — die Stelle bleibt leer statt einen Entwurf zu zeigen.
 */
export async function loadReportBausteine(): Promise<ReportBaustein[]> {
  const { data, error } = await supabase
    .from('report_bausteine')
    .select('schluessel, slot, fall, variante, text')
    .not('freigegeben_am', 'is', null)
  if (error || !data) return []

  return (data as ReportBaustein[]).map((b) => ({
    schluessel: b.schluessel,
    slot: b.slot,
    fall: b.fall,
    variante: b.variante,
    text: b.text,
  }))
}

/**
 * Die Zuordnung der von Eltern genannten Bereiche auf prüfbare Belege.
 *
 * Keine Abnahme-Schranke: Hier stehen Schlüssel, keine Sätze. Was daraus wird,
 * entscheidet report_bausteine — und das trägt die Schranke.
 */
export async function loadAnlassZuordnungen(): Promise<AnlassZuordnung[]> {
  const { data, error } = await supabase
    .from('report_anlass_zuordnung')
    .select('thema, anzeigename, skill_keys, fehlbild_familien, strukturell, messbar')
  if (error || !data) return []

  return (
    data as {
      thema: string
      anzeigename: string | null
      skill_keys: string[] | null
      fehlbild_familien: string[] | null
      strukturell: boolean
      messbar: boolean
    }[]
  ).map((z) => ({
    thema: z.thema,
    // Fällt der Anzeigename aus, steht der Rohwert da — holprig, aber lesbar.
    // Ein leerer Punkt in der Aufzählung wäre schlimmer.
    anzeigename: z.anzeigename?.trim() || z.thema,
    skillKeys: z.skill_keys ?? [],
    fehlbildFamilien: z.fehlbild_familien ?? [],
    strukturell: z.strukturell,
    messbar: z.messbar,
  }))
}

/**
 * Wer die Analyse begleitet hat — die Fußzeile des Dokuments.
 *
 * Quelle ist platz_assignments.created_by: die Person, die den Platz für diese
 * Sitzung vergeben hat. Das ist der belastbarste Bezug, den die Daten
 * hergeben — lsa_sessions trägt kein created_by, leads.owner_id ist bei beiden
 * Pilot-Leads null, und student_coach ist für provisorische Schüler leer.
 *
 * Gibt es mehrere Zuordnungen (Sitzung unterbrochen und fortgesetzt), zählt die
 * erste: Sie hat die Analyse begonnen.
 *
 * Fehlt die Zuordnung oder das Profil, bleiben beide Felder null und die
 * Fußzeile entfällt. Ein erfundener Ansprechpartner in einem Elterndokument
 * wäre schlimmer als keiner.
 */
export async function loadAnsprechpartner(
  sessionId: string,
): Promise<ReportAnsprechpartner> {
  const leer: ReportAnsprechpartner = { name: null, email: null }

  const { data, error } = await supabase
    .from('platz_assignments')
    .select('created_by, created_at')
    .eq('session_id', sessionId)
    .order('created_at', { ascending: true })
    .limit(1)
  if (error || !data || data.length === 0) return leer

  const createdBy = (data[0] as { created_by: string | null }).created_by
  if (!createdBy) return leer

  const { data: profil, error: pErr } = await supabase
    .from('profiles')
    .select('full_name, email')
    .eq('id', createdBy)
    .maybeSingle()
  if (pErr || !profil) return leer

  const p = profil as { full_name: string | null; email: string | null }
  return {
    name: p.full_name?.trim() || null,
    email: p.email?.trim() || null,
  }
}
