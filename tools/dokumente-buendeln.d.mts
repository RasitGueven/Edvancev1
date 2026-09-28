// Typen fuer das Buendel-Werkzeug. Das Werkzeug selbst bleibt .mjs, damit es
// ohne Bauschritt laeuft (node tools/dokumente-buendeln.mjs); der Test
// importiert es und braucht dafuer diese Beschreibung.

/** Pfad der erzeugten Datei, relativ zur Repo-Wurzel. */
export const ZIEL: string

/** Der Inhalt von texte.ts, erzeugt aus den Quellen unter `wurzel`. */
export function baueTexte(wurzel?: string): string
