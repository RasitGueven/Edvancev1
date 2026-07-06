import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { ArrowLeft } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { HintsEditor } from '@/components/edvance/screening/editor/HintsEditor'
import { MetadatenEditor } from '@/components/edvance/screening/editor/MetadatenEditor'
import { TeilaufgabenEditor } from '@/components/edvance/screening/editor/TeilaufgabenEditor'
import { LivePreview } from '@/components/edvance/screening/editor/LivePreview'
import {
  Banner,
  Field,
  JSON_TEXT,
  SaveBar,
  Section,
  SELECT,
  TEXTAREA,
  UsageToggle,
} from '@/components/edvance/screening/editor/ScreeningEditorPrimitives'
import {
  buildInput,
  CHECK_TYPES,
  emptyState,
  fromItem,
  INPUT_TYPES,
  parsePayloadCanonical,
  validate,
  type FormState,
} from '@/components/edvance/screening/editor/state'
import {
  createScreeningItem,
  getScreeningItem,
  setScreeningItemActive,
  updateScreeningItem,
} from '@/lib/supabase/screeningItems'
import type {
  ScreeningCheckType,
  ScreeningItem,
} from '@/types'

export function ScreeningItemEditorPage(): JSX.Element {
  const { t } = useTranslation('screening-editor')
  const { id } = useParams<{ id: string }>()
  const [params] = useSearchParams()
  const navigate = useNavigate()
  const clusterIdParam = params.get('clusterId') ?? ''
  const isNew = !id || id === 'new'

  const [state, setState] = useState<FormState>(emptyState)
  const [loaded, setLoaded] = useState<ScreeningItem | null>(null)
  const [loading, setLoading] = useState(!isNew)
  const [dirty, setDirty] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [active, setActive] = useState(false)

  useEffect(() => {
    if (isNew) return
    setLoading(true)
    getScreeningItem(id!).then(({ data, error: err }) => {
      if (err || !data) {
        setError(err ?? t('loadError'))
        setLoading(false)
        return
      }
      setLoaded(data)
      setState(fromItem(data))
      setActive(data.active)
      setLoading(false)
    })
  }, [id, isNew, t])

  const set = <K extends keyof FormState>(k: K, v: FormState[K]): void => {
    setState((s) => ({ ...s, [k]: v }))
    setDirty(true)
  }

  const toggleActive = async (): Promise<void> => {
    if (!loaded) return
    const next = !active
    setActive(next)
    await setScreeningItemActive(loaded.id, next)
  }

  const save = async (): Promise<void> => {
    setError(null)
    const vErr = validate(state)
    if (vErr) {
      setError(t(`validation.${vErr}`))
      return
    }
    const parsed = parsePayloadCanonical(state)
    if ('error' in parsed) {
      setError('payload oder canonical ist kein gültiges JSON.')
      return
    }
    const cid = loaded ? loaded.cluster_id : clusterIdParam
    if (!cid) {
      setError(t('validation.clusterMissing'))
      return
    }
    setBusy(true)
    const input = buildInput(state, cid, parsed.payload, parsed.canonical)
    const { data, error: err } = loaded
      ? await updateScreeningItem(loaded.id, input)
      : await createScreeningItem(input)
    setBusy(false)
    if (err) {
      setError(t('validation.saveFailed', { error: err }))
      return
    }
    setDirty(false)
    if (!loaded && data) {
      navigate(`/admin/screening-items/${data.id}/edit`, { replace: true })
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-background">
        <EdvanceNavbar subtitle={t('page.subtitle')} sticky />
        <main className="mx-auto max-w-5xl px-4 py-8">
          <LoadingPulse type="list" lines={6} />
        </main>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle={t('page.subtitle')} sticky />
      <main className="mx-auto max-w-5xl px-4 pb-32 pt-6">
        <Link
          to="/admin/screening-items"
          className="mb-2 inline-flex items-center gap-1 text-sm text-[var(--color-text-tertiary)]"
        >
          <ArrowLeft className="h-4 w-4" /> {t('page.backToList')}
        </Link>

        <header className="mb-6 flex flex-col gap-3">
          <div className="flex items-start gap-3">
            <Input
              className="flex-1 border-transparent bg-transparent text-xl font-bold focus-visible:border-[var(--color-border)] focus-visible:bg-[var(--color-bg-surface)]"
              value={state.skill_label}
              onChange={(e) => set('skill_label', e.target.value)}
              placeholder={
                isNew ? t('header.newPlaceholder') : t('page.titleEdit')
              }
            />
            {!isNew && (
              <Button
                size="sm"
                variant={active ? 'outline' : 'default'}
                onClick={toggleActive}
              >
                {active ? t('common:active', { defaultValue: 'Aktiv' }) : t('common:inactive', { defaultValue: 'Inaktiv' })}
              </Button>
            )}
          </div>

          <div className="flex flex-wrap items-center gap-3 text-xs text-[var(--color-text-tertiary)]">
            <UsageToggle
              value={state.usage}
              onChange={(v) => set('usage', v)}
            />
            {loaded && (
              <span>
                {t('header.idLabel')} <strong>{loaded.id.slice(0, 8)}</strong>
              </span>
            )}
            <span>·</span>
            <span>{t(`inputTypes.${state.input_type}`)}</span>
          </div>

          {state.input_type === 'COORDINATE' && state.usage !== 'lernpfad' && (
            <Banner variant="warning">⚠️ {t('usage.drawWarning')}</Banner>
          )}
          <Banner variant="info">ℹ️ {t('usage.notPersisted')}</Banner>
        </header>

        <div className="grid gap-6 lg:grid-cols-2">
          <div className="flex flex-col gap-4">
            <Section title={t('sections.aufgabenstellung')}>
              <Field label={`${t('fields.context')} (${t('common:optional', { defaultValue: 'optional' })})`}>
                <textarea
                  className={TEXTAREA}
                  value={state.kontext}
                  onChange={(e) => set('kontext', e.target.value)}
                />
              </Field>
              <Field label={t('fields.prompt')}>
                <textarea
                  className={TEXTAREA}
                  value={state.prompt}
                  onChange={(e) => set('prompt', e.target.value)}
                />
              </Field>
            </Section>

            <Section title={t('sections.aufgabentyp')}>
              <div className="flex flex-wrap gap-1.5">
                {INPUT_TYPES.map((tp) => (
                  <button
                    type="button"
                    key={tp}
                    onClick={() => set('input_type', tp)}
                    className={`rounded-full border px-3 py-1.5 text-xs font-semibold transition ${
                      state.input_type === tp
                        ? 'border-[var(--color-primary)] bg-[var(--color-primary)] text-white'
                        : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)]'
                    }`}
                  >
                    {t(`inputTypes.${tp}`)}
                  </button>
                ))}
              </div>
            </Section>

            <Section title={t('sections.antwortoptionen')}>
              <p className="mb-2 text-xs text-[var(--color-text-tertiary)]">
                v1: JSON-Edit. Visuelle Builder pro Typ folgen.
              </p>
              <Field label="payload (JSON)">
                <textarea
                  className={JSON_TEXT}
                  value={state.payloadStr}
                  onChange={(e) => set('payloadStr', e.target.value)}
                />
              </Field>
              <Field label="canonical (JSON)">
                <textarea
                  className={JSON_TEXT}
                  value={state.canonicalStr}
                  onChange={(e) => set('canonicalStr', e.target.value)}
                />
              </Field>
              <div className="grid grid-cols-2 gap-3">
                <Field label={t('fields.checkType')}>
                  <select
                    className={SELECT}
                    value={state.check_type}
                    onChange={(e) =>
                      set('check_type', e.target.value as ScreeningCheckType)
                    }
                  >
                    {CHECK_TYPES.map((c) => (
                      <option key={c} value={c}>
                        {c}
                      </option>
                    ))}
                  </select>
                </Field>
                <Field label={t('fields.tolerance')}>
                  <Input
                    value={state.tolerance}
                    onChange={(e) => set('tolerance', e.target.value)}
                  />
                </Field>
              </div>
            </Section>

            <Section title={t('sections.hinweise')}>
              <HintsEditor
                hint1={state.hint1}
                hint2={state.hint2}
                onChange={(which, v) => set(which, v)}
                showNotPersistedBanner
              />
            </Section>

            <Section title={t('sections.teilaufgaben')}>
              <TeilaufgabenEditor
                items={state.teilaufgaben}
                onChange={(items) => set('teilaufgaben', items)}
              />
            </Section>

            <Section title={t('sections.coach')}>
              <Field label={t('fields.explanation')}>
                <textarea
                  className={TEXTAREA}
                  value={state.explanation}
                  onChange={(e) => set('explanation', e.target.value)}
                />
              </Field>
              <Field
                label={`${t('fields.typicalErrors')} (${t('fields.typicalErrorsHint')})`}
              >
                <textarea
                  className={TEXTAREA}
                  value={state.typical}
                  onChange={(e) => set('typical', e.target.value)}
                />
              </Field>
            </Section>

            <MetadatenEditor state={state} set={set} />
          </div>

          <div className="sticky top-20 self-start">
            <LivePreview state={state} />
          </div>
        </div>
      </main>

      <SaveBar
        dirty={dirty}
        busy={busy}
        error={error}
        onSave={save}
        onDiscard={() => {
          if (loaded) setState(fromItem(loaded))
          else setState(emptyState())
          setDirty(false)
          setError(null)
        }}
      />
    </div>
  )
}
