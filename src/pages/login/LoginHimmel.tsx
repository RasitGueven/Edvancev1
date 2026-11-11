import { STERNE } from './sterne'

/**
 * Nachthimmel des Logins (CI-1 Teil A): rund 70 feste Sterne in drei Größen,
 * nur die großen leuchten und schimmern sehr langsam (marke.css). Ohne Text,
 * rein dekorativ.
 */
export function LoginSterne(): JSX.Element {
  return (
    <svg
      aria-hidden="true"
      className="pointer-events-none absolute inset-0 h-full w-full"
      viewBox="0 0 1440 900"
      preserveAspectRatio="xMidYMid slice"
    >
      <defs>
        <radialGradient id="login-stern-schein">
          <stop offset="0" stopColor="var(--color-marke-ivory)" stopOpacity="0.5" />
          <stop offset="1" stopColor="var(--color-marke-ivory)" stopOpacity="0" />
        </radialGradient>
      </defs>
      {STERNE.map(([x, y, d], i) =>
        d >= 4 ? (
          <g key={i} className="marke-schimmer">
            <circle cx={x} cy={y} r={d * 2.2} fill="url(#login-stern-schein)" />
            <circle cx={x} cy={y} r={d / 2} fill="var(--color-marke-ivory)" />
          </g>
        ) : (
          <circle key={i} cx={x} cy={y} r={d / 2} fill="var(--color-marke-ivory)" fillOpacity={d > 2 ? 0.7 : 0.45} />
        ),
      )}
    </svg>
  )
}

/**
 * Horizont aus der Schale des Logos: ein sehr großer, leicht geneigter
 * Kreisbogen mit feinem Amber-Lichtsaum, darüber links der Mitte der
 * Amber-Lichtpunkt — die Lichtquelle der Ansicht.
 */
export function LoginHorizont({ className = '' }: { className?: string }): JSX.Element {
  return (
    <svg
      aria-hidden="true"
      className={`pointer-events-none ${className}`}
      viewBox="0 0 1440 420"
      preserveAspectRatio="xMidYMin slice"
    >
      <defs>
        <linearGradient id="login-erde" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="var(--color-marke-navy)" />
          <stop offset="0.35" stopColor="var(--color-marke-navy)" stopOpacity="0.96" />
          <stop offset="1" stopColor="var(--color-marke-navy)" />
        </linearGradient>
        <radialGradient id="login-licht-schein">
          <stop offset="0" stopColor="var(--color-marke-amber)" stopOpacity="0.55" />
          <stop offset="0.45" stopColor="var(--color-marke-amber)" stopOpacity="0.16" />
          <stop offset="1" stopColor="var(--color-marke-amber)" stopOpacity="0" />
        </radialGradient>
        <filter id="login-saum-weich" x="-10%" y="-10%" width="120%" height="120%">
          <feGaussianBlur stdDeviation="7" />
        </filter>
      </defs>

      <g transform="rotate(-5 720 240)">
        <circle cx="720" cy="2140" r="1900" fill="url(#login-erde)" />
        <circle
          cx="720"
          cy="2140"
          r="1900"
          fill="none"
          stroke="var(--color-marke-amber)"
          strokeOpacity="0.5"
          strokeWidth="16"
          filter="url(#login-saum-weich)"
        />
        <circle cx="720" cy="2140" r="1900" fill="none" stroke="var(--color-marke-amber)" strokeOpacity="0.85" strokeWidth="1.5" />
      </g>

      <circle cx="580" cy="214" r="96" fill="url(#login-licht-schein)" />
      <circle cx="580" cy="214" r="9" fill="var(--color-marke-amber)" />
    </svg>
  )
}
