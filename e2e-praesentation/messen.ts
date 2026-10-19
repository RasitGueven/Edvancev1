// Messungen im Browser für die Ansichtstests der Tablet-Präsentation (T2,
// Entscheidung 10). Allgemein gehalten: Die Prüfungen kennen keine Inhalte der
// Stationen, nur diese Verträge (T3 und T4 setzen die Attribute):
//
//   data-tp-pflicht        muss sichtbar sein
//   data-tp-liste          wird als Ganzes gemessen, nicht ihr Inhalt (darf in sich scrollen)
//   data-tp-beschriftung   überlappt keine andere und enthält keinen Punkt der Kurve
//   data-tp-kurve          der Pfad der Kurve (SVG <path>)
//   data-tp-zeile          eine Zeile mit Detail; data-tp-bereiche="n" = Zahl der Bereiche,
//                          der Knopf darin trägt aria-expanded
import type { Page } from '@playwright/test'

export type Rechteck = { links: number; oben: number; rechts: number; unten: number }

/**
 * Alle Verstöße einer Station gegen Passform und Pflichtteile, als lesbare Zeilen.
 * Leer = in Ordnung.
 */
export async function verstoesse(page: Page, station: number): Promise<string[]> {
  return page.evaluate((nr) => {
    const s = document.querySelector<HTMLElement>(`.tp-station[data-station="${nr}"]`)
    if (!s) return [`Station ${nr} fehlt`]
    const sr = s.getBoundingClientRect()
    const fehler: string[] = []
    const name = (el: Element): string =>
      `${el.tagName.toLowerCase()}${el.className && typeof el.className === 'string' ? '.' + el.className.trim().split(/\s+/).join('.') : ''}`

    if (Math.abs(sr.top) > 1) fehler.push(`Station steht nicht oben (top ${sr.top.toFixed(1)})`)
    if (s.scrollHeight > s.clientHeight + 1) fehler.push(`Station scrollt (${s.scrollHeight} > ${s.clientHeight})`)

    /** Nicht ausgeblendet (bis zur Station hinauf). */
    const gezeigt = (el: Element): boolean => {
      for (let e: Element | null = el; e && e !== s; e = e.parentElement) {
        const cs = getComputedStyle(e)
        if (cs.display === 'none' || cs.visibility === 'hidden' || Number(cs.opacity) === 0) return false
      }
      return true
    }
    /** Sichtbarer Teil: Rechteck geschnitten mit allen abschneidenden Vorfahren in der Station. */
    const sichtbarerTeil = (el: Element) => {
      const r = el.getBoundingClientRect()
      let l = r.left
      let o = r.top
      let re = r.right
      let u = r.bottom
      for (let e = el.parentElement; e && e !== s; e = e.parentElement) {
        const cs = getComputedStyle(e)
        if (cs.overflowX === 'visible' && cs.overflowY === 'visible') continue
        const p = e.getBoundingClientRect()
        l = Math.max(l, p.left)
        o = Math.max(o, p.top)
        re = Math.min(re, p.right)
        u = Math.min(u, p.bottom)
      }
      return re - l > 0.5 && u - o > 0.5 ? { links: l, oben: o, rechts: re, unten: u } : null
    }
    /** Zeichnet etwas: eigener Text, Grafik, Knopf, Fläche oder Rand. */
    const zeichnet = (el: Element): boolean => {
      if (/^(svg|img|canvas|button|input|path|circle|rect|line|polyline)$/i.test(el.tagName)) return true
      if ([...el.childNodes].some((n) => n.nodeType === Node.TEXT_NODE && n.textContent!.trim())) return true
      const cs = getComputedStyle(el)
      if (cs.backgroundImage !== 'none') return true
      if (cs.backgroundColor !== 'rgba(0, 0, 0, 0)' && cs.backgroundColor !== 'transparent') return true
      return ['Top', 'Right', 'Bottom', 'Left'].some(
        (k) => parseFloat(cs.getPropertyValue(`border-${k.toLowerCase()}-width`)) > 0,
      )
    }

    // Kopf und Leiste liegen über den Stationen: kein Inhalt darf darunter rutschen.
    const ueber = [
      ...document.querySelectorAll('.tp-kopf > *, .tp-leiste-eintrag, .tp-eddie'),
    ].map((el) => ({ el, r: el.getBoundingClientRect() }))
    const schneidet = (a: { links: number; oben: number; rechts: number; unten: number }, b: DOMRect): boolean =>
      Math.min(a.rechts, b.right) - Math.max(a.links, b.left) > 0.5 &&
      Math.min(a.unten, b.bottom) - Math.max(a.oben, b.top) > 0.5

    for (const el of s.querySelectorAll('*')) {
      if (el.closest('[data-tp-liste]') && !el.hasAttribute('data-tp-liste')) continue
      if (el.closest('svg') && el.tagName.toLowerCase() !== 'svg') continue
      if (!gezeigt(el) || !zeichnet(el)) continue
      const r = sichtbarerTeil(el)
      if (!r) continue
      // Volle Fläche der Station (Hintergründe) zählt nicht als Inhalt.
      if (r.unten - r.oben >= sr.height - 1 && r.rechts - r.links >= sr.width - 1) continue
      if (r.unten > sr.bottom - 8 + 0.5) fehler.push(`${name(el)} reicht bis ${r.unten.toFixed(1)} (Grenze ${(sr.bottom - 8).toFixed(1)})`)
      if (r.oben < sr.top - 0.5) fehler.push(`${name(el)} ragt oben hinaus (${r.oben.toFixed(1)})`)
      if (r.rechts > sr.right + 0.5) fehler.push(`${name(el)} ragt rechts hinaus (${r.rechts.toFixed(1)} > ${sr.right})`)
      if (r.links < sr.left - 0.5) fehler.push(`${name(el)} ragt links hinaus (${r.links.toFixed(1)})`)
      const unter = ueber.find((u) => schneidet(r, u.r))
      if (unter) fehler.push(`${name(el)} liegt unter ${name(unter.el)}`)
    }

    for (const el of s.querySelectorAll('[data-tp-pflicht]')) {
      // Fast ganz zu sehen: mindestens 95 % der Fläche.
      const r = el.getBoundingClientRect()
      const t = gezeigt(el) ? sichtbarerTeil(el) : null
      const anteil = t ? ((t.rechts - t.links) * (t.unten - t.oben)) / Math.max(1, r.width * r.height) : 0
      if (anteil < 0.95) fehler.push(`Pflichtteil ${name(el)} nicht sichtbar (${Math.round(anteil * 100)} von 100)`)
    }

    // Beschriftungen: keine Überlappung, kein Punkt der Kurve darin. Verschachtelte
    // Beschriftungen (Label in der Karte) zählen nicht als Überlappung.
    const schriften = [...s.querySelectorAll('[data-tp-beschriftung]')]
      .filter(gezeigt)
      .map((el) => ({ el, r: el.getBoundingClientRect() }))
    for (let i = 0; i < schriften.length; i++) {
      for (let k = i + 1; k < schriften.length; k++) {
        if (schriften[i].el.contains(schriften[k].el) || schriften[k].el.contains(schriften[i].el)) continue
        const a = schriften[i].r
        const b = schriften[k].r
        const x = Math.min(a.right, b.right) - Math.max(a.left, b.left)
        const y = Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top)
        if (x > 0.5 && y > 0.5) fehler.push(`${name(schriften[i].el)} überlappt ${name(schriften[k].el)}`)
      }
    }
    for (const pfad of s.querySelectorAll<SVGPathElement>('path[data-tp-kurve]')) {
      const ctm = pfad.getScreenCTM()
      if (!ctm) continue
      const laenge = pfad.getTotalLength()
      for (let i = 0; i < 200; i++) {
        const p = pfad.getPointAtLength((laenge * i) / 199)
        const q = new DOMPoint(p.x, p.y).matrixTransform(ctm)
        const treffer = schriften.find(({ r }) => q.x > r.left && q.x < r.right && q.y > r.top && q.y < r.bottom)
        if (treffer) {
          fehler.push(`Kurve läuft durch ${name(treffer.el)} bei ${q.x.toFixed(0)},${q.y.toFixed(0)}`)
          break
        }
      }
    }
    return fehler
  }, station)
}

/**
 * Knöpfe und Tabs der Präsentation unter 44 px (Trefferfläche: das größere
 * aus Element und ::before/::after mit position absolute).
 */
export async function kleineZiele(page: Page): Promise<string[]> {
  return page.evaluate(() => {
    const gezeigt = (el: Element): boolean => {
      for (let e: Element | null = el; e; e = e.parentElement) {
        const cs = getComputedStyle(e)
        if (cs.display === 'none' || cs.visibility === 'hidden' || Number(cs.opacity) === 0) return false
      }
      return true
    }
    const px = (v: string): number | null => (v.endsWith('px') ? parseFloat(v) : null)
    const fehler: string[] = []
    for (const el of document.querySelectorAll('.tp button, .tp [role="tab"]')) {
      if (!gezeigt(el)) continue
      const r = el.getBoundingClientRect()
      let b = r.width
      let h = r.height
      for (const pseudo of ['::before', '::after']) {
        const cs = getComputedStyle(el, pseudo)
        if (cs.content === 'none' || cs.position !== 'absolute') continue
        const [o, re, u, l] = [cs.top, cs.right, cs.bottom, cs.left].map(px)
        const pb = l !== null && re !== null ? r.width - l - re : px(cs.width)
        const ph = o !== null && u !== null ? r.height - o - u : px(cs.height)
        if (pb !== null) b = Math.max(b, pb)
        if (ph !== null) h = Math.max(h, ph)
      }
      if (b < 44 - 0.5 || h < 44 - 0.5) {
        const text = (el.getAttribute('aria-label') ?? el.textContent ?? '').trim().slice(0, 40)
        fehler.push(`„${text}" ${b.toFixed(1)}×${h.toFixed(1)}`)
      }
    }
    return fehler
  })
}

/** Oberkante einer Station relativ zum Bild. */
export async function stationOben(page: Page, station: number): Promise<number> {
  return page.evaluate(
    (nr) => document.querySelector(`.tp-station[data-station="${nr}"]`)!.getBoundingClientRect().top,
    station,
  )
}

/** Das Intro passt: Logo, Kicker, Name, Unterzeile und Knopf liegen ganz im Bild. */
export async function introVerstoesse(page: Page): Promise<string[]> {
  return page.evaluate(() => {
    const intro = document.querySelector('.tp-intro')
    if (!intro) return ['Intro fehlt']
    const ir = intro.getBoundingClientRect()
    const fehler: string[] = []
    for (const el of intro.querySelectorAll('.tp-intro-innen > *, .tp-intro-los')) {
      const r = el.getBoundingClientRect()
      if (r.left < ir.left - 0.5 || r.right > ir.right + 0.5 || r.top < ir.top - 0.5 || r.bottom > ir.bottom - 8 + 0.5) {
        fehler.push(`${el.className} außerhalb (${r.left.toFixed(0)},${r.top.toFixed(0)}–${r.right.toFixed(0)},${r.bottom.toFixed(0)})`)
      }
    }
    return fehler
  })
}
