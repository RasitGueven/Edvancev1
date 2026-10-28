import './mathjaxVersion'
import { mathjax } from 'mathjax-full/js/mathjax.js'
import { TeX } from 'mathjax-full/js/input/tex.js'
import { SVG } from 'mathjax-full/js/output/svg.js'
import { liteAdaptor } from 'mathjax-full/js/adaptors/liteAdaptor.js'
import { RegisterHTMLHandler } from 'mathjax-full/js/handlers/html.js'
import { AllPackages } from 'mathjax-full/js/input/tex/AllPackages.js'

/**
 * Formeln wie in E1.4 (tools/formeln-svg.mjs): mathjax-full, TeX → SVG, fontCache none, Farbe currentColor.
 * Die Farbe kommt damit aus der Welt (CSS color). Ergebnisse werden je TeX-Text zwischengespeichert.
 */
let dokument: ReturnType<typeof mathjax.document> | null = null
let adaptor: ReturnType<typeof liteAdaptor> | null = null
const cache = new Map<string, string>()

export function texZuSvg(tex: string): string {
  const fertig = cache.get(tex)
  if (fertig) return fertig
  if (!dokument || !adaptor) {
    adaptor = liteAdaptor()
    RegisterHTMLHandler(adaptor)
    dokument = mathjax.document('', { InputJax: new TeX({ packages: AllPackages }), OutputJax: new SVG({ fontCache: 'none' }) })
  }
  const svg = adaptor.innerHTML(dokument.convert(tex, { display: false }))
  cache.set(tex, svg)
  return svg
}

export function Formel({ tex, gross }: { tex: string; gross?: boolean }): JSX.Element {
  // MathJax-Ausgabe aus eigenen Bildparametern (kein Fremdinhalt).
  return <span className={gross ? 'sv-formel sv-formel-gross' : 'sv-formel'} dangerouslySetInnerHTML={{ __html: texZuSvg(tex) }} />
}
