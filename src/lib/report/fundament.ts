// Eltern-Report — das Fundament unter dem aktuellen Thema (R4).
//
// Reine Rechnung, keine Datenbank: alles hier bekommt die Skill-Urteile als
// Argument. Der Lesepfad liegt in src/lib/supabase/, der Generator für die
// HTML-Entwürfe in scripts/report/ — beide rufen dieselben Funktionen auf,
// damit App und Entwurf nicht auseinanderlaufen.
//
// ----------------------------------------------------------------------------
// Warum das eine eigene Ebene braucht
// ----------------------------------------------------------------------------
// Bis R3 sagte Abschnitt 02 fest verdrahtet: „Als sich zeigte, dass sie noch
// nicht sicher sitzen, sind wir Schritt für Schritt tiefer gegangen." In den
// beiden echten Sitzungen vom 16.08. trägt das Einstiegsthema aber (2 von 2) —
// und der Einstiegsskill steht einen Abschnitt weiter unter „Das trägt". Ein
// Elternteil liest den Widerspruch sofort.
//
// Der Renderer konnte das nicht anders entscheiden, weil ihm der Begriff
// fehlte: Er kannte Ltief (wie tief liegen die Lücken), aber nicht den ZUSTAND
// DES EINSTIEGS. Genau den liefert diese Datei.

import type { Fundament, FundamentEbene, FundamentSkill } from '@/types'

/** Nur dieser Zustand ist ein positiver Beleg. Alles andere ist es nicht. */
const TRAEGT = 'traegt'

/**
 * Höchstens so viele Labels als Untertitel einer Ebenenzeile.
 *
 * „Zwei Ebenen tiefer" sagt für sich genommen nichts — die Zeile braucht die
 * Bereiche, die dort tatsächlich liegen. Drei ist die Grenze, ab der die Zeile
 * zum Absatz wird; darüber steht „u. a.".
 */
export const MAX_EBENEN_LABELS = 3

const nachLabel = (a: FundamentSkill, b: FundamentSkill) =>
  a.label.localeCompare(b.label, 'de')

/**
 * Schichtet die direkt geprüften Skills und leitet daraus alles ab, was die
 * Erzählung braucht.
 *
 * Erwartet AUSSCHLIESSLICH direkt geprüfte Skills (lsa_skill_urteil.
 * belegt_direkt = true). Mitbelegte Urteile sind aus dem Voraussetzungsgraphen
 * gefolgert — eine Schlussfolgerung, keine Beobachtung — und haben in einem
 * Elterngespräch nichts verloren. Das Filtern passiert im Lesepfad, nicht hier,
 * damit diese Funktion testbar bleibt.
 *
 * Gibt null zurück, wenn nichts direkt geprüft wurde: dann gibt es kein
 * Fundament zu beschreiben, und der Report lässt die Abschnitte weg.
 */
export function baueFundament(skills: readonly FundamentSkill[]): Fundament | null {
  if (skills.length === 0) return null

  const einstiegTiefe = Math.max(...skills.map((s) => s.fundamentTiefe))

  // Absteigend: aktuelles Thema zuerst, dann abwärts. Ebenen ohne geprüften
  // Skill entstehen gar nicht erst — eine leere Zeile im Abstieg wäre eine
  // Behauptung über etwas, das nicht geprüft wurde.
  const tiefen = [...new Set(skills.map((s) => s.fundamentTiefe))].sort((a, b) => b - a)

  const ebenen: FundamentEbene[] = tiefen.map((tiefe) => {
    const drauf = skills.filter((s) => s.fundamentTiefe === tiefe).sort(nachLabel)
    return {
      tiefe,
      delta: einstiegTiefe - tiefe,
      geprueft: drauf.length,
      traegt: drauf.filter((s) => s.zustand === TRAEGT).length,
      labels: drauf.slice(0, MAX_EBENEN_LABELS).map((s) => s.label),
      weitere: Math.max(0, drauf.length - MAX_EBENEN_LABELS),
    }
  })

  const tragend = skills
    .filter((s) => s.zustand === TRAEGT)
    .sort((a, b) => b.fundamentTiefe - a.fundamentTiefe || nachLabel(a, b))

  // Aufsteigend nach Tiefe: die tiefste Lücke zuerst. Der Report arbeitet von
  // unten nach oben, weil oben auf unten aufbaut.
  const luecken = skills
    .filter((s) => s.zustand !== TRAEGT)
    .sort((a, b) => a.fundamentTiefe - b.fundamentTiefe || nachLabel(a, b))

  const einstiegEbene = ebenen[0]
  const darunter = ebenen.slice(1)

  return {
    einstiegTiefe,
    ebenen,
    geprueft: skills.length,
    traegt: tragend.length,
    luecken,
    tragend,
    einstiegTraegt: einstiegEbene.traegt === einstiegEbene.geprueft,
    fundamentGeprueft: darunter.length > 0,
    // Keine Ebene darunter geprüft? Dann ist über das Fundament nichts bekannt,
    // und „es trägt" wäre eine Behauptung ohne Beleg.
    fundamentTraegt:
      darunter.length > 0 && darunter.every((e) => e.traegt === e.geprueft),
    einbruch: findeEinbruch(ebenen),
    bodenTraegt: ebenen[ebenen.length - 1].traegt === ebenen[ebenen.length - 1].geprueft,
  }
}

/**
 * Mindestzahl geprüfter Bereiche, damit eine Ebene als Einbruch zitierbar ist.
 *
 * „1 von 2" ist keine belastbare Aussage über eine Ebene — ein einziges
 * Skill-Urteil, das bei zwei Proben kippt, dreht den Wert von 50 % auf 0 oder
 * 100 %. Erst ab drei Bereichen trägt die Zahl.
 */
export const MIN_GEPRUEFT_EINBRUCH = 3

/**
 * Mindestabstand im Anteil zur nächstschlechteren Ebene.
 *
 * Warum 0,25: Eine Ebene trägt in der Praxis drei bis fünf geprüfte Bereiche.
 * Ein einzelner Bereich ist dort 20 bis 33 Prozentpunkte wert. Ein Abstand
 * unter einem Viertel lässt sich also durch EIN einziges Skill-Urteil erzeugen
 * — und genau ein Urteil ist das, was zwei Proben danebenliegen können.
 *
 * Der Satz „am deutlichsten zeigt es sich hier" behauptet eine Rangordnung.
 * Sie muss größer sein als die Unschärfe, aus der sie entsteht.
 */
export const MIN_ABSTAND_EINBRUCH = 0.25

/**
 * Die Ebene mit dem größten Einbruch — oder null, wenn es keinen gibt.
 *
 * Der Abstieg ist nicht monoton. Bei der Sitzung d8b0d885 lautet die Spur
 * 2/2 · 2/3 · 0/2 · 1/3 · 1/4 · 3/3; er bricht in der MITTE, ganz unten trägt
 * wieder alles. Die Erzählung „immer tiefer bis zum Grund" passt darauf nicht.
 *
 * ----------------------------------------------------------------------------
 * Warum zwei Bedingungen und nicht nur „die schlechteste Ebene"
 * ----------------------------------------------------------------------------
 * Bis R5 nahm die Funktion schlicht die Ebene mit dem kleinsten Anteil. Bei der
 * Sitzung 920d00ae ergab das „Am deutlichsten zeigt es sich zwei Ebenen unter
 * dem aktuellen Thema: Dort trugen 1 von 2 geprüften Bereichen." — drei Ebenen
 * tiefer stand aber ebenfalls 1 von 2. Die Funktion entschied den Gleichstand
 * über eine Tiebreaker-Regel und der Text machte daraus einen Befund. Es gab
 * dort schlicht keinen Einbruch.
 *
 * Beide Bedingungen müssen halten:
 *   1. die Ebene trägt mindestens MIN_GEPRUEFT_EINBRUCH geprüfte Bereiche
 *   2. ihr Anteil liegt mindestens MIN_ABSTAND_EINBRUCH unter dem der
 *      nächstschlechteren Ebene, die Bedingung 1 ebenfalls erfüllt
 *
 * Sonst null — und der Satz entfällt ersatzlos.
 */
export function findeEinbruch(
  ebenen: readonly FundamentEbene[],
): FundamentEbene | null {
  const anteil = (e: FundamentEbene) => e.traegt / e.geprueft

  // Nur Ebenen mit tragfähiger Grundlage kommen überhaupt in Frage — auch als
  // Vergleichsmaßstab. Eine 0-von-2-Ebene als „nächstschlechtere" heranzuziehen
  // hieße, die Rangordnung an derselben Unschärfe zu messen, die Bedingung 1
  // gerade ausschließt.
  const kandidaten = ebenen
    .filter((e) => e.geprueft >= MIN_GEPRUEFT_EINBRUCH && e.traegt < e.geprueft)
    .sort((a, b) => anteil(a) - anteil(b) || b.geprueft - a.geprueft || a.delta - b.delta)

  if (kandidaten.length === 0) return null

  const schlimmste = kandidaten[0]
  const naechste = kandidaten[1]

  // Einzige Ebene mit Lücke und tragfähiger Grundlage: Es gibt nichts, wogegen
  // sie sich abheben müsste — sie IST der Einbruch.
  if (!naechste) return schlimmste

  return anteil(naechste) - anteil(schlimmste) >= MIN_ABSTAND_EINBRUCH
    ? schlimmste
    : null
}

/**
 * Der Fall-Schlüssel für den Erzählbaustein in Abschnitt 02 (slot 'suche').
 *
 * Vier Fälle über zwei Achsen — trägt der Einstieg, trägt das darunter. Bis R4
 * kannte der Renderer nur `einstieg_luecken_fundament_luecken` und behauptete
 * ihn auch dann, wenn die Zahlen daneben das Gegenteil zeigten.
 */
export function sucheFall(f: Fundament): string | null {
  // Nichts unterhalb des Einstiegs geprüft: Es gab keinen Abstieg, also gibt es
  // auch nichts über ihn zu erzählen. Der Slot bleibt leer, statt einen der
  // vier Fälle zu behaupten — jeder davon würde etwas über das Fundament
  // aussagen, das die Sitzung nicht angesehen hat.
  if (!f.fundamentGeprueft) return null
  if (f.einstiegTraegt && f.fundamentTraegt) return 'alles_traegt'
  if (f.einstiegTraegt) return 'einstieg_traegt_fundament_luecken'
  if (f.fundamentTraegt) return 'einstieg_luecken_fundament_traegt'
  return 'einstieg_luecken_fundament_luecken'
}
