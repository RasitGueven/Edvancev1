import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Modal } from '@/components/edvance/Modal'
import { Button } from '@/components/ui/button'
import { berlinLocalParts, berlinLocalToIso } from '@/lib/datetime'
import { ladeZiele, terminAbsagen, terminUmbuchen } from '@/lib/supabase/slotplan'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import type { SlotsZiel, SlotsZiele } from '@/types/slotplan'
import { datumKurz, datumLang } from '../slotsFormat'
import { rechtzeitigVorschau } from '../slots.model'
import { ZieleRaster, zielKey } from './ZieleRaster'

export type AbsageTermin = {
  termin_id: string
  student_id: string
  name: string | null
  datum: string
  beginn: string
  ende?: string
}

const FELD = 'h-11 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm tabular-nums'

/**
 * Absage erfassen und — mit `umbuchen` — gleich einen neuen Termin wählen (Anforderung F 36–37, G 42–43).
 * Die 10-Uhr-Regel ist hier nur Vorschau; gesendet wird der Eingang, entscheiden tut der Server.
 */
export function AbsageDialog({
  termin,
  umbuchen,
  onClose,
  onGespeichert,
}: {
  termin: AbsageTermin | null
  umbuchen: boolean
  onClose: () => void
  onGespeichert: (meldung: string) => void
}): JSX.Element | null {
  const { t, i18n } = useTranslation('slots')
  const jetzt = berlinLocalParts(new Date().toISOString())
  const [datum, setDatum] = useState(jetzt.date)
  const [uhr, setUhr] = useState(jetzt.time)
  const [ziele, setZiele] = useState<SlotsZiele | null>(null)
  const [ziel, setZiel] = useState<SlotsZiel | null>(null)
  const [fehler, setFehler] = useState<string | null>(null)
  const [speichert, setSpeichert] = useState(false)
  const eingang = datum && uhr ? berlinLocalToIso(datum, uhr) : null

  useEffect(() => {
    if (!termin || !umbuchen || !eingang) return
    let aktiv = true
    void ladeZiele(termin.student_id, termin.termin_id, eingang, jetzt.date, 4).then((res) => {
      if (!aktiv) return
      setZiele(res.data)
      if (res.error !== null) setFehler(slotsFehlerSchluessel(res))
    })
    return () => {
      aktiv = false
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps -- neu laden, wenn sich Termin oder Eingang ändert
  }, [termin?.termin_id, umbuchen, eingang])

  if (!termin) return null
  const rechtzeitig = rechtzeitigVorschau(datum, uhr, termin.datum)

  const speichern = async (): Promise<void> => {
    if (!eingang) return
    setSpeichert(true)
    setFehler(null)
    const res = umbuchen && ziel
      ? await terminUmbuchen(termin.termin_id, eingang, ziel.datum, ziel.zeit_id)
      : await terminAbsagen(termin.termin_id, eingang)
    setSpeichert(false)
    if (res.error !== null) {
      setFehler(slotsFehlerSchluessel(res))
      return
    }
    onGespeichert(
      umbuchen && ziel
        ? t('dialog.absage.umgebucht', { name: termin.name, datum: datumKurz(ziel.datum, i18n.language), beginn: ziel.beginn })
        : t(rechtzeitig ? 'dialog.absage.gespeichertRechtzeitig' : 'dialog.absage.gespeichertSpaet', { name: termin.name }),
    )
  }

  const gesperrt = !eingang || (umbuchen && !ziel)
  const grund = !eingang ? t('dialog.absage.eingangFehlt') : umbuchen && !ziel ? t('dialog.ziele.waehlen') : null

  return (
    <Modal
      open
      onClose={onClose}
      size={umbuchen ? 'lg' : 'md'}
      title={t(umbuchen ? 'dialog.absage.titelUmbuchen' : 'dialog.absage.titel')}
      description={t('dialog.absage.wer', { name: termin.name, datum: datumLang(termin.datum, i18n.language), beginn: termin.beginn })}
      footer={
        <div className="flex w-full flex-col items-end gap-2">
          <div className="flex gap-2">
            <Button type="button" variant="ghost" onClick={onClose}>{t('dialog.abbrechen')}</Button>
            <Button type="button" onClick={() => void speichern()} disabled={gesperrt || speichert} loading={speichert}>
              {t(umbuchen ? 'dialog.absage.umbuchen' : 'dialog.absage.speichern')}
            </Button>
          </div>
          {grund && <p className="text-xs text-[var(--color-text-tertiary)]">{grund}</p>}
        </div>
      }
    >
      <div className="flex flex-col gap-4">
        <fieldset className="flex flex-col gap-2">
          <legend className="text-xs font-semibold text-[var(--color-text-tertiary)]">{t('dialog.absage.eingang')}</legend>
          <div className="flex flex-wrap gap-2">
            <input
              autoFocus
              type="date"
              aria-label={t('dialog.absage.eingangDatum')}
              value={datum}
              max={jetzt.date}
              onChange={(e) => setDatum(e.target.value)}
              className={FELD}
            />
            <input type="time" aria-label={t('dialog.absage.eingangUhr')} value={uhr} onChange={(e) => setUhr(e.target.value)} className={FELD} />
          </div>
          <p
            role="status"
            className={`rounded-[var(--radius-md)] px-4 py-2 text-sm ${
              rechtzeitig
                ? 'bg-[var(--color-success-eltern-light)] text-[var(--color-success-eltern)]'
                : 'bg-[var(--color-gold-warning-light)] text-[var(--color-gold-warning)]'
            }`}
          >
            {t(rechtzeitig ? 'dialog.absage.rechtzeitig' : 'dialog.absage.spaet')}
          </p>
        </fieldset>

        {umbuchen && (
          <section className="flex flex-col gap-2">
            <h3 className="text-xs font-semibold text-[var(--color-text-tertiary)]">{t('dialog.ziele.titel')}</h3>
            {ziele?.alt_verbraucht && <p className="text-sm text-[var(--color-text-secondary)]">{t('dialog.ziele.weitereEinheit')}</p>}
            {ziele?.kein_budget ? (
              <p className="text-sm text-[var(--color-text-secondary)]">{t('fehler.SL005')}</p>
            ) : ziele ? (
              <ZieleRaster ziele={ziele.ziele} gewaehlt={ziel ? zielKey(ziel) : null} onWahl={setZiel} />
            ) : null}
            {ziel?.verdraengt && (
              <p className="text-sm text-[var(--color-gold-warning)]">
                {t('dialog.ziele.verdraengt', { datum: datumKurz(ziel.verdraengt, i18n.language) })}
              </p>
            )}
          </section>
        )}

        {fehler && <p role="alert" className="text-sm text-[var(--color-error-coach)]">{t(fehler)}</p>}
      </div>
    </Modal>
  )
}
