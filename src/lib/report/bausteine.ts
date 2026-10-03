// Eltern-Report — Auswahl der Erzählbausteine (R4).
//
// Die Sätze stehen in report_bausteine, nicht hier. Diese Datei entscheidet
// nur, WELCHER Satz an welche Stelle kommt, und setzt die Platzhalter ein.
//
// ----------------------------------------------------------------------------
// Warum zwei Varianten je Fall
// ----------------------------------------------------------------------------
// Ein Standort schickt an einem Abend mehrere Reports raus. Sind sie
// wortgleich, liest sich das wie ein Serienbrief — und entwertet genau den
// Eindruck, den ein Report über das eigene Kind erzeugen soll. Zwei Fassungen
// je Fall reichen, um das aufzubrechen, ohne die Abnahme zu vervielfachen.
//
// Die Wahl ist DETERMINISTISCH über die Sitzungs-ID: Dieselbe Sitzung ergibt
// immer denselben Satz. Ein Report, der sich beim zweiten Öffnen anders liest,
// wäre ein Fehler — Eltern drucken ihn aus, legen ihn weg und lesen ihn im
// Gespräch noch einmal.

import type { ReportBaustein } from '@/types'

/**
 * Trennzeichen der zusammengesetzten Nachschlage-Schlüssel.
 *
 * Bewusst ein Zeichen, das in einem Slot- oder Fall-Namen nicht vorkommen kann —
 * sonst könnten `('a b', 'c')` und `('a', 'b c')` auf denselben Schlüssel fallen.
 * Als Escape-Sequenz geschrieben, damit die Quelldatei ASCII bleibt.
 */
const TRENNER = '\u0000'

/**
 * Stabiler Streuwert über einen String (FNV-1a, 32 Bit).
 *
 * Bewusst keine Krypto-Funktion und kein Math.random(): gebraucht wird
 * Wiederholbarkeit über Prozessgrenzen hinweg — dieselbe Sitzungs-ID muss in
 * der App und im Entwurfs-Generator dieselbe Variante ergeben.
 */
export function streuwert(text: string): number {
  let h = 0x811c9dc5
  for (let i = 0; i < text.length; i++) {
    h ^= text.charCodeAt(i)
    h = Math.imul(h, 0x01000193)
  }
  return h >>> 0
}

/**
 * Nachschlagewerk über die abgenommenen Bausteine.
 *
 * `waehle` gibt null zurück, wenn es zu (slot, fall) keinen abgenommenen
 * Baustein gibt. Der Aufrufer lässt die Stelle dann leer — dieselbe
 * Weglass-Regel wie bei den Fehlbild-Familien (AF4/AF5): Ein Platzhalter
 * würde genau die Behauptung aufstellen, die die Abnahme verhindern soll.
 */
export class Bausteinsatz {
  private readonly nachFall: Map<string, ReportBaustein[]>

  constructor(bausteine: readonly ReportBaustein[]) {
    this.nachFall = new Map()
    for (const b of bausteine) {
      const key = `${b.slot}${TRENNER}${b.fall}`
      const liste = this.nachFall.get(key)
      if (liste) liste.push(b)
      else this.nachFall.set(key, [b])
    }
    // Nach Variante sortieren, damit die Auswahl nicht von der
    // Zeilenreihenfolge der Datenbank abhängt.
    for (const liste of this.nachFall.values()) {
      liste.sort((a, b) => a.variante.localeCompare(b.variante))
    }
  }

  /**
   * Der Satz für (slot, fall), mit eingesetzten Platzhaltern.
   *
   * `fall` darf null sein — dann gibt es für diese Sitzung keinen passenden
   * Fall (etwa: kein Abstieg stattgefunden), und die Stelle bleibt leer.
   */
  waehle(
    slot: string,
    fall: string | null,
    streuung: string,
    werte: Readonly<Record<string, string | number>> = {},
  ): string | null {
    if (!fall) return null
    const liste = this.nachFall.get(`${slot}${TRENNER}${fall}`)
    if (!liste || liste.length === 0) return null

    // Die Streuung enthält den Slot: sonst zöge dieselbe Sitzung in JEDEM Slot
    // die Variante 'a' und die Abwechslung wäre wieder weg.
    const b = liste[streuwert(`${streuung}${TRENNER}${slot}`) % liste.length]
    return setzePlatzhalter(b.text, werte)
  }

  /** Für Tests und Diagnose: gibt es zu (slot, fall) überhaupt etwas? */
  hat(slot: string, fall: string | null): boolean {
    if (!fall) return false
    return (this.nachFall.get(`${slot}${TRENNER}${fall}`)?.length ?? 0) > 0
  }
}

/**
 * Ersetzt {name}-Platzhalter.
 *
 * Ein Platzhalter ohne Wert bleibt UNERSETZT stehen und fällt damit im Review
 * auf, statt still zu einem leeren String zu werden. Ein Satz wie „Dort trugen
 * von geprüften Bereichen." wäre schlimmer als einer mit sichtbarer Lücke.
 */
export function setzePlatzhalter(
  text: string,
  werte: Readonly<Record<string, string | number>>,
): string {
  return text.replace(/\{(\w+)\}/g, (treffer, name: string) =>
    name in werte ? String(werte[name]) : treffer,
  )
}
