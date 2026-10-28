/**
 * Zahlen-Sperre (Anforderung Studio §4): Jede Variante nennt dieselben Zahlen
 * wie das Skelett, als Ziffern oder als Zahlwörter. Verglichen wird die Menge
 * der Werte, nicht die Häufigkeit. Vorzeichen („minus“) zählen nicht mit.
 */

const EINER: Record<string, number> = {
  null: 0, eins: 1, zwei: 2, drei: 3, vier: 4, fünf: 5, sechs: 6, sieben: 7, acht: 8, neun: 9,
  zehn: 10, elf: 11, zwölf: 12, dreizehn: 13, vierzehn: 14, fünfzehn: 15, sechzehn: 16,
  siebzehn: 17, achtzehn: 18, neunzehn: 19,
}
const ZEHNER: Record<string, number> = {
  zwanzig: 20, dreißig: 30, vierzig: 40, fünfzig: 50, sechzig: 60, siebzig: 70, achtzig: 80, neunzig: 90,
}
/** Einer vor „und“ bzw. vor „hundert“/„tausend“ („ein“ statt „eins“). */
const VORSILBE: Record<string, number> = { ...EINER, ein: 1 }
const BRUCH: Record<string, string> = {
  halb: '1/2', halbe: '1/2', halben: '1/2', hälfte: '1/2', drittel: '1/3', viertel: '1/4',
  fünftel: '1/5', sechstel: '1/6', achtel: '1/8', zehntel: '1/10', hundertstel: '1/100',
}

function unterHundert(s: string): number | null {
  if (s in EINER) return EINER[s]
  if (s in ZEHNER) return ZEHNER[s]
  const i = s.indexOf('und')
  if (i > 0) {
    const e = s.slice(0, i)
    const z = s.slice(i + 3)
    if (e in VORSILBE && VORSILBE[e] >= 1 && VORSILBE[e] <= 9 && z in ZEHNER) return VORSILBE[e] + ZEHNER[z]
  }
  return null
}

function unterTausend(s: string): number | null {
  const i = s.indexOf('hundert')
  if (i < 0) return unterHundert(s)
  const vor = s.slice(0, i)
  const nach = s.slice(i + 7)
  const h = vor === '' ? 1 : vor in VORSILBE ? VORSILBE[vor] : null
  if (h === null || h < 1 || h > 9) return null
  if (nach === '') return h * 100
  const r = unterHundert(nach)
  return r === null ? null : h * 100 + r
}

/** Wert eines deutschen Zahlworts bis 999 999, sonst null. */
export function zahlwort(wort: string): number | null {
  const s = wort.toLowerCase()
  const i = s.indexOf('tausend')
  if (i < 0) return unterTausend(s)
  const vor = s.slice(0, i)
  const nach = s.slice(i + 7)
  const t = vor === '' ? 1 : vor in VORSILBE ? VORSILBE[vor] : unterTausend(vor)
  if (t === null || t < 1) return null
  if (nach === '') return t * 1000
  const r = unterTausend(nach)
  return r === null ? null : t * 1000 + r
}

/** Alle Zahlen eines Textes als normalisierte Werte („49“, „0.5“, „1/4“). */
export function zahlenIn(text: string): Set<string> {
  const werte = new Set<string>()
  for (const m of text.matchAll(/\d+(?:[.,]\d+)?/g)) werte.add(String(Number(m[0].replace(',', '.'))))
  for (const m of text.toLowerCase().matchAll(/[a-zäöüß]+/g)) {
    const w = m[0]
    if (w in BRUCH) werte.add(BRUCH[w])
    else {
      const z = zahlwort(w)
      if (z !== null) werte.add(String(z))
    }
  }
  return werte
}

/** Werte, die nur in einem der beiden Texte vorkommen (leer = gleich). */
export function zahlenUnterschied(skelett: string, variante: string): { fehlt: string[]; neu: string[] } {
  const a = zahlenIn(skelett)
  const b = zahlenIn(variante)
  return { fehlt: [...a].filter((x) => !b.has(x)), neu: [...b].filter((x) => !a.has(x)) }
}

/** Formelzeichen im Sprechtext („3/4“, „x²“, „a = b“, TeX). */
export function formelImText(text: string): string | null {
  const m = /[=+^²³√·×÷*/<>≤≥≠$\\]|\d\s*[-–:]\s*\d|\d[a-zA-Z]|[a-zA-Z]\d/.exec(text)
  return m ? m[0] : null
}

export function hatZiffern(text: string): boolean {
  return /\d/.test(text)
}
