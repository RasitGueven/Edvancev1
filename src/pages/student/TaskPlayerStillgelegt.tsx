import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EmptyState } from '@/components/edvance'
import { Button } from '@/components/ui/button'

/**
 * Ersatz fuer den stillgelegten Web-TaskPlayer (/student/task/:taskId,
 * Bauauftrag Session-Rahmen P1, Entscheidung 24). Aufgaben laufen nur noch in
 * der Session am Tablet. Der alte Player bleibt als Code liegen, ist aber
 * nicht mehr erreichbar.
 */
export function TaskPlayerStillgelegt(): JSX.Element {
  const { t } = useTranslation('student')
  return (
    <div className="flex min-h-screen items-center justify-center bg-[var(--color-bg-app)] p-6">
      <EmptyState
        icon="📘"
        title={t('taskPlayerStillgelegt.title')}
        description={t('taskPlayerStillgelegt.body')}
        action={
          <Button asChild size="lg" className="rounded-xl">
            <Link to="/student">{t('taskPlayerStillgelegt.back')}</Link>
          </Button>
        }
      />
    </div>
  )
}
