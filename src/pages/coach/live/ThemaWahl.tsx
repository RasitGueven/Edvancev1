import { useEffect, useState } from 'react'
import { ThemaSuche } from '@/pages/admin/intake/ThemaSuche'
import { checkinCoachSetzen, themenKatalog } from '@/lib/session/coachLive'
import type { CoachLiveKind } from '@/types/coachLive'
import type { Thema } from '@/types/themen'
import { Feldname } from './bausteine'
import { useLive } from './LiveKontext'
import { useLiveTexte } from './useLiveTexte'

/**
 * F1 (Trockenlauf, Befund A1): Thema fuer ein Kind waehlen, auch ohne Schulthema und mitten in der
 * Session. Gewaehlt wird ueber checkin_coach_setzen mit Fall „Schulthema“: Das Thema wird das aktuelle
 * Schulthema des Leads und das Ziel der Stunde. Die Engine plant jeden Schritt neu; eine offene Aufgabe
 * bleibt, das neue Thema gilt ab der naechsten.
 */
export function ThemaWahl({
  kind,
  katalog: vorgegeben,
  startEingabe = '',
  onFertig,
}: {
  kind: CoachLiveKind
  katalog?: Thema[]
  startEingabe?: string
  onFertig?: () => void
}): JSX.Element {
  const { sessionId, ausfuehren } = useLive()
  const tx = useLiveTexte()
  const [geladen, setGeladen] = useState<Thema[]>([])
  const katalog = vorgegeben ?? geladen
  const unterwegs = kind.phase === 'warmup' || kind.phase === 'kern'

  useEffect(() => {
    if (vorgegeben) return
    void themenKatalog().then((res) => res.data && setGeladen(res.data))
  }, [vorgegeben])

  const waehle = (key: string): void => {
    const label = katalog.find((t) => t.thema_key === key)?.label ?? key
    void ausfuehren(checkinCoachSetzen(sessionId, kind.id, 'schulthema', key), tx.t('toast.thema', { name: kind.vorname, thema: label })).then(
      (ok) => ok && onFertig?.(),
    )
  }

  return (
    <div className="flex flex-col gap-2 rounded-[var(--radius-md)] border border-[var(--color-gold-warning)]/40 bg-[var(--color-bg-app)] p-3">
      <Feldname htmlFor={`thema-${kind.id}`}>{tx.t('checkin.suchen', { name: kind.vorname })}</Feldname>
      <ThemaSuche
        katalog={katalog}
        stufe={kind.stufe}
        aktuell={kind.ziel.themaKey}
        disabled={false}
        onWaehle={waehle}
        startEingabe={startEingabe}
        inputId={`thema-${kind.id}`}
      />
      {unterwegs && <p className="text-xs text-[var(--color-text-tertiary)]">{tx.t('thema.abNaechster')}</p>}
    </div>
  )
}
