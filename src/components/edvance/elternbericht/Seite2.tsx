import { useTranslation } from 'react-i18next'

import type { ThemenfeldKey } from '@/types'

import { Profil } from './Profil'
import { deutung, meisterUebung, profilZeilen } from './seite2Rechnung'
import type { SeitenProps } from './seitenProps'
import { useStufe } from './useStufe'

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
 *
 * Bericht v4 (mit bericht.fahrplan): je Zeile „Wichtig für“ mit den
 * Klassenarbeiten, „Was die Grafik zeigt“ im mint Kasten.
 */
export function Seite2({ data, bericht, name }: SeitenProps): JSX.Element {
  const fahrplan = bericht.fahrplan ?? null
  // Bericht v4: Mit den „Wichtig für“-Zeilen läuft die Seite eher über; dann rückt sie enger zusammen.
  const dicht = useStufe(fahrplan ? 2 : 0)
  const { t, i18n } = useTranslation('elternbericht')
  const { zaehlung } = bericht
  // Bericht v2: nur direkt geprüfte Bereiche, keine Umrisse abgeleiteter Bereiche.
  const profil = profilZeilen({
    profil: bericht.profil,
    bereiche: [...bericht.sicherListe, ...bericht.uebungListe],
    abgeleitet: [],
  })
  const liste = new Intl.ListFormat(i18n.language, { style: 'long', type: 'conjunction' })
  const felder = (keys: ThemenfeldKey[]): string => liste.format(keys.map((k) => t(`feld.${k}`)))
  const d = deutung(profil)
  const meist = meisterUebung(profil)
  // Die Felder des Übungsbedarf-Satzes zählen nicht zusätzlich als „überwiegend sicher“.
  const sicherFelder = d.sicher.filter((f) => !meist?.felder.includes(f))
  const saetze = [
    sicherFelder.length > 0 && t('s2.deutung.sicher', { count: sicherFelder.length, felder: felder(sicherFelder) }),
    meist &&
      (meist.felder.length === 1
        ? t('s2.deutung.uebungAnteil', { feld: felder(meist.felder), uebung: meist.uebung, geprueft: meist.geprueft })
        : t('s2.deutung.uebungAnteilMehrere', { felder: felder(meist.felder), uebung: meist.uebung, geprueft: meist.geprueft })),
  ].filter((s): s is string => Boolean(s))
  // Warum auch frühere Klassen? Nur, wenn es frühere Klassen ab 5 gibt.
  const bis = data.grade - 1
  const werte = { sicher: zaehlung.sicher, uebung: zaehlung.uebung, geprueft: zaehlung.untersucht }

  return (
    <div
      ref={dicht.ref}
      data-stufe={dicht.wert || undefined}
      data-v4={fahrplan ? true : undefined}
      className={[
        'eb-s2',
        profil.length >= 7 || bis >= 5 ? 'eb-s2-eng' : '',
        fahrplan ? 'eb-s2-v4' : '',
      ]
        .filter(Boolean)
        .join(' ')}
    >
      <p className="eb-kicker eb-s2-kicker">{t('s2.kicker')}</p>
      <h1 className="eb-titel eb-s2-titel">
        {name ? t('s2.titel', { name }) : t('s2.titelOhneName')}
      </h1>

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

      {bis >= 5 && (
        <section className="eb-s2-warum" data-testid="eb-warum">
          <h2 className="eb-kicker">{t('s2.warum.kicker')}</h2>
          <p className="eb-s2-warum-text">{bis === 5 ? t('s2.warum.textEine') : t('s2.warum.text', { bis })}</p>
        </section>
      )}

      <Profil
        profil={profil}
        wessen={null}
        klassenarbeiten={fahrplan ? { fahrplan, signale: bericht.signale ?? [] } : undefined}
      />

      <section className={fahrplan ? 'eb-s2-deutung eb-s2-deutung-v4' : 'eb-s2-deutung'} data-testid="eb-deutung">
        <h2 className="eb-kicker eb-s2-deutung-kicker">{t('s2.deutung.kicker')}</h2>
        <div>
          {saetze.length > 0 && (
            <p className="eb-s2-deutung-text">
              {saetze.map((s, i) => (
                <span key={i}>
                  {i > 0 && ' '}
                  {s}
                </span>
              ))}
            </p>
          )}
          <p className="eb-s2-fussnote">{t('s2.fussnote')}</p>
        </div>
      </section>
    </div>
  )
}
