// Inhalts-Bloecke der Schublade: Ziel der Stunde, Erklaersequenz, aktuelle Aufgabe
// mit Musterloesung (nur hier), falsche Antworten mit Fehlbild (nur hier), Hinweise,
// Heute, Info. Alles nur fuer den Coach (Entscheidung 17).

import { Check, Lock } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { geltenderFall } from '@/lib/session/coachLiveLogik'
import { signalErledigen } from '@/lib/session/coachLive'
import { cn } from '@/lib/utils'
import type { CoachLiveKind, LiveAufgabeDetail, LiveErklaersequenz, ZielZeile } from '@/types/coachLive'
import { Block, Feldname, Pille } from './bausteine'
import { useLive } from './LiveKontext'
import { useLiveTexte } from './useLiveTexte'

const ZIEL_PUNKT: Record<ZielZeile['stand'], string> = {
  sicher: 'bg-[var(--color-primary)]',
  aktiv: 'bg-primary/20 ring-[1.5px] ring-inset ring-[var(--color-primary)]',
  kandidat: 'bg-[var(--color-primary)] ring-[3px] ring-[var(--color-primary-light)]',
  noch_nicht_sicher: 'bg-[var(--color-gold-warning)]',
  offen: 'ring-[1.5px] ring-inset ring-[var(--color-neutral-unknown)]',
  gemeistert: 'bg-[var(--color-success)]',
}

export function ZielBlock({ kind }: { kind: CoachLiveKind }): JSX.Element {
  const tx = useLiveTexte()
  const fall = geltenderFall(kind.ziel)
  return (
    <Block titel={tx.t('ziel.titel')} rechts={fall && <Pille>{tx.t(`fall.${fall}`)}</Pille>}>
      <p className="text-sm font-semibold text-[var(--color-text-primary)]">{tx.ziel(kind)}</p>
      <ul className="flex flex-col gap-2">
        {kind.zielFertigkeiten.map((z) => (
          <li key={z.skillKey} className="grid grid-cols-[14px_minmax(0,1fr)] items-start gap-2.5">
            <i className={cn('mt-1 h-3 w-3 rounded-full', ZIEL_PUNKT[z.stand])} aria-hidden />
            <span className="flex flex-col leading-snug">
              <b className="text-sm font-semibold text-[var(--color-text-primary)]">{z.label}</b>
              <span className="text-xs text-[var(--color-text-secondary)]">
                {[tx.t(`stand.${z.stand}`), ...z.notizen.map(tx.zielNotiz)].join(' · ')}
              </span>
            </span>
          </li>
        ))}
      </ul>
    </Block>
  )
}

export function SequenzBlock({ kind, seq }: { kind: CoachLiveKind; seq: LiveErklaersequenz }): JSX.Element {
  const { raum } = useLive()
  const tx = useLiveTexte()
  const notiz = (k: LiveErklaersequenz['kernideen'][number]): string => {
    if (k.stand === 'sicher') return tx.t('sequenz.sicher', { runde: k.runde })
    if (k.stand === 'offen') return tx.t('sequenz.offen')
    return k.fehlbild && k.variante
      ? tx.t('sequenz.laeuft', { vorher: k.runde - 1, fehlbild: k.fehlbild, variante: k.variante, runde: k.runde })
      : tx.t('sequenz.laeuftOhne', { runde: k.runde })
  }
  return (
    <Block titel={tx.t('sequenz.titel')} rechts={<Pille>{tx.t('sequenz.kernidee', { aktuell: seq.aktuell, von: seq.kernideen.length })}</Pille>}>
      <ol className="flex flex-col gap-2">
        {seq.kernideen.map((k, i) => (
          <li key={i} className="grid grid-cols-[28px_minmax(0,1fr)] items-start gap-2.5">
            <span
              className={cn(
                'inline-flex h-7 w-7 items-center justify-center rounded-full text-xs font-bold',
                k.stand === 'sicher' && 'bg-[var(--color-primary)] text-[var(--color-text-inverse)]',
                k.stand === 'laeuft' && 'bg-[var(--color-primary-light)] text-[var(--color-primary)] ring-[1.5px] ring-inset ring-[var(--color-primary)]',
                k.stand === 'offen' && 'bg-[var(--color-bg-subtle)] text-[var(--color-text-tertiary)]',
              )}
            >
              {k.stand === 'sicher' ? <Check className="h-4 w-4" aria-hidden /> : i + 1}
            </span>
            <span className="flex flex-col leading-snug">
              <b className="text-sm font-semibold text-[var(--color-text-primary)]">{k.text}</b>
              <span className="text-xs text-[var(--color-text-secondary)]">{notiz(k)}</span>
            </span>
          </li>
        ))}
      </ol>
      <div className="rounded-[var(--radius-md)] border border-[var(--color-bg-subtle)] bg-[var(--color-bg-app)] px-4 py-2.5">
        <Feldname>{tx.t('sequenz.sieht', { name: kind.vorname, variante: seq.variante })}</Feldname>
        <p className="mt-1 text-sm text-[var(--color-text-primary)]">{seq.siehtGerade}</p>
      </div>
      <p className="text-xs text-[var(--color-text-tertiary)]">
        {tx.t('sequenz.signal', { count: Number(raum.einstellungen.erklaerrunden_bis_signal ?? 2) })}
      </p>
    </Block>
  )
}

export function AufgabeBlock({ aufgabe }: { aufgabe: LiveAufgabeDetail }): JSX.Element {
  const tx = useLiveTexte()
  const k = aufgabe.kopf
  const titel =
    k.art === 'check'
      ? tx.t('schublade.aufgabeKopf.check', { kernidee: k.kernidee, runde: k.runde })
      : tx.t(`schublade.aufgabeKopf.${k.art}`, { ...k, skill: aufgabe.skill })
  const e = aufgabe.letzteEingabe
  const letzte = e
    ? tx.t('schublade.eingabe', {
        eingabe: e.eingabe,
        ergebnis: e.nachHinweis ? tx.t('schublade.nachHinweis', { stufe: e.nachHinweis }) : tx.t(`schublade.ergebnis.${e.ergebnis}`),
      })
    : aufgabe.ohneEingabeMin
      ? tx.t('schublade.ohneEingabe', { count: aufgabe.ohneEingabeMin })
      : tx.t('schublade.keineEingabe')
  return (
    <Block titel={titel}>
      <div className="rounded-[var(--radius-md)] border border-[var(--color-bg-subtle)] bg-[var(--color-bg-app)] px-4 py-3 text-base leading-relaxed text-[var(--color-text-primary)]">
        {aufgabe.text}
      </div>
      <div className="flex flex-col gap-1 rounded-[var(--radius-md)] bg-[var(--color-primary-light)] px-4 py-2.5" data-testid="musterloesung">
        <span className="flex items-center gap-1.5 text-xs font-semibold text-[var(--color-primary)]">
          <Lock className="h-4 w-4" aria-hidden />
          {tx.t('schublade.musterloesung')}
        </span>
        <ol className="list-decimal pl-5 text-sm text-[var(--color-text-primary)]">
          {aufgabe.musterloesung.map((z, i) => (
            <li key={i}>{z}</li>
          ))}
        </ol>
      </div>
      <p className="flex flex-wrap items-baseline gap-2 text-sm">
        <Feldname>{tx.t('schublade.letzteEingabe')}</Feldname>
        <span className="text-[var(--color-text-primary)]">{letzte}</span>
      </p>
    </Block>
  )
}

export function VersucheBlock({ kind }: { kind: CoachLiveKind }): JSX.Element {
  const tx = useLiveTexte()
  return (
    <Block titel={tx.t('schublade.falscheAntworten')}>
      <ul className="flex flex-col gap-2" data-testid="fehlbilder">
        {kind.versuche.map((v, i) => (
          <li key={i} className="grid grid-cols-[auto_minmax(0,1fr)] items-baseline gap-x-2.5 gap-y-0.5 text-sm">
            <Pille ton="bad">{tx.t(`schublade.versuchKopf.${v.kopf.art}`, { nr: v.kopf.nr })}</Pille>
            <code className="font-sans text-sm font-semibold text-[var(--color-error-gap)]">{v.eingabe}</code>
            <span className="col-start-2 text-xs text-[var(--color-text-secondary)]">{tx.t('schublade.fehlbild', { fehlbild: v.fehlbild })}</span>
          </li>
        ))}
      </ul>
    </Block>
  )
}

export function HinweiseBlock({ kind }: { kind: CoachLiveKind }): JSX.Element {
  const tx = useLiveTexte()
  return (
    <Block titel={tx.t('schublade.hinweise')}>
      <ul className="flex list-disc flex-col gap-0.5 pl-5 text-sm text-[var(--color-text-secondary)]">
        {kind.hinweise.map((h) => (
          <li key={h.stufe}>{tx.t('schublade.hinweisStufe', h)}</li>
        ))}
      </ul>
    </Block>
  )
}

export function HeuteBlock({ kind }: { kind: CoachLiveKind }): JSX.Element {
  const { raum } = useLive()
  const tx = useLiveTexte()
  return (
    <Block titel={tx.t('schublade.heute')}>
      <dl className="grid grid-cols-[96px_minmax(0,1fr)] gap-x-3 gap-y-1 text-sm">
        {kind.heute.map((h, i) => {
          const zusatz = tx.heuteZusatz(h, raum.einstellungen)
          return (
            <div key={i} className="contents">
              <dt className="text-xs text-[var(--color-text-tertiary)]">{tx.t(`schublade.heuteAbschnitt.${h.abschnitt}`)}</dt>
              <dd className="min-w-0 text-[var(--color-text-primary)]">
                {[tx.heuteText(h, raum.session.beginn), zusatz].filter(Boolean).join(' · ')}
              </dd>
            </div>
          )
        })}
      </dl>
    </Block>
  )
}

export function InfoBlock({ kind }: { kind: CoachLiveKind }): JSX.Element | null {
  const { sessionId, ausfuehren } = useLive()
  const tx = useLiveTexte()
  if (!kind.info) return null
  const i = kind.info.inhalt
  const text =
    i.art === 'spaet'
      ? tx.t('schublade.info.spaet', { zeit: tx.uhrzeit(i.ankunft) })
      : i.art === 'klassenarbeit'
        ? tx.t('schublade.info.klassenarbeit', { datum: tx.tagDatum(i.datum), count: i.tage })
        : tx.t('schublade.info.stimmung')
  return (
    <Block ton="info">
      <p className="text-sm text-[var(--color-text-primary)]">{text}</p>
      {kind.info.quittierbar && (
        <div>
          <Button size="md" onClick={() => void ausfuehren(signalErledigen(sessionId, kind.id, 'hinweis'), tx.t('toast.angesprochen'))}>
            {tx.t('schublade.info.angesprochen')}
          </Button>
        </div>
      )}
    </Block>
  )
}
