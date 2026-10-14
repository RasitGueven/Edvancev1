// Edge Function: provision_coach — stillgelegt (Konto K1, 14.10.2026).
//
// Coaches werden per Mail eingeladen und vergeben ihr Passwort selbst:
// Edge Function coach_einladen. Ein Admin legt kein Passwort mehr fest.
//
// Aufrufer vor der Stilllegung (Bestandsaufnahme im PR K1): nur
// src/pages/admin/CoachesPage.tsx ueber src/lib/supabase/provisionCoach.ts.
// Keine Tests, Werkzeuge, Skripte oder Seeds. Beide Stellen sind mit K1 auf
// coach_einladen umgestellt.
//
// Die Function bleibt deployt und antwortet 410, damit ein vergessener
// Aufrufer eine klare Meldung bekommt statt eines stillen Kontos mit
// Admin-Passwort.
//
// Deploy: npx supabase functions deploy provision_coach --project-ref ztcppihxqcphlqaguhma

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

Deno.serve((req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  return new Response(
    JSON.stringify({
      error: 'provision_coach ist stillgelegt. Coaches werden ueber coach_einladen per Mail eingeladen.',
      ersatz: 'coach_einladen',
    }),
    { status: 410, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
  )
})
