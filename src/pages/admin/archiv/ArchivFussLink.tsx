import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { countArchiv } from '@/lib/supabase/archiv'

/**
 * MSA-1 M3: unauffälliger Textlink „Archiv (n)“ am Fuß der Item-Pflege, nur für Admins eingebunden. Die einzige
 * Stelle, über die das Archiv erreichbar ist (nicht in der Navigation). Ohne Zähler (Fehler) erscheint der Link ohne Zahl.
 */
export function ArchivFussLink(): JSX.Element {
  const { t } = useTranslation('authoring')
  const [anzahl, setAnzahl] = useState<number | null>(null)

  useEffect(() => {
    let alive = true
    void countArchiv().then((res) => {
      if (alive) setAnzahl(res.data)
    })
    return () => {
      alive = false
    }
  }, [])

  return (
    <div className="flex justify-end">
      <Link
        to="/admin/authoring/archiv"
        className="inline-flex min-h-[44px] items-center text-xs text-[var(--color-text-tertiary)] hover:underline"
      >
        {anzahl == null ? t('archiv.link') : t('archiv.linkMitZahl', { count: anzahl })}
      </Link>
    </div>
  )
}
