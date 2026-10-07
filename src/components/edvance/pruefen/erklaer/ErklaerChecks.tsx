// Mini-Checks einer Kernidee: je Check-Aufgabe die Kinderansicht (serverseitig ueber AuthoringPreview, wie
// in der Aufgaben-Pruefung), ihr Pruefstand und ein Link zu ihrer Aufgaben-Pruefung. Darunter die
// Denkfehler der Fertigkeit und welche Variante fuer welchen gedacht ist.

import type { JSX } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge } from '@/components/edvance/EdvanceBadge'
import { EdvanceCard } from '@/components/edvance/EdvanceCard'
import { AuthoringPreview } from '@/components/edvance/authoring/AuthoringPreview'
import type { ErklaerDetail } from '@/types/erklaerPruefung'

const KEIN_ENTWURF = {}

type Props = { detail: ErklaerDetail; aufgabenPfad: (taskId: string) => string }

export function ErklaerChecks({ detail, aufgabenPfad }: Props): JSX.Element {
  const { t } = useTranslation('erklaerPruefen')
  const zaehlen = detail.checks.filter((c) => c.zaehlt).length

  return (
    <section className="flex flex-col gap-4">
      <div className="flex flex-wrap items-baseline justify-between gap-2">
        <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('checks.titel')}</h2>
        <span className="text-sm text-[var(--color-text-secondary)]">{t('checks.soll', { ist: zaehlen, soll: detail.checks_soll })}</span>
      </div>
      {detail.checks.length === 0 && <p className="text-sm text-[var(--color-text-secondary)]">{t('checks.leer')}</p>}
      {detail.checks.map((c) => (
        <EdvanceCard key={c.task_id} className="flex flex-col gap-4">
          <div className="flex flex-wrap items-center gap-2">
            <span className="min-w-0 flex-1 text-base font-semibold">{t('checks.nr', { nr: c.reihenfolge, titel: c.titel })}</span>
            <EdvanceBadge variant={c.zaehlt ? 'strength' : 'warning'}>
              {c.zaehlt ? t('checks.zaehlt') : !c.einsatz_check ? t('checks.ohneEinsatz') : !c.aktiv ? t('checks.inaktiv') : t('checks.nichtFrei')}
            </EdvanceBadge>
            {c.lena_status && <EdvanceBadge variant="muted">{t(`checks.lena.${c.lena_status}`)}</EdvanceBadge>}
          </div>
          <AuthoringPreview taskId={c.task_id} draft={KEIN_ENTWURF} dirty={false} />
          <Link to={aufgabenPfad(c.task_id)}
            className="min-h-[44px] content-center self-start text-sm font-semibold text-[var(--color-text-link)] hover:underline">
            {t('checks.zurPruefung')}
          </Link>
        </EdvanceCard>
      ))}
      <div className="flex flex-col gap-2">
        <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('fehlbilder.titel')}</h2>
        {detail.fehlbilder.length === 0 && <p className="text-sm text-[var(--color-text-secondary)]">{t('fehlbilder.leer')}</p>}
        <ul className="flex flex-col">
          {detail.fehlbilder.map((f) => {
            const varianten = detail.schritte
              .filter((s) => s.art === 'erklaerung' && s.fehlbild_slugs.includes(f.slug)).map((s) => s.variante)
            return (
              <li key={f.slug} className="flex min-h-[44px] flex-wrap items-center gap-2 border-b border-[var(--color-border)] py-2 text-sm">
                <span className="min-w-0 flex-1 text-[var(--color-text-primary)]">{f.klartext ?? f.slug}</span>
                <span className="text-xs text-[var(--color-text-tertiary)]">{t('fehlbilder.aufgaben', { count: f.aufgaben })}</span>
                <span className={varianten.length ? 'text-xs font-semibold text-[var(--color-primary)]' : 'text-xs text-[var(--color-warning)]'}>
                  {varianten.length ? t('fehlbilder.variante', { varianten: varianten.join(', ') }) : t('fehlbilder.ohneVariante')}
                </span>
              </li>
            )
          })}
        </ul>
      </div>
    </section>
  )
}
