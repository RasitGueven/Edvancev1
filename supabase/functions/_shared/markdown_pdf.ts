// Ein kleiner Markdown-Setzer fuer die Vertragsunterlagen.
//
// Keine Markdown-Bibliothek und kein Headless-Browser. Die Vorlagen benutzen
// fuenf Konstrukte — "#", "##", "-", ">" und **fett** —, das sind 74 Zeilen
// ueber sechs Dateien. Eine Engine dafuer einzubinden hiesse, ihren ganzen
// Sprachumfang zu erben, ohne ihn je zu benutzen: jedes Konstrukt, das die
// Vorlage nie enthaelt, ist eine Seite im Vertrag, die niemand vorhergesehen
// hat. Was hier nicht steht, wird als gewoehnlicher Absatz gesetzt.
//
// pdf-lib statt Puppeteer: Eine Edge Function hat keinen Browser. pdf-lib
// erzeugt das PDF direkt und kommt ohne Systemabhaengigkeit aus.

import { PDFDocument, StandardFonts, rgb } from 'https://esm.sh/pdf-lib@1.17.1'
import type { PDFFont, PDFImage, PDFPage } from 'https://esm.sh/pdf-lib@1.17.1'

const SEITE = { breite: 595.28, hoehe: 841.89 } // A4 in Punkt
const RAND = 56
const TEXTBREITE = SEITE.breite - 2 * RAND

const FARBE_TEXT = rgb(0.11, 0.14, 0.21)
const FARBE_LEISE = rgb(0.42, 0.46, 0.55)
const FARBE_LINIE = rgb(0.8, 0.83, 0.88)

type Art = 'h1' | 'h2' | 'li' | 'quote' | 'p' | 'seitenumbruch'
/** `klebt` = im Quelltext stand kein Leerzeichen davor (Satzzeichen). */
type Wort = { text: string; fett: boolean; klebt: boolean }
/** `weiter` = direkt an den Block darueber, ohne Absatzabstand. */
type Block = { art: Art; woerter: Wort[]; weiter: boolean }

type Stil = { groesse: number; hoehe: number; davor: number; einzug: number }

const STIL: Record<Art, Stil> = {
  h1: { groesse: 20, hoehe: 26, davor: 0, einzug: 0 },
  h2: { groesse: 12, hoehe: 17, davor: 18, einzug: 0 },
  li: { groesse: 10.5, hoehe: 15, davor: 3, einzug: 14 },
  quote: { groesse: 9.5, hoehe: 14, davor: 12, einzug: 12 },
  p: { groesse: 10.5, hoehe: 15, davor: 10, einzug: 0 },
  seitenumbruch: { groesse: 0, hoehe: 0, davor: 0, einzug: 0 },
}

/**
 * WinAnsi kann fast alles, was deutsche Typografie braucht — aber nicht die
 * schmalen Leerzeichen, die Intl.NumberFormat vor das Euro-Zeichen setzt
 * (U+202F). Die werden zu gewoehnlichen Leerzeichen; alles andere ausserhalb
 * des Zeichenvorrats zu "?", damit ein exotisches Zeichen aus einem Namen das
 * PDF nicht platzen laesst.
 */
export function winAnsi(text: string): string {
  return text
    .replace(/[      ]/g, ' ')
    .replace(
      /[^\x20-\x7E\xA0-\xFFŒœŠšŸŽžƒˆ˜–—‘’‚“”„†‡•…‰‹›€™]/g,
      '?',
    )
}

/**
 * Zerlegt eine Zeile an **…** in fette und normale Woerter.
 *
 * Die Fettschrift endet in der Vorlage oft mitten im Satz: "**389,90 €**, **6**
 * Beitraege". Das Komma ist danach ein eigenes Wort — ohne die Merkung, dass
 * im Quelltext kein Leerzeichen davor stand, saesse es abgerueckt da.
 */
function woerter(zeile: string): Wort[] {
  const raus: Wort[] = []
  // Das Leerzeichen zwischen zwei Stuecken steht am ENDE des vorigen, nicht am
  // Anfang des naechsten: "Paket: " + "Fokus". Nur das vordere Stueck zu
  // befragen ist der Unterschied zwischen "Paket: Fokus" und "Paket:Fokus".
  let luecke_davor = true
  for (const [i, stueck] of zeile.split('**').entries()) {
    const fett = i % 2 === 1
    const teile = stueck.split(/\s+/).filter((w) => w !== '')
    for (const [j, w] of teile.entries()) {
      const klebt = j === 0 && raus.length > 0 && !luecke_davor && !/^\s/.test(stueck)
      raus.push({ text: winAnsi(w), fett, klebt })
    }
    // Ein leeres Stueck (zwei ** direkt hintereinander) aendert nichts daran,
    // ob vor dem naechsten Wort ein Leerzeichen stand.
    if (teile.length > 0) luecke_davor = /\s$/.test(stueck)
  }
  return raus
}

/**
 * Breite eines Worts — Zeichen fuer Zeichen gemessen.
 *
 * Nicht aus Umstaendlichkeit: pdf-lib MISST mit Kerning, ZEICHNET aber ohne.
 * "Text" ist gemessen 1,57 pt schmaler als gezeichnet, weil "Te" ein
 * Kerningpaar ist — das Wort danach ruecke um diesen Betrag zu weit nach
 * links und klebte an. Ein einzelnes Zeichen hat kein Paar, also kann diese
 * Messung nicht kernen und stimmt mit dem ueberein, was im PDF landet.
 */
function breite(schrift: PDFFont, text: string, groesse: number): number {
  let b = 0
  for (const zeichen of text) b += schrift.widthOfTextAtSize(zeichen, groesse)
  return b
}

/**
 * Breite der Luecke vor einem Wort — gemessen in der Schrift des Wortes
 * davor. Das Leerzeichen der fetten Helvetica ist breiter als das der
 * mageren; immer die magere zu nehmen, drueckt fette Zeilen zusammen.
 */
function luecke(vor: Wort | undefined, w: Wort, groesse: number, normal: PDFFont, fett: PDFFont): number {
  if (vor === undefined || w.klebt) return 0
  return breite(vor.fett ? fett : normal, ' ', groesse)
}

/**
 * Markdown zu Bloecken.
 *
 * Zwei aufeinanderfolgende gewoehnliche Zeilen bleiben zwei Zeilen — sie
 * werden nicht zu einem Absatz verschmolzen, wie Markdown es sonst tut. Das
 * ist dieselbe Regel, die die Bildschirmansicht mit whitespace-pre-line
 * anwendet, und sie haelt die Anschrift zusammen: Name, Strasse, Ort stehen
 * untereinander und nicht in einer Zeile hintereinander.
 */
export function bloecke(markdown: string): Block[] {
  const raus: Block[] = []
  let letzteWarText = false
  for (const roh of markdown.split('\n')) {
    const zeile = roh.trim()
    if (zeile === '') {
      letzteWarText = false
      continue
    }
    // "---" allein auf einer Zeile beginnt eine neue Seite. Gebraucht fuer
    // die Unterlagen zum Ausdrucken: Vertrag und SEPA-Mandat liegen in einer
    // Datei, sollen aber nicht auf demselben Blatt anfangen.
    if (zeile === '---') {
      raus.push({ art: 'seitenumbruch', woerter: [], weiter: false })
      letzteWarText = false
      continue
    }
    const art: Art = zeile.startsWith('## ')
      ? 'h2'
      : zeile.startsWith('# ')
        ? 'h1'
        : zeile.startsWith('- ')
          ? 'li'
          : zeile.startsWith('> ')
            ? 'quote'
            : 'p'
    const inhalt = art === 'p' ? zeile : zeile.slice(zeile.indexOf(' ') + 1)
    raus.push({ art, woerter: woerter(inhalt), weiter: art === 'p' && letzteWarText })
    letzteWarText = art === 'p'
  }
  return raus
}

/** Greedy-Umbruch. Jedes Wort wird mit seiner eigenen Schrift gemessen. */
function umbrechen(ws: Wort[], maxBreite: number, groesse: number, normal: PDFFont, fett: PDFFont): Wort[][] {
  const zeilen: Wort[][] = []
  let zeile: Wort[] = []
  let x = 0
  for (const w of ws) {
    const b = breite(w.fett ? fett : normal, w.text, groesse)
    const l = luecke(zeile[zeile.length - 1], w, groesse, normal, fett)
    // Ein klebendes Wort ist ein Satzzeichen — es faengt keine neue Zeile an,
    // auch wenn es dafuer ein paar Punkt ueber den Rand ragt.
    if (zeile.length > 0 && !w.klebt && x + l + b > maxBreite) {
      zeilen.push(zeile)
      zeile = []
      x = 0
      zeile.push(w)
      x += b
      continue
    }
    zeile.push(w)
    x += l + b
  }
  if (zeile.length > 0) zeilen.push(zeile)
  return zeilen
}

export type PdfEingabe = {
  markdown: string
  /** Steht klein unter jeder Seite, neben der Seitenzahl. */
  fusszeile: string
  unterschrift?: { png: Uint8Array; beschriftung: string; ort: string } | null
}

export async function markdownZuPdf({ markdown, fusszeile, unterschrift }: PdfEingabe): Promise<Uint8Array> {
  const pdf = await PDFDocument.create()
  const normal = await pdf.embedFont(StandardFonts.Helvetica)
  const fett = await pdf.embedFont(StandardFonts.HelveticaBold)

  let seite: PDFPage = pdf.addPage([SEITE.breite, SEITE.hoehe])
  let y = SEITE.hoehe - RAND

  const neueSeite = (): void => {
    seite = pdf.addPage([SEITE.breite, SEITE.hoehe])
    y = SEITE.hoehe - RAND
  }
  const platz = (hoehe: number): void => {
    if (y - hoehe < RAND + 24) neueSeite()
  }

  const zeileSetzen = (ws: Wort[], groesse: number, x0: number, farbe: typeof FARBE_TEXT): void => {
    let x = x0
    for (const [i, w] of ws.entries()) {
      const schrift = w.fett ? fett : normal
      x += luecke(ws[i - 1], w, groesse, normal, fett)
      seite.drawText(w.text, { x, y, size: groesse, font: schrift, color: farbe })
      x += breite(schrift, w.text, groesse)
    }
  }

  for (const block of bloecke(markdown)) {
    if (block.art === 'seitenumbruch') {
      neueSeite()
      continue
    }
    const s = STIL[block.art]
    const farbe = block.art === 'quote' ? FARBE_LEISE : FARBE_TEXT
    const x0 = RAND + s.einzug
    const zeilen = umbrechen(block.woerter, TEXTBREITE - s.einzug, s.groesse, normal, fett)

    y -= block.weiter ? 0 : s.davor
    for (const [i, zeile] of zeilen.entries()) {
      platz(s.hoehe)
      // Der Aufzaehlungspunkt steht vor der ERSTEN Zeile; Folgezeilen eines
      // Punkts ruecken unter den Text, nicht unter den Punkt.
      if (block.art === 'li' && i === 0) {
        seite.drawText('•', { x: RAND + 3, y, size: s.groesse, font: normal, color: FARBE_LEISE })
      }
      if (block.art === 'quote') {
        seite.drawLine({
          start: { x: RAND + 2, y: y - 3 },
          end: { x: RAND + 2, y: y + s.groesse },
          thickness: 2,
          color: FARBE_LINIE,
        })
      }
      zeileSetzen(zeile, s.groesse, x0, farbe)
      y -= s.hoehe
    }
    if (block.art === 'h1') {
      platz(12)
      y -= 4
      seite.drawLine({
        start: { x: RAND, y },
        end: { x: SEITE.breite - RAND, y },
        thickness: 1,
        color: FARBE_LINIE,
      })
      y -= 12
    }
  }

  if (unterschrift) {
    const bild: PDFImage = await pdf.embedPng(unterschrift.png)
    // Auf 150 pt Breite skaliert, aber nie hoeher als 60 pt.
    const skala = Math.min(150 / bild.width, 60 / bild.height)
    const b = bild.width * skala
    const h = bild.height * skala
    if (y - (h + 54) < RAND) neueSeite()
    y -= 34
    seite.drawImage(bild, { x: RAND, y: y - h, width: b, height: h })
    y -= h + 6
    seite.drawLine({
      start: { x: RAND, y },
      end: { x: RAND + Math.max(b, 180), y },
      thickness: 1,
      color: FARBE_LINIE,
    })
    y -= 12
    seite.drawText(winAnsi(unterschrift.beschriftung), {
      x: RAND, y, size: 9, font: normal, color: FARBE_LEISE,
    })
    y -= 12
    seite.drawText(winAnsi(unterschrift.ort), {
      x: RAND, y, size: 9, font: normal, color: FARBE_LEISE,
    })
  }

  const seiten = pdf.getPages()
  for (const [i, s] of seiten.entries()) {
    const text = winAnsi(`${fusszeile}  ·  Seite ${i + 1} von ${seiten.length}`)
    s.drawText(text, {
      x: RAND,
      y: RAND - 22,
      size: 7.5,
      font: normal,
      color: FARBE_LEISE,
    })
  }

  return await pdf.save()
}
