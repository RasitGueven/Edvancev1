/**
 * Reihe 1 C0b (Konzept §9): Einbaupunkt im Kind-Detail an der Aufgabe. Hier haengt Auftrag A
 * den Melde-Knopf „Aufgabe stimmt nicht“ ein (eine Zeile in BEITRAEGE). Ohne Beitrag zeigt er nichts.
 */
export type AufgabeEinbauProps = { kindId: string; sessionId: string; taskId: string }

type Beitrag = (p: AufgabeEinbauProps) => JSX.Element | null

export const AUFGABE_BEITRAEGE: Beitrag[] = []

export function AufgabeEinbau(props: AufgabeEinbauProps): JSX.Element | null {
  if (AUFGABE_BEITRAEGE.length === 0) return null
  return (
    <div data-testid="einbau-aufgabe" className="flex flex-wrap items-center gap-2">
      {AUFGABE_BEITRAEGE.map((B, i) => <B key={i} {...props} />)}
    </div>
  )
}
