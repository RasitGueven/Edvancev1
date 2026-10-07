import { ChevronLeft } from 'lucide-react'
import { minuteImAblauf, segmentZustand, SESSION_MINUTEN } from '@/lib/session/coachLiveLogik'
import { cn } from '@/lib/utils'
import type { CoachLiveRaum } from '@/types/coachLive'
import { useLiveTexte } from './useLiveTexte'

/** Kopf der Fokus-Seite: zurueck, Session, Uhr, darunter die Phasen aus dem Snapshot. */
export function LiveKopf({ raum, onZurueck }: { raum: CoachLiveRaum; onZurueck: () => void }): JSX.Element {
  const { t, uhrzeit } = useLiveTexte()
  const s = raum.session
  const minute = minuteImAblauf(s.beginn, s.jetzt)
  const unterzeile =
    minute < 0
      ? t('kopf.beginntIn', { count: -minute })
      : minute > SESSION_MINUTEN
        ? t('kopf.vorbei', { count: minute - SESSION_MINUTEN })
        : t('kopf.minute', { minute, dauer: SESSION_MINUTEN })

  return (
    <header className="flex-none border-b border-[var(--color-border)] bg-[var(--color-bg-surface)]">
      <div className="flex items-center gap-4 px-5 py-2">
        <button
          type="button"
          onClick={onZurueck}
          className="inline-flex min-h-[44px] items-center gap-1 rounded-[var(--radius-md)] pl-1 pr-3 text-sm font-semibold text-[var(--color-primary)] hover:bg-[var(--color-primary-light)]"
        >
          <ChevronLeft className="h-5 w-5" aria-hidden />
          {t('kopf.zurueck')}
        </button>
        <div className="flex min-w-0 flex-1 flex-col">
          <h1 className="truncate font-serif text-xl font-medium text-[var(--color-text-primary)]">
            {t('kopf.titel', { uhrzeit: uhrzeit(s.beginn), raum: s.raum })}
          </h1>
          <span className="truncate text-xs text-[var(--color-text-tertiary)]">
            {t('kopf.untertitel', { fach: s.fach, von: s.klassen[0], bis: s.klassen[1], coach: s.coachName })}
          </span>
        </div>
        <div className="flex flex-col items-end text-right">
          <span className="text-2xl font-semibold tabular-nums text-[var(--color-text-primary)]">{uhrzeit(s.jetzt)}</span>
          <span className="text-xs text-[var(--color-text-tertiary)]">{unterzeile}</span>
        </div>
      </div>
      <Zeitleiste raum={raum} minute={minute} />
    </header>
  )
}

function Zeitleiste({ raum, minute }: { raum: CoachLiveRaum; minute: number }): JSX.Element {
  const { t } = useLiveTexte()
  const gesamt = raum.zeitleiste.reduce((s, z) => s + z.minuten, 0) || SESSION_MINUTEN
  return (
    <div className="border-t border-[var(--color-border)] px-5 py-2">
      <div className="relative flex h-8 gap-1" role="list" aria-label={t('kopf.zeitleiste')}>
        {raum.zeitleiste.map((z, i) => {
          const zustand = segmentZustand(raum.zeitleiste, i, minute)
          return (
            <div
              key={z.phase}
              role="listitem"
              aria-current={zustand === 'jetzt' ? 'step' : undefined}
              // flex-grow ist dynamisch (Minuten aus dem Snapshot).
              style={{ flexGrow: z.minuten, flexBasis: 0 }}
              className={cn(
                'flex min-w-0 items-center justify-center truncate rounded-lg px-1 text-xs font-semibold',
                zustand === 'vorbei' && 'bg-primary/20 text-[var(--color-primary)]',
                zustand === 'jetzt' && 'bg-[var(--color-primary)] text-[var(--color-text-inverse)]',
                zustand === 'kommt' && 'bg-[var(--color-bg-subtle)] text-[var(--color-text-secondary)]',
              )}
            >
              {t(`phase.${z.phase}`)}
            </div>
          )
        })}
        {minute >= 0 && minute <= gesamt && (
          <span
            aria-hidden
            style={{ left: `${((minute / gesamt) * 100).toFixed(2)}%` }}
            className="absolute -bottom-1.5 -top-1.5 -ml-px w-[3px] rounded-full bg-[var(--color-gold-altgold)]"
          />
        )}
      </div>
      <div className="mt-1 flex gap-1">
        {raum.zeitleiste.map((z) => (
          <span
            key={z.phase}
            style={{ flexGrow: z.minuten, flexBasis: 0 }}
            className="min-w-0 truncate text-center text-xs text-[var(--color-text-tertiary)]"
          >
            {t('kopf.dauer', { count: z.minuten })}
          </span>
        ))}
      </div>
    </div>
  )
}
