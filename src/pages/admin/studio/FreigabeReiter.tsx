import { useCallback, useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'

import { EdvanceBadge, EdvanceCard, LoadingPulse } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import {
  ladeFreigabeStand,
  pruefeAusgabe,
  pruefeSequenz,
  reicheSequenzEin,
  zieheSequenzZurueck,
} from '@/lib/supabase/studio'
import type { Skript } from '@/studio/skript/typen'
import type { StudioFreigabeStand, StudioFreigabeWelt } from '@/types/studio'

import { PruefBox } from './PruefBox'
import { RenderPanel } from './RenderPanel'
import { VariantenTexte } from './VariantenTexte'

const datum = (iso: string, sprache: string): string =>
  new Intl.DateTimeFormat(sprache, { dateStyle: 'medium', timeStyle: 'short', timeZone: 'Europe/Berlin' }).format(new Date(iso))

/**
 * Reiter Freigabe (Anforderung Studio §8): geschrieben, verständlich, fachlich, Varianten-Texte je Welt, Stimme und
 * Render. Kinder sehen eine Welt erst, wenn alles erteilt und der Render aktuell ist (studio_ausgabe); bis dahin die
 * alte Fassung. Rechte und „Prüfer ≠ Autor“ prüft die Datenbank; die Knöpfe zeigen den Grund als Tooltip.
 */
export function FreigabeReiter({
  sequenzId,
  skript,
  stand: aenderung,
  onGeaendert,
}: {
  sequenzId: string
  skript: Skript
  stand: string
  onGeaendert: () => void
}): JSX.Element {
  const { t, i18n } = useTranslation('studio')
  const [stand, setStand] = useState<StudioFreigabeStand | null>(null)
  const [meldung, setMeldung] = useState<string | null>(null)

  const lade = useCallback(async () => {
    const r = await ladeFreigabeStand(sequenzId)
    setStand(r.data)
  }, [sequenzId])
  useEffect(() => {
    void lade()
  }, [lade, aenderung])

  const ergebnis = async (aufruf: Promise<{ data: string[] | null; error: { message: string } | null }>): Promise<void> => {
    const r = await aufruf
    if (r.error) setMeldung(t('freigabe.fehler', { grund: r.error.message }))
    else
      setMeldung(
        r.data && r.data.length > 0
          ? t('freigabe.freigegebenWelten', { welten: r.data.map((w) => t(`welt.${w}`)).join(', ') })
          : t('freigabe.gespeichert'),
      )
    await lade()
    onGeaendert()
  }

  if (!stand) return <LoadingPulse type="list" lines={4} />
  const beats = skript.beats.map((b) => ({ key: b.id, titel: b.titel }))
  const eingereicht = stand.status === 'in_pruefung' || stand.status === 'freigegeben'
  const sperre = (darf: boolean): string | null =>
    stand.ich_bin_autor ? t('freigabe.autorGesperrt') : !darf ? t('freigabe.rolleFehlt') : !eingereicht ? t('freigabe.nichtEingereicht') : null
  const skelett = stand.welten.find((w) => w.welt === 'skelett')
  const pruefZustand = (gueltig: boolean | undefined, art: string, welt = 'skelett'): JSX.Element => {
    const letzte = stand.pruefungen.find((p) => p.art === art && p.welt === welt)
    return (
      <EdvanceBadge variant={gueltig ? 'strength' : 'muted'}>
        {gueltig ? t('freigabe.gueltig') : letzte?.ergebnis === 'passt' ? t('freigabe.veraltet') : t('freigabe.offen')}
      </EdvanceBadge>
    )
  }
  const ausgabe = (w: StudioFreigabeWelt): JSX.Element => (
    <div className="flex flex-col gap-2 text-xs text-[var(--color-text-muted)]">
      <span>
        {w.ausgabe && !w.ausgabe.zurueckgezogen ? t('freigabe.ausgabe', { datum: datum(w.ausgabe.freigegeben_am, i18n.language) }) : t('freigabe.keineAusgabe')}
      </span>
      {w.fehlt.length > 0 && <span>{t('freigabe.fehlt', { liste: w.fehlt.map((f) => t(`freigabe.fehltCode.${f}`)).join(', ') })}</span>}
    </div>
  )
  const anmerkungen = stand.pruefungen.filter((p) => p.ergebnis === 'passt_nicht')

  return (
    <div className="flex flex-col gap-4" data-testid="studio-freigabe">
      <EdvanceCard>
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex flex-col gap-2">
            <h3 className="text-base font-semibold">{t('freigabe.geschrieben')}</h3>
            <p className="text-sm text-[var(--color-text-secondary)]">
              {t('freigabe.geschriebenVon', { autor: stand.autor ?? '–', datum: datum(stand.geschrieben_am, i18n.language) })}
            </p>
          </div>
          <Button
            disabled={!stand.darf.einreichen || eingereicht}
            title={!stand.darf.einreichen || eingereicht ? t('freigabe.einreichenTooltip') : undefined}
            onClick={() => void reicheSequenzEin(sequenzId).then((r) => ergebnis(Promise.resolve({ data: [], error: r.error })))}
          >
            {t('freigabe.einreichen')}
          </Button>
        </div>
      </EdvanceCard>

      {(['verstaendlich', 'fachlich'] as const).map((art) => (
        <EdvanceCard key={art}>
          <div className="flex flex-col gap-4">
            <div className="flex flex-wrap items-center gap-2">
              <h3 className="text-base font-semibold">{t(`freigabe.${art}`)}</h3>
              {pruefZustand(skelett?.gueltig[art], art)}
            </div>
            <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{t(`freigabe.${art}Satz`)}</p>
            <PruefBox
              beats={beats}
              passtText={t(art === 'verstaendlich' ? 'freigabe.verstanden' : 'freigabe.passt')}
              passtNichtText={t(art === 'verstaendlich' ? 'freigabe.anmerkung' : 'freigabe.passtNicht')}
              gesperrt={sperre(stand.darf[art])}
              onPasst={() => void ergebnis(pruefeSequenz(sequenzId, art, 'skelett', 'passt'))}
              onPasstNicht={(b, k) => void ergebnis(pruefeSequenz(sequenzId, art, 'skelett', 'passt_nicht', b, k))}
            />
            {skelett && art === 'fachlich' && ausgabe(skelett)}
          </div>
        </EdvanceCard>
      ))}

      {stand.welten
        .filter((w) => w.welt !== 'skelett')
        .map((w) => (
          <EdvanceCard key={w.welt}>
            <div className="flex flex-col gap-4">
              <div className="flex flex-wrap items-center gap-2">
                <h3 className="text-base font-semibold">
                  {t('freigabe.varianten')} · {t(`welt.${w.welt}`)}
                </h3>
                {pruefZustand(w.gueltig.variante, 'variante', w.welt)}
              </div>
              <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{t('freigabe.variantenSatz')}</p>
              <VariantenTexte skript={skript} welt={w.welt} />
              <PruefBox
                beats={beats}
                passtText={t('freigabe.passt')}
                passtNichtText={t('freigabe.passtNicht')}
                gesperrt={sperre(stand.darf.fachlich)}
                onPasst={() => void ergebnis(pruefeSequenz(sequenzId, 'variante', w.welt, 'passt'))}
                onPasstNicht={(b, k) => void ergebnis(pruefeSequenz(sequenzId, 'variante', w.welt, 'passt_nicht', b, k))}
              />
              {ausgabe(w)}
            </div>
          </EdvanceCard>
        ))}

      <RenderPanel sequenzId={sequenzId} stand={aenderung} onFertig={() => void ergebnis(pruefeAusgabe(sequenzId))} />

      <EdvanceCard>
        <div className="flex flex-col gap-2" data-testid="studio-anmerkungen">
          <h3 className="text-base font-semibold">{t('freigabe.verlauf')}</h3>
          {anmerkungen.length === 0 ? (
            <p className="text-sm text-[var(--color-text-muted)]">{t('freigabe.verlaufLeer')}</p>
          ) : (
            anmerkungen.map((a, i) => (
              <p key={i} className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
                <span className="font-semibold">{t('freigabe.amBeat', { beat: a.beat_key })}</span> · {a.person} ·{' '}
                {t(`freigabe.${a.art === 'variante' ? 'varianten' : a.art}`)}: {a.kommentar}
              </p>
            ))
          )}
        </div>
      </EdvanceCard>

      {stand.darf.zurueckziehen && (
        <div className="flex flex-wrap items-center gap-2">
          <Button
            variant="destructive"
            onClick={() => void zieheSequenzZurueck(sequenzId).then((r) => ergebnis(Promise.resolve({ data: [], error: r.error })))}
          >
            {t('freigabe.zurueckziehen')}
          </Button>
          <span className="text-xs text-[var(--color-text-muted)]">{t('freigabe.zurueckziehenSatz')}</span>
        </div>
      )}
      {meldung && <p className="text-sm text-[var(--color-text-secondary)]">{meldung}</p>}
    </div>
  )
}
