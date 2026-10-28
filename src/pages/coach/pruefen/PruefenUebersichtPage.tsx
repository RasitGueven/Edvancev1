// /coach/pruefen — Uebersicht "Aufgaben pruefen" und Abschluss (Entscheidungen 29, 30; Anforderung
// B und G). Lena landet hier ohne Auswahl von Lernstandsanalyse, Klasse oder Fach.
// ?thema=<key>&pause=1 nach "Pause": Thema aufgeklappt, Meldung. ?abschluss=1: Abschlussseite.
// ?bereich=lsa|session (Standard lsa): nur Aufgaben dieses Anlasses; LSA mit Stufen-Reitern, Session nach Thema und
// Fertigkeit. Sollzahlen je Bereich nur mit dem passenden Anlass.
// P4: "Als Naechstes", Enter und "Pruefen" je Thema folgen dem Bedarf (naechsteNoetige, Start im aktiven Reiter).
// MC-Nachtrag: mit den Aufgabentypen zieht der Lauf in Knoten, denen "ohne MC" fehlt, erst die Aufgaben ohne MC.
// ?ohneSoll=1: Lauf nach "Weitere Aufgaben ohne Soll pruefen", wieder der alte Weg.

import { useEffect, useMemo, useState, type JSX } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EmptyState, LoadingPulse } from '@/components/edvance'
import { ErklaerEinstieg } from '@/components/edvance/pruefen/erklaer/ErklaerEinstieg'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { BauformEinstieg } from '@/components/edvance/pruefen/bauform/BauformEinstieg'
import { EntscheidungsMeldung } from '@/components/edvance/pruefen/Entscheidungsleiste'
import { Abschluss, AlsNaechstes, BereichsUmschalter, Themenliste } from '@/components/edvance/pruefen/Uebersicht'
import { useAuth } from '@/hooks/useAuth'
import { ersteNoetigeImThema, knotenOhneAufgabe, naechsteNoetige, restImThema } from '@/lib/pruefung/lauf'
import { naechsteOffene, positionImThema, stand, stufenMitAufgaben } from '@/lib/pruefung/reihenfolge'
import { fehlerSchluessel } from '@/lib/pruefung/texte'
import { getMeineDauer, getPruefBoard } from '@/lib/supabase/pruefung'
import type { PruefBoardZeile, PruefFehlerInfo, PruefSollZeile, Stufe } from '@/types'
import { leseUebersprungen } from './uebersprungen'
import { BEREICHE, bereichsBoard, leseBereich, ohneBereich, type Bereich } from './bereich'
import { ladeMc, ladeSoll } from './usePruefLauf'

export function PruefenUebersichtPage(): JSX.Element {
  const { t } = useTranslation('pruefen')
  const navigate = useNavigate()
  const { user } = useAuth()
  const [params, setParams] = useSearchParams()
  const bereich: Bereich = leseBereich(params) ?? 'lsa'
  const [alle, setAlle] = useState<PruefBoardZeile[] | null>(null)
  const [sollJe, setSollJe] = useState<Record<Bereich, PruefSollZeile[]>>({ lsa: [], session: [] })
  const [mc, setMc] = useState<Set<string> | null>(null)
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
      if (r.data) void ladeMc(r.data).then(setMc)
      const ohne = r.data ? ohneBereich(r.data) : 0
      if (ohne > 0) console.warn('pruef_board: tasks without lsa/session anlass (hidden)', ohne)
    })
    // Sollzahlen sind Zusatz: fehlen sie, bleibt das Board wie vor P2. Ein Bereich zeigt sie erst, wenn alle
    // seine Anlaesse geantwortet haben, sonst stimmten "noch X zu pruefen" und "X von Y noetig" nicht.
    for (const b of BEREICHE) {
      void ladeSoll(b).then((s) => s && setSollJe((x) => ({ ...x, [b]: s })))
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
  const ohneSoll = params.get('ohneSoll') === '1'
  const themaParam = params.get('thema')
  const start = reiter ?? board?.find((z) => z.thema_key === themaParam)?.stufe ?? null
  const skip = leseUebersprungen()
  const schritt = board
    ? naechsteNoetige(board, soll, null, skip, { start, stufen: bereich === 'lsa', ohneSoll, mc })
    : null
  const naechsteId = schritt?.taskId ?? null
  const naechste = board?.find((z) => z.task_id === naechsteId) ?? null
  const aktiv: Stufe | null = start ?? naechste?.stufe ?? stufen[0] ?? null
  const freiId = board ? naechsteOffene(board, null, skip) : null

  const oeffne = (id: string | null, frei = ohneSoll): void => {
    if (id) navigate(`/coach/pruefen/${id}?bereich=${bereich}${frei ? '&ohneSoll=1' : ''}`)
  }
  const fertig = schritt?.grund === 'fertig'
    ? { onOhneSoll: freiId ? () => oeffne(freiId, true) : null, onUebersicht: () => navigate(`/coach/pruefen?bereich=${bereich}`) }
    : null
  const waehle = (b: Bereich): void => {
    setReiter(null)
    setParams({ bereich: b })
  }
  // Reihe 1 A1: keine Aufgabe steht mehr in beiden Pools; die Zeile nennt ihren Pool.
  const zusatz = (z: PruefBoardZeile): string | null => (z.pool ? t(`bereich.pool.${z.pool}`) : null)

  useEffect(() => {
    const taste = (e: KeyboardEvent): void => {
      const el = document.activeElement as HTMLElement | null
      const aufKnopf = !!el && ['BUTTON', 'A', 'INPUT', 'SELECT', 'TEXTAREA'].includes(el.tagName)
      if (e.key === 'Enter' && !aufKnopf && !abschluss && naechsteId) {
        e.preventDefault()
        navigate(`/coach/pruefen/${naechsteId}?bereich=${bereich}${ohneSoll ? '&ohneSoll=1' : ''}`)
      }
    }
    window.addEventListener('keydown', taste)
    return () => window.removeEventListener('keydown', taste)
  }, [naechsteId, abschluss, navigate, bereich, ohneSoll])

  return (
    <>
      <div className="flex flex-col gap-6">
        {!board && !fehler && <LoadingPulse type="card" />}
        {fehler && (
          <EmptyState icon="🔒" title={t('kopf.titel')} description={t(fehlerSchluessel(fehler) ?? 'fehlermeldung.allgemein')} />
        )}
        {board && abschluss && (
          <Abschluss board={board} schnitt={schnitt} onOffene={() => oeffne(naechsteId)}
            onUebersicht={() => navigate(`/coach/pruefen?bereich=${bereich}`)}
            fertig={fertig && { fehlen: knotenOhneAufgabe(board, soll), onOhneSoll: fertig.onOhneSoll }} />
        )}
        {board && !abschluss && (
          <>
            <PageHeader titel={t('kopf.titel')} satz={t('kopf.text')} />
            <ErklaerEinstieg />
            <BauformEinstieg />
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
                <AlsNaechstes board={board} naechste={naechste} fertig={fertig}
                  position={naechste ? positionImThema(board, naechste.task_id) : null}
                  rest={naechste && !ohneSoll ? restImThema(soll, naechste.thema_key) : null}
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
                      onPruefen={(k) => oeffne(ersteNoetigeImThema(board, soll, k, mc))}
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
