// Kindersicht der neuen Aufgabenformate (Sessionreihe 1, A3) — dieselbe Form wie in edvance-app
// (`src/components/aufgaben/formate/typen.ts`) und im DATENVERTRAG §13.1. Die Loesung kommt in diesem Vertrag nie vor.

export type FormatKey = 'feldmaske' | 'loesungsmenge' | 'graph_auswahl' | 'fehler_finden' | 'bausteine' | 'schritte_ordnen'

export type FormatBaustein = { id: string; text: string }

export type FormatSchablonenTeil = { text: string } | { feld: string; typ: 'zahl' | 'bruch' | 'vorzeichen'; leer_heisst_eins?: boolean }

export type FormatPayload =
  | { format: 'feldmaske'; schablone: FormatSchablonenTeil[] }
  | { format: 'loesungsmenge'; element: 'zahl' | 'bruch'; max_felder: number; variable: string }
  | { format: 'graph_auswahl'; optionen: { id: string; alt: string; bild?: string; bild_hell?: string }[] }
  | { format: 'fehler_finden'; zeilen: { nr: number; text: string }[]; warum: FormatBaustein[] }
  | { format: 'bausteine'; bausteine: FormatBaustein[]; anzahl: 1 | 2 }
  | { format: 'schritte_ordnen'; schritte: FormatBaustein[] }

/** Lösungsbeispiel einer Instanz der Rolle beispiel (aufgabe_payload). */
export type FormatLoesungsbeispiel = {
  aufgabe: string
  schritte: { text: string }[]
  warum: { bei_schritt: number; frage: string; bausteine: FormatBaustein[]; richtig: string } | null
}
