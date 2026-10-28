// Lesbare Kurzform einer Loesung bzw. eines Fehlbilds fuer Lenas Pruefansicht (DATENVERTRAG §13.6).
type Wert = Record<string, unknown>

export function loesungText(l: Wert | null | undefined): string {
  if (!l) return '–'
  if (l.keine_loesung === true) return 'L = { }'
  if (Array.isArray(l.menge)) return `L = {${(l.menge as string[]).join('; ')}}`
  if (l.werte && typeof l.werte === 'object') {
    return Object.entries(l.werte as Record<string, string>).map(([k, v]) => `${k} = ${v}`).join(', ')
  }
  if (typeof l.option === 'string') return `Option ${l.option}`
  if (l.zeile !== undefined) return [l.zeile !== undefined ? `Zeile ${String(l.zeile)}` : '', l.warum ? `Warum ${String(l.warum)}` : ''].filter(Boolean).join(', ')
  if (Array.isArray(l.gewaehlt)) return (l.gewaehlt as string[]).join(' + ')
  if (Array.isArray(l.reihenfolgen)) return (l.reihenfolgen as string[][]).map((r) => r.join(' → ')).join(' oder ')
  if (Array.isArray(l.reihenfolge)) return (l.reihenfolge as string[]).join(' → ')
  return JSON.stringify(l)
}
