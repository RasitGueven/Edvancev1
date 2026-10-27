import { useEffect, useMemo, useState, type ComponentType } from 'react'
import { createPortal } from 'react-dom'
import { useTranslation } from 'react-i18next'

import { EmptyState } from '@/components/edvance/EmptyState'
import { LoadingPulse } from '@/components/edvance/LoadingPulse'
import { Bausteinsatz } from '@/lib/report/bausteine'
import { UEBERSPRUNGEN_ANZEIGE } from '@/lib/report/praesentation/einstellungen'
import { bauePraesentation } from '@/lib/report/praesentation/praesentation'
import type { PraesentationDaten, ReportData, ReportNotes, TierPlan, TpAnzeige } from '@/types'

import { Bestaetigung, type TpBestaetigung } from './Bestaetigung'
import { Intro } from './Intro'
import { Kopf } from './Kopf'
import { Leiste } from './Leiste'
import { Station1 } from './Station1'
import { Station1V4 } from './Station1V4'
import { Station2 } from './Station2'
import { Station3 } from './Station3'
import { Station4 } from './Station4'
import { StationFoerderansatz } from './StationFoerderansatz'
import { StationKlassenarbeiten } from './StationKlassenarbeiten'
import { STATIONEN, stationsName, type StationProps } from './stationProps'
import { useStationen } from './useStationen'
import { baueV4, type PraesentationV4 } from './v4Daten'

const STATION: Record<number, ComponentType<StationProps>> = {
  1: Station1,
  2: Station2,
  3: Station3,
  4: Station4,
}

/** Mit Fahrplan (V4): Überblick, Lernstand, Klassenarbeiten, Förderansatz. */
const STATION_V4: Record<number, ComponentType<StationProps>> = {
  1: Station1V4,
  2: Station2,
  3: StationKlassenarbeiten,
  4: StationFoerderansatz,
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
  /** Nur für Tests und Vorschau: false erzwingt die Zuordnung vor V4 (Station 03 = Lernweg). */
  fahrplan?: boolean
  /** L5 Teil D: nur Admin — Schalter „im Gespräch bestätigt“ in Station 04. */
  bestaetigung?: TpBestaetigung
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
  const { data, notes, tiers, tiersFehler, laden, onSchliessen, fahrplan = true } = props
  const { t } = useTranslation('praesentation')

  // Beim Schließen geht der Fokus dorthin zurück, wo er vor dem Öffnen war (Knopf im Report).
  // Gemerkt beim ersten Render: Die Effekte der Bühne setzen den Fokus schon vorher um.
  const [vorher] = useState(() => (document.activeElement instanceof HTMLElement ? document.activeElement : null))
  useEffect(() => () => vorher?.focus({ preventScroll: true }), [vorher])

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
  // Klassenarbeiten als roter Faden; ohne Fahrplan null und die Zuordnung vor V4.
  const v4 = useMemo(
    () => (fahrplan && data && p && !('fehlt' in p) ? baueV4(data, notes) : null),
    [fahrplan, data, notes, p],
  )

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
    inhalt = <Buehne {...props} p={p} satz={satz} v4={v4} />
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
  v4,
  notes,
  bestaetigung,
}: PraesentationProps & { p: PraesentationDaten; satz: Bausteinsatz; v4: PraesentationV4 | null }): JSX.Element {
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
        v4={v4 !== null}
      />
      <Leiste aktuell={s.aktuell} onSprung={s.springe} v4={v4 !== null} />
      <main ref={s.flussRef} className="tp-fluss" tabIndex={-1}>
        <Intro name={p.name} fach={p.fach} weg={s.introWeg} introRef={s.introRef} onLos={() => s.springe(1)} />
        {STATIONEN.map((n) => {
          const Station = (v4 ? STATION_V4 : STATION)[n]
          const klassen = ['tp-station']
          if (s.betreten[n - 1]) klassen.push('entered')
          if (s.fertig[n - 1]) klassen.push('motion-complete')
          return (
            <section
              key={n}
              ref={s.stationRef(n)}
              className={klassen.join(' ')}
              data-station={n}
              aria-label={stationsName(t, n, v4 !== null)}
            >
              <Station p={p} anzeige={anzeige} satz={satz} sessionId={sessionId} v4={v4} />
              {n === 4 && bestaetigung && <Bestaetigung notes={notes} bestaetigung={bestaetigung} />}
            </section>
          )
        })}
      </main>
    </div>
  )
}
