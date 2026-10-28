import { useState } from 'react'
import { useTranslation } from 'react-i18next'

import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { speichereStudioSkript } from '@/lib/supabase/studio'
import { skriptPruefen } from '@/studio/skript/pruefen'

import { BefundListe } from './BefundListe'
import { FELD_MONO } from './felder'

type Pruefung = ReturnType<typeof skriptPruefen>

/**
 * „Skript einfügen“ (Anforderung Studio §4): JSON einfügen, prüfen, nur ohne Sperre speichern.
 * Die Prüfung ist dieselbe Funktion wie in den Skript-Tests (src/studio/skript/pruefen.ts).
 */
export function SkriptEinfuegen({
  katalog,
  onGespeichert,
  onAbbrechen,
}: {
  katalog: ReadonlySet<string> | null
  onGespeichert: (id: string) => void
  onAbbrechen: () => void
}): JSX.Element {
  const { t } = useTranslation('studio')
  const [text, setText] = useState('')
  const [jsonFehler, setJsonFehler] = useState<string | null>(null)
  const [pruefung, setPruefung] = useState<Pruefung | null>(null)
  const [speicherFehler, setSpeicherFehler] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  const pruefen = (): void => {
    setSpeicherFehler(null)
    try {
      const roh: unknown = JSON.parse(text)
      setJsonFehler(null)
      setPruefung(skriptPruefen(roh, { katalog }))
    } catch (e) {
      setPruefung(null)
      setJsonFehler(e instanceof Error ? e.message : String(e))
    }
  }

  const speichern = async (): Promise<void> => {
    if (!pruefung?.ok || !pruefung.skript) return
    setBusy(true)
    const res = await speichereStudioSkript(null, pruefung.skript, pruefung)
    setBusy(false)
    if (res.error || !res.data) setSpeicherFehler(res.error?.message ?? '')
    else onGespeichert(res.data)
  }

  const gesperrt = pruefung?.gesperrteWelten.map((w) => t(`welt.${w}`)).join(', ')
  return (
    <EdvanceCard>
      <div className="flex flex-col gap-4">
        <div className="flex flex-col gap-2">
          <h2 className="text-base font-semibold">{t('einfuegen.titel')}</h2>
          <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{t('einfuegen.satz')}</p>
        </div>
        {!katalog && <p className="text-xs text-[var(--color-text-muted)]">{t('einfuegen.katalogFehlt')}</p>}
        <textarea
          className={`${FELD_MONO} min-h-[320px]`}
          value={text}
          placeholder={t('einfuegen.platzhalter')}
          onChange={(e) => {
            setText(e.target.value)
            setPruefung(null)
          }}
          aria-label={t('einfuegen.titel')}
          data-testid="studio-skript-json"
        />
        {jsonFehler && <p className="text-sm text-[var(--color-error-coach)]">{t('einfuegen.keinJson', { fehler: jsonFehler })}</p>}
        {pruefung && pruefung.befunde.length > 0 && <BefundListe befunde={pruefung.befunde} />}
        {pruefung?.ok && (
          <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]" data-testid="studio-pruef-ok">
            {gesperrt ? t('einfuegen.okWelten', { welten: gesperrt }) : t('einfuegen.ok')}
          </p>
        )}
        {speicherFehler !== null && (
          <p className="text-sm text-[var(--color-error-coach)]">{t('einfuegen.speicherFehler', { grund: speicherFehler })}</p>
        )}
        <div className="flex flex-wrap gap-2">
          {pruefung?.ok ? (
            <Button onClick={() => void speichern()} disabled={busy} data-testid="studio-speichern">
              {t('einfuegen.speichern')}
            </Button>
          ) : (
            <Button onClick={pruefen} disabled={text.trim() === ''} title={t('einfuegen.gesperrtTooltip')} data-testid="studio-pruefen">
              {t('einfuegen.pruefen')}
            </Button>
          )}
          <Button variant="ghost" onClick={onAbbrechen}>
            {t('einfuegen.abbrechen')}
          </Button>
        </div>
      </div>
    </EdvanceCard>
  )
}
