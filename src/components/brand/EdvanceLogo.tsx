import type { CSSProperties } from 'react'

// SVG viewBox 0 0 100 100 — alle Paths im Design-Handoff festgelegt.
const PATHS = {
  spine: 'M 8,36 C 12,52 28,60 34,58 C 52,54 70,14 90,8',
  arrow: 'M 83,14 L 90,8 L 81,7',
  calligraphic:
    'M 8,36 C 12,53.5 28,61.5 34.5,60 C 52.5,55.5 70.5,14.5 90,8 C 70,13.5 51.5,52.5 33.5,56.5 C 27.5,59 11.5,50.5 8,36 Z',
};

const COLORS = {
  midnight: 'var(--color-primary)',
  white: 'var(--color-bg-app)',
  black: 'var(--color-text-primary)',
  gold: 'var(--color-accent)',
};

interface EdvanceSymbolProps {
  size?: number;
  color?: string;
  accentColor?: string;
  filled?: boolean;
  className?: string;
  style?: CSSProperties;
}

export function EdvanceSymbol({
  size = 32,
  color = COLORS.midnight,
  accentColor = COLORS.gold,
  filled = false,
  className,
  style,
}: EdvanceSymbolProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 100 100"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-label="edvance Symbol"
      role="img"
      className={className}
      style={style}
    >
      {filled ? (
        <path d={PATHS.calligraphic} fill={color} />
      ) : (
        <>
          <path
            d={PATHS.spine}
            stroke={color}
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <circle cx="8" cy="36" r="3.5" fill={color} />
          <path
            d={PATHS.arrow}
            stroke={accentColor}
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </>
      )}
    </svg>
  );
}

interface EdvanceLogoProps {
  size?: number;
  color?: string;
  accentColor?: string;
  symbolRight?: boolean;
  className?: string;
  style?: CSSProperties;
}

export function EdvanceLogo({
  size = 20,
  color = COLORS.midnight,
  accentColor = COLORS.gold,
  symbolRight = false,
  className,
  style,
}: EdvanceLogoProps) {
  const symSize = Math.round(size * 1.8);
  const gap = Math.round(size * 0.55);

  const symbol = (
    <svg
      width={symSize}
      height={symSize}
      viewBox="0 0 100 100"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden="true"
      className="shrink-0"
    >
      <path
        d={PATHS.spine}
        stroke={color}
        strokeWidth="2.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <circle cx="8" cy="36" r="3.5" fill={color} />
      <path
        d={PATHS.arrow}
        stroke={accentColor}
        strokeWidth="2.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );

  const wordmark = (
    <span
      style={{
        fontFamily: "'Space Grotesk', sans-serif",
        fontWeight: 400,
        fontSize: size,
        letterSpacing: '0.045em',
        color,
        lineHeight: 1,
        userSelect: 'none',
      }}
    >
      edvance
    </span>
  );

  return (
    <div
      className={className}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap,
        flexDirection: symbolRight ? 'row-reverse' : 'row',
        ...style,
      }}
      aria-label="edvance"
      role="img"
    >
      {symbol}
      {wordmark}
    </div>
  );
}

interface EdvanceAppIconProps {
  size?: number;
  background?: string;
  symbolColor?: string;
  accentColor?: string;
  borderRadius?: number;
  filled?: boolean;
  className?: string;
  style?: CSSProperties;
}

export function EdvanceAppIcon({
  size = 48,
  background = COLORS.midnight,
  symbolColor = COLORS.white,
  accentColor = COLORS.gold,
  borderRadius,
  filled = false,
  className,
  style,
}: EdvanceAppIconProps) {
  const radius = borderRadius ?? Math.round(size * 0.22);
  const innerSize = Math.round(size * 0.52);

  return (
    <div
      className={className}
      style={{
        width: size,
        height: size,
        borderRadius: radius,
        background,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexShrink: 0,
        ...style,
      }}
      aria-label="edvance"
      role="img"
    >
      <svg
        width={innerSize}
        height={innerSize}
        viewBox="0 0 100 100"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        aria-hidden="true"
      >
        {filled ? (
          <path d={PATHS.calligraphic} fill={symbolColor} />
        ) : (
          <>
            <path
              d={PATHS.spine}
              stroke={symbolColor}
              strokeWidth="2.8"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
            <circle cx="8" cy="36" r="3.8" fill={symbolColor} />
            <path
              d={PATHS.arrow}
              stroke={accentColor}
              strokeWidth="2.8"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </>
        )}
      </svg>
    </div>
  );
}

export default EdvanceLogo;
