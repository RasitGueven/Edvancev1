// Eltern-Bericht v4 — der Fahrplan (Bauauftrag V4, Entscheidungen 1–3; L5, Entscheidungen 8–10). Reine Rechnung
// für Seite 1, die Leiste der Seiten 2–5 und die Präsentation.
//
// Erste Station = das aktuelle Thema (Plan-Eintrag an der aktuellen Position, dieselbe Quelle wie kommtNoch).
//
// Folge unbekannt (L5, der Normalfall): Die Stationen sind die kommenden Plan-Themen dieses Schuljahrs, jedes Thema
// einmal, höchstens vier, ohne Nummer einer Klassenarbeit; gibt es weniger, wird aus dem Plan der nächsten Klasse
// aufgefüllt (Trenner „Klasse k“).
//
// Folge bekannt (Arbeiten mit Nummer aus ka_folge_lead): Die Stationen sind die Arbeiten mit ihrer Nummer im
// Schuljahr, höchstens vier kommende; Themen ohne bekannte Arbeit folgen danach ohne Nummer.
//
// Signal je kommender Station: fehlt (ein Bereich mit Übungsbedarf betrifft das Thema), erfuellt (nur sichere), ohne
// (keiner); bei einer Arbeit das schlechteste ihrer Themen. Ohne Plan oder ohne aktuelles Thema: null — die Seiten
// fallen dann auf v3 zurück.

import { nummerierteArbeiten, schlechtestes, type KaArbeit } from '@/lib/report/elternbericht/kaFolge'
import { kommtNoch } from '@/lib/report/elternbericht/lernweg'
import { aktuellePosition } from '@/lib/report/elternbericht/plan'
import type {
  EbBereich,
  EbFahrplan,
  EbFahrtStand,
  EbSignal,
  EbStation,
  KlassenarbeitStatus,
  LernPlan,
  ReportKlassenarbeit,
} from '@/types'

/** Höchstens so viele kommende Stationen. */
export const KOMMENDE_MAX = 4

export type FahrplanEingabe = {
  plan: LernPlan | null
  /** Thema der Sitzung (lsa_sessions.thema_key); null ohne Thema. */
  themaKey: string | null
  /** Datum der Sitzung, für die Position ohne Thema und als Bezug für „Datum vorbei“. */
  datum: string | null
  klassenarbeitStatus: KlassenarbeitStatus | null
  /** signaleJeThema(...) aus lueckenweg.ts. */
  signale: ReadonlyMap<string, { sitzt: readonly EbBereich[]; fehlt: readonly EbBereich[] }>
  /** leads.letzte_klassenarbeit_note; nur bei 'geschrieben' gezeigt. */
  note?: number | null
  /** L5: Mathearbeiten dieses Schuljahrs (ka_folge_lead); ohne Arbeit mit Nummer gilt die Folge als unbekannt. */
  arbeiten?: readonly ReportKlassenarbeit[]
}

type Thema = { themaKey: string; titel: string; halbjahr: 1 | 2 | null }

export function signalVon(
  signale: FahrplanEingabe['signale'],
  themaKey: string,
): EbSignal {
  const s = signale.get(themaKey)
  if (s && s.fehlt.length > 0) return 'fehlt'
  return s && s.sitzt.length > 0 ? 'erfuellt' : 'ohne'
}

/** Eine Station zu einem Thema ohne bekannte Arbeit. */
const themaStation = (
  p: Thema,
  nummer: number,
  stand: EbFahrtStand,
  schuljahr: EbStation['schuljahr'],
  signal: EbSignal | null,
): EbStation => ({
  nummer,
  ka: null,
  themaKey: p.themaKey,
  titel: p.titel,
  themen: [{ themaKey: p.themaKey, titel: p.titel }],
  datum: null,
  halbjahr: p.halbjahr,
  schuljahr,
  stand,
  signal,
  note: null,
})

export function baueFahrplan(e: FahrplanEingabe): EbFahrplan | null {
  const plan = e.plan
  if (!plan) return null
  const pos = aktuellePosition(plan.eintraege, e.themaKey, e.datum)
  const aktuell = pos >= 0 ? plan.eintraege[pos] : null
  if (!aktuell?.themaKey) return null
  const jetzt: Thema = { themaKey: aktuell.themaKey, titel: aktuell.titel, halbjahr: aktuell.halbjahr }

  // Kommende Themen dieses Schuljahrs, jedes einmal und nicht das aktuelle; danach die der nächsten Klasse.
  const gesehen = new Set([aktuell.themaKey])
  const dieses: Thema[] = []
  for (const p of kommtNoch({ plan, themaKey: e.themaKey, datum: e.datum })) {
    if (!p.themaKey || gesehen.has(p.themaKey)) continue
    gesehen.add(p.themaKey)
    dieses.push({ themaKey: p.themaKey, titel: p.titel, halbjahr: p.halbjahr })
  }
  const spaeter: Thema[] = []
  for (const p of plan.naechsteKlasse?.eintraege ?? []) {
    if (!p.themaKey || gesehen.has(p.themaKey)) continue
    gesehen.add(p.themaKey)
    spaeter.push({ themaKey: p.themaKey, titel: p.titel, halbjahr: null })
  }

  const titel = new Map<string, string>()
  for (const p of [...plan.eintraege, ...(plan.naechsteKlasse?.eintraege ?? [])]) {
    if (p.themaKey && !titel.has(p.themaKey)) titel.set(p.themaKey, p.titel)
  }
  const tag = e.datum ? e.datum.slice(0, 10) : null
  const arbeiten = nummerierteArbeiten(e.arbeiten ?? [], titel, tag)

  const teil =
    arbeiten.length > 0
      ? mitFolge(e, jetzt, dieses, spaeter, arbeiten)
      : ohneFolge(e, jetzt, dieses, spaeter)
  const stationen = teil.stationen
  const kommende = stationen.slice(1)
  const halbjahre = new Set(stationen.filter((s) => s.schuljahr === 'dieses').map((s) => s.halbjahr))
  const signale = kommende.map((s) => s.signal)
  return {
    stationen,
    weitere: dieses.filter((p) => !stationen.some((s) => s.themen.some((x) => x.themaKey === p.themaKey))).length,
    halbjahrTrenner: halbjahre.has(1) && halbjahre.has(2),
    klassenTrenner: kommende.some((s) => s.schuljahr === 'naechstes') ? (plan.naechsteKlasse?.klasse ?? null) : null,
    quelle: plan.quelle,
    schulname: plan.schulname,
    satz: signale.includes('fehlt') ? 'fehlt' : signale.includes('erfuellt') ? 'erfuellt' : null,
    folge: teil.folge,
  }
}

/** Folge unbekannt (Entscheidung 9): Plan-Themen ohne Nummer. */
function ohneFolge(
  e: FahrplanEingabe,
  jetzt: Thema,
  dieses: Thema[],
  spaeter: Thema[],
): { stationen: EbStation[]; folge: EbFahrplan['folge'] } {
  const status = e.klassenarbeitStatus
  const erste = {
    ...themaStation(jetzt, 1, status === 'geschrieben' ? 'geschrieben' : status === 'bevorstehend' ? 'steht' : 'aktuell', 'dieses', null),
    note: status === 'geschrieben' ? (e.note ?? null) : null,
  }
  const gezeigt = dieses.slice(0, KOMMENDE_MAX)
  const auffuellen = spaeter.slice(0, KOMMENDE_MAX - gezeigt.length)
  const kommende = [
    ...gezeigt.map((p) => ({ p, schuljahr: 'dieses' as const })),
    ...auffuellen.map((p) => ({ p, schuljahr: 'naechstes' as const })),
  ].map(({ p, schuljahr }, i) =>
    themaStation(p, i + 2, i === 0 ? 'unterricht' : 'danach', schuljahr, signalVon(e.signale, p.themaKey)),
  )
  return { stationen: [erste, ...kommende], folge: 'unbekannt' }
}

/** Folge bekannt (Entscheidung 10): Arbeiten mit Nummer, danach Themen ohne bekannte Arbeit. */
function mitFolge(
  e: FahrplanEingabe,
  jetzt: Thema,
  dieses: Thema[],
  spaeter: Thema[],
  arbeiten: KaArbeit[],
): { stationen: EbStation[]; folge: EbFahrplan['folge'] } {
  const status = e.klassenarbeitStatus
  const halbjahrVon = new Map([jetzt, ...dieses].map((p) => [p.themaKey, p.halbjahr]))
  const a = arbeiten.find((x) => x.themen.some((t) => t.themaKey === jetzt.themaKey)) ?? null
  const geschrieben = status === 'geschrieben' || a?.geschrieben === true
  const erste: EbStation = a
    ? {
        nummer: 1,
        ka: a.nr,
        themaKey: jetzt.themaKey,
        titel: jetzt.titel,
        themen: a.themen,
        datum: a.datum,
        halbjahr: jetzt.halbjahr,
        schuljahr: 'dieses',
        stand: geschrieben ? 'geschrieben' : 'naechste',
        signal: null,
        note: geschrieben ? (a.note ?? e.note ?? null) : null,
      }
    : {
        ...themaStation(jetzt, 1, status === 'geschrieben' ? 'geschrieben' : status === 'bevorstehend' ? 'steht' : 'aktuell', 'dieses', null),
        note: status === 'geschrieben' ? (e.note ?? null) : null,
      }

  // Kommend: nach der aktuellen Arbeit (sonst nach der letzten geschriebenen), mit einem Thema, das noch kommt.
  const ab = a?.nr ?? Math.max(0, ...arbeiten.filter((x) => x.geschrieben).map((x) => x.nr))
  const noch = new Set([...dieses, ...spaeter].map((p) => p.themaKey))
  const kommendeArbeiten = arbeiten.filter((x) => x.nr > ab && x.themen.some((t) => noch.has(t.themaKey)))
  const gezeigt = kommendeArbeiten.slice(0, KOMMENDE_MAX)
  const stationen: EbStation[] = [erste]
  for (const x of gezeigt) {
    const kopf = x.themen[0]
    stationen.push({
      nummer: stationen.length + 1,
      ka: x.nr,
      themaKey: kopf.themaKey,
      titel: kopf.titel,
      themen: x.themen,
      datum: x.datum,
      halbjahr: halbjahrVon.get(kopf.themaKey) ?? null,
      schuljahr: 'dieses',
      stand: stationen.length === 1 && erste.stand !== 'naechste' ? 'naechste' : 'voraussichtlich',
      signal: schlechtestes(x.themen.map((t) => signalVon(e.signale, t.themaKey))),
      note: null,
    })
  }

  // Themen ohne bekannte Arbeit: nach den Arbeiten, ohne Nummer; alle Themen einer Arbeit gelten als vergeben.
  const vergeben = new Set([...(a?.themen ?? []), ...kommendeArbeiten.flatMap((x) => x.themen)].map((t) => t.themaKey))
  const offen = [
    ...dieses.filter((p) => !vergeben.has(p.themaKey)).map((p) => ({ p, schuljahr: 'dieses' as const })),
    ...spaeter.filter((p) => !vergeben.has(p.themaKey)).map((p) => ({ p, schuljahr: 'naechstes' as const })),
  ]
  for (const { p, schuljahr } of offen) {
    if (stationen.length > KOMMENDE_MAX) break
    if (schuljahr === 'naechstes' && kommendeArbeiten.length > gezeigt.length) break
    const stand = stationen.length === 1 ? 'unterricht' : 'danach'
    stationen.push(themaStation(p, stationen.length + 1, stand, schuljahr, signalVon(e.signale, p.themaKey)))
  }

  const genutzt = [a, ...gezeigt].filter((x): x is KaArbeit => x !== null)
  // Keine Arbeit mit Nummer zu sehen (alle schon vorbei): dann ist auch hier keine Folge bekannt.
  const folge = genutzt.length === 0 ? 'unbekannt' : genutzt.some((x) => x.herkunft === 'schule') ? 'schule' : 'eigen'
  return { stationen, folge }
}
