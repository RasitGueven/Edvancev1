import { useCallback, useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'

import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { useAuthContext } from '@/context/AuthContext'
import {
  erzeugeFehlendeStimmen,
  ladeStimmeBedarf,
  ladeStudioEinstellungen,
  setzeStudioEinstellung,
  type StimmeBedarf,
} from '@/lib/supabase/studio'

import { FELD } from './felder'

/**
 * Stimme einer Sequenz (Anforderung Studio §5): Stand je Satz, „Fehlende erzeugen“ in Durchgängen über die
 * Server-Route, Stimmen-ID für Admins. Ein unveränderter Satz hat denselben Fingerabdruck und gilt als vertont.
 */
export function StimmePanel({ sequenzId, stand, onFertig }: { sequenzId: string; stand: string; onFertig?: () => void }): JSX.Element {
  const { t } = useTranslation('studio')
  const { role } = useAuthContext()
  const [bedarf, setBedarf] = useState<StimmeBedarf[] | null>(null)
  const [laeuft, setLaeuft] = useState<number | null>(null)
  const [meldung, setMeldung] = useState<string | null>(null)
  const [stimmeId, setStimmeId] = useState('')

  const lade = useCallback(async () => {
    const r = await ladeStimmeBedarf(sequenzId)
    setBedarf(r.data ?? [])
  }, [sequenzId])
  useEffect(() => {
    void lade()
  }, [lade, stand])
  useEffect(() => {
    if (role === 'admin') void ladeStudioEinstellungen().then((r) => setStimmeId(String(r.data?.stimme_id ?? '')))
  }, [role])

  const erzeugen = async (): Promise<void> => {
    setMeldung(null)
    for (let runde = 0; runde < 50; runde++) {
      const r = await erzeugeFehlendeStimmen(sequenzId)
      if (r.error || !r.data) {
        setMeldung(t('stimme.fehler', { grund: r.error?.message ?? '' }))
        break
      }
      setLaeuft(r.data.offen)
      if (r.data.fehler.length) {
        setMeldung(t('stimme.fehlerSaetze', { liste: r.data.fehler.join(', ') }))
        break
      }
      if (r.data.offen === 0 || r.data.erzeugt === 0) break
    }
    setLaeuft(null)
    await lade()
    onFertig?.()
  }

  const gesamt = bedarf?.length ?? 0
  const vorhanden = bedarf?.filter((b) => b.vorhanden).length ?? 0
  const platzhalter = bedarf?.filter((b) => b.platzhalter).length ?? 0
  return (
    <EdvanceCard>
      <div className="flex flex-col gap-4" data-testid="studio-stimme">
        <div className="flex flex-col gap-2">
          <h3 className="text-base font-semibold">{t('stimme.titel')}</h3>
          <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
            {gesamt > 0 && vorhanden === gesamt ? t('stimme.fertig') : t('stimme.stand', { vorhanden, gesamt })}
          </p>
          {platzhalter > 0 && <p className="text-xs text-[var(--color-text-muted)]">{t('stimme.platzhalter', { anzahl: platzhalter })}</p>}
          {laeuft !== null && <p className="text-xs text-[var(--color-text-muted)]">{t('stimme.laeuft', { offen: laeuft })}</p>}
          {meldung && <p className="text-sm text-[var(--color-error-coach)]">{meldung}</p>}
        </div>
        <div className="flex flex-wrap items-end gap-2">
          <Button
            onClick={() => void erzeugen()}
            disabled={laeuft !== null || bedarf === null || vorhanden === gesamt}
            title={vorhanden === gesamt ? t('stimme.gesperrtTooltip') : undefined}
          >
            {t('stimme.erzeugen')}
          </Button>
          {role === 'admin' && (
            <>
              <label className="flex flex-col gap-2 text-xs text-[var(--color-text-muted)]">
                {t('stimme.einstellung')}
                <input className={FELD} value={stimmeId} onChange={(e) => setStimmeId(e.target.value)} />
              </label>
              <Button
                variant="secondary"
                onClick={() =>
                  void setzeStudioEinstellung('stimme_id', stimmeId.trim() || null).then((r) =>
                    setMeldung(r.error ? t('stimme.fehler', { grund: r.error.message }) : t('stimme.einstellungGespeichert')),
                  )
                }
              >
                {t('stimme.einstellungSpeichern')}
              </Button>
            </>
          )}
        </div>
      </div>
    </EdvanceCard>
  )
}
