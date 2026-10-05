// /admin/pruefen/:taskId — die Admin-Pruefansicht (Bauauftrag A 1, B 3 bis C 16). Eine Fokusseite ohne Leiste:
// links Lenas Kinderansicht, rechts „Vor der Freigabe klären“, „Lenas Ergebnis“ und dieselbe Pruefkarte wie bei
// Lena (Bausteine aus components/edvance/pruefen), darunter der Verlauf; unten die Admin-Leiste. Die Reihe kommt
// aus dem sessionStorage (lib/pruefung/reihe); ein direkter Link ohne Reihe oeffnet die einzelne Aufgabe.

import { useCallback, useMemo, useState, type JSX } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { Button } from '@/components/ui'
import { Kinderansicht } from '@/components/edvance/pruefen/Kinderansicht'
import { RichtigeAntwort } from '@/components/edvance/pruefen/RichtigeAntwort'
import { AntwortTesten, Loesungsweg, RegelBlock } from '@/components/edvance/pruefen/RegelUndTesten'
import { TypischeFehler } from '@/components/edvance/pruefen/TypischeFehler'
import { AenderungenBox, Einordnung } from '@/components/edvance/pruefen/Einordnung'
import { Auffaelligkeiten, EntscheidungsMeldung } from '@/components/edvance/pruefen/Entscheidungsleiste'
import { formatBerlinDateTime } from '@/lib/datetime'
import { adminFehler, uebersetze } from '@/lib/pruefung/adminTexte'
import { editorZiel, type EditorAbschnitt } from '@/lib/pruefung/befunde'
import { feldZuruecksetzen, geaenderteFelder, lokaleAenderungen, type Feld } from '@/lib/pruefung/entwurf'
import { herkunftVon } from '@/lib/pruefung/herkunft'
import { leistenInfo, leistenKnoepfe } from '@/lib/pruefung/leiste'
import {
  leseReihe, OHNE_REIHE_ZURUECK, position, reiheFuer, vorige, type Reihe,
} from '@/lib/pruefung/reihe'
import { setzePilot } from '@/lib/supabase/pruefungAdmin'
import { AdminKopf } from './AdminKopf'
import { AdminLeiste, type LeistenPanel } from './AdminLeiste'
import { EditorLink, Verlauf, VorFreigabeKlaeren } from './KarteZusatz'
import { LenasErgebnis } from './LenasErgebnis'
import { useAdminAktionen } from './useAdminAktionen'
import { useAdminPruefung } from './useAdminPruefung'
import { useAdminTasten } from './useAdminTasten'

/** Diese Ausschluesse bearbeitet auch ein Admin nur im Editor (pruef_sperren). */
const NUR_EDITOR = ['vera8', 'inaktiv', 'typ']

export function AdminPruefansichtPage(): JSX.Element {
  const { taskId } = useParams<{ taskId: string }>()
  const navigate = useNavigate()
  const { t, i18n } = useTranslation('pruefenAdmin')
  const p = useAdminPruefung(taskId)
  const { s, kontext, befunde } = p
  const [reihe, setReihe] = useState<Reihe | null>(() => leseReihe())
  const [panel, setPanel] = useState<LeistenPanel>(null)
  const [antwort, setAntwort] = useState('')
  const [pilotArbeitet, setPilotArbeitet] = useState(false)
  // Neue Aufgabe: Felder ueber der Leiste schliessen (Zustand an der Aufgabe, nicht im Effekt).
  const [fuer, setFuer] = useState(taskId)
  if (fuer !== taskId) {
    setFuer(taskId)
    setPanel(null)
    setAntwort('')
  }

  const aufraeumen = useCallback(() => {
    setPanel(null)
    setAntwort('')
  }, [])
  const x = useAdminAktionen({ taskId, p, reihe: reiheFuer(reihe, taskId), setReihe, antwort, aufraeumen })

  const a = s.aufgabe
  const meineReihe = reiheFuer(reihe, taskId)
  const pos = meineReihe && taskId ? position(meineReihe, taskId) : null
  const ausschluss = a?.aufgabe.ausschluss ?? null
  const status = a?.aufgabe.status ?? ''
  const lesend = !a || status === 'ready' || NUR_EDITOR.includes(ausschluss ?? '') || s.konflikt
  const felder = useMemo(() => (s.b && s.ausgang ? geaenderteFelder(s.ausgang, s.b) : new Set<Feld>()), [s.b, s.ausgang])
  const aenderungen = useMemo(() => (s.b && s.ausgang ? lokaleAenderungen(s.ausgang, s.b) : []), [s.b, s.ausgang])
  const fehlbildName = useCallback((slug: string) => p.fehlbilder.find((f) => f.slug === slug)?.klartext ?? slug, [p.fehlbilder])
  const namen = useMemo(() => ({
    fehlbild: fehlbildName,
    fertigkeit: (k: string) => a?.fertigkeit_optionen.find((o) => o.key === k)?.label ?? k,
    option: (id: string) => {
      const o = a?.aufgabe.optionen.find((y) => y.id === id)
      return o ? `${id}) ${o.label}` : id
    },
  }), [a, fehlbildName])
  const lenaAenderungen = kontext?.lena?.entscheidung === 'zurueckgenommen' ? [] : kontext?.lena?.aenderungen ?? []

  const ersterBefund = befunde.sperrend[0] ? t(befunde.sperrend[0].key, befunde.sperrend[0].vars) : null
  const freigebenGesperrt = ersterBefund ?? (p.befundeGeladen ? null : t('pruefen:ansicht.speichert'))
  const lage = { status, ausgeschlossen: !!ausschluss, team: !!a?.aufgabe.team_beanstandet }
  const infoKey = leistenInfo({ ...lage, lenaStatus: a?.aufgabe.lena_status ?? '', geaendert: aenderungen.length, befund: ersterBefund })

  const geheZu = (id: string): void => navigate(`/admin/pruefen/${id}`)
  const schliessen = (): void => {
    void s.sichern().then(() => navigate(meineReihe?.zurueck ?? OHNE_REIHE_ZURUECK))
  }
  const zurueck = (): void => {
    const v = meineReihe && taskId ? vorige(meineReihe, taskId) : null
    if (v) void s.sichern().then((ok) => ok && geheZu(v))
  }
  const ueberspringen = (): void => {
    if (!taskId) return
    void s.sichern().then((ok) => {
      if (ok) x.weiter(taskId, 'uebersprungen')
    })
  }
  const editor = (abschnitt?: EditorAbschnitt): void => {
    if (!taskId) return
    // Vor dem Wechsel speichern; scheitert das, bleibt die Pruefansicht offen und zeigt den Fehler.
    void s.sichern().then((ok) => ok && navigate(editorZiel(taskId, abschnitt)))
  }
  const pilot = async (an: boolean): Promise<void> => {
    if (!taskId || !(await s.sichern())) return
    setPilotArbeitet(true)
    const res = await setzePilot(taskId, an)
    setPilotArbeitet(false)
    if (res.error) return x.zeigeFehler(res.error)
    x.setMeldung({ text: t(an ? 'kopf.pilotAn' : 'kopf.pilotAus') })
    // Die Pilotmarke erhoeht pruef_version: neu laden, sonst scheitert das naechste Speichern mit ED409.
    p.neuLaden()
  }
  const zuruecksetzen = (feld: Feld): void => {
    if (s.b && s.ausgang) s.aendern(feldZuruecksetzen(s.b, s.ausgang, feld))
  }
  const knoepfe = leistenKnoepfe(lage)

  useAdminTasten({
    aktiv: !!a,
    panelOffen: panel !== null,
    freigeben: () => {
      if (knoepfe.primaer === 'freigeben' && !freigebenGesperrt) void x.entscheide('freigeben')
    },
    zurueck,
    weiter: ueberspringen,
    editor: () => editor(),
    panelZu: () => setPanel(null),
    schliessen,
  })

  const link = (ziel: EditorAbschnitt): JSX.Element => <EditorLink ziel={ziel} onEditor={editor} />
  const freigabe = kontext?.freigabe
  const sitzungsFehler = s.fehler && !s.konflikt ? adminFehler(s.fehler) : null

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <main className="mx-auto flex max-w-6xl flex-col gap-6 px-4 pb-72 pt-6">
        {s.laedt && <LoadingPulse type="card" />}
        {!s.laedt && !a && (
          <EmptyState icon="🔎" title={t('ansicht.ladeFehler')} description={uebersetze(t, adminFehler(s.ladeFehler) ?? { key: 'pruefen:fehlermeldung.allgemein' })}
            action={<Button onClick={() => navigate(meineReihe?.zurueck ?? OHNE_REIHE_ZURUECK)}>{t('ansicht.zurListe')}</Button>} />
        )}
        {a && s.b && s.ausgang && (
          <>
            <AdminKopf aufgabe={a} reihe={pos && meineReihe ? { label: meineReihe.label, ...pos } : null}
              hatVorige={!!(meineReihe && taskId && vorige(meineReihe, taskId))}
              pilot={{ an: a.aufgabe.pilot, sichtbar: !ausschluss && status !== 'ready', arbeitet: pilotArbeitet }}
              onZurueck={zurueck} onUeberspringen={ueberspringen} onEditor={() => editor()} onSchliessen={schliessen}
              onPilot={(an) => void pilot(an)} />
            {s.konflikt && (
              <EdvanceCard className="flex flex-wrap items-center justify-between gap-4 border-[var(--color-warning)] bg-[var(--color-warning-light)]">
                <p className="text-sm font-semibold text-[var(--color-warning)]">{t('pruefen:ansicht.konflikt')}</p>
                <Button onClick={p.neuLaden}>{t('pruefen:ansicht.neuLaden')}</Button>
              </EdvanceCard>
            )}
            <div className="grid items-start gap-6 lg:grid-cols-[minmax(0,0.92fr)_minmax(0,1.08fr)]">
              <Kinderansicht aufgabe={a} />
              <div className="flex min-w-0 flex-col gap-6">
                <VorFreigabeKlaeren sperrend={befunde.sperrend} hinweise={befunde.hinweise} onEditor={editor} />
                <LenasErgebnis aufgabe={a} kontext={kontext} namen={namen} />
                <EdvanceCard className="flex flex-col gap-6">
                  {status === 'ready' && (
                    <p role="status" className="rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] p-3 text-sm text-[var(--color-text-secondary)]">
                      {t('karte.freigegeben', {
                        am: freigabe ? formatBerlinDateTime(freigabe.am, i18n.language) : '—', wer: freigabe?.von ?? '—',
                      })}
                    </p>
                  )}
                  {status !== 'ready' && NUR_EDITOR.includes(ausschluss ?? '') && (
                    <p role="status" className="rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] p-3 text-sm text-[var(--color-text-secondary)]">
                      {t('karte.nichtBearbeitbar', { grund: t(`authoring:lena.ausschluss.${ausschluss}`) })}
                    </p>
                  )}
                  <Auffaelligkeiten aufgabe={a} liste={s.auffaelligkeiten} />
                  <section className="flex flex-col gap-4">
                    <RichtigeAntwort aufgabe={a} b={s.b} geaendert={felder.has('antwort')} lesend={lesend}
                      onChange={s.aendern} onZurueck={() => zuruecksetzen('antwort')} kopfAktion={link('antwort')} />
                    <RegelBlock aufgabe={a} b={s.b} geaendert={felder.has('regel')} lesend={lesend}
                      onChange={s.aendern} onZurueck={() => zuruecksetzen('regel')} />
                    <AntwortTesten aufgabe={a} b={s.b} />
                    <Loesungsweg text={a.loesungsweg} />
                  </section>
                  <TypischeFehler aufgabe={a} b={s.b} fehlbilder={p.fehlbilder} geaendert={felder.has('fehler')} lesend={lesend}
                    onChange={s.aendern} onZurueck={() => zuruecksetzen('fehler')} kopfAktion={link('antwort')} />
                  <Einordnung aufgabe={a} b={s.b} ausgang={s.ausgang} fertigkeitGeaendert={felder.has('fertigkeit')}
                    afbGeaendert={felder.has('afb')} lesend={lesend} onChange={s.aendern} onZurueck={zuruecksetzen}
                    kopfAktion={link('einordnung')} />
                  <AenderungenBox aenderungen={aenderungen} namen={namen} mc={a.aufgabe.input_type === 'MC'}
                    grund="" grundPflicht={false} onGrund={() => undefined}
                    herkunft={(e) => herkunftVon(e, lenaAenderungen)} kopfAktion={link('antwort')} />
                  <p className="text-xs text-[var(--color-text-tertiary)]" aria-live="polite">
                    {t(s.speichert ? 'pruefen:ansicht.speichert' : 'pruefen:ansicht.gespeichert')}
                  </p>
                </EdvanceCard>
                <Verlauf zeilen={kontext?.protokoll ?? []} namen={namen} mc={a.aufgabe.input_type === 'MC'} />
              </div>
            </div>
          </>
        )}
      </main>
      {a && s.b && (
        <AdminLeiste key={taskId} knoepfe={knoepfe}
          info={{ text: t(`leiste.info.${infoKey}`, { befund: ersterBefund ?? '', count: aenderungen.length }), warnung: infoKey === 'befund' }}
          freigebenGesperrt={freigebenGesperrt} rueckfrage={status === 'rueckfrage'} antwort={antwort} setAntwort={setAntwort}
          nachrichtGesperrt={kontext && !kontext.lena ? t('leiste.nachrichtGesperrt') : null}
          ausschluss={ausschluss ? t(`authoring:lena.ausschluss.${ausschluss}`) : null}
          panel={panel} setPanel={setPanel} arbeitet={x.arbeitet}
          fehler={x.fehler ?? (sitzungsFehler ? uebersetze(t, sitzungsFehler) : null)}
          onAktion={(akt, eingabe) => (akt === 'editor' ? editor() : void x.entscheide(akt, eingabe))} />
      )}
      {x.meldung && (
        <EntscheidungsMeldung text={x.meldung.text} onRueckgaengig={x.meldung.oeffnen} aktionLabel={t('meldung.oeffnen')}
          onZu={() => x.setMeldung(null)} />
      )}
    </div>
  )
}

