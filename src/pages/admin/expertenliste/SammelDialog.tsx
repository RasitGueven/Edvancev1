// Vorschau-Dialog einer Sammelaktion (Bauauftrag E 18, Anforderung F 31–36). Vorschau und Ausfuehrung sind
// derselbe Serveraufruf (pruef_sammel, einmal mit nur_vorschau). Der Dialog zeigt „Betrifft k“ und „Ausgelassen m“,
// nach Grund gruppiert und aufklappbar, dazu die Eingaben. Bestaetigen nennt die Zahl und ist bei 0 gesperrt; ab
// 100 Betroffenen braucht es ein zweites Bestaetigen.

import { useEffect, useMemo, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Modal } from '@/components/edvance/Modal'
import { Button } from '@/components/ui'
import { cn } from '@/lib/utils'
import type { FertigkeitWahl } from '@/lib/authoring/auswahl'
import { adminFehler, auslassText, nachGrund, uebersetze } from '@/lib/pruefung/adminTexte'
import { pruefSammel } from '@/lib/supabase/pruefungAdmin'
import type { PruefAdminZeile, SammelAktion, SammelErgebnis, SammelWerte } from '@/types'

export const ZWEITES_BESTAETIGEN_AB = 100

type Props = {
  aktion: SammelAktion
  ids: string[]
  /** Kurztitel und Thema je Aufgabe, fuer die aufklappbaren Listen. */
  zeile: (id: string) => { titel: string; thema: string }
  lena: Map<string, PruefAdminZeile>
  fertigkeiten: FertigkeitWahl[]
  onClose: () => void
  onFertig: (ergebnis: SammelErgebnis, aktion: SammelAktion) => void
}

const FELD = 'min-h-[44px] w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm'

export function SammelDialog({ aktion, ids, zeile, lena, fertigkeiten, onClose, onFertig }: Props): JSX.Element {
  const { t } = useTranslation('pruefenAdmin')
  const [werte, setWerte] = useState<SammelWerte>({})
  const [vorschau, setVorschau] = useState<SammelErgebnis | null>(null)
  const [laedt, setLaedt] = useState(false)
  const [fehler, setFehler] = useState<string | null>(null)
  const [geprueft, setGeprueft] = useState(false)
  const brauchtWahl = (aktion === 'fertigkeit' && !werte.skill_key) || (aktion === 'afb' && !werte.afb)
  const schluessel = aktion === 'fertigkeit' ? werte.skill_key : aktion === 'afb' ? werte.afb : ''

  useEffect(() => {
    if (brauchtWahl) return
    let aktiv = true
    setLaedt(true)
    void pruefSammel(aktion, ids, aktion === 'fertigkeit' || aktion === 'afb' ? werte : {}, true).then((r) => {
      if (!aktiv) return
      setLaedt(false)
      setVorschau(r.data)
      setFehler(r.error ? uebersetze(t, adminFehler(r.error) ?? { key: 'pruefen:fehlermeldung.allgemein' }) : null)
    })
    return () => {
      aktiv = false
    }
    // Die Vorschau haengt nur an Aktion, Auswahl und dem gewaehlten Wert, nicht an Grund oder Nachricht.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [aktion, ids, schluessel, brauchtWahl])

  const betrifft = vorschau && !brauchtWahl ? vorschau.betrifft : []
  const gruppen = useMemo(() => (vorschau && !brauchtWahl ? nachGrund(vorschau.ausgelassen) : []), [vorschau, brauchtWahl])
  const schonBewertet = aktion === 'fertigkeit' || aktion === 'afb'
    ? betrifft.filter((id) => lena.get(id)?.lena_status === 'passt' && !lena.get(id)?.geaendert).length : 0
  const grosse = betrifft.length >= ZWEITES_BESTAETIGEN_AB
  const grundFehlt = aktion === 'ausschliessen' && !werte.grund?.trim()
  const sperre = betrifft.length === 0 ? t('sammel.keineBetroffen')
    : grundFehlt ? t('sammel.grundPflicht') : grosse && !geprueft ? t('sammel.erstPruefen') : null

  const ausfuehren = async (): Promise<void> => {
    if (sperre) return
    setLaedt(true)
    const r = await pruefSammel(aktion, ids, werte, false)
    setLaedt(false)
    if (r.error || !r.data) {
      setFehler(uebersetze(t, adminFehler(r.error) ?? { key: 'pruefen:fehlermeldung.allgemein' }))
      return
    }
    onFertig(r.data, aktion)
  }

  const liste = (teil: string[]): JSX.Element => (
    <ul className="flex flex-col gap-1 pl-4 text-sm text-[var(--color-text-secondary)]">
      {teil.map((id) => {
        const z = zeile(id)
        return <li key={id}>{z.titel} <span className="text-[var(--color-text-tertiary)]">· {z.thema}</span></li>
      })}
    </ul>
  )

  return (
    <Modal open onClose={onClose} title={t(`sammel.titel.${aktion}`, { count: ids.length })} size="lg"
      footer={(
        <div className="flex flex-wrap justify-end gap-2">
          <Button variant="ghost" onClick={onClose}>{t('leiste.abbrechen')}</Button>
          <span title={sperre ?? undefined}>
            <Button loading={laedt} disabled={!!sperre || brauchtWahl} onClick={() => void ausfuehren()}>
              {t(`sammel.knopf.${aktion}`, { count: betrifft.length })}
            </Button>
          </span>
        </div>
      )}>
      <div className="flex flex-col gap-4">
        <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{t(`sammel.lead.${aktion}`)}</p>
        {aktion === 'fertigkeit' && (
          <label className="flex flex-col gap-2 text-sm font-semibold">
            {t('sammel.fertigkeit')}
            <select className={FELD} value={werte.skill_key ?? ''} onChange={(e) => setWerte({ ...werte, skill_key: e.target.value || undefined })}>
              <option value="">{t('sammel.bitteWaehlen')}</option>
              {[...new Set(fertigkeiten.map((f) => f.gruppe))].map((g) => (
                <optgroup key={g} label={g}>
                  {fertigkeiten.filter((f) => f.gruppe === g).map((f) => <option key={f.key} value={f.key}>{f.label}</option>)}
                </optgroup>
              ))}
            </select>
          </label>
        )}
        {aktion === 'afb' && (
          <div role="group" aria-label={t('sammel.afb')} className="flex flex-wrap gap-2">
            {(['I', 'II', 'III'] as const).map((x) => (
              <button key={x} type="button" aria-pressed={werte.afb === x} onClick={() => setWerte({ ...werte, afb: x })}
                className={cn('min-h-[44px] rounded-[var(--radius-md)] border px-4 text-sm',
                  werte.afb === x ? 'border-[var(--color-primary)] bg-[var(--color-primary)] font-semibold text-white' : 'border-[var(--color-border)]')}>
                {x} · {t(`pruefen:einordnung.afbName.${x}`)}
              </button>
            ))}
          </div>
        )}
        {(aktion === 'fertigkeit' || aktion === 'afb' || aktion === 'ausschliessen' || aktion === 'hinweise_bestaetigen') && (
          <label className="flex flex-col gap-2 text-sm font-semibold">
            {t(aktion === 'ausschliessen' ? 'sammel.grundPflichtLabel' : 'sammel.grundOptional')}
            <input className={FELD} value={werte.grund ?? ''} placeholder={aktion === 'ausschliessen' ? t('sammel.grundPlatzhalter') : undefined}
              onChange={(e) => setWerte({ ...werte, grund: e.target.value })} />
          </label>
        )}
        {aktion === 'an_lena' && (
          <label className="flex flex-col gap-2 text-sm font-semibold">
            <span>{t('leiste.nachrichtLabel')} <span className="font-normal text-[var(--color-text-tertiary)]">{t('leiste.nachrichtHinweis')}</span></span>
            <textarea rows={2} className={cn(FELD, 'py-2')} value={werte.nachricht ?? ''} onChange={(e) => setWerte({ ...werte, nachricht: e.target.value })} />
          </label>
        )}
        {brauchtWahl ? (
          <p className="text-sm text-[var(--color-text-tertiary)]">{t('sammel.erstWaehlen')}</p>
        ) : (
          <>
            <div className="grid grid-cols-2 gap-4">
              <div className="rounded-[var(--radius-md)] bg-[var(--color-success-light)] p-3">
                <p className="text-xs text-[var(--color-text-secondary)]">{t('sammel.betrifft')}</p>
                <p className="text-3xl font-bold text-[var(--color-success)]">{vorschau ? betrifft.length : '…'}</p>
              </div>
              <div className="rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] p-3">
                <p className="text-xs text-[var(--color-text-secondary)]">{t('sammel.ausgelassen')}</p>
                <p className="text-3xl font-bold text-[var(--color-text-primary)]">{vorschau ? vorschau.ausgelassen.length : '…'}</p>
              </div>
            </div>
            {betrifft.length > 0 && (
              <details className="text-sm">
                <summary className="min-h-[44px] cursor-pointer content-center font-semibold">{t('sammel.werdenGeaendert', { count: betrifft.length })}</summary>
                {liste(betrifft)}
              </details>
            )}
            {gruppen.map((g) => (
              <details key={`${g.grund}|${g.text ?? ''}`} className="text-sm">
                <summary className="min-h-[44px] cursor-pointer content-center">
                  {uebersetze(t, auslassText({ grund: g.grund, text: g.text }))} <strong>· {g.ids.length}</strong>
                </summary>
                {liste(g.ids)}
              </details>
            ))}
            {schonBewertet > 0 && (
              <p className="rounded-[var(--radius-md)] bg-[var(--color-warning-light)] p-3 text-sm text-[var(--color-warning)]">
                {t('sammel.schonBewertet', { count: schonBewertet })}
              </p>
            )}
            {grosse && (
              <label className="flex min-h-[44px] items-center gap-2 text-sm font-semibold">
                <input type="checkbox" className="h-5 w-5" checked={geprueft} onChange={(e) => setGeprueft(e.target.checked)} />
                {t('sammel.geprueft')}
              </label>
            )}
          </>
        )}
        {fehler && <p role="alert" className="text-sm text-[var(--color-destructive)]">{fehler}</p>}
      </div>
    </Modal>
  )
}
