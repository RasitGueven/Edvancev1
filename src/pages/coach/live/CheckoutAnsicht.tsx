import { useState } from 'react'
import { Check, Home } from 'lucide-react'
import { EdvanceCard } from '@/components/edvance/EdvanceCard'
import { Button } from '@/components/ui/button'
import { abschlussSetzen, questTerminSetzenCoach } from '@/lib/session/coachLive'
import { cn } from '@/lib/utils'
import type { CoachLiveKind } from '@/types/coachLive'
import { Abschnitt, Chip, Feldname, Pille, Platz } from './bausteine'
import { useLive } from './LiveKontext'
import { useLiveTexte } from './useLiveTexte'

const FELD = 'w-full rounded-[var(--radius-md)] border border-[var(--color-neutral-unknown)] bg-[var(--color-bg-surface)] px-3 text-sm'

function CheckoutKarte({ kind }: { kind: CoachLiveKind }): JSX.Element {
  const { sessionId, ausfuehren } = useLive()
  const tx = useLiveTexte()
  const c = kind.checkout
  const [satz, setSatz] = useState(c.satz)
  const [notiz, setNotiz] = useState(c.notiz)
  const setzen = (e: Parameters<typeof abschlussSetzen>[2], erfolg?: string): void =>
    void ausfuehren(abschlussSetzen(sessionId, kind.id, e), erfolg)

  const andererVorschlag = (): void => {
    const i = c.satzVorschlaege.indexOf(satz)
    const neu = c.satzVorschlaege[(i + 1) % c.satzVorschlaege.length]
    setSatz(neu)
    setzen({ satzText: neu })
  }

  const exitOffen = c.exit.gesamt === 0
  const exitOk = !exitOffen && c.exit.richtig === c.exit.gesamt
  return (
    <EdvanceCard className={cn('flex flex-col gap-2.5 px-4 py-4 hover:shadow-xs', c.gesagt && 'border-[var(--color-success)]/30')}>
      <header className="flex items-center gap-2">
        <Platz nr={kind.tablet} />
        <b className="min-w-0 flex-1 text-base font-semibold">{kind.name}</b>
        <Pille ton={exitOk ? 'ok' : 'neutral'}>{exitOffen ? tx.t('checkout.exitOffen') : tx.t('checkout.exit', c.exit)}</Pille>
      </header>
      <span className="text-xs text-[var(--color-text-tertiary)]">
        {tx.t('checkout.zusammenfassung', { aufgaben: c.aufgaben, richtig: c.richtig, schwerpunkt: c.schwerpunkt })}
        {c.eingriffe > 0 && ` · ${tx.t('checkout.eingriffe', { count: c.eingriffe })}`}
      </span>
      <Feldname htmlFor={`satz-${kind.id}`}>{tx.t('checkout.satz', { name: kind.vorname })}</Feldname>
      <textarea
        id={`satz-${kind.id}`}
        value={satz}
        onChange={(e) => setSatz(e.target.value)}
        onBlur={() => satz !== c.satz && setzen({ satzText: satz })}
        className={cn(FELD, 'min-h-[76px] resize-y py-2.5 text-base leading-snug')}
      />
      <div className="flex flex-wrap items-center gap-2">
        {c.satzVorschlaege.length > 1 && (
          <button type="button" onClick={andererVorschlag} className="min-h-[44px] text-sm font-semibold text-[var(--color-primary)] hover:underline">
            {tx.t('checkout.andererVorschlag')}
          </button>
        )}
        <span className="flex-1" />
        <Button
          size="md"
          variant={c.gesagt ? 'primary' : 'outline'}
          className={cn(c.gesagt && 'bg-[var(--color-success)]')}
          onClick={() => setzen({ satzText: satz, satzGesagt: !c.gesagt })}
        >
          {c.gesagt && <Check className="h-4 w-4" aria-hidden />}
          {c.gesagt ? tx.t('checkout.gesagt') : tx.t('checkout.alsGesagt')}
        </Button>
      </div>
      {c.questsAktiv && (
      <div className="flex items-start gap-1.5 text-sm text-[var(--color-text-secondary)]">
        <Home className="mt-0.5 h-4 w-4 flex-none" aria-hidden />
        <div className="flex flex-col gap-1">
          {c.questA.termin ? (
            <span>
              <b className="font-semibold text-[var(--color-text-primary)]">{tx.t('checkout.questA', { termin: tx.termin(c.questA.termin) })}</b>{' '}
              <span className="text-[var(--color-text-tertiary)]">
                ({c.questA.von === 'coach' ? tx.t('checkout.questACoach') : tx.t('checkout.questAVon', { name: kind.vorname })})
              </span>
            </span>
          ) : (
            <>
              <span className="text-[var(--color-gold-warning)]">{tx.t('checkout.questAOffen')}</span>
              <span className="text-xs text-[var(--color-text-tertiary)]">{tx.t('checkout.questAWaehlen', { name: kind.vorname })}</span>
              <span className="flex flex-wrap gap-1.5">
                {c.questAVorschlaege.map((iso) => (
                  <Chip
                    key={iso}
                    aktiv={false}
                    onClick={() => void ausfuehren(questTerminSetzenCoach(sessionId, kind.id, iso), tx.t('toast.quest', { name: kind.vorname }))}
                  >
                    {tx.termin(iso)}
                  </Chip>
                ))}
              </span>
            </>
          )}
          {c.questB && (
            <span>
              {c.questB.paketKlassenarbeit
                ? tx.t('checkout.questBPaket', { termin: tx.tagDatum(c.questB.termin) })
                : tx.t('checkout.questB', { termin: tx.tagDatum(c.questB.termin) })}
            </span>
          )}
        </div>
      </div>
      )}
      <Feldname htmlFor={`notiz-${kind.id}`}>{tx.t('checkout.notiz')}</Feldname>
      <input
        id={`notiz-${kind.id}`}
        value={notiz}
        onChange={(e) => setNotiz(e.target.value)}
        onBlur={() => notiz !== c.notiz && setzen({ notiz })}
        placeholder={tx.t('checkout.notizPlatzhalter')}
        className={cn(FELD, 'min-h-[44px]')}
      />
      <div className="flex flex-wrap gap-1.5">
        <Chip aktiv={c.flags.eltern} onClick={() => setzen({ flagEltern: !c.flags.eltern })}>
          {tx.t('checkout.flagEltern')}
        </Chip>
        <Chip aktiv={c.flags.pfad} onClick={() => setzen({ flagPfad: !c.flags.pfad })}>
          {tx.t('checkout.flagPfad')}
        </Chip>
      </div>
    </EdvanceCard>
  )
}

/** Check-out: ein konkreter Satz je Kind (Vorschlag aus Bausteinen, der Coach bestaetigt). */
export function CheckoutAnsicht(): JSX.Element {
  const { raum } = useLive()
  const tx = useLiveTexte()
  const kinder = raum.kinder.filter((k) => k.tablet !== null).sort((a, b) => (a.tablet ?? 0) - (b.tablet ?? 0))
  return (
    <Abschnitt titel={tx.t('checkout.titel')} zusatz={tx.t('checkout.hinweis')}>
      <div className="grid grid-cols-[repeat(auto-fill,minmax(330px,1fr))] gap-4">
        {kinder.map((k) => (
          <CheckoutKarte key={k.id} kind={k} />
        ))}
      </div>
    </Abschnitt>
  )
}
