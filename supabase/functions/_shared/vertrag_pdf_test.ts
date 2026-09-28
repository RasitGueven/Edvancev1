// Der Test setzt ein PDF aus festen Werten und liest nach, was drinsteht.
//
// Nicht "das PDF hat 12 kB" — das waere gruen, auch wenn das Vertragsende
// fehlte. Geprueft werden die Angaben, wegen derer das Dokument existiert:
// Beginn, Ende, Widerrufsdatum, Paket, Beitrag und die Ferienklausel.
//
// Lauf:  npx deno test --allow-net --allow-read supabase/functions/_shared/vertrag_pdf_test.ts

import { assert, assertEquals, assertStringIncludes } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { markdownZuPdf, winAnsi } from './markdown_pdf.ts'
import { dokumentAusZeile } from './vertrag_dokument.ts'

// Ein winziges echtes PNG — pdf-lib liest den Header, ein Fantasiestring
// wuerde beim Einbetten fliegen.
const SIGNATUR = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAHgAAAAoCAIAAAC6iKlyAAAAfklEQVR4nO3QwQmAAAwEwfTftDag4COsgjMNJLdzkJi3H/gLoSNCR4SOCB0ROiJ0ROjIfuh5Zv3uut0hQt8SOiJ0ROiI0BGhI0JHhI4IHRE6InRE6IjQEaEjQkeEjggdEToidEToiNARoSNfD80loSNCR4SOCB0ROiJ0ROjICfxCD6I3k/eCAAAAAElFTkSuQmCC'

const VERTRAG = {
  id: '11111111-2222-3333-4444-555555555555',
  status: 'abgeschlossen',
  eltern_vorname: 'Miriam',
  eltern_nachname: 'Özdemir',
  strasse: 'Aachener Straße',
  hausnummer: '117',
  plz: '50674',
  ort: 'Köln',
  eltern_telefon: '0221 1234567',
  eltern_email: 'miriam@example.org',
  kind_vorname: 'Jonas',
  kind_nachname: 'Özdemir',
  kind_geburtsdatum: '2012-04-08',
  klasse: 8,
  fach: 'Mathematik',
  schule: 'Gymnasium Köln-Lindenthal',
  laufzeit_monate: 6,
  preis_cents: 38990,
  einheiten: 24,
  vertragsbeginn: '2026-10-01',
  vertrag_ende: '2027-04-30',
  ferientage: 35,
  widerruf_bis: '2026-10-15',
  mandatsreferenz: 'EDV-2026-000042',
  unterschrieben_am: '2026-09-24',
  abgeschlossen_am: '2026-09-24',
}

async function entpacken(b: Uint8Array): Promise<Uint8Array | null> {
  try {
    const strom = new Blob([new Uint8Array(b)]).stream().pipeThrough(new DecompressionStream('deflate'))
    return new Uint8Array(await new Response(strom).arrayBuffer())
  } catch {
    return null
  }
}

// WinAnsi ist nicht Latin-1: 0x80–0x9F tragen dort Typografie.
const WINANSI_OBEN: Record<number, string> = {
  0x80: '€', 0x84: '„', 0x85: '…', 0x91: '\u2018', 0x92: '\u2019',
  0x93: '\u201C', 0x94: '\u201D', 0x95: '\u2022', 0x96: '–', 0x97: '—',
}

/**
 * Die im PDF gezeichneten Zeichenketten.
 *
 * pdf-lib packt die Inhaltsstroeme mit Flate ein und schreibt den Text als
 * Hex-String (`<546974656C> Tj`). Beides wird hier rueckgaengig gemacht. Das
 * ist mehr Aufwand als auf die Dateigroesse zu schauen — aber eine Pruefung,
 * die nur die Groesse kennt, bleibt gruen, wenn das Vertragsende fehlt.
 *
 * Die Laenge kommt aus /Length: das Wort "stream" steckt auch in "endstream",
 * eine Suche nach dem Endwort findet die falsche Stelle.
 */
async function pdfText(bytes: Uint8Array): Promise<string> {
  const roh = new TextDecoder('latin1').decode(bytes)
  const woerter: string[] = []
  for (const kopf of roh.matchAll(/\/Length (\d+)[\s\S]{0,120}?stream\r?\n/g)) {
    const von = kopf.index! + kopf[0].length
    const klar = await entpacken(bytes.subarray(von, von + Number(kopf[1])))
    if (!klar) continue
    for (const t of new TextDecoder('latin1').decode(klar).matchAll(/<([0-9A-Fa-f]*)>\s*Tj/g)) {
      const hex = t[1]
      let wort = ''
      for (let i = 0; i + 1 < hex.length; i += 2) {
        const code = parseInt(hex.slice(i, i + 2), 16)
        wort += WINANSI_OBEN[code] ?? String.fromCharCode(code)
      }
      woerter.push(wort)
    }
  }
  return woerter.join(' ')
}

Deno.test('Vertrags-PDF traegt die Angaben, wegen derer es existiert', async () => {
  const dok = dokumentAusZeile(VERTRAG, 'Fokus', SIGNATUR)
  const pdf = await markdownZuPdf({
    markdown: dok.markdown,
    fusszeile: dok.fusszeile,
    unterschrift: dok.unterschrift,
  })

  assertEquals(new TextDecoder().decode(pdf.slice(0, 5)), '%PDF-')
  const text = await pdfText(pdf)

  assertStringIncludes(text, '01.10.2026', 'Vertragsbeginn fehlt')
  assertStringIncludes(text, '30.04.2027', 'Vertragsende fehlt')
  assertStringIncludes(text, '15.10.2026', 'Widerrufsdatum fehlt')
  assertStringIncludes(text, 'Widerrufsfrist', 'Widerrufsabschnitt fehlt')
  assertStringIncludes(text, 'Fokus', 'Paket fehlt')
  assertStringIncludes(text, '389,90', 'Monatsbeitrag fehlt')
  assertStringIncludes(text, '2.339,40', 'Gesamtpreis fehlt')
  assertStringIncludes(text, 'Halbjahrespaket', 'Laufzeittext fehlt')
  assertStringIncludes(text, 'Ferientage', 'Ferienklausel fehlt')
  assertStringIncludes(text, '35', 'Ferientage-Zahl fehlt')
  assertStringIncludes(text, 'Jonas', 'Name des Kindes fehlt')
  // Umlaute muessen den Weg durch WinAnsi ueberstehen.
  assertStringIncludes(text, 'Özdemir', 'Umlaut im Nachnamen verloren')
  assertStringIncludes(text, 'Köln', 'Ort verloren')
  assertStringIncludes(text, 'EDV-2026-000042', 'Fusszeile ohne Mandatsreferenz')
  assertStringIncludes(text, 'Seite 1 von', 'Seitenzahl fehlt')
})

Deno.test('Zwoelf Monate: keine Ferienklausel, sondern der Zwoelf-Monats-Satz', async () => {
  const dok = dokumentAusZeile(
    { ...VERTRAG, laufzeit_monate: 12, vertrag_ende: '2027-09-30', ferientage: 0 },
    'Fokus',
    null,
  )
  assertStringIncludes(dok.markdown, 'zwölf volle Kalendermonate')
  assert(!dok.markdown.includes('Ferientage'), 'Ferienklausel im Jahresvertrag')
  assertEquals(dok.unterschrift, null, 'Unterschrift ohne Signatur erzeugt')
})

Deno.test('Kein Platzhalter bleibt ungefuellt', () => {
  const dok = dokumentAusZeile(VERTRAG, 'Fokus', null)
  assertEquals(dok.markdown.match(/\{\{\w+\}\}/g), null)
})

Deno.test('WinAnsi: schmales Leerzeichen wird gewoehnlich, Exoten werden ersetzt', () => {
  assertEquals(winAnsi('389,90 €'), '389,90 €')
  assertEquals(winAnsi('Wei\u{1F600}ter'), 'Wei??ter') // ausserhalb der BMP: zwei Einheiten
  assertEquals(winAnsi('Größe – „Zitat" · 24 × 60'), 'Größe – „Zitat" · 24 × 60')
})
