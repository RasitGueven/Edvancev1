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
import { baueLernweg } from '@/lib/report/elternbericht/lernweg'
import { waehleSchwerpunkte } from '@/lib/report/elternbericht/schwerpunkte'
import { zaehle } from '@/lib/report/elternbericht/zaehlung'
import type { Elternbericht, KatalogSkill, ReportErzaehlung, SucheSkill } from '@/types'

/** Was der Lernweg (R7-9) über die Kompetenzen hinaus braucht. */
export type LernwegQuelle = {
  erzaehlung: Pick<ReportErzaehlung, 'kanten' | 'katalog' | 'heimatThemen' | 'plan' | 'raum' | 'suche'>
  /** Datum der Sitzung, dasselbe wie im Kopf von Seite 1 (data.analysedAt). */
  datum: string | null
}

export type ElternberichtEingabe = {
  /** ReportErzaehlung.kompetenzen — nur direkt geprüfte Skills mit Label. */
  kompetenzen: readonly SucheSkill[]
  /** ReportErzaehlung.katalog */
  katalog: readonly KatalogSkill[]
  /** Klasse der Sitzung (lsa_sessions.grade). */
  klasse: number
  /** Ohne sie kein Lernweg (bericht.lernweg null). Bogen und Präsentation geben sie mit. */
  lernweg?: LernwegQuelle
}

export function baueElternbericht({
  kompetenzen,
  katalog,
  klasse,
  lernweg,
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
    lernweg: lernweg
      ? baueLernweg({
          bereiche,
          klasse,
          kanten: lernweg.erzaehlung.kanten,
          katalog: lernweg.erzaehlung.katalog,
          heimatThemen: lernweg.erzaehlung.heimatThemen,
          plan: lernweg.erzaehlung.plan,
          themaKey: lernweg.erzaehlung.raum?.themaKey ?? null,
          thema: lernweg.erzaehlung.suche?.themaLabel ?? null,
          datum: lernweg.datum,
        })
      : null,
  }
}
