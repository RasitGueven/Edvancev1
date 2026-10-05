// Kopf der Admin-Pruefansicht (Bauauftrag B 4): Kopfzeile wie bei Lena, Kurztitel, Thema · Fertigkeit, die Reihe
// mit Herkunft und „x von y“, dazu Zurueck, Ueberspringen, Im Editor oeffnen, Schliessen. Der Pilot-Schalter
// erscheint nur, wenn die Aufgabe bei Lena erscheinen kann.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { ArrowLeft, ArrowRight, PenLine, X } from 'lucide-react'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui'
import { KopfMeta } from '@/components/edvance/pruefen/PruefKopf'
import { Taste } from '@/components/edvance/pruefen/InfoTip'
import type { PruefAufgabe } from '@/types'

type Props = {
  aufgabe: PruefAufgabe
  reihe: { label: string; nr: number; anzahl: number } | null
  hatVorige: boolean
  pilot: { an: boolean; sichtbar: boolean; arbeitet: boolean }
  onZurueck: () => void
  onUeberspringen: () => void
  onEditor: () => void
  onSchliessen: () => void
  onPilot: (an: boolean) => void
}

export function AdminKopf({ aufgabe, reihe, hatVorige, pilot, ...on }: Props): JSX.Element {
  const { t } = useTranslation('pruefenAdmin')
  const f = aufgabe.fertigkeit
  const thema = f?.thema_label ?? aufgabe.kopf.thema_label
  const anteil = reihe ? (reihe.nr / reihe.anzahl) * 100 : 0
  return (
    <EdvanceCard className="flex flex-col gap-3">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div className="flex min-w-0 flex-col gap-1">
          <KopfMeta aufgabe={aufgabe} />
          <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">{aufgabe.kopf.kurztitel}</h1>
          {(thema || f) && (
            <p className="text-sm text-[var(--color-text-secondary)]">
              {thema && f ? t('kopf.themaFertigkeit', { thema, fertigkeit: f.label }) : (thema ?? f?.label)}
            </p>
          )}
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <span title={hatVorige ? undefined : t(reihe ? 'kopf.ersteAufgabe' : 'kopf.keineReihe')}>
            <Button variant="outline" disabled={!hatVorige} onClick={on.onZurueck}>
              <ArrowLeft className="h-4 w-4" aria-hidden="true" /> {t('kopf.zurueck')} <Taste>←</Taste>
            </Button>
          </span>
          <Button variant="outline" onClick={on.onUeberspringen}>
            {t('kopf.ueberspringen')} <ArrowRight className="h-4 w-4" aria-hidden="true" /> <Taste>→</Taste>
          </Button>
          <Button variant="outline" onClick={on.onEditor}>
            <PenLine className="h-4 w-4" aria-hidden="true" /> {t('kopf.editor')} <Taste>E</Taste>
          </Button>
          <Button size="icon" variant="ghost" aria-label={t('kopf.schliessen')} title={t('kopf.schliessen')} onClick={on.onSchliessen}>
            <X className="h-5 w-5" aria-hidden="true" />
          </Button>
        </div>
      </div>
      <div className="flex flex-wrap items-center gap-x-3 gap-y-2 text-sm text-[var(--color-text-secondary)]">
        <span>{reihe ? reihe.label : t('kopf.einzeln')}</span>
        {reihe && (
          <>
            <span aria-hidden="true">·</span>
            <span className="font-semibold text-[var(--color-text-primary)]">{t('kopf.position', { nr: reihe.nr, anzahl: reihe.anzahl })}</span>
            <div className="h-1 w-24 overflow-hidden rounded-[var(--radius-full)] bg-[var(--color-bg-subtle)]" role="progressbar"
              aria-valuemin={0} aria-valuemax={reihe.anzahl} aria-valuenow={reihe.nr}>
              <div className="h-full bg-[var(--color-gold-altgold)] transition-[width]" style={{ width: `${anteil}%` }} />
            </div>
          </>
        )}
        {pilot.sichtbar && (
          <label className="ml-auto flex min-h-[44px] cursor-pointer items-center gap-2 font-semibold text-[var(--color-text-primary)]">
            <input type="checkbox" role="switch" className="h-5 w-5 accent-[var(--color-primary)]" checked={pilot.an}
              disabled={pilot.arbeitet} onChange={(e) => on.onPilot(e.target.checked)} />
            {t('kopf.pilot')}
          </label>
        )}
      </div>
    </EdvanceCard>
  )
}
