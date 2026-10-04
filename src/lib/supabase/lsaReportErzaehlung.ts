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
import { baueSuche } from '@/lib/report/suche'
import { themenraumFuer, type SucheKante } from '@/lib/report/themenraum'
import { gruppiereFehlbilderNachFamilie } from '@/lib/reportFehlbilder'
import {
  loadAnlassZuordnungen,
  loadAnsprechpartner,
  loadReportBausteine,
} from '@/lib/supabase/reportBausteine'
import type {
  ReportErzaehlung,
  ReportFehlbild,
  ReportBaustein,
  SucheSkill,
  Themenraum,
} from '@/types'

/**
 * Die direkt geprüften Skills einer Sitzung, mit Label, Fundamenttiefe und
 * Herkunftsklasse.
 *
 * NUR `belegt_direkt`. Mitbelegte Urteile sind aus dem Voraussetzungsgraphen
 * gefolgert — eine Schlussfolgerung, keine Beobachtung — und gehören nicht in
 * ein Elterngespräch.
 *
 * Zwei Abfragen statt eines Embeds: die Zuordnung Urteil → Label ist ein
 * einfacher Join über den Schlüssel, und zwei klare Abfragen sind hier weniger
 * fehleranfällig als eine eingebettete.
 */
async function loadUrteile(sessionId: string): Promise<SucheSkill[]> {
  const { data: urteile, error } = await supabase
    .from('lsa_skill_urteil')
    .select('skill_key, zustand, proben_anzahl, offen')
    .eq('session_id', sessionId)
    .eq('belegt_direkt', true)
  if (error || !urteile || urteile.length === 0) return []

  const rows = urteile as {
    skill_key: string
    zustand: string
    proben_anzahl: number | null
    offen: boolean | null
  }[]

  const { data: skills, error: sErr } = await supabase
    .from('skills')
    .select('skill_key, label, fundament_tiefe, klasse_herkunft')
    .in(
      'skill_key',
      rows.map((r) => r.skill_key),
    )
  if (sErr || !skills) return []

  type SkillRow = {
    skill_key: string
    label: string | null
    fundament_tiefe: number | null
    klasse_herkunft: number
  }
  const meta = new Map(
    (skills as SkillRow[])
      .filter((s) => s.label?.trim() && s.fundament_tiefe != null)
      .map((s) => [
        s.skill_key,
        {
          label: s.label!.trim(),
          tiefe: s.fundament_tiefe!,
          klasse: s.klasse_herkunft,
        },
      ]),
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
        klasseHerkunft: m.klasse,
        offen: r.offen ?? false,
      },
    ]
  })
}

type ThemaDaten = {
  label: string | null
  raum: Themenraum | null
}

/**
 * Das gewählte Thema der Sitzung und sein Themenraum.
 *
 * Der Raum kommt bevorzugt aus result_summary.themenraum (beim Abschluss
 * gespeichert, W5-d). Nur wenn er fehlt, wird er wie in #189 aus den heutigen
 * Einstiegen und Kanten gerechnet — die werden dann erst geladen.
 *
 * Alte Sitzungen tragen thema_key NULL — dann kein Raum, und der Abschnitt
 * gliedert ohne Thema. thema_einstieg ist nur für admin/coach lesbar; der
 * Report läuft im Admin-Bereich.
 */
async function loadThema(sessionId: string): Promise<ThemaDaten> {
  const leer: ThemaDaten = { label: null, raum: null }
  try {
    const { data: s, error } = await supabase
      .from('lsa_sessions')
      .select('thema_key, themenraum:result_summary->themenraum')
      .eq('id', sessionId)
      .maybeSingle()
    const zeile = s as { thema_key: string | null; themenraum: unknown } | null
    const key = zeile?.thema_key ?? null
    if (error || !key) return leer

    const gespeichert = zeile?.themenraum ?? null
    const [thema, einstieg, kanten] = await Promise.all([
      supabase.from('themen').select('label').eq('thema_key', key).maybeSingle(),
      gespeichert
        ? Promise.resolve({ data: [], error: null })
        : supabase.from('thema_einstieg').select('skill_key').eq('thema_key', key),
      gespeichert ? Promise.resolve([]) : loadKanten(),
    ])
    if (thema.error || einstieg.error) {
      console.warn('report: thema lookup failed', thema.error ?? einstieg.error)
    }
    return {
      label: (thema.data as { label: string | null } | null)?.label ?? null,
      raum: themenraumFuer({
        themaKey: key,
        gespeichert,
        einstieg: ((einstieg.data ?? []) as { skill_key: string }[]).map((e) => e.skill_key),
        kanten,
      }),
    }
  } catch (e) {
    console.warn('report: thema lookup failed', e)
    return leer
  }
}

/** Der Voraussetzungsgraph, für den Abschluss der Einstiegsknoten. */
async function loadKanten(): Promise<SucheKante[]> {
  const { data, error } = await supabase
    .from('skill_kante')
    .select('skill_key, voraussetzt_skill_key')
  if (error || !data) return []
  return (data as { skill_key: string; voraussetzt_skill_key: string }[]).map((k) => ({
    skillKey: k.skill_key,
    voraussetzt: k.voraussetzt_skill_key,
  }))
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
  const [urteile, bestand, bausteine, zuordnungen, ansprechpartner, thema] =
    await Promise.all([
      loadUrteile(sessionId),
      loadBestand(),
      loadReportBausteine(),
      loadAnlassZuordnungen(),
      loadAnsprechpartner(sessionId),
      loadThema(sessionId),
    ])

  const fundament = baueFundament(urteile)
  const suche = baueSuche({ skills: urteile, themaLabel: thema.label, raum: thema.raum })
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
      suche,
      raum: thema.raum,
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
    raum: thema.raum,
  })

  // Fazit und Empfehlung hängen an der VERTEILUNG der Lücken, nicht am Paket —
  // gezählt mit derselben Taxonomie, die das Profil daneben zeichnet.
  const { familien: lueckenFam } = lueckenFamilien(fundament.luecken)
  const verteilung =
    fundament.luecken.length === 0 ? 'keine' : verteilungsFall(lueckenFam.length)

  return {
    fundament,
    suche,
    raum: thema.raum,
    profil,
    rueckbezuege,
    verteilung,
    bausteine: bausteine as ReportBaustein[],
    ansprechpartner,
    anlassNamen,
  }
}
