// Session-Rahmen C2: echte Antworten (coach_raum_live, coach_kind_detail, session_briefing,
// satz_vorschlaege, A1) → Ansichtsmodell der Coach-Live-Sicht. Rein und testbar; die Seite
// bleibt wie in C1. Was der Server (noch) nicht liefert, bleibt leer statt erfunden.
// C3: Pfad-Vorschlag, Heute, Grund mit Zahl, alle Kernideen und der Warm-up-Beleg aus coach_kind_detail
// (coachLiveSchublade.ts); sie gibt es nur fuer das Kind mit offener Schublade.

import type {
  CoachLiveKind,
  CoachLiveRaum,
  KachelMeta,
  LiveAufgabeDetail,
  LiveInfo,
  LiveZeitpunkt,
  Taetigkeit,
  ZielNotiz,
  ZielZeile,
} from '@/types/coachLive'
import type { LernpfadEintrag, SkillPruefung, ZielFertigkeit } from '@/types/lernpfad'
import type { BriefingKind, KindRaum, SatzVorschlag } from '@/types/sessionC2'
import type { KindDetail, RaumLive, StellschraubeWert } from '@/types/sessionLive'
import { tageBis, zeitleisteAusSnapshot } from './coachLiveLogik'
import {
  briefingAus,
  checkoutAus,
  ergebnisMarken,
  imBlickAus,
  masteryAus,
  sequenzAus,
  signalAus,
  stufeAusKlasse,
  vornameAus,
  zeitpunktAus,
} from './coachLiveTeile'
import { grundAus, heuteAus, pfadVorschlagAus, sequenzMitKernideen, warmupBelegAus } from './coachLiveSchublade'

/** Was neben coach_raum_live geladen wurde. Detail nur fuer das Kind mit offener Schublade. */
export type LiveZusatz = {
  detail: { kindId: string; detail: KindDetail; ziel: ZielFertigkeit[]; pruefung: SkillPruefung | null; lernpfad: LernpfadEintrag | null } | null
  briefing: BriefingKind[]
  satz: Record<string, SatzVorschlag[]>
  themen: Map<string, string>
  /** Client-Zustand: „nicht erschienen“ bestaetigt (offene-punkte-c1 Nr. 4). */
  nichtErschienen: Set<string>
  /** Client-Zustand: Pfad-Entscheidung zum Aendern geoeffnet, seit (ISO). */
  pfadGeoeffnet: Record<string, string>
}

type Kontext = { raum: RaumLive; zeitpunkt: LiveZeitpunkt; e: Record<string, StellschraubeWert>; z: LiveZusatz; label: (k: string) => string | null }

function taetigkeitAus(k: KindRaum, c: Kontext): Taetigkeit {
  const phase = k.phase
  if (phase === null || phase === 'checkin') return { art: 'checkin' }
  if (phase === 'warmup') {
    const von = Number(c.e.warmup_aufgaben ?? 3)
    const nr = k.aufgabe?.phase === 'warmup' ? k.aufgabe.nr_in_phase : 0
    return nr >= von && k.ergebnisfolge.filter((p) => p.phase === 'warmup').length >= von ? { art: 'warmupFertig' } : { art: 'warmup', nr, von }
  }
  const seq = k.erklaersequenz
  if (phase === 'kern' && seq && !(seq.stand === 'richtig' && seq.kernideen_fertig >= seq.kernideen)) {
    return { art: 'erklaerung', kernidee: seq.kernidee_nr, von: seq.kernideen }
  }
  return k.pfad_entscheidung?.entscheidung === 'tiefer' ? { art: 'tiefer' } : { art: 'ueben' }
}

function metaAus(k: KindRaum, c: Kontext): KachelMeta | null {
  if (k.mastery_heute.at(-1)?.stand_coach === 'vertagt') return { art: 'vertagt' }
  if (c.zeitpunkt === 'warmup' && k.pfad_entscheidung) {
    return { art: k.pfad_entscheidung.entscheidung === 'tiefer' ? 'kernTiefer' : 'kernPlan' }
  }
  const phase = k.phase
  const folge = k.ergebnisfolge.filter((p) => p.phase === phase)
  if (folge.length === 0) return null
  if (k.hinweise_genutzt > 0) return { art: 'hinweise', anzahl: k.hinweise_genutzt }
  const richtig = folge.filter((p) => p.ergebnis === 'richtig').length
  return richtig === folge.length ? { art: 'ohneHinweis', anzahl: richtig } : { art: 'richtig', richtig, von: folge.length, ueberZiel: null }
}

function infoAus(k: KindRaum, c: Kontext): CoachLiveKind['info'] {
  const stimmung = k.signale.find((s) => s.grund === 'stimmung')
  if (stimmung) return { inhalt: { art: 'stimmung' }, quittierbar: true }
  if (k.klassenarbeit_datum) {
    const tage = tageBis(k.klassenarbeit_datum, c.raum.stand)
    const inhalt: LiveInfo = { art: 'klassenarbeit', datum: k.klassenarbeit_datum, tage }
    if (tage >= 0 && tage <= Number(c.e.ka_tage ?? 7)) return { inhalt, quittierbar: false }
  }
  if (k.tablet_seit && Date.parse(k.tablet_seit) - Date.parse(c.raum.session.scheduled_at) > 5 * 60_000) {
    return { inhalt: { art: 'spaet', ankunft: k.tablet_seit }, quittierbar: false }
  }
  return null
}

function zielZeilen(k: KindRaum, ziel: ZielFertigkeit[]): ZielZeile[] {
  const aktuell = k.schritt?.skill_key ?? k.aufgabe?.skill_key ?? null
  return ziel.map((f) => {
    const notizen: ZielNotiz[] = []
    if (f.rolle === 'voraussetzung' || f.rolle === 'voraussetzung_sicher') notizen.push({ art: 'voraussetzung' })
    if (f.pruefung_faellig) notizen.push({ art: 'pruefungFaellig' })
    const heute = k.mastery_heute.find((m) => m.skill_key === f.skill_key)
    if (heute) notizen.push(heute.stand_coach === 'gemeistert' ? { art: 'bestaetigt', zeit: heute.am } : { art: 'vertagt' })
    if (f.skill_key === aktuell) {
      const folge = k.ergebnisfolge.filter((p) => p.phase === 'kern')
      if (folge.length > 0) notizen.push({ art: 'heute', richtig: folge.filter((p) => p.ergebnis === 'richtig').length, von: folge.length })
    }
    return { skillKey: f.skill_key, label: f.label, stand: heute?.stand_coach === 'gemeistert' ? 'gemeistert' : f.stand, notizen }
  })
}

const text = (payload: Record<string, unknown> | undefined): string => {
  const p = payload ?? {}
  for (const k of ['prompt', 'question', 'text']) if (typeof p[k] === 'string') return p[k] as string
  return ''
}

const eingabeText = (eingabe: unknown): string =>
  typeof eingabe === 'string' ? eingabe : eingabe === null || eingabe === undefined ? '' : JSON.stringify(eingabe)

function aufgabeAus(k: KindRaum, d: KindDetail, c: Kontext): LiveAufgabeDetail | null {
  const a = d.aufgabe_detail
  if (!a) return null
  const nr = k.aufgabe?.nr_in_phase ?? 1
  const versuche = d.versuche.filter((v) => v.task_id === a.task_id)
  const letzte = versuche.at(-1)
  return {
    kopf: k.aufgabe?.phase === 'warmup' ? { art: 'warmup', nr, von: Number(c.e.warmup_aufgaben ?? 3) } : { art: 'aufgabe', nr },
    skill: k.schritt?.skill_label ?? (k.aufgabe?.skill_key ? (c.label(k.aufgabe.skill_key) ?? '') : ''),
    text: text(a.payload),
    musterloesung: (a.musterloesung ?? '').split('\n').map((z) => z.trim()).filter(Boolean),
    letzteEingabe: letzte
      ? { eingabe: eingabeText(letzte.eingabe), ergebnis: letzte.ergebnis, nachHinweis: letzte.hinweisstufe_max > 0 ? letzte.hinweisstufe_max : null }
      : null,
    ohneEingabeMin: null,
  }
}

function kindAus(k: KindRaum, c: Kontext): CoachLiveKind {
  const name = k.name ?? ''
  const klasse = k.klasse ?? 0
  const d = c.z.detail?.kindId === k.student_id ? c.z.detail : null
  const heute = d?.detail.heute ?? []
  const mastery = masteryAus(k, d?.pruefung ?? null, d?.lernpfad ?? null, c.raum.stand, (sk) => warmupBelegAus(heute, sk))
  const signale = k.signale.map((s) => signalAus(s, c.label))
  const geoeffnet = c.z.pfadGeoeffnet[k.student_id]
  const pfad = k.pfad_entscheidung && (!geoeffnet || Date.parse(k.pfad_entscheidung.zeit) > Date.parse(geoeffnet))
    ? { art: k.pfad_entscheidung.entscheidung, zeit: k.pfad_entscheidung.zeit }
    : null
  const seq = sequenzMitKernideen(sequenzAus(k), d?.detail.erklaer_kernideen ?? [])
  const letzterFehler = d?.detail.versuche.filter((v) => v.fehlbild_slug).at(-1)
  const themaKey = k.ziel_thema_key ?? k.schulthema_key
  const schulthema = k.schulthema_key ? (c.z.themen.get(k.schulthema_key) ?? k.schulthema_key) : null
  return {
    id: k.student_id,
    name,
    vorname: vornameAus(name),
    klasse,
    stufe: stufeAusKlasse(klasse),
    tablet: k.tablet_nr,
    tabletSeit: k.tablet_seit,
    nichtErschienen: c.z.nichtErschienen.has(k.student_id),
    phase: k.phase,
    status: mastery?.entscheidung?.art === 'gemeistert' ? 'gemeistert' : k.status,
    taetigkeit: taetigkeitAus(k, c),
    skill: k.schritt?.skill_label ?? seq?.siehtGerade ?? '',
    ergebnisfolge: ergebnisMarken(k.ergebnisfolge, k.aufgabe !== null && k.phase !== 'checkin'),
    sequenzBalken: seq ? seq.kernideen.map((x) => x.stand) : null,
    aufgabeNr: k.aufgabe?.nr_in_phase ?? null,
    meta: metaAus(k, c),
    signale,
    ziel: {
      fallVorschlag: k.fall_vorschlag,
      fallCoach: k.fall_coach,
      themaKey,
      themaLabel: k.ziel_thema_label ?? (themaKey ? (c.z.themen.get(themaKey) ?? null) : null),
      klassenarbeit: k.klassenarbeit_datum ? { datum: k.klassenarbeit_datum, themaLabel: null } : null,
      lsaLuecke: c.z.briefing.find((b) => b.student_id === k.student_id)?.naechste_luecke?.label ?? null,
    },
    zielFertigkeiten: d ? zielZeilen(k, d.ziel) : [],
    aufgabe: d ? aufgabeAus(k, d.detail, c) : null,
    versuche: (d?.detail.versuche ?? [])
      .filter((v) => v.ergebnis !== 'richtig' && v.fehlbild_klartext)
      .map((v, i) => ({ kopf: { art: 'versuch', nr: i + 1 }, eingabe: eingabeText(v.eingabe), fehlbild: v.fehlbild_klartext ?? '' })),
    hinweise: (d?.detail.hinweise ?? [])
      .filter((h) => h.task_id === k.aufgabe?.task_id)
      .map((h) => ({ stufe: h.stufe, text: h.text ?? '' })),
    erklaersequenz: seq,
    masteryKandidat: mastery,
    pruefungAufTablet: k.pruefung_auf_tablet !== null,
    pfadVorschlag: pfadVorschlagAus(d?.detail.pfad_vorschlag, k.pfad_entscheidung, geoeffnet),
    pfadEntscheidung: pfad,
    info: infoAus(k, c),
    eingreifen: {
      empfohlen: k.status === 'haengt' ? 2 : 0,
      fehlbild: letzterFehler?.fehlbild_slug ? { slug: letzterFehler.fehlbild_slug, klartext: letzterFehler.fehlbild_klartext ?? '' } : null,
      eingriffe: k.eingriffe,
    },
    heute: heuteAus(heute),
    grundLetzterSchritt: grundAus(k, d?.detail.schritt_details ?? null, c.e),
    checkin: {
      fertig: k.checkin_fertig,
      stimmung: k.stimmung,
      klassenarbeit: k.klassenarbeit_datum ? { datum: k.klassenarbeit_datum, themaLabel: null } : null,
      themaAntwort: k.thema_antwort,
      stichwort: k.thema_stichwort,
      themaBisher: schulthema,
    },
    checkout: checkoutAus(k, c.z.satz[k.student_id] ?? [], c.raum.session.scheduled_at, c.e, c.label),
    briefing: briefingAus(c.z.briefing.find((b) => b.student_id === k.student_id)),
  }
}

/** Der ganze Raum. `jetzt` ist die Serverzeit der Abfrage (coach_raum_live.stand). */
export function raumAus(raum: RaumLive, z: LiveZusatz): CoachLiveRaum {
  const e = raum.session.einstellungen ?? {}
  const zeitpunkt = zeitpunktAus(raum.session, raum.stand)
  const labels = new Map<string, string>()
  for (const k of raum.kinder) {
    if (k.schritt?.skill_key && k.schritt.skill_label) labels.set(k.schritt.skill_key, k.schritt.skill_label)
    if (k.mastery_kandidat) labels.set(k.mastery_kandidat.skill_key, k.mastery_kandidat.label)
    if (k.erklaersequenz) labels.set(k.erklaersequenz.skill_key, k.erklaersequenz.label)
  }
  const c: Kontext = { raum, zeitpunkt, e, z, label: (key) => labels.get(key) ?? null }
  const kinder = raum.kinder.map((k) => kindAus(k, c))
  const klassen = kinder.map((k) => k.klasse).filter((x) => x > 0)
  return {
    zeitpunkt,
    session: {
      id: raum.session.id,
      beginn: raum.session.scheduled_at,
      gestartet: raum.session.gestartet_am,
      jetzt: raum.stand,
      raum: raum.session.room ?? '',
      coachName: raum.session.coach_name ?? '',
      fach: 'mathematik',
      klassen: klassen.length > 0 ? [Math.min(...klassen), Math.max(...klassen)] : [0, 0],
      plaetze: 5,
      abgeschlossen: raum.session.beendet_am,
      status: raum.session.status,
      testlauf: raum.session.testlauf === true,
    },
    einstellungen: e,
    zeitleiste: zeitleisteAusSnapshot(e),
    kinder,
    signale: kinder.flatMap((k) => k.signale),
    masteryEntschieden: raum.kinder.reduce((s, k) => s + k.mastery_heute.length, 0),
    erklaersequenzenFertig: raum.kinder.filter((k) => k.erklaersequenz && k.erklaersequenz.kernideen_fertig >= k.erklaersequenz.kernideen).length,
    imBlick: imBlickAus(z.briefing),
    stand: raum.stand,
  }
}
