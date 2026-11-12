import { defineConfig, mergeConfig, type Plugin } from 'vite'
import path from 'node:path'
import basis from './vite.config'

// Ansichtstests „Archiv“ (MSA-1 M3): Supabase-Client und useAuth werden auf Attrappen umgebogen, envDir zeigt ins
// Leere, damit keine .env mit Prod-Zugang geladen wird. Die Lib bleibt echt: die Filter auf archiviert_am laufen mit.
const V = path.resolve(__dirname, 'src/pages/admin/archiv/vorschau')
const ZIELE: [RegExp, string][] = [
  [/src\/lib\/supabase\/client(\.ts)?$/, `${V}/fakeClient.ts`],
  [/src\/hooks\/useAuth(\.ts)?$/, `${V}/fakeAuth.ts`],
]

function attrappen(): Plugin {
  return {
    name: 'archiv-attrappen',
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
