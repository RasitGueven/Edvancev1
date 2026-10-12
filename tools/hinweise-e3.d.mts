// Typen fuer das E3-Werkzeug (pruefen, vorschau, migration, fixture); der Test importiert es.

import type { Eintrag } from './hinweise-e3-lib.mjs'

export interface Quelle { skill: string; aufgaben: Record<string, Eintrag> }
export function ladeQuellen(skills: string[]): Promise<Quelle[]>
export function pruefen(quellen: Quelle[]): { fehler: string[]; liste: { t: unknown; e: Eintrag; skill: string }[] }
