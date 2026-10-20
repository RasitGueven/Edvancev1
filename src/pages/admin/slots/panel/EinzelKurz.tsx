import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import type { TagSessionOhneRaum } from '@/types/slotplan'
import type { StundenplanSession } from '@/types/stundenplan'
import { uhrzeit } from '../slotsFormat'

type Props = {
  session: StundenplanSession | TagSessionOhneRaum
  onOeffnen: () => void
  /** Im Tagespanel eine Zeile der Liste statt einer eigenen Karte. */
  alsZeile?: boolean
}

/** Eine Einzel- oder Sofort-Session kurz (Slot-Panel, Tagespanel): Uhrzeit, Raum, Leitung, Kinder, „Öffnen“. */
export function EinzelKurz({ session, onOeffnen, alsZeile = false }: Props): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const kinder = typeof session.kinder === 'number' ? session.kinder : session.kinder.length
  const Huelle = alsZeile ? 'div' : EdvanceCard
  return (
    <Huelle className={`flex flex-wrap items-center gap-2 ${alsZeile ? 'border-l-[3px] border-[var(--color-primary)] pl-4' : 'p-4'}`}>
      <span className="flex min-w-0 flex-1 flex-col gap-1">
        <span className="flex flex-wrap items-center gap-2">
          <span className="text-base font-semibold tabular-nums text-[var(--color-text-primary)]">
            {t('wochenplan2.einzel.chip', { zeit: uhrzeit(session.scheduled_at, i18n.language), raum: session.room ?? t('stundenplan.ohneRaum') })}
          </span>
          {session.testlauf && <EdvanceBadge variant="warning">{t('stundenplan.testlauf.kennzeichen')}</EdvanceBadge>}
          <EdvanceBadge variant="primary">{t('wochenplan2.einzel.art')}</EdvanceBadge>
        </span>
        <span className="truncate text-sm text-[var(--color-text-secondary)]">
          {t('wochenplan2.einzel.leitungKinder', { leitung: session.coach_name ?? t('stundenplan.ohneCoach'), count: kinder })}
        </span>
      </span>
      <Button type="button" variant="outline" size="sm" className="min-h-[44px]" onClick={onOeffnen}>
        {t('wochenplan2.oeffnen')}
      </Button>
    </Huelle>
  )
}
