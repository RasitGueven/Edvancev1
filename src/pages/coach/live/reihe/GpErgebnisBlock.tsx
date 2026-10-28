import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { gpErgebnisLesen, type GpSkill } from '@/lib/supabase/reihe'
import { Abschnitt, Pille } from '../bausteine'

/** Reihe 1 C4.1: Generalprobe-Ergebnis je Skill im Kind-Detail. Ohne Generalprobe nichts. */
export function GpErgebnisBlock({ sessionId, kindId }: { sessionId: string; kindId: string }): JSX.Element | null {
  const { t } = useTranslation('reihe')
  const [liste, setListe] = useState<GpSkill[]>([])
  useEffect(() => {
    let aktiv = true
    void gpErgebnisLesen(sessionId, kindId).then((r) => { if (aktiv) setListe(r.data ?? []) })
    return () => { aktiv = false }
  }, [sessionId, kindId])
  if (liste.length === 0) return null
  return (
    <Abschnitt titel={t('gp.titel')}>
      <ul className="flex flex-col gap-2">
        {liste.map((s) => (
          <li key={s.skill_key} className="flex items-center justify-between gap-2 text-sm">
            <span className="min-w-0 text-[var(--color-text-primary)]">{s.label}</span>
            <Pille ton={s.offen ? 'neutral' : s.sicher ? 'ok' : 'warn'}>{t(s.offen ? 'gp.offen' : s.sicher ? 'gp.sicher' : 'gp.ueben')}</Pille>
          </li>
        ))}
      </ul>
    </Abschnitt>
  )
}
