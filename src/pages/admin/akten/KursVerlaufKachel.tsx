import { useCallback, useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { kindKursAnlegen, listKindKurs, type KindKursZeile } from '@/lib/supabase/kindKurs'
import { schulformVon } from '@/lib/supabase/schulen'
import type { Abschlussziel, KursMathe, SchoolKind } from '@/types'
import { KURS_SCHULFORMEN } from '../intake/intakeConstants'
import { KursFelder } from '../intake/KursFelder'

const heute = (): string => new Intl.DateTimeFormat('en-CA', { timeZone: 'Europe/Berlin' }).format(new Date())

/**
 * SF-1: Mathe-Kurs und Abschlussziel als Verlauf (kind_kurs). Eine Änderung legt eine neue Zeile mit
 * Datum an, alte Zeilen bleiben sichtbar. Erscheint bei Gesamt- und Sekundarschule oder sobald ein
 * Verlauf existiert. Admin erfasst, Coach liest.
 */
export function KursVerlaufKachel({
  studentId,
  schuleId,
  istAdmin,
}: {
  studentId: string
  schuleId: string | null
  istAdmin: boolean
}): JSX.Element | null {
  const { t, i18n } = useTranslation('akte')
  const { t: ta } = useTranslation('admin')
  const [zeilen, setZeilen] = useState<KindKursZeile[] | null>(null)
  const [schulform, setSchulform] = useState<string | null>(null)
  const [kurs, setKurs] = useState<KursMathe | null>(null)
  const [ziel, setZiel] = useState<Abschlussziel | null>(null)
  const [ab, setAb] = useState(heute())
  const [busy, setBusy] = useState(false)
  const [fehler, setFehler] = useState<string | null>(null)

  const laden = useCallback(async (): Promise<void> => {
    const { data, error } = await listKindKurs(studentId)
    setFehler(error)
    setZeilen(data ?? [])
  }, [studentId])

  useEffect(() => {
    void laden()
  }, [laden])

  useEffect(() => {
    if (!istAdmin || !schuleId) return
    void schulformVon(schuleId).then(({ data }) => setSchulform(data))
  }, [istAdmin, schuleId])

  if (zeilen === null) return <LoadingPulse type="list" lines={2} />
  const mitKurs = KURS_SCHULFORMEN.includes(schulform as SchoolKind)
  if (!mitKurs && zeilen.length === 0) return null

  const speichern = async (): Promise<void> => {
    setBusy(true)
    setFehler(null)
    const { error } = await kindKursAnlegen(studentId, { kurs, abschlussziel: ziel, ab_datum: ab })
    setBusy(false)
    if (error) {
      setFehler(error)
      return
    }
    setKurs(null)
    setZiel(null)
    await laden()
  }

  const datum = (iso: string): string =>
    new Intl.DateTimeFormat(i18n.language, { timeZone: 'Europe/Berlin', dateStyle: 'medium' }).format(
      new Date(`${iso}T12:00:00Z`),
    )
  const leer = kurs === null && ziel === null

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('kurs.titel')}
      </h2>

      {zeilen.length === 0 ? (
        <EmptyState icon="🎓" title={t('kurs.leer')} description={t('kurs.leerHinweis')} />
      ) : (
        <ul className="flex flex-col gap-2" data-testid="kurs-verlauf">
          {zeilen.map((z, i) => (
            <li
              key={z.id}
              className="flex flex-wrap items-baseline justify-between gap-2 border-b border-[var(--color-border)] pb-2 text-sm"
            >
              <span
                className={
                  i === 0 ? 'font-semibold text-[var(--color-text-primary)]' : 'text-[var(--color-text-secondary)]'
                }
              >
                {[
                  z.kurs ? ta(`intake.kurs.kurse.${z.kurs}`) : null,
                  z.abschlussziel ? ta(`intake.kurs.ziele.${z.abschlussziel}`) : null,
                ]
                  .filter(Boolean)
                  .join(' · ')}
              </span>
              <span className="text-xs tabular-nums text-[var(--color-text-tertiary)]">
                {t('kurs.ab', { datum: datum(z.ab_datum) })}
              </span>
            </li>
          ))}
        </ul>
      )}

      {istAdmin && (
        <div className="flex flex-col gap-4">
          <KursFelder
            idPrefix="akte"
            kurs={kurs}
            ziel={ziel}
            disabled={busy}
            onChange={(n) => {
              if (n.kurs_mathe !== undefined) setKurs(n.kurs_mathe)
              if (n.abschlussziel !== undefined) setZiel(n.abschlussziel)
            }}
          />
          <div className="flex flex-col gap-2">
            <Label htmlFor="akte-kurs-ab">{t('kurs.abLabel')}</Label>
            <Input id="akte-kurs-ab" type="date" value={ab} disabled={busy} onChange={(e) => setAb(e.target.value)} />
          </div>
          <div>
            <Button
              disabled={busy || leer || !ab}
              title={leer ? t('kurs.leerePflicht') : undefined}
              onClick={() => void speichern()}
            >
              {busy ? t('kurs.speichert') : t('kurs.speichern')}
            </Button>
          </div>
        </div>
      )}
      {fehler && <p className="text-sm text-[var(--color-error-exam)]">{fehler}</p>}
    </EdvanceCard>
  )
}
