#!/usr/bin/env node
/**
 * erklaer-k8-linfkt-charge.mjs — baut aus tools/erklaer-k8-linfkt/<skill>.mjs
 *   docs/prefill/erklaer-k8-linfkt.json         Erklär-Charge (Kernideen, Schritte, Bilder mit svg_hash, Checks)
 *   docs/prefill/erklaer-k8-linfkt-checks.json  Check-Aufgaben im Charge-Format von tools/vorlauf-build.mjs
 *   docs/prefill/erklaer-k8-linfkt-ids.json     feste ids (bleiben bei jedem Lauf gleich)
 * Vor dem Schreiben rechnet tools/erklaer-rechnen.mjs alles nach; ist etwas rot, wird nichts geschrieben.
 *
 *   node tools/erklaer-k8-linfkt-charge.mjs
 *
 * Danach: node tools/vorlauf-build.mjs docs/prefill/erklaer-k8-linfkt-checks.json <version> erklaer_k8_linfkt_checks
 *         node tools/erklaer-build.mjs docs/prefill/erklaer-k8-linfkt.json <version> erklaer_k8_linfkt
 */

import fs from 'node:fs';
import crypto from 'node:crypto';
import { zahl } from './prefill-rechnen.mjs';
import { bilderPython } from './erklaer-lib.mjs';
import { pruefeCharge } from './erklaer-rechnen.mjs';
import * as steigung from './erklaer-k8-linfkt/steigung.mjs';

const MODULE = [steigung];
const PFAD = 'docs/prefill/erklaer-k8-linfkt';
const BESTAND = `${PFAD}-bestand.json`;
const AUFGABEN = 'docs/prefill/k8-linfkt.json';
const ALGEBRA_FUNKTIONEN = 'edbb548a-54d9-4a8f-8be4-3052f9025524'; // wie tools/k8-linfkt-charge.mjs
const ZEIT = { I: 45, II: 60, III: 90 };
// Startwerte der Stellschrauben (Bauauftrag F, 20261007110100_session_einstellungen.sql:82-83).
const EINSTELLUNGEN = { kernideen_max: 3, check_aufgaben_je_kernidee: 1 };

// Schreibweisen wie tools/k8-linfkt-charge.mjs (formen): lsa_is_correct vergleicht Text,
// das Unicode-Minus und ein führendes "+" normalisiert es nicht.
function formen(wert) {
  const s = wert.replace('.', ',');
  const zahlen = s.includes(',') ? [s, s.replace(',', '.')] : [s];
  const out = [];
  for (const z of zahlen) {
    if (z.startsWith('-')) out.push(z, `−${z.slice(1)}`, `- ${z.slice(1)}`);
    else if (z !== '0') out.push(z, `+${z}`);
    else out.push(z);
  }
  return [...new Set(out)];
}

const bestand = JSON.parse(fs.readFileSync(BESTAND, 'utf8'));
const IDS = fs.existsSync(`${PFAD}-ids.json`) ? JSON.parse(fs.readFileSync(`${PFAD}-ids.json`, 'utf8')) : {};
const id = (k) => (IDS[k] ??= crypto.randomUUID());
const fehler = [];
const punkt = (s) => s.replace(',', '.');
const nachgerechnet = (r, soll, wo) => {
  if (!zahl(punkt(r)).eq(zahl(punkt(soll)))) fehler.push(`${wo}: ${r} = ${zahl(punkt(r))}, nicht ${soll}`);
};

// Reihenfolge der Module = Reihenfolge aus ziel_fertigkeiten (Bestand).
const reihenfolge = bestand.skills.map((s) => s.skill_key);
MODULE.forEach((m, i) => { if (m.SKILL !== reihenfolge[i]) fehler.push(`Modul ${i + 1}: ${m.SKILL}, erwartet ${reihenfolge[i]}`); });

const aufgaben = [];
const kernideen = [];
for (const m of MODULE) {
  const klasse = bestand.skills.find((s) => s.skill_key === m.SKILL).klasse;
  for (const k of m.KERNIDEEN) {
    const kid = id(`kernidee:${m.SKILL}:${k.nr}`);
    const schritte = [];
    for (const [variante, v] of Object.entries(k.varianten)) {
      for (const art of ['erklaerung', 'beispiel']) {
        const s = v[art];
        if (!s) continue;
        schritte.push({
          id: id(`schritt:${m.SKILL}:${k.nr}:${variante}:${art}`), variante, art, inhalt: s.inhalt,
          ...(s.bild ? { bild: s.bild } : {}),
          fehlbild_slugs: art === 'erklaerung' ? (v.fehlbilder ?? []) : [],
          rechnungen: s.rechnungen ?? [],
        });
      }
    }
    const checks = k.checks.map((c, i) => {
      const tid = id(`task:${c.ref}`);
      nachgerechnet(c.r, c.antwort, c.ref);
      const known = {};
      for (const [wert, slug, r] of c.ke) {
        nachgerechnet(r, wert, `${c.ref} known_error ${slug}`);
        if (zahl(punkt(wert)).eq(zahl(punkt(c.antwort)))) fehler.push(`${c.ref}: falscher Wert ${wert} = Antwort`);
        for (const f of formen(wert)) known[f] = slug;
      }
      const richtig = [...new Set([c.antwort, ...(c.auch ?? [])].flatMap(formen))];
      for (const w of Object.keys(known)) if (richtig.includes(w)) fehler.push(`${c.ref}: ${w} ist richtig und falsch`);
      aufgaben.push({
        nr: aufgaben.length + 1, id: tid, titel: c.titel,
        basis: {
          skill_key: m.SKILL, source_ref: c.ref, input_type: 'NUMERIC', frage: c.frage, known_errors: known,
          ...(c.figur ? { figur: { generator: c.figur.generator, params: c.figur.params, alt_text: c.figur.alt } } : {}),
        },
        felder: {
          afb: { wert: c.afb, sicher: 'mittel', grund: c.afbGrund },
          est_duration_sec: { wert: ZEIT[c.afb], sicher: 'mittel', grund: `Zeitregel wie k8-linfkt: AFB ${c.afb}, kein Sachkontext.` },
          curriculum_grade: { wert: klasse, sicher: 'hoch', grund: `skills.klasse_herkunft = ${klasse} (Bestand, dbread).` },
          cluster_id: { wert: ALGEBRA_FUNKTIONEN, sicher: 'hoch', grund: 'Algebra & Funktionen, wie die Aufgaben der Charge k8-linfkt.' },
          competency_content: { wert: 'funktionen', sicher: 'hoch', grund: 'Inhaltsfeld Funktionen (KLP Fkt-4 bis Fkt-7).' },
          competency_process: { wert: c.prozess, sicher: 'mittel', grund: 'Check der Erklärsequenz: das Verfahren der Kernidee einmal anwenden.' },
          needs_image: { wert: !!c.figur, sicher: 'hoch', grund: c.figur ? 'Ohne Abbildung nicht lösbar (Generator koordinatensystem).' : 'Alle Angaben stehen im Text.' },
        },
        loesung: {
          correct_answers: { wert: richtig, sicher: 'hoch', grund: 'Nachgerechnet; Komma/Punkt und Minus/Plus-Formen wie k8-linfkt.' },
          solution: { wert: c.weg, sicher: 'hoch', grund: 'Nachgerechnet.' },
          typical_errors: {
            // je Fehlbild ein Eintrag (der erste, wenn ein Slug mehrere Schreibweisen hat)
            wert: c.ke.filter((x, i) => c.ke.findIndex((y) => y[1] === x[1]) === i)
              .map(([, slug, , error, socratic_question]) => ({ error, socratic_question, fehlbild: slug })),
            sicher: 'hoch', grund: 'Aus acceptance.known_errors; jedes Fehlbild zeigt auf eine Variante der Kernidee.',
          },
        },
        leer: { hints: 'Check der Erklärsequenz: Hinweise gibt es nur in der Kernarbeit (Entscheidung 32).' },
        pruefung: [{ rechnung: c.r, antwort: c.antwort },
          ...c.ke.map(([wert, slug, r]) => ({ rechnung: r, antwort: wert, rolle: `fehlbild:${slug}` }))],
      });
      return { task_id: tid, ref: c.ref, reihenfolge: i + 1 };
    });
    kernideen.push({ id: kid, skill_key: m.SKILL, nr: k.nr, titel: k.titel,
      ...(k.ohne_variante ? { ohne_variante: k.ohne_variante } : {}), schritte, checks });
  }
}

// Bild-Hashes wie upload_figures.params_hash (Generator + kanonische params).
const mitBild = kernideen.flatMap((k) => k.schritte).filter((s) => s.bild);
bilderPython(mitBild.map((s) => s.bild)).forEach((r, i) => { mitBild[i].bild.svg_hash = r.hash; });

const checkCharge = {
  batch: 'erklaer-k8-linfkt-checks',
  kopf: [
    `Erklärsequenzen Lineare Funktionen (E2b), Migration 1 von 2 — ${aufgaben.length} Check-Aufgaben, nur Einsatz check.`,
    'Erzeugt von tools/vorlauf-build.mjs aus docs/prefill/erklaer-k8-linfkt-checks.json (Quelle:',
    'tools/erklaer-k8-linfkt/*.mjs und tools/erklaer-k8-linfkt-charge.mjs) — nicht von Hand editieren.',
    '',
    'Einspiel-Reihenfolge: vor der Erklär-Migration (erklaer_check verweist auf diese Aufgaben).',
  ],
  auswahl: 'Je Kernidee check_aufgaben_je_kernidee (1) Check-Aufgabe, NUMERIC, mit known_errors, die auf die Varianten der Kernidee zeigen. Keine Hinweise, kein Sondierrang, Einsatz nur check (Entscheidung 28).',
  source: 'edvance_erklaer_k8_linfkt',
  einsatz: ['check'],
  ohne_transaktion: true,
  ohne_sondierrang: [...new Set(aufgaben.map((a) => a.basis.skill_key))],
  ohne_sondierrang_grund: 'kein Rang: Check-Aufgaben der Erklaersequenz sondieren nie (Einsatz nur check)',
  zeitregel: { beschreibung: 'est_duration_sec wie k8-linfkt: AFB I 45 s, AFB II 60 s.', basis: ZEIT },
  aufgaben,
};
const charge = {
  batch: 'erklaer-k8-linfkt', thema_key: bestand.thema_key, einstellungen: EINSTELLUNGEN,
  bestand: BESTAND, aufgaben_charge: AUFGABEN, check_charge: `${PFAD}-checks.json`,
  kernideen,
};

fehler.push(...pruefeCharge(charge, checkCharge, bestand, JSON.parse(fs.readFileSync(AUFGABEN, 'utf8'))));
if (fehler.length) { console.error(`Charge abgelehnt (${fehler.length}):\n  ${fehler.join('\n  ')}`); process.exit(1); }

fs.writeFileSync(`${PFAD}-ids.json`, JSON.stringify(IDS, null, 1) + '\n');
fs.writeFileSync(`${PFAD}-checks.json`, JSON.stringify(checkCharge, null, 1) + '\n');
fs.writeFileSync(`${PFAD}.json`, JSON.stringify(charge, null, 1) + '\n');
console.log(`${PFAD}.json: ${kernideen.length} Kernideen, ${kernideen.reduce((s, k) => s + k.schritte.length, 0)} Schritte, ${mitBild.length} Bilder`);
console.log(`${PFAD}-checks.json: ${aufgaben.length} Check-Aufgaben`);
