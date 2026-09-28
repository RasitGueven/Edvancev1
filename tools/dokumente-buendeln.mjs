// Erzeugt supabase/functions/_shared/dokumente/texte.ts aus den Quellen.
//
// Die Edge Function kann die .md-Dateien nicht lesen — der Supabase-Bundler
// nimmt nur den Import-Graph der TypeScript-Dateien mit. Statt den Text von
// Hand zu kopieren, wird er hier erzeugt; vorlagenGleich.test.ts baut ihn im
// Test noch einmal und vergleicht mit der eingecheckten Datei.
//
//     node tools/dokumente-buendeln.mjs

import { readFileSync, writeFileSync } from 'node:fs'
import { resolve } from 'node:path'

export const ZIEL = 'supabase/functions/_shared/dokumente/texte.ts'

const ARTEN = [
  'vertrag',
  'sepa_mandat',
  'agb',
  'widerruf',
  'datenschutz_vertrag',
  'einwilligung_fotos',
]

/** Der Inhalt von texte.ts, ohne ihn zu schreiben. */
export function baueTexte(wurzel = '.') {
  const lies = (p) => readFileSync(resolve(wurzel, p), 'utf8')
  const register = lies('src/pages/admin/vertraege/dokumente/index.ts')
  const i18n = JSON.parse(lies('src/i18n/locales/de/vertraege.json'))

  // Schluessel -> Fassung, aus DOKUMENTE in dokumente/index.ts.
  const fassungen = Object.fromEntries(
    [...register.matchAll(/(\w+): \{ version: '([^']+)'/g)].map((m) => [m[1], m[2]]),
  )

  const texte = {}
  for (const art of ARTEN) {
    if (!fassungen[art]) throw new Error(`${art}: keine Fassung in dokumente/index.ts`)
    texte[art] = lies(`src/pages/admin/vertraege/dokumente/de/${art}.md`).replace(/\n+$/, '')
  }

  // JSON statt Template-Literal: agb.md enthaelt Backticks, und ein Text, der
  // seine eigene Syntax mitbringt, hat in einer erzeugten Datei nichts zu
  // suchen. JSON.stringify escapt alles, was escapt werden muss.
  const s = (x) => JSON.stringify(x)

  return [
    '// ERZEUGT von tools/dokumente-buendeln.mjs — nicht von Hand bearbeiten.',
    '//',
    '// Die Textbausteine der Vertragsunterlagen als TypeScript. Warum nicht die',
    '// .md direkt lesen: Der Supabase-Bundler nimmt nur den Import-Graph der',
    '// TypeScript-Dateien mit. Ein Deno.readTextFile auf eine .md im Function-',
    '// Ordner liefe lokal und waere nach dem Deploy tot.',
    '//',
    '// Damit gibt es die Vorlagen zweimal. Bewusste Doppelung mit Wachhund:',
    '// vorlagenGleich.test.ts erzeugt diese Datei im Test noch einmal und',
    '// vergleicht sie mit der eingecheckten. Aendert jemand nur eine Seite,',
    '// wird der Test rot und nennt den Befehl, der es richtet.',
    '',
    `export type DokumentArt = ${ARTEN.map(s).join(' | ')}`,
    '',
    '/** Die Arten, die je Vertrag entstehen — mit eingesetzten Werten. */',
    `export const JE_VERTRAG: DokumentArt[] = [${['vertrag', 'sepa_mandat'].map(s).join(', ')}]`,
    '',
    '/** Die Arten, die fuer alle gleich sind — eine Datei je Fassung. */',
    `export const JE_FASSUNG: DokumentArt[] = [${ARTEN.filter((a) => !['vertrag', 'sepa_mandat'].includes(a)).map(s).join(', ')}]`,
    '',
    '/** Fassungskennung je Art, muss zu vertrag_dokumente.version passen. */',
    'export const FASSUNG: Record<DokumentArt, string> = {',
    ...ARTEN.map((a) => `  ${a}: ${s(fassungen[a])},`),
    '}',
    '',
    '/** Wortgleich mit src/pages/admin/vertraege/dokumente/de/<art>.md. */',
    'export const TEXT: Record<DokumentArt, string> = {',
    ...ARTEN.map((a) => `  ${a}: ${s(texte[a])},`),
    '}',
    '',
    '/** Wortgleich mit de/vertraege.json → doc.* */',
    `export const FERIENKLAUSEL = ${s(i18n.doc.ferienklausel)}`,
    `export const KEINE_FERIENKLAUSEL = ${s(i18n.doc.keineFerienklausel)}`,
    `export const GLAEUBIGER_ID_FEHLT = ${s(i18n.doc.glaeubigerIdFehlt)}`,
    '',
    '/** Wortgleich mit de/vertraege.json → form.laufzeitOption. */',
    'export const LAUFZEIT_TEXT: Record<number, string> = {',
    ...Object.entries(i18n.form.laufzeitOption)
      .sort((a, b) => Number(a[0]) - Number(b[0]))
      .map(([k, v]) => `  ${k}: ${s(v)},`),
    '}',
    '',
  ].join('\n')
}

if (import.meta.url === `file://${process.argv[1]}`) {
  writeFileSync(ZIEL, baueTexte())
  console.log(`${ZIEL} erzeugt (${ARTEN.length} Dokumente)`)
}
