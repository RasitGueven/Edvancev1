// /coach/pruefen — Uebersicht "Aufgaben pruefen" und Abschluss (Entscheidungen 29, 30; Anforderung
// B und G). Lena landet hier ohne Auswahl von Lernstandsanalyse, Klasse oder Fach.
// ?thema=<key>&pause=1 nach "Pause": Thema aufgeklappt, Meldung. ?abschluss=1: Abschlussseite.
// ?bereich=lsa|session (Standard lsa): nur Aufgaben dieses Anlasses; LSA mit Stufen-Reitern, Session nach Thema und
// Fertigkeit. Sollzahlen je Bereich nur mit dem passenden Anlass.

import { useEffect, useMemo, useState, type JSX } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EmptyState, LoadingPulse } from '@/components/edvance'
import { ErklaerEinstieg } from '@/components/edvance/pruefen/erklaer/ErklaerEinstieg'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { EntscheidungsMeldung } from '@/components/edvance/pruefen/Entscheidungsleiste'
import { Abschluss, AlsNaechstes, BereichsUmschalter, Themenliste } from '@/components/edvance/pruefen/Uebersicht'
import { useAuth } from '@/hooks/useAuth'
import { ersteImThema, naechsteOffene, positionImThema, stand, stufenMitAufgaben } from '@/lib/pruefung/reihenfolge'
import { fehlerSchluessel } from '@/lib/pruefung/texte'
import { getMeineDauer, getPruefBoard, getPruefSoll } from '@/lib/supabase/pruefung'
import type { PruefBoardZeile, PruefFehlerInfo, PruefSollZeile, Stufe } from '@/types'
import { leseUebersprungen } from './uebersprungen'
import { ANLASS, auchIn, BEREICHE, bereichsBoard, leseBereich, ohneBereich, sollDesBereichs, type Bereich } from './bereich'

export function PruefenUebersichtPage(): JSX.Element {
  const { t } = useTranslation('pruefen')
  const navigate = useNavigate()
  const { user } = useAuth()
  const [params, setParams] = useSearchParams()
  const bereich: Bereich = leseBereich(params) ?? 'lsa'
  const [alle, setAlle] = useState<PruefBoardZeile[] | null>(null)
  const [sollJe, setSollJe] = useState<Record<Bereich, PruefSollZeile[]>>({ lsa: [], session: [] })
  const [fehler, setFehler] = useState<PruefFehlerInfo | null>(null)
  const [schnitt, setSchnitt] = useState<number | null>(null)
  const [reiter, setReiter] = useState<Stufe | null>(null)
  const [offen, setOffen] = useState<Set<string>>(() => new Set(params.get('thema') ? [params.get('thema') as string] : []))
  const [pausiert, setPausiert] = useState(params.get('pause') === '1')
  const abschluss = params.get('abschluss') === '1'

  useEffect(() => {
    void getPruefBoard().then((r) => {
      setAlle(r.data)
      setFehler(r.error)
      const ohne = r.data ? ohneBereich(r.data) : 0
      if (ohne > 0) console.warn('pruef_board: tasks without lsa/session anlass (hidden)', ohne)
    })
    // Sollzahlen sind Zusatz: fehlen sie, bleibt das Board wie vor P2. Ein Bereich zeigt sie erst, wenn alle
    // seine Anlaesse geantwortet haben, sonst stimmten "noch X zu pruefen" und "X von Y noetig" nicht.
    for (const b of BEREICHE) {
      void Promise.all(ANLASS[b].map((a) => getPruefSoll(a))).then((rs) => {
        const kaputt = rs.find((r) => r.error)
        if (kaputt?.error) console.warn('pruef_board_soll failed', ANLASS[b], kaputt.error.message)
        else setSollJe((s) => ({ ...s, [b]: sollDesBereichs(rs.map((r) => r.data ?? [])) }))
      })
    }
  }, [])

  const board = useMemo(() => (alle ? bereichsBoard(alle, bereich) : null), [alle, bereich])
  const soll = sollJe[bereich]

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
    if (id) navigate(`/coach/pruefen/${id}?bereich=${bereich}`)
  }
  const waehle = (b: Bereich): void => {
    setReiter(null)
    setParams({ bereich: b })
  }
  const zusatz = (z: PruefBoardZeile): string | null => {
    const auch = auchIn(z, bereich)
    return auch ? t(`bereich.auch.${auch}`) : null
  }

  useEffect(() => {
    const taste = (e: KeyboardEvent): void => {
      const el = document.activeElement as HTMLElement | null
      const aufKnopf = !!el && ['BUTTON', 'A', 'INPUT', 'SELECT', 'TEXTAREA'].includes(el.tagName)
      if (e.key === 'Enter' && !aufKnopf && !abschluss && naechsteId) {
        e.preventDefault()
        navigate(`/coach/pruefen/${naechsteId}?bereich=${bereich}`)
      }
    }
    window.addEventListener('keydown', taste)
    return () => window.removeEventListener('keydown', taste)
  }, [naechsteId, abschluss, navigate, bereich])

  return (
    <>
      <div className="flex flex-col gap-6">
        {!board && !fehler && <LoadingPulse type="card" />}
        {fehler && (
          <EmptyState icon="🔒" title={t('kopf.titel')} description={t(fehlerSchluessel(fehler) ?? 'fehlermeldung.allgemein')} />
        )}
        {board && abschluss && (
          <Abschluss board={board} schnitt={schnitt} onOffene={() => oeffne(naechsteId)}
            onUebersicht={() => navigate(`/coach/pruefen?bereich=${bereich}`)} />
        )}
        {board && !abschluss && (
          <>
            <PageHeader titel={t('kopf.titel')} satz={t('kopf.text')} />
            <ErklaerEinstieg />
            {alle && alle.length > 0 && (
              <BereichsUmschalter aktiv={bereich} onWahl={waehle} bereiche={BEREICHE.map((b) => {
                const st = stand(bereichsBoard(alle, b))
                return { key: b, label: t(`bereich.${b}`), zahl: t('bereich.zahl', { offen: st.offen, gesamt: st.gesamt }) }
              })} />
            )}
            {board.length === 0 ? (
              <EmptyState icon="📋" title={t(alle?.length ? `bereich.leer.${bereich}` : 'themen.leer')}
                description={t(alle?.length ? 'bereich.leerText' : 'themen.leerText')} />
            ) : (
              <>
                <AlsNaechstes board={board} naechste={naechste}
                  position={naechste ? positionImThema(board, naechste.task_id) : null}
                  onWeiter={() => oeffne(naechsteId)} />
                {aktiv && (
                  <section className="flex flex-col gap-2">
                    <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                      {bereich === 'lsa' ? t(`stufe.${aktiv}`) : t('bereich.sessionUeberschrift')}
                    </h2>
                    <Themenliste board={board} soll={soll} stufen={stufen} aktiv={aktiv} offen={offen} onReiter={setReiter}
                      reiter={bereich === 'lsa'} zusatz={zusatz} reichtText={t(`bereich.reicht.${bereich}`)}
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
      </div>
      {pausiert && <EntscheidungsMeldung text={t('pausiert')} onZu={() => setPausiert(false)} />}
    </>
  )
}
