// "Wie das Kind es sieht." Live, neben dem Editor — und vom SERVER gebaut.
//
// Diese Komponente baut kein Payload. Sie holt eins (task_preview_payload →
// lsa_question_payload) und gibt es an PreviewStage weiter. Vorher stand hier ein
// Nachbau aus dem FormState: er zeigte, was der EDITOR denkt, nicht was das Kind
// sieht, und divergierte still — die Aufgaben-Tabelle aus F01 kam serverseitig
// laengst an und ist in dieser Vorschau nie aufgetaucht.
//
// ZWEI STAENDE, EIN KENNZEICHEN:
//   gespeichert    → RPC ohne Draft. Das ist, was das Kind heute bekaeme.
//   ungespeichert  → RPC MIT Draft (dem Objekt, das ein Speichern schreiben wuerde).
//                    Der Server spielt ihn ein, baut, rollt zurueck. Auch dieser
//                    Payload kommt also aus lsa_question_payload — nur eben aus
//                    einem Zustand, den die DB nie behalten hat.
//   Der Unterschied wird ANGEZEIGT, nicht verschwiegen: niemand soll einen Entwurf
//   fuer den echten Payload halten.

import { useEffect, useMemo, useRef, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { AlertTriangle, Eye, PencilLine } from 'lucide-react'
import { EdvanceCard, LoadingPulse } from '@/components/edvance'
import { getTaskPreview, PREVIEW_RPC_MISSING } from '@/lib/supabase/taskPreview'
import type { AuthoringTaskPatch, PreviewPayload } from '@/types'
import { PreviewStage } from './PreviewStage'

/** Ein Tastendruck ist kein Roundtrip. Lang genug fuer einen Tippfluss, kurz genug,
 *  dass es sich wie live anfuehlt. */
const DEBOUNCE_MS = 400

type Props = {
  taskId: string
  /** Was ein Speichern schreiben WUERDE (toPatch(state)) — nur relevant, wenn dirty. */
  draft: AuthoringTaskPatch
  dirty: boolean
}

export function AuthoringPreview({ taskId, draft, dirty }: Props): JSX.Element {
  const { t } = useTranslation('authoring')

  const [payload, setPayload] = useState<PreviewPayload | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(true)

  // Der Draft ist bei jedem Tastendruck ein neues Objekt — als Effect-Dependency
  // waere er nutzlos. Der serialisierte Stand ist der ehrliche Schluessel: er
  // aendert sich genau dann, wenn sich der Payload aendern KANN. (Es ist ausserdem
  // exakt das, was ueber die Leitung geht.)
  const draftKey = useMemo(() => JSON.stringify(draft), [draft])

  // Antworten koennen ueberholen: Tippt der Pfleger weiter, waehrend eine Anfrage
  // laeuft, darf die aeltere die neuere nicht ueberschreiben.
  const seq = useRef(0)

  useEffect(() => {
    const mine = ++seq.current
    setPending(true)

    const timer = setTimeout(() => {
      void (async () => {
        const body = dirty ? (JSON.parse(draftKey) as AuthoringTaskPatch) : null
        const { data, error: err } = await getTaskPreview(taskId, body)
        if (mine !== seq.current) return
        setPending(false)
        if (err) {
          setError(err)
          return
        }
        setError(null)
        setPayload(data)
      })()
    }, DEBOUNCE_MS)

    return () => clearTimeout(timer)
  }, [taskId, dirty, draftKey])

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <div className="flex flex-col gap-2">
        <div className="flex items-center justify-between gap-2">
          <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('sections.preview')}
          </h3>
          <StateBadge dirty={dirty} pending={pending} />
        </div>
        <span className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
          {dirty ? t('preview.unsavedHint') : t('preview.hint')}
        </span>
      </div>

      {error ? (
        <PreviewError message={error} />
      ) : payload ? (
        // Waehrend eine Aktualisierung laeuft, bleibt der letzte Payload stehen und
        // dimmt nur ab. Ein Skeleton bei jedem Tastendruck waere Flackern, kein Feedback.
        <div className={pending ? 'opacity-60 transition-opacity' : 'transition-opacity'}>
          <PreviewStage payload={payload} />
        </div>
      ) : (
        <LoadingPulse type="list" lines={4} />
      )}
    </EdvanceCard>
  )
}

/** Der Stand, den die Vorschau gerade zeigt. Ein Entwurf darf nie wie der echte
 *  Payload aussehen — deshalb traegt er ein sichtbares Etikett, kein Icon allein. */
function StateBadge({ dirty, pending }: { dirty: boolean; pending: boolean }): JSX.Element {
  const { t } = useTranslation('authoring')

  if (dirty) {
    return (
      <span className="inline-flex items-center gap-1.5 rounded-[var(--radius-full)] bg-[var(--color-gold-warning-light)] px-3 py-1 text-xs font-semibold text-[var(--color-gold-warning)]">
        <PencilLine className="h-3.5 w-3.5" aria-hidden="true" />
        {pending ? t('preview.updating') : t('preview.unsaved')}
      </span>
    )
  }

  return (
    <span className="inline-flex items-center gap-1.5 rounded-[var(--radius-full)] bg-[var(--color-bg-app)] px-3 py-1 text-xs font-semibold text-[var(--color-text-tertiary)]">
      <Eye className="h-3.5 w-3.5" aria-hidden="true" />
      {pending ? t('preview.updating') : t('preview.saved')}
    </span>
  )
}

/**
 * Fehlt die RPC, gibt es KEINE Vorschau — und keinen Notnagel. Ein Client-seitiger
 * Nachbau waere genau die zweite Wahrheit, die A02 abschafft: er saehe richtig aus
 * und waere es nicht.
 */
function PreviewError({ message }: { message: string }): JSX.Element {
  const { t } = useTranslation('authoring')
  const missing = message === PREVIEW_RPC_MISSING

  return (
    <div className="flex items-start gap-3 rounded-[var(--radius-md)] bg-[var(--color-bg-app)] p-4">
      <AlertTriangle
        className="mt-0.5 h-4 w-4 shrink-0 text-[var(--color-gold-warning)]"
        aria-hidden="true"
      />
      <div className="flex flex-col gap-1">
        <span className="text-sm font-semibold text-[var(--color-text-primary)]">
          {missing ? t('preview.rpcMissing') : t('preview.failed')}
        </span>
        <span className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
          {missing ? t('preview.rpcMissingHint') : message}
        </span>
      </div>
    </div>
  )
}
