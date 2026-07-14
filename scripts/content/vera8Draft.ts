// Bauplan fuer den Draft-Import der Neuextraktion (data/vera8_v2.json → tasks).
//
// Reine Abbildung, kein DB-Zugriff: JSON rein, tasks-Zeile + Loesung + Flags raus.
// Damit ist der Bau testbar (vera8Draft.test.ts) und der Import-Lauf duenn.
//
// DIE DREI VERTRAEGE, gegen die hier GEBAUT wird — nicht gehofft:
//   lsa_parts_valid  (P02): >=2 Teilaufgaben, kind in (short_input|mc), Prompt da,
//                           MC mit >=2 Optionen, KEIN Loesungsfeld.
//   lsa_table_valid  (F01): {headers:[string], rows:[[string]]}, Zeilenbreite ==
//                           Header-Breite, alle Zellen Strings.
//   tasks_question_payload_no_solution (T1b): kein correct/accepted/… im Payload.
// Was einen dieser Vertraege verletzt, wird hier ABGEWIESEN und geflaggt — es geht
// entschaerft (ohne Tabelle, ohne parts) als Draft rein, statt am CHECK zu sterben.
// Der CHECK ist die Zusage, nicht der Gegner.
//
// WAS NICHT GESETZT WIRD: curriculum_grade. Das ist der Stoffanker, er wird von
// Hand gepflegt (A01). Aus `klasse: 8` liesse er sich nur raten — 8 ist die
// Herkunft des Tests, nicht der geprueffte Stoff.

/** Leitidee → Inhaltsfeld → Cluster. Die Leitidee steht in der Kommentierung. */
const LEITIDEE_TO_INHALTSFELD: Record<string, string> = {
  '1': 'arithmetik_algebra', // Zahl
  '2': 'geometrie', // Messen
  '3': 'geometrie', // Raum und Form
  '4': 'funktionen', // Funktionaler Zusammenhang
  '5': 'stochastik', // Daten und Zufall
}

export const CLUSTER_BY_INHALTSFELD: Record<string, string> = {
  arithmetik_algebra: 'Zahl & Rechnen',
  funktionen: 'Algebra & Funktionen',
  geometrie: 'Geometrie & Messen',
  stochastik: 'Daten & Zufall',
}

/** KMK-Kompetenz → NRW-Prozesskompetenz. Uebernommen aus scripts/content/enrich_full.py
 *  — dieselbe Zuordnung wie im C02-Lauf, damit competency_process eine Sprache spricht. */
const K_TO_NRW: Record<string, string> = {
  K1: 'arg',
  K2: 'pro',
  K3: 'mod',
  K4: 'kom',
  K5: 'ope',
  K6: 'kom',
}

/** Zeitbudget-Platzhalter. tasks_multipart_check verlangt est_duration_sec bei
 *  MULTI_PART — ohne Wert kaeme das Item gar nicht in die Tabelle. Die Quelle nennt
 *  keine Zeit, also ein sichtbarer Platzhalter statt einer erfundenen Zahl: er wird
 *  geflaggt und im Tool geprueft. */
const SEC_PER_PART = 90

export type V2Part = {
  nr: number
  kind: string
  prompt?: string | null
  unit?: string | null
  options?: { id: string; label: string }[] | null
  correct_answers?: string[] | null
  afb_raw?: string | null
  afb?: number | null
  kompetenzen?: string[] | null
  leitidee?: string | null
}

export type V2Asset = {
  kind: string
  verweis?: string | null
  lizenz_hinweis?: string | null
  grafik_gedeckt?: boolean
  begruendung?: string | null
}

export type V2Item = {
  id: string
  slug?: string
  titel?: string
  klasse?: number | null
  is_diagnostic?: boolean
  input_type?: string | null
  stem?: { text?: string | null; table?: { header?: unknown; rows?: unknown } | null } | null
  parts?: V2Part[] | null
  assets?: V2Asset[] | null
  _flags?: string[] | null
  _grounding?: Record<string, { gate?: string; quelle?: string; zitat?: string; hinweis?: string }> | null
}

export type TaskTable = { headers: string[]; rows: string[][] }

export type BuiltRow = {
  source_ref: string
  content_type: 'exercise'
  status: 'draft'
  is_active: boolean
  is_diagnostic: boolean
  title: string | null
  question: string | null
  input_type: string | null
  unit: string | null
  afb: string | null
  class_level: number | null
  est_duration_sec: number | null
  competency_content: string | null
  competency_process: string | null
  parts: unknown[]
  assets: { url: string; alt: string }[]
  question_payload: Record<string, unknown> | null
}

export type Built = {
  sourceRef: string
  titel: string
  row: BuiltRow
  inhaltsfeld: string | null
  /** NRW-Codes der Prozesskompetenzen — der DB-Lauf loest sie zu Namen/IDs auf. */
  processCodes: string[]
  /** Flach: string[]. Multi-Part: {"1": [...]}. null = keine Loesung belegt. */
  answers: string[] | Record<string, string[]> | null
  /** Der Beleg, auf den sich die Loesung stuetzt. Geht nach task_solutions.solution
   *  — die Server-Only-Zone, die NUR Coach/Admin ueber task_solution_get sieht. */
  solutionBeleg: string | null
  /** Was der Import an diesem Item nicht sauber abbilden konnte. Landet im
   *  Beleg-Index und damit im Tool. */
  importFlags: string[]
  /** Teilaufgaben, die der P02-Vertrag nicht halten kann (free_text u.a.) —
   *  read-only in den Index, damit der Pfleger sie sieht statt sie zu verlieren. */
  droppedParts: V2Part[]
  /** Alles gesetzt, was der Import setzen KANN? Dann fehlt nur noch die
   *  Handarbeit (Stoffanker, Alt-Texte) bis zur Pool-Faehigkeit. */
  poolReadyAfterCare: boolean
}

const trim = (s: unknown): string => (typeof s === 'string' ? s.trim() : '')
const isNumeric = (s: string): boolean => /^-?\d+([.,]\d+)?$/.test(s.trim())

/** Spiegelt lsa_table_valid. Streng mit Absicht: eine kaputte Tabelle ist eine
 *  kaputte Extraktion, kein Grenzfall. */
export function toTable(raw: unknown): TaskTable | null {
  if (!raw || typeof raw !== 'object') return null
  const t = raw as { header?: unknown; headers?: unknown; rows?: unknown }
  const headers = t.headers ?? t.header // v2 schreibt `header`, F01 verlangt `headers`
  if (!Array.isArray(headers) || headers.length === 0) return null
  if (!headers.every((h) => typeof h === 'string' && h.trim() !== '')) return null
  if (!Array.isArray(t.rows) || t.rows.length === 0) return null
  const rows: string[][] = []
  for (const r of t.rows) {
    if (!Array.isArray(r) || r.length !== headers.length) return null
    if (!r.every((c) => typeof c === 'string')) return null
    rows.push(r as string[])
  }
  return { headers: headers as string[], rows }
}

/** Spiegelt lsa_parts_valid. */
export function partsValid(parts: V2Part[]): boolean {
  if (parts.length < 2) return false
  const nrs = new Set<number>()
  for (const p of parts) {
    if (!Number.isInteger(p.nr) || p.nr < 1) return false
    if (p.kind !== 'short_input' && p.kind !== 'mc') return false
    if (trim(p.prompt) === '') return false
    if (p.kind === 'mc' && (p.options?.length ?? 0) < 2) return false
    nrs.add(p.nr)
  }
  return nrs.size === parts.length
}

function inhaltsfeldOf(parts: V2Part[]): { feld: string | null; ambig: boolean } {
  const felder = new Set<string>()
  for (const p of parts) {
    const l = trim(p.leitidee)
    const m = l.match(/\(L(\d)\)/) ?? l.match(/^(\d)\./)
    const feld = m ? LEITIDEE_TO_INHALTSFELD[m[1]] : undefined
    if (feld) felder.add(feld)
  }
  if (felder.size === 1) return { feld: [...felder][0], ambig: false }
  return { feld: null, ambig: felder.size > 1 }
}

const afbOf = (p: V2Part): string | null => {
  const a = trim(p.afb_raw).toUpperCase()
  return a === 'I' || a === 'II' || a === 'III' ? a : null
}

/** Nur Grafiken, die der eingebettete Lizenzhinweis WOERTLICH deckt.
 *  Das pauschale `lizenz_status` am Item ist fuer Abbildungen falsch — es sagt
 *  "CC BY", waehrend die Lizenzzeile im Item nur Text und Teilaufgaben nennt. */
export function coveredAssets(assets: V2Asset[]): { kept: V2Asset[]; dropped: V2Asset[] } {
  const kept: V2Asset[] = []
  const dropped: V2Asset[] = []
  for (const a of assets) {
    const deckt = /grafik/i.test(a.lizenz_hinweis ?? '')
    if (deckt && trim(a.verweis) !== '') kept.push(a)
    else dropped.push(a)
  }
  return { kept, dropped }
}

/** Der Loesungsbeleg als Klartext. Geht NICHT in den oeffentlichen Index —
 *  er nennt die Loesung. */
function solutionBeleg(item: V2Item): string | null {
  const g = item._grounding ?? {}
  const zeilen: string[] = []
  for (const [feld, beleg] of Object.entries(g)) {
    if (!/correct_answers/.test(feld)) continue
    const zitat = trim(beleg?.zitat)
    if (!zitat) continue
    const quelle = trim(beleg?.quelle) || 'Quelle unbekannt'
    const gate = trim(beleg?.gate)
    zeilen.push(`[${feld}${gate ? ` · ${gate}` : ''}] ${quelle}:\n${zitat}`)
  }
  return zeilen.length ? zeilen.join('\n\n') : null
}

export function buildItem(item: V2Item): Built {
  const parts = item.parts ?? []
  const flags: string[] = []
  const stemText = trim(item.stem?.text)
  const table = item.stem?.table ? toTable(item.stem.table) : null
  if (item.stem?.table && !table) {
    flags.push('IMPORT: Tabelle verletzt den F01-Vertrag (ragged rows / Nicht-Strings) — nicht uebernommen.')
  }

  const { feld, ambig } = inhaltsfeldOf(parts)
  if (ambig) flags.push('IMPORT: mehrere Leitideen im Item — Cluster nicht eindeutig, cluster_id bleibt leer.')
  else if (!feld && parts.length) flags.push('IMPORT: keine Leitidee gelesen — cluster_id bleibt leer.')

  const processCodes = [
    ...new Set(parts.flatMap((p) => (p.kompetenzen ?? []).map((k) => K_TO_NRW[k]).filter(Boolean))),
  ]

  const { kept, dropped } = coveredAssets(item.assets ?? [])
  if (dropped.length) {
    flags.push(
      `IMPORT: ${dropped.length} Abbildung(en) weggelassen — die Lizenzzeile im Item nennt keine "Grafik", ` +
        'IQBs CC BY deckt sie damit nicht.',
    )
  }

  const wantsMulti = item.input_type === 'MULTI_PART'
  const multiOk = wantsMulti && partsValid(parts) && stemText !== ''
  const droppedParts: V2Part[] = []

  let inputType: string | null = null
  let question: string | null = null
  let unit: string | null = null
  let afb: string | null = null
  let estDuration: number | null = null
  let rowParts: unknown[] = []
  let answers: string[] | Record<string, string[]> | null = null
  const payload: Record<string, unknown> = {}

  if (multiOk) {
    inputType = 'MULTI_PART'
    question = stemText
    estDuration = SEC_PER_PART * parts.length
    flags.push(
      `IMPORT: est_duration_sec = ${estDuration}s (${SEC_PER_PART}s je Teilaufgabe) ist ein Platzhalter — ` +
        'die Quelle nennt keine Bearbeitungszeit. Im Tool pruefen.',
    )
    rowParts = parts.map((p) => ({
      nr: p.nr,
      kind: p.kind,
      prompt: trim(p.prompt),
      ...(trim(p.unit) ? { unit: trim(p.unit) } : {}),
      ...(p.kind === 'mc' && p.options ? { options: p.options } : {}),
      ...(afbOf(p) ? { afb: afbOf(p) } : {}),
      ...(feld ? { competency_content: feld } : {}),
    }))
    const byNr: Record<string, string[]> = {}
    for (const p of parts) {
      const a = (p.correct_answers ?? []).map((x) => String(x)).filter((x) => x.trim() !== '')
      if (a.length) byNr[String(p.nr)] = a
    }
    answers = Object.keys(byNr).length ? byNr : null
  } else if (wantsMulti) {
    // P02 kann diese Teilaufgaben nicht halten (free_text, leerer Prompt, MC ohne
    // Optionen, fehlender Stamm). Das Item kommt als Rumpf rein — die Teilaufgaben
    // gehen NICHT verloren, sie stehen read-only im Beleg-Index.
    droppedParts.push(...parts)
    const gruende = [
      parts.length < 2 ? 'weniger als 2 Teilaufgaben' : null,
      parts.some((p) => p.kind === 'free_text') ? 'Freitext-Teilaufgabe (P02 laesst nur short_input|mc)' : null,
      parts.some((p) => trim(p.prompt) === '') ? 'leerer Teilaufgaben-Prompt' : null,
      parts.some((p) => p.kind === 'mc' && (p.options?.length ?? 0) < 2) ? 'MC ohne Optionen' : null,
      stemText === '' ? 'kein Stamm (MULTI_PART verlangt einen)' : null,
    ].filter(Boolean)
    flags.push(
      `IMPORT: ${parts.length} Teilaufgabe(n) nicht gespeichert — ${gruende.join(', ')}. ` +
        'Sie stehen unten im Quellenbeleg und muessen im Tool neu angelegt werden.',
    )
    question = stemText || null
  } else if (parts.length === 1) {
    const p = parts[0]
    const prompt = trim(p.prompt)
    question = [stemText, prompt].filter(Boolean).join('\n\n') || null
    unit = trim(p.unit) || null
    afb = afbOf(p)
    const a = (p.correct_answers ?? []).map((x) => String(x)).filter((x) => x.trim() !== '')

    if (item.input_type === 'MC') {
      inputType = 'MC'
      if ((p.options?.length ?? 0) >= 2) payload.input_type = 'MC'
      if ((p.options?.length ?? 0) >= 2) payload.options = p.options
      else flags.push('IMPORT: MC ohne verwertbare Optionen — input_type bleibt MC, Optionen im Tool nachtragen.')
      answers = a.length ? a : null
    } else if (item.input_type === 'FREE_TEXT') {
      // Freitext ist nicht auto-korrigierbar und gehoert nicht in den LSA-Pool.
      // Der Erwartungshorizont wird als Loesungstext gefuehrt, NICHT als
      // correct_answers — sonst wuerde lsa_is_correct daran zu messen versuchen.
      inputType = 'FREE_TEXT'
      answers = null
    } else if (item.input_type === 'SHORT_INPUT') {
      inputType = a.length && a.every(isNumeric) ? 'NUMERIC' : 'SHORT_TEXT'
      if (!a.length) {
        flags.push(
          'IMPORT: keine Loesung belegt — input_type auf SHORT_TEXT gesetzt (Rueckfall). ' +
            'Mit Loesung ist NUMERIC oft richtiger: im Tool pruefen.',
        )
      }
      answers = a.length ? a : null
    }
  } else if (parts.length === 0) {
    question = stemText || null
    flags.push('IMPORT: keine Teilaufgabe gelesen — Rumpf importiert, Aufgabe im Tool aufbauen.')
  }

  if (table) payload.table = table

  const freeTextExpectation =
    item.input_type === 'FREE_TEXT' && parts[0]?.correct_answers?.length
      ? `Erwartungshorizont (Freitext, nicht auto-korrigierbar):\n${parts[0].correct_answers!.join('\n')}`
      : null
  const beleg = [freeTextExpectation, solutionBeleg(item)].filter(Boolean).join('\n\n') || null

  const row: BuiltRow = {
    source_ref: item.id,
    content_type: 'exercise',
    status: 'draft',
    is_active: true,
    is_diagnostic: item.is_diagnostic ?? false,
    title: trim(item.titel) || null,
    question,
    input_type: inputType,
    unit,
    afb,
    class_level: item.klasse ?? null,
    est_duration_sec: estDuration,
    competency_content: multiOk ? null : feld, // bei Multi-Part traegt die Teilaufgabe die Kompetenz (P02)
    competency_process: null, // der DB-Lauf setzt den Klartext aus process_competencies
    parts: rowParts,
    assets: kept.map((a) => ({ url: a.verweis!, alt: '' })),
    question_payload: Object.keys(payload).length ? payload : null,
  }

  const answersComplete = multiOk
    ? parts.every((p) => (answers as Record<string, string[]> | null)?.[String(p.nr)]?.length)
    : Array.isArray(answers) && answers.length > 0

  const poolReadyAfterCare =
    Boolean(question) &&
    inputType !== null &&
    inputType !== 'FREE_TEXT' &&
    feld !== null &&
    answersComplete &&
    (multiOk ? parts.every((p) => afbOf(p) !== null) : afb !== null)

  return {
    sourceRef: item.id,
    titel: trim(item.titel) || item.id,
    row,
    inhaltsfeld: feld,
    processCodes,
    answers,
    solutionBeleg: beleg,
    importFlags: flags,
    droppedParts,
    poolReadyAfterCare,
  }
}
