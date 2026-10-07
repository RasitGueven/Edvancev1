// Liste der Kernideen wie die Themenliste der Aufgaben-Pruefung: je Thema eine Karte, darin je Kernidee
// eine Zeile mit Skill, Varianten, Checks und Stand. Fuer Admins dazu die Filter „Bereit zur Freigabe“
// und „Rückfragen“.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { ChevronRight } from 'lucide-react'
import { cn } from '@/lib/utils'
import { EdvanceCard } from '@/components/edvance/EdvanceCard'
import { STAND_FARBE, nachThema, type AdminFilter } from '@/lib/pruefung/erklaerAnzeige'
import type { ErklaerListenZeile } from '@/types/erklaerPruefung'

const FILTER: AdminFilter[] = ['alle', 'bereit', 'rueckfragen']

export function AdminFilterLeiste({ aktiv, zahlen, onFilter }: {
  aktiv: AdminFilter
  zahlen: Record<AdminFilter, number>
  onFilter: (f: AdminFilter) => void
}): JSX.Element {
  const { t } = useTranslation('erklaerPruefen')
  return (
    <div role="tablist" aria-label={t('filter.label')} className="flex flex-wrap gap-2">
      {FILTER.map((f) => (
        <button key={f} type="button" role="tab" aria-selected={f === aktiv} onClick={() => onFilter(f)}
          className={cn('min-h-[44px] rounded-[var(--radius-full)] border px-4 text-sm',
            f === aktiv ? 'border-[var(--color-primary)] bg-[var(--color-primary)] font-semibold text-[var(--color-text-inverse)]'
              : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)] hover:border-[var(--color-primary)]')}>
          {t(`filter.${f}`)} <span className="ml-1 opacity-75">{zahlen[f]}</span>
        </button>
      ))}
    </div>
  )
}

function standText(z: ErklaerListenZeile, t: (k: string) => string, admin: boolean): string {
  if (admin && z.rueckfrage) return t('stand.rueckfrage')
  if (admin && z.bereit) return t('stand.bereit')
  return t(`stand.${z.stand}`)
}

export function ErklaerListe({ zeilen, admin, onOeffnen }: {
  zeilen: ErklaerListenZeile[]
  admin: boolean
  onOeffnen: (kernideeId: string) => void
}): JSX.Element {
  const { t } = useTranslation('erklaerPruefen')
  return (
    <div className="flex flex-col gap-4">
      {nachThema(zeilen).map((g) => {
        const offen = g.zeilen.filter((z) => z.stand === 'offen').length
        return (
          <EdvanceCard key={g.key} className="flex flex-col gap-2 p-4">
            <div className="flex flex-wrap items-baseline justify-between gap-2">
              <h3 className="text-base font-semibold text-[var(--color-text-primary)]">{g.label ?? t('liste.ohneThema')}</h3>
              <span className="text-sm text-[var(--color-text-secondary)]">{t('liste.offen', { count: offen })}</span>
            </div>
            <ul className="flex flex-col border-t border-[var(--color-border)]">
              {g.zeilen.map((z) => (
                <li key={z.kernidee_id}>
                  <button type="button" onClick={() => onOeffnen(z.kernidee_id)}
                    className="flex min-h-[44px] w-full items-center gap-2 border-b border-[var(--color-border)] py-2 text-left text-sm hover:bg-[var(--color-bg-subtle)]">
                    <span className="flex min-w-0 flex-1 flex-col">
                      <span className="font-medium text-[var(--color-text-primary)]">{t('liste.kernidee', { nr: z.nr, titel: z.titel })}</span>
                      <span className="text-xs text-[var(--color-text-tertiary)]">
                        {t('liste.zeile', { skill: z.skill_label, varianten: z.varianten, ist: z.checks, soll: z.checks_soll })}
                      </span>
                    </span>
                    <span className={cn('whitespace-nowrap text-xs font-semibold', admin && z.rueckfrage ? STAND_FARBE.unsicher : STAND_FARBE[z.stand])}>
                      {standText(z, t, admin)}
                    </span>
                    <ChevronRight className="h-4 w-4 shrink-0 text-[var(--color-text-tertiary)]" aria-hidden="true" />
                  </button>
                </li>
              ))}
            </ul>
          </EdvanceCard>
        )
      })}
    </div>
  )
}
