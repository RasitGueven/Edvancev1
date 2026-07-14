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
    // scripts/: der Import-Bau (C08) spiegelt die DB-Vertraege (lsa_parts_valid,
    // lsa_table_valid) — er wird getestet wie Produktivcode, nicht wie ein Skript.
    include: ['src/**/*.test.{ts,tsx}', 'scripts/**/*.test.ts'],
    exclude: [
      'node_modules',
      'dist',
      // Legacy node:test suites — executed via `npm run test:mock`, not vitest.
      'src/lib/mocks/sessionMachine.test.ts',
      'src/pages/mock/session/components/taskEval.test.ts',
    ],
  },
})
