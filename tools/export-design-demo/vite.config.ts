import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'node:path'

// Standalone-Build der /demo/design-Route in EINE HTML-Datei (post-processed).
// Bewusst KEIN BrowserRouter, KEINE Context-Provider — DesignDemo ist
// self-contained und soll als Inspirations-Artefakt fuer den Designer
// per file:// laufen.
export default defineConfig({
  plugins: [react(), tailwindcss()],
  root: __dirname,
  base: './',
  resolve: {
    alias: {
      '@': path.resolve(__dirname, '../../src'),
    },
  },
  build: {
    outDir: path.resolve(__dirname, 'dist'),
    emptyOutDir: true,
    assetsInlineLimit: 100_000_000, // alle Assets inlinen
    cssCodeSplit: false,
    // IIFE statt ESM, damit das inlinete Script auch via file:// laeuft
    // (Module-Scripts werden vom Browser per file:// blockiert).
    rollupOptions: {
      output: {
        format: 'iife',
        inlineDynamicImports: true,
        manualChunks: undefined,
      },
    },
  },
})
