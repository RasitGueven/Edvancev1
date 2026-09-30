/**
 * prefill-lib.mjs — gemeinsame Logik fuer Vorbefuellung (Generator + Pruefer).
 *
 * Eine Charge (docs/prefill/<charge>.json) beschreibt pro Aufgabe:
 *   felder  -> Spalten in tasks          { wert, sicher, grund [, alt, art] }
 *   teile   -> Schluessel je parts[nr]   { afb, competency_content, needs_image, antwort }
 *              "antwort" landet in task_solutions.correct_answers[nr]
 *   loesung -> Spalten in task_solutions { correct_answers, solution, hints, typical_errors }
 *   leer    -> Feld -> Grund, warum bewusst nichts gesetzt wird (wird als Kennzeichen sichtbar)
 *   pruefung-> maschinelle Nachrechnung (siehe verify-prefill.mjs)
 *
 * Neu setzen: nur in leere Felder. Ueberschreiben (Nachtrag 2 zu PR #176): nur mit
 * `alt` = exakter alter Wert (Compare-and-set) und Begruendung; `art` ist dann
 * 'ueberschrieben' oder 'ergaenzt' (ergaenzt = alle alten Varianten bleiben).
 *
 * Der Snapshot ist der Stand der DB beim Erzeugen (task + sol je Aufgabe).
 * `wirksam()` liefert genau das, was die Migration auf diesem Stand aendern wuerde.
 */

import fs from 'node:fs';

/**
 * VERA8 wird nie vorbefuellt (Entscheidung zu PR #176). Dieselbe Definition wie
 * das Board: src/lib/authoring/vera8.json (tasks.source).
 */
// Pfade relativ zur Repo-Wurzel (Aufruf immer von dort, wie bei verify-tasks.mjs).
export const VERA8_SOURCE = JSON.parse(fs.readFileSync('src/lib/authoring/vera8.json', 'utf8')).source;

/** SQL-Bedingung "keine VERA8-Aufgabe" fuer eine tasks-Zeile (optional mit Alias). */
export const keinVera8Sql = (alias = '') => `${alias}source is distinct from '${VERA8_SOURCE}'`;

/** Liegen in task_solutions; ihr Kennzeichen steht in tasks.vorbefuellt (wertfrei). */
export const LOESUNGS_FELDER = ['correct_answers', 'solution', 'hints', 'typical_errors', 'coach_hints'];

/** Entscheidung 2+4: kein Kennzeichen, kein Befund, wenn diese Felder leer bleiben. */
export const NIE_LUECKE = ['coach_hints', 'unit'];

/**
 * VERA8-Verstoesse einer Charge: ueber die Herkunft im Snapshot UND unabhaengig
 * davon ueber den VERA-Belegindex (source_ref), falls ein Snapshot die Herkunft
 * einmal falsch fuehrt.
 */
export function vera8Verstoesse(charge, stand) {
  const index = JSON.parse(fs.readFileSync('public/authoring/grounding-vera8.json', 'utf8'));
  const raus = [];
  for (const a of charge.aufgaben) {
    const t = stand.get(a.id)?.task;
    if (t?.source === VERA8_SOURCE) raus.push(`#${a.nr} ${a.titel}: VERA8-Aufgabe (source=${t.source}) in der Charge`);
    else if (t?.source_ref && Object.hasOwn(index, t.source_ref)) raus.push(`#${a.nr} ${a.titel}: source_ref steht im VERA8-Belegindex`);
  }
  return raus;
}

export const leer = (v) =>
  v == null ||
  (typeof v === 'string' && v.trim() === '') ||
  (Array.isArray(v) && v.length === 0) ||
  (typeof v === 'object' && !Array.isArray(v) && Object.keys(v).length === 0);

const gleich = (a, b) => JSON.stringify(a ?? null) === JSON.stringify(b ?? null);

export function ladeCharge(pfad, snapshotPfad) {
  const charge = JSON.parse(fs.readFileSync(pfad, 'utf8'));
  const snap = JSON.parse(fs.readFileSync(snapshotPfad, 'utf8'));
  const stand = new Map(snap.map((x) => [x.task.id, x]));
  for (const a of charge.aufgaben) {
    if (!stand.has(a.id)) throw new Error(`Aufgabe ${a.id} (${a.titel}) fehlt im Snapshot`);
  }
  return { charge, stand };
}

/** Teilaufgaben-Antworten aus einem correct_answers-Objekt. */
const teilAntwort = (ca, nr) => (ca && !Array.isArray(ca) && Array.isArray(ca[nr]) ? ca[nr] : []);

/**
 * Greift der Eintrag auf diesem Stand? Neu: nur ins Leere. Ueberschreiben:
 * leer ODER exakt der alte Wert. Sonst hat jemand den Wert inzwischen geaendert.
 */
function greift(e, aktuell) {
  if (leer(aktuell)) return true;
  return e.alt !== undefined && gleich(aktuell, e.alt);
}
const artVon = (e, aktuell) => (leer(aktuell) ? 'neu' : e.art ?? 'ueberschrieben');

/**
 * Welche Aenderungen wirken auf dem Snapshot-Stand? Liefert eine flache Liste
 * { id, teil, tabelle, feld, schluessel, wert, alt, art, sicher, grund }, die
 * Leer-Kennzeichen, uebersprungene Ueberschreibungen und den neuen Gesamtstand.
 */
export function wirksam(a, x) {
  const task = structuredClone(x.task);
  const sol = structuredClone(x.sol ?? { correct_answers: [], hints: [], typical_errors: [], coach_hints: [], solution: null });
  const aenderungen = [];
  const uebersprungen = [];
  const merk = (teil, tabelle, feld, schluessel, e, aktuell) => aenderungen.push({
    id: a.id, teil, tabelle, feld, schluessel, wert: e.wert, alt: leer(aktuell) ? null : aktuell,
    art: artVon(e, aktuell), sicher: e.sicher, grund: e.grund, casAlt: e.alt,
  });
  const pruefe = (e, aktuell, wo, setze) => {
    if (greift(e, aktuell)) return setze();
    if (e.alt !== undefined) uebersprungen.push(`${wo}: aktueller Wert weicht von "alt" ab — nicht ueberschrieben`);
  };

  for (const [feld, e] of Object.entries(a.felder ?? {})) {
    pruefe(e, task[feld], feld, () => { merk(null, 'tasks', feld, feld, e, task[feld]); task[feld] = e.wert; });
  }
  for (const [nr, t] of Object.entries(a.teile ?? {})) {
    const p = task.parts.find((q) => String(q.nr) === nr);
    if (!p) throw new Error(`${a.titel}: Teilaufgabe ${nr} existiert nicht`);
    for (const feld of ['afb', 'competency_content', 'needs_image']) {
      if (!t[feld]) continue;
      pruefe(t[feld], p[feld], `Teil ${nr} ${feld}`, () => {
        merk(nr, 'tasks.parts', feld, `parts.${nr}.${feld}`, t[feld], p[feld]); p[feld] = t[feld].wert;
      });
    }
    if (t.antwort) {
      const ca = sol.correct_answers;
      // Ein gefuelltes flaches Array bei MULTI_PART bleibt unangetastet (Befund, kein Umbau).
      if (Array.isArray(ca) && ca.length > 0) continue;
      const aktuell = teilAntwort(ca, nr);
      pruefe(t.antwort, aktuell, `Teil ${nr} antwort`, () => {
        merk(nr, 'task_solutions', 'correct_answers', `correct_answers.${nr}`, t.antwort, aktuell);
        sol.correct_answers = { ...(Array.isArray(ca) ? {} : ca), [nr]: t.antwort.wert };
      });
    }
  }
  for (const [feld, e] of Object.entries(a.loesung ?? {})) {
    pruefe(e, sol[feld], feld, () => { merk(null, 'task_solutions', feld, feld, e, sol[feld]); sol[feld] = e.wert; });
  }

  // Bewusst leer: nur Felder, die im Endstand wirklich leer sind; nie coach_hints/unit.
  const leerKennzeichen = [];
  for (const [schluessel, grund] of Object.entries(a.leer ?? {})) {
    const spalte = schluessel.split('.')[0];
    if (NIE_LUECKE.includes(spalte)) continue;
    const wert = LOESUNGS_FELDER.includes(spalte) ? sol[spalte] : task[spalte];
    if (leer(wert)) leerKennzeichen.push({ schluessel, spalte, grund });
  }
  return { task, sol, aenderungen, uebersprungen, leerKennzeichen, hatteLoesungszeile: x.sol != null };
}

/**
 * Grund fuer das Kennzeichen in tasks.vorbefuellt. Loesungsfelder: wertfrei —
 * tasks ist fuer ready-Aufgaben auch fuer Schueler lesbar. Enthaelt der Grund
 * Ziffern oder Options-Ids, steht dort nur der Verweis auf die CSV.
 */
export function kennzeichenGrund(schluessel, grund) {
  const loesung = LOESUNGS_FELDER.includes(schluessel.split('.')[0]);
  if (loesung && /\d|\([a-e][:,)]|\b[a-e]\)/.test(grund)) return 'Begruendung in der Charge-CSV (docs/prefill)';
  return grund;
}
