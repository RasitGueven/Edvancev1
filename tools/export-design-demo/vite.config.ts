import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'node:path'

// Standalone-Build der /demo/design-Route in EINE HTML-Datei.
// WICHTIG: root = Projekt-Wurzel, damit Tailwind v4 die Utility-Klassen aus
// src/ scannt. Nur die HTML-Entry-Datei wird gegen tools/export-design-demo/
// gesetzt. KEIN BrowserRouter, KEINE Context-Provider — DesignDemo ist
// self-contained und soll als Inspirations-Artefakt fuer den Designer per
// file:// laufen.
const ROOT = path.resolve(__dirname, '../..')
const ENTRY_HTML = path.resolve(__dirname, 'index.html')

export default defineConfig({
  plugins: [react(), tailwindcss()],
  root: ROOT,
  base: './',
  resolve: {
    alias: {
      '@': path.resolve(ROOT, 'src'),
    },
  },
  build: {
    outDir: path.resolve(__dirname, 'dist'),
    emptyOutDir: true,
    assetsInlineLimit: 100_000_000,
    cssCodeSplit: false,
    // IIFE statt ESM, damit das inlinete Script auch via file:// laeuft
    // (Module-Scripts werden vom Browser per file:// blockiert).
    rollupOptions: {
      input: ENTRY_HTML,
      output: {
        format: 'iife',
        inlineDynamicImports: true,
        manualChunks: undefined,
      },
    },
  },
})
