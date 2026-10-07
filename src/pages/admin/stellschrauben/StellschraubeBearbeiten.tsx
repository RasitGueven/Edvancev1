import { useEffect, useState } from 'react'
import { EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { speichernSperre, wertAusEingabe } from '@/lib/session/stellschrauben'
import { listStellschraubenProtokoll, stellschraubeSetzen } from '@/lib/supabase/sessionEinstellungen'
import type { Stellschraube, StellschraubeProtokoll } from '@/types/sessionLive'
import { useStellschraubenTexte } from './useStellschraubenTexte'

const FELD = 'w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm'

type Props = { s: Stellschraube; onGespeichert: (meldung: string) => void; onFehler: (meldung: string) => void }

/** Ändern nur mit Grund und innerhalb der Spanne (einstellung_setzen); darunter der Verlauf aus dem Protokoll. */
export function StellschraubeBearbeiten({ s, onGespeichert, onFehler }: Props): JSX.Element {
  const tx = useStellschraubenTexte()
  const { t } = tx
  const [roh, setRoh] = useState<string | boolean>(typeof s.wert === 'boolean' ? s.wert : String(s.wert))
  const [grund, setGrund] = useState('')
  const [speichert, setSpeichert] = useState(false)
  const [verlauf, setVerlauf] = useState<StellschraubeProtokoll[] | null>(null)

  useEffect(() => {
    let aktiv = true
    setVerlauf(null)
    void listStellschraubenProtokoll(s.schluessel).then((res) => {
      if (aktiv) setVerlauf(res.data ?? [])
    })
    return () => {
      aktiv = false
    }
  }, [s.schluessel, s.wert])

  const wert = wertAusEingabe(s, roh)
  const sperre = speichernSperre(s, wert, grund)

  const speichern = async (): Promise<void> => {
    if (sperre !== null || wert === null) return
    setSpeichert(true)
    const res = await stellschraubeSetzen(s.schluessel, wert, grund.trim())
    setSpeichert(false)
    if (res.error !== null) {
      onFehler(t(res.code === '22023' ? 'stellschrauben.fehlerSpanne' : 'stellschrauben.fehlerAllgemein'))
      return
    }
    setGrund('')
    onGespeichert(t('stellschrauben.gespeichert', { name: s.beschreibung }))
  }

  return (
    <section data-testid="stellschraube-bearbeiten">
      <EdvanceCard className="flex flex-col gap-4 p-6">
        <div className="flex flex-col gap-2">
          <h2 className="text-base font-semibold">{s.beschreibung}</h2>
          <p className="text-xs text-[var(--color-text-tertiary)]">
            {t('stellschrauben.aktuell', { wert: tx.wert(s, s.wert), start: tx.wert(s, s.startwert), spanne: tx.spanne(s) })}
          </p>
        </div>
        <label className="flex flex-col gap-2 text-sm">
          <span className="font-semibold">{t('stellschrauben.neuerWert')}</span>
          {s.typ === 'schalter' ? (
            <select value={String(roh)} onChange={(e) => setRoh(e.target.value === 'true')} className={`${FELD} min-h-[44px]`}>
              <option value="true">{t('stellschrauben.schalter.an')}</option>
              <option value="false">{t('stellschrauben.schalter.aus')}</option>
            </select>
          ) : s.typ === 'auswahl' ? (
            <select value={String(roh)} onChange={(e) => setRoh(e.target.value)} className={`${FELD} min-h-[44px]`}>
              {(s.werte ?? []).map((w) => (
                <option key={w} value={w}>
                  {t(`stellschrauben.auswahl.${w}`, { defaultValue: w })}
                </option>
              ))}
            </select>
          ) : (
            <Input inputMode="decimal" value={String(roh)} onChange={(e) => setRoh(e.target.value)} />
          )}
        </label>
        <label className="flex flex-col gap-2 text-sm">
          <span className="font-semibold">{t('stellschrauben.grund')}</span>
          <textarea
            value={grund}
            onChange={(e) => setGrund(e.target.value)}
            placeholder={t('stellschrauben.grundPlatzhalter')}
            className={`${FELD} min-h-[72px] py-2`}
          />
        </label>
        {sperre && sperre !== 'unveraendert' && (
          <p className="text-xs text-[var(--color-gold-warning)]">{t(`stellschrauben.sperre.${sperre}`)}</p>
        )}
        <div className="flex justify-end">
          <Button
            disabled={sperre !== null}
            loading={speichert}
            title={sperre ? t(`stellschrauben.sperre.${sperre}`) : undefined}
            onClick={() => void speichern()}
          >
            {t('stellschrauben.speichern')}
          </Button>
        </div>

        <div className="flex flex-col gap-2 border-t border-[var(--color-border)] pt-4">
          <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('stellschrauben.verlauf')}</h3>
          {verlauf === null ? (
            <LoadingPulse type="list" lines={2} />
          ) : verlauf.length === 0 ? (
            <EmptyState icon="🗂️" title={t('stellschrauben.verlaufLeer')} description={t('stellschrauben.verlaufLeerText')} />
          ) : (
            <ul className="flex flex-col">
              {verlauf.map((p) => (
                <li key={p.id} className="flex flex-col gap-1 border-t border-[var(--color-border)] py-2 first:border-t-0">
                  <span className="text-sm font-semibold">
                    {t('stellschrauben.verlaufZeile', { alt: tx.wert(s, p.alt), neu: tx.wert(s, p.neu) })}
                  </span>
                  <span className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{p.grund}</span>
                  <span className="text-xs text-[var(--color-text-tertiary)]">{tx.datumZeit(p.am)}</span>
                </li>
              ))}
            </ul>
          )}
        </div>
      </EdvanceCard>
    </section>
  )
}
