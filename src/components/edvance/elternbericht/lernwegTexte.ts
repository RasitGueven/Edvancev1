// Lernweg (R7-9) — die Texte für Seite 3 und Station 03 an einer Stelle:
// Zonen, Klassenangaben, ↳-Unterzeilen, Quelle, Monat, Legende. Alles aus dem
// Namespace `elternbericht`; die Präsentation holt sie über dieselbe Funktion.

import { useTranslation } from 'react-i18next'

import { stufeVon } from '@/lib/report/elternbericht/plan'
import type { Lernweg, LwInsel, LwStand, LwUnter, LwWeitere, LwZaehlzeile, LwZoneKey } from '@/types'

/** Einträge der Legende, in der Reihenfolge des Entwurfs. */
export const LEGENDE = ['sicher', 'uebung', 'offen', 'linie', 'unter', 'broeckelt', 'kommt'] as const
export type LegendenArt = (typeof LEGENDE)[number]

/** Nur, was auf der Fläche vorkommt (Entscheidung 12). */
export function legendeFuer(lw: Lernweg, mitNaechsterKlasse = false): LegendenArt[] {
  const inseln = lw.zonen.flatMap((z) => z.inseln)
  const staende = new Set<LwStand>(inseln.flatMap((i) => i.eintraege.flatMap((e) => [e.stand, ...e.unter.map((u) => u.stand)])))
  const kommt = (lw.zonen.find((z) => z.key === 'kommt')?.inseln.length ?? 0) > 0 || (mitNaechsterKlasse && !!lw.naechsteKlasse)
  const da: Record<LegendenArt, boolean> = {
    sicher: staende.has('sicher'),
    uebung: staende.has('uebung'),
    offen: staende.has('offen'),
    linie: lw.linien.length > 0,
    unter: inseln.some((i) => i.eintraege.some((e) => e.unter.length > 0)),
    broeckelt: inseln.some((i) => i.broeckelt),
    kommt,
  }
  return LEGENDE.filter((a) => da[a])
}

export function useLernwegTexte(lw: Lernweg) {
  const { t, i18n } = useTranslation('elternbericht')
  const monat = lw.datum
    ? new Intl.DateTimeFormat(i18n.language, { month: 'long', timeZone: 'Europe/Berlin' }).format(new Date(lw.datum))
    : null
  const quelle = (art: 'quelle' | 'quelleAus'): string =>
    lw.quelle === 'klp'
      ? t(`s3.weg.${art}.klp`)
      : lw.schulname
        ? t(`s3.weg.${art}.schule`, { schulname: lw.schulname })
        : t(`s3.weg.${art}.schuleOhneName`)

  return {
    t,
    monat,
    /** „laut Schulplan der Schule …“ / „nach dem Kernlehrplan NRW“ (Intro). */
    quelle: quelle('quelle'),
    /** „dem Schulplan der Schule …“ / „dem Kernlehrplan NRW“ (Hinweis). */
    quelleAus: quelle('quelleAus'),
    hier: monat ? t('s3.weg.hier', { monat }) : t('s3.weg.hierOhneMonat'),
    zoneName: (key: LwZoneKey): string => t(`s3.weg.zone.${key}`),
    /** Die leise Zeile unter dem Zonennamen. */
    zoneKlasse: (key: LwZoneKey, mitNaechsterKlasse = false): string => {
      if (key === 'grundlagen') return t('stufe.erprobung')
      if (key === 'weiterfuehrend') return t('stufe.erste')
      if (key === 'aktuell') {
        return lw.thema
          ? t('s3.weg.zone.aktuellKlasse', { klasse: lw.klasse, thema: lw.thema })
          : t('s3.weg.zone.aktuellKlasseOhneThema', { klasse: lw.klasse })
      }
      if (lw.quelle === 'klp') return t('s3.weg.zone.kommtKlp', { stufe: t(`stufe.${stufeVon(lw.klasse)}`) })
      return mitNaechsterKlasse && lw.naechsteKlasse
        ? t('s3.weg.zone.kommtSchuleNaechste', { klasse: lw.klasse, naechste: lw.naechsteKlasse.klasse })
        : t('s3.weg.zone.kommtSchule', { klasse: lw.klasse })
    },
    inselTitel: (i: LwInsel): string => (i.feld ? t(`feld.${i.feld}`) : (i.titel ?? '')),
    stand: (s: LwStand): string => t(`s3.weg.stand.${s}`),
    /** „baut darauf auf · noch nicht geprüft“ */
    unterZeile: (u: LwUnter): string =>
      t('s3.weg.unter.zeile', {
        wie:
          u.basen.length === 1
            ? t('s3.weg.unter.eine')
            : u.basen.length === 2
              ? t('s3.weg.unter.beide')
              : t('s3.weg.unter.mehrere', { count: u.basen.length }),
        stand: t(`s3.weg.stand.${u.stand}`),
      }),
    spaeter: (klasse: number | null): string => (klasse ? t('s3.weg.spaeter', { klasse }) : ''),
    legende: (a: LegendenArt): string => t(`s3.weg.legende.${a}`),
    /** „+ 3 weitere mit Übungsbedarf, 2 sicher“ (R7-12, Entscheidung 4). */
    weitere: (w: LwWeitere): string => {
      const teile = (['uebung', 'sicher', 'offen'] as const).filter((s) => w[s] > 0)
      return teile
        .map((s, i) =>
          t(i === 0 ? 's3.weg.weitere.erste' : 's3.weg.weitere.folge', { count: w[s], stand: t(`s3.weg.weitere.stand.${s}`) }),
        )
        .join(t('s3.weg.weitere.trenner'))
    },
    /** „Geometrie: 2 sicher · 7 Übungsbedarf“ (R7-12, Entscheidung 5). */
    zaehlzeile: (z: LwZaehlzeile): string =>
      t('s3.weg.zusammen.zeile', {
        feld: t(`feld.${z.feld}`),
        teile: (['sicher', 'uebung'] as const)
          .filter((s) => z[s] > 0)
          .map((s) => t(`s3.weg.zusammen.${s}`, { count: z[s] }))
          .join(t('s3.weg.zusammen.trenner')),
      }),
  }
}
