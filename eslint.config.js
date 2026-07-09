import js from '@eslint/js'
import tseslint from 'typescript-eslint'
import reactHooks from 'eslint-plugin-react-hooks'
import globals from 'globals'

// Minimal, non-stylistic ESLint setup (P00): typescript-eslint recommended plus
// react-hooks correctness rules. No style rules — per prompts/infra/P00-autonomy-foundation.md.
export default tseslint.config(
  {
    ignores: ['dist', 'node_modules', 'dist-ssr', 'coverage', 'playwright-report'],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ['**/*.{ts,tsx}'],
    plugins: {
      'react-hooks': reactHooks,
    },
    // Existing code predates ESLint and carries eslint-disable directives for
    // react-hooks/exhaustive-deps. Don't re-flag those as "unused" here.
    linterOptions: {
      reportUnusedDisableDirectives: 'off',
    },
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
      globals: { ...globals.browser, ...globals.node },
    },
    rules: {
      // Classic react-hooks correctness rules only (plugin registered so existing
      // eslint-disable directives resolve). No broader preset — avoids forcing
      // effect refactors on the existing codebase in this foundation run.
      'react-hooks/rules-of-hooks': 'error',
      // Legacy tech-debt: existing effects don't satisfy exhaustive-deps and
      // fixing them means changing product behavior — out of scope for P00.
      // Kept off (not removed) so it can be re-enabled deliberately later.
      'react-hooks/exhaustive-deps': 'off',
      // Standard convention: underscore-prefixed identifiers are intentional-ignore.
      '@typescript-eslint/no-unused-vars': [
        'error',
        {
          argsIgnorePattern: '^_',
          varsIgnorePattern: '^_',
          caughtErrorsIgnorePattern: '^_',
        },
      ],
    },
  },
)
