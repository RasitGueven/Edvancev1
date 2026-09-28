// Verhalten der Vertragsdetailansicht, mit gemocktem Supabase.
//
// Drei Dinge, die nur hier entschieden werden: dass die volle IBAN erst nach
// dem protokollierten Aufruf sichtbar wird, dass die Sonderkuendigung beide
// Felder verlangt, und dass "Widerruf erfassen" nur waehrend der Frist geht.

import { describe, expect, it, vi, beforeEach } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import '@/i18n'
import type { VertragAktuell } from '@/types'

vi.mock('@/lib/supabase/vertraegeMenue', () => ({
  getVertragAktuell: vi.fn(),
  listVertragHistorie: vi.fn(() => Promise.resolve({ data: [], error: null })),
  vertragIbanAnzeigen: vi.fn(() =>
    Promise.resolve({ data: 'DE89370400440532013000', error: null }),
  ),
  vertragZugangscodeNeu: vi.fn(() => Promise.resolve({ data: 'EDV-NEUA-NEU2', error: null })),
  vertragWiderrufErfassen: vi.fn(() => Promise.resolve({ data: true, error: null })),
  vertragSonderkuendigungErfassen: vi.fn(() => Promise.resolve({ data: true, error: null })),
  vertragFolgevertragStarten: vi.fn(() => Promise.resolve({ data: 'neu-id', error: null })),
}))
vi.mock('@/lib/supabase/vertraege', () => ({
  getVertragNachweise: vi.fn(() =>
    Promise.resolve({ data: { zustimmungen: [], unterschriften: [], versand: [] }, error: null }),
  ),
  listVertragDokumente: vi.fn(() => Promise.resolve({ data: [], error: null })),
}))
vi.mock('@/lib/supabase/vertragScan', () => ({
  listArchiv: vi.fn(() => Promise.resolve({ data: [], error: null })),
  scanUrl: vi.fn(() => Promise.resolve({ data: 'https://example.invalid/x', error: null })),
  VERTRAEGE_BUCKET: 'vertraege',
}))
vi.mock('@/lib/supabase/vertragDateien', () => ({
  listVertragDateien: vi.fn(() => Promise.resolve({ data: [], error: null })),
  listDokumentFassungen: vi.fn(() => Promise.resolve({ data: [], error: null })),
  vertragPdfErzeugen: vi.fn(() => Promise.resolve({ data: true, error: null })),
}))
vi.mock('@/lib/supabase/subscriptions', () => ({
  listTiers: vi.fn(() =>
    Promise.resolve({ data: [{ id: 't3', name: 'Premium', price_cents: 34990 }], error: null }),
  ),
}))
vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { email: 'admin@edvance.de' }, role: 'admin', signOut: vi.fn() }),
}))

import {
  listDokumentFassungen,
  listVertragDateien,
  vertragPdfErzeugen,
} from '@/lib/supabase/vertragDateien'
import { getVertragNachweise } from '@/lib/supabase/vertraege'
import { listArchiv, scanUrl } from '@/lib/supabase/vertragScan'
import {
  getVertragAktuell,
  vertragIbanAnzeigen,
  vertragSonderkuendigungErfassen,
} from '@/lib/supabase/vertraegeMenue'
import { VertragDetailPage } from './VertragDetailPage'

function v(over: Partial<VertragAktuell> = {}): VertragAktuell {
  return {
    id: 'v1',
    wirksamer_status: 'im_widerruf',
    laufzeit_monat: 1,
    ist_aktueller_vertrag: true,
    beitrag_diesen_monat_cents: 38990,
    zugangscode_gueltig: true,
    endet_in_tagen: 200,
    mandatsreferenz: 'EDV-2026-000001',
    eltern_vorname: 'ZZ_Anna',
    eltern_nachname: 'Muster',
    kind_vorname: 'ZZ_Mia',
    kind_nachname: 'Muster',
    klasse: 8,
    tier_id: 't3',
    laufzeit_monate: 6,
    preis_cents: 38990,
    einheiten: 38,
    vertragsbeginn: '2026-10-01',
    vertrag_ende: '2027-05-15',
    widerruf_bis: '2026-10-30',
    ferientage: 43,
    iban_masked: 'DE** **** 3000',
    zugangscode: 'EDV-ABCD-EFG2',
    zahlungsstatus: 'in_ordnung',
    student_id: 's1',
    ...over,
  } as VertragAktuell
}

function zeige(): void {
  render(
    <MemoryRouter>
      <VertragDetailPage />
    </MemoryRouter>,
  )
}

beforeEach(() => vi.clearAllMocks())

describe('IBAN', () => {
  it('zeigt sie maskiert und erst nach dem protokollierten Aufruf vollständig', async () => {
    vi.mocked(getVertragAktuell).mockResolvedValue({ data: v(), error: null })
    zeige()

    await waitFor(() => expect(screen.getByText('DE** **** 3000')).toBeTruthy())
    expect(screen.queryByText(/DE89 3704/)).toBeNull()
    expect(vertragIbanAnzeigen).not.toHaveBeenCalled()

    fireEvent.click(screen.getByRole('button', { name: /Vollständig anzeigen/ }))
    await waitFor(() => expect(screen.getByText(/DE89 3704/)).toBeTruthy())
    expect(vertragIbanAnzeigen).toHaveBeenCalledWith('v1')
  })

  it('vergisst sie beim Zuklappen wieder', async () => {
    vi.mocked(getVertragAktuell).mockResolvedValue({ data: v(), error: null })
    zeige()
    fireEvent.click(await screen.findByRole('button', { name: /Vollständig anzeigen/ }))
    fireEvent.click(await screen.findByRole('button', { name: /Wieder verbergen/ }))
    await waitFor(() => expect(screen.queryByText(/DE89 3704/)).toBeNull())
  })
})

describe('Widerruf', () => {
  it('ist während der Frist anklickbar', async () => {
    vi.mocked(getVertragAktuell).mockResolvedValue({ data: v(), error: null })
    zeige()
    const knopf = await screen.findByRole('button', { name: 'Widerruf erfassen' })
    expect((knopf as HTMLButtonElement).disabled).toBe(false)
  })

  it('ist gesperrt, sobald der Vertrag aktiv ist', async () => {
    vi.mocked(getVertragAktuell).mockResolvedValue({
      data: v({ wirksamer_status: 'aktiv' }),
      error: null,
    })
    zeige()
    const knopf = await screen.findByRole('button', { name: 'Widerruf erfassen' })
    expect((knopf as HTMLButtonElement).disabled).toBe(true)
  })
})

describe('Sonderkündigung', () => {
  it('verlangt Datum und Grund', async () => {
    vi.mocked(getVertragAktuell).mockResolvedValue({ data: v(), error: null })
    zeige()

    fireEvent.click(await screen.findByRole('button', { name: 'Sonderkündigung erfassen' }))
    const bestaetigen = await screen.findByRole('button', { name: 'Kündigung erfassen' })
    expect((bestaetigen as HTMLButtonElement).disabled).toBe(true)

    fireEvent.change(screen.getByLabelText(/Gekündigt zum/), { target: { value: '2027-01-31' } })
    expect((bestaetigen as HTMLButtonElement).disabled).toBe(true)
    expect(vertragSonderkuendigungErfassen).not.toHaveBeenCalled()

    fireEvent.change(screen.getByLabelText(/Grund/), { target: { value: 'Umzug' } })
    expect((bestaetigen as HTMLButtonElement).disabled).toBe(false)

    fireEvent.click(bestaetigen)
    await waitFor(() =>
      expect(vertragSonderkuendigungErfassen).toHaveBeenCalledWith('v1', '2027-01-31', 'Umzug'),
    )
  })
})

describe('Archiv', () => {
  it('meldet ein fehlendes Vertrags-PDF und bietet an, es nachzuholen', async () => {
    vi.mocked(getVertragAktuell).mockResolvedValue({ data: v(), error: null })
    zeige()

    // Der Vertrag ist geschlossen, im Archiv liegt nichts: das gehoert gesagt,
    // nicht verschwiegen.
    expect(await screen.findByText('PDF ausstehend')).toBeTruthy()
    fireEvent.click(screen.getByRole('button', { name: 'PDF erzeugen' }))
    await waitFor(() => expect(vertragPdfErzeugen).toHaveBeenCalledWith('v1'))
  })

  it('zeigt das erzeugte PDF mit seinem Datum und keinen Nachhol-Knopf mehr', async () => {
    vi.mocked(getVertragAktuell).mockResolvedValue({ data: v(), error: null })
    vi.mocked(listArchiv).mockResolvedValue({
      data: [{ name: 'vertrag.pdf', pfad: 'v1/vertrag.pdf', groesseBytes: 6886 }],
      error: null,
    })
    vi.mocked(listVertragDateien).mockResolvedValue({
      data: [
        {
          art: 'vertrag',
          pfad: 'v1/vertrag.pdf',
          sha256: 'a'.repeat(64),
          bytes: 6886,
          erzeugtAm: '2026-09-24T10:00:00Z',
        },
      ],
      error: null,
    })
    zeige()

    expect(await screen.findByText('vertrag.pdf')).toBeTruthy()
    expect(screen.getByText('Erzeugt am 24.09.2026')).toBeTruthy()
    expect(screen.queryByText('PDF ausstehend')).toBeNull()
    expect(screen.queryByRole('button', { name: 'PDF erzeugen' })).toBeNull()
  })
})

describe('Fassungen im Archiv', () => {
  // clearAllMocks loescht die Aufrufe, nicht die Rueckgaben. Ohne das hier
  // liegt noch die Datei aus dem Archiv-Test in der Liste und es gibt zwei
  // "Oeffnen"-Knoepfe.
  beforeEach(() => {
    vi.mocked(listArchiv).mockResolvedValue({ data: [], error: null })
    vi.mocked(listVertragDateien).mockResolvedValue({ data: [], error: null })
  })

  it('verlinkt die Fassung, der zugestimmt wurde — nicht die neueste', async () => {
    vi.mocked(getVertragAktuell).mockResolvedValue({ data: v(), error: null })
    vi.mocked(getVertragNachweise).mockResolvedValue({
      data: {
        zustimmungen: [
          {
            dokument_schluessel: 'agb',
            dokument_version: 'platzhalter-v1',
            akzeptiert_at: '2026-10-01T09:00:00Z',
          },
        ],
        unterschriften: [],
        versand: [],
      },
      error: null,
    } as never)
    vi.mocked(listDokumentFassungen).mockResolvedValue({
      data: [
        { art: 'agb', fassung: 'platzhalter-v1', pfad: 'fassungen/agb/platzhalter-v1.pdf', erzeugtAm: '2026-10-01T08:00:00Z' },
        { art: 'agb', fassung: 'platzhalter-v2', pfad: 'fassungen/agb/platzhalter-v2.pdf', erzeugtAm: '2026-11-01T08:00:00Z' },
      ],
      error: null,
    })
    zeige()

    // Zugestimmt wurde v1. Ein Link auf v2 zeigte einen Text, den dieses
    // Elternteil nie gesehen hat.
    fireEvent.click(await screen.findByRole('button', { name: /Öffnen/ }))
    await waitFor(() => expect(scanUrl).toHaveBeenCalledWith('fassungen/agb/platzhalter-v1.pdf'))
  })

  it('bietet kein Öffnen an, solange die Fassungsdatei fehlt', async () => {
    vi.mocked(getVertragAktuell).mockResolvedValue({ data: v(), error: null })
    vi.mocked(getVertragNachweise).mockResolvedValue({
      data: {
        zustimmungen: [
          {
            dokument_schluessel: 'agb',
            dokument_version: 'platzhalter-v1',
            akzeptiert_at: '2026-10-01T09:00:00Z',
          },
        ],
        unterschriften: [],
        versand: [],
      },
      error: null,
    } as never)
    vi.mocked(listDokumentFassungen).mockResolvedValue({ data: [], error: null })
    zeige()

    expect(await screen.findByText(/Fassung platzhalter-v1/)).toBeTruthy()
    expect(screen.queryByRole('button', { name: /Öffnen/ })).toBeNull()
  })
})
