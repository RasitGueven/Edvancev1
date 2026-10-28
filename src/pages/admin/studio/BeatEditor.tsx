import { useState } from 'react'
import { useTranslation } from 'react-i18next'

import { EdvanceCard, Reiterleiste, type Reiter } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { speichereStudioSkript } from '@/lib/supabase/studio'
import { BAUSTEINE } from '@/studio/skript/bausteine'
import { skriptPruefen } from '@/studio/skript/pruefen'
import type { Befund, Skript, SkriptBeat } from '@/studio/skript/typen'
import type { StudioWeltStand } from '@/types/studio'

import { BefundListe } from './BefundListe'
import { FELD, FELD_MONO } from './felder'

/**
 * Feinschliff im Beat-Editor (Anforderung Studio §3.3): Sprungmarke, Baustein, Parameter, Sprechtext je Welt,
 * Bildparameter je Welt. Gespeichert wird das ganze Skript über dieselbe Prüfung wie beim Einfügen — so gibt es
 * genau einen Schreibweg und die Zahlen-Sperre gilt auch für Änderungen.
 */
export function BeatEditor({
  sequenzId,
  skript,
  welten,
  katalog,
  onGespeichert,
}: {
  sequenzId: string
  skript: Skript
  welten: StudioWeltStand[]
  katalog: ReadonlySet<string> | null
  onGespeichert: () => void
}): JSX.Element {
  const { t } = useTranslation('studio')
  const [welt, setWelt] = useState('skelett')
  const [entwurf, setEntwurf] = useState<Skript>(skript)
  const [paramText, setParamText] = useState<Record<string, string>>({})
  const [befunde, setBefunde] = useState<Befund[]>([])
  const [fehler, setFehler] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  const geaendert = JSON.stringify(entwurf) !== JSON.stringify(skript) || Object.keys(paramText).length > 0

  const reiter: Reiter<string>[] = skript.welten.map((w) => ({
    key: w,
    titel: welten.find((x) => x.welt === w)?.gesperrt ? `${t(`welt.${w}`)} · ${t('kopf.gesperrt')}` : t(`welt.${w}`),
  }))

  const setzeBeat = (id: string, f: (b: SkriptBeat) => SkriptBeat): void =>
    setEntwurf((s) => ({ ...s, beats: s.beats.map((b) => (b.id === id ? f(b) : b)) }))

  const setzeText = (b: SkriptBeat, wert: string): void =>
    setzeBeat(b.id, (x) => {
      const text = { ...x.text }
      if (wert.trim() === '' && welt !== 'skelett') delete text[welt]
      else text[welt] = wert
      return { ...x, text }
    })

  const speichern = async (): Promise<void> => {
    setFehler(null)
    let s = entwurf
    try {
      for (const [id, txt] of Object.entries(paramText)) {
        const params = JSON.parse(txt) as Record<string, unknown>
        s = { ...s, beats: s.beats.map((b) => (b.id === id ? { ...b, params } : b)) }
      }
    } catch {
      setFehler(t('beat.jsonFehler'))
      return
    }
    const p = skriptPruefen(s, { katalog })
    setBefunde(p.befunde)
    if (!p.ok || !p.skript) return
    setBusy(true)
    const res = await speichereStudioSkript(sequenzId, p.skript, p)
    setBusy(false)
    if (res.error) setFehler(t('einfuegen.speicherFehler', { grund: res.error.message }))
    else {
      setParamText({})
      onGespeichert()
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <Reiterleiste reiter={reiter} aktiv={welt} onWechsel={setWelt} label={t('reiter.welten')} />
      {entwurf.beats.map((b) => (
        <EdvanceCard key={b.id}>
          <div className="flex flex-col gap-4" data-testid={`studio-beat-${b.id}`}>
            <div className="flex flex-wrap items-center gap-2">
              <span className="text-base font-semibold">{b.id}</span>
              <span className="text-xs text-[var(--color-text-muted)]">
                {t('beat.kernidee')} {b.kernidee}
              </span>
            </div>
            {welt === 'skelett' && (
              <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                <label className="flex flex-col gap-2 text-xs text-[var(--color-text-muted)]">
                  {t('beat.sprungmarke')}
                  <input className={FELD} value={b.titel} maxLength={40} onChange={(e) => setzeBeat(b.id, (x) => ({ ...x, titel: e.target.value }))} />
                </label>
                <label className="flex flex-col gap-2 text-xs text-[var(--color-text-muted)]">
                  {t('beat.baustein')}
                  <select className={FELD} value={b.baustein} onChange={(e) => setzeBeat(b.id, (x) => ({ ...x, baustein: e.target.value }))}>
                    {Object.keys(BAUSTEINE).map((k) => (
                      <option key={k} value={k}>
                        {k}
                      </option>
                    ))}
                  </select>
                </label>
                <label className="flex flex-col gap-2 text-xs text-[var(--color-text-muted)] md:col-span-2">
                  {t('beat.params')}
                  <textarea
                    className={`${FELD_MONO} min-h-[72px]`}
                    value={paramText[b.id] ?? JSON.stringify(b.params)}
                    onChange={(e) => setParamText((p) => ({ ...p, [b.id]: e.target.value }))}
                  />
                </label>
              </div>
            )}
            <label className="flex flex-col gap-2 text-xs text-[var(--color-text-muted)]">
              {t('beat.sprechtext', { welt: t(`welt.${welt}`) })}
              <textarea
                className={`${FELD} min-h-[64px]`}
                value={b.text[welt] ?? ''}
                placeholder={welt === 'skelett' ? undefined : b.text.skelett}
                onChange={(e) => setzeText(b, e.target.value)}
              />
              {welt !== 'skelett' && b.text[welt] === undefined && <span>{t('beat.wieSkelett')}</span>}
            </label>
          </div>
        </EdvanceCard>
      ))}
      {befunde.length > 0 && <BefundListe befunde={befunde} />}
      {fehler && <p className="text-sm text-[var(--color-error-coach)]">{fehler}</p>}
      <div className="flex flex-wrap gap-2">
        <Button onClick={() => void speichern()} disabled={!geaendert || busy} title={geaendert ? undefined : t('einfuegen.gesperrtTooltip')}>
          {t('beat.speichern')}
        </Button>
        {geaendert && (
          <Button
            variant="ghost"
            onClick={() => {
              setEntwurf(skript)
              setParamText({})
              setBefunde([])
            }}
          >
            {t('beat.verwerfen')}
          </Button>
        )}
      </div>
    </div>
  )
}
