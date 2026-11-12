// Rechte Spalte der Prüfansicht (SP-1 S4): Lenas Kommentare (Ort als Überschrift, Gründe des Ankers als Chips,
// Textfeld, ×), darunter ein einziger Knopf: „Passt · n Aufgaben zur Freigabe“ oder „Rückfrage senden (n Kommentare)“,
// gesperrt, solange ein Kommentar weder Grund noch Text hat. Admins sehen die letzte Rückfrage mit erledigt-Notizen.
import { useEffect, useRef, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { X } from 'lucide-react'
import { EmptyState } from '@/components/edvance'
import { Button } from '@/components/ui'
import { GRUENDE, istGueltig, schluesselVon, sendbar, type Entwurf, type Kommentar } from '@/lib/pruefung/bauformKommentar'
import type { BauformRueckfrage } from '@/types/bauformPruefung'

type Props = {
  entwurf: Entwurf
  ort: (k: Kommentar) => string
  fokus: string | null
  aufgaben: number
  zeitZeile: string | null
  offen: boolean
  hinweisGesperrt: string | null
  busy: boolean
  rueckfrage: BauformRueckfrage | null
  isAdmin: boolean
  onSpringen: (k: Kommentar) => void
  onEntfernen: (schluessel: string) => void
  onGrund: (schluessel: string, grund: string) => void
  onText: (schluessel: string, text: string) => void
  onSenden: () => void
}

export function RueckmeldungSpalte(p: Props): JSX.Element {
  const { t } = useTranslation('bauformPruefen')
  const felder = useRef(new Map<string, HTMLTextAreaElement>())
  useEffect(() => {
    if (p.fokus) felder.current.get(p.fokus.split('#')[0])?.focus()
  }, [p.fokus])
  const n = p.entwurf.kommentare.length
  const ok = sendbar(p.entwurf)

  return (
    <aside className="flex min-h-0 flex-col rounded-[var(--radius-lg)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] shadow-card">
      <div className="flex flex-col gap-2 border-b border-[var(--color-border)] p-4">
        <h2 className="text-base font-semibold text-[var(--color-text-primary)]">{t('ansicht.rechts')}</h2>
        <p className="text-sm text-[var(--color-text-secondary)]">{t('ansicht.rechtsSatz')}</p>
      </div>
      <div className="flex min-h-0 flex-1 flex-col gap-4 overflow-y-auto p-4">
        {p.isAdmin && p.rueckfrage && <AdminRueckfrage r={p.rueckfrage} />}
        {n === 0 ? (
          <EmptyState icon="💬" title={t('ansicht.leer')} description={t('ansicht.leerSatz')} />
        ) : (
          p.entwurf.kommentare.map((k) => {
            const s = schluesselVon(k)
            const ort = p.ort(k)
            return (
              <div key={s} className={`flex flex-col gap-2 rounded-[var(--radius-lg)] border p-4 ${istGueltig(k) ? 'border-[var(--color-border)]' : 'border-[var(--color-gold-warning)]'} bg-[var(--color-gold-warning-light)]`}>
                <div className="flex items-center justify-between gap-2">
                  <button type="button" onClick={() => p.onSpringen(k)}
                    className="min-h-[44px] text-left text-sm font-semibold text-[var(--color-gold-warning)] hover:underline focus-visible:outline-2 focus-visible:outline-[var(--color-primary)]">
                    {ort}
                  </button>
                  <button type="button" aria-label={`${t('ansicht.entfernen')}: ${ort}`} title={t('ansicht.entfernen')} onClick={() => p.onEntfernen(s)}
                    className="flex h-11 w-11 items-center justify-center rounded-[var(--radius-full)] text-[var(--color-text-muted)] hover:bg-[var(--color-bg-subtle)] focus-visible:outline-2 focus-visible:outline-[var(--color-primary)]">
                    <X aria-hidden="true" className="h-4 w-4" />
                  </button>
                </div>
                <div className="flex flex-wrap gap-2" role="group" aria-label={t('ansicht.gruende')}>
                  {GRUENDE[k.anker].map((g) => (
                    <button key={g} type="button" aria-pressed={k.gruende.includes(g)} onClick={() => p.onGrund(s, g)}
                      className={`min-h-[44px] rounded-[var(--radius-full)] border px-4 text-xs font-medium focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)] ${
                        k.gruende.includes(g)
                          ? 'border-[var(--color-primary)] bg-[var(--color-primary)] text-[var(--color-text-inverse)]'
                          : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)]'
                      }`}>
                      {t(`ansicht.grund.${g}`)}
                    </button>
                  ))}
                </div>
                <textarea
                  ref={(el) => { if (el) felder.current.set(s, el); else felder.current.delete(s) }}
                  value={k.text}
                  onChange={(e) => p.onText(s, e.target.value)}
                  aria-label={t('ansicht.textLabel', { ort })}
                  placeholder={t('ansicht.textPlatzhalter')}
                  rows={3}
                  className="w-full resize-y rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-2 text-sm focus-visible:outline-2 focus-visible:outline-[var(--color-primary)]"
                />
              </div>
            )
          })
        )}
      </div>
      {p.offen && (
        <div className="flex flex-col gap-2 border-t border-[var(--color-border)] p-4">
          {p.zeitZeile && <p className="text-xs font-semibold text-[var(--color-primary)]">{p.zeitZeile}</p>}
          <p className="text-xs text-[var(--color-text-secondary)]">
            {n === 0 ? t('ansicht.passtSatz') : ok ? t('ansicht.rueckfrageSatz') : t('ansicht.unvollstaendig')}
          </p>
          <Button className="min-h-[44px] w-full" disabled={!ok || p.busy} title={!ok ? t('ansicht.gesperrtTitel') : undefined} onClick={p.onSenden}>
            {n === 0 ? t('ansicht.passt', { count: p.aufgaben }) : t('ansicht.rueckfrage', { count: n })}
          </Button>
        </div>
      )}
      {!p.offen && p.hinweisGesperrt && (
        <p className="border-t border-[var(--color-border)] p-4 text-sm text-[var(--color-text-secondary)]">{p.hinweisGesperrt}</p>
      )}
    </aside>
  )
}

function AdminRueckfrage({ r }: { r: BauformRueckfrage }): JSX.Element {
  const { t } = useTranslation('bauformPruefen')
  return (
    <section className="flex flex-col gap-2 rounded-[var(--radius-lg)] border border-[var(--color-border)] p-4" aria-label={t('ansicht.adminRueckfrage', { version: r.version })}>
      <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-muted)]">{t('ansicht.adminRueckfrage', { version: r.version })}</h3>
      <ul className="flex flex-col gap-2 text-sm">
        {r.kommentare.map((k) => (
          <li key={k.id} className="flex flex-col gap-1">
            <span className="font-semibold text-[var(--color-text-primary)]">
              {k.anker === 'beispiel' ? (k.frage ?? t('ansicht.ort.beispiel', { nr: '' })) : t(`ansicht.ort.${k.anker}`)}
            </span>
            <span className="text-[var(--color-text-secondary)]">
              {[...k.gruende.map((g) => t(`ansicht.grund.${g}`)), k.text].filter(Boolean).join(' · ')}
            </span>
            <span className={k.status === 'erledigt' ? 'text-[var(--color-success)]' : 'text-[var(--color-gold-warning)]'}>
              {k.status === 'erledigt' ? t('ansicht.adminErledigt', { notiz: k.erledigt_notiz ?? '' }) : t('ansicht.adminOffen')}
            </span>
          </li>
        ))}
      </ul>
    </section>
  )
}
