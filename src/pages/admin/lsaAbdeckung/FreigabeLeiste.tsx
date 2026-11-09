import { useCallback, useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'

import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { getLsaAbdeckung, getPruefZielListe } from '@/lib/supabase/lsaAbdeckung'
import { pruefSammel } from '@/lib/supabase/pruefungAdmin'

import { vereinige, wirkung } from './abdeckung'

type Ergebnis = { art: 'success' | 'error'; text: string }

/**
 * Sammelfreigabe (F2 Punkt 6): alles, was Lena für die Prüfliste als „passt“ markiert hat, über
 * pruef_sammel('freigeben') — mit pruef_freigabe_erlaubt und Gate je Aufgabe, nur Admin. Die Zahl im Knopf kommt aus
 * der Vorschau desselben Aufrufs. Danach die Wirkung über alle Pakete (vorher/nachher lsa_abdeckung).
 */
export function FreigabeLeiste({ onFertig }: { onFertig: (e: Ergebnis) => void }): JSX.Element {
  const { t } = useTranslation('admin')
  const [freigabe, setFreigabe] = useState<string[] | null>(null)
  const [busy, setBusy] = useState(false)

  const laden = useCallback(async () => {
    const liste = await getPruefZielListe()
    const gezielt = (liste.data ?? []).filter((z) => z.abschnitt === 'gezielt')
    const ids = vereinige(gezielt.map((z) => z.freigabe_ids))
    if (ids.length === 0) {
      setFreigabe([])
      return
    }
    const vorschau = await pruefSammel('freigeben', ids, {}, true)
    setFreigabe(vorschau.data?.betrifft ?? [])
  }, [])

  useEffect(() => {
    void laden()
  }, [laden])

  const freigeben = async (): Promise<void> => {
    if (!freigabe?.length) return
    setBusy(true)
    const filter = { klasse: null, quartal: null, nurFokus: false }
    const vorher = await getLsaAbdeckung(filter)
    const r = await pruefSammel('freigeben', freigabe, {}, false)
    const nachher = await getLsaAbdeckung(filter)
    setBusy(false)
    if (r.error || !r.data) {
      onFertig({ art: 'error', text: t('lsaAbdeckung.freigabeFehler') })
      return
    }
    const w = wirkung(vorher.data ?? [], nachher.data ?? [])
    onFertig({
      art: 'success',
      text: t('lsaAbdeckung.freigabeErgebnis', { count: r.data.betrifft.length, pakete: w.pakete, schulen: w.schulen }),
    })
    void laden()
  }

  const n = freigabe?.length ?? 0
  return (
    <EdvanceCard variant="subtle" className="flex flex-col gap-4 p-6 md:flex-row md:items-center md:justify-between">
      <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{t('lsaAbdeckung.freigabeSatz')}</p>
      <Button
        disabled={busy || freigabe === null || n === 0}
        title={n === 0 ? t('lsaAbdeckung.freigabeNichts') : undefined}
        onClick={() => void freigeben()}
        data-testid="alles-freigeben"
      >
        {t('lsaAbdeckung.freigabeKnopf', { count: n })}
      </Button>
    </EdvanceCard>
  )
}
