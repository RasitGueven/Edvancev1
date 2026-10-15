import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Modal } from '@/components/edvance/Modal'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { useAuth } from '@/hooks/useAuth'
import { berlinToday } from '@/lib/datetime'
import { SELECT_MD } from '@/lib/formStyles'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import { ladeEinstellungen } from '@/lib/supabase/slotplan'
import { ladeKinderBuchbar, ladeSessionLeitung, sofortSessionAnlegen } from '@/lib/supabase/stundenplan'
import type { SlotsEinstellungen } from '@/types/slotplan'
import type { KindBuchbar, SessionLeitung } from '@/types/stundenplan'
import { KindAuswahl } from '../stundenplan/KindAuswahl'
import { gemischt, MAX_KINDER, raeumeAktivAm } from '../stundenplan/stundenplan.model'

type Raum = SlotsEinstellungen['raeume'][number]

/**
 * „Session jetzt starten“ (Slots S2, Entscheidung 7 und 8): Kinder mit Grund für heute, Leitung (vorbelegt: wer
 * angemeldet ist), Raum (Pflicht). „Starten“ legt über sofort_session_anlegen an und öffnet die Live-Sicht.
 */
export function SofortDialog({ vorauswahl, onClose }: { vorauswahl?: string; onClose: () => void }): JSX.Element {
  const { t } = useTranslation('slots')
  const userId = useAuth().user?.id ?? null
  const navigate = useNavigate()
  const [heute] = useState(berlinToday)
  const [kinder, setKinder] = useState<KindBuchbar[] | null>(null)
  const [leitung, setLeitung] = useState<SessionLeitung[]>([])
  const [raeume, setRaeume] = useState<Raum[]>([])
  const [ladeFehler, setLadeFehler] = useState<string | null>(null)
  const [gewaehlt, setGewaehlt] = useState<string[]>([])
  const [coach, setCoach] = useState('')
  const [raum, setRaum] = useState('')
  const [startet, setStartet] = useState(false)
  const [fehler, setFehler] = useState<string | null>(null)
  const [runde, setRunde] = useState(0)

  useEffect(() => {
    let aktiv = true
    void Promise.all([ladeKinderBuchbar(heute), ladeSessionLeitung(), ladeEinstellungen()]).then(([k, l, e]) => {
      if (!aktiv) return
      const fehlgeschlagen = [k, l, e].find((r) => r.error !== null)
      setLadeFehler(fehlgeschlagen ? slotsFehlerSchluessel(fehlgeschlagen) : null)
      setKinder(k.data ?? [])
      setLeitung(l.data ?? [])
      const offen = raeumeAktivAm(e.data?.raeume ?? [], heute)
      setRaeume(offen)
      // Nach einer Ablehnung neu geladen: wer jetzt nicht buchbar ist, fällt aus der Wahl (gesperrt ließe es sich nicht abwählen).
      const ok = new Set((k.data ?? []).filter((x) => x.code === 'ok').map((x) => x.student_id))
      setGewaehlt((g) => g.filter((id) => ok.has(id)))
      if (runde > 0) return
      if (userId && (l.data ?? []).some((x) => x.id === userId)) setCoach(userId)
      if (offen.length === 1) setRaum(offen[0].id)
      if (vorauswahl && (k.data ?? []).some((x) => x.student_id === vorauswahl && x.code === 'ok')) setGewaehlt([vorauswahl])
    })
    return () => {
      aktiv = false
    }
  }, [heute, runde, userId, vorauswahl])

  const sperre = gewaehlt.length === 0
    ? 'fehler.keineKinder'
    : kinder && gemischt(kinder, gewaehlt) ? 'fehler.artKonflikt'
      : !coach ? 'sofort.fehlt.coach'
        : !raum ? (raeume.length === 0 ? 'sofort.fehlt.keinRaum' : 'sofort.fehlt.raum') : null

  const starten = async (): Promise<void> => {
    if (sperre) return
    setStartet(true)
    setFehler(null)
    const res = await sofortSessionAnlegen(coach, raum, gewaehlt)
    setStartet(false)
    if (res.error !== null || !res.data) {
      const grund = t(slotsFehlerSchluessel(res))
      const kind = kinder?.find((k) => k.student_id === res.detail)
      setFehler(kind ? t('sofort.fehlerKind', { name: kind.name ?? t('stundenplan.unbenannt'), grund }) : grund)
      setRunde((r) => r + 1)
      return
    }
    navigate(`/coach/session/${res.data.session_id}/live`)
  }

  return (
    <Modal
      open
      onClose={onClose}
      title={t('sofort.titel')}
      description={t('sofort.satz')}
      footer={
        <div className="flex w-full flex-col items-end gap-2">
          <div className="flex gap-2">
            <Button type="button" variant="ghost" onClick={onClose}>{t('dialog.abbrechen')}</Button>
            <Button type="button" onClick={() => void starten()} disabled={!!sperre || startet} loading={startet}>
              {t('sofort.starten')}
            </Button>
          </div>
          {sperre && <p className="text-xs text-[var(--color-text-tertiary)]">{t(sperre)}</p>}
        </div>
      }
    >
      <div className="flex flex-col gap-6">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div className="flex flex-col gap-2">
            <Label htmlFor="sofort-coach">{t('stundenplan.feld.leitung')}</Label>
            <select id="sofort-coach" className={SELECT_MD} value={coach} onChange={(e) => setCoach(e.target.value)}>
              <option value="">{t('stundenplan.feld.waehlen')}</option>
              {leitung.map((l) => (
                <option key={l.id} value={l.id}>
                  {l.rolle === 'admin' ? t('stundenplan.feld.leitungAdmin', { name: l.name }) : l.name}
                </option>
              ))}
            </select>
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="sofort-raum">{t('stundenplan.feld.raum')}</Label>
            <select id="sofort-raum" className={SELECT_MD} value={raum} onChange={(e) => setRaum(e.target.value)}>
              <option value="">{t('stundenplan.feld.waehlen')}</option>
              {raeume.map((r) => (
                <option key={r.id} value={r.id}>{r.name}</option>
              ))}
            </select>
          </div>
        </div>
        <div className="flex flex-col gap-2">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('sofort.kinder', { anzahl: gewaehlt.length, max: MAX_KINDER })}
          </p>
          <KindAuswahl kinder={kinder} fehler={ladeFehler} gewaehlt={gewaehlt} onWahl={setGewaehlt} frei={MAX_KINDER} />
        </div>
        {fehler && <p role="alert" className="text-sm text-[var(--color-error-coach)]">{fehler}</p>}
      </div>
    </Modal>
  )
}
