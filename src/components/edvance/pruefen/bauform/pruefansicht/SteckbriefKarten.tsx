// Linke Spalte oben (SP-1 S4): Grundgerüst mit markierten Platzhaltern, typische Fehler mit Rückmeldung, Stufen mit
// Klartext und Zeit-Richtwert (Minus/Plus, geänderter Wert markiert mit „vorher …“).
import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import type { BauformDetail, BauformStufe } from '@/types/bauformPruefung'
import { Abschnitt, AnkerKarte, Etikett, KommentarKnopf } from './Bausteine'
import { fehlbildName } from './fehlbildName'

type Anker = { markiert: boolean; onKommentar: () => void }
const zahl = (n: number, sprache: string): string => new Intl.NumberFormat(sprache, { maximumFractionDigits: 1 }).format(n)

export function GrundgeruestKarte({ detail, anker }: { detail: BauformDetail; anker: Anker }): JSX.Element {
  const { t, i18n } = useTranslation('bauformPruefen')
  const teile = (detail.steckbrief.text ?? '').split(/\{(\w+)\}/)
  const wort = (name: string): string =>
    i18n.exists(`bauformPruefen:platzhalter.${detail.schluessel}.${name}`)
      ? t(`platzhalter.${detail.schluessel}.${name}`)
      : i18n.exists(`bauformPruefen:platzhalter._.${name}`) ? t(`platzhalter._.${name}`) : t('platzhalter._.wort')
  return (
    <AnkerKarte id="anker-grundgeruest" markiert={anker.markiert}>
      <div className="flex items-center justify-between gap-4">
        <Abschnitt>{t('ansicht.grundgeruest')}</Abschnitt>
        <KommentarKnopf aktiv={anker.markiert} onClick={anker.onKommentar} ort={t('ansicht.ort.grundgeruest')} />
      </div>
      <p className="text-base font-medium leading-loose text-[var(--color-text-primary)]">
        {teile.map((x, i) =>
          i % 2 === 1 ? (
            <span key={i} className="mx-0.5 rounded-[var(--radius-sm)] border border-dashed border-[var(--color-primary)] bg-[var(--color-primary-light)] px-2 text-sm font-semibold text-[var(--color-primary)]">
              {wort(x)}
            </span>
          ) : (
            <span key={i}>{x}</span>
          ),
        )}
      </p>
      <p className="text-xs text-[var(--color-text-muted)]">{t('ansicht.grundgeruestHinweis')}</p>
    </AnkerKarte>
  )
}

export function FehlerKarte({ detail, anker }: { detail: BauformDetail; anker: Anker }): JSX.Element {
  const { t, i18n } = useTranslation('bauformPruefen')
  return (
    <AnkerKarte id="anker-fehlbilder" markiert={anker.markiert}>
      <div className="flex items-center justify-between gap-4">
        <Abschnitt>{t('ansicht.fehler')}</Abschnitt>
        <KommentarKnopf aktiv={anker.markiert} onClick={anker.onKommentar} ort={t('ansicht.ort.fehlbilder')} />
      </div>
      <ul className="flex flex-col divide-y divide-[var(--color-border)]">
        {(detail.steckbrief.fehlbilder ?? []).map((f) => {
          const name = fehlbildName(t, i18n, detail.schluessel, f.key, null)
          const regel = detail.fehlbild_texte[f.key] ?? null
          return (
          <li key={f.key} className="flex flex-col gap-2 py-2 text-sm">
            <span className="flex flex-wrap items-center gap-2 font-semibold text-[var(--color-text-primary)]">
              {name ?? regel}
              <Etikett>{t('ansicht.stufenListe', { stufen: f.gilt_fuer_stufen.join(', ') })}</Etikett>
            </span>
            {name && regel && <span className="text-[var(--color-text-secondary)]">{regel}</span>}
            <span className="text-[var(--color-text-primary)]">{t('ansicht.rueckmeldungAnsKind', { text: f.rueckmeldung })}</span>
          </li>
          )
        })}
      </ul>
      <p className="text-xs text-[var(--color-text-muted)]">{t('ansicht.fehlerHinweis')}</p>
    </AnkerKarte>
  )
}

type StufenProps = {
  detail: BauformDetail
  anker: Anker
  zeiten: Record<string, number>
  onZeit: (stufe: number, vorher: number, delta: number) => void
  aenderbar: boolean
}

export function StufenKarte({ detail, anker, zeiten, onZeit, aenderbar }: StufenProps): JSX.Element {
  const { t, i18n } = useTranslation('bauformPruefen')
  // Ohne Klartext (noch nicht geprüft) je Stufe die Regel aus dem Steckbrief, damit keine Zeile leer bleibt (SP-1b).
  const regel = detail.steckbrief.stufen ?? {}
  const stufen: BauformStufe[] = detail.stufen?.length
    ? detail.stufen.map((s) => ({ ...s, beschreibung: s.beschreibung ?? regel[String(s.stufe)] ?? null }))
    : Object.entries(regel).map(([k, v]) => ({ stufe: Number(k), beschreibung: v, beispiel: null, zeit_min: 1 }))
  return (
    <AnkerKarte id="anker-stufen" markiert={anker.markiert}>
      <div className="flex items-center justify-between gap-4">
        <Abschnitt>{t('ansicht.stufen')}</Abschnitt>
        <KommentarKnopf aktiv={anker.markiert} onClick={anker.onKommentar} ort={t('ansicht.ort.stufen')} />
      </div>
      <ul className="flex flex-col divide-y divide-[var(--color-border)]">
        {stufen.map((s) => {
          const wert = zeiten[String(s.stufe)] ?? s.zeit_min
          const geaendert = wert !== s.zeit_min
          return (
            <li key={s.stufe} className="grid grid-cols-[auto_minmax(0,1fr)] items-center gap-4 py-2 sm:grid-cols-[auto_minmax(0,1fr)_auto]">
              <Etikett ton="blau">{t('ansicht.stufe', { stufe: s.stufe })}</Etikett>
              <span className="flex flex-col gap-1 text-sm">
                <span className="font-medium text-[var(--color-text-primary)]">{s.beschreibung}</span>
                {s.beispiel && <span className="text-[var(--color-text-secondary)]">{t('ansicht.zBsp', { beispiel: s.beispiel })}</span>}
              </span>
              <span className="col-span-2 flex items-center justify-end gap-2 text-sm text-[var(--color-text-secondary)] sm:col-span-1">
                {geaendert && <span className="text-xs font-semibold text-[var(--color-primary)]">{t('ansicht.vorher', { wert: zahl(s.zeit_min, i18n.language) })}</span>}
                <span className={`flex items-center overflow-hidden rounded-[var(--radius-md)] border ${geaendert ? 'border-[var(--color-primary)] bg-[var(--color-primary-light)]' : 'border-[var(--color-border)] bg-[var(--color-bg-surface)]'}`}>
                  <ZeitKnopf zeichen="−" label={t('ansicht.kuerzer', { stufe: s.stufe })} aus={!aenderbar || wert <= 0.5}
                    onClick={() => onZeit(s.stufe, s.zeit_min, -0.5)} />
                  <b className="min-w-12 text-center font-semibold tabular-nums text-[var(--color-text-primary)]">{zahl(wert, i18n.language)}</b>
                  <ZeitKnopf zeichen="+" label={t('ansicht.laenger', { stufe: s.stufe })} aus={!aenderbar || wert >= 10}
                    onClick={() => onZeit(s.stufe, s.zeit_min, 0.5)} />
                </span>
                {t('ansicht.min')}
              </span>
            </li>
          )
        })}
      </ul>
      <p className="text-xs text-[var(--color-text-muted)]">{t('ansicht.stufenHinweis')}</p>
    </AnkerKarte>
  )
}

function ZeitKnopf({ zeichen, label, aus, onClick }: { zeichen: string; label: string; aus: boolean; onClick: () => void }): JSX.Element {
  return (
    <button type="button" aria-label={label} title={label} disabled={aus} onClick={onClick}
      className="h-11 w-11 text-lg text-[var(--color-primary)] hover:bg-[var(--color-primary-light)] focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-[var(--color-primary)] disabled:opacity-40">
      {zeichen}
    </button>
  )
}
