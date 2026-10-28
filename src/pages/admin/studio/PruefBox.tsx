import { useState } from 'react'
import { useTranslation } from 'react-i18next'

import { Button } from '@/components/ui/button'

import { FELD } from './felder'

/**
 * Zwei Antworten einer Prüfung: „passt“ (primär) oder „passt nicht“ an einem Beat mit Kommentar (inline, kein Modal).
 * Gesperrt mit Grund als Tooltip, z. B. für den Autor (die Datenbank lehnt es zusätzlich ab).
 */
export function PruefBox({
  beats,
  passtText,
  passtNichtText,
  gesperrt,
  onPasst,
  onPasstNicht,
}: {
  beats: { key: string; titel: string }[]
  passtText: string
  passtNichtText: string
  gesperrt: string | null
  onPasst: () => void
  onPasstNicht: (beat: string, kommentar: string) => void
}): JSX.Element {
  const { t } = useTranslation('studio')
  const [offen, setOffen] = useState(false)
  const [beat, setBeat] = useState(beats[0]?.key ?? '')
  const [kommentar, setKommentar] = useState('')
  if (offen)
    return (
      <div className="flex flex-col gap-2">
        <label className="flex flex-col gap-2 text-xs text-[var(--color-text-muted)]">
          {t('freigabe.beat')}
          <select className={FELD} value={beat} onChange={(e) => setBeat(e.target.value)}>
            {beats.map((b) => (
              <option key={b.key} value={b.key}>
                {b.key} · {b.titel}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-2 text-xs text-[var(--color-text-muted)]">
          {t('freigabe.kommentar')}
          <textarea className={`${FELD} min-h-[64px]`} value={kommentar} onChange={(e) => setKommentar(e.target.value)} />
        </label>
        <div className="flex flex-wrap gap-2">
          <Button
            disabled={kommentar.trim() === ''}
            title={kommentar.trim() === '' ? t('freigabe.kommentar') : undefined}
            onClick={() => {
              onPasstNicht(beat, kommentar.trim())
              setOffen(false)
              setKommentar('')
            }}
          >
            {t('freigabe.senden')}
          </Button>
          <Button variant="ghost" onClick={() => setOffen(false)}>
            {t('freigabe.abbrechen')}
          </Button>
        </div>
      </div>
    )
  return (
    <div className="flex flex-wrap gap-2">
      <Button disabled={gesperrt !== null} title={gesperrt ?? undefined} onClick={onPasst}>
        {passtText}
      </Button>
      <Button variant="secondary" disabled={gesperrt !== null} title={gesperrt ?? undefined} onClick={() => setOffen(true)}>
        {passtNichtText}
      </Button>
    </div>
  )
}
