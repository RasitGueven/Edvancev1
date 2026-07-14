// Der Payload, wie das Kind ihn bekommt — und wie die Vorschau ihn rendert.
//
// Diese Typen beschreiben KEINE Formularstruktur und keinen DB-Zeilenschnitt: sie
// beschreiben, was lsa_question_payload ausliefert (P01 §4, P02, F01). Deshalb ist
// die Loesung hier nicht "weggelassen" — sie ist in diesem Vertrag nie vorgekommen.
//
// Gebaut wird der Payload ausschliesslich serverseitig (RPC task_preview_payload →
// lsa_question_payload). Wer hier ein Feld vermisst, aendert den SERVER, nicht
// diese Datei — sonst rendert die Vorschau wieder etwas, das das Kind nie sieht.

/** Eine Abbildung. Der Alt-Text ist Teil des Vertrags — ein Bild ohne ihn ist ein Mangel. */
export type PreviewAsset = { url: string; alt?: string }

/** Die Aufgaben-Tabelle (F01). Zellen sind IMMER Strings — der Client rendert, er rechnet nicht. */
export type PreviewTable = { headers: string[]; rows: string[][] }

export type PreviewOption = { id: string; label: string }

/** Eine Teilaufgabe (P02) — ohne afb/competency: Diagnostik geht das Kind nichts an. */
export type PreviewPart = {
  nr: number
  kind: 'short_input' | 'mc'
  prompt?: string
  unit?: string
  table?: PreviewTable
  options?: PreviewOption[]
}

type PreviewBase = {
  task_id: string
  assets: PreviewAsset[]
  /** Fehlt ganz, wenn das Item keine Tabelle hat (jsonb_strip_nulls serverseitig). */
  table?: PreviewTable
}

/** Die drei Zweige von lsa_question_payload, unterschieden an `kind`. */
export type PreviewPayload =
  | (PreviewBase & { kind: 'multi_part'; stem: string; parts: PreviewPart[] })
  | (PreviewBase & { kind: 'mc'; prompt: string; options: PreviewOption[] })
  | (PreviewBase & { kind: 'short_input'; prompt: string; unit?: string })
