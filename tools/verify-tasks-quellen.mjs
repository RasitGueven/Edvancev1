/**
 * verify-tasks-quellen.mjs — woher der Prüfer seine Aufgaben nimmt.
 *
 * Zwei Quellen, gleiche Form nach aussen:
 *
 *   prod   Produktionsdatenbank (Vorgabe). Prüft, was schon eingespielt IST.
 *   datei  JSON-Datei.          Prüft, was eingespielt WERDEN SOLL.
 *
 * Der Grund für die zweite Quelle: Content-Specs dürfen nicht in Produktion
 * schreiben. Solange der Prüfer nur aus Produktion lesen konnte, war der eine
 * Fall, für den er gebaut wurde — neue Aufgaben VOR dem Einspielen — der
 * einzige, den er nicht prüfen konnte. In der K8-Charge musste sich der
 * Erzeuger deshalb selbst prüfen; damit war die Unabhängigkeit weg.
 *
 * Dateiformat (JSON) — entweder ein Array von Aufgaben oder ein Objekt:
 *
 *   {
 *     "tasks": [
 *       {
 *         "id": "binom-quadrat-01",
 *         "skill_key": "term_binom_quadrat",
 *         "input_type": "MC",
 *         "status": "draft",
 *         "source": "edvance_k8",
 *         "unit": null,
 *         "question": "Multipliziere aus …",
 *         "solution": { "correct_answers": ["c"], "acceptance": {} }
 *       }
 *     ]
 *   }
 *
 * Die Lösung darf statt in "solution" auch in einer zweiten Liste stehen —
 * "solutions" bzw. "task_solutions", jeder Eintrag mit "task_id". Das ist die
 * Form, in der ein Datenbankabzug herauskommt, und sie soll ohne Umbau passen.
 *
 * Die Feldnamen sind die der Tabellen tasks / task_solutions. Absicht: der
 * Prüfkern dahinter sieht keinen Unterschied und bleibt unverändert.
 */

import fs from 'node:fs/promises';

/** Fehler mit Datei-Kontext — der Aufrufer soll ihn ohne Stacktrace ausgeben. */
export class QuellenFehler extends Error {}

const listeVon = (o, ...namen) => {
  for (const n of namen) if (Array.isArray(o?.[n])) return o[n];
  return null;
};

/**
 * Liest die Aufgaben aus einer JSON-Datei.
 * @returns {Promise<{tasks: object[], loesungVon: Map<string, object>}>}
 */
export async function ausDatei(pfad) {
  if (!pfad) throw new QuellenFehler('--quelle datei braucht --pfad <datei.json>.');

  let roh;
  try {
    roh = await fs.readFile(pfad, 'utf8');
  } catch (e) {
    throw new QuellenFehler(`Datei nicht lesbar: ${pfad} (${e.code ?? e.message})`);
  }

  let daten;
  try {
    daten = JSON.parse(roh);
  } catch (e) {
    throw new QuellenFehler(`${pfad} ist kein gültiges JSON: ${e.message}`);
  }

  const tasks = Array.isArray(daten) ? daten : listeVon(daten, 'tasks', 'aufgaben');
  if (!tasks) {
    throw new QuellenFehler(
      `${pfad}: erwartet ein Array von Aufgaben oder ein Objekt mit "tasks".`);
  }

  // Lösungen aus einer zweiten Liste, falls vorhanden.
  const extern = new Map();
  for (const s of listeVon(daten, 'solutions', 'task_solutions', 'loesungen') ?? []) {
    if (s?.task_id != null) extern.set(String(s.task_id), s);
  }

  const raus = [];
  const loesungVon = new Map();
  const gesehen = new Set();

  tasks.forEach((t, i) => {
    if (!t || typeof t !== 'object') {
      throw new QuellenFehler(`${pfad}: Eintrag ${i} ist keine Aufgabe.`);
    }
    if (t.id == null || String(t.id).trim() === '') {
      throw new QuellenFehler(`${pfad}: Eintrag ${i} hat keine id.`);
    }
    const id = String(t.id);
    if (gesehen.has(id)) {
      throw new QuellenFehler(`${pfad}: id "${id}" kommt mehrfach vor.`);
    }
    gesehen.add(id);

    raus.push({
      id,
      question: t.question ?? t.question_payload ?? t.frage ?? null,
      skill_key: t.skill_key ?? null,
      input_type: t.input_type ?? null,
      status: t.status ?? null,
      source: t.source ?? null,
      unit: t.unit ?? null,
      created_at: t.created_at ?? null,
    });

    // Nur setzen, wenn wirklich eine Lösung dabei ist: eine fehlende Lösung ist
    // ein Befund von Stufe 1 und darf hier nicht zu einem leeren Objekt werden.
    const s = t.solution ?? t.loesung ?? extern.get(id) ?? null;
    if (s && typeof s === 'object') loesungVon.set(id, s);
  });

  return { tasks: raus, loesungVon };
}

/**
 * Liest die Aufgaben aus Produktion. Unverändertes Verhalten der Vorgabe-Quelle.
 * @returns {Promise<{tasks: object[], loesungVon: Map<string, object>}>}
 */
export async function ausProduktion(sb, filter) {
  let q = sb.from('tasks')
    .select('id,question,skill_key,input_type,status,source,unit,created_at');
  if (filter.skill)  q = q.eq('skill_key', filter.skill);
  if (filter.status) q = q.eq('status', filter.status);
  if (filter.source) q = q.eq('source', filter.source);
  if (filter.seit)   q = q.gte('created_at', filter.seit);

  const { data: tasks, error } = await q;
  if (error) throw new QuellenFehler(`Ladefehler: ${error.message}`);

  const ids = (tasks ?? []).map((t) => t.id);
  const loesungVon = new Map();
  if (ids.length) {
    const { data: loesungen } = await sb.from('task_solutions').select('*').in('task_id', ids);
    for (const s of loesungen ?? []) loesungVon.set(s.task_id, s);
  }
  return { tasks: tasks ?? [], loesungVon };
}

/**
 * Wendet dieselben Filter an, die Produktion per SQL erledigt — damit --skill,
 * --status, --source und --seit an beiden Quellen dasselbe bedeuten.
 */
export function filtere(tasks, filter) {
  return tasks.filter((t) => {
    if (filter.skill  && t.skill_key !== filter.skill)  return false;
    if (filter.status && t.status    !== filter.status) return false;
    if (filter.source && t.source    !== filter.source) return false;
    // Ohne created_at kann --seit nicht zutreffen; die Aufgabe fällt heraus.
    if (filter.seit && !(t.created_at && String(t.created_at) >= filter.seit)) return false;
    return true;
  });
}
