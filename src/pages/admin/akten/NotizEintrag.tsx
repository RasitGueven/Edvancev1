import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { EdvanceBadge } from '@/components/edvance'
import { formatBerlinDateTime } from '@/lib/datetime'
import type { SchuelerNotiz } from '@/types'

type Aktion = 'ausblenden' | 'entfernen' | null

/**
 * Eine Notiz. Coaches bekommen per RLS weder ausgeblendete noch entfernte
 * Notizen; die Admin-Sicht zeigt beides mit Vermerk. Bestaetigungen laufen
 * inline, nicht als Modal.
 */
export function NotizEintrag({
  notiz,
  istAdmin,
  busy,
  onAusblenden,
  onEinblenden,
  onEntfernen,
}: {
  notiz: SchuelerNotiz
  istAdmin: boolean
  busy: boolean
  onAusblenden: (grund: string) => void
  onEinblenden: () => void
  onEntfernen: () => void
}): JSX.Element {
  const { t, i18n } = useTranslation('akte')
  const lang = i18n.language
  const [aktion, setAktion] = useState<Aktion>(null)
  const [grund, setGrund] = useState('')
  const unbekannt = t('notizen.unbekannt')
  const entfernt = notiz.entfernt_am !== null
  const ausgeblendet = notiz.ausgeblendet_am !== null

  return (
    <li className="flex flex-col gap-2 border-b border-[var(--color-border)] pb-4 last:border-b-0 last:pb-0">
      <div className="flex flex-wrap items-center gap-2">
        <EdvanceBadge variant="muted">{t(`notizen.kategorien.${notiz.kategorie}`)}</EdvanceBadge>
        <span className="text-xs text-[var(--color-text-tertiary)]">
          {t('notizen.von', {
            name: notiz.autor_name ?? unbekannt,
            rolle: t(`notizen.rolle.${notiz.autor_rolle}`),
            datum: formatBerlinDateTime(notiz.created_at, lang),
          })}
        </span>
      </div>

      {entfernt ? (
        <p className="text-sm italic text-[var(--color-text-tertiary)]">
          {t('notizen.entfernt', {
            name: notiz.entfernt_von_name ?? unbekannt,
            datum: formatBerlinDateTime(notiz.entfernt_am as string, lang),
          })}
        </p>
      ) : (
        <p
          className={`text-sm leading-relaxed text-[var(--color-text-secondary)] ${ausgeblendet ? 'line-through' : ''}`}
        >
          {notiz.text}
        </p>
      )}

      {ausgeblendet && !entfernt && (
        <p className="text-xs text-[var(--color-text-tertiary)]">
          {t('notizen.ausgeblendet', {
            name: notiz.ausgeblendet_von_name ?? unbekannt,
            datum: formatBerlinDateTime(notiz.ausgeblendet_am as string, lang),
            grund: notiz.ausgeblendet_grund ?? '',
          })}
        </p>
      )}

      {istAdmin && !entfernt && aktion === null && (
        <div className="flex flex-wrap gap-2">
          {ausgeblendet ? (
            <Button size="sm" variant="outline" disabled={busy} onClick={onEinblenden}>
              {t('notizen.einblenden')}
            </Button>
          ) : (
            <Button size="sm" variant="outline" disabled={busy} onClick={() => setAktion('ausblenden')}>
              {t('notizen.ausblenden')}
            </Button>
          )}
          <Button size="sm" variant="outline" disabled={busy} onClick={() => setAktion('entfernen')}>
            {t('notizen.entfernen')}
          </Button>
        </div>
      )}

      {aktion === 'ausblenden' && (
        <div className="flex flex-wrap items-center gap-2">
          <Input
            aria-label={t('notizen.grundPflicht')}
            placeholder={t('notizen.grundPflicht')}
            value={grund}
            onChange={(e) => setGrund(e.target.value)}
          />
          <Button
            size="sm"
            disabled={busy || !grund.trim()}
            title={!grund.trim() ? t('notizen.grundPflicht') : undefined}
            onClick={() => {
              onAusblenden(grund.trim())
              setAktion(null)
              setGrund('')
            }}
          >
            {t('notizen.ausblendenBestaetigen')}
          </Button>
          <Button size="sm" variant="outline" onClick={() => setAktion(null)}>
            {t('notizen.abbrechen')}
          </Button>
        </div>
      )}

      {aktion === 'entfernen' && (
        <div className="flex flex-col gap-2">
          <p className="text-sm text-[var(--color-text-secondary)]">{t('notizen.entfernenFrage')}</p>
          <div className="flex flex-wrap gap-2">
            <Button
              size="sm"
              variant="destructive"
              disabled={busy}
              onClick={() => {
                onEntfernen()
                setAktion(null)
              }}
            >
              {t('notizen.entfernenBestaetigen')}
            </Button>
            <Button size="sm" variant="outline" onClick={() => setAktion(null)}>
              {t('notizen.abbrechen')}
            </Button>
          </div>
        </div>
      )}
    </li>
  )
}
