import { useState } from 'react'
import { Play } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { useAuth } from '@/hooks/useAuth'
import { SofortDialog } from './SofortDialog'

/**
 * Knopf „Session jetzt starten“ mit Dialog (Slots S2, Entscheidung 7 und 9). Nur für Admins; andere Rollen
 * sehen nichts. studentId wählt das Kind vor (Akte), sofern es heute buchbar ist.
 */
export function SofortKnopf({ studentId, variante = 'primary' }: { studentId?: string; variante?: 'primary' | 'outline' }): JSX.Element | null {
  const { t } = useTranslation('slots')
  const { role } = useAuth()
  const [offen, setOffen] = useState(false)
  if (role !== 'admin') return null
  return (
    <>
      <Button type="button" variant={variante} onClick={() => setOffen(true)}>
        <Play aria-hidden="true" className="h-4 w-4" />
        {t('sofort.knopf')}
      </Button>
      {offen && <SofortDialog vorauswahl={studentId} onClose={() => setOffen(false)} />}
    </>
  )
}
