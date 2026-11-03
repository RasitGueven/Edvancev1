// Präsentation auf Laptop und großen Bildschirmen (TP-L1, Entscheidungen 1, 2,
// 4 und 5). Die Bühne ist das iPad quer, 1180 × 820. Ist der Bildschirm in
// beiden Richtungen größer, wird die ganze Ebene per CSS zoom gleichmäßig
// vergrößert, bis sie ihn füllt; kleiner wird sie nie. Auf dem iPad (quer wie
// hoch) bleibt der Faktor 1 und das Bild pixelgleich.
//
// zoom statt transform: scale, weil scale die Messungen verfälschen würde.
// Unter zoom liefern getBoundingClientRect und clientX/clientY in Chromium wie
// in WebKit Bildschirm-px, offset* und scroll* dagegen Bühnen-px. Wo beides
// zusammenkommt, rechnet inBuehnenPx um (Entscheidung 5).
//
// Container-Einheiten: WebKit rechnet cqw unter zoom gegen die vergrößerte
// Größe, also doppelt; Chromium richtig. Wo das so ist, misst cqDoppelt es
// nach, und die Ebene bekommt die Klasse tp-cq-zoom (rahmen.css).

import { useLayoutEffect, useState, type RefObject } from 'react'

export const BUEHNE = { breite: 1180, hoehe: 820 } as const

/** f = max(1, min(w / 1180, h / 820)): nur vergrößern, ohne Obergrenze. */
export function buehnenFaktor(breite: number, hoehe: number): number {
  return Math.max(1, Math.min(breite / BUEHNE.breite, hoehe / BUEHNE.hoehe))
}

/** Der Faktor der Ebene, in der el liegt (1 außerhalb der Präsentation). */
export function zoomVon(el: Element | null | undefined): number {
  const tp = el?.closest<HTMLElement>('.tp')
  const f = tp ? Number(tp.style.getPropertyValue('--tp-zoom')) : NaN
  return Number.isFinite(f) && f > 0 ? f : 1
}

/** Bildschirm-px (Rechtecke, Zeigerkoordinaten) in Bühnen-px (offset*, scroll*). */
export function inBuehnenPx(px: number, el: Element | null | undefined): number {
  return px / zoomVon(el)
}

/** Rechnet der Browser cqw in dieser Ebene doppelt? Probe 100 px breit, darin 100cqw. Nur bei f > 1 messbar. */
function cqDoppelt(ebene: HTMLElement, f: number): boolean {
  if (f <= 1) return false
  const probe = document.createElement('div')
  probe.className = 'tp-cq-probe'
  probe.setAttribute('aria-hidden', 'true')
  const innen = probe.appendChild(document.createElement('i'))
  ebene.appendChild(probe)
  const breite = innen.offsetWidth
  probe.remove()
  return breite > 101
}

const standalone = (): boolean =>
  typeof window.matchMedia === 'function' && window.matchMedia('(display-mode: standalone)').matches

/** Vollbild geht: der Browser kann es, und die Seite läuft nicht als Web-App vom Home-Bildschirm. */
export function vollbildMoeglich(): boolean {
  return typeof document !== 'undefined' && document.fullscreenEnabled === true && !standalone()
}

export const imVollbild = (): boolean => typeof document !== 'undefined' && document.fullscreenElement != null

/**
 * Vollbild für die ganze Seite. Muss im Klick-Handler selbst laufen, sonst
 * fehlt die Nutzergeste. Scheitert es, bleibt alles still wie es ist.
 */
export function vollbildStarten(): void {
  if (!vollbildMoeglich() || imVollbild()) return
  try {
    void document.documentElement.requestFullscreen?.()?.catch(() => undefined)
  } catch {
    // ohne Vollbild weiter
  }
}

export function vollbildBeenden(): void {
  if (!imVollbild()) return
  try {
    void document.exitFullscreen?.()?.catch(() => undefined)
  } catch {
    // schon beendet
  }
}

/**
 * Setzt --tp-zoom an der Ebene (die einzige Inline-Variable, Leitplanke) und
 * rechnet bei resize und fullscreenchange neu. Liefert den Faktor, ob gerade
 * Vollbild läuft (für den Knopf im Kopf) und ob cqw nachgerechnet werden muss.
 */
export function useBuehnenZoom(ref: RefObject<HTMLElement>): { faktor: number; vollbild: boolean; cqZoom: boolean } {
  const [faktor, setFaktor] = useState(() => buehnenFaktor(window.innerWidth, window.innerHeight))
  const [vollbild, setVollbild] = useState(imVollbild)
  const [cqZoom, setCqZoom] = useState(false)

  useLayoutEffect(() => {
    const rechnen = (): void => {
      const f = buehnenFaktor(window.innerWidth, window.innerHeight)
      const ebene = ref.current
      ebene?.style.setProperty('--tp-zoom', String(f))
      setCqZoom(ebene ? cqDoppelt(ebene, f) : false)
      setFaktor(f)
      setVollbild(imVollbild())
    }
    rechnen()
    window.addEventListener('resize', rechnen)
    document.addEventListener('fullscreenchange', rechnen)
    return () => {
      window.removeEventListener('resize', rechnen)
      document.removeEventListener('fullscreenchange', rechnen)
    }
  }, [ref])

  return { faktor, vollbild, cqZoom }
}
