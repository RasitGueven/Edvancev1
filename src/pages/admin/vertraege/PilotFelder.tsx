import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { formatDateOnly } from '@/lib/datetime'
import type { PilotVorschlag } from '@/lib/supabase/vertragEnde'
import { Feld } from './FormTeile'
import { einheitenGueltig, type VertragFormState } from './vertragForm'

type PilotFelderProps = {
  form: VertragFormState
  onChange: (next: Partial<VertragFormState>) => void
  readOnly: boolean
  vorschlag: PilotVorschlag | null
  vorschlagFehler: string | null
}

/**
 * V5: Vertragsende und Einheiten einer Pilotvereinbarung. Beides gibt der Admin
 * vor; der Vorschlag (letzter Schultag vor den Sommerferien, ein Termin je
 * Schulwoche) fuellt leere Felder und laesst sich jederzeit wieder uebernehmen.
 */
export function PilotFelder({
  form,
  onChange,
  readOnly,
  vorschlag,
  vorschlagFehler,
}: PilotFelderProps): JSX.Element {
  const { t, i18n } = useTranslation('vertraege')
  const einheitenFalsch = form.einheiten.trim() !== '' && !einheitenGueltig(form.einheiten)
  const weichtAb =
    vorschlag !== null &&
    (form.vertrag_ende !== vorschlag.ende || form.einheiten !== String(vorschlag.einheiten))

  return (
    <>
      <Feld id="vertrag-preis" label={t('field.preis')}>
        <p id="vertrag-preis" className="flex h-11 items-center text-sm font-semibold text-[var(--color-text-primary)]">
          {t('pilot.ohneEntgelt')}
        </p>
      </Feld>
      <Feld id="vertrag-vertrag_ende" label={t('field.vertrag_ende')} hint={t('pilot.endeHint')} pflicht>
        <Input
          id="vertrag-vertrag_ende"
          type="date"
          value={form.vertrag_ende}
          disabled={readOnly}
          onChange={(e) => onChange({ vertrag_ende: e.target.value })}
        />
      </Feld>
      <Feld
        id="vertrag-einheiten-pilot"
        label={t('field.einheiten')}
        hint={einheitenFalsch ? t('pilot.einheitenFalsch') : t('pilot.einheitenHint')}
        pflicht
      >
        <Input
          id="vertrag-einheiten-pilot"
          type="number"
          min={1}
          step={1}
          value={form.einheiten}
          disabled={readOnly}
          aria-invalid={einheitenFalsch}
          onChange={(e) => onChange({ einheiten: e.target.value })}
        />
      </Feld>
      <div className="flex flex-wrap items-center gap-4 sm:col-span-2">
        <p className="text-xs text-[var(--color-text-tertiary)]">
          {vorschlag
            ? t('pilot.vorschlag', {
                ende: formatDateOnly(vorschlag.ende, i18n.language),
                count: vorschlag.einheiten,
              })
            : (vorschlagFehler ?? t('pilot.vorschlagOhneBeginn'))}
        </p>
        {vorschlag && weichtAb && !readOnly && (
          <Button
            size="sm"
            variant="outline"
            onClick={() =>
              onChange({ vertrag_ende: vorschlag.ende, einheiten: String(vorschlag.einheiten) })
            }
          >
            {t('pilot.vorschlagUebernehmen')}
          </Button>
        )}
      </div>
    </>
  )
}
