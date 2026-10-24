// Eltern-Bericht v2 — Sätze für Seite 1, 4 und 5 aus den festen Bausteinen in
// i18n. Reine Funktionen über t, damit die Zusammensetzung ohne Rendern
// prüfbar ist. Welche Variante gilt, entscheiden die Regeln in
// src/lib/report/elternbericht/berichtKonfig.ts; hier wird nur zusammengesetzt.

import type { TFunction } from 'i18next'

import { LUECKEN_FELDER } from '@/lib/report/elternbericht/berichtKonfig'
import { lueckenStufe } from '@/lib/report/elternbericht/stufenBlick'
import type { UrsachenAntwort } from '@/lib/report/elternbericht/ursache'
import type {
  EbGrund,
  EbProfilZeile,
  EbSchwerpunkt,
  EbStufeKey,
  EbStufenZeile,
  ReportErstgespraech,
  ReportPaket,
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
    fach,
    liste,
  }: {
    erstgespraech: ReportErstgespraech | null
    /** Anzeigenamen der vermuteten Ursachen (erzaehlung.anlassNamen). */
    ursachen: readonly string[]
    fach: string
    liste: (s: readonly string[]) => string
  },
): string[] {
  const e = erstgespraech
  // Bericht v3: Note und Tendenz in einer knappen Zeile, ohne Namen.
  return [
    e?.note &&
      (e.trend ? t(`s1.anliegen.noteTrend.${e.trend}`, { fach, note: e.note }) : t('s1.anliegen.note', { fach, note: e.note })),
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
  if (g.art === 'naechstesThema') {
    if (!g.stufe || !g.reihe) return t('grund.naechstesThema', { titel: g.titel })
    const stufe = t(`stufe.${g.stufe}`)
    return g.reihe === 'zuerst'
      ? t('grund.naechstesThemaZuerst', { titel: g.titel, stufe })
      : t('grund.naechstesThemaDanach', { titel: g.titel, stufe })
  }
  if (g.art === 'spaeterGebraucht') return t('grund.spaeterGebraucht', { titel: g.titel })
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

/**
 * Das Fazit auf Seite 5 (Bericht v3): Seite 1–4 in drei bis vier Sätzen, aus
 * denselben Daten — wie es um die Grundlagen steht, wo die Lücken liegen, das
 * Fehlermuster, womit wir beginnen. Kein neuer Inhalt.
 */
export function fazitSaetze(
  t: T,
  {
    stufen,
    felder,
    sorgfalt,
    start,
  }: {
    stufen: readonly EbStufenZeile[]
    /** lueckenFelder(bericht.profil) */
    felder: readonly ThemenfeldKey[]
    sorgfalt: boolean
    /** startSatz(...) */
    start: string | null
  },
): string[] {
  const luecken = lueckenStufe(stufen) ?? undefined
  const basis = stufen.find((z) => z.stufe === 'grundlagen')
  const basisSitzt = basis && (basis.urteil === 'sicher' || basis.urteil === 'weitgehend') && luecken !== 'grundlagen'
  const feldText =
    felder.length === 2
      ? t('s5.fazit.zweiFelder', { erstes: t(`feldMit.${felder[0]}`), zweites: t(`feldMit.${felder[1]}`) })
      : felder.length === 1
        ? t(`feldMit.${felder[0]}`)
        : null
  const zeile = stufen.find((z) => z.stufe === luecken)
  const lueckenSatz =
    zeile && feldText
      ? t('s5.fazit.luecken', { stufe: stufenKlasse(t, zeile), felder: feldText })
      : zeile
        ? t('ursache.grundlagen.bestaetigt', { stufe: stufenKlasse(t, zeile) })
        : feldText
          ? t('s1.blick.luecken', { felder: feldText })
          : null
  return [
    basisSitzt ? t('ursache.grundlagen.basisSitzt') : null,
    lueckenSatz,
    sorgfalt ? t('s1.blick.muster') : null,
    start,
  ].filter((s): s is string => Boolean(s))
}

/** Wie viele Schwerpunkte die Ziele je Paket umfassen: gleiche Richtung, anderer Umfang. */
const ZIELE_JE_PAKET = { basis: 2, standard: 3, premium: 4 } as const

/**
 * Ziele für die nächsten 6 Monate (Bericht v3): ein Systemvorschlag aus den
 * Schwerpunkten (in ihrer Reihenfolge) und dem Paket. Nur Förderziele („…
 * sicher anwenden“), nie Noten- oder Ergebnisziele; mit Sorgfaltsmuster ein
 * Ziel dazu. Das Paket bestimmt nur, wie viele Schwerpunkte in sechs Monaten
 * vorkommen.
 */
export function zieleSaetze(
  t: T,
  {
    schwerpunkte,
    gruende,
    paket,
    sorgfalt,
    liste,
  }: {
    schwerpunkte: readonly EbSchwerpunkt[]
    gruende: readonly (EbGrund | undefined)[]
    paket: ReportPaket
    sorgfalt: boolean
    liste: (s: readonly string[]) => string
  },
): string[] {
  const ziele = schwerpunkte.slice(0, ZIELE_JE_PAKET[paket]).map((s, i) => {
    const g = gruende[i]
    const was =
      g?.art === 'spaeterGebraucht' || g?.art === 'themaGeschrieben'
        ? liste(s.uebung)
        : (s.thema ?? t(`feldZiel.${s.feld ?? 'weitere'}`))
    if (g?.art === 'naechstesThema' || g?.art === 'spaeterGebraucht') return t('s5.ziele.vorThema', { was, titel: g.titel })
    if (g?.art === 'klassenarbeit') return t('s5.ziele.klassenarbeit', { was })
    return t('s5.ziele.allgemein', { was })
  })
  return sorgfalt ? [...ziele, t('s5.ziele.sorgfalt')] : ziele
}
