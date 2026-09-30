import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { EdvanceCard } from '@/components/edvance'
import { SELECT_MD } from '@/lib/formStyles'
import { stammdatenSpeichern } from '@/lib/supabase/akte'
import { listSchulen, type Schule } from '@/lib/supabase/schulen'
import type { Schuelerakte } from '@/types'
import { SchuleAuswahl } from '../vertraege/SchuleAuswahl'

// Auswahl laut Anforderung (Daten: Klasse 8, 9, 10). Eine andere, schon
// gespeicherte Klasse bleibt waehlbar, damit Speichern sie nicht verliert.
const KLASSEN = [8, 9, 10]

const WERT = 'text-sm leading-relaxed text-[var(--color-text-secondary)]'

/**
 * Stammdaten (Anforderung G). Admin bearbeitet Klasse und Schule (Schulliste
 * wie unter Vertraege, "neu anlegen" inklusive); Coach liest. Faecher werden
 * nur angezeigt. Den Namen aendert hier niemand: profiles hat keine
 * Schreibregel, eine RPC dafuer gehoert ins Foundation-Fenster.
 */
export function StammdatenKachel({
  akte,
  faecher,
  istAdmin,
  onGespeichert,
}: {
  akte: Schuelerakte
  faecher: string[]
  istAdmin: boolean
  onGespeichert: () => void
}): JSX.Element {
  const { t } = useTranslation('akte')
  const [schulen, setSchulen] = useState<Schule[]>([])
  const [klasse, setKlasse] = useState<string>(akte.klasse !== null ? String(akte.klasse) : '')
  const [schuleId, setSchuleId] = useState<string>(akte.schule_id ?? '')
  const [busy, setBusy] = useState(false)
  const [meldung, setMeldung] = useState<string | null>(null)
  const [fehler, setFehler] = useState<string | null>(null)

  useEffect(() => {
    if (!istAdmin) return
    void listSchulen().then(({ data }) => setSchulen(data ?? []))
  }, [istAdmin])

  const klassen = akte.klasse !== null && !KLASSEN.includes(akte.klasse) ? [...KLASSEN, akte.klasse] : KLASSEN

  const speichern = async (): Promise<void> => {
    setBusy(true)
    setFehler(null)
    setMeldung(null)
    const { error } = await stammdatenSpeichern(akte.student_id, {
      class_level: klasse ? Number(klasse) : null,
      schule_id: schuleId || null,
    })
    setBusy(false)
    if (error) {
      setFehler(error)
      return
    }
    setMeldung(t('stammdaten.gespeichert'))
    onGespeichert()
  }

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('stammdaten.titel')}
      </h2>

      <div className="flex flex-col gap-2">
        <span className="text-xs text-[var(--color-text-tertiary)]">{t('stammdaten.name')}</span>
        <span className={WERT}>{akte.name ?? t('stammdaten.offen')}</span>
        {istAdmin && <span className="text-xs text-[var(--color-text-tertiary)]">{t('stammdaten.nameHinweis')}</span>}
      </div>

      {istAdmin ? (
        <>
          <div className="flex flex-col gap-2">
            <Label htmlFor="akte-klasse">{t('stammdaten.klasse')}</Label>
            <select id="akte-klasse" className={SELECT_MD} value={klasse} onChange={(e) => setKlasse(e.target.value)}>
              <option value="">{t('stammdaten.klasseWaehlen')}</option>
              {klassen.map((k) => (
                <option key={k} value={String(k)}>
                  {k}
                </option>
              ))}
            </select>
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="vertrag-schule">{t('stammdaten.schule')}</Label>
            <SchuleAuswahl
              schulen={schulen}
              value={schuleId}
              freitext={akte.schule ?? ''}
              readOnly={false}
              onChange={(id) => setSchuleId(id)}
              onAngelegt={(s) => setSchulen((alt) => [...alt, s].sort((a, b) => a.name.localeCompare(b.name)))}
            />
          </div>
        </>
      ) : (
        <>
          <div className="flex flex-col gap-2">
            <span className="text-xs text-[var(--color-text-tertiary)]">{t('stammdaten.klasse')}</span>
            <span className={WERT}>{akte.klasse ?? t('stammdaten.offen')}</span>
          </div>
          <div className="flex flex-col gap-2">
            <span className="text-xs text-[var(--color-text-tertiary)]">{t('stammdaten.schule')}</span>
            <span className={WERT}>{akte.schule ?? t('stammdaten.offen')}</span>
          </div>
        </>
      )}

      <div className="flex flex-col gap-2">
        <span className="text-xs text-[var(--color-text-tertiary)]">{t('stammdaten.faecher')}</span>
        <span className={WERT}>{faecher.length > 0 ? faecher.join(', ') : t('stammdaten.keineFaecher')}</span>
      </div>

      {fehler && <p className="text-sm text-[var(--color-error-exam)]">{fehler}</p>}
      {meldung && <p className="text-sm text-[var(--color-text-secondary)]">{meldung}</p>}

      {istAdmin && (
        <div>
          <Button disabled={busy} onClick={() => void speichern()}>
            {busy ? t('stammdaten.speichert') : t('stammdaten.speichern')}
          </Button>
        </div>
      )}
    </EdvanceCard>
  )
}
