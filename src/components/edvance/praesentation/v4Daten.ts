// Tablet-Präsentation V4 (Bauauftrag V4, V4-3) — was die Stationen über die
// Klassenarbeiten wissen, aus denselben Rechnungen wie der Bericht.
//
// bauePraesentation (src/lib) liefert den Fahrplan nicht und kennt weder den
// Stand der Klassenarbeit noch die Note. Darum rechnet die Ebene der
// Komponenten den Elternbericht hier noch einmal, so wie Bogen.tsx (gleiche
// Eingaben, gleiche Zahlen auf Tablet und Papier). Ohne Fahrplan gibt es
// null: Die Präsentation fällt auf die Zuordnung vor V4 zurück.

import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { fehlermusterAus, type Fehlermuster } from '@/lib/report/elternbericht/fehlermuster'
import { zieleV4, type ZielSchluessel } from '@/lib/report/elternbericht/zielbild'
import type {
  EbFahrplan,
  EbStation,
  Elternbericht,
  KlassenarbeitStatus,
  ReportData,
  ReportNotes,
  ThemenfeldKey,
} from '@/types'

export type PraesentationV4 = {
  bericht: Elternbericht
  fahrplan: EbFahrplan
  /** Aufgaben der Sitzung (Eckdaten in Station 02). */
  aufgaben: number
  /** Bearbeitungszeit in Minuten (ReportData.dauerMinuten); null ohne Zeiten. */
  minuten: number | null
  muster: Fehlermuster | null
  /** Ziele in Elternsprache (Systemvorschlag), immer gesetzt (L5 Teil D). */
  ziele: ZielSchluessel[]
  /** L5 Teil D: Ziele im Gespräch bestätigt (Kicker der Ziele in Station 04). */
  zieleBestaetigt: boolean
  /** LSA-L4: Stand der Klassenarbeit beim LSA-Start und die gemeldete Note (Satz in Station 03). */
  klassenarbeit: KlassenarbeitStatus | null
  note: number | null
}

/** Die Bereiche in „Wird später wichtig“ (Lücken ohne kommende Station). */
function spaeterLuecken(bericht: Elternbericht): number {
  return (bericht.lueckenwegV4?.weitere ?? []).reduce((summe, g) => summe + g.labels.length + (g.rest ?? 0), 0)
}

export function baueV4(data: ReportData, notes: ReportNotes | null): PraesentationV4 | null {
  const { kompetenzen, katalog } = data.erzaehlung
  const bericht = baueElternbericht({
    kompetenzen,
    katalog,
    klasse: data.grade,
    lernweg: { erzaehlung: data.erzaehlung, datum: data.analysedAt },
    klassenarbeit: data.erstgespraech?.klassenarbeit ?? null,
    note: data.erstgespraech?.letzteNote ?? null,
    arbeiten: data.erstgespraech?.klassenarbeiten,
  })
  if (!bericht?.fahrplan) return null
  const muster = fehlermusterAus(data.fehlbilder)
  const name = data.firstName?.trim() || null
  return {
    bericht,
    fahrplan: bericht.fahrplan,
    aufgaben: data.aufgaben,
    minuten: data.dauerMinuten ?? null,
    muster,
    klassenarbeit: data.erstgespraech?.klassenarbeit ?? null,
    note: data.erstgespraech?.letzteNote ?? null,
    zieleBestaetigt: notes?.zieleBestaetigt === true,
    // L5 Teil D (Entscheidung 13): die Systemziele immer, auch ohne Bestätigung.
    ziele: zieleV4({ fahrplan: bericht.fahrplan, muster, name, spaeterLuecken: spaeterLuecken(bericht) }),
  }
}

/** Die kommenden Stationen (alles außer dem aktuellen Thema). */
export const kommende = (f: EbFahrplan): EbStation[] => f.stationen.filter((s) => s.nummer > 1)

/**
 * „Wichtig für“ eines Themenfelds (Seite 2 des Berichts): die Stationen, die ein
 * geprüfter Bereich des Felds betrifft, höchstens zwei in Plan-Reihenfolge.
 * 'spaeter' = kein Thema, aber Übungsbedarf; null = nichts anzuzeigen.
 */
export function wichtigFuer(v4: PraesentationV4, feld: ThemenfeldKey, mitUebung: boolean): EbStation[] | 'spaeter' | null {
  const betrifft = (themaKey: string): boolean =>
    (v4.bericht.signale ?? []).some(
      (s) => s.themaKey === themaKey && [...s.sitzt, ...s.fehlt].some((b) => b.feld === feld),
    )
  const treffer = kommende(v4.fahrplan)
    .filter((s) => betrifft(s.themaKey))
    .slice(0, 2)
  if (treffer.length > 0) return treffer
  return mitUebung ? 'spaeter' : null
}

/**
 * Die Schule für „aus dem Schulplan des {{schule}}“: der Name mit Genitiv-s bei
 * Gymnasium und Kolleg, sonst der Name selbst.
 */
