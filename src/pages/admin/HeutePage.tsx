import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { LoadingPulse } from '@/components/edvance'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { useProfilName } from '@/components/edvance/shell/useProfilName'
import { Button } from '@/components/ui/button'
import { useAuth } from '@/hooks/useAuth'
import { berlinTagesGrenzen } from '@/lib/supabase/heute'
import { updateLead } from '@/lib/supabase/leads'
import { vertragStarten } from '@/lib/supabase/vertraege'
import { auslaufende, imVerzug, summen } from '@/lib/vertrag/menue'
import type { Lead } from '@/types'
import { HeuteImBetrieb } from './heute/HeuteImBetrieb'
import { OffeneSessionsListe } from './heute/OffeneSessionsListe'
import { KennzahlenLeiste, type Kennzahl } from '@/components/edvance/admin/KennzahlenLeiste'
import { InhalteListe, RueckstandListe, VertraegeListe } from './heute/ListenBetrieb'
import { ErstgespraecheListe, LsaListe, NeueLeadsListe } from './heute/ListenVertrieb'
import {
  berlinStunde,
  erstgespraeche,
  freigabeGruppen,
  imRueckstand,
  lsaLeads,
  neueLeads,
  offeneAntraege,
  rueckfrageIds,
  tageszeit,
  vorname,
} from './heute/heuteModel'
import { useHeuteDaten } from './heute/useHeuteDaten'
import { TerminModal, type TerminInput } from './leads/TerminModal'
import { formatEuro } from './vertraege/VertragForm'

/**
 * Startseite „Heute“ (/admin, Entscheidung 7): Kennzahlen als schmale Leiste,
 * sechs Arbeitslisten und rechts „Heute im Betrieb“. Jede Liste zeigt dieselbe
 * Menge wie ihr Bereich; geschrieben wird nur über die bestehenden Wege
 * (Termin über updateLead, Vertrag über vertragStarten).
 */
export function HeutePage(): JSX.Element {
  const { t, i18n } = useTranslation('admin')
  const { role } = useAuth()
  const navigate = useNavigate()
  const name = useProfilName()
  const { daten, loading, error: ladeFehler, neuLaden } = useHeuteDaten()
  const [terminLead, setTerminLead] = useState<Lead | null>(null)
  const [saving, setSaving] = useState(false)
  const [busyLeadId, setBusyLeadId] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  const jetzt = useMemo(() => new Date(), [])
  const lang = i18n.language

  const listen = useMemo(() => {
    const { von } = berlinTagesGrenzen(jetzt)
    return {
      neu: neueLeads(daten.leads),
      gespraeche: erstgespraeche(daten.leads, von),
      lsa: lsaLeads(daten.leads),
      antraege: offeneAntraege(daten.antraege),
      auslaufend: auslaufende(daten.vertraege),
      verzug: imVerzug(daten.vertraege),
      rueckstand: imRueckstand(daten.schueler),
      freigabe: freigabeGruppen(daten.aufgaben, daten.skillThemen),
      rueckfragen: rueckfrageIds(daten.aufgaben),
    }
  }, [daten, jetzt])

  const offen =
    listen.neu.length +
    listen.gespraeche.length +
    listen.lsa.length +
    listen.antraege.length +
    listen.auslaufend.length +
    listen.verzug.length +
    listen.rueckstand.length +
    daten.aufgaben.length

  const summe = summen(daten.vertraege)
  const monat = new Intl.DateTimeFormat(lang, { timeZone: 'Europe/Berlin', month: 'long' }).format(jetzt)
  const coachesHeute = new Set(daten.sessions.map((s) => s.coach_id).filter(Boolean)).size

  const zahlen: Kennzahl[] = [
    {
      key: 'schueler',
      label: t('heute.kpi.schueler'),
      wert: String(daten.stats?.students ?? 0),
      unterzeile: t('heute.kpi.schuelerSub', { count: listen.rueckstand.length }),
      ziel: '/admin/akten',
    },
    {
      key: 'leads',
      label: t('heute.kpi.leads'),
      wert: String(daten.stats?.leadsOpen ?? 0),
      unterzeile: t('heute.kpi.leadsSub', { count: daten.stats?.leadsNew ?? 0 }),
      ziel: '/admin/leads',
    },
    {
      key: 'vertraege',
      label: t('heute.kpi.vertraege'),
      wert: String(summe.laufend),
      unterzeile: t('heute.kpi.vertraegeSub', { count: summe.imWiderruf }),
      ziel: '/admin/vertraege',
    },
    {
      key: 'abbuchung',
      label: t('heute.kpi.abbuchung', { monat }),
      wert: formatEuro(summe.abbuchungCents, lang),
      unterzeile: t('heute.kpi.abbuchungSub'),
      ziel: '/admin/vertraege',
    },
    {
      key: 'coaches',
      label: t('heute.kpi.coaches'),
      wert: String(daten.stats?.coaches ?? 0),
      unterzeile: t('heute.kpi.coachesSub', { count: coachesHeute }),
      ziel: '/admin/coaches',
    },
  ]

  // Wie auf dem Leads-Board: aus „Neu“ wechselt der Lead erst mit dem Termin.
  const saveTermin = async (lead: Lead, termin: TerminInput): Promise<void> => {
    setSaving(true)
    const first = lead.status === 'new'
    const { error: err } = await updateLead(lead.id, {
      erstgespraech_at: termin.at,
      erstgespraech_standort: termin.standort,
      ...(first ? { status: 'contacted', contacted_at: new Date().toISOString() } : {}),
    })
    setSaving(false)
    if (err) {
      setError(err)
      return
    }
    setTerminLead(null)
    neuLaden()
  }

  // Wie auf dem Leads-Board: Vertrag anlegen, dann ins Formular.
  const startContract = async (lead: Lead): Promise<void> => {
    if (busyLeadId) return
    setBusyLeadId(lead.id)
    setError(null)
    const { data: vertragId, error: err } = await vertragStarten(lead.id)
    setBusyLeadId(null)
    if (err || !vertragId) {
      setError(err)
      return
    }
    navigate(`/admin/vertraege/${vertragId}`)
  }

  const vor = vorname(name)
  const gruss = t(`heute.gruss.${tageszeit(berlinStunde(jetzt))}`)
  const datum = new Intl.DateTimeFormat(lang, {
    timeZone: 'Europe/Berlin',
    weekday: 'long',
    day: 'numeric',
    month: 'long',
  }).format(jetzt)
  const meldung = error ?? ladeFehler

  return (
    <>
      <PageHeader
        rubrik={datum}
        titel={vor ? t('heute.grussName', { gruss, name: vor }) : gruss}
        satz={loading ? undefined : t('heute.offen', { count: offen })}
        aktionen={
          <Button type="button" onClick={() => navigate('/admin/leads?neu=1')}>
            <Plus aria-hidden="true" className="h-4 w-4" /> {t('heute.neuerLead')}
          </Button>
        }
      />

      {meldung && <p className="text-sm text-[var(--color-error-exam)]">{meldung}</p>}

      {loading ? (
        <LoadingPulse type="list" lines={6} />
      ) : (
        <>
          <KennzahlenLeiste zahlen={zahlen} label={t('heute.kpi.label')} />

          <div className="grid grid-cols-1 items-start gap-6 @heute-spalte:grid-cols-[minmax(0,1fr)_var(--container-heute-betrieb)]">
            <section className="@container flex min-w-0 flex-col gap-2" aria-labelledby="heute-listen">
              <h2 id="heute-listen" className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                {t('heute.zuErledigen')}
              </h2>
              <div className="grid grid-cols-1 gap-4 @heute-listen:grid-cols-2">
                <NeueLeadsListe leads={listen.neu} onTermin={setTerminLead} />
                <ErstgespraecheListe leads={listen.gespraeche} />
                <LsaListe
                  leads={listen.lsa}
                  platzByLead={daten.platzByLead}
                  reportByLead={daten.reportByLead}
                  canStartContract={role === 'admin'}
                  busyLeadId={busyLeadId}
                  onStartContract={(lead) => void startContract(lead)}
                />
                <VertraegeListe antraege={listen.antraege} auslaufend={listen.auslaufend} verzug={listen.verzug} />
                <RueckstandListe schueler={listen.rueckstand} />
                <InhalteListe gruppen={listen.freigabe} rueckfragen={listen.rueckfragen} anzahl={daten.aufgaben.length} />
              </div>
            </section>

            <aside className="flex min-w-0 flex-col gap-2" aria-labelledby="heute-betrieb">
              <h2 id="heute-betrieb" className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                {t('heute.betrieb.titel')}
              </h2>
              <HeuteImBetrieb sessions={daten.sessions} lsa={daten.lsaHeute} />
              <OffeneSessionsListe />
            </aside>
          </div>
        </>
      )}

      <TerminModal
        lead={terminLead}
        saving={saving}
        onClose={() => setTerminLead(null)}
        onSave={(lead, termin) => void saveTermin(lead, termin)}
      />
    </>
  )
}
