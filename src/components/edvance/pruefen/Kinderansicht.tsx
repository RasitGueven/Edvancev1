// Links in der Pruefansicht: die serverseitige Kinderansicht (task_preview_payload ueber
// AuthoringPreview), darunter der Satz zum Antworttyp (Entscheidung 31). Laeuft ab Laptop-Breite
// beim Scrollen mit; "Bild vergroessern" oeffnet dieselbe Ansicht gross.

import { useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Maximize2 } from 'lucide-react'
import { Modal } from '@/components/edvance/Modal'
import { AuthoringPreview } from '@/components/edvance/authoring/AuthoringPreview'
import { Button } from '@/components/ui'
import { satzZumAntworttyp } from '@/lib/pruefung/texte'
import type { PruefAufgabe } from '@/types'

const KEIN_ENTWURF = {}

export function Kinderansicht({ aufgabe }: { aufgabe: PruefAufgabe }): JSX.Element {
  const { t } = useTranslation('pruefen')
  const [gross, setGross] = useState(false)
  const satz = satzZumAntworttyp(aufgabe.aufgabe)

  return (
    <section className="flex flex-col gap-4 lg:sticky lg:top-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('kind.titel')}
        </h2>
        {aufgabe.aufgabe.bild_vorhanden && (
          <Button variant="secondary" size="sm" onClick={() => setGross(true)}>
            <Maximize2 className="h-4 w-4" aria-hidden="true" />
            {t('kind.bildGross')}
          </Button>
        )}
      </div>
      <AuthoringPreview taskId={aufgabe.task_id} draft={KEIN_ENTWURF} dirty={false} />
      <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
        {t(satz.key, { count: satz.count, einheit: satz.einheit })} {t('kind.danach')}
      </p>
      <Modal open={gross} onClose={() => setGross(false)} title={t('kind.bildTitel')} size="xl">
        <AuthoringPreview taskId={aufgabe.task_id} draft={KEIN_ENTWURF} dirty={false} />
      </Modal>
    </section>
  )
}
