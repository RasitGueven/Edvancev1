// /coach/pruefen — Uebersicht "Aufgaben pruefen" und Abschluss (Entscheidungen 29, 30; Anforderung
// B und G). Lena landet hier ohne Auswahl von Lernstandsanalyse, Klasse oder Fach.
// ?thema=<key>&pause=1 nach "Pause": Thema aufgeklappt, Meldung. ?abschluss=1: Abschlussseite.

import { useEffect, useMemo, useState, type JSX } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { EntscheidungsMeldung } from '@/components/edvance/pruefen/Entscheidungsleiste'
import { Abschluss, AlsNaechstes, Themenliste } from '@/components/edvance/pruefen/Uebersicht'
import { useAuth } from '@/hooks/useAuth'
import { ersteImThema, naechsteOffene, positionImThema, stufenMitAufgaben } from '@/lib/pruefung/reihenfolge'
import { fehlerSchluessel } from '@/lib/pruefung/texte'
import { getMeineDauer, getPruefBoard } from '@/lib/supabase/pruefung'
import type { PruefBoardZeile, PruefFehlerInfo, Stufe } from '@/types'
import { leseUebersprungen } from './uebersprungen'

export function PruefenUebersichtPage(): JSX.Element {
  const { t } = useTranslation('pruefen')
  const navigate = useNavigate()
  const { user } = useAuth()
  const [params] = useSearchParams()
  const [board, setBoard] = useState<PruefBoardZeile[] | null>(null)
  const [fehler, setFehler] = useState<PruefFehlerInfo | null>(null)
  const [schnitt, setSchnitt] = useState<number | null>(null)
  const [reiter, setReiter] = useState<Stufe | null>(null)
  const [offen, setOffen] = useState<Set<string>>(() => new Set(params.get('thema') ? [params.get('thema') as string] : []))
  const [pausiert, setPausiert] = useState(params.get('pause') === '1')
  const abschluss = params.get('abschluss') === '1'

  useEffect(() => {
    void getPruefBoard().then((r) => {
      setBoard(r.data)
      setFehler(r.error)
    })
  }, [])

  useEffect(() => {
    if (abschluss && user) void getMeineDauer(user.id).then((r) => setSchnitt(r.data))
  }, [abschluss, user])

  useEffect(() => {
    if (!pausiert) return
    const timer = setTimeout(() => setPausiert(false), 3000)
    return () => clearTimeout(timer)
  }, [pausiert])

  const stufen = useMemo(() => (board ? stufenMitAufgaben(board) : []), [board])
  const naechsteId = board ? naechsteOffene(board, null, leseUebersprungen()) : null
  const naechste = board?.find((z) => z.task_id === naechsteId) ?? null
  const themaParam = params.get('thema')
  const aktiv: Stufe | null = reiter
    ?? board?.find((z) => z.thema_key === themaParam)?.stufe
    ?? naechste?.stufe ?? stufen[0] ?? null

  const oeffne = (id: string | null): void => {
    if (id) navigate(`/coach/pruefen/${id}`)
  }

  useEffect(() => {
    const taste = (e: KeyboardEvent): void => {
      const el = document.activeElement as HTMLElement | null
      const aufKnopf = !!el && ['BUTTON', 'A', 'INPUT', 'SELECT', 'TEXTAREA'].includes(el.tagName)
      if (e.key === 'Enter' && !aufKnopf && !abschluss && naechsteId) {
        e.preventDefault()
        navigate(`/coach/pruefen/${naechsteId}`)
      }
    }
    window.addEventListener('keydown', taste)
    return () => window.removeEventListener('keydown', taste)
  }, [naechsteId, abschluss, navigate])

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)]">
      <EdvanceNavbar subtitle={t('kopf.titel')} sticky />
      <main className="mx-auto flex max-w-5xl flex-col gap-6 px-4 py-8">
        {!board && !fehler && <LoadingPulse type="card" />}
        {fehler && (
          <EmptyState icon="🔒" title={t('kopf.titel')} description={t(fehlerSchluessel(fehler) ?? 'fehlermeldung.allgemein')} />
        )}
        {board && abschluss && (
          <Abschluss board={board} schnitt={schnitt} onOffene={() => oeffne(naechsteId)}
            onUebersicht={() => navigate('/coach/pruefen')} />
        )}
        {board && !abschluss && (
          <>
            <div className="flex flex-col gap-2">
              <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">{t('kopf.titel')}</h1>
              <p className="max-w-3xl text-sm leading-relaxed text-[var(--color-text-secondary)]">{t('kopf.text')}</p>
            </div>
            {board.length === 0 ? (
              <EmptyState icon="📋" title={t('themen.leer')} description={t('themen.leerText')} />
            ) : (
              <>
                <AlsNaechstes board={board} naechste={naechste}
                  position={naechste ? positionImThema(board, naechste.task_id) : null}
                  onWeiter={() => oeffne(naechsteId)} />
                {aktiv && (
                  <section className="flex flex-col gap-2">
                    <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                      {t(`stufe.${aktiv}`)}
                    </h2>
                    <Themenliste board={board} stufen={stufen} aktiv={aktiv} offen={offen} onReiter={setReiter}
                      onThema={(k) => setOffen((o) => {
                        const n = new Set(o)
                        if (n.has(k)) n.delete(k)
                        else n.add(k)
                        return n
                      })}
                      onPruefen={(k) => oeffne(ersteImThema(board, k))}
                      onAufgabe={(id) => oeffne(id)} />
                  </section>
                )}
              </>
            )}
          </>
        )}
      </main>
      {pausiert && <EntscheidungsMeldung text={t('pausiert')} onZu={() => setPausiert(false)} />}
    </div>
  )
}
