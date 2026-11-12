import { useCallback, useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EdvanceCard, EmptyState, LoadingPulse, ToastBanner } from '@/components/edvance'
import { EdvanceTable, type Spalte } from '@/components/edvance/EdvanceTable'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { Button } from '@/components/ui/button'
import { archivWiederherstellen, listArchiv } from '@/lib/supabase/archiv'
import type { ArchivGrund, ArchivZeile } from '@/types/archiv'

const AUSWAHL_KLASSE =
  'min-h-[44px] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm text-[var(--color-text-primary)]'

/**
 * Archiv der Aufgaben (MSA-1 M3): die einzige Stelle, an der archivierte Aufgaben zu sehen sind. Nur Admins,
 * erreichbar über den Textlink „Archiv (n)“ am Fuß der Item-Pflege, nicht über die Navigation.
 * Filter nach Skill und Grund, Vorschau des Aufgabentexts, Wiederherstellen einzeln oder für die Auswahl nach einer
 * Rückfrage (inline, CLAUDE.md §11: keine Modals für einfache Bestätigungen). Einen Löschen-Knopf gibt es nicht.
 */
export function ArchivPage(): JSX.Element {
  const { t, i18n } = useTranslation('authoring')
  const [zeilen, setZeilen] = useState<ArchivZeile[] | null>(null)
  const [fehler, setFehler] = useState<string | null>(null)
  const [skill, setSkill] = useState('')
  const [grund, setGrund] = useState<'' | ArchivGrund>('')
  const [auswahl, setAuswahl] = useState<Set<string>>(new Set())
  const [vorschau, setVorschau] = useState<string | null>(null)
  const [rueckfrage, setRueckfrage] = useState<string[] | null>(null)
  const [arbeitet, setArbeitet] = useState(false)
  const [meldung, setMeldung] = useState<string | null>(null)

  const laden = useCallback(async () => {
    const res = await listArchiv()
    setFehler(res.error)
    setZeilen(res.data ?? [])
  }, [])

  useEffect(() => {
    void laden()
  }, [laden])

  const datum = useMemo(
    () => new Intl.DateTimeFormat(i18n.language, { day: '2-digit', month: '2-digit', year: 'numeric', timeZone: 'Europe/Berlin' }),
    [i18n.language],
  )

  const skills = useMemo(() => {
    const je = new Map<string, string>()
    for (const z of zeilen ?? []) if (z.skill_key) je.set(z.skill_key, z.skill_label ?? z.skill_key)
    return [...je.entries()].sort((a, b) => a[1].localeCompare(b[1], i18n.language))
  }, [zeilen, i18n.language])

  const treffer = (zeilen ?? []).filter((z) => (!skill || z.skill_key === skill) && (!grund || z.grund === grund))
  const ausgewaehlt = treffer.filter((z) => auswahl.has(z.id)).map((z) => z.id)
  const vorschauZeile = treffer.find((z) => z.id === vorschau) ?? null

  const umschalten = (id: string): void =>
    setAuswahl((alt) => {
      const neu = new Set(alt)
      if (neu.has(id)) neu.delete(id)
      else neu.add(id)
      return neu
    })

  const wiederherstellen = async (ids: string[]): Promise<void> => {
    setArbeitet(true)
    const res = await archivWiederherstellen(ids)
    setArbeitet(false)
    setRueckfrage(null)
    if (res.error) {
      setFehler(res.error)
      return
    }
    setMeldung(t('archiv.wiederhergestellt', { count: res.data ?? 0 }))
    setAuswahl(new Set())
    setVorschau(null)
    await laden()
  }

  const spalten: Spalte<ArchivZeile>[] = [
    {
      key: 'wahl',
      kopf: t('archiv.spalte.auswahl'),
      zelle: (z) => (
        <label className="inline-flex min-h-[44px] min-w-[44px] items-center justify-center">
          <input
            type="checkbox"
            checked={auswahl.has(z.id)}
            onChange={() => umschalten(z.id)}
            aria-label={t('archiv.aktion.auswaehlen', { text: z.kurztext })}
            className="h-4 w-4 accent-[var(--color-primary)]"
          />
        </label>
      ),
    },
    {
      key: 'text',
      kopf: t('archiv.spalte.aufgabe'),
      zelle: (z) => (
        <button
          type="button"
          onClick={() => setVorschau(vorschau === z.id ? null : z.id)}
          className="min-h-[44px] text-left text-[var(--color-text-link)] hover:underline"
        >
          {z.kurztext}
        </button>
      ),
    },
    { key: 'skill', kopf: t('archiv.spalte.skill'), zelle: (z) => z.skill_label ?? z.skill_key ?? t('archiv.ohneSkill') },
    { key: 'status', kopf: t('archiv.spalte.status'), zelle: (z) => t(`archiv.status.${z.status}`, { defaultValue: z.status }) },
    { key: 'grund', kopf: t('archiv.spalte.grund'), zelle: (z) => t(`archiv.grund.${z.grund}`) },
    {
      key: 'am',
      kopf: t('archiv.spalte.am'),
      zelle: (z) => <span className="tabular-nums">{datum.format(new Date(z.archiviert_am))}</span>,
    },
    { key: 'von', kopf: t('archiv.spalte.von'), zelle: (z) => z.archiviert_von ?? t('archiv.system') },
    {
      key: 'aktion',
      kopf: t('archiv.spalte.aktion'),
      zelle: (z) => (
        <Button variant="outline" size="sm" className="min-h-[44px]" onClick={() => setRueckfrage([z.id])}>
          {t('archiv.aktion.wiederherstellen')}
        </Button>
      ),
    },
  ]

  return (
    <div className="flex flex-col gap-6">
      <PageHeader titel={t('archiv.titel')} zurueckZu="/admin/authoring" zurueckLabel={t('page.backToList')} />
      <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{t('archiv.erklaerung')}</p>

      {meldung && <ToastBanner type="success" message={meldung} onClose={() => setMeldung(null)} />}
      {fehler && <EmptyState icon="⚠️" title={t('archiv.fehler')} description={fehler} />}
      {!fehler && zeilen === null && <LoadingPulse type="list" lines={4} />}
      {!fehler && zeilen !== null && zeilen.length === 0 && (
        <EmptyState icon="🗂️" title={t('archiv.leerTitel')} description={t('archiv.leerText')} />
      )}

      {!fehler && zeilen !== null && zeilen.length > 0 && (
        <>
          <div className="flex flex-wrap items-end gap-4">
            <label className="flex flex-col gap-2 text-xs text-[var(--color-text-tertiary)]">
              {t('archiv.filter.skill')}
              <select className={AUSWAHL_KLASSE} value={skill} onChange={(e) => setSkill(e.target.value)}>
                <option value="">{t('archiv.filter.alle')}</option>
                {skills.map(([key, label]) => (
                  <option key={key} value={key}>
                    {label}
                  </option>
                ))}
              </select>
            </label>
            <label className="flex flex-col gap-2 text-xs text-[var(--color-text-tertiary)]">
              {t('archiv.filter.grund')}
              <select className={AUSWAHL_KLASSE} value={grund} onChange={(e) => setGrund(e.target.value as '' | ArchivGrund)}>
                <option value="">{t('archiv.filter.alle')}</option>
                <option value="nicht_notwendig">{t('archiv.grund.nicht_notwendig')}</option>
                <option value="sonstiges">{t('archiv.grund.sonstiges')}</option>
              </select>
            </label>
            <span className="text-xs text-[var(--color-text-tertiary)] tabular-nums">
              {t('archiv.anzahl', { count: treffer.length })}
            </span>
            <Button
              className="min-h-[44px]"
              disabled={ausgewaehlt.length === 0}
              title={ausgewaehlt.length === 0 ? t('archiv.aktion.keineAuswahl') : undefined}
              onClick={() => setRueckfrage(ausgewaehlt)}
            >
              {t('archiv.aktion.auswahlWiederherstellen', { count: ausgewaehlt.length })}
            </Button>
          </div>

          {rueckfrage && (
            <EdvanceCard variant="subtle" className="p-6">
              <div className="flex flex-wrap items-center gap-4" role="alertdialog" aria-label={t('archiv.rueckfrage.titel')}>
                <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
                  {t('archiv.rueckfrage.text', { count: rueckfrage.length })}
                </p>
                <Button className="min-h-[44px]" disabled={arbeitet} onClick={() => void wiederherstellen(rueckfrage)}>
                  {t('archiv.rueckfrage.ja')}
                </Button>
                <Button variant="outline" className="min-h-[44px]" disabled={arbeitet} onClick={() => setRueckfrage(null)}>
                  {t('archiv.rueckfrage.nein')}
                </Button>
              </div>
            </EdvanceCard>
          )}

          {vorschauZeile && (
            <EdvanceCard variant="subtle" className="p-6">
              <div className="flex flex-col gap-2">
                <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                  {t('archiv.vorschau')}
                </span>
                <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{vorschauZeile.kurztext}</p>
                <Link to={`/admin/authoring/${vorschauZeile.id}`} className="text-sm text-[var(--color-text-link)] hover:underline">
                  {t('archiv.oeffnen')}
                </Link>
              </div>
            </EdvanceCard>
          )}

          <EdvanceTable spalten={spalten} zeilen={treffer} zeileKey={(z) => z.id} beschriftung={t('archiv.titel')} />
        </>
      )}
    </div>
  )
}
