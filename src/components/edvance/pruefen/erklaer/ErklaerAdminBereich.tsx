// Admin-Teil der Detailseite (L6.3): Lenas Ergebnis, was zur Freigabe fehlt, Freigeben, Ruecknahme mit
// Grund und die Antwort auf Lenas Rueckfrage. Ein primaerer CTA: „Freigeben“; die Ruecknahme oeffnet
// sich inline (keine Modals fuer einfache Bestaetigungen).

import { useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui'
import { EdvanceCard } from '@/components/edvance/EdvanceCard'
import { berlinZeit, fehltText } from '@/lib/pruefung/erklaerAnzeige'
import type { ErklaerDetail, ErklaerFehlt, ErklaerProtokollZeile } from '@/types/erklaerPruefung'

const LENA = ['passt', 'unsicher', 'passt_nicht', 'zurueckgenommen', 'freigabe_zurueck']

type Props = {
  detail: ErklaerDetail
  arbeitet: boolean
  fehler: string | null
  /** Liste aus dem letzten Freigabe-Fehler; sonst gilt detail.freigabe_fehlt. */
  fehltAusFehler: ErklaerFehlt[] | null
  onFreigeben: () => void
  onZuruecknehmen: (grund: string) => void
  onAntworten: (antwort: string) => void
}

export function FehltListe({ liste }: { liste: ErklaerFehlt[] }): JSX.Element {
  const { t } = useTranslation('erklaerPruefen')
  return (
    <ul className="ml-5 list-disc text-sm text-[var(--color-text-primary)]" data-testid="freigabe-fehlt">
      {liste.map((f, i) => {
        const { key, werte } = fehltText(f)
        return <li key={i}>{t(key, { ...werte, art: 'art' in werte ? t(`art.${String(werte.art)}`) : '' })}</li>
      })}
    </ul>
  )
}

function LenasErgebnis({ zeile }: { zeile: ErklaerProtokollZeile | undefined }): JSX.Element {
  const { t, i18n } = useTranslation('erklaerPruefen')
  if (!zeile) return <p className="text-sm text-[var(--color-text-secondary)]">{t('admin.lenaOffen')}</p>
  return (
    <div className="flex flex-col gap-1 text-sm">
      <span className="font-semibold">
        {t(`protokoll.art.${zeile.entscheidung}`)} · {t('protokoll.wer', { von: zeile.von ?? t('protokoll.system'), am: berlinZeit(zeile.am, i18n.language) })}
      </span>
      {zeile.gruende.length > 0 && <span className="text-[var(--color-text-secondary)]">{zeile.gruende.map((g) => t(`gruende.${g}`)).join(' · ')}</span>}
      {zeile.notiz && <span className="text-[var(--color-text-secondary)]">{t('protokoll.notiz', { notiz: zeile.notiz })}</span>}
      {zeile.antwort && <span className="text-[var(--color-primary)]">{t('protokoll.antwort', { von: zeile.beantwortet_von ?? '', antwort: zeile.antwort })}</span>}
    </div>
  )
}

export function ErklaerAdminBereich(p: Props): JSX.Element {
  const { t } = useTranslation('erklaerPruefen')
  const [offen, setOffen] = useState<'zurueck' | 'antwort' | null>(null)
  const [text, setText] = useState('')
  const k = p.detail.kernidee
  const fehlt = p.fehltAusFehler ?? p.detail.freigabe_fehlt
  const lena = p.detail.protokoll.find((z) => LENA.includes(z.entscheidung))
  const nichtsZuTun = k.status === 'freigegeben' && p.detail.schritte.every((s) => s.status === 'freigegeben')
  const sperre = nichtsZuTun ? t('admin.schonFrei') : fehlt.length > 0 ? t('admin.fehltTip') : null

  const absenden = (): void => {
    if (!text.trim()) return
    if (offen === 'zurueck') p.onZuruecknehmen(text)
    else p.onAntworten(text)
  }

  return (
    <EdvanceCard className="flex flex-col gap-4" >
      <div className="flex flex-col gap-2">
        <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('admin.lena')}</h2>
        <LenasErgebnis zeile={lena} />
      </div>
      {!nichtsZuTun && fehlt.length > 0 && (
        <div className="flex flex-col gap-2 rounded-[var(--radius-md)] border border-[var(--color-warning)] bg-[var(--color-warning-light)] p-4" aria-live="polite">
          <span className="text-sm font-semibold text-[var(--color-warning)]">{t('admin.fehltTitel')}</span>
          <FehltListe liste={fehlt} />
        </div>
      )}
      {p.fehler && <p role="alert" className="text-sm text-[var(--color-destructive)]">{p.fehler}</p>}
      {offen && (
        <div className="flex flex-col gap-2">
          <label htmlFor="erklaer-admin-text" className="text-sm font-semibold">
            {t(offen === 'zurueck' ? 'admin.grundTitel' : 'admin.antwortTitel')}
          </label>
          <textarea id="erklaer-admin-text" autoFocus rows={2} value={text} onChange={(e) => setText(e.target.value)}
            placeholder={t(offen === 'zurueck' ? 'admin.grundPlatzhalter' : 'admin.antwortPlatzhalter')}
            className="w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-3 text-sm" />
          <div className="flex flex-wrap justify-end gap-2">
            <Button variant="ghost" size="sm" onClick={() => { setOffen(null); setText('') }}>{t('leiste.abbrechen')}</Button>
            <Button size="sm" variant={offen === 'zurueck' ? 'destructive' : 'default'} loading={p.arbeitet}
              disabled={!text.trim()} title={!text.trim() ? t('admin.textFehlt') : undefined} onClick={absenden}>
              {t(offen === 'zurueck' ? 'admin.zuruecknehmen' : 'admin.antwortSenden')}
            </Button>
          </div>
        </div>
      )}
      <div className="flex flex-wrap gap-2">
        <span title={sperre ?? undefined}>
          <Button loading={p.arbeitet} disabled={!!sperre} onClick={p.onFreigeben}>{t('admin.freigeben')}</Button>
        </span>
        {k.status === 'freigegeben' && !offen && (
          <Button variant="secondary" onClick={() => setOffen('zurueck')}>{t('admin.zuruecknehmenOeffnen')}</Button>
        )}
        {k.rueckfrage && !offen && (
          <Button variant="secondary" onClick={() => setOffen('antwort')}>{t('admin.antworten')}</Button>
        )}
      </div>
    </EdvanceCard>
  )
}
