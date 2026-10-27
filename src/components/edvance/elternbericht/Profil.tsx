import { useTranslation } from 'react-i18next'

import type { EbFahrplan, EbThemaSignal } from '@/types'

import {
  linienLage,
  massstabFuer,
  segmente,
  teile,
  zeilenAbstand,
  type ProfilZeile,
} from './seite2Rechnung'
import { wichtigFuer } from './wichtigFuer'

// Lage in der Karte, in pt relativ zur Innenkante (Maßblatt Seite 2: Karte
// (44,323)–(551,663), Rand 0,9, Inhalt ab x 64). Jede Zeile ist ein SVG mit
// 1 Einheit = 1 pt; Text steht dort auf seiner Grundlinie.
const BREITE = 467 // x 64–531
const RECHTS = 468 // rechte Texte bis x 532
const SPUR_X = 165 // x 229
const SPUR_H = 13.5
/** Rand der Umriss-Kästchen; das Rechteck rückt um die halbe Stärke ein, damit
 * es außen so groß ist wie ein farbiges. */
const UMRISS = 0.7
/** Legende: dritter Eintrag hinter „Übungsbedarf“ (Textende 129,1, gemessen)
 * mit demselben Abstand wie zwischen den ersten beiden (Textende 41,6 → 59,9). */
const LEGENDE_UMRISS_X = 147.4
/** Bericht v4: Höhe der Zeile (Feld, Spur, Zählung); „Wichtig für“ folgt darunter. */
const ZEILE_V4 = 22
/** Bericht v4: Kopf der Karte ohne den Leerraum des Musters. */
const KOPF_V4 = 50
const KOPF_VERSATZ_V4 = KOPF_V4 - 63.1

/**
 * Das Kompetenzprofil: eine Zeile je Themenfeld, ein Kästchen je geprüftem
 * Bereich (R7-6). Seit R7-8 mit einem Maßstab für alle Zeilen, der
 * Klassenspanne unter dem Feldnamen und — nur bei abgestufter LSA — den
 * abgeleiteten Bereichen des Themas als Umriss ohne Farbe, Zustand und Label.
 *
 * Die Kästchen sind Anzahlen, keine Quote: Die Zahlen stehen als Text
 * daneben, die Spur ist für Vorleseprogramme verborgen, jede Zeile hat einen
 * eigenen Vorlesetext.
 *
 * Bericht v4 (`klassenarbeiten`): unter jeder Zeile „Wichtig für“ mit einer
 * Marke je Klassenarbeit (wichtigFuer.ts), oder „wird in späteren Schuljahren
 * wichtig“; die Legende nennt die Nummer.
 */
export function Profil({
  profil,
  wessen,
  klassenarbeiten,
}: {
  profil: ProfilZeile[]
  wessen: string | null
  klassenarbeiten?: { fahrplan: EbFahrplan; signale: readonly EbThemaSignal[] }
}): JSX.Element {
  const { t } = useTranslation('elternbericht')
  const v4 = klassenarbeiten !== undefined
  const kopfDy = v4 ? KOPF_VERSATZ_V4 : 0
  const abstand = v4 ? ZEILE_V4 : zeilenAbstand(profil.length)
  const m = massstabFuer(profil)
  const mitAbgeleiteten = profil.some((z) => z.abgeleitet > 0)
  // Trennlinie zwischen zwei Zeilen: im Muster 31,8 unter der Spur-Oberkante;
  // bei engem Abstand mittig zwischen Unterzeile und nächster Spur.
  const linieY = linienLage(abstand)

  return (
    <section className="eb-s2-profil" data-testid="eb-profil">
      <svg
        className={v4 ? 'eb-s2-profil-kopf eb-s2-profil-kopf-v4' : 'eb-s2-profil-kopf'}
        viewBox={`0 0 467 ${v4 ? KOPF_V4 : 63.1}`}
      >
        <text className="eb-s2-profil-titel" x="0" y={28.9 + kopfDy}>
          {wessen ? t('s2.profil.titel', { wessen }) : t('s2.profil.titelOhneName')}
        </text>
        <text className="eb-s2-profil-hinweis" x={BREITE} y={26.9 + kopfDy}>
          {t('s2.profil.hinweis')}
        </text>
        <line className="eb-s2-profil-linie" x1="0" y1={52.1 + kopfDy} x2={BREITE} y2={52.1 + kopfDy} />
      </svg>

      <ul className="eb-s2-zeilen">
        {profil.map((z, i) => {
          const untersucht = z.sicher + z.uebung
          const feld = t(`feld.${z.feld}`)
          const vorlesen = [
            untersucht > 0
              ? t('s2.profil.aria', { feld, untersucht, sicher: z.sicher, uebung: z.uebung })
              : t('s2.profil.ariaNurAbgeleitet', { feld, count: z.abgeleitet }),
            untersucht > 0 && z.abgeleitet > 0 && t('s2.profil.ariaAbgeleitet', { count: z.abgeleitet }),
          ]
          const oben = [
            untersucht > 0 && t('s2.profil.geprueft', { count: untersucht }),
            z.abgeleitet > 0 && t('s2.profil.abgeleitet', { count: z.abgeleitet }),
          ]
          const marken = klassenarbeiten ? wichtigFuer(z.feld, klassenarbeiten.fahrplan, klassenarbeiten.signale) : []
          return (
            <li key={z.feld} className={v4 ? 'eb-s2-zeile eb-s2-zeile-w' : 'eb-s2-zeile'} data-testid="eb-profil-zeile">
              <span className="sr-only">
                {vorlesen.filter((x): x is string => Boolean(x)).join(' ')}
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
                {z.klasse && (
                  <text className="eb-s2-klasse" x="0" y="20" data-testid="eb-profil-klasse">
                    {z.klasse.von === z.klasse.bis
                      ? t('s2.profil.klasse', { k: z.klasse.von })
                      : t('s2.profil.klasseSpanne', { von: z.klasse.von, bis: z.klasse.bis })}
                  </text>
                )}
                <g className="eb-s2-spur" transform={`translate(${SPUR_X} 0)`}>
                  {segmente(z, m).map((s, j) => {
                    const ein = s.art === 'abgeleitet' ? UMRISS / 2 : 0
                    return (
                      <rect
                        key={j}
                        className={`eb-s2-segment-${s.art}`}
                        x={s.x + ein}
                        y={ein}
                        width={s.breite - 2 * ein}
                        height={SPUR_H - 2 * ein}
                        rx={Math.max(0, s.radius - ein)}
                      />
                    )
                  })}
                </g>
                <text className="eb-s2-geprueft" x={RECHTS} y="5.5">
                  {oben.filter((x): x is string => Boolean(x)).join(t('s2.profil.trenner'))}
                </text>
                <text className="eb-s2-teile" x={RECHTS} y="20">
                  {teile(z)
                    .map((teil) => t(`s2.profil.${teil.art}`, { count: teil.anzahl }))
                    .join(t('s2.profil.trenner'))}
                </text>
                {!v4 && i < profil.length - 1 && (
                  <line className="eb-s2-zeilen-linie" x1="0" y1={linieY} x2={BREITE} y2={linieY} />
                )}
              </svg>
              {klassenarbeiten && (marken.length > 0 || z.uebung > 0) && (
                <p className="eb-s2-wichtig" data-testid="eb-wichtig">
                  {marken.length > 0 ? (
                    <>
                      <span className="eb-s2-wichtig-label">{t('v4.s2.wichtig')}</span>
                      {marken.map((m) => (
                        <span
                          key={m.nummer}
                          className={m.naechste || m.unterricht ? 'eb-s2-marke eb-s2-marke-naechste' : 'eb-s2-marke'}
                          data-testid="eb-marke"
                        >
                          {m.ka !== null && <b>{m.ka}</b>}
                          {m.naechste
                            ? `${m.titel}${t('s2.profil.trenner')}${t('v4.s2.naechste')}`
                            : m.unterricht
                              ? `${m.titel}${t('s2.profil.trenner')}${t('v4.s2.unterricht')}`
                              : m.titel}
                        </span>
                      ))}
                    </>
                  ) : (
                    <span className="eb-s2-wichtig-spaeter">{t('v4.s2.spaeter')}</span>
                  )}
                </p>
              )}
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
        {v4 && klassenarbeiten?.fahrplan.folge !== 'unbekannt' && (
          <g data-testid="eb-legende-nummer">
            <rect
              className="eb-s2-segment-nummer"
              x={LEGENDE_UMRISS_X + UMRISS / 2}
              y={UMRISS / 2}
              width={10 - UMRISS}
              height={10 - UMRISS}
              rx={2.6 - UMRISS / 2}
            />
            <text x={LEGENDE_UMRISS_X + 16} y="6.1">
              {t('v4.s2.legendeNummer')}
            </text>
          </g>
        )}
        {mitAbgeleiteten && (
          <g data-testid="eb-legende-abgeleitet">
            <rect
              className="eb-s2-segment-abgeleitet"
              x={LEGENDE_UMRISS_X + UMRISS / 2}
              y={UMRISS / 2}
              width={10 - UMRISS}
              height={10 - UMRISS}
              rx={2.6 - UMRISS / 2}
            />
            <text x={LEGENDE_UMRISS_X + 16} y="6.1">
              {t('s2.profil.legende.abgeleitet')}
            </text>
          </g>
        )}
      </svg>
    </section>
  )
}
