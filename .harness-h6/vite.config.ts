import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'node:path'

const ROOT = path.resolve(__dirname, '..')
const CLIENT = path.join(ROOT, 'src/lib/supabase/client.ts')
const FAKE = path.join(__dirname, 'fakeClient.ts')

export default defineConfig({
  root: ROOT,
  envDir: __dirname,
  plugins: [
    {
      name: 'fake-supabase',
      enforce: 'pre',
      async resolveId(source, importer, opts) {
        if (importer === FAKE) return null
        const r = await this.resolve(source, importer, { ...opts, skipSelf: true })
        if (r && r.id === CLIENT) return FAKE
        return null
      },
    },
    react(),
    tailwindcss(),
  ],
  resolve: { alias: { '@': path.join(ROOT, 'src') } },
  server: { port: 5206, strictPort: true },
})
