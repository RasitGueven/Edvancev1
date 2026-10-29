// PostgREST liefert hoechstens 1000 Zeilen je Abfrage (max-rows). Listen, die darueber wachsen koennen
// (tasks, pruef_admin_liste), laden deshalb in 1000er-Bloecken, bis ein Block kleiner ist. Die Abfrage
// braucht eine feste Sortierung, sonst verrutschen Zeilen zwischen den Bloecken.

export const SEITE = 1000

type Block<T> = { data: T[] | null; error: { message: string; code?: string; hint?: string | null } | null }

/** Ruft seite(von, bis) so lange auf, bis ein Block kleiner als SEITE ist; der erste Fehler bricht ab. */
export async function alleSeiten<T>(
  seite: (von: number, bis: number) => PromiseLike<Block<T>>,
): Promise<Block<T>> {
  const alle: T[] = []
  for (let von = 0; ; von += SEITE) {
    const { data, error } = await seite(von, von + SEITE - 1)
    if (error) return { data: null, error }
    const block = data ?? []
    alle.push(...block)
    if (block.length < SEITE) return { data: alle, error: null }
  }
}
