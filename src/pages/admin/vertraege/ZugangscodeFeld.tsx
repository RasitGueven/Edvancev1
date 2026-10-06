import { useState } from 'react'
import { Eye, EyeOff } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { maskIban } from '@/lib/vertrag/iban'

type ZugangscodeFeldProps = {
  code: string | null
}

/**
 * Der Zugangscode, maskiert wie die IBAN (Entscheidung 25): dieselbe
 * Maskierung `maskIban` — erste zwei Zeichen, Sterne, letzte vier. Voll
 * sichtbar nur auf Klick, und nur in diesem Zustand; beim Zuklappen ist er
 * wieder verborgen. Lesen darf den Code ohnehin nur ein Admin (RLS auf
 * vertraege).
 */
export function ZugangscodeFeld({ code }: ZugangscodeFeldProps): JSX.Element {
  const { t } = useTranslation('vertraege')
  const [offen, setOffen] = useState(false)

  if (!code) {
    return <p className="font-mono text-3xl font-bold tracking-widest text-[var(--color-text-primary)]">—</p>
  }

  return (
    <div className="flex flex-col gap-2">
      <p
        className="font-mono text-3xl font-bold tracking-widest text-[var(--color-text-primary)]"
        data-testid="zugangscode-wert"
      >
        {offen ? code : maskIban(code)}
      </p>
      <Button
        variant="outline"
        className="min-h-11 self-start"
        onClick={() => setOffen((o) => !o)}
        aria-pressed={offen}
      >
        {offen ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
        {offen ? t('code.verbergen') : t('code.anzeigen')}
      </Button>
    </div>
  )
}
