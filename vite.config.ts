import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'node:path'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  // LR-2: Das Mail-PDF lädt diese Pakete erst beim Senden (und in der Vorschau
  // per import im Test). Ohne Vorab-Bündelung lädt der Dev-Server die Seite
  // beim ersten Aufruf neu, mitten im laufenden Test.
  optimizeDeps: { include: ['modern-screenshot', 'jspdf'] },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
