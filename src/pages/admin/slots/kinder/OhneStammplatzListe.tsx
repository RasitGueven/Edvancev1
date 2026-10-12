import { CalendarPlus } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { CardMenu } from '@/pages/admin/leads/CardMenu'
import type { SlotsKinderZeile } from '@/types/slotplan'
import { datumTagMonat, wochentagName } from '../slotsFormat'
import { paketText, rhythmusText } from './KinderSpalten'
import { KlasseFach } from '../KlasseFach'

/**
 * "Ohne Stammplatz" im Stil der Arbeitslisten auf Heute: läuft der Vertrag schon, steht das Datum in der
 * Handeln-Farbe. Bei einem Folgevertrag ist "Wie bisher weiterführen" der eine Knopf.
 */
export function OhneStammplatzListe({
  kinder,
  fehlerBei,
  onVergeben,
  onWeiterfuehren,
}: {
  kinder: SlotsKinderZeile[]
  fehlerBei: { ort: string; text: string } | null
  onVergeben: (k: SlotsKinderZeile) => void
  onWeiterfuehren: (k: SlotsKinderZeile) => void
}): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  return (
    <EdvanceCard className="flex flex-col p-4">
      <header className="flex items-start gap-4 pb-2">
        <span className="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-[var(--radius-md)] bg-[var(--color-primary-light)] text-[var(--color-primary)]">
          <CalendarPlus aria-hidden="true" className="h-5 w-5" />
        </span>
        <div className="flex min-w-0 flex-1 flex-col">
          <h2 className="text-base font-semibold">{t('kinder.ohne.titel')}</h2>
          <p className="text-xs text-[var(--color-text-tertiary)]">{t('kinder.ohne.unterzeile')}</p>
        </div>
        <span className="font-serif text-2xl font-semibold tabular-nums">{kinder.length}</span>
      </header>
      <ul className="flex flex-col">
        {kinder.map((k) => {
          const vorschlag = k.weiterfuehren && k.weiterfuehren.zeilen.length > 0 ? k.weiterfuehren : null
          const slot = vorschlag
            ? vorschlag.zeilen.map((z) => `${wochentagName(z.wochentag, i18n.language)} ${z.beginn}`).join(', ')
            : ''
          return (
            <li key={k.student_id} className="flex flex-col gap-1 border-t border-[var(--color-border)] py-2">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <span className="flex min-w-0 flex-col">
                  <span className="truncate text-sm font-semibold">{k.name ?? t('kind.ohneName')}</span>
                  <span className="flex flex-wrap items-center gap-2 text-xs text-[var(--color-text-tertiary)]">
                    <KlasseFach klasse={k.klasse} fach={k.fach} />
                    <span>{[paketText(k, t), rhythmusText(k.rhythmus, t)].join(' · ')}</span>
                  </span>
                  <span className={`text-xs font-semibold ${k.vertrag_laeuft ? 'text-[var(--color-error-coach)]' : 'text-[var(--color-text-secondary)]'}`}>
                    {t(k.vertrag_laeuft ? 'kinder.ohne.laeuftSeit' : 'kinder.ohne.beginntAm', { datum: datumTagMonat(k.beginn, i18n.language) })}
                  </span>
                </span>
                <span className="flex items-center gap-2">
                  {vorschlag ? (
                    <>
                      <Button type="button" size="sm" variant="outline" className="min-h-[44px]" onClick={() => onWeiterfuehren(k)}>
                        {t('kinder.ohne.weiterfuehren', { slot })}
                      </Button>
                      <CardMenu items={[{ label: t('aktion.stammplatzVergeben'), onSelect: () => onVergeben(k) }]} />
                    </>
                  ) : (
                    <Button type="button" size="sm" variant="outline" className="min-h-[44px]" onClick={() => onVergeben(k)}>
                      {t('aktion.stammplatzVergeben')}
                    </Button>
                  )}
                </span>
              </div>
              {fehlerBei?.ort === k.student_id && <p role="alert" className="text-xs text-[var(--color-error-coach)]">{t(fehlerBei.text)}</p>}
            </li>
          )
        })}
      </ul>
    </EdvanceCard>
  )
}
