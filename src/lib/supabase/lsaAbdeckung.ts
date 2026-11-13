import { supabase } from '@/lib/supabase/client'
import { rufe } from '@/lib/supabase/pruefung'
import type {
  LsaAbdeckungZeile,
  LsaPaketSkill,
  LsaWirkungZeile,
  PruefResult,
  PruefZielStandZeile,
  PruefZielZeile,
} from '@/types'

/**
 * FR-2: Pakete je Klassenarbeit und gezielte Prüfliste (Migration 20261109114850_fr2_lsa_pakete).
 * Alle Funktionen prüfen darf_pruefen (Admins und Lena); Fokus setzen nur Admins (RLS schule_fokus).
 * Die Funktionen stehen nicht in database.ts — rufe() hält den Cast an einer Stelle (Muster pruefung.ts).
 */

/** Rechnet den Zwischenspeicher neu, wenn Plan, Einstiege oder Graph sich geändert haben (sonst nichts). */
export function frischeLsaAbdeckung(): Promise<PruefResult<boolean>> {
  return rufe<boolean>('lsa_abdeckung_auffrischen')
}

/** Je Schule und Paket die Ampel (lsa_abdeckung). */
export function getLsaAbdeckung(filter: {
  klasse: number | null
  quartal: number | null
  nurFokus: boolean
}): Promise<PruefResult<LsaAbdeckungZeile[]>> {
  return rufe<LsaAbdeckungZeile[]>('lsa_abdeckung', {
    p_klasse: filter.klasse,
    p_quartal: filter.quartal,
    p_nur_fokus: filter.nurFokus,
  })
}

/** Skills eines Pakets mit Stand und Prüfbedarf (lsa_paket_skills). */
export function getLsaPaketSkills(schuleId: string, klasse: number, paketNr: number): Promise<PruefResult<LsaPaketSkill[]>> {
  return rufe<LsaPaketSkill[]>('lsa_paket_skills', { p_schule: schuleId, p_klasse: klasse, p_paket_nr: paketNr })
}

/**
 * Gezielte Prüfliste und Nachprüfen (pruef_ziel_liste). IU-1: optional Prüfziel (z. B. msa_zp10, auch Kompetenzen
 * ohne Paket) und Kompetenz; ohne sie ruft die Seite genau wie bisher.
 */
export function getPruefZielListe(
  nurFokus = false,
  quartal: number | null = null,
  filter: { ziel?: string | null; skill?: string | null } = {},
): Promise<PruefResult<PruefZielZeile[]>> {
  return rufe<PruefZielZeile[]>('pruef_ziel_liste', {
    p_nur_fokus: nurFokus,
    p_quartal: quartal,
    ...(filter.ziel ? { p_pruefziel: filter.ziel } : {}),
    ...(filter.skill ? { p_skill: filter.skill } : {}),
  })
}

/** IU-1: Stand je Kompetenz eines Prüfziels (pruef_ziel_stand), auch erledigte Kompetenzen. */
export function getPruefZielStand(ziel: string): Promise<PruefResult<PruefZielStandZeile[]>> {
  return rufe<PruefZielStandZeile[]>('pruef_ziel_stand', { p_pruefziel: ziel })
}

/** Pakete, deren Ampel sich ändert, wenn skill (und auch) die Regel erfüllen (lsa_wirkung). */
export function getLsaWirkung(
  skill: string,
  auch: string[] = [],
  quartal: number | null = null,
): Promise<PruefResult<LsaWirkungZeile[]>> {
  return rufe<LsaWirkungZeile[]>('lsa_wirkung', { p_skill: skill, p_auch: auch, p_quartal: quartal })
}

/** Quartal des nächsten LSA-Fensters (Stellschraube lsa_fokus_quartal); ohne Zeile 3. */
export async function getFokusQuartal(): Promise<number> {
  try {
    const { data, error } = await supabase
      .from('session_einstellungen')
      .select('wert')
      .eq('schluessel', 'lsa_fokus_quartal')
      .maybeSingle()
    if (error || !data) return 3
    const q = Number((data as { wert: unknown }).wert)
    return Number.isInteger(q) && q >= 1 && q <= 4 ? q : 3
  } catch {
    return 3
  }
}

/** Fokus an oder aus (schule_fokus; RLS: nur Admins). */
export async function setSchuleFokus(schuleId: string, an: boolean): Promise<PruefResult<null>> {
  try {
    const tabelle = supabase.from('schule_fokus' as never) as unknown as {
      insert: (z: { schule_id: string }) => PromiseLike<{ error: { message: string; code?: string } | null }>
      delete: () => { eq: (c: string, v: string) => PromiseLike<{ error: { message: string; code?: string } | null }> }
    }
    const { error } = an ? await tabelle.insert({ schule_id: schuleId }) : await tabelle.delete().eq('schule_id', schuleId)
    if (error) return { data: null, error: { code: error.code ?? null, hint: null, message: error.message } }
    return { data: null, error: null }
  } catch (err) {
    return { data: null, error: { code: null, hint: null, message: err instanceof Error ? err.message : 'Fokus fehlgeschlagen' } }
  }
}
