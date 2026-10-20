import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard, EmptyState, LoadingPulse, ToastBanner } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { CardMenu } from '@/pages/admin/leads/CardMenu'
import {
  absageZuruecknehmen, ladeTermin, terminAusgefallen, terminCoachSetzen, terminRaumSetzen, type SlotsResult,
} from '@/lib/supabase/slotplan'
import { berlinLocalParts } from '@/lib/datetime'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import type { NichtDabei, TerminKind, TerminRaum } from '@/types/slotplan'
import type { StundenplanSession } from '@/types/stundenplan'
import { datumLang } from '../slotsFormat'
import { useSlotsLaden } from '../useSlotsLaden'
import { AbsageDialog, type AbsageTermin } from '../dialoge/AbsageDialog'
import { FaelltAusDialog, RaumOeffnenDialog } from '../dialoge/TerminDialoge'
import type { Panel } from '../wochenplan/wochenplan.model'
import { EinzelKurz } from './EinzelKurz'
import { KindInRaumDialog } from './KindInRaumDialog'
import { RaumKarte } from './RaumKarte'
import { Seitenpanel } from './Seitenpanel'
import { NichtDabeiKarte, OhneRaumKarte, type KindAktion } from './TerminKarten'

type Dialog =
  | { art: 'absage' | 'umbuchen'; termin: AbsageTermin }
  | { art: 'raum' | 'faelltAus' }
  | { art: 'kind'; raum: TerminRaum }
  | null

type Props = {
  datum: string
  zeitId: string
  /** Einzel-Sessions des Tages (stundenplan_woche); im Panel stehen die dieser Stunde. */
  einzel: StundenplanSession[]
  onPanel: (panel: Panel) => void
  onClose: () => void
  /** Nach jeder Änderung: der Wochenplan lädt neu. */
  onGeaendert: () => void
}

/**
 * Slot-Panel (W2, Entscheidung 6; ersetzt die Termin-Seite): alle Räume der Stunde mit Coach, Kindern, „+ Kind in …“
 * und Session öffnen / Live-Sicht; Kinder ohne Raum zuerst, darunter wer nicht dabei ist. Alle Aktionen der
 * bisherigen Termin-Seite bleiben: Coach je Raum, Raum öffnen, Absage, Umbuchen, Raum je Kind, ausgefallen,
 * Absage zurücknehmen, ganzer Termin fällt aus.
 */
export function SlotPanel({ datum, zeitId, einzel, onPanel, onClose, onGeaendert }: Props): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const termin = useSlotsLaden(() => ladeTermin(datum, zeitId), `${datum}|${zeitId}`)
  const [dialog, setDialog] = useState<Dialog>(null)
  const [meldung, setMeldung] = useState<string | null>(null)
  const [fehlerBei, setFehlerBei] = useState<{ ort: string; text: string } | null>(null)
  const d = termin.daten && termin.daten.datum === datum && termin.daten.zeit.id === zeitId ? termin.daten : null

  const fertig = (text: string): void => {
    setDialog(null)
    setMeldung(text)
    termin.neuLaden()
    onGeaendert()
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
      <Seitenpanel titel={t('termin.titelLaedt')} onClose={onClose}>
        {termin.fehler ? <p role="alert" className="text-sm text-[var(--color-text-secondary)]">{t(termin.fehler)}</p> : <LoadingPulse type="card" />}
      </Seitenpanel>
    )
  }

  const ansicht = d.vergangen
  const mitCoach = d.raeume.filter((r) => r.offen)
  const anzahl = d.raeume.reduce((n, r) => n + r.kinder.length, 0) + d.ohne_raum.length
  const inDieserStunde = einzel.filter((s) => {
    const uhr = berlinLocalParts(s.scheduled_at).time
    return uhr >= d.zeit.beginn && uhr < d.zeit.ende
  })
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

  const menu = ansicht || !d.betrieb
    ? []
    : [
        ...(d.raeume_schliessbar.length > 0 && !d.begonnen ? [{ label: t('aktion.raumOeffnen'), onSelect: () => setDialog({ art: 'raum' }) }] : []),
        ...(anzahl > 0 ? [{ label: t('aktion.faelltAus'), onSelect: () => setDialog({ art: 'faelltAus' }), danger: true }] : []),
      ]
  const stand = d.laeuft ? t('wochenplan2.slot.laeuft') : d.heute && d.begonnen ? t('wochenplan2.slot.beendet') : null

  return (
    <Seitenpanel
      rubrik={t('wochenplan2.slot.rubrik', { kw: d.kw })}
      titel={t('termin.titel', { datum: datumLang(d.datum, i18n.language), beginn: d.zeit.beginn, ende: d.zeit.ende })}
      satz={[t('wochenplan2.slot.satz', { belegt: d.belegt, plaetze: d.kapazitaet, count: mitCoach.length }), stand].filter(Boolean).join(' · ')}
      aktionen={menu.length > 0 ? <CardMenu items={menu} /> : undefined}
      escape={dialog === null}
      onClose={onClose}
    >
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
            action={!ansicht && !d.begonnen && d.raeume_schliessbar.length > 0 ? (
              <Button type="button" variant="outline" onClick={() => setDialog({ art: 'raum' })}>{t('aktion.raumOeffnen')}</Button>
            ) : undefined}
          />
        </EdvanceCard>
      ) : (
        <section className="flex flex-col gap-4" aria-label={t('termin.raeume')}>
          {d.raeume.map((r) => (
            <RaumKarte
              key={r.raum_id}
              raum={r}
              termin={d}
              ansicht={ansicht}
              fehlerBei={fehlerBei}
              onKind={onKind}
              onCoach={onCoach}
              onKindPlus={(raum) => setDialog({ art: 'kind', raum })}
            />
          ))}
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

      {inDieserStunde.length > 0 && (
        <section className="flex flex-col gap-2" aria-label={t('wochenplan2.slot.einzel')}>
          <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('wochenplan2.slot.einzel')}</h3>
          {inDieserStunde.map((s) => (
            <EinzelKurz key={s.session_id} session={s} onOeffnen={() => onPanel({ art: 'einzel', datum: d.datum, sessionId: s.session_id })} />
          ))}
        </section>
      )}

      {!ansicht && <p className="text-xs text-[var(--color-text-tertiary)]">{t('wochenplan2.slot.hinweisAbsage')}</p>}

      {dialog && (dialog.art === 'absage' || dialog.art === 'umbuchen') && (
        <AbsageDialog termin={dialog.termin} umbuchen={dialog.art === 'umbuchen'} onClose={() => setDialog(null)} onGespeichert={fertig} />
      )}
      {dialog?.art === 'kind' && <KindInRaumDialog termin={d} raum={dialog.raum} onClose={() => setDialog(null)} onGespeichert={fertig} />}
      {dialog?.art === 'raum' && <RaumOeffnenDialog termin={d} onClose={() => setDialog(null)} onGespeichert={fertig} />}
      {dialog?.art === 'faelltAus' && <FaelltAusDialog termin={d} onClose={() => setDialog(null)} onGespeichert={fertig} />}
      {meldung && <ToastBanner type="success" message={meldung} onClose={() => setMeldung(null)} />}
    </Seitenpanel>
  )
}
