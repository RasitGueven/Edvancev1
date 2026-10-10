import { useState } from 'react'
import { Check, Flag } from 'lucide-react'
import { checkinCoachSetzen } from '@/lib/session/coachLive'
import { geltenderFall, tageBis } from '@/lib/session/coachLiveLogik'
import { cn } from '@/lib/utils'
import type { CoachLiveKind } from '@/types/coachLive'
import type { SessionFall } from '@/types/sessionLive'
import type { Thema } from '@/types/themen'
import { Feldname, Pille, Platz } from './bausteine'
import { useLive } from './LiveKontext'
import { ThemaWahl } from './ThemaWahl'
import { useLiveTexte } from './useLiveTexte'

const FAELLE: SessionFall[] = ['klassenarbeit', 'schulthema', 'lernpfad']

const STIMMUNG_PUNKT = { gut: 'bg-[var(--color-success-answer)]', geht_so: 'bg-[var(--color-neutral-unknown)]', angespannt: 'bg-[var(--color-gold-warning)]' }

/**
 * Eine Zeile „Check-in am Tablet“: Antworten des Kindes live, Fall-Vorschlag (goldener
 * Punkt) getrennt von der Wahl des Coaches, Themensuche wie im Erstgespraech (kein Freitext).
 * F1: „Thema waehlen“ bzw. „Aendern“ immer, auch ohne Schulthema; ist das Kind schon weiter, steht seine Phase dabei.
 */
export function CheckinZeile({ kind, katalog }: { kind: CoachLiveKind; katalog: Thema[] }): JSX.Element {
  const { sessionId, raum, ausfuehren } = useLive()
  const tx = useLiveTexte()
  const c = kind.checkin
  const fertig = c.fertig
  const neuOffen = c.themaAntwort === 'neu' && kind.ziel.themaKey === null
  const [suche, setSuche] = useState(false)
  const offen = suche || neuOffen
  const fall = geltenderFall(kind.ziel)
  const geaendert = kind.ziel.fallCoach !== null && kind.ziel.fallCoach !== kind.ziel.fallVorschlag
  const bisher = katalog.find((t) => t.thema_key === c.themaBisher)?.label ?? ''

  const antwort = !fertig || c.themaAntwort === null
    ? tx.t('checkin.antwort.leer')
    : tx.t(`checkin.antwort.${c.themaAntwort}`, { stichwort: c.stichwort ?? '' })

  const ka = c.klassenarbeit
  const kaText = !fertig
    ? tx.t('checkin.antwort.leer')
    : ka === null
      ? tx.t('checkin.kaNein')
      : tx.t('checkin.kaWert', { datum: ka.datum ? tx.tagDatum(ka.datum) : tx.t('checkin.kaOhneDatum'), thema: ka.themaLabel ?? '' })

  return (
    <div className="grid grid-cols-3 items-start gap-x-4 gap-y-2.5 px-4 py-4 @min-[1000px]:grid-cols-[180px_120px_minmax(0,1fr)_minmax(0,1.4fr)]">
      <div className="col-span-3 flex items-center gap-2 font-semibold @min-[1000px]:col-span-1">
        <Platz nr={kind.tablet} />
        {kind.name}
      </div>
      <div className="min-w-0 text-sm">
        <Feldname>{tx.t('checkin.stimmung')}</Feldname>
        {fertig && c.stimmung ? (
          <>
            <span className="inline-flex items-center gap-1.5">
              <i className={cn('h-2.5 w-2.5 rounded-full', STIMMUNG_PUNKT[c.stimmung])} aria-hidden />
              {tx.t(`checkin.stimmungWert.${c.stimmung}`)}
            </span>
            {c.stimmung === 'angespannt' && <div className="text-xs text-[var(--color-gold-warning)]">{tx.t('checkin.ansprechen')}</div>}
          </>
        ) : (
          tx.t('checkin.antwort.leer')
        )}
      </div>
      <div className="min-w-0 text-sm">
        <Feldname>{tx.t('checkin.klassenarbeit')}</Feldname>
        {kaText}
        {fertig && ka?.datum && (
          <div className="text-xs text-[var(--color-text-tertiary)]">{tx.t('checkin.kaTage', { count: tageBis(ka.datum, raum.session.jetzt) })}</div>
        )}
      </div>
      <div className="min-w-0 text-sm">
        <Feldname>{tx.t('checkin.schulthemaSagt', { name: kind.vorname, antwort })}</Feldname>
        <div className="flex flex-wrap items-center gap-2">
          {kind.ziel.themaLabel ? (
            <b className="font-semibold">{kind.ziel.themaLabel}</b>
          ) : neuOffen ? (
            <span className="text-[var(--color-gold-warning)]">{tx.t('checkin.neuWaehlen', { thema: bisher })}</span>
          ) : (
            tx.t('checkin.antwort.leer')
          )}
          {!offen && (
            <button type="button" onClick={() => setSuche(true)} className="min-h-[44px] text-sm font-semibold text-[var(--color-primary)] hover:underline">
              {kind.ziel.themaLabel ? tx.t('checkin.aendern') : tx.t('checkin.themaWaehlen')}
            </button>
          )}
        </div>
        {tx.phaseZeile(kind) && <div className="text-xs text-[var(--color-text-tertiary)]">{tx.phaseZeile(kind)}</div>}
      </div>
      {offen && (
        <div className="col-span-full">
          <ThemaWahl
            kind={kind}
            katalog={katalog}
            startEingabe={c.themaAntwort === 'neu' ? (c.stichwort ?? '') : ''}
            onFertig={() => setSuche(false)}
          />
        </div>
      )}
      <div className="col-span-full flex flex-col gap-2 @min-[1000px]:col-start-2">
        <Feldname>{geaendert ? tx.t('checkin.fallGeaendert') : tx.t('checkin.fall')}</Feldname>
        <div className="flex flex-wrap items-center gap-2">
          <div role="group" aria-label={tx.t('checkin.fallFuer', { name: kind.vorname })} className="inline-flex flex-wrap overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-neutral-unknown)]">
            {FAELLE.map((f) => (
              <button
                key={f}
                type="button"
                aria-pressed={fall === f}
                title={kind.ziel.fallVorschlag === f ? tx.t('fall.vorschlag') : undefined}
                onClick={() => void ausfuehren(checkinCoachSetzen(sessionId, kind.id, f))}
                className={cn(
                  'inline-flex min-h-[44px] items-center gap-1.5 border-l border-[var(--color-neutral-unknown)] px-3 text-sm first:border-l-0',
                  fall === f ? 'bg-[var(--color-primary)] font-semibold text-[var(--color-text-inverse)]' : 'bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)]',
                )}
              >
                {tx.t(`fall.${f}`)}
                {kind.ziel.fallVorschlag === f && (
                  <span className="h-1.5 w-1.5 rounded-full bg-[var(--color-gold-altgold)]" aria-label={tx.t('fall.vorschlag')} />
                )}
              </button>
            ))}
          </div>
          {fertig ? (
            <Pille ton="ok" icon={<Check className="h-3.5 w-3.5" aria-hidden />}>
              {tx.t('checkin.fertig')}
            </Pille>
          ) : (
            <Pille>{tx.t('checkin.fuelltAus')}</Pille>
          )}
        </div>
        <div className="flex items-center gap-2 text-sm text-[var(--color-text-secondary)]">
          <Flag className="h-4 w-4" aria-hidden />
          <span>
            {tx.t('ziel.satz')} <b className="font-semibold text-[var(--color-text-primary)]">{tx.ziel(kind)}</b>
          </span>
        </div>
      </div>
    </div>
  )
}
