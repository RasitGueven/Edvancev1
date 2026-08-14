#!/usr/bin/env node
/**
 * verify-tasks.mjs — prüft generierte Aufgaben unabhängig vom Generator.
 *
 * Das Prinzip: der Prüfer sieht die hinterlegte Lösung NICHT. Er bekommt nur den
 * Aufgabentext, rechnet selbst, und erst danach wird verglichen. Ein Modell, das
 * seine eigene Ausgabe beurteilen soll, winkt seine eigenen Fehler durch — es
 * müsste sich dafür widersprechen. Ein Modell, das die Aufgabe blind löst, kann
 * das nicht.
 *
 * Drei Stufen:
 *   1. Struktur    (kostenlos)  Lösung vorhanden, Skill gesetzt, Antwortformat gültig
 *   2. Rechnung    (LLM)        Aufgabe blind lösen, dann mit der Lösung vergleichen
 *   3. Plausibilität (LLM)      Sind Kontext und Zahlen realistisch? Nur Bericht, kein Gate.
 *
 * Als Gate in einer Spec:
 *     gates:
 *       - node tools/verify-tasks.mjs --skill bruch_add --min-pass 0.95
 *
 *   node tools/verify-tasks.mjs --skill <skill>       [--min-pass 0.95]
 *   node tools/verify-tasks.mjs --seit 2026-07-28     # alles seit einem Datum
 *   node tools/verify-tasks.mjs --status draft --source edvance_fundament
 *   node tools/verify-tasks.mjs --nur-struktur        # ohne LLM, kostenlos
 */

import { createClient } from '@supabase/supabase-js';
import fs from 'node:fs/promises';

const CFG = {
  url: process.env.SUPABASE_URL,
  key: process.env.SUPABASE_SERVICE_ROLE_KEY,
  anthropic: process.env.ANTHROPIC_API_KEY,
  model: process.env.VERIFY_MODEL ?? 'claude-sonnet-5',
  batch: 10,
  parallel: 4,
};

const A = process.argv.slice(2);
const flag = (n) => A.includes(`--${n}`);
const opt = (n, d) => { const i = A.indexOf(`--${n}`); return i === -1 ? d : A[i + 1]; };
const MIN_PASS = Number(opt('min-pass', '0.95'));

if (!CFG.url || !CFG.key) { console.error('SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY fehlen.'); process.exit(2); }

const sb = createClient(CFG.url, CFG.key, { auth: { persistSession: false } });

// ─── Aufgaben laden ──────────────────────────────────────────────────────────

let q = sb.from('tasks').select('id,question,skill_key,input_type,status,source,unit,created_at');
if (opt('skill'))  q = q.eq('skill_key', opt('skill'));
if (opt('status')) q = q.eq('status', opt('status'));
if (opt('source')) q = q.eq('source', opt('source'));
if (opt('seit'))   q = q.gte('created_at', opt('seit'));

const { data: tasks, error } = await q;
if (error) { console.error(`Ladefehler: ${error.message}`); process.exit(2); }
if (!tasks?.length) { console.error('Keine Aufgabe passt auf die Auswahl.'); process.exit(2); }

const ids = tasks.map((t) => t.id);
const { data: loesungen } = await sb.from('task_solutions').select('*').in('task_id', ids);
const loesungVon = new Map((loesungen ?? []).map((s) => [s.task_id, s]));

console.log(`\n  ${tasks.length} Aufgabe(n) zu prüfen\n`);

// ─── Stufe 1 · Struktur ──────────────────────────────────────────────────────

const text = (v) => {
  if (v == null) return '';
  if (typeof v === 'string') return v;
  const teile = [];
  (function walk(n) {
    if (typeof n === 'string') teile.push(n);
    else if (Array.isArray(n)) n.forEach(walk);
    else if (n && typeof n === 'object') Object.values(n).forEach(walk);
  })(v);
  return teile.join(' ');
};

const befund = new Map();   // id -> { struktur:[], rechnung, plausibel }
const gesehen = new Set();

for (const t of tasks) {
  const m = [];
  const s = loesungVon.get(t.id);

  if (!s) m.push('keine Lösung hinterlegt');
  if (!t.skill_key) m.push('kein skill_key — wird nie gezogen');
  if (!text(t.question).trim()) m.push('leerer Aufgabentext');

  if (s) {
    const antworten = s.correct_answers ?? s.correct_answer ?? null;
    if (antworten == null || (Array.isArray(antworten) && !antworten.length)) {
      m.push('Lösung ohne Antwortwert');
    }
    if (s.acceptance && typeof s.acceptance === 'object') {
      const acc = s.acceptance;
      if ('require_reduced' in acc && typeof acc.require_reduced !== 'boolean') {
        m.push('require_reduced ist nicht boolesch');
      }
    }
  }

  const schluessel = text(t.question).toLowerCase().replace(/\s+/g, ' ').trim();
  if (gesehen.has(schluessel)) m.push('wortgleiche Dublette');
  gesehen.add(schluessel);

  befund.set(t.id, { struktur: m, rechnung: null, plausibel: null });
}

const strukturFehler = [...befund.values()].filter((b) => b.struktur.length).length;
console.log(`  Struktur:  ${tasks.length - strukturFehler} ok, ${strukturFehler} beanstandet`);

if (flag('nur-struktur')) {
  await bericht();
  process.exit(strukturFehler ? 1 : 0);
}

// ─── Stufe 2 · Blind lösen ───────────────────────────────────────────────────

if (!CFG.anthropic) { console.error('\nANTHROPIC_API_KEY fehlt (oder --nur-struktur nutzen).'); process.exit(2); }

const SYSTEM_LOESEN = `Du bist Mathematiklehrer und löst Aufgaben für Klasse 5 bis 7.

Du bekommst nur den Aufgabentext. Löse jede Aufgabe selbst und sorgfältig.

Gib zu jeder Aufgabe an:
- "antwort": das Ergebnis, so knapp wie möglich. Zahl als Zahl (Dezimaltrennzeichen ist der Punkt),
  Bruch als "3/4", mehrere Werte durch Semikolon getrennt. Keine Einheit, keine Erklärung,
  kein Satz — nur der Wert.
- "eindeutig": false, wenn die Aufgabe mehrdeutig, unlösbar oder unvollständig ist, sonst true.
- "anmerkung": nur bei eindeutig=false ein Satz dazu, was fehlt. Sonst "".

Wenn eine Aufgabe fehlerhaft ist, sag das über eindeutig=false. Rate nicht.

Antworte AUSSCHLIESSLICH mit einem JSON-Array in derselben Reihenfolge, ohne Markdown-Fences:
[{"id":"<id>","antwort":"<wert>","eindeutig":true,"anmerkung":""}]`;

const SYSTEM_PLAUSIBEL = `Du prüfst Mathematikaufgaben für Klasse 5 bis 7 auf Realitätsnähe.

Nicht die Rechnung — nur den Kontext. Achte auf:
- unrealistische Mengen ("47,3 Brötchen", "ein Auto wiegt 3 kg")
- Sachverhalte, die ein Kind dieser Stufe nicht kennt
- Personen oder Situationen, die unpassend, klischeehaft oder befremdlich wirken
- Zahlen, die rechnerisch gehen, in der Sache aber unsinnig sind

Antworte AUSSCHLIESSLICH mit einem JSON-Array, ohne Markdown-Fences:
[{"id":"<id>","ok":true,"einwand":""}]`;

async function llm(system, inhalt) {
  for (let versuch = 1; versuch <= 4; versuch++) {
    try {
      const res = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-api-key': CFG.anthropic,
                   'anthropic-version': '2023-06-01' },
        body: JSON.stringify({ model: CFG.model, max_tokens: 3000, system,
                               messages: [{ role: 'user', content: inhalt }] }),
      });
      if (res.status === 429 || res.status >= 500) throw new Error(`HTTP ${res.status}`);
      if (!res.ok) throw new Error(`HTTP ${res.status}: ${(await res.text()).slice(0, 200)}`);
      const data = await res.json();
      const roh = data.content.filter((c) => c.type === 'text').map((c) => c.text).join('\n');
      return JSON.parse(roh.replace(/```json/gi, '').replace(/```/g, '').trim());
    } catch (e) {
      if (versuch === 4) { console.error(`  Batch gescheitert: ${e.message}`); return []; }
      await new Promise((r) => setTimeout(r, 1200 * versuch ** 2));
    }
  }
}

// Wichtig: die hinterlegte Lösung wird NICHT mitgeschickt.
const pruefbar = tasks.filter((t) => !befund.get(t.id).struktur.length);
const batches = [];
for (let i = 0; i < pruefbar.length; i += CFG.batch) batches.push(pruefbar.slice(i, i + CFG.batch));

async function pool(items, n, fn) {
  let i = 0;
  await Promise.all(Array.from({ length: Math.min(n, items.length) }, async () => {
    while (i < items.length) { const k = i++; await fn(items[k]); }
  }));
}

console.log(`\n  Rechnung:  ${batches.length} Batch(es), Modell ${CFG.model}`);
let fertig = 0;
await pool(batches, CFG.parallel, async (b) => {
  const inhalt = b.map((t) => `--- id: ${t.id}\n${text(t.question)}`).join('\n\n');
  const r = await llm(SYSTEM_LOESEN, inhalt);
  const byId = new Map(r.map((x) => [String(x.id), x]));
  for (const t of b) befund.get(t.id).rechnung = byId.get(String(t.id)) ?? null;
  process.stdout.write(`\r             ${++fertig}/${batches.length}`);
});
process.stdout.write('\n');

// ─── Vergleichen ─────────────────────────────────────────────────────────────

const norm = (v) => String(v ?? '')
  .toLowerCase().replace(',', '.').replace(/\s+/g, '')
  .replace(/^[+]/, '').replace(/[€%]|cm2|cm²|m2|m²/g, '');

function stimmtUeberein(erwartet, bekommen) {
  const e = Array.isArray(erwartet) ? erwartet : [erwartet];
  const b = norm(bekommen);
  for (const x of e) {
    const n = norm(text(x));
    if (n === b) return true;
    const za = Number(n), zb = Number(b);
    if (Number.isFinite(za) && Number.isFinite(zb) && Math.abs(za - zb) < 1e-6) return true;
    // Bruch gegen Dezimal
    const bruch = (s) => { const m = s.match(/^(-?\d+)\/(\d+)$/); return m ? Number(m[1]) / Number(m[2]) : NaN; };
    const fa = bruch(n), fb = bruch(b);
    if (Number.isFinite(fa) && Number.isFinite(zb) && Math.abs(fa - zb) < 1e-6) return true;
    if (Number.isFinite(fb) && Number.isFinite(za) && Math.abs(fb - za) < 1e-6) return true;
    if (Number.isFinite(fa) && Number.isFinite(fb) && Math.abs(fa - fb) < 1e-6) return true;
  }
  return false;
}

// ─── Plausibilität (nur Bericht) ─────────────────────────────────────────────

if (!flag('ohne-plausibel')) {
  console.log(`\n  Plausibilität: ${batches.length} Batch(es)`);
  fertig = 0;
  await pool(batches, CFG.parallel, async (b) => {
    const inhalt = b.map((t) => `--- id: ${t.id}\n${text(t.question)}`).join('\n\n');
    const r = await llm(SYSTEM_PLAUSIBEL, inhalt);
    const byId = new Map(r.map((x) => [String(x.id), x]));
    for (const t of b) befund.get(t.id).plausibel = byId.get(String(t.id)) ?? null;
    process.stdout.write(`\r                 ${++fertig}/${batches.length}`);
  });
  process.stdout.write('\n');
}

// ─── Bericht ─────────────────────────────────────────────────────────────────

async function bericht() {
  const zeilen = [];
  let ok = 0, falsch = 0, mehrdeutig = 0, unpruefbar = 0;

  for (const t of tasks) {
    const b = befund.get(t.id);
    const s = loesungVon.get(t.id);
    let urteil, detail = '';

    if (b.struktur.length) {
      urteil = 'struktur'; detail = b.struktur.join('; '); unpruefbar++;
    } else if (!b.rechnung) {
      urteil = 'ungeprueft'; detail = 'kein Urteil vom Prüfer'; unpruefbar++;
    } else if (b.rechnung.eindeutig === false) {
      urteil = 'mehrdeutig'; detail = b.rechnung.anmerkung || 'Prüfer hält die Aufgabe für unklar';
      mehrdeutig++;
    } else {
      const erwartet = s?.correct_answers ?? s?.correct_answer;
      if (stimmtUeberein(erwartet, b.rechnung.antwort)) { urteil = 'ok'; ok++; }
      else {
        urteil = 'abweichung';
        detail = `hinterlegt: ${JSON.stringify(erwartet)} · Prüfer: ${b.rechnung.antwort}`;
        falsch++;
      }
    }

    const einwand = b.plausibel && b.plausibel.ok === false ? b.plausibel.einwand : '';
    zeilen.push({ id: t.id, skill: t.skill_key ?? '', urteil, detail, einwand,
                  frage: text(t.question).slice(0, 200) });
  }

  await fs.mkdir('out', { recursive: true });
  const kopf = ['id','skill','urteil','detail','einwand','frage'];
  await fs.writeFile('out/verify-tasks.csv',
    '\uFEFF' + [kopf.join(';'),
      ...zeilen.map((z) => kopf.map((k) => `"${String(z[k] ?? '').replace(/"/g,'""').replace(/\n/g,' ')}"`).join(';'))
    ].join('\n'));

  const quote = tasks.length ? ok / tasks.length : 0;

  console.log('\n  ────────────────────────────────────');
  console.log(`  ok            ${String(ok).padStart(5)}`);
  console.log(`  abweichung    ${String(falsch).padStart(5)}   ← Lösung stimmt nicht`);
  console.log(`  mehrdeutig    ${String(mehrdeutig).padStart(5)}   ← Aufgabe unklar gestellt`);
  console.log(`  nicht prüfbar ${String(unpruefbar).padStart(5)}`);
  console.log('  ────────────────────────────────────');
  console.log(`  Trefferquote  ${(quote * 100).toFixed(1)} %   (verlangt ${(MIN_PASS * 100).toFixed(1)} %)`);

  const schlecht = zeilen.filter((z) => z.urteil !== 'ok');
  if (schlecht.length) {
    console.log('\n  Beanstandet:');
    for (const z of schlecht.slice(0, 20)) {
      console.log(`    ${z.urteil.padEnd(11)} ${z.skill.slice(0,22).padEnd(23)} ${z.detail.slice(0, 70)}`);
      console.log(`                ${z.frage.slice(0, 90)}`);
    }
    if (schlecht.length > 20) console.log(`    … und ${schlecht.length - 20} weitere`);
  }

  const einwaende = zeilen.filter((z) => z.einwand);
  if (einwaende.length) {
    console.log(`\n  Plausibilität — ${einwaende.length} Einwand/Einwände (kein Gate):`);
    for (const z of einwaende.slice(0, 10)) console.log(`    ${z.einwand.slice(0, 100)}`);
  }

  console.log('\n  Vollständig: out/verify-tasks.csv\n');
  return quote;
}

const quote = await bericht();
process.exit(quote >= MIN_PASS ? 0 : 1);
