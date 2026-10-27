import { useState } from 'react'
import { useTranslation } from 'react-i18next'

import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import type { KaPlanThema, KaSchulArbeit } from '@/lib/supabase/kaFolge'

import { OptionChips } from '../intake/OptionChips'

export type KaKorrektur = { nr: number; themaKeys: string[]; datum: string | null; vorherNr: number | null }

/**
 * Eine abgeleitete Arbeit einer Schule und Klasse (L5, Entscheidung 7): Nummer bzw. Datum, Themen, wie viele Kinder
 * übereinstimmen, Stand (gültig/bestätigt). „Bestätigen“ übernimmt sie, „Korrigieren“ öffnet die Felder inline.
 * Ohne Nummer lässt sie sich nur über „Korrigieren“ bestätigen (der Button sagt warum).
 */
export function KaArbeitKarte({
  arbeit,
  plan,
  busy,
  onBestaetigen,
}: {
  arbeit: KaSchulArbeit
  plan: KaPlanThema[]
  busy: boolean
  onBestaetigen: (k: KaKorrektur) => void
}): JSX.Element {
  const { t, i18n } = useTranslation('admin')
  const [offen, setOffen] = useState(false)
  const [nr, setNr] = useState(arbeit.nr === null ? '' : String(arbeit.nr))
  const [themen, setThemen] = useState(arbeit.themaKeys)
  const [datum, setDatum] = useState(arbeit.datum ?? '')
  const titel = new Map(plan.map((p) => [p.themaKey, p.titel]))
  const k = 'klassenarbeiten'
  const datumText = arbeit.datum
    ? new Intl.DateTimeFormat(i18n.language, { dateStyle: 'medium', timeZone: 'Europe/Berlin' }).format(new Date(`${arbeit.datum}T12:00:00Z`))
    : null
  const nrZahl = Number(nr)
  const nrGut = Number.isInteger(nrZahl) && nrZahl >= 1 && nrZahl <= 8

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6" data-testid="ka-arbeit">
      <div className="flex flex-wrap items-center gap-2">
        <h3 className="text-base font-semibold">
          {arbeit.nr !== null ? t(`${k}.arbeit`, { n: arbeit.nr }) : t(`${k}.ohneNummer`)}
        </h3>
        {arbeit.bestaetigt ? (
          <EdvanceBadge variant="primary">{t(`${k}.bestaetigt`)}</EdvanceBadge>
        ) : arbeit.gueltig ? (
          <EdvanceBadge variant="warning">{t(`${k}.gueltig`)}</EdvanceBadge>
        ) : (
          <EdvanceBadge variant="muted">{t(`${k}.offen`)}</EdvanceBadge>
        )}
      </div>
      <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
        {arbeit.themaKeys.map((key) => titel.get(key) ?? key).join(' · ')}
      </p>
      <p className="text-xs text-[var(--color-text-tertiary)]">
        {[datumText, t(`${k}.kinder`, { count: arbeit.kinder })].filter(Boolean).join(' · ')}
      </p>

      {offen ? (
        <div className="flex flex-col gap-4" data-testid="ka-korrektur">
          <label className="flex flex-col gap-2 text-sm">
            <span>{t(`${k}.nummer`)}</span>
            <Input type="number" min={1} max={8} className="min-h-11 max-w-[8rem]" value={nr} onChange={(e) => setNr(e.target.value)} />
          </label>
          <OptionChips
            options={plan.map((p) => ({ value: p.themaKey, label: p.titel }))}
            selected={themen}
            onToggle={(key) => setThemen(themen.includes(key) ? themen.filter((x) => x !== key) : [...themen, key])}
            columns
          />
          <label className="flex flex-col gap-2 text-sm">
            <span>{t(`${k}.datum`)}</span>
            <Input type="date" className="min-h-11 max-w-xs" value={datum} onChange={(e) => setDatum(e.target.value)} />
          </label>
          <Button
            className="min-h-11 self-start"
            disabled={busy || !nrGut || themen.length === 0}
            title={!nrGut || themen.length === 0 ? t(`${k}.korrekturFehlt`) : undefined}
            onClick={() => onBestaetigen({ nr: nrZahl, themaKeys: themen, datum: datum || null, vorherNr: arbeit.bestaetigt ? arbeit.nr : null })}
          >
            {t(`${k}.speichern`)}
          </Button>
        </div>
      ) : (
        <div className="flex flex-wrap gap-2">
          {!arbeit.bestaetigt && (
            <Button
              className="min-h-11"
              disabled={busy || arbeit.nr === null}
              title={arbeit.nr === null ? t(`${k}.nummerFehlt`) : undefined}
              onClick={() =>
                arbeit.nr !== null &&
                onBestaetigen({ nr: arbeit.nr, themaKeys: arbeit.themaKeys, datum: arbeit.datum, vorherNr: null })
              }
            >
              {t(`${k}.bestaetigen`)}
            </Button>
          )}
          <Button variant="outline" className="min-h-11" disabled={busy} onClick={() => setOffen(true)}>
            {t(`${k}.korrigieren`)}
          </Button>
        </div>
      )}
    </EdvanceCard>
  )
}
