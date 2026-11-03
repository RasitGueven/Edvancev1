// Der Eltern-Bericht als PDF aus dem fertigen Bogen im Browser (Bauauftrag LR-2,
// Entscheidungen 1–3).
//
// Warum im Browser: Der Bogen misst nach dem Schriftladen (Namensregel, Stufen
// auf Seite 4). Ein Nachbau auf dem Server wiche davon ab. Jede `.eb-seite`
// wird deshalb in ihrer natürlichen Größe (595,28 × 841,89 pt) als Bild
// gerendert und auf eine A4-Seite gelegt. Die Einpassung am Bildschirm
// (transform an der Hülle, BerichtAnsicht) gilt dabei nicht: Die Seite wird mit
// ihren Layoutmaßen geklont, nicht mit den skalierten. Der Text im PDF ist
// nicht markierbar; das ist akzeptiert.
//
// modern-screenshot statt html-to-image: Es bettet die Schriften auch aus
// fremden Stylesheets ein (Google Fonts: Literata, Schibsted Grotesk), wo
// html-to-image an den cssRules eines fremden Ursprungs scheitert.
//
// Grenzen (Entscheidung 3): höchstens 2,5 MB, mindestens 200 dpi effektiv.
// Zuerst sinkt die JPEG-Qualität, dann die Auflösung bis zur Untergrenze. Passt
// es dann noch nicht, gibt es PdfZuGross und es wird nichts verschickt.

import { jsPDF } from 'jspdf'
import { domToCanvas } from 'modern-screenshot'

import { bogenBereit } from '@/pages/admin/reportDruck'

/** Entscheidung 3, dezimal: Graph nimmt Anhänge inline bis etwa 3 MB (Base64 legt ein Drittel drauf). */
export const PDF_MAX_BYTES = 2_500_000
/** Von oben nach unten probiert; der letzte Wert ist die Untergrenze. */
export const PDF_DPI = [300, 250, 200] as const
export const PDF_QUALITAET = [0.92, 0.85, 0.75, 0.65] as const

// A4 in pt, wie .eb-seite (595,28 × 841,89 pt).
const A4_PT = { b: 595.28, h: 841.89 }
// CSS-px sind 1/96 Zoll: scale = dpi / 96.
const CSS_DPI = 96

export class PdfZuGross extends Error {
  constructor(readonly bytes: number) {
    super(`PDF too large: ${bytes} bytes`)
    this.name = 'PdfZuGross'
  }
}

/** Die Schriften des Bogens ließen sich nicht einbetten; mit Ersatzschrift bräche der Text anders um. */
export class PdfOhneSchrift extends Error {
  constructor() {
    super('Report fonts could not be embedded')
    this.name = 'PdfOhneSchrift'
  }
}

export class PdfOhneSeiten extends Error {
  constructor() {
    super('No .eb-seite found')
    this.name = 'PdfOhneSeiten'
  }
}

/**
 * Die @font-face-Regeln der Google-Fonts-Stylesheets als Text. Von selbst liest
 * modern-screenshot die Regeln eines fremden Ursprungs nicht (cssRules wirft),
 * und der Bogen fiele auf Ersatzschriften zurück, mit anderen Umbrüchen. Google
 * liefert das CSS mit CORS aus. Nur die Untermengen latin und latin-ext: Mehr
 * kommt im Bogen nicht vor, und jede weitere würde mitgeladen.
 */
async function schriftCss(): Promise<string | undefined> {
  const links = [...document.querySelectorAll<HTMLLinkElement>('link[rel="stylesheet"][href*="fonts.googleapis.com"]')]
  const texte = await Promise.all(
    links.map((l) =>
      fetch(l.href)
        .then((r) => (r.ok ? r.text() : ''))
        .catch(() => ''),
    ),
  )
  const css = texte
    .join('\n')
    .split(/(?=\/\*\s*[\w-]+\s*\*\/)/)
    .filter((block) => /^\/\*\s*latin(-ext)?\s*\*\//.test(block.trim()))
    .join('\n')
  if (links.length === 0) return undefined
  // Ohne die Schriften kein PDF: lieber eine klare Meldung als ein Bericht mit anderen Umbrüchen.
  if (!/font-family:\s*'Literata'/.test(css) || !/font-family:\s*'Schibsted Grotesk'/.test(css)) throw new PdfOhneSchrift()
  // Als data-URL: Das Bild entsteht aus einem SVG, und ein SVG als Bild lädt
  // nichts von außen nach. modern-screenshot bettet die Adressen aus cssText
  // nicht selbst ein.
  const adressen = [...new Set([...css.matchAll(/url\((https:[^)]+)\)/g)].map((m) => m[1]))]
  const daten = await Promise.all(adressen.map(alsDatenUrl))
  if (daten.some((d) => !d.startsWith('data:'))) throw new PdfOhneSchrift()
  return adressen.reduce((text, adresse, i) => text.replaceAll(adresse, daten[i]), css)
}

async function alsDatenUrl(adresse: string): Promise<string> {
  const antwort = await fetch(adresse).catch(() => null)
  if (!antwort?.ok) return adresse
  const bytes = new Uint8Array(await antwort.arrayBuffer())
  let roh = ''
  for (let i = 0; i < bytes.length; i += 0x8000) roh += String.fromCharCode(...bytes.subarray(i, i + 0x8000))
  return `data:${antwort.headers.get('content-type') ?? 'font/woff2'};base64,${btoa(roh)}`
}

async function jpeg(canvas: HTMLCanvasElement, qualitaet: number): Promise<Uint8Array> {
  const blob = await new Promise<Blob | null>((fertig) => canvas.toBlob(fertig, 'image/jpeg', qualitaet))
  if (!blob) throw new Error('JPEG encoding failed')
  return new Uint8Array(await blob.arrayBuffer())
}

/**
 * Alle Seiten in einer Auflösung, je Seite gleich in allen Qualitäten kodiert.
 * Die Leinwand wird danach verworfen: Fünf Seiten zu 300 dpi gleichzeitig
 * wären auf dem iPad zu viel Speicher.
 */
async function seitenBilder(seiten: HTMLElement[], dpi: number, schriften: string | undefined): Promise<Uint8Array[][]> {
  const raus: Uint8Array[][] = []
  for (const seite of seiten) {
    const hintergrund = getComputedStyle(seite).backgroundColor
    const canvas = await domToCanvas(seite, {
      scale: dpi / CSS_DPI,
      width: seite.offsetWidth,
      height: seite.offsetHeight,
      // JPEG kennt keine Transparenz; der Schatten am Bildschirm gehört nicht aufs Papier.
      backgroundColor: hintergrund === 'rgba(0, 0, 0, 0)' ? 'white' : hintergrund,
      style: { boxShadow: 'none', margin: '0' },
      ...(schriften ? { font: { cssText: schriften } } : {}),
    })
    raus.push(await Promise.all(PDF_QUALITAET.map((q) => jpeg(canvas, q))))
    canvas.width = 0
    canvas.height = 0
  }
  return raus
}

function pdfAus(bilder: Uint8Array[], titel: string): Blob {
  const doc = new jsPDF({ unit: 'pt', format: 'a4', orientation: 'portrait', compress: true })
  doc.setProperties({ title: titel })
  bilder.forEach((bild, i) => {
    if (i > 0) doc.addPage('a4', 'portrait')
    doc.addImage(bild, 'JPEG', 0, 0, A4_PT.b, A4_PT.h, undefined, 'NONE')
  })
  return doc.output('blob')
}

/**
 * Das PDF des Bogens in `container`: eine A4-Seite je `.eb-seite`, in der
 * Reihenfolge des Bogens. Wirft PdfOhneSeiten oder PdfZuGross.
 */
export async function bogenZuPdf(container: HTMLElement, titel: string): Promise<Blob> {
  await bogenBereit()
  const seiten = [...container.querySelectorAll<HTMLElement>('.eb-seite')]
  if (seiten.length === 0) throw new PdfOhneSeiten()

  const schriften = await schriftCss()
  let kleinstes = Infinity
  for (const dpi of PDF_DPI) {
    const bilder = await seitenBilder(seiten, dpi, schriften)
    for (let q = 0; q < PDF_QUALITAET.length; q++) {
      const pdf = pdfAus(
        bilder.map((b) => b[q]),
        titel,
      )
      if (pdf.size <= PDF_MAX_BYTES) return pdf
      kleinstes = Math.min(kleinstes, pdf.size)
    }
  }
  throw new PdfZuGross(kleinstes)
}
