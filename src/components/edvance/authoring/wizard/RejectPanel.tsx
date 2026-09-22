// Zurueckweisen: Grund waehlen (Pflicht), optional einen Satz ergaenzen, dann
// "Zurueckweisen und weiter". Inline statt Modal — eine Entscheidung, kein Dialog.
//
// Falsche Einordnung ist KEIN Grund: die wird in Schritt 2 geaendert. Deshalb
// fehlt ein "falsches Thema" in der Liste bewusst.

import { useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { BEANSTANDUNGS_KATEGORIEN } from '@/lib/supabase/freigabe'
import type { BeanstandungsKategorie } from '@/types'
import { ChoiceChip } from './ChoiceChip'

export function RejectPanel({
  busy,
  onReject,
}: {
  busy: boolean
  onReject: (kategorie: BeanstandungsKategorie, notiz: string | null) => void
}): JSX.Element {
  const { t } = useTranslation('authoring')
  const [kategorie, setKategorie] = useState<BeanstandungsKategorie | null>(null)
  const [notiz, setNotiz] = useState('')

  return (
    <div className="flex flex-col gap-4 rounded-[var(--radius-md)] bg-[var(--color-bg-app)] p-4 animate-fade-in">
      <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('reject.title')}
      </span>
      <div className="flex flex-wrap gap-2">
        {BEANSTANDUNGS_KATEGORIEN.map((k) => (
          <ChoiceChip key={k} selected={kategorie === k} onClick={() => setKategorie(k)}>
            {t(`reject.kategorie.${k}`)}
          </ChoiceChip>
        ))}
      </div>
      <Input
        value={notiz}
        onChange={(e) => setNotiz(e.target.value)}
        placeholder={t('reject.notePlaceholder')}
        aria-label={t('reject.notePlaceholder')}
      />
      <Button
        className="self-start"
        disabled={busy || kategorie == null}
        title={kategorie == null ? t('reject.needsReason') : undefined}
        onClick={() => kategorie && onReject(kategorie, notiz.trim() === '' ? null : notiz.trim())}
      >
        {t('reject.confirm')}
      </Button>
      {kategorie == null && (
        <span className="text-xs text-[var(--color-text-tertiary)]">{t('reject.needsReason')}</span>
      )}
    </div>
  )
}
