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
import { baueLernweg, kommtNoch } from '@/lib/report/elternbericht/lernweg'
import { themaZuerst, waehleSchwerpunkte, type ThemaKontext } from '@/lib/report/elternbericht/schwerpunkte'
import { themaAbdeckung } from '@/lib/report/elternbericht/themaAbdeckung'
import { zaehle } from '@/lib/report/elternbericht/zaehlung'
import type { Elternbericht, KatalogSkill, ReportErzaehlung, SucheSkill } from '@/types'

/**
 * Was der Lernweg (R7-9) und die Thema-Regel der Schwerpunkte (R7-11) über die
 * Kompetenzen hinaus brauchen.
 */
export type LernwegQuelle = {
  erzaehlung: Pick<
    ReportErzaehlung,
    'kanten' | 'katalog' | 'heimatThemen' | 'plan' | 'raum' | 'suche' | 'modus' | 'abgeleitet'
  >
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
  const thema = themaKontext(kompetenzen, lernweg)
  return {
    zaehlung,
    profil,
    pyramide: bauePyramide(bereiche, klasse),
    ...waehleSchwerpunkte(bereiche, thema),
    sicherListe: themaZuerst(sicherListe(bereiche), thema),
    uebungListe: themaZuerst(uebungListe(bereiche), thema),
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

/**
 * Mit Thema (R7-11, Entscheidung 1): dieselbe Bedingung wie der Thema-Satz auf
 * Seite 1 (themaAbdeckung: abgestuft, Raum vom Abschluss, Label, etwas direkt
 * im Raum). Sonst null — dann gilt die Regel aus R7, Entscheidung 7.
 */
function themaKontext(kompetenzen: readonly SucheSkill[], quelle?: LernwegQuelle): ThemaKontext | null {
  if (!quelle) return null
  const e = quelle.erzaehlung
  const abdeckung = themaAbdeckung({
    modus: e.modus,
    raum: e.raum,
    themaLabel: e.suche?.themaLabel ?? null,
    direkt: kompetenzen.map((k) => k.skillKey),
    abgeleitet: e.abgeleitet,
  })
  if (!abdeckung || !e.raum) return null
  return {
    thema: abdeckung.thema,
    raum: new Set([...e.raum.einstieg, ...e.raum.darunter]),
    geprueft: new Set(kompetenzen.map((k) => k.skillKey)),
    kanten: e.kanten,
    heimatThemen: e.heimatThemen,
    kommt: kommtNoch({ plan: e.plan, themaKey: e.raum.themaKey, datum: quelle.datum }),
  }
}
