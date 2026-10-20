import { useEffect } from 'react'
import { useLocation, useNavigate, useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Reiterleiste, type Reiter } from '@/components/edvance'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { dieseWoche, montagVon } from '@/components/edvance/wochenNavigation.model'
import { ladeCoaches, ladeWoche } from '@/lib/supabase/slotplan'
import { ladeStundenplanWoche } from '@/lib/supabase/stundenplan'
import { reiterAusSuche, sucheMitReiter, type SlotsReiter } from './slots.model'
import { useSlotsLaden } from './useSlotsLaden'
import { WochenplanReiter } from './wochenplan/WochenplanReiter'
import { einzelAmTag, panelAusSuche, sucheMitPanel, sucheOhneStundenplan, type Panel } from './wochenplan/wochenplan.model'
import { KinderReiter } from './kinder/KinderReiter'
import { CoachesReiter } from './coaches/CoachesReiter'
import { EinstellungenReiter } from './einstellungen/EinstellungenReiter'
import { SofortKnopf } from './sofort/SofortKnopf'
import { SlotPanel } from './panel/SlotPanel'
import { TagPanel } from './panel/TagPanel'
import { EinzelPanel } from './panel/EinzelPanel'

/**
 * Menüpunkt Slots (Bauauftrag Slots SL2, W2): Seitenkopf mit „Session jetzt starten“, Reiter Wochenplan · Kinder ·
 * Coaches · Einstellungen (Reiter und Woche in der URL) und darüber das Panel aus der URL (?slot=, ?tag=, ?einzel=).
 * Ein im Wochenplan geöffnetes Panel ist ein eigener Schritt in der Geschichte: Zurück schließt es.
 */
export function SlotsPage(): JSX.Element {
  const { t } = useTranslation('slots')
  const [suche, setSuche] = useSearchParams()
  const navigate = useNavigate()
  const location = useLocation()
  const reiter = reiterAusSuche(suche)
  const panel = panelAusSuche(suche)
  // Ohne ?woche zeigt der Wochenplan die Woche des Panels (alte Termin-Adresse, geteilte Links).
  const montag = montagVon(suche.get('woche') ?? panel?.datum ?? dieseWoche())
  const imAppGeoeffnet = (location.state as { panel?: boolean } | null)?.panel === true

  // W2, Entscheidung 1: Den Reiter Stundenplan gibt es nicht mehr; die alte Adresse landet im Wochenplan.
  useEffect(() => {
    if (suche.get('reiter') === 'stundenplan') setSuche(sucheOhneStundenplan(suche), { replace: true, state: location.state })
  }, [suche, setSuche, location.state])

  const woche = useSlotsLaden(() => ladeWoche(montag), montag)
  const einzel = useSlotsLaden(() => ladeStundenplanWoche(montag), `einzel:${montag}`)
  const coaches = useSlotsLaden(() => ladeCoaches(montag), montag)
  const kopf = woche.daten?.montag === montag ? woche.daten.kopf : null
  const abweichungen = coaches.daten?.coaches.reduce((n, c) => n + c.abweichungen.length, 0)
  const ausfall = coaches.daten?.coaches.some((c) => c.abweichungen.some((a) => a.art === 'faellt_aus')) ?? false

  const setWoche = (m: string): void => {
    const neu = new URLSearchParams(suche)
    if (m === dieseWoche()) neu.delete('woche')
    else neu.set('woche', m)
    setSuche(neu)
  }

  /** Erstes Panel: neuer Schritt in der Geschichte. Wechsel zwischen Panels (Tag → Slot): ersetzt den Schritt. */
  const oeffnePanel = (p: Panel): void => {
    if (panel) setSuche(sucheMitPanel(suche, p), { replace: true, state: location.state })
    else setSuche(sucheMitPanel(suche, p), { state: { panel: true } })
  }
  const schliessePanel = (): void => {
    if (imAppGeoeffnet) return navigate(-1)
    const neu = sucheMitPanel(suche, null)
    if (!neu.get('woche') && montag !== dieseWoche()) neu.set('woche', montag)
    setSuche(neu, { replace: true })
  }
  const geaendert = (): void => {
    woche.neuLaden()
    einzel.neuLaden()
  }

  const reiterListe: Reiter<SlotsReiter>[] = [
    { key: 'wochenplan', titel: t('reiter.wochenplan') },
    {
      key: 'kinder',
      titel: t('reiter.kinder'),
      anzahl: kopf?.ohne_stammplatz,
      ton: kopf && kopf.ohne_stammplatz_laufend > 0 ? 'handeln' : 'neutral',
    },
    { key: 'coaches', titel: t('reiter.coaches'), anzahl: abweichungen, ton: ausfall ? 'handeln' : 'neutral' },
    { key: 'einstellungen', titel: t('reiter.einstellungen') },
  ]

  const satz = kopf
    ? [
        t('seite.kw', { kw: woche.daten?.kw }),
        t('seite.belegt', { belegt: kopf.belegt, plaetze: kopf.plaetze }),
        t('seite.ohneStammplatz', { count: kopf.ohne_stammplatz }),
      ].join(' · ')
    : undefined

  return (
    <>
      <PageHeader rubrik={t('seite.rubrik')} titel={t('seite.titel')} satz={satz} aktionen={<SofortKnopf />} />
      <Reiterleiste
        reiter={reiterListe}
        aktiv={reiter}
        label={t('seite.reiterLabel')}
        onWechsel={(r) => setSuche(sucheMitReiter(suche, r))}
      />
      {reiter === 'wochenplan' && (
        <WochenplanReiter woche={woche} einzel={einzel} montag={montag} onWoche={setWoche} onPanel={oeffnePanel} />
      )}
      {reiter === 'kinder' && <KinderReiter />}
      {reiter === 'coaches' && <CoachesReiter coaches={coaches} montag={montag} onWoche={setWoche} />}
      {reiter === 'einstellungen' && <EinstellungenReiter />}

      {panel?.art === 'slot' && (
        <SlotPanel
          datum={panel.datum}
          zeitId={panel.zeitId}
          einzel={einzel.daten?.montag === montagVon(panel.datum) ? einzelAmTag(einzel.daten.sessions, panel.datum) : []}
          onPanel={oeffnePanel}
          onClose={schliessePanel}
          onGeaendert={geaendert}
        />
      )}
      {panel?.art === 'tag' && (
        <TagPanel
          datum={panel.datum}
          woche={woche.daten}
          onPanel={oeffnePanel}
          onClose={schliessePanel}
          onGeaendert={geaendert}
        />
      )}
      {panel?.art === 'einzel' && (
        <EinzelPanel datum={panel.datum} sessionId={panel.sessionId} onClose={schliessePanel} onGeaendert={geaendert} />
      )}
    </>
  )
}
