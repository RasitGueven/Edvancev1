/**
 * hinweise-e3-lib.mjs — Nachrechnung der Hinweis-Entwürfe (Paket E3), ohne DB, ohne LLM.
 *
 * Eine Quelle je Skill (tools/hinweise-e3/<skill>.mjs) liefert je Aufgabe (source_ref) drei Stufen.
 * Jede Stufe trägt ihre Belege:
 *   ['≡', a, b]           b steht wörtlich im Text und ist als Term gleichwertig zu a (exakt, prefill-rechnen)
 *   ['gl', von, nach, k]  Umformung einer Gleichung: (L−R) von nach ist das k-Fache von (L−R) von von
 *   ['=', ausdruck, wert] wert steht im Text und ist exakt der Wert des Ausdrucks
 *   ['√', radikand, wurzel] wurzel steht im Text, wurzel² = radikand, wurzel ≥ 0
 *   ['ggT', 'a, b', g]    g steht im Text und ist der größte gemeinsame Teiler von a und b
 *   ['begr', zahl, grund] Zahl aus dem Wortlaut der Aufgabe („doppelt“ → 2); der Grund steht in der Quelle
 * Ein Zwischenwert, der zufällig wie eine Lösung lautet, braucht frei: [[zahl, grund]] am Eintrag der Stufe.
 * Die Zahlen von a, von und ausdruck müssen selbst belegt sein (Aufgabentext oder ein früherer Beleg).
 * Mit vars (z. B. { b: ['7', '-2'] }) wird ein Term mit weiteren Buchstaben für jeden Wert geprüft;
 * var: 't' heißt, die Unbekannte der Aufgabe ist t (wird für den Rechner zu x).
 */

import { Q, term, zahl } from './prefill-rechnen.mjs';

export const MAX_ZEICHEN = 200; // L5 nimmt 500 an (src/lib/pruefung/hinweise.ts); kurz heißt hier höchstens 200
export const MAX_SAETZE = 2;
const VERBOTEN = /\b(richtig|falsch|Fehler|Note|super|toll|leicht|einfach|Sie|Ihnen|Ihr)\b/;

/** Zahlen eines Textes mit Vorzeichen: "−5" nur, wenn das Minus direkt vor der Ziffer steht und kein Rechenzeichen ist. */
export function zahlen(text) {
  const out = [];
  const s = String(text);
  for (const m of s.matchAll(/(\d+(?:,\d+)?)/g)) {
    const vor = s.slice(0, m.index);
    const neg = /(^|[\s(=:;,])[−-]$/.test(vor);
    // Hochzahlen sind keine Ziffern, Ziffern in Wörtern gibt es nicht
    out.push({ roh: m[1], wert: Q.von((neg ? '-' : '') + m[1]), betrag: Q.von(m[1]), index: m.index });
  }
  return out;
}

const hat = (liste, q) => liste.some((p) => p.eq(q));
const absQ = (q) => (q.n < 0n ? q.neg() : q);

/** Unbekannte der Aufgabe für den Rechner zu x machen (nur in Belegen, nie im Text). */
const alsX = (t, v) => {
  const s = String(t).replace(/(\d),(\d)/g, '$1.$2');
  return v && v !== 'x' ? s.replaceAll(v, 'x') : s;
};

function termGleich(a, b, var_, vars) {
  const belegungen = Object.entries(vars ?? {});
  if (!belegungen.length) return term(alsX(a, var_)).eq(term(alsX(b, var_)));
  const n = Math.max(...belegungen.map(([, w]) => w.length));
  for (let i = 0; i < n; i++) {
    const v = Object.fromEntries(belegungen.map(([k, w]) => [k, Q.von(w[i % w.length])]));
    if (!term(alsX(a, var_), v).eq(term(alsX(b, var_), v))) return false;
  }
  return true;
}

function seiten(gl) {
  const t = String(gl).split('=');
  if (t.length !== 2) throw new Error(`keine Gleichung: "${gl}"`);
  return `(${t[0]}) - (${t[1]})`;
}

/** Antworten einer Aufgabe als Zahlen (alle Teile; MC: die richtigen Optionen als Text). */
export function antworten(aufgabe) {
  const ca = aufgabe.correct_answers;
  const roh = Array.isArray(ca) ? ca : Object.values(ca ?? {}).flat();
  const werte = [], texte = [];
  for (const r of roh) {
    const s = String(r).replace(/\s*(s|m|cm|€|°)$/u, '').replace(/[−–]/g, '-').replace(/\s/g, '').replace(/^\+/, '');
    try { werte.push(Q.von(s)); } catch { texte.push(String(r)); }
  }
  return { werte, texte };
}

const ohneLeer = (t) => String(t).replace(/\s/g, '').replace(/[−–]/g, '-');

/** MC: Texte der richtigen Optionen aus question_payload.options. */
export function richtigeOptionen(aufgabe) {
  if (aufgabe.input_type !== 'MC') return [];
  const ids = new Set([].concat(aufgabe.correct_answers ?? []).map(String));
  return (aufgabe.question_payload?.options ?? []).filter((o) => ids.has(String(o.id))).map((o) => o.label);
}

/** Fehlbild-Slugs aus acceptance.known_errors (oberste Ebene und je Teil). */
export function fehlbilder(aufgabe) {
  const acc = aufgabe.acceptance ?? {};
  const s = new Set();
  const nimm = (ke) => { if (ke && typeof ke === 'object') for (const v of Object.values(ke)) s.add(v); };
  nimm(acc.known_errors);
  for (const v of Object.values(acc)) if (v && typeof v === 'object') nimm(v.known_errors);
  return s;
}

/** MULTI_PART mit den Teilen „kleinere Lösung“ und „größere Lösung“. */
export const istKleinerGroesser = (aufgabe) =>
  aufgabe.input_type === 'MULTI_PART' && (aufgabe.parts ?? []).some((p) => /kleinere Lösung/i.test(p.prompt ?? ''));

/**
 * Prüft die drei Stufen einer Aufgabe. Liefert { fehler: string[], belegt: string[] }.
 * eintrag = { stufen: [{ text, belege?, fehlbild? }, …], var?, vars? }
 */
export function pruefeAufgabe(aufgabe, eintrag) {
  const fehler = [];
  const wo = (i) => `${aufgabe.source_ref} Stufe ${i + 1}`;
  const frageZahlen = zahlen(aufgabe.question).map((z) => z.betrag);
  const { werte: loes, texte: loesTexte } = antworten(aufgabe);
  const slugs = fehlbilder(aufgabe);
  const belegt = [...frageZahlen, new Q(0n)]; // 0: „ein Produkt ist null“ / „= 0“ gehört zum Verfahren
  const stufen = eintrag.stufen ?? [];
  if (stufen.length !== 3) fehler.push(`${aufgabe.source_ref}: ${stufen.length} Stufen statt 3`);
  const texte = new Set();

  stufen.forEach((st, i) => {
    const text = st.text ?? '';
    if (texte.has(text)) fehler.push(`${wo(i)}: gleicher Text wie eine frühere Stufe`);
    texte.add(text);
    if (text.length > MAX_ZEICHEN) fehler.push(`${wo(i)}: ${text.length} Zeichen (höchstens ${MAX_ZEICHEN})`);
    const saetze = (text.match(/[.!?](\s|$)/g) ?? []).length;
    if (saetze > MAX_SAETZE || saetze === 0) fehler.push(`${wo(i)}: ${saetze} Sätze (1 bis ${MAX_SAETZE})`);
    const v = text.match(VERBOTEN);
    if (v) fehler.push(`${wo(i)}: Wort „${v[1]}“ (kein richtig/falsch, keine Wertung, Du-Form)`);
    if (/ - |\*|\^|\$/.test(text)) fehler.push(`${wo(i)}: Schreibweise wie in den Lösungen (−, ·, x², keine $…$)`);

    // Belege abarbeiten: Zahlen der Eingangsseite müssen schon belegt sein
    const termeImText = [];
    for (const b of st.belege ?? []) {
      try {
        const [art, a, z, k] = b;
        if (art === 'begr') {
          // Zahl aus dem Wortlaut (z. B. „doppelt“ → 2); Grund ist Pflicht und wird mitgeprüft
          if (!(typeof z === 'string' && z.trim().length >= 8)) throw new Error('Grund fehlt');
          if (!zahlen(text).some((n) => n.betrag.eq(Q.von(a)))) fehler.push(`${wo(i)}: begründete Zahl ${a} steht nicht im Text`);
          belegt.push(Q.von(a));
          continue;
        }
        for (const n of zahlen(a)) {
          if (!hat(belegt, n.betrag)) fehler.push(`${wo(i)}: Beleg ${JSON.stringify(b)} rechnet mit unbelegter Zahl ${n.roh}`);
        }
        if (!text.includes(z)) fehler.push(`${wo(i)}: „${z}“ steht nicht wörtlich im Text`);
        let ok;
        if (art === '≡') ok = termGleich(a, z, eintrag.var, eintrag.vars);
        else if (art === 'gl') ok = termGleich(seiten(z), `(${k ?? '1'}) * (${seiten(a)})`, eintrag.var, eintrag.vars);
        else if (art === '=') ok = zahl(alsX(a, eintrag.var), {}).eq(Q.von(z.replace(/[−–]/g, '-')));
        else if (art === 'ggT') {
          const [x, y] = String(a).split(',').map((t) => BigInt(t.trim()));
          let [u, w] = [x, y]; while (w) [u, w] = [w, u % w];
          ok = String(u) === String(z);
        }
        else if (art === '√') { const w = Q.von(z); ok = w.n >= 0n && w.mul(w).eq(zahl(alsX(a), {})); }
        else throw new Error(`unbekannte Belegart ${art}`);
        if (!ok) { fehler.push(`${wo(i)}: Beleg stimmt nicht: ${JSON.stringify(b)}`); continue; }
        for (const n of zahlen(z)) belegt.push(n.betrag);
        if (art === '≡' || art === 'gl') termeImText.push(z);
      } catch (e) {
        fehler.push(`${wo(i)}: Beleg ${JSON.stringify(b)} nicht rechenbar: ${e.message}`);
      }
    }

    for (const n of zahlen(text)) {
      if (!hat(belegt, n.betrag)) fehler.push(`${wo(i)}: Zahl ${n.roh} ist nicht belegt`);
      if (i === 0 && !hat(frageZahlen, n.betrag) && !n.betrag.istNull()) {
        fehler.push(`${wo(i)}: Stufe 1 nennt ${n.roh}, eine Zahl, die nicht in der Aufgabe steht`);
      }
    }

    // Nie das Ergebnis: keine Zuweisung „x = Lösung“, keine Lösungszahl außerhalb belegter Terme
    let rest = text;
    for (const t of termeImText) rest = rest.replaceAll(t, ' ');
    for (const n of zahlen(text)) {
      const vor = text.slice(0, n.index).replace(/[−-]$/, '');
      const zuweisung = /(^|[^\w²³)·])([a-zA-Z])\s*=\s*$/.exec(vor);
      if (zuweisung && hat(loes, n.wert) && zuweisung[2] === (eintrag.var ?? 'x')) {
        fehler.push(`${wo(i)}: nennt das Ergebnis ${zuweisung[2]} = ${n.roh}`);
      }
      if (zuweisung && hat(loes, n.wert) && eintrag.gesucht && zuweisung[2] === eintrag.gesucht) {
        fehler.push(`${wo(i)}: nennt das Ergebnis ${zuweisung[2]} = ${n.roh}`);
      }
    }
    // Zwischenwert, der wie eine Lösung lautet (z. B. q = −3 unter der Wurzel): nur mit Grund in frei
    const frei = (st.frei ?? []).map(([zahl, grund]) => {
      if (!(typeof grund === 'string' && grund.trim().length >= 8)) fehler.push(`${wo(i)}: frei ${zahl} ohne Grund`);
      return Q.von(zahl);
    });
    for (const n of zahlen(rest)) {
      if (hat(loes.map(absQ), n.betrag) && !hat(frageZahlen, n.betrag) && !n.betrag.istNull() && !hat(frei, n.betrag)) {
        fehler.push(`${wo(i)}: Lösungszahl ${n.roh} steht frei im Text`);
      }
    }
    if (/(Lösung|Ergebnis)(en)?\s+(ist|sind|lautet|lauten|heißt|heißen)\s*[−-]?\d/.test(text)) {
      fehler.push(`${wo(i)}: nennt eine Lösung als Zahl`);
    }
    // MC: die richtige Option (Text der Option) steht nie im Hinweis
    for (const o of richtigeOptionen(aufgabe)) {
      if (ohneLeer(text).includes(ohneLeer(o))) fehler.push(`${wo(i)}: nennt die richtige Option „${o}“`);
    }
    for (const lt of loesTexte) if (lt.length > 2 && text.includes(lt)) fehler.push(`${wo(i)}: nennt die Antwort „${lt}“`);

    // Rundung so wie in der Aufgabe: „auf zwei Stellen nach dem Komma“, nicht nur „zwei Stellen“
    if (/Stellen/.test(text) && /nach dem Komma/.test(aufgabe.question) && !/Stellen nach dem Komma/.test(text)) {
      fehler.push(`${wo(i)}: Rundung nicht wie in der Aufgabe („Stellen nach dem Komma“)`);
    }
    // Das Kind sieht nur den Text: kein Fehlbild-Slug, kein Unterstrich, keine Anmerkung in Klammern
    if (/_/.test(text) || [...slugs].some((f) => text.includes(f))) fehler.push(`${wo(i)}: Fehlbild-Slug im Text`);
    // Reihenfolge (Rasit 12.10.): Teile „kleinere/größere Lösung“ → Stufe 3 erinnert an die Reihenfolge
    if (i === 2 && istKleinerGroesser(aufgabe) && !/kleinere Lösung zuerst/.test(text)) {
      fehler.push(`${wo(i)}: erinnert nicht daran, die kleinere Lösung zuerst einzutragen`);
    }
    for (const f of [].concat(st.fehlbild ?? [])) {
      if (!slugs.has(f)) fehler.push(`${wo(i)}: Fehlbild ${f} steht nicht in known_errors der Aufgabe`);
    }
  });
  return { fehler };
}

/** Die Hinweise so, wie sie in task_solutions.hints landen. */
export const alsHints = (eintrag) =>
  eintrag.stufen.map((st, i) => ({ level: i + 1, text: st.text, status: 'entwurf' }));
