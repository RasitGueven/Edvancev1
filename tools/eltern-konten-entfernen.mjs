#!/usr/bin/env node
/**
 * eltern-konten-entfernen.mjs — entfernt alle Eltern-Konten (K1b, Entscheidung Rasit 14.10.2026).
 *
 * Eltern bekommen kein Konto mehr; alle Mails an Eltern gehen an vertraege.eltern_email.
 * Die Konten, die vertrag_abschluss bis dahin angelegt hat, werden entfernt:
 *   1. parent_student-Zeilen dieser Konten
 *   2. das Auth-Konto (auth.users); das Profil haengt per ON DELETE CASCADE daran
 *
 * Bricht ab, ohne etwas zu loeschen, sobald
 *   - ein Eltern-Konto mit einem Kind verknuepft ist, das NICHT ist_test ist
 *     (auch: verknuepftes Profil ohne students-Zeile — dann ist es nicht als Test belegt), oder
 *   - eine Tabelle per Fremdschluessel ohne Cascade auf eines der Konten zeigt
 *     (das Loeschen wuerde mittendrin scheitern), oder
 *   - ein Konto ueber die Admin-API nicht als parent-Konto auffindbar ist
 *     (SUPABASE_URL zeigt dann nicht auf dieselbe Datenbank wie dbread).
 *
 * Lesen nur ueber ~/bin/dbread (read-only). Geschrieben wird nur mit --ausfuehren, mit
 * SUPABASE_URL (oder VITE_SUPABASE_URL) und SUPABASE_SERVICE_ROLE_KEY aus der Umgebung.
 * Die Ausgabe nennt nur Anzahlen — keine Adressen, keine IDs.
 *
 *   node tools/eltern-konten-entfernen.mjs --dry-run
 *   node tools/eltern-konten-entfernen.mjs --ausfuehren
 */
import { execFileSync } from 'node:child_process'
import os from 'node:os'
import path from 'node:path'
import { pathToFileURL } from 'node:url'

/**
 * bestand.eltern: IDs der Profile mit Rolle parent.
 * bestand.links: { parent, istTest } je parent_student-Zeile; istTest true | false | null (keine students-Zeile).
 * bestand.blockierend: Zeilen in Tabellen, die per Fremdschluessel ohne Cascade auf die Konten zeigen.
 * bestand.cascade: Zeilen, die per ON DELETE CASCADE mitfallen (ohne parent_student) — nur zur Information.
 */
export function planen(bestand) {
  const links = bestand.links
  const zahlen = {
    eltern: bestand.eltern.length,
    elternMitKind: new Set(links.map((l) => l.parent)).size,
    parentStudent: links.length,
    kinderTest: links.filter((l) => l.istTest === true).length,
    kinderEcht: links.filter((l) => l.istTest === false).length,
    kinderOhneSchuelerzeile: links.filter((l) => l.istTest === null).length,
    blockierend: bestand.blockierend,
    cascade: bestand.cascade ?? 0,
  }
  const gruende = []
  if (zahlen.kinderEcht > 0) gruende.push(`${zahlen.kinderEcht} Verknüpfung(en) mit einem Kind, das nicht ist_test ist`)
  if (zahlen.kinderOhneSchuelerzeile > 0) {
    gruende.push(`${zahlen.kinderOhneSchuelerzeile} Verknüpfung(en) mit einem Profil ohne students-Zeile (nicht als Test belegt)`)
  }
  if (zahlen.blockierend > 0) gruende.push(`${zahlen.blockierend} Zeile(n) mit Fremdschlüssel ohne Cascade auf ein Eltern-Konto`)
  return { zahlen, abbruch: gruende.length > 0, gruende }
}

export function bericht({ zahlen, abbruch, gruende }, modus) {
  const z = [
    `Konten mit Rolle parent:                 ${zahlen.eltern}`,
    `  davon mit verknüpftem Kind:            ${zahlen.elternMitKind}`,
    `parent_student-Zeilen:                   ${zahlen.parentStudent}`,
    `verknüpfte Kinder ist_test ja:           ${zahlen.kinderTest}`,
    `verknüpfte Kinder ist_test nein:         ${zahlen.kinderEcht}`,
    `verknüpft, aber ohne students-Zeile:     ${zahlen.kinderOhneSchuelerzeile}`,
    `blockierende Fremdbezüge:                ${zahlen.blockierend}`,
    `weitere Zeilen, die per Cascade fallen:  ${zahlen.cascade}`,
  ]
  if (abbruch) z.push('', 'ABBRUCH — es wird nichts gelöscht:', ...gruende.map((g) => `  - ${g}`))
  else if (zahlen.eltern === 0) z.push('', 'Nichts zu tun.')
  else if (modus === 'dry-run') z.push('', `--ausfuehren würde ${zahlen.parentStudent} parent_student-Zeilen und ${zahlen.eltern} Konten löschen.`)
  return z.join('\n')
}

// ---------------------------------------------------------------------------
// Ablauf mit eingespritzten Effekten (testbar ohne DB und ohne Netz)

/**
 * lesen(): Bestand (wirft bei Lesefehler). konten: { pruefen(id) -> 'parent' | 'fehlt' | 'andere_rolle',
 * verknuepfungenLoeschen(ids), kontoLoeschen(id) } oder null (keine Schreibrechte).
 * Gibt { geloescht, abbruch } zurueck; loescht nie, wenn irgendeine Pruefung scheitert.
 */
export async function lauf({ modus, lesen, konten, log = console.log }) {
  const plan = planen(lesen())
  log(bericht(plan, modus))
  if (modus === 'dry-run' || plan.abbruch || plan.zahlen.eltern === 0) return { geloescht: 0, abbruch: plan.abbruch }
  if (!konten) {
    log('SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY fehlen in der Umgebung. Nichts gelöscht.')
    return { geloescht: 0, abbruch: true }
  }

  // Unmittelbar vor dem Schreiben noch einmal lesen: Zwischen Lesen und Loeschen darf kein echtes Kind dazukommen.
  const vorher = lesen()
  const erneut = planen(vorher)
  if (erneut.abbruch) {
    log(bericht(erneut, 'ausfuehren'))
    return { geloescht: 0, abbruch: true }
  }
  // Kopplung: Jedes Konto muss ueber die Admin-API als parent-Konto auffindbar sein. Sonst zeigt
  // SUPABASE_URL auf ein anderes Projekt als dbread — dann wird nichts geloescht.
  let abweichend = 0
  for (const id of vorher.eltern) if ((await konten.pruefen(id)) !== 'parent') abweichend++
  if (abweichend > 0) {
    log(`ABBRUCH — ${abweichend} Konto/Konten über die Admin-API nicht als parent-Konto gefunden (anderes Projekt?). Nichts gelöscht.`)
    return { geloescht: 0, abbruch: true }
  }

  await konten.verknuepfungenLoeschen(vorher.eltern)
  let geloescht = 0
  for (const id of vorher.eltern) {
    await konten.kontoLoeschen(id).catch((e) => {
      throw new Error(`Konto ${geloescht + 1} von ${vorher.eltern.length}: ${e instanceof Error ? e.message : e}`)
    })
    geloescht++
  }
  const danach = planen(lesen())
  log(`\nGelöscht: ${geloescht} Konten. dbread danach: ${danach.zahlen.eltern} Konten mit Rolle parent, ${danach.zahlen.parentStudent} parent_student-Zeilen.`)
  return { geloescht, abbruch: false }
}

// ---------------------------------------------------------------------------
// Echte Effekte: dbread (lesen), Admin-API (schreiben)

function dbread(sql) {
  try {
    // stderr nicht durchreichen: eine Postgres-Meldung kann Werte enthalten.
    return String(
      execFileSync(path.join(os.homedir(), 'bin', 'dbread'), ['-tAc', sql], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }),
    )
  } catch (e) {
    throw new Error(`dbread fehlgeschlagen (Exit ${e.status ?? '?'})`)
  }
}

const zeilen = (s) => s.split('\n').map((x) => x.trim()).filter(Boolean)

/** Zeilen in Tabellen, die per einspaltigem FK auf profiles oder auth.users zeigen, je nach Loeschregel. */
const sqlFremdbezuege = (regeln, ohne) => String.raw`
with eltern as (select array_agg(id) ids from public.profiles where role = 'parent'),
fks as (
  select c.conrelid::regclass as tabelle, a.attname as spalte
    from pg_constraint c
    join pg_attribute a on a.attrelid = c.conrelid and a.attnum = c.conkey[1]
   where c.contype = 'f' and array_length(c.conkey, 1) = 1
     and c.confrelid in ('public.profiles'::regclass, 'auth.users'::regclass)
     and c.confdeltype in (${regeln})
     and c.conrelid not in (${ohne})
)
select coalesce(sum((xpath('/row/c/text()', query_to_xml(
         format('select count(*) as c from %s where %I = any(%L::uuid[])', f.tabelle, f.spalte, e.ids),
         false, true, '')))[1]::text::int), 0)
  from fks f, eltern e
 where e.ids is not null`

/** NO ACTION / RESTRICT: wuerde das Loeschen verhindern. */
export const SQL_BLOCKIEREND = sqlFremdbezuege(`'a', 'r'`, `0`)
/** CASCADE ohne parent_student und ohne profiles selbst: faellt mit. */
export const SQL_CASCADE = sqlFremdbezuege(`'c'`, `'public.parent_student'::regclass, 'public.profiles'::regclass`)

export function bestandLesen() {
  const eltern = zeilen(dbread(`select id from public.profiles where role = 'parent'`))
  const links = zeilen(
    dbread(`select ps.parent_id, coalesce(s.ist_test::text, 'null')
              from public.parent_student ps
              join public.profiles p on p.id = ps.parent_id and p.role = 'parent'
              left join public.students s on s.profile_id = ps.student_id`),
  ).map((z) => {
    const [parent, t] = z.split('|')
    return { parent, istTest: t === 'true' ? true : t === 'false' ? false : null }
  })
  const blockierend = Number(zeilen(dbread(SQL_BLOCKIEREND))[0] ?? 0)
  const cascade = Number(zeilen(dbread(SQL_CASCADE))[0] ?? 0)
  return { eltern, links, blockierend, cascade }
}

async function kontenUeberAdminApi() {
  const url = process.env.SUPABASE_URL ?? process.env.VITE_SUPABASE_URL
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY
  if (!url || !key) return null
  const { createClient } = await import('@supabase/supabase-js')
  const sb = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } })
  return {
    async pruefen(id) {
      const { data } = await sb.from('profiles').select('role').eq('id', id).maybeSingle()
      if (!data) return 'fehlt'
      return data.role === 'parent' ? 'parent' : 'andere_rolle'
    },
    async verknuepfungenLoeschen(ids) {
      for (let i = 0; i < ids.length; i += 50) {
        const { error } = await sb.from('parent_student').delete().in('parent_id', ids.slice(i, i + 50))
        if (error) throw new Error(`parent_student: ${error.message}`)
      }
    },
    async kontoLoeschen(id) {
      const { error } = await sb.auth.admin.deleteUser(id)
      if (error) throw new Error(error.message)
    },
  }
}

async function main(argv = process.argv.slice(2)) {
  const dryRun = argv.includes('--dry-run')
  const ausfuehren = argv.includes('--ausfuehren')
  if (dryRun === ausfuehren) {
    console.error('Genau eins angeben: --dry-run oder --ausfuehren.')
    process.exit(2)
  }
  const r = await lauf({
    modus: dryRun ? 'dry-run' : 'ausfuehren',
    lesen: bestandLesen,
    konten: ausfuehren ? await kontenUeberAdminApi() : null,
  })
  if (r.abbruch) process.exitCode = 1
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  main().catch((e) => {
    console.error(e instanceof Error ? e.message : e)
    process.exit(1)
  })
}
