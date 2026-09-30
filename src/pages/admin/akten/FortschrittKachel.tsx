import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import { datum } from '@/lib/akte/format'
import type { FachFortschritt } from '@/types'

const SICHTBAR = 4

/**
 * Fortschritt (Anforderung I 37–40, Bauauftrag S3). Je Fach: aktuelles Thema,
 * Station x von y mit schmalem Balken, darunter hoechstens vier vom Coach
 * bestaetigte Kompetenzen (neueste zuerst), sonst "und n weitere".
 * "gemeistert" steht nur bei Eintraegen mit Coach-Bestaetigung — die liefert
 * fortschritt() ausschliesslich. Keine XP, keine Streaks, keine Home Quests.
 */
export function FortschrittKachel({ faecher }: { faecher: FachFortschritt[] }): JSX.Element {
  const { t, i18n } = useTranslation('akte')
  const lang = i18n.language

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('fortschritt.titel')}
      </h2>

      {faecher.length === 0 ? (
        <p className="text-sm text-[var(--color-text-secondary)]">{t('fortschritt.keinLernpfad')}</p>
      ) : (
        <ul className="flex flex-col gap-4">
          {faecher.map((f) => {
            const rest = f.kompetenzen.length - SICHTBAR
            const hatPfad = f.thema !== null && f.station !== null && f.stationen !== null && f.stationen > 0
            return (
              <li key={f.fach_id} className="flex flex-col gap-2 border-b border-[var(--color-border)] pb-4 last:border-b-0 last:pb-0">
                <span className="text-base font-semibold text-[var(--color-text-primary)]">{f.fach}</span>

                {hatPfad ? (
                  <div className="flex flex-col gap-2">
                    <div className="flex flex-wrap items-center justify-between gap-2 text-sm">
                      <span className="text-[var(--color-text-secondary)]">{f.thema}</span>
                      <span className="text-xs text-[var(--color-text-tertiary)]">
                        {t('fortschritt.station', { x: f.station, y: f.stationen })}
                      </span>
                    </div>
                    <div
                      role="img"
                      aria-label={t('fortschritt.station', { x: f.station, y: f.stationen })}
                      className="h-1.5 w-full rounded-full bg-[var(--color-bg-subtle)]"
                    >
                      <div
                        className="h-1.5 rounded-full bg-[var(--color-primary)]"
                        style={{ width: `${Math.min(100, ((f.station as number) / (f.stationen as number)) * 100)}%` }}
                      />
                    </div>
                  </div>
                ) : (
                  <span className="text-sm text-[var(--color-text-secondary)]">{t('fortschritt.keinLernpfad')}</span>
                )}

                {f.kompetenzen.length > 0 && (
                  <ul className="flex flex-col gap-2">
                    {f.kompetenzen.slice(0, SICHTBAR).map((k, i) => (
                      <li key={`${k.kompetenz}-${i}`} className="flex flex-wrap items-center gap-2 text-sm">
                        <EdvanceBadge variant="mastered">{t('fortschritt.gemeistert')}</EdvanceBadge>
                        <span className="text-[var(--color-text-primary)]">{k.kompetenz}</span>
                        <span className="text-xs text-[var(--color-text-tertiary)]">
                          {t('fortschritt.bestaetigt', {
                            coach: k.coach ?? t('fortschritt.coachUnbekannt'),
                            datum: k.am ? datum(k.am, lang) : '—',
                          })}
                        </span>
                      </li>
                    ))}
                    {rest > 0 && (
                      <li className="text-xs text-[var(--color-text-tertiary)]">{t('fortschritt.weitere', { count: rest })}</li>
                    )}
                  </ul>
                )}
              </li>
            )
          })}
        </ul>
      )}
    </EdvanceCard>
  )
}
