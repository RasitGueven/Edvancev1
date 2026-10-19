/**
 * Das Kurven-Logo aus dem Dummy V7: navy Linie mit Startpunkt, goldene
 * Pfeilspitze. Zwei Zeichnungen wie dort — klein im Kopf, groß im Intro.
 * Farben über Klassen (rahmen.css), nie als Attribut.
 */
export function Logo({ gross = false }: { gross?: boolean }): JSX.Element {
  if (gross) {
    return (
      <svg className="tp-logo" viewBox="0 0 110 110" aria-hidden="true" focusable="false">
        <path className="tp-logo-linie tp-logo-dick" d="M15 51 C35 81 48 72 63 51 S85 22 94 19" />
        <path className="tp-logo-pfeil tp-logo-dick" d="M82 19 L94 19 L90 31" />
        <circle className="tp-logo-punkt" cx="15" cy="51" r="4" />
      </svg>
    )
  }
  return (
    <svg className="tp-logo" viewBox="0 0 40 40" aria-hidden="true" focusable="false">
      <path className="tp-logo-linie" d="M5 20 Q16 35 25 20 L35 7" />
      <path className="tp-logo-pfeil" d="M29 7 L35 7 L33 13" />
      <circle className="tp-logo-punkt" cx="5" cy="20" r="2.4" />
    </svg>
  )
}
