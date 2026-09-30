/**
 * prefill-lib.mjs — gemeinsame Logik fuer Vorbefuellung (Generator + Pruefer).
 *
 * Eine Charge (docs/prefill/<charge>.json) beschreibt pro Aufgabe:
 *   felder  -> Spalten in tasks          { wert, sicher, grund }
 *   teile   -> Schluessel je parts[nr]   { afb, competency_content, antwort }
 *              "antwort" landet in task_solutions.correct_answers[nr]
 *   loesung -> Spalten in task_solutions { correct_answers, solution, hints, typical_errors }
 *   leer    -> Feld -> Grund, warum bewusst nichts gesetzt wird
 *   pruefung-> maschinelle Nachrechnung (siehe verify-prefill.mjs)
 *
 * Der Snapshot ist der Stand der DB beim Erzeugen (task + sol je Aufgabe).
 * Grundsatz: nur leere Felder werden gesetzt. `wirksam()` liefert genau das,
 * was die Migration auf diesem Stand tatsaechlich aendern wuerde.
 */

import fs from 'node:fs';

export const leer = (v) =>
  v == null ||
  (typeof v === 'string' && v.trim() === '') ||
  (Array.isArray(v) && v.length === 0) ||
  (typeof v === 'object' && !Array.isArray(v) && Object.keys(v).length === 0);

export function ladeCharge(pfad, snapshotPfad) {
  const charge = JSON.parse(fs.readFileSync(pfad, 'utf8'));
  const snap = JSON.parse(fs.readFileSync(snapshotPfad, 'utf8'));
  const stand = new Map(snap.map((x) => [x.task.id, x]));
  for (const a of charge.aufgaben) {
    if (!stand.has(a.id)) throw new Error(`Aufgabe ${a.id} (${a.titel}) fehlt im Snapshot`);
  }
  return { charge, stand };
}

/** Antworten je Teilaufgabe aus einem correct_answers-Wert (Objekt) lesen. */
const teilAntwort = (ca, nr) => (ca && !Array.isArray(ca) && Array.isArray(ca[nr]) ? ca[nr] : []);

/**
 * Welche Aenderungen wirken auf dem Snapshot-Stand? Liefert eine flache Liste
 * { id, teil, tabelle, feld, wert, sicher, grund } und den neuen Gesamtstand.
 */
export function wirksam(a, x) {
  const task = structuredClone(x.task);
  const sol = structuredClone(x.sol ?? { correct_answers: [], hints: [], typical_errors: [], coach_hints: [], solution: null });
  const aenderungen = [];
  const merk = (teil, tabelle, feld, e) =>
    aenderungen.push({ id: a.id, teil, tabelle, feld, wert: e.wert, sicher: e.sicher, grund: e.grund });

  for (const [feld, e] of Object.entries(a.felder ?? {})) {
    if (leer(task[feld])) { task[feld] = e.wert; merk(null, 'tasks', feld, e); }
  }
  for (const [nr, t] of Object.entries(a.teile ?? {})) {
    const p = task.parts.find((q) => String(q.nr) === nr);
    if (!p) throw new Error(`${a.titel}: Teilaufgabe ${nr} existiert nicht`);
    for (const feld of ['afb', 'competency_content']) {
      if (t[feld] && leer(p[feld])) { p[feld] = t[feld].wert; merk(nr, 'tasks.parts', feld, t[feld]); }
    }
    if (t.antwort && teilAntwort(sol.correct_answers, nr).length === 0) {
      const ca = sol.correct_answers;
      // Nur ein leeres Array darf zum Objekt werden; ein gefuelltes flaches Array bleibt unangetastet.
      if (Array.isArray(ca) && ca.length > 0) continue;
      sol.correct_answers = { ...(Array.isArray(ca) ? {} : ca), [nr]: t.antwort.wert };
      merk(nr, 'task_solutions', 'correct_answers', t.antwort);
    }
  }
  for (const [feld, e] of Object.entries(a.loesung ?? {})) {
    if (leer(sol[feld])) { sol[feld] = e.wert; merk(null, 'task_solutions', feld, e); }
  }
  return { task, sol, aenderungen, hatteLoesungszeile: x.sol != null };
}
