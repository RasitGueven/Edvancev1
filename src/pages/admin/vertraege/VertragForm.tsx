import type { ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { formatDateOnly } from '@/lib/datetime'
import { SELECT_MD } from '@/lib/formStyles'
import type { Schule } from '@/lib/supabase/schulen'
import type { VertragEnde } from '@/lib/supabase/vertragEnde'
import { isValidIban } from '@/lib/vertrag/iban'
import { kondition } from '@/lib/vertrag/konditionen'
import type { TierPlan } from '@/types'
import { CLASS_LEVELS, SUBJECTS } from '../intake/intakeConstants'
import { EndeVorschau } from './EndeVorschau'
import { SchuleAuswahl } from './SchuleAuswahl'
import type { VertragFormState } from './vertragForm'

type VertragFormProps = {
  form: VertragFormState
  onChange: (next: Partial<VertragFormState>) => void
  readOnly: boolean
  tiers: TierPlan[]
  ibanMasked: string | null
  mandatsreferenz: string
  glaeubigerId: string | null
  schulen: Schule[]
  onSchuleAngelegt: (schule: Schule) => void
  /** Monatserste zur Auswahl — Vertragsbeginn ist nie ein freies Datum. */
  beginnOptionen: string[]
  /** Vorschau aus vertrag_ende_berechnen; null, solange etwas fehlt. */
  ende: VertragEnde | null
  endeFehler: string | null
}

const LAUFZEITEN = [6, 12] as const

export function formatEuro(cents: number, locale: string): string {
  return new Intl.NumberFormat(locale, { style: 'currency', currency: 'EUR' }).format(cents / 100)
}

function Section({ title, children }: { title: string; children: ReactNode }): JSX.Element {
  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-muted)]">
        {title}
      </h2>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">{children}</div>
    </EdvanceCard>
  )
}

function Feld({
  id,
  label,
  hint,
  wide = false,
  children,
}: {
  id: string
  label: string
  hint?: string | null
  wide?: boolean
  children: ReactNode
}): JSX.Element {
  return (
    <div className={`flex flex-col gap-2 ${wide ? 'sm:col-span-2' : ''}`}>
      <Label htmlFor={id}>{label}</Label>
      {children}
      {hint && <p className="text-xs text-[var(--color-text-muted)]">{hint}</p>}
    </div>
  )
}

/**
 * Vertragsformular: Vertragspartner, Kind, Vertragsdaten, SEPA. Beitrag und
 * Einheiten sind keine Eingabefelder — sie folgen aus Paket und Laufzeit
 * (tier_laufzeiten). Nach dem Versand oder der Unterschrift nur noch lesbar.
 */
export function VertragForm({
  form,
  onChange,
  readOnly,
  tiers,
  ibanMasked,
  mandatsreferenz,
  glaeubigerId,
  schulen,
  onSchuleAngelegt,
  beginnOptionen,
  ende,
  endeFehler,
}: VertragFormProps): JSX.Element {
  const { t, i18n } = useTranslation('vertraege')
  const tier = tiers.find((x) => x.id === form.tier_id) ?? null
  const k = kondition(tier, form.laufzeit_monate === '' ? null : Number(form.laufzeit_monate))
  const euro = (cents: number): string => formatEuro(cents, i18n.language)
  const ibanInvalid = form.iban.trim() !== '' && !isValidIban(form.iban)

  const text = (feld: keyof VertragFormState, opts: { type?: string; wide?: boolean } = {}) => (
    <Feld id={`vertrag-${feld}`} label={t(`field.${feld}`)} wide={opts.wide}>
      <Input
        id={`vertrag-${feld}`}
        type={opts.type ?? 'text'}
        value={form[feld]}
        disabled={readOnly}
        onChange={(e) => onChange({ [feld]: e.target.value })}
      />
    </Feld>
  )

  return (
    <div className="flex flex-col gap-4">
      <Section title={t('form.parent')}>
        {text('eltern_vorname')}
        {text('eltern_nachname')}
        {text('strasse')}
        {text('hausnummer')}
        {text('plz')}
        {text('ort')}
        {text('eltern_telefon', { type: 'tel' })}
        {text('eltern_email', { type: 'email' })}
      </Section>

      <Section title={t('form.child')}>
        {text('kind_vorname')}
        {text('kind_nachname')}
        {text('kind_geburtsdatum', { type: 'date' })}
        <Feld id="vertrag-klasse" label={t('field.klasse')}>
          <select
            id="vertrag-klasse"
            className={SELECT_MD}
            value={form.klasse}
            disabled={readOnly}
            onChange={(e) => onChange({ klasse: e.target.value })}
          >
            <option value="">{t('form.choose')}</option>
            {CLASS_LEVELS.map((lvl) => (
              <option key={lvl} value={lvl}>
                {t('form.classOption', { level: lvl })}
              </option>
            ))}
          </select>
        </Feld>
        <Feld id="vertrag-fach" label={t('field.fach')}>
          <select
            id="vertrag-fach"
            className={SELECT_MD}
            value={form.fach}
            disabled={readOnly}
            onChange={(e) => onChange({ fach: e.target.value })}
          >
            <option value="">{t('form.choose')}</option>
            {SUBJECTS.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </select>
        </Feld>
        <Feld id="vertrag-schule" label={t('field.schule')} wide>
          <SchuleAuswahl
            schulen={schulen}
            value={form.schule_id}
            readOnly={readOnly}
            freitext={form.schule}
            onChange={(id, name) => onChange({ schule_id: id, schule: name })}
            onAngelegt={onSchuleAngelegt}
          />
        </Feld>
      </Section>

      <Section title={t('form.contract')}>
        <Feld id="vertrag-tier" label={t('field.tier_id')}>
          <select
            id="vertrag-tier"
            className={SELECT_MD}
            value={form.tier_id}
            disabled={readOnly}
            onChange={(e) => onChange({ tier_id: e.target.value })}
          >
            <option value="">{t('form.choose')}</option>
            {tiers.map((x) => (
              <option key={x.id} value={x.id}>
                {t('form.tierOption', {
                  name: x.name,
                  price: formatEuro(x.price_cents, i18n.language),
                })}
              </option>
            ))}
          </select>
        </Feld>
        <Feld id="vertrag-laufzeit" label={t('field.laufzeit_monate')}>
          <select
            id="vertrag-laufzeit"
            className={SELECT_MD}
            value={form.laufzeit_monate}
            disabled={readOnly}
            onChange={(e) => onChange({ laufzeit_monate: e.target.value })}
          >
            <option value="">{t('form.choose')}</option>
            {LAUFZEITEN.map((m) => (
              <option key={m} value={m}>
                {t(`form.laufzeitOption.${m}`)}
              </option>
            ))}
          </select>
        </Feld>
        <Feld
          id="vertrag-preis"
          label={t('field.preis')}
          hint={
            k
              ? t('form.konditionHint', { beitraege: k.beitraege, gesamt: euro(k.gesamt_cents) })
              : t('form.priceHint')
          }
        >
          <p id="vertrag-preis" className="flex h-11 items-center text-sm font-semibold text-[var(--color-text-primary)]">
            {k ? euro(k.preis_cents) : '—'}
          </p>
        </Feld>
        <Feld id="vertrag-einheiten" label={t('field.einheiten')} hint={k ? t('form.einheitenHint') : null}>
          <p id="vertrag-einheiten" className="flex h-11 items-center text-sm font-semibold text-[var(--color-text-primary)]">
            {k ? k.einheiten : '—'}
          </p>
        </Feld>
        <Feld
          id="vertrag-vertragsbeginn"
          label={t('field.vertragsbeginn')}
          hint={t('form.beginnHint')}
        >
          <select
            id="vertrag-vertragsbeginn"
            className={SELECT_MD}
            value={form.vertragsbeginn}
            disabled={readOnly}
            onChange={(e) => onChange({ vertragsbeginn: e.target.value })}
          >
            <option value="">{t('form.choose')}</option>
            {beginnOptionen.map((tag) => (
              <option key={tag} value={tag}>
                {formatDateOnly(tag, i18n.language)}
              </option>
            ))}
          </select>
        </Feld>
        <div className="sm:col-span-2">
          <EndeVorschau
            ende={ende}
            fehler={endeFehler}
            laufzeitMonate={form.laufzeit_monate === '' ? null : Number(form.laufzeit_monate)}
          />
        </div>
      </Section>

      <Section title={t('form.sepa')}>
        <Feld
          id="vertrag-iban"
          label={t('field.iban')}
          wide
          hint={
            ibanInvalid
              ? t('form.ibanInvalid')
              : ibanMasked
                ? t('form.ibanSaved', { masked: ibanMasked })
                : null
          }
        >
          <Input
            id="vertrag-iban"
            value={form.iban}
            disabled={readOnly}
            autoComplete="off"
            placeholder={ibanMasked ?? t('form.ibanPlaceholder')}
            aria-invalid={ibanInvalid}
            onChange={(e) => onChange({ iban: e.target.value })}
          />
        </Feld>
        <Feld id="vertrag-kontoinhaber" label={t('field.kontoinhaber')} hint={t('form.accountHolderHint')} wide>
          <Input
            id="vertrag-kontoinhaber"
            value={form.kontoinhaber}
            disabled={readOnly}
            onChange={(e) => onChange({ kontoinhaber: e.target.value })}
          />
        </Feld>
        <Feld id="vertrag-mandat" label={t('field.mandatsreferenz')}>
          <p id="vertrag-mandat" className="text-sm text-[var(--color-text-primary)]">{mandatsreferenz}</p>
        </Feld>
        <Feld id="vertrag-glaeubiger" label={t('field.glaeubiger_id')}>
          <p id="vertrag-glaeubiger" className="text-sm text-[var(--color-text-primary)]">
            {glaeubigerId ?? t('form.creditorMissing')}
          </p>
        </Feld>
      </Section>
    </div>
  )
}
