import { useEffect } from 'react'
import { X } from 'lucide-react'
import { AvatarInitials } from '@/components/edvance/AvatarInitials'
import type { CoachLiveKind } from '@/types/coachLive'
import { Interventionsleiter, PfadEntscheidung } from './Eingreifen'
import { MasteryPruefung } from './MasteryPruefung'
import { AufgabeBlock, HeuteBlock, HinweiseBlock, InfoBlock, SequenzBlock, VersucheBlock, WartetBlock, ZielBlock } from './SchubladeBloecke'
import { useLiveTexte } from './useLiveTexte'

/**
 * Schublade je Kind (Warm-up und Kernarbeit): rechts im Querformat, von unten im
 * Hochformat. Musterloesung und Fehlbild gibt es nur hier.
 */
export function Schublade({ kind, onSchliessen }: { kind: CoachLiveKind; onSchliessen: () => void }): JSX.Element {
  const tx = useLiveTexte()

  useEffect(() => {
    const taste = (e: KeyboardEvent): void => {
      if (e.key === 'Escape') onSchliessen()
    }
    window.addEventListener('keydown', taste)
    return () => window.removeEventListener('keydown', taste)
  }, [onSchliessen])

  const grund = kind.grundLetzterSchritt
  const grundText = grund
    ? grund.art === 'ueberQuote' || grund.art === 'unterQuote'
      ? grund.richtig !== null && grund.von !== null
        ? tx.t(`schublade.grund.${grund.art}Zahl`, { quote: tx.prozent(grund.quote), richtig: grund.richtig, von: grund.von })
        : tx.t(`schublade.grund.${grund.art}`, { quote: tx.prozent(grund.quote) })
      : grund.art === 'imZiel'
        ? tx.t('schublade.grund.imZiel', { quote: tx.prozent(grund.quote), richtig: grund.richtig, von: grund.von })
        : grund.art === 'eingemischt'
        ? tx.t('schublade.grund.eingemischt', { anteil: tx.prozent(grund.anteil) })
        : tx.t('schublade.grund.tiefer')
    : null

  return (
    <>
      <div className="fixed inset-0 z-20 bg-[var(--color-overlay)]" onClick={onSchliessen} aria-hidden />
      <aside
        role="dialog"
        aria-modal="true"
        aria-label={tx.t('schublade.label')}
        className="fixed inset-x-0 bottom-0 z-30 flex h-[90%] flex-col overflow-hidden rounded-t-[var(--radius-xl)] bg-[var(--color-bg-app)] shadow-xl spalte:inset-y-0 spalte:left-auto spalte:right-0 spalte:h-full spalte:w-[min(580px,100%)] spalte:rounded-l-[var(--radius-xl)] spalte:rounded-tr-none"
      >
        <header className="flex flex-none items-center gap-3 border-b border-[var(--color-border)] bg-[var(--color-bg-surface)] py-3 pl-5 pr-3">
          <AvatarInitials name={kind.name} color="var(--color-primary)" />
          <div className="flex min-w-0 flex-1 flex-col">
            <b className="truncate font-serif text-xl font-medium text-[var(--color-text-primary)]">{kind.name}</b>
            <span className="truncate text-xs text-[var(--color-text-tertiary)]">
              {tx.t('schublade.kopf', { tablet: kind.tablet ?? '–', klasse: kind.klasse, taetigkeit: tx.taetigkeit(kind) })}
            </span>
          </div>
          <button
            type="button"
            onClick={onSchliessen}
            aria-label={tx.t('schublade.schliessen')}
            className="inline-flex h-11 w-11 flex-none items-center justify-center rounded-[var(--radius-md)] text-[var(--color-text-secondary)] hover:bg-[var(--color-bg-subtle)]"
          >
            <X className="h-5 w-5" aria-hidden />
          </button>
        </header>
        <div className="flex flex-1 flex-col gap-4 overflow-auto px-5 pb-8 pt-4">
          {kind.wartet && <WartetBlock kind={kind} />}
          {kind.masteryKandidat && <MasteryPruefung key={kind.id} kind={kind} m={kind.masteryKandidat} />}
          {kind.pfadVorschlag && <PfadEntscheidung kind={kind} p={kind.pfadVorschlag} />}
          <InfoBlock kind={kind} />
          <ZielBlock kind={kind} />
          {kind.erklaersequenz && <SequenzBlock kind={kind} seq={kind.erklaersequenz} />}
          {kind.aufgabe && <AufgabeBlock aufgabe={kind.aufgabe} />}
          {grundText && <p className="text-xs text-[var(--color-text-tertiary)]">{grundText}</p>}
          {kind.versuche.length > 0 && <VersucheBlock kind={kind} />}
          {kind.hinweise.length > 0 && <HinweiseBlock kind={kind} />}
          {(kind.aufgabe || kind.erklaersequenz) && <Interventionsleiter kind={kind} />}
          {kind.heute.length > 0 && <HeuteBlock kind={kind} />}
        </div>
      </aside>
    </>
  )
}
