# Export `/demo/design` als einzelne HTML

Standalone-Build der `DesignDemo`-Route in eine self-contained HTML-Datei,
die der Designer per Doppelklick (file://) interaktiv öffnen kann.

## Was raus kommt

`dist/edvance-design-demo.html` — ein File mit allem inline (JS + CSS).
Tab-Wechsel, Antwort-Submit, Toasts etc. funktionieren. Fonts kommen
weiterhin von Google Fonts (Online-Verbindung empfohlen).

## Bauen

```bash
npx vite build --config tools/export-design-demo/vite.config.ts
node tools/export-design-demo/inline.mjs
# dist/edvance-design-demo.html ist fertig
```

## Architektur-Notizen

- **Eigener Vite-Build:** `main.tsx` mounted `DesignDemo` direkt ohne
  `BrowserRouter`, `AuthProvider`, `ThemeProvider` — die Demo ist
  self-contained.
- **IIFE statt ESM:** `output.format: 'iife'`, damit das inlinete Script
  via `file://` läuft (Module-Scripts werden vom Browser per `file://`
  per CORS blockiert).
- **CSS inline im `<head>`**, Script vor `</body>` (sonst läuft die IIFE
  bevor `<div id="root">` im DOM ist → React error #299).
- **`String.replace`-Falle:** JS interpretiert `$&`/`$1` im Replacement-
  String — das React-Bundle enthält solche Patterns. `inline.mjs` nutzt
  daher die Callback-Variante.
