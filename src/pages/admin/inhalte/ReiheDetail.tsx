// IU-1 U2: Detail einer Session-Reihe: je Session eine Karte (Bauformen, Erklärvideo, nächster Schritt).
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'

import { EdvanceBadge, EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { BAUFORMEN_PRUEFEN, STUDIO } from '@/lib/inhalte/uebersicht'
import { getSessionReihe } from '@/lib/supabase/inhalte'
import type { InhalteReihe, InhalteSession, SessionSchritt } from '@/types/inhalte'

import { FARBE, Stapel, useZeitfenster, type Farbe } from './Bausteine'

const SCHRITT_ZIEL: Record<SessionSchritt, string | null> = {
  lena_prueft: BAUFORMEN_PRUEFEN, rueckfrage: BAUFORMEN_PRUEFEN, entwurf: null, admin_gibt_frei: BAUFORMEN_PRUEFEN,
  video: STUDIO, fertig: null,
}
const VIDEO_FARBE: Record<string, Farbe> = { freigegeben: 'gut', in_pruefung: 'achtung', fehlt: 'offen', keins: 'offen' }

function SessionKarte({ s }: { s: InhalteSession }): JSX.Element {
  const { t } = useTranslation('admin')
  const bereit = s.naechster_schritt === 'admin_gibt_frei' || s.naechster_schritt === 'fertig'
  const stand = bereit ? 'bereit' : s.geprueft > 0 ? 'arbeit' : 'offen'
  const video = s.video_status ?? 'keins'
  const ziel = SCHRITT_ZIEL[s.naechster_schritt]
  const schritt = t(`inhalte.session.schritt.${s.naechster_schritt}`, { count: s.zu_pruefen })
  const offen = Math.max(s.bauformen - s.geprueft - s.rueckfrage, 0)
  return (
    <EdvanceCard className="flex flex-col gap-2">
      <span><EdvanceBadge variant={stand === 'bereit' ? 'success' : stand === 'arbeit' ? 'warning' : 'muted'}>
        {s.nr === null ? t('inhalte.session.ohneNr') : t('inhalte.session.tag', { nr: s.nr, stand: t(`inhalte.session.stand.${stand}`) })}
      </EdvanceBadge></span>
      {s.titel && <h3 className="text-sm font-semibold text-[var(--color-text-primary)]">{s.titel}</h3>}
      <Stapel label={t('inhalte.reihen.bfZahl', { frei: s.freigegeben, zur: s.zur_freigabe, rueck: s.rueckfrage, offen })}
        teile={[{ wert: s.freigegeben, farbe: 'gut' }, { wert: s.zur_freigabe, farbe: 'primaer' },
          { wert: s.rueckfrage, farbe: 'achtung' }, { wert: offen, farbe: 'offen' }]} />
      <dl className="flex flex-col text-sm">
        <div className="flex justify-between gap-2 border-t border-[var(--color-border)] py-2">
          <dt className="text-[var(--color-text-secondary)]">{t('inhalte.session.bauformen')}</dt>
          <dd className="tabular-nums">{t('inhalte.session.bauformenWert', { g: s.geprueft, n: s.bauformen })}
            {s.rueckfrage > 0 && t('inhalte.session.rueckfrage', { count: s.rueckfrage })}</dd>
        </div>
        <div className="flex justify-between gap-2 border-t border-[var(--color-border)] py-2">
          <dt className="text-[var(--color-text-secondary)]">{t('inhalte.session.video')}</dt>
          <dd className="inline-flex items-center gap-2">
            <span aria-hidden="true" className={`inline-block h-2.5 w-2.5 rounded-[var(--radius-full)] ${FARBE[VIDEO_FARBE[video]]}`} />
            {t(`inhalte.session.videoStatus.${video}`)}
          </dd>
        </div>
        <div className="flex justify-between gap-2 border-t border-[var(--color-border)] py-2">
          <dt className="text-[var(--color-text-secondary)]">{t('inhalte.session.naechster')}</dt>
          <dd>{ziel ? <Link to={ziel} className="text-[var(--color-text-link)] hover:underline">{schritt}</Link> : schritt}</dd>
        </div>
      </dl>
    </EdvanceCard>
  )
}

export function ReiheDetail({ reihe, kopf }: { reihe: string; kopf: InhalteReihe | null | undefined }): JSX.Element {
  const { t } = useTranslation('admin')
  const fenster = useZeitfenster()
  const [liste, setListe] = useState<InhalteSession[] | null>(null)
  const [fehler, setFehler] = useState(false)
  useEffect(() => {
    void getSessionReihe(reihe).then((r) => {
      setFehler(r.error !== null)
      setListe(r.data ?? [])
    })
  }, [reihe])
  if (fehler) return <EmptyState icon="⚠️" title={t('inhalte.ladeFehler')} description={t('inhalte.ladeFehlerText')} />
  if (!liste || kopf === undefined) return <LoadingPulse type="card" />
  if (kopf === null || liste.length === 0)
    return <EmptyState icon="🧩" title={t('inhalte.session.unbekannt')} description={t('inhalte.reihen.leerText')} />
  return (
    <div className="flex flex-col gap-4">
      <p className="text-sm text-[var(--color-text-secondary)]">
        {t('inhalte.session.unter', {
          klasse: kopf.klasse ? t('inhalte.klasseTag', { klasse: kopf.klasse }) : '',
          sessions: t('inhalte.reihen.sessions', { count: kopf.sessions }),
          fenster: fenster(kopf.quartal, kopf.von, kopf.bis),
          schulen: t('inhalte.lsa.schulen', { count: kopf.schulen }),
        })}
      </p>
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
        {liste.map((s) => <SessionKarte key={s.nr ?? 'ohne'} s={s} />)}
      </div>
    </div>
  )
}
