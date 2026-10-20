import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { ladeEinstellungen, ladeTag } from '@/lib/supabase/slotplan'
import { ladeSessionLeitung } from '@/lib/supabase/stundenplan'
import { berlinToday } from '@/lib/datetime'
import type { SlotZeit, SlotsWoche, TagRaumTermin, WocheZelle } from '@/types/slotplan'
import { kalenderwoche, montagVon } from '@/components/edvance/wochenNavigation.model'
import { datumLang } from '../slotsFormat'
import { zelleVon } from '../slots.model'
import { useSlotsLaden } from '../useSlotsLaden'
import { RaumZeile } from '../wochenplan/RaumZeile'
import { tagZeilen, type Panel } from '../wochenplan/wochenplan.model'
import { EinzelKurz } from './EinzelKurz'
import { SessionPlanen } from './SessionPlanen'
import { Seitenpanel } from './Seitenpanel'

/** Ohne passende Woche: die Uhrzeiten, die slots_tag kennt. */
function zeitenAusTag(rt: TagRaumTermin[]): SlotZeit[] {
  const m = new Map(rt.map((r) => [r.zeit_id, { id: r.zeit_id, beginn: r.beginn, ende: r.ende }]))
  return [...m.values()]
}

type Props = {
  datum: string
  /** Angezeigte Woche (Uhrzeiten, „läuft gerade“); passt sie nicht zum Tag, gelten die Uhrzeiten aus slots_tag. */
  woche: SlotsWoche | null
  onPanel: (panel: Panel) => void
  onClose: () => void
  onGeaendert: () => void
}

/**
 * Tagespanel (W2, Entscheidung 5): je Stunde die Räume mit Punkten, Coach und n/5, groß die freien Plätze und
 * „Öffnen“ ins Slot-Panel; Einzel-Sessions an ihrer Uhrzeit; unten „+ Einzel-Session an diesem Tag planen“.
 * Zweck: am Telefon sofort sagen können, wo etwas frei ist.
 */
export function TagPanel({ datum, woche, onPanel, onClose, onGeaendert }: Props): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const tag = useSlotsLaden(() => ladeTag(datum), datum)
  const leitung = useSlotsLaden(() => ladeSessionLeitung(), 'leitung')
  const einst = useSlotsLaden(() => ladeEinstellungen(), 'einstellungen')
  const d = tag.daten?.datum === datum ? tag.daten : null
  const w = woche && woche.montag === montagVon(datum) ? woche : null
  const zeiten = w?.zeiten ?? zeitenAusTag(d?.raum_termine ?? [])
  // Kinder ohne Raum und „läuft gerade“ kennt nur die Woche (slots_tag liefert beides nicht).
  const zelleZu = (zeitId: string): WocheZelle | undefined => (w ? zelleVon(w, datum, zeitId) : undefined)
  const zeilen = d ? tagZeilen(zeiten, d.raum_termine, d.sessions_ohne_raum) : []
  const frei = zeilen.reduce((s, z) => s + (z.art === 'slot' ? z.frei : 0), 0)
  const kinder = d ? d.raum_termine.reduce((s, r) => s + r.belegt, 0) : 0

  const titel = datumLang(datum, i18n.language)
  return (
    <Seitenpanel
      rubrik={t('wochenplan2.tag.rubrik', { kw: kalenderwoche(datum) })}
      titel={titel}
      satz={d ? t('wochenplan2.tag.satz', { frei, count: kinder }) : undefined}
      breit
      onClose={onClose}
    >
      {tag.fehler && !d ? (
        <p role="alert" className="text-sm text-[var(--color-text-secondary)]">{t(tag.fehler)}</p>
      ) : !d ? (
        <LoadingPulse type="list" lines={5} />
      ) : !d.betrieb ? (
        <EdvanceCard>
          <EmptyState icon="🗓️" title={d.anlass ?? t('woche.keinBetrieb')} description={t('woche.keinBetriebTag', { anlass: d.anlass ?? t('woche.keinBetrieb') })} />
        </EdvanceCard>
      ) : (
        <EdvanceCard className="flex flex-col p-0">
          <ul className="flex flex-col">
            {zeilen.map((z) =>
              z.art === 'einzel' ? (
                <li key={z.s.session_id} className="border-t border-[var(--color-border)] px-4 py-2 first:border-t-0">
                  <EinzelKurz alsZeile session={z.s} onOeffnen={() => onPanel({ art: 'einzel', datum, sessionId: z.s.session_id })} />
                </li>
              ) : (
                <li
                  key={z.zeit.id}
                  className="grid grid-cols-[3.5rem_minmax(0,1fr)_auto] items-center gap-4 border-t border-[var(--color-border)] px-4 py-4 first:border-t-0"
                >
                  <span className="text-base font-semibold tabular-nums text-[var(--color-text-primary)]">{z.zeit.beginn}</span>
                  <span className="flex min-w-0 flex-col gap-1">
                    {z.raeume.length === 0 ? (
                      <span className="text-sm text-[var(--color-text-tertiary)]">{t('woche.keinRaum')}</span>
                    ) : (
                      z.raeume.map((r) => (
                        <RaumZeile key={r.raum_id} name={r.raum_name} belegt={r.belegt} mitCoach={r.offen} coach={r.offen ? r.coach_name : null} />
                      ))
                    )}
                    {(zelleZu(z.zeit.id)?.ohne_raum ?? 0) > 0 && (
                      <span className="text-xs font-semibold text-[var(--color-error-coach)]">
                        {t('woche.ohneRaum', { count: zelleZu(z.zeit.id)?.ohne_raum ?? 0 })}
                      </span>
                    )}
                    {zelleZu(z.zeit.id)?.laeuft && (
                      <EdvanceBadge variant="primary" className="self-start">{t('wochenplan2.zelle.laeuft')}</EdvanceBadge>
                    )}
                  </span>
                  <span className="flex items-center gap-4">
                    <span className="flex flex-col items-end">
                      <span className={`font-serif text-2xl font-semibold tabular-nums ${z.frei > 0 ? 'text-[var(--color-text-primary)]' : 'text-[var(--color-text-tertiary)]'}`}>
                        {z.frei}
                      </span>
                      <span className="text-xs text-[var(--color-text-tertiary)]">{t('wochenplan2.tag.frei')}</span>
                    </span>
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      className="min-h-[44px]"
                      aria-label={t('wochenplan2.tag.oeffnenUm', { beginn: z.zeit.beginn })}
                      onClick={() => onPanel({ art: 'slot', datum, zeitId: z.zeit.id })}
                    >
                      {t('wochenplan2.oeffnen')}
                    </Button>
                  </span>
                </li>
              ),
            )}
          </ul>
        </EdvanceCard>
      )}

      {d?.betrieb && datum >= berlinToday() && leitung.daten && einst.daten && (
        <SessionPlanen
          key={datum}
          datum={datum}
          leitung={leitung.daten}
          raeume={einst.daten.raeume}
          onAngelegt={() => {
            tag.neuLaden()
            onGeaendert()
          }}
        />
      )}
    </Seitenpanel>
  )
}
