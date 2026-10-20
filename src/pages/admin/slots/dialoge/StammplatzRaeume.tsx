import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EmptyState, LoadingPulse } from '@/components/edvance'
import type { StammplatzVorschauZeile, Takt } from '@/types/slotplan'
import { datumKurz } from '../slotsFormat'
import { PLAETZE } from '../wochenplan/wochenplan.model'
import { kennzeichen, raumStand, vorschauSatz, type Kennzeichen, type StammRaum } from './stammplatz.model'

const KENNZEICHEN_FARBE: Record<Kennzeichen, 'strength' | 'warning' | 'muted'> = {
  geplant: 'strength',
  entfaellt: 'warning',
  keinBetrieb: 'muted',
  andereWoche: 'muted',
}

/** Vorschau eines Raums; fehler = i18n-Schlüssel, wenn stammplatz_vorschau für diesen Raum scheiterte. */
export type RaumVorschau = { zeilen: StammplatzVorschauZeile[]; fehler: string | null }

type T = (k: string, o?: Record<string, unknown>) => string

/** Warum ein Raum nicht wählbar ist, als Satz (auch für die Gründe unter „Speichern“); null = wählbar. */
export function sperrSatz(v: RaumVorschau, raum: string, beginn: string, takt: Takt, t: T, sprache: string): string | null {
  if (v.fehler) return t('kinder2.sperre.fehler', { raum, fehler: t(v.fehler) })
  const stand = raumStand(v.zeilen, takt)
  if (!stand.sperre || !stand.datum) return null
  const datum = datumKurz(stand.datum, sprache)
  if (stand.sperre === 'ohne_coach') return t('kinder2.sperre.ohneCoach', { raum, datum, beginn })
  return t(stand.sperre === 'voll' ? 'kinder2.sperre.voll' : 'kinder2.sperre.keinPlatz', { raum, datum, max: PLAETZE })
}

/**
 * Je aktivem Raum eine Karte (Bauauftrag W3, Entscheidung 3): Coach der Schicht oder „kein Coach eingeteilt“,
 * „n von 5 frei“ am ersten Termin. Volle Räume und Räume ohne Coach sind nicht wählbar und sagen warum (S4 offen).
 */
export function StammplatzRaeume({
  raeume,
  vorschau,
  beginn,
  takt,
  gewaehlt,
  onWahl,
}: {
  raeume: StammRaum[]
  /** null = lädt. */
  vorschau: Record<string, RaumVorschau> | null
  beginn: string
  takt: Takt
  gewaehlt: string | null
  onWahl: (raumId: string) => void
}): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  if (raeume.length === 0) return <EmptyState icon="🚪" title={t('kinder2.raum.keinerTitel')} description={t('kinder2.raum.keinerText')} />
  if (!vorschau) return <LoadingPulse type="list" lines={2} />
  return (
    <div role="group" aria-label={t('kinder2.raum.titel')} className="grid grid-cols-1 gap-2 @md:grid-cols-2 @3xl:grid-cols-4">
      {raeume.map((r) => {
        const v = vorschau[r.id] ?? { zeilen: [], fehler: null }
        const stand = raumStand(v.zeilen, takt)
        const sperre = sperrSatz(v, r.name, beginn, takt, t, i18n.language)
        const an = r.id === gewaehlt
        const frei = stand.datum
          ? t('kinder2.raum.frei', { frei: stand.frei, max: PLAETZE, datum: datumKurz(stand.datum, i18n.language) })
          : t('kinder2.raum.keinTermin')
        return (
          <button
            key={r.id}
            type="button"
            aria-pressed={an}
            disabled={sperre !== null}
            title={sperre ?? undefined}
            onClick={() => onWahl(r.id)}
            className={`flex min-h-[44px] flex-col items-start gap-1 rounded-[var(--radius-md)] border p-4 text-left transition-colors duration-150 ease-out disabled:cursor-not-allowed ${
              an
                ? 'border-[var(--color-primary)] bg-[var(--color-primary-light)]'
                : sperre
                  ? 'border-[var(--color-border)] bg-[var(--color-bg-subtle)]'
                  : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] hover:border-[var(--color-primary)]'
            }`}
          >
            <span className="text-sm font-semibold text-[var(--color-text-primary)]">{r.name}</span>
            {stand.datum && !v.fehler && (
              <span className="text-xs text-[var(--color-text-secondary)]">{stand.coach_name ?? t('kinder2.raum.keinCoach')}</span>
            )}
            {sperre ? (
              <span className="text-xs font-semibold text-[var(--color-error-coach)]">{sperre}</span>
            ) : (
              <span className="text-xs tabular-nums text-[var(--color-text-tertiary)]">{frei}</span>
            )}
          </button>
        )
      })}
    </div>
  )
}

/** „Die nächsten Termine“ aus stammplatz_vorschau: Datum, Kennzeichen und Grund als Satz (Entscheidung 5). */
export function StammplatzTermine({ zeilen, raum, takt }: { zeilen: StammplatzVorschauZeile[]; raum: string; takt: Takt }): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  return (
    <ul aria-label={t('kinder2.termine.titel')} className="flex flex-col">
      {zeilen.map((z) => {
        const k = kennzeichen(z.ergebnis)
        return (
          <li key={z.datum} className="grid grid-cols-[5.5rem_auto_minmax(0,1fr)] items-center gap-2 border-t border-[var(--color-border)] py-2 text-sm">
            <span className="whitespace-nowrap font-semibold tabular-nums">{datumKurz(z.datum, i18n.language)}</span>
            <span><EdvanceBadge variant={KENNZEICHEN_FARBE[k]}>{t(`kinder2.kennzeichen.${k}`)}</EdvanceBadge></span>
            <span className="text-[var(--color-text-secondary)]">{vorschauSatz(z, raum, takt, t)}</span>
          </li>
        )
      })}
    </ul>
  )
}
