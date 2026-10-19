import type { SeitenProps } from './seitenProps'

/**
 * Seite 2 des Eltern-Berichts R7: Lernstand mit Kompetenzprofil (R7-3).
 *
 * In R7-2 nur die Hülle im Rahmen; der Inhalt kommt im genannten Paket. Styles
 * in src/styles/elternbericht/seite2.css, alles unter .eb-s2.
 */
export function Seite2(_props: SeitenProps): JSX.Element {
  return <div className="eb-s2" />
}
