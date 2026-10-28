// „Aufgabe stimmt nicht“ an der Aufgabe im Kind-Detail der Coach-Live-Sicht (Konzept §6): ein Tipp oeffnet ein kurzes
// Feld, Melden pausiert die Aufgabe sofort fuer alle (aufgabe_melden). Eigene Komponente, kleinster Eingriff in die Seite.
import { useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Flag } from 'lucide-react'
import { Button } from '@/components/ui'
import { aufgabeMelden } from '@/lib/supabase/bauformPruefung'

export function AufgabeMelden({ taskId }: { taskId: string }): JSX.Element {
  const { t } = useTranslation('bauformPruefen')
  const [offen, setOffen] = useState(false)
  const [grund, setGrund] = useState('')
  const [stand, setStand] = useState<'bereit' | 'busy' | 'gemeldet' | 'fehler'>('bereit')

  if (stand === 'gemeldet') return <p role="status" className="text-sm text-[var(--color-text-secondary)]">{t('melden.gemeldet')}</p>
  if (!offen) {
    return (
      <Button variant="outline" onClick={() => setOffen(true)} className="self-start">
        <Flag className="h-4 w-4" aria-hidden />
        {t('melden.knopf')}
      </Button>
    )
  }
  const senden = async (): Promise<void> => {
    setStand('busy')
    const r = await aufgabeMelden(taskId, grund.trim())
    setStand(r.error ? 'fehler' : 'gemeldet')
  }
  return (
    <div className="flex flex-col gap-2">
      <label className="flex flex-col gap-1 text-sm text-[var(--color-text-secondary)]">
        {t('melden.titel')}
        <input autoFocus value={grund} placeholder={t('melden.platzhalter')} onChange={(e) => setGrund(e.target.value)}
          className="min-h-[44px] rounded-[var(--radius-md)] border border-[var(--color-border)] px-3 text-sm text-[var(--color-text-primary)]" />
      </label>
      {stand === 'fehler' && <p role="alert" className="text-sm text-[var(--color-text-secondary)]">{t('melden.fehler')}</p>}
      <div className="flex gap-2">
        <Button variant="outline" onClick={() => setOffen(false)}>{t('melden.abbrechen')}</Button>
        <Button disabled={!grund.trim() || stand === 'busy'} title={grund.trim() ? undefined : t('melden.platzhalter')}
          onClick={() => void senden()}>{t('melden.senden')}</Button>
      </div>
    </div>
  )
}
