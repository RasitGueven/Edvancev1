// LSA-Report per Mail (LR-2): Ablage im Bucket, Aufruf von mail_senden und
// Protokoll — gegen einen gemockten Supabase-Client, nichts verlässt die Maschine.
import { beforeEach, describe, expect, it, vi } from 'vitest'

const m = vi.hoisted(() => ({
  aufrufe: [] as [string, ...unknown[]][],
  upload: { error: null as { message: string } | null },
  invoke: { data: { an: 'zz@example.org', anhaenge: ['x.pdf'] } as unknown, error: null as unknown },
  rows: [] as unknown[],
}))

vi.mock('@/lib/supabase/client', () => {
  const builder = {
    select: (s: string) => (m.aufrufe.push(['select', s]), builder),
    eq: (c: string, v: unknown) => (m.aufrufe.push(['eq', c, v]), builder),
    order: (c: string, o: unknown) => (m.aufrufe.push(['order', c, o]), builder),
    single: () => Promise.resolve({ data: { full_name: 'ZZ_Ilkay B', first_name: 'ZZ_Ilkay', contact_email: 'zz@example.org' }, error: null }),
    then: (res: (v: unknown) => unknown) => Promise.resolve({ data: m.rows, error: null }).then(res),
  }
  return {
    supabase: {
      from: (t: string) => (m.aufrufe.push(['from', t]), builder),
      storage: {
        from: (b: string) => ({
          upload: (pfad: string, _blob: Blob, opt: unknown) => (m.aufrufe.push(['upload', b, pfad, opt]), Promise.resolve(m.upload)),
        }),
      },
      functions: {
        invoke: (name: string, opt: unknown) => (m.aufrufe.push(['invoke', name, opt]), Promise.resolve(m.invoke)),
      },
    },
  }
})

import {
  ladeLsaReportEmpfaenger,
  listLsaReportVersand,
  lsaReportHochladen,
  lsaReportSenden,
  reportPfad,
} from './lsaReportMail'

const SID = '0f0e0d0c-0b0a-4908-8706-050403020100'

describe('lsaReportMail', () => {
  beforeEach(() => {
    m.aufrufe = []
    m.upload = { error: null }
    m.invoke = { data: { an: 'zz@example.org', anhaenge: ['x.pdf'] }, error: null }
  })

  it('Pfad: {session}/{yyyyMMdd-HHmmss}.pdf in UTC', () => {
    expect(reportPfad(SID, new Date('2026-11-03T09:05:07.123Z'))).toBe(`${SID}/20261103-090507.pdf`)
  })

  it('lädt ohne Überschreiben in lsa_reports hoch und gibt den Pfad zurück', async () => {
    const r = await lsaReportHochladen(SID, new Blob(['%PDF']), new Date('2026-11-03T09:05:07Z'))
    expect(r).toEqual({ data: `${SID}/20261103-090507.pdf`, error: null })
    expect(m.aufrufe).toEqual([
      ['upload', 'lsa_reports', `${SID}/20261103-090507.pdf`, { contentType: 'application/pdf', upsert: false }],
    ])
  })

  it('meldet einen gescheiterten Upload', async () => {
    m.upload = { error: { message: 'The resource already exists' } }
    expect(await lsaReportHochladen(SID, new Blob(['%PDF']))).toEqual({ data: null, error: 'The resource already exists' })
  })

  it('schickt nur Anlass, Sitzung und Pfad — keine Adresse, keine Lead-ID', async () => {
    const r = await lsaReportSenden(SID, `${SID}/20261103-090507.pdf`)
    expect(r.data?.an).toBe('zz@example.org')
    expect(m.aufrufe).toEqual([
      ['invoke', 'mail_senden', { body: { anlass: 'lsa_report', lsa_session_id: SID, pfad: `${SID}/20261103-090507.pdf` } }],
    ])
  })

  it('holt die Meldung aus dem Antwortrumpf der Edge Function', async () => {
    m.invoke = {
      data: null,
      error: { message: 'non-2xx', context: new Response(JSON.stringify({ error: 'Keine Eltern-Mail am Lead hinterlegt' })) },
    }
    expect(await lsaReportSenden(SID, 'p')).toEqual({ data: null, error: 'Keine Eltern-Mail am Lead hinterlegt' })
  })

  it('liest das Protokoll der Sitzung, neueste zuerst', async () => {
    m.rows = [{ id: '1', anlass: 'lsa_report' }]
    expect((await listLsaReportVersand(SID)).data).toEqual(m.rows)
    expect(m.aufrufe).toContainEqual(['from', 'lead_mail_versand'])
    expect(m.aufrufe).toContainEqual(['eq', 'lsa_session_id', SID])
    expect(m.aufrufe).toContainEqual(['eq', 'anlass', 'lsa_report'])
    expect(m.aufrufe).toContainEqual(['order', 'erfolgt_at', { ascending: false }])
  })

  it('liest Name und Eltern-Mail des Leads', async () => {
    const r = await ladeLsaReportEmpfaenger('ZZ_lead')
    expect(r.data?.contact_email).toBe('zz@example.org')
    expect(m.aufrufe).toContainEqual(['from', 'leads'])
    expect(m.aufrufe).toContainEqual(['eq', 'id', 'ZZ_lead'])
  })
})
