import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { AdminHeader, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { berlinToday } from '@/lib/datetime'
import { listTiers } from '@/lib/supabase/subscriptions'
import { listVertraege, vertragAblehnen } from '@/lib/supabase/vertraege'
import {
  listVertraegeAktuell,
  vertragVerlaengerungSetzen,
  vertragZahlungsstatusSetzen,
} from '@/lib/supabase/vertraegeMenue'
import { auslaufende, imVerzug, naechsteStufe, LEERER_FILTER, type UebersichtFilter } from '@/lib/vertrag/menue'
import type {
  RejectionReason,
  TierPlan,
  VerlaengerungStatus,
  VertragAktuell,
  VertragMitLead,
} from '@/types'
import { RejectModal } from './leads/RejectModal'
import { EingabeDialog, type DialogFeld } from './vertraege/menue/EingabeDialog'
import { ReiterAntraege } from './vertraege/menue/ReiterAntraege'
import { ReiterAuslaufend } from './vertraege/menue/ReiterAuslaufend'
import { ReiterUebersicht } from './vertraege/menue/ReiterUebersicht'
import { ReiterVerzug } from './vertraege/menue/ReiterVerzug'
import { Reiterleiste, type ReiterKey } from './vertraege/menue/Reiterleiste'
import { kindName } from './vertraege/vertragModel'

/** Eine offene Rueckfrage: ein Feld, ein Knopf, eine Wirkung. */
type Frage =
  | { art: 'keine_verlaengerung'; vertrag: VertragAktuell }
  | { art: 'naechste_stufe'; vertrag: VertragAktuell }

const ANTRAG_STATUS = ['in_vorbereitung', 'unterschrift_ausstehend', 'abgelehnt']

/**
 * Das Menue "Vertraege" (/admin/vertraege): vier Reiter auf einer Seite.
 *
 * Alles Angezeigte kommt aus der Sicht vertraege_aktuell und den RPCs aus P3a.
 * Hier wird kein Status abgeleitet, kein Datum gerechnet und keine Summe
 * erfunden — die Seite zeigt, was die Datenbank liefert.
 */
export function VertraegeMenuePage(): JSX.Element {
  const { t } = useTranslation('vertraege')
  const navigate = useNavigate()
  const [reiter, setReiter] = useState<ReiterKey>('uebersicht')
  const [vertraege, setVertraege] = useState<VertragAktuell[]>([])
  const [antraege, setAntraege] = useState<VertragMitLead[]>([])
  const [tiers, setTiers] = useState<TierPlan[]>([])
  const [filter, setFilter] = useState<UebersichtFilter>(LEERER_FILTER)
  const [zeigeAbgelehnte, setZeigeAbgelehnte] = useState(false)
  const [loading, setLoading] = useState(true)
  const [busyId, setBusyId] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [frage, setFrage] = useState<Frage | null>(null)
  const [ablehnen, setAblehnen] = useState<VertragMitLead | null>(null)

  const laden = (): void => {
    void Promise.all([listVertraegeAktuell(), listVertraege(), listTiers()]).then(
      ([v, a, ti]) => {
        setVertraege(v.data ?? [])
        setAntraege((a.data ?? []).filter((x) => ANTRAG_STATUS.includes(x.status)))
        setTiers(ti.data ?? [])
        setError(v.error ?? a.error ?? ti.error)
        setLoading(false)
      },
    )
  }

  useEffect(laden, [])

  const run = async (
    id: string,
    aktion: () => Promise<{ error: string | null }>,
  ): Promise<boolean> => {
    if (busyId) return false
    setBusyId(id)
    setError(null)
    const { error: err } = await aktion()
    setBusyId(null)
    if (err) setError(err)
    laden()
    return err === null
  }

  const setzeVerlaengerung = (v: VertragAktuell, status: VerlaengerungStatus): void => {
    // Der Grund ist Pflicht — die RPC wuerde ihn ohnehin verlangen, aber der
    // Dialog fragt danach, bevor der Fehler kommt.
    if (status === 'keine_verlaengerung') {
      setFrage({ art: 'keine_verlaengerung', vertrag: v })
      return
    }
    void run(v.id, () =>
      vertragVerlaengerungSetzen(
        v.id,
        status as Exclude<VerlaengerungStatus, 'verlaengert'>,
        null,
        v.wiedervorlage_am,
      ),
    )
  }

  const beantworte = async (wert: string): Promise<void> => {
    if (!frage) return
    const v = frage.vertrag
    if (frage.art === 'keine_verlaengerung') {
      if (await run(v.id, () =>
        vertragVerlaengerungSetzen(v.id, 'keine_verlaengerung', wert, v.wiedervorlage_am),
      )) {
        setFrage(null)
      }
      return
    }
    const stufe = naechsteStufe(v.zahlungsstatus)
    if (!stufe) return
    // Eingabe in Euro, gespeichert wird in Cent.
    const cents = Math.round(Number(wert.replace(',', '.')) * 100)
    if (await run(v.id, () =>
      vertragZahlungsstatusSetzen(v.id, stufe, Number.isFinite(cents) ? cents : null),
    )) {
      setFrage(null)
    }
  }

  const reiterListe = [
    { key: 'antraege' as const, titel: t('menue.reiter.antraege'), anzahl: antraege.filter((a) => a.status !== 'abgelehnt').length },
    { key: 'uebersicht' as const, titel: t('menue.reiter.uebersicht'), anzahl: vertraege.filter((v) => v.ist_aktueller_vertrag).length },
    { key: 'auslaufend' as const, titel: t('menue.reiter.auslaufend'), anzahl: auslaufende(vertraege).length },
    { key: 'verzug' as const, titel: t('menue.reiter.verzug'), anzahl: imVerzug(vertraege).length },
  ]

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <EdvanceNavbar subtitle={t('page.subtitle')} sticky />
      <main className="mx-auto flex max-w-6xl flex-col gap-6 px-4 py-8">
        <AdminHeader
          eyebrow={t('page.eyebrow')}
          title={t('page.title')}
          description={t('menue.beschreibung')}
        />

        <Reiterleiste reiter={reiterListe} aktiv={reiter} onWechsel={setReiter} />

        {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}

        {loading ? (
          <LoadingPulse type="list" lines={4} />
        ) : reiter === 'antraege' ? (
          <ReiterAntraege
            antraege={antraege}
            tiers={tiers}
            zeigeAbgelehnte={zeigeAbgelehnte}
            onZeigeAbgelehnte={setZeigeAbgelehnte}
            heute={berlinToday()}
            onFortsetzen={(v) => navigate(`/admin/vertraege/${v.id}`)}
            onAblehnen={setAblehnen}
          />
        ) : reiter === 'uebersicht' ? (
          <ReiterUebersicht
            vertraege={vertraege}
            tiers={tiers}
            filter={filter}
            onFilter={(next) => setFilter((f) => ({ ...f, ...next }))}
            onZeile={(v) => navigate(`/admin/vertraege/${v.id}/detail`)}
          />
        ) : reiter === 'auslaufend' ? (
          <ReiterAuslaufend
            vertraege={vertraege}
            tiers={tiers}
            busyId={busyId}
            onStatus={setzeVerlaengerung}
            onWiedervorlage={(v, datum) =>
              void run(v.id, () =>
                vertragVerlaengerungSetzen(
                  v.id,
                  (v.verlaengerung_status ?? 'offen') as Exclude<VerlaengerungStatus, 'verlaengert'>,
                  v.verlaengerung_grund,
                  datum === '' ? null : datum,
                ),
              )
            }
            neuerVertragSperre={t('menue.neuerVertragFolgt')}
          />
        ) : (
          <ReiterVerzug
            vertraege={vertraege}
            busyId={busyId}
            onNaechsteStufe={(v) => setFrage({ art: 'naechste_stufe', vertrag: v })}
            onBezahlt={(v) => void run(v.id, () => vertragZahlungsstatusSetzen(v.id, 'in_ordnung'))}
          />
        )}
      </main>

      <EingabeDialog
        key={frage ? `${frage.art}-${frage.vertrag.id}` : 'zu'}
        offen={frage !== null}
        titel={frage?.art === 'naechste_stufe' ? t('menue.dialog.stufeTitel') : t('menue.dialog.grundTitel')}
        beschreibung={
          frage?.art === 'naechste_stufe' ? t('menue.dialog.stufeHinweis') : t('menue.dialog.grundHinweis')
        }
        feld={(frage?.art === 'naechste_stufe' ? 'betrag' : 'grund') as DialogFeld}
        label={frage?.art === 'naechste_stufe' ? t('menue.dialog.betragLabel') : t('menue.dialog.grundLabel')}
        pflicht={frage?.art === 'keine_verlaengerung'}
        bestaetigen={t('menue.dialog.bestaetigen')}
        saving={busyId !== null}
        onAbbruch={() => setFrage(null)}
        onBestaetigen={(wert) => void beantworte(wert)}
      />

      <RejectModal
        key={ablehnen?.id ?? 'keiner'}
        name={ablehnen ? kindName(ablehnen) : null}
        saving={busyId !== null}
        onClose={() => setAblehnen(null)}
        onConfirm={(grund: RejectionReason, notiz) => {
          if (!ablehnen) return
          void run(ablehnen.id, () => vertragAblehnen(ablehnen.id, grund, notiz)).then((ok) => {
            if (ok) setAblehnen(null)
          })
        }}
      />
    </div>
  )
}
