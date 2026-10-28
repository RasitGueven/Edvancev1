import { interpolate } from 'remotion'

/** Ruhige Einblendung 0 → 1 ab `startS` über `dauerS`; bei reduzierter Bewegung sofort 1. */
export function einblenden(frame: number, fps: number, startS: number, dauerS: number, ruhig: boolean): number {
  if (ruhig) return 1
  return interpolate(frame, [startS * fps, (startS + dauerS) * fps], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' })
}

/** Leichter Anstieg von unten (in px) passend zur Einblendung. */
export const anstieg = (wert: number, px = 24): string => `translateY(${Math.round((1 - wert) * px)}px)`
