/**
 * POST /api/studio/render — Render per Knopf (Anforderung Studio §7, Bauauftrag B4).
 *
 * Vercel Function. Body: { sequenzId, welt }. Header: Authorization: Bearer <Supabase-JWT des Autors>.
 * Legt den Auftrag an (studio_render_anlegen prüft Rolle und Welt) und startet eine Vercel Sandbox, die das
 * Repo auf demselben Commit klont und `tools/studio-render.ts` mit dem JWT des Autors ausführt. Die Sandbox
 * meldet Status und Ergebnis selbst (studio_render_melden); die Route wartet nicht auf das Ende.
 *
 * Umgebung (Vercel): VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY, STUDIO_GIT_TOKEN (Lesezugriff aufs Repo),
 * optional STUDIO_GIT_URL; die Sandbox-Anmeldung kommt über VERCEL_OIDC_TOKEN (in Vercel Functions gesetzt).
 *
 * Das JWT des Autors muss noch mindestens 50 Minuten gelten (die Oberfläche frischt es vorher auf); länger als
 * 60 Minuten gilt kein Auftrag (studio_render_anlegen räumt ab). Installiert wird ohne Token in der Umgebung,
 * das Token bekommt nur der Render-Schritt. Scheitert die Installation, meldet ein curl den Fehler.
 */
import { createClient } from '@supabase/supabase-js'
import { Sandbox } from '@vercel/sandbox'

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
const WELTEN = ['skelett', 'fussball', 'gaming', 'musik']
// Bibliotheken für Chrome Headless Shell auf dem Sandbox-Image (Amazon Linux).
const CHROME_PAKETE = 'nss atk at-spi2-atk cups-libs libdrm libxkbcommon libXcomposite libXdamage libXrandr mesa-libgbm pango alsa-lib'

const MIN_RESTLAUFZEIT_S = 50 * 60

/** Restlaufzeit eines JWT in Sekunden (ohne Signaturprüfung; die prüft Supabase bei jedem Aufruf). */
function restlaufzeit(jwt: string): number {
  try {
    const nutzlast = JSON.parse(Buffer.from(jwt.split('.')[1], 'base64url').toString('utf8')) as { exp?: number }
    return (nutzlast.exp ?? 0) - Math.floor(Date.now() / 1000)
  } catch {
    return 0
  }
}

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } })

export async function POST(request: Request): Promise<Response> {
  const token = request.headers.get('authorization')?.replace(/^Bearer\s+/i, '')
  const url = process.env.VITE_SUPABASE_URL ?? process.env.SUPABASE_URL
  const anon = process.env.VITE_SUPABASE_ANON_KEY ?? process.env.SUPABASE_ANON_KEY
  if (!token) return json(401, { fehler: 'ohne_anmeldung' })
  if (!url || !anon || !process.env.STUDIO_GIT_TOKEN) return json(500, { fehler: 'konfiguration' })
  if (restlaufzeit(token) < MIN_RESTLAUFZEIT_S) return json(401, { fehler: 'token_zu_alt' })
  let body: { sequenzId?: unknown; welt?: unknown }
  try {
    body = (await request.json()) as typeof body
  } catch {
    return json(400, { fehler: 'kein_json' })
  }
  const { sequenzId, welt } = body
  if (typeof sequenzId !== 'string' || !UUID.test(sequenzId) || typeof welt !== 'string' || !WELTEN.includes(welt))
    return json(400, { fehler: 'eingabe' })

  const db = createClient(url, anon, {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  })
  const angelegt = await db.rpc('studio_render_anlegen', { p_sequenz_id: sequenzId, p_welt: welt, p_ort: 'server' })
  if (angelegt.error) {
    const status = angelegt.error.code === '42501' ? 403 : angelegt.error.code === '23505' ? 409 : angelegt.error.code === '22023' ? 400 : 502
    return json(status, { fehler: status === 409 ? 'laeuft_schon' : 'anlegen' })
  }
  const auftrag = angelegt.data as string

  let sandbox: Awaited<ReturnType<typeof Sandbox.create>> | null = null
  try {
    sandbox = await Sandbox.create({
      source: {
        type: 'git',
        url: process.env.STUDIO_GIT_URL ?? 'https://github.com/RasitGueven/Edvancev1.git',
        username: 'x-access-token',
        password: process.env.STUDIO_GIT_TOKEN,
        depth: 1,
        revision: process.env.VERCEL_GIT_COMMIT_SHA ?? 'main',
      },
      resources: { vcpus: 4 },
      timeout: 40 * 60 * 1000,
      runtime: 'node22',
    })
    // sequenzId (UUID), welt (Liste) und auftrag (aus der DB) sind geprüft; nichts davon ist frei eingegeben.
    const melden = (grund: string) =>
      `curl -s -X POST "$VITE_SUPABASE_URL/rest/v1/rpc/studio_render_melden" -H "apikey: $VITE_SUPABASE_ANON_KEY" ` +
      `-H "Authorization: Bearer $STUDIO_TOKEN" -H "content-type: application/json" ` +
      `-d '{"p_id":"${auftrag}","p_status":"fehler","p_fehler":"${grund}"}' >/dev/null`
    await sandbox.runCommand({
      cmd: 'bash',
      args: [
        '-lc',
        `git remote set-url origin https://github.com/RasitGueven/Edvancev1.git; ` +
          `(sudo dnf install -y ${CHROME_PAKETE} >/dev/null && ` +
          `env -u STUDIO_TOKEN -u VITE_SUPABASE_ANON_KEY npm ci --no-audit --no-fund >/dev/null) || { ${melden('installation')}; exit 1; }; ` +
          `npx tsx tools/studio-render.ts ${sequenzId} --welt ${welt} --auftrag ${auftrag} || ${melden('render_abbruch')}`,
      ],
      env: { STUDIO_TOKEN: token, VITE_SUPABASE_URL: url, VITE_SUPABASE_ANON_KEY: anon },
      detached: true,
    })
    return json(202, { auftrag })
  } catch {
    await sandbox?.stop().catch(() => undefined)
    await db.rpc('studio_render_melden', { p_id: auftrag, p_status: 'fehler', p_fehler: 'sandbox_start' })
    return json(502, { fehler: 'sandbox_start', auftrag })
  }
}
