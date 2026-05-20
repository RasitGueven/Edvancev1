// Liest dist/index.html + assets, inlinet <script src=...> und
// <link rel="stylesheet"> direkt — Ergebnis: eine einzige HTML-Datei.
import { readFile, writeFile, readdir } from 'node:fs/promises'
import path from 'node:path'

const DIST = path.resolve(import.meta.dirname, 'dist')
const ASSETS = path.join(DIST, 'assets')
const OUT = path.join(DIST, 'edvance-design-demo.html')

const html = await readFile(path.join(DIST, 'index.html'), 'utf8')
const files = await readdir(ASSETS)

const read = async (name) =>
  readFile(path.join(ASSETS, name), 'utf8')

const jsFile = files.find((f) => f.endsWith('.js'))
const cssFile = files.find((f) => f.endsWith('.css'))
if (!jsFile || !cssFile) {
  console.error('Expected one .js + one .css in dist/assets/')
  process.exit(1)
}

const rawJs = await read(jsFile)
const rawCss = await read(cssFile)
// </script> in JS-Strings/Regex bricht das inline-Script-Tag — escapen.
const js = rawJs.replaceAll('</script>', '<\\/script>')
const css = rawCss.replaceAll('</style>', '<\\/style>')

let out = html
// Callback-Form, weil JS .replace() $&/$1 im String-Replacement interpretiert
// und das React-Bundle solche Patterns enthaelt → wuerde die externe Script-URL
// quer durch den Code injizieren. Mit () => "..." passiert das nicht.
// CSS bleibt im <head> (inline-Style).
out = out.replace(
  /<link[^>]*rel="stylesheet"[^>]*href="[^"]*\.css"[^>]*\/?>/,
  () => `<style>${css}</style>`,
)
// Script aus <head> entfernen und ans Ende von </body> verschieben — sonst
// laeuft die IIFE bevor <div id="root"> im DOM ist (React error #299).
out = out.replace(/<script[^>]*src="[^"]*\.js"[^>]*><\/script>/, () => '')
out = out.replace(
  '</body>',
  () => `<script>${js}</script>\n</body>`,
)

await writeFile(OUT, out, 'utf8')
const kb = (out.length / 1024).toFixed(1)
console.log(`✓ ${OUT} (${kb} KB)`)
