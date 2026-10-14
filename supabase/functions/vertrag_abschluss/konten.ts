// Konten beim Vertragsabschluss (K1b, Entscheidung Rasit 14.10.2026):
// Es entsteht genau EIN Auth-Konto, das des Kindes. Eltern bekommen kein Konto;
// alle Mails an Eltern gehen an vertraege.eltern_email (mail_senden).
//
// Herausgezogen aus index.ts, damit der Test ohne Netz pruefen kann, welche
// Konten angelegt werden und was an vertrag_abschliessen geht.

import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

/**
 * Passwort des Schuelerkontos: 48 Zeichen aus dem CSPRNG, nirgends angezeigt,
 * nirgends gespeichert. Es gibt bewusst kein Eingabefeld dafuer.
 *
 * Vor Ort meldet sich das Kind nicht an — es bekommt einen Platz zugewiesen
 * (platz_assign, das Tablet ist mit dem Platz-Konto angemeldet). Und zuhause
 * fuehrt der Weg spaeter ueber den Zugangscode, nicht ueber ein Passwort, das
 * am Empfang vergeben und weitergereicht wird. Ein Passwort, das niemand
 * braucht, soll auch niemand kennen.
 */
export function randomPassword(): string {
  const bytes = new Uint8Array(36)
  crypto.getRandomValues(bytes)
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')
}

export type Schuelerkonto = { uid: string; email: string }

/**
 * Das Schuelerkonto anlegen. Das Kind hat keine eigene Adresse — dieselbe
 * Konvention wie frueher in provision_student. Bestaetigt, damit keine Mail entsteht.
 */
export async function schuelerkontoAnlegen(
  admin: Pick<SupabaseClient, 'auth'>,
): Promise<Schuelerkonto | { fehler: string }> {
  const email = `student.${crypto.randomUUID()}@edvance.invalid`
  const { data, error } = await admin.auth.admin.createUser({
    email,
    password: randomPassword(),
    email_confirm: true,
  })
  if (error || !data.user) return { fehler: `Schueler-Account: ${error?.message ?? 'unbekannt'}` }
  return { uid: data.user.id, email }
}

export type AbschlussBody = {
  vertrag_id: string
  weg: 'vor_ort' | 'papier'
  zustimmungen?: { schluessel: string; version: string; akzeptiert_at?: string }[]
  signatur_vertrag?: string | null
  signatur_sepa?: string | null
  unterschrieben_am?: string | null
  eingang_datum?: string | null
  scan_pfad?: string | null
  abweichung_vermerk?: string | null
  tier_id?: string | null
  laufzeit_monate?: number | null
  vertragsbeginn?: string | null
}

/** Die Parameter fuer vertrag_abschliessen. Eltern-Parameter immer null: kein Eltern-Konto, keine parent_student-Zeile. */
export function abschlussParameter(body: AbschlussBody, konto: Schuelerkonto | null): Record<string, unknown> {
  return {
    p_vertrag_id: body.vertrag_id,
    p_weg: body.weg,
    p_zustimmungen: body.zustimmungen ?? [],
    p_signatur_vertrag: body.signatur_vertrag ?? null,
    p_signatur_sepa: body.signatur_sepa ?? null,
    p_unterschrieben_am: body.unterschrieben_am ?? null,
    p_eingang_datum: body.eingang_datum ?? null,
    p_scan_pfad: body.scan_pfad ?? null,
    p_abweichung_vermerk: body.abweichung_vermerk ?? null,
    p_tier_id: body.tier_id ?? null,
    p_laufzeit_monate: body.laufzeit_monate ?? null,
    p_vertragsbeginn: body.vertragsbeginn ?? null,
    p_student_uid: konto?.uid ?? null,
    p_student_email: konto?.email ?? null,
    p_parent_uid: null,
    p_parent_email: null,
  }
}
