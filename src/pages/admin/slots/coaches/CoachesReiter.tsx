import { useEffect, useRef, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceCard, EmptyState, LoadingPulse, ToastBanner, WochenNavigation } from '@/components/edvance'
import type { SlotsCoaches } from '@/types/slotplan'
import type { Geladen } from '../useSlotsLaden'
import { sucheMitPanel } from '../wochenplan/wochenplan.model'
import { bloeckeBilden, type Block, type CoachDaten } from './coaches.model'
import { CoachKarte } from './CoachKarte'
import { SchichtEintragen } from './SchichtEintragen'
import { RaumWechselDialog } from './RaumWechselDialog'
import { EntfernenDialog } from './EntfernenDialog'

type Dialog = { art: 'raum' | 'weg'; coach: CoachDaten; block: Block } | null

/**
 * Reiter Coaches (Bauauftrag Slots-Wochenplan v2, W4): je Coach eine Karte mit den Schichten als Blöcke, daneben
 * „Schicht eintragen“. „Raum ändern“ und „Entfernen“ öffnen je einen Dialog. Die Blöcke gelten für die gewählte Woche.
 */
export function CoachesReiter({ coaches, montag, onWoche }: { coaches: Geladen<SlotsCoaches>; montag: string; onWoche: (m: string) => void }): JSX.Element {
  const { t } = useTranslation('slots')
  const [suche] = useSearchParams()
  const [dialog, setDialog] = useState<Dialog>(null)
  const [meldung, setMeldung] = useState<string | null>(null)
  const d = coaches.daten

  // Schließt sich ein Slot-Panel (Abweichung geöffnet), können sich Vertretung oder Ausfall geändert haben.
  const slot = suche.get('slot')
  const warOffen = useRef(slot)
  const { neuLaden } = coaches
  useEffect(() => {
    if (warOffen.current && !slot) neuLaden()
    warOffen.current = slot
  }, [slot, neuLaden])

  if (!d) return coaches.fehler ? <p className="text-sm text-[var(--color-text-secondary)]">{t(coaches.fehler)}</p> : <LoadingPulse type="list" lines={5} />
  if (d.coaches.length === 0) {
    return <EdvanceCard><EmptyState icon="🧑‍🏫" title={t('coaches.leerTitel')} description={t('coaches.leerText')} /></EdvanceCard>
  }

  const gespeichert = (m: string): void => {
    setDialog(null)
    setMeldung(m)
    coaches.neuLaden()
  }
  const panelZiel = (datum: string, zeitId: string): { search: string } => ({
    search: `?${sucheMitPanel(suche, { art: 'slot', datum, zeitId }).toString()}`,
  })

  return (
    <div className="@container flex flex-col gap-6">
      <WochenNavigation montag={montag} onWechsel={onWoche} pfeiltasten={false} />
      <div className="grid grid-cols-1 items-start gap-6 @slots-coaches:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]">
        <div className="flex min-w-0 flex-col gap-4">
          {d.coaches.map((c) => (
            <CoachKarte
              key={c.id}
              coach={c}
              bloecke={bloeckeBilden(c.stammschichten, d.zeiten, d.montag)}
              kw={d.kw}
              panelZiel={panelZiel}
              onRaumAendern={(block) => setDialog({ art: 'raum', coach: c, block })}
              onEntfernen={(block) => setDialog({ art: 'weg', coach: c, block })}
            />
          ))}
        </div>
        <SchichtEintragen daten={d} onGespeichert={gespeichert} />
      </div>

      {dialog?.art === 'raum' && (
        <RaumWechselDialog coach={dialog.coach} block={dialog.block} daten={d} onClose={() => setDialog(null)} onGespeichert={gespeichert} />
      )}
      {dialog?.art === 'weg' && (
        <EntfernenDialog coach={dialog.coach} block={dialog.block} onClose={() => setDialog(null)} onGespeichert={gespeichert}
          onTeilweise={coaches.neuLaden} />
      )}
      {meldung && <ToastBanner type="success" message={meldung} onClose={() => setMeldung(null)} />}
    </div>
  )
}
