/**
 * Horizont-Motiv aus der Logo-Schale, klein unten in der Admin-Leiste (CI-1
 * „Gestaltungstiefe“): flacher Bogen mit Amber-Lichtsaum und schwachem Schein.
 * Rein dekorativ, liegt hinter dem Fuß der Leiste.
 */
export function LeistenHorizont(): JSX.Element {
  return (
    <svg
      aria-hidden="true"
      className="pointer-events-none absolute inset-x-0 bottom-0 z-0 h-28 w-full"
      viewBox="0 0 256 112"
      preserveAspectRatio="xMidYMax slice"
    >
      <defs>
        <radialGradient id="leiste-schein" cx="0.35" cy="0.55" r="0.65">
          <stop offset="0" stopColor="var(--color-marke-amber)" stopOpacity="0.16" />
          <stop offset="1" stopColor="var(--color-marke-amber)" stopOpacity="0" />
        </radialGradient>
      </defs>
      <rect x="0" y="0" width="256" height="112" fill="url(#leiste-schein)" />
      <g transform="rotate(-6 128 70)">
        <circle cx="128" cy="470" r="400" fill="var(--color-marke-navy)" fillOpacity="0.55" />
        <circle cx="128" cy="470" r="400" fill="none" stroke="var(--color-marke-amber)" strokeOpacity="0.55" strokeWidth="1" />
      </g>
    </svg>
  )
}
