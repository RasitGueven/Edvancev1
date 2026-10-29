// Ein Session-Abschnitt der Muster-Ansicht (M1): Titel, Fortschritt „4 von 6 geprüft“, die Muster (Voraussetzungen
// zuerst) und fuer Admins „Session n freigeben“ mit Bestaetigung im Abschnitt (kein Modal).
import { useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui'
import { freigebbar, passtZuFilter, type MusterFilter, type SessionGruppe } from '@/lib/pruefung/bauformPlan'
import type { BauformStatus } from '@/types/bauformPruefung'

const BADGE: Partial<Record<BauformStatus, 'warning' | 'success' | 'muted'>> = {
  zur_pruefung: 'warning',
  rueckfrage: 'warning',
  zur_freigabe: 'success',
  freigegeben: 'success',
}

export function MusterSessionGruppe({
  gruppe,
  filter,
  isAdmin,
  onOeffnen,
  onFreigeben,
}: {
  gruppe: SessionGruppe
  filter: MusterFilter
  isAdmin: boolean
  onOeffnen: (bauformId: string) => void
  onFreigeben: (schluessel: string[]) => Promise<void>
}): JSX.Element | null {
  const { t } = useTranslation('bauformPruefen')
  const [frage, setFrage] = useState(false)
  const [busy, setBusy] = useState(false)
  const sichtbar = gruppe.zeilen.filter((z) => passtZuFilter(z.status, filter))
  if (sichtbar.length === 0) return null

  const frei = freigebbar(gruppe)
  const titel = gruppe.nr == null
    ? t(gruppe.nurVoraussetzungen ? 'plan.voraussetzungen' : 'plan.ohneSession')
    : t('plan.session', { nr: gruppe.nr, titel: gruppe.titel ?? '' })
  const gesperrt = gruppe.zeilen.some((z) => z.status === 'rueckfrage') ? 'plan.gesperrtRueckfrage' : 'plan.gesperrtLeer'
  const bestaetigen = async (): Promise<void> => {
    setBusy(true)
    await onFreigeben(frei)
    setBusy(false)
    setFrage(false)
  }

  return (
    <section className="flex flex-col gap-4" aria-label={titel}>
      <div className="flex flex-wrap items-end justify-between gap-2">
        <div className="flex flex-col gap-2">
          <h2 className="text-base font-semibold text-[var(--color-text-primary)]">{titel}</h2>
          <span className="text-xs text-[var(--color-text-muted)]">
            {t('plan.fortschritt', { geprueft: gruppe.stand.geprueft, total: gruppe.stand.total })}
          </span>
        </div>
        {isAdmin && gruppe.nr != null && !frage && (
          <Button variant="outline" disabled={frei.length === 0} title={frei.length === 0 ? t(gesperrt) : undefined}
            onClick={() => setFrage(true)}>
            {t('plan.freigeben', { nr: gruppe.nr })}
          </Button>
        )}
      </div>
      {frage && (
        <EdvanceCard className="flex flex-wrap items-center gap-4">
          <span className="flex-1 text-sm text-[var(--color-text-secondary)]">
            {t('plan.bestaetigen', { count: frei.length, nr: gruppe.nr, liste: frei.join(', ') })}
          </span>
          <Button variant="outline" disabled={busy} onClick={() => setFrage(false)}>{t('plan.abbrechen')}</Button>
          <Button disabled={busy} onClick={() => void bestaetigen()}>{t('plan.jaFreigeben', { count: frei.length })}</Button>
        </EdvanceCard>
      )}
      <ul className="flex flex-col gap-4">
        {sichtbar.map((b) => (
          <li key={b.bauform_id}>
            <button type="button" onClick={() => onOeffnen(b.bauform_id)} className="w-full text-left">
              <EdvanceCard className="flex flex-wrap items-center gap-4 hover:shadow-md">
                <span className="text-base font-semibold text-[var(--color-text-primary)]">{b.schluessel}</span>
                <span className="flex-1 text-sm text-[var(--color-text-secondary)]">
                  {b.ist_voraussetzung ? t('plan.voraussetzung', { skill: b.skill_label }) : (b.kernidee_titel ?? b.skill_label)} · {b.format}
                </span>
                <span className="text-xs text-[var(--color-text-muted)]">{t('liste.version', { version: b.version })} · {t('liste.gruen', { count: b.gruen })}</span>
                <EdvanceBadge variant={BADGE[b.status] ?? 'muted'}>{t(`status.${b.status}`)}</EdvanceBadge>
              </EdvanceCard>
            </button>
          </li>
        ))}
      </ul>
    </section>
  )
}
