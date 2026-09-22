import { useState } from 'react'
import { MoreHorizontal } from 'lucide-react'
import { useTranslation } from 'react-i18next'

export type CardMenuItem = {
  label: string
  onSelect: () => void
  /** Rot dargestellt: Aktionen, die einen Eintrag aus dem Trichter nehmen. */
  danger?: boolean
}

/** Overflow-Menue einer Board-Karte (Leads und Vertraege). Ohne Eintraege unsichtbar. */
export function CardMenu({ items }: { items: CardMenuItem[] }): JSX.Element | null {
  const { t } = useTranslation('leads')
  const [open, setOpen] = useState(false)
  if (items.length === 0) return null

  return (
    <div
      className="relative shrink-0"
      onBlur={(e) => {
        if (!e.currentTarget.contains(e.relatedTarget as Node | null)) setOpen(false)
      }}
    >
      <button
        type="button"
        aria-label={t('card.moreActions')}
        aria-haspopup="menu"
        aria-expanded={open}
        onClick={() => setOpen((v) => !v)}
        onKeyDown={(e) => {
          if (e.key === 'Escape') setOpen(false)
        }}
        className="rounded-full p-2 text-[var(--color-text-tertiary)] hover:bg-[var(--color-bg-surface)]"
      >
        <MoreHorizontal className="h-5 w-5" />
      </button>
      {open && (
        <div
          role="menu"
          className="absolute right-0 z-10 mt-1 min-w-[10rem] rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-1 shadow-elevation-lg"
        >
          {items.map((item) => (
            <button
              key={item.label}
              type="button"
              role="menuitem"
              onClick={() => {
                setOpen(false)
                item.onSelect()
              }}
              className={`w-full rounded-lg px-3 py-2 text-left text-sm font-medium hover:bg-[var(--color-bg-app)] ${
                item.danger
                  ? 'text-[var(--color-destructive)]'
                  : 'text-[var(--color-text-primary)]'
              }`}
            >
              {item.label}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
