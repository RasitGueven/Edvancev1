// Steckbrief und Befund einer Bauform in Lenas Pruefansicht (Konzept §3.1, §5).
import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import type { BauformDetail } from '@/types/bauformPruefung'

const Titel = ({ children }: { children: string }): JSX.Element => (
  <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-muted)]">{children}</h3>
)

export function BauformSteckbrief({ detail }: { detail: BauformDetail }): JSX.Element {
  const { t } = useTranslation('bauformPruefen')
  const s = detail.steckbrief
  const p = detail.pruefprotokoll
  const b = detail.blindloeser
  return (
    <div className="grid gap-4 lg:grid-cols-2">
      <EdvanceCard className="flex flex-col gap-3">
        <Titel>{t('detail.steckbrief')}</Titel>
        {s.text && <p className="text-base text-[var(--color-text-primary)]">{s.text}</p>}
        <p className="text-sm text-[var(--color-text-secondary)]">
          {t('detail.rollen')}: {detail.rollen.join(', ')}
          {s.zeit_sek ? ` · ${t('detail.zeit', { minuten: Math.round(s.zeit_sek / 60) || 1 })}` : ''}
        </p>
        {s.kann_entfallen && <p className="text-sm text-[var(--color-text-secondary)]">{t('detail.kannEntfallen')}</p>}
        <Titel>{t('detail.stufen')}</Titel>
        <ul className="flex flex-col gap-1 text-sm text-[var(--color-text-secondary)]">
          {Object.entries(s.stufen ?? {}).map(([k, v]) => (
            <li key={k}>{t('detail.stufe', { stufe: k })}: {v}</li>
          ))}
        </ul>
        {s.warum && (
          <>
            <Titel>{t('detail.warum')}</Titel>
            <p className="text-sm text-[var(--color-text-primary)]">{s.warum.frage}</p>
            <ul className="flex flex-col gap-1 text-sm text-[var(--color-text-secondary)]">
              {s.warum.bausteine.map((w) => (
                <li key={w.id}>{w.text}{w.id === s.warum?.richtig ? ` · ${t('detail.richtig')}` : ''}</li>
              ))}
            </ul>
          </>
        )}
      </EdvanceCard>
      <EdvanceCard className="flex flex-col gap-3">
        <Titel>{t('detail.fehlbilder')}</Titel>
        <ul className="flex flex-col gap-3">
          {(s.fehlbilder ?? []).map((f) => (
            <li key={f.key} className="flex flex-col gap-1 text-sm">
              <span className="flex flex-wrap items-center gap-2">
                <span className="font-mono text-xs text-[var(--color-text-secondary)]">{f.key}</span>
                <EdvanceBadge variant="muted">{t('detail.giltFuer', { stufen: f.gilt_fuer_stufen.join(', ') })}</EdvanceBadge>
              </span>
              {detail.fehlbild_texte[f.key] && <span className="text-[var(--color-text-secondary)]">{detail.fehlbild_texte[f.key]}</span>}
              <span className="text-[var(--color-text-primary)]">„{f.rueckmeldung}“</span>
            </li>
          ))}
        </ul>
        <Titel>{t('detail.befund')}</Titel>
        <p className="text-sm text-[var(--color-text-secondary)]">{t('detail.pruefmaschine', { gruen: p.gruen ?? 0, rot: p.rot ?? 0 })}</p>
        {b && (
          <p className="text-sm text-[var(--color-text-secondary)]">
            {b.abweichend && b.abweichend.length > 0
              ? t('detail.blindAbweichend', { anzahl: b.abweichend.length, geloest: b.geloest ?? 0 })
              : t('detail.blindBestanden', { geloest: b.geloest ?? 0 })}
          </p>
        )}
        <p className="text-sm text-[var(--color-text-secondary)]">{t('detail.instanzen', { count: detail.instanzen })}</p>
      </EdvanceCard>
    </div>
  )
}
