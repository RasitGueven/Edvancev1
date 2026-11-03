// Wer versenden darf: nur ein angemeldeter Admin (fail-closed). Ausgelagert aus
// index.ts, damit die Tests (lsa_report_test.ts) den 401/403-Weg pruefen
// koennen, ohne Deno.serve zu starten.

import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

export type Ablehnung = { status: 401 | 403; error: string }

/** null = Admin; sonst die Antwort, mit der die Funktion abbricht. */
export async function nurAdmin(admin: SupabaseClient, caller: SupabaseClient): Promise<Ablehnung | null> {
  const { data: userData, error: userErr } = await caller.auth.getUser()
  if (userErr || !userData.user) return { status: 401, error: 'Nicht authentifiziert' }
  const { data: prof } = await admin
    .from('profiles')
    .select('role')
    .eq('id', userData.user.id)
    .maybeSingle()
  if (prof?.role !== 'admin') return { status: 403, error: 'Nur Admin darf versenden' }
  return null
}
