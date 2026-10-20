import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { SELECT_MD } from '@/lib/formStyles'
import { CardMenu, type CardMenuItem } from '@/pages/admin/leads/CardMenu'
import type { TerminKind, TerminRaum } from '@/types/slotplan'
import { FARBE, Punkte } from '../wochenplan/RaumZeile'
import { PLAETZE, raumFarbe } from '../wochenplan/wochenplan.model'
import { RaumAktion } from './RaumAktion'
import { FehlerZeile, Herkunft, KindKopf, ZustandBadge, type KartenProps } from './TerminKarten'

type Props = KartenProps & {
  raum: TerminRaum
  onCoach: (raum: TerminRaum, coachId: string | null) => void
  /** „+ Kind in <Raum>“ (Entscheidung 7). */
  onKindPlus: (raum: TerminRaum) => void
}

/**
 * Ein Raum im Slot-Panel (W2, Entscheidung 6): Coach nur für diesen Termin, Belegung in der Farbe des Raums, Kinder
 * mit „…“-Menü (Absage, Umbuchen, anderer Raum, ausgefallen) und bei laufender Session „Live“, unten „+ Kind in …“
 * und rechts Session öffnen / Live-Sicht / Rückblick.
 */
export function RaumKarte({ raum, termin, ansicht, fehlerBei, onKind, onCoach, onKindPlus }: Props): JSX.Element {
  const { t } = useTranslation('slots')
  const andereRaeume = termin.raeume.filter((r) => r.offen && r.raum_id !== raum.raum_id && r.kinder.length < PLAETZE)
  const coachWahl = termin.coaches.filter((c) => c.raum_id === null || c.raum_id === raum.raum_id)
  const anzahl = raum.kinder.length
  const farbe = raumFarbe(anzahl, raum.offen)
  const voll = anzahl >= PLAETZE
  const live = termin.laeuft && raum.session_id ? `/coach/session/${raum.session_id}/live` : null

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
    <EdvanceCard className="flex flex-col gap-2 p-4">
      <header className="flex flex-wrap items-center gap-2">
        <h3 className="text-base font-semibold text-[var(--color-text-primary)]">{raum.name}</h3>
        {raum.vertretung && raum.offen && <EdvanceBadge variant="warning">{t('termin.vertretung')}</EdvanceBadge>}
        {raum.gemischt && <EdvanceBadge variant="warning">{t('termin.gemischt')}</EdvanceBadge>}
        <span className={`ml-auto flex items-center gap-2 rounded-[var(--radius-sm)] px-2 py-1 text-xs font-semibold tabular-nums ${FARBE[farbe].flaeche}`}>
          <Punkte belegt={anzahl} farbe={farbe} />
          {farbe === 'keinCoach' ? t('wochenplan2.raum.keinCoach') : t('wochenplan2.raum.belegt', { belegt: anzahl, max: PLAETZE })}
        </span>
      </header>

      {ansicht ? (
        <p className="text-sm text-[var(--color-text-secondary)]">{raum.coach_name ?? t('termin.keinCoach')}</p>
      ) : (
        <label className="flex flex-col gap-2 text-xs text-[var(--color-text-tertiary)]">
          {raum.offen ? t('termin.coachNurHier') : t('termin.geschlossen', { coach: raum.stamm_coach_name ?? t('termin.keinCoach') })}
          <select className={SELECT_MD} value={raum.coach_id ?? ''} disabled={raum.gestartet} onChange={(e) => onCoach(raum, e.target.value || null)}>
            <option value="">{t(raum.offen ? 'termin.faelltAus' : 'termin.vertretungWaehlen')}</option>
            {coachWahl.map((c) => (
              <option key={c.id} value={c.id}>{c.name}</option>
            ))}
          </select>
          {raum.gestartet && <span>{t('termin.gestartet')}</span>}
        </label>
      )}
      <FehlerZeile text={fehlerBei?.ort === raum.raum_id ? fehlerBei.text : null} />

      {!raum.offen && anzahl > 0 && (
        <p role="status" className="rounded-[var(--radius-md)] bg-[var(--color-error-coach-light)] px-3 py-2 text-sm text-[var(--color-error-coach)]">
          {raum.art === 'faellt_aus' && raum.stamm_coach_name ? `${t('wochenplan2.raum.faelltAus', { coach: raum.stamm_coach_name })} ` : ''}
          {t('wochenplan2.raum.ohneCoachSatz', { count: anzahl })}
        </p>
      )}
      {anzahl === 0 && (
        <p className="text-sm text-[var(--color-text-tertiary)]">{t(raum.offen ? 'termin.raumLeer' : 'wochenplan2.raum.geschlossenLeer')}</p>
      )}

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
              <span className="flex items-center gap-2">
                {live && (
                  <Link to={live} className="inline-flex min-h-[44px] items-center px-2 text-sm font-semibold text-[var(--color-text-link)] hover:underline">
                    {t('wochenplan2.kind.live')}
                  </Link>
                )}
                <CardMenu items={menu(k)} />
              </span>
            </div>
            <FehlerZeile text={fehlerBei?.ort === k.termin_id ? fehlerBei.text : null} />
          </li>
        ))}
      </ul>

      <footer className="flex flex-wrap items-center justify-between gap-2 border-t border-[var(--color-border)] pt-2">
        {!ansicht && termin.betrieb && raum.offen ? (
          <span className="flex flex-col gap-1">
            <Button
              type="button"
              variant="outline"
              size="sm"
              className="min-h-[44px] self-start"
              disabled={voll}
              title={voll ? t('wochenplan2.raum.vollGrund', { max: PLAETZE }) : undefined}
              onClick={() => onKindPlus(raum)}
            >
              {t('wochenplan2.raum.kindPlus', { raum: raum.name })}
            </Button>
            {voll && <span className="text-xs text-[var(--color-text-tertiary)]">{t('wochenplan2.raum.vollGrund', { max: PLAETZE })}</span>}
          </span>
        ) : (
          <span />
        )}
        <RaumAktion termin={termin} raum={raum} />
      </footer>
    </EdvanceCard>
  )
}
