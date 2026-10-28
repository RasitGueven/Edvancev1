import { useCallback, useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'

import { EdvanceBadge, EdvanceCard, EmptyState, LoadingPulse, ToastBanner } from '@/components/edvance'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { Button } from '@/components/ui/button'
import { ladeFehlbildKatalog, listeStudioSequenzen } from '@/lib/supabase/studio'
import type { StudioSequenz } from '@/types/studio'

import { SequenzAnsicht } from './SequenzAnsicht'
import { SkriptEinfuegen } from './SkriptEinfuegen'
import { FreigabeReiter } from './FreigabeReiter'
import { StimmePanel } from './StimmePanel'
import { StudioVorschau } from './StudioVorschau'

type Meldung = { art: 'success' | 'error'; text: string; id: number }

/**
 * Edvance-Studio (Reihe 1, Bauauftrag B, Anforderung Studio): links die Sequenzen, rechts Skript einfügen
 * oder die gewählte Sequenz. Die Rechte prüft die Datenbank (studio_rolle, Autor ≠ Prüfer).
 */
export function StudioPage(): JSX.Element {
  const { t } = useTranslation('studio')
  const [sequenzen, setSequenzen] = useState<StudioSequenz[] | null>(null)
  const [katalog, setKatalog] = useState<Set<string> | null>(null)
  const [gewaehlt, setGewaehlt] = useState<string | null>(null)
  const [einfuegen, setEinfuegen] = useState(false)
  const [meldung, setMeldung] = useState<Meldung | null>(null)

  const lade = useCallback(async () => {
    const res = await listeStudioSequenzen()
    if (res.error) setMeldung({ art: 'error', text: t('liste.ladeFehler'), id: Date.now() })
    setSequenzen(res.data ?? [])
  }, [t])

  useEffect(() => {
    void lade()
    void ladeFehlbildKatalog().then((r) => setKatalog(r.data))
  }, [lade])

  const aktuell = sequenzen?.find((s) => s.id === gewaehlt) ?? null

  return (
    <div className="flex flex-col gap-6">
      <PageHeader
        titel={t('titel')}
        satz={t('satz')}
        aktionen={
          <Button onClick={() => setEinfuegen(true)} data-testid="studio-einfuegen">
            {t('einfuegen.knopf')}
          </Button>
        }
      />
      {sequenzen === null ? (
        <LoadingPulse type="list" lines={4} />
      ) : (
        <div className="grid grid-cols-1 items-start gap-6 lg:grid-cols-[300px_minmax(0,1fr)]">
          <div className="flex flex-col gap-4" data-testid="studio-liste">
            <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">{t('liste.titel')}</h2>
            {sequenzen.length === 0 ? (
              <EmptyState icon="🎬" title={t('liste.leer')} description={t('liste.leerText')} />
            ) : (
              sequenzen.map((s) => (
                <EdvanceCard
                  key={s.id}
                  variant={s.id === gewaehlt ? 'blue-pale' : 'default'}
                  onClick={() => {
                    setGewaehlt(s.id)
                    setEinfuegen(false)
                  }}
                >
                  <div className="flex flex-col gap-2">
                    <span className="text-base font-semibold">{s.titel}</span>
                    <div className="flex flex-wrap items-center gap-2">
                      <EdvanceBadge variant={s.status === 'freigegeben' ? 'strength' : 'muted'}>{t(`status.${s.status}`)}</EdvanceBadge>
                      <span className="text-xs text-[var(--color-text-muted)]">{s.skillKey}</span>
                    </div>
                  </div>
                </EdvanceCard>
              ))
            )}
          </div>
          {einfuegen ? (
            <SkriptEinfuegen
              katalog={katalog}
              onAbbrechen={() => setEinfuegen(false)}
              onGespeichert={(id) => {
                setEinfuegen(false)
                setGewaehlt(id)
                setMeldung({ art: 'success', text: t('einfuegen.gespeichert'), id: Date.now() })
                void lade()
              }}
            />
          ) : aktuell ? (
            <SequenzAnsicht
              sequenz={aktuell}
              katalog={katalog}
              onGeaendert={() => void lade()}
              zusatz={{
                oben: <StudioVorschau sequenzId={aktuell.id} skript={aktuell.skript} stand={aktuell.geaendertAm} />,
                skript: <StimmePanel sequenzId={aktuell.id} stand={aktuell.geaendertAm} />,
                freigabe: (
                  <FreigabeReiter sequenzId={aktuell.id} skript={aktuell.skript} stand={aktuell.geaendertAm} onGeaendert={() => void lade()} />
                ),
              }}
            />
          ) : (
            <EmptyState icon="👈" title={t('liste.waehlen')} description={t('liste.waehlenText')} />
          )}
        </div>
      )}
      {meldung && <ToastBanner key={meldung.id} type={meldung.art} message={meldung.text} onClose={() => setMeldung(null)} />}
    </div>
  )
}
