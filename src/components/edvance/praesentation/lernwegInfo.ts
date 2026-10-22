// Station 03 · Lernweg — was das Infofeld beim Antippen sagt (R7-9,
// Entscheidung 25) und was mit einem Eintrag verbunden ist.

import type { TFunction } from 'i18next'

import type { Lernweg, LwInsel, LwStand, LwWeitere } from '@/types'

type Knoten = { id: string; label: string; stand: LwStand; insel: LwInsel }

/** Alle Einträge (auch ↳) mit ihrer Insel. */
export function knotenVon(lw: Lernweg): Map<string, Knoten> {
  const m = new Map<string, Knoten>()
  for (const z of lw.zonen) {
    for (const i of z.inseln) {
      for (const e of i.eintraege) {
        m.set(e.id, { id: e.id, label: e.label, stand: e.stand, insel: i })
        for (const u of e.unter) m.set(u.id, { id: u.id, label: u.label, stand: u.stand, insel: i })
      }
    }
  }
  return m
}

/** Basen und Ziele eines Eintrags: über Linien und ↳. */
export function bezuege(lw: Lernweg, id: string): { basen: string[]; ziele: string[] } {
  const basen = new Set<string>()
  const ziele = new Set<string>()
  for (const l of lw.linien) {
    if (l.zu === id) basen.add(l.von)
    if (l.von === id) ziele.add(l.zu)
  }
  for (const z of lw.zonen) {
    for (const i of z.inseln) {
      for (const e of i.eintraege) {
        for (const u of e.unter) {
          if (u.id === id) u.basen.forEach((b) => basen.add(b))
          if (u.basen.includes(id)) ziele.add(u.id)
        }
      }
    }
  }
  return { basen: [...basen], ziele: [...ziele] }
}

/** Der Eintrag und alles, was mit ihm verbunden ist. */
export function verbunden(lw: Lernweg, id: string): Set<string> {
  const { basen, ziele } = bezuege(lw, id)
  return new Set([id, ...basen, ...ziele])
}

export type Info = { titel: string | null; text: string }

export function infoEintrag(
  lw: Lernweg,
  id: string,
  t: TFunction<'praesentation'>,
  tb: TFunction<'elternbericht'>,
  liste: (l: string[]) => string,
): Info {
  const k = knotenVon(lw)
  const n = k.get(id)
  if (!n) return infoLeer(t)
  const { basen, ziele } = bezuege(lw, id)
  const label = (x: string): string => k.get(x)?.label ?? ''
  const saetze: string[] = []
  if (ziele.length) saetze.push(t('s3.weg.info.ziele', { liste: liste(ziele.map(label)) }))
  const sichere = basen.filter((b) => k.get(b)?.stand === 'sicher')
  if (sichere.length) saetze.push(t('s3.weg.info.basis', { basis: liste(sichere.map(label)) }))
  if (n.stand === 'offen') saetze.push(t('s3.weg.info.offen'))
  if (n.stand === 'vorgriff') saetze.push(t('s3.weg.info.vorgriff'))
  return {
    titel: t('s3.weg.info.eintrag', { label: n.label, stand: tb(`s3.weg.stand.${n.stand}`) }),
    text: saetze.join(' '),
  }
}

/** Eine Insel in Kommt noch: als Nächstes oder in Klasse …, und was schon sitzt. */
export function infoKommt(
  lw: Lernweg,
  insel: LwInsel,
  t: TFunction<'praesentation'>,
  liste: (l: string[]) => string,
): Info {
  const titel = insel.titel ?? ''
  const jahr = lw.zonen.find((z) => z.key === 'kommt')?.inseln ?? []
  const naechste = lw.naechsteKlasse?.inseln.some((i) => i.id === insel.id)
  const kopf =
    jahr[0]?.id === insel.id
      ? t('s3.weg.info.naechstes', { titel })
      : t('s3.weg.info.spaeter', { titel, klasse: naechste ? lw.naechsteKlasse!.klasse : lw.klasse })
  const k = knotenVon(lw)
  const drin = new Set(insel.eintraege.map((e) => e.id))
  const basen = [...new Set(lw.linien.filter((l) => drin.has(l.zu)).map((l) => l.von))].map((b) => k.get(b)?.label ?? '')
  return { titel: kopf, text: basen.length ? t('s3.weg.info.kommtBasis', { liste: liste(basen) }) : '' }
}

/** „+ n weitere“ angetippt (R7-12, Entscheidung 11): die weggelassenen Bereiche als Liste. */
export const infoWeitere = (w: LwWeitere, t: TFunction<'praesentation'>, liste: (l: string[]) => string): Info => ({
  titel: t('s3.weg.info.weitere'),
  text: liste(w.labels),
})

export const infoLeer = (t: TFunction<'praesentation'>): Info => ({ titel: null, text: t('s3.weg.info.leer') })
