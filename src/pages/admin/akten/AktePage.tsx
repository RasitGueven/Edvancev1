import { useCallback, useEffect, useState } from 'react'
import { Navigate, useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { AdminHeader, EdvanceBadge, EdvanceCard, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { useAuth } from '@/hooks/useAuth'
import { datum } from '@/lib/akte/format'
import {
  getEinheitenStand,
  getFortschritt,
  getSchuelerakte,
  listAkteSessions,
  listElternReports,
  listFaecher,
} from '@/lib/supabase/akte'
import { listNotizen, listWortlisteGesundheit } from '@/lib/supabase/akteNotizen'
import type {
  AkteSession,
  EinheitenStand,
  ElternReport,
  FachFortschritt,
  Schuelerakte,
  SchuelerNotiz,
  WortlisteEintrag,
} from '@/types'
import { FortschrittKachel } from './FortschrittKachel'
import type { BoardHinweis } from './BoardPage'
import { EinheitenKachel } from './EinheitenKachel'
import { NotizenKachel } from './NotizenKachel'
import { ReportsKachel } from './ReportsKachel'
import { SessionsKachel } from './SessionsKachel'
import { StammdatenKachel } from './StammdatenKachel'

type Daten = {
  stand: EinheitenStand | null
  sessions: AkteSession[]
  notizen: SchuelerNotiz[]
  wortliste: WortlisteEintrag[]
  faecher: string[]
  reports: ElternReport[]
  fortschritt: FachFortschritt[]
}

const LEER: Daten = { stand: null, sessions: [], notizen: [], wortliste: [], faecher: [], reports: [], fortschritt: [] }

/**
 * Die Schuelerakte (/admin/akten/:studentId) fuer Admin und Coach.
 * Sichtbarkeit entscheidet die Datenbank: schuelerakten liefert einem Coach
 * keine ruhende Akte — dann zurueck aufs Board mit Hinweis.
 */
export function AktePage(): JSX.Element {
  const { t, i18n } = useTranslation('akte')
  const { role } = useAuth()
  const { studentId = '' } = useParams()
  const istAdmin = role === 'admin'

  const [akte, setAkte] = useState<Schuelerakte | null>(null)
  const [daten, setDaten] = useState<Daten>(LEER)
  const [status, setStatus] = useState<'laedt' | 'da' | 'weg'>('laedt')
  const [error, setError] = useState<string | null>(null)

  const laden = useCallback((): void => {
    void getSchuelerakte(studentId).then(async ({ data: a, error: e }) => {
      if (e) {
        setError(e)
        setStatus('da')
        return
      }
      if (!a) {
        setStatus('weg')
        return
      }
      const [stand, sessions, notizen, wortliste, faecher, reports, fortschritt] = await Promise.all([
        a.zustand === 'aktiv' ? getEinheitenStand(studentId) : Promise.resolve({ data: null, error: null }),
        listAkteSessions(studentId),
        listNotizen(studentId),
        listWortlisteGesundheit(),
        listFaecher(studentId),
        listElternReports(studentId),
        getFortschritt(studentId),
      ])
      setAkte(a)
      setDaten({
        stand: stand.data,
        sessions: sessions.data ?? [],
        notizen: notizen.data ?? [],
        wortliste: wortliste.data ?? [],
        faecher: faecher.data ?? [],
        reports: reports.data ?? [],
        fortschritt: fortschritt.data ?? [],
      })
      setError(
        stand.error ?? sessions.error ?? notizen.error ?? wortliste.error ?? faecher.error ?? reports.error ?? fortschritt.error,
      )
      setStatus('da')
    })
  }, [studentId])

  useEffect(laden, [laden])

  if (status === 'weg') {
    const hinweis: BoardHinweis = istAdmin ? 'nichtGefunden' : 'ruhendCoach'
    return <Navigate to="/admin/akten" replace state={{ hinweis }} />
  }

  const lang = i18n.language
  const ruhend = akte?.zustand === 'ruhend'

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <EdvanceNavbar subtitle={t('board.titel')} sticky />
      <main className="mx-auto flex max-w-5xl flex-col gap-6 px-4 py-8">
        {status === 'laedt' || !akte ? (
          error ? (
            <p className="text-sm text-[var(--color-error-exam)]">{t('fehler.laden')}</p>
          ) : (
            <LoadingPulse type="list" lines={6} />
          )
        ) : (
          <>
            <AdminHeader
              eyebrow={[
                akte.klasse !== null ? t('kopf.klasse', { klasse: akte.klasse }) : null,
                akte.schule,
              ]
                .filter(Boolean)
                .join(' · ')}
              title={akte.name ?? '—'}
              description={akte.akte_seit ? t('kopf.akteSeit', { datum: datum(akte.akte_seit, lang) }) : undefined}
              backTo="/admin/akten"
              backLabel={t('kopf.zurueck')}
              actions={<EdvanceBadge variant={ruhend ? 'muted' : 'strength'}>{t(`kopf.zustand.${akte.zustand}`)}</EdvanceBadge>}
            />

            {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}

            {ruhend && (
              <EdvanceCard variant="subtle" className="flex flex-col gap-2 p-6">
                <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{t('kopf.ruhendHinweis')}</p>
                {akte.ruhend_seit && (
                  <p className="text-xs text-[var(--color-text-tertiary)]">
                    {t('kopf.ruhendSeit', { datum: datum(akte.ruhend_seit, lang) })}
                  </p>
                )}
              </EdvanceCard>
            )}

            <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
              {!ruhend && <EinheitenKachel stand={daten.stand} />}
              <SessionsKachel sessions={daten.sessions} />
              <NotizenKachel
                studentId={studentId}
                notizen={daten.notizen}
                wortliste={daten.wortliste}
                darfSchreiben={istAdmin || !ruhend}
                istAdmin={istAdmin}
                onGeaendert={laden}
              />
              <StammdatenKachel akte={akte} faecher={daten.faecher} istAdmin={istAdmin} onGespeichert={laden} />
              <ReportsKachel reports={daten.reports} />
              <FortschrittKachel faecher={daten.fortschritt} />
            </div>
          </>
        )}
      </main>
    </div>
  )
}
