import { describe, expect, it } from 'vitest'

import { TOPIC_UNASSIGNED, buildTopics } from '@/lib/supabase/lsaReport'

/**
 * Die Themenachse des Eltern-Reports (R2).
 *
 * Bis R2 baute getReportData sie ausschließlich aus `lsa_sessions.item_ids`.
 * Adaptive Sitzungen starten mit `'{}'` und lsa_finish trägt nichts nach —
 * dadurch fiel JEDE Antwort auf „ohne Zuordnung", `planned` blieb 0, und der
 * Report zeigte „30 von 0 bearbeitet".
 *
 * Diese Suite hält beides fest: dass die Achse jetzt auch ohne item_ids trägt,
 * UND dass sich für den 'fest'-Modus nichts geändert hat.
 */

const antwort = (
  task_id: string,
  correct: boolean | null,
  duration_ms: number | null = 30000,
) => ({ task_id, correct, duration_ms })

describe('buildTopics — Achse ohne item_ids (adaptiv)', () => {
  it('gruppiert nach competency_content der beantworteten Aufgaben', () => {
    const topics = buildTopics(
      ['t1', 't2', 't3'],
      new Map([
        ['t1', 'arithmetik_algebra'],
        ['t2', 'arithmetik_algebra'],
        ['t3', 'geometrie'],
      ]),
      [antwort('t1', true), antwort('t2', false), antwort('t3', true)],
    )

    expect(topics.map((t) => t.topic)).toEqual(['arithmetik_algebra', 'geometrie'])
    expect(topics[0]).toMatchObject({ planned: 2, answered: 2, correct: 1, skipped: 0 })
    expect(topics[1]).toMatchObject({ planned: 1, answered: 1, correct: 1 })
  })

  it('zählt planned aus der Aufgabenmenge, nicht aus den Antwortzeilen', () => {
    // Ein MULTI_PART-Item erzeugt ZWEI Antwortzeilen zu EINER Aufgabe.
    const topics = buildTopics(
      ['t1'],
      new Map([['t1', 'arithmetik_algebra']]),
      [antwort('t1', false), antwort('t1', true)],
    )

    expect(topics[0]).toMatchObject({ planned: 1, answered: 2, correct: 1 })
    // skipped darf dabei nicht negativ werden.
    expect(topics[0].skipped).toBe(0)
  })

  it('trägt den ROHEN Schlüssel, nicht einen deutschen Text', () => {
    const topics = buildTopics(['t1'], new Map([['t1', 'stochastik']]), [
      antwort('t1', true),
    ])
    // Die Übersetzung passiert in der Anzeige (CLAUDE §12), nicht hier.
    expect(topics[0].topic).toBe('stochastik')
  })
})

describe('buildTopics — Aufgaben ohne competency_content', () => {
  it('sammelt sie unter dem Sentinel, wenn es zugeordnete Themen gibt', () => {
    const topics = buildTopics(
      ['t1', 't2'],
      new Map([['t1', 'geometrie']]),
      [antwort('t1', true), antwort('t2', false)],
    )

    expect(topics.map((t) => t.topic)).toEqual(['geometrie', TOPIC_UNASSIGNED])
  })

  it('führt „ohne Zuordnung" ans ENDE, nie an den Anfang', () => {
    const topics = buildTopics(
      ['t0', 't1'],
      new Map([['t1', 'stochastik']]),
      [antwort('t0', true), antwort('t1', true)],
    )
    expect(topics[topics.length - 1].topic).toBe(TOPIC_UNASSIGNED)
  })

  it('liefert GAR KEINE Themen, wenn nur der Rest übrig bliebe', () => {
    // Ein Balken namens „ohne Zuordnung" ist ein Etikett auf dem Nichts.
    const topics = buildTopics(['t1', 't2'], new Map(), [
      antwort('t1', true),
      antwort('t2', false),
    ])
    expect(topics).toEqual([])
  })
})

describe('buildTopics — der fest-Modus bleibt unverändert', () => {
  // Im Modus 'fest' ist item_ids gefüllt und wird unverändert durchgereicht.
  // Diese Fälle beschreiben das Verhalten VOR R2 und müssen es festhalten.

  it('zählt zugeloste, aber unbeantwortete Aufgaben weiterhin als ausgelassen', () => {
    const topics = buildTopics(
      ['t1', 't2', 't3'],
      new Map([
        ['t1', 'geometrie'],
        ['t2', 'geometrie'],
        ['t3', 'geometrie'],
      ]),
      [antwort('t1', true)],
    )

    expect(topics[0]).toMatchObject({
      topic: 'geometrie',
      planned: 3,
      answered: 1,
      skipped: 2,
      correct: 1,
    })
  })

  it('mittelt die Bearbeitungszeit nur über Zeilen mit echter Zeit', () => {
    const topics = buildTopics(
      ['t1', 't2', 't3'],
      new Map([
        ['t1', 'funktionen'],
        ['t2', 'funktionen'],
        ['t3', 'funktionen'],
      ]),
      [antwort('t1', true, 20000), antwort('t2', true, 40000), antwort('t3', true, null)],
    )
    expect(topics[0].avgDurationMs).toBe(30000)
  })

  it('liefert null als Zeit, wenn keine Zeile eine Zeit trägt', () => {
    const topics = buildTopics(['t1'], new Map([['t1', 'geometrie']]), [
      antwort('t1', true, null),
    ])
    expect(topics[0].avgDurationMs).toBeNull()
  })

  it('sortiert zugeordnete Themen alphabetisch', () => {
    const topics = buildTopics(
      ['a', 'b', 'c'],
      new Map([
        ['a', 'stochastik'],
        ['b', 'arithmetik_algebra'],
        ['c', 'geometrie'],
      ]),
      [antwort('a', true), antwort('b', true), antwort('c', true)],
    )
    expect(topics.map((t) => t.topic)).toEqual([
      'arithmetik_algebra',
      'geometrie',
      'stochastik',
    ])
  })
})
