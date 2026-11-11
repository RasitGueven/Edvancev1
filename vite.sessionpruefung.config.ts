import { defineConfig, mergeConfig, type Plugin } from 'vite'
import path from 'node:path'
import basis from './vite.config'

// Ansichtstests „Session-Aufgaben prüfen“ (SP-1): Lib, useAuth und Supabase-Client werden auf Attrappen umgebogen,
// envDir zeigt ins Leere, damit keine .env mit Prod-Zugang geladen wird.
const V = path.resolve(__dirname, 'src/pages/coach/pruefen/bauformen/vorschau')
const ZIELE: [RegExp, string][] = [
  [/src\/lib\/supabase\/bauformPruefung(\.ts)?$/, `${V}/fakeLib.ts`],
  [/src\/lib\/supabase\/client(\.ts)?$/, `${V}/fakeClient.ts`],
  [/src\/hooks\/useAuth(\.ts)?$/, `${V}/fakeAuth.ts`],
]

function attrappen(): Plugin {
  return {
    name: 'sessionpruefung-attrappen',
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
