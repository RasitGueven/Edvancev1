import { useCallback, useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { EdvanceBadge, EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { formatBerlinDateTime, formatDateOnly } from '@/lib/datetime'
import {
  getKindZugang,
  kindGeraetAbmelden,
  listKindGeraete,
  zugangscodeFreischalten,
  zugangscodeNeu,
  type KindGeraet,
  type KindZugang,
} from '@/lib/supabase/kindGeraete'
import { ZugangscodeFeld } from '../vertraege/ZugangscodeFeld'

/**
 * Reihe 1 · D1: Geräte der Home-App und der Zugangscode, nur für Admins.
 *
 * Höchstens drei Geräte je Kind sind angemeldet. „Gerät abmelden“ löscht die Sitzung des Geräts; das Kind
 * landet dort wieder auf „Code eingeben“. Ein neuer Code macht den alten sofort ungültig, angemeldete
 * Geräte bleiben angemeldet. Bestätigt wird inline, nicht im Modal.
 */
export function GeraeteKachel({ studentId }: { studentId: string }): JSX.Element {
  const { t, i18n } = useTranslation('akte')
  const lang = i18n.language
  const [geraete, setGeraete] = useState<KindGeraet[] | null>(null)
  const [zugang, setZugang] = useState<KindZugang | null>(null)
  const [fehler, setFehler] = useState<string | null>(null)
  const [frage, setFrage] = useState<string | null>(null) // Gerät, dessen Abmeldung gerade bestätigt wird
  const [laeuft, setLaeuft] = useState(false)

  const laden = useCallback((): void => {
    void Promise.all([listKindGeraete(studentId), getKindZugang(studentId)]).then(([g, z]) => {
      setGeraete(g.data ?? [])
      setZugang(z.data)
      setFehler(g.error ?? z.error ? t('geraete.fehlerLaden') : null)
    })
  }, [studentId, t])

  useEffect(laden, [laden])

  const ausfuehren = async (aktion: () => Promise<{ error: string | null }>): Promise<void> => {
    setLaeuft(true)
    setFehler(null)
    const { error } = await aktion()
    setLaeuft(false)
    setFrage(null)
    if (error) setFehler(t('geraete.fehlerAktion'))
    laden()
  }

  const aktiv = (geraete ?? []).filter((g) => g.abgemeldet_am === null)
  const frueher = (geraete ?? []).filter((g) => g.abgemeldet_am !== null).slice(0, 3)

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('geraete.titel')}
      </h2>
      {fehler && <p className="text-sm text-[var(--color-error-exam)]">{fehler}</p>}

      {geraete === null ? (
        <LoadingPulse type="list" lines={3} />
      ) : (
        <>
          {aktiv.length === 0 ? (
            <EmptyState icon="📱" title={t('geraete.leerTitel')} description={t('geraete.leer')} />
          ) : (
            <ul className="flex flex-col gap-4" data-testid="geraete-aktiv">
              {aktiv.map((g) => (
                <li key={g.id} className="flex flex-col gap-2 border-b border-[var(--color-border)] pb-4 last:border-b-0 last:pb-0">
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="text-base font-semibold text-[var(--color-text-primary)]">{g.name}</span>
                    <EdvanceBadge variant="muted">{t(`geraete.plattform.${g.plattform}`)}</EdvanceBadge>
                  </div>
                  <p className="text-xs text-[var(--color-text-tertiary)]">
                    {t('geraete.seit', {
                      seit: formatBerlinDateTime(g.angemeldet_am, lang),
                      zuletzt: formatBerlinDateTime(g.zuletzt_gesehen, lang),
                    })}
                  </p>
                  {frage === g.id ? (
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="text-sm text-[var(--color-text-secondary)]">{t('geraete.abmeldenFrage')}</span>
                      <Button size="sm" variant="destructive" className="min-h-11" disabled={laeuft}
                        onClick={() => void ausfuehren(() => kindGeraetAbmelden(g.id))}>
                        {t('geraete.abmeldenJa')}
                      </Button>
                      <Button size="sm" variant="outline" className="min-h-11" onClick={() => setFrage(null)}>
                        {t('geraete.abbrechen')}
                      </Button>
                    </div>
                  ) : (
                    <div>
                      <Button size="sm" variant="outline" className="min-h-11" onClick={() => setFrage(g.id)}>
                        {t('geraete.abmelden')}
                      </Button>
                    </div>
                  )}
                </li>
              ))}
            </ul>
          )}
          <p className="text-xs text-[var(--color-text-tertiary)]">{t('geraete.grenze', { anzahl: aktiv.length })}</p>
          {frueher.length > 0 && (
            <p className="text-xs text-[var(--color-text-tertiary)]">
              {t('geraete.frueher', {
                liste: frueher.map((g) => `${g.name} (${formatBerlinDateTime(g.abgemeldet_am as string, lang)})`).join(', '),
              })}
            </p>
          )}
        </>
      )}

      {zugang && (
        <div className="flex flex-col gap-2 border-t border-[var(--color-border)] pt-4">
          <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('geraete.code')}
          </span>
          <ZugangscodeFeld code={zugang.zugangscode} />
          {zugang.zugangscode_gesperrt_am ? (
            <div className="flex flex-wrap items-center gap-2">
              <span className="text-sm text-[var(--color-error-exam)]">
                {t('geraete.gesperrt', { datum: formatDateOnly(zugang.zugangscode_gesperrt_am, lang) })}
              </span>
              <Button size="sm" variant="outline" className="min-h-11" disabled={laeuft}
                onClick={() => void ausfuehren(() => zugangscodeFreischalten(zugang.vertrag_id))}>
                {t('geraete.freischalten')}
              </Button>
            </div>
          ) : (
            zugang.zugangscode_erzeugt_am && (
              <span className="text-xs text-[var(--color-text-tertiary)]">
                {t('geraete.erzeugt', { datum: formatDateOnly(zugang.zugangscode_erzeugt_am, lang) })}
              </span>
            )
          )}
          {/* Einen gesperrten Code erst freischalten; vertrag_zugangscode_neu lehnt ihn sonst ab. */}
          {zugang.zugangscode_gesperrt_am ? null : frage === 'code' ? (
            <div className="flex flex-wrap items-center gap-2">
              <span className="text-sm text-[var(--color-text-secondary)]">{t('geraete.neuFrage')}</span>
              <Button size="sm" className="min-h-11" disabled={laeuft}
                onClick={() => void ausfuehren(() => zugangscodeNeu(zugang.vertrag_id))}>
                {t('geraete.neuJa')}
              </Button>
              <Button size="sm" variant="outline" className="min-h-11" onClick={() => setFrage(null)}>
                {t('geraete.abbrechen')}
              </Button>
            </div>
          ) : (
            <div>
              <Button size="sm" variant="outline" className="min-h-11" onClick={() => setFrage('code')}>
                {t('geraete.neu')}
              </Button>
            </div>
          )}
        </div>
      )}
    </EdvanceCard>
  )
}
