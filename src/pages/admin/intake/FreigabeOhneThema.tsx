import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'

type FreigabeOhneThemaProps = {
  busy: boolean
  freigebenLoading: boolean
  onSave: () => void
  onFreigeben: () => void
}

// Fussbereich, wenn kein aktuelles Thema gewaehlt ist: inline statt Modal
// (CLAUDE.md §11). Primaer geht es zurueck zur Themensuche, die Freigabe
// ohne Thema ist bewusst nachrangig.
export function FreigabeOhneThema({
  busy,
  freigebenLoading,
  onSave,
  onFreigeben,
}: FreigabeOhneThemaProps): JSX.Element {
  const { t } = useTranslation('admin')

  const zurSuche = (): void => {
    const feld = document.getElementById('thema-suche')
    feld?.scrollIntoView({ behavior: 'smooth', block: 'center' })
    feld?.focus()
  }

  return (
    <div className="flex flex-col gap-4 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-subtle)] p-4">
      <p className="text-sm text-[var(--color-text-secondary)]" role="status">
        {t('intake.freigabe.ohneThemaHinweis')}
      </p>
      <div className="flex flex-wrap items-center justify-end gap-2">
        <Button variant="outline" onClick={onSave} disabled={busy || freigebenLoading}>
          {busy ? t('intake.wizard.saving') : t('intake.wizard.save')}
        </Button>
        <Button variant="outline" onClick={onFreigeben} disabled={busy || freigebenLoading}>
          {freigebenLoading ? t('intake.wizard.freigebend') : t('intake.freigabe.ohneThema')}
        </Button>
        <Button onClick={zurSuche} disabled={busy || freigebenLoading}>
          {t('intake.freigabe.themaWaehlen')}
        </Button>
      </div>
    </div>
  )
}
