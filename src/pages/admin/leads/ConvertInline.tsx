import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { provisionStudent } from '@/lib/supabase/provision'
import type { Lead } from '@/types'

type ConvertInlineProps = {
  lead: Lead
  onDone: () => void
  onCancel: () => void
  onError: (message: string) => void
}

/**
 * Konversion eines Leads in einen echten Schueler — irreversibel, deshalb mit
 * Passwortabfrage. Inline statt Modal, mit dem Namen des Leads. Unveraenderter
 * Weg: provisionStudent (Edge Function).
 */
export function ConvertInline({ lead, onDone, onCancel, onError }: ConvertInlineProps): JSX.Element {
  const { t } = useTranslation('leads')
  const { t: tc } = useTranslation('common')
  const [pw, setPw] = useState('')
  const [converting, setConverting] = useState(false)

  const convert = async (): Promise<void> => {
    setConverting(true)
    const { error } = await provisionStudent({
      lead_id: lead.id,
      full_name: lead.full_name,
      parent_email: lead.contact_email,
      class_level: lead.class_level,
      school_type: lead.school_type,
      school_name: lead.school_name,
      subjects: lead.subjects,
      student_password: pw,
    })
    setConverting(false)
    if (error) {
      onError(error)
      return
    }
    onDone()
  }

  return (
    <EdvanceCard className="flex flex-col gap-2 p-4">
      <Label htmlFor="convert-pw">{t('convert.passwordLabel', { name: lead.full_name })}</Label>
      <div className="flex flex-wrap items-center gap-2">
        <Input
          id="convert-pw"
          type="text"
          autoComplete="off"
          className="max-w-xs"
          value={pw}
          onChange={(e) => setPw(e.target.value)}
        />
        <Button size="sm" disabled={converting || pw.length < 6} onClick={() => void convert()}>
          {converting ? t('convert.converting') : t('convert.confirm')}
        </Button>
        <Button size="sm" variant="outline" disabled={converting} onClick={onCancel}>
          {tc('cancel')}
        </Button>
      </div>
    </EdvanceCard>
  )
}
