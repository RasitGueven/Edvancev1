import { Link } from 'react-router-dom'
import { ArrowRight } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard, EmptyState } from '@/components/edvance'
import { PlatzPunkte } from '@/components/edvance/PlatzPunkte'
import type { LsaSessionListItem } from '@/types'
import type { SlotsTag } from '@/types/slotplan'
import { AbsagenHeute } from './AbsagenHeute'
import { BetriebAktionKnopf } from './BetriebAktionKnopf'
import { betriebAktion, betriebKinder, betriebZeilen } from './betriebModel'
import { berlinZeit } from './ListenVertrieb'

type Eintrag = {
  key: string; zeit: string; sortier: number; titel: string; marke?: JSX.Element; unterzeile: string; rechts: JSX.Element
  aktion?: JSX.Element
}

type Props = {
  tag: SlotsTag | null
  lsa: LsaSessionListItem[]
  /** i18n-Schlüssel im Namespace slots, wenn slots_tag scheitert. */
  tagFehler?: string | null
}

/**
 * Was heute im Haus passiert (Slots SL3): die Raum-Termine aus slots_tag (Zeit, Raum, Coach,
 * Platz-Punkte), die Einzel-Sessions und Testläufe ohne Raum-Termin (gekennzeichnet), die
 * Lernstandsanalysen von heute und darunter die Absagen des Tages. Jede Session steht genau einmal da;
 * Raum-Termine und Sessions tragen rechts genau eine Aktion (S3, betriebAktion).
 */
export function HeuteImBetrieb({ tag, lsa, tagFehler = null }: Props): JSX.Element {
  const { t, i18n } = useTranslation('admin')
  const { t: tSlots } = useTranslation('slots')
  const lang = i18n.language
  const zeilen = betriebZeilen(tag)
  const kinder = betriebKinder(zeilen)

  const eintraege: Eintrag[] = [
    ...zeilen.map((z): Eintrag =>
      z.art === 'raum'
        ? {
            key: z.key,
            zeit: z.t.beginn,
            sortier: z.sortier,
            titel: z.t.raum_name,
            unterzeile: z.t.art === 'faellt_aus' ? t('heute.betrieb.faelltAus') : (z.t.coach_name ?? t('heute.betrieb.ohneCoach')),
            rechts: <PlatzPunkte raeume={[z.t.belegt]} mitZahl />,
            aktion: tag ? <BetriebAktionKnopf aktion={betriebAktion(z, tag.datum)} /> : undefined,
          }
        : {
            key: z.key,
            zeit: berlinZeit(z.s.scheduled_at, lang, false),
            sortier: z.sortier,
            // room ist frei (Stundenplan) bzw. der Raumname einer Slot-Session; so, wie er ist.
            titel: z.s.room ?? t('heute.betrieb.session'),
            marke: (
              <EdvanceBadge variant={z.s.testlauf ? 'warning' : 'primary'}>
                {t(z.s.testlauf ? 'heute.betrieb.testlauf' : 'heute.betrieb.einzel')}
              </EdvanceBadge>
            ),
            unterzeile: z.s.coach_name ?? t('heute.betrieb.ohneCoach'),
            rechts: <PlatzPunkte raeume={[z.s.kinder]} mitZahl />,
            aktion: tag ? <BetriebAktionKnopf aktion={betriebAktion(z, tag.datum)} /> : undefined,
          },
    ),
    ...lsa.map((l) => {
      const zeitpunkt = l.started_at ?? l.completed_at
      return {
        key: `l-${l.session_id}`,
        zeit: zeitpunkt ? berlinZeit(zeitpunkt, lang, false) : '—',
        sortier: zeitpunkt ? new Date(zeitpunkt).getTime() : Number.MAX_SAFE_INTEGER,
        titel: l.first_name ?? '—',
        unterzeile: t('heute.betrieb.lsaMeta', { klasse: l.grade, fach: l.subject }),
        // LSA-R2: laufende LSA, die gerade durchgeklickt wird (listTodaysLsaSessions).
        marke: l.schnell ? (
          <span title={t('heute.betrieb.schnellTitel')}>
            <EdvanceBadge variant="warning">{t('heute.betrieb.schnell')}</EdvanceBadge>
          </span>
        ) : undefined,
        rechts: <EdvanceBadge variant="primary">{t('heute.betrieb.lsa')}</EdvanceBadge>,
      }
    }),
  ].sort((a, b) => a.sortier - b.sortier)

  return (
    <EdvanceCard className="flex flex-col gap-2 p-4">
      <h3 className="font-serif text-2xl font-semibold">
        {[t('heute.betrieb.sessions', { count: zeilen.length }), t('heute.betrieb.kinder', { count: kinder })].join(' · ')}
      </h3>
      <p className="text-xs text-[var(--color-text-tertiary)]">{t('heute.betrieb.lsaAnzahl', { count: lsa.length })}</p>
      {tagFehler && <p role="alert" className="text-xs text-[var(--color-error-coach)]">{tSlots(tagFehler)}</p>}
      {tag && !tag.betrieb && tag.anlass && (
        <p className="text-xs text-[var(--color-text-tertiary)]">{t('heute.betrieb.keinBetrieb', { anlass: tag.anlass })}</p>
      )}

      {eintraege.length === 0 ? (
        <EmptyState icon="🌤️" title={t('heute.betrieb.leerTitel')} description={t('heute.betrieb.leerText')} />
      ) : (
        <ol className="flex flex-col">
          {eintraege.map((e) => (
            <li
              key={e.key}
              className="grid min-h-[56px] grid-cols-[3.25rem_minmax(0,1fr)_auto] items-center gap-2 border-t border-[var(--color-border)] py-2"
            >
              <time className="text-sm font-semibold tabular-nums">{e.zeit}</time>
              <div className="flex min-w-0 flex-col">
                <span className="truncate text-sm font-semibold">{e.titel}</span>
                <span className="flex min-w-0 flex-wrap items-center gap-2">
                  <span className="truncate text-xs text-[var(--color-text-tertiary)]">{e.unterzeile}</span>
                  {e.marke}
                </span>
              </div>
              <div className="flex flex-wrap items-center justify-end gap-2">
                {e.rechts}
                {e.aktion}
              </div>
            </li>
          ))}
        </ol>
      )}

      <AbsagenHeute absagen={tag?.absagen ?? []} />

      <div className="flex justify-end border-t border-[var(--color-border)] pt-1">
        <Link
          to="/admin/slots"
          className="inline-flex min-h-[44px] items-center gap-2 text-sm font-semibold text-[var(--color-text-link)] hover:underline"
        >
          {t('heute.betrieb.fussWochenplan')}
          <ArrowRight aria-hidden="true" className="h-4 w-4" />
        </Link>
      </div>
    </EdvanceCard>
  )
}
