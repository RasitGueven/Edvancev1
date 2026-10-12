import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { LoadingPulse, ToastBanner } from '@/components/edvance'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { Button } from '@/components/ui/button'
import { berlinToday } from '@/lib/datetime'
import { absageZuruecknehmen, ladeKind, stammplatzBeenden } from '@/lib/supabase/slotplan'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import type { KindNaechsterTermin, Stammplatz } from '@/types/slotplan'
import { datumKurz } from '../slotsFormat'
import { useSlotsLaden } from '../useSlotsLaden'
import { paketText, rhythmusText } from '../kinder/KinderSpalten'
import { AbsageDialog, type AbsageTermin } from '../dialoge/AbsageDialog'
import { StammplatzDialog } from '../dialoge/StammplatzDialog'
import { ZusatzterminDialog } from '../dialoge/ZusatzterminDialog'
import { EinheitenKarte, LetzteKarte, NaechsteKarte, StammplaetzeKarte, VertragKarte } from './KindKarten'

type Dialog =
  | { art: 'absage' | 'umbuchen'; termin: AbsageTermin }
  | { art: 'stamm'; aendern?: Stammplatz }
  | { art: 'zusatz' }
  | null

/** Kind (/admin/slots/kind/:studentId): Stammplätze, Termine, Einheiten und Planbilanz. */
export function KindPage(): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const { studentId = '' } = useParams()
  const kind = useSlotsLaden(() => ladeKind(studentId), studentId)
  const [dialog, setDialog] = useState<Dialog>(null)
  const [meldung, setMeldung] = useState<string | null>(null)
  const [fehlerBei, setFehlerBei] = useState<{ ort: string; text: string } | null>(null)
  const heute = berlinToday()
  const zurueck = '/admin/slots?reiter=kinder'
  const k = kind.daten

  const fertig = (text: string): void => {
    setDialog(null)
    setMeldung(text)
    kind.neuLaden()
  }

  if (!k) {
    return (
      <>
        <PageHeader titel={t('kind.titelLaedt')} zurueckZu={zurueck} zurueckLabel={t('kind.zurueck')} />
        {kind.fehler ? <p className="text-sm text-[var(--color-text-secondary)]">{t(kind.fehler)}</p> : <LoadingPulse type="card" />}
      </>
    )
  }

  const satz = [
    t('kind.klasse', { klasse: k.kind.klasse }),
    k.kind.fach,
    k.vertrag ? paketText(k.vertrag, t) : null,
    k.vertrag ? rhythmusText(k.vertrag.rhythmus, t) : null,
  ].filter(Boolean).join(' · ')

  const onTermin = async (x: KindNaechsterTermin, aktion: 'absage' | 'umbuchen' | 'zuruecknehmen'): Promise<void> => {
    if (aktion !== 'zuruecknehmen') {
      setDialog({ art: aktion, termin: { termin_id: x.termin_id, student_id: studentId, name: k.kind.name, datum: x.datum, beginn: x.beginn, ende: x.ende } })
      return
    }
    setFehlerBei(null)
    const res = await absageZuruecknehmen(x.termin_id)
    if (res.error !== null) return setFehlerBei({ ort: x.termin_id, text: slotsFehlerSchluessel(res) })
    fertig(t('meldung.zurueckgenommen', { name: k.kind.name }))
  }

  const onBeenden = async (s: Stammplatz, ab: string): Promise<void> => {
    setFehlerBei(null)
    const res = await stammplatzBeenden(s.id, ab)
    if (res.error !== null) return setFehlerBei({ ort: 'stamm', text: slotsFehlerSchluessel(res) })
    fertig(t('meldung.stammBeendet', { ab: datumKurz(ab, i18n.language) }))
  }

  const kannBuchen = k.zugelassen && !!k.vertrag

  return (
    <>
      <PageHeader
        rubrik={t('kind.rubrik')}
        titel={k.kind.name ?? t('kind.ohneName')}
        satz={satz}
        zurueckZu={zurueck}
        zurueckLabel={t('kind.zurueck')}
        aktionen={
          <>
            <Link to={`/admin/akten/${studentId}`} className="inline-flex min-h-[44px] items-center px-2 text-sm font-semibold text-[var(--color-text-link)] hover:underline">
              {t('kind.akte')}
            </Link>
            {kannBuchen && <Button type="button" onClick={() => setDialog({ art: 'zusatz' })}>{t('aktion.zusatzBuchen')}</Button>}
          </>
        }
      />
      {!k.zugelassen && <p className="text-sm text-[var(--color-text-secondary)]">{t('fehler.testkonto')}</p>}
      {k.weiterfuehren && k.weiterfuehren.zeilen.length > 0 && k.stammplaetze.length === 0 && (
        <p className="text-sm text-[var(--color-text-secondary)]">{t('kind.weiterfuehrenHinweis')}</p>
      )}

      <div className="@container">
        <div className="grid grid-cols-1 items-start gap-6 @slots-kind:grid-cols-[minmax(0,3fr)_minmax(0,2fr)]">
          <div className="flex min-w-0 flex-col gap-4">
            <StammplaetzeKarte
              kind={k}
              heute={heute}
              fehler={fehlerBei?.ort === 'stamm' ? fehlerBei.text : null}
              onVergeben={() => setDialog({ art: 'stamm' })}
              onAendern={(s) => setDialog({ art: 'stamm', aendern: s })}
              onBeenden={(s, ab) => void onBeenden(s, ab)}
            />
            <NaechsteKarte termine={k.naechste} fehlerBei={fehlerBei} onAktion={(x, a) => void onTermin(x, a)} />
            <LetzteKarte termine={k.letzte} />
          </div>
          <aside className="flex min-w-0 flex-col gap-4 @slots-kind:sticky @slots-kind:top-4">
            <EinheitenKarte kind={k} />
            <VertragKarte kind={k} />
          </aside>
        </div>
      </div>

      {dialog && (dialog.art === 'absage' || dialog.art === 'umbuchen') && (
        <AbsageDialog termin={dialog.termin} umbuchen={dialog.art === 'umbuchen'} onClose={() => setDialog(null)} onGespeichert={fertig} />
      )}
      {dialog?.art === 'zusatz' && (
        <ZusatzterminDialog kind={{ student_id: studentId, name: k.kind.name }} onClose={() => setDialog(null)} onGespeichert={fertig} />
      )}
      {dialog?.art === 'stamm' && k.vertrag && (
        <StammplatzDialog
          kind={{ student_id: studentId, name: k.kind.name, beginn: k.vertrag.beginn, vertrag_laeuft: !!k.vertrag_laeuft, rhythmus: k.vertrag.rhythmus }}
          aendern={dialog.aendern}
          onClose={() => setDialog(null)}
          onGespeichert={fertig}
        />
      )}
      {meldung && <ToastBanner type="success" message={meldung} onClose={() => setMeldung(null)} />}
    </>
  )
}
