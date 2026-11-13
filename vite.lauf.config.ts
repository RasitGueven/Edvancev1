import { defineConfig, mergeConfig, type Plugin } from 'vite'
import path from 'node:path'
import basis from './vite.config'

// Ansichtstests „Lauf mit Prüfziel“ (IU-1b): Lib-Aufrufe der Prüfung, Auth und Kinderansicht-Vorschau werden auf
// Attrappen umgebogen, envDir zeigt ins Leere (keine .env mit Prod-Zugang). Seiten und Rechnungen bleiben echt.
const V = path.resolve(__dirname, 'src/pages/coach/pruefen/vorschau-lauf')
const ZIELE: [RegExp, string][] = [
  [/src\/lib\/supabase\/pruefung(\.ts)?$/, `${V}/fakePruefung.ts`],
  [/src\/lib\/supabase\/lsaAbdeckung(\.ts)?$/, `${V}/fakeAbdeckung.ts`],
  [/src\/lib\/supabase\/taskPreview(\.ts)?$/, `${V}/fakePreview.ts`],
  [/src\/hooks\/useAuth(\.ts)?$/, `${V}/fakeAuth.ts`],
]

function attrappen(): Plugin {
  return {
    name: 'lauf-attrappen',
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
