import { useCallback, useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { AdminHeader, EdvanceBadge, EdvanceCard, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { Button } from '@/components/ui/button'
import { listTiers } from '@/lib/supabase/subscriptions'
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
  type VertragNachweise,
} from '@/lib/supabase/vertraege'
import { isValidIban, normalizeIban } from '@/lib/vertrag/iban'
import type { RejectionReason, TierPlan, VertragDokument, VertragMitLead } from '@/types'
import { RejectModal } from './leads/RejectModal'
import { AbschlussWege } from './vertraege/AbschlussWege'
import { DokumentCheckliste } from './vertraege/DokumentCheckliste'
import { NachAbschluss } from './vertraege/NachAbschluss'
import { PapierAbschluss } from './vertraege/PapierAbschluss'
import { VertragForm } from './vertraege/VertragForm'
import { isDirty, toFormState, toPatch, type VertragFormState } from './vertraege/vertragForm'
import { fehlendeAngaben, kindName } from './vertraege/vertragModel'
import { STATUS_BADGE, openUnterlagen } from './vertraege/vertragUi'

type Stammdaten = { tiers: TierPlan[]; dokumente: VertragDokument[]; glaeubigerId: string | null }

/** Vertrag erfassen, Dokumente bestaetigen, unterschreiben oder versenden (/admin/vertraege/:id). */
export function VertragPage(): JSX.Element {
  const { id = '' } = useParams<{ id: string }>()
  const { t } = useTranslation('vertraege')
  const { t: tl } = useTranslation('leads')
  const [vertrag, setVertrag] = useState<VertragMitLead | null>(null)
  const [form, setForm] = useState<VertragFormState | null>(null)
  const [iban, setIban] = useState<string | null>(null)
  const [stamm, setStamm] = useState<Stammdaten>({ tiers: [], dokumente: [], glaeubigerId: null })
  const [nachweise, setNachweise] = useState<VertragNachweise | null>(null)
  // Angehakte Dokumente mit dem Zeitpunkt des Hakens — gespeichert erst mit der Unterschrift.
  const [haken, setHaken] = useState<Record<string, string>>({})
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
      const [tiers, dokumente, glaeubiger] = await Promise.all([
        listTiers(),
        listVertragDokumente(),
        getGlaeubigerId(),
        load(),
      ])
      setStamm({
        tiers: tiers.data ?? [],
        dokumente: dokumente.data ?? [],
        glaeubigerId: glaeubiger.data ?? null,
      })
      setError((e) => e ?? tiers.error ?? dokumente.error ?? glaeubiger.error)
      setLoading(false)
    })()
  }, [load])

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
          {loading ? <LoadingPulse type="card" /> : <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}
        </main>
      </div>
    )
  }

  const editable = vertrag.status === 'in_vorbereitung'
  const offen = editable || vertrag.status === 'unterschrift_ausstehend'
  const dirty = isDirty(form, vertrag)
  const ibanInvalid = form.iban.trim() !== '' && !isValidIban(form.iban)
  const fehlt = fehlendeAngaben(vertrag, iban !== null)
  const datenSperre = dirty
    ? t('ways.blockedUnsaved')
    : fehlt.length > 0
      ? t('ways.blockedMissing', { fields: fehlt.map((f) => t(`field.${f}`)).join(', ') })
      : null
  const offenePflicht = stamm.dokumente.filter((d) => d.pflicht && haken[d.schluessel] === undefined)
  const hakenSperre = offenePflicht.length > 0 ? t('ways.blockedChecks') : null

  const save = async (): Promise<void> => {
    const ok = await run(async () => {
      const res = await updateVertrag(vertrag.id, toPatch(form))
      if (res.error || form.iban.trim() === '') return res
      return saveIban(vertrag.id, normalizeIban(form.iban))
    })
    setSaved(ok)
  }

  const sign = (signaturVertrag: string, signaturSepa: string): void => {
    const zustimmungen = stamm.dokumente
      .filter((d) => haken[d.schluessel] !== undefined)
      .map((d) => ({ schluessel: d.schluessel, version: d.version, akzeptiert_at: haken[d.schluessel] }))
    void run(() =>
      vertragAbschliessen(vertrag.id, { weg: 'vor_ort', zustimmungen, signaturVertrag, signaturSepa }),
    )
  }

  const print = (anlass: 'unterlagen' | 'bestaetigung'): void => {
    // Tab zuerst oeffnen — nach dem await wuerde der Popup-Blocker greifen.
    openUnterlagen(vertrag.id)
    void run(() => vertragVersandProtokollieren(vertrag.id, 'druck', anlass))
  }

  const reject = async (reason: RejectionReason, note: string | null): Promise<void> => {
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
          actions={<EdvanceBadge variant={STATUS_BADGE[vertrag.status]}>{t(`status.${vertrag.status}`)}</EdvanceBadge>}
        />

        {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}

        {vertrag.status === 'abgelehnt' && vertrag.abgelehnt_grund && (
          <EdvanceCard className="p-6 text-sm text-[var(--color-text-secondary)]">
            {tl('card.rejectedReason', {
              reason: vertrag.abgelehnt_notiz ?? tl(`reasons.${vertrag.abgelehnt_grund}`),
            })}
          </EdvanceCard>
        )}

        <VertragForm
          form={form}
          onChange={(next) => {
            setSaved(false)
            setForm((f) => (f ? { ...f, ...next } : f))
          }}
          readOnly={!editable}
          tiers={stamm.tiers}
          ibanMasked={vertrag.iban_masked}
          mandatsreferenz={vertrag.mandatsreferenz}
          glaeubigerId={vertrag.glaeubiger_id ?? stamm.glaeubigerId}
        />

        {editable && (
          <div className="flex flex-wrap items-center justify-end gap-4">
            {saved && !dirty && <p className="text-xs text-[var(--color-text-muted)]">{t('form.saved')}</p>}
            <Button variant="outline" disabled={!dirty || ibanInvalid || saving} loading={saving} onClick={() => void save()}>
              {t('form.save')}
            </Button>
          </div>
        )}

        {offen && (
          <>
            <EdvanceCard className="flex flex-col gap-4 p-6">
              <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-muted)]">
                {t('docs.title')}
              </h2>
              <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{t('docs.hint')}</p>
              <DokumentCheckliste
                vertragId={vertrag.id}
                dokumente={stamm.dokumente}
                haken={haken}
                disabled={saving}
                onToggle={(dok, checked) =>
                  setHaken((h) => {
                    const next = { ...h }
                    if (checked) next[dok.schluessel] = new Date().toISOString()
                    else delete next[dok.schluessel]
                    return next
                  })
                }
              />
            </EdvanceCard>

            <AbschlussWege
              datenSperre={datenSperre}
              hakenSperre={hakenSperre}
              saving={saving}
              onSign={sign}
              onPrint={() => print('unterlagen')}
            />

            {vertrag.status === 'unterschrift_ausstehend' && (
              <EdvanceCard className="flex flex-col gap-4 p-6">
                <p className="text-sm text-[var(--color-text-secondary)]">{t('paper.hint')}</p>
                <PapierAbschluss
                  idPrefix="detail"
                  saving={saving}
                  onConfirm={(datum) => void run(() => vertragAbschliessen(vertrag.id, { weg: 'papier', unterschriebenAm: datum }))}
                />
              </EdvanceCard>
            )}

            <div className="flex justify-end">
              <Button variant="ghost" className="text-[var(--color-destructive)]" onClick={() => setRejecting(true)}>
                {t('card.reject')}
              </Button>
            </div>
          </>
        )}

        {nachweise && (vertrag.status === 'abgeschlossen' || nachweise.versand.length > 0) && (
          <NachAbschluss
            vertrag={vertrag}
            dokumente={stamm.dokumente}
            nachweise={nachweise}
            saving={saving}
            onPrint={() => print('bestaetigung')}
          />
        )}
      </main>

      <RejectModal
        key={rejecting ? 'open' : 'closed'}
        name={rejecting ? kindName(vertrag) : null}
        saving={saving}
        onClose={() => setRejecting(false)}
        onConfirm={(reason, note) => void reject(reason, note)}
      />
    </div>
  )
}
