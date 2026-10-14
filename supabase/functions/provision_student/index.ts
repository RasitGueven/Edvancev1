// Edge Function: provision_student — stillgelegt (Konto K1, Entscheidung Rasit 14.10.2026).
//
// Frueher: Lead -> Schueler-Konto, Eltern per inviteUserByEmail. Heute legt
// der Vertragsabschluss (vertrag_abschluss) Schueler- und Elternkonto an,
// ohne Auth-Mail. Mit dem Send Email Hook (auth_mail) haette eine Einladung
// von hier Eltern die Mitarbeiter-Einladung geschickt.
//
// Aufrufer vor der Stilllegung (Bestandsaufnahme K1): keiner in src/,
// scripts/, tools/ oder supabase/tests/. scripts/seed-test-student.ts ruft
// nur die RPC app_provision_student direkt, nicht diese Function; die RPC
// bleibt unveraendert.
//
// Die Function bleibt deployt und antwortet 410, damit ein vergessener
// Aufrufer eine klare Meldung bekommt.
//
// Deploy: npx supabase functions deploy provision_student --project-ref ztcppihxqcphlqaguhma

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

Deno.serve((req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  return new Response(
    JSON.stringify({
      error: 'provision_student ist stillgelegt. Konten entstehen beim Vertragsabschluss (vertrag_abschluss).',
      ersatz: 'vertrag_abschluss',
    }),
    { status: 410, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
  )
})
