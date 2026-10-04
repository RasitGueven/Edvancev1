import { useTranslation } from 'react-i18next'

import type { Bausteinsatz } from '@/lib/report/bausteine'
import { aktuellKopf, ausgangspunktSatz, sucheSaetze } from '@/lib/report/suche'
import type { SucheStufe, SucheZeile, Suchweg } from '@/types'

/**
 * „Wie wir gesucht haben" — nach Thema und Lehrplanstufe statt nach Ebenen (W2-7).
 *
 *   1. Aktuelles Thema     die geprüften Einstiegsknoten
 *   2. Grundlagen darunter Skills im Voraussetzungsabschluss, nach Stufe
 *   3. Außerdem angesehen  alles Übrige, nach Stufe und Inhaltsbereich
 *
 * Nur Block 2 darf einen Zusammenhang zum Thema behaupten. Alte Sitzungen ohne
 * Thema haben nur Block 3 („Angesehen").
 *
 * Jede Zeile nennt „x von y sicher" im Klartext und die Bereiche einzeln mit
 * Zustand — kein Balken, keine Ampel (INV-4.4).
 */
export function ReportSuche({
  suche,
  satz,
  sessionId,
  titleClassName,
}: {
  suche: Suchweg | null
  satz: Bausteinsatz
  sessionId: string
  titleClassName: string
}): JSX.Element | null {
  const { t, i18n } = useTranslation('report')
  if (!suche) return null

  const saetze = sucheSaetze(
    suche,
    (k, w) => t(k, w),
    i18n.language,
    ausgangspunktSatz(suche, satz, sessionId),
  )
  const mitThema = suche.fall === 'thema'

  return (
    <section className="report-block report-hauptteil report-suche flex flex-col gap-2">
      <h3 className={titleClassName}>{t('suche.title')}</h3>
      <p className="mb-2 text-base leading-relaxed text-[var(--color-report-navy)]">
        {saetze.join(' ')}
      </p>

      {suche.aktuell && (
        <div className="report-suche-block" data-testid="suche-aktuell">
          <p className="report-suche-kopf">{t(aktuellKopf(suche))}</p>
          <ZeileView zeile={suche.aktuell} name={suche.themaLabel ?? t(aktuellKopf(suche))} />
        </div>
      )}

      {suche.grundlagen.length > 0 && (
        <div className="report-suche-block" data-testid="suche-grundlagen">
          <p className="report-suche-kopf">{t('suche.block.grundlagen')}</p>
          <p className="report-suche-hinweis">{t('suche.block.grundlagenHinweis')}</p>
          <StufenView stufen={suche.grundlagen} />
        </div>
      )}

      {suche.angesehen.length > 0 && (
        <div className="report-suche-block" data-testid="suche-angesehen">
          <p className="report-suche-kopf">
            {t(mitThema ? 'suche.block.ausserdem' : 'suche.block.angesehen')}
          </p>
          {mitThema && <p className="report-suche-hinweis">{t('suche.block.ausserdemHinweis')}</p>}
          <StufenView stufen={suche.angesehen} />
        </div>
      )}
    </section>
  )
}

function StufenView({ stufen }: { stufen: readonly SucheStufe[] }): JSX.Element {
  const { t } = useTranslation('report')
  return (
    <>
      {stufen.map((s) => (
        <div key={s.stufe} className="report-suche-stufe">
          <p className="report-suche-stufe-name">{t(`suche.stufe.${s.stufe}`)}</p>
          {s.zeilen.map((z) => (
            <ZeileView key={z.bereich} zeile={z} name={t(`suche.bereich.${z.bereich}`)} />
          ))}
        </div>
      ))}
    </>
  )
}

function ZeileView({ zeile, name }: { zeile: SucheZeile; name: string }): JSX.Element {
  const { t } = useTranslation('report')
  return (
    <div className="report-suche-zeile">
      <div className="report-suche-zeile-kopf">
        <span className="report-suche-bereich">{name}</span>
        <span className="report-suche-zahl">
          {t('suche.zaehlung', { sicher: zeile.sicher, geprueft: zeile.geprueft })}
        </span>
      </div>
      <ul className="report-suche-skills">
        {zeile.eintraege.map((e) => (
          <li key={e.label} className={e.sicher ? 'report-suche-skill-sicher' : undefined}>
            {e.label} · {t(e.sicher ? 'suche.zustand.sicher' : 'suche.zustand.offen')}
            {e.nurEineAufgabe && (
              <span className="report-suche-duenn"> ({t('suche.nurEineAufgabe')})</span>
            )}
          </li>
        ))}
      </ul>
    </div>
  )
}
