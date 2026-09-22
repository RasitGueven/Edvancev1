// Register der Vertragsdokumente. Eine Datei je Dokument unter ./de/, die
// Versionskennung muss der aktiven Fassung in vertrag_dokumente entsprechen —
// sonst zeigt die Unterlagenansicht eine Warnung statt eines falschen Texts.
//
// Die Datenschutzhinweise zum Vertrag sind bewusst NICHT die LSA-Einwilligung
// (src/pages/admin/intake/consentDocument.ts): eigene Datei, eigener Datensatz.

import vertrag from './de/vertrag.md?raw'
import sepaMandat from './de/sepa_mandat.md?raw'
import agb from './de/agb.md?raw'
import widerruf from './de/widerruf.md?raw'
import datenschutzVertrag from './de/datenschutz_vertrag.md?raw'
import einwilligungFotos from './de/einwilligung_fotos.md?raw'

export type DokumentText = { version: string; text: string }

export const DOKUMENTE: Record<string, DokumentText> = {
  vertrag: { version: 'platzhalter-v1', text: vertrag },
  sepa_mandat: { version: 'platzhalter-v1', text: sepaMandat },
  agb: { version: 'platzhalter-v1', text: agb },
  widerruf: { version: 'platzhalter-v1', text: widerruf },
  datenschutz_vertrag: { version: 'platzhalter-v1', text: datenschutzVertrag },
  einwilligung_fotos: { version: 'platzhalter-v1', text: einwilligungFotos },
}

/** Setzt {{schluessel}}-Platzhalter ein; unbekannte oder leere Werte werden zu "—". */
export function fillDokument(text: string, werte: Record<string, string | null>): string {
  return text.replace(/\{\{(\w+)\}\}/g, (_, key: string) => {
    const wert = werte[key]
    return wert === undefined || wert === null || wert.trim() === '' ? '—' : wert
  })
}
