import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { SELECT_MD } from '@/lib/formStyles'
import { schuleAnlegen, type Schule } from '@/lib/supabase/schulen'
import { sucheSchulen } from '@/lib/themen/suche'

type SchuleAuswahlProps = {
  schulen: Schule[]
  value: string
  /** Freitext aus dem Lead — steht bis zur Zuordnung noch im alten Feld. */
  freitext: string
  readOnly: boolean
  onChange: (schuleId: string, name: string) => void
  onAngelegt: (schule: Schule) => void
}

const NEU = '__neu__'

/**
 * Schule ist eine Auswahl, kein Freitext (Entscheidung 15) — sonst steht
 * dieselbe Schule nach zehn Vertraegen in acht Schreibweisen da.
 *
 * "Neu anlegen" bleibt im selben Feld: Wer am Empfang sitzt, hat die Eltern
 * gegenueber und soll die Strecke nicht verlassen, um eine Schule zu pflegen.
 * Der Freitext aus dem Lead steht als Vorschlag im Namensfeld.
 */
export function SchuleAuswahl({
  schulen,
  value,
  freitext,
  readOnly,
  onChange,
  onAngelegt,
}: SchuleAuswahlProps): JSX.Element {
  const { t } = useTranslation('vertraege')
  const { t: tc } = useTranslation('common')
  const { t: ta } = useTranslation('admin')
  const [suche, setSuche] = useState('')
  const [anlegen, setAnlegen] = useState(false)
  const [name, setName] = useState(freitext)
  const [ort, setOrt] = useState('')
  const [busy, setBusy] = useState(false)
  const [fehler, setFehler] = useState<string | null>(null)

  const speichern = async (): Promise<void> => {
    setBusy(true)
    setFehler(null)
    const { data, error } = await schuleAnlegen(name, ort)
    setBusy(false)
    if (error || !data) {
      setFehler(error ?? t('schule.saveFailed'))
      return
    }
    onAngelegt(data)
    onChange(data.id, data.name)
    setAnlegen(false)
  }

  if (anlegen) {
    return (
      <div className="flex flex-col gap-2">
        <Input
          value={name}
          disabled={busy}
          placeholder={t('schule.namePlaceholder')}
          aria-label={t('schule.name')}
          onChange={(e) => setName(e.target.value)}
        />
        <Input
          value={ort}
          disabled={busy}
          placeholder={t('schule.ortPlaceholder')}
          aria-label={t('schule.ort')}
          onChange={(e) => setOrt(e.target.value)}
        />
        {fehler && <p className="text-xs text-[var(--color-error-exam)]">{fehler}</p>}
        <div className="flex flex-wrap gap-2">
          <Button
            size="sm"
            disabled={busy || name.trim() === ''}
            loading={busy}
            onClick={() => void speichern()}
          >
            {t('schule.save')}
          </Button>
          <Button size="sm" variant="outline" disabled={busy} onClick={() => setAnlegen(false)}>
            {tc('cancel')}
          </Button>
        </div>
      </div>
    )
  }

  // SF-1: Suche nach Name und Ort; die gewaehlte Schule bleibt in der Liste, auch wenn sie nicht passt.
  const gefiltert = suche.trim()
    ? sucheSchulen(
        schulen.map((s) => ({ ...s, stadtteil: null })),
        suche,
        schulen.length,
      )
    : schulen
  const sichtbar = gefiltert.some((s) => s.id === value)
    ? gefiltert
    : [...schulen.filter((s) => s.id === value), ...gefiltert]
  const beschriftung = (s: Schule): string =>
    [s.name, s.schulform ? ta(`intake.optionen.schulform.${s.schulform}`) : null, s.ort]
      .filter(Boolean)
      .join(' · ')

  return (
    <div className="flex flex-col gap-2">
      {!readOnly && (
        <Input
          value={suche}
          placeholder={t('schule.suche')}
          aria-label={t('schule.suche')}
          onChange={(e) => setSuche(e.target.value)}
        />
      )}
      <select
        id="vertrag-schule"
        className={SELECT_MD}
        value={value}
        disabled={readOnly}
        onChange={(e) => {
          if (e.target.value === NEU) {
            setName(freitext)
            setAnlegen(true)
            return
          }
          const treffer = schulen.find((s) => s.id === e.target.value)
          onChange(e.target.value, treffer?.name ?? '')
        }}
      >
        <option value="">{t('form.choose')}</option>
        {sichtbar.map((s) => (
          <option key={s.id} value={s.id}>
            {beschriftung(s)}
          </option>
        ))}
        {!readOnly && <option value={NEU}>{t('schule.new')}</option>}
      </select>
    </div>
  )
}
