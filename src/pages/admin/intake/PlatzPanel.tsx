import { useEffect, useState } from 'react'
import { Loader2, MonitorSmartphone } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Modal } from '@/components/edvance/Modal'
import { getOpenSessionForLead } from '@/lib/supabase/leadLsa'
import {
  assignPlatz,
  listPlaetze,
  releasePlatz,
  type PlatzBelegt,
  type PlatzDevice,
} from '@/lib/supabase/platz'
import type { Lead } from '@/types'

type PlatzPanelProps = {
  lead: Lead
  onClose: () => void
  onChanged: () => void
}

const berlinTime = (iso: string): string =>
  new Date(iso).toLocaleTimeString('de-DE', {
    timeZone: 'Europe/Berlin',
    hour: '2-digit',
    minute: '2-digit',
  })

/**
 * Platzvergabe zu einem freigegebenen Lead. Lag frueher in Schritt 3 des
 * Wizards; seit dem Umbau auf zwei Schritte haengt sie an der Lead-Karte und
 * ist damit auch nach dem Erstgespraech noch erreichbar.
 */
export function PlatzPanel({ lead, onClose, onChanged }: PlatzPanelProps): JSX.Element {
  const [sessionId, setSessionId] = useState<string | null>(null)
  const [frei, setFrei] = useState<PlatzDevice[]>([])
  const [belegt, setBelegt] = useState<PlatzBelegt[]>([])
  const [loading, setLoading] = useState(true)
  const [assigningId, setAssigningId] = useState<string | null>(null)
  const [releasingId, setReleasingId] = useState<string | null>(null)
  const [confirmReleaseId, setConfirmReleaseId] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  const load = async (): Promise<void> => {
    setLoading(true)
    const [sessionRes, platzRes] = await Promise.all([
      getOpenSessionForLead(lead.id),
      listPlaetze(),
    ])
    setLoading(false)
    setSessionId(sessionRes.data?.session_id ?? null)
    setFrei(platzRes.data?.frei ?? [])
    setBelegt(platzRes.data?.belegt ?? [])
    setError(sessionRes.error ?? platzRes.error)
  }

  useEffect(() => {
    void load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [lead.id])

  const assign = async (profileId: string): Promise<void> => {
    if (!sessionId) return
    setAssigningId(profileId)
    setError(null)
    const { error: err } = await assignPlatz(profileId, sessionId)
    setAssigningId(null)
    if (err) {
      setError(err)
      return
    }
    await load()
    onChanged()
  }

  const release = async (platz: PlatzBelegt): Promise<void> => {
    setReleasingId(platz.assignment_id)
    setError(null)
    const { error: err } = await releasePlatz(platz.assignment_id)
    setReleasingId(null)
    setConfirmReleaseId(null)
    if (err) {
      setError(err)
      return
    }
    await load()
    onChanged()
  }

  return (
    <Modal
      open
      onClose={onClose}
      title="Platz zuweisen"
      description={`${lead.first_name ? `${lead.first_name} · ` : ''}${lead.full_name}`}
      footer={
        <Button variant="outline" onClick={onClose}>
          Schließen
        </Button>
      }
    >
      <div className="flex flex-col gap-5">
        {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}

        {loading ? (
          <div className="flex items-center gap-2 text-sm text-[var(--color-text-tertiary)]">
            <Loader2 className="h-4 w-4 animate-spin" /> Plätze werden geladen …
          </div>
        ) : (
          <>
            <div className="flex flex-col gap-2">
              <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                Freien Platz wählen
              </p>
              {sessionId === null ? (
                <p className="text-sm text-[var(--color-text-secondary)]">
                  Für diesen Lead läuft gerade keine offene LSA-Session — eine neue
                  Zuweisung ist deshalb nicht möglich. Belegte Plätze lassen sich
                  unten trotzdem freigeben.
                </p>
              ) : frei.length === 0 ? (
                <p className="text-sm text-[var(--color-error-exam)]">
                  Kein freier Platz verfügbar. Bitte unten einen belegten Platz freigeben.
                </p>
              ) : (
                <div className="flex flex-wrap gap-2">
                  {frei.map((platz) => (
                    <Button
                      key={platz.profile_id}
                      variant="outline"
                      onClick={() => assign(platz.profile_id)}
                      disabled={assigningId !== null}
                    >
                      <MonitorSmartphone className="mr-1.5 h-4 w-4" />
                      {assigningId === platz.profile_id ? 'Weist zu …' : platz.label}
                    </Button>
                  ))}
                </div>
              )}
            </div>

            {/* Belegte Plaetze — jeder einzeln freigebbar, wenn er haengen
                bleibt (Kind abgebrochen, Tablet weggelegt). */}
            {belegt.length > 0 && (
              <div className="flex flex-col gap-2 border-t border-[var(--color-border)] pt-4">
                <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                  Belegte Plätze
                </p>
                {belegt.map((platz) => (
                  <div
                    key={platz.assignment_id}
                    className="flex flex-wrap items-center justify-between gap-2"
                  >
                    <span className="text-sm text-[var(--color-text-primary)]">
                      {platz.label}
                      <span className="text-[var(--color-text-tertiary)]">
                        {' '}
                        — bis {berlinTime(platz.expires_at)} Uhr
                      </span>
                    </span>
                    {confirmReleaseId === platz.assignment_id ? (
                      // Bestaetigung inline statt zweitem Modal (Design-Regel).
                      <span className="flex flex-wrap items-center gap-2">
                        <span className="text-sm text-[var(--color-text-secondary)]">
                          {platz.label} wirklich freigeben?
                        </span>
                        <Button
                          size="sm"
                          disabled={releasingId !== null}
                          onClick={() => release(platz)}
                        >
                          {releasingId === platz.assignment_id ? 'Gibt frei …' : 'Ja, freigeben'}
                        </Button>
                        <Button
                          size="sm"
                          variant="outline"
                          disabled={releasingId !== null}
                          onClick={() => setConfirmReleaseId(null)}
                        >
                          Abbrechen
                        </Button>
                      </span>
                    ) : (
                      <Button
                        variant="outline"
                        size="sm"
                        disabled={releasingId !== null}
                        onClick={() => setConfirmReleaseId(platz.assignment_id)}
                      >
                        Platz freigeben
                      </Button>
                    )}
                  </div>
                ))}
              </div>
            )}
          </>
        )}
      </div>
    </Modal>
  )
}
