#!/usr/bin/env node
/**
 * orch.mjs — Spec-getriebener Orchestrator, Teil 1 (Code-Jobs).
 *
 *   node orchestrator/orch.mjs list
 *   node orchestrator/orch.mjs run <spec-id> [--dry-run] [--attempts 3]
 *   node orchestrator/orch.mjs run --all
 *   node orchestrator/orch.mjs clean <spec-id>      # Worktree entfernen
 *
 * Ablauf je Spec: validieren → Worktree → claude -p → Gates → bei rot Retry mit
 * Fehlerausgabe im Kontext → bei grün commit + push + PR. Merged nie.
 */

import fs from 'node:fs/promises';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '..');
const SPECS = path.join(ROOT, 'specs', 'active');
const DONE = path.join(ROOT, 'specs', 'done');
const STATE = path.join(ROOT, 'state');
const WORKTREES = path.join(ROOT, '.worktrees');

const ARGV = process.argv.slice(2);
const CMD = ARGV[0];
const flag = (n) => ARGV.includes(`--${n}`);
const opt = (n, d) => { const i = ARGV.indexOf(`--${n}`); return i === -1 ? d : ARGV[i + 1]; };

const MAX_ATTEMPTS = Number(opt('attempts', 3));

// ─── Prozess-Helfer ──────────────────────────────────────────────────────────

function sh(cmd, { cwd = ROOT, quiet = false, env = {} } = {}) {
  return new Promise((resolve) => {
    const p = spawn('bash', ['-lc', cmd], { cwd, env: { ...process.env, ...env } });
    let out = '', err = '';
    p.stdout.on('data', (d) => { out += d; if (!quiet) process.stdout.write(d); });
    p.stderr.on('data', (d) => { err += d; if (!quiet) process.stderr.write(d); });
    p.on('close', (code) => resolve({ code, out, err, combined: out + err }));
  });
}

const log = (...a) => console.log(...a);
const fail = (m) => { console.error(`✗ ${m}`); process.exit(1); };

// ─── Spec parsen ─────────────────────────────────────────────────────────────

function parseFrontmatter(raw) {
  const m = raw.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n([\s\S]*)$/);
  if (!m) return null;
  const meta = {};
  let key = null;
  for (const line of m[1].split(/\r?\n/)) {
    if (!line.trim() || line.trim().startsWith('#')) continue;
    const item = line.match(/^\s+-\s+(.*)$/);
    if (item && key) { (meta[key] ||= []).push(item[1].trim()); continue; }
    const kv = line.match(/^([A-Za-z_][\w-]*):\s*(.*)$/);
    if (!kv) continue;
    key = kv[1];
    const v = kv[2].trim();
    if (v === '' ) meta[key] = [];
    else if (v === '[]') meta[key] = [];
    else if (v.startsWith('[')) meta[key] = v.slice(1, -1).split(',').map((s) => s.trim().replace(/^["']|["']$/g, '')).filter(Boolean);
    else meta[key] = v.replace(/^["']|["']$/g, '');
  }
  return { meta, body: m[2].trim() };
}

async function loadSpec(id) {
  const file = path.join(SPECS, `${id}.md`);
  let raw;
  try { raw = await fs.readFile(file, 'utf8'); }
  catch { fail(`Spec nicht gefunden: ${file}`); }

  const parsed = parseFrontmatter(raw);
  if (!parsed) fail(`${id}: kein gültiges Frontmatter (--- ... ---).`);
  const { meta, body } = parsed;

  // Validierung — hier wird abgelehnt, nicht gewarnt.
  const problems = [];
  if (!meta.id) problems.push('id fehlt');
  if (meta.id && meta.id !== id) problems.push(`id "${meta.id}" ≠ Dateiname "${id}"`);
  if (!meta.type) problems.push('type fehlt');
  if (meta.type && !['code', 'content'].includes(meta.type)) problems.push(`type "${meta.type}" unbekannt`);

  if (!meta.repo) problems.push('repo fehlt');
  if (!Array.isArray(meta.gates) || meta.gates.length === 0) {
    problems.push(
      'gates fehlt oder ist leer.\n' +
      '    Eine Spec ohne ausführbares Gate wird nicht angenommen. Woran erkennt die\n' +
      '    Maschine, dass diese Arbeit fertig ist? Beispiele:\n' +
      '      gates:\n        - npm run typecheck\n        - npm test -- <muster>\n        - scripts/check-migration-drift.sh'
    );
  }
  if (body.length < 80) problems.push('Body zu dünn — Ziel, Kontext, Akzeptanz, Nicht-Ziele beschreiben.');

  if (problems.length) {
    console.error(`✗ Spec "${id}" abgelehnt:\n`);
    problems.forEach((p) => console.error(`  · ${p}`));
    process.exit(1);
  }

  meta.depends_on ||= [];
  meta.branch ||= `spec/${id}`;
  return { ...meta, body, file };
}

async function listSpecIds(dir = SPECS) {
  try { return (await fs.readdir(dir)).filter((f) => f.endsWith('.md')).map((f) => f.slice(0, -3)); }
  catch { return []; }
}

// ─── Zustand ─────────────────────────────────────────────────────────────────

const statePath = (id) => path.join(STATE, `${id}.json`);
async function readState(id) {
  try { return JSON.parse(await fs.readFile(statePath(id), 'utf8')); }
  catch { return { id, status: 'offen', attempts: 0 }; }
}
async function writeState(id, patch) {
  await fs.mkdir(STATE, { recursive: true });
  const s = { ...(await readState(id)), ...patch, updated: new Date().toISOString() };
  await fs.writeFile(statePath(id), JSON.stringify(s, null, 2));
  return s;
}

// ─── Repos ───────────────────────────────────────────────────────────────────

async function repos() {
  const p = path.join(HERE, 'repos.json');
  try { return JSON.parse(await fs.readFile(p, 'utf8')); }
  catch { fail(`${p} fehlt. Anlegen: { "edvancev1": { "path": "...", "base": "main" } }`); }
}

// ─── Prompt bauen ────────────────────────────────────────────────────────────

function buildPrompt(spec, gateFeedback) {
  const parts = [];

  parts.push(`Du arbeitest an einer abgegrenzten Aufgabe im Repo "${spec.repo}".
Der Branch ${spec.branch} ist bereits ausgecheckt. Arbeite nur in diesem Arbeitsverzeichnis.`);

  parts.push(`## Spezifikation\n\n${spec.body}`);

  parts.push(`## Regeln

- Halte dich an die Nicht-Ziele. Kein Aufräumen, kein Umformatieren, keine Refactorings
  ausserhalb des Auftrags — der Diff muss von Hand prüfbar bleiben.
- Migrationshistorie ist append-only. Neue Migration anlegen als
  supabase/migrations/<14-stelliger UTC-Zeitstempel>_<name>.sql. Eine bereits committete
  Migration wird nie geändert; Fehler werden durch eine neue Migration korrigiert.
- Kein git commit, kein git push, kein PR. Das macht der Orchestrator.
- Keine Secrets, keine .env-Dateien, keine Änderung an CI-Credentials.

## Fertig ist die Arbeit, wenn diese Befehle durchlaufen

${spec.gates.map((g) => `    ${g}`).join('\n')}

Führe sie selbst aus, bevor du fertig meldest.`);

  if (gateFeedback) {
    parts.push(`## Vorheriger Versuch ist an den Gates gescheitert

Das ist Versuch ${gateFeedback.attempt}. Ausgabe des fehlgeschlagenen Gates:

\`\`\`
${gateFeedback.output.slice(-6000)}
\`\`\`

Behebe die Ursache. Nicht das Gate anpassen, nicht den Test abschwächen, nicht
überspringen — die Ursache.`);
  }

  return parts.join('\n\n---\n\n');
}

// ─── Worktree ────────────────────────────────────────────────────────────────

async function setupWorktree(spec, repoCfg) {
  const wt = path.join(WORKTREES, spec.id);
  await fs.mkdir(WORKTREES, { recursive: true });

  const exists = await fs.stat(wt).then(() => true).catch(() => false);
  if (exists) {
    await sh(`git fetch origin ${repoCfg.base}`, { cwd: wt, quiet: true });
    const eigene = await sh(`git rev-list --count origin/${repoCfg.base}..HEAD`, { cwd: wt, quiet: true });
    const zurueck = await sh(`git rev-list --count HEAD..origin/${repoCfg.base}`, { cwd: wt, quiet: true });
    const n = Number(eigene.out.trim() || 0), b = Number(zurueck.out.trim() || 0);
    if (n === 0 && b > 0) {
      log(`  Worktree war ${b} Commit(s) hinter ${repoCfg.base} — wird nachgezogen`);
      await sh(`git reset --hard origin/${repoCfg.base}`, { cwd: wt, quiet: true });
    } else if (b > 0) {
      log(`  ⚠ Worktree hat ${n} eigene Commit(s) und ist ${b} hinter ${repoCfg.base}.`);
      log(`    Nicht automatisch nachgezogen. Von Hand rebasen oder Worktree entfernen.`);
    } else {
      log(`  Worktree besteht und ist aktuell: ${wt}`);
    }
    return wt;
  }

  log(`  Worktree anlegen: ${wt}`);
  let r = await sh(`git fetch origin ${repoCfg.base}`, { cwd: repoCfg.path, quiet: true });
  if (r.code !== 0) log(`  (fetch fehlgeschlagen, weiter mit lokalem Stand)`);

  r = await sh(
    `git worktree add -b "${spec.branch}" "${wt}" "origin/${repoCfg.base}" 2>/dev/null || ` +
    `git worktree add -b "${spec.branch}" "${wt}" "${repoCfg.base}"`,
    { cwd: repoCfg.path, quiet: true }
  );
  if (r.code !== 0) fail(`Worktree fehlgeschlagen:\n${r.combined}`);

  // Abhängigkeiten spiegeln, wenn vorhanden
  const hasLock = await fs.stat(path.join(wt, 'package-lock.json')).then(() => true).catch(() => false);
  if (hasLock) {
    log('  npm ci …');
    await sh('npm ci --silent', { cwd: wt, quiet: true });
  }
  return wt;
}

// ─── Gates ───────────────────────────────────────────────────────────────────

async function runGates(spec, wt) {
  for (const g of spec.gates) {
    log(`\n  Gate: ${g}`);
    const r = await sh(g, { cwd: wt, quiet: true });
    if (r.code !== 0) {
      log(`  ✗ rot (exit ${r.code})`);
      return { ok: false, gate: g, output: r.combined };
    }
    log('  ✓ grün');
  }
  return { ok: true };
}

// ─── Agent ───────────────────────────────────────────────────────────────────

async function runAgent(prompt, wt) {
  const pf = path.join(wt, '.orch-prompt.md');
  await fs.writeFile(pf, prompt);
  log('\n  claude -p läuft …\n');
  // Produktionszugang bleibt draussen. Ein Agent, der DBURL erbt, verbindet sich
  // damit — auch wenn die Spec nichts davon sagt.
  const sauber = { DBURL: '', SUPABASE_SERVICE_ROLE_KEY: '', SUPABASE_URL: '',
                   PGPASSWORD: '', PGHOST: '', PGUSER: '', DATABASE_URL: '' };
  const r = await sh(
    `claude -p "$(cat .orch-prompt.md)" --permission-mode bypassPermissions < /dev/null`,
    { cwd: wt, env: sauber }
  );
  await fs.rm(pf, { force: true });
  return r;
}

// ─── Kommandos ───────────────────────────────────────────────────────────────

async function cmdList() {
  const ids = await listSpecIds();
  if (!ids.length) return log(`Keine Specs in ${SPECS}`);
  log(`${'spec'.padEnd(32)}${'typ'.padEnd(10)}${'repo'.padEnd(16)}${'status'.padEnd(12)}gates`);
  log('─'.repeat(88));
  for (const id of ids) {
    let meta = {};
    try {
      const p = parseFrontmatter(await fs.readFile(path.join(SPECS, `${id}.md`), 'utf8'));
      meta = p?.meta ?? {};
    } catch { /* ignorieren */ }
    const st = await readState(id);
    const gates = Array.isArray(meta.gates) ? meta.gates.length : 0;
    log(
      `${id.slice(0, 31).padEnd(32)}${String(meta.type ?? '?').padEnd(10)}` +
      `${String(meta.repo ?? '?').slice(0, 15).padEnd(16)}${st.status.padEnd(12)}` +
      `${gates || '⚠ keine'}`
    );
  }
  const done = await listSpecIds(DONE);
  if (done.length) log(`\n${done.length} erledigt in specs/done/`);
}

async function cmdRun(id) {
  const spec = await loadSpec(id);
  const cfg = (await repos())[spec.repo];
  if (!cfg) fail(`Repo "${spec.repo}" nicht in orchestrator/repos.json.`);

  // Abhängigkeiten
  for (const dep of spec.depends_on) {
    const st = await readState(dep);
    if (st.status !== 'pr-offen' && st.status !== 'erledigt') {
      fail(`Abhängigkeit "${dep}" ist "${st.status}" — erst die erledigen.`);
    }
  }

  log(`\n▸ ${spec.id}  [${spec.type}]  → ${spec.repo}:${spec.branch}`);
  log(`  Gates: ${spec.gates.join(' · ')}`);

  if (flag('dry-run')) {
    log(`\n──── Prompt ────\n\n${buildPrompt(spec, null)}\n\n──── Ende ────`);
    return;
  }

  const wt = await setupWorktree(spec, cfg);
  await writeState(id, { status: 'läuft', worktree: wt, branch: spec.branch });

  let feedback = null;
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    log(`\n── Versuch ${attempt}/${MAX_ATTEMPTS}`);
    await runAgent(buildPrompt(spec, feedback), wt);

    const g = await runGates(spec, wt);
    if (g.ok) {
      log('\n  Alle Gates grün.');
      const dirty = await sh('git status --porcelain', { cwd: wt, quiet: true });
      if (!dirty.out.trim()) {
        await writeState(id, { status: 'geparkt', grund: 'Gates grün, aber keine Änderung im Worktree.' });
        return fail('Nichts geändert. Spec vermutlich schon erfüllt oder zu vage.');
      }

      await sh('git add -A', { cwd: wt, quiet: true });
      await sh(`git commit -m "${spec.id}: $(head -c 60 <<< "${spec.body.replace(/"/g, "'").split('\n').find((l) => l && !l.startsWith('#')) ?? spec.id}")"`, { cwd: wt, quiet: true });
      await sh(`git push -u origin "${spec.branch}"`, { cwd: wt, quiet: true });

      const pr = await sh(
        `gh pr create --base "${cfg.base}" --head "${spec.branch}" ` +
        `--title "${spec.id}" ` +
        `--body "Erzeugt aus specs/active/${spec.id}.md\n\nGates grün nach ${attempt} Versuch(en):\n${spec.gates.map((x) => `- \\\`${x}\\\``).join('\n')}\n\nNicht automatisch gemerged — Review erforderlich."`,
        { cwd: wt, quiet: true }
      );
      const url = (pr.out.match(/https?:\/\/\S+/) ?? [''])[0];
      await writeState(id, { status: 'pr-offen', pr: url, attempts: attempt });
      log(`\n✓ PR offen: ${url || '(gh-Ausgabe prüfen)'}`);
      log(`  Worktree bleibt für Nacharbeit: ${wt}`);
      log(`  Nach dem Merge:  node orchestrator/orch.mjs clean ${id}`);
      return;
    }

    feedback = { attempt, output: `Gate "${g.gate}" ist gescheitert:\n\n${g.output}` };
    await writeState(id, { status: 'läuft', attempts: attempt, letztes_gate: g.gate });
  }

  await writeState(id, { status: 'geparkt', attempts: MAX_ATTEMPTS, letzte_ausgabe: feedback?.output?.slice(-3000) });
  log(`\n✗ Nach ${MAX_ATTEMPTS} Versuchen geparkt.`);
  log(`  Worktree: ${wt}`);
  log(`  Meist heisst das: Gate zu grob, Spec zu vage, oder es fehlt Kontext.`);
}

async function cmdClean(id) {
  const st = await readState(id);
  if (!st.worktree) return log('Kein Worktree eingetragen.');
  const cfg = (await repos())[(await loadSpec(id)).repo];
  await sh(`git worktree remove --force "${st.worktree}"`, { cwd: cfg.path, quiet: true });
  await fs.mkdir(DONE, { recursive: true });
  await fs.rename(path.join(SPECS, `${id}.md`), path.join(DONE, `${id}.md`)).catch(() => {});
  await writeState(id, { status: 'erledigt', worktree: null });
  log(`✓ ${id} aufgeräumt, Spec nach specs/done/`);
}

// ─── Einstieg ────────────────────────────────────────────────────────────────

const HELP = `Orchestrator (Teil 1 — Code-Jobs)

  orch.mjs list
  orch.mjs run <spec-id> [--dry-run] [--attempts 3]
  orch.mjs run --all
  orch.mjs clean <spec-id>
`;

switch (CMD) {
  case 'list': await cmdList(); break;
  case 'run': {
    if (flag('all')) {
      for (const id of await listSpecIds()) {
        const st = await readState(id);
        if (['pr-offen', 'erledigt'].includes(st.status)) { log(`· ${id} übersprungen (${st.status})`); continue; }
        await cmdRun(id);
      }
    } else {
      const id = ARGV[1];
      if (!id || id.startsWith('--')) fail('Spec-ID fehlt.');
      await cmdRun(id);
    }
    break;
  }
  case 'clean': await cmdClean(ARGV[1] ?? fail('Spec-ID fehlt.')); break;
  default: log(HELP);
}
