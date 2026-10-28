import type { VideoBeat } from '../zeitplan'

/** Gemeinsame Props aller Bausteine (Anforderung Studio §6): Parameter aus dem Skelett, Bild aus der Welt. */
export type BausteinProps = { beat: VideoBeat; ruhig: boolean }

export const text = (p: Record<string, unknown>, k: string): string | undefined => (typeof p[k] === 'string' ? (p[k] as string) : undefined)
export const zahl = (p: Record<string, unknown>, k: string, d: number): number => (typeof p[k] === 'number' ? (p[k] as number) : d)
export const liste = <T,>(p: Record<string, unknown>, k: string): T[] => (Array.isArray(p[k]) ? (p[k] as T[]) : [])
