import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { reiheKaSetzen } from '@/lib/supabase/reihe'
import { Feldname } from '../bausteine'
import { ReiheKarte } from './ReiheKarte'

/**
 * Reihe 1 C1.4: Klassenarbeitsdatum im Check-in erfassen bzw. bestätigen. Vorbelegt mit der Antwort des
 * Kindes; „Datum bestätigen“ legt die Reihe an oder plant sie neu (reihe_ka_setzen).
 */
export function ReiheKaFeld({ sessionId, kindId, kindDatum }: { sessionId: string; kindId: string; kindDatum: string | null }): JSX.Element {
  const { t, i18n } = useTranslation('reihe')
  const [wert, setWert] = useState(kindDatum ?? '')
  const [stand, setStand] = useState<{ datum: string } | { fehler: 'fehler' | 'keinThema' } | null>(null)
  const id = `ka-${kindId}`
  const anzeige = (iso: string): string =>
    new Intl.DateTimeFormat(i18n.language, { timeZone: 'Europe/Berlin', day: '2-digit', month: '2-digit', year: 'numeric' })
      .format(new Date(`${iso}T12:00:00Z`))
  const speichern = async (): Promise<void> => {
    const r = await reiheKaSetzen(sessionId, kindId, wert || null)
    setStand(r.error ? { fehler: r.hint === 'kein_thema' ? 'keinThema' : 'fehler' } : { datum: wert })
  }
  return (
    <div className="col-span-full flex flex-col gap-2 @min-[1000px]:col-start-2">
      <Feldname htmlFor={id}>{t('ka.feld')}</Feldname>
      <div className="flex flex-wrap items-center gap-2">
        <input id={id} type="date" value={wert} onChange={(e) => setWert(e.target.value)}
          className="min-h-[44px] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm" />
        <Button variant="secondary" onClick={() => void speichern()}>{t('ka.bestaetigen')}</Button>
        {kindDatum && <span className="text-xs text-[var(--color-text-muted)]">{t('ka.kindSagt', { datum: anzeige(kindDatum) })}</span>}
      </div>
      {stand && 'datum' in stand && stand.datum && <span className="text-xs text-[var(--color-text-muted)]">{t('ka.gespeichert', { datum: anzeige(stand.datum) })}</span>}
      {stand && 'fehler' in stand && <span role="alert" className="text-xs text-[var(--color-text-muted)]">{t(`ka.${stand.fehler}`)}</span>}
      {/* Warnung „passt nicht“ sieht der Coach im Check-in (Konzept §2.3 Regel 5); neu geladen nach dem Speichern. */}
      <ReiheKarte key={stand && 'datum' in stand ? stand.datum : 'start'} studentId={kindId} kompakt />
    </div>
  )
}
