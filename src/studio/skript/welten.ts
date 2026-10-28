/** Welten zum Start (Anforderung Studio §6). Weitere nur mit Skin für alle Bausteine. */
export const WELTEN = ['skelett', 'fussball', 'gaming', 'musik'] as const
export type StartWelt = (typeof WELTEN)[number]

export function istWelt(w: string): w is StartWelt {
  return (WELTEN as readonly string[]).includes(w)
}
