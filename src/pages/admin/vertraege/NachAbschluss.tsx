import { CheckCircle2, Mail, Printer } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { formatBerlinDateTime, formatDateOnly } from '@/lib/datetime'
import type { VertragNachweise } from '@/lib/supabase/vertraege'
import type { Vertrag, VertragDokument } from '@/types'

type NachAbschlussProps = {
  vertrag: Vertrag
  dokumente: VertragDokument[]
  nachweise: VertragNachweise
  saving: boolean
  onPrint: () => void
}

/**
 * Nach dem Abschluss: Bestaetigung per E-Mail (noch deaktiviert) und/oder
 * Ausdruck der unterschriebenen Unterlagen, darunter die Nachweise —
 * Haekchen mit Version und Zeitpunkt, Unterschriften, Versandprotokoll.
 */
export function NachAbschluss({
  vertrag,
  dokumente,
  nachweise,
  saving,
  onPrint,
}: NachAbschlussProps): JSX.Element {
  const { t, i18n } = useTranslation('vertraege')
  const lang = i18n.language
  const titel = (schluessel: string): string =>
    dokumente.find((d) => d.schluessel === schluessel)?.titel ?? schluessel

  return (
    <div className="flex flex-col gap-4">
      {vertrag.status === 'abgeschlossen' && (
        <EdvanceCard className="flex flex-col gap-4 p-6">
          <div className="flex items-center gap-2">
            <CheckCircle2 className="h-5 w-5 text-[var(--color-success)]" />
            <h2 className="text-base font-semibold text-[var(--color-text-primary)]">{t('after.title')}</h2>
          </div>
          <p className="text-sm text-[var(--color-text-secondary)]">{t('after.hint')}</p>
          <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
            <span title={t('ways.emailDisabled')}>
              <Button className="w-full" variant="outline" disabled>
                <Mail className="h-4 w-4" />
                {t('after.email')}
              </Button>
            </span>
            <Button className="w-full" disabled={saving} onClick={onPrint}>
              <Printer className="h-4 w-4" />
              {t('after.print')}
            </Button>
          </div>
        </EdvanceCard>
      )}

      <EdvanceCard className="flex flex-col gap-4 p-6">
        <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-muted)]">
          {t('proof.title')}
        </h2>
        <ul className="flex flex-col gap-2 text-sm text-[var(--color-text-secondary)]">
          {vertrag.abschluss_weg === 'papier' && vertrag.unterschrieben_am && (
            <li>{t('proof.paper', { date: formatDateOnly(vertrag.unterschrieben_am, lang) })}</li>
          )}
          {nachweise.unterschriften.map((u) => (
            <li key={u.art}>
              {t('proof.signed', {
                art: t(`art.${u.art}`),
                date: formatBerlinDateTime(u.unterschrieben_at, lang),
              })}
            </li>
          ))}
          {nachweise.zustimmungen.map((z) => (
            <li key={z.dokument_schluessel}>
              {t('proof.accepted', {
                titel: titel(z.dokument_schluessel),
                version: z.dokument_version,
                date: formatBerlinDateTime(z.akzeptiert_at, lang),
              })}
            </li>
          ))}
          {nachweise.versand.map((v) => (
            <li key={v.id}>
              {t('proof.sent', {
                weg: t(`weg.${v.weg}`),
                anlass: t(`anlass.${v.anlass}`),
                date: formatBerlinDateTime(v.erfolgt_at, lang),
              })}
            </li>
          ))}
          {nachweise.unterschriften.length === 0 &&
            nachweise.zustimmungen.length === 0 &&
            nachweise.versand.length === 0 &&
            vertrag.abschluss_weg !== 'papier' && <li>{t('proof.none')}</li>}
        </ul>
      </EdvanceCard>
    </div>
  )
}
