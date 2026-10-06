import { useState } from 'react'
import { Check, CheckCircle2, Clock } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { masteryEntscheiden } from '@/lib/session/coachLive'
import { vertagenAbsendbar } from '@/lib/session/coachLiveLogik'
import { cn } from '@/lib/utils'
import type { CoachLiveKind, LiveMasteryKandidat, MasteryBeleg } from '@/types/coachLive'
import { Block, Chip, Feldname, Pille } from './bausteine'
import { useLive } from './LiveKontext'
import { useLiveTexte } from './useLiveTexte'

const GRUENDE = ['wegNichtErklaert', 'nurMitHilfe', 'rechenfehler', 'nichtPruefbar'] as const

/**
 * Mastery-Pruefung in vier Schritten (Entscheidung 16): Prueffrage stellen, das Kind
 * erklaert, der Coach entscheidet, der Coach bucht. Gruen erst nach der Buchung.
 */
export function MasteryPruefung({ kind, m }: { kind: CoachLiveKind; m: LiveMasteryKandidat }): JSX.Element {
  const { sessionId, ausfuehren } = useLive()
  const tx = useLiveTexte()
  const [frage, setFrage] = useState(false)
  const [erklaert, setErklaert] = useState(false)
  const [vertagenOffen, setVertagenOffen] = useState(false)
  const [grund, setGrund] = useState<string | null>(null)

  const beleg = (b: MasteryBeleg): string =>
    b.art === 'session'
      ? tx.t('mastery.beleg.session', { datum: tx.datum(b.datum), richtig: b.richtig, von: b.von })
      : b.art === 'warmupHeute'
        ? tx.t('mastery.beleg.warmupHeute', { richtig: b.richtig, von: b.von })
        : tx.t('mastery.beleg.abstand', { count: b.tage })

  const e = m.entscheidung
  if (e?.art === 'gemeistert') {
    return (
      <Block titel={tx.t('mastery.titel')} ton="kandidat">
        <div className="flex items-center gap-3 text-[var(--color-success)]">
          <CheckCircle2 className="h-5 w-5" aria-hidden />
          <span className="flex flex-col">
            <b className="text-base font-semibold">{tx.t('mastery.gemeistert', { skill: m.label })}</b>
            <span className="text-xs text-[var(--color-text-tertiary)]">{tx.t('mastery.bestaetigtVon', { von: e.von, zeit: tx.uhrzeit(e.zeit) })}</span>
          </span>
        </div>
        <p className="text-xs text-[var(--color-text-tertiary)]">{tx.t('mastery.siehtAbzeichen', { name: kind.vorname })}</p>
      </Block>
    )
  }
  if (e?.art === 'vertagt') {
    return (
      <Block titel={tx.t('mastery.titel')}>
        <div className="flex items-center gap-3 text-[var(--color-text-primary)]">
          <Clock className="h-5 w-5" aria-hidden />
          <span className="flex flex-col">
            <b className="text-base font-semibold">{tx.t('mastery.vertagt', { skill: m.label })}</b>
            <span className="text-xs text-[var(--color-text-tertiary)]">{tx.t('mastery.vertagtGrund', { grund: e.grund ?? '', zeit: tx.uhrzeit(e.zeit) })}</span>
          </span>
        </div>
        <p className="text-xs text-[var(--color-text-tertiary)]">{tx.t('mastery.wiederVorgeschlagen')}</p>
      </Block>
    )
  }

  const buchen = (entscheidung: 'gemeistert' | 'vertagt'): void => {
    void ausfuehren(
      masteryEntscheiden({ sessionId, studentId: kind.id, skillKey: m.skillKey, entscheidung, grund: entscheidung === 'vertagt' ? grund : null }),
      entscheidung === 'gemeistert' ? tx.t('toast.gemeistert', { skill: m.label }) : tx.t('toast.vertagt'),
    )
  }
  const bereit = frage && erklaert
  const schritt = (an: boolean, setzen: (v: boolean) => void, text: string): JSX.Element => (
    <button type="button" aria-pressed={an} onClick={() => setzen(!an)} className="flex min-h-[44px] items-center gap-2.5 text-left text-sm text-[var(--color-text-primary)]">
      <span
        className={cn(
          'inline-flex h-[22px] w-[22px] flex-none items-center justify-center rounded-[var(--radius-sm)] border-[1.5px]',
          an ? 'border-[var(--color-primary)] bg-[var(--color-primary)] text-[var(--color-text-inverse)]' : 'border-[var(--color-neutral-unknown)]',
        )}
      >
        {an && <Check className="h-4 w-4" aria-hidden />}
      </span>
      {text}
    </button>
  )

  return (
    <Block titel={tx.t('mastery.titel')} ton="kandidat" rechts={<Pille ton="navy">{tx.t('mastery.vorschlag')}</Pille>}>
      <div>
        <b className="block font-serif text-xl font-medium leading-tight text-[var(--color-text-primary)]">{m.label}</b>
        <span className="text-xs text-[var(--color-text-tertiary)]">{tx.t('mastery.unterzeile', { thema: m.themaLabel, klasse: m.klasse })}</span>
      </div>
      <ul className="flex list-disc flex-col gap-0.5 pl-5 text-sm text-[var(--color-text-secondary)]">
        {m.belege.map((b, i) => (
          <li key={i}>{beleg(b)}</li>
        ))}
      </ul>
      <div className="rounded-r-[var(--radius-md)] border-l-[3px] border-[var(--color-primary)] bg-[var(--color-bg-app)] px-4 py-2.5">
        <Feldname>{tx.t('mastery.frage')}</Feldname>
        <p className="mt-1 text-base leading-relaxed text-[var(--color-text-primary)]">{m.frage}</p>
      </div>
      <dl className="grid grid-cols-[96px_minmax(0,1fr)] gap-x-3 gap-y-1 text-sm">
        <dt className="text-xs text-[var(--color-text-tertiary)]">{tx.t('mastery.erwartung')}</dt>
        <dd className="text-[var(--color-text-primary)]">{m.erwartung}</dd>
        <dt className="text-xs text-[var(--color-text-tertiary)]">{tx.t('mastery.kriterium')}</dt>
        <dd className="text-[var(--color-text-primary)]">{m.kriterium}</dd>
      </dl>
      <div className="flex flex-col">
        {schritt(frage, setFrage, tx.t('mastery.schrittFrage'))}
        {schritt(erklaert, setErklaert, tx.t('mastery.schrittErklaert', { name: kind.vorname }))}
      </div>
      <div className="flex flex-wrap items-center gap-2">
        <Button
          size="md"
          disabled={!bereit}
          title={bereit ? undefined : tx.t('mastery.bestaetigenGesperrt')}
          onClick={() => buchen('gemeistert')}
          className="bg-[var(--color-success)]"
        >
          <CheckCircle2 className="h-4 w-4" aria-hidden />
          {tx.t('mastery.bestaetigen')}
        </Button>
        <Button size="md" variant="outline" onClick={() => setVertagenOffen(true)}>
          {tx.t('mastery.vertagen')}
        </Button>
      </div>
      {!bereit && <p className="text-xs text-[var(--color-text-tertiary)]">{tx.t('mastery.bestaetigenGesperrt')}</p>}
      {vertagenOffen && (
        <div className="flex flex-col gap-2">
          <Feldname>{tx.t('mastery.grundLabel')}</Feldname>
          <div className="flex flex-wrap gap-1.5">
            {GRUENDE.map((g) => {
              const text = tx.t(`mastery.gruende.${g}`)
              return (
                <Chip key={g} aktiv={grund === text} onClick={() => setGrund(text)}>
                  {text}
                </Chip>
              )
            })}
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <Button
              size="md"
              disabled={!vertagenAbsendbar(grund)}
              title={vertagenAbsendbar(grund) ? undefined : tx.t('mastery.vertagenGesperrt')}
              onClick={() => buchen('vertagt')}
            >
              {tx.t('mastery.vertagen')}
            </Button>
            <Button size="md" variant="ghost" onClick={() => { setVertagenOffen(false); setGrund(null) }}>
              {tx.t('mastery.abbrechen')}
            </Button>
          </div>
        </div>
      )}
    </Block>
  )
}
