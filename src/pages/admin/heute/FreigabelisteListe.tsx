import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ListChecks } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { neueReihe, reiheStarten } from '@/lib/pruefung/reihe'
import { getPruefBoard, getPruefSoll } from '@/lib/supabase/pruefung'
import { ArbeitsListe, type ListenZeile } from './ArbeitsListe'
import { ANLASS_BATU, freigabeStand, type FreigabeStand } from './freigabelisteModel'

/**
 * Batus Freigabeliste (P4): was noch offen ist, je Block (KA2, Rückblick, Ausblick) in Listenreihenfolge, mit dem
 * Teil, den Lena noch prüfen muss. Was Lena mit „passt“ geprüft hat, gibt der Admin als Reihe frei (Enter je
 * Aufgabe). Lenas eigener Lauf fragt die nötigen Aufgaben über pruef_board_soll nacheinander ab. Die Liste lädt selbst.
 */
export function FreigabelisteListe(): JSX.Element {
  const { t } = useTranslation('admin')
  const { t: ta } = useTranslation('pruefenAdmin')
  const navigate = useNavigate()
  const [stand, setStand] = useState<FreigabeStand | null>(null)
  const [fehler, setFehler] = useState(false)

  useEffect(() => {
    let aktiv = true
    void Promise.all([getPruefSoll(ANLASS_BATU), getPruefBoard()]).then(([soll, board]) => {
      if (!aktiv) return
      setFehler(soll.error !== null || board.error !== null)
      setStand(freigabeStand(soll.data ?? [], board.data ?? []))
    })
    return () => {
      aktiv = false
    }
  }, [])

  const zeilen: ListenZeile[] = (stand?.bloecke ?? []).map((b) => ({
    key: b.block,
    titel: t(`heute.listen.freigabeliste.block.${b.block}`),
    unterzeile: [
      t('heute.listen.freigabeliste.bereiche', { count: b.bereiche }),
      b.lena > 0 ? t('heute.listen.freigabeliste.lena', { count: b.lena }) : null,
      b.ohneMc.length > 0 ? t('heute.listen.freigabeliste.ohneMc', { bereiche: b.ohneMc.join(', ') }) : null,
    ].filter(Boolean).join(' · '),
    rechts: <EdvanceBadge variant="muted">{t('heute.listen.freigabeliste.fehlt', { count: b.fehlt })}</EdvanceBadge>,
  }))
  const wartend = stand?.wartend ?? []

  return (
    <ArbeitsListe
      icon={ListChecks}
      titel={t('heute.listen.freigabeliste.titel')}
      unterzeile={fehler ? t('heute.listen.freigabeliste.fehler') : t('heute.listen.freigabeliste.unterzeile')}
      anzahl={stand?.fehlt ?? 0}
      zeilen={zeilen}
      leerText={stand ? t('heute.listen.freigabeliste.leer') : t('heute.listen.freigabeliste.laedt')}
      nachZeilen={
        wartend.length > 0 ? (
          <li className="flex min-h-[54px] items-center gap-2 border-t border-[var(--color-border)] py-2" data-testid="freigabeliste-wartend">
            <div className="flex min-w-0 flex-1 flex-col">
              <span className="truncate text-sm font-semibold">{t('heute.listen.freigabeliste.wartend', { count: wartend.length })}</span>
              <span className="truncate text-xs text-[var(--color-text-tertiary)]">{t('heute.listen.freigabeliste.wartendSub')}</span>
            </div>
            <Button type="button" size="sm" variant="outline" className="min-h-[44px]"
              onClick={() => navigate(reiheStarten(neueReihe(wartend, 'heute', ta('reihe.freigabeliste'), '/admin')))}>
              {t('heute.listen.inhalte.freigeben')}
            </Button>
          </li>
        ) : undefined
      }
      fussLabel={t('heute.listen.freigabeliste.fuss')}
      fussZiel="/coach/pruefen?bereich=lsa"
    />
  )
}
