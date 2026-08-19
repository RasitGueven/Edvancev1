// Eltern-Report — die Erzählschicht der App (R6).
//
// Sammelt, was die sechs Schritte des Reports brauchen, und rechnet sie mit den
// REINEN Funktionen aus src/lib/report/ aus. Genau denselben Funktionen, die
// auch der Entwurfs-Generator (scripts/report/) benutzt — damit App und Entwurf
// nicht auseinanderlaufen. Hier steht nur der Weg zu den Daten, keine Regel.
//
// Eigene Datei neben lsaReport.ts, weil die 400-Zeilen-Grenze (CLAUDE §4) sonst
// fällt und weil dieser Pfad andere Quellen hat: lsa_skill_urteil, skills,
// report_bausteine, report_anlass_zuordnung, platz_assignments.
//
// Ein Fehler darf den Report nicht kippen. Fehlt eine Quelle, fehlt der
// zugehörige Abschnitt — nicht das Dokument.

import { supabase } from '@/lib/supabase/client'
import {
  familienBefunde,
  familienBestand,
  lueckenFamilien,
  verteilungsFall,
} from '@/lib/report/familien'
import { baueFundament } from '@/lib/report/fundament'
import { baueRueckbezuege } from '@/lib/report/rueckbezug'
import { gruppiereFehlbilderNachFamilie } from '@/lib/reportFehlbilder'
import {
  loadAnlassZuordnungen,
  loadAnsprechpartner,
  loadReportBausteine,
} from '@/lib/supabase/reportBausteine'
import type {
  FundamentSkill,
  ReportErzaehlung,
  ReportFehlbild,
  ReportBaustein,
} from '@/types'

/**
 * Die direkt geprüften Skills einer Sitzung, mit Label und Fundamenttiefe.
 *
 * NUR `belegt_direkt`. Mitbelegte Urteile sind aus dem Voraussetzungsgraphen
 * gefolgert — eine Schlussfolgerung, keine Beobachtung — und gehören nicht in
 * ein Elterngespräch.
 *
 * Zwei Abfragen statt eines Embeds: die Zuordnung Urteil → Label ist ein
 * einfacher Join über den Schlüssel, und zwei klare Abfragen sind hier weniger
 * fehleranfällig als eine eingebettete.
 */
async function loadUrteile(sessionId: string): Promise<FundamentSkill[]> {
  const { data: urteile, error } = await supabase
    .from('lsa_skill_urteil')
    .select('skill_key, zustand, proben_anzahl')
    .eq('session_id', sessionId)
    .eq('belegt_direkt', true)
  if (error || !urteile || urteile.length === 0) return []

  const rows = urteile as {
    skill_key: string
    zustand: string
    proben_anzahl: number | null
  }[]

  const { data: skills, error: sErr } = await supabase
    .from('skills')
    .select('skill_key, label, fundament_tiefe')
    .in(
      'skill_key',
      rows.map((r) => r.skill_key),
    )
  if (sErr || !skills) return []

  const meta = new Map(
    (skills as { skill_key: string; label: string | null; fundament_tiefe: number | null }[])
      .filter((s) => s.label?.trim() && s.fundament_tiefe != null)
      .map((s) => [s.skill_key, { label: s.label!.trim(), tiefe: s.fundament_tiefe! }]),
  )

  // Ohne Label oder Tiefe kein Eintrag: Der Schlüssel selbst ist snake_case und
  // kein Satz für Eltern (INV-4.3), und ohne Tiefe hat der Skill keine Ebene.
  return rows.flatMap((r) => {
    const m = meta.get(r.skill_key)
    if (!m) return []
    return [
      {
        skillKey: r.skill_key,
        label: m.label,
        fundamentTiefe: m.tiefe,
        zustand: r.zustand,
        proben: r.proben_anzahl ?? 0,
      },
    ]
  })
}

/**
 * Der Bestand: alle Skills des Fachs, als Nenner des Profils.
 *
 * Ohne ihn zeigte die Profilachse `traegt / geprueft` — und „2 von 2" ergäbe
 * eine volle Achse, obwohl von acht vorhandenen Bereichen sechs nie angesehen
 * wurden.
 */
async function loadBestand(): Promise<string[]> {
  const { data, error } = await supabase.from('skills').select('skill_key')
  if (error || !data) return []
  return (data as { skill_key: string }[]).map((s) => s.skill_key)
}

/**
 * Baut die Erzählschicht einer Sitzung.
 *
 * `weakTopics` kommt vom Aufrufer, weil der die Eltern-Einschätzung ohnehin
 * schon geladen hat — zweimal dieselbe Zeile zu lesen wäre Verschwendung.
 */
export async function loadErzaehlung(
  sessionId: string,
  weakTopics: readonly string[],
  fehlbilder: readonly ReportFehlbild[],
): Promise<ReportErzaehlung> {
  const [urteile, bestand, bausteine, zuordnungen, ansprechpartner] = await Promise.all([
    loadUrteile(sessionId),
    loadBestand(),
    loadReportBausteine(),
    loadAnlassZuordnungen(),
    loadAnsprechpartner(sessionId),
  ])

  const fundament = baueFundament(urteile)
  const profil = familienBefunde(urteile, familienBestand(bestand))

  // Die Anzeigenamen der genannten Punkte, für die Aufzählung in Abschnitt 01.
  // Ohne Zuordnung steht der Rohwert da — holprig, aber lesbar; ein leerer
  // Punkt in der Aufzählung wäre schlimmer.
  const nachThema = new Map(zuordnungen.map((z) => [z.thema, z]))
  const anlassNamen = [...new Set(weakTopics)].map(
    (t) => nachThema.get(t)?.anzeigename ?? t,
  )

  if (!fundament) {
    return {
      fundament: null,
      profil,
      rueckbezuege: [],
      verteilung: null,
      bausteine: bausteine as ReportBaustein[],
      ansprechpartner,
      anlassNamen,
    }
  }

  const familien = gruppiereFehlbilderNachFamilie(fehlbilder)
  const rueckbezuege = baueRueckbezuege({
    weakTopics,
    zuordnungen,
    skills: urteile,
    familien,
    fundament,
  })

  // Fazit und Empfehlung hängen an der VERTEILUNG der Lücken, nicht am Paket —
  // gezählt mit derselben Taxonomie, die das Profil daneben zeichnet.
  const { familien: lueckenFam } = lueckenFamilien(fundament.luecken)
  const verteilung =
    fundament.luecken.length === 0 ? 'keine' : verteilungsFall(lueckenFam.length)

  return {
    fundament,
    profil,
    rueckbezuege,
    verteilung,
    bausteine: bausteine as ReportBaustein[],
    ansprechpartner,
    anlassNamen,
  }
}
