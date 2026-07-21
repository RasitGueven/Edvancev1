import { Button } from '@/components/ui/button'
import { EdvanceBadge } from '@/components/edvance'
import { CheckCircle2, Loader2, MonitorSmartphone } from 'lucide-react'
import type { PlatzBelegt, PlatzDevice } from '@/lib/supabase/platz'
import { OptionChips } from './OptionChips'
import type { IntakeFormState } from './formState'

export type FreigabeSession = { session_id: string; total_items: number }

type SectionFreigabePlatzProps = {
  form: IntakeFormState
  consentGiven: boolean
  confirmingConsent: boolean
  onConfirmConsent: () => void
  selectedSubject: string | null
  onSelectSubject: (subject: string) => void
  onFreigeben: () => void
  freigebenLoading: boolean
  session: FreigabeSession | null
  plaetze: PlatzDevice[] | null
  belegtePlaetze: PlatzBelegt[]
  platzLoading: boolean
  assigningId: string | null
  releasingId: string | null
  confirmReleaseId: string | null
  assignedPlatz: { label: string; expires_at: string } | null
  onAssignPlatz: (platzProfileId: string) => void
  onConfirmRelease: (assignmentId: string | null) => void
  onReleasePlatz: (platz: PlatzBelegt) => void
}

const berlinTime = (iso: string): string =>
  new Date(iso).toLocaleTimeString('de-DE', {
    timeZone: 'Europe/Berlin',
    hour: '2-digit',
    minute: '2-digit',
  })

// Schritt 3 — DSGVO bestätigen, LSA freigeben, Platz zuweisen. Ein Fluss von
// oben nach unten: jedes Tor öffnet das nächste.
export function SectionFreigabePlatz(props: SectionFreigabePlatzProps): JSX.Element {
  const {
    form,
    consentGiven,
    confirmingConsent,
    onConfirmConsent,
    selectedSubject,
    onSelectSubject,
    onFreigeben,
    freigebenLoading,
    session,
    plaetze,
    belegtePlaetze,
    platzLoading,
    assigningId,
    releasingId,
    confirmReleaseId,
    assignedPlatz,
    onAssignPlatz,
    onConfirmRelease,
    onReleasePlatz,
  } = props

  const canFreigeben =
    consentGiven && selectedSubject !== null && form.class_level !== null && !session

  return (
    <div className="flex flex-col gap-6">
      {/* DSGVO — expliziter Bestätigungs-Schritt */}
      <div className="flex flex-col gap-3 rounded-xl border border-[var(--color-border)] p-4">
        <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          DSGVO-Einwilligung
        </p>
        {consentGiven ? (
          <div className="flex items-center gap-2 text-sm text-[var(--color-success)]">
            <CheckCircle2 className="h-5 w-5" />
            Einwilligung dokumentiert — LSA-Freigabe ist möglich.
          </div>
        ) : (
          <>
            <p className="text-sm text-[var(--color-text-secondary)]">
              Die Eltern haben der Verarbeitung der Lerndaten ihres Kindes zugestimmt.
              Pflicht vor der LSA-Freigabe.
            </p>
            <Button onClick={onConfirmConsent} disabled={confirmingConsent} className="self-start">
              {confirmingConsent ? 'Speichert …' : 'DSGVO-Einwilligung bestätigen'}
            </Button>
          </>
        )}
      </div>

      {/* LSA freigeben */}
      <div className="flex flex-col gap-3 rounded-xl border border-[var(--color-border)] p-4">
        <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          Lernstandsanalyse
        </p>
        {session ? (
          <div className="flex flex-col gap-2">
            <div className="flex items-center gap-2">
              <EdvanceBadge variant="primary">LSA freigegeben</EdvanceBadge>
              <span className="text-sm text-[var(--color-text-secondary)]">
                {session.total_items} Aufgaben
              </span>
            </div>
            <p className="text-xs text-[var(--color-text-tertiary)]">
              Session {session.session_id.slice(0, 8)}… gestartet.
            </p>
          </div>
        ) : (
          <>
            {form.subjects.length > 1 && (
              <div className="flex flex-col gap-2">
                <span className="text-sm text-[var(--color-text-secondary)]">
                  Für welches Fach?
                </span>
                <OptionChips
                  options={form.subjects.map((s) => ({ value: s, label: s }))}
                  selected={selectedSubject ? [selectedSubject] : []}
                  onToggle={onSelectSubject}
                />
              </div>
            )}
            {form.class_level === null && (
              <p className="text-sm text-[var(--color-error-exam)]">
                Ohne Klasse keine Freigabe — bitte oben die Klasse ergänzen.
              </p>
            )}
            <Button
              onClick={onFreigeben}
              disabled={!canFreigeben || freigebenLoading}
              className="self-start"
            >
              {freigebenLoading ? 'Gibt frei …' : 'LSA freigeben'}
            </Button>
            {!consentGiven && (
              <p className="text-xs text-[var(--color-text-tertiary)]">
                Zuerst die DSGVO-Einwilligung bestätigen.
              </p>
            )}
          </>
        )}
      </div>

      {/* Platz zuweisen — direkt im Anschluss an die Freigabe */}
      {session && (
        <div className="flex flex-col gap-3 rounded-xl border border-[var(--color-border)] p-4">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            Platz zuweisen
          </p>
          {assignedPlatz ? (
            <div className="flex flex-col gap-2 rounded-xl bg-[color-mix(in_srgb,var(--color-success)_10%,transparent)] p-4">
              <div className="flex items-center gap-2 text-[var(--color-success)]">
                <MonitorSmartphone className="h-5 w-5" />
                <span className="text-base font-semibold">
                  {assignedPlatz.label} ist zugewiesen
                </span>
              </div>
              <p className="text-sm text-[var(--color-text-secondary)]">
                Das Tablet zeigt jetzt „Hi {form.first_name.trim() || 'dort'}".
              </p>
              <p className="text-xs text-[var(--color-text-tertiary)]">
                Freigabe läuft bis {berlinTime(assignedPlatz.expires_at)} Uhr (2-Stunden-Fenster).
              </p>
            </div>
          ) : platzLoading ? (
            <div className="flex items-center gap-2 text-sm text-[var(--color-text-tertiary)]">
              <Loader2 className="h-4 w-4 animate-spin" /> Plätze werden geladen …
            </div>
          ) : plaetze && plaetze.length > 0 ? (
            <div className="flex flex-col gap-2">
              <span className="text-sm text-[var(--color-text-secondary)]">
                Freien Platz wählen:
              </span>
              <div className="flex flex-wrap gap-2">
                {plaetze.map((platz) => (
                  <Button
                    key={platz.profile_id}
                    variant="outline"
                    onClick={() => onAssignPlatz(platz.profile_id)}
                    disabled={assigningId !== null}
                  >
                    {assigningId === platz.profile_id ? 'Weist zu …' : platz.label}
                  </Button>
                ))}
              </div>
            </div>
          ) : (
            <p className="text-sm text-[var(--color-error-exam)]">
              Kein freier Platz verfügbar. Bitte unten einen belegten Platz freigeben.
            </p>
          )}

          {/* Belegte Plätze — jeder einzeln freigebbar, wenn er hängen bleibt
              (Kind abgebrochen, Tablet weggelegt). Beendet die aktive Zuweisung;
              der Platz fällt sofort auf „wartet" zurück und wird wieder frei. */}
          {belegtePlaetze.length > 0 && (
            <div className="flex flex-col gap-2 border-t border-[var(--color-border)] pt-3">
              <span className="text-sm text-[var(--color-text-secondary)]">
                Belegte Plätze:
              </span>
              {belegtePlaetze.map((platz) => (
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
                    // Bestätigung inline statt Modal (Design-Regel: keine Modals
                    // für einfache Bestätigungen).
                    <span className="flex flex-wrap items-center gap-2">
                      <span className="text-sm text-[var(--color-text-secondary)]">
                        {platz.label} wirklich freigeben?
                      </span>
                      <Button
                        size="sm"
                        disabled={releasingId !== null}
                        onClick={() => onReleasePlatz(platz)}
                      >
                        {releasingId === platz.assignment_id ? 'Gibt frei …' : 'Ja, freigeben'}
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        disabled={releasingId !== null}
                        onClick={() => onConfirmRelease(null)}
                      >
                        Abbrechen
                      </Button>
                    </span>
                  ) : (
                    <Button
                      variant="outline"
                      size="sm"
                      disabled={releasingId !== null}
                      onClick={() => onConfirmRelease(platz.assignment_id)}
                    >
                      Platz freigeben
                    </Button>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  )
}
