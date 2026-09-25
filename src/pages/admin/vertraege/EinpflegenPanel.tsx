import { useState } from 'react'
import { FileUp, Upload } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { berlinToday, formatDateOnly } from '@/lib/datetime'
import { uploadScan } from '@/lib/supabase/vertragScan'
import { SELECT_MD, TEXTAREA_MD } from '@/lib/formStyles'
import { abweichendeFelder, type AbgleichStand } from '@/lib/vertrag/abgleich'
import { paketOptionen } from '@/lib/vertrag/konditionen'
import type { TierPlan, Vertrag } from '@/types'
import { formatEuro } from './VertragForm'

type EinpflegenProps = {
  vertrag: Vertrag
  tiers: TierPlan[]
  beginnOptionen: string[]
  saving: boolean
  onAbschluss: (eingabe: {
    unterschriebenAm: string
    eingangDatum: string
    scanPfad: string
    abweichungVermerk: string | null
    tierId: string
    laufzeitMonate: number
    vertragsbeginn: string
  }) => void
  onNichtZustande: () => void
}

const LAUFZEITEN = [6, 12] as const

/**
 * Einpflegen eines Ruecklaufs (Anforderung F).
 *
 * Links steht, was versendet wurde, rechts, was auf dem Papier steht. Weicht
 * etwas ab, wird der Vermerk zum Pflichtfeld — es gilt das Papier, und der
 * Vermerk haelt fest, was die Eltern geaendert haben. Ohne hochgeladenen Scan
 * geht der Abschluss nicht: der Scan IST der Nachweis.
 */
export function EinpflegenPanel({
  vertrag,
  tiers,
  beginnOptionen,
  saving,
  onAbschluss,
  onNichtZustande,
}: EinpflegenProps): JSX.Element {
  const { t, i18n } = useTranslation('vertraege')
  const [scanPfad, setScanPfad] = useState<string | null>(vertrag.scan_pfad)
  const [upload, setUpload] = useState(false)
  const [uploadFehler, setUploadFehler] = useState<string | null>(null)
  const [tierId, setTierId] = useState(vertrag.tier_id ?? '')
  const [laufzeit, setLaufzeit] = useState(String(vertrag.laufzeit_monate ?? ''))
  const [beginn, setBeginn] = useState(vertrag.vertragsbeginn ?? '')
  const [unterschriebenAm, setUnterschriebenAm] = useState('')
  const [eingangDatum, setEingangDatum] = useState(berlinToday())
  const [vermerk, setVermerk] = useState(vertrag.abweichung_vermerk ?? '')

  const soll: AbgleichStand = {
    tier_id: vertrag.tier_id,
    laufzeit_monate: vertrag.laufzeit_monate,
    vertragsbeginn: vertrag.vertragsbeginn,
  }
  const ist: AbgleichStand = {
    tier_id: tierId === '' ? null : tierId,
    laufzeit_monate: laufzeit === '' ? null : Number(laufzeit),
    vertragsbeginn: beginn === '' ? null : beginn,
  }
  const abweichend = abweichendeFelder(soll, ist)

  const hochladen = async (datei: File): Promise<void> => {
    setUpload(true)
    setUploadFehler(null)
    const { data, error } = await uploadScan(vertrag.id, datei)
    setUpload(false)
    if (error || !data) {
      setUploadFehler(error ?? t('einpflegen.uploadFailed'))
      return
    }
    setScanPfad(data)
  }

  const fehlt = [
    scanPfad === null ? t('einpflegen.missingScan') : null,
    unterschriebenAm === '' ? t('einpflegen.missingSigned') : null,
    eingangDatum === '' ? t('einpflegen.missingReceived') : null,
    tierId === '' || laufzeit === '' || beginn === '' ? t('einpflegen.missingTerms') : null,
    abweichend.length > 0 && vermerk.trim() === '' ? t('einpflegen.missingNote') : null,
  ].filter((x): x is string => x !== null)

  const sperre = fehlt.length > 0 ? fehlt.join(' · ') : null

  const sollWert = (feld: 'tier_id' | 'laufzeit_monate' | 'vertragsbeginn'): string => {
    if (feld === 'tier_id') return tiers.find((x) => x.id === vertrag.tier_id)?.name ?? '—'
    if (feld === 'laufzeit_monate') {
      return vertrag.laufzeit_monate ? t(`form.laufzeitOption.${vertrag.laufzeit_monate}`) : '—'
    }
    return vertrag.vertragsbeginn ? formatDateOnly(vertrag.vertragsbeginn, i18n.language) : '—'
  }

  const zeile = (
    feld: 'tier_id' | 'laufzeit_monate' | 'vertragsbeginn',
    eingabe: JSX.Element,
  ): JSX.Element => (
    <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
      <div className="flex flex-col gap-2">
        <Label>{t('einpflegen.soll', { feld: t(`field.${feld}`) })}</Label>
        <p
          className={`flex min-h-[44px] items-center text-sm ${
            abweichend.includes(feld)
              ? 'text-[var(--color-text-tertiary)] line-through'
              : 'text-[var(--color-text-primary)]'
          }`}
        >
          {sollWert(feld)}
        </p>
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor={`ist-${feld}`}>
          {t('einpflegen.ist', { feld: t(`field.${feld}`) })}
          <span aria-hidden="true" className="text-[var(--color-error-exam)]">{' *'}</span>
        </Label>
        {eingabe}
      </div>
    </div>
  )

  return (
    <div className="flex flex-col gap-4">
      <EdvanceCard className="flex flex-col gap-4 p-6">
        <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('einpflegen.scanTitle')}
        </h2>
        <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
          {t('einpflegen.scanHint')}
        </p>
        <label className="inline-flex min-h-[44px] w-fit cursor-pointer items-center gap-2 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 text-sm font-semibold text-[var(--color-text-primary)] hover:border-[var(--color-primary)]">
          <Upload className="h-4 w-4" />
          {upload ? t('einpflegen.uploading') : t('einpflegen.choose')}
          <input
            type="file"
            className="sr-only"
            accept="application/pdf,image/*"
            disabled={upload || saving}
            onChange={(e) => {
              const datei = e.target.files?.[0]
              if (datei) void hochladen(datei)
            }}
          />
        </label>
        {scanPfad && (
          <p className="flex items-center gap-2 text-sm text-[var(--color-success)]">
            <FileUp className="h-4 w-4" />
            {t('einpflegen.scanReady')}
          </p>
        )}
        {uploadFehler && <p className="text-sm text-[var(--color-error-exam)]">{uploadFehler}</p>}
      </EdvanceCard>

      <EdvanceCard className="flex flex-col gap-4 p-6">
        <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('einpflegen.abgleichTitle')}
        </h2>
        {/* Wie in Schritt 1: erst die Laufzeit, dann das Paket mit IHREN Zahlen. */}
        {zeile(
          'laufzeit_monate',
          <select
            id="ist-laufzeit_monate"
            className={SELECT_MD}
            value={laufzeit}
            disabled={saving}
            onChange={(e) => setLaufzeit(e.target.value)}
          >
            <option value="">{t('form.choose')}</option>
            {LAUFZEITEN.map((m) => (
              <option key={m} value={m}>
                {t(`form.laufzeitOption.${m}`)}
              </option>
            ))}
          </select>,
        )}
        {zeile(
          'tier_id',
          <select
            id="ist-tier_id"
            className={SELECT_MD}
            value={tierId}
            disabled={saving || laufzeit === ''}
            onChange={(e) => setTierId(e.target.value)}
          >
            <option value="">{t('form.choose')}</option>
            {paketOptionen(tiers, laufzeit === '' ? null : Number(laufzeit)).map((x) => (
              <option key={x.id} value={x.id}>
                {x.kondition
                  ? t('form.tierOption', {
                      name: x.name,
                      price: formatEuro(x.kondition.preis_cents, i18n.language),
                      einheiten: x.kondition.einheiten,
                    })
                  : x.name}
              </option>
            ))}
          </select>,
        )}
        {zeile(
          'vertragsbeginn',
          <select
            id="ist-vertragsbeginn"
            className={SELECT_MD}
            value={beginn}
            disabled={saving}
            onChange={(e) => setBeginn(e.target.value)}
          >
            <option value="">{t('form.choose')}</option>
            {beginnOptionen.map((tag) => (
              <option key={tag} value={tag}>
                {formatDateOnly(tag, i18n.language)}
              </option>
            ))}
          </select>,
        )}

        {abweichend.length > 0 && (
          <div className="flex flex-col gap-2">
            <Label htmlFor="ist-vermerk">
              {t('einpflegen.vermerk')}
              <span aria-hidden="true" className="text-[var(--color-error-exam)]">{' *'}</span>
            </Label>
            <textarea
              id="ist-vermerk"
              className={TEXTAREA_MD}
              value={vermerk}
              disabled={saving}
              onChange={(e) => setVermerk(e.target.value)}
            />
            <p className="text-xs text-[var(--color-text-tertiary)]">
              {t('einpflegen.vermerkHint', {
                felder: abweichend.map((f) => t(`field.${f}`)).join(', '),
              })}
            </p>
          </div>
        )}
      </EdvanceCard>

      <EdvanceCard className="flex flex-col gap-4 p-6">
        <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('einpflegen.datenTitle')}
        </h2>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div className="flex flex-col gap-2">
            <Label htmlFor="ist-unterschrieben">
              {t('einpflegen.signedOn')}
              <span aria-hidden="true" className="text-[var(--color-error-exam)]">{' *'}</span>
            </Label>
            <Input
              id="ist-unterschrieben"
              type="date"
              value={unterschriebenAm}
              disabled={saving}
              onChange={(e) => setUnterschriebenAm(e.target.value)}
            />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="ist-eingang">
              {t('einpflegen.receivedOn')}
              <span aria-hidden="true" className="text-[var(--color-error-exam)]">{' *'}</span>
            </Label>
            <Input
              id="ist-eingang"
              type="date"
              value={eingangDatum}
              disabled={saving}
              onChange={(e) => setEingangDatum(e.target.value)}
            />
          </div>
        </div>
      </EdvanceCard>

      {sperre && <p className="text-sm text-[var(--color-text-tertiary)]">{sperre}</p>}

      <div className="flex flex-wrap items-center justify-between gap-2">
        <Button
          variant="ghost"
          className="text-[var(--color-destructive)]"
          disabled={saving}
          onClick={onNichtZustande}
        >
          {t('einpflegen.notConcluded')}
        </Button>
        <span title={sperre ?? undefined}>
          <Button
            disabled={sperre !== null || saving}
            loading={saving}
            onClick={() =>
              onAbschluss({
                unterschriebenAm,
                eingangDatum,
                scanPfad: scanPfad!,
                abweichungVermerk: vermerk.trim() === '' ? null : vermerk.trim(),
                tierId,
                laufzeitMonate: Number(laufzeit),
                vertragsbeginn: beginn,
              })
            }
          >
            {t('einpflegen.conclude')}
          </Button>
        </span>
      </div>
    </div>
  )
}
