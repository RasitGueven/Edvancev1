// /coach/pruefen/:taskId — die Pruefansicht: ein Bildschirm je Aufgabe (Entscheidungen 30 bis 37).
// Links die Kinderansicht, rechts die Pruefkarte, unten die Entscheidungsleiste. Nach jeder
// Entscheidung oeffnet sich sofort die naechste offene Aufgabe; eine Meldung bietet 5 s "Rueckgaengig".

import { useCallback, useEffect, useMemo, useState, type JSX } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { Button } from '@/components/ui'
import { Kinderansicht } from '@/components/edvance/pruefen/Kinderansicht'
import { PruefKopf } from '@/components/edvance/pruefen/PruefKopf'
import { RichtigeAntwort } from '@/components/edvance/pruefen/RichtigeAntwort'
import { AntwortTesten, Loesungsweg, RegelBlock } from '@/components/edvance/pruefen/RegelUndTesten'
import { TypischeFehler } from '@/components/edvance/pruefen/TypischeFehler'
import { AenderungenBox, Einordnung } from '@/components/edvance/pruefen/Einordnung'
import {
  Auffaelligkeiten, EntscheidungsMeldung, Entscheidungsleiste, type Panel,
} from '@/components/edvance/pruefen/Entscheidungsleiste'
import { useAuth } from '@/hooks/useAuth'
import { feldZuruecksetzen, geaenderteFelder, lokaleAenderungen, sperrgrund, type Feld } from '@/lib/pruefung/entwurf'
import { naechsteOffene, positionImThema, vorige } from '@/lib/pruefung/reihenfolge'
import { fehlerSchluessel } from '@/lib/pruefung/texte'
import { getFehlbilder, getPruefBoard, getPruefEinstellungen, pruefEntscheiden, pruefRueckgaengig } from '@/lib/supabase/pruefung'
import type { Fehlbild, LenaStatus, PasstNichtGrund, PruefBoardZeile, PruefEntscheidung } from '@/types'
import { leseUebersprungen, merkeUebersprungen, vergissUebersprungen } from './uebersprungen'
import { usePruefSitzung } from './usePruefSitzung'
import { useTasten } from './useTasten'

const NICHT_IM_BOARD = ['vera8', 'inaktiv', 'typ']

export function PruefansichtPage(): JSX.Element {
  const { taskId } = useParams<{ taskId: string }>()
  const navigate = useNavigate()
  const { t } = useTranslation('pruefen')
  const { role } = useAuth()
  const s = usePruefSitzung(taskId)
  const [board, setBoard] = useState<PruefBoardZeile[]>([])
  const [fehlbilder, setFehlbilder] = useState<Fehlbild[]>([])
  const [grundPflicht, setGrundPflicht] = useState(false)
  const [panel, setPanel] = useState<Panel>(null)
  const [grund, setGrund] = useState('')
  const [arbeitet, setArbeitet] = useState(false)
  const [fehler, setFehler] = useState<string | null>(null)
  const [meldung, setMeldung] = useState<{ text: string; rueckgaengig?: () => void } | null>(null)

  useEffect(() => {
    void getPruefBoard().then((r) => r.data && setBoard(r.data))
    void getFehlbilder().then((r) => r.data && setFehlbilder(r.data))
    void getPruefEinstellungen().then((r) => setGrundPflicht(r.data?.grund_pflicht ?? false))
  }, [])

  useEffect(() => {
    setPanel(null)
    setGrund('')
    setFehler(null)
    window.scrollTo({ top: 0 })
  }, [taskId])

  useEffect(() => {
    if (!meldung) return
    const timer = setTimeout(() => setMeldung(null), 5000)
    return () => clearTimeout(timer)
  }, [meldung])

  const a = s.aufgabe
  const team = !!a?.aufgabe.team_beanstandet
  const lesend = !a || a.aufgabe.status === 'ready' || team || NICHT_IM_BOARD.includes(a.aufgabe.ausschluss ?? '') || s.konflikt
  const felder = useMemo(() => (s.b && s.ausgang ? geaenderteFelder(s.ausgang, s.b) : new Set<Feld>()), [s.b, s.ausgang])
  const aenderungen = useMemo(() => (s.b && s.ausgang ? lokaleAenderungen(s.ausgang, s.b) : []), [s.b, s.ausgang])
  const sperre = a && s.b ? sperrgrund(a.aufgabe.input_type, s.b) : null
  const position = taskId ? positionImThema(board, taskId) : null
  const fehlbildName = useCallback((slug: string) => fehlbilder.find((f) => f.slug === slug)?.klartext ?? slug, [fehlbilder])
  const namen = useMemo(() => ({
    fehlbild: fehlbildName,
    fertigkeit: (k: string) => a?.fertigkeit_optionen.find((o) => o.key === k)?.label ?? k,
    option: (id: string) => {
      const o = a?.aufgabe.optionen.find((x) => x.id === id)
      return o ? `${id}) ${o.label}` : id
    },
  }), [a, fehlbildName])

  const geheZu = useCallback((id: string | null) => {
    navigate(id ? `/coach/pruefen/${id}` : '/coach/pruefen?abschluss=1')
  }, [navigate])

  const pause = async (): Promise<void> => {
    await s.sichern()
    navigate(`/coach/pruefen?thema=${encodeURIComponent(position?.thema_key ?? '')}&pause=1`)
  }

  const statusText = (st: LenaStatus, geaendert: boolean): string =>
    st === 'passt' && geaendert ? t('status.passtGeaendert') : t(`status.${st}`)

  const entscheide = async (e: PruefEntscheidung, gruende?: PasstNichtGrund[], notiz?: string): Promise<void> => {
    if (!taskId || !a || arbeitet) return
    setArbeitet(true)
    setFehler(null)
    const gesichert = await s.sichern()
    if (!gesichert) {
      setArbeitet(false)
      return
    }
    const res = await pruefEntscheiden({
      taskId, version: s.versionJetzt(), entscheidung: e, gruende, notiz,
      aenderungGrund: grund, dauerSek: s.dauerSek(),
    })
    setArbeitet(false)
    if (res.error || !res.data) {
      const key = fehlerSchluessel(res.error)
      setFehler(key ? t(key) : null)
      return
    }
    const geaendert = aenderungen.length > 0
    const neu = board.map((z) => (z.task_id === taskId ? { ...z, lena_status: res.data!.lena_status, geaendert } : z))
    setBoard(neu)
    vergissUebersprungen(taskId)
    const version = res.data.pruef_version
    const id = taskId
    setMeldung({
      text: t('meldung.entschieden', {
        thema: position?.thema_label ?? '', nr: position?.nr ?? '', status: statusText(res.data.lena_status, geaendert),
      }),
      rueckgaengig: () => {
        setMeldung(null)
        void pruefRueckgaengig(id, version).then((r) => {
          if (r.error) return setFehler(t(fehlerSchluessel(r.error) ?? 'fehlermeldung.allgemein'))
          setBoard((b) => b.map((z) => (z.task_id === id ? { ...z, lena_status: 'offen' } : z)))
          geheZu(id)
        })
      },
    })
    geheZu(naechsteOffene(neu, taskId, leseUebersprungen()))
  }

  const ueberspringen = (): void => {
    if (!taskId) return
    void s.sichern().then(() => geheZu(naechsteOffene(board, taskId, merkeUebersprungen(taskId))))
  }
  const zurueck = (): void => {
    const v = taskId ? vorige(board, taskId) : null
    if (v) void s.sichern().then(() => geheZu(v))
  }

  useTasten({
    aktiv: !!a && !lesend,
    panelOffen: panel !== null,
    passt: () => { if (!sperre) void entscheide('passt') },
    panel: (p) => setPanel(p),
    panelZu: () => setPanel(null),
    zurueck,
    weiter: ueberspringen,
    pause: () => void pause(),
  })

  const zuruecksetzen = (feld: Feld): void => {
    if (s.b && s.ausgang) s.aendern(feldZuruecksetzen(s.b, s.ausgang, feld))
  }

  const info = !a || a.aufgabe.status === 'ready'
    ? { art: 'gesperrt' as const, text: t('leiste.gesperrtFreigegeben') }
    : team ? { art: 'gesperrt' as const, text: t('leiste.gesperrtTeam') }
    : sperre ? { art: 'sperre' as const, text: t(`leiste.sperre.${sperre}`) }
      : aenderungen.length ? { art: 'aenderungen' as const, text: t('leiste.aenderungen', { count: aenderungen.length }) }
        : { art: 'vorbefuellt' as const, text: t('leiste.allesVorbefuellt') }

  const letzte = a?.letzte_pruefung
  const bewertet = a && !team && a.aufgabe.lena_status !== 'offen' && a.aufgabe.lena_status !== 'freigegeben'

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)]">
      <EdvanceNavbar subtitle={t('kopf.titel')} sticky />
      <main className="mx-auto flex max-w-6xl flex-col gap-6 px-4 pb-56 pt-6">
        {s.laedt && <LoadingPulse type="card" />}
        {!s.laedt && !a && (
          <EmptyState icon="🔎" title={t('ansicht.ladeFehler')} description={t(fehlerSchluessel(s.ladeFehler) ?? 'fehlermeldung.allgemein')}
            action={<Button onClick={() => navigate('/coach/pruefen')}>{t('abschluss.zurUebersicht')}</Button>} />
        )}
        {a && s.b && s.ausgang && (
          <>
            <PruefKopf aufgabe={a} position={position} hatVorige={!!(taskId && vorige(board, taskId))}
              onZurueck={zurueck} onUeberspringen={ueberspringen} onPause={() => void pause()} />
            {s.konflikt && (
              <EdvanceCard className="flex flex-wrap items-center justify-between gap-4 border-[var(--color-warning)] bg-[var(--color-warning-light)]">
                <p className="text-sm font-semibold text-[var(--color-warning)]">{t('ansicht.konflikt')}</p>
                <Button onClick={s.neuLaden}>{t('ansicht.neuLaden')}</Button>
              </EdvanceCard>
            )}
            {a.aufgabe.status === 'ready' && <p className="text-sm text-[var(--color-text-secondary)]">{t('ansicht.freigegeben')}</p>}
            {team && (
              <p role="status" className="rounded-[var(--radius-md)] bg-[var(--color-destructive-light)] p-3 text-sm font-semibold text-[var(--color-destructive)]">
                {t('ansicht.teamBeanstandet')}
              </p>
            )}
            {a.aufgabe.ausschluss && <p className="text-sm text-[var(--color-text-secondary)]">{t('ansicht.nichtImBoard')}</p>}
            {bewertet && (
              <p className="rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] p-3 text-sm text-[var(--color-text-secondary)]">
                {t('ansicht.schonBewertet', { status: statusText(a.aufgabe.lena_status, a.aenderungen.length > 0) })}
                {letzte?.gruende.length ? ` · ${letzte.gruende.map((g) => t(`gruende.${g}`)).join(', ')}` : ''}
                {letzte?.notiz ? ` · „${letzte.notiz}“` : ''}. {t('ansicht.schonBewertetNeu')}
                {letzte?.antwort && <><br />{t('ansicht.antwortTeam', { antwort: letzte.antwort })}</>}
              </p>
            )}
            <div className="grid items-start gap-6 lg:grid-cols-[minmax(0,0.92fr)_minmax(0,1.08fr)]">
              <Kinderansicht aufgabe={a} />
              <EdvanceCard className="flex flex-col gap-6">
                <Auffaelligkeiten aufgabe={a} liste={s.auffaelligkeiten} />
                <section className="flex flex-col gap-4">
                  <RichtigeAntwort aufgabe={a} b={s.b} geaendert={felder.has('antwort')} lesend={lesend}
                    onChange={s.aendern} onZurueck={() => zuruecksetzen('antwort')} />
                  <RegelBlock aufgabe={a} b={s.b} geaendert={felder.has('regel')} lesend={lesend}
                    onChange={s.aendern} onZurueck={() => zuruecksetzen('regel')} />
                  <AntwortTesten aufgabe={a} b={s.b} />
                  <Loesungsweg text={a.loesungsweg} />
                </section>
                <TypischeFehler aufgabe={a} b={s.b} fehlbilder={fehlbilder} geaendert={felder.has('fehler')} lesend={lesend}
                  onChange={s.aendern} onZurueck={() => zuruecksetzen('fehler')} />
                <Einordnung aufgabe={a} b={s.b} ausgang={s.ausgang} fertigkeitGeaendert={felder.has('fertigkeit')}
                  afbGeaendert={felder.has('afb')} lesend={lesend} onChange={s.aendern} onZurueck={zuruecksetzen} />
                <AenderungenBox aenderungen={aenderungen} namen={namen} mc={a.aufgabe.input_type === 'MC'}
                  grund={grund} grundPflicht={grundPflicht} onGrund={setGrund} />
                <p className="text-xs text-[var(--color-text-tertiary)]" aria-live="polite">
                  {s.speichert ? t('ansicht.speichert') : t('ansicht.gespeichert')}
                </p>
                {role === 'admin' && (
                  <Link to={`/admin/authoring/${a.task_id}`} className="min-h-[44px] text-sm text-[var(--color-text-link)] hover:underline">
                    {t('ansicht.expertenmodus')}
                  </Link>
                )}
              </EdvanceCard>
            </div>
          </>
        )}
      </main>
      {a && s.b && (
        <Entscheidungsleiste key={taskId} panel={panel} setPanel={setPanel} info={info}
          passtGesperrt={sperre ? t(`leiste.sperre.${sperre}`) : null} arbeitet={arbeitet}
          fehler={fehler ?? (s.fehler && !s.konflikt ? t(fehlerSchluessel(s.fehler) ?? 'fehlermeldung.allgemein') : null)}
          onPasst={() => void entscheide('passt')}
          onNicht={(g, n) => void entscheide('passt_nicht', g, n)}
          onUnsicher={(f) => void entscheide('unsicher', undefined, f)} />
      )}
      {meldung && <EntscheidungsMeldung text={meldung.text} onRueckgaengig={meldung.rueckgaengig} onZu={() => setMeldung(null)} />}
    </div>
  )
}
