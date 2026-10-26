// LSA-L4 Teil D (Entscheidung 15): Hinweis vor der LSA-Freigabe, wenn der Stand der Klassenarbeit fehlt.
import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import admin from '@/i18n/locales/de/admin.json'

import { EMPTY_INTAKE } from './formState'
import { KlassenarbeitHinweis, KLASSENARBEIT_ANKER } from './KlassenarbeitHinweis'

describe('KlassenarbeitHinweis', () => {
  it('fehlt der Stand (nichts gewählt oder „weiß nicht“): Hinweis mit Link zu den Feldern', () => {
    for (const klassenarbeit of [null, 'weissNicht'] as const) {
      const { unmount } = render(<KlassenarbeitHinweis form={{ ...EMPTY_INTAKE, klassenarbeit }} />)
      expect(screen.getByTestId('intake-ka-hinweis')).toHaveTextContent(admin.intake.erstgespraech.klassenarbeit.fehltHinweis)
      expect(screen.getByRole('link')).toHaveAttribute('href', `#${KLASSENARBEIT_ANKER}`)
      unmount()
    }
  })

  it('mit Stand kein Hinweis (kein Blocker)', () => {
    for (const klassenarbeit of ['bevorstehend', 'geschrieben'] as const) {
      const { container, unmount } = render(<KlassenarbeitHinweis form={{ ...EMPTY_INTAKE, klassenarbeit }} />)
      expect(container).toBeEmptyDOMElement()
      unmount()
    }
  })
})
