// Session-Rahmen C2: Bausteine der Abbildung echter Antworten auf das Ansichtsmodell der
// Coach-Live-Sicht (Herkunftstabelle in offene-punkte-c1). Rein: ohne Supabase, ohne React.

import type {
  BlickPunkt,
  BriefingTag,
  ErgebnisMarke,
  Kernidee,
  LiveBriefing,
  LiveCheckout,
  LiveErklaersequenz,
  LiveMasteryKandidat,
  LiveSignal,
  LiveSignalGrund,
  LiveZeitpunkt,
  MasteryBeleg,
} from '@/types/coachLive'
import type { LernpfadEintrag, SkillPruefung } from '@/types/lernpfad'
import type { BriefingKind, KindRaum, SatzVorschlag } from '@/types/sessionC2'
import type { ErgebnisPunkt, RaumSignal, StellschraubeWert } from '@/types/sessionLive'
import type { Stufe } from '@/types/themen'
import { SESSION_MINUTEN, zeitleisteAusSnapshot } from './coachLiveLogik'

const zahl = (e: Record<string, StellschraubeWert>, k: string, standard: number): number => {
  const w = e[k]
  return typeof w === 'number' && Number.isFinite(w) ? w : standard
}

export function stufeAusKlasse(klasse: number): Stufe {
  if (klasse <= 6) return 'erprobung'
  return klasse <= 10 ? 'erste' : 'zweite'
}

export const vornameAus = (name: string): string => name.trim().split(/\s+/)[0] ?? ''

/**
 * Zeitpunkt der Ansicht: vor dem Start „vorher“, nach dem Abschluss „danach“. Dazwischen nach der
 * Uhr wie session_uhr_phase (Start + Phasen aus dem Snapshot); nach 60 Minuten „danach“.
 */
export function zeitpunktAus(r: { status: string; gestartet_am: string | null; einstellungen: Record<string, StellschraubeWert> }, jetzt: string): LiveZeitpunkt {
  if (r.status === 'upcoming' || r.gestartet_am === null) return r.status === 'done' ? 'danach' : 'vorher'
  if (r.status === 'done') return 'danach'
  const minute = (Date.parse(jetzt) - Date.parse(r.gestartet_am)) / 60_000
  let ende = 0
  for (const seg of zeitleisteAusSnapshot(r.einstellungen)) {
    ende += seg.minuten
    if (minute < ende) return seg.phase
  }
  return minute < SESSION_MINUTEN ? 'checkout' : 'danach'
}

/** Punkte der Kachel: je Antwort richtig/falsch, Hinweis vor der Antwort, dazu die offene Aufgabe. */
export function ergebnisMarken(folge: ErgebnisPunkt[], offen: boolean): ErgebnisMarke[] {
  const marken: ErgebnisMarke[] = folge.map((p) =>
    p.hinweisstufe_max > 0 ? 'hinweis' : p.ergebnis === 'richtig' ? 'richtig' : 'falsch',
  )
  if (offen) marken.push('aktuell')
  return marken.slice(-10)
}

const SIGNAL_GRUND: Record<string, LiveSignalGrund> = {
  kandidat: 'kandidat',
  entscheidung: 'warmup_luecke',
  fehlversuche: 'fehlversuche',
  ohne_eingabe: 'ohne_eingabe',
  erklaerrunden: 'erklaerrunden',
  stimmung: 'stimmung',
}

/** raum_signale → Signal der Seite. Gemeldete Signale tragen einen Satz als grund; dann zaehlt die Art. */
export function signalAus(s: RaumSignal, label: (key: string) => string | null): LiveSignal {
  const d = s.details ?? {}
  const n = (k: string): number | null => (typeof d[k] === 'number' ? (d[k] as number) : null)
  const skillKey = typeof d.skill_key === 'string' ? d.skill_key : null
  const grund = SIGNAL_GRUND[s.grund] ?? (s.art === 'haengt' ? 'fehlversuche' : (SIGNAL_GRUND[s.art] ?? 'stimmung'))
  return {
    kindId: s.student_id,
    art: s.art,
    grund,
    seit: s.seit,
    wert: n('anzahl') ?? n('minuten') ?? n('runden'),
    skill: typeof d.label === 'string' ? d.label : skillKey ? (label(skillKey) ?? skillKey) : null,
    aufgabeNr: null,
  }
}

/** Erklaersequenz: Kernideen vor der aktuellen sind sicher, die aktuelle laeuft. */
export function sequenzAus(k: KindRaum): LiveErklaersequenz | null {
  const e = k.erklaersequenz
  if (!e || e.stand === 'richtig' && e.kernideen_fertig >= e.kernideen) return null
  const kernideen: Kernidee[] = Array.from({ length: Math.max(e.kernideen, e.kernidee_nr) }, (_, i) => {
    const nr = i + 1
    const stand: Kernidee['stand'] = nr < e.kernidee_nr ? 'sicher' : nr === e.kernidee_nr ? 'laeuft' : 'offen'
    return { text: nr === e.kernidee_nr ? e.kernidee_titel : null, stand, runde: nr === e.kernidee_nr ? e.runde : 1, fehlbild: null, variante: e.variante }
  })
  return { kernideen, aktuell: e.kernidee_nr, variante: e.variante, siehtGerade: e.kernidee_titel }
}

/** Mastery-Kandidat aus coach_raum_live, Pruefgespraech (A1) und Belegen aus dem Lernpfad. */
export function masteryAus(
  k: KindRaum,
  pruefung: SkillPruefung | null,
  lernpfad: LernpfadEintrag | null,
  jetzt: string,
  warmupHeute: (skillKey: string) => MasteryBeleg | null = () => null,
): LiveMasteryKandidat | null {
  const heute = k.mastery_heute.at(-1) ?? null
  const kandidat = k.mastery_kandidat
  const skillKey = kandidat?.skill_key ?? heute?.skill_key
  if (!skillKey) return null
  const belege: MasteryBeleg[] = (lernpfad?.skill_key === skillKey ? lernpfad.belege : [])
    .slice(-3)
    .map((b) => ({ art: 'session', datum: b.am, richtig: b.richtig_ohne_hinweis, von: b.gesamt }))
  // C3: Warm-up von heute, wenn der Skill heute im Warm-up dran war (nur mit offener Schublade).
  const warmup = warmupHeute(skillKey)
  if (warmup) belege.push(warmup)
  const erster = lernpfad?.skill_key === skillKey ? lernpfad.belege[0] : undefined
  if (erster) belege.push({ art: 'abstand', tage: Math.floor((Date.parse(jetzt) - Date.parse(erster.am)) / 86_400_000) })
  return {
    skillKey,
    label: kandidat?.label ?? heute?.label ?? skillKey,
    themaLabel: k.ziel_thema_label ?? '',
    klasse: k.klasse ?? 0,
    belege,
    frage: pruefung?.frage ?? '',
    erwartung: pruefung?.erwartung ?? '',
    kriterium: pruefung?.kriterium ?? '',
    entscheidung: heute ? { art: heute.stand_coach, grund: heute.grund, zeit: heute.am, von: heute.von ?? '' } : null,
  }
}

/** Zwei Termine fuer Quest A (Entscheidung 21), 16:00 Uhr Berliner Zeit. */
export function questAVorschlaege(beginn: string, einstellungen: Record<string, StellschraubeWert>): string[] {
  if (einstellungen.home_quests_aktiv !== true) return []
  const abstand = zahl(einstellungen, 'quest_a_abstand_tage', 2)
  const tag = new Date(beginn)
  return [abstand, abstand + 1].map((d) => {
    const t = new Date(Date.UTC(tag.getUTCFullYear(), tag.getUTCMonth(), tag.getUTCDate() + d, 14))
    // 16:00 in Berlin ist 14:00 UTC (Sommerzeit) bzw. 15:00 UTC (Winterzeit).
    const teile = new Intl.DateTimeFormat('en-GB', { timeZone: 'Europe/Berlin', hour: '2-digit', hourCycle: 'h23' }).formatToParts(t)
    const stunde = Number(teile.find((x) => x.type === 'hour')?.value ?? 16)
    t.setUTCHours(14 + (16 - stunde))
    return t.toISOString()
  })
}

/** Check-out je Kind aus Antworten, Eingriffen, session_kind_abschluss und den Satzvorschlaegen. */
export function checkoutAus(
  k: KindRaum,
  vorschlaege: SatzVorschlag[],
  beginn: string,
  einstellungen: Record<string, StellschraubeWert>,
  label: (key: string) => string | null,
): LiveCheckout {
  const exit = k.ergebnisfolge.filter((p) => p.phase === 'checkout')
  const a = k.abschluss
  const texte = vorschlaege.map((v) => v.text)
  const aufgaben = new Set(k.ergebnisfolge.map((p) => p.task_id)).size
  return {
    exit: a?.exit_ergebnis ?? { richtig: exit.filter((p) => p.ergebnis === 'richtig').length, gesamt: exit.length },
    aufgaben,
    richtig: k.ergebnisfolge.filter((p) => p.ergebnis === 'richtig').length,
    eingriffe: k.eingriffe.length,
    schwerpunkt: k.schritt?.skill_label ?? (k.aufgabe?.skill_key ? (label(k.aufgabe.skill_key) ?? '') : ''),
    satzVorschlaege: texte,
    satz: a?.satz_text ?? texte[0] ?? '',
    gesagt: a?.satz_gesagt ?? false,
    questsAktiv: einstellungen.home_quests_aktiv === true,
    questA: { termin: a?.quest_termin ?? null, von: a?.quest_von ?? null },
    questAVorschlaege: questAVorschlaege(beginn, einstellungen),
    questB: k.quest_b ? { termin: k.quest_b, paketKlassenarbeit: false } : null,
    notiz: a?.notiz ?? '',
    flags: { eltern: a?.flag_eltern ?? false, pfad: a?.flag_pfad ?? false },
  }
}

const LEERES_BRIEFING: LiveBriefing = {
  tags: [], thema: { label: '', quelle: 'schulthema', seit: null }, plan: { skill: '', art: null }, imBlick: null, notiz: null, quests: null,
}

/** Briefing je Kind aus session_briefing (Kinder ohne laufenden Vertrag fehlen dort). */
export function briefingAus(b: BriefingKind | undefined): LiveBriefing {
  if (!b) return LEERES_BRIEFING
  const tags: BriefingTag[] = []
  if (b.pruefungen_faellig.length > 0) tags.push({ art: 'mastery' })
  if (b.schulthema?.nachfragen) tags.push({ art: 'themaAlt', wochen: Math.floor(b.schulthema.tage / 7) })
  if (b.klassenarbeit) tags.push({ art: 'klassenarbeit', datum: b.klassenarbeit.datum })
  if (b.letzte_session && b.letzte_session.signale > 0) tags.push({ art: 'signale', anzahl: b.letzte_session.signale, am: b.letzte_session.am })
  if (b.erste_session && b.naechste_luecke?.quelle === 'lsa') tags.push({ art: 'ersteNachLsa' })
  const l = b.letzte_session
  const quests = b.quests_woche.erledigt + b.quests_woche.offen
  return {
    tags,
    thema: { label: b.schulthema?.label ?? b.schulthema?.thema_key ?? '', quelle: b.schulthema ? 'schulthema' : 'lsa', seit: b.schulthema?.seit ?? null },
    plan: { skill: b.naechste_luecke?.label ?? '', art: b.naechste_luecke ? (b.erste_session ? 'neu' : 'weiter') : null },
    imBlick: b.flags_offen.length > 0 ? b.flags_offen.map((f) => f.flag).join(', ') : null,
    notiz: l?.notiz ? { text: l.notiz, von: l.coach_name ?? '', am: l.am } : null,
    quests: quests > 0 ? { erledigt: b.quests_woche.erledigt, von: quests } : null,
  }
}

/** „Heute im Blick“ fuer den Raum: faellige Pruefungen, Klassenarbeiten, erste Session nach der LSA. */
export function imBlickAus(briefing: BriefingKind[]): BlickPunkt[] {
  const punkte: BlickPunkt[] = []
  for (const b of briefing) {
    if (b.pruefungen_faellig.length > 0) {
      punkte.push({ art: 'mastery', kindId: b.student_id, detail: b.pruefungen_faellig.map((p) => p.label).join(', '), datum: null })
    }
    if (b.klassenarbeit) {
      punkte.push({ art: 'klassenarbeit', kindId: b.student_id, detail: b.klassenarbeit.label ?? '', datum: b.klassenarbeit.datum })
    }
    if (b.erste_session && b.naechste_luecke?.quelle === 'lsa') {
      punkte.push({ art: 'lsa', kindId: b.student_id, detail: b.naechste_luecke.label, datum: null })
    }
  }
  return punkte
}
