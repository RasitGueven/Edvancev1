import js from '@eslint/js'
import tseslint from 'typescript-eslint'
import reactHooks from 'eslint-plugin-react-hooks'
import globals from 'globals'

// supabase.rpc / .from / .schema ungebunden in eine Variable gezogen — direkt
// oder hinter bis zu zwei Casts (`as unknown as X`), per Zuweisung oder per
// Destrukturierung. `supabase.rpc.bind(supabase)` trifft keiner der Selektoren.
const SB_METHOD = "MemberExpression[object.name='supabase'][property.name=/^(rpc|from|schema)$/]"
const CAST = ':matches(TSAsExpression, TSSatisfiesExpression, TSNonNullExpression)'
const unboundSupabaseMethod = [
  `VariableDeclarator > ${SB_METHOD}.init`,
  `VariableDeclarator > ${CAST}.init > ${SB_METHOD}.expression`,
  `VariableDeclarator > ${CAST}.init > ${CAST}.expression > ${SB_METHOD}.expression`,
  `AssignmentExpression > ${SB_METHOD}.right`,
  `AssignmentExpression > ${CAST}.right > ${SB_METHOD}.expression`,
  `AssignmentExpression > ${CAST}.right > ${CAST}.expression > ${SB_METHOD}.expression`,
  "VariableDeclarator[init.name='supabase'] > ObjectPattern > Property[key.name=/^(rpc|from|schema)$/]",
].map((selector) => ({
  selector,
  message:
    'supabase-Methode ohne this-Bindung: supabase.<methode>.bind(supabase) verwenden oder direkt supabase.<methode>(…) aufrufen.',
}))

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
      // `const rpc = supabase.rpc as …; rpc('…')` verliert `this` — supabase-js
      // wirft dann "Cannot read properties of undefined (reading 'rest')", bevor
      // eine Anfrage rausgeht. Wer die Methode in eine Variable zieht, bindet sie.
      'no-restricted-syntax': ['error', ...unboundSupabaseMethod],
    },
  },
)
