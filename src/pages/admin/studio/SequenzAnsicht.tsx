import { useCallback, useEffect, useState, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'

import { EdvanceBadge, EmptyState, LoadingPulse, Reiterleiste, type Reiter } from '@/components/edvance'
import { ladeStudioWelten } from '@/lib/supabase/studio'
import type { StudioSequenz, StudioWeltStand } from '@/types/studio'

import { BeatEditor } from './BeatEditor'
import { MiniCheckReiter } from './MiniCheckReiter'

export type SequenzReiter = 'skript' | 'minicheck' | 'freigabe'

/**
 * Sequenzkopf und Reiter Skript, Mini-Check, Freigabe. Weitere Phasen hängen ihre Teile über `zusatz` an
 * (Vorschau B3, Stimme B2, Render B4, Freigabe B5), ohne diese Datei zu verbreitern.
 */
export function SequenzAnsicht({
  sequenz,
  katalog,
  onGeaendert,
  zusatz,
}: {
  sequenz: StudioSequenz
  katalog: ReadonlySet<string> | null
  onGeaendert: () => void
  zusatz?: Partial<Record<SequenzReiter | 'oben', ReactNode>>
}): JSX.Element {
  const { t } = useTranslation('studio')
  const [reiter, setReiter] = useState<SequenzReiter>('skript')
  const [welten, setWelten] = useState<StudioWeltStand[] | null>(null)

  const lade = useCallback(async () => {
    const res = await ladeStudioWelten(sequenz.id)
    setWelten(res.data ?? [])
  }, [sequenz.id])
  useEffect(() => {
    void lade()
  }, [lade, sequenz.version])

  const liste: Reiter<SequenzReiter>[] = [
    { key: 'skript', titel: t('reiter.skript'), anzahl: sequenz.skript.beats.length },
    { key: 'minicheck', titel: t('reiter.minicheck'), anzahl: sequenz.skript.minichecks.length },
    { key: 'freigabe', titel: t('reiter.freigabe') },
  ]
  const gesperrt = (welten ?? []).filter((w) => w.gesperrt)

  return (
    <div className="flex min-w-0 flex-col gap-6" data-testid="studio-sequenz">
      <div className="flex flex-col gap-2">
        <div className="flex flex-wrap items-center gap-2">
          <h2 className="text-2xl font-bold text-[var(--text-primary)]">{sequenz.titel}</h2>
          <EdvanceBadge variant={sequenz.status === 'freigegeben' ? 'strength' : 'muted'}>{t(`status.${sequenz.status}`)}</EdvanceBadge>
        </div>
        <p className="text-xs text-[var(--color-text-muted)]">
          {[t('kopf.skill', { skill: sequenz.skillKey }), t('kopf.version', { version: sequenz.version }),
            t('kopf.beats', { count: sequenz.skript.beats.length }), sequenz.welten.map((w) => t(`welt.${w}`)).join(' · ')].join(' · ')}
        </p>
        {gesperrt.length > 0 && (
          <div className="flex flex-wrap gap-2">
            {gesperrt.map((w) => (
              <EdvanceBadge key={w.welt} variant="warning">
                {t(`welt.${w.welt}`)} · {t('kopf.gesperrt')}
              </EdvanceBadge>
            ))}
          </div>
        )}
      </div>
      {zusatz?.oben}
      <Reiterleiste reiter={liste} aktiv={reiter} onWechsel={setReiter} label={t('reiter.label')} />
      {welten === null ? (
        <LoadingPulse type="list" lines={4} />
      ) : reiter === 'skript' ? (
        <>
          {zusatz?.skript}
          <BeatEditor
            key={`${sequenz.id}-${sequenz.geaendertAm}`}
            sequenzId={sequenz.id}
            skript={sequenz.skript}
            welten={welten}
            katalog={katalog}
            onGespeichert={onGeaendert}
          />
        </>
      ) : reiter === 'minicheck' ? (
        <>
          {zusatz?.minicheck}
          <MiniCheckReiter skript={sequenz.skript} />
        </>
      ) : (
        zusatz?.freigabe ?? <EmptyState icon="✅" title={t('freigabe.folgt')} description={t('freigabe.folgtText')} />
      )}
    </div>
  )
}
