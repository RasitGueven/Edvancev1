import { useCallback, useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { KeyRound, Mail, Printer } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { AdminHeader, EdvanceBadge, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { Button } from '@/components/ui/button'
import { berlinToday, formatDateOnly } from '@/lib/datetime'
import { listTiers } from '@/lib/supabase/subscriptions'
import { getVertragNachweise, listVertragDokumente, type VertragNachweise } from '@/lib/supabase/vertraege'
import {
  listDokumentFassungen,
  listVertragDateien,
  vertragPdfErzeugen,
  type DokumentFassung,
  type VertragDatei,
} from '@/lib/supabase/vertragDateien'
import { mailSenden, type Versandanlass } from '@/lib/supabase/vertragMail'
import { listArchiv, type ArchivDatei } from '@/lib/supabase/vertragScan'
import {
  getVertragAktuell,
  listVertragHistorie,
  vertragFolgevertragStarten,
  vertragSonderkuendigungErfassen,
  vertragWiderrufErfassen,
  vertragZugangscodeNeu,
} from '@/lib/supabase/vertraegeMenue'
import { buendelVollstaendig, kind, vertragspartner } from '@/lib/vertrag/menue'
import type { TierPlan, VertragAktuell, VertragDokument } from '@/types'
import { AktionenKarte } from './vertraege/detail/AktionenKarte'
import { ArchivListe } from './vertraege/detail/ArchivListe'
import { Datenblock } from './vertraege/detail/Datenblock'
import { IbanFeld } from './vertraege/detail/IbanFeld'
import { KuendigungDialog } from './vertraege/detail/KuendigungDialog'
import { VertragHistorie } from './vertraege/detail/VertragHistorie'
import { EingabeDialog } from './vertraege/menue/EingabeDialog'
import { STATUS_FARBE, ZAHLUNG_FARBE } from './vertraege/menue/statusFarben'
import { formatEuro } from './vertraege/VertragForm'
import { openUnterlagen } from './vertraege/vertragUi'

type Daten = {
  vertrag: VertragAktuell | null
  nachweise: VertragNachweise | null
  dokumente: VertragDokument[]
  tiers: TierPlan[]
  historie: VertragAktuell[]
  archiv: ArchivDatei[]
  erzeugte: VertragDatei[]
  fassungen: DokumentFassung[]
}

const LEER: Daten = {
  vertrag: null, nachweise: null, dokumente: [], tiers: [], historie: [], archiv: [],
  erzeugte: [], fassungen: [],
}

/**
 * Die Vertragsdetailansicht (/admin/vertraege/:id/detail).
 *
 * Zweispaltig wie im Clickdummy: links Vertragspartner, Kind, Vertragsdaten und
 * die Historie, rechts der Zugangscode und das Archiv. Alles Angezeigte kommt
 * aus vertraege_aktuell und den RPCs — gerechnet wird hier nichts.
 */
export function VertragDetailPage(): JSX.Element {
  const { id = '' } = useParams<{ id: string }>()
  const { t, i18n } = useTranslation('vertraege')
  const lang = i18n.language
  const navigate = useNavigate()
  const [d, setD] = useState<Daten>(LEER)
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [widerruf, setWiderruf] = useState(false)
  const [kuendigung, setKuendigung] = useState(false)
  const [codeFrage, setCodeFrage] = useState(false)
  const [hinweis, setHinweis] = useState<string | null>(null)

  const laden = useCallback(async (): Promise<void> => {
    const [v, n, dok, ti, ar, ez, fa] = await Promise.all([
      getVertragAktuell(id),
      getVertragNachweise(id),
      listVertragDokumente(),
      listTiers(),
      listArchiv(id),
      listVertragDateien(id),
      listDokumentFassungen(),
    ])
    const hist = v.data?.student_id ? await listVertragHistorie(v.data.student_id) : null
    setD({
      vertrag: v.data ?? null,
      nachweise: n.data,
      dokumente: dok.data ?? [],
      tiers: ti.data ?? [],
      historie: hist?.data ?? (v.data ? [v.data] : []),
      archiv: ar.data ?? [],
      erzeugte: ez.data ?? [],
      fassungen: fa.data ?? [],
    })
    setError(
      v.error ?? n.error ?? dok.error ?? ti.error ?? ar.error ?? ez.error ?? fa.error ?? hist?.error ?? null,
    )
    setLoading(false)
  }, [id])

  useEffect(() => {
    void laden()
  }, [laden])

  const run = async (aktion: () => Promise<{ error: string | null }>): Promise<boolean> => {
    setBusy(true)
    setError(null)
    setHinweis(null)
    const { error: err } = await aktion()
    setBusy(false)
    if (err) setError(err)
    await laden()
    return err === null
  }

  const v = d.vertrag

  const buendelDa = buendelVollstaendig(d.erzeugte.map((e) => e.art))

  const versenden = async (anlass: Versandanlass): Promise<void> => {
    if (!v) return
    const ok = await run(() => mailSenden(v.id, anlass))
    if (ok) setHinweis(t('detailansicht.versandOk', { an: v.eltern_email ?? '' }))
  }

  if (loading || !v) {
    return (
      <div className="min-h-screen bg-[var(--color-bg-app)]">
        <EdvanceNavbar subtitle={t('page.subtitle')} sticky />
        <main className="mx-auto max-w-5xl px-4 py-8">
          {loading ? (
            <LoadingPulse type="card" />
          ) : (
            <p className="text-sm text-[var(--color-text-tertiary)]">{t('menue.nichtGefunden')}</p>
          )}
        </main>
      </div>
    )
  }

  const paket = d.tiers.find((x) => x.id === v.tier_id)?.name ?? '—'
  const datum = (ymd: string | null): string => (ymd ? formatDateOnly(ymd, lang) : '—')
  const widerrufMoeglich = v.wirksamer_status === 'im_widerruf'

  const folgevertrag = async (): Promise<void> => {
    setBusy(true)
    setError(null)
    const { data, error: err } = await vertragFolgevertragStarten(v.id)
    setBusy(false)
    if (err || !data) {
      setError(err ?? t('detailansicht.folgevertragFehler'))
      return
    }
    navigate(`/admin/vertraege/${data}`)
  }

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <EdvanceNavbar subtitle={t('page.subtitle')} sticky />
      <main className="mx-auto flex max-w-5xl flex-col gap-6 px-4 py-8">
        <AdminHeader
          eyebrow={t('detail.eyebrow')}
          title={kind(v) || '—'}
          description={t('detail.mandate', { ref: v.mandatsreferenz })}
          backTo="/admin/vertraege"
          backLabel={t('detail.back')}
          actions={
            <EdvanceBadge variant={STATUS_FARBE[v.wirksamer_status]}>
              {t(`menue.wirksam.${v.wirksamer_status}`)}
            </EdvanceBadge>
          }
        />

        {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}
        {hinweis !== null && (
          <p className="text-sm text-[var(--color-success)]">{hinweis}</p>
        )}

        <div className="grid grid-cols-1 gap-6 lg:grid-cols-[2fr_1fr]">
          {/* ---- links: wer, was, seit wann ---------------------------- */}
          <div className="flex flex-col gap-6">
            <Datenblock
              titel={t('form.parent')}
              zeilen={[
                { label: t('menue.spalte.partner'), wert: vertragspartner(v) || '—' },
                {
                  label: t('field.strasse'),
                  wert: [v.strasse, v.hausnummer].filter(Boolean).join(' ') || '—',
                },
                { label: t('field.ort'), wert: [v.plz, v.ort].filter(Boolean).join(' ') || '—' },
                { label: t('field.eltern_email'), wert: v.eltern_email ?? '—' },
                { label: t('field.eltern_telefon'), wert: v.eltern_telefon ?? '—' },
                { label: t('field.kontoinhaber'), wert: v.kontoinhaber ?? '—' },
                {
                  label: t('field.iban'),
                  wert: <IbanFeld vertragId={v.id} maskiert={v.iban_masked} onFehler={setError} />,
                },
                { label: t('field.mandatsreferenz'), wert: v.mandatsreferenz },
              ]}
            />

            <Datenblock
              titel={t('form.child')}
              zeilen={[
                { label: t('menue.spalte.partner'), wert: kind(v) || '—' },
                { label: t('field.kind_geburtsdatum'), wert: datum(v.kind_geburtsdatum) },
                { label: t('field.klasse'), wert: v.klasse ?? '—' },
                { label: t('field.fach'), wert: v.fach ?? '—' },
                { label: t('field.schule'), wert: v.schule ?? '—' },
              ]}
            />

            <Datenblock
              titel={t('form.contract')}
              zeilen={[
                { label: t('field.tier_id'), wert: paket },
                {
                  label: t('field.laufzeit_monate'),
                  wert: v.laufzeit_monate ? t(`form.laufzeitOption.${v.laufzeit_monate}`) : '—',
                },
                {
                  label: t('field.preis'),
                  wert: v.preis_cents !== null ? formatEuro(v.preis_cents, lang) : '—',
                },
                { label: t('field.einheiten'), wert: v.einheiten ?? '—' },
                { label: t('field.vertragsbeginn'), wert: datum(v.vertragsbeginn) },
                {
                  label: t('menue.spalte.endetAm'),
                  wert: (
                    <span>
                      {datum(v.vertrag_ende)}
                      {v.ferientage !== null && (
                        <span className="text-xs text-[var(--color-text-tertiary)]">
                          {` · ${t('detailansicht.ferientage', { count: v.ferientage })}`}
                        </span>
                      )}
                    </span>
                  ),
                },
                { label: t('detailansicht.widerrufBis'), wert: datum(v.widerruf_bis) },
                { label: t('detailansicht.abgeschlossenAm'), wert: datum(v.abgeschlossen_am) },
                {
                  label: t('menue.spalte.zahlung'),
                  wert: (
                    <EdvanceBadge variant={ZAHLUNG_FARBE[v.zahlungsstatus]}>
                      {t(`menue.zahlung.${v.zahlungsstatus}`)}
                    </EdvanceBadge>
                  ),
                },
                ...(v.abweichung_vermerk
                  ? [{ label: t('einpflegen.vermerk'), wert: v.abweichung_vermerk }]
                  : []),
              ]}
            />

            <Datenblock
              titel={t('detailansicht.historie')}
              kinder={
                <VertragHistorie historie={d.historie} aktuellerId={v.id} tiers={d.tiers} />
              }
            />
          </div>

          {/* ---- rechts: Zugang und Archiv ----------------------------- */}
          <div className="flex flex-col gap-6">
            <Datenblock
              titel={t('code.title')}
              kinder={
                <div className="flex flex-col gap-3">
                  <p className="font-mono text-3xl font-bold tracking-widest text-[var(--color-text-primary)]">
                    {v.zugangscode ?? '—'}
                  </p>
                  <p className="text-xs text-[var(--color-text-tertiary)]">
                    {v.zugangscode_gesperrt_am
                      ? t('code.blocked', { date: datum(v.zugangscode_gesperrt_am) })
                      : t('code.created', { date: datum(v.zugangscode_erzeugt_am) })}
                  </p>

                  {/* Inline statt Modal: eine Bestaetigung verschiebt keinen Inhalt. */}
                  {codeFrage ? (
                    <div className="flex flex-col gap-2 rounded-[var(--radius-md)] border border-[var(--color-gold-warning)] bg-[var(--color-gold-warning-light)] p-3">
                      <p className="text-sm text-[var(--color-text-primary)]">
                        {t('detailansicht.codeNeuFrage')}
                      </p>
                      <div className="flex flex-wrap gap-2">
                        <Button
                          size="sm"
                          disabled={busy}
                          loading={busy}
                          onClick={() =>
                            void run(async () => {
                              const r = await vertragZugangscodeNeu(v.id)
                              if (!r.error) setCodeFrage(false)
                              return { error: r.error }
                            })
                          }
                        >
                          {t('detailansicht.codeNeuJa')}
                        </Button>
                        <Button size="sm" variant="outline" disabled={busy} onClick={() => setCodeFrage(false)}>
                          {t('detailansicht.codeNeuNein')}
                        </Button>
                      </div>
                    </div>
                  ) : (
                    <div className="flex flex-col gap-2">
                      <span title={v.zugangscode_gueltig ? undefined : t('detailansicht.codeUngueltig')}>
                        <Button
                          size="sm"
                          variant="outline"
                          className="w-full"
                          disabled={!v.zugangscode_gueltig || busy}
                          onClick={() => setCodeFrage(true)}
                        >
                          <KeyRound className="h-4 w-4" />
                          {t('detailansicht.codeNeu')}
                        </Button>
                      </span>
                      <Button size="sm" variant="outline" onClick={() => openUnterlagen(v.id)}>
                        <Printer className="h-4 w-4" />
                        {t('after.print')}
                      </Button>
                      <span title={t('ways.emailDisabled')}>
                        <Button size="sm" variant="outline" className="w-full" disabled>
                          <Mail className="h-4 w-4" />
                          {t('after.email')}
                        </Button>
                      </span>
                    </div>
                  )}
                </div>
              }
            />

            <Datenblock
              titel={t('proof.title')}
              kinder={
                <ArchivListe
                  dateien={d.archiv}
                  erzeugte={d.erzeugte}
                  fassungen={d.fassungen}
                  zustimmungen={d.nachweise?.zustimmungen ?? []}
                  dokumente={d.dokumente}
                  erzeugt={busy}
                  onPdfErzeugen={() => void run(() => vertragPdfErzeugen(v.id))}
                  onFehler={setError}
                />
              }
            />

            <AktionenKarte
              busy={busy}
              buendelDa={buendelDa}
              elternEmail={v.eltern_email}
              zugangscode={v.zugangscode}
              widerrufMoeglich={widerrufMoeglich}
              onFolgevertrag={() => void folgevertrag()}
              onVersenden={(anlass) => void versenden(anlass)}
              onWiderruf={() => setWiderruf(true)}
              onKuendigung={() => setKuendigung(true)}
            />
          </div>
        </div>
      </main>

      <EingabeDialog
        key={widerruf ? 'widerruf-auf' : 'widerruf-zu'}
        offen={widerruf}
        titel={t('detailansicht.widerrufTitel')}
        beschreibung={t('detailansicht.widerrufHinweis', { date: datum(v.widerruf_bis) })}
        feld="datum"
        label={t('detailansicht.widerrufDatum')}
        pflicht
        vorbelegung={berlinToday()}
        bestaetigen={t('detailansicht.widerrufBestaetigen')}
        saving={busy}
        onAbbruch={() => setWiderruf(false)}
        onBestaetigen={(wert) =>
          void run(() => vertragWiderrufErfassen(v.id, wert)).then((ok) => {
            if (ok) setWiderruf(false)
          })
        }
      />

      <KuendigungDialog
        key={kuendigung ? 'kuendigung-auf' : 'kuendigung-zu'}
        offen={kuendigung}
        saving={busy}
        onAbbruch={() => setKuendigung(false)}
        onBestaetigen={(zum, grund) =>
          void run(() => vertragSonderkuendigungErfassen(v.id, zum, grund)).then((ok) => {
            if (ok) setKuendigung(false)
          })
        }
      />
    </div>
  )
}
