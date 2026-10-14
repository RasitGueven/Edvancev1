import { useEffect, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  EdvanceCard,
  EdvanceBadge,
  EmptyState,
  LoadingPulse,
} from '@/components/edvance'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { getCoaches } from '@/lib/supabase/profiles'
import { coachEinladen, einladungErneut, getKontoStand, type KontoStand } from '@/lib/supabase/coachEinladen'
import type { Coach } from '@/types'

type Meldung = { art: 'ok' | 'fehler'; text: string }

/**
 * Coaches einladen (Konto K1). Der Admin traegt Name und Mail ein; das
 * Passwort legt der Coach selbst fest. Je Konto steht, ob die Einladung
 * angenommen ist; offene Einladungen lassen sich erneut senden.
 */
export function CoachesPage(): JSX.Element {
  const { t, i18n } = useTranslation('admin')
  const [coaches, setCoaches] = useState<Coach[]>([])
  const [stand, setStand] = useState<Map<string, KontoStand> | null>(null)
  const [loading, setLoading] = useState(true)
  const [meldung, setMeldung] = useState<Meldung | null>(null)

  const [vorname, setVorname] = useState('')
  const [nachname, setNachname] = useState('')
  const [email, setEmail] = useState('')
  const [saving, setSaving] = useState(false)
  const [erneutFuer, setErneutFuer] = useState<string | null>(null)

  const datum = new Intl.DateTimeFormat(i18n.language, { dateStyle: 'medium', timeZone: 'Europe/Berlin' })

  const load = (): void => {
    setLoading(true)
    void Promise.all([getCoaches(), getKontoStand()]).then(([c, s]) => {
      setCoaches(c.data ?? [])
      setStand(s.data ? new Map(s.data.map((z) => [z.id, z])) : null)
      if (c.error) setMeldung({ art: 'fehler', text: c.error })
      else if (s.error) setMeldung({ art: 'fehler', text: t('coaches.fehler.stand') })
      setLoading(false)
    })
  }

  useEffect(load, [])

  const submit = async (): Promise<void> => {
    if (vorname.trim() === '' || nachname.trim() === '' || email.trim() === '') {
      setMeldung({ art: 'fehler', text: t('coaches.pflichtfelder') })
      return
    }
    setSaving(true)
    setMeldung(null)
    const { error } = await coachEinladen({ vorname, nachname, email })
    setSaving(false)
    if (error) {
      setMeldung({ art: 'fehler', text: t(`coaches.fehler.${error}`) })
      return
    }
    setMeldung({ art: 'ok', text: t('coaches.eingeladen', { email: email.trim() }) })
    setVorname('')
    setNachname('')
    setEmail('')
    load()
  }

  const erneut = async (c: Coach): Promise<void> => {
    setErneutFuer(c.id)
    setMeldung(null)
    const { error } = await einladungErneut(c.id)
    setErneutFuer(null)
    if (error) {
      setMeldung({ art: 'fehler', text: t(`coaches.fehler.${error}`) })
      return
    }
    setMeldung({ art: 'ok', text: t('coaches.erneutGesendet', { name: c.full_name ?? t('coaches.unbenannt') }) })
    load()
  }

  const standZeile = (c: Coach): { text: string; offen: boolean } => {
    const z = stand?.get(c.id)
    if (!z) return { text: t('coaches.stand.unbekannt'), offen: false }
    if (z.bestaetigt_at) return { text: t('coaches.stand.aktiv', { datum: datum.format(new Date(z.bestaetigt_at)) }), offen: false }
    if (z.eingeladen_at) {
      return { text: t('coaches.stand.eingeladen', { datum: datum.format(new Date(z.eingeladen_at)) }), offen: true }
    }
    return { text: t('coaches.stand.unbekannt'), offen: false }
  }

  return (
    <>
      <PageHeader rubrik={t('coaches.rubrik')} titel={t('coaches.titel')} satz={t('coaches.satz')} />

      {/* Formular bleibt schmal und steht links; die Liste nutzt die volle Breite. */}
      <div className="flex flex-col gap-6 @4xl:max-w-3xl">
        {meldung && (
          <p
            role={meldung.art === 'fehler' ? 'alert' : 'status'}
            className={`text-sm ${meldung.art === 'fehler' ? 'text-[var(--color-error-exam)]' : 'text-[var(--color-success)]'}`}
          >
            {meldung.text}
          </p>
        )}

        <EdvanceCard className="flex flex-col gap-4 p-6">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('coaches.neu')}
          </p>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div className="flex flex-col gap-2">
              <Label htmlFor="c-vorname">{t('coaches.vorname')}</Label>
              <Input id="c-vorname" autoComplete="off" value={vorname} onChange={(e) => setVorname(e.target.value)} />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="c-nachname">{t('coaches.nachname')}</Label>
              <Input id="c-nachname" autoComplete="off" value={nachname} onChange={(e) => setNachname(e.target.value)} />
            </div>
            <div className="flex flex-col gap-2 sm:col-span-2">
              <Label htmlFor="c-email">{t('coaches.email')}</Label>
              <Input id="c-email" type="email" autoComplete="off" value={email} onChange={(e) => setEmail(e.target.value)} />
            </div>
          </div>
          <p className="text-xs text-[var(--color-text-tertiary)]">{t('coaches.hinweis')}</p>
          <div>
            <Button onClick={() => void submit()} loading={saving}>
              {saving ? t('coaches.laedtEin') : t('coaches.einladen')}
            </Button>
          </div>
        </EdvanceCard>
      </div>

      <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('coaches.bestehende')}
      </p>
      {loading ? (
        <LoadingPulse type="list" lines={3} />
      ) : coaches.length === 0 ? (
        <EmptyState icon="🧑‍🏫" title={t('coaches.leer.titel')} description={t('coaches.leer.beschreibung')} />
      ) : (
        <div className="grid grid-cols-1 gap-4 @3xl:grid-cols-2 @6xl:grid-cols-3">
          {coaches.map((c) => {
            const s = standZeile(c)
            return (
              <EdvanceCard key={c.id} className="flex flex-col gap-4 p-6">
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <span className="text-base font-semibold text-[var(--color-text-primary)]">
                    {c.full_name ?? t('coaches.unbenannt')}
                  </span>
                  <EdvanceBadge variant={s.offen ? 'warning' : 'mastered'}>{t('coaches.rolle')}</EdvanceBadge>
                </div>
                <p className="text-xs text-[var(--color-text-tertiary)]">{s.text}</p>
                {s.offen && (
                  <div>
                    <Button variant="secondary" size="sm" loading={erneutFuer === c.id} onClick={() => void erneut(c)}>
                      {erneutFuer === c.id ? t('coaches.sendetErneut') : t('coaches.erneut')}
                    </Button>
                  </div>
                )}
              </EdvanceCard>
            )
          })}
        </div>
      )}
    </>
  )
}
