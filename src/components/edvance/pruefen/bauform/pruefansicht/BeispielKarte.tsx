// Ein Beispiel wie auf dem Tablet (SP-1 S4): Vorschau links, rechts Lösung, Lösungsweg, drei Hinweise; darunter je
// geltendem typischen Fehler die gespeicherte falsche Antwort (bei Auswahl-Formaten die Option), Name und Rückmeldung.
// Lösungsbeispiel-Instanzen zeigen zusätzlich die „Warum?“-Bausteine. Nichts wird nachgerechnet.
import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { PreviewStage } from '@/components/edvance/authoring/PreviewStage'
import { fehlerAntworten } from '@/lib/pruefung/bauformKommentar'
import type { BauformBeispiel, BauformDetail } from '@/types/bauformPruefung'
import { Abschnitt, AnkerKarte, Etikett, KommentarKnopf, wertText } from './Bausteine'

const ANKER = 'ABCDEFGH'

/** Option-IDs (MC, Graph-Auswahl) in der Reihenfolge, wie das Kind sie sieht. */
function optionIds(b: BauformBeispiel): string[] {
  const p = b.payload as unknown as { options?: { id: string }[]; payload?: { optionen?: { id: string }[]; options?: { id: string }[] } }
  return (p.options ?? p.payload?.optionen ?? p.payload?.options ?? []).map((o) => o.id)
}

type Props = {
  nr: number
  beispiel: BauformBeispiel
  detail: BauformDetail
  zeit: number
  markiert: boolean
  onKommentar: () => void
}

export function BeispielKarte({ nr, beispiel: b, detail, zeit, markiert, onKommentar }: Props): JSX.Element {
  const { t, i18n } = useTranslation('bauformPruefen')
  const ids = optionIds(b)
  const text = (antwort: Record<string, unknown> | string | null): string => {
    if (typeof antwort === 'string' && ids.includes(antwort)) return t('ansicht.option', { anker: ANKER[ids.indexOf(antwort)] })
    if (antwort && typeof antwort === 'object' && typeof antwort.option === 'string') {
      const i = ids.indexOf(antwort.option)
      return t('ansicht.option', { anker: i >= 0 ? ANKER[i] : antwort.option })
    }
    return wertText(antwort)
  }
  const regel = new Map((detail.steckbrief.fehlbilder ?? []).map((f) => [f.key, f]))
  const fehler = fehlerAntworten(b).filter((f) => regel.get(f.key)?.gilt_fuer_stufen.includes(b.stufe) ?? true)
  const warum = b.rolle === 'beispiel' ? detail.steckbrief.warum : null
  const minuten = new Intl.NumberFormat(i18n.language, { maximumFractionDigits: 1 }).format(zeit)

  return (
    <AnkerKarte id={`anker-beispiel-${b.task_id}`} markiert={markiert}>
      <div className="flex flex-wrap items-center justify-between gap-2">
        <span className="flex flex-wrap items-center gap-2">
          <b className="text-sm text-[var(--color-text-primary)]">{t('ansicht.beispiel', { nr })}</b>
          <Etikett ton="blau">{t('ansicht.stufe', { stufe: b.stufe })}</Etikett>
          <Etikett>{t(`rolle.${b.rolle}`, { defaultValue: t('rolle.uebung') })}</Etikett>
          <span className="text-xs text-[var(--color-text-muted)] tabular-nums">{t('ansicht.minuten', { wert: minuten })}</span>
        </span>
        <KommentarKnopf aktiv={markiert} onClick={onKommentar} ort={t('ansicht.ort.beispiel', { nr })} />
      </div>
      <div className="grid gap-4 lg:grid-cols-2">
        <PreviewStage payload={b.payload} />
        <dl className="flex flex-col gap-4 text-sm">
          <div className="flex flex-col gap-2">
            <dt><Abschnitt>{t('ansicht.loesung')}</Abschnitt></dt>
            <dd className="text-base font-semibold tabular-nums text-[var(--color-text-primary)]">{text(stripFehlbilder(b.loesung))}</dd>
          </div>
          {b.loesungsweg && (
            <div className="flex flex-col gap-2">
              <dt><Abschnitt>{t('ansicht.loesungsweg')}</Abschnitt></dt>
              <dd className="whitespace-pre-wrap tabular-nums text-[var(--color-text-secondary)]">{b.loesungsweg}</dd>
            </div>
          )}
          <div className="flex flex-col gap-2">
            <dt><Abschnitt>{t('ansicht.hinweise')}</Abschnitt></dt>
            {b.hinweise.map((h) => (
              <dd key={h.level} className="text-[var(--color-text-secondary)]">{t('ansicht.hinweis', { nr: h.level, text: h.text })}</dd>
            ))}
          </div>
          {warum && (
            <div className="flex flex-col gap-2">
              <dt><Abschnitt>{t('ansicht.warum')}</Abschnitt></dt>
              <dd className="text-[var(--color-text-primary)]">{warum.frage}</dd>
              {warum.bausteine.map((w, i) => (
                <dd key={w.id} className="text-[var(--color-text-secondary)]">
                  {ANKER[i]} · {w.text}{w.id === warum.richtig ? ` · ${t('ansicht.warumRichtig')}` : ''}
                </dd>
              ))}
            </div>
          )}
        </dl>
      </div>
      <div className="flex flex-col gap-2 border-t border-[var(--color-border)] pt-4">
        <Abschnitt>{t('ansicht.kindFehler')}</Abschnitt>
        {fehler.length === 0 ? (
          <p className="text-sm text-[var(--color-text-muted)]">{t('ansicht.keineFehler')}</p>
        ) : (
          <ul className="flex flex-col gap-2">
            {fehler.map((f) => (
              <li key={f.key} className="grid grid-cols-[minmax(4rem,auto)_minmax(0,1fr)] items-baseline gap-4 text-sm">
                <span className="rounded-[var(--radius-sm)] bg-[var(--color-bg-subtle)] px-2 text-center font-semibold tabular-nums text-[var(--color-text-primary)]">
                  {text(f.antwort)}
                </span>
                <span>
                  <b className="text-[var(--color-text-primary)]">{t(`fehlbild.${f.key}`, { defaultValue: detail.fehlbild_texte[f.key] ?? '' })}</b>
                  {regel.get(f.key) && <span className="text-[var(--color-text-secondary)]"> → „{regel.get(f.key)?.rueckmeldung}“</span>}
                </span>
              </li>
            ))}
          </ul>
        )}
      </div>
    </AnkerKarte>
  )
}

function stripFehlbilder(l: Record<string, unknown> | null): Record<string, unknown> | string | null {
  if (!l || typeof l !== 'object') return l
  const { fehlbilder: _weg, ...rest } = l as Record<string, unknown> & { fehlbilder?: unknown }
  void _weg
  return rest
}
