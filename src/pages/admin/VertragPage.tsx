import { useCallback, useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { AdminHeader, EdvanceBadge, EdvanceCard, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { Button } from '@/components/ui/button'
import { berlinToday } from '@/lib/datetime'
import { listSchulen, type Schule } from '@/lib/supabase/schulen'
import { listTiers } from '@/lib/supabase/subscriptions'
import { berechneVertragsende, type VertragEnde } from '@/lib/supabase/vertragEnde'
import {
  getGlaeubigerId,
  getIban,
  getVertrag,
  getVertragNachweise,
  listVertragDokumente,
  saveIban,
  updateVertrag,
  vertragAblehnen,
  vertragAbschliessen,
  vertragVersandProtokollieren,
  vertragVersenden,
  type VertragNachweise,
} from '@/lib/supabase/vertraege'
import { beginnAuswahl } from '@/lib/vertrag/beginnOptionen'
import { isValidIban, normalizeIban } from '@/lib/vertrag/iban'
import type { RejectionReason, TierPlan, VertragDokument, VertragMitLead } from '@/types'
import { RejectModal } from './leads/RejectModal'
import { EinpflegenPanel } from './vertraege/EinpflegenPanel'
import { NachAbschluss } from './vertraege/NachAbschluss'
import { Schritt2Dokument } from './vertraege/Schritt2Dokument'
import { Schritt3Weg, type AbschlussWahl } from './vertraege/Schritt3Weg'
import { Schritt4VorOrt } from './vertraege/Schritt4VorOrt'
import { Schritt4Versand } from './vertraege/Schritt4Versand'
import { VertragForm } from './vertraege/VertragForm'
import { WizardKopf, type WizardSchritt } from './vertraege/WizardKopf'
import { ZugangscodeKarte } from './vertraege/ZugangscodeKarte'
import { isDirty, toFormState, toPatch, type VertragFormState } from './vertraege/vertragForm'
import { fehlendeAngaben, kindName } from './vertraege/vertragModel'
import { STATUS_BADGE, openUnterlagen } from './vertraege/vertragUi'

type Stammdaten = {
  tiers: TierPlan[]
  dokumente: VertragDokument[]
  glaeubigerId: string | null
  schulen: Schule[]
}

const LEER: Stammdaten = { tiers: [], dokumente: [], glaeubigerId: null, schulen: [] }

/**
 * Die Abschlussstrecke (/admin/vertraege/:id).
 *
 * Vier Schritte, die einer Reihenfolge folgen: Daten, Dokument, Weg, Abschluss.
 * Der Weg steht VOR den Bedingungen, weil erst er entscheidet, ob der
 * Elternteil hier abhakt oder auf dem Ausdruck (Anforderung C.9).
 *
 * Kommt der Vertrag auf Papier zurueck, ist die Strecke vorbei und es beginnt
 * das Einpflegen — derselbe Abschluss, andere Nachweise.
 */
export function VertragPage(): JSX.Element {
  const { id = '' } = useParams<{ id: string }>()
  const { t } = useTranslation('vertraege')
  const { t: tl } = useTranslation('leads')
  const [vertrag, setVertrag] = useState<VertragMitLead | null>(null)
  const [form, setForm] = useState<VertragFormState | null>(null)
  const [iban, setIban] = useState<string | null>(null)
  const [stamm, setStamm] = useState<Stammdaten>(LEER)
  const [nachweise, setNachweise] = useState<VertragNachweise | null>(null)
  const [ende, setEnde] = useState<VertragEnde | null>(null)
  const [endeFehler, setEndeFehler] = useState<string | null>(null)
  const [schritt, setSchritt] = useState<WizardSchritt>(1)
  const [wahl, setWahl] = useState<AbschlussWahl | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)
  const [rejecting, setRejecting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const load = useCallback(async (): Promise<void> => {
    const [v, i, n] = await Promise.all([getVertrag(id), getIban(id), getVertragNachweise(id)])
    if (v.data) {
      setVertrag(v.data)
      setForm(toFormState(v.data))
    }
    setIban(i.data ?? null)
    setNachweise(n.data)
    setError(v.error ?? i.error ?? n.error)
  }, [id])

  useEffect(() => {
    void (async () => {
      const [tiers, dokumente, glaeubiger, schulen] = await Promise.all([
        listTiers(),
        listVertragDokumente(),
        getGlaeubigerId(),
        listSchulen(),
        load(),
      ])
      setStamm({
        tiers: tiers.data ?? [],
        dokumente: dokumente.data ?? [],
        glaeubigerId: glaeubiger.data ?? null,
        schulen: schulen.data ?? [],
      })
      setError((e) => e ?? tiers.error ?? dokumente.error ?? glaeubiger.error ?? schulen.error)
      setLoading(false)
    })()
  }, [load])

  // Vorschau des Vertragsendes — aus der Datenbank, nicht aus dem Frontend.
  const beginn = form?.vertragsbeginn ?? ''
  const laufzeit = form?.laufzeit_monate ?? ''
  useEffect(() => {
    if (beginn === '' || laufzeit === '') {
      setEnde(null)
      setEndeFehler(null)
      return
    }
    let aktuell = true
    void berechneVertragsende(beginn, Number(laufzeit)).then(({ data, error: err }) => {
      if (!aktuell) return
      setEnde(data)
      setEndeFehler(err)
    })
    return () => {
      aktuell = false
    }
  }, [beginn, laufzeit])

  const run = async (action: () => Promise<{ error: string | null }>): Promise<boolean> => {
    setSaving(true)
    setError(null)
    const { error: err } = await action()
    if (err) setError(err)
    await load()
    setSaving(false)
    return err === null
  }

  if (loading || !vertrag || !form) {
    return (
      <div className="min-h-screen bg-[var(--color-bg-app)]">
        <EdvanceNavbar subtitle={t('page.subtitle')} sticky />
        <main className="mx-auto max-w-4xl px-4 py-8">
          {loading ? (
            <LoadingPulse type="card" />
          ) : (
            <p className="text-sm text-[var(--color-error-exam)]">{error}</p>
          )}
        </main>
      </div>
    )
  }

  const inVorbereitung = vertrag.status === 'in_vorbereitung'
  const einpflegen = vertrag.status === 'unterschrift_ausstehend'
  const abgeschlossen = vertrag.status === 'abgeschlossen'
  const dirty = isDirty(form, vertrag)
  const ibanInvalid = form.iban.trim() !== '' && !isValidIban(form.iban)
  const fehlt = fehlendeAngaben(vertrag, iban !== null)
  const datenSperre = dirty
    ? t('ways.blockedUnsaved')
    : fehlt.length > 0
      ? t('ways.blockedMissing', { fields: fehlt.map((f) => t(`field.${f}`)).join(', ') })
      : endeFehler
        ? endeFehler
        : null

  // Vorwaerts nur so weit, wie die Daten tragen. Zurueck immer.
  const erreichbar: WizardSchritt =
    datenSperre !== null ? 1 : wahl !== null ? 4 : 3
  const paket = stamm.tiers.find((x) => x.id === vertrag.tier_id)?.name ?? null
  const optionen = beginnAuswahl(berlinToday(), vertrag.vertragsbeginn)

  const speichern = async (): Promise<void> => {
    const ok = await run(async () => {
      const res = await updateVertrag(vertrag.id, toPatch(form))
      if (res.error || form.iban.trim() === '') return res
      return saveIban(vertrag.id, normalizeIban(form.iban))
    })
    setSaved(ok)
  }

  const drucken = (anlass: 'unterlagen' | 'bestaetigung'): void => {
    // Tab zuerst oeffnen — nach dem await wuerde der Popup-Blocker greifen.
    openUnterlagen(vertrag.id)
    void run(() => vertragVersandProtokollieren(vertrag.id, 'druck', anlass))
  }

  const ablehnen = async (reason: RejectionReason, note: string | null): Promise<void> => {
    if (await run(() => vertragAblehnen(vertrag.id, reason, note))) setRejecting(false)
  }

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <EdvanceNavbar subtitle={t('page.subtitle')} sticky />
      <main className="mx-auto flex max-w-4xl flex-col gap-6 px-4 py-8">
        <AdminHeader
          eyebrow={t('detail.eyebrow')}
          title={kindName(vertrag)}
          description={t('detail.mandate', { ref: vertrag.mandatsreferenz })}
          backTo="/admin/vertraege"
          backLabel={t('detail.back')}
          actions={
            <EdvanceBadge variant={STATUS_BADGE[vertrag.status]}>
              {t(`status.${vertrag.status}`)}
            </EdvanceBadge>
          }
        />

        {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}

        {vertrag.status === 'abgelehnt' && vertrag.abgelehnt_grund && (
          <EdvanceCard className="p-6 text-sm text-[var(--color-text-secondary)]">
            {tl('card.rejectedReason', {
              reason: vertrag.abgelehnt_notiz ?? tl(`reasons.${vertrag.abgelehnt_grund}`),
            })}
          </EdvanceCard>
        )}

        {inVorbereitung && (
          <>
            <WizardKopf aktuell={schritt} erreichbar={erreichbar} onSpringe={setSchritt} />

            {schritt === 1 && (
              <>
                <VertragForm
                  form={form}
                  onChange={(next) => {
                    setSaved(false)
                    setForm((f) => (f ? { ...f, ...next } : f))
                  }}
                  readOnly={false}
                  tiers={stamm.tiers}
                  ibanMasked={vertrag.iban_masked}
                  mandatsreferenz={vertrag.mandatsreferenz}
                  glaeubigerId={vertrag.glaeubiger_id ?? stamm.glaeubigerId}
                  schulen={stamm.schulen}
                  onSchuleAngelegt={(s) =>
                    setStamm((st) => ({ ...st, schulen: [...st.schulen, s] }))
                  }
                  beginnOptionen={optionen}
                  ende={ende}
                  endeFehler={endeFehler}
                />
                <div className="flex flex-wrap items-center justify-end gap-4">
                  {saved && !dirty && (
                    <p className="text-xs text-[var(--color-text-muted)]">{t('form.saved')}</p>
                  )}
                  <Button
                    variant="outline"
                    disabled={!dirty || ibanInvalid || saving}
                    loading={saving}
                    onClick={() => void speichern()}
                  >
                    {t('form.save')}
                  </Button>
                  <span title={datenSperre ?? undefined}>
                    <Button disabled={datenSperre !== null} onClick={() => setSchritt(2)}>
                      {t('wizard.next')}
                    </Button>
                  </span>
                </div>
              </>
            )}

            {schritt === 2 && (
              <>
                <Schritt2Dokument
                  vertrag={vertrag}
                  iban={iban}
                  paket={paket}
                  glaeubigerId={stamm.glaeubigerId}
                  dokumente={stamm.dokumente}
                  ende={ende}
                />
                <div className="flex justify-end">
                  <Button onClick={() => setSchritt(3)}>{t('wizard.next')}</Button>
                </div>
              </>
            )}

            {schritt === 3 && (
              <>
                <Schritt3Weg wahl={wahl} onWahl={setWahl} disabled={saving} />
                <div className="flex justify-end">
                  <span title={wahl === null ? t('wizard.wegMissing') : undefined}>
                    <Button disabled={wahl === null} onClick={() => setSchritt(4)}>
                      {t('wizard.next')}
                    </Button>
                  </span>
                </div>
              </>
            )}

            {schritt === 4 && wahl === 'vor_ort' && (
              <Schritt4VorOrt
                vertragId={vertrag.id}
                dokumente={stamm.dokumente}
                datenSperre={datenSperre}
                saving={saving}
                onAbschluss={(zustimmungen, signaturVertrag, signaturSepa, passwort) =>
                  void run(() =>
                    vertragAbschliessen(vertrag.id, {
                      weg: 'vor_ort',
                      zustimmungen,
                      signaturVertrag,
                      signaturSepa,
                      studentPassword: passwort,
                    }),
                  )
                }
              />
            )}

            {schritt === 4 && wahl !== null && wahl !== 'vor_ort' && (
              <Schritt4Versand
                weg={wahl}
                empfaenger={vertrag.eltern_email}
                datenSperre={datenSperre}
                saving={saving}
                onDrucken={() => drucken('unterlagen')}
                onVersenden={(bis) =>
                  void run(() =>
                    vertragVersenden(vertrag.id, wahl, vertrag.eltern_email, bis),
                  )
                }
              />
            )}

            <div className="flex justify-end">
              <Button
                variant="ghost"
                className="text-[var(--color-destructive)]"
                onClick={() => setRejecting(true)}
              >
                {t('card.reject')}
              </Button>
            </div>
          </>
        )}

        {einpflegen && (
          <EinpflegenPanel
            vertrag={vertrag}
            tiers={stamm.tiers}
            beginnOptionen={optionen}
            saving={saving}
            onNichtZustande={() => setRejecting(true)}
            onAbschluss={(eingabe) =>
              void run(() =>
                vertragAbschliessen(vertrag.id, {
                  weg: 'papier',
                  unterschriebenAm: eingabe.unterschriebenAm,
                  eingangDatum: eingabe.eingangDatum,
                  scanPfad: eingabe.scanPfad,
                  abweichungVermerk: eingabe.abweichungVermerk,
                  tierId: eingabe.tierId,
                  laufzeitMonate: eingabe.laufzeitMonate,
                  vertragsbeginn: eingabe.vertragsbeginn,
                  studentPassword: eingabe.passwort,
                }),
              )
            }
          />
        )}

        {abgeschlossen && vertrag.zugangscode && (
          <ZugangscodeKarte
            code={vertrag.zugangscode}
            erzeugtAm={vertrag.zugangscode_erzeugt_am}
            gesperrtAm={vertrag.zugangscode_gesperrt_am}
          />
        )}

        {nachweise && (abgeschlossen || nachweise.versand.length > 0) && (
          <NachAbschluss
            vertrag={vertrag}
            dokumente={stamm.dokumente}
            nachweise={nachweise}
            saving={saving}
            onPrint={() => drucken('bestaetigung')}
          />
        )}
      </main>

      <RejectModal
        key={rejecting ? 'open' : 'closed'}
        name={rejecting ? kindName(vertrag) : null}
        saving={saving}
        onClose={() => setRejecting(false)}
        onConfirm={(reason, note) => void ablehnen(reason, note)}
      />
    </div>
  )
}
