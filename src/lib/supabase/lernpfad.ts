// Lernpfad und Mastery auf skill_key (Session-Rahmen P1, Paket A1,
// Migrationen 20261007120412–20261007120416). Noch ohne Oberflaeche; P2 baut
// darauf. Gelesen wird der Lernpfad direkt (RLS: Admin, Coach bei laufendem
// Vertrag), alles andere geht ueber RPCs. Schreibende Aufrufe gibt es nur als
// RPC — die Tabellen haben fuer authenticated kein INSERT/UPDATE/DELETE.

import { supabase } from '@/lib/supabase/client'
import { sessionRpc, type RpcResult } from '@/lib/supabase/sessionRpc'
import type {
  BelegErgebnis,
  LernpfadEintrag,
  LernpfadStandCoach,
  LernpfadStandSystem,
  LernpfadUebernahme,
  MasteryEntscheidung,
  MasteryVorschlag,
  MeinLernpfadEintrag,
  PfadAnlass,
  NaechsteLuecke,
  SkillPruefung,
  SupabaseResult,
  ZielFertigkeit,
} from '@/types'

const fehler = (err: unknown, fallback: string): string =>
  err instanceof Error ? err.message : fallback

// C2: ueber sessionRpc, damit SQLSTATE und Hinweis bei Fehlern mitgehen.
function rufe<T>(fn: string, args: Record<string, unknown>, fallback: string): Promise<RpcResult<T>> {
  return sessionRpc<T>(fn, args, fallback)
}

/** Lernpfad eines Kindes (Coach bei laufendem Vertrag oder Admin). */
export async function listLernpfad(studentId: string): Promise<SupabaseResult<LernpfadEintrag[]>> {
  try {
    const { data, error } = await supabase
      .from('lernpfad')
      .select(
        'id, student_id, skill_key, stand_system, stand_system_seit, stand_coach, coach_grund, coach_von, coach_am, coach_session_id, quelle, lsa_session_id, letzte_uebung_am, letzte_session_id, belege',
      )
      .eq('student_id', studentId)
      .order('skill_key', { ascending: true })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as LernpfadEintrag[], error: null }
  } catch (err) {
    return { data: null, error: fehler(err, 'Could not load learning path') }
  }
}

/** Uebernahme aus der LSA (Skill-Urteile, student_focus_areas). Idempotent. */
export function lernpfadAusLsa(studentId: string): Promise<SupabaseResult<LernpfadUebernahme>> {
  return rufe('lernpfad_aus_lsa', { p_student_id: studentId }, 'Could not transfer LSA into learning path')
}

/** Bucht einen Beleg aus einer Session; liefert den neuen Systemzustand. */
export function lernpfadBeleg(args: {
  studentId: string
  skillKey: string
  sessionId: string
  ergebnis: BelegErgebnis
  hinweisGenutzt: boolean
}): Promise<SupabaseResult<LernpfadStandSystem>> {
  return rufe(
    'lernpfad_beleg',
    {
      p_student_id: args.studentId,
      p_skill_key: args.skillKey,
      p_session_id: args.sessionId,
      p_ergebnis: args.ergebnis,
      p_hinweis_genutzt: args.hinweisGenutzt,
    },
    'Could not record evidence',
  )
}

/** „Ziel der Stunde“: Fertigkeiten des Themas mit Voraussetzungen und Stand. */
export function zielFertigkeiten(studentId: string, themaKey: string): Promise<SupabaseResult<ZielFertigkeit[]>> {
  return rufe('ziel_fertigkeiten', { p_student_id: studentId, p_thema_key: themaKey }, 'Could not load session goal')
}

/** Ziel fuer den Fall Lernpfad; null, wenn es keine Luecke gibt. */
export async function naechsteLuecke(studentId: string): Promise<SupabaseResult<NaechsteLuecke | null>> {
  const res = await rufe<NaechsteLuecke[]>('naechste_luecke', { p_student_id: studentId }, 'Could not load next gap')
  if (res.error !== null) return { data: null, error: res.error }
  return { data: res.data?.[0] ?? null, error: null }
}

/** Eine Stufe tiefer; liefert den Skill, der jetzt aktiv ist. */
export function pfadTiefer(args: {
  studentId: string
  skillKey: string
  sessionId: string | null
  voraussetzung?: string | null
  anlass?: PfadAnlass
}): Promise<SupabaseResult<string>> {
  return rufe(
    'pfad_tiefer',
    {
      p_student_id: args.studentId,
      p_skill_key: args.skillKey,
      p_session_id: args.sessionId,
      p_voraussetzung: args.voraussetzung ?? null,
      p_anlass: args.anlass ?? 'warmup',
    },
    'Could not set path one level deeper',
  )
}

/** Zur Mastery-Pruefung vorgeschlagene Kandidaten eines Kindes. */
export function masteryVorschlaege(studentId: string): Promise<SupabaseResult<MasteryVorschlag[]>> {
  return rufe('mastery_vorschlaege', { p_student_id: studentId }, 'Could not load mastery proposals')
}

/** Freigegebene Pruefgespraeche eines Skills (Coach, Admin). */
export function skillPruefungen(skillKey: string): Promise<SupabaseResult<SkillPruefung[]>> {
  return rufe('skill_pruefung_lesen', { p_skill_key: skillKey }, 'Could not load mastery check')
}

/** Mastery-Entscheidung des Coaches; „vertagt“ braucht einen Grund. */
export function masteryEntscheiden(args: {
  studentId: string
  skillKey: string
  entscheidung: LernpfadStandCoach
  grund: string | null
  sessionId: string | null
}): Promise<RpcResult<MasteryEntscheidung>> {
  return rufe(
    'mastery_entscheiden',
    {
      p_student_id: args.studentId,
      p_skill_key: args.skillKey,
      p_entscheidung: args.entscheidung,
      p_grund: args.grund,
      p_session_id: args.sessionId,
    },
    'Could not save mastery decision',
  )
}

/** Eigener Lernpfad des Kindes. */
export function meinLernpfad(): Promise<SupabaseResult<MeinLernpfadEintrag[]>> {
  return rufe('mein_lernpfad', {}, 'Could not load own learning path')
}
