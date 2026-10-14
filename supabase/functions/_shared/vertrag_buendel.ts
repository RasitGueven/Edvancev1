// Was in den Umschlag gehoert — reine Zusammenstellung ohne Datenbank.
// Ausgelagert aus vertrag_pdf_erzeugen.ts (V5), Verhalten unveraendert bis auf
// den Pilot-Zweig; vertrag_pdf_erzeugen.ts exportiert es weiter.

import { JE_FASSUNG, NUR_REGULAER } from './dokumente/texte.ts'

/**
 * Was in den Umschlag gehoert — als Pfade im Bucket, in Lesereihenfolge.
 *
 * Fehlt etwas, wird es hier erzeugt statt eine halbe Mail zu verschicken. Ein
 * Buendel, dem die Widerrufsbelehrung fehlt, ist kein unvollstaendiges
 * Buendel, sondern ein rechtliches Problem.
 *
 * Die Fassungen sind die, denen dieser Vertrag ZUGESTIMMT hat — nicht die
 * neuesten. Sonst laege dem Elternteil ein Text bei, den es nie gesehen hat.
 * Die Foto-Einwilligung ist freiwillig und nur dabei, wenn zugestimmt wurde.
 */
export type Umschlagstueck = { pfad: string; name: string }

/**
 * Die Unterlagen, die JEDE Mail tragen muss.
 *
 * Die Foto-Einwilligung fehlt hier mit Absicht: sie ist freiwillig und keine
 * Voraussetzung fuer den Vertrag. Die drei anderen sind es.
 */
const PFLICHT: readonly string[] = ['agb', 'widerruf', 'datenschutz_vertrag']

/** Dateiname ohne Pfadtrenner und ohne Zeichen, die Mailprogramme stolpern lassen. */
function sicherName(titel: string, art: string): string {
  const roh = titel.trim() === '' ? art : titel
  const sauber = roh
    .replace(/[\\/:*?"<>|]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
  return `${sauber === '' ? art : sauber}.pdf`
}

/**
 * Was in den Umschlag gehoert — mit Pfad UND Dateinamen.
 *
 * Der Name kommt aus dem Katalog, nicht aus dem Pfad. Die Fassungen liegen
 * unter fassungen/<art>/<fassung>.pdf; aus dem Pfad abgeleitet hiessen sie
 * alle gleich ("platzhalter-v1.pdf"), und die Eltern haetten vier
 * ununterscheidbare Anhaenge im Postfach.
 *
 * Fehlt eine Pflichtunterlage, wird geworfen statt uebersprungen. Eine Mail
 * ohne AGB und Widerrufsbelehrung ist kein unvollstaendiges Buendel, sondern
 * ein rechtliches Problem — und sie saehe aus wie ein vollstaendiges.
 */
export function buendelZusammenstellen(opts: {
  dateien: { art: string; pfad: string }[]
  zustimmungen: { dokument_schluessel: string; dokument_version: string }[]
  fassungen: { art: string; fassung: string; pfad: string }[]
  titel: Record<string, string>
  anlass: 'bestaetigung' | 'unterlagen'
  /** V5: Pilot — ohne SEPA-Mandat, AGB und Widerrufsbelehrung. */
  pilot?: boolean
}): Umschlagstueck[] {
  const { dateien, zustimmungen, fassungen, titel, anlass, pilot = false } = opts
  const pflicht = pilot ? PFLICHT.filter((a) => !(NUR_REGULAER as string[]).includes(a)) : PFLICHT
  const je = new Map(dateien.map((d) => [d.art, d.pfad]))
  const raus: Umschlagstueck[] = []

  if (anlass === 'bestaetigung') {
    const vertrag = je.get('vertrag')
    const sepa = je.get('sepa_mandat')
    if (!vertrag || (!sepa && !pilot)) {
      throw new Error('Das Vertrags-PDF fehlt noch — bitte erst im Archiv erzeugen')
    }
    if (pilot) {
      raus.push({ pfad: vertrag, name: sicherName(titel.pilotvereinbarung ?? '', 'Pilotvereinbarung') })
    } else {
      raus.push({ pfad: vertrag, name: sicherName(titel.vertrag ?? '', 'Vertrag') })
      raus.push({ pfad: sepa!, name: sicherName(titel.sepa_mandat ?? '', 'SEPA-Mandat') })
    }
  } else {
    const unterlagen = je.get('unterlagen_versand')
    if (!unterlagen) throw new Error('Die Unterlagen wurden noch nicht erzeugt')
    raus.push({ pfad: unterlagen, name: 'Vertragsunterlagen.pdf' })
  }

  for (const art of JE_FASSUNG) {
    const z = zustimmungen.find((x) => x.dokument_schluessel === art)
    if (!z) {
      if (pflicht.includes(art)) {
        throw new Error(
          `Zu diesem Vertrag ist keine Zustimmung zu "${art}" festgehalten — ` +
            'ohne sie darf das Dokument nicht als vereinbart mitgeschickt werden',
        )
      }
      continue
    }
    const f = fassungen.find((x) => x.art === art && x.fassung === z.dokument_version)
    if (!f) throw new Error(`Die Fassung ${art} ${z.dokument_version} liegt nicht im Archiv`)
    raus.push({ pfad: f.pfad, name: sicherName(titel[art] ?? '', art) })
  }
  return raus
}
