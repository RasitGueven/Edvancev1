import { useTranslation } from 'react-i18next'

import { themaAbdeckungAus } from '@/lib/report/elternbericht/themaAbdeckung'
import type { ThemenfeldKey } from '@/types'

import { Profil } from './Profil'
import { deutung, profilZeilen } from './seite2Rechnung'
import type { SeitenProps } from './seitenProps'

// Die drei Zahlen (Maßblatt Seite 2): Spalten ab x 44 / 218 / 392, Balken
// 158 × 2,6 bei y 236, Zahl auf y 277,6, Label auf y 294,4. Ein SVG in
// Seitenkoordinaten, Ausschnitt y 232–298. Die dritte ist seit R7-6 „geprüft“,
// nicht mehr „nicht untersucht“.
const ZAHLEN = [
  { art: 'sicher', x: 44 },
  { art: 'uebung', x: 218 },
  { art: 'geprueft', x: 392 },
] as const

/**
 * Seite 2 des Eltern-Berichts R7: Lernstand in Zahlen und als Kompetenzprofil
 * je Themenfeld (Maßblatt E7, „Seite 2“).
 *
 * Das Profil zeigt Felder mit geprüften Bereichen (R7-6), bei abgestufter LSA
 * auch solche mit abgeleiteten Bereichen des Themas — genau die, die der
 * Thema-Satz auf Seite 1 zählt (R7-8). Ab sieben Zeilen rückt die Seite enger
 * zusammen (`eb-s2-eng`), damit acht nicht überlaufen.
 */
export function Seite2({ data, bericht, wessen }: SeitenProps): JSX.Element {
  const { t, i18n } = useTranslation('elternbericht')
  const { zaehlung } = bericht
  const profil = profilZeilen({
    profil: bericht.profil,
    bereiche: [...bericht.sicherListe, ...bericht.uebungListe],
    abgeleitet: themaAbdeckungAus(data.erzaehlung)?.abgeleiteteBereiche ?? [],
  })
  const mitAbgeleiteten = profil.some((z) => z.abgeleitet > 0)
  const liste = new Intl.ListFormat(i18n.language, { style: 'long', type: 'conjunction' })
  const felder = (keys: ThemenfeldKey[]): string => liste.format(keys.map((k) => t(`feld.${k}`)))
  const d = deutung(profil)
  // Der Coach-Satz bezieht sich auf den Satz davor und steht nie allein (R7-10).
  const mitFeldSatz = d.sicher.length > 0 || d.uebung.length > 0
  const werte = { sicher: zaehlung.sicher, uebung: zaehlung.uebung, geprueft: zaehlung.untersucht }

  return (
    <div className={profil.length >= 7 ? 'eb-s2 eb-s2-eng' : 'eb-s2'}>
      <p className="eb-kicker eb-s2-kicker">{t('s2.kicker')}</p>
      <h1 className="eb-titel eb-s2-titel">
        {wessen ? t('s2.titel', { wessen }) : t('s2.titelOhneName')}
      </h1>
      <p className="eb-s2-intro">
        {t('s2.intro', {
          untersucht: zaehlung.untersucht,
          sicher: zaehlung.sicher,
          uebung: zaehlung.uebung,
        })}
      </p>

      <svg className="eb-s2-zahlen" viewBox="44 232 507 66" data-testid="eb-zahlen">
        {ZAHLEN.map((z) => (
          <g key={z.art} className={`eb-s2-zahl-${z.art}`}>
            <rect x={z.x} y="236" width="158" height="2.6" rx="1.3" />
            <text className="eb-s2-zahl" x={z.x} y="277.6">
              {werte[z.art]}
            </text>
            <text className="eb-s2-zahl-label" x={z.x} y="294.4">
              {t(`s2.zahl.${z.art}`)}
            </text>
          </g>
        ))}
      </svg>

      <Profil profil={profil} wessen={wessen} />

      <section className="eb-s2-deutung" data-testid="eb-deutung">
        <h2 className="eb-kicker eb-s2-deutung-kicker">{t('s2.deutung.kicker')}</h2>
        <div>
          {mitFeldSatz && (
            <p className="eb-s2-deutung-text">
              {[
                d.sicher.length > 0 &&
                  t('s2.deutung.sicher', { count: d.sicher.length, felder: felder(d.sicher) }),
                d.uebung.length > 0 &&
                  t('s2.deutung.uebung', { count: d.uebung.length, felder: felder(d.uebung) }),
                zaehlung.uebung > 0 && t('s2.deutung.coach'),
              ]
                .filter((s): s is string => Boolean(s))
                .map((s, i) => (
                  <span key={i}>
                    {i > 0 && ' '}
                    {s}
                  </span>
                ))}
            </p>
          )}
          <p className="eb-s2-fussnote">
            {t('s2.fussnote')}
            {mitAbgeleiteten && <> {t('s2.fussnoteAbgeleitet')}</>}
          </p>
        </div>
      </section>
    </div>
  )
}
