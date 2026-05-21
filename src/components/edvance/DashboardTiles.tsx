import type { ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { EdvanceCard } from '@/components/edvance'

export type DashboardTile = {
  to: string
  icon: ReactNode
  title: string
  description: string
  // true => same-page Anker (<a href>), sonst React-Router-Link
  anchor?: boolean
}

function TileBody({ tile }: { tile: DashboardTile }): JSX.Element {
  return (
    <EdvanceCard className="flex h-full items-start gap-4 p-5">
      <span
        className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl text-[var(--primary)] bg-[color-mix(in_srgb,var(--primary)_12%,transparent)]"
        aria-hidden="true"
      >
        {tile.icon}
      </span>
      <span className="flex flex-col gap-1">
        <span className="text-base font-semibold text-[var(--text-primary)]">
          {tile.title}
        </span>
        <span className="text-xs leading-relaxed text-[var(--text-muted)]">
          {tile.description}
        </span>
      </span>
    </EdvanceCard>
  )
}

export function DashboardTiles({ tiles }: { tiles: DashboardTile[] }): JSX.Element {
  return (
    <section className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {tiles.map((tile) =>
        tile.anchor ? (
          <a
            key={tile.to}
            href={tile.to}
            className="block min-h-[44px] transition-transform hover:-translate-y-0.5"
          >
            <TileBody tile={tile} />
          </a>
        ) : (
          <Link
            key={tile.to}
            to={tile.to}
            className="block min-h-[44px] transition-transform hover:-translate-y-0.5"
          >
            <TileBody tile={tile} />
          </Link>
        ),
      )}
    </section>
  )
}
