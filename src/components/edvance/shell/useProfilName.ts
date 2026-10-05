import { useEffect, useState } from 'react'
import { useAuth } from '@/hooks/useAuth'
import { profilNamen } from '@/lib/supabase/akte'

/**
 * Der eigene Name aus profiles.full_name (nicht aus user_metadata — dort steht
 * er nur, wenn er bei der Anlage mitgegeben wurde). null, solange er lädt oder
 * fehlt.
 */
export function useProfilName(): string | null {
  const { user } = useAuth()
  const id = user?.id ?? null
  const [name, setName] = useState<string | null>(null)

  useEffect(() => {
    if (!id) {
      setName(null)
      return
    }
    let aktiv = true
    void profilNamen([id])
      .then((namen) => {
        if (aktiv) setName(namen.get(id)?.trim() || null)
      })
      .catch(() => {
        if (aktiv) setName(null)
      })
    return () => {
      aktiv = false
    }
  }, [id])

  return name
}
