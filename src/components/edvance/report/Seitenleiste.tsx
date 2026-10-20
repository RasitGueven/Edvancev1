import { useEffect, useState, type RefObject } from 'react'
import { useTranslation } from 'react-i18next'

const SEITEN = [1, 2, 3, 4, 5] as const

const ruhig = (): boolean =>
  typeof window.matchMedia === 'function' &&
  window.matchMedia('(prefers-reduced-motion: reduce)').matches

const seite = (bogen: HTMLElement | null, nummer: number): HTMLElement | null =>
  bogen?.querySelector<HTMLElement>(`.eb-seite[data-seite="${nummer}"]`) ?? null

/**
 * Sprungleiste über dem Bogen (Bauauftrag R7-7, Entscheidung 2): die fünf
 * Stationen des Berichts als Knöpfe. Ein Klick scrollt weich an den
 * Seitenanfang; markiert ist die Seite, die gerade im oberen Teil des Fensters
 * steht. Nur am Bildschirm, und nur, wenn der Bogen Seiten hat.
 */
export function Seitenleiste({
  bogen,
  bogenKey,
}: {
  bogen: RefObject<HTMLElement>
  /** Nach jedem Neueinhängen des Bogens die neuen Seiten beobachten. */
  bogenKey: string
}): JSX.Element | null {
  const { t } = useTranslation('report')
  const { t: tb } = useTranslation('elternbericht')
  const [hatSeiten, setHatSeiten] = useState(false)
  const [aktiv, setAktiv] = useState(1)

  useEffect(() => {
    const seiten = SEITEN.map((n) => seite(bogen.current, n)).filter(
      (el): el is HTMLElement => el !== null,
    )
    setHatSeiten(seiten.length > 0)
    if (seiten.length === 0 || typeof IntersectionObserver === 'undefined') return
    // Ein schmales Band im oberen Drittel des Fensters: Die Seite, die es
    // schneidet, ist die aktive. Seiten berühren sich nie (24 px Abstand).
    const beobachter = new IntersectionObserver(
      (eintraege) => {
        for (const e of eintraege) {
          const n = Number((e.target as HTMLElement).dataset.seite)
          if (e.isIntersecting && n > 0) setAktiv(n)
        }
      },
      { rootMargin: '-25% 0px -70% 0px' },
    )
    seiten.forEach((el) => beobachter.observe(el))
    return () => beobachter.disconnect()
  }, [bogen, bogenKey])

  if (!hatSeiten) return null

  const springe = (n: number): void => {
    setAktiv(n)
    seite(bogen.current, n)?.scrollIntoView({
      behavior: ruhig() ? 'auto' : 'smooth',
      block: 'start',
    })
  }

  return (
    <nav
      aria-label={t('ansicht.seitenleiste')}
      className="print-hide sticky top-0 z-10 -mx-4 mb-4 bg-[var(--color-bg-subtle)] px-4 py-2"
    >
      <ul className="flex flex-wrap justify-center gap-2">
        {SEITEN.map((n) => (
          <li key={n}>
            <button
              type="button"
              aria-current={n === aktiv ? 'true' : undefined}
              onClick={() => springe(n)}
              className={`min-h-[44px] rounded-[var(--radius-md)] px-4 text-sm font-semibold transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-primary)] ${
                n === aktiv
                  ? 'bg-[var(--color-primary)] text-[var(--color-text-inverse)]'
                  : 'bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)]'
              }`}
            >
              {tb(`s1.weg.station.${n}`)}
            </button>
          </li>
        ))}
      </ul>
    </nav>
  )
}
