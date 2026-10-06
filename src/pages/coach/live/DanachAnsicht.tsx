import { AlertTriangle, Award, CheckCircle2, Flag, PencilLine, Route, Tablet, type LucideIcon } from 'lucide-react'
import { EdvanceCard } from '@/components/edvance/EdvanceCard'
import { Button } from '@/components/ui/button'
import { beispielZeitpunktSetzen, nichtErschienenBestaetigen, sessionAbschliessen } from '@/lib/session/coachLive'
import { abschlussMoeglich, akteZahlen, kinderOhneTablet } from '@/lib/session/coachLiveLogik'
import { cn } from '@/lib/utils'
import { Abschnitt, Pille } from './bausteine'
import { useLive } from './LiveKontext'
import { useLiveTexte } from './useLiveTexte'

type Punkt = { icon: LucideIcon; warn: boolean; titel: string; text: string; aktion?: JSX.Element }

function Zeile({ p }: { p: Punkt }): JSX.Element {
  const Icon = p.icon
  return (
    <li className="grid grid-cols-[36px_minmax(0,1fr)_auto] items-center gap-3 px-4 py-3">
      <span
        className={cn(
          'inline-flex h-9 w-9 items-center justify-center rounded-[var(--radius-md)]',
          p.warn ? 'bg-[var(--color-gold-warning-light)] text-[var(--color-gold-warning)]' : 'bg-[var(--color-primary-light)] text-[var(--color-primary)]',
        )}
      >
        <Icon className="h-5 w-5" aria-hidden />
      </span>
      <span className="flex min-w-0 flex-col">
        <b className="text-sm font-semibold leading-snug">{p.titel}</b>
        <span className="text-xs text-[var(--color-text-secondary)]">{p.text}</span>
      </span>
      {p.aktion ?? <span />}
    </li>
  )
}

/** Danach: offene Punkte, Kinder ohne Tablet bestaetigen, „Geht in die Akten“ und Abschluss. */
export function DanachAnsicht(): JSX.Element {
  const { raum, sessionId, ausfuehren } = useLive()
  const tx = useLiveTexte()
  const kinder = raum.kinder
  const ohneTablet = kinderOhneTablet(kinder)
  const anwesend = kinder.filter((k) => k.tablet !== null)
  const z = akteZahlen(kinder)
  const kannAbschliessen = abschlussMoeglich(kinder)
  const fertig = raum.session.abgeschlossen

  const punkte: Punkt[] = []
  const ohneNotiz = anwesend.filter((k) => k.checkout.notiz.trim() === '').map((k) => k.vorname)
  if (ohneNotiz.length > 0) {
    punkte.push({
      icon: PencilLine, warn: true,
      titel: tx.t('danach.notizFehlt', { namen: ohneNotiz.join(', ') }),
      text: tx.t('danach.notizFehltHilfe'),
      aktion: raum.beispiel ? (
        <Button size="md" variant="outline" onClick={() => void ausfuehren(beispielZeitpunktSetzen(sessionId, 'checkout'))}>
          {tx.t('danach.nachtragen')}
        </Button>
      ) : undefined,
    })
  }
  for (const k of kinder) {
    const m = k.masteryKandidat
    if (m) {
      const e = m.entscheidung
      punkte.push(
        !e
          ? { icon: Award, warn: false, titel: tx.t('danach.masteryOffen', { name: k.vorname }), text: tx.t('danach.masteryOffenHilfe', { skill: m.label }) }
          : e.art === 'vertagt'
            ? { icon: Award, warn: false, titel: tx.t('danach.vertagt', { name: k.vorname, skill: m.label }), text: e.grund ?? '' }
            : { icon: CheckCircle2, warn: false, titel: tx.t('danach.gemeistert', { name: k.vorname, skill: m.label }), text: tx.t('danach.bestaetigtUm', { zeit: tx.uhrzeit(e.zeit) }) },
      )
    }
    if (k.pfadEntscheidung?.art === 'tiefer') {
      punkte.push({ icon: Route, warn: false, titel: tx.t('danach.pfadGeaendert', { name: k.vorname }), text: tx.t('danach.pfadGeaendertHilfe') })
    }
    if (k.checkout.flags.eltern) punkte.push({ icon: Flag, warn: true, titel: tx.t('danach.flagEltern', { name: k.vorname }), text: tx.t('danach.flagElternHilfe') })
    if (k.checkout.flags.pfad) punkte.push({ icon: Flag, warn: true, titel: tx.t('danach.flagPfad', { name: k.vorname }), text: tx.t('danach.flagPfadHilfe') })
  }

  const von = (anzahl: number, gesamt: number): string => tx.t('danach.vonGesamt', { anzahl, gesamt })
  const akte: [string, string][] = [
    ['anwesend', von(z.anwesend, z.gesamt)],
    ['einheit', String(z.einheitVerbraucht)],
    ['aufgaben', String(z.aufgaben)],
    ['eingriffe', String(z.eingriffeAb3)],
    ['mastery', tx.t('danach.paar', { a: z.masteryBestaetigt, b: z.masteryVertagt })],
    ['sequenzen', String(raum.erklaersequenzenFertig)],
    ['satz', von(z.satzGesagt, z.anwesend)],
    ['notizen', von(z.notizen, z.anwesend)],
    ['quests', von(z.questTermine, z.anwesend)],
  ]

  return (
    <div className="grid items-start gap-6 @min-[900px]:grid-cols-[minmax(0,1fr)_360px]">
      <div className="flex min-w-0 flex-col gap-6">
        <Abschnitt titel={tx.t('danach.ohneTablet')} zusatz={ohneTablet.length > 0 ? tx.t('danach.ohneTabletHilfe') : undefined}>
          <EdvanceCard className="p-0 hover:shadow-xs" >
            {ohneTablet.length === 0 ? (
              <p className="flex items-center gap-2 px-4 py-4 text-sm font-medium text-[var(--color-success)]">
                <CheckCircle2 className="h-5 w-5" aria-hidden />
                {tx.t('danach.alleMitTablet')}
              </p>
            ) : (
              <ul className="divide-y divide-[var(--color-bg-subtle)]" data-testid="ohne-tablet">
                {ohneTablet.map((k) => (
                  <Zeile
                    key={k.id}
                    p={{
                      icon: Tablet, warn: !k.nichtErschienen, titel: k.name, text: tx.t('raster.klasse', { klasse: k.klasse }),
                      aktion: k.nichtErschienen ? (
                        <Pille>{tx.t('danach.bestaetigt')}</Pille>
                      ) : (
                        <Button size="md" variant="outline" disabled={!!fertig} onClick={() => void ausfuehren(nichtErschienenBestaetigen(sessionId, k.id))}>
                          {tx.t('danach.bestaetigen')}
                        </Button>
                      ),
                    }}
                  />
                ))}
              </ul>
            )}
          </EdvanceCard>
        </Abschnitt>
        <Abschnitt titel={tx.t('danach.vorAbschluss')} zusatz={tx.t('danach.punkte', { count: punkte.length })}>
          <EdvanceCard className="p-0 hover:shadow-xs">
            <ul className="divide-y divide-[var(--color-bg-subtle)]">
              {punkte.map((p, i) => (
                <Zeile key={i} p={p} />
              ))}
            </ul>
          </EdvanceCard>
        </Abschnitt>
      </div>
      <aside>
        <Abschnitt titel={tx.t('danach.akte')}>
          <EdvanceCard className="flex flex-col gap-3 px-4 pb-4 pt-1.5 hover:shadow-xs">
            <dl className="grid grid-cols-[minmax(0,1fr)_auto] text-sm">
              {akte.map(([key, wert]) => (
                <div key={key} className="contents">
                  <dt className="border-b border-[var(--color-bg-subtle)] py-2 text-[var(--color-text-secondary)]">{tx.t(`danach.zeile.${key}`)}</dt>
                  <dd className="border-b border-[var(--color-bg-subtle)] py-2 text-right font-semibold tabular-nums">{wert}</dd>
                </div>
              ))}
            </dl>
            {fertig ? (
              <p className="flex items-center gap-2 py-2 text-sm font-semibold text-[var(--color-success)]">
                <CheckCircle2 className="h-5 w-5" aria-hidden />
                {tx.t('danach.abgeschlossen', { zeit: tx.uhrzeit(fertig) })}
              </p>
            ) : (
              <>
                <Button
                  className="w-full"
                  disabled={!kannAbschliessen}
                  title={kannAbschliessen ? undefined : tx.t('danach.abschliessenGesperrt')}
                  onClick={() => void ausfuehren(sessionAbschliessen(sessionId), tx.t('toast.abgeschlossen'))}
                >
                  {tx.t('danach.abschliessen')}
                </Button>
                {!kannAbschliessen && (
                  <span className="flex items-center gap-1.5 text-xs text-[var(--color-gold-warning)]">
                    <AlertTriangle className="h-4 w-4" aria-hidden />
                    {tx.t('danach.abschliessenGesperrt')}
                  </span>
                )}
              </>
            )}
          </EdvanceCard>
        </Abschnitt>
      </aside>
    </div>
  )
}
