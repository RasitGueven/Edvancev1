import { useEffect, useState } from 'react'
import { CheckCircle2, Tablet } from 'lucide-react'
import { AvatarInitials } from '@/components/edvance/AvatarInitials'
import { EdvanceCard } from '@/components/edvance/EdvanceCard'
import { EmptyState } from '@/components/edvance/EmptyState'
import { Button } from '@/components/ui/button'
import { tabletLoesen, tabletZuweisen, themenKatalog } from '@/lib/session/coachLive'
import { cn } from '@/lib/utils'
import type { Thema } from '@/types/themen'
import { Abschnitt } from './bausteine'
import { CheckinZeile } from './CheckinZeile'
import { useLive } from './LiveKontext'
import { useLiveTexte } from './useLiveTexte'

/** Check-in: Tablets zuweisen (= Ankunft), Antworten der Kinder live, Fall und Thema waehlen. */
export function CheckinAnsicht(): JSX.Element {
  const { raum, sessionId, ausfuehren } = useLive()
  const tx = useLiveTexte()
  const [katalog, setKatalog] = useState<Thema[]>([])
  // „Ist da“ ohne Tablet: nur auf diesem Geraet; erst das Tablet setzt die Anwesenheit (R1).
  const [angekommen, setAngekommen] = useState<string[]>([])

  useEffect(() => {
    void themenKatalog().then((res) => res.data && setKatalog(res.data))
  }, [])

  const plaetze = Array.from({ length: raum.session.plaetze }, (_, i) => i + 1)
  const sitzt = (nr: number) => raum.kinder.find((k) => k.tablet === nr)
  const frei = plaetze.filter((nr) => !sitzt(nr))
  const wartend = raum.kinder.filter((k) => k.tablet === null)
  const imRaum = raum.kinder.filter((k) => k.tablet !== null).sort((a, b) => (a.tablet ?? 0) - (b.tablet ?? 0))

  return (
    <>
      <Abschnitt
        titel={tx.t('checkin.plaetze', { raum: raum.session.raum })}
        zusatz={tx.t('checkin.belegt', { count: imRaum.length, plaetze: raum.session.plaetze })}
      >
        <div className="grid grid-cols-5 gap-2.5">
          {plaetze.map((nr) => {
            const k = sitzt(nr)
            return (
              <div
                key={nr}
                className={cn(
                  'flex min-h-[112px] flex-col items-center justify-center gap-0.5 rounded-[var(--radius-lg)] border-[1.5px] bg-[var(--color-bg-surface)] p-2 text-center',
                  k ? 'border-solid border-primary/25 shadow-xs' : 'border-dashed border-[var(--color-neutral-unknown)]',
                )}
              >
                <span className="inline-flex items-center gap-1 text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                  <Tablet className="h-4 w-4" aria-hidden />
                  {tx.t('checkin.tablet', { nr })}
                </span>
                {k ? (
                  <>
                    <b className="text-base font-semibold">{k.vorname}</b>
                    <span className="text-xs text-[var(--color-text-tertiary)]">{tx.t('raster.klasse', { klasse: k.klasse })}</span>
                    <button
                      type="button"
                      onClick={() => void ausfuehren(tabletLoesen(sessionId, k.id))}
                      className="min-h-[44px] text-xs font-semibold text-[var(--color-primary)] hover:underline"
                    >
                      {tx.t('checkin.loesen')}
                    </button>
                  </>
                ) : (
                  <span className="text-sm text-[var(--color-text-tertiary)]">{tx.t('checkin.frei')}</span>
                )}
              </div>
            )
          })}
        </div>
      </Abschnitt>

      {wartend.length > 0 ? (
        <Abschnitt titel={tx.t('checkin.ankommen')} zusatz={tx.t('checkin.ankommenHilfe')}>
          <div className="grid grid-cols-[repeat(auto-fill,minmax(320px,1fr))] gap-2.5">
            {wartend.map((k) => {
              const da = angekommen.includes(k.id)
              return (
                <EdvanceCard key={k.id} className="flex flex-wrap items-center gap-3 px-4 py-3 hover:shadow-xs">
                  <AvatarInitials name={k.name} color="var(--color-primary)" />
                  <span className="flex min-w-[140px] flex-1 flex-col leading-snug">
                    <b className="font-semibold">{k.name}</b>
                    <span className="text-xs text-[var(--color-text-tertiary)]">{da ? tx.t('checkin.istDaOhnePlatz') : tx.t('checkin.erwartet')}</span>
                  </span>
                  <span className="flex flex-wrap gap-1.5">
                    {da ? (
                      frei.map((nr) => (
                        <Button
                          key={nr}
                          size="md"
                          onClick={() => void ausfuehren(tabletZuweisen(sessionId, k.id, nr), tx.t('toast.tablet', { name: k.vorname, nr }))}
                        >
                          {tx.t('checkin.platz', { nr })}
                        </Button>
                      ))
                    ) : (
                      <Button size="md" variant="outline" onClick={() => setAngekommen((a) => [...a, k.id])}>
                        {tx.t('checkin.istDa')}
                      </Button>
                    )}
                  </span>
                </EdvanceCard>
              )
            })}
          </div>
        </Abschnitt>
      ) : (
        <EdvanceCard className="flex items-center gap-2 px-4 py-4 text-sm font-medium text-[var(--color-success)] hover:shadow-xs">
          <CheckCircle2 className="h-5 w-5" aria-hidden />
          {tx.t('checkin.alleDa')}
        </EdvanceCard>
      )}

      <Abschnitt titel={tx.t('checkin.amTablet')} zusatz={tx.t('checkin.amTabletHilfe')}>
        <EdvanceCard className="p-0 hover:shadow-xs">
          {imRaum.length === 0 ? (
            <EmptyState icon="🪑" title={tx.t('checkin.niemand')} description={tx.t('checkin.ankommenHilfe')} />
          ) : (
            <div className="divide-y divide-[var(--color-bg-subtle)]">
              {imRaum.map((k) => (
                <CheckinZeile key={k.id} kind={k} katalog={katalog} />
              ))}
            </div>
          )}
        </EdvanceCard>
      </Abschnitt>
    </>
  )
}
