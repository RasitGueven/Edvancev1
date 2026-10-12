import { useTranslation } from 'react-i18next'
import { EdvanceBadge } from '@/components/edvance'
import type { Planbilanz } from '@/types/slotplan'
import { datumKurz, datumTagMonat, datumVoll } from '../slotsFormat'
import { planbilanzVariante } from '../slots.model'

/**
 * Einheiten als Stapelbalken: verbraucht (primary), geplant (primary-light), frei (nur Rand).
 * Die Breiten sind berechnet und stehen deshalb als Inline-Style (CLAUDE.md §11).
 */
export function EinheitenBalken({ verbraucht, geplant, gesamt }: { verbraucht: number; geplant: number; gesamt: number }): JSX.Element {
  const { t } = useTranslation('slots')
  const anteil = (n: number): string => `${gesamt > 0 ? Math.min(100, Math.max(0, (n / gesamt) * 100)) : 0}%`
  return (
    <div
      role="img"
      aria-label={t('einheiten.balkenLabel', { verbraucht, geplant, gesamt })}
      className="flex h-2 w-full overflow-hidden rounded-[var(--radius-full)] border border-[var(--color-border)] bg-[var(--color-bg-surface)]"
    >
      <span className="h-full bg-[var(--color-primary)]" style={{ width: anteil(verbraucht) }} />
      <span className="h-full bg-[var(--color-primary-light)]" style={{ width: anteil(geplant) }} />
    </div>
  )
}

/** Planbilanz als Abzeichen (Entscheidung 12, Farbe nach Entscheidung 28). */
export function PlanbilanzBadge({ planbilanz, vertragLaeuft }: { planbilanz: Pick<Planbilanz, 'art' | 'datum' | 'zahl'>; vertragLaeuft: boolean }): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  return (
    <EdvanceBadge variant={planbilanzVariante(planbilanz.art, vertragLaeuft)}>
      {t(`planbilanz.art.${planbilanz.art}`, {
        datum: planbilanz.datum ? datumTagMonat(planbilanz.datum, i18n.language) : '',
        count: planbilanz.zahl ?? 0,
      })}
    </EdvanceBadge>
  )
}

/** Der Satz zur Planbilanz (Wortlaut nach Anforderung J 57). */
export function planbilanzSatz(pb: Planbilanz, t: (k: string, o?: Record<string, unknown>) => string, sprache: string): string {
  const letzter = pb.letzter_termin ? datumVoll(pb.letzter_termin, sprache) : ''
  const saetze: string[] = []
  if (pb.art === 'kein_stammplatz') saetze.push(t('planbilanz.satz.kein_stammplatz', { count: pb.ohne_termin }))
  if (pb.art === 'aufgebraucht') saetze.push(t('planbilanz.satz.aufgebraucht'))
  if (pb.art === 'reicht_bis') saetze.push(t('planbilanz.satz.reicht_bis', { count: pb.ohne_einheit, datum: letzter }))
  if (pb.art === 'ohne_termin') saetze.push(t('planbilanz.satz.ohne_termin', { count: pb.ohne_termin }))
  if (pb.art === 'passt') {
    saetze.push(letzter ? t('planbilanz.satz.passt', { datum: letzter }) : t('planbilanz.satz.passtOhneDatum'))
    if (pb.abweichung) saetze.push(t(`planbilanz.satz.abweichung.${pb.abweichung.art}`, { count: pb.abweichung.zahl }))
  }
  if (pb.uebersprungen && pb.uebersprungen.length > 0) {
    saetze.push(t('planbilanz.satz.uebersprungen', { daten: pb.uebersprungen.map((d) => datumKurz(d, sprache)).join(', ') }))
  }
  if (pb.hinweis === 'SL012') saetze.push(t('planbilanz.satz.ferientabelle'))
  return saetze.join(' ')
}
