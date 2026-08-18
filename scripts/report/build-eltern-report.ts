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
import { fileURLToPath } from 'node:url'

import { Bausteinsatz } from '@/lib/report/bausteine'
import { baueFundament } from '@/lib/report/fundament'
import { baueRueckbezuege } from '@/lib/report/rueckbezug'
import { gruppiereFehlbilderNachFamilie } from '@/lib/reportFehlbilder'
import type { ReportFehlbild } from '@/types'

import { baueReport, esc, type ReportEingabe } from './reportHtml'
import { SITZUNG_SQL } from './sitzungSql'

const HIER = dirname(fileURLToPath(import.meta.url))
const REPO = resolve(HIER, '../..')
const MIGRATION = join(REPO, 'supabase/migrations/20260818120000_r4_report_bausteine.sql')

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
    skill_keys: string[] | null
    fehlbild_familien: string[] | null
    strukturell: boolean
  }[]
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
function anlassSatz(weakTopics: string[], thema: string | null): string {
  const teile: string[] = []
  if (weakTopics.length > 0) {
    const hervor = weakTopics.map((t) => `<span class="em">${esc(t)}</span>`)
    const liste =
      hervor.length === 1
        ? hervor[0]
        : `${hervor.slice(0, -1).join(', ')} und ${hervor[hervor.length - 1]}`
    teile.push(`Sie sind zu uns gekommen, weil Sie ${liste} als Schwierigkeiten sehen.`)
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

const FAZIT: Record<string, string> = {
  Premium:
    'Die Schwierigkeiten liegen nicht im aktuellen Thema selbst — die Grundlagen darunter tragen noch nicht durchgehend. Wir beginnen deshalb dort und arbeiten uns zum aktuellen Thema vor. Da die Bereiche über mehrere Themen verteilt sind, nehmen wir sie nacheinander vor, nicht gleichzeitig.',
  Standard:
    'Das aktuelle Thema steht. Was darunter noch nicht sicher ist, lässt sich benennen und der Reihe nach aufarbeiten — wir beginnen unten und halten das übrige Niveau parallel.',
  Basic:
    'Der Lernstand trägt weitgehend. Die wenigen Bereiche, die noch nicht sicher sind, nehmen wir im laufenden Unterricht mit.',
}

const WARUM: Record<string, string> = {
  Premium:
    'Es sind mehrere Bereiche, und ein Teil davon liegt unter dem aktuellen Stoff — das braucht Wiederholung in kurzen Abständen.',
  Standard:
    'Die Bereiche liegen dicht beieinander und lassen sich zügig aufarbeiten. Drei Termine geben dafür genug Raum, ohne dass der übrige Stoff liegen bleibt.',
  Basic:
    'Es geht um wenige Bereiche. Zwei Termine pro Woche reichen, um sie aufzuarbeiten und den laufenden Stoff mitzunehmen.',
}

function main(): void {
  const [ziel, ...ids] = process.argv.slice(2)
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

  const nachstellen = !process.argv.includes('--ohne-nachstellen')
  const migration = nachstellen
    ? readFileSync(MIGRATION, 'utf8').replace(/^\s*(begin|commit);\s*$/gm, '')
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

    const zuordnungen = r.zuordnungen.map((z) => ({
      thema: z.thema,
      skillKeys: z.skill_keys ?? [],
      fehlbildFamilien: z.fehlbild_familien ?? [],
      strukturell: z.strukturell,
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
      rueckbezuege,
      ansprechpartner: r.ansprechpartner ?? { name: null, email: null },
      anlass: anlassSatz(r.weak_topics ?? [], r.next_exam_topic),
      fazit: `        ${FAZIT[paket]}`,
      paket,
      frequenz: tier?.features?.[0] ?? '',
      paketWarum: `          ${WARUM[paket]}`,
    }

    const satz = new Bausteinsatz(r.bausteine)
    const datei = join(
      ziel,
      `report-${(r.vorname ?? r.session_id.slice(0, 8)).toLowerCase()}-v2.html`,
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
    for (const rb of rueckbezuege) {
      console.log(`  Rückbezug „${rb.thema}" -> ${rb.fall} (Belege: ${rb.belege})`)
    }
  }
}

/** SQL-Literal. Nur für Werte, die wir selbst erzeugen (IDs, JSON-Claim). */
function quote(v: string): string {
  return `'${v.replace(/'/g, "''")}'`
}

main()
