import { defineConfig, mergeConfig, type Plugin } from 'vite'
import path from 'node:path'
import basis from './vite.config'

// Ansichtstests „Gezielt prüfen mit Prüfziel“ (IU-1 U3): der Supabase-Client wird auf eine Attrappe umgebogen, envDir zeigt ins
// Leere, damit keine .env mit Prod-Zugang geladen wird. Lib und Seite bleiben echt.
const V = path.resolve(__dirname, 'src/pages/coach/pruefen/vorschau-ziel')
const ZIELE: [RegExp, string][] = [
  [/src\/lib\/supabase\/client(\.ts)?$/, `${V}/fakeClient.ts`],
]

function attrappen(): Plugin {
  return {
    name: 'gezielt-attrappen',
    enforce: 'pre',
    async resolveId(quelle, importer, opts) {
      if (!importer || importer.startsWith(V)) return null
      const r = await this.resolve(quelle, importer, { ...opts, skipSelf: true })
      const pfad = r?.id ?? quelle
      for (const [muster, ziel] of ZIELE) if (muster.test(pfad.replace(/\?.*$/, ''))) return ziel
      return null
    },
  }
}

export default mergeConfig(basis, defineConfig({ plugins: [attrappen()], envDir: V }))
