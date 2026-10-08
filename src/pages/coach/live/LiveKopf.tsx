import { ChevronLeft } from 'lucide-react'
import { minuteImAblauf, segmentZustand, SESSION_MINUTEN } from '@/lib/session/coachLiveLogik'
import { cn } from '@/lib/utils'
import type { CoachLiveRaum, LiveZeitpunkt } from '@/types/coachLive'
import type { SessionPhase } from '@/types/sessionLive'
import { Pille } from './bausteine'
import { useLiveTexte } from './useLiveTexte'

type KopfProps = {
  raum: CoachLiveRaum
  /** true, wenn der Coach eine andere Phase ansieht als die Uhr. */
  eigeneAnsicht: boolean
  onZeige: (z: LiveZeitpunkt | null) => void
  onZurueck: () => void
}

/**
 * Kopf der Fokus-Seite: zurueck, Session (mit Testlauf-Kennzeichen), Uhr, darunter die Phasen
 * aus dem Snapshot. Die Phasen sind antippbar: der Coach kann vorziehen (z. B. Check-out).
 */
export function LiveKopf({ raum, eigeneAnsicht, onZeige, onZurueck }: KopfProps): JSX.Element {
  const { t, uhrzeit } = useLiveTexte()
  const s = raum.session
  const minute = minuteImAblauf(s.gestartet ?? s.beginn, s.jetzt)
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
          <span className="flex min-w-0 items-center gap-2">
            <h1 className="truncate font-serif text-xl font-medium text-[var(--color-text-primary)]">
              {t('kopf.titel', { uhrzeit: uhrzeit(s.beginn), raum: s.raum })}
            </h1>
            {s.testlauf && <Pille ton="warn">{t('kopf.testlauf')}</Pille>}
          </span>
          <span className="truncate text-xs text-[var(--color-text-tertiary)]">
            {t('kopf.untertitel', { fach: t(`fach.${s.fach}`, { defaultValue: s.fach }), von: s.klassen[0], bis: s.klassen[1], coach: s.coachName })}
          </span>
        </div>
        <div className="flex flex-col items-end text-right">
          <span className="text-2xl font-semibold tabular-nums text-[var(--color-text-primary)]">{uhrzeit(s.jetzt)}</span>
          <span className="text-xs text-[var(--color-text-tertiary)]">{unterzeile}</span>
        </div>
      </div>
      <Zeitleiste raum={raum} minute={minute} onZeige={onZeige} />
      <KinderPhasen raum={raum} onZeige={onZeige} />
      {s.status === 'active' && (
        <div className="flex flex-wrap items-center justify-end gap-2 px-5 pb-2">
          {eigeneAnsicht && (
            <button type="button" onClick={() => onZeige(null)} className="min-h-[44px] rounded-[var(--radius-md)] px-3 text-sm font-semibold text-[var(--color-primary)] hover:bg-[var(--color-primary-light)]">
              {t('kopf.liveFolgen')}
            </button>
          )}
          <button
            type="button"
            aria-pressed={raum.zeitpunkt === 'danach'}
            onClick={() => onZeige('danach')}
            className="min-h-[44px] rounded-[var(--radius-md)] border border-[var(--color-border)] px-3 text-sm font-semibold text-[var(--color-text-secondary)] hover:bg-[var(--color-bg-subtle)]"
          >
            {t('kopf.abschluss')}
          </button>
        </div>
      )}
    </header>
  )
}

/**
 * F1 (Trockenlauf, Befund A4): in welcher Phase die Kinder wirklich sind (Phasenwechsel vom Tablet),
 * neben der Uhr. Antippen zeigt die Ansicht dieser Phase.
 */
function KinderPhasen({ raum, onZeige }: { raum: CoachLiveRaum; onZeige: (z: LiveZeitpunkt) => void }): JSX.Element | null {
  const { t } = useLiveTexte()
  if (raum.session.status !== 'active') return null
  const zahl = new Map<SessionPhase, number>()
  for (const k of raum.kinder) if (k.tablet !== null && k.phase) zahl.set(k.phase, (zahl.get(k.phase) ?? 0) + 1)
  const phasen = raum.zeitleiste.map((z) => z.phase).filter((p) => zahl.has(p))
  if (phasen.length === 0) return null
  return (
    <div className="flex flex-wrap items-center gap-2 px-5 pb-2 text-xs text-[var(--color-text-tertiary)]" data-testid="kinder-phasen">
      {t('kopf.kinderPhasen')}
      {phasen.map((p) => (
        <button
          key={p}
          type="button"
          onClick={() => onZeige(p)}
          aria-pressed={raum.zeitpunkt === p}
          className="min-h-[44px] rounded-[var(--radius-md)] border border-[var(--color-border)] px-3 text-sm font-semibold text-[var(--color-text-secondary)] hover:bg-[var(--color-bg-subtle)]"
        >
          {t('kopf.kinderPhase', { phase: t(`phase.${p}`), count: zahl.get(p) })}
        </button>
      ))}
    </div>
  )
}

function Zeitleiste({ raum, minute, onZeige }: { raum: CoachLiveRaum; minute: number; onZeige: (z: LiveZeitpunkt) => void }): JSX.Element {
  const waehlbar = raum.session.status === 'active'
  const { t } = useLiveTexte()
  const gesamt = raum.zeitleiste.reduce((s, z) => s + z.minuten, 0) || SESSION_MINUTEN
  return (
    <div className="border-t border-[var(--color-border)] px-5 py-2">
      <div className="relative flex h-11 gap-1" role="group" aria-label={t('kopf.zeitleiste')} title={t('kopf.ansicht')}>
        {raum.zeitleiste.map((z, i) => {
          const zustand = segmentZustand(raum.zeitleiste, i, minute)
          return (
            <button
              type="button"
              disabled={!waehlbar}
              onClick={() => onZeige(z.phase)}
              key={z.phase}
              aria-current={zustand === 'jetzt' ? 'step' : undefined}
              aria-pressed={raum.zeitpunkt === z.phase}
              // flex-grow ist dynamisch (Minuten aus dem Snapshot).
              style={{ flexGrow: z.minuten, flexBasis: 0 }}
              className={cn(
                'flex min-w-0 items-center justify-center truncate rounded-lg px-1 text-xs font-semibold disabled:cursor-default',
                raum.zeitpunkt === z.phase && 'ring-2 ring-inset ring-[var(--color-gold-altgold)]',
                zustand === 'vorbei' && 'bg-primary/20 text-[var(--color-primary)]',
                zustand === 'jetzt' && 'bg-[var(--color-primary)] text-[var(--color-text-inverse)]',
                zustand === 'kommt' && 'bg-[var(--color-bg-subtle)] text-[var(--color-text-secondary)]',
              )}
            >
              {t(`phase.${z.phase}`)}
            </button>
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
