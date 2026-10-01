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
 * Zwei Quellen (siehe verify-tasks-quellen.mjs):
 *   --quelle prod            Produktion. Vorgabe, bestehende Aufrufe bleiben gleich.
 *   --quelle datei --pfad x  JSON-Datei. Prüft eine Charge VOR dem Einspielen —
 *                            der Fall, für den das Werkzeug gebaut wurde und den
 *                            es bis hierher als einziges nicht konnte.
 *
 * Als Gate in einer Spec:
 *     gates:
 *       - node tools/verify-tasks.mjs --skill bruch_add --min-pass 0.95
 *
 *   node tools/verify-tasks.mjs --skill <skill>       [--min-pass 0.95]
 *   node tools/verify-tasks.mjs --seit 2026-07-28     # alles seit einem Datum
 *   node tools/verify-tasks.mjs --status draft --source edvance_fundament
 *   node tools/verify-tasks.mjs --nur-struktur        # ohne LLM, kostenlos
 *   node tools/verify-tasks.mjs --quelle datei --pfad out/k8-charge.json
 *   node tools/verify-tasks.mjs --from-file docs/prefill/k8-vorlauf.json   # Charge-Format
 *   node tools/verify-tasks.mjs --from-file <charge.json> --answers-from <antworten.json>
 *
 * --answers-from ersetzt den API-Loeser: Antworten eines Subagenten (tools/blind-loeser/),
 * gewertet wie lsa_is_correct, dazu acceptance-Toleranz wie lsa_grade (gemeldet).
 *
 * --from-file liest eine Charge im Format von docs/prefill/<batch>.json (vorlauf-build.mjs)
 * und prueft sie mit Stufe 1 und Blindloeser, bevor sie eingespielt ist. MULTI_PART: der
 * Loeser bekommt die Teilprompts und antwortet "x;y" in Teil-Reihenfolge; verglichen wird
 * je Teil gegen dessen Varianten.
 *
 * Vorbefuellung fuer Lenas Pruefung (siehe verify-prefill.mjs) — ohne LLM, ohne DB:
 *   node tools/verify-tasks.mjs --prefill docs/prefill/<charge>.json \
 *        --snapshot docs/prefill/<charge>-snapshot.json [--migration <datei.sql>]
 *        [--blind <loeser.json>] [--bericht <datei.md>]
 *   Scheitert u. a., sobald eine Prefill-Migration eine VERA8-Aufgabe anfassen koennte.
 */

import fs from 'node:fs/promises';
import { ausCharge, ausDatei, ausProduktion, filtere, QuellenFehler } from './verify-tasks-quellen.mjs';

// Node liest .env nicht von selbst — ohne das hier fehlten SUPABASE_URL und
// ANTHROPIC_API_KEY jedem Aufruf, der die Variablen nicht vorher exportiert hat.
// Bereits gesetzte Werte gewinnen (loadEnvFile überschreibt nicht), die Umgebung
// bleibt also stärker als die Datei.
try { process.loadEnvFile('.env'); } catch { /* keine .env — dann eben nur echte Umgebung */ }

const CFG = {
  url: process.env.SUPABASE_URL,
  key: process.env.SUPABASE_SERVICE_ROLE_KEY,
  anthropic: process.env.ANTHROPIC_API_KEY,
  // Standard-Variable des Anthropic-SDK. Erlaubt, den Prüfer im Test gegen einen
  // lokalen Löser laufen zu lassen, ohne den Prüfkern anzufassen.
  apiBase: (process.env.ANTHROPIC_BASE_URL ?? 'https://api.anthropic.com').replace(/\/+$/, ''),
  model: process.env.VERIFY_MODEL ?? 'claude-sonnet-5',
  batch: 10,
  parallel: 4,
};

const A = process.argv.slice(2);
const flag = (n) => A.includes(`--${n}`);
const opt = (n, d) => { const i = A.indexOf(`--${n}`); return i === -1 ? d : A[i + 1]; };
const MIN_PASS = Number(opt('min-pass', '0.95'));

if (flag('prefill')) {
  const { pruefePrefill } = await import('./verify-prefill.mjs');
  const r = await pruefePrefill({
    charge: opt('prefill'), snapshot: opt('snapshot'), blind: opt('blind'), migration: opt('migration'),
  });
  console.log(r.bericht);
  if (opt('bericht')) await fs.writeFile(opt('bericht'), r.bericht);
  process.exit(r.fehler.length ? 1 : 0);
}

// ─── Aufgaben laden ──────────────────────────────────────────────────────────

const QUELLE = flag('from-file') ? 'charge' : opt('quelle', 'prod');
if (QUELLE !== 'prod' && QUELLE !== 'datei' && QUELLE !== 'charge') {
  console.error(`--quelle kennt nur "prod" oder "datei", nicht "${QUELLE}".`);
  process.exit(2);
}

const FILTER = { skill: opt('skill'), status: opt('status'), source: opt('source'), seit: opt('seit') };

let tasks, loesungVon, herkunft;
try {
  if (QUELLE === 'datei' || QUELLE === 'charge') {
    const pfad = QUELLE === 'charge' ? opt('from-file') : opt('pfad');
    ({ tasks, loesungVon } = await (QUELLE === 'charge' ? ausCharge(pfad) : ausDatei(pfad)));
    tasks = filtere(tasks, FILTER);
    herkunft = pfad;
  } else {
    if (!CFG.url || !CFG.key) {
      console.error('SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY fehlen (oder --quelle datei nutzen).');
      process.exit(2);
    }
    // Dynamisch: --prefill und --quelle datei laufen so auch ohne node_modules.
    const { createClient } = await import('@supabase/supabase-js');
    const sb = createClient(CFG.url, CFG.key, { auth: { persistSession: false } });
    ({ tasks, loesungVon } = await ausProduktion(sb, FILTER));
    herkunft = 'Produktion';
  }
} catch (e) {
  console.error(e instanceof QuellenFehler ? e.message : `Ladefehler: ${e.message}`);
  process.exit(2);
}

if (!tasks.length) { console.error('Keine Aufgabe passt auf die Auswahl.'); process.exit(2); }

console.log(`\n  ${tasks.length} Aufgabe(n) zu prüfen — Quelle: ${herkunft}\n`);
const mitBild = tasks.filter((t) => t.needs_image === true).length;
if (mitBild && !flag('answers-from')) {
  console.log(`  Hinweis: ${mitBild} Aufgabe(n) brauchen eine Abbildung. Stufe 2 schickt nur den Text —`);
  console.log('           dort ist "mehrdeutig" das erwartbare Urteil, kein Inhaltsfehler.\n');
}

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
    const leerObjekt = antworten && typeof antworten === 'object' && !Array.isArray(antworten)
      && !Object.values(antworten).some((v) => Array.isArray(v) && v.length);
    if (antworten == null || (Array.isArray(antworten) && !antworten.length) || leerObjekt) {
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

// Ohne API: Antworten eines Blind-Loesers (Subagent, tools/blind-loeser/AUFTRAG.md),
// deterministisch gewertet wie im Schuelerpfad (tools/blind-loeser/bewertung.mjs).
// Format: [{task_id, part?, antwort, unsicher?: 'ja'|'nein'}]. Kein Netz, kein Schluessel.
if (flag('answers-from')) {
  const pfad = opt('answers-from');
  let roh;
  try {
    roh = JSON.parse(await fs.readFile(pfad, 'utf8'));
  } catch (e) {
    console.error(`--answers-from: ${pfad} nicht lesbar (${e.code ?? e.message})`);
    process.exit(2);
  }
  if (!Array.isArray(roh)) {
    console.error(`--answers-from: ${pfad} muss ein Array [{task_id, part?, antwort}] sein.`);
    process.exit(2);
  }
  const { bewerteAufgabe } = await import('./blind-loeser/bewertung.mjs');
  const nachAufgabe = new Map();
  for (const r of roh) {
    const id = String(r?.task_id ?? '').trim();
    if (!id) continue;
    if (!nachAufgabe.has(id)) nachAufgabe.set(id, []);
    nachAufgabe.get(id).push({ part: r.part ?? null, antwort: r.antwort, unsicher: r.unsicher });
  }
  console.log(`\n  Rechnung:  Blind-Antworten aus ${pfad} — kein API-Aufruf`);
  for (const t of tasks) {
    const b = befund.get(t.id);
    // Ohne Antwort: leere Liste → "keine Blind-Antwort" (ungeprueft), nicht stilles Weglassen.
    const antworten = nachAufgabe.get(String(t.id)) ?? [];
    if (b.struktur.length) continue;
    b.rechnung = { eindeutig: true, bewertung: bewerteAufgabe(t, loesungVon.get(t.id), antworten) };
  }
  const fremd = [...nachAufgabe.keys()].filter((id) => !befund.has(id));
  if (fremd.length) console.log(`  Hinweis: ${fremd.length} Antwort(en) passen zu keiner geprüften Aufgabe (${fremd.slice(0, 3).join(', ')}…)`);
  const quote = await bericht();
  process.exit(quote >= MIN_PASS ? 0 : 1);
}

if (!CFG.anthropic) {
  console.error(`
  ANTHROPIC_API_KEY ist nicht gesetzt — Stufe 2 bricht ab, es geht kein API-Aufruf raus.

  Stufe 2 (blind nachrechnen) ist der eigentliche Prüfer. Ohne Schlüssel:

    1. node tools/blind-loeser/exportiere.mjs <charge.json> <ordner>
    2. Subagent mit tools/blind-loeser/AUFTRAG.md lösen lassen → <antworten.json>
    3. --answers-from <antworten.json>          (siehe tools/blind-loeser/README.md)

  Oder:  --nur-struktur   (Stufe 1 allein)
`);
  process.exit(2);
}

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
      const res = await fetch(`${CFG.apiBase}/v1/messages`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-api-key': CFG.anthropic,
                   'anthropic-version': '2023-06-01' },
        body: JSON.stringify({ model: CFG.model, max_tokens: 3000, system,
                               messages: [{ role: 'user', content: inhalt }] }),
      });
      if (res.status === 401 || res.status === 403) {
        // Nicht wiederholen und nicht als Aufgabenbefund verbuchen: ohne gültigen
        // Schlüssel bliebe jede Aufgabe "ungeprueft" und die Trefferquote fiele auf
        // 0 % — das sähe aus wie schlechter Inhalt und ist ein Zugangsproblem.
        console.error(`
  ANTHROPIC_API_KEY wird abgelehnt (HTTP ${res.status}).

  Der Schlüssel ist gesetzt, aber ungültig oder ohne Berechtigung. Der Prüfer bricht
  hier ab, statt jede Aufgabe als "ungeprueft" zu zählen — eine Trefferquote von 0 %
  würde sonst wie ein Inhaltsfehler aussehen.

  Gültigen Schlüssel hinterlegen oder --nur-struktur nutzen.
`);
        process.exit(2);
      }
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
  // MULTI_PART: correct_answers = {"1": [...], "2": [...]}; der Loeser antwortet "a;b" in
  // Teil-Reihenfolge. Jeder Teil muss gegen SEINE Varianten stimmen.
  if (erwartet && typeof erwartet === 'object' && !Array.isArray(erwartet)) {
    const teile = Object.keys(erwartet).sort((a, b) => Number(a) - Number(b));
    const seine = String(bekommen ?? '').split(';');
    return seine.length === teile.length && teile.every((k, i) => stimmtUeberein(erwartet[k], seine[i]));
  }
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
  const nurToleranz = [], unsicher = [];

  for (const t of tasks) {
    const b = befund.get(t.id);
    const s = loesungVon.get(t.id);
    let urteil, detail = '';

    if (b.struktur.length) {
      urteil = 'struktur'; detail = b.struktur.join('; '); unpruefbar++;
    } else if (!b.rechnung) {
      urteil = 'ungeprueft'; detail = 'kein Urteil vom Prüfer'; unpruefbar++;
    } else if (b.rechnung.bewertung) {
      const w = b.rechnung.bewertung;
      const erwartet = s?.correct_answers;
      if (w.ok) {
        urteil = 'ok'; ok++;
        if (w.nurToleranz) nurToleranz.push(`${t.id}: ${w.anzeige} — nur über acceptance (lsa_grade); lsa_is_correct wertet falsch`);
      } else if (w.falsch.length) {
        urteil = 'abweichung'; falsch++;
        detail = `hinterlegt: ${JSON.stringify(erwartet)} · Blind-Löser: ${w.anzeige}`;
      } else {
        urteil = 'ungeprueft'; unpruefbar++;
        detail = `keine Blind-Antwort${w.fehlt[0] == null ? '' : ` für Teil ${w.fehlt.join(', ')}`}`;
      }
      if (w.unsicher) unsicher.push(`${t.id} (${urteil})`);
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

  if (nurToleranz.length) {
    console.log(`\n  Nur über Toleranz/equivalents richtig — ${nurToleranz.length} (lsa_responses.correct wäre false):`);
    for (const z of nurToleranz.slice(0, 10)) console.log(`    ${z}`);
  }
  if (unsicher.length) {
    console.log(`\n  Blind-Löser unsicher — ${unsicher.length} (kein Gate, bitte ansehen):`);
    for (const z of unsicher.slice(0, 10)) console.log(`    ${z}`);
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
