// Schuelerakte (S2) — Notizen. Geschrieben wird nur ueber die RPCs aus S1
// (notiz_anlegen / _ausblenden / _einblenden / _gesundheit_entfernen); die
// Tabelle hat keine Schreib-Policy. Die Wortliste liest das Notizfeld fuer die
// Live-Pruefung; verbindlich prueft notiz_anlegen serverseitig.

import { supabase } from '@/lib/supabase/client'
import { profilNamen } from '@/lib/supabase/akte'
import type { NotizKategorie, SchuelerNotiz, SupabaseResult, WortlisteEintrag } from '@/types'

const fehlertext = (err: unknown, fallback: string): string =>
  err instanceof Error ? err.message : fallback

/** Ergebnis eines Schreibaufrufs; `gesundheitsbegriff` ist gesetzt, wenn der Server wegen der Wortliste ablehnt. */
export type NotizErgebnis = SupabaseResult<true> & { gesundheitsbegriff?: string | null }

export async function listNotizen(studentId: string): Promise<SupabaseResult<SchuelerNotiz[]>> {
  try {
    const { data, error } = await supabase
      .from('schueler_notizen')
      .select('id, kategorie, text, autor_id, autor_rolle, created_at, ausgeblendet_am, ausgeblendet_von, ausgeblendet_grund, entfernt_am, entfernt_von')
      .eq('student_id', studentId)
      .order('created_at', { ascending: false })
    if (error) return { data: null, error: error.message }
    type Zeile = Omit<SchuelerNotiz, 'autor_name' | 'ausgeblendet_von_name' | 'entfernt_von_name'> & {
      autor_id: string | null
      ausgeblendet_von: string | null
      entfernt_von: string | null
    }
    const zeilen = (data ?? []) as Zeile[]
    const namen = await profilNamen(zeilen.flatMap((z) => [z.autor_id, z.ausgeblendet_von, z.entfernt_von]))
    const name = (id: string | null): string | null => (id ? (namen.get(id) ?? null) : null)
    return {
      data: zeilen.map(({ autor_id, ausgeblendet_von, entfernt_von, ...rest }) => ({
        ...rest,
        autor_name: name(autor_id),
        ausgeblendet_von_name: name(ausgeblendet_von),
        entfernt_von_name: name(entfernt_von),
      })),
      error: null,
    }
  } catch (err) {
    return { data: null, error: fehlertext(err, 'notizen failed') }
  }
}

export async function listWortlisteGesundheit(): Promise<SupabaseResult<WortlisteEintrag[]>> {
  try {
    const { data, error } = await supabase
      .from('akte_wortliste')
      .select('wort, nur_ganzes_wort')
      .eq('liste', 'gesundheit')
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as WortlisteEintrag[], error: null }
  } catch (err) {
    return { data: null, error: fehlertext(err, 'wortliste failed') }
  }
}

async function rpc(name: string, args: Record<string, unknown>): Promise<NotizErgebnis> {
  try {
    const { error } = await supabase.rpc(name, args)
    if (!error) return { data: true, error: null }
    // notiz_anlegen meldet einen Treffer der Wortliste mit hint 'gesundheitsbegriff:<wort>'.
    const hint = (error as { hint?: string | null }).hint ?? ''
    const begriff = hint.startsWith('gesundheitsbegriff:') ? hint.slice('gesundheitsbegriff:'.length) : null
    return { data: null, error: error.message, gesundheitsbegriff: begriff }
  } catch (err) {
    return { data: null, error: fehlertext(err, `${name} failed`) }
  }
}

export const notizAnlegen = (studentId: string, kategorie: NotizKategorie, text: string): Promise<NotizErgebnis> =>
  rpc('notiz_anlegen', { p_student_id: studentId, p_kategorie: kategorie, p_text: text })

export const notizAusblenden = (notizId: string, grund: string): Promise<NotizErgebnis> =>
  rpc('notiz_ausblenden', { p_notiz_id: notizId, p_grund: grund })

export const notizEinblenden = (notizId: string): Promise<NotizErgebnis> =>
  rpc('notiz_einblenden', { p_notiz_id: notizId })

export const notizGesundheitEntfernen = (notizId: string): Promise<NotizErgebnis> =>
  rpc('notiz_gesundheit_entfernen', { p_notiz_id: notizId })
