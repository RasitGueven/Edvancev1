// BEISPIELMODUS: baut aus den Beispieldaten und dem lokalen Zustand (Entscheidungen
// des Coaches in dieser Sitzung) das Ansichtsmodell. Entspricht tileData, queue und
// zielBlk im Dummy. Faellt mit C2 weg; die Seite merkt davon nichts.

import type {
  CoachLiveKind,
  CoachLiveRaum,
  LiveSignal,
  LiveZeitpunkt,
  MasteryEntscheidungLive,
  ZielZeile,
} from '@/types/coachLive'
import type { EingriffStufe, SessionFall, SignalArt } from '@/types/sessionLive'
import {
  BEISPIEL_ANKUNFT,
  BEISPIEL_BRIEFING,
  BEISPIEL_CHECKIN,
  BEISPIEL_CHECKOUT,
  BEISPIEL_EINSTELLUNGEN,
  BEISPIEL_FALL,
  BEISPIEL_IM_BLICK,
  BEISPIEL_KINDER,
  BEISPIEL_LSA_LUECKE,
  BEISPIEL_MASTERY,
  BEISPIEL_PFAD,
  BEISPIEL_SESSION,
  BEISPIEL_TABLET,
  BEISPIEL_TABLET_CHECKIN,
  BEISPIEL_THEMA_LIVE,
  BEISPIEL_ZEIT,
  BEISPIEL_ZIEL,
  themaLabel,
} from './coachLiveBeispiel'
import { BEISPIEL_KERN, BEISPIEL_KERN_TIEFER, BEISPIEL_WARMUP, type BeispielLive } from './coachLiveBeispielLive'
import { themaAltWochen, zeitleisteAusSnapshot, ZEITPUNKTE } from './coachLiveLogik'

/** Was der Coach in dieser Sitzung entschieden hat (nur im Speicher). */
export type BeispielZustand = {
  zeitpunkt: LiveZeitpunkt
  /** Explizit gesetzte Tablets; sonst gilt die Vorgabe des Zeitpunkts. */
  tablets: Record<string, number | null>
  fall: Record<string, SessionFall>
  thema: Record<string, string>
  pfad: Record<string, { art: 'tiefer' | 'plan'; zeit: string }>
  mastery: Record<string, MasteryEntscheidungLive>
  /** `${kindId}:${art}` */
  erledigt: string[]
  eingriffe: { kindId: string; stufe: EingriffStufe; zeit: string }[]
  satz: Record<string, string>
  gesagt: string[]
  notiz: Record<string, string>
  flags: Record<string, { eltern: boolean; pfad: boolean }>
  questA: Record<string, string>
  nichtErschienen: string[]
  abgeschlossen: string | null
}

export function neuerBeispielZustand(): BeispielZustand {
  return {
    zeitpunkt: 'kern', tablets: {}, fall: {}, thema: {}, pfad: {}, mastery: {}, erledigt: [], eingriffe: [],
    satz: {}, gesagt: [], notiz: {}, flags: {}, questA: {}, nichtErschienen: [], abgeschlossen: null,
  }
}

const ab = (z: LiveZeitpunkt, von: LiveZeitpunkt): boolean => ZEITPUNKTE.indexOf(z) >= ZEITPUNKTE.indexOf(von)

function tabletVon(id: string, z: BeispielZustand): number | null {
  if (id in z.tablets) return z.tablets[id]
  if (z.zeitpunkt === 'vorher') return null
  return z.zeitpunkt === 'checkin' ? BEISPIEL_TABLET_CHECKIN[id] : BEISPIEL_TABLET[id]
}

/** Live-Daten des Kindes im Zeitpunkt, mit Emirs Pfad und Milas Mastery (Dummy: tileData). */
function liveVon(id: string, z: BeispielZustand): BeispielLive | null {
  if (z.zeitpunkt === 'warmup') return BEISPIEL_WARMUP[id]
  if (z.zeitpunkt !== 'kern') return null
  if (z.pfad[id]?.art === 'tiefer' && BEISPIEL_KERN_TIEFER[id]) return BEISPIEL_KERN_TIEFER[id]
  return BEISPIEL_KERN[id]
}

function offen(s: LiveSignal, z: BeispielZustand): boolean {
  if (z.erledigt.includes(`${s.kindId}:${s.art}`)) return false
  if (s.art === 'kandidat' && z.mastery[s.kindId]) return false
  if (s.art === 'entscheidung' && z.pfad[s.kindId]) return false
  return true
}

function zielZeilen(id: string, z: BeispielZustand): ZielZeile[] {
  const zeilen = BEISPIEL_ZIEL[id].map((r) => ({ ...r }))
  if (z.pfad[id]?.art === 'tiefer' && id === 'emir') {
    zeilen[0] = { ...zeilen[0], stand: 'aktiv', notizen: [{ art: 'tieferGesetzt' }] }
    zeilen[1] = { ...zeilen[1], stand: 'offen', notizen: [{ art: 'danach' }] }
  }
  const m = z.mastery[id]
  const i = zeilen.findIndex((r) => r.skillKey === BEISPIEL_MASTERY[id]?.skillKey)
  if (m && i >= 0) {
    zeilen[i] = m.art === 'gemeistert'
      ? { ...zeilen[i], stand: 'gemeistert', notizen: [{ art: 'bestaetigt', zeit: m.zeit }] }
      : { ...zeilen[i], stand: 'sicher', notizen: [{ art: 'vertagt' }] }
  }
  return zeilen
}

function baueKind(basis: (typeof BEISPIEL_KINDER)[number], z: BeispielZustand): CoachLiveKind {
  const { id } = basis
  const jetzt = BEISPIEL_ZEIT[z.zeitpunkt]
  const tablet = tabletVon(id, z)
  const live = liveVon(id, z)
  const signale = (live?.signale ?? []).filter((s) => offen(s, z))
  const mastery = BEISPIEL_MASTERY[id] ? { ...BEISPIEL_MASTERY[id], entscheidung: z.mastery[id] ?? null } : null
  const pfadBasis = BEISPIEL_PFAD[id]
  const pfad = z.pfad[id]

  // Status nur aus Zustaenden; Gruen erst nach der Bestaetigung (Entscheidung 6).
  const rangfolge: SignalArt[] = ['kandidat', 'entscheidung', 'haengt', 'hinweis']
  let status: CoachLiveKind['status'] = rangfolge.find((a) => signale.some((s) => s.art === a)) ?? 'laeuft'
  let meta = live?.meta ?? null
  if (live && z.zeitpunkt === 'warmup' && pfad && pfadBasis) meta = { art: pfad.art === 'tiefer' ? 'kernTiefer' : 'kernPlan' }
  if (mastery?.entscheidung?.art === 'gemeistert') status = 'gemeistert'
  else if (mastery?.entscheidung?.art === 'vertagt') meta = { art: 'vertagt' }
  if (z.erledigt.includes(`${id}:haengt`) && live?.signale.some((s) => s.art === 'haengt')) meta = { art: 'signalErledigt' }
  if (z.erledigt.includes(`${id}:hinweis`) && live?.signale.some((s) => s.art === 'hinweis')) meta = { art: 'angesprochen' }

  const checkin = { ...BEISPIEL_CHECKIN[id], fertig: id !== 'deniz' || ab(z.zeitpunkt, 'kern') }
  const neuOffen = checkin.themaAntwort === 'neu' && !z.thema[id]
  let themaKey = z.thema[id] ?? (neuOffen ? null : checkin.themaBisher)
  if (themaKey === null && ab(z.zeitpunkt, 'warmup')) themaKey = BEISPIEL_THEMA_LIVE

  const co = BEISPIEL_CHECKOUT[id]
  const vorschlaege = mastery?.entscheidung?.art === 'gemeistert' && co.satzNachMastery ? co.satzNachMastery : co.satzVorschlaege
  const briefing = BEISPIEL_BRIEFING[id]
  const alt = themaAltWochen(briefing.thema.seit, jetzt, Number(BEISPIEL_EINSTELLUNGEN.thema_alt_tage))

  return {
    ...basis,
    tablet,
    tabletSeit: tablet === null ? null : BEISPIEL_ANKUNFT[id],
    nichtErschienen: z.nichtErschienen.includes(id),
    phase: z.zeitpunkt === 'vorher' || z.zeitpunkt === 'danach' ? null : z.zeitpunkt,
    status: live ? status : 'laeuft',
    taetigkeit: live?.taetigkeit ?? { art: 'checkin' },
    skill: live?.skill ?? '',
    ergebnisfolge: live?.ergebnisfolge ?? [],
    sequenzBalken: live?.sequenzBalken ?? null,
    aufgabeNr: live?.aufgabeNr ?? null,
    meta,
    signale,
    ziel: {
      fallVorschlag: BEISPIEL_FALL[id],
      fallCoach: z.fall[id] ?? null,
      themaKey,
      themaLabel: themaLabel(themaKey),
      klassenarbeit: checkin.klassenarbeit,
      lsaLuecke: BEISPIEL_LSA_LUECKE[id],
    },
    zielFertigkeiten: zielZeilen(id, z),
    aufgabe: live?.aufgabe ?? null,
    versuche: live?.versuche ?? [],
    hinweise: live?.hinweise ?? [],
    erklaersequenz: live?.erklaersequenz ?? null,
    masteryKandidat: mastery,
    pfadVorschlag: pfadBasis && z.zeitpunkt === 'warmup'
      ? { ...pfadBasis, entscheidung: pfad ? { ...pfad, von: BEISPIEL_SESSION.coachVorname } : null }
      : null,
    info: live?.info ? { inhalt: live.info, quittierbar: signale.some((s) => s.art === 'hinweis') } : null,
    eingreifen: {
      empfohlen: live?.empfohlen ?? 0,
      fehlbild: live?.fehlbild ?? null,
      eingriffe: z.eingriffe.filter((e) => e.kindId === id).map(({ stufe, zeit }) => ({ stufe, zeit })),
    },
    heute: live?.heute ?? [],
    grundLetzterSchritt: live?.grund ?? null,
    checkin,
    checkout: {
      ...co,
      satzVorschlaege: vorschlaege,
      satz: z.satz[id] ?? vorschlaege[0],
      gesagt: z.gesagt.includes(id),
      questA: z.questA[id] ? { termin: z.questA[id], von: 'coach' } : co.questA,
      notiz: z.notiz[id] ?? co.notiz,
      flags: z.flags[id] ?? { eltern: false, pfad: false },
    },
    briefing: alt === null ? briefing : { ...briefing, tags: [{ art: 'themaAlt', wochen: alt }, ...briefing.tags] },
  }
}

export function baueBeispielRaum(sessionId: string, z: BeispielZustand): CoachLiveRaum {
  const kinder = BEISPIEL_KINDER.map((k) => baueKind(k, z))
  return {
    beispiel: true,
    zeitpunkt: z.zeitpunkt,
    session: {
      id: sessionId,
      beginn: BEISPIEL_SESSION.beginn,
      jetzt: BEISPIEL_ZEIT[z.zeitpunkt],
      raum: BEISPIEL_SESSION.raum,
      coachName: BEISPIEL_SESSION.coachName,
      fach: BEISPIEL_SESSION.fach,
      klassen: BEISPIEL_SESSION.klassen,
      plaetze: BEISPIEL_SESSION.plaetze,
      abgeschlossen: z.abgeschlossen,
    },
    einstellungen: BEISPIEL_EINSTELLUNGEN,
    zeitleiste: zeitleisteAusSnapshot(BEISPIEL_EINSTELLUNGEN),
    kinder,
    signale: kinder.flatMap((k) => k.signale),
    masteryEntschieden: Object.keys(z.mastery).length,
    erklaersequenzenFertig: ab(z.zeitpunkt, 'checkout') ? 1 : 0,
    imBlick: BEISPIEL_IM_BLICK,
    stand: BEISPIEL_ZEIT[z.zeitpunkt],
  }
}

export { BEISPIEL_SESSION }
