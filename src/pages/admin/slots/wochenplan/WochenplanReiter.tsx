import { useTranslation } from 'react-i18next'
import { EdvanceCard, EmptyState, LoadingPulse, WochenNavigation } from '@/components/edvance'
import { KennzahlenLeiste, type Kennzahl } from '@/components/edvance/admin/KennzahlenLeiste'
import type { SlotsWoche } from '@/types/slotplan'
import type { StundenplanWoche } from '@/types/stundenplan'
import type { Geladen } from '../useSlotsLaden'
import { prozent } from '../slotsFormat'
import { FARBE } from './RaumZeile'
import { WochenRaster } from './WochenRaster'
import { wochenKennzahlen, type Panel, type RaumFarbe } from './wochenplan.model'

/** Wochenraster als Skelett, solange die Woche lädt. */
function RasterSkelett(): JSX.Element {
  return (
    <div className="grid grid-cols-[4rem_repeat(5,minmax(0,1fr))] gap-2" aria-hidden="true">
      {Array.from({ length: 6 * 5 }, (_, i) => (
        <div key={i} className={`h-20 rounded-[var(--radius-md)] ${i % 6 === 0 ? '' : 'bg-[var(--color-border)] animate-skeleton'}`} />
      ))}
    </div>
  )
}

const LEGENDE: RaumFarbe[] = ['rot', 'gelb', 'gruen', 'leer', 'keinCoach']
const SWATCH: Record<RaumFarbe, string> = {
  rot: `w-3 ${FARBE.rot.punkt}`,
  gelb: `w-3 ${FARBE.gelb.punkt}`,
  gruen: `w-3 ${FARBE.gruen.punkt}`,
  leer: `w-3 ${FARBE.leer.leer}`,
  keinCoach: 'w-6 bg-[var(--color-error-coach)]',
}

function Legende(): JSX.Element {
  const { t } = useTranslation('slots')
  return (
    <ul className="flex flex-wrap items-center gap-4 text-xs text-[var(--color-text-tertiary)]">
      <li>{t('wochenplan2.legende.titel')}</li>
      {LEGENDE.map((f) => (
        <li key={f} className="flex items-center gap-2">
          <span aria-hidden="true" className={`inline-block h-3 rounded-sm ${SWATCH[f]}`} />
          {t(`wochenplan2.legende.${f}`)}
        </li>
      ))}
    </ul>
  )
}

/**
 * Reiter Wochenplan (Bauauftrag W2): Woche mit A/B-Kennzeichen, fünf Kennzahlen mit sichtbaren Testkonten,
 * Raster mit Räumen je Zelle und Zeile „Einzel“. Zellen, Tage und Einzel-Sessions öffnen ihr Panel.
 */
export function WochenplanReiter({
  woche,
  einzel,
  montag,
  onWoche,
  onPanel,
}: {
  woche: Geladen<SlotsWoche>
  einzel: Geladen<StundenplanWoche>
  montag: string
  onWoche: (montag: string) => void
  onPanel: (panel: Panel) => void
}): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const w = woche.daten && woche.daten.montag === montag ? woche.daten : null
  const e = einzel.daten && einzel.daten.montag === montag ? einzel.daten.sessions : null
  const k = w ? wochenKennzahlen(w.kopf) : null
  const pz = (a: number | null): string => (a === null ? '–' : prozent(a, i18n.language))

  const zahlen: Kennzahl[] = k
    ? [
        { key: 'plaetze', label: t('wochenplan2.kpi.plaetze'), wert: String(k.plaetze), unterzeile: t('wochenplan2.kpi.plaetzeSub') },
        {
          key: 'belegt',
          label: t('wochenplan2.kpi.belegt'),
          wert: String(k.belegt),
          unterzeile: t('wochenplan2.kpi.belegtSub', { kinder: k.echt, count: k.test }),
        },
        {
          key: 'auslastung',
          label: t('wochenplan2.kpi.auslastung'),
          wert: pz(k.auslastung),
          unterzeile: t('wochenplan2.kpi.auslastungSub', { prozent: pz(k.auslastungOhneTest) }),
        },
        {
          key: 'ohneCoach',
          label: t('wochenplan2.kpi.ohneCoach'),
          wert: String(k.raeumeOhneCoach),
          ton: k.raeumeOhneCoach > 0 ? 'handeln' : 'neutral',
          unterzeile: t(k.raeumeOhneCoach > 0 ? 'wochenplan2.kpi.ohneCoachHandeln' : 'wochenplan2.kpi.ohneCoachKeiner'),
        },
        {
          key: 'ohneStammplatz',
          label: t('wochenplan2.kpi.ohneStammplatz'),
          wert: String(k.ohneStammplatz),
          ton: k.ohneStammplatzHandeln ? 'handeln' : 'neutral',
          unterzeile: t('wochenplan2.kpi.ohneStammplatzSub', { count: k.ohneStammplatzTest }),
          ziel: k.ohneStammplatz + k.ohneStammplatzTest > 0 ? '/admin/slots?reiter=kinder&filter=kein_stammplatz' : undefined,
        },
      ]
    : []

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center gap-4">
        <WochenNavigation montag={montag} onWechsel={onWoche} />
        {w && (
          <span className="text-xs text-[var(--color-text-tertiary)]">
            {t(w.a_woche ? 'wochenplan2.aWoche' : 'wochenplan2.bWoche')}
          </span>
        )}
      </div>

      <div className="@container">
        {w ? <KennzahlenLeiste zahlen={zahlen} label={t('woche.kpi.label')} breite="slots-kpi" /> : <LoadingPulse type="stat" />}
      </div>

      <EdvanceCard className="flex min-w-0 flex-col gap-4 p-4">
        {woche.fehler && !w ? (
          <p role="alert" className="text-sm text-[var(--color-text-secondary)]">{t(woche.fehler)}</p>
        ) : !w ? (
          <RasterSkelett />
        ) : w.zeiten.length === 0 ? (
          <EmptyState icon="🕓" title={t('woche.leerTitel')} description={t('woche.leerText')} />
        ) : (
          <WochenRaster woche={w} einzel={e} onPanel={onPanel} />
        )}
        {einzel.fehler && <p role="alert" className="text-xs text-[var(--color-text-secondary)]">{t(einzel.fehler)}</p>}
        <footer className="border-t border-[var(--color-border)] pt-2">
          <Legende />
        </footer>
      </EdvanceCard>
    </div>
  )
}
