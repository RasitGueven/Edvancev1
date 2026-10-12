import { Info } from 'lucide-react'
import { EdvanceCard } from '@/components/edvance/EdvanceCard'
import { useRaumLiveTestkonten } from '@/hooks/useRaumLiveTestkonten'
import { testlaufHinweis } from '@/lib/session/coachLiveLogik'
import { useLive } from './LiveKontext'
import { useLiveTexte } from './useLiveTexte'

/**
 * F2 (Trockenlauf 10.10.): ruhiger Hinweis, wenn ein Kind ohne Ziel oder ohne Aufgabe wartet, die Session kein
 * Testlauf ist und alle gebuchten Kinder Testkonten sind. Nur Anzeige; den Testlauf setzt der Admin.
 */
export function TestlaufHinweis(): JSX.Element | null {
  const { raum } = useLive()
  const { t } = useLiveTexte()
  const testkonto = useRaumLiveTestkonten(raum)
  if (!testlaufHinweis(raum, testkonto)) return null
  // EdvanceCard reicht data-testid nicht durch.
  return (
    <section data-testid="hinweis-kein-testlauf">
      <EdvanceCard className="flex items-center gap-2 px-4 py-3 text-sm text-[var(--color-text-secondary)] hover:shadow-xs">
        <Info className="h-5 w-5 flex-none text-[var(--color-primary)]" aria-hidden />
        {t('kopf.keinTestlauf')}
      </EdvanceCard>
    </section>
  )
}
