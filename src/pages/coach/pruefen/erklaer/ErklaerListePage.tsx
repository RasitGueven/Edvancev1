// /coach/pruefen/erklaerungen (Lena) und /admin/pruefen/erklaerungen (Admin, mit Filtern): alle Kernideen
// der Erklaersequenzen nach Thema, offen zuerst (Bauauftrag L6, Punkte 5 und 7).

import { useEffect, useMemo, useState, type JSX } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EmptyState, LoadingPulse } from '@/components/edvance'
import { Button } from '@/components/ui'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { AdminFilterLeiste, ErklaerListe } from '@/components/edvance/pruefen/erklaer/ErklaerListe'
import { filtereErklaer, naechsteOffeneKernidee, zaehleFilter, type AdminFilter } from '@/lib/pruefung/erklaerAnzeige'
import { erklaerBasis, erklaerFehlerSchluessel, type ErklaerModus } from '@/lib/pruefung/erklaerTexte'
import { getErklaerListe } from '@/lib/supabase/erklaerPruefung'
import type { ErklaerFehler, ErklaerListenZeile } from '@/types/erklaerPruefung'

function alsFilter(wert: string | null): AdminFilter {
  return wert === 'bereit' || wert === 'rueckfragen' ? wert : 'alle'
}

export function ErklaerListePage({ modus }: { modus: ErklaerModus }): JSX.Element {
  const { t } = useTranslation('erklaerPruefen')
  const navigate = useNavigate()
  const [params, setParams] = useSearchParams()
  const [zeilen, setZeilen] = useState<ErklaerListenZeile[] | null>(null)
  const [fehler, setFehler] = useState<ErklaerFehler | null>(null)
  const admin = modus === 'admin'
  const filter = admin ? alsFilter(params.get('filter')) : 'alle'

  useEffect(() => {
    void getErklaerListe().then((r) => {
      setZeilen(r.data)
      setFehler(r.error)
    })
  }, [])

  const gefiltert = useMemo(() => (zeilen ? filtereErklaer(zeilen, filter) : []), [zeilen, filter])
  const naechste = zeilen ? naechsteOffeneKernidee(zeilen, null) : null
  const oeffne = (id: string): void => navigate(`${erklaerBasis(modus)}/${id}${admin && filter !== 'alle' ? `?filter=${filter}` : ''}`)

  return (
    <div className="flex flex-col gap-6">
      <PageHeader titel={t(admin ? 'liste.adminTitel' : 'liste.titel')} satz={t(admin ? 'liste.adminSatz' : 'liste.satz')}
        zurueckZu={admin ? '/admin/authoring' : '/coach/pruefen'} zurueckLabel={t(admin ? 'liste.zurueckAdmin' : 'liste.zurueck')}
        aktionen={!admin && naechste ? <Button onClick={() => oeffne(naechste)}>{t('liste.naechste')}</Button> : undefined} />
      {!zeilen && !fehler && <LoadingPulse type="card" />}
      {fehler && <EmptyState icon="🔒" title={t('liste.titel')} description={t(erklaerFehlerSchluessel(fehler))} />}
      {zeilen && admin && (
        <AdminFilterLeiste aktiv={filter} zahlen={zaehleFilter(zeilen)}
          onFilter={(f) => setParams(f === 'alle' ? {} : { filter: f }, { replace: true })} />
      )}
      {zeilen && zeilen.length === 0 && <EmptyState icon="💡" title={t('liste.leer')} description={t('liste.leerText')} />}
      {zeilen && zeilen.length > 0 && gefiltert.length === 0 && (
        <EmptyState icon="✅" title={t('liste.filterLeer')} description={t(`liste.filterLeerText.${filter}`)} />
      )}
      {gefiltert.length > 0 && <ErklaerListe zeilen={gefiltert} admin={admin} onOeffnen={oeffne} />}
    </div>
  )
}
