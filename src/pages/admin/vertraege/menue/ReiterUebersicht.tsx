import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EmptyState } from '@/components/edvance'
import { EdvanceTable, type Spalte } from '@/components/edvance/EdvanceTable'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { formatDateOnly } from '@/lib/datetime'
import { SELECT_SM } from '@/lib/formStyles'
import {
  kind,
  passtZumFilter,
  summen,
  vertragspartner,
  type UebersichtFilter,
} from '@/lib/vertrag/menue'
import type { TierPlan, VertragAktuell, WirksamerStatus, Zahlungsstatus } from '@/types'
import { formatEuro } from '../VertragForm'
import { STATUS_FARBE, ZAHLUNG_FARBE } from './statusFarben'

const STATUS: WirksamerStatus[] = ['aktiv', 'im_widerruf', 'gekuendigt', 'ausgelaufen', 'widerrufen']
const ZAHLUNG: Zahlungsstatus[] = ['in_ordnung', 'zahlung_offen', 'mahnung_1', 'mahnung_2', 'inkasso']

type Props = {
  vertraege: VertragAktuell[]
  tiers: TierPlan[]
  filter: UebersichtFilter
  onFilter: (next: Partial<UebersichtFilter>) => void
  onZeile: (v: VertragAktuell) => void
}

/**
 * Die Vertragsuebersicht mit der Summenzeile darueber.
 *
 * Die drei Zahlen der Summenzeile sind addierte Spaltenwerte, keine eigene
 * Rechnung: wirksamer_status und beitrag_diesen_monat_cents stehen fertig in
 * jeder Zeile (vertraege_aktuell). Deshalb kann hier nichts von dem abweichen,
 * was im Vertrag steht.
 */
export function ReiterUebersicht({ vertraege, tiers, filter, onFilter, onZeile }: Props): JSX.Element {
  const { t, i18n } = useTranslation('vertraege')
  const lang = i18n.language
  const sichtbar = vertraege.filter((v) => passtZumFilter(v, filter))
  const s = summen(sichtbar)
  const paketName = (id: string | null): string =>
    tiers.find((x) => x.id === id)?.name ?? '—'

  const spalten: Spalte<VertragAktuell>[] = [
    {
      key: 'partner',
      kopf: t('menue.spalte.partner'),
      zelle: (v) => (
        <div className="flex flex-col">
          <span className="font-semibold">{vertragspartner(v) || '—'}</span>
          <span className="text-xs text-[var(--color-text-tertiary)]">
            {t('menue.kindMitKlasse', { kind: kind(v) || '—', klasse: v.klasse ?? '—' })}
          </span>
        </div>
      ),
    },
    { key: 'paket', kopf: t('field.tier_id'), zelle: (v) => paketName(v.tier_id) },
    {
      key: 'betrag',
      kopf: t('menue.spalte.betrag'),
      rechts: true,
      zelle: (v) => (v.preis_cents !== null ? formatEuro(v.preis_cents, lang) : '—'),
    },
    {
      key: 'laufzeit',
      kopf: t('field.laufzeit_monate'),
      zelle: (v) => (v.laufzeit_monate ? t(`form.laufzeitOption.${v.laufzeit_monate}`) : '—'),
    },
    {
      key: 'zeitraum',
      kopf: t('menue.spalte.zeitraum'),
      zelle: (v) => (
        <div className="flex flex-col">
          <span>
            {v.vertragsbeginn ? formatDateOnly(v.vertragsbeginn, lang) : '—'}
            {' – '}
            {v.vertrag_ende ? formatDateOnly(v.vertrag_ende, lang) : '—'}
          </span>
          {/* laufzeit_monat ist NULL, solange der Vertrag nicht begonnen hat. */}
          {v.laufzeit_monat === null && v.vertragsbeginn && (
            <span className="text-xs text-[var(--color-text-tertiary)]">
              {t('menue.beginntAm', { date: formatDateOnly(v.vertragsbeginn, lang) })}
            </span>
          )}
        </div>
      ),
    },
    {
      key: 'status',
      kopf: t('menue.spalte.status'),
      zelle: (v) => (
        <EdvanceBadge variant={STATUS_FARBE[v.wirksamer_status]}>
          {t(`menue.wirksam.${v.wirksamer_status}`)}
        </EdvanceBadge>
      ),
    },
    {
      key: 'zahlung',
      kopf: t('menue.spalte.zahlung'),
      zelle: (v) => (
        <EdvanceBadge variant={ZAHLUNG_FARBE[v.zahlungsstatus]}>
          {t(`menue.zahlung.${v.zahlungsstatus}`)}
        </EdvanceBadge>
      ),
    },
  ]

  return (
    <div className="flex flex-col gap-4">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        {[
          { k: 'laufend', wert: String(s.laufend) },
          { k: 'abbuchung', wert: formatEuro(s.abbuchungCents, lang) },
          { k: 'widerruf', wert: String(s.imWiderruf) },
        ].map(({ k, wert }) => (
          <div
            key={k}
            className="flex flex-col gap-1 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-4"
          >
            <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
              {t(`menue.summe.${k}`)}
            </span>
            <span className="text-3xl font-bold text-[var(--color-text-primary)]">{wert}</span>
          </div>
        ))}
      </div>

      <div className="flex flex-wrap items-end gap-3">
        <div className="flex min-w-[14rem] flex-1 flex-col gap-2">
          <Label htmlFor="uebersicht-suche">{t('menue.suche')}</Label>
          <Input
            id="uebersicht-suche"
            value={filter.suche}
            placeholder={t('menue.suchePlatzhalter')}
            onChange={(e) => onFilter({ suche: e.target.value })}
          />
        </div>
        <select
          className={SELECT_SM}
          aria-label={t('menue.spalte.status')}
          value={filter.status ?? ''}
          onChange={(e) => onFilter({ status: (e.target.value || null) as WirksamerStatus | null })}
        >
          <option value="">{t('menue.alleStatus')}</option>
          {STATUS.map((x) => (
            <option key={x} value={x}>{t(`menue.wirksam.${x}`)}</option>
          ))}
        </select>
        <select
          className={SELECT_SM}
          aria-label={t('field.tier_id')}
          value={filter.tierId ?? ''}
          onChange={(e) => onFilter({ tierId: e.target.value || null })}
        >
          <option value="">{t('menue.allePakete')}</option>
          {tiers.map((x) => (
            <option key={x.id} value={x.id}>{x.name}</option>
          ))}
        </select>
        <select
          className={SELECT_SM}
          aria-label={t('field.laufzeit_monate')}
          value={filter.laufzeit ?? ''}
          onChange={(e) => onFilter({ laufzeit: e.target.value ? Number(e.target.value) : null })}
        >
          <option value="">{t('menue.alleLaufzeiten')}</option>
          <option value="6">{t('form.laufzeitOption.6')}</option>
          <option value="12">{t('form.laufzeitOption.12')}</option>
        </select>
        <select
          className={SELECT_SM}
          aria-label={t('menue.spalte.zahlung')}
          value={filter.zahlungsstatus ?? ''}
          onChange={(e) =>
            onFilter({ zahlungsstatus: (e.target.value || null) as Zahlungsstatus | null })
          }
        >
          <option value="">{t('menue.alleZahlungen')}</option>
          {ZAHLUNG.map((x) => (
            <option key={x} value={x}>{t(`menue.zahlung.${x}`)}</option>
          ))}
        </select>
        <label className="inline-flex min-h-[44px] items-center gap-2 text-sm text-[var(--color-text-secondary)]">
          <input
            type="checkbox"
            checked={!filter.nurAktuelle}
            onChange={(e) => onFilter({ nurAktuelle: !e.target.checked })}
          />
          {t('menue.auchVorgaenger')}
        </label>
      </div>

      {sichtbar.length === 0 ? (
        <EmptyState icon="📄" title={t('menue.leer.uebersicht')} description={t('menue.leer.uebersichtHint')} />
      ) : (
        <EdvanceTable
          beschriftung={t('menue.reiter.uebersicht')}
          spalten={spalten}
          zeilen={sichtbar}
          zeileKey={(v) => v.id}
          onZeile={onZeile}
        />
      )}
    </div>
  )
}
