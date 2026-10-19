// Eltern-Bericht R7 — alles, was die fünf Seiten rechnen, an einer Stelle.
//
// Der Bogen ruft das einmal (useMemo) und reicht das Ergebnis an die Seiten.
// null, wenn kein Bereich direkt geprüft wurde oder der Katalog fehlt
// (Entscheidung 3): Dann gibt es keinen Bogen, nur einen Hinweis.

import {
  bereicheAus,
  kopfFall,
  sicherListe,
  uebungListe,
} from '@/lib/report/elternbericht/bereiche'
import { bauePyramide } from '@/lib/report/elternbericht/einordnung'
import { waehleSchwerpunkte } from '@/lib/report/elternbericht/schwerpunkte'
import { zaehle } from '@/lib/report/elternbericht/zaehlung'
import type { Elternbericht, KatalogSkill, SucheSkill } from '@/types'

export type ElternberichtEingabe = {
  /** ReportErzaehlung.kompetenzen — nur direkt geprüfte Skills mit Label. */
  kompetenzen: readonly SucheSkill[]
  /** ReportErzaehlung.katalog */
  katalog: readonly KatalogSkill[]
  /** Klasse der Sitzung (lsa_sessions.grade). */
  klasse: number
}

export function baueElternbericht({
  kompetenzen,
  katalog,
  klasse,
}: ElternberichtEingabe): Elternbericht | null {
  if (kompetenzen.length === 0) return null
  const bereiche = bereicheAus(kompetenzen)
  const gezaehlt = zaehle(bereiche, katalog, klasse)
  if (!gezaehlt) return null

  const { zaehlung, profil } = gezaehlt
  return {
    zaehlung,
    profil,
    pyramide: bauePyramide(bereiche, klasse),
    ...waehleSchwerpunkte(bereiche),
    sicherListe: sicherListe(bereiche),
    uebungListe: uebungListe(bereiche),
    kopfFall: kopfFall(zaehlung.sicher, zaehlung.uebung),
  }
}
