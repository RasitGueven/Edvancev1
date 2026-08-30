import { useMemo } from 'react'
import { useTranslation } from 'react-i18next'

import { ReportBefund } from '@/components/edvance/report/ReportBefund'
import { ReportEbenen } from '@/components/edvance/report/ReportEbenen'
import { ReportFehlbilder } from '@/components/edvance/report/ReportFehlbilder'
import { ReportProfil } from '@/components/edvance/report/ReportProfil'
import { ReportSchluss } from '@/components/edvance/report/ReportSchluss'
import { ReportSkillbefunde } from '@/components/edvance/report/ReportSkillbefunde'
import { Bausteinsatz } from '@/lib/report/bausteine'
import type { ReportData } from '@/types'

/**
 * Der lesende Teil des Eltern-Reports — die abgestimmte Erzählung in sechs
 * Schritten (R6).
 *
 * 01 Warum wir geschaut haben   was die Eltern genannt haben, wörtlich
 * 02 Wie wir gesucht haben      der Abstieg durch die Fundamentebenen
 * 03 Was wir gefunden haben     Profil über die Themen, dann die zwei Listen
 * 04 Wie es sich zeigt          wiederkehrende Denkschritte (Fehlbilder)
 *    Aufklappbereich            was der Coach zuerst nachprüft
 * 05 So geht es weiter          Fazit, Aufgriff der Eltern-Punkte, Empfehlung
 *    Fußzeile                   wer die Analyse begleitet hat
 *
 * ----------------------------------------------------------------------------
 * Was mit R6 entfallen ist und warum
 * ----------------------------------------------------------------------------
 * Bis R5 stand hier eine andere Dramaturgie: eine Erzählung aus
 * Bearbeitungsdauern (`reportNarrative.ts`), ein Stärke-Abschnitt, Belege je
 * Themenfeld (`ReportTopicBar`), ein Themen-Anhang und ein eigener Block mit
 * der Eltern-Einschätzung.
 *
 * Sie ist ersetzt, nicht ergänzt. Zwei Erzählungen nebeneinander — eine aus
 * Bearbeitungszeiten, eine aus Trag-Urteilen — hätten sich gegenseitig
 * relativiert, und die Zeit-Erzählung war von Anfang an als Platzhalter
 * angelegt: „Die spätere System-Erzählung mit Voraussetzungs-Kausalkette
 * ersetzt diese Datei vollständig" stand in ihrem eigenen Kopf. Die
 * Eltern-Einschätzung ist nicht verschwunden, sondern an zwei bessere Stellen
 * gewandert: in Schritt 01 als Anlass und in Schritt 05 als Antwort.
 *
 * Kein Gesamtscore, keine Note, kein Prozentrang. Alle Vergleiche laufen
 * innerhalb der Sitzung.
 */
export function ReportBody({ data }: { data: ReportData }): JSX.Element {
  const { t, i18n } = useTranslation('report')
  const name = data.firstName?.trim() || t('head.childFallback')
  const { erzaehlung } = data

  // Der Bausteinsatz gruppiert einmal, nicht bei jedem Rendern neu — und die
  // Variantenwahl bleibt über Rerenders stabil, weil sie deterministisch an der
  // Sitzungs-ID hängt.
  const satz = useMemo(() => new Bausteinsatz(erzaehlung.bausteine), [erzaehlung.bausteine])

  const dateLabel = data.analysedAt
    ? new Intl.DateTimeFormat(i18n.language, {
        dateStyle: 'long',
        timeZone: 'Europe/Berlin',
      }).format(new Date(data.analysedAt))
    : '—'

  // Drei Gewichte statt sieben gleichwertiger Abschnitte (R3). Die Ordnung ist
  // in src/styles/report.css begründet; hier steht nur die Typografie dazu.
  const titelHaupt =
    'font-serif text-[1.375rem] font-semibold text-[var(--color-report-navy)]'
  const titelBeleg =
    'font-serif text-[1.0625rem] font-semibold text-[var(--color-report-navy)]'

  const punkte = erzaehlung.anlassNamen
  const kontakt = erzaehlung.ansprechpartner

  return (
    <>
      {/* KOPF */}
      <header className="report-block flex flex-col gap-3 border-b-2 border-[var(--color-report-gold)] pb-5">
        <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-report-gold)]">
          {t('head.title')}
        </p>
        <h2 className="font-serif text-3xl font-bold text-[var(--color-report-navy)]">
          {t('head.ueberschrift', { name })}
        </h2>
        <dl className="flex flex-wrap gap-x-8 gap-y-1 text-sm text-[color-mix(in_srgb,var(--color-report-navy)_70%,transparent)]">
          <div className="flex gap-2">
            <dt>{t('head.grade')}:</dt>
            <dd className="font-medium">{data.grade}</dd>
          </div>
          <div className="flex gap-2">
            <dt>{t('head.subject')}:</dt>
            <dd className="font-medium">{data.subject}</dd>
          </div>
          <div className="flex gap-2">
            <dt>{t('head.umfang')}:</dt>
            <dd className="font-medium">
              {t('head.aufgaben', { count: data.aufgaben })}
            </dd>
          </div>
          <div className="flex gap-2">
            <dt>{t('head.date')}:</dt>
            <dd className="font-medium">{dateLabel}</dd>
          </div>
        </dl>
      </header>

      {/* 01 ANLASS — wörtlich, was die Eltern genannt haben. Fehlt beides,
          entfällt der Abschnitt: ein erfundener Anlass wäre schlimmer als
          keiner. */}
      {(punkte.length > 0 || data.naechstesThema) && (
        <section className="report-block report-hauptteil flex flex-col gap-2">
          <h3 className={titelHaupt}>{t('anlass.title')}</h3>
          <p className="text-base leading-relaxed text-[var(--color-report-navy)]">
            {punkte.length > 0 &&
              t('anlass.genannt', {
                punkte: new Intl.ListFormat(i18n.language, {
                  style: 'long',
                  type: 'conjunction',
                }).format(punkte),
                count: punkte.length,
              })}
            {punkte.length > 0 && data.naechstesThema ? ' ' : ''}
            {data.naechstesThema &&
              t('anlass.thema', { thema: data.naechstesThema })}
          </p>
        </section>
      )}

      {/* 02 SUCHE */}
      <ReportEbenen
        fundament={erzaehlung.fundament}
        satz={satz}
        sessionId={data.sessionId}
        titleClassName={titelHaupt}
      />

      {/* 03 BEFUND — erst das Bild, dann die Listen. */}
      {erzaehlung.fundament && (
        <section className="report-block report-hauptteil flex flex-col gap-3">
          <h3 className={titelHaupt}>{t('befund.title')}</h3>
          <p className="text-sm leading-relaxed text-[color-mix(in_srgb,var(--color-report-navy)_70%,transparent)]">
            {t('befund.description')}
          </p>
          <ReportProfil profil={erzaehlung.profil} titleClassName={titelBeleg} />
          <ReportBefund
            fundament={erzaehlung.fundament}
            satz={satz}
            sessionId={data.sessionId}
            titleClassName={titelBeleg}
          />
        </section>
      )}

      {/* 04 MUSTER — gebündelt auf Familienebene. Bleibt nach der Bündelung
          nichts übrig, rendert die Komponente nichts. */}
      <ReportFehlbilder
        fehlbilder={data.fehlbilder}
        name={name}
        titleClassName={titelHaupt}
      />

      {/* AUFKLAPPBEREICH — was der Coach zuerst nachprüft. */}
      <ReportSkillbefunde befunde={data.skillbefunde} titleClassName={titelHaupt} />

      {/* 05 SCHLUSS — Fazit, Aufgriff der Eltern-Punkte, Empfehlung. */}
      <ReportSchluss
        verteilung={erzaehlung.verteilung}
        rueckbezuege={erzaehlung.rueckbezuege}
        satz={satz}
        sessionId={data.sessionId}
      />

      {/* FUSSZEILE — wer die Analyse begleitet hat. Fehlt die Zuordnung,
          entfällt sie: ein erfundener Ansprechpartner wäre schlimmer. */}
      {(kontakt.name || kontakt.email) && (
        <p className="report-block report-kontakt">
          {t('kontakt.satz', { name: kontakt.name ?? t('kontakt.team') })}{' '}
          {kontakt.email ? (
            <>
              {t('kontakt.frage')}{' '}
              <a href={`mailto:${kontakt.email}`}>{kontakt.email}</a>.
            </>
          ) : (
            t('kontakt.frageOhneMail')
          )}
        </p>
      )}
    </>
  )
}
