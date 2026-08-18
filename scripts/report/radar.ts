// Eltern-Report — das Profil über die Themenfamilien (R5).
//
// Das Bild, auf das der Coach im Gespräch zeigt. Es steht in Abschnitt 03 neben
// den beiden Listen und beantwortet eine andere Frage als die Ebenenspur in
// Abschnitt 02: Die Spur ordnet nach TIEFE, das Profil nach THEMA. Keine
// Dopplung — dieselben Urteile, zwei Achsen.
//
// (Variante B, die Balken nach Tiefe, bleibt entfallen. Sie zeigte exakt die
// Zahlen der Ebenenspur, und von beiden ist die Spur die tragfähigere: Sie
// lässt sich beschriften.)
//
// ----------------------------------------------------------------------------
// Der Punkt, an dem dieses Diagramm lügen könnte
// ----------------------------------------------------------------------------
// Ein Radar über Anteile verschweigt seinen Nenner. „Brüche 100 %" können zwei
// von zwei geprüften Skills sein — auf so dünner Basis liest sich eine volle
// Achse wie eine Bestnote. Und eine Familie, die gar nicht geprüft wurde, sähe
// mit einem Punkt im Mittelpunkt aus wie eine, die nichts kann.
//
// Drei Vorkehrungen dagegen, in dieser Reihenfolge wichtig:
//
//   1. NICHT GEPRÜFT wird nie wie NULL gezeichnet. Die Achse bekommt keinen
//      Vertexpunkt, die Kanten dorthin sind gestrichelt, und die Beschriftung
//      sagt „nicht geprüft" statt eines Familiennamens allein.
//   2. Achsen unter MIN_GEPRUEFT_ACHSE tragen keine Fläche und heißen „zu wenig
//      geprüft". Eine volle Achse aus einem Skill gibt es nicht.
//   3. Unter dem Diagramm steht der Nenner je Familie im Klartext. Wer die Form
//      liest, sieht daneben, worauf sie beruht.
//
// Ein echter Anteil von 0 bekommt dagegen einen sichtbaren Punkt knapp neben
// dem Mittelpunkt (NULL_RADIUS) — sonst wäre er von „nicht geprüft" nicht zu
// unterscheiden.

import type { FamilienBefund } from '@/lib/report/familien'

const CX = 130
const CY = 128
const R = 82

/**
 * Radius, mit dem ein echter Anteil von 0 gezeichnet wird.
 *
 * Klein genug, um als „nichts davon trägt" zu lesen, groß genug, damit der
 * Punkt sichtbar NEBEN dem Mittelpunkt sitzt — dort, wo die nicht geprüften
 * Achsen enden. Bei 0,05 überlappte der Vertexpunkt (r=3) noch den
 * Mittelpunkt, und ein echter Nullwert war von „nicht geprüft" nicht mehr zu
 * unterscheiden.
 */
const NULL_RADIUS = 0.09

const r1 = (n: number): number => Math.round(n * 10) / 10
const esc = (s: string): string =>
  s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

type Punkt = { x: number; y: number; gezeichnet: boolean }

function punkte(befunde: readonly FamilienBefund[]): Punkt[] {
  const n = befunde.length
  return befunde.map((b, i) => {
    const w = ((-90 + (i * 360) / n) * Math.PI) / 180
    // Nicht auswertbare Achsen enden exakt im Mittelpunkt — die Fläche greift
    // dort nicht aus, behauptet aber auch keinen Wert.
    const f = b.anteil === null ? 0 : Math.max(b.anteil, NULL_RADIUS)
    return {
      x: r1(Math.cos(w) * R * f),
      y: r1(Math.sin(w) * R * f),
      gezeichnet: b.anteil !== null,
    }
  })
}

function netz(n: number): string {
  const ring = (f: number) =>
    Array.from({ length: n }, (_, i) => {
      const w = ((-90 + (i * 360) / n) * Math.PI) / 180
      return `${r1(Math.cos(w) * R * f)},${r1(Math.sin(w) * R * f)}`
    }).join(' ')
  const speichen = Array.from({ length: n }, (_, i) => {
    const w = ((-90 + (i * 360) / n) * Math.PI) / 180
    return `              <line x1="0" y1="0" x2="${r1(Math.cos(w) * R)}" y2="${r1(Math.sin(w) * R)}"/>`
  }).join('\n')
  return `            <polygon points="${ring(1)}" fill="none" stroke="#E8E8E5"/>
            <polygon points="${ring(2 / 3)}" fill="none" stroke="#EFEFED"/>
            <polygon points="${ring(1 / 3)}" fill="none" stroke="#EFEFED"/>
            <g stroke="#EFEFED">
${speichen}
            </g>`
}

/**
 * Beschriftung je Achse.
 *
 * Zweizeilige Familiennamen bekommen ihre zweite Zeile, nicht auswertbare
 * Achsen zusätzlich eine dritte in Grau mit dem Grund. Der Block wird nach oben
 * geschoben, wenn er sonst unten aus dem Bild liefe.
 */
function beschriftung(befunde: readonly FamilienBefund[]): string {
  const n = befunde.length
  return befunde
    .map((b, i) => {
      const w = ((-90 + (i * 360) / n) * Math.PI) / 180
      const lx = Math.min(224, Math.max(36, r1(CX + Math.cos(w) * (R + 26))))
      const zeilen = [
        ...b.zeilen.map((t) => ({ text: t, grau: b.anteil === null })),
        ...(b.grund
          ? [
              {
                text: b.grund === 'nicht_geprueft' ? 'nicht geprüft' : 'zu wenig geprüft',
                grau: true,
                klein: true,
              },
            ]
          : []),
      ]
      let ly = r1(CY + Math.sin(w) * (R + 26)) + 3
      const hoehe = (zeilen.length - 1) * 10
      if (ly + hoehe > 244) ly = 244 - hoehe
      if (ly < 12) ly = 12
      return zeilen
        .map(
          (z, k) =>
            `            <text x="${lx}" y="${r1(ly + k * 10)}"` +
            ` fill="${z.grau ? '#A8A8A4' : '#4A4A47'}"` +
            (('klein' in z && z.klein) ? ' font-size="8.5" font-style="italic"' : '') +
            `>${esc(z.text)}</text>`,
        )
        .join('\n')
    })
    .join('\n')
}

/**
 * Das Profil als SVG.
 *
 * Ein Farbton (Primary), Fläche mit niedriger Deckkraft, keine Prozentzahlen an
 * den Achsen, keine Skalenbeschriftung, keine Ampelfarben — die Ringe sind das
 * einzige Maß, und sie tragen bewusst keine Zahl. Wer eine Prozentzahl
 * anschreibt, hat eine Note gebaut (INV-4.4).
 */
export function radarSvg(befunde: readonly FamilienBefund[]): string {
  const p = punkte(befunde)
  const flaeche = p.map((x) => `${x.x},${x.y}`).join(' ')
  const dots = p
    .filter((x) => x.gezeichnet)
    .map((x) => `              <circle cx="${x.x}" cy="${x.y}" r="3"/>`)
    .join('\n')

  // Gestrichelte Kanten dorthin, wo nichts geprüft wurde: Die Fläche schließt
  // sich, ohne zu behaupten, dass dort etwas gemessen wurde.
  const gestrichelt = p
    .map((x, i) => {
      const next = p[(i + 1) % p.length]
      if (x.gezeichnet && next.gezeichnet) return null
      return `              <line x1="${x.x}" y1="${x.y}" x2="${next.x}" y2="${next.y}" stroke-dasharray="3 3"/>`
    })
    .filter((x): x is string => x !== null)
    .join('\n')

  return `        <svg viewBox="0 0 260 258" width="100%" role="img"
             aria-label="Profil über sechs Themenfamilien; nicht geprüfte Familien sind als solche gekennzeichnet">
          <g transform="translate(${CX},${CY})">
${netz(befunde.length)}
            <polygon points="${flaeche}" fill="rgba(51,77,122,.14)" stroke="#334D7A"
                     stroke-width="2" stroke-linejoin="round"/>
${gestrichelt ? `            <g stroke="#FFFFFF" stroke-width="2">\n${gestrichelt}\n            </g>` : ''}
            <g fill="#334D7A">
${dots}
            </g>
          </g>
          <g font-size="9.5" font-family="Schibsted Grotesk" text-anchor="middle">
${beschriftung(befunde)}
          </g>
        </svg>`
}

/**
 * Die Nennerzeile unter dem Diagramm.
 *
 * Ohne sie ist die Grundgesamtheit unsichtbar, und genau daran ist die erste
 * Fassung des Radars gescheitert.
 */
export function radarNenner(befunde: readonly FamilienBefund[]): string {
  return befunde
    .map((b) =>
      b.geprueft === 0
        ? `${b.label}: nicht geprüft`
        : `${b.label}: ${b.traegt} von ${b.geprueft}`,
    )
    .join(' · ')
}
