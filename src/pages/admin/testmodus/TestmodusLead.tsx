import { TestkontoHaken } from './TestkontoHaken'
import { TestlaufSchalter } from './TestlaufSchalter'

type TestmodusLeadProps = {
  leadId: string
  istAdmin: boolean
  istTest: boolean
  onIstTest: (wert: boolean) => void
  testlauf: boolean
  onTestlauf: (wert: boolean) => void
  onFehler: (text: string) => void
}

/**
 * Testmodus im Erstgespraech (Entscheidung 27): Haken "Testkonto" am Lead und,
 * fuer Test-Leads, der Schalter "Testlauf" fuer die LSA-Freigabe. Beides nur
 * fuer Admins.
 */
export function TestmodusLead({
  leadId,
  istAdmin,
  istTest,
  onIstTest,
  testlauf,
  onTestlauf,
  onFehler,
}: TestmodusLeadProps): JSX.Element | null {
  if (!istAdmin) return null
  return (
    <div className="flex flex-col gap-2">
      <TestkontoHaken
        art="lead"
        id={leadId}
        wert={istTest}
        istAdmin={istAdmin}
        onGeaendert={(wert) => {
          onIstTest(wert)
          if (!wert) onTestlauf(false)
        }}
        onFehler={onFehler}
      />
      <TestlaufSchalter istAdmin={istAdmin} istTest={istTest} wert={testlauf} onChange={onTestlauf} />
    </div>
  )
}
