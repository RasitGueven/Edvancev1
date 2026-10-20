import { Link, type To } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { datumKurz, datumTagMonat, wochentagName } from '../slotsFormat'
import type { Block, CoachDaten } from './coaches.model'

type Props = {
  coach: CoachDaten
  bloecke: Block[]
  kw: number
  /** Ziel des Slot-Panels eines Termins (W2), im selben Reiter. */
  panelZiel: (datum: string, zeitId: string) => To
  onRaumAendern: (b: Block) => void
  onEntfernen: (b: Block) => void
}

/**
 * W4, Entscheidung 1: je Coach eine Karte mit Name, Stunden pro Woche und den Blöcken („Mo 14:00–18:00“, Raum,
 * Stammplätze dort, „Raum ändern“ und „Entfernen“). Darunter die Abweichungen der Woche als Verweis ins Slot-Panel
 * (Entscheidung 5: geändert werden sie dort, nicht hier).
 */
export function CoachKarte({ coach, bloecke, kw, panelZiel, onRaumAendern, onEntfernen }: Props): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const name = coach.name ?? t('kind.ohneName')

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <div className="flex flex-wrap items-baseline justify-between gap-2">
        <h3 className="text-base font-semibold">{name}</h3>
        <span className="text-xs tabular-nums text-[var(--color-text-tertiary)]">{t('coaches2.stunden', { count: coach.stunden_pro_woche })}</span>
      </div>

      {bloecke.length === 0 ? (
        <p className="text-sm text-[var(--color-text-tertiary)]">{t('coaches2.keineSchicht')}</p>
      ) : (
        <ul className="flex flex-col" aria-label={t('coaches2.liste')}>
          {bloecke.map((b) => {
            const tag = wochentagName(b.wochentag, i18n.language)
            const zeit = t('coaches2.block', { tag, beginn: b.beginn, ende: b.ende })
            const label = t('coaches2.blockLabel', { coach: name, tag, beginn: b.beginn, ende: b.ende, raum: b.raumName })
            return (
              <li key={b.schluessel} aria-label={label}
                className="flex flex-wrap items-center gap-2 border-t border-[var(--color-border)] py-2 first:border-t-0">
                <span className="flex min-w-[14rem] flex-1 flex-wrap items-center gap-2">
                <span className="text-sm font-semibold tabular-nums">{zeit}</span>
                <EdvanceBadge variant="primary">{t('coaches2.raum', { raum: b.raumName })}</EdvanceBadge>
                {b.ab && <EdvanceBadge variant="warning">{t('coaches2.ab', { datum: datumTagMonat(b.ab, i18n.language) })}</EdvanceBadge>}
                {b.gueltigBis && <EdvanceBadge variant="muted">{t('coaches2.bis', { datum: datumTagMonat(b.gueltigBis, i18n.language) })}</EdvanceBadge>}
                <span className="text-xs tabular-nums text-[var(--color-text-tertiary)]">{t('coaches2.stammplaetze', { count: b.stammplaetze })}</span>
                </span>
                <span className="flex shrink-0 gap-2">
                  <Button type="button" variant="ghost" onClick={() => onRaumAendern(b)} aria-label={t('coaches2.raumAendernLabel', { block: label })}>
                    {t('coaches2.raumAendern')}
                  </Button>
                  <Button type="button" variant="ghost" onClick={() => onEntfernen(b)} aria-label={t('coaches2.entfernenLabel', { block: label })}
                    className="text-[var(--color-error-coach)]">
                    {t('coaches2.entfernen')}
                  </Button>
                </span>
              </li>
            )
          })}
        </ul>
      )}

      {coach.abweichungen.length > 0 && (
        <div className="flex flex-col gap-2 border-t border-[var(--color-border)] pt-4">
          <h4 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('coaches2.abweichungen', { kw })}</h4>
          <ul className="flex flex-col">
            {coach.abweichungen.map((a) => (
              <li key={`${a.datum}-${a.zeit_id}-${a.raum_id}`}>
                <Link to={panelZiel(a.datum, a.zeit_id)} state={{ panel: true }}
                  aria-label={t('coaches2.abweichungLabel', { datum: datumKurz(a.datum, i18n.language), beginn: a.beginn, raum: a.raum_name })}
                  className="flex min-h-[44px] items-center justify-between gap-2 rounded-[var(--radius-md)] px-2 text-sm hover:bg-[var(--color-bg-subtle)]">
                  <span className="tabular-nums">{`${datumKurz(a.datum, i18n.language)} ${a.beginn} · ${a.raum_name}`}</span>
                  <EdvanceBadge variant={a.art === 'faellt_aus' ? 'coach-emergency' : 'warning'}>{t(`raumArt.${a.art}`)}</EdvanceBadge>
                </Link>
              </li>
            ))}
          </ul>
          <p className="text-xs text-[var(--color-text-tertiary)]">{t('coaches2.abweichungenSatz')}</p>
        </div>
      )}
    </EdvanceCard>
  )
}
