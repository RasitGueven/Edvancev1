import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'
import de from '@/i18n/locales/de/vertraege.json'

/**
 * Die Vertragsvorlage gibt es zweimal.
 *
 * Die Druckansicht liest src/pages/admin/vertraege/dokumente/de/vertrag.md
 * über Vites ?raw-Import. Die Edge Function kann das nicht — der Supabase-
 * Bundler nimmt nur den Import-Graph der TypeScript-Dateien mit, eine .md im
 * Function-Ordner wäre nach dem Deploy nicht da. Also steht der Text dort als
 * Konstante.
 *
 * Diese Doppelung ist tragbar, solange sie nicht unbemerkt auseinanderläuft.
 * Genau das prüft dieser Test: Ändert jemand nur eine Seite, wird er rot. Der
 * Vergleich liest beide Dateien vom Datenträger — ein Import würde die Edge-
 * Function-Datei durch Vite schicken, die hier nichts zu suchen hat.
 */

const WURZEL = resolve(__dirname, '../../../../../..')

function lies(pfad: string): string {
  return readFileSync(resolve(WURZEL, pfad), 'utf8')
}

const gebuendelt = lies('supabase/functions/_shared/dokumente/vertrag_de.ts')

/** Holt den Wert einer exportierten Konstante aus der Bündel-Datei. */
function konstante(name: string): string {
  const re = new RegExp(`export const ${name}(?:: [^=]+)? =\\s*([\`"])([\\s\\S]*?)\\1\\n`)
  const treffer = re.exec(gebuendelt)
  if (!treffer) throw new Error(`${name} nicht in vertrag_de.ts gefunden`)
  return treffer[1] === '"' ? (JSON.parse(`"${treffer[2]}"`) as string) : treffer[2]
}

describe('Vertragsvorlage: Druckansicht und Edge Function', () => {
  it('benutzen denselben Vertragstext', () => {
    const ausDatei = lies('src/pages/admin/vertraege/dokumente/de/vertrag.md').replace(/\n+$/, '')
    expect(konstante('VERTRAG_MD')).toBe(ausDatei)
  })

  it('benutzen dieselbe Ferienklausel', () => {
    expect(konstante('FERIENKLAUSEL')).toBe(de.doc.ferienklausel)
    expect(konstante('KEINE_FERIENKLAUSEL')).toBe(de.doc.keineFerienklausel)
  })

  it('benutzen dieselben Laufzeittexte', () => {
    const block = /export const LAUFZEIT_TEXT[^=]*= \{([\s\S]*?)\n\}/.exec(gebuendelt)
    expect(block).not.toBeNull()
    for (const [monate, text] of Object.entries(de.form.laufzeitOption)) {
      expect(block![1]).toContain(`${monate}: ${JSON.stringify(text)}`)
    }
  })

  it('nennen dieselbe Fassung wie das Register', () => {
    // DOKUMENTE.vertrag.version in dokumente/index.ts — dort steht die
    // Fassung, gegen die die Unterlagenansicht die Datenbank prüft.
    const register = lies('src/pages/admin/vertraege/dokumente/index.ts')
    const ausRegister = /vertrag: \{ version: '([^']+)'/.exec(register)
    expect(ausRegister).not.toBeNull()
    expect(konstante('VERTRAG_VERSION')).toBe(ausRegister![1])
  })
})
