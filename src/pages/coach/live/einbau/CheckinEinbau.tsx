/**
 * Reihe 1 C0b (Konzept §9): Einbaupunkt im Check-in je Kind. Hier haengt Auftrag D die
 * Kachel „Zuhause geübt“ ein (eine Zeile in BEITRAEGE). Ohne Beitrag zeigt er nichts.
 */
export type CheckinEinbauProps = { kindId: string; sessionId: string }

type Beitrag = (p: CheckinEinbauProps) => JSX.Element | null

export const CHECKIN_BEITRAEGE: Beitrag[] = []

export function CheckinEinbau(props: CheckinEinbauProps): JSX.Element | null {
  if (CHECKIN_BEITRAEGE.length === 0) return null
  return (
    <div data-testid="einbau-checkin" className="col-span-full flex flex-col gap-2 @min-[1000px]:col-start-2">
      {CHECKIN_BEITRAEGE.map((B, i) => <B key={i} {...props} />)}
    </div>
  )
}
