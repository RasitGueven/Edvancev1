// Admin-Pruefansicht, Abschnitt „Hinweise für das Kind“ (Paket L5): dieselben Hinweise wie bei Lena, lesend, mit
// Statuspille. Bei einer freigegebenen Aufgabe mit ungeprueften Hinweisen steht oben „Hinweise bestätigen“
// (hinweise_bestaetigen, nur Admin, protokolliert). Vor der Freigabe der Satz, dass die Freigabe sie prueft.

import { useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui'
import { KinderHinweise } from '@/components/edvance/pruefen/KinderHinweise'
import type { Bearbeitung } from '@/lib/pruefung/entwurf'
import { hinweiseOffen } from '@/lib/pruefung/hinweise'
import { hinweiseBestaetigen } from '@/lib/supabase/pruefungAdmin'
import type { PruefAufgabe, PruefFehlerInfo } from '@/types'

type Props = {
  aufgabe: PruefAufgabe
  b: Bearbeitung
  onBestaetigt: () => void
  onFehler: (err: PruefFehlerInfo) => void
}

export function HinweiseAdmin({ aufgabe, b, onBestaetigt, onFehler }: Props): JSX.Element {
  const { t } = useTranslation('pruefenAdmin')
  const [arbeitet, setArbeitet] = useState(false)
  const offen = hinweiseOffen(aufgabe.hinweise)
  const freigegeben = aufgabe.aufgabe.status === 'ready'

  const bestaetigen = async (): Promise<void> => {
    setArbeitet(true)
    const res = await hinweiseBestaetigen(aufgabe.task_id)
    setArbeitet(false)
    if (res.error) return onFehler(res.error)
    onBestaetigt()
  }

  const knopf = freigegeben && offen > 0
    ? <Button size="sm" disabled={arbeitet} onClick={() => void bestaetigen()}>{t('hinweise.bestaetigen')}</Button>
    : undefined
  const fuss = offen === 0 ? null : (
    <p role="status" className="text-sm text-[var(--color-text-secondary)]">
      {freigegeben ? t('hinweise.offen', { count: offen }) : t('hinweise.mitFreigabe')}
    </p>
  )

  return (
    <KinderHinweise geladen={aufgabe.hinweise} b={b} geaendert={false} lesend onChange={() => undefined}
      onZurueck={() => undefined} kopfAktion={knopf} fuss={fuss} />
  )
}
