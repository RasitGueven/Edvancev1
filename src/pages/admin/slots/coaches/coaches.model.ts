// Slots W4 (Bauauftrag Slots-Wochenplan v2, Abschnitt W4): Stammschichten als Blöcke. Reine Funktionen, testbar.
// In der Datenbank bleibt es eine Zeile je Stunde (Entscheidung 8); die Oberfläche fasst sie zusammen.

import type { RpcFehler } from '@/lib/supabase/sessionRpc'
import type { SlotsCoaches, SlotZeit, Stammschicht } from '@/types/slotplan'
import { wocheVerschieben, dieseWoche } from '@/components/edvance/wochenNavigation.model'

export type CoachDaten = SlotsCoaches['coaches'][number]

export type Block = {
  /** Stabil für React-Keys: Wochentag, Raum und erste Stammschicht. */
  schluessel: string
  wochentag: number
  raumId: string
  raumName: string
  /** Ids aller Stunden des Blocks in Uhrzeit-Reihenfolge (für Raum ändern und Entfernen). */
  ids: string[]
  zeitIds: string[]
  beginn: string
  ende: string
  /** Stammplätze in diesem Raum zu diesen Zeiten: Summe je Stunde (ein Kind in zwei Stunden zählt zweimal). */
  stammplaetze: number
  /** Gemeinsames Ende aller Stunden, null = offen. */
  gueltigBis: string | null
  /** Beginnt der Block erst nach dem Tag der angezeigten Woche: sein Beginn, sonst null. */
  ab: string | null
}

/** ISO-Tag plus n Tage. */
export function tagPlus(isoTag: string, n: number): string {
  const [y, m, d] = isoTag.split('-').map(Number)
  const x = new Date(Date.UTC(y, m - 1, d + n))
  return x.toISOString().slice(0, 10)
}

/** Standard für „gültig ab“ beim Raum ändern und Entfernen: nächster Montag. */
export function naechsterMontag(jetzt: Date = new Date()): string {
  return wocheVerschieben(dieseWoche(jetzt), 1)
}

const gueltigAm = (s: Stammschicht, tag: string): boolean => s.gueltig_ab <= tag && (s.gueltig_bis === null || s.gueltig_bis >= tag)

/**
 * Blöcke eines Coaches für die Woche ab `montag` (Entscheidung 1). Je Wochentag zählt, was am Tag dieser Woche gilt;
 * `slots_coaches` liefert auch künftige Schichten (gueltig_bis ≥ Montag), die erst später beginnen. Diese bilden eigene
 * Blöcke mit `ab`. Aufeinanderfolgend heißt: benachbarte Uhrzeiten in der Liste der aktiven `zeiten` (nicht +60 min).
 * Eine Lücke, ein anderer Raum, ein anderes Ende (gueltig_bis) oder ein anderer Beginn (künftig) trennt.
 */
export function bloeckeBilden(schichten: Stammschicht[], zeiten: SlotZeit[], montag: string): Block[] {
  const index = new Map(zeiten.map((z, i) => [z.id, i]))
  const zeilen = schichten
    .map((s) => {
      const tag = tagPlus(montag, s.wochentag - 1)
      return { s, ab: gueltigAm(s, tag) ? null : s.gueltig_ab > tag ? s.gueltig_ab : undefined, i: index.get(s.zeit_id) ?? -1 }
    })
    .filter((x): x is { s: Stammschicht; ab: string | null; i: number } => x.ab !== undefined)
    .sort((a, b) => (a.ab ?? '').localeCompare(b.ab ?? '') || a.s.wochentag - b.s.wochentag
      || a.s.raum_id.localeCompare(b.s.raum_id) || a.i - b.i || a.s.beginn.localeCompare(b.s.beginn))

  const bloecke: (Block & { letzterIndex: number })[] = []
  for (const { s, ab, i } of zeilen) {
    const vor = bloecke[bloecke.length - 1]
    const passt = vor && vor.ab === ab && vor.wochentag === s.wochentag && vor.raumId === s.raum_id
      && vor.gueltigBis === s.gueltig_bis && i >= 0 && vor.letzterIndex >= 0 && i === vor.letzterIndex + 1
    const ende = i >= 0 ? zeiten[i].ende : s.beginn
    if (passt) {
      vor.ids.push(s.id)
      vor.zeitIds.push(s.zeit_id)
      vor.ende = ende
      vor.stammplaetze += s.kinder
      vor.letzterIndex = i
    } else {
      bloecke.push({
        schluessel: `${ab ?? ''}-${s.wochentag}-${s.raum_id}-${s.id}`, wochentag: s.wochentag, raumId: s.raum_id,
        raumName: s.raum_name, ids: [s.id], zeitIds: [s.zeit_id], beginn: s.beginn, ende, stammplaetze: s.kinder,
        gueltigBis: s.gueltig_bis, ab, letzterIndex: i,
      })
    }
  }
  return bloecke
    .map(({ letzterIndex: _, ...b }) => b)
    .sort((a, b) => (a.ab === null ? 0 : 1) - (b.ab === null ? 0 : 1) || a.wochentag - b.wochentag
      || a.beginn.localeCompare(b.beginn) || (a.ab ?? '').localeCompare(b.ab ?? ''))
}

/** Anfangswert für „gültig ab“: nächster Montag, bei einem künftigen Block frühestens dessen Beginn. */
export function standardAb(block: Block, montag: string = naechsterMontag()): string {
  return block.ab && block.ab > montag ? block.ab : montag
}

export type Besetzt = { beginn: string; coach: string | null }

/**
 * Entscheidung 3: Ist der Zielraum ab `ab` zu einer der Zeiten des Blocks schon mit einer Schicht belegt? Wie in
 * stammschicht_raum_wechseln: jede andere Schicht im Zielraum am selben Wochentag und zur selben Uhrzeit, die am
 * Datum `ab` oder später noch gilt (gueltig_bis offen oder ≥ ab).
 */
export function zielraumBesetzt(block: Block, zielRaumId: string, ab: string, coaches: CoachDaten[]): Besetzt[] {
  const treffer: Besetzt[] = []
  for (const c of coaches) {
    for (const s of c.stammschichten) {
      if (s.raum_id !== zielRaumId || s.wochentag !== block.wochentag || !block.zeitIds.includes(s.zeit_id)) continue
      if (block.ids.includes(s.id) || (s.gueltig_bis !== null && s.gueltig_bis < ab)) continue
      if (!treffer.some((t) => t.beginn === s.beginn)) treffer.push({ beginn: s.beginn, coach: c.name })
    }
  }
  return treffer.sort((a, b) => a.beginn.localeCompare(b.beginn))
}

export type Satz = { schluessel: string; werte: Record<string, string | number> }

/** Uhrzeit aus einem Hinweis wie 'raum:16:00' bzw. 'coach:16:00'. */
function hinweis(f: RpcFehler): { art: string; beginn: string } | null {
  const h = f.hint ?? ''
  const i = h.indexOf(':')
  return i > 0 ? { art: h.slice(0, i), beginn: h.slice(i + 1) } : null
}

/** Schicht eines Wochentags und einer Uhrzeit in den geladenen Daten (für den Konfliktsatz). */
function schichtUm(coaches: CoachDaten[], wochentag: number, beginn: string, passt: (c: CoachDaten, s: Stammschicht) => boolean): { c: CoachDaten; s: Stammschicht } | null {
  for (const c of coaches) {
    const s = c.stammschichten.find((x) => x.wochentag === wochentag && x.beginn === beginn && passt(c, x))
    if (s) return { c, s }
  }
  return null
}

/**
 * Entscheidung 2: Konflikt aus stammschicht_block_anlegen als Satz mit Uhrzeit. SL009 'raum:HH:MM' → wer den Raum
 * dann schon hat, 'coach:HH:MM' → in welchem Raum der Coach dann schon ist; Coach bzw. Raum aus slots_coaches.
 * Ohne Treffer ein Satz nur mit Uhrzeit. null = kein Konflikt dieser Art (dann slotsFehlerSchluessel).
 */
export function konfliktSatzAnlegen(
  f: RpcFehler, eingabe: { coachId: string; wochentag: number; raumId: string }, coaches: CoachDaten[], namen: { raum: string; coach: string },
): Satz | null {
  const h = f.code === 'SL009' ? hinweis(f) : null
  if (!h) return null
  if (h.art === 'raum') {
    const t = schichtUm(coaches, eingabe.wochentag, h.beginn, (_, s) => s.raum_id === eingabe.raumId)
    return t?.c.name
      ? { schluessel: 'coaches2.konflikt.raum', werte: { raum: namen.raum, beginn: h.beginn, coach: t.c.name } }
      : { schluessel: 'coaches2.konflikt.raumOhneName', werte: { raum: namen.raum, beginn: h.beginn } }
  }
  if (h.art === 'coach') {
    const t = schichtUm(coaches, eingabe.wochentag, h.beginn, (c) => c.id === eingabe.coachId)
    return t
      ? { schluessel: 'coaches2.konflikt.coach', werte: { coach: namen.coach, beginn: h.beginn, raum: t.s.raum_name } }
      : { schluessel: 'coaches2.konflikt.coachOhneRaum', werte: { coach: namen.coach, beginn: h.beginn } }
  }
  return null
}

/** Fehler aus stammschicht_raum_wechseln mit Uhrzeit als Satz (SL009 / SL001 'raum:HH:MM'), sonst null. */
export function konfliktSatzWechsel(f: RpcFehler, block: Block, zielRaumId: string, zielName: string, coaches: CoachDaten[]): Satz | null {
  const h = hinweis(f)
  if (!h || h.art !== 'raum') return null
  if (f.code === 'SL001') return { schluessel: 'coaches2.konflikt.voll', werte: { raum: zielName, beginn: h.beginn } }
  if (f.code !== 'SL009') return null
  const t = schichtUm(coaches, block.wochentag, h.beginn, (_, s) => s.raum_id === zielRaumId && !block.ids.includes(s.id))
  return t?.c.name
    ? { schluessel: 'coaches2.konflikt.raum', werte: { raum: zielName, beginn: h.beginn, coach: t.c.name } }
    : { schluessel: 'coaches2.konflikt.raumOhneName', werte: { raum: zielName, beginn: h.beginn } }
}
