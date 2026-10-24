// Eltern-Bericht v2 — Sätze für Seite 1, 4 und 5 aus den festen Bausteinen in
// i18n. Reine Funktionen über t, damit die Zusammensetzung ohne Rendern
// prüfbar ist. Welche Variante gilt, entscheiden die Regeln in
// src/lib/report/elternbericht/berichtKonfig.ts; hier wird nur zusammengesetzt.

import type { TFunction } from 'i18next'

import { LUECKEN_FELDER } from '@/lib/report/elternbericht/berichtKonfig'
import type { UrsachenAntwort } from '@/lib/report/elternbericht/ursache'
import type {
  EbGrund,
  EbProfilZeile,
  EbSchwerpunkt,
  EbStufeKey,
  EbStufenZeile,
  ReportErstgespraech,
  ThemenfeldKey,
} from '@/types'

type T = TFunction<'elternbericht'>

/** DB-Werte von leads.struggling_since → i18n-Schlüssel (dot-notation ohne snake_case). */
const SEIT_KEY = { dieses_halbjahr: 'diesesHalbjahr', letztes_schuljahr: 'letztesSchuljahr', laenger: 'laenger' } as const

/** „Klasse 5/6“, „Klasse 7/8“, beim aktuellen Stoff die Klassen der Zeile („Klasse 9“). */
export function stufenKlasse(t: T, z: Pick<EbStufenZeile, 'stufe' | 'von' | 'bis'>): string {
  if (z.stufe === 'grundlagen') return t('stufe.erprobung')
  if (z.stufe === 'weiterfuehrend') return t('stufe.erste')
  return z.von === z.bis ? t('s1.stufen.klasse', { k: z.von }) : t('s1.stufen.klasseSpanne', { von: z.von, bis: z.bis })
}

/** Der Kurzsatz einer Zeile; „weitgehend“ heißt beim aktuellen Stoff „fast sicher“. */
export function stufenUrteil(t: T, z: Pick<EbStufenZeile, 'stufe' | 'urteil'>): string {
  if (z.urteil === 'weitgehend' && z.stufe === 'aktuell') return t('s1.stufen.urteil.weitgehendAktuell')
  return t(`s1.stufen.urteil.${z.urteil}`)
}

/** „Ihr Anliegen“: Notenlage, seit wann, vermutete Ursache — nur, was erfasst ist. */
export function anliegenSaetzeV2(
  t: T,
  {
    erstgespraech,
    ursachen,
    name,
    fach,
    liste,
  }: {
    erstgespraech: ReportErstgespraech | null
    /** Anzeigenamen der vermuteten Ursachen (erzaehlung.anlassNamen). */
    ursachen: readonly string[]
    name: string | null
    fach: string
    liste: (s: readonly string[]) => string
  },
): string[] {
  const e = erstgespraech
  return [
    e?.note && (name ? t('s1.anliegen.note', { name, fach, note: e.note }) : t('s1.anliegen.noteOhneName', { fach, note: e.note })),
    e?.note && e.trend && t(`s1.anliegen.trend.${e.trend}`),
    e?.seit && t(`s1.anliegen.seit.${SEIT_KEY[e.seit]}`),
    ursachen.length > 0 && t('s1.anliegen.ursache', { punkte: liste(ursachen) }),
  ].filter((s): s is string => Boolean(s))
}

/** Die Antwort auf die vermutete Ursache, je genannter Ursache ein oder zwei Sätze. */
export function ursachenSaetze(
  t: T,
  antworten: readonly UrsachenAntwort[],
  stufen: readonly EbStufenZeile[],
  name: string | null,
): string[] {
  const klasse = (key: EbStufeKey | undefined): string => {
    const z = stufen.find((s) => s.stufe === key)
    return z ? stufenKlasse(t, z) : ''
  }
  return antworten.flatMap((a) => {
    if (a.key !== 'grundlagen') return [t(`ursache.${a.key}.${a.variante}`, { name: name ?? t('kind') })]
    if (a.variante === 'bestaetigt') {
      if (a.lueckenIn === 'grundlagen') return [t('ursache.grundlagen.bestaetigtTief')]
      return [
        ...(a.grundlagenSitzen ? [t('ursache.grundlagen.basisSitzt')] : []),
        t('ursache.grundlagen.bestaetigt', { stufe: klasse(a.lueckenIn) }),
      ]
    }
    return [
      t('ursache.grundlagen.eherNicht'),
      ...(a.lueckenIn === 'aktuell' ? [t('ursache.grundlagen.eherNichtAktuell', { stufe: klasse('aktuell') })] : []),
    ]
  })
}

/**
 * Die Themenfelder mit dem meisten Übungsbedarf für „Die Lücken liegen vor
 * allem bei …“: ab LUECKEN_FELDER.minUebung, höchstens LUECKEN_FELDER.max,
 * Gleichstand in der Reihenfolge des Profils.
 */
export function lueckenFelder(profil: readonly EbProfilZeile[]): ThemenfeldKey[] {
  return profil
    .map((z, i) => ({ z, i }))
    .filter(({ z }) => z.uebung >= LUECKEN_FELDER.minUebung)
    .sort((a, b) => b.z.uebung - a.z.uebung || a.i - b.i)
    .slice(0, LUECKEN_FELDER.max)
    .map(({ z }) => z.feld)
}

/** Der halbe Satz nach „weil“. */
export function grundText(t: T, g: EbGrund): string {
  if (g.art === 'naechstesThema') return t('grund.naechstesThema', { titel: g.titel })
  if (g.art === 'anzahl') return t('grund.anzahl', { count: g.count })
  return t(`grund.${g.art}`)
}

/** „Wir beginnen mit …, weil …“; null ohne Schwerpunkt oder ohne Grund. */
export function startSatz(t: T, s: EbSchwerpunkt | undefined, grund: EbGrund | undefined): string | null {
  if (!s || !grund) return null
  const was = s.thema ? t('s1.blick.startThema', { thema: s.thema }) : t(`feldMit.${s.feld ?? 'weitere'}`)
  return t('s1.blick.start', { was, grund: grundText(t, grund) })
}

/**
 * Die Schule im Genitiv: „des Friedrich-Wilhelm-Gymnasiums“, „des Gymnasiums
 * Kreuzgasse“, „der Gesamtschule Holweide“; sonst „der Schule …“.
 */
export function schuleGenitiv(t: T, name: string): string {
  if (/(gymnasium|kolleg)$/i.test(name)) return t('schule.gymnasium', { name })
  const gym = name.match(/^(Gymnasium|Kolleg)\s+(.+)$/)
  if (gym) return t('schule.gymnasiumVorn', { art: gym[1], rest: gym[2] })
  if (/(schule|akademie)\b/i.test(name)) return t('schule.schule', { name })
  return t('schule.sonst', { name })
}
