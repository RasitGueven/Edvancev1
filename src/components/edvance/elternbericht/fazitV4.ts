// Eltern-Bericht v4 — das Fazit auf Seite 5 (Bauauftrag V4, V4-2 Entscheidung 6):
// Stufen, Lückenfelder, Fahrplan und Start in drei bis fünf Sätzen, aus denselben
// Daten wie vorne. Reine Funktion über t.

import type { TFunction } from 'i18next'

import { lueckenStufe } from '@/lib/report/elternbericht/stufenBlick'
import type { EbFahrplan, EbLernpfadPunkt, EbStufenZeile, ThemenfeldKey } from '@/types'

import { stufenKlasse } from './berichtSaetze'

type T = TFunction<'elternbericht'>

export function fazitSaetzeV4(
  t: T,
  {
    stufen,
    felder,
    fahrplan,
    lernpfad,
    sorgfalt,
    wessen,
    startV3,
  }: {
    stufen: readonly EbStufenZeile[]
    /** lueckenFelder(bericht.profil) */
    felder: readonly ThemenfeldKey[]
    fahrplan: EbFahrplan
    lernpfad: readonly EbLernpfadPunkt[]
    sorgfalt: boolean
    /** genitiv(name); null ohne Namen. */
    wessen: string | null
    /** Rückfall, wenn der erste Lernpfad-Punkt keine kommende Arbeit vorbereitet. */
    startV3: string | null
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
      ? t('v4.s5.fazit.luecken', { stufe: stufenKlasse(t, zeile), felder: feldText })
      : zeile
        ? t('ursache.grundlagen.bestaetigt', { stufe: stufenKlasse(t, zeile) })
        : feldText
          ? t('s1.blick.luecken', { felder: feldText })
          : null
  const fehlend = fahrplan.stationen.filter((s) => s.nummer > 1 && s.signal === 'fehlt')
  // L5: „Klassenarbeiten“ zählt nur Arbeiten mit Nummer; sonst (oder ohne solche) die Themen.
  const arbeiten = fehlend.filter((s) => s.ka !== null).length
  const fehlen = arbeiten > 0 ? arbeiten : fehlend.length
  const ziel = fahrplan.stationen.find((s) => s.nummer === lernpfad[0]?.ziele[0])

  return [
    basisSitzt
      ? wessen && basis
        ? t('v4.s5.fazit.grundlagen', { wessen, stufe: stufenKlasse(t, basis) })
        : t('ursache.grundlagen.basisSitzt')
      : null,
    lueckenSatz,
    lueckenSatz && fehlen > 0
      ? t(arbeiten > 0 ? 'v4.s5.fazit.fahrplan' : 'v4.s5.fazit.fahrplanThema', { count: fehlen })
      : null,
    sorgfalt ? t('v4.s5.fazit.sorgfalt') : null,
    ziel ? t('v4.s5.fazit.start', { thema: ziel.titel }) : startV3,
  ].filter((s): s is string => Boolean(s))
}
