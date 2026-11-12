import { describe, expect, it } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import '@/i18n'
import { ArchivHinweis } from './ArchivHinweis'

describe('ArchivHinweis', () => {
  it('zeigt bei einer archivierten Aufgabe den Hinweis und den Weg ins Archiv', () => {
    render(
      <MemoryRouter>
        <ArchivHinweis archiviertAm="2026-11-12T16:00:00Z" grund="nicht_notwendig" />
      </MemoryRouter>,
    )
    expect(screen.getByText(/Diese Aufgabe ist archiviert \(am 12\.11\.2026, Grund: nicht notwendig\)/)).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Zum Archiv, dort wiederherstellen' })).toHaveAttribute('href', '/admin/authoring/archiv')
  })

  it('zeigt ohne Archiv-Kennzeichen nichts', () => {
    const { container } = render(
      <MemoryRouter>
        <ArchivHinweis archiviertAm={null} grund={null} />
      </MemoryRouter>,
    )
    expect(container).toBeEmptyDOMElement()
  })
})
