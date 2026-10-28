// Render eines Erklärvideos (Anforderung Studio §7, Bauauftrag B4) — lokal (Ashkans Mac) und in der Vercel Sandbox.
//
//   npm run studio:render -- <sequenz-id> [--welt fussball] [--auftrag <render-id>]
//   npm run studio:render -- --skript datei.json --welt skelett --ohne-hochladen <ordner>   (ohne Datenbank)
//
// Ergebnis je Welt: <skill>_<welt>.mp4 (H.264, 1920 × 1080, preset veryfast), kapitel.json, untertitel.vtt,
// poster.jpg; Upload nach studio/render/<sequenz>/<welt>/<fingerabdruck>/<auftrag>/ und Meldung über
// studio_render_melden. --auftrag nur zusammen mit --welt (die Sandbox rendert genau einen Auftrag).
// Anmeldung: STUDIO_TOKEN (JWT, Sandbox) oder STUDIO_EMAIL + STUDIO_PASSWORT (lokal), dazu VITE_SUPABASE_URL und
// VITE_SUPABASE_ANON_KEY (.env). Browser: CHROME=<Pfad>, sonst lädt Remotion seinen eigenen.
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import path from 'node:path'
import { createClient, type SupabaseClient } from '@supabase/supabase-js'
import { bundle } from '@remotion/bundler'
import { renderMedia, renderStill, selectComposition } from '@remotion/renderer'

import { videoDatenAus, type BeatAudio } from '../src/studio/remotion/daten'
import { FPS, frameVonBeat, kapitel, untertitel, zeitplan } from '../src/studio/remotion/zeitplan'
import type { Skript } from '../src/studio/skript/typen'

const args = process.argv.slice(2)
const opt = (name: string) => {
  const i = args.indexOf(`--${name}`)
  return i >= 0 ? args[i + 1] : undefined
}
const sequenzId = args[0] && !args[0].startsWith('--') ? args[0] : undefined
const offline = opt('ohne-hochladen')
const browserExecutable = process.env.CHROME || undefined

async function anmelden(): Promise<SupabaseClient> {
  const url = process.env.VITE_SUPABASE_URL ?? process.env.SUPABASE_URL
  const anon = process.env.VITE_SUPABASE_ANON_KEY ?? process.env.SUPABASE_ANON_KEY
  if (!url || !anon) throw new Error('VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY fehlen')
  if (process.env.STUDIO_TOKEN)
    return createClient(url, anon, {
      global: { headers: { Authorization: `Bearer ${process.env.STUDIO_TOKEN}` } },
      auth: { persistSession: false, autoRefreshToken: false },
    })
  const db = createClient(url, anon, { auth: { persistSession: false } })
  const { error } = await db.auth.signInWithPassword({ email: process.env.STUDIO_EMAIL ?? '', password: process.env.STUDIO_PASSWORT ?? '' })
  if (error) throw new Error('Anmeldung fehlgeschlagen (STUDIO_EMAIL/STUDIO_PASSWORT)')
  return db
}

async function audioFuer(db: SupabaseClient, id: string, welt: string): Promise<BeatAudio> {
  const { data: bedarf, error } = await db.rpc('studio_stimme_bedarf', { p_sequenz_id: id })
  if (error) throw new Error(`studio_stimme_bedarf: ${error.message}`)
  const meine = ((bedarf ?? []) as { beat_key: string; welt: string; fingerabdruck: string; vorhanden: boolean }[]).filter(
    (b) => b.welt === welt && b.vorhanden,
  )
  if (meine.length === 0) return {}
  const { data: audio } = await db.from('studio_audio').select('fingerabdruck, pfad, dauer_ms').in('fingerabdruck', meine.map((b) => b.fingerabdruck))
  const zeilen = (audio ?? []) as { fingerabdruck: string; pfad: string; dauer_ms: number }[]
  const { data: urls } = await db.storage.from('studio').createSignedUrls(zeilen.map((a) => a.pfad), 7200)
  const url = new Map((urls ?? []).map((u) => [u.path, u.signedUrl]))
  const fp = new Map(zeilen.map((a) => [a.fingerabdruck, { url: url.get(a.pfad) ?? '', dauerMs: a.dauer_ms }]))
  return Object.fromEntries(meine.flatMap((b) => (fp.get(b.fingerabdruck)?.url ? [[b.beat_key, fp.get(b.fingerabdruck)!]] : [])))
}

/** Rendert eine Welt in einen Ordner. Gibt die Dateien und die Dauer zurück. */
export async function weltRendern(serveUrl: string, skript: Skript, welt: string, audio: BeatAudio, ordner: string) {
  mkdirSync(ordner, { recursive: true })
  const inputProps = videoDatenAus(skript, welt, audio, false)
  const composition = await selectComposition({ serveUrl, id: 'Erklaervideo', inputProps, browserExecutable })
  const mp4 = path.join(ordner, `${skript.skill_key}_${welt}.mp4`)
  await renderMedia({ composition, serveUrl, codec: 'h264', x264Preset: 'veryfast', outputLocation: mp4, inputProps, browserExecutable })
  const titel = inputProps.beats.find((b) => b.baustein === 'titelkarte')?.key ?? inputProps.beats[0].key
  const poster = path.join(ordner, 'poster.jpg')
  await renderStill({
    composition, serveUrl, output: poster, imageFormat: 'jpeg', inputProps: { ...inputProps, ruhig: true },
    frame: frameVonBeat(inputProps.beats, titel), browserExecutable,
  })
  const kap = kapitel(inputProps.beats)
  writeFileSync(path.join(ordner, 'kapitel.json'), JSON.stringify(kap, null, 2))
  writeFileSync(path.join(ordner, 'untertitel.vtt'), untertitel(inputProps.beats))
  return { mp4, poster, kapitel: kap, dauerMs: Math.round((zeitplan(inputProps.beats).frames / FPS) * 1000) }
}

async function main() {
  const serveUrl = await bundle({ entryPoint: path.resolve('remotion/index.ts') })
  if (offline) {
    const datei = opt('skript')
    if (!datei) throw new Error('--skript fehlt')
    const skript = JSON.parse(readFileSync(datei, 'utf8')) as Skript
    for (const welt of opt('welt') ? [opt('welt') as string] : skript.welten) {
      const r = await weltRendern(serveUrl, skript, welt, {}, path.join(offline, welt))
      console.log(`${welt}: ${r.mp4} (${r.dauerMs} ms, ${r.kapitel.length} Kapitel)`)
    }
    return
  }
  if (!sequenzId) throw new Error('Sequenz-ID fehlt')
  if (opt('auftrag') && !opt('welt')) throw new Error('--auftrag nur zusammen mit --welt')
  const db = await anmelden()
  const { data: seq, error } = await db.from('studio_sequenz').select('skript').eq('id', sequenzId).single()
  if (error || !seq) throw new Error('Sequenz nicht lesbar')
  const skript = seq.skript as Skript
  const welten = opt('welt') ? [opt('welt') as string] : skript.welten
  for (const welt of welten) {
    let auftrag = opt('auftrag')
    if (!auftrag) {
      const r = await db.rpc('studio_render_anlegen', { p_sequenz_id: sequenzId, p_welt: welt, p_ort: 'lokal' })
      if (r.error) {
        console.error(`${welt}: übersprungen (${r.error.message})`)
        continue
      }
      auftrag = r.data as string
    }
    const { data: r, error: rFehler } = await db.from('studio_render').select('fingerabdruck, welt').eq('id', auftrag).single()
    if (rFehler || !r || (r as { welt: string }).welt !== welt) throw new Error('Auftrag nicht lesbar oder andere Welt')
    const l = await db.rpc('studio_render_melden', { p_id: auftrag, p_status: 'laeuft' })
    if (l.error) throw new Error(`melden laeuft: ${l.error.message}`)
    const { data: s2 } = await db.from('studio_render').select('status, fehler').eq('id', auftrag).single()
    if ((s2 as { status: string } | null)?.status !== 'laeuft') {
      console.error(`${welt}: abgebrochen (${(s2 as { fehler: string | null } | null)?.fehler ?? 'Status'})`)
      process.exitCode = 1
      continue
    }
    try {
      const ordner = path.join(tmpdir(), 'studio-render', auftrag)
      const erg = await weltRendern(serveUrl, skript, welt, await audioFuer(db, sequenzId, welt), ordner)
      const basis = `render/${sequenzId}/${welt}/${(r as { fingerabdruck: string }).fingerabdruck}/${auftrag}/`
      const hoch = async (datei: string, name: string, typ: string) => {
        const u = await db.storage.from('studio').upload(basis + name, readFileSync(datei), { contentType: typ, upsert: false })
        if (u.error) throw new Error(`Upload ${name}: ${u.error.message}`)
        return basis + name
      }
      const ergebnis = {
        mp4: await hoch(erg.mp4, path.basename(erg.mp4), 'video/mp4'),
        untertitel: await hoch(path.join(ordner, 'untertitel.vtt'), 'untertitel.vtt', 'text/vtt'),
        poster: await hoch(erg.poster, 'poster.jpg', 'image/jpeg'),
        kapitel: erg.kapitel,
        dauer_ms: erg.dauerMs,
      }
      await hoch(path.join(ordner, 'kapitel.json'), 'kapitel.json', 'application/json')
      const m = await db.rpc('studio_render_melden', { p_id: auftrag, p_status: 'fertig', p_ergebnis: ergebnis })
      if (m.error) throw new Error(m.error.message)
      const { data: s3 } = await db.from('studio_render').select('status, fehler').eq('id', auftrag).single()
      if ((s3 as { status: string } | null)?.status !== 'fertig') throw new Error((s3 as { fehler: string | null } | null)?.fehler ?? 'nicht fertig')
      console.log(`${welt}: fertig (${erg.dauerMs} ms)`)
    } catch (e) {
      const grund = e instanceof Error ? e.message : String(e)
      await db.rpc('studio_render_melden', { p_id: auftrag, p_status: 'fehler', p_fehler: grund })
      console.error(`${welt}: Fehler: ${grund}`)
      process.exitCode = 1
    }
  }
}

main().catch((e) => {
  console.error(e instanceof Error ? e.message : e)
  process.exit(1)
})
