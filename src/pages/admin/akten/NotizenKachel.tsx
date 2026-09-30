import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { EdvanceCard } from '@/components/edvance'
import { gesundheitsTreffer } from '@/lib/akte/board'
import { SELECT_MD } from '@/lib/formStyles'
import {
  notizAnlegen,
  notizAusblenden,
  notizEinblenden,
  notizGesundheitEntfernen,
  type NotizErgebnis,
} from '@/lib/supabase/akteNotizen'
import type { NotizKategorie, SchuelerNotiz, WortlisteEintrag } from '@/types'
import { NotizEintrag } from './NotizEintrag'

const KATEGORIEN: NotizKategorie[] = ['lernen', 'verhalten', 'organisatorisch']

/**
 * Notizen (Anforderung F): nur anhaengen. Das Feld prueft live gegen die
 * Wortliste "gesundheit" und sperrt Speichern bei einem Treffer; verbindlich
 * prueft notiz_anlegen in der Datenbank dasselbe noch einmal.
 */
export function NotizenKachel({
  studentId,
  notizen,
  wortliste,
  darfSchreiben,
  istAdmin,
  onGeaendert,
}: {
  studentId: string
  notizen: SchuelerNotiz[]
  wortliste: WortlisteEintrag[]
  darfSchreiben: boolean
  istAdmin: boolean
  onGeaendert: () => void
}): JSX.Element {
  const { t } = useTranslation('akte')
  const [kategorie, setKategorie] = useState<NotizKategorie | ''>('')
  const [text, setText] = useState('')
  const [busy, setBusy] = useState(false)
  const [fehler, setFehler] = useState<string | null>(null)

  const treffer = gesundheitsTreffer(text, wortliste)
  const gesperrt = busy || !kategorie || !text.trim() || treffer !== null

  const ausfuehren = async (aufruf: () => Promise<NotizErgebnis>, danach?: () => void): Promise<void> => {
    setBusy(true)
    setFehler(null)
    const r = await aufruf()
    setBusy(false)
    if (r.error) {
      setFehler(r.gesundheitsbegriff ? t('notizen.gesundheit', { wort: r.gesundheitsbegriff }) : r.error)
      return
    }
    danach?.()
    onGeaendert()
  }

  const speichern = (): void => {
    if (gesperrt || !kategorie) return
    void ausfuehren(
      () => notizAnlegen(studentId, kategorie, text.trim()),
      () => {
        setText('')
        setKategorie('')
      },
    )
  }

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('notizen.titel')}
      </h2>

      {darfSchreiben ? (
        <div className="flex flex-col gap-2">
          <div className="flex flex-col gap-2">
            <Label htmlFor="notiz-kategorie">{t('notizen.kategorie')}</Label>
            <select
              id="notiz-kategorie"
              className={SELECT_MD}
              value={kategorie}
              onChange={(e) => setKategorie(e.target.value as NotizKategorie | '')}
            >
              <option value="">{t('notizen.kategorieWaehlen')}</option>
              {KATEGORIEN.map((k) => (
                <option key={k} value={k}>
                  {t(`notizen.kategorien.${k}`)}
                </option>
              ))}
            </select>
          </div>
          <Label htmlFor="notiz-text">{t('notizen.feldLabel')}</Label>
          <textarea
            id="notiz-text"
            rows={3}
            className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-app)] p-3 text-sm"
            value={text}
            onChange={(e) => setText(e.target.value)}
          />
          {treffer && (
            <p role="alert" className="text-sm text-[var(--color-gold-warning)]">
              {t('notizen.gesundheit', { wort: treffer })}
            </p>
          )}
          <p className="text-xs text-[var(--color-text-tertiary)]">{t('notizen.hinweis')}</p>
          <div>
            <Button
              disabled={gesperrt}
              title={gesperrt && !busy ? t('notizen.speichernGesperrt') : undefined}
              onClick={speichern}
            >
              {busy ? t('notizen.speichert') : t('notizen.speichern')}
            </Button>
          </div>
        </div>
      ) : (
        <p className="text-xs text-[var(--color-text-tertiary)]">{t('notizen.nurAdminRuhend')}</p>
      )}

      {fehler && <p className="text-sm text-[var(--color-error-exam)]">{fehler}</p>}

      {notizen.length === 0 ? (
        <p className="text-sm text-[var(--color-text-secondary)]">{t('notizen.leer')}</p>
      ) : (
        <ul className="flex flex-col gap-4">
          {notizen.map((n) => (
            <NotizEintrag
              key={n.id}
              notiz={n}
              istAdmin={istAdmin}
              busy={busy}
              onAusblenden={(grund) => void ausfuehren(() => notizAusblenden(n.id, grund))}
              onEinblenden={() => void ausfuehren(() => notizEinblenden(n.id))}
              onEntfernen={() => void ausfuehren(() => notizGesundheitEntfernen(n.id))}
            />
          ))}
        </ul>
      )}
    </EdvanceCard>
  )
}
