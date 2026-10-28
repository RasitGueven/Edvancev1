// Die neuen Aufgabenformate (Sessionreihe 1, A3) in Lenas Vorschau — inhaltlich wie auf dem Tablet
// (edvance-app `src/components/aufgaben/formate/`), im flachen Rahmen der Vorschau (PreviewStage).
//
// Rendert AUSSCHLIESSLICH das serverseitige Payload (aufgabe_payload bzw. task_preview_payload): keine Loesung,
// keine Wertung. Die Eingaben sind Attrappen (disabled), wie die uebrigen Formate der Vorschau. Reihenfolgen,
// Optionen und Texte stehen genau so da, wie das Kind sie bekommt.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import type { FormatLoesungsbeispiel, FormatPayload } from '@/types'

const ANKER = 'ABCDEFGH'

function Zeile({ anker, children }: { anker?: string; children: React.ReactNode }): JSX.Element {
  return (
    <div className="flex min-h-[44px] items-center gap-3 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 py-2">
      {anker && (
        <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-[var(--radius-full)] bg-[var(--color-primary-light)] text-xs font-bold text-[var(--color-primary)]">
          {anker}
        </span>
      )}
      <span className="whitespace-pre-wrap text-sm text-[var(--color-text-primary)]">{children}</span>
    </div>
  )
}

function Feld({ label, breit }: { label: string; breit?: boolean }): JSX.Element {
  return (
    <input
      disabled
      aria-label={label}
      className={`h-11 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-subtle)] ${breit ? 'w-28' : 'w-16'}`}
    />
  )
}

function Hinweis({ children }: { children: React.ReactNode }): JSX.Element {
  return <p className="text-xs text-[var(--color-text-tertiary)]">{children}</p>
}

export function FormatAnsicht({ payload }: { payload: FormatPayload }): JSX.Element {
  const { t } = useTranslation('authoring')
  switch (payload.format) {
    case 'feldmaske': {
      let nr = 0
      return (
        <div className="flex flex-wrap items-center gap-2">
          {payload.schablone.map((teil, i) => {
            if ('text' in teil) return <span key={i} className="whitespace-pre text-base text-[var(--color-text-primary)]">{teil.text}</span>
            if (teil.typ === 'vorzeichen') {
              return (
                <span key={i} aria-label={t('formate.vorzeichen')} className="flex h-11 w-11 items-center justify-center rounded-[var(--radius-md)] border border-[var(--color-border)] text-base font-bold text-[var(--color-text-primary)]">
                  +
                </span>
              )
            }
            nr += 1
            return <Feld key={i} label={t('formate.feld', { nr })} breit={teil.typ === 'bruch'} />
          })}
        </div>
      )
    }
    case 'loesungsmenge':
      return (
        <div className="flex flex-col gap-2">
          <div className="flex items-center gap-2">
            <span className="text-base text-[var(--color-text-primary)]">{payload.variable} =</span>
            <Feld label={t('formate.loesung', { nr: 1 })} breit={payload.element === 'bruch'} />
          </div>
          <Zeile>{t('formate.keineLoesung')}</Zeile>
        </div>
      )
    case 'graph_auswahl':
      return (
        <div className="grid grid-cols-2 gap-3">
          {payload.optionen.map((o, i) => (
            <div key={o.id} className="flex flex-col gap-2 rounded-[var(--radius-md)] border border-[var(--color-border)] p-2">
              <span className="text-xs font-bold text-[var(--color-primary)]">{ANKER[i]}</span>
              {o.bild ? (
                <img src={o.bild} alt={o.alt} className="block h-auto w-full rounded-[var(--radius-md)]" />
              ) : (
                <Hinweis>{t('formate.graphOhneBild', { alt: o.alt })}</Hinweis>
              )}
            </div>
          ))}
        </div>
      )
    case 'fehler_finden':
      return (
        <div className="flex flex-col gap-2">
          {payload.zeilen.map((z) => (
            <Zeile key={z.nr} anker={String(z.nr)}>{z.text}</Zeile>
          ))}
          <Hinweis>{t('formate.warumFrage')}</Hinweis>
          {payload.warum.map((b, i) => (
            <Zeile key={b.id} anker={ANKER[i]}>{b.text}</Zeile>
          ))}
        </div>
      )
    case 'bausteine':
      return (
        <div className="flex flex-col gap-2">
          <Hinweis>{payload.anzahl === 2 ? t('formate.bausteineZwei') : t('formate.bausteineEins')}</Hinweis>
          {payload.bausteine.map((b, i) => (
            <Zeile key={b.id} anker={ANKER[i]}>{b.text}</Zeile>
          ))}
        </div>
      )
    case 'schritte_ordnen':
      return (
        <div className="flex flex-col gap-2">
          <Hinweis>{t('formate.schritteAnleitung')}</Hinweis>
          {payload.schritte.map((s, i) => (
            <Zeile key={s.id} anker={String(i + 1)}>{s.text}</Zeile>
          ))}
        </div>
      )
  }
}

/** Lösungsbeispiel einer Instanz der Rolle beispiel: alle Schritte offen, das „Warum?“ mit Markierung des passenden Bausteins (für Lena). */
export function LoesungsbeispielAnsicht({ beispiel }: { beispiel: FormatLoesungsbeispiel }): JSX.Element {
  const { t } = useTranslation('authoring')
  return (
    <div className="flex flex-col gap-2">
      <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('formate.beispielTitel')}</span>
      {beispiel.schritte.map((s, i) => (
        <Zeile key={i} anker={String(i + 1)}>{s.text}</Zeile>
      ))}
      {beispiel.warum && (
        <>
          <Hinweis>{beispiel.warum.frage || t('formate.beispielWarum')}</Hinweis>
          {beispiel.warum.bausteine.map((b, i) => (
            <Zeile key={b.id} anker={ANKER[i]}>
              {b.text}
              {b.id === beispiel.warum?.richtig ? ` · ${t('formate.beispielRichtig')}` : ''}
            </Zeile>
          ))}
        </>
      )}
    </div>
  )
}
