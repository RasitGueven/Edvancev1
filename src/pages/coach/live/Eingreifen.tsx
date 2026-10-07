import { Check, Route } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { eingriffNotieren, pfadEntscheiden, signalErledigen } from '@/lib/session/coachLive'
import { eingriffAbsendbar } from '@/lib/session/coachLiveLogik'
import { cn } from '@/lib/utils'
import type { CoachLiveKind, PfadVorschlag } from '@/types/coachLive'
import type { EingriffStufe } from '@/types/sessionLive'
import { Block, Feldname, Pille } from './bausteine'
import { useLive } from './LiveKontext'
import { useLiveTexte } from './useLiveTexte'

const STUFEN: EingriffStufe[] = [1, 2, 3, 4]

/** Interventionsleiter 1 bis 4 (Entscheidung 14); ab Stufe 3 nur mit Fehlbild. */
export function Interventionsleiter({ kind }: { kind: CoachLiveKind }): JSX.Element {
  const { sessionId, raum, ausfuehren } = useLive()
  const tx = useLiveTexte()
  const { empfohlen, fehlbild, eingriffe } = kind.eingreifen
  const slug = fehlbild?.slug ?? null
  const haengt = kind.signale.some((s) => s.art === 'haengt')

  const notieren = (stufe: EingriffStufe): void => {
    const text =
      stufe === 4 ? tx.t('toast.stufe4', { name: kind.vorname }) : stufe === 3 ? tx.t('toast.stufeAkte', { stufe }) : tx.t('toast.stufe', { stufe })
    void ausfuehren(eingriffNotieren(sessionId, kind.id, stufe, stufe >= 3 ? slug : null), text)
  }

  return (
    <Block titel={tx.t('leiter.titel')} rechts={empfohlen === 0 && <Pille>{tx.t('leiter.stufe0')}</Pille>}>
      <div className="flex flex-col gap-1.5">
        {STUFEN.map((n) => {
          const geht = eingriffAbsendbar(n, slug)
          const passt = n === empfohlen
          return (
            <button
              key={n}
              type="button"
              disabled={!geht}
              title={geht ? undefined : tx.t('leiter.ohneFehlbild')}
              onClick={() => notieren(n)}
              className={cn(
                'grid min-h-[56px] w-full grid-cols-[30px_minmax(0,1fr)_auto] items-center gap-2.5 rounded-[var(--radius-md)] border bg-[var(--color-bg-surface)] px-2.5 py-2 text-left hover:bg-[var(--color-bg-subtle)]/50 disabled:cursor-not-allowed disabled:opacity-40',
                passt ? 'border-[var(--color-primary)] ring-2 ring-[var(--color-primary-light)]' : 'border-[var(--color-border)]',
              )}
            >
              <span
                className={cn(
                  'inline-flex h-[30px] w-[30px] items-center justify-center rounded-full text-sm font-bold',
                  passt ? 'bg-[var(--color-primary)] text-[var(--color-text-inverse)]' : 'bg-[var(--color-bg-subtle)] text-[var(--color-text-secondary)]',
                )}
              >
                {n}
              </span>
              <span className="min-w-0">
                <b className="block text-sm font-semibold leading-snug text-[var(--color-text-primary)]">{tx.t(`leiter.titel${n}`)}</b>
                <span className="block text-xs leading-snug text-[var(--color-text-secondary)]">
                  {tx.t(`leiter.text${n}`, { count: Number(raum.einstellungen.mikro_erklaerung_min ?? 2) })}
                </span>
              </span>
              {passt && <Pille ton="navy">{tx.t('leiter.passt')}</Pille>}
            </button>
          )
        })}
      </div>
      {fehlbild ? (
        <p className="text-sm">
          <Feldname>{tx.t('leiter.fehlbild')}</Feldname>
          <span className="text-[var(--color-text-primary)]">{tx.t('leiter.fehlbildVorbelegt', { fehlbild: fehlbild.klartext })}</span>
        </p>
      ) : (
        <p className="text-xs text-[var(--color-text-tertiary)]">{tx.t('leiter.ohneFehlbild')}</p>
      )}
      {eingriffe.length > 0 && (
        <div className="flex flex-col gap-0.5 text-xs text-[var(--color-text-secondary)]">
          <Feldname>{tx.t('leiter.notiert')}</Feldname>
          {eingriffe.map((e, i) => (
            <span key={i}>{tx.t('leiter.eintrag', { stufe: e.stufe, zeit: tx.uhrzeit(e.zeit) })}</span>
          ))}
        </div>
      )}
      {haengt && (
        <div>
          <Button size="md" variant="outline" onClick={() => void ausfuehren(signalErledigen(sessionId, kind.id, 'haengt'), tx.t('toast.signalErledigt'))}>
            <Check className="h-4 w-4" aria-hidden />
            {tx.t('leiter.signalErledigt')}
          </Button>
        </div>
      )}
    </Block>
  )
}

/** Vorschlag „eine Stufe tiefer“ aus dem Warm-up: das System schlaegt vor, der Coach entscheidet. */
export function PfadEntscheidung({ kind, p }: { kind: CoachLiveKind; p: PfadVorschlag }): JSX.Element {
  const { sessionId, ausfuehren } = useLive()
  const tx = useLiveTexte()
  const e = p.entscheidung
  if (e) {
    return (
      <Block titel={tx.t('pfad.titelErledigt')}>
        <div className="flex items-center gap-3">
          <Route className="h-5 w-5 text-[var(--color-primary)]" aria-hidden />
          <span className="flex flex-col">
            <b className="text-sm font-semibold text-[var(--color-text-primary)]">
              {e.art === 'tiefer'
                ? tx.t('pfad.entschiedenTiefer', { skill: p.skillTiefer, klasse: p.klasseTiefer })
                : tx.t('pfad.entschiedenPlan', { skill: p.skillPlan })}
            </b>
            <span className="text-xs text-[var(--color-text-tertiary)]">{tx.t('pfad.entschiedenVon', { von: e.von, zeit: tx.uhrzeit(e.zeit) })}</span>
          </span>
        </div>
        <div>
          <Button size="md" variant="ghost" onClick={() => void ausfuehren(pfadEntscheiden(sessionId, kind.id, null))}>
            {tx.t('pfad.aendern')}
          </Button>
        </div>
      </Block>
    )
  }
  const entscheiden = (art: 'tiefer' | 'plan'): void =>
    void ausfuehren(
      pfadEntscheiden(sessionId, kind.id, art),
      art === 'tiefer' ? tx.t('toast.pfadTiefer', { name: kind.vorname }) : tx.t('toast.pfadPlan', { name: kind.vorname }),
    )
  return (
    <Block titel={tx.t('pfad.titel')} ton="entscheidung" rechts={<Pille ton="warn">{tx.t('mastery.vorschlag')}</Pille>}>
      <p className="text-sm text-[var(--color-text-primary)]">
        <b className="font-semibold">{tx.t('pfad.frage')}</b>{' '}
        {tx.t('pfad.erklaerung', { plan: p.skillPlan, tiefer: p.skillTiefer, klasse: p.klasseTiefer })}
      </p>
      <ul className="flex list-disc flex-col gap-0.5 pl-5 text-sm text-[var(--color-text-secondary)]">
        <li>{tx.t('pfad.belegWarmup', { skill: p.skillTiefer, richtig: p.warmupRichtig, von: p.warmupVon })}</li>
        {p.fehlbildAm && <li>{tx.t('pfad.belegFehlbild', { datum: tx.datum(p.fehlbildAm), fehlbild: p.fehlbild })}</li>}
        <li>{tx.t('pfad.belegThema', { thema: p.themaLabel })}</li>
      </ul>
      <div className="flex flex-wrap gap-2">
        <Button size="md" onClick={() => entscheiden('tiefer')}>
          {tx.t('pfad.tiefer')}
        </Button>
        <Button size="md" variant="outline" onClick={() => entscheiden('plan')}>
          {tx.t('pfad.plan')}
        </Button>
      </div>
    </Block>
  )
}
