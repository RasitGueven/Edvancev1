// Erzeugt die HTML-Entwürfe des Eltern-Reports aus echten Sitzungen (R4).
//
//   npx tsx scripts/report/build-eltern-report.ts <ziel-verzeichnis> <session-id>…
//
// ----------------------------------------------------------------------------
// Warum die Migration hier in einer Transaktion nachgestellt und zurückgerollt wird
// ----------------------------------------------------------------------------
// Die Erzählbausteine leben in report_bausteine — einer Tabelle, die die
// R4-Migration anlegt und die (nach Vorgabe) noch NICHT eingespielt ist. Der
// Generator kann sie also nicht einfach lesen.
//
// Er könnte die Sätze zweitschriftlich in einer Fixture halten. Dann gäbe es
// zwei Wahrheiten, die auseinanderlaufen, sobald jemand einen Satz ändert.
//
// Stattdessen: eine Transaktion, die die Migrationsdatei einspielt, die Daten
// als JSON liest und zurückrollt. Die Datenbank bleibt unverändert, und die
// Entwürfe entstehen aus GENAU den Sätzen, die in der Migration stehen — ohne
// Kopie. Ist die Migration erst eingespielt, greift derselbe Pfad ohne das
// Nachstellen (Schalter --ohne-nachstellen).

import { execFileSync } from 'node:child_process'
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'

import { Bausteinsatz } from '@/lib/report/bausteine'
import {
  familienBefunde,
  familienBestand,
  lueckenFamilien,
  verteilungsFall,
} from '@/lib/report/familien'
import { baueFundament } from '@/lib/report/fundament'
import { baueRueckbezuege } from '@/lib/report/rueckbezug'
import { gruppiereFehlbilderNachFamilie } from '@/lib/reportFehlbilder'
import type { AnlassZuordnung, ReportFehlbild } from '@/types'

import { baueReport, esc, type ReportEingabe } from './reportHtml'
import { SITZUNG_SQL } from './sitzungSql'

const HIER = dirname(fileURLToPath(import.meta.url))
const REPO = resolve(HIER, '../..')
/**
 * Die Migrationen, die Erzählbausteine mitbringen — in Reihenfolge.
 *
 * Der Generator stellt sie in einer Transaktion nach und rollt zurück, damit
 * die Entwürfe aus GENAU den Sätzen der Migration entstehen, auch wenn sie noch
 * nicht eingespielt ist. Eine bereits eingespielte Migration erneut
 * nachzustellen ist unschädlich: Alle Anweisungen sind idempotent
 * (`create table if not exists`, `add column if not exists`,
 * `drop policy if exists`, Upserts).
 */
const NACHSTELL_MIGRATIONEN = [
  'supabase/migrations/20260818120000_r4_report_bausteine.sql',
  'supabase/migrations/20260818160000_r5_bausteine_verteilung.sql',
].map((f) => join(REPO, f))

/** Der Admin, unter dessen Claim gelesen wird — lsa_fehlbild_auswertung prüft lsa_may_act_for. */
const LESE_CLAIM_ENV = 'REPORT_ADMIN_PROFILE_ID'

function dbUrl(): string {
  const roh = readFileSync(join(REPO, '.env'), 'utf8')
  for (const zeile of roh.split('\n')) {
    const m = zeile.match(/^DATABASE_URL=(.*)$/)
    if (m) return m[1].trim().replace(/^['"]|['"]$/g, '')
  }
  throw new Error('DATABASE_URL fehlt in .env')
}

/**
 * Führt SQL aus und gibt die einzige JSON-Zelle zurück.
 *
 * Die Verbindungszeichenkette geht als Argument an psql, nie durch eine Shell —
 * sonst stünde sie in Prozesslisten und Logs.
 */
function frage(sql: string): unknown {
  const out = execFileSync(
    'psql',
    ['-X', '-q', '-t', '-A', '-v', 'ON_ERROR_STOP=1', dbUrl(), '-f', '-'],
    { input: sql, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 },
  )
  const json = out.slice(out.indexOf('['))
  return JSON.parse(json)
}

type Roh = {
  session_id: string
  vorname: string | null
  klasse: number
  fach: string
  gestartet: string
  aufgaben: number
  next_exam_topic: string | null
  weak_topics: string[] | null
  urteile: {
    skill_key: string
    label: string
    tiefe: number
    zustand: string
    proben: number
  }[]
  fehlbilder: {
    slug: string
    familie: string | null
    elterntext: string | null
    anzahl: number
    aufgaben: number
    skills: string[] | null
  }[]
  bausteine: {
    schluessel: string
    slot: string
    fall: string
    variante: string
    text: string
  }[]
  zuordnungen: {
    thema: string
    anzeigename: string | null
    skill_keys: string[] | null
    fehlbild_familien: string[] | null
    strukturell: boolean
    messbar: boolean
  }[]
  skill_bestand: string[]
  ansprechpartner: { name: string | null; email: string | null } | null
  tiers: { name: string; features: string[] }[]
}

/**
 * Paketregel, unverändert aus dem Stand vor R4.
 *
 * L      = nicht tragende, direkt geprüfte Bereiche
 * Ltief  = davon mindestens drei Stufen unter der Einstiegstiefe
 */
function paketFuer(luecken: { fundamentTiefe: number }[], einstieg: number): string {
  const L = luecken.length
  const Ltief = luecken.filter((l) => einstieg - l.fundamentTiefe >= 3).length
  if (L >= 6 || Ltief >= 3) return 'Premium'
  if (L >= 3 && Ltief >= 1) return 'Standard'
  return 'Basic'
}

/**
 * Abschnitt 01 aus BELEGTEN Lead-Feldern.
 *
 * leads trägt keine Spalte `leitthema` — geprüft am Schema, nicht vermutet.
 * Ersatz ist next_exam_topic, und der Satz sagt entsprechend „steht als
 * nächstes Thema an", nicht „fällt schwer". Die genannten Bereiche kommen
 * wörtlich aus lead_assessments.weak_topics (source 'parent').
 */
function anlassSatz(
  weakTopics: readonly string[],
  zuordnungen: readonly AnlassZuordnung[],
  thema: string | null,
): string {
  const nachThema = new Map(zuordnungen.map((z) => [z.thema, z]))
  const teile: string[] = []

  // Anzeigenamen statt Rohwerte: weak_topics mischt einen Teilsatz
  // ("Grundlagen fehlen") mit Substantiven. Aneinandergereiht ergab das
  // "weil Sie Grundlagen fehlen, Textverstaendnis und Konzentration als
  // Schwierigkeiten sehen". Der Anzeigename glaettet die Aufzaehlung.
  const namen = [...new Set(weakTopics)].map(
    (t) => nachThema.get(t)?.anzeigename?.trim() || t,
  )

  if (namen.length > 0) {
    const hervor = namen.map((t) => `<span class="em">${esc(t)}</span>`)
    const liste =
      hervor.length === 1
        ? hervor[0]
        : `${hervor.slice(0, -1).join(', ')} und ${hervor[hervor.length - 1]}`
    teile.push(
      `Sie sind zu uns gekommen, weil Sie ${liste} als ` +
        `${namen.length === 1 ? 'Schwierigkeit' : 'Schwierigkeiten'} sehen.`,
    )
  }
  if (thema) {
    teile.push(
      `Als nächstes Thema steht <span class="em">${esc(thema)}</span> an — genau dort haben wir angesetzt.`,
    )
  }
  if (teile.length === 0) {
    teile.push('Sie haben Ihr Kind für eine Lernstandsanalyse angemeldet.')
  }
  return `      ${teile.join(' ')}`
}

/**
 * Trennt Schalter von Positionsargumenten.
 *
 * Eigene Funktion, weil genau hier ein Fehler steckte: `--ohne-nachstellen`
 * wurde per `includes` ERKANNT, aber nicht aus der Liste ENTFERNT — und landete
 * damit als vierte Sitzungs-ID im SQL:
 *
 *   ERROR: invalid input syntax for type uuid: "--ohne-nachstellen"
 *
 * Ein Schalter, der die Positionsargumente verschiebt, ist der klassische Fall
 * dafuer; deshalb steht die Zerlegung an einer Stelle und wird geprueft.
 */
export function zerlegeArgumente(argv: readonly string[]): {
  ziel: string | undefined
  ids: string[]
  nachstellen: boolean
} {
  const schalter = argv.filter((a) => a.startsWith('--'))
  const [ziel, ...ids] = argv.filter((a) => !a.startsWith('--'))
  return { ziel, ids, nachstellen: !schalter.includes('--ohne-nachstellen') }
}

function main(): void {
  const { ziel, ids, nachstellen } = zerlegeArgumente(process.argv.slice(2))
  if (!ziel || ids.length === 0) {
    console.error(
      'Nutzung: npx tsx scripts/report/build-eltern-report.ts <ziel-verzeichnis> <session-id>…',
    )
    process.exit(1)
  }

  const adminId = process.env[LESE_CLAIM_ENV]
  if (!adminId) {
    console.error(`${LESE_CLAIM_ENV} fehlt — profiles.id eines Admins, unter dessen`)
    console.error('Claim gelesen wird (lsa_fehlbild_auswertung prüft lsa_may_act_for).')
    process.exit(1)
  }

  const migration = nachstellen
    ? NACHSTELL_MIGRATIONEN.map((f) =>
        readFileSync(f, 'utf8').replace(/^\s*(begin|commit);\s*$/gm, ''),
      ).join('\n')
    : ''

  const sql = [
    'begin;',
    `select set_config('request.jwt.claims', ${quote(
      JSON.stringify({ sub: adminId, role: 'authenticated' }),
    )}, true);`,
    migration,
    // Ersetzung als Funktion und global: $IDS$ steht zweimal im SQL, und ein
    // String-Replacement würde nur den ersten Treffer ersetzen.
    SITZUNG_SQL.replace(/\$IDS\$/g, () => ids.map(quote).join(', ')),
    'rollback;',
  ].join('\n')

  const rohdaten = frage(sql) as Roh[]
  mkdirSync(ziel, { recursive: true })

  for (const r of rohdaten) {
    const fundament = baueFundament(
      r.urteile.map((u) => ({
        skillKey: u.skill_key,
        label: u.label,
        fundamentTiefe: u.tiefe,
        zustand: u.zustand,
        proben: u.proben,
      })),
    )
    if (!fundament) {
      console.error(`${r.session_id}: kein direkt geprüfter Skill — übersprungen`)
      continue
    }

    const fehlbilder: ReportFehlbild[] = r.fehlbilder.map((f) => ({
      slug: f.slug,
      familie: f.familie,
      familieElterntext: f.elterntext,
      anzahl: Number(f.anzahl),
      aufgaben: Number(f.aufgaben),
      skills: f.skills ?? [],
      skillUebergreifend: (f.skills ?? []).length >= 2,
      einstufung: 'befund',
    }))
    const familien = gruppiereFehlbilderNachFamilie(fehlbilder)

    const zuordnungen: AnlassZuordnung[] = r.zuordnungen.map((z) => ({
      thema: z.thema,
      anzeigename: z.anzeigename?.trim() || z.thema,
      skillKeys: z.skill_keys ?? [],
      fehlbildFamilien: z.fehlbild_familien ?? [],
      strukturell: z.strukturell,
      messbar: z.messbar,
    }))

    const rueckbezuege = baueRueckbezuege({
      weakTopics: r.weak_topics ?? [],
      zuordnungen,
      skills: fundament.tragend.concat(fundament.luecken),
      familien,
      fundament,
    })

    const paket = paketFuer(fundament.luecken, fundament.einstiegTiefe)
    const tier = r.tiers.find((t) => t.name === paket)

    // Fazit und Empfehlung haengen an der VERTEILUNG der Luecken, nicht am
    // Paket. Dieselbe Familientaxonomie wie das Profil daneben — wer die
    // Verteilung behauptet, muss sie mit demselben Massstab zaehlen.
    const alleSkills = fundament.tragend.concat(fundament.luecken)
    const profil = familienBefunde(alleSkills, familienBestand(r.skill_bestand ?? []))
    const { familien: lueckenFam, ohneFamilie } = lueckenFamilien(fundament.luecken)
    const verteilung =
      fundament.luecken.length === 0
        ? 'keine'
        : verteilungsFall(lueckenFam.length)

    const eingabe: ReportEingabe = {
      sessionId: r.session_id,
      vorname: r.vorname?.trim() || 'Ihrem Kind',
      klasse: r.klasse,
      fach: r.fach,
      datum: new Intl.DateTimeFormat('de-DE', {
        day: 'numeric',
        month: 'long',
        year: 'numeric',
        timeZone: 'Europe/Berlin',
      }).format(new Date(r.gestartet)),
      aufgaben: Number(r.aufgaben),
      fundament,
      familien,
      profil,
      rueckbezuege,
      ansprechpartner: r.ansprechpartner ?? { name: null, email: null },
      anlass: anlassSatz(r.weak_topics ?? [], zuordnungen, r.next_exam_topic),
      verteilung,
      paket,
      frequenz: tier?.features?.[0] ?? '',
    }

    const satz = new Bausteinsatz(r.bausteine)
    const datei = join(
      ziel,
      `report-${(r.vorname ?? r.session_id.slice(0, 8)).toLowerCase()}-v3.html`,
    )
    writeFileSync(datei, baueReport(eingabe, satz), 'utf8')

    console.log(`${(r.vorname ?? '?').padEnd(9)} -> ${datei}`)
    console.log(
      `  geprüft ${fundament.geprueft} | trägt ${fundament.traegt}` +
        ` | Einstieg ${fundament.einstiegTraegt ? 'trägt' : 'trägt nicht'}` +
        ` | Einbruch Δ${fundament.einbruch?.delta ?? '—'}` +
        ` | Boden ${fundament.bodenTraegt ? 'trägt' : 'trägt nicht'}` +
        ` | ${paket}`,
    )
    console.log(
      `  Verteilung: ${verteilung} (${lueckenFam.length} Familie(n)` +
        `${ohneFamilie > 0 ? `, ${ohneFamilie} ohne Familie` : ''})` +
        ` | Profil (geprueft|traegt/vorhanden): ` +
        profil.map((b) => `${b.key} ${b.geprueft}|${b.traegt}/${b.vorhanden}`).join(' '),
    )
    for (const rb of rueckbezuege) {
      console.log(`  Rückbezug „${rb.thema}" -> ${rb.fall} (Belege: ${rb.belege})`)
    }
  }
}

/** SQL-Literal. Nur für Werte, die wir selbst erzeugen (IDs, JSON-Claim). */
function quote(v: string): string {
  return `'${v.replace(/'/g, "''")}'`
}

// Nur ausfuehren, wenn die Datei direkt gestartet wurde. Sonst wuerde jeder
// Import — etwa aus einem Test — den Generator laufen lassen und gegen die
// Datenbank gehen.
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main()
}
