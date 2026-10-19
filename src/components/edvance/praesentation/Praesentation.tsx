import { useEffect, useMemo, type ComponentType } from 'react'
import { createPortal } from 'react-dom'
import { useTranslation } from 'react-i18next'

import { EmptyState } from '@/components/edvance/EmptyState'
import { LoadingPulse } from '@/components/edvance/LoadingPulse'
import { Bausteinsatz } from '@/lib/report/bausteine'
import { UEBERSPRUNGEN_ANZEIGE } from '@/lib/report/praesentation/einstellungen'
import { bauePraesentation } from '@/lib/report/praesentation/praesentation'
import type { PraesentationDaten, ReportData, ReportNotes, TierPlan, TpAnzeige } from '@/types'

import { Intro } from './Intro'
import { Kopf } from './Kopf'
import { Leiste } from './Leiste'
import { Station1 } from './Station1'
import { Station2 } from './Station2'
import { Station3 } from './Station3'
import { Station4 } from './Station4'
import { STATIONEN, type StationProps } from './stationProps'
import { useStationen } from './useStationen'

const STATION: Record<number, ComponentType<StationProps>> = {
  1: Station1,
  2: Station2,
  3: Station3,
  4: Station4,
}

export type PraesentationProps = {
  data: ReportData | null
  /** Der aktuelle Stand im Ausblick, auch ungespeichert. */
  notes: ReportNotes | null
  tiers: readonly TierPlan[]
  /** Die Pakete ließen sich nicht laden: dann entfällt nur die Empfehlungszeile. */
  tiersFehler: boolean
  sessionId: string
  /** Report, Notizen oder Pakete laden noch. */
  laden: boolean
  onSchliessen: () => void
  /** Nur für Tests: die Zählweise „übersprungen". */
  anzeige?: TpAnzeige
}

/**
 * Tablet-Präsentation der Lernstandsanalyse (T2, Entscheidungen 1–3).
 *
 * Eine Ebene über der ganzen App, per Portal direkt unter document.body: Der
 * Inhaltsbereich der AppShell ist ein @container, darin wäre position: fixed
 * an die Inhaltsspalte gebunden. Solange die Ebene offen ist, trägt <html> die
 * Klasse tp-offen (kein Scrollen dahinter). Escape schließt.
 */
export function Praesentation(props: PraesentationProps): JSX.Element {
  const { data, notes, tiers, tiersFehler, laden, onSchliessen } = props
  const { t } = useTranslation('praesentation')

  useEffect(() => {
    document.documentElement.classList.add('tp-offen')
    const taste = (e: KeyboardEvent): void => {
      if (e.key === 'Escape') onSchliessen()
    }
    document.addEventListener('keydown', taste)
    return () => {
      document.documentElement.classList.remove('tp-offen')
      document.removeEventListener('keydown', taste)
    }
  }, [onSchliessen])

  // Einmal rechnen. Fehlen die Pakete, rechnet die Präsentation ohne sie:
  // keine Empfehlung, aber alles andere.
  const p = useMemo(() => {
    if (!data || laden) return null
    if (tiersFehler) console.warn('praesentation: tiers failed to load — no recommendation')
    return bauePraesentation({ data, notes, tiers: tiersFehler ? [] : tiers })
  }, [data, notes, tiers, tiersFehler, laden])
  const satz = useMemo(() => new Bausteinsatz(data?.erzaehlung.bausteine ?? []), [data])

  const name = p && !('fehlt' in p) ? p.name : null

  let inhalt: JSX.Element
  if (!p) {
    inhalt = (
      <div className="tp-mitte" data-testid="tp-laden">
        <LoadingPulse type="card" lines={5} />
      </div>
    )
  } else if ('fehlt' in p) {
    inhalt = (
      <div className="tp-mitte" data-testid="tp-leer">
        <EmptyState
          icon="📊"
          title={t('ariaOhneName')}
          description={t(p.fehlt === 'katalog' ? 'keinKatalog' : 'leer')}
          action={
            <button type="button" className="tp-knopf" onClick={onSchliessen}>
              {t('kopf.schliessen')}
            </button>
          }
        />
      </div>
    )
  } else {
    inhalt = <Buehne {...props} p={p} satz={satz} />
  }

  return createPortal(
    <div
      className="tp"
      role="dialog"
      aria-modal="true"
      aria-label={name ? t('aria', { name }) : t('ariaOhneName')}
    >
      {inhalt}
    </div>,
    document.body,
  )
}

/** Intro, Kopf, Leiste und die vier einrastenden Stationen. */
function Buehne({
  p,
  satz,
  sessionId,
  onSchliessen,
  anzeige = UEBERSPRUNGEN_ANZEIGE,
}: PraesentationProps & { p: PraesentationDaten; satz: Bausteinsatz }): JSX.Element {
  const { t } = useTranslation('praesentation')
  const s = useStationen()
  const amIntro = s.aktuell === 0 && !s.introWeg

  // Der Fluss bekommt den Fokus, damit Tastatur und Escape sofort wirken.
  useEffect(() => {
    s.flussRef.current?.focus({ preventScroll: true })
  }, [s.flussRef])

  return (
    <div className={amIntro ? 'tp-buehne tp-am-intro' : 'tp-buehne'}>
      <Kopf
        aktuell={s.aktuell}
        testlauf={p.testlauf}
        laeuftNoch={p.laeuftNoch}
        onLogo={() => s.springe(1)}
        onSchliessen={onSchliessen}
      />
      <Leiste aktuell={s.aktuell} onSprung={s.springe} />
      <main ref={s.flussRef} className="tp-fluss" tabIndex={-1}>
        <Intro name={p.name} fach={p.fach} weg={s.introWeg} introRef={s.introRef} onLos={() => s.springe(1)} />
        {STATIONEN.map((n) => {
          const Station = STATION[n]
          const klassen = ['tp-station']
          if (s.betreten[n - 1]) klassen.push('entered')
          if (s.fertig[n - 1]) klassen.push('motion-complete')
          return (
            <section
              key={n}
              ref={s.stationRef(n)}
              className={klassen.join(' ')}
              data-station={n}
              aria-label={t(`leiste.station.${n}`)}
            >
              <Station p={p} anzeige={anzeige} satz={satz} sessionId={sessionId} />
            </section>
          )
        })}
      </main>
    </div>
  )
}
