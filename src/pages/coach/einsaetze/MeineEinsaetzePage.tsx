import { useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EmptyState, LoadingPulse } from '@/components/edvance'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { WochenNavigation } from '@/components/edvance/WochenNavigation'
import { dieseWoche, montagVon } from '@/components/edvance/wochenNavigation.model'
import { ladeMeineEinsaetze } from '@/lib/supabase/slotplan'
import { datumLang } from '@/pages/admin/slots/slotsFormat'
import { useSlotsLaden } from '@/pages/admin/slots/useSlotsLaden'
import { EinsatzKarte } from './EinsatzKarte'
import { kinderZahl, nachTagen } from './einsaetze.model'
import { useSessionOeffnen } from './useSessionOeffnen'

/**
 * Coach „Meine Einsätze“ (/coach/einsaetze, Anforderung I 53): die eigenen Raum-Termine einer Woche,
 * nach Tagen gruppiert, mit den Kindern im Raum. Woche in der URL (?woche=), Zurück funktioniert.
 * Keine Absagen, kein Vertrag, keine Planbilanz (I 54) — meine_einsaetze liefert sie gar nicht.
 */
export function MeineEinsaetzePage(): JSX.Element {
  const { t, i18n } = useTranslation('coach')
  const { t: tSlots } = useTranslation('slots')
  const [suche, setSuche] = useSearchParams()
  const montag = montagVon(suche.get('woche') ?? dieseWoche())
  const geladen = useSlotsLaden(() => ladeMeineEinsaetze(montag), montag)
  const { oeffnen, laeuft, fehler: oeffnenFehler } = useSessionOeffnen()

  const daten = geladen.daten?.montag === montag ? geladen.daten : null
  const tage = daten ? nachTagen(daten.einsaetze) : []

  const setWoche = (m: string): void => {
    const neu = new URLSearchParams(suche)
    if (m === dieseWoche()) neu.delete('woche')
    else neu.set('woche', m)
    setSuche(neu)
  }

  const satz = daten
    ? [
        t('einsaetze.kw', { kw: daten.kw }),
        t('einsaetze.anzahl', { count: daten.einsaetze.length }),
        t('einsaetze.kinder', { count: kinderZahl(daten.einsaetze) }),
      ].join(' · ')
    : undefined
  const fehler = oeffnenFehler ?? geladen.fehler

  return (
    <>
      <PageHeader rubrik={t('einsaetze.rubrik')} titel={t('einsaetze.titel')} satz={satz} />
      <WochenNavigation montag={montag} onWechsel={setWoche} />

      {fehler && (
        <p role="alert" className="text-sm text-[var(--color-error-coach)]">
          {tSlots(fehler)}
        </p>
      )}

      {!daten && geladen.laedt ? (
        <LoadingPulse type="list" lines={4} />
      ) : tage.length === 0 ? (
        !geladen.fehler && <EmptyState icon="🗓️" title={t('einsaetze.leerTitel')} description={t('einsaetze.leerText')} />
      ) : (
        <div className="flex flex-col gap-6">
          {tage.map((tag) => (
            <section key={tag.datum} aria-labelledby={`tag-${tag.datum}`} className="flex flex-col gap-4">
              <h2
                id={`tag-${tag.datum}`}
                className="sticky top-0 z-10 flex min-h-[44px] items-center gap-2 bg-[var(--color-bg-app)] text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]"
              >
                {datumLang(tag.datum, i18n.language)}
                {tag.heute && (
                  <span className="rounded-[var(--radius-full)] bg-[var(--color-primary-light)] px-2 text-[var(--color-primary)]">
                    {t('einsaetze.heute')}
                  </span>
                )}
              </h2>
              <div className="grid grid-cols-1 gap-4 @heute-listen:grid-cols-2">
                {tag.einsaetze.map((e) => (
                  <EinsatzKarte key={e.key} e={e} oeffnet={laeuft === e.key} onOeffnen={(x) => void oeffnen(x)} />
                ))}
              </div>
            </section>
          ))}
        </div>
      )}
    </>
  )
}
