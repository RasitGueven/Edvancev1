// Eltern-Bericht R7 — alles, was die fünf Seiten rechnen, an einer Stelle.
//
// Der Bogen ruft das einmal (useMemo) und reicht das Ergebnis an die Seiten.
// null, wenn kein Bereich direkt geprüft wurde oder der Katalog fehlt
// (Entscheidung 3): Dann gibt es keinen Bogen, nur einen Hinweis.
//
// LSA-V2: Vorgriffe (vorgriff.ts), die noch nicht sicher sind, zählen nirgends
// als Übungsbedarf — nicht in Zahlen, Profil, Pyramide, Schwerpunkten und
// Listen. Der Lernweg zeigt sie in „Kommt noch“ als „noch nicht behandelt“.

import {
  bereicheAus,
  kopfFall,
  sicherListe,
  uebungListe,
} from '@/lib/report/elternbericht/bereiche'
import { bauePyramide } from '@/lib/report/elternbericht/einordnung'
import { baueLernweg, kommtNoch } from '@/lib/report/elternbericht/lernweg'
import { baueLueckenweg } from '@/lib/report/elternbericht/lueckenweg'
import { baueStufen } from '@/lib/report/elternbericht/stufenBlick'
import { schwerpunkteMitGrund, themaZuerst, type ThemaKontext } from '@/lib/report/elternbericht/schwerpunkte'
import { themaAbdeckung } from '@/lib/report/elternbericht/themaAbdeckung'
import { gezaehlt, vorgriffe } from '@/lib/report/elternbericht/vorgriff'
import { zaehle } from '@/lib/report/elternbericht/zaehlung'
import type {
  EbBereich,
  Elternbericht,
  KatalogSkill,
  KlassenarbeitStatus,
  ReportErzaehlung,
  SucheSkill,
} from '@/types'

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
  /** Bericht v2: Stand der Klassenarbeit zum Thema (Startlogik der Schwerpunkte); null = unbekannt. */
  klassenarbeit?: KlassenarbeitStatus | null
}

export function baueElternbericht({
  kompetenzen,
  katalog,
  klasse,
  lernweg,
  klassenarbeit = null,
}: ElternberichtEingabe): Elternbericht | null {
  if (kompetenzen.length === 0) return null
  const { alle, bereiche, vorgriff } = gezaehlteBereiche(kompetenzen, lernweg)
  const zahlen = zaehle(bereiche, katalog, klasse)
  if (!zahlen) return null

  const { zaehlung, profil } = zahlen
  const thema = themaKontext(kompetenzen, lernweg)
  const mitGrund = schwerpunkteMitGrund(bereiche, thema, klassenarbeit)
  return {
    zaehlung,
    profil,
    pyramide: bauePyramide(bereiche, klasse),
    schwerpunkte: mitGrund.schwerpunkte.map(({ grund: _g, ...s }) => s),
    danach: mitGrund.danach,
    gruende: mitGrund.schwerpunkte.map((s) => s.grund),
    stufen: baueStufen(bereiche, klasse),
    lueckenweg: lernweg
      ? baueLueckenweg({
          bereiche,
          kanten: lernweg.erzaehlung.kanten,
          heimatThemen: lernweg.erzaehlung.heimatThemen,
          plan: lernweg.erzaehlung.plan,
          kommt: kommtNoch({
            plan: lernweg.erzaehlung.plan,
            themaKey: lernweg.erzaehlung.raum?.themaKey ?? null,
            datum: lernweg.datum,
          }),
          raum: thema?.raum ?? new Set(),
          thema: thema?.thema ?? null,
        })
      : null,
    sicherListe: themaZuerst(sicherListe(bereiche), thema),
    uebungListe: themaZuerst(uebungListe(bereiche), thema),
    thema: thema
      ? {
          titel: thema.thema,
          uebung: themaZuerst(uebungListe(bereiche), thema)
            .filter((b) => thema.raum.has(b.skillKey))
            .map((b) => b.label),
        }
      : null,
    kopfFall: kopfFall(zaehlung.sicher, zaehlung.uebung),
    lernweg: lernweg
      ? baueLernweg({
          bereiche: alle,
          vorgriffe: vorgriff,
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
 * Die direkt geprüften Bereiche (alle), die Vorgriffe darunter und die, die
 * zählen (LSA-V2, Entscheidung 13). Vorgriffe gibt es nur in Sitzungen mit
 * Thema, dort auch rückwirkend (Rasit, 22.10.2026); ohne Thema oder ohne
 * Lernweg-Quelle (dann fehlt der Plan) bleibt alles wie vor LSA-V2. Auch für
 * die Präsentation (dieselbe Ableitung).
 */
export function gezaehlteBereiche(
  kompetenzen: readonly SucheSkill[],
  quelle?: LernwegQuelle,
): { alle: EbBereich[]; bereiche: EbBereich[]; vorgriff: Set<string> } {
  const alle = bereicheAus(kompetenzen)
  const e = quelle?.erzaehlung
  const themaKey = e?.raum?.themaKey ?? null
  if (!quelle || !e || !themaKey) return { alle, bereiche: alle, vorgriff: new Set() }
  const vorgriff = vorgriffe({
    bereiche: alle,
    raum: new Set(e.raum ? [...e.raum.einstieg, ...e.raum.darunter] : []),
    kanten: e.kanten,
    heimatThemen: e.heimatThemen,
    kommt: kommtNoch({ plan: e.plan, themaKey, datum: quelle.datum }).map((p) => p.themaKey),
    naechsteKlasse: e.plan?.naechsteKlasse?.eintraege.map((p) => p.themaKey) ?? [],
    themaKey,
  })
  return { alle, bereiche: gezaehlt(alle, vorgriff), vorgriff }
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
