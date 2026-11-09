import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'

import { EdvanceBadge, EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { getLsaPaketSkills } from '@/lib/supabase/lsaAbdeckung'
import type { LsaAbdeckungZeile, LsaPaketSkill } from '@/types'

import { AMPEL_KLASSE } from './AbdeckungMatrix'

/** Ein Skill einmal je Paket: Pflicht, wenn er in Fall A oder B Pflicht ist. */
function zusammen(skills: LsaPaketSkill[]): LsaPaketSkill[] {
  const je = new Map<string, LsaPaketSkill>()
  for (const s of skills) {
    const alt = je.get(s.skill_key)
    if (!alt || (s.pflicht && !alt.pflicht)) je.set(s.skill_key, s)
  }
  return [...je.values()]
}

/** Aufgaben, die Lena für das Paket noch prüft (je fehlendem Skill so viele, wie Vorschläge für den Bedarf da sind). */
export const nochZuPruefen = (skills: LsaPaketSkill[]): number =>
  zusammen(skills).filter((s) => !s.erfuellt).reduce((n, s) => n + s.vorschlaege, 0)

/**
 * Paket-Detail (F2 Punkt 3): Themen, Pflicht- und Tiefe-Skills mit Stand, fehlende Texte und „Lena prüft dafür noch
 * n Aufgaben“. Skills ohne Vorschlag brauchen eine neue Aufgabe (F4).
 */
export function PaketDetail({ paket }: { paket: LsaAbdeckungZeile }): JSX.Element {
  const { t, i18n } = useTranslation('admin')
  const [skills, setSkills] = useState<LsaPaketSkill[] | null>(null)
  const [fehler, setFehler] = useState(false)

  useEffect(() => {
    let aktiv = true
    setSkills(null)
    void getLsaPaketSkills(paket.schule_id, paket.klasse, paket.paket_nr).then((r) => {
      if (!aktiv) return
      setFehler(r.error !== null)
      setSkills(r.data ?? [])
    })
    return () => {
      aktiv = false
    }
  }, [paket.schule_id, paket.klasse, paket.paket_nr])

  const datum = paket.datum
    ? new Intl.DateTimeFormat(i18n.language, { dateStyle: 'medium', timeZone: 'Europe/Berlin' }).format(new Date(`${paket.datum}T12:00:00Z`))
    : null
  const liste = skills ? zusammen(skills) : []
  const gruppe = (pflicht: boolean): LsaPaketSkill[] =>
    liste.filter((s) => s.pflicht === pflicht).sort((a, b) => Number(a.erfuellt) - Number(b.erfuellt))

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <div className="flex flex-col gap-2">
        <span className={`self-start rounded-[var(--radius-md)] border px-2 py-1 text-xs font-semibold ${AMPEL_KLASSE[paket.ampel]}`}>
          {t(`lsaAbdeckung.ampel.${paket.ampel}`)}
        </span>
        <h2 className="text-base font-semibold">{paket.schule} · {t('lsaAbdeckung.klasseNr', { klasse: paket.klasse, nr: paket.paket_nr })}</h2>
        <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
          {paket.thema_labels.join(', ')}
          {' · '}
          {t(`lsaAbdeckung.quelle.${paket.quelle}`)}
          {datum ? ` · ${datum}` : ''}
        </p>
        {!paket.hat_einstieg && <p className="text-sm text-[var(--color-text-secondary)]">{t('lsaAbdeckung.ohneEinstieg')}</p>}
      </div>
      {skills === null && !fehler && <LoadingPulse type="list" lines={4} />}
      {fehler && <EmptyState icon="⚠️" title={t('lsaAbdeckung.ladeFehler')} description={t('lsaAbdeckung.ladeFehlerText')} />}
      {skills !== null && !fehler && (
        <>
          <p className="text-sm font-semibold" data-testid="lena-satz">
            {t('lsaAbdeckung.lenaPrueft', { count: nochZuPruefen(skills) })}
            {paket.fehlende_texte > 0 && ` · ${t('lsaAbdeckung.fehlendeTexte', { count: paket.fehlende_texte })}`}
          </p>
          {[true, false].map((pflicht) => (
            <section key={String(pflicht)} className="flex flex-col gap-2">
              <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                {t(pflicht ? 'lsaAbdeckung.pflicht' : 'lsaAbdeckung.tiefe')}
              </h3>
              {gruppe(pflicht).length === 0 ? (
                <p className="text-sm text-[var(--color-text-secondary)]">{t('lsaAbdeckung.keineSkills')}</p>
              ) : (
                <ul className="flex flex-col gap-2">
                  {gruppe(pflicht).map((s) => (
                    <li key={s.skill_key} className="flex items-start justify-between gap-2 text-sm" title={s.skill_key}>
                      <span className="flex flex-col">
                        <span>{s.skill_label}</span>
                        {!s.erfuellt && (
                          <span className="text-xs text-[var(--color-text-tertiary)]">
                            {s.vorschlaege > 0
                              ? t('lsaAbdeckung.skillOffen', { texte: s.fehlende_texte, count: s.vorschlaege })
                              : t('lsaAbdeckung.skillNeu', { count: s.fehlende_texte })}
                          </span>
                        )}
                      </span>
                      <EdvanceBadge variant={s.erfuellt ? 'success' : 'warning'}>
                        {t(s.erfuellt ? 'lsaAbdeckung.erfuellt' : 'lsaAbdeckung.fehlt')}
                      </EdvanceBadge>
                    </li>
                  ))}
                </ul>
              )}
            </section>
          ))}
        </>
      )}
    </EdvanceCard>
  )
}
