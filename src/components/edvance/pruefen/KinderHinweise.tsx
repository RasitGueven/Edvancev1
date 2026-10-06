// Pruefkarte, Abschnitt „Hinweise für das Kind“ (Paket L5): die Kinder-Hinweise in Stufenreihenfolge, so wie das
// Kind sie nacheinander abruft, je Stufe mit Statuspille Entwurf/Geprüft. Lena aendert sie wie die uebrigen Felder
// im Entwurf; geprueft werden sie mit der Freigabe der Aufgabe. Die Admin-Pruefansicht zeigt sie lesend.

import { type JSX, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge } from '@/components/edvance'
import { Button } from '@/components/ui'
import type { Bearbeitung } from '@/lib/pruefung/entwurf'
import { hinweisEntfernen, hinweisSetzen, hinweisStatus, MAX_STUFEN, MAX_ZEICHEN } from '@/lib/pruefung/hinweise'
import type { KinderHinweis } from '@/types'
import { GeaendertMarke, InfoTip } from './InfoTip'

const FELD =
  'min-h-[88px] w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-3 text-sm leading-relaxed'

type Props = {
  /** Stand vom Server (pruef_aufgabe.hinweise): liefert den Status unveraenderter Stufen. */
  geladen: KinderHinweis[]
  b: Bearbeitung
  geaendert: boolean
  lesend: boolean
  onChange: (b: Bearbeitung) => void
  onZurueck: () => void
  /** Rechts im Abschnittskopf, z. B. „Hinweise bestätigen“ in der Admin-Pruefansicht. */
  kopfAktion?: ReactNode
  /** Unter der Liste, z. B. der Satz zur Freigabe in der Admin-Pruefansicht. */
  fuss?: ReactNode
}

export function StatusPille({ status }: { status: KinderHinweis['status'] }): JSX.Element {
  const { t } = useTranslation('pruefen')
  return (
    <span title={t(`hinweise.statusInfo.${status}`)}>
      <EdvanceBadge variant={status === 'geprueft' ? 'success' : 'warning'}>{t(`hinweise.status.${status}`)}</EdvanceBadge>
    </span>
  )
}

export function KinderHinweise({ geladen, b, geaendert, lesend, onChange, onZurueck, kopfAktion, fuss }: Props): JSX.Element {
  const { t } = useTranslation('pruefen')
  const texte = b.hinweise
  const setze = (i: number, text: string): void => onChange({ ...b, hinweise: hinweisSetzen(texte, i, text) })

  return (
    <section aria-labelledby="pruef-hinweise" className="flex flex-col gap-3 border-t border-[var(--color-border)] pt-6">
      <h3 id="pruef-hinweise" className="flex flex-wrap items-center gap-2 text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        <span className="inline-flex items-center gap-2">{t('hinweise.titel')} <InfoTip schluessel="hinweise" /></span>
        <GeaendertMarke an={geaendert && !lesend} onZurueck={onZurueck} />
        {kopfAktion && <span className="ml-auto normal-case tracking-normal">{kopfAktion}</span>}
      </h3>
      <p className="text-sm text-[var(--color-text-secondary)]">{t('hinweise.sub')}</p>
      {texte.length === 0 && (
        <p className="text-sm text-[var(--color-text-tertiary)]">{t(lesend ? 'hinweise.keineLesend' : 'hinweise.keine')}</p>
      )}
      <ol className="flex flex-col gap-2">
        {texte.map((text, i) => {
          const stufe = i + 1
          return (
            <li key={stufe} className="flex flex-col gap-2 rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] p-3">
              <div className="flex flex-wrap items-center gap-2">
                <span className="text-xs font-semibold text-[var(--color-text-secondary)]">{t('hinweise.stufe', { stufe })}</span>
                <StatusPille status={hinweisStatus(geladen, stufe, text)} />
                {!lesend && (
                  <Button variant="ghost" size="sm" className="ml-auto" aria-label={t('hinweise.entfernenLabel', { stufe })}
                    onClick={() => onChange({ ...b, hinweise: hinweisEntfernen(texte, i) })}>
                    {t('hinweise.entfernen')}
                  </Button>
                )}
              </div>
              {lesend ? (
                <p className="whitespace-pre-line text-sm leading-relaxed text-[var(--color-text-primary)]">{text}</p>
              ) : (
                <>
                  <textarea aria-label={t('hinweise.feld', { stufe })} placeholder={t('hinweise.platzhalter')} value={text}
                    maxLength={MAX_ZEICHEN} onChange={(e) => setze(i, e.target.value)} className={FELD} />
                  {text.length > MAX_ZEICHEN * 0.8 && (
                    <span className="text-xs text-[var(--color-text-tertiary)]">
                      {t('hinweise.zeichen', { count: text.length, max: MAX_ZEICHEN })}
                    </span>
                  )}
                </>
              )}
            </li>
          )
        })}
      </ol>
      {!lesend && texte.length < MAX_STUFEN && (
        <button type="button" onClick={() => setze(texte.length, '')}
          className="min-h-[44px] self-start rounded-[var(--radius-md)] border border-dashed border-[var(--color-border)] px-3 text-sm text-[var(--color-primary)] hover:border-[var(--color-primary)]">
          {t('hinweise.ergaenzen', { stufe: texte.length + 1 })}
        </button>
      )}
      {fuss}
    </section>
  )
}
