// T3: Im Testlauf steht im Kopf der Live-Sicht gut sichtbar, dass Inhalte ungeprueft sein koennen
// (Hinweise, Musterloesungen, Fehlbilder erscheinen dort auch ohne Freigabe). Ausserhalb eines Testlaufs nicht.

import { describe, expect, it } from 'vitest'
import { render, screen } from '@testing-library/react'
import '@/i18n'
import { beispielZuruecksetzen, ladeRaumLive } from '@/lib/session/coachLiveBeispielQuelle'
import type { CoachLiveRaum } from '@/types/coachLive'
import { LiveKopf } from './LiveKopf'

async function raum(testlauf: boolean): Promise<CoachLiveRaum> {
  beispielZuruecksetzen()
  const { data } = await ladeRaumLive('s1')
  if (!data) throw new Error('Beispielraum fehlt')
  return { ...data, session: { ...data.session, testlauf } }
}

function zeige(r: CoachLiveRaum): void {
  render(<LiveKopf raum={r} eigeneAnsicht={false} onZeige={() => {}} onZurueck={() => {}} />)
}

describe('T3 Testlauf-Hinweis im Kopf der Live-Sicht', () => {
  it('zeigt im Testlauf den Satz zu ungeprüften Inhalten', async () => {
    zeige(await raum(true))
    expect(screen.getByTestId('testlauf-hinweis').textContent).toBe('Testlauf: Inhalte können ungeprüft sein.')
    expect(screen.getByRole('status').textContent).toContain('Inhalte können ungeprüft sein')
  })

  it('zeigt ihn außerhalb eines Testlaufs nicht', async () => {
    zeige(await raum(false))
    expect(screen.queryByTestId('testlauf-hinweis')).toBeNull()
    expect(screen.queryByText(/ungeprüft/)).toBeNull()
  })
})
