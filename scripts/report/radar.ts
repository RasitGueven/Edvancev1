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
// Der Punkt, an dem dieses Diagramm gelogen hat
// ----------------------------------------------------------------------------
// Die erste Fassung zeigte EINE Fläche mit dem Wert `traegt / geprueft`. Das
// verzerrt in genau die falsche Richtung: „2 von 2" ergab eine volle Achse,
// obwohl in der Familie nur zwei von acht vorhandenen Bereichen überhaupt
// angesehen wurden. Je weniger geprüft, desto besser sah die Familie aus.
//
// Jetzt zwei Flächen auf DEMSELBEN Nenner — allen Skills der Familie im
// Bestand:
//
//   AUSSEN, blass und gestrichelt   geprueft / vorhanden
//   INNEN,  gefüllt in Primary      traegt   / vorhanden
//
// Der Abstand zwischen beiden ist die Information:
//
//   dicht beieinander   das Geprüfte trägt
//   weit auseinander    gründlich geprüft, es trägt wenig
//   beide klein         hier wurde kaum geprüft — keine Aussage, kein Vorwurf
//
// Die innere Fläche kann die äußere nie überragen: Ein Skill trägt nicht, ohne
// geprüft worden zu sein. Wo die äußere den Mittelpunkt nicht verlässt, wurde
// nichts angesehen; die Beschriftung sagt das zusätzlich („nicht geprüft"), und
// die Zeile unter dem Diagramm nennt für jede Familie geprüft von vorhanden.
//
// Die frühere Sonderbehandlung „zu wenig geprüft" ist damit entfallen. Sie war
// eine Krücke für den alten Nenner; mit dem Bestand zeigt derselbe Fall von
// sich aus eine kleine Fläche.

import type { FamilienBefund } from '@/lib/report/familien'

const CX = 130
const CY = 128
const R = 82

const r1 = (n: number): number => Math.round(n * 10) / 10
const esc = (t: string): string =>
  t.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

/** Winkel der i-ten von n Achsen, im Uhrzeigersinn ab oben. */
const winkel = (i: number, n: number): number => ((-90 + (i * 360) / n) * Math.PI) / 180

/**
 * Die Eckpunkte einer Fläche über alle Achsen.
 *
 * `wert` liest den Anteil aus dem Befund; null (Familie ohne Bestand) wird als
 * Mittelpunkt gezeichnet.
 */
function polygon(
  befunde: readonly FamilienBefund[],
  wert: (b: FamilienBefund) => number | null,
): { x: number; y: number }[] {
  const n = befunde.length
  return befunde.map((b, i) => {
    const w = winkel(i, n)
    const f = wert(b) ?? 0
    return { x: r1(Math.cos(w) * R * f), y: r1(Math.sin(w) * R * f) }
  })
}

const alsPunkte = (p: readonly { x: number; y: number }[]): string =>
  p.map((q) => `${q.x},${q.y}`).join(' ')

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
      const w = winkel(i, n)
      const lx = Math.min(224, Math.max(36, r1(CX + Math.cos(w) * (R + 26))))
      const grau = b.grund !== null
      const zeilen: { text: string; grau: boolean; klein?: boolean }[] = [
        ...b.zeilen.map((t) => ({ text: t, grau })),
        ...(b.grund ? [{ text: 'nicht geprüft', grau: true, klein: true }] : []),
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
            (z.klein ? ' font-size="8.5" font-style="italic"' : '') +
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
  const aussen = polygon(befunde, (b) => b.anteilGeprueft)
  const innen = polygon(befunde, (b) => b.anteilTraegt)

  // Punkte nur auf der inneren Flaeche, und nur wo geprueft wurde. Ein Punkt im
  // Mittelpunkt einer ungeprueften Achse laese sich als gemessene Null.
  const dots = innen
    .map((q, i) =>
      befunde[i].grund === null
        ? `              <circle cx="${q.x}" cy="${q.y}" r="2.5"/>`
        : null,
    )
    .filter((x): x is string => x !== null)
    .join('\n')

  return `        <svg viewBox="0 0 260 258" width="100%" role="img"
             aria-label="Profil über sechs Themenfamilien. Äußere gestrichelte Fläche: Anteil geprüfter Bereiche am Bestand. Innere gefüllte Fläche: Anteil tragender Bereiche am Bestand.">
          <g transform="translate(${CX},${CY})">
${netz(befunde.length)}
            <polygon points="${alsPunkte(aussen)}" fill="rgba(51,77,122,.05)"
                     stroke="rgba(51,77,122,.45)" stroke-width="1.5"
                     stroke-dasharray="4 3" stroke-linejoin="round"/>
            <polygon points="${alsPunkte(innen)}" fill="rgba(51,77,122,.18)"
                     stroke="#334D7A" stroke-width="2" stroke-linejoin="round"/>
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
 * Fassung des Radars gescheitert. Sie nennt beide Zahlen, die die beiden
 * Flächen zeichnen: wie viel der Familie angesehen wurde und wie viel davon
 * trägt — jeweils gegen den Bestand.
 */
export function radarNenner(befunde: readonly FamilienBefund[]): string {
  return befunde
    .map((b) =>
      b.geprueft === 0
        ? `${b.label}: 0 von ${b.vorhanden} geprüft`
        : `${b.label}: ${b.geprueft} von ${b.vorhanden} geprüft, ${b.traegt} tragen`,
    )
    .join(' · ')
}
