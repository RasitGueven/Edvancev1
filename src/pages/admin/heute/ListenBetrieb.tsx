import { useNavigate } from 'react-router-dom'
import { Gauge, PenLine, ScrollText } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { formatDateOnly } from '@/lib/datetime'
import { kind, vertragspartner } from '@/lib/vertrag/menue'
import type { BoardSchueler, VertragAktuell, VertragMitLead } from '@/types'
import { AMPEL_BADGE } from '../akten/ampel'
import { kindName } from '../vertraege/vertragModel'
import { ArbeitsListe, OkZeile, type ListenZeile } from './ArbeitsListe'
import type { FreigabeGruppe } from './heuteModel'

type VertraegeProps = {
  antraege: VertragMitLead[]
  auslaufend: VertragAktuell[]
  verzug: VertragAktuell[]
}

/** Offene Anträge, Ausläufer, Zahlungsverzüge — dieselben Mengen wie die Reiter unter Verträge. */
export function VertraegeListe({ antraege, auslaufend, verzug }: VertraegeProps): JSX.Element {
  const { t, i18n } = useTranslation('admin')
  const { t: tv } = useTranslation('vertraege')
  const navigate = useNavigate()
  const lang = i18n.language
  const zeilen: ListenZeile[] = [
    ...antraege.map((v) => ({
      key: `a-${v.id}`,
      titel: t('heute.listen.vertraege.antrag', {
        name: [v.eltern_vorname, v.eltern_nachname].filter(Boolean).join(' ') || v.lead.full_name,
      }),
      unterzeile: t('heute.listen.vertraege.fuer', { kind: kindName(v), status: tv(`status.${v.status}`) }),
      rechts: (
        <Button
          type="button"
          size="sm"
          variant="outline"
          className="min-h-[44px]"
          onClick={() => navigate(`/admin/vertraege/${v.id}`)}
        >
          {t('heute.listen.vertraege.oeffnen')}
        </Button>
      ),
    })),
    ...auslaufend.map((v) => ({
      key: `e-${v.id}`,
      titel: t('heute.listen.vertraege.laeuftAus', { kind: kind(v) || vertragspartner(v) || '—' }),
      unterzeile: v.vertrag_ende
        ? t('heute.listen.vertraege.endet', { datum: formatDateOnly(v.vertrag_ende, lang) })
        : undefined,
      rechts: <EdvanceBadge variant="warning">{tv('menue.inTagen', { count: v.endet_in_tagen ?? 0 })}</EdvanceBadge>,
    })),
    ...verzug.map((v) => ({
      key: `z-${v.id}`,
      titel: vertragspartner(v) || kind(v) || '—',
      unterzeile: kind(v) || undefined,
      rechts: <EdvanceBadge variant="gap">{tv(`menue.zahlung.${v.zahlungsstatus}`)}</EdvanceBadge>,
    })),
  ]
  return (
    <ArbeitsListe
      icon={ScrollText}
      titel={t('heute.listen.vertraege.titel')}
      unterzeile={t('heute.listen.vertraege.unterzeile')}
      anzahl={zeilen.length}
      zeilen={zeilen}
      nachZeilen={verzug.length === 0 && zeilen.length > 0 ? <OkZeile text={t('heute.listen.vertraege.keinVerzug')} /> : undefined}
      fussLabel={t('heute.listen.vertraege.fuss')}
      fussZiel="/admin/vertraege"
    />
  )
}

/** Aktive Akten im Rückstand. Ampel und „verbraucht“ kommen fertig aus board_schueler(). */
export function RueckstandListe({ schueler }: { schueler: BoardSchueler[] }): JSX.Element {
  const { t } = useTranslation('admin')
  const { t: ta } = useTranslation('akte')
  const { t: tl } = useTranslation('leads')
  const zeilen: ListenZeile[] = schueler.map((s) => ({
    key: s.student_id,
    titel: s.name ?? '—',
    unterzeile: [
      s.klasse !== null ? tl('card.classShort', { level: s.klasse }) : null,
      s.einheiten !== null && s.verbraucht !== null
        ? ta('board.karte.verbraucht', { verbraucht: s.verbraucht, einheiten: s.einheiten })
        : null,
    ]
      .filter(Boolean)
      .join(' · '),
    rechts: s.ampel ? <EdvanceBadge variant={AMPEL_BADGE[s.ampel]}>{ta(`ampel.${s.ampel}`)}</EdvanceBadge> : undefined,
  }))
  return (
    <ArbeitsListe
      icon={Gauge}
      titel={t('heute.listen.rueckstand.titel')}
      unterzeile={t('heute.listen.rueckstand.unterzeile')}
      anzahl={schueler.length}
      zeilen={zeilen}
      fussLabel={t('heute.listen.rueckstand.fuss')}
      fussZiel="/admin/akten"
    />
  )
}

/** Ziel der Freigabe: die Item-Pflege, Bereich LSA. */
const ITEM_PFLEGE = '/admin/authoring?bereich=lsa'

/** Aufgaben im Status review, je Thema eine Zeile. */
export function InhalteListe({ gruppen, anzahl }: { gruppen: FreigabeGruppe[]; anzahl: number }): JSX.Element {
  const { t } = useTranslation('admin')
  const { t: tau } = useTranslation('authoring')
  const navigate = useNavigate()
  const zeilen: ListenZeile[] = gruppen.map((g) => ({
    key: g.themaKey ?? 'ohne',
    titel: g.label ?? tau('board.ohneZuordnung'),
    unterzeile: [g.stufe ? tau(`board.stufe.${g.stufe}`) : null, t('heute.listen.inhalte.aufgaben', { count: g.anzahl })]
      .filter(Boolean)
      .join(' · '),
    rechts: (
      <Button type="button" size="sm" variant="outline" className="min-h-[44px]" onClick={() => navigate(ITEM_PFLEGE)}>
        {t('heute.listen.inhalte.freigeben')}
      </Button>
    ),
  }))
  return (
    <ArbeitsListe
      icon={PenLine}
      titel={t('heute.listen.inhalte.titel')}
      unterzeile={t('heute.listen.inhalte.unterzeile')}
      anzahl={anzahl}
      zeilen={zeilen}
      fussLabel={t('heute.listen.inhalte.fuss')}
      fussZiel={ITEM_PFLEGE}
    />
  )
}
