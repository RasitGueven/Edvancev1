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
    include: ['src/**/*.test.{ts,tsx}'],
    exclude: [
      'node_modules',
      'dist',
      // Legacy node:test suites — executed via `npm run test:mock`, not vitest.
      'src/lib/mocks/sessionMachine.test.ts',
      'src/pages/mock/session/components/taskEval.test.ts',
      'src/lib/answer/evaluators.test.ts',
      'src/components/edvance/tasks/answer/answerState.test.ts',
    ],
  },
})
