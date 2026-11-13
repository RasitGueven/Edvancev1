// FR-2 F3: Reiter „Gezielt prüfen“ im Lena-Board. Nur die Aufgaben, die einer Klassenarbeit wirklich einen fehlenden
// Beleg bringen (pruef_ziel_liste), gruppiert nach Thema, mit Wirkung. Klick öffnet die Prüfansicht mit
// ?liste=gezielt; dort geht es nach jeder Entscheidung mit der nächsten Aufgabe dieser Liste weiter.
// IU-1 U3: oben „Alle | MSA (ZP10)“ (?ziel=msa_zp10), Sprung aus der Inhalte-Übersicht mit ?skill= filtert auf eine
// Kompetenz. Der Prüfablauf bleibt unverändert.
// Keine Fachbegriffe (Pool, Textschlüssel, Hülle); der Skill-Schlüssel steht nur im Info-Hinweis.

import { useEffect, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { useSearchParams } from 'react-router-dom'
import { Info } from 'lucide-react'
import { EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { Button } from '@/components/ui'
import { naechsteZiel, neueSchulen, zielGruppen, zielReihe, zielStand } from '@/lib/pruefung/gezielt'
import { getLsaWirkung, getPruefZielListe, getPruefZielStand } from '@/lib/supabase/lsaAbdeckung'
import type { PruefBoardZeile, PruefZielStandZeile, PruefZielZeile } from '@/types'
import { AufgabenListe, FilterHinweis, PRUEFZIELE, ZielUmschalter } from './GezieltBausteine'
import { GezieltMsa } from './GezieltMsa'
import { leseUebersprungen } from './uebersprungen'

type Props = { board: PruefBoardZeile[]; onOeffne: (taskId: string) => void }

export function GezieltPruefen({ board, onOeffne }: Props): JSX.Element {
  const { t } = useTranslation('pruefen')
  const [params, setParams] = useSearchParams()
  const zielRoh = params.get('ziel')
  const ziel = (PRUEFZIELE as readonly string[]).includes(zielRoh ?? '') ? zielRoh : null
  const skill = params.get('skill')
  const [liste, setListe] = useState<PruefZielZeile[] | null>(null)
  const [stand, setStand] = useState<PruefZielStandZeile[] | null>(null)
  const [fehler, setFehler] = useState(false)
  const [schulen, setSchulen] = useState<number | null>(null)

  useEffect(() => {
    let aktiv = true
    setListe(null)
    setStand(null)
    void Promise.all([
      getPruefZielListe(false, null, { ziel, skill }),
      ziel ? getPruefZielStand(ziel) : Promise.resolve(null),
    ]).then(([r, s]) => {
      if (!aktiv) return
      setFehler(r.error !== null || (s !== null && s.error !== null))
      setListe(r.data ?? [])
      setStand(s?.data ?? null)
      if (ziel) return
      const offen = (r.data ?? []).filter((z) => z.abschnitt === 'gezielt' && z.rest > 0).map((z) => z.skill_key)
      if (offen.length) void getLsaWirkung(offen[0], offen.slice(1)).then((w) => aktiv && setSchulen(w.data ? neueSchulen(w.data) : null))
      else setSchulen(0)
    })
    return () => {
      aktiv = false
    }
  }, [ziel, skill])

  const setze = (neu: { ziel?: string | null; skill?: string | null }): void => {
    const p = new URLSearchParams()
    const z = 'ziel' in neu ? neu.ziel : ziel
    const s = 'skill' in neu ? neu.skill : skill
    if (z) p.set('ziel', z)
    if (s) p.set('skill', s)
    setParams(p)
  }

  if (fehler) return <EmptyState icon="🔒" title={t('gezielt.titel')} description={t('gezielt.fehler')} />
  if (!liste || (ziel && !stand)) return <LoadingPulse type="card" />

  const kompetenz = skill
    ? (liste.find((z) => z.skill_key === skill)?.skill_label ?? stand?.find((s) => s.skill_key === skill)?.skill_label ?? skill)
    : null
  const kopfzeile = (
    <>
      <ZielUmschalter ziel={ziel} onWahl={(z) => setze({ ziel: z, skill: null })} />
      {kompetenz && <FilterHinweis kompetenz={kompetenz} onAufheben={() => setze({ skill: null })} />}
    </>
  )

  if (ziel && stand) {
    const sichtbar = skill ? stand.filter((s) => s.skill_key === skill) : stand
    return (
      <div className="flex flex-col gap-6">
        {kopfzeile}
        <GezieltMsa liste={liste} stand={sichtbar} board={board} onOeffne={onOeffne} gefiltert={Boolean(skill)} />
      </div>
    )
  }

  const st = zielStand(liste)
  const gesamt = st.offen + st.geprueft
  const anteil = gesamt ? Math.round((st.geprueft / gesamt) * 100) : 100
  const erste = naechsteZiel(zielReihe(liste), board, null, leseUebersprungen())
  const gruppen = zielGruppen(liste, 'gezielt', t('gezielt.ohneThema'))
  const nach = zielGruppen(liste, 'nachpruefen', t('gezielt.ohneThema'))

  return (
    <div className="flex flex-col gap-6">
      {kopfzeile}
      <EdvanceCard className="flex flex-col gap-4">
        <p className="text-base font-semibold" data-testid="gezielt-kopf">
          {st.offen > 0
            ? t('gezielt.kopf', { count: st.offen, schulen: schulen ?? '…' })
            : t('gezielt.fertig')}
        </p>
        <div className="h-2.5 w-full overflow-hidden rounded-full bg-[var(--color-bg-subtle)]" role="progressbar"
          aria-valuemin={0} aria-valuemax={100} aria-valuenow={anteil} aria-label={t('gezielt.fortschritt')}>
          <div className="h-full rounded-full bg-[var(--color-primary)] transition-all" style={{ width: `${anteil}%` }} />
        </div>
        {erste && <Button className="self-start" onClick={() => onOeffne(erste)}>{t('gezielt.start')}</Button>}
      </EdvanceCard>
      {gruppen.length === 0 && (
        <EmptyState icon="🎉" title={skill ? t('gezielt.filter.leer') : t('gezielt.leer')} description={t('gezielt.leerText')} />
      )}
      {gruppen.map((g) => (
        <section key={g.thema} className="flex flex-col gap-2">
          <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {g.thema} · {t('gezielt.schulen', { count: g.schulen })}
          </h2>
          {g.zeilen.map((z) => (
            <EdvanceCard key={z.skill_key} className="flex flex-col gap-2 p-4">
              <p className="flex items-center gap-2 text-sm font-semibold">
                {z.skill_label}
                <span title={t('gezielt.info', { key: z.skill_key })} aria-label={t('gezielt.info', { key: z.skill_key })}>
                  <Info aria-hidden className="h-4 w-4 text-[var(--color-text-tertiary)]" />
                </span>
              </p>
              <p className="text-xs text-[var(--color-text-tertiary)]">
                {z.rest > 0 ? t('gezielt.noch', { count: z.rest }) : t('gezielt.reicht')}
              </p>
              <AufgabenListe ids={z.task_ids} board={board} onOeffne={onOeffne} />
            </EdvanceCard>
          ))}
        </section>
      ))}
      {nach.length > 0 && (
        <section className="flex flex-col gap-2" data-testid="nachpruefen">
          <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('gezielt.nachpruefen')}</h2>
          <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{t('gezielt.nachpruefenText')}</p>
          <EdvanceCard className="p-4">
            <AufgabenListe ids={nach.flatMap((g) => g.zeilen.flatMap((z) => z.task_ids))} board={board} onOeffne={onOeffne} />
          </EdvanceCard>
        </section>
      )}
    </div>
  )
}
