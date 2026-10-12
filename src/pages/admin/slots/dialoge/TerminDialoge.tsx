import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { LoadingPulse } from '@/components/edvance'
import { Modal } from '@/components/edvance/Modal'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { SELECT_MD } from '@/lib/formStyles'
import { ladeKandidaten, terminFaelltAus, terminRaumOeffnen, zusatzterminBuchen } from '@/lib/supabase/slotplan'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import type { SlotsKandidat, SlotsTermin } from '@/types/slotplan'
import { datumKurz, datumLang } from '../slotsFormat'
import { KlasseFach } from '../KlasseFach'

type Props = { termin: SlotsTermin; onClose: () => void; onGespeichert: (meldung: string) => void }

function Fuss({ grund, children, onClose }: { grund?: string | null; children: React.ReactNode; onClose: () => void }): JSX.Element {
  const { t } = useTranslation('slots')
  return (
    <div className="flex w-full flex-col items-end gap-2">
      <div className="flex gap-2">
        <Button type="button" variant="ghost" onClick={onClose}>{t('dialog.abbrechen')}</Button>
        {children}
      </div>
      {grund && <p className="text-xs text-[var(--color-text-tertiary)]">{grund}</p>}
    </div>
  )
}

/** Kind hinzufügen (Zusatztermin vom Termin aus): nur Kinder, für die alle Regeln erfüllt sind. */
export function KindHinzufuegenDialog({ termin, onClose, onGespeichert }: Props): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const [kandidaten, setKandidaten] = useState<SlotsKandidat[] | null>(null)
  const [suche, setSuche] = useState('')
  const [gewaehlt, setGewaehlt] = useState<SlotsKandidat | null>(null)
  const [fehler, setFehler] = useState<string | null>(null)
  const [speichert, setSpeichert] = useState(false)

  useEffect(() => {
    let aktiv = true
    void ladeKandidaten(termin.datum, termin.zeit.id).then((res) => {
      if (!aktiv) return
      setKandidaten(res.data ?? [])
      if (res.error !== null) setFehler(slotsFehlerSchluessel(res))
    })
    return () => {
      aktiv = false
    }
  }, [termin.datum, termin.zeit.id])

  const q = suche.trim().toLocaleLowerCase('de')
  const liste = (kandidaten ?? []).filter((k) => q === '' || (k.name ?? '').toLocaleLowerCase('de').includes(q))

  const speichern = async (): Promise<void> => {
    if (!gewaehlt) return
    setSpeichert(true)
    const res = await zusatzterminBuchen(gewaehlt.student_id, termin.datum, termin.zeit.id)
    setSpeichert(false)
    if (res.error !== null) return setFehler(slotsFehlerSchluessel(res))
    onGespeichert(t('dialog.hinzufuegen.gebucht', { name: gewaehlt.name }))
  }

  return (
    <Modal
      open
      onClose={onClose}
      title={t('dialog.hinzufuegen.titel')}
      description={`${datumLang(termin.datum, i18n.language)} · ${termin.zeit.beginn}–${termin.zeit.ende}`}
      footer={
        <Fuss onClose={onClose} grund={gewaehlt ? null : t('dialog.hinzufuegen.waehlen')}>
          <Button type="button" onClick={() => void speichern()} disabled={!gewaehlt || speichert} loading={speichert}>
            {t('dialog.hinzufuegen.speichern')}
          </Button>
        </Fuss>
      }
    >
      <div className="flex flex-col gap-4">
        <Input autoFocus type="search" value={suche} onChange={(e) => setSuche(e.target.value)} placeholder={t('dialog.hinzufuegen.suche')} aria-label={t('dialog.hinzufuegen.suche')} />
        {kandidaten === null ? (
          <LoadingPulse lines={3} />
        ) : liste.length === 0 ? (
          <p className="text-sm text-[var(--color-text-secondary)]">{t('dialog.hinzufuegen.keine')}</p>
        ) : (
          <ul className="flex max-h-80 flex-col overflow-y-auto">
            {liste.map((k) => {
              const an = gewaehlt?.student_id === k.student_id
              return (
                <li key={k.student_id} className="border-t border-[var(--color-border)]">
                  <button
                    type="button"
                    aria-pressed={an}
                    onClick={() => setGewaehlt(k)}
                    className={`flex min-h-[44px] w-full items-center justify-between gap-2 px-2 py-2 text-left transition-colors duration-150 ease-out ${
                      an ? 'bg-[var(--color-primary-light)]' : 'hover:bg-[var(--color-bg-subtle)]'
                    }`}
                  >
                    <span className="flex min-w-0 flex-col">
                      <span className="truncate text-sm font-semibold">{k.name}</span>
                      <span className="flex flex-wrap items-center gap-2 text-xs text-[var(--color-text-tertiary)]">
                        <KlasseFach klasse={k.klasse} fach={k.fach} test={k.ist_test} />
                        {k.verdraengt && t('dialog.ziele.verdraengtKurz', { datum: datumKurz(k.verdraengt, i18n.language) })}
                      </span>
                    </span>
                    <span className="shrink-0 text-xs tabular-nums text-[var(--color-text-secondary)]">{t('dialog.hinzufuegen.offen', { count: k.offen })}</span>
                  </button>
                </li>
              )
            })}
          </ul>
        )}
        {gewaehlt?.verdraengt && (
          <p className="text-sm text-[var(--color-gold-warning)]">{t('dialog.ziele.verdraengt', { datum: datumKurz(gewaehlt.verdraengt, i18n.language) })}</p>
        )}
        {fehler && <p role="alert" className="text-sm text-[var(--color-error-coach)]">{t(fehler)}</p>}
      </div>
    </Modal>
  )
}

/** Raum öffnen: Raum und Coach nur für diesen Termin (Anforderung D 23). */
export function RaumOeffnenDialog({ termin, onClose, onGespeichert }: Props): JSX.Element {
  const { t } = useTranslation('slots')
  const freieCoaches = termin.coaches.filter((c) => c.raum_id === null)
  const [raum, setRaum] = useState(termin.raeume_schliessbar[0]?.raum_id ?? '')
  const [coach, setCoach] = useState(freieCoaches[0]?.id ?? '')
  const [fehler, setFehler] = useState<string | null>(null)
  const [speichert, setSpeichert] = useState(false)
  const grund = !raum ? t('dialog.raum.keinRaum') : !coach ? t('dialog.raum.keinCoach') : null

  const speichern = async (): Promise<void> => {
    setSpeichert(true)
    const res = await terminRaumOeffnen(termin.datum, termin.zeit.id, raum, coach)
    setSpeichert(false)
    if (res.error !== null) return setFehler(slotsFehlerSchluessel(res))
    onGespeichert(t('dialog.raum.geoeffnet', { raum: termin.raeume_schliessbar.find((r) => r.raum_id === raum)?.name }))
  }

  return (
    <Modal
      open
      size="md"
      onClose={onClose}
      title={t('dialog.raum.titel')}
      description={t('dialog.raum.nurDieser')}
      footer={
        <Fuss onClose={onClose} grund={grund}>
          <Button type="button" onClick={() => void speichern()} disabled={!!grund || speichert} loading={speichert}>
            {t('dialog.raum.speichern')}
          </Button>
        </Fuss>
      }
    >
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <label className="flex flex-col gap-2 text-xs font-semibold text-[var(--color-text-tertiary)]">
          {t('dialog.raum.raum')}
          <select autoFocus className={SELECT_MD} value={raum} onChange={(e) => setRaum(e.target.value)}>
            {termin.raeume_schliessbar.map((r) => <option key={r.raum_id} value={r.raum_id}>{r.name}</option>)}
          </select>
        </label>
        <label className="flex flex-col gap-2 text-xs font-semibold text-[var(--color-text-tertiary)]">
          {t('dialog.raum.coach')}
          <select className={SELECT_MD} value={coach} onChange={(e) => setCoach(e.target.value)}>
            {freieCoaches.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>
        </label>
        {fehler && <p role="alert" className="text-sm text-[var(--color-error-coach)] sm:col-span-2">{t(fehler)}</p>}
      </div>
    </Modal>
  )
}

/** Ganzer Termin fällt aus: die einzige Bestätigung als Dialog, mit Zahl der Kinder. */
export function FaelltAusDialog({ termin, onClose, onGespeichert }: Props): JSX.Element {
  const { t } = useTranslation('slots')
  const anzahl = termin.raeume.reduce((n, r) => n + r.kinder.length, 0) + termin.ohne_raum.length
  const [fehler, setFehler] = useState<string | null>(null)
  const [speichert, setSpeichert] = useState(false)

  const speichern = async (): Promise<void> => {
    setSpeichert(true)
    const res = await terminFaelltAus(termin.datum, termin.zeit.id)
    setSpeichert(false)
    if (res.error !== null) return setFehler(slotsFehlerSchluessel(res))
    onGespeichert(t('dialog.faelltAus.gespeichert', { count: res.data?.betroffen ?? anzahl }))
  }

  return (
    <Modal
      open
      size="md"
      onClose={onClose}
      title={t('dialog.faelltAus.titel')}
      footer={
        <Fuss onClose={onClose}>
          <Button type="button" variant="destructive" autoFocus onClick={() => void speichern()} disabled={speichert} loading={speichert}>
            {t('dialog.faelltAus.speichern')}
          </Button>
        </Fuss>
      }
    >
      <div className="flex flex-col gap-2">
        <p className="text-sm text-[var(--color-text-primary)]">{t('dialog.faelltAus.frage', { count: anzahl })}</p>
        <p className="text-sm text-[var(--color-text-secondary)]">{t('dialog.faelltAus.einheiten')}</p>
        {fehler && <p role="alert" className="text-sm text-[var(--color-error-coach)]">{t(fehler)}</p>}
      </div>
    </Modal>
  )
}
