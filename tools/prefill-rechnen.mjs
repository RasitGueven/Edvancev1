/**
 * prefill-rechnen.mjs — exakte Nachrechnung ohne Gleitkomma.
 *
 * Ein kleiner Parser fuer Schul-Terme: Zahlen (auch "3,70"), Variablen, + - * / ^,
 * Klammern, round(x, n), Hochzahlen (² ³ ⁴), "·" und ":" sowie implizites Mal
 * ("3x", "2(x+1)", ")("). Ergebnis ist ein Polynom in x mit Bruch-Koeffizienten;
 * andere Variablen werden vorher eingesetzt. Damit lassen sich Zahlen exakt
 * vergleichen und Terme auf Gleichwertigkeit pruefen.
 */

const gcd = (a, b) => { a = a < 0n ? -a : a; b = b < 0n ? -b : b; while (b) [a, b] = [b, a % b]; return a; };

export class Q {
  constructor(n, d = 1n) {
    if (d === 0n) throw new Error('Division durch 0');
    if (d < 0n) { n = -n; d = -d; }
    const g = gcd(n, d) || 1n;
    this.n = n / g; this.d = d / g;
  }
  static von(text) {
    const s = String(text).trim().replace(',', '.');
    const m = s.match(/^(-?)(\d+)(?:\.(\d+))?$/);
    if (!m) throw new Error(`keine Zahl: "${text}"`);
    const nach = m[3] ?? '';
    const q = new Q(BigInt(m[2] + nach), 10n ** BigInt(nach.length));
    return m[1] ? q.neg() : q;
  }
  add(o) { return new Q(this.n * o.d + o.n * this.d, this.d * o.d); }
  sub(o) { return this.add(o.neg()); }
  mul(o) { return new Q(this.n * o.n, this.d * o.d); }
  div(o) { return new Q(this.n * o.d, this.d * o.n); }
  neg() { return new Q(-this.n, this.d); }
  eq(o) { return this.n === o.n && this.d === o.d; }
  istNull() { return this.n === 0n; }
  /** kaufmaennisch auf s Stellen runden (halbe Stelle weg von 0) */
  round(s) {
    const f = 10n ** BigInt(s);
    const z = this.n * f * 2n, n2 = this.d * 2n;
    const q = (z + (z >= 0n ? this.d : -this.d)) / n2;
    return new Q(q, f);
  }
  toString() { return this.d === 1n ? String(this.n) : `${this.n}/${this.d}`; }
}

/** Polynom in x: Map Grad -> Q */
class P {
  constructor(m = new Map()) { this.m = m; for (const [k, v] of [...m]) if (v.istNull()) m.delete(k); }
  static k(q) { return new P(new Map([[0, q]])); }
  static x() { return new P(new Map([[1, new Q(1n)]])); }
  add(o) { const m = new Map(this.m); for (const [k, v] of o.m) m.set(k, (m.get(k) ?? new Q(0n)).add(v)); return new P(m); }
  neg() { return new P(new Map([...this.m].map(([k, v]) => [k, v.neg()]))); }
  mul(o) {
    const m = new Map();
    for (const [a, u] of this.m) for (const [b, v] of o.m) m.set(a + b, (m.get(a + b) ?? new Q(0n)).add(u.mul(v)));
    return new P(m);
  }
  konst() {
    if ([...this.m.keys()].some((k) => k !== 0)) throw new Error('Term enthaelt noch x');
    return this.m.get(0) ?? new Q(0n);
  }
  eq(o) { return this.add(o.neg()).m.size === 0; }
}

const HOCH = { '²': '^2', '³': '^3', '⁴': '^4' };

function tokens(text) {
  const s = String(text).replace(/[²³⁴]/g, (c) => HOCH[c]).replace(/[·×]/g, '*').replace(/:/g, '/').replace(/[−–]/g, '-');
  const out = [];
  for (const m of s.matchAll(/\s*(\d+(?:\.\d+)?|[A-Za-z]+|[-+*/^(),])/gy)) out.push(m[1]);
  if (out.join('').replace(/\s/g, '') !== s.replace(/\s/g, '')) throw new Error(`nicht lesbar: "${text}"`);
  // implizites Mal: Zahl|x|")" gefolgt von x|"("|Zahl
  const r = [];
  for (const t of out) {
    const v = r[r.length - 1];
    if (v != null && /^[\d.,A-Za-z)]/.test(v) && !/^round$/.test(v) && /^[A-Za-z(]/.test(t) && !(v === 'round')) r.push('*');
    r.push(t);
  }
  return r;
}

/** Wertet einen Term aus. vars: { P: Q, M: Q, A: Q } — x bleibt symbolisch. */
export function term(text, vars = {}) {
  const t = tokens(text); let i = 0;
  const sieh = () => t[i], nimm = (e) => { if (e && t[i] !== e) throw new Error(`erwartet ${e} in "${text}"`); return t[i++]; };
  const summe = () => {
    let a = produkt();
    while (sieh() === '+' || sieh() === '-') { const op = nimm(); const b = produkt(); a = op === '+' ? a.add(b) : a.add(b.neg()); }
    return a;
  };
  const produkt = () => {
    let a = potenz();
    while (sieh() === '*' || sieh() === '/') {
      const op = nimm(); const b = potenz();
      a = op === '*' ? a.mul(b) : a.mul(P.k(new Q(1n).div(b.konst())));
    }
    return a;
  };
  const potenz = () => {
    const b = vorzeichen();
    if (sieh() !== '^') return b;
    nimm('^'); const e = Number(vorzeichen().konst().toString());
    let r = P.k(new Q(1n)); for (let k = 0; k < e; k++) r = r.mul(b);
    return r;
  };
  const vorzeichen = () => (sieh() === '-' ? (nimm(), atom().neg()) : sieh() === '+' ? (nimm(), atom()) : atom());
  const atom = () => {
    const c = nimm();
    if (c === '(') { const v = summe(); nimm(')'); return v; }
    if (c === 'round') { nimm('('); const v = summe().konst(); nimm(','); const s = Number(summe().konst().toString()); nimm(')'); return P.k(v.round(s)); }
    if (/^\d/.test(c)) return P.k(Q.von(c));
    if (c === 'x') return P.x();
    if (c in vars) return P.k(vars[c]);
    throw new Error(`unbekanntes Symbol "${c}" in "${text}"`);
  };
  const v = summe();
  if (i !== t.length) throw new Error(`Rest nicht gelesen in "${text}"`);
  return v;
}

export const zahl = (text, vars) =>
  /^-?\d+(,\d+)?$/.test(String(text).trim()) ? Q.von(text) : term(text, vars).konst();
export const gleichwertig = (a, b) => term(a).eq(term(b));

/** Anzahl der Faktoren auf oberster Ebene, Potenzen mitgezaehlt: "3(x+2)²" -> 3. */
export function faktoren(text) {
  const s = String(text).replace(/\s/g, '').replace(/[²³⁴]/g, (c) => HOCH[c]);
  let n = 0, tiefe = 0, i = 0;
  while (i < s.length) {
    const c = s[i];
    if (tiefe === 0 && /[+-]/.test(c) && i > 0) return 1; // Summe oben: kein Produkt
    if (c === '(') { if (tiefe === 0) n++; tiefe++; } else if (c === ')') tiefe--;
    else if (tiefe === 0 && /[\dx]/.test(c) && (i === 0 || !/[\dx^]/.test(s[i - 1]))) n++;
    else if (tiefe === 0 && c === '^') { const m = s.slice(i + 1).match(/^\d+/); n += Number(m[0]) - 1; i += m[0].length; }
    i++;
  }
  return Math.max(n, 1);
}
