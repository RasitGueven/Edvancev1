import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { EmptyState, LoadingPulse } from '@/components/edvance'
import { Modal } from '@/components/edvance/Modal'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { ladeKandidatenAlle, stammplatzVergeben, zusatzterminBuchen } from '@/lib/supabase/slotplan'
import { slotsFehlerSchluessel } from '@/lib/slots/fehler'
import type { SlotsKandidatAlle, SlotsTermin, TerminRaum } from '@/types/slotplan'
import { datumLang, datumVoll, wochentagName } from '../slotsFormat'
import { KlasseFach } from '../KlasseFach'
import { isoWochentag, PLAETZE } from '../wochenplan/wochenplan.model'
import { grundSchluesselKandidat, kandidatenSortiert, stammplatzZeile, type KindModus } from './kandidaten.model'

type Props = {
  termin: SlotsTermin
  raum: TerminRaum
  onClose: () => void
  onGespeichert: (meldung: string) => void
}

/**
 * Dialog „Kind in <Raum>“ (W2, Entscheidung 7): „Nur an diesem Termin“ bucht einen Zusatztermin fest in diesem Raum,
 * „Jede Woche“ vergibt einen Stammplatz an Wochentag, Uhrzeit und Raum ab dem Termindatum. Die Liste zeigt alle
 * Kinder aus slots_kandidaten_alle; nicht buchbare stehen ausgegraut mit ihrem Grund als Satz.
 */
export function KindInRaumDialog({ termin, raum, onClose, onGespeichert }: Props): JSX.Element {
  const { t, i18n } = useTranslation('slots')
  const [kandidaten, setKandidaten] = useState<SlotsKandidatAlle[] | null>(null)
  const [modus, setModus] = useState<KindModus>('einmal')
  const [suche, setSuche] = useState('')
  const [wahl, setWahl] = useState<string | null>(null)
  const [fehler, setFehler] = useState<string | null>(null)
  const [speichert, setSpeichert] = useState(false)

  useEffect(() => {
    let aktiv = true
    void ladeKandidatenAlle(termin.datum, termin.zeit.id, raum.raum_id).then((res) => {
      if (!aktiv) return
      if (res.error !== null) setFehler(slotsFehlerSchluessel(res))
      setKandidaten(res.data ?? [])
    })
    return () => {
      aktiv = false
    }
  }, [termin.datum, termin.zeit.id, raum.raum_id])

  const gewaehlt = kandidaten?.find((k) => k.student_id === wahl) ?? null
  const liste = kandidatenSortiert(kandidaten ?? [], suche)
  const tagLang = wochentagName(isoWochentag(termin.datum), i18n.language, true)

  const grund = (k: SlotsKandidatAlle): string | null => {
    const s = grundSchluesselKandidat(k.code)
    return s ? t(s, { datum: k.datum ? datumVoll(k.datum, i18n.language) : '' }) : null
  }
  const stammText = (k: SlotsKandidatAlle): string =>
    k.stammplaetze.length === 0
      ? t('wochenplan2.kind.ohneStammplatz')
      : t('wochenplan2.kind.stammplatz', {
          liste: k.stammplaetze
            .map((s) =>
              t(s.takt === 'woechentlich' ? 'wochenplan2.kind.stammKurz' : 'wochenplan2.kind.stammKurzTakt', {
                tag: wochentagName(s.wochentag, i18n.language),
                beginn: s.beginn,
                raum: s.raum_name ?? t('wochenplan2.kind.raumAutomatisch'),
                takt: s.takt === 'woechentlich' ? '' : t(`takt.${s.takt}`),
              }),
            )
            .join(', '),
        })

  const speichern = async (): Promise<void> => {
    if (!gewaehlt) return
    setSpeichert(true)
    setFehler(null)
    const res =
      modus === 'einmal'
        ? await zusatzterminBuchen(gewaehlt.student_id, termin.datum, termin.zeit.id, raum.raum_id)
        : await stammplatzVergeben(gewaehlt.student_id, [stammplatzZeile(termin.datum, termin.zeit.id, raum.raum_id)], termin.datum)
    setSpeichert(false)
    if (res.error !== null) return setFehler(slotsFehlerSchluessel(res))
    onGespeichert(
      t(modus === 'einmal' ? 'wochenplan2.kind.gebuchtEinmal' : 'wochenplan2.kind.gebuchtJedeWoche', {
        name: gewaehlt.name ?? t('kind.ohneName'),
        raum: raum.name,
      }),
    )
  }

  const MODI: KindModus[] = ['einmal', 'jedeWoche']
  return (
    <Modal
      open
      onClose={onClose}
      size="md"
      title={t('wochenplan2.kind.titel', { raum: raum.name })}
      description={t('wochenplan2.kind.kopf', {
        datum: datumLang(termin.datum, i18n.language),
        beginn: termin.zeit.beginn,
        coach: raum.coach_name ?? t('termin.keinCoach'),
        belegt: raum.kinder.length,
        max: PLAETZE,
      })}
      footer={
        <div className="flex w-full flex-col items-end gap-2">
          <div className="flex gap-2">
            <Button type="button" variant="ghost" onClick={onClose}>{t('dialog.abbrechen')}</Button>
            <Button type="button" onClick={() => void speichern()} disabled={!gewaehlt || speichert} loading={speichert}>
              {t(modus === 'einmal' ? 'wochenplan2.kind.speichernEinmal' : 'wochenplan2.kind.speichernJedeWoche')}
            </Button>
          </div>
          {!gewaehlt && <p className="text-xs text-[var(--color-text-tertiary)]">{t('wochenplan2.kind.waehlen')}</p>}
        </div>
      }
    >
      <div className="flex flex-col gap-4">
        <div role="group" aria-label={t('wochenplan2.kind.modusLabel')} className="inline-flex self-start overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-border)]">
          {MODI.map((m) => (
            <button
              key={m}
              type="button"
              aria-pressed={modus === m}
              onClick={() => setModus(m)}
              className={`min-h-[44px] px-4 text-sm ${
                modus === m
                  ? 'bg-[var(--color-primary)] font-semibold text-[var(--color-text-inverse)]'
                  : 'bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)] hover:bg-[var(--color-bg-subtle)]'
              }`}
            >
              {t(`wochenplan2.kind.modus.${m}`)}
            </button>
          ))}
        </div>
        <p className="text-sm text-[var(--color-text-secondary)]">
          {modus === 'einmal'
            ? t('wochenplan2.kind.satzEinmal')
            : t('wochenplan2.kind.satzJedeWoche', { tag: tagLang, beginn: termin.zeit.beginn, raum: raum.name, ab: datumVoll(termin.datum, i18n.language) })}
        </p>
        <Input type="search" value={suche} onChange={(e) => setSuche(e.target.value)} placeholder={t('wochenplan2.kind.suche')} aria-label={t('wochenplan2.kind.suche')} />

        {!kandidaten ? (
          <LoadingPulse type="list" lines={4} />
        ) : kandidaten.length === 0 ? (
          fehler ? null : (
          <EmptyState icon="🧒" title={t('stundenplan.auswahl.leerTitel')} description={t('stundenplan.auswahl.leerText')} />
          )
        ) : liste.length === 0 ? (
          <p className="text-sm text-[var(--color-text-tertiary)]">{t('stundenplan.auswahl.keinTreffer')}</p>
        ) : (
          <ul className="flex max-h-80 flex-col overflow-y-auto rounded-[var(--radius-md)] border border-[var(--color-border)]" aria-label={t('stundenplan.auswahl.liste')}>
            {liste.map((k) => {
              const satz = grund(k)
              const an = wahl === k.student_id
              return (
                <li key={k.student_id} className="border-t border-[var(--color-border)] first:border-t-0">
                  <button
                    type="button"
                    disabled={satz !== null}
                    aria-pressed={an}
                    onClick={() => setWahl(k.student_id)}
                    className={`flex min-h-[52px] w-full items-center gap-2 px-3 py-2 text-left ${
                      satz !== null
                        ? 'cursor-not-allowed text-[var(--color-text-tertiary)]'
                        : an
                          ? 'bg-[var(--color-primary-light)] shadow-[inset_3px_0_0_var(--color-primary)]'
                          : 'hover:bg-[var(--color-primary-light)]'
                    }`}
                  >
                    <span className="flex min-w-0 flex-1 flex-col">
                      <span className="truncate text-sm font-semibold">{k.name ?? t('kind.ohneName')}</span>
                      <KlasseFach klasse={k.klasse} fach={k.fach} test={k.ist_test} />
                    </span>
                    <span className={`max-w-[50%] text-right text-xs ${satz !== null ? 'text-[var(--color-error-coach)]' : 'text-[var(--color-text-tertiary)]'}`}>
                      {satz ?? stammText(k)}
                    </span>
                  </button>
                </li>
              )
            })}
          </ul>
        )}
        {fehler && <p role="alert" className="text-sm text-[var(--color-error-coach)]">{t(fehler)}</p>}
      </div>
    </Modal>
  )
}
