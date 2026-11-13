// IU-1 U3: „Gezielt prüfen“ mit Prüfziel (MSA). Gruppiert nach den vier Bereichen; erledigte Kompetenzen stehen
// eingeklappt mit Haken und zählen im Fortschritt mit, teilweise belegte zeigen „1 von 2“. Der Prüfablauf bleibt
// derselbe (Klick öffnet die Prüfansicht).
import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Check } from 'lucide-react'
import { EdvanceCard, EmptyState } from '@/components/edvance'
import { Button } from '@/components/ui'
import { naechsteZiel, zielAnteil, zielBereiche, zielReihe, zielStand } from '@/lib/pruefung/gezielt'
import type { PruefBoardZeile, PruefZielStandZeile, PruefZielZeile } from '@/types'
import { AufgabenListe } from './GezieltBausteine'
import { leseUebersprungen } from './uebersprungen'

type Props = {
  liste: PruefZielZeile[]
  stand: PruefZielStandZeile[]
  board: PruefBoardZeile[]
  onOeffne: (taskId: string) => void
  /** Auf eine Kompetenz gefiltert: die Kopfzeile verspricht dann nicht die ganze MSA-LSA. */
  gefiltert?: boolean
}

export function GezieltMsa({ liste, stand, board, onOeffne, gefiltert = false }: Props): JSX.Element {
  const { t } = useTranslation('pruefen')
  const offen = zielStand(liste).offen
  const anteil = zielAnteil(stand)
  const erste = naechsteZiel(zielReihe(liste), board, null, leseUebersprungen())
  const bereiche = zielBereiche(liste, stand)

  return (
    <div className="flex flex-col gap-6">
      <EdvanceCard className="flex flex-col gap-4">
        <p className="text-base font-semibold" data-testid="gezielt-kopf">
          {offen === 0 ? t(gefiltert ? 'gezielt.reicht' : 'gezielt.ziel.fertig')
            : t(gefiltert ? 'gezielt.noch' : 'gezielt.ziel.kopf', { count: offen })}
        </p>
        <div className="h-2.5 w-full overflow-hidden rounded-full bg-[var(--color-bg-subtle)]" role="progressbar"
          aria-valuemin={0} aria-valuemax={100} aria-valuenow={anteil} aria-label={t('gezielt.ziel.fortschritt')}>
          <div className="h-full rounded-full bg-[var(--color-primary)] transition-all" style={{ width: `${anteil}%` }} />
        </div>
        {erste && <Button className="self-start" onClick={() => onOeffne(erste)}>{t('gezielt.start')}</Button>}
      </EdvanceCard>
      {bereiche.length === 0 && <EmptyState icon="🎉" title={t('gezielt.leer')} description={t('gezielt.leerText')} />}
      {bereiche.map((g) => (
        <section key={g.bereich} className="flex flex-col gap-2" data-testid={`bereich-${g.bereich}`}>
          <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t(`gezielt.ziel.bereich.${g.bereich}`, { defaultValue: g.bereich })}
          </h2>
          {g.offen.map(({ zeile, texte }) => (
            <EdvanceCard key={zeile.skill_key} className="flex flex-col gap-2 p-4">
              <p className="flex flex-wrap items-center justify-between gap-2 text-sm font-semibold">
                {zeile.skill_label}
                <span className="text-xs font-normal tabular-nums text-[var(--color-text-tertiary)]">
                  {t('gezielt.ziel.nVon', { n: texte })}
                </span>
              </p>
              <p className="text-xs text-[var(--color-text-tertiary)]">
                {zeile.rest > 0 ? t('gezielt.noch', { count: zeile.rest }) : t('gezielt.reicht')}
              </p>
              <AufgabenListe ids={zeile.task_ids} board={board} onOeffne={onOeffne} />
            </EdvanceCard>
          ))}
          {g.ohneVorschlag.length > 0 && (
            <p className="text-xs text-[var(--color-text-tertiary)]">
              {t('gezielt.ziel.ohneVorschlag', { count: g.ohneVorschlag.length })}
            </p>
          )}
          {g.erledigt.length > 0 && (
            <details className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4">
              <summary className="flex min-h-[44px] cursor-pointer items-center gap-2 text-sm text-[var(--color-text-secondary)]">
                <Check aria-hidden className="h-4 w-4 text-[var(--color-success)]" />
                {t('gezielt.ziel.erledigt', { count: g.erledigt.length })}
              </summary>
              <ul className="flex flex-col gap-1 pb-2">
                {g.erledigt.map((s) => (
                  <li key={s.skill_key} className="flex items-center gap-2 text-sm">
                    <Check aria-label={t('gezielt.ziel.erledigtHaken')} className="h-4 w-4 text-[var(--color-success)]" />
                    {s.skill_label}
                  </li>
                ))}
              </ul>
            </details>
          )}
        </section>
      ))}
    </div>
  )
}
