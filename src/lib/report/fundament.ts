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
 * Die Ebene mit dem größten Einbruch.
 *
 * Der Abstieg ist nicht monoton — bei der Sitzung d8b0d885 lautet die Spur
 * 2/2 · 2/3 · 0/2 · 1/3 · 1/4 · 3/3. Er bricht in der MITTE, ganz unten trägt
 * wieder alles. Die Erzählung „immer tiefer bis zum Grund" passt darauf nicht,
 * und „0 von 2" stand bis R4 unkommentiert in einer Zeile, obwohl es der
 * schärfste Datenpunkt des ganzen Dokuments ist.
 *
 * Kriterium ist der ANTEIL, nicht die absolute Zahl: 0 von 2 wiegt schwerer als
 * 1 von 4, obwohl dort mehr Bereiche fehlen. Bei gleichem Anteil gewinnt die
 * breitere Grundlage, danach die höhere Ebene — dort merkt es das Kind zuerst.
 *
 * null, wenn keine Ebene einen Einbruch hat.
 */
export function findeEinbruch(
  ebenen: readonly FundamentEbene[],
): FundamentEbene | null {
  const mitLuecke = ebenen.filter((e) => e.traegt < e.geprueft)
  if (mitLuecke.length === 0) return null

  return mitLuecke.reduce((schlimmste, e) => {
    const anteilE = e.traegt / e.geprueft
    const anteilS = schlimmste.traegt / schlimmste.geprueft
    if (anteilE !== anteilS) return anteilE < anteilS ? e : schlimmste
    if (e.geprueft !== schlimmste.geprueft)
      return e.geprueft > schlimmste.geprueft ? e : schlimmste
    return e.delta < schlimmste.delta ? e : schlimmste
  })
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
