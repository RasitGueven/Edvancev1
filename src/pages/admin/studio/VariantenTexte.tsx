import { useTranslation } from 'react-i18next'

import type { Skript } from '@/studio/skript/typen'

/** Text der Welt neben dem Skelett, Beat für Beat (Anforderung §8.4). Zahlen und Animation sind gesperrt. */
export function VariantenTexte({ skript, welt }: { skript: Skript; welt: string }): JSX.Element {
  const { t } = useTranslation('studio')
  return (
    <div className="grid grid-cols-[48px_1fr_1fr] gap-2 text-sm leading-relaxed" data-testid={`studio-varianten-${welt}`}>
      <span />
      <span className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">{t('freigabe.skelett')}</span>
      <span className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">{t(`welt.${welt}`)}</span>
      {skript.beats.map((b) => (
        <div key={b.id} className="contents">
          <span className="text-xs text-[var(--color-text-muted)]">{b.id}</span>
          <span className="text-[var(--color-text-secondary)]">{b.text.skelett}</span>
          <span className={b.text[welt] ? 'text-[var(--color-text-primary)]' : 'text-[var(--color-text-muted)]'}>
            {b.text[welt] ?? t('freigabe.wieSkelett')}
          </span>
        </div>
      ))}
    </div>
  )
}
