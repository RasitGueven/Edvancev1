// Startseite „Heute“: reine Auswahl- und Sortierlogik der Arbeitslisten.
// Gerechnet wird hier nichts, was die Datenbank schon liefert: Ampel und
// Rückstand kommen aus board_schueler(), Ausläufer und Verzüge aus
// auslaufende()/imVerzug() (src/lib/vertrag/menue.ts).

import type { BoardSchueler, Lead, LeadStatus, SkillThema, Stufe, VertragMitLead } from '@/types'
import type { AufgabeFuerAdmin } from '@/lib/supabase/heute'

/** Wie viele Einträge eine Liste höchstens zeigt (Entscheidung 7). */
export const MAX_ZEILEN = 3

/** Ab so vielen Tagen wird die Pille „seit n Tagen“ amber. */
export const WARTEN_AMBER_TAGE = 7

/** Wie der Reiter „Offene Anträge“: alles vor der Unterschrift, abgelehnte nicht. */
export const OFFENER_ANTRAG = ['in_vorbereitung', 'unterschrift_ausstehend']

const zeit = (iso: string | null): number => (iso ? new Date(iso).getTime() : 0)

/** Neue Leads, älteste zuerst. */
export function neueLeads(leads: Lead[]): Lead[] {
  return leads.filter((l) => l.status === 'new').sort((a, b) => zeit(a.created_at) - zeit(b.created_at))
}

/** Dieselben Status wie die Board-Spalte „Termin vereinbart“ (leads/boardModel). */
const TERMIN_STATUS: LeadStatus[] = ['contacted', 'onboarding_scheduled']

/** Vereinbarte Erstgespräche ab Beginn des heutigen Tags, nächstes zuerst. */
export function erstgespraeche(leads: Lead[], tagesBeginn: string): Lead[] {
  const ab = zeit(tagesBeginn)
  return leads
    .filter((l) => l.ist_test !== true && TERMIN_STATUS.includes(l.status) && l.erstgespraech_at !== null && zeit(l.erstgespraech_at) >= ab)
    .sort((a, b) => zeit(a.erstgespraech_at) - zeit(b.erstgespraech_at))
}

/** Freigegebene und fertige Analysen; die fertigen zuerst, je am längsten wartend zuerst. */
export function lsaLeads(leads: Lead[]): Lead[] {
  const rang = (l: Lead): number => (l.status === 'lsa_fertig' ? 0 : 1)
  const seit = (l: Lead): number => zeit(l.status === 'lsa_fertig' ? l.lsa_fertig_at : l.lsa_freigegeben_at) || zeit(l.created_at)
  return leads
    // Test-Leads zaehlen nicht (Entscheidung 27).
    .filter((l) => l.ist_test !== true && (l.status === 'lsa_fertig' || l.status === 'lsa_freigegeben'))
    .sort((a, b) => rang(a) - rang(b) || seit(a) - seit(b))
}

/** Offene Anträge, älteste zuerst. */
export function offeneAntraege(vertraege: VertragMitLead[]): VertragMitLead[] {
  return vertraege
    .filter((v) => OFFENER_ANTRAG.includes(v.status))
    .sort((a, b) => zeit(a.created_at) - zeit(b.created_at))
}

/** Aktive Akten mit Ampel deutlich, dann leicht; je größter Rückstand zuerst. */
export function imRueckstand(liste: BoardSchueler[]): BoardSchueler[] {
  const rang = (s: BoardSchueler): number => (s.ampel === 'deutlich_im_rueckstand' ? 0 : 1)
  return liste
    .filter((s) => s.zustand === 'aktiv' && (s.ampel === 'deutlich_im_rueckstand' || s.ampel === 'leicht_im_rueckstand'))
    .sort((a, b) => rang(a) - rang(b) || (b.rueckstand ?? 0) - (a.rueckstand ?? 0))
}

/** Eine Gruppe „Inhalte freigeben“: ein Thema mit seinen Aufgaben im Status review. */
export type FreigabeGruppe = {
  /** thema_key, oder null für Aufgaben ohne Thema. */
  themaKey: string | null
  label: string | null
  stufe: Stufe | null
  anzahl: number
}

/** Aufgaben im Status review, gruppiert nach Thema (skill_key → skill_thema); größte Gruppe zuerst. */
export function freigabeGruppen(aufgaben: AufgabeFuerAdmin[], skillThemen: SkillThema[]): FreigabeGruppe[] {
  const themaVon = new Map(skillThemen.map((s) => [s.skill_key, s]))
  const gruppen = new Map<string, FreigabeGruppe>()
  for (const a of aufgaben) {
    if (a.status !== 'review') continue
    const thema = a.skill_key ? themaVon.get(a.skill_key) : undefined
    const key = thema?.thema_key ?? ''
    const g = gruppen.get(key) ?? {
      themaKey: thema?.thema_key ?? null,
      label: thema?.label ?? null,
      stufe: thema?.stufe ?? null,
      anzahl: 0,
    }
    g.anzahl += 1
    gruppen.set(key, g)
  }
  return [...gruppen.values()].sort(
    (a, b) => b.anzahl - a.anzahl || (a.label ?? '￿').localeCompare(b.label ?? '￿', 'de'),
  )
}

/**
 * Stunde in Berlin (0–23). Über formatToParts: format() liefert in de-DE
 * „10 Uhr“, und Number() daraus wäre NaN.
 */
export function berlinStunde(now: Date): number {
  const teil = new Intl.DateTimeFormat('de-DE', { timeZone: 'Europe/Berlin', hour: '2-digit', hourCycle: 'h23' })
    .formatToParts(now)
    .find((p) => p.type === 'hour')
  return Number(teil?.value ?? 0)
}

/** Lenas Rückfragen (Status rueckfrage, Lena-Board). */
export function rueckfragen(aufgaben: AufgabeFuerAdmin[]): number {
  return rueckfrageIds(aufgaben).length
}

/** Die Rückfragen als Reihe für die Admin-Prüfansicht. */
export function rueckfrageIds(aufgaben: AufgabeFuerAdmin[]): string[] {
  return aufgaben.filter((a) => a.status === 'rueckfrage').map((a) => a.id)
}

/** Tageszeit für den Gruß, nach der Berliner Stunde. */
export function tageszeit(stunde: number): 'morgen' | 'tag' | 'abend' {
  if (stunde < 11) return 'morgen'
  if (stunde < 18) return 'tag'
  return 'abend'
}

/** Vorname = erstes Wort des Namens. */
export function vorname(name: string | null | undefined): string | null {
  const erstes = (name ?? '').trim().split(/\s+/)[0]
  return erstes ? erstes : null
}
