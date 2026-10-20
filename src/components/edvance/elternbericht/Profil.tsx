import { useTranslation } from 'react-i18next'

import type { EbProfilZeile } from '@/types'

import { linienLage, segmente, teile, zeilenAbstand } from './seite2Rechnung'

// Lage in der Karte, in pt relativ zur Innenkante (Maßblatt Seite 2: Karte
// (44,323)–(551,663), Rand 0,9, Inhalt ab x 64). Jede Zeile ist ein SVG mit
// 1 Einheit = 1 pt; Text steht dort auf seiner Grundlinie.
const BREITE = 467 // x 64–531
const RECHTS = 468 // rechte Texte bis x 532
const SPUR_X = 165 // x 229
const SPUR_H = 13.5

/**
 * Das Kompetenzprofil: eine Zeile je Themenfeld mit geprüften Bereichen, ein
 * Segment je geprüftem Bereich (R7-6). `profil` kommt schon gefiltert.
 *
 * Die Segmente sind Anzahlen, keine Quote: Beide Zahlen stehen als Text
 * daneben, die Spur ist für Vorleseprogramme verborgen, jede Zeile hat einen
 * eigenen Vorlesetext.
 */
export function Profil({
  profil,
  wessen,
}: {
  profil: EbProfilZeile[]
  wessen: string | null
}): JSX.Element {
  const { t } = useTranslation('elternbericht')
  const abstand = zeilenAbstand(profil.length)
  // Trennlinie zwischen zwei Zeilen: im Muster 31,8 unter der Spur-Oberkante;
  // bei engem Abstand mittig zwischen Unterzeile und nächster Spur.
  const linieY = linienLage(abstand)

  return (
    <section className="eb-s2-profil" data-testid="eb-profil">
      <svg className="eb-s2-profil-kopf" viewBox="0 0 467 63.1">
        <text className="eb-s2-profil-titel" x="0" y="28.9">
          {wessen ? t('s2.profil.titel', { wessen }) : t('s2.profil.titelOhneName')}
        </text>
        <text className="eb-s2-profil-hinweis" x={BREITE} y="26.9">
          {t('s2.profil.hinweis')}
        </text>
        <line className="eb-s2-profil-linie" x1="0" y1="52.1" x2={BREITE} y2="52.1" />
      </svg>

      <ul className="eb-s2-zeilen">
        {profil.map((z, i) => {
          const untersucht = z.sicher + z.uebung
          const feld = t(`feld.${z.feld}`)
          return (
            <li key={z.feld} className="eb-s2-zeile" data-testid="eb-profil-zeile">
              <span className="sr-only">
                {t('s2.profil.aria', { feld, untersucht, sicher: z.sicher, uebung: z.uebung })}
              </span>
              <svg
                className="eb-s2-zeile-bild"
                aria-hidden="true"
                width={`${RECHTS}pt`}
                height={`${abstand}pt`}
                viewBox={`0 0 ${RECHTS} ${abstand}`}
              >
                <text className="eb-s2-feld" x="0" y="9.1">
                  {feld}
                </text>
                <g className="eb-s2-spur" transform={`translate(${SPUR_X} 0)`}>
                  {segmente(z).map((s, j) => (
                    <rect
                      key={j}
                      className={`eb-s2-segment-${s.art}`}
                      x={s.x}
                      y="0"
                      width={s.breite}
                      height={SPUR_H}
                      rx={s.radius}
                    />
                  ))}
                </g>
                <text className="eb-s2-geprueft" x={RECHTS} y="5.5">
                  {t('s2.profil.geprueft', { count: untersucht })}
                </text>
                <text className="eb-s2-teile" x={RECHTS} y="20">
                  {teile(z)
                    .map((teil) => t(`s2.profil.${teil.art}`, { count: teil.anzahl }))
                    .join(t('s2.profil.trenner'))}
                </text>
                {i < profil.length - 1 && (
                  <line className="eb-s2-zeilen-linie" x1="0" y1={linieY} x2={BREITE} y2={linieY} />
                )}
              </svg>
            </li>
          )
        })}
      </ul>

      <svg className="eb-s2-legende" viewBox="0 0 467 10">
        <rect className="eb-s2-segment-sicher" x="1" y="0" width="10" height="10" rx="2.6" />
        <text x="17" y="6.1">
          {t('s2.profil.legende.sicher')}
        </text>
        <rect className="eb-s2-segment-uebung" x="59.9" y="0" width="10" height="10" rx="2.6" />
        <text x="75.9" y="6.1">
          {t('s2.profil.legende.uebung')}
        </text>
      </svg>
    </section>
  )
}
