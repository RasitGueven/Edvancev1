#!/usr/bin/env node
/**
 * bildbedarf.mjs — liest jede Aufgabe aus `tasks` und leitet ab, ob sie eine
 * Abbildung braucht.
 *
 * Zweistufig:
 *   Stufe 1 (deterministisch, kostenlos): Verweis-Erkennung, Reinrechnung-Erkennung,
 *            vorhandene Bildverweise. Entscheidet je nach Bestand 30–50 % der Items.
 *   Stufe 2 (LLM): nur der Rest. Klassifiziert nach der Diagnostik-Regel, nicht nach Optik.
 *
 * SETUP
 *   npm i @supabase/supabase-js          # hast du im Repo schon
 *   export SUPABASE_URL=https://ztcppihxqcphlqaguhma.supabase.co
 *   export SUPABASE_SERVICE_ROLE_KEY=...
 *   export ANTHROPIC_API_KEY=...
 *
 * LAUF
 *   node bildbedarf.mjs --probe             # Spaltennamen ausgeben, sonst nichts
 *   node bildbedarf.mjs --limit 20          # Probelauf auf 20 Aufgaben
 *   node bildbedarf.mjs --no-llm            # nur Stufe 1, kostenlos, sofort
 *   node bildbedarf.mjs                     # voller Lauf
 *   node bildbedarf.mjs --sql               # zusätzlich out/bildbedarf.sql erzeugen
 *
 * Der Lauf schreibt NICHTS in die DB. Mit --sql fällt eine Datei für
 * supabase/pending/ ab, die du selbst einspielst.
 */

import { createClient } from '@supabase/supabase-js';
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';

// ─────────────────────────────────────────────────────────────────────────────
// Spalten-Mapping. Mit --probe prüfen und hier anpassen.
// ─────────────────────────────────────────────────────────────────────────────
const COL = {
  id: 'id',
  question: 'question',      // Frage. Darf Text oder JSON-Payload sein, beides wird behandelt.
  skill: 'skill_key',
  inputType: 'input_type',
  status: 'status',
  afb: 'afb',
  asset: 'assets',
};

const CFG = {
  supabaseUrl: process.env.SUPABASE_URL,
  serviceKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
  anthropicKey: process.env.ANTHROPIC_API_KEY,
  model: process.env.MODEL ?? 'claude-sonnet-5',
  table: process.env.TASKS_TABLE ?? 'tasks',
  batchSize: 20,
  concurrency: 4,
  outDir: process.env.OUT_DIR ?? './out',
  pageSize: 1000,
};

const ARGV = process.argv.slice(2);
const flag = (n) => ARGV.includes(`--${n}`);
const opt  = (n, d) => { const i = ARGV.indexOf(`--${n}`); return i === -1 ? d : ARGV[i + 1]; };

// ─────────────────────────────────────────────────────────────────────────────
// Stufe 1 — Regeln
// ─────────────────────────────────────────────────────────────────────────────

// Verweist die Frage auf etwas Sichtbares? Dann ist die Abbildung konstitutiv,
// egal was ein Modell dazu meint.
const REF_RE = /\b(abbildung|abb\.|skizze|zeichnung|diagramm|schaubild|grafik|graphik|graphen|nebenstehend|dargestellt|abgebildet|siehe\s+(bild|figur|grafik)|der figur|folgende[nrs]?\s+(figur|körper|koerper))\b/iu;

// Reine Rechnung: kein einziges Wort mit >= 4 Buchstaben. "3/4 + 1/6" fällt hier rein,
// "Berechne den Umfang" nicht.
function isPureCalc(q) {
  return (q.match(/\p{L}{4,}/gu) ?? []).length === 0;
}

const FIGUR_TYPEN = [
  'koordinatensystem', 'saeulendiagramm', 'baumdiagramm', 'urne', 'rechteck',
  'dreieck', 'winkel', 'kreis', 'koerper', 'zahlenstrahl', 'bruchmodell',
  'stellenwerttafel', 'tabelle', 'sachbild', 'keine',
];

function ruleClassify(t) {
  if (t.assetRef) return { bedarf: 'hat_bild', figur: null, quelle: 'regel', grund: 'Bildverweis bereits hinterlegt.' };
  if (REF_RE.test(t.question)) {
    return { bedarf: 'konstitutiv', figur: null, quelle: 'regel',
             grund: 'Fragetext verweist auf eine Abbildung, die nicht hinterlegt ist — die Aufgabe ist so nicht lösbar.',
             dangling: true };
  }
  if (isPureCalc(t.question)) {
    return { bedarf: 'keine', figur: 'keine', quelle: 'regel', grund: 'Reine Rechnung ohne Text.' };
  }
  return null; // an Stufe 2
}

// ─────────────────────────────────────────────────────────────────────────────
// Stufe 2 — LLM
// ─────────────────────────────────────────────────────────────────────────────

const SYSTEM = `Du beurteilst Mathematik-Aufgaben für eine 20-minütige Lernstandsanalyse (Klasse 5–7 Fundament, NRW). Du entscheidest ausschliesslich, ob eine Aufgabe eine Abbildung braucht.

Die Regel ist diagnostisch, nicht ästhetisch. Drei Stufen:

konstitutiv — Ohne Abbildung ist die Aufgabe nicht oder nur mit erheblichem Mehraufwand lösbar. Die Information steckt im Bild. Beispiele: eine Figur, deren Masse nur der Zeichnung zu entnehmen sind; ein Diagramm, das abgelesen werden soll; eine Winkelsituation, die sich nicht eindeutig verbalisieren lässt.

stuetze — Die Aufgabe ist ohne Abbildung vollständig lösbar, das Bild würde sie aber erleichtern. Beispiel: ein Bruchmodell zu einer Bruchrechnung, ein Zahlenstrahl zu Vorzeichen. WICHTIG: In einer Diagnostik ist das ein Nachteil. Eine Stütze verändert, was gemessen wird — das Kind erscheint stärker, als es ist. Klassifiziere hier ehrlich, auch wenn das Bild didaktisch nett wäre.

keine — Die Abbildung wäre Dekoration. Sie kostet Lesezeit und misst nichts.

Weitere Vorgaben:
- Ein Geometrie-Skill allein macht eine Aufgabe nicht konstitutiv. "Ein Rechteck ist 4 cm lang und 3 cm breit. Berechne den Umfang." braucht kein Bild — alle Masse stehen im Text.
- Umgekehrt: Sachkontext-Aufgaben brauchen fast nie ein Bild. Der Kontext steht im Text.
- Ein falsches Bild ist schlimmer als kein Bild. Im Zweifel die niedrigere Stufe.

Gib zusätzlich den passenden Figurtyp aus dieser geschlossenen Liste an: ${FIGUR_TYPEN.join(', ')}. Bei bedarf="keine" immer "keine".

Antworte AUSSCHLIESSLICH mit einem JSON-Array, ein Objekt pro Aufgabe, in derselben Reihenfolge, ohne Markdown-Fences und ohne Vor- oder Nachtext:
[{"id":"<id>","bedarf":"konstitutiv|stuetze|keine","figur":"<typ>","grund":"<ein Satz>"}]`;

async function llmBatch(batch) {
  const body = {
    model: CFG.model,
    max_tokens: 4000,
    system: SYSTEM,
    messages: [{
      role: 'user',
      content: batch.map((t) =>
        `--- id: ${t.id}\nskill: ${t.skill ?? '?'}\ninput_type: ${t.inputType ?? '?'}\nafb: ${t.afb ?? '?'}\nfrage: ${t.question}`
      ).join('\n\n'),
    }],
  };

  for (let attempt = 1; attempt <= 4; attempt++) {
    try {
      const res = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'x-api-key': CFG.anthropicKey,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify(body),
      });
      if (res.status === 429 || res.status >= 500) throw new Error(`HTTP ${res.status}`);
      if (!res.ok) throw new Error(`HTTP ${res.status}: ${(await res.text()).slice(0, 300)}`);

      const data = await res.json();
      const text = data.content.filter((c) => c.type === 'text').map((c) => c.text).join('\n');
      const clean = text.replace(/```json/gi, '').replace(/```/g, '').trim();
      const parsed = JSON.parse(clean);
      if (!Array.isArray(parsed)) throw new Error('kein Array');

      const byId = new Map(parsed.map((r) => [String(r.id), r]));
      return batch.map((t) => {
        const r = byId.get(String(t.id));
        if (!r) return { bedarf: 'unklar', figur: null, quelle: 'llm', grund: 'Kein Urteil zurückgekommen.' };
        return {
          bedarf: ['konstitutiv', 'stuetze', 'keine'].includes(r.bedarf) ? r.bedarf : 'unklar',
          figur: FIGUR_TYPEN.includes(r.figur) ? r.figur : null,
          quelle: 'llm',
          grund: String(r.grund ?? '').slice(0, 300),
        };
      });
    } catch (e) {
      if (attempt === 4) {
        console.error(`  Batch endgültig gescheitert: ${e.message}`);
        return batch.map(() => ({ bedarf: 'unklar', figur: null, quelle: 'llm', grund: `Fehler: ${e.message}` }));
      }
      await new Promise((r) => setTimeout(r, 1500 * attempt ** 2));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hilfsfunktionen
// ─────────────────────────────────────────────────────────────────────────────

// question kann Text oder JSON-Payload sein. Beides zu Klartext eindampfen.
function toText(v) {
  if (v == null) return '';
  if (typeof v === 'string') return v.trim();
  if (typeof v === 'object') {
    const parts = [];
    const walk = (n) => {
      if (typeof n === 'string') parts.push(n);
      else if (Array.isArray(n)) n.forEach(walk);
      else if (n && typeof n === 'object') Object.values(n).forEach(walk);
    };
    walk(v);
    return parts.join(' ').trim();
  }
  return String(v);
}

const hash = (s) => crypto.createHash('sha1').update(s).digest('hex').slice(0, 12);
const csvCell = (v) => `"${String(v ?? '').replace(/"/g, '""').replace(/\r?\n/g, ' ')}"`;

async function pool(items, n, fn) {
  const out = new Array(items.length);
  let i = 0;
  await Promise.all(Array.from({ length: Math.min(n, items.length) }, async () => {
    while (i < items.length) { const k = i++; out[k] = await fn(items[k], k); }
  }));
  return out;
}

// ─────────────────────────────────────────────────────────────────────────────
// Hauptlauf
// ─────────────────────────────────────────────────────────────────────────────

async function main() {
  if (!CFG.supabaseUrl || !CFG.serviceKey) {
    console.error('SUPABASE_URL und SUPABASE_SERVICE_ROLE_KEY setzen.');
    process.exit(1);
  }
  const sb = createClient(CFG.supabaseUrl, CFG.serviceKey, { auth: { persistSession: false } });

  // --probe: Spalten zeigen und raus
  if (flag('probe')) {
    const { data, error } = await sb.from(CFG.table).select('*').limit(1);
    if (error) { console.error(error.message); process.exit(1); }
    if (!data?.length) { console.error('Tabelle leer.'); process.exit(1); }
    console.log(`Spalten in ${CFG.table}:\n`);
    for (const [k, v] of Object.entries(data[0])) {
      const t = v === null ? 'null' : Array.isArray(v) ? 'array' : typeof v;
      console.log(`  ${k.padEnd(28)} ${t.padEnd(8)} ${JSON.stringify(v ?? '').slice(0, 70)}`);
    }
    console.log('\n→ COL oben im File anpassen, dann ohne --probe laufen lassen.');
    return;
  }

  // Laden, paginiert
  const cols = [COL.id, COL.question, COL.skill, COL.inputType, COL.status, COL.afb, COL.asset]
    .filter(Boolean).join(',');
  const limit = opt('limit') ? Number(opt('limit')) : null;
  const rows = [];
  for (let from = 0; ; from += CFG.pageSize) {
    let q = sb.from(CFG.table).select(cols).order(COL.id, { ascending: true })
             .range(from, from + CFG.pageSize - 1);
    if (opt('status')) q = q.eq(COL.status, opt('status'));
    if (opt('skill'))  q = q.eq(COL.skill, opt('skill'));
    const { data, error } = await q;
    if (error) { console.error(`Ladefehler: ${error.message}`); process.exit(1); }
    rows.push(...(data ?? []));
    if (!data || data.length < CFG.pageSize) break;
    if (limit && rows.length >= limit) break;
  }

  const tasks = rows.slice(0, limit ?? rows.length).map((r) => ({
    id: r[COL.id],
    question: toText(r[COL.question]),
    skill: r[COL.skill] ?? '(ohne skill)',
    inputType: r[COL.inputType],
    status: r[COL.status],
    afb: r[COL.afb],
    assetRef: COL.asset ? (toText(r[COL.asset]) || null) : null,
  }));
  console.log(`${tasks.length} Aufgaben geladen.\n`);

  // Cache — abgestürzter Lauf kostet keine zweite Runde
  await fs.mkdir(CFG.outDir, { recursive: true });
  const cachePath = path.join(CFG.outDir, 'cache.jsonl');
  const cache = new Map();
  try {
    for (const line of (await fs.readFile(cachePath, 'utf8')).split('\n')) {
      if (line.trim()) { const o = JSON.parse(line); cache.set(o.k, o.v); }
    }
    if (cache.size) console.log(`Cache: ${cache.size} Urteile übernommen.`);
  } catch { /* kein Cache */ }

  // Stufe 1
  const results = new Map();
  const offen = [];
  for (const t of tasks) {
    const key = `${t.id}:${hash(t.question)}`;
    if (cache.has(key)) { results.set(t.id, cache.get(key)); continue; }
    const r = ruleClassify(t);
    if (r) results.set(t.id, r); else offen.push(t);
  }
  console.log(`Stufe 1: ${tasks.length - offen.length - 0} entschieden, ${offen.length} offen.`);

  // Stufe 2
  if (offen.length && !flag('no-llm')) {
    if (!CFG.anthropicKey) { console.error('ANTHROPIC_API_KEY fehlt (oder --no-llm nutzen).'); process.exit(1); }
    const batches = [];
    for (let i = 0; i < offen.length; i += CFG.batchSize) batches.push(offen.slice(i, i + CFG.batchSize));
    console.log(`Stufe 2: ${batches.length} Batches à ${CFG.batchSize}, Modell ${CFG.model}\n`);

    let done = 0;
    const cacheOut = [];
    const all = await pool(batches, CFG.concurrency, async (b) => {
      const r = await llmBatch(b);
      done++;
      process.stdout.write(`\r  ${done}/${batches.length} Batches`);
      return r;
    });
    process.stdout.write('\n\n');

    batches.forEach((b, bi) => b.forEach((t, ti) => {
      const v = all[bi][ti];
      results.set(t.id, v);
      cacheOut.push(JSON.stringify({ k: `${t.id}:${hash(t.question)}`, v }));
    }));
    await fs.appendFile(cachePath, cacheOut.join('\n') + '\n');
  } else if (offen.length) {
    for (const t of offen) results.set(t.id, { bedarf: 'unklar', figur: null, quelle: 'übersprungen', grund: '--no-llm' });
  }

  // Ausgabe
  const out = tasks.map((t) => {
    const r = results.get(t.id) ?? {};
    return {
      id: t.id, skill: t.skill, status: t.status, input_type: t.inputType, afb: t.afb,
      bedarf: r.bedarf, figur: r.figur, quelle: r.quelle,
      dangling: r.dangling === true, grund: r.grund,
      frage: t.question.slice(0, 400),
    };
  });

  await fs.writeFile(path.join(CFG.outDir, 'bildbedarf.json'), JSON.stringify(out, null, 2));
  const head = ['id','skill','status','input_type','afb','bedarf','figur','quelle','dangling','grund','frage'];
  await fs.writeFile(path.join(CFG.outDir, 'bildbedarf.csv'),
    '\uFEFF' + [head.join(';'), ...out.map((r) => head.map((h) => csvCell(r[h])).join(';'))].join('\n'));

  if (flag('sql')) {
    const esc = (s) => String(s ?? '').replace(/'/g, "''");
    const sql = [
      '-- erzeugt von bildbedarf.mjs, read-only Analyse. Nach supabase/pending/ legen.',
      'create table if not exists task_bildbedarf (',
      '  task_id     bigint primary key,',
      "  bedarf      text not null check (bedarf in ('konstitutiv','stuetze','keine','hat_bild','unklar')),",
      '  figur       text,', '  quelle      text,', '  grund       text,',
      '  bewertet_am timestamptz not null default now()', ');', '',
      ...out.map((r) => `insert into task_bildbedarf (task_id,bedarf,figur,quelle,grund) values (${r.id},'${esc(r.bedarf)}',${r.figur ? `'${esc(r.figur)}'` : 'null'},'${esc(r.quelle)}','${esc(r.grund)}') on conflict (task_id) do update set bedarf=excluded.bedarf, figur=excluded.figur, quelle=excluded.quelle, grund=excluded.grund, bewertet_am=now();`),
    ].join('\n');
    await fs.writeFile(path.join(CFG.outDir, 'bildbedarf.sql'), sql);
  }

  // Zusammenfassung
  const K = ['konstitutiv','stuetze','keine','hat_bild','unklar'];
  const bySkill = new Map();
  for (const r of out) {
    const s = bySkill.get(r.skill) ?? { n: 0, konstitutiv: 0, stuetze: 0, keine: 0, hat_bild: 0, unklar: 0 };
    s.n++; if (r.bedarf in s) s[r.bedarf]++;
    bySkill.set(r.skill, s);
  }

  console.log('Bildbedarf je Skill (nach konstitutiv sortiert)\n');
  console.log(`${'skill'.padEnd(34)}${'n'.padStart(5)}${'konst'.padStart(8)}${'stütze'.padStart(8)}${'keine'.padStart(8)}${'hat'.padStart(6)}${'unklar'.padStart(8)}`);
  console.log('─'.repeat(77));
  for (const [skill, s] of [...bySkill].sort((a, b) => b[1].konstitutiv - a[1].konstitutiv || b[1].n - a[1].n)) {
    console.log(`${skill.slice(0,33).padEnd(34)}${String(s.n).padStart(5)}${String(s.konstitutiv).padStart(8)}${String(s.stuetze).padStart(8)}${String(s.keine).padStart(8)}${String(s.hat_bild).padStart(6)}${String(s.unklar).padStart(8)}`);
  }

  const tot = K.reduce((a, k) => ({ ...a, [k]: out.filter((r) => r.bedarf === k).length }), {});
  console.log('─'.repeat(77));
  console.log(`${'GESAMT'.padEnd(34)}${String(out.length).padStart(5)}${String(tot.konstitutiv).padStart(8)}${String(tot.stuetze).padStart(8)}${String(tot.keine).padStart(8)}${String(tot.hat_bild).padStart(6)}${String(tot.unklar).padStart(8)}`);

  const figuren = new Map();
  for (const r of out) if (r.bedarf === 'konstitutiv' && r.figur) figuren.set(r.figur, (figuren.get(r.figur) ?? 0) + 1);
  if (figuren.size) {
    console.log('\nBenötigte Figurtypen (nur konstitutiv):');
    for (const [f, n] of [...figuren].sort((a, b) => b[1] - a[1])) console.log(`  ${String(n).padStart(4)}  ${f}`);
  }

  const dangling = out.filter((r) => r.dangling);
  if (dangling.length) {
    console.log(`\n⚠  ${dangling.length} Aufgaben verweisen auf eine Abbildung, die nicht hinterlegt ist.`);
    console.log('   Das sind kaputte Items, nicht Wunschbedarf — vor der Freigabe klären.');
    for (const r of dangling.slice(0, 15)) console.log(`   ${String(r.id).padStart(6)}  ${r.skill.slice(0,24).padEnd(25)} ${r.frage.slice(0, 60)}…`);
    if (dangling.length > 15) console.log(`   … und ${dangling.length - 15} weitere (vollständig in der CSV)`);
  }

  console.log(`\nGeschrieben nach ${path.resolve(CFG.outDir)}/ — bildbedarf.csv, bildbedarf.json${flag('sql') ? ', bildbedarf.sql' : ''}`);
}

main().catch((e) => { console.error(e); process.exit(1); });
