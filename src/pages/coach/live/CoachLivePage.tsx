import { useCallback, useMemo, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { EmptyState } from '@/components/edvance/EmptyState'
import { LoadingPulse } from '@/components/edvance/LoadingPulse'
import { ToastBanner } from '@/components/edvance/ToastBanner'
import { Button } from '@/components/ui/button'
import { useAuth } from '@/hooks/useAuth'
import { useRaumLive } from '@/hooks/useRaumLive'
import { beispielZeitpunktSetzen } from '@/lib/session/coachLive'
import { istArbeitsphase } from '@/lib/session/coachLiveLogik'
import type { UserRole } from '@/types'
import type { LiveZeitpunkt } from '@/types/coachLive'
import type { SupabaseResult } from '@/types/ui'
import { BeispielLeiste } from './BeispielLeiste'
import { LiveKontext, type LiveKontextWert } from './LiveKontext'
import { LiveKopf } from './LiveKopf'
import { LiveRaster } from './LiveRaster'
import { Schublade } from './Schublade'
import { useLiveTexte } from './useLiveTexte'

/** Coach und Admin; Schuelerkonten kommen nicht hinein (ProtectedRoute in App.tsx). */
export const COACH_LIVE_ROLLEN: UserRole[] = ['coach', 'admin']

type Meldung = { art: 'success' | 'error'; text: string; id: number }

function Ansicht({ zeitpunkt, gewaehlt }: { zeitpunkt: LiveZeitpunkt; gewaehlt: string | null }): JSX.Element | null {
  if (istArbeitsphase(zeitpunkt)) return <LiveRaster gewaehlt={gewaehlt} />
  return null
}

/**
 * Coach-Live-Sicht einer Session: Fokus-Seite ohne Leiste (wie die Vertragsunterschrift),
 * gebaut fuers iPad quer und hoch. Daten nur ueber useRaumLive / lib/session/coachLive.
 */
export function CoachLivePage(): JSX.Element {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { role } = useAuth()
  const tx = useLiveTexte()
  const { raum, fehler, laedt, neuLaden } = useRaumLive(id)
  const [gewaehlt, setGewaehlt] = useState<string | null>(null)
  const [meldung, setMeldung] = useState<Meldung | null>(null)

  const ausfuehren = useCallback(
    async (aktion: Promise<SupabaseResult<unknown>>, erfolg?: string): Promise<boolean> => {
      const res = await aktion
      if (res.error !== null) {
        const key = `fehler.${res.error}`
        setMeldung({ art: 'error', text: tx.t(key, { defaultValue: tx.t('fehler.allgemein') }), id: Date.now() })
        return false
      }
      if (erfolg) setMeldung({ art: 'success', text: erfolg, id: Date.now() })
      await neuLaden()
      return true
    },
    [neuLaden, tx],
  )

  const kontext = useMemo<LiveKontextWert | null>(
    () =>
      raum && {
        sessionId: id,
        raum,
        ausfuehren,
        oeffneKind: setGewaehlt,
        kind: (kindId: string) => raum.kinder.find((k) => k.id === kindId) ?? raum.kinder[0],
      },
    [raum, id, ausfuehren],
  )

  const zeitpunktSetzen = async (z: LiveZeitpunkt): Promise<void> => {
    setGewaehlt(null)
    await ausfuehren(beispielZeitpunktSetzen(id, z))
  }

  if (laedt && !raum) {
    return (
      <div className="min-h-screen bg-[var(--color-bg-app)] p-6">
        <LoadingPulse lines={5} />
      </div>
    )
  }
  if (!raum || !kontext) {
    return (
      <div className="min-h-screen bg-[var(--color-bg-app)]">
        <EmptyState
          icon="📡"
          title={tx.t('laden.fehler')}
          description={fehler ?? ''}
          action={<Button onClick={() => void neuLaden()}>{tx.t('laden.erneut')}</Button>}
        />
      </div>
    )
  }

  const kind = gewaehlt && istArbeitsphase(raum.zeitpunkt) ? raum.kinder.find((k) => k.id === gewaehlt) : undefined

  return (
    <LiveKontext.Provider value={kontext}>
      <div className="flex h-dvh flex-col bg-[var(--color-bg-app)] text-[var(--color-text-primary)]">
        {raum.beispiel && <BeispielLeiste zeitpunkt={raum.zeitpunkt} onWaehle={(z) => void zeitpunktSetzen(z)} />}
        <LiveKopf raum={raum} onZurueck={() => navigate(role === 'admin' ? '/admin' : '/coach')} />
        <main className="flex-1 overflow-auto">
          <div className="@container mx-auto flex max-w-[1400px] flex-col gap-6 px-5 pb-10 pt-5">
            <Ansicht zeitpunkt={raum.zeitpunkt} gewaehlt={gewaehlt} />
          </div>
        </main>
        {kind && <Schublade kind={kind} onSchliessen={() => setGewaehlt(null)} />}
        {meldung && (
          <ToastBanner key={meldung.id} type={meldung.art} message={meldung.text} onClose={() => setMeldung(null)} />
        )}
      </div>
    </LiveKontext.Provider>
  )
}

