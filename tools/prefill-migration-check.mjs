/**
 * prefill-migration-check.mjs — prueft Prefill-Migrationen als TEXT, bevor sie
 * eingespielt werden (Teil von verify-tasks.mjs --prefill).
 *
 * Fuer JEDE Datei supabase/migrations/*_prefill_*.sql:
 *   - nichts loeschen (kein DELETE/MERGE/TRUNCATE), keine DDL
 *   - jede schreibende Anweisung traegt den VERA8-Ausschluss
 *   - jedes UPDATE traegt eine Compare-and-set-Bedingung /*cas*\/ (...), und sie
 *     prueft die Spalte, die das UPDATE setzt (bei parts: das Teil-Feld p->>)
 * Fuer die Migration dieser Charge (--migration) zusaetzlich: nur Aufgaben der
 * Charge, keine davon VERA8.
 */

import fs from 'node:fs';
import { keinVera8Sql, LOESUNGS_FELDER, vera8Verstoesse } from './prefill-lib.mjs';

const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/** Anweisungen einer Datei ohne fuehrende Kommentarzeilen. */
export function anweisungen(text) {
  return text.split(/;\s*\n/).map((s) => s.replace(/^(\s*--[^\n]*\n)+/, '').trim()).filter(Boolean);
}

/** Die Spalte, die das (erste) UPDATE einer Anweisung setzt. */
const gesetzteSpalte = (s) => (s.match(/\bupdate\s+public\.\w+(?:\s+\w+)?\s+set\s+(\w+)\s*=/i) ?? [])[1];

/** Der Text der CAS-Bedingung (bis zur schliessenden Klammer auf Ebene 0). */
function casText(s) {
  const i = s.indexOf('/*cas*/');
  if (i < 0) return null;
  let tiefe = 0;
  for (let k = s.indexOf('(', i); k < s.length; k++) {
    if (s[k] === '(') tiefe++;
    else if (s[k] === ')' && --tiefe === 0) return s.slice(i, k + 1);
  }
  return null;
}

export function pruefeMigrationen(eigene, charge, stand) {
  const raus = [];
  const dir = 'supabase/migrations';
  const dateien = fs.readdirSync(dir).filter((f) => /_prefill_.*\.sql$/.test(f)).map((f) => `${dir}/${f}`);
  if (eigene && !dateien.includes(eigene)) dateien.push(eigene);
  const guard = new RegExp(`\\b(\\w+\\.)?${esc(keinVera8Sql())}`);
  for (const datei of dateien) {
    const text = fs.readFileSync(datei, 'utf8');
    for (const s of anweisungen(text)) {
      const kurz = s.replace(/\s+/g, ' ').slice(0, 90);
      if (/^(delete|merge|truncate|drop|alter|create|grant|revoke)\b/i.test(s) || /\bdelete\s+from\b/i.test(s)) {
        raus.push(`${datei}: verbotene Anweisung: ${kurz}`);
        continue;
      }
      if (!/^(update|insert|with)\b/i.test(s)) continue;
      if (!guard.test(s)) raus.push(`${datei}: Anweisung ohne VERA8-Ausschluss: ${kurz}`);
      if (/^insert\b/i.test(s)) continue;
      const cas = casText(s);
      if (!cas) { raus.push(`${datei}: UPDATE ohne Compare-and-set: ${kurz}`); continue; }
      const spalte = gesetzteSpalte(s);
      const geprueft = spalte === 'parts' ? /p->>/.test(cas)
        : spalte === 'vorbefuellt' ? true // Leer-Kennzeichen: CAS prueft das leere Feld selbst
          : spalte && new RegExp(`\\b${esc(spalte)}\\b`).test(cas);
      if (!geprueft) raus.push(`${datei}: Compare-and-set prueft nicht die gesetzte Spalte ${spalte}: ${kurz}`);
      // Loesungsschutz: tasks.vorbefuellt ist fuer ready-Aufgaben oeffentlich lesbar.
      for (const m of s.matchAll(/vorbefuellt \|\| '([^']*)'::jsonb/g)) {
        for (const [k, v] of Object.entries(JSON.parse(m[1]))) {
          if (LOESUNGS_FELDER.includes(k.split('.')[0]) && /\d|\([a-e][:,)]/.test(v.grund ?? '')) {
            raus.push(`${datei}: Kennzeichen ${k} traegt Werte im Grund (Loesungsschutz): ${v.grund}`);
          }
        }
      }
    }
    if (datei !== eigene) continue;
    const ids = new Set(charge.aufgaben.map((a) => a.id));
    // Nur Aufgaben-Bezuege (id = / task_id =) — UUIDs als WERT (z. B. cluster_id) sind keine Aufgaben.
    const bezuege = [...text.matchAll(/\b(?:id|task_id)\s*=\s*'([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})'/g)].map((m) => m[1]);
    for (const id of new Set(bezuege)) {
      if (!ids.has(id)) raus.push(`${datei}: fasst Aufgabe ${id} an, die nicht in der Charge steht`);
      else if (vera8Verstoesse({ aufgaben: [{ id, nr: '?', titel: id }] }, stand).length) raus.push(`${datei}: fasst VERA8-Aufgabe ${id} an`);
    }
  }
  return raus;
}
