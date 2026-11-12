// /coach/pruefen/bauformen/:bauformId: Lena prüft eine Bauform (SP-1 S4, Aufbau wie docs/freigabe/sp1/referenz/
// session-pruefung-dummy.html). Links scrollt: Grundgerüst, typische Fehler, Stufen mit Zeit, sechs Beispiele; rechts
// steht fest: Kommentare und ein Knopf (Passt | Rückfrage). Kommentare und Zeiten bleiben als Entwurf im Browser je
// Bauform und Version. Nach dem Senden öffnet sich die nächste Bauform „Zu prüfen“, sonst die Liste mit Rückmeldung.
import { useCallback, useEffect, useMemo, useRef, useState, type JSX } from 'react'
import { useLocation, useNavigate, useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EmptyState, LoadingPulse } from '@/components/edvance'
import { Button } from '@/components/ui'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { Abschnitt, Etikett } from '@/components/edvance/pruefen/bauform/pruefansicht/Bausteine'
import { BeispielKarte } from '@/components/edvance/pruefen/bauform/pruefansicht/BeispielKarte'
import { FehlerKarte, GrundgeruestKarte, StufenKarte } from '@/components/edvance/pruefen/bauform/pruefansicht/SteckbriefKarten'
import { RueckmeldungSpalte } from '@/components/edvance/pruefen/bauform/pruefansicht/RueckmeldungSpalte'
import { useAuth } from '@/hooks/useAuth'
import { bauformTitel, naechsteZuPruefen } from '@/lib/pruefung/bauformPlan'
import {
  aendern, entfernen, entwurfLaden, entwurfSpeichern, grundUmschalten, hinzufuegen, kommentarSchluessel, LEER,
  schluesselVon, zeitSchritt, zumSenden, type Entwurf, type Kommentar, type KommentarAnker,
} from '@/lib/pruefung/bauformKommentar'
import { bauformPruefungSenden, getBauformDetail, getBauformPlan } from '@/lib/supabase/bauformPruefung'
import type { BauformDetail, BauformPlanZeile } from '@/types/bauformPruefung'

export function BauformDetailPage(): JSX.Element {
  const { t, i18n } = useTranslation('bauformPruefen')
  const { bauformId = '' } = useParams()
  const navigate = useNavigate()
  const ankunft = (useLocation().state as { meldung?: string } | null)?.meldung ?? null
  const { role } = useAuth()
  const [seed, setSeed] = useState(0)
  const [detail, setDetail] = useState<BauformDetail | null>(null)
  const [fehler, setFehler] = useState<string | null>(null)
  const [meldung, setMeldung] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  const [plan, setPlan] = useState<BauformPlanZeile[]>([])
  const [entwurf, setEntwurf] = useState<Entwurf>(LEER)
  const [fokus, setFokus] = useState<string | null>(null)
  const start = useRef(Date.now())
  const behalten = useRef<string[]>([])

  useEffect(() => {
    void getBauformDetail(bauformId, seed, behalten.current).then((r) => {
      setDetail(r.data)
      setFehler(r.error?.message ?? null)
    })
  }, [bauformId, seed])

  // Neue Bauform: Entwurf dieser Version laden, Zähler und Ziehung zurück.
  const version = detail?.version
  useEffect(() => {
    if (version == null) return
    setEntwurf(entwurfLaden(bauformId, version))
    start.current = Date.now()
  }, [bauformId, version])
  useEffect(() => {
    setSeed(0)
    setMeldung(null)
  }, [bauformId])

  useEffect(() => {
    void getBauformPlan().then((r) => setPlan(r.data ?? []))
  }, [bauformId])

  const aendereEntwurf = useCallback((f: (e: Entwurf) => Entwurf) => {
    setEntwurf((alt) => {
      const neu = f(alt)
      if (version != null) entwurfSpeichern(bauformId, version, neu)
      return neu
    })
  }, [bauformId, version])

  const zeile = plan.find((z) => z.bauform_id === bauformId) ?? null
  const nrVon = useMemo(() => new Map((detail?.beispiele ?? []).map((b, i) => [b.task_id, i + 1])), [detail])
  const ort = (k: Kommentar): string =>
    k.anker === 'beispiel' ? t('ansicht.ort.beispiel', { nr: nrVon.get(k.task_id ?? '') ?? '' }) : t(`ansicht.ort.${k.anker}`)
  const hat = (anker: KommentarAnker, taskId: string | null = null): boolean =>
    entwurf.kommentare.some((k) => schluesselVon(k) === kommentarSchluessel(anker, taskId))
  const kommentieren = (anker: KommentarAnker, taskId: string | null = null): void => {
    aendereEntwurf((e) => hinzufuegen(e, anker, taskId))
    setFokus(`${kommentarSchluessel(anker, taskId)}#${Date.now()}`)
  }
  const springen = (k: Kommentar): void => {
    const el = document.getElementById(k.anker === 'beispiel' ? `anker-beispiel-${k.task_id}` : `anker-${k.anker}`)
    el?.scrollIntoView({ behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth', block: 'start' })
    el?.focus({ preventScroll: true })
  }
  const andereBeispiele = (): void => {
    behalten.current = entwurf.kommentare.filter((k) => k.anker === 'beispiel' && k.task_id).map((k) => k.task_id as string)
    setSeed((s) => s + 1)
  }

  const senden = async (): Promise<void> => {
    if (!detail || busy) return
    setBusy(true)
    const { kommentare, zeiten } = zumSenden(entwurf)
    const r = await bauformPruefungSenden(detail.bauform_id, detail.version, kommentare, zeiten, Math.round((Date.now() - start.current) / 1000))
    setBusy(false)
    if (r.error) {
      setMeldung(r.error.code === 'ED409' ? t('ansicht.geaendert') : t('ansicht.fehlerSenden', { message: r.error.message }))
      return
    }
    entwurfSpeichern(detail.bauform_id, detail.version, LEER)
    const titel = zeile ? bauformTitel(zeile) : (detail.titel ?? detail.skill_label)
    const erst = t(kommentare.length ? 'ansicht.gesendetRueckfrage' : 'ansicht.gesendetPasst', { titel })
    const weiter = naechsteZuPruefen(plan, detail.bauform_id)
    behalten.current = []
    if (weiter) navigate(`/coach/pruefen/bauformen/${weiter.bauform_id}`, { state: { meldung: `${erst} ${t('ansicht.weiterMit', { titel: bauformTitel(weiter) })}` } })
    else navigate('/coach/pruefen/bauformen', { state: { meldung: `${erst} ${t('ansicht.alleGeprueft')}` } })
  }

  if (fehler) return <EmptyState icon="🔒" title={t('liste.titel')} description={fehler} />
  if (!detail) return <LoadingPulse type="card" />
  const offen = detail.status === 'zur_pruefung'
  const zeitVon = (stufe: number): number =>
    entwurf.zeiten[String(stufe)] ?? detail.stufen?.find((s) => s.stufe === stufe)?.zeit_min ?? 1
  const zahl = (n: number): string => new Intl.NumberFormat(i18n.language, { maximumFractionDigits: 1 }).format(n)
  const zeitZeile = Object.keys(entwurf.zeiten).length
    ? t('ansicht.zeitGeaendert', { liste: Object.entries(entwurf.zeiten).map(([s, w]) => t('ansicht.zeitStufe', { stufe: s, wert: zahl(w) })).join(' · ') })
    : null
  const p = detail.pruefprotokoll
  const gesamt = (p.gruen ?? 0) + (p.rot ?? 0)
  const titel = zeile ? bauformTitel(zeile) : (detail.titel ?? detail.skill_label)

  return (
    <div className="flex flex-col gap-6">
      <PageHeader titel={titel} zurueckZu="/coach/pruefen/bauformen" zurueckLabel={t('ansicht.zurueck')}
        aktionen={<EdvanceBadge variant={offen ? 'warning' : 'muted'}>{t('ansicht.statusVersion', { status: t(`status.${detail.status}`), version: detail.version })}</EdvanceBadge>} />
      <div className="-mt-4 flex flex-col gap-2">
        <p className="flex flex-wrap items-center gap-2 text-sm text-[var(--color-text-secondary)]">
          <Etikett ton="kuerzel">{detail.schluessel}</Etikett>
          <span>{t(zeile?.ist_voraussetzung ?? !detail.kernidee_key ? 'ansicht.voraussetzung' : 'ansicht.kern')}</span>
          {zeile?.session_nr != null && <span>· {t('ansicht.gebrauchtIn', { nr: zeile.session_nr })}</span>}
          <span>· {t('karte.antwort', { art: t(`antwortart.${zeile?.antwortart ?? detail.format}`, { defaultValue: t('antwortart.sonst') }) })}</span>
          <b className="text-[var(--color-text-primary)]">· {t('ansicht.uebernehmen', { count: zeile?.gruen ?? detail.instanzen })}</b>
        </p>
        {gesamt > 0 && <p className="text-xs text-[var(--color-text-muted)]">{t('ansicht.automatisch', { gruen: p.gruen ?? 0, gesamt })}</p>}
        {role === 'admin' && detail.blindloeser && (
          <p className="text-xs text-[var(--color-text-muted)]">
            {t('ansicht.blindloeser', { geloest: detail.blindloeser.geloest ?? 0, abweichend: detail.blindloeser.abweichend?.length ?? 0 })}
          </p>
        )}
        {(meldung ?? ankunft) && <p role="status" className="text-sm font-semibold text-[var(--color-text-primary)]">{meldung ?? ankunft}</p>}
      </div>

      <div className="grid gap-6 min-[980px]:grid-cols-[minmax(0,1fr)_380px]">
        <div className="flex min-w-0 flex-col gap-4">
          <div className="grid gap-4 min-[1600px]:grid-cols-2">
            <GrundgeruestKarte detail={detail} anker={{ markiert: hat('grundgeruest'), onKommentar: () => kommentieren('grundgeruest') }} />
            <FehlerKarte detail={detail} anker={{ markiert: hat('fehlbilder'), onKommentar: () => kommentieren('fehlbilder') }} />
          </div>
          <StufenKarte detail={detail} anker={{ markiert: hat('stufen'), onKommentar: () => kommentieren('stufen') }}
            zeiten={entwurf.zeiten} aenderbar={offen} onZeit={(s, v, d) => aendereEntwurf((e) => zeitSchritt(e, s, v, d))} />
          <div className="flex items-center justify-between gap-4 pt-2">
            <Abschnitt>{t('ansicht.beispiele')}</Abschnitt>
            <Button variant="outline" onClick={andereBeispiele}>{t('ansicht.andere')}</Button>
          </div>
          {detail.beispiele.length === 0 ? (
            <EmptyState icon="🧩" title={t('detail.keineBeispiele')} description={t('liste.leerSatz')} />
          ) : (
            detail.beispiele.map((b, i) => (
              <BeispielKarte key={b.task_id} nr={i + 1} beispiel={b} detail={detail} zeit={zeitVon(b.stufe)}
                markiert={hat('beispiel', b.task_id)} onKommentar={() => kommentieren('beispiel', b.task_id)} />
            ))
          )}
        </div>
        <div className="min-[980px]:sticky min-[980px]:top-4 min-[980px]:flex min-[980px]:max-h-[calc(100dvh-2rem)] min-[980px]:self-start min-[980px]:flex-col">
          <RueckmeldungSpalte
            entwurf={entwurf}
            ort={ort}
            fokus={fokus}
            aufgaben={zeile?.gruen ?? detail.instanzen}
            zeitZeile={zeitZeile}
            offen={offen}
            hinweisGesperrt={detail.status === 'rueckfrage' ? t('ansicht.inUeberarbeitung') : t('ansicht.nichtZuPruefen', { status: t(`status.${detail.status}`) })}
            busy={busy}
            rueckfrage={detail.rueckfrage ?? null}
            isAdmin={role === 'admin'}
            onSpringen={springen}
            onEntfernen={(s) => aendereEntwurf((e) => entfernen(e, s))}
            onGrund={(s, g) => aendereEntwurf((e) => grundUmschalten(e, s, g))}
            onText={(s, text) => aendereEntwurf((e) => aendern(e, s, { text }))}
            onSenden={() => void senden()}
          />
        </div>
      </div>
    </div>
  )
}
