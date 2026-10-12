import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard, EmptyState, LoadingPulse, ToastBanner } from '@/components/edvance'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { Button } from '@/components/ui/button'
import { montagVon } from '@/components/edvance/wochenNavigation.model'
import { CardMenu } from '@/pages/admin/leads/CardMenu'
import {
  absageZuruecknehmen, ladeTermin, terminAusgefallen, terminCoachSetzen, terminRaumSetzen, terminSessionAnlegen, type SlotsResult,
} from '@/lib/supabase/slotplan'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import type { NichtDabei, TerminKind, TerminRaum } from '@/types/slotplan'
import { datumLang } from '../slotsFormat'
import { useSlotsLaden } from '../useSlotsLaden'
import { AbsageDialog, type AbsageTermin } from '../dialoge/AbsageDialog'
import { FaelltAusDialog, KindHinzufuegenDialog, RaumOeffnenDialog } from '../dialoge/TerminDialoge'
import { NichtDabeiKarte, OhneRaumKarte, RaumKarte, type KindAktion } from './TerminKarten'

type Dialog = { art: 'absage' | 'umbuchen'; termin: AbsageTermin } | { art: 'hinzufuegen' | 'raum' | 'faelltAus' } | null

/** Termin (/admin/slots/termin/:datum/:zeitId): Räume, Kinder ohne Raum, wer nicht dabei ist. */
export function TerminPage(): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const { datum = '', zeitId = '' } = useParams()
  const termin = useSlotsLaden(() => ladeTermin(datum, zeitId), `${datum}|${zeitId}`)
  const [dialog, setDialog] = useState<Dialog>(null)
  const [meldung, setMeldung] = useState<string | null>(null)
  const [fehlerBei, setFehlerBei] = useState<{ ort: string; text: string } | null>(null)
  const zurueck = `/admin/slots?woche=${montagVon(datum)}`
  const d = termin.daten

  const fertig = (text: string): void => {
    setDialog(null)
    setMeldung(text)
    termin.neuLaden()
  }
  /** Eine Aktion ohne Dialog: Fehler erscheint an der Stelle, an der sie entsteht. */
  const aktion = async (ort: string, aufruf: Promise<SlotsResult<unknown>>, erfolg: string): Promise<void> => {
    setFehlerBei(null)
    const res = await aufruf
    if (res.error !== null) return setFehlerBei({ ort, text: slotsFehlerSchluessel(res) })
    fertig(erfolg)
  }

  if (!d) {
    return (
      <>
        <PageHeader titel={t('termin.titelLaedt')} zurueckZu={zurueck} zurueckLabel={t('termin.zurueck')} />
        {termin.fehler ? <p className="text-sm text-[var(--color-text-secondary)]">{t(termin.fehler)}</p> : <LoadingPulse type="card" />}
      </>
    )
  }

  const ansicht = d.vergangen
  const offen = d.raeume.filter((r) => r.offen)
  const anzahl = d.raeume.reduce((n, r) => n + r.kinder.length, 0) + d.ohne_raum.length
  const absageTermin = (k: TerminKind | NichtDabei): AbsageTermin => ({
    termin_id: k.termin_id, student_id: k.student_id, name: k.name, datum: d.datum, beginn: d.zeit.beginn, ende: d.zeit.ende,
  })

  const onKind = (k: TerminKind, a: KindAktion): void => {
    if (a === 'absage' || a === 'umbuchen') return setDialog({ art: a, termin: absageTermin(k) })
    if (a === 'ausgefallen') {
      void aktion(k.termin_id, terminAusgefallen(k.termin_id), t('meldung.ausgefallen', { name: k.name }))
      return
    }
    const ziel = d.raeume.find((r) => r.raum_id === a.raum)
    void aktion(k.termin_id, terminRaumSetzen(k.termin_id, a.raum), t('meldung.verschoben', { name: k.name, raum: ziel?.name }))
  }
  const onCoach = (raum: TerminRaum, coachId: string | null): void => {
    const name = d.coaches.find((c) => c.id === coachId)?.name
    void aktion(
      raum.raum_id,
      terminCoachSetzen(d.datum, d.zeit.id, raum.raum_id, coachId),
      coachId ? t('meldung.coach', { coach: name, raum: raum.name }) : t('meldung.coachFaelltAus', { raum: raum.name }),
    )
  }
  const onSession = (raum: TerminRaum): void => {
    void aktion(raum.raum_id, terminSessionAnlegen(d.datum, d.zeit.id, raum.raum_id), t('meldung.sessionOffen', { raum: raum.name }))
  }

  const menu = ansicht
    ? []
    : [
        ...(d.raeume_schliessbar.length > 0 ? [{ label: t('aktion.raumOeffnen'), onSelect: () => setDialog({ art: 'raum' }) }] : []),
        ...(anzahl > 0 ? [{ label: t('aktion.faelltAus'), onSelect: () => setDialog({ art: 'faelltAus' }), danger: true }] : []),
      ]

  return (
    <>
      <PageHeader
        rubrik={t('termin.rubrik', { kw: d.kw })}
        titel={t('termin.titel', { datum: datumLang(d.datum, i18n.language), beginn: d.zeit.beginn, ende: d.zeit.ende })}
        satz={t('termin.satz', { kinder: d.belegt, plaetze: d.kapazitaet, offen: offen.length, raeume: d.raeume.length })}
        zurueckZu={zurueck}
        zurueckLabel={t('termin.zurueck')}
        aktionen={
          ansicht || !d.betrieb ? undefined : (
            <>
              <Button type="button" onClick={() => setDialog({ art: 'hinzufuegen' })}>{t('aktion.kindHinzufuegen')}</Button>
              <CardMenu items={menu} />
            </>
          )
        }
      />

      {!d.betrieb && <p className="text-sm text-[var(--color-text-secondary)]">{t('termin.keinBetrieb', { anlass: d.anlass ?? '' })}</p>}
      {ansicht && (
        <p className="flex flex-wrap items-center gap-2 text-sm text-[var(--color-text-secondary)]">
          {t('termin.ansicht')}
          {d.anwesenheit_fehlt && <EdvanceBadge variant="warning">{t('termin.anwesenheitOffen')}</EdvanceBadge>}
        </p>
      )}
      {termin.fehler && <p role="alert" className="text-sm text-[var(--color-error-coach)]">{t(termin.fehler)}</p>}

      {d.ohne_raum.length > 0 && <OhneRaumKarte termin={d} ansicht={ansicht} fehlerBei={fehlerBei} onKind={onKind} />}

      {d.raeume.length === 0 ? (
        <EdvanceCard>
          <EmptyState
            icon="🚪"
            title={t('termin.keineRaeumeTitel')}
            description={t('termin.keineRaeumeText')}
            action={!ansicht && d.raeume_schliessbar.length > 0 ? (
              <Button type="button" variant="outline" onClick={() => setDialog({ art: 'raum' })}>{t('aktion.raumOeffnen')}</Button>
            ) : undefined}
          />
        </EdvanceCard>
      ) : (
        <section className="@container flex flex-col gap-2" aria-label={t('termin.raeume')}>
          <div className="grid grid-cols-1 items-start gap-4 @slots-raeume:grid-cols-2">
            {d.raeume.map((r) => (
              <RaumKarte
                key={r.raum_id}
                raum={r}
                termin={d}
                ansicht={ansicht}
                fehlerBei={fehlerBei}
                onKind={onKind}
                onCoach={onCoach}
                onSessionOeffnen={onSession}
              />
            ))}
          </div>
          {!ansicht && <p className="text-xs text-[var(--color-text-tertiary)]">{t(d.heute ? 'termin.hinweisFestschreiben' : 'termin.hinweisZuteilung')}</p>}
        </section>
      )}

      {d.nicht_dabei.length > 0 && (
        <NichtDabeiKarte
          liste={d.nicht_dabei}
          ansicht={ansicht}
          fehlerBei={fehlerBei}
          onZuruecknehmen={(k) => void aktion(k.termin_id, absageZuruecknehmen(k.termin_id), t('meldung.zurueckgenommen', { name: k.name }))}
        />
      )}

      {dialog && (dialog.art === 'absage' || dialog.art === 'umbuchen') && (
        <AbsageDialog termin={dialog.termin} umbuchen={dialog.art === 'umbuchen'} onClose={() => setDialog(null)} onGespeichert={fertig} />
      )}
      {dialog?.art === 'hinzufuegen' && <KindHinzufuegenDialog termin={d} onClose={() => setDialog(null)} onGespeichert={fertig} />}
      {dialog?.art === 'raum' && <RaumOeffnenDialog termin={d} onClose={() => setDialog(null)} onGespeichert={fertig} />}
      {dialog?.art === 'faelltAus' && <FaelltAusDialog termin={d} onClose={() => setDialog(null)} onGespeichert={fertig} />}
      {meldung && <ToastBanner type="success" message={meldung} onClose={() => setMeldung(null)} />}
    </>
  )
}
