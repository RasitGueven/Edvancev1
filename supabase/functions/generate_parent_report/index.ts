// Edge Function: generate_parent_report
//
// Erzeugt einen KI-gestuetzten Elternreport-ENTWURF (strukturiertes JSON)
// aus Schueler-Daten. Schreibt NICHT in die DB — der Coach editiert den
// Entwurf und gibt ihn ueber die bestehende parentReports-Lib frei.
//
// Laeuft privilegiert mit service-role; Autorisierung fail-closed:
//   - Bearer == SERVICE_ROLE_KEY  ODER
//   - eingeloggter User mit Rolle admin|coach
//
// LLM: Anthropic Messages API, Modell claude-sonnet-4-6.
// Key: Edge-Function-Secret ANTHROPIC_API_KEY (nie im Repo/Frontend).
//
// Kosten-Guardrail (fail-closed, VOR dem bezahlten Call): zaehlt
// erfolgreiche Generierungen aus parent_report_generations (Migration 027)
// und blockt mit 429 bei Limit-Ueberschreitung. Limits per Secret
// nachjustierbar (Default 30/Coach·Tag, 5/Schueler·7T, 3000/Monat global):
//   PR_COACH_DAILY_LIMIT, PR_STUDENT_WINDOW_DAYS, PR_STUDENT_WINDOW_LIMIT,
//   PR_GLOBAL_MONTHLY_LIMIT. Anrechnung NUR bei erfolgreichem Call.
//
// Deploy: supabase functions deploy generate_parent_report

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

type Body = {
  student_id: string
  period_start: string
  period_end: string
  coach_context?: string | null
}

function json(status: number, payload: unknown): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

const MODEL = 'claude-sonnet-4-6'

// Kosten-Guardrail-Limits — per Supabase-Secret ohne Redeploy nachjustierbar.
function intEnv(name: string, fallback: number): number {
  const v = Number(Deno.env.get(name))
  return Number.isFinite(v) && v > 0 ? Math.floor(v) : fallback
}

// Statischer System-Prompt — zuerst gerendert, per cache_control gecacht.
const SYSTEM_PROMPT = `Du bist eine erfahrene Lerncoach-Assistenz der Lernakademie Edvance.
Schreibe einen Elternreport auf Deutsch: warm, vertrauenswuerdig, klar und
beruhigend. Positive Entwicklungen prominent, Probleme sachlich und loesungs-
orientiert formuliert. Sprich die Eltern direkt an ("Ihr Kind").

STRIKTE REGELN:
- Nutze AUSSCHLIESSLICH die uebergebenen Daten. Erfinde keine Zahlen,
  Termine oder Ereignisse. Fehlt eine Information, formuliere vorsichtig
  ("In diesem Zeitraum liegen dazu keine Daten vor.").
- Keine Diagnosen, keine Versprechen von Notenzielen.
- Jeder Abschnitt 2-4 Saetze, konkret, ohne Floskeln.
- coach_notiz: eine persoenliche, ermutigende Schlussbemerkung der Coach-Sicht.`

const REPORT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    lernfortschritt: { type: 'string' },
    anwesenheit: { type: 'string' },
    eingriffe: { type: 'string' },
    empfehlung: { type: 'string' },
    coach_notiz: { type: 'string' },
  },
  required: [
    'lernfortschritt',
    'anwesenheit',
    'eingriffe',
    'empfehlung',
    'coach_notiz',
  ],
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') return json(405, { error: 'Method not allowed' })

  const url = Deno.env.get('SUPABASE_URL')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const anthropicKey = Deno.env.get('ANTHROPIC_API_KEY')
  if (!url || !serviceKey) return json(500, { error: 'Service-Config fehlt' })
  if (!anthropicKey) return json(500, { error: 'ANTHROPIC_API_KEY fehlt' })

  let body: Body
  try {
    body = await req.json()
  } catch {
    return json(400, { error: 'Ungueltiger Request-Body' })
  }
  if (!body.student_id || !body.period_start || !body.period_end) {
    return json(400, {
      error: 'student_id, period_start, period_end erforderlich',
    })
  }

  const admin = createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  // Autorisierung (fail-closed): Service-Role ODER Admin/Coach-JWT.
  // callerId = auth-User bei JWT-Pfad; null bei Service-Role (System).
  let callerId: string | null = null
  const authHeader = req.headers.get('Authorization') ?? ''
  const bearer = authHeader.replace(/^Bearer\s+/i, '').trim()
  if (bearer !== serviceKey) {
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
    if (!bearer || !anonKey) return json(401, { error: 'Nicht authentifiziert' })
    const caller = createClient(url, anonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { autoRefreshToken: false, persistSession: false },
    })
    const { data: u, error: uErr } = await caller.auth.getUser()
    if (uErr || !u.user) return json(401, { error: 'Nicht authentifiziert' })
    const { data: prof } = await admin
      .from('profiles')
      .select('role')
      .eq('id', u.user.id)
      .single()
    if (!prof || (prof.role !== 'admin' && prof.role !== 'coach')) {
      return json(403, { error: 'Nur Admin/Coach' })
    }
    callerId = u.user.id
  }

  const sId = body.student_id

  // ── Kosten-Guardrail (fail-closed, VOR dem bezahlten Anthropic-Call) ──────
  // Zaehlt erfolgreiche Generierungen aus parent_report_generations. Bei
  // Limit-Ueberschreitung ODER Zaehl-Fehler: 429 (lieber blocken als
  // ungebremst Kosten erzeugen).
  const COACH_DAILY_LIMIT = intEnv('PR_COACH_DAILY_LIMIT', 30)
  const STUDENT_WINDOW_DAYS = intEnv('PR_STUDENT_WINDOW_DAYS', 7)
  const STUDENT_WINDOW_LIMIT = intEnv('PR_STUDENT_WINDOW_LIMIT', 5)
  const GLOBAL_MONTHLY_LIMIT = intEnv('PR_GLOBAL_MONTHLY_LIMIT', 3000)

  const now = new Date()
  const monthStart = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1),
  ).toISOString()
  const dayStart = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
  ).toISOString()
  const windowStart = new Date(
    Date.now() - STUDENT_WINDOW_DAYS * 864e5,
  ).toISOString()

  const BLOCKED_UNCHECKABLE =
    'Kosten-Guardrail nicht pruefbar — Generierung vorsorglich blockiert.'

  // Liefert die Trefferzahl seit `since`, optional gefiltert auf eine
  // Spalte. null = Zaehlfehler (Aufrufer blockt fail-closed).
  async function genCount(
    since: string,
    eq?: { col: string; val: string },
  ): Promise<number | null> {
    let q = admin
      .from('parent_report_generations')
      .select('*', { count: 'exact', head: true })
      .gte('created_at', since)
    if (eq) q = q.eq(eq.col, eq.val)
    const { count, error } = await q
    if (error) {
      console.error('guardrail count failed:', error.message)
      return null
    }
    return count ?? 0
  }

  const globalCount = await genCount(monthStart)
  if (globalCount === null || globalCount >= GLOBAL_MONTHLY_LIMIT) {
    return json(429, {
      error:
        globalCount === null
          ? BLOCKED_UNCHECKABLE
          : `Globales Monatslimit fuer Report-Generierung erreicht (${GLOBAL_MONTHLY_LIMIT}). Bitte spaeter erneut versuchen oder Limit anpassen.`,
    })
  }

  const studentCount = await genCount(windowStart, {
    col: 'student_id',
    val: sId,
  })
  if (studentCount === null || studentCount >= STUDENT_WINDOW_LIMIT) {
    return json(429, {
      error:
        studentCount === null
          ? BLOCKED_UNCHECKABLE
          : `Limit fuer diesen Schueler erreicht (${STUDENT_WINDOW_LIMIT} in ${STUDENT_WINDOW_DAYS} Tagen). Bitte vorhandenen Entwurf nutzen oder spaeter erneut versuchen.`,
    })
  }

  if (callerId) {
    const coachCount = await genCount(dayStart, {
      col: 'coach_id',
      val: callerId,
    })
    if (coachCount === null || coachCount >= COACH_DAILY_LIMIT) {
      return json(429, {
        error:
          coachCount === null
            ? BLOCKED_UNCHECKABLE
            : `Tageslimit fuer Report-Generierung erreicht (${COACH_DAILY_LIMIT}). Morgen wieder verfuegbar oder Limit anpassen.`,
      })
    }
  }

  // ── Daten sammeln (service-role) ──────────────────────────────────────────
  const [stuRes, progRes, scrRes, attRes, ivRes] = await Promise.all([
    admin
      .from('students')
      .select('class_level, profiles!profile_id(full_name)')
      .eq('id', sId)
      .single(),
    admin
      .from('student_progress')
      .select('xp_total, streak_days, level')
      .eq('student_id', sId)
      .maybeSingle(),
    admin
      .from('screening_tests')
      .select('subject, result_summary, completed_at')
      .eq('student_id', sId)
      .eq('status', 'completed')
      .order('completed_at', { ascending: false })
      .limit(1),
    admin
      .from('session_students')
      .select('attendance, coaching_sessions!inner(scheduled_at)')
      .eq('student_id', sId)
      .gte('coaching_sessions.scheduled_at', body.period_start)
      .lte('coaching_sessions.scheduled_at', body.period_end),
    admin
      .from('interventions')
      .select('started_at, resolved_at, note')
      .eq('student_id', sId)
      .gte('started_at', body.period_start)
      .lte('started_at', body.period_end),
  ])

  const attendance = (attRes.data ?? []) as { attendance: string }[]
  const facts = {
    schueler: {
      name:
        (stuRes.data as { profiles?: { full_name?: string } } | null)?.profiles
          ?.full_name ?? 'Das Kind',
      klasse: (stuRes.data as { class_level?: number } | null)?.class_level ?? null,
    },
    zeitraum: { von: body.period_start, bis: body.period_end },
    fortschritt: progRes.data ?? null,
    letztes_screening: scrRes.data?.[0] ?? null,
    anwesenheit: {
      gesamt: attendance.length,
      anwesend: attendance.filter((a) => a.attendance === 'present').length,
      abwesend: attendance.filter((a) => a.attendance === 'absent').length,
    },
    eingriffe: ivRes.data ?? [],
    coach_kontext: body.coach_context ?? null,
  }

  // ── Claude aufrufen ───────────────────────────────────────────────────────
  let aiResp: Response
  try {
    aiResp = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': anthropicKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 3000,
        system: [
          {
            type: 'text',
            text: SYSTEM_PROMPT,
            cache_control: { type: 'ephemeral' },
          },
        ],
        output_config: {
          format: { type: 'json_schema', schema: REPORT_SCHEMA },
        },
        messages: [
          {
            role: 'user',
            content:
              'Erzeuge den Elternreport aus diesen Fakten (JSON):\n' +
              JSON.stringify(facts),
          },
        ],
      }),
    })
  } catch (err) {
    const m = err instanceof Error ? err.message : 'Netzwerkfehler'
    return json(502, { error: `LLM nicht erreichbar: ${m}` })
  }

  if (!aiResp.ok) {
    const t = await aiResp.text()
    return json(502, { error: `LLM-Fehler ${aiResp.status}: ${t.slice(0, 300)}` })
  }

  const data = (await aiResp.json()) as {
    content?: { type: string; text?: string }[]
    stop_reason?: string
  }
  if (data.stop_reason === 'refusal') {
    return json(422, { error: 'LLM hat die Generierung abgelehnt' })
  }
  const textBlock = (data.content ?? []).find(
    (b) => b.type === 'text' && typeof b.text === 'string',
  )
  if (!textBlock?.text) {
    return json(502, { error: 'Keine Textantwort vom LLM' })
  }
  let draft: Record<string, string>
  try {
    draft = JSON.parse(textBlock.text)
  } catch {
    return json(502, { error: 'LLM-Antwort war kein gueltiges JSON' })
  }

  // Kosten-Guardrail: NUR erfolgreiche Generierung anrechnen. Log-Fehler
  // bricht die User-Antwort nicht ab (nur console.error).
  try {
    const { error: logErr } = await admin
      .from('parent_report_generations')
      .insert({ coach_id: callerId, student_id: sId, model: MODEL })
    if (logErr) {
      console.error('parent_report_generations log failed:', logErr.message)
    }
  } catch (err) {
    console.error('parent_report_generations log threw:', err)
  }

  return json(200, { draft })
})
