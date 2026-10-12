import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard, PlatzPunkte } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { SELECT_MD } from '@/lib/formStyles'
import { CardMenu, type CardMenuItem } from '@/pages/admin/leads/CardMenu'
import type { NichtDabei, SlotsTermin, TerminKind, TerminRaum, TerminZustand } from '@/types/slotplan'
import { datumKurz, zeitpunktKurz } from '../slotsFormat'
import { KlasseFach } from '../KlasseFach'

export type KindAktion = 'absage' | 'umbuchen' | 'ausgefallen' | { raum: string }

/** Zustand eines Kind-Termins als Abzeichen (Entscheidung 28). */
export function ZustandBadge({ zustand }: { zustand: TerminZustand }): JSX.Element {
  const { t } = useTranslation('slots')
  const variante = { planned: 'primary', present: 'strength', unexcused: 'coach-emergency', cancelled: 'muted', cancelled_by_us: 'muted' } as const
  return <EdvanceBadge variant={variante[zustand]}>{t(`zustand.${zustand}`)}</EdvanceBadge>
}

function KindKopf({ kind }: { kind: { student_id: string; name: string | null; klasse: number | null; fach: string | null; ist_test?: boolean } }): JSX.Element {
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
function Herkunft({ kind }: { kind: TerminKind }): JSX.Element | null {
  const { t, i18n } = useTranslation('slots')
  if (kind.umgebucht_von) return <EdvanceBadge variant="primary">{t('termin.umgebuchtVon', { datum: datumKurz(kind.umgebucht_von.datum, i18n.language) })}</EdvanceBadge>
  if (kind.herkunft === 'zusatz') return <EdvanceBadge variant="primary">{t('termin.zusatz')}</EdvanceBadge>
  return null
}

function FehlerZeile({ text }: { text: string | null }): JSX.Element | null {
  const { t } = useTranslation('slots')
  return text ? <p role="alert" className="text-xs text-[var(--color-error-coach)]">{t(text)}</p> : null
}

type KartenProps = {
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
      <h2 className="text-base font-semibold text-[var(--color-error-coach)]">{t('termin.ohneRaum.titel', { count: termin.ohne_raum.length })}</h2>
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

/** Eine Raum-Karte: Coach-Auswahl nur für diesen Termin, Kinder mit "…"-Menü, am Tag "Session öffnen". */
export function RaumKarte({
  raum,
  termin,
  ansicht,
  fehlerBei,
  onKind,
  onCoach,
  onSessionOeffnen,
}: KartenProps & {
  raum: TerminRaum
  onCoach: (raum: TerminRaum, coachId: string | null) => void
  onSessionOeffnen: (raum: TerminRaum) => void
}): JSX.Element {
  const { t } = useTranslation('slots')
  const andereRaeume = termin.raeume.filter((r) => r.offen && r.raum_id !== raum.raum_id)
  const coachWahl = termin.coaches.filter((c) => c.raum_id === null || c.raum_id === raum.raum_id)

  const menu = (k: TerminKind): CardMenuItem[] =>
    ansicht || raum.gestartet
      ? []
      : [
          { label: t('aktion.absage'), onSelect: () => onKind(k, 'absage') },
          { label: t('aktion.umbuchen'), onSelect: () => onKind(k, 'umbuchen') },
          ...andereRaeume.map((r) => ({ label: t('aktion.inRaum', { raum: r.name }), onSelect: () => onKind(k, { raum: r.raum_id }) })),
          { label: t('aktion.ausgefallen'), onSelect: () => onKind(k, 'ausgefallen'), danger: true },
        ]

  return (
    <EdvanceCard
      className={`flex flex-col gap-2 p-4 ${raum.offen ? '' : 'border-2 border-dashed border-[var(--color-border)] bg-[var(--color-bg-subtle)] shadow-none'}`}
    >
      <header className="flex flex-wrap items-center gap-2">
        <h2 className={`text-base font-semibold ${raum.offen ? '' : 'text-[var(--color-text-tertiary)]'}`}>{raum.name}</h2>
        {!raum.offen && raum.stamm_coach_id && termin.ohne_raum.length > 0 && (
          <EdvanceBadge variant="coach-emergency">{t('woche.coachFehlt')}</EdvanceBadge>
        )}
        {raum.vertretung && <EdvanceBadge variant="warning">{t('termin.vertretung')}</EdvanceBadge>}
        {raum.gemischt && <EdvanceBadge variant="warning">{t('termin.gemischt')}</EdvanceBadge>}
        <span className="ml-auto flex items-center gap-2">
          {raum.offen && <PlatzPunkte raeume={[raum.kinder.length]} mitZahl />}
        </span>
      </header>

      {ansicht ? (
        <p className="text-sm text-[var(--color-text-secondary)]">{raum.coach_name ?? t('termin.keinCoach')}</p>
      ) : (
        <label className="flex flex-col gap-2 text-xs text-[var(--color-text-tertiary)]">
          {raum.offen ? t('termin.coachNurHier') : t('termin.geschlossen', { coach: raum.stamm_coach_name ?? t('termin.keinCoach') })}
          <select
            className={SELECT_MD}
            value={raum.coach_id ?? ''}
            disabled={raum.gestartet}
            onChange={(e) => onCoach(raum, e.target.value || null)}
          >
            <option value="">{t(raum.offen ? 'termin.faelltAus' : 'termin.vertretungWaehlen')}</option>
            {coachWahl.map((c) => (
              <option key={c.id} value={c.id}>{c.name}</option>
            ))}
          </select>
          {raum.gestartet && <span>{t('termin.gestartet')}</span>}
        </label>
      )}
      <FehlerZeile text={fehlerBei?.ort === raum.raum_id ? fehlerBei.text : null} />

      {raum.offen && raum.kinder.length === 0 && <p className="text-sm text-[var(--color-text-tertiary)]">{t('termin.raumLeer')}</p>}
      <ul className="flex flex-col">
        {raum.kinder.map((k) => (
          <li key={k.termin_id} className="flex flex-col border-t border-[var(--color-border)] py-1">
            <div className="flex min-h-[44px] items-center justify-between gap-2">
              <span className="flex min-w-0 flex-wrap items-center gap-2">
                <KindKopf kind={k} />
                <Herkunft kind={k} />
                {ansicht &&
                  (k.zustand === 'planned' ? (
                    <EdvanceBadge variant="warning">{t('termin.anwesenheitOffen')}</EdvanceBadge>
                  ) : (
                    <ZustandBadge zustand={k.zustand} />
                  ))}
              </span>
              <CardMenu items={menu(k)} />
            </div>
            <FehlerZeile text={fehlerBei?.ort === k.termin_id ? fehlerBei.text : null} />
          </li>
        ))}
      </ul>

      {termin.heute && raum.offen && (
        <footer className="flex flex-wrap items-center justify-between gap-2 border-t border-[var(--color-border)] pt-2">
          {raum.session_id ? (
            <Link to={`/coach/session/${raum.session_id}/live`} className="inline-flex min-h-[44px] items-center text-sm font-semibold text-[var(--color-text-link)] hover:underline">
              {t('termin.liveSicht')}
            </Link>
          ) : (
            <Button type="button" variant="outline" size="sm" className="min-h-[44px]" onClick={() => onSessionOeffnen(raum)}>
              {t('termin.sessionOeffnen')}
            </Button>
          )}
        </footer>
      )}
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
      <h2 className="text-base font-semibold">{t('termin.nichtDabei')}</h2>
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
