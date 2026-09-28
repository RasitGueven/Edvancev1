import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'
import { baueTexte, ZIEL } from '../../../../../../tools/dokumente-buendeln.mjs'

/**
 * Die Vorlagen gibt es zweimal.
 *
 * Die Druckansicht liest `dokumente/de/<art>.md` über Vites ?raw-Import. Die
 * Edge Function kann das nicht — der Supabase-Bundler nimmt nur den
 * Import-Graph der TypeScript-Dateien mit, eine .md im Function-Ordner wäre
 * nach dem Deploy nicht da. Also steht der Text dort als Konstante.
 *
 * Diese Doppelung ist tragbar, solange sie nicht unbemerkt auseinanderläuft.
 * Der Test erzeugt die gebündelte Datei aus denselben Quellen noch einmal und
 * vergleicht sie mit der eingecheckten. Das deckt alles auf einmal ab: die
 * sechs Vorlagentexte, die Ferienklausel, den Gläubiger-ID-Hinweis, die
 * Laufzeittexte und die Fassungskennungen.
 */

const WURZEL = resolve(__dirname, '../../../../../..')

describe('Vertragsvorlagen: Druckansicht und Edge Function', () => {
  it('sind Zeichen für Zeichen dieselben', () => {
    const eingecheckt = readFileSync(resolve(WURZEL, ZIEL), 'utf8')
    const frisch = baueTexte(WURZEL)

    // Die Meldung nennt den Befehl, der es richtet — sonst sucht man beim
    // nächsten Mal wieder, woher die Datei kommt.
    expect(
      frisch === eingecheckt,
      `${ZIEL} ist nicht mehr aktuell.\nNeu erzeugen:  node tools/dokumente-buendeln.mjs`,
    ).toBe(true)
  })

  it('kennt jede Vorlage, die das Register führt', () => {
    const register = readFileSync(
      resolve(WURZEL, 'src/pages/admin/vertraege/dokumente/index.ts'),
      'utf8',
    )
    const arten = [...register.matchAll(/^ {2}(\w+): \{ version:/gm)].map((m) => m[1])
    expect(arten.length).toBeGreaterThan(0)

    const gebuendelt = baueTexte(WURZEL)
    for (const art of arten) {
      // Eine Vorlage, die im Register steht, aber nicht im Bündel, wäre eine
      // Unterlage, die die Oberfläche anzeigt und das Archiv nicht kennt.
      expect(gebuendelt, `${art} fehlt im Bündel`).toContain(`  ${art}: "`)
    }
  })
})
