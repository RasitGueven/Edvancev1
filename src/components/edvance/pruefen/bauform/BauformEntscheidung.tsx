// Lenas Entscheidung je Bauform: passt | unsicher | passt nicht, Tasten 1/2/3 wie im Board (1 passt nicht, 2 unsicher,
// 3 passt; useTasten.ts). Unsicher braucht eine Notiz, passt nicht mindestens einen Grund (bauform_pruefen).
import { useEffect, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui'
import { EdvanceCard } from '@/components/edvance'
import type { BauformEntscheidung as Entscheidung } from '@/types/bauformPruefung'

export const GRUENDE = ['rechnung', 'text', 'fehlbild', 'hinweis', 'stufe', 'figur'] as const

type Props = {
  aktiv: boolean
  busy: boolean
  onEntscheide: (e: Entscheidung, gruende: string[], notiz: string | null) => void
}

export function BauformEntscheidung({ aktiv, busy, onEntscheide }: Props): JSX.Element {
  const { t } = useTranslation('bauformPruefen')
  const [gruende, setGruende] = useState<string[]>([])
  const [notiz, setNotiz] = useState('')
  const kannUnsicher = notiz.trim() !== ''
  const kannNicht = gruende.length > 0

  useEffect(() => {
    if (!aktiv) return
    const taste = (e: KeyboardEvent): void => {
      const ziel = e.target as HTMLElement | null
      if (ziel && ['INPUT', 'TEXTAREA'].includes(ziel.tagName)) return
      if (e.key === '3') onEntscheide('passt', [], notiz.trim() || null)
      if (e.key === '2' && kannUnsicher) onEntscheide('unsicher', [], notiz.trim())
      if (e.key === '1' && kannNicht) onEntscheide('passt_nicht', gruende, notiz.trim() || null)
    }
    window.addEventListener('keydown', taste)
    return () => window.removeEventListener('keydown', taste)
  }, [aktiv, gruende, notiz, kannUnsicher, kannNicht, onEntscheide])

  return (
    <EdvanceCard className="flex flex-col gap-4">
      <div className="flex items-baseline justify-between">
        <h2 className="text-base font-semibold text-[var(--color-text-primary)]">{t('entscheidung.titel')}</h2>
        <span className="text-xs text-[var(--color-text-muted)]">{t('entscheidung.tasten')}</span>
      </div>
      <fieldset className="flex flex-col gap-2">
        <legend className="text-sm text-[var(--color-text-secondary)]">{t('entscheidung.gruende')}</legend>
        <div className="flex flex-wrap gap-2">
          {GRUENDE.map((g) => (
            <label key={g} className="flex min-h-[44px] items-center gap-2 rounded-[var(--radius-md)] border border-[var(--color-border)] px-3 text-sm">
              <input type="checkbox" checked={gruende.includes(g)} disabled={!aktiv}
                onChange={() => setGruende((x) => (x.includes(g) ? x.filter((y) => y !== g) : [...x, g]))} />
              {t(`entscheidung.grund.${g}`)}
            </label>
          ))}
        </div>
      </fieldset>
      <label className="flex flex-col gap-2 text-sm text-[var(--color-text-secondary)]">
        {t('entscheidung.notiz')}
        <textarea rows={2} value={notiz} disabled={!aktiv} placeholder={t('entscheidung.notizPlatzhalter')}
          onChange={(e) => setNotiz(e.target.value)}
          className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-2 text-sm text-[var(--color-text-primary)]" />
      </label>
      <div className="flex flex-wrap justify-end gap-2">
        <Button variant="outline" disabled={!aktiv || busy || !kannNicht} title={kannNicht ? undefined : t('entscheidung.gruende')}
          onClick={() => onEntscheide('passt_nicht', gruende, notiz.trim() || null)}>{t('entscheidung.passt_nicht')}</Button>
        <Button variant="outline" disabled={!aktiv || busy || !kannUnsicher} title={kannUnsicher ? undefined : t('entscheidung.notizPlatzhalter')}
          onClick={() => onEntscheide('unsicher', [], notiz.trim())}>{t('entscheidung.unsicher')}</Button>
        <Button disabled={!aktiv || busy} onClick={() => onEntscheide('passt', [], notiz.trim() || null)}>{t('entscheidung.passt')}</Button>
      </div>
    </EdvanceCard>
  )
}
