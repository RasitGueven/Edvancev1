/**
 * verify-prefill.mjs — unabhaengige Pruefung einer Vorbefuellungs-Charge.
 * Aufruf ueber verify-tasks.mjs:
 *
 *   node tools/verify-tasks.mjs --prefill docs/prefill/mathe8-pilot.json \
 *        --snapshot docs/prefill/mathe8-pilot-snapshot.json \
 *        [--migration supabase/migrations/<v>_prefill_<name>.sql]
 *        [--blind docs/prefill/mathe8-pilot-blind.json] [--bericht <datei.md>]
 *
 * Vorab (Gate): VERA8 wird nie vorbefuellt — weder in der Charge noch in einer
 * Prefill-Migration (jede Anweisung traegt den Ausschluss; siehe pruefeMigrationen).
 *
 * Danach vier Stufen, alle ohne LLM und ohne DB:
 *   1. Constraints/Kataloge  jeder neue Wert gegen CHECKs und Wertelisten
 *   2. Vollstaendigkeit      jedes Lena-Feld ist gefuellt ODER hat einen Leer-Grund
 *   3. Nachrechnen           exakt (Brueche, Polynome) — Rechnung, Probe, Formel, Term
 *   4. Blind-Abgleich        Antworten eines Loesers, der die Loesungen nicht sah
 *
 * "Fehler" (Exit 1) betreffen nur, was die Charge setzt. Maengel an gesetzten
 * Werten des Bestands werden als "Bestand" gemeldet — die Charge darf sie nicht
 * ueberschreiben, Lena soll sie sehen.
 */

import fs from 'node:fs';
import { ladeCharge, leer, vera8Verstoesse, wirksam } from './prefill-lib.mjs';
import { pruefeMigrationen } from './prefill-migration-check.mjs';
import { Q, zahl, gleichwertig, faktoren } from './prefill-rechnen.mjs';

const AFB = ['I', 'II', 'III'];
const INHALT = [...fs.readFileSync('src/lib/authoring/einordnung.ts', 'utf8')
  .match(/INHALTSFELDER = \[([^\]]*)\]/)[1].matchAll(/'([a-z_]+)'/g)].map((m) => m[1]);
const PROZESS = ['Argumentieren', 'Problemlösen', 'Modellieren', 'Darstellen', 'Operieren', 'Kommunizieren'];
const VERBOTEN = /gemeistert|meisterst|mastered|beherrscht/i;

export async function pruefePrefill(opt) {
  const { charge, stand } = ladeCharge(opt.charge, opt.snapshot);
  const blind = opt.blind ? JSON.parse(fs.readFileSync(opt.blind, 'utf8')) : [];
  const fehler = [], bestand = [], rechnung = [], abgleich = [];
  const bilanz = new Map(); // feld -> { vorher, jetzt, leer, offen }
  // ── 0. VERA8 wird nie vorbefuellt ──
  fehler.push(...vera8Verstoesse(charge, stand));
  fehler.push(...pruefeMigrationen(opt.migration, charge, stand));

  const zaehl = (feld, art) => {
    const b = bilanz.get(feld) ?? { vorherLeer: 0, befuellt: 0, bewusstLeer: 0, ungeklaert: 0 };
    b[art]++; bilanz.set(feld, b);
  };
  const arten = new Map(); // feld -> { neu, ueberschrieben, ergaenzt, leer }
  const zaehlArt = (feld, art) => {
    const b = arten.get(feld) ?? { neu: 0, ueberschrieben: 0, ergaenzt: 0, leer: 0 };
    b[art]++; arten.set(feld, b);
  };
  const ueberschreibungen = [];

  for (const a of charge.aufgaben) {
    const x = stand.get(a.id);
    const { task, sol, aenderungen, uebersprungen, leerKennzeichen } = wirksam(a, x);
    const tag = `#${a.nr} ${a.titel}`;
    const F = (m) => fehler.push(`${tag}: ${m}`), B = (m) => bestand.push(`${tag}: ${m}`);
    const mp = task.input_type === 'MULTI_PART';
    uebersprungen.forEach(B);
    leerKennzeichen.forEach((l) => zaehlArt(l.schluessel.replace(/\.\d+\./, '[].').replace(/\.\d+$/, '[]'), 'leer'));

    // ── 1. Constraints der neu gesetzten Werte ──
    for (const c of aenderungen) {
      const w = c.wert, wo = c.teil ? `Teil ${c.teil} ${c.feld}` : c.feld;
      zaehlArt(c.teil ? `${c.tabelle === 'tasks.parts' ? 'parts' : c.feld}[].${c.tabelle === 'tasks.parts' ? c.feld : 'antwort'}` : c.feld, c.art);
      if (c.art !== 'neu') {
        // Ueberschreiben (Nachtrag 2): Begruendung, exakter Altwert, Nachweis "kein Mensch".
        const e = c.casAlt === undefined ? null : c;
        if (!e) F(`${wo}: Ueberschreibung ohne exakten alten Wert (alt)`);
        const quelle = c.teil ? a.teile?.[c.teil]?.[c.feld === 'correct_answers' ? 'antwort' : c.feld]
          : a.felder?.[c.feld] ?? a.loesung?.[c.feld];
        if (!String(quelle?.begruendung ?? '').trim()) F(`${wo}: Ueberschreibung ohne Begruendung`);
        if (!String(quelle?.nachweis ?? '').trim()) F(`${wo}: Ueberschreibung ohne Nachweis, dass kein Mensch den Wert bearbeitet hat`);
        if (c.tabelle === 'task_solutions' && x.sol && Date.parse(x.sol.updated_at) - Date.parse(x.task.created_at) > 10 * 60e3) {
          F(`${wo}: Loesung nach dem Import geaendert (updated_at) — moeglicherweise von Hand, nicht ueberschreiben`);
        }
        if (c.art === 'ergaenzt' && !(Array.isArray(c.alt) && Array.isArray(w) && c.alt.every((v) => w.includes(v)))) {
          F(`${wo}: "ergaenzt" darf keine vorhandene Variante entfernen`);
        }
        ueberschreibungen.push(`${tag} · ${wo}: ${JSON.stringify(c.alt)} → ${JSON.stringify(w)} (${c.art}) — ${quelle?.begruendung ?? ''}`);
      }
      if (c.feld === 'needs_image' && w === true && !/Bild|Abbildung|Graph|Tabelle|Skizze|Grafik/i.test(c.grund)) {
        F(`${wo}: Bildbedarf true, aber der Grund nennt kein fehlendes Bild`);
      }
      if (c.feld === 'afb' && !AFB.includes(w)) F(`${wo}="${w}" nicht in I/II/III`);
      if (c.feld === 'est_duration_sec' && !(Number.isInteger(w) && w >= 10 && w <= 3600)) F(`${wo}=${w} ausserhalb 10..3600`);
      if (c.feld === 'curriculum_grade' && !(Number.isInteger(w) && w >= 5 && w <= 13)) F(`${wo}=${w} ausserhalb 5..13`);
      if (c.feld === 'competency_content' && !INHALT.includes(w)) F(`${wo}="${w}" nicht im Katalog ${INHALT.join('/')}`);
      if (c.feld === 'competency_process' && w.split(/,\s*/).some((p) => !PROZESS.includes(p))) F(`${wo}="${w}" nicht im Katalog`);
      if (c.feld === 'est_duration_sec') {
        const soll = charge.zeitregel.basis[task.afb] + (/\+ Sachkontext/.test(c.grund) ? charge.zeitregel.sachkontext_zuschlag : 0);
        if (w !== soll) F(`Zeitbudget ${w} s weicht von der Zeitregel ab (${soll} s)`);
      }
      if (c.feld === 'hints' && !(Array.isArray(w) && w.every((h, i) => h.level === i + 1 && typeof h.text === 'string' && h.text.trim()))) F('hints: Form {level 1..n, text}');
      if (c.feld === 'typical_errors' && !(Array.isArray(w) && w.every((e) => e.error?.trim() && typeof e.socratic_question === 'string'))) F('typical_errors: Form {error, socratic_question}');
      if (c.feld === 'correct_answers' && !(Array.isArray(w) && w.length && w.every((s) => typeof s === 'string' && s.trim()))) F(`${wo}: kein nichtleeres String-Array`);
      if (VERBOTEN.test(JSON.stringify(w))) F(`${wo}: Mastery-Sprache im Text`);
      if (c.grund == null || !String(c.grund).trim()) F(`${wo}: Begruendung fehlt`);
    }
    // Endstand gegen Datenmodell
    const ca = sol.correct_answers;
    if (mp && Array.isArray(ca) && ca.length) B('MULTI_PART mit flachem correct_answers-Array — wird pro Teil nie gewertet');
    for (const p of task.parts) {
      const ant = !Array.isArray(ca) ? ca?.[p.nr] ?? [] : [];
      if (p.kind === 'mc' && ant.some((s) => !(p.options ?? []).some((o) => o.id === s))) B(`Teil ${p.nr} (mc): Antwort ${JSON.stringify(ant)} ist keine Options-ID — nie richtig wertbar`);
      if (ant.some((s) => /^(UND|ODER)$|\[pic\]|Begründung|Intervall|angekreuzt/.test(s))) B(`Teil ${p.nr}: correct_answers enthaelt Kodiertext ${JSON.stringify(ant)}`);
    }
    if (!mp && Array.isArray(ca)) {
      const opts = task.question_payload?.options;
      if (task.input_type === 'MC' && opts && ca.some((s) => !opts.some((o) => o.id === s))) B(`MC-Antwort ${JSON.stringify(ca)} ist keine Options-ID`);
      if (task.input_type === 'MC' && !opts) B('MC ohne Optionen in question_payload');
      if (task.input_type === 'NUMERIC' && ca.some((s) => /[a-z]\s*=/.test(s))) B(`NUMERIC-Antwort ${JSON.stringify(ca)} enthaelt "x =" — Eingabe "${ca[0].replace(/^.*=\s*/, '')}" wird als falsch gewertet`);
    }
    if (VERBOTEN.test(JSON.stringify(a))) F('Mastery-Sprache in der Charge');

    // ── 2. Vollstaendigkeit je Lena-Feld ──
    // Nicht als Luecke: coach_hints (LSA, Entscheidung 2) und unit (reine Zahlen, Entscheidung 4).
    const felder = [
      ['tasks.input_type', task.input_type], ['tasks.afb', task.afb], ['tasks.est_duration_sec', task.est_duration_sec],
      ['tasks.curriculum_grade', task.curriculum_grade], ['tasks.cluster_id', task.cluster_id], ['tasks.needs_image', task.needs_image],
      ['task_solutions.solution', sol.solution], ['task_solutions.hints', sol.hints], ['task_solutions.typical_errors', sol.typical_errors],
    ];
    if (!mp) felder.push(['tasks.competency_content', task.competency_content], ['tasks.competency_process', task.competency_process], ['task_solutions.correct_answers', Array.isArray(ca) ? ca : null]);
    // Entscheidung 3: Bildbedarf ist bei JEDER Aufgabe gesetzt — ein Leer-Grund reicht nicht.
    if (task.needs_image == null) F('needs_image nicht gesetzt (true oder false Pflicht)');
    for (const p of task.parts) {
      felder.push([`parts[].afb`, p.afb, p.nr], [`parts[].competency_content`, p.competency_content, p.nr],
        [`parts[].antwort`, Array.isArray(ca) ? null : ca?.[p.nr], p.nr]);
    }
    const vorherTask = x.task, vorherSol = x.sol ?? {};
    for (const [feld, jetzt, nr] of felder) {
      const kurz = feld.split('.').pop();
      const vorher = nr != null
        ? (kurz === 'antwort' ? (Array.isArray(vorherSol.correct_answers) ? null : vorherSol.correct_answers?.[nr]) : vorherTask.parts.find((p) => p.nr === nr)?.[kurz])
        : feld.startsWith('tasks.') ? vorherTask[kurz] : vorherSol[kurz];
      if (!leer(vorher)) continue;
      zaehl(feld, 'vorherLeer');
      const teilSchluessel = kurz === 'antwort' ? `correct_answers.${nr}` : `parts.${nr}.${kurz}`;
      const grund = nr != null ? a.leer?.[teilSchluessel] : a.leer?.[kurz];
      if (!leer(jetzt)) zaehl(feld, 'befuellt');
      else if (grund) zaehl(feld, 'bewusstLeer');
      else { zaehl(feld, 'ungeklaert'); F(`${feld}${nr != null ? ` (Teil ${nr})` : ''} leer ohne Grund`); }
    }

    // ── 3. Nachrechnen ──
    const antwortenVon = (teil) => (teil == null ? (Array.isArray(ca) ? ca : []) : Array.isArray(ca) ? [] : ca?.[teil] ?? []);
    for (const pr of a.pruefung ?? []) {
      const wo = `${tag}${pr.teil ? ` Teil ${pr.teil}` : ''}`;
      try {
        if (pr.rechnung || pr.probe) {
          const ist = pr.rechnung ? zahl(pr.rechnung) : zahl(pr.probe, { A: zahl(pr.antwort) });
          const soll = pr.rechnung ? zahl(pr.antwort) : zahl(pr.soll);
          const ok = ist.eq(soll);
          rechnung.push(`${ok ? 'ok ' : 'FEHLER'} ${wo}: ${pr.rechnung ?? pr.probe.replace(/A/g, pr.antwort)} = ${ist} (soll ${soll})`);
          if (!ok) F(`Nachrechnung ${pr.rechnung ?? pr.probe} ergibt ${ist}, nicht ${soll}`);
          if (!pr.rolle) {
            const gespeichert = antwortenVon(pr.teil);
            const drin = gespeichert.some((s) => { try { return zahl(s).eq(zahl(pr.antwort)); } catch { return false; } });
            if (!drin) (aenderungen.some((c) => c.feld === 'correct_answers') ? F : B)(`nachgerechneter Wert ${pr.antwort} fehlt in correct_answers ${JSON.stringify(gespeichert)}`);
          }
        } else if (pr.formel) {
          for (const f of pr.faelle) {
            const ist = zahl(pr.formel, { P: new Q(BigInt(f.P)), M: new Q(BigInt(f.M)) });
            if (!ist.eq(zahl(f.soll))) F(`Formel ${pr.formel} bei P=${f.P}, M=${f.M} ergibt ${ist}, nicht ${f.soll}`);
          }
          for (const s of antwortenVon(pr.teil)) {
            const t = s.replace(/^Note\s*=\s*/, '').replace(/erreichte Punktzahl/g, 'P').replace(/Maximalpunktzahl/g, 'M');
            const gleich = pr.faelle.every((f) => zahl(t, { P: new Q(BigInt(f.P)), M: new Q(BigInt(f.M)) }).eq(zahl(pr.formel, { P: new Q(BigInt(f.P)), M: new Q(BigInt(f.M)) })));
            if (!gleich) F(`Antwort "${s}" entspricht nicht der Formel ${pr.formel}`);
          }
          rechnung.push(`ok  ${wo}: Formel ${pr.formel} an ${pr.faelle.length} Stellen und alle Antwort-Varianten`);
        } else if (pr.term) {
          const opts = task.question_payload?.options ?? [];
          const frage = (task.question.match(/\n([^\n]*?)\s*=\s*\?/) ?? [])[1];
          if (frage && !gleichwertig(frage, pr.term)) F(`Term ${pr.term} passt nicht zur Aufgabe "${frage}"`);
          let treffer = opts.filter((o) => gleichwertig(o.label, pr.term));
          if (pr.vollstaendig && treffer.length > 1) {
            const max = Math.max(...treffer.map((o) => faktoren(o.label)));
            treffer = treffer.filter((o) => faktoren(o.label) === max);
          }
          const soll = treffer.map((o) => o.id);
          const ok = soll.length === 1 && JSON.stringify(ca) === JSON.stringify(soll);
          rechnung.push(`${ok ? 'ok ' : 'FEHLER'} ${wo}: ${frage ?? pr.term} ≡ Option ${soll.join(',') || '—'} (gespeichert ${JSON.stringify(ca)})`);
          if (!ok) B(`Term-Pruefung: gleichwertige Option ${soll.join(',') || 'keine'}, gespeichert ${JSON.stringify(ca)}`);
          const lw = (sol.solution ?? '').replace(/\s/g, '');
          if (soll.length === 1 && !lw.includes(opts.find((o) => o.id === soll[0]).label.replace(/\s/g, ''))) F('Loesungsweg nennt das richtige Ergebnis nicht');
        }
      } catch (e) { F(`Nachrechnung nicht auswertbar (${e.message})`); }
    }
    // Loesungsweg nennt jede Zahlenantwort
    for (const [teil, ant] of Object.entries(Array.isArray(ca) ? { '': ca } : ca ?? {})) {
      const p = task.parts.find((q) => String(q.nr) === teil);
      if (p?.kind === 'mc' || task.input_type === 'MC') continue;
      const z = ant.find((s) => /^-?\d+(,\d+)?$/.test(s));
      if (z && aenderungen.some((c) => c.feld === 'solution') && !(sol.solution ?? '').includes(z)) F(`Loesungsweg nennt ${z}${teil ? ` (Teil ${teil})` : ''} nicht`);
    }
    for (const h of (aenderungen.find((c) => c.feld === 'hints')?.wert ?? []).slice(0, 1)) {
      for (const s of Array.isArray(ca) ? ca : Object.values(ca ?? {}).flat()) {
        if (/^\d{2,}$/.test(s) && h.text.includes(s)) F(`Hinweis Stufe 1 verraet die Antwort ${s}`);
      }
    }

    // ── 4. Blind-Abgleich ──
    for (const b of blind.filter((r) => r.id === a.id)) {
      const gespeichert = antwortenVon(b.teil);
      const wo = `${tag}${b.teil ? ` Teil ${b.teil}` : ''}`;
      if (!b.eindeutig) { abgleich.push(`info ${wo}: Loeser nennt die Aufgabe nicht eindeutig (${b.anmerkung || 'ohne Anmerkung'})`); continue; }
      const seine = String(b.antwort).split(';').map((s) => s.trim());
      let gleich;
      if (/[PM]/.test(b.antwort)) {
        const t = (s) => s.replace(/^Note\s*=\s*/, '').replace(/erreichte Punktzahl/g, 'P').replace(/Maximalpunktzahl/g, 'M');
        gleich = gespeichert.length > 0 && gespeichert.every((s) => [[0, 50], [25, 50], [7, 20]].every(([P, M]) =>
          zahl(t(s), { P: new Q(BigInt(P)), M: new Q(BigInt(M)) }).eq(zahl(b.antwort, { P: new Q(BigInt(P)), M: new Q(BigInt(M)) }))));
      } else if (/^[a-z]$/.test(seine[0])) {
        gleich = JSON.stringify([...gespeichert].sort()) === JSON.stringify([...seine].sort());
      } else {
        const num = (s) => { try { return zahl(s.replace(/^.*=\s*/, '')); } catch { return null; } };
        const g = gespeichert.map(num).filter(Boolean), s = seine.map(num).filter(Boolean);
        gleich = s.length > 0 && s.every((v) => g.some((w) => w.eq(v))) && g.every((v) => s.some((w) => w.eq(v)));
      }
      abgleich.push(`${gleich ? 'ok ' : 'ABWEICHUNG'} ${wo}: Loeser ${b.antwort} · gespeichert ${JSON.stringify(gespeichert)}`);
      if (!gleich) (aenderungen.some((c) => c.feld === 'correct_answers' && String(c.teil ?? '') === String(b.teil ?? '')) ? F : B)(`Blind-Loeser ${b.antwort} ≠ gespeichert ${JSON.stringify(gespeichert)}`);
    }
  }

  const zeilen = [...bilanz].map(([f, b]) => `| ${f} | ${b.vorherLeer} | ${b.befuellt} | ${b.bewusstLeer} | ${b.ungeklaert} |`);
  const artZeilen = [...arten].map(([f, b]) => `| ${f} | ${b.neu} | ${b.ueberschrieben} | ${b.ergaenzt} | ${b.leer} |`);
  const bericht = [
    `# Verifikation ${charge.batch}`, '',
    `Aufgaben: ${charge.aufgaben.length} · Charge-Fehler: **${fehler.length}** · Bestands-Befunde: ${bestand.length} · Ueberschreibungen: ${ueberschreibungen.length}`, '',
    '## Feldtabelle (was die Migration auf dem Snapshot-Stand tut)', '',
    '| Feld | neu | ueberschrieben | ergaenzt | bewusst leer (Kennzeichen) |', '|---|---|---|---|---|', ...artZeilen, '',
    '## Ueberschreibungen (alt → neu)', '', ...(ueberschreibungen.length ? ueberschreibungen.map((u) => `- ${u}`) : ['- keine']), '',
    '## Vollstaendigkeit je Feld', '', '| Feld | vorher leer | jetzt befuellt | bewusst leer | ungeklaert |', '|---|---|---|---|---|', ...zeilen, '',
    '## Charge-Fehler (Gate)', '', ...(fehler.length ? fehler.map((f) => `- ${f}`) : ['- keine']), '',
    '## Bestands-Befunde (gesetzte Werte, nicht ueberschrieben)', '', ...(bestand.length ? bestand.map((f) => `- ${f}`) : ['- keine']), '',
    '## Nachrechnung (exakt, Skript)', '', ...rechnung.map((r) => `- ${r}`), '',
    `## Blind-Abgleich (${opt.blind ?? 'kein Loeser'})`, '', ...abgleich.map((r) => `- ${r}`), '',
  ].join('\n');
  return { fehler, bestand, bericht };
}
