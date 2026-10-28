import { useCallback, useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { LoadingPulse } from '@/components/edvance'
import { coachFrageErledigt, getZuhauseStand, zeigsMirEntscheiden, type ZuhauseStand } from '@/lib/session/zuhause'

/**
 * Reihe 1 · D2.3: Kachel „Zuhause geübt“ im Check-in je Kind (Dummy c-checkin). Sie hängt im Einbaupunkt
 * CheckinEinbau von Auftrag C (Props { kindId, sessionId }) und liest nur über src/lib/session/zuhause.ts.
 *
 * Zuhause wird nur gespeichert, DASS geübt wurde: Balken je Skill seit der letzten Session, ohne Ergebnis.
 * Dazu höchstens ein Vorschlag „Zeig's mir“ (Übernehmen / Nicht heute) und die Fragen, die das Kind bei
 * Eddie gemerkt hat. Coach-Sicht: flach, ohne Verläufe.
 */
export function ZuhauseKachel({ kindId, sessionId }: { kindId: string; sessionId: string }): JSX.Element | null {
  const { t } = useTranslation('coachLive')
  const [stand, setStand] = useState<ZuhauseStand | null>(null)
  const [fehler, setFehler] = useState(false)
  const [laeuft, setLaeuft] = useState(false)

  const laden = useCallback((): void => {
    void getZuhauseStand(kindId, sessionId).then(({ data, error }) => {
      setFehler(error !== null)
      if (data) setStand(data)
    })
  }, [kindId, sessionId])

  useEffect(laden, [laden])

  const ausfuehren = async (aktion: () => Promise<{ error: string | null }>): Promise<void> => {
    setLaeuft(true)
    const { error } = await aktion()
    setLaeuft(false)
    setFehler(error !== null)
    laden()
  }

  if (!stand) {
    return fehler ? (
      <p className="text-xs text-[var(--color-text-tertiary)]">{t('zuhause.fehler')}</p>
    ) : (
      <LoadingPulse type="list" lines={2} />
    )
  }

  const max = Math.max(1, ...stand.skills.map((s) => s.quests))
  const minuten = Math.round(stand.skills.reduce((n, s) => n + s.dauer_sek, 0) / 60)
  const v = stand.vorschlag

  return (
    <div className="flex flex-col gap-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-4" data-testid="zuhause-kachel">
      <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('zuhause.titel')}</span>
      {stand.skills.length === 0 ? (
        <p className="text-sm text-[var(--color-text-secondary)]">{t('zuhause.nicht')}</p>
      ) : (
        <>
          <ul className="flex flex-col gap-2">
            {stand.skills.map((s) => (
              <li key={s.skill_key} className="grid grid-cols-[minmax(0,1fr)_96px_auto] items-center gap-2 text-sm">
                <span className="truncate text-[var(--color-text-primary)]">{s.label}</span>
                <span className="h-2 overflow-hidden rounded-full bg-[var(--color-bg-subtle)]">
                  {/* Breite ist berechnet (Anteil am meistgeübten Skill): einziger Inline-Wert. */}
                  <span className="block h-full rounded-full bg-[var(--color-primary)]" style={{ width: `${(s.quests / max) * 100}%` }} />
                </span>
                <span className="text-xs text-[var(--color-text-tertiary)]">
                  {t('zuhause.menge', { count: s.quests, aufgaben: s.aufgaben })}
                </span>
              </li>
            ))}
          </ul>
          <p className="text-xs text-[var(--color-text-tertiary)]">{t('zuhause.hinweis', { count: minuten })}</p>
        </>
      )}

      {v && (
        <div className="flex flex-col gap-2 border-t border-[var(--color-border)] pt-2" data-testid="zeigs-mir">
          <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('zuhause.vorschlagTitel')}</span>
          <p className="text-sm text-[var(--color-text-primary)]">{t('zuhause.vorschlag', { skill: v.label })}</p>
          {v.entscheidung === null ? (
            <div className="flex flex-wrap gap-2">
              <Button size="sm" className="min-h-11" disabled={laeuft}
                onClick={() => void ausfuehren(() => zeigsMirEntscheiden(kindId, sessionId, v.skill_key, 'uebernehmen'))}>
                {t('zuhause.uebernehmen')}
              </Button>
              <Button size="sm" variant="outline" className="min-h-11" disabled={laeuft}
                onClick={() => void ausfuehren(() => zeigsMirEntscheiden(kindId, sessionId, v.skill_key, 'nicht_heute'))}>
                {t('zuhause.nichtHeute')}
              </Button>
            </div>
          ) : (
            <p className="text-sm text-[var(--color-text-secondary)]">
              {t(v.entscheidung === 'uebernehmen' ? 'zuhause.uebernommen' : 'zuhause.nichtHeuteGesetzt')}
            </p>
          )}
        </div>
      )}

      {stand.fragen.map((f) => (
        <div key={f.id} className="flex flex-col gap-2 border-t border-[var(--color-border)] pt-2" data-testid="coach-frage">
          <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('zuhause.frageTitel')}</span>
          <p className="text-sm text-[var(--color-text-primary)]">{t('zuhause.frage', { text: f.text })}</p>
          <div>
            <Button size="sm" variant="outline" className="min-h-11" disabled={laeuft}
              onClick={() => void ausfuehren(() => coachFrageErledigt(f.id))}>
              {t('zuhause.besprochen')}
            </Button>
          </div>
        </div>
      ))}
      {fehler && <p className="text-xs text-[var(--color-text-tertiary)]">{t('zuhause.fehler')}</p>}
    </div>
  )
}
