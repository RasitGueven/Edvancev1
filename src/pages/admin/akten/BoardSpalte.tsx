import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Input } from '@/components/ui/input'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import { datum } from '@/lib/akte/format'
import type { Spalte } from '@/lib/akte/board'
import type { BoardSchueler } from '@/types'
import { AMPEL_BADGE } from './ampel'

function BoardKarte({ s }: { s: BoardSchueler }): JSX.Element {
  const { t, i18n } = useTranslation('akte')
  const lang = i18n.language
  return (
    <Link
      to={`/admin/akten/${s.student_id}`}
      className="block rounded-[var(--radius-lg)] focus-visible:outline-2 focus-visible:outline-[var(--color-primary)]"
    >
      <EdvanceCard className="flex flex-col gap-2 p-4 shadow-card transition-shadow hover:shadow-elevation-md">
        <span className="text-base font-semibold text-[var(--color-text-primary)]">{s.name ?? '—'}</span>
        <span className="text-xs text-[var(--color-text-tertiary)]">
          {s.schule ?? t('board.karte.ohneSchule')}
        </span>

        {s.zustand === 'ruhend' ? (
          <EdvanceBadge variant="muted">
            {s.ruhend_seit
              ? t('board.karte.ruhendSeit', { datum: datum(s.ruhend_seit, lang) })
              : t('board.karte.ruhend')}
          </EdvanceBadge>
        ) : s.art === 'vorher' && s.beginn ? (
          <EdvanceBadge variant="primary">{t('board.karte.startetAm', { datum: datum(s.beginn, lang) })}</EdvanceBadge>
        ) : s.art === 'laufend' && s.ampel ? (
          <div className="flex flex-wrap items-center gap-2">
            <EdvanceBadge variant={AMPEL_BADGE[s.ampel]}>{t(`ampel.${s.ampel}`)}</EdvanceBadge>
            <span className="text-xs text-[var(--color-text-secondary)]">
              {t('board.karte.verbraucht', { verbraucht: s.verbraucht ?? 0, einheiten: s.einheiten ?? 0 })}
            </span>
          </div>
        ) : null}

        <span className="text-xs text-[var(--color-text-tertiary)]">
          {s.letzte_session
            ? t('board.karte.letzteSession', { datum: datum(s.letzte_session, lang) })
            : t('board.karte.keineSession')}
        </span>
      </EdvanceCard>
    </Link>
  )
}

export function BoardSpalte({
  spalte,
  suche,
  onSuche,
}: {
  spalte: Spalte
  suche: string
  onSuche: (wert: string) => void
}): JSX.Element {
  const { t } = useTranslation('akte')
  const titel = spalte.klasse === null ? t('board.ohneKlasse') : t('board.klasse', { klasse: spalte.klasse })
  const gefiltert = spalte.sichtbar.length !== spalte.gesamt
  return (
    <section
      aria-label={titel}
      className="flex w-board-spalte shrink-0 snap-start flex-col gap-4 rounded-[var(--radius-lg)] bg-[var(--color-bg-subtle)] p-4 @board-akten:w-auto @board-akten:min-w-0"
    >
      <div className="flex items-center justify-between gap-2">
        <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {titel}
        </h2>
        <EdvanceBadge variant="muted">
          {gefiltert
            ? t('board.anzahlVon', { x: spalte.sichtbar.length, y: spalte.gesamt })
            : t('board.anzahl', { count: spalte.gesamt })}
        </EdvanceBadge>
      </div>
      <Input
        aria-label={t('board.sucheSpalte', { klasse: spalte.klasse ?? t('board.ohneKlasse') })}
        placeholder={t('board.sucheSpalte', { klasse: spalte.klasse ?? t('board.ohneKlasse') })}
        value={suche}
        onChange={(e) => onSuche(e.target.value)}
      />
      <div className="flex max-h-[70vh] flex-col gap-2 overflow-y-auto">
        {spalte.sichtbar.length === 0 ? (
          <p className="text-sm text-[var(--color-text-tertiary)]">
            {spalte.gesamt === 0 ? t('board.spalteLeer') : t('board.sucheLeer')}
          </p>
        ) : (
          spalte.sichtbar.map((s) => <BoardKarte key={s.student_id} s={s} />)
        )}
      </div>
    </section>
  )
}
