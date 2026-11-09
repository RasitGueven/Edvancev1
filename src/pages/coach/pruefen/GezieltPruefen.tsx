// FR-2 F3: Reiter „Gezielt prüfen“ im Lena-Board. Nur die Aufgaben, die einer Klassenarbeit wirklich einen fehlenden
// Beleg bringen (pruef_ziel_liste), gruppiert nach Thema, mit Wirkung. Klick öffnet die Prüfansicht mit
// ?liste=gezielt; dort geht es nach jeder Entscheidung mit der nächsten Aufgabe dieser Liste weiter.
// Keine Fachbegriffe (Pool, Textschlüssel, Hülle); der Skill-Schlüssel steht nur im Info-Hinweis.

import { useEffect, useMemo, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Info } from 'lucide-react'
import { EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { Button } from '@/components/ui'
import { naechsteZiel, neueSchulen, zielGruppen, zielReihe, zielStand } from '@/lib/pruefung/gezielt'
import { getLsaWirkung, getPruefZielListe } from '@/lib/supabase/lsaAbdeckung'
import type { PruefBoardZeile, PruefZielZeile } from '@/types'
import { leseUebersprungen } from './uebersprungen'

type Props = { board: PruefBoardZeile[]; onOeffne: (taskId: string) => void }

export function GezieltPruefen({ board, onOeffne }: Props): JSX.Element {
  const { t } = useTranslation('pruefen')
  const [liste, setListe] = useState<PruefZielZeile[] | null>(null)
  const [fehler, setFehler] = useState(false)
  const [schulen, setSchulen] = useState<number | null>(null)

  useEffect(() => {
    void getPruefZielListe().then((r) => {
      setFehler(r.error !== null)
      setListe(r.data ?? [])
      const offen = (r.data ?? []).filter((z) => z.abschnitt === 'gezielt' && z.rest > 0).map((z) => z.skill_key)
      if (offen.length) void getLsaWirkung(offen[0], offen.slice(1)).then((w) => setSchulen(w.data ? neueSchulen(w.data) : null))
      else setSchulen(0)
    })
  }, [])

  const zeile = useMemo(() => new Map(board.map((z) => [z.task_id, z])), [board])
  if (fehler) return <EmptyState icon="🔒" title={t('gezielt.titel')} description={t('gezielt.fehler')} />
  if (!liste) return <LoadingPulse type="card" />

  const stand = zielStand(liste)
  const gesamt = stand.offen + stand.geprueft
  const anteil = gesamt ? Math.round((stand.geprueft / gesamt) * 100) : 100
  const erste = naechsteZiel(zielReihe(liste), board, null, leseUebersprungen())
  const gruppen = zielGruppen(liste, 'gezielt', t('gezielt.ohneThema'))
  const nach = zielGruppen(liste, 'nachpruefen', t('gezielt.ohneThema'))

  const aufgabe = (id: string): JSX.Element | null => {
    const z = zeile.get(id)
    if (!z) return null
    return (
      <li key={id}>
        <button type="button" onClick={() => onOeffne(id)} data-testid={`ziel-${id}`}
          className="flex min-h-[44px] w-full items-center justify-between gap-2 rounded-[var(--radius-md)] px-2 text-left text-sm hover:bg-[var(--color-bg-subtle)]">
          <span>{z.kurztitel}</span>
          <span className="text-xs text-[var(--color-text-tertiary)]">{t(`status.${z.lena_status}`)}</span>
        </button>
      </li>
    )
  }

  return (
    <div className="flex flex-col gap-6">
      <EdvanceCard className="flex flex-col gap-4">
        <p className="text-base font-semibold" data-testid="gezielt-kopf">
          {stand.offen > 0
            ? t('gezielt.kopf', { count: stand.offen, schulen: schulen ?? '…' })
            : t('gezielt.fertig')}
        </p>
        <div className="h-2.5 w-full overflow-hidden rounded-full bg-[var(--color-bg-subtle)]" role="progressbar"
          aria-valuemin={0} aria-valuemax={100} aria-valuenow={anteil} aria-label={t('gezielt.fortschritt')}>
          <div className="h-full rounded-full bg-[var(--color-primary)] transition-all" style={{ width: `${anteil}%` }} />
        </div>
        {erste && <Button className="self-start" onClick={() => onOeffne(erste)}>{t('gezielt.start')}</Button>}
      </EdvanceCard>
      {gruppen.length === 0 && <EmptyState icon="🎉" title={t('gezielt.leer')} description={t('gezielt.leerText')} />}
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
              <ul className="flex flex-col">{z.task_ids.map(aufgabe)}</ul>
            </EdvanceCard>
          ))}
        </section>
      ))}
      {nach.length > 0 && (
        <section className="flex flex-col gap-2" data-testid="nachpruefen">
          <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{t('gezielt.nachpruefen')}</h2>
          <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{t('gezielt.nachpruefenText')}</p>
          <EdvanceCard className="p-4">
            <ul className="flex flex-col">{nach.flatMap((g) => g.zeilen.flatMap((z) => z.task_ids)).map(aufgabe)}</ul>
          </EdvanceCard>
        </section>
      )}
    </div>
  )
}
