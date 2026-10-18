// Das Tablet, wie das Kind es sieht — nur eben im Editor-Panel.
//
// Diese Datei rendert AUSSCHLIESSLICH das serverseitig gebaute Payload
// (task_preview_payload → lsa_question_payload). Sie bekommt keinen FormState, sie
// kennt keine Loesung, sie hat keinen Zugriff darauf. Was hier nicht ankommt,
// kommt auch beim Kind nicht an — und umgekehrt.
//
// TEXT WIE AUF DEM TABLET: Kinder sehen Aufgaben nur noch in edvance-app (der
// Web-TaskPlayer ist stillgelegt, Entscheidung 24). Dort setzt `Buehne` Stamm,
// Teilaufgaben und Antwortoptionen als reinen Text in ein <Text>: kein Markdown,
// kein LaTeX, Zeilenumbrueche bleiben stehen. Frueher lief der Text hier durch
// MathContent (Markdown + KaTeX) — das klappte einfache Umbrueche zusammen
// („I: …" und „II: …" eines Gleichungssystems standen in einer Zeile) und haette
// $…$, *…* oder Tabellen anders gezeigt als das Kind sie sieht. Deshalb steht der
// Text hier genauso roh da wie auf dem Tablet, auch „-2^2" bleibt „-2^2".
// Rahmen und Schrift bleiben flach (Coach-Sprache), geteilt wird nur der Inhalt.
//
// TABELLE (F01): Das Tablet hat dafuer noch keinen Renderer. Sie steht hier mit
// den Klassen, die MathContent einer Markdown-Tabelle gibt.
//
// NICHT INTERAKTIV: Die Eingaben sind Attrappen (disabled). Die Vorschau zeigt,
// sie bewertet nicht — kein Richtig/Falsch, kein Absenden (CLAUDE §6).

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { AssetList } from '@/lib/render/AssetList'
import type { PreviewAsset, PreviewOption, PreviewPart, PreviewPayload, PreviewTable } from '@/types'

/** Aufgabentext wie `Buehne` auf dem Tablet: reiner Text, Umbrueche und Leerzeichen bleiben. */
function KindText({ text }: { text: string }): JSX.Element {
  return <p className="whitespace-pre-wrap text-sm leading-relaxed text-[var(--color-text-primary)]">{text}</p>
}

function Assets({ assets }: { assets: PreviewAsset[] }): JSX.Element | null {
  if (assets.length === 0) return null
  // Der Alt-Text ist Vertragsbestandteil. Fehlt er, zeigt die Vorschau ein leeres
  // alt="" — genau das, was ein Screenreader beim Kind vorfinden wuerde. Der
  // Missstand gehoert in die Flag-Liste, nicht in einen erfundenen Ersatztext.
  return <AssetList assets={assets.map((a) => ({ url: a.url, alt: a.alt ?? '' }))} />
}

function Table({ table }: { table: PreviewTable }): JSX.Element {
  return (
    <div className="my-3 overflow-x-auto rounded-[var(--radius-md)] border border-[var(--color-border)] shadow-card">
      <table className="w-full border-collapse text-sm tabular-nums">
        <thead className="bg-[var(--color-primary-light)] text-[var(--color-primary)]">
          <tr>
            {table.headers.map((h, i) => (
              <th key={i} className="px-3 py-2 text-left text-xs font-bold uppercase tracking-wider">
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="[&_tr:nth-child(even)]:bg-[color-mix(in_srgb,var(--color-primary-light)_40%,white)]">
          {table.rows.map((row, r) => (
            <tr key={r}>
              {row.map((cell, c) => (
                <td key={c} className="border-t border-[var(--color-border)] px-3 py-2 align-top">
                  {cell}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function ShortInput({ unit }: { unit?: string }): JSX.Element {
  const { t } = useTranslation('authoring')
  return (
    <div className="flex items-center gap-2">
      <input
        disabled
        readOnly
        placeholder={t('preview.answerPlaceholder')}
        className="h-14 w-full rounded-[var(--radius-lg)] border-2 border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 text-sm"
      />
      {unit && (
        <span className="inline-flex h-14 shrink-0 items-center rounded-[var(--radius-lg)] border-2 border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 text-sm font-semibold text-[var(--color-text-secondary)]">
          {unit}
        </span>
      )}
    </div>
  )
}

function McOptions({ options }: { options: PreviewOption[] }): JSX.Element | null {
  if (options.length === 0) return null
  return (
    <div className="flex flex-col gap-2" role="group">
      {options.map((option, i) => (
        <div
          key={option.id || i}
          className="flex min-h-[56px] items-center gap-3 rounded-[var(--radius-lg)] border-2 border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 py-2"
        >
          <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-[var(--radius-full)] bg-[var(--color-primary-light)] text-xs font-bold text-[var(--color-primary)]">
            {String.fromCharCode(65 + i)}
          </span>
          <span className="whitespace-pre-wrap text-sm text-[var(--color-text-primary)]">{option.label}</span>
        </div>
      ))}
    </div>
  )
}

/** Eine Teilaufgabe (P02): eigene Karte, eigener Prompt, eigene Tabelle, eigene Eingabe. */
function Part({ part }: { part: PreviewPart }): JSX.Element {
  const { t } = useTranslation('authoring')
  return (
    <EdvanceCard className="flex flex-col gap-3">
      <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('parts.part', { nr: part.nr })}
      </span>
      {part.prompt && <KindText text={part.prompt} />}
      {part.table && <Table table={part.table} />}
      {part.kind === 'mc' ? (
        <McOptions options={part.options ?? []} />
      ) : (
        <ShortInput unit={part.unit} />
      )}
    </EdvanceCard>
  )
}

/**
 * Die Buehne. Ein Weiter-Button ganz unten — auch bei Multi-Part genau EINER
 * (P02: das Kind beantwortet den ganzen Block, nicht Teilaufgabe fuer Teilaufgabe).
 * Er ist disabled: hier wird nichts abgeschickt.
 */
export function PreviewStage({ payload }: { payload: PreviewPayload }): JSX.Element {
  const { t } = useTranslation('authoring')
  const multi = payload.kind === 'multi_part'
  const stem = multi ? payload.stem : payload.prompt

  return (
    <div className="preview-stage flex flex-col gap-3 rounded-[var(--radius-lg)] p-4">
      <EdvanceCard className="flex flex-col gap-3">
        {stem.trim() === '' ? (
          <p className="text-sm italic text-[var(--color-text-tertiary)]">{t('preview.empty')}</p>
        ) : (
          <KindText text={stem} />
        )}
        <Assets assets={payload.assets} />
        {payload.table && <Table table={payload.table} />}

        {/* Der Stamm eines Multi-Part-Items traegt selbst keine Eingabe — die
            Teilaufgaben tun es. Bei flachen Items steht die Eingabe hier. */}
        {payload.kind === 'mc' && <McOptions options={payload.options} />}
        {payload.kind === 'short_input' && <ShortInput unit={payload.unit} />}
      </EdvanceCard>

      {multi && payload.parts.map((part) => <Part key={part.nr} part={part} />)}

      <div className="flex justify-end pt-1">
        <button
          type="button"
          disabled
          className="inline-flex min-h-[44px] items-center justify-center rounded-[var(--radius-xl)] bg-[var(--color-bg-surface)] px-6 text-base font-semibold text-[var(--color-primary)] opacity-50"
        >
          {t('preview.submit')}
        </button>
      </div>
    </div>
  )
}
