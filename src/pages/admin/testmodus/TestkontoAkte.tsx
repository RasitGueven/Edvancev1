import { useEffect, useState } from 'react'
import { EdvanceCard } from '@/components/edvance'
import { getStudentIstTest } from '@/lib/supabase/testmodus'
import { TestkontoHaken } from './TestkontoHaken'

type TestkontoAkteProps = {
  studentId: string
  istAdmin: boolean
  onFehler: (text: string) => void
}

/** Haken "Testkonto" in der Akte (Entscheidung 27). Nur fuer Admins. */
export function TestkontoAkte({ studentId, istAdmin, onFehler }: TestkontoAkteProps): JSX.Element | null {
  const [wert, setWert] = useState<boolean | null>(null)

  useEffect(() => {
    if (!istAdmin) return
    let aktiv = true
    void getStudentIstTest(studentId).then(({ data, error }) => {
      if (!aktiv) return
      if (error) onFehler(error)
      else setWert(data === true)
    })
    return () => {
      aktiv = false
    }
  }, [studentId, istAdmin, onFehler])

  if (!istAdmin || wert === null) return null
  return (
    <EdvanceCard className="p-6">
      <TestkontoHaken art="student" id={studentId} wert={wert} istAdmin={istAdmin} onGeaendert={setWert} onFehler={onFehler} />
    </EdvanceCard>
  )
}
