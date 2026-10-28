/**
 * POST /api/studio/stimme — „Fehlende erzeugen“ (Anforderung Studio §5, Bauauftrag B2).
 *
 * Vercel Function. Body: { sequenzId }. Header: Authorization: Bearer <Supabase-JWT des Autors>.
 * Rechte prüft die Datenbank (studio_stimme_bedarf liest nur für Studio-Beteiligte, studio_audio_eintragen
 * und der Storage-Upload nur für Autor/Admin). Der ElevenLabs-Schlüssel kommt nur aus der Server-Umgebung
 * (ELEVENLABS_API_KEY), nie aus dem Browser, nie in Antworten oder Logs. Ohne Schlüssel: Platzhalter
 * (stumme WAV, stimme 'platzhalter').
 *
 * Je Aufruf höchstens MAX_JE_AUFRUF Dateien (Laufzeitgrenze); die Oberfläche ruft erneut, solange `offen` > 0.
 * Gleicher Fingerabdruck → dieselbe Datei: ein Satz, der in mehreren Welten gleich ist, wird einmal vertont.
 */
import { createClient } from '@supabase/supabase-js'

import { elevenVertonen, platzhalterVertonen, type Vertonung } from '../../src/studio/stimme/anbieter'

const MAX_JE_AUFRUF = 8
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

type Bedarf = {
  beat_key: string
  welt: string
  satz: string
  davor: string | null
  danach: string | null
  fingerabdruck: string
  vorhanden: boolean
  stimme: string
  modell: string
}

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } })

export async function POST(request: Request): Promise<Response> {
  const token = request.headers.get('authorization')?.replace(/^Bearer\s+/i, '')
  const url = process.env.VITE_SUPABASE_URL ?? process.env.SUPABASE_URL
  const anon = process.env.VITE_SUPABASE_ANON_KEY ?? process.env.SUPABASE_ANON_KEY
  if (!token) return json(401, { fehler: 'ohne_anmeldung' })
  if (!url || !anon) return json(500, { fehler: 'konfiguration' })
  let sequenzId: unknown
  try {
    sequenzId = ((await request.json()) as { sequenzId?: unknown }).sequenzId
  } catch {
    return json(400, { fehler: 'kein_json' })
  }
  if (typeof sequenzId !== 'string' || !UUID.test(sequenzId)) return json(400, { fehler: 'sequenz_fehlt' })

  const db = createClient(url, anon, {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  })
  // Erst die Rolle, dann jede kostenpflichtige Vertonung (Anforderung §5: nur Autor und Admin).
  const { data: autor, error: rFehler } = await db.rpc('studio_hat_rolle', { p_rolle: 'autor' })
  if (rFehler || autor !== true) return json(403, { fehler: 'kein_zugriff' })

  // Ohne Schlüssel immer Platzhalter; sonst wählt die Datenbank die Stimme (Sequenz, sonst Einstellung).
  const schluessel = process.env.ELEVENLABS_API_KEY
  const { data: bedarf, error: bFehler } = await db.rpc('studio_stimme_bedarf', {
    p_sequenz_id: sequenzId,
    p_stimme: schluessel ? null : 'platzhalter',
  })
  if (bFehler) return json(403, { fehler: 'kein_zugriff' })
  const fehlend = new Map<string, Bedarf>()
  for (const b of (bedarf ?? []) as Bedarf[]) if (!b.vorhanden && !fehlend.has(b.fingerabdruck)) fehlend.set(b.fingerabdruck, b)

  let erzeugt = 0
  let platzhalter = !schluessel
  const fehler: string[] = []
  for (const b of [...fehlend.values()].slice(0, MAX_JE_AUFRUF)) {
    try {
      const still = b.stimme === 'platzhalter'
      platzhalter = platzhalter || still
      const v: Vertonung = still
        ? platzhalterVertonen(b)
        : await elevenVertonen(b, { schluessel: schluessel as string, stimme: b.stimme, modell: b.modell })
      const pfad = `audio/${still ? 'platzhalter/' : ''}${b.fingerabdruck}.${v.endung}`
      // Ohne upsert: liegt die Datei schon da (früherer Lauf), ist es dieselbe — weiter zum Eintrag.
      const up = await db.storage.from('studio').upload(pfad, v.audio, { contentType: v.mime, upsert: false })
      if (up.error && !/exist|duplicate/i.test(up.error.message)) throw new Error('upload')
      const ein = await db.rpc('studio_audio_eintragen', {
        p_fingerabdruck: b.fingerabdruck,
        p_pfad: pfad,
        p_stimme: b.stimme,
        p_modell: b.modell,
        p_dauer_ms: v.dauerMs,
        p_zeitstempel: v.zeitstempel,
        p_platzhalter: still,
      })
      if (ein.error) throw new Error('eintragen')
      erzeugt++
    } catch (e) {
      // Nur Beat, Welt und eine kurze Ursache; nie Schlüssel oder Antworttexte.
      fehler.push(`${b.beat_key}/${b.welt}: ${e instanceof Error ? e.message : 'fehler'}`)
    }
  }
  return json(200, { erzeugt, offen: Math.max(0, fehlend.size - erzeugt), platzhalter, fehler })
}
