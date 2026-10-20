import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import type { NichtDabei, SlotsTermin, TerminKind, TerminZustand } from '@/types/slotplan'
import { datumKurz, zeitpunktKurz } from '../slotsFormat'
import { KlasseFach } from '../KlasseFach'

export type KindAktion = 'absage' | 'umbuchen' | 'ausgefallen' | { raum: string }

/** Zustand eines Kind-Termins als Abzeichen (Entscheidung 28). */
export function ZustandBadge({ zustand }: { zustand: TerminZustand }): JSX.Element {
  const { t } = useTranslation('slots')
  const variante = { planned: 'primary', present: 'strength', unexcused: 'coach-emergency', cancelled: 'muted', cancelled_by_us: 'muted' } as const
  return <EdvanceBadge variant={variante[zustand]}>{t(`zustand.${zustand}`)}</EdvanceBadge>
}

export function KindKopf({ kind }: { kind: { student_id: string; name: string | null; klasse: number | null; fach: string | null; ist_test?: boolean } }): JSX.Element {
  const { t } = useTranslation('slots')
  return (
    <span className="flex min-w-0 flex-col">
      <Link to={`/admin/slots/kind/${kind.student_id}`} className="truncate text-sm font-semibold text-[var(--color-text-primary)] hover:underline">
        {kind.name ?? t('kind.ohneName')}
      </Link>
      <KlasseFach klasse={kind.klasse} fach={kind.fach} test={kind.ist_test} />
    </span>
  )
}

/** Abzeichen nur, wenn es nicht der Stammplatz ist: "umgebucht von Di 14.03." oder "Zusatz". */
export function Herkunft({ kind }: { kind: TerminKind }): JSX.Element | null {
  const { t, i18n } = useTranslation('slots')
  if (kind.umgebucht_von) return <EdvanceBadge variant="primary">{t('termin.umgebuchtVon', { datum: datumKurz(kind.umgebucht_von.datum, i18n.language) })}</EdvanceBadge>
  if (kind.herkunft === 'zusatz') return <EdvanceBadge variant="primary">{t('termin.zusatz')}</EdvanceBadge>
  return null
}

export function FehlerZeile({ text }: { text: string | null }): JSX.Element | null {
  const { t } = useTranslation('slots')
  return text ? <p role="alert" className="text-xs text-[var(--color-error-coach)]">{t(text)}</p> : null
}

export type KartenProps = {
  termin: SlotsTermin
  /** Termin vergangen: nur Ansicht. */
  ansicht: boolean
  fehlerBei: { ort: string; text: string } | null
  onKind: (kind: TerminKind, aktion: KindAktion) => void
}

/** "Ohne Raum" steht zuerst; je Kind genau zwei Knöpfe (Entscheidung 27). */
export function OhneRaumKarte({ termin, ansicht, fehlerBei, onKind }: KartenProps): JSX.Element {
  const { t } = useTranslation('slots')
  return (
    <EdvanceCard className="flex flex-col gap-2 border-l-[3px] border-[var(--color-error-coach)] bg-[var(--color-error-coach-light)] p-4">
      <h3 className="text-base font-semibold text-[var(--color-error-coach)]">{t('termin.ohneRaum.titel', { count: termin.ohne_raum.length })}</h3>
      <p className="text-sm text-[var(--color-text-secondary)]">{t(ansicht ? 'termin.ohneRaum.vergangen' : 'termin.ohneRaum.satz')}</p>
      <ul className="flex flex-col">
        {termin.ohne_raum.map((k) => (
          <li key={k.termin_id} className="flex flex-col gap-2 border-t border-[var(--color-border)] py-2">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <span className="flex min-w-0 items-center gap-2">
                <KindKopf kind={k} />
                <Herkunft kind={k} />
              </span>
              {!ansicht && (
                <span className="flex gap-2">
                  <Button type="button" variant="outline" size="sm" className="min-h-[44px]" onClick={() => onKind(k, 'umbuchen')}>
                    {t('aktion.umbuchen')}
                  </Button>
                  <Button type="button" variant="outline" size="sm" className="min-h-[44px]" onClick={() => onKind(k, 'ausgefallen')}>
                    {t('aktion.ausgefallen')}
                  </Button>
                </span>
              )}
            </div>
            <FehlerZeile text={fehlerBei?.ort === k.termin_id ? fehlerBei.text : null} />
          </li>
        ))}
      </ul>
    </EdvanceCard>
  )
}

/** Abgesagt, unentschuldigt, ausgefallen — mit Eingang und Rücknahme bis zum Beginn. */
export function NichtDabeiKarte({
  liste,
  ansicht,
  fehlerBei,
  onZuruecknehmen,
}: {
  liste: NichtDabei[]
  ansicht: boolean
  fehlerBei: { ort: string; text: string } | null
  onZuruecknehmen: (k: NichtDabei) => void
}): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  return (
    <EdvanceCard className="flex flex-col gap-2 p-4">
      <h3 className="text-base font-semibold">{t('termin.nichtDabei')}</h3>
      <ul className="flex flex-col">
        {liste.map((k) => (
          <li key={k.termin_id} className="flex flex-col border-t border-[var(--color-border)] py-1">
            <div className="flex min-h-[44px] flex-wrap items-center justify-between gap-2">
              <span className="flex min-w-0 flex-wrap items-center gap-2">
                <KindKopf kind={k} />
                <ZustandBadge zustand={k.zustand} />
                {k.rechtzeitig !== null && (
                  <EdvanceBadge variant={k.rechtzeitig ? 'strength' : 'coach-emergency'}>
                    {t(k.rechtzeitig ? 'termin.rechtzeitig' : 'termin.nichtRechtzeitig')}
                  </EdvanceBadge>
                )}
                {k.absage_eingang && (
                  <span className="text-xs tabular-nums text-[var(--color-text-tertiary)]">
                    {t('termin.eingang', { wann: zeitpunktKurz(k.absage_eingang, i18n.language) })}
                  </span>
                )}
              </span>
              {!ansicht && k.zuruecknehmbar && (
                <Button type="button" variant="ghost" size="sm" className="min-h-[44px]" onClick={() => onZuruecknehmen(k)}>
                  {t('aktion.zuruecknehmen')}
                </Button>
              )}
            </div>
            <FehlerZeile text={fehlerBei?.ort === k.termin_id ? fehlerBei.text : null} />
          </li>
        ))}
      </ul>
    </EdvanceCard>
  )
}
