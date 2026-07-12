// Seedet EINEN Test-Schueler mit bewohntem Hub (XP, Level, beide Streaks).
//
// Voraussetzung:
//   - ENV: SUPABASE_URL (oder VITE_SUPABASE_URL) + SUPABASE_SERVICE_ROLE_KEY
//
// Nutzung:
//   npm run seed:test-student
//   npm run seed:test-student -- --email a@b.de --password geheim123
//
// Vorgehen (keine manuellen auth.users-INSERTs):
//   1. auth-User via Auth-Admin-API (wie Edge Function provision_student, Schritt 1)
//   2. DB-Teil via RPC app_provision_student (service_role-only, Migration 021)
//   3. XP via EIN xp_event -> Trigger apply_xp_event schreibt student_progress
//      (xp_total + level = 1 + xp/500). xp_rules/Trigger bleiben unangetastet.
//   4. Zwei-Streak-Felder (Migration 032) direkt auf student_progress gesetzt
//
// Idempotenz:
//   - auth-User: per E-Mail gesucht, sonst angelegt; Passwort wird immer neu gesetzt
//   - students-Zeile: nur angelegt, wenn fuer das Profil noch keine existiert
//   - XP: das Seed-xp_event traegt reason=SEED_REASON und wird nur eingefuegt,
//     wenn es noch keins gibt -> zweiter Lauf verdoppelt XP nicht
//   - Streaks: absolute Werte (UPDATE, nicht additiv)

import { WebSocket as WsWebSocket } from 'ws'
import { createClient, type SupabaseClient, type User } from '@supabase/supabase-js'

// Node 20 ships no global WebSocket. supabase-js instantiates its Realtime client
// eagerly in createClient(), which throws without one. Polyfill before that call.
if (typeof globalThis.WebSocket === 'undefined') {
  globalThis.WebSocket = WsWebSocket as unknown as typeof globalThis.WebSocket
}

const DEFAULT_EMAIL = 'test.schueler@edvance.invalid'
const DEFAULT_PASSWORD = 'Edvance-Test-2026!'
const SEED_REASON = 'seed:test-student'

// XP im mittleren vierstelligen Bereich. Level folgt der Logik aus
// apply_xp_event (Migration 019/037): level = 1 + floor(xp_total / 500).
const SEED_XP = 4200
const EXPECTED_LEVEL = 1 + Math.floor(SEED_XP / 500) // = 9

// Zwei-Streak-Modell (Migration 032). Der Multiplikator folgt
// calc_presence_multiplier(weeks): >=3 -> 1.10, >=5 -> 1.20, >=8 -> 1.30.
const PRESENCE_STREAK_WEEKS = 6
const PRESENCE_MULTIPLIER = 1.2
const HOME_STREAK_SESSIONS = 12

const STUDENT = {
  full_name: 'Testa Schuelerin',
  class_level: 8,
  school_type: 'Gymnasium',
  school_name: 'Testgymnasium Koeln',
  subjects: ['Mathematik'],
}

function getArg(name: string): string | undefined {
  const i = process.argv.indexOf(name)
  return i >= 0 ? process.argv[i + 1] : undefined
}

// Montag der laufenden Woche, 00:00 UTC – Ankerdatum des Praesenz-Streaks.
function currentWeekStart(): string {
  const now = new Date()
  const day = (now.getUTCDay() + 6) % 7 // Mo = 0
  const monday = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - day),
  )
  return monday.toISOString()
}

async function findAuthUser(sb: SupabaseClient, email: string): Promise<User | null> {
  const target = email.toLowerCase()
  for (let page = 1; page <= 20; page++) {
    const { data, error } = await sb.auth.admin.listUsers({ page, perPage: 200 })
    if (error) throw new Error(`auth.listUsers: ${error.message}`)
    const hit = data.users.find((u) => (u.email ?? '').toLowerCase() === target)
    if (hit) return hit
    if (data.users.length < 200) return null
  }
  return null
}

async function ensureAuthUser(
  sb: SupabaseClient,
  email: string,
  password: string,
): Promise<{ uid: string; created: boolean }> {
  const existing = await findAuthUser(sb, email)
  if (existing) {
    // Passwort neu setzen, damit die dokumentierten Zugangsdaten immer gelten.
    const { error } = await sb.auth.admin.updateUserById(existing.id, {
      password,
      email_confirm: true,
    })
    if (error) throw new Error(`auth.updateUserById: ${error.message}`)
    return { uid: existing.id, created: false }
  }

  const { data, error } = await sb.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  })
  if (error || !data.user) {
    throw new Error(`auth.createUser: ${error?.message ?? 'unbekannt'}`)
  }
  return { uid: data.user.id, created: true }
}

async function ensureStudentRow(sb: SupabaseClient, uid: string, email: string): Promise<string> {
  const { data: existing, error: selErr } = await sb
    .from('students')
    .select('id')
    .eq('profile_id', uid)
    .maybeSingle()
  if (selErr) throw new Error(`students.select: ${selErr.message}`)
  if (existing) return existing.id as string

  // app_provision_student legt profiles + students + student_subjects atomar an.
  const { data, error } = await sb.rpc('app_provision_student', {
    p_student_uid: uid,
    p_student_email: email,
    p_parent_uid: null,
    p_parent_email: null,
    p_full_name: STUDENT.full_name,
    p_class_level: STUDENT.class_level,
    p_school_type: STUDENT.school_type,
    p_school_name: STUDENT.school_name,
    p_subjects: STUDENT.subjects,
    p_coach_id: null,
    p_tier_id: null,
    p_lead_id: null,
  })
  if (error) throw new Error(`app_provision_student: ${error.message}`)
  return data as string
}

async function ensureXp(sb: SupabaseClient, studentId: string): Promise<boolean> {
  const { data: seeded, error: selErr } = await sb
    .from('xp_events')
    .select('id')
    .eq('student_id', studentId)
    .eq('reason', SEED_REASON)
    .maybeSingle()
  if (selErr) throw new Error(`xp_events.select: ${selErr.message}`)
  if (seeded) return false

  const { error } = await sb
    .from('xp_events')
    .insert({ student_id: studentId, xp: SEED_XP, reason: SEED_REASON, task_id: null })
  if (error) throw new Error(`xp_events.insert: ${error.message}`)
  return true
}

async function setStreaks(sb: SupabaseClient, studentId: string): Promise<void> {
  const { error } = await sb
    .from('student_progress')
    .update({
      last_activity: new Date().toISOString(),
      presence_streak_weeks: PRESENCE_STREAK_WEEKS,
      presence_streak_last_week_start: currentWeekStart(),
      presence_streak_multiplier: PRESENCE_MULTIPLIER,
      home_streak_sessions: HOME_STREAK_SESSIONS,
      home_streak_last_completed_at: new Date().toISOString(),
    })
    .eq('student_id', studentId)
  if (error) throw new Error(`student_progress.update: ${error.message}`)
}

async function main(): Promise<void> {
  const email = getArg('--email') ?? DEFAULT_EMAIL
  const password = getArg('--password') ?? DEFAULT_PASSWORD
  const url = process.env.SUPABASE_URL ?? process.env.VITE_SUPABASE_URL
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY
  if (!url || !key) {
    console.error('Fehlende ENV: SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY.')
    process.exit(1)
  }
  const sb = createClient(url, key, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  const { uid, created } = await ensureAuthUser(sb, email, password)
  console.log(`auth-User:        ${created ? 'angelegt' : 'vorhanden (Passwort gesetzt)'}`)

  const studentId = await ensureStudentRow(sb, uid, email)
  console.log(`students-Zeile:   ${studentId}`)

  const awarded = await ensureXp(sb, studentId)
  console.log(`XP:               ${awarded ? `+${SEED_XP} vergeben` : 'bereits geseedet (kein zweites Event)'}`)

  await setStreaks(sb, studentId)

  const { data: progress, error } = await sb
    .from('student_progress')
    .select('xp_total, level, presence_streak_weeks, home_streak_sessions')
    .eq('student_id', studentId)
    .maybeSingle()
  if (error) throw new Error(`student_progress.select: ${error.message}`)

  console.log('\n=== Test-Schueler ===')
  console.log(`  E-Mail:     ${email}`)
  console.log(`  Passwort:   ${password}`)
  console.log(`  student_id: ${studentId}`)
  console.log('\n=== Hub-Zustand ===')
  console.log(`  XP:              ${progress?.xp_total} (erwartet: ${SEED_XP})`)
  console.log(`  Level:           ${progress?.level} (erwartet: ${EXPECTED_LEVEL})`)
  console.log(`  Praesenz-Streak: ${progress?.presence_streak_weeks} Wochen (x${PRESENCE_MULTIPLIER})`)
  console.log(`  Heim-Streak:     ${progress?.home_streak_sessions} Sessions`)
}

main().catch((err) => {
  console.error('Seed fehlgeschlagen:', err instanceof Error ? err.message : err)
  process.exit(1)
})
