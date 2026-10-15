import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { EmptyState, LoadingPulse, WochenNavigation } from '@/components/edvance'
import { montagVon } from '@/components/edvance/wochenNavigation.model'
import { Label } from '@/components/ui/label'
import { SELECT_MD } from '@/lib/formStyles'
import { ladeEinstellungen } from '@/lib/supabase/slotplan'
import { ladeSessionLeitung, ladeStundenplanWoche } from '@/lib/supabase/stundenplan'
import { datumLang } from '../slotsFormat'
import { useSlotsLaden } from '../useSlotsLaden'
import { SofortKnopf } from '../sofort/SofortKnopf'
import { SessionKarte } from './SessionKarte'
import { SessionPlanen } from './SessionPlanen'
import { nachCoach, nachTag } from './stundenplan.model'

/**
 * Reiter Stundenplan (Slots S2, Entscheidung 2–4): alle Einzel-Sessions der Woche nach Tag, Filter nach Leitung,
 * „Session planen“ für später. „Session jetzt starten“ steht im Seitenkopf; ist die Woche leer, auch hier.
 */
export function StundenplanReiter({ montag, onWoche }: { montag: string; onWoche: (m: string) => void }): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const woche = useSlotsLaden(() => ladeStundenplanWoche(montag), `stundenplan:${montag}`)
  const leitung = useSlotsLaden(() => ladeSessionLeitung(), 'leitung')
  const einst = useSlotsLaden(() => ladeEinstellungen(), 'einstellungen')
  const [coach, setCoach] = useState('')

  const daten = woche.daten?.montag === montag ? woche.daten : null
  const tage = daten ? nachTag(nachCoach(daten.sessions, coach)) : []

  const angelegt = (datum: string): void => {
    const m = montagVon(datum)
    if (m === montag) woche.neuLaden()
    else onWoche(m)
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <WochenNavigation montag={montag} onWechsel={onWoche} />
        <div className="flex flex-col gap-2">
          <Label htmlFor="sp-filter">{t('stundenplan.filter.label')}</Label>
          <select id="sp-filter" className={SELECT_MD} value={coach} onChange={(e) => setCoach(e.target.value)}>
            <option value="">{t('stundenplan.filter.alle')}</option>
            {(leitung.daten ?? []).map((l) => (
              <option key={l.id} value={l.id}>
                {l.rolle === 'admin' ? t('stundenplan.feld.leitungAdmin', { name: l.name }) : l.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {leitung.daten && einst.daten && (
        <SessionPlanen leitung={leitung.daten} raeume={einst.daten.raeume} onAngelegt={angelegt} />
      )}

      {woche.fehler && !daten ? (
        <p role="alert" className="text-sm text-[var(--color-error-coach)]">{t(woche.fehler)}</p>
      ) : !daten ? (
        <LoadingPulse type="list" lines={6} />
      ) : tage.length === 0 ? (
        <EmptyState
          icon="📅"
          title={t(coach ? 'stundenplan.leer.coachTitel' : 'stundenplan.leer.titel')}
          description={t('stundenplan.leer.text')}
          action={<SofortKnopf variante="outline" />}
        />
      ) : (
        tage.map((tag) => (
          <section key={tag.datum} className="flex flex-col gap-4" aria-label={datumLang(tag.datum, i18n.language)}>
            <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
              {datumLang(tag.datum, i18n.language)}
            </h2>
            <div className="grid grid-cols-1 gap-4 @4xl:grid-cols-2">
              {tag.sessions.map((s) => (
                <SessionKarte key={s.session_id} session={s} onGeaendert={woche.neuLaden} />
              ))}
            </div>
          </section>
        ))
      )}
    </div>
  )
}
