import { defineConfig } from 'vitest/config'
import path from 'node:path'

// Vitest runs the unit/component suite. The legacy node:test suites (run via
// `npm run test:mock`) are excluded here so both runners coexist.
export default defineConfig({
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['src/test/setup.ts'],
    // Mehrere Agenten lassen die Suite auf derselben Maschine (10 Kerne, 7,7 GB) parallel laufen.
    // Mit dem Standard (Kerne - 1 = 9 jsdom-Forks, je ~200 MB) liefen drei gleichzeitige Läufe in
    // den Swap; Forks starteten nicht mehr, Tests liefen in das 5-s-Limit. 4 Forks: 48 s statt 45 s,
    // halber Speicher (Messung in docs/offene-punkte-v1.md).
    maxWorkers: 4,
    // Dummy-Env, NICHT als Ersatz fuer die Mocks: Fehlt irgendwo ein Wrapper-Mock,
    // soll createClient() in supabase/client.ts nicht schon beim IMPORT sterben und
    // den Worker mitreissen (das faerbt fremde Suiten rot, an der falschen Stelle).
    // Mit gesetzter — aber unerreichbarer — URL bleibt der Fehler lokal: erst der
    // konkrete RPC-Aufruf scheitert (connection refused), dort wo er hingehoert.
    env: {
      VITE_SUPABASE_URL: 'http://localhost:54321',
      VITE_SUPABASE_ANON_KEY: 'test-anon-key',
    },
    // scripts/: der Import-Bau (C08) spiegelt die DB-Vertraege (lsa_parts_valid,
    // lsa_table_valid) — er wird getestet wie Produktivcode, nicht wie ein Skript.
    // tests/: Suiten, die keinen Ort im Produktivbaum haben — die
    // Figuren-Generatoren (A19) liegen unter scripts/figures/, ihre Tests
    // laut Spec unter tests/.
    include: ['src/**/*.test.{ts,tsx}', 'scripts/**/*.test.ts', 'tests/**/*.test.ts'],
    exclude: [
      'node_modules',
      'dist',
      // Legacy node:test suites — executed via `npm run test:mock`, not vitest.
      'src/lib/mocks/sessionMachine.test.ts',
      'src/pages/mock/session/components/taskEval.test.ts',
    ],
  },
})
