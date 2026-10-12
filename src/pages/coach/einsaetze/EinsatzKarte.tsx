import { useTranslation } from 'react-i18next'
import { DoorOpen } from 'lucide-react'
import { EdvanceCard } from '@/components/edvance'
import { PlatzPunkte } from '@/components/edvance/PlatzPunkte'
import { Button } from '@/components/ui/button'
import { KlasseFach } from '@/pages/admin/slots/KlasseFach'
import type { EinsatzVM } from './einsaetze.model'

type Props = {
  e: EinsatzVM
  /** Ruhige Zeile ohne Kinder: Knopf zurückhaltend (ein primärer Knopf je Karte, nicht je Leerlauf). */
  ruhig?: boolean
  onOeffnen: (e: EinsatzVM) => void
  /** Der Knopf dieses Einsatzes wartet auf die Antwort. */
  oeffnet: boolean
}

/** Knopf nur am Tag des Einsatzes, sonst ein ruhiger Satz (Entscheidung 14: nur am Tag). */
function Aktion({ e, onOeffnen, oeffnet, ruhig = false }: Props): JSX.Element {
  const { t } = useTranslation('coach')
  return e.heute ? (
    <Button variant={ruhig ? 'outline' : 'default'} loading={oeffnet} onClick={() => onOeffnen(e)} className="min-h-[44px]">
      {t('einsaetze.oeffnen')}
    </Button>
  ) : (
    <span className="text-xs text-[var(--color-text-tertiary)]">{t('einsaetze.amTag')}</span>
  )
}

/**
 * Ein Einsatz des Coaches: Uhrzeit groß, Raum, Platz-Punkte und die Kinder mit Name, Klasse und
 * Fach-Kürzel. Ein Einsatz ohne Kinder ist eine ruhige Zeile statt einer vollen Karte.
 */
export function EinsatzKarte(props: Props): JSX.Element {
  const { t } = useTranslation('coach')
  const { e } = props

  if (e.kinder.length === 0) {
    return (
      <div
        data-testid="einsatz-ruhig"
        className="flex min-h-[44px] flex-wrap items-center gap-4 rounded-[var(--radius-lg)] border border-dashed @heute-listen:col-span-2 border-[var(--color-border)] px-4 py-2"
      >
        <span className="text-sm font-semibold tabular-nums text-[var(--color-text-secondary)]">
          {t('einsaetze.zeitspanne', { beginn: e.beginn, ende: e.ende })}
        </span>
        <span className="text-sm text-[var(--color-text-secondary)]">{e.raum_name}</span>
        <span className="min-w-0 flex-1 text-xs text-[var(--color-text-tertiary)]">{t('einsaetze.keineKinder')}</span>
        <Aktion {...props} ruhig />
      </div>
    )
  }

  return (
    <section data-testid="einsatz-karte" aria-label={t('einsaetze.karteLabel', { beginn: e.beginn, raum: e.raum_name })}>
      <EdvanceCard className="flex flex-col gap-4 p-6">
        <div className="flex flex-wrap items-start gap-4">
          <div className="flex min-w-0 flex-1 flex-col gap-2">
            <span className="font-serif text-2xl font-semibold tabular-nums text-[var(--color-text-primary)]">{e.beginn}</span>
            <span className="flex flex-wrap items-center gap-2 text-sm text-[var(--color-text-secondary)]">
              <DoorOpen aria-hidden="true" className="h-4 w-4" />
              {e.raum_name}
              <span className="text-xs tabular-nums text-[var(--color-text-tertiary)]">{t('einsaetze.bis', { ende: e.ende })}</span>
            </span>
          </div>
          <PlatzPunkte raeume={[e.kinder.length]} mitZahl className="pt-2" />
        </div>
        <ul className="flex flex-col">
          {e.kinder.map((k) => (
            <li key={k.student_id} className="flex min-h-[44px] items-center gap-2 border-t border-[var(--color-border)] py-2">
              <span className="min-w-0 flex-1 truncate text-sm font-semibold">{k.name ?? t('dashboard.unbenannt')}</span>
              <KlasseFach klasse={k.klasse} fach={k.fach} />
            </li>
          ))}
        </ul>
        <div className="flex justify-end border-t border-[var(--color-border)] pt-4">
          <Aktion {...props} />
        </div>
      </EdvanceCard>
    </section>
  )
}
