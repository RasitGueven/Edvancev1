// Baukasten der Fixtures für den Eltern-Bericht R7.
//
// Rechnet eine vollständige ReportData aus den Rohdaten einer Sitzung — mit
// denselben reinen Funktionen und in derselben Reihenfolge wie der Lesepfad
// (src/lib/supabase/lsaReportErzaehlung.ts, lsaReportSkills.ts). Der Lesepfad
// selbst lädt den Supabase-Client und darf hier nicht importiert werden: die
// Vorschau läuft ohne .env. Ändert sich die Komposition dort, hier nachziehen.

import { BAUSTEINE, ZUORDNUNGEN } from '@/lib/report/elternbericht/fixtures/bausteine'
import { KATALOG } from '@/lib/report/elternbericht/fixtures/katalog'
import {
  familienBefunde,
  familienBestand,
  lueckenFamilien,
  verteilungsFall,
} from '@/lib/report/familien'
import { baueFundament } from '@/lib/report/fundament'
import { baueRueckbezuege } from '@/lib/report/rueckbezug'
import { baueSuche } from '@/lib/report/suche'
import { gruppiereFehlbilderNachFamilie } from '@/lib/reportFehlbilder'
import type {
  KatalogSkill,
  ReportData,
  ReportFehlbild,
  ReportSkillbefunde,
  SucheSkill,
  Themenraum,
} from '@/types'

/** Ein direkt geprüfter Skill, Spalten wie in lsa_skill_urteil + skills. */
export const u = (
  skillKey: string,
  label: string,
  fundamentTiefe: number,
  klasseHerkunft: number,
  zustand: string,
  proben: number,
  offen: boolean,
): SucheSkill => ({ skillKey, label, fundamentTiefe, klasseHerkunft, zustand, proben, offen })

export type SitzungRoh = {
  sessionId: string
  firstName: string | null
  grade: number
  analysedAt: string
  aufgaben: number
  testlauf: boolean
  schulform: string | null
  naechstesThema: string | null
  weakTopics: string[]
  urteile: readonly SucheSkill[]
  fehlbilder?: ReportFehlbild[]
  themaLabel: string | null
  raum: Themenraum | null
  katalog?: readonly KatalogSkill[]
}

/** Wie loadSkillbefunde, aber aus den schon geladenen Urteilen. */
function skillbefundeAus(urteile: readonly SucheSkill[]): ReportSkillbefunde | null {
  if (urteile.length === 0) return null
  const nichtTragend = urteile
    .filter((s) => s.zustand === 'traegt_nicht' || s.zustand === 'traegt_teilweise')
    .map(({ skillKey, label, fundamentTiefe }) => ({ skillKey, label, fundamentTiefe }))
    .sort((a, b) => b.fundamentTiefe - a.fundamentTiefe || a.label.localeCompare(b.label, 'de'))
  return {
    nichtTragend,
    tragendAnzahl: urteile.filter((s) => s.zustand === 'traegt').length,
    zurueckgegangen: new Set(nichtTragend.map((s) => s.fundamentTiefe)).size > 1,
  }
}

export function datenAus(roh: SitzungRoh): ReportData {
  const urteile = [...roh.urteile]
  const katalog = [...(roh.katalog ?? KATALOG)]
  const fehlbilder = roh.fehlbilder ?? []
  const fundament = baueFundament(urteile)

  const nachThema = new Map(ZUORDNUNGEN.map((z) => [z.thema, z]))
  const anlassNamen = [...new Set(roh.weakTopics)].map((t) => nachThema.get(t)?.anzeigename ?? t)

  const lueckenFam = fundament ? lueckenFamilien(fundament.luecken).familien : []
  const verteilung = !fundament
    ? null
    : fundament.luecken.length === 0
      ? 'keine'
      : verteilungsFall(lueckenFam.length)

  return {
    sessionId: roh.sessionId,
    firstName: roh.firstName,
    grade: roh.grade,
    subject: 'Mathematik',
    status: 'completed',
    analysedAt: roh.analysedAt,
    testlauf: roh.testlauf,
    aufgaben: roh.aufgaben,
    naechstesThema: roh.naechstesThema,
    schulform: roh.schulform,
    parentAssessment:
      roh.weakTopics.length > 0 ? { note: null, weakTopics: [...roh.weakTopics] } : null,
    skillbefunde: skillbefundeAus(urteile),
    fehlbilder,
    erzaehlung: {
      fundament,
      suche: baueSuche({ skills: urteile, themaLabel: roh.themaLabel, raum: roh.raum }),
      raum: roh.raum,
      profil: familienBefunde(urteile, familienBestand(katalog.map((k) => k.skillKey))),
      rueckbezuege: fundament
        ? baueRueckbezuege({
            weakTopics: roh.weakTopics,
            zuordnungen: [...ZUORDNUNGEN],
            skills: urteile,
            familien: gruppiereFehlbilderNachFamilie(fehlbilder),
            raum: roh.raum,
          })
        : [],
      verteilung,
      bausteine: [...BAUSTEINE],
      ansprechpartner: { name: 'Rasit Güven', email: 'rasit@edvanceacademy.de' },
      anlassNamen,
      kompetenzen: urteile,
      katalog,
    },
  }
}
