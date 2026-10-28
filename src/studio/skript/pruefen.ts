/**
 * Importprüfung der Studio-Skripte (Anforderung Studio §4, Bauauftrag B1).
 *
 * Reine Funktion ohne Oberfläche und ohne Datenbank: Die Oberfläche („Skript
 * einfügen“) und die Skript-Tests aus B8 rufen sie gleich auf. Der Fehlbild-
 * Katalog kommt von außen (Prod: fehlbild_labels.slug, Test: Test-Katalog).
 */
import { BAUSTEINE, paramFehler, type BausteinSpec } from './bausteine'
import { formelImText, hatZiffern, zahlenUnterschied } from './zahlen'
import { istWelt } from './welten'
import type { Befund, PruefErgebnis, Skript, SkriptOption } from './typen'

export type PruefOptionen = {
  /** Erlaubte Fehlbild-Schlüssel; null = nicht prüfen (nur in der Vorschau ohne Katalog). */
  katalog: ReadonlySet<string> | null
  bausteine?: Record<string, BausteinSpec>
}

const BEAT_ID = /^[a-z][a-z0-9_]{0,15}$/
const KERNIDEE = /^(?:([a-z][a-z0-9_]*):)?k([1-9])$/
const SLUG = /^[a-z0-9_]+$/
export const SPRUNGMARKE_MAX = 40

const istObjekt = (x: unknown): x is Record<string, unknown> => typeof x === 'object' && x !== null && !Array.isArray(x)
const istText = (x: unknown): x is string => typeof x === 'string' && x.trim() !== ''

/** "k2" → "<skill>:k2"; Langform bleibt. null bei ungültigem Schlüssel. */
export function kernideeNormal(schluessel: string, skill: string): string | null {
  const m = KERNIDEE.exec(schluessel)
  return m ? `${m[1] ?? skill}:k${m[2]}` : null
}

export function skriptPruefen(roh: unknown, opt: PruefOptionen): PruefErgebnis & { skript: Skript | null } {
  const bausteine = opt.bausteine ?? BAUSTEINE
  const befunde: Befund[] = []
  const sperre = (code: string, b: Omit<Befund, 'stufe' | 'code'> = {}) => befunde.push({ stufe: 'sperre', code, ...b })
  const welt = (code: string, w: string, b: Omit<Befund, 'stufe' | 'code' | 'welt'> = {}) =>
    befunde.push({ stufe: 'welt', code, welt: w, ...b })
  const hinweis = (code: string, b: Omit<Befund, 'stufe' | 'code'> = {}) => befunde.push({ stufe: 'hinweis', code, ...b })
  const ende = (skript: Skript | null) => {
    const gesperrteWelten = [...new Set(befunde.filter((b) => b.stufe === 'welt').map((b) => b.welt as string))]
    const ok = !befunde.some((b) => b.stufe === 'sperre')
    return { ok, befunde, gesperrteWelten, bereiche: ok ? bereiche : {}, skript: ok ? skript : null }
  }
  const bereiche: PruefErgebnis['bereiche'] = {}

  if (!istObjekt(roh)) {
    sperre('kein_objekt')
    return ende(null)
  }
  const s = roh as Partial<Skript>
  if (!istText(s.skill_key)) sperre('skill_fehlt')
  if (!istText(s.titel)) sperre('titel_fehlt')
  if (!Array.isArray(s.welten) || !s.welten.includes('skelett')) sperre('welten_ohne_skelett')
  const welten = Array.isArray(s.welten) ? s.welten.filter((w): w is string => typeof w === 'string') : []
  for (const w of welten) if (!istWelt(w)) sperre('welt_unbekannt', { werte: { welt: w } })
  if (!Array.isArray(s.beats) || s.beats.length === 0) {
    sperre('keine_beats')
    return ende(null)
  }
  const skill = istText(s.skill_key) ? s.skill_key : ''

  // Texte je Welt prüfen: Skelett Pflicht, Varianten mit Zahlen-Sperre.
  const texte = (t: unknown, beat: string | undefined, sprechtext: boolean, wo: string) => {
    if (!istObjekt(t) || !istText(t.skelett)) {
      sperre('text_fehlt', { beat, werte: { wo } })
      return
    }
    for (const [w, text] of Object.entries(t)) {
      if (!welten.includes(w)) {
        sperre('text_welt_unbekannt', { beat, werte: { welt: w, wo } })
        continue
      }
      if (!istText(text)) {
        sperre('text_fehlt', { beat, werte: { wo } })
        continue
      }
      if (sprechtext) {
        const f = formelImText(text)
        if (f && w === 'skelett') sperre('formel_im_text', { beat, werte: { zeichen: f } })
        else if (f) welt('formel_im_text', w, { beat, werte: { zeichen: f } })
        if (hatZiffern(text)) hinweis('ziffer_im_text', { beat, welt: w })
      }
      if (w !== 'skelett') {
        const u = zahlenUnterschied(t.skelett as string, text)
        if (u.fehlt.length || u.neu.length)
          welt('zahlen_sperre', w, { beat, werte: { wo, fehlt: u.fehlt.join(', '), neu: u.neu.join(', ') } })
      }
    }
  }

  // Beats
  const ids: string[] = []
  const laeufe: string[] = []
  for (const [i, b] of s.beats.entries()) {
    if (!istObjekt(b)) {
      sperre('beat_kein_objekt', { werte: { nr: i + 1 } })
      continue
    }
    const id = typeof b.id === 'string' ? b.id : ''
    if (!BEAT_ID.test(id)) sperre('beat_id_ungueltig', { werte: { nr: i + 1, id } })
    else if (ids.includes(id)) sperre('beat_doppelt', { beat: id })
    ids.push(id)
    if (!istText(b.titel)) sperre('sprungmarke_fehlt', { beat: id })
    else if (b.titel.length > SPRUNGMARKE_MAX)
      sperre('sprungmarke_zu_lang', { beat: id, werte: { laenge: b.titel.length, max: SPRUNGMARKE_MAX } })
    const k = typeof b.kernidee === 'string' ? kernideeNormal(b.kernidee, skill) : null
    if (!k) sperre('kernidee_ungueltig', { beat: id, werte: { wert: String(b.kernidee ?? '') } })
    else {
      if (laeufe[laeufe.length - 1] !== k) {
        if (laeufe.includes(k)) sperre('kernidee_nicht_zusammen', { beat: id, werte: { kernidee: k } })
        laeufe.push(k)
        bereiche[k] = { von: id, bis: id }
      } else bereiche[k].bis = id
    }
    const spec = typeof b.baustein === 'string' ? bausteine[b.baustein] : undefined
    if (!spec) sperre('baustein_unbekannt', { beat: id, werte: { baustein: String(b.baustein ?? '') } })
    else {
      const params = istObjekt(b.params) ? b.params : {}
      for (const [p, wert] of Object.entries(params)) {
        const ps = spec.params[p]
        if (!ps) sperre('param_unbekannt', { beat: id, werte: { param: p } })
        else {
          const f = paramFehler(ps, wert)
          if (f) sperre(f, { beat: id, werte: { param: p } })
        }
      }
      for (const [p, ps] of Object.entries(spec.params))
        if (ps.pflicht && !(p in params)) sperre('param_fehlt', { beat: id, werte: { param: p } })
      if (b.bild !== undefined) {
        if (!istObjekt(b.bild)) sperre('bild_kein_objekt', { beat: id })
        else
          for (const [w, bp] of Object.entries(b.bild)) {
            if (!welten.includes(w) || w === 'skelett') {
              sperre('bild_welt_unbekannt', { beat: id, werte: { welt: w } })
              continue
            }
            for (const [p, wert] of Object.entries(istObjekt(bp) ? bp : {})) {
              if (!spec.bild.includes(p)) welt('bild_param_unbekannt', w, { beat: id, werte: { param: p } })
              else if (!istText(wert) || hatZiffern(wert)) welt('bild_zahl', w, { beat: id, werte: { param: p } })
            }
          }
      }
    }
    texte(b.text, id, true, 'text')
  }

  // Mini-Checks
  const minichecks = Array.isArray(s.minichecks) ? s.minichecks : []
  if (!Array.isArray(s.minichecks)) sperre('minichecks_fehlen')
  else if (minichecks.length === 0) hinweis('ohne_minicheck')
  const bereichVon = (id: string) => Object.keys(bereiche).find((k) => ids.indexOf(bereiche[k].von) <= ids.indexOf(id) && ids.indexOf(id) <= ids.indexOf(bereiche[k].bis))
  const optionen = (opts: unknown, nach: number, beat: string) => {
    if (!Array.isArray(opts) || opts.length < 2) {
      sperre('optionen_zu_wenig', { beat })
      return false
    }
    const antworten = new Set<string>()
    const fehlbilder = new Set<string>()
    let richtig = 0
    let sprung = false
    for (const o of opts as Partial<SkriptOption>[]) {
      if (!istObjekt(o) || !istText(o.antwort)) {
        sperre('antwort_fehlt', { beat })
        continue
      }
      if (antworten.has(o.antwort)) sperre('antwort_doppelt', { beat, werte: { antwort: o.antwort } })
      antworten.add(o.antwort)
      if (!istText(o.rueckmeldung)) sperre('rueckmeldung_fehlt', { beat, werte: { antwort: o.antwort } })
      if (o.richtig === true) {
        richtig++
        if (o.fehlbild || o.ruecksprung) sperre('richtig_mit_fehlbild', { beat, werte: { antwort: o.antwort } })
        continue
      }
      if (o.fehlbild !== undefined) {
        if (!istText(o.fehlbild) || !SLUG.test(o.fehlbild)) sperre('fehlbild_ungueltig', { beat, werte: { antwort: o.antwort } })
        else {
          if (opt.katalog && !opt.katalog.has(o.fehlbild))
            sperre('fehlbild_unbekannt', { beat, werte: { fehlbild: o.fehlbild } })
          if (fehlbilder.has(o.fehlbild)) sperre('fehlbild_doppelt', { beat, werte: { fehlbild: o.fehlbild } })
          fehlbilder.add(o.fehlbild)
        }
      }
      if (o.ruecksprung !== undefined) {
        sprung = true
        const ziel = ids.indexOf(String(o.ruecksprung))
        if (ziel < 0) sperre('ruecksprung_unbekannt', { beat, werte: { ziel: String(o.ruecksprung) } })
        else if (bereichVon(ids[ziel]) !== bereichVon(ids[nach]))
          hinweis('ruecksprung_andere_kernidee', { beat, werte: { ziel: String(o.ruecksprung) } })
        if (!o.fehlbild) sperre('ruecksprung_ohne_fehlbild', { beat, werte: { antwort: o.antwort } })
      }
    }
    if (richtig !== 1) sperre('richtig_genau_eine', { beat, werte: { anzahl: richtig } })
    return sprung
  }
  for (const [i, m] of minichecks.entries()) {
    if (!istObjekt(m)) {
      sperre('minicheck_kein_objekt', { werte: { nr: i + 1 } })
      continue
    }
    const nach = ids.indexOf(String(m.nach_beat))
    const beat = String(m.nach_beat ?? '')
    if (nach < 0) {
      sperre('beat_unbekannt', { werte: { beat } })
      continue
    }
    texte(m.frage, beat, false, 'frage')
    const sprung = optionen(m.optionen, nach, beat)
    const zwillinge = Array.isArray(m.zwillinge) ? m.zwillinge : []
    if (m.zwillinge !== undefined && !Array.isArray(m.zwillinge)) sperre('zwillinge_keine_liste', { beat })
    for (const z of zwillinge) {
      if (!istObjekt(z)) {
        sperre('zwilling_kein_objekt', { beat })
        continue
      }
      texte(z.frage, beat, false, 'zwilling')
      optionen(z.optionen, nach, beat)
    }
    if (sprung && zwillinge.length === 0) hinweis('ohne_zwilling', { beat })
  }

  return ende(s as Skript)
}
