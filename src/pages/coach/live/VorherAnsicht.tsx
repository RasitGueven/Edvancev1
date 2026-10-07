import { AlertTriangle, Award, Calendar, User } from 'lucide-react'
import { AvatarInitials } from '@/components/edvance/AvatarInitials'
import { EdvanceCard } from '@/components/edvance/EdvanceCard'
import { Button } from '@/components/ui/button'
import { sessionStarten } from '@/lib/session/coachLive'
import { cn } from '@/lib/utils'
import type { BlickPunkt, BriefingTag, CoachLiveKind } from '@/types/coachLive'
import { Abschnitt, Pille, type PillenTon } from './bausteine'
import { useLive } from './LiveKontext'
import { useLiveTexte, type LiveTexte } from './useLiveTexte'

const TAG_TON: Record<BriefingTag['art'], PillenTon> = {
  mastery: 'navy', signale: 'warn', themaAlt: 'warn', klassenarbeit: 'warn', ersteNachLsa: 'navy',
}

const BLICK_ICON: Record<BlickPunkt['art'], typeof Award> = { mastery: Award, klassenarbeit: Calendar, fehlbild: AlertTriangle, lsa: User }

function tagText(tag: BriefingTag, tx: LiveTexte): string {
  if (tag.art === 'signale') return tx.t('vorher.tag.signale', { count: tag.anzahl, datum: tx.datum(tag.am) })
  if (tag.art === 'themaAlt') return tx.t('vorher.tag.themaAlt', { count: tag.wochen })
  if (tag.art === 'klassenarbeit') return tx.t('vorher.tag.klassenarbeit', { datum: tx.tagDatum(tag.datum) })
  return tx.t(`vorher.tag.${tag.art}`)
}

function Briefing({ kind }: { kind: CoachLiveKind }): JSX.Element {
  const tx = useLiveTexte()
  const b = kind.briefing
  const kaTag = b.tags.find((x) => x.art === 'klassenarbeit')
  const themaDatum = b.thema.seit ? tx.datum(b.thema.seit) : kaTag?.art === 'klassenarbeit' ? tx.tagDatum(kaTag.datum) : ''
  const zeile = (feld: string, wert: JSX.Element | string): JSX.Element => (
    <div className="contents">
      <dt className="pt-px text-xs text-[var(--color-text-tertiary)]">{tx.t(`vorher.feld.${feld}`)}</dt>
      <dd className="min-w-0 text-sm text-[var(--color-text-primary)]">{wert}</dd>
    </div>
  )
  return (
    <li className="grid grid-cols-[40px_minmax(0,1fr)] gap-3 px-4 py-4">
      <AvatarInitials name={kind.name} color="var(--color-primary)" />
      <div className="flex min-w-0 flex-col gap-2">
        <div className="flex flex-wrap items-center gap-2">
          <b className="text-base font-semibold">{kind.name}</b>
          <span className="text-xs text-[var(--color-text-tertiary)]">{tx.t('raster.klasse', { klasse: kind.klasse })}</span>
          {b.tags.map((tag, i) => (
            <Pille key={i} ton={TAG_TON[tag.art]}>
              {tagText(tag, tx)}
            </Pille>
          ))}
        </div>
        <dl className="grid grid-cols-[96px_minmax(0,1fr)] gap-x-3 gap-y-1">
          {zeile('thema', tx.t(`vorher.thema.${b.thema.quelle}`, { label: b.thema.label, datum: themaDatum }))}
          {zeile('plan', tx.t(`vorher.plan.${b.plan.art ?? 'ohne'}`, { skill: b.plan.skill }))}
          {b.imBlick && zeile('imBlick', b.imBlick)}
          {zeile(
            'notiz',
            b.notiz ? (
              <>
                {tx.t('vorher.notiz', { text: b.notiz.text })}{' '}
                <span className="text-xs text-[var(--color-text-tertiary)]">{tx.t('vorher.notizVon', { von: b.notiz.von, datum: tx.datum(b.notiz.am) })}</span>
              </>
            ) : (
              <span className="text-[var(--color-text-tertiary)]">{tx.t('vorher.keineNotiz')}</span>
            ),
          )}
          {zeile('quests', b.quests ? tx.t('vorher.quests', b.quests) : tx.t('vorher.keineQuests'))}
        </dl>
      </div>
    </li>
  )
}

/** Vorher: Briefing je Kind und „Heute im Blick“, 30 Minuten vor Beginn. */
export function VorherAnsicht(): JSX.Element {
  const { raum, sessionId, ausfuehren, kind } = useLive()
  const tx = useLiveTexte()
  const ab = new Date(Date.parse(raum.session.beginn) - 5 * 60_000).toISOString()
  return (
    <div className="grid items-start gap-6 @min-[900px]:grid-cols-[minmax(0,1fr)_340px]">
      <Abschnitt titel={tx.t('vorher.werKommt')} zusatz={tx.t('vorher.gebucht', { count: raum.kinder.length, plaetze: raum.session.plaetze })}>
        <EdvanceCard className="p-0 hover:shadow-xs">
          <ul className="divide-y divide-[var(--color-bg-subtle)]">
            {raum.kinder.map((k) => (
              <Briefing key={k.id} kind={k} />
            ))}
          </ul>
        </EdvanceCard>
      </Abschnitt>
      <aside>
        <Abschnitt titel={tx.t('vorher.imBlick')}>
          <EdvanceCard className="flex flex-col gap-3 px-4 pb-4 pt-1.5 hover:shadow-xs">
            <ul>
              {raum.imBlick.map((p, i) => {
                const Icon = BLICK_ICON[p.art]
                const warn = p.art === 'klassenarbeit' || p.art === 'fehlbild'
                return (
                  <li key={i} className="grid grid-cols-[36px_minmax(0,1fr)] gap-2.5 border-b border-[var(--color-bg-subtle)] py-3">
                    <span
                      className={cn(
                        'inline-flex h-9 w-9 items-center justify-center rounded-[var(--radius-md)]',
                        warn ? 'bg-[var(--color-gold-warning-light)] text-[var(--color-gold-warning)]' : 'bg-[var(--color-primary-light)] text-[var(--color-primary)]',
                      )}
                    >
                      <Icon className="h-5 w-5" aria-hidden />
                    </span>
                    <span className="flex flex-col">
                      <b className="text-sm font-semibold leading-snug">
                        {tx.t(`vorher.blick.${p.art}`, { name: kind(p.kindId).vorname, datum: p.datum ? tx.tagDatum(p.datum) : '' })}
                      </b>
                      <span className="text-xs leading-snug text-[var(--color-text-secondary)]">{p.detail}</span>
                    </span>
                  </li>
                )
              })}
            </ul>
            <Button className="w-full" onClick={() => void ausfuehren(sessionStarten(sessionId))}>
              {tx.t('vorher.starten')}
            </Button>
            <span className="text-xs text-[var(--color-text-tertiary)]">{tx.t('vorher.startenAb', { zeit: tx.uhrzeit(ab) })}</span>
          </EdvanceCard>
        </Abschnitt>
      </aside>
    </div>
  )
}
