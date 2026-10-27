// LSA-L4 Teil D (docs/lsa/Bauauftrag-L4.md, Entscheidungen 12–14): der Satz zur Klassenarbeit im aktuellen Thema,
// je nach Stand. Auf Seite 3 des Berichts v4 (Einstieg) und in Station 03 der Präsentation (Karte der aktuellen
// Arbeit). Hier nur die Auswahl und die Werte; die Texte stehen in den Namespaces elternbericht bzw. praesentation
// unter v4.s3.ka (kaTeile liefert die Schlüssel).
//
// Fälle:
//   steht  Arbeit steht an oder Stand unbekannt
//   offen  geschrieben, Note offen: sicher {X}, noch unsicher {Y}; dann der Abgleich, sobald die Note da ist
//   note   geschrieben, Note bekannt: „dazu passt“ {Y}; {Y} wird bei Klassenarbeit {k} wieder gebraucht
//          (L5: ohne bekannte Arbeit bei „{Thema}“, nie mit einer Nummer, die nicht feststeht)
// {X}/{Y}: höchstens zwei Bereiche (direkt geprüft) aus dem Themenraum. Ohne {Y} entfällt der Satzteil mit {Y}, ohne
// kommende Arbeit, die {Y} braucht, der letzte Satz. Keine erwartete Note, keine Ursache.

import type { Elternbericht, KlassenarbeitStatus } from '@/types'

/** Höchstens so viele Bereiche je Platzhalter. */
const JE_PLATZHALTER = 2

export type KaFall = 'steht' | 'offen' | 'note'

export type KaSatz = {
  fall: KaFall
  /** Titel des aktuellen Themas (Fahrplan, sonst Thema der LSA). */
  thema: string
  /** {X}: sichere Bereiche im Themenraum. */
  sicher: string[]
  /** {Y}: Bereiche mit Übungsbedarf im Themenraum. */
  unsicher: string[]
  /** {n}: gemeldete Note, nur im Fall note. */
  note: number | null
  /** {k}: erste kommende Station, die einen der {Y} braucht; null ohne. ka = Nummer der Arbeit, null = unbekannt. */
  k: { ka: number | null; thema: string } | null
}

/** Ein Satz: Schlüssel unter v4.s3.ka und seine Werte (Listen schon verbunden). */
export type KaTeil = { key: string; values: Record<string, string | number> }

export function kaSatz(
  bericht: Elternbericht,
  status: KlassenarbeitStatus | null,
  note: number | null,
): KaSatz | null {
  const thema = bericht.fahrplan?.stationen[0]?.titel ?? bericht.thema?.titel ?? null
  if (!thema) return null
  const sicher = (bericht.thema?.sicher ?? []).slice(0, JE_PLATZHALTER)
  const unsicher = (bericht.thema?.uebung ?? []).slice(0, JE_PLATZHALTER)
  if (status !== 'geschrieben') return { fall: 'steht', thema, sicher: [], unsicher: [], note: null, k: null }
  const mitNote = note !== null && note >= 1 && note <= 6
  return { fall: mitNote ? 'note' : 'offen', thema, sicher, unsicher, note: mitNote ? note : null, k: kommendeArbeit(bericht, unsicher) }
}

/** Die erste kommende Station, deren Signal einen der Bereiche als fehlend führt (bei einer Arbeit: eines ihrer Themen). */
function kommendeArbeit(bericht: Elternbericht, bereiche: string[]): KaSatz['k'] {
  if (bereiche.length === 0) return null
  const themen = new Set(
    (bericht.signale ?? []).filter((s) => s.fehlt.some((b) => bereiche.includes(b.label))).map((s) => s.themaKey),
  )
  const s = (bericht.fahrplan?.stationen ?? [])
    .filter((x) => x.nummer > 1)
    .sort((a, b) => a.nummer - b.nummer)
    .map((x) => ({ x, thema: x.themen.find((t) => themen.has(t.themaKey)) }))
    .find((y) => y.thema !== undefined)
  return s?.thema ? { ka: s.x.ka, thema: s.thema.titel } : null
}

/**
 * Die Sätze in Reihenfolge, als Schlüssel unter v4.s3.ka. Listen werden mit Intl.ListFormat der Sprache verbunden
 * („A und B“); count steuert Einzahl/Mehrzahl (war/waren, wird/werden). `zitat` setzt jeden Bereichsnamen in
 * Anführungszeichen (v4.s3.ka.bereich), damit Namen mit „und“ in der Aufzählung lesbar bleiben.
 */
export function kaTeile(satz: KaSatz, sprache: string, zitat: (label: string) => string = (l) => l): KaTeil[] {
  const liste = new Intl.ListFormat(sprache, { style: 'long', type: 'conjunction' })
  const x = liste.format(satz.sicher.map(zitat))
  const y = liste.format(satz.unsicher.map(zitat))
  const { thema } = satz
  if (satz.fall === 'steht') return [{ key: 'steht', values: { thema } }]
  if (satz.fall === 'offen') {
    const analyse: KaTeil | null =
      satz.sicher.length > 0 && satz.unsicher.length > 0
        ? { key: 'analyse.xy', values: { thema, x, y, count: satz.sicher.length } }
        : satz.sicher.length > 0
          ? { key: 'analyse.x', values: { thema, x, count: satz.sicher.length } }
          : satz.unsicher.length > 0
            ? { key: 'analyse.y', values: { thema, y } }
            : null
    return [analyse ?? { key: 'geschrieben', values: { thema } }, { key: 'abgleich', values: {} }]
  }
  const teile: KaTeil[] = [{ key: 'note', values: { thema, n: satz.note ?? '' } }]
  if (satz.unsicher.length > 0) {
    teile.push({ key: 'dazu', values: { y, count: satz.unsicher.length } })
    if (satz.k && satz.k.ka !== null) teile.push({ key: 'wieder', values: { y, k: satz.k.ka, count: satz.unsicher.length } })
    else if (satz.k) teile.push({ key: 'wiederThema', values: { y, thema: satz.k.thema, count: satz.unsicher.length } })
  }
  return teile
}
