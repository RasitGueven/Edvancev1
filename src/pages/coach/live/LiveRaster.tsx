import { AlertTriangle, Award, CheckCircle2 } from 'lucide-react'
import { sortiereWarteschlange, SIGNAL_RANG } from '@/lib/session/coachLiveLogik'
import { EdvanceCard } from '@/components/edvance/EdvanceCard'
import { cn } from '@/lib/utils'
import type { CoachLiveKind, KachelStatus } from '@/types/coachLive'
import { Abschnitt, Pille, Platz, Punkte, Sequenzbalken } from './bausteine'
import { useLive } from './LiveKontext'
import { useLiveTexte } from './useLiveTexte'

/** Statusfarbe nur aus Zustaenden: neutral laeuft, Bernstein haengt/Entscheidung, Navy Kandidat, Gruen erst nach Bestaetigung. */
const KACHEL: Record<KachelStatus, { rahmen: string; band: string }> = {
  laeuft: { rahmen: 'border-[var(--color-border)]', band: 'bg-[var(--color-bg-subtle)]/50 text-[var(--color-text-tertiary)]' },
  haengt: {
    rahmen: 'border-[var(--color-gold-warning)]/40',
    band: 'bg-[var(--color-gold-warning-light)] text-[var(--color-gold-warning)] border-[var(--color-gold-warning)]/40',
  },
  entscheidung: {
    rahmen: 'border-[var(--color-gold-warning)]/40',
    band: 'bg-[var(--color-gold-warning-light)] text-[var(--color-gold-warning)] border-[var(--color-gold-warning)]/40',
  },
  kandidat: { rahmen: 'border-primary/30', band: 'bg-[var(--color-primary)] text-[var(--color-text-inverse)] border-[var(--color-primary)]' },
  hinweis: { rahmen: 'border-[var(--color-border)]', band: 'bg-[var(--color-primary-light)] text-[var(--color-primary)]' },
  gemeistert: { rahmen: 'border-[var(--color-success)]/30', band: 'bg-[var(--color-success-light)] text-[var(--color-success)]' },
}

const QUEUE_NR: Record<number, string> = {
  0: 'bg-[var(--color-primary)] text-[var(--color-text-inverse)]',
  1: 'bg-[var(--color-gold-warning-light)] text-[var(--color-gold-warning)]',
  2: 'bg-[var(--color-gold-warning-light)] text-[var(--color-gold-warning)]',
  3: 'bg-[var(--color-primary-light)] text-[var(--color-primary)]',
}

function BandIcon({ status }: { status: KachelStatus }): JSX.Element | null {
  if (status === 'kandidat') return <Award className="h-4 w-4" aria-hidden />
  if (status === 'haengt' || status === 'entscheidung') return <AlertTriangle className="h-4 w-4" aria-hidden />
  if (status === 'gemeistert') return <CheckCircle2 className="h-4 w-4" aria-hidden />
  return null
}

function KindKachel({ kind, gewaehlt }: { kind: CoachLiveKind; gewaehlt: boolean }): JSX.Element {
  const { raum, oeffneKind } = useLive()
  const tx = useLiveTexte()
  const stil = KACHEL[kind.status]
  const zeile = kind.taetigkeit.art === 'checkin' ? (tx.ankunft(kind, raum.session.beginn) ?? '') : kind.skill
  return (
    <button
      type="button"
      onClick={() => oeffneKind(kind.id)}
      aria-label={tx.t('raster.oeffnen', { name: kind.name })}
      className={cn(
        'flex min-h-[178px] flex-col gap-1.5 overflow-hidden rounded-[var(--radius-lg)] border bg-[var(--color-bg-surface)] pb-3 text-left shadow-xs transition-shadow duration-150 hover:shadow-md',
        stil.rahmen,
        gewaehlt && 'outline outline-2 outline-offset-1 outline-[var(--color-primary)]',
      )}
    >
      <span className={cn('flex min-h-8 items-center gap-1.5 border-b border-[var(--color-bg-subtle)] px-4 py-1.5 text-xs font-semibold', stil.band)}>
        <BandIcon status={kind.status} />
        {tx.band(kind, raum.zeitpunkt)}
      </span>
      <span className="flex items-center gap-2 px-4 pt-1">
        <Platz nr={kind.tablet} />
        <b className="text-base font-semibold text-[var(--color-text-primary)]">{kind.vorname}</b>
        <span className="ml-auto text-xs text-[var(--color-text-tertiary)]">{tx.t('raster.klasse', { klasse: kind.klasse })}</span>
      </span>
      <span className="px-4 text-xs text-[var(--color-text-tertiary)]">{tx.taetigkeit(kind)}</span>
      {tx.phaseZeile(kind) && (
        <span className="px-4 text-xs text-[var(--color-text-secondary)]" data-testid="kachel-phase">
          {tx.phaseZeile(kind)}
        </span>
      )}
      <span className="px-4 text-sm font-medium leading-snug text-[var(--color-text-primary)]">{zeile}</span>
      <span className="flex items-center gap-2 px-4 pt-0.5 text-xs text-[var(--color-text-secondary)]">
        {kind.sequenzBalken ? <Sequenzbalken staende={kind.sequenzBalken} /> : <Punkte folge={kind.ergebnisfolge} />}
        {kind.aufgabeNr !== null && <span>{tx.t('raster.aufgabe', { nr: kind.aufgabeNr })}</span>}
      </span>
      <span className="mt-auto px-4 text-xs text-[var(--color-text-tertiary)]">{tx.meta(kind.meta)}</span>
    </button>
  )
}

/** Warm-up und Kernarbeit: Kacheln je Kind, daneben die Warteschlange. */
export function LiveRaster({ gewaehlt }: { gewaehlt: string | null }): JSX.Element {
  const { raum, oeffneKind, kind } = useLive()
  const tx = useLiveTexte()
  const max = Number(raum.einstellungen.mastery_kandidaten_je_raum ?? 3)
  const queue = sortiereWarteschlange(raum.signale, { masteryJeRaum: max, masteryEntschieden: raum.masteryEntschieden })
  const kinder = [...raum.kinder].sort((a, b) => (a.tablet ?? 99) - (b.tablet ?? 99))

  return (
    <div className="grid items-start gap-6 @min-[900px]:grid-cols-[minmax(0,1fr)_310px]">
      <Abschnitt titel={tx.t('raster.titel', { raum: raum.session.raum, phase: tx.t(`phase.${raum.zeitpunkt}`) })} zusatz={tx.t('raster.tippen')}>
        {raum.session.testlauf && (
          <div data-testid="testlauf-raster">
            <Pille ton="warn">{tx.t('raster.testlauf')}</Pille>
          </div>
        )}
        <div className="grid grid-cols-[repeat(auto-fill,minmax(232px,1fr))] gap-3">
          {kinder.map((k) => (
            <KindKachel key={k.id} kind={k} gewaehlt={gewaehlt === k.id} />
          ))}
        </div>
        <div className="mt-2 flex flex-wrap gap-4 text-xs text-[var(--color-text-tertiary)]">
          {(['richtig', 'falsch', 'hinweis', 'aktuell'] as const).map((m) => (
            <span key={m} className="inline-flex items-center gap-1.5">
              <Punkte folge={[m]} />
              {tx.t(`legende.${m}`)}
            </span>
          ))}
        </div>
      </Abschnitt>

      <aside className="-order-1 @min-[900px]:order-none">
        <Abschnitt titel={tx.t('queue.titel')} zusatz={tx.t('queue.offen', { count: queue.length })}>
          <EdvanceCard className="p-1.5 hover:shadow-xs">
            {queue.length === 0 ? (
              <p className="flex items-center gap-2 px-3 py-4 text-sm font-medium text-[var(--color-success)]">
                <CheckCircle2 className="h-5 w-5" aria-hidden />
                {tx.t('queue.leer')}
              </p>
            ) : (
              <ol className="divide-y divide-[var(--color-bg-subtle)]">
                {queue.map((s, i) => (
                  <li key={`${s.kindId}:${s.art}`}>
                    <button
                      type="button"
                      onClick={() => oeffneKind(s.kindId)}
                      className="grid min-h-[62px] w-full grid-cols-[28px_minmax(0,1fr)_auto] items-center gap-2 rounded-[var(--radius-md)] px-2.5 py-2 text-left hover:bg-[var(--color-bg-subtle)]/50"
                    >
                      <span className={cn('inline-flex h-7 w-7 items-center justify-center rounded-full text-xs font-bold', QUEUE_NR[SIGNAL_RANG[s.art]])}>
                        {i + 1}
                      </span>
                      <span className="min-w-0">
                        <b className="block text-sm font-semibold leading-snug text-[var(--color-text-primary)]">
                          {tx.t('queue.zeile', { name: kind(s.kindId).vorname, titel: tx.signalTitel(s, raum.zeitpunkt) })}
                        </b>
                        <span className="block text-xs leading-snug text-[var(--color-text-tertiary)]">{tx.signalGrund(s, raum.einstellungen)}</span>
                      </span>
                      <span className="self-start whitespace-nowrap pt-1 text-xs tabular-nums text-[var(--color-text-tertiary)]">
                        {tx.alter(s.seit, raum.session.jetzt)}
                      </span>
                    </button>
                  </li>
                ))}
              </ol>
            )}
          </EdvanceCard>
          <p className="text-xs text-[var(--color-text-tertiary)]">
            {tx.t('queue.mastery', { entschieden: raum.masteryEntschieden, max })}
          </p>
        </Abschnitt>
      </aside>
    </div>
  )
}
